; Strings
;          Various string utility functions
;
;          2017 Scott Lawrence
;
;  This code is free for any use. MIT License, etc.

	.module Strings

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
