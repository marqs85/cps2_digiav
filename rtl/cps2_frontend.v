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

module cps2_frontend (
    input PCLK_i,
    input [3:0] R_i,
    input [3:0] G_i,
    input [3:0] B_i,
    input [3:0] F_i,
    input HSYNC_i,
    input VSYNC_i,
    output reg [3:0] R_o,
    output reg [3:0] G_o,
    output reg [3:0] B_o,
    output reg [3:0] F_o,
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

localparam CPS2_H_TOTAL     = 512;
localparam CPS2_H_SYNCLEN   = 8'd36;
localparam CPS2_H_BACKPORCH = 9'd62;
localparam CPS2_H_ACTIVE    = 9'd384;

localparam CPS2_V_TOTAL     = 262;
localparam CPS2_V_SYNCLEN   = 3'd3;
localparam CPS2_V_BACKPORCH = 6'd22;
localparam CPS2_V_ACTIVE    = 9'd224;

reg [8:0] h_ctr;
reg h_ctr_divctr;
reg [8:0] v_ctr;
reg HSYNC_i_prev, VSYNC_i_prev;

reg [3:0] R, G, B, F;
reg HSYNC, VSYNC;

wire [7:0] H_SYNCLEN = CPS2_H_SYNCLEN;
wire [8:0] H_BACKPORCH = CPS2_H_BACKPORCH;
wire [8:0] H_ACTIVE = CPS2_H_ACTIVE;

wire [2:0] V_SYNCLEN = CPS2_V_SYNCLEN;
wire [5:0] V_BACKPORCH = CPS2_V_BACKPORCH;
wire [8:0] V_ACTIVE = CPS2_V_ACTIVE;

assign h_active = CPS2_H_ACTIVE;
assign v_active = CPS2_V_ACTIVE;
assign h_total = CPS2_H_TOTAL;
assign v_total = CPS2_V_TOTAL;
assign mclk_cfg_id = CPS2_MCLK_CFG;

always @(posedge PCLK_i) begin
    if (h_ctr_divctr) begin
        R <= R_i;
        G <= G_i;
        B <= B_i;
        F <= F_i;
    end

    HSYNC_i_prev <= HSYNC_i;

    if (HSYNC_i_prev & ~HSYNC_i) begin
        h_ctr <= 0;
        h_ctr_divctr <= 0;
        HSYNC <= 1'b0;

        if (VSYNC_i_prev & ~VSYNC_i) begin
            v_ctr <= 0;
            frame_change <= 1'b1;
            VSYNC <= 1'b0;
        end else begin
            v_ctr <= v_ctr + 1'b1;
            frame_change <= 1'b0;
            if (v_ctr == V_SYNCLEN-1)
                VSYNC <= 1'b1;
        end

        VSYNC_i_prev <= VSYNC_i;
    end else begin
        if (h_ctr_divctr) begin
            h_ctr <= h_ctr + 1'b1;
            if (h_ctr == H_SYNCLEN-1)
                HSYNC <= 1'b1;
        end
        h_ctr_divctr <= h_ctr_divctr + 1'b1;
    end
end

always @(posedge PCLK_i) begin
    R_o <= R;
    G_o <= G;
    B_o <= B;
    F_o <= F;
    HSYNC_o <= HSYNC;
    VSYNC_o <= VSYNC;

    DE_o <= (h_ctr >= H_SYNCLEN+H_BACKPORCH) & (h_ctr < H_SYNCLEN+H_BACKPORCH+H_ACTIVE) & (v_ctr >= V_SYNCLEN+V_BACKPORCH) & (v_ctr < V_SYNCLEN+V_BACKPORCH+V_ACTIVE);
    xpos <= (h_ctr-H_SYNCLEN-H_BACKPORCH);
    ypos <= (v_ctr-V_SYNCLEN-V_BACKPORCH);
end

endmodule
