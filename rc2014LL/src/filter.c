/* Filter
 *
 *  2017-02-17 Scott Lawrence
 *
 *   Filter console input to provide a backchannel for data transfer
 */

#include <stdio.h>
#include "mc6850_console.h"


void Filter_Init( z80info * z80 )
{
    printf( "Example Filter init\n" );
}

////////////////////////////////////////////////////////////////////////////////

static int x = -1;
char ToConsoleBuffer[32]; /* additional stuff we're sending to the console */


/* filter input going TO the CONSOLE */
void Filter_ToConsole( byte data )
{
    if( data == 'q' ) {
        sprintf( ToConsoleBuffer, "RX a q" );
        x = 0;
    } else {
        ToConsoleBuffer[0] = data;
        ToConsoleBuffer[1] = '\0';
    }
    x = 0;
}

/* is stuff available in our filter queue to send TO the CONSOLE? */
int Filter_ToConsoleAvailable()
{
    if( x == -1 ) return 0;
    return 1;
}

/* get something from the filter that needs to go TO the CONSOLE */
byte Filter_ToConsoleGet()
{
    byte r;

    if( x == -1 ) return 0xff;

    r = ToConsoleBuffer[x];
    x++;
    if( ToConsoleBuffer[x] == '\0' ) { x = -1; }

    return r;
}


////////////////////////////////////////////////////////////////////////////////

static int y = -1;
char ToRemoteBuffer[32]; 

/* filter input going TO the REMOTE */
void Filter_ToRemote( byte data )
{
    ToRemoteBuffer[0] = data;
    ToRemoteBuffer[1] = '\0';
    y = 0;
}


/* is stuff available in our filter queue to send TO the REMOTE? */
int Filter_ToRemoteAvailable()
{
    if( y == -1 ) return 0;
    return 1;
}


/* get something from the filter that needs to go TO the REMOTE */
byte Filter_ToRemoteGet()
{
    byte r;

    if( y == -1 ) return 0xff;

    r = ToRemoteBuffer[y];
    y++;
    if( ToRemoteBuffer[y] == '\0' ) { y = -1; }

    return r;
}
