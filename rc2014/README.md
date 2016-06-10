# RC2014 Architecture

## Memory

    $0000 - $1FFF	8k BASIC ROM
    $2000 - $7FFF	(unused)
    $8000 - $FFFF	32k RAM

## Input Ports

    $00 - (prototype SD bootloader card) (unavailable)

    $00 - Digital Input board (available soon)
    $01 - alternate for Digital Input Board
    $02 - alternate for Digital Input Board
    $03 - alternate for Digital Input Board

    $80 - Serial I/O Board (console) - MC68B50 ACIA Status
    $80 - Serial I/O Board (console) - MC68B50 ACIA Data

    $EE - Emulation detection (reports 0x53 'S')

## Output Ports

    $00 - (prototype SD bootloader card) (unavailable)

    $00 - Digital Output board (available soon)
    $01 - alternate for Digital Output Board
    $02 - alternate for Digital Output Board
    $03 - alternate for Digital Output Board

    $80 - Serial I/O Board (console) - MC68B50 ACIA Control
    $80 - Serial I/O Board (console) - MC68B50 ACIA Data

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
