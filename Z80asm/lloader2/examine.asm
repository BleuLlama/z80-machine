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
	call	Print
EM0:
	call	GetCh		; get terminal character

	;call	PutCh		; echo
	;call	PrintNL

	cp	#'q
	jr	z, EMExit	; quit 
	
	cp	#' 
	jr	z, EM_next	; next chunk

	cp	#'x
	jr	z, EM_addr	; enter address

	cp	#0x0d
	jr	z, EM0
	cp	#0x0a
	jr	z, EM0

	jp	ExaMem		; not valid, try again

EMExit:
	xor	a
	ret


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
	call	PrintNL
	ld	hl, #str_address
	call	Print

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
	call	PrintNL
	pop	hl

	call	Exa_Line	; print out a line of data

	pop	bc
	djnz	EB_Loop		; go again if we're not done
	jp	ExaMem		; done! return to the shell

xx:
	ld	a, #'.
	call	PutCh
	ret

;;;;;;;;;;;;;;;;;;;;
; dump out a line
Exa_Line:			; print out one line of memory
	call	printHLnoX	;  print start address
	push	hl
	ld	hl, #str_spaces
	call	Print
	call	Print
	pop	hl

	; print out the HEX
	push	hl		; store aside start address
	ld	b, #16		; for 16 bytes...

EL_OneByte:
	push	bc
	ld	a, (hl)		; print out one byte as hex
	call	printByte
	push	hl
	 ld	hl, #str_spaces
	 call	Print
	
	; add an extra space on the middle byte
	 ld	a, b
	 cp	#0x09
	 jr 	nz, EL_NoExtraSpace

	 ld	hl, #str_spaces
	 call	Print
	
EL_NoExtraSpace:
	pop	hl
	inc	hl
	pop	bc
	djnz	EL_OneByte	; go again if we're not done

	pop	hl		; restore start address

	push	hl		; store it aside again

	; print out asciiprintable

EL_Prable:
	push	hl
	ld	hl, #str_spaces
	call	Print
	pop	hl
	ld	b, #8

EL_Pr00:
	ld	a, (hl)
	call	printASCIIok
	inc	hl
	djnz	EL_Pr00

	; space in the middle
	ld	a, #' 
	call	PutCh

	ld	b, #8
EL_Pr01:
	ld	a, (hl)
	call	printASCIIok
	inc	hl
	djnz	EL_Pr01
	
	pop	hl		; restore start address
	ld	de, #0x10
	add	hl, de		; adjust HL for the new start location

	ld	a, h
	ld	(LASTADDR), a
	ld	a, l
	ld	(LASTADDR+1), a ; and store it aside
	
	ret
