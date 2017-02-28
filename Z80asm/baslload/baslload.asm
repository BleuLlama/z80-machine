; Lloader for BASIc integration
;
;  A simple HEX file loader, and file lister (through console backchannel file access)
;

.include "../Common/hardware.asm"

        .module BASIC_USR
.area   .CODE (ABS)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; these two are safe for loading CP/M and should be 
; so way high up that they won't interfere with
; the BASIC program in memory... which only needs
; to be around until we're running, so it doesn't
; matter much.  BASIC is just a springbord to get 
; into here!
;
STACK	= 0xC000		; new stack pointer (goes down towards B000)
USERRAM = 0xB000		; user ram starts here



LBUF    = USERRAM       ; line buffer for the shell
LBUFLEN = 100
LBUFEND = LBUF + LBUFLEN

LASTADDR = LBUFEND + 1

        CH_NULL  = 0x0
        CH_BELL  = 0x07
        CH_NL    = 0x0A
        CH_CR    = 0x0D
        CH_SPACE = 0x20
        CH_TAB   = 0x09

        CH_BS    = 0x08
        CH_COLON = 0x3a
        CH_DEL   = 0x7F

        CH_CTRLU = 0x15

        CH_PRLOW = 0x20
        CH_PRHI  = 0x7E

CBUF = LASTADDR         ; buffer for calling a function pointer
NEXTRAM = CBUF+6



Emulation = 1

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.org	0xC000		; make sure that this lines up with the Makefile

usr:
	di			; don't want to muck about with the ROM...

	ld	a, #'O
	call	PutCh

	ld	sp, #STACK	; since we're in our own thing, and don't care to
				; return to BASIC, let's set up a new stack
			
	ld	a, #'k
	call	PutCh
	ld	a, #'.
	call	PutCh
	call	PrintNL

splash:
	ld	hl, #str_Splash
	call	PrintLn

Shell:
	call	ClearLine
	call	GetLine
	call	ProcessLine
	jr	Shell


Exit:
	call	ExitEmulation
	ei
	ret


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; shell handler routines


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; command list

; this is a list of pointers to a structure of 3 elements.
;   0    word    flags 
;   2    word    char * - address of zero-terminated string of function name
;   4    word    void (*fcn)(void) - address of handler function to call

CMDEntry        = 0x0001        ; command to use
CMDEnd          = 0x0000        ; all zeroes. important
CMDTop		= 0x0003

CmdTable:
        .word   CMDEntry, cHelp, fHelp           ; 'help'
        .word   CMDEntry, cHelp2, fHelp          ; '?'
.if( Emulation )
        .word   CMDEntry, cQuit, fQuit           ; 'quit'
        .word   CMDEntry, cQuit2, fQuit          ; 'quit'
.endif
        .word   CMDEnd, 0, fWhat                     ; (EOL, bad cmd)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; help
cHelp:  .asciz  "help"
cHelp2: .asciz  "?"
fHelp:
	ld	hl, #str_help
	call	Print
	ret

str_help:
	.ascii "cmds:  "
.if( Emulation )
	.ascii "quit "
.endif
	.ascii	"help ? :HEX\r\n"
	.asciz	"\r\n"



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.if( Emulation )
; 'quit' - quit out of the emulation
cQuit:  .asciz  "quit"
cQuit2: .asciz  "q"
fQuit:
	call	ExitEmulation
        halt                    ; rc2014sim will exit on a halt
.endif


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; unknown command
;       this stub is called as the function when no other matche

fWhat:
        ld      hl, #str_What
        call    Print
        ret

str_What:
        .asciz  "What?\r\n"



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; process the line in memory
ProcessLine:
        ; check for empty
        ld      hl, #LBUF
        ld      a, (hl)
        cp      #CH_NULL
        ret     z

        ; check for Intel Hex input/paste
        cp      a, #CH_COLON
        jp      z, ProcessHex

        ; okay. first, let's kick off the strtok style processing
        call    U_NullSpace     ; replaces first space with a null


; test for now. iterate over the list
        ld      hl, #CmdTable   ; command list is structured:
                                ; 00 word       int     flags (0000 for end)
                                ; 02 word       char *  command
                                ; 04 word       void (*fcn)( void )
__plLoop:
        ; check for end of table
        push    hl
        call    DerefHL
        call    IsHLZero
        pop     hl
        cp      a, #0x00
        jr      z, __plLaunch   ; entry was not found, launch "what?"

        ; we can continue...
        push    hl              ; save current table position

        ; check for command-only
        cp      a, #0x01        ; command
        jr      nz, __plNext    ; skip if not a command


        ; work with the table item

        ; make HL point to the "command" we're checking
        ld      bc, #0x0002
        add     hl, bc          ; hl = command name

        call    DerefHL         ; dereference the string

        ; make DE point to the typed command
        ld      de, #LBUF
        call    U_Streq         ; "command" == typed?
        cp      #0x00           ; equal?
        jr      nz, __plNext    ; nope

        ; yep!
        pop     hl              ; hl points to the complete structure now
        jr      __plLaunch

        ; advance to the next item
__plNext:
        pop     hl              ; restore hl
        ld      bc, #0x06
        add     hl, bc
        jr      __plLoop

        ; launch the item!
        ; we enter here with just the ret stack
        ; hl = structure pointer
__plLaunch:
        call    PrintNL         ; end the current line
        call    PrintNL         ; add a space
        ld      bc, #0x04
        add     hl, bc          ; point hl at the function pointer
        call    DerefHL         ; point hl at the function!
        ; this looks weird, but it works.  we're basically doing a jump
        ; to the support function.  We're using the 'ret' mechanism to
        ; do this.  ret will set SP to the top value on the stack and
        ; pop it. so essentially this is:  "jp hl"
        push    hl
        ret


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
ProcessHex:
	rst	0
	; fly code into here
	ret


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; strings

str_Splash:	.ascii	"Lloader  v0.01 (c)2017 \r\n"
		.asciz	"  Scott Lawrence - yorgle@gmail.com"


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; other things
.include "rc2014hw.asm"
.include "linebuf.asm"
.include "string.asm"
.include "pointers.asm"
