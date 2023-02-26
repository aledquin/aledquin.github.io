# History:
#   001 ljames      11/18/2022
#       Modified readLegalRelease() so it only takes the filename as input.
#       So I needed to adjust this test script until it passed.
#       9am-1:00pm
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
our $FPRINT_NOEXIT = 1;
our $gtext = "";

sub suppress_output_and_process($$$) {

    my $testname    = shift;
    my $file        = shift;
    my $href_output = shift;

    # Variables returned by readLegalRelease()
    my (
        $rel, 
        $p4ReleaseRoot, 
        $referenceDateTimeLibs, 
        $process, 
        $metalStack, 
        $metalStackIp, 
        $metalStackCover, 
        $layers, 
        $href_layersOverrides, 
        $supplyPins, 
        $href_supplyPinsOverrides, 
        $href_areaOverrides,
        $href_bndLayer, 
        $releaseShimMacro, 
        $releasePhyvMacro, 
        $releaseUtilityMacro, 
        $releaseRepeaterMacro, 
        $projDiskArchiveLibFiles, 
        $coverStackExists, 
        $releaseCtlMacro, 
        $releaseDefMacro, 
        $autoMatch
    ); 

    my $aref_CtlMacs        ; 
    my $aref_timingLibs      = [];  # array ref
    my $aref_repeaterMacro   = [];  # annonymous perl array ref
    my $aref_utilityMacro    = [];
    my $aref_allowed_timing_cases = [];
    my $href_releaseMacro    = {};  # annonymous perl hash ref
    my $href_referenceGdses  = {};  # annonymous perl hash ref
    my $href_shimMacros      = {};
    my $href_phyvMacros      = {};
    my $href_repeaterSubMacros={};
    my $href_stackHash       = {};  # annonymous perl hash ref (the INTERSECTION of metalStack and metalStackIp)

    do {
        local *STDOUT;
        local *STDERR;
        open( STDOUT, '>', "/dev/null" ) || return 0;
        open( STDERR, '>', "/dev/null" ) || return 0;
        (   $rel, 
            $p4ReleaseRoot, 
            $referenceDateTimeLibs, 
            $process, 
            $metalStack, 
            $metalStackIp, 
            $metalStackCover, 
            $href_stackHash,  
            $layers, 
            $href_layersOverrides, 
            $supplyPins, 
            $href_supplyPinsOverrides, 
            $href_areaOverrides,
            $href_bndLayer, 
            $releaseShimMacro, 
            $releasePhyvMacro, 
            $releaseUtilityMacro, 
            $releaseRepeaterMacro, 
            $projDiskArchiveLibFiles, 
            $coverStackExists, 
            $releaseDefMacro, 
            $autoMatch,
            $href_shimMacros,
            $href_phyvMacros,
            $href_releaseMacro, 
            $href_repeaterSubMacros,
            $aref_timingLibs,
            $href_referenceGdses,
            $aref_utilityMacro,
            $aref_CtlMacs ) = readLegalRelease( $file); 

        if ( $aref_CtlMacs ) {
            $releaseCtlMacro = join(" ", @$aref_CtlMacs);
        }else{
            $releaseCtlMacro = "no_releaseCtlMacro";
        }

        my @keys_l = ('no_layersOverrides');
        my @keys_s = ('no_supplyPinsOverrides');
        my @keys_a = ('no_areaOverrides');
        my @keys_b = ('no_bndLayer');
        my @keys_g = ('no_referenceGdses');
        my @keys_sh= ('no_stackHash');
           @keys_l = keys( %$href_layersOverrides)     if ( $href_layersOverrides );
           @keys_s = keys( %$href_supplyPinsOverrides) if ( $href_supplyPinsOverrides );
           @keys_a = keys( %$href_areaOverrides)       if ( $href_areaOverrides );
           @keys_b = keys( %$href_bndLayer)            if ( $href_bndLayer);
           @keys_g = keys( %$href_referenceGdses )     if ( $href_referenceGdses);
           @keys_sh= keys( %$href_stackHash)           if ( $href_stackHash);  # NOTE: this is the INTERSECTION of metalStack and metalStackIp

        
        # prevent 'uninitialized value' warning in print $fout for variables
        # that may not have been defined
        $p4ReleaseRoot           = "no_p4ReleaseRoot"           if ( ! $p4ReleaseRoot );
        $releaseShimMacro        = "no_releaseShimMacro"        if ( ! $releaseShimMacro );
#        $releaseRepeaterMacro    = "no_releaseRepeaterMacro"    if ( ! $releaseRepeaterMacro );
        $projDiskArchiveLibFiles = "no_projDiskArchiveLibFiles" if ( ! $projDiskArchiveLibFiles );
        $releaseUtilityMacro     = "no_releaseUtilityMacro"     if ( ! $releaseUtilityMacro );
        $rel                     = "no_rel"                     if ( ! $rel );
        $referenceDateTimeLibs   = "no_referenceDateTimeLibs"   if ( !$referenceDateTimeLibs);    
        $process                 = "no_process"            if ( !$process         );
        $metalStack              = "no_metalStack"         if ( !$metalStack      );
        $metalStackIp            = "no_metalStackIp"       if ( !$metalStackIp    );
        $metalStackCover         = "no_metalStackCover"    if ( !$metalStackCover );
        $layers                  = "no_layers"             if ( !$layers          );
        $supplyPins              = "no_supplyPins"         if ( !$supplyPins      );
        $releasePhyvMacro        = "no_releasePhyvMacro"   if ( !$releasePhyvMacro);
        $releaseDefMacro         = "no_releaseDefMacro"    if ( !$releaseDefMacro );
        $autoMatch               = "no_autoMatch"          if ( !$autoMatch       );

        if ( $main::DEBUG > NONE ) {
            open(my $fout, ">", "james_foo_${testname}.txt") ||die;
            print $fout "rel $rel,\n"; 
            print $fout "stackHash @keys_sh,\n"; # NOTE: this is the INTERSECTION of metalStack and metalStackIp
            print $fout "p4ReleaseRoot $p4ReleaseRoot,\n"; 
            print $fout "referenceDateTimeLibs $referenceDateTimeLibs,\n"; 
            print $fout "process $process,\n"; 
            print $fout "metalStack $metalStack,\n"; 
            print $fout "metalStackIp $metalStackIp,\n"; 
            print $fout "metalStackCover $metalStackCover,\n"; 
            print $fout "layers $layers,\n"; 
            print $fout "timingLibs @$aref_timingLibs,\n";
            print $fout "href_layersOverrides @keys_l,\n";
            print $fout "supplyPins $supplyPins,\n"; 
            print $fout "href_supplyPinsOverrides @keys_s,\n"; 
            print $fout "href_areaOverrides @keys_a,\n";
            print $fout "href_bndLayer @keys_b,\n"; 
            print $fout "referenceGdses @keys_g,\n";
            print $fout "releaseShimMacro $releaseShimMacro,\n"; 
            print $fout "releasePhyvMacro $releasePhyvMacro,\n"; 
            print $fout "releaseUtilityMacro $releaseUtilityMacro,\n"; 
            print $fout "utilityMacro @$aref_utilityMacro,\n";
            print $fout "releaseRepeaterMacro $releaseRepeaterMacro,\n"  if ( $releaseRepeaterMacro );
            print $fout "projDiskArchiveLibFiles $projDiskArchiveLibFiles,\n"; 
            print $fout "coverStackExists $coverStackExists,\n"; 
            print $fout "releaseCtlMacro $releaseCtlMacro,\n"; 
            print $fout "releaseDefMacro $releaseDefMacro,\n"; 
            print $fout "autoMatch   $autoMatch,\n";
            close($fout);
        }

#        $href_output->{'vcrel'}               = '-vcrel-';
#        $href_output->{'cdlPruneCells'}       = '-cdlPruneCells-';
        $href_output->{'layersOverrides'}     = $href_layersOverrides;
        $href_output->{'layers'}              = $layers; # M0 M1 ... 
        $href_output->{'lefdiffRel'}          = $rel;
        $href_output->{'metalStack'}          = $metalStack ; # 18M_4MX_...
        $href_output->{'metalStackIp'}        = $metalStackIp; # 18M_4MX_...
        $href_output->{'metalStackCover'}     = $metalStackCover;
        $href_output->{'p4ReleaseRoot'}       = $p4ReleaseRoot;
        $href_output->{'phyvMacros'}          = $href_phyvMacros; 
        $href_output->{'process'}             = $process; 
        $href_output->{'referenceDateTime'}   = $referenceDateTimeLibs; 
        $href_output->{'referenceGdses'}      = $href_referenceGdses;
        $href_output->{'rel'}                 = $rel;
        $href_output->{'releaseCtlMacro'}     = $releaseCtlMacro;
        $href_output->{'supplyPins'}          = $supplyPins; # D8
        $href_output->{'stackHash'}           = $href_stackHash; # NOTE: this is the INTERSECTION of metalStack and metalStackIp
        $href_output->{'supplyPinsOverrides'} = $href_supplyPinsOverrides; 
        $href_output->{'timingLibs'}          = $aref_timingLibs; 
        $href_output->{'releaseDefMacro'}     = $releaseDefMacro; # ab/b c/d ...
        $href_output->{'releaseMacro'}        = $href_releaseMacro; # {}
        $href_output->{'releasePhyvMacro'}    = $releasePhyvMacro;
        $href_output->{'utilityMacro'}        = $aref_utilityMacro ;
        $href_output->{'releaseRepeaterMacro'}= $releaseRepeaterMacro  ; 

    };

}

sub Main() {

    plan(3);

    my %datum_hash     = (); 
    my $file          = "$RealBin/../data/test_legal_release_non_existant.t";
    my %expected_hash = ();

    # Non-existant file test
    try {
        suppress_output_and_process( "01", $file, \%datum_hash);
        %expected_hash = (
            'layers'               => "no_layers",
            'layersOverrides'      => {},
            'referenceGdses'       => {}, 
            'releaseRepeaterMacro' => undef,
            'lefdiffRel'           => "no_rel",
            'metalStack'           => "no_metalStack",
            'metalStackCover'      => "no_metalStackCover",
            'metalStackIp'         => "no_metalStackIp",
            'p4ReleaseRoot'        => "no_p4ReleaseRoot",
            'phyvMacros'           => {},
            'process'              => "no_process",
            'referenceDateTime'    => "no_referenceDateTimeLibs",
            'rel'                  => "no_rel",
            'releaseCtlMacro'      => '',
            'releaseDefMacro'      => "no_releaseDefMacro", 
            'releaseMacro'         => {},
            'releasePhyvMacro'     => "no_releasePhyvMacro",
            'stackHash'            => {},
            'supplyPins'           => "no_supplyPins",
            'supplyPinsOverrides'  => {},
            'timingLibs'           => [],
            'utilityMacro'         => [],
        );

        is_deeply( \%datum_hash, \%expected_hash, "readLegalRelease 1st test");
    }
    catch {
        my $search_string = "Failed to open project release file";
        my $expected_answer = 1;

        # The following line will set the value of $output to 1 if the
        # $search_string is found inside $_. $_ is the output captured by
        # the try/catch stmnt.
        my $result = $_;
        my $output = 0;
        if ( $result =~ m/$search_string/ig ){
            $output = 1;
        }
        ok( $expected_answer == $output , "expect $expected_answer got $output: result '$result'");
    };


    # Test Set 02
    # Full file test
    %datum_hash = (); 
    $file          = "$RealBin/../data/test_legal_release.t";
    %expected_hash = (
#        'cdlPruneCells'   => 'cvcp* cvpp* vflag* *MOMcap_Cp *MOMcap_Cc *MOMcap_pu1 *MOMcap_pux cvcp* cvpp* vflag*',
        'layers'          => 'M0 M1 M2 M3 M4 D4 D5 D6 D7 D8 OVERLAP',
        'layersOverrides' => {
            'dwc_ddrphy_utility_blocks'              => 'B1 B2 G1 G2 H1 H2 H3 H4 OI1 M17',
            'dwc_ddrphycover_dwc_ddrphyacx4_top_ns'  => 'B1 B2 G1 G2 H1 H2 H3 H4 OI1 M17',
            'dwc_ddrphycover_dwc_ddrphydbyte_top_ns' => 'B1 B2 G1 G2 H1 H2 H3 H4 OI1 M17',
            'dwc_ddrphycover_dwc_ddrphymaster_top'   => 'B1 B2 G1 G2 H1 H2 H3 H4 OI1 M17'
         },
        'referenceGdses'  => {
            'dwc_ddrphy_txrxac_ns'     => 'dwc_ddrphy_txrxac_ns_IntLoadFill.gds.gz dwc_ddrphy_txrxac_ns_InternalLoad.gds.gz',
            'dwc_ddrphy_memreset_ens'  => 'dwc_ddrphy_memreset_ns_analogTestVflag.gds.gz',
            'dwc_ddrphy_txrxdqs_ns'    => 'dwc_ddrphydbyte_lcdlroutes_ns.gds.gz',
        },
        'releaseRepeaterMacro' => undef,
        'lefdiffRel'      => '1.00a',
        'metalStack'      => '18M_4Mx_4Dx_4Hx_2Bx_2Gx_2UTM_ILB',
        'metalStackCover' => '18M_4Mx_4Dx_4Hx_2Bx_2Gx_2UTM_ILB',
        'metalStackIp'    => '8M_4Mx_4Dx',
        'p4ReleaseRoot'   => 'products/ddr54/project/d822-ddr54-ss7hpp-18',
        'phyvMacros'      => {
            'dwc_ddrphy_utility_blocks' => [ 
                'dwc_ddrphy_decapvddq_dbyte_ns',
                'dwc_ddrphy_decapvddq_acx4_ns',
                'dwc_ddrphy_decapvddq_master',
                ],
            'dwc_ddrphy_utility_cells'  => [
                'dwc_ddrphy_decapvddq_ew',
                'dwc_ddrphy_decapvddq_ns',
                'dwc_ddrphy_decapvddq_ld_ew',
                'dwc_ddrphy_decapvddq_ld_ns',
                'dwc_ddrphy_vddqclamp_ns',
                ],
            'dwc_ddrphy_decapvaa_tile'  => ['dwc_ddrphy_decapvaa_tile'],
            'dwc_ddrphy_decapvdd_tile'  => ['dwc_ddrphy_decapvdd_tile'],
            'dwc_ddrphy_vaaclamp'       => ['dwc_ddrphy_vaaclamp'],
            'dwc_ddrphy_vddqclamp_ns'   => ['dwc_ddrphy_vddqclamp_ns']
        },
        'process'           => 'ss7hpp-18',
        'referenceDateTime' => '30 days ago',
        'rel'             => '1.00a',
#        'relGdsCdl'       => 'icv',
#        'relGdsShim'      => 'drcint',
        'releaseCtlMacro' => 'dwc_ddrphy_lcdl dwc_ddrphy_txrxdq_ns dwc_ddrphy_txrxdqs_ns',
#        'releaseCtlMacro' => 'dwc_ddrphy_testbenches/dwc_ddrphyacx4_analog_inst_ns dwc_ddrphy_testbenches/dwc_ddrphydbyte_analog_inst_ns dwc_ddrphy_testbenches/dwc_ddrphymaster_analog_inst',
        'releaseDefMacro' => 'dwc_ddrphy_testbenches/dwc_ddrphyacx4_analog_inst_ns dwc_ddrphy_testbenches/dwc_ddrphydbyte_analog_inst_ns dwc_ddrphy_testbenches/dwc_ddrphymaster_analog_inst',
        'releaseMacro'    => {
            'dwc_ddrphy_utility_blocks' => 'dwc_ddrphy_decapvddq_dbyte_ns dwc_ddrphy_decapvddq_acx4_ns dwc_ddrphy_decapvddq_master',
            'dwc_ddrphy_utility_cells'  => 'dwc_ddrphy_decapvddq_ew dwc_ddrphy_decapvddq_ns dwc_ddrphy_decapvddq_ld_ew dwc_ddrphy_decapvddq_ld_ns dwc_ddrphy_vddqclamp_ns'
        },
        'releasePhyvMacro' => 'dwc_ddrphy_vddqclamp_ns dwc_ddrphy_vaaclamp dwc_ddrphy_decapvaa_tile dwc_ddrphy_decapvdd_tile',
        'stackHash'        => { '18M_4Mx_4Dx_4Hx_2Bx_2Gx_2UTM_ILB' => '8M_4Mx_4Dx' },
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
        'timingLibs'   => ['lvf'],
        'utilityMacro' => [ 'dwc_ddrphy_utility_cells', 'dwc_ddrphy_utility_blocks' ]
    );

    my $failed = 0;
    try {
        suppress_output_and_process( "02", $file, \%datum_hash);
    }catch{
        $failed = 1;
        print("$_\n");
        ok( 1==0);
    };
    if ( ! $failed ) {
        my $shortfile = $file; 
        $shortfile =~ s/.*\/data/data/g;
        is_deeply( \%datum_hash, \%expected_hash , "readLegalRelease '$shortfile' Test set 02" );
    }

    # Test Set 03
    # Another full file test using 
    # /data/alphaHLDepotSeed/legalReleaseTest3.txt (was lpddr5x.d931-lpddr5x-tsmc3eff-12.rel1.00_cktpcs.legalRelease.txt)
    $file          = "$RealBin/../data/alphaHLDepotRelease/legalReleaseTest3.txt";
    %datum_hash    = (); 
    $failed        = 0;
    # NOTE: the original readLegalRelease() call never looks for release_gds_cdl; but
    #   the other function (which this test is not calling) will return 'relGdsCdl'
    %expected_hash = (
#        'cdlPruneCells'   => 'cvcp* cvpp* vflag* *MOMcap_Cp *MOMcap_Cc *MOMcap_pu1 *MOMcap_pux cvcp* cvpp* vflag*',
        'layers'          => 'M0 M1 M2 M3 M4 M5 M6 M7 M8 M9 M10 OVERLAP',
#        'vcrel'           => '1.00a',
        'layersOverrides' => {
            'dwc_lpddr5xphycover_acx2_top_ew' =>  "M10 M11 M12 M13 M14 M15 MTOP MTOP-1",
            'dwc_lpddr5xphycover_csx2_top_ew' =>  "M10 M11 M12 M13 M14 M15 MTOP MTOP-1",
            'dwc_lpddr5xphycover_ckx2_top_ew' =>  "M10 M11 M12 M13 M14 M15 MTOP MTOP-1",
            'dwc_lpddr5xphycover_cmosx2_top_ew' =>  "M10 M11 M12 M13 M14 M15 MTOP MTOP-1",
            'dwc_lpddr5xphycover_dx4_top_ew' =>  "M10 M11 M12 M13 M14 M15 MTOP MTOP-1",
            'dwc_lpddr5xphycover_dx5_top_ew' =>  "M10 M11 M12 M13 M14 M15 MTOP MTOP-1",
            'dwc_lpddr5xphycover_master_top_ew' =>  "M10 M11 M12 M13 M14 M15 MTOP MTOP-1",
            'dwc_lpddr5xphycover_zcal_top_ew' =>  "M10 M11 M12 M13 M14 M15 MTOP MTOP-1",
            'dwc_lpddr5xphy_utility_blocks' =>  "M0 M1 M2 M3 M4 M5 M6 M7 M8 M9 M10 M11 M12 M13 M14 M15 MTOP MTOP-1",
         },
        'releaseRepeaterMacro' => undef,
        'lefdiffRel'      => '1.00a_pre3',
        'metalStack'      => '15M_1Xa_h_1Xb_v_1Xc_h_1Xd_v_1Ya_h_1Yb_v_4Y_hvhv_2Yy2Z',
        'metalStackCover' => '15M_1Xa_h_1Xb_v_1Xc_h_1Xd_v_1Ya_h_1Yb_v_4Y_hvhv_2Yy2Z',
        'metalStackIp'    => '10M_1Xa_h_1Xb_v_1Xc_h_1Xd_v_1Ya_h_1Yb_v_3Y_hvh',
        'p4ReleaseRoot'   => 'products/lpddr5x_ddr5_phy/lp5x/project/d931-lpddr5x-tsmc3eff-12',
        'phyvMacros'      => {
            'dwc_lpddr5xphy_utility_blocks'   => [
                'dwc_lpddr5xphy_decapvddq_x2_ew',
                'dwc_lpddr5xphy_decapvddq_ld_x2_ew',
                'dwc_lpddr5xphy_decapvddq_hd_x2_ew',
                'dwc_lpddr5xphy_decapvddq_x3_ew',
                'dwc_lpddr5xphy_decapvddq_ld_x3_ew',
                'dwc_lpddr5xphy_decapvddq_hd_x3_ew',
                'dwc_lpddr5xphy_decapvdd_x2_ew',
                'dwc_lpddr5xphy_decapvdd_ld_x2_ew',
                'dwc_lpddr5xphy_decapvdd_hd_x2_ew',
                'dwc_lpddr5xphy_decapvdd_x3_ew',
                'dwc_lpddr5xphy_decapvdd_ld_x3_ew',
                'dwc_lpddr5xphy_decapvdd_hd_x3_ew',
                'dwc_lpddr5xphy_decapvdd2h_x2_ew',
                'dwc_lpddr5xphy_decapvdd2h_x3_ew',
                'dwc_lpddr5xphy_decapvdd2h_ld_x2_ew',
                'dwc_lpddr5xphy_decapvdd2h_ld_x3_ew',
                'dwc_lpddr5xphy_vdd2hclamp_ew',
                'dwc_lpddr5xphy_vdd2hclamp_x6_ew',
                ],
            'dwc_lpddr5xphy_utility_cells'    => [
                'dwc_lpddr5xphy_decapvddq_x2_cell_ew',
                'dwc_lpddr5xphy_decapvddq_hd_x2_cell_ew',
                'dwc_lpddr5xphy_decapvdd2h_x2_cell_ew',
                'dwc_lpddr5xphy_decapvdd_x2_cell_ew',
                'dwc_lpddr5xphy_decapvdd_hd_x2_cell_ew',
                'dwc_lpddr5xphy_vddqclamp_x2_ew',
                'dwc_lpddr5xphy_vdd2hclamp_x2_ew',
                ],
            'dwc_lpddr5xphy_vaaclamp_ew'      => ['dwc_lpddr5xphy_vaaclamp_ew'],
            'dwc_lpddr5xphy_decapvaa_tile'    => ['dwc_lpddr5xphy_decapvaa_tile'],
            'dwc_lpddr5xphy_vddqclamp_x2_ew'  => ['dwc_lpddr5xphy_vddqclamp_x2_ew'],
            'dwc_lpddr5xphy_vdd2hclamp_x2_ew' => ['dwc_lpddr5xphy_vdd2hclamp_x2_ew'],
            'dwc_lpddr5xphy_vddqclamp_dx4_ew' => ['dwc_lpddr5xphy_vddqclamp_dx4_ew'],
            'dwc_lpddr5xphy_vddqclamp_dx5_ew' => ['dwc_lpddr5xphy_vddqclamp_dx5_ew'],
        },
        'process'           => 'tsmc3eff-12',
        'referenceDateTime' => '21 days ago',
        'rel'             => '1.00a_pre3',
        #'releaseCtlMacro' => 'pro_hard_macro/dwc_lpddr5xphyacx2_ew pro_hard_macro/dwc_lpddr5xphycmosx2_ew pro_hard_macro/dwc_lpddr5xphyckx2_ew pro_hard_macro/dwc_lpddr5xphycsx2_ew pro_hard_macro/dwc_lpddr5xphydx4_ew pro_hard_macro/dwc_lpddr5xphydx5_ew pro_hard_macro/dwc_lpddr5xphymaster pro_hard_macro/dwc_lpddr5xphyzcal_ew pro_hard_macro/dwc_lpddr5xphydqx1_ew pro_hard_macro/dwc_lpddr5xphydqsx1_ew',
        'releaseCtlMacro' => 'dwc_lpddr5xphy_lcdl dwc_lpddr5xphy_lstx_acx2_ew dwc_lpddr5xphy_lstx_dx4_ew dwc_lpddr5xphy_lstx_dx5_ew dwc_lpddr5xphy_lstx_zcal_ew dwc_lpddr5xphy_pclk_master dwc_lpddr5xphy_pclk_rxdca dwc_lpddr5xphy_rxreplica_ew dwc_lpddr5xphy_txrxac_ew dwc_lpddr5xphy_txrxcs_ew dwc_lpddr5xphy_txrxdq_ew dwc_lpddr5xphy_txrxdqs_ew',
        'releaseDefMacro' => 'pro_hard_macro/dwc_lpddr5xphyacx2_ew pro_hard_macro/dwc_lpddr5xphycmosx2_ew pro_hard_macro/dwc_lpddr5xphyckx2_ew pro_hard_macro/dwc_lpddr5xphycsx2_ew pro_hard_macro/dwc_lpddr5xphydx4_ew pro_hard_macro/dwc_lpddr5xphydx5_ew pro_hard_macro/dwc_lpddr5xphymaster pro_hard_macro/dwc_lpddr5xphyzcal_ew pro_hard_macro/dwc_lpddr5xphydqx1_ew pro_hard_macro/dwc_lpddr5xphydqsx1_ew',
        'releaseMacro'    => {
            'dwc_lpddr5xphy_utility_cells' => 'dwc_lpddr5xphy_decapvddq_x2_cell_ew dwc_lpddr5xphy_decapvddq_hd_x2_cell_ew dwc_lpddr5xphy_decapvdd2h_x2_cell_ew dwc_lpddr5xphy_decapvdd_x2_cell_ew dwc_lpddr5xphy_decapvdd_hd_x2_cell_ew dwc_lpddr5xphy_vddqclamp_x2_ew dwc_lpddr5xphy_vdd2hclamp_x2_ew',
            'dwc_lpddr5xphy_utility_blocks' => 'dwc_lpddr5xphy_decapvddq_x2_ew dwc_lpddr5xphy_decapvddq_ld_x2_ew dwc_lpddr5xphy_decapvddq_hd_x2_ew dwc_lpddr5xphy_decapvddq_x3_ew dwc_lpddr5xphy_decapvddq_ld_x3_ew dwc_lpddr5xphy_decapvddq_hd_x3_ew dwc_lpddr5xphy_decapvdd_x2_ew dwc_lpddr5xphy_decapvdd_ld_x2_ew dwc_lpddr5xphy_decapvdd_hd_x2_ew dwc_lpddr5xphy_decapvdd_x3_ew dwc_lpddr5xphy_decapvdd_ld_x3_ew dwc_lpddr5xphy_decapvdd_hd_x3_ew dwc_lpddr5xphy_decapvdd2h_x2_ew dwc_lpddr5xphy_decapvdd2h_x3_ew dwc_lpddr5xphy_decapvdd2h_ld_x2_ew dwc_lpddr5xphy_decapvdd2h_ld_x3_ew dwc_lpddr5xphy_vdd2hclamp_ew dwc_lpddr5xphy_vdd2hclamp_x6_ew',
            'dwc_lpddr5xphy_repeater_cells' => 'dwc_lpddr5xphy_pclk_rptx1',
        },
        'releasePhyvMacro' => 'dwc_lpddr5xphy_vaaclamp_ew dwc_lpddr5xphy_decapvaa_tile dwc_lpddr5xphy_vddqclamp_x2_ew dwc_lpddr5xphy_vdd2hclamp_x2_ew dwc_lpddr5xphy_vddqclamp_dx4_ew dwc_lpddr5xphy_vddqclamp_dx5_ew',
#        'repeaterMacro'    => ['dwc_lpddr5xphy_repeater_cells'],
        'stackHash'        => {'15M_1Xa_h_1Xb_v_1Xc_h_1Xd_v_1Ya_h_1Yb_v_4Y_hvhv_2Yy2Z' => '10M_1Xa_h_1Xb_v_1Xc_h_1Xd_v_1Ya_h_1Yb_v_3Y_hvh' },
        #'stackHash'        => {'18M_4Mx_4Dx_4Hx_2Bx_2Gx_2UTM_ILB' => '8M_4Mx_4Dx' },
        'supplyPins'          => 'M10',
        'supplyPinsOverrides' => {
            'dwc_lpddr5xphy_lcdl' =>  "M4",
            'dwc_lpddr5xphy_techrevision' =>  "M5",
            'dwc_lpddr5xphycover_acx2_top_ew' =>  "M10 M14 M15 MTOP MTOP-1",
            'dwc_lpddr5xphycover_csx2_top_ew' =>  "M10 M14 M15 MTOP MTOP-1",
            'dwc_lpddr5xphycover_ckx2_top_ew' =>  "M10 M14 M15 MTOP MTOP-1",
            'dwc_lpddr5xphycover_cmosx2_top_ew' =>  "M10 M14 M15 MTOP MTOP-1",
            'dwc_lpddr5xphycover_dx4_top_ew' =>  "M10 M14 M15 MTOP MTOP-1",
            'dwc_lpddr5xphycover_dx5_top_ew' =>  "M10 M14 M15 MTOP MTOP-1",
            'dwc_lpddr5xphycover_master_top_ew' =>  "M10 M14 M15 MTOP MTOP-1",
            'dwc_lpddr5xphycover_zcal_top_ew' =>  "M10 M14 M15 MTOP MTOP-1",
            'dwc_lpddr5xphy_utility_blocks' =>  "M10 M14 M15 MTOP MTOP-1",
        },
        'referenceGdses' => {},
        'timingLibs'   => ['lvf'],
        'utilityMacro' => ['dwc_lpddr5xphy_utility_cells', 
                           'dwc_lpddr5xphy_utility_blocks' ]
    );
    try {
        suppress_output_and_process( "03", $file, \%datum_hash);
    }
    catch {
        $failed = 1;
        print("$_\n");
        ok( 1==0);
    };
    if ( ! $failed ) {
        my $shortfile = $file; $shortfile =~ s/.*\/data/data/g;
        is_deeply( \%datum_hash, \%expected_hash , "readLegalRelease '$shortfile'" );
    }

    done_testing();

    return 0;
}

Main();

