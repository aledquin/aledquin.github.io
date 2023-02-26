use strict;
use warnings;
use 5.14.2;

use Test2::Bundle::More;
use File::Temp;

use FindBin qw($RealBin $RealScript);

use lib "$RealBin/../lib";
use Util::Excel;

our $DEBUG      = 0;
our $VERBOSITY  = 0;
our $STDOUT_LOG = undef; 

sub Main() {

    plan(8);

    ok(blue_shades(1,100)   eq "577AC1", 'Blue Shade 1/100');
    ok(blue_shades(25,100)  eq "7B96CE", 'Blue Shade 25/100');
    ok(blue_shades(50,100)  eq "A0B4DC", 'Blue Shade 50/100');
    ok(blue_shades(75,100)  eq "C6D2EA", 'Blue Shade 75/100');
    ok(blue_shades(100,100) eq "ECEFF8", 'Blue Shade 100/100');
    ok(blue_shades(0,100)   eq "000000", 'Blue Shade 0/100');
    ok(blue_shades(101,100) eq "000000", 'Blue Shade 101/100');
    ok(blue_shades(1,0)     eq "000000", 'Blue Shade 1/0');

    done_testing();
}

Main();

