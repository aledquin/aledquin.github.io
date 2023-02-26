#!/depot/tk8.6.1/bin/wish
##!/depot/tcl8.6.3/bin/tclsh8.6

#proc addItemUnique { myArray myIndex item } {
#
#    if [info exists $myArray($myIndex)] {
#	set x [set $myarray($myIndex)]
#	if {[lsearch -exact $x $item] == -1} { lappend $x $item }
#    } else {set x [list $item]}
#    set $myArray($myIndex) $x
#}
#

# package require try         ; # Tcllib.
# package require cmdline 1.5 ; # First version with proper error-codes.
# package require fileutil

set DEBUG      0
set VERBOSITY  0
set STDOUT_LOG ""
set AUTHOR     "Manmit Muker (mmuker), Patrick Juliano (juliano), Alvaro Quintana Carvacho"
set RealBin [file dirname [file normalize [info script]] ]
set RealScript [file tail [file normalize [info script]] ]
set PROGRAM_NAME $RealScript

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
lappend auto_path "$RealBin/../lib/tcl/bwidget-1.9.15"
if {![info exists ::env(DA_TEST_NOGUI)]} {
    package require BWidget 1.9.15
}

# header

##  Controls the execution of a pcs snapshot
set doSnapshotOnMail 0
set emailSend {}
set thisScript [file normalize [info script]]
set thisScriptDir [file dirname $thisScript]
set testmode  0
if { [info exists ::env(DA_TEST_MODE)] } {
    set testmode 1
}

##  Log usage: Invocation


##  Dict's to keep track of pincheck status
set pincheckInfo [dict create]
set pincheckMacroReleaseChecks [dict create]

##  Scoreboard to keep track of pincheck for each macro
array unset macroPincheckStatus

##  date/desc indexedby changelist #
array unset changelistInfo

##  Checking pincheck staleness requires knowing the latest check-in times for views that are relevant to pincheck.
##  This is a list of patterns applied to the p4 file names to identify these.
##  The variables 'macro' and 'release' will be defined when these are expanded.
set pincheckAssocPattList [list]
##  verilog views.
lappend pincheckAssocPattList {/interface/${macro}_interface\.v$}
lappend pincheckAssocPattList {/behavior/$macro\.v$}

## cdl, without a metalstack dir
lappend pincheckAssocPattList {/netlist/$macro\.cdl$}
## cdl, with a metalstack dir
lappend pincheckAssocPattList {/netlist/[a-z_0-9]+/$macro\.cdl$}
## gds/oas, with a metalstack dir
lappend pincheckAssocPattList {/gds/[a-z_0-9]+/$macro.gds(\.gz)?$}
lappend pincheckAssocPattList {/oasis/[a-z_0-9]+/$macro.oas(\.gz)?$}
# lef
lappend pincheckAssocPattList {/lef/[a-z_0-9]+/$macro\.lef$}
lappend pincheckAssocPattList {/lef/[a-z_0-9]+/${macro}_merged\.lef$}
## pininfo
lappend pincheckAssocPattList {/pininfo/$macro.csv$}
## libs
##
lappend pincheckAssocPattList {/timing/[a-z_0-9]+/lib[a-z_]*/${macro}_[a-z0-9_]+\.lib(.gz)?$}
# cosim
lappend pincheckAssocPattList {/cosim/$macro\.sp$}

proc displayLabel {macro chgWidget} {

    set bfr "History for $macro:\n"
    foreach cl [$chgWidget cget -text] {
        set d $::changelistInfo($cl)
        append bfr "[dict get $d datetime]  $cl  [dict get $d desc]  ([dict get $d viewList])\n"
    }

    set w .lblViewer
    catch {
        toplevel $w
        pack [text $w.out -state disabled -font "MyDefaultFont 8"] -expand 1 -fill both -side top
        #        pack $w -expand 1 -fill both
        pack [button $w.close -text "Close" -command {destroy .lblViewer}] -side top
    }


    $w.out config -state normal
    $w.out delete 0.0 end
    $w.out insert end $bfr
    $w.out config -state disabled


}

proc doMailProceed {answer} {
    set ::doMailProceed $answer
    destroy .proceedDialog
}

proc addPincheckInfo {release macro info} {
    if {![dict exists $::pincheckInfo $release]} {dict set ::pincheckInfo $release [dict create]}
    dict set ::pincheckInfo $release $macro $info
}

proc enterWaiver {} {
    if {$::waiver eq "" } {
        tk_dialog .empty "ERROR" "Waiver cannot be empty!" error 0 OK
    } else {
        set ::topcellWaiver $::waiver
        set ::proceed 1
    }
}

proc pincheckAssociated {type} {
    ##  Determines based on type whether there should be a pincheck associated.
    switch -nocase -exact -- $type {
        main {return true}
        utility {return true}
        hspice {return false}
        ibis {return false}
        repeater {return true}
        tc {return true}
        default {return false}
    }
}

proc viewP4File {p4FileName} {
    set bfr [exec p4 print -q $p4FileName]
    #logMsg $bfr

    set w .viewer
    set fframe $w.files
    catch {
        toplevel $w
        frame $fframe
        pack [text $w.file -height 1 -width 200 -state disabled -font "MyDefaultFont 10"] -expand 1 -fill both -side top
        pack [text $fframe.out -height 60 -width 200 -yscrollcommand "$fframe.scroll set" -state disabled -font "MyDefaultFont 8"] -expand 1 -fill both -side right
        pack [scrollbar $fframe.scroll -command "$fframe.out yview"] -side right -fill y
        pack $fframe -expand 1 -fill both
        pack [button $w.close -text "Close" -command {destroy .viewer}] -side top
    }
    $fframe.out config -state normal
    $fframe.out delete 0.0 end
    $fframe.out insert end $bfr
    $fframe.out config -state disabled

    $w.file config -state normal
    $w.file delete 0.0 end
    $w.file insert end $p4FileName
    $w.file config -state disabled
}


proc showUsage {} {
    puts "Usage:  $::thisScript \[-project projType/projName/projRel\] \[-config <config-file>\] \[-configP4 <depot-spec-of-config-file>\]"
    puts "\t-project example: ddr43/d515-ddr43-tsmc10ff18/rel1.00a"
    #puts "\t\tReferences legalMacros.txt and legalRelease.txt in \$PROJ_HOME/design/"
    puts "\t\tReferences topcells.txt and legalRelease.txt in \$PROJ_HOME/design/"
    puts "\t\tThe former is a simple list of the macros"
    puts "\t\tThe latter defines a set of variables (tcl syntax):"
    puts "\t\t\trel:  Identifier for the IP release."
    puts "\t\t\tp4_release_root:  Where in the depot the IP files live, not including the //depot/"
    puts "\t\t\tprocess:  The technology.  Informational only."
    puts "\t\t\treleaseMailDist:  Comma-separated list of mail recipients."
    puts "\t-config: Simple file spec of a config file.  Generally, the config is generated by the IP manager"
    puts ""
    puts "Flow:"
    puts "\tIP release manager runs script with -project, selects the macro versions (tool defaults to latest)"
    puts "\tMail button will generate the following:"
    puts "\t\tA config file in //depot/\$p4_release_root of the form \"release_\$rel.config"
    puts "\t\tAn email summary of the macro versions, the the readme and the command to invoke the script with the above config"
    puts "\t\tNote: The readme will be picked up from //depot/\$p4_release_root/release_\$rel.readme"
    puts "\t\tIt is expected that the implementation will exec this script with the config provided to export the released IP files"
    puts "\tBuild button will export the selected macro files in a directory named after the \"rel\" variable"
    puts "\tClean button will delete everything in the \"rel\" directory"
}

proc checkPincheckLog {pincheckP4 summaryP4} {

    set clean true
    set timingclean true
    set nontimingclean true
    set status true
    set runTime 0
    set maxrunTime 0
    set llist {}
    set fileList {}

    ## If using new flow, get statuses from summary file
    if {$summaryP4 != FALSE} {
        set bfr [exec p4 print $summaryP4]
        set bfr [split $bfr "\n"]
        foreach line $bfr {
            set clean_regex ""
            set nontimingclean_regex ""
            set timingclean_regex ""
            regexp -all {([A-Z]+)\W\s([A-Z]+)\W\s([A-Z]+)} $line whole_match clean_regex nontimingclean_regex timingclean_regex
            if {$clean_regex == "DIRTY"} {
                set clean false
                set status false
            }
            if {$nontimingclean_regex == "STALE"} {
                set nontimingclean false
                set status false
            }
            if {$timingclean_regex == "STALE"} {
                set timingclean false
                set status false
            }
        }
    }
    ## Parses the pincheck log
    set bfr [exec p4 print $pincheckP4]
    set bfr [split $bfr "\n"]
    foreach line $bfr {
        ## If using legacy flow, get statuses from log file
        if {$summaryP4 == FALSE} {
            if {[regexp {DIRTY} $line]} {
                set clean false
                set status false
            }
            if {[regexp -line {Non-timing File .* \((.*)\).* is stale} $line]} {
                set nontimingclean false
                set status false
            }
            if {[regexp -line {Timing File .*.lib.gz \((.*)\).* is stale} $line]} {
                set timingclean false
                set status false
            }
        }
        ## Get runtime of pincheck
        ## Uses '-I-' in newer pinchecks, 'Info: ' in older pinchecks
        if {[regexp {(-I-|Info: ) Current time is (.*)} $line dmy opt_info t]} {
            set runTime [clock scan $t]
        }
        ## Get all files being read by pincheck
        if {[regexp {^(-I- )?Reading (\"/u.+\"|/u.+)$} $line full_match optional_info file_name]} {
            ## Remove optional quotes and replace local file_name with P4 file name
            set file_name [regsub ".*products" [regsub -all "\"" $file_name ""] "//depot/products"]
            ## append file only if not already in fileList
            if {[lsearch -exact $fileList $file_name] < 0} {
                lappend fileList $file_name
            }
        }
    }
    #########################################################################################
    ## Runs fstat command to get latest modification time of all files in $fileList
    #########################################################################################
    ## ***IMPORTANT***: The 'p4 fstat' command can take in multiple files at once.
    ## Please ensure you do not run 1 file at a time as this increases the runtime immensely.
    #########################################################################################
    exec rm -f /tmp/fstatcmd
    if {[llength $fileList] > 0} {
        set TIME_start3 [clock clicks -milliseconds]
        set tmpfile [open "/tmp/fstatcmd" w+]
        puts -nonewline $tmpfile "p4 fstat -T 'headModTime'"
        foreach file $fileList {
            puts -nonewline $tmpfile " $file"
        }
        close $tmpfile
        catch {exec chmod +x /tmp/fstatcmd}
        if {[catch {set fstat [exec "/tmp/fstatcmd"]}]} {
            ## Do something if error
            #puts "Error: fstat command failed"
        } else {

            set TIME_taken3 [expr [clock clicks -milliseconds] - $TIME_start3]

            set t [string trim [string map {"... headModTime" "" "\n" ""} $fstat] " "]
            set llist [split $t " "]
            set length [llength $fileList]
            set lastIndex [expr {$length -1}]
            if {$length > 0} {
                set TIME_sort [clock clicks -milliseconds]
                set sorted_list [sort $llist]
                set TIME_taken_sort [expr [clock clicks -milliseconds] - $TIME_sort]
                #set minrunTime [lindex $sorted_list 0]
                set maxrunTime [lindex $sorted_list $lastIndex]
            }
        }
        file delete "/tmp/fstatcmd"
    }

    if {$summaryP4 == FALSE} {
        return [dict create file $pincheckP4 clean $clean timingclean $timingclean nontimingclean $nontimingclean runTime $runTime maxrunTime $maxrunTime status $status]
    } else {
        return [dict create file $summaryP4 clean $clean timingclean $timingclean nontimingclean $nontimingclean runTime $runTime maxrunTime $maxrunTime status $status]
    }
}

proc firstAvailableFile {args} {

    foreach ff $args {
        if {[file exists $ff]} {return $ff}
    }

    puts "Error:  None of these exist:"
    foreach ff $args {puts "\t$ff"}

    return ""

}

proc sort { mylist } {  #### added this function to sort wide integers like timestamps. The lsort -integer switch didn't work. ##########
set len [llength $mylist]
set len [expr {$len-1}]

for {set i 0} {$i<$len} {incr i} {
    for {set j 0} {$j<[expr {$len-$i}]} {incr j} {
        if { [lindex $mylist $j] > [lindex $mylist [expr {$j+1}]]} {
            set temp [lindex $mylist $j]
            lset mylist $j [lindex $mylist [expr {$j+1}]]
            lset mylist [expr {$j+1}] $temp
        }
    }
}
foreach n $mylist {
    set clk [clock format $n -format "%a %b %T %Y"]
    #        puts "$n $clk"
}
return $mylist
}


proc prevCommand {} {
    ##  Gets previous command
    if [info exists ::commandSelected] {
        incr ::commandSelected -1
        if {$::commandSelected < 0} {set ::commandSelected 0}
        .cf.entry delete 0 end
    } else {
        set ::commandSelected [expr {[llength $::commandHistory]-1}]
    }
    .cf.entry insert end [lindex $::commandHistory $::commandSelected]
}

proc executeCommand {} {
    ##  Get the text in the command frame and execute it.
    set ::Command [.cf.entry get]
    if {$::Command != ""} {
        lappend ::commandHistory $::Command
        .cf.entry delete 0 end
        uplevel {
            set status [eval $::Command]
            logMsg "$status\n"
            unset -nocomplain ::commandSelected
        }
    }
}

proc logMsg {msg} {

    if {![info exists ::DDR_DA_UNIT_TEST]} {
        .tf.out config -state normal
        .tf.out insert end $msg
        .tf.out see end
        .tf.out config -state disabled
        update
    } else {
        puts $msg
    }
}

proc logError {msg} {

    .tf.out config -state normal
    .tf.out insert end $msg err
    .tf.out see end
    .tf.out config -state disabled
    update
}

proc refreshRow {macro type tabName num} {

    if {$type == "main"} {
        upvar #0 releases releases
        upvar #0 changelists changelists
        upvar #0 datetimes datetimes
        upvar #0 descs descs
    } elseif {$type == "utility"} {
        upvar #0 utilityReleases releases
        upvar #0 utilityChangelists changelists
        upvar #0 utilityDatetimes datetimes
        upvar #0 utilityDescs descs
    } elseif {$type == "hspice"} {
        upvar #0 hspiceReleases releases
        upvar #0 hspiceChangelists changelists
        upvar #0 hspiceDatetimes datetimes
        upvar #0 hspiceDescs descs
    } elseif {$type == "ibis"} {
        upvar #0 ibisReleases releases
        upvar #0 ibisChangelists changelists
        upvar #0 ibisDatetimes datetimes
        upvar #0 ibisDescs descs
    } elseif {$type == "repeater"} {
        upvar #0 repeaterReleases releases
        upvar #0 repeaterChangelists changelists
        upvar #0 repeaterDatetimes datetimes
        upvar #0 repeaterDescs descs
    } elseif {$type == "tc"} {
        upvar #0 tcReleases releases
        upvar #0 tcChangelists changelists
        upvar #0 tcDatetimes datetimes
        upvar #0 tcDescs descs
    }

    set macroType "$macro:$type"
    set release $::selectedRelease($macroType)
    set macroRelease "$type:$macro:$release"
    if {$release == $::latestMacroRel($macroType)} {
        set latest "Latest"
        set fgColor green
    } else {
        set latest "Old"
        set fgColor red
    }
    .nb.$tabName.c.mac.latestLabel$num configure -text $latest -fg $fgColor
    .nb.$tabName.c.mac.chgLabel$num configure -text $changelists($macroRelease) -fg $fgColor
    .nb.$tabName.c.mac.dateLabel$num configure -text $datetimes($macroRelease) -fg $fgColor
    .nb.$tabName.c.mac.descLabel$num configure -text $descs($macroRelease) -fg $fgColor

    if {[pincheckAssociated $type]} {
        if {[dict exists $::pincheckInfo $release $macro]} {
            if {[dict get $::pincheckInfo $release $macro clean]} {
                set pcStat "Pincheck Clean"
                set pcColor green
            } else {
                set pcStat "Pincheck Dirty"
                set pincheckStatus "Dirty"
                set pcColor red
            }
            ##  Check for timing pincheck freshness
            if {[dict get $::pincheckInfo $release $macro timingclean]} {
                set pcStat "$pcStat/Timing Fresh"
            } else {
                set pcStat "$pcStat/Timing Stale"
                set pcColor red
            }
            set relTime [dict get $::pincheckMacroReleaseChecks $release $macro]
            ##  Check for non-timing  pincheck freshness
            if {[dict get $::pincheckInfo $release $macro nontimingclean]} {
                set pcStat "$pcStat/Non-Timing Fresh"
            } else {
                set pcStat "$pcStat/NonTiming Stale"
                set pcColor red
            }
            if {[dict get $::pincheckInfo $release $macro maxrunTime] == 0 && [dict get $::pincheckInfo $release $macro status]} {
                set pcStat "$pcStat/Fresh"
            } elseif {[dict get $::pincheckInfo $release $macro runTime] < [dict get $::pincheckInfo $release $macro maxrunTime] && ![dict get $::pincheckInfo $release $macro status]} {
                ##   Release after pincheck time
                set pcStat "$pcStat/Stale"
                set pcColor red
            } else {
                set pcStat "$pcStat/Fresh"
                #                set pcColor green
            }
            .nb.$tabName.c.mac.pcViewButton$num configure -command "viewP4File [dict get $::pincheckInfo $release $macro file]" -state normal
            .nb.$tabName.c.mac.pcStatLabel$num configure -text $pcStat -fg $pcColor
            set balloonHelp [join {"Column 1: SUMMARY"
                "Column 2: Status of STALE checks for non-timing views only"
                "Column 3: Status of STALE checks for timing views only"
                "Column 4: Freshness of Pincheck run"
                "    FRESH - if run after views were updated in depot"
                "    STALE - if not run after views were updated in depot"} "\n"]
                ::DynamicHelp::register .nb.$tabName.c.mac.pcStatLabel$num balloon $balloonHelp
                set ::macroPincheckStatus($macro) $pcStat
            } else {
            if {$release != $::latestMacroRel($macroType) && $release != $::ipReleaseName} {
                set pcStat "Old release, pincheck files not loaded"
                .nb.$tabName.c.mac.pcStatLabel$num configure -text $pcStat -fg red
                .nb.$tabName.c.mac.pcViewButton$num configure -command "viewP4File nil" -state disabled
                set ::macroPincheckStatus($macro) "Missing"
            } else {
                set pcStat "Pincheck Missing"
                .nb.$tabName.c.mac.pcStatLabel$num configure -text $pcStat -fg red
                .nb.$tabName.c.mac.pcViewButton$num configure -command "viewP4File nil" -state disabled
                set ::macroPincheckStatus($macro) "Missing"
            }
        }
    }
}

proc refreshOnManualSelect { num name1 name2 op } {
    ##  name1:  variable name  (Should be ::selectedRelease)
    ##  name2:  macro:type
    #puts "refresh  $name1  $name2  $op $num"
    set l [split $name2 ":"]
    set macro [lindex $l 0]
    set type [lindex $l 1]
    set tabName "${type}tab"
    refreshRow $macro $type $tabName $num
}

proc getLatestDatetime {datetime} {
    set l 0
    foreach dt $datetime {if {$dt > $l} {set l $dt}}
    return $l
}

proc addDesc {type macroRelease desc} {

    if {$type == "main"} {
        if [info exists ::descs($macroRelease)] {
            if {[lsearch -exact $::descs($macroRelease) $desc] == -1} { lappend ::descs($macroRelease) $desc }
        } else {
            lappend ::descs($macroRelease) $desc
        }
    } elseif {$type == "utility"} {
        if [info exists ::utilityDescs($macroRelease)] {
            if {[lsearch -exact $::utilityDescs($macroRelease) $desc] == -1}  { lappend ::utilityDescs($macroRelease) $desc }
        } else {
            lappend ::utilityDescs($macroRelease) $desc
        }
    } elseif {$type == "hspice"} {
        if [info exists ::hspiceDescs($macroRelease)] {
            if {[lsearch -exact $::hspiceDescs($macroRelease) $desc] == -1}   { lappend ::hspiceDescs($macroRelease) $desc }
        } else {
            lappend ::hspiceDescs($macroRelease) $desc
        }
    } elseif {$type == "ibis"} {
        if [info exists ::ibisDescs($macroRelease)] {
            if {[lsearch -exact $::ibisDescs($macroRelease) $desc] == -1}     { lappend ::ibisDescs($macroRelease) $desc }
        } else {
            lappend ::ibisDescs($macroRelease) $desc
        }
    } elseif {$type == "repeater"} {
        if [info exists ::repeaterDescs($macroRelease)] {
            if {[lsearch -exact $::repeaterDescs($macroRelease) $desc] == -1} { lappend ::repeaterDescs($macroRelease) $desc }
        } else {
            lappend ::repeaterDescs($macroRelease) $desc
        }
    } elseif {$type == "tc"} {
        if [info exists ::tcDescs($macroRelease)] {
            if {[lsearch -exact $::tcDescs($macroRelease) $desc] == -1} { lappend ::tcDescs($macroRelease) $desc }
        } else {
            lappend ::tcDescs($macroRelease) $desc
        }
    }
}


proc addDatetime {type macroRelease datetime} {

    if {$type == "main"} {
        if [info exists ::datetimes($macroRelease)] {
            if {[lsearch -exact $::datetimes($macroRelease) $datetime] == -1} { lappend ::datetimes($macroRelease) $datetime }
        } else {
            lappend ::datetimes($macroRelease) $datetime
        }
    } elseif {$type == "utility"} {
        if [info exists ::utilityDatetimes($macroRelease)] {
            if {[lsearch -exact $::utilityDatetimes($macroRelease) $datetime] == -1} { lappend ::utilityDatetimes($macroRelease) $datetime }
        } else {
            lappend ::utilityDatetimes($macroRelease) $datetime
        }
    } elseif {$type == "hspice"} {
        if [info exists ::hspiceDatetimes($macroRelease)] {
            if {[lsearch -exact $::hspiceDatetimes($macroRelease) $datetime] == -1} { lappend ::hspiceDatetimes($macroRelease) $datetime }
        } else {
            lappend ::hspiceDatetimes($macroRelease) $datetime
        }
    } elseif {$type == "ibis"} {
        if [info exists ::ibisDatetimes($macroRelease)] {
            if {[lsearch -exact $::ibisDatetimes($macroRelease) $datetime] == -1} { lappend ::ibisDatetimes($macroRelease) $datetime }
        } else {
            lappend ::ibisDatetimes($macroRelease) $datetime
        }
    } elseif {$type == "repeater"} {
        if [info exists ::repeaterDatetimes($macroRelease)] {
            if {[lsearch -exact $::repeaterDatetimes($macroRelease) $datetime] == -1} { lappend ::repeaterDatetimes($macroRelease) $datetime }
        } else {
            lappend ::repeaterDatetimes($macroRelease) $datetime
        }
    } elseif {$type == "tc"} {
        if [info exists ::tcDatetimes($macroRelease)] {
            if {[lsearch -exact $::tcDatetimes($macroRelease) $datetime] == -1} { lappend ::tcDatetimes($macroRelease) $datetime }
        } else {
            lappend ::tcDatetimes($macroRelease) $datetime
        }
    }
}


proc addDatetimeCmp {type macroRelease datetimeCmp} {

    if {$type == "main"} {
        if [info exists ::datetimeCmps($macroRelease)] {
            if {[lsearch -exact $::datetimeCmps($macroRelease) $datetimeCmp] == -1} { lappend ::datetimeCmps($macroRelease) $datetimeCmp }
        } else {
            lappend ::datetimeCmps($macroRelease) $datetimeCmp
        }
    } elseif {$type == "utility"} {
        if [info exists ::utilityDatetimeCmps($macroRelease)] {
            if {[lsearch -exact $::utilityDatetimeCmps($macroRelease) $datetimeCmp] == -1} { lappend ::utilityDatetimeCmps($macroRelease) $datetimeCmp }
        } else {
            lappend ::utilityDatetimeCmps($macroRelease) $datetimeCmp
        }
    } elseif {$type == "hspice"} {
        if [info exists ::hspiceDatetimeCmps($macroRelease)] {
            if {[lsearch -exact $::hspiceDatetimeCmps($macroRelease) $datetimeCmp] == -1} { lappend ::hspiceDatetimeCmps($macroRelease) $datetimeCmp }
        } else {
            lappend ::hspiceDatetimeCmps($macroRelease) $datetimeCmp
        }
    } elseif {$type == "ibis"} {
        if [info exists ::ibisDatetimeCmps($macroRelease)] {
            if {[lsearch -exact $::ibisDatetimeCmps($macroRelease) $datetimeCmp] == -1} { lappend ::ibisDatetimeCmps($macroRelease) $datetimeCmp }
        } else {
            lappend ::ibisDatetimeCmps($macroRelease) $datetimeCmp
        }
    } elseif {$type == "repeater"} {
        if [info exists ::repeaterDatetimeCmps($macroRelease)] {
            if {[lsearch -exact $::repeaterDatetimeCmps($macroRelease) $datetimeCmp] == -1} { lappend ::repeaterDatetimeCmps($macroRelease) $datetimeCmp }
        } else {
            lappend ::repeaterDatetimeCmps($macroRelease) $datetimeCmp
        }
    } elseif {$type == "tc"} {
        if [info exists ::tcDatetimeCmps($macroRelease)] {
            if {[lsearch -exact $::tcDatetimeCmps($macroRelease) $datetimeCmp] == -1} { lappend ::tcDatetimeCmps($macroRelease) $datetimeCmp }
        } else {
            lappend ::tcDatetimeCmps($macroRelease) $datetimeCmp
        }
    }
}



proc addChangelist {type macroRelease changelist} {

    if {$type == "main"} {
        if [info exists ::changelists($macroRelease)] {
            if {[lsearch -exact $::changelists($macroRelease) $changelist] == -1} { lappend ::changelists($macroRelease) $changelist }
        } else {
            lappend ::changelists($macroRelease) $changelist
        }
    } elseif {$type == "utility"} {
        if [info exists ::utilityChangelists($macroRelease)] {
            if {[lsearch -exact $::utilityChangelists($macroRelease) $changelist] == -1} { lappend ::utilityChangelists($macroRelease) $changelist }
        } else {
            lappend ::utilityChangelists($macroRelease) $changelist
        }
    } elseif {$type == "hspice"} {
        if [info exists ::hspiceChangelists($macroRelease)] {
            if {[lsearch -exact $::hspiceChangelists($macroRelease) $changelist] == -1} { lappend ::hspiceChangelists($macroRelease) $changelist }
        } else {
            lappend ::hspiceChangelists($macroRelease) $changelist
        }
    } elseif {$type == "ibis"} {
        if [info exists ::ibisChangelists($macroRelease)] {
            if {[lsearch -exact $::ibisChangelists($macroRelease) $changelist] == -1} { lappend ::ibisChangelists($macroRelease) $changelist }
        } else {
            lappend ::ibisChangelists($macroRelease) $changelist
        }
    } elseif {$type == "repeater"} {
        if [info exists ::repeaterChangelists($macroRelease)] {
            if {[lsearch -exact $::repeaterChangelists($macroRelease) $changelist] == -1} { lappend ::repeaterChangelists($macroRelease) $changelist }
        } else {
            lappend ::repeaterChangelists($macroRelease) $changelist
        }
    } elseif {$type == "tc"} {
        if [info exists ::tcChangelists($macroRelease)] {
            if {[lsearch -exact $::tcChangelists($macroRelease) $changelist] == -1} { lappend ::tcChangelists($macroRelease) $changelist }
        } else {
            lappend ::tcChangelists($macroRelease) $changelist
        }
    }

}

proc addRelease {type macro release} {
    ## See if a pattern exists for the release.

    #    puts "addRelease $type $macro $release"

    if [regexp {_qadata$} $release dummy] {
        #	puts "Info:  Skipping $macro release $release"
        return 0
    }

    if [info exists ::releasePatt($macro)] {
        if {![string match $::releasePatt($macro) $release]} {
            ##  release does not match pattern.  Skip
            return 0
        } else {
        }

    }

    if {$type == "main"} {
        if [info exists ::releases($macro)] {
            if {[lsearch -exact $::releases($macro) $release] == -1} {
                lappend ::releases($macro) $release
            }
        } else {
            lappend ::releases($macro) $release
        }
        return 1

    } elseif {$type == "utility"} {
        if [info exists ::utilityReleases($macro)] {
            if {[lsearch -exact $::utilityReleases($macro) $release] == -1} {
                lappend ::utilityReleases($macro) $release
            }
        } else {
            lappend ::utilityReleases($macro) $release
        }
        return 1

    } elseif {$type == "hspice"} {
        if [info exists ::hspiceReleases($macro)] {
            if {[lsearch -exact $::hspiceReleases($macro) $release] == -1} {
                lappend ::hspiceReleases($macro) $release
            }
        } else {
            lappend ::hspiceReleases($macro) $release
        }
        return 1

    } elseif {$type == "ibis"} {
        if [info exists ::ibisReleases($macro)] {
            if {[lsearch -exact $::ibisReleases($macro) $release] == -1} {
                lappend ::ibisReleases($macro) $release
            }
        } else {
            lappend ::ibisReleases($macro) $release
        }
        return 1

    } elseif {$type == "repeater"} {
        if [info exists ::repeaterReleases($macro)] {
            if {[lsearch -exact $::repeaterReleases($macro) $release] == -1} {
                lappend ::repeaterReleases($macro) $release
            }
        } else {
            lappend ::repeaterReleases($macro) $release
        }
        return 1

    } elseif {$type == "tc"} {
        if [info exists ::tcReleases($macro)] {
            if {[lsearch -exact $::tcReleases($macro) $release] == -1} {
                lappend ::tcReleases($macro) $release
            }
        } else {
            lappend ::tcReleases($macro) $release
        }
        return 1

    } else {
        logError "Error:  Unrecognized type \"$type\" in addRelease"
        return 0
    }
}


proc doExit {} { exit }

proc doExecCRR {type} {

    puts $type
    return

    if [info exists ::relCRRP4] {
        set crrFiles [exec p4 files -e $::relCRRP4 2> /dev/null]
        if {$crrFiles == ""} {
            logError "Error:  $::relCRRP4 does not exist\n"
            return
        } else {
            exec p4 print -o crr.tmp $::relCRRP4
            logMsg "executing $::relCRRP4"
            file attributes crr.tmp -permissions "+x"

            set out [exec ./crr.tmp]
            logMsg $out
            file delete crr.tmp
        }
    } else {
        logError "Error:  CRR file undefined\n"
    }
}

proc doBuild {type} {

    if {$type == "main"} {
        upvar #0 releases releases
        upvar #0 changelists changelists
        upvar #0 datetimes datetimes
        upvar #0 descs descs
    } elseif {$type == "utility"} {
        upvar #0 utilityReleases releases
        upvar #0 utilityChangelists changelists
        upvar #0 utilityDatetimes datetimes
        upvar #0 utilityDescs descs
    } elseif {$type == "hspice"} {
        upvar #0 hspiceReleases releases
        upvar #0 hspiceChangelists changelists
        upvar #0 hspiceDatetimes datetimes
        upvar #0 hspiceDescs descs
    } elseif {$type == "ibis"} {
        upvar #0 ibisReleases releases
        upvar #0 ibisChangelists changelists
        upvar #0 ibisDatetimes datetimes
        upvar #0 ibisDescs descs
    } elseif {$type == "repeater"} {
        upvar #0 repeaterReleases releases
        upvar #0 repeaterChangelists changelists
        upvar #0 repeaterDatetimes datetimes
        upvar #0 repeaterDescs descs
    } elseif {$type == "tc"} {
        upvar #0 tcReleases releases
        upvar #0 tcChangelists changelists
        upvar #0 tcDatetimes datetimes
        upvar #0 tcDescs descs
    }

    set log [open "build_${type}$::ipReleaseName.log" "w"]
    puts $log "P4 Release Root: {$::releaseRoot}"
    puts $log "\n"

    if {$type == "main"} {set suffix ""} else {set suffix "_$type"}

    set relDir $::ipReleaseName$suffix
    if [file exists $relDir] {
        doClean $type
    } else {
        logMsg "Info:  Creating $relDir\n"
        file mkdir $relDir
    }

    if [info exists ::macroCRR] {
        logMsg "Info:  Using CRR-like build mechanism\n"
        ##  Use newer build process.
        foreach fileSpec $::macroCRR {
            set p4File [lindex $fileSpec 0]
            set buildFile [lindex $fileSpec 1]
            puts $log "Exporting $p4File"
            puts $log "\t--> $buildFile"
            logMsg "Exporting $p4File\n"
            set out [exec p4 print -o $buildFile $p4File]
        }
        logMsg "Done"
        return
    }

    foreach macro [lsort -ascii [array names releases]] {
        set macroType "$macro:$type"
        set release $::selectedRelease($macroType)
        if {$::numP4Roots > 1} {
            regexp {root(\d+)/(\S+)} $release dummy rootNum relName
            set root [lindex $::releaseRoot $rootNum]
        } else {
            set root $::releaseRoot
            set relName $release
        }
        set macroRelease "$type:$macro:$release"
        logMsg "Exporting $root/$macro/$relName ... "
        #	set root $::releaseRootMacro($macro)
        puts $log "$macro:  Release=$relName, root=$root, changelist=$changelists($macroRelease), date=$datetimes($macroRelease), desc=$descs($macroRelease)"
        foreach fileRec $::fileList($macroRelease) {
            set file [lindex $fileRec 0]
            set fileVer [lindex $fileRec 1]
            #	    puts "$root/$file   {$macro/$relName}"
            set dstFile [regsub "$macro/$relName" $file "$macro"]
            set dstFile "$relDir/$dstFile"
            #	    puts "\t$dstFile"
            set out [exec p4 print -o $dstFile "$root/ckt/rel/$file"]
        }
        logMsg "done\n"
    }
    logMsg "Info:  Export completed\n"
    close $log
}

proc checkRequiredFile {fileName} {
    if [file exists $fileName] {return 1}
    puts "Error:  Missing required file \"$fileName\""
    return 0
}

proc putVar {varName cfg mail} {
    global $varName

    if [info exists $varName] {
        set val [set $varName]
        puts $cfg "set $varName {$val}"
        if {$mail != 0} {
            puts $mail "\t$varName = $val"
        }
    } else {
        logError "Warning:  Variable \"$varName\" does not exist\n"
    }
}

proc doSnapshot {type} {

    ## Notes on enabling users for snapshot:
    ##  For global enablement, need to add user to //wwcad/msip/ude_conf/p4branch_permissions.csv
    ##  (/remote/cad-rep/msip/ude_conf/p4branch_permissions.csv).
    ##  To enable for a specific project, setenv p4branch_users "user1 user2 ..." in the pcs project.env

    if $::doSnapshotOnMail {
        ##  Going to do apcs snapshot.
        set snapUtil "/remote/cad-rep/msip/tools/CDtools/ude_utils/2017.07/scripts/msip_udeProjSnapBranch"
        ##                           --projectName <project_name>  mandatory, PCS name
        ##                           --releaseName <release_name>  mandatory, PCS release name
        ##                           --metalStack <metal_stack>    mandatory, metal_stack name
        ##                           --snapName <snapshot_name>    mandatory, name of the snapshot
        ##                           [--inCD]                      optional, defines whether run the script inside CDesigner, default is false
        ##                           [--help]                      optional, prints this message
        ##                           [--noBranch]                  optional, prints information about actions that are going to be performed
        ##                           [--remove]                    optional, used to delete a snapshot from depot
        ##                           [--override]                  optional, used to override the snapshot from depot if exists
        ##                           [--cleanup]                   optional, used to cleanup the snapshot in override mode
        ##                           [--mapProj]                   optional, used to add the project to global pcs client. Please use the option if you have access to "csadmin" account
        ##                           [--libList]                   optional, used to define libraries to branch. If not defined, all project libraries are branched by default
        ##                           [--pcsP4P]                    optional, used to specify the P4 port number used for PCS storage
        ##                           [--libP4P]                    optional, used to specify the P4 port number used for project libraries storage
        if {$type == "main"} {set type "ckt"}
        set ::snapName "${type}_rel$::ipReleaseName"
        set ::fullSnapName "${::pcsRelease}_snap_$::snapName"
        if {![info exists ::metalStack]} {
            logError "\"metal_stack\" is undefined in $::legalRelease; Required for snapshot"
            return
        }
        set err "udeProjSnapBranch_${::pcsType}-${::pcsName}-${::pcsRelease}-${::metalStack}.err"
        if [file exists $err] {file delete $err}
        set cmd "$snapUtil --projectType $::pcsType --projectName $::pcsName --releaseName $::pcsRelease --metalStack $::metalStack --snapName $::snapName --override 2> $err"
        logMsg "Info:  Executing snapshot \"$cmd\"\n"
        logMsg "Info:  Snapshot name:  $::fullSnapName\n"
        update
        catch {set o [exec {*}$cmd]}
        set ef [open $err r]
        set errData [read $ef]
        close $ef
        logError "$errData\n"
        ##	logMsg "$o\n"
        logMsg "Snapshot complete\n"
    }
}

proc doMail {type theProjPath runTiming flowStat} {
    ##  For the cases where there are multiple roots, the first is assumed to be the primary one.
    global relCRRP4
    global relConfigP4
    global topcellWaiver
    global thisScriptDir
    global testmode
    ##  Check the pincheck cleanliness
    set pcOK true
    set msg "Pincheck issues:\n"
    foreach macro [array names ::macroPincheckStatus] {
        puts "!!!  $::macroPincheckStatus($macro)"
        if {![regexp {Clean/Fresh} $::macroPincheckStatus($macro)]} {
            append msg "$macro:  $::macroPincheckStatus($macro)\n"
            lappend troubleList $macro
            set pcOK false
        }
    }
    set ::doMailProceed yes
    if {!$pcOK} {
        append msg "Proceed?\n"

        ##  I don't like the way the msgBox looks
        #        set answer [tk_messageBox -message $msg -type yesno]
        #        if {$answer == "no"} return
        ##  Pre-setting in case the dialog is just closed, defaults to "no"
        set ::doMailProceed no
        toplevel .proceedDialog
        pack [label .proceedDialog.msg -text $msg -fg red] -side top
        frame .proceedDialog.buttons
        pack [button .proceedDialog.buttons.yes -text "Yes" -command {doMailProceed yes}] -side left
        pack [button .proceedDialog.buttons.no -text "No" -command {doMailProceed no}] -side left
        pack .proceedDialog.buttons -side top
        set g [wm geometry .]
        if {[regexp {(\d+)x(\d+)\+(\d+)\+(\d+)} $g dmy w h x y]} {
            incr x 100
            incr y 100
        } else {
            set x 100
            set y 100
        }
        ## Put dialog over the main window
        wm geometry .proceedDialog "+$x+$y"
        tkwait window .proceedDialog
    }
    if {!$::doMailProceed} {
        logMsg "Mail cancelled\n"
        return
    }
    logMsg "Proceeding with Mail\n"


    doSnapshot $type
    set prefix $type
    set path "ckt/vcrel"
    if {$type == "main"} {
        upvar #0 releases releases
        upvar #0 changelists changelists
        upvar #0 datetimes datetimes
        upvar #0 descs descs
        set prefix "ckt"
        set mailDistVar ::releaseMailDist
    } elseif {$type == "utility"} {
        upvar #0 utilityReleases releases
        upvar #0 utilityChangelists changelists
        upvar #0 utilityDatetimes datetimes
        upvar #0 utilityDescs descs
        set prefix "utility"
        set mailDistVar ::releasePmMailDist
    } elseif {$type == "hspice"} {
        upvar #0 hspiceReleases releases
        upvar #0 hspiceChangelists changelists
        upvar #0 hspiceDatetimes datetimes
        upvar #0 hspiceDescs descs
        set mailDistVar ::releasePmMailDist
    } elseif {$type == "ibis"} {
        upvar #0 ibisReleases releases
        upvar #0 ibisChangelists changelists
        upvar #0 ibisDatetimes datetimes
        upvar #0 ibisDescs descs
        set mailDistVar ::releasePmMailDist
    } elseif {$type == "repeater"} {
        upvar #0 repeaterReleases releases
        upvar #0 repeaterChangelists changelists
        upvar #0 repeaterDatetimes datetimes
        upvar #0 repeaterDescs descs
        set prefix "repeater"
        set mailDistVar ::releasePmMailDist
    } elseif {$type == "tc"} {
        upvar #0 tcReleases releases
        upvar #0 tcChangelists changelists
        upvar #0 tcDatetimes datetimes
        upvar #0 tcDescs descs
        set mailDistVar ::releaseTCMailDist
    }
    set isEmptyCheck [lsort -ascii [array names releases]]
    if { $isEmptyCheck eq "" } {
        logError "Error: Nothing to release here. Aborting\n"
        return
    }
    set root1 [lindex $::releaseRoot 0]
    set relConfigP4nv "$root1/$path/${::ipReleaseNameVC}/${prefix}_release_${::ipReleaseName}.config"
    set relCRRP4nv    "$root1/$path/${::ipReleaseNameVC}/${prefix}_release_${::ipReleaseName}_crr.txt"
    #    set relCRRP4nv "$root1/release_${::ipReleaseName}_crr.txt"
    #    set relReadmeP4 "$root1/release_${::ipReleaseName}.readme"
    set relReadmeP4 "$root1/$path/${::ipReleaseNameVC}/${prefix}_release_${::ipReleaseName}_readme.txt"
    logMsg "Config = $relConfigP4nv\n"
    logMsg "CRR = $relCRRP4nv\n"
    logMsg "Readme = $relReadmeP4\n"
    ##  Check for readme existance.  Abort if not there.

    regexp -nocase {\/\/depot\/products\/.*\/project\/([a-z0-9_\-\.]+)} $root1 to theProj
    #catch { set theProd [exec /bin/tcsh -c "ls -d /remote/cad-rep/projects/*/*/ | grep $theProj"] }
    regexp -nocase {\/\/depot\/products\/(.*)\/project\/[a-z][0-9]{3}\-([a-z0-9\-]+)\-[0-9a-z\._\-]+} $root1 to theHProd theProd
    #regexp -nocase {.*\/projects\/([0-9a-z_]+)\/[a-z][0-9]{3}\-([a-z0-9\-]+)\-[0-9a-z\._]+\/} $theProd to theHProd theProd
    if { [regexp -nocase {\-} $theProd] } {
        set splitProd [split $theProd "-"]
        foreach match $splitProd {
            if { [lsearch -regexp $match $theHProd] >= 0 } { set theProd $match }
        }
    }
    if { $theProd eq "" } { logError "Error: Could not find correct product name\n" }
    set test [exec p4 files -e $relReadmeP4 2> /dev/null]
    if {$test == ""} {
        ##  No readme
        logError "Error:  $relReadmeP4 does not exist; Aborting\n"
        return
    } else {
        ##  Exists.  Check to see if it's checked out
        set o [exec p4 opened $relReadmeP4 2> /dev/null]
        ##  If returns nothing, file not open.  Otherwise open for write, abort
        if {$o != ""} {
            logError "Error:  $relReadmeP4 opened for write.  Aborting\n"
            return
        }
    }

    if [info exists $mailDistVar] {
        set mailDist [set $mailDistVar]
        logMsg "Info:  Mail distribution ($mailDistVar): $mailDist\n"
    } else {
        logError "Error: Mail distribution is undefined.  Use variable $mailDistVar\n"
        return
    }


    set test [exec p4 files -e $relConfigP4nv 2> /dev/null]
    if {$test == ""} {
        ##  File does not exist.  Create it.
        logMsg "Info:  Creating $relConfigP4nv\n"
        set addInfo [exec p4 add -t text $relConfigP4nv]
        set f [lindex $addInfo 0]
        regexp {\#(\d+)$}  $f dummy relConfigP4Version
    } else {
        ##  File exists.
        exec p4 sync $relConfigP4nv 2> /dev/null
        set f [lindex [exec p4 edit $relConfigP4nv] 0]
        regexp {\#(\d+)$}  $f dummy relConfigP4Version
        incr relConfigP4Version
    }

    set relConfigP4 "$relConfigP4nv#$relConfigP4Version"
    set t [exec p4 where $relConfigP4nv]
    set relConfigClient [lindex $t 2]
    logMsg "Info:  Writing $relConfigP4nv\n"

    set dName [file dirname $relConfigClient]
    if {![file exists $dName]} {file mkdir $dName}
    set CFG [open $relConfigClient "w"]

    set test [exec p4 files -e $relCRRP4nv 2> /dev/null]
    if {$test == ""} {
        ##  File does not exist.  Create it.
        set isFirstCRR 1
        logMsg "Info:  Creating $relCRRP4nv\n"
        set addInfo [exec p4 add -t text $relCRRP4nv]
        set f [lindex $addInfo 0]
        regexp {\#(\d+)$}  $f dummy relCRRP4Version
    } else {
        ##  File exists.
        set isFirstCRR 0
        exec p4 sync $relCRRP4nv 2> /dev/null
        set f [lindex [exec p4 edit $relCRRP4nv] 0]
        regexp {\#(\d+)$}  $f dummy relCRRP4Version
        incr relCRRP4Version
    }

    set relCRRP4 "$relCRRP4nv#$relCRRP4Version"

    set t [exec p4 where $relCRRP4nv]
    set relCRRClient [lindex $t 2]
    logMsg "Info:  Writing $relCRRP4nv\n"

    set dName [file dirname $relCRRClient]
    if {![file exists $dName]} {file mkdir $dName}
    set maxLen 0
    foreach macro [lsort -ascii [array names releases]] {
        if { [string length $macro] > $maxLen} { set maxLen [string length $macro] }
    }
    set MAIL [open "abmlogs/releaseMail.tmp" "w"]
    set tag [string toupper $prefix]
    if [file exists "abmlogs/noReleaseBranch"] {
        puts $MAIL "*************************** RELEASED WITHOUT RELEASE BRANCH CHECKS ***************************\n"
        file delete "abmlogs/noReleaseBranch"
    }
    if [file exists "abmlogs/initialBranch"] {
        puts $MAIL "*************************** INITIAL BRANCH ***************************\n"
    }
    puts $MAIL "Release Status:\n---------------------------------------------"
    set totResults {}
    regexp -nocase {([a-z0-9]+\/[0-9a-z\-\_\.]+)\/} $theProjPath to projP
    set shimMacs $::releaseShimMacro
    set phyvMacs $::releasePhyvMacro
    catch {set sisDirs [exec p4 dirs //wwcad/msip/projects/$projP/latest/design/timing/sis/"*" 2> /dev/null]}
    if {[info exists sisDirs] } {
        set sisDirs [split $sisDirs "\n"]
        set sisMacs {}
        foreach sd $sisDirs {
            regsub -all {\/\/.*\/sis\/} $sd "" sd
            lappend sisMacs $sd
        }
    } else {
        logMsg "WARNING: Unable to find SIS blocks in $theProjPath\n"
    }
    #   set scriptPath [ file dirname [ file normalize [ info script ] ] ]
    set alphaTimingCollateralScript "$thisScriptDir/alphaVerifyTimingCollateral.pl"
    foreach macro [lsort -ascii [array names releases]] {
        if { [regexp {app_note|tcoil_models|CKT_Special_Routing_Spec} $macro] } { continue }
        set checkResults ""
        set macroType "$macro:$type"
        set release $::selectedRelease($macroType)
        if {$::numP4Roots > 1} {
            regexp {root(\d+)/(\S+)} $release dummy rootNum relName
            set root [lindex $::releaseRoot $rootNum]
        } else {
            set root $::releaseRoot
            set relName $release
        }
        set p4Path "$root/ckt/rel/$macro/$relName/macro/..."
        if {[checkPinCheckExist $p4Path] == TRUE} {
            set pinCheckFile "$root/ckt/rel/$macro/$relName/macro/${macro}_pincheck_summary_file.txt"
        } elseif {[checkPinCheckExist $p4Path] == FALSE} {
            set pinCheckFile "$root/ckt/rel/$macro/$relName/macro/${macro}.pincheck"
        } else {
            dprint HIGH "$p4Path"
            dprint HIGH "Unexpected return from subroutine, pincheck missing!\n Contact developer!"
        }
        set macLen [string length $macro]
        set HLlog "$root/ckt/rel/$macro/$relName/macro/doc/qalogs/...hiprelynx_sum"
        set HLlogExist [exec p4 files -e $HLlog 2> /dev/null]
        set pinCheckExist [exec p4 files -e $pinCheckFile 2> /dev/null]
        if {$type != "ibis" && $type != "hspice"} {
            if {$HLlogExist == ""} {
                set checkResults "HL logs: MISSING "
            } else {
                set checkResults "HL logs: CLEAN   "
            }
            if { $runTiming } {
                if { [lsearch $shimMacs $macro] >= 0 } {
                } elseif { [lsearch $phyvMacs $macro] >= 0} {
                } elseif { [info exists sisMacs] && ([lsearch $sisMacs $macro] >= 0) }  {
                } else {
                    logMsg "Info:  Running verify timing collateral check on $macro\n"
                    set alphaVerifyTimingLog [exec $alphaTimingCollateralScript -project $theProjPath -macros $macro -log abmlogs/${macro}_TC.log]
                    catch { set isError [exec grep -i \"error\" abmlogs/${macro}_TC.log] }
                    if { [info exists isError] } {
                        logMsg "WARNING: Verify timing collateral not clean for $macro\n";
                        set checkResults "$checkResults, Timing QA: ERRORS  "
                    } else {
                        set checkResults "$checkResults, Timing QA: CLEAN   "
                    }
                }
            } else {
                set checkResults "$checkResults, Timing QA: SKIPPED "
            }
            if {$pinCheckExist == ""} {
                set checkResults "$checkResults, PinCheck: MISSING "
            } else {
                exec p4 print -o pinCheck.log $pinCheckFile
                catch {set checkErr [dict get $::pincheckInfo $release $macro status] }
                set checkResults "$checkResults, PinCheck: CLEAN  "
                file delete pinCheck.log
                file delete config.tmp
            }
        }
        set lenDiff [expr {$maxLen-$macLen}]
        set div	    [expr {$lenDiff/5+1}]
        set remain  [expr {$lenDiff%5}]
        if { $remain != 0 } {
            set div [expr {$div+1}]
        }
        if { [lsearch -exact $::releaseDefMacro $macro] >= 0} {
            set checkResults "defQA: NOT RUN"
            set totResults "$totResults\nfloorplans/$macro"
        } else {
            set totResults "$totResults\n$macro"
        }
        for {set im 0} { $im <= $div } {incr im} {
            set totResults "$totResults\t"
        }
        if {$type != "ibis" && $type != "hspice"} {
            set totResults "$totResults--> $checkResults"
        } else {
            set totResults "$totResults $checkResults"
        }
        #}

        puts $MAIL $totResults
        set out [exec p4 print -o readme.tmp $relReadmeP4]
        set README [open readme.tmp "r"]
        if { ![file exists "abmlogs/initialBranch"] } {
            puts $MAIL "\n--------------------------------------------------------------\nDatabase Integrity Status:"
            puts $MAIL "\tRelease Branch: $::releaseBranchName"
            puts $MAIL "\tProject Topcells Flow: PASS"
            puts $MAIL "\tRelease Branch Topcells Flow: PASS"
            if { [info exists topcellWaiver] } {
                puts $MAIL "\tTopcells report was NOT created within last 24 hours!! WAIVED -> $topcellWaiver"
            } else {
                puts $MAIL "\tTopcells report created within last 24 hours: PASS"
            }

        }
        puts $MAIL "--------------------------------------------------------------\nReadme:\n"
        while {[gets $README line] >= 0} {puts $MAIL $line}
        close $README
        file delete readme.tmp
        puts $MAIL "--------------------------------------------------------------\n"


        #    set banner "$tag Release Summary for ${::pcsType}/${::pcsName}/${::pcsRelease}, release $::ipReleaseName"
        set banner "$tag Release Summary for $::releaseRoot, release $::ipReleaseName"
        puts $MAIL $banner

        puts $CFG "## Config file for ${::pcsType}/${::pcsName}/${::pcsRelease}, IP release $::ipReleaseName"
        puts $CFG "set releaseType $type"
        putVar releaseRoot $CFG $MAIL
        putVar ipReleaseName $CFG $MAIL
        putVar ipReleaseNameVC $CFG $MAIL
        putVar relConfigP4 $CFG $MAIL
        putVar relCRRP4 $CFG $MAIL
        putVar pcsType $CFG $MAIL
        putVar pcsName $CFG $MAIL
        putVar pcsRelease $CFG $MAIL
        putVar releaseBranchName $CFG $MAIL
        putVar processName $CFG $MAIL
        #    putVar metalStack $CFG $MAIL
        ##  Not necessary, since it writes the filtered macroList.
        #    putVar releaseIgnoreMacro $CFG $MAIL
        putVar macroList $CFG 0
        putVar macroList $CFG 0
        putVar releaseUtilityMacro $CFG 0

        puts $MAIL "\tMacro/Version:"
        puts $CFG "set macroCRR \{"
        set releasePatt {}
        set crrLines {}
        set relqaLines {}
        set appNoteExists 0
        foreach macro [lsort -ascii [array names releases]] {
            set macroType "$macro:$type"
            set release $::selectedRelease($macroType)
            lappend releasePatt "set releasePatt($macro) $release"
            set changelist [string map {" " ,} $changelists($type:$macro:$release)]
            if { [lsearch $shimMacs $macro] >= 0 } {
                set macType "SHIM"
                } elseif { [lsearch $phyvMacs $macro] >= 0} { set macType "PHYV"
            } elseif { [lsearch $sisMacs $macro] >= 0}  {
                set macType "SIS"
            } else {
                set macType "MACRO"
                lappend timingMacs $macro
            }
            puts $MAIL "\t\t$macro/$release, $macType, changelist=$changelist"
            if {$::numP4Roots > 1} {
                regexp {root(\d+)/(\S+)} $release dummy rootNum relName
                set root [lindex $::releaseRoot $rootNum]
            } else {
                set root $::releaseRoot
                set relName $release
            }

            set macroRelease "$type:$macro:$release"
            #	set root $::releaseRootMacro($macro)
            if {$type == "main"} {set suffix ""} else {set suffix "_$type"}
            set relDir $::ipReleaseName$suffix
            foreach fileRec $::fileList($macroRelease) {
                set file [lindex $fileRec 0]
                set fileVer [lindex $fileRec 1]
                #	    puts "$root/$file   {$macro/$relName}"

                # ibis app-note does not follow the same directory convention
                if { ($type == "ibis") && ([regexp {_ibis_application_note.pdf} $fileRec])} {
                    set dstFile [regsub {.*templates/} $file ""]
                    set dstFile "$relDir/$dstFile"
                    puts $CFG "\t{$file#$fileVer $dstFile}"
                    if { $testmode == 1 } {
                        lappend crrLines "echo 'p4 sync -f $file#$fileVer' "
                    } else {
                        lappend crrLines "p4 sync -f '$file#$fileVer'"
                    }
                    lappend relqaLines "$file"
                    lappend filesInCRR "$file#$fileVer"
                } else {
                    set dstFile [regsub "$macro/$relName" $file "$macro"]
                    set dstFile "$relDir/$dstFile"
                    puts $CFG "\t{$root/ckt/rel/$file#$fileVer $dstFile}"
                    if { $testmode == 1 } {
                        lappend crrLines "echo 'p4 sync -f $root/ckt/rel/$file#$fileVer' "
                    } else {
                        lappend crrLines "p4 sync -f '$root/ckt/rel/$file#$fileVer'"
                    }
                    lappend relqaLines "$root/ckt/rel/$file"
                    if { ($type == "hspice") && ( ![regexp -nocase {\/hspice\/[0-9a-z_]+\/} $file ]) && (![regexp {app_note|tcoil_models} $file])} {
                        ## Resolve issue where symlink from one metal stack to another was being flagged as incorrect
                        set checkSymlink [exec p4 files $root/ckt/rel/$file]
                        if {![regexp {symlink} $checkSymlink]} {
                            lappend incorrectHspice "$root/ckt/rel/$file#$fileVer"
                        }
                    }
                    if { ($type == "hspice") && ([regexp {app_note|tcoil_models} $file]) } {
                        incr appNoteExists
                    }
                    lappend filesInCRR "$root/ckt/rel/$file#$fileVer"
                    #	    puts $MAIL "\t\t\t$root/$file#$fileVer"
                }
            }
        }
        puts $CFG " \}"

        #    foreach xx [array names ::changelists] {puts $xx}

        foreach p $releasePatt {
            puts $CFG $p
        }

        close $CFG

        if ($::doSnapshotOnMail) {
            puts $MAIL "\tInfo:  PCS snapshot name = $::fullSnapName"
        } else {
            puts $MAIL "\tInfo:  PCS snapshot not requested"
        }
        if { $type == "hspice" } {
            if { [info exists incorrectHspice] } {
                set incorrectHspice [ linsert $incorrectHspice 0 "--------------Hspice files not under metal stack directory--------------\n"]
                set theIgnoreStatus [confirmDialog $incorrectHspice "Incorrect HSPICE file format!"]
                if {$theIgnoreStatus == 0} { return }
            }
            if { $appNoteExists == 0 } {
                logError "Error: HSPICE app note \"HSPICE_model_app_note_<product>.pdf/.docx\" doesn't exist\n"
                logError "Error: Cannot proceed to release\n"
                return
            }
        }

        close $MAIL
        ## Check for zero size files in CRR
        set crrFiles [open "abmlogs/crrFiles.tmp" "w"]
        foreach crrfile $filesInCRR { puts $crrFiles $crrfile }
        close $crrFiles
        set checkZeroFiles [ catch {exec p4 -x "abmlogs/crrFiles.tmp" -e sizes | grep "\ 0\ bytes" | sed "s/\^info\: //g" | sed "s/\ 0\ bytes//g"} zeroErr ]
        if {$zeroErr ne "" } {
            foreach zr $zeroErr {
                if { [regexp -nocase {child|process|exited|abnormally} $zr] } { break }
                lappend zeroErrArr $zr
            }
        }
        if { [info exists zeroErrArr] } {
            set theIgnoreStatus [confirmDialog $zeroErrArr "Zero size files detected in CRR!"]
            if {$theIgnoreStatus == 0} { return }
        }
        ##  Reopen mail for read to copy contents to crr file
        set MAIL [open "abmlogs/releaseMail.tmp" "r"]
        set CRR [open "abmlogs/latest_crr.tmp" "w"]
        set qaRel [open "abmlogs/${type}_relqa.txt" "w"]
        while {[gets $MAIL line] >= 0} {puts $CRR "## $line"}
        close $MAIL
        puts $CRR "\n"
        foreach line $crrLines {puts $CRR $line}
        foreach line $relqaLines {puts $qaRel $line}
        close $qaRel
        close $CRR

        ##  Reopen mail for read to copy contents to crr file
        set MAIL [open "abmlogs/releaseMail.tmp" "a"]
        if { $isFirstCRR != 1 } {
            catch { exec p4 print -o abmlogs/current_crr.tmp $relCRRP4nv} errMsg
            ##############################################################################################
            ## Jira P10020416-36721
            ## Need to strip quotations when doing diff on CRR in the cases where only one have quotations
            exec tr -d \"\'\" < abmlogs/current_crr.tmp > abmlogs/current_crr_stripped.tmp
            exec tr -d \"\'\" < abmlogs/latest_crr.tmp > abmlogs/latest_crr_stripped.tmp
            ##############################################################################################
            set status [ catch { exec diff abmlogs/current_crr_stripped.tmp abmlogs/latest_crr_stripped.tmp \| egrep "\^\>" \| sed "s/\^\> p4 sync \\\-f //g" \| egrep "\/\/"} theOut]
            set oldChange ""
            set oldMacro ""
            foreach eachline $theOut {
                set patchView ""
                set patchFile ""
                if { [regexp -nocase {child|process|exited|abnormally|^diff|erro} $eachline] } { break }
                if { [regexp -nocase {ckt\/rel\/(floorplans)\/.*\/(.*)(\.def|\.csv)} $eachline to patchView patchMacro] } {
                } elseif { [regexp -nocase {ckt\/rel\/([a-z0-9_\-]+)\/.*\/macro\/([0-9a-z]+)\/} $eachline to patchMacro patchView] } {
                } elseif { [regexp -nocase {ckt\/rel\/([a-z0-9_\-]+)\/.*\/macro\/(.*)$} $eachline to patchMacro patchFile] } {
                } elseif { [regexp -nocase {ckt\/rel\/([a-z0-9_\-]+)\/.*\/(.*)} $eachline to patchView patchFile] } {
                } else {
                    continue
                }
                if { ![info exists patchMacro] } { set patchMacro "" }
                set newMacro $patchMacro
                if { $patchView ne "" } {
                    set newChange $patchView
                    if { $newMacro ne "" } {
                        if { $newMacro ne $oldMacro }   { lappend crrDiff "\n$newMacro --------------------------------------------------------------------------------------------------------------------------" }
                        if { $newChange ne $oldChange } { lappend crrDiff "\n    $newChange:" }
                    } else {
                        if { $newChange ne $oldChange } { lappend crrDiff "\n$patchView --------------------------------------------------------------------------------------------------------------------------" }
                    }
                    lappend crrDiff "        $eachline"
                    if { [info exists patches] } {
                        if { $patchMacro ne "" } {
                            if { [lsearch [dict keys $patches] $patchMacro] < 0 } { dict lappend patches $patchMacro "$patchView|"
                        } elseif { [lsearch [dict get $patches $patchMacro] $patchView] < 0} { dict lappend patches $patchMacro "$patchView|" }
                    } else {
                        if { [lsearch [dict keys $patches] $patchView] < 0 } { dict lappend patches $patchView }
                    }
                    } elseif { $newMacro ne "" } { dict lappend patches $patchMacro "$patchView|"
                    } else { dict lappend patches $patchView }
                } else {
                    set newChange $patchFile
                    if { $newMacro ne $oldMacro } { lappend crrDiff "\n$newMacro --------------------------------------------------------------------------------------------------------------------------" }
                    if { $newChange ne $oldChange } { lappend crrDiff "\n    other:" }
                    lappend crrDiff "        $eachline"
                }
                set oldChange $newChange
                set oldMacro $newMacro
            }
            if {[info exists patches]} {
                set theContinueStatus [confirmDialog $crrDiff "Changes from previous CRR" ]
                if { $theContinueStatus == 0 } { return }
                puts $MAIL "\nPatch Changes:\n--------------------------"
                foreach pMacro [dict keys $patches] {
                    set pList [dict get $patches $pMacro]
                    if {$pList ne "" } {
                        set pList [lsort -unique $pList]
                        puts $MAIL "$pMacro: $pList"
                    } else {
                        puts $MAIL $pMacro
                    }
                }
            } else {
                set reply [tk_dialog .nochange "No changes from previous CRR" "Do you still want to proceed to release?" \
                    questhead 0 Proceed Cancel]
                if { $reply == 1 } { return }
            }
            file delete abmlogs/current_crr.tmp
            file delete abmlogs/latest_crr.tmp
        }
        puts $MAIL "\nBuild command:\n\t$::thisScript -configP4 $relConfigP4"
        #if { ![file exists "abmlogs/initialBranch"] } { puts $MAIL "\n\n^ - Release branch checks performed without running topcells flow. Topcells status is taken from Topcells_report.txt of project and release branch" }
        close $MAIL

        ## Run only for MAIN release; Jira P10020416-35541
        if { $type == "main"} {
            #################################################
            ## Running defQA on the CRR. Jira P10020416-34027
            #################################################
            ## Making optional for now since there are issues: Jira P10020416-34178 - @kevinxie Apr 13/22
            set runDefQA [confirmDialog "Run defQA?" "Run defQA?"]
            if { $runDefQA == 1 } {
                #################################################
                ## Running defQA on the CRR. Jira P10020416-34027
                #################################################
                set defQAScript "$thisScriptDir/defQA.py"
                logMsg "Info:  Running defQA on $relCRRClient\n"
                #Adding legalRelease file path with DEFQA script as per JIRA P10020416-35541(by Dikshant Rohatgi)
                #Adding $projHome as per above mentioned JIRA
                set projHome "/remote/cad-rep/projects/$theProjPath"
                set legalRelease_def [firstAvailableFile $projHome/design/legalRelease.txt $projHome/design_unrestricted/legalRelease.txt]
                exec $defQAScript --crr $relCRRClient --legal $legalRelease_def
                set defQALog [open "defQA.log" "r"]
                while {[gets $defQALog line] >=  0} {
                    lappend defQALines "$line"
                }
                close $defQALog
                set defQA [confirmDialog $defQALines "defQA"]
                if { $defQA == 0 } {
                    return
                } else {
                    set MAIL [open "abmlogs/releaseMail.tmp" "r"]
                    set MAIL_WITH_DEF [open "abmlogs/releaseMail.def.tmp" "w"]
                    while {[gets $MAIL line] >= 0} {
                        set newline [string map {"defQA: NOT RUN" "defQA: CLEAN"} $line]
                        puts $MAIL_WITH_DEF $newline
                    }
                    close $MAIL
                    close $MAIL_WITH_DEF
                    file rename -force "abmlogs/releaseMail.def.tmp" "abmlogs/releaseMail.tmp"
                }
            }
        }
        #################################################

        ##  Reopen mail for read to copy contents to crr file

        set MAIL [open "abmlogs/releaseMail.tmp" "r"]
        set CRR [open $relCRRClient "w"]
        while {[gets $MAIL line] >= 0} {
            puts $CRR "## $line"
            lappend relMail "$line"
        }
        close $MAIL
        puts $CRR "\n"
        foreach line $crrLines {puts $CRR $line}
        close $CRR

        set releaseReview [confirmDialog $relMail "Release email Preview"]
        if { $releaseReview == 0 } { return }

        if { $testmode == 1 } {
            puts "TESTMODE: p4 submit -d AutoCreate $relConfigP4nv"
            puts "TESTMODE: p4 submit -d AutoCreate $relCRRP4nv"
        } else {
            set o [exec p4 submit -d "AutoCreate" $relConfigP4nv]
            set o [exec p4 submit -d "AutoCreate" $relCRRP4nv]
            logMsg $o
        }
        logMsg "Info:  Running CRR X-ray analysis..\n"
        #    set crrReport [ catch { exec $scriptPath/crr_X-ray.pl $relCRRP4nv} harvesterOut ]
        if { $testmode == 1 } {
            puts "TESTMODE: $thisScriptDir/crr_X-ray.pl $relCRRP4nv harvesterOut"
        } else {
            set crrReport [ catch { exec $thisScriptDir/crr_X-ray.pl $relCRRP4nv} harvesterOut ]
        }
        #if { [info exists harvesterOut] } { logErr "ERROR: $harvesterOut\n" }
        set analysisPath "$dName/crr_analysis"
        regexp {^([a-z0-9]{4})\-} $theProj to projNum
        set xrayOut "CRR_XRay-${prefix}-${projNum}-${::ipReleaseName}.xlsx";
        if { ![file exists $analysisPath] } {
            file mkdir $analysisPath
        }
        set isExistOut [exec p4 files -e "$analysisPath/$xrayOut" 2> /dev/null]
        if {$isExistOut == ""} {
            ##  File does not exist.  Create it.
            if { $testmode == 1 } {
                puts "TESTMODE: set addInfo p4 add -t text $analysisPath/$xrayOut"
            } else {
                set addInfo [exec p4 add -t text "$analysisPath/$xrayOut"]
            }
        } else {
            ##  File exists.
            if { $testmode == 1 } {
                puts "TESTMODE: exec p4 sync -f '$analysisPath/$xrayOut'"
                puts "TESTMODE: exec p4 edit '$analysisPath/$xrayOut'"
            } else {
                exec p4 sync -f "$analysisPath/$xrayOut" 2> /dev/null
                exec p4 edit "$analysisPath/$xrayOut" 2> /dev/null
            }
        }
        set isExistMail [exec p4 files -e "$analysisPath/${prefix}-${projNum}-${::ipReleaseName}_mail.txt" 2> /dev/null]
        if {$isExistMail == ""} {
            ##  File does not exist.  Create it.
            if { $testmode == 1 } {
                puts "TESTMODE: set addInfo exec p4 add -t text '$analysisPath/${prefix}-${projNum}-${::ipReleaseName}_mail.txt'"
            } else {
                set addInfo [exec p4 add -t text "$analysisPath/${prefix}-${projNum}-${::ipReleaseName}_mail.txt"]
            }
        } else {
            ##  File exists.
            if { $testmode == 1 } {
                puts "p4 sync -f '$analysisPath/${prefix}-${projNum}-${::ipReleaseName}_mail.txt'"
                puts "p4 edit '$analysisPath/${prefix}-${projNum}-${::ipReleaseName}_mail.txt'"
            } else {
                exec p4 sync -f "$analysisPath/${prefix}-${projNum}-${::ipReleaseName}_mail.txt" 2> /dev/null
                exec p4 edit "$analysisPath/${prefix}-${projNum}-${::ipReleaseName}_mail.txt" 2> /dev/null
            }
        }
        if { $testmode == 1 } {
            puts "TESTMODE: file copy -force "
        } else {
            file copy -force "$xrayOut" "$analysisPath/$xrayOut"
            file copy -force "./abmlogs/releaseMail.tmp" "$analysisPath/${prefix}-${projNum}-${::ipReleaseName}_mail.txt"
            set o [exec p4 submit -d "CRR-XRay analysis" "$analysisPath/$xrayOut"]
            set o [exec p4 submit -d "Release email" "$analysisPath/${prefix}-${projNum}-${::ipReleaseName}_mail.txt"]
            logMsg "Info:  Mailing release announcement to $mailDist\n"
            exec mail -s "$banner" -a "./$xrayOut" $mailDist < "abmlogs/releaseMail.tmp"
            #set bcmailDist "bhuvanc@synopsys.com"
            #exec mail -s "$banner" -a "./$xrayOut" $bcmailDist < "abmlogs/releaseMail.tmp"
        }

        catch { exec /remote/cad-rep/msip/tools/bin/msip_get_usage_info --tool_name alphaBuildMacroReleaseMail \
            --stage main --category ude_ext_1 \
                --tool_path NA --tool_version dev \
                & } sniff_msg

            ## Here is where QA happens
            logMsg "Info: Running release QA...\n"
            set relqaPath "$dName/relqa"
            if { ![file exists $relqaPath] } {
            file mkdir $relqaPath
        }
        set tagVar "${type}-${projNum}-${::ipReleaseName}"
        set config    "$relqaPath/$tagVar--config.cfg"
        set outputXLS "$relqaPath/$tagVar"

        set mm_path "//depot/products/$theHProd/common/qms/templates/MM"
        checkP4Mapping "$mm_path"
        set mm_versions [exec p4 dirs "$mm_path/*" 2> /dev/null]
        if { $mm_versions ne "" } {
            set latestMMVer ""
            foreach mmv $mm_versions {
                regexp {.*\/([\w+\.]+)$} $mmv to mmVer
                if { $mmVer > $latestMMVer } { set latestMMVer $mmVer }
                lappend allMMVers "$mmVer"
            }
            if { [lsearch $allMMVers $::bomVersion] == -1 } { set bom_version $latestMMVer }

            set manifest [exec p4 files $mm_path/$bom_version/...xlsx]
            regexp -nocase {(.*)\#.*} $manifest to manifest

            if { $testmode == 1} {
                puts "TESTMODE: exec p4 sync -f '$manifest'"
            } else {
                exec p4 sync -f $manifest 2> /dev/null
            }

            set manifest [exec p4 have $manifest | sed -e "s/^.*\\-\\s//g" ]

            set xlsReport "$outputXLS--report.xlsx"
            set isExistOut [exec p4 files -e $xlsReport 2> /dev/null]

            if {$isExistOut == ""} {
                ##  File does not exist.  Create it.
                if { $testmode == 1} {
                    puts "TESTMODE: set addInfo 'exec p4 add -t text $xlsReport'"
                } else {
                    exec touch "$xlsReport"
                    set addInfo [exec p4 add -t text $xlsReport]
                }
            } else {
                ##  File exists.
                if { $testmode == 1 } {
                    puts "TESTMODE: exec p4 sync -f '$xlsReport'"
                    puts "TESTMODE: exec p4 edit '$xlsReport'"
                } else {
                    exec p4 sync -f $xlsReport 2> /dev/null
                    exec p4 edit $xlsReport
                }
            }

            set isExistOut [exec p4 files -e "$config" 2> /dev/null]
            if {$isExistOut == ""} {
                ##  File does not exist.  Create it.
                if { $testmode == 1} {
                    puts "TESTMODE: set addInfo exec p4 add -t text '$config'"
                } else {
                    exec touch "$config"
                    set addInfo [exec p4 add -t text "$config"]
                }
            } else {
                ##  File exists.
                if { $testmode == 1 } {
                    puts "TESTMODE: exec p4 sync -f '$config'"
                    puts "TESTMODE: exec p4 edit '$config'"
                } else {
                    exec p4 sync -f "$config" 2> /dev/null
                    exec p4 edit "$config"
                }
            }

            #puts "Running config $manifest gen_ckt_cell_cfgs.pl -proj $theProjPath -phase $flowStat -manifest $manifest -output $config -release $type"

            set RUNQA [open "abmlogs/${type}_qa.sh" "w" ]

            puts $RUNQA "#!/bin/csh"
            puts $RUNQA "module unload bom-checker"
            puts $RUNQA "module load bom-checker"

            puts $RUNQA "gen_ckt_cell_cfgs.pl -proj $theProjPath -phase $flowStat -manifest $manifest -output $config -release $type"
            puts $RUNQA "alphaDepotRelChecker.pl -cfg $config -rel abmlogs/${type}_relqa.txt -log $outputXLS"
            puts $RUNQA "\n";
            close $RUNQA

            catch {exec chmod +x abmlogs/${type}_qa.sh}

            set qa_output [ catch { exec "./abmlogs/${type}_qa.sh" } qaOut ]

            set status_line [lsearch -regexp -inline [split $qaOut "\n"] "FAIL|PASS|ERR\!"]
            regexp {(FAIL|PASS|ERR\!)}  $status_line line qaStatus

            if { $testmode == 1} {
                puts "TESTMODE: "
            } else {
                set o [exec p4 submit -d "Submitting relQA config" $config]
                set o [exec p4 submit -d "Submitting relQA report" $xlsReport]

                #puts $qaOut
                #puts "Emailing... "
                exec mail -s "$qaStatus: Release QA on '$flowStat' $tagVar" -a "$xlsReport" -a "$config" "kevinxie,maisha,juliano" < "$outputXLS--stdout.log"
                #file delete {*}[glob $outputXLS*.log]
            }
        } else {
            set BODY [open "abmlogs/no_mm.txt" "w"]
            puts $BODY "Product $theProd does not have Master manifest\n"
            puts $BODY "$tagVar\n"
            close $BODY
            if { $testmode == 1 } {
                puts "TESTMODE: mail message and delete abmlogs/no_mm.txt"
            } else {
                exec mail -s "ATTN: MM not available for $theProd" "kevinxie,maisha,juliano" < "abmlogs/no_mm.txt"
                file delete "abmlogs/no_mm.txt"
            }
        }

        if { $testmode == 1 } {
            puts "TESTMODE: doing some file deletes"
        } else {
            file delete "./$xrayOut"
            file delete "abmlogs/crrFiles.tmp"
            file delete "abmlogs/releaseMail.tmp"
            file delete "abmlogs/initialBranch"
        }

    }

    proc checkP4Mapping { p4path } {
        catch { exec p4 where $p4path/... 2> /dev/null } p4where
        if { $p4where eq "" } {
            set p4client $::env(P4CLIENT)
            regexp {\/\/(.*)} $p4path to noSlash
            set addView "$p4path/... //$p4client/$noSlash/..."
            catch { exec p4 --field "View+=$addView" client -o $p4client | p4 client -i } mapErr
        }
    }

    proc confirmDialog {contents theMsg} {
        global proceedStatus
        global wincounter
        set w .dialog[incr wincounter]
        toplevel $w
        set fframe $w.files
        frame $fframe
        pack [text $fframe.out -height 10 -width 110 -yscrollcommand "$fframe.scroll set" -state disabled -font "MyDefaultFont 9"] -expand 1 -fill both -side left
        pack [scrollbar $fframe.scroll -command "$fframe.out yview"] -side right -fill y
        pack $fframe -expand 1 -fill both
        foreach ze $contents {
            $fframe.out config -state normal
            $fframe.out insert end "$ze\n"
            $fframe.out see end
            $fframe.out config -state disabled
            update
        }
        #frame $w.msg
        #pack [label $w.msg -text "Proceed to release?"]
        #pack $w.msg -side bottom
        #pack $w.msg -side top -padx 4 -pady 4
        set eframe $w.buttons
        frame $eframe
        pack [button $eframe.proceed -text "Proceed" -command {set proceedStatus 1}] -side left
        pack [button $eframe.cancel -text "Cancel" -command {set proceedStatus 0} ] -side left
        pack $eframe -side bottom
        wm title $w $theMsg
        #wm label
        wm withdraw $w
        bind modalDialog <ButtonPress> {
            wm deiconify %W
            raise %W
        }
        bindtags $w [linsert [bindtags $w] 0 modalDialog]
        wm protocol $w WM_DELETE_WINDOW {
            set proceedStatus 0
            #$w.cancel invoke
        }
        set oldFocus [focus]
        wm deiconify $w
        catch {tkwait visibility $w}
        catch {grab set $w}
        tkwait variable proceedStatus
        grab release $w
        focus $oldFocus
        wm withdraw $w
        return $proceedStatus
    }


    proc waiveDialog {message title} {
        tk_setPalette snow
        set input [tk_dialog .wdlg "$title" "$message" warning 0 "Waive & Proceed" "Exit"]
        switch $input {
            0 { waiverWindow }
            1 { exit }
        }
    }

    proc waiverWindow {} {
        global topcellWaiver
        tk_setPalette snow
        set proceed ""
        set w .form
        toplevel $w
        wm title $w "Waiver Form"
        label $w.l -text "Enter Waiver:"
        entry $w.e -width 60 -relief sunken -bd 2 -textvariable waiver
        focus $w.e
        pack $w.l $w.e -side left -fill x
        set bframe $w.buttons
        frame $bframe
        pack [ button $bframe.b1 -text Proceed -command enterWaiver] -side left
        bind $w.e <KeyPress-Return> enterWaiver
        pack [ button $bframe.b2 -text Exit -command {exit } ] -side left
        pack $bframe -side bottom -fill x
        wm withdraw $w
        bind modalDialog <ButtonPress> {
            wm deiconify %W
            raise %W
        }
        bindtags $w [linsert [bindtags $w] 0 modalDialog]
        set oldFocus [focus]
        wm deiconify $w
        catch {tkwait visibility $w}
        catch {grab set $w}
        tkwait variable proceed
        grab release $w
        focus $oldFocus
        wm withdraw $w
    }

    proc doClean {type} {

        if {$type == "main"} {set suffix ""} else {set suffix "_$type"}

        set relDir $::ipReleaseName$suffix
        if [file exists $relDir] {
            if [file isdirectory $relDir] {
                ##  Exists, and is directory.  Flush it.
                set files [glob -nocomplain "$relDir/*"]
                foreach f $files {
                    logMsg "Info:  Deleting $f\n"
                    file delete -force $f
                }
            } else {
                logError "Error:  $relDir exists, and is not a directory\n"
                return
            }
        }
    }

    proc checkRequiredVariable {varName} {
        global $varName

        if [info exists $varName] {return 1}
        puts "Error:  Variable \"$varName\" is undefined"
        return 0

    }

    proc lockGuiForConfig {} {
        ##  Based on the type of release, lock the gui pages.
        if {![info exists ::releaseType]} {
            ##  For backward compatibility
            set ::releaseType "main"
        }
        set type $::releaseType
        set ::tabState($::releaseType) "normal"
        set ::startTab "${type}tab"
        foreach type {main utility ibis hspice repeater tc} {
            if {$type != $::releaseType} {set ::tabState($type) "disabled"}
        }
    }

    proc processConfig {configFile} {
        if [file exists $configFile] {
            set ::configFile $configFile
            uplevel {source $configFile}
            lockGuiForConfig
        } else {
            puts "Error:  $configFile does not exist"
        }
    }

    proc processConfigP4 {configFile} {
        ##  Processes a config file presented as a p4 depot file
        ##  Exports to "config.tmp", sources then deletes.
        set configFiles [exec p4 files -e $configFile 2> /dev/null]
        if {$configFiles == ""} {
            logError "Error:  $configFile does not exist\n"
            return
        } else {
            exec p4 print -o config.tmp $configFile
            uplevel {source config.tmp}
            file delete config.tmp
            lockGuiForConfig
        }
    }

    proc processProject {projPath flowStat} {
        file delete "abmlogs/initialBranch"
        #    set projHome "$::env(MSIP_PROJ_ROOT)/$projPath"
        set projHome "/remote/cad-rep/projects/$projPath"
        set theProjPath $projPath
        set projEnv "$projHome/cad/project.env"
        if {![file exists $projEnv]} {
            puts "ERROR: Projects \"$projPath\" does not exist"
            exit
        }
        set topcellsReportStat 0
        set t [split $projPath "/"]
        set ::pcsType [lindex $t 0]
        set ::pcsName [lindex $t 1]
        set ::pcsRelease [lindex $t 2]

        #    set legalMacros "$projHome/design/legalMacros.txt"
        #    set legalRelease "$projHome/design/legalRelease.txt"

        regexp -nocase {(.*\/.*\/).*} $projPath to tempPath
        #set legalMacros [firstAvailableFile $projHome/design/legalMacros.txt $projHome/design_unrestricted/legalMacros.txt]
        set topcells [firstAvailableFile $projHome/design/topcells.txt $projHome/design_unrestricted/topcells.txt]
        set ::legalRelease [firstAvailableFile $projHome/design/legalRelease.txt $projHome/design_unrestricted/legalRelease.txt]
        #set ::legalRelease "/u/bhuvanc/legalRelease.txt"
        set topCellsReport [firstAvailableFile $projHome/design/Topcells_report.txt $projHome/design_unrestricted/Topcells_report.txt]
        set OK true
        #if {$legalMacros == ""} {set OK false}
        if {$topcells == ""} {set OK false}
        if {$::legalRelease == ""} {
            set OK false
        } else {
            source $::legalRelease
        }
        if {[info exists releaseBranch]} {
            set relNameCheck $releaseBranch
        } else {
            puts "INFO:  releaseBranch variable not defined in legalRelease.txt"
            regexp -nocase {\/(rel[0-9a-z\.\_]+)} $projPath to tempRelVer
            puts "INFO:  ReleaseBranch set to ${tempRelVer}_${rel}_rel_"
            set relNameCheck "${tempRelVer}_${rel}_rel_"
        }

        set topCellsRB [firstAvailableFile /remote/cad-rep/projects/${tempPath}${relNameCheck}/design/Topcells_report.txt /remote/cad-rep/projects/${tempPath}${relNameCheck}/design_unrestricted/Topcells_report.txt]

        if { $flowStat ne "initial" } {
            if {$topCellsReport == ""} {set OK false}
            if {($topCellsRB == "")} {set OK false}
            if {!$OK} {
                puts "Aborting on missing file(s)"
                exit
            }
            puts "INFO:  Checking topcells report..."
            catch {set tcrStatus [exec grep "Verification Results:" $topCellsReport 2> /dev/null]}
            if {[info exists tcrStatus]} {
                regexp {Verification Results: ([A-Z]+)} $tcrStatus -> tcrStat
                if {$tcrStat != "PASS"} {
                    puts "ERROR: Topcells report status is FAIL in $topCellsReport"
                    puts "INFO:  Please run topcells flow and make sure it has status: PASS\r"
                    puts "INFO:  Aborting release process..."
                    exit
                } else {
                    puts "INFO:  Project Topcells report - OK"
                }
            } else {
                puts "ERROR: Cannot find topcells results status"
                puts "INFO:  Please check and re-run topcells report\r"
                exit
            }
            catch {set tcrStatusRB [exec grep "Verification Results:" $topCellsRB 2> /dev/null]}
            if {[info exists tcrStatusRB]} {
                regexp {Verification Results: ([A-Z]+)} $tcrStatusRB -> tcrStatRB
                if {$tcrStatRB != "PASS"} {
                    puts "ERROR: Topcells report status is FAIL in $topCellsRB"
                    puts "INFO:  Please run topcells flow and make sure it has status: PASS\r"
                    puts "INFO:  Aborting release process..."
                    exit
                } else {
                    puts "INFO:  Release branch Topcells report - OK"
                }
            } else {
                puts "ERROR: Cannot find topcells results status"
                puts "INFO:  Please check and re-run topcells report\r"
                exit
            }

            # Project topcells report
            set currDate [clock scan [clock format [clock seconds] -format {%m/%d/%Y}] -format {%m/%d/%Y}]
            set tcEDMsgs ""
            catch {set tcrDate [exec grep "Execution Date:" $topCellsReport 2> /dev/null]}
            if {[info exists tcrDate]} {
                regexp {Execution Date:([\d\/]+)} $tcrDate -> tcrDate
                set tcrDate [clock scan $tcrDate -format {%m/%d/%Y}]
                set diffd [expr {$currDate-$tcrDate}]
                if {[expr {$currDate-$tcrDate}] > 86400} {
                    puts "WARNING: PCS Release Topcells report was not created within last 24 hours"
                    lappend tcEDMsgs "PCS Release Topcells report was not created within last 24 hours\n"
                }
            } else {
                puts "ERROR: Cannot find topcells Execution Date"
                puts "INFO:  Please check topcells report and re-run\r"
                exit
            }
            catch {set tcrDateRB [exec grep "Execution Date:" $topCellsRB 2> /dev/null]}
            if {[info exists tcrDateRB]} {
                regexp {Execution Date:([\d\/]+)} $tcrDateRB -> tcrDateRB
                set tcrDateRB [clock scan $tcrDateRB -format {%m/%d/%Y}]
                set diffd [expr {$currDate-$tcrDateRB}]
                if {[expr {$currDate-$tcrDateRB}] > 86400} {
                    puts "WARNING: Release branch Topcells report was not created within last 24 hours"
                    lappend tcEDMsgs "Release branch Topcells report was not created within last 24 hours\n"
                }
            } else {
                puts "ERROR: Cannot find topcells Execution Date"
                puts "INFO:  Please check topcells report and re-run\r"
                exit
            }
            if { $tcEDMsgs ne "" } {
                waiveDialog "Topcells report was not created within last 24 hours" "Topcells execution time error"
            }

        } else {
            puts "INFO: Skipping database integrity checks"
            file delete "abmlogs/initialBranch"
            set theINIT [open "abmlogs/initialBranch" "w"]
            puts $theINIT "This is initial branch"
            close $theINIT
        }
        ##  Populate macroList from the legalMacros file
        #    set m [open $legalMacros "r"]
        #    while {[gets $m line] >= 0} {
        #	##  Uncomment
        #	set line [regsub {\#.*} $line ""]
        #	##  Strip whitespace
        #	set line [string trim $line " \t"]
        #	if {$line != ""} {
        #	    set toks [split $line "/"]
        #	    if {[llength $toks] == 2} {
        #		set mcr [lindex $toks 1]
        #		lappend ::macroList $mcr
        #	    } else {
        #		puts "ERROR: Bad line in $legalMacros:"
        #		puts "\t\"$line\""
        #	    }
        #	}
        #    }
        #    puts $::macroList
        #    puts "\n--------\n"
        #    close $m

        ##  Populate macroList from the topcells file
        set m [open $topcells "r"]
        while {[gets $m line] >= 0} {
            ##Uncomment
            set line [regsub {\#.*} $line ""]
            ## Strip whitespace
            set line [string trim $line " \t"]
            if {$line != ""} {
                set line [regsub {\[LAY\]} $line ""]
                set line [regsub {\[SCH\]} $line ""]
                set line [regsub {\/layout} $line ""]
                set line [regsub {\/schematic} $line ""]
                set toks [split $line "/"]
                if {[llength $toks] == 2} {
                    set mcr [lindex $toks 1]
                    lappend ::macroList $mcr
                } else {
                    puts "ERROR: Bad line in $topcells:"
                    puts "\t\"$line\""
                }
            }
        }
        set counters {}
        foreach item $::macroList { dict incr counters $item }
        dict for {item count} $counters {
            if {[regexp -nocase {cover} $item]} { lappend ::finalMacroList $item }
            if {$count == 2} { lappend ::finalMacroList $item }
        }
        lsort -unique $::finalMacroList
        set ::macroList $::finalMacroList
        close $m

        source $::legalRelease
        if [info exists p4_release_root] {
            foreach xx $p4_release_root {lappend ::releaseRoot "//depot/$xx"}
        }
        if {[info exists rel]} {
            set ::ipReleaseName $rel
            set ::ipReleaseNameVC $rel

        }
        if {[info exists vcrel]} {set ::ipReleaseNameVC $vcrel}
        if {[info exists process]} {set ::processName $process}
        if {[info exists releaseBranch]} {set ::releaseBranchName $releaseBranch }
        if {[info exists metal_stack]} {set ::metalStack $metal_stack}
        if {[info exists metal_stack_cover]} {set ::metalStackCover $metal_stack_cover}
        if {[info exists metal_stack_ip]} {set ::metalStackIp $metal_stack_ip}
        if {[info exists releaseMailDist]} {set ::releaseMailDist $releaseMailDist}
        if {[info exists releasePmMailDist]} {set ::releasePmMailDist $releasePmMailDist}
        if {[info exists releaseTCMailDist]} {set ::releaseTCMailDist $releaseTCMailDist}
        if {[info exists releasePhyvMacro]} {set ::releasePhyvMacro $releasePhyvMacro} else { set ::releasePhyvMacro {} }
        if {[info exists releaseShimMacro]} {
            set ::releaseShimMacro $releaseShimMacro
            foreach smac $::releaseShimMacro {
                lappend ::macroList $smac
            }
        } else {
            set ::releaseShimMacro {}
        }
        if [info exists releaseIgnoreMacro] {set ::releaseIgnoreMacro $releaseIgnoreMacro}
        if [info exists releaseIgnoreMacroIbis] {set ::releaseIgnoreMacroIbis $releaseIgnoreMacroIbis}
        if [info exists releaseIgnoreMacroHspice] { set ::releaseIgnoreMacroHspice $releaseIgnoreMacroHspice }
        ## the utility cells library cell contains all utility macros, so we only release it
        if [info exists utility_name] {set ::releaseUtilityMacro $utility_name } else { set ::releaseUtilityMacro "dwc_ddrphy_utility_cells" }
        if [info exists repeater_name] { set ::releaseRepeaterMacro $repeater_name } else { set ::releaseRepeaterMacro "dwc_ddrphy_repeater_cells" }
        if [info exists releaseTCMacro] { set ::releaseTCMacro $releaseTCMacro } else { set ::releaseTCMacro {} }
        if [info exists releaseDefMacro] { set ::releaseDefMacro $releaseDefMacro } else { set ::releaseDefMacro {} }
        if [info exists bomVersion] {set ::bomVersion $bomVersion} else { set ::bomVersion "Latest" }
    }

    # When running unit tests, we do not want the bulk of the code to run.
    # We just want to make the proc names available.
    # So, for now the unit test script will set a global var to tell this script
    # not to run the mainline code. don't execute anything other than defining
    # procs.
    if { [info exists ::DDR_DA_UNIT_TEST] } {
        return
    }

    set i 0
    set nArg [llength $argv]
    if {$nArg == 0} {
        showUsage
        exit
    }

    #creating log directory
    if {![file exists abmlogs ]} {file mkdir abmlogs}

    set startTab "maintab"

    set doWaive  [lsearch -all -regexp $argv "-skipTimingCheck"]

    set isInitial  [lsearch -all -nocase -regexp $argv "-initial"]
    set isFinal    [lsearch -all -nocase -regexp $argv "-final"]
    set isPrefinal [lsearch -all -nocase -regexp $argv "-prefinal"]
    set isPrelim   [lsearch -all -nocase -regexp $argv "-prelim"]

    if { $isFinal eq "" && $isPrefinal eq "" && $isPrelim eq "" && $isInitial eq "" } {
        puts "ERROR: Please specify release phase: -initial or -prelim or -prefinal or -final"
        exit
    }

    if { $isFinal ne "" } { set flowStat "final"
    } elseif { $isPrefinal ne "" } { set flowStat "prefinal"
    } elseif { $isPrelim ne "" } { set flowStat "prelim"
    } elseif { $isInitial ne "" } { set flowStat "initial"
    } else { set flowStat "initial" }

    if { [string trimleft $doWaive] == "" } {
        set runTiming 1
    } else {
        set runTiming 0
        puts "WARNING: Skipping verify timing collateral check"
    }

    while {$i < $nArg} {
        set argName [lindex $argv $i]
        if {$argName == "-config"} {
            incr i
            set theProjPath ""
            processConfig [lindex $argv $i]
            set mailButtonState "disabled"
        }
        if {$argName == "-configP4"} {
            incr i
            set theProjPath ""
            processConfigP4 [lindex $argv $i]
            set mailButtonState "disabled"
        }
        if {$argName == "-project"} {
            incr i
            set theProjPath [lindex $argv $i]
            processProject [lindex $argv $i] $flowStat
            set mailButtonState "normal"
        }
        incr i
    }

    ##  Check the required variables
    set OK true
    if {![checkRequiredVariable pcsType]} {set OK false}
    if {![checkRequiredVariable pcsName]} {set OK false}
    if {![checkRequiredVariable pcsRelease]} {set OK false}
    if {![checkRequiredVariable ipReleaseName]} {set OK false}
    if {![checkRequiredVariable processName]} {set OK false}
    #if {![checkRequiredVariable metalStack]} {set OK false}
    if {![checkRequiredVariable releaseRoot]} {set OK false}
    if {!$OK} {
        puts "Aborting on missing required variable(s)"
        exit
    }

    set ::numP4Roots [llength $releaseRoot]

    set home [pwd]

    proc exitApp {} {
        if [info exists ::LOG] {close $::LOG}
        exit
    }

    proc addReleaseInfo {type macro release file version changelist datetime desc view} {
        set macroRelease "$type:$macro:$release"
        set datetimeCmp [regsub -all {[/:]} $datetime ""]

        ##  Check to see if the provided file is relevant to pincheck
        set pincheckRelated false
        foreach p $::pincheckAssocPattList {
            if {[regexp -nocase [subst -nocommands $p] $file]} {
                set pincheckRelated true
                break
            }
        }

        ##  Keep track of the latest pincheck-related-view checking times, indexed by release
        if {$pincheckRelated} {
            set t [clock scan $datetime -format "%Y/%m/%d:%T"]
            if {[dict exists ::pincheckMacroReleaseChecks $release $macro]} {
                if {$t > [dict get $::pincheckMacroReleaseChecks $release $macro]} {
                    dict set ::pincheckMacroReleaseChecks $release $macro $t
                }
            } else {
                dict set ::pincheckMacroReleaseChecks $release $macro $t
            }
        }

        if [addRelease $type $macro $release] {
            addChangelist $type $macroRelease $changelist
            addDatetime $type $macroRelease $datetime
            addDatetimeCmp $type $macroRelease $datetimeCmp
            addDesc $type $macroRelease $desc
            set viewList [list]
            if {[info exists ::changelistInfo($changelist)]} {set viewList [dict get $::changelistInfo($changelist) viewList]}
            if {$view != ""} {
                if {[lsearch -nocase -exact $viewList $view] == -1} {lappend viewList $view}
            }
            set ::changelistInfo($changelist) [dict create datetime $datetime desc $desc viewList $viewList]
            lappend ::fileList($macroRelease) [list $file $version $changelist $datetime]
        }
    }

    set fontSize 8
    set wincounter 0
    #puts [font actual TkDefaultFont]
    set TkDefaultFontAttr [font actual TkDefaultFont]
    set TkTextFontAttr [font actual TkTextFont]
    ##  Mke copy of default font, change size to 10
    font create MyDefaultFont {*}$TkDefaultFontAttr
    font configure MyDefaultFont -size $fontSize

    ##  For config-driven usage, tabState will be properly defined.  If not defined, set to normal for -project driven behavior
    foreach type {main utility ibis hspice repeater tc} {
        if {[info exists ::tabState($type)]} {
            #	puts "Info:  tabState($type) - $tabState($type)"
        } else {
            set ::tabState($type) "normal"
        }
    }


    ## From http://www.tcl.tk/man/tcl8.5/TkCmd/ttk_notebook.htm
    #pack [ttk::notebook .nb -height 500 -width 1500]

    tk_setPalette snow
    pack [ttk::notebook .nb ] -fill both -expand yes
    ttk::style configure TFrame -background snow -height 600

    set ml [llength $macroList]
    set ml [ expr {int(ceil(double($ml*65)/100.0))} ]
    set ml "${ml}c"
    foreach type { main utility ibis hspice repeater tc} {
        set tabTitle [string toupper $type]
        ## Add frames
        .nb add [frame .nb.${type}tab]     -text "$tabTitle"
        ## Create Canvas
        if { $type eq "main" } { canvas .nb.${type}tab.c     -width 150 -height 500 -yscrollcommand ".nb.${type}tab.yscroll set"     -background snow -scrollregion "0 0 30 $ml"
        } else {    canvas .nb.${type}tab.c  -width 150 -height 500 -yscrollcommand ".nb.${type}tab.yscroll set"  -background snow  -scrollregion "0 0 0c 13c"}
        ## Create vertical scrollbar
        scrollbar .nb.${type}tab.yscroll     -command ".nb.${type}tab.c yview"
        ## Setup grid
        grid .nb.${type}tab.yscroll     -row 0 -column 1 -rowspan 1 -columnspan 1 -sticky news
        ## Pack scrollbar
        pack .nb.${type}tab.yscroll     -side right -fill y
        ## Pack canvas
        pack .nb.${type}tab.c     -expand yes -fill both -side top

        ## Create buttons for Clean/Mail/Build
        set frame .nb.${type}tab.c.bt
        frame $frame -borderwidth 1 -relief solid
        button $frame.clean -text "Clean" -command "doClean $type" -font MyDefaultFont
        button $frame.mail -text "Mail" -command "doMail $type $theProjPath $runTiming $flowStat" -state $mailButtonState -font MyDefaultFont
        button $frame.build -text "Build" -command "doBuild $type" -font MyDefaultFont
        checkbutton $frame.snap -text "Snapshot pcs on Mail" -variable doSnapshotOnMail -font MyDefaultFont
        grid $frame.clean -padx 1 -pady 1 -row 0 -column 0
        grid $frame.mail -padx 1 -pady 1 -row 0 -column 1
        grid $frame.build -padx 1 -pady 1 -row 0 -column 2
        grid $frame.snap -padx 1 -pady 1 -row 0 -column 3
        #pack $frame
        .nb.${type}tab.c create window 400 0 -anchor nw -window $frame

    }


    ttk::notebook::enableTraversal .nb
    #.nb select .nb.$startTab

    frame .bf
    pack [button .bf.exit -text "Exit" -command exitApp -font MyDefaultFont]
    pack .bf -fill both -side top


    frame .tf
    pack [text .tf.out -width 150 -height 13 -yscrollcommand ".tf.scroll set" -state disabled  -font MyDefaultFont] -side left -expand yes -fill both
    pack [scrollbar .tf.scroll -command ".tf.out yview" ] -side right -fill y
    .tf.out tag configure err -foreground red
    pack .tf -fill both -side top



    frame .cf
    pack [label .cf.label -text "Command:"] -side left
    pack [entry .cf.entry -width 150 -justify left -font MyDefaultFont] -side left -expand yes -fill both
    pack .cf -fill both -side top


    bind .cf.entry  <KeyPress-Return> { executeCommand }
    bind .cf.entry  <KeyPress-Up> { prevCommand }
    bind .cf.entry  <KeyPress-Down> { nextCommand }

    ##  Force the top level window to a fixed position.
    wm geometry . 1400x800

    logMsg "Info: releaseRoot = $releaseRoot\n"
    logMsg "Info: ipRelease = $ipReleaseName\n"
    logMsg "Info: ipReleaseVC = $ipReleaseNameVC\n"
    logMsg "Info: pcsType = $pcsType\n"
    logMsg "Info: pcsName = $pcsName\n"
    logMsg "Info: pcsRelease = $pcsRelease\n"
    logMsg "Info: process = $processName\n"
    if [info exists ::releaseMailDist] {logMsg "Info: MailDist = $::releaseMailDist\n"}
    if [info exists ::releaseIgnoreMacro] {
        logMsg "Info: releaseIgnoreMacro = {$::releaseIgnoreMacro}\n"
        foreach m $::releaseIgnoreMacro {
            set i [lsearch -exact $macroList $m]
            if {$i >= 0} {
                logMsg "Info:  Skipping $m\n"
                set macroList [lreplace $macroList $i $i]
            }
        }
    }
    if [info exists ::releaseIgnoreMacroHspice] {
        logMsg "Info: releaseIgnoreMacroHspice = {$::releaseIgnoreMacroHspice}\n"
        foreach m $::releaseIgnoreMacroHspice {set ignoreMacroHspice($m) 1}
    }
    if [info exists ::releaseIgnoreMacroIbis] {
        logMsg "Info: releaseIgnoreMacroIbis = {$::releaseIgnoreMacroIbis}\n"
        foreach m $::releaseIgnoreMacroIbis {set ignoreMacroIbis($m) 1}
    }
    #logMsg "Info: metalStack = $metalStack\n"

    #set repeaterMacros ""
    #lappend repeaterMacros ""
    #lappend repeaterMacros "dwc_ddrphy_repeater_cells"
    set rootNum 0
    set TIME_start_total [clock clicks -milliseconds]
    foreach root $releaseRoot {

        set root "$root/ckt/rel"

        ##  If more than one p4 root specified, releases get qualified with "rootX/"
        if {$::numP4Roots == 1} {set rootID ""} else {set rootID "root$rootNum/"}
        set releaseRootLen [string length $root]

        logMsg "Info:  Getting p4 file log...\n";
        set filelog [split [exec p4 filelog -t -m 1 -s $root/...] "\n"]

        # change so it only checks release from legalRelease
        # change p4 filelog to p4 files
        # take a detailed look at sub and check what files are needed exactly for the release

        set checkversion 0
        set isMainFile 0
        set isUtilityFile 0
        set isIbisFile 0
        set isHspiceFile 0
        set isRepeaterFile 0
        set isTCFile 0
        logMsg "Info:  Processing p4 file log...\n";
        if { $releaseDefMacro ne ""} {
            foreach defMacro $releaseDefMacro {
                lappend finalDefMacros [lindex [split $defMacro "/"] 1]
            }
            set releaseDefMacro $finalDefMacros
        }
        set macroPincheckExists [dict create]
        foreach line $filelog {
            if {[regexp {^//} $line dummy]} {
                ##  Parsing the file name
                set file [string replace $line 0 $releaseRootLen]
                set toks [split $file "/"]
                set n [llength $toks]

                if { [regexp {floorplans} $line]} {
                    ## .def files under floorplans or dXXX_CKT_Special_Routing_Spec.csv as per Jira P10020416-40130
                    regexp -nocase {(.*)(\.def|\.csv)} [lindex $toks end] to macro
                    set release [lindex $toks 1]
                    set release "$rootID$release"
                    set something [lindex $toks 2]
                    set view [lindex $toks 0]
                } else {
                    set macro [lindex $toks 0]
                    ##  These are speculative for now
                    set release [lindex $toks 1]
                    set something [lindex $toks 2]
                    set view [lindex $toks 3]
                    if {[llength $toks] < 5} {
                        ## Indicates this is a file, not dir, and doesn't indicate a view.
                        set view ""
                    }
                    set release "$rootID$release"
                }
                set isHspice [string equal $view hspice]
                if { [regexp {HSPICE_model|tcoil_model} $macro ] } { set isHspice 1 }
                #	    puts "!!!  $view  $isHspice"
                set isIbis [string equal $view ibis]
                set releaseRootMacro($macro) $root
                ##  See if macro is in legal list
                if {([lsearch -exact $macroList $macro] >= 0) || ([info exists releaseDefMacro] && [lsearch -exact $releaseDefMacro $macro] >= 0) || [regexp -nocase {HSPICE_model|tcoil_model|CKT_Special_Routing_Spec} $macro]} {set macroOK 1} else {set macroOK 0}

                ##  See if legal utility macro
                if [info exists releaseUtilityMacro] {
                    if {[lsearch -exact $releaseUtilityMacro $macro] >= 0} {
                        set utilityOK 1
                    } else {
                        set utilityOK 0
                    }
                } else {
                    set utilityOK 0
                }
                if [info exists releaseRepeaterMacro] {
                    if {[lsearch -exact $releaseRepeaterMacro $macro] >= 0} {set repeaterOK 1} else {
                        set repeaterOK 0
                    }
                    } else { set repeaterOK 0}

                    if [info exists releaseTCMacro] {
                        if { ([lsearch -exact $releaseTCMacro $macro] >= 0) && ([lsearch -exact $macroList $macro] >= 0) } {set tcOK 1} else {set tcOK 0}
                    } else {
                        set tcOK 0
                    }

                    #Def macros must be under main
                    # if [info exists releaseDefMacro] {
                    #	if {[lsearch -exact $releaseDefMacro $macro] >= 0} {set macroOK 1} else {set macroOK 0}
                # }
                ##  See if it should be ignored
                if {[info exists fileIgnorePattList]} {
                    foreach patt $fileIgnorePattList {
                        if [regexp $patt $file] {
                            ##  Matched the ignore list; skip.
                            set macroOK 0
                        }
                    }
                }


                set checkversion 0
                if $macroOK {
                    ##  Satisfies check as main macro.
                    set checkversion 1
                    set isMainFile 1
                    set isUtilityFile 0
                    set isHspiceFile $isHspice
                    set isIbisFile $isIbis
                    set isRepeaterFile 0
                    set isTCFile 0
                }
                if $utilityOK {
                    ##  Satisfies check as utility macro
                    set checkversion 1
                    set isMainFile 0
                    set isUtilityFile 1
                    set isHspiceFile $isHspice
                    set isIbisFile $isIbis
                    set isRepeaterFile 0
                    set isTCFile 0
                }
                if $repeaterOK {
                    ##  Satisfies check as repeater macro
                    set checkversion 1
                    set isMainFile 0
                    set isUtilityFile 0
                    set isHspiceFile $isHspice
                    set isIbisFile $isIbis
                    set isRepeaterFile 1
                    set isTCFile 0
                }
                if $tcOK {
                    ##  Satisfies check as repeater macro
                    set checkversion 1
                    set isMainFile 0
                    set isUtilityFile 0
                    set isHspiceFile $isHspice
                    set isIbisFile $isIbis
                    set isRepeaterFile 0
                    set isTCFile 1
                }

                #if { [regexp -nocase {repeater} $macro] } { puts "isRepeater $isRepeater $macroOK $isRepeaterFile" }
                #	    puts "$file ($macro) checkversion=$checkversion isMain=$isMainFile isUtility=$isUtilityFile isHspice=$isHspiceFile isIbis=$isIbisFile"

            } elseif $checkversion {
                ##  Parsing the history of the file
                if [regexp {^\.\.\. \#(\d+) change (\d+) (\S+) on (\S+) (\S+) by (\S+) \((\S+)\) '(.*)'} $line dummy version changelist action date time client type desc] {
                    ##  Filelog as executed above appears to include deleted files. Ignore these
                    if {![regexp {delete} $action]} {
                        set datetime "$date:$time"
                        set checkversion 0

                        ## Need $type for pincheck; only needed for main/utility/repeater/tc
                        if {$isMainFile} {
                            if { ![regexp {HSPICE_model|tcoil_model} $macro] && ![regexp {hspice|ibis} $view] } {
                                set type main
                                addReleaseInfo $type $macro $release $file $version $changelist $datetime $desc $view
                            }
                        }
                        if {$isUtilityFile} {
                            set type utility
                            addReleaseInfo $type $macro $release $file $version $changelist $datetime $desc $view
                        }
                        if {$isRepeaterFile} {
                            set type repeater
                            addReleaseInfo $type $macro $release $file $version $changelist $datetime $desc $view
                        }
                        if {$isTCFile} {
                            set type tc
                            addReleaseInfo $type $macro $release $file $version $changelist $datetime $desc $view
                        }
                        if {$isHspiceFile} {
                            if {![info exists ignoreMacroHspice($macro)]} {
                                addReleaseInfo hspice $macro $release $file $version $changelist $datetime $desc $view
                            }
                        }
                        if {$isIbisFile} {
                            if {![info exists ignoreMacroIbis($macro)]} {
                                addReleaseInfo ibis $macro $release $file $version $changelist $datetime $desc $view
                            }
                        }

                        ## If the file is a pincheck, add the release version to the dict if not already there
                        if {[regexp {.pincheck} $file]} {

                            ## Intent of $macroPincheckExists dict is to create a dict where the keys are the type of release
                            ## and macro, and the values are the releases where a pincheck file is found.
                            ## (e.g. [main:dwc_ddr5phy_ato_ew {1.00a 1.00a_pre2 1.10a} ... utility:dwc_ddr5phy_utility_blocks {1.00a 1.00a_pre2} ...]
                            if {![dict exists $macroPincheckExists $type:$macro] || $release ni [dict get $macroPincheckExists $type:$macro]} {
                                dict lappend macroPincheckExists $type:$macro $release
                            }
                        }
                    }
                }
            }
        }

        ## Use the rel version set by legalRelease for pincheck. If it does not exist, use latest.
        foreach key [dict keys $macroPincheckExists] {
            set key_split [split $key ":"]
            set type [lindex $key_split 0]
            set macro [lindex $key_split 1]
            set pincheckVersions [dict get $macroPincheckExists $key]

            if {$::ipReleaseName in $pincheckVersions} {
                set pincheckRelVersion $::ipReleaseName
            } else {
                if {$type == "main"} {
                    upvar #0 datetimeCmps dateTimeList
                } elseif {$type == "utility"} {
                    upvar #0 utilityDatetimeCmps dateTimeList
                } elseif {$type == "repeater"} {
                    upvar #0 repeaterDatetimeCmps dateTimeList
                } elseif {$type == "tc"} {
                    upvar #0 tcDatetimeCmps dateTimeList
                }
                set latestRel {}
                set latestDatetime 0
                foreach rel $pincheckVersions {
                    set macroRel "$type:$macro:$rel"
                    set relLatest [getLatestDatetime $dateTimeList($macroRel)]
                    if {$latestRel == ""} {
                        set latestRel $rel
                        set latestDatetime $relLatest
                    } else {
                        if {$relLatest > $latestDatetime} {
                            set latestRel $rel
                            set latestDatetime $relLatest
                        }
                    }
                }
                set pincheckRelVersion $latestRel
            }

            ## Need to check if $release contains a '/' in the cases where
            ## there are two P4 roots (e.g. $release = root0/rel1.00a)
            ## Jira P10020416-38859
            if {[regexp {\/} $pincheckRelVersion]} {
                set rel [lindex [split $pincheckRelVersion "/"] 1]
            } else {
                set rel $pincheckRelVersion
            }
            ##########################################################
            ## Must use $rel in file path after checking for the '/',
            ## otherwise it will error out if there are two roots

            logMsg "Checking pincheck file for $macro/$rel..."

            ## If new flow is used (pincheck summary file exists)
            set pincheckExist [checkPinCheckExist "$root/$macro/$rel/macro/..."]
            if {$pincheckExist == TRUE} {
                set pincheckStatus TRUE
                lassign [run_system_cmd "p4 dirs $root/$macro/$rel/macro/pincheck/\"*\""] pincheckSubdirs
                foreach dir $pincheckSubdirs {
                    regexp {pincheck\/(\S*)} $dir stack
                    set p [checkPincheckLog $root/$macro/$rel/macro/$stack/$macro.pincheck $root/$macro/$rel/macro/${macro}_pincheck_summary.txt]
                    if {[dict get $p status] == false} {
                        set pincheckStatus FALSE
                    }
                    if {[dict get $p runTime] == 0} {
                        dict set p runTime [clock scan $datetime -format "%Y/%m/%d:%T"]
                        logMsg "\nPincheck file for $macro/$rel does not include run timestamp; using P4 checkin time instead.\n"
                    }
                }
                if {$pincheckStatus == FALSE} {
                    dict set p status FALSE
                }
                dprint HIGH "$p"
                addPincheckInfo $pincheckRelVersion $macro $p
                logMsg "Done\n"
            } elseif {$pincheckExist == FALSE} {
                set p [checkPincheckLog $root/$macro/$rel/macro/$macro.pincheck FALSE]
                if {[dict get $p runTime] == 0} {
                    dict set p runTime [clock scan $datetime -format "%Y/%m/%d:%T"]
                    logMsg "\nPincheck file for $macro/$rel does not include run timestamp; using P4 checkin time instead.\n"
                }
                dprint HIGH "$p"
                addPincheckInfo $pincheckRelVersion $macro $p
                logMsg "Done\n"
            } else {
                logMsg "Done\n"
            }
            ##########################################################
        }

        ##############################################################
        # Add ibis-app-note to IBIS CRR; Jira P10020416-34748
        # Paths to ibis-app-note files taken from Jira P10020416-34674

        set ibisAppNoteExists 0
        set ibisAppNotePath [regsub "project/.*" ${root} "common/qms/templates/IBIS_model_app_note"]
        set allFiles [exec p4 files -e $ibisAppNotePath/... 2> /dev/null]
        set allFiles [split $allFiles "\n"]
        set foundAppNoteFiles {}

        foreach f $allFiles {
            if {[regexp {(.*_ibis_application_note.pdf)} $f]} {
                lappend foundAppNoteFiles $f
            }
        }

        # If there are multiple ibis-app-note files found, use product name to differentiate
        # e.g. ddr54 vs. ddr54v2
        if {[llength $foundAppNoteFiles] > 1} {
            # Regex to capture dXXX-(prodName)-phy-...
            regexp {.*d[0-9]+-([a-zA-Z0-9]+)-} $::pcsName full_match prodName
            foreach f $foundAppNoteFiles {
                if {[regexp -nocase _${prodName}_ $f match]} {
                    regexp {(.*_ibis_application_note.pdf)#([0-9]+).*change ([0-9]+)} $f full_match ibisAppNoteFile version changeList
                    set ibisAppNoteExists 1
                }
            }
            # Otherwise just use the one found
        } elseif {[llength $foundAppNoteFiles] == 1} {
            regexp {(.*_ibis_application_note.pdf)#([0-9]+).*change ([0-9]+)} [lindex $foundAppNoteFiles 0] full_match ibisAppNoteFile version changeList
            set ibisAppNoteExists 1
        }

        if {$ibisAppNoteExists == 1} {
            addReleaseInfo ibis "IBIS_model_app_note" "Latest" $ibisAppNoteFile $version $changeList "" "" ""
        }
        ##############################################################

        incr rootNum
    }
    set TIME_taken_total [expr [clock clicks -milliseconds] - $TIME_start_total]
    puts "Total loading time: $TIME_taken_total ms"
    if {0} {
        puts "Pincheck file info:"
        foreach rel [dict keys $::pincheckInfo] {
            foreach macro [dict keys [dict get $::pincheckInfo $rel]] {
                puts "$rel/$macro: [dict get $::pincheckInfo $rel $macro]"
            }
        }

        puts "Release/Macro checkin times:"
        foreach rel [dict keys $::pincheckMacroReleaseChecks] {
            foreach macro [dict keys [dict get $::pincheckMacroReleaseChecks $rel]] {
                puts "$rel/$macro: [dict get $::pincheckMacroReleaseChecks $rel $macro]"
            }
        }
    }

    if [info exists fileListFP] {close $fileListFP}

    foreach r [array names ::latestPincheckViewTime] {
        puts "$r:  [clock format $::latestPincheckViewTime($r)]"
    }

    #foreach macro $macroList {
    #    if {![info exists releases($macro)]} {logMsg "Warning:  No release data found for macro $macro\n"}
    #}

    #puts "!!!  [array names utilityReleases]"

    proc buildReleasePage {type} {

        logMsg "Info:  Building $type release page\n"
        ##  Get the data arrays associated with the type
        if {$type == "main"} {
            upvar #0 releases releases
            upvar #0 datetimeCmps datetimeCmps
            set tabName "maintab"
        } elseif {$type == "utility"} {
            upvar #0 utilityReleases releases
            upvar #0 utilityDatetimeCmps datetimeCmps
            set tabName "utilitytab"
        } elseif {$type == "hspice"} {
            upvar #0 hspiceReleases releases
            upvar #0 hspiceDatetimeCmps datetimeCmps
            set tabName "hspicetab"
        } elseif {$type == "ibis"} {
            upvar #0 ibisReleases releases
            upvar #0 ibisDatetimeCmps datetimeCmps
            set tabName "ibistab"
        } elseif {$type == "repeater"} {
            upvar #0 repeaterReleases releases
            upvar #0 repeaterDatetimeCmps datetimeCmps
            set tabName "repeatertab"
        } elseif {$type == "tc"} {
            upvar #0 tcReleases releases
            upvar #0 tcDatetimeCmps datetimeCmps
            set tabName "tctab"
        }

        ##  Set the width of the macro name field and release combobox to the width of the largest value
        set maxRelWidth 0
        set maxMacroWidth 0
        foreach m [array names releases] {
            set ml [string length $m]
            if {$ml > $maxMacroWidth} {set maxMacroWidth $ml}
            foreach r $releases($m) {
                set l [string length $r]
                if {$l > $maxRelWidth} {set maxRelWidth $l}
            }
        }

        set mList [lsort -ascii [array names releases]]
        set fname .nb.$tabName.c.mac
        frame $fname
        set i 0
        foreach macro $mList {

            set latestRel {}
            set latestDatetime 0
            foreach rel $releases($macro) {
                set macroRel "$type:$macro:$rel"
                set relLatest [getLatestDatetime $datetimeCmps($macroRel)]
                if {$latestRel == ""} {
                    set latestRel $rel
                    set latestDatetime $relLatest
                } else {
                    if {$relLatest > $latestDatetime} {
                        set latestRel $rel
                        set latestDatetime $relLatest
                    }
                }
            }

            #    puts "$macro:  $latestRel"

            #    puts "Latest rel for $macro is $latestRel out of {$releases($macro)} "
            set macroType "$macro:$type"
            set ::selectedRelease($macroType) $latestRel
            set ::latestMacroRel($macroType) $latestRel
            #	puts "Setting selectedRelease($macroType) to $latestRel"

            label $fname.label$i -text $macro -width $maxMacroWidth -justify right -font MyDefaultFont -relief flat
            ttk::combobox $fname.cbx$i -textvariable ::selectedRelease($macroType) -state readonly -values "$releases($macro)" -width $maxRelWidth
            trace add variable ::selectedRelease($macroType) write "refreshOnManualSelect $i"
            label $fname.latestLabel$i -width 10 -relief sunken -text changelist -font MyDefaultFont
            label $fname.chgLabel$i    -width 20 -relief sunken -text changelist -font MyDefaultFont
            label $fname.dateLabel$i   -width 20 -relief sunken -text dateTime -font MyDefaultFont
            label $fname.descLabel$i   -width 40 -relief sunken -text description -font MyDefaultFont
            set viewerCommand "displayLabel $macro $fname.chgLabel$i"
            bind $fname.descLabel$i <Double-Button-1> $viewerCommand
            bind $fname.dateLabel$i <Double-Button-1> $viewerCommand
            bind $fname.chgLabel$i <Double-Button-1> $viewerCommand
            if {[pincheckAssociated $type]} {
                label $fname.pcStatLabel$i -width 50 -text "" -relief sunken -font MyDefaultFont
                ##  A test to see if you can trigger an event by dbl-clicking on a label widget.  Yes you can.
                ##bind $fname.pcStatLabel$i <Double-Button-1> "foo $macro $fname.cbx$i"
                button $fname.pcViewButton$i -text "View" -command {viewP4File} -state disabled -pady 0 -bd 0
            }

            grid $fname.label$i       -padx 2 -pady 2 -row $i -column 0
            grid $fname.cbx$i         -padx 2 -pady 2 -row $i -column 1
            grid $fname.latestLabel$i -padx 2 -pady 2 -row $i -column 2
            grid $fname.chgLabel$i    -padx 2 -pady 2 -row $i -column 3
            grid $fname.dateLabel$i   -padx 2 -pady 2 -row $i -column 4
            grid $fname.descLabel$i   -padx 2 -pady 2 -row $i -column 5
            if {[pincheckAssociated $type]} {
                grid $fname.pcStatLabel$i -padx 2 -pady 2 -row $i -column 6
                grid $fname.pcViewButton$i -padx 2 -pady 2 -row $i -column 7
            }

            refreshRow $macro $type $tabName $i
            incr i
        }
        #pack $fname -side top
        .nb.$tabName.c create window 10 40 -anchor nw -window .nb.$tabName.c.mac
        pack .nb.$tabName.c  -side top

    }


    foreach type {main utility ibis hspice repeater tc} {buildReleasePage $type}



    ################################################################################
    # No Linting Area
    ################################################################################
    # nolint Main

    # 11-07-2022: monitor usage is in header now
    # nolint utils__script_usage_statistics

    # nolint Line 281: W Found constant
    # nolint Line 302: N Expr called in expression
    # nolint Line 794: N Non constant argument to global
    # nolint Line 796: N Suspicious variable name
    # nolint Line 797: N Suspicious variable name
    # nolint Line 991: N Suspicious variable name
    # nolint Line 992: N Suspicious variable name
    # nolint Line 1067: N Unescaped quot
    # nolint Line 1190: W Found constant
    # nolint Line 1191: W Found constant
    # nolint Line 1773: N Non constant a
    # nolint Line 1775: N Suspicious var
    # nolint Line 1905: N Expr called in
    # nolint Line 1919: N Expr called in
    # nolint Line 2137: W Found constant
    # nolint Line 2141: W Found constant
    # nolint Line 2620: N No braces arou
