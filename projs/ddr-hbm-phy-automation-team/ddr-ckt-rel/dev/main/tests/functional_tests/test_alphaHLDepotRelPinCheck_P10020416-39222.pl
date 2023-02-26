#!/depot/perl-5.14.2/bin/perl
use strict;
use warnings;
# nolint utils__script_usage_statistics
use Cwd     qw(getcwd);
use Cwd     qw( abs_path );
use Carp    qw( cluck confess croak );
use File::Copy;
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
    my $scriptName = "alphaHLDepotRelPinCheck";
    my $USER = get_username();
    my %t = (
        '01'=>{
            'description' => "dwc_ddrphy_repeater_blocks",
            'testScript'  =>"$RealScript",
            'testDataDir' =>"$RealBin/../data",
            'scriptDir'   =>"$RealBin/../../bin",
            'scriptName'  =>"$scriptName",
            'product'     =>"lpddr54",
            'project'     =>"d856-lpddr54-tsmc12ffc18",
            'release'     =>"rel2.00_cktpcs",
            'macro'       =>"dwc_ddrphy_repeater_blocks",
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
        my $proj = $href_args->{'project'};
        my $mac  = $href_args->{'macro'};
        my $pincheck = abs_path( "/u/$USER/$workspace/depot/products/${prod}/project/${proj}/ckt/rel/${mac}/2.00a/macro/${mac}.pincheck");


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
            my $found_NA = `grep "missing in 'N/A'" $pincheck`;
            if ( $found_NA ne ""){
                $nfails++;
                # copy pincheck to /tmp
                my $tempfile = "/tmp/${tstnum}_$href_args->{'testScript'}_$$.pincheck.log";
                copy( $pincheck, $tempfile);
                print("FAILED: #${tstnum} $href_args->{'testScript'} $href_args->{'description'} Because we see 'missing in N/A' in the pincheck file. See $tempfile \n");
            }else{
                gprint("PASSED: #${tstnum} $href_args->{'testScript'} $href_args->{'description'}\n");
            }
        }
    }


    if ( $nfails ){
        print("FAILED: ($nfails/$ntests) $RealScript\n");
    }else{
        gprint("PASSED: ($ntests/$ntests) $RealScript\n");
    }

    
    exit($nfails);
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

&Main();
