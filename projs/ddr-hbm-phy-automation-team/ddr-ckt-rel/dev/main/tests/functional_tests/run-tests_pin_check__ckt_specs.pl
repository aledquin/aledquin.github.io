#!/depot/perl-5.14.2/bin/perl

use strict;
use warnings;
# nolint utils__script_usage_statistics
use Cwd     qw(getcwd);
use Cwd     qw( abs_path );
use Carp    qw( cluck confess croak );
use Getopt::Std;
use Getopt::Long;
use File::Basename;
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
use Time::HiRes qw( usleep gettimeofday tv_interval clock_gettime clock_getres);

our $START_TIME;
sub start_timer() {
    $main::START_TIME = [ gettimeofday ];
    #print("Starting the clock\n");
}
sub end_timer() {
    my ($seconds, $microseconds) = gettimeofday;
    my $elapsed_time             = tv_interval( $START_TIME, [$seconds, $microseconds]);
    $elapsed_time = sprintf("%.1f", $elapsed_time);
    return "Elapsed Time: $elapsed_time (seconds)";
}


sub Main(){
    start_timer();
    # WorkSpace can be overidden with an env variable
    my $WorkSpace        = $ENV{'DDR_DA_DEFAULT_P4WS'} || $DDR_DA_DEFAULT_P4WS;
    my $opt_cleanup      = 1;
    my $opt_coverage     = 0;
    my $opt_help         = 0;
    my $opt_tnum         = 0;
    my $SOMETHING_FAILED = 0 ;

    my ($output, $ret_val) = run_system_cmd("ls -1 $RealBin/test_pin_check__ckt_specs*.pl" );
    my @tests = split(/\n/, $output);
    # Setting this env var will prevent scripts from hanging up on <STDIN>
    # calls. That is if the script is looking for the env var :)
    $ENV{'DA_RUNNING_UNIT_TESTS'} = '1';
    # Setting the following will prevent _usage_stats from being called; thus
    # speeding things up and not causing tests to bump the count up in the
    # usage database.
    $ENV{'DDR_DA_SKIP_USAGE'}     = '1';
    # Setting the following will indicate to scripts that popup a GUI to not
    # do that. But only if the script is looking for DA_TEST_NOGUI env var :)
    $ENV{'DA_TEST_NOGUI'}         = '1';

    ($WorkSpace, $opt_cleanup, $opt_coverage, $opt_help, $opt_tnum) = 
        test_scripts__get_options( $WorkSpace );

    if ( $opt_help ) {
        exit(0);
    }

    # Some passthru options, defaults are not enabled
    my $optCleanup   = "";
    my $optVerbosity = "";
    my $optDebug     = "";
    my $optCoverage  = "";
    my $optWorkspace = "";

    $optCleanup   = "-nocleanup"            if ( ! $opt_cleanup );
    $optVerbosity = "-verbosity $VERBOSITY" if ( $VERBOSITY > NONE);
    $optDebug     = "-debug $DEBUG"         if ( $DEBUG > NONE);
    $optCoverage  = "-coverage"             if ( $opt_coverage);
    $optWorkspace = "-p4ws $WorkSpace"      if ( $WorkSpace );

    my $ntests = @tests;
    my $tstnum = 1;
    foreach my $test ( @tests ){
        if ( $opt_tnum ) {
            my $num = $tstnum + 0;     # convert string of number to a number
            next if ( $num != $opt_tnum );
        }
        $tstnum++;
        chomp $test;
        my $testname = basename($test, '.pl') ;

        my ($stdout, $status) = 
            run_system_cmd( "$test $optWorkspace $optCoverage $optCleanup"
                ." $optVerbosity $optDebug", $VERBOSITY );

        if ( $status ){
            $SOMETHING_FAILED += 1;
            print("FAILED: $test\n$stdout\n");
        }else{
            my @lines = split('\n', $stdout);
            foreach my $line ( @lines) {
                gprint($line . "\n") if ( $line =~ m/PASSED/);
            }
        }
    }

    if ( ! $SOMETHING_FAILED ) {
        my $timed = end_timer();
        gprint("PASSED: $RealScript $timed\n");
    }


    exit( $SOMETHING_FAILED )
}

Main();

