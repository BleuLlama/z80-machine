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
9001 DATA 237, 95, 60, 237, 79, 71, 175, 195, 125, 17
9003 DATA 999
9004 REM - Created Wed Mar 22 01:23:18 2017
