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
    plan(8);
    #-------------------------------------------------------------------------
    #  Test 'append_arrays'
    #-------------------------------------------------------------------------
    setup_tests__insert_at_key();
    #-------------------------------------------------------------------------
    #
    done_testing();
    exit(0);
}
############    END Main    ####################

#-------------------------------------------------------------------------
#  Setup tests to exercise the insert_at_key subroutine
#-------------------------------------------------------------------------
sub setup_tests__insert_at_key() {
    my $subname = 'insert_at_key';
    my $cnt     = 1;

    #-------------------------------------------------------------------------
    #  Test 'insert_at_key'
    #-------------------------------------------------------------------------
    #-------------------------------------------------------------------------
    #  Misc. Vars. For Testing.
    #-------------------------------------------------------------------------
    my @ARRAY = qw ( a b c);

    my %test0 = (

        'insert' => [

            ["a", 123], ["a", 123], ["a", 123],

        ],

        'expect' => {

            'a' => [123, 123, 123],

        }

    );

    my %test1 = (

        'insert' => [

            ["a", 123], ["b", 123], ["c", 123],

        ],

        'expect' => {

            'a' => [123],
            'b' => [123],
            'c' => [123],

        }

    );

    my %test2 = (

        'insert' => [

            ["a", "ABC"], ["b", "123"], ["c", "ABC123"],

        ],

        'expect' => {

            'a' => ["ABC"],
            'b' => ["123"],
            'c' => ["ABC123"],

        }

    );
  
    my %test3 = (

        'insert' => [

            ["a", ""], ["b", ""], ["c", ""],

        ],

        'expect' => {

            'a' => [""],
            'b' => [""],
            'c' => [""],

        }

    );
    
    my %test4 = (

        'insert' => [

            ["a", 1], ["a", 2], ["a", 3], ["a", "ABCXYZ"], ["b", ""], ["c", ""], 

        ],

        'expect' => {

            'a' => [1,2,3, "ABCXYZ"],
            'b' => [""],
            'c' => [""],

        }

    );

    my %test5 = (

        'insert' => [

            ["a", 1], ["a", 2], ["a", 3], ["a", "ABCXYZ"], ["a", qr/abc/], 

        ],

        'expect' => {

            'a' => [1,2,3, "ABCXYZ", qr/abc/],

        }

    );
    
    my %test6 = (

        'insert' => [

            ["a", \%test5], ["a", \%test4], 

        ],

        'expect' => {

            'a' => [\%test5, \%test4],

        }

    );

    my %test7 = (

        'insert' => [

            ["a", \@ARRAY], ["b", \%test6], 

        ],

        'expect' => {

            'a' => [\@ARRAY],
            'b' => [\%test6]
        }

    );

    my @tests = (\%test0, \%test1, \%test2, \%test3, \%test4, \%test5, \%test6, \%test7);

    foreach my $cnt (@tests) {

        my %testcase = %{$cnt};

        # Testing Hash.
        my %computed_list = ();

        # Test Vector
        my @test_vector = @{$testcase{insert}};
        
        # Expected Vector
        my %expect_vector = %{$testcase{expect}};

        foreach my $pair_ref ( @test_vector ) {
            my @pair = @{$pair_ref};
            insert_at_key(\%computed_list, $pair[0], $pair[1]);
        }

        is_deeply( \%computed_list , \%expect_vector, "$subname : test$cnt" );        
        dprint(SUPER, "test     list: ".Dumper( \@test_vector   )."\n" );
        dprint(SUPER, "expected list: ".Dumper( \%expect_vector )."\n" );
        dprint(SUPER, "computed list: ".Dumper( \%computed_list )."\n" );

    }

}

