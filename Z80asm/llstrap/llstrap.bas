10 print "LL-Kickstart-USR() v1.0"

20 REM == poke at 0xF800 ==
30 let mb=&HF800

100 print "Poking in the program...";
110 read op
120 if op = 999 then goto 160
130 poke mb, op
140 let mb = mb + 1
150 goto 110
160 print "...Done!"

200 REM == JP start address (c3 00 f8) jp f800 ==
210 mb = &H8048
220 poke mb, &HC3
230 poke mb+1, &H00
240 poke mb+2, &HF8

250 print "Calling usr()..."
260 print usr(0)
270 end

9000 REM == program == 
9001 DATA 237, 95, 60, 237, 79, 62, 72, 211, 129, 211
9003 DATA 129, 62, 73, 211, 129, 211, 129, 24, 5, 71
9005 DATA 175, 195, 125, 17, 33, 46, 248, 6, 8, 14
9007 DATA 0, 126, 211, 17, 121, 246, 128, 211, 17, 12
9009 DATA 35, 16, 244, 195, 125, 17, 0, 208, 0, 0
9011 DATA 1, 0, 0, 244, 197, 6, 255, 16, 254, 193
9013 DATA 201, 999
9015 REM - Created Sun Apr 21 11:47:14 2019
