#!/depot/perl-5.14.2/bin/perl -w
use strict;
use warnings;
use Getopt::Std;
use Data::Dumper;
use FindBin qw($RealBin $RealScript);
use File::Spec::Functions qw( catfile );
use Cwd qw( abs_path );
use Carp qw(cluck confess croak);
#use Test2::Tools::Compare;
use Test2::Bundle::More;

use lib "$RealBin/../../lib/perl/";
use Util::CommonHeader;
use Util::Misc;
use Util::Messaging;
use Util::DS;
use Util::P4;

use alphaHLDepotRelease;

our $PROGRAM_NAME = $0;
our $AUTHOR_NAME  = 'Haashim Shahzada';
#----------------------------------#
our $DEBUG     = NONE;
our $VERBOSITY = NONE;
our $DEBUG_LOG = undef;
#----------------------------------#


Main();

########  YOUR CODE goes in Main  ##############
sub Main {
    utils__process_cmd_line_args();
    # Current planned test count
    plan(11);
    #-------------------------------------------------------------------------
    #  Test 'append_arrays'
    #-------------------------------------------------------------------------
    setup_tests__checkPinCheckExist();
    #-------------------------------------------------------------------------
    #
    done_testing();
    exit(0);
}
############    END Main    ####################

#-------------------------------------------------------------------------
#  Setup tests to exercise the insert_at_key subroutine
#-------------------------------------------------------------------------
sub setup_tests__checkPinCheckExist() {
    my $subname = 'checkPinCheckExist';    

    #-------------------------------------------------------------------------
    #  Test 'checkPinCheckExist'
    #-------------------------------------------------------------------------
    my %test0 = (
        'string'   => "//depot/products/training/project/t125-training-tsmc7ff-1.8v/ckt/rel/dwc_ddrphy_utility_cells/1.00a/macro/...",
        'expect' => ["1"]
    );

    my %test1 = (
        'string'   => "//depot/products/training/project/t125-training-tsmc7ff-1.8v/ckt/rel/dwc_ddrphy_txrxdqs_ew/1.00a/macro/...",
        'expect' => ["0"]
    );

    my %test2 = (
        'string'   => "//depot/products/lpddr5x_ddr5_phy/lp5x/project/d932-lpddr5x-tsmc4ffp-12/ckt/rel/dwc_lpddr5xphy_pclk_master/1.00a/macro/...",
        'expect' => ["0"]
    );

    my %test3 = (
        'string'   => "//depot/products/lpddr5x_ddr5_phy/lp5x/project/d933-lpddr5x-tsmc5ff-12/ckt/rel/dwc_lpddr5xphy_pclk_master/1.00a/macro/...",
        'expect' => ["0"]
    );
    
    my %test4 = (
        'string'   => "//wwcad/msip/projects/alpha/alpha_common/bin/beta/lib/Util/ABCXYZ/...",       
        'expect' => [NULL_VAL]
    );

    my %test5 = (
        'string'   => "//wwcad/msip/projects/alpha/alpha_common/bin/beta/lib/ASD.",       
        'expect' => [NULL_VAL]
    );

    my %test6 = (
        'string'   => "//wwcad/msip/projects/alpha/alpha_common/bin/beta/lib/ASDFGHIJKLMN/*",       
        'expect' => [NULL_VAL]
    );

    my %test7 = (       
        'expect' => [NULL_VAL]
    );

    my %test8 = (
        'string'   => "haashim",       
        'expect' => [NULL_VAL]
    );

    my %test9 = (
        'string'   => -1,       
        'expect' => [NULL_VAL]
    );

    my %test10 = (
        'string'   => -1,       
        'expect' => [NULL_VAL]
    );


    my @tests_nullval = (\%test0, \%test1, \%test2, \%test3, \%test4, \%test5, \%test6, \%test7, \%test8, \%test9, \%test10);
    foreach my $cnt (@tests_nullval) {

        my %testcase = %{$cnt};
        my @out      = &checkPinCheckExist( $testcase{string} );        
        is_deeply (\@out, $testcase{expect}, $subname);

    }  

}

1;
