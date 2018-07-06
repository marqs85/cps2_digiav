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

`define NUM_LINE_BUFFERS        40

module syncgen (
    input PCLK,
    input reset_n,
    input HSYNC_ref,
    input VSYNC_ref,
    output reg HSYNC_out,
    output reg VSYNC_out,
    output reg DE_out,
    output reg [11:0] hcnt, //max. 4096
    output reg [10:0] vcnt, //max. 2048
    output reg [8:0] hcnt_lbuf,
    output reg [5:0] vcnt_lbuf
);

parameter   H_SYNCLEN       =   44;
parameter   H_BACKPORCH     =   148;
parameter   H_ACTIVE        =   1920;
parameter   H_TOTAL         =   2200;
parameter   V_SYNCLEN       =   5;
parameter   V_BACKPORCH     =   36;
parameter   V_ACTIVE        =   1080;
parameter   V_TOTAL         =   1125;

parameter   X_START     =   H_SYNCLEN + H_BACKPORCH;
parameter   Y_START     =   V_SYNCLEN + V_BACKPORCH;

parameter h_ctr_max = 3;
parameter v_ctr_max = 4;

parameter H_STARTPOS = 464-48;
parameter V_STARTPOS = 0;


reg [2:0] h_ctr, v_ctr;

reg prev_hs, prev_vs;
reg v_leadedge, v_leadedge_synced;

reg [7:0] V_gen;
reg frameid;

// HSYNC gen (negative polarity)
always @(posedge PCLK or negedge reset_n)
begin
    if (!reset_n) begin
        hcnt <= 0;
        hcnt_lbuf <= 0;
        HSYNC_out <= 0;
        prev_hs <= 1'b1;
        prev_vs <= 1'b1;
        v_leadedge <= 0;
        v_leadedge_synced <= 0;
    end else begin
        // Hsync counter
        if (!v_leadedge_synced && (prev_vs == 1'b1) && (VSYNC_ref == 1'b0)) begin
            v_leadedge <= 1;
        end else if ((v_leadedge == 1'b1) && (prev_hs == 1'b1) && (HSYNC_ref == 1'b0)) begin
            v_leadedge <= 0;
            v_leadedge_synced <= 1;
            hcnt <= 0;
            h_ctr <= 0;
            hcnt_lbuf <= H_STARTPOS;
        end else if (hcnt < H_TOTAL-1 ) begin
            hcnt <= hcnt + 1;
            h_ctr <= (h_ctr == h_ctr_max) ? 0 : (h_ctr + 1'b1);
            hcnt_lbuf <= (h_ctr == h_ctr_max) ? (hcnt_lbuf + 1'b1) : hcnt_lbuf;
        end else begin
            hcnt <= 0;
            h_ctr <= 0;
            hcnt_lbuf <= H_STARTPOS;
        end
        
        // Hsync signal
        HSYNC_out <= (hcnt < H_SYNCLEN) ? 0 : 1;
        
        prev_hs <= HSYNC_ref;
        prev_vs <= VSYNC_ref;
    end
end

// VSYNC gen (negative polarity)
always @(posedge PCLK or negedge reset_n)
begin
    if (!reset_n) begin
        vcnt <= 0;
        VSYNC_out <= 0;
    end else begin
        if (v_leadedge == 1'b1) begin
            vcnt <= 1054;
        end else if (hcnt == H_TOTAL-1) begin
            // Vsync counter
            if (vcnt < V_TOTAL-1 )
                vcnt <= vcnt + 1;
            else
                vcnt <= 0;
            
            if (vcnt == Y_START-1) begin
                vcnt_lbuf <= V_STARTPOS;
                v_ctr <= 0;
            end else if (v_ctr == v_ctr_max) begin
                if (vcnt_lbuf < `NUM_LINE_BUFFERS-1)
                    vcnt_lbuf <= (vcnt_lbuf + 1'b1);
                else
                    vcnt_lbuf <= 0;
                    
                v_ctr <= 0;
            end else begin
                v_ctr <= v_ctr + 1'b1;
            end

            // Vsync signal
            VSYNC_out <= (vcnt < V_SYNCLEN) ? 0 : 1;
        end
    end
end

// DE gen
always @(posedge PCLK or negedge reset_n)
begin
    if (!reset_n)
        DE_out <= 1'b0;
    else
        DE_out <= (hcnt >= X_START && hcnt < X_START + H_ACTIVE && vcnt >= Y_START && vcnt < Y_START + V_ACTIVE);
end

endmodule
