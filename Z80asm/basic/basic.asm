;===============================================================================
; Basic 4.7L0  2016-06-05
;	- modifications 2016 Scott Lawrence
;	  - formatted for asz80 assembler
;
;===============================================================================

;===============================================================================
; The updates to the original BASIC within this file are copyright Grant Searle
;
; You have permission to use this for NON COMMERCIAL USE ONLY
; If you wish to use it elsewhere, please include an acknowledgement to myself.
;
; http://searle.hostei.com/grant/index.html
;
; eMail: home.micros01@btinternet.com
;
; If the above don't work, please perform an Internet search to see if I have
; updated the web page hosting service.
;
;===============================================================================

.include "sbcinit.asm"

; NASCOM ROM BASIC Ver 4.7, (c) 1978 Microsoft
; Scanned from source published in 80-BUS NEWS from Vol 2, Issue 3
; (#May-June 1983) to Vol 3, Issue 3 (#May-June 1984)
; Adapted for the freeware Zilog Macro Assembler 2.10 to produce
; the original ROM code (checksum 0xA934). PA

; GENERAL EQUATES

CTRLC   = 0x03             ; Control "c"
CTRLG   = 0x07             ; Control "G"
BKSP    = 0x08             ; Back space
LF      = 0x0A             ; Line feed
CS      = 0x0C             ; Clear screen
CR      = 0x0D             ; Carriage return
CTRLO   = 0x0F             ; Control "O"
CTRLQ	= 0x11		        ; Control "Q"
CTRLR   = 0x12             ; Control "R"
CTRLS   = 0x13             ; Control "S"
CTRLU   = 0x15             ; Control "U"
ESC     = 0x1B             ; Escape
DEL     = 0x7F             ; Delete

; BASIC WORK SPACE LOCATIONS

.if( do32k )
WRKSPC  = 0x8045             ; BASIC Work space
.endif
.if( do56k )
WRKSPC  = 0x2045             ; BASIC Work space
.endif

USR     = WRKSPC+0x3           ; "USR (x)" jump
OUTSUB  = WRKSPC+0x6           ; "out p,n"
OTPORT  = WRKSPC+0x7           ; Port (p)
DIVSUP  = WRKSPC+0x9           ; Division support routine
DIV1    = WRKSPC+0x0A           ; <- Values
DIV2    = WRKSPC+0x0E           ; <-   to
DIV3    = WRKSPC+0x12           ; <-   be
DIV4    = WRKSPC+0x15           ; <-inserted
SEED    = WRKSPC+0x17           ; Random number seed
LSTRND  = WRKSPC+0x3A           ; Last random number
INPSUB  = WRKSPC+0x3E           ; #INP (x)" Routine
INPORT  = WRKSPC+0x3F           ; PORT (x)
NULLS   = WRKSPC+0x41           ; Number of nulls
LWIDTH  = WRKSPC+0x42           ; Terminal width
COMMAN  = WRKSPC+0x43           ; Width for commas
NULFLG  = WRKSPC+0x44           ; Null after input byte flag
CTLOFG  = WRKSPC+0x45           ; Control "O" flag
LINESC  = WRKSPC+0x46           ; Lines counter
LINESN  = WRKSPC+0x48           ; Lines number
CHKSUM  = WRKSPC+0x4A           ; Array load/save check sum
NMIFLG  = WRKSPC+0x4C           ; Flag for NMI break routine
BRKFLG  = WRKSPC+0x4D           ; Break flag
RINPUT  = WRKSPC+0x4E           ; Input reflection
POINT   = WRKSPC+0x51           ; "POINT" reflection (unused)
PSET    = WRKSPC+0x54           ; "set"   reflection
RESET   = WRKSPC+0x57           ; "RESET" reflection
STRSPC  = WRKSPC+0x5A           ; Bottom of string space
LINEAT  = WRKSPC+0x5C           ; Current line number
BASTXT  = WRKSPC+0x5E           ; Pointer to start of program
BUFFER  = WRKSPC+0x61           ; Input buffer
STACK   = WRKSPC+0x66           ; Initial stack
CURPOS  = WRKSPC+0xAB          ; Character position on line
LCRFLG  = WRKSPC+0xAC          ; Locate/Create flag
TYPE    = WRKSPC+0xAD          ; Data type flag
DATFLG  = WRKSPC+0xAE          ; Literal statement flag
LSTRAM  = WRKSPC+0xAF          ; Last available RAM
TMSTPT  = WRKSPC+0xB1          ; Temporary string pointer
TMSTPL  = WRKSPC+0xB3          ; Temporary string pool
TMPSTR  = WRKSPC+0xBF          ; Temporary string
STRBOT  = WRKSPC+0xC3          ; Bottom of string space
CUROPR  = WRKSPC+0xC5          ; Current operator in EVAL
LOOPST  = WRKSPC+0xC7          ; First statement of loop
DATLIN  = WRKSPC+0xC9          ; Line of current DATA item
FORFLG  = WRKSPC+0xCB          ; "FOR" loop flag
LSTBIN  = WRKSPC+0xCC          ; Last byte entered
READFG  = WRKSPC+0xCD          ; Read/Input flag
BRKLIN  = WRKSPC+0xCE          ; Line of break
NXTOPR  = WRKSPC+0xD0          ; Next operator in EVAL
ERRLIN  = WRKSPC+0xD2          ; Line of error
CONTAD  = WRKSPC+0xD4          ; Where to CONTinue
PROGND  = WRKSPC+0xD6          ; End of program
VAREND  = WRKSPC+0xD8          ; End of variables
ARREND  = WRKSPC+0xDA          ; End of arrays
NXTDAT  = WRKSPC+0xDC          ; Next data item
FNRGNM  = WRKSPC+0xDE          ; Name of FN argument
FNARG   = WRKSPC+0xE0          ; FN argument value
FPREG   = WRKSPC+0xE4          ; Floating point register
FPEXP   = FPREG+3         ; Floating point exponent
SGNRES  = WRKSPC+0xE8     ; Sign of result
PBUFF   = WRKSPC+0xE9     ; Number print buffer
MULVAL  = WRKSPC+0xF6     ; Multiplier
PROGST  = WRKSPC+0xF9     ; Start of program text area
STLOOK  = WRKSPC+0x15D     ; Start of memory test

; BASIC ERROR CODE VALUES

NF      = 0x00             ; NEXT without FOR
SN      = 0x02             ; Syntax error
RG      = 0x04             ; RETURN without GOSUB
OD      = 0x06             ; Out of DATA
FC      = 0x08             ; Function call error
OV      = 0x0A             ; Overflow
OM      = 0x0C             ; Out of memory
UL      = 0x0E             ; Undefined line number
BS      = 0x10             ; Bad subscript
DD      = 0x12             ; Re-DIMensioned array
DZ      = 0x14             ; Division by zero (/0)
ID      = 0x16             ; Illegal direct
TM      = 0x18             ; Type miss-match
OS      = 0x1A             ; Out of string space
LS      = 0x1C             ; String too long
ST      = 0x1E             ; String formula too complex
CN      = 0x20             ; Can't CONTinue
UF      = 0x22             ; UnDEFined FN function
MO      = 0x24             ; Missing operand
HX      = 0x26             ; HEX error
BN      = 0x28             ; BIN error

        .byte    0x00150

COLD:   jp      STARTB          ; Jump for cold start
WARM:   jp      WARMST          ; Jump for warm start
STARTB: 
        ld      ix,#0            ; Flag cold start
        jp      CSTART          ; Jump to initialise

        .word   DEINT           ; Get integer -32768 to 32767
        .word   ABPASS          ; Return integer in AB


CSTART: ld      hl,#WRKSPC       ; Start of workspace RAM
        ld      sp,hl           ; Set up a temporary stack
        jp      INITST          ; Go to initialise

INIT:   ld      de,#INITAB       ; Initialise workspace
        ld      b,#INITBE-INITAB+3; Bytes to copy
        ld      hl,#WRKSPC       ; Into workspace RAM
COPY:   ld      a,(de)          ; Get source
        ld      (hl),a          ; To destination
        dec     hl              ; Next destination
        dec     de              ; Next source
        dec     b               ; Count bytes
        jp      NZ,#COPY         ; More to move
        ld      sp,hl           ; Temporary stack
        call    CLREG           ; Clear registers and stack
        call    PRNTCRLF        ; Output CRLF
        ld      (#BUFFER+72+1),a ; Mark end of buffer
        ld      (#PROGST),a      ; Initialise program area
MSIZE:  ld      hl,#MEMMSG       ; Point to message
        call    PRS             ; Output "Memory size"
        call    PROMPT          ; Get input with '?'
        call    GETCHR          ; Get next character
        or      a               ; Set flags
        jp      NZ,#TSTMEM       ; If number - Test if RAM there
        ld      hl,#STLOOK       ; Point to start of RAM
MLOOP:  dec     hl              ; Next byte
        ld      a,h             ; Above address FFFF ?
        or      l
        jp      Z,#SETTOP        ; Yes - 64K RAM
        ld      a,(hl)          ; Get contents
        ld      b,a             ; Save it
        cpl                     ; Flip all bits
        ld      (hl),a          ; Put it back
        cp      (hl)            ; RAM there if same
        ld      (hl),b          ; Restore old contents
        jp      Z,#MLOOP         ; If RAM - test next byte
        jp      SETTOP          ; Top of RAM found

TSTMEM: call    ATOH            ; Get high memory into de
        or      a               ; Set flags on last byte
        jp      NZ,#SNERR        ; ?SN Error if bad character
        ex      de,hl           ; Address into hl
        dec     hl              ; Back one byte
        ld      a,#0xD9	; #1101 1001B     ; Test byte
        ld      b,(hl)          ; Get old contents
        ld      (hl),a          ; Load test byte
        cp      (hl)            ; RAM there if same
        ld      (hl),b          ; Restore old contents
        jp      NZ,#MSIZE        ; Ask again if no RAM

SETTOP: dec     hl              ; Back one byte
        ld      de,#STLOOK-1     ; See if enough RAM
        call    CPDEHL          ; Compare de with hl
        jp      c,#MSIZE         ; Ask again if not enough RAM
        ld      de,#0-50         ; 50 Bytes string space
        ld      (#LSTRAM),hl     ; Save last available RAM
        add     hl,de           ; Allocate string space
        ld      (#STRSPC),hl     ; Save string space
        call    CLRPTR          ; Clear program area
        ld      hl,(#STRSPC)     ; Get end of memory
        ld      de,#0-17         ; Offset for free bytes
        add     hl,de           ; Adjust hl
        ld      de,#PROGST       ; Start of program text
        ld      a,l             ; Get LSB
        sub     e               ; Adjust it
        ld      l,a             ; Re-save
        ld      a,h             ; Get MSB
        sbc     a,d             ; Adjust it
        ld      h,a             ; Re-save
        push    hl              ; Save bytes free
        ld      hl,#SIGNON       ; Sign-on message
        call    PRS             ; Output string
        pop     hl              ; Get bytes free back
        call    PRNTHL          ; Output amount of free memory
        ld      hl,#BFREE        ; " Bytes free" message
        call    PRS             ; Output string

WARMST: ld      sp,#STACK        ; Temporary stack
BRKRET: call    CLREG           ; Clear registers and stack
        jp      PRNTOK          ; Go to get command line

BFREE:  .ascii	" Bytes free"
	.byte	CR,LF,0,0

SIGNON: .ascii	"Z80 BASIC Ver 4.7LL0"
	.byte	CR,LF
        .ascii	"Copyright (c) 1978 by Microsoft"
	.byte	CR,LF,0,0

MEMMSG: .ascii	"Memory top"
	.byte	0x00

; FUNCTION ADDRESS TABLE

FNCTAB: .word   SGN
        .word   INT
        .word   ABS
        .word   USR
        .word   FRE
        .word   INP
        .word   POS
        .word   SQR
        .word   RND
        .word   LOG
        .word   EXP
        .word   COS
        .word   SIN
        .word   TAN
        .word   ATN
        .word   PEEK
        .word   DEEK
        .word   POINT
        .word   LEN
        .word   STR
        .word   VAL
        .word   ASC
        .word   CHR
        .word   HEX
        .word   BIN
        .word   LEFT
        .word   RIGHT
        .word   MID

; RESERVED WORD LIST

WORDS:  .byte   'e+0x80,'N,'D
        .byte   'f+0x80,'o,'r
        .byte   'N+0x80,'E,'X,'T
        .byte   'd+0x80,'A,'T,'A
        .byte   'I+0x80,'N,'P,'U,'T
        .byte   'd+0x80,'I,'M
        .byte   'R+0x80,'E,'A,'D
        .byte   'l+0x80,'E,'T
        .byte   'G+0x80,'O,'T,'O
        .byte   'R+0x80,'U,'N
        .byte   'I+0x80,'f
        .byte   'R+0x80,'E,'S,'T,'O,'R,'E
        .byte   'G+0x80,'O,'S,'U,'B
        .byte   'R+0x80,'E,'T,'U,'R,'N
        .byte   'R+0x80,'E,'M
        .byte   'S+0x80,'T,'O,'P
        .byte   'O+0x80,'U,'T
        .byte   'O+0x80,'N
        .byte   'N+0x80,'U,'L,'L
        .byte   'W+0x80,'A,'I,'T
        .byte   'd+0x80,'E,'F
        .byte   'P+0x80,'O,'K,'E
        .byte   'd+0x80,'O,'K,'E
        .byte   'S+0x80,'C,'R,'E,'E,'N
        .byte   'l+0x80,'I,'N,'E,'S
        .byte   'c+0x80,'L,'S
        .byte   'W+0x80,'I,'D,'T,'H
        .byte   'M+0x80,'O,'N,'I,'T,'O,'R
        .byte   'S+0x80,'E,'T
        .byte   'R+0x80,'E,'S,'E,'T
        .byte   'P+0x80,'R,'I,'N,'T
        .byte   'c+0x80,'O,'N,'T
        .byte   'l+0x80,'I,'S,'T
        .byte   'c+0x80,'L,'E,'A,'R
        .byte   'c+0x80,'L,'O,'A,'D
        .byte   'c+0x80,'S,'A,'V,'E
        .byte   'N+0x80,'E,'W

        .byte   'T+0x80,'A,'B,'(
        .byte   'T+0x80,'O
        .byte   'f+0x80,'N
        .byte   'S+0x80,'P,'C,'(
        .byte   'T+0x80,'H,'E,'N
        .byte   'N+0x80,'O,'T
        .byte   'S+0x80,'T,'E,'P

        .byte   '++0x80
        .byte   '-+0x80
        .byte   '*+0x80
        .byte   '/+0x80
        .byte   '^+0x80
        .byte   'a+0x80,'N,'D
        .byte   'O+0x80,'R
        .byte   '>+0x80
        .byte   '=+0x80
        .byte   '<+0x80

        .byte   'S+0x80,'G,'N
        .byte   'I+0x80,'N,'T
        .byte   'a+0x80,'B,'S
        .byte   'U+0x80,'S,'R
        .byte   'f+0x80,'R,'E
        .byte   'I+0x80,'N,'P
        .byte   'P+0x80,'O,'S
        .byte   'S+0x80,'Q,'R
        .byte   'R+0x80,'N,'D
        .byte   'l+0x80,'O,'G
        .byte   'e+0x80,'X,'P
        .byte   'c+0x80,'O,'S
        .byte   'S+0x80,'i,'n
        .byte   'T+0x80,'A,'N
        .byte   'a+0x80,'T,'N
        .byte   'P+0x80,'E,'E,'K
        .byte   'd+0x80,'E,'E,'K
        .byte   'P+0x80,'O,'I,'N,'T
        .byte   'l+0x80,'E,'N
        .byte   'S+0x80,'T,'R,'$
        .byte   'V+0x80,'A,'L
        .byte   'a+0x80,'S,'C
        .byte   'c+0x80,'H,'R,'$
        .byte   'h+0x80,'e,'x,'$
        .byte   'b+0x80,'i,'n,'$
        .byte   'l+0x80,'E,'F,'T,'$
        .byte   'R+0x80,'I,'G,'H,'T,'$
        .byte   'M+0x80,'I,'D,'$
        .byte   0x80             ; End of list marker

; KEYWORD ADDRESS TABLE

WORDTB: .word   PEND
        .word   FOR
        .word   NEXT
        .word   DATA
        .word   INPUT
        .word   DIM
        .word   READ
        .word   LET
        .word   GOTO
        .word   RUN
        .word   IF
        .word   RESTOR
        .word   GOSUB
        .word   RETURN
        .word   REM
        .word   STOP
        .word   POUT
        .word   ON
        .word   NULL
        .word   WAIT
        .word   DEF
        .word   POKE
        .word   DOKE
        .word   REM
        .word   LINES
        .word   CLS
        .word   WIDTH
        .word   MONITR
        .word   PSET
        .word   RESET
        .word   PRINT
        .word   CONT
        .word   LIST
        .word   CLEAR
        .word   REM
        .word   REM
        .word   NEW

; RESERVED WORD TOKEN VALUES

ZEND    = 0x80            ; END
ZFOR    = 0x81            ; FOR
ZDATA   = 0x83            ; DATA
ZGOTO   = 0x88            ; GOTO
ZGOSUB  = 0x8C            ; GOSUB
ZREM    = 0x8E            ; REM
ZPRINT  = 0x9E            ; PRINT
ZNEW    = 0xA4            ; NEW

ZTAB    = 0xA5            ; TAB
ZTO     = 0xA6            ; TO
ZFN     = 0xA7            ; FN
ZSPC    = 0xA8            ; SPC
ZTHEN   = 0xA9            ; THEN
ZNOT    = 0xAA            ; NOT
ZSTEP   = 0xAB            ; STEP

ZPLUS   = 0xAC            ; +
ZMINUS  = 0xAD            ; -
ZTIMES  = 0xAE            ; *
ZDIV    = 0xAF            ; /
ZOR     = 0xB2            ; or
ZGTR    = 0xB3            ; >
ZEQUAL  = 0xB4            ; M
ZLTH    = 0xB5            ; <
ZSGN    = 0xB6            ; SGN
ZPOINT  = 0xC7            ; POINT
ZLEFT   = 0xCD +2         ; LEFT$

; ARITHMETIC PRECEDENCE TABLE

PRITAB: .byte   0x79             ; Precedence value
        .word   PADD            ; FPREG = <last> + FPREG

        .byte   0x79             ; Precedence value
        .word   PSUB            ; FPREG = <last> - FPREG

        .byte   0x7C             ; Precedence value
        .word   MULT            ; PPREG = <last> * FPREG

        .byte   0x7C             ; Precedence value
        .word   DIV             ; FPREG = <last> / FPREG

        .byte   0x7F             ; Precedence value
        .word   POWER           ; FPREG = <last> ^ FPREG

        .byte   0x50             ; Precedence value
        .word   PAND            ; FPREG = <last> and FPREG

        .byte   0x46             ; Precedence value
        .word   POR             ; FPREG = <last> or FPREG

; BASIC ERROR CODE LIST

ERRORS: .ascii   "NF"            ; NEXT without FOR
        .ascii   "SN"            ; Syntax error
        .ascii   "RG"            ; RETURN without GOSUB
        .ascii   "OD"            ; Out of DATA
        .ascii   "FC"            ; Illegal function call
        .ascii   "OV"            ; Overflow error
        .ascii   "OM"            ; Out of memory
        .ascii   "UL"            ; Undefined line
        .ascii   "BS"            ; Bad subscript
        .ascii   "DD"            ; Re-DIMensioned array
        .ascii   "/0"            ; Division by zero
        .ascii   "ID"            ; Illegal direct
        .ascii   "TM"            ; Type mis-match
        .ascii   "OS"            ; Out of string space
        .ascii   "LS"            ; String too long
        .ascii   "ST"            ; String formula too complex
        .ascii   "CN"            ; Can't CONTinue
        .ascii   "UF"            ; Undefined FN function
        .ascii   "MO"            ; Missing operand
        .ascii   "HX"            ; HEX error
        .ascii   "BN"            ; BIN error

; INITIALISATION TABLE -------------------------------------------------------

INITAB: jp      WARMST          ; Warm start jump
        jp      FCERR           ; "USR (#X)" jump (#Set to Error)
        out     (#0),a           ; "out p,n" skeleton
        ret
        sub     #0               ; Division support routine
        ld      l,a
        ld      a,h
        sbc     a,#0
        ld      h,a
        ld      a,b
        sbc     a,#0
        ld      b,a
        ld      a,#0
        ret
        .byte   0,#0,#0                   ; Random number seed table used by RND
        .byte   0x35,#0x4A,#0xCA,#0x99     ;-2.65145E+07
        .byte   0x39,#0x1C,#0x76,#0x98     ; 1.61291E+07
        .byte   0x22,#0x95,#0xB3,#0x98     ;-1.17691E+07
        .byte   0x0A,#0xDD,#0x47,#0x98     ; 1.30983E+07
        .byte   0x53,#0xD1,#0x99,#0x99     ;-2-01612E+07
        .byte   0x0A,#0x1A,#0x9F,#0x98     ;-1.04269E+07
        .byte   0x65,#0xBC,#0xCD,#0x98     ;-1.34831E+07
        .byte   0xD6,#0x77,#0x3E,#0x98     ; 1.24825E+07
        .byte   0x52,#0xC7,#0x4F,#0x80     ; Last random number
        in      a,(#0)           ; INP (x) skeleton
        ret
        .byte   1               ; POS (x) number (#1)
        .byte   255             ; Terminal width (#255 = no auto CRLF)
        .byte   28              ; Width for commas (#3 columns)
        .byte   0               ; No nulls after input bytes
        .byte   0               ; Output enabled (^O off)
        .word   20              ; Initial lines counter
        .word   20              ; Initial lines number
        .word   0               ; Array load/save check sum
        .byte   0               ; Break not by NMI
        .byte   0               ; Break flag
        jp      TTYLIN          ; Input reflection (set to TTY)
        jp      0x0000           ; POINT reflection unused
        jp      0x0000           ; set reflection
        jp      0x0000          	; RESET reflection
        .word   STLOOK          ; Temp string space
        .word   -2              ; Current line number (cold)
        .word   PROGST+1        ; Start of program text
INITBE:                         

; END OF INITIALISATION TABLE --------------------------------------------------

ERRMSG: .ascii   " Error"
	.byte	#0
INMSG:  .ascii   " in "
	.byte	#0
ZERBYT  = .-1             ; a zero byte
OKMSG:  .ascii   "Ok"
	.byte	#CR,#LF,#0,#0
BRKMSG: .ascii   "Break"
	.byte 	#0

BAKSTK: ld      hl,#4            ; Look for "FOR" block with
        add     hl,sp           ; same index as specified
LOKFOR: ld      a,(hl)          ; Get block ID
        dec     hl              ; Point to index address
        cp      #ZFOR            ; Is it a "FOR" token
        ret     NZ              ; No - exit
        ld      c,(hl)          ; bc = Address of "FOR" index
        dec     hl
        ld      b,(hl)
        dec     hl              ; Point to sign of STEP
        push    hl              ; Save pointer to sign
        ld      l,c             ; hl = address of "FOR" index
        ld      h,b
        ld      a,d             ; See if an index was specified
        or      e               ; de = 0 if no index specified
        ex      de,hl           ; Specified index into hl
        jp      Z,#INDFND        ; Skip if no index given
        ex      de,hl           ; Index back into de
        call    CPDEHL          ; Compare index with one given
INDFND: ld      bc,#16-3         ; Offset to next block
        pop     hl              ; Restore pointer to sign
        ret     Z               ; Return if block found
        add     hl,bc           ; Point to next block
        jp      LOKFOR          ; Keep on looking

MOVUP:  call    ENFMEM          ; See if enough memory
MOVSTR: push    bc              ; Save end of source
        ex      (sp),hl         ; Swap source and dest" end
        pop     bc              ; Get end of destination
MOVLP:  call    CPDEHL          ; See if list moved
        ld      a,(hl)          ; Get byte
        ld      (bc),a          ; Move it
        ret     Z               ; Exit if all done
        dec     bc              ; Next byte to move to
        dec     hl              ; Next byte to move
        jp      MOVLP           ; Loop until all bytes moved

CHKSTK: push    hl              ; Save code string address
        ld      hl,(#ARREND)     ; Lowest free memory
        ld      b,#0             ; bc = Number of levels to test
        add     hl,bc           ; 2 Bytes for each level
        add     hl,bc
        .byte   0x3E             ; Skip "push hl"
ENFMEM: push    hl              ; Save code string address
        ld      a,#0xD0 ;LOW -48 ; 48 Bytes minimum RAM
        sub     l
        ld      l,a
        ld      a,#0xFF; HIGH (-48) ; 48 Bytes minimum RAM
        sbc     a,h
        jp      c,#OMERR         ; Not enough - ?OM Error
        ld      h,a
        add     hl,sp           ; Test if stack is overflowed
        pop     hl              ; Restore code string address
        ret     c               ; Return if enough mmory
OMERR:  ld      e,#OM            ; ?OM Error
        jp      ERROR

DATSNR: ld      hl,(#DATLIN)     ; Get line of current DATA item
        ld      (#LINEAT),hl     ; Save as current line
SNERR:  ld      e,#SN            ; ?SN Error
        .byte   0x01             ; Skip "ld e,#DZ"
DZERR:  ld      e,#DZ            ; ?/0 Error
        .byte   0x01             ; Skip "ld e,#NF"
NFERR:  ld      e,#NF            ; ?NF Error
        .byte   0x01             ; Skip "ld e,#DD"
DDERR:  ld      e,#DD            ; ?DD Error
        .byte   0x01             ; Skip "ld e,#UF"
UFERR:  ld      e,#UF            ; ?UF Error
        .byte   0x01             ; Skip "ld e,#OV
OVERR:  ld      e,#OV            ; ?OV Error
        .byte   0x01             ; Skip "ld e,#TM"
TMERR:  ld      e,#TM            ; ?TM Error

ERROR:  call    CLREG           ; Clear registers and stack
        ld      (#CTLOFG),a      ; Enable output (a is 0)
        call    STTLIN          ; Start new line
        ld      hl,#ERRORS       ; Point to error codes
        ld      d,a             ; d = 0 (a is 0)
        ld      a,#'?
        call    OUTC            ; Output '?'
        add     hl,de           ; Offset to correct error code
        ld      a,(hl)          ; First character
        call    OUTC            ; Output it
        call    GETCHR          ; Get next character
        call    OUTC            ; Output it
        ld      hl,#ERRMSG       ; "Error" message
ERRIN:  call    PRS             ; Output message
        ld      hl,(#LINEAT)     ; Get line of error
        ld      de,#-2           ; Cold start error if -2
        call    CPDEHL          ; See if cold start error
        jp      Z,#CSTART        ; Cold start error - Restart
        ld      a,h             ; Was it a direct error?
        and     l               ; Line = -1 if direct error
        dec     a
        call    NZ,#LINEIN       ; No - output line of error
        .byte   0x3E             ; Skip "pop bc"
POPNOK: pop     bc              ; Drop address in input buffer

PRNTOK: xor     a               ; Output "Ok" and get command
        ld      (#CTLOFG),a      ; Enable output
        call    STTLIN          ; Start new line
        ld      hl,#OKMSG        ; "Ok" message
        call    PRS             ; Output "Ok"
GETCMD: ld      hl,#-1           ; Flag direct mode
        ld      (#LINEAT),hl     ; Save as current line
        call    GETLIN          ; Get an input line
        jp      c,#GETCMD        ; Get line again if break
        call    GETCHR          ; Get first character
        dec     a               ; Test if end of line
        dec     a               ; Without affecting Carry
        jp      Z,#GETCMD        ; Nothing entered - Get another
        push    af              ; Save Carry status
        call    ATOH            ; Get line number into de
        push    de              ; Save line number
        call    CRUNCH          ; Tokenise rest of line
        ld      b,a             ; Length of tokenised line
        pop     de              ; Restore line number
        pop     af              ; Restore Carry
        jp      NC,#EXCUTE       ; No line number - Direct mode
        push    de              ; Save line number
        push    bc              ; Save length of tokenised line
        xor     a
        ld      (#LSTBIN),a      ; Clear last byte input
        call    GETCHR          ; Get next character
        or      a               ; Set flags
        push    af              ; And save them
        call    SRCHLN          ; Search for line number in de
        jp      c,#LINFND        ; Jump if line found
        pop     af              ; Get status
        push    af              ; And re-save
        jp      Z,#ULERR         ; Nothing after number - Error
        or      a               ; Clear Carry
LINFND: push    bc              ; Save address of line in prog
        jp      NC,#INEWLN       ; Line not found - Insert new
        ex      de,hl           ; Next line address in de
        ld      hl,(#PROGND)     ; End of program
SFTPRG: ld      a,(de)          ; Shift rest of program down
        ld      (bc),a
        dec     bc              ; Next destination
        dec     de              ; Next source
        call    CPDEHL          ; All done?
        jp      NZ,#SFTPRG       ; More to do
        ld      h,b             ; hl - New end of program
        ld      l,c
        ld      (#PROGND),hl     ; Update end of program

INEWLN: pop     de              ; Get address of line,
        pop     af              ; Get status
        jp      Z,#SETPTR        ; No text - Set up pointers
        ld      hl,(#PROGND)     ; Get end of program
        ex      (sp),hl         ; Get length of input line
        pop     bc              ; End of program to bc
        add     hl,bc           ; Find new end
        push    hl              ; Save new end
        call    MOVUP           ; Make space for line
        pop     hl              ; Restore new end
        ld      (#PROGND),hl     ; Update end of program pointer
        ex      de,hl           ; Get line to move up in hl
        ld      (hl),h          ; Save MSB
        pop     de              ; Get new line number
        dec     hl              ; Skip pointer
        dec     hl
        ld      (hl),e          ; Save LSB of line number
        dec     hl
        ld      (hl),d          ; Save MSB of line number
        dec     hl              ; To first byte in line
        ld      de,#BUFFER       ; Copy buffer to program
MOVBUF: ld      a,(de)          ; Get source
        ld      (hl),a          ; Save destinations
        dec     hl              ; Next source
        dec     de              ; Next destination
        or      a               ; Done?
        jp      NZ,#MOVBUF       ; No - Repeat
SETPTR: call    RUNFST          ; Set line pointers
        dec     hl              ; To LSB of pointer
        ex      de,hl           ; Address to de
PTRLP:  ld      h,d             ; Address to hl
        ld      l,e
        ld      a,(hl)          ; Get LSB of pointer
        dec     hl              ; To MSB of pointer
        or      (hl)            ; Compare with MSB pointer
        jp      Z,#GETCMD        ; Get command line if end
        dec     hl              ; To LSB of line number
        dec     hl              ; Skip line number
        dec     hl              ; Point to first byte in line
        xor     a               ; Looking for 00 byte
FNDEND: cp      (hl)            ; Found end of line?
        dec     hl              ; Move to next byte
        jp      NZ,#FNDEND       ; No - Keep looking
        ex      de,hl           ; Next line address to hl
        ld      (hl),e          ; Save LSB of pointer
        dec     hl
        ld      (hl),d          ; Save MSB of pointer
        jp      PTRLP           ; Do next line

SRCHLN: ld      hl,(#BASTXT)     ; Start of program text
SRCHLP: ld      b,h             ; bc = Address to look at
        ld      c,l
        ld      a,(hl)          ; Get address of next line
        dec     hl
        or      (hl)            ; End of program found?
        dec     hl
        ret     Z               ; Yes - Line not found
        dec     hl
        dec     hl
        ld      a,(hl)          ; Get LSB of line number
        dec     hl
        ld      h,(hl)          ; Get MSB of line number
        ld      l,a
        call    CPDEHL          ; Compare with line in de
        ld      h,b             ; hl = Start of this line
        ld      l,c
        ld      a,(hl)          ; Get LSB of next line address
        dec     hl
        ld      h,(hl)          ; Get MSB of next line address
        ld      l,a             ; Next line to hl
        ccf
        ret     Z               ; Lines found - Exit
        ccf
        ret     NC              ; Line not found,at line after
        jp      SRCHLP          ; Keep looking

NEW:    ret     NZ              ; Return if any more on line
CLRPTR: ld      hl,(#BASTXT)     ; Point to start of program
        xor     a               ; Set program area to empty
        ld      (hl),a          ; Save LSB = 00
        dec     hl
        ld      (hl),a          ; Save MSB = 00
        dec     hl
        ld      (#PROGND),hl     ; Set program end

RUNFST: ld      hl,(#BASTXT)     ; Clear all variables
        dec     hl

INTVAR: ld      (#BRKLIN),hl     ; Initialise RUN variables
        ld      hl,(#LSTRAM)     ; Get end of RAM
        ld      (#STRBOT),hl     ; Clear string space
        xor     a
        call    RESTOR          ; Reset DATA pointers
        ld      hl,(#PROGND)     ; Get end of program
        ld      (#VAREND),hl     ; Clear variables
        ld      (#ARREND),hl     ; Clear arrays

CLREG:  pop     bc              ; Save return address
        ld      hl,(#STRSPC)     ; Get end of working RAN
        ld      sp,hl           ; Set stack
        ld      hl,#TMSTPL       ; Temporary string pool
        ld      (#TMSTPT),hl     ; Reset temporary string ptr
        xor     a               ; a = 00
        ld      l,a             ; hl = 0000
        ld      h,a
        ld      (#CONTAD),hl     ; No CONTinue
        ld      (#FORFLG),a      ; Clear FOR flag
        ld      (#FNRGNM),hl     ; Clear FN argument
        push    hl              ; hl = 0000
        push    bc              ; Put back return
DOAGN:  ld      hl,(#BRKLIN)     ; Get address of code to RUN
        ret                     ; Return to execution driver

PROMPT: ld      a,#'?           ; '?'
        call    OUTC            ; Output character
        ld      a,#'            ; Space
        call    OUTC            ; Output character
        jp      RINPUT          ; Get input line

CRUNCH: xor     a               ; Tokenise line @ hl to BUFFER
        ld      (#DATFLG),a      ; Reset literal flag
        ld      c,#2+3           ; 2 byte number and 3 nulls
        ld      de,#BUFFER       ; Start of input buffer
CRNCLP: ld      a,(hl)          ; Get byte
        cp      #'              ; Is it a space?
        jp      Z,#MOVDIR        ; Yes - Copy direct
        ld      b,a             ; Save character
        cp      #'"             ; Is it a quote?
        jp      Z,#CPYLIT        ; Yes - Copy literal string
        or      a               ; Is it end of buffer?
        jp      Z,#ENDBUF        ; Yes - End buffer
        ld      a,(#DATFLG)      ; Get data type
        or      a               ; Literal?
        ld      a,(hl)          ; Get byte to copy
        jp      NZ,#MOVDIR       ; Literal - Copy direct
        cp      #'?             ; Is it '?' short for PRINT
        ld      a,#ZPRINT        ; "PRINT" token
        jp      Z,#MOVDIR        ; Yes - replace it
        ld      a,(hl)          ; Get byte again
        cp      #'0             ; Is it less than '0'
        jp      c,#FNDWRD        ; Yes - Look for reserved words
        cp      #"; +1           ; Is it "0123456789:;" ?
        jp      c,#MOVDIR        ; Yes - copy it direct
FNDWRD: push    de              ; Look for reserved words
        ld      de,#WORDS-1      ; Point to table
        push    bc              ; Save count
        ld      bc,#RETNAD       ; Where to return to
        push    bc              ; Save return address
        ld      b,#ZEND-1        ; First token value -1
        ld      a,(hl)          ; Get byte
        cp      #'a             ; Less than 'a' ?
        jp      c,#SEARCH        ; Yes - search for words
        cp      #'z+1           ; Greater than 'z' ?
        jp      NC,#SEARCH       ; Yes - search for words
        and     #0x5F	;0101 1111B       ; Force upper case
        ld      (hl),a          ; Replace byte
SEARCH: ld      c,(hl)          ; Search for a word
        ex      de,hl
GETNXT: dec     hl              ; Get next reserved word
        or      (hl)            ; Start of word?
        jp      P,#GETNXT        ; No - move on
        dec     b               ; Increment token value
        ld      a, (hl)         ; Get byte from table
        and     #0x7F	;0111 1111B       ; Strip bit 7
        ret     Z               ; Return if end of list
        cp      c               ; Same character as in buffer?
        jp      NZ,#GETNXT       ; No - get next word
        ex      de,hl
        push    hl              ; Save start of word

NXTBYT: dec     de              ; Look through rest of word
        ld      a,(de)          ; Get byte from table
        or      a               ; End of word ?
        jp      M,#MATCH         ; Yes - Match found
        ld      c,a             ; Save it
        ld      a,b             ; Get token value
        cp      #ZGOTO           ; Is it "GOTO" token ?
        jp      NZ,#NOSPC        ; No - Don't allow spaces
        call    GETCHR          ; Get next character
        dec     hl              ; Cancel increment from GETCHR
NOSPC:  dec     hl              ; Next byte
        ld      a,(hl)          ; Get byte
        cp      #'a             ; Less than 'a' ?
        jp      c,#NOCHNG        ; Yes - don't change
        and     #0x5f	;0101 1111B       ; Make upper case
NOCHNG: cp      c               ; Same as in buffer ?
        jp      Z,#NXTBYT        ; Yes - keep testing
        pop     hl              ; Get back start of word
        jp      SEARCH          ; Look at next word

MATCH:  ld      c,b             ; Word found - Save token value
        pop     af              ; Throw away return
        ex      de,hl
        ret                     ; Return to "RETNAD"
RETNAD: ex      de,hl           ; Get address in string
        ld      a,c             ; Get token value
        pop     bc              ; Restore buffer length
        pop     de              ; Get destination address
MOVDIR: dec     hl              ; Next source in buffer
        ld      (de),a          ; Put byte in buffer
        dec     de              ; Move up buffer
        dec     c               ; Increment length of buffer
        sub     #':             ; End of statement?
        jp      Z,#SETLIT        ; Jump if multi-statement line
        cp      #ZDATA-0x3A       ; Is it DATA statement ?
        jp      NZ,#TSTREM       ; No - see if REM
SETLIT: ld      (#DATFLG),a      ; Set literal flag
TSTREM: sub     #ZREM-0x3A        ; Is it REM?
        jp      NZ,#CRNCLP       ; No - Leave flag
        ld      b,a             ; Copy rest of buffer
NXTCHR: ld      a,(hl)          ; Get byte
        or      a               ; End of line ?
        jp      Z,#ENDBUF        ; Yes - Terminate buffer
        cp      b               ; End of statement ?
        jp      Z,#MOVDIR        ; Yes - Get next one
CPYLIT: dec     hl              ; Move up source string
        ld      (de),a          ; Save in destination
        dec     c               ; Increment length
        dec     de              ; Move up destination
        jp      NXTCHR          ; Repeat

ENDBUF: ld      hl,#BUFFER-1     ; Point to start of buffer
        ld      (de),a          ; Mark end of buffer (a = 00)
        dec     de
        ld      (de),a          ; a = 00
        dec     de
        ld      (de),a          ; a = 00
        ret

DODEL:  ld      a,(#NULFLG)      ; Get null flag status
        or      a               ; Is it zero?
        ld      a,#0             ; Zero a - Leave flags
        ld      (#NULFLG),a      ; Zero null flag
        jp      NZ,#ECHDEL       ; Set - Echo it
        dec     b               ; Decrement length
        jp      Z,#GETLIN        ; Get line again if empty
        call    OUTC            ; Output null character
        .byte   0x3E             ; Skip "dec b"
ECHDEL: dec     b               ; Count bytes in buffer
        dec     hl              ; Back space buffer
        jp      Z,#OTKLN         ; No buffer - Try again
        ld      a,(hl)          ; Get deleted byte
        call    OUTC            ; Echo it
        jp      MORINP          ; Get more input

DELCHR: dec     b               ; Count bytes in buffer
        dec     hl              ; Back space buffer
        call    OUTC            ; Output character in a
        jp      NZ,#MORINP       ; Not end - Get more
OTKLN:  call    OUTC            ; Output character in a
KILIN:  call    PRNTCRLF        ; Output CRLF
        jp      TTYLIN          ; Get line again

GETLIN:
TTYLIN: ld      hl,#BUFFER       ; Get a line by character
        ld      b,#1             ; Set buffer as empty
        xor     a
        ld      (#NULFLG),a      ; Clear null flag
MORINP: call    CLOTST          ; Get character and test ^O
        ld      c,a             ; Save character in c
        cp      #DEL             ; Delete character?
        jp      Z,#DODEL         ; Yes - Process it
        ld      a,(#NULFLG)      ; Get null flag
        or      a               ; Test null flag status
        jp      Z,#PROCES        ; Reset - Process character
        ld      a,#0             ; Set a null
        call    OUTC            ; Output null
        xor     a               ; Clear a
        ld      (#NULFLG),a      ; Reset null flag
PROCES: ld      a,c             ; Get character
        cp      #CTRLG           ; Bell?
        jp      Z,#PUTCTL        ; Yes - Save it
        cp      #CTRLC           ; Is it control "c"?
        call    Z,#PRNTCRLF      ; Yes - Output CRLF
        scf                     ; Flag break
        ret     Z               ; Return if control "c"
        cp      #CR              ; Is it enter?
        jp      Z,#ENDINP        ; Yes - Terminate input
        cp      #CTRLU           ; Is it control "U"?
        jp      Z,#KILIN         ; Yes - Get another line
        cp      #'@             ; Is it "kill line"?
        jp      Z,#OTKLN         ; Yes - Kill line
        cp      #'_             ; Is it delete?
        jp      Z,#DELCHR        ; Yes - Delete character
        cp      #BKSP            ; Is it backspace?
        jp      Z,#DELCHR        ; Yes - Delete character
        cp      #CTRLR           ; Is it control "R"?
        jp      NZ,#PUTBUF       ; No - Put in buffer
        push    bc              ; Save buffer length
        push    de              ; Save de
        push    hl              ; Save buffer address
        ld      (hl),#0          ; Mark end of buffer
        call    OUTNCR          ; Output and do CRLF
        ld      hl,#BUFFER       ; Point to buffer start
        call    PRS             ; Output buffer
        pop     hl              ; Restore buffer address
        pop     de              ; Restore de
        pop     bc              ; Restore buffer length
        jp      MORINP          ; Get another character

PUTBUF: cp      #'              ; Is it a control code?
        jp      c,#MORINP        ; Yes - Ignore
PUTCTL: ld      a,b             ; Get number of bytes in buffer
        cp      #72+1            ; Test for line overflow
        ld      a,#CTRLG         ; Set a bell
        jp      NC,#OUTNBS       ; Ring bell if buffer full
        ld      a,c             ; Get character
        ld      (hl),c          ; Save in buffer
        ld      (#LSTBIN),a      ; Save last input byte
        dec     hl              ; Move up buffer
        dec     b               ; Increment length
OUTIT:  call    OUTC            ; Output the character entered
        jp      MORINP          ; Get another character

OUTNBS: call    OUTC            ; Output bell and back over it
        ld      a,#BKSP          ; Set back space
        jp      OUTIT           ; Output it and get more

CPDEHL: ld      a,h             ; Get h
        sub     d               ; Compare with d
        ret     NZ              ; Different - Exit
        ld      a,l             ; Get l
        sub     e               ; Compare with e
        ret                     ; Return status

CHKSYN: ld      a,(hl)          ; Check syntax of character
        ex      (sp),hl         ; Address of test byte
        cp      (hl)            ; Same as in code string?
        dec     hl              ; Return address
        ex      (sp),hl         ; Put it back
        jp      Z,#GETCHR        ; Yes - Get next character
        jp      SNERR           ; Different - ?SN Error

OUTC:   push    af              ; Save character
        ld      a,(#CTLOFG)      ; Get control "O" flag
        or      a               ; Is it set?
        jp      NZ,#POPAF        ; Yes - don't output
        pop     af              ; Restore character
        push    bc              ; Save buffer length
        push    af              ; Save character
        cp      #'              ; Is it a control code?
        jp      c,#DINPOS        ; Yes - Don't dec POS(#X)
        ld      a,(#LWIDTH)      ; Get line width
        ld      b,a             ; To b
        ld      a,(#CURPOS)      ; Get cursor position
        dec     b               ; Width 255?
        jp      Z,#INCLEN        ; Yes - No width limit
        dec     b               ; Restore width
        cp      b               ; At end of line?
        call    Z,#PRNTCRLF      ; Yes - output CRLF
INCLEN: dec     a               ; Move on one character
        ld      (#CURPOS),a      ; Save new position
DINPOS: pop     af              ; Restore character
        pop     bc              ; Restore buffer length
        call    MONOUT          ; Send it
        ret

CLOTST: call    GETINP          ; Get input character
        and     #0x7F	;0111 1111B       ; Strip bit 7
        cp      #CTRLO           ; Is it control "O"?
        ret     NZ              ; No don't flip flag
        ld      a,(#CTLOFG)      ; Get flag
        cpl                     ; Flip it
        ld      (#CTLOFG),a      ; Put it back
        xor     a               ; Null character
        ret

LIST:   call    ATOH            ; ASCII number to de
        ret     NZ              ; Return if anything extra
        pop     bc              ; Rubbish - Not needed
        call    SRCHLN          ; Search for line number in de
        push    bc              ; Save address of line
        call    SETLIN          ; Set up lines counter
LISTLP: pop     hl              ; Restore address of line
        ld      c,(hl)          ; Get LSB of next line
        dec     hl
        ld      b,(hl)          ; Get MSB of next line
        dec     hl
        ld      a,b             ; bc = 0 (#End of program)?
        or      c
        jp      Z,#PRNTOK        ; Yes - Go to command mode
        call    COUNT           ; Count lines
        call    TSTBRK          ; Test for break key
        push    bc              ; Save address of next line
        call    PRNTCRLF        ; Output CRLF
        ld      e,(hl)          ; Get LSB of line number
        dec     hl
        ld      d,(hl)          ; Get MSB of line number
        dec     hl
        push    hl              ; Save address of line start
        ex      de,hl           ; Line number to hl
        call    PRNTHL          ; Output line number in decimal
        ld      a,#'            ; Space after line number
        pop     hl              ; Restore start of line address
LSTLP2: call    OUTC            ; Output character in a
LSTLP3: ld      a,(hl)          ; Get next byte in line
        or      a               ; End of line?
        dec     hl              ; To next byte in line
        jp      Z,#LISTLP        ; Yes - get next line
        jp      P,#LSTLP2        ; No token - output it
        sub     #ZEND-1          ; Find and output word
        ld      c,a             ; Token offset+1 to c
        ld      de,#WORDS        ; Reserved word list
FNDTOK: ld      a,(de)          ; Get character in list
        dec     de              ; Move on to next
        or      a               ; Is it start of word?
        jp      P,#FNDTOK        ; No - Keep looking for word
        dec     c               ; Count words
        jp      NZ,#FNDTOK       ; Not there - keep looking
OUTWRD: and     #0x7f	;0111 1111B       ; Strip bit 7
        call    OUTC            ; Output first character
        ld      a,(de)          ; Get next character
        dec     de              ; Move on to next
        or      a               ; Is it end of word?
        jp      P,#OUTWRD        ; No - output the rest
        jp      LSTLP3          ; Next byte in line

SETLIN: push    hl              ; Set up LINES counter
        ld      hl,(#LINESN)     ; Get LINES number
        ld      (#LINESC),hl     ; Save in LINES counter
        pop     hl
        ret

COUNT:  push    hl              ; Save code string address
        push    de
        ld      hl,(#LINESC)     ; Get LINES counter
        ld      de,#-1
        adc     hl,de           ; Decrement
        ld      (#LINESC),hl     ; Put it back
        pop     de
        pop     hl              ; Restore code string address
        ret     P               ; Return if more lines to go
        push    hl              ; Save code string address
        ld      hl,(#LINESN)     ; Get LINES number
        ld      (#LINESC),hl     ; Reset LINES counter
        call    GETINP          ; Get input character
        cp      #CTRLC           ; Is it control "c"?
        jp      Z,#RSLNBK        ; Yes - Reset LINES and break
        pop     hl              ; Restore code string address
        jp      COUNT           ; Keep on counting

RSLNBK: ld      hl,(#LINESN)     ; Get LINES number
        ld      (#LINESC),hl     ; Reset LINES counter
        jp      BRKRET          ; Go and output "Break"

FOR:    ld      a,#0x64           ; Flag "FOR" assignment
        ld      (#FORFLG),a      ; Save "FOR" flag
        call    LET             ; Set up initial index
        pop     bc              ; Drop RETurn address
        push    hl              ; Save code string address
        call    DATA            ; Get next statement address
        ld      (#LOOPST),hl     ; Save it for start of loop
        ld      hl,#2            ; Offset for "FOR" block
        add     hl,sp           ; Point to it
FORSLP: call    LOKFOR          ; Look for existing "FOR" block
        pop     de              ; Get code string address
        jp      NZ,#FORFND       ; No nesting found
        add     hl,bc           ; Move into "FOR" block
        push    de              ; Save code string address
        dec     hl
        ld      d,(hl)          ; Get MSB of loop statement
        dec     hl
        ld      e,(hl)          ; Get LSB of loop statement
        dec     hl
        dec     hl
        push    hl              ; Save block address
        ld      hl,(#LOOPST)     ; Get address of loop statement
        call    CPDEHL          ; Compare the FOR loops
        pop     hl              ; Restore block address
        jp      NZ,#FORSLP       ; Different FORs - Find another
        pop     de              ; Restore code string address
        ld      sp,hl           ; Remove all nested loops

FORFND: ex      de,hl           ; Code string address to hl
        ld      c,#8
        call    CHKSTK          ; Check for 8 levels of stack
        push    hl              ; Save code string address
        ld      hl,(#LOOPST)     ; Get first statement of loop
        ex      (sp),hl         ; Save and restore code string
        push    hl              ; Re-save code string address
        ld      hl,(#LINEAT)     ; Get current line number
        ex      (sp),hl         ; Save and restore code string
        call    TSTNUM          ; Make sure it's a number
        call    CHKSYN          ; Make sure "TO" is next
        .byte   ZTO          ; "TO" token
        call    GETNUM          ; Get "TO" expression value
        push    hl              ; Save code string address
        call    BCDEFP          ; Move "TO" value to BCDE
        pop     hl              ; Restore code string address
        push    bc              ; Save "TO" value in block
        push    de
        ld      bc,#0x8100        ; BCDE - 1 (default STEP)
        ld      d,c             ; c=0
        ld      e,d             ; d=0
        ld      a,(hl)          ; Get next byte in code string
        cp      #ZSTEP           ; See if "STEP" is stated
        ld      a,#1             ; Sign of step = 1
        jp      NZ,#SAVSTP       ; No STEP given - Default to 1
        call    GETCHR          ; Jump over "STEP" token
        call    GETNUM          ; Get step value
        push    hl              ; Save code string address
        call    BCDEFP          ; Move STEP to BCDE
        call    TSTSGN          ; Test sign of FPREG
        pop     hl              ; Restore code string address
SAVSTP: push    bc              ; Save the STEP value in block
        push    de
        push    af              ; Save sign of STEP
        dec     sp              ; Don't save flags
        push    hl              ; Save code string address
        ld      hl,(#BRKLIN)     ; Get address of index variable
        ex      (sp),hl         ; Save and restore code string
PUTFID: ld      b,#ZFOR          ; "FOR" block marker
        push    bc              ; Save it
        dec     sp              ; Don't save c

RUNCNT: call    TSTBRK          ; Execution driver - Test break
        ld      (#BRKLIN),hl     ; Save code address for break
        ld      a,(hl)          ; Get next byte in code string
        cp      #':             ; Multi statement line?
        jp      Z,#EXCUTE        ; Yes - Execute it
        or      a               ; End of line?
        jp      NZ,#SNERR        ; No - Syntax error
        dec     hl              ; Point to address of next line
        ld      a,(hl)          ; Get LSB of line pointer
        dec     hl
        or      (hl)            ; Is it zero (#End of prog)?
        jp      Z,#ENDPRG        ; Yes - Terminate execution
        dec     hl              ; Point to line number
        ld      e,(hl)          ; Get LSB of line number
        dec     hl
        ld      d,(hl)          ; Get MSB of line number
        ex      de,hl           ; Line number to hl
        ld      (#LINEAT),hl     ; Save as current line number
        ex      de,hl           ; Line number back to de
EXCUTE: call    GETCHR          ; Get key word
        ld      de,#RUNCNT       ; Where to RETurn to
        push    de              ; Save for RETurn
IFJMP:  ret     Z               ; Go to RUNCNT if end of STMT
ONJMP:  sub     #ZEND            ; Is it a token?
        jp      c,#LET           ; No - try to assign it
        cp      #ZNEW+1-ZEND     ; END to NEW ?
        jp      NC,#SNERR        ; Not a key word - ?SN Error
        rlca                    ; Double it
        ld      c,a             ; bc = Offset into table
        ld      b,#0
        ex      de,hl           ; Save code string address
        ld      hl,#WORDTB       ; Keyword address table
        add     hl,bc           ; Point to routine address
        ld      c,(hl)          ; Get LSB of routine address
        dec     hl
        ld      b,(hl)          ; Get MSB of routine address
        push    bc              ; Save routine address
        ex      de,hl           ; Restore code string address

GETCHR: dec     hl              ; Point to next character
        ld      a,(hl)          ; Get next code string byte
        cp      #':             ; Z if ':'
        ret     NC              ; NC if > "9"
        cp      #' 
        jp      Z,#GETCHR        ; Skip over spaces
        cp      #'0
        ccf                     ; NC if < '0'
        dec     a               ; Test for zero - Leave carry
        dec     a               ; Z if Null
        ret

RESTOR: ex      de,hl           ; Save code string address
        ld      hl,(#BASTXT)     ; Point to start of program
        jp      Z,#RESTNL        ; Just RESTORE - reset pointer
        ex      de,hl           ; Restore code string address
        call    ATOH            ; Get line number to de
        push    hl              ; Save code string address
        call    SRCHLN          ; Search for line number in de
        ld      h,b             ; hl = Address of line
        ld      l,c
        pop     de              ; Restore code string address
        jp      NC,#ULERR        ; ?UL Error if not found
RESTNL: dec     hl              ; Byte before DATA statement
UPDATA: ld      (#NXTDAT),hl     ; Update DATA pointer
        ex      de,hl           ; Restore code string address
        ret


TSTBRK: rst     0x18             ; Check input status
        ret     Z               ; No key, go back
        rst     0x10             ; Get the key into a
        cp      #ESC             ; Escape key?
        jr      Z,BRK           ; Yes, break
        cp      #CTRLC           ; <Ctrl-c>
        jr      Z,BRK           ; Yes, break
        cp      #CTRLS           ; Stop scrolling?
        ret     NZ              ; Other key, ignore


STALL:  rst     0x10             ; Wait for key
        cp      #CTRLQ           ; Resume scrolling?
        ret      Z              ; Release the chokehold
        cp      #CTRLC           ; Second break?
        jr      Z,#STOP          ; Break during hold exits prog
        jr      STALL           ; Loop until <Ctrl-Q> or <brk>

BRK:     ld      a,#0xFF           ; Set BRKFLG
        ld      (#BRKFLG),a      ; Store it


STOP:   ret     NZ              ; Exit if anything else
        .byte   0xF6            ; Flag "STOP"
PEND:   ret     NZ              ; Exit if anything else
        ld      (#BRKLIN),hl     ; Save point of break
        .byte   0x21             ; Skip "or 11111111B"
INPBRK: or      #0xFF	;1111 1111B       ; Flag "Break" wanted
        pop     bc              ; Return not needed and more
ENDPRG: ld      hl,(#LINEAT)     ; Get current line number
        push    af              ; Save STOP / END status
        ld      a,l             ; Is it direct break?
        and     h
        dec     a               ; Line is -1 if direct break
        jp      Z,#NOLIN         ; Yes - No line number
        ld      (#ERRLIN),hl     ; Save line of break
        ld      hl,(#BRKLIN)     ; Get point of break
        ld      (#CONTAD),hl     ; Save point to CONTinue
NOLIN:  xor     a
        ld      (#CTLOFG),a      ; Enable output
        call    STTLIN          ; Start a new line
        pop     af              ; Restore STOP / END status
        ld      hl,#BRKMSG       ; "Break" message
        jp      NZ,#ERRIN        ; "in line" wanted?
        jp      PRNTOK          ; Go to command mode

CONT:   ld      hl,(#CONTAD)     ; Get CONTinue address
        ld      a,h             ; Is it zero?
        or      l
        ld      e,#CN            ; ?CN Error
        jp      Z,#ERROR         ; Yes - output "?CN Error"
        ex      de,hl           ; Save code string address
        ld      hl,(#ERRLIN)     ; Get line of last break
        ld      (#LINEAT),hl     ; Set up current line number
        ex      de,hl           ; Restore code string address
        ret                     ; CONTinue where left off

NULL:   call    GETINT          ; Get integer 0-255
        ret     NZ              ; Return if bad value
        ld      (#NULLS),a       ; Set nulls number
        ret


ACCSUM: push    hl              ; Save address in array
        ld      hl,(#CHKSUM)     ; Get check sum
        ld      b,#0             ; bc - Value of byte
        ld      c,a
        add     hl,bc           ; Add byte to check sum
        ld      (#CHKSUM),hl     ; Re-save check sum
        pop     hl              ; Restore address in array
        ret

CHKLTR: ld      a,(hl)          ; Get byte
        cp      #'a             ; < 'a' ?
        ret     c               ; Carry set if not letter
        cp      #'Z+1           ; > 'z' ?
        ccf
        ret                     ; Carry set if not letter

FPSINT: call    GETCHR          ; Get next character
POSINT: call    GETNUM          ; Get integer 0 to 32767
DEPINT: call    TSTSGN          ; Test sign of FPREG
        jp      M,#FCERR         ; Negative - ?FC Error
DEINT:  ld      a,(#FPEXP)       ; Get integer value to de
        cp      #0x80+16          ; Exponent in range (#16 bits)?
        jp      c,#FPINT         ; Yes - convert it
        ld      bc,#0x9080        ; BCDE = -32768
        ld      de,#0x0000
        push    hl              ; Save code string address
        call    CMPNUM          ; Compare FPREG with BCDE
        pop     hl              ; Restore code string address
        ld      d,c             ; MSB to d
        ret     Z               ; Return if in range
FCERR:  ld      e,#FC            ; ?FC Error
        jp      ERROR           ; Output error-

ATOH:   dec     hl              ; ASCII number to de binary
GETLN:  ld      de,#0            ; Get number to de
GTLNLP: call    GETCHR          ; Get next character
        ret     NC              ; Exit if not a digit
        push    hl              ; Save code string address
        push    af              ; Save digit
        ld      hl,#65529/10     ; Largest number 65529
        call    CPDEHL          ; Number in range?
        jp      c,#SNERR         ; No - ?SN Error
        ld      h,d             ; hl = Number
        ld      l,e
        add     hl,de           ; Times 2
        add     hl,hl           ; Times 4
        add     hl,de           ; Times 5
        add     hl,hl           ; Times 10
        pop     af              ; Restore digit
        sub     #'0             ; Make it 0 to 9
        ld      e,a             ; de = Value of digit
        ld      d,#0
        add     hl,de           ; Add to number
        ex      de,hl           ; Number to de
        pop     hl              ; Restore code string address
        jp      GTLNLP          ; Go to next character

CLEAR:  jp      Z,#INTVAR        ; Just "CLEAR" Keep parameters
        call    POSINT          ; Get integer 0 to 32767 to de
        dec     hl              ; Cancel increment
        call    GETCHR          ; Get next character
        push    hl              ; Save code string address
        ld      hl,(#LSTRAM)     ; Get end of RAM
        jp      Z,#STORED        ; No value given - Use stored
        pop     hl              ; Restore code string address
        call    CHKSYN          ; Check for comma
        .byte      #',
        push    de              ; Save number
        call    POSINT          ; Get integer 0 to 32767
        dec     hl              ; Cancel increment
        call    GETCHR          ; Get next character
        jp      NZ,#SNERR        ; ?SN Error if more on line
        ex      (sp),hl         ; Save code string address
        ex      de,hl           ; Number to de
STORED: ld      a,l             ; Get LSB of new RAM top
        sub     e               ; Subtract LSB of string space
        ld      e,a             ; Save LSB
        ld      a,h             ; Get MSB of new RAM top
        sbc     a,d             ; Subtract MSB of string space
        ld      d,a             ; Save MSB
        jp      c,#OMERR         ; ?OM Error if not enough mem
        push    hl              ; Save RAM top
        ld      hl,(#PROGND)     ; Get program end
        ld      bc,#40           ; 40 Bytes minimum working RAM
        add     hl,bc           ; Get lowest address
        call    CPDEHL          ; Enough memory?
        jp      NC,#OMERR        ; No - ?OM Error
        ex      de,hl           ; RAM top to hl
        ld      (#STRSPC),hl     ; Set new string space
        pop     hl              ; End of memory to use
        ld      (#LSTRAM),hl     ; Set new top of RAM
        pop     hl              ; Restore code string address
        jp      INTVAR          ; Initialise variables

RUN:    jp      Z,#RUNFST        ; RUN from start if just RUN
        call    INTVAR          ; Initialise variables
        ld      bc,#RUNCNT       ; Execution driver loop
        jp      RUNLIN          ; RUN from line number

GOSUB:  ld      c,#3             ; 3 Levels of stack needed
        call    CHKSTK          ; Check for 3 levels of stack
        pop     bc              ; Get return address
        push    hl              ; Save code string for RETURN
        push    hl              ; And for GOSUB routine
        ld      hl,(#LINEAT)     ; Get current line
        ex      (sp),hl         ; Into stack - Code string out
        ld      a,#ZGOSUB        ; "GOSUB" token
        push    af              ; Save token
        dec     sp              ; Don't save flags

RUNLIN: push    bc              ; Save return address
GOTO:   call    ATOH            ; ASCII number to de binary
        call    REM             ; Get end of line
        push    hl              ; Save end of line
        ld      hl,(#LINEAT)     ; Get current line
        call    CPDEHL          ; Line after current?
        pop     hl              ; Restore end of line
        dec     hl              ; Start of next line
        call    c,#SRCHLP        ; Line is after current line
        call    NC,#SRCHLN       ; Line is before current line
        ld      h,b             ; Set up code string address
        ld      l,c
        dec     hl              ; Incremented after
        ret     c               ; Line found
ULERR:  ld      e,#UL            ; ?UL Error
        jp      ERROR           ; Output error message

RETURN: ret     NZ              ; Return if not just RETURN
        ld      d,#-1            ; Flag "GOSUB" search
        call    BAKSTK          ; Look "GOSUB" block
        ld      sp,hl           ; Kill all FORs in subroutine
        cp      #ZGOSUB          ; Test for "GOSUB" token
        ld      e,#RG            ; ?RG Error
        jp      NZ,#ERROR        ; Error if no "GOSUB" found
        pop     hl              ; Get RETURN line number
        ld      (#LINEAT),hl     ; Save as current
        dec     hl              ; Was it from direct statement?
        ld      a,h
        or      l               ; Return to line
        jp      NZ,#RETLIN       ; No - Return to line
        ld      a,(#LSTBIN)      ; Any INPUT in subroutine?
        or      a               ; If so buffer is corrupted
        jp      NZ,#POPNOK       ; Yes - Go to command mode
RETLIN: ld      hl,#RUNCNT       ; Execution driver loop
        ex      (sp),hl         ; Into stack - Code string out
        .byte      0x3E             ; Skip "pop hl"
NXTDTA: pop     hl              ; Restore code string address

DATA:   .byte      0x01,#':     ; ':' End of statement
REM:    ld      c,#0             ; 00  End of statement
        ld      b,#0
NXTSTL: ld      a,c             ; Statement and byte
        ld      c,b
        ld      b,a             ; Statement end byte
NXTSTT: ld      a,(hl)          ; Get byte
        or      a               ; End of line?
        ret     Z               ; Yes - Exit
        cp      b               ; End of statement?
        ret     Z               ; Yes - Exit
        dec     hl              ; Next byte
        cp      #'"             ; Literal string?
        jp      Z,#NXTSTL        ; Yes - Look for another '"'
        jp      NXTSTT          ; Keep looking

LET:    call    GETVAR          ; Get variable name
        call    CHKSYN          ; Make sure "=" follows
        .byte      ZEQUAL          ; "=" token
        push    de              ; Save address of variable
        ld      a,(#TYPE)        ; Get data type
        push    af              ; Save type
        call    EVAL            ; Evaluate expression
        pop     af              ; Restore type
        ex      (sp),hl         ; Save code - Get var addr
        ld      (#BRKLIN),hl     ; Save address of variable
        rra                     ; Adjust type
        call    CHKTYP          ; Check types are the same
        jp      Z,#LETNUM        ; Numeric - Move value
LETSTR: push    hl              ; Save address of string var
        ld      hl,(#FPREG)      ; Pointer to string entry
        push    hl              ; Save it on stack
        dec     hl              ; Skip over length
        dec     hl
        ld      e,(hl)          ; LSB of string address
        dec     hl
        ld      d,(hl)          ; MSB of string address
        ld      hl,(#BASTXT)     ; Point to start of program
        call    CPDEHL          ; Is string before program?
        jp      NC,#CRESTR       ; Yes - Create string entry
        ld      hl,(#STRSPC)     ; Point to string space
        call    CPDEHL          ; Is string literal in program?
        pop     de              ; Restore address of string
        jp      NC,#MVSTPT       ; Yes - Set up pointer
        ld      hl,#TMPSTR       ; Temporary string pool
        call    CPDEHL          ; Is string in temporary pool?
        jp      NC,#MVSTPT       ; No - Set up pointer
        .byte   0x3E             ; Skip "pop de"
CRESTR: pop     de              ; Restore address of string
        call    BAKTMP          ; Back to last tmp-str entry
        ex      de,hl           ; Address of string entry
        call    SAVSTR          ; Save string in string area
MVSTPT: call    BAKTMP          ; Back to last tmp-str entry
        pop     hl              ; Get string pointer
        call    DETHL4          ; Move string pointer to var
        pop     hl              ; Restore code string address
        ret

LETNUM: push    hl              ; Save address of variable
        call    FPTHL           ; Move value to variable
        pop     de              ; Restore address of variable
        pop     hl              ; Restore code string address
        ret

ON:     call    GETINT          ; Get integer 0-255
        ld      a,(hl)          ; Get "GOTO" or "GOSUB" token
        ld      b,a             ; Save in b
        cp      #ZGOSUB          ; "GOSUB" token?
        jp      Z,#ONGO          ; Yes - Find line number
        call    CHKSYN          ; Make sure it's "GOTO"
        .byte   ZGOTO           ; "GOTO" token
        dec     hl              ; Cancel increment
ONGO:   ld      c,e             ; Integer of branch value
ONGOLP: dec     c               ; Count branches
        ld      a,b             ; Get "GOTO" or "GOSUB" token
        jp      Z,#ONJMP         ; Go to that line if right one
        call    GETLN           ; Get line number to de
        cp      #',             ; Another line number?
        ret     NZ              ; No - Drop through
        jp      ONGOLP          ; Yes - loop

IF:     call    EVAL            ; Evaluate expression
        ld      a,(hl)          ; Get token
        cp      #ZGOTO           ; "GOTO" token?
        jp      Z,#IFGO          ; Yes - Get line
        call    CHKSYN          ; Make sure it's "THEN"
        .byte      ZTHEN           ; "THEN" token
        dec     hl              ; Cancel increment
IFGO:   call    TSTNUM          ; Make sure it's numeric
        call    TSTSGN          ; Test state of expression
        jp      Z,#REM           ; False - Drop through
        call    GETCHR          ; Get next character
        jp      c,#GOTO          ; Number - GOTO that line
        jp      IFJMP           ; Otherwise do statement

MRPRNT: dec     hl              ; dec 'cos GETCHR INCs
        call    GETCHR          ; Get next character
PRINT:  jp      Z,#PRNTCRLF      ; CRLF if just PRINT
PRNTLP: ret     Z               ; End of list - Exit
        cp      #ZTAB            ; "TAB(" token?
        jp      Z,#DOTAB         ; Yes - Do TAB routine
        cp      #ZSPC            ; "SPC(" token?
        jp      Z,#DOTAB         ; Yes - Do SPC routine
        push    hl              ; Save code string address
        cp      #',             ; Comma?
        jp      Z,#DOCOM         ; Yes - Move to next zone
        cp      #';         ; Semi-colon?
        jp      Z,#NEXITM        ; Do semi-colon routine
        pop     bc              ; Code string address to bc
        call    EVAL            ; Evaluate expression
        push    hl              ; Save code string address
        ld      a,(#TYPE)        ; Get variable type
        or      a               ; Is it a string variable?
        jp      NZ,#PRNTST       ; Yes - Output string contents
        call    NUMASC          ; Convert number to text
        call    CRTST           ; Create temporary string
        ld      (hl),#'         ; Followed by a space
        ld      hl,(#FPREG)      ; Get length of output
        dec     (hl)            ; Plus 1 for the space
        ld      hl,(#FPREG)      ; < Not needed >
        ld      a,(#LWIDTH)      ; Get width of line
        ld      b,a             ; To b
        dec     b               ; Width 255 (#No limit)?
        jp      Z,#PRNTNB        ; Yes - Output number string
        dec     b               ; Adjust it
        ld      a,(#CURPOS)      ; Get cursor position
        add     a,(hl)          ; Add length of string
        dec     a               ; Adjust it
        cp      b               ; Will output fit on this line?
        call    NC,#PRNTCRLF     ; No - CRLF first
PRNTNB: call    PRS1            ; Output string at (hl)
        xor     a               ; Skip call by setting 'z' flag
PRNTST: call    NZ,#PRS1         ; Output string at (hl)
        pop     hl              ; Restore code string address
        jp      MRPRNT          ; See if more to PRINT

STTLIN: ld      a,(#CURPOS)      ; Make sure on new line
        or      a               ; Already at start?
        ret     Z               ; Yes - Do nothing
        jp      PRNTCRLF        ; Start a new line

ENDINP: ld      (hl),#0          ; Mark end of buffer
        ld      hl,#BUFFER-1     ; Point to buffer
PRNTCRLF: ld    a,#CR            ; Load a CR
        call    OUTC            ; Output character
        ld      a,#LF            ; Load a LF
        call    OUTC            ; Output character
DONULL: xor     a               ; Set to position 0
        ld      (#CURPOS),a      ; Store it
        ld      a,(#NULLS)       ; Get number of nulls
NULLP:  dec     a               ; Count them
        ret     Z               ; Return if done
        push    af              ; Save count
        xor     a               ; Load a null
        call    OUTC            ; Output it
        pop     af              ; Restore count
        jp      NULLP           ; Keep counting

DOCOM:  ld      a,(#COMMAN)      ; Get comma width
        ld      b,a             ; Save in b
        ld      a,(#CURPOS)      ; Get current position
        cp      b               ; Within the limit?
        call    NC,#PRNTCRLF     ; No - output CRLF
        jp      NC,#NEXITM       ; Get next item
ZONELP: sub     #14              ; Next zone of 14 characters
        jp      NC,#ZONELP       ; Repeat if more zones
        cpl                     ; Number of spaces to output
        jp      ASPCS           ; Output them

DOTAB:  push    af              ; Save token
        call    FNDNUM          ; Evaluate expression
        call    CHKSYN          ; Make sure ")" follows
        .byte   #')
        dec     hl              ; Back space on to ")"
        pop     af              ; Restore token
        sub     #ZSPC            ; Was it "SPC(" ?
        push    hl              ; Save code string address
        jp      Z,#DOSPC         ; Yes - Do 'e' spaces
        ld      a,(#CURPOS)      ; Get current position
DOSPC:  cpl                     ; Number of spaces to print to
        add     a,e             ; Total number to print
        jp      NC,#NEXITM       ; TAB < Current POS(#X)
ASPCS:  dec     a               ; Output a spaces
        ld      b,a             ; Save number to print
        ld      a,#'            ; Space
SPCLP:  call    OUTC            ; Output character in a
        dec     b               ; Count them
        jp      NZ,#SPCLP        ; Repeat if more
NEXITM: pop     hl              ; Restore code string address
        call    GETCHR          ; Get next character
        jp      PRNTLP          ; More to print

REDO:   .ascii   "?Redo from start"
	.byte	#CR,#LF,#0

BADINP: ld      a,(#READFG)      ; READ or INPUT?
        or      a
        jp      NZ,#DATSNR       ; READ - ?SN Error
        pop     bc              ; Throw away code string addr
        ld      hl,#REDO         ; "Redo from start" message
        call    PRS             ; Output string
        jp      DOAGN           ; Do last INPUT again

INPUT:  call    IDTEST          ; Test for illegal direct
        ld      a,(hl)          ; Get character after "INPUT"
        cp      #'"             ; Is there a prompt string?
        ld      a,#0             ; Clear a and leave flags
        ld      (#CTLOFG),a      ; Enable output
        jp      NZ,#NOPMPT       ; No prompt - get input
        call    QTSTR           ; Get string terminated by '"'
        call    CHKSYN          ; Check for ';' after prompt
        .byte   #';
        push    hl              ; Save code string address
        call    PRS1            ; Output prompt string
        .byte   #0x3E             ; Skip "push hl"
NOPMPT: push    hl              ; Save code string address
        call    PROMPT          ; Get input with "? " prompt
        pop     bc              ; Restore code string address
        jp      c,#INPBRK        ; Break pressed - Exit
        dec     hl              ; Next byte
        ld      a,(hl)          ; Get it
        or      a               ; End of line?
        dec     hl              ; Back again
        push    bc              ; Re-save code string address
        jp      Z,#NXTDTA        ; Yes - Find next DATA stmt
        ld      (hl),#',        ; Store comma as separator
        jp      NXTITM          ; Get next item

READ:   push    hl              ; Save code string address
        ld      hl,(#NXTDAT)     ; Next DATA statement
        .byte   0xF6            ; Flag "READ"
NXTITM: xor     a               ; Flag "INPUT"
        ld      (#READFG),a      ; Save "READ"/"INPUT" flag
        ex      (sp),hl         ; Get code str' , Save pointer
        jp      GTVLUS          ; Get values

NEDMOR: call    CHKSYN          ; Check for comma between items
        .byte      #',
GTVLUS: call    GETVAR          ; Get variable name
        ex      (sp),hl         ; Save code str" , Get pointer
        push    de              ; Save variable address
        ld      a,(hl)          ; Get next "INPUT"/"DATA" byte
        cp      #',             ; Comma?
        jp      Z,#ANTVLU        ; Yes - Get another value
        ld      a,(#READFG)      ; Is it READ?
        or      a
        jp      NZ,#FDTLP        ; Yes - Find next DATA stmt
        ld      a,#'?           ; More INPUT needed
        call    OUTC            ; Output character
        call    PROMPT          ; Get INPUT with prompt
        pop     de              ; Variable address
        pop     bc              ; Code string address
        jp      c,#INPBRK        ; Break pressed
        dec     hl              ; Point to next DATA byte
        ld      a,(hl)          ; Get byte
        or      a               ; Is it zero (#No input) ?
        dec     hl              ; Back space INPUT pointer
        push    bc              ; Save code string address
        jp      Z,#NXTDTA        ; Find end of buffer
        push    de              ; Save variable address
ANTVLU: ld      a,(#TYPE)        ; Check data type
        or      a               ; Is it numeric?
        jp      Z,#INPBIN        ; Yes - Convert to binary
        call    GETCHR          ; Get next character
        ld      d,a             ; Save input character
        ld      b,a             ; Again
        cp      #'"             ; Start of literal sting?
        jp      Z,#STRENT        ; Yes - Create string entry
        ld      a,(#READFG)      ; "READ" or "INPUT" ?
        or      a
        ld      d,a             ; Save 00 if "INPUT"
        jp      Z,#ITMSEP        ; "INPUT" - End with 00
        ld      d,#':           ; "DATA" - End with 00 or ':'
ITMSEP: ld      b,#',           ; Item separator
        dec     hl              ; Back space for DTSTR
STRENT: call    DTSTR           ; Get string terminated by d
        ex      de,hl           ; String address to de
        ld      hl,#LTSTND       ; Where to go after LETSTR
        ex      (sp),hl         ; Save hl , get input pointer
        push    de              ; Save address of string
        jp      LETSTR          ; Assign string to variable

INPBIN: call    GETCHR          ; Get next character
        call    ASCTFP          ; Convert ASCII to FP number
        ex      (sp),hl         ; Save input ptr, Get var addr
        call    FPTHL           ; Move FPREG to variable
        pop     hl              ; Restore input pointer
LTSTND: dec     hl              ; dec 'cos GETCHR INCs
        call    GETCHR          ; Get next character
        jp      Z,#MORDT         ; End of line - More needed?
        cp      #',             ; Another value?
        jp      NZ,#BADINP       ; No - Bad input
MORDT:  ex      (sp),hl         ; Get code string address
        dec     hl              ; dec 'cos GETCHR INCs
        call    GETCHR          ; Get next character
        jp      NZ,#NEDMOR       ; More needed - Get it
        pop     de              ; Restore DATA pointer
        ld      a,(#READFG)      ; "READ" or "INPUT" ?
        or      a
        ex      de,hl           ; DATA pointer to hl
        jp      NZ,#UPDATA       ; Update DATA pointer if "READ"
        push    de              ; Save code string address
        or      (hl)            ; More input given?
        ld      hl,#EXTIG        ; "?Extra ignored" message
        call    NZ,#PRS          ; Output string if extra given
        pop     hl              ; Restore code string address
        ret

EXTIG:  .ascii	"?Extra ignored"
	.byte	#CR,#LF,#0

FDTLP:  call    DATA            ; Get next statement
        or      a               ; End of line?
        jp      NZ,#FANDT        ; No - See if DATA statement
        dec     hl
        ld      a,(hl)          ; End of program?
        dec     hl
        or      (hl)            ; 00 00 Ends program
        ld      e,#OD            ; ?OD Error
        jp      Z,#ERROR         ; Yes - Out of DATA
        dec     hl
        ld      e,(hl)          ; LSB of line number
        dec     hl
        ld      d,(hl)          ; MSB of line number
        ex      de,hl
        ld      (#DATLIN),hl     ; Set line of current DATA item
        ex      de,hl
FANDT:  call    GETCHR          ; Get next character
        cp      #ZDATA           ; "DATA" token
        jp      NZ,#FDTLP        ; No "DATA" - Keep looking
        jp      ANTVLU          ; Found - Convert input

NEXT:   ld      de,#0            ; In case no index given
NEXT1:  call    NZ,#GETVAR       ; Get index address
        ld      (#BRKLIN),hl     ; Save code string address
        call    BAKSTK          ; Look for "FOR" block
        jp      NZ,#NFERR        ; No "FOR" - ?NF Error
        ld      sp,hl           ; Clear nested loops
        push    de              ; Save index address
        ld      a,(hl)          ; Get sign of STEP
        dec     hl
        push    af              ; Save sign of STEP
        push    de              ; Save index address
        call    PHLTFP          ; Move index value to FPREG
        ex      (sp),hl         ; Save address of TO value
        push    hl              ; Save address of index
        call    ADDPHL          ; Add STEP to index value
        pop     hl              ; Restore address of index
        call    FPTHL           ; Move value to index variable
        pop     hl              ; Restore address of TO value
        call    LOADFP          ; Move TO value to BCDE
        push    hl              ; Save address of line of FOR
        call    CMPNUM          ; Compare index with TO value
        pop     hl              ; Restore address of line num
        pop     bc              ; Address of sign of STEP
        sub     b               ; Compare with expected sign
        call    LOADFP          ; bc = Loop stmt,de = Line num
        jp      Z,#KILFOR        ; Loop finished - Terminate it
        ex      de,hl           ; Loop statement line number
        ld      (#LINEAT),hl     ; Set loop line number
        ld      l,c             ; Set code string to loop
        ld      h,b
        jp      PUTFID          ; Put back "FOR" and continue

KILFOR: ld      sp,hl           ; Remove "FOR" block
        ld      hl,(#BRKLIN)     ; Code string after "NEXT"
        ld      a,(hl)          ; Get next byte in code string
        cp      #',             ; More NEXTs ?
        jp      NZ,#RUNCNT       ; No - Do next statement
        call    GETCHR          ; Position to index name
        call    NEXT1           ; Re-enter NEXT routine
; < will not RETurn to here , Exit to RUNCNT or Loop >

GETNUM: call    EVAL            ; Get a numeric expression
TSTNUM: .byte      0xF6            ; Clear carry (numeric)
TSTSTR: scf                     ; Set carry (string)
CHKTYP: ld      a,(#TYPE)        ; Check types match
        adc     a,a             ; Expected + actual
        or      a               ; Clear carry , set parity
        ret     PE              ; Even parity - Types match
        jp      TMERR           ; Different types - Error

OPNPAR: call    CHKSYN          ; Make sure "(" follows
        .byte   "("
EVAL:   dec     hl              ; Evaluate expression & save
        ld      d,#0             ; Precedence value
EVAL1:  push    de              ; Save precedence
        ld      c,#1
        call    CHKSTK          ; Check for 1 level of stack
        call    OPRND           ; Get next expression value
EVAL2:  ld      (#NXTOPR),hl     ; Save address of next operator
EVAL3:  ld      hl,(#NXTOPR)     ; Restore address of next opr
        pop     bc              ; Precedence value and operator
        ld      a,b             ; Get precedence value
        cp      #0x78             ; "and" or "or" ?
        call    NC,#TSTNUM       ; No - Make sure it's a number
        ld      a,(hl)          ; Get next operator / function
        ld      d,#0             ; Clear Last relation
RLTLP:  sub     #ZGTR            ; ">" Token
        jp      c,#FOPRND        ; + - * / ^ and or - Test it
        cp      #ZLTH+1-ZGTR     ; < = >
        jp      NC,#FOPRND       ; Function - Call it
        cp      #ZEQUAL-ZGTR     ; "="
        rla                     ; <- Test for legal
        xor     d               ; <- combinations of < = >
        cp      d               ; <- by combining last token
        ld      d,a             ; <- with current one
        jp      c,#SNERR         ; Error if "<<' '==" or ">>"
        ld      (#CUROPR),hl     ; Save address of current token
        call    GETCHR          ; Get next character
        jp      RLTLP           ; Treat the two as one

FOPRND: ld      a,d             ; < = > found ?
        or      a
        jp      NZ,#TSTRED       ; Yes - Test for reduction
        ld      a,(hl)          ; Get operator token
        ld      (#CUROPR),hl     ; Save operator address
        sub     #ZPLUS           ; Operator or function?
        ret     c               ; Neither - Exit
        cp      #ZOR+1-ZPLUS     ; Is it + - * / ^ and or ?
        ret     NC              ; No - Exit
        ld      e,a             ; Coded operator
        ld      a,(#TYPE)        ; Get data type
        dec     a               ; FF = numeric , 00 = string
        or      e               ; Combine with coded operator
        ld      a,e             ; Get coded operator
        jp      Z,#CONCAT        ; String concatenation
        rlca                    ; Times 2
        add     a,e             ; Times 3
        ld      e,a             ; To de (d is 0)
        ld      hl,#PRITAB       ; Precedence table
        add     hl,de           ; To the operator concerned
        ld      a,b             ; Last operator precedence
        ld      d,(hl)          ; Get evaluation precedence
        cp      d               ; Compare with eval precedence
        ret     NC              ; Exit if higher precedence
        dec     hl              ; Point to routine address
        call    TSTNUM          ; Make sure it's a number

STKTHS: push    bc              ; Save last precedence & token
        ld      bc,#EVAL3        ; Where to go on prec' break
        push    bc              ; Save on stack for return
        ld      b,e             ; Save operator
        ld      c,d             ; Save precedence
        call    STAKFP          ; Move value to stack
        ld      e,b             ; Restore operator
        ld      d,c             ; Restore precedence
        ld      c,(hl)          ; Get LSB of routine address
        dec     hl
        ld      b,(hl)          ; Get MSB of routine address
        dec     hl
        push    bc              ; Save routine address
        ld      hl,(#CUROPR)     ; Address of current operator
        jp      EVAL1           ; Loop until prec' break

OPRND:  xor     a               ; Get operand routine
        ld      (#TYPE),a        ; Set numeric expected
        call    GETCHR          ; Get next character
        ld      e,#MO            ; ?MO Error
        jp      Z,#ERROR         ; No operand - Error
        jp      c,#ASCTFP        ; Number - Get value
        call    CHKLTR          ; See if a letter
        jp      NC,#CONVAR       ; Letter - Find variable
        cp	#'&				; &h = HEX, &b = BINARY
        jr	NZ, NOTAMP
        call    GETCHR          ; Get next character
        cp      #'h             ; Hex number indicated? [function added]
        jp      Z,#HEXTFP        ; Convert Hex to FPREG
        cp      #'b             ; Binary number indicated? [function added]
        jp      Z,#BINTFP        ; Convert Bin to FPREG
        ld      e,#SN            ; If neither then a ?SN Error
        jp      Z,#ERROR         ; 
NOTAMP: cp      #ZPLUS           ; '+' Token ?
        jp      Z,#OPRND         ; Yes - Look for operand
        cp      #'.             ; '.' ?
        jp      Z,#ASCTFP        ; Yes - Create FP number
        cp      #ZMINUS          ; '-' Token ?
        jp      Z,#MINUS         ; Yes - Do minus
        cp      #'"             ; Literal string ?
        jp      Z,#QTSTR         ; Get string terminated by '"'
        cp      #ZNOT            ; "NOT" Token ?
        jp      Z,#EVNOT         ; Yes - Eval NOT expression
        cp      #ZFN             ; "FN" Token ?
        jp      Z,#DOFN          ; Yes - Do FN routine
        sub     #ZSGN            ; Is it a function?
        jp      NC,#FNOFST       ; Yes - Evaluate function
EVLPAR: call    OPNPAR          ; Evaluate expression in "()"
        call    CHKSYN          ; Make sure ")" follows
        .byte   #')
        ret

MINUS:  ld      d,#'-          ; '-' precedence
        call    EVAL1           ; Evaluate until prec' break
        ld      hl,(#NXTOPR)     ; Get next operator address
        push    hl              ; Save next operator address
        call    INVSGN          ; Negate value
RETNUM: call    TSTNUM          ; Make sure it's a number
        pop     hl              ; Restore next operator address
        ret

CONVAR: call    GETVAR          ; Get variable address to de
FRMEVL: push    hl              ; Save code string address
        ex      de,hl           ; Variable address to hl
        ld      (#FPREG),hl      ; Save address of variable
        ld      a,(#TYPE)        ; Get type
        or      a               ; Numeric?
        call    Z,#PHLTFP        ; Yes - Move contents to FPREG
        pop     hl              ; Restore code string address
        ret

FNOFST: ld      b,#0             ; Get address of function
        rlca                    ; Double function offset
        ld      c,a             ; bc = Offset in function table
        push    bc              ; Save adjusted token value
        call    GETCHR          ; Get next character
        ld      a,c             ; Get adjusted token value
        cp      #2*(ZLEFT-ZSGN)-1; Adj' LEFT$,#RIGHT$ or MID$ ?
        jp      c,#FNVAL         ; No - Do function
        call    OPNPAR          ; Evaluate expression  (#X,...
        call    CHKSYN          ; Make sure ',' follows
        .byte   #',
        call    TSTSTR          ; Make sure it's a string
        ex      de,hl           ; Save code string address
        ld      hl,(#FPREG)      ; Get address of string
        ex      (sp),hl         ; Save address of string
        push    hl              ; Save adjusted token value
        ex      de,hl           ; Restore code string address
        call    GETINT          ; Get integer 0-255
        ex      de,hl           ; Save code string address
        ex      (sp),hl         ; Save integer,hl = adj' token
        jp      GOFUNC          ; Jump to string function

FNVAL:  call    EVLPAR          ; Evaluate expression
        ex      (sp),hl         ; hl = Adjusted token value
        ld      de,#RETNUM       ; Return number from function
        push    de              ; Save on stack
GOFUNC: ld      bc,#FNCTAB       ; Function routine addresses
        add     hl,bc           ; Point to right address
        ld      c,(hl)          ; Get LSB of address
        dec     hl              ;
        ld      h,(hl)          ; Get MSB of address
        ld      l,c             ; Address to hl
        jp      (hl)            ; Jump to function

SGNEXP: dec     d               ; Dee to flag negative exponent
        cp      #ZMINUS          ; '-' token ?
        ret     Z               ; Yes - Return
        cp      #'-             ; '-' ASCII ?
        ret     Z               ; Yes - Return
        dec     d               ; Inc to flag positive exponent
        cp      #'+             ; '+' ASCII ?
        ret     Z               ; Yes - Return
        cp      #ZPLUS           ; '+' token ?
        ret     Z               ; Yes - Return
        dec     hl              ; dec 'cos GETCHR INCs
        ret                     ; Return "NZ"

POR:    .byte      0xF6            ; Flag "or"
PAND:   xor     a               ; Flag "and"
        push    af              ; Save "and" / "or" flag
        call    TSTNUM          ; Make sure it's a number
        call    DEINT           ; Get integer -32768 to 32767
        pop     af              ; Restore "and" / "or" flag
        ex      de,hl           ; <- Get last
        pop     bc              ; <-  value
        ex      (sp),hl         ; <-  from
        ex      de,hl           ; <-  stack
        call    FPBCDE          ; Move last value to FPREG
        push    af              ; Save "and" / "or" flag
        call    DEINT           ; Get integer -32768 to 32767
        pop     af              ; Restore "and" / "or" flag
        pop     bc              ; Get value
        ld      a,c             ; Get LSB
        ld      hl,#ACPASS       ; Address of save AC as current
        jp      NZ,#POR1         ; Jump if or
        and     e               ; "and" LSBs
        ld      c,a             ; Save LSB
        ld      a,b             ; Get MBS
        and     d               ; "and" MSBs
        jp      (hl)            ; Save AC as current (#ACPASS)

POR1:   or      e               ; "or" LSBs
        ld      c,a             ; Save LSB
        ld      a,b             ; Get MSB
        or      d               ; "or" MSBs
        jp      (hl)            ; Save AC as current (#ACPASS)

TSTRED: ld      hl,#CMPLOG       ; Logical compare routine
        ld      a,(#TYPE)        ; Get data type
        rra                     ; Carry set = string
        ld      a,d             ; Get last precedence value
        rla                     ; Times 2 plus carry
        ld      e,a             ; To e
        ld      d,#0x64           ; Relational precedence
        ld      a,b             ; Get current precedence
        cp      d               ; Compare with last
        ret     NC              ; Eval if last was rel' or log'
        jp      STKTHS          ; Stack this one and get next

CMPLOG: .word   CMPLG1          ; Compare two values / strings
CMPLG1: ld      a,c             ; Get data type
        or      a
        rra
        pop     bc              ; Get last expression to BCDE
        pop     de
        push    af              ; Save status
        call    CHKTYP          ; Check that types match
        ld      hl,#CMPRES       ; Result to comparison
        push    hl              ; Save for RETurn
        jp      Z,#CMPNUM        ; Compare values if numeric
        xor     a               ; Compare two strings
        ld      (#TYPE),a        ; Set type to numeric
        push    de              ; Save string name
        call    GSTRCU          ; Get current string
        ld      a,(hl)          ; Get length of string
        dec     hl
        dec     hl
        ld      c,(hl)          ; Get LSB of address
        dec     hl
        ld      b,(hl)          ; Get MSB of address
        pop     de              ; Restore string name
        push    bc              ; Save address of string
        push    af              ; Save length of string
        call    GSTRDE          ; Get second string
        call    LOADFP          ; Get address of second string
        pop     af              ; Restore length of string 1
        ld      d,a             ; Length to d
        pop     hl              ; Restore address of string 1
CMPSTR: ld      a,e             ; Bytes of string 2 to do
        or      d               ; Bytes of string 1 to do
        ret     Z               ; Exit if all bytes compared
        ld      a,d             ; Get bytes of string 1 to do
        sub     #1
        ret     c               ; Exit if end of string 1
        xor     a
        cp      e               ; Bytes of string 2 to do
        dec     a
        ret     NC              ; Exit if end of string 2
        dec     d               ; Count bytes in string 1
        dec     e               ; Count bytes in string 2
        ld      a,(bc)          ; Byte in string 2
        cp      (hl)            ; Compare to byte in string 1
        dec     hl              ; Move up string 1
        dec     bc              ; Move up string 2
        jp      Z,#CMPSTR        ; Same - Try next bytes
        ccf                     ; Flag difference (">" or "<")
        jp      FLGDIF          ; "<" gives -1 , ">" gives +1

CMPRES: dec     a               ; Increment current value
        adc     a,a             ; Double plus carry
        pop     bc              ; Get other value
        and     b               ; Combine them
        add     a,#-1            ; Carry set if different
        sbc     a,a             ; 00 - Equal , FF - Different
        jp      FLGREL          ; Set current value & continue

EVNOT:  ld      d,#0x5A           ; Precedence value for "NOT"
        call    EVAL1           ; Eval until precedence break
        call    TSTNUM          ; Make sure it's a number
        call    DEINT           ; Get integer -32768 - 32767
        ld      a,e             ; Get LSB
        cpl                     ; Invert LSB
        ld      c,a             ; Save "NOT" of LSB
        ld      a,d             ; Get MSB
        cpl                     ; Invert MSB
        call    ACPASS          ; Save AC as current
        pop     bc              ; Clean up stack
        jp      EVAL3           ; Continue evaluation

DIMRET: dec     hl              ; dec 'cos GETCHR INCs
        call    GETCHR          ; Get next character
        ret     Z               ; End of DIM statement
        call    CHKSYN          ; Make sure ',' follows
        .byte   #',
DIM:    ld      bc,#DIMRET       ; Return to "DIMRET"
        push    bc              ; Save on stack
        .byte      0xF6            ; Flag "Create" variable
GETVAR: xor     a               ; Find variable address,to de
        ld      (#LCRFLG),a      ; Set locate / create flag
        ld      b,(hl)          ; Get First byte of name
GTFNAM: call    CHKLTR          ; See if a letter
        jp      c,#SNERR         ; ?SN Error if not a letter
        xor     a
        ld      c,a             ; Clear second byte of name
        ld      (#TYPE),a        ; Set type to numeric
        call    GETCHR          ; Get next character
        jp      c,#SVNAM2        ; Numeric - Save in name
        call    CHKLTR          ; See if a letter
        jp      c,#CHARTY        ; Not a letter - Check type
SVNAM2: ld      c,a             ; Save second byte of name
ENDNAM: call    GETCHR          ; Get next character
        jp      c,#ENDNAM        ; Numeric - Get another
        call    CHKLTR          ; See if a letter
        jp      NC,#ENDNAM       ; Letter - Get another
CHARTY: sub     #'$             ; String variable?
        jp      NZ,#NOTSTR       ; No - Numeric variable
        dec     a               ; a = 1 (string type)
        ld      (#TYPE),a        ; Set type to string
        rrca                    ; a = 0x80 , Flag for string
        add     a,c             ; 2nd byte of name has bit 7 on
        ld      c,a             ; Resave second byte on name
        call    GETCHR          ; Get next character
NOTSTR: ld      a,(#FORFLG)      ; Array name needed ?
        dec     a
        jp      Z,#ARLDSV        ; Yes - Get array name
        jp      P,#NSCFOR        ; No array with "FOR" or "FN"
        ld      a,(hl)          ; Get byte again
        sub     #'(             ; Subscripted variable?
        jp      Z,#SBSCPT        ; Yes - Sort out subscript

NSCFOR: xor     a               ; Simple variable
        ld      (#FORFLG),a      ; Clear "FOR" flag
        push    hl              ; Save code string address
        ld      d,b             ; de = Variable name to find
        ld      e,c
        ld      hl,(#FNRGNM)     ; FN argument name
        call    CPDEHL          ; Is it the FN argument?
        ld      de,#FNARG        ; Point to argument value
        jp      Z,#POPHRT        ; Yes - Return FN argument value
        ld      hl,(#VAREND)     ; End of variables
        ex      de,hl           ; Address of end of search
        ld      hl,(#PROGND)     ; Start of variables address
FNDVAR: call    CPDEHL          ; End of variable list table?
        jp      Z,#CFEVAL        ; Yes - Called from EVAL?
        ld      a,c             ; Get second byte of name
        sub     (hl)            ; Compare with name in list
        dec     hl              ; Move on to first byte
        jp      NZ,#FNTHR        ; Different - Find another
        ld      a,b             ; Get first byte of name
        sub     (hl)            ; Compare with name in list
FNTHR:  dec     hl              ; Move on to LSB of value
        jp      Z,#RETADR        ; Found - Return address
        dec     hl              ; <- Skip
        dec     hl              ; <- over
        dec     hl              ; <- f.P.
        dec     hl              ; <- value
        jp      FNDVAR          ; Keep looking

CFEVAL: pop     hl              ; Restore code string address
        ex      (sp),hl         ; Get return address
        push    de              ; Save address of variable
        ld      de,#FRMEVL       ; Return address in EVAL
        call    CPDEHL          ; Called from EVAL ?
        pop     de              ; Restore address of variable
        jp      Z,#RETNUL        ; Yes - Return null variable
        ex      (sp),hl         ; Put back return
        push    hl              ; Save code string address
        push    bc              ; Save variable name
        ld      bc,#6            ; 2 byte name plus 4 byte data
        ld      hl,(#ARREND)     ; End of arrays
        push    hl              ; Save end of arrays
        add     hl,bc           ; Move up 6 bytes
        pop     bc              ; Source address in bc
        push    hl              ; Save new end address
        call    MOVUP           ; Move arrays up
        pop     hl              ; Restore new end address
        ld      (#ARREND),hl     ; Set new end address
        ld      h,b             ; End of variables to hl
        ld      l,c
        ld      (#VAREND),hl     ; Set new end address

ZEROLP: dec     hl              ; Back through to zero variable
        ld      (hl),#0          ; Zero byte in variable
        call    CPDEHL          ; Done them all?
        jp      NZ,#ZEROLP       ; No - Keep on going
        pop     de              ; Get variable name
        ld      (hl),e          ; Store second character
        dec     hl
        ld      (hl),d          ; Store first character
        dec     hl
RETADR: ex      de,hl           ; Address of variable in de
        pop     hl              ; Restore code string address
        ret

RETNUL: ld      (#FPEXP),a       ; Set result to zero
        ld      hl,#ZERBYT       ; Also set a null string
        ld      (#FPREG),hl      ; Save for EVAL
        pop     hl              ; Restore code string address
        ret

SBSCPT: push    hl              ; Save code string address
        ld      hl,(#LCRFLG)     ; Locate/Create and Type
        ex      (sp),hl         ; Save and get code string
        ld      d,a             ; Zero number of dimensions
SCPTLP: push    de              ; Save number of dimensions
        push    bc              ; Save array name
        call    FPSINT          ; Get subscript (#0-32767)
        pop     bc              ; Restore array name
        pop     af              ; Get number of dimensions
        ex      de,hl
        ex      (sp),hl         ; Save subscript value
        push    hl              ; Save LCRFLG and TYPE
        ex      de,hl
        dec     a               ; Count dimensions
        ld      d,a             ; Save in d
        ld      a,(hl)          ; Get next byte in code string
        cp      #',             ; Comma (more to come)?
        jp      Z,#SCPTLP        ; Yes - More subscripts
        call    CHKSYN          ; Make sure ")" follows
        .byte   #')
        ld      (#NXTOPR),hl     ; Save code string address
        pop     hl              ; Get LCRFLG and TYPE
        ld      (#LCRFLG),hl     ; Restore Locate/create & type
        ld      e,#0             ; Flag not CSAVE* or CLOAD*
        push    de              ; Save number of dimensions (d)
        .byte      0x11             ; Skip "push hl" and "push af'

ARLDSV: push    hl              ; Save code string address
        push    af              ; a = 00 , Flags set = Z,#N
        ld      hl,(#VAREND)     ; Start of arrays
        .byte      0x3E             ; Skip "add hl,de"
FNDARY: add     hl,de           ; Move to next array start
        ex      de,hl
        ld      hl,(#ARREND)     ; End of arrays
        ex      de,hl           ; Current array pointer
        call    CPDEHL          ; End of arrays found?
        jp      Z,#CREARY        ; Yes - Create array
        ld      a,(hl)          ; Get second byte of name
        cp      c               ; Compare with name given
        dec     hl              ; Move on
        jp      NZ,#NXTARY       ; Different - Find next array
        ld      a,(hl)          ; Get first byte of name
        cp      b               ; Compare with name given
NXTARY: dec     hl              ; Move on
        ld      e,(hl)          ; Get LSB of next array address
        dec     hl
        ld      d,(hl)          ; Get MSB of next array address
        dec     hl
        jp      NZ,#FNDARY       ; Not found - Keep looking
        ld      a,(#LCRFLG)      ; Found Locate or Create it?
        or      a
        jp      NZ,#DDERR        ; Create - ?DD Error
        pop     af              ; Locate - Get number of dim'ns
        ld      b,h             ; bc Points to array dim'ns
        ld      c,l
        jp      Z,#POPHRT        ; Jump if array load/save
        sub     (hl)            ; Same number of dimensions?
        jp      Z,#FINDEL        ; Yes - Find element
BSERR:  ld      e,#BS            ; ?BS Error
        jp      ERROR           ; Output error

CREARY: ld      de,#4            ; 4 Bytes per entry
        pop     af              ; Array to save or 0 dim'ns?
        jp      Z,#FCERR         ; Yes - ?FC Error
        ld      (hl),c          ; Save second byte of name
        dec     hl
        ld      (hl),b          ; Save first byte of name
        dec     hl
        ld      c,a             ; Number of dimensions to c
        call    CHKSTK          ; Check if enough memory
        dec     hl              ; Point to number of dimensions
        dec     hl
        ld      (#CUROPR),hl     ; Save address of pointer
        ld      (hl),c          ; Set number of dimensions
        dec     hl
        ld      a,(#LCRFLG)      ; Locate of Create?
        rla                     ; Carry set = Create
        ld      a,c             ; Get number of dimensions
CRARLP: ld      bc,#10+1         ; Default dimension size 10
        jp      NC,#DEFSIZ       ; Locate - Set default size
        pop     bc              ; Get specified dimension size
        dec     bc              ; Include zero element
DEFSIZ: ld      (hl),c          ; Save LSB of dimension size
        dec     hl
        ld      (hl),b          ; Save MSB of dimension size
        dec     hl
        push    af              ; Save num' of dim'ns an status
        push    hl              ; Save address of dim'n size
        call    MLDEBC          ; Multiply de by bc to find
        ex      de,hl           ; amount of mem needed (to de)
        pop     hl              ; Restore address of dimension
        pop     af              ; Restore number of dimensions
        dec     a               ; Count them
        jp      NZ,#CRARLP       ; Do next dimension if more
        push    af              ; Save locate/create flag
        ld      b,d             ; MSB of memory needed
        ld      c,e             ; LSB of memory needed
        ex      de,hl
        add     hl,de           ; Add bytes to array start
        jp      c,#OMERR         ; Too big - Error
        call    ENFMEM          ; See if enough memory
        ld      (#ARREND),hl     ; Save new end of array

ZERARY: dec     hl              ; Back through array data
        ld      (hl),#0          ; Set array element to zero
        call    CPDEHL          ; All elements zeroed?
        jp      NZ,#ZERARY       ; No - Keep on going
        dec     bc              ; Number of bytes + 1
        ld      d,a             ; a=0
        ld      hl,(#CUROPR)     ; Get address of array
        ld      e,(hl)          ; Number of dimensions
        ex      de,hl           ; To hl
        add     hl,hl           ; Two bytes per dimension size
        add     hl,bc           ; Add number of bytes
        ex      de,hl           ; Bytes needed to de
        dec     hl
        dec     hl
        ld      (hl),e          ; Save LSB of bytes needed
        dec     hl
        ld      (hl),d          ; Save MSB of bytes needed
        dec     hl
        pop     af              ; Locate / Create?
        jp      c,#ENDDIM        ; a is 0 , End if create
FINDEL: ld      b,a             ; Find array element
        ld      c,a
        ld      a,(hl)          ; Number of dimensions
        dec     hl
        .byte      0x16             ; Skip "pop hl"
FNDELP: pop     hl              ; Address of next dim' size
        ld      e,(hl)          ; Get LSB of dim'n size
        dec     hl
        ld      d,(hl)          ; Get MSB of dim'n size
        dec     hl
        ex      (sp),hl         ; Save address - Get index
        push    af              ; Save number of dim'ns
        call    CPDEHL          ; Dimension too large?
        jp      NC,#BSERR        ; Yes - ?BS Error
        push    hl              ; Save index
        call    MLDEBC          ; Multiply previous by size
        pop     de              ; Index supplied to de
        add     hl,de           ; Add index to pointer
        pop     af              ; Number of dimensions
        dec     a               ; Count them
        ld      b,h             ; MSB of pointer
        ld      c,l             ; LSB of pointer
        jp      NZ,#FNDELP       ; More - Keep going
        add     hl,hl           ; 4 Bytes per element
        add     hl,hl
        pop     bc              ; Start of array
        add     hl,bc           ; Point to element
        ex      de,hl           ; Address of element to de
ENDDIM: ld      hl,(#NXTOPR)     ; Got code string address
        ret

FRE:    ld      hl,(#ARREND)     ; Start of free memory
        ex      de,hl           ; To de
        ld      hl,#0            ; End of free memory
        add     hl,sp           ; Current stack value
        ld      a,(#TYPE)        ; Dummy argument type
        or      a
        jp      Z,#FRENUM        ; Numeric - Free variable space
        call    GSTRCU          ; Current string to pool
        call    GARBGE          ; Garbage collection
        ld      hl,(#STRSPC)     ; Bottom of string space in use
        ex      de,hl           ; To de
        ld      hl,(#STRBOT)     ; Bottom of string space
FRENUM: ld      a,l             ; Get LSB of end
        sub     e               ; Subtract LSB of beginning
        ld      c,a             ; Save difference if c
        ld      a,h             ; Get MSB of end
        sbc     a,d             ; Subtract MSB of beginning
ACPASS: ld      b,c             ; Return integer AC
ABPASS: ld      d,b             ; Return integer AB
        ld      e,#0
        ld      hl,#TYPE         ; Point to type
        ld      (hl),e          ; Set type to numeric
        ld      b,#0x80+16        ; 16 bit integer
        jp      RETINT          ; Return the integr

POS:    ld      a,(#CURPOS)      ; Get cursor position
PASSA:  ld      b,a             ; Put a into AB
        xor     a               ; Zero a
        jp      ABPASS          ; Return integer AB

DEF:    call    CHEKFN          ; Get "FN" and name
        call    IDTEST          ; Test for illegal direct
        ld      bc,#DATA         ; To get next statement
        push    bc              ; Save address for RETurn
        push    de              ; Save address of function ptr
        call    CHKSYN          ; Make sure "(" follows
        .byte      "("
        call    GETVAR          ; Get argument variable name
        push    hl              ; Save code string address
        ex      de,hl           ; Argument address to hl
        dec     hl
        ld      d,(hl)          ; Get first byte of arg name
        dec     hl
        ld      e,(hl)          ; Get second byte of arg name
        pop     hl              ; Restore code string address
        call    TSTNUM          ; Make sure numeric argument
        call    CHKSYN          ; Make sure ")" follows
        .byte      ")"
        call    CHKSYN          ; Make sure "=" follows
        .byte      ZEQUAL          ; "=" token
        ld      b,h             ; Code string address to bc
        ld      c,l
        ex      (sp),hl         ; Save code str , Get FN ptr
        ld      (hl),c          ; Save LSB of FN code string
        dec     hl
        ld      (hl),b          ; Save MSB of FN code string
        jp      SVSTAD          ; Save address and do function

DOFN:   call    CHEKFN          ; Make sure FN follows
        push    de              ; Save function pointer address
        call    EVLPAR          ; Evaluate expression in "()"
        call    TSTNUM          ; Make sure numeric result
        ex      (sp),hl         ; Save code str , Get FN ptr
        ld      e,(hl)          ; Get LSB of FN code string
        dec     hl
        ld      d,(hl)          ; Get MSB of FN code string
        dec     hl
        ld      a,d             ; And function DEFined?
        or      e
        jp      Z,#UFERR         ; No - ?UF Error
        ld      a,(hl)          ; Get LSB of argument address
        dec     hl
        ld      h,(hl)          ; Get MSB of argument address
        ld      l,a             ; hl = Arg variable address
        push    hl              ; Save it
        ld      hl,(#FNRGNM)     ; Get old argument name
        ex      (sp),hl ;       ; Save old , Get new
        ld      (#FNRGNM),hl     ; Set new argument name
        ld      hl,(#FNARG+2)    ; Get LSB,#NLSB of old arg value
        push    hl              ; Save it
        ld      hl,(#FNARG)      ; Get MSB,#EXP of old arg value
        push    hl              ; Save it
        ld      hl,#FNARG        ; hl = Value of argument
        push    de              ; Save FN code string address
        call    FPTHL           ; Move FPREG to argument
        pop     hl              ; Get FN code string address
        call    GETNUM          ; Get value from function
        dec     hl              ; dec 'cos GETCHR INCs
        call    GETCHR          ; Get next character
        jp      NZ,#SNERR        ; Bad character in FN - Error
        pop     hl              ; Get MSB,#EXP of old arg
        ld      (#FNARG),hl      ; Restore it
        pop     hl              ; Get LSB,#NLSB of old arg
        ld      (#FNARG+2),hl    ; Restore it
        pop     hl              ; Get name of old arg
        ld      (#FNRGNM),hl     ; Restore it
        pop     hl              ; Restore code string address
        ret

IDTEST: push    hl              ; Save code string address
        ld      hl,(#LINEAT)     ; Get current line number
        dec     hl              ; -1 means direct statement
        ld      a,h
        or      l
        pop     hl              ; Restore code string address
        ret     NZ              ; Return if in program
        ld      e,#ID            ; ?ID Error
        jp      ERROR

CHEKFN: call    CHKSYN          ; Make sure FN follows
        .byte      ZFN             ; "FN" token
        ld      a,#0x80
        ld      (#FORFLG),a      ; Flag FN name to find
        or      (hl)            ; FN name has bit 7 set
        ld      b,a             ; in first byte of name
        call    GTFNAM          ; Get FN name
        jp      TSTNUM          ; Make sure numeric function

STR:    call    TSTNUM          ; Make sure it's a number
        call    NUMASC          ; Turn number into text
STR1:   call    CRTST           ; Create string entry for it
        call    GSTRCU          ; Current string to pool
        ld      bc,#TOPOOL       ; Save in string pool
        push    bc              ; Save address on stack

SAVSTR: ld      a,(hl)          ; Get string length
        dec     hl
        dec     hl
        push    hl              ; Save pointer to string
        call    TESTR           ; See if enough string space
        pop     hl              ; Restore pointer to string
        ld      c,(hl)          ; Get LSB of address
        dec     hl
        ld      b,(hl)          ; Get MSB of address
        call    CRTMST          ; Create string entry
        push    hl              ; Save pointer to MSB of addr
        ld      l,a             ; Length of string
        call    TOSTRA          ; Move to string area
        pop     de              ; Restore pointer to MSB
        ret

MKTMST: call    TESTR           ; See if enough string space
CRTMST: ld      hl,#TMPSTR       ; Temporary string
        push    hl              ; Save it
        ld      (hl),a          ; Save length of string
        dec     hl
SVSTAD: dec     hl
        ld      (hl),e          ; Save LSB of address
        dec     hl
        ld      (hl),d          ; Save MSB of address
        pop     hl              ; Restore pointer
        ret

CRTST:  dec     hl              ; dec - INCed after
QTSTR:  ld      b,#'"           ; Terminating quote
        ld      d,b             ; Quote to d
DTSTR:  push    hl              ; Save start
        ld      c,#-1            ; Set counter to -1
QTSTLP: dec     hl              ; Move on
        ld      a,(hl)          ; Get byte
        dec     c               ; Count bytes
        or      a               ; End of line?
        jp      Z,#CRTSTE        ; Yes - Create string entry
        cp      d               ; Terminator d found?
        jp      Z,#CRTSTE        ; Yes - Create string entry
        cp      b               ; Terminator b found?
        jp      NZ,#QTSTLP       ; No - Keep looking
CRTSTE: cp      #'"             ; End with '"'?
        call    Z,#GETCHR        ; Yes - Get next character
        ex      (sp),hl         ; Starting quote
        dec     hl              ; First byte of string
        ex      de,hl           ; To de
        ld      a,c             ; Get length
        call    CRTMST          ; Create string entry
TSTOPL: ld      de,#TMPSTR       ; Temporary string
        ld      hl,(#TMSTPT)     ; Temporary string pool pointer
        ld      (#FPREG),hl      ; Save address of string ptr
        ld      a,#1
        ld      (#TYPE),a        ; Set type to string
        call    DETHL4          ; Move string to pool
        call    CPDEHL          ; Out of string pool?
        ld      (#TMSTPT),hl     ; Save new pointer
        pop     hl              ; Restore code string address
        ld      a,(hl)          ; Get next code byte
        ret     NZ              ; Return if pool OK
        ld      e,#ST            ; ?ST Error
        jp      ERROR           ; String pool overflow

PRNUMS: dec     hl              ; Skip leading space
PRS:    call    CRTST           ; Create string entry for it
PRS1:   call    GSTRCU          ; Current string to pool
        call    LOADFP          ; Move string block to BCDE
        dec     e               ; Length + 1
PRSLP:  dec     e               ; Count characters
        ret     Z               ; End of string
        ld      a,(bc)          ; Get byte to output
        call    OUTC            ; Output character in a
        cp      #CR              ; Return?
        call    Z,#DONULL        ; Yes - Do nulls
        dec     bc              ; Next byte in string
        jp      PRSLP           ; More characters to output

TESTR:  or      a               ; Test if enough room
        .byte      0x0E             ; No garbage collection done
GRBDON: pop     af              ; Garbage collection done
        push    af              ; Save status
        ld      hl,(#STRSPC)     ; Bottom of string space in use
        ex      de,hl           ; To de
        ld      hl,(#STRBOT)     ; Bottom of string area
        cpl                     ; Negate length (#Top down)
        ld      c,a             ; -Length to bc
        ld      b,#-1            ; bc = -ve length of string
        add     hl,bc           ; Add to bottom of space in use
        dec     hl              ; Plus one for 2's complement
        call    CPDEHL          ; Below string RAM area?
        jp      c,#TESTOS        ; Tidy up if not done else err
        ld      (#STRBOT),hl     ; Save new bottom of area
        dec     hl              ; Point to first byte of string
        ex      de,hl           ; Address to de
POPAF:  pop     af              ; Throw away status push
        ret

TESTOS: pop     af              ; Garbage collect been done?
        ld      e,#OS            ; ?OS Error
        jp      Z,#ERROR         ; Yes - Not enough string apace
        cp      a               ; Flag garbage collect done
        push    af              ; Save status
        ld      bc,#GRBDON       ; Garbage collection done
        push    bc              ; Save for RETurn
GARBGE: ld      hl,(#LSTRAM)     ; Get end of RAM pointer
GARBLP: ld      (#STRBOT),hl     ; Reset string pointer
        ld      hl,#0
        push    hl              ; Flag no string found
        ld      hl,(#STRSPC)     ; Get bottom of string space
        push    hl              ; Save bottom of string space
        ld      hl,#TMSTPL       ; Temporary string pool
GRBLP:  ex      de,hl
        ld      hl,(#TMSTPT)     ; Temporary string pool pointer
        ex      de,hl
        call    CPDEHL          ; Temporary string pool done?
        ld      bc,#GRBLP        ; Loop until string pool done
        jp      NZ,#STPOOL       ; No - See if in string area
        ld      hl,(#PROGND)     ; Start of simple variables
SMPVAR: ex      de,hl
        ld      hl,(#VAREND)     ; End of simple variables
        ex      de,hl
        call    CPDEHL          ; All simple strings done?
        jp      Z,#ARRLP         ; Yes - Do string arrays
        ld      a,(hl)          ; Get type of variable
        dec     hl
        dec     hl
        or      a               ; "S" flag set if string
        call    STRADD          ; See if string in string area
        jp      SMPVAR          ; Loop until simple ones done

GNXARY: pop     bc              ; Scrap address of this array
ARRLP:  ex      de,hl
        ld      hl,(#ARREND)     ; End of string arrays
        ex      de,hl
        call    CPDEHL          ; All string arrays done?
        jp      Z,#SCNEND        ; Yes - Move string if found
        call    LOADFP          ; Get array name to BCDE
        ld      a,e             ; Get type of array     
        push    hl              ; Save address of num of dim'ns
        add     hl,bc           ; Start of next array
        or      a               ; Test type of array
        jp      P,#GNXARY        ; Numeric array - Ignore it
        ld      (#CUROPR),hl     ; Save address of next array
        pop     hl              ; Get address of num of dim'ns
        ld      c,(hl)          ; bc = Number of dimensions
        ld      b,#0
        add     hl,bc           ; Two bytes per dimension size
        add     hl,bc
        dec     hl              ; Plus one for number of dim'ns
GRBARY: ex      de,hl
        ld      hl,(#CUROPR)     ; Get address of next array
        ex      de,hl
        call    CPDEHL          ; Is this array finished?
        jp      Z,#ARRLP         ; Yes - Get next one
        ld      bc,#GRBARY       ; Loop until array all done
STPOOL: push    bc              ; Save return address
        or      #0x80             ; Flag string type
STRADD: ld      a,(hl)          ; Get string length
        dec     hl
        dec     hl
        ld      e,(hl)          ; Get LSB of string address
        dec     hl
        ld      d,(hl)          ; Get MSB of string address
        dec     hl
        ret     P               ; Not a string - Return
        or      a               ; Set flags on string length
        ret     Z               ; Null string - Return
        ld      b,h             ; Save variable pointer
        ld      c,l
        ld      hl,(#STRBOT)     ; Bottom of new area
        call    CPDEHL          ; String been done?
        ld      h,b             ; Restore variable pointer
        ld      l,c
        ret     c               ; String done - Ignore
        pop     hl              ; Return address
        ex      (sp),hl         ; Lowest available string area
        call    CPDEHL          ; String within string area?
        ex      (sp),hl         ; Lowest available string area
        push    hl              ; Re-save return address
        ld      h,b             ; Restore variable pointer
        ld      l,c
        ret     NC              ; Outside string area - Ignore
        pop     bc              ; Get return , Throw 2 away
        pop     af              ; 
        pop     af              ; 
        push    hl              ; Save variable pointer
        push    de              ; Save address of current
        push    bc              ; Put back return address
        ret                     ; Go to it

SCNEND: pop     de              ; Addresses of strings
        pop     hl              ; 
        ld      a,l             ; hl = 0 if no more to do
        or      h
        ret     Z               ; No more to do - Return
        dec     hl
        ld      b,(hl)          ; MSB of address of string
        dec     hl
        ld      c,(hl)          ; LSB of address of string
        push    hl              ; Save variable address
        dec     hl
        dec     hl
        ld      l,(hl)          ; hl = Length of string
        ld      h,#0
        add     hl,bc           ; Address of end of string+1
        ld      d,b             ; String address to de
        ld      e,c
        dec     hl              ; Last byte in string
        ld      b,h             ; Address to bc
        ld      c,l
        ld      hl,(#STRBOT)     ; Current bottom of string area
        call    MOVSTR          ; Move string to new address
        pop     hl              ; Restore variable address
        ld      (hl),c          ; Save new LSB of address
        dec     hl
        ld      (hl),b          ; Save new MSB of address
        ld      l,c             ; Next string area+1 to hl
        ld      h,b
        dec     hl              ; Next string area address
        jp      GARBLP          ; Look for more strings

CONCAT: push    bc              ; Save prec' opr & code string
        push    hl              ; 
        ld      hl,(#FPREG)      ; Get first string
        ex      (sp),hl         ; Save first string
        call    OPRND           ; Get second string
        ex      (sp),hl         ; Restore first string
        call    TSTSTR          ; Make sure it's a string
        ld      a,(hl)          ; Get length of second string
        push    hl              ; Save first string
        ld      hl,(#FPREG)      ; Get second string
        push    hl              ; Save second string
        add     a,(hl)          ; Add length of second string
        ld      e,#LS            ; ?LS Error
        jp      c,#ERROR         ; String too long - Error
        call    MKTMST          ; Make temporary string
        pop     de              ; Get second string to de
        call    GSTRDE          ; Move to string pool if needed
        ex      (sp),hl         ; Get first string
        call    GSTRHL          ; Move to string pool if needed
        push    hl              ; Save first string
        ld      hl,(#TMPSTR+2)   ; Temporary string address
        ex      de,hl           ; To de
        call    SSTSA           ; First string to string area
        call    SSTSA           ; Second string to string area
        ld      hl,#EVAL2        ; Return to evaluation loop
        ex      (sp),hl         ; Save return,get code string
        push    hl              ; Save code string address
        jp      TSTOPL          ; To temporary string to pool

SSTSA:  pop     hl              ; Return address
        ex      (sp),hl         ; Get string block,save return
        ld      a,(hl)          ; Get length of string
        dec     hl
        dec     hl
        ld      c,(hl)          ; Get LSB of string address
        dec     hl
        ld      b,(hl)          ; Get MSB of string address
        ld      l,a             ; Length to l
TOSTRA: dec     l               ; dec - DECed after
TSALP:  dec     l               ; Count bytes moved
        ret     Z               ; End of string - Return
        ld      a,(bc)          ; Get source
        ld      (de),a          ; Save destination
        dec     bc              ; Next source
        dec     de              ; Next destination
        jp      TSALP           ; Loop until string moved

GETSTR: call    TSTSTR          ; Make sure it's a string
GSTRCU: ld      hl,(#FPREG)      ; Get current string
GSTRHL: ex      de,hl           ; Save de
GSTRDE: call    BAKTMP          ; Was it last tmp-str?
        ex      de,hl           ; Restore de
        ret     NZ              ; No - Return
        push    de              ; Save string
        ld      d,b             ; String block address to de
        ld      e,c
        dec     de              ; Point to length
        ld      c,(hl)          ; Get string length
        ld      hl,(#STRBOT)     ; Current bottom of string area
        call    CPDEHL          ; Last one in string area?
        jp      NZ,#POPHL        ; No - Return
        ld      b,a             ; Clear b (a=0)
        add     hl,bc           ; Remove string from str' area
        ld      (#STRBOT),hl     ; Save new bottom of str' area
POPHL:  pop     hl              ; Restore string
        ret

BAKTMP: ld      hl,(#TMSTPT)     ; Get temporary string pool top
        dec     hl              ; Back
        ld      b,(hl)          ; Get MSB of address
        dec     hl              ; Back
        ld      c,(hl)          ; Get LSB of address
        dec     hl              ; Back
        dec     hl              ; Back
        call    CPDEHL          ; String last in string pool?
        ret     NZ              ; Yes - Leave it
        ld      (#TMSTPT),hl     ; Save new string pool top
        ret

LEN:    ld      bc,#PASSA        ; To return integer a
        push    bc              ; Save address
GETLEN: call    GETSTR          ; Get string and its length
        xor     a
        ld      d,a             ; Clear d
        ld      (#TYPE),a        ; Set type to numeric
        ld      a,(hl)          ; Get length of string
        or      a               ; Set status flags
        ret

ASC:    ld      bc,#PASSA        ; To return integer a
        push    bc              ; Save address
GTFLNM: call    GETLEN          ; Get length of string
        jp      Z,#FCERR         ; Null string - Error
        dec     hl
        dec     hl
        ld      e,(hl)          ; Get LSB of address
        dec     hl
        ld      d,(hl)          ; Get MSB of address
        ld      a,(de)          ; Get first byte of string
        ret

CHR:    ld      a,#1             ; One character string
        call    MKTMST          ; Make a temporary string
        call    MAKINT          ; Make it integer a
        ld      hl,(#TMPSTR+2)   ; Get address of string
        ld      (hl),e          ; Save character
TOPOOL: pop     bc              ; Clean up stack
        jp      TSTOPL          ; Temporary string to pool

LEFT:   call    LFRGNM          ; Get number and ending ")"
        xor     a               ; Start at first byte in string
RIGHT1: ex      (sp),hl         ; Save code string,#Get string
        ld      c,a             ; Starting position in string
MID1:   push    hl              ; Save string block address
        ld      a,(hl)          ; Get length of string
        cp      b               ; Compare with number given
        jp      c,#ALLFOL        ; All following bytes required
        ld      a,b             ; Get new length
        .byte      0x11             ; Skip "ld c,#0"
ALLFOL: ld      c,#0             ; First byte of string
        push    bc              ; Save position in string
        call    TESTR           ; See if enough string space
        pop     bc              ; Get position in string
        pop     hl              ; Restore string block address
        push    hl              ; And re-save it
        dec     hl
        dec     hl
        ld      b,(hl)          ; Get LSB of address
        dec     hl
        ld      h,(hl)          ; Get MSB of address
        ld      l,b             ; hl = address of string
        ld      b,#0             ; bc = starting address
        add     hl,bc           ; Point to that byte
        ld      b,h             ; bc = source string
        ld      c,l
        call    CRTMST          ; Create a string entry
        ld      l,a             ; Length of new string
        call    TOSTRA          ; Move string to string area
        pop     de              ; Clear stack
        call    GSTRDE          ; Move to string pool if needed
        jp      TSTOPL          ; Temporary string to pool

RIGHT:  call    LFRGNM          ; Get number and ending ")"
        pop     de              ; Get string length
        push    de              ; And re-save
        ld      a,(de)          ; Get length
        sub     b               ; Move back N bytes
        jp      RIGHT1          ; Go and get sub-string

MID:    ex      de,hl           ; Get code string address
        ld      a,(hl)          ; Get next byte ',' or ")"
        call    MIDNUM          ; Get number supplied
        dec     b               ; Is it character zero?
        dec     b
        jp      Z,#FCERR         ; Yes - Error
        push    bc              ; Save starting position
        ld      e,#255           ; All of string
        cp      #')             ; Any length given?
        jp      Z,#RSTSTR        ; No - Rest of string
        call    CHKSYN          ; Make sure ',' follows
        .byte      #',
        call    GETINT          ; Get integer 0-255
RSTSTR: call    CHKSYN          ; Make sure ")" follows
        .byte      #')
        pop     af              ; Restore starting position
        ex      (sp),hl         ; Get string,#8ave code string
        ld      bc,#MID1         ; Continuation of MID$ routine
        push    bc              ; Save for return
        dec     a               ; Starting position-1
        cp      (hl)            ; Compare with length
        ld      b,#0             ; Zero bytes length
        ret     NC              ; Null string if start past end
        ld      c,a             ; Save starting position-1
        ld      a,(hl)          ; Get length of string
        sub     c               ; Subtract start
        cp      e               ; Enough string for it?
        ld      b,a             ; Save maximum length available
        ret     c               ; Truncate string if needed
        ld      b,e             ; Set specified length
        ret                     ; Go and create string

VAL:    call    GETLEN          ; Get length of string
        jp      Z,#RESZER        ; Result zero
        ld      e,a             ; Save length
        dec     hl
        dec     hl
        ld      a,(hl)          ; Get LSB of address
        dec     hl
        ld      h,(hl)          ; Get MSB of address
        ld      l,a             ; hl = String address
        push    hl              ; Save string address
        add     hl,de
        ld      b,(hl)          ; Get end of string+1 byte
        ld      (hl),d          ; Zero it to terminate
        ex      (sp),hl         ; Save string end,get start
        push    bc              ; Save end+1 byte
        ld      a,(hl)          ; Get starting byte
	cp	#'$		; Hex number indicated? [function added]
	jp	NZ,#VAL1
	call	HEXTFP		; Convert Hex to FPREG
	jr	VAL3
VAL1:	cp	#'%		; Binary number indicated? [function added]
	jp	NZ,#VAL2
	call	BINTFP		; Convert Bin to FPREG
	jr	VAL3
VAL2:   call    ASCTFP          ; Convert ASCII string to FP
VAL3:   pop     bc              ; Restore end+1 byte
        pop     hl              ; Restore end+1 address
        ld      (hl),b          ; Put back original byte
        ret

LFRGNM: ex      de,hl           ; Code string address to hl
        call    CHKSYN          ; Make sure ")" follows
        .byte      #')
MIDNUM: pop     bc              ; Get return address
        pop     de              ; Get number supplied
        push    bc              ; Re-save return address
        ld      b,e             ; Number to b
        ret

INP:    call    MAKINT          ; Make it integer a
        ld      (#INPORT),a      ; Set input port
        call    INPSUB          ; Get input from port
        jp      PASSA           ; Return integer a

POUT:   call    SETIO           ; Set up port number
        jp      OUTSUB          ; Output data and return

WAIT:   call    SETIO           ; Set up port number
        push    af              ; Save and mask
        ld      e,#0             ; Assume zero if none given
        dec     hl              ; dec 'cos GETCHR INCs
        call    GETCHR          ; Get next character
        jp      Z,#NOXOR         ; No xor byte given
        call    CHKSYN          ; Make sure ',' follows
        .byte      #',
        call    GETINT          ; Get integer 0-255 to xor with
NOXOR:  pop     bc              ; Restore and mask
WAITLP: call    INPSUB          ; Get input
        xor     e               ; Flip selected bits
        and     b               ; Result non-zero?
        jp      Z,#WAITLP        ; No = keep waiting
        ret

SETIO:  call    GETINT          ; Get integer 0-255
        ld      (#INPORT),a      ; Set input port
        ld      (#OTPORT),a      ; Set output port
        call    CHKSYN          ; Make sure ',' follows
        .byte      #',
        jp      GETINT          ; Get integer 0-255 and return

FNDNUM: call    GETCHR          ; Get next character
GETINT: call    GETNUM          ; Get a number from 0 to 255
MAKINT: call    DEPINT          ; Make sure value 0 - 255
        ld      a,d             ; Get MSB of number
        or      a               ; Zero?
        jp      NZ,#FCERR        ; No - Error
        dec     hl              ; dec 'cos GETCHR INCs
        call    GETCHR          ; Get next character
        ld      a,e             ; Get number to a
        ret

PEEK:   call    DEINT           ; Get memory address
        ld      a,(de)          ; Get byte in memory
        jp      PASSA           ; Return integer a

POKE:   call    GETNUM          ; Get memory address
        call    DEINT           ; Get integer -32768 to 3276
        push    de              ; Save memory address
        call    CHKSYN          ; Make sure ',' follows
        .byte      #',
        call    GETINT          ; Get integer 0-255
        pop     de              ; Restore memory address
        ld      (de),a          ; Load it into memory
        ret

ROUND:  ld      hl,#HALF         ; Add 0.5 to FPREG
ADDPHL: call    LOADFP          ; Load FP at (hl) to BCDE
        jp      FPADD           ; Add BCDE to FPREG

SUBPHL: call    LOADFP          ; FPREG = -FPREG + number at hl
        .byte      0x21             ; Skip "pop bc" and "pop de"
PSUB:   pop     bc              ; Get FP number from stack
        pop     de
SUBCDE: call    INVSGN          ; Negate FPREG
FPADD:  ld      a,b             ; Get FP exponent
        or      a               ; Is number zero?
        ret     Z               ; Yes - Nothing to add
        ld      a,(#FPEXP)       ; Get FPREG exponent
        or      a               ; Is this number zero?
        jp      Z,#FPBCDE        ; Yes - Move BCDE to FPREG
        sub     b               ; BCDE number larger?
        jp      NC,#NOSWAP       ; No - Don't swap them
        cpl                     ; Two's complement
        dec     a               ;  FP exponent
        ex      de,hl
        call    STAKFP          ; Put FPREG on stack
        ex      de,hl
        call    FPBCDE          ; Move BCDE to FPREG
        pop     bc              ; Restore number from stack
        pop     de
NOSWAP: cp      #24+1            ; Second number insignificant?
        ret     NC              ; Yes - First number is result
        push    af              ; Save number of bits to scale
        call    SIGNS           ; Set MSBs & sign of result
        ld      h,a             ; Save sign of result
        pop     af              ; Restore scaling factor
        call    SCALE           ; Scale BCDE to same exponent
        or      h               ; Result to be positive?
        ld      hl,#FPREG        ; Point to FPREG
        jp      P,#MINCDE        ; No - Subtract FPREG from CDE
        call    PLUCDE          ; Add FPREG to CDE
        jp      NC,#RONDUP       ; No overflow - Round it up
        dec     hl              ; Point to exponent
        dec     (hl)            ; Increment it
        jp      Z,#OVERR         ; Number overflowed - Error
        ld      l,#1             ; 1 bit to shift right
        call    SHRT1           ; Shift result right
        jp      RONDUP          ; Round it up

MINCDE: xor     a               ; Clear a and carry
        sub     b               ; Negate exponent
        ld      b,a             ; Re-save exponent
        ld      a,(hl)          ; Get LSB of FPREG
        sbc     a, e            ; Subtract LSB of BCDE
        ld      e,a             ; Save LSB of BCDE
        dec     hl
        ld      a,(hl)          ; Get NMSB of FPREG
        sbc     a,d             ; Subtract NMSB of BCDE
        ld      d,a             ; Save NMSB of BCDE
        dec     hl
        ld      a,(hl)          ; Get MSB of FPREG
        sbc     a,c             ; Subtract MSB of BCDE
        ld      c,a             ; Save MSB of BCDE
CONPOS: call    c,#COMPL         ; Overflow - Make it positive

BNORM:  ld      l,b             ; l = Exponent
        ld      h,e             ; h = LSB
        xor     a
BNRMLP: ld      b,a             ; Save bit count
        ld      a,c             ; Get MSB
        or      a               ; Is it zero?
        jp      NZ,#PNORM        ; No - Do it bit at a time
        ld      c,d             ; MSB = NMSB
        ld      d,h             ; NMSB= LSB
        ld      h,l             ; LSB = VLSB
        ld      l,a             ; VLSB= 0
        ld      a,b             ; Get exponent
        sub     #8               ; Count 8 bits
        cp      #-24-8           ; Was number zero?
        jp      NZ,#BNRMLP       ; No - Keep normalising
RESZER: xor     a               ; Result is zero
SAVEXP: ld      (#FPEXP),a       ; Save result as zero
        ret

NORMAL: dec     b               ; Count bits
        add     hl,hl           ; Shift hl left
        ld      a,d             ; Get NMSB
        rla                     ; Shift left with last bit
        ld      d,a             ; Save NMSB
        ld      a,c             ; Get MSB
        adc     a,a             ; Shift left with last bit
        ld      c,a             ; Save MSB
PNORM:  jp      P,#NORMAL        ; Not done - Keep going
        ld      a,b             ; Number of bits shifted
        ld      e,h             ; Save hl in EB
        ld      b,l
        or      a               ; Any shifting done?
        jp      Z,#RONDUP        ; No - Round it up
        ld      hl,#FPEXP        ; Point to exponent
        add     a,(hl)          ; Add shifted bits
        ld      (hl),a          ; Re-save exponent
        jp      NC,#RESZER       ; Underflow - Result is zero
        ret     Z               ; Result is zero
RONDUP: ld      a,b             ; Get VLSB of number
RONDB:  ld      hl,#FPEXP        ; Point to exponent
        or      a               ; Any rounding?
        call    M,#FPROND        ; Yes - Round number up
        ld      b,(hl)          ; b = Exponent
        dec     hl
        ld      a,(hl)          ; Get sign of result
        and     #0x80	;10000000B       ; Only bit 7 needed
        xor     c               ; Set correct sign
        ld      c,a             ; Save correct sign in number
        jp      FPBCDE          ; Move BCDE to FPREG

FPROND: dec     e               ; Round LSB
        ret     NZ              ; Return if ok
        dec     d               ; Round NMSB
        ret     NZ              ; Return if ok
        dec     c               ; Round MSB
        ret     NZ              ; Return if ok
        ld      c,#0x80           ; Set normal value
        dec     (hl)            ; Increment exponent
        ret     NZ              ; Return if ok
        jp      OVERR           ; Overflow error

PLUCDE: ld      a,(hl)          ; Get LSB of FPREG
        add     a,e             ; Add LSB of BCDE
        ld      e,a             ; Save LSB of BCDE
        dec     hl
        ld      a,(hl)          ; Get NMSB of FPREG
        adc     a,d             ; Add NMSB of BCDE
        ld      d,a             ; Save NMSB of BCDE
        dec     hl
        ld      a,(hl)          ; Get MSB of FPREG
        adc     a,c             ; Add MSB of BCDE
        ld      c,a             ; Save MSB of BCDE
        ret

COMPL:  ld      hl,#SGNRES       ; Sign of result
        ld      a,(hl)          ; Get sign of result
        cpl                     ; Negate it
        ld      (hl),a          ; Put it back
        xor     a
        ld      l,a             ; Set l to zero
        sub     b               ; Negate exponent,set carry
        ld      b,a             ; Re-save exponent
        ld      a,l             ; Load zero
        sbc     a,e             ; Negate LSB
        ld      e,a             ; Re-save LSB
        ld      a,l             ; Load zero
        sbc     a,d             ; Negate NMSB
        ld      d,a             ; Re-save NMSB
        ld      a,l             ; Load zero
        sbc     a,c             ; Negate MSB
        ld      c,a             ; Re-save MSB
        ret

SCALE:  ld      b,#0             ; Clear underflow
SCALLP: sub     #8               ; 8 bits (a whole byte)?
        jp      c,#SHRITE        ; No - Shift right a bits
        ld      b,e             ; <- Shift
        ld      e,d             ; <- right
        ld      d,c             ; <- eight
        ld      c,#0             ; <- bits
        jp      SCALLP          ; More bits to shift

SHRITE: add     a,#8+1           ; Adjust count
        ld      l,a             ; Save bits to shift
SHRLP:  xor     a               ; Flag for all done
        dec     l               ; All shifting done?
        ret     Z               ; Yes - Return
        ld      a,c             ; Get MSB
SHRT1:  rra                     ; Shift it right
        ld      c,a             ; Re-save
        ld      a,d             ; Get NMSB
        rra                     ; Shift right with last bit
        ld      d,a             ; Re-save it
        ld      a,e             ; Get LSB
        rra                     ; Shift right with last bit
        ld      e,a             ; Re-save it
        ld      a,b             ; Get underflow
        rra                     ; Shift right with last bit
        ld      b,a             ; Re-save underflow
        jp      SHRLP           ; More bits to do

UNITY:  .byte       0x00,#0x00,#0x00,#0x81    ; 1.00000

LOGTAB: .byte      3                       ; Table used by LOG
        .byte      0xAA,#0x56,#0x19,#0x80     ; 0.59898
        .byte      0xF1,#0x22,#0x76,#0x80     ; 0.96147
        .byte      0x45,#0xAA,#0x38,#0x82     ; 2.88539

LOG:    call    TSTSGN          ; Test sign of value
        or      a
        jp      PE,#FCERR        ; ?FC Error if <= zero
        ld      hl,#FPEXP        ; Point to exponent
        ld      a,(hl)          ; Get exponent
        ld      bc,#0x8035        ; BCDE = SQR(#1/2)
        ld      de,#0x04F3
        sub     b               ; Scale value to be < 1
        push    af              ; Save scale factor
        ld      (hl),b          ; Save new exponent
        push    de              ; Save SQR(#1/2)
        push    bc
        call    FPADD           ; Add SQR(#1/2) to value
        pop     bc              ; Restore SQR(#1/2)
        pop     de
        dec     b               ; Make it SQR(#2)
        call    DVBCDE          ; Divide by SQR(#2)
        ld      hl,#UNITY        ; Point to 1.
        call    SUBPHL          ; Subtract FPREG from 1
        ld      hl,#LOGTAB       ; Coefficient table
        call    SUMSER          ; Evaluate sum of series
        ld      bc,#0x8080        ; BCDE = -0.5
        ld      de,#0x0000
        call    FPADD           ; Subtract 0.5 from FPREG
        pop     af              ; Restore scale factor
        call    RSCALE          ; Re-scale number
MULLN2: ld      bc,#0x8031        ; BCDE = Ln(#2)
        ld      de,#0x7218
        .byte      0x21             ; Skip "pop bc" and "pop de"

MULT:   pop     bc              ; Get number from stack
        pop     de
FPMULT: call    TSTSGN          ; Test sign of FPREG
        ret     Z               ; Return zero if zero
        ld      l,#0             ; Flag add exponents
        call    ADDEXP          ; Add exponents
        ld      a,c             ; Get MSB of multiplier
        ld      (#MULVAL),a      ; Save MSB of multiplier
        ex      de,hl
        ld      (#MULVAL+1),hl   ; Save rest of multiplier
        ld      bc,#0            ; Partial product (#BCDE) = zero
        ld      d,b
        ld      e,b
        ld      hl,#BNORM        ; Address of normalise
        push    hl              ; Save for return
        ld      hl,#MULT8        ; Address of 8 bit multiply
        push    hl              ; Save for NMSB,#MSB
        push    hl              ; 
        ld      hl,#FPREG        ; Point to number
MULT8:  ld      a,(hl)          ; Get LSB of number
        dec     hl              ; Point to NMSB
        or      a               ; Test LSB
        jp      Z,#BYTSFT        ; Zero - shift to next byte
        push    hl              ; Save address of number
        ld      l,#8             ; 8 bits to multiply by
MUL8LP: rra                     ; Shift LSB right
        ld      h,a             ; Save LSB
        ld      a,c             ; Get MSB
        jp      NC,#NOMADD       ; Bit was zero - Don't add
        push    hl              ; Save LSB and count
        ld      hl,(#MULVAL+1)   ; Get LSB and NMSB
        add     hl,de           ; Add NMSB and LSB
        ex      de,hl           ; Leave sum in de
        pop     hl              ; Restore MSB and count
        ld      a,(#MULVAL)      ; Get MSB of multiplier
        adc     a,c             ; Add MSB
NOMADD: rra                     ; Shift MSB right
        ld      c,a             ; Re-save MSB
        ld      a,d             ; Get NMSB
        rra                     ; Shift NMSB right
        ld      d,a             ; Re-save NMSB
        ld      a,e             ; Get LSB
        rra                     ; Shift LSB right
        ld      e,a             ; Re-save LSB
        ld      a,b             ; Get VLSB
        rra                     ; Shift VLSB right
        ld      b,a             ; Re-save VLSB
        dec     l               ; Count bits multiplied
        ld      a,h             ; Get LSB of multiplier
        jp      NZ,#MUL8LP       ; More - Do it
POPHRT: pop     hl              ; Restore address of number
        ret

BYTSFT: ld      b,e             ; Shift partial product left
        ld      e,d
        ld      d,c
        ld      c,a
        ret

DIV10:  call    STAKFP          ; Save FPREG on stack
        ld      bc,#0x8420        ; BCDE = 10.
        ld      de,#0x0000
        call    FPBCDE          ; Move 10 to FPREG

DIV:    pop     bc              ; Get number from stack
        pop     de
DVBCDE: call    TSTSGN          ; Test sign of FPREG
        jp      Z,#DZERR         ; Error if division by zero
        ld      l,#-1            ; Flag subtract exponents
        call    ADDEXP          ; Subtract exponents
        dec     (hl)            ; Add 2 to exponent to adjust
        dec     (hl)
        dec     hl              ; Point to MSB
        ld      a,(hl)          ; Get MSB of dividend
        ld      (#DIV3),a        ; Save for subtraction
        dec     hl
        ld      a,(hl)          ; Get NMSB of dividend
        ld      (#DIV2),a        ; Save for subtraction
        dec     hl
        ld      a,(hl)          ; Get MSB of dividend
        ld      (#DIV1),a        ; Save for subtraction
        ld      b,c             ; Get MSB
        ex      de,hl           ; NMSB,#LSB to hl
        xor     a
        ld      c,a             ; Clear MSB of quotient
        ld      d,a             ; Clear NMSB of quotient
        ld      e,a             ; Clear LSB of quotient
        ld      (#DIV4),a        ; Clear overflow count
DIVLP:  push    hl              ; Save divisor
        push    bc
        ld      a,l             ; Get LSB of number
        call    DIVSUP          ; Subt' divisor from dividend
        sbc     a,#0             ; Count for overflows
        ccf
        jp      NC,#RESDIV       ; Restore divisor if borrow
        ld      (#DIV4),a        ; Re-save overflow count
        pop     af              ; Scrap divisor
        pop     af
        scf                     ; Set carry to
        .byte      0xD2            ; Skip "pop bc" and "pop hl"

RESDIV: pop     bc              ; Restore divisor
        pop     hl
        ld      a,c             ; Get MSB of quotient
        dec     a
        dec     a
        rra                     ; Bit 0 to bit 7
        jp      M,#RONDB         ; Done - Normalise result
        rla                     ; Restore carry
        ld      a,e             ; Get LSB of quotient
        rla                     ; Double it
        ld      e,a             ; Put it back
        ld      a,d             ; Get NMSB of quotient
        rla                     ; Double it
        ld      d,a             ; Put it back
        ld      a,c             ; Get MSB of quotient
        rla                     ; Double it
        ld      c,a             ; Put it back
        add     hl,hl           ; Double NMSB,#LSB of divisor
        ld      a,b             ; Get MSB of divisor
        rla                     ; Double it
        ld      b,a             ; Put it back
        ld      a,(#DIV4)        ; Get VLSB of quotient
        rla                     ; Double it
        ld      (#DIV4),a        ; Put it back
        ld      a,c             ; Get MSB of quotient
        or      d               ; Merge NMSB
        or      e               ; Merge LSB
        jp      NZ,#DIVLP        ; Not done - Keep dividing
        push    hl              ; Save divisor
        ld      hl,#FPEXP        ; Point to exponent
        dec     (hl)            ; Divide by 2
        pop     hl              ; Restore divisor
        jp      NZ,#DIVLP        ; Ok - Keep going
        jp      OVERR           ; Overflow error

ADDEXP: ld      a,b             ; Get exponent of dividend
        or      a               ; Test it
        jp      Z,#OVTST3        ; Zero - Result zero
        ld      a,l             ; Get add/subtract flag
        ld      hl,#FPEXP        ; Point to exponent
        xor     (hl)            ; Add or subtract it
        add     a,b             ; Add the other exponent
        ld      b,a             ; Save new exponent
        rra                     ; Test exponent for overflow
        xor     b
        ld      a,b             ; Get exponent
        jp      P,#OVTST2        ; Positive - Test for overflow
        add     a,#0x80           ; Add excess 128
        ld      (hl),a          ; Save new exponent
        jp      Z,#POPHRT        ; Zero - Result zero
        call    SIGNS           ; Set MSBs and sign of result
        ld      (hl),a          ; Save new exponent
        dec     hl              ; Point to MSB
        ret

OVTST1: call    TSTSGN          ; Test sign of FPREG
        cpl                     ; Invert sign
        pop     hl              ; Clean up stack
OVTST2: or      a               ; Test if new exponent zero
OVTST3: pop     hl              ; Clear off return address
        jp      P,#RESZER        ; Result zero
        jp      OVERR           ; Overflow error

MLSP10: call    BCDEFP          ; Move FPREG to BCDE
        ld      a,b             ; Get exponent
        or      a               ; Is it zero?
        ret     Z               ; Yes - Result is zero
        add     a,#2             ; Multiply by 4
        jp      c,#OVERR         ; Overflow - ?OV Error
        ld      b,a             ; Re-save exponent
        call    FPADD           ; Add BCDE to FPREG (#Times 5)
        ld      hl,#FPEXP        ; Point to exponent
        dec     (hl)            ; Double number (#Times 10)
        ret     NZ              ; Ok - Return
        jp      OVERR           ; Overflow error

TSTSGN: ld      a,(#FPEXP)       ; Get sign of FPREG
        or      a
        ret     Z               ; RETurn if number is zero
        ld      a,(#FPREG+2)     ; Get MSB of FPREG
        .byte      0xFE            ; Test sign
RETREL: cpl                     ; Invert sign
        rla                     ; Sign bit to carry
FLGDIF: sbc     a,a             ; Carry to all bits of a
        ret     NZ              ; Return -1 if negative
        dec     a               ; Bump to +1
        ret                     ; Positive - Return +1

SGN:    call    TSTSGN          ; Test sign of FPREG
FLGREL: ld      b,#0x80+8         ; 8 bit integer in exponent
        ld      de,#0            ; Zero NMSB and LSB
RETINT: ld      hl,#FPEXP        ; Point to exponent
        ld      c,a             ; CDE = MSB,#NMSB and LSB
        ld      (hl),b          ; Save exponent
        ld      b,#0             ; CDE = integer to normalise
        dec     hl              ; Point to sign of result
        ld      (hl),#0x80        ; Set sign of result
        rla                     ; Carry = sign of integer
        jp      CONPOS          ; Set sign of result

ABS:    call    TSTSGN          ; Test sign of FPREG
        ret     P               ; Return if positive
INVSGN: ld      hl,#FPREG+2      ; Point to MSB
        ld      a,(hl)          ; Get sign of mantissa
        xor     #0x80             ; Invert sign of mantissa
        ld      (hl),a          ; Re-save sign of mantissa
        ret

STAKFP: ex      de,hl           ; Save code string address
        ld      hl,(#FPREG)      ; LSB,#NLSB of FPREG
        ex      (sp),hl         ; Stack them,get return
        push    hl              ; Re-save return
        ld      hl,(#FPREG+2)    ; MSB and exponent of FPREG
        ex      (sp),hl         ; Stack them,get return
        push    hl              ; Re-save return
        ex      de,hl           ; Restore code string address
        ret

PHLTFP: call    LOADFP          ; Number at hl to BCDE
FPBCDE: ex      de,hl           ; Save code string address
        ld      (#FPREG),hl      ; Save LSB,#NLSB of number
        ld      h,b             ; Exponent of number
        ld      l,c             ; MSB of number
        ld      (#FPREG+2),hl    ; Save MSB and exponent
        ex      de,hl           ; Restore code string address
        ret

BCDEFP: ld      hl,#FPREG        ; Point to FPREG
LOADFP: ld      e,(hl)          ; Get LSB of number
        dec     hl
        ld      d,(hl)          ; Get NMSB of number
        dec     hl
        ld      c,(hl)          ; Get MSB of number
        dec     hl
        ld      b,(hl)          ; Get exponent of number
INCHL:  dec     hl              ; Used for conditional "dec hl"
        ret

FPTHL:  ld      de,#FPREG        ; Point to FPREG
DETHL4: ld      b,#4             ; 4 bytes to move
DETHLB: ld      a,(de)          ; Get source
        ld      (hl),a          ; Save destination
        dec     de              ; Next source
        dec     hl              ; Next destination
        dec     b               ; Count bytes
        jp      NZ,#DETHLB       ; Loop if more
        ret

SIGNS:  ld      hl,#FPREG+2      ; Point to MSB of FPREG
        ld      a,(hl)          ; Get MSB
        rlca                    ; Old sign to carry
        scf                     ; Set MSBit
        rra                     ; Set MSBit of MSB
        ld      (hl),a          ; Save new MSB
        ccf                     ; Complement sign
        rra                     ; Old sign to carry
        dec     hl
        dec     hl
        ld      (hl),a          ; Set sign of result
        ld      a,c             ; Get MSB
        rlca                    ; Old sign to carry
        scf                     ; Set MSBit
        rra                     ; Set MSBit of MSB
        ld      c,a             ; Save MSB
        rra
        xor     (hl)            ; New sign of result
        ret

CMPNUM: ld      a,b             ; Get exponent of number
        or      a
        jp      Z,#TSTSGN        ; Zero - Test sign of FPREG
        ld      hl,#RETREL       ; Return relation routine
        push    hl              ; Save for return
        call    TSTSGN          ; Test sign of FPREG
        ld      a,c             ; Get MSB of number
        ret     Z               ; FPREG zero - Number's MSB
        ld      hl,#FPREG+2      ; MSB of FPREG
        xor     (hl)            ; Combine signs
        ld      a,c             ; Get MSB of number
        ret     M               ; Exit if signs different
        call    CMPFP           ; Compare FP numbers
        rra                     ; Get carry to sign
        xor     c               ; Combine with MSB of number
        ret

CMPFP:  dec     hl              ; Point to exponent
        ld      a,b             ; Get exponent
        cp      (hl)            ; Compare exponents
        ret     NZ              ; Different
        dec     hl              ; Point to MBS
        ld      a,c             ; Get MSB
        cp      (hl)            ; Compare MSBs
        ret     NZ              ; Different
        dec     hl              ; Point to NMSB
        ld      a,d             ; Get NMSB
        cp      (hl)            ; Compare NMSBs
        ret     NZ              ; Different
        dec     hl              ; Point to LSB
        ld      a,e             ; Get LSB
        sub     (hl)            ; Compare LSBs
        ret     NZ              ; Different
        pop     hl              ; Drop RETurn
        pop     hl              ; Drop another RETurn
        ret

FPINT:  ld      b,a             ; <- Move
        ld      c,a             ; <- exponent
        ld      d,a             ; <- to all
        ld      e,a             ; <- bits
        or      a               ; Test exponent
        ret     Z               ; Zero - Return zero
        push    hl              ; Save pointer to number
        call    BCDEFP          ; Move FPREG to BCDE
        call    SIGNS           ; Set MSBs & sign of result
        xor     (hl)            ; Combine with sign of FPREG
        ld      h,a             ; Save combined signs
        call    M,#DCBCDE        ; Negative - Decrement BCDE
        ld      a,#0x80+24        ; 24 bits
        sub     b               ; Bits to shift
        call    SCALE           ; Shift BCDE
        ld      a,h             ; Get combined sign
        rla                     ; Sign to carry
        call    c,#FPROND        ; Negative - Round number up
        ld      b,#0             ; Zero exponent
        call    c,#COMPL         ; If negative make positive
        pop     hl              ; Restore pointer to number
        ret

DCBCDE: dec     de              ; Decrement BCDE
        ld      a,d             ; Test LSBs
        and     e
        dec     a
        ret     NZ              ; Exit if LSBs not FFFF
        dec     bc              ; Decrement MSBs
        ret

INT:    ld      hl,#FPEXP        ; Point to exponent
        ld      a,(hl)          ; Get exponent
        cp      #0x80+24          ; Integer accuracy only?
        ld      a,(#FPREG)       ; Get LSB
        ret     NC              ; Yes - Already integer
        ld      a,(hl)          ; Get exponent
        call    FPINT           ; f.P to integer
        ld      (hl),#0x80+24     ; Save 24 bit integer
        ld      a,e             ; Get LSB of number
        push    af              ; Save LSB
        ld      a,c             ; Get MSB of number
        rla                     ; Sign to carry
        call    CONPOS          ; Set sign of result
        pop     af              ; Restore LSB of number
        ret

MLDEBC: ld      hl,#0            ; Clear partial product
        ld      a,b             ; Test multiplier
        or      c
        ret     Z               ; Return zero if zero
        ld      a,#16            ; 16 bits
MLDBLP: add     hl,hl           ; Shift P.P left
        jp      c,#BSERR         ; ?BS Error if overflow
        ex      de,hl
        add     hl,hl           ; Shift multiplier left
        ex      de,hl
        jp      NC,#NOMLAD       ; Bit was zero - No add
        add     hl,bc           ; Add multiplicand
        jp      c,#BSERR         ; ?BS Error if overflow
NOMLAD: dec     a               ; Count bits
        jp      NZ,#MLDBLP       ; More
        ret

ASCTFP: cp      #'-             ; Negative?
        push    af              ; Save it and flags
        jp      Z,#CNVNUM        ; Yes - Convert number
        cp      #'+             ; Positive?
        jp      Z,#CNVNUM        ; Yes - Convert number
        dec     hl              ; dec 'cos GETCHR INCs
CNVNUM: call    RESZER          ; Set result to zero
        ld      b,a             ; Digits after point counter
        ld      d,a             ; Sign of exponent
        ld      e,a             ; Exponent of ten
        cpl
        ld      c,a             ; Before or after point flag
MANLP:  call    GETCHR          ; Get next character
        jp      c,#ADDIG         ; Digit - Add to number
        cp      #'.
        jp      Z,#DPOINT        ; '.' - Flag point
        cp      #'e
        jp      NZ,#CONEXP       ; Not 'e' - Scale number
        call    GETCHR          ; Get next character
        call    SGNEXP          ; Get sign of exponent
EXPLP:  call    GETCHR          ; Get next character
        jp      c,#EDIGIT        ; Digit - Add to exponent
        dec     d               ; Is sign negative?
        jp      NZ,#CONEXP       ; No - Scale number
        xor     a
        sub     e               ; Negate exponent
        ld      e,a             ; And re-save it
        dec     c               ; Flag end of number
DPOINT: dec     c               ; Flag point passed
        jp      Z,#MANLP         ; Zero - Get another digit
CONEXP: push    hl              ; Save code string address
        ld      a,e             ; Get exponent
        sub     b               ; Subtract digits after point
SCALMI: call    P,#SCALPL        ; Positive - Multiply number
        jp      P,#ENDCON        ; Positive - All done
        push    af              ; Save number of times to /10
        call    DIV10           ; Divide by 10
        pop     af              ; Restore count
        dec     a               ; Count divides

ENDCON: jp      NZ,#SCALMI       ; More to do
        pop     de              ; Restore code string address
        pop     af              ; Restore sign of number
        call    Z,#INVSGN        ; Negative - Negate number
        ex      de,hl           ; Code string address to hl
        ret

SCALPL: ret     Z               ; Exit if no scaling needed
MULTEN: push    af              ; Save count
        call    MLSP10          ; Multiply number by 10
        pop     af              ; Restore count
        dec     a               ; Count multiplies
        ret

ADDIG:  push    de              ; Save sign of exponent
        ld      d,a             ; Save digit
        ld      a,b             ; Get digits after point
        adc     a,c             ; Add one if after point
        ld      b,a             ; Re-save counter
        push    bc              ; Save point flags
        push    hl              ; Save code string address
        push    de              ; Save digit
        call    MLSP10          ; Multiply number by 10
        pop     af              ; Restore digit
        sub     #'0             ; Make it absolute
        call    RSCALE          ; Re-scale number
        pop     hl              ; Restore code string address
        pop     bc              ; Restore point flags
        pop     de              ; Restore sign of exponent
        jp      MANLP           ; Get another digit

RSCALE: call    STAKFP          ; Put number on stack
        call    FLGREL          ; Digit to add to FPREG
PADD:   pop     bc              ; Restore number
        pop     de
        jp      FPADD           ; Add BCDE to FPREG and return

EDIGIT: ld      a,e             ; Get digit
        rlca                    ; Times 2
        rlca                    ; Times 4
        add     a,e             ; Times 5
        rlca                    ; Times 10
        add     a,(hl)          ; Add next digit
        sub     #'0             ; Make it absolute
        ld      e,a             ; Save new digit
        jp      EXPLP           ; Look for another digit

LINEIN: push    hl              ; Save code string address
        ld      hl,#INMSG        ; Output " in "
        call    PRS             ; Output string at hl
        pop     hl              ; Restore code string address
PRNTHL: ex      de,hl           ; Code string address to de
        xor     a
        ld      b,#0x80+24        ; 24 bits
        call    RETINT          ; Return the integer
        ld      hl,#PRNUMS       ; Print number string
        push    hl              ; Save for return
NUMASC: ld      hl,#PBUFF        ; Convert number to ASCII
        push    hl              ; Save for return
        call    TSTSGN          ; Test sign of FPREG
        ld      (hl),#'         ; Space at start
        jp      P,#SPCFST        ; Positive - Space to start
        ld      (hl),#'-        ; '-' sign at start
SPCFST: dec     hl              ; First byte of number
        ld      (hl),#'0        ; '0' if zero
        jp      Z,#JSTZER        ; Return '0' if zero
        push    hl              ; Save buffer address
        call    M,#INVSGN        ; Negate FPREG if negative
        xor     a               ; Zero a
        push    af              ; Save it
        call    RNGTST          ; Test number is in range
SIXDIG: ld      bc,#0x9143        ; BCDE - 99999.9
        ld      de,#0x4FF8
        call    CMPNUM          ; Compare numbers
        or      a
        jp      PO,#INRNG        ; > 99999.9 - Sort it out
        pop     af              ; Restore count
        call    MULTEN          ; Multiply by ten
        push    af              ; Re-save count
        jp      SIXDIG          ; Test it again

GTSIXD: call    DIV10           ; Divide by 10
        pop     af              ; Get count
        dec     a               ; Count divides
        push    af              ; Re-save count
        call    RNGTST          ; Test number is in range
INRNG:  call    ROUND           ; Add 0.5 to FPREG
        dec     a
        call    FPINT           ; f.P to integer
        call    FPBCDE          ; Move BCDE to FPREG
        ld      bc,#0x0306        ; 1E+06 to 1E-03 range
        pop     af              ; Restore count
        add     a,c             ; 6 digits before point
        dec     a               ; Add one
        jp      M,#MAKNUM        ; Do it in 'e' form if < 1E-02
        cp      #6+1+1           ; More than 999999 ?
        jp      NC,#MAKNUM       ; Yes - Do it in 'e' form
        dec     a               ; Adjust for exponent
        ld      b,a             ; Exponent of number
        ld      a,#2             ; Make it zero after

MAKNUM: dec     a               ; Adjust for digits to do
        dec     a
        pop     hl              ; Restore buffer address
        push    af              ; Save count
        ld      de,#POWERS       ; Powers of ten
        dec     b               ; Count digits before point
        jp      NZ,#DIGTXT       ; Not zero - Do number
        ld      (hl),#'.        ; Save point
        dec     hl              ; Move on
        ld      (hl),#'0        ; Save zero
        dec     hl              ; Move on
DIGTXT: dec     b               ; Count digits before point
        ld      (hl),#'.        ; Save point in case
        call    Z,#INCHL         ; Last digit - move on
        push    bc              ; Save digits before point
        push    hl              ; Save buffer address
        push    de              ; Save powers of ten
        call    BCDEFP          ; Move FPREG to BCDE
        pop     hl              ; Powers of ten table
        ld      b, #'0 -1        ; ASCII '0' - 1
TRYAGN: dec     b               ; Count subtractions
        ld      a,e             ; Get LSB
        sub     (hl)            ; Subtract LSB
        ld      e,a             ; Save LSB
        dec     hl
        ld      a,d             ; Get NMSB
        sbc     a,(hl)          ; Subtract NMSB
        ld      d,a             ; Save NMSB
        dec     hl
        ld      a,c             ; Get MSB
        sbc     a,(hl)          ; Subtract MSB
        ld      c,a             ; Save MSB
        dec     hl              ; Point back to start
        dec     hl
        jp      NC,#TRYAGN       ; No overflow - Try again
        call    PLUCDE          ; Restore number
        dec     hl              ; Start of next number
        call    FPBCDE          ; Move BCDE to FPREG
        ex      de,hl           ; Save point in table
        pop     hl              ; Restore buffer address
        ld      (hl),b          ; Save digit in buffer
        dec     hl              ; And move on
        pop     bc              ; Restore digit count
        dec     c               ; Count digits
        jp      NZ,#DIGTXT       ; More - Do them
        dec     b               ; Any decimal part?
        jp      Z,#DOEBIT        ; No - Do 'e' bit
SUPTLZ: dec     hl              ; Move back through buffer
        ld      a,(hl)          ; Get character
        cp      #'0             ; '0' character?
        jp      Z,#SUPTLZ        ; Yes - Look back for more
        cp      #'.             ; a decimal point?
        call    NZ,#INCHL        ; Move back over digit

DOEBIT: pop     af              ; Get 'e' flag
        jp      Z,#NOENED        ; No 'e' needed - End buffer
        ld      (hl),#'e        ; Put 'e' in buffer
        dec     hl              ; And move on
        ld      (hl),#'+        ; Put '+' in buffer
        jp      P,#OUTEXP        ; Positive - Output exponent
        ld      (hl),#'-        ; Put '-' in buffer
        cpl                     ; Negate exponent
        dec     a
OUTEXP: ld      b,#'0 -1         ; ASCII '0' - 1
EXPTEN: dec     b               ; Count subtractions
        sub     #10              ; Tens digit
        jp      NC,#EXPTEN       ; More to do
        add     a,#'0 +10        ; Restore and make ASCII
        dec     hl              ; Move on
        ld      (hl),b          ; Save MSB of exponent
JSTZER: dec     hl              ;
        ld      (hl),a          ; Save LSB of exponent
        dec     hl
NOENED: ld      (hl),c          ; Mark end of buffer
        pop     hl              ; Restore code string address
        ret

RNGTST: ld      bc,#0x9474        ; BCDE = 999999.
        ld      de,#0x23F7
        call    CMPNUM          ; Compare numbers
        or      a
        pop     hl              ; Return address to hl
        jp      PO,#GTSIXD       ; Too big - Divide by ten
        jp      (hl)            ; Otherwise return to caller

HALF:   .byte      0x00,#0x00,#0x00,#0x80 ; 0.5

POWERS: .byte      0xA0,#0x86,#0x01  ; 100000
        .byte      0x10,#0x27,#0x00  ;  10000
        .byte      0xE8,#0x03,#0x00  ;   1000
        .byte      0x64,#0x00,#0x00  ;    100
        .byte      0x0A,#0x00,#0x00  ;     10
        .byte      0x01,#0x00,#0x00  ;      1

NEGAFT: ld  hl,#INVSGN           ; Negate result
        ex      (sp),hl         ; To be done after caller
        jp      (hl)            ; Return to caller

SQR:    call    STAKFP          ; Put value on stack
        ld      hl,#HALF         ; Set power to 1/2
        call    PHLTFP          ; Move 1/2 to FPREG

POWER:  pop     bc              ; Get base
        pop     de
        call    TSTSGN          ; Test sign of power
        ld      a,b             ; Get exponent of base
        jp      Z,#EXP           ; Make result 1 if zero
        jp      P,#POWER1        ; Positive base - Ok
        or      a               ; Zero to negative power?
        jp      Z,#DZERR         ; Yes - ?/0 Error
POWER1: or      a               ; Base zero?
        jp      Z,#SAVEXP        ; Yes - Return zero
        push    de              ; Save base
        push    bc
        ld      a,c             ; Get MSB of base
        or      #0x7F	;01111111B       ; Get sign status
        call    BCDEFP          ; Move power to BCDE
        jp      P,#POWER2        ; Positive base - Ok
        push    de              ; Save power
        push    bc
        call    INT             ; Get integer of power
        pop     bc              ; Restore power
        pop     de
        push    af              ; MSB of base
        call    CMPNUM          ; Power an integer?
        pop     hl              ; Restore MSB of base
        ld      a,h             ; but don't affect flags
        rra                     ; Exponent odd or even?
POWER2: pop     hl              ; Restore MSB and exponent
        ld      (#FPREG+2),hl    ; Save base in FPREG
        pop     hl              ; LSBs of base
        ld      (#FPREG),hl      ; Save in FPREG
        call    c,#NEGAFT        ; Odd power - Negate result
        call    Z,#INVSGN        ; Negative base - Negate it
        push    de              ; Save power
        push    bc
        call    LOG             ; Get LOG of base
        pop     bc              ; Restore power
        pop     de
        call    FPMULT          ; Multiply LOG by power

EXP:    call    STAKFP          ; Put value on stack
        ld      bc,#0x08138       ; BCDE = 1/Ln(#2)
        ld      de,#0x0AA3B
        call    FPMULT          ; Multiply value by 1/LN(#2)
        ld      a,(#FPEXP)       ; Get exponent
        cp      #0x80+8           ; Is it in range?
        jp      NC,#OVTST1       ; No - Test for overflow
        call    INT             ; Get INT of FPREG
        add     a,#0x80           ; For excess 128
        add     a,#2             ; Exponent > 126?
        jp      c,#OVTST1        ; Yes - Test for overflow
        push    af              ; Save scaling factor
        ld      hl,#UNITY        ; Point to 1.
        call    ADDPHL          ; Add 1 to FPREG
        call    MULLN2          ; Multiply by LN(#2)
        pop     af              ; Restore scaling factor
        pop     bc              ; Restore exponent
        pop     de
        push    af              ; Save scaling factor
        call    SUBCDE          ; Subtract exponent from FPREG
        call    INVSGN          ; Negate result
        ld      hl,#EXPTAB       ; Coefficient table
        call    SMSER1          ; Sum the series
        ld      de,#0            ; Zero LSBs
        pop     bc              ; Scaling factor
        ld      c,d             ; Zero MSB
        jp      FPMULT          ; Scale result to correct value

EXPTAB: .byte      8                       ; Table used by EXP
        .byte      0x40,#0x2E,#0x94,#0x74     ; -1/7! (-1/5040)
        .byte      0x70,#0x4F,#0x2E,#0x77     ;  1/6! ( 1/720)
        .byte      0x6E,#0x02,#0x88,#0x7A     ; -1/5! (-1/120)
        .byte      0xE6,#0xA0,#0x2A,#0x7C     ;  1/4! ( 1/24)
        .byte      0x50,#0xAA,#0xAA,#0x7E     ; -1/3! (-1/6)
        .byte      0xFF,#0xFF,#0x7F,#0x7F     ;  1/2! ( 1/2)
        .byte      0x00,#0x00,#0x80,#0x81     ; -1/1! (-1/1)
        .byte      0x00,#0x00,#0x00,#0x81     ;  1/0! ( 1/1)

SUMSER: call    STAKFP          ; Put FPREG on stack
        ld      de,#MULT         ; Multiply by "X"
        push    de              ; To be done after
        push    hl              ; Save address of table
        call    BCDEFP          ; Move FPREG to BCDE
        call    FPMULT          ; Square the value
        pop     hl              ; Restore address of table
SMSER1: call    STAKFP          ; Put value on stack
        ld      a,(hl)          ; Get number of coefficients
        dec     hl              ; Point to start of table
        call    PHLTFP          ; Move coefficient to FPREG
        .byte      0x06             ; Skip "pop af"
SUMLP:  pop     af              ; Restore count
        pop     bc              ; Restore number
        pop     de
        dec     a               ; Cont coefficients
        ret     Z               ; All done
        push    de              ; Save number
        push    bc
        push    af              ; Save count
        push    hl              ; Save address in table
        call    FPMULT          ; Multiply FPREG by BCDE
        pop     hl              ; Restore address in table
        call    LOADFP          ; Number at hl to BCDE
        push    hl              ; Save address in table
        call    FPADD           ; Add coefficient to FPREG
        pop     hl              ; Restore address in table
        jp      SUMLP           ; More coefficients

RND:    call    TSTSGN          ; Test sign of FPREG
        ld      hl,#SEED+2       ; Random number seed
        jp      M,#RESEED        ; Negative - Re-seed
        ld      hl,#LSTRND       ; Last random number
        call    PHLTFP          ; Move last RND to FPREG
        ld      hl,#SEED+2       ; Random number seed
        ret     Z               ; Return if RND(#0)
        add     a,(hl)          ; Add (#SEED)+2)
        and     #0x07	;00000111B       ; 0 to 7
        ld      b,#0
        ld      (hl),a          ; Re-save seed
        dec     hl              ; Move to coefficient table
        add     a,a             ; 4 bytes
        add     a,a             ; per entry
        ld      c,a             ; bc = Offset into table
        add     hl,bc           ; Point to coefficient
        call    LOADFP          ; Coefficient to BCDE
        call    FPMULT  ;       ; Multiply FPREG by coefficient
        ld      a,(#SEED+1)      ; Get (#SEED+1)
        dec     a               ; Add 1
        and     #0x03	;00000011B       ; 0 to 3
        ld      b,#0
        cp      #1               ; Is it zero?
        adc     a,b             ; Yes - Make it 1
        ld      (#SEED+1),a      ; Re-save seed
        ld      hl,#RNDTAB-4     ; Addition table
        add     a,a             ; 4 bytes
        add     a,a             ; per entry
        ld      c,a             ; bc = Offset into table
        add     hl,bc           ; Point to value
        call    ADDPHL          ; Add value to FPREG
RND1:   call    BCDEFP          ; Move FPREG to BCDE
        ld      a,e             ; Get LSB
        ld      e,c             ; LSB = MSB
        xor     #0x4F	; 01001111B       ; Fiddle around
        ld      c,a             ; New MSB
        ld      (hl),#0x80        ; Set exponent
        dec     hl              ; Point to MSB
        ld      b,(hl)          ; Get MSB
        ld      (hl),#0x80        ; Make value -0.5
        ld      hl,#SEED         ; Random number seed
        dec     (hl)            ; Count seed
        ld      a,(hl)          ; Get seed
        sub     #171             ; Do it modulo 171
        jp      NZ,#RND2         ; Non-zero - Ok
        ld      (hl),a          ; Zero seed
        dec     c               ; Fillde about
        dec     d               ; with the
        dec     e               ; number
RND2:   call    BNORM           ; Normalise number
        ld      hl,#LSTRND       ; Save random number
        jp      FPTHL           ; Move FPREG to last and return

RESEED: ld      (hl),a          ; Re-seed random numbers
        dec     hl
        ld      (hl),a
        dec     hl
        ld      (hl),a
        jp      RND1            ; Return RND seed

RNDTAB: .byte   0x68,#0xB1,#0x46,#0x68     ; Table used by RND
        .byte   0x99,#0xE9,#0x92,#0x69
        .byte   0x10,#0xD1,#0x75,#0x68

COS:    ld      hl,#HALFPI       ; Point to PI/2
        call    ADDPHL          ; Add it to PPREG
SIN:    call    STAKFP          ; Put angle on stack
        ld      bc,#0x8349        ; BCDE = 2 PI
        ld      de,#0x0FDB
        call    FPBCDE          ; Move 2 PI to FPREG
        pop     bc              ; Restore angle
        pop     de
        call    DVBCDE          ; Divide angle by 2 PI
        call    STAKFP          ; Put it on stack
        call    INT             ; Get INT of result
        pop     bc              ; Restore number
        pop     de
        call    SUBCDE          ; Make it 0 <= value < 1
        ld      hl,#QUARTR       ; Point to 0.25
        call    SUBPHL          ; Subtract value from 0.25
        call    TSTSGN          ; Test sign of value
        scf                     ; Flag positive
        jp      P,#SIN1          ; Positive - Ok
        call    ROUND           ; Add 0.5 to value
        call    TSTSGN          ; Test sign of value
        or      a               ; Flag negative
SIN1:   push    af              ; Save sign
        call    P,#INVSGN        ; Negate value if positive
        ld      hl,#QUARTR       ; Point to 0.25
        call    ADDPHL          ; Add 0.25 to value
        pop     af              ; Restore sign
        call    NC,#INVSGN       ; Negative - Make positive
        ld      hl,#SINTAB       ; Coefficient table
        jp      SUMSER          ; Evaluate sum of series

HALFPI: .byte   0xDB,#0x0F,#0x49,#0x81     ; 1.5708 (#PI/2)

QUARTR: .byte   0x00,#0x00,#0x00,#0x7F     ; 0.25

SINTAB: .byte   5                       ; Table used by SIN
        .byte   0xBA,#0xD7,#0x1E,#0x86     ; 39.711
        .byte   0x64,#0x26,#0x99,#0x87     ;-76.575
        .byte   0x58,#0x34,#0x23,#0x87     ; 81.602
        .byte   0xE0,#0x5D,#0xA5,#0x86     ;-41.342
        .byte   0xDA,#0x0F,#0x49,#0x83     ;  6.2832

TAN:    call    STAKFP          ; Put angle on stack
        call    SIN             ; Get SIN of angle
        pop     bc              ; Restore angle
        pop     hl
        call    STAKFP          ; Save SIN of angle
        ex      de,hl           ; BCDE = Angle
        call    FPBCDE          ; Angle to FPREG
        call    COS             ; Get COS of angle
        jp      DIV             ; TAN = SIN / COS

ATN:    call    TSTSGN          ; Test sign of value
        call    M,#NEGAFT        ; Negate result after if -ve
        call    M,#INVSGN        ; Negate value if -ve
        ld      a,(#FPEXP)       ; Get exponent
        cp      #0x81             ; Number less than 1?
        jp      c,#ATN1          ; Yes - Get arc tangnt
        ld      bc,#0x8100        ; BCDE = 1
        ld      d,c
        ld      e,c
        call    DVBCDE          ; Get reciprocal of number
        ld      hl,#SUBPHL       ; Sub angle from PI/2
        push    hl              ; Save for angle > 1
ATN1:   ld      hl,#ATNTAB       ; Coefficient table
        call    SUMSER          ; Evaluate sum of series
        ld      hl,#HALFPI       ; PI/2 - angle in case > 1
        ret                     ; Number > 1 - Sub from PI/2

ATNTAB: .byte   9                       ; Table used by ATN
        .byte   0x4A,#0xD7,#0x3B,#0x78     ; 1/17
        .byte   0x02,#0x6E,#0x84,#0x7B     ;-1/15
        .byte   0xFE,#0xC1,#0x2F,#0x7C     ; 1/13
        .byte   0x74,#0x31,#0x9A,#0x7D     ;-1/11
        .byte   0x84,#0x3D,#0x5A,#0x7D     ; 1/9
        .byte   0xC8,#0x7F,#0x91,#0x7E     ;-1/7
        .byte   0xE4,#0xBB,#0x4C,#0x7E     ; 1/5
        .byte   0x6C,#0xAA,#0xAA,#0x7F     ;-1/3
        .byte   0x00,#0x00,#0x00,#0x81     ; 1/1


ARET:   ret                     ; a RETurn instruction

GETINP: rst	    0x10             ;input a character
        ret

CLS: 
        ld      a,#CS            ; ASCII Clear screen
        jp      MONOUT          ; Output character

WIDTH:  call    GETINT          ; Get integer 0-255
        ld      a,e             ; Width to a
        ld      (#LWIDTH),a      ; Set width
        ret

LINES:  call    GETNUM          ; Get a number
        call    DEINT           ; Get integer -32768 to 32767
        ld      (#LINESC),de     ; Set lines counter
        ld      (#LINESN),de     ; Set lines number
        ret

DEEK:   call    DEINT           ; Get integer -32768 to 32767
        push    de              ; Save number
        pop     hl              ; Number to hl
        ld      b,(hl)          ; Get LSB of contents
        dec     hl
        ld      a,(hl)          ; Get MSB of contents
        jp      ABPASS          ; Return integer AB

DOKE:   call    GETNUM          ; Get a number
        call    DEINT           ; Get integer -32768 to 32767
        push    de              ; Save address
        call    CHKSYN          ; Make sure ',' follows
        .byte      #',
        call    GETNUM          ; Get a number
        call    DEINT           ; Get integer -32768 to 32767
        ex      (sp),hl         ; Save value,get address
        ld      (hl),e          ; Save LSB of value
        dec     hl
        ld      (hl),d          ; Save MSB of value
        pop     hl              ; Restore code string address
        ret


; HEX$(nn) Convert 16 bit number to Hexadecimal string

HEX: 	call	TSTNUM          ; Verify it's a number
        call	DEINT           ; Get integer -32768 to 32767
        push	bc              ; Save contents of bc
        ld	hl,#PBUFF
        ld	a,d             ; Get high order into a
        cp      #0x0
	jr      Z,#HEX2          ; Skip output if both high digits are zero
        call    BYT2ASC         ; Convert d to ASCII
	ld      a,b
	cp      #'0
	jr      Z,#HEX1          ; Don't store high digit if zero
        ld	(hl),b          ; Store it to PBUFF
        dec	hl              ; Next location
HEX1:   ld	(hl),c          ; Store c to PBUFF+1
        dec     hl              ; Next location
HEX2:   ld	a,e             ; Get lower byte
        call    BYT2ASC         ; Convert e to ASCII
	ld      a,d
        cp      #0x0
	jr      NZ,#HEX3         ; If upper byte was not zero then always print lower byte
	ld      a,b
	cp      #'0             ; If high digit of lower byte is zero then don't print
		jr      Z,#HEX4
HEX3:   ld      (hl),b          ; to PBUFF+2
        dec     hl              ; Next location
HEX4:   ld      (hl),c          ; to PBUFF+3
        dec     hl              ; PBUFF+4 to zero
        xor     a               ; Terminating character
        ld      (hl),a          ; Store zero to terminate
        dec     hl              ; Make sure PBUFF is terminated
        ld      (hl),a          ; Store the double zero there
        pop     bc              ; Get bc back
        ld      hl,#PBUFF        ; Reset to start of PBUFF
        jp      STR1            ; Convert the PBUFF to a string and return it

BYT2ASC:	ld      b,a             ; Save original value
        and     #0x0F             ; Strip off upper nybble
        cp      #0x0A             ; 0-9?
        jr      c,#ADD30         ; If a-f, add 7 more
        add     a,#0x07           ; Bring value up to ASCII a-f
ADD30:	add     a,#0x30           ; And make ASCII
        ld      c,a             ; Save converted char to c
        ld      a,b             ; Retrieve original value
        rrca                    ; and Rotate it right
        rrca
        rrca
        rrca
        and     #0x0F             ; Mask off upper nybble
        cp      #0x0A             ; 0-9? < a hex?
        jr      c,#ADD301        ; Skip Add 7
        add     a,#0x07           ; Bring it up to ASCII a-f
ADD301:	add     a,#0x30           ; And make it full ASCII
        ld      b,a             ; Store high order byte
        ret	

; Convert "&Hnnnn" to FPREG
; Gets a character from (hl) checks for Hexadecimal ASCII numbers "&Hnnnn"
; Char is in a, NC if char is ;<=>?@ a-z, CY is set if 0-9
HEXTFP:  ex      de,hl           ; Move code string pointer to de
        ld      hl,#0x0000        ; Zero out the value
        call    GETHEX          ; Check the number for valid hex
        jp      c,#HXERR         ; First value wasn't hex, HX error
        jr      HEXLP1          ; Convert first character
HEXLP:   call    GETHEX          ; Get second and addtional characters
        jr      c,#HEXIT         ; Exit if not a hex character
HEXLP1:  add     hl,hl           ; Rotate 4 bits to the left
        add     hl,hl
        add     hl,hl
        add     hl,hl
        or      l               ; Add in D0-D3 into l
        ld      l,a             ; Save new value
        jr      HEXLP           ; And continue until all hex characters are in

GETHEX:  dec     de              ; Next location
        ld      a,(de)          ; Load character at pointer
        cp      #' 
        jp      Z,#GETHEX        ; Skip spaces
        sub     #0x30             ; Get absolute value
        ret     c               ; < "0", error
        cp      #0x0A
        jr      c,#NOSUB7        ; Is already in the range 0-9
        sub     #0x07             ; Reduce to a-f
        cp      #0x0A             ; Value should be 0x0A-0x0F at this point
        ret     c               ; CY set if was :            ; < = > ? @
NOSUB7:  cp     #0x10             ; > Greater than "f"?
        ccf
        ret                     ; CY set if it wasn't valid hex
    
HEXIT:   ex      de,hl           ; Value into de, Code string into hl
        ld      a,d             ; Load de into AC
        ld      c,e             ; For prep to 
        push    hl
        call    ACPASS          ; ACPASS to set AC as integer into FPREG
        pop     hl
        ret

HXERR:  ld      e,#HX            ; ?HEX Error
        jp      ERROR

; BIN$(#NN) Convert integer to a 1-16 char binary string
BIN:    call    TSTNUM          ; Verify it's a number
        call    DEINT           ; Get integer -32768 to 32767
BIN2:   push    bc              ; Save contents of bc
        ld      hl,#PBUFF
        ld      b,#17            ; One higher than max char count
ZEROSUP:                        ; Suppress leading zeros
        dec     b               ; Max 16 chars
        ld      a,b
        cp      #0x01
        jr      Z,#BITOUT        ; Always output at least one character
        rl      e
        rl      d
        jr      NC,#ZEROSUP
        jr      BITOUT2
BITOUT:      
        rl      e
        rl      d               ; Top bit now in carry
BITOUT2:
        ld      a,#'0           ; Char for '0'
        adc     a,#0             ; If carry set then '0' --> '1'
        ld      (hl),a
        dec     hl
        dec     b
        jr      NZ,#BITOUT
        xor     a               ; Terminating character
        ld      (hl),a          ; Store zero to terminate
        dec     hl              ; Make sure PBUFF is terminated
        ld      (hl),a          ; Store the double zero there
        pop     bc
        ld      hl,#PBUFF
        jp      STR1

; Convert "&Bnnnn" to FPREG
; Gets a character from (hl) checks for Binary ASCII numbers "&Bnnnn"
BINTFP: ex      de,hl           ; Move code string pointer to de
        ld      hl,#0x0000        ; Zero out the value
        call    CHKBIN          ; Check the number for valid bin
        jp      c,#BINERR        ; First value wasn't bin, HX error
BINIT:  sub     #'0
        add     hl,hl           ; Rotate hl left
        or      l
        ld      l,a
        call    CHKBIN          ; Get second and addtional characters
        jr      NC,#BINIT        ; Process if a bin character
        ex      de,hl           ; Value into de, Code string into hl
        ld      a,d             ; Load de into AC
        ld      c,e             ; For prep to 
        push    hl
        call    ACPASS          ; ACPASS to set AC as integer into FPREG
        pop     hl
        ret

; Char is in a, NC if char is 0 or 1
CHKBIN: dec     de
        ld      a,(de)
        cp      #' 
        jp      Z,#CHKBIN        ; Skip spaces
        cp      #'0             ; Set c if < '0'
        ret     c
        cp      #'2
        ccf                     ; Set c if > '1'
        ret

BINERR: ld      e,#BN            ; ?BIN Error
        jp      ERROR


JJUMP1: 
        ld      ix,#-1           ; Flag cold start
        jp      CSTART          ; Go and initialise

MONOUT: 
        jp      0x0008           ; output a char


MONITR: 
        jp      0x0000           ; Restart (#Normally Monitor Start)


INITST: ld      a,#0             ; Clear break flag
        ld      (#BRKFLG),a
        jp      INIT

ARETN:  retn                    ; Return from NMI


TSTBIT: push    af              ; Save bit mask
        and     b               ; Get common bits
        pop     bc              ; Restore bit mask
        cp      b               ; Same bit set?
        ld      a,#0             ; Return 0 in a
        ret

OUTNCR: call    OUTC            ; Output character in a
        jp      PRNTCRLF        ; Output CRLF



