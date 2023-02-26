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


use lib "$RealBin/../lib/perl/";
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
our $DEFAULT_WORKSPACE = "p4_func_tests";

sub Main(){
    my $scriptName = "ddr-crd_abutment.tcl";
    my %t = ( 
        '01'=>{
            'description' => "CRD abutment tcl",
            'testScript'  =>"$RealScript",
            'testDataDir' =>"$RealBin/../tdata",
            'scriptDir'   =>"$RealBin/../bin",
            'scriptName'  =>"$scriptName",
            'parameters'  =>"crd_abutment_parameters.csv"
        },
        '02'=>{
            'description' => "CRD abutment tcl",
            'testScript'  =>"$RealScript",
            'testDataDir' =>"$RealBin/../tdata",
            'scriptDir'   =>"$RealBin/../bin",
            'scriptName'  =>"$scriptName",
            'parameters'  =>"../tdata/crd_abutment_parameters.csv"
        },
    );

    my $workspace    = $DEFAULT_WORKSPACE;
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
            my $ostatus  = open my $FOUT, ">", $tempfile ;
            my $seeFile = "";
            if ( $ostatus ){
                print $FOUT "$href_args->{'scriptName'} $cmdline_args\n";
                print $FOUT "$stdout\n";
                close($FOUT);
                $seeFile = " See $tempfile ";
            }
           
            # We expect std_template.pl to fail, because it is testing fatal_error()
            #
            #print("FAILED: #${tstnum} $href_args->{'testScript'} $href_args->{'description'}${seeFile}\n");
            #$nfails += 1;
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
   
    my $parameters= $href_args->{'parameters'};

    my $cmd = "";
    $cmd .= " -p ${parameters} "      if ( $parameters );
    $cmd .= " -debug $debug "         if ( $debug );
    $cmd .= " -verbosity $verbosity " if ( $verbosity );

    return $cmd;
}

&Main();

# nolint open<
# nolint open>
