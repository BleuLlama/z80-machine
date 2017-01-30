; Memory Probe
;          Display what's going on for each 4k block
;
;          2016-06-10 Scott Lawrence
;
;  This code is free for any use. MIT License, etc.

	.module MemProbe

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

cMMap:	.asciz	"mmap"
iMMap:	.asciz	"Detect RAM/ROM in system"

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
fMMap:
ShowMemoryMap:
	ld	hl, #str_memheader
	call	Print
	
	xor	a
	ld	h, a
	ld	l, a		; hl = $0000	(start)

	ld	c, a
	ld	b, a
	push 	bc
	pop	ix
	push 	bc
	pop 	iy

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
	inc	ix
	jr	memnext

memopen:
	ld	hl, #str_opn
	jr	memnext

memram:
	ld	hl, #str_ram
	inc	iy
	jr	memnext
	

memnext:
	call	Print 		; print it out
	call	PrintNL

	pop 	hl
	; restore the value just in case it was ram
	ld	(hl), b

	; next
	ld	a, h
	cp	#0xF0
	jr	z, memsummary	; we're done

	add	a, #0x10
	ld	h, a		; hl += $1000
	push	hl
	jr	memloop


memsummary:
	call	PrintNL

	push	ix		; number of 2k ROM banks
	pop	bc
	call	memadjust
	call	printByte
	ld	hl, #str_kROM
	call	Print
	call	PrintNL

	push	iy
	pop	bc
	call	memadjust
	call 	printByte
	ld	hl, #str_kRAM
	call	Print
	call	PrintNL
	
	xor	a
	ret

; memadjust
;	value is in BC 0..16 (using a table)
;	messes up hl, stores value in A
;	I could probably multiply A by 4, and BCD it
;	but meh. this is fine.
memadjust:
	ld	a, c
	cp	#0x00
	ret	z		; 0

	dec 	bc		; 0..15
	ld	hl, #memtab
	add	hl, bc
	ld	a, (hl)
	ret

memtab: ; bcd list of kbytes per num banks
	.byte 0x04, 0x08, 0x12, 0x16
	.byte 0x20, 0x24, 0x28, 0x32
	.byte 0x36, 0x40, 0x44, 0x48
	.byte 0x52, 0x56, 0x60, 0x64

str_ram: .asciz	"RAM"
str_rom: .asciz	"    ROM"
str_opn: .asciz	"-"

str_memheader:
	.asciz	"Memory map probe:\n"
str_0x:
	.asciz	" 0x"

str_kROM: 
	.asciz 	" kBytes ROM"
str_kRAM: 
	.asciz 	" kBytes RAM"

