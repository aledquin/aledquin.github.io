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

#### added this function to sort wide integers like timestamps. The lsort -integer switch didn't work. ##########
proc sort { mylist } {
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

    .tf.out config -state normal
    .tf.out insert end $msg
    .tf.out see end
    .tf.out config -state disabled
    update
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
            if {$currDate-$tcrDate > 86400} {
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
            if {$currDate-$tcrDateRB > 86400} {
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

