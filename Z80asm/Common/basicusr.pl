#!/usr/bin/perl
#  hackey perl script to mangle .lst to basic listings


$filename = shift;
$destfn = shift;
$baseramtop = shift;

$baseram = $baseramtop . "00";


printf ">>  Reading in %s\n", $filename;


open IF, "<$filename";
@lines = <IF>;
close IF;

$work = 1;

$lines = 0;

foreach $line (@lines)
{
    print $line;
    chomp $line;

    $care = substr( $line, 8, 18 );

    if(index( $care, "Assembler") != -1 ) { $work = 0; }

    if( $work == 1 ) {
	$care =~ s/^\s+//g;
	$care =~ s/\s+$//g;
	next if $care eq "";

    	printf ">> |%s|\n", $care;
	push @program, split( ' ', $care );
	$lines++;
    }
}


printf ">>  %d items processed.\n", scalar @program;
printf ">>  Found %d lines of code.\n", $lines;
printf ">>  Generating %s for 0x%s\n", $destfn, $baseram;


open OF, ">$destfn";

print OF <<EOP;
10 REM == poke at 0x$baseram ==
20 let mb=&H$baseram

100 REM == poke it in ==
110 read op
120 if op = 999 then goto 200
130 poke mb, op
140 let mb = mb + 1
150 goto 110

200 REM == JP start address (c3 00 f8) jp f800 ==
210 mb = &H8048
220 poke mb, &HC3
230 poke mb+1, &H00
240 poke mb+2, &H$baseramtop

250 REM == run it ==
260 print usr(0)
270 end

EOP


printf OF "9000 REM == program == \n";
printf OF "9010 DATA ";

$line = 9010;

$l = 0;

foreach $byte (@program)
{
    if( $l == 0 ) {
	$line += 10;
    }
    $l++;
    printf OF hex $byte;

    if( $l < 10 ) { 
	printf OF ", ";
    } else {
	$line += 10;
	printf OF "\n%d DATA ", $line;
	$l = 0;
    }
}

if( $l == 5 ) {
}
printf OF "999\n";


printf OF "run\n"; 

close OF;

