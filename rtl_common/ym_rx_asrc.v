//
// Copyright (C) 2019  Markus Hiienkari <mhiienka@niksula.hut.fi>
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

module ym_rx_asrc (
    input AMCLK_i,
    input reset_n,
    input I2S_BCK,
    input I2S_WS,
    input I2S_DATA,
    output reg signed [(I2S_DATA_BITS-1):0] APDATA_LEFT_o,
    output reg signed [(I2S_DATA_BITS-1):0] APDATA_RIGHT_o,
    output reg APDATA_VALID_o
);

parameter I2S_DATA_BITS = 16;
parameter MCLK_DIVIDER = 16; // must be power of 2

reg I2S_WS_prev;

reg signed [(I2S_DATA_BITS-1):0] samplebuf_l;
reg signed [(I2S_DATA_BITS-1):0] samplebuf_r;
reg signed [(I2S_DATA_BITS-1):0] sample_l;
reg signed [(I2S_DATA_BITS-1):0] sample_r;
reg [$clog2(I2S_DATA_BITS):0] samplebuf_l_ctr;
reg [$clog2(I2S_DATA_BITS):0] samplebuf_r_ctr;

reg samplebuf_copied;
reg samplebuf_copied_L, samplebuf_copied_LL, samplebuf_copied_LLL;

reg [($clog2(MCLK_DIVIDER)-1):0] mclk_div_ctr;

always @(posedge I2S_BCK or negedge reset_n)
begin
    if (!reset_n) begin
        samplebuf_l_ctr <= 0;
        samplebuf_r_ctr <= 0;
        I2S_WS_prev <= 0;
    end else begin
        if ((I2S_WS_prev == 1'b1) && (I2S_WS == 1'b0)) begin
            samplebuf_l_ctr <= I2S_DATA_BITS-1;
            samplebuf_l[0] <= I2S_DATA;
        end else if (samplebuf_l_ctr == 1) begin
            samplebuf_r_ctr <= I2S_DATA_BITS;
        end

        if (samplebuf_l_ctr > 0) begin
            samplebuf_l[I2S_DATA_BITS-samplebuf_l_ctr] <= I2S_DATA;
            samplebuf_l_ctr <= samplebuf_l_ctr - 1;
        end

        if (samplebuf_r_ctr > 0) begin
            samplebuf_r[I2S_DATA_BITS-samplebuf_r_ctr] <= I2S_DATA;
            samplebuf_r_ctr <= samplebuf_r_ctr - 1;
        end

        if ((I2S_WS_prev == 1'b1) && (I2S_WS == 1'b0)) begin
            sample_l <= {{6'h0, samplebuf_l[12:3]} - 512} <<< (samplebuf_l[15:13]-3'h1);
            sample_r <= {{6'h0, samplebuf_r[12:3]} - 512} <<< (samplebuf_r[15:13]-3'h1);
            samplebuf_copied <= 1'b1;
        end else if (samplebuf_l_ctr == (I2S_DATA_BITS-2)) begin
            samplebuf_copied <= 1'b0;
        end

        I2S_WS_prev <= I2S_WS;
    end
end


// output samples at MCLK/DIV rate
always @(posedge AMCLK_i) begin
    if (!samplebuf_copied_LLL & samplebuf_copied_LL) begin
        APDATA_LEFT_o <= sample_l;
        APDATA_RIGHT_o <= sample_r;
    end

    APDATA_VALID_o <= (mclk_div_ctr == 0);

    mclk_div_ctr <= mclk_div_ctr + 1'b1;
    
    samplebuf_copied_L <= samplebuf_copied;
    samplebuf_copied_LL <= samplebuf_copied_L;
    samplebuf_copied_LLL <= samplebuf_copied_LL;
end

endmodule
