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
 
    my %tests = (
        'test1' => {
            'file'     => "$RealBin/../data/ddr5--d911-ddr5-tsmc3eff-12--rel1.00_cktpcs--alphaNT.config", 
            'expected_aref' => [ 'ffg0p825vn40c',
                                 'ffg0p825v0c',
                                 'ffg0p825v125c',
            ],
            'expected_href' => {
                'ffg0p825v0c' => {
                             'VAA' => '1.98',
                             'VDA' => '0.825',
                             'VDD' => '0.825',
                             'VDDQ' => '1.21',
                             'VDDQ_VDD2H' => '1.21',
                             'VSH' => '0.3542',
                             'temp' => '0'
                },
                'ffg0p825v125c' => {
                               'VAA' => '1.98',
                               'VDA' => '0.825',
                               'VDD' => '0.825',
                               'VDDQ' => '1.21',
                               'VDDQ_VDD2H' => '1.21',
                               'VSH' => '0.3542',
                               'temp' => '125'
                },
                'ffg0p825vn40c' => {
                               'VAA' => '1.98',
                               'VDA' => '0.825',
                               'VDD' => '0.825',
                               'VDDQ' => '1.21',
                               'VDDQ_VDD2H' => '1.21',
                               'VSH' => '0.3542',
                               'temp' => '-40'
                },
            }, # expected_href
        }, # test1
    ); # %tests
#--------------
    my $ntests = keys(%tests);
    plan(2*$ntests);

    foreach my $test ( keys %tests ) {
        my $test_datafile = $tests{$test}->{'file'};
        my $aref      = $tests{$test}->{'expected_aref'};
        my $href      = $tests{$test}->{'expected_href'};
        my @corners_ckt_expected        = @$aref;
        my %corners_ckt_params_expected = %$href;
        dprint(LOW, "Expected Array :\n". scalar(Dumper \@corners_ckt_expected ) ."\n");
        dprint(LOW, "Expected Hash:\n". scalar(Dumper \%corners_ckt_params_expected ) ."\n");
           ($aref, $href) = &readNtFile( $test_datafile );
        my @corners_ckt_got        = @$aref;
        my %corners_ckt_params_got = %$href;

        dprint(LOW, "Got PVT Array:\n". scalar(Dumper \@corners_ckt_got) ."\n");
        dprint(LOW, "Got PVT Hash :\n". scalar(Dumper \%corners_ckt_params_got) ."\n");

        # is_deeply( $got, $expected, $test_name );
        is_deeply( @corners_ckt_got, @corners_ckt_expected, "readNtFile subroutine test..." );
        is_deeply( %corners_ckt_params_got, %corners_ckt_params_expected, "readNtFile subroutine test..." );
    }


    done_testing();

    return 0;
}

Main();

