#!/depot/tcl8.5.12/bin/tclsh8.5
# CC script
###############################################################################
# File       : defCheckCC.tcl
# Author     : Ahmed Hesham(ahmedhes)
# Date       : 06/26/2022
# Description: The script is called from CC. It will check the instances of the
#              currently opened design to see if they lie on the stdcells grid
#              or not. The pitch for some technologies is hardcoded, for others
#              the user will have to pass the values. The script will also che-
#              ck the placement status of the instances whether its "placed" or 
#              not.
# Usage      : To use the dialog call
#                   ddr_utils::defCheck::gui
###############################################################################
proc utils__script_usage_statistics {toolname version} {

    set prefix "ddr-da-"
    set reporter "/remote/cad-rep/msip/tools/bin/msip_get_usage_info"
    set cmd ""
    set script_dirname [file dirname [file normalize [info script]]]
    append cmd "$reporter --tool_name  \"${prefix}${toolname}\" "
    append cmd "--stage main --category ude_ext_1 "
    append cmd "--tool_path \"$script_dirname\" --tool_version \"$version\""

    exec sh -c $cmd &
}


set script_name [file tail [file rootname [file normalize [info script]]]]
utils__script_usage_statistics $script_name "2022ww43"

# If the script was loaded once before, delete it
if {[namespace exists ::defCheck]} {
    namespace delete ::defCheck
}

namespace eval defCheck {
    global env
    variable logFile
    variable tech $env(PROCESSNAME)
    variable oaDesign [ed]
    variable pitchArray
    set pitchArray(tsmc5ff) {0.102 0.42}
    set pitchArray(tsmc7ff) {0.114 0.48}
    variable excludeArray
    set excludeArray(all) {vflags}
    set excludeArray(tsmc5ff) {ts05}
    variable topcells ""

    # Create the prefs
    db::createPref "defCheckXPitch"            -value ""       -description "x-pitch"
    db::createPref "defCheckYPitch"            -value ""       -description "y-pitch"
    db::createPref "defCheckPitchMode"         -value "Manual" -description "Pitch Mode"
    db::createPref "defCheckPitchEnable"       -value "0"      -description "Enable pitch mode change"
    db::createPref "defCheckPlacementEnable"   -value "0"      -description "Placement check enable"
    db::createPref "defCheckPlacementMode"     -value "placed" -description "Placement mode"
    db::createPref "defCheckCellName"          -value ""       -description "The cellname for the current DEF file"
    db::createPref "defCheckPitchInputEnable"  -value "1"      -description "Enable changing the pitch"
    db::createPref "defCheckDefInputFile"      -value ""       -description "def file"
    db::createPref "defCheckCompareDef"        -value "1"      -description "compareDef enable"
    db::createPref "defCheckDefType"           -value "DI"     -description "DEF type: DI/CKT"
    db::createPref "defCheckExclude"           -value "1"      -description "Exclude enable"
    db::createPref "defCheckExcludeLibs"       -value "1"      -description "Exclude libs enable"
    db::createPref "defCheckExcludeGlobEnable" -value "0"      -description "Exclude anycell containing the exclude list cell names"
    db::createPref "defCheckExcludedLibsList"  -value ""       -description "Excluded libs list"
    db::createPref "defCheckExcludeCells"      -value "1"      -description "Exclude cells enable"
    db::createPref "defCheckExcludedCellsList" -value ""       -description "Excluded cells list"
    db::createPref "defCheckPrintUnmatched"    -value "0"      -description "Print unmatched DEF cells"

    proc gui {} {
        variable oaDesign
        set oaDesign [ed]
        set dialog [gi::createDialog defCheck \
                                     -title "DEF Check" \
                                     -showApply false \
                                     -showHelp false \
                                     -defaultsProc [namespace code _resetEntries] \
                                     -execProc [namespace code _checkDesignGUI]]

        # Read the topcells file
        _readTopCells
        # Auto fill the entries with the default values
        set techExist [_autofillDefaults]
        # Create the dialog widgets
        set excludeGroup [gi::createCheckableGroup widgetExcludeGroup \
                                                   -parent $dialog \
                                                   -prefName defCheckExclude \
                                                   -label "Exclude List"]
        set excludeLibsGroup [gi::createCheckableGroup widgetExcludeLibsGroup \
                                                       -parent $excludeGroup \
                                                       -prefName defCheckExcludeLibs \
                                                       -label "Exclude Libs"]
        set libList [db::createLibListInput widgetExcludeLibList \
                                            -parent $excludeLibsGroup \
                                            -prefName defCheckExcludedLibsList \
                                            -label "Excluded libs list:"]
        set excludeGlob [gi::createBooleanInput widgetExcludeGlob \
                                                -parent $excludeLibsGroup \
                                                -label "Exclude cellname with partial match" \
                                                -prefName defCheckExcludeGlobEnable]
        set excludeCellsGroup [gi::createCheckableGroup widgetExcludeGroup \
                                                        -parent $excludeGroup \
                                                        -prefName defCheckExcludeCells \
                                                        -label "Exclude Cells"]
        set cellsList [gi::createTextInput widgetExcludeCellsist \
                                           -parent $excludeCellsGroup \
                                           -prefName defCheckExcludedCellsList \
                                           -label "Excluded cells list:"]
        set pitchGroup [gi::createGroup widgetpitchGroup \
                                        -parent $dialog \
                                        -label "Pitch Check"]

        set warningMsg "Warning: Default values for the technology were not found."
        set warningLabel [gi::createLabel widgetWarningLabel \
                                          -parent $pitchGroup \
                                          -label $warningMsg \
                                          -shown [expr {! $techExist}]]
        db::setAttr foreground -of [db::getAttr style -of $warningLabel]  -value "red"
        db::setAttr bold -of [db::getAttr font -of [db::getAttr style -of $warningLabel]] -value 1
        set pitchMode [gi::createMutexInput widgetPitchMode \
                                            -parent $pitchGroup \
                                            -label "Pitch" \
                                            -viewType "radio" \
                                            -enum "Default Manual" \
                                            -prefName defCheckPitchMode \
                                            -enabled [db::getPrefValue defCheckPitchEnable] \
                                            -valueChangeProc [namespace code _pitchModeChange]]

        set pitchValuesGroup [gi::createGroup widgetPitchValuesGroup \
                                              -parent $pitchGroup \
                                              -enabled [db::getPrefValue defCheckPitchInputEnable] \
                                              -label "Pitch Values:"]
        set xPitchText [gi::createTextInput widgetXPitch \
                                            -parent $pitchValuesGroup \
                                            -label "x-pitch" \
                                            -required true \
                                            -prefName defCheckXPitch \
                                            -valueChangeProc [namespace code _checkDouble]]
        set yPitchText [gi::createTextInput widgetYPitch \
                                            -parent $pitchValuesGroup \
                                            -label "y-pitch" \
                                            -required true \
                                            -prefName defCheckYPitch \
                                            -valueChangeProc [namespace code _checkDouble]]
        set placementGroup [gi::createCheckableGroup widgetPlacementGroup \
                                                     -parent $dialog \
                                                     -prefName defCheckPlacementEnable \
                                                     -label "Placement Check"]
        set placementMode [gi::createMutexInput widgetPlacementMode \
                                                -parent $placementGroup \
                                                -label "Placement Status:" \
                                                -viewType "radio" \
                                                -enum "placed fixed" \
                                                -prefName defCheckPlacementMode]
        set defGroup [gi::createCheckableGroup widgetDefGroup \
                                               -parent $dialog \
                                               -prefName defCheckCompareDef \
                                               -label "Compare with DEF" ]
        set defTypeToolTip [join [list "For CKT, the cells in the design are compared as is. " \
                                       "For DI,  the cells sharing the same lib as the top " \
                                       "cell are 'flattened', where the absolute placmenet " \
                                       "status for their componets are used instead of the " \
                                       "cells. The cells themselves are not used in the " \
                                       "comparison."] "\n"]
        set defType [gi::createMutexInput widgetDefType \
                                                -parent $defGroup \
                                                -label "DEF Type:" \
                                                -viewType "radio" \
                                                -enum "CKT DI" \
                                                -toolTip $defTypeToolTip \
                                                -prefName defCheckDefType]
        set defFile [gi::createFileInput widgetdefInputFile \
                                         -parent $defGroup \
                                         -label "DEF File" \
                                         -fileMasks "*.def*"\
                                         -required true \
                                         -prefName defCheckDefInputFile \
                                         -valueChangeProc [namespace code _checkValidFile]]
        if {![file isfile [db::getPrefValue defCheckDefInputFile]]} {
            db::setAttr valid -of $defFile -value false
        }
        set printUnmatched [gi::createBooleanInput widgetPrintUnmatched \
                                                   -parent $defGroup \
                                                   -label "Print unmatched DEF cells" \
                                                   -prefName defCheckPrintUnmatched]
        gi::layout $warningLabel -align $pitchValuesGroup
        return
    }

    proc _resetEntries {dialog} {
        variable oaDesign
        variable pitchArray
        variable tech
        # Check if the tech has a pitch default
        set techExist [info exists pitchArray($tech)]
        # If the excluded libs/cells list was not set previosly, set it to the project's
        # default
        set cellName [db::getAttr cellName -of $oaDesign]
        db::setPrefValue "defCheckPlacementEnable"   -value "0"     
        db::setPrefValue "defCheckPlacementMode"     -value "placed"
        db::setPrefValue "defCheckCompareDef"        -value "1"     
        db::setPrefValue "defCheckDefType"           -value "DI"    
        db::setPrefValue "defCheckExclude"           -value "1"     
        db::setPrefValue "defCheckExcludeLibs"       -value "1"     
        db::setPrefValue "defCheckExcludedLibsList"  -value ""     
        db::setPrefValue "defCheckExcludeGlobEnable" -value "0"     
        db::setPrefValue "defCheckExcludeCells"      -value "1"     
        db::setPrefValue "defCheckExcludedCellsList" -value ""     
        db::setPrefValue "defCheckPrintUnmatched"    -value "0"     
        _setDefaultExcludedList $cellName
        # If the pitch values was not set previosly, set it to the project's 
        # default values if they exist.
        if {$techExist == 0} {
            db::setPrefValue defCheckXPitch           -value "0"
            db::setPrefValue defCheckYPitch           -value "0"
            db::setPrefValue defCheckPitchMode        -value "Manual"
            db::setPrefValue defCheckPitchEnable      -value "0"
            db::setPrefValue defCheckPitchInputEnable -value "1"
        } else {
            db::setPrefValue defCheckXPitch  -value [lindex $pitchArray($tech) 0]
            db::setPrefValue defCheckYPitch  -value [lindex $pitchArray($tech) 1]
            db::setPrefValue defCheckPitchMode        -value "Default"
            db::setPrefValue defCheckPitchEnable      -value "1"
            db::setPrefValue defCheckPitchInputEnable -value "0"
        }
        # Update the Def input path given the cellname
        db::setPrefValue defCheckCellName     -value $cellName
        db::setPrefValue defCheckDefInputFile -value [_getDefaultDefPath $cellName]
    }

    proc yml2tcl_import {sample {level 1}} {
        dict for {key value} [yaml::yaml2dict -file $sample] {
            upvar $level $key $key
            if {[array exists value]} {
                array set $name_array $value
            } else {
                set $key $value
            }
        }
        foreach {key value} $releaseMacro {
            set var_name "releaseMacro\{$key\}"
            upvar $level $var_name $var_name  
            set $var_name $value
        }
    }

    proc get_variables_from_file {__file} {
        source $__file
        unset __file
        return [info locals]
    }

    proc yml2tcl_getvalue {sample var_name} {
    dict for {key value} [yaml::yaml2dict -file $sample] {
        if {$key == $var_name} {return $value}
    }
    eprint "The variable $var_name was not found"
    return error
}

    proc _autofillDefaults {} {
        variable oaDesign
        variable pitchArray
        variable tech
        # Check if the tech has a pitch default
        set techExist [info exists pitchArray($tech)]
        # If the excluded libs/cells list was not set previosly, set it to the project's
        # default
        set cellName [db::getAttr cellName -of $oaDesign]
        _setDefaultExcludedList $cellName
        # If the pitch values was not set previosly, set it to the project's 
        # default values if they exist.
        if {[db::getPrefValue defCheckXPitch] == "" || [db::getPrefValue defCheckYPitch] == "" } {
            if {$techExist == 0} {
                db::setPrefValue defCheckXPitch           -value "0"
                db::setPrefValue defCheckYPitch           -value "0"
                db::setPrefValue defCheckPitchMode        -value "Manual"
                db::setPrefValue defCheckPitchEnable      -value "0"
                db::setPrefValue defCheckPitchInputEnable -value "1"
            } else {
                db::setPrefValue defCheckXPitch  -value [lindex $pitchArray($tech) 0]
                db::setPrefValue defCheckYPitch  -value [lindex $pitchArray($tech) 1]
                db::setPrefValue defCheckPitchMode        -value "Default"
                db::setPrefValue defCheckPitchEnable      -value "1"
                db::setPrefValue defCheckPitchInputEnable -value "0"
            }
        }
        # Update the Def input path given the cellname
        if { $cellName != [db::getPrefValue defCheckCellName] \
             || [db::getPrefValue defCheckDefInputFile] == ""} {
            db::setPrefValue defCheckCellName     -value $cellName
            db::setPrefValue defCheckDefInputFile -value [_getDefaultDefPath $cellName]
        }
        
        return $techExist
    }

    proc _setDefaultExcludedList {cellName} {
        if {[db::getPrefValue defCheckExcludedLibsList] eq ""} {
            # Get the list of available libs in the project
            set libsList [_getLibsList]
            # Add the libs common to all
            set excludedList {}
            foreach excludeItem $::defCheck::excludeArray(all) {
                lappend excludedList {*}[lsearch -all -inline $libsList "*$excludeItem*"]
            }
            # Add the libs specific to the technology
            if {[info exists ::defCheck::excludeArray($::defCheck::tech)]} {
                foreach excludeItem $::defCheck::excludeArray($::defCheck::tech) {
                    lappend excludedList {*}[lsearch -all -inline $libsList "*$excludeItem*"]
                }
            }
            # Update the excluded libs list preference to see the changes in the GUI
            db::setPrefValue defCheckExcludedLibsList -value $excludedList
        }
        
        if {[db::getPrefValue defCheckExcludedCellsList] eq ""} {
            set excludedList [list "*_BEOL" "*_FEOL" "${cellName}_HD*"]
            # Update the excluded libs list preference to see the changes in the GUI
            db::setPrefValue defCheckExcludedCellsList -value $excludedList
        }
    }

    proc _getLibsList {} {
        set libsCollection [dm::getLibs]
        while { [set lib [db::getNext $libsCollection]] ne "" } {
            lappend libsList [db::getAttr lib.name]
        }
        return $libsList
    }

    proc _pitchModeChange {widget} {
        set status [db::getAttr value  -of $widget]
        set dialog [db::getAttr parent -of $widget]
        set pitchGroup [gi::findChild  widgetPitchValuesGroup -in $dialog]
        if {$status == "Manual"} {
            db::setAttr enabled -of $pitchGroup -value true
            db::setPrefValue defCheckPitchInputEnable -value "1"
        } else {
            set xPitch  [lindex $::defCheck::pitchArray($::defCheck::tech) 0]
            set yPitch  [lindex $::defCheck::pitchArray($::defCheck::tech) 1]
            db::setAttr value \
                        -of [gi::findChild widgetXPitch -in $pitchGroup] \
                        -value $xPitch
            db::setAttr value \
                        -of [gi::findChild widgetYPitch -in $pitchGroup] \
                        -value $yPitch
            db::setAttr enabled -of $pitchGroup -value false
            db::setPrefValue defCheckPitchInputEnable -value "0"
        }
    }

    proc _getDefaultDefPath {cellName} {
        global env
        # Get the path to the legalRelease file
        set designDir "$::env(MSIP_PROJ_ROOT)/$::env(MSIP_PRODUCT_NAME)/$::env(MSIP_PROJ_NAME)/$::env(MSIP_REL_NAME)/design"
        set legalRel [_firstAvailableFile "$designDir/legalRelease.yml" \
                                         "${designDir}_unrestricted/legalRelease.yml"]
        if {![file exists $legalRel]} {
            return "~/p4_ws/"
        }
        # Get the p4_release_root
        # set p4RelRoot [exec grep -E "set\\s+p4_release_root\\s+" $legalRel]
        # regexp {set\s+p4_release_root\s+\"(.*)\"} $p4RelRoot to p4RelRoot
        set p4RelRoot [yml2tcl_getvalue $legalRel "p4_release_root"]
        # Check if the path exists
        set path "~/p4_ws/$p4RelRoot/di/rel/"
        # Get the latest DI DEF available
        if {[file exists $path]} {
            foreach dir [lsort [glob -types d -directory $path "*"]] {
                set dir "$dir/$cellName/views/def/$env(METAL_STACK)"
                if {[file exists $dir]} {
                    set defFile [_firstAvailableFile "$dir/$cellName.def.gz" \
                                                    "$dir/$cellName.def"]
                    if {$defFile != ""} {
                        return $defFile
                    } else {
                        return $dir
                    }
                }
            }
        }
        # If a DEF file was not found, get the last directory that exists in 
        # the path.
        while {![file exists $path]} {
            set path [file dirname $path]
        }
        return $path
    }

    proc _firstAvailableFile {args} {
        foreach ff $args {
            if {[file exists $ff]} {return $ff}
        }
        de::sendMessage "None of these exist:" -severity "error"
        foreach ff $args {puts "\t$ff"}
        return ""
    }
    
    proc _checkDouble {widget} {
        set value [db::getAttr value -of $widget]
        if {$value == ""} {
            db::setAttr valid -of $widget -value false
            error "The pitch can not be left empty."
        } elseif {![string is double $value]} {
            db::setAttr valid -of $widget -value false
            error "The pitch be a floating number."
        } else {
            db::setAttr valid -of $widget -value true
        }
    }

    proc _checkValidFile {widget} {
        set fname [db::getAttr value  -of $widget]
        if {[file isfile $fname]} {
            db::setAttr valid -of $widget -value true
        } else {
            db::setAttr valid -of $widget -value false
        }

    }

    proc _checkDesignGUI {dialog} {
        variable oaDesign
        variable topcells
        # For clarity, in the code, the def cells will be called components, the
        # OA cells will be called instances, and the cells in the excluded libs
        # will be called cells.
        
        _log_file_setup
        set pitchList [list [db::getPrefValue defCheckXPitch] [db::getPrefValue defCheckYPitch]]

        set libName  [db::getAttr libName  -of $oaDesign]
        set cellName [db::getAttr cellName -of $oaDesign]
        set msg "Checking the cells placement using the following parameters:"
        _print $msg "information"
        _print "\t libname: $libName"
        _print "\tcellname: $cellName"
        _print "\t x-pitch: [lindex $pitchList 0]"
        _print "\t y-pitch: [lindex $pitchList 1]"
        if {[db::getPrefValue defCheckExclude]} {
            if {[db::getPrefValue defCheckExcludeLibs]} {
                _print "\tExcluded libs list: [db::getPrefValue defCheckExcludedLibsList]"
            }
            if {[db::getPrefValue defCheckExcludeCells]} {
                _print "\tExcluded cells list: [db::getPrefValue defCheckExcludedCellsList]"
            }
        }

        set errorDict [dict create offgrid {} unplaced {} misplaced {} waived {}]
        dict set errorDict waived [dict create cktcells {} "topcells" {}]
        set cellsList {}
        set excludedCells [_getExcludedCells]
        
        # Loop all instances, getting the placement info, and checking the 
        # contained cells if the DEF was of type DI. The list returned is a list
        # of lists containing the cellname, bBox and orientation. The errorDict
        # contains the number of off-grid, unplaced, and misplaced cells
        set instCollection [db::getInsts -of $oaDesign]
        set instList {}
        db::foreach inst $instCollection {
            set instName [db::getAttr cellName -of $inst] 
            if {[_checkExcludeList $excludedCells $instName]} {
                if {[lsearch $topcells $instName] != -1} {
                    set msg [join [list "The cell '$instName' was found in the topcells " \
                                        "file and was included in the exclude list! " \
                                        "The cell will not be excluded."] \
                                   ""]
                    _print $msg "error"
                } else {
                    continue
                }
            }
            if {[db::listAttrs def_ignoreExists -of $inst] != "" \
                && [db::getAttr def_ignoreExists -of $inst]} {
                if {[lsearch $topcells $instName] != -1} {
                    set msg [join [list "The cell '$instName' was found in the topcells " \
                                        "file and was previously waived! " \
                                        "The cell will not be ignored."] \
                                   ""]
                    _print $msg "error"
                    set errorList [list $instName [db::getAttr libName -of $inst] $cellName]
                    set bBox [db::getAttr bBox -of $inst]
                    lassign [split [lindex $bBox 0]] x y
                    lappend errorList [list $x $y]
                    dict update errorDict waived var {dict lappend var topcells $errorList}
                } else {
                    set errorList [list $instName [db::getAttr libName -of $inst] $cellName]
                    set bBox [db::getAttr bBox -of $inst]
                    lassign [split [lindex $bBox 0]] x y
                    lappend errorList [list $x $y]
                    dict update errorDict waived var {dict lappend var cktcells $errorList}
                    _print_to_log "The following cell has been waived:" "warning"
                    _print_to_log "\t cellname: $instName"
                    _print_to_log "\t  libName: [db::getAttr libName -of $inst]"
                    _print_to_log "\thierarchy: $cellName"
                    _print_to_log "\t     bBox: $bBox"
                    continue
                }
            }
            lappend instList {*}[_checkInst $inst $libName $cellName $pitchList \
                                            $excludedCells errorDict]
        }

        # Print the summary
        _print_to_log "Placement Check Summary:" "information" 
        set offgrid [llength [dict get $errorDict offgrid]]
        if {$offgrid != 0} {
            _print "\tThere are $offgrid off-grid cells." "error"
        } else {
            _print "\tAll of the cells are on-grid." "information"
        }
        set unplaced [llength [dict get $errorDict unplaced]]
        if {$unplaced != 0} {
            _print "\tThere are $unplaced unplaced cells." "error"
        } else {
            _print "\tThere are no unplaced cells." "information"
        }
        if {[db::getPrefValue defCheckPlacementEnable]} {
            set misplaced [llength [dict get $errorDict misplaced]]
            if {$misplaced != 0} {
                set msg "\tThere are $misplaced cells with a wrong placement status."
                _print $msg "warning"
            } else {
                set msg "\tAll of the cells have the correct placement status."
                _print $msg "information"
            }
        }
        set waived [llength [dict get $errorDict waived cktcells]]
        if {$waived > 0} {
            _print "\tThere are $waived waived cells." "warning" 
        } else {
            _print "\tThere are no waived cells." "information" 
        }
        
        # Run compare DEF
        set compareDef [db::getPrefValue defCheckCompareDef]
        if {$compareDef == 1} {
            set errorList [_compareDef $instList $excludedCells]
            _printCompareDefErrorMessages $errorList
            # Add the compare DEF errors to the errorDict
            dict set errorDict "compareDef" $errorList
        }

        close $::defCheck::logFile
        _resultsDialog $errorDict
    }

    proc _checkInst {oaInst topLibName instHier pitchList excludedCells errorDictName} {
        variable topcells
        upvar $errorDictName errorDict
        set instList {}

        # Get instance attributes.
        set bBox            [db::getAttr bBox            -of $oaInst]
        set origin          [db::getAttr origin          -of $oaInst]
        set orient          [db::getAttr orientation     -of $oaInst]
        set placementStatus [db::getAttr placementStatus -of $oaInst]
        set instLibName     [db::getAttr libName         -of $oaInst]
        set instCellName    [db::getAttr cellName        -of $oaInst]

        # Check if the cell is placed on the grid
        set xPitch  [lindex $pitchList 0]
        set yPitch  [lindex $pitchList 1]
        lassign [split [lindex $bBox 0]] x y
        set xMod [expr {fmod($x*1000,$xPitch*1000)}]
        set yMod [expr {fmod($y*1000,$yPitch*1000)}]
        if {$xMod != 0 || $yMod != 0} {
            set errorList [list $instCellName $instLibName $instHier]
            lappend errorList [list $x $y]
            lappend errorList [list [expr {$xMod/1000}] [expr {$yMod/1000}]]
            dict lappend errorDict offgrid $errorList
            _print_to_log "The following cell is off-grid:" "error"
            _print_to_log "\t cellname: $instCellName"
            _print_to_log "\t  libName: $instLibName"
            _print_to_log "\thierarchy: $instHier"
            if {$xMod != 0} {
                _print_to_log "\t       x: $x, remainder: [expr {$xMod/1000}]"
            }
            if {$yMod != 0} {
                _print_to_log "\t       y: $y, remainder: [expr {$yMod/1000}]"
            }
        }

        # Check cell placement status
        if {$placementStatus == "unplaced"} {
            set errorList [list $instCellName $instLibName $instHier [list $x $y]]
            dict lappend errorDict unplaced $errorList
            _print_to_log "The following cell has a placment status of unplaced:" "error"
            _print_to_log "\t libName: $instLibName"
            _print_to_log "\tcellname: $instCellName"
            _print_to_log "\t    path: $instHier"
            _print_to_log "\t       x: $x"
            _print_to_log "\t       y: $y"
        } elseif {[db::getPrefValue defCheckPlacementEnable]} {
            if {$placementStatus != [db::getPrefValue defCheckPlacementMode]} {
                set errorList [list $instCellName $instLibName $instHier [list $x $y] $placementStatus]
                dict lappend errorDict misplaced $errorList
                set msg [join [list "The following cell does not have a" \
                                    "placment status of" \
                                    "[db::getPrefValue defCheckPlacementMode]:"]]
                _print_to_log  $msg "warning"
                _print_to_log "\t  libName: $instLibName"
                _print_to_log "\t cellname: $instCellName"
                _print_to_log "\t     path: $instHier"
                _print_to_log "\t        x: $x"
                _print_to_log "\t        y: $y"
                _print_to_log "\tplacement: $placementStatus"
            }
        }

        # Check Orientation
        set bOrient [_orientToBinary $orient]
        if {$bOrient == -1} {
            set msg "Aborting due to a cell having an illegal orientation\n"
            append msg "\t libName: $instLibName\n"
            append msg "\tcellName: $instCellName\n"
            append msg "\t    path: $instHier\n"
            append msg "\t  origin: $origin\n"
            append msg "\t  orient: $orient"
            _print $msg "error"
            error "Aborting"
        }

        if {[db::getPrefValue defCheckCompareDef] == 1 \
            && [db::getPrefValue defCheckDefType] == "DI" \
            && $topLibName == $instLibName} {
            set instViewName [db::getAttr viewName -of $oaInst]
            set context [de::open [dm::getCellViews $instViewName \
                                                    -libName $instLibName \
                                                    -cellName $instCellName] \
                                  -headless true \
                                  -readOnly true]
            set instDesign [db::getAttr viewDesign -of $context]
            set instCollection [db::getInsts -of $instDesign]

            set instCellsList {}
            db::foreach inst $instCollection {
                set instName [db::getAttr cellName -of $inst] 
                if {[_checkExcludeList $excludedCells $instName]} {
                    if {[lsearch $topcells $instName] != -1} {
                        set msg [join [list "The cell '$instName' was found in the topcells " \
                                            "file and was included in the exclude list! " \
                                            "The cell will not be excluded."] \
                                       ""]
                        _print $msg "error"
                    } else {
                        continue
                    }
                }
                if {[db::listAttrs def_ignoreExists -of $inst] != "" \
                    && [db::getAttr def_ignoreExists -of $inst]} {
                    lassign [db::getAttr bBox -of $inst] llCorner
                    if {[lsearch $topcells $instName] != -1} {
                        set msg [join [list "The cell '$instName' was found in the topcells " \
                                            "file and was previously waived! " \
                                            "The cell will not be ignored and the waive flag will be updated."] \
                                       ""]
                        _print $msg "error"
                        set errorList [list $instName $instLibName "$instHier/$instCellName"]
                        lappend errorList $llCorner
                        dict update errorDict waived var {dict lappend var topcells $errorList}
                    } else {
                        set errorList [list $instName $instLibName "$instHier/$instCellName"]
                        lappend errorList $llCorner
                        dict update errorDict waived var {dict lappend var cktcells $errorList}
                        _print_to_log "The following cell has been waived:" "warning"
                        _print_to_log "\t cellname: $instName"
                        _print_to_log "\t  libName: $instLibName"
                        _print_to_log "\thierarchy: $instHier/$instCellName"
                        _print_to_log "\t     bBox: [db::getAttr bBox -of $inst]"
                        continue
                    }
                }
                set retList [_checkInst $inst $topLibName "$instHier/$instCellName" \
                                        $pitchList $excludedCells errorDict]
                lappend instCellsList {*}$retList
            }

            foreach iList $instCellsList {
                set newBBox   [_updateBBox $orient $origin [lindex $iList 1]]
                set newOrient [_updateOrient $orient [lindex $iList 2]]
                lappend instList [list [lindex $iList 0] $newBBox $newOrient {*}[lrange $iList 3 end]]
            }
            de::close $context
        } else {
            lappend instList [list $instCellName $bBox $orient $instHier $bBox $orient]
        }

        return $instList
    }

    proc _updateBBox {orient origin bBox} {
        lassign [split $origin]     xOrigin yOrigin
        set lowerLeft  [lindex $bBox 0]
        set upperRight [lindex $bBox 1]
        lassign [split $lowerLeft]  xMin yMin
        lassign [split $upperRight] xMax yMax
        switch $orient {
            "R0" {
                # Do Nothing
            }
            "MX" {
                set yTemp $yMin
                set yMin  [expr {-$yMax}]
                set yMax  [expr {-$yTemp}]
            }
            "MY" {
                set xTemp $xMin
                set xMin  [expr {-$xMax}]
                set xMax  [expr {-$xTemp}]
            }
            "R180" {
                set yTemp $yMin
                set yMin  [expr {-$yMax}]
                set yMax  [expr {-$yTemp}]
                set xTemp $xMin
                set xMin  [expr {-$xMax}]
                set xMax  [expr {-$xTemp}]
            }
            default {
                _print "Illegal orientation: $orient" "error"
                error "Aborting"
            }
        }
        set lowerLeft  [list [expr {$xOrigin+$xMin}] [expr {$yOrigin+$yMin}]]
        set upperRight [list [expr {$xOrigin+$xMax}] [expr {$yOrigin+$yMax}]]
        return [list $lowerLeft $upperRight]
    }

    proc _updateOrient {cellOrient subcellOrient} {
        set cOrient [_orientToBinary $cellOrient]
        set sOrient [_orientToBinary $subcellOrient]
        set rOrient [expr {$cOrient ^ $sOrient}]
        return [_binaryToOrient $rOrient]
    }

    proc _orientToBinary {orient} {
        switch $orient {
            "R0" {
                set bin 0
            }
            "MY" {
                set bin 1
            }
            "MX" {
                set bin 2
            }
            "R180" {
                set bin 3
            }
            default {
                set bin -1
            }
        }
        return $bin
    }

    proc _binaryToOrient {bin} {
        switch $bin {
            0 {
                set orient "R0"
            }
            1 {
                set orient "MY"
            }
            2 {
                set orient "MX"
            }
            3 {
                set orient "R180"
            }
            default {
                _print "Illegal orientation conversion: $bin" "error"
                error "Aborting"
            }
        }
        return $orient
    }

    proc _compareDef {instList excludedCells} {
        variable topcells
        # Read the DEF
        lassign [_readDef] unitsDistance components
        # If the units distance factor was not read, abort.
        if {$unitsDistance == 0} {
            set msg "Unable to find the units distance line in DEF! Aborting..."
            _print $msg "error"
            # TBD: Adjust return number
            return -1
        }
        # Separate the components using the ';' delimiter. Now each item in the
        # list contains a single component. This was done because a component 
        # can be span multiple lines, but it always ends with ';'.
        set defComp [lreplace [split $components ";"] end end]

        # Get the list of excluded cells. The list is empty if the option is not
        # set.

        set unmatchedComps     {}
        set unplacedComps      {}
        set illegalOrientComps {}
        # Check each inst from the list. Check if the cell is excluded. If not, 
        # check its placement status, and try to find the matching instance from
        # the current cell instance list. If it was not found print an error 
        # message.
        foreach comp $defComp {
            # Split the attribute list using the delimiter "+"
            set compAttrList [split $comp "+"]
            # Get the component cellname, and check if it was excluded or not.
            set compCellName [lindex [split [string trimleft [lindex $compAttrList 0] " -"]] 1]
            set compInstanceName [lindex [split [string trimleft [lindex $compAttrList 0] " -"]] 0]
            if {[_checkExcludeList $excludedCells $compCellName]} {
                if {[lsearch $topcells $compCellName] != -1} {
                    set msg [join [list "The cell '$compCellName' was found in the topcells " \
                                        "file and was included in the exclude list! " \
                                        "The cell will not be excluded."] \
                                   ""]
                    _print $msg "error"
                } else {
                    continue
                }
            }

            set placementStatus 0
            # Loop the attributes list to find the placement attribute
            foreach compAttr $compAttrList {
                # Split the attribute into a list.
                set compAttr [regexp -inline -all -- {\S+} $compAttr]
                # Check if this attribute is related to the palcement, and it 
                # starts with COVER/PLACED/FIXED
                if {[regexp (^COVER|^PLACED|^FIXED) [lindex $compAttr 0]] } {
                    incr placementStatus
                    # Get the position and orientation
                    lassign $compAttr {} {} x y {} orient
                    set position [list [expr {double($x)/$unitsDistance}] \
                                       [expr {double($y)/$unitsDistance}]]
                    set cOrient [_defOrientToBinary $orient]
                    # Check the orientation
                    if {$cOrient == -1} {
                        lappend illegalOrientComps [list $compCellName \
                                                         $compInstanceName \
                                                         $orient]
                    } else {
                        # Check for a matching instance from the instances list.
                        # Compare the cellname, position and orientation.
                        set matchedInstanceList [lsearch -all -index 0 $instList $compCellName]
                        set found 0
                        if {[llength $matchedInstanceList] > 0} {
                            foreach instIndex $matchedInstanceList {
                                set instPosition [lindex [lindex [lindex $instList $instIndex] 1] 0]
                                set iOrient [_orientToBinary [lindex [lindex $instList $instIndex] 2]]
                                # If found, remove the instance from the list.
                                if {$instPosition == $position && $iOrient == $cOrient} {
                                    set instList [lreplace $instList $instIndex $instIndex]
                                    set found 1
                                    break
                                }
                            }
                        }
                        if {$found == 0} {
                            lappend unmatchedComps [list $compCellName \
                                                         $compInstanceName \
                                                         $position \
                                                         [_binaryToOrient $cOrient]]
                        }
                    }
                }
            }
            # If the placement attribute was not found or the cell is unplaced, 
            # print an error.
            if {$placementStatus == 0} {
                lappend unplacedComps [list $compCellName $compInstanceName]
            }
        }
        return [list $unplacedComps $illegalOrientComps $unmatchedComps $instList]
    }

    proc _readDef {} {
        # Get and read the DEF file
        set defFile [db::getPrefValue defCheckDefInputFile]
        set defFH [open $defFile r]
        if {[string match "*.gz" $defFile]} {
            zlib push gunzip $defFH
        }

        # Initialize the variables to know if they have been changed or not.
        set unitsDistance 0
        set status ""
        set components ""

        # Get the units distance factor, and all of the components
        # The units distance factor shoold be before the components
        # The components listing starts with COMPONENTS #### and ends with
        # END COMPONENTS ;
        while {[gets $defFH line] >=0} {
            if {[string match "COMPONENTS*" $line]} {
                set status "COMPONENTS"
                continue
            } 
            if {[string match "END COMPONENTS*" $line]} {
                break
            }
            if {$status == "COMPONENTS"} {
                append components $line
            }
            if {[regexp {UNITS DISTANCE MICRONS (\d+)} $line match factor]} {
                set unitsDistance $factor
            }
        }
        close $defFH
        return [list $unitsDistance $components]
    }

    proc _getExcludedCells {} {
        set excludedCells {}
        if {[db::getPrefValue defCheckExclude] == 1} {
            #  Get the list of cells in the exlcuded libs
            if {[db::getPrefValue defCheckExcludeLibs] == 1} {
                set excludedLibsList [db::getPrefValue defCheckExcludedLibsList]
                if {[db::getPrefValue defCheckExcludeGlobEnable]} {
                    foreach lib $excludedLibsList {
                        set dmCellsList [dm::getCells -libName $lib]
                        db::foreach dmCell $dmCellsList {
                            lappend excludedCells "*[db::getAttr name -of $dmCell]*"
                        }
                    }
                } else {
                    foreach lib $excludedLibsList {
                        set dmCellsList [dm::getCells -libName $lib]
                        db::foreach dmCell $dmCellsList {
                            lappend excludedCells [db::getAttr name -of $dmCell]
                        }
                    }
                }
            }
            # Add the excluded cells to the list
            if {[db::getPrefValue defCheckExcludeCells] == 1} {
                set excludedCellsList [db::getPrefValue defCheckExcludedCellsList]
                lappend excludedCells {*}$excludedCellsList
            }
        }
        return $excludedCells
    }

    proc _defOrientToBinary {orient} {
        switch $orient {
            "N" {
                set bin 0
            }
            "FN" {
                set bin 1
            }
            "FS" {
                set bin 2
            }
            "S" {
                set bin 3
            }
            default {
                set bin -1
            }
        }
        return $bin
    }

    proc _checkExcludeList {excludedCells cellName} {
        set excluded 0
        foreach excludedCell $excludedCells {
            if {[string match $excludedCell $cellName]} {
                set excluded 1
                break
            }
        }
        return $excluded
    }

    proc _printCompareDefErrorMessages {errorList} {
        lassign $errorList unplacedC iOrientC unmatchedC unmatchedI
        set printUnmatched [db::getPrefValue defCheckPrintUnmatched]

        # Print the list of unplaced components
        foreach comp $unplacedC {
            set msg "Unable to find the placement status for the following cell in the DEF:"
            _print_to_log $msg "error"
            _print_to_log "\t    cellName: [lindex $comp 0]"
            _print_to_log "\tinstanceName: [lindex $comp 1]"
        }

        # Print the list of components with illegal orientation
        foreach comp $iOrientC {
            set msg "The following cell has an illegal orientation in the DEF:"
            _print_to_log $msg "error"
            _print_to_log "\t    cellName: [lindex $comp 0]"
            _print_to_log "\tinstanceName: [lindex $comp 1]"
            _print_to_log "\t orientation: [lindex $comp 2]"

        }

        # Print the list of unmatched instances
        foreach inst $unmatchedI {
            set msg "The following cell exists in OA but not in the DEF:"
            _print_to_log $msg "error"
            _print_to_log "\t       cellName: [lindex $inst 0]"
            _print_to_log "\t  toplevel bBox: [lindex $inst 1]"
            _print_to_log "\ttoplevel orient: [lindex $inst 2]"
            _print_to_log "\t      hierarchy: [lindex $inst 3]"
            _print_to_log "\t           bBox: [lindex $inst 4]"
            _print_to_log "\t         orient: [lindex $inst 5]"
        }

        # Print the list of unmatched components
        if {$printUnmatched == 1} {
            foreach comp $unmatchedC {
                set msg "The following cell exists in the DEF but not in OA:"
                _print_to_log $msg "error"
                _print_to_log "\t    cellName: [lindex $comp 0]"
                _print_to_log "\tinstanceName: [lindex $comp 1]"
                _print_to_log "\t   LL corner: [lindex $comp 2]"
                _print_to_log "\t      orient: [lindex $comp 3]"
            }
        }

        # Print the summary
        _print_to_log "DEF Compare Summary:" "information" 
        if {[llength $unplacedC] > 0} {
            set msg "\tUnable to find the placement status for [llength $unplacedC] cells in the DEF!"
            _print $msg "error"
        }
        if {[llength $iOrientC] > 0} {
            set msg "\tThere are [llength $iOrientC] cells with illegal orientation in the DEF!"
            _print $msg "error"
        }
        if {[llength $unmatchedI] > 0} {
            set msg "\tThere are [llength $unmatchedI] unmatched cells in OA!"
            _print $msg "error"
        } else {
            set msg "\tAll of the cells in OA match a cell in the DEF." 
            _print $msg "information"
        }
        if {[llength $unmatchedC] > 0} {
            set msg "\tThere are [llength $unmatchedC] unmatched cells in the DEF!"
            _print $msg "error"
        } else {
            set msg "\tAll of the cells in the DEF are either excluded or match a cell in OA."
            _print $msg "information"
        }
    }

    proc _log_file_setup {} {
        global RUN_DIR_ROOT
        variable oaDesign
        set libName [db::getAttr libName -of $oaDesign]
        set cellName [db::getAttr cellName -of $oaDesign]
        set verifPath "$RUN_DIR_ROOT/$libName/$cellName"
        if {![file exists $verifPath]} {
            file mkdir $verifPath
        }
        set fileName "$verifPath/defCheck_$cellName.log"
        set ::defCheck::logFile [open $fileName w]
    }

    proc _print { msg {type ""}} {
        if {$type eq ""} {
            set prefix "    "
        } elseif {$type eq "information"} {
            set prefix "-I- "
        } elseif {$type eq "warning"} {
            set prefix "-W- "
        } elseif {$type eq "error"} {
            set prefix "-E- "
        } else {
            set type ""
            set prefix "    "
        }
        
        if {$type eq ""} {
            puts $msg
        } else {
            de::sendMessage $msg -severity $type
        }
        puts $::defCheck::logFile "$prefix$msg"
        flush $::defCheck::logFile
    }

    proc _print_to_log { msg {type ""}} {
        if {$type eq ""} {
            set prefix "    "
        } elseif {$type eq "information"} {
            set prefix "-I- "
        } elseif {$type eq "warning"} {
            set prefix "-W- "
        } elseif {$type eq "error"} {
            set prefix "-E- "
        } else {
            set type ""
            set prefix "    "
        }
        
        puts $::defCheck::logFile "$prefix$msg"
        flush $::defCheck::logFile
    }

    proc _createMenuEntry {} {
        set toolMenu [gi::getMenus -filter {%title == "ddr-utils-lay"}]
        if {[db::isEmpty $toolMenu]} {
            return
        }
        db::setAttr shown -of $toolMenu -value true
        gi::createAction widgetDefCheckAction -title "DEF Check" -command [namespace code gui]
        gi::addActions widgetDefCheckAction -to $toolMenu
        return
    }

    proc _resultsDialog {errorDict} {
        # Create Dialog
        set dialog [gi::createDialog defCheckResults \
                                     -title "DEF Check Results" \
                                     -showApply false \
                                     -showHelp false]
        set tabGroup [gi::createTabGroup tabGroup -parent $dialog]
        # Summary Tab
        set summaryTab [gi::createGroup summaryTab -parent $tabGroup -label "Summary"]
        set summaryTable [gi::createTable widgetSummaryTable \
                                          -parent $summaryTab \
                                          -readOnly true]
        # Create Columns
        set checkCol [gi::createColumn -parent $summaryTable \
                                       -label "Check" \
                                       -stretch true \
                                       -readOnly true]
        set violationsCol [gi::createColumn -parent $summaryTable \
                                            -label "Violations" \
                                            -stretch true \
                                            -readOnly true]
        # Create offgrid row
        set offgrid   [llength [dict get $errorDict offgrid]]
        set offgridRow [gi::createRow -parent $summaryTable]
        db::setAttr value -of [gi::getCells -row $offgridRow -column $checkCol] \
                          -value "Off-grid OA cells"
        db::setAttr value -of [gi::getCells -row $offgridRow -column $violationsCol] \
                          -value $offgrid
        if {$offgrid != 0} {
            db::setAttr background -of [db::getAttr style -of [gi::getCells -row $offgridRow]] \
                                   -value red
            set offgridTab [gi::createGroup offgridTab -parent $tabGroup -label "Off-grid"]
            _createOffgridTab $offgridTab [dict get $errorDict "offgrid"]
        } else {
            db::setAttr background -of [db::getAttr style -of [gi::getCells -row $offgridRow]] \
                                   -value "light green"
        }
        # Create unplaced row
        set unplaced  [llength [dict get $errorDict unplaced]]
        set unplacedRow [gi::createRow -parent $summaryTable]
        db::setAttr value -of [gi::getCells -row $unplacedRow -column $checkCol] \
                          -value "Unplaced OA cells"
        db::setAttr value -of [gi::getCells -row $unplacedRow -column $violationsCol] \
                          -value $unplaced
        if {$unplaced != 0} {
            db::setAttr background -of [db::getAttr style -of [gi::getCells -row $unplacedRow]] \
                                   -value red
            set unplacedTab [gi::createGroup unplacedTab -parent $tabGroup -label "Unplaced"]
            _createUnplacedTab $unplacedTab [dict get $errorDict "unplaced"]
        } else {
            db::setAttr background -of [db::getAttr style -of [gi::getCells -row $unplacedRow]] \
                                   -value "light green"
        }
        # Create misplaced row
        if {[db::getPrefValue defCheckPlacementEnable]} {
            set misplaced [llength [dict get $errorDict misplaced]]
            set misplacedRow [gi::createRow -parent $summaryTable]
            db::setAttr value -of [gi::getCells -row $misplacedRow -column $checkCol] \
                              -value "OA cells with placmenet status other than [db::getPrefValue defCheckPlacementMode]"
            db::setAttr value -of [gi::getCells -row $misplacedRow -column $violationsCol] \
                              -value $misplaced
            if {$misplaced != 0} {
                db::setAttr background -of [db::getAttr style -of [gi::getCells -row $misplacedRow]] \
                                       -value orange
                set misplacedTab [gi::createGroup misplacedTab -parent $tabGroup -label "Wrong Placement"]
                _createMisplacedTab $misplacedTab [dict get $errorDict "misplaced"]
            } else {
                db::setAttr background -of [db::getAttr style -of [gi::getCells -row $misplacedRow]] \
                                       -value "light green"
            }
        }
        # Create waived tab
        set waivedCkt [llength [dict get $errorDict waived cktcells]]
        set waivedTop [llength [dict get $errorDict waived topcells]]
        if {$waivedTop != 0} {
            set waivedRow [gi::createRow -parent $summaryTable]
            db::setAttr value -of [gi::getCells -row $waivedRow -column $checkCol] \
                              -value "Waived OA cells that exist in topcells.txt"
            db::setAttr value -of [gi::getCells -row $waivedRow -column $violationsCol] \
                              -value $waivedTop
            db::setAttr background -of [db::getAttr style -of [gi::getCells -row $waivedRow]] \
                                   -value red
        }
        if {$waivedCkt != 0 || $waivedTop != 0} {
            set waivedTab [gi::createGroup waivedTab -parent $tabGroup -label "Waived"]
            _createWaivedTab $waivedTab [dict get $errorDict waived topcells] [dict get $errorDict waived cktcells]
        }
        # Create compare DEF rows
        if {[db::getPrefValue defCheckCompareDef]} {
            lassign [dict get $errorDict compareDef] unplacedC iOrientC unmatchedC unmatchedI
            if {[llength $unplacedC] > 0} {
                set defUnplacedRow [gi::createRow -parent $summaryTable]
                db::setAttr value -of [gi::getCells -row $defUnplacedRow -column $checkCol] \
                                  -value "Unplaced DEF cells"
                db::setAttr value -of [gi::getCells -row $defUnplacedRow -column $violationsCol] \
                                  -value [llength $unplacedC]
                db::setAttr background -of [db::getAttr style -of [gi::getCells -row $defUnplacedRow]] \
                                       -value red
            }
            if {[llength $iOrientC] > 0} {
                set defiOrientRow [gi::createRow -parent $summaryTable]
                db::setAttr value -of [gi::getCells -row $defiOrientRow -column $checkCol] \
                                  -value "DEF cells with illegal orientation"
                db::setAttr value -of [gi::getCells -row $defiOrientRow -column $violationsCol] \
                                  -value [llength $iOrientC]
                db::setAttr background -of [db::getAttr style -of [gi::getCells -row $defiOrientRow]] \
                                       -value red
            }
            # Create unmatched OA cells row
            set unmatchedOa [llength $unmatchedI]
            set unmatchedOaRow [gi::createRow -parent $summaryTable]
            db::setAttr value -of [gi::getCells -row $unmatchedOaRow -column $checkCol] \
                              -value "Unmatched OA cells"
            db::setAttr value -of [gi::getCells -row $unmatchedOaRow -column $violationsCol] \
                              -value $unmatchedOa
            if {$unmatchedOa != 0} {
                db::setAttr background -of [db::getAttr style -of [gi::getCells -row $unmatchedOaRow]] \
                                       -value red
                set unmatchedOaTab [gi::createGroup unmatchedOaTab -parent $tabGroup -label "Unmatched OA"]
                _createUnmatchedOaTab $unmatchedOaTab $unmatchedI
            } else {
                db::setAttr background -of [db::getAttr style -of [gi::getCells -row $unmatchedOaRow]] \
                                       -value "light green"
            }
            # Create unmatched DEF cells row
            set unmatchedDef [llength $unmatchedC]
            set unmatchedDefRow [gi::createRow -parent $summaryTable]
            db::setAttr value -of [gi::getCells -row $unmatchedDefRow -column $checkCol] \
                              -value "Unmatched DEF cells"
            db::setAttr value -of [gi::getCells -row $unmatchedDefRow -column $violationsCol] \
                              -value $unmatchedDef
            if {$unmatchedDef != 0} {
                db::setAttr background -of [db::getAttr style -of [gi::getCells -row $unmatchedDefRow]] \
                                       -value red
                set unmatchedDefTab [gi::createGroup unmatchedDefTab -parent $tabGroup -label "Unmatched DEF"]
                _createUnmatchedDefTab $unmatchedDefTab $unmatchedC
            } else {
                db::setAttr background -of [db::getAttr style -of [gi::getCells -row $unmatchedDefRow]] \
                                       -value "light green"
            }
        }

        gi::_update
        set currentGeometry [db::getAttr geometry -of $dialog]
        lassign [split $currentGeometry "+"] tmp xoff yoff
        lassign [split $tmp "x"] x y
        if {$x < 500} {
            set x 500
        }
        db::setAttr geometry -of $dialog -value "$x\x$y+$xoff+$yoff"
        return
    }

    proc _createOffgridTab {offgridTab errorList} {
        # Create waive menu
        set offgridTable [gi::createTable widgetOffgridTable \
                                          -parent $offgridTab \
                                          -allowSortColumns true \
                                          -allowHideColumns true \
                                          -alternatingRowColors true \
                                          -readOnly true]
        # Create Columns
        set numberCol [gi::createColumn -parent $offgridTable \
                                        -readOnly true]
        set cellnameCol [gi::createColumn -parent $offgridTable \
                                          -label "Cell Name" \
                                          -stretch true \
                                          -readOnly true]
        set libnameCol [gi::createColumn -parent $offgridTable \
                                         -label "Lib Name" \
                                         -stretch true \
                                         -readOnly true]
        set hierarchyCol [gi::createColumn -parent $offgridTable \
                                           -label "Hierarchy" \
                                           -stretch true \
                                           -readOnly true]
        set llCol [gi::createColumn -parent $offgridTable \
                                           -label "Lower Left Corner" \
                                           -stretch true \
                                           -readOnly true]
        set remainderCol [gi::createColumn -parent $offgridTable \
                                           -label "Remainder" \
                                           -stretch true \
                                           -readOnly true]

        set ind 0
        # Create a row for each violation
        foreach item $errorList {
            set currentRow [gi::createRow -parent $offgridTable]
            db::setAttr value -of [gi::getCells -row $currentRow -column $numberCol] \
                              -value [incr ind]
            db::setAttr value -of [gi::getCells -row $currentRow -column $cellnameCol] \
                              -value [lindex $item 0]
            db::setAttr value -of [gi::getCells -row $currentRow -column $libnameCol] \
                              -value [lindex $item 1]
            db::setAttr value -of [gi::getCells -row $currentRow -column $hierarchyCol] \
                              -value [lindex $item 2]
            db::setAttr value -of [gi::getCells -row $currentRow -column $llCol] \
                              -value [lindex $item 3]
            db::setAttr value -of [gi::getCells -row $currentRow -column $remainderCol] \
                              -value [lindex $item 4]
        }
    }

    proc _createUnplacedTab {unplacedTab errorList} {
        set unplacedTable [gi::createTable widgetUnplacedTable \
                                          -parent $unplacedTab \
                                          -allowSortColumns true \
                                          -allowHideColumns true \
                                          -alternatingRowColors true \
                                          -readOnly true]
        # Create Columns
        set numberCol [gi::createColumn -parent $unplacedTable \
                                        -readOnly true]
        set cellnameCol [gi::createColumn -parent $unplacedTable \
                                          -label "Cell Name" \
                                          -stretch true \
                                          -readOnly true]
        set libnameCol [gi::createColumn -parent $unplacedTable \
                                         -label "Lib Name" \
                                         -stretch true \
                                         -readOnly true]
        set hierarchyCol [gi::createColumn -parent $unplacedTable \
                                           -label "Hierarchy" \
                                           -stretch true \
                                           -readOnly true]
        set llCol [gi::createColumn -parent $unplacedTable \
                                           -label "Lower Left Corner" \
                                           -stretch true \
                                           -readOnly true]

        set ind 0
        # Create a row for each violation
        foreach item $errorList {
            set currentRow [gi::createRow -parent $unplacedTable]
            db::setAttr value -of [gi::getCells -row $currentRow -column $numberCol] \
                              -value [incr ind]
            db::setAttr value -of [gi::getCells -row $currentRow -column $cellnameCol] \
                              -value [lindex $item 0]
            db::setAttr value -of [gi::getCells -row $currentRow -column $libnameCol] \
                              -value [lindex $item 1]
            db::setAttr value -of [gi::getCells -row $currentRow -column $hierarchyCol] \
                              -value [lindex $item 2]
            db::setAttr value -of [gi::getCells -row $currentRow -column $llCol] \
                              -value [lindex $item 3]
        }
    }

    proc _createMisplacedTab {misplacedTab errorList} {
        set misplacedTable [gi::createTable widgetMisplacedTable \
                                          -parent $misplacedTab \
                                          -allowSortColumns true \
                                          -allowHideColumns true \
                                          -alternatingRowColors true \
                                          -readOnly true]
        # Create Columns
        set numberCol [gi::createColumn -parent $misplacedTable \
                                        -readOnly true]
        set cellnameCol [gi::createColumn -parent $misplacedTable \
                                          -label "Cell Name" \
                                          -stretch true \
                                          -readOnly true]
        set libnameCol [gi::createColumn -parent $misplacedTable \
                                         -label "Lib Name" \
                                         -stretch true \
                                         -readOnly true]
        set hierarchyCol [gi::createColumn -parent $misplacedTable \
                                           -label "Hierarchy" \
                                           -stretch true \
                                           -readOnly true]
        set llCol [gi::createColumn -parent $misplacedTable \
                                           -label "Lower Left Corner" \
                                           -stretch true \
                                           -readOnly true]
        set placementStatusCol [gi::createColumn -parent $misplacedTable \
                                                 -label "Placement Status" \
                                                 -stretch true \
                                                 -readOnly true]

        set ind 0
        # Create a row for each violation
        foreach item $errorList {
            set currentRow [gi::createRow -parent $misplacedTable]
            db::setAttr value -of [gi::getCells -row $currentRow -column $numberCol] \
                              -value [incr ind]
            db::setAttr value -of [gi::getCells -row $currentRow -column $cellnameCol] \
                              -value [lindex $item 0]
            db::setAttr value -of [gi::getCells -row $currentRow -column $libnameCol] \
                              -value [lindex $item 1]
            db::setAttr value -of [gi::getCells -row $currentRow -column $hierarchyCol] \
                              -value [lindex $item 2]
            db::setAttr value -of [gi::getCells -row $currentRow -column $llCol] \
                              -value [lindex $item 3]
            db::setAttr value -of [gi::getCells -row $currentRow -column $placementStatusCol] \
                              -value [lindex $item 4]
        }
    }

    proc _createWaivedTab {waivedTab topcellsList cktcellsList} {
        set waivedTable [gi::createTable widgetWaivedTable \
                                          -parent $waivedTab \
                                          -allowSortColumns true \
                                          -allowHideColumns true \
                                          -alternatingRowColors true \
                                          -contextMenuProc [namespace code _removeWaiverCmd] \
                                          -selectionModel multipleRows \
                                          -readOnly true]
        # Create Columns
        set numberCol [gi::createColumn -parent $waivedTable \
                                        -readOnly true]
        set cellnameCol [gi::createColumn -parent $waivedTable \
                                          -label "Cell Name" \
                                          -stretch true \
                                          -readOnly true]
        set libnameCol [gi::createColumn -parent $waivedTable \
                                         -label "Lib Name" \
                                         -stretch true \
                                         -readOnly true]
        set hierarchyCol [gi::createColumn -parent $waivedTable \
                                           -label "Hierarchy" \
                                           -stretch true \
                                           -readOnly true]
        set llCol [gi::createColumn -parent $waivedTable \
                                           -label "Lower Left Corner" \
                                           -stretch true \
                                           -readOnly true]
        set topcellCol [gi::createColumn -parent $waivedTable \
                                         -label "Exist in topcells" \
                                         -stretch true \
                                         -readOnly true]

        set ind 0
        # Create a row for each topcell and set the background to red
        foreach item $topcellsList {
            set currentRow [gi::createRow -parent $waivedTable]
            db::setAttr value -of [gi::getCells -row $currentRow -column $numberCol] \
                              -value [incr ind]
            db::setAttr value -of [gi::getCells -row $currentRow -column $cellnameCol] \
                              -value [lindex $item 0]
            db::setAttr value -of [gi::getCells -row $currentRow -column $libnameCol] \
                              -value [lindex $item 1]
            db::setAttr value -of [gi::getCells -row $currentRow -column $hierarchyCol] \
                              -value [lindex $item 2]
            db::setAttr value -of [gi::getCells -row $currentRow -column $llCol] \
                              -value [lindex $item 3]
            db::setAttr value -of [gi::getCells -row $currentRow -column $topcellCol] \
                              -value "Yes"
            db::setAttr background -of [db::getAttr style -of [gi::getCells -row $currentRow]] \
                                   -value red
        }
        # Create a row for each cktcell
        foreach item $cktcellsList {
            set currentRow [gi::createRow -parent $waivedTable]
            db::setAttr value -of [gi::getCells -row $currentRow -column $numberCol] \
                              -value [incr ind]
            db::setAttr value -of [gi::getCells -row $currentRow -column $cellnameCol] \
                              -value [lindex $item 0]
            db::setAttr value -of [gi::getCells -row $currentRow -column $libnameCol] \
                              -value [lindex $item 1]
            db::setAttr value -of [gi::getCells -row $currentRow -column $hierarchyCol] \
                              -value [lindex $item 2]
            db::setAttr value -of [gi::getCells -row $currentRow -column $llCol] \
                              -value [lindex $item 3]
            db::setAttr value -of [gi::getCells -row $currentRow -column $topcellCol] \
                              -value "No"
        }
    }

    proc _createUnmatchedOaTab {unmatchedOaTab errorList} {
        set unmatchedOaTable [gi::createTable widgetUnmatchedOaTable \
                                              -parent $unmatchedOaTab \
                                              -allowSortColumns true \
                                              -allowHideColumns true \
                                              -alternatingRowColors true \
                                              -selectionModel multipleRows \
                                              -contextMenuProc [namespace code _waiveCmd] \
                                              -readOnly true]
        # Create Columns
        set numberCol [gi::createColumn -parent $unmatchedOaTable \
                                        -readOnly true]
        set cellnameCol [gi::createColumn -parent $unmatchedOaTable \
                                          -label "Cell Name" \
                                          -stretch true \
                                          -readOnly true]
        set topBboxCol [gi::createColumn -parent $unmatchedOaTable \
                                         -label "Toplevel Bbox" \
                                         -stretch true \
                                         -readOnly true]
        set topOrientCol [gi::createColumn -parent $unmatchedOaTable \
                                           -label "Toplevel Orientation" \
                                           -stretch true \
                                           -readOnly true]
        set hierarchyCol [gi::createColumn -parent $unmatchedOaTable \
                                           -label "Hierarchy" \
                                           -stretch true \
                                           -readOnly true]
        set bboxCol [gi::createColumn -parent $unmatchedOaTable \
                                      -label "bBox" \
                                      -stretch true \
                                      -readOnly true]
        set orientCol [gi::createColumn -parent $unmatchedOaTable \
                                        -label "Orientation" \
                                        -stretch true \
                                        -readOnly true]

        set ind 0
        # Create a row for each violation
        foreach item $errorList {
            set currentRow [gi::createRow -parent $unmatchedOaTable]
            db::setAttr value -of [gi::getCells -row $currentRow -column $numberCol] \
                              -value [incr ind]
            db::setAttr value -of [gi::getCells -row $currentRow -column $cellnameCol] \
                              -value [lindex $item 0]
            db::setAttr value -of [gi::getCells -row $currentRow -column $topBboxCol] \
                              -value [lindex $item 1]
            db::setAttr value -of [gi::getCells -row $currentRow -column $topOrientCol] \
                              -value [lindex $item 2]
            db::setAttr value -of [gi::getCells -row $currentRow -column $hierarchyCol] \
                              -value [lindex $item 3]
            db::setAttr value -of [gi::getCells -row $currentRow -column $bboxCol] \
                              -value [lindex $item 4]
            db::setAttr value -of [gi::getCells -row $currentRow -column $orientCol] \
                              -value [lindex $item 5]
        }
    }

    proc _createUnmatchedDefTab {unmatchedDefTab errorList} {
        set unmatchedDefTable [gi::createTable widgetUnmatchedDefTable \
                                          -parent $unmatchedDefTab \
                                          -allowSortColumns true \
                                          -allowHideColumns true \
                                          -alternatingRowColors true \
                                          -readOnly true]
        # Create Columns
        set numberCol [gi::createColumn -parent $unmatchedDefTable \
                                        -readOnly true]
        set cellnameCol [gi::createColumn -parent $unmatchedDefTable \
                                          -label "Cell Name" \
                                          -stretch true \
                                          -readOnly true]
        set instnameCol [gi::createColumn -parent $unmatchedDefTable \
                                          -label "Instance Name" \
                                          -stretch true \
                                          -readOnly true]
        set llCol [gi::createColumn -parent $unmatchedDefTable \
                                    -label "Lower Left Corner" \
                                    -stretch true \
                                    -readOnly true]
        set orientCol [gi::createColumn -parent $unmatchedDefTable \
                                                -label "Orientation" \
                                                -stretch true \
                                                -readOnly true]

        set ind 0
        # Create a row for each violation
        foreach item $errorList {
            set currentRow [gi::createRow -parent $unmatchedDefTable]
            db::setAttr value -of [gi::getCells -row $currentRow -column $numberCol] \
                              -value [incr ind]
            db::setAttr value -of [gi::getCells -row $currentRow -column $cellnameCol] \
                              -value [lindex $item 0]
            db::setAttr value -of [gi::getCells -row $currentRow -column $instnameCol] \
                              -value [lindex $item 1]
            db::setAttr value -of [gi::getCells -row $currentRow -column $llCol] \
                              -value [lindex $item 2]
            db::setAttr value -of [gi::getCells -row $currentRow -column $orientCol] \
                              -value [lindex $item 3]
        }
    }

    proc _waiveSelectedCell {} {
        variable topcells
        variable oaDesign
        # Get the selected rows
        set table  [gi::findChild widgetUnmatchedOaTable -in [gi::getActiveDialog]]
   		set selectedRows [db::getAttr selection -of $table]
        # Get the columns
        set cellNameCol [gi::getColumns -parent $table -filter {%label=="Cell Name"}]
        set bBoxCol [gi::getColumns -parent $table -filter {%label=="bBox"}]
        set orientCol [gi::getColumns -parent $table -filter {%label=="Orientation"}]
        set hierarchyCol [gi::getColumns -parent $table -filter {%label=="Hierarchy"}]
        # waive each selected cell if it doesn't 
        db::foreach selectedRow $selectedRows {
            set cellname [db::getAttr value -of [gi::getCells -row $selectedRow \
                                                              -column $cellNameCol]]
            if {[lsearch $topcells $cellname] != -1} {
                set msg "Cannot waive the cell '$cellname' because it is located in the topcells file."
                de::sendMessage $msg -severity "error"
            } else {
                set topCellName    [db::getAttr cellName -of $oaDesign]
                set topLibName     [db::getAttr libName  -of $oaDesign]
                set topViewName    [db::getAttr viewName -of $oaDesign]
                set instCollection [db::getInsts -of $oaDesign]
                set oaCellView [dm::getCellViews $topViewName -cellName $topCellName -libName $topLibName]
                set instList {}
                set waiveDict [dict create removed {} status [dict create]]
                set trans [de::startTransaction "defCheck: Waive $cellname" -design $oaDesign]
                db::foreach inst $instCollection {
                    _waiveInstances $inst $cellname $topLibName $oaCellView $topCellName waiveDict
                }
                de::endTransaction $trans
                set count [llength [dict get $waiveDict removed]]
                if {$count > 0} {
                    de::sendMessage "Waived $count instances of $cellname!" -severity "information"
                    set rowCollection [gi::getRows -parent $table]
                    set removedList [dict get $waiveDict removed]
                    while {[set row [db::getNext $rowCollection]] != ""} {
                        set cellname [db::getAttr value -of [gi::getCells -row $row \
                                                                          -column $cellNameCol]]
                        set hierarchy [db::getAttr value -of [gi::getCells -row $row \
                                                                           -column $hierarchyCol]]
                        set localBBox [db::getAttr value -of [gi::getCells -row $row \
                                                                           -column $bBoxCol]]
                        set localOrient [db::getAttr value -of [gi::getCells -row $row \
                                                                             -column $orientCol]]
                        if {$cellname == $cellname} {
                            foreach item $removedList {
                                if {     [lindex $item 0] == $hierarchy \
                                      && [lindex $item 1] == $localBBox \
                                      && [lindex $item 2] == $localOrient} {
                                    db::setAttr shown -of $row -value false
                                    break
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    proc _waiveInstances {oaInst cellname topLibName parentOaCellView instHier dictName} {
        upvar 1 $dictName waiveDict
        set instCellName [db::getAttr cellName -of $oaInst] 
        set instLibName  [db::getAttr libName -of $oaInst] 
        if {$instCellName == $cellname} {
            set status [_checkoutCell $parentOaCellView $instHier $dictName]
            if {$status == 1} {
                if {[db::listAttrs def_ignoreExists -of $oaInst] == ""} {
                    db::createProp $oaInst -name def_ignoreExists -value true -type bool
                } else {
                    if {[db::getAttr def_ignoreExists -of $oaInst]} {
                        return
                    }
                    db::setAttr def_ignoreExists -value true -of $oaInst
                }
                set bBox   [db::getAttr bBox -of $oaInst]
                set orient [db::getAttr orientation -of $oaInst]
                dict lappend waiveDict removed [list $instHier $bBox $orient]
            }
        } elseif {[db::getPrefValue defCheckCompareDef] == 1 \
                  && [db::getPrefValue defCheckDefType] == "DI" \
                  && $topLibName == $instLibName} {
            set instViewName [db::getAttr viewName -of $oaInst]
            set context [de::open [dm::getCellViews $instViewName \
                                                    -libName $instLibName \
                                                    -cellName $instCellName] \
                                  -headless true \
                                  -readOnly true]
            set oaDesign [db::getAttr viewDesign -of $context]
            set instCollection [db::getInsts -of $oaDesign]
            set oaCellView [dm::getCellViews $instViewName -cellName $instCellName -libName $instLibName]

            set instCellsList {}
            db::foreach inst $instCollection {
                _waiveInstances $inst $cellname $topLibName $oaCellView "$instHier/$instCellName" $dictName
            }
            de::close $context
        }
    }

    proc _checkoutCell {oaCellView hier dictName} {
        upvar 1 $dictName waiveDict
        set cellName [db::getAttr oaCellView.cellName]
        # Check if the cell status is stored
        if {[dict exists $waiveDict status $cellName]} {
            return [dict get $waiveDict status $cellName]
        } else {
            set path [file dirname [db::getAttr oaCellView.primary.path]]
            set viewName [db::getAttr oaCellView.name]
            set status [_checkCellPerforceStatus $oaCellView]
            switch -exact -- $status {
                "notOnDepot" - "opened" { return 1 }
                "otherOpen" { 
                    set err "The view $cellName/$viewName is opened by another user."
                    de::sendMessage $err -severity error
                    dict set waiveDict "status" $cellName -1
                    return -1
                }
                "notOpened" {
                    set reply [gi::prompt "Checkout $cellName/$viewName?" \
                                          -title "Checkout cell" \
                                          -buttons "Yes No" \
                                          -icon question]
                    set checkout -1
                    if {$reply == "Yes"} {
                        dm::checkOut $oaCellView
                        set checkout 1
                    }
                    dict set waiveDict "status" $cellName $checkout
                    return $checkout
                }
                default {
                    error "Unknown status when checking the view $cellName/$viewName status"
                }
            }
        }
    }

    proc _checkCellPerforceStatus { dmCellView } {
        set cellViewPath [db::getAttr dmCellView.primary.path]
        set status "unknown"
        if {[catch {exec p4 have $cellViewPath} err]} {
            set status "notOnDepot"
        } else {
            if {[catch {set buffer [exec p4 fstat -T "action otherOpen" $cellViewPath]} err]} {
                set status "notOpened"
            } else {
                if {[regexp {otherOpen} $buffer match]} {
                    set status "otherOpen"
                }
                if {[regexp {action} $buffer match]} {
                    set status "opened"
                }
            }
        }
        return $status
    }

    proc _removeWaiverSelectedCell {} {
        variable topcells
        variable oaDesign
        # Get the selected rows
        set table  [gi::findChild widgetWaivedTable -in [gi::getActiveDialog]]
   		set selectedRows [db::getAttr selection -of $table]
        # Get the columns
        set cellNameCol [gi::getColumns -parent $table -filter {%label=="Cell Name"}]
        set llCol [gi::getColumns -parent $table -filter {%label=="Lower Left Corner"}]
        set hierarchyCol [gi::getColumns -parent $table -filter {%label=="Hierarchy"}]
        # Remove waiver foreach selected cell
        db::foreach selectedRow $selectedRows {
            set cellname [db::getAttr value -of [gi::getCells -row $selectedRow \
                                                              -column $cellNameCol]]
            set topCellName    [db::getAttr cellName -of $oaDesign]
            set topLibName     [db::getAttr libName  -of $oaDesign]
            set topViewName    [db::getAttr viewName -of $oaDesign]
            set instCollection [db::getInsts -of $oaDesign]
            set oaCellView [dm::getCellViews $topViewName -cellName $topCellName -libName $topLibName]
            set instList {}
            set waiveDict [dict create removed {} status [dict create]]
            set trans [de::startTransaction "defCheck: Remove waiver $cellname" -design $oaDesign]
            db::foreach inst $instCollection {
                _removeWaiverInstances $inst $cellname $topLibName $oaCellView $topCellName waiveDict
            }
            de::endTransaction $trans
            set count [llength [dict get $waiveDict removed]]
            if {$count > 0} {
                de::sendMessage "Remove waiver for $count instances of $cellname!" -severity "information"
                set rowCollection [gi::getRows -parent $table]
                set removedList [dict get $waiveDict removed]
                while {[set row [db::getNext $rowCollection]] != ""} {
                    set cellname [db::getAttr value -of [gi::getCells -row $row \
                                                                      -column $cellNameCol]]
                    set hierarchy [db::getAttr value -of [gi::getCells -row $row \
                                                                       -column $hierarchyCol]]
                    set llCorner  [db::getAttr value -of [gi::getCells -row $row \
                                                                       -column $llCol]]
                    if {$cellname == $cellname} {
                        foreach item $removedList {
                            if {     [lindex $item 0] == $hierarchy \
                                  && [lindex $item 1] == $llCorner } {
                                db::setAttr shown -of $row -value false
                                break
                            }
                        }
                    }
                }
            }
        }
    }

    proc _removeWaiverInstances {oaInst cellname topLibName parentOaCellView instHier dictName} {
        upvar 1 $dictName waiveDict
        set instCellName [db::getAttr cellName -of $oaInst] 
        set instLibName  [db::getAttr libName -of $oaInst] 
        if {$instCellName == $cellname} {
            set status [_checkoutCell $parentOaCellView $instHier waiveDict]
            if {$status == 1} {
                if {[db::listAttrs def_ignoreExists -of $oaInst] == ""} {
                    return
                } else {
                    if {![db::getAttr def_ignoreExists -of $oaInst]} {
                        return
                    }
                    db::setAttr def_ignoreExists -value false -of $oaInst
                }
                lassign [db::getAttr bBox -of $oaInst] llCorner
                dict lappend waiveDict removed [list $instHier $llCorner]
            }
        } elseif {[db::getPrefValue defCheckCompareDef] == 1 \
                  && [db::getPrefValue defCheckDefType] == "DI" \
                  && $topLibName == $instLibName} {
            set instViewName [db::getAttr viewName -of $oaInst]
            set context [de::open [dm::getCellViews $instViewName \
                                                    -libName $instLibName \
                                                    -cellName $instCellName] \
                                  -headless true \
                                  -readOnly true]
            set oaDesign [db::getAttr viewDesign -of $context]
            set instCollection [db::getInsts -of $oaDesign]
            set oaCellView [dm::getCellViews $instViewName -cellName $instCellName -libName $instLibName]

            set instCellsList {}
            db::foreach inst $instCollection {
                _removeWaiverInstances $inst $cellname $topLibName $oaCellView "$instHier/$instCellName" $dictName
            }
            de::close $context
        }
    }

    proc _readTopCells {} {
        global env
        variable topcells
        # Get the path to the topCells file
        set designDir "$::env(MSIP_PROJ_ROOT)/$::env(MSIP_PRODUCT_NAME)/$::env(MSIP_PROJ_NAME)/$::env(MSIP_REL_NAME)/design"
        set topcellsFile [_firstAvailableFile "$designDir/topcells.txt" \
                                              "${designDir}_unrestricted/topcells.txt"]
        if {![file exists $topcellsFile]} {
            _print "Couldn't find the topcells.txt file!" "warning"
            return
        }
        set fp [open $topcellsFile r]
        set lines [read $fp]
        close $fp
        set topcells ""
        foreach line $lines {
            if {[regexp {^\[LAY\][^/]+/([^/]+)/[^/]+} $line to cellname]} {
                lappend topcells $cellname
            }
        }
    }

    proc _waiveCmd {table} {
        set waiveMenu [gi::createMenu widgetDefCheckWaiveMenu -title "Waive"]
        gi::createAction widgetDefCheckWaiveAction \
                         -title "waive" \
                         -command [namespace code _waiveSelectedCell]
        gi::addActions widgetDefCheckWaiveAction -to $waiveMenu
        return [gi::getMenus widgetDefCheckWaiveMenu]
    }

    proc _removeWaiverCmd {table} {
        set removeWaiverMenu [gi::createMenu widgetDefCheckRemoveWaiverMenu -title "RemoveWaiver"]
        gi::createAction widgetDefCheckRemoveWaiverAction \
                         -title "remove waiver" \
                         -command [namespace code _removeWaiverSelectedCell]
        gi::addActions widgetDefCheckRemoveWaiverAction -to $removeWaiverMenu
        return [gi::getMenus widgetDefCheckRemoveWaiverMenu]
    }
}

defCheck::_createMenuEntry




################################################################################
# No Linting Area
################################################################################

# nolint Main
# nolint Line  77: E Wrong number of arguments 
# nolint Line  78: E Wrong number of arguments 
# nolint Line  79: E Wrong number of arguments 
# nolint Line 128: E Wrong number of arg
# nolint Line 139: E Wrong number of arg
# nolint Line 145: E Wrong number of arg
# nolint Line 179: E Wrong number of arg
# nolint Line 234: N Non constant level 
# nolint Line 234: N Suspicious upvar va
# nolint Line 236: N Suspicious variable
# nolint Line 238: N Suspicious variable
# nolint Line 243: N Non constant level 
# nolint Line 243: N Suspicious upvar va
# nolint Line 244: N Suspicious variable
# nolint Line 260: N Close brace not ali
# nolint Line 260: N Close brace not ali
# nolint Line 1420: E Wrong number of ar
# nolint Line 1491: E Wrong number of ar