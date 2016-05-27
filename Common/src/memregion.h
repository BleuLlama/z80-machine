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
    byte * mem;
    char * loadFileName;
} MemRegion;

#define REGION_RO	(0)
#define REGION_RW	(1)

#define REGION_MAX	(64*1024)
#define REGION_END	{ REGION_MAX+100, 0, 0, NULL, NULL }

/* example:

MemRegion mems[] = 
{
    { 0x0000, (2 * 1024), REGION_RO, NULL, "ROMs/basic.32.rom" },
    { 0x2000, (32 * 1024), REGION_RW, NULL, NULL },
    REGION_END
};
*/

void regions_init( MemRegion * m, byte * z80mem );
byte regions_read( MemRegion * m, word addr );
byte regions_write( MemRegion * m, word addr, byte val );

#endif
