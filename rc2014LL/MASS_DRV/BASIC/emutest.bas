10 REM == Emulation tester ==

50 print "Emulation Testing..."
60 print ""

110 print "Select option:"
120 print "0: End"
130 print "1: Exit emulation"
140 print "2: Set LL for RAM at $0000"
150 print "3: Set LL for ROM at $0000"
160 print "4: Copy ROM to RAM"
170 print "5: Test ROM at $0000"

200 print ""
210 input s
220 print "Selection: ", s
230 if s = 0  then end
240 if s = 1  goto 1000
250 if s = 2  goto 1100
260 if s = 3  goto 1200
270 if s = 4  goto 1300
280 if s = 5  goto 1400

900 print ""
910 goto 110

1000 REM == Exit emulation ==
1010 out 238, 240
1020 end

1100 REM == Switch off ROM ==
1110 out 0, 1
1120 goto 900

1200 REM == Switch on ROM ==
1210 out 0, 0
1220 goto 900

1300 REM == COPY ROM TO RAM ==
1310 print "Working..."
1320 for a = 0 to 8192
1330 poke a, peek( a )
1340 next a
1350 print "Done."
1360 goto 900

1400 REM == TEST IF RAM ==
1410 b = peek(8000)
1420 z = 24
1430 if b = 24 then z = 42
1440 poke 8000, z
1450 c = peek( 8000 )
1460 poke 8000, b
1470 if c = z goto 1500
1480 print ">> $0000 is ROM"
1490 goto 900
1500 print ">> $0000 is RAM"
1510 goto 900
