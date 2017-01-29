; Printout helpers
;          print nibble, byte, HL
;
;          2016-06-10 Scott Lawrence
;
;  This code is free for any use. MIT License, etc.

	.module PrintHelp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; printout helpers

; printNibble
; 	send the nibble (a & 0x0F) out as ascii to the console 
printNibble:
	push	af
	and	#0x0f		; mask it to be 0x0F
	add	#'0		; add ascii for 0
	cp	#'9+1
	jr	c, pn2
	add	#'A - '0 - 10
pn2:
	call	PutCh
	pop	af
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
printHLnoX:
	push	hl

	ld	a, h
	call	printByte
	ld	a, l
	call	printByte

	; add space
	ld	a, #' 
	call	PutCh
	call	PutCh

	pop	hl
	ret


; printDE
; 	send the word de out as ascii
printDE:
	push	af
	push	hl

	push	de
	pop	hl
	call	printHL

	pop	hl
	pop	af
	ret


; printASCIIok
;	print out the printable character, or '.'
printASCIIok:
	push	af
	push	hl

	cp 	a, #' 
	jr 	c, pao_0	; dot!

	cp	a, #'~+1
	jr	c, pao_1	; printable!
pao_0:
	ld	a, #'.

pao_1:
	call	PutCh

	pop	hl
	pop	af
	ret

; Print hl string out
Print:
	push	af
to_loop:
	ld	a, (hl)		; get the next character
	cp	#0x00		; is it a NULL?
	jr	z, termz	; if yes, we're done here.
	call	PutCh
	inc	hl		; go to the next character
	jr	to_loop		; do it again!
termz:
	pop	af
	ret			; we're done, return!

; print a newline (safe)
PrintNL:
	push	hl
	ld	hl, #str_crlf	; set up the newline string
	call	Print		
	pop	hl
	ret

str_crlf:
	.byte 	0x0d, 0x0a, 0x00	; "\r\n"


__printhl:
        push    hl
        ld      a, #'|
        call    PutCh
        call    Print
        ld      a, #'|
        call    PutCh
        pop     hl
        call    PrintNL
        ret

__printhlA:
	ld	a, #'A
	call	PutCh
	jr	__printhl


__printhlB:
	ld	a, #'B
	call	PutCh
	jr	__printhl

