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

	ld	b, a
	xor	a
	jp	ABPASS
