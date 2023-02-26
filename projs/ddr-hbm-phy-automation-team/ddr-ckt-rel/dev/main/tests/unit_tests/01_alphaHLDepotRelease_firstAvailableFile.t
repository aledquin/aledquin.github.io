use strict;
use warnings;
use 5.14.2;

use Test2::Bundle::More;
use File::Temp;

use FindBin qw($RealBin $RealScript);

use lib "$RealBin/../../lib/perl/";
use alphaHLDepotRelease;
use Util::CommonHeader;

our $DEBUG = 0;

sub Main() {
    my %tests = ( 
        'test01' => [ 'file1', "$RealBin/../data/test1"],
        'test02' => [ 'file1', 'file2', "$RealBin/../data/test2" ],
        'test03' => [ 'file1', 'file2' ],
        'test04' => [ "$RealBin/../data/test1", "$RealBin/../data/test2" ],
        'test05' => [ "$RealBin/../data/test2", "$RealBin/../data/test1" ],
        'test06' => [ "$RealBin/../data/test2" ],
        'test07' => [ 'file1' ],
        'test08' => [],
    );
    my %expected = (
        'test01' => "$RealBin/../data/test1",
        'test02' => "$RealBin/../data/test2",
        'test03' => NULL_VAL,
        'test04' => "$RealBin/../data/test1",
        'test05' => "$RealBin/../data/test2",
        'test06' => "$RealBin/../data/test2",
        'test07' => NULL_VAL,
        'test08' => NULL_VAL,

    );
    my $ntests = keys %tests;
    plan( $ntests);

    foreach my $key (sort keys( %tests )) {
        my $aref_fnames = $tests{$key};
        my $value = &firstAvailableFile( @$aref_fnames );
        #print("$key : '$value'\n");
        ok( $expected{$key} eq $value , "$key firstAvailableFile");
    }

    done_testing();

    return 0;
}

Main();

