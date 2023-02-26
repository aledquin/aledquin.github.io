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

    ok(purple_shades(1,100)   eq "8D4DB3", 'Purple Shade 1/100');
    ok(purple_shades(25,100)  eq "A070C2", 'Purple Shade 25/100');
    ok(purple_shades(50,100)  eq "B594D1", 'Purple Shade 50/100');
    ok(purple_shades(75,100)  eq "CAB9E1", 'Purple Shade 75/100');
    ok(purple_shades(100,100) eq "DFDEF1", 'Purple Shade 100/100');
    ok(purple_shades(0,100)   eq "000000", 'Purple Shade 0/100');
    ok(purple_shades(101,100) eq "000000", 'Purple Shade 101/100');
    ok(purple_shades(1,0)     eq "000000", 'Purple Shade 1/0');

    done_testing();
}

Main();

