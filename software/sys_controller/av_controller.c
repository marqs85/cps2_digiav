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
#include "hdmitx.h"

// Initialize hardware
int init_hw() {
	alt_u32 chiprev;

	// Reset error vector and scan converter

	//wait >500ms for SD card interface to be stable
	usleep(200000);

	// IT6613 supports only 100kHz
	I2C_init(I2C_OPENCORES_0_BASE,ALT_CPU_FREQ,100000);

	chiprev = read_it2(IT_DEVICEID);

	if ( chiprev != 0x13) {
		printf("Error: could not read from IT6613 (0x%x)\n", chiprev);
		return -5;
	}

	InitIT6613();

	return 0;
}

inline void TX_enable(alt_u8 mode) {
    // shut down TX before setting new config
    SetAVMute(TRUE);
    DisableVideoOutput();
    EnableAVIInfoFrame(FALSE, NULL);

    // re-setup
    EnableVideoOutput(PCLK_MEDIUM, COLOR_RGB444, COLOR_RGB444, mode == 1);
    //TODO: set correct VID based on mode
    if (mode == 1)
        HDMITX_SetAVIInfoFrame(2, F_MODE_RGB444, 0, 0);

    // start TX
    SetAVMute(FALSE);

    //HDMITX_SetPixelRepetition(1, 0);
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

int main()
{
    alt_u8 rd;
    alt_u32 lines;

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

	while(1) {

		usleep(WAITLOOP_SLEEP_US);
        lines = IORD_ALTERA_AVALON_PIO_DATA(PIO_0_BASE);


        ncts = 0;
        Switch_HDMITX_Bank(1);
        //rd = read_it2(0xc5);
        //printf("osclock: 0x%x\n", rd);
        ncts |= read_it2(0x35) >> 4;
        ncts |= read_it2(0x36) << 4;
        ncts |= read_it2(0x37) << 12;
        printf("NCTS: %u\n", ncts);
        printf("lines: %u\n", lines);
	}

	return 0;
}
