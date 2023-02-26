#!/usr/local/bin/tclsh

# Revision history.
# 20200408 - Added "use_text = TOP" to text_net function to avoid lower level text, possibly of a different name, to be assigned to a net.
# 20191025 - Enhanced to provide a text_depth switch to trace texts from a lower level of hierarchy.
# 20191018 - Enhanced to allow top level texts to attach to polygons at lower levels of hierarchy.
# 20190802 - Changed grid queue from normal to quick.
# 20190310 - Added -vueshort to ICV call.
# 20181030 - Added support for OASIS layout databases.
# 20181024 - GDS and edtext files can now be specified with relative paths.

# Prints usage info and exits script.
proc printHelp {} {
  global script_name
  puts "***** Script to trace nets in a layout database based on their netname. Nets can be labeled in the layout database or provided in an edtext file."
  puts "\n***** Usage: ${script_name}.tcl -layout <GDS/OAS file> -cell <cellname> -layermap <layermap file> \[-layout_format <GDS|OAS>\] \[-bot_metal <lowest metal number to include for connectivity>\] \[-nets \"<net1> <net2> ...\"\] \[-edtext <edtext file>\]"
  puts "*****   \[-text_depth <depth, where 0 is top>\] \[-icv_version <version>\] \[-grid\] \[-cores <cores>\] \[-mem <memory>\]"
  puts "\n***** Contact info: Manmit Muker (mmuker)"
  exit
}

# Process arguments and set variables.
set script_name exec_net_tracer
set runset_name net_tracer
if { $argc == 0 } {
  printHelp
}
set i 0
while {$i < $argc} {
  switch -- [lindex $argv $i] {
    -bot_metal            { incr i; set bot_metal [lindex $argv $i]; incr i }
    -cell                 { incr i; set cell [lindex $argv $i]; incr i }
    -cores                { incr i; set cores [lindex $argv $i]; incr i }
    -edtext               { incr i; set edtext [lindex $argv $i]; incr i }
    -layout               { incr i; set layout [lindex $argv $i]; incr i }
    -layout_format        { incr i; set layout_format [lindex $argv $i]; incr i }
    -grid                 { set grid 1; incr i }
    -icv_version          { incr i; set icv_version [lindex $argv $i]; incr i }
    -layermap             { incr i; set layermap [lindex $argv $i]; incr i }
    -mem                  { incr i; set mem [lindex $argv $i]; incr i }
    -nets                 { incr i; set nets [lindex $argv $i]; incr i }
    -text_depth           { incr i; set text_depth [lindex $argv $i]; incr i }
    default               { puts "***** Error: Illegal argument: [lindex $argv $i]."; printHelp }
  }
}
if {![info exists bot_metal]} {
  set bot_metal 1
}
if {![info exists cell]} {
  puts "***** Error: No cellname provided."
  printHelp
}
if {![info exists cores]} {
  set cores 1
}
if {![info exists layout]} {
  puts "***** Error: No layout database file provided."
  printHelp
} else {
  set layout [file join .. .. $layout]
}
if {(![info exists layout_format]) || ($layout_format == "GDS")} {
  set layout_format "GDSII"
} elseif {$layout_format == "OAS"} {
  set layout_format "OASIS"
} else {
  puts "***** Error: Invalid layout database format specified."
  printHelp
}
if {![info exists mem]} {
  set mem 50G
}
if {[info exists grid]} {
  set grid "qsub -P bnormal -A quick -pe mt $cores -l mem_free=${mem},h_vmem=$mem -cwd -V"
} else {
  set grid ""
}
if {[info exists icv_version]} {
  set icv_version "/$icv_version"
} else {
  set icv_version ""
}
if {![info exists layermap]} {
  puts "***** Error: No layermap provided."
  printHelp
}
if {![info exists nets]} {
  set nets "VAA VDD VDDQ VDDQLP VSS"
}
if {![info exists text_depth]} {
  set text_depth 0
}

# Parse layermap for layout database layers and datatypes.
set top_metal $bot_metal
if {[catch {open $layermap} fid]} {
  puts "***** $fid"
  exit
}
while {[gets $fid line] >= 0} {
  if {[regexp {^M(\d+)(_WIDE)?\s+(cddummy|dpl1|dpl2|dpl3|dpl4|drawing|dummy|dummy_dpl1|dummy_dpl1opc|dummy_dpl2|dummy_dpl2opc|dummy_dpl3|dummy_dpl3opc|dummy_dpl4|dummy_dpl4opc|fillOPC)\s+(\d+)\s+(\d+)} $line match metal name_ext purpose layer datatype]} {
    if {$metal > $top_metal} {
      set top_metal $metal
    }
    lappend m${metal} $layer
    lappend m${metal} $datatype
    continue
  }
  if {[regexp {^M(\d+)\s+label\s+(\d+)\s+(\d+)} $line match metal layer datatype]} {
    lappend m${metal}_txt $layer
    lappend m${metal}_txt $datatype
    continue
  }
  if {[regexp {^VIA(\d+)(_DPL1|_DPL2)?\s+(bar|bar_dpl1|bar_dpl2|bar_dpl3|bar_dpl4|cddummy|dpl1|dpl2|dpl3|dpl4|drawing|dummy|dummy_dpl1|dummy_dpl1opc|dummy_dpl2|dummy_dpl2opc|dummy_dpl3|dummy_dpl3opc|dummy_dpl4|dummy_dpl4opc|fillOPC|large|large_dpl1|large_dpl2|large_dpl3)\s+(\d+)\s+(\d+)} $line match via name_ext purpose layer datatype]} {
    lappend v${via} $layer
    lappend v${via} $datatype
    continue
  }
  if {[regexp {^RDLVIA\s+(bar|drawing)\s+(\d+)\s+(\d+)} $line match purpose layer datatype]} {
    lappend rdlvia $layer
    lappend rdlvia $datatype
    continue
  }
  if {[regexp {^RDL\s+(drawing|dummy|fillOPC)\s+(\d+)\s+(\d+)} $line match purpose layer datatype]} {
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
close $fid

# Create working directory and change to it.
file mkdir $cell
cd $cell
file mkdir $runset_name
cd $runset_name

# Create runset.
if {[catch {open ${runset_name}.rs w} fid]} {
  puts "***** $fid"
  exit
}
puts $fid "#include <icv.rh>"
# Increase error limit and flatten violations.
puts $fid "error_options(error_limit_per_check = ERROR_LIMIT_MAX, flatten_violations = {\"*\"});"
# Set text_options and add edtext file.
puts $fid "text_options("
if {[info exists edtext]} {
  set edtext [file join .. .. $edtext]
  if {[catch {open $edtext } f_edtext]} {
    puts "***** $f_edtext"
    exit
  }
  set edtext [read $f_edtext]
  close $f_edtext
  puts $fid "\tedtext = {${edtext}\t},"
}
puts $fid "\ttext_depth = $text_depth"
puts $fid ");"
# Set trace nets.
# Special handling for square brackets in ICV.
regsub -all {\[} $nets {\\\\\\\[} nets
regsub -all {\]} $nets {\\\\\\\]} nets
set nets_formatted ""
foreach net $nets {
  set nets_formatted "$nets_formatted \"$net\","
}
puts $fid "trace_nets : list of string = {${nets_formatted}};"
# Set layer assignments.
for {set j $bot_metal} {($j >= $bot_metal) && ($j <= ($top_metal - 1))} {incr j} {
  puts $fid "m${j} = assign(\n\tldt_list = {"
  for {set i 0} {$i < [llength [set m${j}]]} {set i [expr {$i + 2}]} {
    puts $fid "\t\t{layer_num_range = [lindex [set m${j}] $i], data_type_range = [lindex [set m${j}] [expr {$i + 1}]]},"
  }
  puts $fid "\t}\n);"
  puts $fid "m${j}_txt = assign_text(\n\tldt_list = {"
  for {set i 0} {$i < [llength [set m${j}_txt]]} {set i [expr {$i + 2}]} {
    puts $fid "\t\t{layer_num_range = [lindex [set m${j}_txt] $i], data_type_range = [lindex [set m${j}_txt] [expr {$i + 1}]]},"
  }
  puts $fid "\t}\n);"
  puts $fid "v${j} = assign(\n\tldt_list = {"
  for {set i 0} {$i < [llength [set v${j}[expr $j + 1]]]} {set i [expr {$i + 2}]} {
    puts $fid "\t\t{layer_num_range = [lindex [set v${j}[expr $j + 1]] $i], data_type_range = [lindex [set v${j}[expr $j + 1]] [expr {$i + 1}]]},"
  }
  puts $fid "\t}\n);"
}
puts $fid "m${top_metal} = assign(\n\tldt_list = {"
for {set i 0} {$i < [llength [set m${top_metal}]]} {set i [expr {$i + 2}]} {
  puts $fid "\t\t{layer_num_range = [lindex [set m${top_metal}] $i], data_type_range = [lindex [set m${top_metal}] [expr {$i + 1}]]},"
}
puts $fid "\t}\n);"
puts $fid "m${top_metal}_txt = assign_text(\n\tldt_list = {"
for {set i 0} {$i < [llength [set m${top_metal}_txt]]} {set i [expr {$i + 2}]} {
  puts $fid "\t\t{layer_num_range = [lindex [set m${top_metal}_txt] $i], data_type_range = [lindex [set m${top_metal}_txt] [expr {$i + 1}]]},"
}
puts $fid "\t}\n);"
puts $fid "rdlvia = assign(\n\tldt_list = {"
for {set i 0} {$i < [llength $rdlvia]} {set i [expr {$i + 2}]} {
  puts $fid "\t\t{layer_num_range = [lindex $rdlvia $i], data_type_range = [lindex $rdlvia [expr {$i + 1}]]},"
}
puts $fid "\t}\n);"
puts $fid "rdl = assign(\n\tldt_list = {"
for {set i 0} {$i < [llength $rdl]} {set i [expr {$i + 2}]} {
  puts $fid "\t\t{layer_num_range = [lindex $rdl $i], data_type_range = [lindex $rdl [expr {$i + 1}]]},"
}
puts $fid "\t}\n);"
puts $fid "rdl_txt = assign_text(\n\tldt_list = {"
for {set i 0} {$i < [llength $rdl_txt]} {set i [expr {$i + 2}]} {
  puts $fid "\t\t{layer_num_range = [lindex $rdl_txt $i], data_type_range = [lindex $rdl_txt [expr {$i + 1}]]},"
}
puts $fid "\t}\n);"
# Connect layers.
puts $fid "cdb = connect(\n\tconnect_items = {"
for {set i $bot_metal} {($i >= $bot_metal) && ($i <= ($top_metal - 1))} {incr i} {
  puts $fid "\t\t{layers = {m${i}, m[expr {$i + 1}]}, by_layer = v${i}},"
}
puts $fid "\t\t{layers = {m${top_metal}, rdl}, by_layer = rdlvia}"
puts $fid "\t}\n);"
# Label nets.
puts $fid "cdb = text_net(\n\tconnect_sequence = cdb,\n\ttext_layer_items = {"
for {set i $bot_metal} {($i >= $bot_metal) && ($i <= $top_metal)} {incr i} {
  puts $fid "\t\t{layer = m${i}, text_layer = m${i}_txt},"
}
puts $fid "\t\t{layer = rdl, text_layer = rdl_txt}"
puts $fid "\t},\n\tuse_text = TOP,"
puts $fid "\tattach_text = ALL\n);"
# Output nets.
puts $fid "foreach(trace_net in trace_nets){"
for {set i $bot_metal} {($i >= $bot_metal) && ($i <= $top_metal)} {incr i} {
  puts $fid "\t{ @ trace_net + \" M${i}\";\n\t\tnet_texted_with(connect_sequence = cdb, text = {trace_net}, output_from_layers = {m${i}});\n\t}"
}
puts $fid "\t{ @ trace_net + \" RDL\";\n\t\tnet_texted_with(connect_sequence = cdb, text = {trace_net}, output_from_layers = {rdl});\n\t}"
puts $fid "};"
close $fid

# Run net_tracer runset.
if {[catch {open ${script_name}.tcsh w} fid]} {
  puts "***** $fid"
  exit
}
puts $fid "#!/bin/tcsh"
puts $fid "module unload icv; module load icv${icv_version}"
puts $fid "icv -norscache -host_init $cores -c $cell -f $layout_format -i $layout -vue -vueshort ${runset_name}.rs"
close $fid
file attributes ${script_name}.tcsh -permissions +x
eval exec >&@ stdout $grid ${script_name}.tcsh

# Return to original directory.
cd ..
cd ..

##### Adding usage statistics ######
# 2022-05-10 12:45:02
# Editor: wadhawan
# Statistics can be seen here: https://kibana/kibana/s/tesla/goto/b1a25580-d080-11ec-94f7-0990dc75113f

proc utils__script_usage_statistics {toolname version} {
    set prefix "ddr-da-"
    set reporter "/remote/cad-rep/msip/tools/bin/msip_get_usage_info"
    set cmd ""
    set script_dirname [file dirname [file normalize [info script]]]
    append cmd "$reporter --tool_name  \"${prefix}${toolname}\" "
    append cmd "--stage main --category ude_ext_1 "
    append cmd "--tool_path \"$script_dirname\" --tool_version \"$version\""

    exec sh -c $cmd
}

set script_name [file tail [file rootname [file normalize [info script]]]]
utils__script_usage_statistics $script_name "2022ww16"

###################################
################################################################################
# No Linting Area
################################################################################

# nolint Main