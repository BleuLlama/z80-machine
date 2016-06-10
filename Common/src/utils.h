/* Utils.h
 *
 * Various utility thingies
 */

#ifndef __UTILS_H__
#define __UTILS_H__


/* ********************************************************************** */
/* snagged this from stackoverflow.com */
#define BYTE_TO_BINARY_PATTERN "%c%c%c%c%c%c%c%c"

#define BYTE_TO_BINARY(byte)  \
  (byte & 0x80 ? '1' : '0'), \
  (byte & 0x40 ? '1' : '0'), \
  (byte & 0x20 ? '1' : '0'), \
  (byte & 0x10 ? '1' : '0'), \
  (byte & 0x08 ? '1' : '0'), \
  (byte & 0x04 ? '1' : '0'), \
  (byte & 0x02 ? '1' : '0'), \
  (byte & 0x01 ? '1' : '0') 

/* use it like this:
	printf( "Test: " BYTE_TO_BINARY_PATTERN " foo!\n",
		BYTE_TO_BINARY_PATTERN( 37 )
		);
*/


/* ********************************************************************** */

#endif
