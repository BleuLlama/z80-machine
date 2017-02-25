; Lloader for BASIc integration
;
;  A simple HEX file loader, and file lister (through console backchannel file access)
;

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

DisableROM:
        ld      a, #01
        out     (RomDisable), a
        ret

EnableROM:
        xor     a
        out     (RomDisable), a
        ret


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; strings

str_Splash:	.asciz	"Lloader3  (c)2017 Scott Lawrence"
str_CRLF:	.asciz	"\r\n"
		.byte	0x00
