/* Filter for LlamaBDOS
 *	LL/Llama Backchannel Disk Operating System

 *  2017-02-17 Scott Lawrence
 *
 *   Filter console input to provide a backchannel for data transfer
 */

#include <dirent.h>
#include <stdio.h>
#include <string.h>	/* strlen, strcmp */
#include <time.h>	/* time */
#include "mc6850_console.h"
#include "filter.h"

////////////////////////////////////////////////////////////////////////////////
// Define stuff

// This is the starting path on our filesystem
#define kHomePath ("MASS_DRV/BASIC/")

// this is the file autoloaded when "Memory Size? 0"
#define kBootFile ("boot.bas")

// Path buffer sizes
#define kBDOSBufSz (1024)
#define kPRBufSz (255)

// current working directory path
static char cwbuf[kBDOSBufSz];

// full path buffer for building filename paths
char fpbuf[kBDOSBufSz];

// pointer to the current working directory buffer. Should be &cwbuf[0]
char * cwd = NULL;


////////////////////////////////////////////////////////////////////////////////

/* Handle_init
 *
 *  do one-time inits
 */
void Handle_init( void )
{
    if( cwd != NULL ) return;

    cwd = &cwbuf[0];
    strncpy( cwd, kHomePath, kBDOSBufSz );
}

////////////////////////////////////////

/* checkAndAdvance
 *
 *  checks if "buf" starts with "key"
 *	if it does, return the pointer to the next thing in the string
 *	if it doesn't, return a NULL
 */
char * checkAndAdvance( char * buf, char * key )
{
    size_t keylen = 0;
    int cmp = 0;

    if( !buf || !key ) return NULL;

    keylen = strlen( key );
    cmp = strncmp( buf, key, keylen );

    /* if they don't match, just return NULL */
    if( cmp ) return NULL;

    /* now, advance the "buf" ptr */
    buf += keylen;

    /* and move it past whitespace */
    while( *buf == ' ' ) { buf++; };
    
    return buf;
}



////////////////////////////////////////////////////////////////////////////////
/* command handlers... */


////////////////////////////////////////
// path and directory stuff


/* Handle_cd
 *	change directory relative, absolute or $HOME
 */
void Handle_cd( byte * path )
{
    // no path, reset to "home"
    if( !path || path[0] == '\0' )
    {
	cwd = &cwbuf[0];
	strncpy( cwd, kHomePath, kBDOSBufSz );
	return;
    }

    // path set, build the new path, and then test if it exists
    // if it does exist, copy that to 'cwd'

    // TODO
}


int quietText( byte b )
{
    static byte lastb = 0;

    if( ( lastb == 0x0a || lastb == 0x0d ) && b == '.')
    {
    	consumeFcn = NULL;
    }

    lastb = b;
	
    return -1;
}

#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>

int DirOrFileSize( const char *path )
{
    struct stat statbuf;

    /* attempt to stat */
    if (stat(path, &statbuf) != 0) {
    	return -999;
    }

    /* -1 for directory */
    if( S_ISDIR(statbuf.st_mode) ) {
	return -1;
    }

    return statbuf.st_size;
}

/* Handle_catalog
 *	give a listing of the current directory
 *	end it with "."
 */
void Handle_catalog( byte * junk )
{
    DIR *d;
    struct dirent *dir;
    char buf[80];
    int fsize = 0;

    d = opendir( cwd );
    if (d)
    {
	Filter_ToConsolePutString( "Listing of " );
	Filter_ToConsolePutString( cwd );
	Filter_ToConsolePutString( "\n" );
        while ((dir = readdir(d)) != NULL)
        {
	    /* skip if there's no content, or "." */
	    if(    !( dir->d_name[0] == '.' && dir->d_name[1] == '\0' )
		&& !( dir->d_name[0] == '\0' )
	      )
	    {
		snprintf( buf, 80, "%s/%s", cwd, dir->d_name );
		fsize = DirOrFileSize( buf );

		snprintf( buf, 80, "  %20s   ", dir->d_name );
		Filter_ToConsolePutString( buf );
		if( fsize == -1 ) {
		    Filter_ToConsolePutString( "DIR\n" );
		} else if( fsize == -999 ) {
		    Filter_ToConsolePutString( "?err\n" );
		} else {
		    snprintf( buf, 80, "%d\n", fsize );
		    Filter_ToConsolePutString( buf );
		}
	    }
        }
        closedir(d);
    }
}

////////////////////////////////////////////////////////////////////////////////
/* Handle_more
 *	load in a file and send it to the console directly
 */
void Handle_more( byte * filename )
{
    int c = 0;
    FILE * fp = NULL;
    char prbuf[ kPRBufSz ];

    /* build the path */
    strncpy( fpbuf, cwbuf, kBDOSBufSz );
    strncat( fpbuf, filename, kBDOSBufSz );

    fp = fopen( fpbuf, "r" );
    if( fp ) {
	snprintf( prbuf, kPRBufSz, "------- Begin %s -------\n", fpbuf );
	Filter_ToConsolePutString( prbuf );

	while( (c = fgetc(fp)) != EOF ) {
		Filter_ToConsolePutByte( (byte) c );
	}
	
    	fclose( fp );
	snprintf( prbuf, kPRBufSz, "------- End %s -------\n", fpbuf );
	Filter_ToConsolePutString( prbuf );

    } else {
	snprintf( prbuf, kPRBufSz, "%s: Cannot open!/n", fpbuf );
	Filter_ToConsolePutString( prbuf );
    }
}

/* Handle_type
 *	load in a file and send it as though the console was typing it.
 */
void Handle_type( byte * filename )
{
    int crlf = 0;
    int c = 0;
    FILE * fp = NULL;
    char prbuf[ kPRBufSz ];

    /* build the path */
    strncpy( fpbuf, cwbuf, kBDOSBufSz );
    strncat( fpbuf, filename, kBDOSBufSz );

    fp = fopen( fpbuf, "r" );
    if( fp ) {
	snprintf( prbuf, kPRBufSz, "%s: Typing to remote...\n", fpbuf );
	Filter_ToConsolePutString( prbuf );

	while( (c = fgetc(fp)) != EOF ) {
		if( (c == '\r' || c == '\n') && (crlf == 0)) {
		    crlf = 1;
		    Filter_ToRemotePutByte( 0x0a );
		    Filter_ToRemotePutByte( 0x0d );
		} else {
		    crlf = 0;
		    Filter_ToRemotePutByte( (byte) c );
		}
	}
	
    	fclose( fp );
	Filter_ToConsolePutString( "Done!\n" );
    } else {
	snprintf( prbuf, kPRBufSz, "%s: Cannot open!/n", fpbuf );
	Filter_ToConsolePutString( prbuf );
    }
}


////////////////////////////////////////////////////////////////////////////////

/* Handle_load
 *	New, clear and run a new program
 */
void Handle_load( byte * filename )
{
    Filter_ToRemotePutString( "new\r\n" );
    Filter_ToRemotePutString( "clear\r\n" );
    Handle_type( filename );
}

/* Handle_loadrun
 *	New, clear and run a new program, then run it
 */
void Handle_loadrun( byte * filename )
{
    Filter_ToRemotePutString( "new\r\n" );
    Filter_ToRemotePutString( "clear\r\n" );
    Handle_type( filename );
    Filter_ToRemotePutString( "run\r\n" );
}

/* Handle_chain
 *	load and run a program
 *	without 'new' and 'clear'
 */
void Handle_chain( byte * filename )
{
    Handle_type( filename );
    Filter_ToRemotePutString( "run\r\n" );
}


////////////////////////////////////////////////////////////////////////////////
// SAVE routine

/* things i've tried:
 - screen scraping hack -
  1. ^c at the end
  2. ^g at the end
  3. add:  9999 REM SENTINEL
  4. \nOk
  5. manual ^g to end
  6. wait for digits, stop on non-digits, ctrl-g to exit (works, messy)
  7. read in and handle a line at a time
	- if Number, set "got numbers", save line to file
	- if Ok, and gotNumbers, terminate
 */


/* static/globals for the save routine */
#define kLBsz (kBDOSBufSz)
static char cfLineBuf[kLBsz];
static size_t cfLinePos = 0;
static int gotNumbers = 0;
static FILE * savefp = NULL;


/* consumeSaveByte
 *	consume a byte for the save function
 */
int consumeSaveByte( byte b )
{
    if( !savefp )
    {
	consumeFcn = NULL;
	return b;
    }


    /* is end of line? */
    if( b == 0x0a || b == 0x0d ) {
	Filter_ToConsolePutByte( '.' );

	if( cfLineBuf[0] == '\0' ) {
	    /* empty string. do nothing */
	    return( -1 );
	}

	if( cfLineBuf[ 0 ] >= '0' && cfLineBuf[ 0 ] <= '9' ) {
	    /* starts with a line number... save it! */
	    fprintf( savefp, "%s\n", cfLineBuf );
	    gotNumbers = 1;

	} else if( gotNumbers ) {
	    /* it's non-digits after digits, so we exit. */
	    gotNumbers = 0;
	    fclose( savefp );
	    savefp = NULL;
	    Filter_ToConsolePutString( "\n\nDone saving.\n" );
	}

	/* clear the buffer */
	cfLinePos = 0;
	cfLineBuf[0] = '\0';

    } else {
	/* save to the line buffer*/
	if( cfLinePos <= (kLBsz-2) )
	{
	    cfLineBuf[ cfLinePos++ ] = b;
	    cfLineBuf[ cfLinePos ] = '\0';
	}
    }

    return( -1 ); /* don't echo anything! */
}

/* Handle_save
 *	Start the mechanism to save out to a file
 *	- Open the file
 *	- trigger the 'list' command
 *	- set up our capture function above
 */
void Handle_save( byte * filename )
{
    strncpy( fpbuf, cwd, kBDOSBufSz );
    strncat( fpbuf, filename, kBDOSBufSz );

    /* attempt to open the file for write */
    savefp = fopen( fpbuf, "w" );
    if( !savefp ) {
	return;
    }

    /* send out the command and the end marker sentinel */
    Filter_ToRemotePutString( "\n\n\nlist\n" );

    /* enable capture */
    cfLineBuf[0] = '\0';
    cfLinePos = 0;
    gotNumbers = 0;

    consumeFcn = consumeSaveByte;

    /* leave the file open... */
}

////////////////////////////////////////////////////////////////////////////////
// Date and time

/* handle_seconds
 *	send back a number and hit return
 */
void Handle_seconds( byte * arg )
{
    char buf[16];
    snprintf( buf, 16, "   %lu\r\n", (unsigned long) time( NULL ));
    Filter_ToRemotePutString( buf );
    //printf( "secs>> %s <<\n", buf );
}


/* handle_date
 *	send back a parseable date string
 */
void Handle_date( byte * arg )
{
    time_t current_time = time( NULL );
    char buf[32];

    struct tm * loctime;
    loctime = localtime( &current_time );
    strftime( buf, 32, "   %Y%m%d  %H%M%S\r\n", loctime );
    Filter_ToRemotePutString( buf );
    //printf( "date>> %s <<\n", buf );
}



////////////////////////////////////////////////////////////////////////////////
/* handle_boot
 *	trigger the command to run when the "boot" command is called
 *	basically, chain "boot.bas" (new, load, run )
 */
void Handle_boot( byte * filename )
{
    /* handle the case where the user types 0 for autoboot */
    Handle_loadrun( kBootFile );
}

////////////////////////////////////////////////////////////////////////////////

typedef void (*handleFcn)( byte * );

struct HandlerFuns {
    char * name;
    handleFcn fcn;
};


/* handlers for all of the functions called by the remote */
struct HandlerFuns tcFuncs[] = {
    { "boot", Handle_boot },

    /* file type */
    { "type", Handle_type },
    { "chain", Handle_chain },
    { "loadrun", Handle_loadrun }, /* must be before "load" */
    { "load", Handle_load },
    { "save", Handle_save },

    /* directory */
    { "catalog", Handle_catalog },
    { "cd", Handle_cd },

    /* datetime */
    { "seconds", Handle_seconds },
    { "date", Handle_date },

    { NULL, NULL }
};

/* handlers for all of the functions called by the console */
struct HandlerFuns trFuncs[] = {
    { "boot", Handle_boot },
    { "more", Handle_more },

    /* file type */
    { "type", Handle_type },
    { "chain", Handle_chain },
    { "loadrun", Handle_loadrun }, /* must be before "load" */
    { "load", Handle_load },
    { "save", Handle_save },

    /* directory */
    { "catalog", Handle_catalog },
    { "cd", Handle_cd },

    /* datetime */
    { "seconds", Handle_seconds },
    { "date", Handle_date },

    { NULL, NULL }
};


////////////////////////////////////////////////////////////////////////////////

/* Filter_ProcessTC
 *
 *  Process content initiated by the remote computer 
 */
void Filter_ProcessTC( byte * buf, size_t len )
{
    struct HandlerFuns * hf = tcFuncs;
    byte *args = NULL;
    int used = 0;

    printf( "PROCESS To Console: %ld|%s|\n", len, buf );

    /* sanity check the arguments */
    if( len < 1 || buf == NULL || buf[0] == '\0' ) return;

    /* iterate over the function list to find the handler */
    while( hf->name != NULL && !used ) {
    	if( (args = checkAndAdvance( buf, hf->name )) != NULL )
	{
	    /* found it! Call the handler! */
	    Handle_init();
	    hf->fcn( args );
	    used = 1;
	}
	hf++;
    }

    /* output a message if it wasn't handled. */
    if( !used ) {
	Filter_ToConsolePutString( "TC: Command not found: " );
	Filter_ToConsolePutString( buf );
	Filter_ToConsolePutString( "\n" );
    }
}

/* Filter_ProcessTR
 *
 *  Process content initiated by the user at the console
 */
void Filter_ProcessTR( byte * buf, size_t len )
{
    int used = 0;
    byte *args = NULL;

    printf( "PROCESS To Remote: %ld|%s|\n", len, buf );

    /* sanity check the arguments */
    if( len < 1 || buf == NULL || buf[0] == '\0' ) return;

    /* iterate over the function list to find the handler */
    struct HandlerFuns * hf = trFuncs;
    while( hf->name != NULL ) {
    	if( (args = checkAndAdvance( buf, hf->name )) != NULL )
	{
	    /* found it! Call the handler! */
	    hf->fcn( args );
	    used = 1;
	}
	hf++;
    }

    /* output a message if it wasn't handled. */
    if( !used ) {
	Filter_ToConsolePutString( "TR: Command not found: " );
	Filter_ToConsolePutString( buf );
	Filter_ToConsolePutString( "\n" );
    }
}
