/* memregion.h
 *
 *   An example file to show how IO and Memory can be implemented 
 *   outside of the z80 core
 */

#include "defs.h"

#ifndef __MEMREGION_H__
#define __MEMREGION_H__

typedef struct memRegion
{
    long   addressStart;
    long   length;
    byte   writable;
    byte   active;
    byte * mem;
    char * loadFileName;
} MemRegion;

#define REGION_RO	(0)
#define REGION_RW	(1)

#define REGION_MAX	(64*1024)
#define REGION_END	{ REGION_MAX+100, 0, 0, 0, NULL, NULL }

#define REGION_ACTIVE	(1) /* region is usable */
#define REGION_INACTIVE (0) /* region should be ignored */

/* example:

MemRegion mems[] = 
{
    { 0x0000, (2 * 1024), REGION_RO, REGION_ACTIVE, NULL, "ROMs/basic.32.rom" },
    { 0x2000, (32 * 1024), REGION_RW, REGION_ACTIVE, NULL, NULL },
    REGION_END
};
*/

/* regions_init
 *
 *      load in ROMs, allocate memory, all that stuff
 */
void regions_init( MemRegion * m, byte * z80mem );

/* regions_read
 *
 *	perform a memory read on the specified address
 */
byte regions_read( MemRegion * m, word addr );

/* regions_write
 *
 *	perform a memory write on the specified address
 */
byte regions_write( MemRegion * m, word addr, byte val );


/* regions_display
 *
 * 	display the rom regions 
 */
void regions_display( MemRegion * m );

#endif
