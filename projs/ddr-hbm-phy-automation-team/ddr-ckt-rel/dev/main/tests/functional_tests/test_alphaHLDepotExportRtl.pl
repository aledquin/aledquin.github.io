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
my $DDR_DA_DEFAULT_P4WS = "p4_funct_tests";

sub Main(){
    my $WorkSpace;
    my $opt_cleanup  = 1;
    my $opt_coverage = 1;
    my $opt_help     = 0;
    my $opt_tnum     = 0;

    $WorkSpace = $ENV{'DDR_DA_DEFAULT_P4WS'} || $DDR_DA_DEFAULT_P4WS;
    ($WorkSpace, $opt_cleanup, $opt_coverage, $opt_help, $opt_tnum) = 
        test_scripts__get_options( $WorkSpace );

    if ( $opt_help ) {
        exit(0);
    }

    $opt_coverage = 0; # we do not have coverage working for non-perl script


    # Setting this will stop the script from doing <STDIN> statements. We
    # need to do this to ensure the script does not stall on us waiting for
    # user input.
    $ENV{'DA_RUNNING_UNIT_TESTS'} = 1;

    my $scriptName = "alphaHLDepotExportRtl.tcl";

    #--------------------------
    # Setup cmd line opts
    #--------------------------
    my $opt_verbosity = "";
    my $opt_debug     = "";
    if( $VERBOSITY ){ $opt_verbosity = "-v $VERBOSITY"; }
    if( $DEBUG     ){ $opt_debug     = "-d $DEBUG"; }
    #--------------------------
    my %t = ( 
        '01'=>{
            'description' => "lp5x d931",
            'testScript'  => "$RealScript",
            'testDataDir' => "$RealBin/../data",
            'scriptDir'   => "$RealBin/../../bin",
            'scriptName'  => "$scriptName",
            'cmdline_args'=> "-p lpddr5x/d931-lpddr5x-tsmc3eff-12/rel1.00_cktpcs  -t $opt_verbosity $opt_debug",
        },
        '02'=>{
            'description' => "lp5x d930",
            'testScript'  => "$RealScript",
            'testDataDir' => "$RealBin/../data",
            'scriptDir'   => "$RealBin/../../bin",
            'scriptName'  => "$scriptName",
            'cmdline_args'=> "-p lpddr5x/d930-lpddr5x-tsmc5ff12/rel1.00_cktpcs  -t $opt_verbosity $opt_debug",
        },
    );

    # the script under test doesn't accept a workspace option
    if( defined $WorkSpace ){
        eprint( "At command line, workspace specified '-p4ws'. This script does not use/need the p4 workspace. Setting p4ws='undef' ...\n" );
        $WorkSpace = undef;
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
        hprint( "$href_args->{'testScript'} $href_args->{'cmdline_args'} \n" );

        my ($status,$stdout) = test_scripts__main(
            $tstnum, $opt_cleanup, $opt_coverage,
            $href_args->{'testScript'},
            $href_args->{'testDataDir'},
            $href_args->{'scriptDir'},
            $href_args->{'scriptName'},
            $href_args->{'cmdline_args'},
            undef, undef
        );
        if ( $status != 0 ){
            dprint(LOW, "$tstnum: common main returned status = $status\n");
            my $tempfile = "/tmp/${tstnum}_$href_args->{'testScript'}_$$.log";
            my $ostatus  = open my $FOUT, ">", $tempfile ; #nolint open>
            my $seeFile = "";
            if ( $ostatus ){
                print $FOUT "$href_args->{'scriptName'} $href_args->{'cmdline_args'}\n";
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


&Main();


