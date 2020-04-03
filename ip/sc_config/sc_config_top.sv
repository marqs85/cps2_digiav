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
    output reg [31:0] misc_config_o,
    output reg [31:0] sl_config_o,
    output reg [31:0] sl_config2_o,
    output reg [31:0] hv_out_config_o,
    output reg [31:0] hv_out_config2_o,
    output reg [31:0] hv_out_config3_o,
    output reg [31:0] xy_out_config_o,
    output reg [31:0] xy_out_config2_o
);

localparam FE_STATUS_REGNUM =       4'h0;
localparam FE_STATUS2_REGNUM =      4'h1;
localparam MISC_CONFIG_REGNUM =     4'h2;
localparam SL_CONFIG_REGNUM =       4'h3;
localparam SL_CONFIG2_REGNUM =      4'h4;
localparam HV_OUT_CONFIG_REGNUM =   4'h5;
localparam HV_OUT_CONFIG2_REGNUM =  4'h6;
localparam HV_OUT_CONFIG3_REGNUM =  4'h7;
localparam XY_OUT_CONFIG_REGNUM =   4'h8;
localparam XY_OUT_CONFIG2_REGNUM =  4'h9;


assign avalon_s_waitrequest_n = 1'b1;

always @(posedge clk_i or posedge rst_i) begin
    if (rst_i) begin
        misc_config_o <= 0;
    end else begin
        if (avalon_s_chipselect && avalon_s_write && (avalon_s_address==MISC_CONFIG_REGNUM)) begin
            if (avalon_s_byteenable[3])
                misc_config_o[31:24] <= avalon_s_writedata[31:24];
            if (avalon_s_byteenable[2])
                misc_config_o[23:16] <= avalon_s_writedata[23:16];
            if (avalon_s_byteenable[1])
                misc_config_o[15:8] <= avalon_s_writedata[15:8];
            if (avalon_s_byteenable[0])
                misc_config_o[7:0] <= avalon_s_writedata[7:0];
        end
    end
end

always @(posedge clk_i or posedge rst_i) begin
    if (rst_i) begin
        sl_config_o <= 0;
    end else begin
        if (avalon_s_chipselect && avalon_s_write && (avalon_s_address==SL_CONFIG_REGNUM)) begin
            if (avalon_s_byteenable[3])
                sl_config_o[31:24] <= avalon_s_writedata[31:24];
            if (avalon_s_byteenable[2])
                sl_config_o[23:16] <= avalon_s_writedata[23:16];
            if (avalon_s_byteenable[1])
                sl_config_o[15:8] <= avalon_s_writedata[15:8];
            if (avalon_s_byteenable[0])
                sl_config_o[7:0] <= avalon_s_writedata[7:0];
        end
    end
end

always @(posedge clk_i or posedge rst_i) begin
    if (rst_i) begin
        sl_config2_o <= 0;
    end else begin
        if (avalon_s_chipselect && avalon_s_write && (avalon_s_address==SL_CONFIG2_REGNUM)) begin
            if (avalon_s_byteenable[3])
                sl_config2_o[31:24] <= avalon_s_writedata[31:24];
            if (avalon_s_byteenable[2])
                sl_config2_o[23:16] <= avalon_s_writedata[23:16];
            if (avalon_s_byteenable[1])
                sl_config2_o[15:8] <= avalon_s_writedata[15:8];
            if (avalon_s_byteenable[0])
                sl_config2_o[7:0] <= avalon_s_writedata[7:0];
        end
    end
end

always @(posedge clk_i or posedge rst_i) begin
    if (rst_i) begin
        hv_out_config_o <= 0;
    end else begin
        if (avalon_s_chipselect && avalon_s_write && (avalon_s_address==HV_OUT_CONFIG_REGNUM)) begin
            if (avalon_s_byteenable[3])
                hv_out_config_o[31:24] <= avalon_s_writedata[31:24];
            if (avalon_s_byteenable[2])
                hv_out_config_o[23:16] <= avalon_s_writedata[23:16];
            if (avalon_s_byteenable[1])
                hv_out_config_o[15:8] <= avalon_s_writedata[15:8];
            if (avalon_s_byteenable[0])
                hv_out_config_o[7:0] <= avalon_s_writedata[7:0];
        end
    end
end

always @(posedge clk_i or posedge rst_i) begin
    if (rst_i) begin
        hv_out_config2_o <= 0;
    end else begin
        if (avalon_s_chipselect && avalon_s_write && (avalon_s_address==HV_OUT_CONFIG2_REGNUM)) begin
            if (avalon_s_byteenable[3])
                hv_out_config2_o[31:24] <= avalon_s_writedata[31:24];
            if (avalon_s_byteenable[2])
                hv_out_config2_o[23:16] <= avalon_s_writedata[23:16];
            if (avalon_s_byteenable[1])
                hv_out_config2_o[15:8] <= avalon_s_writedata[15:8];
            if (avalon_s_byteenable[0])
                hv_out_config2_o[7:0] <= avalon_s_writedata[7:0];
        end
    end
end

always @(posedge clk_i or posedge rst_i) begin
    if (rst_i) begin
        hv_out_config3_o <= 0;
    end else begin
        if (avalon_s_chipselect && avalon_s_write && (avalon_s_address==HV_OUT_CONFIG3_REGNUM)) begin
            if (avalon_s_byteenable[3])
                hv_out_config3_o[31:24] <= avalon_s_writedata[31:24];
            if (avalon_s_byteenable[2])
                hv_out_config3_o[23:16] <= avalon_s_writedata[23:16];
            if (avalon_s_byteenable[1])
                hv_out_config3_o[15:8] <= avalon_s_writedata[15:8];
            if (avalon_s_byteenable[0])
                hv_out_config3_o[7:0] <= avalon_s_writedata[7:0];
        end
    end
end

always @(posedge clk_i or posedge rst_i) begin
    if (rst_i) begin
        xy_out_config_o <= 0;
    end else begin
        if (avalon_s_chipselect && avalon_s_write && (avalon_s_address==XY_OUT_CONFIG_REGNUM)) begin
            if (avalon_s_byteenable[3])
                xy_out_config_o[31:24] <= avalon_s_writedata[31:24];
            if (avalon_s_byteenable[2])
                xy_out_config_o[23:16] <= avalon_s_writedata[23:16];
            if (avalon_s_byteenable[1])
                xy_out_config_o[15:8] <= avalon_s_writedata[15:8];
            if (avalon_s_byteenable[0])
                xy_out_config_o[7:0] <= avalon_s_writedata[7:0];
        end
    end
end

always @(posedge clk_i or posedge rst_i) begin
    if (rst_i) begin
        xy_out_config2_o <= 0;
    end else begin
        if (avalon_s_chipselect && avalon_s_write && (avalon_s_address==XY_OUT_CONFIG2_REGNUM)) begin
            if (avalon_s_byteenable[3])
                xy_out_config2_o[31:24] <= avalon_s_writedata[31:24];
            if (avalon_s_byteenable[2])
                xy_out_config2_o[23:16] <= avalon_s_writedata[23:16];
            if (avalon_s_byteenable[1])
                xy_out_config2_o[15:8] <= avalon_s_writedata[15:8];
            if (avalon_s_byteenable[0])
                xy_out_config2_o[7:0] <= avalon_s_writedata[7:0];
        end
    end
end

// no config reg readback -> no space reserved for unused bits
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

endmodule
