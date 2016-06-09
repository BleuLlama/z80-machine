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
void mc6850_out_console_data( byte data );

/* set control in the 6850 (baud, etc */
void mc6850_out_console_control( byte data );

/* read in data from the ACIA
 	if nothing available, returns 0xff (not sure if this is accurate)
*/
byte mc6850_in_console_data( void );

/* read in the status byte from the ACIA */
byte mc6850_in_console_status( void );

#endif
