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

    ok(gold_shades(1,100)   eq "FFE181", 'Gold Shade 1/100');
    ok(gold_shades(25,100)  eq "F2D062", 'Gold Shade 25/100');
    ok(gold_shades(50,100)  eq "E4BD42", 'Gold Shade 50/100');
    ok(gold_shades(75,100)  eq "D6AB21", 'Gold Shade 75/100');
    ok(gold_shades(100,100) eq "C898 0", 'Gold Shade 100/100');
    ok(gold_shades(0,100)   eq "000000", 'Gold Shade 0/100');
    ok(gold_shades(101,100) eq "000000", 'Gold Shade 101/100');
    ok(gold_shades(1,0)     eq "000000", 'Gold Shade 1/0');

    done_testing();
}

Main();

