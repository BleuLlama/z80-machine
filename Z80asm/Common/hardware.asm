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
  DataReady	= 0x01  ;  this is the only bit emulation works with.

;;;;;;;;;;;;;;;;;;;;
SDStatus	= 0xD0	; Status on MC6850 for SD comms
SDData		= 0xD1	; Data on MC6850 for SD comms
	; SD Commands: (newline delimited)
	;  ~L		Get directory listing
	;  ~Fname	Set operations name (file or directory)
	;  ~R		Open that file for read

;;;;;;;;;;;;;;;;;;;;
RomDisable	= 0x00	; IO port 00
	; bit 0 (0x01) is the ROM disable bit,
	;  = 0x00 -> ROM is active
	;  = 0x01 -> ROM is disabled

;;;;;;;;;;;;;;;;;;;;
EmulatorControl	= 0xEE
	; Read for version of emulator:
	;   'A' for RC2014 emu (32k)    v1.0 2016/10/10
	;   'B' for RC2014LL emu (64k)  v1.0 2016/10/10
	; write F0 to exit emulator
