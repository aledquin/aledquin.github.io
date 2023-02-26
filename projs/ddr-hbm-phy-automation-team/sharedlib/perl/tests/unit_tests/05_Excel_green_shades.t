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

    ok(green_shades(1,100)   eq " 0E1 0", 'Green Shade 1/100');
    ok(green_shades(25,100)  eq "30E130", 'Green Shade 25/100');
    ok(green_shades(50,100)  eq "62E162", 'Green Shade 50/100');
    ok(green_shades(75,100)  eq "95E195", 'Green Shade 75/100');
    ok(green_shades(100,100) eq "C8E1C8", 'Green Shade 100/100');
    ok(green_shades(0,100)   eq "000000", 'Green Shade 0/100');
    ok(green_shades(101,100) eq "000000", 'Green Shade 101/100');
    ok(green_shades(1,0)     eq "000000", 'Green Shade 1/0');

    done_testing();
}

Main();

