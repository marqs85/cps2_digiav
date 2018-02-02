### Clocks ###

create_clock -period 16MHz -name clk16 [get_ports PCLK2x_in]
create_clock -period 5MHz -name clk5 [get_ports I2S_BCK]

#derive_pll_clocks
create_generated_clock -source {upsampler0|pll_i2s_inst|altpll_component|auto_generated|pll1|inclk[0]} -divide_by 5 -multiply_by 4 -duty_cycle 50.00 -name i2s_clkout {upsampler0|pll_i2s_inst|altpll_component|auto_generated|pll1|clk[0]}
create_generated_clock -source {pll_pclk_inst|altpll_component|auto_generated|pll1|inclk[0]} -divide_by 16 -multiply_by 25 -duty_cycle 50.00 -name clk25 {pll_pclk_inst|altpll_component|auto_generated|pll1|clk[0]}
create_generated_clock -source {pll_pclk_inst|altpll_component|auto_generated|pll1|inclk[0]} -multiply_by 5 -duty_cycle 50.00 -name pclk_5x {pll_pclk_inst|altpll_component|auto_generated|pll1|clk[1]}
derive_clock_uncertainty


### IO constraints ###

set critinputs [get_ports {R_in* G_in* B_in* F_in* HSYNC_in VSYNC_in}]
set_input_delay -clock clk16 -min 0 $critinputs
set_input_delay -clock clk16 -max 1.5 $critinputs

set i2s_inputs [get_ports {I2S_WS I2S_DATA}]
set_input_delay -clock clk5 -min 0 $i2s_inputs
set_input_delay -clock clk5 -max 1.5 $i2s_inputs

set_input_delay -clock clk16 0 [get_ports {sda scl HDMI_TX_INT_N BTN*}]

set critoutputs_hdmi {HDMI_TX_RD* HDMI_TX_GD* HDMI_TX_BD* HDMI_TX_DE HDMI_TX_HS HDMI_TX_VS}
set i2soutputs_hdmi {HDMI_TX_I2S_DATA HDMI_TX_I2S_WS HDMI_TX_I2S_MCLK}
set_output_delay -reference_pin HDMI_TX_PCLK -clock pclk_5x 0 $critoutputs_hdmi
set_output_delay -reference_pin HDMI_TX_I2S_BCK -clock i2s_clkout 0 $i2soutputs_hdmi
set_false_path -to [remove_from_collection [all_outputs] "$critoutputs_hdmi $i2soutputs_hdmi"]


### CPU/scanconverter clock relations ###

# Set pixel clocks as exclusive clocks
set_clock_groups -exclusive \
-group {clk5 i2s_clkout} \
-group {clk16 pclk_5x} \
-group {clk25}

set_false_path -from [get_clocks i2s_clkout] -to [get_clocks clk5]
set_false_path -from [get_clocks pclk_5x] -to [get_clocks clk16]

# Filter out impossible output mux combinations
#set clkmuxregs [get_cells {scanconverter:scanconverter_inst|R_out[*] scanconverter:scanconverter_inst|G_out[*] scanconverter:scanconverter_inst|B_out[*] scanconverter:scanconverter_inst|HSYNC_out scanconverter:scanconverter_inst|DATA_enable scanconverter:scanconverter_inst|*_pp1*}]
#set clkmuxnodes [get_pins {scanconverter_inst|linebuf_*|altsyncram_*|auto_generated|ram_*|portbaddr*}]
#set_false_path -from [get_clocks {pclk_vga}] -through $clkmuxregs

# Ignore paths from registers which are updated only at the end of vsync
set_false_path -from [get_cells {scanconverter_inst|H_* scanconverter_inst|V_* scanconverter_inst|X_*}]

# Ignore paths from registers which are updated only at leading edge of hsync
set_false_path -from [get_registers {scanconverter:scanconverter_inst|line_idx scanconverter:scanconverter_inst|line_out_idx* scanconverter:scanconverter_inst|HSYNC_start*}]

# Ignore paths to registers which do not drive critical logic
#set_false_path -to [get_cells {scanconverter:scanconverter_inst|line_out_idx*}]


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
#set_output_delay -clock altera_reserved_tck 20 [get_ports altera_reserved_tdo]
