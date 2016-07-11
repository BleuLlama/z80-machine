/* MC6850 emulation
 *
 *  2016-06-08 Scott Lawrence 
 */

#include <stdio.h>
#include "mc6850_console.h"	/* port bit definitions */


/* we have a throttled kbhit which reduces the number of MS between keypresses */
#undef EXPERIMENTAL_THROTTLED_KBHIT

/* time in milliseconds between keypresses */
#define kThrottleMS	(1000)

#ifdef EXPERIMENTAL_THROTTLED_KBHIT
#include <unistd.h>     // for usleep
#include <sys/time.h>   // for timeval
#endif

/* ********************************************************************** */

/* initialize the ACIA */
void mc6850_console_init( z80info * z80 )
{
    /* do nothing */
}

/* send out a byte of data */
void mc6850_out_console_data( byte data )
{
    /* send out a byte to the console */
    putchar( (int) data);
    fflush( stdout );
}

/* set control in the 6850 (baud, etc */
void mc6850_out_console_control( byte data )
{
    /* do nothing -- ignored */
}




#ifdef EXPERIMENTAL_THROTTLED_KBHIT

static long long millis( void )
{
    	struct timeval te; 
	long long milliseconds;

	static long long startTime = 0;

    	gettimeofday(&te, NULL); // get current time
	if( startTime == 0 ) {
		startTime = te.tv_sec*1000LL + te.tv_usec/1000; // caculate milliseconds
	}

	milliseconds = te.tv_sec*1000LL + te.tv_usec/1000; // caculate milliseconds
	//printf("milliseconds: %lld\n", milliseconds);
	return milliseconds;
}

int throttled_kbhit( void ) 
{
	static long long nextm = 0;

	if( !z_kbhit() ) return 0;

	if( millis() > nextm ) {
		nextm = millis() + kThrottleMS;
		return z_kbhit();
	}

	return 0;
}

#define KBHIT	throttled_kbhit

#else 

#define KBHIT	z_kbhit

#endif /* EXPERIMENTAL_THROTTLED_KBHIT */

/* read in data from the ACIA
 	if nothing available, returns 0xff (not sure if this is accurate)
*/
byte mc6850_in_console_data( void )
{
    byte val = 0xff;

    /* get in a byte from the console */
    if( z_kbhit() ) {
	    val = getchar();
    }

    return val;
}

/* read in the status byte from the ACIA */
byte mc6850_in_console_status( void )
{
    byte val = 0;

    if( KBHIT() ) {
	    val |= kPRS_RxDataReady; /* key is available to read */
    }
    val |= kPRS_TXDataEmpty;        /* we're always ready for new stuff */
    val |= kPRS_DCD;                /* connected to a carrier */
    val |= kPRS_CTS;                /* we're clear to send */

    return val;
}
