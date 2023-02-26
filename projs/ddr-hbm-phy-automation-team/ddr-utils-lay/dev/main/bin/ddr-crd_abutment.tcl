#!/depot/tcl8.6.3/bin/tclsh8.6
###############################################################################
#
# Name    : ddr-crd_abutment.tcl
# Author  : Manmit Muker (mmuker)
# Date    : 2019.08
# Purpose : Facilites execution and verification of CRD testcases.
#
set ScriptVersion 2023.02
# Modification History
# 2023.02 - Full LVS flow added for Abutment and Utility Cell/Block Boundary testcases.
#   -Updated tool versions: ICC - 2022.12-SP1, ICC2 - 2022.12-SP1, ICV - 2022.12-SP1-1, msip_cd_pv - 2022.12-2.
#   -Changing tsmc12ffc18 to tsmc12ffc to increase CCS/PCS compatibility.
#   -Added support for voltage high label additions in tsmc12ffc.
# 2023.01-1 - Added fixes to tsmc7ff stdcell support.
# 2023.01 - Added tsmc7ff stdcell support.
#   -Changed default output_layout_format to OASIS.
#   -Updated tool versions: msip_cd_pv - 2022.12.
# 2022.12-1 - Full LVS flow added for Standard Cell Fill testcases. LEF is also generated. Additional input requirements include CDL for stdcell and macros.
#   -Added net_voltage_high parameter to set net high voltage in following format: net1 voltage1 net2 voltage2...
#   -Added support for voltage high label additions in tsmc5ff.
#   -Updated tool versions: ICC - 2022.12, ICC2 - 2022.12, ICV - 2022.12, ICVWB - 2022.12, msip_cd_pv - 2022.11.
# 2022.12 - Added sourcing of ${RealBin}/../cfg/crd_pin_mappings.cfg to define instance pin connections to nets.
#   -Added user_pin_mappings_cfg_file parameter to specify pin mappings config file to source after ${RealBin}/../cfg/crd_pin_mappings.cfg gets sourced.
#   -Removed pin_mappings parameter.
#   -Removed powers and grounds internal parameters.
#   -Added support for shape mask_constraint to ICC2_Generate_Ports proc.
#   -Added fixes to umc28hpcp18 stdcell support.
# 2022.11 - Full LVS flow added for Standard Cell Boundary testcases. Additional input requirements: macro CDL and LEF; stdcell CDL.
#   -Added pin_mappings parameter to support manual net assignment to pins.
#   -Script can now be run incrementally in same work directory as only testcases being run again will have their data deleted at script start.
#   -Added user_floorplans_cfg_file parameter to specify floorplans config file to source after ${RealBin}/../cfg/crd_abutment_floorplans.cfg gets sourced.
#   -Updated tool versions: msip_cd_pv to 2022.09-2.
#   -Improved parameters processing to remove whitespace characters causing script errors.
#   -Added support for different fill runsets through drc_feol_prefix and drc_beol_prefix parameters.
#   -Added support for umc28hpcp18 stdcells.
# 2022.10 - Submitting each testcase generation and pvbatch job to the grid to increase script efficiency.
#   -CDL netlist now placed in crd_results directory.
#   -Updated ICC2 to 2022.03-SP4, ICVWB to 2022.03-SP2 and msip_cd_pv to 2022.07.
#   -Updated to adhere to latest DDR DA WG template.
#   -Changing tsmc16ffc18 to tsmc16ffc in reference to standard cell rules to increase CCS/PCS compatibility.
#   -Changing tsmc5ff12/tsmc5ffp12 to tsmc5ff in reference to standard cell rules to increase CCS/PCS compatibility.
#   -Added further OASIS support enhancements.
# 2022.09-5 - Script updated to adhere to DDR DA WG template.
#   -Moving generated testcases into crd_testcases directory. Updated names of other directories to include crd_ prefix.
#   -Simplified log files such that testcase logs in crd_results directory are now just a link to the script log. There is no longer a <testcase>.log in work directory.
#   -Work directory is now cleaned at start of script execution.
# 2022.09-4 - DDR DA WG script enhancements added.
# 2022.09-3 - DDR DA WG script enhancements added.
# 2022.09-2 - Updated to source floorplans from ${RealBin}/../cfg/crd_abutment_floorplans.cfg.
# 2022.09-1 - Updated floorplans as per DDR43, LPDDR4 multiPHY V2, LPDDR4x and DDR54 CRD rev1.6 for review (//depot/products/ddr43_lpddr4_v2/project/crd/_4review/DDR43_LPDDR4mV2_LPDDR4X_DDR54_Construction_Requirements_Document.docx#22).
#   -Added tcoil_unit_width parameter to support different tcoil cell widths.
#   -Added cell_substitution parameter to support cell substitution in floorplans.
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
#
##### Adding usage statistics ######
# 2022-05-10 12:45:02
# Editor: wadhawan
# Stats: https://kibana/kibana/s/tesla/app/dashboards#/view/cc72dfe0-013f-11eb-a373-d7f01031644f?_g=(filters:!(),refreshInterval:(pause:!t,value:0),time:(from:now-3M,to:now))
#
###############################################################################


package require try         ;# Tcllib.
package require cmdline 1.5 ;# First version with proper error-codes.
package require fileutil

set DEBUG      0
set VERBOSITY  0
set STDOUT_LOG ""
set TIMESTAMP  1
set AUTHOR "Manmit Muker (mmuker)"
set RealBin [file dirname [file normalize [info script]] ]
set RealScript [file tail [file normalize [info script]] ]

# Declare cmdline opt vars here, so they are global
set opt_fast ""
set opt_test ""
set opt_help ""
set opt_project ""

set paramsCSVfile "" 

lappend auto_path "$RealBin/../lib/tcl"
package require Messaging 1.0
namespace import ::Messaging::*
package require Misc 1.0
namespace import ::Misc::*

set VERSION [get_release_version]

set PROGRAM_NAME $RealScript
set LOGFILE "[pwd]/$PROGRAM_NAME.[clock format [clock seconds] -format %Y_%m_%d_%H_%M_%S].log"


#-----------------------------------------------------------------
# Show the script usage details to the user
#-----------------------------------------------------------------
proc showUsage {} {
    global RealScript RealBin
    set msg "\nUsage:  $RealScript "
    append msg "\n\t Example command lines:\n"
    append msg "\t\t  $RealScript \n"
    append msg "\t\t  $RealScript -params $RealBin/crd_abutment_parameters.csv \n"
    append msg "\t\t  $RealScript -debug 1000 -verbosity 5 \n"
    append msg "\t\t  $RealScript -h \n"
    append msg "\n\t Valid command line options:\n"
    append msg "\t     -params <parameter CSV file location>\n"
    append msg "\t     -p <projID> : specifies the product/project/release triplet\n"
    append msg "\t     -d/debug #        : verbosity of debug messaging\n"
    append msg "\t     -v/verbosity #        : verbosity of user messaging\n"
    append msg "\t     -t          : use functional testing setup\n"
    append msg "\t     -f          : fast execution (skip pre-clean of RTL area & export from Perforce)\n"
    puts $msg
    return $msg
}

#-----------------------------------------------------------------
# process command line options...must have the variables 
#    declared globally and set their value in this proc
#-----------------------------------------------------------------
proc process_cmdline {} {

    set parameters {
            {verbosity.arg "0" "verbosity"}
            {v.arg  "0"    "verbosity"}
            {debug.arg "0" "debug"}
            {d.arg  "0"    "debug"}
            {params.arg  "crd_abutment_parameters.csv" "crd_abutment_parameters.csv"}
            {p.arg  "none" "product/project/release"}
            {f             "run fast (skip delete, p4 print" }
            {t             "functional testing mode"}
            {h             "help message"}
    }
    set usage {showUsage}
    try {
       array set options [::cmdline::getoptions ::argv $parameters $usage ]
       # test: iprint [array names options]
    } trap {CMDLINE USAGE} {msg o} {
       # Trap the usage signal, print the message, and exit the application.
       # Note: Other errors are not caught and passed through to higher levels!
	     eprint "Invalid Command line options provided!"
	     showUsage
	     myexit 1
    }

    global VERBOSITY
    global DEBUG
    global opt_project
    global opt_fast
    global opt_test
    global opt_help

    global paramsCSVfile

    
    set VERBOSITY [get_max_val $options(verbosity) $options(v)]
    set DEBUG [get_max_val $options(debug) $options(d)]
 
    set opt_test    $options(t)
    set opt_fast    $options(f)
    set opt_help    $options(h)
    set opt_project $options(p)
    
    set paramsCSVfile $options(params)

    dprint 1 "debug value     : $DEBUG"
    dprint 1 "verbosity value : $VERBOSITY"
    dprint 1 "project value   : $opt_project" 
    dprint 1 "test value      : $opt_test" 
    dprint 1 "fast value      : $opt_fast" 
    dprint 1 "help value      : $opt_help" 

    if { $opt_help } {
        showUsage
        myexit 0
    }

    return true
}

proc get_clean_dir {{args}} {
    
  # 2022.11 - Removed deletion of crd_results, crd_testcases and ${RealScript}.log to preserve results for incremental runs.
  file delete -force -- {*}[list \
              crd_perforce_files \
              crd_uniquified_input_CDL \
              crd_uniquified_input_GDS \
              ]
}

# 2022.11 - proc to remove testcase files.
proc get_clean_testcase {testcase} {
  file delete -force -- {*}[list \
    crd_results/$testcase \
    crd_testcases/$testcase \
    ]
}

# Utility procs

# 2022.12-1 - Merge pin mappings from ALL and testcase.
proc Create_Testcase_Pin_Mapping {pin_mappings testcase} {
  print_function_header
  
  if {[dict exists $pin_mappings $testcase]} {
    set testcase_pin_mapping [dict merge [dict get $pin_mappings ALL] [dict get $pin_mappings $testcase]]
  } else {
    set testcase_pin_mapping [dict get $pin_mappings ALL]
  }
  
  print_function_footer
  return $testcase_pin_mapping
}
# end Create_Testcase_Pin_Mapping

# Generate abutment layout and Verilog netlist using ICC2.
proc Generate_Abutment_Layout_And_Netlist_ICC2 {mainFloorplans mainParameters pin_mapping testcase} {
  print_function_header
  upvar $mainFloorplans floorplans
  upvar $mainParameters parameters
  iprint "Generating $testcase ${parameters(output_layout_format)} and Verilog."
  
  # Create ICC2 script.
  set file_contents [list]
  lappend file_contents [ICC2_Create_Lib parameters $testcase]
  set gds_files [list]
  set macros [Get_Macro_List floorplans $testcase]
  foreach macro $macros {
    if {$parameters(test_macros)} {
      lappend file_contents "set bbox \[get_attribute -objects \[get_lib_cell $macro\] -name bbox \]"
      lappend file_contents "set x_$macro \[lindex \$bbox 1 0\]"
      lappend file_contents "set y_$macro \[lindex \$bbox 1 1\]"
      lappend gds_files $parameters(gds_$macro)
    }
    if {$parameters(test_covercells) && [info exists parameters(gds_dwc_ddrphycover_$macro)]} {
      lappend file_contents "set bbox \[get_attribute -objects \[get_lib_cell dwc_ddrphycover_$macro\] -name bbox \]"
      lappend file_contents "set x_$macro \[lindex \$bbox 1 0\]"
      lappend file_contents "set y_$macro \[lindex \$bbox 1 1\]"
      lappend gds_files $parameters(gds_dwc_ddrphycover_$macro)
    }
  }
  set gds_files [lsort -unique $gds_files] 
  lappend file_contents "create_block $testcase"
  set instance_number 0
  foreach {macro columns rows d_x d_y x y angle mirror} $floorplans($testcase) {
    # angle and mirror from floorplans are based on ICVWB, where entire array is rotated by angle but individual elements are mirrored.
    switch -- "$angle $mirror" {
      {0 0}   {
        set orientation R0
        set d_x $d_x
        set d_y $d_y
      }
      {180 0}   {
        set orientation R180
        set d_x -$d_x
        set d_y -$d_y
      }
      {180 1}   {
        set orientation MY
        set d_x -$d_x
        set d_y -$d_y
      }
      {0 1}   {
        set orientation MX
        set d_x $d_x
        set d_y $d_y
      }
      default {
        fatal_error "Illegal floorplan orientation encountered for $testcase. Exiting."
      }
    }
    for {set row 0} {$row < $rows} {incr row} {
      for {set column 0} {$column < $columns} {incr column} {
        incr instance_number
        if {$parameters(test_macros)} {
          lappend file_contents "create_cell MACRO$instance_number $macro"
          # Using move_objects instead of set_cell_location allows for selecting origin of cell as the reference point for the cell during placement.
          #lappend file_contents "set_cell_location MACRO$i -coordinates \"\[expr $x\] \[expr $y\]\" -orientation $orientation -fixed"
          lappend file_contents "move_objects -from \[get_attribute -objects \[get_cells MACRO$instance_number\] -name origin\] -to \"\[expr $x + ($d_x * $column)\] \[expr $y + ($d_y * $row)\]\" -rotate_by $orientation -group \[get_cells MACRO$instance_number\]"
        }
        if {$parameters(test_covercells)} {
          lappend file_contents "create_cell COVER$instance_number dwc_ddrphycover_$macro"
          #lappend file_contents "set_cell_location COVER$i -coordinates \"\[expr $x\] \[expr $y\]\" -orientation $orientation -fixed"
          lappend file_contents "move_objects -from \[get_attribute -objects \[get_cells COVER$instance_number\] -name origin\] -to \"\[expr $x + ($d_x * $column)\] \[expr $y + ($d_y * $row)\]\" -rotate_by $orientation -group \[get_cells COVER$instance_number\]"
        }
      }
    }
  }
  lappend file_contents "set_attribute -objects \[get_cells\] -name physical_status -value fixed"
  lappend file_contents "set bbox \[get_attribute -objects \[get_designs\] -name bbox\]"
  lappend file_contents "set bbox \"{\[expr \[lindex \$bbox 0 0\] - $parameters(generated_boundary_upsize_l)\] \[expr \[lindex \$bbox 0 1\] - $parameters(generated_boundary_upsize_b)\]} {\[expr \[lindex \$bbox 1 0\] + $parameters(generated_boundary_upsize_r)\] \[expr \[lindex \$bbox 1 1\] + $parameters(generated_boundary_upsize_t)\]}\""
  lappend file_contents "set_app_options -name finfet.ignore_grid.std_cell -value true"
  lappend file_contents "initialize_floorplan -boundary \$bbox -keep_all"
  lappend file_contents [ICC2_Generate_Ports parameters $pin_mapping]
  lappend file_contents [ICC2_Write_Layout parameters $gds_files $testcase]
  lappend file_contents [ICC2_Write_Netlist parameters $testcase]
  lappend file_contents "save_lib"
  lappend file_contents "exit"
  write_file icc2.tcl [join $file_contents \n]
  
  # Create ICC2 run script.
  set file_contents [list]
  lappend file_contents "#!/bin/tcsh"
  lappend file_contents "module unload icc2"
  lappend file_contents "module load icc2/$parameters(icc2_version)"
  lappend file_contents "icc2_shell -file icc2.tcl"
  write_file icc2.tcsh [join $file_contents \n]
  file attributes icc2.tcsh -permissions +x
    
  print_function_footer
  return ./icc2.tcsh
}
# end Generate_Abutment_Layout_And_Netlist_ICC2

# Generate CDL.
proc Generate_CDL {mainParameters testcase verilogList cdlList} {
  print_function_header
  upvar $mainParameters parameters
  iprint "Generating $testcase CDL."
  
  # 2023.01 - Add quotes around each CDL file path to avoid errors with # symbols in filenames.
  foreach cdlFile $cdlList {
    append cdlString "\"${cdlFile}\" "
  }
  
  set file_contents [list]
  lappend file_contents "#!/bin/tcsh"
  lappend file_contents "module unload icv"
  lappend file_contents "module load icv/$parameters(icv_version)"
  lappend file_contents "icv_nettran -verilog $verilogList -sp $cdlString -outName ${testcase}.cdl -outType SPICE"
  write_file icv_generate_cdl.tcsh [join $file_contents \n]
  file attributes icv_generate_cdl.tcsh -permissions +x
  
  print_function_footer
  return ./icv_generate_cdl.tcsh
}
# end Generate_CDL

# Generates empty CDL.
proc Generate_Empty_CDL {macro} {
  print_function_header
  iprint "Generating empty $macro CDL."
  set file_contents [list]
  lappend file_contents ".subckt $macro"
  lappend file_contents ".ends $macro"
  write_file ${macro}.cdl [join $file_contents \n]
  print_function_footer
}
# end Generate_Empty_CDL

# Generate layout database.
# 2022.04 - Eliminate need for macros array variable.
#proc Generate_GDS {mainFloorplans mainMacros mainParameters hard_macros testcase}
# 2022.07 - Renaming to Generate_Layout to reflect that OASIS is supported as well.
proc Generate_Layout {mainFloorplans mainParameters hard_macros testcase} {
  print_function_header
  upvar $mainFloorplans floorplans
  #upvar $mainMacros macros
  upvar $mainParameters parameters
  iprint "Generating $testcase ${parameters(output_layout_format)}."
  
  # Adding check as ICVWB will complete without exiting on error due to being run with -runnohalt option.
  if {$parameters(boundary_layer) == ""} {
    fatal_error "boundary_layer parameter not defined. Exiting."
  }

  set file_contents [list]
  lappend file_contents "default filter_layer_hier 1"
  lappend file_contents "default layer_hier_level 0"
  lappend file_contents "default find_limit unlimited"
  lappend file_contents "set layoutID \[layout new $testcase -dbu $parameters(dbu) -uu_per_dbu $parameters(uu_per_dbu)\]"
  
  # 2022.04 - To eliminate need for macros array variable, getting list of macros from floorplans array variable.
  foreach {macro columns rows d_x d_y x y angle mirror} $floorplans($testcase) {
    lappend macros $macro
  }
  set macros [lsort -unique $macros]
  
  #foreach macro $macros($testcase)
  foreach macro $macros {
    lappend file_contents "set pinID_$macro \[layout new pin_$macro -dbu $parameters(dbu) -uu_per_dbu $parameters(uu_per_dbu)\]"
    if {$parameters(test_macros)} {
      lappend file_contents "layout open $parameters(gds_$macro) $macro"
      lappend file_contents "set boundary_bbox \[layer bbox $parameters(boundary_layer) -levels 0\]"
      lappend file_contents "set x_$macro \[lindex \$boundary_bbox 2\]"
      lappend file_contents "set y_$macro \[lindex \$boundary_bbox 3\]"
      if {$parameters(macro_text_layers) != ""} {
        lappend file_contents "if \{\[find init -type text -layer \"$parameters(macro_text_layers)\"\]\} \{"
        lappend file_contents "  find table select *"
        lappend file_contents "  select copy \"0 0\""
        lappend file_contents "  layout active \$pinID_$macro"
        lappend file_contents "  select paste \"0 0\""
        lappend file_contents "\}"
      }
    }
    if {$parameters(test_covercells) && [regexp $hard_macros $macro]} {
      lappend file_contents "layout open $parameters(gds_dwc_ddrphycover_$macro) dwc_ddrphycover_$macro"
      lappend file_contents "set boundary_bbox \[layer bbox $parameters(boundary_layer) -levels 0\]"
      lappend file_contents "set x_$macro \[lindex \$boundary_bbox 2\]"
      lappend file_contents "set y_$macro \[lindex \$boundary_bbox 3\]"
      if {$parameters(covercell_text_layers) != ""} {
        lappend file_contents "if \{\[find init -type text -layer \"$parameters(covercell_text_layers)\"\]\} \{"
        lappend file_contents "  find table select *"
        lappend file_contents "  select copy \"0 0\""
        lappend file_contents "  layout active \$pinID_$macro"
        lappend file_contents "  select paste \"0 0\""
        lappend file_contents "\}"
      }
    }
  }
  lappend file_contents "layout active \$layoutID"
  
  #foreach macro $macros($testcase)
  # 2022.04-3 - To prevent ICVWB error for adding same reference layout, compiling list of unique GDS files prior to adding them.
  foreach macro $macros {
    if {$parameters(test_macros)} {
      #lappend file_contents "layout reference add $parameters(gds_$macro)"
      lappend reference_layouts $parameters(gds_$macro)
    }
    if {$parameters(test_covercells) && [regexp $hard_macros $macro]} {
      #lappend file_contents "layout reference add $parameters(gds_dwc_ddrphycover_$macro)"
      lappend reference_layouts $parameters(gds_dwc_ddrphycover_$macro)
    }
    lappend file_contents "layout reference add \$pinID_$macro"
  }
  foreach reference_layout [lsort -unique $reference_layouts] {
    lappend file_contents "layout reference add $reference_layout"
  }

  foreach {macro columns rows d_x d_y x y angle mirror} $floorplans($testcase) {
    if {$parameters(test_macros)} {
      lappend file_contents "cell add aref $macro $rows $columns \[expr $d_x\] \[expr $d_y\] \"\[expr $x\] \[expr $y\]\" $angle $mirror"
    }
    if {$parameters(test_covercells) && [regexp $hard_macros $macro]} {
      lappend file_contents "cell add aref dwc_ddrphycover_$macro $rows $columns \[expr $d_x\] \[expr $d_y\] \"\[expr $x\] \[expr $y\]\" $angle $mirror"
    }
    lappend file_contents "cell add aref pin_$macro $rows $columns \[expr $d_x\] \[expr $d_y\] \"\[expr $x\] \[expr $y\]\" $angle $mirror"
    
    if {$parameters(uniquify_signal_pins)} {
      lappend file_contents "cell open pin_$macro"
      lappend file_contents "cell edit_state 1"
      lappend file_contents "find init -type text"
      lappend file_contents "find table select *"
      lappend file_contents "set texts \[select list\]"
      lappend file_contents "foreach text \$texts {"
      lappend file_contents "  set string \[cell object info \$text string\]"
      lappend file_contents "  if \[regexp {^(VAA|VDD|VDDQ|VDDQ_VDD2H|VDDQLP|VSH|VSS)\$} \$string\] {"
      lappend file_contents "    continue"
      lappend file_contents "  }"
      lappend file_contents "  cell object modify \$text \"string 1_\$string\""
      lappend file_contents "}"
      lappend file_contents "cell active $testcase"
    }
    
    lappend file_contents "hierarchy explode -cells pin_$macro"
  }
  
  # 2022.03 - Add rectangular boundary.
  if {$parameters(generate_boundary)} {
    # Using "-levels 1" to only consider boundary at top level of abutted macros.
    lappend file_contents "set boundary_bbox \[layer bbox $parameters(boundary_layer) -levels 1\]"
    lappend file_contents "set boundary_llx \[lindex \$boundary_bbox 0\]"
    lappend file_contents "set boundary_llx \[expr \$boundary_llx - $parameters(generated_boundary_upsize_l) * 1000\]"
    lappend file_contents "set boundary_lly \[lindex \$boundary_bbox 1\]"
    lappend file_contents "set boundary_lly \[expr \$boundary_lly - $parameters(generated_boundary_upsize_b) * 1000\]"
    lappend file_contents "set boundary_urx \[lindex \$boundary_bbox 2\]"
    lappend file_contents "set boundary_urx \[expr \$boundary_urx + $parameters(generated_boundary_upsize_r) * 1000\]"
    lappend file_contents "set boundary_ury \[lindex \$boundary_bbox 3\]"
    lappend file_contents "set boundary_ury \[expr \$boundary_ury + $parameters(generated_boundary_upsize_t) * 1000\]"
    lappend file_contents "cell object add rectangle \"coords {\$boundary_llx \$boundary_lly \$boundary_urx \$boundary_ury} layer $parameters(boundary_layer)\""
  }
  
  if {$parameters(output_layout_format) == "GDS"} {
    lappend file_contents "layout extract ${testcase}$parameters(layout_file_extension_zipped) -format gds.gz -cell $testcase"
  } else {
    lappend file_contents "layout extract ${testcase}$parameters(layout_file_extension_zipped) -format oasis -cell $testcase"
  }
  
  lappend file_contents "exit"
  write_file icvwb_generate_layout.mac [join $file_contents \n]
  
  set file_contents [list]
  lappend file_contents "#!/bin/tcsh"
  lappend file_contents "module unload icvwb"
  lappend file_contents "module load icvwb/$parameters(icvwb_version)"
  
  # 2022.04-3 - Changed ICVWB to now stop on errors.
  #lappend file_contents "icvwb -run icvwb_generate_gds.mac -runnohalt -nodisplay -log icvwb_generate_gds.log"
  lappend file_contents "icvwb -run icvwb_generate_layout.mac -nodisplay -log icvwb_generate_layout.log"
  
  write_file icvwb_generate_layout.tcsh [join $file_contents \n]
  file attributes icvwb_generate_layout.tcsh -permissions +x
  
  print_function_footer
  return ./icvwb_generate_layout.tcsh
}
# end Generate_Layout

# Generate size-only LEF from GDS.
proc Generate_LEF {mainParameters macro} {
  print_function_header
  upvar $mainParameters parameters
  iprint "Generating $macro size-only LEF."
  
  set file_contents [list]
  lappend file_contents "layout open $parameters(gds_$macro) $macro"
  lappend file_contents "cell edit_state 1"
  lappend file_contents "set myBOP \[bop extract -layers $parameters(boundary_layer)\]"
  lappend file_contents "bop insert \$myBOP 10000:0"
  lappend file_contents "set myBbox \[layer bbox 10000:0\]"
  lappend file_contents "set size_x \[expr \[lindex \$myBbox 2\] - \[lindex \$myBbox 0\]\]"
  lappend file_contents "set size_x \[expr \$size_x / 1000.0\]"
  lappend file_contents "set size_y \[expr \[lindex \$myBbox 3\] - \[lindex \$myBbox 1\]\]"
  lappend file_contents "set size_y \[expr \$size_y / 1000.0\]"
  lappend file_contents "find init -type shape -layer 10000:0"
  lappend file_contents "find table select *"
  lappend file_contents "set myBoundary \[cell object info coords\]"
  lappend file_contents "set myFixedBoundary \[list\]"
  lappend file_contents "foreach coordinate \$myBoundary {"
  lappend file_contents "  lappend myFixedBoundary \[expr \$coordinate / 1000.0\]"
  lappend file_contents "}"
  lappend file_contents "if {\[catch {open ${macro}.lef w} fid\]} {"
  lappend file_contents "  puts \"***** \$fid\""
  lappend file_contents "  exit"
  lappend file_contents "}"
  lappend file_contents "puts \$fid \"VERSION 5.8 ;\""
  lappend file_contents "puts \$fid \"BUSBITCHARS \\\"\\\[\\\]\\\" ;\""
  lappend file_contents "puts \$fid \"DIVIDERCHAR \\\"/\\\" ;\""
  lappend file_contents "puts \$fid \"MACRO $macro\""
  lappend file_contents "puts \$fid \"  CLASS BLOCK ;\""
  lappend file_contents "puts \$fid \"  ORIGIN 0 0 ;\""
  lappend file_contents "puts \$fid \"  FOREIGN $macro 0 0 ;\""
  lappend file_contents "puts \$fid \"  SYMMETRY X Y ;\""
  lappend file_contents "puts \$fid \"  SIZE \$size_x BY \$size_y ;\""
  lappend file_contents "puts \$fid \"  OBS\""
  lappend file_contents "puts \$fid \"    LAYER OVERLAP ;\""
  lappend file_contents "puts \$fid \"      POLYGON \$myFixedBoundary ;\""
  lappend file_contents "puts \$fid \"  END\""
  lappend file_contents "puts \$fid \"END $macro\""
  lappend file_contents "puts \$fid \"\""
  lappend file_contents "puts \$fid \"END LIBRARY\""
  lappend file_contents "close \$fid"
  lappend file_contents "exit"
  write_file icvwb_generate_lef.mac [join $file_contents \n]
  
  set file_contents [list]
  lappend file_contents "#!/bin/tcsh"
  lappend file_contents "module unload icvwb"
  lappend file_contents "module load icvwb/$parameters(icvwb_version)"
  lappend file_contents "icvwb -run icvwb_generate_lef.mac -nodisplay -log icvwb_generate_lef.log"
  write_file icvwb_generate_lef.tcsh [join $file_contents \n]
  file attributes icvwb_generate_lef.tcsh -permissions +x
  
  print_function_footer
  return ./icvwb_generate_lef.tcsh
}
# end Generate_LEF

# Generate reference library.
proc Generate_Reference_Lib {mainParameters macros} {
  print_function_header
  upvar $mainParameters parameters
  iprint "Generating reference library reference_lib.ndm."
  
  # Create Library Manager script.
  set file_contents [list]
  
  # Changing from creating an NDM for each macro to a single NDM.
  #foreach macro [split $testcases] {
  #    lappend file_contents "create_workspace -technology $parameters(icc2_techfile) $macro -scale_factor [expr round(1e-6 / $parameters(dbu))]"
  #    lappend file_contents "configure_frame_options -mode preserve_all"
  #    lappend file_contents "read_lef $parameters(lef_$macro)"
  #    lappend file_contents "check_workspace"
  #    lappend file_contents "commit_workspace"
  #  }
  #lappend file_contents "exit"
  #close $fid
  
  if {[regexp {gf12lpp18|tsmc3eff|tsmc7ff|tsmc12ffc|tsmc16ffc} $parameters(project_name)]} {
    # Use 10000 scale_factor to match (incorrect) scale factor in stdcell NDM.
    # 2022.03-2 - Same workaround required for gf12lpp18.
    # 2022.03-4 - Same workaround required for tsmc12ffc18.
    # 2022.08 - Same workaround required for tsmc3eff.
    # 2023.01 - Same workaround required for tsmc7ff.
    lappend file_contents "create_workspace -technology $parameters(icc2_techfile) reference_lib -scale_factor 10000"
  } else {
    lappend file_contents "create_workspace -technology $parameters(icc2_techfile) reference_lib -scale_factor [expr round(1e-6 / $parameters(dbu))]"
  }
  lappend file_contents "configure_frame_options -mode preserve_all"
  set lef_files [list]
  foreach macro [split $macros] {
    lappend lef_files $parameters(lef_$macro)
  }
  set lef_files [lsort -unique $lef_files]
  foreach lef_file $lef_files {
    lappend file_contents "read_lef $lef_file"
  }
  lappend file_contents "check_workspace"
  lappend file_contents "commit_workspace"
  lappend file_contents "exit"
  write_file lm_generate_reference_lib.tcl [join $file_contents \n]

  # Run Library Manager script.
  set file_contents [list]
  lappend file_contents "#!/bin/tcsh"
  lappend file_contents "module unload icc2"
  lappend file_contents "module load icc2/$parameters(icc2_version)"
  lappend file_contents "lm_shell -file lm_generate_reference_lib.tcl"
  write_file lm_generate_reference_lib.tcsh [join $file_contents \n]
  file attributes lm_generate_reference_lib.tcsh -permissions +x
  
  print_function_footer
  return ./lm_generate_reference_lib.tcsh
}
# end Generate_Reference_Lib

# Generate standard cell fill.
proc Generate_Stdcell_Fill {mainParameters pin_mapping macro} {
  print_function_header
  upvar $mainParameters parameters
  iprint "Generating $macro ${parameters(output_layout_format)}, LEF and Verilog."
  
  set icc2_scripts [list]
  
  # Create IC Compiler II script.
  set file_contents [list]
  
  lappend file_contents [ICC2_Create_Lib parameters $macro]
    
  lappend file_contents "read_verilog -top $macro ${macro}.stdcell_empty.v"
  lappend file_contents "read_def -add_def_only_objects all $parameters(def_$macro)"
  #Locking cell placements as initialize_floorplan may move them around, particularly in cases where macros are overlapped and the tool assumes there is not enough area in floorplan.
  lappend file_contents "set_attribute -name physical_status -value locked -objects \[get_cells\]"
  lappend file_contents "set_app_options -name finfet.ignore_grid.std_cell -value true"
  
  # 2022.03-2 - For gf12lpp18, ensure space of at least 2 units between standard cells to avoid fin cut spacing errors.. Note that place.rules.min_od_filler_size and place.rules.min_tpo_filler_size adjustments not required.
  if {[regexp {gf12lpp18} $parameters(project_name)]} {
    lappend file_contents "set_app_options -name place.rules.min_vt_filler_size -value 2"
  }
  
  lappend file_contents "initialize_floorplan -keep_boundary -keep_all -flip_first_row false"
  lappend file_contents "create_keepout_margin -outer \"$parameters(stdcell_kpt_l) $parameters(stdcell_kpt_b) $parameters(stdcell_kpt_r) $parameters(stdcell_kpt_t)\" \[get_cells\]"
  lappend file_contents "create_keepout_margin -inner \"$parameters(stdcell_inner_kpt_l) $parameters(stdcell_inner_kpt_b) $parameters(stdcell_inner_kpt_r) $parameters(stdcell_inner_kpt_t)\" \[current_block\]"

  # 2022.03-1 - Add manual standard cell keepouts.
  lappend file_contents [ICC2_Generate_Manual_Stdcell_Keepouts parameters $macro]
  
  # 2022.03-2 - Generating boundary cells using new proc.
  lappend file_contents [ICC2_Generate_Boundary_Cells parameters]
  
  # 2022.04-1 - Generating tap cells using new proc.
  # 2022.08 - Not required for tsmc3eff as these are added with boundary and wall cells.
  if {![regexp {tsmc3eff} $parameters(project_name)]} {
    lappend file_contents [ICC2_Generate_Tap_Cells parameters]
  }
  
  lappend file_contents "create_utilization_configuration -capacity boundary -include all utilization_config"
  lappend file_contents "set utilization \[report_utilization -config utilization_config\]"
  lappend file_contents "set spare_area \[expr \[get_attribute -objects \[current_block\] -name core_area_area\] * (1 - \$utilization)\]"
  lappend file_contents "set num_inv \[expr int(\$spare_area * 0.2 / \[get_attribute -objects \[get_lib_cells *INV_$parameters(stdcell_drive_strength)\] -name area\])\]"
  lappend file_contents "set num_buf \[expr int(\$spare_area * 0.2 / \[get_attribute -objects \[get_lib_cells *BUF_$parameters(stdcell_drive_strength)\] -name area\])\]"
  lappend file_contents "set num_nand \[expr int(\$spare_area * 0.2 / \[get_attribute -objects \[get_lib_cells *ND2_$parameters(stdcell_drive_strength)\] -name area\])\]"
  lappend file_contents "set num_nor \[expr int(\$spare_area * 0.2 / \[get_attribute -objects \[get_lib_cells *NR2_$parameters(stdcell_drive_strength)\] -name area\])\]"
  lappend file_contents "add_spare_cells -cell_name SpareCell -num_cells \"\[get_attribute -objects \[get_lib_cells *INV_$parameters(stdcell_drive_strength)\] -name name\] \$num_inv \[get_attribute -objects \[get_lib_cells *BUF_$parameters(stdcell_drive_strength)\] -name name\] \$num_buf \[get_attribute -objects \[get_lib_cells *ND2_$parameters(stdcell_drive_strength)\] -name name\] \$num_nand \[get_attribute -objects \[get_lib_cells *NR2_$parameters(stdcell_drive_strength)\] -name name\] \$num_nor\" -random_distribution"
  if {[regexp {tsmc7ff} $parameters(project_name)]} {
    lappend file_contents "set_app_options -name place.legalize.enable_pin_color_alignment_check -value true"
    lappend file_contents "set_app_options -name place.legalize.pin_color_alignment_layers -value M1"
    lappend file_contents "set_attribute -objects \[get_tracks -filter \"layer_name == M1\"\] -name mask_pattern -value \"mask_one mask_two\""
  }
  lappend file_contents "legalize_placement"
  
  # 2022.03-2 - For gf12lpp18, cannot leave 1x space as there is no fill cell that size.
  if {[regexp {gf12lpp18} $parameters(project_name)]} {
    lappend file_contents "create_stdcell_fillers -lib_cells \[sort_collection -descending \[get_lib_cells -regexp \{.*FILL\\\\d.*\}\] name\] -rules no_1x"
  } else {
    lappend file_contents "create_stdcell_fillers -lib_cells \[sort_collection -descending \[get_lib_cells -regexp \{.*FILL\\\\d.*\}\] name\]"
  }
  
  # 2022.03 - Generating top level pin labels using new proc.
  # 2022.12-1 - Using ICC2_Generate_Ports proc.
  #lappend file_contents [ICC2_Generate_Pin_Labels parameters $power_supplies]
  lappend file_contents [ICC2_Generate_Ports parameters $pin_mapping]
 
  lappend file_contents [ICC2_Fix_DRCs parameters]
  
  set layout_files [list $parameters(stdcell_gds)]
  foreach component $parameters(def_components_$macro) {
    lappend layout_files $parameters(gds_$component)
  }
  
  # 2022.04-2 - Using proc to write GDS.
  lappend file_contents [ICC2_Write_Layout parameters $layout_files $macro]
  
  lappend file_contents [ICC2_Write_LEF $macro]
  
  lappend file_contents [ICC2_Write_Netlist parameters $macro]
  
  lappend file_contents "save_lib"
  lappend file_contents "exit"
  write_file icc2.tcl [join $file_contents \n]
  
  # Run IC Compiler II script.
  set file_contents [list]
  lappend file_contents "#!/bin/tcsh"
  lappend file_contents "module unload icc2"
  lappend file_contents "module load icc2/$parameters(icc2_version)"
  lappend file_contents "icc2_shell -file icc2.tcl"
  write_file icc2.tcsh [join $file_contents \n]
  file attributes icc2.tcsh -permissions +x
  lappend icc2_scripts ./icc2.tcsh
  
  print_function_footer
  return [join $icc2_scripts \n]
}
# end Generate_Stdcell_Fill

# Generate standard cell ring.
proc Generate_Stdcell_Ring {mainParameters power_supplies macro testcase} {
  print_function_header
  upvar $mainParameters parameters
  iprint "Generating $testcase ${parameters(output_layout_format)}."
  
  set icc2_scripts [list]
  
  # Create IC Compiler II script.
  set file_contents [list]
  
  lappend file_contents [ICC2_Create_Lib parameters $testcase]
  
  lappend file_contents "set site_def \[get_site_defs unit\]"
  lappend file_contents "set stdcell_x \[get_attribute \$site_def width\]"
  lappend file_contents "set stdcell_y \[get_attribute \$site_def height\]"
  # Doubling site height to ensure even number of stdcell rows for TSMC5 and to avoid needing top boundary cells.
  lappend file_contents "set stdcell_y \[expr 2 * \$stdcell_y\]"
  
  if {[regexp {tsmc7ff} $parameters(project_name)]} {
    # 2023.01 - Ensuring even number of poly for tsmc7ff.
    lappend file_contents "set stdcell_width \[expr ceil(10 / \$stdcell_x) * 2 * \$stdcell_x\]"
  } else {
    # Ensuring odd site width for TSMC5.
    lappend file_contents "set stdcell_width \[expr ceil(10 / \$stdcell_x) * 2 * \$stdcell_x + \$stdcell_x\]"
  }
  
  lappend file_contents "set stdcell_height \[expr ceil(20 / \$stdcell_y) * \$stdcell_y\]"
  
  #lappend file_contents "set macro_width \[get_attribute ${macro}/${macro} width\]"
  lappend file_contents "set macro_width \[get_attribute $macro width\]"
  lappend file_contents "set width \[expr \$macro_width + 2 * \$stdcell_width + $parameters(stdcell_kpt_l) + $parameters(stdcell_kpt_r)\]"
  #lappend file_contents "set macro_height \[get_attribute ${macro}/${macro} height\]"
  lappend file_contents "set macro_height \[get_attribute $macro height\]"
  lappend file_contents "set height \[expr \$macro_height + 2 * \$stdcell_height + $parameters(stdcell_kpt_b) + $parameters(stdcell_kpt_t)\]"
 
  # 2022.03 - Placing macro at testbench origin.
  #lappend file_contents "set origin_x \[expr \$stdcell_width + $parameters(stdcell_kpt_l)\]"
  lappend file_contents "set origin_offset_x \[expr -\$stdcell_width - $parameters(stdcell_kpt_l)\]"
  #lappend file_contents "set origin_y \[expr \$stdcell_height + $parameters(stdcell_kpt_b)\]"
  lappend file_contents "set origin_offset_y \[expr -\$stdcell_height - $parameters(stdcell_kpt_b)\]"
  lappend file_contents "create_block $testcase"
  lappend file_contents "set_app_options -name finfet.ignore_grid.std_cell -value true"
  
  # 2022.03-2 - For gf12lpp18, ensure space of at least 2 units between standard cells to avoid fin cut spacing errors. Note that place.rules.min_od_filler_size and place.rules.min_tpo_filler_size adjustments not required.
  if {[regexp {gf12lpp18} $parameters(project_name)]} {
    lappend file_contents "set_app_options -name place.rules.min_vt_filler_size -value 2"
  }

  # By not flipping first row, don't require top boundary cells.
  #lappend file_contents "initialize_floorplan -side_length \"\$width \$height\" -flip_first_row false"
  switch -regexp -- $parameters(project_name) {
    gf12lpp18 {
      # 2022.03-2 - For gf12lpp18, require boundary extended outside of standard cell boundaries to avoid OUTLINE related DRC errors.
      lappend file_contents "initialize_floorplan -side_length \"\$width \$height\" -flip_first_row false -origin_offset \"\[expr \$origin_offset_x - 0.045\] \[expr \$origin_offset_y - 0.053\]\" -core_offset {0.045 0.053}"
    }
    tsmc3eff {
      # 2022.08 - For tsmc3eff, require boundary extended outside of standard cell boundaries to avoid forbidden enclosure DRC errors.
      lappend file_contents "initialize_floorplan -side_length \"\$width \$height\" -flip_first_row false -origin_offset \"\$origin_offset_x \[expr \$origin_offset_y - 0.052\]\" -core_offset {0 0.052}"
    }
    default {
      lappend file_contents "initialize_floorplan -side_length \"\$width \$height\" -flip_first_row false -origin_offset \"\$origin_offset_x \$origin_offset_y\""
    }
  }
  
  lappend file_contents "create_cell $macro $macro"
  #lappend file_contents "set_cell_location -coordinates \"\$origin_x \$origin_y\" $macro"
  lappend file_contents "set_cell_location -coordinates {0 0} $macro"
  #lappend file_contents "create_placement_blockage -boundary \[list \"\$stdcell_width \$stdcell_height\" \"\[expr \$origin_x + \$macro_width + $parameters(stdcell_kpt_r)\] \[expr \$origin_y + \$macro_height + $parameters(stdcell_kpt_t)\]\"\]"
  # Updated creation of placement blockage to support rectilinear boundaries.
  #lappend file_contents "set myPolyRect \[create_poly_rect -boundary \[get_attribute -objects $macro -name boundary\]\]"
  #lappend file_contents "set myGeoMask \[resize_polygons -objects \$myPolyRect -size \"$parameters(stdcell_kpt_l) $parameters(stdcell_kpt_b) $parameters(stdcell_kpt_r) $parameters(stdcell_kpt_t)\"\]"
  #lappend file_contents "create_placement_blockage -boundary \$myGeoMask"
  # move_objects not required as obtaining boundary of cell and not lib_cell.
  #lappend file_contents "move_objects -delta \"\$origin_x \$origin_y\" -simple \[get_placement_blockages\]"
  # Updated to use keepout margins instead of placement blockages.
  lappend file_contents "create_keepout_margin -outer \"$parameters(stdcell_kpt_l) $parameters(stdcell_kpt_b) $parameters(stdcell_kpt_r) $parameters(stdcell_kpt_t)\" $macro"
  
  # 2022.03-1 - Add manual standard cell keepouts.
  lappend file_contents [ICC2_Generate_Manual_Stdcell_Keepouts parameters $testcase]
  
  # 2022.03-2 - Generating boundary cells using new proc.
  lappend file_contents [ICC2_Generate_Boundary_Cells parameters]
  
  # 2022.04-1 - Generating tap cells using new proc.
  # 2022.08 - Not required for tsmc3eff as these are added with boundary and wall cells.
  if {![regexp {tsmc3eff} $parameters(project_name)]} {
    lappend file_contents [ICC2_Generate_Tap_Cells parameters]
  }
  
  # Remove placement blockage area from total area.
  #lappend file_contents "set spare_area \[expr \$width * \$height - \[get_attribute -objects \[get_placement_blockages\] -name area\]\]"
  # Get utilization of area outside placement blockage.
  #lappend file_contents "create_utilization_configuration -capacity boundary -include all -exclude \{hard_macros hard_blockages\} utilization_config"
  # Get utilization. Macro, keepout and boundary/tap cells should be considered correctly with following.
  lappend file_contents "create_utilization_configuration -capacity boundary -include all utilization_config"
  lappend file_contents "set utilization \[report_utilization -config utilization_config\]"
  lappend file_contents "set spare_area \[expr \$width * \$height * (1 - \$utilization)\]"
  lappend file_contents "set num_inv \[expr int(\$spare_area * 0.2 / \[get_attribute -objects \[get_lib_cells *INV_$parameters(stdcell_drive_strength)\] -name area\])\]"
  lappend file_contents "set num_buf \[expr int(\$spare_area * 0.2 / \[get_attribute -objects \[get_lib_cells *BUF_$parameters(stdcell_drive_strength)\] -name area\])\]"
  lappend file_contents "set num_nand \[expr int(\$spare_area * 0.2 / \[get_attribute -objects \[get_lib_cells *ND2_$parameters(stdcell_drive_strength)\] -name area\])\]"
  lappend file_contents "set num_nor \[expr int(\$spare_area * 0.2 / \[get_attribute -objects \[get_lib_cells *NR2_$parameters(stdcell_drive_strength)\] -name area\])\]"
  lappend file_contents "add_spare_cells -cell_name SpareCell -num_cells \"\[get_attribute -objects \[get_lib_cells *INV_$parameters(stdcell_drive_strength)\] -name name\] \$num_inv \[get_attribute -objects \[get_lib_cells *BUF_$parameters(stdcell_drive_strength)\] -name name\] \$num_buf \[get_attribute -objects \[get_lib_cells *ND2_$parameters(stdcell_drive_strength)\] -name name\] \$num_nand \[get_attribute -objects \[get_lib_cells *NR2_$parameters(stdcell_drive_strength)\] -name name\] \$num_nor\" -random_distribution"
  if {[regexp {tsmc7ff} $parameters(project_name)]} {
    lappend file_contents "set_app_options -name place.legalize.enable_pin_color_alignment_check -value true"
    lappend file_contents "set_app_options -name place.legalize.pin_color_alignment_layers -value M1"
    lappend file_contents "set_attribute -objects \[get_tracks -filter \"layer_name == M1\"\] -name mask_pattern -value \"mask_one mask_two\""
  }
  lappend file_contents "legalize_placement"
  
  # 2022.03-2 - For gf12lpp18, cannot leave 1x space as there is no fill cell that size.
  if {[regexp {gf12lpp18} $parameters(project_name)]} {
    lappend file_contents "create_stdcell_fillers -lib_cells \[sort_collection -descending \[get_lib_cells -regexp \{.*FILL\\\\d.*\}\] name\] -rules no_1x"
  } else {
    lappend file_contents "create_stdcell_fillers -lib_cells \[sort_collection -descending \[get_lib_cells -regexp \{.*FILL\\\\d.*\}\] name\]"
  }
  
  # 2022.03 - Generating top level pin labels using new proc.
  lappend file_contents [ICC2_Generate_Pin_Labels parameters $power_supplies]
  #  lappend file_contents "set terminals \[get_terminals -hierarchical -include_lib_cell\]"
  #  lappend file_contents "foreach_in_collection terminal \$terminals \{"
  #  lappend file_contents "  set text \[get_attribute -objects \$terminal -name port.name\]"
  #  lappend file_contents "  set layer \[get_attribute -objects \$terminal -name layer.name\]"
  #  # Changing text origin coordinate to boundary from bbox to fix issue where bbox coordinate may not fall within non-rectangular pin shape.
  #  #lappend file_contents "  set origin \[lindex \[get_attribute -objects \$terminal -name bbox\] 0\]"
  #  lappend file_contents "  set origin \[lindex \[get_attribute -objects \$terminal -name boundary\] 0\]"
  #  if {[regexp {int22ffl18} $parameters(project_name)]} {
  #    lappend file_contents "  if \[regexp \{(m\\d+)\} \$layer match layer\] \{"
  #    lappend file_contents "    set layer \$\{layer\}_pin"
  #  } else {
  #    lappend file_contents "  if \[regexp \{M(\\d+)\} \$layer match layer\] \{"
  #    lappend file_contents "    set layer TEXT\$\{layer\}"
  #  }
  #  lappend file_contents "    create_shape -shape_type text -layer \$layer -origin \$origin -height 0.1 -text \$text"
  #  lappend file_contents "  \}"
  #  lappend file_contents "\}"
  
  lappend file_contents [ICC2_Fix_DRCs parameters]
  
  # 2022.04-2 - Using proc to write GDS.
  lappend file_contents [ICC2_Write_Layout parameters "$parameters(gds_$macro) $parameters(stdcell_gds)" $testcase]
  
  lappend file_contents "save_lib"
  lappend file_contents "exit"
  write_file icc2.tcl [join $file_contents \n]
  
  # Run IC Compiler II script.
  set file_contents [list]
  lappend file_contents "#!/bin/tcsh"
  lappend file_contents "module unload icc2"
  lappend file_contents "module load icc2/$parameters(icc2_version)"
  lappend file_contents "icc2_shell -file icc2.tcl"
  write_file icc2.tcsh [join $file_contents \n]
  file attributes icc2.tcsh -permissions +x
  lappend icc2_scripts ./icc2.tcsh
  
  # As of ver1.2b of the ICC2 techfile/layermap file for tsmc5ff12, TEXT0 gets incorrectly streamed out to 202:0, not 202:30 as it should. Post-processing GDS to correct.
  # 2022.08 - Same fix required for tsmc3eff as of ICC2 techfile/layermap ver0.9_1a_eval062422.
  if {[regexp {tsmc3eff|tsmc5ff} $parameters(project_name)]} {
    file rename ${testcase}.gds.gz ${testcase}.pre_m0_fix.gds.gz
    
    set file_contents [list]
    lappend file_contents "layout open ${testcase}.pre_m0_fix.gds.gz $testcase"
    lappend file_contents "layout extract ${testcase}.gds.gz -format gds.gz -cell $testcase -map_layer {202:0 202:30}"
    lappend file_contents "exit"
    write_file icvwb_m0_fix.mac [join $file_contents \n]
    
    set file_contents [list]
    lappend file_contents "#!/bin/tcsh"
    lappend file_contents "module unload icvwb"
    lappend file_contents "module load icvwb/$parameters(icvwb_version)"
    
    # 2022.04-3 - Changed ICVWB to now stop on errors.
    #lappend file_contents "icvwb -run icvwb_m0_fix.mac -runnohalt -nodisplay -log icvwb_m0_fix.log"
    lappend file_contents "icvwb -run icvwb_m0_fix.mac -nodisplay -log icvwb_m0_fix.log"
    
    write_file icvwb_m0_fix.tcsh [join $file_contents \n]
    file attributes icvwb_m0_fix.tcsh -permissions +x
    lappend icc2_scripts ./icvwb_m0_fix.tcsh
  }
  print_function_footer
  return [join $icc2_scripts \n]
}
# end Generate_Stdcell_Ring

# Generate standard cell ring layout and Verilog netlist.
proc Generate_Stdcell_Ring_Layout_And_Netlist_ICC2 {mainParameters pin_mapping macro testcase} {
  print_function_header
  upvar $mainParameters parameters
  iprint "Generating $testcase ${parameters(output_layout_format)} and Verilog."
  
  set icc2_scripts [list]
  
  # Create IC Compiler II script.
  set file_contents [list]
  
  lappend file_contents [ICC2_Create_Lib parameters $testcase]
  
  lappend file_contents "set site_def \[get_site_defs unit\]"
  lappend file_contents "set stdcell_x \[get_attribute \$site_def width\]"
  lappend file_contents "set stdcell_y \[get_attribute \$site_def height\]"
  # Doubling site height to ensure even number of stdcell rows for TSMC5 and to avoid needing top boundary cells.
  lappend file_contents "set stdcell_y \[expr 2 * \$stdcell_y\]"
  
  if {[regexp {tsmc7ff} $parameters(project_name)]} {
    # 2023.01 - Ensuring even number of poly for tsmc7ff.
    lappend file_contents "set stdcell_width \[expr ceil(10 / \$stdcell_x) * 2 * \$stdcell_x\]"
  } else {
    # Ensuring odd site width for TSMC5.
    lappend file_contents "set stdcell_width \[expr ceil(10 / \$stdcell_x) * 2 * \$stdcell_x + \$stdcell_x\]"
  }
  
  lappend file_contents "set stdcell_height \[expr ceil(20 / \$stdcell_y) * \$stdcell_y\]"
  
  #lappend file_contents "set macro_width \[get_attribute ${macro}/${macro} width\]"
  lappend file_contents "set macro_width \[get_attribute $macro width\]"
  lappend file_contents "set width \[expr \$macro_width + 2 * \$stdcell_width + $parameters(stdcell_kpt_l) + $parameters(stdcell_kpt_r)\]"
  #lappend file_contents "set macro_height \[get_attribute ${macro}/${macro} height\]"
  lappend file_contents "set macro_height \[get_attribute $macro height\]"
  lappend file_contents "set height \[expr \$macro_height + 2 * \$stdcell_height + $parameters(stdcell_kpt_b) + $parameters(stdcell_kpt_t)\]"
 
  # 2022.03 - Placing macro at testbench origin.
  #lappend file_contents "set origin_x \[expr \$stdcell_width + $parameters(stdcell_kpt_l)\]"
  lappend file_contents "set origin_offset_x \[expr -\$stdcell_width - $parameters(stdcell_kpt_l)\]"
  #lappend file_contents "set origin_y \[expr \$stdcell_height + $parameters(stdcell_kpt_b)\]"
  lappend file_contents "set origin_offset_y \[expr -\$stdcell_height - $parameters(stdcell_kpt_b)\]"
  lappend file_contents "create_block $testcase"
  lappend file_contents "set_app_options -name finfet.ignore_grid.std_cell -value true"
  
  # 2022.03-2 - For gf12lpp18, ensure space of at least 2 units between standard cells to avoid fin cut spacing errors. Note that place.rules.min_od_filler_size and place.rules.min_tpo_filler_size adjustments not required.
  if {[regexp {gf12lpp18} $parameters(project_name)]} {
    lappend file_contents "set_app_options -name place.rules.min_vt_filler_size -value 2"
  }

  # By not flipping first row, don't require top boundary cells.
  #lappend file_contents "initialize_floorplan -side_length \"\$width \$height\" -flip_first_row false"
  switch -regexp -- $parameters(project_name) {
    gf12lpp18 {
      # 2022.03-2 - For gf12lpp18, require boundary extended outside of standard cell boundaries to avoid OUTLINE related DRC errors.
      lappend file_contents "initialize_floorplan -side_length \"\$width \$height\" -flip_first_row false -origin_offset \"\[expr \$origin_offset_x - 0.045\] \[expr \$origin_offset_y - 0.053\]\" -core_offset {0.045 0.053}"
    }
    tsmc3eff {
      # 2022.08 - For tsmc3eff, require boundary extended outside of standard cell boundaries to avoid forbidden enclosure DRC errors.
      lappend file_contents "initialize_floorplan -side_length \"\$width \$height\" -flip_first_row false -origin_offset \"\$origin_offset_x \[expr \$origin_offset_y - 0.052\]\" -core_offset {0 0.052}"
    }
    default {
      lappend file_contents "initialize_floorplan -side_length \"\$width \$height\" -flip_first_row false -origin_offset \"\$origin_offset_x \$origin_offset_y\""
    }
  }
  
  lappend file_contents "create_cell $macro $macro"
  #lappend file_contents "set_cell_location -coordinates \"\$origin_x \$origin_y\" $macro"
  lappend file_contents "set_cell_location -coordinates {0 0} $macro"
  #lappend file_contents "create_placement_blockage -boundary \[list \"\$stdcell_width \$stdcell_height\" \"\[expr \$origin_x + \$macro_width + $parameters(stdcell_kpt_r)\] \[expr \$origin_y + \$macro_height + $parameters(stdcell_kpt_t)\]\"\]"
  # Updated creation of placement blockage to support rectilinear boundaries.
  #lappend file_contents "set myPolyRect \[create_poly_rect -boundary \[get_attribute -objects $macro -name boundary\]\]"
  #lappend file_contents "set myGeoMask \[resize_polygons -objects \$myPolyRect -size \"$parameters(stdcell_kpt_l) $parameters(stdcell_kpt_b) $parameters(stdcell_kpt_r) $parameters(stdcell_kpt_t)\"\]"
  #lappend file_contents "create_placement_blockage -boundary \$myGeoMask"
  # move_objects not required as obtaining boundary of cell and not lib_cell.
  #lappend file_contents "move_objects -delta \"\$origin_x \$origin_y\" -simple \[get_placement_blockages\]"
  # Updated to use keepout margins instead of placement blockages.
  lappend file_contents "create_keepout_margin -outer \"$parameters(stdcell_kpt_l) $parameters(stdcell_kpt_b) $parameters(stdcell_kpt_r) $parameters(stdcell_kpt_t)\" $macro"
  
  # 2022.03-1 - Add manual standard cell keepouts.
  lappend file_contents [ICC2_Generate_Manual_Stdcell_Keepouts parameters $testcase]
  
  # 2022.03-2 - Generating boundary cells using new proc.
  lappend file_contents [ICC2_Generate_Boundary_Cells parameters]
  
  # 2022.04-1 - Generating tap cells using new proc.
  # 2022.08 - Not required for tsmc3eff as these are added with boundary and wall cells.
  if {![regexp {tsmc3eff} $parameters(project_name)]} {
    lappend file_contents [ICC2_Generate_Tap_Cells parameters]
  }
  
  # Remove placement blockage area from total area.
  #lappend file_contents "set spare_area \[expr \$width * \$height - \[get_attribute -objects \[get_placement_blockages\] -name area\]\]"
  # Get utilization of area outside placement blockage.
  #lappend file_contents "create_utilization_configuration -capacity boundary -include all -exclude \{hard_macros hard_blockages\} utilization_config"
  # Get utilization. Macro, keepout and boundary/tap cells should be considered correctly with following.
  lappend file_contents "create_utilization_configuration -capacity boundary -include all utilization_config"
  lappend file_contents "set utilization \[report_utilization -config utilization_config\]"
  lappend file_contents "set spare_area \[expr \$width * \$height * (1 - \$utilization)\]"
  lappend file_contents "set num_inv \[expr int(\$spare_area * 0.2 / \[get_attribute -objects \[get_lib_cells *INV_$parameters(stdcell_drive_strength)\] -name area\])\]"
  lappend file_contents "set num_buf \[expr int(\$spare_area * 0.2 / \[get_attribute -objects \[get_lib_cells *BUF_$parameters(stdcell_drive_strength)\] -name area\])\]"
  lappend file_contents "set num_nand \[expr int(\$spare_area * 0.2 / \[get_attribute -objects \[get_lib_cells *ND2_$parameters(stdcell_drive_strength)\] -name area\])\]"
  lappend file_contents "set num_nor \[expr int(\$spare_area * 0.2 / \[get_attribute -objects \[get_lib_cells *NR2_$parameters(stdcell_drive_strength)\] -name area\])\]"
  lappend file_contents "add_spare_cells -cell_name SpareCell -num_cells \"\[get_attribute -objects \[get_lib_cells *INV_$parameters(stdcell_drive_strength)\] -name name\] \$num_inv \[get_attribute -objects \[get_lib_cells *BUF_$parameters(stdcell_drive_strength)\] -name name\] \$num_buf \[get_attribute -objects \[get_lib_cells *ND2_$parameters(stdcell_drive_strength)\] -name name\] \$num_nand \[get_attribute -objects \[get_lib_cells *NR2_$parameters(stdcell_drive_strength)\] -name name\] \$num_nor\" -random_distribution"
  if {[regexp {tsmc7ff} $parameters(project_name)]} {
    lappend file_contents "set_app_options -name place.legalize.enable_pin_color_alignment_check -value true"
    lappend file_contents "set_app_options -name place.legalize.pin_color_alignment_layers -value M1"
    lappend file_contents "set_attribute -objects \[get_tracks -filter \"layer_name == M1\"\] -name mask_pattern -value \"mask_one mask_two\""
  }
  lappend file_contents "legalize_placement"
  
  # 2022.03-2 - For gf12lpp18, cannot leave 1x space as there is no fill cell that size.
  if {[regexp {gf12lpp18} $parameters(project_name)]} {
    lappend file_contents "create_stdcell_fillers -lib_cells \[sort_collection -descending \[get_lib_cells -regexp \{.*FILL\\\\d.*\}\] name\] -rules no_1x"
  } else {
    lappend file_contents "create_stdcell_fillers -lib_cells \[sort_collection -descending \[get_lib_cells -regexp \{.*FILL\\\\d.*\}\] name\]"
  }
  
  lappend file_contents [ICC2_Generate_Ports parameters $pin_mapping]
  
  lappend file_contents [ICC2_Fix_DRCs parameters]
  
  # 2022.04-2 - Using proc to write GDS.
  lappend file_contents [ICC2_Write_Layout parameters "$parameters(gds_$macro) $parameters(stdcell_gds)" $testcase]
  
  lappend file_contents [ICC2_Write_Netlist parameters $testcase]
    
  lappend file_contents "save_lib"
  lappend file_contents "exit"
  write_file icc2.tcl [join $file_contents \n]
  
  # Run IC Compiler II script.
  set file_contents [list]
  lappend file_contents "#!/bin/tcsh"
  lappend file_contents "module unload icc2"
  lappend file_contents "module load icc2/$parameters(icc2_version)"
  lappend file_contents "icc2_shell -file icc2.tcl"
  write_file icc2.tcsh [join $file_contents \n]
  file attributes icc2.tcsh -permissions +x
  lappend icc2_scripts ./icc2.tcsh
  
  print_function_footer
  return [join $icc2_scripts \n]
}
# end Generate_Stdcell_Ring_Layout_And_Netlist_ICC2

# Generate Verilog.
proc Generate_Verilog {mainParameters testcase cdlList} {
  print_function_header
  upvar $mainParameters parameters
  iprint "Generate $testcase Verilog."
  
  set file_contents [list]
  lappend file_contents "#!/bin/tcsh"
  lappend file_contents "module unload icv"
  lappend file_contents "module load icv/$parameters(icv_version)"
  lappend file_contents "icv_nettran -sp $cdlList -sp-chopXPrefix -outName ${testcase}.v -outType Verilog"
  write_file icv_generate_verilog.tcsh [join $file_contents \n]
  file attributes icv_generate_verilog.tcsh -permissions +x
  
  print_function_footer
  return ./icv_generate_verilog.tcsh
}
# end Generate_Verilog

# Return list of macros for a given testcase from the floorplans array.
proc Get_Macro_List {mainFloorplans testcase} {
  print_function_header
  upvar $mainFloorplans floorplans
  
  set macros [list]
  foreach {macro columns rows d_x d_y x y angle mirror} $floorplans($testcase) {
    lappend macros $macro
  }
  set macros [lsort -unique $macros]
  
  print_function_footer
  return $macros
}
# end Get_Macro_List

# 2022.12 - Create lib in ICC2.
proc ICC2_Create_Lib {mainParameters libName} {
  print_function_header
  upvar $mainParameters parameters
  
  set file_contents [list]
  
  # Setting icc_shell executable path to allow import of Milkyway stdcell library.
  if {[regexp {umc28hpcp18} $parameters(project_name)]} {
    lappend file_contents "set_app_options -name lib.configuration.icc_shell_exec -value $parameters(icc_shell_exec)"
  }
  switch -regexp -- $parameters(project_name) {
    gf12lpp18 {
      # Use stdcell NDM for TSMC16 due to its (incorrect) 10000 scale_factor.
      # 2022.03-2 - Same workaround required for gf12lpp18.
      # 2022.08-1 - tsmc16ffc18 NDM no longer compatible as techlib for newer versions of ICC2.
      lappend file_contents "create_lib -use_technology_lib $parameters(stdcell_ndm) -ref_libs \"reference_lib.ndm $parameters(stdcell_ndm)\" $libName"
    }
    tsmc3eff {
      # 2022.08 - Use 10000 scale_factor to match (incorrect) scale factor in stdcell NDM. Allow MY placement of stdcells through Y-symmetry.
      lappend file_contents "create_lib -technology $parameters(icc2_techfile) -scale_factor 10000 -ref_libs \"reference_lib.ndm $parameters(stdcell_ndm)\" $libName"
      lappend file_contents "set_attribute -name symmetry -objects \[get_site_defs unitW48H169\] -value Y"
    }
    tsmc5ff {
      # Use stdcell NDM for TSMC5 due to legal orientations specified in unit site_def.
      # 2022.04 - Updated to use tech file to support any metal stack so that stdcell NDM reference techlib no longer needs to be changed.
      #lappend file_contents "create_lib -use_technology_lib $parameters(stdcell_ndm) -scale_factor [expr round(1e-6 / $parameters(dbu))] -ref_libs \"../${macro}.ndm $parameters(stdcell_ndm)\" $testcase"
      #lappend file_contents "create_lib -use_technology_lib $parameters(stdcell_ndm) -scale_factor [expr round(1e-6 / $parameters(dbu))] -ref_libs \"reference_lib.ndm $parameters(stdcell_ndm)\" $testcase"
      lappend file_contents "create_lib -technology $parameters(icc2_techfile) -scale_factor [expr round(1e-6 / $parameters(dbu))] -ref_libs \"reference_lib.ndm $parameters(stdcell_ndm)\" $libName"
      lappend file_contents "set_attribute -name symmetry -objects \[get_site_defs unit\] -value Y"
    }
    {tsmc7ff|tsmc12ffc|tsmc16ffc} {
      # 2022.03-4 - Use 10000 scale_factor to match (incorrect) scale factor in stdcell NDM. Allow MY placement of stdcells through Y-symmetry.
      # 2022.08-1 - Same workaround for tsmc16ffc18.
      # 2023.01-1 - Same workaround for tsmc7ff.
      lappend file_contents "create_lib -technology $parameters(icc2_techfile) -scale_factor 10000 -ref_libs \"reference_lib.ndm $parameters(stdcell_ndm)\" $libName"
      lappend file_contents "set_attribute -name symmetry -objects \[get_site_defs unit\] -value Y"
    }
    default {
      #lappend file_contents "create_lib -technology $parameters(icc2_techfile) -scale_factor [expr round(1e-6 / $parameters(dbu))] -ref_libs \"../${macro}.ndm $parameters(stdcell_ndm)\" $testcase"
      lappend file_contents "create_lib -technology $parameters(icc2_techfile) -scale_factor [expr round(1e-6 / $parameters(dbu))] -ref_libs \"reference_lib.ndm $parameters(stdcell_ndm)\" $libName"
    }
  }
  
  print_function_footer
  return [join $file_contents \n]
}
# end ICC2_Create_Lib

# 2023.01-1 - Manual DRC fixes in ICC2.
proc ICC2_Fix_DRCs {mainParameters} {
  print_function_header
  upvar $mainParameters parameters
  
  set file_contents [list]
  
  if {[regexp {tsmc7ff} $parameters(project_name)]} {
    lappend file_contents "foreach_in_collection shape \[get_shapes -of_objects \[get_cells -filter \"design_type == lib_cell\"\] -filter \"layer_name == M1\"\] {"
    lappend file_contents "  set mask_constraint \[get_attribute -objects \$shape -name mask_constraint\]"
    lappend file_contents "  set boundary \[get_attribute -objects \$shape -name boundary\]"
    lappend file_contents "  set cell_bbox \[get_attribute -objects \$shape -name parent_cell.boundary_bbox\]"
    lappend file_contents "  set boundary \"{\[lindex \$boundary 0 0\] \[expr \[lindex \$cell_bbox 0 1\] + 0.015\]} {\[lindex \$boundary 1 0\] \[expr \[lindex \$cell_bbox 1 1\] - 0.015\]}\""
    lappend file_contents "  set new_shape \[create_shape -shape_type rect -layer M1 -boundary \$boundary\]"
    lappend file_contents "  set_attribute -objects \$new_shape -name mask_constraint -value \$mask_constraint"
    lappend file_contents "}"
    lappend file_contents "create_cut_metals"
    lappend file_contents "foreach_in_collection cut_shape \[get_shapes -filter \"(layer.name == CM1:metal_cut) && (mask_constraint == mask_two)\"\] {"
    lappend file_contents "  set cut_boundary \[get_attribute -objects \$cut_shape -name boundary\]"
    lappend file_contents "  foreach_in_collection m1_shape \[get_shapes -quiet -filter \"(layer.name == M1) && (mask_constraint == mask_one)\" -intersect \$cut_boundary\] {"
    # "intersect" does not give ideal M1 shape selection, i.e., M1 that has already been extended will be selected again for other cut shapes.
    # "if" statement below will ensure that only desired M1 shapes are modified.
    lappend file_contents "    set m1_boundary \[get_attribute -objects \$m1_shape -name boundary\]"
    lappend file_contents "    if {\[lindex \$cut_boundary 0 1\] == \[lindex \$m1_boundary 1 1\]} {"
    # M1 touching bottom of cut metal.
    lappend file_contents "      set m1_boundary \[list \[lindex \$m1_boundary 0] \"\[lindex \$m1_boundary 1 0\] \[expr \[lindex \$m1_boundary 1 1\] + 0.015\]\"\]"
    lappend file_contents "      set_attribute -objects \$m1_shape -name boundary -value \$m1_boundary"
    lappend file_contents "    } elseif {\[lindex \$cut_boundary 1 1\] == \[lindex \$m1_boundary 0 1\]} {"
    # M1 touching top of cut metal.
    lappend file_contents "      set m1_boundary \[list \"\[lindex \$m1_boundary 0 0\] \[expr \[lindex \$m1_boundary 0 1\] - 0.015\]\" \[lindex \$m1_boundary 1\]\]"
    lappend file_contents "      set_attribute -objects \$m1_shape -name boundary -value \$m1_boundary"
    lappend file_contents "    } else {"
    # M1 not touching cut metal so do nothing.
    lappend file_contents "    }"
    lappend file_contents "  }"
    lappend file_contents "}"
  }
  
  print_function_footer
  return [join $file_contents \n]
}
# end ICC2_Fix_DRCs

# 2022.03-2 - Generate boundary cells in ICC2.
proc ICC2_Generate_Boundary_Cells {mainParameters} {
  print_function_header
  upvar $mainParameters parameters
  
  set file_contents [list]
  
  # 2022.08 - Not required for tsmc3eff as it uses set_tap_boundary_wall_cell_rules instead.
  if {![regexp {tsmc3eff|umc28hpcp18} $parameters(project_name)]} {
    lappend file_contents "set_boundary_cell_rules -left_boundary_cell $parameters(boundary_left) -right_boundary_cell $parameters(boundary_right) -bottom_boundary_cells \"$parameters(boundary_bottom)\" -bottom_left_outside_corner_cell $parameters(boundary_bottom_left_outside_corner) -bottom_right_outside_corner_cell $parameters(boundary_bottom_right_outside_corner) -bottom_left_inside_corner_cells $parameters(boundary_bottom_left_inside_corner) -bottom_right_inside_corner_cells $parameters(boundary_bottom_right_inside_corner)" 
  }
  if {$parameters(boundary_bottom_left_inside_horizontal_abutment) != ""} {
    lappend file_contents "set_boundary_cell_rules -bottom_left_inside_horizontal_abutment_cells $parameters(boundary_bottom_left_inside_horizontal_abutment) -bottom_right_inside_horizontal_abutment_cells $parameters(boundary_bottom_right_inside_horizontal_abutment)"
  }
  if {$parameters(boundary_top) != ""} {
    lappend file_contents "set_boundary_cell_rules -top_boundary_cells \"$parameters(boundary_top)\" -top_left_outside_corner_cell $parameters(boundary_top_left_outside_corner) -top_right_outside_corner_cell $parameters(boundary_top_right_outside_corner) -top_left_inside_corner_cells $parameters(boundary_top_left_inside_corner) -top_right_inside_corner_cells $parameters(boundary_top_right_inside_corner)"
  }
  if {[regexp {tsmc5ff} $parameters(project_name)]} {
    lappend file_contents "set_boundary_cell_rules -mirror_left_inside_corner_cell -mirror_right_inside_corner_cell -mirror_right_inside_horizontal_abutment_cell -mirror_left_inside_horizontal_abutment_cell"
  }
  # 2022.03-4 - Rule also required for tsmc12ffc18.
  if {[regexp {tsmc12ffc|tsmc16ffc} $parameters(project_name)]} {
    lappend file_contents "set_boundary_cell_rules -mirror_right_outside_corner_cell"
  }
  # 2022.03-2 - Required for gf12lpp18.
  if {[regexp {gf12lpp18} $parameters(project_name)]} {
    lappend file_contents "set_boundary_cell_rules -mirror_left_boundary_cell -mirror_left_outside_corner_cell -mirror_right_inside_corner_cell"
  }
  # 2022.03-4 - Workaround also required for tsmc12ffc18.
  if {[regexp {tsmc5ff|tsmc12ffc|tsmc16ffc} $parameters(project_name)]} {
    lappend file_contents "set_app_options -name place.legalize.enable_advanced_rules -value false"
  }
  
  if {[regexp {tsmc3eff} $parameters(project_name)]} {
    lappend file_contents "set_tap_boundary_wall_cell_rules \
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
  
  if {[regexp {umc28hpcp18} $parameters(project_name)]} {
    lappend file_contents "set_boundary_cell_rules -left_boundary_cell $parameters(boundary_left) -right_boundary_cell $parameters(boundary_right)" 
  }
  
  # 2022.08 - tsmc3eff requires compile_tap_boundary_wall_cells instead.
  if {[regexp {tsmc3eff} $parameters(project_name)]} {
    lappend file_contents "set_app_options -name chipfinishing.enable_advanced_legalizer_postfixing -value true"
    lappend file_contents "set_app_options -name chipfinishing.enable_al_tap_insertion -value true"
    #lappend file_contents "set_app_options -name place.legalize.tap_cover_drop_edges -value {VDD}"
    #lappend file_contents "set_app_options -name plan.flow.segment_rule -value {vertical_odd}"
    lappend file_contents "set_app_options -name chipfinishing.enable_even_uniform_row_pattern -value true"
    lappend file_contents "compile_tap_boundary_wall_cells"
  } else {
    lappend file_contents "compile_boundary_cells"
  }
  
  # 2022.03-4 - Workaround also required for tsmc12ffc18.
  if {[regexp {tsmc5ff|tsmc12ffc|tsmc16ffc} $parameters(project_name)]} {
    lappend file_contents "set_app_options -name place.legalize.enable_advanced_rules -value true"
  }
  
  # 2022.03-2 - gf12lpp18 requires manual placement of inside corner cells.
  if {[regexp {gf12lpp18} $parameters(project_name)]} {
    # Remove all boundary cells except inside corner cells.
    lappend file_contents "remove_cells -force \[get_cells -filter \"ref_name !~ *CAPTINC13 && ref_name !~ *CAPBINC13\" boundarycell*\]"
    # Move inside corner cells to correct position.
    lappend file_contents "move_objects -delta {0.39 0} -force \[get_cells -filter \"orientation == R0 || orientation == MX\" boundarycell*\]"
    lappend file_contents "move_objects -delta {-0.39 0} -force \[get_cells -filter \"orientation == MY || orientation == R180\" boundarycell*\]"
    # Add remaining boundary cells.
    lappend file_contents "compile_boundary_cells"
  }
  print_function_footer
  return [join $file_contents \n]
}
# end ICC2_Generate_Boundary_Cells

# 2022.03-1 - Generate manual standard cell keepouts in ICC2 based on stdcell_manual_kpt_<macro/testcase> parameter.
proc ICC2_Generate_Manual_Stdcell_Keepouts {mainParameters testcase} {
  print_function_header
  upvar $mainParameters parameters
  
  set file_contents [list]
  
  # If parameter is not defined, exit proc.
  if {![info exists parameters(stdcell_manual_kpt_$testcase)]} {
    return
  }
  
  # Add standard cell keepouts. Parameter value must be given as sets of four numbers representing rectangular bbox (llx lly urx ury) of keepout.
  foreach {llx lly urx ury} $parameters(stdcell_manual_kpt_$testcase) {
    lappend file_contents "create_placement_blockage -boundary {{$llx $lly} {$urx $ury}}"
  }
  print_function_footer
  return [join $file_contents \n]
}
# end ICC2_Generate_Manual_Stdcell_Keepouts

# 2022.03 - Generate top level pin labels in ICC2 from subcells. Signal pin names for spare cells are uniquified to eliminate LVS opens.
proc ICC2_Generate_Pin_Labels {mainParameters power_supplies} {
  print_function_header
  upvar $mainParameters parameters
  
  set file_contents [list]

  lappend file_contents "set terminals \[get_terminals -hierarchical -include_lib_cell\]"
  lappend file_contents "foreach_in_collection terminal \$terminals \{"
  lappend file_contents "  set text \[get_attribute -objects \$terminal -name port.name\]"
  lappend file_contents "  set parent_cell_name \[get_attribute -objects \$terminal -name parent_cell.name\]"
  lappend file_contents "  if {\[regexp {SpareCell.*} \$parent_cell_name\] && !(\[regexp \{${power_supplies}\} \$text\])} {"
  lappend file_contents "    set text \${parent_cell_name}_\$text"
  lappend file_contents "  }"
  lappend file_contents "  set layer \[get_attribute -objects \$terminal -name layer.name\]"
  # Using boundary for text origin coordinate instead of bbox as bbox coordinate may not fall within non-rectangular pin shape.
  lappend file_contents "  set origin \[lindex \[get_attribute -objects \$terminal -name boundary\] 0\]"
  if {[regexp {int22ffl18} $parameters(project_name)]} {
    lappend file_contents "  if \[regexp \{(m\\d+)\} \$layer match layer\] \{"
    lappend file_contents "    set layer \$\{layer\}_pin"
  } elseif {[regexp {gf12lpp18} $parameters(project_name)]} {
    #2022.03-2 - Check for metal layer by seeing if first letter of layer is M, C, K or G. Text should be added to same metal layer in ICC2 to output to label datatype, hence no "set layer" required.
    lappend file_contents "  if \[regexp \{^(M|C|K|G)\} \$layer match\] \{"
  } else {
    lappend file_contents "  if \[regexp \{M(\\d+)\} \$layer match layer\] \{"
    lappend file_contents "    set layer TEXT\$\{layer\}"
  }
  lappend file_contents "    create_shape -shape_type text -layer \$layer -origin \$origin -height 0.1 -text \$text"
  lappend file_contents "  \}"
  lappend file_contents "\}"
  print_function_footer
  return [join $file_contents \n]
}
# end ICC2_Generate_Pin_Labels

# 2022.11 - Generate top level ports.
# 2022.12-1 - Added support for voltage high label additions in tsmc5ff.
proc ICC2_Generate_Ports {mainParameters pin_mapping} {
  print_function_header
  upvar $mainParameters parameters
  
  set file_contents [list]
  lappend file_contents "set pin_mapping {$pin_mapping}"
  
  # Remove net connections from spare cell inputs.
  lappend file_contents "if {\[sizeof_collection \[get_nets -quiet \"*Logic0*\"\]\]} {"
  lappend file_contents "  disconnect_net -net \[get_nets \"*Logic0*\"\] -all"
  lappend file_contents "}"
  
  # Iterate through pins.
  lappend file_contents "foreach_in_collection pin \[get_pins\] {"
  lappend file_contents "  set pin_name \[get_attribute -objects \$pin -name name\]"
  lappend file_contents "  set direction \[get_attribute -objects \$pin -name direction\]"
  lappend file_contents "  set port_type \[get_attribute -objects \$pin -name port_type\]"
  lappend file_contents "  set cell \[get_attribute -objects \$pin -name cell\]"
  lappend file_contents "  set cellname \[get_attribute -objects \$cell -name name\]"
  # Get connected net. If net doesn't exist, set net name from pin_mapping dictionary or use a uniquified name, and create the net.
  lappend file_contents "  set net_name \[get_attribute -quiet -objects \$pin -name net_name\]"
  lappend file_contents "  if {\$net_name == \"\"} {"
  lappend file_contents "    if {\[dict exists \$pin_mapping \$cellname \$pin_name\]} {"
  lappend file_contents "      set net_name \[dict get \$pin_mapping \$cellname \$pin_name\]"
  lappend file_contents "    } elseif {\[dict exists \$pin_mapping ALL \$pin_name\]} {"
  lappend file_contents "      set net_name \[dict get \$pin_mapping ALL \$pin_name\]"
  lappend file_contents "    } else {"
  lappend file_contents "      set net_name \${cellname}_\$pin_name"
  lappend file_contents "    }"
  lappend file_contents "  }"
  lappend file_contents "  if {!\[sizeof_collection \[get_nets -quiet \$net_name\]\]} {"
  lappend file_contents "    set net \[create_net \$net_name\]"
  lappend file_contents "  } else {"
  lappend file_contents "    set net \[get_nets \$net_name\]"
  lappend file_contents "  }"
  # Set net type to power or ground, if needed. Once a net is set to either power or ground, it doesn't get set back to signal type even if connected to a signal pin.
  lappend file_contents "  switch -- \$port_type {"
  lappend file_contents "    power {"
  lappend file_contents "      set_attribute -objects \$net -name net_type -value power"
  lappend file_contents "    }"
  lappend file_contents "    ground {"
  lappend file_contents "      set_attribute -objects \$net -name net_type -value ground"
  lappend file_contents "    }"
  lappend file_contents "  }"
  # Connect net to pin if not already connected.
  lappend file_contents "  if {\[sizeof_collection \[get_pins -filter undefined(net) \$pin\]\]} {"
  lappend file_contents "    connect_net -net \$net \$pin"
  lappend file_contents "  }"
  # Create port if it doesn't exist and connect it to net.
  lappend file_contents "  if {!\[sizeof_collection \[get_ports -quiet \$net_name\]\]} {"
  lappend file_contents "    set port \[create_port -direction \$direction \$net_name\]"
  lappend file_contents "    connect_net -net \$net \$port"
  lappend file_contents "  }"
  # Create terminals.
  lappend file_contents "  foreach_in_collection terminal \[get_terminals -quiet -of_objects \$pin\] {"
  lappend file_contents "    set boundary \[get_attribute -objects \$terminal -name boundary\]"
  lappend file_contents "    set layer \[get_attribute -objects \$terminal -name layer\]"
  lappend file_contents "    set mask \[get_attribute -objects \$terminal -name shape.mask_constraint\]"
  lappend file_contents "    set new_terminal \[create_terminal -port \$net_name -boundary \$boundary -layer \$layer\]"
  lappend file_contents "    set_attribute -objects \$new_terminal -name shape.mask_constraint -value \$mask"
  lappend file_contents "  }"
  lappend file_contents "}"
  
  # Create voltage high labels.
  switch -regexp -- $parameters(project_name) {
    {tsmc5ff} {
      set voltage_high_layers [dict create M0 300:8 M1 301:8 M2 302:8 M3 303:8 M4 304:8 M5 305:8 M6 306:8 M7 307:8 M8 308:8 M9 309:8 M10 310:8 M11 311:8 M12 312:8 M13 313:8 M14 314:8 M15 315:8 M16 316:8 M17 317:8]
    }
    {tsmc7ff} {
      set voltage_high_layers [dict create M0 180:230 M1 31:230 M2 32:230 M3 33:230 M4 34:230 M5 35:230 M6 36:230 M7 37:230 M8 38:230 M9 39:230 M10 40:230 M11 41:230 M12 42:230 M13 43:230 M14 44:230 M15 45:230 M16 46:230]
    }
    {tsmc12ffc} {
      set voltage_high_layers [dict create M1 31:230 M2 32:230 M3 33:230 M4 34:230 M5 35:230 M6 36:230 M7 37:230 M8 38:230 M9 39:230 M10 40:230 M11 41:230 M12 42:230 M13 43:230]
    }
  }
  
  if {[regexp {tsmc5ff|tsmc7ff|tsmc12ffc} $parameters(project_name)]} {
    lappend file_contents "set voltage_high_layers {$voltage_high_layers}"
    lappend file_contents "set net_voltage_high {$parameters(net_voltage_high)}"
#    lappend file_contents "foreach_in_collection terminal \[get_terminals\] {"
#    lappend file_contents "  set port_name \[get_attribute -objects \$terminal -name port.name\]"
#    lappend file_contents "  if {\[dict exists \$net_voltage_high \$port_name\]} {"
#    lappend file_contents "    set layer_name \[get_attribute -objects \$terminal -name layer.name\]"
#    lappend file_contents "    set point \[lindex \[get_attribute -objects \$terminal -name boundary\] 0\]"
#    lappend file_contents "    create_shape -shape_type text -layer \[dict get \$voltage_high_layers \$layer_name\] -origin \$point -height 0.1 -text \[dict get \$net_voltage_high \$port_name\]"
#    lappend file_contents "  }"
#    lappend file_contents "}"
    lappend file_contents "dict for {net voltage} \$net_voltage_high {"
    lappend file_contents "  foreach_in_collection terminal \[get_terminals -filter \"port.name == \$net\"\] {"
    lappend file_contents "    set layer_name \[get_attribute -objects \$terminal -name layer.name\]"
    lappend file_contents "    set point \[lindex \[get_attribute -objects \$terminal -name boundary\] 0\]"
    lappend file_contents "    create_shape -shape_type text -layer \[dict get \$voltage_high_layers \$layer_name\] -origin \$point -height 0.1 -text \$voltage"
    lappend file_contents "  }"
    lappend file_contents "}"
  }
  
  print_function_footer
  return [join $file_contents \n]
}
# end ICC2_Generate_Ports

# 2022.04-1 - Generate tap cells in ICC2.
proc ICC2_Generate_Tap_Cells {mainParameters} {
  print_function_header
  upvar $mainParameters parameters
  
  set file_contents [list]
    
  switch -regexp -- $parameters(project_name) {
    {tsmc5ff} {
      # Avoid DRCs due to misaligned vertically abutted taps and tap abutment to certain boundary cells.
      # Although taps can abut directly vertically, -no_abutment option is the easiest way to avoid the misaligned tap scenario.
      lappend file_contents "create_tap_cells -lib_cell $parameters(stdcell_tap) -distance $parameters(tap_distance) -pattern stagger -skip_fixed_cells -no_abutment -no_abutment_cells \"$parameters(boundary_bottom_left_inside_horizontal_abutment) $parameters(boundary_bottom_right_inside_horizontal_abutment)\""
    
      # Taps can still be placed in misaligned vertically abutted configuration in narrow stdcell regions.
      # While it doesn't appear possible for 3 taps to be vertically abutted, if this were to happen, this could be problematic as a tap aligned to the tap above could end up misaligned to the tap below depending upon tap collection order.
      # Possible fix for this scenario is to sort_collection on y-coordinate prior to iterating through taps. Not implemented as this doesn't appear to be required.
      lappend file_contents "set tap_width \[get_attribute -objects $parameters(stdcell_tap) -name width\]"
      lappend file_contents "foreach_in_collection tap \[get_cells tapfiller*\] {"
      lappend file_contents "  set tap_name \[get_attribute -objects \$tap -name name\]"
	    lappend file_contents "  set tap_bbox \[get_attribute -objects \$tap -name boundary_bbox\]" 
	    lappend file_contents "  set tap_llx \[lindex \$tap_bbox 0 0\]"
	    lappend file_contents "  foreach_in_collection abutting_tap \[get_cells -quiet -filter \"(ref_name == $parameters(stdcell_tap)) && (name != \\\"\$tap_name\\\")\" -intersect \$tap_bbox\] {"
      lappend file_contents "    set abutting_tap_llx \[lindex \[get_attribute -objects \$abutting_tap -name boundary_bbox\] 0 0\]"
      lappend file_contents "    set delta_x \[expr \$tap_llx - \$abutting_tap_llx\]"
      lappend file_contents "    set abs_delta_x \[expr abs(\$delta_x)\]"
      lappend file_contents "    if {(\$abs_delta_x != 0) && (\$abs_delta_x != \$tap_width)} {"
      lappend file_contents "      move_objects -delta \"\$delta_x 0\" -force \$abutting_tap"
      lappend file_contents "    }"
      lappend file_contents "  }"
      lappend file_contents "}" 
    }
    default {
      lappend file_contents "create_tap_cells -lib_cell $parameters(stdcell_tap) -distance $parameters(tap_distance) -pattern stagger -skip_fixed_cells"
    }
  }
  print_function_footer
  return [join $file_contents \n]
}
# end ICC2_Generate_Tap_Cells

# 2022.04-2 - Write GDS in ICC2.
# 2022.10 - Renamed to ICC2_Write_Layout and added OASIS support. Using dbu parameter to determine units.
proc ICC2_Write_Layout {mainParameters layout_files macro} {
  print_function_header
  upvar $mainParameters parameters
  
  set file_contents [list]
  
  if {$parameters(output_layout_format) == "GDS"} {
    lappend file_contents "set_app_options -name file.gds.text_all_pins -value true"
    switch -regexp -- $parameters(project_name) {
      {tsmc7ff} {
        lappend file_contents "write_gds -compress -connect_below_cut_metal -layer_map $parameters(icc2_gds_layer_map) -long_names -merge_files \"$layout_files\" -merge_gds_top_cell $macro -units [expr round(1 / $parameters(dbu) / 1e6)] ${macro}$parameters(layout_file_extension_zipped)"
      }
      {tsmc12ffc|tsmc16ffc|umc28hpcp18} {
        # 2022.03-4 - Manually set units to 1000 for 1nm DBU as scale_factor for library is incorrect due to stdcell NDM.
        # 2022.04-2 - Layer map is in ICC format.
        # 2022.09 - Same workaround required for tsmc16ffc18.
        #lappend file_contents "write_gds -compress -layer_map $parameters(icc2_gds_layer_map) -layer_map_format icc_extended -long_names -merge_files \"$layout_files\" -merge_gds_top_cell $macro -units 1000 ${macro}.gds.gz"
        lappend file_contents "write_gds -compress -layer_map $parameters(icc2_gds_layer_map) -layer_map_format icc_extended -long_names -merge_files \"$layout_files\" -merge_gds_top_cell $macro -units [expr round(1 / $parameters(dbu) / 1e6)] ${macro}$parameters(layout_file_extension_zipped)"
      }
      default {
        #lappend file_contents "write_gds -compress -layer_map $parameters(icc2_gds_layer_map) -long_names -merge_files \"$layout_files\" -merge_gds_top_cell $macro -units \[get_attribute -objects \[current_lib\] -name scale_factor\] ${macro}.gds.gz"
        lappend file_contents "write_gds -compress -layer_map $parameters(icc2_gds_layer_map) -long_names -merge_files \"$layout_files\" -merge_gds_top_cell $macro -units [expr round(1 / $parameters(dbu) / 1e6)] ${macro}$parameters(layout_file_extension_zipped)"
      }
    }
  } else {
    lappend file_contents "set_app_options -name file.oasis.text_all_pins -value true"
    switch -regexp -- $parameters(project_name) {
      {tsmc7ff} {
        lappend file_contents "write_oasis -compress 6 -connect_below_cut_metal -layer_map $parameters(icc2_gds_layer_map) -merge_files \"$layout_files\" -merge_oasis_top_cell $macro -units [expr round(1 / $parameters(dbu) / 1e6)] ${macro}$parameters(layout_file_extension_zipped)"
      }
      {tsmc12ffc|tsmc16ffc|umc28hpcp18} {
        lappend file_contents "write_oasis -compress 6 -layer_map $parameters(icc2_gds_layer_map) -layer_map_format icc_extended -merge_files \"$layout_files\" -merge_oasis_top_cell $macro -units [expr round(1 / $parameters(dbu) / 1e6)] ${macro}$parameters(layout_file_extension_zipped)"
      }
      default {
        lappend file_contents "write_oasis -compress 6 -layer_map $parameters(icc2_gds_layer_map) -merge_files \"$layout_files\" -merge_oasis_top_cell $macro -units [expr round(1 / $parameters(dbu) / 1e6)] ${macro}$parameters(layout_file_extension_zipped)"
      }
    }
  }
  print_function_footer
  return [join $file_contents \n]
}
# end ICC2_Write_Layout

# 2022.12-1 - Write LEF in ICC2.
proc ICC2_Write_LEF {cell} {
  print_function_header

  set file_contents [list]

  lappend file_contents "create_frame -block_all false -hierarchical false"
  lappend file_contents "write_lef -include cell ${cell}.lef"
  
  print_function_footer
  return [join $file_contents \n] 
}
# end ICC2_Write_LEF

# 2022.11 - Write Verilog netlist in ICC2.
proc ICC2_Write_Netlist {mainParameters macro} {
  print_function_header
  upvar $mainParameters parameters
  
  set file_contents [list]
  
  # Changing boundary cell design_type to end_cap from its default of lib_cell to avoid inclusion in Verilog netlist export.
  if {[regexp {umc28hpcp18} $parameters(project_name)]} {
    lappend file_contents "set_app_options -name design.enable_lib_cell_editing -value mutable"
    lappend file_contents "set_attribute -name design_type -value end_cap $parameters(boundary_left)"
  }
  
  lappend file_contents "write_verilog -exclude {end_cap_cells filler_cells well_tap_cells} ${macro}.v"
  
  print_function_footer
  return [join $file_contents \n] 
}
# end ICC2_Write_Netlist

# Merge macro layout as subcell into wrapper.
proc Merge_Layout {mainParameters macro wrapper} {
  print_function_header
  upvar $mainParameters parameters
  iprint "Generating $wrapper ${parameters(output_layout_format)}."
  
  set file_contents [list]
  lappend file_contents "#!/bin/tcsh"
  lappend file_contents "msip_layGdsMerge $parameters(gds_$wrapper) $parameters(gds_$macro) -o ${wrapper}$parameters(layout_file_extension_zipped)"
  write_file merge_layout.tcsh [join $file_contents \n]
  file attributes merge_layout.tcsh -permissions +x
  
  print_function_footer
  return ./merge_layout.tcsh
}
# end Merge_Layout

# Runs physical verification.
# Note for gf12lpp18: as of 20210916, "--type drc --prefix DRC" actually runs MSIP-Tools->Verification->Internal->DRC. 
#   In order to run MSIP-Tools->Verification->Tapeout->DRC_DPcolored, set "--type drc --prefix DRCsignOff".
#   Also, change the error file path to "find -path \"*drcsignoff_icv/${testcase}.LAYOUT_ERRORS\".
proc Run_PV {mainParameters testcase} {
  print_function_header
  upvar $mainParameters parameters
  global LOGFILE
  #iprint "Running PV on ${testcase}..."
 
  set pv_launch_scripts [list]
  
  set file_contents [list]
  lappend file_contents "module unload msip_cd_pv"
  lappend file_contents "module load msip_cd_pv/$parameters(msip_cd_pv_version)"
  lappend file_contents "setenv RUN_DIR_ROOT [pwd]/pv"
  write_file ude_sourceme [join $file_contents \n]
  
  if {[info exists parameters(drc_icv)] && $parameters(drc_icv)} {
    iprint "Running DRC_ICV on ${testcase}."
    set file_contents [list]
    lappend file_contents "set useGrid $parameters(grid)"
    lappend file_contents "set enableGridFilling $parameters(grid)"
    #lappend file_contents "set gridUserDefRes \"-l h_vmem=$parameters(mem),mem_free=$parameters(mem)\""
    lappend file_contents "set gridProc $parameters(drc_icv_grid_processes)"
    if {[info exists parameters(drc_icv_options_file)] && ($parameters(drc_icv_options_file) != "")} {
      lappend file_contents "set optionsFile $parameters(drc_icv_options_file)"
    }
    if {[info exists parameters(drc_icv_runset)] && ($parameters(drc_icv_runset) != "")} {
      lappend file_contents "set runset $parameters(drc_icv_runset)"
    }
    lappend file_contents "set icvUnselectRuleNames \"$parameters(drc_icv_unselect_rule_names)\""
    # Grid filling fix and general instructions: https://jira.internal.synopsys.com/browse/P10020416-28026
    if {$parameters(drc_feol_fill) && $parameters(drc_beol_fill)} {
      lappend file_contents "set enableDRCFilling true"
      #lappend file_contents "set enableFEOLFilling true"
      #lappend file_contents "set enableBEOLFilling true"
      lappend file_contents "set enableFILLFEOLFilling false"
      lappend file_contents "set enable${parameters(drc_feol_prefix)}Filling true"
      lappend file_contents "set enableFILLBEOLFilling false"
      lappend file_contents "set enable${parameters(drc_beol_prefix)}Filling true"
    } elseif {$parameters(drc_feol_fill)} {
      lappend file_contents "set enableDRCFilling true"
      #lappend file_contents "set enableFEOLFilling true"
      #lappend file_contents "set enableBEOLFilling false"
      lappend file_contents "set enableFILLFEOLFilling false"
      lappend file_contents "set enable${parameters(drc_feol_prefix)}Filling true"
      lappend file_contents "set enableFILLBEOLFilling false"
    } elseif {$parameters(drc_beol_fill)} {
      lappend file_contents "set enableDRCFilling true"
      #lappend file_contents "set enableFEOLFilling false"
      #lappend file_contents "set enableBEOLFilling true"
      lappend file_contents "set enableFILLFEOLFilling false"
      lappend file_contents "set enableFILLBEOLFilling false"
      lappend file_contents "set enable${parameters(drc_beol_prefix)}Filling true"
    }
    
    # 2022.08 - Error limit.
    if {[info exists parameters(drc_error_limit)] && ($parameters(drc_error_limit) != "")} {
      lappend file_contents "set errorLimitEnabled true"
      lappend file_contents "set errorLimit $parameters(drc_error_limit)"
    }
    write_file pvbatch_config_drc_icv [join $file_contents \n]
    
    set file_contents [list]
    lappend file_contents "#!/bin/tcsh"
    lappend file_contents "module unload msip_cd_pv"
    lappend file_contents "module load msip_cd_pv/$parameters(msip_cd_pv_version)"
    lappend file_contents "pvbatch --projectType $parameters(project_type) --projectName $parameters(project_name) --releaseName $parameters(release_name) --metalStack $parameters(metal_stack) --type drc --prefix $parameters(drc_prefix) --streamPath [pwd]/${testcase}$parameters(layout_file_extension_zipped) --cellName $testcase --layoutFormat $parameters(output_layout_format) --tool icv --config [pwd]/pvbatch_config_drc_icv --udeArgs \"--log [pwd]/pvbatch_drc_icv.log --sourceShellFile [pwd]/ude_sourceme\" --tmpLibPath"
    # 2022.07 - Updated output file structure to match CKT P4 release structure.
    lappend file_contents "mkdir -p ../../crd_results/${testcase}/icv/drc"
    lappend file_contents "find -ipath \"*${parameters(drc_prefix)}_icv/${testcase}.LAYOUT_ERRORS\" -exec ln -s \"[pwd]/{}\" ../../crd_results/${testcase}/icv/drc/drc_${testcase}_${parameters(metal_stack)}.rpt \\;"
    lappend file_contents "ln -s $LOGFILE ../../crd_results/${testcase}/icv/drc/drc_${testcase}_${parameters(metal_stack)}.log"
    write_file pv_drc_icv.tcsh [join $file_contents \n]
    file attributes pv_drc_icv.tcsh -permissions +x
    lappend pv_launch_scripts "qsub -P bnormal -cwd -V -m a -b y ./pv_drc_icv.tcsh"
    # Delay no longer required with lib.defs access fix: https://jira.internal.synopsys.com/browse/P10020416-27925
    #after 120000
  }
  
  if {[info exists parameters(drc_calibre)] && $parameters(drc_calibre)} {
    iprint "Running DRC_CALIBRE on ${testcase}."
    set file_contents [list]
    lappend file_contents "set calexExtraArg \"$parameters(drc_calex_extra_arguments)\""
    # Grid filling fix and general instructions: https://jira.internal.synopsys.com/browse/P10020416-28026
    # 2022.08 - Added required preferences for Calibre.
    if {$parameters(drc_feol_fill) && $parameters(drc_beol_fill)} {
      lappend file_contents "set enableDRCFilling true"
      #lappend file_contents "set enableFEOLFilling true"
      #lappend file_contents "set enableBEOLFilling true"
      lappend file_contents "set enableFILLFEOLFilling false"
      lappend file_contents "set enable${parameters(drc_feol_prefix)}Filling true"
      lappend file_contents "set enableFILLBEOLFilling false"
      lappend file_contents "set enable${parameters(drc_beol_prefix)}Filling true"
      lappend file_contents "db::createPref MSIPDRCenableDRCFilling -value 1"
      lappend file_contents "db::createPref MSIPDRCimportCalibreFillBEOLGDSName -value \"BEOL\""
      lappend file_contents "db::createPref MSIPDRCimportCalibreFillFEOLGDSName -value \"FEOL\""
    } elseif {$parameters(drc_feol_fill)} {
      lappend file_contents "set enableDRCFilling true"
      #lappend file_contents "set enableFEOLFilling true"
      #lappend file_contents "set enableBEOLFilling false"
      lappend file_contents "set enableFILLFEOLFilling false"
      lappend file_contents "set enable${parameters(drc_feol_prefix)}Filling true"
      lappend file_contents "set enableFILLBEOLFilling false"
      lappend file_contents "db::createPref MSIPDRCenableDRCFilling -value 1"
      lappend file_contents "db::createPref MSIPDRCimportCalibreFillFEOLGDSName -value \"FEOL\""
    } elseif {$parameters(drc_beol_fill)} {
      lappend file_contents "set enableDRCFilling true"
      #lappend file_contents "set enableFEOLFilling false"
      #lappend file_contents "set enableBEOLFilling true"
      lappend file_contents "set enableFILLFEOLFilling false"
      lappend file_contents "set enableFILLBEOLFilling false"
      lappend file_contents "set enable${parameters(drc_beol_prefix)}Filling true"
      lappend file_contents "db::createPref MSIPDRCenableDRCFilling -value 1"
      lappend file_contents "db::createPref MSIPDRCimportCalibreFillBEOLGDSName -value \"BEOL\""
    }
    
    # 2022.08 - Error limit.
    if {[info exists parameters(drc_error_limit)] && ($parameters(drc_error_limit) != "")} {
      lappend file_contents "set errorLimitEnabled true"
      lappend file_contents "set errorLimit $parameters(drc_error_limit)"
    }
    write_file pvbatch_config_drc_calibre [join $file_contents \n]
    
    set file_contents [list]
    lappend file_contents "#!/bin/tcsh"
    lappend file_contents "module unload msip_cd_pv"
    lappend file_contents "module load msip_cd_pv/$parameters(msip_cd_pv_version)"
    lappend file_contents "pvbatch --projectType $parameters(project_type) --projectName $parameters(project_name) --releaseName $parameters(release_name) --metalStack $parameters(metal_stack) --type drc --prefix $parameters(drc_prefix) --streamPath [pwd]/${testcase}$parameters(layout_file_extension_zipped) --cellName $testcase --layoutFormat $parameters(output_layout_format) --tool calibre --config [pwd]/pvbatch_config_drc_calibre --udeArgs \"--log [pwd]/pvbatch_drc_calibre.log --sourceShellFile [pwd]/ude_sourceme\" --tmpLibPath"
    # 2022.07 - Updated output file structure to match CKT P4 release structure.
    lappend file_contents "mkdir -p ../../crd_results/${testcase}/calibre/drc"
    lappend file_contents "find -ipath \"*${parameters(drc_prefix)}_calibre/drc_summary.report\" -exec ln -s \"[pwd]/{}\" ../../crd_results/${testcase}/calibre/drc/drc_${testcase}_${parameters(metal_stack)}.rpt \\;"
    lappend file_contents "ln -s $LOGFILE ../../crd_results/${testcase}/calibre/drc/drc_${testcase}_${parameters(metal_stack)}.log"
    write_file pv_drc_calibre.tcsh [join $file_contents \n]
    file attributes pv_drc_calibre.tcsh -permissions +x
    lappend pv_launch_scripts "qsub -P bnormal -cwd -V -m a -b y ./pv_drc_calibre.tcsh"
    # Delay no longer required with lib.defs access fix: https://jira.internal.synopsys.com/browse/P10020416-27925
    #after 120000
  }
  
  if {[info exists parameters(lvs_icv)] && $parameters(lvs_icv)} {
    iprint "Running LVS_ICV on ${testcase}."
    set file_contents [list]
    lappend file_contents "set useGrid $parameters(grid)"
    #lappend file_contents "set gridUserDefRes \"-l h_vmem=$parameters(mem),mem_free=$parameters(mem)\""
    lappend file_contents "set gridProc $parameters(lvs_icv_grid_processes)"
    
    # 2022.03-2 - Removed FOUNDRY_DEFAULT from virtual_connect parameter in parameters file template, so need to check for missing parameter or empty string.
    if {[info exists parameters(virtual_connect_icv)] && ($parameters(virtual_connect_icv) != "")} {
      lappend file_contents "set virtualConnect $parameters(virtual_connect_icv)"
    }
    write_file pvbatch_config_lvs_icv [join $file_contents \n]
    
    set file_contents [list]
    lappend file_contents "#!/bin/tcsh"
    lappend file_contents "module unload msip_cd_pv"
    lappend file_contents "module load msip_cd_pv/$parameters(msip_cd_pv_version)"
    lappend file_contents "pvbatch --projectType $parameters(project_type) --projectName $parameters(project_name) --releaseName $parameters(release_name) --metalStack $parameters(metal_stack) --type lvs --prefix $parameters(lvs_prefix) --streamPath [pwd]/${testcase}$parameters(layout_file_extension_zipped) --cdlPath [pwd]/${testcase}.cdl --cellName $testcase --layoutFormat $parameters(output_layout_format) --tool icv --config [pwd]/pvbatch_config_lvs_icv --udeArgs \"--log [pwd]/pvbatch_lvs_icv.log --sourceShellFile [pwd]/ude_sourceme\" --tmpLibPath"
    # 2022.07 - Updated output file structure to match CKT P4 release structure.
    lappend file_contents "mkdir -p ../../crd_results/${testcase}/icv/erc"
    lappend file_contents "mkdir -p ../../crd_results/${testcase}/icv/lvs"
    lappend file_contents "find -ipath \"*${parameters(lvs_prefix)}_icv/${testcase}.LAYOUT_ERRORS\" -exec ln -s \"[pwd]/{}\" ../../crd_results/${testcase}/icv/erc/erc_${testcase}_${parameters(metal_stack)}.rpt \\;"
    lappend file_contents "ln -s $LOGFILE ../../crd_results/${testcase}/icv/erc/erc_${testcase}_${parameters(metal_stack)}.log"
    lappend file_contents "find -ipath \"*${parameters(lvs_prefix)}_icv/${testcase}.LVS_ERRORS\" -exec ln -s \"[pwd]/{}\" ../../crd_results/${testcase}/icv/lvs/lvs_${testcase}_${parameters(metal_stack)}.rpt \\;"
    lappend file_contents "ln -s $LOGFILE ../../crd_results/${testcase}/icv/lvs/lvs_${testcase}_${parameters(metal_stack)}.log"
    write_file pv_lvs_icv.tcsh [join $file_contents \n]
    file attributes pv_lvs_icv.tcsh -permissions +x
    lappend pv_launch_scripts "qsub -P bnormal -cwd -V -m a -b y ./pv_lvs_icv.tcsh"
    # Delay no longer required with lib.defs access fix: https://jira.internal.synopsys.com/browse/P10020416-27925
    #after 120000
  }
  
  if {[info exists parameters(lvs_calibre)] && $parameters(lvs_calibre)} {
    iprint "Running LVS_CALIBRE on ${testcase}."
    set file_contents [list]
    
    # 2022.03-2 - Removed FOUNDRY_DEFAULT from virtual_connect parameter in parameters file template, so need to check for missing parameter or empty string.
    if {[info exists parameters(virtual_connect_calibre)] && ($parameters(virtual_connect_calibre) != "")} {
      lappend file_contents "set virtualConnect $parameters(virtual_connect_calibre)"
    }
    
    lappend file_contents "set calexExtraArg \"$parameters(lvs_calex_extra_arguments)\""
    write_file pvbatch_config_lvs_calibre [join $file_contents \n]
    
    set file_contents [list]
    lappend file_contents "#!/bin/tcsh"
    lappend file_contents "module unload msip_cd_pv"
    lappend file_contents "module load msip_cd_pv/$parameters(msip_cd_pv_version)"
    lappend file_contents "pvbatch --projectType $parameters(project_type) --projectName $parameters(project_name) --releaseName $parameters(release_name) --metalStack $parameters(metal_stack) --type lvs --prefix $parameters(lvs_prefix) --streamPath [pwd]/${testcase}$parameters(layout_file_extension_zipped) --cdlPath [pwd]/${testcase}.cdl --cellName $testcase --layoutFormat $parameters(output_layout_format) --tool calibre --config [pwd]/pvbatch_config_lvs_calibre --udeArgs \"--log [pwd]/pvbatch_lvs_calibre.log --sourceShellFile [pwd]/ude_sourceme\" --tmpLibPath"
    # 2022.07 - Updated output file structure to match CKT P4 release structure.
    lappend file_contents "mkdir -p ../../crd_results/${testcase}/calibre/erc"
    lappend file_contents "mkdir -p ../../crd_results/${testcase}/calibre/lvs"
    #lappend file_contents "find -path \"*lvs_calibre/cell.results.ext\" -exec ln -s \"${testcase}/{}\" ../${testcase}.LVS_CALIBRE.cell.results.ext \\;"
    lappend file_contents "find -ipath \"*${parameters(lvs_prefix)}_calibre/erc_summary.report\" -exec ln -s \"[pwd]/{}\" ../../crd_results/${testcase}/calibre/erc/erc_${testcase}_${parameters(metal_stack)}.rpt \\;"
    lappend file_contents "ln -s $LOGFILE ../../crd_results/${testcase}/calibre/erc/erc_${testcase}_${parameters(metal_stack)}.log"
    lappend file_contents "find -ipath \"*${parameters(lvs_prefix)}_calibre/cell.results\" -exec ln -s \"[pwd]/{}\" ../../crd_results/${testcase}/calibre/lvs/lvs_${testcase}_${parameters(metal_stack)}.rpt \\;"
    lappend file_contents "ln -s $LOGFILE ../../crd_results/${testcase}/calibre/lvs/lvs_${testcase}_${parameters(metal_stack)}.log"
    write_file pv_lvs_calibre.tcsh [join file_contents \n]
    file attributes pv_lvs_calibre.tcsh -permissions +x
    lappend pv_launch_scripts "qsub -P bnormal -cwd -V -m a -b y ./pv_lvs_calibre.tcsh"
    # Delay no longer required with lib.defs access fix: https://jira.internal.synopsys.com/browse/P10020416-27925
    #after 120000
  }
 
  if {[info exists parameters(perccnod_icv)] && $parameters(perccnod_icv)} {
    iprint "Running PERCCNOD_ICV on ${testcase}."
    set file_contents [list]
    lappend file_contents "set useGrid $parameters(grid)"
    lappend file_contents "set gridProc $parameters(perccnod_icv_grid_processes)"
    
    # 2022.03-2 - Removed FOUNDRY_DEFAULT from virtual_connect parameter in parameters file template, so need to check for missing parameter or empty string.
    if {[info exists parameters(virtual_connect_icv)] && ($parameters(virtual_connect_icv) != "")} {
      lappend file_contents "set virtualConnect $parameters(virtual_connect_icv)"
    }
    write_file pvbatch_config_perccnod_icv [join $file_contents \n]
    
    set file_contents [list]
    lappend file_contents "#!/bin/tcsh"
    lappend file_contents "module unload msip_cd_pv"
    lappend file_contents "module load msip_cd_pv/$parameters(msip_cd_pv_version)"
    lappend file_contents "pvbatch --projectType $parameters(project_type) --projectName $parameters(project_name) --releaseName $parameters(release_name) --metalStack $parameters(metal_stack) --type perc --prefix $parameters(perccnod_prefix) --streamPath [pwd]/${testcase}$parameters(layout_file_extension_zipped) --cdlPath [pwd]/${testcase}.cdl --cellName $testcase --layoutFormat $parameters(output_layout_format) --tool icv --config [pwd]/pvbatch_config_perccnod_icv --udeArgs \"--log [pwd]/pvbatch_perccnod_icv.log --sourceShellFile [pwd]/ude_sourceme\" --tmpLibPath"
    # 2022.07 - Updated output file structure to match CKT P4 release structure.
    lappend file_contents "mkdir -p ../../crd_results/${testcase}/icv/perc_cnod"
    lappend file_contents "find -ipath \"*${parameters(perccnod_prefix)}_icv/${testcase}.LAYOUT_ERRORS\" -exec ln -s \"[pwd]/{}\" ../../crd_results/${testcase}/icv/perc_cnod/perc_cnod_${testcase}_${parameters(metal_stack)}.rpt \\;"
    lappend file_contents "ln -s $LOGFILE ../../crd_results/${testcase}/icv/perc_cnod/perc_cnod_${testcase}_${parameters(metal_stack)}.log"
    write_file pv_perccnod_icv.tcsh [join $file_contents \n]
    file attributes pv_perccnod_icv.tcsh -permissions +x
    lappend pv_launch_scripts "qsub -P bnormal -cwd -V -m a -b y ./pv_perccnod_icv.tcsh"
    # Delay no longer required with lib.defs access fix: https://jira.internal.synopsys.com/browse/P10020416-27925
    #after 120000
  }
  
  if {[info exists parameters(perccnod_calibre)] && $parameters(perccnod_calibre)} {
    iprint "Running PERCCNOD_CALIBRE on ${testcase}."
    set file_contents [list]
    lappend file_contents "set calexExtraArg \"$parameters(perccnod_calex_extra_arguments)\""
    
    # 2022.03-2 - Removed FOUNDRY_DEFAULT from virtual_connect parameter in parameters file template, so need to check for missing parameter or empty string.
    if {[info exists parameters(virtual_connect_calibre)] && ($parameters(virtual_connect_calibre) != "")} {
      lappend file_contents "set virtualConnect $parameters(virtual_connect_calibre)"
    }
    write_file pvbatch_config_perccnod_calibre [join $file_contents \n]
    
    set file_contents [list]
    lappend file_contents "#!/bin/tcsh"
    lappend file_contents "module unload msip_cd_pv"
    lappend file_contents "module load msip_cd_pv/$parameters(msip_cd_pv_version)"
    lappend file_contents "pvbatch --projectType $parameters(project_type) --projectName $parameters(project_name) --releaseName $parameters(release_name) --metalStack $parameters(metal_stack) --type perc --prefix $parameters(perccnod_prefix) --streamPath [pwd]/${testcase}$parameters(layout_file_extension_zipped) --cellName $testcase --layoutFormat $parameters(output_layout_format) --tool calibre --config [pwd]/pvbatch_config_perccnod_calibre --udeArgs \"--log [pwd]/pvbatch_perccnod_calibre.log --sourceShellFile [pwd]/ude_sourceme\" --tmpLibPath"
    # 2022.07 - Updated output file structure to match CKT P4 release structure.
    lappend file_contents "mkdir -p ../../crd_results/${testcase}/calibre/perc_cnod"
    lappend file_contents "find -ipath \"*${parameters(perccnod_prefix)}_calibre/cell.results\" -exec ln -s \"[pwd]/{}\" ../../crd_results/${testcase}/calibre/perc_cnod/perc_cnod_${testcase}_${parameters(metal_stack)}.cell.results \\;"
    lappend file_contents "ln -s $LOGFILE ../../crd_results/${testcase}/calibre/perc_cnod/perc_cnod_${testcase}_${parameters(metal_stack)}.log"
    write_file pv_perccnod_calibre.tcsh [join $file_contents \n]
    file attributes pv_perccnod_calibre.tcsh -permissions +x
    lappend pv_launch_scripts "qsub -P bnormal -cwd -V -m a -b y ./pv_perccnod_calibre.tcsh"
    # Delay no longer required with lib.defs access fix: https://jira.internal.synopsys.com/browse/P10020416-27925
    #after 120000
  }
  
  if {[info exists parameters(percldl_icv)] && $parameters(percldl_icv)} {
    iprint "Running PERCLDL_ICV on ${testcase}."
    set file_contents [list]
    lappend file_contents "set useGrid $parameters(grid)"
    lappend file_contents "set gridProc $parameters(percldl_icv_grid_processes)"
    
    # 2022.03-2 - Removed FOUNDRY_DEFAULT from virtual_connect parameter in parameters file template, so need to check for missing parameter or empty string.
    if {[info exists parameters(virtual_connect_icv)] && ($parameters(virtual_connect_icv) != "")} {
      lappend file_contents "set virtualConnect $parameters(virtual_connect_icv)"
    }
    write_file pvbatch_config_percldl_icv [join $file_contents \n]
    
    set file_contents [list]
    lappend file_contents "#!/bin/tcsh"
    lappend file_contents "module unload msip_cd_pv"
    lappend file_contents "module load msip_cd_pv/$parameters(msip_cd_pv_version)"
    lappend file_contents "pvbatch --projectType $parameters(project_type) --projectName $parameters(project_name) --releaseName $parameters(release_name) --metalStack $parameters(metal_stack) --type perc --prefix $parameters(percldl_prefix) --streamPath [pwd]/${testcase}$parameters(layout_file_extension_zipped) --cellName $testcase --layoutFormat $parameters(output_layout_format) --tool icv --config [pwd]/pvbatch_config_percldl_icv --udeArgs \"--log [pwd]/pvbatch_percldl_icv.log --sourceShellFile [pwd]/ude_sourceme\" --tmpLibPath"
    # 2022.07 - Updated output file structure to match CKT P4 release structure.
    lappend file_contents "mkdir -p ../../crd_results/${testcase}/icv/perc_esd"
    lappend file_contents "find -ipath \"*${parameters(percldl_prefix)}_icv/${testcase}.LAYOUT_ERRORS\" -exec ln -s \"[pwd]/{}\" ../../crd_results/${testcase}/icv/perc_esd/perc_ldl_${testcase}_${parameters(metal_stack)}.rpt \\;"
    lappend file_contents "find -ipath \"*${parameters(percldl_prefix)}_icv/perc_reports/ldl_results.txt\" -exec ln -s \"[pwd]/{}\" ../../crd_results/${testcase}/icv/perc_esd/perc_ldl_${testcase}_${parameters(metal_stack)}.results \\;"
    lappend file_contents "find -ipath \"*${parameters(percldl_prefix)}_icv/perc_reports/ldl_results.html\" -exec ln -s \"[pwd]/{}\" ../../crd_results/${testcase}/icv/perc_esd/perc_ldl_${testcase}_${parameters(metal_stack)}.results.html \\;"
    lappend file_contents "ln -s $LOGFILE ../../crd_results/${testcase}/icv/perc_esd/perc_ldl_${testcase}_${parameters(metal_stack)}.log"
    lappend file_contents "find -ipath \"*${parameters(percldl_prefix)}_icv/merged.TSMC.ESD.MARK$parameters(layout_file_extension)\" -exec ln -s {} percldl_icv.merged.TSMC.ESD.MARK$parameters(layout_file_extension) \\;"
        
    if {[info exists parameters(perccd_icv)] && $parameters(perccd_icv)} {
      iprint "Running PERCCD_ICV on ${testcase}."
      lappend file_contents "qsub -P bnormal -cwd -V -m a -b y ./pv_perccd_icv.tcsh"
      set file2_contents [list]
      lappend file2_contents "set useGrid $parameters(grid)"
      lappend file2_contents "set gridUserDefResEn 1"
      lappend file2_contents "set gridUserDefRes \"--hosts $parameters(perccd_icv_grid_hosts) --cores-per-host $parameters(perccd_icv_grid_cores_per_host) --grid-options \\\"-P bnormal -l mem_free=100G,h_vmem=$parameters(perccd_icv_grid_h_vmem),scratch_free=10G\\\"\""
      
      # 2022.03-2 - Removed FOUNDRY_DEFAULT from virtual_connect parameter in parameters file template, so need to check for missing parameter or empty string.
      if {[info exists parameters(virtual_connect_icv)] && ($parameters(virtual_connect_icv) != "")} {
        lappend file2_contents "set virtualConnect $parameters(virtual_connect_icv)"
      }
      write_file pvbatch_config_perccd_icv [join $file2_contents \n]
       
      set file2_contents [list]
      lappend file2_contents "#!/bin/tcsh"
      lappend file2_contents "module unload msip_cd_pv"
      lappend file2_contents "module load msip_cd_pv/$parameters(msip_cd_pv_version)"
      lappend file2_contents "pvbatch --projectType $parameters(project_type) --projectName $parameters(project_name) --releaseName $parameters(release_name) --metalStack $parameters(metal_stack) --type perc --prefix $parameters(perccd_prefix) --streamPath [pwd]/percldl_icv.merged.TSMC.ESD.MARK$parameters(layout_file_extension) --cellName $testcase --layoutFormat $parameters(output_layout_format) --tool icv --config [pwd]/pvbatch_config_perccd_icv --udeArgs \"--log [pwd]/pvbatch_perccd_icv.log --sourceShellFile [pwd]/ude_sourceme\" --tmpLibPath"
      # 2022.07 - Updated output file structure to match CKT P4 release structure.
      #lappend file2_contents "find -path \"*perccd_icv/${testcase}.LAYOUT_ERRORS\" -exec ln -s \"[pwd]/{}\" ../results/${testcase}/icv/perc_esd/perc_cd_${testcase}_${parameters(metal_stack)}.rpt \\;"
      # 2022.09 - Fixed ICV PERC CD report names.
      lappend file2_contents "find -ipath \"*${parameters(perccd_prefix)}_icv/perc_reports/cd_results.Worst_per_net.txt\" -exec ln -s \"[pwd]/{}\" ../../crd_results/${testcase}/icv/perc_esd/perc_cd_${testcase}_${parameters(metal_stack)}.results \\;"
      lappend file2_contents "find -ipath \"*${parameters(perccd_prefix)}_icv/perc_reports/cd_results.Worst_per_net.html\" -exec ln -s \"[pwd]/{}\" ../../crd_results/${testcase}/icv/perc_esd/perc_cd_${testcase}_${parameters(metal_stack)}.results.html \\;"
      lappend file2_contents "ln -s $LOGFILE ../../crd_results/${testcase}/icv/perc_esd/perc_cd_${testcase}_${parameters(metal_stack)}.log"
      write_file pv_perccd_icv.tcsh [join $file2_contents \n]
      file attributes pv_perccd_icv.tcsh -permissions +x
    }
    
    if {[info exists parameters(percp2p_icv)] && $parameters(percp2p_icv)} {
      iprint "Running PERCP2P_ICV on ${testcase}."
      lappend file_contents "qsub -P bnormal -cwd -V -m a -b y ./pv_percp2p_icv.tcsh"
      set file2_contents [list]
      lappend file2_contents "set useGrid $parameters(grid)"
      lappend file2_contents "set gridUserDefResEn 1"
      lappend file2_contents "set gridUserDefRes \"--hosts $parameters(percp2p_icv_grid_hosts) --cores-per-host $parameters(percp2p_icv_grid_cores_per_host) --grid-options \\\"-P bnormal -l mem_free=100G,h_vmem=$parameters(percp2p_icv_grid_h_vmem),scratch_free=10G\\\"\""
      
      # 2022.03-2 - Removed FOUNDRY_DEFAULT from virtual_connect parameter in parameters file template, so need to check for missing parameter or empty string.
      if {[info exists parameters(virtual_connect_icv)] && ($parameters(virtual_connect_icv) != "")} {
        lappend file2_contents "set virtualConnect $parameters(virtual_connect_icv)"
      }
      write_file pvbatch_config_percp2p_icv [join $file2_contents \n]
      
      set file2_contents [list]
      lappend file2_contents "#!/bin/tcsh"
      lappend file2_contents "module unload msip_cd_pv"
      lappend file2_contents "module load msip_cd_pv/$parameters(msip_cd_pv_version)"
      lappend file2_contents "pvbatch --projectType $parameters(project_type) --projectName $parameters(project_name) --releaseName $parameters(release_name) --metalStack $parameters(metal_stack) --type perc --prefix $parameters(percp2p_prefix) --streamPath [pwd]/percldl_icv.merged.TSMC.ESD.MARK$parameters(layout_file_extension) --cellName $testcase --layoutFormat $parameters(output_layout_format) --tool icv --config [pwd]/pvbatch_config_percp2p_icv --udeArgs \"--log [pwd]/pvbatch_percp2p_icv.log --sourceShellFile [pwd]/ude_sourceme\" --tmpLibPath"
      # 2022.07 - Updated output file structure to match CKT P4 release structure.
      #lappend file2_contents "find -path \"*percp2p_icv/${testcase}.LAYOUT_ERRORS\" -exec ln -s \"[pwd]/{}\" ../results/${testcase}/icv/perc_esd/perc_p2p_${testcase}_${parameters(metal_stack)}.rpt \\;"
      lappend file2_contents "find -ipath \"*${parameters(percp2p_prefix)}_icv/perc_reports/p2p_results.txt\" -exec ln -s \"[pwd]/{}\" ../../crd_results/${testcase}/icv/perc_esd/perc_p2p_${testcase}_${parameters(metal_stack)}.results \\;"
      lappend file2_contents "find -ipath \"*${parameters(percp2p_prefix)}_icv/perc_reports/p2p_results.html\" -exec ln -s \"[pwd]/{}\" ../../crd_results/${testcase}/icv/perc_esd/perc_p2p_${testcase}_${parameters(metal_stack)}.results.html \\;"
      lappend file2_contents "ln -s $LOGFILE ../../crd_results/${testcase}/icv/perc_esd/perc_p2p_${testcase}_${parameters(metal_stack)}.log"
      write_file pv_percp2p_icv.tcsh [join $file2_contents \n]
      file attributes pv_percp2p_icv.tcsh -permissions +x
    }
    
    write_file pv_percldl_icv.tcsh [join $file_contents \n]
    file attributes pv_percldl_icv.tcsh -permissions +x
    lappend pv_launch_scripts "qsub -P bnormal -cwd -V -m a -b y ./pv_percldl_icv.tcsh"
    # Delay no longer required with lib.defs access fix: https://jira.internal.synopsys.com/browse/P10020416-27925
    #after 120000
  } else {
    if {[info exists parameters(perccd_icv)] && $parameters(perccd_icv)} {
      eprint "Attempting to run PERCCD_ICV without running PERCLDL_ICV. Skipping PERCCD_ICV."
    }
    if {[info exists parameters(percp2p_icv)] && $parameters(percp2p_icv)} {
      eprint "Attempting to run PERCP2P_ICV without running PERCLDL_ICV. Skipping PERCP2P_ICV."
    }
  }
  
  if {[info exists parameters(percldl_calibre)] && $parameters(percldl_calibre)} {
    iprint "Running PERCLDL_CALIBRE on ${testcase}."
    set file_contents [list]
    lappend file_contents "set calexExtraArg \"$parameters(percldl_calex_extra_arguments)\""
    
    # 2022.03-2 - Removed FOUNDRY_DEFAULT from virtual_connect parameter in parameters file template, so need to check for missing parameter or empty string.
    if {[info exists parameters(virtual_connect_calibre)] && ($parameters(virtual_connect_calibre) != "")} {
      lappend file_contents "set virtualConnect $parameters(virtual_connect_calibre)"
    }
    write_file pvbatch_config_percldl_calibre [join $file_contents \n]
    
    set file_contents [list]
    lappend file_contents "#!/bin/tcsh"
    lappend file_contents "module unload msip_cd_pv"
    lappend file_contents "module load msip_cd_pv/$parameters(msip_cd_pv_version)"
    lappend file_contents "pvbatch --projectType $parameters(project_type) --projectName $parameters(project_name) --releaseName $parameters(release_name) --metalStack $parameters(metal_stack) --type perc --prefix $parameters(percldl_prefix) --streamPath [pwd]/${testcase}$parameters(layout_file_extension_zipped) --cellName $testcase --layoutFormat $parameters(output_layout_format) --tool calibre --config [pwd]/pvbatch_config_percldl_calibre --udeArgs \"--log [pwd]/pvbatch_percldl_calibre.log --sourceShellFile [pwd]/ude_sourceme\" --tmpLibPath"
    # 2022.07 - Updated output file structure to match CKT P4 release structure.
    lappend file_contents "mkdir -p ../../crd_results/${testcase}/calibre/perc_esd"
    lappend file_contents "find -ipath \"*${parameters(percldl_prefix)}_calibre/cell.results\" -exec ln -s \"[pwd]/{}\" ../../crd_results/${testcase}/calibre/perc_esd/perc_ldl_${testcase}_${parameters(metal_stack)}.cell.results \\;"
    lappend file_contents "find -ipath \"*${parameters(percldl_prefix)}_calibre/perc.rep.ldl\" -exec ln -s \"[pwd]/{}\" ../../crd_results/${testcase}/calibre/perc_esd/perc_ldl_${testcase}_${parameters(metal_stack)}.perc.rep.ldl \\;"
    lappend file_contents "ln -s $LOGFILE ../../crd_results/${testcase}/calibre/perc_esd/perc_ldl_${testcase}_${parameters(metal_stack)}.log"
    lappend file_contents "find -ipath \"*${parameters(percldl_prefix)}_calibre/TSMC.ESD.MARK.gds\" -exec ln -s {} percldl_calibre.TSMC.ESD.MARK.gds \\;"
    
    if {[info exists parameters(perccd_calibre)] && $parameters(perccd_calibre)} {
      iprint "Running PERCCD_CALIBRE on ${testcase}."
      lappend file_contents "qsub -P bnormal -cwd -V -m a -b y ./pv_perccd_calibre.tcsh"
      set file2_contents [list]
      lappend file2_contents "set calexExtraArg \"$parameters(perccd_calex_extra_arguments)\""
      
      # 2022.03-2 - Removed FOUNDRY_DEFAULT from virtual_connect parameter in parameters file template, so need to check for missing parameter or empty string.
      if {[info exists parameters(virtual_connect_calibre)] && ($parameters(virtual_connect_calibre) != "")} {
        lappend file2_contents "set virtualConnect $parameters(virtual_connect_calibre)"
      }
      
      lappend file2_contents "set enStreamComp 1"
      lappend file2_contents "set inputStreamComp [pwd]/percldl_calibre.TSMC.ESD.MARK.gds"
      write_file pvbatch_config_perccd_calibre [join $file2_contents \n]
      
      set file2_contents [list]
      lappend file2_contents "#!/bin/tcsh"
      lappend file2_contents "module unload msip_cd_pv"
      lappend file2_contents "module load msip_cd_pv/$parameters(msip_cd_pv_version)"
      lappend file2_contents "pvbatch --projectType $parameters(project_type) --projectName $parameters(project_name) --releaseName $parameters(release_name) --metalStack $parameters(metal_stack) --type perc --prefix $parameters(perccd_prefix) --streamPath [pwd]/${testcase}$parameters(layout_file_extension_zipped) --cellName $testcase --layoutFormat $parameters(output_layout_format) --tool calibre --config [pwd]/pvbatch_config_perccd_calibre --udeArgs \"--log [pwd]/pvbatch_perccd_calibre.log --sourceShellFile [pwd]/ude_sourceme\" --tmpLibPath"
      # 2022.07 - Updated output file structure to match CKT P4 release structure.
      lappend file2_contents "find -ipath \"*${parameters(perccd_prefix)}_calibre/cell.results\" -exec ln -s \"[pwd]/{}\" ../../crd_results/${testcase}/calibre/perc_esd/perc_cd_${testcase}_${parameters(metal_stack)}.cell.results \\;"
      lappend file2_contents "find -ipath \"*${parameters(perccd_prefix)}_calibre/cell.results.cd\" -exec ln -s \"[pwd]/{}\" ../../crd_results/${testcase}/calibre/perc_esd/perc_cd_${testcase}_${parameters(metal_stack)}.cell.results.cd \\;"
      lappend file2_contents "ln -s $LOGFILE ../../crd_results/${testcase}/calibre/perc_esd/perc_cd_${testcase}_${parameters(metal_stack)}.log"
      write_file pv_perccd_calibre.tcsh [join $file2_contents \n]
      file attributes pv_perccd_calibre.tcsh -permissions +x
    }
    
    if {[info exists parameters(percp2p_calibre)] && $parameters(percp2p_calibre)} {
      iprint "Running PERCP2P_CALIBRE on ${testcase}."
      lappend file_contents "qsub -P bnormal -cwd -V -m a -b y ./pv_percp2p_calibre.tcsh"
      set file2_contents [list]
      lappend file2_contents "set calexExtraArg \"$parameters(percp2p_calex_extra_arguments)\""
      
      # 2022.03-2 - Removed FOUNDRY_DEFAULT from virtual_connect parameter in parameters file template, so need to check for missing parameter or empty string.
      if {[info exists parameters(virtual_connect_calibre)] && ($parameters(virtual_connect_calibre) != "")} {
        lappend file2_contents "set virtualConnect $parameters(virtual_connect_calibre)"
      }
      
      lappend file2_contents "set enStreamComp 1"
      lappend file2_contents "set inputStreamComp [pwd]/percldl_calibre.TSMC.ESD.MARK.gds"
      write_file pvbatch_config_percp2p_calibre [join $file2_contents \n]
      
      set file2_contents [list]
      lappend file2_contents "#!/bin/tcsh"
      lappend file2_contents "module unload msip_cd_pv"
      lappend file2_contents "module load msip_cd_pv/$parameters(msip_cd_pv_version)"
      lappend file2_contents "pvbatch --projectType $parameters(project_type) --projectName $parameters(project_name) --releaseName $parameters(release_name) --metalStack $parameters(metal_stack) --type perc --prefix $parameters(percp2p_prefix) --streamPath [pwd]/${testcase}$parameters(layout_file_extension_zipped) --cellName $testcase --layoutFormat $parameters(output_layout_format) --tool calibre --config [pwd]/pvbatch_config_percp2p_calibre --udeArgs \"--log [pwd]/pvbatch_percp2p_calibre.log --sourceShellFile [pwd]/ude_sourceme\" --tmpLibPath"
      # 2022.07 - Updated output file structure to match CKT P4 release structure.
      lappend file2_contents "find -ipath \"*${parameters(percp2p_prefix)}_calibre/cell.results\" -exec ln -s \"[pwd]/{}\" ../../crd_results/${testcase}/calibre/perc_esd/perc_p2p_${testcase}_${parameters(metal_stack)}.cell.results \\;"
      lappend file2_contents "find -ipath \"*${parameters(percp2p_prefix)}_calibre/cell.results.p2p\" -exec ln -s \"[pwd]/{}\" ../../crd_results/${testcase}/calibre/perc_esd/perc_p2p_${testcase}_${parameters(metal_stack)}.cell.results.p2p \\;"
      lappend file2_contents "find -ipath \"*${parameters(percp2p_prefix)}_calibre/perc.rep.p2p.sum\" -exec ln -s \"[pwd]/{}\" ../../crd_results/${testcase}/calibre/perc_esd/perc_p2p_${testcase}_${parameters(metal_stack)}.perc.rep.p2p.sum \\;"
      lappend file2_contents "ln -s $LOGFILE ../../crd_results/${testcase}/calibre/perc_esd/perc_p2p_${testcase}_${parameters(metal_stack)}.log"
      write_file pv_percp2p_calibre.tcsh [join $file2_contents \n]
      file attributes pv_percp2p_calibre.tcsh -permissions +x
    }
    
    write_file pv_percldl_calibre.tcsh [join $file_contents \n]
    file attributes pv_percldl_calibre.tcsh -permissions +x
    lappend pv_launch_scripts "qsub -P bnormal -cwd -V -m a -b y ./pv_percldl_calibre.tcsh"
    # Delay no longer required with lib.defs access fix: https://jira.internal.synopsys.com/browse/P10020416-27925
    #after 120000
  } else {
    if {[info exists parameters(perccd_calibre)] && $parameters(perccd_calibre)} {
      eprint "Attempting to run PERCCD_CALIBRE without running PERCLDL_CALIBRE. Skipping PERCCD_CALIBRE."
    }
    if {[info exists parameters(percp2p_calibre)] && $parameters(percp2p_calibre)} {
      eprint "Attempting to run PERCP2P_CALIBRE without running PERCLDL_CALIBRE. Skipping PERCP2P_CALIBRE."
    }
  }
  
  if {[info exists parameters(perctopo_icv)] && $parameters(perctopo_icv)} {
    iprint "Running PERCTOPO_ICV on ${testcase}."
    set file_contents [list]
    lappend file_contents "set useGrid $parameters(grid)"
    lappend file_contents "set gridProc $parameters(perctopo_icv_grid_processes)"
    
    # 2022.03-2 - Removed FOUNDRY_DEFAULT from virtual_connect parameter in parameters file template, so need to check for missing parameter or empty string.
    if {[info exists parameters(virtual_connect_icv)] && ($parameters(virtual_connect_icv) != "")} {
      lappend file_contents "set virtualConnect $parameters(virtual_connect_icv)"
    }
    write_file pvbatch_config_perctopo_icv [join $file_contents \n]
    
    set file_contents [list]
    lappend file_contents "#!/bin/tcsh"
    lappend file_contents "module unload msip_cd_pv"
    lappend file_contents "module load msip_cd_pv/$parameters(msip_cd_pv_version)"
    lappend file_contents "pvbatch --projectType $parameters(project_type) --projectName $parameters(project_name) --releaseName $parameters(release_name) --metalStack $parameters(metal_stack) --type perc --prefix $parameters(perctopo_prefix) --streamPath [pwd]/${testcase}$parameters(layout_file_extension_zipped) --cdlPath [pwd]/${testcase}.cdl --cellName $testcase --layoutFormat $parameters(output_layout_format) --tool icv --config [pwd]/pvbatch_config_perctopo_icv --udeArgs \"--log [pwd]/pvbatch_perctopo_icv.log --sourceShellFile [pwd]/ude_sourceme\" --tmpLibPath"
    # 2022.07 - Updated output file structure to match CKT P4 release structure.
    lappend file_contents "mkdir -p ../../crd_results/${testcase}/icv/perc_esd"
    lappend file_contents "find -ipath \"*${parameters(perctopo_prefix)}_icv/${testcase}.LAYOUT_ERRORS\" -exec ln -s \"[pwd]/{}\" ../../crd_results/${testcase}/icv/perc_esd/perc_topo_${testcase}_${parameters(metal_stack)}.rpt \\;"
    lappend file_contents "find -ipath \"*${parameters(perctopo_prefix)}_icv/perc_reports/topo_results.txt\" -exec ln -s \"[pwd]/{}\" ../../crd_results/${testcase}/icv/perc_esd/perc_topo_${testcase}_${parameters(metal_stack)}.results \\;"
    lappend file_contents "find -ipath \"*${parameters(perctopo_prefix)}_icv/perc_reports/topo_results.html\" -exec ln -s \"[pwd]/{}\" ../../crd_results/${testcase}/icv/perc_esd/perc_topo_${testcase}_${parameters(metal_stack)}.results.html \\;"
    lappend file_contents "find -ipath \"*${parameters(perctopo_prefix)}_icv/perc_reports/esd_network_report.txt\" -exec ln -s \"[pwd]/{}\" ../../crd_results/${testcase}/icv/perc_esd/perc_topo_${testcase}_${parameters(metal_stack)}.esd_network.results \\;"
    lappend file_contents "find -ipath \"*${parameters(perctopo_prefix)}_icv/perc_reports/esd_network_report.html\" -exec ln -s \"[pwd]/{}\" ../../crd_results/${testcase}/icv/perc_esd/perc_topo_${testcase}_${parameters(metal_stack)}.esd_network.results.html \\;"
    lappend file_contents "ln -s $LOGFILE ../../crd_results/${testcase}/icv/perc_esd/perc_topo_${testcase}_${parameters(metal_stack)}.log"
    write_file pv_perctopo_icv.tcsh [join $file_contents \n]
    file attributes pv_perctopo_icv.tcsh -permissions +x
    lappend pv_launch_scripts "qsub -P bnormal -cwd -V -m a -b y ./pv_perctopo_icv.tcsh"
    # Delay no longer required with lib.defs access fix: https://jira.internal.synopsys.com/browse/P10020416-27925
    #after 120000
  }
  
  if {[info exists parameters(perctopo_calibre)] && $parameters(perctopo_calibre)} {
    iprint "Running PERCTOPO_CALIBRE on ${testcase}."
    set file_contents [list]
    lappend file_contents "set calexExtraArg \"$parameters(perctopo_calex_extra_arguments)\""
    
    # 2022.03-2 - Removed FOUNDRY_DEFAULT from virtual_connect parameter in parameters file template, so need to check for missing parameter or empty string.
    if {[info exists parameters(virtual_connect_calibre)] && ($parameters(virtual_connect_calibre) != "")} {
      lappend file_contents "set virtualConnect $parameters(virtual_connect_calibre)"
    }
    write_file pvbatch_config_perctopo_calibre [join $file_contents \n]
    
    set file_contents [list]
    lappend file_contents "#!/bin/tcsh"
    lappend file_contents "module unload msip_cd_pv"
    lappend file_contents "module load msip_cd_pv/$parameters(msip_cd_pv_version)"
    lappend file_contents "pvbatch --projectType $parameters(project_type) --projectName $parameters(project_name) --releaseName $parameters(release_name) --metalStack $parameters(metal_stack) --type perc --prefix $parameters(perctopo_prefix) --streamPath [pwd]/${testcase}$parameters(layout_file_extension_zipped) --cdlPath [pwd]/${testcase}.cdl --cellName $testcase --layoutFormat $parameters(output_layout_format) --tool calibre --config [pwd]/pvbatch_config_perctopo_calibre --udeArgs \"--log [pwd]/pvbatch_perctopo_calibre.log --sourceShellFile [pwd]/ude_sourceme\" --tmpLibPath"
    # 2022.07 - Updated output file structure to match CKT P4 release structure.
    lappend file_contents "mkdir -p ../../crd_results/${testcase}/calibre/perc_esd"
    lappend file_contents "find -ipath \"*${parameters(perctopo_prefix)}_calibre/perc.sum\" -exec ln -s \"[pwd]/{}\" ../../crd_results/${testcase}/calibre/perc_esd/perc_topo_${testcase}_${parameters(metal_stack)}.perc.sum \\;"
    lappend file_contents "find -ipath \"*${parameters(perctopo_prefix)}_calibre/cell.results\" -exec ln -s \"[pwd]/{}\" ../../crd_results/${testcase}/calibre/perc_esd/perc_topo_${testcase}_${parameters(metal_stack)}.cell.results \\;"
    lappend file_contents "ln -s $LOGFILE ../../crd_results/${testcase}/calibre/perc_esd/perc_topo_${testcase}_${parameters(metal_stack)}.log"
    write_file pv_perctopo_calibre.tcsh [join $file_contents \n]
    file attributes pv_perctopo_calibre.tcsh -permissions +x
    lappend pv_launch_scripts "qsub -P bnormal -cwd -V -m a -b y ./pv_perctopo_calibre.tcsh"
    # Delay no longer required with lib.defs access fix: https://jira.internal.synopsys.com/browse/P10020416-27925
    #after 120000
  }
  
  if {[info exists parameters(perctopola_icv)] && $parameters(perctopola_icv)} {
    iprint "Running PERCTOPOLA_ICV on ${testcase}."
    set file_contents [list]
    lappend file_contents "set useGrid $parameters(grid)"
    lappend file_contents "set gridProc $parameters(perctopola_icv_grid_processes)"
    
    # 2022.03-2 - Removed FOUNDRY_DEFAULT from virtual_connect parameter in parameters file template, so need to check for missing parameter or empty string.
    if {[info exists parameters(virtual_connect_icv)] && ($parameters(virtual_connect_icv) != "")} {
      lappend file_contents "set virtualConnect $parameters(virtual_connect_icv)"
    }
    write_file pvbatch_config_perctopola_icv [join $file_contents \n]
    
    set file_contents [list]
    lappend file_contents "#!/bin/tcsh"
    lappend file_contents "module unload msip_cd_pv"
    lappend file_contents "module load msip_cd_pv/$parameters(msip_cd_pv_version)"
    lappend file_contents "pvbatch --projectType $parameters(project_type) --projectName $parameters(project_name) --releaseName $parameters(release_name) --metalStack $parameters(metal_stack) --type perc --prefix $parameters(perctopola_prefix) --streamPath [pwd]/${testcase}$parameters(layout_file_extension_zipped) --cellName $testcase --layoutFormat $parameters(output_layout_format) --tool icv --config [pwd]/pvbatch_config_perctopola_icv --udeArgs \"--log [pwd]/pvbatch_perctopola_icv.log --sourceShellFile [pwd]/ude_sourceme\" --tmpLibPath"
    # 2022.07 - Updated output file structure to match CKT P4 release structure.
    lappend file_contents "mkdir -p ../../crd_results/${testcase}/icv/perc_esd"
    lappend file_contents "find -ipath \"*${parameters(perctopola_prefix)}_icv/${testcase}.LAYOUT_ERRORS\" -exec ln -s \"[pwd]/{}\" ../../crd_results/${testcase}/icv/perc_esd/perc_topola_${testcase}_${parameters(metal_stack)}.rpt \\;"
    lappend file_contents "find -ipath \"*${parameters(perctopola_prefix)}_icv/perc_reports/topo_results.txt\" -exec ln -s \"[pwd]/{}\" ../../crd_results/${testcase}/icv/perc_esd/perc_topola_${testcase}_${parameters(metal_stack)}.results \\;"
    lappend file_contents "find -ipath \"*${parameters(perctopola_prefix)}_icv/perc_reports/topo_results.html\" -exec ln -s \"[pwd]/{}\" ../../crd_results/${testcase}/icv/perc_esd/perc_topola_${testcase}_${parameters(metal_stack)}.results.html \\;"
    lappend file_contents "find -ipath \"*${parameters(perctopola_prefix)}_icv/perc_reports/esd_network_report.txt\" -exec ln -s \"[pwd]/{}\" ../../crd_results/${testcase}/icv/perc_esd/perc_topola_${testcase}_${parameters(metal_stack)}.esd_network.results \\;"
    lappend file_contents "find -ipath \"*${parameters(perctopola_prefix)}_icv/perc_reports/esd_network_report.html\" -exec ln -s \"[pwd]/{}\" ../../crd_results/${testcase}/icv/perc_esd/perc_topola_${testcase}_${parameters(metal_stack)}.esd_network.results.html \\;"
    lappend file_contents "ln -s $LOGFILE ../../crd_results/${testcase}/icv/perc_esd/perc_topola_${testcase}_${parameters(metal_stack)}.log"
    write_file pv_perctopola_icv.tcsh [join $file_contents \n]
    file attributes pv_perctopola_icv.tcsh -permissions +x
    lappend pv_launch_scripts "qsub -P bnormal -cwd -V -m a -b y ./pv_perctopola_icv.tcsh"
    # Delay no longer required with lib.defs access fix: https://jira.internal.synopsys.com/browse/P10020416-27925
    #after 120000
  }
  
  if {[info exists parameters(perctopola_calibre)] && $parameters(perctopola_calibre)} {
    iprint "Running PERCTOPOLA_CALIBRE on ${testcase}."
    set file_contents [list]
    lappend file_contents "set calexExtraArg \"$parameters(perctopola_calex_extra_arguments)\""
    
    # 2022.03-2 - Removed FOUNDRY_DEFAULT from virtual_connect parameter in parameters file template, so need to check for missing parameter or empty string.
    if {[info exists parameters(virtual_connect_calibre)] && ($parameters(virtual_connect_calibre) != "")} {
      lappend file_contents "set virtualConnect $parameters(virtual_connect_calibre)"
    }
    write_file pvbatch_config_perctopola_calibre [join $file_contents \n]
    
    set file_contents [list]
    lappend file_contents "#!/bin/tcsh"
    lappend file_contents "module unload msip_cd_pv"
    lappend file_contents "module load msip_cd_pv/$parameters(msip_cd_pv_version)"
    lappend file_contents "pvbatch --projectType $parameters(project_type) --projectName $parameters(project_name) --releaseName $parameters(release_name) --metalStack $parameters(metal_stack) --type perc --prefix $parameters(perctopola_prefix) --streamPath [pwd]/${testcase}$parameters(layout_file_extension_zipped) --cellName $testcase --layoutFormat $parameters(output_layout_format) --tool calibre --config [pwd]/pvbatch_config_perctopola_calibre --udeArgs \"--log [pwd]/pvbatch_perctopola_calibre.log --sourceShellFile [pwd]/ude_sourceme\" --tmpLibPath"
    # 2022.07 - Updated output file structure to match CKT P4 release structure.
    lappend file_contents "mkdir -p ../../crd_results/${testcase}/calibre/perc_esd"
    lappend file_contents "find -ipath \"*${parameters(perctopola_prefix)}_calibre/perc.sum\" -exec ln -s \"[pwd]/{}\" ../../crd_results/${testcase}/calibre/perc_esd/perc_topola_${testcase}_${parameters(metal_stack)}.perc.sum \\;"
    lappend file_contents "find -ipath \"*${parameters(perctopola_prefix)}_calibre/cell.results\" -exec ln -s \"[pwd]/{}\" ../../crd_results/${testcase}/calibre/perc_esd/perc_topola_${testcase}_${parameters(metal_stack)}.cell.results \\;"
    lappend file_contents "ln -s $LOGFILE ../../crd_results/${testcase}/calibre/perc_esd/perc_topola_${testcase}_${parameters(metal_stack)}.log"
    write_file pv_perctopola_calibre.tcsh [join $file_contents \n]
    file attributes pv_perctopola_calibre.tcsh -permissions +x
    lappend pv_launch_scripts "qsub -P bnormal -cwd -V -m a -b y ./pv_perctopola_calibre.tcsh"
    # Delay no longer required with lib.defs access fix: https://jira.internal.synopsys.com/browse/P10020416-27925
    #after 120000
  }
  print_function_footer
  return [join $pv_launch_scripts \n]
}
# end Run_PV

#-----------------------------------------------------------------
# Main procedure -->  put __ALL__ your code in this proc
#-----------------------------------------------------------------
proc Main {} {
  global RealBin
  global RealScript
  global paramsCSVfile
  global ScriptVersion
  
  process_cmdline
  get_clean_dir
    
  # Names of hard macros for regex matching.
  set hard_macros "^dwc_ddrphyacx4_top_ew\$|^dwc_ddrphyacx4_top_ns\$|^dwc_ddrphydbyte_top_ew\$|^dwc_ddrphydbyte_top_ns\$|^dwc_ddrphymaster_top\$|^dwc_lpddr5xmphyacx2_top_ew\$|^dwc_lpddr5xmphyckx2_top_ew\$|^dwc_lpddr5xmphycmosx2_top_ew\$|^dwc_lpddr5xmphydx4_top_ew\$|^dwc_lpddr5xmphydx5_top_ew\$|^dwc_lpddr5xmphymaster_top_ew\$|^dwc_lpddr5xmphyzcal_top_ew\$"

  # Names of power supplies for regex matching.
  set power_supplies "^(VAA|VDD|VDDQ|VDDQ_VDD2H|VDDQLP|VSH|VSS)\$"

  # 2022.03-1 - Add script version to script log file.
  hprint "CRD Abutment Verification Script version: $ScriptVersion"
  
  # Read in parameters.
  # 2022.07 - Parameters file must be in working directory.
  set original_parameters_file [read_file $paramsCSVfile]
  
  # 2022.03-3 - Add parameters file contents to script log file.
  nprint ""
  hprint  "Parameters file contents:"
  nprint $original_parameters_file
  hprint "End of parameters file contents."

  #Process parameters.
  set parameter_names_values [split $original_parameters_file \n]
  foreach parameter_name_value $parameter_names_values {
    set parameter_name_value [split $parameter_name_value ,]
    set name [lindex $parameter_name_value 0]
    # 2022.11 - Clean $value to remove leading/trailing whitespace and additional spaces between words to avoid generating empty elements when using the split command.
    set value [string trim [lindex $parameter_name_value 1]]
    regsub -all -- {\s\s+} $value " " value
    set parameters($name) $value
  }

  # 2022.04-1 - Setting version of ICC2, ICVWB and msip_cd_pv tools to support result reproducibility.
  # 2022.04-3 - Updated msip_cd_pv version to 2022.03.
  # 2022.07 - Updated ICC2 to 2022.03-SP2, ICVWB to 2022.03-SP1 and msip_cd_pv to 2022.05.
  # 2022.08 - Updated ICC2 to 2022.03-SP3.
  # 2022.10 - Updated ICC2 to 2022.03-SP4, ICVWB to 2022.03-SP2 and msip_cd_pv to 2022.07.
  # 2022.11 - Updated tool versions: msip_cd_pv to 2022.09-2. Added icc_shell executable path.
  # 2022.12-1 - Updated tool versions: ICC - 2022.12, ICC2 - 2022.12, ICV - 2022.12, ICVWB - 2022.12, msip_cd_pv - 2022.11.
  # 2023.01 - Updated tool versions: msip_cd_pv - 2022.12.
  set parameters(icc2_version) 2022.12-SP1
  # ICV used for icv_nettran.
  set parameters(icv_version) 2022.12-SP1-1
  set parameters(icvwb_version) 2022.12
  if {$parameters(msip_cd_pv_version) == ""} {
    set parameters(msip_cd_pv_version) 2022.12-2
  }
  set parameters(icc_shell_exec) /global/apps/icc_2022.12-SP1/bin/icc_shell

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
      nprint ""
      fatal_error "Illegal output_layout_format parameter value. Exiting."
    }  
  }

  # 2022.09-1 - Set tcoil_unit_width parameter to default of 5 if not set in parameters file.
  if {![info exists parameters(tcoil_unit_width)] || ($parameters(tcoil_unit_width) == "")} {
    set parameters(tcoil_unit_width) 5
  }

  #2022.11 - Create pin_mapping dict.
  #if {![info exists parameters(pin_mappings)]} {
  #  set parameters(pin_mappings) ""
  #}
  #set pin_mappings [dict create {*}$parameters(pin_mappings)]
  
  # 2022.11 - Create lists of powers and grounds in parameters.
  #set parameters(powers) [list VAA VDD VDDQ VDDQ_VDD2H VDDQLP VDDR]
  #set parameters(grounds) [list VSS]
  
  # 2022.07 - Read in floorplans.
  # 2022.09-2 - Updated to source floorplans from ${RealBin}/../cfg/crd_abutment_floorplans.cfg.
  source ${RealBin}/../cfg/crd_abutment_floorplans.cfg

  # 2022.11 - Source user floorplans config file.
  if {[info exists parameters(user_floorplans_cfg_file)] && ($parameters(user_floorplans_cfg_file) != "")} {
    source $parameters(user_floorplans_cfg_file)
  }

  # 2022.09-1 - Cell substitution in floorplans.
  if {[info exists parameters(cell_substitution)]} {
    foreach {oldCellname newCellname} $parameters(cell_substitution) {
      foreach element [array names floorplans] {
        regsub -all [subst -nobackslashes -nocommands {\m([xy]_)?$oldCellname\M}] $floorplans($element) [subst -nobackslashes -nocommands {\1$newCellname}] floorplans($element)
      }
    }
  }

  #2022.12 - Read in pin mappings.
  source ${RealBin}/../cfg/crd_pin_mappings.cfg
  if {[info exists parameters(user_pin_mappings_cfg_file)] && ($parameters(user_pin_mappings_cfg_file) != "")} {
    source $parameters(user_pin_mappings_cfg_file)
  }

  # 2022.03-3 - Download of Perforce files.
  # Check parameters for // to indicate Perforce paths.
  if {[regexp {//} [array get parameters]]} {
    nprint ""
    hprint "Downloading Perforce files..."

    file mkdir crd_perforce_files
    cd crd_perforce_files

    # Get parameter names for collaterals.
    set parameter_names [concat [array names parameters cdl_*] [array names parameters def_*] [array names parameters gds_*] [array names parameters lef_*]]

    # Iterate through collaterals.
    set perforce_paths [list]
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
      iprint "[lindex [run_system_cmd "p4 -p p4p-us01:1999 print -o [file tail $perforce_path] $perforce_path"] 0]"
    }

    cd ..
    hprint "Download of Perforce files complete."
  }

  # Parse DEF files to create list of components.
  foreach macro [split $parameters(testcases_stdcell_fill)] {
    set macro_def [read_file $parameters(def_$macro)]

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
    nprint ""
    hprint "Uniquifying input CDL files..."
    file mkdir crd_uniquified_input_CDL
    cd crd_uniquified_input_CDL

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
      iprint "Uniquifying $macro CDL..."
      run_system_cmd "netl_namemap -pre ${macro}_ -top $macro -fltf $parameters(uniquify_input_cdl_filter_file) $parameters(cdl_$macro) ${macro}.cdl"
      set parameters(cdl_$macro) [file join [pwd] ${macro}.cdl]
    }
    cd ..
    hprint "Uniquification of input CDL files complete."
  }

  # Uniquify input GDS files.
  if {$parameters(uniquify_input_gds)} {
    nprint ""
    hprint "Uniquifying input GDS files..."
    file mkdir crd_uniquified_input_GDS
    cd crd_uniquified_input_GDS

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
      iprint "Uniquifying $macro GDS..."
      # gds_namemap will only work on GDS root cells, so will fail for utility cell/block GDS files, for example.
      # Workaround is to extract macro from GDS file first.
      set file_contents [list]
      lappend file_contents "layout open $parameters($gds_parameter) ??"
      lappend file_contents "layout extract ${macro}.pre-uniquified.gds.gz -format gds.gz -cell $macro"
      lappend file_contents "exit"
      write_file icvwb_extract_${macro}.mac [join $file_contents \n]

      set file_contents [list]
      lappend file_contents "#!/bin/tcsh"
      lappend file_contents "module unload icvwb"
      lappend file_contents "module load icvwb/$parameters(icvwb_version)"
      lappend file_contents "icvwb -run icvwb_extract_${macro}.mac -nodisplay -log icvwb_extract_${macro}.log"
      write_file icvwb_extract_${macro}.tcsh [join $file_contents \n]
      file attributes icvwb_extract_${macro}.tcsh -permissions +x
      run_system_cmd ./icvwb_extract_${macro}.tcsh

      run_system_cmd "gds_namemap -pre ${macro}_ -nolvl $macro ${macro}.pre-uniquified.gds.gz ${macro}.gds.gz"
      set parameters($gds_parameter) [file join [pwd] ${macro}.gds.gz]
    }
    cd ..
    hprint "Uniquification of input GDS files complete."
  }

  # Create testcase GDS and run PV.
  foreach testcase [split $parameters(testcases_abutment)] {
    nprint ""
    hprint "Launching ${testcase} on grid:"
    
    get_clean_testcase $testcase
    file mkdir crd_testcases/$testcase
    cd crd_testcases/$testcase
    
    set testcase_pin_mapping [Create_Testcase_Pin_Mapping $pin_mappings $testcase]
    set macros [Get_Macro_List floorplans $testcase]

    set file_contents [list]
    lappend file_contents "#!/bin/tcsh"
    lappend file_contents [Generate_Reference_Lib parameters $macros]
    lappend file_contents [Generate_Abutment_Layout_And_Netlist_ICC2 floorplans parameters $testcase_pin_mapping $testcase]
    lappend file_contents "mkdir -p ../../crd_results/${testcase}/[string tolower $parameters(output_layout_format)]/${parameters(metal_stack)}"
    lappend file_contents "ln -s [pwd]/${testcase}$parameters(layout_file_extension_zipped) ../../crd_results/${testcase}/[string tolower $parameters(output_layout_format)]/${parameters(metal_stack)}/${testcase}$parameters(layout_file_extension_zipped)"
    #Generate_Empty_CDL $testcase
    #run_system_cmd "mkdir -p ../../crd_results/${testcase}/netlist/${parameters(metal_stack)}"
    #run_system_cmd "ln -s [pwd]/${testcase}.cdl ../../crd_results/${testcase}/netlist/${parameters(metal_stack)}/${testcase}.cdl"
    set macroCdls [list]
    foreach macro $macros {
      lappend macroCdls $parameters(cdl_$macro)
    }
    set macroCdls [lsort -unique $macroCdls]
    lappend file_contents [Generate_CDL parameters $testcase [list ${testcase}.v] $macroCdls]
    lappend file_contents "mkdir -p ../../crd_results/${testcase}/netlist/${parameters(metal_stack)}"
    lappend file_contents "ln -s [pwd]/${testcase}.cdl ../../crd_results/${testcase}/netlist/${parameters(metal_stack)}/${testcase}.cdl"
    lappend file_contents [Run_PV parameters $testcase]
    write_file ${testcase}.tcsh [join $file_contents \n]
    file attributes ${testcase}.tcsh -permissions +x
    run_system_cmd "qsub -P bnormal -cwd -V -m a -b y ./${testcase}.tcsh"

    cd ../..
  }
  
  # Create testcase_abutment_wrapper GDS, empty CDL and run PV.
  foreach testcase [split $parameters(testcases_abutment_wrapper)] {
    nprint ""
    hprint "Launching ${testcase} on grid:"
    
    regexp {wrapper_(.+)} $testcase match floorplan
    
    get_clean_testcase $testcase
    file mkdir crd_testcases/$testcase
    cd crd_testcases/$testcase

    set file_contents [list]
    lappend file_contents "#!/bin/tcsh"
    lappend file_contents [Generate_Layout floorplans parameters $hard_macros $floorplan]
    set parameters(gds_$floorplan) ${floorplan}$parameters(layout_file_extension_zipped)
    lappend file_contents [Merge_Layout parameters $floorplan $testcase]
    lappend file_contents "mkdir -p ../../crd_results/${testcase}/[string tolower $parameters(output_layout_format)]/${parameters(metal_stack)}"
    lappend file_contents "ln -s [pwd]/${testcase}$parameters(layout_file_extension_zipped) ../../crd_results/${testcase}/[string tolower $parameters(output_layout_format)]/${parameters(metal_stack)}/${testcase}$parameters(layout_file_extension_zipped)"
    Generate_Empty_CDL $testcase
    run_system_cmd "mkdir -p ../../crd_results/${testcase}/netlist/${parameters(metal_stack)}"
    run_system_cmd "ln -s [pwd]/${testcase}.cdl ../../crd_results/${testcase}/netlist/${parameters(metal_stack)}/${testcase}.cdl"
    lappend file_contents [Run_PV parameters $testcase]
    write_file ${testcase}.tcsh [join $file_contents \n]
    file attributes ${testcase}.tcsh -permissions +x
    run_system_cmd "qsub -P bnormal -cwd -V -m a -b y ./${testcase}.tcsh"

    cd ../..
  }

  # Create testcase_wrapper GDS, CDL and run PV.
  foreach testcase [split $parameters(testcases_wrapper)] {
    nprint ""
    hprint "Launching ${testcase} on grid:"
    
    regexp {wrapper_(.+)} $testcase match macro    

    get_clean_testcase $testcase
    file mkdir crd_testcases/$testcase
    cd crd_testcases/$testcase

    set file_contents [list]
    lappend file_contents [Merge_Layout parameters $macro $testcase]
    lappend file_contents "mkdir -p ../../crd_results/${testcase}/[string tolower $parameters(output_layout_format)]/${parameters(metal_stack)}"
    lappend file_contents "ln -s [pwd]/${testcase}$parameters(layout_file_extension_zipped) ../../crd_results/${testcase}/[string tolower $parameters(output_layout_format)]/${parameters(metal_stack)}/${testcase}$parameters(layout_file_extension_zipped)"

    # Generate testcase CDL.
    if {$parameters(generate_cdl)} {
      iprint "Generating $testcase CDL."

      # Read in macro CDL.
      set macro_cdl [read_file $parameters(cdl_$macro)]

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
      set testcase_orig_cdl [read_file $parameters(cdl_$testcase)]

      # Create updated testcase CDL.
      set cdl_contents [list]
      lappend cdl_contents ".include $parameters(cdl_$macro)"
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
          lappend cdl_contents "XDUT"
          foreach pin_line $macro_pins_list {
            lappend cdl_contents "+ $pin_line"
          }
          lappend cdl_contents "+ $macro"
          set subckt_section 0
        }
        lappend cdl_contents $line
      }
      write_file ${testcase}.cdl [join $cdl_contents \n]

    } else {
      Generate_Empty_CDL $testcase
    }
    run_system_cmd "mkdir -p ../../crd_results/${testcase}/netlist/${parameters(metal_stack)}"
    run_system_cmd "ln -s [pwd]/${testcase}.cdl ../../crd_results/${testcase}/netlist/${parameters(metal_stack)}/${testcase}.cdl"
    
    lappend file_contents [Run_PV parameters $testcase]
    write_file ${testcase}.tcsh [join $file_contents \n]
    file attributes ${testcase}.tcsh -permissions +x
    run_system_cmd "qsub -P bnormal -cwd -V -m a -b y ./${testcase}.tcsh"

    cd ../..
  }

  # Generate standard cell boundary testcase and run PV.
  foreach macro [split $parameters(testcases_stdcell)] {
    set testcase boundary_${macro}_stdcell
    nprint ""
    hprint "Launching ${testcase} on grid:"
    
    get_clean_testcase $testcase
    file mkdir crd_testcases/$testcase
    cd crd_testcases/$testcase
    
    set testcase_pin_mapping [Create_Testcase_Pin_Mapping $pin_mappings $testcase]
    
    set file_contents [list]
    lappend file_contents "#!/bin/tcsh"
    # Optionally generate size-only LEF.
    if {$parameters(generate_lef)} {
      lappend file_contents [Generate_LEF parameters $macro]
      set parameters(lef_$macro) ${macro}.lef
    }
    lappend file_contents [Generate_Reference_Lib parameters $macro]
    lappend file_contents [Generate_Stdcell_Ring_Layout_And_Netlist_ICC2 parameters $testcase_pin_mapping $macro $testcase]
    lappend file_contents "mkdir -p ../../crd_results/${testcase}/[string tolower $parameters(output_layout_format)]/${parameters(metal_stack)}"
    lappend file_contents "ln -s [pwd]/${testcase}$parameters(layout_file_extension_zipped) ../../crd_results/${testcase}/[string tolower $parameters(output_layout_format)]/${parameters(metal_stack)}/${testcase}$parameters(layout_file_extension_zipped)"
    #Generate_Empty_CDL $testcase
    #run_system_cmd "mkdir -p ../../crd_results/${testcase}/netlist/${parameters(metal_stack)}"
    #run_system_cmd "ln -s [pwd]/${testcase}.cdl ../../crd_results/${testcase}/netlist/${parameters(metal_stack)}/${testcase}.cdl"
    lappend file_contents [Generate_CDL parameters $testcase [list ${testcase}.v] [list $parameters(stdcell_cdl) $parameters(cdl_$macro)]]
    lappend file_contents "mkdir -p ../../crd_results/${testcase}/netlist/${parameters(metal_stack)}"
    lappend file_contents "ln -s [pwd]/${testcase}.cdl ../../crd_results/${testcase}/netlist/${parameters(metal_stack)}/${testcase}.cdl"
    lappend file_contents [Run_PV parameters $testcase]
    write_file ${testcase}.tcsh [join $file_contents \n]
    file attributes ${testcase}.tcsh -permissions +x
    run_system_cmd "qsub -P bnormal -cwd -V -m a -b y ./${testcase}.tcsh"

    cd ../..
  }

  # Generate abutment standard cell boundary testcase and run PV.
  foreach floorplan [split $parameters(testcases_abutment_stdcell)] {
    set testcase boundary_${floorplan}_stdcell
    nprint ""
    hprint "Launching ${testcase} on grid:"
    
    get_clean_testcase $testcase
    file mkdir crd_testcases/$testcase
    cd crd_testcases/$testcase

    set file_contents [list]
    lappend file_contents "#!/bin/tcsh"
    lappend file_contents [Generate_Layout floorplans parameters $hard_macros $floorplan]
    set parameters(gds_$floorplan) ${floorplan}$parameters(layout_file_extension_zipped)
    lappend file_contents [Generate_LEF parameters $floorplan]
    set parameters(lef_$floorplan) ${floorplan}.lef
    lappend file_contents [Generate_Reference_Lib parameters $floorplan]
    lappend file_contents [Generate_Stdcell_Ring parameters $power_supplies $floorplan $testcase]
    lappend file_contents "mkdir -p ../../crd_results/${testcase}/[string tolower $parameters(output_layout_format)]/${parameters(metal_stack)}"
    lappend file_contents "ln -s [pwd]/${testcase}$parameters(layout_file_extension_zipped) ../../crd_results/${testcase}/[string tolower $parameters(output_layout_format)]/${parameters(metal_stack)}/${testcase}$parameters(layout_file_extension_zipped)"
    Generate_Empty_CDL $testcase
    run_system_cmd "mkdir -p ../../crd_results/${testcase}/netlist/${parameters(metal_stack)}"
    run_system_cmd "ln -s [pwd]/${testcase}.cdl ../../crd_results/${testcase}/netlist/${parameters(metal_stack)}/${testcase}.cdl"
    lappend file_contents [Run_PV parameters $testcase]
    write_file ${testcase}.tcsh [join $file_contents \n]
    file attributes ${testcase}.tcsh -permissions +x
    run_system_cmd "qsub -P bnormal -cwd -V -m a -b y ./${testcase}.tcsh"

    cd ../..
  }

  # Generate standard cell fill testcase and run PV.
  foreach macro [split $parameters(testcases_stdcell_fill)] {
    nprint ""
    hprint "Launching Standard Cell Fill on ${macro} on grid:"
    
    get_clean_testcase $macro
    file mkdir crd_testcases/$macro
    cd crd_testcases/$macro
    
    set macro_pin_mapping [Create_Testcase_Pin_Mapping $pin_mappings $macro]
    
    set file_contents [list]
    lappend file_contents "#!/bin/tcsh"
    lappend file_contents [Generate_Verilog parameters $macro $parameters(cdl_$macro)]
    lappend file_contents "mv ${macro}.v ${macro}.stdcell_empty.v"
    lappend file_contents [Generate_Reference_Lib parameters $parameters(def_components_$macro)]
    lappend file_contents [Generate_Stdcell_Fill parameters $macro_pin_mapping $macro]
    lappend file_contents "mkdir -p ../../crd_results/${macro}/[string tolower $parameters(output_layout_format)]/${parameters(metal_stack)}"
    lappend file_contents "ln -s [pwd]/${macro}$parameters(layout_file_extension_zipped) ../../crd_results/${macro}/[string tolower $parameters(output_layout_format)]/${parameters(metal_stack)}/${macro}$parameters(layout_file_extension_zipped)"
    lappend file_contents "mkdir -p ../../crd_results/${macro}/lef/${parameters(metal_stack)}"
    lappend file_contents "ln -s [pwd]/${macro}.lef ../../crd_results/${macro}/lef/${parameters(metal_stack)}/${macro}.lef"
    #Generate_Empty_CDL $macro
    #run_system_cmd "mkdir -p ../../crd_results/${macro}/netlist/${parameters(metal_stack)}"
    #run_system_cmd "ln -s [pwd]/${macro}.cdl ../../crd_results/${macro}/netlist/${parameters(metal_stack)}/${macro}.cdl"
    set cdl_list [list $parameters(stdcell_cdl)]
    foreach component $parameters(def_components_$macro) {
      lappend cdl_list $parameters(cdl_$component)
    }
    lappend file_contents [Generate_CDL parameters $macro ${macro}.v $cdl_list]
    lappend file_contents "mkdir -p ../../crd_results/${macro}/netlist/${parameters(metal_stack)}"
    lappend file_contents "ln -s [pwd]/${macro}.cdl ../../crd_results/${macro}/netlist/${parameters(metal_stack)}/${macro}.cdl"
    lappend file_contents [Run_PV parameters $macro]
    write_file ${macro}.tcsh [join $file_contents \n]
    file attributes ${macro}.tcsh -permissions +x
    run_system_cmd "qsub -P bnormal -cwd -V -m a -b y ./${macro}.tcsh"

    cd ../..
  }

  foreach testcase [split $parameters(testcases_pv_only)] {
    nprint ""
    hprint "Launching PV only flow for ${testcase} on grid:"

    get_clean_testcase $testcase
    file mkdir crd_testcases/$testcase
    cd crd_testcases/$testcase

    set file_contents [list]
    lappend file_contents "#!/bin/tcsh"
    # create link to GDS and CDL.
    run_system_cmd "ln -s $parameters(gds_$testcase) ${testcase}$parameters(layout_file_extension_zipped)"
    run_system_cmd "mkdir -p ../../crd_results/${testcase}/[string tolower $parameters(output_layout_format)]/${parameters(metal_stack)}"
    run_system_cmd "ln -s [pwd]/${testcase}$parameters(layout_file_extension_zipped) ../../crd_results/${testcase}/[string tolower $parameters(output_layout_format)]/${parameters(metal_stack)}/${testcase}$parameters(layout_file_extension_zipped)"
    run_system_cmd "ln -s $parameters(cdl_$testcase) ${testcase}.cdl"
    run_system_cmd "mkdir -p ../../crd_results/${testcase}/netlist/${parameters(metal_stack)}"
    run_system_cmd "ln -s [pwd]/${testcase}.cdl ../../crd_results/${testcase}/netlist/${parameters(metal_stack)}/${testcase}.cdl"
    lappend file_contents [Run_PV parameters $testcase]
    write_file ${testcase}.tcsh [join $file_contents \n]
    file attributes ${testcase}.tcsh -permissions +x
    run_system_cmd "qsub -P bnormal -cwd -V -m a -b y ./${testcase}.tcsh"
    
    cd ../..
  }

  foreach testcase [array names parameters testcases_utility_*] {
    # Move to next testcase if testcase_utility_* parameter is empty.
    if {$parameters($testcase) == ""} {
      continue
    }

    nprint ""
    hprint "Launching ${testcase} on grid:"

    get_clean_testcase $testcase
    file mkdir crd_testcases/$testcase
    cd crd_testcases/$testcase

    set mode [lindex [split $parameters($testcase) :] 0]
    set macro_list [list]
    foreach macro_sublist [lrange [split $parameters($testcase) :] 1 end] {
      set macro_list [concat $macro_list $macro_sublist]
    }
    set macro_list [lsort -unique $macro_list]

    # Generate testcase GDS.
    iprint "Generating $testcase ${parameters(output_layout_format)}."
    set file_contents [list]
    lappend file_contents "default filter_layer_hier 1"
    lappend file_contents "default layer_hier_level 0"
    lappend file_contents "default find_limit unlimited"
    lappend file_contents "set layoutID \[layout new $testcase -dbu $parameters(dbu) -uu_per_dbu $parameters(uu_per_dbu)\]"

    foreach macro $macro_list {
      lappend file_contents "set pinID_$macro \[layout new pin_$macro -dbu $parameters(dbu) -uu_per_dbu $parameters(uu_per_dbu)\]"
      lappend file_contents "layout open $parameters(gds_$macro) $macro"
      lappend file_contents "set boundary_bbox \[layer bbox $parameters(boundary_layer) -levels 0\]"
      lappend file_contents "set x_$macro \[lindex \$boundary_bbox 2\]"
      lappend file_contents "set y_$macro \[lindex \$boundary_bbox 3\]"
      if {$parameters(macro_text_layers) != ""} {
        lappend file_contents "if \{\[find init -type text -layer \"$parameters(macro_text_layers)\"\]\} \{"
        lappend file_contents "  find table select *"
        lappend file_contents "  select copy \"0 0\""
        lappend file_contents "  layout active \$pinID_$macro"
        lappend file_contents "  select paste \"0 0\""
        lappend file_contents "\}"
      }
    }
    lappend file_contents "layout active \$layoutID"

    # 2022.04-3 - To prevent ICVWB error for adding same reference layout, compiling list of unique GDS files prior to adding them.
    set reference_layouts [list]
    foreach macro $macro_list {
      #lappend file_contents "layout reference add $parameters(gds_$macro)"
      lappend reference_layouts $parameters(gds_$macro)
      lappend file_contents "layout reference add \$pinID_$macro"
    }
    foreach reference_layout [lsort -unique $reference_layouts] {
      lappend file_contents "layout reference add $reference_layout"
    }

    lappend file_contents "set x 0"
    lappend file_contents "set y 0"

    # $mode == "full"
    if {$mode == "full"} {
      for {set i 0} {$i < [llength $macro_list]} {incr i} {
        for {set j $i} {$j < [llength $macro_list]} {incr j} {
          set macro1 [lindex $macro_list $i]
          set macro2 [lindex $macro_list $j]

          lappend file_contents "cell add sref $macro1     \"0 \$y\" 0 0"
          lappend file_contents "cell add sref pin_$macro1 \"0 \$y\" 0 0"
          lappend file_contents "cell add sref $macro2     \"\[expr 2 * \$x_$macro1\] \$y\" 180 1"
          lappend file_contents "cell add sref pin_$macro2 \"\[expr 2 * \$x_$macro1\] \$y\" 180 1"
          lappend file_contents "cell add sref $macro1     \"\[expr 3 * \$x_$macro1\] \$y\" 180 1"
          lappend file_contents "cell add sref pin_$macro1 \"\[expr 3 * \$x_$macro1\] \$y\" 180 1"
          lappend file_contents "cell add sref $macro2     \"\[expr 4 * \$x_$macro1\] \$y\" 180 1"
          lappend file_contents "cell add sref pin_$macro2 \"\[expr 4 * \$x_$macro1\] \$y\" 180 1"
          lappend file_contents "cell add sref $macro1     \"\[expr 5 * \$x_$macro1\] \[expr \$y + \$y_$macro1\]\" 180 0"
          lappend file_contents "cell add sref pin_$macro1 \"\[expr 5 * \$x_$macro1\] \[expr \$y + \$y_$macro1\]\" 180 0"
          lappend file_contents "cell add sref $macro2     \"\[expr 6 * \$x_$macro1\] \$y\" 180 1"
          lappend file_contents "cell add sref pin_$macro2 \"\[expr 6 * \$x_$macro1\] \$y\" 180 1"
          lappend file_contents "cell add sref $macro1     \"\[expr 6 * \$x_$macro1\] \$y\" 0 0"
          lappend file_contents "cell add sref pin_$macro1 \"\[expr 6 * \$x_$macro1\] \$y\" 0 0"
          lappend file_contents "cell add sref $macro2     \"\[expr 8 * \$x_$macro1\] \[expr \$y + \$y_$macro1\]\" 180 0"
          lappend file_contents "cell add sref pin_$macro2 \"\[expr 8 * \$x_$macro1\] \[expr \$y + \$y_$macro1\]\" 180 0"
          lappend file_contents "cell add sref $macro1     \"\[expr 8 * \$x_$macro1\] \$y\" 0 0"
          lappend file_contents "cell add sref pin_$macro1 \"\[expr 8 * \$x_$macro1\] \$y\" 0 0"
          lappend file_contents "cell add sref $macro1     \"\[expr 9 * \$x_$macro1\] \[expr \$y + \$y_$macro1\]\" 0 1"
          lappend file_contents "cell add sref pin_$macro1 \"\[expr 9 * \$x_$macro1\] \[expr \$y + \$y_$macro1\]\" 0 1"
          lappend file_contents "cell add sref $macro2     \"0 \[expr \$y + 2 * \$y_$macro1\]\" 0 1"
          lappend file_contents "cell add sref pin_$macro2 \"0 \[expr \$y + 2 * \$y_$macro1\]\" 0 1"
          lappend file_contents "cell add sref $macro1     \"\$x_$macro1 \[expr \$y + 2 * \$y_$macro1\]\" 0 1"
          lappend file_contents "cell add sref pin_$macro1 \"\$x_$macro1 \[expr \$y + 2 * \$y_$macro1\]\" 0 1"
          lappend file_contents "cell add sref $macro2     \"\[expr 3 * \$x_$macro1\] \[expr \$y + \$y_$macro1\]\" 180 1"
          lappend file_contents "cell add sref pin_$macro2 \"\[expr 3 * \$x_$macro1\] \[expr \$y + \$y_$macro1\]\" 180 1"
          lappend file_contents "cell add sref $macro1     \"\[expr 4 * \$x_$macro1\] \[expr \$y + \$y_$macro1\]\" 180 1"
          lappend file_contents "cell add sref pin_$macro1 \"\[expr 4 * \$x_$macro1\] \[expr \$y + \$y_$macro1\]\" 180 1"
          lappend file_contents "cell add sref $macro2     \"\[expr 4 * \$x_$macro1\] \[expr \$y + 2 * \$y_$macro1\]\" 0 1"
          lappend file_contents "cell add sref pin_$macro2 \"\[expr 4 * \$x_$macro1\] \[expr \$y + 2 * \$y_$macro1\]\" 0 1"
          lappend file_contents "cell add sref $macro2     \"\[expr 6 * \$x_$macro1\] \[expr \$y + 2 * \$y_$macro1\]\" 180 0"
          lappend file_contents "cell add sref pin_$macro2 \"\[expr 6 * \$x_$macro1\] \[expr \$y + 2 * \$y_$macro1\]\" 180 0"
          lappend file_contents "cell add sref $macro2     \"\[expr 7 * \$x_$macro1\] \[expr \$y + \$y_$macro1\]\" 180 1"
          lappend file_contents "cell add sref pin_$macro2 \"\[expr 7 * \$x_$macro1\] \[expr \$y + \$y_$macro1\]\" 180 1"
          lappend file_contents "cell add sref $macro1     \"\[expr 8 * \$x_$macro1\] \[expr \$y + \$y_$macro1\]\" 180 1"
          lappend file_contents "cell add sref pin_$macro1 \"\[expr 8 * \$x_$macro1\] \[expr \$y + \$y_$macro1\]\" 180 1"
          lappend file_contents "cell add sref $macro2     \"\[expr 9 * \$x_$macro1\] \[expr \$y + 2 * \$y_$macro1\]\" 180 0"
          lappend file_contents "cell add sref pin_$macro2 \"\[expr 9 * \$x_$macro1\] \[expr \$y + 2 * \$y_$macro1\]\" 180 0"
          lappend file_contents "cell add sref $macro2     \"\[expr 10 * \$x_$macro1\] \[expr \$y + \$y_$macro1\]\" 180 1"
          lappend file_contents "cell add sref pin_$macro2 \"\[expr 10 * \$x_$macro1\] \[expr \$y + \$y_$macro1\]\" 180 1"
          lappend file_contents "cell add sref $macro2     \"\$x_$macro1 \[expr \$y + 2 * \$y_$macro1\]\" 180 1"
          lappend file_contents "cell add sref pin_$macro2 \"\$x_$macro1 \[expr \$y + 2 * \$y_$macro1\]\" 180 1"
          lappend file_contents "cell add sref $macro1     \"\$x_$macro1 \[expr \$y + 3 * \$y_$macro1\]\" 0 1"
          lappend file_contents "cell add sref pin_$macro1 \"\$x_$macro1 \[expr \$y + 3 * \$y_$macro1\]\" 0 1"
          lappend file_contents "cell add sref $macro2     \"\[expr 2 * \$x_$macro1\] \[expr \$y + 3 * \$y_$macro1\]\" 0 1"
          lappend file_contents "cell add sref pin_$macro2 \"\[expr 2 * \$x_$macro1\] \[expr \$y + 3 * \$y_$macro1\]\" 0 1"
          lappend file_contents "cell add sref $macro1     \"\[expr 4 * \$x_$macro1\] \[expr \$y + 3 * \$y_$macro1\]\" 180 0"
          lappend file_contents "cell add sref pin_$macro1 \"\[expr 4 * \$x_$macro1\] \[expr \$y + 3 * \$y_$macro1\]\" 180 0"
          lappend file_contents "cell add sref $macro2     \"\[expr 5 * \$x_$macro1\] \[expr \$y + 3 * \$y_$macro1\]\" 180 0"
          lappend file_contents "cell add sref pin_$macro2 \"\[expr 5 * \$x_$macro1\] \[expr \$y + 3 * \$y_$macro1\]\" 180 0"
          lappend file_contents "cell add sref $macro1     \"\[expr 5 * \$x_$macro1\] \[expr \$y + 2 * \$y_$macro1\]\" 0 0"
          lappend file_contents "cell add sref pin_$macro1 \"\[expr 5 * \$x_$macro1\] \[expr \$y + 2 * \$y_$macro1\]\" 0 0"
          lappend file_contents "cell add sref $macro1     \"\[expr 7 * \$x_$macro1\] \[expr \$y + 3 * \$y_$macro1\]\" 180 0"
          lappend file_contents "cell add sref pin_$macro1 \"\[expr 7 * \$x_$macro1\] \[expr \$y + 3 * \$y_$macro1\]\" 180 0"
          lappend file_contents "cell add sref $macro1     \"\[expr 7 * \$x_$macro1\] \[expr \$y + 2 * \$y_$macro1\]\" 0 0"
          lappend file_contents "cell add sref pin_$macro1 \"\[expr 7 * \$x_$macro1\] \[expr \$y + 2 * \$y_$macro1\]\" 0 0"
          lappend file_contents "cell add sref $macro1     \"\[expr 8 * \$x_$macro1\] \[expr \$y + 2 * \$y_$macro1\]\" 0 0"
          lappend file_contents "cell add sref pin_$macro1 \"\[expr 8 * \$x_$macro1\] \[expr \$y + 2 * \$y_$macro1\]\" 0 0"
          lappend file_contents "cell add sref $macro1     \"\[expr 10 * \$x_$macro1\] \[expr \$y + 2 * \$y_$macro1\]\" 180 1"
          lappend file_contents "cell add sref pin_$macro1 \"\[expr 10 * \$x_$macro1\] \[expr \$y + 2 * \$y_$macro1\]\" 180 1"

          lappend file_contents "hierarchy explode -cells pin_$macro1"
          if {$macro1 ne $macro2} {
            lappend file_contents "hierarchy explode -cells pin_$macro2"
          }

          lappend file_contents "set y \[expr \$y + 3 * \$y_$macro1\]"
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

            lappend file_contents "cell add sref $macro1     \"0 \$y\" 0 0"
            lappend file_contents "cell add sref pin_$macro1 \"0 \$y\" 0 0"
            lappend file_contents "cell add sref $macro2     \"\$x_$macro1 \$y\" 0 0"
            lappend file_contents "cell add sref pin_$macro2 \"\$x_$macro1 \$y\" 0 0"
            lappend file_contents "cell add sref $macro1     \"\[expr 2 * \$x_$macro1\] \$y\" 0 0"
            lappend file_contents "cell add sref pin_$macro1 \"\[expr 2 * \$x_$macro1\] \$y\" 0 0"
            lappend file_contents "cell add sref $macro2     \"\[expr 3 * \$x_$macro1\] \$y\" 0 0"
            lappend file_contents "cell add sref pin_$macro2 \"\[expr 3 * \$x_$macro1\] \$y\" 0 0"
            lappend file_contents "cell add sref $macro1     \"\[expr 4 * \$x_$macro1\] \$y\" 0 0"
            lappend file_contents "cell add sref pin_$macro1 \"\[expr 4 * \$x_$macro1\] \$y\" 0 0"
            lappend file_contents "cell add sref $macro2     \"0 \[expr \$y + 2 * \$y_$macro1\]\" 0 1"
            lappend file_contents "cell add sref pin_$macro2 \"0 \[expr \$y + 2 * \$y_$macro1\]\" 0 1"
            lappend file_contents "cell add sref $macro1     \"\$x_$macro1 \[expr \$y + 2 * \$y_$macro1\]\" 0 1"
            lappend file_contents "cell add sref pin_$macro1 \"\$x_$macro1 \[expr \$y + 2 * \$y_$macro1\]\" 0 1"
            lappend file_contents "cell add sref $macro1     \"\[expr 2 * \$x_$macro1\] \[expr \$y + 2 * \$y_$macro1\]\" 0 1"
            lappend file_contents "cell add sref pin_$macro1 \"\[expr 2 * \$x_$macro1\] \[expr \$y + 2 * \$y_$macro1\]\" 0 1"
            lappend file_contents "cell add sref $macro2     \"\[expr 3 * \$x_$macro1\] \[expr \$y + 2 * \$y_$macro1\]\" 0 1"
            lappend file_contents "cell add sref pin_$macro2 \"\[expr 3 * \$x_$macro1\] \[expr \$y + 2 * \$y_$macro1\]\" 0 1"
            lappend file_contents "cell add sref $macro1     \"\[expr 4 * \$x_$macro1\] \[expr \$y + 2 * \$y_$macro1\]\" 0 1"
            lappend file_contents "cell add sref pin_$macro1 \"\[expr 4 * \$x_$macro1\] \[expr \$y + 2 * \$y_$macro1\]\" 0 1"
            lappend file_contents "cell add sref $macro1     \"0 \[expr \$y + 3 * \$y_$macro1\]\" 0 1"
            lappend file_contents "cell add sref pin_$macro1 \"0 \[expr \$y + 3 * \$y_$macro1\]\" 0 1"
            lappend file_contents "cell add sref $macro2     \"\$x_$macro1 \[expr \$y + 3 * \$y_$macro1\]\" 0 1"
            lappend file_contents "cell add sref pin_$macro2 \"\$x_$macro1 \[expr \$y + 3 * \$y_$macro1\]\" 0 1"
            lappend file_contents "cell add sref $macro1     \"\[expr 2 * \$x_$macro1\] \[expr \$y + 3 * \$y_$macro1\]\" 0 1"
            lappend file_contents "cell add sref pin_$macro1 \"\[expr 2 * \$x_$macro1\] \[expr \$y + 3 * \$y_$macro1\]\" 0 1"
            lappend file_contents "cell add sref $macro2     \"\[expr 3 * \$x_$macro1\] \[expr \$y + 3 * \$y_$macro1\]\" 0 1"
            lappend file_contents "cell add sref pin_$macro2 \"\[expr 3 * \$x_$macro1\] \[expr \$y + 3 * \$y_$macro1\]\" 0 1"
            lappend file_contents "cell add sref $macro1     \"\[expr 4 * \$x_$macro1\] \[expr \$y + 3 * \$y_$macro1\]\" 0 1"
            lappend file_contents "cell add sref pin_$macro1 \"\[expr 4 * \$x_$macro1\] \[expr \$y + 3 * \$y_$macro1\]\" 0 1"
            lappend file_contents "cell add sref $macro2     \"0 \[expr \$y + 3 * \$y_$macro1\]\" 0 0"
            lappend file_contents "cell add sref pin_$macro2 \"0 \[expr \$y + 3 * \$y_$macro1\]\" 0 0"
            lappend file_contents "cell add sref $macro2     \"\$x_$macro1 \[expr \$y + 3 * \$y_$macro1\]\" 0 0"
            lappend file_contents "cell add sref pin_$macro2 \"\$x_$macro1 \[expr \$y + 3 * \$y_$macro1\]\" 0 0"
            lappend file_contents "cell add sref $macro1     \"\[expr 2 * \$x_$macro1\] \[expr \$y + 3 * \$y_$macro1\]\" 0 0"
            lappend file_contents "cell add sref pin_$macro1 \"\[expr 2 * \$x_$macro1\] \[expr \$y + 3 * \$y_$macro1\]\" 0 0"
            lappend file_contents "cell add sref $macro1     \"\[expr 3 * \$x_$macro1\] \[expr \$y + 3 * \$y_$macro1\]\" 0 0"
            lappend file_contents "cell add sref pin_$macro1 \"\[expr 3 * \$x_$macro1\] \[expr \$y + 3 * \$y_$macro1\]\" 0 0"
            lappend file_contents "cell add sref $macro1     \"\[expr 4 * \$x_$macro1\] \[expr \$y + 3 * \$y_$macro1\]\" 0 0"
            lappend file_contents "cell add sref pin_$macro1 \"\[expr 4 * \$x_$macro1\] \[expr \$y + 3 * \$y_$macro1\]\" 0 0"

            lappend file_contents "hierarchy explode -cells pin_$macro1"
            lappend file_contents "hierarchy explode -cells pin_$macro2"

            lappend file_contents "set y \[expr \$y + 4 * \$y_$macro1\]"
          }
        } 
      }

      # Utility block abutments for blocks for different hard macros.
      # i iterates through sublists of utility blocks. Note that i is set to 1, not 0, as first element of the split $parameters($testcase) is the mode.
      for {set i 1} {$i < [expr [llength [split $parameters($testcase) :]] - 1]} {incr i} {
        # Iterate through each utility block in "i"th sublist.
        foreach macro1 [lindex [split $parameters($testcase) :] $i] {
          # j iterates through sublists after the "i"th sublist.
          for {set j [expr {$i + 1}]} {$j < [llength [split $parameters($testcase) :]]} {incr j} {
            # Iterate through each utility block in the "j"th sublist
            foreach macro2 [lindex [split $parameters($testcase) :] $j] {

              lappend file_contents "cell add sref $macro1     \"0 \$y\" 0 0"
              lappend file_contents "cell add sref pin_$macro1 \"0 \$y\" 0 0"
              lappend file_contents "cell add sref $macro1     \"\$x_$macro1 \$y\" 0 0"
              lappend file_contents "cell add sref pin_$macro1 \"\$x_$macro1 \$y\" 0 0"
              lappend file_contents "cell add sref $macro2     \"0 \[expr \$y + \$y_$macro1 + \$y_$macro2\]\" 0 1"
              lappend file_contents "cell add sref pin_$macro2 \"0 \[expr \$y + \$y_$macro1 + \$y_$macro2\]\" 0 1"
              lappend file_contents "cell add sref $macro2     \"\$x_$macro1 \[expr \$y + \$y_$macro1 + \$y_$macro2\]\" 0 1"
              lappend file_contents "cell add sref pin_$macro2 \"\$x_$macro1 \[expr \$y + \$y_$macro1 + \$y_$macro2\]\" 0 1"
              lappend file_contents "cell add sref $macro1     \"0 \[expr \$y + 2 * \$y_$macro1 + \$y_$macro2\]\" 0 1"
              lappend file_contents "cell add sref pin_$macro1 \"0 \[expr \$y + 2 * \$y_$macro1 + \$y_$macro2\]\" 0 1"
              lappend file_contents "cell add sref $macro1     \"\$x_$macro1 \[expr \$y + 2 * \$y_$macro1 + \$y_$macro2\]\" 0 1"
              lappend file_contents "cell add sref pin_$macro1 \"\$x_$macro1 \[expr \$y + 2 * \$y_$macro1 + \$y_$macro2\]\" 0 1"
              lappend file_contents "cell add sref $macro2     \"0 \[expr \$y + 2 * \$y_$macro1 + 2 * \$y_$macro2\]\" 0 1"
              lappend file_contents "cell add sref pin_$macro2 \"0 \[expr \$y + 2 * \$y_$macro1 + 2 * \$y_$macro2\]\" 0 1"
              lappend file_contents "cell add sref $macro2     \"\$x_$macro1 \[expr \$y + 2 * \$y_$macro1 + 2 * \$y_$macro2\]\" 0 1"
              lappend file_contents "cell add sref pin_$macro2 \"\$x_$macro1 \[expr \$y + 2 * \$y_$macro1 + 2 * \$y_$macro2\]\" 0 1"
              lappend file_contents "cell add sref $macro1     \"0 \[expr \$y + 2 * \$y_$macro1 + 2 * \$y_$macro2\]\" 0 0"
              lappend file_contents "cell add sref pin_$macro1 \"0 \[expr \$y + 2 * \$y_$macro1 + 2 * \$y_$macro2\]\" 0 0"
              lappend file_contents "cell add sref $macro1     \"\$x_$macro1 \[expr \$y + 2 * \$y_$macro1 + 2 * \$y_$macro2\]\" 0 0"
              lappend file_contents "cell add sref pin_$macro1 \"\$x_$macro1 \[expr \$y + 2 * \$y_$macro1 + 2 * \$y_$macro2\]\" 0 0"

              lappend file_contents "hierarchy explode -cells pin_$macro1"
              lappend file_contents "hierarchy explode -cells pin_$macro2"

              lappend file_contents "set y \[expr \$y + 3 * \$y_$macro1 + 2 * \$y_$macro2\]"
            }
          }
        }
      }
    }
    # end $mode == "block_ew"
    
    if {$parameters(output_layout_format) == "GDS"} {
      lappend file_contents "layout extract ${testcase}$parameters(layout_file_extension_zipped) -format gds.gz -cell $testcase"
    } else {
      lappend file_contents "layout extract ${testcase}$parameters(layout_file_extension_zipped) -format oasis -cell $testcase"
    }
    lappend file_contents "exit"
    write_file icvwb.mac [join $file_contents \n]

    set file_contents [list]
    lappend file_contents "#!/bin/tcsh"
    lappend file_contents "module unload icvwb"
    lappend file_contents "module load icvwb/$parameters(icvwb_version)"
    # 2022.04-3 - Changed ICVWB to now stop on errors.
    #lappend file_contents "icvwb -run icvwb.mac -runnohalt -nodisplay -log icvwb.log"
    lappend file_contents "icvwb -run icvwb.mac -nodisplay -log icvwb.log"
    write_file icvwb.tcsh [join $file_contents \n]
    file attributes icvwb.tcsh -permissions +x
    
    set file_contents [list]
    lappend file_contents "#!/bin/tcsh"
    lappend file_contents ./icvwb.tcsh
    lappend file_contents "mkdir -p ../../crd_results/${testcase}/[string tolower $parameters(output_layout_format)]/${parameters(metal_stack)}"
    lappend file_contents "ln -s [pwd]/${testcase}$parameters(layout_file_extension_zipped) ../../crd_results/${testcase}/[string tolower $parameters(output_layout_format)]/${parameters(metal_stack)}/${testcase}$parameters(layout_file_extension_zipped)"
    Generate_Empty_CDL $testcase
    run_system_cmd "mkdir -p ../../crd_results/${testcase}/netlist/${parameters(metal_stack)}"
    run_system_cmd "ln -s [pwd]/${testcase}.cdl ../../crd_results/${testcase}/netlist/${parameters(metal_stack)}/${testcase}.cdl"
    lappend file_contents [Run_PV parameters $testcase]
    write_file ${testcase}.tcsh [join $file_contents \n]
    file attributes ${testcase}.tcsh -permissions +x
    run_system_cmd "qsub -P bnormal -cwd -V -m a -b y ./${testcase}.tcsh"
    
    cd ../..
  }
  
  # 2022.03-1 - Close script log file.
  nprint ""
  hprint "CRD Abutment Verification Script completed."
  
  return 0
}


try {
    header
    set exitval [Main]
} on error {results options} {
    set exitval [fatal_error [dict get $options -errorinfo]]
} finally {
    footer
    write_stdout_log "$LOGFILE"
}
myexit $exitval





################################################################################
# No Linting Area
################################################################################
# Main exists but is too far away from the beggining
# nolint Main
# nolint utils__script_usage_statistics
# it is included in header
