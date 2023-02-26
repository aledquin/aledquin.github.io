# Copyright (c) 2004-2014 Synopsys, Inc. This Galaxy Custom Designer software
# and the associated documentation are confidential and proprietary to
# Synopsys, Inc. Your use or disclosure of this Galaxy Custom Designer software
# is subject to the terms and conditions of a written license agreement between
# you, or your company, and Synopsys, Inc.

namespace eval ::amd::_lsw {

namespace export *
namespace import -force ::amd::utils::*
namespace import -force ::amd::amdLibrary::*

variable onlyActiveWindow 0
variable techLPPs {} 

proc amdCleanUpLayVariables {} {
    if {![info exist ::amd::GVAR_amdLayVariables(amdLayoutAMDLSWUserRemovedLayerSets)]} {
        set ::amd::GVAR_amdLayVariables(amdLayoutAMDLSWUserRemovedLayerSets) ""
    }  
    foreach key [array name ::amd::GVAR_amdLayVariables] {
        if {[regexp {amdLayoutAlias} $key]} {
            set newList {}
            foreach lpp $::amd::GVAR_amdLayVariables($key) {
                set layers [car $lpp]
                set purposes [cadr $lpp]
                foreach layer $layers {
                    foreach purpose $purposes {
                        lappend newList [list $layer $purpose]
                    }
                }
            }
            set ::amd::GVAR_amdLayVariables($key) [lsort -unique $newList]
        }
    }
}

# *** INIT CODE *** - runs after all files loaded
# ---------------------------------------------------------------------------
# First go through all GVAR_amdLayVariables and look for aliases the use a 
# list of a list.  Flatten all lists to a single list.
proc amdLSW_INIT {} {
    set ns [namespace current]
    amdCleanUpLayVariables
    set ::amd::GVAR_amdLayVariables(amdLayoutAMDLSWHiddenLayerSets) {{StdCells stdcells} {Macros macros}}
    amdLeAMDLSWLayerStoreCadLists
    if {![info exist amd::GVAR_amdEnvVariables(amdAMDLSWUserOwnedCurrentFileName)]} {
        if {[info exist amd::GVAR_amdRevRc(global,projrev)]} {
            set amd::GVAR_amdEnvVariables(amdAMDLSWUserOwnedCurrentFileName) $amd::GVAR_amdRevRc(global,projrev)
        } else {
            de::sendMessage "Env not loaded yet: amd::GVAR_amdRevRc(global,projrev)" -severity error
        }
    }
    if {![file isdir [file join $::env(HOME) ".synopsys_custom/AMDLSW"]]} {
        file mkdir [file join $::env(HOME) ".synopsys_custom/AMDLSW"]
    }
    amdLeAMDLSWLayerLoadUserFile "" 1
    amdLeAMDLSWLegacyUpdate
    amdLeAMDLSWPinControlInitEnv
    db::createCallback onPreWindowDestroyed -callbackType onPreWindowDestroyed -procedure ${ns}::onPreWindowDestroyed -priority 100 
    db::createCallback onPostWindowCreated -callbackType onPostWindowCreated -procedure ${ns}::onPostWindowCreated -priority 100 
    db::createCallback onPostContextAttachedToEditor -callbackType onPostContextAttachedToEditor -procedure ${ns}::onPostContextAttachedToEditor -priority 100 
}


proc onPostContextAttachedToEditor {ctx} {
    set oaDes [db::getAttr editDesign -of $ctx]
    if {"maskLayout"==[db::getAttr viewType -of $oaDes]} {
        variable techLPPs
        if {""==$techLPPs} {
            set techLPPs [db::createList [db::getAttr lpp -of [de::getLPPs -from $oaDes]]]
        }
        set ::amd::GVAR_amdLayVariables(amdLayoutAlias,all) $techLPPs
        set w [db::getAttr window -of $ctx]
        if {[db::getPrefValue amdLeAMDLSWMakeLPPsInvalid]} {
            set a [gi::getAssistants leObjectLayerPanel -from $w]
            gi::executeAction leOLPApplyGroupDesignLPPs -in $a            
        }
    }
}

proc onPostWindowCreated {w} {
    if {"leLayout"==[db::getAttr windowType.name -of $w]} {
        amdLayoutLSWDisplay
    }
}

proc onPreWindowDestroyed {w} {
    variable lswWT
    if {[db::getAttr windowType.name -of $w]==$lswWT} {
        db::setPrefValue amdLayoutAMDLSWWindowLastLoc -value [db::getAttr geometry -of $w]
    }
}

proc amdLeAMDLSWLayerLoadUserFile {{userFile ""} {verbose 1} {w ""}} {
    if {""==$userFile} {
        if {[info exist ::amd::GVAR_amdEnvVariables(amdAMDLSWUserOwnedCurrentFileName)]} {
            set userFile $::amd::GVAR_amdEnvVariables(amdAMDLSWUserOwnedCurrentFileName)
        }
    }
    set userfile [amdLeAMDLSWLayerResolveUserOwnedFileEntry $userFile]
    if {""!=$userfile} {
        if {-1==[string first "/" $userfile]} {
            set userfile [file normalize [file join $::env(HOME) ".synopsys_custom/AMDLSW" $userfile]]
        }
        set cantReadFile 0
        if {[catch {source $userfile}]} {
            # Try to parse old format 
            set cantReadFile [amdReadOldTemplate $userfile]
        }
        if {!$cantReadFile} {
            amdCleanUpLayVariables
            de::sendMessage "Read In User AMDLSW: $userfile"
            amdLeAMDLSWLegacyUpdate
            if {[file dirname $userfile] == [file join $::env(HOME) ".synopsys_custom/AMDLSW"]} {
                set userfile [file tail $userfile]
            }
            set amd::GVAR_amdEnvVariables(amdAMDLSWUserOwnedCurrentFileName) $userfile
            set win [amdGetLSWConfigInstance]
            if {""!=$win} {
                set amdLeAMDLSWLayerRemoveField [gi::findChild amdLeAMDLSWLayerRemoveField -in $win]
                db::setAttr selection -of $amdLeAMDLSWLayerRemoveField -value {}
                set amdLeAMDLSWLayerAddField [gi::findChild amdLeAMDLSWLayerAddField -in $win]
                db::setAttr selection -of $amdLeAMDLSWLayerAddField -value {}
                set amdLeAMDLSWLayerChooselayerSetName [gi::findChild amdLeAMDLSWLayerChooselayerSetName -in $win]
                amdLeAMDLSWLayerSelectSetNameCurrent $amdLeAMDLSWLayerChooselayerSetName
                set amdLeAMDLSWLayerButtonListField [gi::findChild amdLeAMDLSWLayerButtonListField -in $win]
                giSetDynamicListValue $amdLeAMDLSWLayerButtonListField [amdLeAMDLSWLayerSelectGetNameList]
                set amdLeAMDLSWLayerButtonRemovedField [gi::findChild amdLeAMDLSWLayerButtonRemovedField -in $win]
                giSetDynamicListValue $amdLeAMDLSWLayerButtonRemovedField [amdLeAMDLSWLayerSelectGetRemovedNameList]                
                amdLeAMDLSWLayerSelectSwapButtonBoxes
                amdLeAMDLSWLayerUpdateUserOwnedFileListField
            }
        } else {
            set msg "Failed to ReadTable on AMDLSW User File:\n\n$userFile\n"
            de::sendMessage $msg -severity error
            amdLeAMDLSWLayerResolveUserOwnedFileQueryFailed $msg
        }
    } else {
        if {$verbose} {
            set msg "amdLeAMDLSWLayerSaveUserFile:\nNull User File Resolved:\n\n$userFile"
            de::sendMessage $msg -severity error
            amdLeAMDLSWLayerResolveUserOwnedFileQueryFailed $msg
        }
    }
}


proc amdReadOldTemplate {fileName} {
    set fh [open $fileName "r"]
    set fileData [read $fh]
    close $fh
    
    set tmpDir /tmp
    if {[info exist $::env(TMPDIR)]} {
        set tmpDir $::env(TMPDIR)
    }
    set tmpFileName [file join $tmpDir "$::env(USER)_[file tail $fileName]"]
    set fh [open $tmpFileName "w"]
    set res 0
    set data [split $fileData "\n"]
    foreach line $data {
        if {[regexp {^\s?(\([^\)]*\))(.*)} $line match key value]} {
            set res 1
            set key [string map {\" ""} $key]
            set key [string map {( "" ) "" } $key]
            set key [join $key ","]
            set value [string map {\( \{ \) \} } $value]
            set value [string trim $value]
            if {"nil"==$value} {
                set value {}
            }
            puts $fh "set ::amd::GVAR_amdLayVariables($key) $value"
        } elseif {[regexp {^\s?([^\s]+)(.*)} $line match key value]} {
            set res 1
            set key [string map {\" ""} $key]
            set key [string map {( "" ) "" } $key]
            set key [join $key ","]
            set value [string map {( \{ ) \} } $value]
            set value [string trim $value]
            puts $fh "set ::amd::GVAR_amdLayVariables($key) $value"
        }
    }
    close $fh
    return [catch {source $tmpFileName}]
}


proc amdLeAMDLSWLegacyUpdate {} {
    set keys [list amdLayoutAMDLSWLayers amdLayoutAMDLSWUserRemovedLayerSets]
    foreach key $keys {
        if {[info exist ::amd::GVAR_amdLayVariables(key)]} {
            if {[member {"StdCells" "stdcells"} $::amd::GVAR_amdLayVariables($key)]} {
                set ::amd::GVAR_amdLayVariables($key) [remove {"StdCells" "stdcells"} $::amd::GVAR_amdLayVariables($key)] 
            }
            if {[member {"Macros" "macros"} $::amd::GVAR_amdLayVariables($key)]} {
                set ::amd::GVAR_amdLayVariables($key) [remove {"Macros" "macros"} $::amd::GVAR_amdLayVariables($key)] 
            }             
        }
    
    }
}


proc amdLeAMDLSWLayerResolveUserOwnedFileQueryFailed {msg {refWin ""}} {
    if {""==$refWin} {
        set refWin [amdGetLSWConfigInstance]
    }
    if {""!=$refWin} {
        set query [gi::prompt $msg -title "File Does Not Exist..." -buttons {Close} -default "Close" -cancel "Close" -icon "error" -name amdLeAMDLSWLayerResolveUserOwnedFileQueryFailedDBox -parent $refWin]
    } else {
        set query [gi::prompt $msg -title "File Does Not Exist..." -buttons {Close} -default "Close" -cancel "Close" -icon "error" -name amdLeAMDLSWLayerResolveUserOwnedFileQueryFailedDBox]
    }
    return $query
}

proc amdLeAMDLSWLayerResolveUserOwnedFileEntry {{userFile ""}} {
    if {""!=$userFile} {
        if {-1!=[string first "/" $userFile]} {
            set normalizePath [file normalize $userFile]
            set dirName [file dirname $normalizePath]
            if {$dirName == [file join $::env(HOME) ".synopsys_custom/AMDLSW"]} {
                return [file tail $userFile]
            } else {
                return $normalizePath
            }
        }
    }
    return $userFile
}


proc amdLeAMDLSWLayerStoreCadLists {} {
    set ::amd::GVAR_amdLayVariables(SaveCadAmdLayoutAlias) {}
    array set SaveCadAmdLayoutAlias {}
    foreach key [amdLeAMDLSWLayerGetUserOwnedCadKeys] {
        set SaveCadAmdLayoutAlias($key) $::amd::GVAR_amdLayVariables($key)
    }
    set ::amd::GVAR_amdLayVariables(SaveCadAmdLayoutAlias) [array get SaveCadAmdLayoutAlias]
}


proc amdLeAMDLSWLayerGetUserOwnedCadKeys {} {
    set keys {}
    foreach x [array name ::amd::GVAR_amdLayVariables] {
        if {[regexp {amdLayoutAlias} $x]} {
            set setNm [string range $x [expr [string first "," $x]+1] end ]
            if {![member $setNm {"always_on" "all" "always_off"}]} {
                lappend keys $x
            }
        }
        if {"amdLayoutAMDLSWLayers"==$x || "amdLayoutAMDLSWUserRemovedLayerSets"==$x} {
            lappend keys $x
        }
    }
    return $keys
}


proc amdLayoutLSWDisplay {} {
    set w [amdGetLSWInstance]
    if {""==$w} {
        variable lswWT
        set w [gi::createWindow -windowType [gi::getWindowTypes $lswWT]]
        amdLayoutLSWBuildForm
        if {""!=[db::getPrefValue amdLayoutAMDLSWWindowLastLoc]} {
            db::setAttr geometry -of $w -value [db::getPrefValue amdLayoutAMDLSWWindowLastLoc]
        }
    } else {
        # Save the last location...
        db::setPrefValue amdLayoutAMDLSWWindowLastLoc -value [db::getAttr geometry -of $w]
        gi::setActiveWindow $w -raise true
        db::setAttr iconified -of $w -value false        
    }
}


proc amdLayoutLSWBuildForm {} {
    set w [amdGetLSWInstance]
    if {""==$w} {
        return 
    }
    set ns [namespace current]
    set showButtons 0
    if {!$showButtons} {
        set tb [gi::createToolbar amdLSW]        
        gi::addToolbar $tb -to $w
        gi::addActions { 
            amdSetAllVisible
            amdSetAllInvisible
            amdSetAllSelectable 
            amdSetAllUnselectable} \
            -to $tb
        if {[db::getPrefValue amdLeAMDLSWShowApllyActiveDesignOnlyButton]} {
            gi::addActions { amdApplyActiveDesign } -to $tb            
        }
    } else {
        set gr [gi::createInlineGroup gr1 -parent $w]
        set av [gi::createPushButton av -parent $gr -label "AV" -execProc ${ns}::amdAVCB]
        set nv [gi::createPushButton nv -parent $gr -label "NV" -execProc ${ns}::amdNVCB]
        set as [gi::createPushButton as -parent $gr -label "AS" -execProc ${ns}::amdASCB]
        set ns [gi::createPushButton ns -parent $gr -label "NS" -execProc ${ns}::amdNSCB]
        db::setAttr av.styleSheet -value "QPushButton {width: 26px; height: 24px; padding: 0;}"
        db::setAttr nv.styleSheet -value "QPushButton {width: 26px; height: 24px; padding: 0;}"
        db::setAttr as.styleSheet -value "QPushButton {width: 26px; height: 24px; padding: 0;}"
        db::setAttr ns.styleSheet -value "QPushButton {width: 26px; height: 24px; padding: 0;}"
    }
    
    set ch1 [gi::createBooleanInput amdLeAMDLSWSelectInstSet -parent $w \
    -label "Inst" \
    -value [db::getAttr selectable -of [de::getObjectFilters leInstance]] \
    -valueChangeProc ${ns}::amdLeInstOnOff] 
    set ch2 [gi::createBooleanInput amdLeAMDLSWSelectPinSet -parent $w \
    -label "Pin" \
    -value [db::getAttr selectable -of [de::getObjectFilters lePin]] \
    -valueChangeProc ${ns}::amdLePinOnOff]
    set ch3 [gi::createBooleanInput amdLeAMDLSWSelectBlockage -parent $w \
    -label "Blockage" \
    -value [db::getAttr selectable -of [de::getObjectFilters leBlockage]] \
    -valueChangeProc ${ns}::amdLeBlockOnOff]        
    
    gi::layout $ch2 -rightOf $ch1
    gi::layout $ch3 -rightOf $ch2
    
    set sa [gi::createScrollArea sa -parent $w -rowsToShow 28]
    amdLayoutLSWAddButtonList
    db::setAttr title -of $w -value "AMD LSW v#1"
    return $w
}


proc amdLayoutLSWAddButtonList {{win ""}} {
    if {""==$win} {
        set win [amdGetLSWInstance]
    }
    set winMaxHeight 924
    set btnW 16
    set btnH 16
    set ns [namespace current]
    set sa [gi::findChild sa -in $win]
    db::destroy [db::getAttr children -of $sa]
    set btnc 0
    foreach layer $::amd::GVAR_amdLayVariables(amdLayoutAMDLSWLayers) {
        set layerDesc [lindex $layer 0]
        set layerRealName [lindex $layer 1]
        if {$layerDesc != "Blockage" && $layerDesc != "ERC DRD"} {
            # Change Layer
            set btn1 [gi::createPushButton -parent $sa -label $layerDesc -execProc "${ns}::amdLSWLayoutViewLayer \"$layerRealName\" change 1"]
            db::setAttr btn1.styleSheet -value "QPushButton {width: 70px; height: ${btnH}px; padding: 0;}"
            set btn2 [gi::createPushButton -parent $sa -label "+" -execProc "${ns}::amdLSWLayoutViewLayer \"$layerRealName\" add 1"]
            set btn3 [gi::createPushButton -parent $sa -label "-" -execProc "${ns}::amdLSWLayoutViewLayer \"$layerRealName\" erase 1"] 
            set btn4 [gi::createPushButton -parent $sa -label "t" -execProc "${ns}::amdLSWLayoutViewLayer \"$layerRealName\" toggleTrack 1"] 
            set btn5 [gi::createPushButton -parent $sa -label "x" -execProc "${ns}::amdLSWLayoutViewLayer \"$layerRealName\" intersect 1"]                     

            # Add
            #set btn2 [gi::createPushButton -parent $sa -execProc "${ns}::amdLSWLayoutViewLayer \"$layerRealName\" add 1" -icon cdf_add_parameter -toolTip "Add"]
            # Remove
            #set btn3 [gi::createPushButton -parent $sa -execProc "${ns}::amdLSWLayoutViewLayer \"$layerRealName\" erase 1" -icon delete -toolTip "Delete"]
            # Toggle
            #set btn4 [gi::createPushButton -parent $sa -execProc "${ns}::amdLSWLayoutViewLayer \"$layerRealName\" toggleTrack 1" -icon reshape_shape -toolTip "Track"]  
            # Intersect
            #set btn5 [gi::createPushButton -parent $sa -execProc "${ns}::amdLSWLayoutViewLayer \"$layerRealName\" intersect 1" -icon connect_wires -toolTip "Intersect"]                    
            #[db::getAttr name -of $btn2]:hover { border-right: 1px solid #000000; border-left: 1px solid white; border-top: 1px solid white; border-bottom: 1px solid #000000;}
            db::setAttr btn2.styleSheet -value "QPushButton {width: ${btnW}px; height: ${btnH}px; padding: 0;}"
            db::setAttr btn3.styleSheet -value "QPushButton {width: ${btnW}px; height: ${btnH}px; padding: 0;}"
            db::setAttr btn4.styleSheet -value "QPushButton {width: ${btnW}px; height: ${btnH}px; padding: 0;}"
            db::setAttr btn5.styleSheet -value "QPushButton {width: ${btnW}px; height: ${btnH}px; padding: 0;}"
            gi::layout $btn2 -rightOf $btn1
            gi::layout $btn3 -rightOf $btn2
            gi::layout $btn4 -rightOf $btn3
            gi::layout $btn5 -rightOf $btn4
            if {![db::getPrefValue amdLeAMDLSWShowToggle]} {
                db::setAttr shown -of $btn4 -value 0
            }
            incr btnc
         }
    }
    foreach button [concat $::amd::GVAR_amdLayVariables(amdLayoutAMDLSWFunctions) $::amd::GVAR_amdLayVariables(amdLayoutAMDLSWUserOwnedFunctions)]  {
        set type [lindex $button 0]
        if {"button" == $type} {
            set funcDesc [lindex $button 1]
            set callback [lindex $button 2]
            set enabled [lindex $button 3]
            if {"Change Layer"==$funcDesc} {
                set btn [gi::createPushButton -parent $sa -label $funcDesc -execProc "$callback" -enabled $enabled]
                db::setAttr btn.styleSheet -value "QPushButton {width: 176px; height: ${btnH}px; padding: 0;}"
                incr btnc
            }
        }
    }   

    set lswGeom [db::getAttr geometry -of $win]
    if {[regexp {(\d+)x(\d+)\+(-?\d+)\+(-?\d+)} $lswGeom match ww wh xp yp]} {
        set btnRealHeight [expr $btnH+4]
        set calcH [expr $btnc*($btnRealHeight + 6) + 124]
        if {""==[db::getPrefValue amdLayoutAMDLSWWindowLastLoc]} {
            set ww 216
            set xp "80%"
            set yp "10%"
        }        
        if {$calcH<$winMaxHeight} {
            db::setAttr geometry -of $win -value "${ww}x${calcH}+$xp+$yp"
        }
    } 
    gi::setActiveWindow $win -raise true
    db::setAttr iconified -of $win -value false        
}



proc amdAVCB {{btn ""}} {
    amdSyncObjSelWithLSW
    leSetAllLayerVisible 1
    db::setAttr visible -of [de::getObjectFilters leBoundaryPR] -value 1
    db::foreach ctx [de::getContexts] {
        db::setAttr visible -of [de::getObjectFilters leBoundaryPR -from $ctx] -value 1
    }
    de::redraw
}


proc amdNVCB {{btn ""}} {
    amdSyncObjSelWithLSW
    leSetAllLayerVisible 0
    db::setAttr visible -of [de::getObjectFilters leBoundaryPR] -value 0
    db::foreach ctx [de::getContexts] {
        db::setAttr visible -of [de::getObjectFilters leBoundaryPR -from $ctx] -value 0
    }
    de::redraw
}


proc amdASCB {{btn ""}} {
    amdSyncObjSelWithLSW
    leSetAllLayerSelectable 1
    db::setAttr selectable -of [de::getObjectFilters leBoundaryPR] -value 1
    db::foreach ctx [de::getContexts] {
        db::setAttr selectable -of [de::getObjectFilters leBoundaryPR -from $ctx] -value 1
    }
    de::redraw
}


proc amdNSCB {{btn ""}} {
    amdSyncObjSelWithLSW
    leSetAllLayerSelectable 0
    db::setAttr selectable -of [de::getObjectFilters leBoundaryPR] -value 0
    db::foreach ctx [de::getContexts] {
        db::setAttr selectable -of [de::getObjectFilters leBoundaryPR -from $ctx] -value 0
    }
    de::redraw
}

proc amdToggleApplyActive {a} {
    db::setPrefValue amdLeAMDLSWApllyActiveDesignOnly -value [db::getAttr checked -of $a]
}

proc amdLeInstOnOff {btn} {
    set val [db::getAttr value -of $btn]
    db::setAttr selectable -of [de::getObjectFilters leInstance] -value $val
    db::foreach ctx [de::getContexts] {
        db::setAttr selectable -of [de::getObjectFilters leInstance -from $ctx] -value $val
    }
    amdSyncObjSelWithLSW
}


proc amdLePinOnOff {btn} {
    set val [db::getAttr value -of $btn]
    db::setAttr selectable -of [de::getObjectFilters lePin] -value $val
    db::foreach ctx [de::getContexts] {
        db::setAttr selectable -of [de::getObjectFilters lePin -from $ctx] -value $val
    }
    amdSyncObjSelWithLSW
}


proc amdLeBlockOnOff {btn} {
    set ns [namespace current]
    after idle ${ns}::amdLeBlockOnOffIdle [db::getAttr value -of $btn]
    #set val [db::getAttr value -of $btn]
}

proc amdLeBlockOnOffIdle {val} {
    db::setAttr visible -of [de::getObjectFilters leBlockage] -value $val
    db::eval {
        set ih [db::createInterruptHandler "myInterrupt"]
        db::foreach ctx [de::getContexts -filter {"maskLayout"==%editDesign.viewType}] {
            set leB [de::getObjectFilters leBlockage -from $ctx] 
            if {[db::getAttr visible -of $leB]!=$val} {
                db::setAttr visible -of $leB -value $val
            }
            db::checkForInterrupt -handler $ih
        }
    }
}

proc amdSyncObjSelWithLSW {} {
    set w [amdGetLSWInstance]
    if {""!=$w} {
        amdLetogglePinLabels [gi::findChild amdLeAMDLSWSelectPinSet.value -in $w]
        db::setAttr value -of [gi::findChild amdLeAMDLSWSelectInstSet -in $w] -value [db::getAttr selectable -of [de::getObjectFilters leInstance]]
        db::setAttr value -of [gi::findChild amdLeAMDLSWSelectPinSet -in $w] -value [db::getAttr selectable -of [de::getObjectFilters lePin]]
    }
}


proc amdLetogglePinLabels {val} {
    if {![catch {set oaDes [ed]}]} {
        if {"maskLayout"==[db::getAttr viewType -of $oaDes]} {
            set layers [lsort -unique [db::createList  [db::getAttr layerNum -of  [db::getShapes -of $oaDes -filter {%pin!=""}]]]]
            foreach l $layers {
                set layerName [getLayerName $l $oaDes]
                set lpp [de::getLPPs [list $layerName pin] -from $oaDes]
                if {![db::isEmpty $lpp]} {
                    db::setAttr selectable -of $lpp -value $val
                }
            }
        }
    }
}


proc amdLSWLayoutViewLayer {layers {cmdOpt "change"} {setVis 1} {btn ""}} {
    amdSyncObjSelWithLSW
    amdLSWLayoutViewOrSelectLayer $layers $setVis $cmdOpt
}


proc amdLSWLayoutViewOrSelectLayer {layers setVis {cmdOpt "change"}} {
    set TIME_start_main [clock clicks -milliseconds]
    set w [amdGetLSWInstance]
    if {""==$layers} {
        db::foreach w [gi::getWindows -filter {%windowType.name=="leLayout"}] {
            gi::executeAction leOLPSetAllVisible -in [gi::getAssistants leObjectLayerPanel -from $w]
        }
        return
    } else {
        if {[member $cmdOpt [list "change" "add" "erase" "toggle" "toggleTrack" "intersect"]]} {
            array set layerAbbrevLay {}
            if {[info exist :amd::GVAR_amdEnvVariables(amdInterpreterLayerAbbrevLay)]} {
                array set layerAbbrevLay $::amd::GVAR_amdEnvVariables(amdInterpreterLayerAbbrevLay)
            }
            set layerList {}
            set all $::amd::GVAR_amdLayVariables(amdLayoutAlias,all)
            
            foreach layerName [split $layers " "] {
                if {"border"==$layerName} {
                    lappend layerList [list "border" "border"]
                    continue
                }
                if {![regexp {\-(.*)} $layerName match suf]} {
                    set suf "drw"
                }
                set purpose ""
                
                if {[info exist layerAbbrevLay($suf))]} {
                    set purpose $layerAbbrevLay($suf)
                }
                # Find the layer first.
                set newLayerName [string tolower $layerName]
                
                # Build a layerList list which is a list of all layers to perform the action on.
                if {[info exist ::amd::GVAR_amdLayVariables(amdLayoutAlias,${newLayerName})]} {
                    # We have a alias.
                    set layerList [concat $layerList $::amd::GVAR_amdLayVariables(amdLayoutAlias,$newLayerName)]
                } else {
                    if {""==$purpose} {
                        de::sendMessage "vl/sl: bad suffix $suf; using drw instead" -severity warning
                        set purpose $layerAbbrevLay(drw)
                    }

                    if {[member [list $layerName $purpose] $all]} {
                        lappend layerList [list $layerName $purpose]
                    } elseif {[member [list $newLayerName $purpose] $all]} {
                        lappend layerList [list $newLayerName $purpose]
                    } else {
                        set newLayerName [string toupper $layerName]
                        if {[member [list $newLayerName $purpose] $all]} {
                            lappend layerList [list $newLayerName $purpose]
                        } else {
                            de::sendMessage "amdLSWLayoutViewOrSelectLayer: the layer $layerName-$purpose could not be found" -severity error
                        }
                    }
                }
            }

            ###set layerList [string map {\" ""} $layerList]
            # Now make sure that the list is only the valid layers.
            set lib $::amd::GVAR_amdEnvVariables(amdTechLibName)

            set enableOldVersion 1

            if {!$enableOldVersion} {
                set olpGr [de::createOLPGroup AMDGR -from [oa::LibFind $lib]]
            }
            ###set oaTech [techGetTechFile $lib]
            ###set validLayers [leGetValidLayerList]

            variable techLPPs
            set validLayers $techLPPs
            
            set newLayerList {}
            foreach lpp $layerList {
                if {[member $lpp $validLayers] || "border" == [lindex $lpp 0]} {\
                    lappend newLayerList $lpp
                }
            }
            set layerList $newLayerList
            # Now we have a layerList.  Perform the action on the layers 
            if {[llength $layerList]} {
                # If we are changing then set the current to the first in the list.
                # and turn everything off.
                if {"change"==$cmdOpt} {
                    if {![member [list border border] $layerList] || [llength $layerList]>1} {
                        set selectLPP ""
                        foreach lpp $layerList {
                            if {[cadr $lpp]=="drawing" && [car $lpp]!="CA" && [car $lpp]!="CAV" && [car $lpp]!="border"} {
                                set selectLPP $lpp
                                break
                            }
                        }
                        leSetEntryLayer $selectLPP
                        if {$setVis} {
                            if {$enableOldVersion} {
                                leSetAllLayerVisible 0
                            } else {
                                leSetOLPGroupAllLayerVisible 0 $olpGr
                            }
                        } else {
                            leSetAllLayerSelectable 0
                        }
                    }
                }
                
                if {"toggleTrack"==$cmdOpt} {
                    set cmdOpt "toggle"
                    set layerList [amdLeIsTrackLayer $layerList]
                }
                # If we are intersecting then pick one of the valid entries.
                if {"intersect"==$cmdOpt} {
                    # Intersect means make anything valid that is the intersection of the choice and what is on.
                    # Do this by filtering the layerList.     
                    if {$setVis} {
                        set visibleLayers [leGetVisibleLPPs]    
                    } else {
                        set visibleLayers [leGetSelectableLPPs]    
                    }
                    set newLayerList {}
                    foreach x $layerList {
                        if {[member $x $visibleLayers]} {
                            lappend newLayerList $x
                        }
                    }
                    set layerList $newLayerList
                    set selectLPP ""
                    if {![member [list border border] $layerList] && [llength $layerList] > 1} {
                        foreach lpp $layerList {
                            if {("CA"!=[car $lpp] && "drawing"==[cadr $lpp] && "border"!=[car $lpp])} {
                                set selectLPP $lpp
                                break
                            }
                        }
                        leSetEntryLayer $selectLPP
                    }
                    if {$setVis} {
                        if {$enableOldVersion} {
                            leSetAllLayerVisible 0
                        } else {
                            leSetOLPGroupAllLayerVisible 0 $olpGr
                        }
                    } else {
                        leSetAllLayerSelectable 0
                    }                     
                }
                
                set newM 0
                if {$newM} {
                    switch $cmdOpt {
                        "change" {
                            amdLeAMDLSWChangeAddGroup $layerList $setVis
                        }
                        "add" {
                            amdLeAMDLSWChangeAddGroup $layerList $setVis
                        }   
                        "erase" {
                            amdLeAMDLSWEraseGroup $layerList $setVis
                        }   
                        "toggle" {
                            amdLeAMDLSWToggleGroup $layerList $setVis
                        }       
                        "intersect" {
                            amdLeAMDLSWIntersectGroup $layerList $setVis
                        }                          
                    }
                } else {
                    foreach lpp $layerList {
                        switch $cmdOpt {
                            "change" {
                                if {$setVis} {
                                    if { "border"==[car $lpp]} {
                                        leSetObjectVisible leBoundaryPR 1
                                    } else {
                                        if {$enableOldVersion} {
                                            leSetLayerVisible $lpp 1
                                        } else {
                                            set deLPP [de::getLPPs $lpp -from $olpGr]
                                            db::setAttr selectable -of $deLPP -value 1
                                        }
                                    }
                                } else {
                                    leSetLayerSelectable $lpp 1 
                                }
                            }
                            "add" {
                                if {$setVis} {
                                    if { "border"==[car $lpp]} {
                                        leSetObjectVisible leBoundaryPR 1
                                    } else {
                                        if {$enableOldVersion} {
                                            leSetLayerVisible $lpp 1
                                        } else {
                                            set deLPP [de::getLPPs $lpp -from $olpGr]
                                            db::setAttr selectable -of $deLPP -value 1
                                        }
                                    }
                                } else {
                                    leSetLayerSelectable $lpp 1 
                                }
                            }
                            "erase" {
                                # Turn off layer...
                                if {$setVis} {
                                    if { "border"==[car $lpp]} {
                                        leSetObjectVisible leBoundaryPR 0
                                    } else {
                                        if {$enableOldVersion} {
                                            leSetLayerVisible $lpp 0
                                        } else {
                                            set deLPP [de::getLPPs $lpp -from $olpGr]
                                            db::setAttr visible -of $deLPP -value 0
                                        }
                                    }
                                } else {
                                    leSetLayerSelectable $lpp 0 
                                }                            
                            }
                            "toggle" {
                                if { "border"==[car $lpp]} { 
                                    set val [expr ![db::getAttr visible -of [de::getObjectFilters leBoundaryPR]]]
                                    leSetObjectVisible leBoundaryPR $val
                                } else {
                                    if {$setVis} {
                                        set s [leIsLayerVisible $lpp]
                                    } else {
                                        set s [leIsLayerSelectable $lpp]
                                    }         
                                    if {$s} {
                                        if {[leGetEntryLayer]==$lpp} {
                                            amdLayoutPickAnotherLayer $lpp
                                        }
                                        # Turn off layer...
                                        if {$setVis} {
                                            if {$enableOldVersion} {
                                                leSetLayerVisible $lpp 0
                                            } else {
                                                set deLPP [de::getLPPs $lpp -from $olpGr]
                                                db::setAttr visible -of $deLPP -value 0
                                            }
                                        } else {
                                            leSetLayerSelectable $lpp 0
                                        }                                     
                                    } else {
                                        # Turn on layer...
                                        if {$setVis} {
                                            if {$enableOldVersion} {
                                                leSetLayerVisible $lpp 1
                                            } else {
                                                set deLPP [de::getLPPs $lpp -from $olpGr]
                                                db::setAttr selectable -of $deLPP -value 1
                                            }
                                        } else {
                                            leSetLayerSelectable $lpp 1
                                        }                                 
                                    }
                                }
                            }
                            "intersect" {
                                if {$setVis} {
                                        if {$enableOldVersion} {
                                            leSetLayerVisible $lpp 1
                                        } else {
                                            set deLPP [de::getLPPs $lpp -from $olpGr]
                                            db::setAttr visible -of $deLPP -value 1
                                        }
                                } else {
                                    leSetLayerSelectable $lpp 1
                                }
                            }
                            default {
                                de::sendMessage "Do not know what to do with $cmdOpt" -severity error
                            }
                        }
                    }
                }
                
                # Make sure the always on list is on.
                if { "change"==$cmdOpt} {
                    set always_on $::amd::GVAR_amdLayVariables(amdLayoutAlias,always_on)
                    set always_on [string map {\" ""} $always_on]
                    foreach lpp $always_on {
                        if {$setVis} {
                            leSetLayerVisible $lpp 1
                        } else {
                            leSetLayerSelectable $lpp 1
                        }
                    }
                }
                if {!$enableOldVersion} {
                    applyOLPGroup $olpGr
                }
            }
        }
    }
    set t [expr [clock clicks -milliseconds] - $TIME_start_main]
    set wc [db::getCount [getLEWindows]]
    if {$wc} {
        puts "amdLSWLayoutViewOrSelectLayer: cmdOpt = $cmdOpt Group Name = $layerName [expr $t/(1000.0*$wc)] sec. per window"
    }
    
    if {[db::getPrefValue amdLeAMDLSWRedraw]} {
        catch {de::redraw}
    }
}


proc amdLeAMDLSWChangeAddGroup {layerList setVis} {
    db::foreach w [getLEWindows] {
        set ctx [de::getContexts -window $w]
        set activeLPP [db::getAttr lpp -of [de::getActiveLPP -design $ctx]]
        foreach lpp $layerList {
            if {"border"==[car $lpp]} {
                db::setAttr visible -of [de::getObjectFilters leBoundaryPR -from $ctx] -value 1
            } else {
                set deLPP [db::getNext [de::getLPPs $lpp -from $ctx]]
                if {""!=$deLPP} {
                    db::setAttr selectable -of $deLPP -value 1
                }
            }
        }
    }
}

proc amdLSWCreateWindowProc {w} {
    #puts amdLSWCreateWindowProc
}


proc amdLSWConfigCreateWindowProc {w} {
}


proc amdLeAMDLSWConfig {wId {layerSet ""} {forceLoad 0}} {
    if {""==$layerSet} {
        if {[info exist ::amd::GVAR_amdLayVariables(amdLayoutAMDLSWLayerSelectCurrentName)]} {
            set layerSet $::amd::GVAR_amdLayVariables(amdLayoutAMDLSWLayerSelectCurrentName)
        } else {
            set layerSet [cadar $::amd::GVAR_amdLayVariables(amdLayoutAMDLSWLayers)]
        }
    }
    set layerSetName [amdLeAMDLSWLayerSelectGetNameFromSet $layerSet]
    if {!$forceLoad} {
        if {[info exist ::amd::GVAR_amdLayVariables(amdLeAMDLSWConfig)]} {
            set forceLoad $::amd::GVAR_amdLayVariables(amdLeAMDLSWConfig)
        } else {
            set forceLoad 1
        }
    }
    if {![info exist ::amd::GVAR_amdLayVariables(amdLayoutLSW,all)]} {
        set ::amd::GVAR_amdLayVariables(amdLayoutLSW,all) ""
    }
    if {![info exist ::amd::GVAR_amdLayVariables(amdLayoutAlias,all)]} {
        set ::amd::GVAR_amdLayVariables(amdLayoutAlias,all) ""
    }
    
    if {""==$::amd::GVAR_amdLayVariables(amdLayoutAlias,all) || ""==$::amd::GVAR_amdLayVariables(amdLayoutLSW,all)} {
        # Populate the "all" layers from the techlib that we are suppose to be using.
        set lib $::amd::GVAR_amdEnvVariables(amdTechLibName)
        set oaTech [techGetTechFile $lib]
        set all [leGetValidLayerList $oaTech]
        set all [string map {\" ""} $all]
        set ::amd::GVAR_amdLayVariables(amdLayoutLSW,all) $all
        set ::amd::GVAR_amdLayVariables(amdLayoutAlias,all) $all
    }
    set ns [namespace current]
    variable lswConfigWT
    set lswWin [amdGetLSWInstance]
    set cfgWin [amdGetLSWConfigInstance]
    set isWinExist 0

    if {""==$cfgWin} {
        set cfgWin [gi::createWindow -windowType [gi::getWindowTypes $lswConfigWT]]
        db::setAttr title -of $cfgWin -value "AMDLSW Configuration"
        db::setAttr geometry -of $cfgWin -value [amdLeAMDLSWLayerGetNewWinBbox $lswWin $cfgWin]
    } else {
        set isWinExist 1
        gi::setActiveWindow $cfgWin -raise true
        db::setAttr iconified -of $cfgWin -value false
    }
    
    if {$forceLoad || !$isWinExist} {
        db::destroy [db::getAttr children -of $cfgWin]
        set tabf [gi::createTabGroup tabf -parent $cfgWin]
        set gr1 [gi::createGroup -parent $tabf -label "Layers"]
        set gr2 [gi::createGroup -parent $tabf -label "Buttons"]
        
        set btn1 [gi::createPushButton amdLeAMDLSWLayerDefaultCadAllList -parent $gr1 -label "Reset All Lists to CAD defaults" -execProc "${ns}::amdLeAMDLSWLayerRetrieveCadLayerLists 1"]
        set btn2 [gi::createPushButton amdLeAMDLSWLayerDefaultCadSingleList -parent $gr1 -label "<- Reset List to CAD Defaults" -execProc "${ns}::amdLeAMDLSWLayerRetrieveCadLayerLists 1"]
        
        set mienum [amdLeAMDLSWLayerSelectGetAllNameList 1]
        if {""==[db::getPrefValue amdLeAMDLSWLayerChooselayerSetName] || ![member $mienum [db::getPrefValue amdLeAMDLSWLayerChooselayerSetName]]} {
            db::setPrefValue amdLeAMDLSWLayerChooselayerSetName -value [lindex $mienum 0]
        }

        set mi1 [gi::createMutexInput amdLeAMDLSWLayerChooselayerSetName -parent $gr1 -label "Layer Set:" -enum $mienum -valueChangeProc "${ns}::amdLeAMDLSWLayerSelectSetNameCurrent" -prefName amdLeAMDLSWLayerChooselayerSetName]
        db::setAttr btn1.styleSheet -value "QPushButton {width: 220px;}"
        db::setAttr btn2.styleSheet -value "QPushButton {width: 220px;}"
        
        gi::layout $mi1 -leftOf $btn2
        gi::layout $btn1 -align $btn2
        
        set gr [gi::createGroup page1gr -parent $gr1]
        
        set refList [amdLeAMDLSWLayerSelectSortToString $::amd::GVAR_amdLayVariables(amdLayoutAlias,${layerSet}) [db::getPrefValue amdLeAMDLSWLayerSortSetsField] $layerSetName]
        
        set grtmp1 [gi::createGroup -parent $gr -decorated false]
        set lbl1 [gi::createLabel -parent $grtmp1 -label "Current Layers:"]
        set l1 [gi::createDynamicList amdLeAMDLSWLayerRemoveField -parent $grtmp1 -value $refList -readOnly true -selectionChangeProc "${ns}::amdLeAMDLSWLayerSelectRmButNameLinesFromValue"]
        set btn5 [gi::createPushButton amdLeAMDLSWLayerClrRemList -parent $grtmp1 -label "Clear" -execProc "${ns}::amdLeAMDLSWLayerClrRemListCB"]
        
        set grmiddle [gi::createGroup -parent $gr -decorated false]
        set btn3 [gi::createPushButton amdLeAMDLSWLayerUpdateLists -parent $grmiddle -icon resume -execProc "${ns}::amdLeAMDLSWLayerSelectSwapListBoxes \"\""]        
        
        set grtmp2 [gi::createGroup -parent $gr -decorated false]
        set lbl2 [gi::createLabel -parent $grtmp2 -label "Add Layers:"]
        set l2 [gi::createDynamicList amdLeAMDLSWLayerAddField -parent $grtmp2 -value {} -readOnly true -selectionChangeProc "${ns}::amdLeAMDLSWLayerSelectRmButNameLinesFromValue"]
        set btn6 [gi::createPushButton amdLeAMDLSWLayerClrAddList -parent $grtmp2 -label "Clear" -execProc "${ns}::amdLeAMDLSWLayerClrAddListCB"]
        
        gi::layout $grmiddle -rightOf $grtmp1
        gi::layout $grtmp2 -rightOf $grmiddle
        gi::layout $btn3 -justify center
        gi::layout $lbl1 -align $l1
        gi::layout $lbl2 -align $l2
        gi::layout $btn5 -align $l1
        gi::layout $btn6 -align $l2
        
        set mi2 [gi::createMutexInput amdLeAMDLSWLayerSortField -parent $gr -prefName amdLeAMDLSWLayerSortField -valueChangeProc "${ns}::amdLeAMDLSWLayerSelectSetSort 0" -label Sort -enum {"Name" "Purpose"} -viewType radio]
        set btn7 [gi::createBooleanInput amdLeAMDLSWLayerSortSetsField -parent $gr -prefName amdLeAMDLSWLayerSortSetsField -valueChangeProc "${ns}::amdLeAMDLSWLayerSelectSetSort 0" -label Sets]
        set mi3 [gi::createMutexInput amdLeAMDLSWLayerSortSetsChoiceField -parent $gr -prefName amdLeAMDLSWLayerSortSetsChoiceField -valueChangeProc "${ns}::amdLeAMDLSWLayerSelectSetSort 1" -label Sort -enum [amdLeAMDLSWLayerSelectGetSortNameList] -viewType combo -comboWidth 18]
        set btn4 [gi::createBooleanInput amdLeAMDLSWLayerSortFoldField -parent $gr -prefName amdLeAMDLSWLayerSortFoldField -valueChangeProc "${ns}::amdLeAMDLSWLayerSelectSetSort 0" -label FoldCase]
        gi::layout $btn7 -rightOf $mi2
        gi::layout $btn4 -rightOf $btn7
        gi::layout $mi3 -rightOf $btn4
        
        
        set l3 [gi::createDynamicList amdLeAMDLSWLayerButtonListField -parent $gr2 -value [amdLeAMDLSWLayerSelectGetNameList] -readOnly true]
        set gr [gi::createGroup page2gr -parent $gr2 -decorated false] 
        set btn7 [gi::createPushButton amdLeAMDLSWLayerButtonRefresh -parent $gr -icon "refresh" -label "AMDLSW" -execProc "${ns}::amdLeAMDLSWLayerRefreshButtonList"]
        gi::layout $gr -rightOf $l3
        set btn8 [gi::createPushButton amdLeAMDLSWLayerButtonUp -parent $gr -icon "arrow_up" -execProc "${ns}::amdLeAMDLSWLayerSelectMvButton up"]
        set btn9 [gi::createPushButton amdLeAMDLSWLayerButtonDown -parent $gr -icon "arrow_down" -execProc "${ns}::amdLeAMDLSWLayerSelectMvButton down"]
        set btn10 [gi::createPushButton amdLeAMDLSWLayerButtonSwap -parent $gr -icon "resume" -execProc "${ns}::amdLeAMDLSWLayerSelectSwapButtonBoxes"]
        gi::createLabel -parent $gr -label "Add/Remove Buttons"
        set l4 [gi::createDynamicList amdLeAMDLSWLayerButtonRemovedField -parent $gr -value [amdLeAMDLSWLayerSelectGetRemovedNameList] -readOnly true]
        
        set btn11 [gi::createPushButton amdLSWUserButton -parent $gr -label "User Defined Button" -execProc "${ns}::amdLeNewButtonform"]
        set btn12 [gi::createPushButton amdLeAMDLSWLayerButtonReset -parent $gr2 -label "Reset Buttons To CAD Defaults" -execProc "${ns}::amdLeAMDLSWLayerRetrieveCadButtonList 1"]
        
        set gr [gi::createGroup -parent $cfgWin -label "User File Names in ~/.synopsys_custom/AMDLSW/"]
        set btn13 [gi::createPushButton amdLeAMDLSWLayerButtonLoadIt -label "LOAD <-" -parent $gr -execProc "${ns}::amdLeAMDLSWLayerLoadUserFile \"\" 0"]
        set mi4 [gi::createTextInput amdLeAMDLSWLayerButtonFileField -parent $gr -prefName amdLeAMDLSWLayerButtonFileField -valueChangeProc "${ns}::amdLeAMDLSWLayerUpdateUserOwnedFileListField 0" -completions [amdLeAMDLSWLayerGetUserOwnedFileList]]
        set btn14 [gi::createPushButton amdLeAMDLSWLayerButtonSaveIt -label "<- SAVE" -parent $gr -execProc "${ns}::amdLeAMDLSWLayerSaveUserFile"]
        
        gi::layout $mi4 -rightOf $btn13
        gi::layout $btn14 -rightOf $mi4
        
        amdLeAMDLSWLayerSelectSetNameCurrent $mi1
    }
    
    
}


proc amdLeAMDLSWLayerSaveUserFile {{w ""}} {
    set cfgWin [amdFindLSWConfigWind $w]
    set userFile $::amd::GVAR_amdEnvVariables(amdAMDLSWUserOwnedCurrentFileName)
    set userfile [amdLeAMDLSWLayerResolveUserOwnedFileEntry $userFile]
    array set input_table {}
    if {""!=$userfile} {
        set user_bak ".${userfile}.bak"
        set keys [amdLeAMDLSWLayerGetUserOwnedCadKeys]
        if {[info exist ::amd::GVAR_amdLayVariables(amdLayoutAMDLSWUserOwnedFunctions)]} {
            set keys [concat $keys $::amd::GVAR_amdLayVariables(amdLayoutAMDLSWUserOwnedFunctions)]
            foreach key $keys {
                set input_table($key) $::amd::GVAR_amdLayVariables($key)
            }
            if {-1!=[string first "/" $userfile]} {
                set userfile [file tail $userfile]
                set user_bak ".${userfile}.bak"
                set query [amdLeAMDLSWLayerResolveUserOwnedFileQueryImport [file normalize $userFile] [file join $::env(HOME) ".synopsys_custom/AMDLSW" $userfile]]
                if {"No"==$query} {
                    set userfile ""
                }
            }
            if {""!=$userfile} {
                set userfile [file join $::env(HOME) ".synopsys_custom/AMDLSW" $userfile]
                set user_bak [file join $::env(HOME) ".synopsys_custom/AMDLSW" $user_bak]
                if {[file exist $userfile]} {
                    if {[file isfile $user_bak]} {
                        set query [amdLeAMDLSWLayerResolveUserOwnedFileQueryOverwrite $user_bak]
                        if {"Yes"==$query} {
                            if {[file exist $userfile]} {
                                file copy -force $userfile $user_bak
                            }
                        } else {
                            return 0
                        }
                    } else {
                        file copy -force $userfile $user_bak
                    }
                }
                amdLeAMDLSWLayerSaveUserTclFile $userfile [array get input_table]
                de::sendMessage "Saved: $userFile"
                amdLeAMDLSWLayerUpdateUserOwnedFileListField
                return
            }
        }
    } else {
        set msg "amdLeAMDLSWLayerSaveUserFile:\nNull User File Resolved:\n$userFile" 
        de::sendMessage $msg -severity warning
        amdLeAMDLSWLayerResolveUserOwnedFileQueryFailed $msg
    }
}


proc amdLeAMDLSWLayerSaveUserTclFile {userfile lst} {
    set fh [open $userfile "w"]
    puts $fh "namespace eval ::amd \{"
    puts $fh "namespace export *"
    puts $fh "variable GVAR_amdLayVariables"
    puts $fh "array set GVAR_amdLayVariables {}"
    foreach {key value} $lst {
        set key "set GVAR_amdLayVariables($key)"
        set value "\{$value\}"
        puts $fh "$key $value"
    }
    puts $fh "\}"
    close $fh
}

proc amdLeAMDLSWLayerResolveUserOwnedFileQueryImport {oldFile newFile} {
    set win [amdGetLSWConfigInstance]
    set msg "You can only LOAD, and not SAVE to an external file:\n"
    append msg $oldFile
    append msg "\n\nDo you want to save to file?:\n" 
    append msg $newFile    
    if {""!=$win} {
        set query [gi::prompt $msg -title "Save File Locally?" -buttons {Yes No} -default Yes -cancel No -icon question -name amdLeAMDLSWLayerResolveUserOwnedFileQueryImportYesNoDBox -parent $win]
    } else {
        set query [gi::prompt $msg -title "Save File Locally?" -buttons {Yes No} -default Yes -cancel No -icon question -name amdLeAMDLSWLayerResolveUserOwnedFileQueryImportYesNoDBox]
    }
    return $query
}

proc amdLeAMDLSWLayerUpdateUserOwnedFileListField {{fromDir 0} {w ""}} {
    if {""!=$w} {
        db::setPrefValue amdLeAMDLSWLayerButtonFileField -value [db::getAttr value -of $w]
    }
    set cfgWin [amdFindLSWConfigWind $w]
    set amdLeAMDLSWLayerButtonFileField [gi::findChild amdLeAMDLSWLayerButtonFileField -in $cfgWin]
    set newvalue [amdLeAMDLSWLayerResolveUserOwnedFileEntry [db::getPrefValue amdLeAMDLSWLayerButtonFileField]]
    # remove paths from file list, must be just name under ~/cadence/AMDLSW/...
    # need a tmp list so we can set value first, if it is not reduced to name only,
    # it will not fit as one of the items and cannot be removed when setting 'items'...    
    if {$fromDir} {
        set newlist [lsort -unique [amdLeAMDLSWLayerGetUserOwnedFileList]]
        if {""!=$newvalue} {
            if {![member $newvalue $$newlist]} {
                set newvalue [car $newlist]
                db::setPrefValue amdLeAMDLSWLayerButtonFileField -value $newvalue
            }
        }
    } else {
        set newlist [lsort -unique [concat [amdLeAMDLSWLayerGetUserOwnedFileList] [db::getAttr completions -of $amdLeAMDLSWLayerButtonFileField]]]
    }
    if {""!=$newvalue && [car $newlist]!=$newvalue} {
        set newlist [lsort -unique [concat $newvalue $newlist]]
        db::setPrefValue amdLeAMDLSWLayerButtonFileField -value $newvalue
    } else {
        db::setPrefValue amdLeAMDLSWLayerButtonFileField -value [car $newlist]
    }
    db::setAttr completions -of $amdLeAMDLSWLayerButtonFileField -value $newlist
    set ::amd::GVAR_amdEnvVariables(amdAMDLSWUserOwnedCurrentFileName) [db::getPrefValue amdLeAMDLSWLayerButtonFileField]
}


proc amdLeAMDLSWLayerGetUserOwnedFileList {} {
    set userFile $::amd::GVAR_amdEnvVariables(amdAMDLSWUserOwnedCurrentFileName)
    set files {}
    if {""!=$userFile} {
        set userFile [file normalize $userFile]
        set user_dir [file join $::env(HOME) ".synopsys_custom/AMDLSW/"]
        if {![file isdir $user_dir]} {
            file mkdir $user_dir
        }
        foreach f [glob -nocomplain [file join ${user_dir} *]] {
            set fName [file tail $f]
            if {![regexp {~$} $fName] && ![regexp {.bak$} $fName]} {
                lappend files $fName
            }
        }
    }
    lappend files $::amd::GVAR_amdEnvVariables(amdAMDLSWUserOwnedCurrentFileName) 
    set files [lsort -unique $files]
    return $files
}


proc amdLeAMDLSWLayerRetrieveCadButtonList {int w} {
    # Reset button list to saved Cad list.
    set query "Yes"
    if {""!=$int} {
        set query [amdLeAMDLSWLayerResolveUserOwnedFileQueryOverwrite "" "Reset Cad Buttons?" "Are you sure you want to Reset all Cad Buttons to the default CAD settings?"]
    }
    if {"Yes"==$query && [info exist ::amd::GVAR_amdLayVariables(SaveCadAmdLayoutAlias)]} {
        array set SaveCadAmdLayoutAlias $::amd::GVAR_amdLayVariables(SaveCadAmdLayoutAlias)      
        set amd::GVAR_amdLayVariables(amdLayoutAMDLSWLayers) $SaveCadAmdLayoutAlias(amdLayoutAMDLSWLayers)
        set amd::GVAR_amdLayVariables(amdLayoutAMDLSWUserRemovedLayerSets) $SaveCadAmdLayoutAlias(amdLayoutAMDLSWUserRemovedLayerSets)
        set cfgWin [getParentWindow $w]
        set amdLeAMDLSWLayerButtonListField [gi::findChild amdLeAMDLSWLayerButtonListField -in $cfgWin]
        giSetDynamicListValue $amdLeAMDLSWLayerButtonListField [amdLeAMDLSWLayerSelectGetNameList]
        set amdLeAMDLSWLayerButtonRemovedField [gi::findChild amdLeAMDLSWLayerButtonRemovedField -in $cfgWin]
        giSetDynamicListValue $amdLeAMDLSWLayerButtonRemovedField [amdLeAMDLSWLayerSelectGetRemovedNameList]     
        amdLeAMDLSWLayerSelectSwapButtonBoxes        
    }
}


proc amdLeNewButtonform {w} {
    set win [getParentWindow $w]
    set ns [namespace current]
    set dlgName "newButtonForm"
    set dlg [gi::createDialog $dlgName -title "User Defined LSW Button" -execProc "${ns}::amdLeAMDLSWLayerSelectAddButton" -parent $win]
    set tf [gi::createTextInput amdLSWUserButton -parent $dlg -label "Enter Button Name"]
    gi::execDialog $dlg
}

proc amdLeAMDLSWLayerSelectAddButton {dlg} {
    set butToAdd [gi::findChild amdLSWUserButton.value -in $dlg]
    set butToAdd [string trim $butToAdd]
    if {""!=$butToAdd} {
        set userDefBut [string tolower $butToAdd]
        set cfgWin [db::getAttr parent -of $dlg]
        set amdLeAMDLSWLayerButtonListField [gi::findChild amdLeAMDLSWLayerButtonListField -in $cfgWin]
        giSetDynamicListValue $amdLeAMDLSWLayerButtonListField [lappend [db::getAttr value -of $amdLeAMDLSWLayerButtonListField] $butToAdd]
        amdLeAMDLSWLayerRefreshButtonList
        lappend ::amd::GVAR_amdLayVariables(amdLayoutAMDLSWLayers) [list $butToAdd $userDefBut]
        amdLeAMDLSWLayerSelectSwapButtonBoxes
        set amdLeAMDLSWLayerChooselayerSetName [gi::findChild amdLeAMDLSWLayerChooselayerSetName -in $cfgWin]
        amdLeAMDLSWLayerSelectSetNameCurrent $amdLeAMDLSWLayerChooselayerSetName
        amdLeAMDLSWLayerRefreshButtonList
        amdLayoutLSWDisplay
        set ::amd::GVAR_amdLayVariables(amdLayoutAlias,${userDefBut}) ""
    }
}

proc amdLeAMDLSWLayerSelectSwapButtonBoxes {{w ""}} {
    set cfgWin [amdFindLSWConfigWind $w]
    # List of chosen layers to remove...
    set amdLeAMDLSWLayerButtonListField [gi::findChild amdLeAMDLSWLayerButtonListField -in $cfgWin]
    set butToRem [giGetDynamicListSelectedItems $amdLeAMDLSWLayerButtonListField]
    # List of chosen layers to add...
    set amdLeAMDLSWLayerButtonRemovedField [gi::findChild amdLeAMDLSWLayerButtonRemovedField -in $cfgWin]
    set butToAdd [giGetDynamicListSelectedItems $amdLeAMDLSWLayerButtonRemovedField]
    set totalSets $::amd::GVAR_amdLayVariables(amdLayoutAMDLSWLayers) 
    if {[info exist ::amd::GVAR_amdLayVariables(amdLayoutAMDLSWUserRemovedLayerSets)]} {
        set totalSets [concat $totalSets $::amd::GVAR_amdLayVariables(amdLayoutAMDLSWUserRemovedLayerSets)]
    }
    set totalButtons [amdLeAMDLSWLayerSelectGetAllNameList]
    set amdLeAMDLSWLayerChooselayerSetName [gi::findChild amdLeAMDLSWLayerChooselayerSetName -in $cfgWin]
    set currLaySet [db::getPrefValue amdLeAMDLSWLayerChooselayerSetName]
    
    # Remove values from Removed List, append values from Current list...
    set newRemvd {}
    foreach x [amdLeAMDLSWLayerSelectGetRemovedNameList] {
        if {![member $x $butToAdd]} {
            lappend newRemvd $x
        }
    }
    set newRemvd [concat $newRemvd $butToRem]

    # Remove values from Current list, append values from Remove List...
    set newCurrent {}
    foreach x [amdLeAMDLSWLayerSelectGetNameList] {
        if {![member $x $butToRem]} {
            lappend newCurrent $x
        }
    }
    set newCurrent [concat $newCurrent $butToAdd]    

    # Rebuld AMDLSW lists...
    set ::amd::GVAR_amdLayVariables(amdLayoutAMDLSWLayers) {}
    foreach x $totalSets {
        if {[member [car $x] $newCurrent]} {
            lappend ::amd::GVAR_amdLayVariables(amdLayoutAMDLSWLayers) $x
        }
    }
    set ::amd::GVAR_amdLayVariables(amdLayoutAMDLSWUserRemovedLayerSets) {}
    foreach x $totalSets {
        if {[member [car $x] $newRemvd]} {
            lappend ::amd::GVAR_amdLayVariables(amdLayoutAMDLSWUserRemovedLayerSets) $x
        }
    }
    
    # Just to make sure, append any missing ones to the Removed list...
    set goneMissing {}
    foreach x $totalButtons {
        if {![member $x $newCurrent] && ![member $x $newRemvd]} {
            lappend goneMissing $x
        }
    }
    if {""!=$goneMissing} {
        de::sendMessage "amdLeAMDLSWLayerSelectSwapButtonBoxes - Some Buttons were Lost!  Adding to Removed List: $goneMissing"
        set newRemvd [concat $newRemvd $goneMissing]
        foreach x $totalSets {
            if {[member [car $x] $goneMissing]} {
                lappend ::amd::GVAR_amdLayVariables(amdLayoutAMDLSWUserRemovedLayerSets) $x
            }            
        }
    }
    
    # Reset fields... (No Hidden layers to be on the button lists)
    giSetDynamicListValue $amdLeAMDLSWLayerButtonListField $newCurrent 
    giSetDynamicListValue $amdLeAMDLSWLayerButtonRemovedField $newRemvd
    # Init the layerset choice...  (Add Hidden layer choices to manipulate their lists)
    db::setAttr enum -of $amdLeAMDLSWLayerChooselayerSetName -value [amdLeAMDLSWLayerSelectGetAllNameList 1]
    if {[member $currLaySet [db::getAttr enum -of $amdLeAMDLSWLayerChooselayerSetName]]} {
        db::setAttr value -of $amdLeAMDLSWLayerChooselayerSetName -value $currLaySet
    } else {
        db::setAttr value -of $amdLeAMDLSWLayerChooselayerSetName -value [car [db::getAttr enum -of $amdLeAMDLSWLayerChooselayerSetName]]
    }
}


proc amdLeAMDLSWLayerSelectMvButton {dir w} {
    set win [getParentWindow $w]
    set amdLeAMDLSWLayerChooselayerSetName [gi::findChild amdLeAMDLSWLayerChooselayerSetName -in $win]
    set amdLeAMDLSWLayerButtonListField [gi::findChild amdLeAMDLSWLayerButtonListField -in $win]
    set selected [car [lsort -integer [db::getAttr selection -of $amdLeAMDLSWLayerButtonListField]]]
    set current_list [db::getAttr value -of $amdLeAMDLSWLayerButtonListField]
    set current_layerset [db::getPrefValue amdLeAMDLSWLayerChooselayerSetName]
    set source_list $::amd::GVAR_amdLayVariables(amdLayoutAMDLSWLayers)
    
    if {""!=$selected && (($dir=="up" && $selected > 0) || ($dir=="down" && $selected < [expr [llength $current_list] - 1]) )} {
        set ::amd::GVAR_amdLayVariables(amdLayoutAMDLSWLayers) ""
        for {set x 0} {$x<[llength $current_list]} {incr x} {
            if {"up"==$dir} {
                if {$x==$selected} {
                    set xpos [expr $x - 1]
                } elseif {$x==$selected - 1} {
                   set xpos [expr $x + 1]
                } else {
                    set xpos $x 
                }
            }
            if {"down"==$dir} {
                if {$x==$selected} {
                    set xpos [expr $x + 1]
                } elseif {$x==$selected + 1} {
                   set xpos [expr $x - 1]
                } else {
                    set xpos $x 
                }
            }  
            lappend ::amd::GVAR_amdLayVariables(amdLayoutAMDLSWLayers) [lindex $source_list $xpos]
        }
        giSetDynamicListValue $amdLeAMDLSWLayerButtonListField [amdLeAMDLSWLayerSelectGetNameList]
        if {"up"==$dir} {
            db::setAttr selection -of $amdLeAMDLSWLayerButtonListField  -value [expr $selected - 1]
        } else {
            db::setAttr selection -of $amdLeAMDLSWLayerButtonListField  -value [expr $selected + 1]
        }
        db::setAttr enum -of $amdLeAMDLSWLayerChooselayerSetName -value [amdLeAMDLSWLayerSelectGetAllNameList 1]
    }
}

proc amdLeAMDLSWLayerRefreshButtonList { {w ""}} {
    #amdCloseAMDLSWWindow
    amdReopenAMDLSWWindow
    amdLayoutLSWAddButtonList
}


proc amdCloseAMDLSWWindow {} {
    set win [amdGetLSWInstance]
    if {""!=$win} {
        gi::closeWindows $win
    }
}


proc amdReopenAMDLSWWindow {} {
    set win [amdGetLSWInstance]
    if {""==$win} {
        amdLayoutLSWDisplay
    }
}


proc amdLeAMDLSWLayerSelectRmButNameLinesFromValue {w} {
    # Strip posssible selection of the ----buttonName---- from value, prevents issues...
    set value [db::getAttr value -of $w]
    set selection {}
    foreach s [db::getAttr selection -of $w] {
        if {-1==[string first "--" [lindex $value $s]]} {
            lappend selection $s
        }
    }
    
    if {[llength $selection]!=[llength [db::getAttr selection -of $w]]} {
        after idle [list db::setAttr selection -of $w -value $selection]
    }
}


proc amdLeAMDLSWLayerRetrieveCadLayerLists {int w} {
    set query "Yes"
    set win [getParentWindow $w]
    if {"amdLeAMDLSWLayerDefaultCadSingleList"==[db::getAttr name -of $w]} {
        set keyNm [db::getPrefValue amdLeAMDLSWLayerChooselayerSetName]
        set title "Reset *$keyNm* list to CAD defaults?"
        set msg "Are you sure you want to Reset the *$keyNm* list to the default CAD settings?"
    } else {
        set keyNm ""
        set title "Reset *All* lists to CAD defaults?"
        set msg "Are you sure you want to Reset *All* lists to the default CAD settings?"
    }

    # Reset layer list to saved Cad list, for one button, or all.
    if {$int} {
        set query [amdLeAMDLSWLayerResolveUserOwnedFileQueryOverwrite "" $title $msg]
    }
    if {"Yes"==$query} {
        array set SaveCadAmdLayoutAlias $::amd::GVAR_amdLayVariables(SaveCadAmdLayoutAlias)      
        if {""!=$keyNm} {
            # convert Key name to table key...
            set key [amdLeAMDLSWLayerSelectGetSetFromName $keyNm]
            if {""!=$key} {
                set ::amd::GVAR_amdLayVariables(amdLayoutAlias,${key}) $SaveCadAmdLayoutAlias(amdLayoutAlias,${key})
            }
        } else {
            foreach key [array name SaveCadAmdLayoutAlias] {
                set ::amd::GVAR_amdLayVariables($key) $SaveCadAmdLayoutAlias($key)
            }
        }
        set amdLeAMDLSWLayerRemoveField [gi::findChild amdLeAMDLSWLayerRemoveField -in $win]
        db::setAttr selection -of $amdLeAMDLSWLayerRemoveField -value {}
        set amdLeAMDLSWLayerAddField [gi::findChild amdLeAMDLSWLayerAddField -in $win]
        db::setAttr selection -of $amdLeAMDLSWLayerAddField -value {}
        set amdLeAMDLSWLayerChooselayerSetName [gi::findChild amdLeAMDLSWLayerChooselayerSetName -in $win]
        amdLeAMDLSWLayerSelectSetNameCurrent $amdLeAMDLSWLayerChooselayerSetName
    }
}


proc amdLeAMDLSWLayerResolveUserOwnedFileQueryOverwrite {newFile {title "Overwrite Local File?"} {msg ""} {refWin ""}} {
    if {""==$refWin} {
        set refWin [amdGetLSWConfigInstance]
    }
    if {""==$msg} {
        set msg "You already have file:\n\n$newFile\n\nDo you want to OVERWRITE this file?\n"
    }
    if {""!=$refWin} {
        set query [gi::prompt $msg -title $title -buttons {"Yes" "No"} -default "Yes" -cancel "No" -icon "question" -name amdLeAMDLSWLayerResolveUserOwnedFileQueryOverwriteYesNoDBox -parent $refWin]
    } else {
        set query [gi::prompt $msg -title $title -buttons {"Yes" "No"} -default "Yes" -cancel "No" -icon "question" -name amdLeAMDLSWLayerResolveUserOwnedFileQueryOverwriteYesNoDBox]
    }
    return $query
}


proc amdLeAMDLSWLayerSelectSetNameCurrent {w} {
    set win [getParentWindow $w]
    db::setPrefValue amdLeAMDLSWLayerChooselayerSetName -value [db::getAttr value -of $w]
    set layerSet [amdLeAMDLSWLayerSelectGetSetFromName [db::getAttr value -of $w]]

    set refList [amdLeAMDLSWLayerSelectSortToString [lsort -unique $::amd::GVAR_amdLayVariables(amdLayoutAlias,${layerSet})] [db::getPrefValue amdLeAMDLSWLayerSortSetsField] [db::getAttr value -of $w]]
    set amdLeAMDLSWLayerRemoveField [gi::findChild amdLeAMDLSWLayerRemoveField -in $win]
    giSetDynamicListValue $amdLeAMDLSWLayerRemoveField $refList
    amdLeAMDLSWLayerSelectSetRemLayersNotInSet [db::getAttr value -of $w] $win
}


proc amdLeAMDLSWLayerSelectSetRemLayersNotInSet {layerNm win} {
    if {""==$layerNm} {
        set layerNm [db::getPrefValue amdLeAMDLSWLayerChooselayerSetName]
    }
    set layerSet [amdLeAMDLSWLayerSelectGetSetFromName $layerNm]
    set amdLeAMDLSWLayerRemoveField [gi::findChild amdLeAMDLSWLayerRemoveField -in $win]
    set layerRem [db::getAttr value -of $amdLeAMDLSWLayerRemoveField]
    if {""!=$layerRem} {
        set layerRem $::amd::GVAR_amdLayVariables(amdLayoutAlias,${layerSet})
    }
    
    set items {}
    foreach x $::amd::GVAR_amdLayVariables(amdLayoutAlias,all) {
        if {![member $x $layerRem]} {
            lappend items $x
        }
    }
    set refList [amdLeAMDLSWLayerSelectSortToString $items [db::getPrefValue amdLeAMDLSWLayerSortSetsField]]
    set amdLeAMDLSWLayerAddField [gi::findChild amdLeAMDLSWLayerAddField -in $win]
    db::setAttr value -of $amdLeAMDLSWLayerAddField -value $refList
}



proc amdLeAMDLSWLayerClrRemListCB {w} {
    set win [getParentWindow $w]
    set amdLeAMDLSWLayerRemoveField [gi::findChild amdLeAMDLSWLayerRemoveField -in $win]
    db::setAttr selection -of $amdLeAMDLSWLayerRemoveField -value {}
}


proc amdLeAMDLSWLayerClrAddListCB {w} {
    set win [getParentWindow $w]
    set amdLeAMDLSWLayerAddField [gi::findChild amdLeAMDLSWLayerAddField -in $win]
    db::setAttr selection -of $amdLeAMDLSWLayerAddField -value {}
}


proc amdLeAMDLSWLayerSelectSetSort {turnOnSets w} {
    if {"amdLeAMDLSWLayerSortFoldField" == [db::getAttr name -of $w]} {
        db::setPrefValue amdLeAMDLSWLayerSortFoldField -value [db::getAttr value -of $w]
    }
    if {"amdLeAMDLSWLayerSortField" == [db::getAttr name -of $w]} {
        db::setPrefValue amdLeAMDLSWLayerSortField -value [db::getAttr value -of $w]
    }
    if {"amdLeAMDLSWLayerSortSetsField" == [db::getAttr name -of $w]} {
        db::setPrefValue amdLeAMDLSWLayerSortSetsField -value [db::getAttr value -of $w]
    }
    if {"amdLeAMDLSWLayerSortSetsChoiceField" == [db::getAttr name -of $w]} {
        db::setPrefValue amdLeAMDLSWLayerSortSetsChoiceField -value [db::getAttr value -of $w]
    }    
    
    set win [getParentWindow $w]
    #set holdRem [gi::findChild amdLeAMDLSWLayerRemoveField.value -in $win]    
    #set holdAdd [gi::findChild amdLeAMDLSWLayerAddField.value -in $win] 
    set holdSetSort [gi::findChild amdLeAMDLSWLayerSortSetsField.value -in $win] 
    
    if {$turnOnSets && !$holdSetSort} {
        # TurnOnSets means Cyclic called this, but Sets button change will also call it again, so just set Sets...
        set amdLeAMDLSWLayerSortSetsField [gi::findChild amdLeAMDLSWLayerSortSetsField -in $win]
        db::setAttr value -of $amdLeAMDLSWLayerSortSetsField -value 1
        # Note, If Sets is turned off, cannot reset Cyclic to "ALL" or that will trigger the start of a loop between them...
    } else {
        set amdLeAMDLSWLayerRemoveField [gi::findChild amdLeAMDLSWLayerRemoveField -in $win]         
        set amdLeAMDLSWLayerAddField [gi::findChild amdLeAMDLSWLayerAddField -in $win]
        # Clear values...        
        #db::setAttr value -of $amdLeAMDLSWLayerRemoveField -value {}
        #db::setAttr value -of $amdLeAMDLSWLayerAddField -value {}
        # Update lists...
        amdLeAMDLSWLayerSelectSwapListBoxes "" $win
        # Restore list values...
        #db::setAttr value -of $amdLeAMDLSWLayerRemoveField -value $holdRem
        #db::setAttr value -of $amdLeAMDLSWLayerAddField -value $holdAdd
    }
}


proc amdLeAMDLSWLayerSelectSwapListBoxes { {layerNm ""} {w ""}} {
    set win [amdFindLSWConfigWind $w]
    if {""==$win} {
        return 
    }
    if {""==$layerNm} {
        set layerNm [db::getPrefValue amdLeAMDLSWLayerChooselayerSetName]
    }
    set layerSet [amdLeAMDLSWLayerSelectGetSetFromName $layerNm]
    set amdLeAMDLSWLayerRemoveField [gi::findChild amdLeAMDLSWLayerRemoveField -in $win]         
    set amdLeAMDLSWLayerAddField [gi::findChild amdLeAMDLSWLayerAddField -in $win] 
    
    # List of chosen layers to remove...
    set layerRem [amdLeAMDLSWLayerSelectStringToList [giGetDynamicListSelectedItems $amdLeAMDLSWLayerRemoveField]]
    # List of chosen layers to add...
    set layerAdd [amdLeAMDLSWLayerSelectStringToList [giGetDynamicListSelectedItems $amdLeAMDLSWLayerAddField]]
    
    # Clear values...
    db::setAttr selection -of $amdLeAMDLSWLayerRemoveField -value {}
    db::setAttr selection -of $amdLeAMDLSWLayerAddField -value {}
    
    # Get form total choices on Remove side; or GVAR set if init'ing; Includes chosen...
    set layerRemChoice [amdLeAMDLSWLayerSelectStringToList [db::getAttr value -of $amdLeAMDLSWLayerRemoveField]]
    if {""==$layerRemChoice} {
        set layerRemChoice $::amd::GVAR_amdLayVariables(amdLayoutAlias,${layerSet})
    }
    
    # Add values to Remove side from layer Add side...
    set layerRemChoice [concat $layerRemChoice $layerAdd]
    
    # Strip out selected Remove values...
    set layerSetItems {}
    foreach x $layerRemChoice {
        if {![member $x $layerRem]} {
           lappend layerSetItems $x
        }
    }
    set ::amd::GVAR_amdLayVariables(amdLayoutAlias,${layerSet}) $layerSetItems
    set refList [amdLeAMDLSWLayerSelectSortToString [lsort -unique $::amd::GVAR_amdLayVariables(amdLayoutAlias,${layerSet})] [db::getPrefValue amdLeAMDLSWLayerSortSetsField] $layerNm]
    giSetDynamicListValue $amdLeAMDLSWLayerRemoveField $refList
    amdLeAMDLSWLayerSelectSetRemLayersNotInSet $layerNm
}


proc amdLeAMDLSWLayerSelectSetRemLayersNotInSet {{layerNm ""} {w ""}} {
    set win [amdFindLSWConfigWind $w]
    if {""==$win} {
        return 
    }
    if {""==$layerNm} {
        set layerNm [db::getPrefValue amdLeAMDLSWLayerChooselayerSetName]
    }
    set layerSet [amdLeAMDLSWLayerSelectGetSetFromName $layerNm]
    set amdLeAMDLSWLayerRemoveField [gi::findChild amdLeAMDLSWLayerRemoveField -in $win] 
    set amdLeAMDLSWLayerAddField [gi::findChild amdLeAMDLSWLayerAddField -in $win]
    set layerRem [amdLeAMDLSWLayerSelectStringToList [giGetDynamicListSelectedItems $amdLeAMDLSWLayerRemoveField]]
    if {""==$layerRem} {
        set layerRem $::amd::GVAR_amdLayVariables(amdLayoutAlias,${layerSet})
    }
    set layerSetItems {}
    foreach x $::amd::GVAR_amdLayVariables(amdLayoutAlias,all) {
        if {![member $x $layerRem]} {
           lappend layerSetItems $x
        }
    }    
    set refList [amdLeAMDLSWLayerSelectSortToString [lsort -unique $layerSetItems] [db::getPrefValue amdLeAMDLSWLayerSortSetsField]]
    giSetDynamicListValue $amdLeAMDLSWLayerAddField $refList
}




proc amdFindLSWConfigWind {{w ""}} {
    if {""==$w} {
        set win [amdGetLSWConfigInstance]
        if {""==$win} {
            return ""
        }
    } else {
        if {"giWindow"==[db::getAttr type -of $w]} {
            set win $w
        } else {
            set win [getParentWindow $w]
        }    
    }
    return $win
}


proc amdLeAMDLSWLayerSelectGetNameFromSet {layerSet} {
    foreach x $::amd::GVAR_amdLayVariables(amdLayoutAMDLSWLayers) {
        if {[cadr $x] == $layerSet} {
            return [car $x]
        }
    }
    return ""
}

proc amdLeAMDLSWLayerSelectGetSetFromName {layerNm } {
    foreach x [concat $::amd::GVAR_amdLayVariables(amdLayoutAMDLSWLayers) $::amd::GVAR_amdLayVariables(amdLayoutAMDLSWUserRemovedLayerSets) $::amd::GVAR_amdLayVariables(amdLayoutAMDLSWHiddenLayerSets)] {
        if {$layerNm == [car $x]} {
            return [cadr $x]
        }
    }
    return ""
}


proc amdLeAMDLSWLayerSelectSortToString {layerList {sortSets 0} {currentOnly ""} } {
    set ns [namespace current]
    set sortOn [db::getPrefValue amdLeAMDLSWLayerSortField]
    set fold ""
    if {[db::getPrefValue amdLeAMDLSWLayerSortFoldField]} {
        set fold "Fold"
    }
    set myTable {}
    foreach x $layerList {
        if {![regexp {\-} [car $x]] && ![regexp {\*} [car $x]]} {
            lappend myTable $x
        }
    }

    if {"Purpose"==$sortOn} {
        set retList [lsort -command ${ns}::AMDalphaNumLesspCadr${fold} $myTable]
    } else {
        set retList [lsort -command ${ns}::AMDalphaNumLesspCar${fold} $myTable]
    }
    if {$sortSets} {
        # sort layername by alpha above, then by set button name...
        set retList [amdLeAMDLSWLayerSelectSortBySets $retList $currentOnly]
    }
    return [amdLeAMDLSWLayerSelectListToString $retList]
}


proc amdLeAMDLSWLayerSelectListToString {refList} {
    # ok to keep ----name---- in return strings for form
    set res {}
    foreach item $refList {
        lappend res [join $item "/"]
    }
    return $res
}


proc amdLeAMDLSWLayerSelectStringToList {refList} {
    # remove ----name---- in return list for layer lists
    set res {} 
    foreach item $refList {
        if {-1==[string first "-" $item]} {
            lappend res [split $item "/"]
        }
    }
    return $res
}


proc amdLeAMDLSWLayerSelectSortBySets {layerList {currentOnly ""}} {
    set ns [namespace current]
    array set myTable {}
    set nameList [concat [amdLeAMDLSWLayerSelectGetAllNameList 1] "NOT_ASSIGNED"]
    set retList {}
    set totalList {}
    
    if {"Purpose"==[db::getPrefValue amdLeAMDLSWLayerSortField]} {
        set sortby ${ns}::AMDalphaNumLesspCadr
    } else {
        set sortby ${ns}::AMDalphaNumLesspCar
    }
    set sortChoice [db::getPrefValue amdLeAMDLSWLayerSortSetsChoiceField]
    if {[db::getPrefValue amdLeAMDLSWLayerSortFoldField]} {
        append sortby "Fold"
    }          
    set allLayers {}
    if {[info exist ::amd::GVAR_amdLayVariables(amdLayoutAMDLSWLayers)]} {
        set allLayers [concat $allLayers $::amd::GVAR_amdLayVariables(amdLayoutAMDLSWLayers)]
    }
    if {[info exist ::amd::GVAR_amdLayVariables(amdLayoutAMDLSWUserRemovedLayerSets)]} {
        set allLayers [concat $allLayers $::amd::GVAR_amdLayVariables(amdLayoutAMDLSWUserRemovedLayerSets)]
    }   
    if {[info exist ::amd::GVAR_amdLayVariables(amdLayoutAMDLSWHiddenLayerSets)]} {
        set allLayers [concat $allLayers $::amd::GVAR_amdLayVariables(amdLayoutAMDLSWHiddenLayerSets)]
    }      
    foreach set $allLayers {
        set myTable([car $set]) {}
        foreach x $layerList {
            if {[member $x $::amd::GVAR_amdLayVariables(amdLayoutAlias,[cadr $set])]} {
                lappend myTable([car $set]) $x
            }
        }
    }
    foreach x $nameList {
        if {[info exist myTable($x)] && $myTable($x)!=""} {
            set totalList [concat $totalList $myTable($x)]
        }
    }
    if {""!=$currentOnly} {
        # Add the layers not contained in any other Set list...
        set myTable(NOT_ASSIGNED) {}
        foreach x $layerList {
            if {![member $x $totalList]} {
                lappend myTable(NOT_ASSIGNED) $x
            }
        }
        set myTable(NOT_ASSIGNED) [lsort -command $sortby $myTable(NOT_ASSIGNED)]
    }
    # return field list with ----name---- inserted...
    # return only one set if chosen on the sortChoice cyclic...
    # always return all fields for the Current Layers box to show which other lists they are in...    
    if {"ALL"==$sortChoice || ""!=$currentOnly} {
        foreach x $nameList {
            if {[info exist myTable($x)] && $myTable($x)!=""} {
                if {!(""!=$currentOnly && $x==$currentOnly)} {
                    set retList [concat $retList "-----$x-----" $myTable($x)]
                }
            }
        }
        if {""!=$currentOnly} {
            set retList [concat "-----$currentOnly-----" $myTable($currentOnly) $retList]
        }
    } else {
        set retList [concat "-----$sortChoice-----" $myTable($sortChoice) $retList]
    }
    return $retList
}


proc amdLeAMDLSWLayerSelectGetAllNameList {{hiddenAlso 0}} {
    if {$hiddenAlso} {
        # Added Stdcel/Macros
        return [concat [amdLeAMDLSWLayerSelectGetNameList] [amdLeAMDLSWLayerSelectGetRemovedNameList] [amdLeAMDLSWLayerSelectGetHiddenNameList]]
    } else {
        return [concat [amdLeAMDLSWLayerSelectGetNameList] [amdLeAMDLSWLayerSelectGetRemovedNameList]]
    }
}


proc amdLeAMDLSWLayerSelectGetSortNameList {} {
    return [concat "ALL" [amdLeAMDLSWLayerSelectGetAllNameList 1] "NOT_ASSIGNED"]
}


proc amdLeAMDLSWLayerSelectGetNameList {} {
    set res {}
    foreach item $::amd::GVAR_amdLayVariables(amdLayoutAMDLSWLayers) {
        lappend res [car $item]
    }
    return $res
}


proc amdLeAMDLSWLayerSelectGetRemovedNameList {} {
    set res {}
    if {[info exist ::amd::GVAR_amdLayVariables(amdLayoutAMDLSWUserRemovedLayerSets)]} {
        foreach item $::amd::GVAR_amdLayVariables(amdLayoutAMDLSWUserRemovedLayerSets) {
            lappend res [car $item]
        }
    }
    return $res
}

proc amdLeAMDLSWLayerSelectGetHiddenNameList {} {
    set res {}
    if {[info exist ::amd::GVAR_amdLayVariables(amdLayoutAMDLSWHiddenLayerSets)]} {
        foreach item $::amd::GVAR_amdLayVariables(amdLayoutAMDLSWHiddenLayerSets) {
            lappend res [car $item]
        }
    }
    return $res
}

proc amdLeAMDLSWLayerSelectQuickStartFAQ {} {
    amdFormHelpFunc "Layer Set Usage QuickStart" "============================================  General  ============================================\n\
\n\
All Settings are updated in the session's SKILL memory immediately.  The Layer Lists are live in the current AMDLSW.\n\
The Button Listings are live, but the AMDLSW form requires a restart (Refresh AMDLSW button) to see the changes.\n\
\n\
MOUSE CONTROL:\n\
For multi-selection, (standard list-box usage), you may drag the mouse over the contiguous entries desired.\n\
Holding Control and Click or Drag can be combined for dispersed selecting.  Do NOT use the Shift, it has issues.\n\
Holding Control and Click or Drag on Already selected items Deselects them.  The Clear button Deselects all.\n\
Practice with it, and you will see the possibilities.  To reduce complexity, only the Layers Tab has Multi-Selection.\n\
\n\
LOAD/SAVE:\n\
All settings may be Loaded from, or Saved to, the file at the bottom of the form at any time.  Any file path may be\n\
loaded, but the files are only saved under ~/cadence/AMDLSW/, and normally loaded from there, where only the filename\n\
need be specified.  The directory list is fetched only on startup.  One .*.bak file is kept, and overwritten per Save.\n\
The default filename is the projrev name, i.e. 'bd45a'.  See the 'Help On TWIKI' link for more info on the file settings.\n\
\n\
===========================================  Layers Tab  ===========================================\n\
\n\
|| Layer Set: ||  Choose the Set desired on the top button, most operations affect only this Set.\n\n\
|| <- Reset List to CAD Defaults ||    Will put the Current list back to the Cad defaults.\n\
|| Reset All Lists to CAD defaults ||  Caution, this will put all LayerSet lists back to the Cad defaults.\n\
\n\
Choose layers to swap in and out of lists.  Choose in one list, or in both lists and swap simultaneously.\n\
|| <---> ||           Use this to swap selections between the lists as selected.\n\
For single selections in one or both lists, you may Double-Click the entry for immediate swap.\n\
\n\
|| Sort By ||         You can sort by ||Name||, ||Purpose||, or list by Button Name ||Sets||.\n\
Note the 'Sets' sorting will also show any duplications in the Sets, and selections will select all duplicates as well.\n\
Changes show in the 'Current Layers' list and will only apply to the current list choice on the 'Layer Set Name' button.\n\
The other sorted Sets shown are only duplicates.  The last Set on the 'Add Layers' list is 'NOT_ASSIGNED' and contains\n\
the layers not in any AMDLSW Set.  Or they are just sorted with the rest when not using Sort By Sets.\n\
\n\
===========================================  Buttons Tab  ===========================================\n\
\n\
Use this Tab to rearrange the Button listing for the Layer Sets.  You can make only a single selection.\n\
|| Move Up   ||  (or Double-Click the entry), or\n\
|| Move Down ||      Move the selected Button Name up or down as desired.\n\
|| <------v  ||      Move the selected entry on or off the list to/from the 'Removed List'.\n\
|| Reset Buttons To CAD Defaults ||    Caution, this will arrange all the Layer Button lists back to the Cad defaults.\n\
\n\
++++++++++++++++++++++++++++ AMDLSW \$Revision: #1 \$ ++++++++++++++++++++++++++++\n\
"
}


proc amdGetLSWInstance {} {
    variable lswWT
    set w [db::getNext [gi::getWindows -filter {%windowType.name=="$lswWT"}]]
    return $w
}

proc amdGetLSWConfigInstance {} {
    variable lswConfigWT
    set w [db::getNext [gi::getWindows -filter {%windowType.name=="$lswConfigWT"}]]
    return $w
}


proc amdLayoutLSWCloseWindowMenuCB {wId} {
    set win [db::getNext [gi::getWindows $wId]]
    if {""!=$win} {
        gi::closeWindows $win
    }
    if {""!=[amdGetLSWConfigInstance]} {
        gi::closeWindows [amdGetLSWConfigInstance]
    }
}

proc amdLeAMDLSWLayerSelect_CloseWindow {wId} {
    set win [db::getNext [gi::getWindows $wId]]
    if {""!=$win} {
        gi::closeWindows $win
    }
    if {""!=[amdGetLSWConfigInstance]} {
        gi::closeWindows [amdGetLSWConfigInstance]
    }
}



# LSW control functions

# Update for stdcells 
proc amdLSWDisplayStdcells {{w ""}} {
    set oaDes [ed]
    if {"maskLayout"!=[db::getAttr viewType -of $oaDes]} {
        return 0
    }
    amdLSWUpdate $oaDes $::amd::GVAR_amdLayVariables(amdLayoutAlias,stdcells)
}

# Update for macros.
proc amdLSWDisplayMacros {{w ""}} {
    set oaDes [ed]
    if {"maskLayout"!=[db::getAttr viewType -of $oaDes]} {
        return 0
    }
    amdLSWUpdate $oaDes $::amd::GVAR_amdLayVariables(amdLayoutAlias,macros)
}

proc amdLSWDisplayAll {{w ""}} {
    set oaDes [ed]
    if {"maskLayout"!=[db::getAttr viewType -of $oaDes]} {
        return 0
    }
    amdLSWUpdate $oaDes $::amd::GVAR_amdLayVariables(amdLayoutAlias,all)
}

# Update based on layers in current cellview
proc amdLSWDisplayCurrentCV {{w ""}} {
    set oaDes [ed]
    if {"maskLayout"!=[db::getAttr viewType -of $oaDes]} {
        return 0
    }
    set lpps [de::getLPPs -from $oaDes -filter {%valid && (!%selectable || !%visible)}]
    db::setAttr selectable -of [de::getLPPs -from $oaDes] -value 1
    db::setAttr visible -of [de::getLPPs -from $oaDes] -value 1
    de::redraw
    amdLeAMDLSWLayerValidListUpdateCB     
}


proc amdLSWUpdate {oaDes lpps} {
    # Turn on all of the layers in the lpps list
    set lppL {}
    set firstRun 1
    foreach n_layerPP $lpps {
        set lpp [db::getNext [de::getLPPs $n_layerPP -from $oaDes]]
        if {""!=$lpp} {
            db::setAttr selectable -of $lpp -value 1
            db::setAttr visible -of $lpp -value 1        
            if {$firstRun} {
                de::setActiveLPP $lpp
                set firstRun 0
            }
        }
    }
    
    db::foreach lpp [de::getLPPs -from $oaDes -filter {%valid}] {
        if {![member [db::getAttr lpp -of $lpp] $lpps]} {
            db::setAttr selectable -of $lpp -value 0
            db::setAttr visible -of $lpp -value 0
        }
    }
    de::redraw
    amdLeAMDLSWLayerValidListUpdateCB
}

# Given a list of shapes and a lpp change the layer.
proc amdLayoutChangeLPP {{w ""}} {
    set oaDes [ed]
    if {"maskLayout"!=[db::getAttr viewType -of $oaDes]} {
        return 0
    }    
    set lpp [db::getAttr lpp -of [de::getActiveLPP -design $oaDes]]
    set ln [getLayerNumber [lindex $lpp 0] $oaDes]
    set pn [getPurposeNumber [lindex $lpp 1] $oaDes]
    set tr [de::startTransaction "Change LPP" -design $oaDes]
    db::foreach s [de::getSelected -design $oaDes -filter {%objType=="Rectangle" || %objType=="Path" || %objType=="Polygon" || %objType=="PathSeg"}] {
        oa::setLPP [db::getAttr object -of $s] $ln $pn
    }
    de::endTransaction $tr
}

proc amdLeAMDLSWLayerValidListUpdateCB {{ok 1}} {
    # Called by the Stdcel/Macros and any buttons that reset Valid layers...
    if {$ok} {
        set oaTech [techGetTechFile $::amd::GVAR_amdEnvVariables(amdTechLibName)]
        set ::amd::GVAR_amdLayVariables(amdLayoutAlias,all) [leGetValidLayerList $oaTech]
    }
    return 1
}


proc amdLeAMDLSWLayerGetNewWinBbox {lswWin cfgWin} {
    set wWidth 500
    set wHeight 560
    set lswGeom [db::getAttr geometry -of $lswWin]
    set x 0
    set y 0
    if {[regexp {\d+x\d+\+(\d+)\+(\d+)} $lswGeom match xp yp]} {
        set x [expr $xp - $wWidth - 10]
        set y $yp
    }
    return ${wWidth}x${wHeight}+$x+$y
}


proc amdLayoutPathConnect {{w ""}} {
    set oaDes [ed]
    if {"maskLayout"!=[db::getAttr viewType -of $oaDes]} {
        return 0
    }  
    set shapes [de::getSelected -design $oaDes -filter {%objType=="Path" && %isPartial==1}]
    if {2>[db::getCount $shapes]} {
        de::sendMessage "Not doing anything. Can only connect 2 selected paths." -severity warning
    } else {
        db::foreach s $shapes {
            if {[db::getAttr isPartial -of $s]} {
                #puts [db::listAttrs -of [db::getAttr lineage -of $s]]
                #puts [db::getAttr points -of [db::getAttr object -of $s]]
            }
        }
    }
}




# These procs are no need any more
# Keep them for getting right statistic
# Menu functions
proc amdLeAMDLSW_WindowCloseItem {} {
}
proc amdLeAMDLSW_WindowConfigItem {} {
}
proc amdLeAMDLSWLayerSelect_WindowCloseItem {} {
}
proc amdLeAMDLSWLayerSelect_FileRefreshItem {} {
}
proc amdLeAMDLSWLayerSelect_WindowQuickStartFAQ {} {
}

# Window functions
proc amdReopenLSWWindow {} {
}
proc amdLeAMDLSWPinControlCB {} {
}
proc amdLeAMDLSWPinControlGetEnv {} {
}
proc amdLeAMDLSWLayerSelect_NullWindow {} {
}
proc amdLeAMDLSWLayerSelectDestroyForm {} {
}
proc amdLepteGetWindowList {} {
}
proc amdEnableReopenAMDLSWWindow {} {
}
proc amdLayoutLSWCloseWindow {} {
}
proc amdCloseLSWWindow {} {
}
proc amdLeGetObjectsWindow {} {
}

# Need info from AMD
proc amdLeAMDLSWLayerValidListIntercept {} {
}
proc amdLeAMDLSWLayerValidListInterceptCB {} {
}
proc amdLeAMDLSWLayerGetObjectIntercept {} {
}
proc amdLeAMDLSWLayerUpdatePinInstButtonsCB {} {
}
proc amdLeBlockLayerOnOff {} {
}
proc amdLeAMDLSWPinControlGetButton {} {
}
proc amdLeAMDLSWPinControlInitEnv {} {
}

}