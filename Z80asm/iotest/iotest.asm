; IO tester for RC2014
; 

	.module SIO_TEST
.area	.CODE (ABS)

.include "../Common/hardware.asm"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; initial entry point
.org 0x0000			; start at 0x0000
	di			; disable interrupts
	ld	sp, #0x4000	; set up a stack pointer
	jp	main		; let's get started!

str_splash:
	.ascii	"ACIA Tester - 2016 Scott Lawrence\r\n"
	.ascii	"  Press 'H' to halt\r\n"
	.ascii  "  Press 'R' for ROM\r\n"
	.byte	0x00

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; main - the main code block
main:
	; send out splash text 
	call	seroutNL	; add newline
	call	seroutNL	; add newline
	ld	hl, #str_splash
	call	serout
	call	seroutNL	; add newline


; loop - our IN/OUT echoer
loop:
	; read in a byte, if we can...
	in	a, (TermStatus) ; check the status on the ACIA
	and	#DataReady	; See if there's a byte available
	jp	z, loop		; if not, try again

	; okay, we have something, let's do something with it!
	in	a, (TermData)	; get data from the ACIA

	; 0x48 = 'H' - halt (to quit the emulation)
	cp	#0x48		; 'H' to halt
	jp	z,cmd_halt	; yep.  halt the cpu...

	; 0x52 = 'R' - switch to ROM
	cp	#0x52		; 'R' for rom
	jp	z,BankSwitchToRom ; yep. bankswitch!

	; 0x0d = [return] convert to CRLF
	cp	#0x0d		; remap 0x0d to 0x0a/0x0d
	jp	z, loopnl

	; echo it back out, and do it again

	push	af		; stash it aside
	ld	a,#0x5b		; send '['
	out	(TermData), a	; send out to the ACIA
	pop	af		; get it back
	out	(TermData), a	; send out to the ACIA
	ld	a,#0x5d		; send ']'
	out	(TermData), a	; send out to the ACIA

	jp	loop		; then do it all again

; for the ret-CRLF code, output CRLF.
loopnl:
	call	seroutNL		; send out the newline
	jp	loop

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

cmd_halt:
	halt			; rc2014sim will exit on a halt

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

str_crlf:
	.byte 	0x0d, 0x0a, 0x00	; "\r\n"

; send out a newline
seroutNL:
	ld	hl, #str_crlf	; send out the newline string

	; fall through....

; serout
;  hl should point to an 0x00 terminated string
;  this will send the string out through the ACIA
serout:
	ld	a, (hl)		; get the next character
	cp	#0x00		; is it a NULL?
	jr	z, donez	; if yes, we're done here.
	out	(TermData), a	; send it out.
	inc	hl		; go to the next character
	jr	serout		; do it again!
donez:
	ret			; we're done, return!

.include "../Common/banks.asm"
