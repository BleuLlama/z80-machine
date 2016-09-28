; Hex
;          Intel hex file parser
;
;          2016-07-15 Scott Lawrence
;
;  This code is free for any use. MIT License, etc.

	.module Hex

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

str_br: 
	.asciz	" bytes read.\n\r"


; Handle parsing 
Hex_Term:
	

Hex_SD:


;;;;;;;;;;;;;;;;;;;;
; Entry point
;	load a character into "a", call this
HexParse:
	cp	#':		; beginning of a new line
	jr	HP_colon

	cp	#0x0a
	jr	HP_end		; handle end of line

	cp	#0x0d
	jr	HP_end		; handle end of line

	; at this point, check to see if it was a digit
	cp	#'0		; less than '0'?
	jr	c, HP_error

	cp	#'9+1		; less than '9'
	jr	c, HP_09

	; force a to be uppercase now.
	call	ToUpper

	cp	#'A		; less than 'A'
	jr	c, HP_error

	cp	#'F+1		; less than 'F'
	jr	c, HP_af

	jr	HP_error


HP_error:
	ld	a, #0xFF
	ret

HP_colon:
	; new line, let's clear out our variables...
	xor	a
	ld	bc, #0x0000
	ld	de, #0x0000
	ld	hl, #0x0000
	jp	HexReturn

	; dunno what it was, return
HexReturn:
	xor	a
	ret

HP_end:
	jp	HexReturn

HP_09:
	; it was [ '0'..'9' ]
	jp	HexReturn

HP_af
	jp	HexReturn

	
; format:
; 	:<1 byte:n bytes parcel><4 bytes: address><1 byte: command><n bytes parcel><1 byte: checksum>\n\r
;	
;  :0D003800F3F5DB81320080D381F1FBED4D4B
;  :0E0100003EAA320010FB18FEDB80E601FE0175
;  :0C0100028F63E7CD381DB81D38118EC05E
;  :00000001FF
;
;  : 0C 010E 00 28F63E7CD381DB81D38118EC 05
;  : 00 0000 01                          FF
;  ^ ^  ^    ^  ^                        ^---- checksum
;  | |  |    |  +----------------------------- parcel
;  | |  |    +-------------------------------- type (00:data, 01:end)
;  | |  +------------------------------------- start address
;  | +---------------------------------------- nbytes for parcel
;  +------------------------------------------ beginning of record (colon)

