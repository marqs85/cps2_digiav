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
#include "video_modes.h"

#define SCANLINESTR_MAX     15
#define L5X_1080P_YOFF_MAX  8

// In reverse order of importance
typedef enum {
    NO_CHANGE           = 0,
    SC_CONFIG_CHANGE    = 1,
    MODE_CHANGE         = 2,
    TX_MODE_CHANGE      = 3,
    ACTIVITY_CHANGE     = 4
} status_t;

typedef struct {
    uint8_t sl_mode;
    uint8_t sl_method;
    uint8_t sl_str;
    uint8_t l5x_1080p_y_offset;
    ad_mode_id_t ad_mode_id;
    adv7513_config adv7513_cfg;
} __attribute__((packed)) avconfig_t;

int reset_target_avconfig();

avconfig_t* get_current_avconfig();

int set_default_avconfig(int update_cc);

status_t update_avconfig(avconfig_t *avc);

#endif
