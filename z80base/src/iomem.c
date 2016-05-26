/* iomem.c
 *
 *   An example file to show how IO and Memory can be implemented 
 *   outside of the z80 core
 */

#include <stdio.h>
#include "defs.h"


/* ********************************************************************** */
/*  -DSYSTEM_POLL */

/* gets called once on startup immediately after z80 struct gets filled */
void system_init( z80info * z80 )
{
    /* status printout */
    printf( "System initialization\n" );
}

/* this gets called before each opcode is run. */
void system_poll( z80info * z80 )
{
    /* status printout */
    printf( "System Poll...\n" );

    /* this is how we'd trigger an NMI: 
    NMI = 1;
     */
}

/* ********************************************************************** */
/*  -DEXTERNAL_IO */
/* Port IO */

/* This gets called when the emulator starts to do any additional init */
void io_init( z80info * z80 )
{
    /* status printout */
    printf( "IO Init\n" );
}


/* Z80 "OUT" instruction calls this if EXTERNAL_IO is defined */
void io_output( z80info *z80, byte haddr, byte laddr, byte data)
{
    /* status printout */
    printf( "IO OUT %02x: %02x\n", laddr, data );
}


/* Z80 "IN" instruction calls this if EXTERNAL_IO is defined */
void io_input(z80info *z80, byte haddr, byte laddr, byte *val )
{
    /* an example of filling the return value */
    if( val ) *val = 0xff;

    /* status printout */
    printf( "IO In %02x\n", laddr );
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
    int i;

    /* here's a short little program we'll shove into RAM to show
       that Memory and IO are functioning as expected */
    byte program[] = {
	0xF3,              // di

	0x3E, 0x55,        // ld      a, #0x55
	0xD3, 0x11,        // out     (0x11), a
	0x3C,              // inc     a
	0xD3, 0x22,        // out     (0x22), a

	0xDB, 0x12,        // in      a, (0x12)
	0xDB, 0xAB,        // in      a, (0xAB)

	0x3E, 0xAA,        // ld      a, #0xaa
	0x32, 0x00, 0x10,  // ld      (#0x1000), a
	0x3D,              // dec     a
	0x32, 0x01, 0x10,  // ld      (#0x1001), a
	0x3D,              // dec     a
	0x32, 0x02, 0x10,  // ld      (#0x1002), a

	0x06, 0x04,        //         ld      b, #4
	0x21, 0x00, 0x20,  //         ld      hl, #0x2000
	                   // here:
	0x23,              //         inc     hl
	0x70,              //         ld      (hl), b
	0x10, 0xFC,        //         djnz    here
	0x76,              //         halt
    };

    printf( "Memory init:\n" );

    /* copy the program into memory */
    for( i=0 ; i<sizeof( program ) ; i++ )
    {
	mem_write( z80, i, program[i] );
    }
}


/* Z80 memory read calls this to get a byte */
word mem_read( z80info * z80, word addr )
{
    /* get the value from Z80 memory */
    byte val = z80->mem[ addr ];

    /* status printout */
    printf( "Memory Read:  addr=0x%04x  val=0x%02x\n", addr, val );

    /* and return the byte from Z80 memory */
    return ( val );
}


/* Z80 memory write calls this to write a byte */
word mem_write( z80info * z80, word addr, byte val )
{
    /* status printout */
    printf( "Memory Write:  addr=0x%04x  val=0x%02x\n", addr, val );

    /* and set the value and return it */
    return( (z80->mem[addr] = val) );
}
