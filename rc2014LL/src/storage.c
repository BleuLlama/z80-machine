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

/*
	New methodology (from the flowchart)

	int shiftSendBit;  // 0x11 for two nibs to send, 0x00 for none
	char sendByte;     // the byte we're sending now
	int moreToSend;    // more content in the file (for chip emu)

    start()
	shiftSendBit = 0x00;
	sendByte = '\0';
	openFile();
	moreToSend = 1;

    done()
	moreToSend = 0;
	closeFile();

    loop()
	// check if we need to refill the sendByte
	if( 0x00 == (shiftSendBit & 0x03) )
	{
	    if( !isNextSendByte() ) {
		// no more bytes to send
		sendByte = 'Z';
		shiftSendBit = 0x03;
			
	    } else {
		sendByte = getNextSendByte();
		shiftSendBit = 0x03;
	    }  
	}

	// send a nib
	nib = 0x00;
	if( shiftSendBit == 0x03 )
	{
	    nib = (sendByte >> 4) & 0x0F;
	} else {
	    // shiftSendBit is 0x01
	    nib = sendByte & 0x0F;
	}
	sendOutByte( ValToHexscii( nib ));

	// adjust our sentinel flags
	shiftSendBit >>= 1;

	// adjust moreToSend
	if( sendByte == 'Z' && shiftSendBit == 0x00 ) {
	    // we do not have more content
	    moreToSend = 0;
	} else {
	    // we have more content
	    moreToSend = 1;
	}
 */


/* Serial interface to the Mass Storage 
 *
 * Status byte will respond if there's more data to be read in
 *
 *  *$ means "ignore everything until end of line"
 *  Commands should read the items they know and ignore until whitespace
 *  or end of line as appropriate
 *
 *  <tilde><cmd><cmd opts (opt.)><space><args (opt.)><dollarSign><newline>
 *  "~<cmd>$\n"
 *  "~<cmd> <args>$\n"
 *
 * Directory
 *   ~L path$		List directory (returned as an ascii file ~FR)
 *			files are on lines by themselves.
 *			lines alternate with <name>,<size>
 *			directores are prepended with a /
 *			directories file size is empty
 *   ~M path$		Create directory (no response)
 *
 * Delete
 *   ~D path$		Delete file or directory
 *
 * File Read
 *   ~FR filename$	File Read as (2 bytes hex per byte of file)
 *			characters used: 0-9,A-F (uppercase)
 *			Newlines may be sent and should be ignored
 *			Ends with ZZ
 * File Write
 *   ~FW filename$	File Write Ascii (as above)
 *   ~FA filename$	File Append Ascii (as above, file is not overwritten)
 *
 *   ~FWH filename$	Write out as intel hex (as above)
 *			File is sent as intel hex format
 *			(Addresses preserved)
 *
 * Sector based file IO (future)
 *   ~SR D S$		Read Drive "D" sector "S"
 *   ~SW D S$		Write Drive "D" sectorn "S"
 * 
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
	char *hexit = "0123456789ABCDEF";
	val = val & 0x0F;
	return hexit[val];
}

#define kBufSize (512)
FILE * fp = NULL;
char buffer[ kBufSize ];
int nInBuf = 0;
int nSent = 0;

#define kReadBufSize (1024 * 1024);	/* 1 meg. why not */
char readBuffer[ 64 * 1024 ];

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

	nInBuf = 0;
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
		nInBuf = 0;
	}
}


/* ********************************************************************** */

/*
    0123
    ~I$		get system info
    ~L path$	ls path
    ~M path$	mkdir path
    ~D path$	rm path

    01234
    ~FR path$	fopen( path, "r" );
    ~FW path$	fopen( path, "w" );
    ~FA path$	fopen( path, "a" ); fseek( 0, SEEK_END );
    ~FW path$	(write as IHX) (future)

    0123
    ~SR D S$	read drive D sector S to buffer
    ~SW D S$	write buffer to drive D sector S
 */

static void MassStorage_ParseLine( char * line )
{
	int error = 0;

	printf( "EMU: SD: Parse Line: [%s]\n", lineBuf );
	if( lineBuf[0] == 'Z' && lineBuf[1] == 'Z' && lineBuf[3] == '\0' ) {
		/* close open write files. */
		MassStorage_End_File();
		return;
	}
	if( lineBuf[0] != '~' ) {
		/* invalid */
		error = 1;
		return;
	}

	if( lineBuf[1] == 'I' && lineBuf[2] == '\0' )
	{
		printf( "EMU: Got ~I.  Should queue up info.\n" );
	}

	if(    lineBuf[2] == ' '
	    && lineBuf[3] != '\0' )
	{
		switch( lineBuf[1] ) {
		case( 'L' ):
			MassStorage_Start_Listing( lineBuf+3 );
			break;
		case( 'M' ):
			MassStorage_Do_MakeDir( lineBuf+3 );
			break;
		case( 'D' ):
			MassStorage_Do_Remove( lineBuf+3 );
			break;
		default:
			error = 2;
		}
	} else if(    lineBuf[3] == ' '
		   && lineBuf[1] == 'S'
		   && lineBuf[4] != '\0' )
	{
		/* Sector operations */
		switch( lineBuf[2] ) {
		case( 'R' ):
			MassStorage_Start_Sector_Read( lineBuf+4 );
			break;
		case( 'W' ):
			MassStorage_Start_Sector_Write( lineBuf+4 );
			break;
		}
	} else if(    lineBuf[3] == ' '
		   && lineBuf[1] == 'F'
		   && lineBuf[4] != '\0' )
	{
		/* file operations */
		switch( lineBuf[2] ) {
		case( 'R' ):
			MassStorage_Start_Read( lineBuf+4 );
			break;
		case( 'W' ):
			MassStorage_Start_Write( lineBuf+4 );
			break;
		case( 'A' ):
			MassStorage_Start_Append( lineBuf+4 );
			break;
		default:
			error = 3;
		}
	}
	else {
		error = 4;
	}

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
