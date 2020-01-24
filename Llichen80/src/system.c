/* system.c
 *
 *  Emulation of the RC2014-LL system.
 *
 *  This covers:
 *	- the general handler, poll routines
 *	- Port IO handling
 *	- memory mapping via memregion
 */

#include <stdio.h>
#include <string.h>	/* for memset(), memcpy() etc */
#include <stdlib.h>
#include "defs.h"	/* z80 emu system header */
#include "rc2014.h"	/* common rc2014 emulator headers */
#include "config.h"	/* z80 emu system header */

/* ********************************************************************** */
/*  our memory layout */

MemRegion mems[] = 
{
	/* memory maps: 

	// MAP 0
	//	0x0000	0x1fff	8k	ROM	(0)
	//	0x2000	0x7fff	24k	RAM	(2)
	//	0x8000	0xffff	32k	RAM	(3)

	// MAP 1
	//	0x0000	0x1fff	8k	RAM	(1)
	//	0x2000	0x7fff	24k	RAM	(2)
	//	0x8000	0xffff	32k	RAM	(3)

	*/
	{ 0x0000, ( 8 * 1024), REGION_RO, REGION_ACTIVE, NULL, kMem0000RomFile }, // 0
	{ 0x0000, ( 8 * 1024), REGION_RW, REGION_INACTIVE, NULL, NULL }, // 1

	{ 0x2000, (24 * 1024), REGION_RW, REGION_ACTIVE, NULL, NULL }, // 2
	{ 0x8000, (32 * 1024), REGION_RW, REGION_ACTIVE, NULL, NULL }, // 3

	REGION_END
};


void page_toggle()
{
	if( mems[0].active == REGION_ACTIVE ) {
		mems[0].active = REGION_INACTIVE;
		mems[1].active = REGION_ACTIVE;
	} else {
		mems[0].active = REGION_ACTIVE;
		mems[1].active = REGION_INACTIVE;
	}
}

void page_0()
{
	mems[0].active = REGION_ACTIVE;
	mems[1].active = REGION_INACTIVE;
	mems[2].active = REGION_ACTIVE;
	mems[3].active = REGION_ACTIVE;
}


/* ********************************************************************** */
/*  -DSYSTEM_POLL */

/* gets called once on startup immediately after z80 struct gets filled */
void system_init( z80info * z80 )
{
	/* Emulation info and credits */
	printf( "Emulation of the Llichen-80 (RC2014) system\n" );
	printf( "    version %s\n", RC2014_VERSION );
	printf( "  RC2014 by Spencer Owen\n" );
	printf( "  Emu and Llichen extensions by Scott Lawrence\n" );
	printf( "  SBC by Grant Searle\n" );
	printf( "\n" );
}

/* this gets called before each opcode is run. */
void system_poll( z80info * z80 )
{
	/* trigger an interrupt when we get a keyhit */

	/* NMI -> call 0x0066 */
	/* INTR -> call 0x0038 (IM1) */

	FromConsoleBuffered_PollConsole();

	if( FromConsoleBuffer_Available() ) 
	{
		INTR = 1; /* for IM 1 support only */
		EVENT = TRUE;
	}
}

/* this gets called on cpu reset */
void reset_handle( z80info * z80 )
{
	page_0();
	regions_display( mems );
}

/* ********************************************************************** */
/*  -DEXTERNAL_IO */
/* Port IO */


/* digital IO simulation */
void myHandlePortWrite00( const byte data )
{
	HandlePortWrite00( data );
}

void myHandlePageableRomToggler( const byte data )
{
	page_toggle();
	regions_display( mems );
}


byte HandleEmulationSignature( void ) { return 'B'; }

/* ********************************************************************** */

/* Z80 "OUT" instruction calls this if EXTERNAL_IO is defined */
void io_output( z80info *z80, byte haddr, byte laddr, byte data )
{
	ports_write( laddr, data );
}


/* Z80 "IN" instruction calls this if EXTERNAL_IO is defined */
void io_input(z80info *z80, byte haddr, byte laddr, byte *val )
{
	if( !val ) return;

	*val = ports_read( laddr );
}


/* ********************************************************************** */

/* This gets called when the emulator starts to do any additional init */
void io_init( z80info * z80 )
{
	mc6850_console_init( z80 );

	/* set up the port io */
	ports_init();

	/* Digital IO card */
	writePorts[ 0x00 ] = myHandlePortWrite00;
	readPorts[ 0x00 ] = HandlePortRead00;

	/* pageable ROM/RAM toggler */
	writePorts[ 0x38 /* = 56 */ ] = myHandlePageableRomToggler;

	/* Serial IO card */
	writePorts[ kMC6850PortTxData ] = mc6850_out_to_console_data;
	writePorts[ kMC6850PortControl ] = mc6850_out_to_console_control;

	readPorts[ kMC6850PortRxData ] = mc6850_in_from_buffered_console_data;
	readPorts[ kMC6850PortStatus ] = mc6850_in_from_buffered_console_status;

	/* emulator interface */
	writePorts[ 0xEE ] = HandleEmulationControl;
	readPorts[ 0xEE ] = HandleEmulationSignature;
}


/* ********************************************************************** */
/*  -DEXTERNAL_MEM */
/* Memory */

/* NOTE: These will have unintended effects when set from the debugger
	Debugger reads from z80->mem directly, so that chunk of memory should
	reflect all reads as intended.
*/

/* This gets called when the emulator starts to do any additional init */
void mem_init( z80info * z80 )
{
	regions_init( mems, z80->mem );

	/* force the ROM to be active. it should be anyway */
	page_0();
}


/* Z80 memory read calls this to get a byte */
word mem_read( z80info * z80, word addr )
{
	/* get the value from Z80 memory */
	byte val = regions_read( mems, addr );

	/* and return the byte from Z80 memory */
	return ( val );
}


/* Z80 memory write calls this to write a byte */
word mem_write( z80info * z80, word addr, byte val )
{
	/* status printout */
	regions_write( mems, addr, val );

	/* and set the value and return it */
	return( (z80->mem[addr] = val) );
}
