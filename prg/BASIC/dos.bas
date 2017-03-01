
10 print "  Menu:"
20 print "   1: load basload.bas"
30 print "   2: catalog directory listing"
40 print "   3: type fib.bas"
50 print "   4: chain fib.bas"
60 print "   5: save foo.bas"

900 input a
910 on a goto 1000, 1050, 1100, 1150, 1200
920 goto 10


999 end
1000 REM == ghost-type a program from the Console ==
1010 cmd$ = "loadrun baslload.bas"
1020 goto 9000

1050 REM == Get a directory catalog
1060 cmd$ = "catalog"
1070 goto 9000

1100 REM == load in a file
1110 cmd$ = "type fib.bas"
1120 goto 9000


1150 REM == load in a file, run it
1160 cmd$ = "chain foo.bas"
1170 goto 9000

1200 REM == Save out the file
1210 cmd$ = "save foo.bas"
1220 goto 9000

9000 REM == Send a command
9101 print CHR$(27);CHR$(123);cmd$;CHR$(7)
9102 end

