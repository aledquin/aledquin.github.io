use strict;
use warnings;
use 5.14.2;

use Test2::Bundle::More;
use File::Temp;
use Data::Dumper;

use FindBin qw($RealBin $RealScript);

use lib "$RealBin/../../lib/perl/";
use alphaHLDepotRelease;

our $DEBUG         = 0;
our $VERBOSITY     = 0;
our $FPRINT_NOEXIT = 1;

sub Main() {

    my %t = (
        '01'=> {'coverStacks'=>['abc'], 
                'expected'   =>['abc_cover']
               },
        '02'=> {'coverStacks'=>['def'], 
                'expected'   =>['def_cover']
               },
        '03'=> {'coverStacks'=>['def'     ], 
                'expected'   =>['def_cover' ]
               },
        '04'=> {'coverStacks'=>['def',            'def',       'cde'], 
                'expected'   =>['def_both_cover', 'cde_cover']
               },
    );

    my $ntests = keys(%t);
    plan($ntests);

    foreach my $testnum (sort keys %t){
        my @allStacks;
        my $href_tst = $t{"$testnum"};
        my $arg1     = $href_tst->{'coverStacks'};
        my $expected = $href_tst->{'expected'};

        coverStackCheck( $arg1, \@allStacks);
        is_deeply( \@allStacks, $expected);
    }

	done_testing();

	return 0;
}
Main();

