CPS2 digital AV interface (CPS3 version)
==============

Features (current)
--------------------------
* framelocked 59.60Hz output with max. 40 scanline latency
  * 240p_CRT (for 15kHz CRTs and capture)
  * 480p_CRT (for 31kHz CRTs)
  * 720p (CEA)
  * 1280x1024 (VESA) [std. aspect only]
  * 1080p (CEA, vertical 4x)
  * 1080p (CEA, vertical 5x) [default]
  * 1600x1200 (VESA) [std. aspect only]
  * 1920x1200 (CVT-RB)
  * 1920x1440 (CVT-RB) [std. aspect only]
* 24bit/48kHz audio output
* supports CPS3 standard and widescreen modes

Installation
--------------------------
The add-on board can be installed on top of CPS3 board, preferably close to JAMMA connector. The following additional parts are required:
* ribbon cable (~15cm, at least 5x4=20 conductors)
* coaxial cable (~50cm total)
* kynar wire (~50cm total)
* hookup for PCB buttons
  * if using JAMMA buttons: 2x 25cm wires
  * if using separate buttons: 2pcs 0603 10k SMD resistors and TL2243 switch (or 2 external buttons connecting "vol+" and "vol-" pads to GND when pressed)
  * if using CPS2 I/O Interface, 1pcs of XHP-2, 2pcs ASXHSXH22K305 and 2pcs 0603 10k SMD resistors

Signal hookup points are listed in doc/cps3_hookup_points.txt and instructions are in doc/install.md .

Usage
--------------------------
Board is controlled via TL2243 (or via 2 external buttons depending on installation).

Bindings outside OSD:
* VOL- (hold 1.5s): enable OSD
* VOL+ (hold 1.5s): toggle scanline mode

Bindings inside OSD:
* VOL-: next option
* VOL+: next value / select function
