//
// Copyright (C) 2016-2018  Markus Hiienkari <mhiienka@niksula.hut.fi>
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

`define TRUE                    1'b1
`define FALSE                   1'b0
`define HI                      1'b1
`define LO                      1'b0

`define HSYNC_POL               `LO
`define VSYNC_POL               `LO

`define SCANLINES_OFF           2'h0
`define SCANLINES_H             2'h1
`define SCANLINES_V             2'h2

`define HSYNC_LEADING_EDGE      ((HSYNC_in_L == `HI) & (HSYNC_in == `LO))
`define VSYNC_LEADING_EDGE      ((VSYNC_in_L == `HI) & (VSYNC_in == `LO))

`define EXT_H_AVIDSTART         144

`define CPS2_H_AVIDSTART        97
`define CPS2_H_ACTIVE           384

`define NUM_LINE_BUFFERS        40

module scanconverter (
    input PCLK_in,
    input PCLK_ext,
    input reset_n,
    input [3:0] R_in,
    input [3:0] G_in,
    input [3:0] B_in,
    input [3:0] F_in,
    input HSYNC_in,
    input VSYNC_in,
    input [10:0] hcnt_ext,
    input [10:0] vcnt_ext,
    input [8:0] hcnt_ext_lbuf,
    input [5:0] vcnt_ext_lbuf,
    input HSYNC_ext,
    input VSYNC_ext,
    input DE_ext,
    input [31:0] x_info,
    output PCLK_out,
    output reg [7:0] R_out,
    output reg [7:0] G_out,
    output reg [7:0] B_out,
    output reg HSYNC_out,
    output reg VSYNC_out,
    output reg DE_out
);

//clock-related signals
wire pclk_1x;
wire linebuf_rdclock;

//RGB signals&registers: 4 bits per component + 4 bit fade
wire [3:0] R_act, G_act, B_act, F_act;
wire [3:0] R_lbuf, G_lbuf, B_lbuf, F_lbuf;
reg [3:0] R_in_L, G_in_L, B_in_L, F_in_L;
reg [7:0] R_pp1, G_pp1, B_pp1, R_pp2, G_pp2, B_pp2, R_pp3, G_pp3, B_pp3, R_pp4, G_pp4, B_pp4;

//H+V syncs + data enable signals&registers
wire HSYNC_act, VSYNC_act, DE_act;
reg HSYNC_in_L, HSYNC_pp2, HSYNC_pp3, HSYNC_pp4;
reg VSYNC_in_L, VSYNC_pp2, VSYNC_pp3, VSYNC_pp4;
reg DE_pp2, DE_pp3, DE_pp4;

//registers indicating line/frame change
reg frame_change, line_change;

//H+V counters
wire [11:0] linebuf_hoffset; //Offset for line (max. 2047 pixels), MSB indicates which line is read/written
reg [11:0] hcnt_1x;
reg [10:0] vcnt_1x;

//other counters
wire [2:0] line_id_act, col_id_act;
reg [2:0] line_id_pp1, line_id_pp2, line_id_pp3, col_id_pp1, col_id_pp2, col_id_pp3;
reg [11:0] hmax[0:1];
reg [10:0] vmax;
reg [5:0] line_idx;
reg [1:0] line_out_idx_2x, line_out_idx_3x, line_out_idx_4x;
reg [2:0] line_out_idx_5x;
reg [23:0] warn_h_unstable, warn_pll_lock_lost, warn_pll_lock_lost_3x;
reg mask_enable_pp1, mask_enable_pp2, mask_enable_pp3, mask_enable_pp4;

reg [1:0] V_SCANLINEMODE;
reg [4:0] V_SCANLINEID;
reg [3:0] X_MASK_BR;
reg [7:0] X_SCANLINESTR;

assign PCLK_out = PCLK_ext;

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
always @(*) begin
        R_act = R_lbuf;
        G_act = G_lbuf;
        B_act = B_lbuf;
        F_act = F_lbuf;
        HSYNC_act = HSYNC_ext;
        VSYNC_act = VSYNC_ext;
        DE_act = DE_ext;
        linebuf_hoffset = ((6*{2'b00, hcnt_ext})/5)-((6*`EXT_H_AVIDSTART)/5);
        line_id_act = {2'b0, vcnt_ext[0]};
end

//wire [9:0] linebuf_rdaddr = (linebuf_hoffset-H_AVIDSTART-96)>>1;
wire [9:0] linebuf_rdaddr = linebuf_hoffset>>1;
wire [9:0] linebuf_wraddr = (hcnt_1x>>1)-`CPS2_H_AVIDSTART;

linebuf linebuf_rgb (
    .data ( {R_in_L, G_in_L, B_in_L, F_in_L} ),
    .rdaddress ( {vcnt_ext_lbuf, hcnt_ext_lbuf} ),
    .rdclock ( PCLK_out ),
    .wraddress( {line_idx, linebuf_wraddr[8:0]} ),
    .wrclock ( PCLK_in ),
    .wren ( linebuf_wraddr < `CPS2_H_ACTIVE ),
    .q ( {R_lbuf, G_lbuf, B_lbuf, F_lbuf} )
);

//Postprocess pipeline
// h_cnt, v_cnt, line_id, col_id:   0
// HSYNC, VSYNC, DE:                1
// RGB:                             2
always @(posedge PCLK_out)
begin
    line_id_pp1 <= line_id_act;
    col_id_pp1 <= col_id_act;
    mask_enable_pp1 <= 0;

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

//Buffer the inputs using input pixel clock and generate 1x signals
always @(posedge PCLK_in or negedge reset_n)
begin
    if (!reset_n) begin
        hcnt_1x <= 0;
        vcnt_1x <= 0;
        line_idx <= 0;
        frame_change <= 1'b0;
    end else begin
        if (`HSYNC_LEADING_EDGE) begin
            hcnt_1x <= 0;
        end else begin
            hcnt_1x <= hcnt_1x + 1'b1;
        end

        if (`HSYNC_LEADING_EDGE) begin
            if ((VSYNC_in == `LO) & (vcnt_1x > 100)) begin
                vcnt_1x <= 0;
                frame_change <= 1'b1;
            end else begin
                vcnt_1x <= vcnt_1x + 1'b1;
                
                if ((vcnt_1x == 24) || (line_idx == `NUM_LINE_BUFFERS-1))
                    line_idx <= 0;
                else
                    line_idx <= line_idx + 1'b1;
            end
        end else
            frame_change <= 1'b0;

        if (frame_change) begin
            //Read configuration data from CPU
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
    end
end

endmodule
