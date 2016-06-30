/* Mass Storage
 *
 *  Simulates a SD card storage device attached via MC6850 ACIA
 *
 *  2016-Jun-10  Scott Lawrence
 */

#include <stdio.h>
#include <sys/types.h>
#include <dirent.h>
#include "defs.h"
#include "storage.h"
#include "mc6850.h"


/* ********************************************************************** */

/* Serial interface to the Mass Storage 
 *
 * We'll define a simple protocol here...
 *  *$ means "ignore everything until end of line"
 *
 * ~*$      Enter command mode
 * ~L*$     Get directory listing (Catalog)
 * ~Dname$  Directory "name"
 * ~Fname$  Filename "name"
 * ~R       Open selected file for read (will be streamed in)
 * Status byte will respond if there's more data to be read in
 */


/* modes for the state machine... */
#define kMassMode_Idle		(0)

#define kMassMode_Command	(1)

#define kMassMode_DirPath	(2)
#define kMassMode_Dir		(3)
#define kMassMode_ReadDir	(4)

#define kMassMode_Filename	(5)
#define kMassMode_ReadFile	(6)

/* we'll handle file writing later */ 
static int mode_Mass = kMassMode_Idle;
static FILE * MassStorage_fp = NULL;
static char filename[ 256 ];
static int fnPos = 0;
static int moreToRead = 0;

static char dirpath[ 256 ];
static DIR * dp;
static struct dirent *ep;
static char * dn;

/* MassStorage_Init
 *   Initialize the SD simulator
 */
void MassStorage_Init( void )
{
	mode_Mass = kMassMode_Idle;
	MassStorage_fp = NULL;
	filename[0] = '\0';
	dirpath[0] = '\0';
	fnPos = 0;
	moreToRead = 0;
}

/* MassStorage_RX
 *   handle the simulation of the SD module sending stuff
 *   (RX on the simulated computer)
 */
byte MassStorage_RX( void )
{
	int ch;
	moreToRead = 0;

	switch( mode_Mass ) {
	case( kMassMode_Dir ):
		/* get next byte of directory listing */
		/* dir listings are 0 terminated strings */
		/* list itself is 0 terminated (send nulls at end) */


		moreToRead = 0;
		return( 0x00 );
		break;

	case( kMassMode_ReadFile ):
		if( MassStorage_fp ) {
			if( fread( &ch, 1, 1, MassStorage_fp ) ) {
				moreToRead = 1;
				return ch;
			} else {
				/* end of file. close it */
				fclose( MassStorage_fp );
			}
		}

		/* no file open, send nulls. */
		mode_Mass = kMassMode_Idle;
		moreToRead = 0;
		return( 0x00 );
		break;

	case( kMassMode_ReadDir ):
		/* read directory poll */
		if( dp ) {
			moreToRead = 1;
			if( *dn == '\0' ) {
				ep = readdir( dp );
				if( !ep ) {
					/* read directory done */
					dn = NULL;
					moreToRead = 0;
					mode_Mass = kMassMode_Idle;
					if( dp ) {
						(void) closedir( dp );
						dp = NULL;
					}
				} else {
					dn = ep->d_name;
					return( *dn );
				}
			} else {
				/* ch = *dp */
				dn++;
				return( *dn );
			}
		} else {
			moreToRead = 0;
			mode_Mass = kMassMode_Idle;
			return( 0x00 );
		}
		break;

	case( kMassMode_Filename ):
	case( kMassMode_Command ):
	case( kMassMode_Idle ):
	default:
		// content read requested during these is ignored
		break;
	}
	return 0xff;
}


/* MassStorage_TX
 *   handle simulation of the sd module receiving stuff
 *   (TX from the simulated computer)
 */
void MassStorage_TX( byte ch )
{
	if( mode_Mass == kMassMode_ReadFile ) {
		/* do nothing... */
	}

	if( mode_Mass == kMassMode_ReadFile ) {
		/* do nothing... */
	}

	else if( mode_Mass == kMassMode_Filename ) {
		/* store the filename until \r \n \0 or filled */
		if(    ch == 0x0a 
		    || ch == 0x0d
		    || ch == 0x00
		    || fnPos > 31 ) {
			printf( "EMU: SD: Filename (%s)\n\r", filename );
			mode_Mass = kMassMode_Idle;
		} else {
			filename[fnPos++] = ch;
		}
	}
	else if( mode_Mass == kMassMode_DirPath ) {
		/* store the filename until \r \n \0 or filled */
		if(    ch == 0x0a 
		    || ch == 0x0d
		    || ch == 0x00
		    || fnPos > 31 ) {
			printf( "EMU: SD: DirPath (%s)\n\r", dirpath );
			mode_Mass = kMassMode_Idle;
		} else {
			dirpath[fnPos++] = ch;
		}
	}

	else if( mode_Mass == kMassMode_Command ) {
		switch( ch ) {
		case( 'L' ):
			printf( "EMU: List command (%s)\n", dirpath );

			/* open directory for read... */
			moreToRead = 0;
			dn = NULL;

			dp = opendir( dirpath );
			if( dp != NULL )
			{
				ep = readdir( dp );
				dn = ep->d_name;
				mode_Mass = kMassMode_ReadDir;
				moreToRead = 1;
			} else {
				mode_Mass = kMassMode_Idle;
				moreToRead = 0;
			}
			break;

		case( 'D' ):
			printf( "EMU: Set dirpath\n" );
			/* reset the dirpath position */
			fnPos = 0;
			/* clear the string */
			do {
				int j;
				for( j=0 ; j<32 ; j++ ) {
					dirpath[j] = '\0';
				}
				fnPos = 0;
			} while ( 0 );

			mode_Mass = kMassMode_DirPath;
			break;

		case( 'F' ):
			printf( "EMU: Set Filename\n" );
			/* reset the file name position */
			fnPos = 0;
			/* clear the string */
			do {
				int j;
				for( j=0 ; j<32 ; j++ ) {
					filename[j] = '\0';
				}
				fnPos = 0;
			} while ( 0 );

			mode_Mass = kMassMode_Filename;
			break;

		case( 'R' ):
			printf( "EMU: Read file (%s)\n", filename );
			/* open file for read */
			if( MassStorage_fp ) fclose( MassStorage_fp );
			MassStorage_fp = fopen( filename, "rb" );
			if( MassStorage_fp ) {
				
				printf( "EMU: SD: Opened %s\n\r", filename );
				moreToRead = 1;
				mode_Mass = kMassMode_ReadFile;
			} else {
				printf( "EMU: SD: Failed %s\n\r", filename );
				moreToRead = 0;
				mode_Mass = kMassMode_Idle;
			}
			break;

		default:
			printf( "EMU: %c: unknown command\n", ch );
			mode_Mass = kMassMode_Idle;
		}
	}

	else if( ch == '~' ) {
		/* enter command mode */
		mode_Mass = kMassMode_Command;
	}

	else if( ch == '\n' || ch == '\r' ) {

	}
	else {
		/* unknown... just return to idle. */
		mode_Mass = kMassMode_Idle;
	}
}


/* MassStorage_Status
 *   get port status (0x01 if more data)
 */
byte MassStorage_Status( void )
{
	byte sts = 0x00;

	if( moreToRead ) {
		sts |= kPRS_RxDataReady; /* key is available to read */
	}

	sts |= kPRS_TXDataEmpty;	/* we're always ready for new stuff */
	sts |= kPRS_DCD;		/* connected to a carrier */
	sts |= kPRS_CTS;		/* we're clear to send */

	return sts;
}


/* MassStorage_Control
 *   set serial speed
 */
void MassStorage_Control( byte data )
{
	/* ignore port settings */
}
