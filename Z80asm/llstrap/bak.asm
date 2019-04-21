; example code for a BASIC USR function

TermStatus = 0x80
TermData   = 0x81

DEINT	   = 0x0a07
ABPASS	   = 0x117D

        .module BASIC_USR
.area   .CODE (ABS)


.org	0xF800
usr:
	ld	a, r
	ld	b, #0
	call	ABPASS
	ret




	call	DEINT
	ld	a, e
	cp	#10

	jr 	c, usr_00

	ld	a, #'H
	out	(TermData), a
	ld	a, #'I
	out	(TermData), a
	ld	a, #0x0d
	out	(TermData), a
	ld	a, #0x0a
	out	(TermData), a

	ld	a, #0
	ld	b, #42

	jr 	usr_ret

usr_00:
	inc	de
	ld	a, d
	ld	b, e

usr_ret:
	call	ABPASS

	ret



