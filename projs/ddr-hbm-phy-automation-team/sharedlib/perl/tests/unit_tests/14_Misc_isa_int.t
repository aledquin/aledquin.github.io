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

sub Main() {
    plan(11);

    my @arrvar = (1,2);
    my %hashvar = ( 'a'=>3 );
    my $scalarvar = 10;
    my $floatvar = 23.32;
    my $stringvar = "Testing String";

    ok( TRUE  == isa_int( @arrvar)    , "Testing isa_int with array");
    ok( FALSE == isa_int( \@arrvar)   , "Testing isa_int with ref array");
    ok( FALSE == isa_int( %hashvar )  , "Testing isa_int with hash");
    ok( FALSE == isa_int( \%hashvar ) , "Testing isa_int with ref hash");
    ok( FALSE == isa_int( $floatvar)  , "Testing isa_int with float");
    ok( FALSE == isa_int( \$floatvar) , "Testing isa_int with ref float");
    ok( TRUE  == isa_int( $scalarvar) , "Testing isa_int with int");
    ok( FALSE == isa_int( \$scalarvar), "Testing isa_int with ref int");
    ok( FALSE == isa_int( undef)      , "Testing isa_int with undef"); 
    ok( FALSE == isa_int( $stringvar) , "Testing isa_int with string"); 
    ok( FALSE == isa_int( \$stringvar), "Testing isa_int with ref string"); 

    done_testing( );
    return(1); 
}

Main();

