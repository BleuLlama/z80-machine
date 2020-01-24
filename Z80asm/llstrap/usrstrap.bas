10 print "Llichen 80 Kickstart"
20 OUT 0,0

100 REM == Start up video
110 MEM=&H10
120 REG=&H11
130 REM Register settings for bitmap mode (0/gray)
140 DATA 0,208,0,0,1,0,0,14
150 FOR I = 0 TO 7
160 READ V
170 OUT REG, V
180 OUT REG, (I OR &h80)
190 NEXT

200 REM == poke at 0xF800 ==
210 print "Poking..";
220 mb = &HF800
230 read op
240 if op = 999 then goto 280
250 poke mb, op
260 let mb = mb + 1
270 goto 230
280 print "..Done."

300 REM == JP start address (c3 00 f8) jp f800 ==
310 mb = &H8048
320 poke mb, &HC3
330 poke mb+1, &H00
340 poke mb+2, &HF8

400 REM change color to gr on ltgry
410 OUT REG, 239
420 OUT REG, ( 7 OR &H80)

450 print "Calling usr()..."
460 print usr(0)
470 end
