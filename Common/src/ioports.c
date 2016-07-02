/* ioports
 *
 *   An example file to show how IO and Memory can be implemented 
 *   outside of the z80 core
 */

#include <stdlib.h> 	/* for exit() */
#include "defs.h"
#include "ioports.h"


/* ********************************************************************** */

/* stubs, do nothing */

void writeStub( const byte data )
{
/*
    printf( "Port Write, port 0x%02x, data 0x%02x\n", portno, data );
*/
}

byte readStub( void )
{
/*
    printf( "Port Read, port 0x%02x\n", portno );
*/
    return 0xff;
}

/* ********************************************************************** */

/* internal port io handlers... */
static byte digital_io0 = 0x00;
static byte digital_io1 = 0x11;
static byte digital_io2 = 0x22;
static byte digital_io3 = 0x33;

void HandlePortWrite00( const byte data ) { digital_io0 = data; }
void HandlePortWrite01( const byte data ) { digital_io1 = data; }
void HandlePortWrite02( const byte data ) { digital_io2 = data; }
void HandlePortWrite03( const byte data ) { digital_io3 = data; }

byte HandlePortRead00( void ) { return digital_io0; }
byte HandlePortRead01( void ) { return digital_io1; }
byte HandlePortRead02( void ) { return digital_io2; }
byte HandlePortRead03( void ) { return digital_io3; }


/* internal emulation control */
void HandleEmulationControl( const byte data )
{
    if( data == 0xF0 )
    {
            z_resetterm();
            exit( 0 );
    }
}



/* ********************************************************************** */

/* our intenral lists. we'll use these everywhere */
writePortFcn _writePorts[ 0xff ];
readPortFcn _readPorts[ 0xff ];

writePortFcn * writePorts = _writePorts;
readPortFcn * readPorts = _readPorts;

/* ports_init
 *
 *	setup the default stubs etc
 */
void ports_init( void )
{
    int i;

    for( i=0 ; i<256 ; i++ )
    {
	writePorts[i] = writeStub;
	readPorts[i] = readStub;
    }
}


/* ports_read
 *
 *	perform a port io read on the specified port
 */
byte ports_read( const byte portno )
{
    byte retval = 0xff;

    if( readPorts[ portno ] != NULL )
    {
	return( readPorts[portno]() );
    }

    return retval;
}

/* ports_write
 *
 *	perform a port io write on the specified port
 */
void ports_write( const byte portno, const byte data )
{
    if( writePorts[ portno ] != NULL )
    {
	writePorts[ portno ]( data );
    }
}


/* ********************************************************************** */

/* ports_display
 *
 *	display the registered ports
 */
void ports_display( writePortFcn *wfcns, readPortFcn *rfcns )
{
}
