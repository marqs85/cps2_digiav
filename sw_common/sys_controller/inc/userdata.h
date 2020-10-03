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

#ifndef USERDATA_H_
#define USERDATA_H_

#include <stdint.h>
#include "avconfig.h"

// EPCS16 pagesize is 256 bytes
// Flash is split 50-50 to FW and userdata, 1MB each
#define PAGESIZE 256
#define PAGES_PER_SECTOR 256        //EPCS "sector" corresponds to "block" on Spansion flash
#define SECTORSIZE (PAGESIZE*PAGES_PER_SECTOR)
#define USERDATA_OFFSET 0x100000
#define MAX_USERDATA_ENTRY 15    // 16 sectors for userdata

typedef enum {
    UDE_INITCFG  = 0,
    UDE_PROFILE,
} ude_type;

typedef struct {
    char userdata_key[8];
    uint8_t version_major;
    uint8_t version_minor;
} __attribute__((packed, __may_alias__)) ude_hdr;

typedef struct {
    ude_hdr hdr;
    uint16_t avc_data_len;
    avconfig_t avc;
} __attribute__((packed, __may_alias__)) ude_profile;

int init_flash();
int write_userdata(uint8_t entry);
int read_userdata(uint8_t entry);

#endif
