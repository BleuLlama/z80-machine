/*
 * SDDrive - LEDs
 * 
 * LED handler...
 *
 */

#include "LEDs.h"

 
#define kPinLEDRed    (3)
#define kPinLEDYellow (5)
#define kPinLEDGreen  (6)

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

void ledEmoteOk()
{
  ledSet( kGreen, 4 ); /* green, slow */
}

void ledEmoteError()
{
  ledSet( kRed, 0 ); /* red, fast */
  ledDelay( 1000 );
}
void ledSetup( void )
{
  pinMode( kPinLEDRed, OUTPUT );
  pinMode( kPinLEDYellow, OUTPUT );
  pinMode( kPinLEDGreen, OUTPUT );

  ledSet( kAll, 0 );
  
  // initialize serial communications at 9600 bps:    
  ledDelay( 100 );
  ledEmoteOk();

}

