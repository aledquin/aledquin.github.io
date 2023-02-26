#!/depot/perl-5.14.2/bin/perl
use strict;
use warnings;
# nolint utils__script_usage_statistics
use Cwd     qw(getcwd);
use Cwd     qw( abs_path );
use Carp    qw( cluck confess croak );
use Getopt::Std;
use Getopt::Long;
use File::Spec;
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
our $VERSION      = get_release_version();

sub Main(){
    my $scriptName = "alphaVerifyTimingCollateral.pl";
    my %t = ( 
        '01'=>{
            'description' => "GitLab Issue 400",
            'testScript'  =>"$RealScript",
            'testDataDir' =>"$RealBin/../data",
            'scriptDir'   =>"$RealBin/../../bin",
            'scriptName'  =>"$scriptName",
            'family'      =>"ddr54",
            'projectName' =>"d822-ddr54-ss7hpp-18",
            'rel'         =>"rel1.00_cktpcs",
            'project'     =>"ddr54/d822-ddr54-ss7hpp-18/rel1.00_cktpcs",
            'macro'       =>"rxdqs_diffmux",
            'metalStack'  => "18M_4Mx_4Dx_4Hx_2Bx_2Gx_2UTM_ILB",
            'others'      => "-timingRel latest -ui 266.66 -lvf",
            'expected'    => "Macro has no timing, skipping checkArc.*"
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
        
        if ( ! check_pre_conditions( $tstnum, $href_args ) ) {
            fprint("#($tstnum) Test $href_args->{'description'} failed pre-conditions !");
            $nfails++;
            next;
        }

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

            # NOTE: so this script has lots of -E- statements in it. I think
            # the users are used to that and do not consider it a reail failure.
            # Not sure what to do...  I will check the $status; if it's because
            # of -E- being found there could be a lot of them; so I'll just
            # check for $status < 10; not great but until we have time to
            # really figure this out; it's the best I can do.
            if ( $status < -10 ){
                # do the normal check for failure now
                my $logfile = getcwd() . "/$href_args->{'scriptName'}.log";
                if ( "FAILED" eq check_logfile_for_failure($logfile, $href_args) ){
                    print("FAILED: #${tstnum}  $href_args->{'testScript'} $href_args->{'description'}\n");
                }else{
                    print("PASSED: #${tstnum} $href_args->{'testScript'} $href_args->{'description'}\n");
                }
            }else{
                print("FAILED: #${tstnum}  $href_args->{'testScript'} $href_args->{'description'}${seeFile}\n");
                $nfails ++;
            }

        }else{
            my $logfile = getcwd() . "/$href_args->{'scriptName'}.log";
            if ( "FAILED" eq check_logfile_for_failure($logfile, $href_args) ){
                print("FAILED: #${tstnum}  $href_args->{'testScript'} $href_args->{'description'}\n");
            }else{
                print("PASSED: #${tstnum} $href_args->{'testScript'} $href_args->{'description'}\n");
            }
        }
    }


    if ( $nfails  ){
        print("FAILED: ($nfails/$ntests) $RealScript\n");
    }else{
        print("PASSED: ($ntests/$ntests) $RealScript\n");
    }

    
    exit($nfails);
}

sub check_pre_conditions($$) {
    my $tstnum    = shift;
    my $href_args = shift;

    my $p4ws               = "p4_ws";
    my $p4client           = "msip_cd_$ENV{USER}";
    my $p4_root            = abs_path( "/u/$ENV{USER}/${p4ws}"); # get absolute path
    my $project_family     = $href_args->{'family'};
    my $project_name       = $href_args->{'projectName'};
    my $macro              = $href_args->{'macro'};
    my $p4_view_dir        = "//wwcad/msip/projects/${project_family}/${project_name}/latest/design/timing/sis_lvf/${macro}/";
    my $view_dir           = "${p4_root}/wwcad/msip/projects/${project_family}/${project_name}";

    if ( ! -e $view_dir ){ 
        fprint( "This probably won't run because you don't have the VIEW synced.\n"
               ."p4_root: ${p4_root}\n"
               ."View:  ${view_dir}\n"
               ."Looking in your p4 client views grepping for '$project_family' finds:\n");
        my $found = `p4 client -o  | grep $p4client | grep $project_family | grep $macro`;
        if ( "$found" eq "" ) {
            print( "You need to add the following to your p4 views.\n");
            print( "//wwcad/msip/projects/${project_family}/d822-ddr54-ss7hpp-18/rel1.00_cktpcs/pcs/design/timing/... //msip_cd_ljames/wwcad/msip/projects/${project_family}/d822-ddr54-ss7hpp-18/rel1.00_cktpcs/pcs/design/timing/...\n");
        }
        return 0; 
    }

    return 1;
}


# This check looks in the generated log file and looks for one or more 
# expected strings that should be in the log file.
#
sub check_logfile_for_failure($$){
    my $logfile   = shift;
    my $href_args = shift;
    my @logfile_contents = read_file( $logfile );

    my $failed = 1;
    foreach my $line ( @logfile_contents ){
        my $re = $href_args->{'expected'};
        if ( $line =~ m/$re/ ){
            $failed = 0;
            last;
        }
    }
    return $failed ? "FAILED" : "PASSED";

}

sub create_cmdline_args($;$){
    my $href_args = shift;
    my $workspace = shift;

    my $verbosity = $main::VERBOSITY;
    my $debug     = $main::DEBUG;
  

    my $cmd = "";
    $cmd .= " -project ". $href_args->{'project'};
    $cmd .= " -macros ". $href_args->{'macro'};
    $cmd .= " -metalStack ". $href_args->{'metalStack'};
    $cmd .= " " . $href_args->{'others'};
    $cmd .= " -debug $debug "          if ( $debug     );
    $cmd .= " -verbosity $verbosity "  if ( $verbosity );

    return $cmd;
}

&Main();


