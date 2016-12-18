### CPU clock constraints ###

create_clock -period 16MHz -name clk16 [get_ports PCLK2x_in]

set_input_delay -clock clk16 0 [get_ports {sda scl HDMI_TX_INT_N BTN* *ALTERA_DATA0}]
set_false_path -to {sys:sys_inst|sys_pio_1:pio_1|readdata*}

### Scanconverter clock constraints ###

#create_clock -period 25MHz -name pclk_sdtv [get_ports PCLK_in] -add

#derive_pll_clocks
create_generated_clock -master_clock clk16 -source {pll_vga|altpll_component|auto_generated|pll1|inclk[0]} -multiply_by 2 -duty_cycle 50.00 -name pclk_vga {pll_vga|altpll_component|auto_generated|pll1|clk[0]}

derive_clock_uncertainty

# input delay constraints
set critinputs [get_ports {R_in* G_in* B_in* F_in* HSYNC_in VSYNC_in}]
set_input_delay -clock clk16 -min 0 $critinputs
set_input_delay -clock clk16 -max 1.5 $critinputs

# output delay constraints (TODO: add vsync)
set critoutputs_hdmi {HDMI_TX_RD* HDMI_TX_GD* HDMI_TX_BD* HDMI_TX_DE HDMI_TX_HS}
set_output_delay -reference_pin HDMI_TX_PCLK -clock pclk_vga 0 $critoutputs_hdmi
set_false_path -to [remove_from_collection [all_outputs] $critoutputs_hdmi]


### CPU/scanconverter clock relations ###

# Set pixel clocks as exclusive clocks
set_clock_groups -exclusive \
-group {clk16 pclk_vga}

# Treat CPU clock asynchronous to pixel clocks 
set_clock_groups -asynchronous -group {clk16}

# Filter out impossible output mux combinations
set clkmuxregs [get_cells {scanconverter:scanconverter_inst|R_out[*] scanconverter:scanconverter_inst|G_out[*] scanconverter:scanconverter_inst|B_out[*] scanconverter:scanconverter_inst|HSYNC_out scanconverter:scanconverter_inst|DATA_enable scanconverter:scanconverter_inst|*_pp1*}]
set clkmuxnodes [get_pins {scanconverter_inst|linebuf_*|altsyncram_*|auto_generated|ram_*|portbaddr*}]
set_false_path -from [get_clocks {pclk_vga}] -through $clkmuxregs

# Ignore paths from registers which are updated only at the end of vsync
set_false_path -from [get_cells {scanconverter_inst|H_* scanconverter_inst|V_* scanconverter:scanconverter_inst|lines_*}]

# Ignore paths from registers which are updated only at the end of hsync
set_false_path -from [get_cells {scanconverter:scanconverter_inst|vcnt_* scanconverter:scanconverter_inst|line_idx scanconverter:scanconverter_inst|line_out_idx* scanconverter:scanconverter_inst|HSYNC_start*}]

# Ignore paths to registers which do not drive critical logic
set_false_path -to [get_cells {scanconverter:scanconverter_inst|line_out_idx*}]

# Ignore following clock transfers
set_false_path -from [get_clocks pclk_vga] -to [get_clocks clk16]


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
