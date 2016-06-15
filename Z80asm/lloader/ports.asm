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
	rst	#0x10
	call 	GetByteFromUser
	rst	#0x08

	ld	c, b		; port to read from in a
	in	a, (c)

	push	af		; print out the port data
	ld	hl, #str_data
	rst	#0x10
	pop	af

	call	printByte	; print the value
	rst	#0x08		; println

	jp	prompt		; next...

; OutPort
;	output the specified byte to the specified port
OutPort:
	ld	hl, #str_port	; request a byte for the port
	rst	#0x10
	call 	GetByteFromUser
	rst	#0x08
	ld	c, b

	ld	hl, #str_data	; request the port data
	rst	#0x10
	call 	GetByteFromUser
	ld	a, b

	out	(c),a		; send it out
	rst	#0x08		; println

	jp	prompt		; next...


str_port:
	.asciz	"Port: 0x"

str_data:
	.asciz	"Data: 0x"

str_address:
	.asciz 	"Address: 0x"

str_spaces:
	.asciz	" "

