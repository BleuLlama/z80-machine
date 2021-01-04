/* system.c
 *
 *  Emulation of the RC2014 system.
 *
 *  This covers:
 *	- the general handler, poll routines
 *	- Port IO handling
 *	- memory mapping via memregion
 */

#include <stdio.h>
#include <string.h>	/* for memset(), memcpy() etc */
#include <stdlib.h>	/* for exit() */
#include "defs.h"	/* z80 emu system header */
#include "rc2014.h"	/* common rc2014 emulator headers */


/* ********************************************************************** */
/*  our memory layout */

MemRegion mems[] = 
{
    /* 0x1000 = 4kbytes */
    // PAGEABLE BASIC ROM MODULE
    { 0x0000, (8 * 1024),  REGION_RO, REGION_ACTIVE, NULL, "ROMs/basic32.rom" },

    // 64k RAM MODULE
    { 0x0000, (32 * 1024), REGION_RW, REGION_INACTIVE, NULL, NULL },
    { 0x8000, (32 * 1024), REGION_RW, REGION_ACTIVE, NULL, NULL },
    REGION_END
};


/* lowmem_page
    changes the lowmem to something different.

    if val == 0, then it will force it back to ROM
    otherwise, it will toggle between ROM and RAM
*/
void lowmem_page( const byte val )
{
    if( val == 0 ) {
        mems[0].active = REGION_ACTIVE;
        mems[1].active = REGION_INACTIVE;
        return;
    }

    // otherwise toggle it!
    if( mems[0].active == REGION_ACTIVE ) {
        mems[0].active = REGION_INACTIVE;
        mems[1].active = REGION_ACTIVE;

    } else {
        mems[0].active = REGION_ACTIVE;
        mems[1].active = REGION_INACTIVE;

    }
}



/* ********************************************************************** */
/*  -DSYSTEM_POLL */

/* gets called once on startup immediately after z80 struct gets filled */
void system_init( z80info * z80 )
{
    /* Emulation info and credits */
    printf( "Emulation of the RC2014 system\n" );
    printf( " - Digital IO Module at 0x00\n" );
    printf( " - Pageable ROM at 0x38\n" );
    printf( "    version %s\n", RC2014_VERSION );
    printf( "  RC2014 by Spencer Owen\n" );
    printf( "  SBC by Grant Searle\n" );
    printf( "  Emu by Scott Lawrence\n" );
    printf( "\n" );
}

/* this gets called before each opcode is run. */
void system_poll( z80info * z80 )
{
    /* poll the buffered console handler */
    FromConsoleBuffered_PollConsole();

    /* trigger an interrupt when we get a keyhit */

    /* NMI -> call 0x0066 */
    /* INTR -> call 0x0038 (IM1) */

    if( FromConsoleBuffer_Available() ) 
    {
    	INTR = 1; /* for IM 1 support only */
    	EVENT = TRUE;
    }
}


/* ********************************************************************** */
/*  -DEXTERNAL_IO */
/* Port IO */

/* digital IO simulation */
void myHandlePortWrite38( const byte data )
{
    lowmem_page( 1 );   // toggle ROM <--> RAM
    regions_display( mems );
}

/*  -DRESET_HANDLER */

void reset_handle( z80info *z80 )
{
    // in a reset, it will force it back to ROM
    lowmem_page( 0 );
    regions_display( mems );
}


byte HandleEmulationSignature( void ) { return 'A'; }



/* Z80 "OUT" instruction calls this if EXTERNAL_IO is defined */
void io_output( z80info *z80, byte haddr, byte laddr, byte data )
{
    ports_write( laddr, data );

    if( laddr >= 0x00 && laddr <= 0x03 ) {
	printf( ">> $%02x: ($%02x b"BYTE_TO_BINARY_PATTERN")"
		  "\n", 
		laddr, data, BYTE_TO_BINARY( data ) );
    }
}


/* Z80 "IN" instruction calls this if EXTERNAL_IO is defined */
void io_input(z80info *z80, byte haddr, byte laddr, byte *val )
{
    if( !val ) return;

    *val = ports_read( laddr );
}



/* This gets called when the emulator starts to do any additional init */
void io_init( z80info * z80 )
{
    mc6850_console_init( z80 );

    /* set up the port io */
    ports_init();

    /* Digital IO card */
    writePorts[ 0x00 ] = HandlePortWrite00;
    readPorts[ 0x00 ] = HandlePortRead00;

    /* Input and Output cards */
    writePorts[ 0x01 ] = HandlePortWrite01;
    writePorts[ 0x02 ] = HandlePortWrite02;
    writePorts[ 0x03 ] = HandlePortWrite03;
    readPorts[ 0x01 ] = HandlePortRead01;
    readPorts[ 0x02 ] = HandlePortRead02;
    readPorts[ 0x03 ] = HandlePortRead03;

    /* Pageable ROM */
    writePorts[ 0x38 ] = myHandlePortWrite38;

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
