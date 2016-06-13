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
#include <string.h>		/* for memset(), memcpy() etc */
#include <stdlib.h>
#include "defs.h"		/* z80 emu system header */
#include "memregion.h"		/* memory region handling */
#include "storage.h"		/* SD card via serial port */
#include "mc6850_console.h"	/* mc6850 emulation as console */


/* ********************************************************************** */
/*  our memory layout */

MemRegion mems[] = 
{
    /* 0x1000 = 4kbytes */
    { 0x0000, (8 * 1024), REGION_RO, REGION_ACTIVE, NULL, "ROMs/lloader.rom" },
    { 0x0000, (32 * 1024), REGION_RW, REGION_ACTIVE, NULL, NULL },
    { 0x8000, (32 * 1024), REGION_RW, REGION_ACTIVE, NULL, NULL },
    REGION_END
};


void romen_update( byte val )
{
    if( val & 0x01 ) {
	mems[0].active = REGION_INACTIVE;
    } else {
	mems[0].active = REGION_ACTIVE;
    }
}


/* ********************************************************************** */
/*  -DSYSTEM_POLL */

/* gets called once on startup immediately after z80 struct gets filled */
void system_init( z80info * z80 )
{
    /* Emulation info and credits */
    printf( "Emulation of the RC2014-LL system\n" );
    printf( "  RC2014 by Spencer Owen\n" );
    printf( "  Emu and LL extensions by Scott Lawrence\n" );
    printf( "  SBC by Grant Searle\n" );
    printf( "\n" );

    /* force the ROM to be active */
    mems[0].active = REGION_ACTIVE;
    mems[1].active = REGION_ACTIVE;
    mems[2].active = REGION_ACTIVE;

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
    MassStorage_Init();
}


/* digital IO simulation */
static byte digital_io0	= 0x00; /* used for ROM EN */

static byte digital_io1	= 0x11;
static byte digital_io2	= 0x22;
static byte digital_io3	= 0x33;


/* Z80 "OUT" instruction calls this if EXTERNAL_IO is defined */
void io_output( z80info *z80, byte haddr, byte laddr, byte data )
{
    int update_romen = 0;

    switch( laddr ) {

    /* simple simulation of digital I/o, output the data we got in */
    case( 0x00 ): digital_io0 = data; update_romen = 1; break;

    case( 0x01 ): digital_io1 = data; break;
    case( 0x02 ): digital_io2 = data; break;
    case( 0x03 ): digital_io3 = data; break;

    /* console IO */
    case( kMC6850PortTxData ):	mc6850_out_console_data( data ); 	break;
    case( kMC6850PortControl ):	mc6850_out_console_control( data );	break;

    /* Mass Storage */
    case( kMassPortControl ): 	MassStorage_Control( data ); 	break;
    case( kMassPortTxData ):	MassStorage_TX( data );		break;


    /* emulator control */
    case( 0xEE ): 
	if( data == 0xF0 )
	{
		z_resetterm();
		exit( 0 );
	}
	break;

    default:
	break;
    }

    if( update_romen ) {
	romen_update( digital_io0 );
	regions_display( mems );
    }
}


/* Z80 "IN" instruction calls this if EXTERNAL_IO is defined */
void io_input(z80info *z80, byte haddr, byte laddr, byte *val )
{
    if( !val ) return;

    /* set a default value of 0xff */
    *val = 0xff;

    switch( laddr ) {

    /* simple simulation of digital I/o, output the data we got in */
    case( 0x00 ): *val = digital_io0; break;
    case( 0x01 ): *val = digital_io1; break;
    case( 0x02 ): *val = digital_io2; break;
    case( 0x03 ): *val = digital_io3; break;

    /* console IO */
    case( kMC6850PortRxData ):	*val = mc6850_in_console_data(); 	break;
    case( kMC6850PortStatus ):	*val = mc6850_in_console_status();	break;

    /* Mass Storage */
    case( kMassPortStatus ): 	*val = MassStorage_Status(); 	break;
    case( kMassPortRxData ):	*val = MassStorage_RX();	break;

    /* emulator detection */
    case( 0xEE ): *val = 'B';   break;

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
