#!/depot/tcl8.5.12/bin/tclsh8.5
;;######################################################################################
;;# proc CheckCmdLineArgs {}
;;# Evaluates the command line args, checks for validity of arguement (existance), and overwrites the default
;;# All command line switches overwite some default program setting
;;# Reference source: http://www.msen.com/~clif/tricks/tricks-sh-3.html
;;# Modified - Yiannis Karaziakos - Feb 20th 2015
;;# Requirements: This script is meant to be used with SiliconSmart
;;#

proc checkCmdLineArgs {} {

    global argGlobalList
    global argv

    set cmdLineArgs [lsearch -all -regexp $argv {^-}]

    if {[llength $cmdLineArgs] != 0} {
        for {set i 0} {$i<[expr {[llength $cmdLineArgs] - 1}]} {incr i} {
            set cmdLineArg [lindex $cmdLineArgs $i]
            lappend argvParsed [lindex $argv $cmdLineArg] [lreplace [lreplace $argv [lindex $cmdLineArgs [expr {$i + 1}]] end] 0 $cmdLineArg] 
        }
        lappend argvParsed [lindex $argv [lindex $cmdLineArgs end]] [lreplace $argv 0 [lindex $cmdLineArgs end]] 
    } else {
        set argvParsed $argv
    }

    ;#itterate through command line args
    foreach {argument value} $argvParsed {

        if {[string first "-" $argument] == 0} {
            #enter this code section of arguement starts with '-'
            set argument [string trimleft $argument {-}]
            #forces the program to only accept command line arguements whose default values have been already set.
            if {[info exists argGlobalList($argument)]} {
                if {[llength $value] == 0} {set value 1}
                set argGlobalList($argument) $value
            } else {
                puts "argument $argument"
                error "Bad command line arguement"
            }
        } else {
            puts "ERROR Bad Arguement List!"
            exit
        }
    }
}

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

################################################################################
# No Linting Area
################################################################################

# nolint Main
# nolint Line  19: N Expr