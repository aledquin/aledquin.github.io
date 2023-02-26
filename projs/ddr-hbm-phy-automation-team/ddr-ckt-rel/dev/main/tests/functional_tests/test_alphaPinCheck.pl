#!/depot/perl-5.14.2/bin/perl
use strict;
use warnings;
# nolint utils__script_usage_statistics
use Cwd     qw(getcwd);
use Cwd     qw( abs_path );
use Carp    qw( cluck confess croak );
use Getopt::Std;
use Getopt::Long;
use FindBin qw( $RealBin $RealScript );
use Test2::Bundle::More;

use lib "$RealBin/../../lib/perl/";
use Util::CommonHeader;
use Util::Misc;
use Util::Messaging;
use lib "$RealBin/lib";
use TestUtils;

our $STDOUT_LOG   = undef; 
our $DEBUG        = undef;
our $VERBOSITY    = undef;
our $PROGRAM_NAME = $RealScript;
our $RUN_SYSTEM_CMDS = undef;
our $AUTO_APPEND_NEWLINE = 1;
our $DDR_DA_DEFAULT_P4WS = "p4_func_tests";
my  $TDATA        = "../data/alphaPinCheck.pl";

#-----------------------------------------------------------
sub check_all_files_in_tests_exist($){
    my %t = %{ +shift };

    # all the file paths for tests are relative to location
    #     of this script
    chdir( $RealBin );
    foreach my $num ( sort keys %t ){
        my @views = qw( liberty libertynopg lef cdl gds pinCSV verilog );
        foreach my $v ( sort @views ){
            if( defined $t{$num}{$v} ){  # view may not exist for any given test
                my $fname = $t{$num}{$v};
                if( isa_aref($fname) ){
                    foreach my $file ( @$fname ){
                        dprint(LOW, "T#$num : V $v : $file\n" );
                        read_file( $file ); # this will fatal if bad
                    }
                }else{
                    dprint(LOW, "T#$num : V $v : $fname\n" );
                    read_file( $fname ); # this will fatal if bad
                }
            }
        }
    }
}

#-------------------------------------------------------------------------------
# process the command line arguments
#     set the values for DEBUG and VERBOSITY
#-------------------------------------------------------------------------------
sub process_cmd_line_args(){
    print_function_header();
    my ( $opt_testnum, $opt_run,  $opt_verbosity,
         $opt_debug,   $opt_help, $opt_p4ws );

    my $success = GetOptions(
        "verbosity=i" => \$opt_verbosity,
        "debug=i"     => \$opt_debug,
        "p4ws=s"      => \$opt_p4ws,
        "testnum=i"   => \$opt_testnum,
        "help!"       => \$opt_help,
        "run!"        => \$opt_run,
        "help"        => \$opt_help, 
    );

    $opt_p4ws = 'p4_func_tests' unless( defined $opt_p4ws );
    $main::VERBOSITY = $opt_verbosity if( defined $opt_verbosity );
    $main::DEBUG     = $opt_debug     if( defined $opt_debug     );
    # turn off system cmds so they can be inspected when user 
    #     calls script with '-norun'
    $main::RUN_SYSTEM_CMDS = 0        if( defined $opt_run && $opt_run == 0 );

    ## quit with usage message, if usage not satisfied
    &usage(0) if $opt_help;
    &usage(1) unless( $success );

    return( $opt_testnum, $opt_p4ws );
}

#-------------------------------------------------------------------------------
#  script usage message
#-------------------------------------------------------------------------------
sub usage($) {
    my $exit_status = shift;

    print << "EOP" ;
Description
  A script to run pin check on all views of all macros in the depot

USAGE : $PROGRAM_NAME [options] -p <projSPEC>

------------------------------------
Required Args:
------------------------------------


------------------------------------
Optional Args:
------------------------------------
-help              print this screen
-p4ws              ROOT for your p4 workspace (default = p4_func_tests)
-norun             don't execute sys-cmds
-testnum    <#>    only run specified test number 
-verbosity  <#>    print additional messages ... includes details of system calls etc. 
                   Must provide integer argument -> higher values increases verbosity.
-debug      <#>    print additional diagnostic messagess to debug script

EOP
    exit($exit_status) ;
}


#-----------------------------------------------------------
sub Main(){
    my ($opt_testnum, $opt_p4ws) = process_cmd_line_args();
    my $p4root = abs_path( "$ENV{HOME}/$opt_p4ws" );
    dprint(LOW, "p4root = '$p4root' \n" );
    my $USER        = get_username();
    my $scriptName  = "alphaPinCheck.pl";
    #--------------------------------------------------------------------------
    # %DP (data path) record the base/root data path to the KGR (Known Good Reference) inputs to the tests
    # Example:
    #    You would find all the required files by appending the filenames to
    #    each 'prefix' here.
    #
    #    '90'  => "$TDATA/ddr54.project.d822-ddr54-ss7hpp-18.ckt.rel.dwc_ddrphy_cmpana.1.00a_pre3",
    #              ------------------------------------------------------------------------------
    #               this is the 'prefix'
    #
    #     The actual files are the  'prefix'.<filename>  
    #
    #--------------------------------------------------------------------------
    my %DP = (
         '1'  => NULL_VAL,
         '2'  => NULL_VAL,
         '3'  => NULL_VAL,
         '4'  => NULL_VAL,
         '5'  => NULL_VAL,
        '88'  => "$TDATA/QA_test_plan.QA_testbenches.alphaPincheck.alphaPinCheck_002.QA_dwc_lpddr5xphy_txrxdq_ew_lppddr5x",
        '89'  => "$TDATA/QA_test_plan.QA_testbenches.alphaPincheck.alphaPinCheck_002.QA_dwc_lpddr5xphy_txrxdq_ew_lppddr5x",
        '90'  => "$TDATA/ddr54.project.d822-ddr54-ss7hpp-18.ckt.rel.dwc_ddrphy_cmpana.1.00a_pre3",
        '91'  => "$TDATA/ddr54.project.d822-ddr54-ss7hpp-18.ckt.rel.dwc_ddrphy_txrxac_ns.1.10a.macro",
        '92'  => "$TDATA/ddr54.project.d822-ddr54-ss7hpp-18.ckt.rel.dwc_ddrphy_txrxdq_ns.1.00a_pre3.macro",
        '93'  => "$TDATA/lpddr54.project.d859-lpddr54-tsmc7ff18.ckt.rel.dwc_ddrphy_pclk_master.1.20a_patch1.macro",
        '94'  => "$TDATA/lpddr54.project.d859-lpddr54-tsmc7ff18.ckt.rel.dwc_ddrphy_se_io_ns.1.20a_patch1.macro",
        '95'  => "$TDATA/lpddr5x_ddr5_phy.lp5x.project.d930-lpddr5x-tsmc5ff12.ckt.rel.dwc_lpddr5xphy_lstx_acx2_ew.3.00a.macro",
        '96'  => "$TDATA/lpddr5x_ddr5_phy.lp5x.project.d930-lpddr5x-tsmc5ff12.ckt.rel.dwc_lpddr5xphy_txrxdq_ew.2.00a.macro",
        '97'  => "$TDATA/lpddr5x_ddr5_phy.lp5x.project.d930-lpddr5x-tsmc5ff12.ckt.rel.dwc_lpddr5xphy_zcalio_ew.2.00a.macro",
        '98'  => "$TDATA/ddr54.project.d809-ddr54-tsmc7ff18.ckt.rel.dwc_ddrphy_por.1.20a.macro",
        '98lib' => "$p4root/products/ddr54/project/d809-ddr54-tsmc7ff18/ckt/rel/dwc_ddrphy_por/1.20a/macro/timing/8M_2X_hv_1Ya_h_4Y_vhvh/",
    );
    #--------------------------------------------------------------------------
    # %t records the configuration details to run each test
    #--------------------------------------------------------------------------
    my %t  = ( 
        '1'=>{
            'description' => "Should PASS Cleanly!",
            'testScript'  =>"$RealScript",
            'testDataDir' => $TDATA,
            'scriptDir'   =>"$RealBin/../../bin",
            'scriptName'  =>"$scriptName",
            'product'     =>"lpddr54",
            'project'     =>"d890-lpddr54-tsmc5ff-12",
            'release'     =>"1.00a",
            'macro'       => "dwc_ddrphy_decapvddq_1by4x1_ns",
            'tech'        => "tsmc5ff-12",
            'lefObsLayers'=> "M0 M1 M2 M3 M4 M5 M6 M7 M8 M9 M10 M11 M12 OVERLAP",
            'lefPinLayers'=> "M0 M1 M2 M3 M4 M5 M6 M7 M8 M9 M10 M11 M12 OVERLAP",
            'PGlayers'    => 'M11 M12 MTOP MTOP-1',
            'bracket'     => 'square',
            'log'         => undef,
            'lef'         => undef,
            'liberty'     => "/u/${USER}/${DDR_DA_DEFAULT_P4WS}/depot/products/lpddr54/project/d890-lpddr54-tsmc5ff12/ckt/rel/dwc_ddrphy_utility_blocks/1.00a/macro/timing/12M_1X_h_1Xb_v_1Xe_h_1Ya_v_1Yb_h_4Y_vhvh_2Z_SHDMIM/lib_pg_lvf/dwc_ddrphy_utility_blocks_ff0p825vn40c_pg.lib.gz",
            'libertyNopg' => "/u/${USER}/${DDR_DA_DEFAULT_P4WS}/depot/products/lpddr54/project/d890-lpddr54-tsmc5ff12/ckt/rel/dwc_ddrphy_utility_blocks/1.00a/macro/timing/12M_1X_h_1Xb_v_1Xe_h_1Ya_v_1Yb_h_4Y_vhvh_2Z_SHDMIM/lib_lvf/dwc_ddrphy_utility_blocks_ff0p825vn40c.lib.gz",
            'extraArgs'   => "",
            'expect_fail' => FALSE,
        }, 
        '2'=>{
            # we expect that this should fail, so adjust the test to complain 
            # if it passes and ok if it fails. But; if it fails we really
            # should add code to make sure it's failing for the right reason,
            # don't want to miss other failures.
            'description' => "Doesn't detect the following : "
                            ."\n\t ZcalCompVOHDAC[0] missing from ffg0p825v150c_pg.lib, but in other 3 files ffg0p825v125c(_pg|).lib, ffg0p825v150c.lib, LEF"
                            ."\n\t VrefDacRef pin direction mismatch"
                            ."\n\t Mismatches for (0) bad BUS-BIT characters (1) Existence (2) Direction (3) Related Power (4) Area ",
            'testScript'  => "$RealScript",
            'testDataDir' => $TDATA,
            'scriptDir'   => "$RealBin/../../bin",
            'scriptName'  => "$scriptName",
            'product'     => "lddr54",
            'project'     => "dXXX",
            'release'     => "zcalana",
            'macro'       => "dwc_ddrphy_zcalana",
            'tech'        => "",
            'lefObsLayers'=> "",
            'lefPinLayers'=> "",
            'PGlayers'    => "",
            'bracket'     => 'square',
            'log'         => undef,
            'lef'         => "$TDATA/lpddr54.dXXX.zcalana/lef/dwc_ddrphy_zcalana_merged.lef",
            'liberty'     => [
                               "$TDATA/lpddr54.dXXX.zcalana/lib_pg/dwc_ddrphy_zcalana_13M_1X_h_1Xa_v_1Ya_h_5Y_vhvhv_2Yy2Z_ffg0p825v125c_pg.lib",
                               "$TDATA/lpddr54.dXXX.zcalana/lib_pg/dwc_ddrphy_zcalana_13M_1X_h_1Xa_v_1Ya_h_5Y_vhvhv_2Yy2Z_ffg0p825v150c_pg.lib",
                             ],
            'libertyNopg' => [
                               "$TDATA/lpddr54.dXXX.zcalana/lib/dwc_ddrphy_zcalana_13M_1X_h_1Xa_v_1Ya_h_5Y_vhvhv_2Yy2Z_ffg0p825v125c.lib",
                               "$TDATA/lpddr54.dXXX.zcalana/lib/dwc_ddrphy_zcalana_13M_1X_h_1Xa_v_1Ya_h_5Y_vhvhv_2Yy2Z_ffg0p825v150c.lib" ,
                             ],
            'extraArgs'   => "",
            'expect_fail'         => TRUE,
            'test_dir'            => "$RealBin",
            'logfile_name'        => 'alphaPinCheck.pl.log',
            'start_regex_strings' => [
                 "-I- Checking across all views for PG pin existence ...\n",
                 "-I- Checking across all views for pin existence ...\n",
                 "-I- Checking across all views for pin direction consistency...\n",
                 "-I- Checking across all views for type consistency...\n",
                 "-I- Checking across all views for related_power consistency...\n",
                 "-I- Checking across all views for related_ground consistency...\n",
                 "-I- Checking bracket consistency across all views;  All views must have \"square\" brackets\n",
                 "-I- Checking for macro area consistency\n",
            ],
            'end_regex_strings' => [
                 "-E- DIRTY!\n", 
                 "-E- DIRTY!\n", 
                 "-E- DIRTY!\n", 
                 "-I- CLEAN!\n",
                 "-E- DIRTY!\n", 
                 "-I- CLEAN!\n", 
                 "-I- CLEAN!\n",
                 "-E- DIRTY!\n",
            ],
            'expected_content' => [
                   "-I- PG pin 'VDD'\n"
                 . "-I- 	 missing in '../data/alphaPinCheck.pl/lpddr54.dXXX.zcalana/lib_pg/dwc_ddrphy_zcalana_13M_1X_h_1Xa_v_1Ya_h_5Y_vhvhv_2Yy2Z_ffg0p825v150c_pg.lib'\n"
                ,
                   "-I- Pin PwrOkVDD\n"
                 . "-I- 	 missing in ../data/alphaPinCheck.pl/lpddr54.dXXX.zcalana/lib_pg/dwc_ddrphy_zcalana_13M_1X_h_1Xa_v_1Ya_h_5Y_vhvhv_2Yy2Z_ffg0p825v150c_pg.lib\n"
                 . "-I- Pin ZCalCompVOHDAC[0]\n"
                 . "-I- 	 missing in ../data/alphaPinCheck.pl/lpddr54.dXXX.zcalana/lib_pg/dwc_ddrphy_zcalana_13M_1X_h_1Xa_v_1Ya_h_5Y_vhvhv_2Yy2Z_ffg0p825v150c_pg.lib\n"
                 . "-I- Pin csrZCalCompGainCurrAdj[1]\n"
                 . "-I- 	 missing in ../data/alphaPinCheck.pl/lpddr54.dXXX.zcalana/lef/dwc_ddrphy_zcalana_merged.lef\n",

                   "-I- Pin VrefDacRef:\n"
 	               . " \t../data/alphaPinCheck.pl/lpddr54.dXXX.zcalana/lib_pg/dwc_ddrphy_zcalana_13M_1X_h_1Xa_v_1Ya_h_5Y_vhvhv_2Yy2Z_ffg0p825v125c_pg.lib: input\n"
 	               . " \t../data/alphaPinCheck.pl/lpddr54.dXXX.zcalana/lib_pg/dwc_ddrphy_zcalana_13M_1X_h_1Xa_v_1Ya_h_5Y_vhvhv_2Yy2Z_ffg0p825v150c_pg.lib: output\n"
 	               . " \t../data/alphaPinCheck.pl/lpddr54.dXXX.zcalana/lib/dwc_ddrphy_zcalana_13M_1X_h_1Xa_v_1Ya_h_5Y_vhvhv_2Yy2Z_ffg0p825v125c.lib: input\n"
 	               . " \t../data/alphaPinCheck.pl/lpddr54.dXXX.zcalana/lib/dwc_ddrphy_zcalana_13M_1X_h_1Xa_v_1Ya_h_5Y_vhvhv_2Yy2Z_ffg0p825v150c.lib: input\n"
 	               . " \t../data/alphaPinCheck.pl/lpddr54.dXXX.zcalana/lef/dwc_ddrphy_zcalana_merged.lef: input\n"
                 . "-I- Pin ZCalAnaClk:\n"
 	               . " \t../data/alphaPinCheck.pl/lpddr54.dXXX.zcalana/lib_pg/dwc_ddrphy_zcalana_13M_1X_h_1Xa_v_1Ya_h_5Y_vhvhv_2Yy2Z_ffg0p825v125c_pg.lib: input\n"
 	               . " \t../data/alphaPinCheck.pl/lpddr54.dXXX.zcalana/lib_pg/dwc_ddrphy_zcalana_13M_1X_h_1Xa_v_1Ya_h_5Y_vhvhv_2Yy2Z_ffg0p825v150c_pg.lib: io\n"
 	               . " \t../data/alphaPinCheck.pl/lpddr54.dXXX.zcalana/lib/dwc_ddrphy_zcalana_13M_1X_h_1Xa_v_1Ya_h_5Y_vhvhv_2Yy2Z_ffg0p825v125c.lib: input\n"
 	               . " \t../data/alphaPinCheck.pl/lpddr54.dXXX.zcalana/lib/dwc_ddrphy_zcalana_13M_1X_h_1Xa_v_1Ya_h_5Y_vhvhv_2Yy2Z_ffg0p825v150c.lib: input\n"
 	               . " \t../data/alphaPinCheck.pl/lpddr54.dXXX.zcalana/lef/dwc_ddrphy_zcalana_merged.lef: input\n"
                 . "-I- Pin ZCalAnaEn:\n"
 	               . " \t../data/alphaPinCheck.pl/lpddr54.dXXX.zcalana/lib_pg/dwc_ddrphy_zcalana_13M_1X_h_1Xa_v_1Ya_h_5Y_vhvhv_2Yy2Z_ffg0p825v125c_pg.lib: output\n"
 	               . " \t../data/alphaPinCheck.pl/lpddr54.dXXX.zcalana/lib_pg/dwc_ddrphy_zcalana_13M_1X_h_1Xa_v_1Ya_h_5Y_vhvhv_2Yy2Z_ffg0p825v150c_pg.lib: input\n"
 	               . " \t../data/alphaPinCheck.pl/lpddr54.dXXX.zcalana/lib/dwc_ddrphy_zcalana_13M_1X_h_1Xa_v_1Ya_h_5Y_vhvhv_2Yy2Z_ffg0p825v125c.lib: input\n"
 	               . " \t../data/alphaPinCheck.pl/lpddr54.dXXX.zcalana/lib/dwc_ddrphy_zcalana_13M_1X_h_1Xa_v_1Ya_h_5Y_vhvhv_2Yy2Z_ffg0p825v150c.lib: input\n"
 	               . " \t../data/alphaPinCheck.pl/lpddr54.dXXX.zcalana/lef/dwc_ddrphy_zcalana_merged.lef: input\n"
                 . "-I- Pin ZCalCompOut:\n"
 	               . " \t../data/alphaPinCheck.pl/lpddr54.dXXX.zcalana/lib_pg/dwc_ddrphy_zcalana_13M_1X_h_1Xa_v_1Ya_h_5Y_vhvhv_2Yy2Z_ffg0p825v125c_pg.lib: io\n"
 	               . " \t../data/alphaPinCheck.pl/lpddr54.dXXX.zcalana/lib_pg/dwc_ddrphy_zcalana_13M_1X_h_1Xa_v_1Ya_h_5Y_vhvhv_2Yy2Z_ffg0p825v150c_pg.lib: output\n"
 	               . " \t../data/alphaPinCheck.pl/lpddr54.dXXX.zcalana/lib/dwc_ddrphy_zcalana_13M_1X_h_1Xa_v_1Ya_h_5Y_vhvhv_2Yy2Z_ffg0p825v125c.lib: output\n"
 	               . " \t../data/alphaPinCheck.pl/lpddr54.dXXX.zcalana/lib/dwc_ddrphy_zcalana_13M_1X_h_1Xa_v_1Ya_h_5Y_vhvhv_2Yy2Z_ffg0p825v150c.lib: output\n"
 	               . " \t../data/alphaPinCheck.pl/lpddr54.dXXX.zcalana/lef/dwc_ddrphy_zcalana_merged.lef: output\n",
                 
                   undef,
                   "-I- Pin ZCalAnaClk:\n"
 	               . " \t../data/alphaPinCheck.pl/lpddr54.dXXX.zcalana/lib_pg/dwc_ddrphy_zcalana_13M_1X_h_1Xa_v_1Ya_h_5Y_vhvhv_2Yy2Z_ffg0p825v125c_pg.lib: VDD\n"
 	               . " \t../data/alphaPinCheck.pl/lpddr54.dXXX.zcalana/lib_pg/dwc_ddrphy_zcalana_13M_1X_h_1Xa_v_1Ya_h_5Y_vhvhv_2Yy2Z_ffg0p825v150c_pg.lib: VDDQ\n"
                 . "-I- Pin ZCalAnaEn:\n"
 	               . " \t../data/alphaPinCheck.pl/lpddr54.dXXX.zcalana/lib_pg/dwc_ddrphy_zcalana_13M_1X_h_1Xa_v_1Ya_h_5Y_vhvhv_2Yy2Z_ffg0p825v125c_pg.lib: VDD\n"
 	               . " \t../data/alphaPinCheck.pl/lpddr54.dXXX.zcalana/lib_pg/dwc_ddrphy_zcalana_13M_1X_h_1Xa_v_1Ya_h_5Y_vhvhv_2Yy2Z_ffg0p825v150c_pg.lib: VDDQ\n"
                 . "-I- Pin ZCalCompEn:\n"
 	               . " \t../data/alphaPinCheck.pl/lpddr54.dXXX.zcalana/lib_pg/dwc_ddrphy_zcalana_13M_1X_h_1Xa_v_1Ya_h_5Y_vhvhv_2Yy2Z_ffg0p825v125c_pg.lib: VDD\n"
 	               . " \t../data/alphaPinCheck.pl/lpddr54.dXXX.zcalana/lib_pg/dwc_ddrphy_zcalana_13M_1X_h_1Xa_v_1Ya_h_5Y_vhvhv_2Yy2Z_ffg0p825v150c_pg.lib: VDDQ\n"
                 . "-I- Pin ZCalCompOut:\n"
 	               . " \t../data/alphaPinCheck.pl/lpddr54.dXXX.zcalana/lib_pg/dwc_ddrphy_zcalana_13M_1X_h_1Xa_v_1Ya_h_5Y_vhvhv_2Yy2Z_ffg0p825v125c_pg.lib: VDD\n"
 	               . " \t../data/alphaPinCheck.pl/lpddr54.dXXX.zcalana/lib_pg/dwc_ddrphy_zcalana_13M_1X_h_1Xa_v_1Ya_h_5Y_vhvhv_2Yy2Z_ffg0p825v150c_pg.lib: VDDQ\n"
                 . "-I- Pin ZCalCompVOHDAC[1]:\n"
 	               . " \t../data/alphaPinCheck.pl/lpddr54.dXXX.zcalana/lib_pg/dwc_ddrphy_zcalana_13M_1X_h_1Xa_v_1Ya_h_5Y_vhvhv_2Yy2Z_ffg0p825v125c_pg.lib: VDD\n"
 	               . " \t../data/alphaPinCheck.pl/lpddr54.dXXX.zcalana/lib_pg/dwc_ddrphy_zcalana_13M_1X_h_1Xa_v_1Ya_h_5Y_vhvhv_2Yy2Z_ffg0p825v150c_pg.lib: VDDQ\n"
                 . "-I- Pin ZCalCompVOHDAC[2]:\n"
 	               . " \t../data/alphaPinCheck.pl/lpddr54.dXXX.zcalana/lib_pg/dwc_ddrphy_zcalana_13M_1X_h_1Xa_v_1Ya_h_5Y_vhvhv_2Yy2Z_ffg0p825v125c_pg.lib: VDD\n"
 	               . " \t../data/alphaPinCheck.pl/lpddr54.dXXX.zcalana/lib_pg/dwc_ddrphy_zcalana_13M_1X_h_1Xa_v_1Ya_h_5Y_vhvhv_2Yy2Z_ffg0p825v150c_pg.lib: VDDQ\n"
                 . "-I- Pin ZCalCompVOHDAC[3]:\n"
 	               . " \t../data/alphaPinCheck.pl/lpddr54.dXXX.zcalana/lib_pg/dwc_ddrphy_zcalana_13M_1X_h_1Xa_v_1Ya_h_5Y_vhvhv_2Yy2Z_ffg0p825v125c_pg.lib: VDD\n"
 	               . " \t../data/alphaPinCheck.pl/lpddr54.dXXX.zcalana/lib_pg/dwc_ddrphy_zcalana_13M_1X_h_1Xa_v_1Ya_h_5Y_vhvhv_2Yy2Z_ffg0p825v150c_pg.lib: VDDQ\n"
                 . "-I- Pin ZCalCompVOHDAC[4]:\n"
 	               . " \t../data/alphaPinCheck.pl/lpddr54.dXXX.zcalana/lib_pg/dwc_ddrphy_zcalana_13M_1X_h_1Xa_v_1Ya_h_5Y_vhvhv_2Yy2Z_ffg0p825v125c_pg.lib: VDD\n"
 	               . " \t../data/alphaPinCheck.pl/lpddr54.dXXX.zcalana/lib_pg/dwc_ddrphy_zcalana_13M_1X_h_1Xa_v_1Ya_h_5Y_vhvhv_2Yy2Z_ffg0p825v150c_pg.lib: VDDQ\n"
                 . "-I- Pin ZCalCompVOHDAC[5]:\n"
 	               . " \t../data/alphaPinCheck.pl/lpddr54.dXXX.zcalana/lib_pg/dwc_ddrphy_zcalana_13M_1X_h_1Xa_v_1Ya_h_5Y_vhvhv_2Yy2Z_ffg0p825v125c_pg.lib: VDD\n"
 	               . " \t../data/alphaPinCheck.pl/lpddr54.dXXX.zcalana/lib_pg/dwc_ddrphy_zcalana_13M_1X_h_1Xa_v_1Ya_h_5Y_vhvhv_2Yy2Z_ffg0p825v150c_pg.lib: VDDQ\n"
                 . "-I- Pin ZCalCompVOHDAC[6]:\n"
 	               . " \t../data/alphaPinCheck.pl/lpddr54.dXXX.zcalana/lib_pg/dwc_ddrphy_zcalana_13M_1X_h_1Xa_v_1Ya_h_5Y_vhvhv_2Yy2Z_ffg0p825v125c_pg.lib: VDD\n"
 	               . " \t../data/alphaPinCheck.pl/lpddr54.dXXX.zcalana/lib_pg/dwc_ddrphy_zcalana_13M_1X_h_1Xa_v_1Ya_h_5Y_vhvhv_2Yy2Z_ffg0p825v150c_pg.lib: VDDQ\n"
                 . "-I- Pin ZCalDACRangeSel:\n"
 	               . " \t../data/alphaPinCheck.pl/lpddr54.dXXX.zcalana/lib_pg/dwc_ddrphy_zcalana_13M_1X_h_1Xa_v_1Ya_h_5Y_vhvhv_2Yy2Z_ffg0p825v125c_pg.lib: VDD\n"
 	               . " \t../data/alphaPinCheck.pl/lpddr54.dXXX.zcalana/lib_pg/dwc_ddrphy_zcalana_13M_1X_h_1Xa_v_1Ya_h_5Y_vhvhv_2Yy2Z_ffg0p825v150c_pg.lib: VDDQ\n"
                 . "-I- Pin ZCalPDEn:\n"
 	               . " \t../data/alphaPinCheck.pl/lpddr54.dXXX.zcalana/lib_pg/dwc_ddrphy_zcalana_13M_1X_h_1Xa_v_1Ya_h_5Y_vhvhv_2Yy2Z_ffg0p825v125c_pg.lib: VDD\n"
 	               . " \t../data/alphaPinCheck.pl/lpddr54.dXXX.zcalana/lib_pg/dwc_ddrphy_zcalana_13M_1X_h_1Xa_v_1Ya_h_5Y_vhvhv_2Yy2Z_ffg0p825v150c_pg.lib: VDDQ\n"
                 . "-I- Pin ZCalPUEn:\n"
 	               . " \t../data/alphaPinCheck.pl/lpddr54.dXXX.zcalana/lib_pg/dwc_ddrphy_zcalana_13M_1X_h_1Xa_v_1Ya_h_5Y_vhvhv_2Yy2Z_ffg0p825v125c_pg.lib: VDD\n"
 	               . " \t../data/alphaPinCheck.pl/lpddr54.dXXX.zcalana/lib_pg/dwc_ddrphy_zcalana_13M_1X_h_1Xa_v_1Ya_h_5Y_vhvhv_2Yy2Z_ffg0p825v150c_pg.lib: VDDQ\n"
                 . "-I- Pin csrZCalCompBiasBypassEn:\n"
 	               . " \t../data/alphaPinCheck.pl/lpddr54.dXXX.zcalana/lib_pg/dwc_ddrphy_zcalana_13M_1X_h_1Xa_v_1Ya_h_5Y_vhvhv_2Yy2Z_ffg0p825v125c_pg.lib: VDD\n"
 	               . " \t../data/alphaPinCheck.pl/lpddr54.dXXX.zcalana/lib_pg/dwc_ddrphy_zcalana_13M_1X_h_1Xa_v_1Ya_h_5Y_vhvhv_2Yy2Z_ffg0p825v150c_pg.lib: VDDQ\n"
                 . "-I- Pin csrZCalCompBiasPowerUp:\n"
 	               . " \t../data/alphaPinCheck.pl/lpddr54.dXXX.zcalana/lib_pg/dwc_ddrphy_zcalana_13M_1X_h_1Xa_v_1Ya_h_5Y_vhvhv_2Yy2Z_ffg0p825v125c_pg.lib: VDD\n"
 	               . " \t../data/alphaPinCheck.pl/lpddr54.dXXX.zcalana/lib_pg/dwc_ddrphy_zcalana_13M_1X_h_1Xa_v_1Ya_h_5Y_vhvhv_2Yy2Z_ffg0p825v150c_pg.lib: VDDQ\n"
                 . "-I- Pin csrZCalCompGainCurrAdj[0]:\n"
 	               . " \t../data/alphaPinCheck.pl/lpddr54.dXXX.zcalana/lib_pg/dwc_ddrphy_zcalana_13M_1X_h_1Xa_v_1Ya_h_5Y_vhvhv_2Yy2Z_ffg0p825v125c_pg.lib: VDD\n"
 	               . " \t../data/alphaPinCheck.pl/lpddr54.dXXX.zcalana/lib_pg/dwc_ddrphy_zcalana_13M_1X_h_1Xa_v_1Ya_h_5Y_vhvhv_2Yy2Z_ffg0p825v150c_pg.lib: VDDQ\n"
                 . "-I- Pin csrZCalCompGainCurrAdj[1]:\n"
 	               . " \t../data/alphaPinCheck.pl/lpddr54.dXXX.zcalana/lib_pg/dwc_ddrphy_zcalana_13M_1X_h_1Xa_v_1Ya_h_5Y_vhvhv_2Yy2Z_ffg0p825v125c_pg.lib: VDD\n"
 	               . " \t../data/alphaPinCheck.pl/lpddr54.dXXX.zcalana/lib_pg/dwc_ddrphy_zcalana_13M_1X_h_1Xa_v_1Ya_h_5Y_vhvhv_2Yy2Z_ffg0p825v150c_pg.lib: VDDQ\n"
                 . "-I- Pin csrZCalCompGainCurrAdj[2]:\n"
 	               . " \t../data/alphaPinCheck.pl/lpddr54.dXXX.zcalana/lib_pg/dwc_ddrphy_zcalana_13M_1X_h_1Xa_v_1Ya_h_5Y_vhvhv_2Yy2Z_ffg0p825v125c_pg.lib: VDD\n"
 	               . " \t../data/alphaPinCheck.pl/lpddr54.dXXX.zcalana/lib_pg/dwc_ddrphy_zcalana_13M_1X_h_1Xa_v_1Ya_h_5Y_vhvhv_2Yy2Z_ffg0p825v150c_pg.lib: VDDQ\n"
                 . "-I- Pin csrZCalCompGainCurrAdj[3]:\n"
 	               . " \t../data/alphaPinCheck.pl/lpddr54.dXXX.zcalana/lib_pg/dwc_ddrphy_zcalana_13M_1X_h_1Xa_v_1Ya_h_5Y_vhvhv_2Yy2Z_ffg0p825v125c_pg.lib: VDD\n"
 	               . " \t../data/alphaPinCheck.pl/lpddr54.dXXX.zcalana/lib_pg/dwc_ddrphy_zcalana_13M_1X_h_1Xa_v_1Ya_h_5Y_vhvhv_2Yy2Z_ffg0p825v150c_pg.lib: VDDQ\n"
                 . "-I- Pin csrZCalCompGainCurrAdj[4]:\n"
 	               . " \t../data/alphaPinCheck.pl/lpddr54.dXXX.zcalana/lib_pg/dwc_ddrphy_zcalana_13M_1X_h_1Xa_v_1Ya_h_5Y_vhvhv_2Yy2Z_ffg0p825v125c_pg.lib: VDD\n"
 	               . " \t../data/alphaPinCheck.pl/lpddr54.dXXX.zcalana/lib_pg/dwc_ddrphy_zcalana_13M_1X_h_1Xa_v_1Ya_h_5Y_vhvhv_2Yy2Z_ffg0p825v150c_pg.lib: VDDQ\n"
                 . "-I- Pin csrZCalCompGainCurrAdj[5]:\n"
 	               . " \t../data/alphaPinCheck.pl/lpddr54.dXXX.zcalana/lib_pg/dwc_ddrphy_zcalana_13M_1X_h_1Xa_v_1Ya_h_5Y_vhvhv_2Yy2Z_ffg0p825v125c_pg.lib: VDD\n"
 	               . " \t../data/alphaPinCheck.pl/lpddr54.dXXX.zcalana/lib_pg/dwc_ddrphy_zcalana_13M_1X_h_1Xa_v_1Ya_h_5Y_vhvhv_2Yy2Z_ffg0p825v150c_pg.lib: VDDQ\n"
                 . "-I- Pin csrZCalCompGainCurrAdj[6]:\n"
 	               . " \t../data/alphaPinCheck.pl/lpddr54.dXXX.zcalana/lib_pg/dwc_ddrphy_zcalana_13M_1X_h_1Xa_v_1Ya_h_5Y_vhvhv_2Yy2Z_ffg0p825v125c_pg.lib: VDD\n"
 	               . " \t../data/alphaPinCheck.pl/lpddr54.dXXX.zcalana/lib_pg/dwc_ddrphy_zcalana_13M_1X_h_1Xa_v_1Ya_h_5Y_vhvhv_2Yy2Z_ffg0p825v150c_pg.lib: VDDQ\n"
                 . "-I- Pin csrZCalCompGainCurrAdj[7]:\n"
 	               . " \t../data/alphaPinCheck.pl/lpddr54.dXXX.zcalana/lib_pg/dwc_ddrphy_zcalana_13M_1X_h_1Xa_v_1Ya_h_5Y_vhvhv_2Yy2Z_ffg0p825v125c_pg.lib: VDD\n"
 	               . " \t../data/alphaPinCheck.pl/lpddr54.dXXX.zcalana/lib_pg/dwc_ddrphy_zcalana_13M_1X_h_1Xa_v_1Ya_h_5Y_vhvhv_2Yy2Z_ffg0p825v150c_pg.lib: VDDQ\n"
                 . "-I- Pin csrZCalCompGainResAdj:\n"
 	               . " \t../data/alphaPinCheck.pl/lpddr54.dXXX.zcalana/lib_pg/dwc_ddrphy_zcalana_13M_1X_h_1Xa_v_1Ya_h_5Y_vhvhv_2Yy2Z_ffg0p825v125c_pg.lib: VDD\n"
 	               . " \t../data/alphaPinCheck.pl/lpddr54.dXXX.zcalana/lib_pg/dwc_ddrphy_zcalana_13M_1X_h_1Xa_v_1Ya_h_5Y_vhvhv_2Yy2Z_ffg0p825v150c_pg.lib: VDDQ\n"
                 . "-I- Pin csrZCalCompVrefDAC[0]:\n"
 	               . " \t../data/alphaPinCheck.pl/lpddr54.dXXX.zcalana/lib_pg/dwc_ddrphy_zcalana_13M_1X_h_1Xa_v_1Ya_h_5Y_vhvhv_2Yy2Z_ffg0p825v125c_pg.lib: VDD\n"
 	               . " \t../data/alphaPinCheck.pl/lpddr54.dXXX.zcalana/lib_pg/dwc_ddrphy_zcalana_13M_1X_h_1Xa_v_1Ya_h_5Y_vhvhv_2Yy2Z_ffg0p825v150c_pg.lib: VDDQ\n"
                 . "-I- Pin csrZCalCompVrefDAC[1]:\n"
 	               . " \t../data/alphaPinCheck.pl/lpddr54.dXXX.zcalana/lib_pg/dwc_ddrphy_zcalana_13M_1X_h_1Xa_v_1Ya_h_5Y_vhvhv_2Yy2Z_ffg0p825v125c_pg.lib: VDD\n"
 	               . " \t../data/alphaPinCheck.pl/lpddr54.dXXX.zcalana/lib_pg/dwc_ddrphy_zcalana_13M_1X_h_1Xa_v_1Ya_h_5Y_vhvhv_2Yy2Z_ffg0p825v150c_pg.lib: VDDQ\n"
                 . "-I- Pin csrZCalCompVrefDAC[2]:\n"
 	               . " \t../data/alphaPinCheck.pl/lpddr54.dXXX.zcalana/lib_pg/dwc_ddrphy_zcalana_13M_1X_h_1Xa_v_1Ya_h_5Y_vhvhv_2Yy2Z_ffg0p825v125c_pg.lib: VDD\n"
 	               . " \t../data/alphaPinCheck.pl/lpddr54.dXXX.zcalana/lib_pg/dwc_ddrphy_zcalana_13M_1X_h_1Xa_v_1Ya_h_5Y_vhvhv_2Yy2Z_ffg0p825v150c_pg.lib: VDDQ\n"
                 . "-I- Pin csrZCalCompVrefDAC[3]:\n"
 	               . " \t../data/alphaPinCheck.pl/lpddr54.dXXX.zcalana/lib_pg/dwc_ddrphy_zcalana_13M_1X_h_1Xa_v_1Ya_h_5Y_vhvhv_2Yy2Z_ffg0p825v125c_pg.lib: VDD\n"
 	               . " \t../data/alphaPinCheck.pl/lpddr54.dXXX.zcalana/lib_pg/dwc_ddrphy_zcalana_13M_1X_h_1Xa_v_1Ya_h_5Y_vhvhv_2Yy2Z_ffg0p825v150c_pg.lib: VDDQ\n"
                 . "-I- Pin csrZCalCompVrefDAC[4]:\n"
 	               . " \t../data/alphaPinCheck.pl/lpddr54.dXXX.zcalana/lib_pg/dwc_ddrphy_zcalana_13M_1X_h_1Xa_v_1Ya_h_5Y_vhvhv_2Yy2Z_ffg0p825v125c_pg.lib: VDD\n"
 	               . " \t../data/alphaPinCheck.pl/lpddr54.dXXX.zcalana/lib_pg/dwc_ddrphy_zcalana_13M_1X_h_1Xa_v_1Ya_h_5Y_vhvhv_2Yy2Z_ffg0p825v150c_pg.lib: VDDQ\n"
                 . "-I- Pin csrZCalCompVrefDAC[5]:\n"
 	               . " \t../data/alphaPinCheck.pl/lpddr54.dXXX.zcalana/lib_pg/dwc_ddrphy_zcalana_13M_1X_h_1Xa_v_1Ya_h_5Y_vhvhv_2Yy2Z_ffg0p825v125c_pg.lib: VDD\n"
 	               . " \t../data/alphaPinCheck.pl/lpddr54.dXXX.zcalana/lib_pg/dwc_ddrphy_zcalana_13M_1X_h_1Xa_v_1Ya_h_5Y_vhvhv_2Yy2Z_ffg0p825v150c_pg.lib: VDDQ\n"
                 . "-I- Pin csrZCalCompVrefDAC[6]:\n"
 	               . " \t../data/alphaPinCheck.pl/lpddr54.dXXX.zcalana/lib_pg/dwc_ddrphy_zcalana_13M_1X_h_1Xa_v_1Ya_h_5Y_vhvhv_2Yy2Z_ffg0p825v125c_pg.lib: VDD\n"
 	               . " \t../data/alphaPinCheck.pl/lpddr54.dXXX.zcalana/lib_pg/dwc_ddrphy_zcalana_13M_1X_h_1Xa_v_1Ya_h_5Y_vhvhv_2Yy2Z_ffg0p825v150c_pg.lib: VDDQ\n",
                  undef,
                  undef,
                    "-I- Macro area disagreement:\n"
                  . "-I- 	../data/alphaPinCheck.pl/lpddr54.dXXX.zcalana/lib_pg/dwc_ddrphy_zcalana_13M_1X_h_1Xa_v_1Ya_h_5Y_vhvhv_2Yy2Z_ffg0p825v125c_pg.lib: 7387.200000\n"
                  . "-I- 	../data/alphaPinCheck.pl/lpddr54.dXXX.zcalana/lib_pg/dwc_ddrphy_zcalana_13M_1X_h_1Xa_v_1Ya_h_5Y_vhvhv_2Yy2Z_ffg0p825v150c_pg.lib: 7300.000000\n"
                  . "-I- 	../data/alphaPinCheck.pl/lpddr54.dXXX.zcalana/lib/dwc_ddrphy_zcalana_13M_1X_h_1Xa_v_1Ya_h_5Y_vhvhv_2Yy2Z_ffg0p825v125c.lib: 7387.200000\n"
                  . "-I- 	../data/alphaPinCheck.pl/lpddr54.dXXX.zcalana/lib/dwc_ddrphy_zcalana_13M_1X_h_1Xa_v_1Ya_h_5Y_vhvhv_2Yy2Z_ffg0p825v150c.lib: 7387.200000\n"
                  . "-I- 	../data/alphaPinCheck.pl/lpddr54.dXXX.zcalana/lef/dwc_ddrphy_zcalana_merged.lef: 7387.200000\n",
            ],

        }, 
        '3'=>{
            'description' => "Pin Mismatches: Csr_VrefDAC[0]",
            'testScript'  => "$RealScript",
            'testDataDir' => $TDATA,
            'scriptDir'   => "$RealBin/../../bin",
            'scriptName'  => "$scriptName",
            'product'     => "ddr54",
            'project'     => "d809",
            'release'     => "vrefglobal",
            'macro'       => "dwc_ddrphy_vrefglobal",
            'tech'        => "",
            'lefObsLayers'=> "",
            'lefPinLayers'=> "",
            'PGlayers'    => "",
            'bracket'     => 'square',
            'log'         => undef,
            'lef'         => "$TDATA/ddr54.d809.vrefglobal/lef/dwc_ddrphy_vrefglobal_merged.lef",
            'libertyNopg' => "$TDATA/ddr54.d809.vrefglobal/lib/dwc_ddrphy_vrefglobal_15M_2X_hv_1Ya_h_5Y_vhvhv_2Yy2Yx2R_ffg0p935vn40c.lib",
            'liberty'     => [
                               "$TDATA/ddr54.d809.vrefglobal/lib_pg/dwc_ddrphy_vrefglobal_15M_2X_hv_1Ya_h_5Y_vhvhv_2Yy2Yx2R_ffg0p935vn40c_pg.lib",
                               "$TDATA/ddr54.d809.vrefglobal/lib_pg/dwc_ddrphy_vrefglobal_15M_2X_hv_1Ya_h_5Y_vhvhv_2Yy2Yx2R_ssg0p765v0c_pg.lib",
                             ],
            'extraArgs'   => "",
            'expect_fail' => TRUE,
            'test_dir'            => $RealBin,
            'logfile_name'        => 'alphaPinCheck.pl.log',
            'start_regex_strings' => [
                 "-I- Checking across all views for PG pin existence ...\n",
                 "-I- Checking across all views for pin existence ...\n",
                 "-I- Checking across all views for pin direction consistency...\n",
                 "-I- Checking across all views for type consistency...\n",
                 "-I- Checking across all views for related_power consistency...\n",
                 "-I- Checking across all views for related_ground consistency...\n",
                 "-I- Checking bracket consistency across all views;  All views must have \"square\" brackets\n",
                 "-I- Checking for macro area consistency\n",
            ],
            'end_regex_strings' => [
                 "-I- CLEAN!\n", "-E- DIRTY!\n", "-I- CLEAN!\n", "-I- CLEAN!\n",
                 "-I- CLEAN!\n", "-I- CLEAN!\n", "-I- CLEAN!\n", "-I- CLEAN!\n",
            ],
            'expected_content' => [
                 undef,
                 "-I- Pin Csr_VrefDAC[0]\n"
               . "-I- 	 missing in ../data/alphaPinCheck.pl/ddr54.d809.vrefglobal/lib_pg/dwc_ddrphy_vrefglobal_15M_2X_hv_1Ya_h_5Y_vhvhv_2Yy2Yx2R_ffg0p935vn40c_pg.lib\n"
            ],
        }, 
        '4'=>{
            'description' => "Pin Direction Consistency Mismatches",
            'testScript'  => "$RealScript",
            'testDataDir' => $TDATA,
            'scriptDir'   => "$RealBin/../../bin",
            'scriptName'  => "$scriptName",
            'product'     => "lpddr54",
            'project'     => "dXXX",
            'release'     => "vrefdacref",
            'macro'       => "dwc_ddrphy_vrefdacref",
            'tech'        => "",
            'lefObsLayers'=> "",
            'lefPinLayers'=> "",
            'PGlayers'    => "",
            'bracket'     => 'square',
            'log'         => undef,
            'lef'         => "$TDATA/lpddr54.dXXX.vrefdacref/lef/dwc_ddrphy_vrefdacref_merged.lef",
            'libertyNopg' => "$TDATA/lpddr54.dXXX.vrefdacref/lib/dwc_ddrphy_vrefdacref_13M_1X_h_1Xa_v_1Ya_h_5Y_vhvhv_2Yy2Z_ssg0p675v0c.lib",
            'liberty'     => [
                               "$TDATA/lpddr54.dXXX.vrefdacref/lib_pg/dwc_ddrphy_vrefdacref_13M_1X_h_1Xa_v_1Ya_h_5Y_vhvhv_2Yy2Z_ffg0p935v125c_pg.lib",
                               "$TDATA/lpddr54.dXXX.vrefdacref/lib_pg/dwc_ddrphy_vrefdacref_13M_1X_h_1Xa_v_1Ya_h_5Y_vhvhv_2Yy2Z_ssg0p675v0c_pg.lib",
                             ],
            'extraArgs'   => "",
            'expect_fail' => TRUE,
        }, 
        '5'=>{
            'description' => "Pin Related Power Mismatches ...",
            'testScript'  => "$RealScript",
            'testDataDir' => "$TDATA",
            'scriptDir'   => "$RealBin/../../bin",
            'scriptName'  => "$scriptName",
            'product'     => "ddr54",
            'project'     => "dXXX",
            'release'     => "por",
            'macro'       => "dwc_ddrphy_por",
            'tech'        => "",
            'lefObsLayers'=> "",
            'lefPinLayers'=> "",
            'PGlayers'    => "",
            'bracket'     => 'square',
            'log'         => undef,
            'lef'         => "$TDATA/ddr54.dXXX.por/lef/dwc_ddrphy_por_merged.lef",
            'libertyNopg' => "$TDATA/ddr54.dXXX.por/lib_pg/dwc_ddrphy_por_18M_4Mx_4Dx_4Hx_2Bx_2Gx_2UTM_ILB_fsg0p675vn40c.lib",
            'liberty'     => [
                               "$TDATA/ddr54.dXXX.por/lib_pg/dwc_ddrphy_por_18M_4Mx_4Dx_4Hx_2Bx_2Gx_2UTM_ILB_fsg0p675vn40c_pg.lib",
                               "$TDATA/ddr54.dXXX.por/lib_pg/dwc_ddrphy_por_18M_4Mx_4Dx_4Hx_2Bx_2Gx_2UTM_ILB_sspg0p825v125c_pg.lib",
                             ],
            'extraArgs'   => "",
            'expect_fail' => TRUE,
        }, 
#-------------------------------------------------------------------------------------------------
# old above -- excpet #1
#-------------------------------------------------------------------------------------------------
# new below
#-------------------------------------------------------------------------------------------------
        '88'=>{
            'description' => "New Issue ... see P10020416-40828"
                            . "\n89 might have uncovered a different issue since the script" 
                            . "\nis supposed to compare lef vs. lib in addition to lib vs. lib" 
                            . "\nit should have still reported it " ,
            'testScript'  => "$RealScript",
            'testDataDir' => $TDATA,
            'scriptDir'   => "$RealBin/../../bin",
            'scriptName'  => "$scriptName",
            'product'     => "",
            'project'     => "",
            'release'     => "",
            'macro'       => "dwc_lpddr5xphy_txrxdq_ew",
            #'tech'        => "ss7hpp-18",
            'lefObsLayers'=> '',
            'lefPinLayers'=> '',
            'PGlayers'    => '',
            'bracket'     => 'square',
            'log'         => undef,
            'cdl'         => undef,
            'gds'         => undef,
            'pinCSV'      => undef,
            'dp88'        =>  "$TDATA/QA_test_plan.QA_testbenches.alphaPincheck.alphaPinCheck_002.QA_dwc_lpddr5xphy_txrxdq_ew_lppddr5x.lef.dwc_lpddr5xphy_txrxdq_ew_merged.lef",
            'lef'         =>  "$DP{88}.lef.dwc_lpddr5xphy_txrxdq_ew_merged.lef",
            'libertyNopg' =>  "$DP{88}.lib.dwc_lpddr5xphy_txrxdq_ew_15M_1X_h_1Xb_v_1Xe_h_1Ya_v_1Yb_h_5Y_vhvhv_2Yy2Z_ffgnp0p715v0c.lib",
            'liberty'     => [
                              "$DP{88}.lib_pg.dwc_lpddr5xphy_txrxdq_ew_15M_1X_h_1Xb_v_1Xe_h_1Ya_v_1Yb_h_5Y_vhvhv_2Yy2Z_ffgnp0p715v0c_pg.lib",
                             ],
            'extraArgs'   => "",
            'expect_fail' => FALSE,
            'test_dir'            => $RealBin,
            'logfile_name'        => 'alphaPinCheck.pl.log',
            'start_regex_strings' => [
                 "-I- Checking across all views for PG pin existence ...\n",
                 "-I- Checking across all views for pin existence ...\n",
                 "-I- Checking across all views for pin direction consistency...\n",
                 "-I- Checking across all views for type consistency...\n",
                 "-I- Checking across all views for related_power consistency...\n",
                 "-I- Checking across all views for related_ground consistency...\n",
                 "-I- Checking bracket consistency across all views;  All views must have \"square\" brackets\n",
                 "-I- Checking for macro area consistency\n",
            ],
            'end_regex_strings' => [
                 "-I- CLEAN!\n", "-I- CLEAN!\n", 
                 "-I- CLEAN!\n", "-I- CLEAN!\n", 
                 "-I- CLEAN!\n", "-I- CLEAN!\n", 
                 "-I- CLEAN!\n", "-I- CLEAN!\n",
            ],
            'expected_content' => [
                 undef, undef, undef, undef, 
                 undef, undef, undef, undef,
            ],
        },        
        '89'=>{
            'description' => "PG Pin missing ... see P10020416-40828"
                            ."\n\t VDDQ is not a pg_pin in one of the two libs" 
                            ,
            'testScript'  => "$RealScript",
            'testDataDir' => $TDATA,
            'scriptDir'   => "$RealBin/../../bin",
            'scriptName'  => "$scriptName",
            'product'     => "",
            'project'     => "",
            'release'     => "",
            'macro'       => "dwc_lpddr5xphy_txrxdq_ew",
            #'tech'        => "ss7hpp-18",
            'lefObsLayers'=> '',
            'lefPinLayers'=> '',
            'PGlayers'    => '',
            'bracket'     => 'square',
            'log'         => undef,
            'cdl'         => undef,
            'gds'         => undef,
            'pinCSV'      => undef,
            'dp89'        =>  "$TDATA/QA_test_plan.QA_testbenches.alphaPincheck.alphaPinCheck_002.QA_dwc_lpddr5xphy_txrxdq_ew_lppddr5x.lef.dwc_lpddr5xphy_txrxdq_ew_merged.lef",
            'lef'         =>  "$DP{89}.lef.dwc_lpddr5xphy_txrxdq_ew_merged.lef",
            'libertyNopg' =>  "$DP{89}.lib.dwc_lpddr5xphy_txrxdq_ew_15M_1X_h_1Xb_v_1Xe_h_1Ya_v_1Yb_h_5Y_vhvhv_2Yy2Z_ffgnp0p715v0c.lib",
            'liberty'     => [
                              "$DP{89}.lib_pg.dwc_lpddr5xphy_txrxdq_ew_15M_1X_h_1Xb_v_1Xe_h_1Ya_v_1Yb_h_5Y_vhvhv_2Yy2Z_ffgnp0p6v85c_pg.lib",
                              "$DP{89}.lib_pg.dwc_lpddr5xphy_txrxdq_ew_15M_1X_h_1Xb_v_1Xe_h_1Ya_v_1Yb_h_5Y_vhvhv_2Yy2Z_ffgnp0p715v0c_pg.lib",
                             ],
            'extraArgs'   => "",
            'expect_fail' => TRUE,
            'test_dir'            => $RealBin,
            'logfile_name'        => 'alphaPinCheck.pl.log',
            'start_regex_strings' => [
                 "-I- Checking across all views for PG pin existence ...\n",
                 "-I- Checking across all views for pin existence ...\n",
                 "-I- Checking across all views for pin direction consistency...\n",
                 "-I- Checking across all views for type consistency...\n",
                 "-I- Checking across all views for related_power consistency...\n",
                 "-I- Checking across all views for related_ground consistency...\n",
                 "-I- Checking bracket consistency across all views;  All views must have \"square\" brackets\n",
                 "-I- Checking for macro area consistency\n",
            ],
            'end_regex_strings' => [
                 "-E- DIRTY!\n", "-I- CLEAN!\n", 
                 "-I- CLEAN!\n", "-I- CLEAN!\n", "-E- DIRTY!\n",
                 "-I- CLEAN!\n", "-I- CLEAN!\n", "-I- CLEAN!\n",
            ],
            'expected_content' => [
#                undef,
                 "-I- PG pin 'VDDQ'\n" .
                "-I- 	 missing in '../data/alphaPinCheck.pl/QA_test_plan.QA_testbenches.alphaPincheck.alphaPinCheck_002.QA_dwc_lpddr5xphy_txrxdq_ew_lppddr5x.lib_pg.dwc_lpddr5xphy_txrxdq_ew_15M_1X_h_1Xb_v_1Xe_h_1Ya_v_1Yb_h_5Y_vhvhv_2Yy2Z_ffgnp0p715v0c_pg.lib'\n",

                 undef, undef, 
                 undef, 
                 "-I- Pin VIO_PAD:\n" .
                        " 	../data/alphaPinCheck.pl/QA_test_plan.QA_testbenches.alphaPincheck.alphaPinCheck_002.QA_dwc_lpddr5xphy_txrxdq_ew_lppddr5x.lib_pg.dwc_lpddr5xphy_txrxdq_ew_15M_1X_h_1Xb_v_1Xe_h_1Ya_v_1Yb_h_5Y_vhvhv_2Yy2Z_ffgnp0p6v85c_pg.lib: VDDQ\n" .
                        " 	../data/alphaPinCheck.pl/QA_test_plan.QA_testbenches.alphaPincheck.alphaPinCheck_002.QA_dwc_lpddr5xphy_txrxdq_ew_lppddr5x.lib_pg.dwc_lpddr5xphy_txrxdq_ew_15M_1X_h_1Xb_v_1Xe_h_1Ya_v_1Yb_h_5Y_vhvhv_2Yy2Z_ffgnp0p715v0c_pg.lib: VDD\n" .
                        "-I- Pin VIO_PwrOk:\n" .
                        " 	../data/alphaPinCheck.pl/QA_test_plan.QA_testbenches.alphaPincheck.alphaPinCheck_002.QA_dwc_lpddr5xphy_txrxdq_ew_lppddr5x.lib_pg.dwc_lpddr5xphy_txrxdq_ew_15M_1X_h_1Xb_v_1Xe_h_1Ya_v_1Yb_h_5Y_vhvhv_2Yy2Z_ffgnp0p6v85c_pg.lib: VDDQ\n" .
                        " 	../data/alphaPinCheck.pl/QA_test_plan.QA_testbenches.alphaPincheck.alphaPinCheck_002.QA_dwc_lpddr5xphy_txrxdq_ew_lppddr5x.lib_pg.dwc_lpddr5xphy_txrxdq_ew_15M_1X_h_1Xb_v_1Xe_h_1Ya_v_1Yb_h_5Y_vhvhv_2Yy2Z_ffgnp0p715v0c_pg.lib: VDD\n",
                         
                 undef, 
                 undef, undef,
            ],
        },
        '90'=>{
            'description' => "Pin missing ... "
                            ."\n\t PwrOK_VIO         not in fsg0p675vn40c_pg.lib"
                            ."\n\t Cmpdig_CalcDac[0] not in sfg0p675v125c_pg.lib"
                            ,
            'testScript'  => "$RealScript",
            'testDataDir' => $TDATA,
            'scriptDir'   => "$RealBin/../../bin",
            'scriptName'  => "$scriptName",
            'product'     => "ddr54",
            'project'     => "d822-ddr54-ss7hpp-18",
            'release'     => "1.00a_pre3",
            'macro'       => "dwc_ddrphy_cmpana",
            #'tech'        => "ss7hpp-18",
            'lefObsLayers'=> '',
            'lefPinLayers'=> '',
            'PGlayers'    => '',
            'bracket'     => 'square',
            'log'         => undef,
            'cdl'         => undef,
            'gds'         => undef,
            'pinCSV'      => undef,
            'dp90'        =>  "$TDATA/ddr54.project.d822-ddr54-ss7hpp-18.ckt.rel.dwc_ddrphy_cmpana.1.00a_pre3",
            'lef'         =>  "$DP{90}.lef.dwc_ddrphy_cmpana_merged.lef",
            'libertyNopg' =>  "$DP{90}.lib.dwc_ddrphy_cmpana_18M_4Mx_4Dx_4Hx_2Bx_2Gx_2UTM_ILB_sspg0p675v125c.lib",
            'liberty'     => [
                              "$DP{90}.lib_pg.dwc_ddrphy_cmpana_18M_4Mx_4Dx_4Hx_2Bx_2Gx_2UTM_ILB_fsg0p675vn40c_pg.lib",
                              "$DP{90}.lib_pg.dwc_ddrphy_cmpana_18M_4Mx_4Dx_4Hx_2Bx_2Gx_2UTM_ILB_sfg0p675v125c_pg.lib"
                             ],
            'extraArgs'   => "",
            'expect_fail' => TRUE,
            'test_dir'            => $RealBin,
            'logfile_name'        => 'alphaPinCheck.pl.log',
            'start_regex_strings' => [
                 "-I- Checking across all views for PG pin existence ...\n",
                 "-I- Checking across all views for pin existence ...\n",
                 "-I- Checking across all views for pin direction consistency...\n",
                 "-I- Checking across all views for type consistency...\n",
                 "-I- Checking across all views for related_power consistency...\n",
                 "-I- Checking across all views for related_ground consistency...\n",
                 "-I- Checking bracket consistency across all views;  All views must have \"square\" brackets\n",
                 "-I- Checking for macro area consistency\n",
            ],
            'end_regex_strings' => [
                 "-I- CLEAN!\n", "-E- DIRTY!\n", 
                 "-I- CLEAN!\n", "-I- CLEAN!\n", "-I- CLEAN!\n",
                 "-I- CLEAN!\n", "-I- CLEAN!\n", "-I- CLEAN!\n",
            ],
            'expected_content' => [
                 undef,
                 "-I- Pin Cmpdig_CalDac[0]\n"
                 . "-I- 	 missing in ../data/alphaPinCheck.pl/ddr54.project.d822-ddr54-ss7hpp-18.ckt.rel.dwc_ddrphy_cmpana.1.00a_pre3.lib_pg.dwc_ddrphy_cmpana_18M_4Mx_4Dx_4Hx_2Bx_2Gx_2UTM_ILB_sfg0p675v125c_pg.lib\n"
                 . "-I- Pin PwrOk_VIO\n"
                 . "-I- 	 missing in ../data/alphaPinCheck.pl/ddr54.project.d822-ddr54-ss7hpp-18.ckt.rel.dwc_ddrphy_cmpana.1.00a_pre3.lib_pg.dwc_ddrphy_cmpana_18M_4Mx_4Dx_4Hx_2Bx_2Gx_2UTM_ILB_sfg0p675v125c_pg.lib\n",
                   undef, undef, undef,
                   undef, undef, undef,
            ],
        }, 
        '91'=>{
            'description' => "bus Pin TxPowerdown[1] missing in lef",
            'testScript'  => "$RealScript",
            'testDataDir' =>  $TDATA,
            'scriptDir'   => "$RealBin/../../bin",
            'scriptName'  => "$scriptName",
            'product'     => "ddr54",
            'project'     => "d822-ddr54-ss7hpp-18",
            'release'     => "1.10a",
            'macro'       => "dwc_ddrphy_txrxac_ns",
            #'tech'        => "ss7hpp-18",
            'lefObsLayers'=> '',
            'lefPinLayers'=> '',
            'PGlayers'    => '',
            'bracket'     => 'square',
            'log'         => undef,
            'cdl'         => undef,
            'gds'         => undef,
            'pinCSV'      => undef,
            'dp91'        =>  "$TDATA/ddr54.project.d822-ddr54-ss7hpp-18.ckt.rel.dwc_ddrphy_txrxac_ns.1.10a.macro",
            'lef'         =>  "$DP{91}.lef.dwc_ddrphy_txrxac_ns_merged.lef",

            'libertyNopg' =>  "$DP{91}.lib.dwc_ddrphy_txrxac_ns_18M_4Mx_4Dx_4Hx_2Bx_2Gx_2UTM_ILB_fsg0p675vn40c.lib",
            'liberty'     => [
                              "$DP{91}.lib_pg.dwc_ddrphy_txrxac_ns_18M_4Mx_4Dx_4Hx_2Bx_2Gx_2UTM_ILB_fsg0p675vn40c_pg.lib",
                              "$DP{91}.lib_pg.dwc_ddrphy_txrxac_ns_18M_4Mx_4Dx_4Hx_2Bx_2Gx_2UTM_ILB_sspg0p675vn40c_pg.lib",
                             ],
            'extraArgs'   => "",
            'expect_fail' => TRUE,
            'test_dir'            => $RealBin,
            'logfile_name'        => 'alphaPinCheck.pl.log',
            'start_regex_strings' => [
                 "-W-                                                               v\n",
                 "-I- Checking across all views for PG pin existence ...\n",
                 "-I- Checking across all views for pin existence ...\n",
                 "-I- Checking across all views for pin direction consistency...\n",
                 "-I- Checking across all views for type consistency...\n",
                 "-I- Checking across all views for related_power consistency...\n",
                 "-I- Checking across all views for related_ground consistency...\n",
                 "-I- Checking bracket consistency across all views;  All views must have \"square\" brackets\n",
                 "-I- Checking for macro area consistency\n",
            ],
            'end_regex_strings' => [
                 '-W-                                                             \^'."\n",
                 "-I- CLEAN!\n",
                 "-E- DIRTY!\n", 
                 "-I- CLEAN!\n", "-I- CLEAN!\n", "-I- CLEAN!\n",
                 "-I- CLEAN!\n", "-I- CLEAN!\n", "-I- CLEAN!\n",
            ],
            'expected_content' => [
                 "-W- In LEF-> PIN Name contains invalid BUSBITCHARs: 'TxPowerdown{1}\'\n",
                 undef,
                 "-I- Pin TxPowerdown[1]\n"
               . "-I- 	 missing in ../data/alphaPinCheck.pl/ddr54.project.d822-ddr54-ss7hpp-18.ckt.rel.dwc_ddrphy_txrxac_ns.1.10a.macro.lef.dwc_ddrphy_txrxac_ns_merged.lef\n",
                   undef, undef, undef,
                   undef, undef, undef,
            ],
        }, 
        '92'=>{
            'description' => "Should have Macro Area mismatch  :"
                            ."\n\t fsg0p675v125c_pg.lib : 11331.459360"
                            ."\n\t sspg0p675vn40c_pg.lib: 11331.459360"
                            ."\n\t fsg0p675v125c.lib    : 11331.459360"
                            ."\n\t merged.lef           : 11333.520000"
                            ,
            'testScript'  => "$RealScript",
            'testDataDir' =>  $TDATA,
            'scriptDir'   => "$RealBin/../../bin",
            'scriptName'  => "$scriptName",
            'product'     => "ddr54",
            'project'     => "d822-ddr54-ss7hpp-18",
            'release'     => "1.00a_pre3",
            'macro'       => "dwc_ddrphy_txrxdq_ns",
            #'tech'        => "ss7hpp-18",
            'lefObsLayers'=> '',
            'lefPinLayers'=> '',
            'PGlayers'    => '',
            'bracket'     => 'square',
            'log'         => undef,
            'cdl'         => undef,
            'gds'         => undef,
            'pinCSV'      => undef,
            'dp92'        =>  "$TDATA/ddr54.project.d822-ddr54-ss7hpp-18.ckt.rel.dwc_ddrphy_txrxdq_ns.1.00a_pre3.macro",
            'lef'         =>  "$DP{92}.lef.dwc_ddrphy_txrxdq_ns_merged.lef",

            'libertyNopg' =>  "$DP{92}.lib.dwc_ddrphy_txrxdq_ns_18M_4Mx_4Dx_4Hx_2Bx_2Gx_2UTM_ILB_fsg0p675v125c.lib",
            'liberty'     => [
                              "$DP{92}.lib_pg.dwc_ddrphy_txrxdq_ns_18M_4Mx_4Dx_4Hx_2Bx_2Gx_2UTM_ILB_fsg0p675v125c_pg.lib",
                              "$DP{92}.lib_pg.dwc_ddrphy_txrxdq_ns_18M_4Mx_4Dx_4Hx_2Bx_2Gx_2UTM_ILB_sspg0p675vn40c_pg.lib",
                             ],
            'extraArgs'   => "",
            'expect_fail' => TRUE,
            'test_dir'            => $RealBin,
            'logfile_name'        => 'alphaPinCheck.pl.log',
            'start_regex_strings' => [
                 "-I- Checking across all views for PG pin existence ...\n",
                 "-I- Checking across all views for pin existence ...\n",
                 "-I- Checking across all views for pin direction consistency...\n",
                 "-I- Checking across all views for type consistency...\n",
                 "-I- Checking across all views for related_power consistency...\n",
                 "-I- Checking across all views for related_ground consistency...\n",
                 "-I- Checking bracket consistency across all views;  All views must have \"square\" brackets\n",
                 "-I- Checking for macro area consistency\n",
            ],
            'end_regex_strings' => [
                 "-I- CLEAN!\n", "-I- CLEAN!\n", "-I- CLEAN!\n", "-I- CLEAN!\n",
                 "-I- CLEAN!\n", "-I- CLEAN!\n", "-I- CLEAN!\n",
                 "-E- DIRTY!\n",
            ],
            'expected_content' => [
                   undef, undef, undef, undef,
                   undef, undef, undef,
                    "-I- Macro area disagreement:\n"
                  . "-I- 	../data/alphaPinCheck.pl/ddr54.project.d822-ddr54-ss7hpp-18.ckt.rel.dwc_ddrphy_txrxdq_ns.1.00a_pre3.macro.lib_pg.dwc_ddrphy_txrxdq_ns_18M_4Mx_4Dx_4Hx_2Bx_2Gx_2UTM_ILB_fsg0p675v125c_pg.lib: 11331.459360\n"
                  . "-I- 	../data/alphaPinCheck.pl/ddr54.project.d822-ddr54-ss7hpp-18.ckt.rel.dwc_ddrphy_txrxdq_ns.1.00a_pre3.macro.lib_pg.dwc_ddrphy_txrxdq_ns_18M_4Mx_4Dx_4Hx_2Bx_2Gx_2UTM_ILB_sspg0p675vn40c_pg.lib: 11331.459360\n"
                  . "-I- 	../data/alphaPinCheck.pl/ddr54.project.d822-ddr54-ss7hpp-18.ckt.rel.dwc_ddrphy_txrxdq_ns.1.00a_pre3.macro.lib.dwc_ddrphy_txrxdq_ns_18M_4Mx_4Dx_4Hx_2Bx_2Gx_2UTM_ILB_fsg0p675v125c.lib: 11331.459360\n"
                  . "-I- 	../data/alphaPinCheck.pl/ddr54.project.d822-ddr54-ss7hpp-18.ckt.rel.dwc_ddrphy_txrxdq_ns.1.00a_pre3.macro.lef.dwc_ddrphy_txrxdq_ns_merged.lef: 11333.520000\n",
            ],
        }, 
        '93'=>{
            'description' => "Pin direction mismatches"
                            ."\n\t Pclk_Dq0: input vs output"
                            ."\n\t Pclk_Dq1 io vs output"
                            ."\n\t atpg_se io vs input"
                            ."\n\t atpg_si output vs input",
            'testScript'  => "$RealScript",
            'testDataDir' =>  $TDATA,
            'scriptDir'   => "$RealBin/../../bin",
            'scriptName'  => "$scriptName",
            'product'     => "lpddr54",
            'project'     => "d859-lpddr54-tsmc7ff18",
            'release'     => "1.20a_patch",
            'macro'       => 'dwc_ddrphy_pclk_master',
            #'tech'        => 'tsmc7ff18',
            'lefObsLayers'=> '',
            'lefPinLayers'=> '',
            'PGlayers'    => '',
            'bracket'     => 'square',
            'log'         => undef,
            'cdl'         => undef,
            'gds'         => undef,
            'pinCSV'      => undef,
            'dp93'        =>  "$TDATA/lpddr54.project.d859-lpddr54-tsmc7ff18.ckt.rel.dwc_ddrphy_pclk_master.1.20a_patch1.macro",
            'lef'         =>  "$DP{93}.lef.dwc_ddrphy_pclk_master_merged.lef",
            'libertyNopg' =>  "$DP{93}.lib.dwc_ddrphy_pclk_master_13M_1X_h_1Xa_v_1Ya_h_5Y_vhvhv_2Yy2Z_ffg0p9v125c.lib",
            'liberty'     => [
                              "$DP{93}.lib_pg.dwc_ddrphy_pclk_master_13M_1X_h_1Xa_v_1Ya_h_5Y_vhvhv_2Yy2Z_ffg0p9v125c_pg.lib",
                              "$DP{93}.lib_pg.dwc_ddrphy_pclk_master_13M_1X_h_1Xa_v_1Ya_h_5Y_vhvhv_2Yy2Z_ssg0p675v0c_pg.lib",
                             ],
            'extraArgs'   => "",
            'expect_fail' => TRUE,
        }, 
        '94'=>{
            'description' => "Pin 'related_power': RxClkT VDD vs VDDQ",
            'testScript'  => "$RealScript",
            'testDataDir' =>  $TDATA,
            'scriptDir'   => "$RealBin/../../bin",
            'scriptName'  => "$scriptName",
            'product'     => "lpddr54",
            'project'     => "d859-lpddr54-tsmc7ff18",
            'release'     => "1.20a_patch",
            'macro'       => 'dwc_ddrphy_se_io_ns',
            #'tech'        => 'tsmc7ff18',
            'lefObsLayers'=> '',
            'lefPinLayers'=> '',
            'PGlayers'    => '',
            'bracket'     => 'square',
            'log'         => undef,
            'cdl'         => undef,
            'gds'         => undef,
            'pinCSV'      => undef,
            'dp94'        =>  "$TDATA/lpddr54.project.d859-lpddr54-tsmc7ff18.ckt.rel.dwc_ddrphy_se_io_ns.1.20a_patch1.macro",
            'lef'         =>  "$DP{94}.lef.dwc_ddrphy_se_io_ns_merged.lef",
            'libertyNopg' =>  "$DP{94}.lib.dwc_ddrphy_se_io_ns_13M_1X_h_1Xa_v_1Ya_h_5Y_vhvhv_2Yy2Z_ssg0p765v0c.lib",
            'liberty'     => [
                              "$DP{94}.lib_pg.dwc_ddrphy_se_io_ns_13M_1X_h_1Xa_v_1Ya_h_5Y_vhvhv_2Yy2Z_ssg0p675v0c_pg.lib",
                              "$DP{94}.lib_pg.dwc_ddrphy_se_io_ns_13M_1X_h_1Xa_v_1Ya_h_5Y_vhvhv_2Yy2Z_ssg0p765v0c_pg.lib",
                             ],

            'extraArgs'   => "",
            'expect_fail' => TRUE,
        }, 
        '95'=>{
            'description' => "Pin 'VDD' direction missing in ffgnp1p16v25c_pg.lib\n\t LEF Invalid busbit 'csrLsTxSlewPD0{0}'"
                            ."\n\t 'csrLsTxSlewPD0[0]' missing in LEF"
                            ."\n\t 'scan_so' missing in ffgnp1p16v25c_pg.lib"
                            ."\n\t 'LsIDDQ_mode' dir mismatch input vs output vs output"
                            ."\n\t 'LsScan_mode' dir mismatch io vs output vs output"
                            ."\n\t 'ResetAsync' dir mismatch output vs input vs input"
                            ."\n\t 'VIO_PwrOk' dir mismatch io vs input vs input"
                            ."\n\t 'VIO_PwrOk' related_power mismatch VDD vs VDDQ in *pg.lib"
                            ."\n\t Should have Area mismatch 'ffgnp1p16v25c_pg.lib: 5500.000000' vs "
                            ."\n\t                           'tt0p75v25c_pg.lib   : 5410.306440' vs "
                            ."\n\t                           'ffgnp1p16v25c.lib   : 5410.306440' vs "
                            ."\n\t                           '*.lef               : 5410.306440'"
                            ,
            'testScript'  => "$RealScript",
            'testDataDir' =>  $TDATA,
            'scriptDir'   => "$RealBin/../../bin",
            'scriptName'  => "$scriptName",
            'product'     => 'lpddr5x_ddr5_phy',
            'project'     => "d930-lpddr5x-tsmc5ff12",
            'release'     => '3.00a',
            'macro'       => 'dwc_lpddr5xphy_lstx_acx2_ew',
            #'tech'        => 'tsmc5ff12',
            'lefObsLayers'=> '',
            'lefPinLayers'=> '',
            'PGlayers'    => '',
            'bracket'     => 'square',
            'log'         => undef,
            'cdl'         => undef,
            'gds'         => undef,
            'pinCSV'      => undef,
            'dp95'        =>  "$TDATA/lpddr5x_ddr5_phy.lp5x.project.d930-lpddr5x-tsmc5ff12.ckt.rel.dwc_lpddr5xphy_lstx_acx2_ew.3.00a.macro",
            'lef'         =>  "$DP{95}.lef.dwc_lpddr5xphy_lstx_acx2_ew_merged.lef",
            'libertyNopg' =>  "$DP{95}.lib.dwc_lpddr5xphy_lstx_acx2_ew_15M_1X_h_1Xb_v_1Xe_h_1Ya_v_1Yb_h_5Y_vhvhv_2Yy2Z_ffgnp1p16v25c.lib",
            'liberty'     => [
                              "$DP{95}.lib_pg.dwc_lpddr5xphy_lstx_acx2_ew_15M_1X_h_1Xb_v_1Xe_h_1Ya_v_1Yb_h_5Y_vhvhv_2Yy2Z_ffgnp1p16v25c_pg.lib",
                              "$DP{95}.lib_pg.dwc_lpddr5xphy_lstx_acx2_ew_15M_1X_h_1Xb_v_1Xe_h_1Ya_v_1Yb_h_5Y_vhvhv_2Yy2Z_tt0p75v25c_pg.lib",
                             ],

            'extraArgs'   => "",
            'expect_fail' => TRUE,
        }, 
        '96'=>{
            'description' => "Pin related_power mismatch VIO_PAD+VIO_PwrOk -> ffgnp0p6v85c_pg.lib:VDDQ ffgnp0p715v0c_pg.lib:VDDD",
            'testScript'  => "$RealScript",
            'testDataDir' =>  $TDATA,
            'scriptDir'   => "$RealBin/../../bin",
            'scriptName'  => "$scriptName",
            'product'     => 'lpddr5x_ddr5_phy',
            'project'     => "d930-lpddr5x-tsmc5ff12",
            'release'     => '2.00a',
            'macro'       => 'dwc_lpddr5xphy_txrxdq_ew',
            #'tech'        => 'tsmc5ff12',
            'lefObsLayers'=> '',
            'lefPinLayers'=> '',
            'PGlayers'    => '',
            'bracket'     => 'square',
            'log'         => undef,
            'cdl'         => undef,
            'gds'         => undef,
            'pinCSV'      => undef,
            'dp96'        =>  "$TDATA/lpddr5x_ddr5_phy.lp5x.project.d930-lpddr5x-tsmc5ff12.ckt.rel.dwc_lpddr5xphy_txrxdq_ew.2.00a.macro",
            'lef'         =>  "$DP{96}.lef.dwc_lpddr5xphy_txrxdq_ew_merged.lef",
            'libertyNopg' =>  "$DP{96}.lib.dwc_lpddr5xphy_txrxdq_ew_15M_1X_h_1Xb_v_1Xe_h_1Ya_v_1Yb_h_5Y_vhvhv_2Yy2Z_ffgnp0p715v0c.lib",
            'liberty'     => [
                              "$DP{96}.lib_pg.dwc_lpddr5xphy_txrxdq_ew_15M_1X_h_1Xb_v_1Xe_h_1Ya_v_1Yb_h_5Y_vhvhv_2Yy2Z_ffgnp0p6v85c_pg.lib",
                              "$DP{96}.lib_pg.dwc_lpddr5xphy_txrxdq_ew_15M_1X_h_1Xb_v_1Xe_h_1Ya_v_1Yb_h_5Y_vhvhv_2Yy2Z_ffgnp0p715v0c_pg.lib",
                             ],
            'extraArgs'   => "",
            'expect_fail' => TRUE,
        }, 
        '97'=>{
            'description' => "Should have Area mismatch"
                            ."\n\t ssg0p675v125c_pg.lib: 14507.551800"
                            ."\n\t tt0p75v85c_pg.lib   : 14500.000000"
                            ."\n\t tt0p75v85c.lib      : 14507.551800" 
                            ."\n\t lef                 : 14507.551800 " 
                            ,
            'testScript'  => "$RealScript",
            'testDataDir' =>  $TDATA,
            'scriptDir'   => "$RealBin/../../bin",
            'scriptName'  => "$scriptName",
            'product'     => 'lpddr5x_ddr5_phy',
            'project'     => "d930-lpddr5x-tsmc5ff12",
            'release'     => '2.00a',
            'macro'       => 'dwc_lpddr5xphy_zcalio_ew',
            #'tech'        => 'tsmc5ff12',
            'lefObsLayers'=> '',
            'lefPinLayers'=> '',
            'PGlayers'    => '',
            'bracket'     => 'square',
            'log'         => undef,
            'cdl'         => undef,
            'gds'         => undef,
            'pinCSV'      => undef,
            'dp97'        =>  "$TDATA/lpddr5x_ddr5_phy.lp5x.project.d930-lpddr5x-tsmc5ff12.ckt.rel.dwc_lpddr5xphy_zcalio_ew.2.00a.macro",
            'lef'         =>  "$DP{97}.lef.dwc_lpddr5xphy_zcalio_ew_merged.lef",
            'libertyNopg' =>  "$DP{97}.lib.dwc_lpddr5xphy_zcalio_ew_15M_1X_h_1Xb_v_1Xe_h_1Ya_v_1Yb_h_5Y_vhvhv_2Yy2Z_tt0p75v85c.lib",
            'liberty'     => [
                              "$DP{97}.lib_pg.dwc_lpddr5xphy_zcalio_ew_15M_1X_h_1Xb_v_1Xe_h_1Ya_v_1Yb_h_5Y_vhvhv_2Yy2Z_ssg0p675v125c_pg.lib",
                              "$DP{97}.lib_pg.dwc_lpddr5xphy_zcalio_ew_15M_1X_h_1Xb_v_1Xe_h_1Ya_v_1Yb_h_5Y_vhvhv_2Yy2Z_tt0p75v85c_pg.lib",
                             ],

            'extraArgs'   => "",
            'expect_fail' => TRUE,
        }, 
        '98'=>{
            'description' => "Fails LEF pin & obs layers .. fresh from //depot/products/ddr54",
            'testScript'  => "$RealScript",
            'testDataDir' => "$RealBin/../data",
            'scriptDir'   => "$RealBin/../../bin",
            'scriptName'  => "$scriptName",
            'product'     => "ddr54",
            'project'     => "d809-ddr54-tsmc7ff18",
            'release'     => "1.20a",
            'macro'       => "dwc_ddrphy_por",
            'tech'        => "",
            'lefObsLayers'=> "",
            'lefPinLayers'=> "",
            'PGlayers'    => "",
            'bracket'     => 'square',
            'log'         => undef,
            'pinCSV'      => "$DP{'98'}.pininfo.dwc_ddrphy_por.csv",
            'cdl'         => "$DP{'98'}.netlist.8M_2X_hv_1Ya_h_4Y_vhvh.dwc_ddrphy_por.cdl",
            'gds'         => "$DP{'98'}.gds.8M_2X_hv_1Ya_h_4Y_vhvh.dwc_ddrphy_por.gds.gz",
            'lef'         => "$DP{'98'}.lef.8M_2X_hv_1Ya_h_4Y_vhvh.dwc_ddrphy_por_merged.lef",
            'lef'         => "$DP{'98'}.lef.8M_2X_hv_1Ya_h_4Y_vhvh.dwc_ddrphy_por.lef",
            'verilog'     => "$DP{'98'}.behavior.dwc_ddrphy_por.v",
            'liberty'     => "$DP{'98'}.timing.8M_2X_hv_1Ya_h_4Y_vhvh.lib.dwc_ddrphy_por_15M_2X_hv_1Ya_h_5Y_vhvhv_2Yy2Yx2R_ffg0p825v0c.lib",
            'dp98'        => "$TDATA/ddr54.project.d809-ddr54-tsmc7ff18.ckt.rel.dwc_ddrphy_por.1.20a.macro",
            'dp98lib'     => "/slowfs/us01dwt2p387/juliano/func_tests/products/ddr54/project/d809-ddr54-tsmc7ff18/ckt/rel/dwc_ddrphy_por/1.20a/macro/timing/8M_2X_hv_1Ya_h_4Y_vhvh/",
            'liberty'     => [
                "$DP{'98lib'}/lib_pg/dwc_ddrphy_por_15M_2X_hv_1Ya_h_5Y_vhvhv_2Yy2Yx2R_ffg0p825v0c_pg.lib",
                "$DP{'98lib'}/lib_pg/dwc_ddrphy_por_15M_2X_hv_1Ya_h_5Y_vhvhv_2Yy2Yx2R_ffg0p825v125c_pg.lib",
                "$DP{'98lib'}/lib_pg/dwc_ddrphy_por_15M_2X_hv_1Ya_h_5Y_vhvhv_2Yy2Yx2R_ffg0p825vn40c_pg.lib",
                "$DP{'98lib'}/lib_pg/dwc_ddrphy_por_15M_2X_hv_1Ya_h_5Y_vhvhv_2Yy2Yx2R_ffg0p935v0c_pg.lib",
                "$DP{'98lib'}/lib_pg/dwc_ddrphy_por_15M_2X_hv_1Ya_h_5Y_vhvhv_2Yy2Yx2R_ffg0p935v125c_pg.lib",
                "$DP{'98lib'}/lib_pg/dwc_ddrphy_por_15M_2X_hv_1Ya_h_5Y_vhvhv_2Yy2Yx2R_ffg0p935vn40c_pg.lib",
                "$DP{'98lib'}/lib_pg/dwc_ddrphy_por_15M_2X_hv_1Ya_h_5Y_vhvhv_2Yy2Yx2R_ssg0p675v0c_pg.lib",
                "$DP{'98lib'}/lib_pg/dwc_ddrphy_por_15M_2X_hv_1Ya_h_5Y_vhvhv_2Yy2Yx2R_ssg0p675v125c_pg.lib",
                "$DP{'98lib'}/lib_pg/dwc_ddrphy_por_15M_2X_hv_1Ya_h_5Y_vhvhv_2Yy2Yx2R_ssg0p675vn40c_pg.lib",
                "$DP{'98lib'}/lib_pg/dwc_ddrphy_por_15M_2X_hv_1Ya_h_5Y_vhvhv_2Yy2Yx2R_ssg0p765v0c_pg.lib",
                "$DP{'98lib'}/lib_pg/dwc_ddrphy_por_15M_2X_hv_1Ya_h_5Y_vhvhv_2Yy2Yx2R_ssg0p765v125c_pg.lib",
                "$DP{'98lib'}/lib_pg/dwc_ddrphy_por_15M_2X_hv_1Ya_h_5Y_vhvhv_2Yy2Yx2R_ssg0p765vn40c_pg.lib",
                "$DP{'98lib'}/lib_pg/dwc_ddrphy_por_15M_2X_hv_1Ya_h_5Y_vhvhv_2Yy2Yx2R_tt0p75v25c_pg.lib",
                "$DP{'98lib'}/lib_pg/dwc_ddrphy_por_15M_2X_hv_1Ya_h_5Y_vhvhv_2Yy2Yx2R_tt0p75v85c_pg.lib",
                "$DP{'98lib'}/lib_pg/dwc_ddrphy_por_15M_2X_hv_1Ya_h_5Y_vhvhv_2Yy2Yx2R_tt0p85v25c_pg.lib",
                "$DP{'98lib'}/lib_pg/dwc_ddrphy_por_15M_2X_hv_1Ya_h_5Y_vhvhv_2Yy2Yx2R_tt0p85v85c_pg.lib",
            ],
            'libertyNopg' => [
                "$DP{'98lib'}/lib/dwc_ddrphy_por_15M_2X_hv_1Ya_h_5Y_vhvhv_2Yy2Yx2R_ffg0p825v0c.lib",
                "$DP{'98lib'}/lib/dwc_ddrphy_por_15M_2X_hv_1Ya_h_5Y_vhvhv_2Yy2Yx2R_ffg0p825v125c.lib",
                "$DP{'98lib'}/lib/dwc_ddrphy_por_15M_2X_hv_1Ya_h_5Y_vhvhv_2Yy2Yx2R_ffg0p825vn40c.lib",
                "$DP{'98lib'}/lib/dwc_ddrphy_por_15M_2X_hv_1Ya_h_5Y_vhvhv_2Yy2Yx2R_ffg0p935v0c.lib",
                "$DP{'98lib'}/lib/dwc_ddrphy_por_15M_2X_hv_1Ya_h_5Y_vhvhv_2Yy2Yx2R_ffg0p935v125c.lib",
                "$DP{'98lib'}/lib/dwc_ddrphy_por_15M_2X_hv_1Ya_h_5Y_vhvhv_2Yy2Yx2R_ffg0p935vn40c.lib",
                "$DP{'98lib'}/lib/dwc_ddrphy_por_15M_2X_hv_1Ya_h_5Y_vhvhv_2Yy2Yx2R_ssg0p675v0c.lib",
                "$DP{'98lib'}/lib/dwc_ddrphy_por_15M_2X_hv_1Ya_h_5Y_vhvhv_2Yy2Yx2R_ssg0p675v125c.lib",
                "$DP{'98lib'}/lib/dwc_ddrphy_por_15M_2X_hv_1Ya_h_5Y_vhvhv_2Yy2Yx2R_ssg0p675vn40c.lib",
                "$DP{'98lib'}/lib/dwc_ddrphy_por_15M_2X_hv_1Ya_h_5Y_vhvhv_2Yy2Yx2R_ssg0p765v0c.lib",
                "$DP{'98lib'}/lib/dwc_ddrphy_por_15M_2X_hv_1Ya_h_5Y_vhvhv_2Yy2Yx2R_ssg0p765v125c.lib",
                "$DP{'98lib'}/lib/dwc_ddrphy_por_15M_2X_hv_1Ya_h_5Y_vhvhv_2Yy2Yx2R_ssg0p765vn40c.lib",
                "$DP{'98lib'}/lib/dwc_ddrphy_por_15M_2X_hv_1Ya_h_5Y_vhvhv_2Yy2Yx2R_tt0p75v25c.lib",
                "$DP{'98lib'}/lib/dwc_ddrphy_por_15M_2X_hv_1Ya_h_5Y_vhvhv_2Yy2Yx2R_tt0p75v85c.lib",
                "$DP{'98lib'}/lib/dwc_ddrphy_por_15M_2X_hv_1Ya_h_5Y_vhvhv_2Yy2Yx2R_tt0p85v25c.lib",
                "$DP{'98lib'}/lib/dwc_ddrphy_por_15M_2X_hv_1Ya_h_5Y_vhvhv_2Yy2Yx2R_tt0p85v85c.lib",
            ],
            'lefObsLayers'=> "M0 M1 M2 M3 M4 M5 M6 M7 M8 M9 M10 M11 M12 OVERLAP",
            'lefPinLayers'=> "M0 M1 M2 M3 M4 M5 M6 M7 M8 M9 M10 M11 M12 OVERLAP",
            'extraArgs'   => "-pcs ddr54/d809-ddr54-tsmc7ff18/rel1.20 "
                            ."-streamLayermap /remote/cad-rep/projects/cad/c239-tsmc7ff-1.8v/rel9.3.0/cad/15M_2X_hv_1Ya_h_5Y_vhvhv_2Yy2Yx2R/stream/stream.layermap",
            'expect_fail' => TRUE,
        }, 
    );
    check_all_files_in_tests_exist( \%t );

    my $workspace    = $ENV{'DDR_DA_DEFAULT_P4WS'} || $DDR_DA_DEFAULT_P4WS;
    my $opt_cleanup  = 1;
    my $opt_coverage = 0;
    my $opt_help     = 0;
    my $opt_tnum     = 0;
    my $opt_randomize= 0;

    #($workspace, $opt_cleanup, $opt_coverage, $opt_help, $opt_tnum, $opt_randomize ) = 
    #    test_scripts__get_options( $workspace );
    if ( $opt_help ) {
        return 0;
    }

    if ( ! $workspace ) {
        return -1;
    }

    plan(49); # this functional test uses is_deeply() so we need to set a plan
    my $ntests = keys(%t);
    my $nfails = 0;
    foreach my $tstnum (sort keys %t) {
        if ( $opt_testnum ) {
            my $num = $tstnum + 0;     # convert string of number to a number
            dprint(LOW, "Run test #$tstnum ? ... user requested $opt_testnum \n" ); 
            viprint(LOW, "Skipping Test #$tstnum ... \n" );
            next if ( $num != $opt_testnum );
        }

        my $href_args = $t{"$tstnum"};
        vhprint(LOW, "Running $href_args->{'testScript'} $tstnum: $href_args->{'description'} \n");
        # We need to assemble the command line args to pass to main.
        my $cmdline_args = create_cmdline_args($href_args, $workspace);
        my ($status,$stdout);
        ($status,$stdout) = test_scripts__main(
            $tstnum,
            $opt_cleanup,
            $opt_coverage,
            $href_args->{'testScript'},
            $href_args->{'testDataDir'},
            $href_args->{'scriptDir'},
            $href_args->{'scriptName'},
            $cmdline_args,
            $workspace,
        );
        my $cmdrun = $href_args->{'scriptName'} . " " . $cmdline_args;
        viprint(LOW, "$cmdrun");

        #prompt_before_continue(NONE);
        if ( $status != 0 ){
            dprint(LOW, "$tstnum: common main returned status = $status\n");
            my $tempfile = "/tmp/${tstnum}_$href_args->{'testScript'}_$$.log";
            my $ostatus  = open my $FOUT, ">", $tempfile ; #nolint open>
            my $seeFile = "";
            if ( $ostatus ){
                print $FOUT "$href_args->{'scriptName'} $cmdline_args\n";
                print $FOUT "$stdout\n";
                close($FOUT);
                $seeFile = " See $tempfile ";
            }
           
            if (
                 exists $href_args->{'test_dir'}            && 
                 exists $href_args->{'logfile_name'}        && 
                 exists $href_args->{'start_regex_strings'} && 
                 exists $href_args->{'end_regex_strings'}   &&
                 exists $href_args->{'expected_content'}      
               ){
                print("Test #$tstnum: comparing logfile vs KGR \n");
                test_logfile_for_KGR_output(
                     $href_args->{test_dir},
                     $href_args->{logfile_name},
                     $href_args->{start_regex_strings},
                     $href_args->{end_regex_strings},
                     $href_args->{expected_content},
                );
            }else{
                wprint( "Test #$tstnum: skipping logfile vs KGR  ...  test details missing.\n" );
            }

            if ( $href_args->{'expect_fail'} ){
                gprint("PASSED: #${tstnum} test failed and was expected to fail. $href_args->{'testScript'} $href_args->{'description'}${seeFile}\n");
            }else{
                eprint("FAILED: #${tstnum} test failed but was expected to pass. $href_args->{'testScript'} $href_args->{'description'}${seeFile}\n");
                $nfails += 1;
            }

        }else{ ## no errors
            if ( $href_args->{'expect_fail'} ){
                eprint("FAILED: #${tstnum} test passed but was expected to fail. $href_args->{'testScript'} $href_args->{'description'}\n");
                $nfails += 1;
            }else{
                gprint("PASSED: #${tstnum} test passed and was expected to pass. $href_args->{'testScript'} $href_args->{'description'}\n");
            }
        }
    }

    done_testing();

    exit($nfails);
} ##  END Main()


#----------------------------------------------------------
#  Check the log file. Inspect to compare KGR vs the
#      generated output in the log file
#----------------------------------------------------------
sub test_logfile_for_KGR_output($$$$$){
   my $test_dir            = shift;
   my $logfile_name        = shift;
   my $start_regex_strings = shift;
   my $end_regex_strings   = shift;
   my $expected_content    = shift;

   my $file = "$test_dir/$logfile_name";
   my $regex_start;
   my $regex_end  ;
   my $expected   ;
   #viprint(LOW, "Open File: '$file'\n");
   open( my $FH, '<', $file ) || confess "Couldn't open file:  '$file'\n";  # nolint open<
       for( my $i=0; $i <= $#{$start_regex_strings} ; $i++ ){
           my $test_description = $start_regex_strings->[$i];
           chomp( $test_description );
           #viprint(LOW, "Start Process Filename: '$file'\n");
           cross_check_logfile( $FH, $start_regex_strings->[$i],
                                     $end_regex_strings->[$i],
                                     $expected_content->[$i],
                                $test_description
           ); 
           #viprint(LOW, "End Process Filename: '$file'\n");
       }
   close( $FH );
   #viprint(LOW, "Close File: '$file'\n");
}
 

#------------------------------------------------------------------------------
#  Arguments
#      File Handle to the alphapincheck log file opened for read
#      $s => the regex used to start the text block extraction
#      $e => the regex used to end the text block extraction
#      $expected => the text block expected to be found (the KGR output)
#      $test_desc => desc of each KGR test comparison
#------------------------------------------------------------------------------
sub cross_check_logfile($$$$$){
    my $FH = shift;
    my $s  = shift;
    my $e  = shift;
    my $expected  = shift;
    my $test_desc = shift;

    #viprint(LOW, "cross_check_logfile: s='$s' e='$e' exp='$expected'\n");

    #-----------------
    # for debug only, line by line
    #-----------------
    my @elines = undef;
    if( defined $expected ){
        @elines = split(/\n/, $expected);
    }
    unshift( @elines , $s );    # add $s, make it 1st elem
    push   ( @elines , $e );    # add $e, make it last elem
    #-----------------
    #if( $s =~ m/direction/ ) #need to debug line by line
        #print "start = $s\n";
        #$DEBUG = CRAZY;
    #}
    #$DEBUG = NONE;
    my ($curpos, $aref_loglines) = ExtractTextBlock( $FH, undef, $s, $e );
    if( $curpos == -1 ){ #end of file
        hprint("hit end of file\n");
    }else{
        #print Dumper $aref_loglines;
        #my $nlines = @$aref_loglines;
        #viprint(LOW, "ExtractTextBlock: returned $nlines lines\n");
        my $got;
        foreach my $line ( @$aref_loglines ){
            $got .= $line if(defined $line );
            #-----------------
            # for debug only, line by line
            #-----------------
              #if( 0 && $s =~ m/anystring/ ){ #need to debug line by line
                 my $got_line;
                 my $expect_line = shift(@elines);
              if( 0 ){
                 if(defined $line ){
                    $got_line .= $line;
                    chomp($got_line);
                 }
                 $expect_line = shift(@elines);
                 chomp($expect_line);
                 is_deeply( $got_line, $expect_line, $test_desc );
                 prompt_before_continue(NONE);
              }
            #-----------------
        }

        $s =~ s|\\||;   # some tests need to remove escape chars in the regex
        $e =~ s|\\||;   # some tests need to remove escape chars in the regex
        my $exp;
        $exp = $s.$expected.$e if( defined $expected );
        # when there is not content between the start/end block
        #    then $expected = undef, so $exp ends up being
        #    just the start and end regex
        $exp = $s.$e           if( ! defined $expected );
        #gprint("got vs exp: \n\tgot='$got'\n\texp='$exp'\n");
        is_deeply( $got, $exp, $test_desc );
    }

    return()
}



#-----------------------------------------------------------
sub create_cmdline_args($;$) {
    print_function_header();
    my $href_args = shift;
    my $workspace = shift;
    my $verbosity = $main::VERBOSITY;
    my $debug     = $main::DEBUG;

    my $prod         = $href_args->{'product'};
    my $proj         = $href_args->{'project'};
    my $rel          = $href_args->{'release'};
    my $macro        = $href_args->{'macro'};
    my $bracket      = $href_args->{'bracket'};
    my $lef          = $href_args->{'lef'};
    my $lib          = $href_args->{'liberty'};
    my $logf         = $href_args->{'log'};
    my $libnopg      = $href_args->{'libertyNopg'};
    my $extra        = $href_args->{'extraArgs'};
    my $pglay        = $href_args->{'PGlayers'};
    my $tech         = $href_args->{'tech'};
    my $gds          = $href_args->{'gds'};
    my $cdl          = $href_args->{'cdl'};
    my $docx         = $href_args->{'docx'};
    my $verilog      = $href_args->{'verilog'};
    my $pininfo      = $href_args->{'pinCSV'};
    my $legalLayers  = $href_args->{'layers'};
    my $lefPinLayers = $href_args->{'lefPinLayers'};
    my $lefObsLayers = $href_args->{'lefObsLayers'};

    my $cmd = "";
    $cmd .= " $extra \\\n"                      if ( $extra );
    $cmd .= " -debug $debug"                    if( $debug       );
    $cmd .= " -verbosity $verbosity"            if( $verbosity   );
    $cmd .= " -macro $macro"                    if( $macro       );
    $cmd .= " -bracket $bracket"                if( $bracket     );
    $cmd .= " -tech $tech"                      if( $tech        );
    $cmd .= " -layers $legalLayers"             if( $legalLayers );
    $cmd .= " -PGlayers $pglay "                if( $pglay       );
    $cmd .= " \\\n";
    $cmd .= " -lefPinLayers $lefPinLayers \\\n" if( $lefPinLayers);
    $cmd .= " -lefObsLayers $lefObsLayers \\\n" if( $lefObsLayers);
    $cmd .= " -gds $gds \\\n"                   if( $gds     );
    $cmd .= " -cdl $cdl \\\n"                   if( $cdl     );
    $cmd .= " -log $logf \\\n"                  if( $logf    );
    $cmd .= build_cmd_args( "-liberty"     , $lib     );
    $cmd .= build_cmd_args( "-libertyNopg" , $libnopg );
    $cmd .= " -verilog $verilog \\\n"           if( $verilog );
    $cmd .= " -lef $lef \\\n"                   if( $lef     );
    $cmd .= " -docx $docx \\\n"                 if( $docx    );
    $cmd .= " -pinCSV $pininfo \\\n"            if( $pininfo );
    $cmd =~ s| \\\n$||;  #remove trailing blank line
    $cmd =~ s| \\\n$||;  #remove trailing blank line

    dprint(LOW, "cmdline args =>\n\t$cmd\n" );
    print_function_footer();
    return $cmd;
}

#----------------------------------------------------------
sub build_cmd_args($$){
    print_function_header();
    my $opt  = shift;
    my $args = shift;

    dprint(LOW, "opt=$opt\n" );
    my $cmd;
    if ( isa_scalar($args) ){
        $cmd .= " $opt $args \\\n";
    }elsif ( isa_aref($args) ){
        foreach my $file ( @$args ){
            $cmd .= " $opt $file \\\n";
        }
    }else{
        eprint( "Expected a scalar or array ref for $opt argument!\n" );
    }
    dprint(LOW, "cmd=$cmd\n" );

    print_function_footer();
    return( $cmd );
}


&Main();



