A-board (revision 89626A-4) signal reference
--------------------------
[List of hookup points](./cps1_hookup_points.txt)

![](cps1_hookup_points.jpg)


Step 1: Preparation
--------------------------

Solder 3pcs U-shaped 2x5 headers M5M RAM chips as shown in the image below. Solder BCS-105-L-D-PE-BE sockets on cps1_adapter (J1-3) and trim down pin metals underside the PCB. Make sure the adapter PCB fits in place before going forward. Solder R7+R8 (2x10k 0603 SMD resistors) on bottom of cps2_digiav board. Install cps2_digiav on top of adapter board via 4pcs 5-pin headers **without using spacers**.

![](install-1.jpg)

It is recommened to cover PAL 10A1 IC legs with electrical tape (at least on the side closer to PCB edge) as well as B-board bottom area above JTAG connector (full-length B-boards only). A-board resistor arrays (RA6-8) can be bent a little towards center so that adapter board PCB lies on level above them.

![](install-2.jpg)


Step 2: Clock and sync signals
--------------------------

Clock is available on 74F32. It's mandatory to use a coax cable to avoid stability issues caused by noise. Composite sync is extracted from R28 as shown in the signal reference image (connect to HS pin on cps2_digiav).


Step 3: Audio, power and button signals
--------------------------

Audio is extracted from YM2151 and R49. Use coax cable for oCM and DAO signals.

5V/GND can be extracted from certain CCX caps, e.g. the one shown in the signal reference image.

The board is operated via 2 keys which can be implemeted with one of the alternatives below:
* Wire vol-/vol+ pads to existing button lines on JAMMA connector (e.g. P1 credit & start).
* Wire two external pushbuttons to the board: one terminal to GND and another to vol-/vol+. Solder resistors R7 and R8 (10k 0603) to the board.
* If using CPS2 I/O Interface, vol-/vol+ pads can be wired to its up/down keys (see parts list on main README). R7 and R8 need to be installed as well.

![](install-3.jpg)


Step 4: Signals between cps1_adapter and cps2_digiav
--------------------------

Bridge SMD jumpers J3, J5 and J6 on cps2_digiav board. Connect oC1, SH1, SO and 3v3 from cps1_adapter to cps2_digiav as defined in the hookup point list. Add a jumper wire between C1 and C2 pads. (Note that cps2_digiav PCB in picture below is v2.0 which is slightly different)

![](install-4.jpg)


