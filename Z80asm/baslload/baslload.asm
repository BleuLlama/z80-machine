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
				; so we're disabling all interrupts which
				; would bring us there...

	ld	a, #'O
	call	PutCh		; Self test output

	ld	sp, #STACK	; since we're in our own thing, and don't care to
				; return to BASIC, let's set up a new stack
			
	ld	a, #'k
	call	PutCh		; Self test output
	ld	a, #'.
	call	PutCh		; Self test output
	call	PrintNL		; Self test output

	; ""		something bad happened with disabling interrupts
	; "O"		Stack might be messed up
	; "Ok"		New stack worked once
	; "Ok.\n"	Stack and everything is AOK.

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
	.word	CMDEntry, cEnab, fEnab		; 'rom0000'
	.word	CMDEntry, cDisab, fDisab	; 'ram0000'
	.word	CMDEntry, cGo0, fGo0		; 'go0'
	.word	CMDEntry, cGoCPM, fGoCPM	; 'gocpm'
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
	.ascii "cmds:\r\n  "
.if( Emulation )
	.ascii "quit, "
.endif
	.ascii	"rom0000, ram0000, "
	.ascii	"go0, gocpm, "
	.ascii	"help, ?, :<hex>\r\n"
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

; rom enable/disablers

cEnab:	.asciz	"rom0000"
fEnab:
	jp	EnableROM


cDisab:	.asciz	"ram0000"
fDisab:
	jp	DisableROM


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EpCPM	= 0xFA00
Ep0000	= 0x0000

; GO 0 (new rom, old rom)

cGo0:	.asciz	"go0"
fGo0:
	jp	Ep0000


; GO FA00 (64k bios for CPM)

cGoCPM:	.asciz	"gocpm"
fGoCPM:
	jp	EpCPM



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

        ;;;;;;;;;;;;;;;
        ; Hex parser
        ; attempt to parse the LBUF as a hex string
        ;
        ;       :<byteCount><addr><type><data><csum>
        ;       byteCount =     1 byte          NumBytes( <data> )
        ;       address =       2 bytes         destination address
        ;       type =          1 byte
        ;               0x00    data to install
        ;               0x01    end of file
        ;       data =          N bytes         where N == byteCount
        ;       csum =          1 byte          twosCompliment( sum( [<byteCount>..<data>] ) )
        ;
        ;       twosCompliment( x ) = { invertBits( x ) + 1 }
; eg:
;
;       :10010000214601360121470136007EFE09D2190140
;       :100110002146017E17C20001FF5F16002148011928
;       :00000001FF
;
; field breakdown:
;         bc addr ty data                             csum
;       : 10 0100 00 214601360121470136007EFE09D21901 (40)
;       : 10 0110 00 2146017E17C20001FF5F160021480119 (28)
;       : 00 0000 01 (FF)
;
;
;       :0C9000003E48CD46003E49CD460018FE1B
;       :00000001FF
;
;       :0C-9000-00-3E 48 CD 46 00 3E 49 CD 46 00 18 FE 1B
;       :00 0000 01 FF



; field type identifiers
HEXF_DATA       = 0x00
HEXF_END        = 0x01


AddToCSUM:
        push    af
        push    bc
        ld      c, a            ; c = new item
        ld      a, (#LBUF)      ; a = previou value
        add     a, c            ; a = sum of the two above
        ld      (#LBUF), a      ; store it 

        pop     bc
        pop     af

        ret

ProcessHex:
        xor     a               ; clear the checksum accumulator
        ld      (#LBUF), a

        inc     hl              ; go to the second byte (past the ':')

        call    ReadHLInc
        call    AddToCSUM
        ld      b, a            ; store number of bytes

        call    ReadHLInc
        call    AddToCSUM
        ld      d, a            ; Addr bottom
        call    ReadHLInc
        call    AddToCSUM
        ld      e, a            ; Addr top

        call    ReadHLInc       ; type field
        call    AddToCSUM

        cp      a, #HEXF_DATA   ; Handle a Data field
        jr      z, __phData

        cp      a, #HEXF_END    ; Handle a End field
        jr      z, __phEnd

        jp      __phEF          ; ERROR: unknown field

;;;;;;;;;;;;;; HEX DATA
__phData:
        ld      a, #'D
        call    PutCh
        call    PrintNL

__phD0:
        ld      a, b
        cp      #0x00           ; special case handling
        jr      z, __phLEX

        ; b has number of bytes
        ; de is the start location
        call    ReadHLInc       ; read byte into a
        call    AddToCSUM
        ld      (de), a
        inc     de
        djnz    __phD0

__phLEX:
        ; ok.  Now the #LBUF[0] contains the sum
        call    ReadHLHex       ; now a contains passed in CSUM

        ; compute our CSUM
        ld      c, a            ; c = good checksum
        ld      hl, #LBUF
        ld      a, (hl)         ; a = our sum
        xor     a, #0xFF        ; a = invert(our sum)
        ld      b, #1
        add     a, b            ; a = our checksum

        cp      a, c
        jr      z, __phOK       ; OK checksum!

__phCSUM:
        ; checksum error
        call    PrintByte
        ld      a, #'=
        call    PutCh
        ld      a, c
        call    PrintByte
        ld      hl, #str_ErrCSUM
        call    Print
        ret

        ; ok!
__phOK:
        push    de
        pop     hl
        call    PrintHL
        ld      hl, #str_OK
        call    Print
        ret

str_ErrCSUM:
        .asciz  ": ERROR: Bad checksum.\r\n"

str_OK:
        .asciz  ": OK.\r\n"


;;;;;;;;;;;;;; HEX END
__phEnd:
        ld      a, #'E
        call    PutCh
        call    PrintNL
        ret

        ; do nothing.  just ignore the line.

__phEF:
        ld      a, #'F
        jr      __phError
__phE0:
        ld      a, #'0
__phError:
        ld      hl, #str_err
        call    Print
        call    PutCh
        call    PrintNL
        ret


str_err:
        .asciz  "\r\nHex error: "

ReadHLInc:
        call    ReadHLHex
        inc     hl
        inc     hl
        ret
ReadHLHex:
        push    hl
        push    bc
        ; top nibble
        ld      a, (hl)
        call    AtoInt
        sla     a
        sla     a
        sla     a
        sla     a
        ld      b, a

        ; bottom nibble
        inc     hl
        ld      a, (hl)
        call    AtoInt

        ; combine
        add     a, b
        pop     bc
        pop     hl
        ret


AtoInt:
        cp      #'0
        jr      c, __ai0        ; < 0, bail
        cp      #'9+1
        jr      c, __ai9        ; 0..9!
        cp      #'A
        jr      c, __ai0        ; ':'..'@', bail
        cp      #'F+1
        jr      c, __aiF        ; A..F!
        cp      #'a
        jr      c, __ai0        ; 'G'..'`', bail
        cp      #'f+1
        jr      c, __aif        ; a..f!
        ; > 'f', bail
__ai0:  ; return a 0 (for error)
        ld      a, #0
        ret

__ai9:  ; 0..9
        sub     a, #'0
        ret

__aiF:  ; A..F
        sub     a, #'A
        add     a, #10
        ret

__aif:  ; a..f
        sub     a, #'a
        add     a, #10
        ret


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; strings

str_Splash:	.ascii	"Lloader  v0.20 (c)2017 \r\n"
		.asciz	"  Scott Lawrence - yorgle@gmail.com"

; 0.20	first version with HEX, go0, gocpm
; 0.01	preliminary versions


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; other things
.include "rc2014hw.asm"
.include "linebuf.asm"
.include "string.asm"
.include "print.asm"
.include "pointers.asm"
