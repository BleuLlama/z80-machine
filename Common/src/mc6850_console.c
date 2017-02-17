/* MC6850 emulation
 *
 *  2016-06-08 Scott Lawrence 
 *
 *  Note: The terminology in this can get confusing, so i'm going to 
 *        define this right now:
 *              HOST                 CONSOLE --> OS specific display
 *                    ---- TO ----->
 *                    <---- FROM ----
 *
 *        The Z80 generates stuff, which goes TO the CONSOLE
 *        The user types something it goes FROM the CONSOLE
 */

#include <stdio.h>
#include <unistd.h>		/* for usleep */
#include <stdlib.h>		/* for exit */
#include <sys/time.h>		/* for timeval */
#include "mc6850_console.h"	/* port bit definitions */
#include "host.h"		/* host cnsole interface */

#ifdef FILTER_CONSOLE
void Filter_Init( z80info * z80 );

/* Handlers for content going TO the console */
void Filter_ToConsole( byte data );
int Filter_ToConsoleAvailable();
byte Filter_ToConsoleGet();

/* Add stuff into the Console send buffer (typer buffer) */
void FromConsoleBuffer_QueueChar( char ch );
void FromConsoleBuffer_QueueStr( char *str );

#endif

//// JUNK TEST

void Filter_Init( z80info * z80 )
{
    printf( "Filter init\n" );
}

static int x = -1;
char buf[32]; /* additional stuff we're sending to the console */



/* process input coming from the emulation */
void Filter_ToConsole( byte data )
{
    if( data == 'q' ) {
	sprintf( buf, "RX a q" );
	x = 0;
    } else {
    	buf[0] = data;
	buf[1] = '\0';
    }
    x = 0;
}

int Filter_ToConsoleAvailable()
{
    if( x == -1 ) return 0;
    return 1;
}

byte Filter_ToConsoleGet()
{
    byte r;

    if( x == -1 ) return 0xff;

    r = buf[x];
    x++;
    if( buf[x] == '\0' ) { x = -1; }
    
    return r;
}


//// END JUNK TEST


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
    Filter_ToConsole( data );
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

/* pseudo-circular buffer, start and end indeces */
static char intbuffer[ kRingBufSz ];
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


/* the next timestamp to read a byte */
long long nextm = 0;
int burst = 0;

/* the kbhit() that references our buffer. */
int FromConsoleBuffer_KBhit( void )
{
    if( bs == be ) return 0;

    if( Host_Millis() > nextm ) {
	return 1;
    }

    return 0;
}

/* this gets polled from the main loop to update our buffer */
void FromConsoleBuffered_PollConsole( void )
{
    /* just queue up all available characters... */
    while ( z_kbhit() ) {
	FromConsoleBuffer_QueueChar( getchar() );
    }
}


/* only get a character from our buffer when it's time.
   if it's not time, return 0xff */
byte mc6850_in_from_buffered_console_data( void )
{
    if( FromConsoleBuffer_KBhit() ) 
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

    if( FromConsoleBuffer_KBhit() ) {
            val |= kPRS_RxDataReady; /* key is available to read */
    }
    val |= kPRS_TXDataEmpty;        /* we're always ready for new stuff */
    val |= kPRS_DCD;                /* connected to a carrier */
    val |= kPRS_CTS;                /* we're clear to send */

    return val;
}
