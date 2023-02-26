#!/depot/perl-5.14.2/bin/perl
use strict;
use warnings;
use Getopt::Std;
use Test2::Bundle::More;

use FindBin qw($RealBin $RealScript);

use lib "$RealBin/../lib";
use Util::CommonHeader;
use Util::Misc;

our $PROGRAM_NAME = $0;
our $AUTHOR_NAME  = 'Haashim Shahzada, ljames';
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
    plan(8);
    #-------------------------------------------------------------------------
    #  Test 'append_arrays'
    #-------------------------------------------------------------------------
    setup_tests__da_findSubdirs();
    #-------------------------------------------------------------------------
    #
    done_testing();
    exit(0);
}
############    END Main    ####################

#-------------------------------------------------------------------------
#  Setup tests to exercise the insert_at_key subroutine
#-------------------------------------------------------------------------
sub setup_tests__da_findSubdirs() {
    my $subname = 'da_findSubdirs';    

    #-------------------------------------------------------------------------
    #  Test 'da_findSubdirs'
    #-------------------------------------------------------------------------
    my %test0 = (
        'string'   => "$RealBin/../data/pinchecktest/metalstacks",
        'expect' => ["13M_1X_h_1Xb_v_1Xe_h_1Ya_v_1Yb_h_5Y_vhvhv_2Z", 
                     "15M_1X_h_1Xb_v_1Xe_h_1Ya_v_1Yb_h_5Y_vhvhv_2Yy2R",
                     "15M_1X_h_1Xb_v_1Xe_h_1Ya_v_1Yb_h_5Y_vhvhv_2Yy2Z", 
                     "16M_1X_h_1Xb_v_1Xe_h_1Ya_v_1Yb_h_4Y_vhvh_2Yy2Yx2R"]
    );

    my %test1 = (
        'string'   => "$RealBin/../data/pinchecktest/macrofolders",
        'expect' => ["gds", "icv", "interface", "lef", "netlist", "pincheck", "pininfo"]
    );

    my %test2 = (
        'string'   => "//depot/products/lpddr5x_ddr5_phy/lp5x/project/d932-lpddr5x-tsmc4ffp-12/ckt/rel/dwc_lpddr5xphy_pclk_master/1.00a/macro/...",
        'expect' => [NULL_VAL]
    );

    my %test3 = (
        'string'   => "//depot/products/lpddr5x_ddr5_phy/lp5x/project/d933-lpddr5x-tsmc5ff-12/ckt/rel/dwc_lpddr5xphy_pclk_master/1.00a/macro/...",
        'expect' => [NULL_VAL]
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

    my @tests_nullval = (\%test0, \%test1, \%test2, \%test3, \%test4, \%test5, \%test6, \%test7);
    foreach my $cnt (@tests_nullval) {

        my %testcase = %{$cnt};
        my @out      = da_findSubdirs( $testcase{string} );        
        is_deeply (\@out, $testcase{expect}, $subname);

    }  

}

1;
