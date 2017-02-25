; Pointers
;          Various utility functions for structures/pointers
;
;          2017 Scott Lawrence
;
;  This code is free for any use. MIT License, etc.

	.module Pointers

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; IsHLZero
;       a = 0 if HL == 0x0000
;       a = nonzero otherwise
IsHLZero:
        ld      a, h
        cp      a, #0x00
        ret     nz              ; return the byte (nonzero)

        ld      a, l
        ret                     ; return the byte (nonzero)

; I did have some logic in here to compare both bytes and set a 
; return value, then i realized that if all i care about is if 
; both bytes are zero, I just need to check the first one for 
; zero.  If it's not, just return it.  If it is zero, then just
; load the second byte into a, and you can use that one as the 
; return value! 


; DerefHL
;	Dereference the pointer in HL
;       visit the address at HL, and take the data there (16 bit) and
;       shove it back into HL.
;       only HL will be modified
DerefHL:
        push    bc
        ld      c, (hl)
        inc     hl
        ld      b, (hl)
        push    bc
        pop     hl
        pop     bc
        ret

