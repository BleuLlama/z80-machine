/* Filter header
 *
 *  2017-02-17 Scott Lawrence
 *
 *   Filter console input to provide a backchannel for data transfer
 */

#ifndef __FILTER_H__
#define __FILTER_H__

////////////////////////////////////////

/* pass-through */
#define kPS_IDLE	(0)

/* Start command? */
#define kEscKey		(0x1b)
#define kPS_ESC		(1)

/* for REMOTE -> CONSOLE */
#define kStartMsgRC 	('{')	/* esc{  to start from the Remote */
#define kStartMsgCR	('}')	/* esc}  to start from the Remote */
#define kEndMsg 	(0x07)	/* ^g (BELL) to end */

#define kPS_TCCMD	(2)

/* for CONSOLE -> REMOTE */
#define kPS_TRCMD	(3)

////////////////////////////////////////
// These are the handlers for the captured streams
void Filter_ProcessTC( byte * buf, size_t len ); // process REMOTE->CONSOLE command
void Filter_ProcessTR( byte * buf, size_t len ); // process CONSOLE->REMOTE command

/* Filters should use these to output text */
void Filter_ToConsolePutByte( byte data );
void Filter_ToConsolePutString( char * str );

void Filter_ToRemotePutByte( byte data );
void Filter_ToRemotePutString( char * str );

////////////////////////////////////////

// If this function pointer is set, then bytes
// will be passed through it as well.
// return the byte passed in for it to get further consumed
// or return -1 to not further pass on anything

typedef int (*consumeByteFcn)( byte );

consumeByteFcn consumeFcn;


#endif
