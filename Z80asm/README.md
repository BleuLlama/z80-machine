# Z80 asm

This directory contains a bunch of native z80 code projects
which are to be run on built platforms.

Some of these directories only contain Intel Hex files (.ihx, .hex)
which can be built into ROMs using 'genroms'


Notes:
- BASIC versions are copied directly from Grant Searle's Z80 SBC project
- Modifications for use in Spencer Owen's RC2014 project
- Some sample ROMS are also here that do the bank switching for the LL project


The assembler used is "asz80" from the zcc package, which is available
in source form from my repository of Z80 dev tools available here:

    https://code.google.com/archive/p/bleu-romtools/

Also there is a required tool called "genroms" which converts Intel
hex files (IHX, HEX) to binary ROM files.
