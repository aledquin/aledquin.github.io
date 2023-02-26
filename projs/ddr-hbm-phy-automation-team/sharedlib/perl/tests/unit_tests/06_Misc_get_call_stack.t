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
    my @expected = ( "Main",
                     "Main -> sub_routine",
                     "Main -> deep_nested -> deep1 -> deep2",
                     "Main -> nested -> nested1 -> nested2 -> control_depth",
                     "Main -> nested -> nested1 -> nested2",
                     "Main -> nested -> nested1",
                     "Main -> nested",
                     "Main",
                   );
    plan(8);

    my $return = get_call_stack();
    ok( $return eq $expected[0] , "get_call_stack" );

    sub_routine( $expected[1] );
    deep_nested( $expected[2] );
    nested( $expected[3], 0 );
    nested( $expected[4], 1 );
    nested( $expected[5], 2 );
    nested( $expected[6], 3 );
    nested( $expected[7], 4 );

    done_testing( );

    return(1); 
}

#--------------------------------------------------------------------
sub nested($$){
    nested1(shift, shift);
}
sub nested1($$){
    nested2(shift, shift);
}
sub nested2($$){
    control_depth(shift, shift);
}
sub control_depth($$){
    my $expected = shift;
    my $frame    = shift;

    my $return = get_call_stack($frame);
    #print "\$return=$return\n";
    is_deeply( $return , $expected, "get_call_stack" );
}
#--------------------------------------------------------------------


#--------------------------------------------------------------------
sub less_deep_nested_1($){
    deep3(shift,1);
}

sub deep3($){
    my $expected = shift;
    my $return = get_call_stack(0);
    ok( $return eq $expected , "get_call_stack" );
}
#--------------------------------------------------------------------


#--------------------------------------------------------------------
sub deep_nested($){
    deep1(shift);
}
sub deep1($){
    deep2(shift);
}

sub deep2($){
    my $expected = shift;
    my $return = get_call_stack();
    ok( $return eq $expected , "get_call_stack" );
}

sub sub_routine($) {
    my $expected = shift;
    my $return = get_call_stack();
    ok( $return eq $expected , "get_call_stack" );
}
Main();

#--------------------------------------------------------------------
