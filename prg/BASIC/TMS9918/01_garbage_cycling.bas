1 REM Gargbage Cycling
2 REM yorgle@gmail.com

10 REM TMS9918A ports 10h,11h (SORD M5)
11 MEM=16
12 REG=17

13 REM you could also do this using hex values like:
14 REM  11 MEM=&h10
14 REM  12 MEM=&h11

20 REM Register settings for bitmap mode
30 DATA 0, 208, 0, 0, 1, 0, 0, 244

40 REM Set up registers
50 FOR I = 0 TO 7
60   READ V
70   OUT REG, V
80   OUT REG, (I OR 128)
90 NEXT

100 REM Cycle through colors
110 FOR B = 1 TO 15
120   FOR F = 1 TO 15
130     OUT REG, F*16+B
140     OUT REG, 135
150     FOR J = 1 TO 100: NEXT
160   NEXT F
170 NEXT B

200 OUT REG, 33
210 OUT REG, 135

