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
	ld	a, (hl)		; get the next character
	cp	#0x00		; is it a NULL?
	jr	z, termz	; if yes, we're done here.
	out	(TermData), a	; send it out.
	inc	hl		; go to the next character
	jr	termout		; do it again!
termz:
	ret			; we're done, return!

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; RST 20 - send out string to SD drive
.org 0x0020
sdout:
	ld	a, (hl)		; get the next character
	cp	#0x00		; is it a null?
	jr	z, sdz		; if yes, we're done
	out	(SDData), a	; send it out
	inc	hl		; next character
	jr	sdout		; do it again
sdz:
	ret			; we're done, return!

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; RST 28 - unused
.org 0x0028

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; RST 30 - unused
.org 0x0030

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; RST 38 - unused
.org 0x0038

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; coldboot - the main code block
.org 0x100
coldboot:
	;;;;;;;;;;;;;;;;;;;;	
	; 1. setup banks for cold boot
				;        vv------------ $c000
				;        || vv--------- $8000
				;        || || vv------ $4000
				;        || || || vv--- $0000
	ld	a, #0x24	; banks: 00 02 01 00
				;        || || || ^^--- ignored
				;        || ^^-^^------ RAM banks
				;        ^^------------ ROM in bank 00
	out	(BankConfig), a	; restore banks to their setup configuration

	;;;;;;;;;;;;;;;;;;;;	
	; 2. setup stack for lloader
	ld	sp, #0x3FFF	; set up a stack pointer (top of bank 1)

	;;;;;;;;;;;;;;;;;;;;	
	; 3. display splash text
	rst	#0x08
	ld	hl, #str_splash
	rst	#0x10		; print to terminal


	;;;;;;;;;;;;;;;;;;;;	
	; 4. display utility menu, get command
main:
	ld	hl, #str_menu
	rst	#0x10		; print to terminal

	ld	bc, #0x0000
	ld	e, #0x01	; enable autostart

	; display the prompt
prompt:
	ld	hl, #str_prompt
	rst	#0x10		; print with newline
ploop:
	; check for autoboot/timeout
	ld	a, e		; if E is clear, we skip auto
	cp	#0x00
	jr	z, SkipAuto
	inc	bc
	ld	a, b		; check for timeout...
	cp	#0xF0		; 0xF000 ?
	jp	z, Autoboot

SkipAuto:
	in	a, (TermStatus)	; ready to read a byte?
	and	#DataReady	; see if a byte is available

	jr	z, ploop	; nope. try again

	xor	a
	ld	e, a		; clear the autostart flag

	rst	#0x08		; print nl
	ld	bc, #0x0000	; reset our timeout

	; handle the passed in byte...

	in	a, (TermData)	; read byte
	cp	#0x3f		; '?' - help
	jr 	z, ShowHelp

	cp	#0x42		; 'B' - Boot.
	jr 	z, DoBoot

	cp	#0x53		; 'S' - sysinfo
	jr 	z, ShowSysInfo

	cp	#0x48		; 'H' - halt and exit
	jr	z, exit


	cp	#0x30		; '0' - basic32.rom
	jr	z, DoBootBasic32

	cp	#0x31		; '1' - basic56.rom
	jr	z, DoBootBasic56

	cp	#0x32		; '2' - iotest.rom
	jr	z, DoBootIotest

	jr	prompt		; ask again...
	
	;;;;;;;;;;;;;;;
	; exit from the rom (halt)
exit:
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
	jr	prompt

	;;;;;;;;;;;;;;;
	; autoboot. (load the default ROM after timeout)
Autoboot:
	ld	hl, #str_idletxt
	rst	#0x10
	jr 	DoBoot

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
	; 5. read the file to C000
	ld 	hl, #CopyRemap0	; 0x0000 is remapped to 0xC000 as per bank

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
	;ld	a, #0x2e	; '.'
	;ut	(TermData), a	; send it out.

	jp	bootloop	; and do the next byte


	;;;;;;;;;;;;;;;;;;;;
	; 6. Loading is completed.
LoadDone:
	ld	hl, #str_loaded
	rst	#0x10


	;;;;;;;;;;;;;;;;;;;;
	; 7. Bankswitch to the new bank
	;	the problem is that we need to bank switch,
	; 	but once we do, this rom goes away.
	;	so we need to pre-can some content
	jp	BankSwitchToC000	; and swap the bank into place
	

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Text strings

; Version history
;   v002 2016-05-10 - usability cleanups
;   v001 2016-05-09 - initial version, functional

str_splash:
	.ascii	"Boot Lloader/Utilities for RC2014-LL\r\n"
	.ascii	"  v002 2016-May-10  Scott Lawrence\r\n"
	.asciz  "\r\n"

str_prompt:
	.asciz  "LL> "

str_menu:
	.asciz  "[?] for help, or wait for autoboot...\r\n"

str_help:
	.ascii  "  ? for help\r\n"
	.ascii  "  B for boot.rom (wait for autoboot)\r\n"
	.ascii	"  H to halt\r\n"
	.ascii	"  S for system info\r\n"
	.ascii	"\r\n"
	.ascii	"  0 for basic32.rom\r\n"
	.ascii	"  1 for basic56.rom\r\n"
	.ascii	"  2 for iotest.rom\r\n"

	;ascii  "  C for catalog\r\n"
	;ascii  "  H for hexdump\r\n"
	;ascii  "  0-9 for 0.rom, 9.rom\r\n"
	.byte 	0x00


cmd_bootfile:
	.asciz	"~FROMs/boot.rom\n"

cmd_bootBasic32:
	.asciz	"~FROMs/basic32.rom\n"

cmd_bootBasic56:
	.asciz	"~FROMs/basic56.rom\n"

cmd_bootIotest:
	.asciz	"~FROMs/iotest.rom\n"

cmd_bootread:
	.asciz	"~R\n"

cmd_bootsave:
	.asciz	"~S\n"

str_idletxt:
	.asciz  "\r\nNo input detected, autobooting..\r\n"

str_loading:
	.ascii 	"Loading \"boot.rom\" from SD...\r\n"
	.asciz	"Storing at $0000 + $4000\r\n"

str_loaded:
	.asciz 	"Done loading. Restarting...\n\r"

str_nofile:
	.asciz	"Couldn't load specified rom.\n\r"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; utility includes

.include "../Common/banks.asm"
