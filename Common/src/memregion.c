/* memregion.c
 *
 *   An example file to show how IO and Memory can be implemented 
 *   outside of the z80 core
 */

#include <stdio.h>
#include <stdlib.h>	/* for calloc */
#include <string.h>	/* for memcpy */
#include <curses.h>
#include "defs.h"
#include "memregion.h"


/* regions_init
 *
 * 	load in ROMs, allocate memory, all that stuff
 */
void regions_init( MemRegion * m, byte * z80mem )
{
    int region = 0;
    FILE * fp;
    if( !m ) return;

    if( z80mem ) {
	memset( z80mem, 0xff, 64 * 1024 );
    }

    while( m->addressStart < REGION_MAX )
    {
	printf( "Mem region %d: 0x%04lx - 0x%04lx (%s) ",
		region,
		m->addressStart, m->addressStart + m->length - 1,
		m->writable? "ram" : "ROM" );
	m->mem = calloc( m->length, sizeof( byte ) );

	if( m->mem && (m->loadFileName != NULL) ) 
	{
	    fp = fopen( m->loadFileName, "rb" );
	    if( fp )
	    {
		size_t nbytes = fread( m->mem, 1, m->length, fp );
		printf( "%s: %ld bytes", m->loadFileName, nbytes );
		fclose( fp );
	    } else {
		printf( "%s: read failed", m->loadFileName );
	    }
	}
	printf( "\n" );

	/* and copy it to z80mem */
	if( z80mem )
	{
	    memcpy( z80mem + m->addressStart, m->mem, m->length-1 );
	}

	region++;
	m++;
    }
}


/* regions_read
 *
 *      perform a memory read on the specified address
 */
byte regions_read( MemRegion * m, word addr )
{
    if( !m ) return 0xff;

    while( m->addressStart < REGION_MAX )
    {
	if(    (addr >= m->addressStart)
	    && (addr < (m->addressStart + m->length ))
	)
	{
	    return m->mem[ addr - m->addressStart ];
	}

	m++;
    }

    return 0xff;
}


/* regions_write
 *
 *      perform a memory write on the specified address
 */
byte regions_write( MemRegion * m, word addr, byte val )
{
    if( !m ) return 0xff;

    while( m->addressStart < REGION_MAX )
    {
	if(    (addr >= m->addressStart)
	    && (addr < (m->addressStart + m->length ))
	    && (m->writable == REGION_RW) 
	)
	{
	    m->mem[ addr - m->addressStart ] = val;
	    return val;
	}

	m++;
    }
    return val;
}
