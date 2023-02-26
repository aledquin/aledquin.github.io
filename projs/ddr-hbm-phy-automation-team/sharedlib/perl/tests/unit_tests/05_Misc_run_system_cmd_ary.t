use strict;
use warnings;
use v5.14.2;

use Test2::Bundle::More;
use Test2::Tools::Compare;
use File::Temp;
use Capture::Tiny qw(capture);
use FindBin qw($RealBin $RealScript);

use lib "$RealBin/../lib";
use Util::CommonHeader;
use Util::Misc;

our $DEBUG      = 0;
our $VERBOSITY  = 0;
our $STDOUT_LOG = undef; 
our $DA_RUNNING_UNIT_TESTS = 1;
our $FPRINT_NOEXIT = 1;

sub Main() {
    my $errout = "";
    my $realerror = "";
    my $expected_output = "testfile1\n";
    my @expected_array = ( "testfile1" );
    my $expected_fail   = 'Can\'t exec "bad-nosuch-command-torun-should-fail": No such file';
    my @levels = (
        NONE,
        LOW,       
        MEDIUM,    
        FUNCTIONS, 
        HIGH,      
        SUPER,     
        CRAZY,     
        INSANE,
        );

    my $nplans = @levels;
    plan( $nplans * 8 );

    my $tmp_file           = "/tmp/unit_test_run_system_cmd_array$$"; 
    my $the_command_action = "touch $tmp_file";
    my $the_command        = "ls $RealBin/../data/run_system_cmd/";
    my $the_bad_command    = "bad-nosuch-command-torun-should-fail";

    for my $the_verbosity (@levels) {
        my $output = run_system_cmd_array($the_command, $the_verbosity);
        ok( $output eq $expected_output , "Returning a long string");
        
        my @got_array = run_system_cmd_array($the_command, $the_verbosity);
        is_deeply(\@got_array, \@expected_array , "Returning an array");

        my $ret_status=1;
        run_system_cmd_array($the_command_action, $the_verbosity, \$ret_status);
        ok( -e $tmp_file, "No return value being tested with optional status ref");
        ok( $ret_status == 0, "Checking if the status was returned");
        unlink $tmp_file if ( -e $tmp_file );

        $ret_status = 333;
        run_system_cmd_array($the_command_action, $the_verbosity, \$ret_status);
        ok( -e $tmp_file, "No return value being tested with optional bad status ref");
        ok( $ret_status == 0, "Checking if the status was returned with success");
        unlink $tmp_file if ( -e $tmp_file );

        ($output, $errout, $realerror) = capture {my $abc = run_system_cmd_array($the_bad_command, $the_verbosity) };
        ok( $realerror =~ m/$expected_fail/, "Testing fail condition" );
        print("-> [$realerror] <-\n") if ( $realerror !~ m/$expected_fail/ ) ;

        ($output, $errout, $realerror) = capture {run_system_cmd_array($the_bad_command, $the_verbosity, \$ret_status) };
        ok( $ret_status == -1, "Testing fail condition number 2 no LVALUE but supply a ret_status");

    }

    done_testing();
}

Main();

