; Lloader
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
; RST 08 - println( "\r\n" );
.org 0x0008 	; send out a newline
PrintNL:
	ld	hl, #str_crlf	; set up the newline string
	jr	Print		

str_crlf:
	.byte 	0x0d, 0x0a, 0x00	; "\r\n"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; RST 10 - println( (hl) );
.org 0x0010
; print
;  hl should point to an 0x00 terminated string
;  this will send the string out through the ACIA
Print:
	push	af
to_loop:
	ld	a, (hl)		; get the next character
	cp	#0x00		; is it a NULL?
	jr	z, termz	; if yes, we're done here.
	out	(TermData), a	; send it out.
	inc	hl		; go to the next character
	jr	to_loop		; do it again!
termz:
	pop	af
	ret			; we're done, return!

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
.org 0x0028

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
; E000 - FFFF 	RAM	RAM	RAM
; C000 - DFFF	RAM	RAM	RAM
; A000 - BFFF	RAM	RAM	RAM
; 8000 - 9FFF	RAM	RAM	RAM
; 6000 - 7FFF	RAM		RAM
; 4000 - 5FFF	RAM		RAM
; 2000 - 3FFF	ROM	ROM	RAOM
; 0000 - 1FFF	ROM	ROM	RAOM

STACK 	= 0xF800

USERRAM = 0xF802
LASTADDR = USERRAM + 1


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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

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

	; and run the main menu
	jp	MenuMain

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


str_prompt:
	.asciz  "LL> "

str_menu:
	.ascii	"== Menu ==\r\n"
	.ascii	"  [B] boot.hex\r\n"
	.ascii	"  [C] cpm.hex\r\n"
	.ascii	"  [3] basic32.hex\r\n"
	.ascii	"  [5] basic56.hex\r\n"
	.ascii  "\r\n"
	.ascii	"  [A] applications\r\n"
	.ascii	"  [F] files\r\n"
	.ascii	"  [R] ROM\r\n"
	.ascii	"  [D] debug\r\n"
.if( Emulation )
	.ascii	"  [Q] quit emulator\r\n"	; should remove for burnable ROM
.endif
	.ascii	"  [?] print menu\r\n"
	.byte	0x00

	;;;;;;;;;;;;;;;;;;;;	
	; display menu, get command
MenuMain:
	ld	hl, #str_menu
	call	Print

MM_prompt:
	call	PrintNL
	ld	hl, #str_prompt
	call	Print

	call	GetCh		; get user input
	call	PutCh		; echo it out
	call	PrintNL

	; handle the passed in byte...

		; General commands
	cp	#'?		; '?' - help
	jp	z, MenuMain


	cp	#'3
	call	z, DoBootBasic32

	cp	#'5
	call	z, DoBootBasic56

	call	ToUpper

	cp	#'C
	call	z, DoBootCPM

.if( Emulation )
	cp	#'Q		; 'Q' - quit the emulator
	jp	z, Quit
.endif

	cp	#'B
	call 	z, DoBoot


	cp	#'A
	call	z, MenuApps

	cp	#'F
	call	z, MenuFiles

	cp	#'R
	call	z, MenuROM

	cp	#'D
	call	z, MenuDebug

	jr	MM_prompt

	; helper to return with a==0
ClrARet:
	xor	a
	ret


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
str_menuD: ;Debug Menu
	.ascii  "== Debug ==\r\n"
	.ascii	"  [E] examine memory\r\n"
	.ascii	"  [P] poke memory\r\n"
	.ascii  "  [I] in from port\r\n"
	.ascii  "  [O] out to port\r\n"
	.ascii	"  [X] exit this menu\r\n"
	.byte	0x00

str_MDprompt:
	.asciz	"DBG "

MenuDebug:
	ld	hl, #str_menuD
	call	Print
MD_prompt:
	call	PrintNL
	ld	hl, #str_MDprompt
	call	Print
	ld	hl, #str_prompt
	call	Print

	call	GetCh
	call	PutCh
	call	PrintNL

	cp	#'?
	jp	z, MenuDebug

	call	ToUpper

	cp	#'X
	jp	z, ClrARet

	cp	#'E
	call	z, ExaMem

	cp	#'P
	call	z, PokeMemory

	cp	#'I
	call	z, InPort

	cp	#'O
	call	z, OutPort

	jr	MD_prompt

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
str_menuR: ; ROM menu
	.ascii  "== ROM ==\r\n"
	.ascii	"  [S] show RAM/ROM config\r\n"
	.ascii	"  [C] copy ROM to RAM\r\n"
	.ascii	"  [D] disable ROM\r\n"
	.ascii	"  [E] enable ROM\r\n"
	.ascii	"  [X] exit this menu\r\n"
	.byte	0x00

str_MRprompt:
	.asciz	"ROM "

MenuROM:
	ld	hl, #str_menuR
	call	Print
MR_prompt:
	call	PrintNL
	ld	hl, #str_MRprompt
	call	Print
	ld	hl, #str_prompt
	call	Print

	call	GetCh
	call	PutCh
	call	PrintNL

	cp	#'?
	jp	z, MenuROM

	call	ToUpper

	cp	#'X
	jp	z, ClrARet

	cp	#'S
	call 	z, ShowMemoryMap

	cp	#'C
	call	z, CopyROMToRAM

	cp	#'D
	call	z, DisableROM

	cp	#'E
	call	z, EnableROM

	jr	MR_prompt


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

str_menuF: 
	.ascii  "== Files ==\r\n"
	.ascii  "  [D] directory listing\r\n"
	.ascii	"  [I] SD info\r\n"
	.ascii  "  [R] SD:readme.txt\r\n"
	.ascii	"  [X] exit this menu\r\n"
	.byte	0x00

str_FILEprompt:
	.asciz	"FILE "

MenuFiles:
	ld	hl, #str_menuF
	call	Print
MF_prompt:
	call	PrintNL
	ld	hl, #str_FILEprompt
	call	Print
	ld	hl, #str_prompt
	call	Print

	call	GetCh
	call	PutCh
	call	PrintNL

	cp	#'?
	jp	z, MenuFiles

	call	ToUpper

	cp	#'X
	jp	z, ClrARet

	cp	#'D
	call	z, directoryList

	cp	#'R
	call	z, catReadme

	cp	#'I
	call	z, sdInfo

	jr	MF_prompt

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
str_menuA:
	.ascii  "== Applications ==\r\n"
	.ascii  "  [T] terminal $C0\r\n"
	.ascii	"  [X] exit this menu\r\n"
	.byte	0x00

str_Aprompt:
	.asciz	"PORT "

MenuApps:
	ld	hl, #str_menuA
	call	Print
MA_prompt:
	call	PrintNL
	ld	hl, #str_Aprompt
	call	Print
	ld	hl, #str_prompt
	call	Print

	call	GetCh
	call	PutCh
	call	PrintNL

	cp	#'?
	jp	z, MenuApps

	call	ToUpper

	cp	#'X
	jp	z, ClrARet	; exit. return

	cp 	#'T
	call	z, TerminalApp

	jr	MA_prompt


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.if( Emulation )
	;;;;;;;;;;;;;;;
	; quit from the rom (halt)
Quit:
	ld	a, #0xF0	; F0 = flag to exit
	out	(EmulatorControl), a
	halt			; rc2014sim will exit on a halt
.endif

	;;;;;;;;;;;;;;;
	; show sysinfo subroutine
ShowSysInfo:
	ld	hl, #str_splash
	call	Print

	xor	a
	ret



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; CopyROMToRAM
;	copies $0000 thru $2000 to itself
;	seems like it would do nothing but it's reading from 
;	the ROM and writing to the RAM
;	Not sure if this is useful, but it's a good test.
CopyROMToRAM:
	ld	hl, #str_Working
	call	Print

	xor	a
	ld	h, a
	ld	l, a	; HL = $0000
CR2Ra:
	ld	a, (hl)
	ld	(hl), a	; RAM[ hl ] = ROM[ hl ]

	inc	hl	; hl++
	ld	a, h	; a = h
	cp	#0x20	; is HL == 0x20 0x00?
	jr	nz, CR2Ra

	; now patch the RAM image of the ROM so if we reset, it will
	; continue to be in RAM mode...
	ld	hl, #ColdBoot	; 0x3E  (ld a,      )
	inc	hl		; 0x00	(    , #0x00)
	ld	a, #0x01	; disable RAM value
	ld	(hl), a		; change the opcode to  "ld a, #0x01"
	
	; we're done. return
	ld	hl, #str_Done
	call	Print
	xor	a
	ret


; DisableROM
;	set the ROM disable flag
DisableROM:
	ld	a, #01
	out	(RomDisable), a
	xor	a
	ret


; EnableROM
;	clear the ROM disable flag
EnableROM:
	xor	a
	out	(RomDisable), a
	xor	a
	ret


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

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
	jr	nz, bootloop	; make sure we have something loaded
	ld	hl, #str_nofile	; print out an error message
	call	Print

	xor	a
	ret
	

bootloop:
	in	a, (SDStatus)
	and	#DataReady	; more bytes to read?
	jp	z, LoadDone	; nope. exit out
	
	in	a, (SDData)	; get the file data byte
	ld	(hl), a		; store it out
	inc	hl		; next position
	
	; uncomment if you want dots printed while it loads...
	  ld	a, #0x2e	; '.'
	  call	PutCh		; send it out

	jp	bootloop	; and do the next byte


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
	.ascii	"  v011 2016-Oct-23  Scott Lawrence\r\n"
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

str_Working:
	.asciz	"Working.."

str_Done:
	.asciz	"..Done!\r\n"

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



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; functionality includes

.include "memprobe.asm"
.include "examine.asm"
.include "poke.asm"
.include "ports.asm"
.include "input.asm"
.include "print.asm"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
