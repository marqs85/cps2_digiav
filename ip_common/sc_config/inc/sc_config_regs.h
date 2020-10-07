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

#ifndef SC_CONFIG_REGS_H_
#define SC_CONFIG_REGS_H_

#include <stdint.h>

// bit-fields coded as little-endian
typedef union {
    struct {
        uint16_t h_active:10;
        uint16_t v_active:10;
    } __attribute__((packed, __may_alias__));
    uint32_t data;
} fe_status_reg;

typedef union {
    struct {
        uint32_t vclks_per_frame:22;
        uint16_t fe_rsv:10;
    } __attribute__((packed, __may_alias__));
    uint32_t data;
} fe_status2_reg;

typedef union {
    struct {
        uint16_t h_total:12;
        uint16_t h_active:11;
        uint16_t h_backporch:9;
    } __attribute__((packed, __may_alias__));
    uint32_t data;
} hv_config_reg;

typedef union {
    struct {
        uint16_t h_synclen:9;
        uint16_t v_total:11;
        uint16_t v_active:11;
        uint8_t interlaced:1;
    } __attribute__((packed, __may_alias__));
    uint32_t data;
} hv_config2_reg;

typedef union {
    struct {
        uint16_t v_backporch:9;
        uint8_t v_synclen:5;
        uint16_t v_startline:11;
        uint8_t hv_rsv:7;
    } __attribute__((packed, __may_alias__));
    uint32_t data;
} hv_config3_reg;

typedef union {
    struct {
        uint16_t x_size:11;
        uint16_t y_size:11;
        int16_t x_offset:10;
    } __attribute__((packed, __may_alias__));
    uint32_t data;
} xy_config_reg;

typedef union {
    struct {
        int16_t y_offset:9;
        uint8_t x_start_lb:8;
        int8_t y_start_lb:6;
        uint8_t x_rpt:3;
        uint8_t y_rpt:3;
        uint16_t x_skip:3;
    } __attribute__((packed, __may_alias__));
    uint32_t data;
} xy_config2_reg;

typedef union {
    struct {
        uint8_t mask_br:4;
        uint32_t misc_rsv:28;
    } __attribute__((packed, __may_alias__));
    uint32_t data;
} misc_config_reg;

typedef union {
    struct {
        uint32_t sl_l_str_arr:24;
        uint8_t sl_l_overlay:6;
        uint8_t sl_method:1;
        uint8_t sl_rsv:1;
    } __attribute__((packed, __may_alias__));
    uint32_t data;
} sl_config_reg;

typedef union {
    struct {
        uint32_t sl_c_str_arr:24;
        uint8_t sl_c_overlay:6;
        uint8_t sl_rsv:2;
    } __attribute__((packed, __may_alias__));
    uint32_t data;
} sl_config2_reg;

typedef struct {
    fe_status_reg fe_status;
    fe_status2_reg fe_status2;
    hv_config_reg hv_out_config;
    hv_config2_reg hv_out_config2;
    hv_config3_reg hv_out_config3;
    xy_config_reg xy_out_config;
    xy_config2_reg xy_out_config2;
    misc_config_reg misc_config;
    sl_config_reg sl_config;
    sl_config2_reg sl_config2;
} __attribute__((packed, __may_alias__)) sc_regs;

#endif //SC_CONFIG_REGS_H_
