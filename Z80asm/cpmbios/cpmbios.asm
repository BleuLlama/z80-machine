; CP/M Bios for RC2014/LL
; 	2017 Scott Lawrence
;	yorgle@gmail.com
; (Based on the MDS Basic I/O System)

	.module CPM_BIOS
.area	.CODE (ABS)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; cp/m addresses

MEMSIZE = 64
BIAS    = (MEMSIZE -20) * 1024
TPAM	= 0x0100	; start of TPA / App memory
CCPM 	= 0x3400 + BIAS	; start of CCP (command interpreter) dc00
BDOSM 	= 0x3C00 + BIAS	; OS functions e400
BIOSM	= 0x4A00 + BIAS	; BIOS (us! f200

STACK   = 0xC000	; anyplace below CCPM is fine.

; Low storage 

DiskBuf	= 0x0080	; disk buffer (0x80 (128) bytes)
BiosWrk = 0x040		; BIOS work area
DFCB	= 0x0060	; Default File Control Block

; 0x0000 low memory addresses
LWARM   = 0x0000
LIOB	= 0x0003
LBDOS	= 0x0005
CURRDRV = 0x0004

; defines
PARITY      = 0x7f
CNST_AVAIL  = 0xff
CNST_NODATA = 0x00
TAPE_EOF    = 0x1A


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; IO ports/data

TermStatus      = 0x80  ; Status on MC6850 for terminal comms
TermData        = 0x81  ; Data on MC6850 for terminal comms
  DataReady     = 0x01  ;  this is the only bit emulation works with.

RomDisable	= 0x00	; IO port 00
        ; for RC2014/LL hardware
        ; bit 0 (0x01) is the ROM disable bit,
        ;  = 0x00 -> ROM is active
        ;  = 0x01 -> ROM is disabled
		

CH_NULL		= 0x00

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.org	BIOSM

; jump table for routines
	jp	boot		; 00  Cold boot 
	jp	wboot		; 01  Warm boot - reload CCP

	jp	const		; 02  console status
				;     A = 0x00 if no char ready
				;     A = 0xff if char ready
	jp	conin		; 03  read to A
	jp	conout		; 04  out from C

	jp	list		; 05  list out from C to printer
	jp	punch		; 06  punch out from C to punch card creator
	jp 	reader		; 07  paper tape reader in TO A

	jp	home		; 08  move to track 00
	jp	seldsk		; 09  select disk from C
	jp	settrk		; 10  set track addr (0..76) from C
	jp	setsec		; 11  set sector addr (1..26) from C
	jp	setdma		; 12  set dma address (0x80 default) from B?

	jp	read		; 13  read sector to dma address
	jp	write		; 14  write sector from dma address

	; Added for CP/M 2.2
	jp	listst		; 15  list status
	jp	sectran		; 16  translate sectors



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 0. BOOT  cold boot
boot:
	; system init
	di			; turn off interrupts
	im	#0		; interrupt mode 0

	call	disableRom	; disable BASIC ROM

	ld	sp, #STACK	; set up the stack

	call	defaultDisk	; reset disk positions

	ld	bc, #DiskBuf	; default of 0x0080
	call	setdma		; default DMA buffer

	; signon messages
	ld	hl, #bstr
	call	conoutstr	; pat our own backs

	; initialize IOBYTE
	; initialize WBOOT 0..8
	call	initwb8		; setup low mem

	; reg c = 0
	ld	c, #0x00

	; transfer operations to CCP
	jp	CCPM


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 1. WBOOT  warm boot - reload CCP
wboot:
	; reload CCP, BDOS, (BIOS)
		; TBD

	; initialize WBOOT 0..8
	call	initwb8

	; reg c = 0
	ld	c, #0x00

	; transfer operations to CCP
	jp	CCPM

	
bstr: 	.ascii "MicroLlama BIOS v0.01\r\n"
	.ascii "   (c) 2017 Scott Lawrence\r\n"
	.asciz "Copyright (c), 1979 Digital Research\r\n"

x00: ; copy this chunk to 0x0000
	jp	BIOSM + 3		; C3 03 FA
	.byte	0x00	; iobyte	; 00
	.byte	0x00	; default disk	; 00
	jp	BDOSM			; C3 00 EC

initwb8:
	ld	b, #8		; number of bytes to copy
	ld	hl, #LWARM
	ld	de, #x00
	ldir
	ret

disableRom:
	; currently this is OK, when we switch to the official RC2014 pageable
	; ROM/0x0000 RAM interface, we'll need to add in a check here to confirm
	; we're in ROM or RAM mode.
	ld	a, #01
	out	(RomDisable), a
	ret

enableRom:
	xor	a
	out	(RomDisable), a
	ret


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 2. CONST  console status
const:
	in	a, (TermStatus)
	and	#DataReady
	jr	z, _cnst_NoData

	; byte is ready
	ld	a, #CNST_AVAIL
	ret

_cnst_NoData:
	; no byte ready
	ld	a, #CNST_NODATA
	xor	a
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 3. CONIN  console read in
; read to A
; hang while waiting
; clear parity bit
conin:
	; loop until a byte is available
	in	a, (TermStatus)
	and	#DataReady
	jr	z, conin
	
	; get it
	in	a, (TermData)
	and	#PARITY	; strip parity bit
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 4. CONOUT  write to console
; write from C
conout:
	ld	a, c
conout_a:
	out	(TermData), a		; no overflow check yet
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; conoutstr - helper to print a string
; print out asciiz string passed in HL
conoutstr:
	; get the character
	ld	a, (hl)
	; return if null
	cp	a, #CH_NULL
	ret	z
	
	; okay, if not, print it and move on
	call 	conout_a
	inc	hl
	jr 	conoutstr
	

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 5. LIST
; write to printer
list:
	; TBD - future
	ld	a, c
	ret


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 15. LISTST  status of list 
; list device status
;	0 if not ready, 1 if ready
listst:
	; TBD - future
	xor	a
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 6. PUNCH / AUXOUT
; output to tape punch
punch:
	; TBD - future
	ld	a, c
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 7. READER
; read from tape
reader:
	; for now, return EOF
	ld	a, #TAPE_EOF
	and 	#PARITY	; strip parity bit
	ret


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; io drivers for the disk

defaultDisk:
	ld	c, #0x00
	call	seldsk
	call	settrk
	call 	setsec
	ret
	

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 8. HOME  reset to track 0
home:
	ld	c, #0x00
	call	settrk
	ret
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 9. SELDSK  select disk in C
seldsk:
	ld	a, c
	ld	(diskno), a
	; validate value 0..15
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 10. SETTRK  set the disk track from from BC
settrk:
	ld	a, b
	ld	(track), a
	ld	a, c
	ld	(track+1), a
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 11. SETSEC  set the current sector from BC
setsec:
	ld	a, b
	ld	(sector), a
	ld	a, c
	ld	(sector+1), a
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 12. SETDMA  set the new DMA value (passed via BC)
setdma:
	; store it
	ld	a, b
	ld	(dma), a
	ld	a, c
	ld	(dma+1), a
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 16. SECTRAN translate sectors
sectran:
	; tbd
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 13. READ  read from sepcified geometry to the dma buffer
read:
	; tbd
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 14. WRITE  write from the dma buffer into the sepcified geometry
write:
	; tbd
	ret


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; disk geometry variables

diskno:	.byte 0x00
track:	.word 0x0000
sector: .word 0x0000
dma:    .word 0x0080

.bound 0xffff
