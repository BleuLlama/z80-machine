/* Host OS interface stuff.
 *
 *  Any os-specific stuff should be only in here.
 *
 *  2017-02-15 Scott Lawrence
 */

#include <stdio.h>
#include "mc6850_console.h"     /* port bit definitions */

/* send a byte of data to the actual console */
void Host_PutChar( byte data );

/* is a key available on the keyboard? */
int Host_KeyHit( void );

/* Get a key if it's available */
byte Host_GetChar( byte defaultVal );

/* utility function to get the number of milliseconds since we started */
long long Host_Millis( void );
