; Examine
;          Memory examiner app for LLoader
;
;          2016-05-09 Scott Lawrence
;
;  This code is free for any use. MIT License, etc.

	.module Examine

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

str_exa_prompt:
	.asciz	"\r\n [q]uit, SP more, [x] addr> "

;;;;;;;;;;;;;;;;;;;;
; initialize the applet
ExaInit:
	xor	a
	ld	(LASTADDR), a
	ld	(LASTADDR+1), a
	ret

;;;;;;;;;;;;;;;;;;;;
; ExaMem
;  prompt the user for what they want to do
ExaMem:
	ld	hl, #str_exa_prompt
	rst	#0x10
EM0:
	in	a, (TermStatus)	; ready to read a byte?
	and	#DataReady	; see if a byte is available
	jr	z, EM0	; nope. try again

	in	a, (TermData)
	;out	(TermData), a	; echo
	;rst	0x08		; newline

	cp	#'q
	jr	z, EM_quit
	
	cp	#' 
	jr	z, EM_next

	cp	#'x
	jr	z, EM_addr

	cp	#0x0d
	jr	z, EM0
	cp	#0x0a
	jr	z, EM0

	jp	ExaMem		; not valid, try again


;;;;;;;;;;;;;;;;;;;;
; quit from the ExaMem applet
EM_quit:
	jp	prompt


;;;;;;;;;;;;;;;;;;;;
; go to the next address block
EM_next:
	; restore last address
	ld	a, (LASTADDR)
	ld	h, a
	ld	a, (LASTADDR+1)
	ld	l, a
	jr	ExaBlock

;;;;;;;;;;;;;;;;;;;;
; get new address from the user
EM_addr:
	rst	0x08		; newline
	ld	hl, #str_address
	rst	#0x10

	; restore last address (in case user hits return)
	ld	a, (LASTADDR)
	ld	h, a
	ld	a, (LASTADDR+1)
	ld	l, a

	call	GetWordFromUser
	cp	#0xFF		; if returned FF, use HL, otherwise new DE
	jr	z, ExaBlock

	push	de
	pop	hl


;;;;;;;;;;;;;;;;;;;;
; dump out the block...
ExaBlock:
	ld	b, #16		; 16 lines per swath
EB_Loop:
	push	bc

	push	hl
	rst	#0x08
	pop	hl

	call	Exa_Line	; print out a line of data

	pop	bc
	djnz	EB_Loop		; go again if we're not done
	jp	ExaMem		; done! return to the shell

xx:
	push	hl
	ld	a, #'.
	out	(TermData), a
	pop	hl
	ret

;;;;;;;;;;;;;;;;;;;;
; dump out a line
Exa_Line:			; print out one line of memory
	call	printHLnoX	;  print start address
	push	hl
	ld	hl, #str_spaces
	rst	#0x10
	rst	#0x10
	pop	hl

	push	hl		; store aside start address
	ld	b, #16		; for 16 bytes...

EL_OneByte:
	push	bc
	ld	a, (hl)		; print out one byte as hex
	call	printByte
	push	hl
	 ld	hl, #str_spaces
	 rst	#0x10
	
	; add an extra space on the middle byte
	 ld	a, b
	 cp	#0x09
	 jr 	nz, EL_NoExtraSpace

	 ld	hl, #str_spaces
	 rst	#0x10
	
EL_NoExtraSpace:
	pop	hl
	inc	hl
	pop	bc
	djnz	EL_OneByte	; go again if we're not done

	pop	hl		; restore start address

	ld	de, #0x10
	add	hl, de		; adjust HL for the new start location

	ld	a, h
	ld	(LASTADDR), a
	ld	a, l
	ld	(LASTADDR+1), a ; and store it aside
	
	ret
