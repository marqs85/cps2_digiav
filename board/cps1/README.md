CPS2 digital AV interface (Rev 2 - CPS1 branch)
==============

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
The add-on board can be installed on top of CPS1 A-board (88617A revisions currently supported). The following additional parts are required:

* cps1_adapter PCB and related parts, see pcb_cps1_adapter folder
* 3pcs 2x5 U-type pin headers
* ribbon cable
* coaxial cable (~40cm)

Installation instructions are found in pcb/doc/install.md .

Usage
--------------------------
Board is controlled via two external buttons:
* BTN1: change vertical offset (0-8, default=4)
* BTN2: enable/disable scanlines

More info and discussion
--------------------------
* [Forum topic](http://shmups.system11.org/viewtopic.php?f=6&t=59479&p=1266977)
