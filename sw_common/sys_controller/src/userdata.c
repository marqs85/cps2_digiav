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
#include "sys/alt_flash.h"
#include "system.h"
#include "sysconfig.h"
#include "userdata.h"
#include "altera_epcq_controller2.h"

#define PROFILE_VER_MAJOR   0
#define PROFILE_VER_MINOR   92

// save some code space
#define SINGLE_FLASH_INSTANCE

alt_flash_dev *epcq_dev;

int init_flash()
{
#ifdef SINGLE_FLASH_INSTANCE
    extern alt_llist alt_flash_dev_list;
    epcq_dev = (alt_flash_dev*)alt_flash_dev_list.next;
#else
    epcq_dev = alt_flash_open_dev(EPCQ_CONTROLLER2_0_AVL_MEM_NAME);
#endif

    return (epcq_dev != NULL);
}

int write_userdata(uint8_t entry)
{
    ude_profile p;
    int retval;

    if (entry > MAX_USERDATA_ENTRY) {
        printf("invalid entry\n");
        return -1;
    }

    strncpy(p.hdr.userdata_key, "USRDATA", 8);
    p.hdr.version_major = PROFILE_VER_MAJOR;
    p.hdr.version_minor = PROFILE_VER_MINOR;
    p.avc_data_len = sizeof(avconfig_t);

    // assume that sizeof(avconfig_t) << PAGESIZE
    memcpy(&p.avc, get_current_avconfig(), sizeof(avconfig_t));

    retval = alt_epcq_controller2_write(epcq_dev, (USERDATA_OFFSET+entry*SECTORSIZE), &p, sizeof(ude_profile));

    return retval;
}

int read_userdata(uint8_t entry)
{
    ude_profile p;
    int retval;

    if (entry > MAX_USERDATA_ENTRY) {
        printf("invalid entry\n");
        return -1;
    }

    retval = alt_epcq_controller2_read(epcq_dev, (USERDATA_OFFSET+entry*SECTORSIZE), &p, sizeof(ude_profile));
    if (retval != 0) {
        printf("Flash read error\n");
        return retval;
    }

    if (strncmp(p.hdr.userdata_key, "USRDATA", 8)) {
        printf("No userdata found on entry %u\n", entry);
        return 1;
    }

    if ((p.hdr.version_major != PROFILE_VER_MAJOR) || (p.hdr.version_minor != PROFILE_VER_MINOR)) {
        printf("Profile version %u.%u does not match current one\n");
        return 2;
    }
    if (p.avc_data_len != sizeof(avconfig_t)) {
        printf("Profile version %u.%u does not match current one\n");
        return 3;
    }

    update_avconfig(&p.avc);

    return 0;
}
