; Ports
;          Ports examiner app for LLoader
;
;          2016-06-15 Scott Lawrence
;
;  This code is free for any use. MIT License, etc.

	.module Ports

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; InPort
;	read in the specified port and print it out
InPort:
	ld	hl, #str_port	; request a byte for the port
	call	Print
	call 	GetByteFromUser
	call	PrintNL

	ld	c, b		; port to read from in a
	in	a, (c)

	push	af		; print out the port data
	ld	hl, #str_data
	call	Print
	pop	af

	call	printByte	; print the value
	call	PrintNL

	ret			; next

; OutPort
;	output the specified byte to the specified port
OutPort:
	ld	hl, #str_port	; request a byte for the port
	call	Print
	call 	GetByteFromUser
	call	PrintNL
	ld	c, b

	ld	hl, #str_data	; request the port data
	call	Print
	call 	GetByteFromUser
	ld	a, b

	out	(c),a		; send it out
	call	PrintNL

	ret


str_port:
	.asciz	"Port: 0x"

str_data:
	.asciz	"Data: 0x"

str_address:
	.asciz 	"Address: 0x"

str_spaces:
	.asciz	" "

