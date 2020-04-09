CPS2 digital AV interface (CPS1 version)
==============

Features (current)
--------------------------
* framelocked 59.64Hz output with max. 40 scanline latency
  * 240p_CRT (for 15kHz CRTs and capture)
  * 480p_CRT (for 31kHz CRTs)
  * 720p (CEA)
  * 1080p (CEA, vertical 4x)
  * 1080p (CEA, vertical 5x) [default]
  * 1920x1200 (CVT-RB)
  * 1920x1440 (CVT-RB)
* 24bit/48kHz audio output

TODO
--------------------------
* OSD/UI
* scanline options
* settings store / profiles

Installation
--------------------------
The add-on board can be installed on top of CPS1 A-board (88617A revisions currently supported). The following additional parts are required:

* cps1_adapter PCB and related parts, see pcb_cps1_adapter folder
* 3pcs 2x5 U-type pin headers
* ribbon cable
* coaxial cable (~40cm)

Installation instructions are found in doc/install.md .

Usage
--------------------------
Board is controlled via two external buttons:
* BTN1 (VOL-): select lower output resolution
* BTN2 (VOL+): select higher output resolution
