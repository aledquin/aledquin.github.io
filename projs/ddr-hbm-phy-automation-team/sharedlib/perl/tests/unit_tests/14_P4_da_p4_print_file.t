use strict;
use warnings;
use Getopt::Std;
use Data::Dumper;
use FindBin qw($RealBin $RealScript);
use File::Spec::Functions qw( catfile );
use Cwd qw( abs_path );
use Carp qw(cluck confess croak);
#use Test2::Tools::Compare;
use Test2::Bundle::More;

use lib "$RealBin/../lib";
use Util::CommonHeader;
use Util::Misc;
use Util::Messaging;
use Util::DS;
use Util::P4;

our $PROGRAM_NAME = $0;
our $AUTHOR_NAME  = 'Harsimrat Wadhawan';
#----------------------------------#
our $DEBUG     = NONE;
our $VERBOSITY = NONE;
our $DEBUG_LOG = undef;
#----------------------------------#


Main();

########  YOUR CODE goes in Main  ##############
sub Main {
    utils__process_cmd_line_args();
    # Current planned test count
    plan(5);
    #-------------------------------------------------------------------------
    #  Test 'append_arrays'
    #-------------------------------------------------------------------------
    setup_tests__da_p4_print_file();
    #-------------------------------------------------------------------------
    #
    done_testing();
    exit(0);
}
############    END Main    ####################

#-------------------------------------------------------------------------
#  Setup tests to exercise the insert_at_key subroutine
#-------------------------------------------------------------------------
sub setup_tests__da_p4_print_file() {
    my $subname = 'da_p4_print_file';
    my $cnt     = 1;

    my $file0 = "//wwcad/msip/projects/alpha/alpha_common/bin/beta/lib/Util/Messaging.pm";
    my $file4 = "//wwcad/msip/projects/alpha/alpha_common/bin/beta/lib/Util/*";
    my ($out0, $err0) = run_system_cmd("p4 print -q $file0", NONE);    
    my ($out4, $err4) = run_system_cmd("p4 print -q $file4", NONE);    

    #-------------------------------------------------------------------------
    #  Test 'da_p4_print_file'
    #-------------------------------------------------------------------------
    my %test0 = (
        'file'   => $file0,
        'expect' => $out0
    );

    my %test1 = (
        'file'   => '//wwcad/msip/projects/alpha/alpha_common/bin/beta/lib/Util/MessagingTest.pm', #This file should not exist
        'expect' => NULL_VAL
    );

    my %test2 = (
        'file'   => 'wcad/msip/projects/alpha/alpha_common/bin/beta/lib/Util/.pm', #This file should not exist
        'expect' => NULL_VAL
    );

    my %test3 = (
        'file'   => 'wcad/msip/projects/alpha/alpha_common/bin/beta/lib/Util/...', 
        'expect' => NULL_VAL
    );

    my %test4 = (
        'file'   => $file4, 
        'expect' => $out4
    );

    my @tests = (\%test0, \%test1, \%test2, \%test3, \%test4);

    foreach my $cnt (@tests) {

        my %testcase = %{$cnt};
        my $out      = da_p4_print_file( $testcase{file} );
        is_deeply ($out, $testcase{expect}, $subname);

    }

}

1;
