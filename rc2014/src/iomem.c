/* iomem.c
 *
 *   An example file to show how IO and Memory can be implemented 
 *   outside of the z80 core
 */

#include <stdio.h>
#include <sys/select.h>  /* for FD_ functions */
#include <string.h>     /* for memset(), memcpy() etc */
#include "defs.h"
#include "memregion.h"

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

#ifndef STDIN_FILENO
#define STDIN_FILENO (0)
#endif


/* util_kbhit
 *   I done stole this from the net.
 *   A non-blocking way to tell if the user has hit a key
 */
static int util_kbhit()
{
    struct timeval tv;

    fd_set fds;
    tv.tv_sec = 0;
    tv.tv_usec = 0;
    FD_ZERO(&fds);
    FD_SET(STDIN_FILENO, &fds); //STDIN_FILENO is 0
    select(STDIN_FILENO+1, &fds, NULL, NULL, &tv);

    return( FD_ISSET(STDIN_FILENO, &fds) );
}



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

    if( util_kbhit() ) 
    {
	INTR = 1; /* for IM 1 support only */
	EVENT = TRUE;
    }
}


/* ********************************************************************** */

/* ********************************************************************** */
/*
 *      Ports and bit masks for MC6580 emulation
 */

#define kMC6850PortControl      (0x80)
        #define kPWC_Div1       0x01
        #define kPWC_Div2       0x02
                /* 0 0  / 1
                   0 1  / 16
                   1 0  / 64
                   1 1  reset
                */
        #define kPWC_Word1      0x04
        #define kPWC_Word2      0x08
        #define kPWC_Word3      0x10
                /* 0 0 0        7 E 2
                   0 0 1        7 O 2
                   0 1 0        7 E 1
                   0 1 1        7 O 1
                   1 0 0        8 n 2
                   1 0 1        8 n 1
                   1 1 0        8 E 1
                   1 1 1        8 O 1
                */
        #define kPWC_Tx1        0x20
        #define kPWC_Tx2        0x40
                /* 0 0  -RTS low, tx interrupt disabled
                   0 1  -RTS low, tx interrupt enabled
                   1 0  -RTS high, tx interrupt disabled
                   1 1  -RTS low, tx break on data, interrupt disabled
                */
        #define kPWC_RxIrqEn    0x80

#define kMC6850PortStatus       (0x80)
        #define kPRS_RxDataReady        0x01 /* rx data is ready to be read */
        #define kPRS_TXDataEmpty        0x02 /* tx data is ready for new contents */
        #define kPRS_DCD        0x04 /* data carrier detect */
        #define kPRS_CTS        0x08 /* clear to send */
        #define kPRS_FrameErr   0x10 /* improper framing */
        #define kPRS_Overrun    0x20 /* characters lost */
        #define kPRS_ParityErr  0x40 /* parity was wrong */
        #define kPRS_IrqReq     0x80 /* irq status */

#define kMC6850PortRxData       (0x81)
#define kMC6850PortTxData       (0x81)

/* 0xDx = serial based SD card */
#define kSDPortControl  (0xD1)
#define kSDPortStatus   (0xD1)
#define kSDPortRxData   (0xD0)
#define kSDPortTxData   (0xD0)

/* 0xFx = rom swapping */
#define kRomSwapper     (0xF0)


/* ********************************************************************** */
/*  -DEXTERNAL_IO */
/* Port IO */

/* This gets called when the emulator starts to do any additional init */
void io_init( z80info * z80 )
{
    /* SD_Init()
    Bank_Init()
    */
}


/* Z80 "OUT" instruction calls this if EXTERNAL_IO is defined */
void io_output( z80info *z80, byte haddr, byte laddr, byte data)
{
    switch( laddr ) {
    case( kMC6850PortTxData ):
        putchar((int) data);
        fflush(stdout);
	break;

    case( kMC6850PortControl ):
	/* ignore */
	break;

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
    byte v;
    /* an example of filling the return value */
    if( val ) *val = 0xff;

    switch( laddr ) {
    case( kMC6850PortRxData ):
	*val = 0xff;
	if( util_kbhit() ) {
	    *val = getchar();
	    //scanf (" %c", val);
//	    if( *val == 0x0d ) printf( "0x0d\n" );
	}
	break;

    case( kMC6850PortStatus ):
	v = 0;
        if( util_kbhit() ) {
                v |= kPRS_RxDataReady; /* key is available to read */
        }
        v |= kPRS_TXDataEmpty;        /* we're always ready for new stuff */
        v |= kPRS_DCD;                /* connected to a carrier */
        v |= kPRS_CTS;                /* we're clear to send */

	*val = v;
	break;

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
