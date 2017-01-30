; Lloader 2
;          Core Rom Loader for RC2014-LL / MicroLlama 5000
;
;          2016-05-09 Scott Lawrence
;
;  This code is free for any use. MIT License, etc.
;
; this ROM loader isn't meant to be the end-all, be-all, 
; it's just something that can easily fit into the 
; boot ROM, that can be used to kick off another, better
; ROM image.

	.module Lloader

.area	.CODE (ABS)

.include "../Common/hardware.asm"	; hardware definitions


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Code configuration

; set to 1 if we're building emulation version of the ROM
Emulation = 1

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; initial entry point

; RST 00 - Cold Boot
.org 0x0000			; start at 0x0000
	di			; disable interrupts
	jp	ColdBoot	; and do the stuff

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; RST 08 ; unused
.org 0x0008 


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; RST 10 ; unused
.org 0x0010

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; RST 20 - send out string to SD drive
.org 0x0020
	
SendSDCommand:
	ld	a, (hl)		; get the next character
	cp	#0x00		; is it a null?
	jr	z, sdz		; if yes, we're done
	out	(SDData), a	; send it out
	inc	hl		; next character
	jr	SendSDCommand	; do it again
sdz:
	ret			; we're done, return!

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; RST 28 - unused
.org 0x0030

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; RST 30 - unused
.org 0x0030

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; RST 38 - Interrupt handler for console input
.org 0x0038
    	reti


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; memory maps of possible hardware...
;  addr   	SBC	2014	LL

; 0000 - 1FFF	ROM	ROM	RAOM (switchable)
; 2000 - 3FFF	ROM	ROM	RAOM (switchable)
;
; 4000 - 5FFF	RAM		RAM
; 6000 - 7FFF	RAM		RAM
;
; 8000 - 9FFF	RAM	RAM	RAM
; A000 - BFFF	RAM	RAM	RAM
; C000 - DFFF	RAM	RAM	RAM
; E000 - FFFF 	RAM	RAM	RAM


; We'll use the ram chunk at 8000-$8FFF for our user stuff
STACK 	= 0x9000	; Stack starts here and goes down

USERRAM = 0x8000	; User ram starts here and goes up

LBUF    = USERRAM	; line buffer for the shell
LBUFLEN = 100
LBUFEND = LBUF + LBUFLEN

LASTADDR = LBUFEND + 1

	CH_NULL	 = 0x0
	CH_BELL	 = 0x07
	CH_NL	 = 0x0A
	CH_CR	 = 0x0D
	CH_SPACE = 0x20
	CH_TAB   = 0x09

	CH_BS    = 0x08
	CH_DEL   = 0x7F

	CH_CTRLU = 0x15

	CH_PRLOW = 0x20
	CH_PRHI  = 0x7E

CBUF = LASTADDR		; buffer for calling a function pointer
NEXTRAM = CBUF+6

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; console io routines

GetCh:
	in	a, (TermStatus)	; ready to read a byte?
	and	#DataReady	; see if a byte is available

	jr	z, GetCh	; nope. try again
	in	a, (TermData)	; get it!
	ret

ToUpper:
	and	#0xDF		; make uppercase (mostly)
	ret

PutCh:
	out	(TermData), a	; echo
	ret

KbHit:
	in	a, (TermStatus)
	and	#DataReady
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; ColdBoot - the main code block
ColdBoot:
	; setup ROM/RAM config
	ld	a, #0x00	; bit 0, 0x01 is ROM Disable
				; = 0x00 -> ROM is enabled
				; = 0x01 -> ROM is disabled
	out	(RomDisable), a	; restore ROM to be enabled

	ld	sp, #STACK	; setup a stack pointer valid for all

	; Misc Subsystem one-time setup
	call	ExaInit

	; display startup splash
	call	PrintNL
	ld	hl, #str_splash
	call	Print

	; initialize any subapps
	call	ExaInit

	; and run the main menu
	jp	Shell

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


; the main shell loop
Shell:
	call	ClearLine
	call	Prompt
	call	GetLine
	call	ProcessLine
	jr	Shell


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; shell handler routines

; process the line in memory
ProcessLine:
	; check for empty
	ld	hl, #LBUF
	ld	a, (hl)
	cp	#CH_NULL
	ret	z

	; okay. first, let's kick off the strtok style processing
	call 	U_NullSpace	; replaces first space with a null


; test for now. iterate over the list
	ld	hl, #CmdTable	; command list is structured:
				; 00 word	int     flags (0000 for end)
				; 02 word	char *  command
				; 04 word  char *  info
				; 06 word 	void (*fcn)( void )
__plLoop:
	; check for end of table
	push	hl
	call 	DerefHL
	call	IsHLZero
	pop	hl
	cp	a, #0x00
	jr	z, __plLaunch	; entry was not found, launch "what?"

	; we can continue...
	push	hl		; save current table position

	; check for command-only
	cp	a, #0x01	; command
	jr	nz, __plNext	; skip if not a command


	; work with the table item

	; make HL point to the "command" we're checking
	ld	bc, #0x0002
	add	hl, bc		; hl = command name
	call	DerefHL		; dereference the string

	; make DE point to the typed command
	ld	de, #LBUF
	call	U_Streq		; "command" == typed?
	cp	#0x00		; equal?
	jr	nz, __plNext	; nope

	; yep!
	pop	hl		; hl points to the complete structure now
	jr	__plLaunch

	; advance to the next item
__plNext: 
	pop	hl		; restore hl
	ld	bc, #0x08
	add	hl, bc
	jr	__plLoop	

	; launch the item!
	; we enter here with just the ret stack
	; hl = structure pointer
__plLaunch:
	call	PrintNL		; end the current line
	call	PrintNL		; add a space
	ld	bc, #0x06
	add	hl, bc		; point hl at the function pointer
	call	DerefHL		; point hl at the function!
	; this looks weird, but it works.  we're basically doing a jump
	; to the support function.  We're using the 'ret' mechanism to
	; do this.  ret will set SP to the top value on the stack and
	; pop it. so essentially this is:  "jp hl"
	push	hl
	ret


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; display the shell prompt
str_prompt:
	.asciz  "L2> "
Prompt:
	call	PrintNL
	ld	hl, #str_prompt
	call	Print
	ret
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; command list

; this is a list of pointers to a structure of 3 elements.
;	word	flags 
;	word	char * - address of zero-terminated string of function name
;	word	char * - address of zero-terminated info string
;	word	void (*fcn)(void) - address of handler function to call

CMDEntry	= 0x0001	; command to use
CMDHeader	= 0x0002	; just a header. skip for command lists
CMDEnd		= 0x0000	; all zeroes. important

CmdTable:
	.word	CMDHeader, cHSys, 0, 0
	.word	CMDEntry, cArgs, iArgs, fArgs		; 'args'
	.word	CMDEntry, cHelp, iHelp, fHelp		; 'help'
	.word	CMDEntry, cHelp2, iHelp, fHelp		; '?'
	.word	CMDEntry, cVer, iVer, fVer		; 'ver'
.if( Emulation )
	.word	CMDEntry, cQuit, iQuit, fQuit		; 'quit'
.endif

	.word	CMDHeader, cHApps, 0, 0
	.word	CMDEntry, cGo, iGo, fGo			; 'go'
	.word	CMDEntry, cTerm, iTerm, fTerm		; 'term'

	.word	CMDHeader, cHPort, 0, 0
	.word	CMDEntry, cIn, iIn, fIn			; 'in'
	.word	CMDEntry, cOut, iOut, fOut		; 'out'

	.word	CMDHeader, cHRAM, 0, 0
	.word	CMDEntry, cExa, iExa, fExa		; 'exa"
	.word	CMDEntry, cMMap, iMMap, fMMap		; 'mmap'
	.word	CMDEntry, cPoke, iPoke, fPoke		; 'poke"

	.word	CMDHeader, cHROM, 0, 0
	.word	CMDEntry, cRom2Ram, iRom2Ram, fRom2Ram	; 'rom2ram'
	.word	CMDEntry, cRomDis, iRomDis, fRomDis	; 'romdis'
	.word	CMDEntry, cRomEn, iRomEn, fRomEn	; 'romen'

	.word	CMDEnd, 0, 0, fWhat			; (EOL, bad cmd)

cHSys:	.asciz	"--- System ---"
cHApps:	.asciz	"--- Applications ---"
cHPort:	.asciz	"--- Port I/O Utils ---"
cHRAM:	.asciz	"--- RAM Utils ---"
cHROM:	.asciz	"--- ROM Utils ---"


; arbitrary ram go

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 'help'

cHelp: 	.asciz	"help"
cHelp2:	.asciz	"?"
iHelp: 	.asciz	"Get help on Lloader2"
fHelp:
	ld	hl, #str_help
	call	Print
	; iterate over the list

	ld	hl, #CmdTable
	push	hl		; start with the stored HL at the cmd table

__fhLoop:
	pop	hl
	push	hl		; restore HL

	; check for end of loops
	call 	DerefHL
	call	IsHLZero
	cp	#0x00
	jr	z, __fhRet

	; check what kind of entry it is
	cp	a, #0x01	; command entry
	jr	z, __fhCmd

	cp	a, #0x02	; header entry
	jr	z, __fhHdr

	jr	__fhNext	; Dunno. skip

__fhHdr:
	pop	hl
	push	hl		; restore HL
	ld	bc, #0x02	; ...
	add	hl, bc		; ... header text pointer
	call	DerefHL		; header tet
	call	PrintNL
	call	Print
	call	PrintNL
	jr	__fhNext	; continue on the next one

__fhCmd:
	; prefix the line
	ld	a, #CH_SPACE
	call	PutCh		; "   "
	call	PutCh
	call	PutCh

	; print the command name
	pop	hl
	push	hl		; restore HL
	ld	bc, #0x02	; ... 
	add	hl, bc		; ...command name ptr
	call 	DerefHL		; command name

	call	Print		; "   CMD"

	; add a bit of space
	ld	a, #CH_TAB
	call	PutCh
	ld	a, #CH_SPACE
	call	PutCh
	call	PutCh
	
	pop	hl
	push	hl		; restore HL
	ld	bc, #0x04
	add	hl, bc		; ...info ptr
	call	DerefHL		; info
	call	Print		; "   CMD\t   Info"

	call	PrintNL		; "   CMD\t   Info\n\r"
	
__fhNext:
	; advance stored HL to the next item
	pop	hl
	ld	bc, #0x0008
	add	hl, bc
	push	hl
	jr	__fhLoop

__fhRet:
	pop	hl		; restore the stack
	ret
	
str_pre:
	.asciz  "   "
str_help:
	.asciz	"List of available commands:\n\r"


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 'args' tester
;	print out all of the args
;	an example of using the NextToken and NullSpace "strtok" equivalent
cArgs:	.asciz	"args"
iArgs:	.asciz	"test display of args"
fArgs:
	ld	e, #'0		; printable argc
	call	__faCInc	; display and inc argc
	
	ld	hl, #LBUF	; restore the arg pointer to HL
	push	hl
	call	__printhl	; print the token
	pop	hl

__faLoop:
	call	U_NextToken	; go to the next token
	ld	a, (hl)
	cp	#CH_NULL	; end of the array?
	ret	z		; return if we're done with the string

	call	__faCInc	; display and inc argc

	call	U_NullSpace	; terminate the current token
	call	__printhl	; print the token

	jr	__faLoop	; repeat
	ret

__faCInc:
	ld	a, #'[
	call	PutCh

	ld	a, e
	call	PutCh
	inc	a
	ld	e, a

	ld	a, #']
	call	PutCh
	ld	a, #CH_SPACE
	call	PutCh
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; unknown command
;	this stub is called as the function when no other matche

fWhat:
	ld	hl, #0$
	call	Print
	ret

0$:
	.asciz	"What?\r\n"


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; ver

cVer:	.asciz	"ver"
iVer:	.asciz	"Display version information"
fVer:
	ld	hl, #str_splash
	call	Print
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.if 0
	call	z, DoBootBasic32
	call	z, DoBootBasic56
	call	z, DoBootCPM
	call 	z, DoBoot

	call	z, CopyROMToRAM
	call	z, DisableROM
	call	z, EnableROM

	call	z, directoryList
	call	z, catReadme
	call	z, sdInfo

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


	;;;;;;;;;;;;;;;
	; boot roms

DoBootCPM:
	ld	hl, #cmd_bootCPM
	jr	DoBootB	

DoBootBasic32:
	ld	hl, #cmd_bootBasic32
	jr	DoBootB	

DoBootBasic56:
	ld	hl, #cmd_bootBasic56
	jr	DoBootB	

	;;;;;;;;;;;;;;;;;;;;	
	; 4. send the file request
DoBoot:
	ld	hl, #cmd_bootfile
DoBootB:
	call	SendSDCommand


	;;;;;;;;;;;;;;;;;;;;	
	; 5. read the file to 0000
	ld 	hl, #0x0000	; Load it to 0x0000

	in	a, (SDStatus)
	and	#DataReady
	jr	nz, hexload	; make sure we have something loaded
	ld	hl, #str_nofile	; print out an error message
	call	Print

	xor	a
	ret
	

hexload:
	in	a, (SDStatus)
	and	#DataReady	; more bytes to read?
	jp	z, LoadDone	; nope. exit out
	
	in	a, (SDData)	; get the file data byte
	ld	(hl), a		; store it out
	inc	hl		; next position
	
	; uncomment if you want dots printed while it loads...
	;  ld	a, #'.
	  call	PutCh		; send it out

	; - need HEX

	jp	hexload		; and do the next byte


	;;;;;;;;;;;;;;;;;;;;
	; 6. Loading is completed.
LoadDone:
	ld	hl, #str_loaded
	call	Print

	;;;;;;;;;;;;;;;;;;;;
	; 7. Swap the ROM out
CopyLoc = 0xfff0        ; make sure there's enough space for the routine

        ;;;;;;;;;;;;;;;;;;;;
        ;  SwitchInRamRom
        ;       the problem is that we need to bank switch,
        ;       but once we do, this rom goes away.
        ;       so we need to pre-can some content

SwitchInRamRom:
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
        ld      a, #01          ; disable rom
        out     (RomDisable), a ; runtime bank sel
        jp      0x0000          ; cold boot
endSwapOutRom:


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; SD interface helpers

DrawHLine:
	ld	hl, #str_line
	call	Print
	ret

; RawCatFromSD
;  dump everything received in a response until
;  there's nothing left.  very dumb logic in here.
RawCatFromSD:
RCFSD0:
	; check for more bytes
	in	a, (SDStatus)
	and	#DataReady	; more bytes to read?
	ret	z	 	; nope. exit out
	
	; load a byte from the file, print it out
	in	a, (SDData)	; get the file data byte
	cp	#0x00		; received null...
	call	z, RCFSDNL	; nulls become newlines for dir listings
	out	(TermData), a	; send it out.

	inc	hl		; next position
	jr	RCFSD0		; repeat

RCFSDNL:
	push	hl
	call	PrintNL
	pop	hl
	ret

; do a raw dump of everything passed in
; and draw lines around it.
RawCatWithLines:
	call	DrawHLine
	call	RawCatFromSD
	call	DrawHLine
	ret

;; Mass storage helpers

MSToken_Unknown		= 0x00
MSToken_None		= 0x01
MSToken_EOF		= 0x02

MSToken_Path		= 0x10	; P  first byte of a PATH token
MSToken_PathBegin	= 0x11	;  B
MSToken_PathEnd		= 0x12	;  E
MSToken_PathDir		= 0x13	;  D
MSToken_PathFile	= 0x14	;  F

MSToken_File		= 0x20	; F  first byte of a FILE token
MSToken_FileBegin	= 0x21	;  B
MSToken_FileEnd		= 0x22	;  E
MSToken_FileString	= 0x23	;  S


; MSGetHeader
;	scans through to the current character being '='
;	rest of the line is still in the device, unread yet
;	a contains the token ID;
MSGetHeader:
	; read in a loop
	; 	(last b goes into c)
	;	(current char goes in b)
	;	until EOF	- return NONE
	; 	until '='	- check BC for code to return

	; clear variables
	xor	a
	ld	a, #'x
	ld 	b, a
	ld	c, a

	; get loop
MSGetLoop:
	; check for more bytes
	in	a, (SDStatus)
	and	#DataReady	; more bytes to read?
	jr	z, MSREOF	; end of file, return

	; we got one, check if it's an equals
        in      a, (SDData)     ; get the file data byte
	;out	(TermData), a
	cp	#'=		; is it an equals?
	jr	z, MSREquals
	
	ld 	d, a		; stash a into d temporarily

	; A (current) -> B (prev) -> C (oldest)
	ld	a, b		; copy B into C
	ld	c, a

	ld	a, d		; copy A (in D) into B
	ld	b, a

	jr	MSGetLoop	; and do it again

MSREOF:
	ld	a, #MSToken_EOF
	ret

	; optimally, this should probably be a lookup table.

MSREquals:
	ld	a, c		; check the maintoken
	cp	#'P		; path stuff
	jr	z, MSRP
	cp	#'F		; file stuff
	jr	z, MSRF
	ld	a, #MSToken_Unknown
	ret

MSRP:
	ld	a, b		; check the subtoken

	ld	c, #MSToken_PathBegin
	cp	#'B		; path begin
	jr 	z, MSRetC

	ld	c, #MSToken_PathEnd
	cp	#'E		; path end
	jr 	z, MSRetC

	ld	c, #MSToken_PathDir
	cp	#'D		; path dir
	jr 	z, MSRetC

	ld	c, #MSToken_PathFile
	cp	#'F		; path file
	jr 	z, MSRetC


	ld	a, #MSToken_Unknown
	ret

MSRF:
	ld	a, b		; check the subtoken

	ld	c, #MSToken_FileBegin
	cp	#'B		; file begin
	jr 	z, MSRetC

	ld	c, #MSToken_FileEnd
	cp	#'E		; file end
	jr 	z, MSRetC

	ld	c, #MSToken_FileString
	cp	#'S		; file string
	jr 	z, MSRetC

	ld	a, #MSToken_Unknown
	ret

MSRetC:
	ld	a, c		; token code is in 'C'
	ret


MSSkipToNewline:
	; check for more bytes
	in	a, (SDStatus)
	and	#DataReady	; more bytes to read?
	ret	z		; end of file

	; we got one, check if it's an equals
        in      a, (SDData)     ; get the file data byte
	cp	#'\r		; is it a newline
	cp	#'\n		; is it a newline
	ret	z	
	jr	MSSkipToNewline	; repeat


MSDecodeToNewline:
	xor	a
	ld	b, a		; b is our byte counter
	ld	c, a		; c gets our output value
	ld	d, a		; d gets our temp 'a' for adding

__deLoop:
	; check for more bytes
	in	a, (SDStatus)
	and	#DataReady	; more bytes to read?
	ret	z		; end of file

	; we got one, check if it's an equals
        in      a, (SDData)     ; get the file data byte
	cp	#'\r		; is it a newline
	cp	#'\n		; is it a newline
	ret	z

	; not a newline, do something with it

	; range of valid characters (ascii sorted)
	; '0'  '9'   'A'  'F'  	'a'  'f'
	; 0x30-0x39  0x41-0x46  0x61-0x66
	
	cp	#'0		; less than '0'? 
	jr	c, __deLoop	; yep, try again
	cp	#'9 +1		; between '0' and '9' inclusive?
	jr	c, __deDigit

	cp	#'A		; below 'A'?
	jr	c, __deLoop	; yep, try again
	cp	#'F +1		; between 'A' and 'F' inclusive?
	jr	c, __deUcChar

	cp	#'a		; below 'a'?
	jr	c, __deLoop	; yep, try again
	cp	#'f +1		; between 'a' and 'f' inclusive?
	jr	c, __deLcChar

	jr	__deLoop	; wasn't valid... repeat


__deDigit:
	sub	a, #'0		; '0'-'9' -> 0x00 - 0x09
	jr	__deConsume	; consume the nibble

__deLcChar:
	and	#0xDF		; make uppercase (mostly)
__deUcChar:
	sub	a, #'A		; 'A'-'F' -> 0x0A - 0x0F
	add	a, #0x0a

__deConsume:
	ld	d, a		; d=a

	ld	a, c		;
	sla	a
	sla	a
	sla	a
	sla	a		; a = a << 4
	add	a, d		; a = (a<<4) | newNib
	ld	c, a		; store aside the new value
	
	ld	a, b		; a = b
	inc	a		; next byte shifted in
	ld	b, a
	bit	#0, a

	jr	nz, __deLoop	; nothing we can use yet, get another

	ld	a, c		; restore the new accumulated value
	call	PutCh
	jr	__deLoop
	

; DecodeCatFromSD
;	take the data coming in, and based on the tag, do something:
;
;	 file:
;	FB	-> "File: " <parameter>
;	FS	-> decode( <parameter> )
;	FE	-> <parameter> " bytes"
;	 dir list
;	PB	-> "Listing of directory " <parameter>
;	PF	-> "File: " decode( <parameter> )
;	PD	-> " Dir: " decode( <parameter> )
;	PE	-> "Files, Dirs: " <parameter>
;	
DecodeCatFromSD:
	call	MSGetHeader
	;call	printByte

	; are we done?  If so, just return
	cp	#MSToken_EOF
	ret	z

	cp	#MSToken_PathFile
	jr	z, _DCFS_File

	cp	#MSToken_PathDir
	jr	z, _DCFS_Dir

	cp	#MSToken_FileString
	jr	z, _DCFS_Text

	; don't know what it was, just skip its data. 
	call	MSSkipToNewline

	; and repeat...
	jr	DecodeCatFromSD

	; filenames just get dumped as-is
_DCFS_File:
	ld	hl, #str_file		; file header
	call	Print			; print it
	call	MSDecodeToNewline	; decode the content
	call	PrintNL			; print a newline
	jr	DecodeCatFromSD		; continue to the next 

	; directory names get a slash appended
_DCFS_Dir:
	ld	hl, #str_dir		; dir header
	call	Print			; print it
	call	MSDecodeToNewline	; decode the content
	ld	a, #'/
	call	PutCh
	call	PrintNL			; print a newline
	jr	DecodeCatFromSD		; continue to the next 

	; text gets dumped verbatim
_DCFS_Text:
	call	MSDecodeToNewline	; decode the content
	jr	DecodeCatFromSD		; continue to the next 

; decode the data coming in,
; and draw lines around it.
DecodeCatWithLines:
	call	DrawHLine
	call	DecodeCatFromSD
	call	DrawHLine

	xor	a
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

sdInfo:
	ld	hl, #cmd_info

	call	SendSDCommand
	call	RawCatWithLines

	xor	a
	ret


catReadme:
	ld	hl, #str_filereadme; select file
	call	SendSDCommand
	call	DecodeCatWithLines

	xor	a
	ret


directoryList:
	ld	hl, #cmd_directory
	call	SendSDCommand
	call	DecodeCatWithLines

	xor	a
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Text strings

; Version history
;   v011 2016-10-23 - New decoder working for directory, files
;   v010 2016-10-13 - Working on Terminal, added ~I, Directory
;   v009 2016-10-11 - Internal support for hex, new SD interface
;   v008 2016-09-28 - Terminal fixed, new file io command strings
;   v007 2016-07-14 - Menu rearrange, better Hexdump
;   v006 2016-07-07 - SD load and boot working again
;   v005 2016-06-16 - New menus?
;   v004 2016-06-11 - Hex dump of memory, in, out, poke
;   v003            - more options
;   v002 2016-05-10 - usability cleanups
;   v001 2016-05-09 - initial version, functional

str_splash:
	.ascii	"Lloader Shell for RC2014/LL MicroLlama\r\n"
	.ascii	"  v020 2017-Jan-29  Scott Lawrence\r\n"
	.asciz  "\r\n"
	
cmd_getinfo:
	.asciz  "\n~0:I\n"

cmd_bootfile:
	.asciz	"\n~0:FR=ROMs/boot.hex\n"

cmd_bootCPM:
	.asciz	"\n~0:FR=ROMs/cpm.hex\n"

cmd_bootBasic32:
	.asciz	"\n~0:FR=ROMs/basic32.hex\n"

cmd_bootBasic56:
	.asciz	"\n~0:FR=ROMs/basic56.hex\n"

str_loaded:
	.asciz 	"Done loading. Restarting...\n\r"

str_nofile:
	.asciz	"Couldn't load hex file.\n\r"

str_line:
	.asciz	"--------------\n\r"

cmd_directory:
	.asciz	"\n~0:PL /\n"

cmd_info:
	.asciz	"\n~0:I\n"

str_filereadme:
	.asciz 	"~0:FR=readme.txt\n"

str_dir:
	.asciz 	"  Dir: "
str_file:
	.asciz 	" File: "
.endif

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Text strings

; Version history
;   v020 2017-01-21 - First Lloader2
;   v001 - v011     - Lloader 1 versions.

str_splash:
	.ascii	"Lloader2 Shell for RC2014/LL MicroLlama\r\n"
	.ascii	"  v020 2017-Jan-21  Scott Lawrence\r\n"
	.asciz  "\r\n"

str_Working:
	.asciz	"Working.."

str_Done:
	.asciz	"..Done!\r\n"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; functionality includes

.include "llhw.asm"
.include "memprobe.asm"
.include "examine.asm"
.include "poke.asm"
.include "ports.asm"
.include "input.asm"
.include "print.asm"
.include "utils.asm"
	.module Lloader ; END

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
