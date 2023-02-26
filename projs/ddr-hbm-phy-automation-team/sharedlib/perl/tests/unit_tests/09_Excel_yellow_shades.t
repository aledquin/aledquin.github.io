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

    ok(yellow_shades(1,100)   eq "FFFF 0", 'Yellow Shade 1/100');
    ok(yellow_shades(25,100)  eq "F8F730", 'Yellow Shade 25/100');
    ok(yellow_shades(50,100)  eq "F0EF62", 'Yellow Shade 50/100');
    ok(yellow_shades(75,100)  eq "E8E795", 'Yellow Shade 75/100');
    ok(yellow_shades(100,100) eq "DFDEC8", 'Yellow Shade 100/100');
    ok(yellow_shades(0,100)   eq "000000", 'Yellow Shade 0/100');
    ok(yellow_shades(101,100) eq "000000", 'Yellow Shade 101/100');
    ok(yellow_shades(1,0)     eq "000000", 'Yellow Shade 1/0');

    done_testing();
}

Main();

