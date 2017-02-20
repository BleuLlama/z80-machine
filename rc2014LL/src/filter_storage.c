/* Filter
 *
 *  2017-02-17 Scott Lawrence
 *
 *   Filter console input to provide a backchannel for data transfer
 */

#include <stdio.h>
#include <string.h>	/* strlen, strcmp */
#include "mc6850_console.h"
#include "filter.h"

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

char cwbuf[1024];
char fpbuf[1024];

char * cwd = NULL;

/* Handle_init
 *
 *  do one-time inits
 */
void Handle_init( void )
{
    if( cwd != NULL ) return;


    cwd = &cwbuf[0];
    strcpy( cwd, "MASS_DRV/BASIC/" );
    
}

/* command handlers... */

void Handle_more( byte * filename )
{
    int c = 0;
    FILE * fp = NULL;
    char prbuf[ 255 ];
    Handle_init();

    /* build the path */
    strcpy( fpbuf, cwbuf );
    strcat( fpbuf, filename );

    fp = fopen( fpbuf, "r" );
    if( fp ) {
	sprintf( prbuf, "------- Begin %s -------\n", fpbuf );
	Filter_ToConsolePutString( prbuf );

	while( (c = fgetc(fp)) != EOF ) {
		Filter_ToConsolePutByte( (byte) c );
	}
	
    	fclose( fp );
	sprintf( prbuf, "------- End %s -------\n", fpbuf );
	Filter_ToConsolePutString( prbuf );

    } else {
	sprintf( prbuf, "%s: Cannot open!/n", fpbuf );
	Filter_ToConsolePutString( prbuf );
    }
}

void Handle_type( byte * filename )
{
    int crlf = 0;
    int c = 0;
    FILE * fp = NULL;
    char prbuf[ 255 ];
    Handle_init();

    /* build the path */
    strcpy( fpbuf, cwbuf );
    strcat( fpbuf, filename );

    fp = fopen( fpbuf, "r" );
    if( fp ) {
	sprintf( prbuf, "%s: Typing to remote...\n", fpbuf );
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
	sprintf( prbuf, "%s: Cannot open!/n", fpbuf );
	Filter_ToConsolePutString( prbuf );
    }
}

void Handle_go( byte * filename )
{
     Handle_type( "go.txt" );
}

////////////////////////////////////////////////////////////////////////////////

typedef void (*handleFcn)( byte * );

struct HandlerFuns {
    char * name;
    handleFcn fcn;
};


/* handlers for all of the functions called by the remote */
struct HandlerFuns tcFuncs[] = {
    { NULL, NULL }
};

/* handlers for all of the functions called by the console */
struct HandlerFuns trFuncs[] = {
    { "go", Handle_go },
    { "type", Handle_type },
    { "more", Handle_more },
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
