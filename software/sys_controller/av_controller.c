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


#define PB_MASK             (3<<30)
#define PB0_BIT             (1<<30)
#define PB1_BIT             (1<<31)

typedef struct {
    const alt_u16 v_initline_ref;
    alt_u8 v_offset;
    alt_u8 v_mult;
    alt_u8 sl_enable;
    alt_u8 sl_str;
    alt_u8 sl_mask;
} mode_config_t;

mode_config_t fpga_480p = {.v_initline_ref=524, .v_offset=0, .v_mult=2, .sl_enable=0, .sl_str=15, .sl_mask=1};
mode_config_t fpga_1080p = {.v_initline_ref=1054, .v_offset=4, .v_mult=5, .sl_enable=0, .sl_str=15, .sl_mask=0x3};

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
    // Wait until display is detected
    while ((adv7513_readreg(0x42) & 0x70) != 0x70) ;

    // Power up TX
    adv7513_writereg(0x41, 0x10);
    //adv7513_writereg(0xd6, 0xc0);

    // Setup fixed registers
    adv7513_writereg(0x98, 0x03);
    adv7513_writereg(0x9A, 0xE0);
    adv7513_writereg(0x9C, 0x30);
    adv7513_writereg(0x9D, 0x01);
    adv7513_writereg(0xA2, 0xA4);
    adv7513_writereg(0xA3, 0xA4);
    adv7513_writereg(0xE0, 0xD0);
    adv7513_writereg(0xF9, 0x00);

    // Setup audio format
    adv7513_writereg(0x12, 0x20); // disable copyright protection
    adv7513_writereg(0x13, 0x20); // set category code
    adv7513_writereg(0x14, 0x0B); // 24-bit audio
    adv7513_writereg(0x15, 0x20); // 48kHz audio Fs, 24-bit RGB

    // Input video format
    adv7513_writereg(0x16, 0x30); // RGB 8bpc
    adv7513_writereg(0x17, 0x02); // 16:9 aspect

    // HDMI output without HDCP
    adv7513_writereg(0xAF, 0x06);

    // No clock delay (?)
    adv7513_writereg(0xBA, 0x60);

    // Audio regeneration settings
    adv7513_writereg(0x01, 0x00);
    adv7513_writereg(0x02, 0x18);
    adv7513_writereg(0x03, 0x00); // N=6144
    //adv7513_writereg(0x0A, 0x00);
    adv7513_writereg(0x0C, 0x04); // I2S0 input

    // Setup InfoFrame
    adv7513_writereg(0x4A, 0xC0); // Enable InfoFrame modify
    adv7513_writereg(0x55, 0x02); // No overscan
    adv7513_writereg(0x57, 0x08); // Full-range RGB
    adv7513_writereg(0x4A, 0x80); // Disable InfoFrame modify
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

void program_mode(mode_config_t *mode_ptr, int resync) {
    alt_u32 x_info;

    IOWR_ALTERA_AVALON_PIO_DATA(PIO_1_BASE, 0);
    IOWR_ALTERA_AVALON_PIO_DATA(PIO_2_BASE, ((mode_ptr->v_initline_ref-(mode_ptr->v_mult*mode_ptr->v_offset))<<4)|mode_ptr->v_offset);
    IOWR_ALTERA_AVALON_PIO_DATA(PIO_3_BASE, (1<<31)|(mode_ptr->sl_mask<<6)|(mode_ptr->sl_str<<2)|mode_ptr->sl_enable);

    if (resync) {
        usleep(20000);
        x_info = IORD_ALTERA_AVALON_PIO_DATA(PIO_3_BASE);
        IOWR_ALTERA_AVALON_PIO_DATA(PIO_3_BASE, (x_info & ~(1<<31)));
        IOWR_ALTERA_AVALON_PIO_DATA(PIO_3_BASE, x_info);
    }
}

int main()
{
    alt_u8 rd;
    alt_u32 btn_vec, btn_vec_prev=0;
    alt_u32 lines;
    alt_u32 ncts;
    mode_config_t *mode_ptr = &fpga_1080p;

    int init_stat;

    init_stat = init_hw();

    if (init_stat >= 0) {
        printf("### cps2_digiAV INIT OK ###\n\n");
    } else {
        printf("Init error  %d", init_stat);
        while (1) {}
    }

    program_mode(mode_ptr, 1);

    while(1) {

        btn_vec = ~IORD_ALTERA_AVALON_PIO_DATA(PIO_0_BASE) & PB_MASK;

        if ((btn_vec_prev == 0) && btn_vec) {
            if (btn_vec & PB0_BIT) {
                mode_ptr->sl_enable ^= 1;
                program_mode(mode_ptr, 0);
            }
            if (btn_vec & PB1_BIT) {
                mode_ptr->v_offset = (mode_ptr->v_offset + 1) % 9;
                program_mode(mode_ptr, 1);
            }
        }

        rd = adv7513_readreg(0x9e);
        if (!(adv7513_readreg(0x42) & 0x20)) {
            printf("Re-init ADV7513\n");
            init_adv();
        }

#ifdef DEBUG
        ncts = 0;
        ncts |= (adv7513_readreg(0x04) & 0xf) << 16;
        ncts |= adv7513_readreg(0x05) << 8;
        ncts |= adv7513_readreg(0x06);
        printf("NCTS: %lu\n", ncts);

        //printf("btnvec: 0x%x\n", btn_vec);

        /*rd = adv7513_readreg(0x9e);
        printf("ADV7513 PLL status(0x%x)\n", rd);*/
#endif
        btn_vec_prev = btn_vec;

        usleep(WAITLOOP_SLEEP_US);
    }

    return 0;
}
