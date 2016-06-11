

        ;;;;;;;;;;;;;;;;;;;;
        ;  Bankswitch to the new bank
        ;       the problem is that we need to bank switch,
        ;       but once we do, this rom goes away.
        ;       so we need to pre-can some content

BankSwitchToC000:
        ld      hl, #CopyLoc    ; this is where we put the stub
        ld      de, #swapOutRom ; copy from
        ld      b, #endSwapOutRom-swapOutRom    ; copy n bytes
LDCopyLoop:
        ld      a, (de)
        ld      (hl), a
        inc     hl
        inc     de
        djnz    LDCopyLoop      ; repeat 8 times

        jp      CopyLoc         ; and run it!
        halt                    ; code should never get here

        ; this stub is here, but it gets copied to CopyLoc
swapOutRom:
        ld      a, #0x01        ; disable rom
        out     (RomDisable), a ; runtime bank sel

        rst     #0x00           ; cold boot
endSwapOutRom:


BankSwitchToRom:
        ld      hl, #CopyLoc    ; this is where we put the stub
        ld      de, #swapInRom ; copy from
        ld      b, #endSwapInRom-swapInRom    ; copy n bytes

TRCopyLoop:
        ld      a, (de)
        ld      (hl), a
        inc     hl
        inc     de
        djnz    TRCopyLoop      ; repeat 8 times

        jp      CopyLoc         ; and run it!
        halt                    ; code should never get here

        ; this stub is here, but it gets copied to CopyLoc
swapInRom:
	xor	a		; clear the disable ROM bit
        out     (RomDisable), a ; runtime bank sel

        rst     #0x00           ; cold boot
endSwapInRom:
