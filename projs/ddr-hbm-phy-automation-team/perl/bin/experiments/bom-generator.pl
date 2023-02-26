#!/depot/perl-5.14.2/bin/perl

#################################################################################
#
#  Name    : bom-generator.pl
#  Author  : Patrick Juliano
#  Date    : Jan 2019
#  Purpose : this takes generates the BOM file lists from config data stored here
#
#################################################################################
#
use strict;
use Data::Dumper;
use Getopt::Std;
use File::Basename qw( dirname );
use File::Spec::Functions qw( catfile );
use Cwd qw( abs_path );
use Carp qw(cluck confess croak);
use lib dirname(abs_path $0) . '/../../lib/';
use Util::CommonHeader;
use Util::Misc;
use Util::Messaging;


#----------------------------------#
our $PROGRAM_NAME = $0; 
#----------------------------------#
our $DEBUG = NONE;
#----------------------------------#

our $DIRNAME = dirname(abs_path $0);
our $PROGRAM_NAME = $0; 
our $AUTHOR_NAME  = 'Patrick Juliano'; 
our $VERSION      = '1.0';

my $href_globals = {
   'base_path' => "synopsys/dwc_hbm2e_phy_hard1_tsmc7ff18/1.00a-EW-Hardened",
	 'phyPrefix' => "dwc_hbmphy",
};
BEGIN { header(); } 
   Main();
END { footer(); }

########  YOUR CODE goes in Main  ##############
sub Main {
	 #utils__script_usage_statistics(abs_path($PROGRAM_NAME, $VERSION));
   utils__process_cmd_line_args();
   my $base_path = $href_globals->{base_path};
   my $phyPrefix = $href_globals->{phyPrefix};

   my $href_hbm_bom;
   my $href_macros_hbm;

      $href_macros_hbm = setup_hbm_CELL_definitions();
      $href_hbm_bom    = construct_BOM_for_HardMacros( $href_macros_hbm , $phyPrefix );
      $href_hbm_bom    = construct_BOM_for_Doc   ( $href_macros_hbm );
      $href_hbm_bom    = construct_BOM_for_Macro ( $href_macros_hbm );
      $href_hbm_bom    = construct_BOM_for_Pub   ( $href_macros_hbm );
      print Dumper $href_hbm_bom;
   my $aref_bom_files  = stream_bom_to_file_list ( $href_hbm_bom, $base_path );

   exit(0);
}
############    END Main    ####################
#
#
#
###############################################################################

###############################################################################
sub stream_bom_to_file_list($$){
   print_function_header();
   my $href_bom  = shift;
   my $base_path = shift;
   my $aref_bom_files;

   foreach my $cell ( keys %$href_bom ){
      my $path = $base_path . '/' .
                   $href_bom->{$cell}{'dirname'} .
                   $href_bom->{$cell}{'orientation'} . "/" .
                   $href_bom->{$cell}{'version'};
      $path =~ s/\/$//;  # strip off trailing '/' when $version is empty
      dprint( MEDIUM, "Streaming BOM for cell '$cell'\n" );
      dprint( MEDIUM, "Base Path is ... '$path'\n" );
         foreach my $view ( keys %{$href_bom->{$cell}{bom}} ){
            my $aref_view = $href_bom->{$cell}{bom}{$view};
            my $fname_target = "$path/$view";

            $Data::Dumper::Varname = "$cell...";
            dprint(MEDIUM, join "Streaming BOM ... '$cell/$view'\n;" , scalar(Dumper $aref_view) , "\n");
            dprint(MEDIUM, "$fname_target\n");
            if( defined $aref_view &&  $#$aref_view+1 > 0){
               foreach my $fname ( sort @$aref_view ){
                  print "$fname_target/$fname\n";
               }
            }else{
               # For cases where the 'view' is not an array of file names, 
               # assumption is that the 'view' is actually a filename itself.
               print "$fname_target\n";
            }
         }
   }

   $Data::Dumper::Varname = "VAR";
   return( $aref_bom_files );
}
#
###############################################################################
sub setup_hbm_CELL_definitions{
   print_function_header();
   my $mstack_phytop  = qw( 15M_1X_h_1Xa_v_1Ya_h_5Y_vhvhv_2Yy2Yx2R ) ;
   my $mstack_macros  = qw( 6M_1X_h_1Xa_v_1Ya_h_2Y_vh ) ;
   my $macro_orientation = "_ew";

   my $href_macros = {
	    'top' => {
			   'dirname'     => "hbmphy_top",
			   'name'        => "top",
			   'version'     => "1.00a",
			   'orientation' => $macro_orientation,
			   'mstack'      => $mstack_phytop,
      },
	    'aword' => {
			   'dirname'     => "awordx2",
			   'name'        => "awordx2",
			   'version'     => "1.12a",
			   'orientation' => $macro_orientation,
			   'mstack'      => $mstack_macros,
      },
	    'dword' => {
			   'dirname'     => "dword",
			   'name'        => "dword",
			   'version'     => "1.02a",
			   'orientation' => $macro_orientation,
			   'mstack'      => $mstack_macros,
      },
	    'midstack' => {
			   'dirname'     => "midstack",
			   'name'        => "midstack",
			   'version'     => "1.02a",
			   'orientation' => $macro_orientation,
			   'mstack'      => $mstack_macros,
      },
	    'master'  => {
			   'dirname'      => "master",
			   'name'         => "master",
			   'version'      => "1.02a",
			   'orientation'  => $macro_orientation,
			   'mstack'       => $mstack_macros,
      },
	    'decap'  => {
			   'dirname'     => "decapvddq",
			   'name'        => "decapvddq",
			   'version'     => "1.50a",
			   'orientation' => '',
			   'mstack'      => $mstack_macros,
      },
	 };

   return( $href_macros );
}

###############################################################################
sub construct_BOM_for_Macro($) {
   my $href_hbm_bom    = shift;

   print_function_header();
   my $cell_type = 'macro';
   $href_hbm_bom->{$cell_type} = {
			   'dirname'     => "macro",
			   'name'        => "macro",
			   'version'     => "1.11a",
			   'orientation' => "",
			   'mstack'      => "",
			   'process'     => "tsmc7ff18",
      };

   my $process = $href_hbm_bom->{$cell_type}{'process'};
   my $version = $href_hbm_bom->{$cell_type}{'version'};

###############################################################################
   $href_hbm_bom->{$cell_type}{'bom'} = {
         'constraints' => [
            "dwc_hbmphy_lib_info_${process}.tcl",
            "dwc_hbmphy_procs.tcl",
            "dwc_hbmphy_top_constr.tcl",
            "dwc_hbmphy_top_setup.tcl",
            "dwc_stdcell_lib_info_${process}.tcl",
            "dwc_hbmphy_top_cfg_setup.tcl",
            "dwc_hbmphy_top_bounds_ew.tcl",
            "dwc_hbmphy_top_bounds_ns.tcl",
            "dwc_hbmphy_top_pin_placement_ew.tcl",
            "dwc_hbmphy_top_pin_placement_ns.tcl",
            "dwc_hbmphy_top_floorplan_ew.tcl",
            "dwc_hbmphy_top_floorplan_ns.tcl",
         ],
         'example' => [
            "sta/dwc_hbmphy_top_sta.tcl",
            "syn/dwc_hbmphy_top_synth.tcl",
            "formality/dwc_hbmphy_rtl_vs_gate.tcl",
         ],
         'interface' => [
            "dwc_hbmphy_top_interface.v",
            "product_version.v",
         ],
         'ipxact' => [
            "dwc_hbmphy_top.xml",
         ],
         'rtl' => [
            "dwc_hbmphy_top.v",
            "dwc_hbmphy.v",
            "dwc_hbmphy_define.v",
            "dwc_hbmphy_channel.v",
            "dwc_hbmphy_cell_premap_${process}.v",
            "list.f",
         ],
         'sim' => [
            "files_release.f",
            "files_tb.f",
            "runtc",
         ],
         "readme_phy_top_${version}.txt" => [ ],
         'testbench' => [
            "bist_common.v",
            "cust_svt_hbm_agent_configuration.sv",
            "debug.v",
            "demo_bist.v",
            "demo_cmd_seq.v",
            "demo_csr.v",
            "demo_ddl_test.v",
            "demo_dfi.v",
            "demo_pll.v",
            "demo_vt_upd.v",
            "dfi_bfm.v",
            "dfi_mctl2phy.v ",
            "dictionary.v",
            "hbm_base_test.sv",
            "hbm_basic_env.sv",
            "hbm_channel.v",
            "hbm_tb.v",
            "hbmphy_dut_wrapper.v",
            "ieee1500.v",
            "initeng_preload.txt",
            "initeng_preload_seq.v",
            "initeng_preload_seq_pll_byp.v",
            "jtag_bfm.v",
            "system.v",
         ],
   };

   $Data::Dumper::Varname = "$cell_type...";
   dprint(HIGH, join  scalar(Dumper $href_hbm_bom) , "Adding '$cell_type' cell ... \n;" ,"\n");

   return( $href_hbm_bom );
}

###############################################################################
sub construct_BOM_for_Pub($) {
   my $href_hbm_bom    = shift;

   print_function_header();
   my $cell_type = 'pub';
   $href_hbm_bom->{$cell_type} = {
			   'dirname'     => "pub",
			   'name'        => "pub",
			   'version'     => "1.10a",
			   'orientation' => "",
			   'mstack'      => "",
			   'process'     => "tsmc7ff18",
      };

   $href_hbm_bom->{$cell_type}{'bom'} = {
      "interface"  => [ "dwc_hbmphy_pub_interface.v" ],
      "rtl"        => [ "dwc_hbmphy_pub.v" ],
   };


   $Data::Dumper::Varname = "$cell_type...";
   dprint(HIGH, join  scalar(Dumper $href_hbm_bom) , "Adding '$cell_type' cell ... \n" ,"\n");

   return( $href_hbm_bom );
}


###############################################################################
sub construct_BOM_for_Doc($) {
   my $href_hbm_bom    = shift;

   print_function_header();
   my $cell_type = 'doc';
   $href_hbm_bom->{$cell_type} = {
			   'dirname'     => "doc",
			   'name'        => "doc",
			   'version'     => "",
			   'orientation' => "",
			   'mstack'      => "",
			   'process'     => "tsmc7ff18",
      };

   my $process = $href_hbm_bom->{$cell_type}{'process'};

   my $version_top      = $href_hbm_bom->{top}{'version'};
   my $version_aword    = $href_hbm_bom->{aword}{'version'};
   my $version_dword    = $href_hbm_bom->{dword}{'version'};
   my $version_midstack = $href_hbm_bom->{midstack}{'version'};
   my $version_master   = $href_hbm_bom->{master}{'version'};
   my $version_pub      = $href_hbm_bom->{pub}{'version'};

   $href_hbm_bom->{$cell_type}{'bom'} = {
      "dwc_hbm2e_phy_ig.pdf"                  => [ ],
      "dwc_hbm2e_phy_pub_databook.pdf"        => [ ],
      "dwc_hbm2e_phy_quickstart.txt"          => [ ],
      "readme_hbm2e_phy_v${version_top}.txt"  => [ ],
      "readme_awordx2_v${version_aword}.txt"  => [ ],
      "readme_dword_v${version_dword}.txt"    => [ ],
      "readme_midstack_v${version_midstack}.txt"=> [ ],
      "readme_master_v${version_master}.txt"  => [ ],
      "readme_pub_v${version_pub}.txt"        => [ ],
      "readme_phy_top_v${version_top}.txt"    => [ ],
      "dwc_hbm2e_phy_${process}_databook.pdf" => [ ],
   };


   $Data::Dumper::Varname = "$cell_type...";
   dprint(HIGH, join  scalar(Dumper $href_hbm_bom) , "Adding '$cell_type' cell ... \n" ,"\n");

   return( $href_hbm_bom );
}


###############################################################################
sub construct_BOM_for_HardMacros($) {
   print_function_header();
   my $href_macros    = shift;
	 my $phyPrefix      = shift;

   my $href_bom       = $href_macros;

	 foreach my $macro_type ( keys %$href_macros ){
      dprint(MEDIUM, "Creating views for ... {$macro_type}\n");
      $href_bom->{$macro_type}{'bom'} = get_views( $phyPrefix, $macro_type,
                                          $href_macros->{$macro_type}{'name'} ,
                                          $href_macros->{$macro_type}{'orientation'} ,
                                          $href_macros->{$macro_type}{'mstack'},
                                        ); 
   }

   dprint(HIGH, Dumper $href_bom );

   # Modifications to basic structure
      ########################
      # VIEW = 'netlist'
      ########################
      # top level netlist format is SP not default of CDL
      my $type   = 'top'; my $view='netlist';
      ${$href_bom->{$type}{'bom'}{$view}}[0] =~ s/\.cdl$/\.sp/;
      $Data::Dumper::Varname = "$type...$view";
      dprint(HIGH, Dumper $href_bom->{$type}{'bom'}{$view} );

      ########################
      # VIEW = 'behavior'
      ########################
      # top only has 2 files rather than 5 files that each macro has 
      my $type   = 'top'; my $view='behavior';
      my $fname1 = "$href_macros->{$type}{'mstack'}/${phyPrefix}_$href_macros->{$type}{'name'}.v";
      my $fname2 = "$href_macros->{$type}{'mstack'}/${phyPrefix}_$href_macros->{$type}{'name'}_pg.v";
      $href_bom->{$type}{'bom'}{$view} = [ $fname1, $fname2 ];
      $Data::Dumper::Varname = "$type...$view";
      dprint(HIGH, Dumper $href_bom->{$type}{'bom'}{$view} );

      # decap only has 1 file
      my $type   = 'decap';
      my $fname = "$href_macros->{$type}{'mstack'}/${phyPrefix}_$href_macros->{$type}{'name'}.v";
      $href_bom->{$type}{'bom'}{$view} = [ $fname ];
      $Data::Dumper::Varname = "$type...$view";
      dprint(HIGH, Dumper $href_bom->{$type}{'bom'}{$view} );


      ########################
      # VIEW = 'rtl'
      ########################
      # top has 3 RTL files ... 
      my $type   = 'top';   my $view='rtl';
      my $fname1 = "${phyPrefix}_$href_macros->{$type}{'name'}$href_macros->{$type}{'orientation'}.v";
      my $fname2 = "${phyPrefix}_$href_macros->{$type}{'name'}$href_macros->{$type}{'orientation'}_pg.v";
      my $fname3 = "${phyPrefix}_$href_macros->{$type}{'name'}$href_macros->{$type}{'orientation'}_define.v";
      $href_bom->{$type}{'bom'}{$view} = [ $fname1, $fname2, $fname3 ];
      $Data::Dumper::Varname = "$type...$view";
      dprint(HIGH, Dumper $href_bom->{$type}{'bom'}{$view} );
      
      ########################
      # VIEW = 'timing'
      ########################
      # hardened PHY top has different corners than macros...see 'get_views'
      # decap doesn't have sdf files
      my $type   = 'decap';   my $view='timing';
      my @files;
      foreach my $fname (  @{ $href_bom->{$type}{'bom'}{$view} } ){
         if( $fname =~ m/\.sdf$/ ){ 
            dprint(HIGH, "$view : $type : pruning file '$fname'\n" );
            next;
         }else{
            push(@files, $fname );;
         }
      }
      $href_bom->{$type}{'bom'}{$view} = \@files;
         
      $Data::Dumper::Varname = "$type...$view";
      dprint(HIGH, Dumper $href_bom->{$type}{'bom'}{$view} );

   return( $href_bom );
   print_function_footer();
}

###############################################################################
sub get_views($$$$){
   print_function_header();
   my $phyPrefix  = shift;
   my $macro_type = shift;
   my $macro_name = shift;
   my $orientation= shift;
   my $mstack     = shift;

   my $href_views = {
			     'atpg' => [
					       "ctl/${phyPrefix}_${macro_name}${orientation}.ctl",
					       "rpt/${phyPrefix}_${macro_name}${orientation}_stuck.rpt",
					       "rpt/${phyPrefix}_${macro_name}${orientation}_atspeed.rpt",
					 ],
			     'behavior' => [
               "${mstack}/${phyPrefix}_${macro_name}${orientation}.v", 
               "${mstack}/${phyPrefix}_${macro_name}${orientation}_pg.v", 
               "${mstack}/vcs_compile.sh",
               "${mstack}/${phyPrefix}_library.v", 
               "${mstack}/${phyPrefix}_macro_library.v", 
					 ],
					 'gds' => [
               "${mstack}/${phyPrefix}_${macro_name}${orientation}.gds.gz", 
               "${mstack}/layerMap_${mstack}.txt", 
					 ],
					 'calibre' => [
					       "ant/ant_${phyPrefix}_${macro_name}${orientation}_${mstack}.rpt",
					       "ant/ant_${phyPrefix}_${macro_name}${orientation}_${mstack}.waive",
					       "drc/drc_${phyPrefix}_${macro_name}${orientation}_${mstack}.rpt",
					       "drc/drc_${phyPrefix}_${macro_name}${orientation}_${mstack}.waive",
					       "erc/erc_${phyPrefix}_${macro_name}${orientation}_${mstack}.rpt",
					       "erc/erc_${phyPrefix}_${macro_name}${orientation}_${mstack}.waive",
					       "lvs/lvs_${phyPrefix}_${macro_name}${orientation}_${mstack}.rpt",
					       "lvs/lvs_${phyPrefix}_${macro_name}${orientation}_${mstack}.waive",
					       "dfm/dfm_${phyPrefix}_${macro_name}${orientation}_${mstack}.rpt",
					       "dfm/dfm_${phyPrefix}_${macro_name}${orientation}_${mstack}.waive",
					         "tc/tc_${phyPrefix}_${macro_name}${orientation}_${mstack}.rpt",
					         "tc/tc_${phyPrefix}_${macro_name}${orientation}_${mstack}.waive",
					       "esd/esd_${phyPrefix}_${macro_name}${orientation}_${mstack}.rpt",
					       "esd/esd_${phyPrefix}_${macro_name}${orientation}_${mstack}.waive",
					       "pad/pad_${phyPrefix}_${macro_name}${orientation}_${mstack}.rpt",
					       "pad/pad_${phyPrefix}_${macro_name}${orientation}_${mstack}.waive",
           ],
					 'icv' => [
					       "ant/ant_${phyPrefix}_${macro_name}${orientation}_${mstack}.rpt",
					       "ant/ant_${phyPrefix}_${macro_name}${orientation}_${mstack}.waive",
					       "drc/drc_${phyPrefix}_${macro_name}${orientation}_${mstack}.rpt",
					       "drc/drc_${phyPrefix}_${macro_name}${orientation}_${mstack}.waive",
					       "erc/erc_${phyPrefix}_${macro_name}${orientation}_${mstack}.rpt",
					       "erc/erc_${phyPrefix}_${macro_name}${orientation}_${mstack}.waive",
					       "lvs/lvs_${phyPrefix}_${macro_name}${orientation}_${mstack}.rpt",
					       "lvs/lvs_${phyPrefix}_${macro_name}${orientation}_${mstack}.waive",
					       "dfm/dfm_${phyPrefix}_${macro_name}${orientation}_${mstack}.rpt",
					       "dfm/dfm_${phyPrefix}_${macro_name}${orientation}_${mstack}.waive",
					       "esd/esd_${phyPrefix}_${macro_name}${orientation}_${mstack}.rpt",
					       "esd/esd_${phyPrefix}_${macro_name}${orientation}_${mstack}.waive",
					       "pad/pad_${phyPrefix}_${macro_name}${orientation}_${mstack}.rpt",
					       "pad/pad_${phyPrefix}_${macro_name}${orientation}_${mstack}.waive",
					 ],
					 'lef' => [
								  "${mstack}/${phyPrefix}_${macro_name}${orientation}.lef",
								  "${mstack}/${phyPrefix}_${macro_name}${orientation}_merged.lef",
							],
					 'netlist' => [
					        "${mstack}/${phyPrefix}_${macro_name}${orientation}.cdl",
					 ],
					 'rtl' => [
								  "${phyPrefix}_${macro_name}.v",   #  No orientation in the RTL file name
							],
					 'timing' => [
					     # insert a coderf to ViCi datamining
					        "${mstack}/lib/${phyPrefix}_${macro_name}${orientation}_\@{pvtcorners}.db",
					        "${mstack}/lib/${phyPrefix}_${macro_name}${orientation}_\@{pvtcorners}.lib",
					        "${mstack}/lib_pg/${phyPrefix}_${macro_name}${orientation}_\@{pvtcorners}_pg.db",
					        "${mstack}/lib_pg/${phyPrefix}_${macro_name}${orientation}_\@{pvtcorners}_pg.lib",
					        "${mstack}/sdf/${phyPrefix}_${macro_name}${orientation}_\@{pvtcorners}.sdf",
					 ],
	 };

   $href_views->{'calibre'}   = [];
   $href_views->{'ibis'}      = setup_views__ibis     ( $macro_type );
   $href_views->{'interface'} = setup_views__interface( $macro_type , $macro_name, $orientation, $phyPrefix );
   $href_views->{'hspice'}    = setup_views__hspice   ( $macro_type , $mstack );
   $href_views->{'upf'}       = setup_views__upf      ( $macro_type , $macro_name, $phyPrefix );
   $href_views->{'waveforms'} = setup_views__waveforms( $macro_type , $macro_name );
   # hardened PHY top has different corners than macros...
   if( $macro_type eq 'top' ){
      $href_views->{timing}   = get_pvtcorners__phytop( $href_views->{timing} );
   }elsif( $macro_type eq 'decap' ){
      $href_views->{timing}   = get_pvtcorners__decap( $href_views->{timing} );
   }else{
      $href_views->{timing}   = get_pvtcorners_from_vici( $href_views->{timing} );

   }

   return( $href_views );
}

###############################################################################
##  DECAP has different corners and names than the macros ... need a customization for the timing view.
sub get_pvtcorners__decap($){
   my $aref_timing = shift;

   my @timing_files;
   my @pvt_list = qw(
      ff0p935v0c ff0p935v125c ff0p935vn40c
      ff0p825v0c ff0p825v125c ff0p825vn40c
      ss0p675v0c ss0p675v125c ss0p675vn40c
      ss0p765v0c ss0p765v125c ss0p765vn40c
   );
   my @custom_pvtrc_list = qw(
      tt0p75v25c
      tt0p85v25c
   );
   my @corners_list;

   #print Dumper $aref_timing;
   #print scalar @{$aref_timing};
   foreach my $custom_pvtrc ( @custom_pvtrc_list ){
      push( @corners_list, $custom_pvtrc );
   }

   foreach my $pvt ( @pvt_list ){
         push( @corners_list, "${pvt}" );
   }
   foreach my $corner ( @corners_list ){
      my @files =  map { s/\@\{pvtcorners\}/$corner/r }  @{ $aref_timing } ;
      push(@timing_files,  @files);
   }
   #print Dumper \@timing_files;
   #print  scalar @timing_files;

   return( \@timing_files );
}

###############################################################################
##  PHY top has different corners and names than the macros ... need a customization for the timing view.
sub get_pvtcorners__phytop($){
   my $aref_timing = shift;

   my @timing_files;
   my @rc_list = qw(
       cbest_CCbest  cworst_CCworst
      rcbest_CCbest rcworst_CCworst 
   );
   my @pvt_list = qw(
      ffgnp0p825v0c ffgnp0p825v125c ffgnp0p825vn40c
      ssgnp0p675v0c ssgnp0p675v125c ssgnp0p675vn40c
   );
   my @custom_pvtrc_list = qw(
      tt0p75v25c_typical 
   );
   my @corners_list;

   #print Dumper $aref_timing;
   #print scalar @{$aref_timing};
   foreach my $custom_pvtrc ( @custom_pvtrc_list ){
      push( @corners_list, $custom_pvtrc );
   }

   foreach my $pvt ( @pvt_list ){
      foreach my $rc ( @rc_list ){
         push( @corners_list, "${pvt}_$rc" );
      }
   }
   foreach my $corner ( @corners_list ){
      my @files =  map { s/\@\{pvtcorners\}/$corner/r }  @{ $aref_timing } ;
      push(@timing_files,  @files);
   }
   #print Dumper \@timing_files;
   #print  scalar @timing_files;

   return( \@timing_files );
}


###############################################################################
sub get_pvtcorners_from_vici($){
   my $aref_timing = shift;

   my @timing_files;
   my @rc_list = qw(
       cbest_CCbest  cworst_CCworst
      rcbest_CCbest rcworst_CCworst 
   );
   my @pvt_list = qw(
      ff0p825v0c ff0p825v125c ff0p825vn40c
      ff0p935v0c ff0p935v125c ff0p935vn40c
      ss0p675v0c ss0p675v125c ss0p675vn40c
      ss0p765v0c ss0p765v125c ss0p765vn40c
   );
   my @custom_pvtrc_list = qw(
      tt0p75v25c_typical
      tt0p85v25c_typical 
   );
   my @corners_list;

   #print Dumper $aref_timing;
   #print scalar @{$aref_timing};
   foreach my $custom_pvtrc ( @custom_pvtrc_list ){
      push( @corners_list, $custom_pvtrc );
   }

   foreach my $pvt ( @pvt_list ){
      foreach my $rc ( @rc_list ){
         push( @corners_list, "${pvt}_$rc" );
      }
   }
   foreach my $corner ( @corners_list ){
      my @files =  map { s/\@\{pvtcorners\}/$corner/r }  @{ $aref_timing } ;
      push(@timing_files,  @files);
   }
   #print Dumper \@timing_files;
   #print  scalar @timing_files;

   return( \@timing_files );
}
###############################################################################
sub deleteme{
   my $href_views_optional = {
			     'atpg' => [
					       #"ctl/${phyPrefix}_${macro_name}.ctl",
					       #"rpt/${phyPrefix}_${macro_name}${orientation}_stuck.rpt",
					       #"rpt/${phyPrefix}_${macro_name}${orientation}_atspeed.rpt",
					        "tetramax/README",     # top, aword, dword, master =>not mid/decap  
					        "tetramax/bash.tcsh",  # top, aword, dword, master =>not mid/decap  
					       #"tetramax/atspeed_atpg/${phyPrefix}_${macro_name}${orientation}_atspeed.rpt", # top, aword, dword, master =>not mid/decap
					       #"tetramax/atspeed_atpg/${phyPrefix}_${macro_name}${orientation}_stuck.rpt",   # top, aword, dword, master =>not mid/decap
					        "tetramax/stuck_atpg/atpg_files.list",
					        "tetramax/stuck_atpg/force.ucli",
					        "tetramax/stuck_atpg/sim_dump.v",

                  "tetramax/stuck_atpg/run_capture_pat_sim",   #top aword dword master => not mid/decap
                  "tetramax/stuck_atpg/run_chain_pat_sim",     #top aword dword master => not mid/decap
                  "tetramax/stuck_atpg/run_stuck_atpg",        #top aword dword master => not mid/decap
                  "tetramax/atspeed_atpg/run_all_pat_sim",       #top aword dword master => not mid/decap
                  "tetramax/atspeed_atpg/run_atspeed_atpg",      #top aword dword master => not mid/decap

					        "tetramax/atspeed_atpg/sims_files.list",     #top aword dword master => not mid/decap
					        "tetramax/stuck_atpg/sims_files.list",       #top aword dword master => not mid/decap

					        "tetramax/library/atpg_models/dwc_hbmphy_atpg_define.v",
					        "tetramax/library/atpg_models/atpg_primitives.v",
					        "tetramax/library/setup_hold_sdfs",
#if master
					        "tetramax/library/common_models/dwc_ddrphy_pll.v",
					        "tetramax/library/common_models/dwc_ddrphy_por.v",
					        "tetramax/library/common_models/dwc_ddrphy_vrefglobal.v",
					        "tetramax/library/common_models/dwc_hbmphy_clktx.v",
					        "tetramax/library/common_models/dwc_hbmphy_vddqls.v",
#if aword
#if dword
					        "tetramax/library/common_models/dwc_hbmphy_clkbuf.v",
					        "tetramax/library/common_models/dwc_hbmphy_clkbuf1.v",
					        "tetramax/library/common_models/dwc_hbmphy_clkrpt1.v",
					        "tetramax/library/common_models/dwc_hbmphy_clkrx.v",
					        "tetramax/library/common_models/dwc_hbmphy_lcdl.v",
					        "tetramax/library/common_models/dwc_hbmphy_nsbridgedw.v",
					        "tetramax/library/common_models/dwc_hbmphy_vddqls.v",
#if top
					        "tetramax/library/common_models/dwc_hbmphy_pll.v",
					        "tetramax/library/common_models/dwc_hbmphy_por.v",
					        "tetramax/library/common_models/dwc_hbmphy_vrefglobal.v",
					        "tetramax/library/common_models/dwc_hbmphy_clkbuf.v",
					        "tetramax/library/common_models/dwc_hbmphy_clkbuf1.v",
					        "tetramax/library/common_models/dwc_hbmphy_clkrpt.v",
					        "tetramax/library/common_models/dwc_hbmphy_clkrpt1.v",
					        "tetramax/library/common_models/dwc_hbmphy_clkrx.v",
					        "tetramax/library/common_models/dwc_hbmphy_clktx.v",
					        "tetramax/library/common_models/dwc_hbmphy_lcdl.v",
					        "tetramax/library/common_models/dwc_hbmphy_nsbridgedw.v",
					        "tetramax/library/common_models/dwc_hbmphy_rxcmos.v",
					        "tetramax/library/common_models/dwc_hbmphy_vddqls.v",

					        "tetramax/library/atpg_models/dwc_hbmphy_rxdq.v",
					        "tetramax/library/atpg_models/dwc_hbmphy_rxdqs.v",
					        "tetramax/library/atpg_models/dwc_hbmphy_tx.v",

					        "tetramax/netlist/atpg_models/dwc_hbmphy_awordx2_ew.v",
					        "tetramax/netlist/atpg_models/dwc_hbmphy_dword_ew.v",
					        "tetramax/netlist/atpg_models/dwc_hbmphy_masteer_ew.v",
					        "tetramax/netlist/atpg_models/dwc_hbmphy_midstack_ew.v",
					        "tetramax/netlist/atpg_models/dwc_hbmphy_top_ew.v",

					        "tetramax/netlist/sim_models/dwc_hbmphy_awordx2_ew.v",
					        "tetramax/netlist/sim_models/dwc_hbmphy_dword_ew.v",
					        "tetramax/netlist/sim_models/dwc_hbmphy_masteer_ew.v",
					        "tetramax/netlist/sim_models/dwc_hbmphy_midstack_ew.v",
					        "tetramax/netlist/sim_models/dwc_hbmphy_top_ew.v",

#if midstack, only 
					        "tetramax/netlist/atpg_models/dwc_hbmphy_midstack_ew.v",
					        "tetramax/netlist/atpg_models/dwc_hbmphy_midstack_ew.v",
#if decapvddq, NOTHING 

					 ],
			     'example' => [ 'N/A'], # top-only, not in BOM
			     'include' => [ 'N/A'], # top-only, not in BOM
			},
};

###############################################################################
sub setup_views__hspice($$){
   print_function_header();
   my $type        = shift;
   my $metal_stack = shift;
   my $aref;

   if( $type eq 'aword' || $type eq 'midstack' ){ 
       $aref = [ 
           'dwc_hbmphy_tx.enc_xtsrccpcc', 'dwc_hbmphy_rxcmos.enc_xtsrccpcc',
           'tb_dwc_hbmphy_tx.sp', 'tb_dwc_hbmphy_rxcmos.sp',
           'README_tx.txt', 'README_rxcmos.txt'
       ];

   }
   if( $type eq 'dword' ){ 
       $aref = [ 
           'dwc_hbmphy_tx.enc_xtsrccpcc', 'dwc_hbmphy_rxdq.enc_xtsrccpcc', 'dwc_hbmphy_rxdqs.enc_xtsrccpcc',
           'tb_dwc_hbmphy_tx.sp', 'tb_dwc_hbmphy_rxdq.sp','tb_dwc_hbmphy_rxdqs.sp',
           'README_tx.txt', 'README_rxdq.txt', 'README_rxdqs.txt'
       ];
   }
   dprint( SUPER, join " ", "View => " , scalar(Dumper $aref), "\n" );
   map { s/^/$metal_stack\// } @{$aref};
   return( $aref );
}

###############################################################################
sub setup_views__ibis($){
   print_function_header();
   my $type = shift;
   my $aref;

   if( $type eq 'aword' || $type eq 'midstack' ){ 
       $aref = [ "non_clipped/dwc_hbmphy_txrxcmos_ew_non_clipped.ibs", "ibis_summary.txt" ]
   }
   if( $type eq 'dword' ){ 
       $aref = [ "non_clipped/dwc_hbmphy_txrxdq_ew_non_clipped.ibs", "ibis_summary.txt" ]
   }
   dprint( SUPER, join " ", "View => " , scalar(Dumper $aref), "\n" );
   return( $aref );
}

###############################################################################
sub setup_views__interface($$$$){
   print_function_header();
   my $type        = shift;
   my $macro_name  = shift;
   my $orientation = shift;
   my $phyPrefix   = shift;

   my @files;

   if( $type =~ m/^(a|d)word|master|midstack|decap$/ ){
       push(@files, "${phyPrefix}_${macro_name}${orientation}_interface.v" );
   }
   return( \@files );
   if( $type =~ m/^midstack|dword$/ ){
       push(@files, "ibis_summary.txt" );
   }
   if( $type eq 'aword' || $type eq 'midstack' ){ 
       push(@files, "non_clipped/dwc_hbmphy_txrxcmos_ew_non_clipped.ibs" );
   }
   if( $type eq 'dword' ){ 
       push(@files, "non_clipped/dwc_hbmphy_txrxdq_ew_non_clipped.ibs" );
   }
   dprint( SUPER, join " ", "View => " , scalar(Dumper \@files), "\n" );
   return( \@files );
}

###############################################################################
sub setup_views__upf($$$){
   print_function_header();
   my $type        = shift;
   my $macro_name  = shift;
   my $phyPrefix   = shift;

   my $aref;

   if( $type eq 'top' ){
       $aref = [ 
          "${phyPrefix}_$macro_name.upf"
       ];

   }
   dprint( SUPER, join " ", "View => " , scalar(Dumper $aref), "\n" );
   return( $aref );
}

###############################################################################
sub setup_views__waveforms($$$){
   print_function_header();
   my $type       = shift;
   my $macro_name = shift;
   my $aref;

   if( $type eq 'aword' ){
       $aref = [ 
           "${macro_name}_burst_ivdd_ff0p7875v125c.pwl",
           "${macro_name}_burst_ivddq_ff1p272v125c.pwl",
           "README_pwl.txt",
       ];

   }
   if( $type eq 'dword' ){ 
       $aref = [ 
           "${macro_name}_write_burst_ivddq_ff1p272v125c.pwl",
           "${macro_name}_write_burst_ivdd_ff0p7875v125c.pwl",
           "${macro_name}_read_burst_ivddq_ff1p272v125c.pwl",
           "${macro_name}_read_burst_ivdd_ff0p7875v125c.pwl",
           "README_pwl.txt",
       ];
   }
   dprint( SUPER, join " ", "View => " , scalar(Dumper $aref), "\n" );
   return( $aref );
}

