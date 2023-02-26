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

#--------------------------------------------------------------------#
set VERSION "2022ww35" ; 
#--------------------------------------------------------------------#

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



#-----------------------------------------------------------------
# Show the script usage details to the user
#-----------------------------------------------------------------
proc showUsage {} {
    global PROGRAM_NAME
    set msg "\nUsage:  $PROGRAM_NAME "
    append msg "\n\t  Example command lines:\n"
    append msg "\t\t  $PROGRAM_NAME  \n"
    append msg "\t\t  $PROGRAM_NAME -debug 1000 -verbosity 5 \n"
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

    
    set VERBOSITY [get_max_val $options(verbosity) $options(v)]
    set DEBUG [get_max_val $options(debug) $options(d)]
 
    set opt_test    $options(t)
    set opt_fast    $options(f)
    set opt_help    $options(h)
    set opt_project $options(p)

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

#-----------------------------------------------------------------
# Main procedure -->  put __ALL__ your code in this proc
#-----------------------------------------------------------------
proc Main {} {
    global PROGRAM_NAME
    process_cmdline
    iprint "Typical user message ... information only"
    wprint "Typical user message ... warning only"
    eprint "Typical user message ... error only"
    dprint 1 "Typical debug message ... only if DEBUG exceeds first arg"
    viprint 1 "Typical user message ... only if VERBOSITY exceeds first arg"
    #hprint "Typical user message ... highlight information only"
    #fatal_error "FATAL mesage to user ... then exit with val '1'"
    return 0
}

try {
    utils__script_usage_statistics $PROGRAM_NAME $VERSION
    header 
    set exitval [Main]
} on error {results options} {
    set exitval [fatal_error [dict get $options -errorinfo]]
} finally {
    footer
    write_stdout_log $LOGFILE
}
myexit $exitval

# nolint 