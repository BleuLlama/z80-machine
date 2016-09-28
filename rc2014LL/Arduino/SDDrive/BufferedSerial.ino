
/* this is a synchronous interface to the Serial or Serial1 interface
 * it will use the regular serial interface, but adds in delays.
 */

#include "BufferedSerial.h"
#include "LEDs.h"

///////////////////////////////////////////////////////
// Constructor, destructor

BufSerial::BufSerial( void )
  : msDelay( 10 )
  , burstCount( 10 )
  , nSent( 0 )
{
}

BufSerial::~BufSerial( void )
{
}

///////////////////////////////////////////////////////

void BufSerial::begin( long baud )
{
#ifdef USE_SERIAL1
  Serial1.begin( baud );
  while( !Serial1 );
#else
  Serial.begin( baud );
  while( !Serial );
#endif  
}

///////////////////////////////////////////////////////

void BufSerial::waitIfBurst( int count )
{
  this->nSent += count;
  
  if( this->nSent > this->burstCount ) {
    ledDelay( this->msDelay );
    this->nSent = 0;
  }
}


void BufSerial::write( char ch )
{
#ifdef USE_SERIAL1
  Serial1.write( ch );
#else
  Serial.write( ch );
#endif

  // wait if our burst limit was reached
  this->waitIfBurst( 1 );
}

void BufSerial::write( const char * ch )
{
  while( ch && (*ch!= '\0' )) {
    this->write( *ch );
    ch++;
  }
}

void BufSerial::print( long val, int type )
{
#ifdef USE_SERIAL1
  Serial1.print( val, type );
#else
  Serial.print( val, type );
#endif

  // wait if our burst limit was reached (assume 3 bytes)
  this->waitIfBurst( 3 );
}

///////////////////////////////////////////////////////

int BufSerial::available( void )
{
#ifdef USE_SERIAL1
  return Serial1.available();
#else
  return Serial.available();
#endif
}

///////////////////////////////////////////////////////

char BufSerial::read( void )
{
#ifdef USE_SERIAL1
  return Serial1.read();
#else
  return Serial.read();
#endif
}

