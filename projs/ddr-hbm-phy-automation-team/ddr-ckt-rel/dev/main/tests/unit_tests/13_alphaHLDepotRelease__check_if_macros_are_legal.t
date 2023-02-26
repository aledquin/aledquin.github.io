###############################################################################
#
# Name    : 13_alphaHLDepotRelease__check_if_macros_are_legal.t
# Author  : Patrick Juliano
# Date    : Sept 14, 2022
# Purpose : description of the script.. can put on multiple lines
#
# Modification History
#     000 Patrick Juliano  Sept, 2022
#         Created this script
#     001 James Laderoute  Sept 16, 2022
#         Update Name comment
#     
###############################################################################
use strict;
use 5.14.2;
use warnings;
use Data::Dumper;
use Getopt::Long;
use File::Basename qw( dirname );
use File::Spec::Functions qw( catfile );
use FindBin qw( $RealBin $RealScript );
use Test2::Bundle::More;

use lib "$RealBin/../../lib/perl/";
use Util::CommonHeader;
use Util::Misc;
use Util::Messaging;
use alphaHLDepotRelease;
#--------------------------------------------------------------------#
#our $STDOUT_LOG  = undef;     # undef       : Log msg to var => OFF
our $STDOUT_LOG   = EMPTY_STR; # Empty String: Log msg to var => ON
our $DEBUG        = NONE;
our $VERBOSITY    = NONE;
our $PROGRAM_NAME = $RealScript;
our $FPRINT_NOEXIT = 1;
our $VERSION      = '2022.10'; # Syntax: YYYYww##[.#] optional day 1-7
                                # The work week number can be found in
                                # your outlook calendar. The days are 1=sunday
                                # 2=monday ... 7=saturday
#--------------------------------------------------------------------#

&Main();  # NOTE: this 'unless caller();' part is only required by used scripts

########  YOUR CODE goes in Main  ##############
sub Main() {

    my ( $opt_debug, $opt_verbosity ) =  complex_process_cmd_line_args();

    my %TopCells = (  
              'dwc_lpddr5xphy_ato_ew' => 1,
              'dwc_lpddr5xphy_ato_pll_ew' => 1,
              'dwc_lpddr5xphy_decapvaa_tile' => 1,
              'dwc_lpddr5xphy_lcdl' => 1,
              'dwc_lpddr5xphy_lstx_acx2_ew' => 1,
              'dwc_lpddr5xphy_lstx_csx2_ew' => 1,
              'dwc_lpddr5xphy_lstx_dx4_ew' => 1,
              'dwc_lpddr5xphy_lstx_dx5_ew' => 1,
              'dwc_lpddr5xphy_lstx_zcal_ew' => 1,
              'dwc_lpddr5xphy_pclk_master' => 1,
              'dwc_lpddr5xphy_pclk_rptx2' => 1,
              'dwc_lpddr5xphy_pclk_rxdca' => 1,
              'dwc_lpddr5xphy_por_ew' => 1,
              'dwc_lpddr5xphy_rxacvref_ew' => 1,
              'dwc_lpddr5xphy_rxdqs_tc_ew' => 1,
              'dwc_lpddr5xphy_techrevision' => 1,
              'dwc_lpddr5xphy_thermdiode' => 1,
              'dwc_lpddr5xphy_txrxac_ew' => 1,
              'dwc_lpddr5xphy_txrxcmos_ew' => 1,
              'dwc_lpddr5xphy_txrxcs_ew' => 1,
              'dwc_lpddr5xphy_txrxcs_tc_ew' => 1,
              'dwc_lpddr5xphy_txrxdq_ew' => 1,
              'dwc_lpddr5xphy_txrxdqs_ew' => 1,
              'dwc_lpddr5xphy_utility_blocks' => 1,
              'dwc_lpddr5xphy_utility_cells' => 1,
              'dwc_lpddr5xphy_vaaclamp_ew' => 1,
              'dwc_lpddr5xphy_vdd2hclamp_x2_ew' => 1,
              'dwc_lpddr5xphy_vddqclamp_dx4_ew' => 1,
              'dwc_lpddr5xphy_vddqclamp_dx5_ew' => 1,
              'dwc_lpddr5xphy_vddqclamp_x2_ew' => 1,
              'dwc_lpddr5xphy_zcalio_ew' => 1,
              'dwc_lpddr5xphycover_acx2_top_ew' => 2,
              'dwc_lpddr5xphycover_ckx2_top_ew' => 2,
              'dwc_lpddr5xphycover_cmosx2_top_ew' => 2,
              'dwc_lpddr5xphycover_csx2_top_ew' => 2,
              'dwc_lpddr5xphycover_dx4_top_ew' => 2,
              'dwc_lpddr5xphycover_dx5_top_ew' => 2,
              'dwc_lpddr5xphycover_master_top_ew' => 2,
              'dwc_lpddr5xphycover_zcal_top_ew' => 2
    );

    my %tests = ( 
        'test01' => '',
        'test02' => ' ',
        'test03' => 'dwc',
        'test04' => 'dwc_lpddr5xphy_lcdl',
        'test05' => 'dwc_lpddr5xphy_zcalio_ew  dwc_lpddr5xphy_lcdl',
    );
    my %expected = (
        'test01' => [],
        'test02' => [],
        'test03' => [],
        'test04' => ['dwc_lpddr5xphy_lcdl'],
        'test05' => ['dwc_lpddr5xphy_zcalio_ew', 'dwc_lpddr5xphy_lcdl'],
    );

    my @test_names_of_macros = ( '', ' ', 'dwc', 'dwc_lpddr5xphy_lcdl', 'dwc_lpddr5xphy_zcalio_ew  dwc_lpddr5xphy_lcdl' );

    ############    start testing    ####################
    ## ---- make sure you have ENV var DA_RUNNING_UNIT_TESTS=1 
    my $ntests = keys %tests;
    plan( $ntests);

    foreach my $key (sort keys( %tests )) {
        my $test_name = $tests{$key};
        dprint(HIGH, "-"x20 . " Testing macro '$test_name'.\n" );
        my @macro_returned = check_if_macros_are_legal( \%TopCells, $test_name );
        is_deeply( $expected{$key} , \@macro_returned ); #, "Test macro string '$test_name'...");
    }

    done_testing();

    exit 0;
} 
############    END Main    ####################

#------------------------------------------------------------------------------
sub complex_process_cmd_line_args(){
    my ( $config, $opt_debug, $opt_verbosity, $optHelp, $opt_nousage_stats );
    GetOptions(
        "debug=s"     => \$opt_debug,
        "verbosity=s" => \$opt_verbosity,
     );

   # VERBOSITY will be used to control the intensity level of 
   #     messages reported to the user while running.
   if( defined $opt_verbosity ){
      if( $opt_verbosity =~ m/^\d+$/ ){  
         $main::VERBOSITY = $opt_verbosity;
      }else{
         eprint( "Ignoring option '-v': arg must be an integer\n" );
      }
   }

   # decide whether to alter DEBUG variable
   # '--debug' indicates DEBUG value ... set based on user input
   # Patrick : modified in order to specify a value >0 but <1
   if( defined $opt_debug ){
      if( $opt_debug =~ m/^\d+\.*\d*$/ ){  
         $main::DEBUG = $opt_debug;
      }else{
         eprint( "Ignoring option '-d': arg must be an integer\n" );
      }
   }
   return( $opt_debug, $opt_verbosity );
};

__END__


