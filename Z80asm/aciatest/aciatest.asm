; small test for the ACIA handler
; 

ACIA_CONTROL	= 0x80
ACIA_DATA	= 0x81

STORE		= 0x8000
STACK		= 0x9000

	.module ACIA_TEST
.area	.CODE (ABS)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; initial entry point
.org 0x0000			; start at 0x0000
	di			; disable interrupts
	ld	sp, #STACK	; setup the stack
	im	1		; interrupt mode 1

	ld	a, #0x0d
	out	(ACIA_DATA), a
	ld	a, #0x0a
	out	(ACIA_DATA), a
	ld	a, #0x0d
	out	(ACIA_DATA), a
	ld	a, #0x0a
	out	(ACIA_DATA), a
xxx:
	in	a, (ACIA_CONTROL)
	and	#0x01
	jr	z, xxx

	ld	a, #0x7c
	out	(ACIA_DATA), a

	in	a, (ACIA_DATA)
	out	(ACIA_DATA), a
	jr	xxx








	jp	main		; do our thing

.org 0x0038			; Interrupt handler
	di
	push	af
	in	a, (ACIA_DATA)
	ld	(STORE), a
	out	(ACIA_DATA), a
	pop	af
	ei
	reti


.org 0x0100
main:
	; write out some memory
	ld	a, #0xaa
	ld	(#0x1000), a
	ei			; turn on interrupts

inloop:
	jr	inloop
	; wait for input
	in	a, (ACIA_CONTROL)
	and	#0x01
	cp	#0x01
	jr	z, inloop	; no input yet, check again

	; send the input back out
	ld	a, #0x7c	; '|'
	out	(ACIA_DATA), a

	in	a, (ACIA_DATA)
	out	(ACIA_DATA), a
	jr 	inloop		; do it again!

