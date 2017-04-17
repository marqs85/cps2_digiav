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

`define LINEMULT_DISABLE        2'h0
`define LINEMULT_DOUBLE         2'h1
`define LINEMULT_5x             2'h2

`define VSYNC_LEADING_EDGE      ((prev_vs == `HI) & (VSYNC_in == `LO))
`define VSYNC_TRAILING_EDGE     ((prev_vs == `LO) & (VSYNC_in == `HI))

`define HSYNC_LEADING_EDGE      ((prev_hs == `HI) & (HSYNC_in == `LO))
`define HSYNC_TRAILING_EDGE     ((prev_hs == `LO) & (HSYNC_in == `HI))

module scanconverter (
    input [3:0] R_in,
    input [3:0] G_in,
    input [3:0] B_in,
    input [3:0] F_in,
    input VSYNC_in,
    input HSYNC_in,
    input PCLK_in,
    input pclk_ext,
    input [10:0] h_ext,
    input [31:0] h_info,
    input [31:0] v_info,
    output reg [7:0] R_out,
    output reg [7:0] G_out,
    output reg [7:0] B_out,
    output reg HSYNC_out,
    output reg VSYNC_out,
    output PCLK_out,
    output reg DE_out,
    output [2:0] pclk_lock,
    output [2:0] pll_lock_lost,
    output [10:0] lines_out
);

wire pclk_1x, pclk_2x, pclk_5x;
wire linebuf_rdclock;

wire pclk_act;
wire [1:0] slid_act;

wire pclk_2x_lock;

wire HSYNC_act, VSYNC_act;
reg HSYNC_1x, HSYNC_2x, HSYNC_5x, HSYNC_pp1;
reg VSYNC_1x, VSYNC_2x, VSYNC_5x, VSYNC_pp1;

reg [11:0] HSYNC_start;

wire DE_act;
reg DE_pp1;

wire [11:0] linebuf_hoffset; //Offset for line (max. 2047 pixels), MSB indicates which line is read/written
wire [11:0] hcnt_act;
reg [11:0] hcnt_1x, hcnt_2x, hcnt_5x;

wire [10:0] vcnt_act;
reg [10:0] vcnt_1x, vcnt_2x, vcnt_2x_ref, vcnt_5x, vcnt_5x_ref, lines_1x, lines_2x, lines_5x;        //max. 2047

reg DE_1x, DE_2x, DE_5x;

reg [1:0] line_out_idx_2x;
reg [2:0] line_out_idx_5x;

reg pclk_1x_prev5x;
reg pclk_1x_prevprev5x;
reg [2:0] pclk_5x_cnt;

reg prev_hs, prev_vs;
reg [11:0] hmax[0:1];
reg line_idx;

reg [23:0] warn_h_unstable, warn_pll_lock_lost;

reg [10:0] H_ACTIVE;    //max. 2047
reg [7:0] H_BACKPORCH;  //max. 255
reg [10:0] V_ACTIVE;    //max. 2047
reg [5:0] V_BACKPORCH;  //max. 63
reg V_MISMODE;
reg V_SCANLINES;
reg V_SCANLINEDIR;
reg V_SCANLINEID;
reg [7:0] V_SCANLINESTR;
reg [5:0] V_MASK;
reg [1:0] H_LINEMULT;
reg [7:0] H_SYNCLEN;
reg [3:0] V_SYNCLEN;
reg [5:0] H_MASK;

//8 bits per component -> 16.7M colors
reg [3:0] R_1x, G_1x, B_1x, F_1x, R_2x, G_2x, B_2x, F_2x, R_5x, G_5x, B_5x, F_5x;
reg [7:0] R_pp1, G_pp1, B_pp1;
wire [3:0] R_lbuf, G_lbuf, B_lbuf, F_lbuf;
wire [3:0] R_act, G_act, B_act, F_act;


assign pclk_1x = PCLK_in;
assign pclk_lock = {pclk_2x_lock, 2'b11};

assign PCLK_out = pclk_act;

assign lines_out = lines_5x;

//Scanline generation
function [7:0] apply_scanlines;
    input enable;
    input dir;
    input [7:0] data;
    input [7:0] str;
    input [1:0] actid;
    input [1:0] lineid;
    input pixid;
    begin
        if (enable & (dir == 1'b0) & (actid == lineid))
            apply_scanlines = (data > str) ? (data-str) : 8'h00;
        else if (enable & (dir == 1'b1) & (actid == pixid))
            apply_scanlines = (data > str) ? (data-str) : 8'h00;
        else
            apply_scanlines = data;
    end
    endfunction

//Border masking
function [7:0] apply_mask;
    input enable;
    input [7:0] data;
    input [11:0] hoffset;
    input [11:0] hstart;
    input [11:0] hend;
    input [10:0] voffset;
    input [10:0] vstart;
    input [10:0] vend;
    begin
        if (enable & (/*(hoffset < hstart) | (hoffset >= hend) | */(voffset < vstart) | (voffset >= vend)))
            apply_mask = 8'h00;
        else
            apply_mask = data;
    end
    endfunction


//Mux for active data selection
//
//Non-critical signals and inactive clock combinations filtered out in SDC
always @(*)
begin
    case (H_LINEMULT)
    `LINEMULT_DISABLE: begin
        R_act = R_lbuf;
        G_act = G_lbuf;
        B_act = B_lbuf;
        DE_act = DE_1x;
        HSYNC_act = HSYNC_1x;
        VSYNC_act = VSYNC_1x;
        linebuf_rdclock = pclk_ext;
        linebuf_hoffset = ((6*{2'b00, h_ext})/5)+24;
        pclk_act = pclk_ext;
        slid_act = {1'b0, vcnt_1x[0]};
        hcnt_act = hcnt_1x;
        vcnt_act = vcnt_1x;
    end
    `LINEMULT_DOUBLE: begin
        R_act = R_2x;
        G_act = G_2x;
        B_act = B_2x;
        DE_act = DE_2x;
        HSYNC_act = HSYNC_2x;
        VSYNC_act = VSYNC_2x;
        linebuf_rdclock = pclk_2x;
        linebuf_hoffset = hcnt_2x;
        pclk_act = pclk_2x;
        slid_act = {1'b0, vcnt_2x[0]};
        hcnt_act = hcnt_2x;
        vcnt_act = vcnt_2x_ref;
    end
    `LINEMULT_5x: begin
        R_act = R_5x;
        G_act = G_5x;
        B_act = B_5x;
        DE_act = DE_5x;
        HSYNC_act = HSYNC_5x;
        VSYNC_act = VSYNC_5x;
        linebuf_rdclock = pclk_5x;
        linebuf_hoffset = hcnt_5x;
        pclk_act = pclk_5x;
        slid_act = {1'b0, vcnt_2x[0]};
        hcnt_act = hcnt_5x;
        vcnt_act = vcnt_5x_ref;
    end
    default: begin
        R_act = 0;
        G_act = 0;
        B_act = 0;
        DE_act = 0;
        HSYNC_act = 0;
        VSYNC_act = VSYNC_1x;
        linebuf_rdclock = 0;
        linebuf_hoffset = 0;
        pclk_act = 0;
        slid_act = 0;
        hcnt_act = 0;
        vcnt_act = 0;
    end
    endcase
end

pll_2x pll_linedouble (
    .areset ( 1'b0 ),
    .inclk0 ( PCLK_in ),
    .c0 ( pclk_2x ),
    .c1 ( pclk_5x ),
    .locked ( pclk_2x_lock )
);

linebuf	linebuf_rgb (
    .data ( {R_1x, G_1x, B_1x, F_1x} ), //or *_in?
    .rdaddress ( linebuf_hoffset + (~line_idx << 11) ),
    .rdclock ( linebuf_rdclock ),
    .wraddress ( hcnt_1x + (line_idx << 11) ),
    .wrclock ( pclk_1x ),
    .wren ( 1'b1 ),
    .q ( {R_lbuf, G_lbuf, B_lbuf, F_lbuf} )
);

//Postprocess pipeline
always @(posedge pclk_act /*or negedge reset_n*/)
begin
    /*if (!reset_n)
        begin
        end
    else*/
        begin
            R_pp1 <= apply_mask(1, {R_act, 4'h0}, hcnt_act, H_BACKPORCH+H_MASK, H_BACKPORCH+H_ACTIVE-H_MASK, vcnt_act, V_BACKPORCH+V_MASK, V_BACKPORCH+V_ACTIVE-V_MASK);
            G_pp1 <= apply_mask(1, {G_act, 4'h0}, hcnt_act, H_BACKPORCH+H_MASK, H_BACKPORCH+H_ACTIVE-H_MASK, vcnt_act, V_BACKPORCH+V_MASK, V_BACKPORCH+V_ACTIVE-V_MASK);
            B_pp1 <= apply_mask(1, {B_act, 4'h0}, hcnt_act, H_BACKPORCH+H_MASK, H_BACKPORCH+H_ACTIVE-H_MASK, vcnt_act, V_BACKPORCH+V_MASK, V_BACKPORCH+V_ACTIVE-V_MASK);
            HSYNC_pp1 <= HSYNC_act;
            VSYNC_pp1 <= VSYNC_act;
            DE_pp1 <= DE_act;
            
            R_out <= apply_scanlines(V_SCANLINES, V_SCANLINEDIR, R_pp1, V_SCANLINESTR, {1'b0, V_SCANLINEID}, slid_act, hcnt_act[0]);
            G_out <= apply_scanlines(V_SCANLINES, V_SCANLINEDIR, G_pp1, V_SCANLINESTR, {1'b0, V_SCANLINEID}, slid_act, hcnt_act[0]);
            B_out <= apply_scanlines(V_SCANLINES, V_SCANLINEDIR, B_pp1, V_SCANLINESTR, {1'b0, V_SCANLINEID}, slid_act, hcnt_act[0]);
            HSYNC_out <= HSYNC_pp1;
            VSYNC_out <= VSYNC_pp1;
            DE_out <= DE_pp1;
        end
end

//Generate a warning signal from horizontal instability or PLL sync loss
always @(posedge pclk_1x /*or negedge reset_n*/)
begin
    /*if (!reset_n)
        begin
        end
    else*/
        begin
            if (hmax[0] != hmax[1])
                warn_h_unstable <= 1;
            else if (warn_h_unstable != 0)
                warn_h_unstable <= warn_h_unstable + 1'b1;
        
            if ((H_LINEMULT == `LINEMULT_DOUBLE) & ~pclk_2x_lock)
                warn_pll_lock_lost <= 1;
            else if (warn_pll_lock_lost != 0)
                warn_pll_lock_lost <= warn_pll_lock_lost + 1'b1;
        end
end

assign h_unstable = (warn_h_unstable != 0);
assign pll_lock_lost = {(warn_pll_lock_lost != 0), 2'b00};

//Buffer the inputs using input pixel clock and generate 1x signals
always @(posedge pclk_1x /*or negedge reset_n*/)
begin
    /*if (!reset_n)
        begin
        end
    else*/
        begin
            if (`HSYNC_LEADING_EDGE)
                begin
                    hcnt_1x <= 0;
                    hmax[line_idx] <= hcnt_1x;
                    line_idx <= line_idx ^ 1'b1;
                    vcnt_1x <= vcnt_1x + 1'b1;
                end
            else
                begin
                    hcnt_1x <= hcnt_1x + 1'b1;
                end

            if (`VSYNC_LEADING_EDGE) begin
                vcnt_1x <= 0;
                lines_1x <= vcnt_1x;
                
                /*H_ACTIVE <= 384*2;
                H_BACKPORCH <= 66*2;
                H_LINEMULT <= `LINEMULT_DOUBLE;
                H_SYNCLEN <= 31*2;
                H_MASK <= 0;
                V_SYNCLEN <= 3;
                V_ACTIVE <= 240;
                V_BACKPORCH <= 16;
                V_MISMODE <= 0;
                V_SCANLINES <= 0;
                V_SCANLINEDIR <= 0;
                V_SCANLINEID <= 0;
                V_SCANLINESTR <= 0;
                V_MASK <= 0;*/
                H_ACTIVE <= 960;
                H_BACKPORCH <= 20;
                H_LINEMULT <= `LINEMULT_DISABLE;
                H_SYNCLEN <= 20;
                V_SYNCLEN <= 3;
                H_MASK <= 0;
                V_ACTIVE <= /*216*/224;
                V_BACKPORCH <= 16+12;
                V_MISMODE <= 0;
                V_SCANLINES <= 0;
                V_SCANLINEDIR <= 0;
                V_SCANLINEID <= 0;
                V_SCANLINESTR <= 0;
                V_MASK <= 0;
            end
            
            prev_hs <= HSYNC_in;
            prev_vs <= VSYNC_in;

            R_1x <= R_in;
            G_1x <= G_in;
            B_1x <= B_in;
            F_1x <= F_in;
            HSYNC_1x <= HSYNC_in;
            VSYNC_1x <= VSYNC_in;
            DE_1x <= ((hcnt_1x >= H_SYNCLEN+H_BACKPORCH) & (hcnt_1x < H_SYNCLEN+H_BACKPORCH + H_ACTIVE)) & ((vcnt_1x >= V_SYNCLEN+V_BACKPORCH) & (vcnt_1x < V_SYNCLEN+V_BACKPORCH + V_ACTIVE));
        end
end

//Generate 2x signals for linedouble
always @(posedge pclk_2x /*or negedge reset_n*/)
begin
    /*if (!reset_n)
        begin
        end
    else*/
        begin
            if ((pclk_1x == 1'b0) & `HSYNC_LEADING_EDGE) begin
                hcnt_2x <= 0;
                line_out_idx_2x <= 0;
                vcnt_2x <= vcnt_2x + 1'b1;
                vcnt_2x_ref <= vcnt_2x_ref + 1'b1;
            end else if (hcnt_2x == hmax[~line_idx]) begin
                hcnt_2x <= 0;
                line_out_idx_2x <= line_out_idx_2x + 1'b1;
                vcnt_2x <= vcnt_2x + 1'b1;
                /*if (line_out_idx_2x == 1)
                    vcnt_2x_ref <= vcnt_2x_ref + 1'b1;*/
            end else begin
                hcnt_2x <= hcnt_2x + 1'b1;
            end

            if ((pclk_1x == 1'b0) & `VSYNC_LEADING_EDGE) begin
                vcnt_2x <= 0;
                vcnt_2x_ref <= 0;
                lines_2x <= vcnt_2x;
            end

            R_2x <= R_lbuf;
            G_2x <= G_lbuf;
            B_2x <= B_lbuf;
            F_2x <= F_lbuf;
            HSYNC_2x <= ~(hcnt_2x < H_SYNCLEN);
            VSYNC_2x <= ~(vcnt_2x_ref < V_SYNCLEN);
            DE_2x <= ((hcnt_2x >= H_SYNCLEN+H_BACKPORCH) & (hcnt_2x < H_SYNCLEN+H_BACKPORCH + H_ACTIVE)) & ((vcnt_2x_ref >= V_SYNCLEN+V_BACKPORCH) & (vcnt_2x_ref < V_SYNCLEN+V_BACKPORCH + V_ACTIVE));
        end
end

always @(posedge pclk_5x /*or negedge reset_n*/)
begin
    /*if (!reset_n)
        begin
            hcnt_5x <= 0;
            vcnt_5x <= 0;
            vcnt_5x_ref <= 0;
            lines_5x <= 0;
            R_5x <= 8'h00;
            G_5x <= 8'h00;
            B_5x <= 8'h00;
        end
    else*/
        begin
            if ((pclk_5x_cnt == 0) & `HSYNC_LEADING_EDGE) begin
                hcnt_5x <= 0;
                line_out_idx_5x <= 0;
                vcnt_5x <= vcnt_5x + 1'b1;
                vcnt_5x_ref <= vcnt_5x_ref + 1'b1;
            end else if (hcnt_5x == hmax[~line_idx]) begin
                hcnt_5x <= 0;
                line_out_idx_5x <= line_out_idx_5x + 1'b1;
                vcnt_5x <= vcnt_5x + 1'b1;
                /*if (line_out_idx_5x == 4)
                    vcnt_5x_ref <= vcnt_5x_ref + 1'b1;*/
            end else begin
                hcnt_5x <= hcnt_5x + 1'b1;
            end
                
            if ((pclk_5x_cnt == 0) & `VSYNC_LEADING_EDGE) begin //aligned with posedge of pclk_1x
                vcnt_5x <= 0;
                vcnt_5x_ref <= 0;
                lines_5x <= vcnt_5x_ref;
            end
            
            //track pclk_5x alignment to pclk_1x rising edge (pclk_1x=1 @ 144deg & pclk_1x=0 @ 216deg & pclk_1x=0 @ 288deg)
            if (((pclk_1x_prevprev5x == 1'b1) & (pclk_1x_prev5x == 1'b0)) | (pclk_5x_cnt == 3'h4))
                pclk_5x_cnt <= 0;
            else
                pclk_5x_cnt <= pclk_5x_cnt + 1'b1;
                
            pclk_1x_prev5x <= pclk_1x;
            pclk_1x_prevprev5x <= pclk_1x_prev5x;
            
            
            R_5x <= R_lbuf;
            G_5x <= G_lbuf;
            B_5x <= B_lbuf;
            HSYNC_5x <= ~(hcnt_5x < H_SYNCLEN);
            VSYNC_5x <= ~(vcnt_5x_ref < V_SYNCLEN);
            DE_5x <= ((hcnt_5x >= H_SYNCLEN+H_BACKPORCH) & (hcnt_5x < H_SYNCLEN+H_BACKPORCH + H_ACTIVE)) & ((vcnt_5x_ref >= V_SYNCLEN+V_BACKPORCH) & (vcnt_5x_ref < V_SYNCLEN+V_BACKPORCH + V_ACTIVE));
        end
end

endmodule
