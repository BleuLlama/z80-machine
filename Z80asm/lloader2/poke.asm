; Poke
;          Poke memory values
;
;          2016-06-15 Scott Lawrence
;
;  This code is free for any use. MIT License, etc.

	.module Poke

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; PokeMemory

PokeMemory:
	ld	hl, #str_address
	call	Print
	call	GetWordFromUser		; de has the word
	push	de			; store it aside
	cp	#0xff
	jr	z, PM_nlret
	call	PrintNL


	ld	hl, #str_data
	call	Print
	call 	GetByteFromUser		; b has the data
	cp	#0xff
	jr	z, PM_nlret
	call	PrintNL

	; and store it...
	pop	hl
	ld	(hl), b

	xor	a
	ret

	; if there was a problem, just return
PM_nlret:
	pop	de			; fix the stack
	call	PrintNL
	xor	a
	ret

