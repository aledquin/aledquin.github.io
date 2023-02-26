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

use lib "$RealBin/../lib";
use Util::CommonHeader;
use Util::Misc;
use Util::Messaging;
use Util::DS;
use Util::P4;

our $PROGRAM_NAME = $0;
our $AUTHOR_NAME  = 'Harsimrat Wadhawan';
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
    plan(7);
    #-------------------------------------------------------------------------
    #  Test 'append_arrays'
    #-------------------------------------------------------------------------
    setup_tests__da_p4_list_files();
    #-------------------------------------------------------------------------
    #
    done_testing();
    exit(0);
}
############    END Main    ####################

#-------------------------------------------------------------------------
#  Setup tests to exercise the insert_at_key subroutine
#-------------------------------------------------------------------------
sub setup_tests__da_p4_list_files() {
    my $subname = 'da_p4_files';    

    #-------------------------------------------------------------------------
    #  Test 'print_p4_file'
    #-------------------------------------------------------------------------
    my %test0 = (
        'string'   => "//openaccess-drops/lefdef/dev/5.8.3/def/*",
        'expect' => [
            "//openaccess-drops/lefdef/dev/5.8.3/def/LICENSE.PDF",
            "//openaccess-drops/lefdef/dev/5.8.3/def/LICENSE.TXT",
            "//openaccess-drops/lefdef/dev/5.8.3/def/Makefile",
            "//openaccess-drops/lefdef/dev/5.8.3/def/template.mk",
        ]
    );

    my %test1 = (
        'string'   => "//wwcad/msip/projects/golden_tb/*",
        'expect' => [
            "//wwcad/msip/projects/golden_tb/README_golden_tb_description.txt"
        ]
    );

    my %test2 = (
        'string'   => "//wwcad/msip/projects/displayport/r102-dptxphy-gf14lpp-18/rel1.00/lib/dptxphy_gold/mpll_out_clocks/schematic/*",
        'expect' => [
            "//wwcad/msip/projects/displayport/r102-dptxphy-gf14lpp-18/rel1.00/lib/dptxphy_gold/mpll_out_clocks/schematic/master.tag",
            "//wwcad/msip/projects/displayport/r102-dptxphy-gf14lpp-18/rel1.00/lib/dptxphy_gold/mpll_out_clocks/schematic/sch.oa",
            "//wwcad/msip/projects/displayport/r102-dptxphy-gf14lpp-18/rel1.00/lib/dptxphy_gold/mpll_out_clocks/schematic/snapshot.png",            
        ]
    );

    my %test3 = (
        'string'   => "//wwcad/msip/projects/dphy/g106-dphy-tsmc28hpm-18/rel6.11/int_deliveries/D01_IOPADS2DPT4W_9M_4X2Y2R_tsmc28hpm_g106_rel6.11_20151116_ABS/IOPADS2DPT4W/...",
        'expect' => [
            "//wwcad/msip/projects/dphy/g106-dphy-tsmc28hpm-18/rel6.11/int_deliveries/D01_IOPADS2DPT4W_9M_4X2Y2R_tsmc28hpm_g106_rel6.11_20151116_ABS/IOPADS2DPT4W/checksums.txt",
            "//wwcad/msip/projects/dphy/g106-dphy-tsmc28hpm-18/rel6.11/int_deliveries/D01_IOPADS2DPT4W_9M_4X2Y2R_tsmc28hpm_g106_rel6.11_20151116_ABS/IOPADS2DPT4W/design_lib/IOPADS2DPT4W/IOPADS2DPT4W/abstract/layout.oa",
            "//wwcad/msip/projects/dphy/g106-dphy-tsmc28hpm-18/rel6.11/int_deliveries/D01_IOPADS2DPT4W_9M_4X2Y2R_tsmc28hpm_g106_rel6.11_20151116_ABS/IOPADS2DPT4W/design_lib/IOPADS2DPT4W/IOPADS2DPT4W/abstract/master.tag",
            "//wwcad/msip/projects/dphy/g106-dphy-tsmc28hpm-18/rel6.11/int_deliveries/D01_IOPADS2DPT4W_9M_4X2Y2R_tsmc28hpm_g106_rel6.11_20151116_ABS/IOPADS2DPT4W/design_lib/IOPADS2DPT4W/IOPADS2DPT4W/symbol/master.tag",
            "//wwcad/msip/projects/dphy/g106-dphy-tsmc28hpm-18/rel6.11/int_deliveries/D01_IOPADS2DPT4W_9M_4X2Y2R_tsmc28hpm_g106_rel6.11_20151116_ABS/IOPADS2DPT4W/design_lib/IOPADS2DPT4W/IOPADS2DPT4W/symbol/symbol.oa"          
        ]
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

    my @tests_nullval = (\%test0, \%test1, \%test2, \%test3, \%test4, \%test5, \%test6);
    foreach my $cnt (@tests_nullval) {
        my %testcase = %{$cnt};
        my @out      = da_p4_files( $testcase{string} );        
        is_deeply (\@out, $testcase{expect}, $subname);
    }  
}

1;

