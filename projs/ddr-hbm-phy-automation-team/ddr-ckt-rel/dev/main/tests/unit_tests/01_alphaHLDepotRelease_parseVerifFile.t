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
use Util::Messaging;


our $DEBUG     = NONE;
our $VERBOSITY = NONE;

sub Main() {

    my %tests = (
        test1 => {
            'file'     => "$RealBin/../data/alphaHLDepotRelease/file1.txt",
            'expected' => [
                'c239-tsmc7ff-1.8v_st',
                'rel1.1.0',
                '/remote/cad-rep/projects/cad/c239-tsmc7ff-1.8v_st/rel1.1.0/cad',
                'tsmc7ff-18_st'
            ]
        },
        test2 => {
            'file'     => "$RealBin/../data/alphaHLDepotRelease/file2.txt",
            'expected' => [
                'fake_proj_name',
                'fake_rel_version',
                '/remote/cad-rep/projects/cad/fake_proj_name/fake_rel_version/cad',
                ''
            ]
        },
    );

    my $ntests = keys(%tests);
    plan($ntests);

    foreach my $test ( keys %tests ) {
        print("test: $test\n");
        my $pef = $tests{$test}->{'file'};
        my @expected = @{$tests{$test}->{'expected'} };
        my @got = &getCadHome($pef);
        dprint(LOW, "Here's the values expected from getCadHome:\n"
                   .scalar(Dumper \@expected) ."\n" );
        dprint(LOW, "Here's the values returned from getCadHome:\n"
                   .scalar(Dumper \@got) ."\n" );
        is_deeply( \@expected , \@got, "getCadHome test '$test'" );
    }

    done_testing();

    return 0;
}

Main();

