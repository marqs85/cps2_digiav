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

#include <stdio.h>
#include <unistd.h>
#include <string.h>
#include <stdint.h>
#include "system.h"
#include "video_modes.h"
#include "sysconfig.h"
#include "avconfig.h"

#define VM_OUT_YMULT        (vm_conf->y_rpt+1)
#define VM_OUT_XMULT        (vm_conf->x_rpt+1)
#define VM_OUT_PCLKMULT     ((vm_conf->x_rpt+1)*(vm_conf->y_rpt+1))


extern avconfig_t tc;

const mode_data_t video_modes_default[] = { \
    /* 240p modes */ \
    { "240p_CRT",   HDMI_240p60,      {0},                                              TX_4X, TX_4X,  0, {0} },  \
    { "240p",       HDMI_240p60,      { 720,  240,   858, 0,  262,   57, 15,   62, 3},  TX_2X, TX_2X,  0, {0} },  \
    /* 480p modes */ \
    { "480p_CRT",   HDMI_480p60,      {0},                                              TX_1X, TX_1X,  0, {0} },  \
    { "480p",       HDMI_480p60,      { 720,  480,   858, 0,  525,   60, 30,   62, 6},  TX_1X, TX_1X,  0, {0} },  \
    { "640x480",    HDMI_640x480p60,  { 640,  480,   800, 0,  525,   48, 33,   96, 2},  TX_1X, TX_1X,  0, {0} },  \
    /* 720p modes */ \
    { "720p",       HDMI_720p60,      {1280,  720,  1650, 0,  750,  220, 20,   40, 5},  TX_1X, TX_1X,  0, {0} },  \
    /* VESA 1280x960 and SXGA modes */ \
    { "1280x960",   HDMI_Unknown,     {1280,  960,  1800, 0, 1000,  312, 36,  112, 3},  TX_1X, TX_1X,  0, {0} },  \
    { "1280x1024",  HDMI_Unknown,     {1280, 1024,  1688, 0, 1066,  248, 38,  112, 3},  TX_1X, TX_1X,  0, {0} },  \
    { "1080p",      HDMI_1080p60,     {1920, 1080,  2200, 0, 1125,  148, 36,   44, 5},  TX_1X, TX_1X,  0, {0} },  \
    /* CVT 1920x1200 with reduced blanking */ \
    { "1920x1200",  HDMI_Unknown,     {1920, 1200,  2080, 0, 1235,   80, 26,   32, 6},  TX_1X, TX_1X,  0, {0} },  \
    /* CVT 1920x1440 with reduced blanking */ \
    { "1920x1440",  HDMI_Unknown,     {1920, 1440,  2080, 0, 1481,   80, 34,   32, 4},  TX_1X, TX_1X,  0, {0} },  \
};

const sync_timings_t cps2_timings =         { 384,  224,   512, 0,  262,   62, 22,   36, 3};
const sync_timings_t cps3_timings_std =     { 384,  224,   546, 0,  264,   68, 21,   51, 3};
const sync_timings_t cps3_timings_wide =    { 495,  224,   682, 0,  264,   72, 21,   54, 3};

const ad_mode_data_t adaptive_modes_default[] = { \
    /* CPS2 modes */ \
    { ADMODE_240p_CRT,  &cps2_timings,  0, 0,  0, 0,  {    0,     0,     0,     0, 0, 0,  0, 1, 0} },  \
    { ADMODE_480p_CRT,  &cps2_timings,  1, 1,  0, 0,  {    0,     0,     0,     0, 0, 0,  0, 1, 0} },  \
    { ADMODE_720p,      &cps2_timings,  2, 2,  0, 0,  { 6572, 15488, 16768,  1024, 0, 1,  0, 0, 0} },  \
    { ADMODE_1080p_4X,  &cps2_timings,  3, 3,  0, 0,  { 6572, 15488, 16768,   256, 0, 1,  0, 0, 0} },  \
    { ADMODE_1080p_5X,  &cps2_timings,  3, 4,  0, 0,  { 6572, 15488, 16768,   256, 0, 1,  0, 0, 0} },  \
    { ADMODE_1200p,     &cps2_timings,  3, 4,  0, 0,  { 4390,   608,  2096,     0, 0, 1,  0, 0, 3} },  \
    { ADMODE_1440p,     &cps2_timings,  4, 5,  0, 0,  { 5366,  1632,  2096,     0, 0, 1,  0, 0, 3} },  \
    /*{ STDMODE_1440p,  &cps2_timings,  4, 5,  0, 0,  {8306, 704, 4192, 256, 0, 1, 0, 0, 0} },       \*/

    /* CPS3 standard modes */ \
    { ADMODE_240p_CRT,  &cps3_timings_std,  0, 0,  0, 0,  { 4851,     2,    10, 12896, 0, 4,  1, 0, 0} },  \
    { ADMODE_480p_CRT,  &cps3_timings_std,  1, 1,  0, 0,  { 4812,     4,     5,  2816, 0, 1,  1, 0, 0} },  \
    { ADMODE_720p,      &cps3_timings_std,  1, 2,  0, 0,  { 4762,    66,    91,  1024, 0, 1,  1, 0, 0} },  \
    { ADMODE_1080p_4X,  &cps3_timings_std,  2, 3,  0, 0,  { 4762,    66,    91,   256, 0, 1,  1, 0, 0} },  \
    { ADMODE_1080p_5X,  &cps3_timings_std,  3, 4,  0, 0,  { 4762,    66,    91,   256, 0, 1,  1, 0, 0} },  \
    { ADMODE_1200p,     &cps3_timings_std,  3, 4,  0, 0,  { 3137,   523,   693,     0, 0, 1,  1, 0, 3} },  \
    { ADMODE_1440p,     &cps3_timings_std,  4, 5,  0, 0,  { 3864,   520,   693,     0, 0, 1,  1, 0, 3} },  \

    /* CPS3 wide modes */ \
    { ADMODE_240p_CRT,  &cps3_timings_wide,  0, 0,  0, 0,  { 4844,    40,   546, 10208, 0, 4,  1, 0, 0} },  \
    { ADMODE_480p_CRT,  &cps3_timings_wide,  1, 1,  0, 0,  { 4796,   148,  1365,  2144, 0, 4,  1, 0, 0} },  \
    { ADMODE_720p,      &cps3_timings_wide,  1, 2,  0, 0,  { 4762,    66,    91,  1024, 0, 1,  1, 0, 0} },  \
    { ADMODE_1080p_4X,  &cps3_timings_wide,  2, 3,  0, 0,  { 4762,    66,    91,   256, 0, 1,  1, 0, 0} },  \
    { ADMODE_1080p_5X,  &cps3_timings_wide,  3, 4,  0, 0,  { 4762,    66,    91,   256, 0, 1,  1, 0, 0} },  \
    { ADMODE_1200p,     &cps3_timings_wide,  3, 4,  0, 0,  { 3137,   523,   693,     0, 0, 1,  1, 0, 3} },  \
};

const mode_idx_t ad_mode_id_map[] = {CRTMODE_240p, CRTMODE_480p, STDMODE_720p, STDMODE_1080p, STDMODE_1080p, STDMODE_1200p, STDMODE_1440p};

//mode_data_t video_modes[sizeof(video_modes_default)/sizeof(mode_data_t)];
ad_mode_data_t adaptive_modes[sizeof(adaptive_modes_default)/sizeof(ad_mode_data_t)];


void set_default_vm_table() {
    //memcpy(video_modes, video_modes_default, sizeof(video_modes_default));
    memcpy(adaptive_modes, adaptive_modes_default, sizeof(adaptive_modes_default));
}

void step_ad_mode(uint8_t next) {
    if (next && (tc.ad_mode_id < ADMODE_LAST))
        tc.ad_mode_id++;
    if (!next && (tc.ad_mode_id > 0))
        tc.ad_mode_id--;
}

void vmode_hv_mult(mode_data_t *vmode, uint8_t h_mult, uint8_t v_mult) {
    // TODO: check limits
    vmode->timings.h_synclen *= h_mult;
    vmode->timings.h_backporch *= h_mult;
    vmode->timings.h_active *= h_mult;
    vmode->timings.h_total = h_mult * vmode->timings.h_total + ((h_mult * vmode->timings.h_total_adj * 5 + 50) / 100);

    vmode->timings.v_synclen *= v_mult;
    vmode->timings.v_backporch *= v_mult;
    vmode->timings.v_active *= v_mult;
    /*if ((vmode->flags & MODE_INTERLACED) && ((v_mult % 2) == 0)) {
        vmode->flags &= ~MODE_INTERLACED;
        vmode->timings.v_total *= (v_mult / 2);
    } else {*/
        vmode->timings.v_total *= v_mult;
    //}
}

int get_output_mode(input_mode_t *im, ad_mode_id_t ad_mode_id, vm_mult_config_t *vm_conf, mode_data_t *vm_in, mode_data_t *vm_out)
{
    int i;
    int32_t v_linediff;
    uint16_t outdiv_val;
    unsigned num_modes = sizeof(adaptive_modes)/sizeof(ad_mode_data_t);
    avconfig_t* cc = get_current_avconfig();
    memset(vm_in, 0, sizeof(mode_data_t));
    memset(vm_out, 0, sizeof(mode_data_t));

    for (i=0; i<num_modes; i++) {
        if ((ad_mode_id == adaptive_modes[i].id) &&
            (im->h_active == (adaptive_modes[i].timings_i->h_active)) &&
            (im->v_active == (adaptive_modes[i].timings_i->v_active)) &&
            (im->h_total == (adaptive_modes[i].timings_i->h_total)) &&
            (im->v_total == (adaptive_modes[i].timings_i->v_total)))
        {
            memcpy(&vm_in->timings, adaptive_modes[i].timings_i, sizeof(sync_timings_t));
            memcpy(vm_out, &video_modes_default[ad_mode_id_map[adaptive_modes[i].id]], sizeof(mode_data_t));

            vm_conf->x_rpt = adaptive_modes[i].x_rpt;
            vm_conf->y_rpt = adaptive_modes[i].y_rpt;
            vm_conf->x_skip = 0;

            // select pure LM ("CRT mode") or adaptive mode
            if (vm_out->timings.v_total == 0) {
                memcpy(&vm_out->timings, adaptive_modes[i].timings_i, sizeof(sync_timings_t));
                vmode_hv_mult(vm_out, adaptive_modes[i].x_rpt+1, adaptive_modes[i].y_rpt+1);

                vm_conf->x_offset = 0;
                vm_conf->y_offset = 0;
                vm_conf->x_size = vm_out->timings.h_active;
                vm_conf->y_size = vm_out->timings.v_active;
                vm_conf->x_start_lb = 0;
                vm_conf->linebuf_startline = 0;

                if (adaptive_modes[i].si_ms_conf.msn_p1 == 0) {
                    vm_out->si_pclk_mult = (adaptive_modes[i].x_rpt+1)*(adaptive_modes[i].y_rpt+1);
                    outdiv_val = (1<<adaptive_modes[i].si_ms_conf.outdiv);
                    if ((vm_out->si_pclk_mult % outdiv_val) == 0)
                        vm_out->si_pclk_mult /= outdiv_val;
                    else
                        vm_out->si_ms_conf.outdiv = adaptive_modes[i].si_ms_conf.outdiv;
                } else {
                    memcpy(&vm_out->si_ms_conf, &adaptive_modes[i].si_ms_conf, sizeof(si5351_ms_config_t));
                }

                vm_conf->framesync_line = vm_out->timings.v_total-(vm_conf->y_rpt+1);
            } else {
                vm_conf->x_offset = ((vm_out->timings.h_active-vm_in->timings.h_active*(vm_conf->x_rpt+1))/2) + adaptive_modes[i].x_offset_i;
                vm_conf->x_start_lb = (vm_conf->x_offset >= 0) ? 0 : (-vm_conf->x_offset / (adaptive_modes[i].x_rpt+1));
                vm_conf->x_size = vm_in->timings.h_active*(vm_conf->x_rpt+1);
                vm_conf->linebuf_startline = ((vm_in->timings.v_active - (vm_out->timings.v_active/(adaptive_modes[i].y_rpt+1)))/2) + adaptive_modes[i].y_offset_i;
                vm_conf->y_offset = -(adaptive_modes[i].y_rpt+1)*vm_conf->linebuf_startline;
                vm_conf->y_size = vm_in->timings.v_active*(adaptive_modes[i].y_rpt+1);

                vm_out->si_pclk_mult = 0;
                memcpy(&vm_out->si_ms_conf, &adaptive_modes[i].si_ms_conf, sizeof(si5351_ms_config_t));

                // calculate the time (in output lines, rounded up) from source frame start to the point where first to-be-visible line has been written into linebuf
                v_linediff = (((vm_in->timings.v_synclen + vm_in->timings.v_backporch + ((vm_conf->linebuf_startline < 0) ? 0 : vm_conf->linebuf_startline) + 1) * vm_out->timings.v_total) / vm_in->timings.v_total) + 1;

                // subtract the previous value from the total number of output blanking/empty lines. Resulting value indicates how many lines output framestart must be offset
                v_linediff = (vm_out->timings.v_synclen + vm_out->timings.v_backporch + ((vm_conf->y_offset < 0) ? 0 : vm_conf->y_offset)) - v_linediff;

                // if linebuf is read faster than written, output framestart must be delayed accordingly to avoid read pointer catching write pointer
                if (vm_out->timings.v_total > vm_in->timings.v_total*(adaptive_modes[i].y_rpt+1))
                    v_linediff -= (((vm_in->timings.v_active * vm_out->timings.v_total) / vm_in->timings.v_total) - vm_conf->y_size);

                vm_conf->framesync_line = (v_linediff < 0) ? vm_out->timings.v_total+v_linediff : v_linediff;
            }

            printf("framesync_line = %u (linebuf_startline: %d, y_offset: %d, y_size: %u)\n", vm_conf->framesync_line, vm_conf->linebuf_startline, vm_conf->y_offset, vm_conf->y_size);
            printf("x_start_lb: %d, x_offset: %d, x_size: %u\n", vm_conf->x_start_lb, vm_conf->x_offset, vm_conf->x_size);

            return i;
        }
    }

    return -1;
}