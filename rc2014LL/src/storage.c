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

typedef enum {
    kMS_fileClosed = 0,
    kMS_fileRead,
    kMS_fileWrite
} MS_FileState;

static FILE * ms_ioFile = NULL;
static MS_FileState ms_fileState = kMS_fileClosed;

#define kMS_BufSize  (1024 * 1024 * 1)
static char * ms_ByteBuffer = NULL;
static int nibMask = 0;
static int bufPtr = -1;


int MS_QueueAvailable( void )
{
    if( bufPtr > 0 ) return 1;
    return 0;
}

/* Send bytes TO the Z80 */
int MS_QueueByte( char b )
{
    if( bufPtr >= kMS_BufSize ) return 0;

    bufPtr++;
    ms_ByteBuffer[ bufPtr ] = b;

    return 1;
}

void MS_QueueStr( const char * s )
{
    if( !s ) return;

    while( *s ) {
	MS_QueueByte( *s );
	s++;
    }
}

//void MS_QueueDataHex( const unsigned char * data, int nBytes

/* not really "pop" but more of a dequeue */
char MS_QueuePop( void )
{
    char retval = 0x00;
    int x;

    /* if there's nothing, return 0 */
    if( bufPtr >= 0 ) {
	/* stash the return byte aside */
	retval = ms_ByteBuffer[0];

	/* shift them all down */
	for( x=0 ; x< kMS_BufSize-1 ; x++ )
	{
	    ms_ByteBuffer[x] = ms_ByteBuffer[x+1];
	}
	bufPtr--;
    }

    return retval;
}

void MS_QueueDebug( void )
{
    int x;
    printf( "QUEUE: [\n" );
    for( x = 0 ; x < kMS_BufSize ; x++ ) {
	printf( "%c", ms_ByteBuffer[ x ] );
    }

    printf( "\n]\n" );
}



#define kMaxLine (255)
static char lineBuf[kMaxLine];

void MassStorage_ClearLine()
{
    int x;

    for( x=0 ; x<kMaxLine ; x++ ) lineBuf[x] = '\0';
}

/* MassStorage_Init
 *   Initialize the SD simulator
 */
void MassStorage_Init( void )
{
    ms_ByteBuffer = (char *) malloc( kMS_BufSize * sizeof( char ) );
    if( ms_ByteBuffer ) {
	printf( "Mass Storage simulation initialized with %d kBytes\n",
		kMS_BufSize / 1024 );
    } else {
	printf( "ERROR: Mass Storage couldn't allocate %d kBytes\n",
		kMS_BufSize / 1024 );
    }
    MassStorage_ClearLine();
}


static char val2ascii( int val )
{
    const char *hexit = "0123456789ABCDEF";
    val = val & 0x0F;
    return hexit[val];
}

/* ********************************************************************** */

/* MassStorage_RX
 *   handle the simulation of the SD module sending stuff
 *   (RX on the simulated computer)
 */
byte MassStorage_RX( void )
{
    return MS_QueuePop();
}

/* ********************************************************************** */

#define kSD_Path 	"SD_DISK/"

static void MassStorage_Start_Listing( char * path )
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
	MS_QueueStr( "-0:E6=No.\n" );
	return;
    }

    /* header */
    MS_QueueStr( "-0:Nbf=" );
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
	    if( status.st_mode & S_IFDIR ) {
		sprintf( pathbuf, "-0:%s/\n",
			theDirEnt->d_name );
		MS_QueueStr( pathbuf );
		nDirs++;
	    } else {
		sprintf( pathbuf, "-0:%s,%ld\n",
			theDirEnt->d_name, (long)status.st_size );
		MS_QueueStr( pathbuf );
		nFiles++;
	    }

	}


	/* get the next one */
	theDirEnt = readdir( theDir );
    }
    closedir( theDir );

    /* footer */
    /* let's re-use pathbuf just because */
    sprintf( pathbuf, "-0:Nef=%d,%d\n", nFiles, nDirs );
    MS_QueueStr( pathbuf );
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

/* **********************************************************************
 * Files
 */

static void MassStorage_File_Start_Read( char * path )
{
	char pathbuf[255];
	sprintf( pathbuf, "%s%s", kSD_Path, path );

	printf( "EMU: SD: Read from [%s]\n", path ); 

	//if( fp ) fclose( fp );
#ifdef NEVER

	fp = fopen( pathbuf, "r" );
	if( fp == NULL ) {
		/* couldn't open file. */
		printf( "EMU: SD: Can't open %s\n", pathbuf );
		return;
	}
#endif
}


static void MassStorage_File_Start_Write( char * path )
{
	printf( "EMU: SD: Write to [%s]\n", path ); 
	printf( "EMU: SD: unavailable\n" );
}

static void MassStorage_File_ConsumeString( char * data )
{
	printf( "EMU: SD: consume data [%s]\n", data ); 
}

static void MassStorage_File_Close( void )
{
	printf( "EMU: SD: end file.\n" );
#ifdef NEVER
	if( fp != NULL ) {
		fclose( fp );
		fp = NULL;
	}
#endif
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
	    MS_QueueStr( "-0:N1=Card OK\n" );
	    MS_QueueStr( "-0:Nt=EMU64\n" );
	    MS_QueueStr( "-0:Ns=128,meg\n" );
	    break;

	/* Path operations */
	case( 'P' ):
	    switch( line[4] ) {
	    case( 'L' ): /* ls */
		MassStorage_Start_Listing( line+6 );
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
	    MS_QueueStr( "-0:E6=No.\n" );
	    break;
	}
    } else {
	error = 3;
	MS_QueueStr( "-0:E3=No.\n" );
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


/* MassStorage_Status
 *   get port status (0x01 if more data)
 */
byte MassStorage_Status( void )
{
	byte sts = 0x00;

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
