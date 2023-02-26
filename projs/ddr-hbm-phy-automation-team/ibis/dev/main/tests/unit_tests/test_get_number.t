#!/depot/perl-5.14.2/bin/perl -w
use strict;
use warnings;
# nolint utils__script_usage_statistics
use Getopt::Std;
use Data::Dumper;
use File::Basename qw{ dirname };
use File::Spec::Functions qw{ catfile };
use Cwd qw{ abs_path };
use Carp qw{cluck confess croak};
use Test2::Bundle::More;
use FindBin qw($RealBin $RealScript);
# use Switch;

use lib "$RealBin/../../lib/perl/";
use lib "$RealBin";
use lib "$RealBin/../lib";

use Util::CommonHeader;
use Util::Misc;
use Util::Messaging;
use Util::DS;
use Util::QA;
use ibis qw{get_number};
# use utilities;

use test_get_number_random;

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
    plan(358);

    #-------------------------------------------------------------------------
    #  Test 'get_number'
    #-------------------------------------------------------------------------
    manual_tests__get_number();
    negative_number_tests__get_number();
    random_number_tests__get_number();
    #-------------------------------------------------------------------------

    done_testing();
    exit(0);
}
############    END Main    ####################

#-------------------------------------------------------------------------
#  Setup manual tests to exercise the get_number subroutine
#-------------------------------------------------------------------------
sub manual_tests__get_number() {

    my $subname = 'get_number';
    my $cnt     = 1;

    #-------------------------------------------------------------------------
    #  Test 'get_number'
    #-------------------------------------------------------------------------
   
    foreach my $cnt (@POSITIVE_VECTOR) {

        my %testcase = %{$cnt};

        # Test string
        my $test_vector = $testcase{insert};

        # Expected number
        my $expect_vector = $testcase{expect};

        is_deeply( get_number($test_vector), $expect_vector, "$subname" );

    }

}

#-------------------------------------------------------------------------
#  Setup tests to exercise the get_number subroutine on negative number strings
#-------------------------------------------------------------------------
sub negative_number_tests__get_number() {

    my $subname = 'get_number';
    my $cnt     = 1;

    #-------------------------------------------------------------------------
    #  Test 'get_number'
    #-------------------------------------------------------------------------

    foreach my $cnt (@NEGATIVE_VECTOR) {

        my %testcase = %{$cnt};

        # Test string
        my $test_vector = $testcase{insert};

        # Expected number
        my $expect_vector = $testcase{expect};

        is_deeply( get_number($test_vector), $expect_vector, "$subname" );

    }

}

#-------------------------------------------------------------------------
#  Setup tests to exercise the get_number subroutine on random number strings
#-------------------------------------------------------------------------
sub random_number_tests__get_number() {

    my $subname = 'get_number';
    my $cnt     = 1;

    #-------------------------------------------------------------------------
    #  Test 'get_number'
    #-------------------------------------------------------------------------
   
    foreach my $key ( keys(%RANDOM_VECTOR) ) {

        my %testcase = %{ $RANDOM_VECTOR{$key} };

        # Test string
        my $test_vector = trim( $testcase{insert} );

        # Expected number
        my $expect_vector = $testcase{expect};

        is_deeply( get_number($test_vector), $expect_vector / 1, "$subname" );

    }

}

1;
