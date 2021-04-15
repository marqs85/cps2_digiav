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
#include <unistd.h>
#include "controls.h"
#include "avconfig.h"
#include "sysconfig.h"
#include "menu.h"

extern avconfig_t tc;

void parse_control(uint8_t btn_vec)
{
    btn_vec_t b = (btn_vec_t)btn_vec;

    if (btn_vec) {
        printf("BTN_CODE: 0x%.2x\n", btn_vec);

        if (!is_menu_active()) {
            if (b == PB_BTN1)
                display_menu(SHOW_MENU);
            else if (b == PB_BTN0)
                tc.sl_mode = (tc.sl_mode + 1) % 3;
        } else {
            if (b == PB_BTN1)
                display_menu(NEXT_OPT);
            else if (b == PB_BTN0)
                display_menu(VAL_PLUS);
        }
    }
}
