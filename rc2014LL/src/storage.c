/* Mass Storage
 *
 *  Simulates a SD card storage device attached via MC6850 ACIA
 *
 *  2016-Jun-10  Scott Lawrence
 */

#include <stdio.h>
#include <sys/types.h>
#include <sys/stat.h>	/* for mkdir */
#include <unistd.h>	/* for rmdir, unlink */
#include <dirent.h>
#include <string.h>
#include "defs.h"
#include "storage.h"
#include "rc2014.h"	/* common rc2014 emulator headers */


/* ********************************************************************** */

/* See the Arduino implementation and document for the full design
 */

/* Meta State */
#define kMS_ReadLine		(0) /* reading, idle */
#define kMS_Writing		(1)

static int metaState	= kMS_ReadLine;
static int moreToRead	= 0;


#define kMaxLine (255)
static char lineBuf[kMaxLine];

/* MassStorage_Init
 *   Initialize the SD simulator
 */
void MassStorage_Init( void )
{
	/* start out reading an input line... */
	metaState = kMS_ReadLine;
	lineBuf[0] = '\0';
	moreToRead = 0;
}


static char val2ascii( int val )
{
	const char *hexit = "0123456789ABCDEF";
	val = val & 0x0F;
	return hexit[val];
}

FILE * fp = NULL;


/* MassStorage_RX
 *   handle the simulation of the SD module sending stuff
 *   (RX on the simulated computer)
 */
byte MassStorage_RX( void )
{
	return 0xff;
}

/* ********************************************************************** */

#define kSD_Path 	"SD_DISK/"

static void MassStorage_Start_Listing( char * path )
{
	printf( "EMU: SD: ls [%s]\n", path );
}

static void MassStorage_Do_MakeDir( char * path )
{
	char pathbuf[255];
	sprintf( pathbuf, "%s%s", kSD_Path, path );

	printf( "EMU: SD: mkdir [%s]\n", path ); 
	printf( "         %s\n", pathbuf );
	mkdir( pathbuf, 0755 );
}

static void MassStorage_Do_Remove( char * path )
{
	char pathbuf[255];
	sprintf( pathbuf, "%s%s", kSD_Path, path );

	printf( "EMU: SD: rm [%s]\n", path ); 

	/* let's be stupid and just try to remove the file AND dir */
	rmdir( pathbuf );
	unlink( pathbuf );
}


static void MassStorage_Start_Read( char * path )
{
	char pathbuf[255];
	sprintf( pathbuf, "%s%s", kSD_Path, path );

	printf( "EMU: SD: Read from [%s]\n", path ); 

	if( fp ) fclose( fp );

	fp = fopen( pathbuf, "r" );
	if( fp == NULL ) {
		/* couldn't open file. */
		printf( "EMU: SD: Can't open %s\n", pathbuf );
		return;
	}
}


static void MassStorage_Start_Write( char * path )
{
	printf( "EMU: SD: Write to [%s]\n", path ); 
	printf( "EMU: SD: unavailable\n" );
}

static void MassStorage_Start_Append( char * path )
{
	printf( "EMU: SD: Append to [%s]\n", path ); 
	printf( "EMU: SD: unavailable\n" );
}


static void MassStorage_Start_Sector_Read( char * args )
{
	printf( "EMU: SD: Read Sector [%s]\n", args ); 
	printf( "EMU: SD: unavailable\n" );
}

static void MassStorage_Start_Sector_Write( char * args )
{
	printf( "EMU: SD: Write Sector [%s]\n", args ); 
	printf( "EMU: SD: unavailable\n" );
}

static void MassStorage_End_File( void )
{
	printf( "EMU: SD: end file.\n" );
	if( fp != NULL ) {
		fclose( fp );
		fp = NULL;
	}
}


/* ********************************************************************** */

/* cheat sheet
    0123
    ~0:I	get system info

    ~0:PL path	ls path
    ~0:PM path	mkdir path
    ~0:PR path	rm path

    01234
    ~0:FR path	fopen( path, "r" );
		-0:Nbf=path
		-0:NS=292929292929292
		-0:Nef=22
		-0:N2=OK
	Nbf begin file
	Nef end file
    ~0:FW path	fopen( path, "w" );
		~0:FW newfile.txt
		-0:N2=OK
		~0:FS 292929292929299A23993
		-0:Nc=03,99
		~0:FC
		-0:N2=OK
    ~0:FC	close
    ~0:FS	Send string

    0123
    ~0:SR D T S	read drive D, Track T, Sector S to buffer
    ~0:SW D T S	write buffer to drive D, Track T, sector S
    ~0:SS data	Data from sector read
    ~0:SC	close sector file
 */

static void MassStorage_ParseLine( char * line )
{
	int error = 0;

	printf( "EMU: SD: Parse Line: [%s]\n", lineBuf );

	if( error != 0 ) {
		printf( "EMU: SD: Error %d with [%s]\n", error, lineBuf );
	}
}


/* MassStorage_TX
 *   handle simulation of the sd module receiving stuff
 *   (TX from the simulated computer)
 */
void MassStorage_TX( byte ch )
{
	char lba[2] = { '\0', '\0' };

	/* printf( "EMU: SD: read 0x%02x\n\r", ch ); */

	if( ch == '\r' || ch == '\n' || ch == '\0' )
	{
		// end of string
		MassStorage_ParseLine( lineBuf );
		lineBuf[0] = '\0';
	}
	else if( strlen( lineBuf ) < (kMaxLine-1) )
	{
		lba[0] = ch;
		strcat( lineBuf, lba );
	}
}


/* MassStorage_Status
 *   get port status (0x01 if more data)
 */
byte MassStorage_Status( void )
{
	byte sts = 0x00;

	if( moreToRead ) {
		sts |= kPRS_RxDataReady; /* data is available to read */
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
