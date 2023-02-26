use strict;
use warnings;
use 5.14.2;

use Test2::Bundle::More;
use File::Temp;

use Data::Dumper;
use FindBin qw($RealBin $RealScript);

use lib "$RealBin/../../lib/perl/";
use Util::CommonHeader;
use Util::Messaging;
use Util::Misc;
use alphaHLDepotRelease;

our $DEBUG = 0;
our $VERBOSITY = 0;

sub Main() {
    
   utils__process_cmd_line_args();
 
   my $relCornersHeaderBase =
         "Corner Type\tCase\tCore Voltage (V)"
        ."\tPLL Voltage (V)\tIO Voltage (V)\tTemperature (C)"
        ."\tExtraction Corner";
  my %corners_params;
 
  my %tests = (
        'test1' => {
            'file'     => "$RealBin/../data/lpddr54--d850-lpddr54-tsmc5ffp12--rel2.00_cktpcs--legalVcCorners.csv",
            'expected_aref' => [ 
               'ff0p825vn40c', 'ff0p825v0c',
               'ff0p825v125c', 'ff0p935vn40c',
               'ff0p935v0c'  , 'ff0p935v125c',
               'ss0p765vn40c', 'ss0p765v0c',
               'ss0p765v125c', 'ss0p675vn40c',
               'ss0p675v0c'  , 'ss0p675v125c',
               'tt0p85v25c'  , 'tt0p75v85c',
               'tt0p75v25c'
            ],
        }, # test1
        'test2' => {
            'file'     => "/remote/cad-rep/projects/lpddr54/d850-lpddr54-tsmc5ffp12/rel2.00_cktpcs/design/legalVcCorners.csv",
            'expected_aref' => [ 
               'ff0p825vn40c', 'ff0p825v0c',
               'ff0p825v125c', 'ff0p935vn40c',
               'ff0p935v0c'  , 'ff0p935v125c',
               'ss0p765vn40c', 'ss0p765v0c',
               'ss0p765v125c', 'ss0p675vn40c',
               'ss0p675v0c'  , 'ss0p675v125c',
               'tt0p85v25c'  , 'tt0p75v85c',
               'tt0p75v25c'
            ],
        }, # test1

    ); # %tests
#--------------
    my $ntests = keys(%tests);
    plan(1*$ntests);

    foreach my $test ( keys %tests ) {
        my $test_datafile = $tests{$test}->{'file'};
        my $aref          = $tests{$test}->{'expected_aref'};

        my @corners_expected        = @$aref;
        dprint(LOW, "Expected Array :\n". scalar(Dumper \@corners_expected ) ."\n");

        my @corners_got = &process_corners_file( $relCornersHeaderBase, $test_datafile, \%corners_params );
        dprint(LOW, "Got PVT Array:\n". scalar(Dumper \@corners_got) ."\n");

        # is_deeply( $got, $expected, $test_name );
        is_deeply( \@corners_got, \@corners_expected, "process_legalVcCorners.csv subroutine test..." );
    }

    done_testing();

    return 0;
}

Main();

