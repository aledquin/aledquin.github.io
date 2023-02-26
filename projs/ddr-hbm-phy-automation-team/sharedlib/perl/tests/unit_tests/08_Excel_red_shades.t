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

    ok(red_shades(1,100)   eq "FF 0 0", 'Red Shade 1/100');
    ok(red_shades(25,100)  eq "F83030", 'Red Shade 25/100');
    ok(red_shades(50,100)  eq "F16262", 'Red Shade 50/100');
    ok(red_shades(75,100)  eq "E99595", 'Red Shade 75/100');
    ok(red_shades(100,100) eq "E1C8C8", 'Red Shade 100/100');
    ok(red_shades(0,100)   eq "000000", 'Red Shade 0/100');
    ok(red_shades(101,100) eq "000000", 'Red Shade 101/100');
    ok(red_shades(1,0)     eq "000000", 'Red Shade 1/0');

    done_testing();
}

Main();

