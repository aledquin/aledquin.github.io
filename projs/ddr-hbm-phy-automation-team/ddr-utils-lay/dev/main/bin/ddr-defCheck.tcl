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
set AUTHOR     "Alvaro Quintana Carvacho"
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
	global PROGRAM_NAME
	set msg "\nUsage:  $PROGRAM_NAME "
	append msg "\n\t  Example command lines:\n"
	append msg "\t\t  $PROGRAM_NAME  <defFile> <X-Pitch> <Y-Pitch>\n"
	append msg "\t\t  $PROGRAM_NAME  <defFile> <X-Pitch> <Y-Pitch> -debug 1000 -verbosity 5 \n"
	append msg "\t\t  $PROGRAM_NAME  -defFile <defFile> -xPitch <X-Pitch> -yPitch <Y-Pitch>\n"
	append msg "\t\t  $PROGRAM_NAME  -defFile <defFile> -xPitch <X-Pitch> -yPitch <Y-Pitch> -debug 1000 -verbosity 5 \n"
	append msg "\t\t  $PROGRAM_NAME -h \n"
	append msg "\n\t Valid command line options:\n"
	append msg "\t     -p <projID> : specifies the product/project/release triplet\n"
	append msg "\t     -d/debug #        : verbosity of debug messaging\n"
	append msg "\t     -v/verbosity #        : verbosity of user messaging\n"
	append msg "\t     -t          : use functional testing setup\n"
	append msg "\t     -f          : fast execution (skip pre-clean of RTL area & export from Perforce)\n"
	puts $msg
	return $msg
}

proc process_cmdline {} {

	set parameters {
		{verbosity.arg "0" "verbosity"}
		{v.arg  "0"    "verbosity"}
		{debug.arg "0" "debug"}
		{d.arg  "0"    "debug"}
		{p.arg  "none" "product/project/release"}
		{t             "functional testing mode"}
		{h             "help message"}
		{f             "run fast (skip delete, p4 print" }
		{defFile.arg "-" "def File"}
		{xPitch.arg	 "-" "x-Pitch"}
		{yPitch.arg	 "-" "y-Pitch"}
	}
	set usage {showUsage}
	try {
		array set options [::cmdline::getoptions ::argv $parameters $usage ]
		set defFile_argv [lindex $::argv 0]
		set xPitch_argv  [lindex $::argv 1]
		set yPitch_argv  [lindex $::argv 2]
	} trap {CMDLINE USAGE} {msg o} {
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

	global defFile
	global xPitch
	global yPitch

	set VERBOSITY [get_max_val $options(verbosity) $options(v)]
	set DEBUG [get_max_val $options(debug) $options(d)]

	set opt_test    $options(t)
	set opt_fast    $options(f)
	set opt_help    $options(h)
	set opt_project $options(p)

	set defFile 	[ if {$options(defFile) == "-"} {list $defFile_arg} ]
	set xPitch 		[ if {$options(xPitch) == "-"} {list $xPitch_arg} ]
	set yPitch 		[ if {$options(yPitch) == "-"} {list $yPitch_arg} ]



	dprint 1 "debug value     : $DEBUG"
	dprint 1 "verbosity value : $VERBOSITY"
	dprint 1 "project value   : $opt_project"
	dprint 1 "test value      : $opt_test"
	dprint 1 "fast value      : $opt_fast"
	dprint 1 "help value      : $opt_help"

	dprint 1 "defFile value	  : $defFile"
	dprint 1 "xPitch 		  : $xPitch"
	dprint 1 "yPitch		  : $yPitch"


	if { $opt_help } {
		showUsage
		myexit 0
	}

	return true
}



proc Main {} {
	global PROGRAM_NAME
	process_cmdline

	global defFile
	global xPitch
	global yPitch

	if {[file exists $defFile] && [regexp {def$} $defFile] && [regexp {[0-9]+} $xPitch] && [regexp {[0-9]+} $yPitch] } {

		#Initialization
		set udb 2000; #Default
		set fp [open $defFile r]
		set file_data [read $fp]
		set lines [split $file_data "\n"]
		set offgrid ""
		close $fp

		foreach line $lines {
			##Setting-up UDB value
			if {[regexp {UNITS DISTANCE MICRONS} $line]} {
				regexp {[0-9]+} $line udb

				#Process Macro Coordinates
			} elseif {[regexp {(^\-.*\;$)} $line] || [regexp {(^\-)} $line]} {
				regexp {([0-9]+\s[0-9]+)} $line origin
				set origin [split $origin " "]
				set xOrigin [lindex $origin 0];set yOrigin [lindex $origin 1]
				set qX [expr {$xOrigin / $xPitch}]
				set qY [expr {$yOrigin / $yPitch}]

				#Determine If Quotient is Floating point and has Remainder
				if { ![regexp {\.0$} $qX] && [regexp {\.} $qX] } {
					append offgrid "X-Pitch Error: $line\n"
				}
				if { ![regexp {\.0$} $qY] && [regexp {\.} $qY]} {
					append offgrid "Y-Pitch Error: $line\n"
				}
			}

		}
		#Display Script Output
		if {$offgrid != ""} {
			puts "Check Following Istances for Pitch Mismatch:\n"
			puts $offgrid
		} else {
			puts "Info: No Pitch Mismatch Found!"
		}

	} else {
		#Output Help information
		puts [showUsage]
	}
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

# nolint utils__script_usage_statistics