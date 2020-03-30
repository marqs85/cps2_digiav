//
// Copyright (C) 2016-2020  Markus Hiienkari <mhiienka@niksula.hut.fi>
//
// This file is part of CPS2 Digital AV Interface project.
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

module scanconverter (
    input PCLK_CAP_i,
    input PCLK_OUT_i,
    input reset_n,
    input [15:0] DATA_i,
    input HSYNC_i,
    input VSYNC_i,
    input DE_i,
    input FID_i,
    input frame_change_i,
    input [8:0] xpos_i,
    input [8:0] ypos_i,
    input [31:0] h_out_config,
    input [31:0] h_out_config2,
    input [31:0] v_out_config,
    input [31:0] v_out_config2,
    input [31:0] xy_out_config,
    input [31:0] misc_config,
    input [31:0] sl_config,
    input [31:0] sl_config2,
    input testpattern_enable,
    output PCLK_o,
    output reg [7:0] R_o,
    output reg [7:0] G_o,
    output reg [7:0] B_o,
    output reg HSYNC_o,
    output reg VSYNC_o,
    output reg DE_o,
    output reg [10:0] xpos_o,
    output reg [10:0] ypos_o,
    output reg resync_strobe
);

localparam NUM_LINE_BUFFERS = 40;

wire [8:0] H_SYNCLEN = h_out_config[28:20];
wire [8:0] H_BACKPORCH = h_out_config[19:11];
wire [10:0] H_ACTIVE = h_out_config[10:0];
wire [11:0] H_TOTAL = h_out_config2[11:0];

wire [4:0] V_SYNCLEN = v_out_config[24:20];
wire [8:0] V_BACKPORCH = v_out_config[19:11];
wire [10:0] V_ACTIVE = v_out_config[10:0];
wire [10:0] V_TOTAL = v_out_config2[10:0];
wire [10:0] V_STARTLINE = v_out_config2[21:11];

reg frame_change_sync1_reg, frame_change_sync2_reg, frame_change_prev;
wire frame_change = frame_change_sync2_reg;

wire [2:0] X_RPT = h_out_config[31:29];
wire [2:0] Y_RPT = v_out_config[27:25];

wire [2:0] X_SKIP = h_out_config2[24:22];

wire signed [9:0] X_OFFSET = h_out_config2[21:12];
wire signed [8:0] Y_OFFSET = v_out_config2[30:22];
wire signed [5:0] Y_START_LB = xy_out_config[27:22];

wire [10:0] X_SIZE = xy_out_config[10:0];
wire [10:0] Y_SIZE = xy_out_config[21:11];

reg [11:0] h_cnt;
reg [10:0] v_cnt;

reg [10:0] xpos_lb;
reg [10:0] ypos_lb;
reg [2:0] x_ctr;
reg [2:0] y_ctr;

reg [5:0] ypos_i_wraddr;
reg [8:0] ypos_i_prev;
reg [8:0] xpos_i_wraddr;
reg [15:0] DATA_i_wrdata;

reg [15:0] DATA_linebuf_pp4;
reg [4:0] fade_mult_pp4;

reg HSYNC_pp[1:4] /* synthesis ramstyle = "logic" */;
reg VSYNC_pp[1:4] /* synthesis ramstyle = "logic" */;
reg DE_pp[1:4] /* synthesis ramstyle = "logic" */;
reg [10:0] xpos_pp[1:4] /* synthesis ramstyle = "logic" */;
reg [10:0] ypos_pp[1:4] /* synthesis ramstyle = "logic" */;
/*reg [7:0] R_pp[4:4]
reg [7:0] G_pp[4:4]
reg [7:0] B_pp[4:4]*/
reg mask_enable_pp[2:4] /* synthesis ramstyle = "logic" */;

reg [10:0] xpos_lb_start;

assign PCLK_o = PCLK_OUT_i;

wire [14:0] linebuf_wraddr = {ypos_i_wraddr, xpos_i_wraddr};
wire [14:0] linebuf_rdaddr = {ypos_lb[5:0], xpos_lb[8:0]};

wire [15:0] DATA_linebuf;

linebuf linebuf_rgb (
    .data(DATA_i_wrdata),
    .rdaddress(linebuf_rdaddr),
    .rdclock(PCLK_OUT_i),
    .wraddress(linebuf_wraddr),
    .wrclock(PCLK_CAP_i),
    .wren(DE_i),
    .q(DATA_linebuf)
);

// Fade function for CPS1/2
function [7:0] apply_fade;
    input [3:0] data;
    input [4:0] fade_m;
    begin
        //apply_fade = {data, data} >> (3'h7-fade[3:1]);
        //apply_fade = {4'h0, data} * ({4'h0, fade} + 8'h2);
        apply_fade = {4'h0, data} * {3'h0, fade_m};
    end
endfunction

// Linebuffer write address calculation
always @(posedge PCLK_CAP_i) begin
    if (ypos_i == 0) begin
        ypos_i_wraddr <= 0;
    end else if (ypos_i != ypos_i_prev) begin
        if (ypos_i_wraddr == NUM_LINE_BUFFERS-1)
            ypos_i_wraddr <= 0;
        else
            ypos_i_wraddr <= ypos_i_wraddr + 1'b1;
    end

    xpos_i_wraddr <= xpos_i;
    ypos_i_prev <= ypos_i;
    DATA_i_wrdata <= DATA_i;
end


// Frame change strobe synchronization
always @(posedge PCLK_OUT_i) begin
    frame_change_sync1_reg <= frame_change_i;
    frame_change_sync2_reg <= frame_change_sync1_reg;
    frame_change_prev <= frame_change_sync2_reg;
end

// H/V counters
always @(posedge PCLK_OUT_i) begin
    // TODO: fix functionality when V_STARTLINE=0
    if (~frame_change_prev & frame_change & ((v_cnt != V_STARTLINE-1) & (v_cnt != V_STARTLINE))) begin
        h_cnt <= 0;
        v_cnt <= V_STARTLINE;
        resync_strobe <= 1'b1;
    end else begin
        if (h_cnt == H_TOTAL-1) begin
            if (v_cnt == V_TOTAL-1) begin
                v_cnt <= 0;
                resync_strobe <= 1'b0;
            end else begin
                v_cnt <= v_cnt + 1'b1;
            end
            h_cnt <= 0;
        end else begin
            h_cnt <= h_cnt + 1'b1;
        end
    end
end

// Postprocess pipeline structure
// |    0     |    1     |    2    |    3    |    4    |
// |----------|----------|---------|---------|---------|
// | SYNC/DE  |          |         |         |         |
// | X/Y POS  |          |         |         |         |
// |          |   MASK   |         |         |         |
// |          |          | LINEBUF |         |         |
// |          |          |         |  FADE   |  FADE   |


// Pipeline stage 0
always @(posedge PCLK_OUT_i) begin
    HSYNC_pp[1] <= (h_cnt < H_SYNCLEN) ? 1'b0 : 1'b1;
    VSYNC_pp[1] <= (v_cnt < V_SYNCLEN) ? 1'b0 : 1'b1;
    DE_pp[1] <= (h_cnt >= H_SYNCLEN+H_BACKPORCH) & (h_cnt < H_SYNCLEN+H_BACKPORCH+H_ACTIVE) & (v_cnt >= V_SYNCLEN+V_BACKPORCH) & (v_cnt < V_SYNCLEN+V_BACKPORCH+V_ACTIVE);

    if (h_cnt == H_SYNCLEN+H_BACKPORCH) begin
        if (v_cnt == V_SYNCLEN+V_BACKPORCH) begin
            ypos_pp[1] <= 0;
            ypos_lb <= Y_START_LB;
            y_ctr <= 0;
            xpos_lb_start <= (X_OFFSET < 10'sd0) ? 11'd0 : {1'b0, X_OFFSET};
        end else begin
            if (ypos_pp[1] < V_ACTIVE) begin
                ypos_pp[1] <= ypos_pp[1] + 1'b1;
            end

            if (y_ctr == Y_RPT) begin
                if (ypos_lb == NUM_LINE_BUFFERS-1)
                    ypos_lb <= 0;
                else
                    ypos_lb <= ypos_lb + 1'b1;
                y_ctr <= 0;
            end else begin
                y_ctr <= y_ctr + 1'b1;
            end
        end
        xpos_pp[1] <= 0;
        xpos_lb <= 0;
        x_ctr <= 0;
    end else begin
        if (xpos_pp[1] < H_ACTIVE) begin
            xpos_pp[1] <= xpos_pp[1] + 1'b1;
        end

        if (xpos_pp[1] >= xpos_lb_start) begin
            if (x_ctr == X_RPT) begin
                xpos_lb <= xpos_lb + 1'b1 + X_SKIP;
                x_ctr <= 0;
            end else begin
                x_ctr <= x_ctr + 1'b1;
            end
        end
    end
end

// Pipeline stages 1-
integer pp_idx;
always @(posedge PCLK_OUT_i) begin

    for(pp_idx = 2; pp_idx <= 4; pp_idx = pp_idx+1) begin
        HSYNC_pp[pp_idx] <= HSYNC_pp[pp_idx-1];
        VSYNC_pp[pp_idx] <= VSYNC_pp[pp_idx-1];
        DE_pp[pp_idx] <= DE_pp[pp_idx-1];
    end
    for(pp_idx = 2; pp_idx <= 4; pp_idx = pp_idx+1) begin
        xpos_pp[pp_idx] <= xpos_pp[pp_idx-1];
        ypos_pp[pp_idx] <= ypos_pp[pp_idx-1];
    end

    if (($signed({1'b0, xpos_pp[1]}) >= X_OFFSET) & ($signed({1'b0, xpos_pp[1]}) < X_OFFSET+X_SIZE) & ($signed({1'b0, ypos_pp[1]}) >= Y_OFFSET) & ($signed({1'b0, ypos_pp[1]}) < Y_OFFSET+Y_SIZE)) begin
        mask_enable_pp[2] <= 1'b0;
    end else begin
        mask_enable_pp[2] <= 1'b1;
    end
    for(pp_idx = 3; pp_idx <= 4; pp_idx = pp_idx+1) begin
        mask_enable_pp[pp_idx] <= mask_enable_pp[pp_idx-1];
    end

    DATA_linebuf_pp4 <= DATA_linebuf;
    fade_mult_pp4 <= {1'b0, DATA_linebuf[3:0]} + 5'h2;

    R_o <= testpattern_enable ? (xpos_pp[4] ^ ypos_pp[4]) : (mask_enable_pp[4] ? 8'h00 : apply_fade(DATA_linebuf_pp4[15:12], fade_mult_pp4));
    G_o <= testpattern_enable ? (xpos_pp[4] ^ ypos_pp[4]) : (mask_enable_pp[4] ? 8'h00 : apply_fade(DATA_linebuf_pp4[11:8], fade_mult_pp4));
    B_o <= testpattern_enable ? (xpos_pp[4] ^ ypos_pp[4]) : (mask_enable_pp[4] ? 8'h00 : apply_fade(DATA_linebuf_pp4[7:4], fade_mult_pp4));
    
    // Output
    HSYNC_o <= HSYNC_pp[4];
    VSYNC_o <= VSYNC_pp[4];
    DE_o <= DE_pp[4];
end

endmodule
