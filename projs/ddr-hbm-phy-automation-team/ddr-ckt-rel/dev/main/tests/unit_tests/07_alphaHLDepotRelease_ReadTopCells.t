use strict;
use warnings;
use 5.14.2;

use Test2::Bundle::More;
use File::Temp;

use Data::Dumper;
use FindBin qw($RealBin $RealScript);

use lib "$RealBin/../../lib/perl/";
use Util::Messaging;
use alphaHLDepotRelease;
use Util::CommonHeader;

our $DEBUG = 0;
our $VERBOSITY = 0;

sub Main() {
    
    my %tests = (
        'test1' => {
            'file'     => "$RealBin/../data/ddr5--d911-ddr5-tsmc3eff-12--rel1.00_cktpcs--topcells.txt",
            'expected' => {
                'dwc_ddr5phy_ato_ew'       => 1,
                'dwc_ddr5phy_ato_pll_ew'   => 1,
                'dwc_ddr5phy_decapvaa_tile'=> 1,
                'dwc_ddr5phy_lcdl'         => 1,
                'dwc_ddr5phy_lstx_acx2_ew' => 1,
                'dwc_ddr5phy_lstx_dx4_ew'  => 1,
                'dwc_ddr5phy_lstx_zcal_ew' => 1,
                'dwc_ddr5phy_pclk_master'  => 1,
                'dwc_ddr5phy_pclk_rptx2'   => 1,
                'dwc_ddr5phy_pclk_rxdca'   => 1,
                'dwc_ddr5phy_por_ew'       => 1,
                'dwc_ddr5phy_rxacvref_ew'  => 1,
                'dwc_ddr5phy_techrevision' => 1,
                'dwc_ddr5phy_txrxac_ew'    => 1,
                'dwc_ddr5phy_txrxcmos_ew'  => 1,
                'dwc_ddr5phy_txrxdq_ew'    => 1,
                'dwc_ddr5phy_txrxdqs_ew'   => 1,
                'dwc_ddr5phy_vaaclamp_ew'  => 1,
                'dwc_ddr5phy_vregdac_ew'   => 1,
                'dwc_ddr5phy_vregvsh_ew'   => 1,
                'dwc_ddr5phy_zcalio_ew'    => 1,
                'dwc_ddr5phy_vddqclamp_x2_ew' => 1,
             },
        },
    );

    my $ntests = keys(%tests);
    plan($ntests);

    foreach my $test ( keys %tests ) {
        my $test_datafile = $tests{$test}->{'file'};
        my $expected      = $tests{$test}->{'expected'};
        dprint(LOW, "Expected :\n". scalar(Dumper $expected) ."\n");
        my %got           = &readTopCells( $test_datafile );
        dprint(LOW, "Got :\n". scalar(Dumper \%got) ."\n");
        my @macros_got      = sort keys %got;
        my @macros_expected = sort keys %$expected;
        # is_deeply( $got, $expected, $test_name );
        is_deeply( @macros_got, @macros_expected, "readTopCells test..." );
    }


    done_testing();

    return 0;
}

Main();

