; small test for the demo code
; 

	.module SM_TEST
.area	.CODE (ABS)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; initial entry point
.org 0x0000			; start at 0x0000
	di			; disable interrupts

	; test some outs
	ld	a, #0x55
	out	(0x11), a
	inc	a
	out	(0x22), a


	; test some ins
	in	a, (0x12)
	in	a, (0xAB)

	; write out some memory
	ld	a, #0xaa
	ld	(#0x1000), a
	dec	a
	ld	(#0x1001), a
	dec	a
	ld	(#0x1002), a

	ld	b, #4
	ld	hl, #0x2000
here:
	inc	hl
	ld	(hl), b
	djnz	here

	halt
	
