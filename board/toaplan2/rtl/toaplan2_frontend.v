//
// Copyright (C) 2020  Markus Hiienkari <mhiienka@niksula.hut.fi>
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

module toaplan2_frontend (
    input PCLK2x_i,
    input [4:0] R_i,
    input [4:0] G_i,
    input [4:0] B_i,
    input CSYNC_i,
    output reg [4:0] R_o,
    output reg [4:0] G_o,
    output reg [4:0] B_o,
    output reg HSYNC_o,
    output reg VSYNC_o,
    output reg DE_o,
    output reg [8:0] xpos,
    output reg [8:0] ypos,
    output reg frame_change,
    output [9:0] h_active,
    output [9:0] v_active,
    output reg [9:0] h_total,
    output reg [9:0] v_total,
    output [4:0] mclk_cfg_id
);

`include "mclk_cfg_ids.vh"

localparam TP2_H_TOTAL     = 432;
localparam TP2_H_SYNCLEN   = 8'd32;
localparam TP2_H_BACKPORCH = 9'd55;
localparam TP2_H_ACTIVE    = 9'd320;

localparam TP2_V_TOTAL     = 263;
localparam TP2_V_SYNCLEN   = 3'd3;
localparam TP2_V_BACKPORCH = 6'd18;
localparam TP2_V_ACTIVE    = 9'd240;

reg [8:0] h_ctr;
reg h_ctr_divctr;
reg [8:0] v_ctr;
reg CSYNC_i_prev;

reg HSYNC, VSYNC;

wire [7:0] H_SYNCLEN = TP2_H_SYNCLEN;
wire [8:0] H_BACKPORCH = TP2_H_BACKPORCH;
wire [8:0] H_ACTIVE = TP2_H_ACTIVE;

wire [2:0] V_SYNCLEN = TP2_V_SYNCLEN;
wire [5:0] V_BACKPORCH = TP2_V_BACKPORCH;
wire [8:0] V_ACTIVE = TP2_V_ACTIVE;

assign h_active = TP2_H_ACTIVE;
assign v_active = TP2_V_ACTIVE;
assign h_total = TP2_H_TOTAL;
assign v_total = TP2_V_TOTAL;
assign mclk_cfg_id = TP2_MCLK_CFG;

always @(posedge PCLK2x_i) begin
    if (h_ctr_divctr == 1'b0) begin
        R_o <= R_i;
        G_o <= G_i;
        B_o <= B_i;
    end

    CSYNC_i_prev <= CSYNC_i;

    if ((CSYNC_i_prev & ~CSYNC_i) | ((h_ctr==TP2_H_TOTAL-1) & h_ctr_divctr)) begin
        h_ctr <= 0;
        h_ctr_divctr <= 0;
        HSYNC <= 1'b0;

        if (~CSYNC_i_prev & (v_ctr >= 16)) begin
            v_ctr <= 0;
            frame_change <= 1'b1;
            VSYNC <= 1'b0;
        end else begin
            v_ctr <= v_ctr + 1'b1;
            frame_change <= 1'b0;
            if (v_ctr == V_SYNCLEN-1)
                VSYNC <= 1'b1;
        end
    end else begin
        if (h_ctr_divctr == 1'b1) begin
            h_ctr <= h_ctr + 1'b1;
            if (h_ctr == H_SYNCLEN-1)
                HSYNC <= 1'b1;
        end
        h_ctr_divctr <= h_ctr_divctr + 1'b1;
    end
end

always @(posedge PCLK2x_i) begin
    HSYNC_o <= HSYNC;
    VSYNC_o <= VSYNC;
    DE_o <= (h_ctr >= H_SYNCLEN+H_BACKPORCH) & (h_ctr < H_SYNCLEN+H_BACKPORCH+H_ACTIVE) & (v_ctr >= V_SYNCLEN+V_BACKPORCH) & (v_ctr < V_SYNCLEN+V_BACKPORCH+V_ACTIVE);
    xpos <= (h_ctr-H_SYNCLEN-H_BACKPORCH);
    ypos <= (v_ctr-V_SYNCLEN-V_BACKPORCH);
end

endmodule
