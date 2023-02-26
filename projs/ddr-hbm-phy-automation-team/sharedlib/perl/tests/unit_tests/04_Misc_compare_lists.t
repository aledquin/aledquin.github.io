use strict;
use warnings;
use v5.14.2;

use Test2::Bundle::More;
use Test2::Tools::Compare;
use File::Temp;

use FindBin qw($RealBin $RealScript);

use lib "$RealBin/../lib";
use Util::CommonHeader;
use Util::Misc;

our $DEBUG      = 0;
our $VERBOSITY  = 0;
our $STDOUT_LOG = undef; 
our $DA_RUNNING_UNIT_TESTS = 1;

sub Main() {
    plan(6);

    my @list_a = (1, 2, 3, 4, 5);
    my @list_b = (1, 6, 4, 7, 3); 
    my @expected_common = (1, 3, 4);
    my @expected_first  = (2, 5);
    my @expected_second = (6, 7);
    my $expected_equiv  =0;
    my @empty_list = ();

    my ($aref_common, 
        $aref_first,
        $aref_second,
        $equivalent ) = &compare_lists(\@list_a,  \@list_b);

    is(@$aref_common, @expected_common);
    is(@$aref_first,  @expected_first);
    is(@$aref_second, @expected_second);
    ok( $equivalent == $expected_equiv );

    do {
        local *STDOUT;
        local *STDERR;
        my $temp_stdout = "/tmp/unit_test_04_Misc_compare_lists_stdout_$$";
        my $temp_stderr = "/tmp/unit_test_04_Misc_compare_lists_stderr_$$";
        open(STDOUT, '>', $temp_stdout) || return 0;
        open(STDERR, '>', $temp_stderr) || return 0;

        # Test bad input (not arefs )
       ($aref_common, 
        $aref_first,
        $aref_second,
        $equivalent ) = &compare_lists( 3,  \@list_b);
        is(@$aref_common, @empty_list);

       ($aref_common, 
        $aref_first,
        $aref_second,
        $equivalent ) = &compare_lists( \@list_a, 3);
        is(@$aref_common, @empty_list);
    };


    done_testing();
}

Main();

