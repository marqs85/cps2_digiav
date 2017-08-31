CPS2 digital AV interface
==============

Overview
--------------------------
cps2_digiav is an add-on for Capcom CP System II arcade board which enables digital video and audio output via HDMI connector. The project consists of an interface PCB and FPGA firmware.

Features (pcb v1.0)
--------------------------
* 2 selectable video outputs
  * 640x480@59.64Hz (near-VESA)
  * 1920x1080@59.64Hz (reduced hblank, increased vblank)
* ~48kHz audio output
* Scanlines enable/disable

Installation
--------------------------
The add-on board can be installed inside (preferred method) or outside of CPS2 A-board. Signal hookup points are listed in pcb/pcb_v1.0/doc/cps2_hookup_points.txt . After installation, FPGA firmware must be uploaded via JTAG using Altera USB Blaster -compatible programmer.

Usage
--------------------------
Resolution switch and scanline enabling are implemented via CPS2 volume buttons on the side (which do not affect digital volume level):
* VOL-: switch output resolution
* VOL+: enable/disable scanlines

More info and discussion
--------------------------
* [Forum topic](http://shmups.system11.org/viewtopic.php?f=6&t=59479&p=1266977)
* [Pre-built firmware](https://www.niksula.hut.fi/~mhiienka/cps2_digiav/fw/)
