### Clocks ###

create_clock -period 183MHz -name pclk_si [get_ports PCLK_SI]
create_clock -period 24.576MHz -name mclk [get_ports MCLK_SI]
create_clock -period 16MHz -name pclk [get_ports PCLK2x_in]
create_clock -period 5MHz -name bck [get_ports I2S_BCK]

#derive_pll_clocks
#create_generated_clock -source {upsampler0|pll_i2s_inst|altpll_component|auto_generated|pll1|inclk[0]} -divide_by 5 -multiply_by 4 -duty_cycle 50.00 -name i2s_bck {upsampler0|pll_i2s_inst|altpll_component|auto_generated|pll1|clk[0]}
create_generated_clock -source {pll_pclk_inst|altpll_component|auto_generated|pll1|inclk[0]} -divide_by 16 -multiply_by 25 -duty_cycle 50.00 -name clk25 {pll_pclk_inst|altpll_component|auto_generated|pll1|clk[0]}

create_generated_clock -source [get_ports MCLK_SI] -divide_by 8 -multiply_by 1 -duty_cycle 50.00 -name i2s_bck {i2s_upsampler_asrc:upsampler0|i2s_tx_asrc:i2s_tx|mclk_div_ctr[1]}
create_generated_clock -name flash_clk -divide_by 2 -source {pll_pclk_inst|altpll_component|auto_generated|pll1|clk[0]} [get_pins sys:sys_inst|sys_intel_generic_serial_flash_interface_top_0:intel_generic_serial_flash_interface_top_0|sys_intel_generic_serial_flash_interface_top_0_qspi_inf_inst:qspi_inf_inst|flash_clk_reg|q]

create_generated_clock -name i2s_bck_out -master_clock i2s_bck -source {i2s_upsampler_asrc:upsampler0|i2s_tx_asrc:i2s_tx|mclk_div_ctr[1]} -multiply_by 1 [get_ports HDMI_TX_I2S_BCK]
create_generated_clock -name pclk_si_out -master_clock pclk_si -source [get_ports PCLK_SI] -multiply_by 1 [get_ports HDMI_TX_PCLK]
create_generated_clock -name flash_clk_out -master_clock flash_clk -source [get_pins sys:sys_inst|sys_intel_generic_serial_flash_interface_top_0:intel_generic_serial_flash_interface_top_0|sys_intel_generic_serial_flash_interface_top_0_qspi_inf_inst:qspi_inf_inst|flash_clk_reg|q] -multiply_by 1 [get_ports *ALTERA_DCLK]

derive_clock_uncertainty


### IO constraints ###

set critinputs [get_ports {R_in* G_in* B_in* F_in* HSYNC_in VSYNC_in}]
set_input_delay -clock pclk -min 0 $critinputs
set_input_delay -clock pclk -max 1.5 $critinputs

set_input_delay -clock bck -clock_fall -min 0 I2S_WS
set_input_delay -clock bck -clock_fall -max 1.5 I2S_WS
set_input_delay -clock bck -min 0 I2S_DATA
set_input_delay -clock bck -max 1.5 I2S_DATA

set_input_delay -clock pclk 0 [get_ports {sda HDMI_TX_INT_N BTN*}]

#set i2soutputs_hdmi {HDMI_TX_I2S_DATA HDMI_TX_I2S_WS}
#set_output_delay -reference_pin HDMI_TX_PCLK -clock pclk_si 0 $critoutputs_hdmi
#set_output_delay -reference_pin HDMI_TX_I2S_BCK -clock i2s_bck 0 $i2soutputs_hdmi
#set_false_path -to [remove_from_collection [all_outputs] "$critoutputs_hdmi $i2soutputs_hdmi"]

# ADV7513 (0ns video clock delay adjustment)
set hdmitx_dmin -1.9
set hdmitx_dmax -0.2
set hdmitx_data_outputs [get_ports {HDMI_TX_RD* HDMI_TX_GD* HDMI_TX_BD* HDMI_TX_DE HDMI_TX_HS HDMI_TX_VS}]
set_output_delay -clock pclk_si_out -min $hdmitx_dmin $hdmitx_data_outputs -add_delay
set_output_delay -clock pclk_si_out -max $hdmitx_dmax $hdmitx_data_outputs -add_delay
set_output_delay -clock i2s_bck_out -min $hdmitx_dmin [get_ports {HDMI_TX_I2S_DATA HDMI_TX_I2S_WS}] -add_delay
set_output_delay -clock i2s_bck_out -max $hdmitx_dmax [get_ports {HDMI_TX_I2S_DATA HDMI_TX_I2S_WS}] -add_delay

# Flash controller (delays from N25Q128A datasheet)
set_input_delay -clock flash_clk_out -clock_fall 5 [get_ports *ALTERA_DATA0]
set_output_delay -clock flash_clk_out 4 [get_ports *ALTERA_SCE]
set_output_delay -clock flash_clk_out 2 [get_ports *ALTERA_SDO]


### CPU/scanconverter clock relations ###

set_clock_groups -exclusive \
-group {bck i2s_bck i2s_bck_out} \
-group {pclk} \
-group {pclk_si pclk_si_out} \
-group {clk25 flash_clk flash_clk_out} \
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
