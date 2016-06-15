; Lloader
;          Core Rom Loader for RC2014-LL
;
;          2016-05-09 Scott Lawrence
;
;  This code is free for any use. MIT License, etc.
;
; this ROM loader isn't meant to be the end-all, be-all, 
; it's just something that can easily fit into the 
; boot ROM, that can be used to kick off another, better
; ROM image.

	.module Lloader

.area	.CODE (ABS)

.include "../Common/hardware.asm"	; hardware definitions

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; initial entry point

; RST 00 - Cold Boot
.org 0x0000			; start at 0x0000
	di			; disable interrupts
	jp	coldboot	; and do the stuff

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; RST 08 - println( "\r\n" );
.org 0x0008 	; send out a newline
	ld	hl, #str_crlf	; set up the newline string
	jr	termout		

str_crlf:
	.byte 	0x0d, 0x0a, 0x00	; "\r\n"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; RST 10 - println( (hl) );
.org 0x0010
; termout
;  hl should point to an 0x00 terminated string
;  this will send the string out through the ACIA
termout:
	push	af
to_loop:
	ld	a, (hl)		; get the next character
	cp	#0x00		; is it a NULL?
	jr	z, termz	; if yes, we're done here.
	out	(TermData), a	; send it out.
	inc	hl		; go to the next character
	jr	to_loop		; do it again!
termz:
	pop	af
	ret			; we're done, return!

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; RST 20 - send out string to SD drive
.org 0x0020
sdout:
	push	af
	ld	a, (hl)		; get the next character
	cp	#0x00		; is it a null?
	jr	z, sdz		; if yes, we're done
	out	(SDData), a	; send it out
	inc	hl		; next character
	jr	sdout		; do it again
sdz:
	pop	af
	ret			; we're done, return!

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; RST 28 - unused
.org 0x0028

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; RST 30 - unused
.org 0x0030
	ret
.byte	0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; RST 38 - Interrupt handler for console input
.org 0x0038
    	reti


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; memory maps of possible hardware...
;  addr   	SBC	2014	LL
; E000 - FFFF 	RAM	RAM	RAM
; C000 - DFFF	RAM	RAM	RAM
; A000 - BFFF	RAM	RAM	RAM
; 8000 - 9FFF	RAM	RAM	RAM
; 6000 - 7FFF	RAM		RAM
; 4000 - 5FFF	RAM		RAM
; 2000 - 3FFF	ROM	ROM	RAOM
; 0000 - 1FFF	ROM	ROM	RAOM

STACK 	= 0xF800

USERRAM = 0xF802
LASTADDR = USERRAM + 1

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; coldboot - the main code block
.org 0x100
coldboot:
	;;;;;;;;;;;;;;;;;;;;	
	; 1. setup 
	ld	a, #0x00	; bit 0, 0x01 is ROM Disable
				; = 0x00 -> ROM is enabled
				; = 0x01 -> ROM is disabled
	out	(RomDisable), a	; restore ROM to be enabled

	;;;;;;;;;;;;;;;;;;;;	
	; 2. setup stack for lloader
	ld	sp, #STACK	; setup a stack pointer valid for all

	
	;;;;;;;;;;;;;;;;;;;;	
	; setup misc variables
	call	ExaInit


	;;;;;;;;;;;;;;;;;;;;	
	; 3. display splash text
	rst	#0x08		; newline
	ld	hl, #str_splash
	rst	#0x10		; print to terminal


	;;;;;;;;;;;;;;;;;;;;	
	; 4. display utility menu, get command
main:
	ld	hl, #str_menu
	rst	#0x10		; print to terminal

prompt:
	ld	hl, #str_prompt
	rst	#0x10		; print with newline

ploop:
	in	a, (TermStatus)	; ready to read a byte?
	and	#DataReady	; see if a byte is available

	jr	z, ploop	; nope. try again

	xor	a
	ld	e, a		; clear the autostart flag

	ld	bc, #0x0000	; reset our timeout

	; handle the passed in byte...

	in	a, (TermData)	; read byte
	out	(TermData), a	; echo

	push	af
	rst	#0x08		; print nl
	pop	af

		; General commands
	cp	#'?		; '?' - help
	jp 	z, ShowHelp

	and	#0xDF		; make uppercase (mostly)

	cp	#'Q		; 'Q' - quit the emulator
	jp	z, Quit

	cp	#'S		; 'S' - sysinfo
	jp 	z, ShowSysInfo


		; memory, I/O

	cp	#'E		; examine memory (hex dump)
	jp	z, ExaMem

	cp	#'P
	jp	z, PokeMemory


	cp	#'I
	jp	z, InPort

	cp	#'O
	jp	z, OutPort

		; ROM operations

	cp	#'7		; temp for now
	jp	z, CopyROMToRAM

	cp	#'8
	jp	z, DisableROM

	cp	#'9
	jp	z, EnableROM

		; test operations

	cp	#'c		; 'c' - cat file
	jp	z, catFile

		; boot operations

	cp	#'B		; 'B' - Boot.
	jp 	z, DoBoot

	cp	#'0		; '0' - basic32.rom
	jp	z, DoBootBasic56

	cp	#'1		; '1' - basic56.rom
	jp	z, DoBootBasic56

	cp	#'2		; '2' - iotest.rom
	jp	z, DoBootIotest

	jr	prompt		; ask again...
	

	;;;;;;;;;;;;;;;
	; quit from the rom (halt)
Quit:
	ld	a, #0xF0	; F0 = flag to exit
	out	(EmulatorControl), a
	halt			; rc2014sim will exit on a halt

	;;;;;;;;;;;;;;;
	; show help subroutine
ShowHelp:
	ld	hl, #str_help
	rst	#0x10
	jr 	prompt

	;;;;;;;;;;;;;;;
	; show sysinfo subroutine
ShowSysInfo:
	ld	hl, #str_splash
	rst	#0x10

	call	ShowMemoryMap	; show the memory map
	ret


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; CopyROMToRAM
;	copies $0000 thru $2000 to itself
;	seems like it would do nothing but it's reading from 
;	the ROM and writing to the RAM
;	Not sure if this is useful, but it's a good test.
CopyROMToRAM:
	xor	a
	ld	h, a
	ld	l, a	; HL = $0000
CR2Ra:
	ld	a, (hl)
	ld	(hl), a	; RAM[ hl ] = ROM[ hl ]

	inc	hl	; hl++
	ld	a, h	; a = h
	cp	#0x20	; is HL == 0x20 0x00?
	jr	nz, CR2Ra

	; now patch the RAM image of the ROM so if we reset, it will
	; continue to be in RAM mode...
	ld	hl, #coldboot	; 0x3E  (ld a,      )
	inc	hl		; 0x00	(    , #0x00)
	ld	a, #0x01	; disable RAM value
	ld	(hl), a		; change the opcode to  "ld a, #0x01"
	
	; we're done. return
	jp	prompt


; DisableROM
;	set the ROM disable flag
DisableROM:
	ld	a, #01
	out	(RomDisable), a
	jp	prompt


; EnableROM
;	clear the ROM disable flag
EnableROM:
	xor	a
	out	(RomDisable), a
	jp	prompt


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	;;;;;;;;;;;;;;;
	; boot roms
DoBootBasic32:
	ld	hl, #cmd_bootBasic32
	jr	DoBootB	

DoBootBasic56:
	ld	hl, #cmd_bootBasic56
	jr	DoBootB	

DoBootIotest:
	ld	hl, #cmd_bootIotest
	jr	DoBootB	

	;;;;;;;;;;;;;;;;;;;;	
	; 4. send the file request
DoBoot:
	ld	hl, #cmd_bootfile
DoBootB:
	rst	#0x20		; send to SD command
	ld	hl, #cmd_bootread
	rst	#0x20		; send to SD command


	;;;;;;;;;;;;;;;;;;;;	
	; 5. read the file to 0000
	ld 	hl, #0x0000	; Load it to 0x0000

	in	a, (SDStatus)
	and	#DataReady
	jr	nz, bootloop	; make sure we have something loaded
	ld	hl, #str_nofile	; print out an error message
	rst	#0x10
	jp	prompt		; and prompt again
	

bootloop:
	in	a, (SDStatus)
	and	#DataReady	; more bytes to read?
	jp	z, LoadDone	; nope. exit out
	
	in	a, (SDData)	; get the file data byte
	ld	(hl), a		; store it out
	inc	hl		; next position
	
	; uncomment if you want dots printed while it loads...
	  ld	a, #0x2e	; '.'
	  out	(TermData), a	; send it out.

	jp	bootloop	; and do the next byte


	;;;;;;;;;;;;;;;;;;;;
	; 6. Loading is completed.
LoadDone:
	ld	hl, #str_loaded
	rst	#0x10

	;;;;;;;;;;;;;;;;;;;;
	; 7. Swap the ROM out
	jp	SwitchInRamRom


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
str_hello:
	.asciz 	"~Ftest.txt\n"

catFile:
	ld	hl, #str_hello	; select file
	rst	#0x20		; send to SD command
	ld	hl, #cmd_bootread ; open for read
	rst	#0x20		; send to SD command

CF0:
	; check for more bytes
	in	a, (SDStatus)
	and	#DataReady	; more bytes to read?
	jp	z, prompt	; nope. exit out
	
	; load a byte from the file, print it out
	in	a, (SDData)	; get the file data byte
	out	(TermData), a	; send it out.
	;ld	(hl), a		; store it out
	inc	hl		; next position
	jr	CF0		; repeat
	

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Text strings

; Version history
;   v004 2016-06-11 - Hex dump of memory, in, out, poke
;   v003            - more options
;   v002 2016-05-10 - usability cleanups
;   v001 2016-05-09 - initial version, functional

str_splash:
	.ascii	"Boot Lloader/Utilities for RC2014-LL\r\n"
	.ascii	"  v004 2016-June-10  Scott Lawrence\r\n"
	.asciz  "\r\n"

str_prompt:
	.asciz  "\r\nLL> "

str_menu:
	.asciz  "[?] for help\r\n"

str_help:
	.ascii  "==== General ====\r\n"
	.ascii  "  ? for help\r\n"
	.ascii	"  Q to quit emulator\r\n"
	.ascii	"  S for system info\r\n"
	.ascii	"\r\n"
	.ascii  "==== Mem, IO ====\r\n"
	.ascii  "  E to examine memory\r\n"
	.ascii  "  P to poke memory\r\n"
	.ascii  "  I to read in from a port\r\n"
	.ascii  "  O to write out to a port\r\n"
	.ascii	"\r\n"
	.ascii  "==== Boot ====\r\n"
	.ascii	"  0 for basic32.rom\r\n"
	.ascii	"  1 for basic56.rom\r\n"
	.ascii	"\r\n"
	.ascii  "==== ROM ====\r\n"
	.ascii	"  7 Copy ROM to RAM\r\n"
	.ascii	"  8 Disable ROM (64k RAM)\r\n"
	.ascii	"  9 Enable ROM (56k RAM)\r\n"

	;ascii  "  C for catalog\r\n"
	;ascii  "  H for hexdump\r\n"
	;ascii  "  0-9 for 0.rom, 9.rom\r\n"
	.byte 	0x00



cmd_bootfile:
	.asciz	"~FROMs/boot.rom\n"

cmd_bootBasic32:
	.asciz	"~FROMs/basic.32.rom\n"

cmd_bootBasic56:
	.asciz	"~FROMs/basic.56.rom\n"

cmd_bootIotest:
	.asciz	"~FROMs/iotest.rom\n"

cmd_bootread:
	.asciz	"~R\n"

cmd_bootsave:
	.asciz	"~S\n"

str_loading:
	.ascii 	"Loading \"boot.rom\" from SD...\r\n"
	.asciz	"Storing at $0000 + $4000\r\n"

str_loaded:
	.asciz 	"Done loading. Restarting...\n\r"

str_nofile:
	.asciz	"Couldn't load specified rom.\n\r"


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.include "memprobe.asm"
.include "examine.asm"
.include "poke.asm"
.include "ports.asm"
.include "input.asm"
.include "print.asm"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; utility includes

.include "../Common/banks.asm"
