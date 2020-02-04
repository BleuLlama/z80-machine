# Overview


These basic programs are made specifically for the default RC2014
BASIC (NASCOM BASIC).  I've provided them here so that you can test
out your TMS9918A card's functionality.

Please feel free to do whatever you'd like with these. :D

These use jblang's video card, documented here:

    https://github.com/jblang/TMS9918A


# Programs

The basic programs can just be pasted into your term window to 
enter them into the RC2014.  To give an idea about what the output
should look like for each of these, there's some screengrabs from
the output of my TMS9918A in th images folder. 

For example, the output from "01_garbage_cycling.bas" may look
like the images in the images folder with names like "01_xxxx.jpg"


# Board Configuration

These examples are written with the TMS board configured like a
"SORD M5".  The jumper settings for this are as follows:

Locations:

      ________________________________________
     / JP1  JP2                 J4            |
    /                                     JP4 |
    | J6                                      |
    |                     J7                  |
    |                                         |
    |                                         |
    |                                         |
    |                                         |
    ------------------------------------------
     ||||||||||||||||||||||||||||||||||||||||
     1                                      40

- J7 is not used, as it is the clock signal header.


## SORD M5

For these, I have the board configured for SORD M5, with the
card at addresses 10 and 11. (0x16, 0x17).  Here are the
pin configurations: ("#" indicates the position of the jumper,
while "." or ":" indicates open pins.

    JP1  JP2  J6       J4     JP4
     .    .                    .
     #    #   ::#   #:::::::   #
     #    #         02468ACE   #

Configured as 0x10, 0x11

- JP1 (bit 1,2) lower - ignore bits 1 and 2
- JP2 (bit 3) lower - ignore bit 3
- J6 (bit 4) right - upper half of port range of J4 (10-1F)
- J4 (bits 7-5) - Port range 00-1F
- JP4 (interrupt) lower - NMI


## ColecoVision

We're not using ColecoVision configuration, but here it is
anyway, for completeness-sake...

    JP1  JP2  J6       J4     JP4
     .    .                    .
     #    #   ::#   :::::#::   #
     #    #         02468ACE   #

Configured as 0xBE, 0xBF

- JP1 (bit 1,2) lower - ignore bits 1 and 2
- JP2 (bit 3) lower - ignore bit 3
- J6 (bit 4) right - upper half of port range of J4 (B0-BF)
- (?)J6 (bit 4) left - ignore range
- J4 (bits 7-5) - Port range A0-BF
- JP4 (interrupt) lower - NMI


## MSX

    JP1  JP2  J6       J4     JP4
     #    #                    #
     #    #   ::#   ::::#:::   #
     .    .         02468ACE   .

Configured as 0x98, 0x99

- JP1 (bit 1,2) upper
- JP2 (bit 3) upper
- J6 (bit 4) right - upper half of port range of J4 (B0-BF)
- J4 (bits 7-5) - Port range A0-BF
- JP4 (interrupt) upper - INT
