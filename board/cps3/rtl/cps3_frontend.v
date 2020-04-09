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

module cps3_frontend (
    input PCLK_i,
    input [4:0] R_i,
    input [4:0] G_i,
    input [4:0] B_i,
    input HSYNC_i,
    input VSYNC_i,
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

localparam CPS3_ASP_STD         = 1'b0;
localparam CPS3_ASP_WIDE        = 1'b1;

localparam CPS3_H_TOTAL_STD     = 546;
localparam CPS3_H_SYNCLEN_STD   = 8'd51;
localparam CPS3_H_BACKPORCH_STD = 9'd68;
localparam CPS3_H_ACTIVE_STD    = 9'd384;

localparam CPS3_H_TOTAL_WIDE     = 682;
localparam CPS3_H_SYNCLEN_WIDE   = 8'd54;
localparam CPS3_H_BACKPORCH_WIDE = 9'd72;
localparam CPS3_H_ACTIVE_WIDE    = 9'd495;

localparam CPS3_V_TOTAL     = 264;
localparam CPS3_V_SYNCLEN   = 3'd3;
localparam CPS3_V_BACKPORCH = 6'd21;
localparam CPS3_V_ACTIVE    = 9'd224;

reg [9:0] h_ctr;
reg h_ctr_divctr;
reg [8:0] v_ctr;
reg HSYNC_i_prev, VSYNC_i_prev;

reg wide_mode;

reg [4:0] R, G, B /* synthesis ramstyle = "logic" */;
reg HSYNC, VSYNC;

wire [7:0] H_SYNCLEN = wide_mode ? CPS3_H_SYNCLEN_WIDE : CPS3_H_SYNCLEN_STD;
wire [8:0] H_BACKPORCH = wide_mode ? CPS3_H_BACKPORCH_WIDE : CPS3_H_BACKPORCH_STD;
wire [8:0] H_ACTIVE = wide_mode ? CPS3_H_ACTIVE_WIDE : CPS3_H_ACTIVE_STD;

wire [2:0] V_SYNCLEN = CPS3_V_SYNCLEN;
wire [5:0] V_BACKPORCH = CPS3_V_BACKPORCH;
wire [8:0] V_ACTIVE = CPS3_V_ACTIVE;

assign h_active = wide_mode ? CPS3_H_ACTIVE_WIDE : CPS3_H_ACTIVE_STD;
assign v_active = CPS3_V_ACTIVE;
assign mclk_cfg_id = CPS3_MCLK_CFG;

always @(posedge PCLK_i) begin
    R <= R_i;
    G <= G_i;
    B <= B_i;

    HSYNC_i_prev <= HSYNC_i;

    if (HSYNC_i_prev & ~HSYNC_i) begin
        h_ctr <= 0;
        HSYNC <= 1'b0;

        if (VSYNC_i_prev & ~VSYNC_i) begin
            v_ctr <= 0;
            frame_change <= 1'b1;
            VSYNC <= 1'b0;
            h_total <= h_ctr + 1'b1;
            v_total <= v_ctr + 1'b1;
            wide_mode <= (h_ctr == CPS3_H_TOTAL_WIDE-1'b1);
        end else begin
            v_ctr <= v_ctr + 1'b1;
            frame_change <= 1'b0;
            if (v_ctr == V_SYNCLEN-1)
                VSYNC <= 1'b1;
        end

        VSYNC_i_prev <= VSYNC_i;
    end else begin
        h_ctr <= h_ctr + 1'b1;
        if (h_ctr == H_SYNCLEN-1)
            HSYNC <= 1'b1;
    end
end

always @(posedge PCLK_i) begin
    R_o <= R;
    G_o <= G;
    B_o <= B;
    HSYNC_o <= HSYNC;
    VSYNC_o <= VSYNC;

    DE_o <= (h_ctr >= H_SYNCLEN+H_BACKPORCH) & (h_ctr < H_SYNCLEN+H_BACKPORCH+H_ACTIVE) & (v_ctr >= V_SYNCLEN+V_BACKPORCH) & (v_ctr < V_SYNCLEN+V_BACKPORCH+V_ACTIVE);
    xpos <= (h_ctr-H_SYNCLEN-H_BACKPORCH);
    ypos <= (v_ctr-V_SYNCLEN-V_BACKPORCH);
end

endmodule
