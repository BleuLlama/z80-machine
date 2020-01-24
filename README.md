# z80-machine

This is my Z80 emulation machine. The basic purpose is to make an
easily portable and expandable Z80 emulation virtual machine platform.
The two main influences are z80Pack and "z80" from github user
oubiwann. (Which I'll refer to as "oubiwann-z80" in this document.

## Reasons for not using either of the two source projects

Z80Pack was excellent for what it is, but it would not allow for
multiple Z80 instances... Which isn't something I need right now,
but would be excellent for future expansion.  It also had an excellent
interface for IO, where you could just add handlers for the input
and output port writes which got called as callbacks at runtime.
However, it used a char buffer "ram" for all of the ram for the
system, and all of the opcodes called directly into this chunk of
memory, storing pointers into the ram chunk, rather than an address
in z80 space.  This means that it becomes near impossible to add
ram swapping routines or to have protected ROM memory, or do weird
things like have a chunk of memory where writes do one thing and
reads produce different results.

Oubiwann-z80 seems to be an excellent z80 emulator, but does not
have a straightforward way to expand the IO routines, nor does it
have the multiple machine targets that Z80Pack has.  It does however
have one very important thing, and that's an encapsulated Z80 in a
structure.  This project also allowed for protected memory, and all
of the RAM access interface that I need. Although the interface to
it is VERY intertwined with emulating a CP/M computer, which is
fine.  It also has an excellent manager/monitor with disassembler
which is awesome

My goals with this project are to emulate the RC2014 Z80 computer
as it currently exists, then to emulate a RC2014/LL expanded computer
before I build it myself.  I eventually plan to port CPM to this,
which I will do starting from that point, where it is in a
hardware-generatable platform, rather than a software emulation
platform, which is where this project started from.

## Emu Shell and Debugger

To interact with the emulator control itself, you have some
debugging controls and tools via a command shell.  You will 
see this with the prompt:
> EMU:

Type a question mark, '?' to see all available tools.  The
tools will let you examine and poke memory, trace execution,
reset the emulated machine, etc.

Type g' to start execution, and CTRL-'-' to get back to the 
emulator prompt.

## New compile-time defines, hooks

I tried to be as minimally invasive into the original source code as
possible, and to accomplish this, I use a series of DEFINEs that 
enable the various hooks and behaviors in the code. I'll list out
the additions here.  They can be seen in action in the z80base and 
rc2014 sub-projects.

AUTORUN

> This will automatically inject (g)(return) into the startup
> of the system. This will effectively tell the host monitor to
> just start executing the emulator.  You can still ctrl-c out 
> of the emulator into the monitor.

SYSTEM\_POLL

> This will enable two function calls:  system\_init() which gets called
> at system initialization time, immediately after the "z80" structure
> is populated.  Second is system\_poll() which will get called 
> immediately before the current opcode is parsed and performed.

EXTERNAL\_IO

> This enables three function calls: io\_init() which gets called at 
> system startup time.  io\_output() gets called when any OUT opcode
> is performed.  It is passed the address and data to be outputted. 
> io\_input() gets called when any IN optcode is performed.  It 
> needs to fill in the 'val' parameter with the appropriate value.

EXTERNAL\_MEM

> This enables three function calls: mem\_init() which gets called at 
> system startup time.  mem\_read() gets called when the CPU reads 
> any memory (opcodes or data).  It needs to return the appropriate 
> value.  mem\_write() gets called whenever the CPU writes to memory.

> NOTE: This does not get called when the monitor is looking through
> or disassembling memory.  Make sure that the 'mem' buffer in the
> z80 structure contains the most up-to-date version of what the 
> CPU should see, as the monitor uses that representation of memory
> directly.

RAW\_TERM

> This flag will disable the core functions' call to muck about 
> with the termcap and ioctls and all of that fancy stuff.

FILTER\_CONSOLE

> This flag will tell the system that you will want to filter the
> content going to and from the console.  This can be used to 
> remove or inject backchannel content, ansi codes, etc.
> Implement the few functions at the bottom of 'mc6850\_console.h'

RESET\_HANDLER
> This flag will enable a function call to reset\_handle() when the
> emulated CPU is hard-reset


MC6850\_SOCKET
> This flag enables a telnettable socket running on the emulator 
> which mimics the local console.  You can enter input and get 
> output from this by telnetting to port 6850.


## Support tools

In order to build everything in this project, you will need a few
additional tools:

    https://github.com/BleuLlama/bleu-romtools

- Bleu-romtools
- This is my toolset that includes a z80 c compiler (small-c based) 
  from which a modified version of a z80 assembler, "asz80" can be
  found.  Also in this project is "genroms" which takes IHX/HEX output
  from asz80 and produces flat rom binaries.


## Directories...

- Z80asm/
    -  collection of hex, and z80 asm source code to be built into ROMs.
    -  more information in the README over there...

- ROMs/
    -  Generated by the tools in the Z80asm directory

- z80orig/
    -  Slightly modified version of the oubiwann's z80 emulator
    -  Adds BUILD-CPM flag to disable CPM specific code
    -  cleanups for modern compilers
    -  (untested)

- z80base/
    -  A basic z80 emulator using the "orig" code, but with no CPM support
    -  This also uses most of the new hooks and such

- rc2014/
    - Using all the hooks and (optionally) the AUTORUN flag, it
      emulates RC2014 computer
    - This emulates the base RC2014, 32k RAM with 32K BASIC

- rc2014LL/
    - My extensions to the rc2014 computer
    - 64k RAM, switchable ROM, SD card interface
    - Arduino-based SD drive

- rc2014SB/
    - ROM/RAM switcher system

## Build info

First head into the "Z80asm" directory and type "make" to build the
romsets.

Next, go into the "rc2014" directory and type "make" to build the
emulator.

Then you can run it using "bin/rc2014".

Enjoy!

## Source credits

This project started off as a fork of oubiwann/z80 on github:

	https://github.com/oubiwann/z80
	"Z80 Instruction Set Simulator -- CP/M Boot-Ready"
	v3.1.1, February 2016

The remnants of that project are in the "z80orig" directory.
