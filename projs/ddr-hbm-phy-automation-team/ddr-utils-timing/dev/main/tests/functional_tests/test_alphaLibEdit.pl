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


use lib "$RealBin/../../lib/perl/";
use Util::CommonHeader;
use Util::Misc;
use Util::Messaging;
use lib "$RealBin/lib";
use TestUtils;

our $STDOUT_LOG   = undef; 
our $DEBUG        = NONE;
our $VERBOSITY    = NONE;
our $PROGRAM_NAME = $RealScript;
our $AUTO_APPEND_NEWLINE = 1;
our $DDR_DA_DEFAULT_P4WS = "p4_func_tests";
our $TEMPDIR = "/tmp";

sub my_comparator($$$$){
    my $workspace   = shift;
    my $testDataDir = shift;
    my $testScript  = shift;
    my $testNumber  = shift;
    my $testData    = shift;
    

	my $currData = "./libEdit/dwc_lpddr5xphy_lstx_dx5_ew_15M_1X_h_1Xb_v_1Xe_h_1Ya_v_1Yb_h_5Y_vhvhv_2Yy2Z_ffg0p825v0c.lib";
	my ($output, $status) = run_system_cmd("diff -qBw $currData $testData",0);
    if(($output =~ m/differ/g) or ($output =~ /No such file or directory/g)) {
	    return(1);
	}
    return 0;
}

sub Main(){
    my $scriptName = "alphaLibEdit.pl";
    my %t = ( 
        '00'=>{
            'description' => "helpfunction/exitstatus",
            'testScript'  =>"$RealScript",
            'testDataDir' =>"$RealBin/../data",
            'scriptDir'   =>"$RealBin/../../bin",
            'scriptName'  =>"$scriptName",
            'Config'      =>"",
            'RefLib'      =>"",
            'outdir'      =>"",
            'extraArgs'   =>"-help",
        },
        '01'=>{
            'description' => "Test",
            'testScript'  =>"$RealScript",
            'testDataDir' =>"$RealBin/../data",
            'scriptDir'   =>"$RealBin/../../bin",
            'scriptName'  =>"$scriptName",
            'Config'      =>"$RealBin/../data/alphaLibEdit/merge.cfg",
            'RefLib'      =>"$RealBin/../data/alphaLibEdit/dwc_lpddr5xphy_lstx_dx5_ew_reset/dwc_lpddr5xphy_lstx_dx5_ew_15M_1X_h_1Xb_v_1Xe_h_1Ya_v_1Yb_h_5Y_vhvhv_2Yy2Z_ffg0p825v0c.lib",
            'outdir'      =>"libEdit",
            'extraArgs'   =>"$RealBin/../data/alphaLibEdit/dwc_lpddr5xphy_lstx_dx5_ew_normal/dwc_lpddr5xphy_lstx_dx5_ew_15M_1X_h_1Xb_v_1Xe_h_1Ya_v_1Yb_h_5Y_vhvhv_2Yy2Z_ffg0p825v0c.lib",
        }
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
    foreach my $tstnum (sort keys %t) {
        if ( $opt_tnum ) {
            my $num = $tstnum + 0;     # convert string of number to a number
            next if ( $num != $opt_tnum );
        }

        my $href_args = $t{"$tstnum"};
        viprint(LOW, "Running $href_args->{'testScript'} $tstnum\n");
        my $cmdline_args = create_cmdline_args( $href_args, $workspace );

        dprint(LOW, "\$cmdline_args = '$cmdline_args'\n");
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
			\&my_comparator,
			"$href_args->{'testDataDir'}/alphaLibEdit/libEdit/dwc_lpddr5xphy_lstx_dx5_ew_15M_1X_h_1Xb_v_1Xe_h_1Ya_v_1Yb_h_5Y_vhvhv_2Yy2Z_ffg0p825v0c.lib",
        );

       if ( $status != 0 ){
            dprint(LOW, "$tstnum: common main returned status = $status\n");
            my $tempfile = "${TEMPDIR}/${tstnum}_$href_args->{'testScript'}_$$.log";
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


    if ( $nfails ){
        print("FAILED: ($nfails/$ntests) $RealScript\n");
    }else{
        print("PASSED: ($ntests/$ntests) $RealScript\n");
    }

    
    exit($nfails);
}


sub create_cmdline_args($;$){
    my $href_args = shift;
    my $verbosity = $main::VERBOSITY;
    my $debug     = $main::DEBUG;

    my $config  = $href_args->{'Config'};
    my $RefLib  = $href_args->{'RefLib'};
    my $outdir  = $href_args->{'outdir'};
    my $extra   = $href_args->{'extraArgs'};
   
    my $cmd = "";
    $cmd .= " -Config '$config' ";
    $cmd .= " -RefLib '$RefLib' ";
    $cmd .= " -outdir '$outdir' ";
    $cmd .= "  $extra " ;
    $cmd .= " -debug $debug "         if ( $debug );
    $cmd .= " -verbosity $verbosity " if ( $verbosity );
    return $cmd;

}

&Main();



