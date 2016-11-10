; SelfTest
;  yorgle@gmail.com
;
;  v001 - 2016-11-09  initial version

; 	- Diagnose systems without RAM accessing
;	- Requires that the following modules partially working:
;	  - Clock
;	  - CPU
;	  - ROM
;	  - Digital IO
;	  - Serial

; NOTE: This does NOT use any RAM at all.  So there are intentionally
;	no subroutines, no stack things, nothing like that.

.include "../Common/hardware.asm"


; additional defines
Emulation = 1


LF 	= 0x0a
CR	= 0x0D
NUL	= 0x00

	.module SELFTEST
.area	.CODE (ABS)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; initial entry point
.org 0x0000			; start at 0x0000

boot:
	di			; disable interrupts
	jp	digOutTest


.org 0x0100
; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; 
; Digital Out test
;	send out AA, 55, FF

digOutTest:
	; test some outs to digital IO
	ld	a, #0xAA
	and	#0xFE		; mask off bank switch bit
	out	(DigitalIO), a

	ld	a, #0x55
	and	#0xFE		; mask off bank switch bit
	out	(DigitalIO), a

	ld	a, #0xFF
	and	#0xFE		; mask off bank switch bit
	out	(DigitalIO), a

	jr	ramTest

; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; 
; ramTest
;	probe memory to find out where ram is

ramTest:
	ld	de, #0x0000	; result goes into d.


	; write 00 out 
	ld	a, #0x00
	ld	hl, #0x0000
	ld	bc, #0x2000
	ld	(hl), a		; 0x0000
	add	hl, bc
	ld	(hl), a		; 0x2000
	add	hl, bc
	ld	(hl), a		; 0x4000
	add	hl, bc
	ld	(hl), a		; 0x6000
	add	hl, bc
	ld	(hl), a		; 0x8000
	add	hl, bc
	ld	(hl), a		; 0xA000
	add	hl, bc
	ld	(hl), a		; 0xC000
	add	hl, bc
	ld	(hl), a		; 0xE000

	; write 55 out
	ld	a, #0x55
	ld	hl, #0x0000
	ld	(hl), a		; 0x0000
	add	hl, bc
	ld	(hl), a		; 0x2000
	add	hl, bc
	ld	(hl), a		; 0x4000
	add	hl, bc
	ld	(hl), a		; 0x6000
	add	hl, bc
	ld	(hl), a		; 0x8000
	add	hl, bc
	ld	(hl), a		; 0xA000
	add	hl, bc
	ld	(hl), a		; 0xC000
	add	hl, bc
	ld	(hl), a		; 0xE000

	; write AA out
	ld	a, #0xAA
	ld	hl, #0x0000
	ld	(hl), a		; 0x0000
	add	hl, bc
	ld	(hl), a		; 0x2000
	add	hl, bc
	ld	(hl), a		; 0x4000
	add	hl, bc
	ld	(hl), a		; 0x6000
	add	hl, bc
	ld	(hl), a		; 0x8000
	add	hl, bc
	ld	(hl), a		; 0xA000
	add	hl, bc
	ld	(hl), a		; 0xC000
	add	hl, bc
	ld	(hl), a		; 0xE000

	; We should assume that 0x0000 is ROM.

ramResult:
	ld	a, d
	and	#0xFE
	out	(DigitalIO), a
	; ram is '1's 	2468 ACE0
	; eg. stock     0000 1111
	; messed up 	0000 0100
	jr	serialTest


; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; 
; serialTest
;	output some stuff through the ACIA
;
serialTest:
	ld	hl, #sText

_s01:
	ld	a, (hl)
	cp	#0x00
	jr	z, _serDone
	out	(TermData), a
	inc	hl
	jr	_s01

_serDone:
	jr	serEcho

	
sText:
	.byte	CR, LF, CR, LF
	.ascii	"This is test ACIA unthrottled output."
	.byte	CR, LF, CR, LF, NUL

; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; 
; serEcho
;	echo everything sent in

serEcho:
	ld	hl, #seText
_se01:
	ld	a, (hl)
	cp	#0x00
	jr	z, _seDone
	out	(TermData), a
	inc	hl
	jr	_se01

_seDone:
	; now loop forever on serial echo

_seLoop:
	; get a byte
	in 	a, (TermStatus)	; comm status
	and	#DataReady	; byte ready for us?
	jr	z, _seLoop	; nope. loop back
	; echo it
	in	a, (TermData)	; get the byte
	cp	#CR		; print a newline
	jr	z, _seNL
	cp	#LF
	jr	z, _seNL
.if( Emulation )
	cp	#'`
	jr	z, endEmu
.endif
	out	(TermData), a	; send it
	jr	_seLoop		; do it again

_seNL:
	ld	a, #CR
	out	(TermData), a	; send it
	ld	a, #LF
	out	(TermData), a	; send it
	jr	_seLoop
	
	
	jr endTest

seText:
	.ascii	"Comm echo test. "
.if( Emulation )
	.ascii	"` to exit."
.else
	.ascii	"Looping forever."
.endif
	.byte	CR, LF, NUL

; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; 
; endTest
;	end of all of the testing.

endTest:
	jr endTest
	halt

; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; 
; endEmu
;	end emulation
endEmu:
	ld 	a, #EmuExit
	out	(EmulatorControl), a
	rst	#0x00
