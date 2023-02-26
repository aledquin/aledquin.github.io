use strict;
use warnings;
use 5.14.0;

use Test2::Bundle::More;
use File::Temp;
use Data::Dumper;
use FindBin qw($RealBin $RealScript);

use lib "$RealBin/../../lib/perl/";
use alphaHLDepotRelease;
use Util::CommonHeader;
use Util::Misc;
use Util::Messaging;


our $DEBUG     = NONE;
our $VERBOSITY = NONE;
our $FPRINT_NOEXIT = 1;

sub Main() {

    my $username    = get_username();
    my $p4_client   = $ENV{'P4CLIENT'};
    my $p4ws        = $ENV{'DDR_DA_DEFAULT_P4WS'} || 'p4_func_tests';
    my $p4_pathbase    = "/u/$username/$p4ws";
    # 
    my $p4_releaseroot = "products/lpddr54/project/d850-lpddr54-tsmc5ffp12";
    my $p4_path      = "$p4_pathbase/$p4_releaseroot/ckt/rel";
    my $badp4_path   = "$p4_pathbase/products/xyzbad/project/macro/ckt/rel";

    # We need to ensure that $badp4_path does not exit. The verify_perforce_setup
    # function always tries to create the directory path if it does not exist.
    if ( -e $badp4_path ) {
        run_system_cmd("rm -fR $p4_pathbase/products/xyzbad");
    }


    # This allows you to set DEBUG and VERBOSITY
    utils__process_cmd_line_args();

    my %tests = (
        test1 => {
            'msg'         => "Test for failure",
            'input'       => ["/dev/null/p4_ws", 
                              "/dev/null/releaseroot", 
                              "/dev/null/path", 
                              "client"],
            'status'      => -1,
            'error_text'  => '-F-\s+Cannot proceed\.\s+Fix P4 path.*'
        },
        test2 => {
            'msg'         => "Test for failure due to bad p4path",
            'input'       => [$p4_pathbase, 
                              $p4_releaseroot, 
                              $badp4_path, 
                              $p4_client],
            'status'      => -1,
            'error_text'  => '-F-\s+Cannot proceed\.\s+Fix release path'
        },
        test3 => {
            'msg'         => "Test for success",
            'input'       => [$p4_pathbase, 
                              $p4_releaseroot, 
                              $p4_path, 
                              $p4_client],
            'status'      => 1,
        },
    );

    my $ntests = keys(%tests);
    plan($ntests);

    foreach my $test ( sort keys %tests ) {
        my $msg         = $tests{$test}->{'msg'};
        my $aref_input  = $tests{$test}->{'input'};
        my $p4base      = shift @$aref_input;
        my $p4root      = shift @$aref_input;
        my $p4path      = shift @$aref_input;
        my $p4client    = shift @$aref_input;
        my $status      = $tests{$test}->{'status'};
        my $got_status;
       
        if ( exists $tests{$test}->{'error_text'} ) {
            my $file_stderr = "/tmp/${RealScript}_errors_${test}_$$.log";
            my $file_stdout = "/tmp/${RealScript}_warnings_${test}_$$.log";
            do {
                local *STDERR;
                local *STDOUT;
                open(STDERR, ">", $file_stderr) || die "$!";
                open(STDOUT, ">", $file_stdout) || die "$!";
                $got_status = verify_perforce_setup($p4base, $p4root, 
                    $p4path, $p4client);
            };
            if ( -e $file_stderr && ! -z $file_stderr) {
                my $errorText = $tests{$test}->{'error_text'};
                my @list = read_file( $file_stderr );
                my $content = join "\n",@list;
                ok( $content =~ m/$errorText/, "$test $msg verify_perforce_setup" );
            }elsif ($got_status != $status) {
                ok( FALSE, "$test $msg verify_perforce_setup has the wrong return status than expected");
                eprint("returned: $got_status,  expected $status\n");
                if ( -e $file_stdout && -z $file_stdout ) {
                    my $errorText = $tests{$test}->{'error_text'};
                    my @list = read_file( $file_stdout );
                    my $content = join "\n",@list;
                    eprint("stdout contains: '$content'\n");
                }else{
                    eprint("stdout file is empty\n");
                }
                if ( -e $file_stderr && -z $file_stderr ) {
                    eprint("stderr file is empty\n");
                }


            }else{
                eprint("Can not find '$file_stderr' !\n");
                ok( FALSE, "$test $msg verify_perforce_setup");
            }

        }else{
            $got_status = verify_perforce_setup($p4base, $p4root, 
                $p4path, $p4client);
            ok( $got_status == $status, "$test $msg verify_perforce_setup");
        }
    }

    done_testing();

    return 0;
}

Main();

