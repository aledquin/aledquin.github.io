use strict;
use warnings;
use Getopt::Std;
use Data::Dumper;
use File::Basename qw( dirname );
use File::Spec::Functions qw( catfile );
use Cwd qw( abs_path );
use Carp qw(cluck confess croak);

#use Test2::Tools::Compare;
use Test2::Bundle::More;

use lib dirname( abs_path $0) . '/../lib/';
use Util::CommonHeader;
use Util::Misc;
use Util::Messaging;
use Util::DS;

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
    plan(7);

    #-------------------------------------------------------------------------
    #  Test 'append_arrays'
    #-------------------------------------------------------------------------
    setup_tests__simple_difference();

    #-------------------------------------------------------------------------
    #
    done_testing();
    exit(0);
}
############    END Main    ####################

#-------------------------------------------------------------------------
#  Setup tests to exercise the simple_difference subroutine
#-------------------------------------------------------------------------
sub setup_tests__simple_difference() {
    my $subname = 'simple_difference';
    my $cnt     = 1;

    #-------------------------------------------------------------------------
    #  Test 'insert_at_key'
    #-------------------------------------------------------------------------

    my %test0 = (
        'a'      => [ 1, 2, 3, 4, 5 ],
        'b'      => [ 6, 7, 8, 9, 10 ],
        'expect' => [ 6, 7, 8, 9, 10 ]
    );

    my %test1 = (
        'a'      => [1],
        'b'      => [ ],
        'expect' => [ ]
    );

    my %test2 = (
        'a'      => [],
        'b'      => [],
        'expect' => []
    );

    my %test3 = (
        'a'      => [ 1, 2, 3, 4 ],
        'b'      => [ 2, 4, 5, 6 ],
        'expect' => [ 5, 6 ]
    );

    my %test4 = (
        'a'      => [ 1.234, 2.234, 3.234, 4.234 ],
        'b'      => [ 6.234, 3.234, 3.235, 4.234 ],
        'expect' => [ 3.235, 6.234 ]
    );

    my %test5 = (
        'a'      => [ 1, 2, 3, 4, 5 ],
        'b'      => [ 1, 2, 3, 4, 5 ],
        'expect' => []
    );

    my %test6 = (
        'a' => [
            90093, 95706, 86263, 47776, 94994, 67008, 29961, 66820, 49792, 25400, 22374, 71529, 78570, 11081, 50232, 16566, 96768
        ],
        'b' => [
            49792, 25400, 22374, 71529, 78570, 11081, 50232, 16566, 96768, 91008, 34646, 70935, 38849
        ],
        'expect' => [
            34646, 38849, 70935, 91008
        ]
    );

    my @tests = ( \%test0, \%test1, \%test2, \%test3, \%test4, \%test5, \%test6 );

    foreach my $cnt (@tests) {

        my %testcase = %{$cnt};

        # Compute simple_difference
        my $simple_difference_ref = simple_difference( $testcase{a}, $testcase{b} );

        dprint( HIGH, Dumper( $testcase{a} ) . "\n" );
        dprint( HIGH, Dumper( $testcase{b} ) . "\n" );

        # Computed vector
        my @computed = @{$simple_difference_ref};

        dprint( HIGH, Dumper( \@computed ) . "\n" );

        # Sorted computed vector
        @computed = sort { $a <=> $b } @computed;

        dprint( HIGH, Dumper( \@computed ) . "\n" );

        is_deeply( $testcase{expect}, \@computed, "$subname : test$cnt" );

    }

}

1;
