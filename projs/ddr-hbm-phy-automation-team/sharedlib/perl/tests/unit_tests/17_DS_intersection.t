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
    setup_tests__intersection();

    #-------------------------------------------------------------------------
    #
    done_testing();
    exit(0);
}
############    END Main    ####################

#-------------------------------------------------------------------------
#  Setup tests to exercise the intersection subroutine
#-------------------------------------------------------------------------
sub setup_tests__intersection() {
    my $subname = 'intersection';
    my $cnt     = 1;

    #-------------------------------------------------------------------------
    #  Test 'insert_at_key'
    #-------------------------------------------------------------------------

    my %test0 = (
        'a'      => [ 1, 2, 3, 4, 5 ],
        'b'      => [ 6, 7, 8, 9, 10 ],
        'expect' => []
    );

    my %test1 = (
        'a'      => [1],
        'b'      => [],
        'expect' => []
    );

    my %test2 = (
        'a'      => [],
        'b'      => [],
        'expect' => []
    );

    my %test3 = (
        'a'      => [ 1, 2, 3, 4 ],
        'b'      => [ 2, 4, 5, 6 ],
        'expect' => [ 2, 4 ]
    );

    my %test4 = (
        'a'      => [ 1.234, 2.234, 3.234, 4.234 ],
        'b'      => [ 6.234, 3.234, 3.235, 4.234 ],
        'expect' => [ 3.234, 4.234 ]
    );

    my %test5 = (
        'a'      => [ 1, 2, 3, 4, 5 ],
        'b'      => [ 1, 2, 3, 4, 5 ],
        'expect' => [ 1, 2, 3, 4, 5 ]
    );

    my %test6 = (
        'a' => [
            90093, 95706, 86263, 47776, 94994, 67008, 29961, 66820, 94499, 52943, 21747, 11658, 10926, 10870, 99243, 98003, 56141, 26239, 59718, 91842, 90107, 18811, 64928, 85118, 10882, 92039,
            63728, 34771, 34266, 58977, 186,   80184, 79956, 18244, 53276, 44755, 4075,  19309, 23753, 92973, 23042, 48003, 47972, 47865, 31475, 62474, 15396, 97260, 2341,  86507, 85128, 68407,
            60649, 44963, 42938, 26665, 60449, 81285, 13838, 2820,  66445, 60047, 89872, 22053, 34635, 82489, 60552, 16963, 87110, 82384, 99413, 98433, 91289, 15349, 97441, 90035, 78516, 51356,
            80448, 30962, 17021, 40300, 50858, 63692, 31387, 29980, 67551, 86804, 45014, 5200,  45267, 38028, 73697, 54318, 55225, 83070, 37562, 29017, 42734, 84472
        ],
        'b' => [
            49792, 25400, 22374, 71529, 78570, 11081, 50232, 16566, 96768, 91008, 34646, 70935, 38849, 50362, 91544, 29674, 64427, 48793, 3212,  54994, 6847,  12833, 7682,  70818, 81057, 3696,
            58329, 27769, 3798,  80791, 22161, 27740, 57552, 89126, 18968, 72729, 77327, 91233, 35363, 85515, 97311, 47450, 5690,  50694, 98685, 53654, 44182, 66343, 92926, 78276, 7674,  3259,
            11574, 12821, 69769, 22389, 75506, 7886,  83924, 94101, 70192, 89606, 40652, 73231, 63197, 51593, 22770, 12730, 9514,  52261, 81032, 78024, 45919, 46497, 75417, 27310, 45078, 6425,
            77154, 53540, 95635, 13026, 35876, 63692, 75900, 80521, 44755, 62424, 50315, 80015, 99894, 84586, 11078, 48023, 63687, 87593, 41375, 8492,  11856, 99437
        ],
        'expect' => [ 44755, 63692 ]
    );

    my @tests = ( \%test0, \%test1, \%test2, \%test3, \%test4, \%test5, \%test6 );

    foreach my $cnt (@tests) {

        my %testcase = %{$cnt};

        # Compute intersection
        my $intersection_ref = intersection( $testcase{a}, $testcase{b} );

        dprint( HIGH, Dumper( $testcase{a} ) . "\n" );
        dprint( HIGH, Dumper( $testcase{b} ) . "\n" );

        # Computed vector
        my @computed = @{$intersection_ref};

        dprint( HIGH, Dumper( \@computed ) . "\n" );

        # Sorted computed vector
        @computed = sort { $a <=> $b } @computed;

        dprint( HIGH, Dumper( \@computed ) . "\n" );

        is_deeply( $testcase{expect}, \@computed, "$subname : test$cnt" );

    }

}

1;
