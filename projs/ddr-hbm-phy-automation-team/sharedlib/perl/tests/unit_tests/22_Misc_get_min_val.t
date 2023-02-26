#!/depot/perl-5.14.2/bin/perl
use strict;
use warnings;
use 5.14.0;

use Test2::Bundle::More;
use File::Temp;

use FindBin qw($RealBin $RealScript);

use lib "$RealBin/../lib";
use alphaHLDepotRelease;
use Util::CommonHeader;
use Util::Messaging;
use Util::Misc;

our $DEBUG = NONE;
our $VERBOSITY = NONE;

sub Main() {

    my %tests = (
        test_comp_AltB => {
            'A'     => 5,
            'B'     => 17,
            'expected' => 5,
        },
        test_one_val_A => {
            'A'     => 5,
            'B'     => 'N/A',
            'expected' => 5,
        },
        test_comp_eqs => {
            'A'     => 1,
            'B'     => 1,
            'expected' => 1,
        },
        test_comp_AgtB => {
            'A'     => 53,
            'B'     => 2,
            'expected' => 2,
        },
        test_comp_neg_nmbs => {
            'A'     => -1,
            'B'     => -2,
            'expected' => -2,
        },
        test_one_val_B => {
            'A'     => 'N/A',
            'B'     => 5,
            'expected' => 5,
        },
        test_no_val => {
            'A'     => 'N/A',
            'B'     => 'N/A',
            'expected' => 'N/A',
        },

        
    );

    my $ntests = keys(%tests);
    plan($ntests);

    foreach my $test ( keys %tests ) {
        print("test: $test\n");
        my $a_value = $tests{$test}->{'A'};
        my $b_value = $tests{$test}->{'B'};
        my $res = $tests{$test}->{'expected'};
        my $ret = &get_min_val($a_value, $b_value);
        ok( $res eq $ret, "get_min_val $test $a_value vs $b_value --> '$ret'" );
    }

    done_testing();

    return 0;
}

Main();

