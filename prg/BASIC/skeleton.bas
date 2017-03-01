10 REM put your comments here through line 47
47 REM ======================================

48 goto 100
49 REM Skeleton BASIC library v001, yorgle@gmail.com 

50 REM == setuup vars
51 f$="example.bas"
59 print "Ready.":end

60 print CHR$(27);CHR$(123);c$;" ";f$;CHR$(7):return
61 print CHR$(27);CHR$(123);c$;CHR$(7):return

70 c$="save":gosub 60:goto 99
71 c$="load":gosub 60:goto 99
72 c$="loadrun":gosub 60:goto 99
73 c$="type":gosub 60:goto 99
74 c$="chain":gosub 60:goto 99

80 c$="catalog":gosub 61:goto 99
81 c$="cd":gosub 61:goto 99
82 c$="load skeleton.bas":gosub 61:goto 99

99 print "Ready.":end

100 REM == Your program here... ==
110 print "Ready for a new program!"
120 end
