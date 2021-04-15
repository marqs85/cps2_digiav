CPS2 digital AV interface (Neo Geo version)
==============

Features (current)
--------------------------
* framelocked 59.19Hz output with max. 40 scanline latency
  * 240p_CRT (for 15kHz CRTs and capture)
  * 480p_CRT (for 31kHz CRTs)
  * 720p (CEA)
  * 1280x1024 (VESA)
  * 1080p (CEA, vertical 4x)
  * 1080p (CEA, vertical 5x) [default]
  * 1600x1200 (VESA)
  * 1920x1200 (CVT-RB)
  * 1920x1440 (CVT-RB)
* 24bit/48kHz audio output

Installation
--------------------------
The add-on board can be installed on top of Neo Geo PCB (MV1C revision currently supported). The following additional parts are required:

* 2pcs 0603 10k SMD resistors and TL2243 switch (or 2 external buttons connecting "vol+" and "vol-" pads to GND when pressed)
* 2pcs 0805 10u SMD ceramic capacitors
* ribbon cable

Installation instructions are found in doc/install.md .

Usage
--------------------------
Board is controlled via TL2243 (or via 2 external buttons depending on installation).

Bindings outside OSD:
* VOL- (hold 1.5s): enable OSD
* VOL+ (hold 1.5s): toggle scanline mode

Bindings inside OSD:
* VOL-: next option
* VOL+: next value / select function
