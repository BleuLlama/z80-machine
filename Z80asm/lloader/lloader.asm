; Lloader
;          Core Rom Loader for RC2014-LL
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
	jr	MenuMain

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

str_prompt:
	.asciz  "LL> "

str_menu:
	.ascii	"== Main ==\r\n"
	.ascii	"  [B]oot options \r\n"
	.ascii  "  [D]iagnostics\r\n"
	.ascii	"  [M]emory\r\n"
	.ascii	"  [P]ort IO\r\n"
.if( Emulation )
	.ascii	"  [Q]uit emulator\r\n"	; should remove for burnable ROM
.endif
	.ascii	"  [?] for menu\r\n"
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

	call	ToUpper

.if( Emulation )
	cp	#'Q		; 'Q' - quit the emulator
	jp	z, Quit
.endif

	cp	#'B
	call	z, MenuBoot

	cp	#'D
	call	z, MenuDiags

	cp	#'M
	call	z, MenuMemory

	cp	#'P
	call	z, MenuPorts

	jr	MM_prompt

	; helper to return with a==0
ClrARet:
	xor	a
	ret


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
str_menuD: ;Diag Menu
	.ascii  "== Diagnostics ==\r\n"
	.ascii	"  [S]ystem info\r\n"
	;.ascii	"  [M]emory Test\r\n"
	.ascii	"  [C]opy ROM to RAM\r\n"
	.ascii	"  [D]isable ROM (64k RAM)\r\n"
	.ascii	"  [E]nable ROM (56k RAM)\r\n"
	.ascii	"  [F]ile SD tests\r\n"
	.ascii	"  [X]it this menu\r\n"
	.byte	0x00

str_MDprompt:
	.asciz	"DIAG "

MenuDiags:
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
	jp	z, MenuDiags

	call	ToUpper

	cp	#'X
	jp	z, ClrARet

	cp	#'S		; 'S' - sysinfo
	call 	z, ShowSysInfo

	cp	#'C
	call	z, CopyROMToRAM

	cp	#'D
	call	z, DisableROM

	cp	#'E
	call	z, EnableROM

	cp	#'F 		; ??? maybe make a file menu
	call	z, MenuFile

	jr	MD_prompt

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
str_menuF: ; File menu
	.ascii  "== Files ==\r\n"
	.ascii	"  [C]at test.txt\r\n"
	.ascii	"  [D]irectory list\r\n"
	.ascii	"  [X]it this menu\r\n"
	.byte	0x00

str_MFprompt:
	.asciz	"FILE "

MenuFile:
	ld	hl, #str_menuF
	call	Print
MF_prompt:
	call	PrintNL
	ld	hl, #str_MFprompt
	call	Print
	ld	hl, #str_prompt
	call	Print

	call	GetCh
	call	PutCh
	call	PrintNL

	cp	#'?
	jp	z, MenuFile

	call	ToUpper

	cp	#'X
	jp	z, ClrARet

	cp	#'C
	call	z, catFile

	cp	#'D
	call	z, directoryList

	jr	MF_prompt


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

str_menuM: ;mem and ports
	.ascii  "== Memory ==\r\n"
	.ascii  "  [E]xamine memory\r\n"
	.ascii  "  [P]oke memory\r\n"
	.ascii	"  [X]it this menu\r\n"
	.byte	0x00

str_MEMprompt:
	.asciz	"MEM "

MenuMemory:
	ld	hl, #str_menuM
	call	Print
Mem_prompt:
	call	PrintNL
	ld	hl, #str_MEMprompt
	call	Print
	ld	hl, #str_prompt
	call	Print

	call	GetCh
	call	PutCh
	call	PrintNL

	cp	#'?
	jp	z, MenuMemory

	call	ToUpper

	cp	#'X
	jp	z, ClrARet

	cp	#'E		; examine memory (hex dump)
	call	z, ExaMem

	cp	#'P
	call	z, PokeMemory

	jr	Mem_prompt

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
str_menuP:
	.ascii  "== Port IO ==\r\n"
	.ascii  "  [I]nput from a port\r\n"
	.ascii  "  [O]utput to a port\r\n"
	.ascii  "  [T]erminal interface\r\n"
	.ascii	"  [X]it this menu\r\n"
	.byte	0x00

str_MPprompt:
	.asciz	"PORT "

MenuPorts:
	ld	hl, #str_menuP
	call	Print
MP_prompt:
	call	PrintNL
	ld	hl, #str_MPprompt
	call	Print
	ld	hl, #str_prompt
	call	Print

	call	GetCh
	call	PutCh
	call	PrintNL

	cp	#'?
	jp	z, MenuPorts

	call	ToUpper

	cp	#'X
	jp	z, ClrARet	; exit. return

	cp	#'I
	call	z, InPort

	cp	#'O
	call	z, OutPort

	cp 	#'T
	call	z, TerminalApp

	jr	MP_prompt


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
str_menuB: ;boot options
	.ascii  "== Boot ==\r\n"
	.ascii	"  [B]oot\r\n"
	.ascii	"  [3]2k basic.32.rom\r\n"
	.ascii	"  [5]6k basic.56.rom\r\n"
	.ascii	"  [X]it this menu\r\n"
	.byte	0x00

str_BOprompt:
	.asciz	"BOOT "

MenuBoot:
	ld	hl, #str_menuB
	call	Print
MB_prompt:
	call	PrintNL
	ld	hl, #str_BOprompt
	call	Print
	ld	hl, #str_prompt
	call	Print

	call	GetCh
	call	PutCh
	call	PrintNL

	cp	#'?
	jp	z, MenuBoot

	cp	#'3		; '3' - basic32.rom
	call	z, DoBootBasic32

	cp	#'5		; '5' - basic56.rom
	call	z, DoBootBasic56

	call	ToUpper

	cp	#'X
	jp	z, ClrARet

	cp	#'B		; 'B' - Boot.
	call 	z, DoBoot

	cp	#'i		; '2' - iotest.rom
	call	z, DoBootIotest

	jr	MB_prompt


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

	call	ShowMemoryMap	; show the memory map

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

DoBootBasic32:
	ld	hl, #cmd_bootBasic32
	jr	DoBootB	

DoBootBasic56:
	ld	hl, #cmd_bootBasic56
	jr	DoBootB	

DoBootIotest:
	ld	hl, #cmd_bootIotest
	jr	DoBootB	

	;;;;;;;;;;;;;;;;;;;;	
	; 4. send the file request
DoBoot:
	ld	hl, #cmd_bootfile
DoBootB:
	call	SendSDCommand
	ld	hl, #cmd_bootread
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
        jp      0x00000         ; cold boot
endSwapOutRom:



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
str_filetest:
	.asciz 	"~Ftest.txt\n"

catFile:
	ld	hl, #str_filetest; select file
	call	SendSDCommand
	ld	hl, #cmd_bootread ; open for read
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
	ld	hl, #cmd_dirpath
	call	SendSDCommand

	ld	hl, #cmd_directory
	call	SendSDCommand
	jr	catSDPort	; pretend it's a cat'd file!


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Text strings

; Version history
;   v006 2016-07-07 - SD load and boot working again
;   v005 2016-06-16 - New menus?
;   v004 2016-06-11 - Hex dump of memory, in, out, poke
;   v003            - more options
;   v002 2016-05-10 - usability cleanups
;   v001 2016-05-09 - initial version, functional

str_splash:
	.ascii	"Lloader Shell for RC2014-LL\r\n"
	.ascii	"  v006 2016-July-07  Scott Lawrence\r\n"
	.asciz  "\r\n"
	
str_help:
	.ascii	"\r\n"
	.ascii  "==== ROM ====\r\n"

	;ascii  "  C for catalog\r\n"
	;ascii  "  H for hexdump\r\n"
	;ascii  "  0-9 for 0.rom, 9.rom\r\n"
	.byte 	0x00

cmd_bootfile:
	.asciz	"~FROMs/boot.rom\n"

cmd_bootBasic32:
	.asciz	"~FROMs/basic.32.rom\n"

cmd_bootBasic56:
	.asciz	"~FROMs/basic.56.rom\n"

cmd_bootIotest:
	.asciz	"~FROMs/iotest.rom\n"

cmd_bootread:
	.asciz	"~R\n"

cmd_bootsave:
	.asciz	"~S\n"

str_loaded:
	.asciz 	"Done loading. Restarting...\n\r"

str_nofile:
	.asciz	"Couldn't load specified rom.\n\r"

str_line:
	.asciz	"--------------\n\r"

cmd_dirpath:
	.asciz	"~DROMs\n"

cmd_directory:
	.asciz	"~L\n"


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; functionality includes

.include "memprobe.asm"
.include "examine.asm"
.include "poke.asm"
.include "ports.asm"
.include "input.asm"
.include "print.asm"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
