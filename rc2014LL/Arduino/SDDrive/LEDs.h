/*
 * SDDrive - LEDs
 * 
 * LED handler...
 *
 */
 
#ifndef __LEDS_H__
#define __LEDS_H__

#define kRed    (0x04)
#define kYellow (0x02)
#define kGreen  (0x01)
#define kAll    (kRed | kYellow | kGreen)

/* poll the LED updater */
void ledPoll( void );

/* delay for milliseconds, while polling the LEDs */
void ledDelay( long ms );

/* set the mask for the LED indicators */
void ledSet( int mask, int spd );

void ledEmoteOk();
void ledEmoteError();

void ledSetup( void );

#endif
