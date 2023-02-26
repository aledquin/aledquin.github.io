#!/depot/perl-5.14.2/bin/perl

use strict;
use Test2::Tools::Compare;
use Test2::Bundle::More;
use Data::Dumper;
use File::Copy;
use Getopt::Std;
use File::Basename qw( dirname );
use File::Spec::Functions qw( catfile );
use Cwd qw( abs_path );
use Carp qw(cluck confess croak);

use lib dirname(abs_path $0) . '/../../perl/lib/';
use Util::CommonHeader;
use Util::Misc;
use Util::Messaging;

our $PROGRAM_NAME = $0; 
#----------------------------------#
use constant PYTHON_SCRIPT_NAME =>  dirname(abs_path $0).'/../bin/get_vici_info.py';
our $DEBUG = SUPER;
#----------------------------------#


BEGIN { header(); } 
   Main();
END { footer(); }

########  YOUR CODE goes in Main  ##############
sub Main {
   process_cmd_line_args();

   my %test;

   (%test) = d852_lpddr54_tsmc6ff18( );
   run_my_test( $test{test_name}, $test{vici_url}, $test{expected_result},  );
   
exit;
   (%test) = d714_hbm2e_tsmc7ff18( );
   run_my_test( $test{test_name}, $test{vici_url}, $test{expected_result},  );

   (%test) = d862_lpddr54_cuamd_tsmc6ff18( );
   run_my_test( $test{test_name}, $test{vici_url}, $test{expected_result},  );

   (%test) = d805_ddr54_tsmc7ff18_plus18( );
   run_my_test( $test{test_name}, $test{vici_url}, $test{expected_result},  );

   done_testing();
}
############    END Main    ####################

############_##################################################################
sub run_my_test ($$$){
   print_function_header();
   my $test_name = shift;
   my $vici_url  = shift;
   my $expected_script_output = shift;


	 my $cmd = PYTHON_SCRIPT_NAME . " $vici_url";
	 my ($stdout, $retval) = run_system_cmd( $cmd, $DEBUG );
   my $aref_vici_slurp = [ split(/\n+/, $stdout) ];
   is_deeply( $aref_vici_slurp, $expected_script_output, $test_name );
   dprint(HIGH, "ViCi slurp complete ... vomiting results:\n " . scalar(Dumper $aref_vici_slurp) . "\n" );

   print_function_footer();
}

#----------------------------------------------------------------------------------------------
# Test 1 - d852
#----------------------------------------------------------------------------------------------
sub d852_lpddr54_tsmc6ff18(){
my $expected_script_output = <<'END_VICI';
-I- Opening the 'http://vici/releasePageConstruct/index/id/25755/page_id/914' url for checking content
-I- Get cell_names and version from vici
-I- ViCi information returned.
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++
diff : _ew+_ns : 1.00a
master : _ew+_ns : 1.00a
repeater cells library :  : 1.00a
se : _ew+_ns : 1.00a
sec : _ew+_ns : 1.00a
utility cells library :  : 1.00a
ctb :  : A-2020.06
firmware :  : A-2020.06
hspice/ibis views :  : 
installed_corekit :  : 1.05b
macro :  : example
phyinit :  : A-2020.06
pub :  : na
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-I- Done grabbing cell_names and version from ViCi
-I- Get pvt_corners from vici
Standard Product Release
['ff', '0.825', '-40, 0, 125', 'cbest_CCbest, cworst_CCworst, rcbest_CCbest, rcworst_CCworst']
['ss', '0.675', '-40, 0, 125', 'cbest_CCbest, cworst_CCworst, rcbest_CCbest, rcworst_CCworst']
['tt', '0.75', '25', 'typical']
++++++++++++++++++++++++++++++++++++++++++++++++++++++++
Standard Product Release : PVT options : ff0p825vn40c_cbest_CCbest ff0p825v0c_cbest_CCbest ff0p825v125c_cbest_CCbest ff0p825vn40c_cworst_CCworst ff0p825v0c_cworst_CCworst ff0p825v125c_cworst_CCworst ff0p825vn40c_rcbest_CCbest ff0p825v0c_rcbest_CCbest ff0p825v125c_rcbest_CCbest ff0p825vn40c_rcworst_CCworst ff0p825v0c_rcworst_CCworst ff0p825v125c_rcworst_CCworst ss0p675vn40c_cbest_CCbest ss0p675v0c_cbest_CCbest ss0p675v125c_cbest_CCbest ss0p675vn40c_cworst_CCworst ss0p675v0c_cworst_CCworst ss0p675v125c_cworst_CCworst ss0p675vn40c_rcbest_CCbest ss0p675v0c_rcbest_CCbest ss0p675v125c_rcbest_CCbest ss0p675vn40c_rcworst_CCworst ss0p675v0c_rcworst_CCworst ss0p675v125c_rcworst_CCworst tt0p75v25c_typical
++++++++++++++++++++++++++++++++++++++++++++++++++++++++
+++++++++++++++++++++++++++++++++++++++++++++
-I- Get metal stacks from vici
Foundry Metal Option: 13M_1X_h_1Xa_v_1Ya_h_5Y_vhvhv_2Yy2Z
PHY Metal Option: 13M_1X_h_1Xa_v_1Ya_h_5Y_vhvhv_2Yy2Z
+++++++++++++++++++++++++++++++++++++
END_VICI
my (@expected_result) = split(/\n+/, $expected_script_output);
my %test = (
    'test_name'       => 'd852-1.00a',
    'vici_url'        => 'http://vici/releasePageConstruct/index/id/25755/page_id/914',
    'expected_result' => [ @expected_result ],
);
return( %test );
}


#----------------------------------------------------------------------------------------------
# Test 2 - d714
#----------------------------------------------------------------------------------------------
sub d714_hbm2e_tsmc7ff18(){
my $expected_script_output = <<'END_VICI';
-I- Opening the 'http://vici/releasePageConstruct/index/id/24925/page_id/249' url for checking content
-I- Get cell_names and version from vici
-I- ViCi information returned.
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
-I- Done grabbing cell_names and version from ViCi
-I- Get pvt_corners from vici
++++++++++++++++++++++++++++++++++++++++++++++++++++++++
Standard Product : PVT options : ffgnp0p825vn40c_cworst_CCworst_T ffgnp0p825v0c_cworst_CCworst_T ffgnp0p825v125c_cworst_CCworst_T ffgnp0p825vn40c_rcworst_CCworst_T ffgnp0p825v0c_rcworst_CCworst_T ffgnp0p825v125c_rcworst_CCworst_T ffgnp0p825vn40c_cbest_CCbest ffgnp0p825v0c_cbest_CCbest ffgnp0p825v125c_cbest_CCbest ffgnp0p825vn40c_rcbest_CCbest ffgnp0p825v0c_rcbest_CCbest ffgnp0p825v125c_rcbest_CCbest ssgnp0p675vn40c_cworst_CCworst ssgnp0p675v0c_cworst_CCworst ssgnp0p675v125c_cworst_CCworst ssgnp0p675vn40c_rcworst_CCworst ssgnp0p675v0c_rcworst_CCworst ssgnp0p675v125c_rcworst_CCworst ssgnp0p675vn40c_cbest_CCbest ssgnp0p675v0c_cbest_CCbest ssgnp0p675v125c_cbest_CCbest ssgnp0p675vn40c_rcbest_CCbest ssgnp0p675v0c_rcbest_CCbest ssgnp0p675v125c_rcbest_CCbest tt0p75v25c_typical
++++++++++++++++++++++++++++++++++++++++++++++++++++++++

+++++++++++++++++++++++++++++++++++++++++++++
-I- Get metal stacks from vici
Foundry Metal Option: 15M_1X_h_1Xa_v_1Ya_h_5Y_vhvhv_2Yy2Yx2R
PHY Metal Option: 6M_1X_h_1Xa_v_1Ya_h_2Y_vh
+++++++++++++++++++++++++++++++++++++
END_VICI
   my (@expected_result) = split(/\n+/, $expected_script_output);
   my %test = (
       'test_name'       => 'd714-1.00a_EWHardened',
       'vici_url'        => 'http://vici/releasePageConstruct/index/id/24925/page_id/249',
       'expected_result' => [ @expected_result ],
   );
   return( %test );
}


#----------------------------------------------------------------------------------------------
# Test 3 - d862
#----------------------------------------------------------------------------------------------
sub d862_lpddr54_cuamd_tsmc6ff18(){

my $expected_script_output = <<'END_VICI';
-I- Opening the 'http://vici/releasePageConstruct/index/id/25748/page_id/914' url for checking content
-I- Get cell_names and version from vici
-I- ViCi information returned.
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++
diff : _ew : 2.00a
master : _ns : 2.00a
repeater cells library :  : 2.01a
se : _ew : 2.00a
sec : _ew : 2.00a
utility cells library :  : 2.01a
ctb :  : A-2020.02-BETA
firmware :  : A-2020.02-BETA
hspice/ibis views :  : 
installed_corekit :  : n/a
macro :  : 1.04a_amdsow2680
phyinit :  : A-2020.02-BETA
pub :  : 1.04a_amdsow2680
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-I- Done grabbing cell_names and version from ViCi
-I- Get pvt_corners from vici
++++++++++++++++++++++++++++++++++++++++++++++++++++++++
['tt', '0.75', '25', 'typical']
++++++++++++++++++++++++++++++++++++++++++++++++++++++++
Standard Product : PVT options : ff0p825vn40c_cbest_CCbest ff0p825v0c_cbest_CCbest ff0p825v125c_cbest_CCbest ff0p825vn40c_cworst_CCworst ff0p825v0c_cworst_CCworst ff0p825v125c_cworst_CCworst ff0p825vn40c_rcbest_CCbest ff0p825v0c_rcbest_CCbest ff0p825v125c_rcbest_CCbest ff0p825vn40c_rcworst_CCworst ff0p825v0c_rcworst_CCworst ff0p825v125c_rcworst_CCworst ff0p935vn40c_cbest_CCbest ff0p935v0c_cbest_CCbest ff0p935v125c_cbest_CCbest ff0p935vn40c_cworst_CCworst ff0p935v0c_cworst_CCworst ff0p935v125c_cworst_CCworst ff0p935vn40c_rcbest_CCbest ff0p935v0c_rcbest_CCbest ff0p935v125c_rcbest_CCbest ff0p935vn40c_rcworst_CCworst ff0p935v0c_rcworst_CCworst ff0p935v125c_rcworst_CCworst ss0p765vn40c_cbest_CCbest ss0p765v0c_cbest_CCbest ss0p765v125c_cbest_CCbest ss0p765vn40c_cworst_CCworst ss0p765v0c_cworst_CCworst ss0p765v125c_cworst_CCworst ss0p765vn40c_rcbest_CCbest ss0p765v0c_rcbest_CCbest ss0p765v125c_rcbest_CCbest ss0p765vn40c_rcworst_CCworst ss0p765v0c_rcworst_CCworst ss0p765v125c_rcworst_CCworst ss0p675vn40c_cbest_CCbest ss0p675v0c_cbest_CCbest ss0p675v125c_cbest_CCbest ss0p675vn40c_cworst_CCworst ss0p675v0c_cworst_CCworst ss0p675v125c_cworst_CCworst ss0p675vn40c_rcbest_CCbest ss0p675v0c_rcbest_CCbest ss0p675v125c_rcbest_CCbest ss0p675vn40c_rcworst_CCworst ss0p675v0c_rcworst_CCworst ss0p675v125c_rcworst_CCworst tt0p85v25c_typical tt0p75v25c_typical
++++++++++++++++++++++++++++++++++++++++++++++++++++++++

+++++++++++++++++++++++++++++++++++++++++++++
-I- Get metal stacks from vici
Foundry Metal Option: 13M_1X_h_1Xa_v_1Ya_h_5Y_vhvhv_2Yy2Z
PHY Metal Option: 6M_1X_h_1Xa_v_1Ya_h_2Y_vh
+++++++++++++++++++++++++++++++++++++
END_VICI

   my (@expected_result) = split(/\n+/, $expected_script_output);
   my %test = (
       'test_name'       => 'd862-2.00a',
       'vici_url'        => 'http://vici/releasePageConstruct/index/id/25748/page_id/914',
       'expected_result' => [ @expected_result ],
   );

   return( %test );
}

#----------------------------------------------------------------------------------------------
# Test 4 - d805 ... this test case triggers the use of a ViCi table index value not exercised
#     by the other tests. And, it exercises python regex manipulations of the PVT tables
#     not exercised by the other tests.
#----------------------------------------------------------------------------------------------
sub d805_ddr54_tsmc7ff18_plus18( ){

my $expected_script_output = <<'END_VICI';
-I- Opening the 'http://vici/releasePageConstruct/index/id/22250/page_id/185' url for checking content
-I- Get cell_names and version from vici
-I- ViCi information returned.
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++
acx4 : _ew : 0.95a
dbyte : _ew : 0.95a
decapvddq :  : 
io :  : 
master :  : 0.95a
pll :  : 
utility cells library :  : 1.00a
ctb :  : 
dml :  : 
firmware :  : 
hardened :  : 
hspice/ibis views :  : 
installed_corekit :  : 
macro :  : 
phyinit :  : 
pub :  : 0.95a
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-I- Done grabbing cell_names and version from ViCi
-I- Get pvt_corners from vici
'[\'FF\', \'0.935\', \'-40 / 0 / 125\', \'cworst_CCworst, rcworst_CCworst, cbest_CCbest, rcbest_CCbest\']',
'[\'SS\', \'0.675\', \'-40 / 0 / 125\', \'cworst_CCworst, rcworst_CCworst, cbest_CCbest, rcbest_CCbest\']',
'[\'TT\', \'0.85\', \'25\', \'RCtypical\']',
'[\'TT\', \'0.75\', \'25\', \'RCtypical\']',

++++++++++++++++++++++++++++++++++++++++++++++++++++++++
Standard Product : PVT options : ff0p935vn40c_cworst_CCworst ff0p935v0c_cworst_CCworst ff0p935v125c_cworst_CCworst ff0p935vn40c_rcworst_CCworst ff0p935v0c_rcworst_CCworst ff0p935v125c_rcworst_CCworst ff0p935vn40c_cbest_CCbest ff0p935v0c_cbest_CCbest ff0p935v125c_cbest_CCbest ff0p935vn40c_rcbest_CCbest ff0p935v0c_rcbest_CCbest ff0p935v125c_rcbest_CCbest ss0p675vn40c_cworst_CCworst ss0p675v0c_cworst_CCworst ss0p675v125c_cworst_CCworst ss0p675vn40c_rcworst_CCworst ss0p675v0c_rcworst_CCworst ss0p675v125c_rcworst_CCworst ss0p675vn40c_cbest_CCbest ss0p675v0c_cbest_CCbest ss0p675v125c_cbest_CCbest ss0p675vn40c_rcbest_CCbest ss0p675v0c_rcbest_CCbest ss0p675v125c_rcbest_CCbest tt0p85v25c_RCtypical tt0p75v25c_RCtypical
++++++++++++++++++++++++++++++++++++++++++++++++++++++++

+++++++++++++++++++++++++++++++++++++++++++++
-I- Get metal stacks from vici
Foundry Metal Option: 13M_1Xs_h_1Xa_v_1Ya_h_5Y_vhvhv_2Yy2Z 15M_1Xs_h_1Xa_v_1Ya_h_5Y_vhvhv_2Yy2Yx2R
PHY Metal Option: 8M_1Xs_h_1Xa_v_1Ya_h_4Y_vhvh 8M_1Xs_h_1Xa_v_1Ya_h_4Y_vhvh
+++++++++++++++++++++++++++++++++++++
END_VICI

   my (@expected_result) = split(/\n+/, $expected_script_output);
   my %test = (
       'test_name'       => 'd805-0.95a_tc',
       'vici_url'        => 'http://vici/releasePageConstruct/index/id/22250/page_id/185',
       'expected_result' => [ @expected_result ],
   );

   return( %test );
}

#----------------------------------------------------------------------------------------------
sub process_cmd_line_args(){

   my %options=();
   getopts("hd:", \%options);
   my $opt_d = $options{d}; # debug verbosity setting
   my $help  = $options{h};


   if ( $help || ( defined $opt_d && $opt_d !~ m/^\d*$/ ) ){  
      my $msg  = "USAGE:  $PROGRAM_NAME -v # -h \n";
         $msg .= "... add debug statments with -v #\n";
      iprint( $msg );
      exit;
   }   

   # decide whether to alter DEBUG variable
   # '-v' indicates DEBUG value ... set based on user input
   if( defined $opt_d && $opt_d =~ m/^\d*$/ ){  
      $DEBUG = $opt_d;
   }

}
