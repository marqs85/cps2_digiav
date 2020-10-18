//
// Copyright (C) 2016-2020  Markus Hiienkari <mhiienka@niksula.hut.fi>
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

module cps2_digiav(
    input [3:0] R_in,
    input [3:0] G_in,
    input [3:0] B_in,
    input [3:0] F_in,
    input CSYNC_in,
    input PCLK2x_in,
    input MCLK_SI,
    input PCLK_SI,
    input YM_o1,
    input YM_SH1,
    input YM_SO,
    input WM_SO,
    input BTN_volminus,
    input BTN_volplus,
    inout sda,
    output scl,
    //output HDMI_TX_RST_N,
    output reg [7:0] HDMI_TX_RD,
    output reg [7:0] HDMI_TX_GD,
    output reg [7:0] HDMI_TX_BD,
    output reg HDMI_TX_DE,
    output reg HDMI_TX_HS,
    output reg HDMI_TX_VS,
    output HDMI_TX_PCLK,
    input HDMI_TX_INT_N,
    output HDMI_TX_I2S_DATA,
    output HDMI_TX_I2S_BCK,
    output HDMI_TX_I2S_WS
    //output HDMI_TX_I2S_MCLK
);

reg reset_n = 1'b0;
reg [3:0] reset_n_ctr;

reg WM_LRCLK;

reg [3:0] R_in_L, G_in_L, B_in_L, F_in_L;
reg CSYNC_in_L;

reg [7:0] R_out, G_out, B_out;
reg HSYNC_out, VSYNC_out, DE_out;
wire PCLK_sc;
wire [7:0] R_sc, G_sc, B_sc;
wire HSYNC_sc, VSYNC_sc, DE_sc;

wire pll_locked;
wire clk25;

wire I2S_BCK_o, I2S_DATA_o, I2S_WS_o; 

wire [31:0] misc_config, sl_config, sl_config2, hv_out_config, hv_out_config2, hv_out_config3, xy_out_config, xy_out_config2, fe_status, fe_status2;

wire [10:0] xpos, ypos;
wire osd_enable;
wire [1:0] osd_color;

wire BTN_volminus_debounced;
wire BTN_volplus_debounced;


// Latch inputs syncronized to pixel clock
always @(posedge PCLK2x_in) begin
    R_in_L <= R_in;
    G_in_L <= G_in;
    B_in_L <= B_in;
    F_in_L <= F_in;
    CSYNC_in_L <= CSYNC_in;
end

always @(negedge YM_SH1) begin
    WM_LRCLK <= ~WM_LRCLK;
end

always @(posedge PCLK2x_in) begin
    if (reset_n_ctr == 4'hf)
        reset_n <= 1'b1;
    else if (pll_locked)
        reset_n_ctr <= reset_n_ctr + 1'b1;
end

// CPS1 frontend
wire [15:0] CPS_data_post;
wire CPS_HSYNC_post, CPS_VSYNC_post, CPS_DE_post;
wire CPS_fe_frame_change;
wire [8:0] CPS_fe_xpos, CPS_fe_ypos;
cps1_frontend u_cps1_frontend ( 
    .PCLK2x_i(PCLK2x_in),
    .R_i(R_in_L),
    .G_i(G_in_L),
    .B_i(B_in_L),
    .F_i(F_in_L),
    .CSYNC_i(CSYNC_in_L),
    .R_o(CPS_data_post[15:12]),
    .G_o(CPS_data_post[11:8]),
    .B_o(CPS_data_post[7:4]),
    .F_o(CPS_data_post[3:0]),
    .HSYNC_o(CPS_HSYNC_post),
    .VSYNC_o(CPS_VSYNC_post),
    .DE_o(CPS_DE_post),
    .xpos(CPS_fe_xpos),
    .ypos(CPS_fe_ypos),
    .frame_change(CPS_fe_frame_change),
    .h_active(fe_status[9:0]),
    .v_active(fe_status[19:10]),
    .vclks_per_frame(fe_status2[21:0])
);

//assign HDMI_TX_RST_N = reset_n;
assign HDMI_TX_PCLK = PCLK_sc;
assign HDMI_TX_I2S_DATA = I2S_DATA_o;
assign HDMI_TX_I2S_BCK = I2S_BCK_o;
assign HDMI_TX_I2S_WS = I2S_WS_o;
//assign HDMI_TX_I2S_MCLK = 0;

always @(posedge PCLK_sc) begin
    if (osd_enable) begin
        if (osd_color == 2'h0) begin
            {R_out, G_out, B_out} <= 24'h000000;
        end else if (osd_color == 2'h1) begin
            {R_out, G_out, B_out} <= 24'h0000ff;
        end else if (osd_color == 2'h2) begin
            {R_out, G_out, B_out} <= 24'hffff00;
        end else begin
            {R_out, G_out, B_out} <= 24'hffffff;
        end
    end else begin
        {R_out, G_out, B_out} <= {R_sc, G_sc, B_sc};
    end

    HSYNC_out <= HSYNC_sc;
    VSYNC_out <= VSYNC_sc;
    DE_out <= DE_sc;
end

always @(negedge PCLK_sc) begin
    HDMI_TX_RD <= R_out;
    HDMI_TX_GD <= G_out;
    HDMI_TX_BD <= B_out;
    HDMI_TX_HS <= HSYNC_out;
    HDMI_TX_VS <= VSYNC_out;
    HDMI_TX_DE <= DE_out;
end

sys sys_inst(
    .clk_clk                            (clk25),
    .reset_reset_n                      (reset_n),
    .pio_0_ctrl_in_export               ({BTN_volminus_debounced, BTN_volplus_debounced, 30'h0}),
    .i2c_opencores_0_export_scl_pad_io  (scl),
    .i2c_opencores_0_export_sda_pad_io  (sda),
    .sc_config_0_sc_if_fe_status_i          (fe_status),
    .sc_config_0_sc_if_fe_status2_i         (fe_status2),
    .sc_config_0_sc_if_misc_config_o        (misc_config),
    .sc_config_0_sc_if_sl_config_o          (sl_config),
    .sc_config_0_sc_if_sl_config2_o         (sl_config2),
    .sc_config_0_sc_if_hv_out_config_o      (hv_out_config),
    .sc_config_0_sc_if_hv_out_config2_o     (hv_out_config2),
    .sc_config_0_sc_if_hv_out_config3_o     (hv_out_config3),
    .sc_config_0_sc_if_xy_out_config_o      (xy_out_config),
    .sc_config_0_sc_if_xy_out_config2_o     (xy_out_config2),
    .osd_generator_0_osd_if_vclk           (PCLK_SI),
    .osd_generator_0_osd_if_xpos           (xpos),
    .osd_generator_0_osd_if_ypos           (ypos),
    .osd_generator_0_osd_if_osd_enable     (osd_enable),
    .osd_generator_0_osd_if_osd_color      (osd_color)
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
    .hv_out_config(hv_out_config),
    .hv_out_config2(hv_out_config2),
    .hv_out_config3(hv_out_config3),
    .xy_out_config(xy_out_config),
    .xy_out_config2(xy_out_config2),
    .misc_config(misc_config),
    .sl_config(sl_config),
    .sl_config2(sl_config2),
    .testpattern_enable(1'b0),
    .PCLK_o(PCLK_sc),
    .R_o(R_sc),
    .G_o(G_sc),
    .B_o(B_sc),
    .HSYNC_o(HSYNC_sc),
    .VSYNC_o(VSYNC_sc),
    .DE_o(DE_sc),
    .xpos_o(xpos),
    .ypos_o(ypos),
    .resync_strobe()
);

pll_pclk pll_pclk_inst (
    .inclk0 ( PCLK2x_in ),
    .c0 ( clk25 ),
    .locked ( pll_locked )
);

i2s_upsampler_asrc upsampler0 (
    .AMCLK_i        (MCLK_SI),
    .nARST          (reset_n),
    .ASCLK_i        (YM_o1),
    .ASDATA_i       (YM_SO),
    .ALRCLK_i       (YM_SH1),
    .ASCLK_WM_i     (YM_o1),
    .ASDATA_WM_i    (WM_SO),
    .ALRCLK_WM_i    (WM_LRCLK),
    .ASCLK_o        (I2S_BCK_o),
    .ASDATA_o       (I2S_DATA_o),
    .ALRCLK_o       (I2S_WS_o)
);

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
