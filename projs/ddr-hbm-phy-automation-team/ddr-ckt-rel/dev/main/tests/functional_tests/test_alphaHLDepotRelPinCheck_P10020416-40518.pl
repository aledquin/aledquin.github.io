#!/depot/perl-5.14.2/bin/perl
#+
# Requirements:
#
#     p4 sync -f //depot/products/lpddr5x_ddr5_phy/lp5x/project/d932-lpddr5x-tsmc4ffp-12/ckt/rel/dwc_lpddr5xphy_repeater_cells/2.00a/...
#     p4 sync -f //depot/products/lpddr5x_ddr5_phy/ddr5/project/d912-ddr5-tsmc3eff-12/ckt/rel/dwc_ddr5phy_utility_blocks/1.00a/... 
#-
use strict;
use warnings;
# nolint utils__script_usage_statistics
use Cwd     qw(getcwd);
use Cwd     qw( abs_path );
use Carp    qw( cluck confess croak );
use Getopt::Std;
use Getopt::Long;
use File::Copy;
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
my $DDR_DA_DEFAULT_P4WS = "p4_func_tests";

&Main();

sub Main(){
    my $USER        = get_username();
    my $scriptName  = "alphaHLDepotRelPinCheck";
    my %t = (
        '01'=>{
            'description' =>"dwc_lpddr5xphy_repeater_cells",
            'testScript'  =>"$RealScript",
            'testDataDir' =>"$RealBin/../data",
            'scriptDir'   =>"$RealBin/../../bin",
            'scriptName'  =>"$scriptName",
            'product'     =>"lpddr5x",
            'subDir'      =>"lp5x",
            'dproduct'    =>"lpddr5x_ddr5_phy",   # on disk in /depot this is the product name
            'project'     =>"d932-lpddr5x-tsmc4ffp-12",
            'release'     =>"rel1.00_cktpcs",
            'verDir'      =>"2.00a",
            'macro'       =>"dwc_lpddr5xphy_repeater_cells",
        },
        '02'=>{
            'description' =>"dwc_ddr5phy_utility_blocks",
            'testScript'  =>"$RealScript",
            'testDataDir' =>"$RealBin/../data",
            'scriptDir'   =>"$RealBin/../../bin",
            'scriptName'  =>"$scriptName",
            'product'     =>"ddr5",
            'subDir'      =>"ddr5",
            'dproduct'    =>"lpddr5x_ddr5_phy",   # on disk in /depot this is the product name
            'project'     =>"d912-ddr5-tsmc3eff-12",
            'release'     =>"rel1.00_cktpcs",
            'verDir'      =>"1.00a",
            'macro'       =>"dwc_ddr5phy_utility_blocks",
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
    if ( $opt_help ){
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

        my $prod = $href_args->{'product'};
        my $dprod= $href_args->{'dproduct'};
        my $proj = $href_args->{'project'};
        my $mac  = $href_args->{'macro'};
        my $subDir = $href_args->{'subDir'};
        my $verDir = $href_args->{'verDir'};

        my $pincheck_fname = "/u/$USER/$workspace/depot/products/${dprod}/${subDir}/project/${proj}/ckt/rel/${mac}/${verDir}/macro/${mac}.pincheck";
        my $pincheck = abs_path( $pincheck_fname ); 
        if ( ! defined $pincheck ){
            my $tempfile = "/tmp/${tstnum}_$href_args->{'testScript'}_$$.log";
            my $ostatus  = open my $FOUT, ">", $tempfile ; #nolint open>
            my $seeFile = "";
            if ( $ostatus ){
                print $FOUT "$href_args->{'scriptName'} $cmdline_args\n";
                print $FOUT "Unable to locate file $pincheck_fname!\n";
                print $FOUT "Try doing a p4 sync:\n";
                print $FOUT "\tp4 sync -f //depot/products/${dprod}/${subDir}/project/${proj}/ckt/rel/${mac}/${verDir}/...\n";
                print $FOUT "$stdout\n";
                close($FOUT);
                $seeFile = " See $tempfile ";
            }
            print("FAILED: #${tstnum} $href_args->{'testScript'} $href_args->{'description'}${seeFile}\n");
            $nfails += 1;
            exit -1;
        }


        if ( $status != 0 ){
            dprint(LOW, "$tstnum: common main returned status = $status\n");
            my $tempfile = "/tmp/${tstnum}_$href_args->{'testScript'}_$$.log";
            my $ostatus  = open my $FOUT, ">", $tempfile ; #nolint open>
            my $seeFile = "";
            if ( $ostatus ){
                print $FOUT "$href_args->{'scriptName'} $cmdline_args\n";
                print $FOUT "Pincheck: $pincheck_fname\n";
                print $FOUT "$stdout\n";
                close($FOUT);
                $seeFile = " See $tempfile ";
            }
            
            print("FAILED: #${tstnum} $href_args->{'testScript'} $href_args->{'description'}${seeFile}\n");
            $nfails += 1;
        }else{
            my $found_NA = `grep "missing in " $pincheck_fname`;
            if ( $found_NA ne ""){
                $nfails++;
                # copy pincheck to /tmp
                my $tempfile = "/tmp/${tstnum}_$href_args->{'testScript'}_$$.pincheck.log";
                copy( $pincheck, $tempfile);
                print("FAILED: #${tstnum} $href_args->{'testScript'} $href_args->{'description'} Because we see 'missing in ' in the pincheck file. See $tempfile \n");
            }else{
                gprint("PASSED: #${tstnum} $href_args->{'testScript'} $href_args->{'description'}\n");
            }
        }
    }
}

sub create_cmdline_args($;$){
    my $href_args = shift;
    my $workspace = shift;
    my $verbosity = $main::VERBOSITY;
    my $debug     = $main::DEBUG;
   
    my $prod = $href_args->{'product'};
    my $proj = $href_args->{'project'};
    my $rel  = $href_args->{'release'};
    my $macro= $href_args->{'macro'};
    my $extra= $href_args->{'extraArgs'};

    my $cmd = "";
    $cmd .= " -p '$prod/$proj/$rel' ";
    $cmd .= " -p4ws ${workspace} "    if ( $workspace );
    $cmd .= " -macros ${macro} "      if ( $macro );
    $cmd .= " ${extra} "              if ( $extra );
    $cmd .= " -debug $debug "         if ( $debug );
    $cmd .= " -verbosity $verbosity " if ( $verbosity );

    return $cmd;
}
sub display_help(){
    print("Usage:\n\n");
    print("\t$RealScript [-debug #] [-verbosity #] [-help]\n");
    print("\t    [-p4ws PATH] -[no]cleanup\n");
    print("\nDefaults:\n\n");
    print("\t-debug     0\n");
    print("\t-verbosity 0\n");
    print("\t-nohelp\n");
    print("\t-p4ws      '$DDR_DA_DEFAULT_P4WS'\n");
    print("\t-cleanup\n");
    return;
}

