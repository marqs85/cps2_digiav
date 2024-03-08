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
//////////////////////////////////////////////////////////////////////////////////
//
// RTL adapted from borti4938's N64 Advanced HDMI Mod
//
//////////////////////////////////////////////////////////////////////////////////

`define MUXED_FIR // using muxed FIR filter increases LE load but uses one M9K less then two dedicated FIRs


module i2s_upsampler_asrc (
  AMCLK_i,
  nARST,

  // YM2151/QSound Audio Input
  ASCLK_i,
  ASDATA_i,
  ALRCLK_i,

  // WM8782 Audio Input
  ASCLK_WM_i,
  ASDATA_WM_i,
  ALRCLK_WM_i,

  // Audio Output
  ASCLK_o,
  ASDATA_o,
  ALRCLK_o
);

input AMCLK_i;
input nARST;

input ASCLK_i;
input ASDATA_i;
input ALRCLK_i;

input ASCLK_WM_i;
input ASDATA_WM_i;
input ALRCLK_WM_i;

output ASCLK_o;
output ASDATA_o;
output ALRCLK_o;


// parallization

wire signed [15:0] APDATA_YM [0:1];
wire APDATA_YM_VALID;

ym_rx_asrc ym_rx_u(
    .AMCLK_i(AMCLK_i),
    .reset_n(nARST),
    .I2S_BCK(ASCLK_i),
    .I2S_DATA(ASDATA_i),
    .I2S_WS(ALRCLK_i),
    .APDATA_LEFT_o(APDATA_YM[1]),
    .APDATA_RIGHT_o(APDATA_YM[0]),
    .APDATA_VALID_o(APDATA_YM_VALID)
);

wire signed [15:0] APDATA_QS [0:1];
wire APDATA_QS_VALID;

i2s_rx_asrc i2s_rx_qs_u(
    .AMCLK_i(AMCLK_i),
    .reset_n(nARST),
    .I2S_BCK(ASCLK_i),
    .I2S_DATA(ASDATA_i),
    .I2S_WS(ALRCLK_i),
    .APDATA_LEFT_o(APDATA_QS[1]),
    .APDATA_RIGHT_o(APDATA_QS[0]),
    .APDATA_VALID_o(APDATA_QS_VALID)
);

wire signed [23:0] APDATA_WM; // WM8782 input is mono
wire APDATA_WM_VALID;

i2s_rx_asrc #(.I2S_DATA_BITS(24)) i2s_rx_wm_u(
    .AMCLK_i(AMCLK_i),
    .reset_n(nARST),
    .I2S_BCK(ASCLK_WM_i),
    .I2S_DATA(ASDATA_WM_i),
    .I2S_WS(ALRCLK_WM_i),
    .APDATA_LEFT_o(),
    .APDATA_RIGHT_o(APDATA_WM),
    .APDATA_VALID_o(APDATA_WM_VALID)
);

// Detect between YM and QSound
reg snd_src_sel;
reg lrclk_prev;
reg [7:0] lrclk_ctr;
always @(posedge ASCLK_i or negedge nARST) begin
    if (!nARST) begin
        snd_src_sel <= 0;
        lrclk_prev <= 0;
        lrclk_ctr <= 0;
    end else begin
        if (~lrclk_prev & ALRCLK_i) begin
            if (lrclk_ctr == 31) begin
                snd_src_sel <= 1'b1;
            end else if ((lrclk_ctr > 190) & (lrclk_ctr < 210)) begin
                snd_src_sel <= 1'b0;
            end
            lrclk_ctr <= 0;
        end else begin
            if (lrclk_ctr != '1);
                lrclk_ctr <= lrclk_ctr + 1'b1;
        end

        lrclk_prev <= ALRCLK_i;
    end
end

// Mux between YM and QSound
wire APDATA_VALID = snd_src_sel ? APDATA_YM_VALID : APDATA_QS_VALID;

// interpolation

`ifndef MUXED_FIR

  wire signed [23:0] APDATA_INT [0:1];
  wire [1:0] APDATA_INT_VALID;

  fir_audio fir_audio_l_u(
    .clk(AMCLK_i),
    .reset_n(nARST),
    .ast_sink_data(APDATA[1]),
    .ast_sink_valid(APDATA_VALID),
    .ast_sink_error(2'b00),
    .ast_source_data(APDATA_INT[1]),
    .ast_source_valid(APDATA_INT_VALID[1])
  );

  fir_audio fir_audio_r_u(
    .clk(AMCLK_i),
    .reset_n(nARST),
    .ast_sink_data(APDATA[0]),
    .ast_sink_valid(APDATA_VALID),
    .ast_sink_error(2'b00),
    .ast_source_data(APDATA_INT[0]),
    .ast_source_valid(APDATA_INT_VALID[0])
  );

`else

  reg [1:0] tdm = 2'b11;
  reg signed [16:0] sink_data_buf_0, sink_data_buf_1, sink_data;
  reg sink_valid, sink_sop, sink_eop;

  always @(posedge AMCLK_i) begin
    case (tdm)
      2'b00: if (APDATA_VALID) begin
        if (snd_src_sel == 1'b1) begin
          // YM2151 + ADC
          sink_data_buf_1 <= {APDATA_YM[1][15], APDATA_YM[1]} + {APDATA_WM[23], APDATA_WM[23:8]};
          sink_data_buf_0 <= {APDATA_YM[0][15], APDATA_YM[0]} + {APDATA_WM[23], APDATA_WM[23:8]};
        end else begin
          // QSound
          sink_data_buf_1 <= {APDATA_QS[1][15], APDATA_QS[1]};
          sink_data_buf_0 <= {APDATA_QS[0][15], APDATA_QS[0]};
        end
        tdm <= 2'b01;
      end
      2'b01: begin
        sink_data <= sink_data_buf_1;
        sink_valid <= 1'b1;
        sink_sop <= 1'b1;
        sink_eop <= 1'b0;
        tdm <= 2'b10;
      end
      2'b10: begin
        sink_data <= sink_data_buf_0;
        sink_valid <= 1'b1;
        sink_sop <= 1'b0;
        sink_eop <= 1'b1;
        tdm <= 2'b11;
      end
      2'b11: begin
        sink_valid <= 1'b0;
        sink_sop <= 1'b0;
        sink_eop <= 1'b0;
        tdm <= 2'b00;
      end
      default: tdm <= 2'b11;
    endcase
    if (!nARST) begin
      sink_valid <= 1'b0;
      sink_sop <= 1'b0;
      sink_eop <= 1'b0;
      tdm <= 2'b00;
    end
  end

  wire signed [23:0] source_data;
  wire source_valid, source_sop, source_eop, source_channel;

  fir_2ch_audio fir_2ch_audio_u(
    .clk(AMCLK_i),
    .reset_n(nARST),
    .ast_sink_data(sink_data),
    .ast_sink_valid(sink_valid),
    .ast_sink_error(2'b00),
    .ast_sink_sop(sink_sop),
    .ast_sink_eop(sink_eop),
    .ast_source_data(source_data),
    .ast_source_valid(source_valid),
    .ast_source_sop(source_sop),
    .ast_source_eop(source_eop),
    .ast_source_channel(source_channel)
  );


  reg signed [23:0] APDATA_INT [0:1];
  reg APDATA_INT_VALID;

  always @(posedge AMCLK_i) begin
    if (source_valid)
      APDATA_INT[source_sop] <= source_data;

    if (source_valid & source_eop)
      APDATA_INT_VALID <= 1'b1;
    else
      APDATA_INT_VALID <= 1'b0;

    if (!nARST) begin
      APDATA_INT[0] <= {24{1'b0}};
      APDATA_INT[1] <= {24{1'b0}};
      APDATA_INT_VALID <= 1'b0;
    end
  end

`endif


// seriellization

i2s_tx_asrc i2s_tx(
  .AMCLK_i(AMCLK_i),
  .reset_n(nARST),
  .APSDATA_LEFT_i(APDATA_INT[1]),
  .APSDATA_RIGHT_i(APDATA_INT[0]),
  .APDATA_VALID_i(APDATA_INT_VALID),
  .downsample_2x(1'b1),
  .I2S_BCK(ASCLK_o),
  .I2S_DATA(ASDATA_o),
  .I2S_WS(ALRCLK_o)
);


endmodule
