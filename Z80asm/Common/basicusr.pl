#!/usr/bin/perl
#  hackey perl script to mangle .lst to basic listings


$filename = shift;

printf "Using %s\n", $filename;

open IF, "<$filename";
@lines = <IF>;
close IF;

$work = 1;

foreach $line (@lines)
{
    print $line;
    chomp $line;

    $care = substr( $line, 8, 21 );

    if(index( $care, "Assembler") != -1 ) { $work = 0; }

    if( $work == 1 ) {
	$care =~ s/^\s+//g;
	$care =~ s/\s+$//g;
	next if $care eq "";

    	printf ">> |%s|\n", $care;
	push @program, split( ' ', $care );
    }
}

print <<EOP;
new
clear
10 REM Start our poke address at 0xF800
20 let mb=&HF800

100 REM poke the program in
110 read op
120 if op = 999 then goto 200
130 poke mb, op
140 let mb = mb + 1
150 goto 110
200 print "Done poking!"

1000 REM JP start address (c3 00 f8) jp f800
1010 poke -32696,&HC3
1020 poke -32695,&H00
1030 poke -32694,&Hf8

1040 REM run the function!
1050 print usr(8)
1060 print usr(5)
1070 print usr(100)

EOP


printf "9000 REM == PROGRAM LISTING ==\n";
printf "9010 DATA ";

$line = 9010;

$l = 0;

foreach $byte (@program)
{
    if( $l == 0 ) {
	$line += 10;
    }
    $l++;
    printf( hex $byte );

    if( $l < 5 ) { 
	printf( ", " );
    } else {
	$line += 10;
	printf( "\n%d DATA ", $line );
	$l = 0;
    }
}

if( $l == 5 ) {
}
printf( "999\n" );

