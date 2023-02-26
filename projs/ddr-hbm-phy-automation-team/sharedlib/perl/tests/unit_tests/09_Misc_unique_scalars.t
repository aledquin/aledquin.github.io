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
    my @empty = ();
    my @expected = qw( one two three  );
    my @testarray = qw( one two three two one two three );
    my @test2array = ( 'one', 'two' );
    my @expected2  = ( 'one', 'two', 'three');
    my %myhash = ( 'one'=>1, 'three'=>3 );
    my @myarray = ( 1, 2, 3);

    plan(7);
   
    my @return = unique_scalars( \@testarray );
    is( \@return, \@expected );

    @return = unique_scalars( 32 );
    is( \@return, \@empty);

    @return = unique_scalars( \%myhash );
    is( \@return, \@empty);

    my $stdout;

    push( @test2array, \%myhash);
    push( @test2array, 'three');
    ($stdout, @return ) = capture_stdout { unique_scalars( \@test2array ) };
    ok( $stdout =~ m/Expected SCALAR where HASH was found/, 'unique_scalars' ); 

    is( \@return, \@expected2 );

    @test2array = ( 'one', 'two' );
    push( @test2array, \@myarray);
    push( @test2array, 'three');
    my @ordered_list;
    ($stdout, @ordered_list) = capture_stdout { 
        &unique_scalars( \@test2array )
    };

    ok( $stdout =~ m/Expected SCALAR where ARRAY was found/, 'unique_scalars' ); 
    is( \@ordered_list, \@expected2 );

    done_testing( );

    return(1); 
}

Main();

