/* iomem.c
 *
 *   An example file to show how IO and Memory can be implemented 
 *   outside of the z80 core
 */

#include <stdio.h>
#include <string.h>		/* for memset(), memcpy() etc */
#include "defs.h"		/* z80 emu system header */
#include "memregion.h"		/* memory region handling */
#include "mc6850_console.h"	/* mc6850 emulation as console */


/* ********************************************************************** */
/*  our memory layout */

MemRegion mems[] = 
{
    /* 0x1000 = 4kbytes */
    { 0x0000, (8 * 1024), REGION_RO, REGION_ACTIVE, NULL, "ROMs/basic.32.rom" },
    { 0x2000, (32 * 1024), REGION_RW, REGION_ACTIVE, NULL, NULL },
    REGION_END
};


/* ********************************************************************** */
/*  -DSYSTEM_POLL */

/* gets called once on startup immediately after z80 struct gets filled */
void system_init( z80info * z80 )
{
    /* Emulation info and credits */
    printf( "Emulation of the RC2014 system\n" );
    printf( "  RC2014 by Spencer Owen\n" );
    printf( "  SBC by Grant Searle\n" );
    printf( "  Emu by Scott Lawrence\n" );
    printf( "\n" );
}

/* this gets called before each opcode is run. */
void system_poll( z80info * z80 )
{
    /* trigger an interrupt when we get a keyhit */

    /* NMI -> call 0x0066 */
    /* INTR -> call 0x0038 (IM1) */

    if( z_kbhit() ) 
    {
	INTR = 1; /* for IM 1 support only */
	EVENT = TRUE;
    }
}


/* ********************************************************************** */
/*  -DEXTERNAL_IO */
/* Port IO */

/* This gets called when the emulator starts to do any additional init */
void io_init( z80info * z80 )
{
    mc6850_console_init( z80 );

    /* SD_Init()
    Bank_Init()
    */
}


/* Z80 "OUT" instruction calls this if EXTERNAL_IO is defined */
void io_output( z80info *z80, byte haddr, byte laddr, byte data )
{
    switch( laddr ) {
    case( kMC6850PortTxData ):	mc6850_out_console_data( data ); 	break;
    case( kMC6850PortControl ):	mc6850_out_console_control( data );	break;

/*
    case( kSDPortTxData ):
    case( kSDPortControl ):

    case( kROMSwapper ):
*/
    default:
	break;
    }
}


/* Z80 "IN" instruction calls this if EXTERNAL_IO is defined */
void io_input(z80info *z80, byte haddr, byte laddr, byte *val )
{
    if( !val ) return;

    /* set a default value of 0xff */
    *val = 0xff;

    switch( laddr ) {
    case( kMC6850PortRxData ):	*val = mc6850_in_console_data(); 	break;
    case( kMC6850PortStatus ):	*val = mc6850_in_console_status();	break;
/*
    case( kSDPortRxData ):
    case( kSDPortStatus ):

    case( kROMSwapper ):
*/
    default:
	break;
    }
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
