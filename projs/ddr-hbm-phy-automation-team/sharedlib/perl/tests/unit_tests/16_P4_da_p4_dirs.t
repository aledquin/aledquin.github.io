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
    setup_tests__list_da_p4_dirs();
    #-------------------------------------------------------------------------
    #
    done_testing();
    exit(0);
}
############    END Main    ####################

#-------------------------------------------------------------------------
#  Setup tests to exercise the insert_at_key subroutine
#-------------------------------------------------------------------------
sub setup_tests__list_da_p4_dirs() {
    my $subname = 'da_p4_dirs';    

    #-------------------------------------------------------------------------
    #  Test 'print_da_p4_dirs'
    #-------------------------------------------------------------------------
    my %test0 = (
        'string'   => "//sde-drops/cci/e2010.12/prod_bf4/*",
        'expect' => [
            "//sde-drops/cci/e2010.12/prod_bf4/avv",
            "//sde-drops/cci/e2010.12/prod_bf4/cci",
            "//sde-drops/cci/e2010.12/prod_bf4/clct",
            "//sde-drops/cci/e2010.12/prod_bf4/compat",
            "//sde-drops/cci/e2010.12/prod_bf4/dev_root",
            "//sde-drops/cci/e2010.12/prod_bf4/dox",
            "//sde-drops/cci/e2010.12/prod_bf4/export",
            "//sde-drops/cci/e2010.12/prod_bf4/gvar",
            "//sde-drops/cci/e2010.12/prod_bf4/include",
            "//sde-drops/cci/e2010.12/prod_bf4/test",
            "//sde-drops/cci/e2010.12/prod_bf4/tools",
            "//sde-drops/cci/e2010.12/prod_bf4/unit",
            "//sde-drops/cci/e2010.12/prod_bf4/utils"
        ]
    );

    my %test1 = (
        'string'   => "//wwcad/msip/projects/golden_tb/*",
        'expect' => [
            "//wwcad/msip/projects/golden_tb/HSIC",
            "//wwcad/msip/projects/golden_tb/TOP_Sim",
            "//wwcad/msip/projects/golden_tb/USB2",
            "//wwcad/msip/projects/golden_tb/doc",
            "//wwcad/msip/projects/golden_tb/flow",
            "//wwcad/msip/projects/golden_tb/work_dir"
        ]
    );

    my %test2 = (
        'string'   => "//foundation-drops/boost/g2012.03/prod/boost/*",
        'expect' => [
            "//foundation-drops/boost/g2012.03/prod/boost/boost",
            "//foundation-drops/boost/g2012.03/prod/boost/boost_chrono",
            "//foundation-drops/boost/g2012.03/prod/boost/boost_date_time",
            "//foundation-drops/boost/g2012.03/prod/boost/boost_exception",
            "//foundation-drops/boost/g2012.03/prod/boost/boost_filesystem",
            "//foundation-drops/boost/g2012.03/prod/boost/boost_graph",
            "//foundation-drops/boost/g2012.03/prod/boost/boost_iostreams",
            "//foundation-drops/boost/g2012.03/prod/boost/boost_locale",
            "//foundation-drops/boost/g2012.03/prod/boost/boost_math_c99",
            "//foundation-drops/boost/g2012.03/prod/boost/boost_math_c99f",
            "//foundation-drops/boost/g2012.03/prod/boost/boost_math_c99l",
            "//foundation-drops/boost/g2012.03/prod/boost/boost_math_tr1",
            "//foundation-drops/boost/g2012.03/prod/boost/boost_math_tr1f",
            "//foundation-drops/boost/g2012.03/prod/boost/boost_math_tr1l",
            "//foundation-drops/boost/g2012.03/prod/boost/boost_prg_exec_monitor",
            "//foundation-drops/boost/g2012.03/prod/boost/boost_program_options",
            "//foundation-drops/boost/g2012.03/prod/boost/boost_random",
            "//foundation-drops/boost/g2012.03/prod/boost/boost_regex",
            "//foundation-drops/boost/g2012.03/prod/boost/boost_serialization",
            "//foundation-drops/boost/g2012.03/prod/boost/boost_signals",
            "//foundation-drops/boost/g2012.03/prod/boost/boost_system",
            "//foundation-drops/boost/g2012.03/prod/boost/boost_test_exec_monitor",
            "//foundation-drops/boost/g2012.03/prod/boost/boost_thread",
            "//foundation-drops/boost/g2012.03/prod/boost/boost_timer",
            "//foundation-drops/boost/g2012.03/prod/boost/boost_unit_test_framework",
            "//foundation-drops/boost/g2012.03/prod/boost/boost_wave",
            "//foundation-drops/boost/g2012.03/prod/boost/boost_wserialization",
            "//foundation-drops/boost/g2012.03/prod/boost/doc",
            "//foundation-drops/boost/g2012.03/prod/boost/lib-aix64",
            "//foundation-drops/boost/g2012.03/prod/boost/lib-amd64",
            "//foundation-drops/boost/g2012.03/prod/boost/lib-linux",
            "//foundation-drops/boost/g2012.03/prod/boost/lib-rs6000",
            "//foundation-drops/boost/g2012.03/prod/boost/lib-sparc64",
            "//foundation-drops/boost/g2012.03/prod/boost/lib-sparcOS5",
            "//foundation-drops/boost/g2012.03/prod/boost/lib-suse32",
            "//foundation-drops/boost/g2012.03/prod/boost/lib-suse64",
            "//foundation-drops/boost/g2012.03/prod/boost/lib-x86sol32",
            "//foundation-drops/boost/g2012.03/prod/boost/lib-x86sol64"      
        ]
    );

    my %test3 = (
        'string'   => "//sde-drops/.test/*",
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
        'string'   => "//foundation-drops/boost/h2013.03/prod/*/*",       
        'expect' => [
            "//foundation-drops/boost/h2013.03/prod/boost-windows-debug/lib-win32",
            "//foundation-drops/boost/h2013.03/prod/boost-windows-debug/lib-win64",
            "//foundation-drops/boost/h2013.03/prod/boost-windows/lib-win32",
            "//foundation-drops/boost/h2013.03/prod/boost-windows/lib-win64",
            "//foundation-drops/boost/h2013.03/prod/boost/boost",
            "//foundation-drops/boost/h2013.03/prod/boost/boost_chrono",
            "//foundation-drops/boost/h2013.03/prod/boost/boost_date_time",
            "//foundation-drops/boost/h2013.03/prod/boost/boost_exception",
            "//foundation-drops/boost/h2013.03/prod/boost/boost_filesystem",
            "//foundation-drops/boost/h2013.03/prod/boost/boost_graph",
            "//foundation-drops/boost/h2013.03/prod/boost/boost_iostreams",
            "//foundation-drops/boost/h2013.03/prod/boost/boost_locale",
            "//foundation-drops/boost/h2013.03/prod/boost/boost_math_c99",
            "//foundation-drops/boost/h2013.03/prod/boost/boost_math_c99f",
            "//foundation-drops/boost/h2013.03/prod/boost/boost_math_c99l",
            "//foundation-drops/boost/h2013.03/prod/boost/boost_math_tr1",
            "//foundation-drops/boost/h2013.03/prod/boost/boost_math_tr1f",
            "//foundation-drops/boost/h2013.03/prod/boost/boost_math_tr1l",
            "//foundation-drops/boost/h2013.03/prod/boost/boost_prg_exec_monitor",
            "//foundation-drops/boost/h2013.03/prod/boost/boost_program_options",
            "//foundation-drops/boost/h2013.03/prod/boost/boost_random",
            "//foundation-drops/boost/h2013.03/prod/boost/boost_regex",
            "//foundation-drops/boost/h2013.03/prod/boost/boost_serialization",
            "//foundation-drops/boost/h2013.03/prod/boost/boost_signals",
            "//foundation-drops/boost/h2013.03/prod/boost/boost_system",
            "//foundation-drops/boost/h2013.03/prod/boost/boost_test_exec_monitor",
            "//foundation-drops/boost/h2013.03/prod/boost/boost_thread",
            "//foundation-drops/boost/h2013.03/prod/boost/boost_timer",
            "//foundation-drops/boost/h2013.03/prod/boost/boost_unit_test_framework",
            "//foundation-drops/boost/h2013.03/prod/boost/boost_wave",
            "//foundation-drops/boost/h2013.03/prod/boost/boost_wserialization",
            "//foundation-drops/boost/h2013.03/prod/boost/doc",
        ]
    );

    my @tests_nullval = (\%test0, \%test1, \%test2, \%test3, \%test4, \%test5, \%test6);
    foreach my $cnt (@tests_nullval) {

        my %testcase = %{$cnt};
        my @out      = da_p4_dirs( $testcase{string} );        
        is_deeply (\@out, $testcase{expect}, $subname);

    }  

}

1;

