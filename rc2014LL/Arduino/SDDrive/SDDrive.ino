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

#define INCLUDE_DEBUG_COMMANDS

////////////////////////////////////////////

class BufSerial ser;
#ifdef INCLUDE_DEBUG_COMMANDS
char echo = 1;
#endif

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

#define CLEAR_BUFFER() \
  memset( buf, '\0', kMaxBuf );

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

  if( myFile.isDirectory() )
  {
    cmd_fail();
    ledEmoteOk();
    myFile.close();
    return;
  }

  /* get filesize */
  unsigned long sz = myFile.size();

  /* output the header */
  ser.print( kStr_Prot0 );
  ser.print( kStr_Begin );
  ser.println( path );
  
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

#ifdef INCLUDE_DEBUG_COMMANDS
void do_cat( const char * fname )
{
  /* attempt to open or fail */  
  File myFile = SD.open( fname );
  if( !myFile ) {
    cmd_fail();
    return;
  }

  if( myFile.isDirectory() )
  {
    cmd_fail();
    ledEmoteOk();
    myFile.close();
    return;
  }

  while( myFile.available() ) 
  {
    int ch = myFile.read();
    if( ch == '\n' ) {
      Serial1.println();
    } else {
      Serial1.write( ch );
    }
  }
  
  myFile.close();
}
#endif

////////////////////////////////
// file write

File writeFile;
bool writing = false;


void do_FileClose( void )
{
  if( !writing ) return;
  
  writeFile.close();
  writing = false;
  ledEmoteOk();
}


void do_FileWriteString( const char * string )
{
  ser.print( "write string " );
  ser.println( string );

  if( !writing ) {
    ser.print( kStr_Prot0 );
    ser.println( kStr_Error_NoFileWrite );
    return;
  }

}

void do_FileOpenWrite( const char * path  )
{
  ser.print( "Open for write " );
  ser.println( path );
  
  if( writing ) do_FileClose();   // close any open file

  // SD.remove( string ); // to clear it out first (write vs append)
  
  writeFile = SD.open( path, FILE_WRITE );
  if( !writeFile ) {
    ser.print( kStr_Prot0 );
    ser.println( kStr_Error_FileNotWR );
    ledEmoteOk();
    return;
  }

  ledEmoteWrite();
  writing = true;  
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

void do_ls( const char * path )
{
  File ppp;
  int nFiles = 0;
  int nSubdirs = 0;

  // clean it up, if we got no parameter, set it to "/"
  if( *path == '\0' ) {
    char * x = (char *) path; // HACK!
    x[0] = '/';
    x[1] = '\0';
  }
  
  ser.print( kStr_Prot0 );
  ser.print( kStr_Begin );
  ser.println( path );

  ppp = SD.open( path );
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

void processLine( void )
{
#ifdef INCLUDE_DEBUG_COMMANDS
  /* some shortcuts for testing */
  if( buf[0] == 'c' ) {
    /* cat a file */
    do_cat( buf+2 );
    CLEAR_BUFFER();
    return;
  }

  if( buf[0] == 'l' ) {
    /* list a directory */
    do_ls( buf+2 );
    CLEAR_BUFFER();
    return;
  }
#endif

  if( buf[0] == '\0' ) {
    // absorb empty lines
    CLEAR_BUFFER();
    return;
  }

  if( buf[0] == '-' ) {
    // It's a response from another node. Let's inc the id and send it through
    buf[1]++;
    ser.println( buf );
    CLEAR_BUFFER();
    return;
  }

  if(    buf[0] == '~' 
      && buf[1] != '0' ) {
    // It's a command for another node.  Let's dec the id and send it through...
    buf[1]--;
    ser.println( buf );
    CLEAR_BUFFER();
    return;
  }
  
  if( buf[0] != '~' ) {
    // if there's no ~, it's a failure command
    ser.print( kStr_Prot0 );
    ser.println( kStr_Error_BadLine );
    ser.print( kStr_Prot0 );
    ser.print( kStr_Error_LEcho );
    ser.println( buf );
    CLEAR_BUFFER();
    return;
  }

  // ok. let's hand off control to the appropriate processor
  switch( buf[3] ) {
#ifdef INCLUDE_DEBUG_COMMANDS
    case( 'e' ):
      // toggle echo
      echo ^= 1;
      break;
#endif
      
    case( 'I' ): sendSDInfo(); break;
    
    case( 'F' ): processFCommands( &buf[4] ); break;
    case( 'P' ): processPCommands( &buf[4] ); break;
    case( 'S' ): processSCommands( &buf[4] ); break;\
    default:
      break;
  }

  // and clear the line
  CLEAR_BUFFER();
}

void serialPoll( void )
{
  size_t l;
  
  if( ser.available() ) {
    char ch = ser.read();
#ifdef INCLUDE_DEBUG_COMMANDS
    if( echo ) {
      if( ch == '\n' || ch=='\r' ) ser.println();
      else ser.write( ch );
    }
#endif

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
