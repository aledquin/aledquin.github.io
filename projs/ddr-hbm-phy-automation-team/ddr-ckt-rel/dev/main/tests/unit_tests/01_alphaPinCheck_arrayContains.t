use strict;
use warnings;
use Carp qw(cluck confess croak);
use Test::More tests => 5;
use Test::Exception;
use File::Spec::Functions;


use FindBin qw($RealBin $RealScript);
use lib "$RealBin/../../bin/";

our $DDR_DA_DISABLE_HEADER = 1; # to prevent header from getting printed
our $DDR_DA_DISABLE_FOOTER = 1; # to prevent footer from getting printed

ok( require( "$RealBin/../../bin/alphaPinCheck.pl"), 'loaded file okay') or exit;

sub TestMain(){
    my @haystack = ( "abc", "def", "hij" );
    my $needle   = "def";
    ok( 1==arrayContains( \@haystack, $needle), 'arrayContains Expecting 1');
    $needle = "xyz";
    ok( 0==arrayContains( \@haystack, $needle), 'arrayContains Expecting 0');
    ok( 0==arrayContains( \@haystack ), 'arrayContains Expecting 0');
    ok( 0==arrayContains( undef, $needle), 'arrayContains Expecting 0');
    exit 0;
}

&TestMain();


