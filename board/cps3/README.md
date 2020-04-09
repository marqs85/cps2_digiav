CPS2 digital AV interface (CPS3 version)
==============

Features (current)
--------------------------
* framelocked 59.60Hz output with max. 40 scanline latency
  * 240p_CRT (for 15kHz CRTs and capture)
  * 480p_CRT (for 31kHz CRTs)
  * 720p (CEA)
  * 1080p (CEA, vertical 4x)
  * 1080p (CEA, vertical 5x) [default]
  * 1920x1200 (CVT-RB)
  * 1920x1440 (CVT-RB) [non-widescreen only]
* 24bit/48kHz audio output
* supports CPS3 standard and widescreen modes

TODO
--------------------------
* OSD/UI
* scanline options
* settings store / profiles

Installation
--------------------------
The add-on board can be installed on top of CPS3 board, preferably close to JAMMA connector. The following additional parts are required:
* 2pcs 0603 10k SMD resistors and TL2243 switch (or 2 external buttons connecting "vol+" and "vol-" pads to GND when pressed)
* ribbon cable (~15cm, at least 5x4=20 conductors)
* coaxial cable (~50cm total)
* kynar wire (~50cm total)

Signal hookup points are listed in doc/cps3_hookup_points.txt and instructions are in doc/install.md .

Usage
--------------------------
Board is controlled via TL2243 (or via 2 external buttons depending on installation):
* Upper button (VOL-): select lower output resolution
* Lower button (VOL+): select higher output resolution
