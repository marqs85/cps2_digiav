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
#include "sysconfig.h"
#include "menu.h"
#include "avconfig.h"
#include "osd_generator_regs.h"
#include "controls.h"
#include "userdata.h"

#define MAX_MENU_DEPTH 1

#define OPT_NOWRAP  0
#define OPT_WRAP    1

#ifdef OSDLANG_JP
#define LNG(e, j) j
#else
#define LNG(e, j) e
#endif

#define FW_VER      "0.90"

extern avconfig_t tc;
extern volatile osd_regs *osd;

char menu_row1[OSD_CHAR_COLS+1];
char menu_row2[OSD_CHAR_COLS+1];

uint8_t menu_active;

menunavi navi[MAX_MENU_DEPTH];
uint8_t navlvl;

static const char *off_on_desc[] = { LNG("Off","ｵﾌ"), LNG("On","ｵﾝ") };
static const char *ad_mode_id_desc[] = { "240p_CRT", "480p_CRT (Line2x)", "1280x720 (Line3x)", "1280x1024 (Line4x)", "1920x1080 (Line4x)", "1920x1080 (Line5x)", "1600x1200 (Line5x)", "1920x1200 (Line5x)", "1920x1440 (Line6x)" };
static const char *tx_mode_desc[] = { "HDMI (RGB Full)", "HDMI (RGB Limited)", "HDMI (YCbCr444)", "DVI" };
static const char *sl_method_desc[] = { "Multiplication", "Subtraction" };
static const char *sl_id_desc[] = { LNG("Top","ｳｴ"), LNG("Bottom","ｼﾀ") };
static const char *audio_sr_desc[] = { "Off", "On (4.0)", "On (5.1)", "On (7.1)" };

static void sl_str_disp(uint8_t v) { sniprintf(menu_row2, OSD_CHAR_COLS+1, "%u%%", ((v+1)*625)/100); }
static void lines_disp(uint8_t v) { sniprintf(menu_row2, OSD_CHAR_COLS+1, LNG("%u lines","%u ﾗｲﾝ"), v); }
static void pixels_disp(uint8_t v) { sniprintf(menu_row2, OSD_CHAR_COLS+1, LNG("%u pixels","%u ﾄﾞｯﾄ"), v); }
static void value_disp(uint8_t v) { sniprintf(menu_row2, OSD_CHAR_COLS+1, "    %u", v); }
static void value16_disp(uint16_t *v) { sniprintf(menu_row2, OSD_CHAR_COLS+1, "    %u", *v); }
static void signed_disp(uint8_t v) { sniprintf(menu_row2, OSD_CHAR_COLS+1, "    %d", (int8_t)(v-SIGNED_NUMVAL_ZERO)); }


MENU(menu_main, P99_PROTECT({ \
    { "Output mode",                            OPT_AVCONFIG_SELECTION, { .sel = { &tc.ad_mode_id,              OPT_WRAP, SETTING_ITEM(ad_mode_id_desc) } } },
    //{ LNG("Scanlines","ｽｷｬﾝﾗｲﾝ"),                OPT_AVCONFIG_SELECTION, { .sel = { &tc.sl_mode,                OPT_WRAP,   SETTING_ITEM(off_on_desc) } } },
    //{ LNG("Sl. strength","ｽｷｬﾝﾗｲﾝﾂﾖｻ"),          OPT_AVCONFIG_NUMVALUE,  { .num = { &tc.sl_str,                 OPT_NOWRAP, 0, SCANLINESTR_MAX, sl_str_disp } } },
    { "Quad stereo",                            OPT_AVCONFIG_SELECTION,  { .sel = { &tc.adv7513_cfg.i2s_chcfg, OPT_WRAP, SETTING_ITEM(audio_sr_desc) } } },
    { LNG("TX mode","TXﾓｰﾄﾞ"),                  OPT_AVCONFIG_SELECTION, { .sel = { &tc.adv7513_cfg.tx_mode,     OPT_WRAP, SETTING_ITEM(tx_mode_desc) } } },
    { "<Save settings>",                        OPT_FUNC_CALL,          { .fun = { save_settings, NULL } } },
    { LNG("<Reset settings>","<ｾｯﾃｲｵｼｮｷｶ    >"),  OPT_FUNC_CALL,          { .fun = { reset_target_avconfig, NULL } } },
    { "<Firmware info>",                        OPT_FUNC_CALL,          { .fun = { get_fw_info, NULL } } },
    { "<Exit menu>",                            OPT_FUNC_CALL,          { .fun = { exit_menu, NULL } } },
}))


int is_menu_active() {
    return !!menu_active;
}

void init_menu() {
    menu_active = 0;
    memset(navi, 0, sizeof(navi));
    navi[0].m = &menu_main;
    navlvl = 0;
}

int exit_menu() {
    menu_active = 0;
    osd->osd_config.menu_active = 0;

    return 0;
}

int save_settings() {
    return write_userdata(0);
}

int get_fw_info() {
    strncpy(menu_row2, "v" FW_VER " @ " __DATE__, OSD_CHAR_COLS);

    return 1;
}

void render_osd_page() {
    int i;
    menuitem_type type;
    uint32_t row_mask[2] = {0, 0};

    for (i=0; i < navi[navlvl].m->num_items; i++) {
        // Generate menu text
        type = navi[navlvl].m->items[i].type;
        strncpy((char*)osd->osd_array.data[i][0], navi[navlvl].m->items[i].name, OSD_CHAR_COLS);
        row_mask[0] |= (1<<i);

        switch (navi[navlvl].m->items[i].type) {
            case OPT_AVCONFIG_SELECTION:
                strncpy(menu_row2, navi[navlvl].m->items[i].sel.setting_str[*(navi[navlvl].m->items[i].sel.data)], OSD_CHAR_COLS+1);
                break;
            case OPT_AVCONFIG_NUMVALUE:
                navi[navlvl].m->items[i].num.df(*(navi[navlvl].m->items[i].num.data));
                break;
            case OPT_AVCONFIG_NUMVAL_U16:
                navi[navlvl].m->items[i].num_u16.df(navi[navlvl].m->items[i].num_u16.data);
                break;
            /*case OPT_SUBMENU:
                if (navi[navlvl].m->items[i].sub.arg_info)
                    navi[navlvl].m->items[i].sub.arg_info->df(*navi[navlvl].m->items[i].sub.arg_info->data);
                else
                    menu_row2[0] = 0;
                break;*/
            case OPT_FUNC_CALL:
                if (navi[navlvl].m->items[i].fun.arg_info)
                    navi[navlvl].m->items[i].fun.arg_info->df(*navi[navlvl].m->items[i].fun.arg_info->data);
                else
                    menu_row2[0] = 0;
                break;
            default:
                break;
        }
        strncpy((char*)osd->osd_array.data[i][1], menu_row2, OSD_CHAR_COLS);
        if (menu_row2[0] != 0)
            row_mask[1] |= (1<<i);
    }

    osd->osd_sec_enable[0].mask = row_mask[0];
    osd->osd_sec_enable[1].mask = row_mask[1];
}

void display_menu(menucode_id code)
{
    menuitem_type type;
    uint8_t *val, val_wrap, val_min, val_max;
    uint16_t *val_u16, val_u16_min, val_u16_max;
    int i, func_called = 0, retval = 0;

    type = navi[navlvl].m->items[navi[navlvl].mp].type;

    // Parse menu control
    switch (code) {
    case SHOW_MENU:
        menu_active = 1;
        render_osd_page();
        osd->osd_config.menu_active = 1;
        break;
    case NEXT_OPT:
        if ((navi[navlvl].m->items[navi[navlvl].mp].type == OPT_FUNC_CALL) && (navi[navlvl].m->items[navi[navlvl].mp].fun.arg_info == NULL))
            osd->osd_sec_enable[1].mask &= ~(1<<navi[navlvl].mp);
        navi[navlvl].mp = (navi[navlvl].mp+1) % navi[navlvl].m->num_items;
        break;
    case VAL_PLUS:
        switch (navi[navlvl].m->items[navi[navlvl].mp].type) {
            case OPT_AVCONFIG_SELECTION:
            case OPT_AVCONFIG_NUMVALUE:
                val = navi[navlvl].m->items[navi[navlvl].mp].sel.data;
                val_wrap = navi[navlvl].m->items[navi[navlvl].mp].sel.wrap_cfg;
                val_min = navi[navlvl].m->items[navi[navlvl].mp].sel.min;
                val_max = navi[navlvl].m->items[navi[navlvl].mp].sel.max;
                *val = (*val < val_max) ? (*val+1) : (val_wrap ? val_min : val_max);
                break;
            case OPT_FUNC_CALL:
                retval = navi[navlvl].m->items[navi[navlvl].mp].fun.f();
                osd->osd_sec_enable[1].mask |= (1<<navi[navlvl].mp);
                func_called = 1;
                break;
            default:
                break;
        }
        break;
    default:
        break;
    }

    // Generate menu text
    type = navi[navlvl].m->items[navi[navlvl].mp].type;
    strncpy(menu_row1, navi[navlvl].m->items[navi[navlvl].mp].name, OSD_CHAR_COLS+1);
    switch (navi[navlvl].m->items[navi[navlvl].mp].type) {
        case OPT_AVCONFIG_SELECTION:
            strncpy(menu_row2, navi[navlvl].m->items[navi[navlvl].mp].sel.setting_str[*(navi[navlvl].m->items[navi[navlvl].mp].sel.data)], OSD_CHAR_COLS+1);
            break;
        case OPT_AVCONFIG_NUMVALUE:
            navi[navlvl].m->items[navi[navlvl].mp].num.df(*(navi[navlvl].m->items[navi[navlvl].mp].num.data));
            break;
        case OPT_FUNC_CALL:
            if (func_called) {
                if (retval <= 0)
                    strncpy(menu_row2, ((retval==0) ? "Done" : "Failed"), OSD_CHAR_COLS);
            } else if (navi[navlvl].m->items[navi[navlvl].mp].fun.arg_info) {
                navi[navlvl].m->items[navi[navlvl].mp].fun.arg_info->df(*navi[navlvl].m->items[navi[navlvl].mp].fun.arg_info->data);
            } else {
                menu_row2[0] = 0;
            }
            break;
        default:
            break;
    }
    strncpy((char*)osd->osd_array.data[navi[navlvl].mp][1], menu_row2, OSD_CHAR_COLS);
    osd->osd_row_color.mask = (1<<navi[navlvl].mp);
}
