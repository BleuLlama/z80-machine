
----------------
MicroLlama 5000
2016-07-15
Scott Lawrence
yorgle@gmail.com
----------------

This is the default SD contents for the RC2014/LL (MicroLlama 5000).

It contains some files:

readme.txt
	This file, contains this information you're reading now.

test.txt
	Just a test file for the ROM test routine in Lloader.


There are also a few directories that contain content:

BASIC/
	.BAS text files containing program listings

ROMs/
	.HEX/.IHX and .ROM files containing program data
	.HEX/.IHX contain their own location information
	.ROM are loaded at $0000

future:

SFDI/
    SFDI/A	Disk A sector file disk image contents
    SFDI/B	Disk C sector file disk image contents
    SFDI/C	Disk D sector file disk image contents
    ...

