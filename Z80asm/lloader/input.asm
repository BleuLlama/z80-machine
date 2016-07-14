; Input
;          get content from the user
;
;          2016-06-13 Scott Lawrence
;
;  This code is free for any use. MIT License, etc.

	.module Input

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; GetNibbleFromUser
; returns a byte read from the user to b
; if user hits 'enter' (default value) then a is 0xFF
GetNibbleFromUser:
	xor	a		; reset our return flag
	ld	b, #0x00	; nibble entered by user
	
GNFU_0:
	call	GetCh		; 

	cp	#0x0a
	jr	z, GNFU_Break	; return hit
	cp	#0x0d
	jr	z, GNFU_Break	; return hit
	
	cp	#'0
	jr	c, GNFU_0	; < 0, try again

	cp	#'9 + 1
	jr	c, GNFU_g0	; got 0..9

	cp	#'A
	jr	c, GNFU_0	; between '9' and 'A', try again
	
	cp	#'F + 1
	jr	c, GNFU_gAuc	; got A-F

	cp	#'a 
	jr	c, GNFU_0	; between 'F' and 'a', try again

	cp	#'f + 1
	jr	c, GNFU_galc	; got a-f

	jr	GNFU_0		; not valid, retry

GNFU_g0:			; '0'..'9'
	sub	#'0
	ld	b, a
	xor	a
	ret

GNFU_galc:			; 'a'..'f'
	and	#0x4F		; make uppercase
GNFU_gAuc:			; 'A'..'F'
	add	#10-'A
	ld	b, a
	xor	a
	ret

GNFU_Break:
	ld	a, #0xff
	ret


; GetByteFromUser
;	returns a value in b
;	returns code in a,  0 if ok, FF if no value
GetByteFromUser:
	; read top nibble
	call	GetNibbleFromUser
	cp	#0xFF
	ret	z		; user escaped

	
	ld	a, b
	call	printNibble
	sla	a
	sla	a
	sla	a
	sla	a
	ld	d, a		; store in top half of d

	; read bottom nibble
	call	GetNibbleFromUser
	cp	#0xFF
	ret	z		; user escaped

	ld	a, b

	; combine the two
	ld	a, b
	call	printNibble
	and	#0x0F		; just in case..
	add	d

	ld	b, a		; store the full result in b

	; return
	xor	a		; just in case, clear a
	ret


; GetWordFromuser
; returns a word read from the user to de
; if user hits 'enter' (default value) then a is 0xFF
GetWordFromUser:
	; read top byte
	call	GetByteFromUser
	cp	#0xFF
	ret	z		; user hit return, just return
	ld	d, b

	; read bottom byte
	push	de
	call	GetByteFromUser
	cp	#0xFF
	ret	z
	pop	de
	ld	e, b

	; if we got here, DE = two nibbles
	xor	a
	ret

