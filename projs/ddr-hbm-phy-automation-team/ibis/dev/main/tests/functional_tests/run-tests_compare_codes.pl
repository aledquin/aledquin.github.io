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

use lib "$RealBin/../lib";
use TestUtils;

our $STDOUT_LOG   = undef; 
our $DEBUG        = NONE;
our $VERBOSITY    = NONE;
our $PROGRAM_NAME = $RealScript;
our $AUTO_APPEND_NEWLINE = 1;
my $DEFAULT_WORKSPACE = "p4_func_tests";

sub Main(){

    # WorkSpace can be overidden with an env variable
    my $WorkSpace        = $ENV{'DEFAULT_WORKSPACE'} || $DEFAULT_WORKSPACE;
    my $opt_cleanup      = 1;
    my $opt_coverage     = 0;
    my $opt_help         = 0;
    my $SOMETHING_FAILED = 0 ;

    my $cmd = "ls -1 $RealBin/test_compare_codes*.pl" ;
    my ($stdout, $pass) = run_system_cmd($cmd);
    my @tests = split /\n/, $stdout;


    ($WorkSpace, $opt_cleanup, $opt_coverage, $opt_help) = 
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
    foreach my $test ( @tests ){
        chomp $test;
        my $testname = basename($test, '.pl') ;

        my ($stdout, $status) = 
            run_system_cmd( "$test $optWorkspace $optCoverage $optCleanup"
                ."$optVerbosity $optDebug", $VERBOSITY );

        if ( $status ){
            $SOMETHING_FAILED += 1;
            print("FAILED: $test\n$stdout\n");
        }else{
            my @lines = split('\n', $stdout);
            foreach my $line ( @lines) {
                print($line . "\n") if ( $line =~ m/PASSED/);
            }
        }
    }

    if ( ! $SOMETHING_FAILED ) {
        print("PASSED: $RealScript\n");
    }


    exit( $SOMETHING_FAILED )
}

Main();

