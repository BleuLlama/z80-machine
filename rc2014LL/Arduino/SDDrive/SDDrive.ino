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

 ~Ffilename	- set the "filename"
 ~R		- read the file
 ~Ddirpath	- set the "dirpath"
 ~L		- directory listing as file

 ~Eerror text
 ~Nnotice text
*/


#include <SD.h>


#define kPinLEDRed    (3)
#define kPinLEDYellow (5)
#define kPinLEDGreen  (6)

#define kRed    (0x04)
#define kYellow (0x02)
#define kGreen  (0x01)
#define kAll    (kRed | kYellow | kGreen)

#define kPinSDPresent (9) /* CD - Card detect */

////////////////////////////////////////////
// Utility...

/* call this to reset the arduino */
void(* resetFunc) (void) = 0;

////////////////////////////////////////////
// Fancy LED control...

int ledMask = 0;
unsigned long ledTick = 0;
int ledCount = 0;
int ledSpeed = 0;

/* poll the LED updater */
void ledPoll( void )
{
  unsigned char aValue;  
  if( millis() > ledTick ) {
    ledCount++;
    if( ledCount > 511 ) ledCount = 0;
    ledTick = millis() + ledSpeed;

    if( ledCount <= 256 ) aValue = ledCount;
    else  aValue = 512 - ledCount;

    aValue = 256 - aValue; /* reverse since they're sunk not sourced */

    if( ledMask & kRed ) analogWrite( kPinLEDRed, aValue );
    if( ledMask & kYellow ) analogWrite( kPinLEDYellow, aValue );
    if( ledMask & kGreen ) analogWrite( kPinLEDGreen, aValue );
    
  }
}

/* delay for milliseconds, while polling the LEDs */
void ledDelay( long ms )
{
  unsigned long endTime = millis() + ms;

  while( millis() < endTime ) {
    ledPoll();
    serialPoll();
  }
}

/* set the mask for the LED indicators */
void ledSet( int mask, int spd )
{
  ledSpeed = spd;
  
  if( mask == ledMask ) return;
  ledMask = mask;

  /* turn them all off */
  digitalWrite( kPinLEDGreen, HIGH );
  digitalWrite( kPinLEDYellow, HIGH );
  digitalWrite( kPinLEDRed, HIGH );

  ledPoll();
}

////////////////////////////////////////////


#define kSDSelectPin  (8)
Sd2Card card;
SdVolume volume;
SdFile root;

void initSD()
{
  pinMode(10, OUTPUT);      // required for SD
  digitalWrite( 10, HIGH ); // needed too

  if (!card.init(SPI_HALF_SPEED, kSDSelectPin)) {
    Serial.write( "~ESD Init failed.\n" );
  } else {
    Serial.write( "~NInitialization Complete.\n" );
  }

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

  if (!volume.init(card)) {
    Serial.println("~NCould not find FAT16/FAT32 partition.");
    return;
  }

    // print the type and size of the first FAT-type volume
  uint32_t volumesize;
  Serial.print("~NVolume type is FAT");
  Serial.println(volume.fatType(), DEC);
  Serial.println();

    volumesize = volume.blocksPerCluster();    // clusters are collections of blocks
  volumesize *= volume.clusterCount();       // we'll have a lot of clusters
  volumesize *= 512;                            // SD card blocks are always 512 bytes
  Serial.print("~NVolume size (bytes): ");
  Serial.println(volumesize);
  Serial.print("~NVolume size (Kbytes): ");
  volumesize /= 1024;
  Serial.println(volumesize);
  Serial.print("~NVolume size (Mbytes): ");
  volumesize /= 1024;
  Serial.println(volumesize);

  Serial.println("\nFiles found on the card (name, date and size in bytes): ");
  root.openRoot(volume);
  
  // list all files in the card with date and size
  //root.ls(LS_R | LS_DATE | LS_SIZE);
}


////////////////////////////////////////////
// System setup

void setup() {
  pinMode( kPinSDPresent, INPUT );

  pinMode( kPinLEDRed, OUTPUT );
  pinMode( kPinLEDYellow, OUTPUT );
  pinMode( kPinLEDGreen, OUTPUT );

  ledSet( kAll, 0 );
  
  // initialize serial communications at 9600 bps:    
  ledDelay( 100 );
  ledSet( kGreen, 4 ); /* green, slow */
  detectCard();

  initSD();
}

////////////////////////////////////////////

void serialInit()
{
  static int initialized = 0;

  if( initialized ) return;
  initialized = 1;
  
  Serial.begin( 115200 );
  while( !Serial );
}


void serialPoll()
{
  if( !Serial ) return;
  
  if( Serial.available() ) {
    char ch = Serial.read();

    if( ch == 'r' ) { ledSet( kRed, 0 ); }
    if( ch == 'y' ) { ledSet( kYellow, 0 ); }
    if( ch == 'g' ) { ledSet( kGreen, 0 ); }

    Serial.write( ch );
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
    ledSet( kRed, 0 ); /* red, fast */
    ledDelay( 1000 );
    resetFunc();
  }

  serialInit();
}

void loop()
{
  detectCard();
  ledPoll();
  serialPoll();
}
