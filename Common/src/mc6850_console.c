/* MC6850 emulation
 *
 *  2016-06-08 Scott Lawrence 
 *
 *  Note: The terminology in this can get confusing, so i'm going to 
 *        define this right now:
 *					running on "HOST"
 *              REMOTE                 CONSOLE --> OS specific display
 *                    ---- TO ----->
 *                    <---- FROM ----
 *
 */

#include <stdio.h>
#include <unistd.h>		/* for usleep */
#include <stdlib.h>		/* for exit */
#include <sys/time.h>		/* for timeval */
#include "mc6850_console.h"	/* port bit definitions */
#include "host.h"		/* host console interface */


/* ********************************************************************** */

/* initialize the ACIA */
void mc6850_console_init( z80info * z80 )
{
#ifdef FILTER_CONSOLE
    Filter_Init( z80 );
#else
    /* do nothing */
#endif
}

/* send out a byte of data */
void mc6850_out_to_console_data( byte data )
{
#ifdef FILTER_CONSOLE
    /* send it into the filter */
    Filter_ToConsole( data );

    /* and poll the filter for bytes to display to the host console */
    while( Filter_ToConsoleAvailable() )
    {
	Host_PutChar( Filter_ToConsoleGet() );
    }
#else
    /* send out a byte to the console */
    Host_PutChar( data );
#endif
}

/* set control in the 6850 (baud, etc */
void mc6850_out_to_console_control( byte data )
{
    /* do nothing -- ignored */
    /* this would be for setting baud, etc. */
}



/* read in data from the ACIA (from the console terminal directly)
 	if nothing available, returns 0xff (not sure if this is accurate)
*/
byte mc6850_in_from_console_data( void )
{
#ifdef FILTER_CONSOLE
    /* incompatible with FILTER */
    printf( "mc6850_in_from_console_data() is incompatible with FILTER_CONSOLE\n" );
    printf( "use mc6850_in_from_buffered_console_data() instead!\n" );
    exit( -1 );
#endif

    return Host_GetChar( 0xff );
}


/* read in the status byte from the ACIA */
byte mc6850_in_from_console_status( void )
{
    byte val = 0;
    int available = 0;

#ifdef FILTER_CONSOLE
    /* incompatible with FILTER */
    printf( "mc6850_in_from_console_status() is incompatible with FILTER_CONSOLE\n" );
    printf( "use mc6850_in_from_buffered_console_status() instead!\n" );
    exit( -1 );
#endif

    available = Host_KeyHit();

    if( Host_KeyHit() ) {
	    val |= kPRS_RxDataReady; /* key is available to read */
    }
    val |= kPRS_TXDataEmpty;        /* we're always ready for new stuff */
    val |= kPRS_DCD;                /* connected to a carrier */
    val |= kPRS_CTS;                /* we're clear to send */

    return val;
}



/* ********************************************************************** */
/* pseudo-circular buffer */


static char intbuffer[ kRingBufSz ];

/* start and end indeces */
static int bs = 0;
static int be = 0;


/* add an item to our pseudo-circular buffer */
void FromConsoleBuffer_QueueChar( char ch )
{
    /* check to see if it collapsed, and clean it up */
    if( bs == be ) {
	if( bs != 0 ) { bs = be = 0; }
    }

    /* add the character on the end */
    intbuffer[ be ] = ch;
    if( be < kRingBufSz ) be++;
}

void FromConsoleBuffer_QueueString( char * str )
{
    while( str && *str ) {
	FromConsoleBuffer_QueueChar( *str );
	str++;
    }
}


/* remove an item from our pseudo-circular buffer */
static byte FromConsoleBuffer_Dequeue( void )
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

/* ********************************************************************** */
/* Our Available also checks time to throttle the input to the emulation */

/* the next timestamp to read a byte */
long long nextm = 0;
int burst = 0;

/* the kbhit() that references our buffer. */
int FromConsoleBuffer_Available( void )
{

    if( bs == be ) return 0;

    if( Host_Millis() > nextm ) {
	return 1;
    }

    return 0;
}

/* ********************************************************************** */

/* this gets polled from the main loop to update our buffer */
void FromConsoleBuffered_PollConsole( void )
{

#ifdef FILTER_CONSOLE
    /* just queue up all available characters... */
    while ( Host_KeyHit() ) {
       Filter_ToRemote( Host_GetChar( 0x00 ) );
    }

    /* and poll the filter for bytes to send to the remote */
    while( Filter_ToRemoteAvailable() )
    {
        FromConsoleBuffer_QueueChar( Filter_ToRemoteGet() );
    }

#else
    /* just queue up all available characters... */
    while ( Host_KeyHit() ) {
	FromConsoleBuffer_QueueChar( Host_GetChar( 0x00 ) );
    }
#endif
}


/* only get a character from our buffer when it's time.
   if it's not time, return 0xff */
byte mc6850_in_from_buffered_console_data( void )
{
    if( FromConsoleBuffer_Available() ) 
    {
	if( burst > kBurstCount ) {
	    nextm = Host_Millis() + kThrottleMS;
	    burst = 0;
	}
	burst++;
    	return FromConsoleBuffer_Dequeue();
    }

    return 0xff;
}


/* get the status about our buffer... */
byte mc6850_in_from_buffered_console_status( void )
{
    byte val = 0;

    if( FromConsoleBuffer_Available() ) {
            val |= kPRS_RxDataReady; /* key is available to read */
    }
    val |= kPRS_TXDataEmpty;        /* we're always ready for new stuff */
    val |= kPRS_DCD;                /* connected to a carrier */
    val |= kPRS_CTS;                /* we're clear to send */

    return val;
}
