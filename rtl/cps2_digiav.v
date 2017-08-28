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

//`define VGAMODE
//`define TESTPATTERN

module cps2_digiav(
    input [3:0] R_in,
    input [3:0] G_in,
    input [3:0] B_in,
    input [3:0] F_in,
    input VSYNC_in,
    input HSYNC_in,
    input PCLK2x_in,
    input I2S_BCK,
    input I2S_WS,
    input I2S_DATA,
    input BTN_volminus,
    input BTN_volplus,
    inout sda,
    output scl,
    output HDMI_TX_RST_N,
    output [7:0] HDMI_TX_RD,
    output [7:0] HDMI_TX_GD,
    output [7:0] HDMI_TX_BD,
    output HDMI_TX_DE,
    output HDMI_TX_HS,
    output HDMI_TX_VS,
    output HDMI_TX_PCLK,
    input HDMI_TX_INT_N,
    output HDMI_TX_I2S_DATA,
    output HDMI_TX_I2S_BCK,
    output HDMI_TX_I2S_WS,
    output HDMI_TX_I2S_MCLK
);

wire reset_n;
wire [2:0] pclk_lock;
wire [2:0] pll_lock_lost;
wire [31:0] x_info;

wire [7:0] R_out, G_out, B_out;
wire HSYNC_out;
wire VSYNC_out;
wire PCLK_out;
wire DATA_enable;

wire clk25, pclk_5x, pclk_hdtv;
wire pclk_ext = clk25;

wire I2S_WS_2x;
wire I2S_DATA_2x;
wire I2S_BCK_OUT;
wire [7:0] clkcnt_out;
wire [10:0] h_ext;


reg [3:0] R_in_L, G_in_L, B_in_L, F_in_L;
reg HSYNC_in_L, VSYNC_in_L;

// Latch inputs syncronized to PCLKx2_in (negedge)
always @(negedge PCLK2x_in or negedge reset_n)
begin
    if (!reset_n) begin
        R_in_L <= 4'h0;
        G_in_L <= 4'h0;
        B_in_L <= 4'h0;
        F_in_L <= 4'h0;
        HSYNC_in_L <= 1'b0;
        VSYNC_in_L <= 1'b0;
    end else begin
        R_in_L <= R_in;
        G_in_L <= G_in;
        B_in_L <= B_in;
        F_in_L <= F_in;
        HSYNC_in_L <= HSYNC_in;
        VSYNC_in_L <= VSYNC_in;
    end
end


assign reset_n = 1'b1;

assign HDMI_TX_RST_N = reset_n;
assign HDMI_TX_DE = DATA_enable;
assign HDMI_TX_PCLK = PCLK_out;
assign HDMI_TX_HS = HSYNC_out;
assign HDMI_TX_VS = VSYNC_out;
assign HDMI_TX_I2S_DATA = I2S_DATA_2x;
assign HDMI_TX_I2S_BCK = I2S_BCK_OUT;
assign HDMI_TX_I2S_WS = I2S_WS_2x;
assign HDMI_TX_I2S_MCLK = 0;
assign HDMI_TX_RD = R_out;
assign HDMI_TX_GD = G_out;
assign HDMI_TX_BD = B_out;

sys sys_inst(
    .clk_clk                            (clk25),
    .reset_reset_n                      (reset_n),
    .pio_0_ctrl_in_export               ({BTN_volminus, BTN_volplus, 30'h0}),
    .pio_1_ctrl_out_export              (x_info),
    .i2c_opencores_0_export_scl_pad_io  (scl),
    .i2c_opencores_0_export_sda_pad_io  (sda)
);

scanconverter scanconverter_inst (
    .reset_n        (reset_n),
    .HSYNC_in       (HSYNC_in_L),
    .VSYNC_in       (VSYNC_in_L),
    .PCLK_in        (PCLK2x_in),
    .pclk_ext       (pclk_ext),
    .pclk_5x        (pclk_5x),
    .h_ext          (h_ext),
    .R_in           (R_in_L),
    .G_in           (G_in_L),
    .B_in           (B_in_L),
    .F_in           (F_in_L),
    .x_info         (x_info),
`ifdef TESTPATTERN
    .R_out          (),
    .G_out          (),
    .B_out          (),
`else
    .R_out          (R_out),
    .G_out          (G_out),
    .B_out          (B_out),
`endif
`ifdef VGAMODE
    .HSYNC_out      (),
    .VSYNC_out      (),
    .PCLK_out       (),
    .DATA_enable    (),
`else
    .HSYNC_out      (HSYNC_out),
    .VSYNC_out      (VSYNC_out),
    .PCLK_out       (PCLK_out),
    .DE_out         (DATA_enable),
`endif
    .pclk_lock      (pclk_lock),
    .pll_lock_lost  (pll_lock_lost)
);

pll_pclk pll_pclk_inst (
    .inclk0 ( PCLK2x_in ),
    .c0 ( clk25 ),
    .c1 ( pclk_5x ),
    .locked ( )
);

pll_pclk_hdtv pll_pclk_hdtv_inst (
    .inclk0 ( PCLK2x_in ),
    .c0 ( pclk_hdtv ),
    .locked ( )
);

`ifdef VGAMODE
videogen vg0 (
    .clk25          (pclk_ext),
    .reset_n        (reset_n),
    .HSYNC_in       (HSYNC_in_L),
    .VSYNC_in       (VSYNC_in_L),
    .HSYNC_out      (HSYNC_out),
    .VSYNC_out      (VSYNC_out),
    .PCLK_out       (PCLK_out),
    .ENABLE_out     (DATA_enable),
    .H_cnt          (h_ext),
`ifdef TESTPATTERN
    .R_out          (R_out),
    .G_out          (G_out),
    .B_out          (B_out)
`else
    .R_out          (),
    .G_out          (),
    .B_out          ()
`endif
);
`endif

i2s_upsampler upsampler0 (
    .reset_n        (reset_n),
    .I2S_BCK        (I2S_BCK),
    .I2S_BCK_OUT    (I2S_BCK_OUT),
    .I2S_WS         (I2S_WS),
    .I2S_DATA       (I2S_DATA),
    .I2S_WS_2x      (I2S_WS_2x),
    .I2S_DATA_2x    (I2S_DATA_2x),
    .clkcnt_out     (clkcnt_out)
);

endmodule
