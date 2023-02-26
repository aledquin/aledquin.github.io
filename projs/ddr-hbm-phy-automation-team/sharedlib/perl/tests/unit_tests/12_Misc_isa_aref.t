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
    plan(6);

    my @arrvar = (1,2);
    my %hashvar = ( 'a'=>3 );
    my $scalarvar = 10;

    ok( FALSE == isa_aref( @arrvar)   ,  "Testing isa_aref");
    ok( TRUE  == isa_aref( \@arrvar)  ,  "Testing isa_aref");
    ok( FALSE == isa_aref( %hashvar ) ,  "Testing isa_aref");
    ok( FALSE == isa_aref( \%hashvar ),  "Testing isa_aref");
    ok( FALSE == isa_aref( $scalarvar),  "Testing isa_aref");
    ok( FALSE == isa_aref( \$scalarvar), "Testing isa_aref");
    
    done_testing( );
    return(1); 
}

Main();

