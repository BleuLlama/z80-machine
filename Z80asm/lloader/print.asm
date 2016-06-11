; Printout helpers
;          print nibble, byte, HL
;
;          2016-06-10 Scott Lawrence
;
;  This code is free for any use. MIT License, etc.
;
; this ROM loader isn't meant to be the end-all, be-all, 
; it's just something that can easily fit into the 
; boot ROM, that can be used to kick off another, better
; ROM image.

	.module PrintHelp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; printout helpers

; printNibble
; 	send the nibble (a & 0x0F) out as ascii to the console 
printNibble:
	and	#0x0f		; mask it to be 0x0F
	add	#'0		; add ascii for 0
	cp	#'9+1
	jr	c, pn2
	add	#'A - '0 - 10
pn2:
	out	(TermData), a	; send it out
	ret

; printByte:
; 	send the byte (a & 0xFF) out as ascii to the console
printByte:
	push	af	; store af
	srl	a
	srl	a
	srl	a
	srl	a
	call	printNibble

	pop	af	; restore af
	call	printNibble
	ret

; printHL
;	send the word hl out as ascii as 0xHHLL to the console
printHL:
	push	hl

	ld	hl, #str_0x
	rst	#0x10		; print it out

	; print the byte
	pop	hl
	push	hl

	ld	a, h
	call	printByte
	ld	a, l
	call	printByte

	; add space
	ld	a, #' 
	out	(TermData), a	; send it out.
	out	(TermData), a	; send it out.

	pop	hl
	ret
