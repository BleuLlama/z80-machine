; Poke
;          Poke memory values, run RAM
;
;          2016,2017 Scott Lawrence
;
;  This code is free for any use. MIT License, etc.

	.module Poke

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

cPoke:	.asciz	"poke"
iPoke:	.asciz	"Write data to memory"

; PokeMemory
fPoke:
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


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

cGo:	.asciz	"go"
iGo:	.asciz	"Start execution at a specific address"
fGo:
	ld	hl, #str_address
	call	Print
	call	GetWordFromUser
	cp	a, #0xff
	ret	z		; user escaped

	; push the address from the user back onto the stack (return location)
	push	de
	ret


.if 0
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; test
;	just a simple thing to jump into to test the 'go' function
test:
	halt
	ld	sp, #0x9000
	ld	hl, #str_testworked
	call	Print
	jr	.
	halt

str_testworked:
	.asciz	"\r\n\r\nHello, world!\r\n"
.endif
