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

use lib dirname(abs_path $0) . '/../lib/';
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
    plan(6);
    #-------------------------------------------------------------------------
    #  Test 'append_arrays'
    #-------------------------------------------------------------------------
    setup_tests__union();
    #-------------------------------------------------------------------------
    #
    done_testing();
    exit(0);
}
############    END Main    ####################

#-------------------------------------------------------------------------
#  Setup tests to exercise the union subroutine
#-------------------------------------------------------------------------
sub setup_tests__union() {
    my $subname = 'union';
    my $cnt     = 1;

    #-------------------------------------------------------------------------
    #  Test 'insert_at_key'
    #-------------------------------------------------------------------------

    my %test0 = (
        'a'      => [1, 2, 3, 4, 5 ],
        'b'      => [6, 7, 8, 9, 10],
        'expect' => [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
    );

    my %test1 = (
        'a'      => [1],
        'b'      => [ ],
        'expect' => [1]
    );

    my %test2 = (
        'a'      => [ ],
        'b'      => [ ],
        'expect' => [ ]
    );

    my %test3 = (
        'a'      => [ 1, 2, 3, 4 ],
        'b'      => [ 2, 4, 5, 6 ],
        'expect' => [ 1, 2, 3, 4, 5, 6]
    );

    my %test4 = (
        'a'      => [ 1.234, 2.234, 3.234, 4.234 ],
        'b'      => [ 6.234, 7.234, 3.235, 4.234 ],
        'expect' => [ 1.234, 2.234, 3.234, 3.235, 4.234, 6.234, 7.234 ]
    );

    my %test5 = (
        'a'      => [ 0, 0, 0, 0, 0 ],
        'b'      => [ 1, 2, 3, 4, 5 ],
        'expect' => [ 0, 1, 2, 3, 4, 5 ]
    );
  
    my @tests = (\%test0, \%test1, \%test2, \%test3, \%test4, \%test5, );

    foreach my $cnt (@tests) {

        my %testcase = %{$cnt};

        # Compute union
        my $union_ref = union($testcase{a}, $testcase{b}); 

        dprint (HIGH, Dumper($testcase{a})."\n");
        dprint (HIGH, Dumper($testcase{b})."\n");

        # Computed vector
        my @computed = @{$union_ref};

        dprint(HIGH, Dumper(\@computed)."\n");
    
        # Sorted computed vector
        @computed    = sort {$a <=> $b} @computed;

        dprint(HIGH, Dumper(\@computed)."\n");

        is_deeply( $testcase{expect} , \@computed, "$subname : test$cnt" );                

    }
    
}

1;
