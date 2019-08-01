
/* this is a synchronous interface to the Serial or Serial1 interface
 * it will use the regular serial interface, but adds in delays.
 */

#ifndef __BUFFEREDSERIAL_H__
#define __BUFFEREDSERIAL_H__

#define USE_SERIAL1

class BufSerial {
public:
  BufSerial();
  ~BufSerial();

private:
  long msDelay;   /* value to wait per character */
  int burstCount; /* number of characters to send per burst */

private:
  int nSent;      /* number sent per this burst */
  
public:
  // accessors
  void setMsDelay( long v ) { this->msDelay = v; }
  long getMsDelay( void ) { return this->msDelay; }
  void setBurstCount( int v ) { this->burstCount = v; }
  int getBurstCount( void ) { return this->burstCount; }

public:
  // setup
  void begin( long baud=115200 );

  // writing
  void write( char ch );
  void write( const char * ch );
  void writeln( void ) { this->write( "\r\n" ); }
  void writeln( const char * ch ) { this->write( ch ), this->writeln(); }

  // printing
  void print( const char * str ) { this->write( str ); }
  void print( long val, int type=DEC );
  void println( void ) { this->print( "\r\n" ); }
  void println( const char * str ) { this->print( str ); this->println(); }
  void println( long val, int type=DEC ) { this->print( val, type ); this->println(); }

  // reading
  int available( void );
  char read( void );
    
private:
  void waitIfBurst( int count );

};

#endif
