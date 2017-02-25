; RC2014 related functions
; 
;  These use the ACIA at $80 for IO
;  Also emulation interface at $EE


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Output 

Print:
	ld	a, (hl)
	cp	#0x00
	ret	z
	out	(TermData), a
	inc	hl
	jr	Print

PrintLn:
	call	Print
	call	PrintNL
	ret

PrintNL:
	push	hl
	ld	hl, #str_CRLF
	call	Print
	pop	hl
	ret


str_CRLF:	.asciz	"\r\n"
		.byte	0x00

PutCh:
        out     (TermData), a   ; echo
        ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Input

GetCh:
        in      a, (TermStatus) ; ready to read a byte?
        and     #DataReady      ; see if a byte is available

        jr      z, GetCh        ; nope. try again
        in      a, (TermData)   ; get it!
        ret

ToUpper:
        and     #0xDF           ; make uppercase (mostly)
        ret

KbHit:
        in      a, (TermStatus)
        and     #DataReady
        ret


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Emulation stuff

; if we're un emulation, this will quit out of the emulator
ExitEmulation:
	ld	a, #EmuExit
	out	(EmulatorControl), a
	halt				; should never get here


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; LL hardware stuff

; turn off the ROM, making $0000-$7FFF RAM Read/Write
DisableROM:
        ld      a, #01
        out     (RomDisable), a
        ret

; turn on the ROM, making $0000-$7FFF RAM Write only
EnableROM:
        xor     a
        out     (RomDisable), a
        ret

