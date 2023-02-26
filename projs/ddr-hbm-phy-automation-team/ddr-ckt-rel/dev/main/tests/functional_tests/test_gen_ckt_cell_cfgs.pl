#!/depot/perl-5.14.2/bin/perl -w

use strict;
use warnings;
use Data::Dumper;
use File::Basename qw( dirname );
use File::Spec::Functions qw( catfile );
use Cwd qw( abs_path );
use Carp qw(cluck confess croak);
use FindBin qw( $RealBin $RealScript );
#use Test2::Tools::Compare;
use Test2::Bundle::More;

use lib "$RealBin/../../lib/perl/";
use Util::CommonHeader;
use Util::Misc;
use Util::Messaging;
use GenCFG qw( extract_list_of_macros );

our $PROGRAM_NAME = $0; 
our $AUTHOR_NAME  = 'Patrick Juliano';
#----------------------------------#
my $REGEX_MACROS = '^\[(?:SCH|LAY)\]\S+/(\S+)/(?:schematic|layout)';
my $REGEX_REFS   = '^\[(REF.*)\]\[(?:SCH|LAY)\]\S+/(\S+)/(?:schematic|layout)';
my $REGEX_PROJ   = '^\[(REF[0-9]+)\]([a-z].*)';
our $DEBUG = NONE;
our $VERBOSITY = NONE;
my $DDR_DA_DEFAULT_P4WS = "p4_func_tests";
#----------------------------------#


BEGIN { header(); } 
   Main();
END { footer();}

########  YOUR CODE goes in Main  ##############
sub Main {

   my $workspace = $ENV{'DDR_DA_DEFAULT_P4WS'} || $DDR_DA_DEFAULT_P4WS;

   utils__process_cmd_line_args();

   # Current planned test count
   plan(4);
   #-------------------------------------------------------------------------
   #  Test 'append_arrays'
   #-------------------------------------------------------------------------
     setup_tests__extract_list_of_macros();
   #-------------------------------------------------------------------------
   #
   if ( 0) {
       utils__script_usage_statistics( "test", "noversion" ); # satisfy plint
   }

   done_testing();
   exit(0);
}
############    END Main    ####################
 
#-------------------------------------------------------------------------
#  Setup tests to exercise the append array subroutine
#-------------------------------------------------------------------------
sub setup_tests__extract_list_of_macros(){
      #-------------------------------------------------------------------------
      #  Test 'append_arrays'
      #-------------------------------------------------------------------------
      my %tests = get_top_cells_examples();
      foreach my $cnt ( sort { $a <=> $b } keys %tests ){
         my ($aref_bad_lines, %components_computed) =  
            extract_list_of_macros( $tests{$cnt}{'sample'} , 
                $REGEX_MACROS, $REGEX_PROJ, $REGEX_REFS );
         is_deeply( \%components_computed, $tests{$cnt}{expected} ,  
             "Testing Subroutine 'extract_list_of_macros' : test$cnt"    );
         dprint(SUPER, "computed: " . pretty_print_href( \%components_computed ) . "\n" );
         dprint(SUPER, "expected: " . pretty_print_href( $tests{$cnt}{expected}  ) . "\n"   );
      } 
      #-------------------------------------------------------------------------
}
 
sub get_top_cells_examples(){

# lpddr54/d850-lpddr54-tsmc5ffp12/rel2.00_cktpcs
my $ex1 = <<EOF;
//wwcad/msip/projects/lpddr54/d850-lpddr54-tsmc5ffp12/rel2.00_cktpcs/pcs/design/topcells.txt#5 - edit change 6352343 (text+x)
###NS
#[LAY]dwc_ddrphy_se_io/dwc_ddrphy_se_io_ns/layout
#[SCH]dwc_ddrphy_se_io/dwc_ddrphy_se_io_ns/schematic
##
#[LAY]dwc_ddrphy_diff_io/dwc_ddrphy_diff_io_ns/layout
#[SCH]dwc_ddrphy_diff_io/dwc_ddrphy_diff_io_ns/schematic
##
#[LAY]dwc_ddrphy_sec_io/dwc_ddrphy_sec_io_ns/layout
#[SCH]dwc_ddrphy_sec_io/dwc_ddrphy_sec_io_ns/schematic
##
#[LAY]dwc_ddrphy_clktree/dwc_ddrphy_pclk_master_ns/layout
#[SCH]dwc_ddrphy_clktree/dwc_ddrphy_pclk_master_ns/schematic
##
#[LAY]dwc_ddrphy_clktree/dwc_ddrphy_pclk_rx_ns/layout
#[SCH]dwc_ddrphy_clktree/dwc_ddrphy_pclk_rx_ns/schematic
##
#[LAY]dwc_ddrphy_zcalana/dwc_ddrphy_zcalana_ns/layout
#[SCH]dwc_ddrphy_zcalana/dwc_ddrphy_zcalana_ns/schematic
##
#[LAY]dwc_ddrphy_por/dwc_ddrphy_por_ns/layout
#[SCH]dwc_ddrphy_por/dwc_ddrphy_por_ns/schematic
##
#[LAY]dwc_ddrphy_vrefdacref/dwc_ddrphy_vrefdacref_ns/layout
#[SCH]dwc_ddrphy_vrefdacref/dwc_ddrphy_vrefdacref_ns/schematic
##
#[LAY]dwc_ddrphy_rxreplica/dwc_ddrphy_rxreplica_ns/layout
#[SCH]dwc_ddrphy_rxreplica/dwc_ddrphy_rxreplica_ns/schematic
##
#[LAY]dwc_ddrphy_ddl/dwc_ddrphy_lcdl_ns/layout
#[SCH]dwc_ddrphy_ddl/dwc_ddrphy_lcdl_ns/schematic
##
#[LAY]dwc_ddrphy_techrevision/dwc_ddrphy_techrevision_ns/layout
#[SCH]dwc_ddrphy_techrevision/dwc_ddrphy_techrevision_ns/schematic
####EW
[LAY]dwc_ddrphy_se_io/dwc_ddrphy_se_io_ew/layout
[SCH]dwc_ddrphy_se_io/dwc_ddrphy_se_io_ew/schematic
#
[LAY]dwc_ddrphy_diff_io/dwc_ddrphy_diff_io_ew/layout
[SCH]dwc_ddrphy_diff_io/dwc_ddrphy_diff_io_ew/schematic
#
[LAY]dwc_ddrphy_sec_io/dwc_ddrphy_sec_io_ew/layout
[SCH]dwc_ddrphy_sec_io/dwc_ddrphy_sec_io_ew/schematic
#
[LAY]dwc_ddrphy_clktree/dwc_ddrphy_pclk_master_ew/layout
[SCH]dwc_ddrphy_clktree/dwc_ddrphy_pclk_master_ew/schematic
#
[LAY]dwc_ddrphy_clktree/dwc_ddrphy_pclk_rx_ew/layout
[SCH]dwc_ddrphy_clktree/dwc_ddrphy_pclk_rx_ew/schematic
#
[LAY]dwc_ddrphy_zcalana/dwc_ddrphy_zcalana_ew/layout
[SCH]dwc_ddrphy_zcalana/dwc_ddrphy_zcalana_ew/schematic
#
[LAY]dwc_ddrphy_por/dwc_ddrphy_por_ew/layout
[SCH]dwc_ddrphy_por/dwc_ddrphy_por_ew/schematic
#
[LAY]dwc_ddrphy_vrefdacref/dwc_ddrphy_vrefdacref_ew/layout
[SCH]dwc_ddrphy_vrefdacref/dwc_ddrphy_vrefdacref_ew/schematic
#
[LAY]dwc_ddrphy_rxreplica/dwc_ddrphy_rxreplica_ew/layout
[SCH]dwc_ddrphy_rxreplica/dwc_ddrphy_rxreplica_ew/schematic
#
[LAY]dwc_ddrphy_ddl/dwc_ddrphy_lcdl_ew/layout
[SCH]dwc_ddrphy_ddl/dwc_ddrphy_lcdl_ew/schematic
#
[LAY]dwc_ddrphy_techrevision/dwc_ddrphy_techrevision_ew/layout
[SCH]dwc_ddrphy_techrevision/dwc_ddrphy_techrevision_ew/schematic
##
[LAY]dwc_ddrphy_decap/dwc_ddrphy_decapvaa_vdd2_ns/layout
[SCH]dwc_ddrphy_decap/dwc_ddrphy_decapvaa_vdd2_ns/schematic
#
[LAY]dwc_ddrphy_decap/dwc_ddrphy_decapvaa_vdd2_ew/layout
[SCH]dwc_ddrphy_decap/dwc_ddrphy_decapvaa_vdd2_ew/schematic
#
#[LAY]dwc_ddrphy_utility/dwc_ddrphy_utility_cells/layout
#[SCH]dwc_ddrphy_utility/dwc_ddrphy_utility_cells/schematic
##
#[LAY]dwc_ddrphy_rptch/dwc_ddrphy_repeater_cells/layout
#[SCH]dwc_ddrphy_rptch/dwc_ddrphy_repeater_cells/schematic
###layout only macros
#[LAY]dwc_ddrphy_se_io/dwc_ddrphy_se_io_ns_overlay/layout
#
#[LAY]dwc_ddrphy_testbenches/dwc_ddrphydiff_top_ns_gradient/layout
##
#[LAY]dwc_ddrphy_testbenches/dwc_ddrphymaster_top_ns_gradient/layout
##
#[LAY]dwc_ddrphy_testbenches/dwc_ddrphysec_top_ns_gradient/layout
##
#[LAY]dwc_ddrphy_testbenches/dwc_ddrphyse_top_ns_gradient/layout
#
[LAY]dwc_ddrphy_se_io/dwc_ddrphy_se_io_ew_overlay/layout
#
[LAY]dwc_ddrphy_testbenches/dwc_ddrphydiff_top_ew_gradient/layout
##
[LAY]dwc_ddrphy_testbenches/dwc_ddrphymaster_top_ew_gradient/layout
##
[LAY]dwc_ddrphy_testbenches/dwc_ddrphysec_top_ew_gradient/layout
##
[LAY]dwc_ddrphy_testbenches/dwc_ddrphyse_top_ew_gradient/layout
##MTOP macros
#[LAY]dwc_ddrphycover/dwc_ddrphycover_dwc_ddrphyse_top_ns/layout
#[SCH]dwc_ddrphycover/dwc_ddrphycover_dwc_ddrphyse_top_ns/schematic
##
#[LAY]dwc_ddrphycover/dwc_ddrphycover_dwc_ddrphysec_top_ns/layout
#[SCH]dwc_ddrphycover/dwc_ddrphycover_dwc_ddrphysec_top_ns/schematic
##
#[LAY]dwc_ddrphycover/dwc_ddrphycover_dwc_ddrphydiff_top_ns/layout
#[SCH]dwc_ddrphycover/dwc_ddrphycover_dwc_ddrphydiff_top_ns/schematic
##
#[LAY]dwc_ddrphycover/dwc_ddrphycover_dwc_ddrphymaster_top_ns/layout
#[SCH]dwc_ddrphycover/dwc_ddrphycover_dwc_ddrphymaster_top_ns/schematic
##
[LAY]dwc_ddrphycover/dwc_ddrphycover_dwc_ddrphyse_top_ew/layout
[SCH]dwc_ddrphycover/dwc_ddrphycover_dwc_ddrphyse_top_ew/schematic
#
[LAY]dwc_ddrphycover/dwc_ddrphycover_dwc_ddrphysec_top_ew/layout
[SCH]dwc_ddrphycover/dwc_ddrphycover_dwc_ddrphysec_top_ew/schematic
#
[LAY]dwc_ddrphycover/dwc_ddrphycover_dwc_ddrphydiff_top_ew/layout
[SCH]dwc_ddrphycover/dwc_ddrphycover_dwc_ddrphydiff_top_ew/schematic
#
[LAY]dwc_ddrphycover/dwc_ddrphycover_dwc_ddrphymaster_top_ew/layout
[SCH]dwc_ddrphycover/dwc_ddrphycover_dwc_ddrphymaster_top_ew/schematic
##
[LAY]dwc_ddrphy_utility/dwc_ddrphy_utility_blocks/layout
[SCH]dwc_ddrphy_utility/dwc_ddrphy_utility_blocks/schematic
##
[LAY]dwc_ddrphy_rptch/dwc_ddrphy_repeater_blocks/layout
[SCH]dwc_ddrphy_rptch/dwc_ddrphy_repeater_blocks/schematic
##
[LAY]dwc_ddrphy_thermdiode/dwc_ddrphy_thermdiode/layout
[SCH]dwc_ddrphy_thermdiode/dwc_ddrphy_thermdiode/schematic
#
EOF

my $ex2 = <<EOF;
//wwcad/msip/projects/ddr54/d819-ddr54-cuamd-tsmc7ff18/rel1.00_cktpcs/pcs/design/topcells.txt#31 - edit change 6518534 (text+x)
##  topcells file created from /remote/cad-rep/projects/ddr54/d809-ddr54-tsmc7ff18/rel1.00_cktpcs/design/legalMacros.txt
[LAY]dwc_ddrphy_bitslice/dwc_ddrphy_txrxdq_ew/layout
[SCH]dwc_ddrphy_bitslice/dwc_ddrphy_txrxdq_ew/schematic
#
[LAY]dwc_ddrphy_bitslice/dwc_ddrphy_txrxdqs_ew/layout
[SCH]dwc_ddrphy_bitslice/dwc_ddrphy_txrxdqs_ew/schematic
#
[LAY]dwc_ddrphy_bitslice/dwc_ddrphy_txrxac_ew/layout
[SCH]dwc_ddrphy_bitslice/dwc_ddrphy_txrxac_ew/schematic
#
[LAY]dwc_ddrphy_bitslice/dwc_ddrphy_memreset_ew/layout
[SCH]dwc_ddrphy_bitslice/dwc_ddrphy_memreset_ew/schematic
#
[LAY]dwc_ddrphy_bitslice/dwc_ddrphy_techrevision/layout
[SCH]dwc_ddrphy_bitslice/dwc_ddrphy_techrevision/schematic
#
[LAY]dwc_ddrphy_clktree/dwc_ddrphy_clk_master/layout
[SCH]dwc_ddrphy_clktree/dwc_ddrphy_clk_master/schematic
#
[LAY]dwc_ddrphy_clktree/dwc_ddrphy_clk_rx/layout
[SCH]dwc_ddrphy_clktree/dwc_ddrphy_clk_rx/schematic
#
#[LAY]dwc_ddrphy_clktree_repeater/dwc_ddrphy_clktree_repeater/layout
#[SCH]dwc_ddrphy_clktree_repeater/dwc_ddrphy_clktree_repeater/schematic
#
[LAY]dwc_ddrphy_clktree/dwc_ddrphy_datclkdrv/layout
[SCH]dwc_ddrphy_clktree/dwc_ddrphy_datclkdrv/schematic
#
[LAY]dwc_ddrphy_lstx/dwc_ddrphy_lstx_ew/layout
[SCH]dwc_ddrphy_lstx/dwc_ddrphy_lstx_ew/schematic
#
#[LAY]dwc_ddrphy_lstx/dwc_ddrphy_lstx_dq_ew/layout
#[SCH]dwc_ddrphy_lstx/dwc_ddrphy_lstx_dq_ew/schematic
#
[LAY]dwc_ddrphy_vreg/dwc_ddrphy_vregvsh_ew/layout
[SCH]dwc_ddrphy_vreg/dwc_ddrphy_vregvsh_ew/schematic
#
[LAY]dwc_ddrphy_ddl/dwc_ddrphy_lcdl/layout
[SCH]dwc_ddrphy_ddl/dwc_ddrphy_lcdl/schematic
#
[LAY]dwc_ddrphy_cmpana/dwc_ddrphy_cmpana/layout
[SCH]dwc_ddrphy_cmpana/dwc_ddrphy_cmpana/schematic
#
[LAY]dwc_ddrphy_por/dwc_ddrphy_por/layout
[SCH]dwc_ddrphy_por/dwc_ddrphy_por/schematic
#
[LAY]dwc_ddrphy_vref/dwc_ddrphy_vrefglobal/layout
[SCH]dwc_ddrphy_vref/dwc_ddrphy_vrefglobal/schematic
#
[LAY]dwc_ddrphy_clamp/dwc_ddrphy_vaaclamp/layout
[SCH]dwc_ddrphy_clamp/dwc_ddrphy_vaaclamp/schematic
#
[LAY]dwc_ddrphy_clamp/dwc_ddrphy_vddqclamp_ew/layout
[SCH]dwc_ddrphy_clamp/dwc_ddrphy_vddqclamp_ew/schematic
#
[LAY]dwc_ddrphy_clamp/dwc_ddrphy_vddqclamp_dqs_ew/layout
[SCH]dwc_ddrphy_clamp/dwc_ddrphy_vddqclamp_dqs_ew/schematic
#
#[LAY]dwc_ddrphy_clamp/dwc_ddrphy_vddqclamp_dq_ew/layout
#[SCH]dwc_ddrphy_clamp/dwc_ddrphy_vddqclamp_dq_ew/schematic
#
#[LAY]dwc_ddrphy_decap/dwc_ddrphy_decapvddq_ew/layout
#[SCH]dwc_ddrphy_decap/dwc_ddrphy_decapvddq_ew/schematic
#
#[LAY]dwc_ddrphy_decap/dwc_ddrphy_decapvddq_ns/layout
#[SCH]dwc_ddrphy_decap/dwc_ddrphy_decapvddq_ns/schematic
#
[LAY]dwc_ddrphy_decap/dwc_ddrphy_decapvaa_tile/layout
[SCH]dwc_ddrphy_decap/dwc_ddrphy_decapvaa_tile/schematic
#
#[LAY]dwc_ddrphy_decap/dwc_ddr54_utility_cells/layout
#[SCH]dwc_ddrphy_decap/dwc_ddr54_utility_cells/schematic
#
[LAY]dwc_ddrphy_testbenches/dwc_ddrphy_gradient/layout
[SCH]dwc_ddrphy_testbenches/dwc_ddrphy_gradient/schematic
#
[LAY]dwc_ddrphy_testbenches/dwc_ddrphy_gradient_wide/layout
[SCH]dwc_ddrphy_testbenches/dwc_ddrphy_gradient_wide/schematic
#
[LAY]dwc_ddrphy_testbenches/dwc_ddrphy_pllshim/layout
[SCH]dwc_ddrphy_testbenches/dwc_ddrphy_pllshim/schematic
#
#[LAY]dwc_ddrphycover/dwc_ddrphycover_acx4_top_ew/layout
#[SCH]dwc_ddrphycover/dwc_ddrphycover_acx4_top_ew/schematic
#
#[LAY]dwc_ddrphycover/dwc_ddrphycover_dbyte_top_ew/layout
#[SCH]dwc_ddrphycover/dwc_ddrphycover_dbyte_top_ew/schematic
#
#[LAY]dwc_ddrphycover/dwc_ddrphycover_master_top/layout
#[SCH]dwc_ddrphycover/dwc_ddrphycover_master_top/schematic
#
#[LAY]dwc_ddrphycover_hdmim/dwc_ddrphycover_acx4_top_ew_hdmim/layout
#[SCH]dwc_ddrphycover_hdmim/dwc_ddrphycover_acx4_top_ew_hdmim/schematic
#
#[LAY]dwc_ddrphycover_hdmim/dwc_ddrphycover_dbyte_top_ew_hdmim/layout
#[SCH]dwc_ddrphycover_hdmim/dwc_ddrphycover_dbyte_top_ew_hdmim/schematic
#
#[LAY]dwc_ddrphycover_hdmim/dwc_ddrphycover_master_top_hdmim/layout
#[SCH]dwc_ddrphycover_hdmim/dwc_ddrphycover_master_top_hdmim/schematic
#
#[LAY]dwc_ddrphycover_hdmim/dwc_ddrphycover_dwc_ddrphyacx4_decapvddq_ew/layout
#[SCH]dwc_ddrphycover_hdmim/dwc_ddrphycover_dwc_ddrphyacx4_decapvddq_ew/schematic
#
#[LAY]dwc_ddrphycover_hdmim/dwc_ddrphycover_dwc_ddrphydbyte_decapvddq_ew/layout
#[SCH]dwc_ddrphycover_hdmim/dwc_ddrphycover_dwc_ddrphydbyte_decapvddq_ew/schematic
#
[LAY]dwc_ddrphycover_hdmim/dwc_ddrphycover_dwc_ddrphydbyte_decapvddq_adjcoil_ew/layout
[SCH]dwc_ddrphycover_hdmim/dwc_ddrphycover_dwc_ddrphydbyte_decapvddq_adjcoil_ew/schematic
EOF

# Example #3 from //wwcad/msip/projects/ddr54/d810-ddr54-tsmc5ffp12/rel1.00_cktpcs/pcs/design_unrestricted/topcells.txt
my $ex3=<<EOF;
## list of legal macros for final design delivery
#
[LAY]dwc_ddrphy_bitslice/dwc_ddrphy_txrxdq_ew/layout
[SCH]dwc_ddrphy_bitslice/dwc_ddrphy_txrxdq_ew/schematic
#
[LAY]dwc_ddrphy_bitslice/dwc_ddrphy_txrxdqs_ew/layout
[SCH]dwc_ddrphy_bitslice/dwc_ddrphy_txrxdqs_ew/schematic
#
[LAY]dwc_ddrphy_bitslice/dwc_ddrphy_txrxac_ew/layout
[SCH]dwc_ddrphy_bitslice/dwc_ddrphy_txrxac_ew/schematic
#
[LAY]dwc_ddrphy_bitslice/dwc_ddrphy_memreset_ew/layout
[SCH]dwc_ddrphy_bitslice/dwc_ddrphy_memreset_ew/schematic
#
[LAY]dwc_ddrphy_bitslice/dwc_ddrphy_techrevision/layout
[SCH]dwc_ddrphy_bitslice/dwc_ddrphy_techrevision/schematic
#
[LAY]dwc_ddrphy_vreg/dwc_ddrphy_vregvsh_ew/layout
[SCH]dwc_ddrphy_vreg/dwc_ddrphy_vregvsh_ew/schematic
#
[LAY]dwc_ddrphy_lstx/dwc_ddrphy_lstx_ew/layout
[SCH]dwc_ddrphy_lstx/dwc_ddrphy_lstx_ew/schematic
#
[LAY]dwc_ddrphy_ddl/dwc_ddrphy_lcdl/layout
[SCH]dwc_ddrphy_ddl/dwc_ddrphy_lcdl/schematic
#
[LAY]dwc_ddrphy_clktree/dwc_ddrphy_clk_master/layout
[SCH]dwc_ddrphy_clktree/dwc_ddrphy_clk_master/schematic
#
[LAY]dwc_ddrphy_clktree/dwc_ddrphy_clk_rx/layout
[SCH]dwc_ddrphy_clktree/dwc_ddrphy_clk_rx/schematic
#
[LAY]dwc_ddrphy_clktree/dwc_ddrphy_clktree_repeater/layout
[SCH]dwc_ddrphy_clktree/dwc_ddrphy_clktree_repeater/schematic
#
[LAY]dwc_ddrphy_clktree/dwc_ddrphy_datclkdrv/layout
[SCH]dwc_ddrphy_clktree/dwc_ddrphy_datclkdrv/schematic
#
[LAY]dwc_ddrphy_cmpana/dwc_ddrphy_cmpana/layout
[SCH]dwc_ddrphy_cmpana/dwc_ddrphy_cmpana/schematic
#
[LAY]dwc_ddrphy_por/dwc_ddrphy_por/layout
[SCH]dwc_ddrphy_por/dwc_ddrphy_por/schematic
#
[LAY]dwc_ddrphy_vref/dwc_ddrphy_vrefglobal/layout
[SCH]dwc_ddrphy_vref/dwc_ddrphy_vrefglobal/schematic
#
## decap and ESD clamps
#
[LAY]dwc_ddrphy_clamp/dwc_ddrphy_vddqclamp_ew/layout
[SCH]dwc_ddrphy_clamp/dwc_ddrphy_vddqclamp_ew/schematic
#
[LAY]dwc_ddrphy_clamp/dwc_ddrphy_vaaclamp/layout
[SCH]dwc_ddrphy_clamp/dwc_ddrphy_vaaclamp/schematic
#
[LAY]dwc_ddrphy_decap/dwc_ddrphy_decapvaa_tile/layout
[SCH]dwc_ddrphy_decap/dwc_ddrphy_decapvaa_tile/schematic
#
[LAY]dwc_ddrphy_decap/dwc_ddrphy_decapvddq_ew/layout
[SCH]dwc_ddrphy_decap/dwc_ddrphy_decapvddq_ew/schematic
#
[LAY]dwc_ddrphy_decap/dwc_ddrphy_decapvddq_ns/layout
[SCH]dwc_ddrphy_decap/dwc_ddrphy_decapvddq_ns/schematic
#
#[LAY]dwc_ddrphy_decap/dwc_ddrphy_decapvsh_acx4_ew/layout
#[SCH]dwc_ddrphy_decap/dwc_ddrphy_decapvsh_acx4_ew/schematic
#
#[LAY]dwc_ddrphy_decap/dwc_ddrphy_decapvsh_dbyte_ew/layout
#[SCH]dwc_ddrphy_decap/dwc_ddrphy_decapvsh_dbyte_ew/schematic
#
#[LAY]dwc_ddrphy_decap/dwc_ddrphy_decapvsh_master/layout
#[SCH]dwc_ddrphy_decap/dwc_ddrphy_decapvsh_master/schematic
#
[LAY]dwc_ddrphy_decap/dwc_ddrphy_utility_cells/layout
[SCH]dwc_ddrphy_decap/dwc_ddrphy_utility_cells/schematic
#
[LAY]dwc_ddrphy_utility/dwc_ddrphy_utility_blocks/layout
[SCH]dwc_ddrphy_utility/dwc_ddrphy_utility_blocks/schematic
#
[LAY]dwc_ddrphy_testbenches/dwc_ddrphy_pllshim/layout
[SCH]dwc_ddrphy_testbenches/dwc_ddrphy_pllshim/schematic
#
[LAY]dwc_ddrphycover/dwc_ddrphycover_dwc_ddrphyacx4_top_ew/layout
[SCH]dwc_ddrphycover/dwc_ddrphycover_dwc_ddrphyacx4_top_ew/schematic
#
[LAY]dwc_ddrphycover/dwc_ddrphycover_dwc_ddrphydbyte_top_ew/layout
[SCH]dwc_ddrphycover/dwc_ddrphycover_dwc_ddrphydbyte_top_ew/schematic
#
[LAY]dwc_ddrphycover/dwc_ddrphycover_dwc_ddrphymaster_top/layout
[SCH]dwc_ddrphycover/dwc_ddrphycover_dwc_ddrphymaster_top/schematic
#
## TC only cells
#
#[LAY]dwc_ddrphy_decap/dwc_ddrphy_decapvdd_tile/layout
#[SCH]dwc_ddrphy_decap/dwc_ddrphy_decapvdd_tile/schematic
#
#[LAY]dwc_ddrphy_decap/dwc_ddrphy_decapvdd_ew/layout
#[SCH]dwc_ddrphy_decap/dwc_ddrphy_decapvdd_ew/schematic
#
#[LAY]dwc_ddrphy_decap/dwc_ddrphy_decapvdd_ns/layout
#[SCH]dwc_ddrphy_decap/dwc_ddrphy_decapvdd_ns/schematic
#
#[LAY]dwc_ddrphy_decap/dwc_ddrphy_decapvddhd_ew/layout
#[SCH]dwc_ddrphy_decap/dwc_ddrphy_decapvddhd_ew/schematic
#
#[LAY]dwc_ddrphy_decap/dwc_ddrphy_decapvddhd_ns/layout
#[SCH]dwc_ddrphy_decap/dwc_ddrphy_decapvddhd_ns/schematic
#
#[LAY]dwc_ddrphy_decap/dwc_ddrphy_decapvddq_acx4_ew/layout
#[SCH]dwc_ddrphy_decap/dwc_ddrphy_decapvddq_acx4_ew/schematic
#
#[LAY]dwc_ddrphy_decap/dwc_ddrphy_decapvddq_dbyte_ew/layout
#[SCH]dwc_ddrphy_decap/dwc_ddrphy_decapvddq_dbyte_ew/schematic
#
#[LAY]dwc_ddrphy_decap/dwc_ddrphy_decapvddq_master/layout
#[SCH]dwc_ddrphy_decap/dwc_ddrphy_decapvddq_master/schematic
#
#[LAY]dwc_ddrphy_clamp/dwc_ddrphy_vddclamp_ew/layout
#[SCH]dwc_ddrphy_clamp/dwc_ddrphy_vddclamp_ew/schematic
#
#[LAY]dwc_ddrphy_rx/dwc_ddrphy_rxdqs_ew/layout
#[SCH]dwc_ddrphy_rx/dwc_ddrphy_rxdqs_ew/schematic
#
#[LAY]unit_esd/ioesd_hbm_9a_ew/layout
#[SCH]unit_esd/ioesd_hbm_9a_ew/schematic
EOF

# Example #4 from //wwcad/msip/projects/ddr54/d803-ddr54-ss10lpp18/rel1.00_cktpcs/pcs/design/topcells.txt
my $ex4=<<EOF;
## Macros from D523
[REF1]ddr43/d523-ddr43-ss10lpp18/rel1.00_cktpcs
[REF1][LAY]dwc_ddrphy_cmpana/dwc_ddrphy_cmpana/layout
[REF1][SCH]dwc_ddrphy_cmpana/dwc_ddrphy_cmpana/schematic
[REF1][LAY]dwc_ddrphy_por/dwc_ddrphy_por/layout
[REF1][SCH]dwc_ddrphy_por/dwc_ddrphy_por/schematic
[REF1][LAY]dwc_ddrphy_vref/dwc_ddrphy_vrefglobal/layout
[REF1][SCH]dwc_ddrphy_vref/dwc_ddrphy_vrefglobal/schematic
[REF1][LAY]dwc_ddrphy_vaaclamp/dwc_ddrphy_vaaclamp/layout 
[REF1][SCH]dwc_ddrphy_vaaclamp/dwc_ddrphy_vaaclamp/schematic 
[REF1][LAY]dwc_ddrphy_clktree/dwc_ddrphy_clk_master/layout
[REF1][SCH]dwc_ddrphy_clktree/dwc_ddrphy_clk_master/schematic
[REF1][LAY]dwc_ddrphy_clktree/dwc_ddrphy_clk_rx/layout
[REF1][SCH]dwc_ddrphy_clktree/dwc_ddrphy_clk_rx/schematic
[REF1][LAY]dwc_ddrphy_clktree/dwc_ddrphy_datclkdrv/layout
[REF1][SCH]dwc_ddrphy_clktree/dwc_ddrphy_datclkdrv/schematic


##  topcells file created from /remote/cad-rep/projects/ddr54/d803-ddr54-ss10lpp18/rel1.00_cktpcs/design/legalMacros.txt
[LAY]dwc_ddrphy_bitslice/dwc_ddrphy_txrxdq_ns/layout
[SCH]dwc_ddrphy_bitslice/dwc_ddrphy_txrxdq_ns/schematic
[LAY]dwc_ddrphy_bitslice/dwc_ddrphy_txrxdqs_ns/layout
[SCH]dwc_ddrphy_bitslice/dwc_ddrphy_txrxdqs_ns/schematic
[LAY]dwc_ddrphy_bitslice/dwc_ddrphy_txrxac_ns/layout
[SCH]dwc_ddrphy_bitslice/dwc_ddrphy_txrxac_ns/schematic
[LAY]dwc_ddrphy_bitslice/dwc_ddrphy_memreset_ns/layout
[SCH]dwc_ddrphy_bitslice/dwc_ddrphy_memreset_ns/schematic
[LAY]dwc_ddrphy_bitslice/dwc_ddrphy_techrevision/layout
[SCH]dwc_ddrphy_bitslice/dwc_ddrphy_techrevision/schematic
[LAY]dwc_ddrphy_lstx/dwc_ddrphy_lstx_ns/layout
[SCH]dwc_ddrphy_lstx/dwc_ddrphy_lstx_ns/schematic
[LAY]dwc_ddrphy_vreg/dwc_ddrphy_vregvsh_ns/layout
[SCH]dwc_ddrphy_vreg/dwc_ddrphy_vregvsh_ns/schematic
[LAY]dwc_ddrphy_ddl/dwc_ddrphy_lcdl/layout
[SCH]dwc_ddrphy_ddl/dwc_ddrphy_lcdl/schematic
[LAY]dwc_ddrphy_clamp/dwc_ddrphy_vddqclamp_ns/layout
[SCH]dwc_ddrphy_clamp/dwc_ddrphy_vddqclamp_ns/schematic
[LAY]dwc_ddrphy_decap/dwc_ddrphy_decapvddq_ew/layout
[SCH]dwc_ddrphy_decap/dwc_ddrphy_decapvddq_ew/schematic
[LAY]dwc_ddrphy_decap/dwc_ddrphy_decapvddq_ns/layout
[SCH]dwc_ddrphy_decap/dwc_ddrphy_decapvddq_ns/schematic
[LAY]dwc_ddrphy_decap/dwc_ddrphy_decapvaa_tile/layout
[SCH]dwc_ddrphy_decap/dwc_ddrphy_decapvaa_tile/schematic
#[LAY]dwc_ddrphy_decap/dwc_ddrphy_utility_cells/layout
#[SCH]dwc_ddrphy_decap/dwc_ddrphy_utility_cells/schematic
#[LAY]dwc_ddrphy_decap/dwc_ddrphy_utility_blocks/layout
#[SCH]dwc_ddrphy_decap/dwc_ddrphy_utility_blocks/schematic
#[LAY]dwc_ddrphy_clktree/dwc_ddrphy_clktree_repeater/layout
#[SCH]dwc_ddrphy_clktree/dwc_ddrphy_clktree_repeater/schematic
#[LAY]dwc_ddrphy_testbenches/dwc_ddrphy_gradient/layout

[LAY]dwc_ddrphy_testbenches/dwc_ddrphy_pllshim/layout
##  [SCH]dwc_ddrphy_testbenches/dwc_ddrphy_pllshim   LAYOUT ONLY
[LAY]dwc_ddrphy_testbenches/dwc_ddrphy_oddSite_shim_odd/layout
##  [SCH]dwc_ddrphy_testbenches/dwc_ddrphy_oddSite_shim_odd/layout   LAYOUT ONLY
[LAY]dwc_ddrphy_testbenches/dwc_ddrphy_oddSite_shim_even/layout
##  [SCH]dwc_ddrphy_testbenches/dwc_ddrphy_oddSite_shim_even/layout   LAYOUT ONLY

#[LAY]ddrphy_unitcells/sg_fdprbsbqb/layout
#[SCH]ddrphy_unitcells/sg_fdprbsbqb/schematic
[LAY]ddrphy_unitcells/sg_fdprbsbqb_left/layout
[SCH]ddrphy_unitcells/sg_fdprbsbqb_left/schematic
[LAY]ddrphy_unitcells/sg_fdprbsbqb_right/layout
[SCH]ddrphy_unitcells/sg_fdprbsbqb_right/schematic

#[LAY]dwc_ddrphycover/dwc_ddrphycover_dwc_ddrphymaster_top/layout
#[SCH]dwc_ddrphycover/dwc_ddrphycover_dwc_ddrphymaster_top/layout
#[LAY]dwc_ddrphycover/dwc_ddrphycover_dwc_ddrphyacx4_top_ns/layout
#[SCH]dwc_ddrphycover/dwc_ddrphycover_dwc_ddrphyacx4_top_ns/layout
#[LAY]dwc_ddrphycover/dwc_ddrphycover_dwc_ddrphydbyte_top_ns/layout
#[SCH]dwc_ddrphycover/dwc_ddrphycover_dwc_ddrphydbyte_top_ns/layout
EOF

   my %tests = (
      '1' => {
         'sample'   => "$ex1",
         'expected' => {
                        'DEFAULT' =>    [ qw(
                                 dwc_ddrphy_se_io_ew dwc_ddrphy_diff_io_ew dwc_ddrphy_sec_io_ew
                                 dwc_ddrphy_pclk_master_ew dwc_ddrphy_pclk_rx_ew dwc_ddrphy_zcalana_ew
                                 dwc_ddrphy_por_ew dwc_ddrphy_vrefdacref_ew dwc_ddrphy_rxreplica_ew
                                 dwc_ddrphy_lcdl_ew dwc_ddrphy_techrevision_ew dwc_ddrphy_decapvaa_vdd2_ns
                                 dwc_ddrphy_decapvaa_vdd2_ew dwc_ddrphy_se_io_ew_overlay dwc_ddrphydiff_top_ew_gradient
                                 dwc_ddrphymaster_top_ew_gradient dwc_ddrphysec_top_ew_gradient dwc_ddrphyse_top_ew_gradient
                                 dwc_ddrphycover_dwc_ddrphyse_top_ew dwc_ddrphycover_dwc_ddrphysec_top_ew
                                 dwc_ddrphycover_dwc_ddrphydiff_top_ew dwc_ddrphycover_dwc_ddrphymaster_top_ew
                                 dwc_ddrphy_utility_blocks dwc_ddrphy_repeater_blocks dwc_ddrphy_thermdiode
                            ) ],
                        }
      },
      '2' => {
         'sample'   => "$ex2",
         'expected' => {
                        'DEFAULT' =>    [ qw( 
                                 dwc_ddrphy_txrxdq_ew dwc_ddrphy_txrxdqs_ew dwc_ddrphy_txrxac_ew
                                 dwc_ddrphy_memreset_ew dwc_ddrphy_techrevision dwc_ddrphy_clk_master
                                 dwc_ddrphy_clk_rx dwc_ddrphy_datclkdrv dwc_ddrphy_lstx_ew
                                 dwc_ddrphy_vregvsh_ew dwc_ddrphy_lcdl dwc_ddrphy_cmpana
                                 dwc_ddrphy_por dwc_ddrphy_vrefglobal dwc_ddrphy_vaaclamp
                                 dwc_ddrphy_vddqclamp_ew dwc_ddrphy_vddqclamp_dqs_ew dwc_ddrphy_decapvaa_tile
                                 dwc_ddrphy_gradient dwc_ddrphy_gradient_wide
                                 dwc_ddrphy_pllshim dwc_ddrphycover_dwc_ddrphydbyte_decapvddq_adjcoil_ew
                              )
                           ],
                       }
      },
      '3' => {
         'sample'   => "$ex3",
         'expected' => {
                        'DEFAULT' =>    [ qw( 
                                 dwc_ddrphy_txrxdq_ew dwc_ddrphy_txrxdqs_ew dwc_ddrphy_txrxac_ew
                                 dwc_ddrphy_memreset_ew dwc_ddrphy_techrevision dwc_ddrphy_vregvsh_ew
                                 dwc_ddrphy_lstx_ew dwc_ddrphy_lcdl dwc_ddrphy_clk_master
                                 dwc_ddrphy_clk_rx dwc_ddrphy_clktree_repeater dwc_ddrphy_datclkdrv
                                 dwc_ddrphy_cmpana dwc_ddrphy_por dwc_ddrphy_vrefglobal
                                 dwc_ddrphy_vddqclamp_ew dwc_ddrphy_vaaclamp dwc_ddrphy_decapvaa_tile
                                 dwc_ddrphy_decapvddq_ew dwc_ddrphy_decapvddq_ns dwc_ddrphy_utility_cells
                                 dwc_ddrphy_utility_blocks dwc_ddrphy_pllshim
                                 dwc_ddrphycover_dwc_ddrphyacx4_top_ew
                                 dwc_ddrphycover_dwc_ddrphydbyte_top_ew
                                 dwc_ddrphycover_dwc_ddrphymaster_top
                               ) 
                           ],
                       }
      },
      '4' => {
         'sample'   => "$ex4",
         'expected' => {
                        'DEFAULT' =>    [ qw(
                                 dwc_ddrphy_txrxdq_ns dwc_ddrphy_txrxdqs_ns dwc_ddrphy_txrxac_ns
                                 dwc_ddrphy_memreset_ns dwc_ddrphy_techrevision dwc_ddrphy_lstx_ns
                                 dwc_ddrphy_vregvsh_ns dwc_ddrphy_lcdl dwc_ddrphy_vddqclamp_ns
                                 dwc_ddrphy_decapvddq_ew dwc_ddrphy_decapvddq_ns dwc_ddrphy_decapvaa_tile
                                 dwc_ddrphy_pllshim dwc_ddrphy_oddSite_shim_odd dwc_ddrphy_oddSite_shim_even
                                 sg_fdprbsbqb_left sg_fdprbsbqb_right
                               )
                           ],
                        'ddr43/d523-ddr43-ss10lpp18/rel1.00_cktpcs' =>  [ qw(
                                 dwc_ddrphy_cmpana dwc_ddrphy_por dwc_ddrphy_vrefglobal
                                 dwc_ddrphy_vaaclamp dwc_ddrphy_clk_master dwc_ddrphy_clk_rx
                                 dwc_ddrphy_datclkdrv
                               )
                            ],
                        }
      },
   );
   return( %tests );
}
1;

