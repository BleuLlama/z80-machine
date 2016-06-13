# RC2014-LL Architecture

## Overview

This is Scott's updated 64k version of the RC2014.  It's features are:

 - 64 kbytes of RAM
 - 8 kbytes of ROM
 - Boot ROM installed that offers the ability to load from SD card
 - ACIA based SD card interface
 - SD Card Serial device (like C64 floppy drives)

The emulation here will be updated when actual hardware is fabricated.
Until then, consider this a prototype of the finalized hardware
system.  This is used to build the firmware.


## Memory

    $0000 - $1FFF	8k BASIC ROM (disableable)
    $0000 - $7FFF	32k RAM
    $8000 - $FFFF	32k RAM


When bit 0 of the Digital IO output is set to 0, reads to memory
region $0000 thru $1fff will return with values from the ROM.  When
that bit is set to 1, reads will come from the RAM.  Writes to this
region will always go to the RAM.

This allows for the ROM program to write content to the RAM that
occupies the same address space as the ROM.  The ROM can then be
switched off, and the content in RAM from the same address space
can be read and written to.

To return the ROM to memory space, simply write a '0' out to that
Digital IO output.  For the sake of emulation, until hardware is
implemented, this port will be at port address $03.


## Input Ports

    $03 - Digital Input (buttons) 

    $80 - Serial I/O Board (console) - MC68B50 ACIA Status
    $81 - Serial I/O Board (console) - MC68B50 ACIA Data

    $D0 - Chained Serial Mass Storage (SD) - MC68B50 ACIA Status
    $D1 - Chained Serial Mass Storage (SD) - MC68B50 ACIA Data

    $EE - Emulation detection (reports 0x42 'B') (see ../rc2014/README.md)


## Output Ports

    $03 - Digital IO output.  bit 0 disables ROM

    $80 - Serial I/O Board (console) - MC68B50 ACIA Control
    $81 - Serial I/O Board (console) - MC68B50 ACIA Data

    $D0 - Chained Serial Mass Storage (SD) - MC68B50 ACIA Control
    $D1 - Chained Serial Mass Storage (SD) - MC68B50 ACIA Data
