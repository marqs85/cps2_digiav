//
// Copyright (C) 2015-2019  Markus Hiienkari <mhiienka@niksula.hut.fi>
//
// This file is part of Open Source Scan Converter project.
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

module sc_config_top(
    // common
    input clk_i,
    input rst_i,
    // avalon slave
    input [31:0] avalon_s_writedata,
    output reg [31:0] avalon_s_readdata,
    input [3:0] avalon_s_address,
    input [3:0] avalon_s_byteenable,
    input avalon_s_write,
    input avalon_s_read,
    input avalon_s_chipselect,
    output avalon_s_waitrequest_n,
    // SC interface
    input [31:0] fe_status_i,
    input [31:0] fe_status2_i,
    output reg [31:0] hv_out_config_o,
    output reg [31:0] hv_out_config2_o,
    output reg [31:0] hv_out_config3_o,
    output reg [31:0] xy_out_config_o,
    output reg [31:0] xy_out_config2_o,
    output reg [31:0] misc_config_o,
    output reg [31:0] sl_config_o,
    output reg [31:0] sl_config2_o
);

localparam FE_STATUS_REGNUM =       4'h0;
localparam FE_STATUS2_REGNUM =      4'h1;
localparam HV_OUT_CONFIG_REGNUM =   4'h2;
localparam HV_OUT_CONFIG2_REGNUM =  4'h3;
localparam HV_OUT_CONFIG3_REGNUM =  4'h4;
localparam XY_OUT_CONFIG_REGNUM =   4'h5;
localparam XY_OUT_CONFIG2_REGNUM =  4'h6;
localparam MISC_CONFIG_REGNUM =     4'h7;
localparam SL_CONFIG_REGNUM =       4'h8;
localparam SL_CONFIG2_REGNUM =      4'h9;

reg [31:0] config_reg[HV_OUT_CONFIG_REGNUM:SL_CONFIG2_REGNUM] /* synthesis ramstyle = "logic" */;

assign avalon_s_waitrequest_n = 1'b1;

genvar i;
generate
    for (i=HV_OUT_CONFIG_REGNUM; i <= SL_CONFIG2_REGNUM; i++) begin : gen_reg
        always @(posedge clk_i or posedge rst_i) begin
            if (rst_i) begin
                config_reg[i] <= 0;
            end else begin
                if (avalon_s_chipselect && avalon_s_write && (avalon_s_address==i)) begin
                    if (avalon_s_byteenable[3])
                        config_reg[i][31:24] <= avalon_s_writedata[31:24];
                    if (avalon_s_byteenable[2])
                        config_reg[i][23:16] <= avalon_s_writedata[23:16];
                    if (avalon_s_byteenable[1])
                        config_reg[i][15:8] <= avalon_s_writedata[15:8];
                    if (avalon_s_byteenable[0])
                        config_reg[i][7:0] <= avalon_s_writedata[7:0];
                end
            end
        end
    end
endgenerate


// no readback for config regs -> unused bits optimized out
always @(*) begin
    if (avalon_s_chipselect && avalon_s_read) begin
        case (avalon_s_address)
            FE_STATUS_REGNUM: avalon_s_readdata = fe_status_i;
            FE_STATUS2_REGNUM: avalon_s_readdata = fe_status2_i;
            default: avalon_s_readdata = 32'h00000000;
        endcase
    end else begin
        avalon_s_readdata = 32'h00000000;
    end
end

assign hv_out_config_o = config_reg[HV_OUT_CONFIG_REGNUM];
assign hv_out_config2_o = config_reg[HV_OUT_CONFIG2_REGNUM];
assign hv_out_config3_o = config_reg[HV_OUT_CONFIG3_REGNUM];
assign xy_out_config_o = config_reg[XY_OUT_CONFIG_REGNUM];
assign xy_out_config2_o = config_reg[XY_OUT_CONFIG2_REGNUM];
assign misc_config_o = config_reg[MISC_CONFIG_REGNUM];
assign sl_config_o = config_reg[SL_CONFIG_REGNUM];
assign sl_config2_o = config_reg[SL_CONFIG2_REGNUM];

endmodule
