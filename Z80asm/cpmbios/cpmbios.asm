; CP/M Bios for RC2014/LL
; 	2017 Scott Lawrence
;	yorgle@gmail.com
; (Based on the MDS Basic I/O System)

	.module CPM_BIOS
.area	.CODE (ABS)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; cp/m addresses

TPAM	= 0x0100	; start of TPA / App memory
CCPM 	= 0xDC00	; start of CCP (command interpreter)
BDOSM 	= 0xE400	; OS functions
BIOSM	= 0xF200	; BIOS (us!)

; Low storage 

DiskBuf	= 0x0080	; disk buffer (0x80 (128) bytes)
BiosWrk = 0x040		; BIOS work area
DFCB	= 0x0060	; Default File Control Block

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


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.org	BIOSM

; jump table for routines
	jp	boot		; Cold boot 
	jp	wboot		; Warm boot

	jp	const		; console status
				; A = 0x00 if no char ready
				; A = 0xff if char ready
	jp	conin		; read to A
	jp	conout		; out from C

	jp	list		; list out from C to printer
	jp	punch		; punch out from C to punch card creator
	jp 	reader		; paper tape reader in TO A

	jp	home		; move to track 00
	jp	seldsk		; select disk from C
	jp	settrk		; set track addr (0..76) from C
	jp	setsec		; set sector addr (1..26) from C
	jp	setdma		; set dma address (0x80 default) from B?

	jp	read		; read sector to dma address
	jp	write		; write sector from dma address

	jp	listst		; list status
	jp	sectran		; translate sectors


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; cold boot
boot:
	ret

; warm boot
wboot:
	ret


; console status
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

; write from C
conout:
	ld	a, c
	out	(TermData), a		; no overflow check yet
	ret

; write to printer
list:
	ld	a, c
	ret

; list device status
;	0 if not ready, 1 if ready
listst:
	xor	a
	ret

; output to tape punch
punch:
	ld	a, c
	ret

; read from tape
reader:
	ld	a, #TAPE_EOF
	and 	#PARITY	; strip parity bit
	ret


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; io drivers for the disk

; home - reset to track 0
home:
	ld	c, #0x00
	call	settrk
	ret
	
; select disk in C
seldsk:
	ld	a, c
	ld	(diskno), a
	; validate value 0..15
	ret

; set the disk track from C
settrk:
	ld	a, c
	ld	(track), a
	ret

; set the current sector
setsec:
	ld	a, c
	ld	(sector), a
	ret

; set the new DMA value
setdma:
	ld l, c
	ld h, b
	; store it

; translate sectors
sectran:
	ret

; read from sepcified geometry to the dma buffer
read:
	ret

; write from the dma buffer into the sepcified geometry
write:
	ret


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; disk vars

diskno:	.byte 0x00
track:	.byte 0x00
sector: .byte 0x00
dma:    .word 0x0080
