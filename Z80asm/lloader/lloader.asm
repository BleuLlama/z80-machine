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
	call	z, catFile

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

str_Working:
	.asciz	"Working.."

str_Done:
	.asciz	"..Done!\r\n"

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
	  out	(TermData), a	; send it out.

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
str_filereadme:
	.asciz 	"~0:FR readme.txt\n"

catFile:
	ld	hl, #str_filereadme; select file
	call	SendSDCommand

catSDPort:
	ld	hl, #str_line
	call	Print

CF0:
	; check for more bytes
	in	a, (SDStatus)
	and	#DataReady	; more bytes to read?
	jr	z, CFRet 	; nope. exit out
	
	; load a byte from the file, print it out
	in	a, (SDData)	; get the file data byte
	cp	#0x00		; received null...
	call	z, CFNull	; nulls become newlines for dir listings
	out	(TermData), a	; send it out.
	;ld	(hl), a		; store it out

	inc	hl		; next position
	jr	CF0		; repeat

CFNull:
	push	hl
	call	PrintNL
	pop	hl
	ret

CFRet:
	ld	hl, #str_line
	call	Print

	xor	a
	ret
	


directoryList:
	ld	hl, #cmd_directory
	call	SendSDCommand
	jr	catSDPort	; pretend it's a cat'd file!


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Text strings

; Version history
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
	.ascii	"  v009 2016-Oct-11  Scott Lawrence\r\n"
	.asciz  "\r\n"
	
cmd_getinfo:
	.asciz  "~0:I\n"

cmd_bootfile:
	.asciz	"~0:FR ROMs/boot.hex\n"

cmd_bootCPM:
	.asciz	"~0:FR ROMs/cpm.hex\n"

cmd_bootBasic32:
	.asciz	"~0:FR ROMs/basic32.hex\n"

cmd_bootBasic56:
	.asciz	"~0:FR ROMs/basic56.hex\n"

str_loaded:
	.asciz 	"Done loading. Restarting...\n\r"

str_nofile:
	.asciz	"Couldn't load hex file.\n\r"

str_line:
	.asciz	"--------------\n\r"

cmd_directory:
	.asciz	"~0:PL \n"


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; functionality includes

.include "memprobe.asm"
.include "examine.asm"
.include "poke.asm"
.include "ports.asm"
.include "input.asm"
.include "print.asm"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
