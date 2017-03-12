/* Mass Storage
 *
 *  Simulates a SD card storage device attached via MC6850 ACIA
 *
 *  2016-Jun-10  Scott Lawrence
 */

#include <stdio.h>
#include <stdlib.h>	/* malloc */
#include <sys/types.h>
#include <sys/stat.h>	/* for mkdir */
#include <unistd.h>	/* for rmdir, unlink */
#include <dirent.h>
#include <string.h>
#include "defs.h"
#include "storage.h"
#include "rc2014.h"	/* common rc2014 emulator headers */
#include "../Arduino/SDDrive/Strings.h"


/* ********************************************************************** */

/* See the Arduino implementation and document for the full protocol
 */

/*
   NOTE: that we can't use the exact same code in here since over
   there, we're basically multiprocessing, so the arduino can sit
   in a tight loop, waiting for new bytes, whereas here, we need
   to prepare a few at a time (or one at a time) and then send that
   and then relinquish control back to the core engine.
*/

#define kMS_BufSize  (1024 * 1)
static char * ms_SendQueue = NULL;
static int bufPtr = -1;


/* MS_QueueAvailable
 *	returns 1 if there's something to be popped from the queue
 *	returns 0 if the queue is empty
 */
int MS_QueueAvailable( void )
{
    if( bufPtr > 0 ) return 1;
    return 0;
}

/* Send bytes TO the Z80 */

/* MS_QueueByte
 *	pushes the single byte onto the queue
 *	reutrns 1 if successful, 0 if not
 */
int MS_QueueByte( char b )
{
    if( bufPtr >= kMS_BufSize ) return 0;

    bufPtr++;
    ms_SendQueue[ bufPtr ] = b;

    return 1;
}

/* MS_QueueStr
 *	takes the string, pushes it onto the queue
 *	returns the number of bytes pushed
 */
int MS_QueueStr( const char * s )
{
    int nq = 0;

    if( s ) {
	while( *s ) {
	    nq += MS_QueueByte( *s );
	    s++;
	}
    }
    return nq;
}

/* MS_QueueHex
 *	takes the value, converts it to an ascii string
 *	then pushes that onto the queue
 *	returns the number of bytes pushed
 */
int MS_QueueHex( unsigned char val )
{
    char b[4];

    sprintf( b, "%02x", val );
    return MS_QueueStr( b );
}

/* MS_QueueHexString
 *	take a string, queue the hex values for the string
 *	returns the number of bytes pushed
 */
int MS_QueueHexString( const char * str )
{
    int ret = 0;

    while( str && *str ) {
	ret += MS_QueueHex( *str );
	str++;
    }
    return ret;
}

/* MS_QueueHexLong
 *	take a value, queue the hex values for it
 *	returns the number of bytes pushed
 */
int MS_QueueHexLong( long val )
{
    char buf[16];

    sprintf( buf, "%ld", val );

    return MS_QueueHexString( buf );
}


/* MS_QueuePop
 *	removes the head char off the queue, shifts the rest
 *	returns the pulled off character
 */
char MS_QueuePop( void )
{
    char retval = 0x00;
    int x;

    /* if there's nothing, return 0 */
    if( bufPtr >= 0 ) {
	/* stash the return byte aside */
	retval = ms_SendQueue[0];

	/* shift them all down */
	for( x=0 ; x< kMS_BufSize-1 ; x++ )
	{
	    ms_SendQueue[x] = ms_SendQueue[x+1];
	}
	bufPtr--;
    }

    return retval;
}

/* MS_QueueSpace
 *	returns the number of bytes of free space in the queue buffer
 */
int MS_QueueSpace( void )
{
    return( kMS_BufSize - bufPtr - 2);
}

/* MS_QueueDebug
 *	dump out the used space in the Queue to stdout
 */
void MS_QueueDebug( void )
{
    int x;
    printf( "QUEUE: [\n" );
    for( x = 0 ; x < kMS_BufSize ; x++ ) {
	printf( "%c", ms_SendQueue[ x ] );
    }

    printf( "\n]\n" );
}


/* ********************************************************************** */

#define kMaxLine (255)
static char lineBuf[kMaxLine];

/* MassStorage_ClearLine
 *	clear the entire linebuffer for parsing
 */
void MassStorage_ClearLine()
{
    int x;

    for( x=0 ; x<kMaxLine ; x++ ) lineBuf[x] = '\0';
}

/* MassStorage_Init
 *	Initialize the SD simulator
 */
void MassStorage_Init( void )
{
    ms_SendQueue = (char *) malloc( kMS_BufSize * sizeof( char ) );
    if( ms_SendQueue ) {
	printf( "Mass Storage simulation initialized with %d kBytes\n",
		kMS_BufSize / 1024 );
    } else {
	printf( "ERROR: Mass Storage couldn't allocate %d kBytes\n",
		kMS_BufSize / 1024 );
    }
    MassStorage_ClearLine();
}



/* ********************************************************************** */

#define kSD_Path 	"MASS_DRV/"


/* MassStorage_Do_Listing
 *	Takes a directory list of the passed-in path
 *	Queues all of the strings into the queue.
 */
static void MassStorage_Do_Listing( char * path )
{
    char pathbuf[255];

    struct stat status;
    struct dirent *theDirEnt;
    DIR * theDir = NULL;
    int nFiles = 0;
    int nDirs = 0;

    /* build the path */
    sprintf( pathbuf, "%s%s", kSD_Path, path );

    printf( "EMU: SD: ls [%s]\n", pathbuf );

    /* open the directory */
    theDir = opendir( pathbuf );

    if( !theDir ) {
	MS_QueueStr( "-0:" kStr_Error_CmdFail "\n" );
	return;
    }

    /* header */
    MS_QueueStr( "-0:PB=" );
    MS_QueueStr( path );
    MS_QueueStr( "\n" );
    
    /* read the first one */
    theDirEnt = readdir( theDir );
    while( theDirEnt ) {
	int skip = 0;

	/* always skip dotpaths */
	if( !strcmp( theDirEnt->d_name, "." )) skip = 1;
	if( !strcmp( theDirEnt->d_name, ".." )) skip = 1;

	if( !skip ) {
	    /* determine if file or dir */
	    sprintf( pathbuf, "%s%s/%s", kSD_Path, path, theDirEnt->d_name );
	    stat( pathbuf, &status );

	    /* output the correct line */
	    if( S_ISDIR( status.st_mode )) {
		MS_QueueStr( "-0:PD=" );
		MS_QueueHexString( theDirEnt->d_name );
		MS_QueueStr( "\n" );
		nDirs++;
	    } else {
		MS_QueueStr( "-0:PF=" );
		MS_QueueHexString( theDirEnt->d_name );
		MS_QueueHex( ',' );
		MS_QueueHexLong( (long)status.st_size );
		MS_QueueStr( "\n" );
		nFiles++;
	    }

	}


	/* get the next one */
	theDirEnt = readdir( theDir );
    }
    closedir( theDir );

    /* footer */
    /* let's re-use pathbuf just because */
    sprintf( pathbuf, "-0:PE=%d,%d\n", nFiles, nDirs );
    MS_QueueStr( pathbuf );
}

static void MassStorage_Do_MakeDir( char * path )
{
	char pathbuf[255];
	sprintf( pathbuf, "%s%s", kSD_Path, path );

	printf( "EMU: SD: mkdir [%s]\n", path ); 
	printf( "         %s\n", pathbuf );
	mkdir( pathbuf, 0755 );
	MS_QueueStr( kStr_CmdOK );
}

static void MassStorage_Do_Remove( char * path )
{
	char pathbuf[255];
	sprintf( pathbuf, "%s%s", kSD_Path, path );

	printf( "EMU: SD: rm [%s]\n", path ); 

	/* let's be stupid and just try to remove the file AND dir */
	rmdir( pathbuf );
	unlink( pathbuf );
	MS_QueueStr( kStr_CmdOK );
}

/* **********************************************************************
 * Files
 */

static FILE * readFile = NULL;
static FILE * writeFile = NULL;

/*
    start read()
	1. open the file
	2. if fail, send error code, done
	3. queue begin line
	4. fillCheck()
	5. return;

    fill check()
	1. if file closed, return
	2. While there's space in the queue buffer
	  2A. Read in the next 16 bytes -> NRead
	  2B. if read 0 bytes:
	    2Ba. queue new -0:FE=(size) line
	  2C. else
	    2Ca. queue new -0:FS= line

    status()
	1. fill check()
	2. if there's stuff in the buffer, ret=1 else ret=0
    
    _rx()
	1. fill check()
	2. pop from queue to return

    close()
	1. close the file, if open
*/

/* MassStorage_FillCheck
 *	check to see if the file has more content for the queue
 */
static void MassStorage_FillCheck( void )
{
#define NPerFill (16)	/* queue buf must be this*2+8+pad minimum */

    char databuf[ (NPerFill * 2) + 2];
    char strbuf[512];
    size_t nRead;
    int j;

    /* no file open, so just return */
    if( readFile == NULL ) return;

    /* if there's space, push some more...*/
    if( MS_QueueSpace() > ( (NPerFill*2) + 8 )) {
	/* read some data */
	nRead = fread( databuf, 1, NPerFill, readFile );

	if( nRead > 0 ) {
	    /* make a queue data message */
	    MS_QueueStr( "-0:FS=" );

	    for( j=0 ; j<nRead ; j++ ) {
		MS_QueueHex( databuf[j] );
	    }

	    MS_QueueStr( "\n" );

	} else {
	    /* no more data, send the footer */
	    nRead = (size_t)ftell( readFile ); 
	    fclose( readFile );
	    readFile = NULL;

	    /* send the footer */
	    sprintf( strbuf, "-0:FE=%ld\n", (long int)nRead );
	    MS_QueueStr( strbuf );
	}
    }
}


static void MassStorage_File_Start_Read( char * path )
{
    char pathbuf[255];
    sprintf( pathbuf, "%s%s", kSD_Path, path );

    printf( "EMU: SD: Read from [%s]\n", path ); 

    if( readFile ) {
	fclose( readFile );
    }
    readFile = fopen( pathbuf, "rb" );
    if( readFile == NULL ) {
	/* couldn't open file. */
	printf( "EMU: SD: Can't open %s\n", pathbuf );
	MS_QueueStr( "-0:" kStr_Error_FileNotFound "\n" );
	return;
    }

    /* start the header... */
    MS_QueueStr( "-0:FB=" );
    MS_QueueStr( path );
    MS_QueueStr( "\n" );

    /* attempt to put some file data into the send queue */
    MassStorage_FillCheck();
}


static void MassStorage_File_Start_Write( char * path )
{
    char pathbuf[255];
    sprintf( pathbuf, "%s%s", kSD_Path, path );

    printf( "EMU: SD: Write to [%s]\n", path ); 

    if( writeFile ) {
	fclose( writeFile );
    }
    writeFile = fopen( pathbuf, "wb" );
    if( writeFile == NULL ) {
	/* couldn't open file. */
	printf( "EMU: SD: Can't open %s\n", pathbuf );
	MS_QueueStr( "-0:" kStr_Error_NoFileWrite "\n" );
	return;
    }

    /* do stuff for write catching */
}

int IsHex( const char ch )
{
    if( ch >= '0' && ch <= '9' ) return 1;
    if( ch >= 'a' && ch <= 'f' ) return 1;
    if( ch >= 'A' && ch <= 'F' ) return 1;
    return 0;
}

int HexToVal( const char ch )
{
    if( ch >= '0' && ch <= '9' ) return( ch-'0' );
    if( ch >= 'a' && ch <= 'f' ) return( ch-'a'+10 );
    if( ch >= 'A' && ch <= 'F' ) return( ch-'A'+10 );
    return 0;
}

static void MassStorage_File_ConsumeString( char * data )
{
    char buf[64];
    printf( "EMU: SD: consume data [%s]\n", data ); 

    if( writeFile == NULL || data == NULL ) {
	MS_QueueStr( "-0:" kStr_Error_NoFileWrite "\n" );
	return;
    }

    if( strlen( data ) < 1 ) {
	MS_QueueStr( "-0:" kStr_Error_NoFileWrite "\n" );
	return;
    }

    /* scan the string */

    unsigned char val = 0;
    unsigned char nNibs = 0;
    int nBytes = 0;
    int sum = 0;

    /* find all alphanum */
    while( *data != '\0' ) {
	if( IsHex( *data )) {
	    if( nNibs == 0 ) {
		/* build the byte */
		val = HexToVal( *data )<<4;
		nNibs = 1;
	    } else {
		/* finish the byte */
		val = (val & 0xF0) | HexToVal( *data );
		nNibs = 0;

		/* hand it off to the file */
		fwrite( &val, 1, 1, writeFile );
		fflush( writeFile );

		/* statistics */
		sum += val;
		nBytes++;
	    }
	}

	/* Next byte in from the user */
	data++;
    }

    sprintf( buf, "-0:Nc=x%02x,x%02x\n", nBytes, 
		(unsigned char)(((~sum)+1) &0x0FF) );

    MS_QueueStr( buf );
}

static void MassStorage_File_Close( void )
{
    printf( "EMU: SD: end file.\n" );

    if( readFile != NULL ) {
	fclose( readFile );
	readFile = NULL;
    }

    if( writeFile != NULL ) {
	fclose( writeFile );
	writeFile = NULL;
    }
}

/* **********************************************************************
 * Sectors
 */


static void MassStorage_Sector_Start_Read( char * args )
{
	printf( "EMU: SD: Read Sector [%s]\n", args ); 
	printf( "EMU: SD: unavailable\n" );
}

static void MassStorage_Sector_Start_Write( char * args )
{
	printf( "EMU: SD: Write Sector [%s]\n", args ); 
	printf( "EMU: SD: unavailable\n" );
}

static void MassStorage_Sector_ConsumeString( char * data )
{
	printf( "EMU: SD: consume data [%s]\n", data ); 
}

static void MassStorage_Sector_Close( void )
{
	printf( "EMU: SD: end file.\n" );
#ifdef NEVER
	if( fp != NULL ) {
		fclose( fp );
		fp = NULL;
	}
#endif
}


/* ********************************************************************** */

/* cheat sheet
    ~ -> command to SD Drive
    - -> response from SD Drive
    ~0:XX=xxx 	with csv parameter(s)
    ~0:XX	no parameters

    [~-]<device>:<type><operation>(=<param>(,<param>)*)

    01234
    ~0:I	get system info

    ~0:PL=path	ls path
    ~0:PM=path	mkdir path
    ~0:PR=path	rm path

    01234
    ~0:FR=file	fopen( path, "r" );
		-0:FB=path
		-0:FS=292929292929292
		-0:FE=22
		-0:N2=OK
	Nbf begin file
	Nef end file
    ~0:FW=file	fopen( path, "w" );
		~0:FW=newfile.txt
		-0:N2=OK
		~0:FS=292929292929299A23993
		-0:Nc=03,99
		~0:FC
		-0:N2=OK
    ~0:FC	close
    ~0:FS=data	Send string

	Nc=xx,yy	xx=Nbytes (not nibbles, yy=2's comp invert(sum)+1
		yy = (~sumVal)+1
    0123
    ~0:SR=D,T,S	read drive D, Track T, Sector S to buffer
    ~0:SW=D,T,S	write buffer to drive D, Track T, sector S
    ~0:SC	close sector file
    ~0:SS=data	Data from sector read

 */


/* MassStorage_ParseLinF
 *	Parse the line coming in from the host computer
 *	Valve it off to the right helper function
 */
static void MassStorage_ParseLine( char * line )
{
    int error = 0;

    /* output some indication of an empty line, but keep things quiet. */
    if( *line == '\0' ) {
	printf( " " );
	fflush( stdout );
	return;
    }

    printf( "EMU: SD: Parse Line: [%s]\n", lineBuf );


    if( line[0] == '~' && line[1] == '0' && line[2] == ':' ) {
	switch( line[3] ) {
	case( 'I' ):
	    /* Info command */
	    MS_QueueStr( "-0:" kStr_CardOk "\n" );
	    MS_QueueStr( "-0:" kStr_FAType "42\n" );
	    MS_QueueStr( "-0:" kStr_Size "100" kStr_SizeUnits "\n" );
	    break;

	/* Path operations */
	case( 'P' ):
	    switch( line[4] ) {
	    case( 'L' ): /* ls */
		MassStorage_Do_Listing( line+6 );
		break;

	    case( 'M' ): /* mkdir */
		MassStorage_Do_MakeDir( line+6 );
		break;

	    case( 'R' ): /* rm */
		MassStorage_Do_Remove( line+6 );
		break;

	    default:
		break;
	    }
	    break;

	/* File operations */
	case( 'F' ):
	    switch( line[4] ) {
	    case( 'R' ):
		MassStorage_File_Start_Read( line+6 );
		break;

	    case( 'W' ):
		MassStorage_File_Start_Write( line+6 );
		break;

	    case( 'S' ):
		MassStorage_File_ConsumeString( line+6 );
		break;

	    case( 'C' ):
		MassStorage_File_Close();
		break;

	    default:
		break;
	    }
	    break;

	/* Sector operations */
	case( 'S' ):
	    switch( line[4] ) {
	    case( 'R' ):
		MassStorage_Sector_Start_Read( line+6 );
		break;

	    case( 'W' ):
		MassStorage_Sector_Start_Write( line+6 );
		break;

	    case( 'S' ):
		MassStorage_Sector_ConsumeString( line+6 );
		break;

	    case( 'C' ):
		MassStorage_Sector_Close();
		break;

	    default:
		break;
	    }
	    break;

	default:
	    error = 6;
	    MS_QueueStr( "-0:" kStr_Error_CmdFail "\n" );
	    break;
	}
    } else {
	error = 3;
	MS_QueueStr( "-0:" kStr_Error_NotImplemented "\n" );
    }

    if( error != 0 ) {
	printf( "EMU: SD: Error %d with [%s]\n", error, lineBuf );
    }
    /* MS_QueueDebug(); */
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
	MassStorage_ClearLine();
    }

    else if( strlen( lineBuf ) < (kMaxLine-1) )
    {
	lba[0] = ch;
	strcat( lineBuf, lba );
    }
}


/* ********************************************************************** */

/* MassStorage_RX
 *   handle the simulation of the SD module sending stuff
 *   (RX on the simulated computer)
 */
byte MassStorage_RX( void )
{
    /* see if there's more to go into the queue */
    MassStorage_FillCheck();

    /* then pop something off (if applicable) */
    return MS_QueuePop();
}


/* ********************************************************************** */

/* MassStorage_Status
 *   get port status (0x01 if more data)
 */
byte MassStorage_Status( void )
    {
    byte sts = 0x00;

    /* see if there's more to go into the queue */
    MassStorage_FillCheck();

    if( bufPtr >= 0 ) {
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
