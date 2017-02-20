/* Filter
 *
 *  2017-02-17 Scott Lawrence
 *
 *   Filter console input to provide a backchannel for data transfer
 */

#include <stdio.h>
#include "mc6850_console.h"

////////////////////////////////////////

void Filter_ProcessTC( byte * buf, size_t len )
{
    printf( "PROCESS To Console: |%s|\n", buf );
}

void Filter_ProcessTR( byte * buf, size_t len )
{
    printf( "PROCESS To Remote: |%s|\n", buf );
}
