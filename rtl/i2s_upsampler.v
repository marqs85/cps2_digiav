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

`define I2S_CLK_GATING

module i2s_upsampler (
    input reset_n,
    input I2S_BCK,
    input I2S_WS,
    input I2S_DATA,
    output I2S_BCK_OUT,
    output reg I2S_WS_2x,
    output reg I2S_DATA_2x,
    output reg [7:0] clkcnt_out
);

reg I2S_WS_prev;
reg [1:0] sample_idx;
reg [1:0] resample_idx;

reg [15:0] samplebuf_l[0:3];
reg [4:0] samplebuf_l_ctr;

reg [15:0] samplebuf_r[0:3];
reg [4:0] samplebuf_r_ctr;

reg [9:0] sample2x_ctr;
reg [4:0] resample_l_ctr;
reg [4:0] resample_r_ctr;

reg [7:0] clkcnt;
reg clken;
reg clken_l;

wire I2S_BCK_proc;

// I2S_BCK_OUT = (4/5)*I2S_BCK = 4MHz
pll_i2s pll_i2s_inst (
    .inclk0(I2S_BCK),
    .c0(I2S_BCK_proc),
    .locked()
);


// Record 16-bit samples at their native rate
// NOTE cps2 WS timing: 208cyc (31/32 pulses), 192cyc (1/32 pulse) avg: 207.5cyc
always @(posedge I2S_BCK or negedge reset_n)
begin
    if (!reset_n) begin
            samplebuf_l_ctr <= 0;
            samplebuf_l[0] <= 0;
            samplebuf_l[1] <= 0;
            samplebuf_l[2] <= 0;
            samplebuf_l[3] <= 0;
            samplebuf_r_ctr <= 0;
            samplebuf_r[0] <= 0;
            samplebuf_r[1] <= 0;
            samplebuf_r[2] <= 0;
            samplebuf_r[3] <= 0;
            I2S_WS_prev <= 0;
            sample_idx <= 0;
            clkcnt <= 0;
    end else begin
        if ((I2S_WS_prev == 1'b1) && (I2S_WS == 1'b0)) begin
            samplebuf_l_ctr <= 16;
            clkcnt_out <= clkcnt;
            sample_idx <= sample_idx + 1'b1;
        end else if ((I2S_WS_prev == 1'b0) && (I2S_WS == 1'b1)) begin
            samplebuf_r_ctr <= 16;
        end
        
        if (samplebuf_l_ctr > 0) begin
            samplebuf_l[sample_idx][samplebuf_l_ctr-1] <= I2S_DATA;
            samplebuf_l_ctr <= samplebuf_l_ctr - 1;
        end
        
        if (samplebuf_r_ctr > 0) begin
            samplebuf_r[sample_idx][samplebuf_r_ctr-1] <= I2S_DATA;
            samplebuf_r_ctr <= samplebuf_r_ctr - 1;
        end
        
        if ((I2S_WS_prev == 1'b1) && (I2S_WS == 1'b0))
            clkcnt <= 0;
        else
            clkcnt <= clkcnt + 1'b1;
        
        I2S_WS_prev <= I2S_WS;
    end
end

// Output samples at 2x rate, 83 BCK cycles per WS cycle
always @(posedge I2S_BCK_proc or negedge reset_n)
begin
    if (!reset_n) begin
            sample2x_ctr <= 0;
            resample_l_ctr <= 0;
            resample_r_ctr <= 0;
            resample_idx <= 2;
            clken <= 0;
    end else begin
        if ((sample2x_ctr == 0) || (sample2x_ctr == 83)) begin
                I2S_WS_2x <= 1'b0;
                resample_l_ctr <= 16;
                clken <= 1;
        end else if ((sample2x_ctr == 42) || (sample2x_ctr == (42+83))) begin
                I2S_WS_2x <= 1'b1;
                resample_r_ctr <= 16;
                clken <= 1;
                sample2x_ctr <= sample2x_ctr - 1'b1;
        end
        
        if (sample2x_ctr == (83*2-1)) begin
            sample2x_ctr <= 0;
            resample_idx <= resample_idx + 1'b1;
        end else begin
            sample2x_ctr <= sample2x_ctr + 1'b1;
        end
        
        if (resample_l_ctr > 0)
            begin
                I2S_DATA_2x <= samplebuf_l[resample_idx][resample_l_ctr-1];
                resample_l_ctr <= resample_l_ctr - 1;
            end
        else if (resample_r_ctr > 0)
            begin
                I2S_DATA_2x <= samplebuf_r[resample_idx][resample_r_ctr-1];
                resample_r_ctr <= resample_r_ctr - 1;
            end
        else
            begin
                I2S_DATA_2x <= 0;
            end
            
        if ((resample_l_ctr == 1) || (resample_r_ctr == 1))
            clken <= 0;
    end
end

`ifdef I2S_CLK_GATING
always @(negedge I2S_BCK_proc)
begin
    clken_l <= clken;
end

assign I2S_BCK_OUT = (I2S_BCK_proc & clken_l);
`else
assign I2S_BCK_OUT = I2S_BCK_proc;
`endif

endmodule
