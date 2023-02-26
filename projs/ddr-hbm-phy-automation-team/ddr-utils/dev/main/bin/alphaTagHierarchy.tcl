#!/depot/tcl8.5.12/bin/tclsh8.5

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


namespace eval ::alpha::tag {
    ##  Some common routines
    
    set thisScript [file normalize [info script]]
    set scriptPath [file dirname $thisScript]
    set dialogScript "$scriptPath/alphaTagHierarchy_dialog.tcl"
    if {![file exists $dialogScript]} {set dialogScript "./alphaTagHierarchy_dialog.tcl"}
    if {![file exists $dialogScript]} {
	de::sendMessage  "Cannot find alphaTagHierarchy_dialog.tcl" -severity "error"
	set dialogScript ""
    }
    
    proc getLibList {} {
	##  Gets a simple list of all libs
	return [db::createList [dm::getLibs *]]
    }

    proc xx {} {
	set ll [getLibList]
	foreach l $ll {
	    set libName [db::getAttr name -of $l]
	    set libPath [db::getAttr fullPath -of $l]
	    puts "$libName:  $libPath"
	}
    }
    
    proc errorReview {errorList title} {
	set errConfig "errorReview.cfg.tmp"
	set CFG [open $errConfig w]
	puts $CFG "set title \"$title\""
	set i 1
	foreach err $errorList {
	    puts $CFG "set errorList($i) {$err}"
	    incr i
	}
	close $CFG
	
	set dialogInfo "noErrors"
	if {[llength staleList] > 0} {
	    set dialogInfo [exec $alpha::tag::dialogScript errorReview $errConfig]
	    file delete $errConfig
	}
	return $dialogInfo
    }
    
    proc stripCommon {fileName root} {
	##  Strips the common root from filename, assuming it's at the beginning.
	if {[string first $root $fileName] == 0} {
	    return [string replace $fileName 0 [string length $root] ""]
	}
	return $fileName
    }

    proc verifyProceed {message} {
	set cfgFile "VerifyProced.cfg.tmp"
	set CFG [open $cfgFile w]
	puts $CFG "set title Confirmation"
	puts $CFG "set message \"$message\""
	close $CFG
	set dialogInfo [exec $alpha::tag::dialogScript runConfirmation $cfgFile]
	file delete $cfgFile
	if {$dialogInfo == ""} {return 0}
	if {$dialogInfo == "PROCEED"} {return 1}
	if {$dialogInfo == "ABORT"} {return 0}
	de::sendMessage  $dialogInfo -severity error
	return 0
    }

    variable errorMask
    set errorMask(OPENED_OA)      0x00000001
    set errorMask(ABORTED)        0x00000002
    set errorMask(LIB_UNMANAGED)  0x00000004
    set errorMask(ERRORS_IGNORED) 0x00000008
    set errorMask(UNKNOWN_ERROR)  0x00000010
    set errorMask(NO_VIEWS)       0x00000020

    proc setErrorCode {old code} {
	##  Sets a bit-mask code, returning the new value.
	
	variable errorMask

	if {[info exists errorMask($code)]} {
	    return [expr {$old | $errorMask($code)}]
	} else {
	    de::sendMessage  "Unrecognized error code \"$code\"" -severity error
	    return $old
	}
    }

    proc getErrorCode {old code} {
	##  Sets a bit-mask code, returning the new value.
	
	variable errorMask
   
	if [info exists errorMask($code)] {
	    return [expr {$old & $errorMask($code)}]
	} else {
	    de::sendMessage  "Unrecognized error code \"$code\"" -severity error
	    return 0
	}
    }

    proc tagGuiProcess {dialog} {


	set libName [ db::getAttr value -of [ gi::findChild alphaTagHierLibName  -in $dialog ] ]
        set cellName [ db::getAttr value -of [ gi::findChild alphaTagHierCellName  -in $dialog ] ]
        set schViewName [ db::getAttr value -of [ gi::findChild alphaTagHierSchView  -in $dialog ] ]
        set layViewName [ db::getAttr value -of [ gi::findChild alphaTagHierLayView  -in $dialog ] ]
        set symViewName [ db::getAttr value -of [ gi::findChild alphaTagHierSymView  -in $dialog ] ]
        set checkinTag [ db::getAttr value -of [ gi::findChild alphaTagHierCheckinEnable  -in $dialog ] ]
        set checkAllClients [ db::getAttr value -of [ gi::findChild alphaTagHierCheckAllClient  -in $dialog ] ]
        set warnNonLatest [ db::getAttr value -of [ gi::findChild alphaTagHierWarnNonLatest  -in $dialog ] ]

	set proceed 1
	if {($schViewName == "") && ($layViewName == "") && ($symViewName == "")} {
	    de::sendMessage  "No views selected; tag generation stopped" -severity "warning"
	    set proceed 0
	} else {
	    if {($schViewName == "")} {
		    de::sendMessage  "No schematic view selected; tag will be layout-only" -severity "warning"
	    } else {
		    if {![oa::DesignExists $libName $cellName $schViewName]} {
		        de::sendMessage  "$libName/$cellName/$schViewName does not exist" -severity "error"
		        set proceed 0
		    }
	    }
	    if {($layViewName == "")} {
		    de::sendMessage  "No layout view selected; tag will be schematic-only" -severity "warning"
	    } else {
		    if {![oa::DesignExists $libName $cellName $layViewName]} {
		        de::sendMessage  "$libName/$cellName/$layViewName does not exist" -severity "error"
		        set proceed 0
		    }
	    }
	    if {($symViewName == "")} {
		    de::sendMessage  "No symbol view selected" -severity "warning"
	    } else {
		    if {![oa::DesignExists $libName $cellName $symViewName]} {
		        de::sendMessage  "$libName/$cellName/$symViewName does not exist" -severity "error"
		        set proceed 0
		    }
	    }
	}
	
	if $proceed {
	    alpha::tag::tagHierarchy -libName $libName -cellName $cellName -schView $schViewName -layView $layViewName -symView $symViewName \
		-checkin $checkinTag -checkAllClients $checkAllClients -warnNonLatest $warnNonLatest
	}
    }

    proc syncTagGuiProcess {dialog} {
	set libName [ db::getAttr value -of [ gi::findChild alphaSyncTagHierLibName  -in $dialog ] ]
        set cellName [ db::getAttr value -of [ gi::findChild alphaSyncTagHierCellName  -in $dialog ] ]

	alpha::tag::syncTagHierarchy -libName $libName -cellName $cellName
    }

    proc refreshCellList {args} {
	##  Refreshes the list of cells when the library is set.

	set dialog [lindex $args 0]
	set cellNameWidget [gi::findChild alphaTagHierCellName  -in $dialog]
        set libName [ db::getAttr value -of [ gi::findChild alphaTagHierLibName  -in $dialog ] ]
        set currentCellName [ db::getAttr value -of $cellNameWidget ]
	set cellList [dm::getCells -libName $libName]
	set cellNameList [list ""]
	db::foreach cell $cellList {lappend cellNameList [db::getAttr name -of $cell]}
	set cellNameList [lsort $cellNameList]
	db::setAttr enum -of $cellNameWidget -value $cellNameList
#	if {[lsearch -exact $cellNameList $currentCellName] < 0} {
#	    catch {db::setAttr value -of $cellNameWidget -value ""}
#	}
    }

    proc refreshSyncCellList {args} {
	##  Refreshes the list of cells when the library is set.

	set dialog [lindex $args 0]
	set cellNameWidget [gi::findChild alphaSyncTagHierCellName  -in $dialog]
        set libName [ db::getAttr value -of [ gi::findChild alphaSyncTagHierLibName  -in $dialog ] ]
        set currentCellName [ db::getAttr value -of $cellNameWidget ]
	set cellList [dm::getCells -libName $libName]
	set cellNameList [list ""]
	db::foreach cell $cellList {lappend cellNameList [db::getAttr name -of $cell]}
	set cellNameList [lsort $cellNameList]
	db::setAttr enum -of $cellNameWidget -value $cellNameList
#	if {[lsearch -exact $cellNameList $currentCellName] < 0} {
#	    catch {db::setAttr value -of $cellNameWidget -value ""}
#	}
    }

    proc refreshCellviewList {args} {

	##   Refreshes view lists
	set dialog [lindex $args 0]
        set libName [ db::getAttr value -of [ gi::findChild alphaTagHierLibName  -in $dialog ] ]
        set cellName [ db::getAttr value -of [ gi::findChild alphaTagHierCellName  -in $dialog ] ]

        set currentLayoutView [ db::getAttr value -of [ gi::findChild alphaTagHierLayView -in $dialog ] ]
        set currentSchematicView [ db::getAttr value -of [ gi::findChild alphaTagHierSchView  -in $dialog ] ]
        set currentSymbolView [ db::getAttr value -of [ gi::findChild alphaTagHierSymView  -in $dialog ] ]

	set cellViewList [dm::getCellViews -cellName $cellName -libName $libName]
	set layoutViewList [list ""]
	set schematicViewList [list ""]
	set symbolViewList [list ""]
	db::foreach cellView $cellViewList {
	    set name [db::getAttr name -of $cellView]
	    set type [db::getAttr viewType -of $cellView]
	    if {$type == "schematic"} {lappend schematicViewList $name} elseif {$type == "maskLayout"} {lappend layoutViewList $name} elseif {$type == "schematicSymbol"} {lappend symbolViewList $name}
	}
	
	if {[lsearch -exact $schematicViewList $currentSchematicView] < 0} {
	    db::setAttr value -of [ gi::findChild alphaTagHierSchView -in $dialog] -value ""
	}
	if {[lsearch -exact $layoutViewList $currentLayoutView] < 0} {
	    db::setAttr value -of [ gi::findChild alphaTagHierLayView -in $dialog] -value ""
	}
	if {[lsearch -exact $symbolViewList $currentSymbolView] < 0} {
	    db::setAttr value -of [ gi::findChild alphaTagHierSymView -in $dialog] -value ""
	}

	set schematicViewList [lsort $schematicViewList]
	set layoutViewList [lsort $layoutViewList]
	set symbolViewList [lsort $symbolViewList]
	db::setAttr enum -of [ gi::findChild alphaTagHierSchView -in $dialog] -value $schematicViewList
	db::setAttr enum -of [ gi::findChild alphaTagHierLayView -in $dialog] -value $layoutViewList
	db::setAttr enum -of [ gi::findChild alphaTagHierSymView -in $dialog] -value $symbolViewList
    }
    
    proc alphaHierSyncTagGui {} {
	set dialog [gi::createDialog tagDialog -title "alphaSyncTagHierarchy" -showApply 0 -execProc [list alpha::tag::syncTagGuiProcess] -showHelp 0 ]
	
	set libList {}
	foreach lib [db::createList [dm::getLibs *]] {lappend libList [db::getAttr name -of $lib]}
	set libList [lsort $libList]
	
	set sel [dm::getSelected];
        if {"dmCell" == [db::getAttr type -of $sel]} {
            set cellName [db::getAttr name -of  $sel]
	} else {
	    de::sendMessage  "Expected dmCell" -severity "error"
	    return
        }
	set libName [db::getAttr libName -of  $sel]

	gi::createMutexInput "alphaSyncTagHierLibName" \
            -parent $dialog \
            -label "Library" \
            -enum $libList \
	    -value $libName \
	    -comboWidth 50 \
	    -viewType combo \
	    -valueChangeProc [list alpha::tag::refreshSyncCellList $dialog]

	gi::createMutexInput "alphaSyncTagHierCellName" \
            -parent $dialog \
            -label "Cell" \
	    -value $cellName \
	    -enum {} \
	    -viewType combo \
	    -comboWidth 50

	refreshSyncCellList $dialog
    }

    proc alphaHierTagGui {} {
	set dialog [gi::createDialog tagDialog -title "alphaTagHierarchy" -showApply 0 -execProc [list alpha::tag::tagGuiProcess] -showHelp 0 ]
	
	set libList {}
	foreach lib [db::createList [dm::getLibs *]] {lappend libList [db::getAttr name -of $lib]}
	set libList [lsort $libList]
	
	set sel [dm::getSelected];
        if {"dmCell" == [db::getAttr type -of $sel]} {
            set cellName [db::getAttr name -of  $sel]
	} else {
	    de::sendMessage  "Expected dmCell" -severity "error"
	    return
        }
	set libName [db::getAttr libName -of  $sel]

	gi::createMutexInput "alphaTagHierLibName" \
            -parent $dialog \
            -label "Library" \
            -enum $libList \
	    -value $libName \
	    -comboWidth 50 \
	    -viewType combo \
	    -valueChangeProc [list alpha::tag::refreshCellList $dialog]

	gi::createMutexInput "alphaTagHierCellName" \
            -parent $dialog \
            -label "Cell" \
	    -value $cellName \
	    -enum {} \
	    -viewType combo \
	    -comboWidth 50 \
	    -valueChangeProc [list alpha::tag::refreshCellviewList $dialog]

	refreshCellList $dialog

	gi::createMutexInput "alphaTagHierSchView" \
            -parent $dialog \
            -label "Schematic View" \
            -enum {} \
	    -value "schematic" \
	    -comboWidth 12 \
	    -viewType combo

	gi::createMutexInput "alphaTagHierLayView" \
            -parent $dialog \
            -label "Layout View" \
            -enum {} \
	    -value "layout" \
	    -comboWidth 12 \
	    -viewType combo

	gi::createMutexInput "alphaTagHierSymView" \
            -parent $dialog \
            -label "Symbol View" \
            -enum {} \
	    -value "symbol" \
	    -comboWidth 12 \
	    -viewType combo

	refreshCellviewList $dialog
	
	gi::createBooleanInput "alphaTagHierCheckinEnable" \
	    -parent $dialog \
	    -label "Check-in Tag File" \
	    -value true

	gi::createBooleanInput "alphaTagHierCheckAllClient" \
	    -parent $dialog \
	    -label "Check All Clients" \
	    -value false

	gi::createBooleanInput "alphaTagHierWarnNonLatest" \
	    -parent $dialog \
	    -label "Check for non-latest" \
	    -value false
    }
}


namespace eval ::alpha::tag::tagHierarchy {

    #####  Namespace globals
    ## lists of minimum required files for each viewType, defined just below
    variable requiredViewFiles
    ##  Simple list of managed libraries.
    variable managedLibList
    ##  Hashes used during hierarchy 
    variable cellViewHash
    variable libHash
    variable libOpenedList
    variable libHaveList
    variable libDepotPath
    variable libIsManaged
    variable managedCellviewList
    ##  character map for "special" chars that get converted to something else in the file name
    variable fileCharMap
    
    set fileCharMap {. #2e - #2d}

    set requiredViewFiles(schematic) [list master.tag sch.oa]
    set requiredViewFiles(maskLayout) [list master.tag layout.oa]
    set requiredViewFiles(schematicSymbol) [list master.tag symbol.oa]
    
    proc dbgPrint {line} {puts "DBG: $line"}

    proc closeButtonPush {cvid 0} {
    }

    proc buttonPush {{cvid 0} dialog buttonname} {
	puts "cvid=$cvid, dialog=$dialog buttonname=$buttonname"
	catch {db::destroy $dialog}
    }

    proc getHierCellviews {topLibName topCellName topViewNames checkExists} {
	
	variable cellViewHash
	variable libHash
	variable fileCharMap

	foreach topViewName $topViewNames {
	    if [oa::DesignExists $topLibName $topCellName $topViewName] {
		set design [oa::DesignOpen $topLibName $topCellName $topViewName r]
		##  design attrs:
		##  
		set viewType [db::getAttr viewType -of $design]
		##  Remap the few special characters.
		set topCellNameFile [string map $fileCharMap $topCellName]
		set topViewNameFile [string map $fileCharMap $topViewName]
		set aggCellView "$topLibName $topCellNameFile/$topViewNameFile $viewType"
		set cellViewHash($aggCellView) 1
		set libHash($topLibName) 1
		set insts [db::getInsts -of $design]
		db::foreach oaInst $insts {
		    set pin [db::getAttr pin -of $oaInst]
		    set isPin [string compare $pin ""]
		    if {!$isPin} {
			set libName [db::getAttr libName -of $oaInst]
			set cellName [db::getAttr cellName -of $oaInst]
			set viewName [db::getAttr viewName -of $oaInst]
#			set viewTypeI [db::getAttr type -of $oaInst]
			set viewType ""
			##  This sometimes master is sometimes empty for some layout. Not sure why.
			catch {set viewType [db::getAttr viewType -of [db::getAttr master -of $oaInst]]}
			#	    set instName [db::getAttr name -of $oaInst]
			## assignments autoAbutment bBox blockagesOwnedBy cellName constraintGroup design dummy figGroupMem groupLeaders groupMems groupsOwnedBy header implicit inst
			## instTerms libName master name net numBits orient orientation origin params physicalOnly pin placementStatus priority props shape source this transform type viewName
			#	    puts [db::listAttrs -of $oaInst]	
			if {$viewType == "schematicSymbol"} {lappend viewName "schematic"}
			getHierCellviews $libName $cellName $viewName 0
		    }
		}
	    } elseif $checkExists {
		de::sendMessage  "$topLibName/$topCellName/$topViewName does not exist" -severity "error"
	    }
	}
	return
    }
    
    
    proc getLibInfo {libList checkAllClients} {
	
	variable managedLibList
	variable libOpenedList
	variable libHaveList
	variable libDepotPath
	variable libIsManaged
	variable managedCellviewList
	variable cellViewHash
	
	#    puts "{$libList}"
	set clientroot [file normalize [exec p4 -F %clientRoot% -ztag info]]
	
	set managedLibList {}
	array unset libHaveList
	array unset libOpenedList
	array unset libDepotPath
	foreach libName $libList {
	    array unset haveArray
	    array unset openedArray
	    set libHaveList($libName) {}
	    set libOpenedList($libName) {}
	    set lib [dm::getLibs $libName]
	    set libPathClient [file normalize [db::getAttr fullPath -of $lib]]
	    set libProps [db::getAttr props -of $lib]
	    ## lib Attrs: accessLevel constraintGroup fullPath groupLeaders groupMems groupsOwnedBy hasAutoLoad loaded mode name path props readable statusIcon this type writable writePath
	    set libPathDepot {}
	    ##  Strange p4 behavior:  p4 where $libPathClient will sometimes think it's not under the client. adding /... is more reliable. Not sure why
	    catch {set libPathDepot [exec p4 where $libPathClient/... 2> /dev/null]}
	    if {$libPathDepot == ""} {
		set libIsManaged($libName) 0
		set libDepotPath($libName) ""
	    } else {
		##  A managed library.
		##  Get rid of the "/..." to get simple paths.
		set libPathDepot [regsub -all {/\.\.\.} $libPathDepot ""]
		lappend managedLibList $libName
		set libPathDepot [lindex $libPathDepot 0]
		set libIsManaged($libName) 1
		set libDepotPath($libName) $libPathDepot
		##  Get the "p4 have" info for this library
		foreach haveSpec [split [exec p4 have "$libPathClient/..."] "\n"] {
		    set depotFile [lindex $haveSpec 0]
		    set depotFile [alpha::tag::stripCommon $depotFile $libPathDepot]
		    set t [split $depotFile "/"]
		    if {[llength $t] == 3} {
			##  A file that's under a view dir
			set cellView "[lindex $t 0]/[lindex $t 1]"
			set t [lreplace $t 0 1]
			set file [join $t "/"]
			lappend haveArray($cellView) $file
		    } elseif {$t == 0} {
			##  Can't happen?
		    } elseif {$t == 2} {
			##  File at the cell level.  Ignore?
		    } elseif {$t == 1} {
			## A file at thetop library level, like data.dm  Ignore?
		    } else {
			##  Hops this can't happen either.
		    }
		}
		#	    puts "Library haves for $libName:"
		#	    foreach cellView [array names haveArray] {
		#		puts "\t $cellView: {$haveArray($cellView)}"
		#	    }
	    }
	    
	    set libHaveList($libName) [array get haveArray]
	    
	    set libOpened {}
	    if $checkAllClients {
		catch {set libOpened [exec p4 opened -as "$libPathClient/..." 2> /dev/null]}
		set openPatt {^(\S+).* by (\S+)@}
	    } else {
		catch {set libOpened [exec p4 opened -s "$libPathClient/..." 2> /dev/null]}
		set openPatt {^(\S+)}
	    }
	    foreach line [split $libOpened "\n"] {
		if [regexp $openPatt $line dummy openedFileDepot openedFileUser] {
		    set openedFileDepot [alpha::tag::stripCommon $openedFileDepot $libPathDepot]
		    set t [split $openedFileDepot "/"]
		    if {[llength $t] == 3} {
			##  A file that's under a view dir
			set cellView "[lindex $t 0]/[lindex $t 1]"
			set t [lreplace $t 0 1]
			set file [join $t "/"]
			lappend openedArray($cellView) [list $file $openedFileUser]
		    } elseif {$t == 0} {
			##  Can't happen?
		    } elseif {$t == 2} {
			##  File at the cell level.  Ignore?
		    } elseif {$t == 1} {
			## A file at thetop library level, like data.dm  Ignore?
		    } else {
			##  Hops this can't happen either.
		    }
		}
	    }
	    set libOpenedList($libName) [array get openedArray]
	}
	
	##  Build managedCellviewList, only cellviews in managed libraries.
	set managedCellviewList {}
	foreach cellView [lsort [array names cellViewHash]] {
	    set libName [lindex $cellView 0]
	    if $libIsManaged($libName) {lappend managedCellviewList $cellView}
	}
    }
    
    proc checkHaveCompleteness {libName cellView viewType haveList tagErr} {
	##  Checks the list of files present in a cellview against the minimum list of required ones.
	
	variable requiredViewFiles

	set errs {}
	##  Build hash of files in the have list
	foreach fn $haveList {
	    set t [split $fn "#"]
	    set fr [lindex $t 0]
	    set hh($fr) 1
	}

	set tCellName [lindex [split $cellView "/"] 0]
        set tagErr $tagErr
        set EERR [open $tagErr a]
	## Then make sure all required files are present
	if [info exists requiredViewFiles($viewType)] {
	    foreach rf $requiredViewFiles($viewType) {
		if {![info exists hh($rf)]} {
		    ##  Required file not present
		    puts $EERR "$libName/$cellView/$viewType is missing"
		    lappend errs [list $libName $cellView $rf "Required file missing"]
		}
	    }
	} else {
            puts $EERR "$libName/$cellView - unknown viewType \"$viewType\""
	    lappend errs [list $libName $cellView "" "Unknown viewType $viewType"]
	}
	close $EERR
	return $errs
    }
    
    proc checkHaves { tagErr } {
	##  Checks the hierarchy cellview list against the have list, buiding a tag file and error file
	
	variable managedLibList
	variable libHaveList
	variable libDepotPath
	variable libCellviewList

	set errors {}
	set haveFiles {}
	foreach libName $managedLibList {
	    array set haves $libHaveList($libName)
	    foreach cv $libCellviewList($libName) {
		set cellView [lindex $cv 0]
		set viewType [lindex $cv 1]
		set tCellName [lindex [split $cellView "/"] 0]
		if [info exists haves($cellView)] {
		    ##  cellview found in haves list.
		    set errs [checkHaveCompleteness $libName $cellView $viewType $haves($cellView) $tagErr]
		    if {$errs != ""} {lappend errors $errs}
		    foreach have $haves($cellView) {
			lappend haveFiles "$libDepotPath($libName)/$cellView/$have"
		    }
		} else {
		    set tagErr $tagErr
		    set EERR [open $tagErr a]
		    puts $EERR "$libName/$cellView - Unmanaged cellview"
		    lappend errors [list $libName $cellView "" "Unmanaged cellview"]
		    close $EERR
		}
	    }
	}
	return [list $haveFiles $errors]
    }
    
    proc checkOpened { tagErr } {
	##  Checks for opened files in the hierarchy cellviews.
	variable managedLibList
	variable libOpenedList
	variable libCellviewList
	
	set errs {}
	foreach libName $managedLibList {
	    array set opened $libOpenedList($libName)
	    foreach cvs $libCellviewList($libName) {
		set cv [lindex $cvs 0]
		if [info exists opened($cv)] {
		    set tCellName [lindex [split $cv "/"] 0]
		    set tagErr $tagErr
		    set EERR [open $tagErr a]
		    puts $EERR "$libName/$cv is checked-out"
		    foreach xx $opened($cv) {
			set file [lindex $xx 0]
			lappend errs [list $libName $cv $file "Opened by [lindex $xx 1]"]
		    }
		    close $EERR
		}
	    }
	}
	return $errs
    }

    proc execSubmit {args} {
	## alphaTagHierarchy
	
	set tagFileDepot [lindex $args 0]
	set dialog [lindex $args 1]
	if {$dialog == ""} {
	    ##  Command-provided comment
	    set comment [lindex $args 2]
	} else {
	    set comment [gi::findChild desc.value -in $dialog];
	}
	exec p4 submit -d $comment $tagFileDepot 
	
	return
    }
    
    proc warnNonLatest {tagInfo} {

	set libList [alpha::tag::getLibList]
	foreach lib $libList {
	    set libName [db::getAttr name -of $lib]
	    set libPathClient [db::getAttr fullPath -of $lib]
	    set libPathDepot ""
	    catch {set libPathDepot [exec p4 where $libPathClient/...]}
	    if {$libPathDepot != ""} {
		##  Lib is managed
		set libPathDepot [regsub -all {/\.\.\.} $libPathDepot ""]
		set libPathDepot [lindex $libPathDepot 0]
		set libPath($libName) $libPathDepot
	    }
	}

	array unset usedLibHash
	foreach tagMember $tagInfo {
	    foreach libName [array names libPath] {
		set len [string length $libPath($libName)]
		if {[string first $libPath($libName) $tagMember] == 0} {
		    ##  Tagmember is in $libName
		    set usedLibHash($libName) 1
		    set fileNameFull [string replace $tagMember 0 $len]
		    regexp {(.*)#(\d+)} $fileNameFull dmy fileName fileVersion
		    lappend tagInfoParsed($libName) [list $fileName $fileVersion]
		    break
		}
	    }
	}
	set usedLibs [array names usedLibHash]

	foreach libName $usedLibs {
	    set libPathDepot $libPath($libName)
	    set filelog ""
	    set filelog [split [exec p4 filelog -t -m 1 -s $libPathDepot/...] "\n"]
	    array unset latest
	    foreach line $filelog {
		if [regexp {^(//\S+)} $line dummy depotFile] {
		    ##  the file
		    set depotFile [alpha::tag::stripCommon $depotFile $libPathDepot]
		} elseif [regexp {^\.\.\. \#(\d+) change (\d+) (\S+) on (\S+) (\S+) by (\S+)} $line dummy version changelist action date time client] {
		    ##  Filelog as executed above appears to include deleted files. Ignore these
		    if {$action != "delete"} {
			set latest($depotFile) $version
		    }
		}
	    }
	    set libLatest($libName) [array get latest]
	}

	array unset latest
	set staleList {}
	foreach libName [array names tagInfoParsed] {
	    array set latest $libLatest($libName)
	    foreach tagRec $tagInfoParsed($libName) {
		set fileName [lindex $tagRec 0]
		set fileVersion [lindex $tagRec 1]
		if [info exists latest($fileName)] {
		    if {$fileVersion != $latest($fileName)} {
			set lVer $latest($fileName)
			set t [split $fileName "/"]
			set fileName [lindex $t end]
			set t [lreplace $t end end]
			set cellView [join $t "/"]
			lappend staleList [list $libName $cellView $fileName "version $fileVersion != $lVer"]
		    }
		} else {
		    de::sendMessage  "Cannot latest info on $libName/$fileName" -severity "error"
		}
	    }
	}

	if {[llength $staleList] > 0} {
	    set dialogInfo [alpha::tag::errorReview $staleList "Review files that are not latest"]
	    if {$dialogInfo == ""} {
		return 0
	    } elseif {$dialogInfo == "IGNORE"} {
		return 1
	    } elseif {$dialogInfo == "ABORT"} {
		return 0
	    } else {
		return 0
	    }
	} else {return 1}
    }

    proc execute {args} {

	variable cellViewHash
	variable managedLibList
	variable libHash
	variable managedCellviewList
	variable libCellviewList
	variable libIsManaged
	variable libDepotPath
	
	if {$alpha::tag::dialogScript == ""} {
	    return
	}

	##  Return status info
	set returnMessage ""
	set errorStatus 0
	
	array set myArgs $args
	set libName $myArgs(-libName)
	set cellName $myArgs(-cellName)
	set viewNames [list]
	if {$myArgs(-schView) != ""} {lappend viewNames $myArgs(-schView)}
	if {$myArgs(-layView) != ""} {lappend viewNames $myArgs(-layView)}
	if {$myArgs(-symView) != ""} {lappend viewNames $myArgs(-symView)}
	
	if {[llength $viewNames] == 0} {
	    de::sendMessage  "No views provided" -severity "warning"
	    set errorStatus [alpha::tag::setErrorCode $errorStatus NO_VIEWS]
	    return [list "" $errorStatus "No views provided"]
	}

	set doCheckin $myArgs(-checkin)
	set checkAllClients $myArgs(-checkAllClients)
	set warnNonLatest $myArgs(-warnNonLatest)
	
	
	if [info exists cellViewHash] {array unset cellViewHash}
	if [info exists libHash] {array unset libHash}
	
	puts "[exec date]:  Getting hierachy"
	update
	getHierCellviews $libName $cellName $viewNames 1

	puts "[exec date]:  Getting library info"
	update
	set libList [array names libHash]
	getLibInfo $libList $checkAllClients
	
	puts "[exec date]:  Paring cellView list"
	update
	array unset libCellviewList
	foreach ln $managedLibList {set libCellviewList($ln) {}}
	foreach cellViewSpec $managedCellviewList {
	    set ln [lindex $cellViewSpec 0]
	    set cv [lindex $cellViewSpec 1]
	    set vt [lindex $cellViewSpec 2]
	    lappend libCellviewList($ln) [list $cv $vt]
	}
	
	##  Check list of what we have vs. what's in the hierarchy.
	puts "[exec date]:  Getting \"have\" info"
	update
	set tagErr "${libName}_${cellName}_tag.err"
	file delete $tagErr
	set haveInfo [checkHaves $tagErr]
	set tagInfo [lindex $haveInfo 0]
	set haveErrors [lindex $haveInfo 1]
	
	puts "[exec date]:  Getting \"opened\" info"
	update
	set openErrors [checkOpened $tagErr]
	set errors [concat $haveErrors $openErrors]
	

	set returnMessage "Successful tag"
	if {[llength $errors] == 0} {
	    puts "Info:  No errors detected."
	    set proceed 1
	} else {

	    ##  Going to go a different direction. Since the tables are difficult or impossible to format,
	    ##  will instead shell out to an external tcl/tk script to manage the error reviews.
	    set errConfig "${libName}_${cellName}_errors.cfg"
	    set CFG [open $errConfig w]
	    puts $CFG "set title \"Review tag warnings\""
	    set i 1
	    foreach err $errors {
		puts $CFG "set errorList($i) {$err}"
		incr i
	    }
	    close $CFG

	    set dialogInfo [exec $alpha::tag::dialogScript errorReview $errConfig]
	    if {$dialogInfo == ""} {
		de::sendMessage  "Aborting checkin of tag file" -severity "info"
		set proceed 0
		##  Happens when dialog is summarily closed by user.  Assume abort.
	    } elseif [regexp {^(\S+)\s*(.*)} $dialogInfo dummy keyword message] {
		if {$keyword == "IGNORE"} {
		    puts "Info:  Ignoring errors and proceeding with checkin of tag file"
		    set errorStatus [alpha::tag::setErrorCode $errorStatus OPENED_OA]
		    set errorStatus [alpha::tag::setErrorCode $errorStatus ERRORS_IGNORED]
		    set proceed 1
		}
		if {$keyword == "ABORT"} {
		    puts "Info:  Aborting checkin of tag file"
		    set errorStatus [alpha::tag::setErrorCode $errorStatus ABORTED]
		    set proceed 0
		}
		if {$keyword == "ERROR"} {
		    puts "Error:  $dialogInfo"
		    set errorStatus [alpha::tag::setErrorCode $errorStatus UNKNOWN_ERROR]
		    set proceed 0
		}
	    } else {
		puts "Error: Unrecognized info \"$dialogInfo\""
		set errorStatus [alpha::tag::setErrorCode $errorStatus UNKNOWN_ERROR]
		set proceed 0
		set returnMessage "Tag aborted on external script error"
	    }
	}	

	if $warnNonLatest {
	    ##  Arg set to warn if any views are not latest.
	    puts "[exec date]:  Checking tag against latest info"
	    update
	    set stat [warnNonLatest $tagInfo]
	    if !$stat {
		set proceed 0
		de::sendMessage  "Aborting tag" -severity "information"
	    }
	}

	set tagFileDepot ""
	if $proceed {
	    set tagFileDepot "$libDepotPath($libName)/$cellName.tag"
	    catch {set tagFileClient [lindex [exec p4 where $tagFileDepot] 2]}

	    if {!$libIsManaged($libName)} {
		de::sendMessage "$libName is unmanaged; cannot check in tag file" -severity error
		set errorStatus [alpha::tag::setErrorCode $errorStatus LIB_UNMANAGED]
		return [list "" $errorStatus "Library unmanaged"]
	    }

	    if {![alpha::tag::verifyProceed  "\nYou are about to create tagfile\n$tagFileDepot\n"]} {
		de::sendMessage  "Aborting tag" -severity "information"
		set errorStatus [alpha::tag::setErrorCode $errorStatus ABORTED]
		return [list "" $errorStatus "Aborted by user"]
	    }

	    puts "Info:  tagFile = $tagFileDepot - $tagFileClient"
	    set tagOpened [exec p4 opened -a $tagFileDepot 2> /dev/null]
	    if {$tagOpened != ""} {
		##  Tag file exists, but is open by someone.
		de::sendMessage "$tagOpened" -severity information
	    }

	    exec p4 sync -q $tagFileDepot 2> /dev/null
	    set haveInfo [exec p4 have $tagFileDepot 2> /dev/null]
	    if {$haveInfo == ""} {
		##  New file.  The presence of a file in the client is not a reliable test.
		puts "Info:  Adding $tagFileClient"
		puts [exec p4 add -t text $tagFileClient]
	    } else {
		puts "Info:  Editing $tagFileClient"
		puts [exec p4 edit $tagFileClient]
	    }
	    
	    puts "[exec date]:  Writing tag file $tagFileDepot"
	    update
	    set tagFile [open $tagFileClient w]
	    foreach line $tagInfo {puts $tagFile $line}
	    close $tagFile

	    if $doCheckin {
		set checkinStatus 1
		if [info exists myArgs(-description)] {
		    set comment $myArgs(-description)
		    execSubmit $tagFileDepot "" $comment
		} else {
		    catch {gi::closeWindows [gi::getDialogs checkindesc]}
		    set dialog [gi::createDialog checkindesc -title "Submit Design Changes" -showApply 0 -execProc [list alpha::tag::tagHierarchy::execSubmit $tagFileDepot] -showHelp 0 ]
		    set l [gi::createLabel submitPrompt -parent $dialog  -label "Write design change description:"]
		    set desc [gi::createTextInput desc -parent $dialog -height 5 -width 35]
		    ##  The following waits until the specified dialog is closed.
		    gi::execDialog $dialog
		}
	    } else {
		de::sendMessage  "Skipping tag checkin" -severity "information"
	    }
	}
	return [list $tagFileDepot $errorStatus $returnMessage]
    }
}

namespace eval ::alpha::tag::syncTagHierarchy {
    
    proc tag_jobclbk {temp} {
	puts "job completed"
	dm::refreshLibraryManager
	set refresh [de::showRefreshDesigns]
	
    }

    proc submit_rolledback {tempvar  dialog} {
	set child [db::getAttr children -of $dialog]
	set table [db::filter $child -filter {%type == "giTable"}]
	set reqlib [list ]
	
	set rows [gi::getRows -parent [db::getNext $table]]
	db::foreach row $rows {
	    set cells [gi::getCells -row $row]
	    set c1 [db::getAttr value -of [db::getNext $cells]]
	    set c2 [db::getAttr value -of [db::getNext $cells]]
	    if {$c2} {
		lappend reqlib $c1
	    }
	}
	set errorcelllist [list ]
	
	
	foreach filepathtemp $tempvar {
	    
	    set errorflag 1
	    set filepath [lindex $filepathtemp 0]
	    set path [split $filepath "#"]
	    
	    
	    set local_filepath [eval exec p4 have [lindex $path 0]]
	    set currentver [lindex  $local_filepath 1]
	    set local_filepath [lindex  $local_filepath 2]
	    if {$currentver == [lindex [split $filepath "#"] 1]} {
		de::sendMessage "$filepath is same as current version, scipping rollback" -severity warning
		set errorflag 0
	    }
	    if {[regexp {.*/(.*)/.*/.*/.*} $local_filepath _l libname]} {
		if {[lsearch $reqlib $libname] >= 0 } {
		    if ![catch {exec p4 fstat -T "otherOpen" } $local_filepath] {
			# de::sendMessage "$filepath open by other user" -severity error
			lappend errorcelllist $filepath
			set errorflag 0
		    }
		    if {$errorflag} {
			
			regsub [file tail [lindex $path 0]] [lindex $path 0] ... cellpath;
			catch {eval exec p4 sync $cellpath}
			if {[catch {set buff [exec p4 edit -t +l $cellpath]} err]} {
			    de::sendMessage $err -severity error
			    set errorflag 0
			    lappend errorcelllist $filepath
			}
		    }
		    if {$errorflag} {
			set file_list [list ]
			set buff [split $buff \n]
			set file_list [list ];
			foreach line $buff {
			    lappend file_list [lindex [split [lindex $line 0] #] 0]
			}
			
			if [catch {exec p4 print -o $local_filepath -q $filepath} err] {
			    de::sendMessage  $err -severity error    
			    return
			}	
			
			set m "Tag Script : Rollback to Version $filepath"
			set m [string map {\n \\n\\t \/ \\/ & \\& # \\#} $m]
			set emptyChangeList [exec p4 change -o | sed {s://.*::} | sed "s/<enter description here>/$m/"  | p4 change -i];
			regexp {Change[\s]+([0-9]+)} $emptyChangeList _a changelist;
			
			set cmd  "exec echo  $file_list | xargs p4 reopen -c $changelist >> p4.log; exec p4 submit -c $changelist " 
			
			#set cmd  "exec echo  $local_filepath | xargs p4 reopen -c $changelist >> p4.log;" 
			#puts $cmd
			#puts  "################################################ Submitting Changes ################################################"
			if [catch {eval $cmd} err ] {
			    #de::sendMessage $err -severity error
			} 			  
		    }
		}
	    }
	}
	
	
	if {[llength $errorcelllist] > 0} {
	    de::sendMessage  "Following Cells are not Rolled back" -severity error 
	    foreach temperrorcell $errorcelllist {
		de::sendMessage  $temperrorcell -severity error	
	    }  
	}	
	dm::refreshLibraryManager	
    }
    
    proc checkOpensAgainstTagfile {tagFile action} {
	##  This checks the files in tagFile for opens.  If sync'ing, checks just the user opens.  If rolling back, checks all.

	## Build an array of all the libs
	puts "[exec date]: Getting library list"
	update
	set libList [alpha::tag::getLibList]
	foreach lib $libList {
	    set libName [db::getAttr name -of $lib]
	    set libPathClient [db::getAttr fullPath -of $lib]
	    set libPathDepot ""
	    catch {set libPathDepot [exec p4 where $libPathClient/...]}
	    if {$libPathDepot != ""} {
		##  Lib is managed
		set libPathDepot [regsub -all {/\.\.\.} $libPathDepot ""]
		set libPathDepot [lindex $libPathDepot 0]
		set libPath($libName) $libPathDepot
	    }
	}

	## get tag file, build list of files $tagData
	puts "[exec date]: Reading tag file"
	update
	set fname [file tail $tagFile]
	exec p4 print -o $fname $tagFile
	set TAG [open $fname r]
	set tagData [read $TAG]
	close $TAG
	set tagData [regsub -all {\#\d+} $tagData ""]
	set tagData [split $tagData "\n"]

	##  To determine opens, will do a "p4 opened" on each library rather than each individual file.
	##  Build list of libraries in use.
	puts "[exec date]: Determining used libraries"
	update
	array unset usedLibHash
	foreach tagMember $tagData {
	    foreach libName [array names libPath] {
		if {[string first $libPath($libName) $tagMember] == 0} {
		    ##  Tagmember is in $libName
		    set usedLibHash($libName) 1
		    break
		}
	    }
	}
	set usedLibs [array names usedLibHash]

	if {$action == "sync"} {
	    ##  If syncing, just care about the user's checkouts
	    set opt "-s"
	    set openRegex {^(\S+)\s}
	} elseif {$action == "rollback"} {
	    ##  If rolling back, care about everybody's checkouts
	    set opt "-as"
	    set openRegex {^(\S+).* by (\S+)@}
	}

	array unset openFileHash
	foreach libName $usedLibs {
	    set libOpened {}
	    catch {set libOpened [exec p4 opened $opt "$libPath($libName)/..."]}
	    foreach line [split $libOpened "\n"] {
		if [regexp $openRegex $line dummy openedFileDepot openedFileUser] {
		    set openFileHash($openedFileDepot) [list $openedFileUser $libName]
		}
	    }
	}

	puts "[exec date]: Checking tag files against open data"
	update
	set errList {}
	foreach tagMember $tagData {
	    if [info exists openFileHash($tagMember)] {
		##  Found an open file referenced in the tag file
		set openInfo $openFileHash($tagMember)
		set user [lindex $openInfo 0]
		set libName [lindex $openInfo 1]
		if {$user == ""} {set user $::env(USER)}
		set ofd [alpha::tag::stripCommon $openedFileDepot $libPath($libName)]
		set t [split $ofd "/"]
		set fileName [lindex $t end]
		set t [lreplace $t end end]
		set cellView [join $t "/"]
		lappend errList [list $libName $cellView $fileName "Opened by $user"]
#		puts "ERROR:  $libName  $cellView  $fileName  is open by $user"
	    }
	}

	set errConfig "openErrors.tmp"
	if {[llength $errList] > 0} {
	    set CFG [open $errConfig w]
	    set i 1
	    puts $CFG "set title \"Review open file warnings\""
	    foreach err $errList {
		puts $CFG "set errorList($i) {$err}"
		incr i
	    }
	    close $CFG
	    puts "Starting dialog"
	    update
	    set dialogInfo [exec $alpha::tag::dialogScript errorReview $errConfig]
	    if {$dialogInfo == ""} {
		puts "Info:  Aborting $action"
		set proceed 0
		##  Happens when dialog is summarily closed by user.  Assume abort.
	    } elseif [regexp {^(\S+)\s*(.*)} $dialogInfo dummy keyword message] {
		if {$keyword == "IGNORE"} {
		    de::sendMessage  "Ignoring checkout and proceeding with $action" -severity information
		    return 1
		}
		if {$keyword == "ABORT"} {
		    puts "Info:  Aborting $action"
		    de::sendMessage  "Aborting $action" -severity information
		    return 0
		}
		if {$keyword == "ERROR"} {
		    de::sendMessage  $dialogInfo -severity "error"	
		    return 0
		}
	    }
	} else {
	    de::sendMessage  "No checkout errors; proceeding with $action" -severity "information"	
	    return 1
	}
    }

	
    proc openTagfile {dialog buttonname} {
	set table [db::filter [db::getAttr children -of $dialog] -filter {%name == "taghistorytable"}]
	
	set row [db::getAttr selection -of $table] 
	
	
	set parent [db::getAttr parent -of $row]
	set cells [gi::getCells -row $row]
	set ver [db::getAttr value -of [db::getNext $cells]]
	
	set cells [gi::getCells -row [gi::getRows -parent [db::getNext $table]]]
	db::getNext $cells
	db::getNext $cells
	db::getNext $cells
	set path [db::getAttr value -of [db::getNext $cells]]
	set theTagFile "$path#$ver"
	
	if {[lindex $buttonname 0] == "Rollback to tagged version"} {
	    set action "rollback"
	} elseif {[lindex $buttonname 0] == "Sync tag file"} {
	    set action "sync"
	}
	
	de::sendMessage  "tagFile = $theTagFile, action = $action" -severity "information"	

	catch {gi::closeWindows [gi::getDialogs tagrev]}
	if {![checkOpensAgainstTagfile $theTagFile $action]} {
	    ##  Errors were reported and not waived.
	    return
	}
	
	if {![alpha::tag::verifyProceed  "\nYou are about to $action using tag file $theTagFile\n"]} {
	    de::sendMessage  "Aborting $action" -severity "information"
	    return
	}
	
	if {$action == "rollback"} {
	    if {![alpha::tag::verifyProceed  "\nYou are about to change what is in the depot.  Really sure?\n"]} {
		de::sendMessage  "Aborting $action" -severity "information"
		return
	    }
	    puts "Rolling back to tagged version"
	    set outfile "$path#$ver"
	    puts "Taking $outfile for rolling back"
	    catch {eval exec p4 sync $outfile}
	    set latestoutfile $path
	    set path [exec p4 have $path]
	    regexp {(.*)[\s]+-[\s]+(.*)} $path _l depotpath path
	    
	    set libnames [list ]
	    set fileid [open $path r]
	    set tempvar  " "
	    while {[gets $fileid file_info] >= 0} {
		
		#regexp {(.*)[\s]+-[\s]+(.*)} $file_info _l depotpath 
		
		if {[regexp {.*\.oa} $file_info]} {
		    lappend tempvar [list $file_info]
		    
		    if {[regexp {.*/(.*)/.*/.*/.*} $file_info _l libname]} {
			lappend libnames $libname
		    }
		}
		
	    }
	    close $fileid
	    
	    if {[llength $libnames] > 0} {
		
		
		set libnames [lsort -unique $libnames]
		set dialog [gi::createDialog displaylibnames -title "Select Libraries to edit and checkin" -showHelp 0 -showApply 0 \
				-execProc [list alpha::tag::syncTagHierarchy::submit_rolledback $tempvar]]
		set table [gi::createTable librariestable -parent $dialog  -readOnly 0 -allowSortColumns 1 -alternatingRowColors 1 -selectionModel "multipleRows"]
		set c1 [gi::createColumn -parent $table -label "Library name" -stretch 1 -readOnly 1]
		set c2 [gi::createColumn -parent $table -label "Sel" -stretch 0 -readOnly 0 -dataType bool]
		foreach temp $libnames {
		    
		    set r [gi::createRow -parent $table]
		    db::setAttr value -of [gi::getCells -row $r -column $c1] -value $temp
		    db::setAttr value -of [gi::getCells -row $r -column $c2] -value 0
		    
		}
		
	    } else {
		de::sendMessage  "Cells are not edited" -severity "information"	
	    }
	    catch {eval exec p4 sync $latestoutfile}
	}
	
	if {$action == "sync"} {
	    set outfile "$path#$ver"
	    set tempvar "_P4_"	
	    if {[regexp {.*/(.*)} $path _l cellname]} {
		set localfile "$cellname$tempvar$ver.sh"
		set localfilelist "$cellname$tempvar$ver"
		puts "p4 print -q -o $localfilelist $outfile "
		exec p4 print -q -o $localfilelist $outfile 		
		puts "Processing $localfilelist Started......"
		#set fileid [open $localfile r]
		#set tempvar  " "
		#while {[gets $fileid file_info] >= 0} {
		    
		    #regexp {(.*)[\s]+-[\s]+(.*)} $file_info _l depotpath localpath
		#    set tempval "p4 sync $file_info"
		#    lappend tempvar $tempval
		    
		#}
		
		#close $fileid
		#exec chmod 777 $localfile
		set fileid [open $localfile w]
		#foreach temp $tempvar {
		 #   puts $fileid $temp
		    
		#}
		puts $fileid "p4 -x $localfilelist sync --parallel \"threads=4,batch=8,batchsize=524288,min=1,minsize=589824\""
		close $fileid
		
		puts "Processing $localfile completed....."
		puts $localfile
		set cmd "xterm -e sh $localfile"
		#exec xterm -e sh $localfile &
		xt::createJob tag_sync -type interactive \
		    -cmdLine $cmd  \
		    -data [list $buttonname $path]\
		    -runDesc "sync tag file"  \
		    -exitProc alpha::tag::syncTagHierarchy::tag_jobclbk
		
		#exec xterm -e nedit -read $localfile &
	    } else {
		de::sendMessage "Error in getting tag file name" -severity error
	    }
	}
	
	#	catch {gi::closeWindows [gi::getDialogs tagrev]}   ##  Moved this to the beginning.  Closes as soon as a button is clicked.
    }

    proc execute {args} {
	array set myArgs $args
	set libName $myArgs(-libName)
	set cellName $myArgs(-cellName)

	if {$alpha::tag::dialogScript == ""} {
	    de::sendMessage  "Cannot find alphaTagHierarchy_dialog.tcl; tell John" -severity "error"
	    return
	}

	if { [catch { set libFullPath [oa::getPath [oa::LibFind $libName]] } ] } {
	    de::sendMessage "$libName does not exist" -severity error
	    return
	}
	
	set libPathClient [file normalize $libFullPath]
	set libPathDepot {}
	##  For some reason, the following p4 command throws an exception when the lib in question isn't p4'ed.  The catch fixes.
	catch {set libPathDepot [lindex [exec p4 where $libPathClient/... 2> /dev/null] 0]}
	if {$libPathDepot == ""} {
	    de::sendMessage "Library \"$libName\" is unmanaged; no tag files will exist" -severity error
	    return
	}

	##  OK.  Lib exists.
	##  Stealing code from old script.
	set libPathDepot [regsub -all {/\.\.\.} $libPathDepot ""]
	set tagfileName "$libPathDepot/$cellName.tag"
	set filelog [exec p4 filelog -l $tagfileName 2> /dev/null]
	set buff [split $filelog "\n"]

	if {$filelog == ""} {
	    de::sendMessage "No tag files for $libName/$cellName" -severity error
	    return
	}
	
	set version {}
	set tagHistory [list]
	set desc {}
	foreach it $buff {
	    if {$it == ""} {
		## Empty lines
	    } elseif [regexp {^//} $it] {
		##  Just the file name.  Have that already.
	    } elseif  [regexp {\.\.\.[\s]+#([0-9]+)[\s]+[a-z]+[\s]+[0-9]+[\s]+([a-z/]+) on ([0-9/]+) by ([a-z][-a-z0-9_]+)@} $it _l t1 t2 t3 t4] {
		## The actual details.
		if {$version != ""} {lappend tagHistory [list $version $operation $time $owner $desc]}
		set version $t1
		set operation $t2
		set time $t3
		set owner $t4
		set desc {}
	    } elseif  [regexp {^\.\.\. \.\.\.} $it] {
		##  Branch info.  Ignore
	    } else {
		##  Comment
		set desc [concat $desc $it]
	    }
	}
	lappend tagHistory [list $version $operation $time $owner $desc]


	##  The original way, mostly.
	catch {gi::closeWindows [gi::getDialogs tagrev]}
	
	set dialog [gi::createDialog tagrev -title "Tag file History" -showHelp 0 -showApply 0 -extraButtons "Sync\\ tag\\ file Rollback\\ to\\ tagged\\ version" \
			-buttonProc "alpha::tag::syncTagHierarchy::openTagfile"]
	db::setAttr geometry -of $dialog -value 1200x500+100+100;
	set table [gi::createTable taghistorytable -parent $dialog  -readOnly 1 -allowSortColumns 1 -alternatingRowColors 1]
	set c1 [gi::createColumn -parent $table -label "Revision Number" -stretch 0 -readOnly 1]
	set c2 [gi::createColumn -parent $table -label "Action" -stretch 0 -readOnly 1]
	set c3 [gi::createColumn -parent $table -label "Date" -stretch 0 -readOnly 1]
	set c4 [gi::createColumn -parent $table -label "Description" -stretch 1 -readOnly 1]
	set c5 [gi::createColumn -parent $table -label "User" -stretch 0 -readOnly 1]
	set buff [split $filelog "\n"]
	
	set fileRow [gi::createRow -parent $table -expanded 1];
	db::setAttr value -of [gi::getCells -row $fileRow -column $c1]  -value [file tail $tagfileName] ;
	db::setAttr value -of [gi::getCells -row $fileRow -column $c4]  -value $tagfileName ;
	
	foreach it $tagHistory {
	    set r [gi::createRow -parent $fileRow];
	    db::setAttr value -of [gi::getCells -row $r -column $c1]  -value [lindex $it 0]
	    db::setAttr value -of [gi::getCells -row $r -column $c2]  -value [lindex $it 1]
	    db::setAttr value -of [gi::getCells -row $r -column $c3]  -value [lindex $it 2]
	    db::setAttr value -of [gi::getCells -row $r -column $c5]  -value [lindex $it 3]
	    db::setAttr value -of [gi::getCells -row $r -column $c4]  -value [lindex $it 4]
	}
    
	##  The silly new way of doing this.
	if 0 {
	    set tagConfig "${libName}_${cellName}_tags.cfg"
	    set CFG [open $tagConfig w]
	    set i 1
	    puts $CFG "set title \"Review warnings\""
	    foreach tag $tagHistory {
		puts $CFG "set tagList($i) {$tag}"
		incr i
	    }
	    close $CFG
	    set dialogInfo [exec $alpha::tag::dialogScript selectTag $tagConfig]
	    if {$dialogInfo == ""} {
		puts "Info:  Aborting sync"
		##  Happens when dialog is summarily closed by user.  Assume abort.
	    } elseif [regexp {^(\S+)\s*(.*)} $dialogInfo dummy keyword message] {
		if {$keyword == "ABORT"} {
		    puts "Info:  Aborting sync"
		}
		if {$keyword == "SYNC"} {
		    set tagfileNameVer "$tagfileName#$message"
		    de::sendMessage "Syncing $tagfileNameVer" -severity information
		    set printInfo [exec p4 print -q -o "$cellName.tag" $tagfileNameVer 2> /dev/null]
		    file attributes $cellName.tag -permissions 0700
		    set TAG [open $cellName.tag r]
		}
		if {$keyword == "ERROR"} {
		    puts "Error:  $dialogInfo"
		    set proceed 0
		}
	    } else {
		puts "Error: Unrecognized info \"$dialogInfo\""
	    }
	}
    }
}

set args [list]
lappend args [de::createArgument -libName  	  -optional false   -description "Library Name"]
lappend args [de::createArgument -cellName  	  -optional false   -description "Cell Name"]
lappend args [de::createArgument -schView  	  -optional true    -description "Schematic view name" -default schematic]
lappend args [de::createArgument -layView  	  -optional true    -description "Layout view name" -default layout]
lappend args [de::createArgument -symView  	  -optional true    -description "symbol view name" -default symbol]
lappend args [de::createArgument -description  	  -optional true    -description "Comment used in tag checkin"]
lappend args [de::createArgument -checkin  	  -optional true    -description "Check in the tag file." -default true]
lappend args [de::createArgument -checkAllClients -optional true    -description "Check all clients for open files" -default false]
lappend args [de::createArgument -warnNonLatest   -optional true    -description "Warn if tagging any views that are not latest" -default false]

de::createCommand alpha::tag::tagHierarchy  -category alpha -arguments $args -description "Tags the hierarchy of a cell"
    
set args [list]
lappend args [de::createArgument -libName  	  -optional false   -description "Library Name"]
lappend args [de::createArgument -cellName  	  -optional false   -description "Cell Name"]

de::createCommand alpha::tag::syncTagHierarchy  -category alpha -arguments $args -description "Syncs a tag file"
    

set m [gi::getMenus dmCellContextMenu];
gi::createAction tagHierarchy -title "Alpha Tag Hierarchy" -command alpha::tag::alphaHierTagGui
gi::createAction syncTagHierarchy -title "Sync/Rollback Tag" -command alpha::tag::alphaHierSyncTagGui

gi::addActions  {tagHierarchy syncTagHierarchy} -to $m 


################################################################################
# No Linting Area
################################################################################

# nolint Main
# nolint Line 143: W Found constant
# nolint Line 395: N Non-default arg after default arg
# nolint Line 701: W Found constant
# nolint Line 991: N Suspicious variable name