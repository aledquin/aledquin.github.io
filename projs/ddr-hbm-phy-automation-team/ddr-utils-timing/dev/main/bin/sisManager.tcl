#!/depot/tk8.6.1/bin/wish

#nolint Main
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
utils__script_usage_statistics $script_name "2022ww21"


variable args
set restart 0

set typeList [list etm]

#  LS_COLORS causes problem for jobs launched on RH5 that land on a RH6 machine (or is it the other way around).  This should resolve it.
if [info exists env(LS_COLORS)] {unset env(LS_COLORS)}

##  List of the recognized source files.  Consider putting this under config file control
set requiredSourceFileList [list instFile netlistFile configFile pvtConfigFile shellScript runScript]
set optionalSourceFileList [list macroRunConfig macroPostProc]

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
} else {set logFile "./sisManager.log"}

if [catch {set LOG [open $logFile "w"]}] {logMsg "Error:  Cannot open $logFile for write\n"}

proc exitApp {} {
    if [info exists ::LOG] {close $::LOG}
    exit
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
	cd "/remote/proj/$::projectType"
	set projectNameGlob [glob -nocomplain -type d "*"]
	cd $cwd
	foreach p [lsort $projectNameGlob] {.nb.projtab.f.cnv.win.name.list.lb insert end $p}
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

proc refreshSourceFileInfo {name required} {
    ##  Refreshes the p4 info label

    set fname .nb.srctab.f.cnv.win.$name
    set val [string trim [$fname.text get]]
#    puts "!!!  $name  $val"
    set fgColor green
    if [file exists $val] {

	set p4info [getP4fileInfo $val]
	set underClient [getP4fileInfoField $p4info "underClient"]
	set depotFile [getP4fileInfoField $p4info "depotFile"]
	set action [getP4fileInfoField $p4info "action"]
	if $underClient {
	    if {$depotFile == ""} {set p4tag "(P4)"} else {set p4tag "P4"}
	    append p4tag " $action"
	} else {
	    set p4tag ""
	    $fname.p4add configure -state disabled
	    $fname.p4edit configure -state disabled
	    $fname.p4submit configure -state disabled
	    $fname.p4revert configure -state disabled
	}
	.nb.srctab.f.cnv.win.$name.p4 config -text "$p4tag"
    } else {
	if $required {
	    set fgColor red
	    .nb.srctab.f.cnv.win.$name.p4 config -text ""
	    set ::setupStatus(processSource) 0
	    lappend ::setupStatusInfo(processSource) "missing_${name}_File"
	}
	$fname.create configure -state disabled
	$fname.edit configure -state disabled
	$fname.p4add configure -state disabled
	$fname.p4add configure -state disabled
	$fname.p4edit configure -state disabled
	$fname.p4submit configure -state disabled
	$fname.p4revert configure -state disabled
    }

    .nb.srctab.f.cnv.win.$name.text config -fg $fgColor
}

proc processPVT {} {

    logMsg "Info:  processPVT\n"
    setSetupButtonColor processPVT blue

    set ::setupStatus(processPVT) 1
    set ::setupStatusInfo(processPVT) ""
    
    set ::pvtCorners [list]
    if [info exists ::pvtConfigFile] {
	if [file readable $::pvtConfigFile] {
	    set CFG [open $::pvtConfigFile r]
	    logMsg "Info:  Reading $::pvtConfigFile\n"
	    while {[gets $CFG line] >= 0} {
		if [regexp {^\s*create_operating_condition\s+(\S+)} $line dmy pvtName] {
		    lappend ::pvtCorners $pvtName
		    logMsg "Info:  Found pvt $pvtName\n"
		}
	    }
	    close $CFG
	} else {
	    ##  Open error
	    logMsg "Error:  $::pvtConfigFile cannot be opened for read"
	    lappend ::setupStatusInfo(processPVT) "pvtConfigFileUnreadable"
	    set ::setupStatus(processPVT) 0
	}
    } else {
	lappend ::setupStatusInfo(processPVT) "pvtConfigFileUndefined"
	set ::setupStatus(processPVT) 0
	logMsg "Error:  pvtConfigFile is undefined"
    }

    if  $::setupStatus(processPVT) {
	set ::setupStatusInfo(processPVT) "Client=$::p4info(client), Port=$::env(P4PORT), Root=$::p4info(clientRoot)"
	.nb.setuptab.f.cnv.win.processPVT.status configure -text "OK"
    } else {
	.nb.setuptab.f.cnv.win.processPVT.status configure -text "Failed"
    }

    return $::setupStatus(processPVT)
}

proc p4SourceFile {cmd name}  {

    #  Perform a p4 command on a given source file.
    set fname .nb.srctab.f.cnv.win.$name
    set val [string trim [$fname.text get]]
    set p4Cmd "p4 $cmd $val"
    set output [exec {*}$p4Cmd]
    logMsg "$output\n"
    refreshSourceFileInfo $name 1

}


proc processSourceFile {name required} {

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
	set file [file normalize $file]
	$fname.text delete 0 end
	$fname.text insert end $file
	##  Check all source files to allow overall status to be defined.
	refreshSourceFileInfo $name $required
    } elseif $required {
	logMsg "Error:  sourceFile variable \"$name\" not defined\n"
	set ::setupStatus(processSource) 0
	lappend ::setupStatusInfo(processSource) "missing_${name}_Definition"
    } else {
	##  A missing, but optional file.
	refreshSourceFileInfo $name $required
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

    logMsg "Info:  processSource\n"
    setSetupButtonColor processSource blue

    set ::setupStatus(processSource) 1
    set ::setupStatusInfo(processSource) ""

    foreach f $::requiredSourceFileList {processSourceFile $f 1}
    foreach f $::optionalSourceFileList {processSourceFile $f 0}

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

    foreach f $::requiredSourceFileList {refreshSourceFileInfo $f 1}
    foreach f $::optionalSourceFileList {refreshSourceFileInfo $f 0}
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


proc findLib {lib} {
    if [info exists ::libPath] {
	foreach dir $::libPath {
	    set srcLib "$dir/$lib"
	    if [file exists $srcLib] { return $srcLib }
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


    set errFound 0
    if [info exists ::mungeScript] {
	if [file exists $::mungeScript] {
	    set cwd [pwd]
	    cd $runDir

	    if [regexp {(\S+)\.lib} $srcLib dummy srcLibRoot] {
		set expLib "${srcLibRoot}_pg.libcleaned"
	    } else {
		set expLib "${srcLib}_cleaned"
	    }
	    ## Munge script annoyingly writes an info message to stderr.
	    deleteFiles $expLib
	    logMsg "Info:  Munging $runDir/$srcLib using $cfg\n"
	    exec $::mungeScript -ignorestderr -lib $srcLib -c $cfg > $id.log 2> $id.err
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

proc runCorner {pvt type force} {
    ##  Runs a corner, type
#    logMsg "Info: Running $pvt $type\n"

    set runDir "./run/char_${pvt}"
    set runscript "run_sis_etm.csh"
    set cmd "./$runscript"
    set status [getRunStatus $pvt $type]
    ##  If status==Complete, only run if forcing.
    ##  Force is on when running from individual button, off when using runAll
    if {!$force && ($status == "Complete")} { 
	logMsg "Info:  Skipping run of $pvt/$type\n"
	return 
    }
    
    if [info exists ::sisQueue] {set cmd [add2CommandLog $cmd "QUEUE=$::sisQueue"]}
    if [info exists ::sisMem]   {set cmd [add2CommandLog $cmd "MEM=$::sisMem"]}
    if [info exists ::sisVmem]   {set cmd [add2CommandLog $cmd "VMEM=$::sisVmem"]}
    if [info exists ::sisExtraSGEArgs]   {set cmd [add2CommandLog $cmd "EXTRASGEARGS=$::sisExtraArgs"]}
    if [info exists ::sisVersion]   {set cmd [add2CommandLog $cmd "SiSversion=$::sisVersion"]}
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
    } else {logMsg "Error:  $runDir/$runscript does not exist\n"}
}

proc editLog {pvt type} {
    set runLog "./run/char_${pvt}/siliconsmart.log"
    if [file exists $runLog] {
	if [info exists ::editor] {set theEditor $::editor} else {set theEditor nedit}
	set cmd "$theEditor $runLog"
	exec {*}$cmd 2> /dev/null
    } else {
	logMsg "Warning:  Logfile \"$runLog\" does not exist\n"
    }
}

proc killCorner {pvt type} {
    ##  Kill a corner, type
#    logMsg "Info: Running $pvt $type\n"

    set runDir "./run/char_${pvt}_$type"
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



proc refreshRunPageRow {pvt} {

    foreach runType $::typeList {
	if [isEtm $runType] {
	    set ms [minorRunSuffix $runType]
	    set f .nb.runtab.f.cnv.win.fr.$pvt
	    set lib "$::outDir/lib/${::cellName}_${::metalStack}_${pvt}.lib"
	    set libPG "$::outDir/lib_pg/${::cellName}_${::metalStack}_${pvt}_pg.lib"
	    set runLog "./run/char_${pvt}/siliconsmart.log"
	    
	    if [file exists $runLog] {$f.editLog_$runType configure -state normal} else {$f.editLog_$runType configure -state disabled}
	    
	    $f.libEntry_$runType delete 0 end
	    if [file exists $lib] {
		set fg green
		set stat "OK"
	    } else {
		set fg red
		set stat "Missing"
	    }
	    $f.libEntry_$runType insert end $stat
	    $f.libEntry_$runType config -fg $fg
	    
	    $f.libEntryPG_$runType delete 0 end
	    if [file exists $libPG] {
		set fg green
		set stat "OK"
	    } else {
		set fg red
		set stat "Missing"
	    }
	    $f.libEntryPG_$runType insert end $stat
	    $f.libEntryPG_$runType config -fg $fg
	}
    }
}

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
	pack [label $fname.status_$runType -text "" -relief sunken -width 10 -font MyDefaultFont] -side left
	pack [label $fname.libLabel_$runType -text "lib" -font MyDefaultFont] -side left
	pack [entry $fname.libEntry_$runType -width 20 -font MyDefaultFont] -side left
	pack [label $fname.libLabelPG_$runType -text "lib_pg" -font MyDefaultFont] -side left
	pack [entry $fname.libEntryPG_$runType -width 20 -font MyDefaultFont] -side left
	pack [button $fname.editLog_$runType -text "editLog" -command "editLog $pvt $runType" -font MyDefaultFont -state disabled] -side left
    }
    refreshRunPageRow $pvt
    return $fname

}

proc runAllCorners {type} {foreach pvt $::pvtCorners {runCorner $pvt $type 0}}

proc killAllCorners {type} {foreach pvt $::pvtCorners {killCorner $pvt $type}}

proc getRunStatus {pvt type} {

    set runDir "./run/char_${pvt}"
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
	    refreshRunPageRow $pvt
	}
    }
}


proc setupRunPage {} {

    logMsg "Info:  setupRunPage\n"
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

    set OUT [open "$dir/pvt_setup.tcl" w]
    puts $OUT "set PROJ_HOME /remote/cad-rep/projects/$::projectType/$::projectName/$::releaseName"
    puts $OUT "set PVT $pvt"
    puts $OUT "set runType $type"
    set scPvt [getPvtField $::cornerData($pvt) scPvt]
    puts $OUT "set scCorner $scPvt"
    puts $OUT "set cellName $::cellName"
    puts $OUT "set metalStack $::metalStack"
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

proc mySymlink {linkName fileNameVar} {
    global $fileNameVar

    if [info exists $fileNameVar] {
	set fileName [set $fileNameVar]
	if {[llength $fileName] > 1} {
	    ##  variable is a list, specifying a linkName to use.
	    set linkName [lindex $fileName 1]
	    set fileName [lindex $fileName 0]
	}
	if [file exists $fileName] {
	    file link -symbolic $linkName $fileName
	} else {
	    logMsg "Error:  File $fileName does not exist\n"
	}
    }
}

proc setupRundirs {} {
    
    logMsg "Info:  setupRundirs\n"
    setSetupButtonColor setupRundirs blue
    set ::setupStatus(setupRundirs) 1
    set ::setupStatusInfo(setupRundirs) ""
    
    if {![info exists ::outDir]} {
	##  outDir not specified.  Default to ./liberty
	set ::outDir "./liberty"
    }
    if {![file exists $::outDir]} {file mkdir $::outDir}
    set ::outDir [file normalize $::outDir]
    
    set cwd [pwd]
    if {!$::restart} {
	logMsg "Info:  Setting up run directories from scratch\n"
	if {[info exists ::runDir]} {
	    set ::runDir [file normalize $::runDir]
	    logMsg "Info:  runDir = $::runDir\n"
	    if {![file exists $::runDir]} {
		file mkdir $::runDir
	    }
	    if [file exists run] {
		if [file isdir run] {exec rm -rf run} else [file delete run]
	    }
	    file link -symbolic run $::runDir
	} else {
	    set ::runDir [file normalize "./run"]
	}
	foreach pvt $::pvtCorners {
	    logMsg "Info:  Creating run dir for $pvt\n"
	    set dir [file normalize "$::runDir/char_$pvt"]
	    if [file exists $dir] {exec rm -rf $dir}
	    file mkdir $dir
	    cd $dir
	    mySymlink $::cellName.spf netlistFile 
	    mySymlink $::cellName.inst instFile 
	    mySymlink commonSetup.tcl commonSetup
	    mySymlink commonSetupProj.tcl  commonSetupProj
	    mySymlink run_char.tcl  runScript
	    mySymlink run_sis_etm.csh  shellScript
	    mySymlink macroRunConfig.tcl macroRunConfig
	    mySymlink macroPostProc.tcl macroPostProc
	    
	    ##  Deal with the config. Copy, replacing the active_pvts list with a single pvt.
	    if [info exists ::configFile] {
		set SRC [open $::configFile r]
		set DST [open configure.tcl w]
		while {[gets $SRC line] >= 0} {
		    if [regexp {^(\s*)set\s+(::)?active_pvts} $line dmy indent gbl] {
			puts $DST "${indent}set active_pvts $pvt"
		    } else {
			puts $DST $line
		    }
		}
		close $SRC
		close $DST
		
	    } else {

	    }
	    
	    set macroConfig "macroSetup.tcl"
	    set CFG [open $macroConfig w]
	    puts $CFG "# Config for cell $::cellName"
	    puts $CFG "set cellName $::cellName"
	    puts $CFG "set metalStack $::metalStack"
	    puts $CFG "set active_pvts $pvt"
	    close $CFG
	    
	    ##  Create link to $::outDir as "liberty" in run dir.
	    ##  Standard flow writes to the liberty dir
	    file link -symbolic "liberty" $::outDir
	    set libFile "liberty/lib/${::cellName}_${::metalStack}_${pvt}.lib"
	    set libFilePG "liberty/lib_pg/${::cellName}_${::metalStack}_${pvt}_pg.lib"
	    ##  Predelete old lib files to prevent issues with staleness
	    if [file exists $libFile] {file delete $libFile}
	    if [file exists $libFilePG] {file delete $libFilePG}
	    cd $cwd
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
setConfigFromArg localConfig "$runDir/alphaSiS.config"


## From http://www.tcl.tk/man/tcl8.5/TkCmd/ttk_notebook.htm
#pack [ttk::notebook .nb -height 500 -width 1500]
pack [ttk::notebook .nb]
#.nb add [frame .nb.projtab.f.cnv.win] -text "Project"
.nb add [frame .nb.setuptab] -text "Setup"
#.nb add [frame .nb.pvttab] -text "PVTs"
.nb add [frame .nb.srctab] -text "Source"
.nb add [frame .nb.runtab] -text "Run"
#.nb add [frame .nb.libtab] -text "Libs"
#.nb add [frame .nb.canvastab] -text "Canvas"
.nb select .nb.setuptab
ttk::notebook::enableTraversal .nb

##  The sizes used for the scrollable workarea under each tab.
set pageWidth 1600
set pageHeight 500
if [info exists scriptArgs(pageHeight)] {set pageHeight $scriptArgs(pageHeight)}
if [info exists scriptArgs(pageWidth)] {set pageWidth $scriptArgs(pageWidth)}

createTabPage .nb.setuptab
#createTabPage .nb.pvttab
createTabPage .nb.srctab
createTabPage .nb.runtab
#createTabPage .nb.libtab

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

    setConfigFromArg projectConfig ""
    
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

##  Adjust font size based on config variable
if [info exists ::fontSize] {
    font configure MyDefaultFont -size $::fontSize
}

foreach step {validateProject validateLibCell validateP4 processPVT processSource setupRundirs setupRunPage} {
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
    

    if {![validateLibCell]} {logMsg  "Warning: Library/Cell validation failed: {$::setupStatusInfo(validateLibCell)}"}
    if {![validateP4]}      {logMsg  "Warning: P4 setup failed: {$::setupStatusInfo(validateP4)}; p4 functions disabled."}
    if {![processPVT]}      {logMsg  "Error: PVT setup failed: {$::setupStatusInfo(processPVT)}"}
    if {![processSource]}   {logMsg  "Error: Missing or undefined source file: {$::setupStatusInfo(processSource)}"}
#    if {![readPininfo]}     {logMsg  "Error: pinInfo file not read: {$::setupStatusInfo(readPininfo)}"}
#    if {![readEquiv]}       {logMsg  "Error: equiv file file not read: {$::setupStatusInfo(readEquiv)}"}
#    if {![processSubckts]}  {logMsg  "Error: subckt processing failed. {$::setupStatusInfo(processSubckts)}"}
#    if {![setupNTsource]}   {logMsg  "Error: NT source setup failed. {$::setupStatusInfo(setupNTsource)}"}
#    if {![processNetlists]} {logMsg  "Error: Netlist processing failed {$::setupStatusInfo(processNetlists)}"}
    if {![setupRundirs]}    {logMsg  "Error: Run dir setup failed, {$::setupStatusInfo(setupRundirs)}"}
    if {![setupRunPage]}    {logMsg  "Error: Run page setup failed {$::setupStatusInfo(setupRunPage)}"}
#    if {![setupLibPage]}    {logMsg  "Error: Lib page setup failed {$::setupStatusInfo(setupRunPage)}"}
#    if {![setupMergedirs]}  {logMsg  "Error: Merge dir setup failed, {$::setupStatusInfo(setupMergedirs)}"}
#    if {![setupMergePage]}  {logMsg  "Error: Merge page setup failed {$::setupStatusInfo(setupRunPage)}"}
} else {
#    tk_messageBox -type ok -message "Project is invalid: {$setupStatusInfo(validateProject)}"
    logMsg "Error:  Project is invalid\n"
}    

setScrollRegion .nb.setuptab
#setScrollRegion .nb.pvttab
setScrollRegion .nb.srctab
setScrollRegion .nb.runtab
#setScrollRegion .nb.libtab
