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
#include "flash.h"

#define PROFILE_VER_MAJOR   0
#define PROFILE_VER_MINOR   94

extern flash_ctrl_dev flashctrl_dev;

int write_userdata(uint8_t entry)
{
    ude_profile p;
    uint32_t flash_addr, bytes_written;

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

    flash_addr = flashctrl_dev.flash_size - (16-entry)*FLASH_SECTOR_SIZE;

    // Disable flash write protect and erase sector
    flash_write_protect(&flashctrl_dev, 0);
    flash_sector_erase(&flashctrl_dev, flash_addr);

    // Write data into erased sector
    memcpy((uint32_t*)(INTEL_GENERIC_SERIAL_FLASH_INTERFACE_TOP_0_AVL_MEM_BASE + flash_addr), &p, sizeof(ude_profile));

    // Re-enable write protection
    flash_write_protect(&flashctrl_dev, 1);

    return 0;
}

int read_userdata(uint8_t entry)
{
    ude_profile p;
    uint32_t flash_addr;

    if (entry > MAX_USERDATA_ENTRY) {
        printf("invalid entry\n");
        return -1;
    }

    flash_addr = flashctrl_dev.flash_size - (16-entry)*FLASH_SECTOR_SIZE;
    memcpy(&p, (uint32_t*)(INTEL_GENERIC_SERIAL_FLASH_INTERFACE_TOP_0_AVL_MEM_BASE + flash_addr), sizeof(ude_profile));

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
