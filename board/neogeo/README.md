CPS2 digital AV interface (Neo Geo version)
==============

Features (current)
--------------------------
* framelocked 59.19Hz output (59.60Hz on AES/CD) with max. 40 scanline latency
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
The add-on board can be installed on top of MVS PCB or inside AES / CD home consoles. Installation instructions are provided for MV1C, NEO-AES3-3/AES3-6 and NEO-CDM3-1/CDM3-2 models, but the mod should be compatible with others too. The following additional parts are required:

* 2pcs 0805 10u SMD ceramic capacitors (MV1C only)
* ribbon cable
* [audio ADC board](../../pcb_neogeo_aadc) for MVS models without NEO-YSA2 chip (present in MV1C and some others) and all AES/CD
* hookup for PCB buttons
  * if using JAMMA buttons: 2x 10cm wires
  * if using separate buttons: 2pcs 0603 10k SMD resistors and TL2243 switch (or 2 external buttons connecting "vol+" and "vol-" pads to GND when pressed)

Installation instructions are found in doc/install.md (MV1C), doc/install_aes.md (AES) and doc/install_cdm.md (CD).

Usage
--------------------------
Board is controlled via TL2243 (or via 2 external buttons depending on installation).

Bindings outside OSD:
* VOL- (hold 1.5s): enable OSD

Bindings inside OSD:
* VOL-: next option
* VOL+: next value / select function
