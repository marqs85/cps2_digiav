CPS2 digital AV interface (Rev 2)
==============

Overview
--------------------------
cps2_digiav is an add-on for Capcom CP System II arcade board which enables digital video and audio output via HDMI connector. The project consists of an interface PCB and FPGA firmware. The board can also be installed on CPS3, see cps3 branch of the project.

Features (current)
--------------------------
* framelocked 1080p@59.64Hz output with max. 40 scanline latency
* 24bit/48kHz audio output

TODO
--------------------------
* OSD/UI
* resolution select
* more scanline options
* settings store / profiles

Installation
--------------------------
The add-on [PCB](https://oshpark.com/shared_projects/fxG9hou9) can be installed inside of CPS2 A-board. The following additional parts are required:

* 2pcs [BCS-105-L-D-PE-BE](http://www.mouser.com/ProductDetail/samtec/bcs-105-l-d-pe-be/?qs=0lQeLiL1qyYLg7p66ONHhg%3d%3d) sockets
* 2pcs 2x5 U-type pin headers
* ribbon cable (~25cm, at least 3x4=12 conductors)
* coaxial cable (~40cm)

Signal hookup points are listed in pcb/doc/cps2_hookup_points.txt and instructions are in pcb/doc/install.md .

Usage
--------------------------
Board is controlled via CPS2 volume buttons on the side (which do not affect digital volume level):
* VOL-: change vertical offset (0-8, default=4)
* VOL+: enable/disable scanlines

More info and discussion
--------------------------
* [Forum topic](http://shmups.system11.org/viewtopic.php?f=6&t=59479&p=1266977)
