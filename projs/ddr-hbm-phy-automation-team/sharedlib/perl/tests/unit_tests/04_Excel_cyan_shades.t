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

    ok(cyan_shades(1,100)   eq " 7797F", 'Cyan Shade 1/100');
    ok(cyan_shades(25,100)  eq "35989D", 'Cyan Shade 25/100');
    ok(cyan_shades(50,100)  eq "66B8BC", 'Cyan Shade 50/100');
    ok(cyan_shades(75,100)  eq "97D9DC", 'Cyan Shade 75/100');
    ok(cyan_shades(100,100) eq "C8FAFB", 'Cyan Shade 100/100');
    ok(cyan_shades(0,100)   eq "000000", 'Cyan Shade 0/100');
    ok(cyan_shades(101,100) eq "000000", 'Cyan Shade 101/100');
    ok(cyan_shades(1,0)     eq "000000", 'Cyan Shade 1/0');

    done_testing();
}

Main();

