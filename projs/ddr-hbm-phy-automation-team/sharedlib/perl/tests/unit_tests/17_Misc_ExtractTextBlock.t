use strict;
use warnings;
use v5.14.2;

use Test2::Bundle::More;
use Test2::Tools::Compare;
use File::Temp;

use FindBin qw($RealBin $RealScript);

use lib "$RealBin/../lib";
use Util::CommonHeader;
use Util::Misc;

our $DEBUG      = 0;
our $VERBOSITY  = 0;
our $STDOUT_LOG = undef; 
our $DA_RUNNING_UNIT_TESTS = 1;

sub Main() {
    plan(3);

    my @extractedLines1 = ("Start from Here\n","Random Line\n","End Here\n"); 
    my @extractedLines2 = ("Start again\n","Random Line\n","End again\n");
    my @extractedLines3 = qw( );
    my $filename = "$RealBin/../data/${RealScript}.lis";
    my $curpos   = 0;
    my $startRegex = "^Start";
    my $endRegex = "^End";

    open(my $fh, "<$filename")|| die("Failed to open '$filename':$!");
    ok(return_is(\&ExtractTextBlock,$fh,$curpos,$startRegex,$endRegex,\@extractedLines1),'Test ExtractTextBlock from the begining of the file'); 
    ok(return_is(\&ExtractTextBlock,$fh,$curpos,$startRegex,$endRegex,\@extractedLines2),'Test ExtractTextBlock from the middle of the file'); 
    ok(return_is(\&ExtractTextBlock,$fh,$curpos,$startRegex,$endRegex,\@extractedLines3),'Test ExtractTextBlock from the middle of the file and no match'); 
    close($fh);

    done_testing();
}

sub return_is($$$$$$) {
    my $ref_func        = shift;
    my $func_fh         = shift;
    my $func_curpos     = shift;
    my $func_startRegex = shift;
    my $func_endRegex   = shift;
    my $aref_expected   = shift;

    my ($curpos,$aref) = &$ref_func($func_fh, $func_curpos, $func_startRegex, $func_endRegex);
    return( @$aref ~~ @$aref_expected);
}

Main();

