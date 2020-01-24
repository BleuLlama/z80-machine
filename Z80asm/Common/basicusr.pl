#!/usr/bin/perl
#  hackey perl script to mangle .lst to basic listings


$filename = shift;
$destfn = shift;
$baseramtop = shift;
$autorun = shift;


$baseram = $baseramtop . "00";


printf ">>  Reading in %s\n", $filename;


open IF, "<$filename";
@lines = <IF>;
close IF;

$work = 1;

$lines = 0;

foreach $line (@lines)
{
    #print $line;
    chomp $line;

    $care = substr( $line, 8, 18 );

    if(index( $care, "Assembler") != -1 ) { $work = 0; }

    if( $work == 1 ) {
	$care =~ s/^\s+//g;
	$care =~ s/\s+$//g;
	next if $care eq "";

    	#printf ">> |%s|\n", $care;
	push @program, split( ' ', $care );
	$lines++;
    }
}


printf ">>  %d items processed.\n", scalar @program;
printf ">>  Found %d lines of code.\n", $lines;
printf ">>  Generating %s for 0x%s\n", $destfn, $baseram;

if( -e "usrstrap.bas" ) {
	`cp usrstrap.bas $destfn`;
	open OF, ">>$destfn";
} else {

open OF, ">$destfn";

print OF <<EOP;
10 print "LL-Kickstart-USR() v1.0"

20 REM == poke at 0x$baseram ==
30 let mb=&H$baseram

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
240 poke mb+2, &H$baseramtop

250 print "Calling usr()..."
260 print usr(0)
270 end

EOP
}

printf OF "9000 REM == program == \n";
printf OF "9001 DATA ";

$line = 9001;

$l = 0;

foreach $byte (@program)
{
    if( $l == 0 ) {
	$line += 1;
    }
    $l++;
    printf OF hex $byte;

    if( $l < 10 ) { 
	printf OF ",";
    } else {
	$line += 1;
	printf OF "\n%d DATA ", $line;
	$l = 0;
    }
}

if( $l == 5 ) {
}
printf OF "999\n";
$lt = localtime;
$line++;		# fix for "9100 DATA 999" error
printf OF "%d REM - Created %s\n", $line, $lt;

close OF;

