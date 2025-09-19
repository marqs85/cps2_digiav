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

#ifndef SYSCONFIG_H_
#define SYSCONFIG_H_

#ifndef DEBUG
#include <stdio.h>
#define OS_PRINTF(...)
#define ErrorF(...)
#define printf(...)
#else
#include <stdio.h>
#include "utils.h"
#define OS_PRINTF printf
#define ErrorF printf
// use reduced printf
//#define printf alt_printf
#define printf dd_printf
#endif

#define sniprintf snprintf

#define NEOGEO

#define WAITLOOP_SLEEP_US   10000

#endif /* SYSCONFIG_H_ */
