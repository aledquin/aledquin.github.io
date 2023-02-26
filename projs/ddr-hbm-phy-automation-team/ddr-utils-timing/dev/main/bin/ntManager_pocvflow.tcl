#!/depot/tk8.6.1/bin/wish
#nolint Main
proc tutils__script_usage_statistics {toolname version} {
    set prefix "ddr-da-timing-utils-"
    set reporter "/remote/cad-rep/msip/tools/bin/msip_get_usage_info"
    set cmd ""
    set script_dirname [file dirname [file normalize [info script]]]
    append cmd "$reporter --tool_name  \"${prefix}${toolname}\" "
    append cmd "--stage main --category ude_ext_1 "
    append cmd "--tool_path \"$script_dirname\" --tool_version \"$version\""

    exec sh -c $cmd
}

set script_name [file tail [file rootname [file normalize [info script]]]]
tutils__script_usage_statistics $script_name "2022ww23"

variable args
set restart 0

set typeList {etm internal}

#  LS_COLORS causes problem for jobs launched on RH5 that land on a RH6 machine (or is it the other way around).  This should resolve it.
if [info exists env(LS_COLORS)] {unset env(LS_COLORS)}

##  List of the recognized source files.  Consider putting this under config file control
set sourceFileList [list pininfoFile equivFile ntConstraintsFile ntExceptionsFile ntPrecheckFile ntPrecheckTopoFile ntPrematchTopoFile ntUserSettingFile ntMungeCustomConfig]

#  default.
set phase pre
set hierSep "/"

if {$argc > 0} { 

    ## Look specifically for "-restart" arg
    set i [lsearch -exact $argv "-restart"]
    if {$i >= 0} {
	set argv [lreplace $argv $i $i]
	puts "Restarting"
	set restart 1
    }

    ## Read any command-line args into array "args".
    for {set i 0} {$i < $argc} {incr i} {
	set argName [lindex $argv $i]
	if {[string range $argName 0 0] == "-"} {
	    ##  Argname detected
	    set argName [string replace $argName 0 0]
	    if {[incr i] < $argc} {
		set scriptArgs($argName) [lindex $argv $i]
	    } else {
		puts "Error:  Missing arg value for \"$argName\""
		exit
	    }
	}
    }
#    foreach argName [array names args] {puts "$argName $args($argName)"} 
}

if [info exists scriptArgs(logFile)] {
    set logFile $scriptArgs(logFile)
    array unset scriptArgs(logFile)
} else {set logFile "./ntManager_pocvflow.log"}

if [catch {set LOG [open $logFile "w"]}] {logMsg "Error:  Cannot open $logFile for write\n"}

proc exitApp {} {
    if [info exists ::LOG] {close $::LOG}
    exit
}


proc getArgValue {argList name} {
    
    set l [llength $argList]
    set i [lsearch $argList $name]
    if {$i >= 0} {
	if {$i == [expr $l-1]} {
	    ## There isn't a value for -type
	    logMsg "Error:  Missing value for \$name\":\n"
	    return ""
	} else {
	    return [lindex $argList [expr $i+1]]
	}
    }
}

proc stdDir {dir} {
    ##  Convert to a standardized direction format

    set d [string tolower $dir]
    
    if {$d == "i"} {
	set d "input"
    } elseif {$d == "o"} {
	set d "output"
    } elseif {$d == "io"} {
	set d "inout"
    } elseif {$d == "input"} {
    } elseif {$d == "output"} {
    } elseif {$d == "inout"} {
    } else {
	logMsg "Error: Unrecognized direction \"$dir\" in pininfo file\n";
	return $dir
    }
    return $d
}

proc mergeLib {args} {
    ##  I think this proc is obsolete.
    set inTypes [getArgValue $args "-inTypes"]
    set outType [getArgValue $args "-outType"]

    set OK 1
    if {$inTypes == ""} {
	logMsg "Error: Missing required arg \"-$inTypes\"\n"
	set OK 0
    }
    if {$outType == ""} {
	logMsg "Error: Missing required arg \"-$outType\"\n"
	set OK 0
    }

    if {!$OK} {
	return
    }

    ##  Save them.
    set ::mergeLibs($outType) $inTypes
}

proc setRunvar {args} {
    
    ##  Look for -type arg
    set l [llength $args]
    set i [lsearch $args "-type"]
    set type "all"
    if {$i >= 0} {
	if {$i == [expr $l-1]} {
	    ## There isn't a value for -type
	    logMsg "Error:  Missing value for \"-type\":\n"
	    logMsg "\tsetRunvar $args\n"
	    return
	} else {
	    set type [lindex $args [expr $i+1]]
	    set args [lreplace $args $i [expr $i+1]]
	}
    }

    if {[llength $args] == 2} {
	set varName [lindex $args 0]
	set varValue [lindex $args 1]
	if [info exists ::runVars($type)] {
	    ## Check for existing definition
	    set i [lsearch -glob $::runVars($type) "$varName=*"]
	    if {$i >= 0} {
		set ::runVars($type) [lreplace $::runVars($type) $i $i]
	    }
	}
	lappend ::runVars($type) "$varName=$varValue"
    } else {
	logMsg "Error:  Bad syntax \"setRunvar $args\"\n"
    }
}


proc logMsg {msg} {

    .tf.out config -state normal
    .tf.out insert end $msg
    .tf.out see end
    .tf.out config -state disabled
    update
    ##  Write to log file.
    if [info exists ::LOG] {puts -nonewline $::LOG $msg}
}

proc setConfigFromArg {argName args} {

    ##  Set a variable to an argument from a script arg, if present.  If not, set to default value, if provided.

    global $argName

    if [info exists ::scriptArgs($argName)] { 
	set $argName $::scriptArgs(localConfig) 
    } else {
	## Not supplied.  See if there's a default.

	## Don't overwrite arg if already defined
	if [info exists $argName] {return}
	if {[llength $args] > 0} {set $argName [lindex $args 0]}
    }

}

proc refreshProjName {} {
    ##  Refreshes the projectName listbox or projectType is defined

    if [info exists ::projectType] {
	.nb.projtab.f.cnv.win.name.list.lb delete 0 end
	set cwd [pwd]
	cd "$env(MSIP_PROJ_ROOT)/$::projectType"
	set projectNameGlob [glob -nocomplain -type d "*"]
	cd $cwd
	foreach p [lsort $projectNameGlob] {.nb.projtab.f.cnv.win.name.list.lb insert end $p}
    }
}

proc refreshReleaseName {} {
    ##  Refreshes the releaseName listbox or projectType and projectName are defined

        if {[info exists ::projectType] && [info exists ::projectName]} {
	.nb.projtab.f.cnv.win.release.list.lb delete 0 end
	set cwd [pwd]
	cd "$env(MSIP_PROJ_ROOT)/$::projectType/$::projectName"
	set releaseNameGlob [glob -nocomplain -type d "*"]
	foreach r [lsort $releaseNameGlob] {if [file exists $r/cad/project.env] {.nb.projtab.f.cnv.win.release.list.lb insert end $r}}
	cd $cwd
    }
}

proc refreshMetalStack {} {
    ##  Refreshes the releaseName listbox or projectType, projectName and releaseName are defined
    if {[info exists ::projectType] && [info exists ::projectName] && [info exists ::releaseName] } {
	.nb.projtab.f.cnv.win.stack.list.lb delete 0 end
	set cwd [pwd]
	cd "$env(MSIP_PROJ_ROOT)/$::projectType/$::projectName/$::releaseName/cad"
	set stackNameGlob [glob -nocomplain -type d "*"]
	foreach s [lsort $stackNameGlob] {if [file exists $s/env.tcl] {.nb.projtab.f.cnv.win.stack.list.lb insert end $s}}
	cd $cwd
    }
}

proc validateProject {} {

    logMsg "Info: validateProject\n"
    setSetupButtonColor validateProject blue
    set ::setupStatusInfo(validateProject) ""
    set projectTypeDefined [info exists ::projectType]
    set projectNameDefined [info exists ::projectName]
    set releaseNameDefined [info exists ::releaseName]
    set metalStackDefined  [info exists ::metalStack]

    set ::setupStatus(validateProject) 1
    if {$projectTypeDefined && $projectNameDefined && $releaseNameDefined && $metalStackDefined} {
	set projPath "$::env(MSIP_PROJ_ROOT)/$::projectType/$::projectName/$::releaseName/cad/$::metalStack"
	set ::setupStatusInfo(validateProject) $projPath
	if {![file exists $projPath]} {
	    set ::setupStatus(validateProject) 0
	    .nb.setuptab.f.cnv.win.validateProject.status configure -text "Does not exist"
	}
    } else {
	if {!$projectTypeDefined} {lappend details "projectTypeUndefined"}
	if {!$projectNameDefined} {lappend details "projectNameUndefined"}
	if {!$releaseNameDefined} {lappend details "releaseNameUndefined"}
	if {!$metalStackDefined} {lappend details "metalStackUndefined"}
	set ::setupStatus(validateProject) 0
	set ::setupStatusInfo(validateProject) $details
	.nb.setuptab.f.cnv.win.validateProject.status configure -text "Failed"
    }

    if $::setupStatus(validateProject) {
	.nb.setuptab.f.cnv.win.validateProject.status configure -text "OK"
	setSetupButtonColor validateProject green
    } else {
	setSetupButtonColor validateProject red
    }
    return $::setupStatus(validateProject)
}

proc validateLibCell {} {

    logMsg "Info: validateLibCell\n"
    setSetupButtonColor validateLibCell blue
    set ::setupStatus(validateLibCell) 1
    set ::setupStatusInfo(validateLibCell) ""

    if {![info exists ::libName]} {
	set ::setupStatus(validateLibCell) 0
	lappend ::setupStatusInfo(validateLibCell) "libNameUndefined"
    } else {set libCell $::libName}

    if {![info exists ::cellName]} {
	set ::setupStatus(validateLibCell) 0
	lappend ::setupStatusInfo(validateLibCell) "cellNameUndefined"
    } else {append libCell " / $::cellName"}
    

    if $::setupStatus(validateLibCell) {set stat "OK"} else {set stat "Failed"}
    .nb.setuptab.f.cnv.win.validateLibCell.status configure -text $stat
    set ::setupStatusInfo(validateLibCell) $libCell
    return $::setupStatus(validateLibCell)

}

proc validatePOCVinfo {} {

    logMsg "Info: validatePOCVinfo\n"
    setSetupButtonColor validatePOCVinfo blue
    set ::setupStatus(validatePOCVinfo) 1
    set ::setupStatusInfo(validatePOCVinfo) ""

   
    if [info exists ::ntEnablePOCV_etm] {
 	set args9 [set ::ntEnablePOCV_etm]
	logMsg  "INFO : set ntEnablePOCVvalidate $args9"
        set stat "OK with pocv"
    } else {
        set stat "OK w/o pocv"
	logMsg  "INFO : set ntEnablePOCVvalidate false"
	}
    

   
    if $::setupStatus(validatePOCVinfo) {
        } else {set stat "Failed"}
   
    .nb.setuptab.f.cnv.win.validatePOCVinfo.status configure -text $stat
   
    set ::setupStatusInfo(validatePOCVinfo) $stat
    return $::setupStatus(validatePOCVinfo)

}



proc modifyCornerData {pvt pvtData} {
    ##  Modifies or adds a pvt entry.  Intended for use in the local config file.
    
    if [info exists ::cornerData] {
	if [info exists ::cornerData($pvt)] {set data $::cornerData($pvt) } else { set data {}  }

	foreach newAttrPair [split $pvtData ","] {
#	    puts "$newAttrPair"
	    if {[llength $newAttrPair] == 2} {
		logMsg "Info: Modifying $pvt: $newAttrPair\n"
		set argName [lindex $newAttrPair 0]
		set argValue [lindex $newAttrPair 1]

		set new ""
		set sep ""
		set found 0
		set attrPairList [split $data ","]
		foreach attrPair $attrPairList {
		    if {[llength $attrPair] == 2} {

			if {[lindex $attrPair 0] == $argName} { 
			    append new "$sep$argName $argValue" 
			    set found 1
			} else { 
			    append new "$sep$attrPair" 
			}
			set sep ","

		    } else {logMsg "Error:  Bad pvt attr spec {$attrPair}"}
		    if {!$found} {lappend attrPairList "$sep$argName $argValue"}
		    set data $new
		}
	    } else {logMsg "Error:  Bad pvt attr spec {$newAttrPair}"}
	}
	set ::cornerData($pvt) $data
    } else {
	#	logMsg "Warning (modifyCornerData):  cornerData  undefined"
    }
}


proc queryProject {} {
    
    global projectType
    global projectName
    global releaseName
    global metalStack
    global projectTypeGlob
    global projectValid
    global cellName
    global libName

    set cwd [pwd]
    ##  Build list of valid project types
    cd $env(MSIP_PROJ_ROOT)
    set projectTypeGlob [lsort [glob -nocomplain -type d "*"]]
    cd $cwd

    frame .nb.projtab.f.cnv.win.type
    pack [label .nb.projtab.f.cnv.win.type.label -text "ProjectType"]  -side top
    frame .nb.projtab.f.cnv.win.type.list
    pack [listbox .nb.projtab.f.cnv.win.type.list.lb -height 10 -width 20 -yscrollcommand ".nb.projtab.f.cnv.win.type.list.scroll set" -listvariable projectTypeGlob -selectmode single] -side left
    pack [scrollbar .nb.projtab.f.cnv.win.type.list.scroll -command ".nb.projtab.f.cnv.win.type.list.lb yview"] -side right
    pack .nb.projtab.f.cnv.win.type.list
    pack [text .nb.projtab.f.cnv.win.type.text -height 1 -width 20] -side bottom
    pack .nb.projtab.f.cnv.win.type -side left

    frame .nb.projtab.f.cnv.win.name
    pack [label .nb.projtab.f.cnv.win.name.label -text "ProjectName"]  -side top
    frame .nb.projtab.f.cnv.win.name.list
    pack [listbox .nb.projtab.f.cnv.win.name.list.lb -height 10 -width 20 -yscrollcommand ".nb.projtab.f.cnv.win.name.list.scroll set" -selectmode single] -side left
    pack [scrollbar .nb.projtab.f.cnv.win.name.list.scroll -command ".nb.projtab.f.cnv.win.name.list.lb yview"] -side right
    pack .nb.projtab.f.cnv.win.name.list
    pack [text .nb.projtab.f.cnv.win.name.text -height 1 -width 20] -side bottom
    pack .nb.projtab.f.cnv.win.name -side left

    frame .nb.projtab.f.cnv.win.release
    pack [label .nb.projtab.f.cnv.win.release.label -text "ProjectRelease"]  -side top
    frame .nb.projtab.f.cnv.win.release.list
    pack [listbox .nb.projtab.f.cnv.win.release.list.lb -height 10 -width 20 -yscrollcommand ".nb.projtab.f.cnv.win.release.list.scroll set" -selectmode single] -side left
    pack [scrollbar .nb.projtab.f.cnv.win.release.list.scroll -command ".nb.projtab.f.cnv.win.release.list.lb yview"] -side right
    pack .nb.projtab.f.cnv.win.release.list
    pack [text .nb.projtab.f.cnv.win.release.text -height 1 -width 20] -side bottom
    pack .nb.projtab.f.cnv.win.release -side left

    frame .nb.projtab.f.cnv.win.stack
    pack [label .nb.projtab.f.cnv.win.stack.label -text "ProjectStack"]  -side top
    frame .nb.projtab.f.cnv.win.stack.list
    pack [listbox .nb.projtab.f.cnv.win.stack.list.lb -height 10 -width 20 -yscrollcommand ".nb.projtab.f.cnv.win.stack.list.scroll set" -selectmode single] -side left
    pack [scrollbar .nb.projtab.f.cnv.win.stack.list.scroll -command ".nb.projtab.f.cnv.win.stack.list.lb yview"] -side right
    pack .nb.projtab.f.cnv.win.stack.list
    pack [text .nb.projtab.f.cnv.win.stack.text -height 1 -width 20] -side bottom
    pack .nb.projtab.f.cnv.win.stack -side left

    if [info exists projectType] {.nb.projtab.f.cnv.win.type.text insert end $projectType}
    if [info exists projectName] {.nb.projtab.f.cnv.win.name.text insert end $projectName}
    if [info exists releaseName] {.nb.projtab.f.cnv.win.release.text insert end $releaseName}
    if [info exists metalStack] {.nb.projtab.f.cnv.win.stack.text insert end $metalStack}

    refreshProjName
    refreshReleaseName
    refreshMetalStack

    validateProject

    frame .nb.projtab.f.cnv.win.cell
    pack [label .nb.projtab.f.cnv.win.cell.nameLabel -text "cellName"] -side top
    pack [text .nb.projtab.f.cnv.win.cell.nameText -height 1 -width 50] -side top
    if [info exists cellName] {.nb.projtab.f.cnv.win.cell.nameText insert end $cellName}

    pack [label .nb.projtab.f.cnv.win.cell.libLabel -text "libName"] -side top
    pack [text .nb.projtab.f.cnv.win.cell.libText -height 1 -width 50] -side top
    if [info exists libName] {.nb.projtab.f.cnv.win.cell.libText insert end $libName}
    pack .nb.projtab.f.cnv.win.cell -side left
    
    bind .nb.projtab.f.cnv.win.cell.nameText  <KeyPress-Return> {
	set cellName [selection get]
    }

    bind .nb.projtab.f.cnv.win.cell.libText  <KeyPress-Return> {
	set libName [selection get]
    }

    bind .nb.projtab.f.cnv.win.type.list.lb  <ButtonRelease-1> {
	##  A project type has been selected.  Grab it and clear all the others
	set projectType [selection get]
	.nb.projtab.f.cnv.win.type.text delete 0.0 end
	.nb.projtab.f.cnv.win.type.text insert end $projectType
	if [info exists projectName] {unset projectName}
	if [info exists releaseName ] {unset releaseName}
	if [info exists metalStack] {unset metalStack}
	.nb.projtab.f.cnv.win.name.text delete 0.0 end
	.nb.projtab.f.cnv.win.release.text delete 0.0 end
	.nb.projtab.f.cnv.win.stack.text delete 0.0 end

	.nb.projtab.f.cnv.win.name.list.lb delete 0 end
	.nb.projtab.f.cnv.win.release.list.lb delete 0 end
	.nb.projtab.f.cnv.win.stack.list.lb delete 0 end
	refreshProjName
	set projectValid 0
    }

    bind .nb.projtab.f.cnv.win.name.list.lb  <ButtonRelease-1> {
	##  A project name has been selected.
	set projectName [selection get]
	.nb.projtab.f.cnv.win.name.text delete 0.0 end
	.nb.projtab.f.cnv.win.name.text insert end $projectName
	if [info exists releaseName ] {unset releaseName}
	if [info exists metalStack] {unset metalStack}
	.nb.projtab.f.cnv.win.release.text delete 0.0 end
	.nb.projtab.f.cnv.win.stack.text delete 0.0 end

	.nb.projtab.f.cnv.win.release.list.lb delete 0 end
	.nb.projtab.f.cnv.win.stack.list.lb delete 0 end
	refreshReleaseName
	set projectValid 0
    }

    bind .nb.projtab.f.cnv.win.release.list.lb  <ButtonRelease-1> {
	##  A project release has been selected.
	set releaseName [selection get]
	.nb.projtab.f.cnv.win.release.text delete 0.0 end
	.nb.projtab.f.cnv.win.release.text insert end $releaseName
	if [info exists metalStack] {unset metalStack}
	.nb.projtab.f.cnv.win.stack.text delete 0.0 end
	.nb.projtab.f.cnv.win.stack.list.lb delete 0 end
	refreshMetalStack
	set projectValid 0
    }

    bind .nb.projtab.f.cnv.win.stack.list.lb  <ButtonRelease-1> {
	##  A project stack has been selected.
	set metalStack [selection get]
	.nb.projtab.f.cnv.win.stack.text delete 0.0 end
	.nb.projtab.f.cnv.win.stack.text insert end $metalStack
	validateProject
    }
}

proc checkRequiredVariable {varName} {
    global $varName

    if [info exists $varName] {
	return 1
    } else {
	set msg "Error:  Missing required variable \"$varName\"\n"
	tk_messageBox -type ok -message $msg
	logMsg $msg
	return 0
    }
}

proc createPvtRow {fields rootName rowNum} {

    ## Build up a row of simple text boxes.
    set colNum 0
    set rowFrame $rootName.row$rowNum
    frame $rowFrame
    foreach val $fields {
	pack [entry $rowFrame.col$colNum -width 10 -justify center -font MyDefaultFont] -side left
	$rowFrame.col$colNum insert end $val
	incr colNum
    }
    return $rowFrame
}


proc moveitx {args} {
        eval ".pvt.pvtFrame.array xview $args"
        set nowat [.pvt.pvtFrame.array xview]
        eval ".pvt.pvtFrame.scrollH set $nowat"
        }
proc moveity {args} {
        eval ".pvt.pvtFrame.array yview $args"
        set nowat [.pvt.pvtFrame.array yview]
        eval ".pvt.pvtFrame.scrollV set $nowat"
        }

proc processPVT {} {
    ## Processes the PVT data and lays out grid on page
    global cornerData
    global pvtCorners
    global supplyPins
    global groundPins
    global modelLibs

    logMsg "Info:  processPVT\n"
    setSetupButtonColor processPVT blue

    set ::setupStatus(processPVT) 1
    set ::setupStatusInfo(processPVT) ""

    ##  Make sure oc_global_supply is defined
    if [info exists ::oc_global_supply] {
	## oc_global_supply is defined
	if {[lsearch -exact $::supplyPins $::oc_global_supply] < 0} {
	    ## ... but is not a listed supply.  Just use the first supply.
	    set defSupply [lindex $::supplyPins 0]
	    logMsg "Error: oc_global_supply \"$::oc_global_supply\" does not exist. Using $defSupply\n"
	    set ::oc_global_supply $defSupply
	} else {
	    ##  Exists.
	}
    } else {
	##  oc_global_supply is undefined. Use the first listed.
	set ::oc_global_supply [lindex $::supplyPins 0]
	logMsg "Warning:  oc_global_supply is undefined.  Using $::oc_global_supply\n"
    }

    ##  Create supplyPinsGlobalLast that has the oc_global_supply listed last.  Important for the pg_pins Munge script processing.
    set s ""
    foreach supply $::supplyPins {
	if {$supply != $::oc_global_supply} {lappend s $supply}
    }
    lappend s $::oc_global_supply
    set ::supplyPinsGlobalLast $s
    
    if {![info exists pvtCorners]} {
	set ::pvtCorners {}
	tk_messageBox -type ok -message "Missing required variable \"pvtCorners\""
	set ::setupStatus(processPVT) 0
	lappend ::setupStatusInfo(processPVT) "pvtCornersUndefined"
	return 0
    }

    if [winfo exists .nb.pvttab.f.cnv.win.pvtFrame] {
	logMsg "Info:  Erasing PVT data array\n"
	destroy .nb.pvttab.f.cnv.win.pvtFrame
    }
    frame .nb.pvttab.f.cnv.win.pvtFrame
    ##  Use a canvas to manage the data rows; scrollable.
#    canvas .pvt.pvtFrame.array -yscrollcommand ".pvt.pvtFrame.scrollV set" -xscrollcommand ".pvt.pvtFrame.scrollH set" -xscrollincrement 10 -yscrollincrement 10
#    canvas .pvt.pvtFrame.array  -width 1000 -height 600
    set rowNum 0
    set colNum 0
    set row ""
    lappend row "Corner"
    if [checkRequiredVariable supplyPins] { foreach pin $supplyPins {lappend row $pin} }
#    if [checkRequiredVariable groundPins] { foreach pin $groundPins {lappend row $pin} }
    lappend row TEMP
    if [checkRequiredVariable modelLibs] { foreach lib $modelLibs {lappend row $lib} }
    
    lappend row "xType"
    lappend row "beol"
    lappend row "scPvt"

    pack [createPvtRow $row .nb.pvttab.f.cnv.win.pvtFrame $rowNum] -side top
    incr rowNum

    foreach PVT $pvtCorners {
	##  Break each list into an array for lookup convenience
	set pvtFields [parsePvt $PVT]
	if [info exists cornerData($PVT)] {
#	    logMsg "$cornerData($PVT)\n"
	    ##  CornerData exists for this PVT
	    set row ""
	    lappend row $PVT
	    if [info exists pvtData] {unset pvtData}
	    set attrPairList [split $cornerData($PVT) ","]
	    foreach attrPair $attrPairList {
		if {[llength $attrPair] == 2} {
		    set varName [lindex $attrPair 0]
		    set varVal [lindex $attrPair 1]
		    set pvtData($varName) $varVal
#		    puts "$PVT:  $varName = $varVal"
		} else { 
		    set ::setupStatus(processPVT) 0
		    lappend ::setupStatusInfo(processPVT) "malformedAttr_${lib}_$PVT"
		    logMsg "Error:  Malformed PVT attribute pair \"$attrPair\"\n"
		}
	    }
	    
	    foreach pin $supplyPins {
		if [info exists pvtData($pin)] { 
		    lappend row $pvtData($pin) 
		} else { 
		    set ::setupStatus(processPVT) 0
		    lappend ::setupStatusInfo(processPVT) "missingAttr_${pin}_$PVT"
		    logMsg "Error: Missing attr \"$pin\" for pvt $PVT\n" 
		}
	    }
#	    foreach pin $groundPins {if [info exists pvtData($pin)] { lappend row $pvtData($pin) } else { logMsg "Error: Missing attr \"$pin\" for pvt $PVT\n" }}
	    if [info exists pvtData(TEMP)] { lappend row $pvtData(TEMP) } else { 
		logMsg "Error: Missing attr \"TEMP\" for pvt $PVT\n" 
		set ::setupStatus(processPVT) 0
		lappend ::setupStatusInfo(processPVT) "missingAttr_TEMP_$PVT"
	    }
	    foreach lib $modelLibs {
		if [info exists pvtData($lib)] { 
		    lappend row $pvtData($lib) 
		} else {
		    logMsg "Error: Missing attr \"$lib\" for pvt $PVT\n" 
		    set ::setupStatus(processPVT) 0
		    lappend ::setupStatusInfo(processPVT) "missingAttr_${lib}_$PVT"
		}
	    }
	    
	    lappend row $pvtData(xType)
	    lappend row $pvtData(beol)
	    lappend row $pvtData(scPvt)

	    pack [createPvtRow $row .nb.pvttab.f.cnv.win.pvtFrame $rowNum] -side top
	    incr rowNum

	} else { 
	    logMsg "Missing required variable \"cornerData($PVT)\"\n"
	    set ::setupStatus(processPVT) 0
	    lappend ::setupStatusInfo(processPVT) "cornerData($PVT)Undefined"
	}
    }
    
#    frame .nb.pvttab.f.cnv.win.pvts
#    pack [label .nb.pvttab.f.cnv.win.pvts.label -text "Defined PVTs"] -side  top
#    pack [listbox .nb.pvttab.f.cnv.win.pvts.lb -height 10 -width 20 -yscrollcommand ".nb.pvttab.f.cnv.win.pvts.scroll set" -listvariable pvtCorners -selectmode single] -side left
#    pack [scrollbar .nb.pvttab.f.cnv.win.pvts.scroll -command ".nb.pvttab.f.cnv.win.pvts.lb yview"] -side right
#    pack .nb.pvttab.f.cnv.win.pvts
#    pack [button .nb.pvttab.f.cnv.win.viewButton -text "View PVT Array" -command "pack .pvt.pvtFrame.array"] -side bottom
    pack .nb.pvttab.f.cnv.win.pvtFrame

##  Aborted attempt to build scrollable pvt table.
#    pack .pvt.pvtFrame.array
#    scrollbar .pvt.pvtFrame.scrollV -orient vertical -command moveity
#    scrollbar .pvt.pvtFrame.scrollH -orient horizontal -command moveitx
#    .pvt.pvtFrame.scrollV set 0 0.75
#    .pvt.pvtFrame.scrollH set 0 0.5

#    pack .pvt.pvtFrame.array
#    pack .pvt.pvtFrame -fill both -expand true


#    grid .pvt.pvtFrame.array .pvt.pvtFrame.scrollV -sticky news
#    grid .pvt.pvtFrame.scrollH -sticky news

    if {$::setupStatus(processPVT)} {
	.nb.setuptab.f.cnv.win.processPVT.status configure -text "OK"
    } else {
	.nb.setuptab.f.cnv.win.processPVT.status configure -text "Failed"
    }

    return $::setupStatus(processPVT)

}

proc runUdeCommand {name commands} {
    global $name
    global libName
    global cellName
    global projectType
    global projectName
    global releaseName
    global metalStack
    global env

    set cwd [pwd]
    logMsg "Info:  Running ude command, name=$name\n"
    logMsg "Info:  Command:  $commands\n"
    set shellScript "runUde.tmp.csh"
    set cdScript "runUde.tmp.tcl"
    set SCR [open $shellScript w]
    puts $SCR "\#!/bin/csh"
    puts $SCR "ude \\"
    puts $SCR "  --nogui \\"
    puts $SCR "  --log $cwd/cdesigner.$name.log \\"
    puts $SCR "  --projectType $projectType \\"
    puts $SCR "  --projectName $projectName \\"
    puts $SCR "  --releaseName $releaseName \\"
    puts $SCR "  --metalStack $metalStack \\"
    
    puts $SCR "  --command \"source $cwd/$cdScript\""
    close $SCR
    
    set SCR [open $cdScript w]
    puts $SCR "if \[catch {"
    puts $SCR $commands
    puts $SCR "} err\] { puts \"Command failed\" }"
    puts $SCR "exit -force 1"
    close $SCR
    
    file attributes $shellScript -permissions "+x"
    if [file exists $shellScript] {
	exec "./$shellScript"
	file delete $shellScript
	file delete $cdScript
    } else {
	logMsg "Error:  $shellScript missing\n"
    }

}

proc createSourceFile {name textWidget} {

    global $name
    global env

#    puts "createSourceFile $name"
    ## Pick up filename from text widget
    set sourceFile [string trim [$textWidget get]]
    set $name $sourceFile
    if {[file exists $sourceFile] && ![file writable $sourceFile]} {
	tk_messageBox -type ok -message "Error:  Cannot create $sourceFile; file exists and is not writable"
	return
    }


    set cwd [pwd]
    if {$name == "equivFile"} {
	set cmd {alpha::lpe::createConfigEquivFiles}
	set args "$::libName $::cellName $env(TMP)/config.tmp $equivFile $cwd/createEquiv.log"
    } elseif {$name == "pininfoFile"} {
	set pininfoName [set $name]
	set cmd {alpha::pininfo::genPininfo}
	set args "$::libName $::cellName {$::supplyPins} {$::groundPins} -pininfoCSV $pininfoName"
	if [info exists ::defaultRelatedPower] {append args " -defaultRelatedPower $::defaultRelatedPower"}
	if [info exists ::defaultRelatedGround] {append args " -defaultRelatedGround $::defaultRelatedGround"}
	if [info exists ::pininfoRelatedPowerAuto] {append args " -relatedPowerAutomatch {$::pininfoRelatedPowerAuto}"}
	if [info exists ::pininfoRelatedGroundAuto] {append args " -relatedGroundAutomatch {$::pininfoRelatedGroundAuto}"}
	if [info exists ::forceBracket] {append args " -forceBracket $::forceBracket"}
    }

    if [info exists cmd] {
	file delete $sourceFile
	runUdeCommand $name "$cmd $args"
	if [file exists $sourceFile] {
	    $textWidget config -fg green
	} else {$textWidget config -fg red}
	set $name $sourceFile
    }
}

proc editSourceFile {entryWidget} {
    ##  Edits a source file
    global editor

    set file [$entryWidget get]
    logMsg "Info:  Editing $file"
    if [info exists editor] {set theEditor $editor} else {set theEditor nedit}

    set cmd "$editor $file"
    exec {*}$cmd 2> /dev/null


}

proc commandDefined {cmd} {
    
    foreach dir [split $::env(PATH) ":"] {
	if [file exists "$dir/$cmd"] {
	    if [file executable "$dir/$cmd"] {return 1}
	}
    }
    return 0
}

proc validateP4 {} {

    logMsg "Info:  validateP4\n"
    setSetupButtonColor validateP4 blue
    set ::setupStatus(validateP4) 1
    set ::setupStatusInfo(validateP4) ""

    if {![commandDefined p4]} {
	set ::setupStatus(validateP4) 0
	lappend ::setupStatusInfo(validateP4) "p4ModuleUnloaded"
    }

    if {![info exists ::env(P4PORT)]} {
	set ::setupStatus(validateP4) 0
	lappend ::setupStatusInfo(validateP4) "portUndefined"
    }

    if {![info exists ::env(P4CLIENT)]} {
	set ::setupStatus(validateP4) 0
	lappend ::setupStatusInfo(validateP4) "clientUndefined"
    }


    if $::setupStatus(validateP4) {
	set info [exec p4 info]
	set infoLines [split $info "\n"]
	foreach line $infoLines {
	    regexp {Client name:\s+(\S+)} $line dummy ::p4info(client)
	    regexp {Client host:\s+(\S+)} $line dummy ::p4info(host)
	    regexp {Client root:\s+(\S+)} $line dummy ::p4info(clientRoot)
	    regexp {Server address:\s+(\S+)} $line dummy ::p4info(serverAddress)
	    regexp {Server root:\s+(\S+)} $line dummy ::p4info(serverRoot)
	}
    }

    if  $::setupStatus(validateP4) {
	set ::setupStatusInfo(validateP4) "Client=$::p4info(client), Port=$::env(P4PORT), Root=$::p4info(clientRoot)"
	.nb.setuptab.f.cnv.win.validateP4.status configure -text "OK"
    } else {
	.nb.setuptab.f.cnv.win.validateP4.status configure -text "Failed"
    }

    return $::setupStatus(validateP4)
}

proc getP4fileInfoField {p4info field } {
    
    if {[set fieldNum [lsearch -glob $p4info "$field=*"]] < 0} {
	return {}
    } else {
	set fieldPair [lindex $p4info $fieldNum]
	set fieldPair [split $fieldPair "="]
	set fieldVal [lindex $fieldPair 1]
	return $fieldVal
    }
}

proc getP4fileInfo {filename} {

    ##  Gets p4 info for a file, returns as a list of name=val elements

    if {!$::setupStatus(validateP4)} {return underClient=false}
    set p4clientRoot [file normalize $::p4info(clientRoot)]
    set normFilename [file normalize $filename]
    set rec {}
    if {[string first $p4clientRoot $normFilename] == 0} {
	lappend rec "underClient=true"
	##  File is known to be under the client root.
	set p4fstat [exec -ignorestderr p4 fstat $normFilename 2> /dev/null]
	if {[string length $p4fstat] == 0} {return {underClient=true}}
	foreach line [split $p4fstat "\n"] {
	    if [regexp {\.\.\.\s+(\S+)\s+(\S+)} $line dummy varName varVal] {
#		set ::p4FileInfo($varName) $varVal
		lappend rec "$varName=$varVal"
	    }
	}
	return $rec
    } else {return {underClient=false}}
}

proc refreshSourceFileInfo {name} {
    ##  Refreshes the p4 info label

    set fname .nb.srctab.f.cnv.win.$name
    set val [string trim [$fname.text get]]
    if [file exists $val] {
	set fgColor green

	set p4info [getP4fileInfo $val]
	set underClient [getP4fileInfoField $p4info "underClient"]
	set depotFile [getP4fileInfoField $p4info "depotFile"]
	set action [getP4fileInfoField $p4info "action"]
	if $underClient {
	    if {$depotFile == ""} {set p4tag "(P4)"} else {set p4tag "P4"}
	    append p4tag " $action"
	} else {
	    set p4tag ""
	}
	.nb.srctab.f.cnv.win.$name.p4 config -text "$p4tag"
    } else {
	set fgColor red
	.nb.srctab.f.cnv.win.$name.p4 config -text ""
	set ::setupStatus(processSource) 0
	lappend ::setupStatusInfo(processSource) "missing_${name}_File"
    }

    .nb.srctab.f.cnv.win.$name.text config -fg $fgColor
}

proc p4SourceFile {cmd name}  {

    #  Perform a p4 command on a given source file.
    set fname .nb.srctab.f.cnv.win.$name
    set val [string trim [$fname.text get]]
    set p4Cmd "p4 $cmd $val"
    set output [exec {*}$p4Cmd]
    logMsg "$output\n"
    refreshSourceFileInfo $name

}


proc processSourceFile {name} {

    global $name


    set fname .nb.srctab.f.cnv.win.$name
    if {![winfo exists $fname]} {
	frame $fname
	pack [label $fname.label -text "$name:" -width 15 -justify right -font MyDefaultFont] -side left
	pack [label $fname.p4 -text "" -width 5 -font MyDefaultFont] -side left
	pack [entry $fname.text -width 100 -font MyDefaultFont] -side left
	pack [button $fname.create -text "Create" -command "createSourceFile $name $fname.text" -font MyDefaultFont] -side left
	pack [button $fname.edit -text "Edit" -command "editSourceFile $fname.text" -font MyDefaultFont] -side left
	pack [button $fname.p4add -text "P4 Add" -command "p4SourceFile add $name" -font MyDefaultFont] -side left
	pack [button $fname.p4edit -text "P4 Edit" -command "p4SourceFile edit $name" -font MyDefaultFont] -side left
	pack [button $fname.p4submit -text "P4 Submit" -command "p4SourceFile submit $name" -font MyDefaultFont] -side left
	pack [button $fname.p4revert -text "P4 Revert" -command "p4SourceFile revert $name" -font MyDefaultFont] -side left
    }

    if {!$::setupStatus(validateP4)} {
	## Disable p4 buttons if p4 setup was not successful.
	$fname.p4add configure -state disabled
	$fname.p4edit configure -state disabled
	$fname.p4submit configure -state disabled
	$fname.p4revert configure -state disabled
    }

    if [info exists $name] {
	set file [set $name]
	$fname.text delete 0 end
	$fname.text insert end $file
	##  Check all source files to allow overall status to be defined.
	refreshSourceFileInfo $name
    } else {
	logMsg "Error:  sourceFile variable \"$name\" not defined\n"
	set ::setupStatus(processSource) 0
	lappend ::setupStatusInfo(processSource) "missing_${name}_Definition"
    }

    bind $fname.text  <KeyPress-Return> {
	## Return has been hit in a sourceFile text widget.  Grab the new value
	set textWidget %W
	##  Get the string from text widget
	set val [string trim [$textWidget get]]

	regexp {.nb.srctab.f.cnv.win.(\w+).text} $textWidget dummy varName
#	logMsg "Info:  Setting $varName to $val\n"
	set $varName $val
	# Check all source files to allow overall statius 
	checkSource
    }
    pack $fname -side top
}


proc processSource {} {
    ##  Deal with the common configuration files

    global configFile
    global equivFile

    logMsg "Info:  processSource\n"
    setSetupButtonColor processSource blue

    set ::setupStatus(processSource) 1
    set ::setupStatusInfo(processSource) ""

    foreach f $::sourceFileList {processSourceFile $f}

    if {$::setupStatus(processSource)} {
	.nb.setuptab.f.cnv.win.processSource.status configure -text "OK"
    } else {
	.nb.setuptab.f.cnv.win.processSource.status configure -text "Failed"
    }
    return $::setupStatus(processSource)
}

proc checkSource {} {
    ##  Check all source files.

    global configFile
    global equivFile

    set setupStatus(processSource) 0
    set setupStatusInfo(processSource) ""

    foreach f $::sourceFileList {
	refreshSourceFileInfo $f
    }
}

proc fixupPininfoHeader {hdr} {
    
    if {$hdr == "related_power_pin"} {
	return "related_power"
    } elseif {$hdr == "related_ground_pin"} {
	return "related_ground"
    } elseif {$hdr == "pin_type"} {
	return "type"
    } elseif {$hdr == "is_bus"} {
	return "isBus"
    } else {return $hdr}

}


proc readPininfo {} {
    global pininfoFile
    global pininfoData
    
    logMsg "Info:  readPininfo\n"
    setSetupButtonColor readPininfo blue
    set ::setupStatus(pinInfo) 1
    set ::setupStatusInfo(pinInfo) ""
    .nb.setuptab.f.cnv.win.readPininfo.status configure -text "OK"

    set hasIsBus 0
    set hasMsb 0
    set hasLsb 0
    set pi {}
    set IN [openFileReadFromVar ::pininfoFile 0]
    if {$IN != 0} {
	logMsg "Info:  Reading pinInfo file $::pininfoFile\n"
	while {[gets $IN line] >= 0} {
	    set line [regsub -all {\#.*} $line ""]
	    set line [string trim $line]
	    if {[llength $line] == 0} { continue }
	    lappend pi $line
	}
	close $IN
	##  pi is a list of all pininfo file lines, stripped of comments.
	##  line 0 is a header, regardless of type.  Line 1 is the first real data line.
	set line1 [lindex $pi 1]
	if {[string first "|" $line1] >= 0} {
	    ##  pininfo is the old, "|" delimited, fixed column style
	    set ::pininfoStyle 0
	    set ::pininfoFieldNum(name) 0
	    set ::pininfoFieldNum(direction) 1
	    set ::pininfoFieldNum(isBus) 2
	    set ::pininfoFieldNum(msb) 3
	    set ::pininfoFieldNum(lsb) 4
	    set ::pininfoFieldNum(type) 5
	    set ::pininfoFieldNum(related_power) 6
	    set ::pininfoFieldNum(related_ground) 7
	} elseif {[string first "," $line1] >= 0} {
	    ##  csv-style
	    set ::pininfoStyle 1
	    set hdr [split [lindex $pi 0] ","]
	    set i 0
	    foreach h $hdr {
		## There's some inconsistency in pininfo header names.  Reconcile.
		set hf [fixupPininfoHeader $h]
		set ::pininfoFieldNum($hf) $i
		incr i
		if {$hf == "isBus"} {set hasIsBus 1}
		if {$hf == "msb"} {set hasMsb 1}
		if {$hf == "lsb"} {set hasLsb 1}
	    }
	    if {!$hasIsBus} {
		##  csv header did not include isBus.  Add to the end.
		set ::pininfoFieldNum(isBus) $i
		incr i
	    }
	    if {!$hasMsb} {
		##  csv header did not include msb.  Add to the end.
		set ::pininfoFieldNum(msb) $i
		incr i
	    }
	    if {!$hasLsb} {
		##  csv header did not include lsb.  Add to the end.
		set ::pininfoFieldNum(lsb) $i
		incr i
	    }
	} else {
	}
	##  Throw away header.
	set pi [lreplace $pi 0 0]
	foreach line $pi {
	    if {$::pininfoStyle == 0} {
		set line1 [regsub -all {\|} $line " "]
		if {[llength $line1] == 8} {
		    set pinName [lindex $line1 0]
		    set ::pininfoData($pinName) $line1
#		    puts "Old pininfo line:  {$line1}"
		} else {
		    logMsg "Error:  Incorrect number of elements in pininfo line:\n\t\"$line\""
		}
	    } elseif {$::pininfoStyle == 1} {
		set line1 [regsub -all {,} $line " "]
		set nameField [pininfoField name]
		if {$nameField >= 0} {
		    set pinName [lindex $line1 $nameField]
		    set isBus 0
		    set msb "-"
		    set lsb "-"
		    if [regexp {[\[<](\d+):(\d+)[\]>]} $pinName dummy a b] {
			set msb [max $a $b]
			set lsb [min $a $b]
			set isBus 1
		    } elseif [regexp {[\[<](\d+)[\]>]} $pinName dummy a] {
			set msb a
			set lsb a
			set isBus 1
		    }
		    if (!$hasIsBus) {lappend line1 $isBus}
		    if (!$hasMsb) {lappend line1 $msb}
		    if (!$hasLsb) {lappend line1 $lsb}
		} else {
		    logMsg "Error: pininfo line does not include name:\n\t\"$line\""
		    continue
		}
		set ::pininfoData($pinName) $line1
#		puts "New pininfo line:  {$line1}"
	    } 
	    
	}
	
	##  Fix-up direction to a standard format
	set dirField [pininfoField direction]
	if {$dirField > 0} {
	    foreach pinname [array names ::pininfoData] {
		set p $::pininfoData($pinname)
		set d [lindex $p $dirField]
		set d [stdDir $d]
		set ::pininfoData($pinname) [lreplace $::pininfoData($pinname) $dirField $dirField $d]
	    }
	}

	set ::setupStatus(readPininfo) 1
	return 1
    } else {
	.nb.setuptab.f.cnv.win.readPininfo.status configure -text "Failed"
	set ::setupStatus(readPininfo) 0
	if [info exists ::pininfoFile] {
	    set ::setupStatusInfo(pinInfo) "Pininfo file \"$::pininfoFile\" not readable"
	} else {
	    set ::setupStatusInfo(pinInfo) "No variable \"pininfoFile\""
	}
	return 0
    }
}

proc readEquiv {} {
    ##  Reads the equiv file to get list of black-box cells
    global equivFile
    global bboxCells
    
    logMsg "Info:  readEquiv\n"
    setSetupButtonColor readEquiv blue
    set status 1
    .nb.setuptab.f.cnv.win.readEquiv.status configure -text "OK"
    set bboxCells {}

    if {([info exists ::ntEnableCCSN_etm])&&($::ntEnableCCSN_etm == "true")} {
	set bboxCells ""
	set ::setupStatus(readEquiv) 1
	return 1
} else {
    set IN [openFileReadFromVar ::equivFile 0]
    if {$IN != 0} {
	logMsg "Info:  Reading equiv file $::equivFile\n"
	if {[gets $IN line] >= 0} {
	    set bboxCells $line
	}
	close $IN
	set ::setupStatus(readEquiv) 1
	return 1
    } else {
	.nb.setuptab.f.cnv.win.readEquiv.status configure -text "Failed"
	set ::setupStatus(readEquiv) 0
	if [info exists ::equivFile] {
	    set ::setupStatusInfo(readEquiv) "Equiv file \"$::equivFile\" not readable"
	} else {
	    set ::setupStatusInfo(readEquiv) "No variable \"equivFile\""
	}
	return 0
    }
    }
}

proc pininfoField {field} {
    ##  Define the field numbers in the pininfo file
    
    if [info exists ::pininfoFieldNum($field)] {return $::pininfoFieldNum($field)} else {return -1}
}

proc createSimpleSourceFile {filename}  {
    ##  Creates a source file, opening, returning file pointer. 0 if a problem occurred.

    if [file exists $filename] {file delete -force $filename}
    if {![file exists $filename]} {
	logMsg "Info:  Creating $filename\n"
	return [open $filename w]
    } else {
	logMsg "Error:  Could not create $filename"
	return 0
    }
}

proc isBus {pin} {
    global pininfoData

    return [lindex $pininfoData($pin) [pininfoField isBus]]
}

proc isInput {pin} {
    global pininfoData

    if {[lindex $pininfoData($pin) [pininfoField direction]] == "input"} {return 1} else {return 0}
}

proc isOutput {pin} {
    global pininfoData

    if {[lindex $pininfoData($pin) [pininfoField direction]] == "output"} {return 1} else {return 0}
}

proc isInout {pin} {
    global pininfoData

    if {[lindex $pininfoData($pin) [pininfoField direction]] == "inout"} {return 1} else {return 0}
}

proc isClock {pin} {
    global clkPins

    if [info exists clkPins] {if {[lsearch -exact $clkPins $pin] < 0} {return 0} else {return 1}} else {return 0}
}

proc isPower {pin} {
    global supplyPins

    if [info exists supplyPins] {if {[lsearch -exact $supplyPins $pin] >= 0} {return 1} else {return 0}} else {return 0}
}

proc isGround {pin} {
    global groundPins

    if [info exists groundPins] {if {[lsearch -exact $groundPins $pin] >= 0} {return 1} else {return 0}} else {return 0}
}

proc getRelatedPower {pin} {

    global pininfoData

    return [lindex $pininfoData($pin) [pininfoField related_power]]

}

proc createFileFromTemplate {fileName fileVar} {
    ##  Attempts to create a file from a template, creating an empty file if template variable or template file does not exist
 
    if {[info exists "${fileVar}Template"]} {
	set templateFile [set ${fileVar}Template]
	if {[file exists $templateFile]} { 
	    logMsg "Info:  Creating $fileName from template $templateFile\n"
	    file copy -force [getRealFile $templateFile] $fileName 
	} else {
	    logMsg "Info:  Creating empty $fileName;  template $templateFile does not exist\n"
	    set fp [open $fileName w]
	    close $fp
	}
    } else {
	logMsg "Warning:  $fileName not created;  template variable ${fileVar}Template does not exist\n"
	#	set fp [open $fileName w]
	#	close $fp
    }
}

proc createLinkSourceFile {fileName fileVar} {
    ##  Creates a file that's typically a link to a user-specified source file.

    global $fileVar

    if [file exists $fileName] {file delete -force $fileName}

    if {![info exists $fileVar]} {
	logMsg "Debug: $fileVar doesn't exist"
	##  File variable does not exist; user has not specified the file.  Create from template
	createFileFromTemplate $fileName $fileVar
    } else {
	set sourceFile [file normalize [set $fileVar]]
	if [file exists $sourceFile] {
	    ##  Source exists, create the link
	    logMsg "Info:  Linking $fileName from $sourceFile\n"
	    if [file exists $sourceFile] {
		file link -symbolic $fileName $sourceFile
	    } else {
		logMsg "Error:  $sourceFile does not exist\n"
	    }
	} else {
	    ##  Source is specified, but does not exist.  Attempt to create, then link
	    createFileFromTemplate $sourceFile $fileVar
	    file link -symbolic $fileName $sourceFile
	}
    }
}

proc getPvtField {pvtAttrs fieldName} {

    foreach attrPair [split $pvtAttrs ","] {
	if {[lindex $attrPair 0] == $fieldName} {return [lindex $attrPair 1]}
    }
    return ""
}

proc parseInstance {instLine} {

    ##  Get rid of line continuations
    set instLine [regsub -all {\n\+} $instLine " "]
    ##  make sure all params are "name=val" with no spaces.
    set instLine [regsub -all {\s+=\s+} $instLine "="]
    set n [llength $instLine]
    set ports ""
    set params ""
    set inst [lindex $instLine 0]
    set cell ""
    for {set i 1} {$i < $n} {incr i} {
	set tok [lindex $instLine $i]
	if {[string first "=" $tok] == -1} {lappend ports $tok} else {lappend params $tok}
    }

    ##  cellname should be last element in "ports".
    set cell [lindex $ports end]
    set ports [lreplace $ports end end]
    return [list $inst $cell $ports $params]

}

proc savePortOrder {subcktLine} {

    ##  Get rid of line continuations
    set subcktLine [regsub -all {\n\+} $subcktLine " "]
    ##  make sure all params are "name=val" with no spaces.
    set subcktLine [regsub -all {\s+=\s+} $subcktLine "="]
    set n [llength $subcktLine]
    set ports ""
    set cell [lindex $subcktLine 1]
    for {set i 2} {$i < $n} {incr i} {
	##  Skip any params
	set tok [lindex $subcktLine $i]
	if {[string first "=" $tok] == -1} {lappend ports $tok}
    }
    set ::portOrder($cell) $ports

}

proc findCellNameInInstance {line} {
    ## Find the name of a cell from an instance line

    ##  Remove all ling continuations
    set bfr [regsub -all {\n\+} $line " "]
    ##  Make sure all parameter definitions are packed.
    set bfr [regsub -all {\s*=\s*} $bfr "="]
    set last ""
    foreach tok $bfr {
	if {[string first "=" $tok] != -1} { 
	    ## Found a parameter.  cellName is previous token
	    return $last 
	}
	set last $tok
    }
    return $last
}

proc createPrunedSubNetlistsLine {line PRUNED SUB} {
    
    ##  process the buffered line

    ##  Make sure all arg spec's have no embedded spaces.
    if [regexp {^\s*\*} $line] {
	##  A simple comment line. print and ignore
	if $::notPruning {puts $PRUNED $line}
	return
    }
    set line [regsub {\s+=\s+} $line "="]
    set id [string tolower [lindex $line 0]]
    if {$id == ".subckt"} {
	##  Save the port order
	savePortOrder $line
	set subcktName [lindex $line 1]
	if {[lsearch -exact $::bboxCells $subcktName] >= 0} {
	    ##  Build list of ports
	    ##  Get rid of contunuation characters.  Newlines are OK.
	    set portList [regsub -all {[\+]} $line " "]
	    ##  Loop through list of tokens after the ".subckt" and subckt name.  Skip any parameters.
	    foreach tok [lreplace $portList 0 1] {if {[string first "=" $tok] == -1} {lappend ports $tok}}
	    set ::bboxPortorder($subcktName) $ports
	    set ::bboxScb($subcktName) 1
	    set ::notPruning 0
	    ##  Note:  NT seems to like having at least on blank line between subckts.
	    puts $SUB "\n$line"
	    puts $SUB ".ends $subcktName"
	} else { if $::notPruning {puts $PRUNED $line}}
    } elseif {$id == ".ends"} {
	if $::notPruning {puts $PRUNED $line} else {set ::notPruning 1}
    } elseif {[string index $id 0] == "x"} {
#	puts [parseInstance $line]
	## A subckt instance. Just pass along
	if $::notPruning {
	    puts $PRUNED $line
	    ##  Make list of cells used in the schematic netlist
	    set ::cellsUsed([findCellNameInInstance $line]) 1
	}
    } else {if $::notPruning {puts $PRUNED $line}}
}

proc readSchInst {netIn netOut} {

    if {![info exists ::flattenScript]} {
	##  flattener script not specified.  See if it's where this script is
	set maybeScript "$::scriptPath/alphaFlattenSpiceInstances.pl"
	if [file exists $maybeScript] {
	    set ::flattenScript $maybeScript
	} else {
	    logMsg "Warning:  No flatten script found. Skipping validation of instance pin order\n"
	    return
	}
    }
    logMsg "Info:  Flattening instance in $netIn, writing $netOut\n"
    deleteFiles $netOut
    exec $::flattenScript $netIn -hierSep $::hierSep -topCell $::cellName -output $netOut
    if [file exists $netOut] {
#	puts "Reading $netOut"
	set IN [open $netOut r]
	while {[gets $IN line] >= 0} {
	    ##  Need to know:  The flattener used here produces a netlist with no continuations.
	    set line [string tolower $line]
	    if {[string index $line 0] == "x"} {
		set instName [lindex $line 0]
		set cellName [lindex $line end]
		set ports [lrange $line 1 end-1]
		foreach bbox $::bboxCells {
		    if {[string tolower $bbox] == $cellName} {
			## Saving connects for schematic instance
			set ::schInstPorts($instName) $ports
		    }
		}
	    }
	}
	close $IN

    } else {
	logMsg "Warning:  Flatten apparently failed; $netOut not created.  Port order will not be checked.\n"
    }

}


proc createPrunedSubNetlists {netlist netlistDir mapBrackets bktMap} {


    logMsg "Info:  Pruning $netlist\n"
    set toks [file split $netlist]
    set root [lindex $toks end]
    set prunedNetlist $netlistDir/$root.pruned
    set subcktNetlist $netlistDir/netlist_sub.spf

    set IN [open $netlist r]
    set PRUNED [open $prunedNetlist w]
    set SUB [open $subcktNetlist w]
    puts $PRUNED "**  Pruned spice netlist generated from $netlist"
    puts $PRUNED "**  Black Boxes:"
    puts $SUB "**  Blackbox subckt header netlist generated from $netlist"
    puts $SUB "**  Black Boxes:"
    ## Create a bbox array
    foreach bbox $::bboxCells {
	set ::bboxScb($bbox) 0
	puts $PRUNED "**\t$bbox"
	puts $SUB "**\t$bbox"
    }

    set state 0
    set bfr ""
    set ::notPruning 1
    while {[gets $IN line] >= 0} {
	set line [string trimleft $line]
	if $mapBrackets {set line [string map $bktMap $line]}
	if {[string index $line 0] == "+"} {
	    ## Continuation line
#	    append bfr " [string range $line 1 end]"
	    append bfr "\n$line"
	} else {
	    ##  New line
	    createPrunedSubNetlistsLine $bfr $PRUNED $SUB
	    set bfr "$line"
	}
    }
    createPrunedSubNetlistsLine $line $PRUNED $SUB
    
    close $IN
    close $PRUNED
    close $SUB

    if [file exists $prunedNetlist] {
	createSimpleLink "$netlistDir/netlist_pre.spf" "$root.pruned"
	##  Flattened netlist (instances only) used to check the port connectivity of bbox instances
	readSchInst "$netlistDir/$root.pruned" "$netlistDir/$root.inst.flat" 

    } else {
	logMsg "Error:  $prunedNetlist does not exist\n"
    }

    return
    ## Skipping the netlist flattening part; flattener doesn't maintain instance name integrity
    set flattenIgnoreFile "netlist/flattenIgnore.tmp"
    set IGN [open $flattenIgnoreFile w]
    foreach cellName [array names ::cellsUsed] {
	##  Any cell not defined in this netlist will not have a defined port order.
	if {![info exists ::portOrder($cellName)]} {puts $IGN "$cellName"}
    }
    ##  Add the list of bbox cells
    foreach bbox $::bboxCells {puts $IGN $bbox}
    close $IGN
    set flatNetlist "$prunedNetlist.flat"
    if [writeFlattenedNetlist "./netlist" "$root.pruned" "$root.pruned.flat" "flattenIgnore.tmp"] {
	logMsg "Info:  Building instance table from flat schematic netlist\n"
	readSpiceNetlist "./netlist/$root.pruned.flat" getSchInstances
    }
    
}

proc getSchInstances {bfr} {
    ##  Building a list of the subckt instances in the flat schematic netlist, to compare to the extracted netlist(s)
    
    set id [string tolower [string range $bfr 0 0]]
    if {$id == "x"} {
	set instData [parseInstance $bfr]
	set instName [lindex $instData 0]
	set instCell [lindex $instData 1]
	set instPorts [lindex $instData 2]
	set ::schInstCell($instName) $instCell
	set ::schInstPorts($instName) $instPorts
    }
}

proc readSpiceNetlist {netlist lineFunction} {

    if {![file readable $netlist]} {
	logMsg:  "Error:  Cannot open $netlist for read"
	return 0
    }
    set IN [open "$netlist" r]
    set bfr ""
    while {[gets $IN line] >= 0} {
	set line [string trimleft $line]
	if {[string index $line 0] == "+"} {append bfr "$line"} else {
	    $lineFunction $bfr
	    set bfr $line
	}
    }
    $lineFunction $bfr
    close $IN
}

proc writeFlattenedNetlist {dir hierNetlist flatNetlist flattenIgnoreFile} {

    set shellScript "flatten.tmp.csh"
    set SCR [open $shellScript w]
    puts $SCR "\#!/bin/csh"
    puts $SCR "cd $dir"
    puts $SCR "module unload msip_shell_sch_utils"
    puts $SCR "module load msip_shell_sch_utils"
    puts $SCR "rm -f msip_schFlattenSpiceNetlist.log"
    puts $SCR "rm -f $flatNetlist"
    puts $SCR "msip_schFlattenSpiceNetlist $hierNetlist $::cellName $flatNetlist -i flattenIgnore.tmp"
    puts $SCR "exit"
    close $SCR
    if [file exists $flatNetlist] {file delete $flatNetlist}
    file attributes $shellScript -permissions "+x"
    exec $shellScript
    if {![file exists "./netlist/$flatNetlist"]} {
	logMsg  "Error:  Netlist flatten failed\n"
	return 0
    } else {
	logMsg  "Info:  $flatNetlist created\n"
	return 1
    }
    

}


######################################################################################################################################################### part 2 sowmya
proc processSubckts {}  {

    logMsg "Info:  processSubckts\n"
    setSetupButtonColor processSubckts blue

    set subcktDir "./subckts"
    createDir $subcktDir

    ##  Handle stdcell libs

    set lcScript "lc.tmp.tcl"
    set shellScript "lc.tmp.csh"
    set SCR [open $shellScript w]
    puts $SCR "\#!/bin/csh"
    puts $SCR "module unload lc"
    ## lc_shell uses default version unless otherwise directed
    if [info exists ::lcVersion] {set lcModule $::lcVersion} else {set lcModule "lc"}
    puts $SCR "module load lc/2020.09-SP5"
    #puts $SCR "module load $lcModule"
    puts $SCR "lc_shell -f $lcScript"
    puts $SCR "exit"
    close $SCR
    file attributes $shellScript -permissions "+x"

    if {![info exists ::libSuffix]} {set ::libSuffix ""}

    if [info exists ::stdCellLibList] {
	##  Only use a single pvt to speed up the proceedings.
	set myCorners [lindex $::pvtCorners 0]
	foreach pvt $myCorners {
	    ##  create a lc_shell script for each pvt
	    set n 0
	    set SCR [open $lcScript w]
	    ##  Get the pvt name for the related stdcell lib
	    set scPvt [getPvtField $::cornerData($pvt) scPvt]
	    if {$scPvt == ""} {set scPvt $pvt}
	    foreach lib $::stdCellLibList {
		set dbFile "${lib}_$scPvt.db"
		if [file exists $dbFile] {
		    logMsg "Info:  Reading $dbFile for names of stdCells\n"
		    puts $SCR "read_db $dbFile"
		    puts $SCR "set libName \[get_object_name \[index_collection \[get_libs\] $n\]\]"
		    puts $SCR {report_lib $libName}
		    incr n
		} else {
		    logMsg  "Warning: $dbFile missing\n"
		}
	    }
	    puts $SCR "quit"
	    close $SCR
	    set output [split [exec "./$shellScript"] "\n"]
	    set state 0
	    foreach line $output {
		set t0 [lindex $line 0]
		if {$state == 0} {
		    ##  Pick up name of current 
		    if {$t0 == "read_db"} {
			set dbFile [lindex $line 1]
#			puts "$dbFile"
		    }
		    if {$t0 == "Cell"} {
			set state 1
		    }
		} elseif {$state == 1} {
		    ## Just wait one line to get past the "-------..."
		    set state 2
		} elseif {$state == 2} {
		    if {$t0 == "1"} {set state 0} else {
			regexp "^(.*)_$pvt\.db" $dbFile dummy dbFileRoot
#			puts "$dbFileRoot:  $t0"
			lappend ::StdCellDbCells($dbFileRoot) $t0
		    }
		}
	    }
	}
    } else {
	logMsg "Warning: No StdCell libraries specified\n"
    }

#    foreach dbFile [array names ::StdCellDbCells] {
#	puts "$dbFile:"
#	foreach cell $::StdCellDbCells($dbFile) {puts "\t$cell"}
#    }

    if [info exists ::skipLibCellList] {
#	puts "skipLibCellList = \"$::skipLibCellList\""
	foreach cell $::skipLibCellList {
#	    puts "\t$cell"
	    set skipLib($cell) 1
	}
    }

    if {![info exists ::libPath]} {logMsg "Warning:  libPath is undefined\n"}
    if {![info exists ::pocvsidefilePath]} {logMsg "Warning:  pocvsidefilePath is undefined\n"}

    set status 1
    foreach bbox $::bboxCells {
	if [info exists skipLib($bbox)] { 
	    logMsg "Info: Skipping libs for $bbox\n"
	    continue 
	}

	##  See if this is a standard cell
	set isStdCell 0
	foreach dbFile [array names ::StdCellDbCells] {
	    if {[lsearch -exact $::StdCellDbCells($dbFile) $bbox] >= 0} {
		set ::stdCellDbArray($dbFile) 1
		set isStdCell 1
		logMsg "Info:  Bbox $bbox found in StdCell lib $dbFile   and so isstdcell turned true\n"
		break
	    }
	}

	if {!$isStdCell} {
	    set ::libsOK($bbox) 1
	    foreach pvt $::pvtCorners {
		set lib "${bbox}_${::metalStack}_${pvt}${::libSuffix}.lib"
		set dstLib "$subcktDir/${bbox}_${::metalStack}_${pvt}.lib"
		set srcLib [findLib $lib]
		if {$srcLib != ""} {
		    createSimpleLink $dstLib $srcLib
		    logMsg "Info : lib FOUND for $bbox $pvt  and is $dstLib --> $srcLib\n"
		} else {
		    ##  Try looking for lib without metalstack
		    set lib "${bbox}_${pvt}${::libSuffix}.lib"
		    set srcLib [findLib $lib]
		    if {$srcLib != ""} {
			createSimpleLink $dstLib $srcLib
			logMsg "Warning:  Found only non-metalStack-specific lib for ${bbox}_$pvt\n"
		    } else {
			logMsg "Error:  Could not find lib for $bbox $pvt\n"
			## Quick hack to id cases where libs are missing.
			set ::libsOK($bbox) 0
			lappend ::setupStatusInfo(processSubckts) "libNotFound$bbox"
			set status 0
		    }
		}
	    }

	}
    }

    set ::setupStatus(processSubckts) $status
    if $status {
	.nb.setuptab.f.cnv.win.processSubckts.status configure -text "OK"

    } else {
	.nb.setuptab.f.cnv.win.processSubckts.status configure -text "Failed"
    }
    return $status
}


######################################################################################################################################################### part 3 sowmya
proc processPOCVSubckts {}  {
if {([info exists ::ntEnablePOCV_etm])&&($::ntEnablePOCV_etm == "true")} { 
    logMsg "Info:  processPOCVSubckts\n"
    setSetupButtonColor processPOCVSubckts blue

    set subcktDir "./subckts"
    createDir $subcktDir
    set pocvDir "./subckts/pocv"
    createDir $pocvDir

    ##  Handle stdcell libs

    set lcScript "lc.tmp.tcl"
    set shellScript "lc.tmp.csh"
    set SCR [open $shellScript w]
    puts $SCR "\#!/bin/csh"
    puts $SCR "module unload lc"
    ## lc_shell uses default version unless otherwise directed
    if [info exists ::lcVersion] {set lcModule $::lcVersion} else {set lcModule "lc"}
    puts $SCR "module load lc/2020.09-SP5"
#    puts $SCR "module load $lcModule"
    puts $SCR "lc_shell -f $lcScript"
    puts $SCR "exit"
    close $SCR
    file attributes $shellScript -permissions "+x"

    if {![info exists ::libSuffix]} {set ::libSuffix ""}

    if [info exists ::stdCellLibList] {
	##  Only use a single pvt to speed up the proceedings.
	set myCorners [lindex $::pvtCorners 0]
	foreach pvt $myCorners {
	    ##  create a lc_shell script for each pvt
	    set n 0
	    set SCR [open $lcScript w]
	    ##  Get the pvt name for the related stdcell lib
	    set Pvt [getPvtField $::cornerData($pvt) Pvt]
	    if {$Pvt == ""} {set Pvt $pvt}
	    foreach lib $::stdCellLibList {
		set dbFile "${lib}_$Pvt.db"
		if [file exists $dbFile] {
		    logMsg "Info:  Reading $dbFile for names of stdCells\n"
		    puts $SCR "read_db $dbFile"
		    puts $SCR "set libName \[get_object_name \[index_collection \[get_libs\] $n\]\]"
		    puts $SCR {report_lib $libName}
		    incr n
		} else {
		    logMsg  "Warning: $dbFile missing\n"
		}
	    }
	    puts $SCR "quit"
	    close $SCR
	    set output [split [exec "./$shellScript"] "\n"]
	    set state 0
	    foreach line $output {
		set t0 [lindex $line 0]
		if {$state == 0} {
		    ##  Pick up name of current 
		    if {$t0 == "read_db"} {
			set dbFile [lindex $line 1]
#			puts "$dbFile"
		    }
		    if {$t0 == "Cell"} {
			set state 1
		    }
		} elseif {$state == 1} {
		    ## Just wait one line to get past the "-------..."
		    set state 2
		} elseif {$state == 2} {
		    if {$t0 == "1"} {set state 0} else {
			regexp "^(.*)_$pvt\.db" $dbFile dummy dbFileRoot
#			puts "$dbFileRoot:  $t0"
			lappend ::StdCellDbCells($dbFileRoot) $t0
		    }
		}
	    }
	}
    } else {
	logMsg "Warning: No StdCell libraries specified\n"
    }

#    foreach dbFile [array names ::StdCellDbCells] {
#	puts "$dbFile:"
#	foreach cell $::StdCellDbCells($dbFile) {puts "\t$cell"}
#    }

    if [info exists ::skipLibCellList] {
#	puts "skipLibCellList = \"$::skipLibCellList\""
	foreach cell $::skipLibCellList {
#	    puts "\t$cell"
	    set skipLib($cell) 1
	}
    }

    if {![info exists ::pocvsidefilePath]} {logMsg "Warning:  pocvsidefilePath is NOT defined\n"}

    set status 1
    foreach bbox $::bboxCells {
	if [info exists skipLib($bbox)] { 
	    logMsg "Info: Skipping libs for $bbox\n"
	    continue 
	}

	##  See if this is a standard cell
	set isStdCell 0
	foreach dbFile [array names ::StdCellDbCells] {
	    if {[lsearch -exact $::StdCellDbCells($dbFile) $bbox] >= 0} {
		set ::stdCellDbArray($dbFile) 1
		set isStdCell 1
		logMsg "Info:  Bbox $bbox found in StdCell lib $dbFile\n"
		break
	    }
	}

	if {!$isStdCell} {
	    set ::pocvsidefilesOK($bbox) 1
            foreach pvt $::pvtCorners {
		set pocvsidefile "${bbox}_${::metalStack}_${pvt}.pocv"
		set dstpocvsidefile "$pocvDir/${bbox}_${::metalStack}_${pvt}.pocv"
		set srcpocvsidefile [findpocvsidefile $pocvsidefile]
		if {$srcpocvsidefile != ""} {
		    createSimpleLink $dstpocvsidefile $srcpocvsidefile
		    #logMsg "Info : pocvsidefile FOUND for $bbox $pvt and is $dstpocvsidefile --> $srcpocvsidefile\n"
		} else {
		    ##  Try looking for pocvsidefile without metalstack
		    set pocvsidefile "${bbox}_${pvt}.pocv"
		    set srcpocvsidefile [findpocvsidefile $pocvsidefile]
		    if {$srcpocvsidefile != ""} {
			createSimpleLink $dstpocvsidefile $srcpocvsidefile
			logMsg "Warning:  Found only non-metalStack-specific bbox pocvsidefile for ${bbox}_$pvt ; \n"
		    } else {
			logMsg "Error:  Could not find pocv side file for $bbox $pvt\n"
			## Quick hack to id cases where bbox POCV SIDEFILES are missing.
			set ::pocvsidefilesOK($bbox) 0
			lappend ::setupStatusInfo(processPOCVSubckts) "pocv_sidefile Not Found for $bbox ; "
			set status 0
		    }
		}
	    }

	} else {}
    }

    set ::setupStatus(processPOCVSubckts) $status
    if $status {
	.nb.setuptab.f.cnv.win.processPOCVSubckts.status configure -text "OK"

    } else {
	.nb.setuptab.f.cnv.win.processPOCVSubckts.status configure -text "Failed"
    }
    return $status
    
 } else { 
 set status 1
 lappend ::setupStatusInfo(processPOCVSubckts) "bbox pocvsidefile checks NOT done"
 set ::setupStatus(processPOCVSubckts) $status
    if $status {
	.nb.setuptab.f.cnv.win.processPOCVSubckts.status configure -text "OK as its NON-POCV flow"

    } else {
	.nb.setuptab.f.cnv.win.processPOCVSubckts.status configure -text "Failed for non-pocv flow"
    }
    return $status
 }
 }

######################################################################################################################################################### part 4 sowmya

proc findLib {lib} {
    if [info exists ::libPath] {
	foreach dir $::libPath {
	    set srcLib "$dir/$lib"
	    logMsg "dir/lib is  $dir/$lib"
	    if [file exists $srcLib] { return $srcLib }
	}
    }
    return ""
}


proc findpocvsidefile {pocvsidefile} {
    if [info exists ::pocvsidefilePath] {
	foreach dir $::pocvsidefilePath {
	    set srcpocvsidefile "$dir/$pocvsidefile"
	    #puts "dir/pocvsidefile ---> $dir/$pocvsidefile"
	    if [file exists $srcpocvsidefile] { return $srcpocvsidefile }
	}
    }
    return ""
}

proc createSimpleLink {linkName fileName} {

    set linkName [file normalize $linkName]
#    puts "$linkName $fileName"
    if [file exists $linkName] {file delete -force $linkName}
    set linkDirName [file dirname $linkName]
    set fileDirName [file dirname $fileName]
    if {$fileDirName == "."} {set absFileName "$linkDirName/$fileName"} else {set absFileName [file normalize $fileName]}

    if [file exists $absFileName] {
	file link -symbolic $linkName $fileName
    } else {
	logMsg "Error:  $fileName missing\n"
    }
}

proc createRebracketedNetlist {netlist bktNetlist bktMap} {
    ##  Makes copy of netlist with brackets remapped.

    logMsg "Info:  Remapping brackets on $netlist\n"
    set IN [open $netlist r]
    set OUT [open $bktNetlist w]
    while {[gets $IN line] >= 0} {
	set line [string map $bktMap $line]
	puts $OUT $line
    }
    close $IN
    close $OUT
}

proc checkInstPorts {instName ports} {

    set bfr "Checking ports of $instName\n"
    set instName [string tolower $instName]
    set status 1
    if [info exists ::schInstPorts] {
	foreach schInst [array names ::schInstPorts] {
	    if {($schInst == $instName) || ("x$schInst" == $instName)} {
		set schPorts $::schInstPorts($schInst)
		set nExt [llength $ports]
		set nSch [llength $schPorts]
		if {$nExt == $nSch} {
		    for {set i 0} {$i<$nExt} {incr i} {
			set e [lindex $ports $i]
			set s [lindex $schPorts $i]
			if [info exists ::netFromSubnet($e)] {
			    set e $::netFromSubnet($e)
			    set noConn 0
			} else {
			    ##  Net not part of a submit.  This is likely an indication of a no-connect, which can probably be ignored.
			    set noConn 1
			}
			set e [string tolower $e]
			set tag ""
			if {($s != $e) && !$noConn} {
			    set status 0
			    set tag "!"
			}
			append bfr "$tag\t$s : $e$tag\n"
		    }
		} else {
		    append bfr "Port number mismatch:\n"
		    append bfr "Sch: $schPorts\n"
		    append bfr "Ext: $ports\n"
		    set status 0
		}
	    }
	}
    } else {
	puts $::portCheckLog "Warning:  Cannot find schematic ports for instance \"$instName\". Skipping port check for this instance"
	return -1
    }
    if $status {
	puts $::portCheckLog "Info: Ports for instance \"$instName\" match"
    } else {
	puts $::portCheckLog "Error: Ports for instance \"$instName\" mismatch:"
	puts $::portCheckLog $bfr
    }
    return $status

}


proc checkExtractedNetlistPortsLine {line} {
    

    set id [string tolower [lindex $line 0]]
    if {$id == ".subckt"} {
	##   Process a subcircuit
	set subcktCell [lindex $line 1]
	set ports ""
	foreach tok [lreplace $line 0 1] {if {[string first "=" $tok] == -1} {lappend ports $tok}}
	if [info exists ::portOrder($subcktCell)] {
	    set refPorts $::portOrder($subcktCell)
	    set nRef [llength $refPorts]
	    set nPorts [llength $ports]
	    if {$nPorts == $nRef} {
		set bfr ""
		set mismatch 0
		for {set i 0} {$i < $nRef} {incr i} {
		    set p [lindex $ports $i]
		    set r [lindex $refPorts $i]
		    if {$p != $r} {set mismatch 1}
		    append bfr "\t$r\t$p\n"
		}
		if $mismatch {
		    puts $::portCheckLog "Error:  Port mismatch for $subcktCell:"
		    puts $::portCheckLog $bfr
		    set ::portCheckStatus 0
		} else {puts $::portCheckLog "Info:  $subcktCell ports match\n"}
	    } else {
		puts $::portCheckLog "Error:  Port number mismatch for \"$subcktCell\";  $nPorts != $nRef"
		set ::portCheckStatus 0
	    }
	} else {
	    puts $::portCheckLog "Warning: Undefined port order for  \"$subcktCell\""
	    set ::portCheckStatus 0
	}
	
    } elseif {[string index $id 0] == "x"} {
	##   Process an instance
#	puts [parseInstance $line]
	set ports ""
	## Inst name unaltered
	set instName0 [lindex $line 0]
	##  Inst name stripping first character
	set instName [string range instName0 1 end]
	foreach tok [lreplace $line 0 0] {
	    if {[string first "=" $tok] == -1} {lappend ports $tok}
	}
	set cellName [lindex $ports end]
	set ports [lreplace $ports end end]
	if [info exists ::portOrder($cellName)] {
	    set refPorts $::portOrder($cellName)
	    set nRef [llength $refPorts]
	    set nPorts [llength $ports]
	    ##  Dump ports, mapped back to simple netnames
	    foreach p $ports {
		if [info exists ::netFromSubnet($p)] {set p $::netFromSubnet($p)}
		lappend schPorts $p
	    }
	    ##  Check the instance connections against the schematic
	    set status [checkInstPorts $instName0 $ports]
	    set ::portCheckStatus [expr $::portCheckStatus && $status]
#	    puts $::portCheckLog "Info: $id $cellName ports:  {$schPorts}"
	    
###    BEGIN Removing old instance pin check

	    if 0 {
		if {$nPorts == $nRef} {
		    set bfr ""
		    set mismatch 0
		    for {set i 0} {$i < $nRef} {incr i} {
			set p [lindex $ports $i]
			set r [lindex $refPorts $i]
			
			#  Strip off the extra "X" at t he beginning
			set patt "^${instName}(\[:_\])(\\S+)"
			if [regexp $patt $p dummy sep inferredPin] {
			    ##  Pattern matches, see if inferred pin name matches
			    if {$inferredPin != $r} {
				set mismatch 1
				append bfr "\t$r\t$inferredPin <<< \n"
			    }
			} else {
			    ##  
			    if {$p == $r} {
				##  Exact match.  Typically occurs for power/ground pins
				if { ![isPower $p] && ![isGround $p] } {
				    puts $::portCheckLog "Warning:  Cannot determine pin match for $cellName pin $r connected to $p\n"
				    set ::portCheckStatus 0
				    append bfr "\t$r\t$p  <<<\n"
				    set mismatch 1
				} else {
				    ##  simple power/ground connection
				}
			    } else {
				puts $::portCheckLog "Warning:  Cannot determine pin match for $cellName pin $r connected to $p"
				set ::portCheckStatus 0
				append bfr "\t$r\t$p  <<<\n"
				set mismatch 1
			    }
			}
		    }
		    append bfr "\n"
		    if $mismatch {
			puts $::portCheckLog "Error:  Port mismatch for $cellName:"
			puts $::portCheckLog $bfr
			set ::portCheckStatus 0
		    } else {puts $::portCheckLog "Info:  $cellName ports match"}
		} else {
		    puts $::portCheckLog "Error:  Port number mismatch for \"$cellName\" instance $instName;  $nPorts != $nRef"
		    set ::portCheckStatus 0
		}
	    }

###    END Removing old instance pin check

	}
    }
}

proc checkExtractedNetlistPortsLineNew {line} {
    ##  New extracted netlist port checker.  Checks connectivity of instances rather than inferring pin names.


    set id [string tolower [lindex $line 0]]
    if {$id == ".subckt"} {
	##   Process a subcircuit
	set subcktCell [lindex $line 1]
	set ports ""
	foreach tok [lreplace $line 0 1] {if {[string first "=" $tok] == -1} {lappend ports $tok}}
	if [info exists ::portOrder($subcktCell)] {
	    set refPorts $::portOrder($subcktCell)
	    set nRef [llength $refPorts]
	    set nPorts [llength $ports]
	    if {$nPorts == $nRef} {
		set bfr ""
		set mismatch 0
		for {set i 0} {$i < $nRef} {incr i} {
		    set p [lindex $ports $i]
		    set r [lindex $refPorts $i]
		    if {$p != $r} {set mismatch 1}
		    append bfr "\t$r\t$p\n"
		}
		if $mismatch {
		    logMsg "Error:  Port mismatch for $subcktCell:\n"
		    logMsg $bfr
		} else {logMsg "Info:  $subcktCell ports match\n"}
	    } else {
		logMsg "Error:  Port number mismatch for \"$subcktCell\";  $nPorts != $nRef\n"
	    }
	} else {
	    logMsg "Warning: Undefined port order for  \"$subcktCell\"\n"
	}
	
    } elseif {[string index $id 0] == "x"} {
	##   Process an instance
	set instData [parseInstance $line]
	set instName [lindex $instData 0]
	set instCell [lindex $instData 1]
	set instPorts [lindex $instData 2]
	if [info exists ::schInstCell($instName)] {
	    puts "Checking instance $instName"
	} else {
	    logMsg "Error:  Instance \"$instName\" missing from schematic netlist\n"
	}
    }
}


proc checkExtractedNetlistPorts {netlist} {
    ##  Checks the ports (subckt and instance) against the ports as defined in the spiceNetlist
    logMsg "Info:  Checking ports of $netlist\n"

    if {![file exists $netlist]} {
	logMsg "Error: checkExtractedNetlistPorts cannot open $netlist\n"
	return
    }

    set ::portCheckStatus 1
    set ::portCheckLog [open "portCheck.log" w]
    puts $::portCheckLog "Checking $netlist for port consistency\n"

    if [info exists ::netFromSubnet] {unset ::netFromSubnet}
    if [info exists ::allNets] {unset ::allNets}
    set IN [open $netlist r]
    set bfr ""
    while {[gets $IN line] >= 0} {
	set line [string trimleft $line]
	if {[string range $line 0 1] == "*|"} {
	    ##  Net connectivity information
	    if [regexp {\*\|NET\s+(\S+)} $line dmy netName] {
		set ::allNets($netName) 1
		#		puts "Found net $netName"
	    } elseif [regexp {\*\|I\s+\((\S+)\s+(\S+)\s+(\S+)} $line dmy subNet instName instPin] {
		#		puts "\t$netName: $subNet $instName $instPin"
		#		lappend netConnect($netName) "$subNet:$instName:$instPin"
		##  Create association fron subnet name to actual net
		set ::netFromSubnet($subNet) $netName
	    }
	} elseif {[string index $line 0] == "+"} {
	    ## Continuation line
	    append bfr " [string range $line 1 end]"
	} else {
	    ##  New line
	    checkExtractedNetlistPortsLine $bfr
	    set bfr "$line"
	}
    }
    checkExtractedNetlistPortsLine $bfr
    close $::portCheckLog
    if {!$::portCheckStatus} {logMsg "Warning:  Possible port match issue.  See portCheck.log\n"}
	
}


proc processNetlists {} {

    global pvtCorners
    global cornerData
    global extractNetlistDir
    global cellName
    global metalStack

    logMsg "Info:  processNetlists\n"
    setSetupButtonColor processNetlists blue

    set status 1
    set ::setupStatusInfo(processNetlists) ""

    set doneNetlists {}
    set netlistDir "./netlist"
    createDir $netlistDir
    
    ##  Dealing with bracket mapping
    set mapBrackets false
    set bktMap {}
    if [info exists ::forceBracket] {
	##  Brackets are to be coerced into a particular form
	logMsg "Info:  Mapping bracket pattern \"$::forceBracket\"\n"
	set mapBrackets true
	if {$::forceBracket == "square"} {
	    set bktMap { < [ > ] }
	} elseif {$::forceBracket == "pointy"} {
	    set bktMap { [ < ] > }
	} else {
	    set mapBrackets false
	    set status 0
	    lappend ::setupStatusInfo(processNetlists) "unrecognizedForceBracket"
	    logMsg "Error:  Unrecognized bracket pattern {$::forceBracket}"
	}
    }

    ##  work on spiceNetlist
    if [info exists ::spiceNetlist] {
	if [file exists $::spiceNetlist] {
	    createPrunedSubNetlists $::spiceNetlist $netlistDir $mapBrackets $bktMap
	} else {
	    ##  Netlist doesn't exist.
	    lappend ::setupStatusInfo(processNetlists) "spiceNetlistMissing"
	    logMsg "Error:  \"$::spiceNetlist does not exist.\"\n"
	    set status 0
	}
    } else {
	logMsg "Error:  spiceNetlist is undefined\"\n"	
	lappend ::setupStatusInfo(processNetlists) "spiceNetlistUndefined"
	set status 0
    }
    
    logMsg "Info:  Checking netlists:\n"
    if {$::phase == "pre"} {
	##  All work should be done by createPrunedNetlists --> netlists/netlist_pre.spf; just build pvt list
	foreach pvt $pvtCorners {
	    set netlist [file normalize $::spiceNetlist]
	    ##  Pluck out netlist file name.
	    set netlistRoot [lindex [file split $netlist] end]
	    set ::netlistList($pvt) $netlistRoot
	}
    } elseif {$::phase == "post"} {
	foreach pvt $pvtCorners {
	    set pvtAttrs $cornerData($pvt)
	    set xType [getPvtField $pvtAttrs xType]
	    set beol [getPvtField $pvtAttrs beol]
	    set netlistRoot "${cellName}_${xType}_${beol}_${metalStack}.spf"
	    set ::netlistList($pvt) $netlistRoot
	    set netlist "$extractNetlistDir/$netlistRoot"
	    logMsg "\t$pvt:  $netlistRoot"
	    if [file exists $netlist] {
		logMsg "  OK\n"
				if {$mapBrackets} {
		    set toks [file split $netlist]
		    set root [lindex $toks end]
		    set bktNetlist "$netlistDir/$root.bktMapped"
		    if {![info exists mapDone($netlist)]} {
			createRebracketedNetlist $netlist $bktNetlist $bktMap
		    }
		    set mapDone($netlist) 1
		    set netlist "$root.bktMapped"
		}
		##  For creating this link, "netlist" must be just the name.
		createSimpleLink "$netlistDir/netlist_post_$pvt.spf" $netlist
		set netlist [file normalize "$netlistDir/$netlist"]
		if {[lsearch -exact $doneNetlists $netlist] < 0} {
		    lappend doneNetlists $netlist
		}
		set sourceNetlists($netlist) 1
	    } else {
		logMsg "  MISSING\n"
		lappend ::setupStatusInfo(processNetlists) "extNetlistMissing"
		set status 0
	    }
	} 
	
	logMsg "Info:  Checking extraction types:\n"
	set spfPath $netlist
	set inFile [open $spfPath "r"]
	set checkPE 0
	set checkExt 0
	set checkReduction 0
	set checkInstPort 0
	while {[gets $inFile line] >= 0} {
		#POWER_EXTRACT: DEVICE_LAYERS, only checks first occurance
		if {([regexp {POWER_EXTRACT: (.+)$} $line -> pExt]) && !$checkPE} {
			if {$pExt == "DEVICE_LAYERS"} {
				logMsg "\tOK POWER_EXTRACT is $pExt\n"
			} else {logMsg "\tWarning:  POWER_EXTRACT is not DEVICE_LAYERS, please indicate reason. Source: $spfPath\n"} 
			set checkPE 1
			}
		#EXTRACTION: RC, only checks first occurance
		if {([regexp {EXTRACTION: (.+)$} $line -> ext]) && !$checkExt} {
			if {$ext == "RC"} {
				logMsg "\tOK EXTRACTION is $ext\n"
			} else {logMsg "\tWarning: EXTRACTION is $ext. Source: $spfPath\n"}
			set checkExt 1
			}
		#REDUCTION: YES
		if {[regexp {REDUCTION: (.+)$} $line -> reduction]} {
			if {$reduction == "YES"} {
				logMsg "\tOK REDUCTION is $reduction\n"
			} else {logMsg "\tWarning: REDUCTION is $reduction.Source: $spfPath\n"} 
			set checkReduction 1
			}
		#INSTANCE_PORT: SUPERCONDUCTIVE, only checks first occurance
		if {([regexp {INSTANCE_PORT: (.+)$} $line -> instPort]) && !$checkInstPort} {
			if {$instPort == "SUPERCONDUCTIVE"} {
				logMsg "\tOK INSTANCE_PORT is $instPort\n"
			} else {logMsg "\tWarning: INSTANCE_PORT is $instPort.Source: $spfPath\n"}
			set checkInstPort 1
			}
	} 
	close $inFile

	if {!$checkPE} {logMsg "\tWarning: No match for POWER_EXTRACT, source: $spfPath\n"}
	if {!$checkExt} {logMsg "\tWarning: No match for EXTRACTION, source: $spfPath\n"}
	if {!$checkReduction} {logMsg "\tWarning: No match for REDUCTION, source: $spfPath\n"}
	if {!$checkInstPort} {logMsg "\tWarning: No match for INSTANCE_PORT, source: $spfPath\n"}	
    } else {
	lappend ::setupStatusInfo(processNetlists) "unrecognizedPhase"
	set $msg "Error: Unrecognized phase \"$::phase\";  Use \"pre\" or \"post\" only\n"
	tk_messageBox -type ok -message $msg
	logMsg $msg
	set status 0
    }

    foreach netlist [array names sourceNetlists] {
	checkExtractedNetlistPorts $netlist
    }
    
    if $status {
	.nb.setuptab.f.cnv.win.processNetlists.status configure -text "OK"
    } else {
	.nb.setuptab.f.cnv.win.processNetlists.status configure -text "Failed"
    }

    set ::setupStatus(processNetlists) $status
    return $status
}

proc mungeLib {runDir srcLib dstLib cfg id} {
global env

    set errFound 0
    if [info exists ::mungeScript] {
	if [file exists $::mungeScript] {
	    set cwd [pwd]
	    cd $runDir
		
		
	    logMsg "** $::mungeScript"
	    ## Munge script annoyingly writes an info message to stderr.
        if {([info exists ::ntEnableCCSN_etm])&&($::ntEnableCCSN_etm == "true")} {
	    if [regexp {(\S+)\.lib} $srcLib dummy srcLibRoot] {
		set nldmLib "$::NLDM_Lib/lib_pg/${srcLibRoot}_pg.lib"
		set expLib "libEdit/${srcLibRoot}_pg.lib"
		deleteFiles $expLib
	    } else {
		set nldmLib "$::NLDM_Lib/lib/${srcLib}"
		set expLib "libEdit/${srcLib}"
		deleteFiles $expLib
	    }
		
	    
	    logMsg "Info: Munging $nldmLib with $srcLib for CCSN using $cfg\n"
	    exec $::mungeScript -RefLib $srcLib -Config $cfg $nldmLib > $id.log 2> $id.err
	    } else {
	    set expLib "libEdit/${srcLib}"
	    deleteFiles $expLib
	    logMsg "Info: Munging $runDir/$srcLib using $cfg\n"
 	    exec $::mungeScript $srcLib -Config $cfg > $id.log 2> $id.err
	    }
	    
	    set IN [open $id.log r]
	    while {[gets $IN line] >= 0} {
		##   Munge_nanotime error messages always begin with "Error:"
		if {[string first "Error:" $line] == 0} {
		    set errFound 1
		    logMsg "$line\n"
		}
	    }
	    close $IN
	    if [file exists $expLib] {
		file rename -force $expLib $dstLib
		logMsg "Info:  $dstLib created successfully\n"
		set status "Created"
	    } else {
		logMsg "Error:  $dstLib creation failed.  See $id.log and $id.err\n"
		set status "Failed"
	    }
	    cd $cwd
	} else {
	    logMsg "Error:  Munge script $::mungeScript does not exist.\n"
	    set status "Failed"
	}
    } else {
	logMsg "Error:  Munge script is undefined (var mungeScript)\n"
	set status "Failed"
    }

    if $errFound {append status ", w/ errors"}
    return $status
}

proc majorRunType {runType} {
    
    set majorType $runType
    regexp {(\S+)_(\S+)} $runType dummy majorType minorType
    if {($majorType != "etm") && ($majorType != "internal")} {logMsg "Error:  Unrecognized majorType \"$majorType\"\n"}
    return $majorType
}

proc minorRunType {runType} {
    
    set minorType ""
    regexp {(\S+)_(\S+)} $runType dummy majorType minorType
    return $minorType
}

proc minorRunSuffix {runType} {
    set minorType [minorRunType $runType]
    if {$minorType == ""} {return ""} else {return "_$minorType"}
}

proc isEtm {runType} {return {[majorRunType $runType] == "etm"}}

proc postprocessLibs {pvt runType} {
    ##  Run the munging script on libs

    logMsg "Info:  postprocessLibs $pvt\n"
    set minorSuffix [minorRunSuffix $runType]
    set runDir "./timing/Run_${pvt}_$runType"
    set outDir [file normalize "lib"]
    set outDirPG [file normalize "lib_pg"]
    createDir $outDir
    createDir $outDirPG
    set srcLib "${::cellName}_${::metalStack}_$pvt.lib"
    set dstLib "$outDir/${::cellName}_${::metalStack}_${pvt}${minorSuffix}.lib"
    set dstLibPG "$outDirPG/${::cellName}_${::metalStack}_${pvt}${minorSuffix}_pg.lib"
    set cfg [file normalize "./src/mungeNanotime_$pvt.cfg"]
    set cfgPG [file normalize "./src/mungeNanotimePG_$pvt.cfg"]
    
    if [file exists "$runDir/$srcLib"] {
	## Update:  Leaving the raw lib in place and unchanged.  Output libs will be placed elsewhere.
	#	## If the .raw lib exists, munging has been done once; skip the copy.
	#	if {![file exists "$runDir/$srcLib.raw"]} {file rename "$runDir/$srcLib" "$runDir/$srcLib.raw"}
	#	set srcLib "$srcLib.raw"
	.nb.libtab.f.cnv.win.fr.$pvt.$runType.mngStat config -text [mungeLib $runDir $srcLib $dstLib $cfg "Munge"]
	.nb.libtab.f.cnv.win.fr.$pvt.$runType.mngStatPG config -text [mungeLib $runDir $srcLib $dstLibPG $cfgPG "MungePG"]
    } else {
	.nb.libtab.f.cnv.win.fr.$pvt.$runType.mngStat config -text "NoSource"
	.nb.libtab.f.cnv.win.fr.$pvt.$runType.mngStatPG config -text "NoSource"
    }
}

proc postprocessMergeLibs {pvt runType} {
    ##  Run the munging script on merged libs

    logMsg "Info:  postprocessMergeLibs $pvt\n"
    set minorSuffix [minorRunSuffix $runType]
    set runDir "./timing/Merge_${pvt}_$runType"
    set outDir [file normalize "lib"]
    set outDirPG [file normalize "lib_pg"]
    createDir $outDir
    createDir $outDirPG
    set srcLib "${::cellName}_${::metalStack}_$pvt.lib"
    set dstLib "$outDir/$srcLib"
    set dstLibPG "$outDirPG/${::cellName}_${::metalStack}_${pvt}${minorSuffix}_pg.lib"
    set cfg [file normalize "./src/mungeNanotime_$pvt.cfg"]
    set cfgPG [file normalize "./src/mungeNanotimePG_$pvt.cfg"]
    
    if [file exists "$runDir/$srcLib"] {
	## Update:  Leaving the raw lib in place and unchanged.  Output libs will be placed elsewhere.
	#	## If the .raw lib exists, munging has been done once; skip the copy.
	#	if {![file exists "$runDir/$srcLib.raw"]} {file rename "$runDir/$srcLib" "$runDir/$srcLib.raw"}
	#	set srcLib "$srcLib.raw"
	.nb.mergetab.f.cnv.win.fr.$runType.$pvt.mngStat config -text [mungeLib $runDir $srcLib $dstLib $cfg "Munge"]
	.nb.mergetab.f.cnv.win.fr.$runType.$pvt.mngStatPG config -text [mungeLib $runDir $srcLib $dstLibPG $cfgPG "MungePG"]
    } else {
	.nb.mergetab.f.cnv.win.fr.$runType.$pvt.mngStat config -text "NoSource"
	.nb.mergetab.f.cnv.win.fr.$runType.$pvt.mngStatPG config -text "NoSource"
    }
}


proc createEmptyFile {file} {

    set fp [open $file w]
    close $fp
}

proc deleteFiles {files} {
    ##  Deletes files; can be glob.
    foreach f [glob -nocomplain "$files"] {file delete -force $f}
}

proc add2CommandLog {cmdString cmdArg} {

    lappend cmdString $cmdArg
    logMsg "Info:  Adding $cmdArg to nt run\n"
    return $cmdString

}


######################################################################################################################################################### part 5 sowmya
proc runCorner {pvt type force} {
    ##  Runs a corner, type
#    logMsg "Info: Running $pvt $type\n"

    set runDir "./timing/Run_${pvt}_$type"
    set runscript "run_nt.csh"
    set cmd "./$runscript"
    set status [getRunStatus $pvt $type]
    ##  If status==Complete, only run if forcing.
    ##  Force is on when running from individual button, off when using runAll
    if {!$force && ($status == "Complete")} { 
	logMsg "Info:  Skipping run of $pvt/$type\n"
	return 
    }
    
    if [info exists ::ntQueue] {set cmd [add2CommandLog $cmd "QUEUE=$::ntQueue"]}
    if [info exists ::ntMem]   {set cmd [add2CommandLog $cmd "MEM=$::ntMem"]}
    if [info exists ::ntVmem]   {set cmd [add2CommandLog $cmd "VMEM=$::ntVmem"]}
    if [info exists ::ntExtraSGEArgs]   {set cmd [add2CommandLog $cmd "EXTRASGEARGS=$::ntExtraArgs"]}
    if [info exists ::ntVersion]   {set cmd [add2CommandLog $cmd "NTversion=$::ntVersion"]}
    if [file exists "$runDir/$runscript"]  {
	logMsg "Info:  Running \"$cmd\"\n"
	set cwd [pwd]
	cd $runDir
	deleteFiles "status*"
	deleteFiles "*.lib"
	deleteFiles "*.lib.raw"
	deleteFiles "*_lib.db"
	deleteFiles "*.sdc"
	set output [exec  {*}$cmd]
	cd $cwd
	logMsg "$output\n"
	if [regexp {Your job (\d+) .* has been submitted} $output dummy jobID] {
	    .nb.runtab.f.cnv.win.fr.$pvt.status_$type config -text "Job $jobID"
	    set ::jobIDarray("${pvt}_${type}") $jobID
	    createEmptyFile "$runDir/statusQueued"
	} else {
	    createEmptyFile "$runDir/statusQueuedFailed"
	}
    } else {puts "Error:  $runDir/$runscript does not exist\n"}
}




proc killCorner {pvt type} {
    ##  Kill a corner, type
#    logMsg "Info: Running $pvt $type\n"

    set runDir "./timing/Run_${pvt}_$type"
    if [info exists ::jobIDarray("${pvt}_${type}")] {
	set status [getRunStatus $pvt $type]
	if {($status == "Queued") || ($status == "Running")} {
	    set jobID $::jobIDarray("${pvt}_${type}")
	    logMsg "Info:  Killing job $jobID\n"
	    set msg [exec qdel $jobID]
	    logMsg "Info:  $msg\n"
	    deleteFiles "$runDir/status*"
	    set SF [open "$runDir/statusKilled" w]
	    close $SF
	    .nb.runtab.f.cnv.win.fr.$pvt.status_$type config -text "Killed"
	}
#	logMsg "Info:  Status = $status\n"
		    
    } else {
	logMsg "Warning:  Job for $pvt/$type has not been started\n"
    }

}

######################################################################################################################################################### part 6 sowmya

proc refreshLibPageRow {pvt} {
    ##  Refreshes the file info for a lib row

    foreach runType $::typeList {
	if [isEtm $runType] {
	    set ms [minorRunSuffix $runType]
	    set f .nb.libtab.f.cnv.win.fr.$pvt.$runType
	    set file "${::cellName}_${::metalStack}_$pvt.lib"
	    set path "./timing/Run_${pvt}_$runType"
	    #    puts "$path/$file"
	    $f.rawLib delete 0 end
	    if [file exists "$path/$file"] {
		set fg green
		set stat "OK"
	    } else {
		set fg red
		set stat "Missing"
	    }
	    $f.rawLib insert end $stat
	    $f.rawLib config -fg $fg
	}
    }
}

proc setupLibPageRow {pvt} {

    set rowFrame .nb.libtab.f.cnv.win.fr.$pvt
    frame $rowFrame
    pack [label $rowFrame.label -text "$pvt:" -width 20 -font MyDefaultFont] -side left
    set doSpace 0
    foreach runType $::typeList {
	if [isEtm $runType] {
	    set fname $rowFrame.$runType
	    frame $fname
	    if $doSpace {pack [label $fname.mngSpace -width 3 -font MyDefaultFont] -side left}
	    set doSpace 1
	    pack [label $fname.rawLabel -text "$runType:" -font MyDefaultFont] -side left
	    pack [entry $fname.rawLib -width 10 -font MyDefaultFont] -side left
	    pack [button $fname.munge -text "Munge -->" -command "postprocessLibs $pvt $runType" -font MyDefaultFont] -side left
	    pack [label $fname.mngLbl -width 8 -relief sunken -text NonPG -font MyDefaultFont] -side left
	    pack [label $fname.mngStat -width 10 -relief sunken -font MyDefaultFont] -side left
	    pack [label $fname.mngLblPG -width 8 -relief sunken -text PG -font MyDefaultFont] -side left
	    pack [label $fname.mngStatPG -width 10 -relief sunken -font MyDefaultFont] -side left
	    pack $fname -side left
	}
    }
    refreshLibPageRow $pvt
    return $rowFrame
}

proc mungeAllLibs {} {
    foreach pvt $::pvtCorners {
	foreach runType $::typeList {
	    if [isEtm $runType] {
		postprocessLibs $pvt $runType
	    }
	}
    }
}

proc mungeAllMergeLibs {} {
    if {![info exists ::mergeLibs]} {
	logMasg "Warning:  No merges defined\n"
	return
    }

    foreach pvt $::pvtCorners {
	foreach type [array names ::mergeLibs] {
	    postprocessMergeLibs $pvt $type
	}
    }
}

proc setupLibPage {} {
    
    logMsg "Info:  setupLibPage\n"
    setSetupButtonColor setupLibPage blue
    if {![winfo exists .nb.libtab.f.cnv.win.bf]} {
	frame .nb.libtab.f.cnv.win.bf
	pack [button .nb.libtab.f.cnv.win.bf.mungeAll -text "MungeAll" -command {mungeAllLibs} -font MyDefaultFont] -side left
	pack .nb.libtab.f.cnv.win.bf
    }

    if [winfo exists .nb.libtab.f.cnv.win.fr] {destroy .nb.libtab.f.cnv.win.fr}
    frame .nb.libtab.f.cnv.win.fr
    foreach pvt $::pvtCorners {
	pack [setupLibPageRow $pvt] -side top
    }
    pack .nb.libtab.f.cnv.win.fr

    set ::setupStatus(setupLibPage) 1
    set ::setupStatusInfo(setupLibPage) ""
    .nb.setuptab.f.cnv.win.setupLibPage.status configure -text "OK"
    return 1

}

proc doMerge {pvt type} {
    logMsg "Info:  Merging $pvt $type\n"
    set dir "./timing/Merge_${pvt}_$type"
    set cwd [pwd]
    cd $dir
    exec ./merge_nt.csh
    cd $cwd

    ##  Need checking bits to verify that the merged lib was produced and no errors.
    ##  See report.rpt
    set file "$dir/${::cellName}_${::metalStack}_${pvt}.lib"
    set stat .nb.mergetab.f.cnv.win.fr.$type.$pvt.execStat
    if [file exists $file] {
	$stat config -fg green -text "OK"
    } else {
	$stat config -fg red -text "Failed"
    }
}

proc setupMergePageRow {outType pvt} {

    set rowFrame .nb.mergetab.f.cnv.win.fr.$outType.$pvt
    frame $rowFrame
    pack [label $rowFrame.label -text "$pvt:" -width 20 -font MyDefaultFont] -side left
    set doSpace 0
    if $doSpace {pack [label $rowFrame.mngSpace -width 3 -font MyDefaultFont] -side left}
    set doSpace 1
#    pack [label $rowFrame.rawLabel -text "$runType:"] -side left
    pack [button $rowFrame.merge -text "ExecMerge" -command "doMerge $pvt $outType" -font MyDefaultFont] -side left
    pack [label $rowFrame.execStat -width 10 -relief sunken -text "" -font MyDefaultFont] -side left
    pack [button $rowFrame.munge -text "Munge -->" -command "postprocessMergeLibs $pvt $outType" -font MyDefaultFont] -side left
    pack [label $rowFrame.mngLbl -width 8 -relief sunken -text NonPG -font MyDefaultFont] -side left
    pack [label $rowFrame.mngStat -width 10 -relief sunken -font MyDefaultFont] -side left
    pack [label $rowFrame.mngLblPG -width 8 -relief sunken -text PG -font MyDefaultFont] -side left
    pack [label $rowFrame.mngStatPG -width 10 -relief sunken -font MyDefaultFont] -side left
    pack $rowFrame -side left

#    refreshLibPageRow $pvt
    return $rowFrame
}
proc setupMergePage {} {
    if {![info exists ::mergeLibs]} {return 1}
    logMsg "Info:  setupLibPage\n"

    setSetupButtonColor setupMergePage blue
    if [winfo exists .nb.mergetab.f.cnv.win.fr] {destroy .nb.mergetab.f.cnv.win.fr}
    frame .nb.mergetab.f.cnv.win.fr
    foreach outType [array names ::mergeLibs] {
	set inTypes $::mergeLibs($outType)
	set f .nb.mergetab.f.cnv.win.fr.$outType
	frame $f
	pack [label $f.label -text "{$inTypes} --> $outType"] -side top
	foreach pvt $::pvtCorners {
	    pack [setupMergePageRow $outType $pvt] -side top
	}
	pack $f -side top
    }

    if {![winfo exists .nb.mergetab.f.cnv.win.bf]} {
	frame .nb.mergetab.f.cnv.win.bf
	pack [button .nb.mergetab.f.cnv.win.bf.mungeAll -text "MungeAll" -command {mungeAllMergeLibs}] -side left
	pack .nb.mergetab.f.cnv.win.fr
	pack .nb.mergetab.f.cnv.win.bf
    }

    set ::setupStatus(setupMergePage) 1
    set ::setupStatusInfo(setupMergePage) ""
    .nb.setuptab.f.cnv.win.setupMergePage.status configure -text "OK"
    return 1

}


######################################################################################################################################################### part 7 sowmya

proc setupRunPageRow {pvt} {
set fname .nb.runtab.f.cnv.win.fr.$pvt
    frame $fname
    pack [label $fname.label -text "$pvt:" -width 20 -font MyDefaultFont] -side left
    # pack [entry $fname.netlist -width 60] -side left
    # set netlist $::netlistList($pvt)
    # $fname.netlist insert end $netlist
    foreach runType $::typeList {
	pack [button $fname.run_$runType -text "Run $runType" -width 10 -command "runCorner $pvt $runType 1" -font MyDefaultFont] -side left
	pack [button $fname.kill_$runType -text "Kill $runType" -width 10 -command "killCorner $pvt $runType" -font MyDefaultFont] -side left
	pack [label $fname.status_$runType -text "" -width 10 -font MyDefaultFont] -side left
    }
    return $fname
}

proc runAllCorners {type} {foreach pvt $::pvtCorners {runCorner $pvt $type 0}}
proc killAllCorners {type} {foreach pvt $::pvtCorners {killCorner $pvt $type}}


proc getRunStatus {pvt type} {

    set runDir "./timing/Run_${pvt}_$type"
    if [info exists ::runjobIDarray("${pvt}_${type}")] {set jobID $::runjobIDarray("${pvt}_${type}") } else {set jobID ""}
    set statusFiles [glob -nocomplain "$runDir/status*"]
    set Nstatus [llength $statusFiles]
    if {$Nstatus == 0} {
	set status "none"
    } elseif {$Nstatus == 1} {
	regexp {status(.*)} $statusFiles dummy status
    } else {
	logMsg "Warning:  Multiple status files for $pvt/$type:  {$statusFiles}\n"
	set status "Unknown"
    }

    return $status

}


proc checkRunStatus {} {

    foreach pvt $::pvtCorners {
	foreach type $::typeList {
	    set status [getRunStatus $pvt $type]
	    .nb.runtab.f.cnv.win.fr.$pvt.status_$type config -text $status
	    ##  Refresh existence of etm libs.
	    refreshLibPageRow $pvt
	}
    }
}


proc setupRunPage {} {

    logMsg "Info:  setting up RunPage\n"
    setSetupButtonColor setupRunPage blue
    if [winfo exists .nb.runtab.f.cnv.win.fr] {destroy .nb.runtab.f.cnv.win.fr}
    frame .nb.runtab.f.cnv.win.fr


    set fname .nb.runtab.f.cnv.win.fr.runAll
    frame $fname
    pack [label $fname.label -text "All PVT:" -width 20 -font MyDefaultFont] -side left
    pack [button .nb.runtab.f.cnv.win.fr.buttonCheck -text "CheckStatus" -command "checkRunStatus" -font MyDefaultFont] -side top
    foreach runType $::typeList {
	pack [button $fname.runAll_$runType -text "RunAll $runType" -width 10 -command "runAllCorners $runType" -font MyDefaultFont] -side left
	pack [button $fname.killAll_$runType -text "KillAll $runType" -width 10 -command "killAllCorners $runType" -font MyDefaultFont] -side left
	pack [label $fname.status_$runType -text "" -width 10 -font MyDefaultFont] -side left
#	pack [button .nb.runtab.f.cnv.win.fr.runAll.button_$type -text "RunAll $type" -command "runAllCorners $type"] -side left
#	pack [button .nb.runtab.f.cnv.win.fr.runAll.killButton_$type -text "KillAll $type" -command "killAllCorners $type"] -side left
    }

    pack .nb.runtab.f.cnv.win.fr.runAll -side top
    pack .nb.runtab.f.cnv.win.fr

    foreach pvt $::pvtCorners {
	pack [setupRunPageRow $pvt] -side top
   }
    

    set ::setupStatus(setupRunPage) 1
    set ::setupStatusInfo(setupRunPage) ""
    .nb.setuptab.f.cnv.win.setupRunPage.status configure -text "OK"
    return 1



}

proc createDir {dirName} {

    if [file exists $dirName] {
	if {![file isdirectory $dirName]} {
	    tk_messageBox -type ok -message "Error:  $dirName exists, not a dir"
	    return 0
	}   
    } else {file mkdir $dirName}
    return 1

}

proc createPvtRunScript {dir pvt type} {
    global env

    set OUT [open "$dir/pvt_setup.tcl" w]
	set script_dirname [file dirname [file normalize [info script]]]
	#puts $OUT "set PROJ_HOME /remote/proj/alpha/alpha_common/flows/For_Evaluation/pocv/"
	set utils_version $env(DDR_UTILS_TIMING_VERSION)
    puts $OUT "set PROJ_HOME /remote/cad-rep/msip/tools/Shelltools/ddr-utils-timing/$utils_version/bin/"
	#puts $OUT "set PROJ_HOME /remote/us01home58/dikshant/Gitlab/ddr-hbm-phy-automation-team/ddr-utils-timing/dev/main/bin"
    puts $OUT "set PVT $pvt"
    puts $OUT "set runType $type"
    set scPvt [getPvtField $::cornerData($pvt) scPvt]
   # puts $OUT "set scCorner $scPvt"
    puts $OUT "set cellName $::cellName"
    puts $OUT "set metalStack $::metalStack"
    puts $OUT "#Adding Projecttype projectName and release variable in setup file for nt_tech.tcl path as per JIRA P10020416-36217"
    puts $OUT "set pt $::projectType"
    puts $OUT "set pn $::projectName"
    puts $OUT "set rn $::releaseName"

    if [info exists ::ntEnablePbsa_$type] {
 	set args [set ::ntEnablePbsa_$type]
	puts $OUT "set ntEnablePbsa {$args}"
    } else {puts $OUT "set ntEnablePbsa false"}

    if [info exists ::stdCellLibPath] {puts $OUT "set STDLIBPATH $::stdCellLibPath"}
    set maxSupplyVal 0
    foreach pwr $::supplyPins {
	set val [getPvtField $::cornerData($pvt) $pwr]
	puts $OUT "set ${pwr}_val $val"
	if {$val > $maxSupplyVal} {set maxSupplyVal $val}
    }

    ##  processPVT makes sure this oc_global_voltage is defined.
    set val [getPvtField $::cornerData($pvt) $::oc_global_supply]
    if {$val == ""} {
	logMsg "Error:  Voltage for $::oc_global_supply is undefined for pvt $pvt\n"
	puts $OUT "set OC_GLOBAL_VOLTAGE 1"
    } else {
	puts $OUT "set OC_GLOBAL_VOLTAGE $val"
    }
	
    #########################Additional options ccsn pocv vector context #############################
    
    if [info exists ::ntEnableCCSN_$type] {
 	set args [set ::ntEnableCCSN_$type]
	puts $OUT "set ntEnableCCSN {$args}"
    } else {puts $OUT "set ntEnableCCSN false"}
    

    if [info exists ::used_pocv_variation_param] {
 	set args [set ::used_pocv_variation_param]
	puts $OUT "set pocv_variation_param {$args}"
    } else {puts $OUT "set pocv_variation_param false"}
     
    
    if [info exists ::ntvectorFile] {
 	set args1 [set ::ntvectorFile]
	puts $OUT "set vectorFile {$args1}"
    } else {puts $OUT "set vectorFile false"}


    if [info exists ::context_dependent] {
 	set args2 [set ::context_dependent]
	puts $OUT "set context_dependentval {$args2}"
    } else {puts $OUT "set context_dependentval false"}
    
    
    if [info exists ::pocvntVersion] {
 	set args445 [set ::pocvntVersion]
	puts $OUT "set ntVersion_pocv $args445"
    } else {
        puts $OUT "#set ntVersion_pocv {false}"     
        puts $OUT "set ntVersion_pocv nt/2017.06-SP3 "
    }
	

    if [info exists ::sisVersion] {
 	set args445 [set ::sisVersion]
	puts $OUT "set SISVersion $args445"
    } else {
        puts $OUT "#set SISVersion {false}"     
        puts $OUT "set SISVersion siliconsmart/2017.03-SP1 "
    }
	
	   
    if [info exists ::ntEnablePOCV_$type] {
 	set args3 [set ::ntEnablePOCV_$type]
	puts $OUT "set ntEnablePOCV {$args3}"
    } else {puts $OUT "set ntEnablePOCV false"}
	
	
    if [info exists ::loadRangeCaps] {
	foreach name [array names ::loadRangeCaps] {puts $OUT "set loadRangeCaps($name) {$::loadRangeCaps($name)}"}
    }

    if [info exists ::loadRangeSlew] {
	foreach name [array names ::loadRangeSlew] {puts $OUT "set loadRangeSlew($name) {$::loadRangeSlew($name)}"}
    }
    
    if [info exists ::loadRangePins] {
	foreach name [array names ::loadRangePins] {puts $OUT "set loadRangePins($name) {$::loadRangePins($name)}"}
    }

    writeRunvars "all" $OUT
    writeRunvars $type $OUT

    close $OUT
}

######################################################################################################################################################### part 8 sowmya

proc writeRunvars {type fp} {

    if [info exists ::runVars($type)] {
	puts $fp "##  Run Variables for type \"$type\""
	foreach varDef $::runVars($type) {
	    set l [split $varDef "="]
	    puts $fp "set [lindex $l 0] {[lindex $l 1]}"
	}
    }
}

proc getRealFile {linkfile} {   
    ## Using this where we really need to copy a physical file, not just a link.
    if {[file type $linkfile] eq "link"} {
	set tempfile [file readlink $linkfile]
    } else { return $linkfile }

    if {[file type $tempfile] eq "link" } {
	getRealFile $tempfile
    } else {
	return $tempfile
    }
}

proc copySimpleFile {src dst} {

    if [info exists $src] {file copy -force [getRealFile $src] $dst} else {logMsg "Error:  $src does not exist\n"}
}

proc openFileReadFromVar {varName level} {
    
    if [info exists $varName] {
	set fileNameVar [set $varName]
	if [file exists $fileNameVar] {
	    return [open $fileNameVar r]
	} else {
	    set msg "Error: File $fileNameVar (referenced via $varName) does not exist"
	    if {$level == 1} {logMsg "$msg\n"}
	    if {$level == 2} {
	    	tk_messageBox -type ok -message $msg
		logMsg "$msg"
	    }
	    return 0
	}
    } else {
	set msg "$varName is undefined"
	if {$level == 1} {logMsg "$msg\n"}
	if {$level == 2} {
	    tk_messageBox -type ok -message $msg
	    logMsg "$msg"
	}
	return 0
    }
}

######################################################################################################################################################### part 9 sowmya

proc setupRundirs {} {
    
    logMsg "Info:  setupRundirs\n"
    setSetupButtonColor setupRundirs blue
    set ::setupStatus(setupRundirs) 1
    set ::setupStatusInfo(setupRundirs) ""
    
    if {!$::restart} {
	logMsg "Info:  Setting up from scratch\n"

	if {![info exists ::scriptDir]} {
	    logMsg "Error: scriptDir  is undefined\n"
	    set ::setupStatus(setupRundirs) 0
	    lappend ::setupStatusInfo(setupRundirs) "scriptDirUndefined"
	    return 0
	}
	
	if ![file exists $::scriptDir] {
	    logMsg "Error:  $scriptDir does not exist\n"
	    set ::setupStatus(setupRundirs) 0
	    lappend ::setupStatusInfo(setupRundirs) "scriptDirMissing"
	    return 0
	}
	
	foreach pvt $::pvtCorners {
	    foreach type $::typeList {
		set majorType [majorRunType $type]
		set dir "./timing/Run_${pvt}_$type"
		createDir $dir
		
		##  Delete pre-existing stuff.
		deleteFiles "$dir/status*"
		deleteFiles "$dir/*.rpt"
		deleteFiles "$dir/*.log"
		deleteFiles "$dir/*.err"
		deleteFiles "$dir/*.lib"
		deleteFiles "$dir/*.db"
		deleteFiles "$dir/*.sdc"
		##  Create the pvt_setup script.  This is where the cell/pvt info is kept.
		createPvtRunScript $dir $pvt $type
		
		##  The run-NT tcl script
		if [file exists $::scriptDir/run_nt_$type.tcl] {
		    createSimpleLink $dir/run_nt_$type.tcl $::scriptDir/run_nt_$type.tcl 
		} else {
		    createSimpleLink $dir/run_nt_$majorType.tcl $::scriptDir/run_nt_$majorType.tcl 
		}
		
		##  The run-NT shell script
		if [file exists $::scriptDir/run_nt_$type.csh] {
		    createSimpleLink $dir/run_nt.csh $::scriptDir/run_nt_$type.csh
		} else {
		    createSimpleLink $dir/run_nt.csh $::scriptDir/run_nt_$majorType.csh
		}
		
		######################################### sowmya
		
		if [file exists $::scriptDir/run_sis_sidefile_pocv.csh ] {
		    createSimpleLink $dir/run_sis_sidefile_pocv.csh  $::scriptDir/run_sis_sidefile_pocv.csh 
		} else {
		    logMsg "Error run_sis_sidefile_pocv.csh script is not present in used ntFiles directory"
		}

		if {([info exists ::ntEnablePOCV_etm])&&($::ntEnablePOCV_etm == "true")} {
		   if [file exists $::scriptDir/gen_pocvSideFile_pocv.tcl ] {
		      createSimpleLink $dir/gen_pocvSideFile.tcl  $::scriptDir/gen_pocvSideFile_pocv.tcl
		   } else {
		      logMsg "Error gen_pocvSideFile.tcl script is not present in used ntFiles directory"
		   }
		} else { 
		   logMsg "WARNING : Creating empty gen_pocvSideFile.tcl file "
		   exec touch $dir/gen_pocvSideFile.tcl
		}
		
		######################################## sowmya
		
		##  Build nt_tech.sp, containing lib and temperature info
		set OUT [open "$dir/nt_tech.sp" w]
		if [info exists ::modelDir] {set mod $::modelDir} else {set mod $env(MSIP_PROJ_ROOT)/$::projectType/$::projectName/$::releaseName/cad/models/hspice}
		puts $OUT "*"
		set voltage {}
		set maxSupply 0
		foreach supply $::supplyPins {
		    set val [getPvtField $::cornerData($pvt) $supply]
		    if {$val > $maxSupply} {set maxSupply $val}
		    lappend voltage [format "%0.3f" $val]
		}
		puts $OUT "*nanosim tech=\"voltage $voltage\""
		set vmax [format "%0.3f" [expr 1.1*$maxSupply]]
		set vstep [format "%0.3f" [expr 0.001*$maxSupply]]
		puts $OUT "*nanosim tech=\"vds 0 $vmax $vstep\""
		puts $OUT "*nanosim tech=\"vgs 0 $vmax $vstep\""
		puts $OUT "*nanosim tech=\"delta_vt -0.5 0.5\""
		if [info exists ::modelLibs] {
		    foreach lib $::modelLibs {
			set val [getPvtField $::cornerData($pvt) "$lib"]
			puts $OUT ".LIB \'$mod/$lib.lib\' $val"
		    }
		    ##  Get extra device models, if any
		    set AUX [openFileReadFromVar ::extraDeviceModels 0]
		    if {$AUX != 0} {
			while {[gets $AUX line] >= 0} { puts $OUT $line}
			close $AUX
		    }
		} else {
		    set ::setupStatus(setupRundirs) 0
		    lappend ::setupStatusInfo(setupRundirs) "modelLibsUndefined"
		    logMsg "Error:  modelLibs is undefined"
		}
		puts $OUT ".temp [getPvtField $::cornerData($pvt) TEMP]"
		close $OUT
		
		##  Links to netlists
		set netlistDir [file normalize "./netlist"]
		createSimpleLink "$dir/netlist_sub.sp" "$netlistDir/netlist_sub.spf"
		if {$::phase == "pre"} {
		    createSimpleLink "$dir/netlist.sp" "$netlistDir/netlist_pre.spf"
		} else {
		    createSimpleLink "$dir/netlist.sp" "$netlistDir/netlist_post_$pvt.spf"
		}
	    }
	}
    } else {
	logMsg "Info:  Restarting\n"
    }

    if {$::setupStatus(setupRundirs)} {
	.nb.setuptab.f.cnv.win.setupRundirs.status configure -text "OK"
	return 1
    } else {
	.nb.setuptab.f.cnv.win.setupRundirs.status configure -text "Failed"
	return 0
    }

}

proc setupMergedirs {} {
    
    if {![info exists ::mergeLibs]} {return 1}
    logMsg "Info:  setupMergedirs\n"
    setSetupButtonColor setupMergedirs blue
    set ::setupStatus(setupMergedirs) 1
    set ::setupStatusInfo(setupMergedirs) ""
    
    if {![info exists ::scriptDir]} {
	logMsg "Error:  scriptDir is undefined\n"
	set ::setupStatus(setupMergedirs) 0
	lappend ::setupStatusInfo(setupMergedirs) "scriptDirUndefined"
	return 0
    }

    if ![file exists $::scriptDir] {
	logMsg "Error:  $scriptDir does not exist\n"
	set ::setupStatus(setupMergedirs) 0
	lappend ::setupStatusInfo(setupMergedirs) "scriptDirMissing"
	return 0
    }

    foreach type [array names ::mergeLibs] {
	foreach pvt $::pvtCorners {        
	    set dir "./timing/Merge_${pvt}_$type"
	    createDir $dir
	    ##  The merge tcl script
	    if [file exists $::scriptDir/merge_nt.tcl] {
		createSimpleLink $dir/merge_nt.tcl $::scriptDir/merge_nt.tcl 
	    }
	    ##  The merge shell script
	    if [file exists $::scriptDir/merge_nt.csh] {
		createSimpleLink $dir/merge_nt.csh $::scriptDir/merge_nt.csh
	    }

	    set SCR [open $dir/merge_setup.tcl w]
	    set db_files {}
	    set mode_names {}
	    foreach inType $::mergeLibs($type) {
		set inMinorType [minorRunType $inType]
		set inFile "./timing/Run_${pvt}_${inType}/${::cellName}_${::metalStack}_${pvt}_lib.db"
		set inFile [file normalize $inFile]
		lappend db_files $inFile
		lappend mode_names $inMinorType
	    }
	    puts $SCR "set db_files {$db_files}"
	    puts $SCR "set mode_names {$mode_names}"
	    puts $SCR "set output ${::cellName}_${::metalStack}_${pvt}"
	    close $SCR
	}
    }

    if {$::setupStatus(setupMergedirs)} {
	.nb.setuptab.f.cnv.win.setupMergedirs.status configure -text "OK"
	return 1
    } else {
	.nb.setuptab.f.cnv.win.setupMergedirs.status configure -text "Failed"
	return 0
    }

}



proc myCopy {src dst} {
    set SRC [open $src r]
    set DST [open $dst w]
    while {[gets $SRC line] >= 0} {
	puts $DST $line
	puts $line
    }
    close $SRC
    close $DST
}

proc min {a b} {if {$a>$b} {return $b} else {return $a}}
proc max {a b} {if {$a>$b} {return $a} else {return $b}}

proc createMungeConfigs {} {
    ##   Creates default Munge_nanotime config files

    foreach PVT $::pvtCorners {
	
	set cfgFile "./src/mungeNanotime_$PVT.cfg"
	set cfgFilePG "./src/mungeNanotimePG_$PVT.cfg"
	
	if [info exists ::ntMungeConfigHdr] {
	    if [file exists $::ntMungeConfigHdr] {
		file copy -force [getRealFile $::ntMungeConfigHdr]  $cfgFile
		file copy -force [getRealFile $::ntMungeConfigHdr]  $cfgFilePG
		file attributes $cfgFile -permissions "+w"
		file attributes $cfgFilePG -permissions "+w"
		set CFG [open $cfgFile a]
		set CFGPG [open $cfgFilePG a]
	    } else {
		logMsg "Warning:  file $::mungeCfgHeader (var mungeCfgHeader) does not exist\n"
	    }
	} else {
	    set CFG [open $cfgFile w]
	    set CFGPG [open $cfgFilePG w]
	}
	
	
	##  Cell area:
	if [info exists ::cellArea] {
	    #  The munge script appears to want 6 decimal places.
	    set area [format "%.6f" $::cellArea]
	    puts $CFG "cell_area $area $::cellName"
	    puts $CFGPG "cell_area $area $::cellName"
	} else {logMsg "Warning:  cellArea is undefined; skipping"}
	
	puts $CFG ""
	puts $CFGPG ""
	
	##  This part is a bit touchy.  
	##    The first voltage map *must* be the supply corresponding to the pvt name.
	##    The Munge script writes the voltage_map in the *reverse* order that the pg_pin statements appear in the config
	##    Therefore, the last pg_pin written must be the one that corresponds to the pvt supply.
	foreach pin $::groundPins {
	    puts $CFGPG "pg_pin $pin GND"
	}
	foreach pin $::supplyPinsGlobalLast {
	    set val [getPvtField $::cornerData($PVT) $pin]
	    puts $CFGPG "pg_pin $pin PWR $val"
	}
	
	puts $CFG ""
	puts $CFGPG ""
	
	##  Buses
	foreach pin [lsort [array names ::pininfoData]] {
	    set dir [lindex $::pininfoData($pin) [pininfoField direction]]
	    if { [isPower $pin] || [isGround $pin] } {
		##  Pin direction is inout by default.  Fix this in non-PG libs.
		puts $CFG "change_dir $pin $dir"
		continue
	    }
	    ##  Strip off the brackets, if there are any
	    if {![regexp "^(.*)(\[\[<\])(.*)(\[\]>\])" $pin dummy rootName lBkt bitField rBkt]} {set rootName $pin}
	    set msb [lindex $::pininfoData($pin) [pininfoField msb]]
	    set lsb [lindex $::pininfoData($pin) [pininfoField lsb]]
	    set related_power [lindex $::pininfoData($pin) [pininfoField related_power]]
	    set related_ground [lindex $::pininfoData($pin) [pininfoField related_ground]]
	    if [isBus $pin] {
		puts $CFG "add_bus_info $rootName $msb $lsb $dir NONE NONE"
		puts $CFGPG "add_bus_info $rootName $msb $lsb $dir $related_power $related_ground"
		set l [min $lsb $msb]
		set u [max $lsb $msb]
		##  set related_power/ground for individual bus bits
		for {set i $l} {$i <= $u} {incr i} {puts $CFGPG "add_pin_info $rootName$lBkt$i$rBkt $related_power $related_ground"}
	    } else {
		puts $CFGPG "add_pin_info $rootName $related_power $related_ground"
	    }
	}
	
	##  Pick up the custom additions
	if [info exists ::ntMungeCustomConfig] {
	    if [file exists $::ntMungeCustomConfig] {
		set IN [open $::ntMungeCustomConfig r]
		while {[gets $IN line] >= 0} {
		    puts $CFG $line
		    puts $CFGPG $line
		}
	    } else {
		logMsg "Warning:  $::ntMungeCustomConfig does not exist\n"
	    }
	}
	
	close $CFG
	close $CFGPG
	
	## Now link to provided files instead, if provided.
	if [info exists ::ntMungeConfig] {
	    if [file exists $::ntMungeConfig] {createSimpleLink $cfgFile $::ntMungeConfig} else {logMsg "Warning: $::ntMungeConfig does not exist; using default config"}
	}
	if [info exists ::ntMungeConfigPG] {
	    if [file exists $::ntMungeConfigPG] {createSimpleLink $cfgFilePG $::ntMungeConfigPG} else {logMsg "Warning: $::ntMungeConfigPG does not exist; using default config"}
	}
    }
}
	
######################################################################################################################################################### part 10 sowmya
proc setupNTsource {} {
    ##  Sets up the NT src directory.

    global supplyPins
    global groundPins
    global bboxCells
    global equivFile
    global clkPins
    global pininfoData
    global scriptDir
    logMsg "Info:  setupNTsource\n"
    setSetupButtonColor setupNTsource blue

    set sourceDir "./src"
    if {![createDir $sourceDir]} {return}
    set cwd [pwd]
    
    ## equiv file
    if {[set fp [createSimpleSourceFile "$sourceDir/equiv.txt"]] != 0} {
	puts $fp $bboxCells
	close $fp
    }

    ##  Generate config from equiv
    set configTmp ""
    set sep ""
    foreach x $bboxCells {
	append configTmp "$sep\"$x\""
	set sep ","
    }
#    if {[set fp [createSimpleSourceFile "$sourceDir/config.txt"]] != 0} {
#	puts $fp [regsub -all " " $configTmp ","]
#	close $fp
#    }

    ## pwr_supply.tcl
    if {[set fp [createSimpleSourceFile "$sourceDir/pwr_supply.tcl"]] != 0} {
	puts $fp "### Power Supply Net ###"
	puts $fp "set supply_net { $supplyPins }"
	foreach supply $supplyPins { puts $fp "set_voltage \$${supply}_val $supply"}
	close $fp
    }

    ##  port_setup.tcl
    if {[set fp [createSimpleSourceFile "$sourceDir/port_setup.tcl"]] != 0} {
	set non_clock_inputs ""
	set outputs ""
	set inputs ""
	set clock_inputs ""
	set inouts ""
	foreach domain $::supplyPins {
	    set inputsDomain($domain) {}
	    set inoutsDomain($domain) {}
	}
	if {![info exists clkPins]} {logMsg "Warning:  No clock pins defined"}
	foreach pin [lsort [array names pininfoData]] {
	    set related_power [getRelatedPower $pin]
	    if {![isPower $pin] && ![isGround $pin]} {
		##  Signal pin
		if [isInput $pin] {
		    lappend inputs $pin
		    lappend inputsDomain($related_power) $pin
		    if [isClock $pin] {lappend clock_inputs $pin} else {lappend non_clock_inputs $pin}
		} elseif [isOutput $pin] {
		    lappend outputs $pin
		} elseif [isInout $pin] {
		    lappend inouts $pin
		    lappend outputs $pin
		    lappend inoutsDomain($related_power) $pin
		} else {
		    set d [lindex $pininfoData($pin) [pininfoField direction]]
		    logMsg "Error:  Unrecognized pin direction($d) for $pin\n"
		}
	    } else {
		   lappend inputs $pin
		} 
	}
	puts $fp "set NON_CLOCK_INPUTS { $non_clock_inputs }" 
	puts $fp "set CLOCK_INPUTS { $clock_inputs }" 
	puts $fp "set OUTPUTS { $outputs }" 
	puts $fp "set INPUTS { $inputs }" 
	puts $fp "set INOUTS { $inouts }" 
	puts $fp "set POWERNET { $supplyPins }" 
	foreach domain $::supplyPins {
	    puts $fp "set INPUTS_$domain { $inputsDomain($domain) }"
	    puts $fp "set INOUTS_$domain { $inoutsDomain($domain) }"
	}
	close $fp
    }
    
    ##  model_port.tcl
    if {[set fp [createSimpleSourceFile "$sourceDir/model_port.tcl"]] != 0} {
	puts $fp "set link_prefer_model_port { $bboxCells }"
	close $fp
    }


    ## user_lib_include.tcl
    if {[set fp [createSimpleSourceFile "$sourceDir/user_lib_include.tcl"]] != 0} {

	set l1 ""
	set l2 ""

	##  First, include all used standard cell libraries
	if [info exists ::stdCellDbArray] {
	    foreach db [array names ::stdCellDbArray] {
		lappend l1 "lappend link_path ${db}_\${corner}.db"
		lappend l2 "read_db ${db}_\${corner}.db"
	    }
	}

	foreach bbox $bboxCells {
	    if {[info exists ::libsOK($bbox)]} {
		lappend l1 "lappend link_path \"../../subckts/${bbox}_\${metal_stack}_\${corner}.lib\""
		lappend l2 "read_lib \"../../subckts/${bbox}_\${metal_stack}_\${corner}.lib\""
	    }
	}
	foreach line $l1 {puts $fp $line}
	foreach line $l2 {puts $fp $line}
 	close $fp
    }
      
    ## user_pocv_side_file.tcl
    if {[set fp [createSimpleSourceFile "$sourceDir/user_pocv_side_file.tcl"]] != 0} {
     if {([info exists ::ntEnablePOCV_etm])&&($::ntEnablePOCV_etm == "true")} {

	set l1 ""
	set l2 ""

	##  First, include all used standard cell libraries
	if [info exists ::stdCellDbArray] {
	    foreach db [array names ::stdCellDbArray] {
		if [regexp {^(.*)\/(.*)} $db match path name] {
		lappend l1 "exec $scriptDir/lvf_to_libCellVar ps ${path}/../../pocv/${name}_\${corner}.pocv"
		#### when using dummy sidefiles for stdcells ; else comment below line and uncomment above line
		#lappend l1 "exec $scriptDir/lvf_to_libCellVar ps ${stdcellpocvsidefilepath}/${name}_\${corner}.pocv"
		} else {
		puts "##pocv Error, std cell path is not in standard format"
		}
	    }
	}

	foreach bbox $bboxCells {
	    if {[info exists ::libsOK($bbox)]} {
		lappend l2 "exec $scriptDir/lvf_to_libCellVar ps ../../subckts/pocv/${bbox}_\${metal_stack}_\${corner}.pocv "
	    }
	}
	
	#puts  $fp "exec $scriptDir/lvf_to_libCellVar ps"
	foreach line $l1 {puts  $fp " $line"}
	#puts $fp ""
	#puts  $fp "exec $scriptDir/lvf_to_libCellVar ps"
	foreach line $l2 {puts  $fp " $line"}
	#puts $fp ""
 	close $fp
    } else {
	puts $fp ""
    }
    }


    ##  Files that should start as p4'ed macro collateral
    ##  consraints.tcl
    createLinkSourceFile "$sourceDir/constraints.tcl" ntConstraintsFile
    createLinkSourceFile "$sourceDir/exceptions.tcl" ntExceptionsFile
    createLinkSourceFile "$sourceDir/precheck.tcl" ntPrecheckFile
    createLinkSourceFile "$sourceDir/prechecktopo.tcl" ntPrecheckTopoFile
    createLinkSourceFile "$sourceDir/prematchtopo.tcl" ntPrematchTopoFile
    createLinkSourceFile "$sourceDir/user_setting.tcl" ntUserSettingFile

    ##  Create the default munge scripts.  Will get overwritten with links, if files provided.
    createMungeConfigs


    ##  Not much to go wrong here.
    set ::setupStatus(setupNTsource) 1
    set ::setupStatusInfo(setupNTsource) ""
    .nb.setuptab.f.cnv.win.setupNTsource.status configure -text "OK"

    return 1


}

proc setupStep {name} {
    ##  Execute a setup step

#    logMsg "Info:  $name\n"
    eval $name


}

proc setSetupButtonColor {step color} {
    .nb.setuptab.f.cnv.win.$step.button config -fg $color
    update
}

proc updateSetupStatus {name1 name2 op} {
#    logMsg "Info:  $name1 $name2\n"
    if $::setupStatus($name2) {
	setSetupButtonColor $name2 green
    } else {
	setSetupButtonColor $name2 red
    }

}

proc setupSetupPageRow {name} {
    set fname .nb.setuptab.f.cnv.win.$name
    frame $fname
    pack [button $fname.button -text "$name" -width 15 -justify right -command "setupStep $name" -font MyDefaultFont] -side left
    set ::setupStatusInfo($name) ""
    pack [label $fname.info -textvariable setupStatusInfo($name) -width 90 -justify right -relief sunken -font MyDefaultFont] -side left
    pack [label $fname.status -text "notRun"  -width 20 -justify right -relief sunken -font MyDefaultFont] -side left
    pack $fname
    trace add variable ::setupStatus($name) write updateSetupStatus

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

proc prevCommand {} {
    ##  Gets previous command
    if [info exists ::commandSelected] {
	incr ::commandSelected -1
	if {$::commandSelected < 0} {set ::commandSelected 0}
	.cf.entry delete 0 end
    } else {
	set ::commandSelected [expr [llength $::commandHistory]-1]
    }
    .cf.entry insert end [lindex $::commandHistory $::commandSelected]
}

proc setupStatus {name} {
    set ::setupStatus($name) 0
    set ::setupStatusInfo($name) ""
    setupSetupPageRow "$name"
}

proc parsePvt {PVT} {
    

    if [regexp {^([a-z]+)(\d[0-9p]+)v(\d+)c$} $PVT dummy corner voltage temp] {
	set voltage [regsub "p" $voltage "."]
	logMsg "Info:  parsePVT:  $PVT = $corner $voltage $temp\n"
	return "$corner $voltage $temp"
    }


}

proc nextCommand {} {
    ##  Gets previous command
    set m [expr [llength $::commandHistory]-1]
    if [info exists ::commandSelected] {
	.cf.entry delete 0 end
	incr ::commandSelected
	if {$::commandSelected > $m} {
	    unset ::commandSelected
	    return
	}
	.cf.entry insert end [lindex $::commandHistory $::commandSelected]
    } else {
	## Down hit when already at end.  Do nothing.
    }
}

proc createTabPage {parent} {
    ##  Each tabbed page consists of a scrollable canvas of a fixed size
    ##  Frame to add to is not $parent.f.cnv.win
    global pageWidth
    global pageHeight
    

    frame $parent.f
    canvas $parent.f.cnv -width $pageWidth -height $pageHeight -yscrollcommand [list $parent.f.yscroll set] -xscrollcommand [list $parent.f.xscroll set]
    scrollbar $parent.f.xscroll -orient horizontal -command [list $parent.f.cnv xview]
    scrollbar $parent.f.yscroll -orient vertical -command [list $parent.f.cnv yview]
    grid $parent.f.cnv $parent.f.yscroll -sticky news
    grid $parent.f.xscroll -stick news
    
    set winFrame [frame $parent.f.cnv.win]
    $parent.f.cnv create window 0 0 -anchor nw -window $winFrame
    #    $parent.f.cnv create rectangle 0 0 1500 1500 -fill blue
    #    $parent.f.cnv create line 0 0 1500 500
    #    $parent.f.cnv create line 0 500 1500 0
    #pack [scrollbar $parent.xscroll -orient horizontal -command [list $parent.cnv xview]] -side bottom
    pack $parent.f
    
}

proc setScrollRegion {parent} {
    ##  Sets the scroll region for the canvas for a tab, once the page has been populated.
    global pageWidth
    global pageHeight
    
    $parent.f.cnv configure -scrollregion [list 0 0 [winfo width $parent.f.cnv.win] [winfo height $parent.f.cnv.win]]
}

##  Get absolute path to current script.
set thisScript [info script]
if {[file type $thisScript] == "link"} {set thisScript [file readlink $thisScript]}
set thisScript [file normalize $thisScript]
set scriptPath [regsub {/[^/]+$} $thisScript ""]
#puts $thisScript
#puts $scriptPath

#puts [font actual TkDefaultFont]
set TkDefaultFontAttr [font actual TkDefaultFont]
set TkTextFontAttr [font actual TkTextFont]

##  Mke copy of default font, change size to 10
font create MyDefaultFont {*}$TkDefaultFontAttr
if [info exists scriptArgs(fontSize)] {
    font configure MyDefaultFont -size $scriptArgs(fontSize)
}

##  Check for local config file, load if it exists.
setConfigFromArg runDir "."
setConfigFromArg localConfig "$runDir/alphaNT.config"


## From http://www.tcl.tk/man/tcl8.5/TkCmd/ttk_notebook.htm
#pack [ttk::notebook .nb -height 500 -width 1500]
pack [ttk::notebook .nb]
#.nb add [frame .nb.projtab.f.cnv.win] -text "Project"
.nb add [frame .nb.setuptab] -text "Setup"
.nb add [frame .nb.pvttab] -text "PVTs"
.nb add [frame .nb.srctab] -text "Source"
.nb add [frame .nb.runtab] -text "Run"
.nb add [frame .nb.libtab] -text "Libs"
.nb add [frame .nb.mergetab] -text "Merge"
#.nb add [frame .nb.canvastab] -text "Canvas"
.nb select .nb.setuptab
ttk::notebook::enableTraversal .nb

##  The sizes used for the scrollable workarea under each tab.
set pageWidth 1000
set pageHeight 500
if [info exists scriptArgs(pageHeight)] {set pageHeight $scriptArgs(pageHeight)}
if [info exists scriptArgs(pageWidth)] {set pageWidth $scriptArgs(pageWidth)}

createTabPage .nb.setuptab
createTabPage .nb.pvttab
createTabPage .nb.srctab
createTabPage .nb.runtab
createTabPage .nb.libtab
createTabPage .nb.mergetab

frame .bf
pack [button .bf.exit -text "Exit" -command exitApp -font MyDefaultFont]
pack .bf -side top


frame .tf
pack [text .tf.out -height 20 -width 200 -yscrollcommand ".tf.scroll set" -state disabled -font MyDefaultFont] -side left
pack [scrollbar .tf.scroll -command ".tf.out yview"] -side right -fill y
pack .tf

frame .cf
pack [label .cf.label -text "Command:"] -side left
pack [entry .cf.entry -width 160 -justify left] -side left
pack .cf

#bind .cf.entry  <KeyPress-Return> { executeCommand }
bind .cf.entry  <KeyPress-Return> { executeCommand }
bind .cf.entry  <KeyPress-Up> { prevCommand }
bind .cf.entry  <KeyPress-Down> { nextCommand }

##  Force the top level window to a fixed position.
wm geometry . +20+20


##  Initialize 
if [file exists $localConfig] {
    logMsg "Info: Sourcing $localConfig\n" 
    if [catch "source $localConfig" sourceError] {
	logMsg "Error:  Error sourcing $localConfig\n"
	logMsg "$sourceError\n"
    }
} else {logMsg "Info: No local config \"$localConfig\"\n"}

##  Adjust font size based on config variable
if [info exists ::fontSize] {
    font configure MyDefaultFont -size $::fontSize
}


foreach step {validateProject validateLibCell validateP4 processPVT validatePOCVinfo processSource readPininfo readEquiv processSubckts processPOCVSubckts setupNTsource processNetlists setupRundirs  setupRunPage setupLibPage setupMergedirs setupMergePage } {
    setupStatus $step
}

if {![info exists sessionTitle]} {set sessionTitle [pwd]}
wm title . $sessionTitle

##  Skipping the project setup tab.  Must be correctly defined in the local config, or all else stops.
#queryProject

if [validateProject] {
    logMsg "Info:  Defined project: $projectType/$projectName/$releaseName/$metalStack\n"
    
    #while {!$projectValid} {
    #    tk_messageBox -type ok -message "Project is invalid.  Please correct"
    #    set projectValid 0
    #    .nb select .nb.projtab.f.cnv.win
    #    tkwait variable projectValid
    #} 
    
#    logMsg "Info:  libName=$libName, cellName=$cellName\n"
    
    setConfigFromArg projectConfig "$env(MSIP_PROJ_ROOT)/$projectType/$projectName/$releaseName/design/alphaNT.config"
    
    if [file exists $projectConfig] {
	logMsg "Info: Sourcing $projectConfig\n" 
	if [catch "source $projectConfig" sourceError] {
	    logMsg "Error:  Error sourcing $projectConfig\n"
	    logMsg "$sourceError\n"
	}
    } else {logMsg "Info: No project config \"$projectConfig\"\n"}
    
    ##  Re-source local config, in case there are local overrides of project level stuff
    if [file exists $localConfig] {
	logMsg "Info: Sourcing $localConfig\n" 
	if [catch "source $localConfig" sourceError] {
	    logMsg "Error:  Error sourcing $localConfig\n"
	    logMsg "$sourceError\n"
	}
    }


    if {![validateLibCell]} {logMsg  "Warning: Library/Cell validation failed: {$::setupStatusInfo(validateLibCell)}"}
    if {![validateP4]}      {logMsg  "Warning: P4 setup failed: {$::setupStatusInfo(validateP4)}; p4 functions disabled."}
    if {![processPVT]}      {logMsg  "Error: PVT setup failed: {$::setupStatusInfo(processPVT)}"}
    if {![validatePOCVinfo]}  {logMsg  "Error: POCV validation failed. {$::setupStatusInfo(validatePOCVinfo)}"}
    if {![processSource]}   {logMsg  "Error: Missing or undefined source file: {$::setupStatusInfo(processSource)}"}
    if {![readPininfo]}     {logMsg  "Error: pinInfo file not read: {$::setupStatusInfo(readPininfo)}"}
    if {![readEquiv]}       {logMsg  "Error: equiv file file not read: {$::setupStatusInfo(readEquiv)}"}
    if {![processSubckts]}  {logMsg  "Error: subckt processing failed. {$::setupStatusInfo(processSubckts)}"}
    if {![processPOCVSubckts]}  {logMsg  "Error: POCVsubckt processing failed. {$::setupStatusInfo(processPOCVSubckts)}"}
    if {![setupNTsource]}   {logMsg  "Error: NT source setup failed. {$::setupStatusInfo(setupNTsource)}"}
    if {![processNetlists]} {logMsg  "Error: Netlist processing failed {$::setupStatusInfo(processNetlists)}"}
    if {![setupRundirs]}    {logMsg  "Error: Run dir setup failed, {$::setupStatusInfo(setupRundirs)}"}
    #if {![setupPocvdirs]}    {logMsg  "Error: Run dir setup failed, {$::setupStatusInfo(setupPocvdirs)}"}
   # if {![setupPocvPage]}    {logMsg  "Error: Pocv page setup failed {$::setupStatusInfo(setupPocvPage)}"}
    if {![setupRunPage]}    {logMsg  "Error: Run page setup failed {$::setupStatusInfo(setupRunPage)}"}
    if {![setupLibPage]}    {logMsg  "Error: Lib page setup failed {$::setupStatusInfo(setupLibPage)}"}
    if {![setupMergedirs]}  {logMsg  "Error: Merge dir setup failed, {$::setupStatusInfo(setupMergedirs)}"}
    if {![setupMergePage]}  {logMsg  "Error: Merge page setup failed {$::setupStatusInfo(setupMergePage)}"}
} else {
#    tk_messageBox -type ok -message "Project is invalid: {$setupStatusInfo(validateProject)}"
    logMsg "Error:  Project is invalid\n"
}    

setScrollRegion  .nb.setuptab
setScrollRegion .nb.pvttab
setScrollRegion .nb.srctab
setScrollRegion .nb.runtab
setScrollRegion .nb.libtab
setScrollRegion .nb.mergetab



#foreach cell [array names portOrder] {
#    puts "$cell:"
#    foreach port $portOrder($cell) {puts "\t$port"}
#}


#setConfigFromArg projectConfig "$runDir/alphaNT.config"

#frame .f 

#pack .f
 
##  Just testing the function of the text box and scrollbar
#set f [open "~/.cshrc" r]
#while {![eof $f]} { .tf.out insert end [read $f 1000] }
