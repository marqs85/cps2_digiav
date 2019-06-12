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

module i2s_tx_asrc (
    input AMCLK_i,
    input reset_n,
    input [(I2S_DATA_BITS-1):0] APSDATA_LEFT_i,
    input [(I2S_DATA_BITS-1):0] APSDATA_RIGHT_i,
    input APDATA_VALID_i,
    input downsample_2x,
    output I2S_BCK,
    output I2S_WS,
    output I2S_DATA
);

parameter I2S_DATA_BITS = 24;
parameter I2S_BCKS_PER_FRAME = 64;  // 32 or 64
parameter MCLK_FRAME_DIVIDER = 256; // must be power of 2

localparam MCLK_DIV_BITS = $clog2(MCLK_FRAME_DIVIDER);
localparam WS_TOGGLE_BIT = (MCLK_DIV_BITS-1);
localparam BCK_TOGGLE_BIT = WS_TOGGLE_BIT-$clog2(I2S_BCKS_PER_FRAME);

reg [(MCLK_DIV_BITS-1):0] mclk_div_ctr;
reg [$clog2(I2S_DATA_BITS):0] l_ctr;
reg [$clog2(I2S_DATA_BITS):0] r_ctr;
reg I2S_BCK_prev;
reg div2x_ctr, skip_sample;

assign I2S_WS = mclk_div_ctr[WS_TOGGLE_BIT];
assign I2S_BCK = mclk_div_ctr[BCK_TOGGLE_BIT];

wire shift_edge = ((I2S_BCK_prev == 1'b1) && (I2S_BCK == 1'b0));

always @(posedge AMCLK_i) begin
    if (APDATA_VALID_i & !skip_sample)
        mclk_div_ctr <= 0;
    else if (div2x_ctr == 1'b1)
        mclk_div_ctr <= mclk_div_ctr + 1'b1;

    if (APDATA_VALID_i) begin
        div2x_ctr <= !downsample_2x;
        skip_sample <= downsample_2x ? (skip_sample ^ 1'b1) : 1'b0;
    end else if (downsample_2x) begin
        div2x_ctr <= div2x_ctr + 1'b1;
    end

    if (mclk_div_ctr == 0)
        l_ctr <= I2S_DATA_BITS;
    else if (mclk_div_ctr == (MCLK_FRAME_DIVIDER/2))
        r_ctr <= I2S_DATA_BITS;
    else if (shift_edge) begin
        if (l_ctr > 0) begin
            I2S_DATA <= APSDATA_LEFT_i[l_ctr-1];
            l_ctr <= l_ctr - 1'b1;
        end else if (r_ctr > 0) begin
            I2S_DATA <= APSDATA_RIGHT_i[r_ctr-1];
            r_ctr <= r_ctr - 1'b1;
        end
    end

    I2S_BCK_prev <= I2S_BCK;
end

endmodule
