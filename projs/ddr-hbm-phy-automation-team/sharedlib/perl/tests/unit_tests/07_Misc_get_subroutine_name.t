use strict;
use warnings;
use v5.14.2;

use Test2::Bundle::More;
use File::Temp;

use FindBin qw($RealBin $RealScript);

use lib "$RealBin/../lib";
use Util::CommonHeader;
use Util::Misc;

our $DEBUG      = 0;
our $VERBOSITY  = 0;
our $STDOUT_LOG = undef; 

our $DA_RUNNING_UNIT_TESTS = 1;
our $FPRINT_NOEXIT = 1;

sub Main() {
    my @expected = ( "Main", "sub_routine", "deep2");
    plan(3);

    my $return = get_subroutine_name();
    ok( $return eq $expected[0] , "get_subroutine_name" );

    sub_routine( $expected[1] );
    deep_nested( $expected[2] );

    done_testing( );

    return(1); 
}

sub deep_nested($){
    deep1(shift);
}
sub deep1($){
    deep2(shift);
}
sub deep2($){
    my $expected = shift;
    my $return = get_subroutine_name();
    ok( $return eq $expected , "get_subroutine_name" );
}

sub sub_routine($) {
    my $expected = shift;
    my $return = get_subroutine_name();
    ok( $return eq $expected , "get_subroutine_name" );
}
Main();

