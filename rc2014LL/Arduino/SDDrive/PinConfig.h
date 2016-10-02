

////////////////////////////////////////////
// LEDs - pwm pins

#define kPinLEDRed     (3)
#define kPinLEDYellow  (5)
#define kPinLEDGreen   (6)

////////////////////////////////////////////
// SD card

#define kPinSDSelect   (8)  /* Chip select wired to 8 */
#define kPinSDPresent  (9)  /* CD - Card detect */
#define kPinSDAux      (10) /* required */
/* Pins 11, 12, 13 are implied, and used in the SD library */

////////////////////////////////////////////
// full pin configuration

// D0  Serial RX to Serial bus
// D1  Serial TX to Serial bus
// D2  -
// D3  Red LED
// D4  -
// D5  Yellow LED
// D6  Green LED
// D7  -

// D8   (SD Card Select for Sparkfun)
// D9   SD Present switch
// D10  SPI Card Select (Adafruit Card Select)
// D11  SPI MOSI (SD Card)
// D12  SPI MISO (SD Card)
// D13  SPI Clock (SD Card)

// A0  -
// A1  -
// A2  -
// A3  -
// A4  - 
// A5  -
