/*
 * SDDrive
 * 
 * Serial based interface for an SD card
 *
 *  v001  2016-06-27  yorgle@gmail.com
 */


/* Commands:

 All commands are newline terminated, and are in the form:

	"~X\n"  or  "~XOpt\n"  or  "~XOpt,Opt,Opt\n"

 "Opt" are optional comma separated options.

 Supprted commands:

 ~Sx,v  - set value for X to V
     x = 'w' => V = wait ms between characters
     x = 'b' => V = number of characters to burstv (up to 16)
 ~Ffilename	- set the "filename"
 ~R		- read the file
 ~Ddirpath	- set the "dirpath"
 ~L		- directory listing as file

 ~Eerror text
 ~Nnotice text
*/


#include <SD.h>
#include "LEDs.h"
#include "BufferedSerial.h"

#define kPinSDPresent (9) /* CD - Card detect */

////////////////////////////////////////////
// Utility...

/* call this to reset the arduino */
void(* resetFunc) (void) = 0;

////////////////////////////////////////////


#define kSDSelectPin  (8)
#define kSDAuxPin     (10) /* required */
Sd2Card card;
SdVolume volume;
//SdFile root;

class BufSerial ser;

void initSD()
{
  pinMode( kSDAuxPin, OUTPUT);      // required for SD
  digitalWrite( kSDAuxPin, HIGH ); // needed too

  if (!card.init(SPI_HALF_SPEED, kSDSelectPin)) {
    ser.write( "~E0=SD Init failed.\n" );
  } else {
    ser.write( "~N0=Ready.\n" );
  }

/*
  switch(card.type()) {
    case SD_CARD_TYPE_SD1:
      Serial.println("~NSD1");
      break;
    case SD_CARD_TYPE_SD2:
      Serial.println("~NSD2");
      break;
    case SD_CARD_TYPE_SDHC:
      Serial.println("~NSDHC");
      break;
    default:
      Serial.println("~NUnknown");
  }
*/
  if (!volume.init(card)) {
    ser.println("~E0=No FAT partition");
    return;
  }

    // print the type and size of the first FAT-type volume
  uint32_t volumesize;
  ser.print("~Nt=FAT");
  ser.println(volume.fatType(), DEC);
  ser.println();

  volumesize = volume.blocksPerCluster();    // clusters are collections of blocks
  volumesize *= volume.clusterCount();       // we'll have a lot of clusters
  volumesize *= 512;                            // SD card blocks are always 512 bytes
  ser.print("~Nsz=");
//  ser.println(volumesize);
//  ser.print("~NVolume size (Kbytes): ");
  volumesize /= 1024;
//  ser.println(volumesize);
  volumesize /= 1024;
  ser.print(volumesize);
  ser.println(",meg");

//  Serial.println("\nFiles found on the card (name, date and size in bytes): ");
  //root.openRoot(volume);
  
  // list all files in the card with date and size
  //root.ls( LS_DATE | LS_SIZE);
  //root.close();
}


////////////////////////////////////////////
// System setup

void setup() {
  pinMode( kPinSDPresent, INPUT );

  ledSetup();
  detectCard(); // will reset the avr if failed
  
  // it worked out.  start up serial...
  serialInit();

  initSD();
}

////////////////////////////////////////////

void serialInit()
{
  static int initialized = 0;

  if( initialized ) return;
  initialized = 1;
  
  ser.begin( 115200 );
}


void serialPoll()
{
  if( ser.available() ) {
    char ch = ser.read();

    if( ch == 'r' ) { ledSet( kRed, 0 ); }
    if( ch == 'y' ) { ledSet( kYellow, 0 ); }
    if( ch == 'g' ) { ledSet( kGreen, 0 ); }

    ser.write( ch );
  }
}


////////////////////////////////////////////
// Main program loop


void detectCard()
{
  static int lastCardPresent = -1;
  int cardPresent = digitalRead( kPinSDPresent );
  if( cardPresent == lastCardPresent ) return;

  lastCardPresent = cardPresent;

  // NO CARD
  if( !cardPresent ) {
    ledEmoteError();
    resetFunc();
  }
}


void loop()
{
  detectCard(); // check to make sure we're still connected
  ledPoll();    // update LED timers
  serialPoll(); // check for input, and respond
}
