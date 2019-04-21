; example code for a BASIC USR function

TermStatus = 0x80
TermData   = 0x81

DEINT	   = 0x0a07
ABPASS	   = 0x117D

        .module BASIC_USR
.area   .CODE (ABS)


.org	0xF800
usr:
	ld	a, r		; a = r
	inc	a		; a++
	ld	r, a		; r = a

    ld  a, #'H
    out (TermData), a
    out (TermData), a
    ld  a, #'I
    out (TermData), a
    out (TermData), a

	jr 	goVid

	ld	b, a
	xor	a
	jp	ABPASS


VidMem	= 0x10
VidReg	= 0x11

goVid:
	ld	hl, #mbmp99
	ld 	b,	#8
	ld 	c,	#0

gv2:
	ld		a, (hl)
	out		(VidReg), a
	;call	delay

	ld		a, c
	or		a, #0x80
	out		(VidReg), a
	;call	delay

	inc		c
	inc		hl
	djnz	gv2

	jp 		ABPASS
	

mbmp99:
	.byte 0, 208, 0, 0, 1, 0, 0, 244

delay:
	push	bc
	ld		b, #255
	djnz	.
	pop		bc
	ret	
