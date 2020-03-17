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

#include <string.h>
#include "system.h"
#include "avconfig.h"
#include "video_modes.h"

#define DEFAULT_ON              1

// Current and target configuration
avconfig_t cc, tc;

// Default configuration
const avconfig_t tc_default = {
    .lm_conf_idx = 4,
};

int reset_target_avconfig() {
    set_default_avconfig(0);

    return 0;
}

avconfig_t* get_current_avconfig() {
    return &cc;
}

int set_default_avconfig(int update_cc)
{
    memcpy(&tc, &tc_default, sizeof(avconfig_t));
    adv7513_get_default_cfg(&tc.adv7513_cfg);

    if (update_cc)
        memcpy(&cc, &tc, sizeof(avconfig_t));

    set_default_vm_table();

    return 0;
}

status_t update_avconfig() {
    status_t status = NO_CHANGE;

    if ((tc.lm_conf_idx != cc.lm_conf_idx))
        status = (status < MODE_CHANGE) ? MODE_CHANGE : status;

    memcpy(&cc, &tc, sizeof(avconfig_t));

    return status;
}
