
$| = 1;

$ifn = "../basic.32/bas32K.asm";
$ofn = "basic.asm";

open $ifh, '<', $ifn;
open $ofh, '>', $ofn;

$nlines = 0;

while( $line = <$ifh> )
{
    print $line;

    $line =~ s/\.WORD/.word/g;
    $line =~ s/\.ORG/.byte/g;
    $line =~ s/\.BYTE/.byte/g;
    $line =~ s/^\s*\.[Ee][Nn][Dd]//g;
    $line =~ s/\bOR\b/or/g;
    $line =~ s/\bJP\b/jp/g;
    $line =~ s/\bJR\b/jr/g;
    $line =~ s/\bCALL\b/call/g;
    $line =~ s/\bINC\b/dec/g;
    $line =~ s/\bDEC\b/dec/g;

    $line =~ s/\bXOR\b/xor/g;
    $line =~ s/\bADD\b/add/g;
    $line =~ s/\bSUB\b/sub/g;
    $line =~ s/\bADC\b/adc/g;
    $line =~ s/\bEX\b/ex/g;

    $line =~ s/\bLD\b/ld/g;
    $line =~ s/\bCP\b/cp/g;
    $line =~ s/\bCPL\b/cpl/g;
    $line =~ s/\bDJNZ\b/djnz/g;
    $line =~ s/\bBIT\b/bit/g;
    $line =~ s/\bSET\b/set/g;
    $line =~ s/\bCLR\b/clr/g;
    $line =~ s/\bAND\b/and/g;
    $line =~ s/\bLD\b/ld/g;
    $line =~ s/\bRETN\b/retn/g;
    $line =~ s/\bRETI\b/reti/g;
    $line =~ s/\bRET\b/ret/g;

    $line =~ s/\bPUSH\b/push/g;
    $line =~ s/\bPOP\b/pop/g;

    $line =~ s/\bRL\b/rl/g;
    $line =~ s/\bCCF\b/ccf/g;
    $line =~ s/\bRRCA\b/rrca/g;
    $line =~ s/\bRLCA\b/rlca/g;
    $line =~ s/\bRRA\b/rra/g;
    $line =~ s/\bRLA\b/rla/g;
    $line =~ s/\bRST\b/rst/g;
    $line =~ s/\bSBC\b/sbc/g;
    $line =~ s/\bSCF\b/scf/g;

    $line =~ s/\bOUT\b/out/g;
    $line =~ s/\bIN\b/in/g;

    $line =~ s/\bNOP\b/nop/g;
    $line =~ s/\bHALT\b/halt/g;

    $line =~ s/\bA\b/a/g;
    $line =~ s/\bB\b/b/g;
    $line =~ s/\bC\b/c/g;
    $line =~ s/\bD\b/d/g;
    $line =~ s/\bE\b/e/g;
    $line =~ s/\bF\b/f/g;
    $line =~ s/\bH\b/h/g;
    $line =~ s/\bL\b/l/g;
    $line =~ s/\bIX\b/ix/g;
    $line =~ s/\bAF\b/af/g;
    $line =~ s/\bBC\b/bc/g;
    $line =~ s/\bDE\b/de/g;
    $line =~ s/\bHL\b/hl/g;
    $line =~ s/\bSP\b/sp/g;

	# fix some values
    $line =~ s/\b([0-9A-F]+)H\b/0x$1/g;
    $line =~ s/\$([0-9A-F]+)/0x$1/g;

	# fix some labels
    $line =~ s/^([A-Za-z0-9]+)(\s+)/$1:$2/g;

	# and tweak for EQUs
    $line =~ s/(.+):(\s+).EQU\s+/$1$2= /g;

	# tweak some immediates

    $line =~ s/,([0-9A-Z])/,#$1/g;
    $line =~ s/\(([0-9A-Z])/(#$1/g;

	# tweak some ugly numbers
    $line =~ s/0x0([0-9A-Fa-f][0-9A-Fa-f])\b/0x$1/g;

    #$line =~ s/'([ -\&\(-~])'/printf( "--%c %02x--", $1, hex($1))/e;

	# fix line endings
    $line =~ s/\r\n/\n/g;
	
    print $ofh $line;
    print $line;
    $nlines++;
}


printf "\n\n%d lines converted\n", $nlines;
close $ofh;
close $ifh;
