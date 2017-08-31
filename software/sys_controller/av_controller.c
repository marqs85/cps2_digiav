//
// Copyright (C) 2015  Markus Hiienkari <mhiienka@niksula.hut.fi>
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

#include <stdio.h>
#include <unistd.h>
#include "system.h"
#include "string.h"
#include "altera_avalon_pio_regs.h"
#include "i2c_opencores.h"
#include "sysconfig.h"

#include "it6613.h"
#include "it6613_sys.h"
#include "hdmitx.h"
#include "HDMI_TX.h"


#define LO_MASK             0x000007ff
#define PB_MASK             (3<<30)
#define PB0_BIT             (1<<30)
#define PB1_BIT             (1<<31)

typedef struct {
    alt_u32 lm_mode;
    alt_u32 h_active;
    alt_u32 h_avidstart;
    alt_u32 h_mask;
    alt_u32 v_active;
    alt_u32 v_avidstart;
    alt_u32 v_mask;
    alt_u32 sl_str;
    alt_u32 sl_mask;
} mode_config_t;

const mode_config_t fpga_480p = {.lm_mode=1, .h_active=640, .h_avidstart=144, .h_mask=0, .v_active=480, .v_avidstart=35, .v_mask=10, .sl_str=15, .sl_mask=1};
const mode_config_t fpga_1080p = {.lm_mode=0, .h_active=960, .h_avidstart=38, .h_mask=0, .v_active=216, .v_avidstart=31, .v_mask=0, .sl_str=15, .sl_mask=3};

// Initialize hardware
int init_hw()
{
    alt_u32 chiprev;

    // Reset error vector and scan converter

    //wait >500ms for SD card interface to be stable
    usleep(200000);

    // IT6613 supports only 100kHz
    I2C_init(I2C_OPENCORES_0_BASE,ALT_CPU_FREQ,100000);

    chiprev = HDMITX_ReadI2C_Byte(IT_DEVICEID);

    if ( chiprev != 0x13) {
        printf("Error: could not read from IT6613 (0x%x)\n", chiprev);
        return -5;
    }

    InitIT6613();

    return 0;
}

inline void TX_enable(alt_u8 mode)
{
    // shut down TX before setting new config
    SetAVMute(TRUE);
    DisableVideoOutput();
    EnableAVIInfoFrame(FALSE, NULL);

    // re-setup
    EnableVideoOutput(PCLK_MEDIUM, COLOR_RGB444, COLOR_RGB444, mode == 1);

    TX_SetPixelRepetition(1, 0);

    //TODO: set correct VID based on mode
    if (mode == 1)
        HDMITX_SetAVIInfoFrame(HDMI_Unkown, 0, 0, 0, 0);

    // start TX
    SetAVMute(FALSE);
}

void SetupAudio(alt_u8 bAudioEn)
{
    // shut down audio-tx before setting new config (recommended for changing audio-tx config)
    DisableAudioOutput();
    EnableAudioInfoFrame(FALSE, NULL);

    if (bAudioEn) {
        alt_u32 pclk = 25000000;
        EnableAudioOutputHDMI(pclk);
        //if (tc.tx_mode == TX_HDMI) {
        HDMITX_SetAudioInfoFrame(0);
        printf("enable infoframe\n");
        //}
    }
}

void program_mode(const mode_config_t *mode_ptr, int sl_enable) {
    IOWR_ALTERA_AVALON_PIO_DATA(PIO_1_BASE, (mode_ptr->h_mask<<21)|(mode_ptr->h_avidstart<<11)|mode_ptr->h_active);
    IOWR_ALTERA_AVALON_PIO_DATA(PIO_2_BASE, (mode_ptr->v_mask<<18)|(mode_ptr->v_avidstart<<11)|mode_ptr->v_active);
    IOWR_ALTERA_AVALON_PIO_DATA(PIO_3_BASE, (mode_ptr->lm_mode<<31)|(mode_ptr->sl_mask<<6)|(mode_ptr->sl_str<<2)|sl_enable);
}

int main()
{
    alt_u8 rd;
    alt_u32 btn_vec, btn_vec_prev=0;
    alt_u32 lines;
    alt_u32 lm_mode = 0;
    alt_u32 sl_enable = 0;
    const mode_config_t *mode_ptr = &fpga_1080p;

    int init_stat;

    init_stat = init_hw();

    if (init_stat >= 0) {
        printf("### cps2_digiAV INIT OK ###\n\n");
    } else {
        printf("Init error  %d", init_stat);
        while (1) {}
    }

    TX_enable(1);
    SetupAudio(1);

    alt_u32 ncts;

    program_mode(mode_ptr, sl_enable);

    while(1) {

        btn_vec = ~IORD_ALTERA_AVALON_PIO_DATA(PIO_0_BASE) & PB_MASK;

        if ((btn_vec_prev == 0) && btn_vec) {
            if (btn_vec & PB0_BIT)
                sl_enable ^= 1;
            if (btn_vec & PB1_BIT) {
                lm_mode ^= 1;
                mode_ptr = lm_mode ? &fpga_480p : &fpga_1080p;
                TX_SetPixelRepetition(!lm_mode, 0);
                HDMITX_SetAVIInfoFrame(HDMI_Unkown, 0, 0, 0, 0);
            }

            program_mode(mode_ptr, sl_enable);
        }

#ifdef DEBUG
        ncts = 0;
        Switch_HDMITX_Bank(1);
        //rd = read_it2(0xc5);
        //printf("osclock: 0x%x\n", rd);
        ncts |= read_it2(0x35) >> 4;
        ncts |= read_it2(0x36) << 4;
        ncts |= read_it2(0x37) << 12;
        printf("NCTS: %u\n", ncts);
        printf("btnvec: 0x%x\n", btn_vec);
#endif
        btn_vec_prev = btn_vec;

        usleep(WAITLOOP_SLEEP_US);
    }

    return 0;
}
