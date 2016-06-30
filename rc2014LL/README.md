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

    $00 - Digital Input (buttons) 

    $80 - Serial I/O Board (console) - MC68B50 ACIA Status
    $81 - Serial I/O Board (console) - MC68B50 ACIA Data

    $C0 - Chained Serial Mass Storage (SD) - MC68B50 ACIA Status
    $C1 - Chained Serial Mass Storage (SD) - MC68B50 ACIA Data

    $EE - Emulation detection (reports 0x42 'B') (see ../rc2014/README.md)
	  (Note: Not in real hardware, only emulation)


## Output Ports

    $00 - Digital IO output.  bit 0 disables ROM

    $80 - Serial I/O Board (console) - MC68B50 ACIA Control
    $81 - Serial I/O Board (console) - MC68B50 ACIA Data

    $C0 - Serial Mass Storage (SD) - MC68B50 ACIA Control
    $C1 - Serial Mass Storage (SD) - MC68B50 ACIA Data
	  (Note: future versions may use a chained serial protocol to allow for multiple devices.)

    $EE - Emulation control
	  (Note: Not in real hardware, only emulation)
  	  write an $F0 to exit the emulation.

## SD File-based Content

The SD loader looks in a folder named ROMs on the SD card for the
ROM images it can load into RAM.

The first version of this loader will simply copy the file contents
to RAM starting at $0000 through whatever the size of the file is.
This copies the content verbatim from the binary file.

A future version of this loader will load in Intel HEX or IHX files
and deposit the contents to the positions in RAM as defined by these
data files.

For more information about this protocol, please refer to the
subproject in the "Arduino" folder, where it is implemented for an
Arduino host.

## SD Sector-based Content (Future)

CP/M looks for disks in a directory named "SDISKS".  In there you
should find up to 26 sub directories each named with the drive
letter (eg "SDISKS/A/" "SDISKS/B" and so on.  From there, you can
find a bunch of files named 0000.BIN 0001.BIN and so on.  These
files contain the data for that sector of the disk.  They each
contain 128 bytes of sector informaiton.  After that, they may
contain other content in each file, but that is ignored by the CP/M
bios routines.

For more information about this protocol, please refer to the
subproject in the "Arduino" folder, where it is implemented for an
Arduino host.
