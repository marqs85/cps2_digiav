//
// Copyright (C) 2016-2021  Markus Hiienkari <mhiienka@niksula.hut.fi>
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

`define PO_RESET_WIDTH 1000

module cps2_digiav(
    input [4:0] R_in,
    input [4:0] G_in,
    input [4:0] B_in,
    input DARK_in,
    input SHADOW_in,
    input CSYNC_in,
    input VCLK_in,
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

reg [15:0] po_reset_ctr = 0;
reg po_reset_n = 1'b0;
wire jtagm_reset_req, ndmreset_req;
reg ndmreset_ack, ndmreset_pulse;
wire sys_reset_n = (po_reset_n & ~jtagm_reset_req & ~ndmreset_pulse);

reg clk_osc_div;
wire clk40 = clk_osc_div;
wire clk_osc;

reg [4:0] R_in_L, G_in_L, B_in_L;
reg DARK_in_L, SHADOW_in_L, CSYNC_in_L;

reg [7:0] R_out, G_out, B_out;
reg HSYNC_out, VSYNC_out, DE_out;
wire PCLK_sc;
wire [7:0] R_sc, G_sc, B_sc;
wire HSYNC_sc, VSYNC_sc, DE_sc;

wire I2S_BCK_o, I2S_DATA_o, I2S_WS_o; 

wire [31:0] misc_config, sl_config, sl_config2, hv_out_config, hv_out_config2, hv_out_config3, xy_out_config, xy_out_config2, fe_status, fe_status2;

wire [10:0] xpos, ypos;
wire osd_enable;
wire [1:0] osd_color;

wire BTN_volminus_debounced;
wire BTN_volplus_debounced;


// Power-on reset pulse generation (seems to be needed for serial flash controller)
always @(posedge VCLK_in)
begin
    if (po_reset_ctr == `PO_RESET_WIDTH)
        po_reset_n <= 1'b1;
    else
        po_reset_ctr <= po_reset_ctr + 1'b1;
end

// ndmreset pulse & ack for RISC-V DM
always @(posedge VCLK_in)
begin
    ndmreset_pulse <= !ndmreset_ack & ndmreset_req;
    ndmreset_ack <= ndmreset_req;
end

// Latch inputs syncronized to pixel clock
always @(posedge VCLK_in) begin
    R_in_L <= R_in;
    G_in_L <= G_in;
    B_in_L <= B_in;
    DARK_in_L <= DARK_in;
    SHADOW_in_L <= SHADOW_in;
    CSYNC_in_L <= CSYNC_in;
end

// Neogeo frontend
wire [4:0] NEO_R_post, NEO_G_post, NEO_B_post;
wire NEO_DARK_post;
wire NEO_HSYNC_post, NEO_VSYNC_post, NEO_DE_post;
wire NEO_fe_frame_change;
wire [8:0] NEO_fe_xpos, NEO_fe_ypos;
neogeo_frontend u_neogeo_frontend ( 
    .VCLK_i(VCLK_in),
    .R_i(R_in_L),
    .G_i(G_in_L),
    .B_i(B_in_L),
    .DARK_i(DARK_in_L),
    .SHADOW_i(SHADOW_in_L),
    .CSYNC_i(CSYNC_in_L),
    .R_o(NEO_R_post),
    .G_o(NEO_G_post),
    .B_o(NEO_B_post),
    .DARK_o(NEO_DARK_post),
    .HSYNC_o(NEO_HSYNC_post),
    .VSYNC_o(NEO_VSYNC_post),
    .DE_o(NEO_DE_post),
    .xpos(NEO_fe_xpos),
    .ypos(NEO_fe_ypos),
    .frame_change(NEO_fe_frame_change),
    .h_active(fe_status[9:0]),
    .v_active(fe_status[19:10]),
    .vclks_per_frame(fe_status2[21:0])
);

//assign HDMI_TX_RST_N = sys_reset_n;
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

// ~20MHz clock from internal oscillator
always @(posedge clk_osc)
begin
    clk_osc_div <= clk_osc_div + 1'b1;
end

sys sys_inst(
    .clk_clk                                (clk40),
    .int_osc_0_clkout_clk                   (clk_osc),
    .int_osc_0_oscena_oscena                (1'b1),
    .reset_reset_n                          (sys_reset_n),
    .reset_po_reset_n                       (po_reset_n),
    .ibex_0_ndm_ndmreset_o                  (ndmreset_req),
    .ibex_0_ndm_ndmreset_ack_i              (ndmreset_ack),
    .ibex_0_config_boot_addr_i              (32'h02080000),
    .ibex_0_config_core_sleep_o             (),
    .master_0_master_reset_reset            (jtagm_reset_req),
    .pio_0_ctrl_in_export                   ({BTN_volminus_debounced, BTN_volplus_debounced, 30'h0}),
    .i2c_opencores_0_export_scl_pad_io      (scl),
    .i2c_opencores_0_export_sda_pad_io      (sda),
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
    .osd_generator_0_osd_if_vclk            (PCLK_SI),
    .osd_generator_0_osd_if_xpos            (xpos),
    .osd_generator_0_osd_if_ypos            (ypos),
    .osd_generator_0_osd_if_osd_enable      (osd_enable),
    .osd_generator_0_osd_if_osd_color       (osd_color)
);

scanconverter #(
    .CPS_FADE(1'b0),
    .NEOGEO_DARKBIT(1'b1)
) scanconverter_inst (
    .PCLK_CAP_i(VCLK_in),
    .PCLK_OUT_i(PCLK_SI),
    .reset_n(sys_reset_n),
    .DATA_i({NEO_DARK_post, NEO_R_post, NEO_G_post, NEO_B_post}),
    .HSYNC_i(NEO_HSYNC_post),
    .VSYNC_i(NEO_VSYNC_post),
    .DE_i(NEO_DE_post),
    .FID_i(1'b0),
    .frame_change_i(NEO_fe_frame_change),
    .xpos_i(NEO_fe_xpos),
    .ypos_i(NEO_fe_ypos),
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

i2s_upsampler_asrc upsampler0 (
    .AMCLK_i        (MCLK_SI),
    .nARST          (sys_reset_n),
    .ASCLK_i        (I2S_BCK),
    .ASDATA_i       (I2S_DATA),
    .ALRCLK_i       (I2S_WS),
    .ASCLK_o        (I2S_BCK_o),
    .ASDATA_o       (I2S_DATA_o),
    .ALRCLK_o       (I2S_WS_o)
);

btn_debounce #(.MIN_PULSE_WIDTH(25000)) deb0 (
    .i_clk          (clk40),
    .i_btn          (BTN_volminus),
    .o_btn          (BTN_volminus_debounced)
);

btn_debounce #(.MIN_PULSE_WIDTH(25000)) deb1 (
    .i_clk          (clk40),
    .i_btn          (BTN_volplus),
    .o_btn          (BTN_volplus_debounced)
);

endmodule
