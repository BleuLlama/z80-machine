# Llichwn-80 Architecture

## Overview

This is Scott's updated 64k version of the RC2014.  Its features are:

 - 8/32 kbytes of Pageable ROM
 - 64 kbytes of RAM
 - Mass storage interface via "back channel" on the console via escape sequences

The emulation here will be updated when actual hardware is fabricated.
Until then, consider this a prototype of the finalized hardware system. 

On actual hardware, the the modules used to achieve this configuration
are:

 - 64k RAM module
 - Pageable ROM module
 - Z80 CPU Module
 - Clock Module
 - TMS9918A Video Module (third party) (at 0x10/0x11)
 - 68B50 ACIA Module (at 0x80/0x81)


## Memory

Memory has two different banking configurations based on the 
output of the Paging ROM module on actual hardware.  

At power on or after reset the memory map is:

 - $0000 - $7FFF	8k BASIC ROM
 - $8000 - $FFFF	32k RAM (B)

And after a write to port 0x38 with any value, the configuration is:

 - $0000 - $7FFF	32k RAM (A)
 - $8000 - $FFFF	32k RAM (B)

Additional writes to 0x38 will toggle the configuration back and forth, as 
per the design of the Pageable ROM module


## Input (Read) Ports

	$10 - TMS9918A VRAM port
	$11 - TMS9918A Register port

    $80 - Serial I/O Board (console) - MC68B50 ACIA Status
    $81 - Serial I/O Board (console) - MC68B50 ACIA Data

    $EE - Emulation detection (reports 0x42 'B') (see ../rc2014/README.md)
	  (Note: Not in real hardware, only emulation)


## Output (Write) Ports

	$10 - TMS9918A VRAM port
	$11 - TMS9918A Register port

	$38	- Any write toggles between ROM and RAM in low memory

    $80 - Serial I/O Board (console) - MC68B50 ACIA Control
    $81 - Serial I/O Board (console) - MC68B50 ACIA Data

    $EE - Emulation control
	  (Note: Not in real hardware, only emulation)
  	  write an $F0 to exit the emulation.


# LlamaSuper - Console and Mass Storage Interface


# LlamaBDOS - Mass Storage Interface

The basic idea for Mass storage for the LL system is to implement
the storage system within the terminal emulation either on a host
computer system, or on the Raspi-Zero Pi-GFX module.  The terminal
will watch for an escape sequence, and handle it in the SSDD2 layer,
similar to the way it will handl VT100 or ANSI control sequences.

Note that this can also be implemented as a device that plugs into
the FTDI port on the RC2014, and then your USB-FTDI interface plugs
into the device.  This would likely be in the form of an Arduino
MEGA type of device with two hardware serial ports, and an SD card
reader.

This keeps the cost of doing this down, as the end users will likely
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

Implemented commands are:

 - "boot"		-- loads and runs "boot.bas"
 - "type file.bas"	-- Types the file to the RC2014
 - "more file.bas"	-- Sends the file to the console
 - "chain file.bas"	-- type, "run"
 - "loadrun file.bas" 	-- "new", "clear", type, "run"
 - "load file.bas"	-- "new", "clear", type
 - "save file.bas"	-- save out to "file.bas"
 - "catalog"		-- display a list of files to the console
 - "cd"			-- change directories to the start directory
 - "seconds"		-- types the number of seconds since 1969
 - "date"		-- types the date as "YYYYMMDD HHMMSS"

Soon to be implemented, perhaps:

 - "cd dirname"		-- change directories
 - "pwd"		-- display the current directory to the console

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

In the future there will also be commands to change virtual disks
around, and perhaps mount disk images as well.

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

- 50 - One-time setup stuff.  (internal use)

- 70 - save the current program
- 71 - clear and (re)load the current program
- 72 - clear, reload, and run the current program
- 73 - type in the specified file (current program)
- 74 - chain to the specified file

- 80 - display a catalog file listing of the current directory (direct to console)
- 81 - reset the directory to BASIC/
- 82 - start a new program based on skeleton.bas
- 83 - start the "baslload.bas" program, a HEX file loader

- 84 - types in the number of seconds since 1969
- 85 - types in the current date

And the following internal entry points, which might change:

- 60 - sends a command with a filename argument (internal use)
- 61 - sends a comamnd with no arguments (internal use)
- 98 - Helper for 84,85, does an input and prints result
- 99 - print "Ready."

