; Memory Probe
;          Display what's going on for each 4k block
;
;          2016-06-10 Scott Lawrence
;
;  This code is free for any use. MIT License, etc.

	.module MemProbe

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; memory maps of possible hardware...
;  addr   	SBC	2014	LL
; E000 - FFFF 	RAM	RAM	RAM
; C000 - DFFF	RAM	RAM	RAM
; A000 - BFFF	RAM	RAM	RAM
; 8000 - 9FFF	RAM	RAM	RAM
; 6000 - 7FFF	RAM		RAM
; 4000 - 5FFF	RAM		RAM
; 2000 - 3FFF	ROM	ROM	RAOM
; 0000 - 1FFF	ROM	ROM	RAOM

	;;;;;;;;;;;;;;;
	; send the memory map out to the console
ShowMemoryMap:
	ld	hl, #str_memheader
	rst	#0x10
	
	xor	a
	ld	h, a
	ld	l, a		; hl = $0000	(start)

	add	a, #1
	ld	c, a		; c = scratch value to write
	push	hl

memloop:
	; ok. HL is loaded with an address.
	; read the value into B
	pop	hl
	push 	hl
	ld	b, (hl)

	; prep a value to shove out
	ld	a, c
	inc	a
	ld	c, a		; c++

	call	printHL		; print out the address

	ld	(hl), c		; (hl) = a (0)
	ld	a, (hl)		; h = (hl) == ?

	cp	#0xff		; read 0xff: could be unused.
	jr	z, memopen

	cp	c		; same as written: could br RAM
	jr	z, memram

	;cp	#0x00		; read 0x00: could be ROM.
	;jr	z, memrom

	; default to ROM
memrom:
	ld	hl, #str_rom
	jr	memnext

memopen:
	ld	hl, #str_opn
	jr	memnext

memram:
	ld	hl, #str_ram
	jr	memnext
	

memnext:
	rst	#0x10		; print it out
	rst	#0x08		; print CRLF

	pop 	hl
	; restore the value just in case it was ram
	ld	(hl), b

	; next
	ld	a, h
	cp	#0xF0
	jp	z, prompt	; we're done...

	add	a, #0x10
	ld	h, a		; hl += $1000
	push	hl
	jr	memloop

	jp	prompt


str_ram: .asciz	"RAM"
str_rom: .asciz	"ROM"
str_opn: .asciz	"-"

str_memheader:
	.asciz	"Memory map probe:\n"
str_0x:
	.asciz	" 0x"

