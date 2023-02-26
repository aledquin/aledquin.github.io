#!/depotbld/RHEL5.5/tcl8.5.2/bin/tclsh8.5

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

header

global argGlobalList
global globalVariables
set globalVariables(usage) "\
    Description: This script takes in a lef, and antenna lef. Output file name is defined by user. Output file is the merged contents of both lefs.

Usage:
lefMerge.tcl -lef <macro>.lef -antLef <macro_ant>.lef -output <output filepath here> -help

lef     -       Provides path to lef file
antLef  -       Provides path to antenna lef file
output  -       Provides path to output lef file
help    -       Outputs this usage message
"
array set argGlobalList [list lef "" antLef "" output "" help "0"]
global index
global listDepth
set listDepth 0

source ./CheckCmdLineArgs.tcl

proc flattenList {inputList {expandedList ""}} {
    foreach el $inputList {
        set nestFlag 0
        if {[llength $el] > 1} {
            foreach nest $el {
                if {[llength $nest] > 1} {
                    set nestFlag 1
                    break
                }
            }
            if {$nestFlag} {
                set expandedList [flattenList $el $expandedList]
            } else {
                lappend expandedList $el
            }
        } else {
            lappend expandedList $el
        }
    }

    return $expandedList
}

proc listGroup {listVar} {
    global index
    set listVar [lindex $listVar 0]

    lappend output [lindex $listVar $index]
    incr index
    while {$index < [llength $listVar]} {
        #if line does not end in ;, it is a start group identifier or end group identifier.
        set line [lindex $listVar $index]

        if {[regexp {\s*;$} $line]} {
            lappend output $line
        } elseif {[regexp -nocase {END} $line]} {
            lappend output $line

            return $output
        } else {
            lappend output [listGroup [list $listVar]]
        }

        incr index
    }
}

checkCmdLineArgs

if {$argGlobalList(help)} {puts "$globalVariables(usage)"; exit}

#lef file
set fp [open $argGlobalList(lef) r]
set lefLineList [lreplace [split [read $fp] "\n"] end end]
close $fp

#remove trailing whitespace
foreach line $lefLineList {
    lappend lefLineList_fixed [string trimright $line]
}
if {[info exists line]} {unset line}
set lefLineList $lefLineList_fixed
unset lefLineList_fixed

#ant lef file
set fp [open $argGlobalList(antLef) r]
set antLefLineList [lreplace [split [read $fp] "\n"] end end]
close $fp
#remove trailing whitespace
foreach line $antLefLineList {
    lappend antLefLineList_fixed [string trimright $line]
}
if {[info exists line]} {unset line}
set antLefLineList $antLefLineList_fixed
unset antLefLineList_fixed

#puts "BareFiles:"
#puts "$lefLineList"
#puts "$antLefLineList"

#Basic lef parse
foreach lefFileName [list lefLineList antLefLineList] {
    if {[info exists body]} {unset body}
    if {[info exists header]} {unset header}

    set lefFile [subst $$lefFileName]

    #foreach lef file
    set skipFlag 1
    for {set index 0} {$index < [llength $lefFile]} {incr index} {
        set line [lindex $lefFile $index]
        if {[regexp {^MACRO} $line]} {
            set skipFlag 0
        }

        if {$skipFlag} {
            lappend ${lefFileName}Header $line
            continue
        } else {
            #lef file contents parse start here

            #if line does not end in ;, it is a start group identifier or end group identifier.
            if {[regexp {\s*;$} $line]} {
                lappend body $line
            } else {
                lappend body [listGroup [list $lefFile]]

            }
        }
    }

    set ${lefFileName}Body $body

}

#search antenna lef.
#search each pin.
#if antenna info found in pin, dump the antenna info within the body

#puts "Begin MERGE"
#puts "[lindex $antLefLineListBody 0]"
if {[llength $lefLineListBody] > 1} {
    set lefLineListTail {*}[lreplace $lefLineListBody 0 0]
} else {
    set lefLineListTail [list "" ""]
}
set lefLineListBody [lindex $lefLineListBody 0]
foreach antEl [lindex $antLefLineListBody 0] {

    if {([llength $antEl] == 1) && ([string equal [lindex $antEl 0] ""])} {
        continue
    } else {
        if {[regexp {^\s*PIN} [lindex $antEl 0]]} {
            #found pin.
            set antPinName [lindex [eval list [string trim $antEl]] 0]

            foreach elOfel $antEl {
                if {[regexp {^\s*ANTENNA} $elOfel]} {
                    puts "$antPinName found"
                    lappend extractedAntennaList $elOfel
                } else {
                    continue
                }
            }



            if {![info exists extractedAntennaList]} {continue}
            puts "Antennas: $antPinName : $extractedAntennaList"

            for {set i 0} {$i < [llength $lefLineListBody]} {incr i} {
                set el [lindex $lefLineListBody $i]

                if {[llength $el] == 1} {
                    continue
                } else {
                    if {[regexp {^\s*PIN} [lindex $el 0]]} {
                        set pinName [lindex [eval list [string trim $el]] 0]
                        if {[string equal $pinName $antPinName]} {
                            puts "Lef pin name $pinName matches ant pin name $antPinName"
                            #found a match! find the index of USE SIGNAL/POWER, and dump the antnna information after that
                            set pinList $el
                            set insertIndex [lsearch -regexp $pinList {^\s*USE}]

                            if {$insertIndex == -1} {
                                error "No USE statement found for $pinName"
                            } else {
                                incr insertIndex
                            }


                            set pinList [linsert $pinList $insertIndex $extractedAntennaList]
                            set lefLineListBody [lreplace $lefLineListBody $i $i $pinList]

                            if {[info exists extractedAntennaList]} {unset extractedAntennaList}
                            break
                        }

                    }
                }
            }
        }
    }
}

#puts "List Print"
#puts $lefLineListBody
set expandedList [flattenList $lefLineListBody]
#puts "START TEST"
#puts $expandedList
#puts $lefLineListHeader
set expandedList [linsert $expandedList 0  {*}$lefLineListHeader]
set expandedList [linsert $expandedList end {*}$lefLineListTail]

set fileId [open $argGlobalList(output) "w"]
puts -nonewline $fileId [join $expandedList "\n"]
close $fileId



################################################################################
# No Linting Area
################################################################################
# 11-07-2022: monitor usage is in header now
# nolint utils__script_usage_statistics
# nolint Main
# nolint Line 120: W Found constant
# nolint Line 135: N Suspicious variable name
# nolint Line 150: N Suspicious variable name