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
    plan(24);

    my $errout = "";
    my $realerror = "";
    my $expected_output = "testfile1\n";
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

    for my $the_verbosity (@levels) {
        my $the_command   = "ls $RealBin/../data/run_system_cmd/";
        my ($output, $exit_val) = run_system_cmd($the_command, $the_verbosity);
        ok( $output eq $expected_output );
        ok( $exit_val == 0);
        
        $the_command = "bad-nosuch-command-torun-should-fail";
        ($output, $errout, $realerror) = capture { run_system_cmd($the_command, $the_verbosity) };
        #print("DEBUG: errout='$errout'\nrealerror='$realerror'\n");
        ok( $realerror =~ m/$expected_fail/ );
        print("-> [$realerror] <-\n") if ( $realerror !~ m/$expected_fail/ ) ;
        #ok( $exit_val == -1);
    }

    done_testing();
}

sub get_temp_filename(){
    my $fh = File::Temp->new(
        TEMPLATE => 'unit_test_05_Misc_run_system_cmd_stdout_XXXXX',
        DIR      => '/tmp',
        SUFFIX   => '.log'
    );
    return $fh->filename;
}


sub stdout_is($$$) {
    my $ref_func   = shift;
    my $halt_level = shift;
    my $expected   = shift;

    my $temp_file  = get_temp_filename();
    do {
        local *STDOUT;
        unlink($temp_file) if ( -e $temp_file );
        open(STDOUT, '>', $temp_file) || return 0;
        $ref_func->($halt_level);
    };
    my $fh;
    open($fh, '<', $temp_file) || return 0;
    my @lines = <$fh>;
    close($fh);
    unlink($temp_file) if ( -e $temp_file);
    
    my $gotvalue = $lines[0] || 'EMPTY_STRING';
    #print("$gotvalue\n");

    return( $gotvalue eq $expected );
}

Main();

