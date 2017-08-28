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

module videogen (
    input clk25,
    input reset_n,
    input HSYNC_in,
    input VSYNC_in,
    output [7:0] R_out,
    output [7:0] G_out,
    output [7:0] B_out,
    output reg HSYNC_out,
    output reg VSYNC_out,
    output PCLK_out,
    output reg ENABLE_out,
    output [10:0] H_cnt
);

//Parameters for 640x480@60Hz (800px x 524lines, pclk 25MHz -> 59.637Hz)

parameter   H_SYNCLEN       =   96;
parameter   H_BACKPORCH     =   48;
parameter   H_ACTIVE        =   640;
parameter   H_TOTAL         =   800;
parameter   V_SYNCLEN       =   6;
parameter   V_BACKPORCH     =   32;
parameter   V_ACTIVE        =   480;
parameter   V_TOTAL         =   524;

/*parameter   H_SYNCLEN       =   44;
parameter   H_BACKPORCH     =   188;
parameter   H_ACTIVE        =   1920;
parameter   H_TOTAL         =   2191;
parameter   V_SYNCLEN       =   5;
parameter   V_BACKPORCH     =   36;
parameter   V_ACTIVE        =   1080;
parameter   V_TOTAL         =   1125;*/

parameter   H_OVERSCAN      =   40; //at both sides
parameter   V_OVERSCAN      =   16; //top and bottom
parameter   H_AREA          =   640;
parameter   V_AREA          =   448;
parameter   H_BORDER        =   (H_AREA-512)/2;
parameter   V_BORDER        =   (V_AREA-256)/2;

parameter   X_START     =   H_SYNCLEN + H_BACKPORCH;
parameter   Y_START     =   V_SYNCLEN + V_BACKPORCH;

//Counters
reg [11:0] h_cnt; //max. 4096
reg [10:0] v_cnt; //max. 2048

assign PCLK_out = clk25;

reg prev_hs, prev_vs;
reg v_leadedge;

//R, G and B should be 0 outside of active area
assign R_out = ENABLE_out ? V_gen : 8'h00;
assign G_out = ENABLE_out ? V_gen : 8'h00;
assign B_out = ENABLE_out ? V_gen : 8'h00;

assign H_cnt = h_cnt;

reg [7:0] V_gen;
reg frameid;

//HSYNC gen (negative polarity)
always @(posedge clk25 or negedge reset_n)
begin
    if (!reset_n)
        begin
            h_cnt <= 0;
            HSYNC_out <= 0;
            prev_vs <= 0;
            v_leadedge <= 0;
        end
    else
        begin
            //Hsync counter
            if ((prev_vs == 1'b1) && (VSYNC_in == 1'b0))
                v_leadedge <= 1;
            else if ((v_leadedge == 1'b1) && (prev_hs == 1'b1) && (HSYNC_in == 1'b0))
                begin
                v_leadedge <= 0;
                h_cnt <= 0;
                end
            else if (h_cnt < H_TOTAL-1 )
                h_cnt <= h_cnt + 1;
            else
                h_cnt <= 0;
            
            //Hsync signal
            HSYNC_out <= (h_cnt < H_SYNCLEN) ? 0 : 1;
            
            prev_hs <= HSYNC_in;
            prev_vs <= VSYNC_in;
        end
end

//VSYNC gen (negative polarity)
always @(posedge clk25 or negedge reset_n)
begin
    if (!reset_n)
        begin
            v_cnt <= 0;
            VSYNC_out <= 0;
        end
    else
        begin
            if ((prev_vs == 1'b1) && (VSYNC_in == 1'b0)) begin
                v_cnt <= 0;
            end else if (h_cnt == 0)
                begin
                    //Vsync counter
                    if (v_cnt < V_TOTAL-1 )
                        v_cnt <= v_cnt + 1;
                    else
                        v_cnt <= 0;
                    
                    //Vsync signal
                    VSYNC_out <= (v_cnt < V_SYNCLEN) ? 0 : 1;
                end
        end
end

//Data gen
always @(posedge clk25 or negedge reset_n)
begin
    if (!reset_n)
        begin
            V_gen <= 8'h00;
        end
    else
        begin
            if ((h_cnt < X_START+H_OVERSCAN) || (h_cnt >= X_START+H_OVERSCAN+H_AREA) || (v_cnt < Y_START+V_OVERSCAN) || (v_cnt >= Y_START+V_OVERSCAN+V_AREA))
                V_gen <= (h_cnt[0] ^ v_cnt[0]) ? 8'hff : 8'h00;
            else if ((h_cnt < X_START+H_OVERSCAN+H_BORDER) || (h_cnt >= X_START+H_OVERSCAN+H_AREA-H_BORDER) || (v_cnt < Y_START+V_OVERSCAN+V_BORDER) || (v_cnt >= Y_START+V_OVERSCAN+V_AREA-V_BORDER))
                V_gen <= 8'h50;
            else
                V_gen <= (h_cnt - (X_START+H_OVERSCAN+H_BORDER)) >> 1;
            /*else
                V_gen <= 8'h00;*/
        end
end

//Enable gen
always @(posedge clk25 or negedge reset_n)
begin
    if (!reset_n)
        begin
            ENABLE_out <= 8'h00;
        end
    else
        begin
            ENABLE_out <= (h_cnt >= X_START && h_cnt < X_START + H_ACTIVE && v_cnt >= Y_START && v_cnt < Y_START + V_ACTIVE);
        end
end

endmodule
