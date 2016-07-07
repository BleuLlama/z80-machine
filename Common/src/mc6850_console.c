/* MC6850 emulation
 *
 *  2016-06-08 Scott Lawrence 
 */

#include <stdio.h>
#include "mc6850_console.h"	/* port bit definitions */

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


#ifdef THROTTLE_KBHIT

#include <unistd.h>     // for usleep
#include <sys/time.h>   // for timeval

static long millis( void )
{
        static struct timeval startTime;

        struct timeval endTime;
        long seconds, useconds;
        double duration;

        if( startTime.tv_sec == 0 && startTime.tv_usec == 0 ) {
                gettimeofday( &startTime, NULL );
        }

        gettimeofday( &endTime, NULL );
        seconds = endTime.tv_sec - startTime.tv_sec;
        useconds = endTime.tv_usec - startTime.tv_usec;

        duration = seconds + useconds/1000000.0;

        return( (long) (duration * 1000) );
}

int throttled_kbhit( void ) 
{
	static long nextm = 0;

	if( z_kbhit() == 0 ) return 0;

	if( millis() > nextm ) {
		printf( "." );
		nextm = millis() + 10;
		return z_kbhit();
	}

	return 0;
}
#else /* THROTTLED KBHIT */
#define throttled_kbhit		z_kbhit
#endif /* THROTTLED KBHIT */

/* read in data from the ACIA
 	if nothing available, returns 0xff (not sure if this is accurate)
*/
byte mc6850_in_console_data( void )
{
    byte val = 0xff;

    /* get in a byte from the console */
    if( throttled_kbhit() ) {
	val = getchar();
    }

    return val;
}

/* read in the status byte from the ACIA */
byte mc6850_in_console_status( void )
{
    byte val = 0;

    if( throttled_kbhit() ) {
	    val |= kPRS_RxDataReady; /* key is available to read */
    }
    val |= kPRS_TXDataEmpty;        /* we're always ready for new stuff */
    val |= kPRS_DCD;                /* connected to a carrier */
    val |= kPRS_CTS;                /* we're clear to send */

    return val;
}
