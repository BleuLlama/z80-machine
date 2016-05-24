; RC2014LL
;          includes for platform defines
;
;          2016-05-09 Scott Lawrence
;
;  This code is free for any use. MIT License, etc.
;
	.module RC2014LL

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; some defines we will use (for ports)

;;;;;;;;;;;;;;;;;;;;
TermStatus	= 0x80	; Status on MC6850 for terminal comms
TermData	= 0x81	; Data on MC6850 for terminal comms
 DataReady	= 0x01

;;;;;;;;;;;;;;;;;;;;
SDStatus	= 0xD1	; Status on MC6850 for SD comms
SDData		= 0xD0	; Data on MC6850 for SD comms
	; SD Commands:
	;  ~L		Get directory listing
	;  ~Fname	Set filename
	;  ~R		Open that file for read

;;;;;;;;;;;;;;;;;;;;
BankConfig	= 0xF0	; bank configuration port
	; bits are in pairs,  0b-33221100
	; when bits for bank 3 are set to 00, the ROM is in place in bank 00
	; on poweron, the value is 0x00

;;;;;;;;;;;;;;;;;;;;
CopyRemap0	= 0xC000	; where bank 0 is remapped to for ROM write
CopyLoc		= 0x8000	; where we copy the stub to to survive remap


