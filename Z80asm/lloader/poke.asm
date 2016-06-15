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
	rst	#0x10
	call	GetWordFromUser		; de has the word
	push	de			; store it aside
	cp	#0xff
	jr	z, PM_nlret
	rst	#0x08


	ld	hl, #str_data
	rst	#0x10
	call 	GetByteFromUser		; b has the data
	cp	#0xff
	jr	z, PM_nlret
	rst	#0x08

	; and store it...
	pop	hl
	ld	(hl), b

	jp	prompt

	; if there was a problem, just return
PM_nlret:
	pop	de			; fix the stack
	rst	#0x08
	jp	prompt

