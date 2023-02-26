use strict;
use warnings;
use v5.14.2;

use Capture::Tiny ':all';
use Test2::Bundle::More;
use Test2::Tools::Compare;
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
    my @testarray1 = ( 1, 2, 3);
    my @testarray2 = (4, 5, 6, 1);
    my @expected   = (1, 2, 3, 4, 5, 6, 1);
    my @expected2  = (1, 2, 3, 'one', 'james' );
    my %testhash   = ( 'one' => 'james' );
    my @testarray3 = (1, 2, \%testhash, 3);
    my @expected3  = (1, 2, 3, 1, 2, 3);
    my $stdout;

    plan(5);
   
    my $aref_combined = append_arrays( 1, 2, 3, 4, 5, 6, 1);
    is( $aref_combined, \@expected );

    $aref_combined = append_arrays( @testarray1, @testarray2 );
    is( $aref_combined, \@expected );

    $aref_combined = append_arrays( @testarray1, %testhash);
    is( $aref_combined, \@expected2 );

    ($stdout, $aref_combined ) = capture_stdout {
        &append_arrays( @testarray1, @testarray3);
    };
    ok( $stdout =~ m/attempt made to append HASH to ARRAY/, 'append_array');
    is( $aref_combined, \@expected3 );

    done_testing( );

    return(1); 
}

Main();

