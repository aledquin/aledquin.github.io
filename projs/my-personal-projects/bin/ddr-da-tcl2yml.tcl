#!/depot/tcl8.6.3/bin/tclsh8.6
###############################################################################
#
# Name    : ddr-da-tcl2yml.tcl
# Author  : Alvaro Quintana
# Date    : 02-14-2023
# Purpose : convert variables set in a legalRelease.txt and converts it to yml
#
# Modification History
#     000 alvaro  02142023
#         Created this script
#         Please check /u/alvaro/GitLab/my-personal-projects/Notes/notes_2023_02_14.ipynb
#         for more information.
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

lappend auto_path "/depot/tcl8.6.3/lib"
package require yaml
#-----------------------------------------------------------------
# Show the script usage details to the user
#-----------------------------------------------------------------
proc showUsage {} {
    global PROGRAM_NAME
    set msg "\nUsage:  $PROGRAM_NAME "
    append msg "\n\t  Example command lines:\n"
    append msg "\t\t  $PROGRAM_NAME -i <legalrelease.txt> \n"
    append msg "\t\t  $PROGRAM_NAME -i <legalrelease.txt> -o <yml_output_file.yml>\n"
    append msg "\t\t  $PROGRAM_NAME -i <legalrelease.txt> -o <yml_output_file.yml> -debug 1000 -verbosity 5 \n"
    append msg "\t\t  $PROGRAM_NAME -h \n"
    append msg "\n\t Valid command line options:\n"
    append msg "\t     -i <legalrelease_file> : specifies the legal release input\n"
    append msg "\t     -o <yml output file> : specifies the yml output file name\n"
    append msg "\t     -d/debug #        : verbosity of debug messaging\n"
    append msg "\t     -v/verbosity #        : verbosity of user messaging\n"
    append msg "\t     -t          : use functional testing setup\n"
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
            {i.arg      "" "legal release input file"}
            {o.arg "yml-log.yml" "output: yml file"}
    }
    set usage {showUsage}
    try {
       array set options [::cmdline::getoptions ::argv $parameters $usage ]
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

    global legalrelease_input
    global yml_output

    set legalrelease_input $options(i)
    set yml_output         $options(o)

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


proc create_dict_from_file {__file} {

    source $__file
    unset __file

    global varlist

    set varlist [lsort [info vars]]

    foreach varname $varlist {
        if {[array exists $varname]} {
            foreach {ark arv} [array get $varname] {
                viprint LOW "$varname $ark --> $arv"
                dict set legal_release $varname "$ark:" "\{$arv\}"
            }
        } else {
            set varvalue [set $varname]
            viprint LOW "$varname --> $varvalue"
            dict set legal_release $varname $varvalue
            unset varvalue
        }        
    }
    return $legal_release
}



#-----------------------------------------------------------------
# Main procedure -->  put __ALL__ your code in this proc
#-----------------------------------------------------------------
proc Main {} {
    global PROGRAM_NAME
    process_cmdline

    global legalrelease_input
    global yml_output


    set legal_release [create_dict_from_file $legalrelease_input]
    set yaml_format [yaml::dict2yaml $legal_release 4 80]
    write_file $yml_output [regsub -all {\|-|>|\{|\}} [regsub -all "\} " $yaml_format "\}\n    "] ""] 

    return 0
}

less {}
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