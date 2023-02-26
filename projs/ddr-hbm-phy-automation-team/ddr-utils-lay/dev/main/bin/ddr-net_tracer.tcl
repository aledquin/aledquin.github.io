#!/depot/tcl8.6.3/bin/tclsh8.6

##################################################################################################################################################################################
# Nettracing , Connectivity map creation, Layer group creation															##
# Revision history.																				##
# 20230201 - Check stream map link/file exist and use that one. define layout format by layout extention. Color scheme exceeds resolved. Coloring corrected			##
# 20221208 - DDR_UTIL_LAY module requirements are implemented, Metal resistor  & MIMCAP groups are created in LayerGrouping							##
# 20220901 - LayerGrouping TSMC05/03 support added, Cleaned-up layer purpose list  												##
# 20220830 - Added metal shape cutting by Metal Resistors (ss &TSmc + TSMC03/05 support)  											##
# 20220824 - Added more(7) colors to colorScheme to support higher metal stacks  												##
# 20210921 - "-layot 1" is removed from LayerGrouping.tcl file 															##
# 20210704 - Create LayerGrouping.tcl file for layer grouping, coloring and patterning in icvwb. Create/update  a link to stream.layermap file  				##
# 20210701 - Create the ConnectivityUp.tcl file starting from M_bot to RDL for loading in ICVWB, removed all layer purposes beside "drawing, label, pin, bar, large"  		##
# 20210225 - Added TSMC05 & TSMC03 layer map support. Use additional option in command line:  -fab_node tsmc05[*] or tsmc03[*]  						##
# 20200408 - Added "use_text = TOP" to text_net function to avoid lower level text, possibly of a different name, to be assigned to a net.					##
# 20191025 - Enhanced to provide a text_depth switch to trace texts from a lower level of hierarchy.										##
# 20191018 - Enhanced to allow top level texts to attach to polygons at lower levels of hierarchy.										##
# 20190802 - Changed grid queue from normal to quick.																##
# 20190310 - Added -vueshort to ICV call.																	##
# 20181030 - Added support for OASIS layout databases.																##
# 20181024 - GDS and edtext files can now be specified with relative paths.													##
# Created By : Manmit Muker : 																			##
# Development continued by:  Sergey Chatrchyan																	##
##################################################################################################################################################################################

#--------------------------------------------------------------------#
set VERSION "2022ww35" ;
#--------------------------------------------------------------------#

package require try         ;# Tcllib.
package require cmdline 1.5 ;# First version with proper error-codes.
package require fileutil

set DEBUG      0
set VERBOSITY  0
set STDOUT_LOG ""
set AUTHOR     "Sergey Chatrchyan (sergeych), Patrick Juliano (juliano), Alvaro Quintana Carvacho"
set RealBin [file dirname [file normalize [info script]] ]
set RealScript [file tail [file normalize [info script]] ]
set PROGRAM_NAME $RealScript
set LOGFILE "[pwd]/$PROGRAM_NAME.log"

# Declare cmdline opt vars here, so they are global
set opt_help ""

if {[file isdirectory "$RealBin/../lib/tcl"]} {
  lappend auto_path "$RealBin/../lib/tcl"
} else {
  set SHELLTOOL_LOC "/remote/cad-rep/msip/tools/Shelltools"
  lappend auto_path "$SHELLTOOL_LOC/ddr-utils-lay/dev/lib/tcl"
  set RealBin       "$SHELLTOOL_LOC/ddr-utils-lay/dev/bin"
}

package require Messaging 1.0
namespace import ::Messaging::*
package require Misc 1.0
namespace import ::Misc::*

#-----------------------------------------------------------------
# Show the script usage details to the user
#-----------------------------------------------------------------
proc showUsage {} {
  global PROGRAM_NAME
  set msg "\nUsage:  $PROGRAM_NAME "
  append msg "***** Script to trace nets in a layout database based on their netname. Nets can be labeled in the layout database or provided in an edtext file."
  append msg "\n\t  Example command lines:\n"
  append msg "\t\t  $PROGRAM_NAME -layout <GDS/OAS file> -cell <cellname> -layermap <layermap file> -layout_format <GDS|OAS> -bot_metal <lowest metal number to include for connectivity> \[-nets \"<net1> <net2> ...\"\]"
  append msg "\t\t\t\t    \[-edtext <edtext file>\] \[-text_depth <depth, where 0 is top>\] \[-icv_version <version>\] \[-grid\] \[-cores <cores>\] \[-mem <memory>\] \[-fab_node <fabNode>\]\n"
  append msg "\t\t  $PROGRAM_NAME -h \n"
  append msg "\n\t Valid command line options:\n"
  append msg "\t     -d/debug #       : verbosity of debug messaging.  Not supported\n"
  append msg "\t     -v/verbosity #   : verbosity of user messaging. Not supported\n"
  append msg "\t     -layout  	: input design file name\n"
  append msg "\t     -cell        	: top cell name\n"
  append msg "\t     -layout_format   : input file format GDS|OAS\n"
  append msg "\t     -layermap	: layermap file name with the path\n"
  append msg "\t     -bot_metal       : MIPLAST metal number\n"
  append msg "\t     -fab_node  	: advanced node name tsmc05|tsmc03 \n"
  append msg "\t     -nets	  	: traced net names list (PG & Signals)\n"
  append msg "\t     -text_depth      : hierarchy level of looking for net names\n"
  append msg "\t     -edtext 	   	: File name with label coordinates\n"
  append msg "\t     -cores       	: CPU core number\n"
  append msg "\t     -grid        	: run on grid if given\n"
  append msg "\t     -icv_version   	: ICV tool version  if specific one is needed\n"
  append msg "\t     -mem 	   	: booked memory size in Gb\n"
  append msg "Contact info: Sergey Chatrchyan (sergeych)"
  puts $msg
  return $msg
}

proc process_cmdline {} {

  set parameters {
    {verbosity.arg  	"0"    		"verbosity"}
    {v.arg          	"0"    		"verbosity"}
    {debug.arg      	"0"    		"debug"}
    {d.arg          	"0"    		"debug"}
    {h                     			"help message"}
    {fab_node.arg           		"TSMC advanced node tsmc05 or tsmc03"}
    {bot_metal.arg  	"1"    		"bottom_metal"}
    {cell.arg       	""     		"top-cell name"}
    {cores.arg      	"1"  	  	"number of CPU cores"}
    {edtext.arg     	"" 		"input File with label coordinates"}
    {layout.arg     	"" 		"input GDS/OASIS file"}
    {layout_format.arg	"OAS"		"OAS/GDS"}
    {grid                  			"run on grid if defined"}
    {icv_version.arg        "" 		"ICV tool version"}
    {layermap.arg           "" 		"path to streamout.layermap file"}
    {mem.arg        	"50G"  		"memory requested"}
    {nets.arg               "VAA VDD VDDQ VDDQLP VSS"		"tracing net names"}
    {text_depth.arg 	"0"    		"hierarchy level for net names"}
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
  global opt_help
  global fab_node
  global bot_metal
  global cell
  global cores
  global edtext
  global layout
  global layout_format
  global grid
  global icv_version
  global layermap
  global mem
  global nets
  global text_depth

  set VERBOSITY [get_max_val $options(verbosity) $options(v)]
  set DEBUG [get_max_val $options(debug) $options(d)]

  set opt_help    	$options(h)
  set fab_node    	$options(fab_node)
  set bot_metal    	$options(bot_metal)
  set cell    	$options(cell)
  set cores    	$options(cores)
  set edtext    	$options(edtext)
  set layout    	$options(layout)
  set layout_format	$options(layout_format)
  set grid    	$options(grid)
  set icv_version    	$options(icv_version)
  set layermap    	$options(layermap)
  set mem    		$options(mem)
  set nets    	$options(nets)
  set text_depth    	$options(text_depth)

  dprint 1 "debug value     : $DEBUG"
  dprint 1 "verbosity value : $VERBOSITY"
  dprint 1 "help value      : $opt_help"
  dprint 1 "fab_node        : $fab_node"
  dprint 1 "bot_metal       : $bot_metal"
  dprint 1 "cell            : $cell"
  dprint 1 "cores           : $cores"
  dprint 1 "edtext          : $edtext"
  dprint 1 "grid            : $grid"
  dprint 1 "icv_version     : $icv_version"
  dprint 1 "layermap        : $layermap"
  dprint 1 "mem             : $mem"
  dprint 1 "nets            : $nets"
  dprint 1 "text_depth      : $text_depth"

  if { $opt_help } {
    showUsage
    myexit 0
  }

  return true
}

proc Main {} {
  global PROGRAM_NAME
  global RealBin
  global opt_help
  global fab_node
  global bot_metal
  global cell
  global cores
  global edtext
  global layout
  global layout_format
  global grid
  global icv_version
  global layermap
  global mem
  global nets
  global text_depth
  process_cmdline

  # Process arguments and set variables/
  set script_name $PROGRAM_NAME
  set runset_name "net_tracer"
  set connectivity_name "ConnectivityUp"
  set grouping_name "LayerGrouping"
  set groupLabel "LABEL"
  set groupTop "TOP"
  set groupMimcap "MIMCAP"
  set groupMetRes "METALRES"
  # Colors  	        blue 	    green	orange	   magenta       cian	    l.blue      l.green	     blue        green	    orange	magenta       cian	  l.blue      l.green     brown     l.yellow     cinnamon      rose  	    red        yellow       grey       beje
  set colorScheme {"#FF0000AA" "#FF00FFBB" "#FFFF99CC" "#FFDD5555" "#FFFF00DD"  "#FF99FFEE" "#FF009977" "#FFAADDBB" "#FF0000FF" "#FF00FF00" "#FFFF9900" "#FFFF00FF"  "#FF99FFFF" "#FF0099FF" "#FFAADD55" "#FF0000FF" "#FF00FF00" "#FFFF9900" "#FFFF00FF"  "#FF99FFFF" "#FF0099FF" "#FFAADD55" "#FFAA5555" "#FFFFFF99" "#FF999900" "#FF990099" "#FFFF0000" "#FFFFFF00" "#FF999999" "#FFDDDDAA"}
  set colorPattern {"empty" "solid" "mesh12" "diamond" "fill37"}
  if {$cell == ""} {
    fatal_error "Top Cell name is not provided!"
  }
  if { ![file exists $layout]} {
    fatal_error "Layout file is not provided!"
  } else {
    set layout $layout
    ## Get extention and assign to layout format
    if  { [string match -nocase "*oas*" $layout]} {
      set layFormat "OASIS"
    } elseif { [string match -nocase "*gds*" $layout]} {
      set layFormat "GDSII"
    } else {
      fatal_error "Layout format is not recognized/specified!"
    }
  }
  ## This If block is kept for a backward compatibility
  if {(![info exists layout_format]) || ($layout_format == "GDS")} {
    set layout_format "GDSII"
  } elseif {$layout_format == "OAS"} {
    set layout_format "OASIS"
  } else {
    set layout_format $layFormat
  }
  set layout_format $layFormat
  if {[info exists grid]} {
    set grid "qsub -P bnormal -A quick -pe mt $cores -l mem_free=${mem},h_vmem=$mem -cwd -V"
  } else {
    set grid ""
  }
  if { $icv_version != ""} {
    set icv_version "/$icv_version"
  } else {
    set icv_version ""
  }
  if {![info exists fab_node]} {
    set fab_node "GENERIC"
  } elseif { [string match -nocase "tsmc05*" $fab_node] || [string match  -nocase "tsmc03*" $fab_node] } {
    set fab_node "TS5LIKE"
    iprint " TSMC advanced node MAP STYLE is used!"
  } else {
    set fab_node "GENERIC"
  }
  set top_metal $bot_metal
  # Parse layermap for layout database layers and datatypes.
  if {![file exists $layermap]} {
    if { [file exists "./stream.layermap"] } {
      set layermap ./stream.layermap
    } else {
      fatal_error "Layermap is not provided!"
    }
  }
  # Grab metal information from streamout.layermap file
  set fmap [read_file $layermap]
  set stream [split $fmap "\n"]
  foreach line $stream {
    if {[regexp {^M(\d+)(_WIDE)?\s+(dpl1|dpl2|dpl3|dpl4|drawing)\s+(\d+)\s+(\d+)} $line match metal name_ext purpose layer datatype]} {
      if {$metal > $top_metal} {
        set top_metal $metal
      }
      lappend m${metal} $layer
      lappend m${metal} $datatype
      continue
    }
    if {[regexp {^VIA(\d+)(_DPL1|_DPL2)?\s+(bar|bar_dpl1|bar_dpl2|bar_dpl3|bar_dpl4|dpl1|dpl2|dpl3|dpl4|drawing|large|large_dpl1|large_dpl2|large_dpl3)\s+(\d+)\s+(\d+)} $line match via name_ext purpose layer datatype]} {
      lappend v${via} $layer
      lappend v${via} $datatype
      continue
    }
    if {$fab_node == "TS5LIKE" } {
      if {[regexp {^RMDMY\s+m(\d+)\s+(\d+)\s+(\d+)} $line match metal layer datatype]} {
        lappend m${metal}_res $layer
        lappend m${metal}_res $datatype
        continue
      }
      if {[regexp {^M(\d+)\s+pin\s+(\d+)\s+(\d+)} $line match metal layer datatype]} {
        lappend m${metal}_txt $layer
        lappend m${metal}_txt $datatype
        continue
      }
      if {[regexp {^RV\s+(bar|drawing)\s+(\d+)\s+(\d+)} $line match purpose layer datatype]} {
        lappend rdlvia $layer
        lappend rdlvia $datatype
        continue
      }
      if {[regexp {^AP\s+(drawing)\s+(\d+)\s+(\d+)} $line match purpose layer datatype]} {
        lappend rdl $layer
        lappend rdl $datatype
        continue
      }
      if {[regexp {^AP\s+pin\s+(\d+)\s+(\d+)} $line match layer datatype]} {
        lappend rdl_txt $layer
        lappend rdl_txt $datatype
        continue
      }
    } else {
      if {[regexp {^M(\d+)RES\s+lvs\s+(\d+)\s+(\d+)} $line match metal layer datatype]} {
        lappend m${metal}_res $layer
        lappend m${metal}_res $datatype
        continue
      }
      if {[regexp {^M(\d+)\s+label\s+(\d+)\s+(\d+)} $line match metal layer datatype]} {
        lappend m${metal}_txt $layer
        lappend m${metal}_txt $datatype
        continue
      }
      if {[regexp {^RDLVIA\s+(bar|drawing)\s+(\d+)\s+(\d+)} $line match purpose layer datatype]} {
        lappend rdlvia $layer
        lappend rdlvia $datatype
        continue
      }
      if {[regexp {^RDL\s+(drawing)\s+(\d+)\s+(\d+)} $line match purpose layer datatype]} {
        lappend rdl $layer
        lappend rdl $datatype
        continue
      }
      if {[regexp {^RDL\s+label\s+(\d+)\s+(\d+)} $line match layer datatype]} {
        lappend rdl_txt $layer
        lappend rdl_txt $datatype
        continue
      }
    }
  }
  # Create working directory and change to it.
  file mkdir  $cell/$runset_name
  set  icvRunSet [file join $cell $runset_name ${runset_name}.rs ]
  iprint "$cell file is running"
  write_file ./$icvRunSet "#include <icv.rh>" w
  # Increase error limit and flatten violations.
  write_file ./$icvRunSet "error_options(error_limit_per_check = ERROR_LIMIT_MAX, flatten_violations = {\"*\"});" a+
  # Set text_options and add edtext file.
  write_file ./$icvRunSet "text_options(" a+
  if {[file exists $edtext]} {
    set edTextFile $edtext
    set f_edtext [read_file $edTextFile]
    write_file ./$icvRunSet "\tedtext = {$f_edtext\t}," a+
  }
  write_file ./$icvRunSet  "\ttext_depth = $text_depth" a+
  write_file ./$icvRunSet   ");"  a+
  # Special handling for square brackets in ICV.
  regsub -all {\[} $nets {\\\\\\\[} nets
  regsub -all {\]} $nets {\\\\\\\]} nets
  set nets_formatted ""
  foreach net $nets {
    set nets_formatted "$nets_formatted \"$net\","
  }
  write_file ./$icvRunSet "trace_nets : list of string = {${nets_formatted}};" a+
  # Set layer assignments.
  for {set j $bot_metal} {($j >= $bot_metal) && ($j <= ($top_metal - 1))} {incr j} {
    set mCon$j ""
    write_file ./$icvRunSet "m${j} = assign(\n\tldt_list = {" a+
    for {set i 0} {$i < [llength [set m${j}]]} {set i [expr $i + 2]} {
      write_file ./$icvRunSet "\t\t{layer_num_range = [lindex [set m${j}] $i], data_type_range = [lindex [set m${j}] [expr $i + 1]]}," a+
      set temp "[lindex [set m${j}] $i]:[lindex [set m${j}] [expr $i + 1]] "
      if { [string match *$temp*  [set mCon$j ] ] } {
        continue
      } else  {
        append mCon$j  "[lindex [set m${j}] $i]:[lindex [set m${j}] [expr $i + 1]]"
      }
    }
    write_file ./$icvRunSet "\t}\n);"  a+
    write_file ./$icvRunSet "m${j}_res = assign(\n\tldt_list = {" a+
    for {set i 0} {$i < [llength [set m${j}_res]]} {set i [expr $i + 2]} {
      write_file ./$icvRunSet "\t\t{layer_num_range = [lindex [set m${j}_res] $i], data_type_range = [lindex [set m${j}_res] [expr $i + 1]]}," a+
    }
    write_file ./$icvRunSet "\t}\n);" a+
    write_file ./$icvRunSet "m${j}_txt = assign_text(\n\tldt_list = {" a+
    for {set i 0} {$i < [llength [set m${j}_txt]]} {set i [expr $i + 2]} {
      write_file ./$icvRunSet "\t\t{layer_num_range = [lindex [set m${j}_txt] $i], data_type_range = [lindex [set m${j}_txt] [expr $i + 1]]}," a+
    }
    write_file ./$icvRunSet "\t}\n);" a+
    set vCon$j ""
    if { $fab_node == "TS5LIKE" } {
      write_file ./$icvRunSet "v${j} = assign(\n\tldt_list = {" a+
      for {set i 0} {$i < [llength [set v${j}]]} {set i [expr $i + 2]} {
        write_file ./$icvRunSet "\t\t{layer_num_range = [lindex [set v${j}] $i], data_type_range = [lindex [set v${j}] [expr $i + 1]]}," a+
        set temp "[lindex [set v${j}] $i]:[lindex [set v${j}] [expr $i + 1]] "
        if { [string match *$temp*  [set vCon$j]] } {
          continue
        } else  {
          append vCon${j} $temp
        }
      }
      write_file ./$icvRunSet "\t}\n);" a+
    } else {
      write_file ./$icvRunSet "v${j} = assign(\n\tldt_list = {" a+
      for {set i 0} {$i < [llength [set v${j}[expr $j + 1]]]} {set i [expr $i + 2]} {
        write_file ./$icvRunSet "\t\t{layer_num_range = [lindex [set v${j}[expr $j + 1]] $i], data_type_range = [lindex [set v${j}[expr $j + 1]] [expr $i + 1]]}," a+
        set temp "[lindex [set v${j}[expr $j + 1]] $i]:[lindex [set v${j}[expr $j + 1]] [expr $i + 1]] "
        if { [string match *$temp*  [set vCon$j ] ] } {
          continue
        } else  {
          append vCon${j} $temp
        }
      }
      write_file ./$icvRunSet "\t}\n);" a+
    }
  }
  write_file ./$icvRunSet "m${top_metal} = assign(\n\tldt_list = {" a+
  set mCon${top_metal} ""
  for {set i 0} {$i < [llength [set m${top_metal}]]} {set i [expr $i + 2]} {
    write_file ./$icvRunSet "\t\t{layer_num_range = [lindex [set m${top_metal}] $i], data_type_range = [lindex [set m${top_metal}] [expr $i + 1]]}," a+
    set temp "[lindex [set m${top_metal}] $i]:[lindex [set m${top_metal}] [expr $i + 1]] "
    if { [string match *$temp*  [set mCon${top_metal} ] ] } {
      continue
    } else  {
      append mCon${top_metal} $temp
    }
  }
  write_file ./$icvRunSet "\t}\n);" a+
  write_file ./$icvRunSet "m${top_metal}_res = assign(\n\tldt_list = {" a+
  for {set i 0} {$i < [llength [set m${top_metal}_res]]} {set i [expr $i + 2]} {
    write_file ./$icvRunSet "\t\t{layer_num_range = [lindex [set m${top_metal}_res] $i], data_type_range = [lindex [set m${top_metal}_res] [expr $i + 1]]}," a+
  }
  write_file ./$icvRunSet "\t}\n);" a+
  write_file ./$icvRunSet "m${top_metal}_txt = assign_text(\n\tldt_list = {" a+
  for {set i 0} {$i < [llength [set m${top_metal}_txt]]} {set i [expr $i + 2]} {
    write_file ./$icvRunSet "\t\t{layer_num_range = [lindex [set m${top_metal}_txt] $i], data_type_range = [lindex [set m${top_metal}_txt] [expr $i + 1]]}," a+
  }
  write_file ./$icvRunSet "\t}\n);" a+
  write_file ./$icvRunSet "rdlvia = assign(\n\tldt_list = {" a+
  set rdlViaCon ""
  for {set i 0} {$i < [llength $rdlvia]} {set i [expr $i + 2]} {
    write_file ./$icvRunSet "\t\t{layer_num_range = [lindex $rdlvia $i], data_type_range = [lindex $rdlvia [expr $i + 1]]}," a+
    set temp "[lindex $rdlvia $i]:[lindex $rdlvia [expr $i + 1]] "
    if { [string match *$temp*  rdlViaCon ] } {
      continue
    } else  {
      append rdlViaCon $temp
    }
  }
  write_file ./$icvRunSet "\t}\n);" a+
  write_file ./$icvRunSet "rdl = assign(\n\tldt_list = {" a+
  set rdlCon ""
  for {set i 0} {$i < [llength $rdl]} {set i [expr $i + 2]} {
    write_file ./$icvRunSet "\t\t{layer_num_range = [lindex $rdl $i], data_type_range = [lindex $rdl [expr $i + 1]]}," a+
    set temp "[lindex $rdl $i]:[lindex $rdl [expr $i + 1]] "
    if { [string match *$temp*  rdlCon ] } {
      continue
    } else  {
      append rdlCon $temp
    }
  }
  write_file ./$icvRunSet "\t}\n);" a+
  write_file ./$icvRunSet "rdl_txt = assign_text(\n\tldt_list = {" a+
  for {set i 0} {$i < [llength $rdl_txt]} {set i [expr $i + 2]} {
    write_file ./$icvRunSet "\t\t{layer_num_range = [lindex $rdl_txt $i], data_type_range = [lindex $rdl_txt [expr $i + 1]]}," a+
  }
  write_file ./$icvRunSet "\t}\n);" a+
  # Cut metal shapes by metal Resistors
  for {set j $bot_metal} {($j >= $bot_metal) && ($j <= $top_metal )} {incr j} {
    write_file ./$icvRunSet "m${j} = not ( m${j} , m${j}_res);"  a+
  }
  # Connect layers.
  write_file ./$icvRunSet "cdb = connect(\n\tconnect_items = {" a+
  for {set i $bot_metal} {($i >= $bot_metal) && ($i <= ($top_metal - 1))} {incr i} {
    write_file ./$icvRunSet "\t\t{layers = {m${i}, m[expr $i + 1]}, by_layer = v${i}}," a+
  }
  write_file ./$icvRunSet "\t\t{layers = {m${top_metal}, rdl}, by_layer = rdlvia}" a+
  write_file ./$icvRunSet "\t}\n);" a+
  # Label nets.
  write_file ./$icvRunSet "cdb = text_net(\n\tconnect_sequence = cdb,\n\ttext_layer_items = {" a+
  for {set i $bot_metal} {($i >= $bot_metal) && ($i <= $top_metal)} {incr i} {
    write_file ./$icvRunSet "\t\t{layer = m${i}, text_layer = m${i}_txt}," a+
  }
  write_file ./$icvRunSet "\t\t{layer = rdl, text_layer = rdl_txt}" a+
  write_file ./$icvRunSet "\t},\n\tuse_text = TOP," a+
  write_file ./$icvRunSet "\tattach_text = ALL\n);" a+
  ## Create a layer grouping file
  set fgrp "${grouping_name}.tcl"
  write_file ./$fgrp "layer import  $layermap  -mode configured" w
  write_file ./$fgrp  "layer group new $groupLabel" a+
  write_file ./$fgrp  "layer group new $groupTop"  a+
  write_file ./$fgrp  "layer group new $groupMetRes"  a+
  write_file ./$fgrp  "layer group new $groupMimcap"  a+
  set k 0
  foreach line $stream {
    incr k
    if { $k >= [llength $colorScheme] } {
      set k 0
    }
    if {[regexp {^(prBoundary)\s+(boundary)\s+(\d+)\s+(\d+).*} $line match pr purpose layer datatype] || [regexp {^(BOUNDARY)\s+(placement)\s+(\d+)\s+(\d+).*} $line match pr purpose layer datatype] } {
      write_file ./$fgrp "layer group move $groupLabel \{$layer:$datatype\}" a+
      write_file ./$fgrp "layer configure $layer:$datatype -name $pr:$purpose -fill [lindex $colorScheme 11] -pattern [lindex $colorPattern 0] -outline [lindex $colorScheme 11] -lineStyle solid" a+
      continue
    }
    if {[regexp {^(ESDHBM)\s+(drc)\s+(\d+)\s+(\d+).*} $line match diode purpose layer datatype] || [regexp {^(DIODE)\s+(lvs)\s+(\d+)\s+(\d+).*} $line match diode purpose layer datatype] || [regexp {^(HIA)\s+(lvs)\s+(\d+)\s+(\d+).*} $line match diode purpose layer datatype] } {
      write_file ./$fgrp "layer group move $groupLabel \{$layer:$datatype\} " a+
      write_file ./$fgrp "layer configure $layer:$datatype -name $diode:$purpose -fill [lindex $colorScheme 12] -pattern [lindex $colorPattern 3] -outline [lindex $colorScheme 12] -lineStyle solid" a+
      continue
    }
    if {[regexp {^MIMEXCL\s+(drawing)\s+(\d+)\s+(\d+)} $line match purpose layer datatype]} {
      write_file ./$fgrp "layer group move $groupMimcap \{$layer:$datatype\}" a+
      write_file ./$fgrp "layer configure $layer:$datatype -name MIMEXCL:$purpose -fill [lindex $colorScheme $k] -pattern [lindex $colorPattern 4] -outline [lindex $colorScheme $k] -lineStyle solid" a+
      continue
    }
    if {[regexp {^DMIMEXCL\s+(drawing)\s+(\d+)\s+(\d+)} $line match purpose layer datatype]} {
      write_file ./$fgrp "layer group move $groupMimcap \{$layer:$datatype\}" a+
      write_file ./$fgrp "layer configure $layer:$datatype -name DMIMEXCL:$purpose -fill [lindex $colorScheme $k] -pattern [lindex $colorPattern 4] -outline [lindex $colorScheme $k] -lineStyle solid" a+
      continue
    }
    if {[regexp {^(MIMTOP\S*)\s+(drawing|marker|dummy|keepout)\s+(\d+)\s+(\d+)} $line match name purpose layer datatype]} {
      write_file ./$fgrp "layer group move $groupMimcap \{$layer:$datatype\}" a+
      write_file ./$fgrp "layer configure $layer:$datatype -name $name:$purpose -fill [lindex $colorScheme $k] -pattern [lindex $colorPattern 4] -outline [lindex $colorScheme $k] -lineStyle solid" a+
      continue
    }
    if {[regexp {^(MIMBOT\S*)\s+(drawing|marker|dummy|keepout)\s+(\d+)\s+(\d+)} $line match name purpose layer datatype]} {
      write_file ./$fgrp "layer group move $groupMimcap \{$layer:$datatype\}" a+
      write_file ./$fgrp "layer configure $layer:$datatype -name $name:$purpose -fill [lindex $colorScheme $k] -pattern [lindex $colorPattern 4] -outline [lindex $colorScheme $k] -lineStyle solid" a+
      continue
    }
    if {[regexp {^(TPC\S*)\s+(drawing|marker|dummy)\s+(\d+)\s+(\d+)} $line match name purpose layer datatype]} {
      write_file ./$fgrp "layer group move $groupMimcap \{$layer:$datatype\}" a+
      write_file ./$fgrp "layer configure $layer:$datatype -name $name:$purpose -fill [lindex $colorScheme $k] -pattern [lindex $colorPattern 4] -outline [lindex $colorScheme $k] -lineStyle solid" a+
      continue
    }
    if {[regexp {^(MPC\S*)\s+(drawing|marker|dummy)\s+(\d+)\s+(\d+)} $line match name purpose layer datatype]} {
      write_file ./$fgrp "layer group move $groupMimcap \{$layer:$datatype\}" a+
      write_file ./$fgrp "layer configure $layer:$datatype -name $name:$purpose -fill [lindex $colorScheme $k] -pattern [lindex $colorPattern 4] -outline [lindex $colorScheme $k] -lineStyle solid" a+
      continue
    }
    if {[regexp {^(BPC\S*)\s+(drawing|marker|dummy)\s+(\d+)\s+(\d+)} $line match name purpose layer datatype]} {
      write_file ./$fgrp "layer group move $groupMimcap \{$layer:$datatype\}" a+
      write_file ./$fgrp "layer configure $layer:$datatype -name $name:$purpose -fill [lindex $colorScheme $k] -pattern [lindex $colorPattern 4] -outline [lindex $colorScheme $k] -lineStyle solid" a+
      continue
    }
    if {[regexp {^M(\d+)(_WIDE)?\s+(drawing)\s+(\d+)\s+(\d+)} $line match metal name_ext purpose layer datatype]} {
      if {$metal >= $bot_metal} {
        write_file ./$fgrp "layer group move $groupTop \{$layer:$datatype\} " a+
        if { "${metal}" == "[expr ${top_metal} - 1]" } {
          write_file ./$fgrp "layer configure $layer:$datatype -name M$metal|MTOP-1:drawing -fill [lindex $colorScheme [expr $metal - $bot_metal]] -pattern [lindex $colorPattern 2] -outline [lindex $colorScheme [expr $metal - $bot_metal]] -lineStyle solid" a+
        } elseif { "${metal}" == "${top_metal}" } {
          write_file ./$fgrp "layer configure $layer:$datatype -name M$metal|MTOP:drawing -fill [lindex $colorScheme [expr $metal - $bot_metal]] -pattern [lindex $colorPattern 2] -outline [lindex $colorScheme [expr $metal - $bot_metal]] -lineStyle solid" a+
        } else {
          write_file ./$fgrp "layer configure $layer:$datatype -name M$metal:drawing -fill [lindex $colorScheme [expr $metal - $bot_metal]] -pattern [lindex $colorPattern 2] -outline [lindex $colorScheme [expr $metal - $bot_metal]] -lineStyle solid" a+
        }
      }
      continue
    }
    if {$fab_node == "TS5LIKE" } {
      if {[regexp {^VIA(\d+)(_DPL1|_DPL2)?\s+(drawing)\s+(\d+)\s+(\d+)} $line match via name_ext purpose layer datatype]} {
        if { $via >= "[expr $bot_metal + 1]" } {
          write_file ./$fgrp "layer group move $groupTop \{$layer:$datatype\} " a+
          if { $via == "[expr $top_metal - 1]" } {
            write_file ./$fgrp "layer configure $layer:$datatype -name VIA${via}|VIATOP:drawing -fill [lindex $colorScheme $k] -pattern [lindex $colorPattern 1] -outline [lindex $colorScheme $k] -lineStyle solid" a+
          } elseif { $via == "[expr $top_metal - 2]" } {
            write_file ./$fgrp "layer configure $layer:$datatype -name VIA${via}|VIATOP-1:drawing -fill [lindex $colorScheme $k] -pattern [lindex $colorPattern 1] -outline [lindex $colorScheme $k] -lineStyle solid" a+
          } else {
            write_file ./$fgrp "layer configure $layer:$datatype -name VIA${via}:drawing -fill [lindex $colorScheme $k] -pattern [lindex $colorPattern 1] -outline [lindex $colorScheme $k] -lineStyle solid" a+
          }
        }
        continue
      }
      if {[regexp {^RMDMY\s+m(\d+)\s+(\d+)\s+(\d+)} $line match metal layer datatype]} {
        if {$metal >= $bot_metal} {
          write_file ./$fgrp "layer group move $groupMetRes \{$layer:$datatype\}" a+
          write_file ./$fgrp "layer configure $layer:$datatype -name RMDMY:m$metal -fill [lindex $colorScheme [expr $metal - $bot_metal]] -pattern [lindex $colorPattern 3] -outline [lindex $colorScheme [expr $metal - $bot_metal]] -lineStyle solid" a+
        }
        continue
      }
    } else {
      if {[regexp {^VIA(\d+)(_DPL1|_DPL2)?\s+(drawing)\s+(\d+)\s+(\d+)} $line match via name_ext purpose layer datatype]} {
        if { $via >= "$bot_metal[expr $bot_metal + 1]" } {
          write_file ./$fgrp "layer group move $groupTop \{$layer:$datatype\} " a+
          if { $via == "[expr $top_metal - 1]$top_metal" } {
            write_file ./$fgrp "layer configure $layer:$datatype -name VIA${via}|VIATOP:drawing -fill [lindex $colorScheme $k] -pattern [lindex $colorPattern 1] -outline [lindex $colorScheme $k] -lineStyle solid" a+
          } elseif { $via == "[expr $top_metal - 2][expr $top_metal - 1]" } {
            write_file ./$fgrp "layer configure $layer:$datatype -name VIA${via}|VIATOP-1:drawing -fill [lindex $colorScheme $k] -pattern [lindex $colorPattern 1] -outline [lindex $colorScheme $k] -lineStyle solid" a+
          } else {
            write_file ./$fgrp "layer configure $layer:$datatype -name VIA${via}:drawing -fill [lindex $colorScheme $k] -pattern [lindex $colorPattern 1] -outline [lindex $colorScheme $k] -lineStyle solid" a+
          }
        }
        continue
      }
      if {[regexp {^M(\d+)RES\s+(lvs)\s+(\d+)\s+(\d+)} $line match metal purpose layer datatype]} {
        if {$metal >= $bot_metal} {
          write_file ./$fgrp "layer group move $groupMetRes \{$layer:$datatype\}" a+
          write_file ./$fgrp "layer configure $layer:$datatype -name M${metal}RES:$purpose -fill [lindex $colorScheme [expr $metal - $bot_metal]] -pattern [lindex $colorPattern 3] -outline [lindex $colorScheme [expr $metal - $bot_metal]] -lineStyle solid" a+
        }
        continue
      }
    }
  }
  ## Create a connectivity file
  set fcon "${connectivity_name}.tcl"
  write_file ./$fcon  "layout connectivity \{ \\" w
  # Output nets.
  write_file ./$icvRunSet "foreach(trace_net in trace_nets)\{" a+
  for {set i $bot_metal} {($i >= $bot_metal) && ($i <= $top_metal)} {incr i} {
    write_file ./$icvRunSet "\t\{ @ trace_net + \"_M${i}\";\n\t\tnet_texted_with(connect_sequence = cdb, text = \{trace_net\}, output_from_layers = {m${i}});\n\t \}" a+
    write_file ./$fcon  "M${i} \{ [set mCon$i] \} \\" a+
    write_file ./$fgrp "layer group move $groupLabel \{[lindex [set m${i}_txt] 0]:[lindex [set m${i}_txt] 1]\} " a+
    write_file ./$fgrp "layer configure  [lindex [set m${i}_txt] 0]:[lindex [set m${i}_txt] 1] -name M$i:label|pin -fill [lindex $colorScheme $i] -pattern [lindex $colorPattern 0] -outline [lindex $colorScheme $i] -lineStyle solid" a+
    if {($i < $top_metal)} {
      write_file ./$fcon "VIA${i}[expr ${i} + 1] \{ [set vCon$i] \} \\" a+
    }
  }
  write_file ./$icvRunSet "\t \{ @ trace_net + \"_RDL\";\n\t\tnet_texted_with(connect_sequence = cdb, text = \{trace_net\}, output_from_layers = {rdl});\n\t \}" a+
  write_file ./$icvRunSet "\};" a+
  write_file ./$fcon "RDLVIA \{ [set rdlViaCon] \} \\" a+
  write_file ./$fgrp "layer group move $groupTop \{[set rdlViaCon]\} " a+
  write_file ./$fgrp "layer configure [set rdlViaCon] -name RDLVIA:drawing -fill [lindex $colorScheme 14] -pattern [lindex $colorPattern 1] -outline [lindex $colorScheme 14] -lineStyle solid" a+
  write_file ./$fcon "RDL \{ [set rdlCon] \} \\" a+
  write_file ./$fgrp "layer group move $groupTop \{[set rdlCon]\} " a+
  write_file ./$fgrp "layer configure [set rdlCon] -name PAD:drawing -fill [lindex $colorScheme 13] -pattern [lindex $colorPattern 2] -outline [lindex $colorScheme 13] -lineStyle solid" a+
  write_file ./$fgrp "layer group move $groupLabel \{[lindex $rdl_txt 0]:[lindex $rdl_txt 1] \} " a+
  write_file ./$fgrp "layer configure [lindex $rdl_txt 0]:[lindex $rdl_txt 1] -name PAD:label|pin -fill [lindex $colorScheme 13] -pattern [lindex $colorPattern 0] -outline [lindex $colorScheme 13] -lineStyle solid" a+
  write_file ./$fcon "\}" a+

  # Run net_tracer runset.
  set fid [file join $cell $runset_name ${runset_name}.tcsh ]
  write_file ./$fid  "#!/bin/tcsh" w
  write_file ./$fid "module unload icv; module load icv${icv_version}" a+
  write_file ./$fid "icv -norscache -host_init $cores -c $cell -f $layout_format -i ../../$layout -vue -vueshort ${runset_name}.rs" a+
  file attributes $fid -permissions +x
  cd $cell/$runset_name
  set cmd [list bash -c "source ~/.bashrc;  $grid ./${runset_name}.tcsh"]
  run_system_cmd $cmd 2
  cd ../../

  return 0
}


try {
  header
  set exitval [Main]
} on error {results options} {
  set exitval [fprint [dict get $options -errorinfo]]
} finally {
  footer
  write_stdout_log $LOGFILE
}
myexit $exitval

# nolint utils__script_usage_statistics