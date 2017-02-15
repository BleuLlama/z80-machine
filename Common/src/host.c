/* Host OS interface stuff.
 *
 *  Any os-specific stuff should be only in here.
 *
 *  2017-02-15 Scott Lawrence
 */

#include <stdio.h>
#include <unistd.h>             /* for usleep */
#include <sys/time.h>           /* for timeval */
#include "mc6850_console.h"     /* port bit definitions */


/* send a byte of data to the actual console */
void Host_PutChar( byte data )
{
    putchar( (int) data );
    fflush( stdout );
}

/* is a key available on the keyboard? */
int Host_KeyHit( void )
{
    return( z_kbhit() );
}

/* Get a key if it's available */
byte Host_GetChar( byte defaultVal )
{
    /* get in a byte from the console */
    if( Host_KeyHit() ) {
	return getchar();
    }
    return defaultVal;
}

/* utility function to get the number of milliseconds since we started */
long long Host_Millis( void )
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
