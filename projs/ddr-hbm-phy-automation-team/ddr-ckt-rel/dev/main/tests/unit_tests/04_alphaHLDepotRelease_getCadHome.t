use strict;
use warnings;
use 5.14.0;

use Test2::Bundle::More;
use File::Temp;

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
            'expected' => "c239-tsmc7ff-1.8v_st, rel1.1.0, /remote/cad-rep/projects/cad/c239-tsmc7ff-1.8v_st/rel1.1.0/cad, tsmc7ff-18_st",
        },
        test2 => {
            'file'     => "$RealBin/../data/alphaHLDepotRelease/file2.txt",
            'expected' => "fake_proj_name, fake_rel_version, /remote/cad-rep/projects/cad/fake_proj_name/fake_rel_version/cad",
        },
        test3 => {
            'file'     => "$RealBin/../data/alphaHLDepotRelease/file3.txt",
            'expected' => "c757-int18a-1.2v, rel2.1.0, /remote/cad-rep/projects/cad/c757-int18a-1.2v/rel2.1.0/cad, int18a-12",
        },
    );

    my $ntests = keys(%tests);
    plan($ntests);

    foreach my $test ( keys %tests ) {
        print("test: $test\n");
        my $pef = $tests{$test}->{'file'};
        my $expected = $tests{$test}->{'expected'};
        my ($cadproj, $cadrel, $cadhome, $cadtech) = &getCadHome($pef);
        dprint(LOW, "cadtech  = '$cadtech'\n");
        my $got = "$cadproj, $cadrel, $cadhome";
        $got .= ", $cadtech" if ( $cadtech);
        dprint(LOW, "got      = '$got'\n" );
        dprint(LOW, "expected = '$expected'\n" );
        ok( $got eq $expected, "getCadHome test file '$pef'" );
    }

    done_testing();

    return 0;
}

Main();

