//
// Copyright (C) 2016-2017  Markus Hiienkari <mhiienka@niksula.hut.fi>
//
// This file is part of CPS2_digiav project.
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

`define TRUE                    1'b1
`define FALSE                   1'b0
`define HI                      1'b1
`define LO                      1'b0

`define HSYNC_POL               `LO
`define VSYNC_POL               `LO

`define V_MULTMODE_EXT          3'd0
`define V_MULTMODE_2X           3'd1
`define V_MULTMODE_3X           3'd2
`define V_MULTMODE_4X           3'd3
`define V_MULTMODE_5X           3'd4

`define SCANLINES_OFF           2'h0
`define SCANLINES_H             2'h1
`define SCANLINES_V             2'h2

`define HSYNC_LEADING_EDGE      ((HSYNC_in_L == `HI) & (HSYNC_in == `LO))
`define VSYNC_LEADING_EDGE      ((VSYNC_in_L == `HI) & (VSYNC_in == `LO))

`define EXT_H_AVIDSTART         144

`define CPS2_H_AVIDSTART        97
`define CPS2_H_ACTIVE           384

module scanconverter (
    input reset_n,
    input [3:0] R_in,
    input [3:0] G_in,
    input [3:0] B_in,
    input [3:0] F_in,
    input HSYNC_in,
    input VSYNC_in,
    input PCLK_in,
    input pclk_5x,
    input pclk_ext,
    input [10:0] hcnt_ext,
    input [10:0] vcnt_ext,
    input HSYNC_ext,
    input VSYNC_ext,
    input DE_ext,
    input [31:0] h_info,
    input [31:0] v_info,
    input [31:0] x_info,
    output reg [7:0] R_out,
    output reg [7:0] G_out,
    output reg [7:0] B_out,
    output reg HSYNC_out,
    output reg VSYNC_out,
    output PCLK_out,
    output reg DE_out,
    output [2:0] pclk_lock,
    output [2:0] pll_lock_lost
);

//clock-related signals
wire pclk_act;
wire pclk_1x, pclk_2x;
wire pclk_2x_lock;
wire linebuf_rdclock;

//RGB signals&registers: 4 bits per component + 4 bit fade
wire [3:0] R_act, G_act, B_act, F_act;
wire [3:0] R_lbuf, G_lbuf, B_lbuf, F_lbuf;
reg [3:0] R_in_L, G_in_L, B_in_L, F_in_L, R_in_LL, G_in_LL, B_in_LL, F_in_LL, R_1x, G_1x, B_1x, F_1x;
reg [7:0] R_pp1, G_pp1, B_pp1, R_pp2, G_pp2, B_pp2, R_pp3, G_pp3, B_pp3, R_pp4, G_pp4, B_pp4;

//H+V syncs + data enable signals&registers
wire HSYNC_act, VSYNC_act, DE_act;
reg HSYNC_in_L, VSYNC_in_L;
reg HSYNC_1x, HSYNC_2x, HSYNC_5x, HSYNC_pp1, HSYNC_pp2, HSYNC_pp3, HSYNC_pp4;
reg VSYNC_1x, VSYNC_2x, VSYNC_5x, VSYNC_pp1, VSYNC_pp2, VSYNC_pp3, VSYNC_pp4;
reg DE_1x, DE_2x, DE_3x, DE_4x, DE_5x, DE_pp1, DE_pp2, DE_pp3, DE_pp4;

//registers indicating line/frame change
reg frame_change, line_change;

//H+V counters
wire [11:0] linebuf_hoffset; //Offset for line (max. 2047 pixels), MSB indicates which line is read/written
wire [11:0] hcnt_act;
reg [11:0] hcnt_1x, hcnt_2x, hcnt_3x, hcnt_4x, hcnt_5x;
wire [10:0] vcnt_act;
reg [10:0] vcnt_1x, vcnt_2x, vcnt_3x, vcnt_4x, vcnt_5x, vcnt_2x_ref, vcnt_5x_ref;        //max. 2047

//other counters
wire [2:0] line_id_act, col_id_act;
reg [2:0] line_id_pp1, line_id_pp2, line_id_pp3, col_id_pp1, col_id_pp2, col_id_pp3;
reg [11:0] hmax[0:1];
reg [10:0] vmax;
reg line_idx;
reg [1:0] line_out_idx_2x, line_out_idx_3x, line_out_idx_4x;
reg [2:0] line_out_idx_5x;
reg [23:0] warn_h_unstable, warn_pll_lock_lost, warn_pll_lock_lost_3x;
reg mask_enable_pp1, mask_enable_pp2, mask_enable_pp3, mask_enable_pp4;

//helper registers for sampling at synchronized clock edges
reg pclk_1x_prev5x;
reg pclk_1x_prevprev5x;
reg [2:0] pclk_5x_cnt;


reg [10:0] H_ACTIVE;    //max. 2047
reg [9:0] H_AVIDSTART;  //max. 1023
reg [10:0] V_ACTIVE;    //max. 2047
reg [6:0] V_AVIDSTART;  //max. 127
reg [7:0] H_SYNCLEN;
reg [2:0] V_SYNCLEN;
reg [1:0] V_SCANLINEMODE;
reg [4:0] V_SCANLINEID;
reg [2:0] V_MULTMODE;
reg [7:0] V_MASK;
reg [7:0] H_MASK;
reg [3:0] X_MASK_BR;
reg [7:0] X_SCANLINESTR;


assign pclk_1x = PCLK_in;
assign PCLK_out = pclk_act;
assign pclk_lock = {pclk_2x_lock, 2'b11};


//Scanline generation
function [7:0] apply_scanlines;
    input [1:0] mode;
    input [7:0] data;
    input [7:0] str;
    input [4:0] mask;
    input [2:0] line_id;
    input [2:0] col_id;
    begin
        if ((mode == `SCANLINES_H) && (mask & (5'h1<<line_id)))
            apply_scanlines = (data > str) ? (data-str) : 8'h00;
        else if ((mode == `SCANLINES_V) && (5'h0 == col_id))
            apply_scanlines = (data > str) ? (data-str) : 8'h00;
        else
            apply_scanlines = data;
    end
    endfunction

//Border masking
function [7:0] apply_mask;
    input enable;
    input [7:0] data;
    input [3:0] brightness;
    begin
        if (enable)
            apply_mask = {brightness, 4'h0};
        else
            apply_mask = data;
    end
    endfunction

//Fade
function [7:0] apply_fade;
    input [3:0] data;
    input [3:0] fade;
    begin
        //apply_fade = {data, data} >> (3'h7-fade[3:1]);
        apply_fade = {4'h0, data} * ({4'h0, fade} + 8'h2);
    end
    endfunction


//Mux for active data selection
//
//Non-critical signals and inactive clock combinations filtered out in SDC
always @(*)
begin
case (V_MULTMODE)
    default: begin //`V_MULTMODE_EXT
        R_act = R_lbuf;
        G_act = G_lbuf;
        B_act = B_lbuf;
        F_act = F_lbuf;
        HSYNC_act = HSYNC_ext;
        VSYNC_act = VSYNC_ext;
        DE_act = DE_ext;
        linebuf_rdclock = pclk_ext;
        linebuf_hoffset = ((6*{2'b00, hcnt_ext})/5)-((6*`EXT_H_AVIDSTART)/5);
        line_id_act = {2'b0, vcnt_ext[0]};
        hcnt_act = hcnt_ext;
        vcnt_act = vcnt_ext;
        pclk_act = pclk_ext;
    end
    `V_MULTMODE_2X: begin
        R_act = R_lbuf;
        G_act = G_lbuf;
        B_act = B_lbuf;
        F_act = F_lbuf;
        HSYNC_act = HSYNC_2x;
        VSYNC_act = VSYNC_2x;
        DE_act = DE_2x;
        linebuf_rdclock = pclk_2x;
        linebuf_hoffset = hcnt_2x;
        line_id_act = {1'b0, line_out_idx_2x};
        hcnt_act = hcnt_2x;
        vcnt_act = vcnt_2x_ref;
        pclk_act = pclk_2x;
    end
    `V_MULTMODE_5X: begin
        R_act = R_lbuf;
        G_act = G_lbuf;
        B_act = B_lbuf;
        F_act = F_lbuf;
        HSYNC_act = HSYNC_5x;
        VSYNC_act = VSYNC_5x;
        DE_act = DE_5x;
        linebuf_rdclock = pclk_5x;
        linebuf_hoffset = hcnt_5x - H_AVIDSTART - 96;
        line_id_act = line_out_idx_5x;
        hcnt_act = hcnt_5x;
        vcnt_act = vcnt_5x;
        pclk_act = pclk_5x;
    end
    endcase
end

//wire [9:0] linebuf_rdaddr = (linebuf_hoffset-H_AVIDSTART-96)>>1;
wire [9:0] linebuf_rdaddr = linebuf_hoffset>>1;
wire [9:0] linebuf_wraddr = (hcnt_1x>>1)-`CPS2_H_AVIDSTART;

linebuf linebuf_rgb (
    .data ( {R_in_L, G_in_L, B_in_L, F_in_L} ),
    .rdaddress ( {~line_idx, linebuf_rdaddr[8:0]} ),
    .rdclock ( linebuf_rdclock ),
    .wraddress( {line_idx, linebuf_wraddr[8:0]} ),
    .wrclock ( pclk_1x ),
    .wren ( linebuf_wraddr < `CPS2_H_ACTIVE ),
    .q ( {R_lbuf, G_lbuf, B_lbuf, F_lbuf} )
);

//Postprocess pipeline
// h_cnt, v_cnt, line_id, col_id:   0
// HSYNC, VSYNC, DE:                1
// RGB:                             2
always @(posedge pclk_act)
begin
    line_id_pp1 <= line_id_act;
    col_id_pp1 <= col_id_act;
    mask_enable_pp1 <= ((hcnt_act < H_AVIDSTART+H_MASK) | (hcnt_act >= H_AVIDSTART+H_ACTIVE-H_MASK) | (vcnt_act < V_AVIDSTART+V_MASK) | (vcnt_act >= V_AVIDSTART+V_ACTIVE-V_MASK));

    HSYNC_pp2 <= HSYNC_act;
    VSYNC_pp2 <= VSYNC_act;
    DE_pp2 <= DE_act;
    line_id_pp2 <= line_id_pp1;
    col_id_pp2 <= col_id_pp1;
    mask_enable_pp2 <= mask_enable_pp1;
    
    R_pp3 <= apply_fade(R_act, F_act);
    G_pp3 <= apply_fade(G_act, F_act);
    B_pp3 <= apply_fade(B_act, F_act);
    HSYNC_pp3 <= HSYNC_pp2;
    VSYNC_pp3 <= VSYNC_pp2;
    DE_pp3 <= DE_pp2;
    line_id_pp3 <= line_id_pp2;
    col_id_pp3 <= col_id_pp2;
    mask_enable_pp3 <= mask_enable_pp2;

    R_pp4 <= apply_scanlines(V_SCANLINEMODE, R_pp3, X_SCANLINESTR, V_SCANLINEID, line_id_pp3, col_id_pp3);
    G_pp4 <= apply_scanlines(V_SCANLINEMODE, G_pp3, X_SCANLINESTR, V_SCANLINEID, line_id_pp3, col_id_pp3);
    B_pp4 <= apply_scanlines(V_SCANLINEMODE, B_pp3, X_SCANLINESTR, V_SCANLINEID, line_id_pp3, col_id_pp3);
    HSYNC_pp4 <= HSYNC_pp3;
    VSYNC_pp4 <= VSYNC_pp3;
    DE_pp4 <= DE_pp3;
    mask_enable_pp4 <= mask_enable_pp3;

    R_out <= apply_mask(mask_enable_pp4, R_pp4, X_MASK_BR);
    G_out <= apply_mask(mask_enable_pp4, G_pp4, X_MASK_BR);
    B_out <= apply_mask(mask_enable_pp4, B_pp4, X_MASK_BR);
    HSYNC_out <= HSYNC_pp4;
    VSYNC_out <= VSYNC_pp4;
    DE_out <= DE_pp4;
end

//Generate a warning signal from horizontal instability or PLL sync loss
always @(posedge pclk_1x /*or negedge reset_n*/)
begin
    if (hmax[0] != hmax[1])
        warn_h_unstable <= 1;
    else if (warn_h_unstable != 0)
        warn_h_unstable <= warn_h_unstable + 1'b1;

    if ((V_MULTMODE == `V_MULTMODE_2X) & ~pclk_2x_lock)
        warn_pll_lock_lost <= 1;
    else if (warn_pll_lock_lost != 0)
        warn_pll_lock_lost <= warn_pll_lock_lost + 1'b1;
end

assign h_unstable = (warn_h_unstable != 0);
assign pll_lock_lost = {(warn_pll_lock_lost != 0), 2'b00};

//Buffer the inputs using input pixel clock and generate 1x signals
always @(posedge pclk_1x or negedge reset_n)
begin
    if (!reset_n) begin
        hcnt_1x <= 0;
        vcnt_1x <= 0;
        hmax[0] <= 0;
        hmax[1] <= 0;
        vmax <= 0;
        line_idx <= 0;
        line_change <= 1'b0;
        frame_change <= 1'b0;
        V_MULTMODE <= 0;
    end else begin
        if (`HSYNC_LEADING_EDGE) begin
            hcnt_1x <= 0;
            hmax[line_idx] <= hcnt_1x;
            line_idx <= line_idx ^ 1'b1;
            line_change <= 1'b1;
        end else begin
            hcnt_1x <= hcnt_1x + 1'b1;
            line_change <= 1'b0;
        end

        if (`HSYNC_LEADING_EDGE) begin
            if ((VSYNC_in == `LO) & (vcnt_1x > 100)) begin
                vcnt_1x <= 0;
                frame_change <= 1'b1;
                vmax <= vcnt_1x;
            end else begin
                vcnt_1x <= vcnt_1x + 1'b1;
            end
        end else
            frame_change <= 1'b0;

        if (frame_change) begin
            //Read configuration data from CPU
            V_MULTMODE <= x_info[31] ? `V_MULTMODE_EXT : `V_MULTMODE_5X;    // Line multiply mode

            H_SYNCLEN <= 20;
            H_AVIDSTART <= h_info[20:11];
            H_ACTIVE <= h_info[10:0];

            V_SYNCLEN <= 3;
            V_AVIDSTART <= v_info[17:11];
            V_ACTIVE <= v_info[10:0];

            H_MASK <= h_info[28:21];
            V_MASK <= v_info[25:18];

            V_SCANLINEMODE <= x_info[1:0];
            X_SCANLINESTR <= ((x_info[5:2]+8'h01)<<4)-1'b1;
            V_SCANLINEID <= x_info[10:6];
            X_MASK_BR <= 0;
        end
            
        R_in_L <= R_in;
        G_in_L <= G_in;
        B_in_L <= B_in;
        F_in_L <= F_in;
        HSYNC_in_L <= HSYNC_in;
        VSYNC_in_L <= VSYNC_in;

        // Add one delay stage to match linebuf delay
        R_in_LL <= R_in_L;
        G_in_LL <= G_in_L;
        B_in_LL <= B_in_L;
        F_in_LL <= F_in_L;

        R_1x <= R_in_LL;
        G_1x <= G_in_LL;
        B_1x <= B_in_LL;
        F_1x <= F_in_LL;
        HSYNC_1x <= (hcnt_1x < H_SYNCLEN) ? `HSYNC_POL : ~`HSYNC_POL;
        VSYNC_1x <= (vcnt_1x < V_SYNCLEN) ? `VSYNC_POL : ~`VSYNC_POL;
        DE_1x <= ((hcnt_1x >= H_AVIDSTART) & (hcnt_1x < H_AVIDSTART+H_ACTIVE)) & ((vcnt_1x >= V_AVIDSTART) & (vcnt_1x < V_AVIDSTART+V_ACTIVE));
    end
end

//Generate 2x signals for linedouble
always @(posedge pclk_2x or negedge reset_n)
begin
    if (!reset_n) begin
        hcnt_2x <= 0;
        vcnt_2x <= 0;
        line_out_idx_2x <= 0;
    end else begin
        if ((pclk_1x == 1'b0) & (line_change | frame_change)) begin  //aligned with posedge of pclk_1x
            hcnt_2x <= 0;
            line_out_idx_2x <= 0;
            if (frame_change)
                vcnt_2x <= -1;
            else if (line_change)
                vcnt_2x <= vcnt_2x + 1'b1;
        end else if (hcnt_2x == hmax[~line_idx]) begin
            hcnt_2x <= 0;
            line_out_idx_2x <= line_out_idx_2x + 1'b1;
        end else begin
            hcnt_2x <= hcnt_2x + 1'b1;
        end

        HSYNC_2x <= (hcnt_2x < H_SYNCLEN) ? `HSYNC_POL : ~`HSYNC_POL;
        VSYNC_2x <= (vcnt_2x < V_SYNCLEN) ? `VSYNC_POL : ~`VSYNC_POL;
        DE_2x <= ((hcnt_2x >= H_AVIDSTART) & (hcnt_2x < H_AVIDSTART+H_ACTIVE)) & ((vcnt_2x >= V_AVIDSTART) & (vcnt_2x < V_AVIDSTART+V_ACTIVE));
    end
end

always @(posedge pclk_5x or negedge reset_n)
begin
    if (!reset_n) begin
        hcnt_5x <= 0;
        vcnt_5x <= 0;
        line_out_idx_5x <= 0;
    end else begin
        if ((pclk_5x_cnt == 0) & (line_change | frame_change)) begin  //aligned with posedge of pclk_1x
            hcnt_5x <= 0;
            line_out_idx_5x <= 0;
            if (frame_change)
                vcnt_5x <= -1;
            else if (line_change)
                vcnt_5x <= vcnt_5x + 1'b1;
        end else if (hcnt_5x == hmax[~line_idx]) begin
            hcnt_5x <= 0;
            line_out_idx_5x <= line_out_idx_5x + 1'b1;
        end else begin
            hcnt_5x <= hcnt_5x + 1'b1;
        end

        //track pclk_5x alignment to pclk_1x rising edge (pclk_1x=1 @ 144deg & pclk_1x=0 @ 216deg & pclk_1x=0 @ 288deg)
        if (((pclk_1x_prevprev5x == 1'b1) & (pclk_1x_prev5x == 1'b0)) | (pclk_5x_cnt == 3'h4))
            pclk_5x_cnt <= 0;
        else
            pclk_5x_cnt <= pclk_5x_cnt + 1'b1;

        pclk_1x_prev5x <= pclk_1x;
        pclk_1x_prevprev5x <= pclk_1x_prev5x;

        HSYNC_5x <= (hcnt_5x < H_SYNCLEN) ? `HSYNC_POL : ~`HSYNC_POL;
        VSYNC_5x <= (vcnt_5x < V_SYNCLEN) ? `VSYNC_POL : ~`VSYNC_POL;
        DE_5x <= ((hcnt_5x >= H_AVIDSTART) & (hcnt_5x < H_AVIDSTART+H_ACTIVE)) & ((vcnt_5x >= V_AVIDSTART) & (vcnt_5x < V_AVIDSTART+V_ACTIVE));
    end
end

endmodule
