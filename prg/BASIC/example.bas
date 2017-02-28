
10 print "type 'run xxxx' to run the desired demo."
20 print " 1000 type fib.bas"

999 end
1000 REM == ghost-type a program from the Console ==
1010 cmd$ = "type fib.bas"
1020 gosub 9000
1020 end

1050 REM == Get a directory catalog
1060 cmd$ = "ls"
1070 gosub 9000
1080 end

1100 REM == load in a file
1110 cmd$ = "load foo.bas"
1120 gosub 9000
1130 end


1150 REM == load in a file, run it
1160 cmd$ = "chain foo.bas"
1170 gosub 9000
1180 end

1100 REM == Save out the file
1110 cmd$ = "save foo.bas"
1120 gosub 9000
1130 end

9000 REM == Send a command
9101 print CHR$(27);CHR$(123);cmd$;CHR$(7)
9102 return



