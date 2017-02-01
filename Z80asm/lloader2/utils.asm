; Utils
;          Various utility functions
;
;          2017 Scott Lawrence
;
;  This code is free for any use. MIT License, etc.

	.module Utils

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Line input routines


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; ClearLine
;	clear the line buffer
ClearLine:
	xor 	a
	ld	d,a		; DE = 0000  (index for GetLine)
	ld	e,a
	ld	b, #LBUFLEN	; set the buffer length
	ld	hl, #LBUF	; set the buffer start
clx:
	ld	(hl),a
	inc	hl
	djnz 	clx		; zero it all!
	ret


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; GetLine Helpers

; output a DING (ctrl-g)
_glDing:
	ld	a, #CH_BELL
	call	PutCh
	ret

; error return
_glErRet:
	call	_glDing
	ret

; error and continue
_glErCont:
	call	_glDing
	jr 	GetLine	

; output a carraige return (reset on the line) and reprint HL
_glCRPrint:
	ld	a, #0x0D
	call	PutCh
	ld	hl, #str_prompt
	call	Print
	ld	hl, #LBUF	; load base
	call	Print

	; now a little hack to make sure we print erased characters
	ld	a, #CH_SPACE
	call	PutCh
	ld	a, #CH_BS
	call	PutCh
	ret
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; interactive get a line/character handler
; stores the input data in the line buffer
GetLine::
	call 	_glCRPrint
	ld 	a, e		; check if line is full
	cp	#LBUFLEN-1	; max length (-1 for null ending)
	jr	z, _glErRet
	ret	z		; FULL! return!

	; we're okay getting more characters
	call	GetCh

	; check for end-of-line cases
	cp	#CH_CR
	ret	z
	cp	#CH_NL
	ret	z


	; check for backspace/delete keyhits
	cp	#CH_BS		; backspace
	jr	z, _glBackspace
	cp 	#CH_DEL		; delete
	jr	z, _glBackspace

	; check for ctrl-u keyhits (clears line)
	cp	#CH_CTRLU
	jr	z, _glClearLine

	; make sure the character is printable
	cp	#CH_PRLOW	; less than PRLOW is not printable
	jr	c, GetLine	; not printable
	cp	#CH_PRHI+1	; greater than PRHI is not printable
	jr	c, _glAdd	; printable!

	; too big. redo!
	jr	GetLine

_glAdd:
	; add the new character onto the line
	ld	hl, #LBUF	; load base
	add	hl, de		; add index
	ld	(hl), a
	inc	de		; inc index

	; and get another character
	jr	GetLine

; handle backspace or delete key being hit
_glBackspace:
	ld	a, e		; check that we can decrement
	cp	#0x00
	jr	z, _glErCont

	dec	de		; move index back

	xor	a
	ld	hl, #LBUF
	add	hl, de
	ld	(hl), a		; store a null

	jr	GetLine		; done


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; ctrl-u hit, clear the line
_glClearLine:
	xor 	a
	ld	d,a		; DE = 0000  (index for GetLine)
	ld	e,a
	ld	b, #LBUFLEN	; set the buffer length
	ld	hl, #LBUF	; set the buffer start
_glcl0:
	ld	a, (hl)
	cp	#CH_NULL
	jr	z, _glclret
	ld	a, #CH_SPACE	; fill with spaces
	ld	(hl),a
	inc	hl
	djnz 	_glcl0		; zero it all!
_glclret:
	; now clear the index
	ld	hl, #LBUF	; set the buffer start
	jr	GetLine


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; U_Streq - string equality compare
; 	compares the string in hl with the string in de
;	if equal returns 0
;	destructive to a and c
U_Streq::
	push	hl
	push	de

_seqLoop:
	ld	a, (hl)
	ld	b, a
	ld	a, (de)
	cp	a, b
	jr	nz, _seqNEQ	; not equal!

	; if we're here then they're equal
	cp	a, #0x00	; check for null
	jr	z, _seqDone	; it was null! continue
	
	; next character!
	inc	hl
	inc	de
	jr	_seqLoop

; it was null, strings were equal!
_seqDone:
	xor	a
	jr	_seqRet

; strings are not equal
_seqNEQ:
	ld	a, #0x01	; not equal
_seqRet:
	pop	de
	pop	hl
	ret
	

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; NullSpace
;	null out the next whitespace (' ') (or null)
;	destructive to the data, returns hl intact
U_NullSpace::
	push	hl
_nlsLoop:
	ld	a, (hl)
	cp	#CH_SPACE
	jr 	z, _nlsRetFix
	cp	#CH_NULL
	jr 	z, _nlsRet
	inc	hl		; next character...
	jr	_nlsLoop

_nlsRetFix:	; fix up the ptr with NULL
	ld	a, #CH_NULL
	ld	(hl), a

_nlsRet:	; restore hl, return
	pop	hl
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; NextToken
;	advance hl to the next non-whitespace character after a null
U_NextToken::
	; advance to next NULL
	ld	a, (hl)
	cp	#CH_NULL	; check if it's null
	jr	z, _nxt2
	inc	hl		; next character
	jr	U_NextToken	; do it again


_nxt2:
	; it's now pointing to a null
	inc	hl 		; advance it by one

	; skip over spaces
	ld	a, (hl)
	cp	#CH_SPACE
	jr	nz, _nxtRet	; not a space, just return
	jr	_nxt2		; next character, do it again

_nxtRet:
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; IsNextToken
;	HL MUST point to the string in-parse
;	returns 0 if no more tokens, non zero if there's another (in 'a')
U_IsNextToken::
	push	hl
	call	U_NextToken
	; we're either pointing at a NULL or a character
	; either way, we have our return values.
	pop	hl
	ret

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

