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
fine.

My goals with this project are to emulate the RC2014 Z80 computer
as it currently exists, then to emulate a RC2014/LL expanded computer
before I build it myself.  I eventually plan to port CPM to this,
which I will do starting from that point, where it is in a
hardware-generatable platform, rather than a software emulation
platform, which is where this project started from.

## Project milestones

1. oubiwann-z80 project is going to be ingested, and shifted to be 
   in a subdirectory
2. The project gets a new Makefile and main.c that handles IO
3. ASM generation of a simple IO tester application
4. Implementation of IO routines for the RC2014/SBC Intel BASIC ROMs

## Support tools

In order to build everything in this project, you will need a few
additional tools:

https://code.google.com/archive/p/bleu-romtools/
- Bleu-romtools
- This is my toolset that includes a z80 c compiler (small-c based) 
  from which a modified version of a z80 assembler, "asz80" can be
  found.  Also in this project is "genroms" which takes IHX/HEX output
  from asz80 and produces flat rom binaries.

## Source credits

This project started off as a fork of oubiwann/z80 on github:

	https://github.com/oubiwann/z80
	"Z80 Instruction Set Simulator -- CP/M Boot-Ready"
	v3.1.1, February 2016

The remnants of that project are in the "z80" directory.
