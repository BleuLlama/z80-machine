/* MC6850 emulation
 *
 *  2016-06-08 Scott Lawrence 
 */

#include <stdio.h>
#include <unistd.h>		/* for usleep */
#include <sys/time.h>		/* for timeval */
#include "mc6850_console.h"	/* port bit definitions */



/* ********************************************************************** */

/* initialize the ACIA */
void mc6850_console_init( z80info * z80 )
{
    /* do nothing */
}

/* send out a byte of data */
void mc6850_out_to_console_data( byte data )
{
    /* send out a byte to the console */
    putchar( (int) data);
    fflush( stdout );
}

/* set control in the 6850 (baud, etc */
void mc6850_out_to_console_control( byte data )
{
    /* do nothing -- ignored */
}



/* read in data from the ACIA (from the console terminal directly)
 	if nothing available, returns 0xff (not sure if this is accurate)
*/
byte mc6850_in_from_console_data( void )
{
    byte val = 0xff;

    /* get in a byte from the console */
    if( z_kbhit() ) {
	    val = getchar();
    }

    return val;
}

/* read in the status byte from the ACIA */
byte mc6850_in_from_console_status( void )
{
    byte val = 0;

    if( z_kbhit() ) {
	    val |= kPRS_RxDataReady; /* key is available to read */
    }
    val |= kPRS_TXDataEmpty;        /* we're always ready for new stuff */
    val |= kPRS_DCD;                /* connected to a carrier */
    val |= kPRS_CTS;                /* we're clear to send */

    return val;
}



/* ********************************************************************** */


/* utility function to get the number of milliseconds since we started */
static long long millis( void )
{
    struct timeval te; 
    long long milliseconds;

    static long long startTime = 0;

    /* get current time */
    gettimeofday(&te, NULL);

    /* adjust the start time */
    if( startTime == 0 ) {
	/* calculate milliseconds */
	startTime = te.tv_sec*1000LL + te.tv_usec/1000;
    }

    /* calculate milliseconds */
    milliseconds = te.tv_sec*1000LL + te.tv_usec/1000;

    return milliseconds;
}


/* ********************************************************************** */

/* pseudo-circular buffer, start and end indeces */
static char intbuffer[ kRingBufSz ];
static int bs = 0;
static int be = 0;

/* add an item to our pseudo-circular buffer */
static void buffered_queue( char ch )
{
    /* check to see if it collapsed, and clean it up */
    if( bs == be ) {
	if( bs != 0 ) { bs = be = 0; }
    }

    /* add the character on the end */
    intbuffer[ be ] = ch;
    if( be < kRingBufSz ) be++;
}

/* remove an item from our pseudo-circular buffer */
static byte buffered_dequeue( void )
{
    byte ret = 0xff;

    /* if we have something... */
    if( bs != be ) {
	ret = intbuffer[ bs ];
	bs++;
    }

    /* check to see if it collapsed, and clean it up */
    if( bs == be )
    {
    	/* reset the queue head and tail */
	if( bs != 0 ) { bs = be = 0; }
    }

    return ret;
}


/* the next timestamp to read a byte */
long long nextm = 0;
int burst = 0;

/* the kbhit() that references our buffer. */
int buffered_kbhit( void )
{
    if( bs == be ) return 0;

    if( millis() > nextm ) {
	return 1;
    }

    return 0;
}


/* this gets polled from the main loop to update our buffer */
void buffered_console_poll( void )
{
    /* just queue up all available characters... */
    while ( z_kbhit() ) {
	buffered_queue( getchar() );
    }
}


/* only get a character from our buffer when it's time.
   if it's not time, return 0xff */
byte mc6850_in_from_buffered_console_data( void )
{
    if( buffered_kbhit() ) 
    {
	if( burst > kBurstCount ) {
	    nextm = millis() + kThrottleMS;
	    burst = 0;
	}
	burst++;
    	return buffered_dequeue();
    }

    return 0xff;
}


/* get the status about our buffer... */
byte mc6850_in_from_buffered_console_status( void )
{
    byte val = 0;

    if( buffered_kbhit() ) {
            val |= kPRS_RxDataReady; /* key is available to read */
    }
    val |= kPRS_TXDataEmpty;        /* we're always ready for new stuff */
    val |= kPRS_DCD;                /* connected to a carrier */
    val |= kPRS_CTS;                /* we're clear to send */

    return val;
}
