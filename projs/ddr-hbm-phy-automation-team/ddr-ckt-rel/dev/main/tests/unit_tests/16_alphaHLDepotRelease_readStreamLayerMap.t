use strict;
use warnings;
use 5.14.2;
use Test2::Bundle::More;
use File::Temp;
use Try::Tiny;
use Data::Dumper;

use FindBin qw($RealBin $RealScript);
use lib "$RealBin/../../lib/perl/";
use alphaHLDepotRelease;
use Util::CommonHeader;
use Util::Messaging;
use Util::Misc;

our $DEBUG         = 0;
our $VERBOSITY     = 0;

sub Main() {

    my %t = (
        '01' => {
            'comment'  => "No such file test",
            'filename' => '/nodir/nofile.txt',
            # Expected Values
            'status'   => 1,
            'hash'     => {},
        },
    );
    my $ntests = keys(%t);
    
    plan($ntests * 2);

    foreach my $tstnum (sort keys %t) {
        my %ret_hash;
        my $href_args = $t{"$tstnum"};
        my $fname         = $href_args->{'filename'};
        my $href_expected = $href_args->{'hash'};
        my $stat_expected = $href_args->{'status'};
        my $comment       = $href_args->{'comment'};

        my $status = readStreamLayerMap($fname, \%ret_hash);
        ok($status,$stat_expected,$comment);
        is_deeply( \%ret_hash, $href_expected, $comment);
    }

    done_testing();

    return 0;
}

Main();

