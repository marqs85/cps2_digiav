CPS2 digital AV interface (CPS2 version)
==============

Features (current)
--------------------------
* framelocked 59.64Hz output with max. 40 scanline latency
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
The add-on board can be installed inside of CPS2 A-board. The following additional parts are required:

* 2pcs [BCS-105-L-D-PE-BE](http://www.mouser.com/ProductDetail/samtec/bcs-105-l-d-pe-be/?qs=0lQeLiL1qyYLg7p66ONHhg%3d%3d) sockets
* 2pcs 2x5 U-type pin headers
* ribbon cable (~25cm, at least 3x4=12 conductors)
* coaxial cable (~40cm)

Signal hookup points are listed in doc/cps2_hookup_points.txt and instructions are in doc/install.md .

Usage
--------------------------
Board is controlled via CPS2 volume buttons on the side (which do not affect digital volume level).

Bindings outside OSD:
* VOL- (hold 1.5s): enable OSD
* VOL+ (hold 1.5s): toggle scanline mode

Bindings inside OSD:
* VOL-: next option
* VOL+: next value / select function
