/*
 * SDDrive
 * 
 * Serial based interface for an SD card
 *
 *  yorgle@gmail.com
 */


#include <SD.h>
#include "LEDs.h"
#include "BufferedSerial.h"
#include "PinConfig.h"
#include "Strings.h"

////////////////////////////////////////////

class BufSerial ser;
char echo = 1;

////////////////////////////////////////////

Sd2Card card;
SdVolume volume;

int errorSD = -1;

////////////////////////////////////////////

void initSD()
{
  pinMode( kPinSDAux, OUTPUT);      // required for SD
  digitalWrite( kPinSDAux, HIGH ); // needed too

  errorSD = 0;

  SD.begin( kPinSDSelect );
  
  if (!card.init(SPI_HALF_SPEED, kPinSDSelect)) {
    errorSD = 1;
  } 
}


void sendSDInfo()
{  
  if( errorSD == 1 ) {
    ser.print( kStr_Prot0 );
    ser.println( kStr_Error_InitFailed );
  } else {
    ser.print( kStr_Prot0 );
    ser.println( kStr_CardOk );
  }

  if (!volume.init(card)) {
    ser.print( kStr_Prot0 );
    ser.println( kStr_Error_NoFatPartition );
    return;
  }

    // print the type and size of the first FAT-type volume
  uint32_t volumesize;
  ser.print( kStr_Prot0 );
  ser.print( kStr_FAType );
  ser.println(volume.fatType(), DEC);

  volumesize = volume.blocksPerCluster();    // clusters are collections of blocks
  volumesize *= volume.clusterCount();       // we'll have a lot of clusters
  volumesize *= 512;                            // SD card blocks are always 512 bytes
  ser.print( kStr_Prot0 );
  ser.print( kStr_Size );
//  ser.println(volumesize);
//  ser.print("~NVolume size (Kbytes): ");
  volumesize /= 1024;
//  ser.println(volumesize);
  volumesize /= 1024;
  ser.print( volumesize );
  ser.println( kStr_SizeUnits );
}


////////////////////////////////////////////
// System setup

void resetFunc();
void detectCard();

void setup() {
  pinMode( kPinSDPresent, INPUT );
  serialInit();
  ser.println( );
  ser.print( kStr_Prot0 );
  ser.println( kStr_Version );

  ledSetup();
  detectCard(); // will reset the avr if failed
  
  initSD();
  sendSDInfo();
}

////////////////////////////////////////////

void serialInit()
{
  static int initialized = 0;

  if( initialized ) return;
  initialized = 1;
  
  ser.begin( 115200 );
}


#define kMaxBuf (128)
char buf[ kMaxBuf ] = { '\0' };

////////////////////////////////////////////

/* cheat sheet
    0123
    ~0:I$         get system info

    ~0:PL path$   ls path
    ~0:PM path$   mkdir path
    ~0:PR path$   rm path

    01234
    ~0:FR path$   fopen( path, "r" );
    ~0:FW path$   fopen( path, "w" );
    ~0:FA path$   fopen( path, "a" ); fseek( 0, SEEK_END );
    ~0:FS ascii$  fwrite( asciiStringToBinary( ascii ));
    ~0:FC$        fclose()

    0123
    ~0:SR D T S$    read drive D, track T, sector S to buffer
    ~0:SW D T S$    write buffer to drive D, track T, sector S
*/


////////////////////////////////////////////

void cmd_fail( void )
{
  ser.println();
  ser.print( kStr_Prot0 );
  ser.println( kStr_Error_CmdFail );
}

void cmd_pass( void )
{
  ser.println();
  ser.print( kStr_Prot0 );
  ser.println( kStr_CmdOK );
}


////////////////////////////////////////////
// F-Commands
//  File IO commands


// ~0:FR TEST.TXT
void do_FileRead( const char * path )
{
  int nper = 0;
  int ch;
  int progress = 0;
  char asciihex[4];

  ledEmoteRead();
  
  /* attempt to open or fail */  
  File myFile = SD.open( path );
  if( !myFile ) {
    cmd_fail();
    ledEmoteOk();
    return;
  }

  /* get filesize */
  unsigned long sz = myFile.size();

  /* output the header */
  ser.print( kStr_Prot0 );
  ser.println( kStr_Begin );
  
  while( myFile.available() ) 
  {

    if( nper == 0 ) {
      ser.print( kStr_Prot0 );
      ser.print( kStr_DataString );
    }

    ch = myFile.read();
    sprintf( asciihex, "%02X", ch );
    ser.print( asciihex );

    nper++;
    progress++;
    if( nper == 20 ) // number of bytes per line
    {
      ser.println();
      if( ( progress % 100 ) == 0 ) {
        ser.print( kStr_Prot0 );
        ser.print( kStr_Progress );
        ser.print( progress ); ser.print( "/" ); ser.println( sz );
      }
      
      nper = 0;
    }
  }

  /* footer */
  ser.println(); 
  ser.print( kStr_Prot0 );
  ser.print( kStr_End );
  ser.println( sz, DEC );

  cmd_pass();
  myFile.close();

  ledEmoteOk();
}

void do_FileWriteString( const char * string )
{
  ser.print( "write string " );
  ser.println( string );
}

void do_FileOpenAppend( const char * path )
{
  ser.print( "Open for append " );
  ser.println( path );
}

void do_FileOpenWrite( const char * path  )
{
  ser.print( "Open for write " );
  ser.println( path );
}


void processFCommands( const char * line )
{
//  ser.write( "F Command: " );
//  ser.writeln( line );

  // for Close, there's just "~FC"
  if( *(line) == 'C' ) {
    cmd_pass();
    return;
  }

  // for the rest, 
  // make sure there's a param
  if(    *(line+1) == '\0'
      || *(line+1) != ' ' 
      || *(line+2) == '\0') {
    // command ends with no param
    ser.print( kStr_Prot0 );
    ser.println( kStr_Error_BadLine );
    return;
  }


  switch( *line ) {
    case( 'R' ):
      do_FileRead( line+2 );
      break;
      
    case( 'W' ):
      do_FileOpenWrite( line+2 );
      ser.print( "Open for Write " );
      ser.println( line+2 );
      break;
      
    case( 'A' ):
      do_FileOpenAppend( line+2 );
      ser.print( "Open for Append " );
      ser.println( line+2 );
      break;

    case( 'S' ):
      do_FileWriteString( line+2 );
      ser.print( "Sending " );
      ser.println( line+2 );
      break;
    
    default:
      ser.print( kStr_Prot0 );
      ser.println( kStr_Error_BadLine );
      break;
  }
}

////////////////////////////////////////////
// P-Commands
//  path-based stuff

void do_ls( const char * line )
{
  File ppp;
  int nFiles = 0;
  int nSubdirs = 0;
  
  ser.print( kStr_Prot0 );
  ser.println( kStr_Begin );

  ppp = SD.open( line );
  ppp.seek( 0 );
  
  while(true) { 
    File entry =  ppp.openNextFile();
    if ( !entry ) {
      // no more files
      entry.close(); // Added
      break;
    }

    ser.print( kStr_Prot0 );
    ser.print( entry.name() );
    if (entry.isDirectory()) {
      ser.println("/");
      nSubdirs++;
    } else {
      // files have sizes, directories do not
      ser.print( "," );
      unsigned long sz = entry.size();
      ser.println( sz, DEC);
      nFiles++;
    }
    entry.close(); // Added
  }
  ser.print( kStr_Prot0 );
  ser.print( kStr_End );
  ser.print( nFiles );
  ser.print( "," );
  ser.println( nSubdirs );
  
  ppp.close();
}

void do_mkdir( const char * line )
{
  if( !SD.mkdir( line ) ) {
    cmd_fail();
  } else {
    cmd_pass();
  }
}

void do_rm( const char * line )
{
  /* we'll play dumb here, first try to remove it as a file, then as a directory */
  
  if( !SD.remove( line ) ) {
    if( !SD.rmdir( line ) ) {
      cmd_fail();
    } else {
      cmd_pass();
    }
  } else {
    cmd_pass();
  }
}


//  Path/Directory commands
void processPCommands( const char * line )
{
  // make sure there's a param
  if( *(line+1) == '\0' || *(line+1) != ' ' || *(line+2) == '\0') {
    // command ends with no param
    ser.print( kStr_Prot0 );
    ser.println( kStr_Error_BadLine );
    return;
  }
  
  switch( *line ) {
    case( 'L' ): do_ls( line+2 ); break;
    case( 'M' ): do_mkdir( line+2 ); break;
    case( 'R' ): do_rm( line+2 ); break;
    default:
      ser.print( kStr_Prot0 );
      ser.println( kStr_Error_BadLine );
      break;
  }
}


////////////////////////////////////////////
// S-Commands
//  sector IO

void processSCommands( const char * line )
{
  ser.print( kStr_Prot0 );
  ser.println( kStr_Error_NotImplemented );
}


////////////////////////////////////////////
// L-commands1211111111111111111111111111111111111111111111111111111111113rdcx
//  undocumented, set the board LEDs for debugging

void processLCommands( const char * line )
{
  if( *line == 'r' ) { ledSet( kRed, 0 ); }
  if( *line == 'y' ) { ledSet( kYellow, 0 ); }
  if( *line == 'g' ) { ledSet( kGreen, 0 ); }
  if( *line == '0' ) { ledSet( kOff, 0 ); }
  if( *line == '1' ) { ledSet( kAll, 0 ); }
}


////////////////////////////////////////////

void processLine( void )
{
  if( buf[0] == '\0' ) {
    // absorb empty lines
    buf[0] = '\0';
    return;
  }

  if( buf[0] == '-' ) {
    // It's a response from another node. Let's inc the id and send it through
    buf[1]++;
    ser.println( buf );
    buf[0] = '\0';
    return;
  }

  if(    buf[0] == '~' 
      && buf[1] != '0' ) {
    // It's a command for another node.  Let's dec the id and send it through...
    buf[1]--;
    ser.println( buf );
    buf[0] = '\0';
    return;
  }
  
  if( buf[0] != '~' ) {
    // if there's no ~, it's a failure command
    ser.print( kStr_Prot0 );
    ser.println( kStr_Error_BadLine );
    ser.print( kStr_Prot0 );
    ser.print( kStr_Error_LEcho );
    ser.println( buf );
    buf[0] = '\0';
    return;
  }

  // ok. let's hand off control to the appropriate processor
  switch( buf[3] ) {
    case( 'e' ):
      // toggle echo
      echo ^= 1;
      break;
      
    case( 'I' ): sendSDInfo(); break;
    
    case( 'F' ): processFCommands( &buf[4] ); break;
    case( 'P' ): processPCommands( &buf[4] ); break;
    case( 'S' ): processSCommands( &buf[4] ); break;
    case( 'L' ): processLCommands( &buf[4] ); break;
    default:
      break;
  }

  // and clear the line
  buf[0] = '\0';
}

void serialPoll( void )
{
  size_t l;
  
  if( ser.available() ) {
    char ch = ser.read();

    if( echo ) {
      if( ch == '\n' || ch=='\r' ) ser.println();
      else ser.write( ch );
    }

    l = strlen( buf );
    if( ch == '\n' || ch == '\r' || l >= (kMaxBuf-1) ) {
      // process the line
      processLine();
      
    } else if( l < kMaxBuf ) {
      // add the character, and null-terminate
      buf[ l ] = ch;
      buf[ l+1 ] = '\0';
    }
  }  
}


////////////////////////////////////////////
// Card detection and reset

/* call this to reset the arduino */
//void(* resetFunc) (void) = 0;

// Restarts program from beginning but does not reset the peripherals and registers
void resetFunc() 
{
  asm volatile ("jmp 0");  
} 

void detectCard()
{
  static int lastCardPresent = -1;
  
  int cardPresent = digitalRead( kPinSDPresent );
  if( cardPresent == lastCardPresent ) return;

  // NO CARD
  if( !cardPresent ) {
    ser.print( kStr_Prot0 );
    ser.println( kStr_Error_NoCard );
    ledEmoteError();
    resetFunc();
  } else {
    
    // CARD OK.
    if( lastCardPresent == -1 ) {
      ledEmoteOk();
    }
  }

  // make sure we don't do things multiple times
  lastCardPresent = cardPresent;
}


////////////////////////////////////////////
// Main program loop
void loop()
{
  detectCard(); // check to make sure we're still connected
  ledPoll();    // update LED timers
  serialPoll(); // check for input, and respond
}
