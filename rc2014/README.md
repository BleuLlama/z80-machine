# RC2014 Architecture

## Overview

This is the 32k base model of the RC2014 computer from Spencer Owen, based
on the Single Board Computer (SBC) from Grant Searle.  This version of 
the emulation 

 - 32 kbytes of RAM
 - 8 kbytes of ROM
 - ACIA serial terminal interface
 - IO card support 
 - Digital Input support (basic)
 - Digital Output support (basic)

Input and output card support does not display or read the value from
anyplace other than itself.  See more details below.

## Memory

    $0000 - $1FFF	8k BASIC ROM (NASCOM 32k version)
    $2000 - $7FFF	(unused)
    $8000 - $FFFF	32k RAM


## Input Ports

    $00 - (prototype SD bootloader card) (unavailable)

    $00 - Digital Input board (available soon)

    $01 - alternate for Digital Input Board
    $02 - alternate for Digital Input Board
    $03 - alternate for Digital Input Board

    $80 - Serial I/O Board (console) - MC68B50 ACIA Status
    $81 - Serial I/O Board (console) - MC68B50 ACIA Data

    $EE - Emulation detection (reports 0x41 'A') (See below)
	  (Note: Not in real hardware, only emulation)


## Output Ports

    $00 - (prototype SD bootloader card) (unavailable)

    $00 - Digital Output board (available soon)
    $01 - alternate for Digital Output Board
    $02 - alternate for Digital Output Board
    $03 - alternate for Digital Output Board

    $80 - Serial I/O Board (console) - MC68B50 ACIA Control
    $81 - Serial I/O Board (console) - MC68B50 ACIA Data


## Emulation info...

For the sake of settling on something for the emulation, the memory
is as defined above. It will attempt to load the rom file
"ROMs/basic.32.rom".

For ports, it uses $80/$81 for the simulated terminal input, which
is accomplished via termcap, so that your typing goes in to simualted
port $80 on the computer, and all text comes out through port $80
as well.

Four Digital IO ports are configured at $00, $01, $02, and $03.
These are wired to themselves, so a write to $00 will appear on a
read from $00 as well, and similarly for $01, $02, and $03.  Anything
written to port $02 will be read back from a read on port $02.


## Emulation detection

To aid in runtime checks, I've added a virtual port at $EE.  Reads
from this port on actual hardware will produce 0x00 or 0xFF (untested)
but on emulation, it will produce a known, defined result.  What
follows is the "registry" of all of the valid responses, and what
emulation they refer to.

 - $00 - reserved / undefined
 - $FF - reserved / undefined
 - $41 - 'A' - RC2014 base hardware (this project)
 - $42 - 'B' - RC2014LL - Scott Lawrence's 64k ROM switchable system
 - See other projects' README files in this repository for other values...
