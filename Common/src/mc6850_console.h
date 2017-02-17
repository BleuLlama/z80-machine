/* MC6850 console emulation
 *
 *  2016-06-08 Scott Lawrence 
 */

#include "mc6850.h"	/* port bit definitions */
#include "defs.h"	/* z80 interface, etc */

#ifndef __MC6850_CONSOLE_H__
#define __MC6850_CONSOLE_H__

/* ********************************************************************** */
/*
 *      Ports for MC6580 emulation
 */

    /* data */
#define kMC6850PortRxData       (0x81)
#define kMC6850PortTxData       (0x81)

    /* status and control */
#define kMC6850PortStatus       (0x80)
#define kMC6850PortControl      (0x80)


/* ********************************************************************** */

/* initialize the ACIA */
void mc6850_console_init( z80info * z80 );

/* send out a byte of data */
void mc6850_out_to_console_data( byte data );

/* set control in the 6850 (baud, etc */
void mc6850_out_to_console_control( byte data );

/* read in data from the ACIA
 	if nothing available, returns 0xff (not sure if this is accurate)
*/
byte mc6850_in_from_console_data( void );

/* read in the status byte from the ACIA */
byte mc6850_in_from_console_status( void );


/* ********************************************************************** */
/* internal buffered versions */

/* minimum time in milliseconds between keypresses */
#define kThrottleMS	(10)
/* number of keypresses to send out every duration timeout */
#define kBurstCount	(5)
/* size of the buffer */
#define kRingBufSz 	(1024 * 64) /* There's a lot of space in this mall! */

/* as described in the above defines, the following use a 
    pseudo-ring buffer of kRingBufSz bytes.  It will send out 
    kBurstCount available bytes from the buffer every kThrottleMS 
    milliseconds. 
*/

/* poll routine to be called from the system_poll() */
void FromConsoleBuffered_PollConsole( void );

/* is a byte available in the buffer? */
int FromConsoleBuffer_Available( void );



/* get the data byte or 0xFF if none */
byte mc6850_in_from_buffered_console_data( void );

/* get the status */
byte mc6850_in_from_buffered_console_status( void );


/* ********************************************************************** */
/* to be implemented for Filters */ 

void Filter_Init( z80info * z80 );

/* Handlers for content going TO the CONSOLE */
void Filter_ToConsole( byte data );
int  Filter_ToConsoleAvailable();
byte Filter_ToConsoleGet();

/* Add stuff into the Console send buffer (typer buffer) */
void FromConsoleBuffer_QueueChar( char ch );
void FromConsoleBuffer_QueueString( char * str );

/* Handlers for content going TO the REMOTE */
void Filter_ToRemote( byte data );
int  Filter_ToRemoteAvailable();
byte Filter_ToRemoteGet();

#endif
