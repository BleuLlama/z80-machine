/* ioports.h
 *
 *   An example file to show how IO and Memory can be implemented 
 *   outside of the z80 core
 */

#include "defs.h"

#ifndef __IOPORTS_H__
#define __IOPORTS_H__

/* ********************************************************************** */

/* function pointer for writes. 
 * of the form:
 *	wrt( const byte portNo, const byte data );
 */
typedef void (*writePortFcn)( const byte );

/* function pointer for reads.
 * of the form:
 *	byte data = read( const byte portNo );
 */
typedef byte (*readPortFcn)( void );


/* we use these arrays once _init is called */
extern writePortFcn * writePorts;
extern readPortFcn * readPorts;

/* ********************************************************************** */
/* stubs, do nothing */

void writeStub( const byte data );
byte readStub( void );

/* ********************************************************************** */
/* intenral handlers */

void HandlePortWrite00( const byte data );
void HandlePortWrite01( const byte data );
void HandlePortWrite02( const byte data );
void HandlePortWrite03( const byte data );

byte HandlePortRead00( void );
byte HandlePortRead01( void );
byte HandlePortRead02( void );
byte HandlePortRead03( void );

/* internal emulation control */
void HandleEmulationControl( const byte data );


/* ********************************************************************** */

/* ports_init
 *
 *	setup the default stubs etc
 */
void ports_init( void );

/* ports_read
 *
 *	perform a port io read on the specified port
 */
byte ports_read( const byte portno );

/* ports_write
 *
 *	perform a port io write on the specified port
 */
void ports_write( const byte portno, const byte data );


/* ********************************************************************** */

/* ports_display
 *
 *	display the registered ports
 */
void ports_display( writePortFcn *wfcns, readPortFcn *rfcns );

#endif
