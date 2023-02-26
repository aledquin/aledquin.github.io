use strict;
use warnings;
use v5.14.2;

use Capture::Tiny ':all';
use Test2::Bundle::More;
use Test2::Tools::Compare;
use File::Temp;
use Term::ANSIColor;
$Term::ANSIColor::EACHLINE = "\n";  # Resets the color after each newline...
use FindBin qw($RealBin $RealScript);
use lib "$RealBin/../lib";
use Util::CommonHeader;
use Util::P4;
#use Util::Misc;

our $STDOUT_LOG = undef;
our $DEBUG      = NONE;
our $VERBOSITY  = NONE;
our $VERSION    = '2022.11';

sub Main() {
    my %tests =( 
        'test1' => {'input' => "", 
                      'expected' => FALSE,
                   },
        'test2' => {'input' => "$RealBin/../data/da_p4_is_in_perforce_test.txt",
                      'expected' => FALSE,
                   },
        'test3' => {'input' => "//depot/products/lpddr5x_ddr5_phy/lp5x/common/qms/templates/HSPICE_IBIS_list/LPDDR5X_HSPICE_list.txt",
                      'expected' => TRUE,
                   },
        'test4' => {'input' => "//depot/products/lpddr5x_ddr5_phy/lp5x/common/qms/templates/HSPICE_IBIS_list/nosuchfile.txt",
                      'expected' => FALSE,
                   },
    );

    my $nplans = keys(%tests);
    plan($nplans);

    foreach my $key ( sort keys( %tests ) ){
        my $href_t   = $tests{"$key"};
        my $input    = $href_t->{'input'};
        my $expected = $href_t->{'expected'};
        my $got      = da_p4_is_in_perforce( $input );
        ok( $expected == da_p4_is_in_perforce( $input ) , "'da_p4_is_in_perforce':$key expected='$expected', got='$got', input='$input' ");
    }

    done_testing( );

    return(0); 
}


Main();

