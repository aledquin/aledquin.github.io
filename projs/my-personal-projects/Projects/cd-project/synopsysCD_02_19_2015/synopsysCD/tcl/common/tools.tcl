# Copyright (c) 2004-2014 Synopsys, Inc. This Galaxy Custom Designer software
# and the associated documentation are confidential and proprietary to
# Synopsys, Inc. Your use or disclosure of this Galaxy Custom Designer software
# is subject to the terms and conditions of a written license agreement between
# you, or your company, and Synopsys, Inc.

namespace eval ::amd::utils {

namespace export *

proc findDependencies {} {
    set ns [namespace current]
    set dlg [gi::createDialog findDependencies -title "Find Dependencies"]
    set sfi [gi::createFileInput sfi -parent $dlg -label "SKILL Files Directory" \
    -fileType directory -valueChangeProc ${ns}::selectSKILLDirCB]
    db::addAttr skillProcs -value {} -of $sfi
    
    set tfi [gi::createFileInput tfi -parent $dlg -label "Tcl Files Directory" \
    -fileType directory -valueChangeProc ${ns}::selectTclDirCB]    
    db::addAttr tclProcs -value {} -of $tfi
    
    set procsTbl [gi::createTable procsTbl -parent $dlg \
    -selectionChangeProc ${ns}::selectProcNameCB -allowSortColumns true]
    gi::createColumn -parent $procsTbl -readOnly true -label "Proc" -stretch true
    gi::createColumn -parent $procsTbl -readOnly true -label "Lines"
    gi::createColumn -parent $procsTbl -readOnly true -label "File"
    
    set depTbl [gi::createTable depTbl -parent $dlg]
    gi::createColumn -parent $depTbl -readOnly true -label "Proc" -stretch true
    gi::createColumn -parent $depTbl -readOnly true -label "Lines"
    gi::createColumn -parent $depTbl -readOnly true -label "File"
    gi::layout $depTbl -rightOf $procsTbl
    db::setAttr geometry -of $dlg -value 1000x600
    #db::setAttr tbl.styleSheet -value "QTableView {width: 80%; background: #CCDDEE}" 

    set totalLinesLbl [gi::createLabel totalLinesLbl -parent $dlg -label "Total lines of code: 0"]
    set procLinesLbl [gi::createLabel procLinesLbl -parent $dlg -label "Lines of code: 0"]
    gi::layout $procLinesLbl -align $depTbl -rightOf $totalLinesLbl
}

proc selectTclDirCB {w} {
    set dlg [db::getAttr parent -of $w]
    set srcDir [db::getAttr value -of $w]  
    set tclProcs {}    
    foreach tclFile [exec find $srcDir -name *.tcl] {
        set fileName [file tail $tclFile]
        set fp [open $tclFile r]
        set file_data [read $fp]
        set data [split $file_data "\n"]  
        close $fp
        foreach line $data {
            if {[regexp {\s?proc\s+([^\s+]*)\s+} $line m procName]} {
                lappend tclProcs $procName
            }
        }      
    } 
    db::addAttr tclProcs -value $tclProcs -of $w
    colorizeProcsTable $dlg
    colorizeDepTable $dlg
}


proc selectSKILLDirCB {w} {
    set dlg [db::getAttr parent -of $w]
    set srcDir [db::getAttr value -of $w]
    array set skillProcs {}
    foreach skillFile [exec find $srcDir -name *.il] {
        set fileName [file tail $skillFile]
        set fp [open $skillFile r]
        set file_data [read $fp]
        close $fp
        set data [split $file_data "\n"]
        set procDetected 0
        set linesCount 0
        foreach line $data {
            set line [string trim $line]
            if {[string first ";" $line]!=0 && ""!=$line} {
                if { [regexp {\s?procedure\s?\(\s?([A-Za-z_]*)\s?} $line m procName]} {
                    set procDetected 1
                    set openBrace 0
                    set closeBrace 0
                    set procs {}
                    set skillProcs($procName) [list $fileName {} 0]
                    set linesCount 1
                }
                if {$procDetected } {
                    incr linesCount
                    set procNames [regexp -inline -all -- {amd\w+\(} $line]
                    foreach p $procNames {
                        regsub -all {\(} $p  "" p
                        if {[lsearch $procs $p]==-1 && $p!=$procName} {
                            lappend procs $p
                        }
                    }
                    set openBrace [expr $openBrace+[regexp -all {\(} $line]]
                    set closeBrace [expr $closeBrace + [regexp -all {\)} $line]]
                    if {$openBrace==$closeBrace} {
                        set skillProcs($procName) [list $fileName $procs $linesCount]
                        set procDetected 0
                    }
                }
            }
        }
    }

    db::addAttr skillProcs -value [array get skillProcs] -of $w
    refreshSKILLProcsList $dlg
}


proc refreshSKILLProcsList {dlg} {
    set sfi [gi::findChild sfi -in $dlg]
    set totalLinesLbl [gi::findChild totalLinesLbl -in $dlg]
    set procsTbl [gi::findChild procsTbl -in $dlg]
    db::destroy [gi::getRows -parent $procsTbl]
    
    set totalLinesNum 0
    array set skillProcs [db::getAttr skillProcs -of $sfi]
    foreach procName [array names skillProcs] {
        set r [gi::createRow -parent $procsTbl]
        set cells [gi::getCells -row $r]
        set c [db::getNext $cells]
        db::setAttr value -of $c -value "$procName"
        set c [db::getNext $cells]    
        db::setAttr value -of $c -value "[lindex $skillProcs($procName) 2]"
        set c [db::getNext $cells]    
        db::setAttr value -of $c -value "[lindex $skillProcs($procName) 0]"
        set totalLinesNum [expr $totalLinesNum + [lindex $skillProcs($procName) 2]]
    }
    db::setAttr label -of $totalLinesLbl -value "Total lines of code: $totalLinesNum"
    colorizeProcsTable $dlg
}

proc colorizeProcsTable {dlg} {
    set tfi [gi::findChild tfi -in $dlg]
    set tclProcs [db::getAttr tclProcs -of $tfi] 
    set procsTbl [gi::findChild procsTbl -in $dlg]    
    db::foreach c [gi::getCells -parent $procsTbl -column [gi::getColumns -parent $procsTbl -filter {%label=="Proc"}]] {
        if {[member [db::getAttr value -of $c] $tclProcs]} {
            db::foreach rc [gi::getCells -row [db::getAttr row -of $c]] {
                db::setAttr style.background -of $rc -value #52f161
            }
        } else {
            db::foreach rc [gi::getCells -row [db::getAttr row -of $c]] {
                db::setAttr style.background -of $rc -value #FFFFFF
            }            
        }        
    }    
}

proc colorizeDepTable {dlg} {
    set depTbl [gi::findChild depTbl -in $dlg]
    set tfi [gi::findChild tfi -in $dlg]
    set tclProcs [db::getAttr tclProcs -of $tfi]
    db::foreach c [gi::getCells -parent $depTbl -column [gi::getColumns -parent $depTbl -filter {%label=="Proc"}]] {
        if {[member [db::getAttr value -of $c] $tclProcs]} {
            db::foreach rc [gi::getCells -row [db::getAttr row -of $c]] {
                db::setAttr style.background -of $rc -value #52f161
            }
        }        
    }
}


proc selectProcNameCB {tbl} {
    set dlg [db::getAttr parent -of $tbl]
    set depTbl [gi::findChild depTbl -in $dlg]
    set sfi [gi::findChild sfi -in $dlg]
    set procLinesLbl [gi::findChild procLinesLbl -in $dlg]
    db::destroy [gi::getRows -parent $depTbl]
    set r [db::getNext [db::getAttr selection -of $tbl]]
    set topProcName [db::getAttr value -of [db::getNext [gi::getCells -row $r]]]
    array set skillProcs [db::getAttr skillProcs -of $sfi]
    array set totalLines {count 0 procs {}}
    getDependencies skillProcs totalLines $topProcName $depTbl
    set totalLines(count) [expr $totalLines(count) + [lindex $skillProcs($topProcName) 2]]
    db::setAttr label -of $procLinesLbl -value "Lines of code: $totalLines(count)" 
    colorizeDepTable $dlg
}

proc getDependencies {refSkillProcs refTotalLines procName parent} {
    upvar $refSkillProcs skillProcs
    upvar $refTotalLines totalLines
    if {![info exist skillProcs($procName)]} {
        puts "$procName is not defined"
        return
    }
    set obj $skillProcs($procName)
    foreach p [lindex $obj 1] {
        if {![info exist skillProcs($p)]} {
            set r [gi::createRow -parent $parent]
            set cells [gi::getCells -row $r]
            set c [db::getNext $cells]
            db::setAttr value -of $c -value "$p"
            db::setAttr style.background -of $c -value red
            set c [db::getNext $cells]
            db::setAttr style.background -of $c -value red
            set c [db::getNext $cells]
            db::setAttr value -of $c -value "can't find source file"
            db::setAttr style.background -of $c -value red
        } else {
            set r [gi::createRow -parent $parent]
            set cells [gi::getCells -row $r]
            set c [db::getNext $cells]
            db::setAttr value -of $c -value "$p"
            set c [db::getNext $cells]
            db::setAttr value -of $c -value "[lindex $skillProcs($p) 2]"
            set c [db::getNext $cells]
            db::setAttr value -of $c -value "[lindex $skillProcs($p) 0]"
            if {![member $p $totalLines(procs)]} {
                lappend totalLines(procs) $p
                set totalLines(count) [expr $totalLines(count)+[lindex $skillProcs($p) 2]]
            }
            getDependencies skillProcs totalLines $p $r
            db::setAttr expanded -of $r -value true
        }
    }
}


proc getStatus { {skillDir ""} {tclDir ""}} {
    if {""==$skillDir} {
        set skillDir "/remote/amscae5/amscae22/CDesigner/hrantm/Customers/AMD/custom_env/SKILL/"
    }
    if {""==$tclDir} {
        set tclDir $::env(SYNOPSYS_CUSTOM_SITE)
    }
    
    array set skillProcs {}
    foreach skillFile [exec find $skillDir -name *.il] {
        set fileName [file tail $skillFile]
        set fp [open $skillFile r]
        set file_data [read $fp]
        close $fp
        set data [split $file_data "\n"]
        set procDetected 0
        set linesCount 0
        foreach line $data {
            set line [string trim $line]
            if {[string first ";" $line]!=0 && ""!=$line} {
                #[regexp {\s?procedure\s?\(\s?([^\(+]*)\s?} $line m procName]
                if {[regexp {^procedure\s?\(\s?(\w+)} $line m procName]} {
                    set procDetected 1
                    set openBrace 0
                    set closeBrace 0
                    set skillProcName $procName
                    set linesCount 1
                }
                if {$procDetected} {
                    incr linesCount
                    set openBrace [expr $openBrace + [regexp -all {\(} $line]]
                    set closeBrace [expr $closeBrace + [regexp -all {\)} $line]]
                    if {$openBrace==$closeBrace} {
                        if {[info exist skillProcs($fileName)]} {
                            lappend skillProcs($fileName) $skillProcName
                            lappend skillProcs($fileName) $linesCount
                        } else {
                            set skillProcs($fileName) "$skillProcName $linesCount"
                        }
                        set procDetected 0
                    }
                }
            }
        }
    }
    

    set tclProcs [list ]
    foreach tclFile [exec find $tclDir -name *.tcl] {
        set fileName [file tail $tclFile]
        set fp [open $tclFile r]
        set file_data [read $fp]
        set data [split $file_data "\n"]  
        close $fp
        foreach line $data {
            set line [string trim $line]
            if {[regexp {^proc\s+([^\s+]*)\s+} $line m procName]} {
                if {-1==[lsearch $tclProcs $procName]} {
                    lappend tclProcs $procName
                }
            }
        }      
    }
    
    array set convertedTclProcs {} 
    array set convertedSkillProcLines {}
    array set nonConvertedSkillProcNames {}
    foreach {fileName procsList} [array get skillProcs] {
        array set skillProcsList $procsList
        set convertedTclProcs($fileName) 0
        set convertedSkillProcLines($fileName) 0
        set nonConvertedSkillProcNames($fileName) {}
        foreach procName $tclProcs {
            set indx [lsearch $procsList $procName]
            if {$indx!=-1} {
                set skillProcsList($procName) ""
                incr convertedTclProcs($fileName)
                set convertedSkillProcLines($fileName) [expr $convertedSkillProcLines($fileName) + [lindex $procsList [expr $indx+1]]]
            }
        }
        
        foreach procName [array name skillProcsList] {
            if {""!=$skillProcsList($procName)} {
                lappend nonConvertedSkillProcNames($fileName) $procName
            }
        }
        array unset skillProcsList
    }
    
    set totalSkillProcs 0
    set totalSkillLineOfCode 0
    set totalSkillConvertedLineOfCode 0
    set totalTclProcs 0

    set _skillProcs [list]
    foreach {k v} [array get skillProcs] {
        lappend _skillProcs [list $k $v]
    }
    set _skillProcs [lsort -index 0 $_skillProcs] 
    puts [format "%40s%20s%20s%20s%20s%20s%20s" "File Name" "Total Lines" "Converted Lines" "Percent" "Total SKILL procs" "Total Tcl procs" "Percent"]
    set allProcs {}
    array set output {}
    foreach val $_skillProcs {
        set fileName [lindex $val 0]
        set procsList [lindex $val 1]
        set skillProcsCount [expr [llength $procsList]/2]
        set totalLinesInFile 0
        foreach {pName pLine} $procsList {
            if {[member $pName $allProcs]} {
            } else {
                lappend allProcs $pName
            }        
            set totalLinesInFile [expr $totalLinesInFile + $pLine ]
        }
        set tclProcsCount $convertedTclProcs($fileName)
        set totalSkillProcs [expr $totalSkillProcs+$skillProcsCount]
        set totalSkillLineOfCode [expr $totalSkillLineOfCode+$totalLinesInFile]
        set convertedLines $convertedSkillProcLines($fileName)
        set totalSkillConvertedLineOfCode [expr $totalSkillConvertedLineOfCode + $convertedLines]
        puts [format "%40s%20s%20s%20s%20s%20s%20s" $fileName $totalLinesInFile $convertedLines "[expr round(1.0*$convertedLines/$totalLinesInFile*100)]% done" $skillProcsCount $tclProcsCount "[expr round(1.0*$tclProcsCount/$skillProcsCount*100)]% done"]
        incr totalTclProcs $tclProcsCount
        set output($fileName) [list $totalLinesInFile $convertedLines [expr round(1.0*$convertedLines/$totalLinesInFile*100)] $skillProcsCount $tclProcsCount [expr round(1.0*$tclProcsCount/$skillProcsCount*100)] $nonConvertedSkillProcNames($fileName)]

    }
    puts "Skill Procs: $totalSkillProcs Tcl Procs: $totalTclProcs [expr round(1.0*$totalTclProcs/$totalSkillProcs*100)]% done"
    puts "Line of Code: $totalSkillLineOfCode Converted: $totalSkillConvertedLineOfCode [expr round(1.0*$totalSkillConvertedLineOfCode/$totalSkillLineOfCode*100)]% done"    
    #puts [array get nonConvertedSkillProcNames]
    return [array get output]
}


proc showProjectStatus {} {
    set ns [namespace current]
    set dlgName "projectStatus"
    set dlg [db::getNext [gi::getDialogs $dlgName]]
    if {""==$dlg} {
        set dlg [gi::createDialog $dlgName -title "Project Status" -execProc "${ns}::displayStatus"]
        set sfi [gi::createFileInput sfi -parent $dlg -label "SKILL Files Directory" \
        -fileType directory -prefName amdProjectStatusSKILLDir]
        db::addAttr skillProcs -value {} -of $sfi
    
        set tfi [gi::createFileInput tfi -parent $dlg -label "Tcl Files Directory" \
        -fileType directory -prefName amdProjectStatusTclDir]    
        db::addAttr tclProcs -value {} -of $tfi   
        
        set tbl [gi::createTable tbl -parent $dlg -allowSortColumns true]
        gi::createColumn -parent $tbl -readOnly true -label "File Name" -stretch true
        gi::createColumn -parent $tbl -readOnly true -label "Total Lines"
        gi::createColumn -parent $tbl -readOnly true -label "Converted Lines"
        gi::createColumn -parent $tbl -readOnly true -label "Percent"
        gi::createColumn -parent $tbl -readOnly true -label "Total SKILL procs"
        gi::createColumn -parent $tbl -readOnly true -label "Total Tcl procs"
        gi::createColumn -parent $tbl -readOnly true -label "Percent"
    }
    gi::setActiveDialog $dlg
}


proc displayStatus {dlg} {
    set sfi [string trim [gi::findChild sfi.value -in $dlg]]
    set tfi [string trim [gi::findChild tfi.value -in $dlg]]
    
    if {[file isdir $sfi] && [file isdir $tfi]} {
        set tbl [gi::findChild tbl -in $dlg]
        db::destroy [gi::getRows -parent $tbl]
        array set result [getStatus $sfi $tfi]
        foreach {fileName item} [array get result] {
            set r [gi::createRow -parent $tbl]
            set cells [gi::getCells -row $r]
            set c [db::getNext $cells]
            db::setAttr value -of $c -value $fileName
            set c [db::getNext $cells]
            db::setAttr value -of $c -value [lindex $item 0]
            set c [db::getNext $cells]
            db::setAttr value -of $c -value [lindex $item 1]
            set c [db::getNext $cells]
            db::setAttr value -of $c -value [lindex $item 2]
            set c [db::getNext $cells]
            db::setAttr value -of $c -value [lindex $item 3]
            set c [db::getNext $cells]
            db::setAttr value -of $c -value [lindex $item 4]
            set c [db::getNext $cells]
            db::setAttr value -of $c -value [lindex $item 5]
            foreach missedProcName [lindex $item 6] {
                set sr [gi::createRow -parent $r]
                set cells [gi::getCells -row $sr]
                set c [db::getNext $cells]   
                db::setAttr value -of $c -value $missedProcName              
            }
        }
    }
}


proc createSNPSMenu {} {
    if {[regexp hrantm [exec hostname]]} {
        set ns [namespace current]
        set wt [gi::getWindowTypes giConsole]
        set m [db::getNext [gi::getMenus dbConsoleCustomMenu -from $wt]]
        if {""==$m} {
            set m [gi::createMenu dbConsoleCustomMenu -title "SNPS"]
            gi::addMenu $m -to $wt
        }
        gi::createAction "dbShowProjectStatus" -title "Project Status..." -command "${ns}::showProjectStatus"
        gi::addActions { dbShowProjectStatus } -to $m
    }
}
if {""==[db::getNext [db::getPrefs amdProjectStatusSKILLDir]]} {
    db::createPref amdProjectStatusSKILLDir -value ""
}

if {""==[db::getNext [db::getPrefs amdProjectStatusTclDir]]} {
    db::createPref amdProjectStatusTclDir -value ""
}

createSNPSMenu


}
