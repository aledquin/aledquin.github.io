#!/depot/perl-5.14.2/bin/perl
#!/usr/bin/env perl

use strict;
use Data::Dumper;
use File::Copy;
use Getopt::Std;
use File::Basename qw( dirname );
use File::Spec::Functions qw( catfile );
use Cwd qw( abs_path );
use Carp qw(cluck confess croak);
use lib dirname(abs_path $0) . '/../lib/';
use lib "/depot/perl-5.14.2/lib/site_perl/5.14.2/";
#use Data::Compare;
use Test2::Tools::Compare;
use Test2::Bundle::More;

use Util::CommonHeader;
use Util::Misc;
use Util::Messaging;
use ViCi;


our $PROGRAM_NAME = $0; 
#----------------------------------#
our $DEBUG     = NONE;
our $VERBOSITY = NONE;
#----------------------------------#


BEGIN { header(); } 
   Main();
END { footer(); }

########  YOUR CODE goes in Main  ##############
sub Main {
   utils__process_cmd_line_args();

   my ($vici_str, $cfg, $cfg_expected, $cfg_with_vici);

   ($vici_str, $cfg, $cfg_expected) = TEST__setup_cell_cfg_d862_modified();
   $cfg_with_vici = TEST__vici_utils( $cfg, $vici_str );
   dprint( SUPER, "Got back CFG=" . scalar( Dumper $cfg_with_vici ) . "\n" );
   $cfg_with_vici = local_sort($cfg_with_vici);
   $cfg_expected  = local_sort($cfg_expected);
   is_deeply( $cfg_with_vici , $cfg_expected, "ViCi d862 checks ..." ); 

      ($vici_str, $cfg, $cfg_expected) = TEST__setup_cell_cfg_d714();
   $cfg_with_vici = TEST__vici_utils( $cfg, $vici_str );
   dprint( SUPER, "Got back CFG=" . scalar( Dumper $cfg_with_vici ) . "\n" );
   #$cfg_with_vici = local_sort($cfg_with_vici);
   #$cfg_expected  = local_sort($cfg_expected);
   is_deeply( $cfg_with_vici , $cfg_expected, "ViCi d714 checks ..." ); 

      ($vici_str, $cfg, $cfg_expected) = TEST__setup_cell_cfg_d862();
   $cfg_with_vici = TEST__vici_utils( $cfg, $vici_str );
   dprint( SUPER, "Got back CFG=" . scalar( Dumper $cfg_with_vici ) . "\n" );
   #$cfg_with_vici = local_sort($cfg_with_vici);
   #$cfg_expected  = local_sort($cfg_expected);
   is_deeply( $cfg_with_vici , $cfg_expected, "ViCi d862 checks ..." ); 

      ($vici_str, $cfg, $cfg_expected) = TEST__setup_cell_cfg_d812();
   $cfg_with_vici = TEST__vici_utils( $cfg, $vici_str );
   #$cfg_with_vici = local_sort($cfg_with_vici);
   #$cfg_expected  = local_sort($cfg_expected);
   is_deeply( $cfg_with_vici , $cfg_expected, "ViCi d812 checks ..." ); 

      ($vici_str, $cfg, $cfg_expected) =  TEST__setup_cell_cfg_d852();
   $cfg_with_vici = TEST__vici_utils( $cfg, $vici_str );
   #$cfg_with_vici = local_sort($cfg_with_vici);
   #$cfg_expected  = local_sort($cfg_expected);
   is_deeply( $cfg_with_vici , $cfg_expected, "ViCi d852 checks ..." ); 

   done_testing();

   exit(0);
}
############    END Main    ####################


#-------------------------------------------------------------------------------
#  These subroutines are used as functional & unit tests for the methods above
#-------------------------------------------------------------------------------

sub local_sort($) {
    my $aref_list  = shift;
    foreach my $key (keys ($aref_list)) { 
        if($aref_list->{$key}) { $aref_list->{$key} = sort $aref_list->{$key};  }
    }
    return $aref_list;
}

#-------------------------------------------------------------------------------
#  Example of slurp from ViCi for HBM d714 release 1.00a_EWHardened 
#-------------------------------------------------------------------------------
#  This is used to setup the cell CFG ... typically comes from a config file.
#      Contains critical information needed to parse the right information from 
#      ViCi ... including the ViCi URL, REGEX to extract metal stack info
#      cell name details etc.
#-------------------------------------------------------------------------------
sub TEST__setup_cell_cfg_d714(){
   print_function_header();
   my $href_cells = {
	    'pub'  => {
			   'dirname'     => "pub",
			   'name'        => "pub",
			   'process'     => "tsmc7ff18",
			   'viciname'    => "pub",
			   'mstack'      => "",
			   'mstack_regex'=> 'N/A',
			   'PVT_regex'   => '^PVT options : (.*)$', 
			   'vici_url'    => 'http://vici/releasePageConstruct/index/id/24925/page_id/249',
			   'PVT_regex'   => "N/A",
      },
	    'top' => {
			   'dirname'     => "hbmphy_top",
			   'name'        => "top",
			   'viciname'    => "hip",
			   'mstack_regex'=> '^Foundry Metal .+ (\w+)$',
			   'PVT_regex'   => '^PVT options : (.*)$', 
			   'vici_url'    => 'http://vici/releasePageConstruct/index/id/24925/page_id/249',
      },
	    'aword' => {
			   'dirname'     => "awordx2",
			   'name'        => "awordx2",
			   'viciname'    => "awordx2",
			   'mstack_regex'=> '^PHY Metal Option: (.*)$',
			   'PVT_regex'   => '^PVT options : (.*)$', 
			   'vici_url'    => 'http://vici/releasePageConstruct/index/id/24925/page_id/249',
      },
      'macro'  => {
			   'dirname'     => "macro",
			   'name'        => "macro",
			   'process'     => "tsmc7ff18",
			   'viciname'    => "phy_top",
			   'mstack'      => "",
			   'mstack_regex'=> 'N/A',
			   'version'     => "", 
			   'PVT_regex'   => "N/A",
      },
	 };

#-------------------------------------------------------------------------------
my $vici_str = <<'END_VICI';
Opening the 'http://vici/releasePageConstruct/index/id/24925/page_id/249' url for checking content
Get cell_names and version from vici
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++
awordx2 : _ew : 1.12a
decapvddq :  : 1.50a
dword : _ew : 1.02a
hip :  : 1.00a
master : _ew : 1.02a
midstack : _ew : 1.02a
pub :  : 1.10a
phy_top :  : 1.11a
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++
Get pvt_corners from vici
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++
Standard Product : Corner type
PVT options : ffgnp0p825v125c_cworst_CCworst_T ffgnp0p825v125c_rcworst_CCworst_T ffgnp0p825v125c_cbest_CCbest ffgnp0p825v125c_rcbest_CCbest ssgnp0p675v125c_cworst_CCworst ssgnp0p675v125c_rcworst_CCworst ssgnp0p675v125c_cbest_CCbest ssgnp0p675v125c_rcbest_CCbest tt0p75v25c_typical
++++++++++++++++++++++++++++++++++++++++++++++++++++++++

+++++++++++++++++++++++++++++++++++++++++++++
Get metal stacks from vici
Foundry Metal Option: 15M_1X_h_1Xa_v_1Ya_h_5Y_vhvhv_2Yy2Yx2R
PHY Metal Option: 6M_1X_h_1Xa_v_1Ya_h_2Y_vh
+++++++++++++++++++++++++++++++++++++
END_VICI

#-------------------------------------------------------------------------------
#  This is used to setup verify the subroutines work as expected.  This sub
#      returns the hash of information expected after parseing the ViCi 
#      information.  This is the format expected along with the details.
#-------------------------------------------------------------------------------
   my $cfg_expected = {
          'top' => {
                     'version_regex' => "^hip :[^:]+: (\\d\\.\\d+\\w+)\$",
                     'version'  => '1.00a',
                     'vici_url' => 'http://vici/releasePageConstruct/index/id/24925/page_id/249',
                     'dirname'  => 'hbmphy_top',
                     'viciname' => 'hip',
                     'orientation' => 'N/A',
                     'orientation_regex' => '^hip : (_\w+)\+*(_\w+)* : ',
                     'mstack' => [
                                   '15M_1X_h_1Xa_v_1Ya_h_5Y_vhvhv_2Yy2Yx2R'
                                 ],
                     'PVT_regex' => '^PVT options : (.*)$',
                     'name' => 'top',
                     'pvt_values' => [
                                        'ssgnp0p675v125c',
                                        'ffgnp0p825v125c',
                                        'tt0p75v25c'
                                     ],
                     'pvt_corners' => [
                                        'rcworst_CCworst',
                                        'cworst_CCworst_T',
                                        'typical',
                                        'rcworst_CCworst_T',
                                        'rcbest_CCbest',
                                        'cbest_CCbest',
                                        'cworst_CCworst'
                                      ],
                     'pvt_combos' => [
                                'ffgnp0p825v125c_cworst_CCworst_T',
                                'ffgnp0p825v125c_rcworst_CCworst_T',
                                'ffgnp0p825v125c_cbest_CCbest',
                                'ffgnp0p825v125c_rcbest_CCbest',
                                'ssgnp0p675v125c_cworst_CCworst',
                                'ssgnp0p675v125c_rcworst_CCworst',
                                'ssgnp0p675v125c_cbest_CCbest',
                                'ssgnp0p675v125c_rcbest_CCbest',
                                'tt0p75v25c_typical'
                              ],
                     'mstack_regex' => '^Foundry Metal .+ (\\w+)$'
                   },
          'aword' => {
                       'version_regex' => "^awordx2 :[^:]+: (\\d\\.\\d+\\w+)\$",
                       'version'  => '1.12a',
                       'vici_url' => 'http://vici/releasePageConstruct/index/id/24925/page_id/249',
                       'dirname'  => 'awordx2',
                       'orientation' => [ '_ew' ],
                       'orientation_regex' => '^awordx2 : (_\w+)\+*(_\w+)* : ',
                       'mstack'   => [
                                     '6M_1X_h_1Xa_v_1Ya_h_2Y_vh'
                                   ],
                       'PVT_regex'  => '^PVT options : (.*)$',
                       'name'       => 'awordx2',
                       'pvt_values' => [
                                         'ssgnp0p675v125c',
                                         'ffgnp0p825v125c',
                                         'tt0p75v25c'
                                       ],
                       'pvt_corners' => [
                                          'rcworst_CCworst',
                                          'cworst_CCworst_T',
                                          'typical',
                                          'rcworst_CCworst_T',
                                          'rcbest_CCbest',
                                          'cbest_CCbest',
                                          'cworst_CCworst'
                                        ],
                       'pvt_combos' => [
                                  'ffgnp0p825v125c_cworst_CCworst_T',
                                  'ffgnp0p825v125c_rcworst_CCworst_T',
                                  'ffgnp0p825v125c_cbest_CCbest',
                                  'ffgnp0p825v125c_rcbest_CCbest',
                                  'ssgnp0p675v125c_cworst_CCworst',
                                  'ssgnp0p675v125c_rcworst_CCworst',
                                  'ssgnp0p675v125c_cbest_CCbest',
                                  'ssgnp0p675v125c_rcbest_CCbest',
                                  'tt0p75v25c_typical'
                                ],
                       'viciname' => 'awordx2',
                       'mstack_regex' => '^PHY Metal Option: (.*)$'
                     },
          'pub' => {
                     'version_regex' => "^pub :[^:]+: (\\d\\.\\d+\\w+)\$",
                     'version'  => '1.10a',
                     'vici_url' => 'http://vici/releasePageConstruct/index/id/24925/page_id/249',
                     'dirname'  => 'pub',
                     'orientation' => 'N/A',
                     'orientation_regex' => '^pub : (_\w+)\+*(_\w+)* : ',
                     'mstack'       => [ 'N/A' ],
                     'mstack_regex' => 'N/A',
                     'name'     => 'pub',
                     'viciname' => 'pub',
                     'process'  => 'tsmc7ff18',
                     'PVT_regex'   => 'N/A',
                     'pvt_combos'  => [ 'N/A' ],
                     'pvt_corners' => [ 'N/A' ],
                     'pvt_values'  => [ 'N/A' ],
                   },
          'macro' => {
                       'version_regex' => "^phy_top :[^:]+: (\\d\\.\\d+\\w+)\$",
                       'version' => '1.11a',
                       'dirname' => 'macro',
                       'orientation' => 'N/A',
                       'orientation_regex' => '^phy_top : (_\w+)\+*(_\w+)* : ',
                       'mstack'       => [ 'N/A' ],
                       'mstack_regex' => 'N/A',
                       'name' => 'macro',
                       'viciname' => 'phy_top',
                       'process'  => 'tsmc7ff18',
                       'PVT_regex'   => 'N/A',
                       'pvt_combos'  => [ 'N/A' ],
                       'pvt_corners' => [ 'N/A' ],
                       'pvt_values'  => [ 'N/A' ],
                     },
        };

   return( $vici_str , $href_cells , $cfg_expected );
}


#-------------------------------------------------------------------------------
#  Example of slurp from ViCi for d862 release 2.00a
#-------------------------------------------------------------------------------
sub TEST__setup_cell_cfg_d862(){
   print_function_header();

my $vici_str = <<'END_VICI';
Opening the \'http://vici/releasePageConstruct/index/id/25748/page_id/914\' url for checking content
Get cell_names and version from vici
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++
diff : _ew : 2.00a
master : _ns : 2.00a
repeater cells library : : 2.01a
se : _ew : 2.00a
sec : _ew : 2.00a
utility cells library : 2.01a
ctb :   : A-2020.02-BETA
firmware :   : A-2020.02-BETA
hspice/ibis views :  : 
installed_corekit :  : n/a
macro :  : 1.04a_amdsow2680
phyinit :  : A-2020.02-BETA
pub :  : 1.04a_amdsow2680
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++
Get pvt_corners from vici
++++++++++++++++++++++++++++++++++++++++++++++++++++++++
Standard Product Release : Corner type
PVT options : ff0p825vn40c_cbest_CCbest ff0p825v0c_cbest_CCbest ff0p825v125c_cbest_CCbest ff0p825vn40c_cworst_CCworst ff0p825v0c_cworst_CCworst ff0p825v125c_cworst_CCworst ff0p825vn40c_rcbest_CCbest ff0p825v0c_rcbest_CCbest ff0p825v125c_rcbest_CCbest ff0p825vn40c_rcworst_CCworst ff0p825v0c_rcworst_CCworst ff0p825v125c_rcworst_CCworst ff0p935vn40c_cbest_CCbest ff0p935v0c_cbest_CCbest ff0p935v125c_cbest_CCbest ff0p935vn40c_cworst_CCworst ff0p935v0c_cworst_CCworst ff0p935v125c_cworst_CCworst ff0p935vn40c_rcbest_CCbest ff0p935v0c_rcbest_CCbest ff0p935v125c_rcbest_CCbest ff0p935vn40c_rcworst_CCworst ff0p935v0c_rcworst_CCworst ff0p935v125c_rcworst_CCworst ss0p765vn40c_cbest_CCbest ss0p765v0c_cbest_CCbest ss0p765v125c_cbest_CCbest ss0p765vn40c_cworst_CCworst ss0p765v0c_cworst_CCworst ss0p765v125c_cworst_CCworst ss0p765vn40c_rcbest_CCbest ss0p765v0c_rcbest_CCbest ss0p765v125c_rcbest_CCbest ss0p765vn40c_rcworst_CCworst ss0p765v0c_rcworst_CCworst ss0p765v125c_rcworst_CCworst ss0p675vn40c_cbest_CCbest ss0p675v0c_cbest_CCbest ss0p675v125c_cbest_CCbest ss0p675vn40c_cworst_CCworst ss0p675v0c_cworst_CCworst ss0p675v125c_cworst_CCworst ss0p675vn40c_rcbest_CCbest ss0p675v0c_rcbest_CCbest ss0p675v125c_rcbest_CCbest ss0p675vn40c_rcworst_CCworst ss0p675v0c_rcworst_CCworst ss0p675v125c_rcworst_CCworst tt0p85v25c_typical tt0p75v25c_typical
++++++++++++++++++++++++++++++++++++++++++++++++++++++++

+++++++++++++++++++++++++++++++++++++++++++++
Get metal stacks from vici
Foundry Metal Option: 13M_1X_h_1Xa_v_1Ya_h_5Y_vhvhv_2Yy2Z
PHY Metal Option: 6M_1X_h_1Xa_v_1Ya_h_2Y_vh
+++++++++++++++++++++++++++++++++++++
END_VICI

my $href_cells = {
	    'master'  => {
			   'cell_name'   => 'master',
			   'dirname'     => 'master',
			   'viciname'    => 'master',
			   'vici_url'    => 'http://vici/releasePageConstruct/index/id/25748/page_id/914',
			   'mstack_regex'=> '^PHY Metal Option: (.*)$',
			   'PVT_regex'   => '^PVT options : (.*)$', 
			   'timing_cases'=> [ '', '_ccsn_lvf_3sigma' ],
      },
	    'rptr_cells'  => {
			   'cell_name'   => "repeater_cells",
			   'dirname'     => "repeater_cells",
			   'viciname'    => "repeater cells library",
			   'timing_cases'=> [ '', '_lvf' ],
			   'vici_url'    => 'http://vici/releasePageConstruct/index/id/25748/page_id/914',
			   'mstack_regex'=> '^PHY Metal Option: (.*)$',
			   'PVT_regex'   => '^PVT options : (.*)$', 
      },
	    'phyinit'  => {
			   'cell_name'   => 'phyinit',
			   'dirname'     => 'phyinit',
			   'viciname'    => 'phyinit',
			   'vici_url'    => 'http://vici/releasePageConstruct/index/id/25748/page_id/914',
			   'mstack_regex'=> 'N/A',
			   'PVT_regex'   => 'N/A',
      },
	    'firmware'  => {
			   'cell_name'   => 'firmware',
			   'dirname'     => 'firmware',
			   'viciname'    => 'firmware',
			   'vici_url'    => 'http://vici/releasePageConstruct/index/id/25748/page_id/914',
			   'mstack_regex'=> 'N/A',
			   'PVT_regex'   => 'N/A',
      },
	    'ctb'  => {
			   'cell_name'   => 'ctb',
			   'dirname'     => 'ctb',
			   'viciname'    => 'ctb',
			   'vici_url'    => 'http://vici/releasePageConstruct/index/id/25748/page_id/914',
			   'mstack_regex'=> 'N/A',
			   'PVT_regex'   => 'N/A',
      },
	 };

my $cfg_expected = {
          'ctb' => {
                     'cell_name'    => 'ctb',
                     'dirname'      => 'ctb',
                     'mstack'       => [ 'N/A' ],
                     'orientation'  => 'N/A',
                     'orientation_regex' => '^ctb : (_\w+)\+*(_\w+)* : ',
                     'pvt_combos'   => [ 'N/A' ],
                     'pvt_corners'  => [ 'N/A' ],
                     'pvt_values'   => [ 'N/A' ],
                     'version_regex' => "^ctb :[^:]+: (\\S+-\\S+-\\S+)\$",
                     'version'      => 'A-2020.02-BETA',
                     'vici_url'     => 'http://vici/releasePageConstruct/index/id/25748/page_id/914',
                     'viciname'     => 'ctb',
			               'mstack_regex' => 'N/A',
			               'PVT_regex'    => 'N/A',
          },
          'firmware' => {
                     'cell_name'    => 'firmware',
                     'dirname'      => 'firmware',
                     'mstack'       => [ 'N/A' ],
                     'orientation'  => 'N/A',
                     'orientation_regex' => '^firmware : (_\w+)\+*(_\w+)* : ',
                     'pvt_combos'   => [ 'N/A' ],
                     'pvt_corners'  => [ 'N/A' ],
                     'pvt_values'   => [ 'N/A' ],
                     'version_regex' => "^firmware :[^:]+: (\\S+-\\S+-\\S+)\$",
                     'version'      => 'A-2020.02-BETA',
                     'vici_url'     => 'http://vici/releasePageConstruct/index/id/25748/page_id/914',
                     'viciname'     => 'firmware',
			               'mstack_regex' => 'N/A',
			               'PVT_regex'    => 'N/A',
          },
          'master' => {
                     'PVT_regex'    => '^PVT options : (.*)$',
                     'cell_name'    => 'master',
                     'dirname'      => 'master',
                     'mstack'       => [ '6M_1X_h_1Xa_v_1Ya_h_2Y_vh' ],
                     'mstack_regex' => '^PHY Metal Option: (.*)$',
                     'orientation' => [ '_ns' ],
                     'orientation_regex' => '^master : (_\w+)\+*(_\w+)* : ',
                     'timing_cases' => [ '', '_ccsn_lvf_3sigma' ],
                     'version_regex' => "^master :[^:]+: (\\d\\.\\d+\\w+)\$",
                     'version'      => '2.00a',
                     'vici_url'     => 'http://vici/releasePageConstruct/index/id/25748/page_id/914',
                     'viciname'     => 'master',
                     'pvt_combos' => [
                         'ff0p825vn40c_cbest_CCbest', 'ff0p825v0c_cbest_CCbest',
                         'ff0p825v125c_cbest_CCbest', 'ff0p825vn40c_cworst_CCworst',
                         'ff0p825v0c_cworst_CCworst', 'ff0p825v125c_cworst_CCworst',
                         'ff0p825vn40c_rcbest_CCbest', 'ff0p825v0c_rcbest_CCbest',
                         'ff0p825v125c_rcbest_CCbest', 'ff0p825vn40c_rcworst_CCworst',
                         'ff0p825v0c_rcworst_CCworst', 'ff0p825v125c_rcworst_CCworst',
                         'ff0p935vn40c_cbest_CCbest', 'ff0p935v0c_cbest_CCbest',
                         'ff0p935v125c_cbest_CCbest', 'ff0p935vn40c_cworst_CCworst',
                         'ff0p935v0c_cworst_CCworst', 'ff0p935v125c_cworst_CCworst',
                         'ff0p935vn40c_rcbest_CCbest', 'ff0p935v0c_rcbest_CCbest',
                         'ff0p935v125c_rcbest_CCbest', 'ff0p935vn40c_rcworst_CCworst',
                         'ff0p935v0c_rcworst_CCworst', 'ff0p935v125c_rcworst_CCworst',
                         'ss0p765vn40c_cbest_CCbest', 'ss0p765v0c_cbest_CCbest',
                         'ss0p765v125c_cbest_CCbest', 'ss0p765vn40c_cworst_CCworst',
                         'ss0p765v0c_cworst_CCworst', 'ss0p765v125c_cworst_CCworst',
                         'ss0p765vn40c_rcbest_CCbest', 'ss0p765v0c_rcbest_CCbest',
                         'ss0p765v125c_rcbest_CCbest', 'ss0p765vn40c_rcworst_CCworst',
                         'ss0p765v0c_rcworst_CCworst', 'ss0p765v125c_rcworst_CCworst',
                         'ss0p675vn40c_cbest_CCbest', 'ss0p675v0c_cbest_CCbest',
                         'ss0p675v125c_cbest_CCbest', 'ss0p675vn40c_cworst_CCworst',
                         'ss0p675v0c_cworst_CCworst', 'ss0p675v125c_cworst_CCworst',
                         'ss0p675vn40c_rcbest_CCbest', 'ss0p675v0c_rcbest_CCbest',
                         'ss0p675v125c_rcbest_CCbest', 'ss0p675vn40c_rcworst_CCworst',
                         'ss0p675v0c_rcworst_CCworst', 'ss0p675v125c_rcworst_CCworst',
                         'tt0p85v25c_typical', 'tt0p75v25c_typical'
                     ],
                     'pvt_corners' => [
                         'cbest_CCbest', 'cworst_CCworst', 'rcworst_CCworst',
                         'typical', 'rcbest_CCbest' 
                     ],
                     'pvt_values' => [
                         'ss0p675vn40c', 'ss0p675v125c', 'ss0p765vn40c', 'ff0p825vn40c',
                         'ff0p935v125c', 'ff0p935v0c', 'tt0p85v25c', 'ss0p675v0c',
                         'ff0p825v125c', 'ss0p765v0c', 'ss0p765v125c', 'ff0p825v0c',
                         'ff0p935vn40c', 'tt0p75v25c'
                     ],
          },
          'phyinit' => {
                     'cell_name'    => 'phyinit',
                     'dirname'      => 'phyinit',
                     'mstack'       => [ 'N/A' ],
                     'orientation'  => 'N/A',
                     'orientation_regex' => '^phyinit : (_\w+)\+*(_\w+)* : ',
                     'pvt_combos'   => [ 'N/A' ],
                     'pvt_corners'  => [ 'N/A' ],
                     'pvt_values'   => [ 'N/A' ],
                     'version_regex' => "^phyinit :[^:]+: (\\S+-\\S+-\\S+)\$",
                     'version'      => 'A-2020.02-BETA',
                     'vici_url'     => 'http://vici/releasePageConstruct/index/id/25748/page_id/914',
                     'viciname'     => 'phyinit',
			               'mstack_regex' => 'N/A',
			               'PVT_regex'    => 'N/A',
          },
          'rptr_cells' => {
                     'PVT_regex'    => '^PVT options : (.*)$',
                     'cell_name'    => 'repeater_cells',
                     'dirname'      => 'repeater_cells',
                     'mstack'       => [ '6M_1X_h_1Xa_v_1Ya_h_2Y_vh' ],
                     'mstack_regex' => '^PHY Metal Option: (.*)$',
                     'orientation'  => 'N/A',
                     'orientation_regex' => '^repeater cells library : (_\w+)\+*(_\w+)* : ',
                     'timing_cases' => [ '', '_lvf' ],
                     'version_regex' => "^repeater cells library :[^:]+: (\\d\\.\\d+\\w+)\$",
                     'version'      => '2.01a',
                     'vici_url'     => 'http://vici/releasePageConstruct/index/id/25748/page_id/914',
                     'viciname'     => 'repeater cells library',
                     'pvt_combos' => [
                          'ff0p825vn40c_cbest_CCbest', 'ff0p825v0c_cbest_CCbest',
                          'ff0p825v125c_cbest_CCbest', 'ff0p825vn40c_cworst_CCworst',
                          'ff0p825v0c_cworst_CCworst', 'ff0p825v125c_cworst_CCworst',
                          'ff0p825vn40c_rcbest_CCbest', 'ff0p825v0c_rcbest_CCbest',
                          'ff0p825v125c_rcbest_CCbest', 'ff0p825vn40c_rcworst_CCworst',
                          'ff0p825v0c_rcworst_CCworst', 'ff0p825v125c_rcworst_CCworst',
                          'ff0p935vn40c_cbest_CCbest', 'ff0p935v0c_cbest_CCbest',
                          'ff0p935v125c_cbest_CCbest', 'ff0p935vn40c_cworst_CCworst',
                          'ff0p935v0c_cworst_CCworst', 'ff0p935v125c_cworst_CCworst',
                          'ff0p935vn40c_rcbest_CCbest', 'ff0p935v0c_rcbest_CCbest',
                          'ff0p935v125c_rcbest_CCbest', 'ff0p935vn40c_rcworst_CCworst',
                          'ff0p935v0c_rcworst_CCworst', 'ff0p935v125c_rcworst_CCworst',
                          'ss0p765vn40c_cbest_CCbest', 'ss0p765v0c_cbest_CCbest',
                          'ss0p765v125c_cbest_CCbest', 'ss0p765vn40c_cworst_CCworst',
                          'ss0p765v0c_cworst_CCworst', 'ss0p765v125c_cworst_CCworst',
                          'ss0p765vn40c_rcbest_CCbest', 'ss0p765v0c_rcbest_CCbest',
                          'ss0p765v125c_rcbest_CCbest', 'ss0p765vn40c_rcworst_CCworst',
                          'ss0p765v0c_rcworst_CCworst', 'ss0p765v125c_rcworst_CCworst',
                          'ss0p675vn40c_cbest_CCbest', 'ss0p675v0c_cbest_CCbest',
                          'ss0p675v125c_cbest_CCbest', 'ss0p675vn40c_cworst_CCworst',
                          'ss0p675v0c_cworst_CCworst', 'ss0p675v125c_cworst_CCworst',
                          'ss0p675vn40c_rcbest_CCbest', 'ss0p675v0c_rcbest_CCbest',
                          'ss0p675v125c_rcbest_CCbest', 'ss0p675vn40c_rcworst_CCworst',
                          'ss0p675v0c_rcworst_CCworst', 'ss0p675v125c_rcworst_CCworst',
                          'tt0p85v25c_typical', 'tt0p75v25c_typical'
                     ],
                     'pvt_corners' => [
                          'cbest_CCbest', 'cworst_CCworst',
                          'rcworst_CCworst', 'typical', 'rcbest_CCbest'
                     ],
                     'pvt_values' => [
                          'ss0p675vn40c', 'ss0p675v125c', 'ss0p765vn40c', 'ff0p825vn40c',
                          'ff0p935v125c', 'ff0p935v0c', 'tt0p85v25c', 'ss0p675v0c',
                          'ff0p825v125c', 'ss0p765v0c', 'ss0p765v125c', 'ff0p825v0c',
                          'ff0p935vn40c', 'tt0p75v25c'
                     ],
          }
   };
   return( $vici_str , $href_cells , $cfg_expected );
}



#-------------------------------------------------------------------------------
#  Example of slurp from ViCi for d852 (LP54) release 1.00a.
#     This shows corner case where the Version Note contains 2 orientations
#     'NS+ EW' & even 'NS + EW'
#-------------------------------------------------------------------------------
sub TEST__setup_cell_cfg_d852(){
   print_function_header();
my $vici_str = <<'END_VICI';
Opening the 'http://vici/releasePageConstruct/index/id/25755/page_id/914' url for checking content
Get cell_names and version from vici
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++
diff : _ew+_ns : 1.00a
master : _ns+_ew : 1.00a
repeater cells library :  : 1.00a
se : _ns+_ew : 1.00a
sec : _ns+_ew : 1.00a
utility cells library :  : 1.00a
ctb :  : A-2020.06
firmware :  : A-2020.06
hspice/ibis views :  : 
installed_corekit :  : 1.05b
macro :  : example
phyinit :  : A-2020.06
pub :  : na
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++
Get pvt_corners from vici
++++++++++++++++++++++++++++++++++++++++++++++++++++++++
Standard Product Release : Corner type
PVT options : ff0p825vn40c_cbest_CCbest ff0p825v0c_cbest_CCbest ff0p825v125c_cbest_CCbest ff0p825vn40c_cworst_CCworst ff0p825v0c_cworst_CCworst ff0p825v125c_cworst_CCworst ff0p825vn40c_rcbest_CCbest ff0p825v0c_rcbest_CCbest ff0p825v125c_rcbest_CCbest ff0p825vn40c_rcworst_CCworst ff0p825v0c_rcworst_CCworst ff0p825v125c_rcworst_CCworst ss0p675vn40c_cbest_CCbest ss0p675v0c_cbest_CCbest ss0p675v125c_cbest_CCbest ss0p675vn40c_cworst_CCworst ss0p675v0c_cworst_CCworst ss0p675v125c_cworst_CCworst ss0p675vn40c_rcbest_CCbest ss0p675v0c_rcbest_CCbest ss0p675v125c_rcbest_CCbest ss0p675vn40c_rcworst_CCworst ss0p675v0c_rcworst_CCworst ss0p675v125c_rcworst_CCworst tt0p75v25c_typical
++++++++++++++++++++++++++++++++++++++++++++++++++++++++

+++++++++++++++++++++++++++++++++++++++++++++
Get metal stacks from vici
Foundry Metal Option: 13M_1X_h_1Xa_v_1Ya_h_5Y_vhvhv_2Yy2Z
PHY Metal Option: 13M_1X_h_1Xa_v_1Ya_h_5Y_vhvhv_2Yy2Z
+++++++++++++++++++++++++++++++++++++
END_VICI

my $href_cells = {
	    'diff'  => {
			   'dirname'     => "diff",
			   'cell_name'   => "diff",
			   'viciname'    => "diff",
			   'vici_url'    => 'http://vici/releasePageConstruct/index/id/25755/page_id/914',
      },
	    'ctb'  => {
         'viciname'  => 'ctb',
			   'vici_url'    => 'http://vici/releasePageConstruct/index/id/25755/page_id/914',
			   'PVT_regex'   => '^PVT$',
      },
   };

   my $cfg_expected = {
      'diff' => {
           'cell_name'    => 'diff',
           'dirname'      => 'diff',
           'viciname'     => 'diff',
           'orientation_regex' => '^diff : (_\w+)\+*(_\w+)* : ',
           'orientation'  => [ '_ew' , '_ns' ],
           'mstack_regex' => '^PHY Metal Option: (.*)$',
           'mstack'       => [ '13M_1X_h_1Xa_v_1Ya_h_5Y_vhvhv_2Yy2Z' ],
           'PVT_regex'    => '^PVT options : (.*)$',
           'version_regex' => "^diff :[^:]+: (\\d\\.\\d+\\w+)\$",
           'version'      => '1.00a',
           'vici_url'     => 'http://vici/releasePageConstruct/index/id/25755/page_id/914',
                      'pvt_combos' => [
                                        'ff0p825vn40c_cbest_CCbest',
                                        'ff0p825v0c_cbest_CCbest',
                                        'ff0p825v125c_cbest_CCbest',
                                        'ff0p825vn40c_cworst_CCworst',
                                        'ff0p825v0c_cworst_CCworst',
                                        'ff0p825v125c_cworst_CCworst',
                                        'ff0p825vn40c_rcbest_CCbest',
                                        'ff0p825v0c_rcbest_CCbest',
                                        'ff0p825v125c_rcbest_CCbest',
                                        'ff0p825vn40c_rcworst_CCworst',
                                        'ff0p825v0c_rcworst_CCworst',
                                        'ff0p825v125c_rcworst_CCworst',
                                        'ss0p675vn40c_cbest_CCbest',
                                        'ss0p675v0c_cbest_CCbest',
                                        'ss0p675v125c_cbest_CCbest',
                                        'ss0p675vn40c_cworst_CCworst',
                                        'ss0p675v0c_cworst_CCworst',
                                        'ss0p675v125c_cworst_CCworst',
                                        'ss0p675vn40c_rcbest_CCbest',
                                        'ss0p675v0c_rcbest_CCbest',
                                        'ss0p675v125c_rcbest_CCbest',
                                        'ss0p675vn40c_rcworst_CCworst',
                                        'ss0p675v0c_rcworst_CCworst',
                                        'ss0p675v125c_rcworst_CCworst',
                                        'tt0p75v25c_typical'
                                      ],
                      'pvt_corners' => [
                                         'cbest_CCbest',
                                         'cworst_CCworst',
                                         'rcbest_CCbest',
                                         'rcworst_CCworst',
                                         'typical',
                                       ],
                      'pvt_values' => [
                                        'ss0p675vn40c',
                                        'ss0p675v125c',
                                        'ff0p825vn40c',
                                        'ss0p675v0c',
                                        'ff0p825v125c',
                                        'ff0p825v0c',
                                        'tt0p75v25c',
                                      ],
      },
      'ctb' => {
           'viciname'  => 'ctb',
           'version_regex' => "Default REGEX's for 'ViCi Versions' failed:\n\tHARD=^ctb :[^:]+: (\\d\\.\\d+\\w+)\$\n\tSOFT=^ctb :[^:]+: (\\S+-\\S+-\\S+)\$",
           'mstack_regex' => '^PHY Metal Option: (.*)$',
           'mstack'       => [ '13M_1X_h_1Xa_v_1Ya_h_5Y_vhvhv_2Yy2Z' ],
           'orientation_regex' => '^ctb : (_\\w+)\\+*(_\\w+)* : ',
           'orientation'       => 'N/A',
           'PVT_regex'   => '^PVT$',
           'pvt_combos'  => [ 'N/A' ],
           'pvt_corners' => [],
           'pvt_values'  => [ 'N/A' ],
           'version' => 'N/A',
           'vici_url' => 'http://vici/releasePageConstruct/index/id/25755/page_id/914',
      },
   };

   return( $vici_str , $href_cells , $cfg_expected );
} # end sub

#---------------------------------------------------------------------------------------
sub TEST__setup_cell_cfg_d812(){
   print_function_header();

my $vici_str = <<'END_VICI';
Opening the \'http://vici/releasePageConstruct/index/id/25928/page_id/185\' url for checking content',
Get cell_names and version from vici
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++
acx4_ew :  : 1.00a
dbyte_ew :  : 1.00a
decapvddq :  :  
io :  : 1.00a
master :  : 1.00a
pll :  : 
utility cells library :  : 1.00a
ctb :  : B-2019.11-BETA_AMD812
dml :  : 
firmware :  : A-2019.11-BETA
hardened :  : 
hspice/ibis views :  : 1.00a
installed_corekit :  : 
macro :  : 2.41b
phyinit :  : A-2019-11-BETA-PRE-20191003_AMDSOW2248
pub :  : 2.41b
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++
Get pvt_corners from vici
++++++++++++++++++++++++++++++++++++++++++++++++++++++++
Standard Product : Corner type
PVT options : ff0p825vn40c_cworst_CCworst ff0p825v0c_cworst_CCworst ff0p825v125c_cworst_CCworst ff0p825vn40c_rcworst_CCworst ff0p825v0c_rcworst_CCworst ff0p825v125c_rcworst_CCworst ff0p825vn40c_cbest_CCbest ff0p825v0c_cbest_CCbest ff0p825v125c_cbest_CCbest ff0p825vn40c_rcbest_CCbest ff0p825v0c_rcbest_CCbest ff0p825v125c_rcbest_CCbest ss0p675vn40c_cworst_CCworst ss0p675v0c_cworst_CCworst ss0p675v125c_cworst_CCworst ss0p675vn40c_rcworst_CCworst ss0p675v0c_rcworst_CCworst ss0p675v125c_rcworst_CCworst ss0p675vn40c_cbest_CCbest ss0p675v0c_cbest_CCbest ss0p675v125c_cbest_CCbest ss0p675vn40c_rcbest_CCbest ss0p675v0c_rcbest_CCbest ss0p675v125c_rcbest_CCbest tt0p75v25c_typical ff0p935vn40c_cworst_CCworst ff0p935v0c_cworst_CCworst ff0p935v125c_cworst_CCworst ff0p935vn40c_rcworst_CCworst ff0p935v0c_rcworst_CCworst ff0p935v125c_rcworst_CCworst ff0p935vn40c_cbest_CCbest ff0p935v0c_cbest_CCbest ff0p935v125c_cbest_CCbest ff0p935vn40c_rcbest_CCbest ff0p935v0c_rcbest_CCbest ff0p935v125c_rcbest_CCbest ss0p765vn40c_cworst_CCworst ss0p765v0c_cworst_CCworst ss0p765v125c_cworst_CCworst ss0p765vn40c_rcworst_CCworst ss0p765v0c_rcworst_CCworst ss0p765v125c_rcworst_CCworst ss0p765vn40c_cbest_CCbest ss0p765v0c_cbest_CCbest ss0p765v125c_cbest_CCbest ss0p765vn40c_rcbest_CCbest ss0p765v0c_rcbest_CCbest ss0p765v125c_rcbest_CCbest tt0p85v25c_typical
++++++++++++++++++++++++++++++++++++++++++++++++++++++++

+++++++++++++++++++++++++++++++++++++++++++++
Get metal stacks from vici
Foundry Metal Option: 13M_1X_h_1Xa_v_1Ya_h_5Y_vhvhv_2Yy2Z
PHY Metal Option: 8M_1X_h_1Xa_v_1Ya_h_4Y_vhvh
+++++++++++++++++++++++++++++++++++++
END_VICI

my $href_cells = {
	    'clktree_repeater'  => {
			   'dirname'     => "clktree_repeater",
			   'cell_name'   => "clktree_repeater",
			   'viciname'    => "io",
			   'mstack_regex'=> '',
			   'overrides'   => { 
             'mstack' => [ '6M_1X_h_1Xa_v_1Ya_h_2Y_vh' ],
             'orientation' => 'N/A',
         },
			   'PVT_regex'   => '^PVT options : (.*)$', 
			   'vici_url'    => 'http://vici/releasePageConstruct/index/id/25928/page_id/185',
      },
	    'phyinit'  => {
			   'dirname'     => "phyinit",
			   'cell_name'   => "phyinit",
			   'viciname'    => "phyinit",
			   'mstack_regex'=> '',
			   'PVT_regex'   => '',
			   'vici_url'    => 'http://vici/releasePageConstruct/index/id/25928/page_id/185',
			   'version_regex'=> ' :  : (\S+)$',
			   'overrides'   => { 
             'orientation' => 'N/A',
			   },
      },
   };

   my $cfg_expected = {
      'phyinit' => {
           'PVT_regex'    => '',
           'cell_name'    => 'phyinit',
           'dirname'      => 'phyinit',
           'mstack_regex' => '',
           'mstack'       => [ 'N/A' ],
           'orientation_regex'  => '^phyinit : (_\w+)\+*(_\w+)* : ',
           'orientation'  => 'N/A',
           'overrides'    => {
                'orientation' => 'N/A'
           },
           'pvt_combos'   => [ 'N/A' ],
           'pvt_corners'  => [],
           'pvt_values'   => [ 'N/A' ],
           'version'      => 'A-2019-11-BETA-PRE-20191003_AMDSOW2248',
			     'version_regex'=> '^phyinit :  : (\S+)$',
           'vici_url'     => 'http://vici/releasePageConstruct/index/id/25928/page_id/185',
           'viciname'     => 'phyinit'
      },
      'clktree_repeater'  => {
           'cell_name'    => 'clktree_repeater',
           'dirname'      => 'clktree_repeater',
           'viciname'     => 'io',
           'mstack_regex' => '',
           'mstack'       => [ 'N/A' ],
           'orientation_regex'  => '^io : (_\w+)\+*(_\w+)* : ',
           'orientation'  => 'N/A',
           'version_regex' => "^io :[^:]+: (\\d\\.\\d+\\w+)\$",
           'version'      => '1.00a',
           'vici_url'     => 'http://vici/releasePageConstruct/index/id/25928/page_id/185',
           'PVT_regex'    => '^PVT options : (.*)$',
           'pvt_combos'   => [
                                                    'ff0p825vn40c_cworst_CCworst',
                                                    'ff0p825v0c_cworst_CCworst',
                                                    'ff0p825v125c_cworst_CCworst',
                                                    'ff0p825vn40c_rcworst_CCworst',
                                                    'ff0p825v0c_rcworst_CCworst',
                                                    'ff0p825v125c_rcworst_CCworst',
                                                    'ff0p825vn40c_cbest_CCbest',
                                                    'ff0p825v0c_cbest_CCbest',
                                                    'ff0p825v125c_cbest_CCbest',
                                                    'ff0p825vn40c_rcbest_CCbest',
                                                    'ff0p825v0c_rcbest_CCbest',
                                                    'ff0p825v125c_rcbest_CCbest',
                                                    'ss0p675vn40c_cworst_CCworst',
                                                    'ss0p675v0c_cworst_CCworst',
                                                    'ss0p675v125c_cworst_CCworst',
                                                    'ss0p675vn40c_rcworst_CCworst',
                                                    'ss0p675v0c_rcworst_CCworst',
                                                    'ss0p675v125c_rcworst_CCworst',
                                                    'ss0p675vn40c_cbest_CCbest',
                                                    'ss0p675v0c_cbest_CCbest',
                                                    'ss0p675v125c_cbest_CCbest',
                                                    'ss0p675vn40c_rcbest_CCbest',
                                                    'ss0p675v0c_rcbest_CCbest',
                                                    'ss0p675v125c_rcbest_CCbest',
                                                    'tt0p75v25c_typical',
                                                    'ff0p935vn40c_cworst_CCworst',
                                                    'ff0p935v0c_cworst_CCworst',
                                                    'ff0p935v125c_cworst_CCworst',
                                                    'ff0p935vn40c_rcworst_CCworst',
                                                    'ff0p935v0c_rcworst_CCworst',
                                                    'ff0p935v125c_rcworst_CCworst',
                                                    'ff0p935vn40c_cbest_CCbest',
                                                    'ff0p935v0c_cbest_CCbest',
                                                    'ff0p935v125c_cbest_CCbest',
                                                    'ff0p935vn40c_rcbest_CCbest',
                                                    'ff0p935v0c_rcbest_CCbest',
                                                    'ff0p935v125c_rcbest_CCbest',
                                                    'ss0p765vn40c_cworst_CCworst',
                                                    'ss0p765v0c_cworst_CCworst',
                                                    'ss0p765v125c_cworst_CCworst',
                                                    'ss0p765vn40c_rcworst_CCworst',
                                                    'ss0p765v0c_rcworst_CCworst',
                                                    'ss0p765v125c_rcworst_CCworst',
                                                    'ss0p765vn40c_cbest_CCbest',
                                                    'ss0p765v0c_cbest_CCbest',
                                                    'ss0p765v125c_cbest_CCbest',
                                                    'ss0p765vn40c_rcbest_CCbest',
                                                    'ss0p765v0c_rcbest_CCbest',
                                                    'ss0p765v125c_rcbest_CCbest',
                                                    'tt0p85v25c_typical'
           ],
           'pvt_corners' => [
                                                     'cbest_CCbest',
                                                     'cworst_CCworst',
                                                     'rcworst_CCworst',
                                                     'typical',
                                                     'rcbest_CCbest'
           ],
           'pvt_values' => [
                                                    'ss0p675vn40c',
                                                    'ss0p675v125c',
                                                    'ss0p765vn40c',
                                                    'ff0p825vn40c',
                                                    'ff0p935v125c',
                                                    'ff0p935v0c',
                                                    'tt0p85v25c',
                                                    'ss0p675v0c',
                                                    'ff0p825v125c',
                                                    'ss0p765v0c',
                                                    'ss0p765v125c',
                                                    'ff0p825v0c',
                                                    'ff0p935vn40c',
                                                    'tt0p75v25c'
           ],
			     # Overrides are not used in ViCi.pm, and are applied afterwards.
			     #    So, these are effectively a don't care for this test.
			     #    However, it's valuable to record how this corner case
			     #    is handled in real situation.
			     'overrides'    => { 
               'mstack'      => [ '6M_1X_h_1Xa_v_1Ya_h_2Y_vh' ],
               'orientation' => 'N/A',
           },
      },
   };

   return( $vici_str , $href_cells , $cfg_expected );
}

#---------------------------------------------------------------------------------------
#  Example of slurp from ViCi for d862 release 2.00a
#---------------------------------------------------------------------------------------
#  this sub is a copy but with slight modification ... there is no metal option
#  in the content returned from ViCi.  This mimics situation reported by Davit H
#  Jul 2021 (JIRA P10020416-29157), where project was being cross-checked for release,
#  but still no metal option was defined in the project vici page.
#
#  The key here is to ensure the behavior of the flow remains stable in light of this
#  possibility.
#-------------------------------------------------------------------------------
sub TEST__setup_cell_cfg_d862_modified(){
   print_function_header();

my $vici_str = <<'END_VICI';
Opening the \'http://vici/releasePageConstruct/index/id/25748/page_id/914\' url for checking content
Get cell_names and version from vici
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++
diff : _ew : 2.00a
master : _ns : 2.00a
repeater cells library : : 2.01a
se : _ew : 2.00a
sec : _ew : 2.00a
utility cells library : 2.01a
ctb :   : A-2020.02-BETA
firmware :   : A-2020.02-BETA
hspice/ibis views :  : 
installed_corekit :  : n/a
macro :  : 1.04a_amdsow2680
phyinit :  : A-2020.02-BETA
pub :  : 1.04a_amdsow2680
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++
Get pvt_corners from vici
++++++++++++++++++++++++++++++++++++++++++++++++++++++++
Standard Product Release : Corner type
PVT options : ff0p825vn40c_cbest_CCbest ff0p825v0c_cbest_CCbest ff0p825v125c_cbest_CCbest ff0p825vn40c_cworst_CCworst ff0p825v0c_cworst_CCworst ff0p825v125c_cworst_CCworst ff0p825vn40c_rcbest_CCbest ff0p825v0c_rcbest_CCbest ff0p825v125c_rcbest_CCbest ff0p825vn40c_rcworst_CCworst ff0p825v0c_rcworst_CCworst ff0p825v125c_rcworst_CCworst ff0p935vn40c_cbest_CCbest ff0p935v0c_cbest_CCbest ff0p935v125c_cbest_CCbest ff0p935vn40c_cworst_CCworst ff0p935v0c_cworst_CCworst ff0p935v125c_cworst_CCworst ff0p935vn40c_rcbest_CCbest ff0p935v0c_rcbest_CCbest ff0p935v125c_rcbest_CCbest ff0p935vn40c_rcworst_CCworst ff0p935v0c_rcworst_CCworst ff0p935v125c_rcworst_CCworst ss0p765vn40c_cbest_CCbest ss0p765v0c_cbest_CCbest ss0p765v125c_cbest_CCbest ss0p765vn40c_cworst_CCworst ss0p765v0c_cworst_CCworst ss0p765v125c_cworst_CCworst ss0p765vn40c_rcbest_CCbest ss0p765v0c_rcbest_CCbest ss0p765v125c_rcbest_CCbest ss0p765vn40c_rcworst_CCworst ss0p765v0c_rcworst_CCworst ss0p765v125c_rcworst_CCworst ss0p675vn40c_cbest_CCbest ss0p675v0c_cbest_CCbest ss0p675v125c_cbest_CCbest ss0p675vn40c_cworst_CCworst ss0p675v0c_cworst_CCworst ss0p675v125c_cworst_CCworst ss0p675vn40c_rcbest_CCbest ss0p675v0c_rcbest_CCbest ss0p675v125c_rcbest_CCbest ss0p675vn40c_rcworst_CCworst ss0p675v0c_rcworst_CCworst ss0p675v125c_rcworst_CCworst tt0p85v25c_typical tt0p75v25c_typical
++++++++++++++++++++++++++++++++++++++++++++++++++++++++

+++++++++++++++++++++++++++++++++++++++++++++
Get metal stacks from vici
Foundry Metal Option: 13M_1X_h_1Xa_v_1Ya_h_5Y_vhvhv_2Yy2Z
PHY Metal Option: 
+++++++++++++++++++++++++++++++++++++
END_VICI

my $href_cells = {
	    'master'  => {
			   'cell_name'   => 'master',
			   'dirname'     => 'master',
			   'viciname'    => 'master',
			   'vici_url'    => 'http://vici/releasePageConstruct/index/id/25748/page_id/914',
			   'mstack_regex'=> '^PHY Metal Option: (.*)$',
			   'PVT_regex'   => '^PVT options : (.*)$', 
			   'timing_cases'=> [ '', '_ccsn_lvf_3sigma' ],
      },
	    'rptr_cells'  => {
			   'cell_name'   => "repeater_cells",
			   'dirname'     => "repeater_cells",
			   'viciname'    => "repeater cells library",
			   'timing_cases'=> [ '', '_lvf' ],
			   'vici_url'    => 'http://vici/releasePageConstruct/index/id/25748/page_id/914',
			   'mstack_regex'=> '^PHY Metal Option: (.*)$',
			   'PVT_regex'   => '^PVT options : (.*)$', 
      },
	    'phyinit'  => {
			   'cell_name'   => 'phyinit',
			   'dirname'     => 'phyinit',
			   'viciname'    => 'phyinit',
			   'vici_url'    => 'http://vici/releasePageConstruct/index/id/25748/page_id/914',
			   'mstack_regex'=> 'N/A',
			   'PVT_regex'   => 'N/A',
      },
	    'firmware'  => {
			   'cell_name'   => 'firmware',
			   'dirname'     => 'firmware',
			   'viciname'    => 'firmware',
			   'vici_url'    => 'http://vici/releasePageConstruct/index/id/25748/page_id/914',
			   'mstack_regex'=> 'N/A',
			   'PVT_regex'   => 'N/A',
      },
	    'ctb'  => {
			   'cell_name'   => 'ctb',
			   'dirname'     => 'ctb',
			   'viciname'    => 'ctb',
			   'vici_url'    => 'http://vici/releasePageConstruct/index/id/25748/page_id/914',
			   'mstack_regex'=> 'N/A',
			   'PVT_regex'   => 'N/A',
      },
	 };

my $cfg_expected = {
          'ctb' => {
                     'cell_name'    => 'ctb',
                     'dirname'      => 'ctb',
                     'mstack'       => [ 'N/A' ],
                     'orientation'  => 'N/A',
                     'orientation_regex' => '^ctb : (_\w+)\+*(_\w+)* : ',
                     'pvt_combos'   => [ 'N/A' ],
                     'pvt_corners'  => [ 'N/A' ],
                     'pvt_values'   => [ 'N/A' ],
                     'version_regex' => "^ctb :[^:]+: (\\S+-\\S+-\\S+)\$",
                     'version'      => 'A-2020.02-BETA',
                     'vici_url'     => 'http://vici/releasePageConstruct/index/id/25748/page_id/914',
                     'viciname'     => 'ctb',
			               'mstack_regex' => 'N/A',
			               'PVT_regex'    => 'N/A',
          },
          'firmware' => {
                     'cell_name'    => 'firmware',
                     'dirname'      => 'firmware',
                     'mstack'       => [ 'N/A' ],
                     'orientation'  => 'N/A',
                     'orientation_regex' => '^firmware : (_\w+)\+*(_\w+)* : ',
                     'pvt_combos'   => [ 'N/A' ],
                     'pvt_corners'  => [ 'N/A' ],
                     'pvt_values'   => [ 'N/A' ],
                     'version_regex' => "^firmware :[^:]+: (\\S+-\\S+-\\S+)\$",
                     'version'      => 'A-2020.02-BETA',
                     'vici_url'     => 'http://vici/releasePageConstruct/index/id/25748/page_id/914',
                     'viciname'     => 'firmware',
			               'mstack_regex' => 'N/A',
			               'PVT_regex'    => 'N/A',
          },
          'master' => {
                     'PVT_regex'    => '^PVT options : (.*)$',
                     'cell_name'    => 'master',
                     'dirname'      => 'master',
                     'mstack'       => [ '6M_1X_h_1Xa_v_1Ya_h_2Y_vh' ],
                     'mstack_regex' => '^PHY Metal Option: (.*)$',
                     'orientation' => [ '_ns' ],
                     'orientation_regex' => '^master : (_\w+)\+*(_\w+)* : ',
                     'timing_cases' => [ '', '_ccsn_lvf_3sigma' ],
                     'version_regex' => "^master :[^:]+: (\\d\\.\\d+\\w+)\$",
                     'version'      => '2.00a',
                     'vici_url'     => 'http://vici/releasePageConstruct/index/id/25748/page_id/914',
                     'viciname'     => 'master',
                     'pvt_combos' => [
                         'ff0p825vn40c_cbest_CCbest', 'ff0p825v0c_cbest_CCbest',
                         'ff0p825v125c_cbest_CCbest', 'ff0p825vn40c_cworst_CCworst',
                         'ff0p825v0c_cworst_CCworst', 'ff0p825v125c_cworst_CCworst',
                         'ff0p825vn40c_rcbest_CCbest', 'ff0p825v0c_rcbest_CCbest',
                         'ff0p825v125c_rcbest_CCbest', 'ff0p825vn40c_rcworst_CCworst',
                         'ff0p825v0c_rcworst_CCworst', 'ff0p825v125c_rcworst_CCworst',
                         'ff0p935vn40c_cbest_CCbest', 'ff0p935v0c_cbest_CCbest',
                         'ff0p935v125c_cbest_CCbest', 'ff0p935vn40c_cworst_CCworst',
                         'ff0p935v0c_cworst_CCworst', 'ff0p935v125c_cworst_CCworst',
                         'ff0p935vn40c_rcbest_CCbest', 'ff0p935v0c_rcbest_CCbest',
                         'ff0p935v125c_rcbest_CCbest', 'ff0p935vn40c_rcworst_CCworst',
                         'ff0p935v0c_rcworst_CCworst', 'ff0p935v125c_rcworst_CCworst',
                         'ss0p765vn40c_cbest_CCbest', 'ss0p765v0c_cbest_CCbest',
                         'ss0p765v125c_cbest_CCbest', 'ss0p765vn40c_cworst_CCworst',
                         'ss0p765v0c_cworst_CCworst', 'ss0p765v125c_cworst_CCworst',
                         'ss0p765vn40c_rcbest_CCbest', 'ss0p765v0c_rcbest_CCbest',
                         'ss0p765v125c_rcbest_CCbest', 'ss0p765vn40c_rcworst_CCworst',
                         'ss0p765v0c_rcworst_CCworst', 'ss0p765v125c_rcworst_CCworst',
                         'ss0p675vn40c_cbest_CCbest', 'ss0p675v0c_cbest_CCbest',
                         'ss0p675v125c_cbest_CCbest', 'ss0p675vn40c_cworst_CCworst',
                         'ss0p675v0c_cworst_CCworst', 'ss0p675v125c_cworst_CCworst',
                         'ss0p675vn40c_rcbest_CCbest', 'ss0p675v0c_rcbest_CCbest',
                         'ss0p675v125c_rcbest_CCbest', 'ss0p675vn40c_rcworst_CCworst',
                         'ss0p675v0c_rcworst_CCworst', 'ss0p675v125c_rcworst_CCworst',
                         'tt0p85v25c_typical', 'tt0p75v25c_typical'
                     ],
                     'pvt_corners' => [
                         'cbest_CCbest', 'cworst_CCworst', 'rcworst_CCworst',
                         'typical', 'rcbest_CCbest' 
                     ],
                     'pvt_values' => [
                         'ss0p675vn40c', 'ss0p675v125c', 'ss0p765vn40c', 'ff0p825vn40c',
                         'ff0p935v125c', 'ff0p935v0c', 'tt0p85v25c', 'ss0p675v0c',
                         'ff0p825v125c', 'ss0p765v0c', 'ss0p765v125c', 'ff0p825v0c',
                         'ff0p935vn40c', 'tt0p75v25c'
                     ],
          },
          'phyinit' => {
                     'cell_name'    => 'phyinit',
                     'dirname'      => 'phyinit',
                     'mstack'       => [ 'N/A' ],
                     'orientation'  => 'N/A',
                     'orientation_regex' => '^phyinit : (_\w+)\+*(_\w+)* : ',
                     'pvt_combos'   => [ 'N/A' ],
                     'pvt_corners'  => [ 'N/A' ],
                     'pvt_values'   => [ 'N/A' ],
                     'version_regex' => "^phyinit :[^:]+: (\\S+-\\S+-\\S+)\$",
                     'version'      => 'A-2020.02-BETA',
                     'vici_url'     => 'http://vici/releasePageConstruct/index/id/25748/page_id/914',
                     'viciname'     => 'phyinit',
			               'mstack_regex' => 'N/A',
			               'PVT_regex'    => 'N/A',
          },
          'rptr_cells' => {
                     'PVT_regex'    => '^PVT options : (.*)$',
                     'cell_name'    => 'repeater_cells',
                     'dirname'      => 'repeater_cells',
                     'mstack'       => [ '6M_1X_h_1Xa_v_1Ya_h_2Y_vh' ],
                     'mstack_regex' => '^PHY Metal Option: (.*)$',
                     'orientation'  => 'N/A',
                     'orientation_regex' => '^repeater cells library : (_\w+)\+*(_\w+)* : ',
                     'timing_cases' => [ '', '_lvf' ],
                     'version_regex' => "^repeater cells library :[^:]+: (\\d\\.\\d+\\w+)\$",
                     'version'      => '2.01a',
                     'vici_url'     => 'http://vici/releasePageConstruct/index/id/25748/page_id/914',
                     'viciname'     => 'repeater cells library',
                     'pvt_combos' => [
                          'ff0p825vn40c_cbest_CCbest', 'ff0p825v0c_cbest_CCbest',
                          'ff0p825v125c_cbest_CCbest', 'ff0p825vn40c_cworst_CCworst',
                          'ff0p825v0c_cworst_CCworst', 'ff0p825v125c_cworst_CCworst',
                          'ff0p825vn40c_rcbest_CCbest', 'ff0p825v0c_rcbest_CCbest',
                          'ff0p825v125c_rcbest_CCbest', 'ff0p825vn40c_rcworst_CCworst',
                          'ff0p825v0c_rcworst_CCworst', 'ff0p825v125c_rcworst_CCworst',
                          'ff0p935vn40c_cbest_CCbest', 'ff0p935v0c_cbest_CCbest',
                          'ff0p935v125c_cbest_CCbest', 'ff0p935vn40c_cworst_CCworst',
                          'ff0p935v0c_cworst_CCworst', 'ff0p935v125c_cworst_CCworst',
                          'ff0p935vn40c_rcbest_CCbest', 'ff0p935v0c_rcbest_CCbest',
                          'ff0p935v125c_rcbest_CCbest', 'ff0p935vn40c_rcworst_CCworst',
                          'ff0p935v0c_rcworst_CCworst', 'ff0p935v125c_rcworst_CCworst',
                          'ss0p765vn40c_cbest_CCbest', 'ss0p765v0c_cbest_CCbest',
                          'ss0p765v125c_cbest_CCbest', 'ss0p765vn40c_cworst_CCworst',
                          'ss0p765v0c_cworst_CCworst', 'ss0p765v125c_cworst_CCworst',
                          'ss0p765vn40c_rcbest_CCbest', 'ss0p765v0c_rcbest_CCbest',
                          'ss0p765v125c_rcbest_CCbest', 'ss0p765vn40c_rcworst_CCworst',
                          'ss0p765v0c_rcworst_CCworst', 'ss0p765v125c_rcworst_CCworst',
                          'ss0p675vn40c_cbest_CCbest', 'ss0p675v0c_cbest_CCbest',
                          'ss0p675v125c_cbest_CCbest', 'ss0p675vn40c_cworst_CCworst',
                          'ss0p675v0c_cworst_CCworst', 'ss0p675v125c_cworst_CCworst',
                          'ss0p675vn40c_rcbest_CCbest', 'ss0p675v0c_rcbest_CCbest',
                          'ss0p675v125c_rcbest_CCbest', 'ss0p675vn40c_rcworst_CCworst',
                          'ss0p675v0c_rcworst_CCworst', 'ss0p675v125c_rcworst_CCworst',
                          'tt0p85v25c_typical', 'tt0p75v25c_typical'
                     ],
                     'pvt_corners' => [
                          'cbest_CCbest', 'cworst_CCworst',
                          'rcworst_CCworst', 'typical', 'rcbest_CCbest'
                     ],
                     'pvt_values' => [
                          'ss0p675vn40c', 'ss0p675v125c', 'ss0p765vn40c', 'ff0p825vn40c',
                          'ff0p935v125c', 'ff0p935v0c', 'tt0p85v25c', 'ss0p675v0c',
                          'ff0p825v125c', 'ss0p765v0c', 'ss0p765v125c', 'ff0p825v0c',
                          'ff0p935vn40c', 'tt0p75v25c'
                     ],
          }
   };
   return( $vici_str , $href_cells , $cfg_expected );
}



#-------------------------------------------------------------------------------
