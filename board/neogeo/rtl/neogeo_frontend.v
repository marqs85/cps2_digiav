//
// Copyright (C) 2021  Markus Hiienkari <mhiienka@niksula.hut.fi>
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

module neogeo_frontend (
    input VCLK_i,
    input [4:0] R_i,
    input [4:0] G_i,
    input [4:0] B_i,
    input DARK_i,
    input SHADOW_i,
    input CSYNC_i,
    output reg [4:0] R_o,
    output reg [4:0] G_o,
    output reg [4:0] B_o,
    output reg DARK_o,
    output reg HSYNC_o,
    output reg VSYNC_o,
    output reg DE_o,
    output reg [8:0] xpos,
    output reg [8:0] ypos,
    output reg frame_change,
    output [9:0] h_active,
    output [9:0] v_active,
    output reg [21:0] vclks_per_frame
);

localparam bit [9:0] NEO_H_TOTAL     = 384;
localparam bit [7:0] NEO_H_SYNCLEN   = 29;
localparam bit [8:0] NEO_H_BACKPORCH = 28;
localparam bit [8:0] NEO_H_ACTIVE    = 320;

localparam bit [9:0] NEO_V_TOTAL     = 264;
localparam bit [2:0] NEO_V_SYNCLEN   = 3;
localparam bit [5:0] NEO_V_BACKPORCH = 21;
localparam bit [8:0] NEO_V_ACTIVE    = 224;

reg [8:0] h_ctr;
reg h_ctr_divctr;
reg [8:0] v_ctr;
reg CSYNC_i_prev;

reg [3:0] equ_line_ctr;

reg [21:0] vclk_ctr;

reg HSYNC, VSYNC;

wire [7:0] H_SYNCLEN = NEO_H_SYNCLEN;
wire [8:0] H_BACKPORCH = NEO_H_BACKPORCH;
wire [8:0] H_ACTIVE = NEO_H_ACTIVE;

wire [2:0] V_SYNCLEN = NEO_V_SYNCLEN;
wire [5:0] V_BACKPORCH = NEO_V_BACKPORCH;
wire [8:0] V_ACTIVE = NEO_V_ACTIVE;

assign h_active = NEO_H_ACTIVE;
assign v_active = NEO_V_ACTIVE;

always @(posedge VCLK_i) begin
    if (SHADOW_i) begin
        R_o <= {1'b0, R_i[4:1]};
        G_o <= {1'b0, G_i[4:1]};
        B_o <= {1'b0, B_i[4:1]};
        DARK_o <= 1'b1;
    end else begin
        R_o <= R_i;
        G_o <= G_i;
        B_o <= B_i;
        DARK_o <= DARK_i;
    end

    CSYNC_i_prev <= CSYNC_i;

    if ((CSYNC_i_prev & ~CSYNC_i) & (h_ctr > (NEO_H_TOTAL/2))) begin
        h_ctr <= 0;
        HSYNC <= 1'b0;

        if ((v_ctr >= 16) & (equ_line_ctr >= 3)) begin
            v_ctr <= 0;
            frame_change <= 1'b1;
            vclks_per_frame <= vclk_ctr;
            vclk_ctr <= 1;
            equ_line_ctr <= 0;
            VSYNC <= 1'b0;
        end else begin
            v_ctr <= v_ctr + 1'b1;
            vclk_ctr <= vclk_ctr + 1'b1;
            frame_change <= 1'b0;
            if (v_ctr == V_SYNCLEN-1)
                VSYNC <= 1'b1;
        end
    end else begin
        h_ctr <= h_ctr + 1'b1;
        if (h_ctr == H_SYNCLEN-1)
            HSYNC <= 1'b1;

        vclk_ctr <= vclk_ctr + 1'b1;

        if (h_ctr == (NEO_H_TOTAL/2)) begin
            if (~CSYNC_i)
                equ_line_ctr <= equ_line_ctr + 1'b1;
            else
                equ_line_ctr <= 0;
        end
    end
end

always @(posedge VCLK_i) begin
    HSYNC_o <= HSYNC;
    VSYNC_o <= VSYNC;
    DE_o <= (h_ctr >= H_SYNCLEN+H_BACKPORCH) & (h_ctr < H_SYNCLEN+H_BACKPORCH+H_ACTIVE) & (v_ctr >= V_SYNCLEN+V_BACKPORCH) & (v_ctr < V_SYNCLEN+V_BACKPORCH+V_ACTIVE);
    xpos <= (h_ctr-H_SYNCLEN-H_BACKPORCH);
    ypos <= (v_ctr-V_SYNCLEN-V_BACKPORCH);
end

endmodule
