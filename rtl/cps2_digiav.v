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

//`define I2S_UPSAMPLE_2X

module cps2_digiav(
    input [3:0] R_in,
    input [3:0] G_in,
    input [3:0] B_in,
    input [3:0] F_in,
    input VSYNC_in,
    input HSYNC_in,
    input PCLK2x_in,
    input MCLK_SI,
    input PCLK_SI,
    input I2S_BCK,
    input I2S_WS,
    input I2S_DATA,
    input BTN_volminus,
    input BTN_volplus,
    inout sda,
    output scl,
    //output HDMI_TX_RST_N,
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
    output HDMI_TX_I2S_WS
    //output HDMI_TX_I2S_MCLK
);

reg reset_n = 1'b0;
reg [3:0] reset_n_ctr;

reg [3:0] R_in_L, G_in_L, B_in_L, F_in_L;
reg HSYNC_in_L, VSYNC_in_L;

wire [7:0] R_out, G_out, B_out;
wire HSYNC_out;
wire VSYNC_out;
wire PCLK_out;
wire DE_out;

wire pll_locked;
wire clk25;

wire I2S_WS_2x;
wire I2S_DATA_2x;
wire I2S_BCK_out;
wire [7:0] clkcnt_out;

wire [31:0] h_in_config, h_in_config2, v_in_config, h_out_config, h_out_config2, v_out_config, v_out_config2, xy_out_config;

wire BTN_volminus_debounced;
wire BTN_volplus_debounced;


// Latch inputs syncronized to PCLKx2_in (negedge)
always @(negedge PCLK2x_in)
begin
    R_in_L <= R_in;
    G_in_L <= G_in;
    B_in_L <= B_in;
    F_in_L <= F_in;
    HSYNC_in_L <= HSYNC_in;
    VSYNC_in_L <= VSYNC_in;
end

always @(posedge PCLK2x_in) begin
    if (reset_n_ctr == 4'hf)
        reset_n <= 1'b1;
    else if (pll_locked)
        reset_n_ctr <= reset_n_ctr + 1'b1;
end

// CPS2 frontend
wire [15:0] CPS_data_post;
wire CPS_HSYNC_post, CPS_VSYNC_post, CPS_DE_post;
wire CPS_fe_frame_change;
wire [8:0] CPS_fe_xpos, CPS_fe_ypos;
cps2_frontend u_cps2_frontend ( 
    .PCLK_i(PCLK2x_in),
    .R_i(R_in_L),
    .G_i(G_in_L),
    .B_i(B_in_L),
    .F_i(F_in_L),
    .HSYNC_i(HSYNC_in_L),
    .VSYNC_i(VSYNC_in_L),
    .R_o(CPS_data_post[15:12]),
    .G_o(CPS_data_post[11:8]),
    .B_o(CPS_data_post[7:4]),
    .F_o(CPS_data_post[3:0]),
    .HSYNC_o(CPS_HSYNC_post),
    .VSYNC_o(CPS_VSYNC_post),
    .DE_o(CPS_DE_post),
    .xpos(CPS_fe_xpos),
    .ypos(CPS_fe_ypos),
    .frame_change(CPS_fe_frame_change)
);

//assign HDMI_TX_RST_N = reset_n;
assign HDMI_TX_DE = DE_out;
assign HDMI_TX_PCLK = PCLK_out;
assign HDMI_TX_HS = HSYNC_out;
assign HDMI_TX_VS = VSYNC_out;
assign HDMI_TX_I2S_DATA = I2S_DATA_2x;
assign HDMI_TX_I2S_BCK = I2S_BCK_out;
assign HDMI_TX_I2S_WS = I2S_WS_2x;
//assign HDMI_TX_I2S_MCLK = 0;
assign HDMI_TX_RD = R_out;
assign HDMI_TX_GD = G_out;
assign HDMI_TX_BD = B_out;

sys sys_inst(
    .clk_clk                            (clk25),
    .reset_reset_n                      (reset_n),
    .pio_0_ctrl_in_export               ({BTN_volminus_debounced, BTN_volplus_debounced, 30'h0}),
    .i2c_opencores_0_export_scl_pad_io  (scl),
    .i2c_opencores_0_export_sda_pad_io  (sda),
    .sc_config_0_sc_if_sc_status_i          (32'h0),
    .sc_config_0_sc_if_sc_status2_i         (32'h0),
    .sc_config_0_sc_if_lt_status_i          (32'h00000000),
    .sc_config_0_sc_if_h_in_config_o        (h_in_config),
    .sc_config_0_sc_if_h_in_config2_o       (h_in_config2),
    .sc_config_0_sc_if_v_in_config_o        (v_in_config),
    .sc_config_0_sc_if_misc_config_o        (),
    .sc_config_0_sc_if_sl_config_o          (),
    .sc_config_0_sc_if_sl_config2_o         (),
    .sc_config_0_sc_if_h_out_config_o       (h_out_config),
    .sc_config_0_sc_if_h_out_config2_o      (h_out_config2),
    .sc_config_0_sc_if_v_out_config_o       (v_out_config),
    .sc_config_0_sc_if_v_out_config2_o      (v_out_config2),
    .sc_config_0_sc_if_xy_out_config_o      (xy_out_config),
);

scanconverter scanconverter_inst (
    .PCLK_CAP_i(PCLK2x_in),
    .PCLK_OUT_i(PCLK_SI),
    .reset_n(reset_n),
    .DATA_i(CPS_data_post),
    .HSYNC_i(CPS_HSYNC_post),
    .VSYNC_i(CPS_VSYNC_post),
    .DE_i(CPS_DE_post),
    .FID_i(1'b0),
    .frame_change_i(CPS_fe_frame_change),
    .xpos_i(CPS_fe_xpos),
    .ypos_i(CPS_fe_ypos),
    .h_out_config(h_out_config),
    .h_out_config2(h_out_config2),
    .v_out_config(v_out_config),
    .v_out_config2(v_out_config2),
    .xy_out_config(xy_out_config),
    .misc_config(32'h0),
    .sl_config(32'h0),
    .sl_config2(32'h0),
    .testpattern_enable(1'b0),
    .PCLK_o(PCLK_out),
    .R_o(R_out),
    .G_o(G_out),
    .B_o(B_out),
    .HSYNC_o(HSYNC_out),
    .VSYNC_o(VSYNC_out),
    .DE_o(DE_out),
    .xpos_o(),
    .ypos_o(),
    .resync_strobe()
);

pll_pclk pll_pclk_inst (
    .inclk0 ( PCLK2x_in ),
    .c0 ( clk25 ),
    .locked ( pll_locked )
);

`ifdef I2S_UPSAMPLE_2X
i2s_upsampler_2x upsampler0 (
    .reset_n        (reset_n),
    .I2S_BCK        (I2S_BCK),
    .I2S_WS         (I2S_WS),
    .I2S_DATA       (I2S_DATA),
    .I2S_BCK_out    (I2S_BCK_out),
    .I2S_WS_out     (I2S_WS_2x),
    .I2S_DATA_out   (I2S_DATA_2x),
    .clkcnt_out     (clkcnt_out)
);
`else
i2s_upsampler_asrc upsampler0 (
    .AMCLK_i        (MCLK_SI),
    .nARST          (reset_n),
    .ASCLK_i        (I2S_BCK),
    .ASDATA_i       (I2S_DATA),
    .ALRCLK_i       (I2S_WS),
    .ASCLK_o        (I2S_BCK_out),
    .ASDATA_o       (I2S_DATA_2x),
    .ALRCLK_o       (I2S_WS_2x)
);
`endif

btn_debounce #(.MIN_PULSE_WIDTH(25000)) deb0 (
    .i_clk          (clk25),
    .i_btn          (BTN_volminus),
    .o_btn          (BTN_volminus_debounced)
);

btn_debounce #(.MIN_PULSE_WIDTH(25000)) deb1 (
    .i_clk          (clk25),
    .i_btn          (BTN_volplus),
    .o_btn          (BTN_volplus_debounced)
);

endmodule
