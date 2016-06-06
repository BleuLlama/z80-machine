;===============================================================================
; Contents of this file are copyright Grant Searle
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

	.module	RC2014INT
.area		.CODE(ABS)

; Minimum 6850 ACIA interrupt driven serial I/O to run modified NASCOM Basic 4.7
; Full input buffering with incoming data hardware handshaking
; Handshake shows full before the buffer is totally filled to allow run-on from the sender

SER_BUFSIZE     = 0x3F
SER_FULLSIZE    = 0x30
SER_EMPTYSIZE   = 0x05

RTS_HIGH        = 0x0D6
RTS_LOW         = 0x096

serBuf          = 0x8000
serInPtr        = serBuf+SER_BUFSIZE
serRdPtr        = serInPtr+2
serBufUsed      = serRdPtr+2
basicStarted    = serBufUsed+1
TEMPSTACK       = 0x80ED ; Top of BASIC line input buffer so is "free ram" when BASIC resets

CR              = 0x0D
LF              = 0x0A
CS              = 0x0C             ; Clear screen

;------------------------------------------------------------------------------
; Reset

.org 0x0000
RST00:          di                       ;Disable interrupts
                jp       SBCINIT         ;Initialize Hardware and go

;------------------------------------------------------------------------------
; TX a character over RS232 

.org 0x0008
RST08:           jp      TXA

;------------------------------------------------------------------------------
; RX a character over RS232 Channel A [Console], hold here until char ready.

.org 0x0010
RST10:           jp      RXA

;------------------------------------------------------------------------------
; Check serial status

.org 0x0018
RST18:           jp      CKINCHAR

;------------------------------------------------------------------------------
; RST 38 - INTERRUPT VECTOR [ for IM 1 ]

.org 0x0038
RST38:           jr      serialInt       

;------------------------------------------------------------------------------
serialInt:      push     af
                push     hl

                in       a,(0x80)
                and      #0x01             ; Check if interupt due to read buffer full
                jr       Z,rts0          ; if not, ignore

                in       a,(0x81)
                push     af
                ld       a,(serBufUsed)
                cp       #SER_BUFSIZE     ; If full then ignore
                jr       NZ,notFull
                pop      af
                jr       rts0

notFull:        ld       hl,(serInPtr)
                inc      hl
                ld       a,l             ; Only need to check low byte becasuse buffer<256 bytes
		; WHAT?
                ;CP       (serBuf+SER_BUFSIZE) & $FF^M
                ;cp       (serBuf+SER_BUFSIZE) & #0xFF
                jr       NZ, notWrap
                ld       hl, #serBuf
notWrap:        ld       (serInPtr),hl
                pop      af
                ld       (hl),a
                ld       a,(serBufUsed)
                inc      a
                ld       (serBufUsed),a
                cp       #SER_FULLSIZE
                jr       C,rts0
                ld       a,#RTS_HIGH
                out      (0x80),a
rts0:           pop      hl
                pop      af
                ei
                reti

;------------------------------------------------------------------------------
RXA:
waitForChar:    ld       a,(serBufUsed)
                cp       #0x00
                jr       Z, waitForChar
                push     hl
                ld       hl,(serRdPtr)
                inc      hl
                ld       a,l             ; Only need to check low byte becasuse buffer<256 bytes
                ;cp       (serBuf+#SER_BUFSIZE & #0xFF)
                jr       NZ, notRdWrap
                ld       hl, #serBuf
notRdWrap:      di
                ld       (serRdPtr),hl
                ld       a,(serBufUsed)
                dec      a
                ld       (serBufUsed),a
                cp       #SER_EMPTYSIZE
                jr       NC,rts1
                ld       a, #RTS_LOW
                out      (0x80),a
rts1:
                ld       a,(hl)
                ei
                pop      hl
                ret                      ; Char ready in A

;------------------------------------------------------------------------------
TXA:            push     af              ; Store character
conout1:        in       a,(0x80)         ; Status byte       
                bit      #1,a             ; Set Zero flag if still transmitting character       
                jr       Z,conout1       ; Loop until flag signals ready
                pop      af              ; retrieve character
                out      (0x81),a         ; Output the character
                ret

;------------------------------------------------------------------------------
CKINCHAR:       ld       a,(serBufUsed)
                cp       #0x00
                ret

SBCPRINT:       ld       a,(hl)          ; Get character
                or       a               ; Is it 0x00 ?
                ret      Z               ; Then return on terminator
                rst      0x08            ; Print it
                inc      hl              ; Next Character
                jr       SBCPRINT        ; Continue until 0x00
                ret
;------------------------------------------------------------------------------
SBCINIT:
               ld        hl, #TEMPSTACK    ; Temp stack
               ld        sp,hl           ; Set up a temporary stack
               ld        hl, #serBuf
               ld        (serInPtr),hl
               ld        (serRdPtr),hl
               xor       a               ;0 to accumulator
               ld        (serBufUsed),a
               ld        a, #RTS_LOW
               out       (0x80),a        ; Initialise ACIA
               im        1
               ei
               ld        hl, #SIGNON1    ; Sign-on message
               call      SBCPRINT        ; Output string
               ld        a,(basicStarted); Check the BASIC STARTED flag
               cp        #0x59	; 'Y'             ; to see if this is power-up
               jr        NZ,COLDSTART    ; If not BASIC started then always do cold start
               ld        hl, #SIGNON2      ; Cold/warm message
               call      SBCPRINT           ; Output string
CORW:
               call      RXA
               and       #0xDF	; %1101 1111       ; lower to uppercase
               cp        a, #0x43	;'C'
               jr        NZ, CHECKWARM
               rst       0x08
               ld        a, #0x0D
               rst       0x08
               ld        a, #0x0A
               rst       0x08
COLDSTART:     ld        a, #0x59	;'Y'; Set the BASIC STARTED flag
               ld        (basicStarted),a
               jp        0x0150           ; Start BASIC COLD
CHECKWARM:
               cp        #0x57	;'W'
               jr        NZ, CORW
               rst       0x08
               ld        a,#0x0D
               rst       0x08
               ld        a,#0x0A
               rst       0x08
               jp        0x0153           ; Start BASIC WARM
              
SIGNON1:       .byte     CS
               .ascii    "Z80 SBC By Grant Searle"
               .byte     CR,LF,0
SIGNON2:       .byte     CR,LF
               .asciz     "Cold or warm start (C or W)? "
