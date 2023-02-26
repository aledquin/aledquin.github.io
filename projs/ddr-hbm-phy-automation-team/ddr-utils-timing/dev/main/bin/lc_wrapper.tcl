#!/depot/tcl8.6.3/bin/tclsh8.6
###############################################################################
#
# Name    : std_template.tcl
# Author  : your name here
# Date    : creation date here
# Purpose : description of the script.. can put on multiple lines
#
# Modification History
#     000 YOURNAME  CURRENT_DATE
#         Created this script
#     001 YOURNAME DATE_OF_YOUR_CHANGES
#         Description of what you have changed.
#     
###############################################################################

package require try         ;# Tcllib.
package require cmdline 1.5 ;# First version with proper error-codes.
package require fileutil

set DEBUG      0
set VERBOSITY  0
set STDOUT_LOG ""
set AUTHOR     "Manmit Muker (mmuker), Patrick Juliano (juliano), Alvaro Quintana Carvacho"
set RealBin [file dirname [file normalize [info script]] ]
set RealScript [file tail [file normalize [info script]] ]
set PROGRAM_NAME $RealScript
set LOGFILE "[pwd]/$PROGRAM_NAME.log"

# Declare cmdline opt vars here, so they are global
set opt_fast ""
set opt_test ""
set opt_help ""
set opt_project ""

lappend auto_path "$RealBin/../lib/tcl"
package require Messaging 1.0
namespace import ::Messaging::*
package require Misc 1.0
namespace import ::Misc::*


proc showUsage {} {
puts "Input options:"
puts "\t-refLib: name/link of reference library file. \
	  \n\t-curLib: name/link of current library file. \
	  \n\t-cells: cells to be checked, default is all cells. \
	  \n\t-ccs 0 | 1 : select 1 if input libs are ccs, will turn on ccs-specific checks. \
	  \n\t-lcVersion : default is latest version \
	  \n\t-report_lib timing | timing_arcs : report timing information of input libs.  \
	  \n\t-min_delay 1 | 0 : enable min_delay_flag checks\
	  \n\t-mono <number> : for NLDM libs, enable monotonicity check with <number> ps tolerance. \
	  \n\t-plot <your_arc_list.csv>: plot tables of arcs specified in <your_arc_list.csv> \	  
	  "
puts "\t-compare construct | attribute | value \
		 \n\t\t \(can be combined with\:\) \
		 \n\t\t-validate timing : enabled with ccs \
		 \n\t\t-analyze table_trend | nominal_vs_sigma | table_bound | table_slope | table_index | sensitivity | voltage_range | interpolation | lvf | value_range | pg_current | ccsp_time_constant : option to show detailed lookup table information. \
		 \n\t\t-criteria \"trend=/\", \"capacitance= 0.5\"etc. \
		 \n\t\t-tolerance \"delay 0 0.01\" : 1st number is relative diff, 2nd number is absolute diff. Can be used on load index | slew index | time | power | current | delay | slew | ocv | ccsn | constraint | capacitance etc \
		 \n\t\t-group_attribute \
		 \n\t\t-report_format csv | html | sql - default: csv + html \
		 \n\t\t-reportOpt 0 | 1 : option to report library comparison settings/tolerances in summary report \
		 "
}
########################## end of procs
proc Main {} {
#parse input options
if {$argc == 1 && $argv == "-help"} {
	showUsage
	return
} elseif {$argc == 1} {
	puts "=== Invalid input opton. Please see usage below. ==="
	showUsage
	return
}
#get script path and run path
set thisScript [info script]																																																																																																																																																																			
if {[file type $thisScript] == "link"} {set thisScript [file readlink $thisScript]}
set thisScript [file normalize $thisScript]
set scriptPath [regsub {/[^/]+$} $thisScript ""]	
set runPath [pwd]


set lcConfig [open "$runPath/lc.config" w]
for { set i 0 } { $i < [ llength $argv ] } { incr i} {
    set theArg [lindex $argv $i]
    if {[string index $theArg 0] == "-"} {
	set argName [string trimleft $theArg "-"]
	incr i
	set argVal [lindex $argv $i]
	set $argName $argVal
#	puts "set $argName $argVal"
    }
}

#set default values
puts $lcConfig "#This is the bare-minimum"
puts $lcConfig "set scriptPath $scriptPath"
puts $lcConfig "set runPath $runPath"
puts $lcConfig "set ref $refLib"
puts $lcConfig "set cur $curLib"
if {![info exists cells]} {puts $lcConfig "set cells \"*\""} else {puts $lcConfig "set cells \{$cells\}"}
puts $lcConfig "###############################################"

#set options
puts $lcConfig "\n# === Liberty & Monotonicity Checks ==="
if [info exists report_lib] {puts $lcConfig "#Report_lib Enabled\nset report_lib $report_lib"} else {puts $lcConfig "#Report_lib Disabled"} 
if [info exists min_delay] {puts $lcConfig "#Min_delay_flag Check Enabled\nset min_delay $min_delay"} else {puts $lcConfig "#Min_delay Disabled"}
if [info exists mono] {
		puts $lcConfig "#Monotonicity Check Enabled - tolerance = $mono ps\nset mono $mono"
		puts $lcConfig "set tol \{delay 0 [expr {double($mono)/1000}] constraint 0 [expr {double($mono)/1000}]\}"
	} else {puts $lcConfig "#Monotonicity Check Disabled"}

puts $lcConfig "\n# === Library Comparison ==="
if {[info exists compare]} {
	puts $lcConfig "#Enabled\nset compare $compare"
    if {[info exists ccs] && $ccs} {
    	puts $lcConfig "set ccs 1"
    	puts $lcConfig "#Turn on timing validation for ccs libs."
    	puts $lcConfig "set args(validate) \{timing\}"
    }
#	if [info exists merge] 
	if [info exists analyze] {puts $lcConfig "set args(analyze) \{$analyze\}"}
	if [info exists criteria] {puts $lcConfig "set args(criteria) \{$criteria\}"}
	if [info exists report_format] {puts $lcConfig "set args(report_format) \{$report_format\}"} else {puts $lcConfig "set args(report_format) \{html csv=compare_lib nosplit\}"}
	if [info exists tolerance] {puts $lcConfig "set args(tolerance) \{$tolerance\}"}
	if [info exists group_attribute] {puts $lcConfig "set args(group_attribute) \{$group_attribute\}"}
	puts $lcConfig "set args(compare) \{$compare\}"
	#option to display check_library settings -- currently turned on by default -- subject to change
	if [info exists reportOpt] {puts $lcConfig "set reportOpt $reportOpt"} else {puts $lcConfig "set reportOpt 1"}
} else {puts $lcConfig "#Disabled"} 


puts $lcConfig "\n# === Plot Table ==="
if {[info exists plot]} {puts $lcConfig "#Enabled\nset plot \"$plot\""} else {puts $lcConfig "#Disabled"} 

close $lcConfig

###########
# generate csh file
###########
set lcScript "$scriptPath/lc_shell.tcl"
set shellScript "$runPath/lc.tmp.csh"
set SCR [open $shellScript w]
puts $SCR "\#!/bin/csh"
puts $SCR "module unload lc"
if [info exists lcVersion] {set lcModule $lcVersion} else {set lcModule "lc"}
puts $SCR "module load $lcModule"
puts $SCR "lc_shell -f $lcScript > lc_run.log"
puts $SCR "exit"
close $SCR
file attributes $shellScript -permissions "+x"
exec $shellScript
#exec "./$shellScript"
file delete $shellScript
###########
}


try {
    header 
    set exitval [Main]
} on error {results options} {
    set exitval [fatal_error [dict get $options -errorinfo]]
} finally {
    footer
    write_stdout_log $LOGFILE
}
myexit $exitval

# nolint Line  96: N Suspicious variable name
# 11-07-2022: monitor usage is in header now
# nolint utils__script_usage_statistics