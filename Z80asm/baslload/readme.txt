BasLLoad

This project will get compiled down to a .lst file, which then will
get packaged into a BASIC application.  At runtime, the program
will get poked into memory at 0xF800.  It's meant to be a very
low-overhead HEX file parser, and simple file lister.

The idea is that you run this basic program, which will poke the
program into RAM, then run it.  It will hop over to the ASM code,
where you can select the file to load.

NOTE: I may need to change the target location in RAM to be compatible
with CP/M.  This is TBD.


BASIC:
8045		Basic workspace
8045+00f9	program text area
8045+15DH	start of memory test (81A2)


0: Trigger the RAM/ROM switch too
Milestone 1: Load 32k RAM BASIC
Milestone 2: Load 64k RAM BASIC

    Addr	LL	BAS	CPM

0000	00FF	ROAM	ROM	Page0
0100	1FFF	ROAM	ROM	TPA

2000	3FFF	ROAM	ROM	TPA
4000	5FFF	ROAM		TPA
6000	7FFF	ROAM		TPA

8000	9FFF	RAM	OSRAM	TPA
A000	BFFF	RAM	RAM	TPA
C000	DBFF	RAM	RAM	TPA

DC00	E3FF	RAM	RAM	CCP - Command line interpreter
E400	F1FF	RAM	RAM	BDOS - OS functions
F200	FFFF	RAM	RAM	BIOS - Compy Specific

So we have an issue here.  We have to put the loader someplace that
won't get clobbered by loading in CP/M, and won't get clobber BASIC
ram.  First thought would be to put it below $8000, but that's
essentially ROM when this is running, and would kill BASIC to turn
it off.  We could copy BASIC to RAM, then use unused space there...
which would be most reluable to do, but that's a lot of extra effort.

By default, this would copy the loader to F800, but that will likely
be needed for loading in the BIOS... unless we build the bios in
such a way that starting at F800 is identical to this loader.. which
could be a possibility.  We could put an entry point there for doing
this hardcoded load, and then use that same portion of code in the
BIOS... making sure that everything places into the same locations.

Or, jsut to make it easier, just load this in to what will be TPA,
at say 0xC000, which is likely to be outside of BASIC workspace.

We also want to use our own IO routines, with interrupts disabled
so that we don't have to rely on the interrupt handler being 
in place while we're working.

We should be able to run the basic wrapper, which will copy this
loader into place, and run the loader, which will allow for a menu
of files to load, or hit 'return' on a timeout.

This relies on the backchannel filesystem/clock being in place as
well.

Once that happens, that HEX file will get loaded in, turn off the
ROM and reset the cpu.
