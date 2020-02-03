/* Host OS interface stuff.
 *
 *  Any os-specific stuff should be only in here.
 *
 *  2017-02-15 Scott Lawrence
 */

#include <stdio.h>
#include <unistd.h>             /* for usleep */
#include <sys/time.h>           /* for timeval */
#include "mc6850_console.h"     /* port bit definitions */

#ifdef MC6850_SOCKET
	#define SOCKS
#else
	#undef SOCKS
#endif

#ifdef SOCKS
#include <fcntl.h>
#include <stdlib.h>
#include <strings.h>
#include <poll.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>

#define kPortNo (6850)


typedef struct Sock {
	int ok;
	int sockfd;
	int newsockfd;
	int portno;
	int clilen;
	char buffer[ 256 ];
	struct sockaddr_in serv_addr;
	struct sockaddr_in cli_addr;
	struct timeval timeout;
	int nbytesvalid;
	int bufsendpos;
} Sock ;

struct Sock sock;

void Socks_error(char *msg)
{
    perror(msg);
    exit(1);
}


void Socks_Init()
{
	sock.ok = 0;

	sock.nbytesvalid = 0;
	sock.bufsendpos = 0;

	// create the socket
	sock.sockfd = sock.newsockfd = sock.clilen = 0;
	sock.portno = kPortNo;
	sock.sockfd = socket(AF_INET, SOCK_STREAM, 0);
	if (sock.sockfd < 0) Socks_error("ERROR opening socket");


	// setup stuff
	bzero((char *) &sock.serv_addr, sizeof(sock.serv_addr));
	sock.serv_addr.sin_family = AF_INET;
	sock.serv_addr.sin_addr.s_addr = INADDR_ANY;
	sock.serv_addr.sin_port = htons(sock.portno);


	// bind it
	int tries = 0;

	while( tries < 15 && !sock.ok ) {
		if (bind(	sock.sockfd,
				(struct sockaddr *) &sock.serv_addr,
				sizeof(sock.serv_addr)) < 0) 
		{
			printf( "Couldn't open port %d\n", sock.portno );
			tries++;
			sock.portno++;
			sock.serv_addr.sin_port = htons(sock.portno);
		} else {
			sock.ok = 1;
		}
	}

	if( !sock.ok ) {
		Socks_error("ERROR on binding");
	}

	printf( "Server started on port %d\n", sock.portno );
	printf( "Waiting for connection...\n" );

	listen(sock.sockfd,5);
	sock.clilen = sizeof(sock.cli_addr);

	// this will block on waiting...
	sock.newsockfd = accept( sock.sockfd,
						(struct sockaddr *) &sock.cli_addr,
						&sock.clilen );

	if (sock.newsockfd < 0) {
		Socks_error("ERROR on accept");
	}
	
	// we want to timeout as quick as we can on this
	// so we will not block the main code.
    sock.timeout.tv_sec = 0;
    sock.timeout.tv_usec = 1;

    if( setsockopt(	sock.newsockfd, 
					SOL_SOCKET,
					SO_RCVTIMEO,
					(char *)&sock.timeout,
					sizeof(sock.timeout) ) < 0)
        Socks_error( "setsockopt failed\n" );

    if( setsockopt(	sock.newsockfd,
					SOL_SOCKET,
					SO_SNDTIMEO,
					(char *)&sock.timeout,
					sizeof(sock.timeout) ) < 0)
        Socks_error( "setsockopt failed\n" );

	// We're ready!!!
	printf( "Remote Connected.\n" );

/*
	while( 1 ) {
		bzero(sock.buffer,256);
		n = read( sock.newsockfd, sock.buffer, 255);
		if( n > 0 ) {

			printf("Here is the message: %s\n",sock.buffer);
			n = write(sock.newsockfd,"I got your message",18);

			if (n < 0) {
				Socks_error("ERROR writing to socket");
			}
		}
	}
*/
}


void Socks_Send( byte data )
{
	int n;
	byte buf[2];

	if( !sock.ok ) return;

	buf[0] = data;
	buf[1] = '\0';

	n = write( sock.newsockfd, buf, 1);

	if (n < 0) {
		printf( "ERROR writing to socket\n" );
	}
}


void Socks_SendString( char * str )
{
	int n=0;
	if( !sock.ok ) return;

	n = write( sock.newsockfd, str, strlen( str ));
}


int Socks_Available()
{
	if( !sock.ok ) return 0;

	// if there's already content, send it.
	if( sock.nbytesvalid > 0 ) { 
		return 1;
	}

	// let's try to read another buffer
	bzero(sock.buffer,256);
	sock.nbytesvalid = read( sock.newsockfd, sock.buffer, 255);
	if( sock.nbytesvalid < 0 ) { 
		sock.nbytesvalid = 0;
	}
	sock.bufsendpos = 0;

	if( sock.nbytesvalid > 0 ) { 
		return 1;
	}
	return 0;
}

byte Socks_Filter( byte ch )
{
	if( ch == 0x03 ) {
		printf( "[BREAK]\n" );
		Socks_SendString( "[BREAK]\n" );
	}
	return ch;

}

byte Socks_GetByte()
{
	byte ret = 0;

	if( !sock.ok ) return ret;

	// if there's nothing to send, send nothing
	if( sock.nbytesvalid < 1 ) {
		return ret;
	}
	
	// get the next byte from our buffer.
	ret = sock.buffer[ sock.bufsendpos ];

	// increment the buffer position
	// and clear the indexes if we've exhausted the buffer
	sock.bufsendpos++;
	if( sock.bufsendpos >= sock.nbytesvalid ) {
		sock.nbytesvalid = 0;
		sock.bufsendpos = 0;
	}

	ret = Socks_Filter( ret );

	return ret;
}

#endif

/* initialization stuff */
void Host_Init( z80info * z80 )
{
#ifdef SOCKS
	Socks_Init();
#endif
}

/* send a byte of data to the actual console */
void Host_PutChar( byte data )
{
	// write to the screen 
    putchar( (int) data );
    fflush( stdout );

#ifdef SOCKS
	Socks_Send( data );
#endif
}

/* is a key available on the keyboard? */
int Host_KeyHit( void )
{
#ifdef SOCKS
	if( Socks_Available() ) return 1;
#endif
    return( z_kbhit() );
}

/* Get a key if it's available */
byte Host_GetChar( byte defaultVal )
{
#ifdef SOCKS
    /* get in a byte from the socket */
	if( Socks_Available() ) {
		return Socks_GetByte();
	}
#endif

    /* get in a byte from the console */
    if( Host_KeyHit() ) {
		return getchar();
    }
    return defaultVal;
}

/* utility function to get the number of milliseconds since we started */
long long Host_Millis( void )
{
    struct timeval te;
    long long milliseconds;

    static long long startTime = 0;

    /* get current time */
    gettimeofday(&te, NULL);

    /* adjust the start time */
    if( startTime == 0 ) {
        /* calculate milliseconds */
        startTime = te.tv_sec*1000LL + te.tv_usec/1000;
    }

    /* calculate milliseconds */
    milliseconds = te.tv_sec*1000LL + te.tv_usec/1000;

    return milliseconds;
}
