; Linebuf
;          Line buffer handler
;
;          2017 Scott Lawrence
;
;  This code is free for any use. MIT License, etc.

	.module Linebuf

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Line input routines

str_prompt:	.asciz "? "

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
