//
// Copyright (C) 2020  Markus Hiienkari <mhiienka@niksula.hut.fi>
//
// This file is part of CPS2 Digital AV Interface project.
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

`ifndef mclk_cfg_ids_vh_
`define mclk_cfg_ids_vh_

enum bit [4:0] {
    CPS2_MCLK_CFG=5'h0,
    CPS3_MCLK_CFG=5'h1
} mclk_cfg;

`endif //mclk_cfg_ids_vh_
