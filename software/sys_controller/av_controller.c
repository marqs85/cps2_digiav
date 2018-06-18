//
// Copyright (C) 2016-2018  Markus Hiienkari <mhiienka@niksula.hut.fi>
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

#include "si5351_regs.h"


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

const mode_config_t fpga_480p = {.lm_mode=1, .h_active=640, .h_avidstart=144, .h_mask=0, .v_active=480, .v_avidstart=29, .v_mask=10, .sl_str=15, .sl_mask=1};
const mode_config_t fpga_1080p = {.lm_mode=0, .h_active=960, .h_avidstart=38, .h_mask=0, .v_active=216, .v_avidstart=29, .v_mask=0, .sl_str=15, .sl_mask=3};

#define ADV7513_BASE (0x72>>1)

inline alt_u32 adv7513_readreg(alt_u8 regaddr)
{
    //Phase 1
    I2C_start(I2CA_BASE, ADV7513_BASE, 0);
    I2C_write(I2CA_BASE, regaddr, 0);

    //Phase 2
    I2C_start(I2CA_BASE, ADV7513_BASE, 1);
    return I2C_read(I2CA_BASE,1);
}

inline void adv7513_writereg(alt_u8 regaddr, alt_u8 data)
{
    I2C_start(I2CA_BASE, ADV7513_BASE, 0);
    I2C_write(I2CA_BASE, regaddr, 0);
    I2C_write(I2CA_BASE, data, 1);
}

inline alt_u32 si5351_readreg(alt_u8 regaddr)
{
    //Phase 1
    I2C_start(I2CA_BASE, SI5351_BASE, 0);
    I2C_write(I2CA_BASE, regaddr, 0);

    //Phase 2
    I2C_start(I2CA_BASE, SI5351_BASE, 1);
    return I2C_read(I2CA_BASE,1);
}

inline void si5351_writereg(alt_u8 regaddr, alt_u8 data)
{
    I2C_start(I2CA_BASE, SI5351_BASE, 0);
    I2C_write(I2CA_BASE, regaddr, 0);
    I2C_write(I2CA_BASE, data, 1);
}


void init_si5351() {
    int i;

    for (i=0; i<SI5351C_REVB_REG_CONFIG_NUM_REGS; i++)
        si5351_writereg(si5351c_revb_registers[i].address, si5351c_revb_registers[i].value);

    printf("Waiting PLL lock\n");
    while ((si5351_readreg(0x00) & (1<<4)) != 0x00) ;
}

void init_adv() {
    while ((adv7513_readreg(0x42) & 0x70) != 0x70) ;
    adv7513_writereg(0x41, 0x10);
    //adv7513_writereg(0xd6, 0xc0);

    adv7513_writereg(0x98, 0x03);
    adv7513_writereg(0x9A, 0xE0);
    adv7513_writereg(0x9C, 0x30);
    adv7513_writereg(0x9D, 0x01);
    adv7513_writereg(0xA2, 0xA4);
    adv7513_writereg(0xA3, 0xA4);
    adv7513_writereg(0xE0, 0xD0);
    adv7513_writereg(0xF9, 0x00);

    adv7513_writereg(0x15, 0x20);
    adv7513_writereg(0x16, 0x00);

    adv7513_writereg(0xAF, 0x06);

    adv7513_writereg(0xBA, 0x60);

    adv7513_writereg(0x01, 0x00);
    adv7513_writereg(0x02, 0x18);
    adv7513_writereg(0x03, 0x00);
    adv7513_writereg(0x0A, 0x00);
    adv7513_writereg(0x0C, 0x84);
}

// Initialize hardware
int init_hw()
{
    alt_u8 retval;
    I2C_init(I2C_OPENCORES_0_BASE,ALT_CPU_FREQ,400000);

    // reset syncgen etc.
    IOWR_ALTERA_AVALON_PIO_DATA(PIO_3_BASE, 0x0);
    usleep(200000);

    retval = si5351_readreg(0x00);
    if ( retval == 0xff) {
        printf("Error: could not read from Si5351 (0x%x)\n", retval);
        return -2;
    } else if (retval >> 7) {
        printf("Error: Si5351 not ready\n");
        return -3;
    }

    printf("Init Si5351\n");
    init_si5351();

    // deassert syncgen reset
    IOWR_ALTERA_AVALON_PIO_DATA(PIO_3_BASE, (1<<31));

    retval = adv7513_readreg(0x00);

    if ( retval != 0x13) {
        printf("Error: could not read from ADV7513 (0x%x)\n", retval);
        return -1;
    }

    printf("Init ADV7513\n");
    init_adv();

    return 0;
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
    const mode_config_t *mode_ptr = &fpga_480p;

    int init_stat;

    init_stat = init_hw();

    if (init_stat >= 0) {
        printf("### cps2_digiAV INIT OK ###\n\n");
    } else {
        printf("Init error  %d", init_stat);
        while (1) {}
    }

    /*TX_enable(1);
    SetupAudio(1);*/

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
                //TX_SetPixelRepetition(!lm_mode, 0);
                //HDMITX_SetAVIInfoFrame(HDMI_Unkown, 0, 0, 0, 0);
            }

            program_mode(mode_ptr, sl_enable);
        }

        rd = adv7513_readreg(0x9e);
        if (!(adv7513_readreg(0x42) & 0x20)) {
            printf("Re-init ADV7513\n");
            init_adv();
        }

#ifdef DEBUG
        /*ncts = 0;
        Switch_HDMITX_Bank(1);
        //rd = read_it2(0xc5);
        //printf("osclock: 0x%x\n", rd);
        ncts |= read_it2(0x35) >> 4;
        ncts |= read_it2(0x36) << 4;
        ncts |= read_it2(0x37) << 12;
        printf("NCTS: %u\n", ncts);
        printf("btnvec: 0x%x\n", btn_vec);*/

        /*rd = adv7513_readreg(0x9e);
        printf("ADV7513 PLL status(0x%x)\n", rd);*/
#endif
        btn_vec_prev = btn_vec;

        usleep(WAITLOOP_SLEEP_US);
    }

    return 0;
}
