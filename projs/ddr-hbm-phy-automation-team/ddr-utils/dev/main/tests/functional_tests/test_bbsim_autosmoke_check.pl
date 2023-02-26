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

use lib "$RealBin/../../lib/perl";
use Util::CommonHeader;
use Util::Misc;
use Util::Messaging;
use lib "$RealBin/../lib";
use TestUtils;

our $STDOUT_LOG   = undef; 
our $DEBUG        = NONE;
our $VERBOSITY    = NONE;
our $PROGRAM_NAME = $RealScript;
our $AUTO_APPEND_NEWLINE = 1;
our $DDR_DA_DEFAULT_P4WS = "p4_func_tests";

sub Main(){
    my $scriptName = "bbsim_autosmoke_check.pl";
    my %t = ( 
        '01'=>{
            'description' => "bbsim autosmoke test",
            'testScript'  =>"$RealScript",
            'testDataDir' =>"$RealBin/../data",
            'scriptDir'   =>"$RealBin/../../bin",
            'scriptName'  =>"$scriptName",
            'p4Path'      =>"/projects/ddr54/tb/gr_ddr54/design/sim/dwc_ddrphy_rxdq/bbSim",
            'bbsim'       =>"tb_vreftop_codefit_post.bbSim",
        },
    );

    my $workspace    = $ENV{'DDR_DA_DEFAULT_P4WS'} || $DDR_DA_DEFAULT_P4WS;
    my $opt_cleanup  = 1;
    my $opt_coverage = 0;
    my $opt_help     = 0;
    my $opt_tnum     = 0;

    ($workspace, $opt_cleanup, $opt_coverage, $opt_help, $opt_tnum) = 
        test_scripts__get_options( $workspace );
    if ( ! $workspace ) {
        return -1;
    }
    if ( $opt_help ) {
        return 0;
    }

    my $ntests = keys(%t);
    my $nfails = 0;
    my $username = get_username();
    my $p4Root = abs_path("/u/$username/$workspace");
    my $p4RootFuncTests = "/slowfs/us01dwt2p387/juliano/func_tests";
    if ( ! -e $p4Root || ! -e "$p4Root/projects/ddr54/tb/gr_ddr54/design/sim/dwc_ddrphy_rxdq/bbSim" ) {
        $workspace = "p4_func_tests";
        $p4Root = $p4RootFuncTests;  # this should always exist and most likey working
    }

    foreach my $tstnum (sort keys %t) {
        if ( $opt_tnum ) {
            my $num = $tstnum + 0;     # convert string of number to a number
            next if ( $num != $opt_tnum );
        }
        my $href_args = $t{"$tstnum"};
        # We have to run our script within the test directory
        my $testDir = $p4Root . $href_args->{'p4Path'};
        if ( ! -e $testDir ) {
            $p4Root = $p4RootFuncTests;
            $workspace = "p4_func_tests";
            $testDir = $p4Root . $href_args->{'p4Path'};
        }
        viprint(LOW, "Running $href_args->{'testScript'} $tstnum\n");
        my $cmdline_args = create_cmdline_args( $href_args,  $workspace );


        chdir ( $testDir ); 
        my ($status,$stdout) = test_scripts__main(
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
           
            print("FAILED: #${tstnum} $href_args->{'testScript'} $href_args->{'description'}${seeFile}\n");
            $nfails += 1;
        }else{
            print("PASSED: #${tstnum} $href_args->{'testScript'} $href_args->{'description'}\n");
        }
    }

    if ( $nfails  ){
        print("FAILED: ($nfails/$ntests) $RealScript\n");
    }else{
        print("PASSED: ($ntests/$ntests) $RealScript\n");
    }
    
    exit($nfails);
}

sub create_cmdline_args($;$){
    my $href_args = shift;
    my $workspace = shift;

    my $verbosity = $main::VERBOSITY;
    my $debug     = $main::DEBUG;
    my $bbsim     = $href_args->{'bbsim'};

    my $cmd = "";
    $cmd .= " -debug $debug "          if ( $debug     );
    $cmd .= " -verbosity $verbosity "  if ( $verbosity );
    $cmd .= " -bbsim $bbsim"           if ( $bbsim );
    $cmd .= " -p4ws $workspace"        if ( $workspace );

    return $cmd;
}

&Main();

#Files that need to be synced for the func_test to pass:
#   p4 sync $HOME/p4_func_tests/projects/ddr54/tb/gr_ddr54/design/sim/dwc_ddrphy_rxdq/bbSim/tb_vreftop_codefit_post.bbSim#1
#   p4 sync $HOME/p4_func_tests/projects/ddr54/tb/gr_ddr54/design/sim/dwc_ddrphy_rxdq/corners/tb_vreftop_codefit.corners#1
#   p4 sync $HOME/p4_func_tests/projects/ddr54/tb/gr_ddr54/design/sim/dwc_ddrphy_rxdq/corners_ref/tb_vreftop_codefit.corners#1
#   p4 sync $HOME/p4_func_tests/projects/ddr54/tb/gr_ddr54/design/sim/dwc_ddrphy_rxdq/bbSim/measure/tb_vreftop_codefit.measure#2
#   p4 sync $HOME/p4_func_tests/projects/ddr54/tb/gr_ddr54/design/sim/dwc_ddrphy_rxdq/scripts/remove_after_sim.py#1
#   p4 sync $HOME/p4_func_tests/projects/ddr54/tb/gr_ddr54/design/sim/dwc_ddrphy_rxdq/scripts/tb_vreftop_codefit.py#1
#   p4 sync $HOME/p4_func_tests/projects/ddr54/tb/gr_ddr54/design/sim/dwc_ddrphy_rxdq/circuit/tb_vreftop_codefit_post.sp#1
