# RC2014-LL Architecture

## Overview

This is Scott's updated 64k version of the RC2014.  Its features are:

 - 64 kbytes of RAM
 - 8 kbytes of ROM
 - Boot ROM installed that offers the ability to load from SD card
 - SD interface via console escape sequences (LlamaBDOS)

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

    $C0 - Chained Serial - MC68B50 ACIA Status
    $C1 - Chained Serial - MC68B50 ACIA Data

    $EE - Emulation detection (reports 0x42 'B') (see ../rc2014/README.md)
	  (Note: Not in real hardware, only emulation)


## Output Ports

    $00 - Digital IO output.  bit 0 disables ROM
		xxxx xxx0  - ROM is enabled, RAM0000 disabled
		xxxx xxx1  - ROM is disabled, RAM0000 enabled

    $80 - Serial I/O Board (console) - MC68B50 ACIA Control
    $81 - Serial I/O Board (console) - MC68B50 ACIA Data

    $C0 - Chained Serial - MC68B50 ACIA Control
    $C1 - Chained Serial - MC68B50 ACIA Data
	  (Note: future versions will use chained serial for expansion)

    $EE - Emulation control
	  (Note: Not in real hardware, only emulation)
  	  write an $F0 to exit the emulation.



# LlamaBDOS - Mass Storage Interface

The basic idea for Mass storage for the LL system is to implement
the storage system within the terminal emulation either on a host
computer system, or on the Raspi-Zero Pi-GFX module.  The terminal
will watch for an escape sequence, and handle it in the SSDD2 layer,
similar to the way it will handl VT100 or ANSI control sequences.

This keeps the cost of doing this down, as the end users will likelu
already have the PigFX module, or can get it cheaply.  It also means
that no additional hardware is necessary... a "software only" mass
storage system, if you will.

The downside of this of course is that it may be slow.  But I think
that's an acceptable tradeoff.

## Modes of Operation

The mass storage layer implements a few different interfaces which
can easily be used to retrieve and store data.  They will be explained
here.

### Typing Mode

This mode allows for applications that do not support disk operations
to easily be expanded for storage and retrieval of data.  Primarily,
this can be used to load and save files with the RC2014-provided
NASCOM BASIC.  Or it can be used to transfer text files to and from
the computer without any additional code written.  

It essentially "types" out files, and saves text being displayed.

There is an included file "skeleton.bas" which can be loaded via the 
autoboot mechanism (copy it as "boot.bas") or can be loaded in using
this one-line program

    10 PRINT CHR$(27);CHR$(123);"loadrun skeleton.bas";CHR$(7) 

See below for the Skeleton.bas documentation.

### File Mode

This mode allows for binary file streams to be loaded and saved to
the mass storage location.  The files will be encoded (plain
ascii-hex) for transfer, which is safer, but slower.

### Sector File Disk Image Mode

This mode is implemented simialrly to File Mode, but instead of
opening a specific file for read/write, it operates on a disk+track+sector
mechanism similar to the way CP/M accesses its disks.  It is designed
to work directly with CP/M.  Data is transferred as 128 byte sectors,
and stored in a directory heirarchy on the host side that reflects
the disk geometry.

This will use a directory named "SFDI" (Sector File Disk Images)
to store its data.  In there you should find up to 26 sub directories
each named with the drive letter, then a series of directories named
000, 001, 002, etc, then in each of those you'll find 0000.BIN,
0001.BIN and so on.  These map to the CP/M way of looking at mass
storage devices.  For example the path

	/SFDI/E/002/094.BIN

is the path to a 128 byte file, "125.BIN" that contains the data stored
for Drive E, Track 2, Sector 94.

## Escape Sequences

This documentation would be incomplete without the full protocol.  So here
it is.

The sequence starts with 'esc'-'{', or in hex values: 0x1b, 0x7b,
and ends with a '}' at the end, hex value 0x7d. These characters
are illegal within the sequence.

The first field is "Command ID".  This specifies what the remote
operation or contained data is.  The following optional fields
indicate parameters.  The fields are separted by commas.  For series
of bytes, they are sent as ascii values for '0'-'9' and 'A'-'F'.
The series lasts until tne next character not in this range.
Whitespace in these sequences is ignored.

The display parser should be switched into command mode when it
gets the sequence 'esc'-'{' and should remain in it until it recieves
a '}' or it is manually reset. If it receives an 'esc' and another
character, it should send down the 'esc' then the other character,
so that its operation is transparent to the next display handlers.

If a command expects a response, its identifier will end with a ?.
If it is the response for a command, the character after the
identifier will be a comma, followed by the requested value.

# Autostart Interface

In order to simplify things, the filtering system will detect a
phrase in the data stream, and if it sees it, it will send down 
a boot command back to the terminal.  This will aid in relatively
hands-off autobooting sequences.  The way to trigger this is by
entering '0' for "Memory Top?" in NASCOM BASIC.  This text
sequence is not otherwise printed out, and entering '0' will
not cause an error with BASIC, so it is a reasonable mechanism
to piggyback on.

By default, this will trigger an "loadrun" of "boot.bas", which
will "type" it in, then type "run".

# Skeleton.bas

This file is provided as an interface for BASIC to add in load,
save, chain, and disk interface functionality. It will occupy the
space between and including lines 50 through 99. This gives you 49
lines for REM style commenting about your program, and then 100-9999
for your application.

It also uses two variables:
- f$ - to define the self-program's filename
- c$ - to define the command to be used. 

To configure it for your program, change the filename you wish to
use for your program on line 51, and when you load in the program
just type "run 50" to set up this (and other future) variables.

The following entry points and line regions will always be 
backwards compatible with the following definitions. These can also
be adapted for your own use, like for example command 73.

- 50 - One-time setup stuff.  Edit on a new program, and type "run 50" to configure
- 70 - save the current program
- 71 - clear and (re)load the current program
- 72 - clear, reload, and run the current program
- 73 - type in the specified file (current program)
- 74 - chain to the specified file
- 80 - display a catalog file listing of the current directory (direct to console)
- 81 - reset the directory to BASIC
- 82 - start a new program based on skeleton.bas
- 83 - start the "baslload.bas" program, a HEX file loader

And the following internal entry points, which might change:

- 60 - sends a command with a filename argument (internal use)
- 61 - sends a comamnd with no arguments (internal use)
- 99 - print ready

