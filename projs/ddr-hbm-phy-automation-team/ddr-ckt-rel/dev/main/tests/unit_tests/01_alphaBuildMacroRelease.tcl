#!/depot/tcl8.6.6/bin/tclsh
#nolint Main
#nolint utils__script_usage_statistics

package require tcltest 2.0
namespace import -force ::tcltest::*

package require try         ;# Tcllib.
package require cmdline 1.5 ;# First version with proper error-codes.
package require fileutil

set DEBUG      0
set VERBOSITY  0
set STDOUT_LOG ""
set AUTHOR     "Alvaro Quintana Carvacho"
set RealBin [file dirname [file normalize [info script]] ]
set RealScript [file tail [file normalize [info script]] ]

set PROGRAM_NAME "$RealScript"

set opt_fast ""
set opt_test ""
set opt_help ""
set opt_project ""

#lappend auto_path "$RealBin/../bin"
lappend auto_path "$RealBin/../../lib"

package require Messaging 1.0
namespace import ::Messaging::*

package require Misc 1.0
namespace import ::Misc::*



#######################################################################
# Your config here
#######################################################################

# set DA_RUNNING_UNIT_TESTS 0

# -verbose level -> Sets the type of output verbosity desired to level,
#                   a list of zero or more of the elements body, pass,
#                   skip, start, and error. Default value is {body error}.
# Levels are defined as:
# body (b) -> Display the body of failed tests
# pass (p) -> Print output when a test passes
# skip (s) -> Print output when a test is skipped
# start (t)-> Print output whenever a test starts
# error (e)-> Print errorInfo and errorCode, if they exist,
# when a test return code does not match its expected return code
# The single letter abbreviations noted above are also recognized so
# that [configure -verbose pt] is the same as [configure -verbose {pass start}].

# source $RealBin/../../bin/alphaBuildMacroRelease.tcl

::tcltest::verbose bpse
::tcltest::debug 2

#######################################################################
# Create your procs here
#######################################################################

proc add2list {list_name new_value} {
    upvar $list_name lister
    #puts "$list_name contains \{$lister\}"

    if {[info exists lister]} {
        #puts "$list_name exist"
        if {[lsearch -exact $lister $new_value] == -1} {
            #puts "Adding in $list_name"
            lappend lister $new_value
            
        }
    } else {
        #puts "Creating $list_name"
        lappend lister $new_value
    }
    #puts "lister  --> $lister"
    #puts "list_name --> [set list_name]"
    #puts "\$list_name --> [set [set list_name]]"

} 


proc addChangelist {type macroRelease changelist} {
    switch $type {
        "main"      {set changelist_list ::changelists($macroRelease)}
        "utility"   {set changelist_list ::utilityChangelists($macroRelease)}
        "hspice"    {set changelist_list ::hspiceChangelists($macroRelease)}
        "ibis"      {set changelist_list ::ibisChangelists($macroRelease)}
        "repeater"  {set changelist_list ::repeaterChangelists($macroRelease)}
        "tc"        {set changelist_list ::tcChangelists($macroRelease)}
        default     {return 1}
    }
    add2list $changelist_list $changelist
}


proc addDatetime {type macroRelease datetime} {
    switch $type {
        "main"      {set datetime_list ::datetimes($macroRelease)}
        "utility"   {set datetime_list ::utilityDatetimes($macroRelease)}
        "hspice"    {set datetime_list ::hspiceDatetimes($macroRelease)}
        "ibis"      {set datetime_list ::ibisDatetimes($macroRelease)}
        "repeater"  {set datetime_list ::repeaterDatetimes($macroRelease)}
        "tc"        {set datetime_list ::tcDatetimes($macroRelease)}
        default     {return 1}
    }
    add2list $datetime_list $datetime
}


proc addDatetimeCmp {type macroRelease datetimeCmp} {
    switch $type {
        "main"      {set datetimeCmp_list ::datetimeCmps($macroRelease)}
        "utility"   {set datetimeCmp_list ::utilityDatetimeCmps($macroRelease)}
        "hspice"    {set datetimeCmp_list ::hspiceDatetimeCmps($macroRelease)}
        "ibis"      {set datetimeCmp_list ::ibisDatetimeCmps($macroRelease)}
        "repeater"  {set datetimeCmp_list ::repeaterDatetimeCmps($macroRelease)}
        "tc"        {set datetimeCmp_list ::tcDatetimeCmps($macroRelease)}
        default     {return 1}
    }
    add2list $datetimeCmp_list $datetimeCmp
}


proc addDesc {type macroRelease desc} {
    switch $type {
        "main"      {set desc_list ::descs($macroRelease)}
        "utility"   {set desc_list ::utilityDescs($macroRelease)}
        "hspice"    {set desc_list ::hspiceDescs($macroRelease)}
        "ibis"      {set desc_list ::ibisDescs($macroRelease)}
        "repeater"  {set desc_list ::repeaterDescs($macroRelease)}
        "tc"        {set desc_list ::tcDescs($macroRelease)}
        default     {return 1}
    }
    add2list $desc_list $desc
}

proc addRelease {type macro release} {

    if [regexp {_qadata$} $release dummy] {
        #	puts "Info:  Skipping $macro release $release"
        return 0
    }

    if [info exists ::releasePatt($macro)] {
        if {![string match $::releasePatt($macro) $release]} {
            ##  release does not match pattern.  Skip
            return 0
        } 
    }

    switch $type {
        "main"      {set release_list ::releases($macro)}
        "utility"   {set release_list ::utilityReleases($macro)}
        "hspice"    {set release_list ::hspiceReleases($macro)}
        "ibis"      {set release_list ::ibisReleases($macro)}
        "repeater"  {set release_list ::repeaterReleases($macro)}
        "tc"        {set release_list ::tcReleases($macro)}
        default     {return 1}
    }
    add2list $release_list $release
}

#######################################################################
# Create your tests here
#######################################################################

#######################################################################
## add2list
#######################################################################

test add2list_t01 { Test: $PROGRAM_NAME } \
    -body { add2list } \
    -returnCodes error \
    -result {wrong # args: should be "add2list list_name new_value"} \
    -output {}

test add2list_t02 { Test: $PROGRAM_NAME } \
    -body { set ::list_testing ""
add2list ::list_testing "first_value"
puts $::list_testing} \
    -result {} \
    -output {first_value
}

test add2list_t03 { Test: $PROGRAM_NAME } \
    -body { 
        add2list ::list_testing "second_value"
puts $list_testing} \
    -result {} \
    -output {first_value second_value
} 

test add2list_t04 { Test: $PROGRAM_NAME } \
    -body { add2list  ::list_testing "second_value"
puts $list_testing} \
    -result {} \
    -output {first_value second_value
} 

















cleanupTests
