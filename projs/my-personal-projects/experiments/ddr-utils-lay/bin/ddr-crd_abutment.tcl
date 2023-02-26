#!/depot/tcl8.6.6/bin/tclsh

package require try         ;# Tcllib.
package require cmdline 1.5 ;# First version with proper error-codes.
package require fileutil

set DEBUG      0
set VERBOSITY  0
set STDOUT_LOG ""
set AUTHOR "Manmit Muker (mmuker)"
set RealBin [file dirname [file normalize [info script]] ]
set RealScript [file tail [file normalize [info script]] ]

# Declare cmdline opt vars here, so they are global
set opt_fast ""
set opt_test ""
set opt_help ""
set opt_project ""

lappend auto_path "$RealBin/../lib/tcl"
package require Messaging 1.0
namespace import ::Messaging::*

header

# Revision history:
set Script_Version 2022.09
# 2022.09 - Further OASIS support enhancements in conjunction with upcoming msip_cd_pv updates.
#   -DDR DA WG script enhancements added.
#   -Updated PERC_11M_dwc_ddrphy_dbyte_cornerclamp floorplan as per LPDDR54 CRD ver1.13
#   -Updated floorplans as per DDR5/LPDDR5X CRD review ver0.9 (//depot/products/lpddr5x_ddr5_phy/crd/_4review/DDR5_LPDDR5X_Construction_Requirements_Document.docx#34).
#   -Added fixes for tsmc16ffc18 standard cells.
#   -Fixed ICV PERC CD report names.
#   -Added "./" to all paths for exec commands related to running generated scripts, at DI's request.
# 2022.08-1 - Fixes for tsmc16ffc18 standard cells for compatibility with newer ICC2 versions.
# 2022.08 - Standard Cell Boundary and Abutment Standard Cell Boundary testcases are now created as boundary_<macro>_stdcell and boundary_<testcase>_stdcell to match with CRDs.
#   -Added support for tsmc3eff standard cells.
#   -Updated ICC2 version to 2022.03-SP3.
#   -Added support for DRC error limit through drc_error_limit parameter.
# 2022.07-1 - Addition of LPDDR54 corner clamp floorplans from CRD v1.12.
# 2022.07 - Removed testcase floorplans to a separate crd_abutment_floorplans.tcl file. This file must be in the same directory as the crd_abutment.tcl script file.
#           Note that crd_abutment.tcl no longer needs to be copied to working directory - it can be run from its published location. crd_abutment_parameters is the only file required in working directory.
#   -Updated tool versions: tclsh 8.6.6, ICC2 2022.03-SP2, ICVWB 2022.03-SP1 and msip_cd_pv 2022.05.
#   -Updated output file structure to match CKT P4 release structure.
#   -Added <pv_type>_prefix parameters to support alternate PV types.
#   -Added partial support for layout output in OASIS format. Note that there are still too many issues to recommend using OASIS.
#   -Replaced virtual_connect parameter with virtual_connect_icv and virtual_connect_calibre to support the different settings used by the tools.
# 2022.05-2 - Adding usage statistics monitor. (wadhawan)
# 2022.05-1 - Added DDR5 testcases for CRD ver0.7.
#   -Added CDL to pvbatch call for PERCCNOD_ICV due to new PERCCNOD flow requiring CDL.
# 2022.05 - Updated LPDDR5X testcases for CRD ver0.7.
#   -Changed ICVWB to now stop on errors.
# 2022.04-2 - Fixes to tsmc12ffc18 standard cell support related to layer map.
# 2022.04-1 - Fixes to tsmc5ff12 standard cell support.
#   -Setting version of ICC2, ICVWB and msip_cd_pv tools to support result reproducibility. These will get updated with future script versions.
# 2022.04 - Script modified to uniquify all GDS files specified in parameters file if uniquify_input_gds is enabled.
#   -Script modified to not use macros array variable.
#   -Fixes to tsmc5ff12 standard cell support.
# 2022.03-4 - Fixes to support tsmc12ffc18 standard cells.
# 2022.03-3 - Support for Perforce paths with revision # for CDL, DEF, GDS and LEF collaterals.
#   -Addition of log files for each testcase called <testcase>.log.
#   -Addition of parameter file contents to log files.
# 2022.03-2 - Fixes to support gf12lpp18 standard cells.
#   -Removed FOUNDRY_DEFAULT value from virtual_connect parameter in parameters file template as some nodes don't report text opens by foundry default.
# 2022.03-1 - Addition of stdcell_manual_kpt_<macro/testcase> parameters to add manual standard cell keepouts to [Abutment] Standard Cell Boundary and Standard Cell Fill testcases.
#   -Addition of script log, crd_abutment.log, generation.
# 2022.03 - Added abutment parameters to enable generation of boundary with upsizing.
#   -For [Abutment] Standard Cell Boundary testcases, signal pin names for spare cells are now uniquified in order to eliminate LVS opens.
#   -For [Abutment] Standard Cell Boundary testcases, macro is now placed at testbench origin.
#   -For Standard Cell Fill testcases, added pin labels at top level.
# 2022.02 - Added LPDDR5X abutment testcases.
# 2022.01 - Added stdcell_inner_kpt_* parameters to specify keepout from top level boundary in Standard Cell Fill testcases.
# 2021.12-1 - Added support for Standard Cell Fill testcases with the testcases_stdcell_fill parameter.
# 2021.12 - Added CDL uniquification with uniquify_input_cdl and uniquify_input_cdl_filter_file parameters. Only applies to Physical Verification Only and Wrapper testcases.
# 2021.11 - Complete set of LPDDR54 CRD abutment and boundary testcases added or updated.
#   -Fix to Generate_Stdcell_Ring proc to use terminal boundary for text origin coordinate instead of bbox as bbox coordinate may not fall within non-rectangular pin shape.
# 2021.09 - Renamed testcases parameter to testcases_abutment for clarity.
#   -Added support for abutment standard cell boundary testcases, where macros are first abutted prior to standard cell ring insertion. Specified with testcases_abutment_stdcell parameter.
#    Testcases are generated with the name stdcell_ring_<testcase>.
#   -Added support for rectilinear boundaries in standard cell boundary testcases. Changed generated testcase name to stdcell_ring_<macro>.
#   -Script can now generate LEF for standard cell boundary testcases by setting the generate_lef parameter to 1. Note that size-only LEFs are generated - no pin information is generated.
#   -Re-introduced boundary_top* parameters for rectilinear boundaries where double stdcell row heights are not followed for each boundary segment.
#   -Added support for abutment wrapper testcases where macros are first abutted prior to insertion as a subcell into wrapper. Wrapper cells should be named as *wrapper_<testcase> and supplied to the new testcases_abutment_wrapper parameter.
#   -Updated to use ICVWB instead of ICWBEV.
#   -Added LPDDR54 standard cell boundary and PERC testcases. 
# 2021.08-1 - Links to the physical verification report files are now created in the script's work directory instead of copies of the files.
# 2021.08 - Updated UDE3/CC log file structure for compatibility with new UDE3. 
#   -Stdcell NDM and macro LEFs are now required for stdcell boundary testcases.
#   -Stdcell boundary testcases are now generated with the name "boundary_stdcell_<macro>" for macros listed in the testcases_stdcell parameter.
#   -TSMC5-specific fixes for stdcell boundary testcases.
#   -Added testcases_wrapper parameter for *wrapper_<macro> testcases where script will add <macro> as subcell to *wrapper_<macro>, then run PV.
#   -Added generate_cdl parameter to enable CDL generation for *wrapper_<macro> testcases.
#   -Added testcases_pv_only parameter. Cells listed here will have PV run on them with the provided GDS and CDL.
#   -Added support for testcases_utility_* parameters for utility cell/block abutment checking. See documentation for details on how to use.
#   -Added support for FEOL and BEOL fill during DRC with drc_feol_fill and drc_beol_fill parameters.
#   -PV result files are now copied to the work directory rather than within each testcase directory.
#   -Added "-runnohalt" to ICWB execution to bypass errors that occur when the same GDS is referenced again through "layout reference add".
#   -Added additional power supplies to avoid uniquifying pin names.
#   -Added support for LPDDR5xm testcases with applicable parameters.
#   -Added support for HM+VDD clamp testcases for PERC, with applicable parameters.
#   -ICC2 flows now use scale_factor.
#   -Script now continues to next testcase while PV jobs are executing. PV jobs are run in parallel.
#   -PV parameters modified for specifying ICV or Calibre for DRC/LVS jobs.
#   -Added stdcell_drive_strength parameter to specify version of INV/BUF/ND2/NR2 cells to add.
#   -Added stdcell_tap parameter to specify tap cell to use. Required as some stdcell libraries include several tap options.
#   -Added stdcell_kpt_* parameters to specify stdcell keepout region around macro.
#   -Removed following parameters:
#     -boundary_top* - These boundary cells not required due to even number of stdcell rows and non-flipped first row.
#     -calex_site - only site 3 exists now.
#     -stdcell_lef - no longer used in stdcell boundary testcases.
#     -uu_per_dbu - it is now calculated by the script.
# 2020.08-1 - Modified to use techlib from stdcell NDM if given. Added int22ffl18 pin text support.
# 2020.08 - Fixed boundary_master_stdcell_ew/ns testcase macros references. Added support for existing stdcell NDM to bypass stdcell library creation.
# 2020.01-1 - Added support for standard cell boundary testcases. Added support for specifying virtual connect value for LVS.
# 2020.01 - Added support for Calex extra arguments.
# 2019.12 - Added LPDDR54 support. Added uu_per_dbu parameter for correct testcase GDS creation.
# 2019.11 - Floorplan bug fixes.
# 2019.10-1 - Added support for hard macro specific utility cell testcases. Covercell insertion is now only enabled for hard macros, not utility cells.
# 2019.10 - PERC_LDL now enabled. msip_cd_pv module can be set to a specific version.
# 2019.09-1 - Script now determines cell sizes through boundary_layer parameter, eliminating need for size parameters. Added parameters for running DRC, LVS and PERC_LDL (not currently enabled). Parameter added for signal pin uniquification.
# 2019.09 - Added support for no pin text layers defined.
# 2019.08 - Initial release.

##### Adding usage statistics ######
# 2022-05-10 12:45:02
# Editor: wadhawan
# Stats: https://kibana/kibana/s/tesla/app/dashboards#/view/cc72dfe0-013f-11eb-a373-d7f01031644f?_g=(filters:!(),refreshInterval:(pause:!t,value:0),time:(from:now-3M,to:now))

proc utils__script_usage_statistics {toolname version} {
    set prefix "ddr-da-alpha_common-"
    set reporter "/remote/cad-rep/msip/tools/bin/msip_get_usage_info"
    set cmd ""
    set script_dirname [file dirname [file normalize [info script]]]
    append cmd "$reporter --tool_name  \"${prefix}${toolname}\" "
    append cmd "--stage main --category ude_ext_1 "
    append cmd "--tool_path \"$script_dirname\" --tool_version \"$version\""

    exec sh -c $cmd
}

set script_name [file tail [file rootname [file normalize [info script]]]]
utils__script_usage_statistics $script_name "2022ww38"

# Names of hard macros for regex matching.
set hard_macros "^dwc_ddrphyacx4_top_ew\$|^dwc_ddrphyacx4_top_ns\$|^dwc_ddrphydbyte_top_ew\$|^dwc_ddrphydbyte_top_ns\$|^dwc_ddrphymaster_top\$|^dwc_lpddr5xmphyacx2_top_ew\$|^dwc_lpddr5xmphyckx2_top_ew\$|^dwc_lpddr5xmphycmosx2_top_ew\$|^dwc_lpddr5xmphydx4_top_ew\$|^dwc_lpddr5xmphydx5_top_ew\$|^dwc_lpddr5xmphymaster_top_ew\$|^dwc_lpddr5xmphyzcal_top_ew\$"

# Names of power supplies for regex matching.
set power_supplies "^(VAA|VDD|VDDQ|VDDQ_VDD2H|VDDQLP|VSH|VSS)\$"

# Utility procs

# 2022.03-2 - Generate boundary cells in ICC2.
proc Generate_Boundary_Cells {mainParameters fid} {
  upvar $mainParameters parameters
  
  # 2022.08 - Not required for tsmc3eff as it uses set_tap_boundary_wall_cell_rules instead.
  if {![regexp {tsmc3eff} $parameters(project_name)]} {
    puts $fid "set_boundary_cell_rules -left_boundary_cell $parameters(boundary_left) -right_boundary_cell $parameters(boundary_right) -bottom_boundary_cells \"$parameters(boundary_bottom)\" -bottom_left_outside_corner_cell $parameters(boundary_bottom_left_outside_corner) -bottom_right_outside_corner_cell $parameters(boundary_bottom_right_outside_corner) -bottom_left_inside_corner_cells $parameters(boundary_bottom_left_inside_corner) -bottom_right_inside_corner_cells $parameters(boundary_bottom_right_inside_corner)" 
  }
  if {$parameters(boundary_bottom_left_inside_horizontal_abutment) != ""} {
    puts $fid "set_boundary_cell_rules -bottom_left_inside_horizontal_abutment_cells $parameters(boundary_bottom_left_inside_horizontal_abutment) -bottom_right_inside_horizontal_abutment_cells $parameters(boundary_bottom_right_inside_horizontal_abutment)"
  }
  if {$parameters(boundary_top) != ""} {
    puts $fid "set_boundary_cell_rules -top_boundary_cells \"$parameters(boundary_top)\" -top_left_outside_corner_cell $parameters(boundary_top_left_outside_corner) -top_right_outside_corner_cell $parameters(boundary_top_right_outside_corner) -top_left_inside_corner_cells $parameters(boundary_top_left_inside_corner) -top_right_inside_corner_cells $parameters(boundary_top_right_inside_corner)"
  }
  if {[regexp {tsmc5ff12|tsmc5ffp12} $parameters(project_name)]} {
    puts $fid "set_boundary_cell_rules -mirror_left_inside_corner_cell -mirror_right_inside_corner_cell -mirror_right_inside_horizontal_abutment_cell -mirror_left_inside_horizontal_abutment_cell"
  }
  # 2022.03-4 - Rule also required for tsmc12ffc18.
  if {[regexp {tsmc12ffc18|tsmc16ffc18} $parameters(project_name)]} {
    puts $fid "set_boundary_cell_rules -mirror_right_outside_corner_cell"
  }
  # 2022.03-2 - Required for gf12lpp18.
  if {[regexp {gf12lpp18} $parameters(project_name)]} {
    puts $fid "set_boundary_cell_rules -mirror_left_boundary_cell -mirror_left_outside_corner_cell -mirror_right_inside_corner_cell"
  }
  # 2022.03-4 - Workaround also required for tsmc12ffc18.
  if {[regexp {tsmc5ff12|tsmc5ffp12|tsmc12ffc18|tsmc16ffc18} $parameters(project_name)]} {
    puts $fid "set_app_options -name place.legalize.enable_advanced_rules -value false"
  }
  
  if {[regexp {tsmc3eff} $parameters(project_name)]} {
    puts $fid "set_tap_boundary_wall_cell_rules \
      -tap_distance $parameters(tap_distance) \
      -incorner_keepout 0.54 \
      -wall_distance {1.008 95.76} \
      -p_tap $parameters(stdcell_tap_boundary_wall_cell_p_tap) \
      -n_tap $parameters(stdcell_tap_boundary_wall_cell_n_tap) \
      -p_tb_wall $parameters(stdcell_tap_boundary_wall_cell_p_tb_wall) \
      -n_tb_wall $parameters(stdcell_tap_boundary_wall_cell_n_tb_wall) \
      -p_fill_wall $parameters(stdcell_tap_boundary_wall_cell_p_fill_wall) \
      -n_fill_wall $parameters(stdcell_tap_boundary_wall_cell_n_fill_wall) \
      -p_tap_wall $parameters(stdcell_tap_boundary_wall_cell_p_tap_wall) \
      -n_tap_wall $parameters(stdcell_tap_boundary_wall_cell_n_tap_wall) \
      -p_tb_tap_wall $parameters(stdcell_tap_boundary_wall_cell_p_tb_tap_wall) \
      -n_tb_tap_wall $parameters(stdcell_tap_boundary_wall_cell_n_tb_tap_wall) \
      -left_boundary $parameters(boundary_left) \
      -right_boundary $parameters(boundary_right) \
      -p_tb_boundary $parameters(stdcell_tap_boundary_wall_cell_p_tb_boundary) \
      -n_tb_boundary $parameters(stdcell_tap_boundary_wall_cell_n_tb_boundary) \
      -p_tb_corner_boundary $parameters(stdcell_tap_boundary_wall_cell_p_tb_corner_boundary) \
      -n_tb_corner_boundary $parameters(stdcell_tap_boundary_wall_cell_n_tb_corner_boundary) \
      -p_inner_corner_boundary $parameters(stdcell_tap_boundary_wall_cell_p_inner_corner_boundary) \
      -n_inner_corner_boundary $parameters(stdcell_tap_boundary_wall_cell_n_inner_corner_boundary) \
      -p_ptap_inner_corner_boundary $parameters(stdcell_tap_boundary_wall_cell_p_ptap_inner_corner_boundary) \
      -p_ntap_inner_corner_boundary $parameters(stdcell_tap_boundary_wall_cell_p_ntap_inner_corner_boundary) \
      -n_ptap_inner_corner_boundary $parameters(stdcell_tap_boundary_wall_cell_n_ptap_inner_corner_boundary) \
      -n_ntap_inner_corner_boundary $parameters(stdcell_tap_boundary_wall_cell_n_ntap_inner_corner_boundary) \
      -p_left_tap $parameters(stdcell_tap_boundary_wall_cell_p_left_tap) \
      -n_left_tap $parameters(stdcell_tap_boundary_wall_cell_n_left_tap) \
      -p_right_tap $parameters(stdcell_tap_boundary_wall_cell_p_right_tap) \
      -n_right_tap $parameters(stdcell_tap_boundary_wall_cell_n_right_tap) \
      -p_tb_tap $parameters(stdcell_tap_boundary_wall_cell_p_tb_tap) \
      -n_tb_tap $parameters(stdcell_tap_boundary_wall_cell_n_tb_tap) \
      -p_tb_corner_tap $parameters(stdcell_tap_boundary_wall_cell_p_tb_corner_tap) \
      -n_tb_corner_tap $parameters(stdcell_tap_boundary_wall_cell_n_tb_corner_tap) \
      -p_fill_wall_replacement $parameters(stdcell_tap_boundary_wall_cell_p_fill_wall_replacement) \
      -n_fill_wall_replacement $parameters(stdcell_tap_boundary_wall_cell_n_fill_wall_replacement)"
  }
  
  # 2022.08 - tsmc3eff requires compile_tap_boundary_wall_cells instead.
  if {[regexp {tsmc3eff} $parameters(project_name)]} {
    puts $fid "set_app_options -name chipfinishing.enable_advanced_legalizer_postfixing -value true"
    puts $fid "set_app_options -name chipfinishing.enable_al_tap_insertion -value true"
    #puts $fid "set_app_options -name place.legalize.tap_cover_drop_edges -value {VDD}"
    #puts $fid "set_app_options -name plan.flow.segment_rule -value {vertical_odd}"
    puts $fid "set_app_options -name chipfinishing.enable_even_uniform_row_pattern -value true"
    puts $fid "compile_tap_boundary_wall_cells"
  } else {
    puts $fid "compile_boundary_cells"
  }
  
  # 2022.03-4 - Workaround also required for tsmc12ffc18.
  if {[regexp {tsmc5ff12|tsmc5ffp12|tsmc12ffc18|tsmc16ffc18} $parameters(project_name)]} {
    puts $fid "set_app_options -name place.legalize.enable_advanced_rules -value true"
  }
  
  # 2022.03-2 - gf12lpp18 requires manual placement of inside corner cells.
  if {[regexp {gf12lpp18} $parameters(project_name)]} {
    # Remove all boundary cells except inside corner cells.
    puts $fid "remove_cells -force \[get_cells -filter \"ref_name !~ *CAPTINC13 && ref_name !~ *CAPBINC13\" boundarycell*\]"
    # Move inside corner cells to correct position.
    puts $fid "move_objects -delta {0.39 0} -force \[get_cells -filter \"orientation == R0 || orientation == MX\" boundarycell*\]"
    puts $fid "move_objects -delta {-0.39 0} -force \[get_cells -filter \"orientation == MY || orientation == R180\" boundarycell*\]"
    # Add remaining boundary cells.
    puts $fid "compile_boundary_cells"
  }
}
# end Generate_Boundary_Cells

# Generates empty CDL.
proc Generate_Empty_CDL {macro} {
  Write_Logs "INFO: Generating empty $macro CDL..."
  if {[catch {open ${macro}.cdl w} fid]} {
    Write_Logs "***** $fid"
    exit
  }
  puts $fid ".subckt $macro"
  puts $fid ".ends $macro"
  close $fid
}
# end Generate_Empty_CDL

# Generate size-only LEF from GDS using ICVWB.
proc Generate_LEF {mainParameters macro} {
  upvar $mainParameters parameters
  
  Write_Logs "INFO: Generating $macro size-only LEF..."
  if {[catch {open icvwb_generate_lef.mac w} fid]} {
    Write_Logs "***** $fid"
    exit
  }
  puts $fid "layout open $parameters(gds_$macro) $macro"
  puts $fid "cell edit_state 1"
  puts $fid "set myBOP \[bop extract -layers $parameters(boundary_layer)\]"
  puts $fid "bop insert \$myBOP 10000:0"
  puts $fid "set myBbox \[layer bbox 10000:0\]"
  puts $fid "set size_x \[expr \[lindex \$myBbox 2\] - \[lindex \$myBbox 0\]\]"
  puts $fid "set size_x \[expr \$size_x / 1000.0\]"
  puts $fid "set size_y \[expr \[lindex \$myBbox 3\] - \[lindex \$myBbox 1\]\]"
  puts $fid "set size_y \[expr \$size_y / 1000.0\]"
  puts $fid "find init -type shape -layer 10000:0"
  puts $fid "find table select *"
  puts $fid "set myBoundary \[cell object info coords\]"
  puts $fid "set myFixedBoundary \[list\]"
  puts $fid "foreach coordinate \$myBoundary {"
  puts $fid "  lappend myFixedBoundary \[expr \$coordinate / 1000.0\]"
  puts $fid "}"
  puts $fid "if {\[catch {open ${macro}.lef w} fid\]} {"
  puts $fid "  puts \"***** \$fid\""
  puts $fid "  exit"
  puts $fid "}"
  puts $fid "puts \$fid \"VERSION 5.8 ;\""
  puts $fid "puts \$fid \"BUSBITCHARS \\\"\\\[\\\]\\\" ;\""
  puts $fid "puts \$fid \"DIVIDERCHAR \\\"/\\\" ;\""
  puts $fid "puts \$fid \"MACRO $macro\""
  puts $fid "puts \$fid \"  CLASS BLOCK ;\""
  puts $fid "puts \$fid \"  ORIGIN 0 0 ;\""
  puts $fid "puts \$fid \"  FOREIGN $macro 0 0 ;\""
  puts $fid "puts \$fid \"  SYMMETRY X Y ;\""
  puts $fid "puts \$fid \"  SIZE \$size_x BY \$size_y ;\""
  puts $fid "puts \$fid \"  OBS\""
  puts $fid "puts \$fid \"    LAYER OVERLAP ;\""
  puts $fid "puts \$fid \"      POLYGON \$myFixedBoundary ;\""
  puts $fid "puts \$fid \"  END\""
  puts $fid "puts \$fid \"END $macro\""
  puts $fid "puts \$fid \"\""
  puts $fid "puts \$fid \"END LIBRARY\""
  puts $fid "close \$fid"
  puts $fid "exit"
  close $fid
  
  if {[catch {open icvwb_generate_lef.tcsh w} fid]} {
    Write_Logs "***** $fid"
    exit
  }
  puts $fid "#!/bin/tcsh"
  puts $fid "module unload icvwb"
  puts $fid "module load icvwb/$parameters(icvwb_version)"
  puts $fid "icvwb -run icvwb_generate_lef.mac -nodisplay -log icvwb_generate_lef.log"
  close $fid
  file attributes icvwb_generate_lef.tcsh -permissions +x
  exec ./icvwb_generate_lef.tcsh
}
# end Generate_LEF

# Generate GDS.
# 2022.04 - Eliminate need for macros array variable.
#proc Generate_GDS {mainFloorplans mainMacros mainParameters hard_macros testcase}
# 2022.07 - Renaming to Generate_Layout to reflect that OASIS is supported as well.
proc Generate_Layout {mainFloorplans mainParameters hard_macros testcase} {
  upvar $mainFloorplans floorplans
  #upvar $mainMacros macros
  upvar $mainParameters parameters
  
  # Adding check as ICVWB will complete without exiting on error due to being run with -runnohalt option.
  if {$parameters(boundary_layer) == ""} {
    Write_Logs "ERROR: boundary_layer parameter not defined. Exiting."
    exit
  }

  Write_Logs "INFO: Generating $testcase ${parameters(output_layout_format)}..."
  if {[catch {open icvwb_generate_layout.mac w} fid]} {
    Write_Logs "***** $fid"
    exit
  }
  puts $fid "default filter_layer_hier 1"
  puts $fid "default layer_hier_level 0"
  puts $fid "default find_limit unlimited"
  puts $fid "set layoutID \[layout new $testcase -dbu $parameters(dbu) -uu_per_dbu $parameters(uu_per_dbu)\]"
  
  # 2022.04 - To eliminate need for macros array variable, getting list of macros from floorplans array variable.
  foreach {macro columns rows d_x d_y x y angle mirror} $floorplans($testcase) {
    lappend macros $macro
  }
  set macros [lsort -unique $macros]
  
  #foreach macro $macros($testcase)
  foreach macro $macros {
    puts $fid "set pinID_$macro \[layout new pin_$macro -dbu $parameters(dbu) -uu_per_dbu $parameters(uu_per_dbu)\]"
    if {$parameters(test_macros)} {
      puts $fid "layout open $parameters(gds_$macro) $macro"
      puts $fid "set boundary_bbox \[layer bbox $parameters(boundary_layer) -levels 0\]"
      puts $fid "set x_$macro \[lindex \$boundary_bbox 2\]"
      puts $fid "set y_$macro \[lindex \$boundary_bbox 3\]"
      if {$parameters(macro_text_layers) != ""} {
        puts $fid "if \{\[find init -type text -layer \"$parameters(macro_text_layers)\"\]\} \{"
        puts $fid "  find table select *"
        puts $fid "  select copy \"0 0\""
        puts $fid "  layout active \$pinID_$macro"
        puts $fid "  select paste \"0 0\""
        puts $fid "\}"
      }
    }
    if {$parameters(test_covercells) && [regexp $hard_macros $macro]} {
      puts $fid "layout open $parameters(gds_dwc_ddrphycover_$macro) dwc_ddrphycover_$macro"
      puts $fid "set boundary_bbox \[layer bbox $parameters(boundary_layer) -levels 0\]"
      puts $fid "set x_$macro \[lindex \$boundary_bbox 2\]"
      puts $fid "set y_$macro \[lindex \$boundary_bbox 3\]"
      if {$parameters(covercell_text_layers) != ""} {
        puts $fid "if \{\[find init -type text -layer \"$parameters(covercell_text_layers)\"\]\} \{"
        puts $fid "  find table select *"
        puts $fid "  select copy \"0 0\""
        puts $fid "  layout active \$pinID_$macro"
        puts $fid "  select paste \"0 0\""
        puts $fid "\}"
      }
    }
  }
  puts $fid "layout active \$layoutID"
  
  #foreach macro $macros($testcase)
  # 2022.04-3 - To prevent ICVWB error for adding same reference layout, compiling list of unique GDS files prior to adding them.
  foreach macro $macros {
    if {$parameters(test_macros)} {
      #puts $fid "layout reference add $parameters(gds_$macro)"
      lappend reference_layouts $parameters(gds_$macro)
    }
    if {$parameters(test_covercells) && [regexp $hard_macros $macro]} {
      #puts $fid "layout reference add $parameters(gds_dwc_ddrphycover_$macro)"
      lappend reference_layouts $parameters(gds_dwc_ddrphycover_$macro)
    }
    puts $fid "layout reference add \$pinID_$macro"
  }
  foreach reference_layout [lsort -unique $reference_layouts] {
    puts $fid "layout reference add $reference_layout"
  }

  foreach {macro columns rows d_x d_y x y angle mirror} $floorplans($testcase) {
    if {$parameters(test_macros)} {
      puts $fid "cell add aref $macro $rows $columns \[expr $d_x\] \[expr $d_y\] \"\[expr $x\] \[expr $y\]\" $angle $mirror"
    }
    if {$parameters(test_covercells) && [regexp $hard_macros $macro]} {
      puts $fid "cell add aref dwc_ddrphycover_$macro $rows $columns \[expr $d_x\] \[expr $d_y\] \"\[expr $x\] \[expr $y\]\" $angle $mirror"
    }
    puts $fid "cell add aref pin_$macro $rows $columns \[expr $d_x\] \[expr $d_y\] \"\[expr $x\] \[expr $y\]\" $angle $mirror"
    
    if {$parameters(uniquify_signal_pins)} {
      puts $fid "cell open pin_$macro"
      puts $fid "cell edit_state 1"
      puts $fid "find init -type text"
      puts $fid "find table select *"
      puts $fid "set texts \[select list\]"
      puts $fid "foreach text \$texts {"
      puts $fid "  set string \[cell object info \$text string\]"
      puts $fid "  if \[regexp {^(VAA|VDD|VDDQ|VDDQ_VDD2H|VDDQLP|VSH|VSS)\$} \$string\] {"
      puts $fid "    continue"
      puts $fid "  }"
      puts $fid "  cell object modify \$text \"string 1_\$string\""
      puts $fid "}"
      puts $fid "cell active $testcase"
    }
    
    puts $fid "hierarchy explode -cells pin_$macro"
  }
  
  # 2022.03 - Add rectangular boundary.
  if {$parameters(generate_boundary)} {
    # Using "-levels 1" to only consider boundary at top level of abutted macros.
    puts $fid "set boundary_bbox \[layer bbox $parameters(boundary_layer) -levels 1\]"
    puts $fid "set boundary_llx \[lindex \$boundary_bbox 0\]"
    puts $fid "set boundary_llx \[expr \$boundary_llx - $parameters(generated_boundary_upsize_l) * 1000\]"
    puts $fid "set boundary_lly \[lindex \$boundary_bbox 1\]"
    puts $fid "set boundary_lly \[expr \$boundary_lly - $parameters(generated_boundary_upsize_b) * 1000\]"
    puts $fid "set boundary_urx \[lindex \$boundary_bbox 2\]"
    puts $fid "set boundary_urx \[expr \$boundary_urx + $parameters(generated_boundary_upsize_r) * 1000\]"
    puts $fid "set boundary_ury \[lindex \$boundary_bbox 3\]"
    puts $fid "set boundary_ury \[expr \$boundary_ury + $parameters(generated_boundary_upsize_t) * 1000\]"
    puts $fid "cell object add rectangle \"coords {\$boundary_llx \$boundary_lly \$boundary_urx \$boundary_ury} layer $parameters(boundary_layer)\""
  }
  
  if {$parameters(output_layout_format) == "GDS"} {
    puts $fid "layout extract ${testcase}$parameters(layout_file_extension_zipped) -format gds.gz -cell $testcase"
  } else {
    puts $fid "layout extract ${testcase}$parameters(layout_file_extension_zipped) -format oasis -cell $testcase"
  }
  
  puts $fid "exit"
  close $fid
  
  if {[catch {open icvwb_generate_layout.tcsh w} fid]} {
    Write_Logs "***** $fid"
    exit
  }
  puts $fid "#!/bin/tcsh"
  puts $fid "module unload icvwb"
  puts $fid "module load icvwb/$parameters(icvwb_version)"
  
  # 2022.04-3 - Changed ICVWB to now stop on errors.
  #puts $fid "icvwb -run icvwb_generate_gds.mac -runnohalt -nodisplay -log icvwb_generate_gds.log"
  puts $fid "icvwb -run icvwb_generate_layout.mac -nodisplay -log icvwb_generate_layout.log"
  
  close $fid
  file attributes icvwb_generate_layout.tcsh -permissions +x
  exec ./icvwb_generate_layout.tcsh
}
# end Generate_Layout

# 2022.03-1 - Generate manual standard cell keepouts in ICC2 based on stdcell_manual_kpt_<macro/testcase> parameter.
proc Generate_Manual_Stdcell_Keepouts {mainParameters testcase fid} {
  upvar $mainParameters parameters 

  # If parameter is not defined, exit proc.
  if {![info exists parameters(stdcell_manual_kpt_$testcase)]} {
    return
  }
  
  # Add standard cell keepouts. Parameter value must be given as sets of four numbers representing rectangular bbox (llx lly urx ury) of keepout.
  foreach {llx lly urx ury} $parameters(stdcell_manual_kpt_$testcase) {
    puts $fid "create_placement_blockage -boundary {{$llx $lly} {$urx $ury}}"
  }
}
# end Generate_Manual_Stdcell_Keepouts

# 2022.03 - Generate top level pin labels in ICC2 from subcells. Signal pin names for spare cells are uniquified to eliminate LVS opens.
proc Generate_Pin_Labels {mainParameters fid power_supplies} {
  upvar $mainParameters parameters

  puts $fid "set terminals \[get_terminals -hierarchical -include_lib_cell\]"
  puts $fid "foreach_in_collection terminal \$terminals \{"
  puts $fid "  set text \[get_attribute -objects \$terminal -name port.name\]"
  puts $fid "  set parent_cell_name \[get_attribute -objects \$terminal -name parent_cell.name\]"
  puts $fid "  if {\[regexp {SpareCell.*} \$parent_cell_name\] && !(\[regexp \{${power_supplies}\} \$text\])} {"
  puts $fid "    set text \${parent_cell_name}_\$text"
  puts $fid "  }"
  puts $fid "  set layer \[get_attribute -objects \$terminal -name layer.name\]"
  # Using boundary for text origin coordinate instead of bbox as bbox coordinate may not fall within non-rectangular pin shape.
  puts $fid "  set origin \[lindex \[get_attribute -objects \$terminal -name boundary\] 0\]"
  if {[regexp {int22ffl18} $parameters(project_name)]} {
    puts $fid "  if \[regexp \{(m\\d+)\} \$layer match layer\] \{"
    puts $fid "    set layer \$\{layer\}_pin"
  } elseif {[regexp {gf12lpp18} $parameters(project_name)]} {
    #2022.03-2 - Check for metal layer by seeing if first letter of layer is M, C, K or G. Text should be added to same metal layer in ICC2 to output to label datatype, hence no "set layer" required.
    puts $fid "  if \[regexp \{^(M|C|K|G)\} \$layer match\] \{"
  } else {
    puts $fid "  if \[regexp \{M(\\d+)\} \$layer match layer\] \{"
    puts $fid "    set layer TEXT\$\{layer\}"
  }
  puts $fid "    create_shape -shape_type text -layer \$layer -origin \$origin -height 0.1 -text \$text"
  puts $fid "  \}"
  puts $fid "\}"
}
# end Generate_Pin_Labels

# Generate reference library.
proc Generate_Reference_Lib {mainParameters macros} {
  upvar $mainParameters parameters
  
  Write_Logs "INFO: Generating reference library reference_lib.ndm..."
  
  # Create Library Manager script.
  if {[catch {open lm_generate_reference_lib.tcl w} fid]} {
    Write_Logs "***** $fid"
    exit
  }
  
  # Changing from creating an NDM for each macro to a single NDM.
  #foreach macro [split $testcases] {
  #    puts $fid "create_workspace -technology $parameters(icc2_techfile) $macro -scale_factor [expr round(1e-6 / $parameters(dbu))]"
  #    puts $fid "configure_frame_options -mode preserve_all"
  #    puts $fid "read_lef $parameters(lef_$macro)"
  #    puts $fid "check_workspace"
  #    puts $fid "commit_workspace"
  #  }
  #puts $fid "exit"
  #close $fid
  
  if {[regexp {gf12lpp18|tsmc3eff|tsmc12ffc18|tsmc16ffc18} $parameters(project_name)]} {
    # Use 10000 scale_factor to match (incorrect) scale factor in stdcell NDM.
    # 2022.03-2 - Same workaround required for gf12lpp18.
    # 2022.03-4 - Same workaround required for tsmc12ffc18.
    # 2022.08 - Same workaround required for tsmc3eff.
    puts $fid "create_workspace -technology $parameters(icc2_techfile) reference_lib -scale_factor 10000"
  } else {
    puts $fid "create_workspace -technology $parameters(icc2_techfile) reference_lib -scale_factor [expr round(1e-6 / $parameters(dbu))]"
  }
  puts $fid "configure_frame_options -mode preserve_all"
  foreach macro [split $macros] {
    puts $fid "read_lef $parameters(lef_$macro)"
  }
  puts $fid "check_workspace"
  puts $fid "commit_workspace"
  puts $fid "exit"
  close $fid

  # Run Library Manager script.
  if {[catch {open lm_generate_reference_lib.tcsh w} fid]} {
    Write_Logs "***** $fid"
    exit
  }
  puts $fid "#!/bin/tcsh"
  puts $fid "module unload icc2"
  puts $fid "module load icc2/$parameters(icc2_version)"
  puts $fid "lm_shell -file lm_generate_reference_lib.tcl"
  close $fid
  file attributes lm_generate_reference_lib.tcsh -permissions +x
  exec ./lm_generate_reference_lib.tcsh
}
# end Generate_Reference_Lib

# Generate standard cell fill.
proc Generate_Stdcell_Fill {mainParameters power_supplies macro} {
  upvar $mainParameters parameters
  
  Write_Logs "INFO: Generating $macro GDS..."
  
  # Create IC Compiler II script.
  if {[catch {open icc2.tcl w} fid]} {
    Write_Logs "***** $fid"
    exit
  }
  switch -regexp -- $parameters(project_name) {
    {tsmc5ff12|tsmc5ffp12} {
      # Use stdcell NDM for TSMC5 due to legal orientations specified in unit site_def.
      # 2022.04 - Updated to use tech file to support any metal stack so that stdcell NDM reference techlib no longer needs to be changed.
      #puts $fid "create_lib -use_technology_lib $parameters(stdcell_ndm) -scale_factor [expr round(1e-6 / $parameters(dbu))] -ref_libs \"reference_lib.ndm $parameters(stdcell_ndm)\" $macro"
      puts $fid "create_lib -technology $parameters(icc2_techfile) -scale_factor [expr round(1e-6 / $parameters(dbu))] -ref_libs \"reference_lib.ndm $parameters(stdcell_ndm)\" $macro"
      puts $fid "set_attribute -name symmetry -objects \[get_site_defs unit\] -value Y"
    }
    gf12lpp18 {
      # Use stdcell NDM for TSMC16 due to its (incorrect) 10000 scale_factor.
      # 2022.03-2 - Same workaround required for gf12lpp18.
      # 2022.08-1 - tsmc16ffc18 NDM no longer compatible as techlib for newer versions of ICC2.
      puts $fid "create_lib -use_technology_lib $parameters(stdcell_ndm) -ref_libs \"reference_lib.ndm $parameters(stdcell_ndm)\" $macro"
    }
    tsmc3eff {
      # 2022.08 - Use 10000 scale_factor to match (incorrect) scale factor in stdcell NDM. Allow MY placement of stdcells through Y-symmetry.
      puts $fid "create_lib -technology $parameters(icc2_techfile) -scale_factor 10000 -ref_libs \"reference_lib.ndm $parameters(stdcell_ndm)\" $macro"
      puts $fid "set_attribute -name symmetry -objects \[get_site_defs unitW48H169\] -value Y"
    }
    {tsmc12ffc18|tsmc16ffc18} {
      # 2022.03-4 - Use 10000 scale_factor to match (incorrect) scale factor in stdcell NDM. Allow MY placement of stdcells through Y-symmetry.
      # 2022.08-1 - Same workaround for tsmc16ffc18.
      puts $fid "create_lib -technology $parameters(icc2_techfile) -scale_factor 10000 -ref_libs \"reference_lib.ndm $parameters(stdcell_ndm)\" $macro"
      puts $fid "set_attribute -name symmetry -objects \[get_site_defs unit\] -value Y"
    }
    default {
      puts $fid "create_lib -technology $parameters(icc2_techfile) -scale_factor [expr round(1e-6 / $parameters(dbu))] -ref_libs \"reference_lib.ndm $parameters(stdcell_ndm)\" $macro"
    }
  }
  
  puts $fid "create_block $macro"
  puts $fid "read_def -add_def_only_objects all $parameters(def_$macro)"
  #Locking cell placements as initialize_floorplan may move them around, particularly in cases where macros are overlapped and the tool assumes there is not enough area in floorplan.
  puts $fid "set_attribute -name physical_status -value locked -objects \[get_cells\]"
  puts $fid "set_app_options -name finfet.ignore_grid.std_cell -value true"
  
  # 2022.03-2 - For gf12lpp18, ensure space of at least 2 units between standard cells to avoid fin cut spacing errors.. Note that place.rules.min_od_filler_size and place.rules.min_tpo_filler_size adjustments not required.
  if {[regexp {gf12lpp18} $parameters(project_name)]} {
    puts $fid "set_app_options -name place.rules.min_vt_filler_size -value 2"
  }
  
  puts $fid "initialize_floorplan -keep_boundary -keep_all -flip_first_row false"
  puts $fid "create_keepout_margin -outer \"$parameters(stdcell_kpt_l) $parameters(stdcell_kpt_b) $parameters(stdcell_kpt_r) $parameters(stdcell_kpt_t)\" \[get_cells\]"
  puts $fid "create_keepout_margin -inner \"$parameters(stdcell_inner_kpt_l) $parameters(stdcell_inner_kpt_b) $parameters(stdcell_inner_kpt_r) $parameters(stdcell_inner_kpt_t)\" \[current_block\]"
  
  # 2022.03-1 - Add manual standard cell keepouts.
  Generate_Manual_Stdcell_Keepouts parameters $macro $fid
  
  # 2022.03-2 - Generating boundary cells using new proc.
  Generate_Boundary_Cells parameters $fid
  
  # 2022.04-1 - Generating tap cells using new proc.
  # 2022.08 - Not required for tsmc3eff as these are added with boundary and wall cells.
  if {![regexp {tsmc3eff} $parameters(project_name)]} {
    ICC2_Generate_Tap_Cells parameters $fid
  }
  
  puts $fid "create_utilization_configuration -capacity boundary -include all utilization_config"
  puts $fid "set utilization \[report_utilization -config utilization_config\]"
  puts $fid "set spare_area \[expr \[get_attribute -objects \[current_block\] -name core_area_area\] * (1 - \$utilization)\]"
  puts $fid "set num_inv \[expr int(\$spare_area * 0.2 / \[get_attribute -objects \[get_lib_cells *INV_$parameters(stdcell_drive_strength)\] -name area\])\]"
  puts $fid "set num_buf \[expr int(\$spare_area * 0.2 / \[get_attribute -objects \[get_lib_cells *BUF_$parameters(stdcell_drive_strength)\] -name area\])\]"
  puts $fid "set num_nand \[expr int(\$spare_area * 0.2 / \[get_attribute -objects \[get_lib_cells *ND2_$parameters(stdcell_drive_strength)\] -name area\])\]"
  puts $fid "set num_nor \[expr int(\$spare_area * 0.2 / \[get_attribute -objects \[get_lib_cells *NR2_$parameters(stdcell_drive_strength)\] -name area\])\]"
  puts $fid "add_spare_cells -cell_name SpareCell -num_cells \"\[get_attribute -objects \[get_lib_cells *INV_$parameters(stdcell_drive_strength)\] -name name\] \$num_inv \[get_attribute -objects \[get_lib_cells *BUF_$parameters(stdcell_drive_strength)\] -name name\] \$num_buf \[get_attribute -objects \[get_lib_cells *ND2_$parameters(stdcell_drive_strength)\] -name name\] \$num_nand \[get_attribute -objects \[get_lib_cells *NR2_$parameters(stdcell_drive_strength)\] -name name\] \$num_nor\" -random_distribution"
  puts $fid "legalize_placement"
  
  # 2022.03-2 - For gf12lpp18, cannot leave 1x space as there is no fill cell that size.
  if {[regexp {gf12lpp18} $parameters(project_name)]} {
    puts $fid "create_stdcell_fillers -lib_cells \[sort_collection -descending \[get_lib_cells -regexp \{.*FILL\\\\d.*\}\] name\] -rules no_1x"
  } else {
    puts $fid "create_stdcell_fillers -lib_cells \[sort_collection -descending \[get_lib_cells -regexp \{.*FILL\\\\d.*\}\] name\]"
  }
  
  # 2022.03 - Generating top level pin labels using new proc.
  Generate_Pin_Labels parameters $fid $power_supplies
  
  set gds_files [list $parameters(stdcell_gds)]
  foreach component $parameters(def_components_$macro) {
    lappend gds_files $parameters(gds_$component)
  }
  
  # 2022.04-2 - Using proc to write GDS.
  ICC2_Write_GDS parameters $fid $gds_files $macro
  
  puts $fid "save_lib"
  puts $fid "exit"
  close $fid
  
  # Run IC Compiler II script.
  if {[catch {open icc2.tcsh w} fid]} {
    Write_Logs "***** $fid"
    exit
  }
  puts $fid "#!/bin/tcsh"
  puts $fid "module unload icc2"
  puts $fid "module load icc2/$parameters(icc2_version)"
  puts $fid "icc2_shell -file icc2.tcl"
  close $fid
  file attributes icc2.tcsh -permissions +x
  exec ./icc2.tcsh
  
  # 2022.04 - As of ver1.2b of the ICC2 techfile/layermap file for tsmc5ff12, TEXT0 gets incorrectly streamed out to 202:0, not 202:30 as it should. Post-processing GDS to correct.
  # 2022.08 - Same fix required for tsmc3eff as of ICC2 techfile/layermap ver0.9_1a_eval062422.
  if {[regexp {tsmc3eff|tsmc5ff12|tsmc5ffp12} $parameters(project_name)]} {
    file rename ${macro}.gds.gz ${macro}.pre_m0_fix.gds.gz
    
    if {[catch {open icvwb_m0_fix.mac w} fid]} {
      Write_Logs "***** $fid"
      exit
    }
    puts $fid "layout open ${macro}.pre_m0_fix.gds.gz $macro"
    puts $fid "layout extract ${macro}.gds.gz -format gds.gz -cell $macro -map_layer {202:0 202:30}"
    puts $fid "exit"
    close $fid
    
    if {[catch {open icvwb_m0_fix.tcsh w} fid]} {
      Write_Logs "***** $fid"
      exit
    }
    puts $fid "#!/bin/tcsh"
    puts $fid "module unload icvwb"
    puts $fid "module load icvwb/$parameters(icvwb_version)"
    
    # 2022.04-3 - Changed ICVWB to now stop on errors.
    #puts $fid "icvwb -run icvwb_m0_fix.mac -runnohalt -nodisplay -log icvwb_m0_fix.log"
    puts $fid "icvwb -run icvwb_m0_fix.mac -nodisplay -log icvwb_m0_fix.log"
    
    close $fid
    file attributes icvwb_m0_fix.tcsh -permissions +x
    exec ./icvwb_m0_fix.tcsh
  }
}
# end Generate_Stdcell_Fill

# Generate standard cell ring.
proc Generate_Stdcell_Ring {mainParameters power_supplies macro testcase} {
  upvar $mainParameters parameters
  
  Write_Logs "INFO: Generating $testcase GDS..."
  
  # Create IC Compiler II script.
  if {[catch {open icc2.tcl w} fid]} {
    Write_Logs "***** $fid"
    exit
  }
  switch -regexp -- $parameters(project_name) {
    {tsmc5ff12|tsmc5ffp12} {
      # Use stdcell NDM for TSMC5 due to legal orientations specified in unit site_def.
      # 2022.04 - Updated to use tech file to support any metal stack so that stdcell NDM reference techlib no longer needs to be changed.
      #puts $fid "create_lib -use_technology_lib $parameters(stdcell_ndm) -scale_factor [expr round(1e-6 / $parameters(dbu))] -ref_libs \"../${macro}.ndm $parameters(stdcell_ndm)\" $testcase"
      #puts $fid "create_lib -use_technology_lib $parameters(stdcell_ndm) -scale_factor [expr round(1e-6 / $parameters(dbu))] -ref_libs \"reference_lib.ndm $parameters(stdcell_ndm)\" $testcase"
      puts $fid "create_lib -technology $parameters(icc2_techfile) -scale_factor [expr round(1e-6 / $parameters(dbu))] -ref_libs \"reference_lib.ndm $parameters(stdcell_ndm)\" $testcase"
      puts $fid "set_attribute -name symmetry -objects \[get_site_defs unit\] -value Y"
    }
    gf12lpp18 {
      # Use stdcell NDM for TSMC16 due to its (incorrect) 10000 scale_factor.
      # 2022.03-2 - Same workaround required for gf12lpp18.
      # 2022.08-1 - tsmc16ffc18 NDM no longer compatible as techlib for newer versions of ICC2.
      puts $fid "create_lib -use_technology_lib $parameters(stdcell_ndm) -ref_libs \"reference_lib.ndm $parameters(stdcell_ndm)\" $testcase"
    }
    tsmc3eff {
      # 2022.08 - Use 10000 scale_factor to match (incorrect) scale factor in stdcell NDM. Allow MY placement of stdcells through Y-symmetry.
      puts $fid "create_lib -technology $parameters(icc2_techfile) -scale_factor 10000 -ref_libs \"reference_lib.ndm $parameters(stdcell_ndm)\" $testcase"
      puts $fid "set_attribute -name symmetry -objects \[get_site_defs unitW48H169\] -value Y"
    }
    {tsmc12ffc18|tsmc16ffc18} {
      # 2022.03-4 - Use 10000 scale_factor to match (incorrect) scale factor in stdcell NDM. Allow MY placement of stdcells through Y-symmetry.
      # 2022.08-1 - Same workaround for tsmc16ffc18.
      puts $fid "create_lib -technology $parameters(icc2_techfile) -scale_factor 10000 -ref_libs \"reference_lib.ndm $parameters(stdcell_ndm)\" $testcase"
      puts $fid "set_attribute -name symmetry -objects \[get_site_defs unit\] -value Y"
    }
    default {
      #puts $fid "create_lib -technology $parameters(icc2_techfile) -scale_factor [expr round(1e-6 / $parameters(dbu))] -ref_libs \"../${macro}.ndm $parameters(stdcell_ndm)\" $testcase"
      puts $fid "create_lib -technology $parameters(icc2_techfile) -scale_factor [expr round(1e-6 / $parameters(dbu))] -ref_libs \"reference_lib.ndm $parameters(stdcell_ndm)\" $testcase"
    }
  }
  puts $fid "set site_def \[get_site_defs unit\]"
  puts $fid "set stdcell_x \[get_attribute \$site_def width\]"
  puts $fid "set stdcell_y \[get_attribute \$site_def height\]"
  # Doubling site height to ensure even number of stdcell rows for TSMC5 and to avoid needing top boundary cells.
  puts $fid "set stdcell_y \[expr 2 * \$stdcell_y\]"
  # Ensuring odd site width for TSMC5.
  puts $fid "set stdcell_width \[expr ceil(10 / \$stdcell_x) * 2 * \$stdcell_x + \$stdcell_x\]"
  puts $fid "set stdcell_height \[expr ceil(20 / \$stdcell_y) * \$stdcell_y\]"
  
  #puts $fid "set macro_width \[get_attribute ${macro}/${macro} width\]"
  puts $fid "set macro_width \[get_attribute $macro width\]"
  puts $fid "set width \[expr \$macro_width + 2 * \$stdcell_width + $parameters(stdcell_kpt_l) + $parameters(stdcell_kpt_r)\]"
  #puts $fid "set macro_height \[get_attribute ${macro}/${macro} height\]"
  puts $fid "set macro_height \[get_attribute $macro height\]"
  puts $fid "set height \[expr \$macro_height + 2 * \$stdcell_height + $parameters(stdcell_kpt_b) + $parameters(stdcell_kpt_t)\]"
 
  # 2022.03 - Placing macro at testbench origin.
  #puts $fid "set origin_x \[expr \$stdcell_width + $parameters(stdcell_kpt_l)\]"
  puts $fid "set origin_offset_x \[expr -\$stdcell_width - $parameters(stdcell_kpt_l)\]"
  #puts $fid "set origin_y \[expr \$stdcell_height + $parameters(stdcell_kpt_b)\]"
  puts $fid "set origin_offset_y \[expr -\$stdcell_height - $parameters(stdcell_kpt_b)\]"
  puts $fid "create_block $testcase"
  puts $fid "set_app_options -name finfet.ignore_grid.std_cell -value true"
  
  # 2022.03-2 - For gf12lpp18, ensure space of at least 2 units between standard cells to avoid fin cut spacing errors. Note that place.rules.min_od_filler_size and place.rules.min_tpo_filler_size adjustments not required.
  if {[regexp {gf12lpp18} $parameters(project_name)]} {
    puts $fid "set_app_options -name place.rules.min_vt_filler_size -value 2"
  }

  # By not flipping first row, don't require top boundary cells.
  #puts $fid "initialize_floorplan -side_length \"\$width \$height\" -flip_first_row false"
  switch -regexp -- $parameters(project_name) {
    gf12lpp18 {
      # 2022.03-2 - For gf12lpp18, require boundary extended outside of standard cell boundaries to avoid OUTLINE related DRC errors.
      puts $fid "initialize_floorplan -side_length \"\$width \$height\" -flip_first_row false -origin_offset \"\[expr \$origin_offset_x - 0.045\] \[expr \$origin_offset_y - 0.053\]\" -core_offset {0.045 0.053}"
    }
    tsmc3eff {
      # 2022.08 - For tsmc3eff, require boundary extended outside of standard cell boundaries to avoid forbidden enclosure DRC errors.
      puts $fid "initialize_floorplan -side_length \"\$width \$height\" -flip_first_row false -origin_offset \"\$origin_offset_x \[expr \$origin_offset_y - 0.052\]\" -core_offset {0 0.052}"
    }
    default {
      puts $fid "initialize_floorplan -side_length \"\$width \$height\" -flip_first_row false -origin_offset \"\$origin_offset_x \$origin_offset_y\""
    }
  }
  
  puts $fid "create_cell $macro $macro"
  #puts $fid "set_cell_location -coordinates \"\$origin_x \$origin_y\" $macro"
  puts $fid "set_cell_location -coordinates {0 0} $macro"
  #puts $fid "create_placement_blockage -boundary \[list \"\$stdcell_width \$stdcell_height\" \"\[expr \$origin_x + \$macro_width + $parameters(stdcell_kpt_r)\] \[expr \$origin_y + \$macro_height + $parameters(stdcell_kpt_t)\]\"\]"
  # Updated creation of placement blockage to support rectilinear boundaries.
  #puts $fid "set myPolyRect \[create_poly_rect -boundary \[get_attribute -objects $macro -name boundary\]\]"
  #puts $fid "set myGeoMask \[resize_polygons -objects \$myPolyRect -size \"$parameters(stdcell_kpt_l) $parameters(stdcell_kpt_b) $parameters(stdcell_kpt_r) $parameters(stdcell_kpt_t)\"\]"
  #puts $fid "create_placement_blockage -boundary \$myGeoMask"
  # move_objects not required as obtaining boundary of cell and not lib_cell.
  #puts $fid "move_objects -delta \"\$origin_x \$origin_y\" -simple \[get_placement_blockages\]"
  # Updated to use keepout margins instead of placement blockages.
  puts $fid "create_keepout_margin -outer \"$parameters(stdcell_kpt_l) $parameters(stdcell_kpt_b) $parameters(stdcell_kpt_r) $parameters(stdcell_kpt_t)\" $macro"
  
  # 2022.03-1 - Add manual standard cell keepouts.
  Generate_Manual_Stdcell_Keepouts parameters $testcase $fid
  
  # 2022.03-2 - Generating boundary cells using new proc.
  Generate_Boundary_Cells parameters $fid
  
  # 2022.04-1 - Generating tap cells using new proc.
  # 2022.08 - Not required for tsmc3eff as these are added with boundary and wall cells.
  if {![regexp {tsmc3eff} $parameters(project_name)]} {
    ICC2_Generate_Tap_Cells parameters $fid
  }
  
  # Remove placement blockage area from total area.
  #puts $fid "set spare_area \[expr \$width * \$height - \[get_attribute -objects \[get_placement_blockages\] -name area\]\]"
  # Get utilization of area outside placement blockage.
  #puts $fid "create_utilization_configuration -capacity boundary -include all -exclude \{hard_macros hard_blockages\} utilization_config"
  # Get utilization. Macro, keepout and boundary/tap cells should be considered correctly with following.
  puts $fid "create_utilization_configuration -capacity boundary -include all utilization_config"
  puts $fid "set utilization \[report_utilization -config utilization_config\]"
  puts $fid "set spare_area \[expr \$width * \$height * (1 - \$utilization)\]"
  puts $fid "set num_inv \[expr int(\$spare_area * 0.2 / \[get_attribute -objects \[get_lib_cells *INV_$parameters(stdcell_drive_strength)\] -name area\])\]"
  puts $fid "set num_buf \[expr int(\$spare_area * 0.2 / \[get_attribute -objects \[get_lib_cells *BUF_$parameters(stdcell_drive_strength)\] -name area\])\]"
  puts $fid "set num_nand \[expr int(\$spare_area * 0.2 / \[get_attribute -objects \[get_lib_cells *ND2_$parameters(stdcell_drive_strength)\] -name area\])\]"
  puts $fid "set num_nor \[expr int(\$spare_area * 0.2 / \[get_attribute -objects \[get_lib_cells *NR2_$parameters(stdcell_drive_strength)\] -name area\])\]"
  puts $fid "add_spare_cells -cell_name SpareCell -num_cells \"\[get_attribute -objects \[get_lib_cells *INV_$parameters(stdcell_drive_strength)\] -name name\] \$num_inv \[get_attribute -objects \[get_lib_cells *BUF_$parameters(stdcell_drive_strength)\] -name name\] \$num_buf \[get_attribute -objects \[get_lib_cells *ND2_$parameters(stdcell_drive_strength)\] -name name\] \$num_nand \[get_attribute -objects \[get_lib_cells *NR2_$parameters(stdcell_drive_strength)\] -name name\] \$num_nor\" -random_distribution"
  puts $fid "legalize_placement"
  
  # 2022.03-2 - For gf12lpp18, cannot leave 1x space as there is no fill cell that size.
  if {[regexp {gf12lpp18} $parameters(project_name)]} {
    puts $fid "create_stdcell_fillers -lib_cells \[sort_collection -descending \[get_lib_cells -regexp \{.*FILL\\\\d.*\}\] name\] -rules no_1x"
  } else {
    puts $fid "create_stdcell_fillers -lib_cells \[sort_collection -descending \[get_lib_cells -regexp \{.*FILL\\\\d.*\}\] name\]"
  }
  
  # 2022.03 - Generating top level pin labels using new proc.
  Generate_Pin_Labels parameters $fid $power_supplies
  #  puts $fid "set terminals \[get_terminals -hierarchical -include_lib_cell\]"
  #  puts $fid "foreach_in_collection terminal \$terminals \{"
  #  puts $fid "  set text \[get_attribute -objects \$terminal -name port.name\]"
  #  puts $fid "  set layer \[get_attribute -objects \$terminal -name layer.name\]"
  #  # Changing text origin coordinate to boundary from bbox to fix issue where bbox coordinate may not fall within non-rectangular pin shape.
  #  #puts $fid "  set origin \[lindex \[get_attribute -objects \$terminal -name bbox\] 0\]"
  #  puts $fid "  set origin \[lindex \[get_attribute -objects \$terminal -name boundary\] 0\]"
  #  if {[regexp {int22ffl18} $parameters(project_name)]} {
  #    puts $fid "  if \[regexp \{(m\\d+)\} \$layer match layer\] \{"
  #    puts $fid "    set layer \$\{layer\}_pin"
  #  } else {
  #    puts $fid "  if \[regexp \{M(\\d+)\} \$layer match layer\] \{"
  #    puts $fid "    set layer TEXT\$\{layer\}"
  #  }
  #  puts $fid "    create_shape -shape_type text -layer \$layer -origin \$origin -height 0.1 -text \$text"
  #  puts $fid "  \}"
  #  puts $fid "\}"
  
  # 2022.04-2 - Using proc to write GDS.
  ICC2_Write_GDS parameters $fid "$parameters(gds_$macro) $parameters(stdcell_gds)" $testcase
  
  puts $fid "save_lib"
  puts $fid "exit"
  close $fid
  
  # Run IC Compiler II script.
  if {[catch {open icc2.tcsh w} fid]} {
    Write_Logs "***** $fid"
    exit
  }
  puts $fid "#!/bin/tcsh"
  puts $fid "module unload icc2"
  puts $fid "module load icc2/$parameters(icc2_version)"
  puts $fid "icc2_shell -file icc2.tcl"
  close $fid
  file attributes icc2.tcsh -permissions +x
  exec ./icc2.tcsh
  
  # As of ver1.2b of the ICC2 techfile/layermap file for tsmc5ff12, TEXT0 gets incorrectly streamed out to 202:0, not 202:30 as it should. Post-processing GDS to correct.
  # 2022.08 - Same fix required for tsmc3eff as of ICC2 techfile/layermap ver0.9_1a_eval062422.
  if {[regexp {tsmc3eff|tsmc5ff12|tsmc5ffp12} $parameters(project_name)]} {
    file rename ${testcase}.gds.gz ${testcase}.pre_m0_fix.gds.gz
    
    if {[catch {open icvwb_m0_fix.mac w} fid]} {
      Write_Logs "***** $fid"
      exit
    }
    puts $fid "layout open ${testcase}.pre_m0_fix.gds.gz $testcase"
    puts $fid "layout extract ${testcase}.gds.gz -format gds.gz -cell $testcase -map_layer {202:0 202:30}"
    puts $fid "exit"
    close $fid
    
    if {[catch {open icvwb_m0_fix.tcsh w} fid]} {
      Write_Logs "***** $fid"
      exit
    }
    puts $fid "#!/bin/tcsh"
    puts $fid "module unload icvwb"
    puts $fid "module load icvwb/$parameters(icvwb_version)"
    
    # 2022.04-3 - Changed ICVWB to now stop on errors.
    #puts $fid "icvwb -run icvwb_m0_fix.mac -runnohalt -nodisplay -log icvwb_m0_fix.log"
    puts $fid "icvwb -run icvwb_m0_fix.mac -nodisplay -log icvwb_m0_fix.log"
    
    close $fid
    file attributes icvwb_m0_fix.tcsh -permissions +x
    exec ./icvwb_m0_fix.tcsh
  }
}
# end Generate_Stdcell_Ring

# 2022.04-1 - Generate tap cells in ICC2.
proc ICC2_Generate_Tap_Cells {mainParameters fid} {
  upvar $mainParameters parameters
  
  switch -regexp -- $parameters(project_name) {
    {tsmc5ff12|tsmc5ffp12} {
      # Avoid DRCs due to misaligned vertically abutted taps and tap abutment to certain boundary cells.
      # Although taps can abut directly vertically, -no_abutment option is the easiest way to avoid the misaligned tap scenario.
      puts $fid "create_tap_cells -lib_cell $parameters(stdcell_tap) -distance $parameters(tap_distance) -pattern stagger -skip_fixed_cells -no_abutment -no_abutment_cells \"$parameters(boundary_bottom_left_inside_horizontal_abutment) $parameters(boundary_bottom_right_inside_horizontal_abutment)\""
    
      # Taps can still be placed in misaligned vertically abutted configuration in narrow stdcell regions.
      # While it doesn't appear possible for 3 taps to be vertically abutted, if this were to happen, this could be problematic as a tap aligned to the tap above could end up misaligned to the tap below depending upon tap collection order.
      # Possible fix for this scenario is to sort_collection on y-coordinate prior to iterating through taps. Not implemented as this doesn't appear to be required.
      puts $fid "set tap_width \[get_attribute -objects $parameters(stdcell_tap) -name width\]"
      puts $fid "foreach_in_collection tap \[get_cells tapfiller*\] {"
      puts $fid "  set tap_name \[get_attribute -objects \$tap -name name\]"
	    puts $fid "  set tap_bbox \[get_attribute -objects \$tap -name boundary_bbox\]" 
	    puts $fid "  set tap_llx \[lindex \$tap_bbox 0 0\]"
	    puts $fid "  foreach_in_collection abutting_tap \[get_cells -quiet -filter \"(ref_name == $parameters(stdcell_tap)) && (name != \\\"\$tap_name\\\")\" -intersect \$tap_bbox\] {"
      puts $fid "    set abutting_tap_llx \[lindex \[get_attribute -objects \$abutting_tap -name boundary_bbox\] 0 0\]"
      puts $fid "    set delta_x \[expr \$tap_llx - \$abutting_tap_llx\]"
      puts $fid "    set abs_delta_x \[expr abs(\$delta_x)\]"
      puts $fid "    if {(\$abs_delta_x != 0) && (\$abs_delta_x != \$tap_width)} {"
      puts $fid "      move_objects -delta \"\$delta_x 0\" -force \$abutting_tap"
      puts $fid "    }"
      puts $fid "  }"
      puts $fid "}" 
    }
    default {
      puts $fid "create_tap_cells -lib_cell $parameters(stdcell_tap) -distance $parameters(tap_distance) -pattern stagger -skip_fixed_cells"
    }
  }
}
# end ICC2_Generate_Tap_Cells

# 2022.04-2 - Write GDS in ICC2.
proc ICC2_Write_GDS {mainParameters fid gds_files macro} {
  upvar $mainParameters parameters
  
  switch -regexp -- $parameters(project_name) {
    {gf12lpp18} {
      # Manually set units to 1000 for 1nm DBU as scale_factor for library is incorrect due to stdcell NDM.
      # 2022.03-2 - Same workaround required for gf12lpp18.
      puts $fid "write_gds -compress -layer_map $parameters(icc2_gds_layer_map) -long_names -merge_files \"$gds_files\" -merge_gds_top_cell $macro -units 1000 ${macro}.gds.gz"
    }
    {tsmc3eff} {
      # 2022.08 - Manually set units to 2000 for 0.5nm DBU as scale_factor for library is incorrect due to stdcell NDM.
      puts $fid "write_gds -compress -layer_map $parameters(icc2_gds_layer_map) -long_names -merge_files \"$gds_files\" -merge_gds_top_cell $macro -units 2000 ${macro}.gds.gz"
    }
    {tsmc12ffc18|tsmc16ffc18} {
      # 2022.03-4 - Manually set units to 1000 for 1nm DBU as scale_factor for library is incorrect due to stdcell NDM.
      # 2022.04-2 - Layer map is in ICC format.
      # 2022.09 - Same workaround required for tsmc16ffc18.
      puts $fid "write_gds -compress -layer_map $parameters(icc2_gds_layer_map) -layer_map_format icc_extended -long_names -merge_files \"$gds_files\" -merge_gds_top_cell $macro -units 1000 ${macro}.gds.gz"
    }
    default {
      puts $fid "write_gds -compress -layer_map $parameters(icc2_gds_layer_map) -long_names -merge_files \"$gds_files\" -merge_gds_top_cell $macro -units \[get_attribute -objects \[current_lib\] -name scale_factor\] ${macro}.gds.gz"
    }
  }
}
# end ICC2_Write_GDS


# Merge macro GDS as subcell into wrapper.
proc Merge_GDS {mainParameters macro wrapper} {
  upvar $mainParameters parameters
  
  Write_Logs "INFO: Generating $wrapper GDS..."
  
  if {[catch {open gds_merge.tcsh w} fid]} {
    Write_Logs "***** $fid"
    exit
  }
  puts $fid "#!/bin/tcsh"
  puts $fid "msip_layGdsMerge $parameters(gds_$wrapper) $parameters(gds_$macro) -o ${wrapper}.gds.gz"
  close $fid
  file attributes gds_merge.tcsh -permissions +x
  exec ./gds_merge.tcsh >& gds_merge.log
}
# end Merge_GDS

# 2022.03-3 - Open testcase log file and put in script version and parameters.
proc Open_Testcase_Log {testcase scriptVersion parameters} {
    
  if {[catch {open ${testcase}.log w} fid]} {
    Write_Log "***** $fid"
    exit
  }
  
  # Get date and time.
  set date_time [clock format [clock seconds]]
  
  puts $fid "\[${date_time}\] INFO: Running CRD Abutment Verification Script version: $scriptVersion"
  puts $fid "\[${date_time}\] INFO: Parameters file contents:\n$parameters"
    
  return $fid
}
# end Open_Testcase_Log

# Runs physical verification.
# Note for gf12lpp18: as of 20210916, "--type drc --prefix DRC" actually runs MSIP-Tools->Verification->Internal->DRC. 
#   In order to run MSIP-Tools->Verification->Tapeout->DRC_DPcolored, set "--type drc --prefix DRCsignOff".
#   Also, change the error file path to "find -path \"*drcsignoff_icv/${testcase}.LAYOUT_ERRORS\".
proc Run_PV {mainParameters testcase} {
  upvar $mainParameters parameters
  
  #Write_Logs "INFO: Running PV on ${testcase}..."
  if {[catch {open ude_sourceme w} fid]} {
    Write_Logs "***** $fid"
    exit
  }
  puts $fid "module unload msip_cd_pv"
  puts $fid "module load msip_cd_pv/$parameters(msip_cd_pv_version)"
  puts $fid "setenv RUN_DIR_ROOT [pwd]/pv"
  close $fid
  
  if {[info exists parameters(drc_icv)] && $parameters(drc_icv)} {
    Write_Logs "INFO: Running DRC_ICV on ${testcase}..."
    if {[catch {open pvbatch_config_drc_icv w} fid]} {
      Write_Logs "***** $fid"
      exit
    }
    puts $fid "set useGrid $parameters(grid)"
    puts $fid "set enableGridFilling $parameters(grid)"
    #puts $fid "set gridUserDefRes \"-l h_vmem=$parameters(mem),mem_free=$parameters(mem)\""
    puts $fid "set gridProc $parameters(drc_icv_grid_processes)"
    if {[info exists parameters(drc_icv_options_file)] && ($parameters(drc_icv_options_file) != "")} {
      puts $fid "set optionsFile $parameters(drc_icv_options_file)"
    }
    if {[info exists parameters(drc_icv_runset)] && ($parameters(drc_icv_runset) != "")} {
      puts $fid "set runset $parameters(drc_icv_runset)"
    }
    puts $fid "set icvUnselectRuleNames \"$parameters(drc_icv_unselect_rule_names)\""
    # Grid filling fix and general instructions: https://jira.internal.synopsys.com/browse/P10020416-28026
    if {$parameters(drc_feol_fill) && $parameters(drc_beol_fill)} {
      puts $fid "set enableDRCFilling true"
      puts $fid "set enableFEOLFilling true"
      puts $fid "set enableBEOLFilling true"
    } elseif {$parameters(drc_feol_fill)} {
      puts $fid "set enableDRCFilling true"
      puts $fid "set enableFEOLFilling true"
      puts $fid "set enableBEOLFilling false"
    } elseif {$parameters(drc_beol_fill)} {
      puts $fid "set enableDRCFilling true"
      puts $fid "set enableFEOLFilling false"
      puts $fid "set enableBEOLFilling true"
    }
    
    # 2022.08 - Error limit.
    if {[info exists parameters(drc_error_limit)] && ($parameters(drc_error_limit) != "")} {
      puts $fid "set errorLimitEnabled true"
      puts $fid "set errorLimit $parameters(drc_error_limit)"
    }
    
    close $fid
    if {[catch {open pv_drc_icv.tcsh w} fid]} {
      Write_Logs "***** $fid"
      exit
    }
    puts $fid "#!/bin/tcsh"
    puts $fid "module unload msip_cd_pv"
    puts $fid "module load msip_cd_pv/$parameters(msip_cd_pv_version)"
    puts $fid "pvbatch --projectType $parameters(project_type) --projectName $parameters(project_name) --releaseName $parameters(release_name) --metalStack $parameters(metal_stack) --type drc --prefix $parameters(drc_prefix) --streamPath [pwd]/${testcase}$parameters(layout_file_extension_zipped) --cellName $testcase --layoutFormat $parameters(output_layout_format) --tool icv --config [pwd]/pvbatch_config_drc_icv --udeArgs \"--log [pwd]/pvbatch_drc_icv.log --sourceShellFile [pwd]/ude_sourceme\" --tmpLibPath"
    # 2022.07 - Updated output file structure to match CKT P4 release structure.
    puts $fid "mkdir -p ../results/${testcase}/icv/drc"
    puts $fid "find -ipath \"*${parameters(drc_prefix)}_icv/${testcase}.LAYOUT_ERRORS\" -exec ln -s \"[pwd]/{}\" ../results/${testcase}/icv/drc/drc_${testcase}_${parameters(metal_stack)}.rpt \\;"
    puts $fid "ln -s [pwd]/../${testcase}.log ../results/${testcase}/icv/drc/drc_${testcase}_${parameters(metal_stack)}.log"
    close $fid
    file attributes pv_drc_icv.tcsh -permissions +x
    catch {exec ./pv_drc_icv.tcsh >& pv_drc_icv.log &}
    # Delay no longer required with lib.defs access fix: https://jira.internal.synopsys.com/browse/P10020416-27925
    #after 120000
  }
  
  if {[info exists parameters(drc_calibre)] && $parameters(drc_calibre)} {
    Write_Logs "INFO: Running DRC_CALIBRE on ${testcase}..."
    if {[catch {open pvbatch_config_drc_calibre w} fid]} {
      Write_Logs "***** $fid"
      exit
    }
    puts $fid "set calexExtraArg \"$parameters(drc_calex_extra_arguments)\""
    # Grid filling fix and general instructions: https://jira.internal.synopsys.com/browse/P10020416-28026
    # 2022.08 - Added required preferences for Calibre.
    if {$parameters(drc_feol_fill) && $parameters(drc_beol_fill)} {
      puts $fid "set enableDRCFilling true"
      puts $fid "set enableFEOLFilling true"
      puts $fid "set enableBEOLFilling true"
      puts $fid "db::createPref MSIPDRCenableDRCFilling -value 1"
      puts $fid "db::createPref MSIPDRCimportCalibreFillBEOLGDSName -value \"BEOL\""
      puts $fid "db::createPref MSIPDRCimportCalibreFillFEOLGDSName -value \"FEOL\""
    } elseif {$parameters(drc_feol_fill)} {
      puts $fid "set enableDRCFilling true"
      puts $fid "set enableFEOLFilling true"
      puts $fid "set enableBEOLFilling false"
      puts $fid "db::createPref MSIPDRCenableDRCFilling -value 1"
      puts $fid "db::createPref MSIPDRCimportCalibreFillFEOLGDSName -value \"FEOL\""
    } elseif {$parameters(drc_beol_fill)} {
      puts $fid "set enableDRCFilling true"
      puts $fid "set enableFEOLFilling false"
      puts $fid "set enableBEOLFilling true"
      puts $fid "db::createPref MSIPDRCenableDRCFilling -value 1"
      puts $fid "db::createPref MSIPDRCimportCalibreFillBEOLGDSName -value \"BEOL\""
    }
    
    # 2022.08 - Error limit.
    if {[info exists parameters(drc_error_limit)] && ($parameters(drc_error_limit) != "")} {
      puts $fid "set errorLimitEnabled true"
      puts $fid "set errorLimit $parameters(drc_error_limit)"
    }
    
    close $fid
    if {[catch {open pv_drc_calibre.tcsh w} fid]} {
      Write_Logs "***** $fid"
      exit
    }
    puts $fid "#!/bin/tcsh"
    puts $fid "module unload msip_cd_pv"
    puts $fid "module load msip_cd_pv/$parameters(msip_cd_pv_version)"
    puts $fid "pvbatch --projectType $parameters(project_type) --projectName $parameters(project_name) --releaseName $parameters(release_name) --metalStack $parameters(metal_stack) --type drc --prefix $parameters(drc_prefix) --streamPath [pwd]/${testcase}$parameters(layout_file_extension_zipped) --cellName $testcase --layoutFormat $parameters(output_layout_format) --tool calibre --config [pwd]/pvbatch_config_drc_calibre --udeArgs \"--log [pwd]/pvbatch_drc_calibre.log --sourceShellFile [pwd]/ude_sourceme\" --tmpLibPath"
    # 2022.07 - Updated output file structure to match CKT P4 release structure.
    puts $fid "mkdir -p ../results/${testcase}/calibre/drc"
    puts $fid "find -ipath \"*${parameters(drc_prefix)}_calibre/drc_summary.report\" -exec ln -s \"[pwd]/{}\" ../results/${testcase}/calibre/drc/drc_${testcase}_${parameters(metal_stack)}.rpt \\;"
    puts $fid "ln -s [pwd]/../${testcase}.log ../results/${testcase}/calibre/drc/drc_${testcase}_${parameters(metal_stack)}.log"
    close $fid
    file attributes pv_drc_calibre.tcsh -permissions +x
    catch {exec ./pv_drc_calibre.tcsh >& pv_drc_calibre.log &}
    # Delay no longer required with lib.defs access fix: https://jira.internal.synopsys.com/browse/P10020416-27925
    #after 120000
  }
  
  if {[info exists parameters(lvs_icv)] && $parameters(lvs_icv)} {
    Write_Logs "INFO: Running LVS_ICV on ${testcase}..."
    if {[catch {open pvbatch_config_lvs_icv w} fid]} {
      Write_Logs "***** $fid"
      exit
    }
    puts $fid "set useGrid $parameters(grid)"
    #puts $fid "set gridUserDefRes \"-l h_vmem=$parameters(mem),mem_free=$parameters(mem)\""
    puts $fid "set gridProc $parameters(lvs_icv_grid_processes)"
    
    # 2022.03-2 - Removed FOUNDRY_DEFAULT from virtual_connect parameter in parameters file template, so need to check for missing parameter or empty string.
    if {[info exists parameters(virtual_connect_icv)] && ($parameters(virtual_connect_icv) != "")} {
      puts $fid "set virtualConnect $parameters(virtual_connect_icv)"
    }
    
    close $fid
    if {[catch {open pv_lvs_icv.tcsh w} fid]} {
      Write_Logs "***** $fid"
      exit
    }
    puts $fid "#!/bin/tcsh"
    puts $fid "module unload msip_cd_pv"
    puts $fid "module load msip_cd_pv/$parameters(msip_cd_pv_version)"
    puts $fid "pvbatch --projectType $parameters(project_type) --projectName $parameters(project_name) --releaseName $parameters(release_name) --metalStack $parameters(metal_stack) --type lvs --prefix $parameters(lvs_prefix) --streamPath [pwd]/${testcase}$parameters(layout_file_extension_zipped) --cdlPath [pwd]/${testcase}.cdl --cellName $testcase --layoutFormat $parameters(output_layout_format) --tool icv --config [pwd]/pvbatch_config_lvs_icv --udeArgs \"--log [pwd]/pvbatch_lvs_icv.log --sourceShellFile [pwd]/ude_sourceme\" --tmpLibPath"
    # 2022.07 - Updated output file structure to match CKT P4 release structure.
    puts $fid "mkdir -p ../results/${testcase}/icv/erc"
    puts $fid "mkdir -p ../results/${testcase}/icv/lvs"
    puts $fid "find -ipath \"*${parameters(lvs_prefix)}_icv/${testcase}.LAYOUT_ERRORS\" -exec ln -s \"[pwd]/{}\" ../results/${testcase}/icv/erc/erc_${testcase}_${parameters(metal_stack)}.rpt \\;"
    puts $fid "ln -s [pwd]/../${testcase}.log ../results/${testcase}/icv/erc/erc_${testcase}_${parameters(metal_stack)}.log"
    puts $fid "find -ipath \"*${parameters(lvs_prefix)}_icv/${testcase}.LVS_ERRORS\" -exec ln -s \"[pwd]/{}\" ../results/${testcase}/icv/lvs/lvs_${testcase}_${parameters(metal_stack)}.rpt \\;"
    puts $fid "ln -s [pwd]/../${testcase}.log ../results/${testcase}/icv/lvs/lvs_${testcase}_${parameters(metal_stack)}.log"
    close $fid
    file attributes pv_lvs_icv.tcsh -permissions +x
    catch {exec ./pv_lvs_icv.tcsh >& pv_lvs_icv.log &}
    # Delay no longer required with lib.defs access fix: https://jira.internal.synopsys.com/browse/P10020416-27925
    #after 120000
  }
  
  if {[info exists parameters(lvs_calibre)] && $parameters(lvs_calibre)} {
    Write_Logs "INFO: Running LVS_CALIBRE on ${testcase}..."
    if {[catch {open pvbatch_config_lvs_calibre w} fid]} {
      Write_Logs "***** $fid"
      exit
    }
    
    # 2022.03-2 - Removed FOUNDRY_DEFAULT from virtual_connect parameter in parameters file template, so need to check for missing parameter or empty string.
    if {[info exists parameters(virtual_connect_calibre)] && ($parameters(virtual_connect_calibre) != "")} {
      puts $fid "set virtualConnect $parameters(virtual_connect_calibre)"
    }
    
    puts $fid "set calexExtraArg \"$parameters(lvs_calex_extra_arguments)\""
    close $fid
    if {[catch {open pv_lvs_calibre.tcsh w} fid]} {
      Write_Logs "***** $fid"
      exit
    }
    puts $fid "#!/bin/tcsh"
    puts $fid "module unload msip_cd_pv"
    puts $fid "module load msip_cd_pv/$parameters(msip_cd_pv_version)"
    puts $fid "pvbatch --projectType $parameters(project_type) --projectName $parameters(project_name) --releaseName $parameters(release_name) --metalStack $parameters(metal_stack) --type lvs --prefix $parameters(lvs_prefix) --streamPath [pwd]/${testcase}$parameters(layout_file_extension_zipped) --cdlPath [pwd]/${testcase}.cdl --cellName $testcase --layoutFormat $parameters(output_layout_format) --tool calibre --config [pwd]/pvbatch_config_lvs_calibre --udeArgs \"--log [pwd]/pvbatch_lvs_calibre.log --sourceShellFile [pwd]/ude_sourceme\" --tmpLibPath"
    # 2022.07 - Updated output file structure to match CKT P4 release structure.
    puts $fid "mkdir -p ../results/${testcase}/calibre/erc"
    puts $fid "mkdir -p ../results/${testcase}/calibre/lvs"
    #puts $fid "find -path \"*lvs_calibre/cell.results.ext\" -exec ln -s \"${testcase}/{}\" ../${testcase}.LVS_CALIBRE.cell.results.ext \\;"
    puts $fid "find -ipath \"*${parameters(lvs_prefix)}_calibre/erc_summary.report\" -exec ln -s \"[pwd]/{}\" ../results/${testcase}/calibre/erc/erc_${testcase}_${parameters(metal_stack)}.rpt \\;"
    puts $fid "ln -s [pwd]/../${testcase}.log ../results/${testcase}/calibre/erc/erc_${testcase}_${parameters(metal_stack)}.log"
    puts $fid "find -ipath \"*${parameters(lvs_prefix)}_calibre/cell.results\" -exec ln -s \"[pwd]/{}\" ../results/${testcase}/calibre/lvs/lvs_${testcase}_${parameters(metal_stack)}.rpt \\;"
    puts $fid "ln -s [pwd]/../${testcase}.log ../results/${testcase}/calibre/lvs/lvs_${testcase}_${parameters(metal_stack)}.log"
    close $fid
    file attributes pv_lvs_calibre.tcsh -permissions +x
    catch {exec ./pv_lvs_calibre.tcsh >& pv_lvs_calibre.log &}
    # Delay no longer required with lib.defs access fix: https://jira.internal.synopsys.com/browse/P10020416-27925
    #after 120000
  }
 
  if {[info exists parameters(perccnod_icv)] && $parameters(perccnod_icv)} {
    Write_Logs "INFO: Running PERCCNOD_ICV on ${testcase}..."
    if {[catch {open pvbatch_config_perccnod_icv w} fid]} {
      Write_Logs "***** $fid"
      exit
    }
    puts $fid "set useGrid $parameters(grid)"
    puts $fid "set gridProc $parameters(perccnod_icv_grid_processes)"
    
    # 2022.03-2 - Removed FOUNDRY_DEFAULT from virtual_connect parameter in parameters file template, so need to check for missing parameter or empty string.
    if {[info exists parameters(virtual_connect_icv)] && ($parameters(virtual_connect_icv) != "")} {
      puts $fid "set virtualConnect $parameters(virtual_connect_icv)"
    }
    
    close $fid
    if {[catch {open pv_perccnod_icv.tcsh w} fid]} {
      Write_Logs "***** $fid"
      exit
    }
    puts $fid "#!/bin/tcsh"
    puts $fid "module unload msip_cd_pv"
    puts $fid "module load msip_cd_pv/$parameters(msip_cd_pv_version)"
    puts $fid "pvbatch --projectType $parameters(project_type) --projectName $parameters(project_name) --releaseName $parameters(release_name) --metalStack $parameters(metal_stack) --type perc --prefix $parameters(perccnod_prefix) --streamPath [pwd]/${testcase}$parameters(layout_file_extension_zipped) --cdlPath [pwd]/${testcase}.cdl --cellName $testcase --layoutFormat $parameters(output_layout_format) --tool icv --config [pwd]/pvbatch_config_perccnod_icv --udeArgs \"--log [pwd]/pvbatch_perccnod_icv.log --sourceShellFile [pwd]/ude_sourceme\" --tmpLibPath"
    # 2022.07 - Updated output file structure to match CKT P4 release structure.
    puts $fid "mkdir -p ../results/${testcase}/icv/perc_cnod"
    puts $fid "find -ipath \"*${parameters(perccnod_prefix)}_icv/${testcase}.LAYOUT_ERRORS\" -exec ln -s \"[pwd]/{}\" ../results/${testcase}/icv/perc_cnod/perc_cnod_${testcase}_${parameters(metal_stack)}.rpt \\;"
    puts $fid "ln -s [pwd]/../${testcase}.log ../results/${testcase}/icv/perc_cnod/perc_cnod_${testcase}_${parameters(metal_stack)}.log"
    close $fid
    file attributes pv_perccnod_icv.tcsh -permissions +x
    catch {exec ./pv_perccnod_icv.tcsh >& pv_perccnod_icv.log &}
    # Delay no longer required with lib.defs access fix: https://jira.internal.synopsys.com/browse/P10020416-27925
    #after 120000
  }
  
  if {[info exists parameters(perccnod_calibre)] && $parameters(perccnod_calibre)} {
    Write_Logs "INFO: Running PERCCNOD_CALIBRE on ${testcase}..."
    if {[catch {open pvbatch_config_perccnod_calibre w} fid]} {
      Write_Logs "***** $fid"
      exit
    }
    puts $fid "set calexExtraArg \"$parameters(perccnod_calex_extra_arguments)\""
    
    # 2022.03-2 - Removed FOUNDRY_DEFAULT from virtual_connect parameter in parameters file template, so need to check for missing parameter or empty string.
    if {[info exists parameters(virtual_connect_calibre)] && ($parameters(virtual_connect_calibre) != "")} {
      puts $fid "set virtualConnect $parameters(virtual_connect_calibre)"
    }
    
    close $fid
    if {[catch {open pv_perccnod_calibre.tcsh w} fid]} {
      Write_Logs "***** $fid"
      exit
    }
    puts $fid "#!/bin/tcsh"
    puts $fid "module unload msip_cd_pv"
    puts $fid "module load msip_cd_pv/$parameters(msip_cd_pv_version)"
    puts $fid "pvbatch --projectType $parameters(project_type) --projectName $parameters(project_name) --releaseName $parameters(release_name) --metalStack $parameters(metal_stack) --type perc --prefix $parameters(perccnod_prefix) --streamPath [pwd]/${testcase}$parameters(layout_file_extension_zipped) --cellName $testcase --layoutFormat $parameters(output_layout_format) --tool calibre --config [pwd]/pvbatch_config_perccnod_calibre --udeArgs \"--log [pwd]/pvbatch_perccnod_calibre.log --sourceShellFile [pwd]/ude_sourceme\" --tmpLibPath"
    # 2022.07 - Updated output file structure to match CKT P4 release structure.
    puts $fid "mkdir -p ../results/${testcase}/calibre/perc_cnod"
    puts $fid "find -ipath \"*${parameters(perccnod_prefix)}_calibre/cell.results\" -exec ln -s \"[pwd]/{}\" ../results/${testcase}/calibre/perc_cnod/perc_cnod_${testcase}_${parameters(metal_stack)}.cell.results \\;"
    puts $fid "ln -s [pwd]/../${testcase}.log ../results/${testcase}/calibre/perc_cnod/perc_cnod_${testcase}_${parameters(metal_stack)}.log"
    close $fid
    file attributes pv_perccnod_calibre.tcsh -permissions +x
    catch {exec ./pv_perccnod_calibre.tcsh >& pv_perccnod_calibre.log &}
    # Delay no longer required with lib.defs access fix: https://jira.internal.synopsys.com/browse/P10020416-27925
    #after 120000
  }
  
  if {[info exists parameters(percldl_icv)] && $parameters(percldl_icv)} {
    Write_Logs "INFO: Running PERCLDL_ICV on ${testcase}..."
    if {[catch {open pvbatch_config_percldl_icv w} fid]} {
      Write_Logs "***** $fid"
      exit
    }
    puts $fid "set useGrid $parameters(grid)"
    puts $fid "set gridProc $parameters(percldl_icv_grid_processes)"
    
    # 2022.03-2 - Removed FOUNDRY_DEFAULT from virtual_connect parameter in parameters file template, so need to check for missing parameter or empty string.
    if {[info exists parameters(virtual_connect_icv)] && ($parameters(virtual_connect_icv) != "")} {
      puts $fid "set virtualConnect $parameters(virtual_connect_icv)"
    }
    
    close $fid
    if {[catch {open pv_percldl_icv.tcsh w} fid]} {
      Write_Logs "***** $fid"
      exit
    }
    puts $fid "#!/bin/tcsh"
    puts $fid "module unload msip_cd_pv"
    puts $fid "module load msip_cd_pv/$parameters(msip_cd_pv_version)"
    puts $fid "pvbatch --projectType $parameters(project_type) --projectName $parameters(project_name) --releaseName $parameters(release_name) --metalStack $parameters(metal_stack) --type perc --prefix $parameters(percldl_prefix) --streamPath [pwd]/${testcase}$parameters(layout_file_extension_zipped) --cellName $testcase --layoutFormat $parameters(output_layout_format) --tool icv --config [pwd]/pvbatch_config_percldl_icv --udeArgs \"--log [pwd]/pvbatch_percldl_icv.log --sourceShellFile [pwd]/ude_sourceme\" --tmpLibPath"
    # 2022.07 - Updated output file structure to match CKT P4 release structure.
    puts $fid "mkdir -p ../results/${testcase}/icv/perc_esd"
    puts $fid "find -ipath \"*${parameters(percldl_prefix)}_icv/${testcase}.LAYOUT_ERRORS\" -exec ln -s \"[pwd]/{}\" ../results/${testcase}/icv/perc_esd/perc_ldl_${testcase}_${parameters(metal_stack)}.rpt \\;"
    puts $fid "find -ipath \"*${parameters(percldl_prefix)}_icv/perc_reports/ldl_results.txt\" -exec ln -s \"[pwd]/{}\" ../results/${testcase}/icv/perc_esd/perc_ldl_${testcase}_${parameters(metal_stack)}.results \\;"
    puts $fid "find -ipath \"*${parameters(percldl_prefix)}_icv/perc_reports/ldl_results.html\" -exec ln -s \"[pwd]/{}\" ../results/${testcase}/icv/perc_esd/perc_ldl_${testcase}_${parameters(metal_stack)}.results.html \\;"
    puts $fid "ln -s [pwd]/../${testcase}.log ../results/${testcase}/icv/perc_esd/perc_ldl_${testcase}_${parameters(metal_stack)}.log"
    puts $fid "find -ipath \"*${parameters(percldl_prefix)}_icv/merged.TSMC.ESD.MARK$parameters(layout_file_extension)\" -exec ln -s {} percldl_icv.merged.TSMC.ESD.MARK$parameters(layout_file_extension) \\;"
        
    if {[info exists parameters(perccd_icv)] && $parameters(perccd_icv)} {
      Write_Logs "INFO: Running PERCCD_ICV on ${testcase}..."
      puts $fid "./pv_perccd_icv.tcsh >& pv_perccd_icv.log &"
      if {[catch {open pvbatch_config_perccd_icv w} fid2]} {
        Write_Logs "***** $fid2"
        exit
      }
      puts $fid2 "set useGrid $parameters(grid)"
      puts $fid2 "set gridUserDefResEn 1"
      puts $fid2 "set gridUserDefRes \"--hosts $parameters(perccd_icv_grid_hosts) --cores-per-host $parameters(perccd_icv_grid_cores_per_host) --grid-options \\\"-P bnormal -l mem_free=100G,h_vmem=$parameters(perccd_icv_grid_h_vmem),scratch_free=10G\\\"\""
      
      # 2022.03-2 - Removed FOUNDRY_DEFAULT from virtual_connect parameter in parameters file template, so need to check for missing parameter or empty string.
      if {[info exists parameters(virtual_connect_icv)] && ($parameters(virtual_connect_icv) != "")} {
        puts $fid2 "set virtualConnect $parameters(virtual_connect_icv)"
      }
      
      close $fid2
      if {[catch {open pv_perccd_icv.tcsh w} fid2]} {
        Write_Logs "***** $fid2"
        exit
      }
      puts $fid2 "#!/bin/tcsh"
      puts $fid2 "module unload msip_cd_pv"
      puts $fid2 "module load msip_cd_pv/$parameters(msip_cd_pv_version)"
      puts $fid2 "pvbatch --projectType $parameters(project_type) --projectName $parameters(project_name) --releaseName $parameters(release_name) --metalStack $parameters(metal_stack) --type perc --prefix $parameters(perccd_prefix) --streamPath [pwd]/percldl_icv.merged.TSMC.ESD.MARK$parameters(layout_file_extension) --cellName $testcase --layoutFormat $parameters(output_layout_format) --tool icv --config [pwd]/pvbatch_config_perccd_icv --udeArgs \"--log [pwd]/pvbatch_perccd_icv.log --sourceShellFile [pwd]/ude_sourceme\" --tmpLibPath"
      # 2022.07 - Updated output file structure to match CKT P4 release structure.
      #puts $fid2 "find -path \"*perccd_icv/${testcase}.LAYOUT_ERRORS\" -exec ln -s \"[pwd]/{}\" ../results/${testcase}/icv/perc_esd/perc_cd_${testcase}_${parameters(metal_stack)}.rpt \\;"
      # 2022.09 - Fixed ICV PERC CD report names.
      puts $fid2 "find -ipath \"*${parameters(perccd_prefix)}_icv/perc_reports/cd_results.Worst_per_net.txt\" -exec ln -s \"[pwd]/{}\" ../results/${testcase}/icv/perc_esd/perc_cd_${testcase}_${parameters(metal_stack)}.results \\;"
      puts $fid2 "find -ipath \"*${parameters(perccd_prefix)}_icv/perc_reports/cd_results.Worst_per_net.html\" -exec ln -s \"[pwd]/{}\" ../results/${testcase}/icv/perc_esd/perc_cd_${testcase}_${parameters(metal_stack)}.results.html \\;"
      puts $fid2 "ln -s [pwd]/../${testcase}.log ../results/${testcase}/icv/perc_esd/perc_cd_${testcase}_${parameters(metal_stack)}.log"
      close $fid2
      file attributes pv_perccd_icv.tcsh -permissions +x
    }
    
    if {[info exists parameters(percp2p_icv)] && $parameters(percp2p_icv)} {
      Write_Logs "INFO: Running PERCP2P_ICV on ${testcase}..."
      puts $fid "./pv_percp2p_icv.tcsh >& pv_percp2p_icv.log &"
      if {[catch {open pvbatch_config_percp2p_icv w} fid2]} {
        Write_Logs "***** $fid2"
        exit
      }
      puts $fid2 "set useGrid $parameters(grid)"
      puts $fid2 "set gridUserDefResEn 1"
      puts $fid2 "set gridUserDefRes \"--hosts $parameters(percp2p_icv_grid_hosts) --cores-per-host $parameters(percp2p_icv_grid_cores_per_host) --grid-options \\\"-P bnormal -l mem_free=100G,h_vmem=$parameters(percp2p_icv_grid_h_vmem),scratch_free=10G\\\"\""
      
      # 2022.03-2 - Removed FOUNDRY_DEFAULT from virtual_connect parameter in parameters file template, so need to check for missing parameter or empty string.
      if {[info exists parameters(virtual_connect_icv)] && ($parameters(virtual_connect_icv) != "")} {
        puts $fid2 "set virtualConnect $parameters(virtual_connect_icv)"
      }
      
      close $fid2
      if {[catch {open pv_percp2p_icv.tcsh w} fid2]} {
        Write_Logs "***** $fid2"
        exit
      }
      puts $fid2 "#!/bin/tcsh"
      puts $fid2 "module unload msip_cd_pv"
      puts $fid2 "module load msip_cd_pv/$parameters(msip_cd_pv_version)"
      puts $fid2 "pvbatch --projectType $parameters(project_type) --projectName $parameters(project_name) --releaseName $parameters(release_name) --metalStack $parameters(metal_stack) --type perc --prefix $parameters(percp2p_prefix) --streamPath [pwd]/percldl_icv.merged.TSMC.ESD.MARK$parameters(layout_file_extension) --cellName $testcase --layoutFormat $parameters(output_layout_format) --tool icv --config [pwd]/pvbatch_config_percp2p_icv --udeArgs \"--log [pwd]/pvbatch_percp2p_icv.log --sourceShellFile [pwd]/ude_sourceme\" --tmpLibPath"
      # 2022.07 - Updated output file structure to match CKT P4 release structure.
      #puts $fid2 "find -path \"*percp2p_icv/${testcase}.LAYOUT_ERRORS\" -exec ln -s \"[pwd]/{}\" ../results/${testcase}/icv/perc_esd/perc_p2p_${testcase}_${parameters(metal_stack)}.rpt \\;"
      puts $fid2 "find -ipath \"*${parameters(percp2p_prefix)}_icv/perc_reports/p2p_results.txt\" -exec ln -s \"[pwd]/{}\" ../results/${testcase}/icv/perc_esd/perc_p2p_${testcase}_${parameters(metal_stack)}.results \\;"
      puts $fid2 "find -ipath \"*${parameters(percp2p_prefix)}_icv/perc_reports/p2p_results.html\" -exec ln -s \"[pwd]/{}\" ../results/${testcase}/icv/perc_esd/perc_p2p_${testcase}_${parameters(metal_stack)}.results.html \\;"
      puts $fid2 "ln -s [pwd]/../${testcase}.log ../results/${testcase}/icv/perc_esd/perc_p2p_${testcase}_${parameters(metal_stack)}.log"
      close $fid2
      file attributes pv_percp2p_icv.tcsh -permissions +x
    }
    
    close $fid
    file attributes pv_percldl_icv.tcsh -permissions +x
    catch {exec ./pv_percldl_icv.tcsh >& pv_percldl_icv.log &}
    # Delay no longer required with lib.defs access fix: https://jira.internal.synopsys.com/browse/P10020416-27925
    #after 120000
  } else {
    if {[info exists parameters(perccd_icv)] && $parameters(perccd_icv)} {
      Write_Logs "ERROR: Attempting to run PERCCD_ICV without running PERCLDL_ICV. Skipping PERCCD_ICV."
    }
    if {[info exists parameters(percp2p_icv)] && $parameters(percp2p_icv)} {
      Write_Logs "ERROR: Attempting to run PERCP2P_ICV without running PERCLDL_ICV. Skipping PERCP2P_ICV."
    }
  }
  
  if {[info exists parameters(percldl_calibre)] && $parameters(percldl_calibre)} {
     Write_Logs "INFO: Running PERCLDL_CALIBRE on ${testcase}..."
    if {[catch {open pvbatch_config_percldl_calibre w} fid]} {
      Write_Logs "***** $fid"
      exit
    }
    puts $fid "set calexExtraArg \"$parameters(percldl_calex_extra_arguments)\""
    
    # 2022.03-2 - Removed FOUNDRY_DEFAULT from virtual_connect parameter in parameters file template, so need to check for missing parameter or empty string.
    if {[info exists parameters(virtual_connect_calibre)] && ($parameters(virtual_connect_calibre) != "")} {
      puts $fid "set virtualConnect $parameters(virtual_connect_calibre)"
    }
    
    close $fid
    if {[catch {open pv_percldl_calibre.tcsh w} fid]} {
      Write_Logs "***** $fid"
      exit
    }
    puts $fid "#!/bin/tcsh"
    puts $fid "module unload msip_cd_pv"
    puts $fid "module load msip_cd_pv/$parameters(msip_cd_pv_version)"
    puts $fid "pvbatch --projectType $parameters(project_type) --projectName $parameters(project_name) --releaseName $parameters(release_name) --metalStack $parameters(metal_stack) --type perc --prefix $parameters(percldl_prefix) --streamPath [pwd]/${testcase}$parameters(layout_file_extension_zipped) --cellName $testcase --layoutFormat $parameters(output_layout_format) --tool calibre --config [pwd]/pvbatch_config_percldl_calibre --udeArgs \"--log [pwd]/pvbatch_percldl_calibre.log --sourceShellFile [pwd]/ude_sourceme\" --tmpLibPath"
    # 2022.07 - Updated output file structure to match CKT P4 release structure.
    puts $fid "mkdir -p ../results/${testcase}/calibre/perc_esd"
    puts $fid "find -ipath \"*${parameters(percldl_prefix)}_calibre/cell.results\" -exec ln -s \"[pwd]/{}\" ../results/${testcase}/calibre/perc_esd/perc_ldl_${testcase}_${parameters(metal_stack)}.cell.results \\;"
    puts $fid "find -ipath \"*${parameters(percldl_prefix)}_calibre/perc.rep.ldl\" -exec ln -s \"[pwd]/{}\" ../results/${testcase}/calibre/perc_esd/perc_ldl_${testcase}_${parameters(metal_stack)}.perc.rep.ldl \\;"
    puts $fid "ln -s [pwd]/../${testcase}.log ../results/${testcase}/calibre/perc_esd/perc_ldl_${testcase}_${parameters(metal_stack)}.log"
    puts $fid "find -ipath \"*${parameters(percldl_prefix)}_calibre/TSMC.ESD.MARK.gds\" -exec ln -s {} percldl_calibre.TSMC.ESD.MARK.gds \\;"
    
    if {[info exists parameters(perccd_calibre)] && $parameters(perccd_calibre)} {
      Write_Logs "INFO: Running PERCCD_CALIBRE on ${testcase}..."
      puts $fid "./pv_perccd_calibre.tcsh >& pv_perccd_calibre.log &"
      if {[catch {open pvbatch_config_perccd_calibre w} fid2]} {
        Write_Logs "***** $fid2"
        exit
      }
      puts $fid2 "set calexExtraArg \"$parameters(perccd_calex_extra_arguments)\""
      
      # 2022.03-2 - Removed FOUNDRY_DEFAULT from virtual_connect parameter in parameters file template, so need to check for missing parameter or empty string.
      if {[info exists parameters(virtual_connect_calibre)] && ($parameters(virtual_connect_calibre) != "")} {
        puts $fid2 "set virtualConnect $parameters(virtual_connect_calibre)"
      }
      
      puts $fid2 "set enStreamComp 1"
      puts $fid2 "set inputStreamComp [pwd]/percldl_calibre.TSMC.ESD.MARK.gds"
      close $fid2
      if {[catch {open pv_perccd_calibre.tcsh w} fid2]} {
        Write_Logs "***** $fid2"
        exit
      }
      puts $fid2 "#!/bin/tcsh"
      puts $fid2 "module unload msip_cd_pv"
      puts $fid2 "module load msip_cd_pv/$parameters(msip_cd_pv_version)"
      puts $fid2 "pvbatch --projectType $parameters(project_type) --projectName $parameters(project_name) --releaseName $parameters(release_name) --metalStack $parameters(metal_stack) --type perc --prefix $parameters(perccd_prefix) --streamPath [pwd]/${testcase}$parameters(layout_file_extension_zipped) --cellName $testcase --layoutFormat $parameters(output_layout_format) --tool calibre --config [pwd]/pvbatch_config_perccd_calibre --udeArgs \"--log [pwd]/pvbatch_perccd_calibre.log --sourceShellFile [pwd]/ude_sourceme\" --tmpLibPath"
      # 2022.07 - Updated output file structure to match CKT P4 release structure.
      puts $fid2 "find -ipath \"*${parameters(perccd_prefix)}_calibre/cell.results\" -exec ln -s \"[pwd]/{}\" ../results/${testcase}/calibre/perc_esd/perc_cd_${testcase}_${parameters(metal_stack)}.cell.results \\;"
      puts $fid2 "find -ipath \"*${parameters(perccd_prefix)}_calibre/cell.results.cd\" -exec ln -s \"[pwd]/{}\" ../results/${testcase}/calibre/perc_esd/perc_cd_${testcase}_${parameters(metal_stack)}.cell.results.cd \\;"
      puts $fid2 "ln -s [pwd]/../${testcase}.log ../results/${testcase}/calibre/perc_esd/perc_cd_${testcase}_${parameters(metal_stack)}.log"
      close $fid2
      file attributes pv_perccd_calibre.tcsh -permissions +x
    }
    
    if {[info exists parameters(percp2p_calibre)] && $parameters(percp2p_calibre)} {
      Write_Logs "INFO: Running PERCP2P_CALIBRE on ${testcase}..."
      puts $fid "./pv_percp2p_calibre.tcsh >& pv_percp2p_calibre.log &"
      if {[catch {open pvbatch_config_percp2p_calibre w} fid2]} {
        Write_Logs "***** $fid2"
        exit
      }
      puts $fid2 "set calexExtraArg \"$parameters(percp2p_calex_extra_arguments)\""
      
      # 2022.03-2 - Removed FOUNDRY_DEFAULT from virtual_connect parameter in parameters file template, so need to check for missing parameter or empty string.
      if {[info exists parameters(virtual_connect_calibre)] && ($parameters(virtual_connect_calibre) != "")} {
        puts $fid2 "set virtualConnect $parameters(virtual_connect_calibre)"
      }
      
      puts $fid2 "set enStreamComp 1"
      puts $fid2 "set inputStreamComp [pwd]/percldl_calibre.TSMC.ESD.MARK.gds"
      close $fid2
      if {[catch {open pv_percp2p_calibre.tcsh w} fid2]} {
        Write_Logs "***** $fid2"
        exit
      }
      puts $fid2 "#!/bin/tcsh"
      puts $fid2 "module unload msip_cd_pv"
      puts $fid2 "module load msip_cd_pv/$parameters(msip_cd_pv_version)"
      puts $fid2 "pvbatch --projectType $parameters(project_type) --projectName $parameters(project_name) --releaseName $parameters(release_name) --metalStack $parameters(metal_stack) --type perc --prefix $parameters(percp2p_prefix) --streamPath [pwd]/${testcase}$parameters(layout_file_extension_zipped) --cellName $testcase --layoutFormat $parameters(output_layout_format) --tool calibre --config [pwd]/pvbatch_config_percp2p_calibre --udeArgs \"--log [pwd]/pvbatch_percp2p_calibre.log --sourceShellFile [pwd]/ude_sourceme\" --tmpLibPath"
      # 2022.07 - Updated output file structure to match CKT P4 release structure.
      puts $fid2 "find -ipath \"*${parameters(percp2p_prefix)}_calibre/cell.results\" -exec ln -s \"[pwd]/{}\" ../results/${testcase}/calibre/perc_esd/perc_p2p_${testcase}_${parameters(metal_stack)}.cell.results \\;"
      puts $fid2 "find -ipath \"*${parameters(percp2p_prefix)}_calibre/cell.results.p2p\" -exec ln -s \"[pwd]/{}\" ../results/${testcase}/calibre/perc_esd/perc_p2p_${testcase}_${parameters(metal_stack)}.cell.results.p2p \\;"
      puts $fid2 "find -ipath \"*${parameters(percp2p_prefix)}_calibre/perc.rep.p2p.sum\" -exec ln -s \"[pwd]/{}\" ../results/${testcase}/calibre/perc_esd/perc_p2p_${testcase}_${parameters(metal_stack)}.perc.rep.p2p.sum \\;"
      puts $fid2 "ln -s [pwd]/../${testcase}.log ../results/${testcase}/calibre/perc_esd/perc_p2p_${testcase}_${parameters(metal_stack)}.log"
      close $fid2
      file attributes pv_percp2p_calibre.tcsh -permissions +x
    }
    
    close $fid
    file attributes pv_percldl_calibre.tcsh -permissions +x
    catch {exec ./pv_percldl_calibre.tcsh >& pv_percldl_calibre.log &}
    # Delay no longer required with lib.defs access fix: https://jira.internal.synopsys.com/browse/P10020416-27925
    #after 120000
  } else {
    if {[info exists parameters(perccd_calibre)] && $parameters(perccd_calibre)} {
      Write_Logs "ERROR: Attempting to run PERCCD_CALIBRE without running PERCLDL_CALIBRE. Skipping PERCCD_CALIBRE."
    }
    if {[info exists parameters(percp2p_calibre)] && $parameters(percp2p_calibre)} {
      Write_Logs "ERROR: Attempting to run PERCP2P_CALIBRE without running PERCLDL_CALIBRE. Skipping PERCP2P_CALIBRE."
    }
  }
  
  if {[info exists parameters(perctopo_icv)] && $parameters(perctopo_icv)} {
    Write_Logs "INFO: Running PERCTOPO_ICV on ${testcase}..."
    if {[catch {open pvbatch_config_perctopo_icv w} fid]} {
      Write_Logs "***** $fid"
      exit
    }
    puts $fid "set useGrid $parameters(grid)"
    puts $fid "set gridProc $parameters(perctopo_icv_grid_processes)"
    
    # 2022.03-2 - Removed FOUNDRY_DEFAULT from virtual_connect parameter in parameters file template, so need to check for missing parameter or empty string.
    if {[info exists parameters(virtual_connect_icv)] && ($parameters(virtual_connect_icv) != "")} {
      puts $fid "set virtualConnect $parameters(virtual_connect_icv)"
    }
    
    close $fid
    if {[catch {open pv_perctopo_icv.tcsh w} fid]} {
      Write_Logs "***** $fid"
      exit
    }
    puts $fid "#!/bin/tcsh"
    puts $fid "module unload msip_cd_pv"
    puts $fid "module load msip_cd_pv/$parameters(msip_cd_pv_version)"
    puts $fid "pvbatch --projectType $parameters(project_type) --projectName $parameters(project_name) --releaseName $parameters(release_name) --metalStack $parameters(metal_stack) --type perc --prefix $parameters(perctopo_prefix) --streamPath [pwd]/${testcase}$parameters(layout_file_extension_zipped) --cdlPath [pwd]/${testcase}.cdl --cellName $testcase --layoutFormat $parameters(output_layout_format) --tool icv --config [pwd]/pvbatch_config_perctopo_icv --udeArgs \"--log [pwd]/pvbatch_perctopo_icv.log --sourceShellFile [pwd]/ude_sourceme\" --tmpLibPath"
    # 2022.07 - Updated output file structure to match CKT P4 release structure.
    puts $fid "mkdir -p ../results/${testcase}/icv/perc_esd"
    puts $fid "find -ipath \"*${parameters(perctopo_prefix)}_icv/${testcase}.LAYOUT_ERRORS\" -exec ln -s \"[pwd]/{}\" ../results/${testcase}/icv/perc_esd/perc_topo_${testcase}_${parameters(metal_stack)}.rpt \\;"
    puts $fid "find -ipath \"*${parameters(perctopo_prefix)}_icv/perc_reports/topo_results.txt\" -exec ln -s \"[pwd]/{}\" ../results/${testcase}/icv/perc_esd/perc_topo_${testcase}_${parameters(metal_stack)}.results \\;"
    puts $fid "find -ipath \"*${parameters(perctopo_prefix)}_icv/perc_reports/topo_results.html\" -exec ln -s \"[pwd]/{}\" ../results/${testcase}/icv/perc_esd/perc_topo_${testcase}_${parameters(metal_stack)}.results.html \\;"
    puts $fid "find -ipath \"*${parameters(perctopo_prefix)}_icv/perc_reports/esd_network_report.txt\" -exec ln -s \"[pwd]/{}\" ../results/${testcase}/icv/perc_esd/perc_topo_${testcase}_${parameters(metal_stack)}.esd_network.results \\;"
    puts $fid "find -ipath \"*${parameters(perctopo_prefix)}_icv/perc_reports/esd_network_report.html\" -exec ln -s \"[pwd]/{}\" ../results/${testcase}/icv/perc_esd/perc_topo_${testcase}_${parameters(metal_stack)}.esd_network.results.html \\;"
    puts $fid "ln -s [pwd]/../${testcase}.log ../results/${testcase}/icv/perc_esd/perc_topo_${testcase}_${parameters(metal_stack)}.log"
    close $fid
    file attributes pv_perctopo_icv.tcsh -permissions +x
    catch {exec ./pv_perctopo_icv.tcsh >& pv_perctopo_icv.log &}
    # Delay no longer required with lib.defs access fix: https://jira.internal.synopsys.com/browse/P10020416-27925
    #after 120000
  }
  
  if {[info exists parameters(perctopo_calibre)] && $parameters(perctopo_calibre)} {
    Write_Logs "INFO: Running PERCTOPO_CALIBRE on ${testcase}..."
    if {[catch {open pvbatch_config_perctopo_calibre w} fid]} {
      Write_Logs "***** $fid"
      exit
    }
    puts $fid "set calexExtraArg \"$parameters(perctopo_calex_extra_arguments)\""
    
    # 2022.03-2 - Removed FOUNDRY_DEFAULT from virtual_connect parameter in parameters file template, so need to check for missing parameter or empty string.
    if {[info exists parameters(virtual_connect_calibre)] && ($parameters(virtual_connect_calibre) != "")} {
      puts $fid "set virtualConnect $parameters(virtual_connect_calibre)"
    }
    
    close $fid
    if {[catch {open pv_perctopo_calibre.tcsh w} fid]} {
      Write_Logs "***** $fid"
      exit
    }
    puts $fid "#!/bin/tcsh"
    puts $fid "module unload msip_cd_pv"
    puts $fid "module load msip_cd_pv/$parameters(msip_cd_pv_version)"
    puts $fid "pvbatch --projectType $parameters(project_type) --projectName $parameters(project_name) --releaseName $parameters(release_name) --metalStack $parameters(metal_stack) --type perc --prefix $parameters(perctopo_prefix) --streamPath [pwd]/${testcase}$parameters(layout_file_extension_zipped) --cdlPath [pwd]/${testcase}.cdl --cellName $testcase --layoutFormat $parameters(output_layout_format) --tool calibre --config [pwd]/pvbatch_config_perctopo_calibre --udeArgs \"--log [pwd]/pvbatch_perctopo_calibre.log --sourceShellFile [pwd]/ude_sourceme\" --tmpLibPath"
    # 2022.07 - Updated output file structure to match CKT P4 release structure.
    puts $fid "mkdir -p ../results/${testcase}/calibre/perc_esd"
    puts $fid "find -ipath \"*${parameters(perctopo_prefix)}_calibre/perc.sum\" -exec ln -s \"[pwd]/{}\" ../results/${testcase}/calibre/perc_esd/perc_topo_${testcase}_${parameters(metal_stack)}.perc.sum \\;"
    puts $fid "find -ipath \"*${parameters(perctopo_prefix)}_calibre/cell.results\" -exec ln -s \"[pwd]/{}\" ../results/${testcase}/calibre/perc_esd/perc_topo_${testcase}_${parameters(metal_stack)}.cell.results \\;"
    puts $fid "ln -s [pwd]/../${testcase}.log ../results/${testcase}/calibre/perc_esd/perc_topo_${testcase}_${parameters(metal_stack)}.log"
    close $fid
    file attributes pv_perctopo_calibre.tcsh -permissions +x
    catch {exec ./pv_perctopo_calibre.tcsh >& pv_perctopo_calibre.log &}
    # Delay no longer required with lib.defs access fix: https://jira.internal.synopsys.com/browse/P10020416-27925
    #after 120000
  }
  
  if {[info exists parameters(perctopola_icv)] && $parameters(perctopola_icv)} {
    Write_Logs "INFO: Running PERCTOPOLA_ICV on ${testcase}..."
    if {[catch {open pvbatch_config_perctopola_icv w} fid]} {
      Write_Logs "***** $fid"
      exit
    }
    puts $fid "set useGrid $parameters(grid)"
    puts $fid "set gridProc $parameters(perctopola_icv_grid_processes)"
    
    # 2022.03-2 - Removed FOUNDRY_DEFAULT from virtual_connect parameter in parameters file template, so need to check for missing parameter or empty string.
    if {[info exists parameters(virtual_connect_icv)] && ($parameters(virtual_connect_icv) != "")} {
      puts $fid "set virtualConnect $parameters(virtual_connect_icv)"
    }
    
    close $fid
    if {[catch {open pv_perctopola_icv.tcsh w} fid]} {
      Write_Logs "***** $fid"
      exit
    }
    puts $fid "#!/bin/tcsh"
    puts $fid "module unload msip_cd_pv"
    puts $fid "module load msip_cd_pv/$parameters(msip_cd_pv_version)"
    puts $fid "pvbatch --projectType $parameters(project_type) --projectName $parameters(project_name) --releaseName $parameters(release_name) --metalStack $parameters(metal_stack) --type perc --prefix $parameters(perctopola_prefix) --streamPath [pwd]/${testcase}$parameters(layout_file_extension_zipped) --cellName $testcase --layoutFormat $parameters(output_layout_format) --tool icv --config [pwd]/pvbatch_config_perctopola_icv --udeArgs \"--log [pwd]/pvbatch_perctopola_icv.log --sourceShellFile [pwd]/ude_sourceme\" --tmpLibPath"
    # 2022.07 - Updated output file structure to match CKT P4 release structure.
    puts $fid "mkdir -p ../results/${testcase}/icv/perc_esd"
    puts $fid "find -ipath \"*${parameters(perctopola_prefix)}_icv/${testcase}.LAYOUT_ERRORS\" -exec ln -s \"[pwd]/{}\" ../results/${testcase}/icv/perc_esd/perc_topola_${testcase}_${parameters(metal_stack)}.rpt \\;"
    puts $fid "find -ipath \"*${parameters(perctopola_prefix)}_icv/perc_reports/topo_results.txt\" -exec ln -s \"[pwd]/{}\" ../results/${testcase}/icv/perc_esd/perc_topola_${testcase}_${parameters(metal_stack)}.results \\;"
    puts $fid "find -ipath \"*${parameters(perctopola_prefix)}_icv/perc_reports/topo_results.html\" -exec ln -s \"[pwd]/{}\" ../results/${testcase}/icv/perc_esd/perc_topola_${testcase}_${parameters(metal_stack)}.results.html \\;"
    puts $fid "find -ipath \"*${parameters(perctopola_prefix)}_icv/perc_reports/esd_network_report.txt\" -exec ln -s \"[pwd]/{}\" ../results/${testcase}/icv/perc_esd/perc_topola_${testcase}_${parameters(metal_stack)}.esd_network.results \\;"
    puts $fid "find -ipath \"*${parameters(perctopola_prefix)}_icv/perc_reports/esd_network_report.html\" -exec ln -s \"[pwd]/{}\" ../results/${testcase}/icv/perc_esd/perc_topola_${testcase}_${parameters(metal_stack)}.esd_network.results.html \\;"
    puts $fid "ln -s [pwd]/../${testcase}.log ../results/${testcase}/icv/perc_esd/perc_topola_${testcase}_${parameters(metal_stack)}.log"
    close $fid
    file attributes pv_perctopola_icv.tcsh -permissions +x
    catch {exec ./pv_perctopola_icv.tcsh >& pv_perctopola_icv.log &}
    # Delay no longer required with lib.defs access fix: https://jira.internal.synopsys.com/browse/P10020416-27925
    #after 120000
  }
  
  if {[info exists parameters(perctopola_calibre)] && $parameters(perctopola_calibre)} {
    Write_Logs "INFO: Running PERCTOPOLA_CALIBRE on ${testcase}..."
    if {[catch {open pvbatch_config_perctopola_calibre w} fid]} {
      Write_Logs "***** $fid"
      exit
    }
    puts $fid "set calexExtraArg \"$parameters(perctopola_calex_extra_arguments)\""
    
    # 2022.03-2 - Removed FOUNDRY_DEFAULT from virtual_connect parameter in parameters file template, so need to check for missing parameter or empty string.
    if {[info exists parameters(virtual_connect_calibre)] && ($parameters(virtual_connect_calibre) != "")} {
      puts $fid "set virtualConnect $parameters(virtual_connect_calibre)"
    }
    
    close $fid
    if {[catch {open pv_perctopola_calibre.tcsh w} fid]} {
      Write_Logs "***** $fid"
      exit
    }
    puts $fid "#!/bin/tcsh"
    puts $fid "module unload msip_cd_pv"
    puts $fid "module load msip_cd_pv/$parameters(msip_cd_pv_version)"
    puts $fid "pvbatch --projectType $parameters(project_type) --projectName $parameters(project_name) --releaseName $parameters(release_name) --metalStack $parameters(metal_stack) --type perc --prefix $parameters(perctopola_prefix) --streamPath [pwd]/${testcase}$parameters(layout_file_extension_zipped) --cellName $testcase --layoutFormat $parameters(output_layout_format) --tool calibre --config [pwd]/pvbatch_config_perctopola_calibre --udeArgs \"--log [pwd]/pvbatch_perctopola_calibre.log --sourceShellFile [pwd]/ude_sourceme\" --tmpLibPath"
    # 2022.07 - Updated output file structure to match CKT P4 release structure.
    puts $fid "mkdir -p ../results/${testcase}/calibre/perc_esd"
    puts $fid "find -ipath \"*${parameters(perctopola_prefix)}_calibre/perc.sum\" -exec ln -s \"[pwd]/{}\" ../results/${testcase}/calibre/perc_esd/perc_topola_${testcase}_${parameters(metal_stack)}.perc.sum \\;"
    puts $fid "find -ipath \"*${parameters(perctopola_prefix)}_calibre/cell.results\" -exec ln -s \"[pwd]/{}\" ../results/${testcase}/calibre/perc_esd/perc_topola_${testcase}_${parameters(metal_stack)}.cell.results \\;"
    puts $fid "ln -s [pwd]/../${testcase}.log ../results/${testcase}/calibre/perc_esd/perc_topola_${testcase}_${parameters(metal_stack)}.log"
    close $fid
    file attributes pv_perctopola_calibre.tcsh -permissions +x
    catch {exec ./pv_perctopola_calibre.tcsh >& pv_perctopola_calibre.log &}
    # Delay no longer required with lib.defs access fix: https://jira.internal.synopsys.com/browse/P10020416-27925
    #after 120000
  }
}
# end Run_PV

# 2022.03-1 - Adds log_text to terminal and script log file.
# newline argument defaults to empty string, such that no additional newline is added prior to writing the log. If desired, proc should be called with \n passed to newline.
proc Write_Log {log_text {newline ""}} {
  global Log_Fid
  
  # Get date and time.
  set date_time [clock format [clock seconds]]
  
  # Output to terminal and script log file.
  puts "${newline}\[$date_time\] $log_text"
  puts $Log_Fid "${newline}\[$date_time\] $log_text"
} 
# end Write_Log

# 2022.03-3 -  Adds log_text to terminal, script log file and testcase log file.
# newline argument defaults to empty string, such that no additional newline is added prior to writing the log. If desired, proc should be called with \n passed to newline.
proc Write_Logs {log_text {newline ""}} {
  global Log_Fid
  global Testcase_Log_Fid
  
  # Get date and time.
  set date_time [clock format [clock seconds]]
  
  # Output to terminal, script log file and testcase log file.
  puts "${newline}\[$date_time\] $log_text"
  puts $Log_Fid "${newline}\[$date_time\] $log_text"
  puts $Testcase_Log_Fid "${newline}\[$date_time\] $log_text"
} 
# end Write_Logs

# Main script start.

# 2022.03-1 - Create script log file.
if {[catch {open crd_abutment.log w} Log_Fid]} {
  puts "***** $Log_Fid"
  exit
}

# 2022.03-1 - Add script version to script log file.
Write_Log "INFO: Running CRD Abutment Verification Script version: $Script_Version"

# Read in parameters.
# 2022.07 - Parameters file must be in working directory.
#if {[catch {open ${script_dir}/crd_abutment_parameters.csv r} fid]} {
if {[catch {open crd_abutment_parameters.csv r} fid]} {
  Write_Log "***** $fid"
  exit
}
set original_parameters_file [read -nonewline $fid]
close $fid

# 2022.07 - Read in floorplans.
source ${RealBin}/ddr-crd_abutment_floorplans.tcl

# 2022.03-3 - Add parameters file contents to script log file.
Write_Log "INFO: Parameters file contents:\n$original_parameters_file"

set parameter_names_values [split $original_parameters_file \n]
foreach parameter_name_value $parameter_names_values {
  set parameter_name_value [split $parameter_name_value ,]
  set name [lindex $parameter_name_value 0]
  set value [lindex $parameter_name_value 1]
  set parameters($name) $value
}

#Process parameters.

# 2022.04-1 - Setting version of ICC2, ICVWB and msip_cd_pv tools to support result reproducibility.
# 2022.04-3 - Updated msip_cd_pv version to 2022.03.
# 2022.07 - Updated ICC2 to 2022.03-SP2, ICVWB to 2022.03-SP1 and msip_cd_pv to 2022.05.
# 2022.08 - Updated ICC2 to 2022.03-SP3.
set parameters(icc2_version) 2022.03-SP3
set parameters(icvwb_version) 2022.03-SP1
if {$parameters(msip_cd_pv_version) == ""} {
  set parameters(msip_cd_pv_version) 2022.05
}

# Calculate uu_per_dbu based on uu of 1um.
set parameters(uu_per_dbu) [expr $parameters(dbu) / 1e-6]

# 2022.07 - Set output layout format parameters.
switch -- $parameters(output_layout_format) {
  GDS {
    set parameters(layout_file_extension) .gds
    set parameters(layout_file_extension_zipped) .gds.gz
  }
  OASIS {
    set parameters(layout_file_extension) .oas
    set parameters(layout_file_extension_zipped) .oas
  }
  default {
    Write_Log "ERROR: Illegal output_layout_format parameter value. Exiting." \n
    exit
  }  
}

# 2022.03-3 - Download of Perforce files.
# Check parameters for // to indicate Perforce paths.
if {[regexp {//} [array get parameters]]} {
  Write_Log "INFO: Downloading Perforce files..." \n
  
  file mkdir perforce_files
  cd perforce_files
  
  # Get parameter names for collaterals.
  set parameter_names [concat [array names parameters cdl_*] [array names parameters def_*] [array names parameters gds_*] [array names parameters lef_*]]
  
  # Iterate through collaterals.
  foreach parameter_name $parameter_names {
    # Check for // to indicate Perforce path.
    if {[regexp {^//} $parameters($parameter_name)]} {
      # Add Perforce path to list.
      lappend perforce_paths $parameters($parameter_name)
      
      # Update parameter to point to download location.
      set parameters($parameter_name) [file join [pwd] [file tail $parameters($parameter_name)]]
    }
  }
  
  # Download Perforce collaterals.
  set perforce_paths [lsort -unique $perforce_paths]
  foreach perforce_path $perforce_paths {
    #exec p4 -p p4p-us01:1999 print -o [file tail $perforce_path] $perforce_path >>& perforce.log
    Write_Log [exec p4 -p p4p-us01:1999 print -o [file tail $perforce_path] $perforce_path]
  }
  
  Write_Log "INFO: Download of Perforce files complete."
  
  cd ..
}

# Parse DEF files to create list of components.
foreach macro [split $parameters(testcases_stdcell_fill)] {
  if {[catch {open $parameters(def_$macro) r} fid]} {
    Write_Log "***** $fid"
    exit
  }
  set macro_def [read -nonewline $fid]
  close $fid

  set components_section 0
  foreach line [split $macro_def \n] {
    if {$components_section} {
      if {[regexp -- {- \S+ (\S+) } $line match component]} {
        lappend parameters(def_components_$macro) $component
      }
      if {[regexp {END COMPONENTS} $line match]} {
        break
      }
    } else {
      if {[regexp {^COMPONENTS} $line match]} {
        set components_section 1
      }
    }
  }
  set parameters(def_components_$macro) [lsort -unique $parameters(def_components_$macro)]
}

# Uniquify input CDL files.
if {$parameters(uniquify_input_cdl)} {
  Write_Log "INFO: Uniquifying input CDL files..."
  file mkdir uniquified_input_CDL
  cd uniquified_input_CDL

  # Create list of macros.
  set macro_list [list]
  foreach testcase [split $parameters(testcases_pv_only)] {
    lappend macro_list $testcase
  }
  foreach testcase [split $parameters(testcases_wrapper)] {
    lappend macro_list $testcase
    regexp {wrapper_(.+)} $testcase match macro
    lappend macro_list $macro
  }
  set macro_list [lsort -unique $macro_list]
  foreach macro $macro_list {
    Write_Log "INFO: Uniquifying $macro CDL..."
    exec netl_namemap -pre ${macro}_ -top $macro -fltf $parameters(uniquify_input_cdl_filter_file) $parameters(cdl_$macro) ${macro}.cdl
    set parameters(cdl_$macro) [file join [pwd] ${macro}.cdl]
  }
  cd ..
}

# Uniquify input GDS files.
if {$parameters(uniquify_input_gds)} {
  Write_Log "INFO: Uniquifying input GDS files..."
  file mkdir uniquified_input_GDS
  cd uniquified_input_GDS
  
  # 2022-04 - Reverting behavior to uniquify all GDS files in parameters file rather than identifying macros in testcases.
  #set gds_files [array names parameters gds_*]
  # Create list of macros.
  #set macro_list [list]
  #foreach testcase [split $parameters(testcases_abutment)] {
  #  set macro_list [concat $macro_list $macros($testcase)]
  #}
  #foreach testcase [split $parameters(testcases_abutment_stdcell)] {
  #  set macro_list [concat $macro_list $macros($testcase)]
  #}
  #foreach testcase [split $parameters(testcases_abutment_wrapper)] {
  #  lappend macro_list $testcase
  #  regexp {wrapper_(.+)} $testcase match floorplan
  #  set macro_list [concat $macro_list $macros($floorplan)]
  #}
  #foreach testcase [split $parameters(testcases_pv_only)] {
  #  lappend macro_list $testcase
  #}
  #foreach testcase [split $parameters(testcases_stdcell)] {
  #  lappend macro_list $testcase
  #}
  #foreach testcase [split $parameters(testcases_stdcell_fill)] {
  #  set macro_list [concat $macro_list $parameters(def_components_$testcase)]
  #}
  #foreach testcase [array names parameters testcases_utility_*] {
  #  foreach macro_sublist [lrange [split $parameters($testcase) :] 1 end] {
  #    set macro_list [concat $macro_list $macro_sublist]
  #  }
  #}
  #foreach testcase [split $parameters(testcases_wrapper)] {
  #  lappend macro_list $testcase
  #  regexp {wrapper_(.+)} $testcase match macro
  #  lappend macro_list $macro
  #}
  #set macro_list [lsort -unique $macro_list]
  #foreach macro $macro_list 
  foreach gds_parameter [array names parameters gds_*] {
    regexp {gds_(.+)} $gds_parameter match macro
    Write_Log "INFO: Uniquifying $macro GDS..."
    # gds_namemap will only work on GDS root cells, so will fail for utility cell/block GDS files, for example.
    # Workaround is to extract macro from GDS file first.
    if {[catch {open icvwb_extract_${macro}.mac w} fid]} {
      Write_Log "***** $fid"
      exit
    }
    puts $fid "layout open $parameters($gds_parameter) ??"
    puts $fid "layout extract ${macro}.pre-uniquified.gds.gz -format gds.gz -cell $macro"
    puts $fid "exit"
    close $fid
      
    if {[catch {open icvwb_extract_${macro}.tcsh w} fid]} {
      Write_Log "***** $fid"
      exit
    }
    puts $fid "#!/bin/tcsh"
    puts $fid "module unload icvwb"
    puts $fid "module load icvwb/$parameters(icvwb_version)"
    puts $fid "icvwb -run icvwb_extract_${macro}.mac -nodisplay -log icvwb_extract_${macro}.log"
    close $fid
    file attributes icvwb_extract_${macro}.tcsh -permissions +x
    exec ./icvwb_extract_${macro}.tcsh
      
    exec gds_namemap -pre ${macro}_ -nolvl $macro ${macro}.pre-uniquified.gds.gz ${macro}.gds.gz
    set parameters($gds_parameter) [file join [pwd] ${macro}.gds.gz]
  }
  cd ..
}

# Create testcase GDS and run PV.
foreach testcase [split $parameters(testcases_abutment)] {
  set Testcase_Log_Fid [Open_Testcase_Log $testcase $Script_Version $original_parameters_file]

  Write_Logs "INFO: Running ${testcase}..." \n
  
  file mkdir $testcase
  cd $testcase

  Generate_Layout floorplans parameters $hard_macros $testcase
  exec mkdir -p ../results/${testcase}/[string tolower $parameters(output_layout_format)]/${parameters(metal_stack)}
  exec ln -s [pwd]/${testcase}$parameters(layout_file_extension_zipped) ../results/${testcase}/[string tolower $parameters(output_layout_format)]/${parameters(metal_stack)}/${testcase}$parameters(layout_file_extension_zipped)
  
  Generate_Empty_CDL $testcase
  Run_PV parameters $testcase

  cd ..
  Write_Logs "INFO: $testcase completed. Note that physical verifications may still be in progress."
  
  close $Testcase_Log_Fid
}

# Create testcase_abutment_wrapper GDS, empty CDL and run PV.
foreach testcase [split $parameters(testcases_abutment_wrapper)] {
  regexp {wrapper_(.+)} $testcase match floorplan
  
  set Testcase_Log_Fid [Open_Testcase_Log $testcase $Script_Version $original_parameters_file]
  
  Write_Logs "INFO: Running ${testcase}..." \n
  
  file mkdir $testcase
  cd $testcase

  Generate_Layout floorplans parameters $hard_macros $floorplan
  set parameters(gds_$floorplan) ${floorplan}.gds.gz
  
  Merge_GDS parameters $floorplan $testcase
  exec mkdir -p ../results/${testcase}/[string tolower $parameters(output_layout_format)]/${parameters(metal_stack)}
  exec ln -s [pwd]/${testcase}$parameters(layout_file_extension_zipped) ../results/${testcase}/[string tolower $parameters(output_layout_format)]/${parameters(metal_stack)}/${testcase}$parameters(layout_file_extension_zipped)
  
  Generate_Empty_CDL $testcase
    
  Run_PV parameters $testcase
  
  cd ..
  Write_Logs "INFO: $testcase completed. Note that physical verifications may still be in progress."
  
  close $Testcase_Log_Fid
}

# Create testcase_wrapper GDS, CDL and run PV.
foreach testcase [split $parameters(testcases_wrapper)] {
  regexp {wrapper_(.+)} $testcase match macro
  
  set Testcase_Log_Fid [Open_Testcase_Log $testcase $Script_Version $original_parameters_file]
  
  Write_Logs "INFO: Running ${testcase}..." \n
  
  file mkdir $testcase
  cd $testcase

  Merge_GDS parameters $macro $testcase
  exec mkdir -p ../results/${testcase}/[string tolower $parameters(output_layout_format)]/${parameters(metal_stack)}
  exec ln -s [pwd]/${testcase}$parameters(layout_file_extension_zipped) ../results/${testcase}/[string tolower $parameters(output_layout_format)]/${parameters(metal_stack)}/${testcase}$parameters(layout_file_extension_zipped)
  
  # Generate testcase CDL.
  if {$parameters(generate_cdl)} {
    Write_Logs "INFO: Generating $testcase CDL..."
    
    # Read in macro CDL.
    if {[catch {open $parameters(cdl_$macro) r} fid]} {
      Write_Logs "***** $fid"
      exit
    }
    set macro_cdl [read -nonewline $fid]
    close $fid
    
    # Get macro pins.
    set pins_section 0
    foreach line [split $macro_cdl \n] {
      if {$pins_section} {
        if {[regexp {\+ (.+)} $line match macro_pins]} {
          lappend macro_pins_list $macro_pins
        } else {
          break
        }
      } else {
        if {[regexp -nocase -- [subst -nobackslashes -nocommands {\.subckt $macro (.+)}] $line match macro_pins]} {
          set macro_pins_list [list $macro_pins]
          set pins_section 1
        }
      }
    }
    
    # Read in original testcase CDL.
    if {[catch {open $parameters(cdl_$testcase) r} fid]} {
      Write_Logs "***** $fid"
      exit
    }
    set testcase_orig_cdl [read -nonewline $fid]
    close $fid
    
    # Create updated testcase CDL.
    if {[catch {open ${testcase}.cdl w} fid]} {
      Write_Logs "***** $fid"
      exit
    }
    puts $fid ".include $parameters(cdl_$macro)"
    set subckt_section 0
    foreach line [split $testcase_orig_cdl \n] {
      # Capture wrapper pins.
      #regexp "\.subckt $testcase (.+)" $line match pins
     
      if {[regexp -nocase -- [subst -nobackslashes -nocommands {\.subckt $testcase\s}] $line]} {
        set subckt_section 1
      }
              
      # Add macro to testcase CDL.
      if {($subckt_section) && ([regexp -nocase -- {\.ends} $line])} {
        #set macro_instance "XDUT"
        #foreach pin [split $pins] {
         # set macro_instance "$macro_instance .${pin}(${pin})"
        #}
        puts $fid "XDUT"
        foreach pin_line $macro_pins_list {
          puts $fid "+ $pin_line"
        }
        puts $fid "+ $macro"
        set subckt_section 0
      }
      puts $fid $line
    }
    close $fid
    
  } else {
    Generate_Empty_CDL $testcase
  }
  
  Run_PV parameters $testcase
  
  cd ..
  Write_Logs "INFO: $testcase completed. Note that physical verifications may still be in progress."
  
  close $Testcase_Log_Fid
}

# Generate standard cell boundary testcase and run PV.
foreach macro [split $parameters(testcases_stdcell)] {
  set testcase boundary_${macro}_stdcell
  
  set Testcase_Log_Fid [Open_Testcase_Log $testcase $Script_Version $original_parameters_file]
  
  Write_Logs "INFO: Running ${testcase}..." \n
  file mkdir $testcase
  cd $testcase
  #set macro $macros($testcase)
  
  # Optionally generate size-only LEF.
  if {$parameters(generate_lef)} {
    Generate_LEF parameters $macro
    set parameters(lef_$macro) ${macro}.lef
  }
  
  Generate_Reference_Lib parameters $macro
  Generate_Stdcell_Ring parameters $power_supplies $macro $testcase
  exec mkdir -p ../results/${testcase}/[string tolower $parameters(output_layout_format)]/${parameters(metal_stack)}
  exec ln -s [pwd]/${testcase}$parameters(layout_file_extension_zipped) ../results/${testcase}/[string tolower $parameters(output_layout_format)]/${parameters(metal_stack)}/${testcase}$parameters(layout_file_extension_zipped)
  
  Generate_Empty_CDL $testcase
  Run_PV parameters $testcase
  
  cd ..
  Write_Logs "INFO: $testcase completed. Note that physical verifications may still be in progress."
  
  close $Testcase_Log_Fid
}

# Generate abutment standard cell boundary testcase and run PV.
foreach floorplan [split $parameters(testcases_abutment_stdcell)] {
  set testcase boundary_${floorplan}_stdcell
  
  set Testcase_Log_Fid [Open_Testcase_Log $testcase $Script_Version $original_parameters_file]
  
  Write_Logs "INFO: Running ${testcase}..." \n
  file mkdir $testcase
  cd $testcase
  
  Generate_Layout floorplans parameters $hard_macros $floorplan
  set parameters(gds_$floorplan) ${floorplan}.gds.gz
  Generate_LEF parameters $floorplan
  set parameters(lef_$floorplan) ${floorplan}.lef
  Generate_Reference_Lib parameters $floorplan
  Generate_Stdcell_Ring parameters $power_supplies $floorplan $testcase
  exec mkdir -p ../results/${testcase}/[string tolower $parameters(output_layout_format)]/${parameters(metal_stack)}
  exec ln -s [pwd]/${testcase}$parameters(layout_file_extension_zipped) ../results/${testcase}/[string tolower $parameters(output_layout_format)]/${parameters(metal_stack)}/${testcase}$parameters(layout_file_extension_zipped)
  
  Generate_Empty_CDL $testcase
  Run_PV parameters $testcase
  
  cd ..
  Write_Logs "INFO: $testcase completed. Note that physical verifications may still be in progress."
  
  close $Testcase_Log_Fid
}

# Generate standard cell fill testcase and run PV.
foreach macro [split $parameters(testcases_stdcell_fill)] {
  set Testcase_Log_Fid [Open_Testcase_Log $macro $Script_Version $original_parameters_file]
  
  Write_Logs "INFO: Running Standard Cell Fill on ${macro}..." \n
  file mkdir $macro
  cd $macro
    
  Generate_Reference_Lib parameters $parameters(def_components_$macro)
  Generate_Stdcell_Fill parameters $power_supplies $macro
  exec mkdir -p ../results/${macro}/[string tolower $parameters(output_layout_format)]/${parameters(metal_stack)}
  exec ln -s [pwd]/${macro}$parameters(layout_file_extension_zipped) ../results/${macro}/[string tolower $parameters(output_layout_format)]/${parameters(metal_stack)}/${macro}$parameters(layout_file_extension_zipped)
  
  Generate_Empty_CDL $macro
  Run_PV parameters $macro
  
  cd ..
  Write_Logs "INFO: Standard Cell Fill on $macro completed. Note that physical verifications may still be in progress."
  
  close $Testcase_Log_Fid
}

foreach testcase [split $parameters(testcases_pv_only)] {
  set Testcase_Log_Fid [Open_Testcase_Log $testcase $Script_Version $original_parameters_file]
  
  Write_Logs "INFO: Running PV only flow on ${testcase}..." \n
  
  file mkdir $testcase
  cd $testcase
  
  # create link to GDS and CDL.
  exec ln -s $parameters(gds_$testcase) ${testcase}.gds.gz
  exec mkdir -p ../results/${testcase}/[string tolower $parameters(output_layout_format)]/${parameters(metal_stack)}
  exec ln -s [pwd]/${testcase}$parameters(layout_file_extension_zipped) ../results/${testcase}/[string tolower $parameters(output_layout_format)]/${parameters(metal_stack)}/${testcase}$parameters(layout_file_extension_zipped)
  
  exec ln -s $parameters(cdl_$testcase) ${testcase}.cdl
  
  Run_PV parameters $testcase
  
  cd ..
  Write_Logs "INFO: Running PV only flow on $testcase completed. Note that physical verifications may still be in progress."
  
  close $Testcase_Log_Fid
}

foreach testcase [array names parameters testcases_utility_*] {
  # Move to next testcase if testcase_utility_* parameter is empty.
  if {$parameters($testcase) == ""} {
    continue
  }
  
  set Testcase_Log_Fid [Open_Testcase_Log $testcase $Script_Version $original_parameters_file]
  
  Write_Logs "INFO: Running ${testcase}..." \n
  
  file mkdir $testcase
  cd $testcase
  
  set mode [lindex [split $parameters($testcase) :] 0]
  set macro_list [list]
  foreach macro_sublist [lrange [split $parameters($testcase) :] 1 end] {
    set macro_list [concat $macro_list $macro_sublist]
  }
  set macro_list [lsort -unique $macro_list]
   
  # Generate testcase GDS.
  Write_Logs "INFO: Generating $testcase GDS..."
  if {[catch {open icvwb.mac w} fid]} {
    Write_Logs "***** $fid"
    exit
  }
  puts $fid "default filter_layer_hier 1"
  puts $fid "default layer_hier_level 0"
  puts $fid "default find_limit unlimited"
  puts $fid "set layoutID \[layout new $testcase -dbu $parameters(dbu) -uu_per_dbu $parameters(uu_per_dbu)\]"
  
  foreach macro $macro_list {
    puts $fid "set pinID_$macro \[layout new pin_$macro -dbu $parameters(dbu) -uu_per_dbu $parameters(uu_per_dbu)\]"
    puts $fid "layout open $parameters(gds_$macro) $macro"
    puts $fid "set boundary_bbox \[layer bbox $parameters(boundary_layer) -levels 0\]"
    puts $fid "set x_$macro \[lindex \$boundary_bbox 2\]"
    puts $fid "set y_$macro \[lindex \$boundary_bbox 3\]"
    if {$parameters(macro_text_layers) != ""} {
      puts $fid "if \{\[find init -type text -layer \"$parameters(macro_text_layers)\"\]\} \{"
      puts $fid "  find table select *"
      puts $fid "  select copy \"0 0\""
      puts $fid "  layout active \$pinID_$macro"
      puts $fid "  select paste \"0 0\""
      puts $fid "\}"
    }
  }
  puts $fid "layout active \$layoutID"
  
  # 2022.04-3 - To prevent ICVWB error for adding same reference layout, compiling list of unique GDS files prior to adding them.
  foreach macro $macro_list {
    #puts $fid "layout reference add $parameters(gds_$macro)"
    lappend reference_layouts $parameters(gds_$macro)
    puts $fid "layout reference add \$pinID_$macro"
  }
  foreach reference_layout [lsort -unique $reference_layouts] {
    puts $fid "layout reference add $reference_layout"
  }
  
  puts $fid "set x 0"
  puts $fid "set y 0"
  
  # $mode == "full"
  if {$mode == "full"} {
    for {set i 0} {$i < [llength $macro_list]} {incr i} {
      for {set j $i} {$j < [llength $macro_list]} {incr j} {
        set macro1 [lindex $macro_list $i]
        set macro2 [lindex $macro_list $j]
        
        puts $fid "cell add sref $macro1     \"0 \$y\" 0 0"
        puts $fid "cell add sref pin_$macro1 \"0 \$y\" 0 0"
        puts $fid "cell add sref $macro2     \"\[expr 2 * \$x_$macro1\] \$y\" 180 1"
        puts $fid "cell add sref pin_$macro2 \"\[expr 2 * \$x_$macro1\] \$y\" 180 1"
        puts $fid "cell add sref $macro1     \"\[expr 3 * \$x_$macro1\] \$y\" 180 1"
        puts $fid "cell add sref pin_$macro1 \"\[expr 3 * \$x_$macro1\] \$y\" 180 1"
        puts $fid "cell add sref $macro2     \"\[expr 4 * \$x_$macro1\] \$y\" 180 1"
        puts $fid "cell add sref pin_$macro2 \"\[expr 4 * \$x_$macro1\] \$y\" 180 1"
        puts $fid "cell add sref $macro1     \"\[expr 5 * \$x_$macro1\] \[expr \$y + \$y_$macro1\]\" 180 0"
        puts $fid "cell add sref pin_$macro1 \"\[expr 5 * \$x_$macro1\] \[expr \$y + \$y_$macro1\]\" 180 0"
        puts $fid "cell add sref $macro2     \"\[expr 6 * \$x_$macro1\] \$y\" 180 1"
        puts $fid "cell add sref pin_$macro2 \"\[expr 6 * \$x_$macro1\] \$y\" 180 1"
        puts $fid "cell add sref $macro1     \"\[expr 6 * \$x_$macro1\] \$y\" 0 0"
        puts $fid "cell add sref pin_$macro1 \"\[expr 6 * \$x_$macro1\] \$y\" 0 0"
        puts $fid "cell add sref $macro2     \"\[expr 8 * \$x_$macro1\] \[expr \$y + \$y_$macro1\]\" 180 0"
        puts $fid "cell add sref pin_$macro2 \"\[expr 8 * \$x_$macro1\] \[expr \$y + \$y_$macro1\]\" 180 0"
        puts $fid "cell add sref $macro1     \"\[expr 8 * \$x_$macro1\] \$y\" 0 0"
        puts $fid "cell add sref pin_$macro1 \"\[expr 8 * \$x_$macro1\] \$y\" 0 0"
        puts $fid "cell add sref $macro1     \"\[expr 9 * \$x_$macro1\] \[expr \$y + \$y_$macro1\]\" 0 1"
        puts $fid "cell add sref pin_$macro1 \"\[expr 9 * \$x_$macro1\] \[expr \$y + \$y_$macro1\]\" 0 1"
        puts $fid "cell add sref $macro2     \"0 \[expr \$y + 2 * \$y_$macro1\]\" 0 1"
        puts $fid "cell add sref pin_$macro2 \"0 \[expr \$y + 2 * \$y_$macro1\]\" 0 1"
        puts $fid "cell add sref $macro1     \"\$x_$macro1 \[expr \$y + 2 * \$y_$macro1\]\" 0 1"
        puts $fid "cell add sref pin_$macro1 \"\$x_$macro1 \[expr \$y + 2 * \$y_$macro1\]\" 0 1"
        puts $fid "cell add sref $macro2     \"\[expr 3 * \$x_$macro1\] \[expr \$y + \$y_$macro1\]\" 180 1"
        puts $fid "cell add sref pin_$macro2 \"\[expr 3 * \$x_$macro1\] \[expr \$y + \$y_$macro1\]\" 180 1"
        puts $fid "cell add sref $macro1     \"\[expr 4 * \$x_$macro1\] \[expr \$y + \$y_$macro1\]\" 180 1"
        puts $fid "cell add sref pin_$macro1 \"\[expr 4 * \$x_$macro1\] \[expr \$y + \$y_$macro1\]\" 180 1"
        puts $fid "cell add sref $macro2     \"\[expr 4 * \$x_$macro1\] \[expr \$y + 2 * \$y_$macro1\]\" 0 1"
        puts $fid "cell add sref pin_$macro2 \"\[expr 4 * \$x_$macro1\] \[expr \$y + 2 * \$y_$macro1\]\" 0 1"
        puts $fid "cell add sref $macro2     \"\[expr 6 * \$x_$macro1\] \[expr \$y + 2 * \$y_$macro1\]\" 180 0"
        puts $fid "cell add sref pin_$macro2 \"\[expr 6 * \$x_$macro1\] \[expr \$y + 2 * \$y_$macro1\]\" 180 0"
        puts $fid "cell add sref $macro2     \"\[expr 7 * \$x_$macro1\] \[expr \$y + \$y_$macro1\]\" 180 1"
        puts $fid "cell add sref pin_$macro2 \"\[expr 7 * \$x_$macro1\] \[expr \$y + \$y_$macro1\]\" 180 1"
        puts $fid "cell add sref $macro1     \"\[expr 8 * \$x_$macro1\] \[expr \$y + \$y_$macro1\]\" 180 1"
        puts $fid "cell add sref pin_$macro1 \"\[expr 8 * \$x_$macro1\] \[expr \$y + \$y_$macro1\]\" 180 1"
        puts $fid "cell add sref $macro2     \"\[expr 9 * \$x_$macro1\] \[expr \$y + 2 * \$y_$macro1\]\" 180 0"
        puts $fid "cell add sref pin_$macro2 \"\[expr 9 * \$x_$macro1\] \[expr \$y + 2 * \$y_$macro1\]\" 180 0"
        puts $fid "cell add sref $macro2     \"\[expr 10 * \$x_$macro1\] \[expr \$y + \$y_$macro1\]\" 180 1"
        puts $fid "cell add sref pin_$macro2 \"\[expr 10 * \$x_$macro1\] \[expr \$y + \$y_$macro1\]\" 180 1"
        puts $fid "cell add sref $macro2     \"\$x_$macro1 \[expr \$y + 2 * \$y_$macro1\]\" 180 1"
        puts $fid "cell add sref pin_$macro2 \"\$x_$macro1 \[expr \$y + 2 * \$y_$macro1\]\" 180 1"
        puts $fid "cell add sref $macro1     \"\$x_$macro1 \[expr \$y + 3 * \$y_$macro1\]\" 0 1"
        puts $fid "cell add sref pin_$macro1 \"\$x_$macro1 \[expr \$y + 3 * \$y_$macro1\]\" 0 1"
        puts $fid "cell add sref $macro2     \"\[expr 2 * \$x_$macro1\] \[expr \$y + 3 * \$y_$macro1\]\" 0 1"
        puts $fid "cell add sref pin_$macro2 \"\[expr 2 * \$x_$macro1\] \[expr \$y + 3 * \$y_$macro1\]\" 0 1"
        puts $fid "cell add sref $macro1     \"\[expr 4 * \$x_$macro1\] \[expr \$y + 3 * \$y_$macro1\]\" 180 0"
        puts $fid "cell add sref pin_$macro1 \"\[expr 4 * \$x_$macro1\] \[expr \$y + 3 * \$y_$macro1\]\" 180 0"
        puts $fid "cell add sref $macro2     \"\[expr 5 * \$x_$macro1\] \[expr \$y + 3 * \$y_$macro1\]\" 180 0"
        puts $fid "cell add sref pin_$macro2 \"\[expr 5 * \$x_$macro1\] \[expr \$y + 3 * \$y_$macro1\]\" 180 0"
        puts $fid "cell add sref $macro1     \"\[expr 5 * \$x_$macro1\] \[expr \$y + 2 * \$y_$macro1\]\" 0 0"
        puts $fid "cell add sref pin_$macro1 \"\[expr 5 * \$x_$macro1\] \[expr \$y + 2 * \$y_$macro1\]\" 0 0"
        puts $fid "cell add sref $macro1     \"\[expr 7 * \$x_$macro1\] \[expr \$y + 3 * \$y_$macro1\]\" 180 0"
        puts $fid "cell add sref pin_$macro1 \"\[expr 7 * \$x_$macro1\] \[expr \$y + 3 * \$y_$macro1\]\" 180 0"
        puts $fid "cell add sref $macro1     \"\[expr 7 * \$x_$macro1\] \[expr \$y + 2 * \$y_$macro1\]\" 0 0"
        puts $fid "cell add sref pin_$macro1 \"\[expr 7 * \$x_$macro1\] \[expr \$y + 2 * \$y_$macro1\]\" 0 0"
        puts $fid "cell add sref $macro1     \"\[expr 8 * \$x_$macro1\] \[expr \$y + 2 * \$y_$macro1\]\" 0 0"
        puts $fid "cell add sref pin_$macro1 \"\[expr 8 * \$x_$macro1\] \[expr \$y + 2 * \$y_$macro1\]\" 0 0"
        puts $fid "cell add sref $macro1     \"\[expr 10 * \$x_$macro1\] \[expr \$y + 2 * \$y_$macro1\]\" 180 1"
        puts $fid "cell add sref pin_$macro1 \"\[expr 10 * \$x_$macro1\] \[expr \$y + 2 * \$y_$macro1\]\" 180 1"
        
        puts $fid "hierarchy explode -cells pin_$macro1"
        puts $fid "hierarchy explode -cells pin_$macro2"
        
        puts $fid "set y \[expr \$y + 3 * \$y_$macro1\]"
      }
    }
  }
  # end $mode == "full"
  
  # $mode == "block_ew"
  if {$mode == "block_ew"} {
    # Utility block abutments for blocks for the same hard macro.
    foreach macro_sublist [lrange [split $parameters($testcase) :] 1 end] {
      for {set i 0} {$i < [llength $macro_sublist]} {incr i} {
        for {set j $i} {$j < [llength $macro_sublist]} {incr j} {
          set macro1 [lindex $macro_sublist $i]
          set macro2 [lindex $macro_sublist $j]
          
          puts $fid "cell add sref $macro1     \"0 \$y\" 0 0"
          puts $fid "cell add sref pin_$macro1 \"0 \$y\" 0 0"
          puts $fid "cell add sref $macro2     \"\$x_$macro1 \$y\" 0 0"
          puts $fid "cell add sref pin_$macro2 \"\$x_$macro1 \$y\" 0 0"
          puts $fid "cell add sref $macro1     \"\[expr 2 * \$x_$macro1\] \$y\" 0 0"
          puts $fid "cell add sref pin_$macro1 \"\[expr 2 * \$x_$macro1\] \$y\" 0 0"
          puts $fid "cell add sref $macro2     \"\[expr 3 * \$x_$macro1\] \$y\" 0 0"
          puts $fid "cell add sref pin_$macro2 \"\[expr 3 * \$x_$macro1\] \$y\" 0 0"
          puts $fid "cell add sref $macro1     \"\[expr 4 * \$x_$macro1\] \$y\" 0 0"
          puts $fid "cell add sref pin_$macro1 \"\[expr 4 * \$x_$macro1\] \$y\" 0 0"
          puts $fid "cell add sref $macro2     \"0 \[expr \$y + 2 * \$y_$macro1\]\" 0 1"
          puts $fid "cell add sref pin_$macro2 \"0 \[expr \$y + 2 * \$y_$macro1\]\" 0 1"
          puts $fid "cell add sref $macro1     \"\$x_$macro1 \[expr \$y + 2 * \$y_$macro1\]\" 0 1"
          puts $fid "cell add sref pin_$macro1 \"\$x_$macro1 \[expr \$y + 2 * \$y_$macro1\]\" 0 1"
          puts $fid "cell add sref $macro1     \"\[expr 2 * \$x_$macro1\] \[expr \$y + 2 * \$y_$macro1\]\" 0 1"
          puts $fid "cell add sref pin_$macro1 \"\[expr 2 * \$x_$macro1\] \[expr \$y + 2 * \$y_$macro1\]\" 0 1"
          puts $fid "cell add sref $macro2     \"\[expr 3 * \$x_$macro1\] \[expr \$y + 2 * \$y_$macro1\]\" 0 1"
          puts $fid "cell add sref pin_$macro2 \"\[expr 3 * \$x_$macro1\] \[expr \$y + 2 * \$y_$macro1\]\" 0 1"
          puts $fid "cell add sref $macro1     \"\[expr 4 * \$x_$macro1\] \[expr \$y + 2 * \$y_$macro1\]\" 0 1"
          puts $fid "cell add sref pin_$macro1 \"\[expr 4 * \$x_$macro1\] \[expr \$y + 2 * \$y_$macro1\]\" 0 1"
          puts $fid "cell add sref $macro1     \"0 \[expr \$y + 3 * \$y_$macro1\]\" 0 1"
          puts $fid "cell add sref pin_$macro1 \"0 \[expr \$y + 3 * \$y_$macro1\]\" 0 1"
          puts $fid "cell add sref $macro2     \"\$x_$macro1 \[expr \$y + 3 * \$y_$macro1\]\" 0 1"
          puts $fid "cell add sref pin_$macro2 \"\$x_$macro1 \[expr \$y + 3 * \$y_$macro1\]\" 0 1"
          puts $fid "cell add sref $macro1     \"\[expr 2 * \$x_$macro1\] \[expr \$y + 3 * \$y_$macro1\]\" 0 1"
          puts $fid "cell add sref pin_$macro1 \"\[expr 2 * \$x_$macro1\] \[expr \$y + 3 * \$y_$macro1\]\" 0 1"
          puts $fid "cell add sref $macro2     \"\[expr 3 * \$x_$macro1\] \[expr \$y + 3 * \$y_$macro1\]\" 0 1"
          puts $fid "cell add sref pin_$macro2 \"\[expr 3 * \$x_$macro1\] \[expr \$y + 3 * \$y_$macro1\]\" 0 1"
          puts $fid "cell add sref $macro1     \"\[expr 4 * \$x_$macro1\] \[expr \$y + 3 * \$y_$macro1\]\" 0 1"
          puts $fid "cell add sref pin_$macro1 \"\[expr 4 * \$x_$macro1\] \[expr \$y + 3 * \$y_$macro1\]\" 0 1"
          puts $fid "cell add sref $macro2     \"0 \[expr \$y + 3 * \$y_$macro1\]\" 0 0"
          puts $fid "cell add sref pin_$macro2 \"0 \[expr \$y + 3 * \$y_$macro1\]\" 0 0"
          puts $fid "cell add sref $macro2     \"\$x_$macro1 \[expr \$y + 3 * \$y_$macro1\]\" 0 0"
          puts $fid "cell add sref pin_$macro2 \"\$x_$macro1 \[expr \$y + 3 * \$y_$macro1\]\" 0 0"
          puts $fid "cell add sref $macro1     \"\[expr 2 * \$x_$macro1\] \[expr \$y + 3 * \$y_$macro1\]\" 0 0"
          puts $fid "cell add sref pin_$macro1 \"\[expr 2 * \$x_$macro1\] \[expr \$y + 3 * \$y_$macro1\]\" 0 0"
          puts $fid "cell add sref $macro1     \"\[expr 3 * \$x_$macro1\] \[expr \$y + 3 * \$y_$macro1\]\" 0 0"
          puts $fid "cell add sref pin_$macro1 \"\[expr 3 * \$x_$macro1\] \[expr \$y + 3 * \$y_$macro1\]\" 0 0"
          puts $fid "cell add sref $macro1     \"\[expr 4 * \$x_$macro1\] \[expr \$y + 3 * \$y_$macro1\]\" 0 0"
          puts $fid "cell add sref pin_$macro1 \"\[expr 4 * \$x_$macro1\] \[expr \$y + 3 * \$y_$macro1\]\" 0 0"
          
          puts $fid "hierarchy explode -cells pin_$macro1"
          puts $fid "hierarchy explode -cells pin_$macro2"
          
          puts $fid "set y \[expr \$y + 4 * \$y_$macro1\]"
        }
      } 
    }
  
    # Utility block abutments for blocks for different hard macros.
    # i iterates through sublists of utility blocks. Note that i is set to 1, not 0, as first element of the split $parameters($testcase) is the mode.
    for {set i 1} {$i < [expr [llength [split $parameters($testcase) :]] - 1]} {incr i} {
      # Iterate through each utility block in "i"th sublist.
      foreach macro1 [lindex [split $parameters($testcase) :] $i] {
        # j iterates through sublists after the "i"th sublist.
        for {set j [expr $i + 1]} {$j < [llength [split $parameters($testcase) :]]} {incr j} {
          # Iterate through each utility block in the "j"th sublist
          foreach macro2 [lindex [split $parameters($testcase) :] $j] {
          
            puts $fid "cell add sref $macro1     \"0 \$y\" 0 0"
            puts $fid "cell add sref pin_$macro1 \"0 \$y\" 0 0"
            puts $fid "cell add sref $macro1     \"\$x_$macro1 \$y\" 0 0"
            puts $fid "cell add sref pin_$macro1 \"\$x_$macro1 \$y\" 0 0"
            puts $fid "cell add sref $macro2     \"0 \[expr \$y + \$y_$macro1 + \$y_$macro2\]\" 0 1"
            puts $fid "cell add sref pin_$macro2 \"0 \[expr \$y + \$y_$macro1 + \$y_$macro2\]\" 0 1"
            puts $fid "cell add sref $macro2     \"\$x_$macro1 \[expr \$y + \$y_$macro1 + \$y_$macro2\]\" 0 1"
            puts $fid "cell add sref pin_$macro2 \"\$x_$macro1 \[expr \$y + \$y_$macro1 + \$y_$macro2\]\" 0 1"
            puts $fid "cell add sref $macro1     \"0 \[expr \$y + 2 * \$y_$macro1 + \$y_$macro2\]\" 0 1"
            puts $fid "cell add sref pin_$macro1 \"0 \[expr \$y + 2 * \$y_$macro1 + \$y_$macro2\]\" 0 1"
            puts $fid "cell add sref $macro1     \"\$x_$macro1 \[expr \$y + 2 * \$y_$macro1 + \$y_$macro2\]\" 0 1"
            puts $fid "cell add sref pin_$macro1 \"\$x_$macro1 \[expr \$y + 2 * \$y_$macro1 + \$y_$macro2\]\" 0 1"
            puts $fid "cell add sref $macro2     \"0 \[expr \$y + 2 * \$y_$macro1 + 2 * \$y_$macro2\]\" 0 1"
            puts $fid "cell add sref pin_$macro2 \"0 \[expr \$y + 2 * \$y_$macro1 + 2 * \$y_$macro2\]\" 0 1"
            puts $fid "cell add sref $macro2     \"\$x_$macro1 \[expr \$y + 2 * \$y_$macro1 + 2 * \$y_$macro2\]\" 0 1"
            puts $fid "cell add sref pin_$macro2 \"\$x_$macro1 \[expr \$y + 2 * \$y_$macro1 + 2 * \$y_$macro2\]\" 0 1"
            puts $fid "cell add sref $macro1     \"0 \[expr \$y + 2 * \$y_$macro1 + 2 * \$y_$macro2\]\" 0 0"
            puts $fid "cell add sref pin_$macro1 \"0 \[expr \$y + 2 * \$y_$macro1 + 2 * \$y_$macro2\]\" 0 0"
            puts $fid "cell add sref $macro1     \"\$x_$macro1 \[expr \$y + 2 * \$y_$macro1 + 2 * \$y_$macro2\]\" 0 0"
            puts $fid "cell add sref pin_$macro1 \"\$x_$macro1 \[expr \$y + 2 * \$y_$macro1 + 2 * \$y_$macro2\]\" 0 0"
            
            puts $fid "hierarchy explode -cells pin_$macro1"
            puts $fid "hierarchy explode -cells pin_$macro2"
          
            puts $fid "set y \[expr \$y + 3 * \$y_$macro1 + 2 * \$y_$macro2\]"
          }
        }
      }
    }
  }
  # end $mode == "block_ew"
  
  puts $fid "layout extract ${testcase}.gds.gz -format gds.gz -cell $testcase"
  puts $fid "exit"
  close $fid
  
  if {[catch {open icvwb.tcsh w} fid]} {
    Write_Logs "***** $fid"
    exit
  }
  puts $fid "#!/bin/tcsh"
  puts $fid "module unload icvwb"
  puts $fid "module load icvwb/$parameters(icvwb_version)"
  
  # 2022.04-3 - Changed ICVWB to now stop on errors.
  #puts $fid "icvwb -run icvwb.mac -runnohalt -nodisplay -log icvwb.log"
  puts $fid "icvwb -run icvwb.mac -nodisplay -log icvwb.log"
  
  close $fid
  file attributes icvwb.tcsh -permissions +x
  exec ./icvwb.tcsh

  Generate_Empty_CDL $testcase
  Run_PV parameters $testcase

  cd ..
  Write_Logs "INFO: $testcase completed. Note that physical verifications may still be in progress."
  
  close $Testcase_Log_Fid
}

# 2022.03-1 - Close script log file.
Write_Log "INFO: CRD Abutment Verification Script completed." \n
close $Log_Fid

footer
