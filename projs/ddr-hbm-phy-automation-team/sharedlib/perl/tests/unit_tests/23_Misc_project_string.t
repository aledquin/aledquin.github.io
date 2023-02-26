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
our $DEBUG         = NONE;
our $VERBOSITY     = NONE;
our $DEBUG_LOG     = undef;
our $FPRINT_NOEXIT = TRUE;
#----------------------------------#


Main();

########  YOUR CODE goes in Main  ##############
sub Main {
    utils__process_cmd_line_args();
    # Current planned test count
    plan(7);
    #-------------------------------------------------------------------------
    #  Test 'append_arrays'
    #-------------------------------------------------------------------------
    setup_tests__parse_project_spec();
    #-------------------------------------------------------------------------
    #
    done_testing();
    exit(0);
}
############    END Main    ####################

#-------------------------------------------------------------------------
#  Setup tests to exercise the insert_at_key subroutine
#-------------------------------------------------------------------------
sub setup_tests__parse_project_spec() {
    my $subname = 'parse_project_spec';

    #-------------------------------------------------------------------------
    #  Test 'parse_project_spec'
    #-------------------------------------------------------------------------
    my %test0 = (
        'string' => "ddr54/d822-ddr54-ss7hpp-18/rel1.00_cktpcs", 
        'expect' => ["ddr54", "d822-ddr54-ss7hpp-18", "rel1.00_cktpcs"]
    );

    my %test1 = (
        'string' => "ddr54/d842-ddr54v2-tsmc6ff18/rel1.00_cktpcs",
        'expect' => ["ddr54", "d842-ddr54v2-tsmc6ff18", "rel1.00_cktpcs"]
    );

    my %test2 = (
        'string' => "asd/asd/asd",
        'expect' => ["asd", "asd", "asd"]
    );

    my @tests = (\%test0, \%test1, \%test2);

    foreach my $cnt (@tests) {

        my %testcase = %{$cnt};
        my @out      = parse_project_spec( $testcase{string}, \&usage );
        is_deeply (\@out, $testcase{expect}, $subname);

    }

    my %test3 = (
        'string' => "asd/asd",
        'expect' => NULL_VAL
    );

    my %test4 = (
        'string' => "asd",
        'expect' => NULL_VAL
    );

    my %test5 = (
        'string' => "s/sasd",
        'expect' => NULL_VAL
    );

    my %test6 = (
        'string' => "//",
        'expect' => NULL_VAL
    );
    @tests = (\%test3, \%test4, \%test5, \%test6);
    
    foreach my $cnt (@tests) {

        my %testcase = %{$cnt};
        my $out      = parse_project_spec( $testcase{string}, \&usage );
        is_deeply ($out, $testcase{expect}, "$subname");

    }

}
#-------------------------------------------------------------------------
#  Dummy usage function
#-------------------------------------------------------------------------
sub usage(){
    return(0);
}

1;
