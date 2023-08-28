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
#include "sysconfig.h"
#include "avconfig.h"
#include "menu.h"

#define DEFAULT_ON              1

// Current and target configuration
avconfig_t cc, tc;

// Default configuration
const avconfig_t tc_default = {
    .sl_str = 4,
    .l5x_1080p_y_offset = (L5X_1080P_YOFF_MAX/2),
    .ad_mode_id = ADMODE_1080p_5X,
};

int reset_target_avconfig() {
    set_default_avconfig(0);
    render_osd_page();

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

status_t update_avconfig(avconfig_t *avc) {
    status_t status = NO_CHANGE;

    if (avc != NULL)
        memcpy(&tc, avc, sizeof(avconfig_t));

    if ((tc.sl_mode != cc.sl_mode) ||
        (tc.sl_method != cc.sl_method) ||
        (tc.sl_str != cc.sl_str))
        status = (status < SC_CONFIG_CHANGE) ? SC_CONFIG_CHANGE : status;

    if ((tc.ad_mode_id != cc.ad_mode_id) ||
#ifdef NEOGEO
        (tc.neogeo_freq != cc.neogeo_freq) ||
#endif
        (tc.l5x_1080p_y_offset != cc.l5x_1080p_y_offset))
        status = (status < MODE_CHANGE) ? MODE_CHANGE : status;

    memcpy(&cc, &tc, sizeof(avconfig_t));

    return status;
}
