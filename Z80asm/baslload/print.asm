; Printout helpers
;          print nibble, byte, HL
;
;          2016-06-10 Scott Lawrence
;
;  This code is free for any use. MIT License, etc.

	.module PrintHelp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; printout helpers

; PrintNibble
; 	send the nibble (a & 0x0F) out as ascii to the console 
PrintNibble:
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

; PrintByte:
; 	send the byte (a & 0xFF) out as ascii to the console
PrintByte:
	push	af	; store af
	srl	a
	srl	a
	srl	a
	srl	a
	call	PrintNibble

	pop	af	; restore af
	call	PrintNibble
	ret

; PrintHL
;       send the word hl out as ascii as 0xHHLL to the console
PrintHL:
        push    hl

        ld      hl, #str_0x
	call	Print

        ; print the byte
        pop     hl
PrintHLnoX:
        push    hl

        ld      a, h
        call    PrintByte
        ld      a, l
        call    PrintByte

        pop     hl
        ret

str_0x:
	.asciz	"0x"


; PrintLn
;	send out a text string to the console, followed by newline
PrintLn:
        call    Print
        call    PrintNL
        ret

; PrintNL
;	just print out a newline (register safe)
PrintNL:
        push    hl
        ld      hl, #str_CRLF
        call    Print
        pop     hl
        ret

str_CRLF:       .asciz  "\r\n"
                .byte   0x00


; ToUpper
;	convert the character in 'a' to uppercase

ToUpper:
        and     #0xDF           ; make uppercase (mostly)
        ret


