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

sub Main(){
    my $scriptName = "pin_check__ckt_specs.py";
    my %t = (
        '01'=>{
            'description' => "testing with remote rxacvref files",
            'testScript'  =>"$RealScript",
            'testDataDir' =>"$RealBin/../data",
            'scriptDir'   =>"$RealBin/../../bin",
            'scriptName'  =>"$scriptName",
            'pathspec'    =>"//depot/products/lpddr5x_ddr5_phy/lp5x/common/ckt_specs/dwc_lpddr5xphy_rxacvref_spec.docx#10",
            'pinpath'     =>"//depot/products/lpddr5x_ddr5_phy/lp5x/project/d930-lpddr5x-tsmc5ff12/ckt/rel/dwc_lpddr5xphy_rxacvref_ew/3.00a/macro/pininfo/dwc_lpddr5xphy_rxacvref_ew.csv#2",
        },
        '02'=>{
            'description' => "testing with rxacvref from data",
            'testScript'  =>"$RealScript",
            'testDataDir' =>"$RealBin/../data",
            'scriptDir'   =>"$RealBin/../../bin",
            'scriptName'  =>"$scriptName",
            'pathspec'    =>"$RealBin/../data/pincheck/lp5xspecs/dwc_lpddr5xphy_rxacvref_spec#10.docx",
            'pinpath'     =>"$RealBin/../data/pincheck/lp5xspecs/dwc_lpddr5xphy_rxacvref_ew#2.csv",
        },
        '03'=>{
            'description' => "testing with lstx_dx4 pin info with lstx spec that has multiple macros",
            'testScript'  =>"$RealScript",
            'testDataDir' =>"$RealBin/../data",
            'scriptDir'   =>"$RealBin/../../bin",
            'scriptName'  =>"$scriptName",
            'pathspec'    =>"$RealBin/../data/pincheck/lp5xspecs/dwc_lpddr5xphy_lstxacx2_lstxcsx2_lstxdx4_lstxdx5_lstxzcal_spec_copy.docx",
            'pinpath'     =>"$RealBin/../data/pincheck/lp5xspecs/dwc_lpddr5xphy_lstx_dx4_ew.csv",
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
    foreach my $tstnum (sort keys %t) {
        if ( $opt_tnum ) {
            my $num = $tstnum + 0;     # convert string of number to a number
            next if ( $num != $opt_tnum );
        }
        my $href_args = $t{"$tstnum"};
        viprint(LOW, "Running $href_args->{'testScript'} $tstnum\n");
        my $cmdline_args = create_cmdline_args( $href_args,  $workspace );

        my ($status,$stdout,$realStatus) = test_scripts__main(
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
            dprint(LOW, "$tstnum: test_scripts__main returned status = $status\n");
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
            if ( $opt_cleanup ) {
                my @genfiles = qw( pin_check__ckt_specs.py.log output.xlsx spec.docx new_file.csv );
                test_scripts__cleanup( @genfiles);
            }
        }
    }

    if ( $opt_coverage  && -e '.coverage' ) {
        my ($coutput, $cstatus) = run_system_cmd( '/depot/Python/Python-3.8.0/bin/coverage report', $main::VERBOSITY );
        print($coutput);
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
    my $workspace = shift;
    my $verbosity = $main::VERBOSITY;
    my $debug     = $main::DEBUG;

    my $pathspec = $href_args->{'pathspec'};
    my $pinpath  = $href_args->{'pinpath'};
    my $extra    = $href_args->{'extraArgs'};

    my $cmd = "";
    $cmd .= " ${pathspec} ";
    $cmd .= " ${pinpath} ";
    #$cmd .= " -p4ws ${workspace} " if ( $workspace );
    $cmd .= " ${extra} "           if ( $extra );
    $cmd .= " -d $debug "          if ( $debug );
    $cmd .= " -v $verbosity "      if ( $verbosity );

    return $cmd;
}

&Main();


