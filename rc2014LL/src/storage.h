/* Mass Storage
 *
 *  Simulates a SD card storage device attached via MC6850 ACIA
 *
 *  2016-Jun-10  Scott Lawrence
 */

#ifndef __MASS_STORAGE_H__
#define __MASS_STORAGE_H__


/* 0xDx = serial based Mass Storage */
#define kMassPortControl	(0xD0)
#define kMassPortStatus		(0xD0)

#define kMassPortRxData		(0xD1)
#define kMassPortTxData		(0xD1)


/* ********************************************************************** */

/* Serial interface to the Mass Storage 
 *
 * We'll define a simple protocol here...
 *  *$ means "ignore everything until end of line"
 *
 * ~*$      Enter command mode
 * ~L*$     Get directory listing (Catalog)
 * ~Fname$  Filename "name"
 * ~R       Open selected file for read (will be streamed in)
 * Status byte will respond if there's more data to be read in
 */



/* MassStorage_Init
 *   Initialize the SD simulator
 */
void MassStorage_Init( void );

/* MassStorage_RX
 *   handle the simulation of the SD module sending stuff
 *   (RX on the simulated computer)
 */
byte MassStorage_RX( void );


/* MassStorage_TX
 *   handle simulation of the sd module receiving stuff
 *   (TX from the simulated computer)
 */
void MassStorage_TX( byte ch );


/* MassStorage_Status
 *   get port status (0x01 if more data)
 */
byte MassStorage_Status( void );


/* MassStorage_Control
 *   set serial speed
 */
void MassStorage_Control( byte data );

#endif
