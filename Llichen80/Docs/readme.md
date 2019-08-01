

Files in this directory:

- RC2014 Memory Map.pdf

This shows the memory maps of various versions of the RC2014:
1. "RC2014LL Power On" - when the RC2014LL powers on, this is 
   the state.  It has 64 k of RAM, all writable, but reads from the 
   lowest 8 k come from the ROM.
2. "RC2014LL ROM DIS" - ROM Disabled, so read/write both come from RAM
3. "Standard RC2014" - Standard configuration of a 32k RC2014
4. "Standard 56k SBC" - Grant Searle's 56k RAM version

- RC2014 SD Memory Dump With Notes.pdf

Spencer's SD Memory Dump card schematic with my notes, to help
  figure out what all of the switches and jumpers do.

- RC2014 Serial on C0.pdf

A modification of the standard serial IO card that makes the 
  serial port on the Z80 side switchable between $80 and $C0

- RC2014 Switchable ROM.pdf

The main changes for the "LL" system. This lets the ROM be switched
out and the RAM switched in for a full 64kbyte system
