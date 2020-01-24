/* Filter
 *
 *  2017-02-17 Scott Lawrence
 *
 *   Filter console input to provide a backchannel for data transfer
 */

#include <stdio.h>
#include <string.h>		/* for strlen() */
#include "mc6850_console.h"
#include "config.h"
#include "filter.h"


////////////////////////////////////////

/* max space in the buffers */
#define kFCPosMax (1024 * 1024) /* 1 megabyte buffers */

/* TO Console buffers */
static int tcPos = -1;
char ToConsoleBuffer[kFCPosMax]; /* additional stuff we're sending to the console */

static int ProcessStageTC = kPS_IDLE;
static byte FilterTCCommand[ kFCPosMax ];
static size_t FC_TCPos = 0;

/* TO Remote buffers */
static int trPos = -1;
char ToRemoteBuffer[kFCPosMax]; /* additional stuff we're sending to the console */

static int ProcessStageTR = kPS_IDLE;
static byte FilterTRCommand[ kFCPosMax ];
static size_t FC_TRPos = 0;


// Filter_Init
//  perform all initialization stuff
void Filter_Init( z80info * z80 )
{
#ifdef FILTER_CONSOLE
    printf( "--------------------------------------------\n" );
    printf( "Type '0' for memory size to trigger autoload.\n" );
	printf( "Autoload file: %s%s\n", kHomePath, kBootFile );
    printf( "--------------------------------------------\n\n" );
#endif
}

////////////////////////////////////////////////////////////////////////////////
// to console buffer stuff 


// Filter_ToConsolePutByte
//  add something into the ToConsole buffer
void Filter_ToConsolePutByte( byte data )
{
    tcPos++;
    ToConsoleBuffer[tcPos] = data;
    ToConsoleBuffer[tcPos+1] = '\0';
}

void Filter_ToConsolePutString( char * str )
{
    while( str && *str ) {
	Filter_ToConsolePutByte( *str );
	str++;
    }
}

// Filter_ToConsoleAvailable
//  Is there something in the ToConsole buffer?
int Filter_ToConsoleAvailable()
{
    if( tcPos == -1 ) return 0;
    return 1;
}

// Filter_ToConsoleGet
//  get something from the ToConsole buffer
byte Filter_ToConsoleGet()
{
    size_t i;
    byte r;

    if( tcPos == -1 ) return 0xff;

    r = ToConsoleBuffer[0];

    /* shift everything down */
    for( i=0 ; i<kFCPosMax-1 ; i++ ) {
	ToConsoleBuffer[i] = ToConsoleBuffer[i+1];
    }
    tcPos--;

    return r;
}


//////////////////////////////////////////////////////////////////////
// autostart support

#define kASBLen	(16)
char autostartBuf[ kASBLen ];
int asBpos = 0;


void Filter_AutostartCheck( byte data )
{
    autostartBuf[ asBpos ] = '\0';

    /* check for end of line */
    if( data == '\n' || data == '\r' ) {
	if( !strcmp( autostartBuf, kAutoBootPhrase )) {
		Filter_ToConsolePutString( "\n>> Autostart phrase detected <<\n" );
    		Filter_ProcessTC( kAutoBootCommand, strlen( kAutoBootCommand ) );
	}

	asBpos = 0;
	autostartBuf[ 0 ] = '\0';
    } else {
	/* Nope. append if we're okay to do so */
	if( asBpos < (kASBLen-2) ) {
	    autostartBuf[ asBpos ] = data;
	    asBpos++;
	    autostartBuf[ asBpos ] = data;
	}
    }

}

//////////////////////////////////////////////////////////////////////

////////////////////////////////////////

/* for REMOTE -> CONSOLE (TC) */

void Filter_ReInitTC( void )
{
    int tcPos=0;

    ProcessStageTC = kPS_IDLE;

    for( tcPos=0 ; tcPos<(kFCPosMax-1) ; tcPos++ )
	FilterTCCommand[tcPos] = '\0';
    FC_TCPos = 0;
}


/* filter input going TO the CONSOLE */
void Filter_ToConsole( byte data )
{
    Filter_AutostartCheck( data );

    if( consumeFcn ) {
    	int r = consumeFcn( data );
	if( r == -1 ) return;
    }
    
    switch( ProcessStageTC ) {

	case( kPS_IDLE ):
	    if( data == kEscKey ) {
		ProcessStageTC = kPS_ESC;
	    } else {
	    	Filter_ToConsolePutByte( data );
	    }
	    break;

	case( kPS_ESC ):
	    if( data == '\r' || data == '\n' ) {
		/* bail out */
                ProcessStageTC = kPS_IDLE;
		Filter_ReInitTC();

	    } else if( data == kStartMsgRC ) {
		/* yep! it's for us! */
                ProcessStageTC = kPS_TCCMD;	/* Remote->Console command! */
            } else {
		/* nope.  inject both bytes so far. */
		Filter_ToConsolePutByte( kEscKey );
		Filter_ToConsolePutByte( data );
		/* and restore our state... */
		ProcessStageTC = kPS_IDLE;
	    }
	    break;

	case( kPS_TCCMD ):
	    /* process... */
	    if( data == '\r' || data == '\n' ) {
		/* bail out */
                ProcessStageTC = kPS_IDLE;
		Filter_ReInitTC();

	    } else if( data == kEndMsg ) {
		/* We're done. process it! */
                ProcessStageTC = kPS_IDLE;
		Filter_ProcessTC( FilterTCCommand, FC_TCPos );
		Filter_ReInitTC();

	    } else {
		if( FC_TCPos < kFCPosMax ) {
		    FilterTCCommand[ FC_TCPos ] = data;
		    FC_TCPos++;
		}
	    }
	    break;

	default:
	    ProcessStageTC = kPS_IDLE;
	    Filter_ToConsolePutByte( data );
	    break;
    }
}


////////////////////////////////////////////////////////////////////////////////
// to remote buffer stuff 


// Filter_ToRemotePutByte
//  add something into the ToRemote buffer
void Filter_ToRemotePutByte( byte data )
{
    if( trPos < 0 ) {
	trPos = 0;
    } else {
	trPos++;
    }
    ToRemoteBuffer[trPos] = data;
    ToRemoteBuffer[trPos+1] = '\0';
}

void Filter_ToRemotePutString( char * str )
{
    while( str && *str ) {
	Filter_ToRemotePutByte( *str );
	str++;
    }
}

// Filter_ToRemoteAvailable
//  Is there something in the ToRemote buffer?
int Filter_ToRemoteAvailable()
{
    if( trPos < 0 ) return 0;
    return 1;
}

// Filter_ToRemoteGet
//  get something from the ToRemote buffer
byte Filter_ToRemoteGet()
{
    size_t i;
    byte r;

    if( trPos < 0 ) return 0xff;

    r = ToRemoteBuffer[0];

    /* shift everything down */
    for( i=0 ; i<kFCPosMax-1 ; i++ ) {
	ToRemoteBuffer[i] = ToRemoteBuffer[i+1];
    }
    trPos--;

    return r;
}

////////////////////////////////////////////////////////////////////////////////
// TO REMOTE


void Filter_ReInitTR( void )
{
    int trPos=0;

    ProcessStageTR = kPS_IDLE;

    for( trPos=0 ; trPos<(kFCPosMax-1) ; trPos++ )
	FilterTCCommand[trPos] = '\0';
    FC_TRPos = 0;
}

/* filter input going TO the REMOTE */
void Filter_ToRemote( byte data )
{
    switch( ProcessStageTR ) {

	case( kPS_IDLE ):
	    if( data == kEscKey ) {
		ProcessStageTR = kPS_ESC;
	    } else {
	    	Filter_ToRemotePutByte( data );
	    }
	    break;

	case( kPS_ESC ):
	    if( data == '\r' || data == '\n' ) {
		/* bail out */
                ProcessStageTR = kPS_IDLE;
		Filter_ReInitTR();

	    } if( data == kStartMsgCR ) {
		/* yep! it's for us! */
                ProcessStageTR = kPS_TRCMD;	/* Console->Remote command! */

            } else {
		/* nope.  inject both bytes so far. */
		Filter_ToRemotePutByte( kEscKey );
		Filter_ToRemotePutByte( data );
		/* and restore our state... */
		ProcessStageTR = kPS_IDLE;
	    }
	    break;

	case( kPS_TRCMD ):
	    /* process... */
	    if( data == '\r' || data == '\n' ) {
		/* Bail out! */
                ProcessStageTR = kPS_IDLE;
		Filter_ReInitTR();

	    } else if( data == kEndMsg ) {
		/* We're done. process it! */
                ProcessStageTR = kPS_IDLE;
		Filter_ProcessTR( FilterTRCommand, FC_TRPos );
		Filter_ReInitTR();

	    } else {
		if( FC_TRPos < kFCPosMax ) {
		    FilterTRCommand[ FC_TRPos ] = data;
		    FC_TRPos++;
		}
	    }
	    break;

	default:
	    ProcessStageTR = kPS_IDLE;
	    Filter_ToRemotePutByte( data );
	    break;
    }
}
