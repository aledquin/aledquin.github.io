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
my $DDR_DA_DEFAULT_P4WS = "p4_func_tests";
our $LOCAL_COMPARE_FAIL_REASON = "";

sub Main(){
    my $scriptName = "genTechrevFile.pl";
    my %t = ( 
        '01'=>{
            'description' => "genTechrevFile test",
            'testScript'  =>"$RealScript",
            'testDataDir' =>"$RealBin/../data",
            'scriptDir'   =>"$RealBin/../../bin",
            'scriptName'  =>"$scriptName",
            'cdlFile'     =>"$scriptName/dwc_lpddr5xphy_techrevision.cdl",
            'outputFile'  =>"$scriptName/new_techrevision.v",
            'goldenFile'  =>"$scriptName/techrevision.v",
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

        $main::LOCAL_COMPARE_FAIL_REASON = ""; # this can get changed by the comparator
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
            \&mycompare,
            $href_args
        );

       if ( $status != 0 ){
            dprint(LOW, "$tstnum: common main returned status = $status\n");
            my $tempfile = "/tmp/${tstnum}_$href_args->{'testScript'}_$$.log";
            my $ostatus  = open my $FOUT, ">", $tempfile ; #nolint open>
            my $seeFile = "";
            if ( $ostatus ){
                print $FOUT "$href_args->{'scriptName'} $cmdline_args\n";
                print $FOUT "$stdout\n";
                print $FOUT "$main::LOCAL_COMPARE_FAIL_REASON\n" if $main::LOCAL_COMPARE_FAIL_REASON;
                close($FOUT);
                $seeFile = " See $tempfile ";
            }
           
            print("FAILED: #${tstnum} $href_args->{'testScript'} $href_args->{'description'}${seeFile}\n");
            $nfails += 1;
        }else{
            print("PASSED: #${tstnum} $href_args->{'testScript'} $href_args->{'description'}\n");
            my $temp_file = "$href_args->{'testDataDir'}/$href_args->{'outputFile'}";
            if ( -e $temp_file ){ 
                unlink($temp_file);
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
sub mycompare($$$$;$){
    my $workspace   = shift;
    my $testDataDir = shift;
    my $testScript  = shift;
    my $testNumber  = shift;
    my $href_args   = shift;  # href 

    my $nerrors     = 0;

    my $diff_options = " -w -B -d --strip-trailing-cr";
    my $golden_file = "${testDataDir}/$href_args->{'goldenFile'}" ;
    my $new_file    = "${testDataDir}/$href_args->{'outputFile'}" ;
    my ($diff, $err)= run_system_cmd("diff $diff_options $golden_file $new_file");
    chomp $diff;
    if ( $diff ne EMPTY_STR ) {
        $main::LOCAL_COMPARE_FAIL_REASON = "test_genTechrevFile.pl:mycompare: diff shows a difference between golden:$golden_file and new:$new_file\n$diff";
        eprint( " $main::LOCAL_COMPARE_FAIL_REASON \n" );
        return 1;
    }
    return 0;
}

sub create_cmdline_args($;$){
    my $href_args = shift;
    my $workspace = shift;

    my $verbosity = $main::VERBOSITY;
    my $debug     = $main::DEBUG;
    my $cdl       = $href_args->{'cdlFile'};
    my $output    = $href_args->{'outputFile'};
   
    my $cmd = "";
    $cmd .= " -cdl $href_args->{'testDataDir'}/${cdl}"       if ( $cdl       );
    $cmd .= " -output $href_args->{'testDataDir'}/${output}" if ( $output    );
    $cmd .= " -debug $debug "                                if ( $debug     );
    $cmd .= " -verbosity $verbosity "                        if ( $verbosity );


    return $cmd;
}

&Main();


