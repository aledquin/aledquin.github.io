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
our $DDR_DA_DEFAULT_P4WS = "./";
our $TEMPDIR = "/tmp";

sub my_comparator($$$$){
    my $workspace   = shift;
    my $testDataDir = shift;
    my $testScript  = shift;
    my $testNumber  = shift;
    my $testData    = shift;
    #my $KGR = "$testDataDir/lib_validation/csvfiles/dwc_lpddr5xphy_txrxac_ew_15M_1X_h_1Xb_v_1Xe_h_1Ya_v_1Yb_h_5Y_vhvhv_2Yy2Z_tt0p75v25c_pg.csv";

	my $currData = "./csvfiles/dwc_lpddr5xphy_txrxac_ew_15M_1X_h_1Xb_v_1Xe_h_1Ya_v_1Yb_h_5Y_vhvhv_2Yy2Z_tt0p75v25c_pg.csv";
	my ($output, $status) = run_system_cmd("diff -qBw $currData $testData",0);
    if($output =~ m/differ/g)  {
	    return(1);
	}
    return 0;
}

sub Main(){
    my $scriptName = "lib_validation.pl";
    my %t = ( 
        '00'=>{
            'description' => "helpfunction/exitstatus",
            'testScript'  =>"$RealScript",
            'testDataDir' =>"$RealBin/../data",
            'scriptDir'   =>"$RealBin/../../bin",
            'scriptName'  =>"$scriptName",
            'corner'      =>"",
            'metalstack'  =>"",
            'localpath'   =>"",
            'macro'       =>"",
            'extraArgs'   =>"-help",
        },
        '01'=>{
            'description' => "Test",
            'testScript'  =>"$RealScript",
            'testDataDir' =>"$RealBin/../data",
            'scriptDir'   =>"$RealBin/../../bin",
            'scriptName'  =>"$scriptName",
            'corner'      =>"tt0p75v25c",
            'metalstack'  =>"15M_1X_h_1Xb_v_1Xe_h_1Ya_v_1Yb_h_5Y_vhvhv_2Yy2Z",
            'localpath'   =>"$RealBin/../data",
            'macro'       =>"dwc_lpddr5xphy_txrxac_ew",
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
			"$href_args->{'testDataDir'}/lib_validation/csvfiles/dwc_lpddr5xphy_txrxac_ew_15M_1X_h_1Xb_v_1Xe_h_1Ya_v_1Yb_h_5Y_vhvhv_2Yy2Z_tt0p75v25c_pg.csv",
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

    my $metalstack = $href_args->{'metalstack'};
    my $localpath  = $href_args->{'localpath'};
    my $macro      = $href_args->{'macro'};
    my $corner     = $href_args->{'corner'};
   
    my $cmd = "";
    $cmd .= " -macro '$macro' ";
    $cmd .= " -corner '$corner' ";
    $cmd .= " -localpath '$localpath' ";
    $cmd .= " -metalstack $metalstack " ;
    $cmd .= " -debug $debug "         if ( $debug );
    $cmd .= " -verbosity $verbosity " if ( $verbosity );
    return $cmd;

}

&Main();



