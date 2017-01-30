; llhw
;          RC2014LL-specific hardware support
;
;          2017-01-30 Scott Lawrence
;
;  This code is free for any use. MIT License, etc.

	.module llhw


.if( Emulation )
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 'quit' - quit out of the emulation
cQuit:  .asciz  "quit"
iQuit:  .asciz  "Exit the emulator"
fQuit:
        ;;;;;;;;;;;;;;;
        ; quit from the rom (halt)
        ld      a, #0xF0        ; F0 = flag to exit
        out     (EmulatorControl), a
        halt                    ; rc2014sim will exit on a halt

.endif


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; DisableROM
;       set the ROM disable flag

cRomDis:	.asciz	"romdis"
iRomDis:	.asciz	"Disable the ROM ($0000 RAM is R/W)"
fRomDis:
DisableROM:
        ld      a, #01
        out     (RomDisable), a
        ret


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; EnableROM
;       clear the ROM disable flag

cRomEn:		.asciz	"romen"
iRomEn:		.asciz	"Enable the ROM ($0000 RAM is write-only)"
fRomEn:
EnableROM:
        xor     a
        out     (RomDisable), a
        ret


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; CopyROMToRAM
;       copies $0000 thru $2000 to itself
;       seems like it would do nothing but it's reading from 
;       the ROM and writing to the RAM
;       Not sure if this is useful, but it's a good test.

cRom2Ram:	.asciz	"rom2ram"
iRom2Ram:	.asciz	"Copy the $0000 ROM to RAM"
fRom2Ram:
CopyROMToRAM:
        ld      hl, #str_Working
        call    Print

        xor     a
        ld      h, a
        ld      l, a    ; HL = $0000
CR2Ra:
        ld      a, (hl)
        ld      (hl), a ; RAM[ hl ] = ROM[ hl ]

        inc     hl      ; hl++
        ld      a, h    ; a = h
        cp      #0x20   ; is HL == 0x20 0x00?
        jr      nz, CR2Ra

        ; now patch the RAM image of the ROM so if we reset, it will
        ; continue to be in RAM mode...
        ld      hl, #ColdBoot   ; 0x3E  (ld a,      )
        inc     hl              ; 0x00  (    , #0x00)
        ld      a, #0x01        ; disable RAM value
        ld      (hl), a         ; change the opcode to  "ld a, #0x01"

        ; we're done. return
        ld      hl, #str_Done
        call    Print
        ret

