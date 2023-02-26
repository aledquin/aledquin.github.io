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
    plan(7);

    my @arrvar = (1,2);
    my %hashvar = ( 'a'=>3 );
    my $scalarvar = 10;

    ok( FALSE == isa_href( @arrvar)    ,  "Testing isa_href");
    ok( FALSE == isa_href( \@arrvar)   ,  "Testing isa_href");
    ok( FALSE == isa_href( %hashvar )  ,  "Testing isa_href");
    ok( TRUE  == isa_href( \%hashvar ) ,  "Testing isa_href");
    ok( FALSE == isa_href( $scalarvar) ,  "Testing isa_href");
    ok( FALSE == isa_href( \$scalarvar), "Testing isa_href");
    ok( FALSE == isa_href( undef)      , "Testing isa_href"); 

    done_testing( );
    return(1); 
}

Main();

