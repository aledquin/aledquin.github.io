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

our $DEBUG         = 0;
our $VERBOSITY     = 0;
our $FPRINT_NOEXIT = 1;

sub suppress_output_and_process($$) {

    my $file     = shift;
    my $hash_ref = shift;

    do {
        local *STDOUT;
        local *STDERR;
        open( STDOUT, '>>', "/dev/null" ) || return 0;
        open( STDERR, '>>', "/dev/null" ) || return 0;
        processLegalReleaseFile( $file, $hash_ref );
    };

}

sub Main() {

    plan(2);
    my %stackHash     = ();
    my $file          = "$RealBin/../data/test_legal_release_non_existant.t";
    my %expected_hash = (
        'allowedTimingCases' => ['ccsn', 'ccsn_lvf', 'lvf', 'nldm'],
    );

    # Non-existant file test
    try {
        suppress_output_and_process( $file, \%stackHash );
        is_deeply(\%stackHash, \%expected_hash, "processLegalReleaseFile 1st test empty expected");
    }
    catch {

        my $search_string = "Failed to open project release file:";

        # The following line will set the value of $output to 1 if the
        # $search_string is found inside $_. $_ is the output captured by
        # the try/catch stmnt.

        my $output          = ( $_ =~ /$search_string/ig );
        my $expected_answer = 1;

        is_deeply( $expected_answer, $output, "processLegalReleaseFile 1st test" );

    };

    # Full file test
    %stackHash     = ();
    $file          = "$RealBin/../data/test_legal_release.t";
    %expected_hash = (
        'ctlMacs'         => ['dwc_ddrphy_lcdl', 'dwc_ddrphy_txrxdq_ns', 'dwc_ddrphy_txrxdqs_ns'],
        'cdlPruneCells'   => 'cvcp* cvpp* vflag* *MOMcap_Cp *MOMcap_Cc *MOMcap_pu1 *MOMcap_pux cvcp* cvpp* vflag*',
        'layers'          => 'M0 M1 M2 M3 M4 D4 D5 D6 D7 D8 OVERLAP',
        'layersOverrides' => {
            'dwc_ddrphy_utility_blocks'              => 'B1 B2 G1 G2 H1 H2 H3 H4 OI1 M17',
            'dwc_ddrphycover_dwc_ddrphyacx4_top_ns'  => 'B1 B2 G1 G2 H1 H2 H3 H4 OI1 M17',
            'dwc_ddrphycover_dwc_ddrphydbyte_top_ns' => 'B1 B2 G1 G2 H1 H2 H3 H4 OI1 M17',
            'dwc_ddrphycover_dwc_ddrphymaster_top'   => 'B1 B2 G1 G2 H1 H2 H3 H4 OI1 M17'
        },
        'lefdiffRel'      => '1.00a',
        'metalStack'      => '18M_4Mx_4Dx_4Hx_2Bx_2Gx_2UTM_ILB',
        'metalStackCover' => '18M_4Mx_4Dx_4Hx_2Bx_2Gx_2UTM_ILB',
        'metalStackIp'    => '8M_4Mx_4Dx',
        'p4ReleaseRoot'   => 'products/ddr54/project/d822-ddr54-ss7hpp-18',
        'phyvMacros'      => {
            'dwc_ddrphy_decapvaa_tile'  => ['dwc_ddrphy_decapvaa_tile'],
            'dwc_ddrphy_decapvdd_tile'  => ['dwc_ddrphy_decapvdd_tile'],
            'dwc_ddrphy_utility_blocks' => [ 'dwc_ddrphy_decapvddq_dbyte_ns', 'dwc_ddrphy_decapvddq_acx4_ns', 'dwc_ddrphy_decapvddq_master' ],
            'dwc_ddrphy_utility_cells'  => [ 'dwc_ddrphy_decapvddq_ew', 'dwc_ddrphy_decapvddq_ns', 'dwc_ddrphy_decapvddq_ld_ew', 'dwc_ddrphy_decapvddq_ld_ns', 'dwc_ddrphy_vddqclamp_ns' ],
            'dwc_ddrphy_vaaclamp'       => ['dwc_ddrphy_vaaclamp'],
            'dwc_ddrphy_vddqclamp_ns'   => ['dwc_ddrphy_vddqclamp_ns']
        },
        'process'           => 'ss7hpp-18',
        'referenceDateTime' => '30 days ago',
        'referenceGdses'    => {
            'dwc_ddrphy_memreset_ens' => 'dwc_ddrphy_memreset_ns_analogTestVflag.gds.gz',
            'dwc_ddrphy_txrxac_ns'    => 'dwc_ddrphy_txrxac_ns_IntLoadFill.gds.gz dwc_ddrphy_txrxac_ns_InternalLoad.gds.gz',
            'dwc_ddrphy_txrxdqs_ns'   => 'dwc_ddrphydbyte_lcdlroutes_ns.gds.gz'
        },
        'rel'             => '1.00a',
        'relGdsCdl'       => 'icv',
        'relGdsShim'      => 'drcint',
        'releaseCtlMacro' => 'dwc_ddrphy_lcdl dwc_ddrphy_txrxdq_ns dwc_ddrphy_txrxdqs_ns',
        'releaseDefMacro' => 'dwc_ddrphy_testbenches/dwc_ddrphyacx4_analog_inst_ns dwc_ddrphy_testbenches/dwc_ddrphydbyte_analog_inst_ns dwc_ddrphy_testbenches/dwc_ddrphymaster_analog_inst',
        'releaseMacro'    => {
            'dwc_ddrphy_utility_blocks' => 'dwc_ddrphy_decapvddq_dbyte_ns dwc_ddrphy_decapvddq_acx4_ns dwc_ddrphy_decapvddq_master',
            'dwc_ddrphy_utility_cells'  => 'dwc_ddrphy_decapvddq_ew dwc_ddrphy_decapvddq_ns dwc_ddrphy_decapvddq_ld_ew dwc_ddrphy_decapvddq_ld_ns dwc_ddrphy_vddqclamp_ns'
        },
        'releasePhyvMacro' => 'dwc_ddrphy_vddqclamp_ns dwc_ddrphy_vaaclamp dwc_ddrphy_decapvaa_tile dwc_ddrphy_decapvdd_tile',
        'repeaterMacro'    => ['dwc_ddrphy_clktree_repeater'],
        'stackHash'        => {
            '18M_4Mx_4Dx_4Hx_2Bx_2Gx_2UTM_ILB' => '8M_4Mx_4Dx'
        },
        'supplyPins'          => 'D8',
        'supplyPinsOverrides' => {
            'dwc_ddrphy_bdl'                         => 'M4',
            'dwc_ddrphy_lcdl'                        => 'M4',
            'dwc_ddrphy_techrevision'                => 'M4',
            'dwc_ddrphy_utility_blocks'              => 'H1 H2 H3 H4 B1 B2 G1 G2 OI1 OI2 ILB MTOP MTOP-1',
            'dwc_ddrphycover_dwc_ddrphyacx4_top_ns'  => 'D8 G2 OI1 M17',
            'dwc_ddrphycover_dwc_ddrphydbyte_top_ns' => 'D8 G2 OI1 M17',
            'dwc_ddrphycover_dwc_ddrphymaster_top'   => 'D8 G2 OI1 M17'
        },
        'timingLibs'         => ['lvf'],
        'utilityMacro'       => [ 'dwc_ddrphy_utility_cells', 'dwc_ddrphy_utility_blocks' ],
        'autoMatch'          => 1,
        'ferel'              => "1.00a",
        'layout_tag'         => "Final Release",
        'releaseBranch'      => "rel1.00_cktpcs_1.00a_rel_",
        'releaseIgnoreMacro' => [ 'dwc_ddrphy_rxac_ew',    'dwc_ddrphy_rxdq_ew', 'dwc_ddrphy_rxdqs_ew', 'dwc_ddrphy_txfe_ew', 
                                  'dwc_ddrphy_txfedqs_ew', 'dwc_ddrphy_txbe_ew', 'dwc_ddrphy_bdl',      'dwc_ddrphy_dqsenreplica_ew'],
        'releaseMailDist'    => 'sg-ddr-ckt-release@synopsys.com,ddr_di@synopsys.com,guttman,jfisher,dube,samy,aparik,eltokhi,hoda,saeidh,hghonie',
        'releasePmMailDist'  => 'sg-ddr-ckt-release@synopsys.com,guttman,jfisher,dube,samy,hoda,saeidh,hghonie',
        'vcrel'              => "1.00a",
        'allowedTimingCases' => ['ccsn', 'ccsn_lvf', 'lvf', 'nldm'],
        'calibre_verifs'     => 'false',
        'calibre_report_list' => [],
        'icv_report_list'    => ['ant', 'drc', 'erc', 'lvs', 'drcint'],
    );

    suppress_output_and_process( $file, \%stackHash );
    is_deeply( \%stackHash, \%expected_hash, "processLegalReleaseFile 2nd test" );

    done_testing();

    return 0;
}

Main();

