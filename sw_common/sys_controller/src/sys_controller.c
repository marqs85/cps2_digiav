//
// Copyright (C) 2016-2020  Markus Hiienkari <mhiienka@niksula.hut.fi>
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
#include "system.h"
#include "string.h"
#include "altera_avalon_pio_regs.h"
#include "i2c_opencores.h"
#include "sysconfig.h"
#include "adv7513.h"
#include "si5351.h"
#include "sc_config_regs.h"
#include "osd_generator_regs.h"
#include "video_modes.h"
#include "avconfig.h"
#include "menu.h"
#include "userdata.h"
#include "controls.h"

#define SSTAT_BTN_MASK  0xc0000000
#define SSTAT_BTN_OFFS  30

#define ADV7513_MAIN_BASE 0x72
#define ADV7513_EDID_BASE 0x7e
#define ADV7513_PKTMEM_BASE 0x70
#define ADV7513_CEC_BASE 0x78

#define SI5351_BASE (0xC0>>1)

si5351_dev si_dev = {.i2cm_base = I2C_OPENCORES_0_BASE,
                     .i2c_addr = SI5351_BASE,
                     .xtal_freq = 0LU};

adv7513_dev advtx_dev = {.i2cm_base = I2C_OPENCORES_0_BASE,
                         .main_base = ADV7513_MAIN_BASE,
                         .edid_base = ADV7513_EDID_BASE,
                         .pktmem_base = ADV7513_PKTMEM_BASE,
                         .cec_base = ADV7513_CEC_BASE};

volatile sc_regs *sc = (volatile sc_regs*)SC_CONFIG_0_BASE;
volatile osd_regs *osd = (volatile osd_regs*)OSD_GENERATOR_0_BASE;

input_mode_t input_mode;
extern uint8_t menu_active;;


void update_osd_size(mode_data_t *vm_out) {
    uint8_t osd_size = vm_out->timings.v_active / 700;

    osd->osd_config.x_size = osd_size;
    osd->osd_config.y_size = osd_size;
}

void update_sc_config(mode_data_t *vm_in, mode_data_t *vm_out, vm_mult_config_t *vm_conf, avconfig_t *avc)
{
    int i;

    hv_config_reg hv_out_config = {.data=0x00000000};
    hv_config2_reg hv_out_config2 = {.data=0x00000000};
    hv_config3_reg hv_out_config3 = {.data=0x00000000};
    xy_config_reg xy_out_config = {.data=0x00000000};
    xy_config2_reg xy_out_config2 = {.data=0x00000000};
    misc_config_reg misc_config = {.data=0x00000000};
    sl_config_reg sl_config = {.data=0x00000000};
    sl_config2_reg sl_config2 = {.data=0x00000000};

    // Set output params
    hv_out_config.h_total = vm_out->timings.h_total;
    hv_out_config.h_active = vm_out->timings.h_active;
    hv_out_config.h_backporch = vm_out->timings.h_backporch;
    hv_out_config2.h_synclen = vm_out->timings.h_synclen;
    hv_out_config2.v_total = vm_out->timings.v_total;
    hv_out_config2.v_active = vm_out->timings.v_active;
    hv_out_config3.v_backporch = vm_out->timings.v_backporch;
    hv_out_config3.v_synclen = vm_out->timings.v_synclen;
    hv_out_config3.v_startline = vm_conf->framesync_line;

    xy_out_config.x_size = vm_conf->x_size;
    xy_out_config.y_size = vm_conf->y_size;
    xy_out_config.x_offset = vm_conf->x_offset;
    xy_out_config2.y_offset = vm_conf->y_offset;
    xy_out_config2.x_start_lb = vm_conf->x_start_lb;
    xy_out_config2.y_start_lb = vm_conf->y_start_lb;
    xy_out_config2.x_rpt = vm_conf->x_rpt;
    xy_out_config2.y_rpt = vm_conf->y_rpt;
    xy_out_config2.x_skip = vm_conf->x_skip;

    for (i=0; i<6; i++) {
        sl_config.sl_l_str_arr |= avc->sl_str<<(4*i);
        sl_config2.sl_c_str_arr |= avc->sl_str<<(4*i);
    }
    sl_config.sl_l_overlay = (avc->sl_mode >= 1) ? ((1<<((vm_conf->y_rpt+1)/2))-1) : 0;
    sl_config2.sl_c_overlay = (avc->sl_mode == 2) ? ((1<<((vm_conf->x_rpt+1)/3))-1) : 0;
    sl_config.sl_method = avc->sl_method;

    sc->hv_out_config = hv_out_config;
    sc->hv_out_config2 = hv_out_config2;
    sc->hv_out_config3 = hv_out_config3;
    sc->xy_out_config = xy_out_config;
    sc->xy_out_config2 = xy_out_config2;
    sc->misc_config = misc_config;
    sc->sl_config = sl_config;
    sc->sl_config2 = sl_config2;
}

// Initialize hardware
int init_hw()
{
    I2C_init(I2C_OPENCORES_0_BASE,ALT_CPU_FREQ, 400000);

    // init HDMI TX
    adv7513_init(&advtx_dev);

    // Init Si5351C
    si5351_init(&si_dev);

    init_flash();

    set_default_avconfig(1);
    read_userdata(0);
    init_menu();

    // Init OSD
    osd->osd_config.x_offset = 3;
    osd->osd_config.y_offset = 3;
    osd->osd_config.enable = 1;
    osd->osd_config.status_timeout = 0;
    osd->osd_config.status_refresh = 0;
    osd->osd_config.menu_active = 0;
    osd->osd_config.border_color = 1;

    return 0;
}

int check_input_mode_change() {
    int mode_changed = 0;

    input_mode_t target_mode = {0};

    target_mode.h_active = sc->fe_status.h_active;
    target_mode.v_active = sc->fe_status.v_active;
    target_mode.vclks_per_frame = sc->fe_status2.vclks_per_frame;

    if (memcmp(&input_mode, &target_mode, sizeof(input_mode_t)))
        mode_changed = 1;

    memcpy(&input_mode, &target_mode, sizeof(input_mode_t));

    return mode_changed;
}

int main()
{
    int ret, input_mode_change;
    status_t status;
    mode_data_t vmode_in, vmode_out;
    vm_mult_config_t vm_conf;
    const ad_mode_data_t *output_mode;
    avconfig_t *cur_avconfig;

    uint32_t btn_vec, btn_vec_prev=0;
    uint8_t btn_rpt=0;

    ret = init_hw();

    if (ret == 0) {
        printf("### cps2_digiAV INIT OK ###\n\n");
    } else {
        printf("Init error  %d", ret);
        while (1) {}
    }

    cur_avconfig = get_current_avconfig();

    while(1) {

        btn_vec = (~IORD_ALTERA_AVALON_PIO_DATA(PIO_0_BASE) & SSTAT_BTN_MASK) >> SSTAT_BTN_OFFS;

        if ((btn_vec != 0) && (btn_vec == btn_vec_prev))
            btn_rpt++;
        else
            btn_rpt = 0;

        if (btn_vec_prev == 0) {
            btn_vec_prev = btn_vec;
        } else {
            btn_vec_prev = btn_vec;
            btn_vec = 0;
        }

        if (!menu_active)
            btn_vec = (btn_rpt == 80) ? btn_vec_prev : 0;

        parse_control(btn_vec);

        status = update_avconfig(NULL);

        input_mode_change = check_input_mode_change();

        if ((status == MODE_CHANGE) || input_mode_change) {
            output_mode = get_output_mode(&input_mode, cur_avconfig->ad_mode_id, &vm_conf, &vmode_in, &vmode_out);

            if (output_mode != NULL) {
                printf("Output mode %d (%s) selected\n", output_mode->id, vmode_out.name);

                // configure output pixel clock
                if (vmode_out.si_pclk_mult != 0)
                    si5351_set_integer_mult(&si_dev, SI_PLLA, SI_CLK1, SI_CLKIN, output_mode->src_params->vclk_hz, vmode_out.si_pclk_mult, vmode_out.si_ms_conf.outdiv);
                else
                    si5351_set_frac_mult(&si_dev, SI_PLLA, SI_CLK1, SI_CLKIN, &vmode_out.si_ms_conf);

                // configure audio MCLK
                si5351_set_frac_mult(&si_dev, SI_PLLB, SI_CLK6, SI_CLKIN, (si5351_ms_config_t*)&output_mode->src_params->vclk_to_mclk_conf);

                update_osd_size(&vmode_out);
                update_sc_config(&vmode_in, &vmode_out, &vm_conf, cur_avconfig);
                adv7513_set_pixelrep_vic(&advtx_dev, vmode_out.tx_pixelrep, vmode_out.hdmitx_pixr_ifr, vmode_out.vic);
            }
        } else if (status == SC_CONFIG_CHANGE) {
            update_sc_config(&vmode_in, &vmode_out, &vm_conf, cur_avconfig);
        }

        adv7513_check_hpd_power(&advtx_dev);
        adv7513_update_config(&advtx_dev, &cur_avconfig->adv7513_cfg);

        usleep(WAITLOOP_SLEEP_US);
    }

    return 0;
}
