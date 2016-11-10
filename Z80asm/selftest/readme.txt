
SelfTest
v1.00
2016-11-10
Scott Lawrence
yorgle@gmail.com

This is meant to be a diagnostic tool to help track down issues
with an RC2014 computer.  Mainly my own. ;)

It has been built specifically so that it does not use or require
RAM at all. This made the program a bit larger than I'd like, since
I couldn't use any subroutines to modularize the code at all, but
it can be used to diagnose problems on computers with faulty RAM.

All tests require functional:
- Clock (check with an oscilloscope)
- CPU
- ROM (with this programmed into it, and selected via jumpers)

And for output:
- Digital IO, or Digital Output module at port 0x00
- Serial module for text output, serial tests

In the tests, "output" means "write to port 0x00"
In the tests, "print" means "send through the 6850 serial console"
In the tests, "get" means "get a byte from the 6850 serial console"
In the tests, "write" means "write to RAM/ROM"
In the tests, "read" means "read from RAM/ROM"

Tests:

1. Digital Output
	Tests writing output to the Digital Output or Digital IO
	module.  Note that these will happen too quickly on regular
	testing, but if you have a manual clock, you should be able
	to see them being displayed.

	A. Output 0xAA
	B. Output 0x55
	C. Output 0xFF
	D. Output 0x82	(completion code)

2. Serial Output
	This will do an unthrottled output of a text string through
	the serial module.

	A. Print out a text string with CR/LF
	B. Output 0x84	(completion code)

	It should look like this:

		This is test ACIA unthrottled output.

	

3. RAM
	This test will write and read to bytes across memory space
	in 0x2000 byte increments.  It will use one byte at 0x0000,
	one byte at 0x2000, and so on up through 0xE0000:
	0x0000, 0x2000, 0x4000, 0x6000,0x8000, 0xA000, 0xC000, 0xE000

	A. Write out 0x00 (to each of the 8 bytes as above)
	B. Output 0x86	(completion code)
	C. Write out 0x55
	D. Output 0x88	(completion code)
 	E. Prep for RAM/ROM test:
	    1. Write out 0x0F to 0x0000
	    2. Write out 0x0E to 0x2000
	    3. Write out 0x0D to 0x4000
	    4. Write out 0x0C to 0x6000
	    5. Write out 0x0B to 0x8000
	    6. Write out 0x0A to 0xA000
	    7. Write out 0x09 to 0xC000
	    8. Write out 0x08 to 0xE000
	F. Print out test header 
        G. Read bytes and print results
	    1. Read from 0x0000, check that it's 0x0F, print result
	    2. Read from 0x2000, check that it's 0x0E, print result
	    3. Read from 0x4000, check that it's 0x0D, print result
	    4. Read from 0x6000, check that it's 0x0C, print result
	    5. Read from 0x8000, check that it's 0x0B, print result
	    6. Read from 0xA000, check that it's 0x0A, print result
	    7. Read from 0xC000, check that it's 0x09, print result
	    8. Read from 0xE000, check that it's 0x08, print result
	D. Output 0x8A	(completion code)

	It should look like this for standard RC2014:

	    02468ACE  * 0x1000  (A = RAM, O = ROM)
	    OOOOAAAA

4. Serial Read (Echo)
	This test will check for serial input, by echoing back
	every byte sent in.  If the byte is a CR or LF, then 
	a CRLF will be returned.  This test will repeat forever.

	A. Get the status byte from the 6850
	B. If a byte is available, get it
	C. If it's a CR or LF output CRLF
	D. Output it to the digital output/IO module
	E. Print it back out to the terminal
	F. Repeat forever...



