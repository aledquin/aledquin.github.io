use strict;
use warnings;
use 5.14.2;

use Test2::Bundle::More;
use File::Temp;

use FindBin qw($RealBin $RealScript);

use lib "$RealBin/../../lib/perl/";
use alphaHLDepotRelease;
use Util::CommonHeader;
use Util::Messaging;

our $DEBUG = NONE;
our $VERBOSITY = NONE;


sub Main() {
    plan(14);
  
    # Both good stacks
    my $first  = "7M_abc"; 
    my $second = "3M_def"; 
    my $value  = arrangeStacks( $first, $second );
    ok( $value ne "ERROR!", "arrangeStacks '$first' vs '$second'");

    # Both bad stacks
    $first  = "o7M"; 
    $second = "o3M"; 
    $value  = arrangeStacks( $first, $second );
    ok( $value eq "ERROR!", "arrangeStacks '$first' vs '$second'");
 
    # Both bad stacks
    $first  = ""; 
    $second = ""; 
    $value  = arrangeStacks( $first, $second );
    ok( $value eq "ERROR!", "arrangeStacks '$first' vs '$second'");
 
    # One bad stack
    $first  = " "; 
    $second = "3M_def"; 
    $value  = arrangeStacks( $first, $second );
    ok( $value eq "ERROR!", "arrangeStacks '$first' vs '$second'");
 
    # One bad stack
    $first  = "3M_def"; 
    $second = " "; 
    $value  = arrangeStacks( $first, $second );
    ok( $value eq "ERROR!", "arrangeStacks '$first' vs '$second'");

    # Same stacks
    $first  = "3M_DEF"; 
    $second = "3M_def"; 
    $value  = arrangeStacks( $first, $second );
    ok( $value eq "ERROR!", "arrangeStacks '$first' vs '$second'");

    # Small, big
    $first  = "3M_def"; 
    $second = "6M_abc"; 
    my ($value1, $value2)  = arrangeStacks( $first, $second );
    my ($expected, $expected2) = ($first,$second);
    is_deeply(($value1), ($expected) , "arrangeStacks '$first' vs '$second'");
    is_deeply(($value2), ($expected2) , "arrangeStacks '$first' vs '$second'");

    # Big, small
    $first  = "6M_def"; 
    $second = "3M_abc"; 
    ($value1, $value2)  = arrangeStacks( $first, $second );
    ($expected, $expected2) = ($second,$first);
    is_deeply(($value1), ($expected) , "arrangeStacks '$first' vs '$second'");
    is_deeply(($value2), ($expected2) , "arrangeStacks '$first' vs '$second'");

    # Integral data
    $first  = 34; 
    $second = 35; 
    $value  = arrangeStacks( $first, $second );
    ok( $value eq "ERROR!", "arrangeStacks '$first' vs '$second'");

    # Very large stacks
    $first  = "12345678M_def"; 
    $second = "12345M_def"; 
    ($value1, $value2)  = arrangeStacks( $first, $second );
    ($expected, $expected2) = ($second,$first);
    is_deeply(($value1), ($expected) , "arrangeStacks '$first' vs '$second'");
    is_deeply(($value2), ($expected2) , "arrangeStacks '$first' vs '$second'");

    # Real number stacks
    $first  = "1.2345678M_def"; 
    $second = "1.2345M_def"; 
    $value  = arrangeStacks( $first, $second );
    ok( $value eq "ERROR!", "arrangeStacks '$first' vs '$second'");
    
    done_testing();

    return 0;
}

Main();

