; Lloader for BASIc integration

.include "../Common/hardware.asm"

        .module BASIC_USR
.area   .CODE (ABS)


.org	0xF800
usr:

	di
u1:
	ld	hl, #str_Splash
	call	PrintLn

u3:
	in	a, (TermStatus)
	and	a, #DataReady
	jr	z, u3

	call	PrintLn
	call	PrintLn
	ld	a, #EmuExit
	out	(EmulatorControl), a

	ei
	ret


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Utility functions

Print:
	ld	a, (hl)
	cp	#0x00
	ret	z
	out	(TermData), a
	inc	hl
	jr	Print

PrintLn:
	call	Print
	ld	hl, #str_CRLF
	call	Print
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; strings

str_Splash:	.asciz	"Lloader3  (c)2017 Scott Lawrence"
str_CRLF:	.asciz	"\r\n"
		.byte	0x00
