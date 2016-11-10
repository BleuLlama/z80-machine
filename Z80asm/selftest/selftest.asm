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

; IO Board displays codes:
;	bottom bit is always 0 to prevent bank switching in LL system
;	1xxx xxx0	pass/fail codes
;	xxxx xxx0	in echo test, this shows the current ascii code <<1

.include "../Common/hardware.asm"


; additional defines
Emulation = 1	; are we building for emulator?
LEDComm	  = 1	; display ascii on LEDs


LF 	= 0x0a
CR	= 0x0D
NUL	= 0x00

; for the ROM/RAM display
ROMCHAR = 'O
RAMCHAR = 'A

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

	; pass code
	ld	a, #0x82
	out	(DigitalIO), a

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
	; pass code
	ld	a, #0x84
	out	(DigitalIO), a

	jr	ramTest
	
sText:
	.byte	CR, LF, CR, LF
	.ascii	"This is test ACIA unthrottled output."
	.byte	CR, LF, CR, LF, NUL


; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; 
; ramTest
;	probe memory to find out where ram is
; 	NOTE: This is destructive to RAM. Deal with it.

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

	; pass code
	ld	a, #0x86
	out	(DigitalIO), a

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

	; pass code
	ld	a, #0x88
	out	(DigitalIO), a

	; write numbers out
	ld	hl, #0x0000
	ld	a, #0x0F
	ld	(hl), a		; 0x0000
	add	hl, bc
	ld	a, #0x0E
	ld	(hl), a		; 0x2000
	add	hl, bc
	ld	a, #0x0D
	ld	(hl), a		; 0x4000
	add	hl, bc
	ld	a, #0x0C
	ld	(hl), a		; 0x6000
	add	hl, bc
	ld	a, #0x0B
	ld	(hl), a		; 0x8000
	add	hl, bc
	ld	a, #0x0A
	ld	(hl), a		; 0xA000
	add	hl, bc
	ld	a, #0x09
	ld	(hl), a		; 0xC000
	add	hl, bc
	ld	a, #0x08
	ld	(hl), a		; 0xE000

	; text header
	; it kills me to re-copy this code, but with 0 ram usage...
roamhdr:
	ld	hl, #sROAM

_sROAM01:
	ld	a, (hl)
	cp	#0x00
	jr	z, _sROAMDone
	out	(TermData), a
	inc	hl
	jr	_sROAM01
_sROAMDone:

	; now, let's read the numbers back and display info.

	; test 0x0000
	ld	hl, #0x0000
	ld	a, (hl)		; should be 0x0F
	cp	#0x0F
	ld	a, #RAMCHAR
	jr	z, _ROAM0out
	ld	a, #ROMCHAR
_ROAM0out:
	out	(TermData), a

	; test 0x2000
	add	hl, bc
	ld	a, (hl)		; should be 0x0E
	cp	#0x0E
	ld	a, #RAMCHAR
	jr	z, _ROAM2out
	ld	a, #ROMCHAR
_ROAM2out:
	out	(TermData), a

	; test 0x4000
	add	hl, bc
	ld	a, (hl)		; should be 0x0D
	cp	#0x0D
	ld	a, #RAMCHAR
	jr	z, _ROAM4out
	ld	a, #ROMCHAR
_ROAM4out:
	out	(TermData), a


	; test 0x6000
	add	hl, bc
	ld	a, (hl)		; should be 0x0C
	cp	#0x0C
	ld	a, #RAMCHAR
	jr	z, _ROAM6out
	ld	a, #ROMCHAR
_ROAM6out:
	out	(TermData), a


	; test 0x8000
	add	hl, bc
	ld	a, (hl)		; should be 0x0B
	cp	#0x0B
	ld	a, #RAMCHAR
	jr	z, _ROAM8out
	ld	a, #ROMCHAR
_ROAM8out:
	out	(TermData), a


	; test 0xA000
	add	hl, bc
	ld	a, (hl)		; should be 0x0A
	cp	#0x0A
	ld	a, #RAMCHAR
	jr	z, _ROAMAout
	ld	a, #ROMCHAR
_ROAMAout:
	out	(TermData), a


	; test 0xC000
	add	hl, bc
	ld	a, (hl)		; should be 0x09
	cp	#0x09
	ld	a, #RAMCHAR
	jr	z, _ROAMCout
	ld	a, #ROMCHAR
_ROAMCout:
	out	(TermData), a


	; test 0xE000
	add	hl, bc
	ld	a, (hl)		; should be 0x08
	cp	#0x08
	ld	a, #RAMCHAR
	jr	z, _ROAMEout
	ld	a, #ROMCHAR
_ROAMEout:
	out	(TermData), a

	

	; footer
	ld	a, #CR
	out	(TermData), a
	ld	a, #LF
	out	(TermData), a

	jp	ramResult

; I know there are better ways to do this, but this will 
; make for simpler code.
sROAM:
	.ascii	"02468ACE  * 0x1000  (A = RAM, O = ROM)"
	.byte	CR, LF, NUL


ramResult:
	; ram is '1's 	2468 ACE0
	; eg. stock     0000 1111
	; messed up 	0000 0100

	; pass code
	ld	a, #0x8A
	out	(DigitalIO), a

	jr	serEcho

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

	; get the byte
	in	a, (TermData)	; get the byte

.if( LEDComm )
	; display it on the IO card
	ld	b, a
	sla	a
	and	#0xFE
	out	(DigitalIO), a
	ld	a, b
.endif

	; echo it
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
