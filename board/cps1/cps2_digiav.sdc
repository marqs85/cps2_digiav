### Clocks ###

create_clock -period 183MHz -name pclk_si [get_ports PCLK_SI]
create_clock -period 24.576MHz -name mclk [get_ports MCLK_SI]
create_clock -period 16MHz -name pclk [get_ports PCLK2x_in]
create_clock -period 1.79MHz -name bck [get_ports YM_o1]
create_clock -period 55kHz -name clk_sh [get_ports YM_SH1]

#derive_pll_clocks
#create_generated_clock -source {upsampler0|pll_i2s_inst|altpll_component|auto_generated|pll1|inclk[0]} -divide_by 5 -multiply_by 4 -duty_cycle 50.00 -name i2s_bck {upsampler0|pll_i2s_inst|altpll_component|auto_generated|pll1|clk[0]}
create_generated_clock -source {pll_pclk_inst|altpll_component|auto_generated|pll1|inclk[0]} -divide_by 16 -multiply_by 25 -duty_cycle 50.00 -name clk25 {pll_pclk_inst|altpll_component|auto_generated|pll1|clk[0]}

create_generated_clock -source [get_ports MCLK_SI] -divide_by 8 -multiply_by 1 -duty_cycle 50.00 -name i2s_bck {i2s_upsampler_asrc:upsampler0|i2s_tx_asrc:i2s_tx|mclk_div_ctr[1]}
create_generated_clock -name i2s_bck_out -master_clock i2s_bck -source {i2s_upsampler_asrc:upsampler0|i2s_tx_asrc:i2s_tx|mclk_div_ctr[1]} -multiply_by 1 [get_ports HDMI_TX_I2S_BCK]
create_generated_clock -name pclk_si_out -master_clock pclk_si -source [get_ports PCLK_SI] -multiply_by 1 [get_ports HDMI_TX_PCLK]
derive_clock_uncertainty


### IO constraints ###

set critinputs [get_ports {R_in* G_in* B_in* F_in* CSYNC_in}]
set_input_delay -clock pclk -min 0 $critinputs
set_input_delay -clock pclk -max 1.5 $critinputs

set_input_delay -clock bck -clock_fall -min 0 [get_ports {YM_SH1 YM_SO WM_SO}]
set_input_delay -clock bck -clock_fall -max 1.5 [get_ports {YM_SH1 YM_SO WM_SO}]

set_input_delay -clock pclk 0 [get_ports {sda HDMI_TX_INT_N BTN*}]

#set i2soutputs_hdmi {HDMI_TX_I2S_DATA HDMI_TX_I2S_WS}
#set_output_delay -reference_pin HDMI_TX_PCLK -clock pclk_si 0 $critoutputs_hdmi
#set_output_delay -reference_pin HDMI_TX_I2S_BCK -clock i2s_bck 0 $i2soutputs_hdmi
#set_false_path -to [remove_from_collection [all_outputs] "$critoutputs_hdmi $i2soutputs_hdmi"]

# ADV7513
set hdmitx_dmin -0.7
set hdmitx_dmax 1
set hdmitx_data_outputs [get_ports {HDMI_TX_RD* HDMI_TX_GD* HDMI_TX_BD* HDMI_TX_DE HDMI_TX_HS HDMI_TX_VS}]
set_output_delay -clock pclk_si_out -min $hdmitx_dmin $hdmitx_data_outputs -add_delay
set_output_delay -clock pclk_si_out -max $hdmitx_dmax $hdmitx_data_outputs -add_delay
set_output_delay -clock i2s_bck_out -min $hdmitx_dmin [get_ports {HDMI_TX_I2S_DATA HDMI_TX_I2S_WS}] -add_delay
set_output_delay -clock i2s_bck_out -max $hdmitx_dmax [get_ports {HDMI_TX_I2S_DATA HDMI_TX_I2S_WS}] -add_delay


### CPU/scanconverter clock relations ###

set_clock_groups -exclusive \
-group {bck i2s_bck i2s_bck_out} \
-group {pclk} \
-group {pclk_si pclk_si_out} \
-group {clk25} \
-group {clk_sh} \
-group {mclk}

set_false_path -from [get_clocks i2s_bck] -to [get_clocks bck]
set_false_path -from [get_ports {scl sda}]
set_false_path -to [get_ports {scl sda}]


### JTAG Signal Constraints ###

#constrain the TCK port
#create_clock -name tck -period "10MHz" [get_ports altera_reserved_tck]
#cut all paths to and from tck
set_clock_groups -exclusive -group [get_clocks altera_reserved_tck]
#constrain the TDI port
set_input_delay -clock altera_reserved_tck 20 [get_ports altera_reserved_tdi]
#constrain the TMS port
set_input_delay -clock altera_reserved_tck 20 [get_ports altera_reserved_tms]
#constrain the TDO port
set_output_delay -clock altera_reserved_tck 20 [get_ports altera_reserved_tdo]
