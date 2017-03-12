; RC2014 related functions
; 
;	theoretically, all of the bare-hardware interface stuff that is
;	specific to the RC2014 and RC2014LL are in this one file.
; 
;  These use the ACIA at $80 for IO
;  Also emulation interface at $EE

	.module RC2014HW


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Output 

; Print
;	output the c-string pointed to by HL to the console
;	string must be null terminated (asciz)
Print:
	ld	a, (hl)
	cp	#0x00
	ret	z
	out	(TermData), a
	inc	hl
	jr	Print

; PutCh
;	put a single character out to the console
PutCh:
        out     (TermData), a   ; echo
        ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Input

; GetCh
;	loops until a character is ready from the terminal
;	then reads it in to 'a'
GetCh:
	; kbhit check
        in      a, (TermStatus) ; ready to read a byte?
        and     #DataReady      ; see if a byte is available

        jr      z, GetCh        ; nope. try again
        in      a, (TermData)   ; get it!
        ret

; KbHit
;	sets zero flag if there is a key ready at the ACIA
KbHit:
        in      a, (TermStatus)
        and     #DataReady
        ret


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Emulation stuff

; ExitEmulation
;	if we're in emulation, this will quit out of the emulator
ExitEmulation:
	ld	a, #EmuExit
	out	(EmulatorControl), a
	halt				; should never get here


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; LL hardware stuff

; DisableROM
;	turn off the ROM, making $0000-$7FFF RAM Read/Write
DisableROM:
        ld      a, #01
        out     (RomDisable), a
        ret

; EnableROM
;	turn on the ROM, making $0000-$7FFF RAM Write only
EnableROM:
        xor     a
        out     (RomDisable), a
        ret

