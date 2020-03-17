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

#ifndef AVCONFIG_H_
#define AVCONFIG_H_

#include <stdint.h>
#include "adv7513.h"

#define SIGNED_NUMVAL_ZERO  128

#define SCANLINESTR_MAX     15
#define SL_HYBRIDSTR_MAX    28
#define H_MASK_MAX          255
#define V_MASK_MAX          63
#define HV_MASK_MAX_BR      15

#define SL_MODE_MAX         2
#define SL_TYPE_MAX         2

// In reverse order of importance
typedef enum {
    NO_CHANGE           = 0,
    SC_CONFIG_CHANGE    = 1,
    MODE_CHANGE         = 2,
    TX_MODE_CHANGE      = 3,
    ACTIVITY_CHANGE     = 4
} status_t;

typedef struct {
    uint8_t lm_conf_idx;
    adv7513_config adv7513_cfg;
} __attribute__((packed)) avconfig_t;

int reset_target_avconfig();

avconfig_t* get_current_avconfig();

int set_default_avconfig(int update_cc);

status_t update_avconfig();

#endif
