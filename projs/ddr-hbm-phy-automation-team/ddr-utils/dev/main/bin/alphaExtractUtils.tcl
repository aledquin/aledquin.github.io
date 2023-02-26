#!/depot/tcl8.5.12/bin/tclsh8.5



#  Contains alpha-specific extraction collateral


##Creates empty files with libnames for autofill
set libDefName "$env(MSIP_PROJ_ROOT)/$env(MSIP_PRODUCT_NAME)/$env(MSIP_PROJ_NAME)/$env(MSIP_REL_NAME)/design/lib.defs"
catch { set libDefContents [ exec grep ^DEFINE $libDefName ] }
if { [info exists libDefContents] } {
	if { [regexp {DEFINE} $libDefContents] } {
		set data [split $libDefContents "\n"]
		foreach line $data {
			regexp -nocase {DEFINE\s([a-z0-9_\-]+)\s} $line -> myTempLib
			if { ![catch {set tempLib [open $myTempLib w+]}]} {
				close $tempLib
			}
		}
	}
}
set locallib "lib.defs"
catch { set localLibDefs [exec grep ^DEFINE $locallib] }
if { [info exists localLibDefs] } {
	if { [regexp {DEFINE} $localLibDefs] } {
		set data [split $localLibDefs "\n"]
		foreach line $data {
			regexp -nocase {DEFINE\s([a-z0-9_\-]+)\s} $line -> myTempLib
			if { ![catch {set tempLib [open $myTempLib w+]}]} {
				close $tempLib
			}
		}
	}
}

set thisScript [file normalize [info script]]
de::sendMessage "Executing $thisScript" -severity information

set scriptPath [file dirname $thisScript]
set tagScript "$scriptPath/alphaTagHierarchy.tcl"
if [file exists $tagScript] {
	de::sendMessage "Source $tagScript" -severity information
	source $tagScript
	set p4TagScript 1
} else {
	##  p4 tagging script not loaded
	set p4TagScript 0
}

#namespace eval ::MSIP_PV {
#    ## Overload this pv proc that generates the skipCellSubcktsFile; just copy the cdl.
#    proc createSkipCellSubcktsFile { cellListFile netlistFile rundir rundirChild cellName } {
#	##  This version simply uses the cdl as the skipCell subckt file.
#	set skipCellSubcktsFile $rundir/$rundirChild/skipCellSubcktsFile
#	if [file exists $skipCellSubcktsFile] {file delete $skipCellSubcktsFile}
#	file copy -- $netlistFile $skipCellSubcktsFile
#	set returnValue "$skipCellSubcktsFile"
#	return $returnValue
#    }
#}
#
if {[namespace exists alpha::lpe]} {
    namespace delete alpha::lpe
}

set DEBUG      0
set VERBOSITY  0
set STDOUT_LOG ""
set RealBin        [file dirname [file normalize [info script]] ]
namespace eval ::alpha::lpe {
    global RealBin
    variable PROGRAM_NAME [file tail [file normalize [info script]] ]
	namespace eval _packages {
        global RealBin
		source "$RealBin/../lib/tcl/Util/Messaging.tcl"
		source "$RealBin/../lib/tcl/Util/Misc.tcl"
	}
	namespace import _packages::Messaging::*
	namespace import _packages::Misc::*
	foreach procName [namespace import] {
		rename $procName "_$procName"
	}
	# Get the version number
	variable VERSION [_get_release_version]
	_utils__script_usage_statistics $PROGRAM_NAME $VERSION

	##  Globals used by
	variable cellList
	variable stopList
	variable bboxCells
	variable bboxLibs

	variable defaultArgs

	variable checkResults

	variable schematicViewName
	variable layoutViewName
	variable symbolViewName

	set schematicViewName "schematic"
	set layoutViewName "layout"
	set symbolViewName "symbol"

	##  Set some default args.
	###LN set defaultArgs(cornerVal) typical
	set defaultArgs(xtPowerNets) [list VDD VDDQ VSS VAA]
	#set defaultArgs(xTypes) {srccpcc}
	set defaultArgs(xTypes) {rcc}

	set defaultArgs(stack) $::env(METAL_STACK)
	###LN set defaultArgs(gridOpts) [list -conf /remote/sge/default/msem/common/settings.sh -dp4 -quick -wait]
	#    set defaultArgs(gridOS) -WS6.0
	#set defaultArgs(gridProc) -dp4
	set pvV [file tail $::env(MSIP_CD_PV)]
	if { $pvV >= "2018.10"} { set defaultArgs(useGrid) 1 }
	###LN set defaultArgs(xtPowerExtract) NO
	###LN set defaultArgs(compressedLVSNetlist) false

	if [info exists ::alpha::lpe::defaultArgsByType] {unset ::alpha::lpe::defaultArgsByType}
	#    proc setDefaultArg {argName argValue} {set ::alpha::lpe::defaultArgs($argName) $argValue}

	##  Quotes are needed in earlier versions of pv.  Including quotes by default
	lappend ::alpha::lpe::defaultArgsByType(selectedNets) {selectedNetList="*"}

	proc CreateSetPref {prefName prefValue prefDesc} {
		##  Creates new pref if it doesn't exist, sets value otherwise
		if {[db::isEmpty [db::getPrefs $prefName]] } {
			de::sendMessage "Creating pref $prefName = $prefValue" -severity information
			catch { db::createPref $prefName -value $prefValue -description $prefDesc -defaultScope cell } err
		} else {
			catch { db::setPrefValue $prefName -value $prefValue } err
			de::sendMessage "ISet pref value $prefName = [db::getPrefValue $prefName]" -severity information
		}
	}

	proc logCheckInfo {msg} {
		variable checkResults
		puts $msg
		lappend checkResults $msg
	}


	proc execExtract {qOpts enGrid} {
		##  Function to actually submit the job.
		if {$::run == "batch"} {
			##  qsub the thing
			#		exec "qsub"
			set address "$::env(USER)@synopsys.com"
			set pvbatchOutput "$::RUNDIR/$::CELLNAME.$::TYPE.pvbatch.out"
			set pvbatchError "$::RUNDIR/$::CELLNAME.$::TYPE.pvbatch.err"
			#set cmd "qsub -P bnormal -l os_version='WS5.0|WS6.0|CS6.0',os_distribution='centos|redhat' -cwd -m as -M $address -e $pvbatchError -o $pvbatchOutput $::pvbatchScript"
			#puts $cmd
			#exec {*}$cmd
			if { $enGrid == 1 } {
				if { $qOpts != "" } {
					set cmd "qsub -P bnormal $qOpts -cwd -m as -M $address -e $pvbatchError -o $pvbatchOutput $::pvbatchScript"
					puts [exec {*}$cmd]
				} else {
					set cmd "qsub -P bnormal -cwd -m as -M $address -e $pvbatchError -o $pvbatchOutput $::pvbatchScript"
					puts [exec {*}$cmd]
				}
			} elseif { $enGrid == 0 } {
				puts "xt::createJob \"ALPHA_RUN_EXTRACT\" -type batch -cmdLine $::pvbatchScript -runDesc \"Running extraction for $::CELLNAME\" "
				xt::createJob "ALPHA_RUN_EXTRACT" -type batch -cmdLine "env -i tcsh $::pvbatchScript" -runDesc "Running extraction for $::CELLNAME"
				#$cmd
			}
		} elseif {$::run == "interactive"} {
			puts "exec $::pvbatchScript"
			exec $::pvbatchScript
		} else {
			de::sendMessage "Setup completed.  Not running." -severity information
		}

	}


	proc genHspiceNetlist {libName cellName outDir} {
		set destNetlist "$outDir/$cellName.sp"
		if [file exists $destNetlist] {file delete $destNetlist}

		##  Get current state of createTopAsModule attr
		set createTopAsModule_save [db::getAttr createTopAsModule -of [nl::getNetlisters HSPICE]]
		##  Force to 1 for this netlist.
		db::setAttr createTopAsModule -of [nl::getNetlisters HSPICE] -value 1

		ude::genNetlist::execute  \
			-libName $libName \
			-cellName $cellName \
			-cellView schematic \
			-netlistFormat HSPICE \
			-viewSearchList {veriloga hspice hspiceD schematic symbol} \
			-viewStopList use_cd_default \
			-includeCIR {} \
			-processName $::env(PROCESSNAME) \
			-postProcess false \
			-enablepostProcess false \
			-postProcessType false \
			-compress false \
			-openInViewer false \
			-openInEditor false \
			-caseSensitive true \
			-runDir $outDir \
			-fileName $cellName.sp \
			-reference false \
			-snapHier true \
			-snapHierEn false \
			-snapRev false

		##  Restore state.
		db::setAttr createTopAsModule -of [nl::getNetlisters HSPICE] -value $createTopAsModule_save


		if [file exists $destNetlist] {
			##  All good.
			de::sendMessage "[file normalize $destNetlist] created" -severity information
		} else {
			de::sendMessage "Netlist failed.  See [file normalize netlist.log] for details." -severity error
		}
	}

	proc setDefaultArg {args} {
		set getType 0
		set type "global"
		foreach arg $args {
			if $getType {
				set type $arg
				set getType 0
			} elseif {$arg == "-type"} {
				set getType 1
			} else {
				lappend argList $arg
			}
		}
		if {[llength $argList] == 2} {
			set argName [lindex $argList 0]
			set argValue [lindex $argList 1]
			if {$type == "global"} {
				set ::alpha::lpe::defaultArgs($argName) $argValue
			} else {
				if [info exists ::alpha::lpe::defaultArgsByType($type)] {
					set i [lsearch -glob $::alpha::lpe::defaultArgsByType($type) "$argName=*"]
					##  See if arg alread defined, and remove old value if it is.
					if {$i  >= 0} {
						de::sendMessage "Removing previous definition of $argName for type $type" -severity information
						set ::alpha::lpe::defaultArgsByType($type) [lreplace $::alpha::lpe::defaultArgsByType($type) $i $i]
					}
				}
				lappend ::alpha::lpe::defaultArgsByType($type) "$argName=$argValue"
			}
		}
		return
	}

	proc showDefaultArgs {} {
		if [info exists ::alpha::lpe::defaultArgs] {
			foreach argName [array names ::alpha::lpe::defaultArgs] {
				puts "$argName = $::alpha::lpe::defaultArgs($argName)"
			}
		} else {
			return
		}
	}

	proc beolCornerIsValid {corners} {
		##  Validate a list of corners
		global env
		global validCorners


		## Load the valid corners once.
		if {![info exists validCorners]} {
			set RCXTTCADgrdFile $env(RCXTTCADgrdFile)
			for { set i 0 } { $i < [llength $RCXTTCADgrdFile] } { incr i 2} {
				set tcadFile [lindex $RCXTTCADgrdFile [expr {$i+1}]]
				if {$tcadFile == "NA"} {continue}
				if {$tcadFile == "na"} {continue}
				if [file readable $tcadFile] {
					set validCorners([lindex $RCXTTCADgrdFile $i])  1
				} else {
					de::sendMessage "TCAD file $tcadFile is not readable" -severity error
				}
			}
		}

		set OK true
		foreach bc $corners {
			if {![info exists validCorners($bc)]} {
				de::sendMessage "Corner \"$bc\" is invalid" -severity error
				set OK false
			}
		}
		return $OK
	}

	proc showUsage {} {
		global thisScript

		set scriptRoot [file rootname $thisScript]
		set scriptPath [file dirname $thisScript]
		puts "$scriptRoot"
		set usageFile "$scriptRoot.txt"
		xt::openTextViewer -files $usageFile
	}

	proc readBboxlist {} {
		##  Reads the bbox list ($PROJ_HOME/design/bboxList.txt, and loads arrays bboxCells and bboxLibs appropriately
		global bboxCells
		global bboxLibs
		global env

		if [info exists bboxCells] {unset bboxCells}
		if [info exists bboxLibs] {unset bboxLibs}
		set bboxList0 "$env(PROJ_HOME)/design/bboxList.txt"
		set bboxList1 "$env(PROJ_HOME)/design_unrestricted/bboxList.txt"

		if [file exists $bboxList0] {
			set bboxList $bboxList0
		} elseif [file exists $bboxList1] {
			set bboxList $bboxList1
		} else {
			de::sendMessage "Cannot open either $bboxList0 or $bboxList1 for read" -severity error
			return
		}

		set fp [open $bboxList r]
		set bboxFile [read $fp]
		close $fp
		set data [split $bboxFile "\n"]
		foreach line $data {
			## puts $line
			##  Uncomment and strip leading/trailing whitespace
			set line [regsub {\#.*} $line ""]
			set line [regsub {^\s+} $line ""]
			set line [regsub {\s+$} $line ""]
			set Ntok [llength $line]
			if {$Ntok == 0} {} elseif {[llength $line] == 2} {
				set type [string tolower [lindex $line 0]]
				set item [lindex $line 1]
				if {$type == "cell"} {
					set bboxCells($item) 1
				} elseif {$type == "lib"} {
					set bboxLibs($item) 1
				} else {
					de::sendMessage "Unrecognized ID in bboxList file:  \"$line\"" -severity warning
				}
			} else {
				de::sendMessage "Unrecognized line in bboxList file:  \"$line\"" -severity warning
			}
		}
	}

	proc genStoplist {topLibName topCellName} {
		global stopList
		global cellList
		variable schematicViewName

		if [info exists stopList] {unset stopList}
		if [info exists cellList] {unset cellList}
		de::sendMessage "Generating stoplist from $topLibName/$topCellName/$schematicViewName" -severity information
		genStoplist_step $topLibName $topCellName $schematicViewName 1
		set returnStopList [array names stopList]
		return $returnStopList
	}

	proc genStoplist_step {topLibName topCellName schematicViewName checkExists} {

		global bboxCells
		global bboxLibs
		global env
		global cellList
		global stopList
		set aggCellName "$topLibName/$topCellName/schematic"
		set libList($topLibName) 1
		#puts "Checking $topLibName/$topCellName"
		if [oa::DesignExists $topLibName $topCellName $schematicViewName] {
			set design [oa::DesignOpen $topLibName $topCellName $schematicViewName r]
			set insts [db::getInsts -of $design]
			db::foreach oaInst $insts {
				set pin [db::getAttr pin -of $oaInst]
				set isPin [string compare $pin ""]
				set libName [db::getAttr libName -of $oaInst]
				set cellName [db::getAttr cellName -of $oaInst]
				set instName [db::getAttr name -of $oaInst]
				set instAggCellName "$libName/$cellName"
				if (![info exists cellList($instAggCellName)]) {
					##  Never addressed this cell before.
					if [info exists bboxCells($cellName)] {
						set stopList($cellName) 1
					} elseif [info exists bboxLibs($libName)] {
						set stopList($cellName) 1
					} else {
						genStoplist_step $libName $cellName schematic 0
					}
				}
				set cellList($instAggCellName)  1
			}
		} elseif {$checkExists == 1} {
			de::sendMessage "$topLibName/$topCellName not found" -severity error
			return
		}
		return
	}

	proc dumpStoplist {} {
		global stopList
		foreach cell [array names stopList] {puts "\t$cell"}
	}


	proc fileName {fileIn} {
		set t [split $fileIn /]
		set fileOut [lindex $t [expr {[llength $t]-1}]]
		return $fileOut

	}
	proc createHackedRunset {rundir} {
		## Generates a hacked runset file from the ccs original.
		global IcvRunLVS

		set filesOK [checkRequiredFile $IcvRunLVS 1]
		set rsRoot [fileName $IcvRunLVS]

		## Open the normal runset
		set fIn [open $IcvRunLVS r]
		set rsOut "$rundir/$rsRoot.Hack"
		set fOut [open $rsOut w]
		while {[gets $fIn line] >= 0} { if {[regexp "flatten.*top_cell_name" $line]} {puts $fOut "//$line"} else {puts $fOut $line}}
		close $fIn
		close $fOut
		de::sendMessage "Wrote hacked runset file $rsOut" -severity information
		de::sendMessage "   generated from $IcvRunLVS" -severity information
		return $rsOut

	}

	proc createHackedRCXTSourceFile {rundir} {
		## Generates a hacked RCXTSourceFile
		global env

		## Find name of icv RCXTSourceFile.
		set RCXTSourceFile $env(RCXTSourceFile)
		set i [lsearch -exact $RCXTSourceFile icv]
		if {$i >= 0} {
			set RCXTSourceFile [lindex $RCXTSourceFile [expr {$i+1}]]
			set filesOK [checkRequiredFile $RCXTSourceFile 1]
			set name [fileName $RCXTSourceFile]
			set RCXTSourceFileHack "$rundir/$name.Hack"

			## Open the normal runset
			set fIn [open $RCXTSourceFile r]
			set fOut [open $RCXTSourceFileHack w]
			while {[gets $fIn line] >= 0} { puts $fOut $line }
			puts $fOut "export DONT_EXTRACT_FLT_GATE=TRUE"
			puts $fOut "export DONT_EXTRACT_TIED_GATE=TRUE"
			puts $fOut "export DONT_EXTRACT_PARASITIC_DIODES=TRUE"
			puts $fOut "export DONT_EXTRACT_PARASITIC_CAP=TRUE"
			close $fIn
			close $fOut
			de::sendMessage "Wrote hacked RCXTSourceFile file $RCXTSourceFileHack" -severity information
			de::sendMessage "   generated from $RCXTSourceFile" -severity information
			return $RCXTSourceFileHack
		}
	}

	proc checkRequiredFile {filename OK} {
		if {$filename == ""} {return $OK}
		if [file exists $filename] {
			return $OK
		} else {
			de::sendMessage "Required file $filename does not exist" -severity error
			return 0
		}
	}

	proc checkRequiredArg {args argName OK} {
		if {[lsearch -exact $args $argName] == -1} {
			de::sendMessage "Required argument $argName not provided" -severity error
			return 0
		} else {
			return $OK
		}
	}

	proc findOptions {optionsList tool} {

		for { set i 0 } { $i < [ llength $optionsList ] } { incr i 2} {
			set optTool [lindex $optionsList $i]
			if {$optTool == $tool} {return [lindex $optionsList [expr {$i+1}]]}
		}
		de::sendMessage "Tool \"$tool\" not found while searching option list $optionsList" -severity error
		return ""
	}

	proc createConfigEquivFiles {libName cellName config equiv log} {
		##  Used by the NT flow
		variable schematicViewName

		set LOG [open $log w]
		puts $LOG "Info:  Generating config and equiv files for $libName/$cellName"
		if [oa::DesignExists $libName $cellName $schematicViewName] {
			readBboxlist
			set stop [genStoplist $libName $cellName]
			set CONFIG [open $config w]
			set EQUIV [open $equiv w]

			puts $LOG "Creating $config and $equiv"
			set configStr ""
			set equivStr ""
			set sepC ""
			set sepE ""
			puts $LOG "Stoplist:"
			foreach sl $stop {
				puts $LOG "\t$sl"
				append configStr "$sepC\"$sl\""
				append equivStr "$sepE$sl"
				set sepC ","
				set sepE " "
			}
			puts $CONFIG $configStr
			puts $EQUIV $equivStr
			close $CONFIG
			close $EQUIV
			puts $LOG "$config created"
			puts $LOG "$equiv created"
			close $LOG
		} else {
			de::sendMessage "Cell $libName/$cellName does not exist" -severity error
		}
	}

	proc errorGui {errorMsg} {
		global thisScript
		set scriptPath [file dirname $thisScript]
		set dialogScript "$scriptPath/alphaTagHierarchy_dialog.tcl"
		if {![file exists $dialogScript]} { set dialogScript "./alphaTagHierarchy_dialog.tcl" }
		#set errorMsg "$errorMsg\nLibName: $argArray($libName)\nCellName: $argArray($cellName)"
		set cfgFile "errorMessage.cfg.tmp"
		set CFG [open $cfgFile w]
		puts $CFG "set title ERROR"
		puts $CFG "set message \"$errorMsg\""
		close $CFG
		exec $dialogScript errorMsg $cfgFile &
	}

	proc runExtract {type args} {
		set scriptArgs "$type $args"
		global env
		global thisScript

		variable schematicViewName
		variable layoutViewName
		variable symbolViewName

		variable checkResults

		if {$type == "help"} {
			showUsage
			return
		}

		## Pre-fill arg array with defaults.
		set user $env(USER)
		set prodName $env(MSIP_PRODUCT_NAME)
		set projName $env(MSIP_PROJ_NAME)
		set relName $env(MSIP_REL_NAME)
		set CCS "/remote/proj/cad/$env(MSIP_CAD_PROJ_NAME)/$env(MSIP_CAD_REL_NAME)"

		#	    set argArray(stack) $env(METAL_STACK)
		#	    set argArray(optionsFile) [findOptions $env(RCXTOptionsFile) icv]
		set projHome $env(PROJ_HOME)
		#	    set argArray(cornerVal) typical
		##      This file would be subject to change, depending on how the icv directories are structured
		#	    set argArray(sourceFile) "$projHome/cad/$argArray(stack)/options/icv/LVS/RCXT_sourceme"
		#	    set argArray(layermap) $env(LayerMapFile)
		#	    set argArray(xcmdFile) $env(RCXTcmdFile)
		#	    set argArray(netlistPProcesor) $env(RCXTnetlistPostProc)
		#	    set argArray(incNetlist) $env(RCXTincludeNetlist)
		#	    set argArray(xInstFile) $env(RCXTXdevFile)
		#	    set argArray(xtPowerNets) [list VDD VDDQ VSS VAA]
		#	    set argArray(tool) icv
		#	    set argArray(calibreFlat) {}
		##  set to {} for BB
		#	    set argArray(runFlat) "-flat"
		#	    set argArray(icvOpts) " -dp2 "
		#	    set argArray(pvprefix) $pvprefix
		#	    set argArray(viewName) "layout"
		#	    set argArray(viewSchematicName) "schematic"
		#	    set argArray(viewSchematicLibName) ""
		#	    set argArray(pinOptionsFile) false
		#	    set argArray(pcsOptionsFile) false
		#	    set argArray(objectLayermap) false
		#	    set argArray(nettranOptions) [list -slash -cdl-a -mprop]
		## Defaults to running in batch
		#	    set argArray(gridOpts) [list -conf /remote/sge/cells/snps/common/settings.sh -dp4 -WS5.0 -quick -wait]
		#	    set argArray(gridOS) -WS5.0
		#	    set argArray(gridProc) -dp4
		#	    set argArray(calexOpts) [list --gds  --technology=gf14lpp]
		#	    set argArray(calexFiles) {}
		#	    set argArray(calexExtraArg) {}
		#	    set argArray(userGDS) false
		#	    set argArray(userNetlist) false
		#	    set argArray(netViewSearch) [list cdl auCdl schematic symbol]
		#	    set argArray(netViewStop) [list]
		#	    set argArray(userMWDB) false
		#	    set argArray(netlister) CDL
		#	    set argArray(netlFormat) cdl
		#	    set argArray(verifPostProc) false
		#	    set argArray(xmap) false
		#	    set argArray(xtPowerExtract) NO
		#	    set argArray(xFormat) SPF
		#	    set argArray(xTempSens) NO
		#	    set argArray(xReduction) NO
		#	    set argArray(xSubExtraction) NO
		#	    set argArray(usercmdFile) 0
		#	    set argArray(xFormatNet) 0
		#	    set argArray(xDpNumCores) 4
		#	    set argArray(xAccuracy) 400
		#	    set argArray(xAnalogSymmetricNets) YES
		#	    set argArray(xCrossRef) YES
		#	    set argArray(xInst) YES
		#	    set argArray(xWidgetsList) [list lstb_1 lstb_diff_1 lstb_2 lstb_diff_2 lstb_3 lstb_diff_3 lstb_4 lstb_diff_4 lstb_5 lstb_diff_5 lstb_6 lstb_diff_6 lstb_7 lstb_diff_7 stb_1 stb_diff_1 stb_2 stb_diff_2 stb_3 stb_diff_3 stb_4 stb_diff_4 stb_5 stb_diff_5 stb_6 stb_diff_6 stb_7 stb_diff_7 va_check_rx_vote_sum va_suck va_check_rx_add_neg va_check_rx_boxcar va_check_rx_estore_neg va_check_rx_int_neg va_check_rx_phug_neg va_measure_jitter_pre_single va_check_rx_vote_sum va_tester_rx]
		#	    set argArray(xPresmult) 1
		#	    set argArray(xPcapmult) 1
		#	    set argArray(xUnflattenNetlist) 1
		#	    set argArray(xAddx) 0
		#	    set argArray(compressedGDS) true
		#	    set argArray(netlistBracketChange) 0
		#	    set argArray(deleteEmptyCell) 0
		#	    set argArray(compressedLVSNetlist) false
		#	    set argArray(onlyGDS) false
		#	    set argArray(onlyNetlist) false
		#	    set argArray(gdsExportTemplateFile) {}
		#	    set argArray(runHerculesServer) localhost
		#	    set argArray(runCalibreServer) localhost
		#	    set argArray(runICVServer) localhost
		#	    set argArray(saveReportandData) true
		#	    set argArray(intDeliveries) false
		#	    set argArray(xGroundNode) 0
		#	    set argArray(xSeparateExtract) 0
		#	    set argArray(renameType) {}
		#	    set argArray(renameCell) {}
		#	    set argArray(targetTopCell) {}
		#	    set argArray(excludeList) {}
		#	    set argArray(virtualConnect) 0
		#	    set argArray(excludeCell) {}
		#	    set argArray(metalShort) {}
		#	    set argArray(operatingTemp) {}
		#	    set argArray(extractViaCaps) {}
		#	    set argArray(cTemplateFile) false
		#	    set argArray(lpePreProcFile) {}
		#	    set argArray(extractedNetlistPProcessor) 1
		#	    set argArray(toolExtraArg) {}
		#	    set argArray(equivFile) {}
		#	    set argArray(blackBoxConfigFile) {}
		#	    set argArray(libFilteredList) {}
		#	    ##  Watch this.  The quotes need to get through.
		#	    set argArray(selectedNetList) {}
		#	    set argArray(listOfDeleteSubs) INACTIVE
		#	    set argArray(actionType) {}
		#	    set argArray(xnetSearchList) [list cdl hspice hspiceD schematic symbol veriloga]
		#	    set argArray(xnetStopList) {}
		#	    set argArray(removeJob) none
		#	    set argArray(importFillLibraryName) false
		#	    set argArray(importFillLocation) false
		#	    set argArray(fillGDSType) false
		#	    set argArray(fillCellCopy) false
		#	    set argArray(flatFillGDS) false
		#	    set argArray(podPostProc) 1
		#	    set argArray(podPostProcOpt) drain
		#	    set argArray(xSubCkt) "-xSubCkt"
		#	    set argArray(xCase) "-xCase"
		#	    set argArray(xrmFloat) ""
		#	    set argArray(xrmDangling) ""
		#	    set argArray(xHierSeparator) ""
		#	    set argArray(confirmRemoveJob) 0
		#	    set argArray(extrPreservedConfigFile) {}
		#	    set argArray(extrPreservedEquivFile) {}
		#	    global IcvRunLVS
		#	    set argArray(runset) $IcvRunLVS


		##  Determine which version of flow to use.
		set pvVersion [file tail $::env(MSIP_CD_PV)]
		if {$pvVersion == "latest"} {set flowVersion "new"} elseif { $pvVersion >= "2016.11"} {set flowVersion "new"} else {set flowVersion "old"}

		##  Load the global default args into argArray
		if [info exists ::alpha::lpe::defaultArgs] {
			foreach argName [array names ::alpha::lpe::defaultArgs] {set argArray($argName) $::alpha::lpe::defaultArgs($argName)}
		}
		if [info exists ::alpha::lpe::defaultArgsByType($type)] {
			##  Type-specific arguments exist.
			foreach arg $::alpha::lpe::defaultArgsByType($type) {
				set argList [split $arg "="]
				set argName [lindex $argList 0]
				set argValue [lindex $argList 1]
				set argArray($argName) $argValue
			}
		}

		## General purpose argument reader.
		##  Put all specified args into argArray, overriding any defaults above.
		for { set i 0 } { $i < [ llength $args ] } { incr i} {
			set theArg [lindex $args $i]
			if {[string index $theArg 0] == "-"} {
				set argName [string trimleft $theArg "-"]
				incr i
				set argVal [lindex $args $i]
				#		puts "Setting $argName = $argVal"
				set argArray($argName) $argVal
			}
		}

		##  Check if ipala option is selected
		if { [info exists argArray(ipala)] } {
			set ipalaPrefix "/ipala"
		} else {
			set ipalaPrefix ""
		}


		## sync netlist to different sites
		if {[info exists argArray(rsync)]} {
			set rsloc [split $argArray(rsync) ":"]
			set site [lindex $rsloc 0]
			set site [string tolower $site]
			set hostID [exec hostname]
			regexp -nocase {^([0-9a-z]{4}).*} $hostID to hostID
			set hostID [string tolower $hostID]
			set location [lindex $rsloc 1]
			set location [string trimright $location "/"]
			de::sendMessage "Remote copy info: Site:$site Location:$location" -severity information
			set siteList [list us01 am04 in01 pl01 pt01 ca06 ca09]
			if {[lsearch $siteList $site] == -1} {
				set theError "Site $site does not exist!"
				de::sendMessage $theError -severity error
				errorGui $theError
				return
			}
			if {$hostID eq $site} {
				de::sendMessage "Current site and targert site are same. Ignoring rsync" -severity information
			}
		}

		##  Handle schematic/layout view names
		if {[info exists argArray(viewSchematicName)]} {set schematicViewName $argArray(viewSchematicName)} else { set schematicViewName "schematic" }
		if {[info exists argArray(viewName)]} {set layoutViewName $argArray(viewName)} else { set layoutViewName "layout" }
		if {[info exists argArray(viewSymbolName)]} {set symbolViewName $argArray(viewSymbolName)} else { set symbolViewName "symbol" }

		set ::run batch
		if {[info exists argArray(run)]} {
			##  The -run arg is specified.
			set ::run $argArray(run)
			set legalRun [list batch interactive int false true 0 1 yes no]
			unset argArray(run)
			if {[lsearch $legalRun $::run] < 0} {
				set theError "Unrecognized run arguments \"$::run\""
				de::sendMessage $theError -severity error
				errorGui $theError
				return
			}
			if {[string is boolean $::run]} {
				if {$::run} {
					set ::run batch
				} else {
					set ::run false
				}
			}
		}

		set tool "icv"
		if {[info exists argArray(tool)]} {
			set tool $argArray(tool)
			unset argArray(tool)
		}

		##  Check outDir for presence of undelet-able netlists.
		if {[info exists argArray(outDir)]} {
			set outDir $argArray(outDir)
		} else {
			set outDir "/remote/proj/$prodName/$projName/$relName/design/$argArray(stack)/netlist/extract/$argArray(cellName)"
		}
		de::sendMessage "outDir = $outDir" -severity information

		##  Where to look for extracted netlist
		set netlistSubdir "rcxt"
		if {$type == "flatRA"} {set netlistSubdir "rcxtra"}
		if {[info exists argArray(checkName)] } {
			set netlistSubdir [string tolower $argArray(checkName)]
		}
		##  HACK ALERT:  Apparent pv bug in which RCXTRA runs go to non-checkout dir even with later pv versions.  Star 9001215820
		if { $pvVersion > "2016.12" } {set netlistDir $outDir/$netlistSubdir/checkout/$::env(USER)} else {set netlistDir $outDir/$netlistSubdir}

		##  Check for genHspice arg
		set genHspice 0
		if {[info exists argArray(genHspice)]} {
			set genHspice $argArray(genHspice)
			unset argArray(genHspice)
		}
		set hspiceDir $outDir
		if {[info exists argArray(hspiceDir)]} {
			set hspiceDir $argArray(hspiceDir)
			unset argArray(genHspice)
		}

		##  Check for the minimum set of required arguments
		set argsOK 1
		set argsOK [checkRequiredArg $args "-libName" $argsOK]
		set argsOK [checkRequiredArg $args "-cellName" $argsOK]

		if {$argsOK != 1} {
			de::sendMessage "Aborting on missing required argument(s)" -severity information
			return
		}

		set check 1
		if {[info exists argArray(nocheck)]} {
			set check 0
			unset argArray(nocheck)
		}
		## Check for SNPS_Check results
		set checkResults {}
		if {($type == "selectedNets") && $check} {
			de::sendMessage "Extraction type is $type, checking required log files" -severity information
			## get tag date
			set localLibPath [oa::getPath [oa::LibFind $argArray(libName)]]
			set localLibPath [file normalize $localLibPath]
			catch {set libPathDepot [lindex [exec p4 where $localLibPath/... 2> /dev/null] 0]}
			if {$libPathDepot == ""} {
				set theError "Library \"$libName\" is unmanaged; no tag files will exist"
				de::sendMessage $theError -severity error
				errorGui $theError
				return
			}
			set libPathDepot [regsub -all {/\.\.\.} $libPathDepot ""]
			set tagfileName "$libPathDepot/$argArray(cellName).tag"
			set tagLatest $tagfileName
			if [info exists argArray(rev)] {set tagfileName "$tagfileName#$argArray(rev)"}
			de::sendMessage "Set tag path to: $tagfileName" -severity information
			update

			set noTag [catch {exec p4 fstat $tagfileName}]

			if {$noTag} {
				set theError "Tag not found: $tagfileName. Abort."
				de::sendMessage $theError -severity error
				errorGui $theError
				return
			}

			set filelog [exec p4 fstat -T 'headModTime, headRev' $tagfileName]
			regexp -nocase {headModTime ([0-9]+)} $filelog -> tagDate
			#		regexp {headRev ([0-9]+)} $filelog -> rev

			## Check existance of log file, and compare dates w/ tag
			if {[info exists argArray(snpsCheck)]} {
				set snpsDefault $argArray(snpsCheck)
			} else {
				set snpsDefault "//wwcad/msip/projects${ipalaPrefix}/$prodName/$projName/latest/design/timing/bbox/$argArray(cellName).LAYOUT_ERRORS"
			}
			logCheckInfo "Info:  snpsDefault = $snpsDefault"

			if [info exists argArray(bboxLvs)] {
				set bboxLvsDefault $argArray(bboxLvs)
			} else {
				set bboxLvsDefault "//wwcad/msip/projects${ipalaPrefix}/$prodName/$projName/latest/design/timing/bbox/$argArray(cellName).RESULTS"
			}
			logCheckInfo "Info:  bboxLvsDefault = $bboxLvsDefault"

			## check if log is on p4 or disk, and check existence
			set sP4 0
			set bP4 0
			if {[regexp -nocase {//wwcad/.*} $snpsDefault]} {
				set invalid [catch {exec p4 files $snpsDefault}]
				if {!$invalid} {
					set sP4 1
					set snpsCheckResult $snpsDefault
					set filelog [exec p4 fstat -T 'headModTime' $snpsCheckResult]
					regexp -nocase {headModTime ([0-9]+)} $filelog -> snpsDate
				} else {
					set theError "snps log not found at default location on p4. Abort."
					de::sendMessage $theError -severity error
					errorGui $theError
					return
				}
			} elseif {[file exists $snpsDefault]} {
				set snpsCheckResult $snpsDefault
				set snpsDate [file mtime $snpsCheckResult]
				logCheckInfo "Warning: snps_check log file on disk, please check in on p4"
			} else {
                set theError "snps log not found at default location on p4 or disk. Abort."
				de::sendMessage $theError -severity error
				errorGui $theError
				return
			}

			if {[regexp -nocase {//wwcad/.*} $bboxLvsDefault]} {
				set invalid [catch {exec p4 files $bboxLvsDefault}]
				if {!$invalid} {
					set bP4 1
					set bboxLvsResult $bboxLvsDefault
					set filelog [exec p4 fstat -T 'headModTime' $bboxLvsResult]
					regexp -nocase {headModTime ([0-9]+)} $filelog -> bboxLvsDate
				} else {
					set theError  "bboxLvs log not found at default location on p4. Abort."
					de::sendMessage $theError -severity error
					errorGui $theError
					return
				}
			} elseif {[file exists $bboxLvsDefault]} {
				logCheckInfo "Warning: bboxLvs log file on disk, please check in on p4"
				set bboxLvsResult $bboxLvsDefault
				set bboxLvsDate [file mtime $bboxLvsResult]
			} else {
				set theError  "bboxLvs log not found at default location on p4 or disk. Abort."
				de::sendMessage $theError -severity error
				errorGui $theError
				return
			}

			# Check if SNPS_CHECK and Bbox LVS is run after latest tag revision
			if {($snpsDate < $tagDate) || ($bboxLvsDate < $tagDate) } {
				logCheckInfo "Warning: SNPS_CHECK or Bbox LVS is run before latest tag revision, please re-run"
				update
			}

			# Check if log files are clean
			if {$sP4} {
				#Log file on p4
				set noErr [catch {exec p4 annotate $snpsCheckResult | grep -i "SNE Error: "}]
				if {!$noErr} {
					set theError "SNPS_CHECK result has SNE Error. Abort."
					de::sendMessage $theError -severity error
					errorGui $theError
					return
				}
				set noWarn [catch {set sneWarning [exec p4 annotate $snpsCheckResult | grep -i "SNE Warning: "]}]
				if {!$noWarn} {logCheckInfo "SNPS_CHECK result has $sneWarning"}
			} else {
				#Log file on disk
				set fIn [open $snpsCheckResult r]
				#			puts $fIn "Warning: snps_check log file not on p4, using log on disk, please check in"
				while {[gets $fIn line] >= 0} {
					if {[regexp -nocase {SNE Error: } $line]} {
						set theError "SNPS_CHECK result has SNE Error. Abort."
						de::sendMessage $theError -severity error
						errorGui $theError
						return
					} elseif {[regexp -nocase {SNE Warning: .+} $line sneWarning]} {
						logCheckInfo "SNPS_CHECK result has $sneWarning"
					}
				}
				close $fIn
			}

			# Check if bboxLvs waivers have been used
			set waiveOk 0
			if {[info exists argArray(bboxWaive)]} {
				set bboxWaiverDir $argArray(bboxWaive)
				logCheckInfo "Info: Waiver has been used for bboxLvs. Path: $argArray(bboxWaive)"
				if {[regexp -nocase {//wwcad/.*} $bboxWaiverDir]} {
					# waiver is on p4
					set invalid [catch {exec p4 files $bboxWaiverDir}]
					if {!$invalid} {
						set data [exec p4 annotate $bboxWaiverDir]
						set line [split $data "\n"]
						if {[lindex $line 2] != ""} {
							set waiveOk 1
						} else {
							logCheckInfo "Waiver file is empty. Abort."
							return
						}
					} else {
						logCheckInfo "Waiver file does not exist on p4. Abort."
						return
					}
				} elseif {[file exists $bboxWaiverDir]} {
					# waiver is on disk
					logCheckInfo "Warning: Waiver file on disk, please check in on p4"
					set fIn [open $bboxWaiverDir r]
					set data [read $fIn]
					close $fIn
					set line [split $data "\n"]
					if {[lindex $line 1] != ""} {
						set waiveOk 1
					} else {
						logCheckInfo "Waiver file is empty. Abort."
						return
					}
				} else {
					logCheckInfo "Waiver file does not exist on p4 or disk. Please enter correct the path."
					return
				}
			}

			if {$bP4} {
				#Log file on p4
				set notClean [catch {exec p4 annotate $bboxLvsResult | grep -i "LVS Compare Results: PASS"}]
				#			logCheckInfo "p4 bbox check pass 0 nopass 1: $notClean"
				if {$notClean} {
					if {!$waiveOk} {
						#no waiver
						logCheckInfo "Error: Bbox LVS check is not clean. Abort."
						return
					} else {
						logCheckInfo "Warning: Bbox LVS check is not clean. Has waiver."
					}
				}
			} else {
                #Log file on disk
				set fIn [open $bboxLvsResult r]
				while {[gets $fIn line] >= 0} {
					# logCheckInfo "disk bbox check pass 0 nopass 1: [regexp -nocase {LVS Compare Results:\s*FAIL} $line]"
					if {[regexp -nocase {LVS Compare Results:\s*FAIL} $line]} {
						if {!$waiveOk} {
							#no waiver
							logCheckInfo "Error: Bbox LVS check is not clean. Abort."
							return
						} else {logCheckInfo "Warning: Bbox LVS check is not clean. Has waiver."}
					}
				}
				close $fIn
			}

			if {[info exists argArray(p4Sync)] && $argArray(p4Sync)} {
                set tagWhere [exec p4 where $tagLatest 2> /dev/null]
				if {$tagWhere != ""} {
					set buff [split $tagWhere " "]
					set tagDir [lindex $buff 2]
					logCheckInfo "Set lib path to [file dirname $tagDir]"
					cd [file dirname $tagDir]
					catch {exec p4 sync $tagfileName} done
					puts $done
					logCheckInfo "Syncing library based on tag"
					catch {exec ./alphaSyncTag $argArray(cellName).tag} done1
					puts $done1
					logCheckInfo "Sync completed, please refer to log above for details"
					update
				} else {
					logCheckInfo "tagFile \"$tagfileName\" is not under user client."
					update
				}
			}
		}

		##  Check for -virtualConnect.  Needs special handling depending on state of pref MSIPRCXTicvVirtualConnect
		if {[info exists argArray(virtualConnect)]} {
			set vc [string toupper $argArray(virtualConnect)]
			set scope [dm::findCell $argArray(cellName) -libName $argArray(libName)]
			if {[db::isEmpty [db::getPrefs MSIPRCXTicvVirtualConnect]] } {
				set virtConnIcv 0
			} else {
				set virtConnIcv [db::getPrefValue MSIPRCXTicvVirtualConnect]
			}

			if {$virtConnIcv} {
				##  Values should be ON, OFF or CUSTOM.
				de::sendMessage "virtConnIcv is TRUE" -severity information
				if {($vc != "ON") && ($vc != "OFF") && ($vc != "CUSTOM")} {
					if {[string is boolean $vc]} {
						if $vc {set vc "ON"} else {set vc "OFF"}
					} else {
						set theError "Could not interpret value for virtualConnect \"$vc\""
						de::sendMessage $theError -severity error
						errorGui $theError
						return
					}
				}
			} else {
				##  Should be boolean. Convert ON/OFF.. Not sure why this is; ON/OFF are legit booleans
				de::sendMessage "virtConnIcv is FALSE" -severity information
				if {$vc == "CUSTOM"} {
					set theError "virtualConnect \"CUSTOM\" not supported"
					de::sendMessage $theError -severity error
					errorGui $theError
					return
				} elseif {[string is boolean $vc]} {
					if {$vc} {set vc 1} else {set vc 0}
				} else {
					set theError "Could not interpret value for virtualConnect \"$vc\""
					de::sendMessage $theError -severity error
					errorGui $theError
					return
				}
			}

			if {$vc==1 && $tool=="calibre"} {set vc "ALL"}
			set argArray(virtualConnect) $vc
			de::sendMessage "virtualConnect = $vc" -severity information
		}

		set cellOK 1
		if {![oa::DesignExists $argArray(libName) $argArray(cellName) $layoutViewName]} {
			set theError "Cell $argArray(libName)/$argArray(cellName)/$layoutViewName does not exist"
			de::sendMessage $theError -severity error
			errorGui $theError
			set cellOK 0
		}
		if {![oa::DesignExists $argArray(libName) $argArray(cellName) $schematicViewName]} {
			set theError "Cell $argArray(libName)/$argArray(cellName)/$schematicViewName does not exist"
			de::sendMessage $theError -severity error
			errorGui $theError
			set cellOK 0
		}
		if {![oa::DesignExists $argArray(libName) $argArray(cellName) $symbolViewName]} {
			set theError "Cell $argArray(libName)/$argArray(cellName)/$symbolViewName does not exist"
			de::sendMessage $theError -severity error
			errorGui $theError
			set cellOK 0
		}

		## Validiate corners listed in cornerVal
		set cornerOK 1
		if {[info exists argArray(cornerVal)]} {
			if {![beolCornerIsValid $argArray(cornerVal)]} {
				set cornerOK 0
			}
		}
		set tempOK 1
		if {[info exists argArray(operatingTemp)]} {
			##  Build a very clean version, without extraneous whitespace, just in case.
			set operatingTemp_upd ""
			set sep ""
			## operatingTemp is specified.  Attempt to validate
			set toks [split $argArray(operatingTemp) ","]
			foreach t $toks {
				##  Expecting a space-separated "corner temp" pair
				if {[llength $t] == 2} {
					set tc [lindex $t 0]
					set tt [lindex $t 1]
					append operatingTemp_upd "$sep$tc $tt"
					set sep ","
					if {![beolCornerIsValid $tc]} {set tempOK 0}
					if {![string is integer $tt]} {
						set theError "Expecting integer for temp in \"$t\""
						de::sendMessage $theError -severity error
						errorGui $theError
						set tempOK 0
					}

				} else {
					set theError "Invalid corner/temp pair \"$t\""
					de::sendMessage $theError -severity error
					errorGui $theError
					set tempOK 0
				}
			}
			set argArray(operatingTemp) $operatingTemp_upd
		}
		if {!($cornerOK && $tempOK && $cellOK)} {
			de::sendMessage "Aborting" -severity information
			return
		}

		##  Special handling for XTMapFile
		##  XTMapFile is currently dropped, mapFile_list does work, but expects to be a list of corner/mapfile pairs.
		##  So, if XTMapFile is specified, convert to mapFile_list
		if {[info exists argArray(XTMapFile)] && [info exists argArray(cornerVal)]} {
			set mapFile_list {}
			foreach c $argArray(cornerVal) {
				lappend mapFile_list $c
				lappend mapFile_list $argArray(XTMapFile)
			}
			set argArray(mapFile_list) $mapFile_list
		}

		## Get rundir defined because we use it here.
		if {![info exists ::env(udescratch)]} {
			set theError "udescratch is undefined"
			de::sendMessage $theError -severity error
			errorGui $theError
			return
		}

		if {![info exists argArray(rundir)]} {
			set argArray(rundir) "$::env(RUN_DIR_ROOT)/$argArray(libName)/$argArray(cellName)"
			# set argArray(rundir) "$::env(udescratch)/$user/$prodName/$projName/$relName/verification/$argArray(stack)/$argArray(libName)/$argArray(cellName)"
		}

		if {![file exists $argArray(rundir)]} {file mkdir $argArray(rundir)}

		##  Set some default args based on extraction type
		if {$type == "flat"} {
			if {![info exists argArray(runFlat)] } { set argArray(runFlat) false }
			set pvprefix "RCXT"
		} elseif {$type == "flatRA"} {
			if {![info exists argArray(runFlat)] } { set argArray(runFlat) false }
			set pvprefix "RCXTRA"
		} elseif {$type == "selectedNets"} {
			set pvprefix "RCXT"
			set argArray(runFlat) false
			set argArray(extractedNetlistPProcessor) 0
			# set argArray(usercmdFile) 0

			## Instead, using env variable to point to necessary runset.
			if {[info exists ::env(icvSelectedNetsRunset)]} {
				if {[file exists $::env(icvSelectedNetsRunset)]} {
					de::sendMessage "runset = $::env(icvSelectedNetsRunset)" -severity information
					set argArray(runset) $::env(icvSelectedNetsRunset)
				} else {
					set theError "Runset file \"$::env(icvSelectedNetsRunset)\" not found"
					de::sendMessage $theError -severity error
					errorGui $theError
					return
				}
			}

			## Instead, using env variable to point to necessary runset.
			if {[info exists ::env(icvSelectedNetsSourceFile)]} {
				if {[file exists $::env(icvSelectedNetsSourceFile)]} {
					de::sendMessage "sourceFile = $::env(icvSelectedNetsSourceFile)" -severity information
					set argArray(sourceFile) $::env(icvSelectedNetsSourceFile)
				} else {
					set theError "Sourceme file \"$::env(icvSelectedNetsSourceFile)\" not found"
					de::sendMessage $theError -severity error
					errorGui $theError
					return
				}
			}

			#####  Generate config and equiv files, if necessary.
			if {![info exists argArray(extrPreservedConfigFile)] || ![info exists argArray(extrPreservedEquivFile)]} {
				##  Config or Equiv files not provided.  Create.
				de::sendMessage "Generating stop list:" -severity information
				##  Reads the project-level bbox list
				readBboxlist
				set stop [genStoplist $argArray(libName) $argArray(cellName)]
				foreach sl $stop {puts "\t$sl"}
				puts ""
			}


			if {$flowVersion eq "old"} {
				##  Original SNE flow.  Create config/equiv files
				if {![info exists argArray(extrPreservedConfigFile)]} {
					set argArray(extrPreservedConfigFile) "$argArray(rundir)/$argArray(cellName).config"
					de::sendMessage "Creating $argArray(extrPreservedConfigFile)" -severity information
					set extrPreservedConfig ""
					set sep ""
					foreach sl $stop {
						append extrPreservedConfig "$sep\"$sl\""
						set sep ","
					}
					set config [open $argArray(extrPreservedConfigFile) w]
					puts $config $extrPreservedConfig
					close $config
				}

				if {![info exists argArray(extrPreservedEquivFile)]} {
					set argArray(extrPreservedEquivFile) "$argArray(rundir)/$argArray(cellName).equiv"
					de::sendMessage "Creating $argArray(extrPreservedEquivFile)" -severity information
					set extrPreservedEquiv ""
					set sep ""
					foreach sl $stop {
						append extrPreservedEquiv "$sep$sl"
						set sep " "
					}
					puts ""
					set equiv [open $argArray(extrPreservedEquivFile) w]
					puts $equiv $extrPreservedEquiv
					close $equiv
				}
			} else {
				##  New flow.  Single bbox config
				if {![info exists argArray(blackBoxConfigFile)]} {
					set argArray(blackBoxConfigFile) "$argArray(rundir)/$argArray(cellName).bbox.config"
					de::sendMessage "Creating $argArray(blackBoxConfigFile)" -severity information
					set config [open $argArray(blackBoxConfigFile) w]
					foreach sl $stop {
						puts $config $sl
					}
					close $config
				}
				set argArray(blackBoxEnabled) 1
				if {$pvVersion >= "2018.07"} { set argArray(superconductivePorts) "SUPERCONDUCTIVE"
				} else { set argArray(superconductivePorts) 1 }
				set argArray(preserveBlackBoxCells) 1
			}

		} else {
			set theError "Unrecognized extraction type \"$type\""
			de::sendMessage $theError -severity error
			errorGui $theError
			return
		}

		# To allow use of "Custom" PCS menu, based on RCXT settings
		if {[info exists argArray(checkName)]} {
			if {($pvprefix == "RCXT") && ($type == "flat")} {
				set pvprefix $argArray(checkName)
				# pv does not take this setting from GUI
				if {![info exists argArray(extractedNetlistPProcessor)]} {
					set argArray(extractedNetlistPProcessor) 1
				}
			} else {
				set theError "Custom check is allowed only for type \"flat\" (derived from RCXT) "
				de::sendMessage $theError -severity error
				errorGui $theError
				return
			}
		}
                if {[info exists argArray(xTypes)] && [info exists argArray(xtPowerNets)] } {
		set supplyNets $argArray(xtPowerNets)
		   ##  Set variables for different extraction types
		   set xtSelNetsSRCCPCC [list RCC "*"]
		   set xtSelNetsSCCPRCC [list CC "*"]
		   set xtSelNetsCCSSRCC [list CC "*"]
		   foreach supply $supplyNets {
			   lappend xtSelNetsSRCCPCC "!$supply"
			   lappend xtSelNetsSCCPRCC "!$supply"
			   lappend xtSelNetsCCSSRCC "!$supply"
		   }
		   lappend xtSelNetsSRCCPCC "CC"
		   lappend xtSelNetsSCCPRCC "RCC"
		   lappend xtSelNetsCCSSRCC "RCC"

		   set xtSelNetsSRCCPCC [concat $xtSelNetsSRCCPCC $supplyNets]
		   set xtSelNetsSCCPRCC [concat $xtSelNetsSCCPRCC $supplyNets]
		   set xtSelNetsCCSSRCC [concat $xtSelNetsCCSSRCC $supplyNets]

                   #foreach t $argArray(xTypes) {
		   #   set t [string tolower $t]
		   #   if { $t == "srccpcc" } { set argArray(xtSelNetsSRCCPCC) $xtSelNetsSRCCPCC }
		   #   if { $t == "sccprcc" } { set argArray(xtSelNetsSCCPRCC) $xtSelNetsSCCPRCC }
		   #   if { $t == "ccssrcc" } { set argArray(xtSelNetsCCSSRCC) $xtSelNetsCCSSRCC }
                   #}
		   if { [lsearch -exact $argArray(xTypes) "srccpcc"] != -1 } { set argArray(xtSelNetsSRCCPCC) $xtSelNetsSRCCPCC }
		   if { [lsearch -exact $argArray(xTypes) "sccprcc"] != -1 } { set argArray(xtSelNetsSCCPRCC) $xtSelNetsSCCPRCC }
		   if { [lsearch -exact $argArray(xTypes) "ccssrcc"] != -1 } { set argArray(xtSelNetsCCSSRCC) $xtSelNetsCCSSRCC }

		}

        ##  Handle extraction types
		##  Take arg named "Xtypes", a list of the desired types, turn it into mask list rcxtTypes

		##  By default, run srccpcc
		###LNif {![info exists argArray(xTypes)]} {set argArray(xTypes) srccpcc}

		set rcxtTypeNames [list r c cc rc rcc srccpcc sccprcc ccssrcc]
		if {[info exists argArray(xTypes)]} {
			set typeMatched 0
			set rcxtTypes [list 0 0 0 0 0 0 0 0]
			foreach t $argArray(xTypes) {
				set t [string tolower $t]
				set idx [lsearch -exact $rcxtTypeNames $t]
				if {$idx >= 0} {
					set rcxtTypes [lreplace $rcxtTypes $idx $idx 1]
					set typeMatched 1
					#		    puts "Found type $t, idx=$idx"
				} else {
					set theError "Unrecognized xType \"$t\";  Ignoring"
					de::sendMessage $theError -severity error
					errorGui "$theError\nAccepted types: {$rcxtTypeNames}"
					puts "\tAccepted types: {$rcxtTypeNames}"
				}
			}
			if {$typeMatched} {
				if [info exists argArray(rcxtTypes)] {
					de::sendMessage "Warning:  Both xTypes and rcxtTypes are defined.  Using xTypes" -severity warning
				}
				set argArray(rcxtTypes) $rcxtTypes
			} else {
				de::sendMessage "No recognized xTypes defined." -severity warning
			}
		}

		set pvbatchConfigFile "$argArray(rundir)/$argArray(cellName).$type.pvbatch.config"
		set config [open $pvbatchConfigFile w]
		puts $config "set runExtractType $type"
	    foreach argName [array names argArray] {
            ## Use quotes for cornerVal (pv_batch bug), braces otherwise
            ##  Unconditionally quoting
            if {$argName == "cornerVal"} {
				puts $config "set $argName \"$argArray($argName)\""
			} else {
				puts $config "set $argName {$argArray($argName)}"
			}
		}

		##  Check for the presence of operatingTemp prefs.
		foreach c [array names ::validCorners] {
			set prefName "MSIP${pvprefix}operatingTemp$c"
			if {![db::isEmpty [db::getPrefs $prefName]] } {
				set prefValue [db::getPrefValue $prefName]
				puts $config "set runExtractOperatingTemp($c) \"$prefValue\""
			}
		}

		puts $config "set alphaNetlistDir $netlistDir"
		## Dump contents of checkResults
		foreach l $checkResults {puts $config "lappend alphaCheckResults {$l}"}
		close $config
		de::sendMessage "Created  $pvbatchConfigFile" -severity information

		set pvbatchSourcemeFile "$argArray(rundir)/$argArray(cellName).$type.pvbatch.sourceme"
		set sourceme [open $pvbatchSourcemeFile w]
		if {[info exists env(MSIP_CD_VERSION)]}      {puts $sourceme "setenv MSIP_CD_VERSION $env(MSIP_CD_VERSION)"}
		if {[info exists env(MSIP_MAXWELL_VERSION)]} {puts $sourceme "setenv MSIP_MAXWELL_VERSION $env(MSIP_MAXWELL_VERSION)"}
		if {[info exists ::env(P4PORT)]} {puts $sourceme "setenv P4PORT $::env(P4PORT)"} else {puts "Warning:  No definition for P4PORT"}
		if {[info exists ::env(P4CLIENT)]} {puts $sourceme "setenv P4CLIENT $::env(P4CLIENT)"} else {puts "Warning:  No definition for P4CLIENT"}

		##  Handle icvVersion arg.
		set icvVersion $env(MSIP_ICV_VERSION)
		if { (![db::isEmpty [db::getPrefs MSIP${pvprefix}icvVersion]]) && ($type != "selectedNets") } {
			##  icv version is set by pref
			set icvv [db::getPrefValue MSIP${pvprefix}icvVersion]
			##  Sometimes gets set to an empty string
			if {$icvv != "" && ($icvVersion == $icvv)} {set icvVersion $icvv}
		} elseif { ($type == "selectedNets") && (![db::isEmpty [db::getPrefs MSIPRCXTBBicvVersion]]) } {
			##  modified this in a very cheap way to handle RCXTBB version change error
			set icvv [db::getPrefValue MSIPRCXTBBicvVersion]
			if {$icvv != ""} {set icvVersion $icvv}
		}
		if {[info exists argArray(icvVersion)]} {set icvVersion $argArray(icvVersion)}

		puts $sourceme "setenv MSIP_ICV_VERSION $icvVersion"
		##   This is a bit of a hack to allow pcs.tcl to pick up the version and set a pref
		puts $sourceme "setenv ALPHA_ICV_VERSION_RCXT $icvVersion"
		puts $sourceme "setenv MSIP_STARRCXT_VERSION $env(MSIP_STARRCXT_VERSION)"

		##  Find pv version
		set modules $env(LOADEDMODULES)
		set modList [split $modules ":"]
		#	foreach m $modList {puts "\t$m"}
		set i [lsearch -glob $modList "msip_cd_pv/*"]
		set pvModule [lindex $modList $i]
		puts $sourceme "module unload msip_cd_pv"
		puts $sourceme "module load $pvModule"
		set i [lsearch -glob $modList "ddr-utils/*"]
		# If the version for the ddr-utils is not defined, load the latest version: P10023532-46136
		if {$i == -1} {
			de::sendMessage "The default ddr-utils version was not set for this project, using the latest version instead." -severity "warning"
			set ddrUtilsModule "ddr-utils"
		} else {
			set ddrUtilsModule [lindex $modList $i]
		}
		puts $sourceme "module unload ddr-utils"
		puts $sourceme "module load $ddrUtilsModule"
		close $sourceme
		puts "Created  $pvbatchSourcemeFile"

		##  This is a tcl file that will be executed onm CC startup.  Handy for setting preferences.
		set pvbatchCmdFile "$argArray(rundir)/$argArray(cellName).$type.pvbatch.cc.tcl"
		set cmdFile [open $pvbatchCmdFile w]
		puts $cmdFile "puts \"Executing $pvbatchCmdFile\""
		if { ($type == "selectedNets") && (![db::isEmpty [db::getPrefs MSIPRCXTBBicvVersion]]) } {
			puts $cmdFile "#this stupid thisng is here"
			puts $cmdFile "alpha::lpe::CreateSetPref MSIPRCXTBBicvVersion $icvVersion runLevelOverride"
		} else {
			puts $cmdFile "alpha::lpe::CreateSetPref MSIP${pvprefix}icvVersion $icvVersion runLevelOverride"
		}
		close $cmdFile

		set ::pvbatchScript "$argArray(rundir)/$argArray(cellName).$type.pvbatch.csh"
		set pvbatchLog "$argArray(rundir)/$argArray(cellName).$type.pvbatch.log"
		set ::RUNDIR  $argArray(rundir)
		set ::CELLNAME $argArray(cellName)
		set ::TYPE $type
		set script [open $::pvbatchScript w]
		puts $script "\#!/bin/csh"
		if { $argArray(useGrid) == 0 } {
			puts $script "setenv HOME /u/$user"
			puts $script "source /remote/cad-rep/etc/.cshrc"
		}
		puts $script "module unload msip_cd_pv"
		puts $script "module load $pvModule"
		puts $script "module unload ddr-utils"
		puts $script "module load $ddrUtilsModule"

		if {[info exists ::env(P4PORT)]} {puts $script "setenv P4PORT $::env(P4PORT)"} else {puts "Warning:  No definition for P4PORT"}
		if {[info exists ::env(P4CLIENT)]} {puts $script "setenv P4CLIENT $::env(P4CLIENT)"} else {puts "Warning:  No definition for P4CLIENT"}

		puts $script "pvbatch \\"
		puts $script " --projectType $prodName \\"
		puts $script " --projectName $projName \\"
		puts $script " --releaseName $relName \\"
		puts $script " --metalStack $argArray(stack) \\"
		puts $script " --type lpe \\"
		puts $script " --prefix $pvprefix \\"
		puts $script " --libName $argArray(libName) \\"
		puts $script " --cellName $argArray(cellName) \\"
		puts $script " --tool $tool \\"
		puts $script " --config $pvbatchConfigFile \\"
		#	puts $script " --udeArgs \'--sourceShellFile $pvbatchSourcemeFile --log $pvbatchLog --cdArg \"-tcl $pvbatchCmdFile\"\'"
		puts $script " --udeArgs \'--sourceShellFile $pvbatchSourcemeFile --log $pvbatchLog\'"
		puts $script ""
		puts $script "alphaCheckExtractResults.tcl \\"
		puts $script " --projectType $prodName \\"
		puts $script " --projectName $projName \\"
		puts $script " --releaseName $relName \\"
		puts $script " --metalStack $argArray(stack) \\"
		puts $script " --type lpe \\"
		puts $script " --prefix $pvprefix \\"
		puts $script " --libName $argArray(libName) \\"
		puts $script " --cellName $argArray(cellName) \\"
		puts $script " --tool $tool \\"
		puts $script " --config $pvbatchConfigFile \\"
		puts $script " --udeArgs \'--sourceShellFile $pvbatchSourcemeFile --log $pvbatchLog ' \\"
		puts $script " --scriptArgs \'$scriptArgs\' \\"
        if {[info exists argArray(bbox_qa)]} {
            puts $script " --bbox_qa $argArray(bbox_qa) \\"
            if {[info exists argArray(cornerVal)]} {
                puts $script " --cornerVal $argArray(cornerVal) \\"
            }
            puts $script " --bboxConfig $argArray(blackBoxConfigFile) \\"
            if {[info exists argArray(xtGroundNode)]} {
                puts $script " --xtGroundNode \"$argArray(xtGroundNode)\" \\"
            }
            if {[info exists argArray(xTypes)]} {
                puts $script " --xTypes $argArray(xTypes) \\"
            }
            if {[info exists argArray(xtPowerExtract)]} {
                puts $script " --xtPowerExtract \"$argArray(xtPowerExtract)\" \\"
            }
            if {[info exists argArray(xReduction)]} {
                puts $script " --xReduction $argArray(xReduction) \\"
            }
            if {[info exists argArray(xTempSens)]} {
                puts $script " --xTempSens $argArray(xTempSens) \\"
            }
            if {[info exists argArray(xtPowerNets)]} {
                puts $script " --xtPowerNets \"$argArray(xtPowerNets)\" \\"
            }
            puts $script " --stdcell $argArray(stdcell) \\"
        }
        if {[info exists argArray(checkIn)]} {
            puts $script " --checkIn $argArray(checkIn)"
        }
         if {[info exists argArray(rsync)]} {
			if {$hostID eq $site} {
				puts $script "\n"
			} else {
				puts $script "\\\n --rsync \'$site $location\' "
			}
		} else {
			puts $script "\n"
		}

		close $script
		file attributes $::pvbatchScript -permissions "+x"
		de::sendMessage "Created  $::pvbatchScript" -severity information

		set ok 1
		set rawFiles [glob -nocomplain "$netlistDir/ideal_*.raw"]
		array unset rawMap
		## Build map of .raw files, mapping to all lowercase for more robust deletion
		foreach rawFile $rawFiles {set rawMap([string tolower $rawFile]) $rawFile}
		foreach t $argArray(xTypes) {
			set idealFile [string tolower "$netlistDir/ideal_$t.raw"]
			if [info exists rawMap($idealFile)] {
				de::sendMessage "Removing $idealFile" -severity information
				file delete -force $rawMap($idealFile)
				if [file exists $idealFile] {
					set theError "Could not delete $rawMap($idealFile)"
					de::sendMessage $theError -severity error
					errorGui $theError
					set ok 0
				}
			}
		}
		if {!$ok} {
			de::sendMessage "Aborting on inability to predelete .raw file(s)" -severity information
			return
		}

		set proceed 1
		if {[info exists argArray(tag)] && ![info exists argArray(notag)]} {
			##  We will be running the p4 tagging script
			if {$::p4TagScript} {
				set tagInfo [alpha::tag::tagHierarchy -libName $argArray(libName) -cellName $argArray(cellName) -layView $layoutViewName -schView $schematicViewName -symView $symbolViewName -checkin false]
				set tagFileDepot [lindex $tagInfo 0]
				set tagStatus [lindex $tagInfo 1]
				set tagMessage [lindex $tagInfo 2]

				if {$tagFileDepot == ""} {
					##  Tag file failed for some reason.
					if [alpha::tag::verifyProceed "Tagging failed or was aborted.  Proceed with extract?"] {set proceed 1} else {set proceed 0}
				} else {
					if [alpha::tag::getErrorCode $tagStatus ERRORS_IGNORED] {
						##  Errors existed, but were ignored.  Revert tagFile
						catch {exec p4 revert $tagFileDepot}
						if [alpha::tag::verifyProceed "Tag errors existed.  Proceed with extract?"] {set proceed 1} else {set proceed 0}
					}
				}

				if {$proceed && ($tagFileDepot != "")} {
					##  TagFile exists, and we're good to go.
					set tagFileWhere [exec p4 where $tagFileDepot]
					set tagFile [lindex $tagFileWhere 2]
					if {$tagFileWhere != ""} {
						de::sendMessage "Tag completed." -severity information
						set config [open $pvbatchConfigFile a]
						puts $config "set tagFile $tagFile"
						close $config
					}
				}
			} else {
				set theError "p4 tagging script was not found"
				de::sendMessage $theError -severity error
				errorGui $theError
			}
		}

		if $proceed {
			if [info exists argArray(qOpts)] {set qOpts $argArray(qOpts)} else {set qOpts ""}
			execExtract $qOpts $argArray(useGrid)

			if $genHspice {
				de::sendMessage "Generating Hspice netlist" -severity information
				genHspiceNetlist $argArray(libName) $argArray(cellName) $hspiceDir
			}
		}
	}
}

##  Obsolete stuff
#    proc runBBextract {args} {
#	global bboxCells
#	global bboxLibs
#	global env
#	global cellList
#	global stopList
#	global RCXTRunGRD_typical
#	# Functional corners
#	global RCXTRunGRD_FuncCmax
#	global RCXTRunGRD_FuncCmin
#	global RCXTRunGRD_FuncRCmax
#	global RCXTRunGRD_FuncRCmin
#	# Sigma corners (3-sigma performance range of hardware for BEOL)
#	global RCXTRunGRD_SigCmax
#	global RCXTRunGRD_SigCmin
#	global RCXTRunGRD_SigRCmax
#	global RCXTRunGRD_SigRCmin
#	# DPT Sigma corners
#	global RCXTRunGRD_SigCmaxDP_ErPlus
#	global RCXTRunGRD_SigCminDP_ErMinus
#	global RCXTRunGRD_SigRCmaxDP_ErPlus
#	global RCXTRunGRD_SigRCminDP_ErMinus
#	# DPT Functional corners
#	global RCXTRunGRD_FuncCmaxDP_ErPlus
#	global RCXTRunGRD_FuncCminDP_ErMinus
#	global RCXTRunGRD_FuncRCmaxDP_ErPlus
#	global RCXTRunGRD_FuncRCminDP_ErMinus
#
#
#
#	set pvprefix "RCXT"
#	## Pre-fill arg array with defaults.
#	set user $env(USER)
#	set prodName $env(MSIP_PRODUCT_NAME)
#	set projName $env(MSIP_PROJ_NAME)
#	set relName $env(MSIP_REL_NAME)
#	set CCS "/remote/proj/cad/$env(MSIP_CAD_PROJ_NAME)/$env(MSIP_CAD_REL_NAME)"
#
#	set argArray(stack) $env(METAL_STACK)
#	set argArray(optionsFile) [findOptions $env(RCXTOptionsFile) icv]
#	set projHome $env(PROJ_HOME)
#	set argArray(xCorner) typical
#	##  This file would be subject to change, depending on how the icv directories are structured
#	set argArray(sourceFile) "$projHome/cad/$argArray(stack)/options/icv/LVS/RCXTBB_sourceme"
#	set argArray(layermap) $env(LayerMapFile)
#	set argArray(xcmdFile) $env(RCXTcmdFile)
#	set argArray(netlistPProcesor) $env(RCXTnetlistPostProc)
#	set argArray(incNetlist) $env(RCXTincludeNetlist)
#	set argArray(xInstFile) $env(RCXTXdevFile)
#	set argArray(xtPowerNets) [list VDD VDDQ VSS]
#	set argArray(tool) icv
#	set argArray(calibreFlat) "-hier"
#	set argArray(runFlat) {}
#	set argArray(icvOpts) " -dp2 "
#	set argArray(pvprefix) $pvprefix
#	set argArray(viewName) "layout"
#	set argArray(viewSchematicName) "schematic"
#	set argArray(viewSchematicLibName) ""
#	set argArray(pinOptionsFile) false
#	set argArray(pcsOptionsFile) false
#	set argArray(objectLayermap) false
#	set argArray(nettranOptions) [list -slash -cdl-a -mprop]
#	set argArray(gridOpts) [list -conf /remote/sge/cells/snps/common/settings.sh -dp4 -WS5.0 -quick -wait]
#	set argArray(gridOS) -WS5.0
#	set argArray(gridProc) -dp4
#	set argArray(calexOpts) [list --gds  --technology=gf14lpp]
#	set argArray(calexFiles) {}
#	set argArray(calexExtraArg) {}
#	set argArray(userGDS) false
#	set argArray(userNetlist) false
#	set argArray(netViewSearch) [list cdl auCdl schematic symbol]
#	set argArray(netViewStop) [list]
#	set argArray(userMWDB) false
#	set argArray(netlister) CDL
#	set argArray(netlFormat) cdl
#	set argArray(verifPostProc) false
#	set argArray(xmap) false
#	set argArray(xPowerExtract) NO
#	set argArray(xFormat) SPF
#	set argArray(xTempSens) NO
#	set argArray(xReduction) NO
#	set argArray(xSubExtraction) NO
#	set argArray(usercmdFile) 0
#	set argArray(xFormatNet) 0
#	set argArray(xDpNumCores) 4
#	set argArray(xAccuracy) 400
#	set argArray(xAnalogSymmetricNets) YES
#	set argArray(xCrossRef) YES
#	set argArray(xInst) YES
#	set argArray(xWidgetsList) [list lstb_1 lstb_diff_1 lstb_2 lstb_diff_2 lstb_3 lstb_diff_3 lstb_4 lstb_diff_4 lstb_5 lstb_diff_5 lstb_6 lstb_diff_6 lstb_7 lstb_diff_7 stb_1 stb_diff_1 stb_2 stb_diff_2 stb_3 stb_diff_3 stb_4 stb_diff_4 stb_5 stb_diff_5 stb_6 stb_diff_6 stb_7 stb_diff_7 va_check_rx_vote_sum va_suck va_check_rx_add_neg va_check_rx_boxcar va_check_rx_estore_neg va_check_rx_int_neg va_check_rx_phug_neg va_measure_jitter_pre_single va_check_rx_vote_sum va_tester_rx]
#	set argArray(xPresmult) 1
#	set argArray(xPcapmult) 1
#	set argArray(xUnflattenNetlist) 1
#	set argArray(xAddx) 0
#	set argArray(compressedGDS) true
#	set argArray(netlistBracketChange) 0
#	set argArray(deleteEmptyCell) 0
#	set argArray(compressedLVSNetlist) false
#	set argArray(onlyGDS) false
#	set argArray(onlyNetlist) false
#	set argArray(gdsExportTemplateFile) {}
#	set argArray(runHerculesServer) localhost
#	set argArray(runCalibreServer) localhost
#	set argArray(runICVServer) localhost
#	set argArray(saveReportandData) true
#	set argArray(intDeliveries) false
#	set argArray(xGroundNode) 0
#	set argArray(xSeparateExtract) 0
#	set argArray(renameType) {}
#	set argArray(renameCell) {}
#	set argArray(targetTopCell) {}
#	set argArray(excludeList) {}
#	set argArray(virtualConnect) 0
#	set argArray(excludeCell) {}
#	set argArray(metalShort) {}
#	set argArray(operatingTemp) {}
#	set argArray(extractViaCaps) {}
#	set argArray(cTemplateFile) false
#	set argArray(lpePreProcFile) {}
#	set argArray(extractedNetlistPProcessor) 0
#	set argArray(toolExtraArg) {}
#	set argArray(equivFile) {}
#	set argArray(blackBoxConfigFile) {}
#	set argArray(libFilteredList) {}
#	##  Watch this.  The quotes need to get through.
#	set argArray(selectedNetList) "\"*\""
#	set argArray(listOfDeleteSubs) INACTIVE
#	set argArray(actionType) {}
#	set argArray(xnetSearchList) [list cdl hspice hspiceD schematic symbol veriloga]
#	set argArray(xnetStopList) {}
#	set argArray(removeJob) none
#	set argArray(importFillLibraryName) false
#	set argArray(importFillLocation) false
#	set argArray(fillGDSType) false
#	set argArray(fillCellCopy) false
#	set argArray(flatFillGDS) false
#	set argArray(podPostProc) 1
#	set argArray(podPostProcOpt) drain
#	set argArray(xSubCkt) "-xSubCkt"
#	set argArray(xCase) "-xCase"
#	set argArray(xrmFloat) ""
#	set argArray(xrmDangling) ""
#	set argArray(xHierSeparator) ""
#	set argArray(confirmRemoveJob) 0
#
#	set supplyNets $argArray(xtPowerNets)
#	##  Set variables for different extraction types
#	set xSelNetsSRCCPCC [list RCC "*"]
#	set xSelNetsSCCPRCC [list CC "*"]
#	set xSelNetsCCSSRCC [list CC "*"]
#	foreach supply $supplyNets {
#	    lappend xSelNetsSRCCPCC "!$supply"
#	    lappend xSelNetsSCCPRCC "!$supply"
#	    lappend xSelNetsCCSSRCC "!$supply"
#	}
#	lappend xSelNetsSRCCPCC "CC"
#	lappend xSelNetsSCCPRCC "RCC"
#	lappend xSelNetsCCSSRCC "RCC"
#
#	set xSelNetsSRCCPCC [concat $xSelNetsSRCCPCC $supplyNets]
#	set xSelNetsSCCPRCC [concat $xSelNetsSCCPRCC $supplyNets]
#	set xSelNetsCCSSRCC [concat $xSelNetsCCSSRCC $supplyNets]
#
#	set argArray(xSelNetsSRCCPCC) $xSelNetsSRCCPCC
#	set argArray(xSelNetsSCCPRCC) $xSelNetsSCCPRCC
#	set argArray(xSelNetsCCSSRCC) $xSelNetsCCSSRCC
#
#	##  xTypes order:  r c cc rC srccpcc sccprcc ccssrcc
#	## !!!  Yes, really a list of lists.  Fails otherwise.
#	set argArray(xTypes) [list [list 0 0 0 0 1 0 0 0]]
#
#
#
#	## General purpose argument reader.
#	##  Put all specified args into argArray, overriding any defaults above.
#	for { set i 0 } { $i < [ llength $args ] } { incr i} {
#	    set theArg [lindex $args $i]
#	    if {[string index $theArg 0] == "-"} {
#		set argName [string trimleft $theArg "-"]
#		incr i
#		set argVal [lindex $args $i]
##		puts "Setting $argName = $argVal"
#		set argArray($argName) $argVal
#	    }
#	}
#
#	##  Check for the minimum set of required arguments
#	set argsOK 1
#	set argsOK [checkRequiredArg $args "-libName" $argsOK]
#	set argsOK [checkRequiredArg $args "-cellName" $argsOK]
##	set argsOK [checkRequiredArg $args "-xCorner" $argsOK]
#
#	set runSubdir "[string tolower $argArray(pvprefix)]_$argArray(tool)"
#
#	set filesOK 1
#
#	if {$argsOK != 1} {
#	    puts "Aborting on missing required argument(s)"
#	    return
#	}
#
#	## A couple special defaults, depend on other args.
#	if {![info exists argArray(rundir)]} {
#	    set argArray(rundir) "/slowfs/sgscratch/$user/$prodName/$projName/$relName/verification/$argArray(stack)/$argArray(libName)/$argArray(cellName)"
#	}
#
#	if {![info exists argArray(xOutDir)]} {
#	    set argArray(xOutdir) "$projHome/design/$argArray(stack)/netlist/extract/$argArray(cellName)"
#	}
#
#	if {![info exists argArray(tcad)]} {
#	    ##  Generate tcad variables from xCorner corner list
#	    set tcadVar ""
#	    foreach corner $argArray(xCorner) {
#		set nxtgrdVar "RCXTRunGRD_$corner"
#		if [info exists $nxtgrdVar] {
#		    lappend tcadVar $corner
#		    set nxtgrdFile [set $nxtgrdVar]
#		    lappend tcadVar $nxtgrdFile
#		    set filesOK [checkRequiredFile $nxtgrdFile $filesOK]
#		} else {
#		    puts "ERROR:  Unrecognized corner $corner"
#		}
#	    }
#
#	    if {[llength tcadVar] == 0} {
#		puts "Error:  No corner specified."
#		return
#	    }
#
#	    set argArray(tcad) $tcadVar
#	}
#
#
#	##  Make sure run directory exists.
#	set theRundir "$argArray(rundir)/$runSubdir"
#	if [file exists $theRundir] {
#	    if {![file isdirectory $theRundir]} {
#		puts "Error:  Run directory \"$theRundir\" exists but is not a directory"
#		return
#	    }
#	} else {
#	    ##  Create the work directory, if it doesn't exist.  We're going to put a hacked version of the runset as well as config and equiv files there.
#	    file mkdir $theRundir
#	}
#
#    	##  This creates the hacked runset
#	if {![info exists argArray(runset)]} {
#	    ##  runset is not specified;  Create and place in rundir
#	    set argArray(runset) [createHackedRunset  $argArray(rundir)]
#	}
#
#    	##  This creates the hacked
#	if {![info exists argArray(sourceFile)]} {
#	    ##  runset is not specified;  Create and place in rundir
#	    set argArray(sourceFile) [createHackedRCXTSourceFile  $argArray(rundir)]
#	}
#
#	#####  Generate config and equiv files, if necessary.
#	if {![info exists argArray(extrPreservedConfigFile)] || ![info exists argArray(extrPreservedEquivFile)]} {
#	    ##  Config or Equiv files not provided.  Create.
#	    puts "Generating stop list:"
#	    ##  Reads the project-level bbox list
#	    readBboxlist
#	    set stop [genStoplist $argArray(libName) $argArray(cellName)]
#	    foreach sl $stop {puts "\t$sl"}
#	    puts ""
#	}
#
#	if {![info exists argArray(extrPreservedConfigFile)]} {
#	    set argArray(extrPreservedConfigFile) "$argArray(rundir)/$argArray(cellName).config"
#	    puts "Creating $argArray(extrPreservedConfigFile)"
#	    set extrPreservedConfig ""
#	    set sep ""
#	    foreach sl $stop {
#		append extrPreservedConfig "$sep\"$sl\""
#		set sep ","
#	    }
#	    set config [open $argArray(extrPreservedConfigFile) w]
#	    puts $config $extrPreservedConfig
#	    close $config
#	}
#
#	if {![info exists argArray(extrPreservedEquivFile)]} {
#	    set argArray(extrPreservedEquivFile) "$argArray(rundir)/$argArray(cellName).equiv"
#	    puts "Creating $argArray(extrPreservedEquivFile)"
#	    set extrPreservedEquiv ""
#	    set sep ""
#	    foreach sl $stop {
#		append extrPreservedEquiv "$sep$sl"
#		set sep " "
#	    }
#	    puts ""
#	    set equiv [open $argArray(extrPreservedEquivFile) w]
#	    puts $equiv $extrPreservedEquiv
#	    close $equiv
#	}
#
#	set filesOK [checkRequiredFile $argArray(runset) $filesOK]
#	set filesOK [checkRequiredFile $argArray(optionsFile) $filesOK]
#	set filesOK [checkRequiredFile $argArray(sourceFile) $filesOK]
#	set filesOK [checkRequiredFile $argArray(layermap) $filesOK]
#	set filesOK [checkRequiredFile $argArray(xcmdFile) $filesOK]
#	set filesOK [checkRequiredFile $argArray(netlistPProcesor) $filesOK]
#	set filesOK [checkRequiredFile $argArray(incNetlist) $filesOK]
#	set filesOK [checkRequiredFile $argArray(xInstFile) $filesOK]
#	set filesOK [checkRequiredFile $argArray(extrPreservedConfigFile) $filesOK]
#	set filesOK [checkRequiredFile $argArray(extrPreservedEquivFile) $filesOK]
#
#	if {!$filesOK} {
#	    puts "Aborting on missing required file(s)"
#	    return
#	}
#
#        # We're batch, so the cell is probably is not open yet.
#        set cxt [de::open [dm::getCellViews layout -libName $argArray(libName) -cellName $argArray(cellName)] -headless 0 -readOnly 1]
#        # get scope for preferences
#        set scope [dm::findCell $argArray(cellName) -libName $argArray(libName)]
#
#	MSIP_PV_DIALOG::createMenuOpt $pvprefix lpe
#	global multipleVerificationEnabled
#	set multipleVerificationEnabled 0
#	global mergeIcvReports
#	set mergeIcvReports 0
#	global drcVerifPrefixList
#	set drcVerifPrefixList ""
#	set env(MSIP_GEN_RELEASE_PACKAGE) "false"
#
#
##	if { [db::isEmpty [db::getPrefs MSIP${pvprefix}gdsFile]] } {
##	    db::createPref MSIP${pvprefix}gdsFile \
#		-value "" -description "The location of the GDS file the user wishes to verify" -defaultScope cell
##	}
##	if { [db::isEmpty [db::getPrefs MSIP${pvprefix}netlistFile]] } {
##	    db::createPref MSIP${pvprefix}netlistFile \
##		-value "" -description "The location of the CDL file the user wishes to verify" -defaultScope cell
#	#}
#
#	MSIP_PV::runPV lpe \
#	    -from_gui \
#	    -tool $argArray(tool) \
#	    -calibreFlat $argArray(calibreFlat) \
#	    -runFlat $argArray(runFlat) \
#	    -icvOpts $argArray(icvOpts) \
#	    -prefix $argArray(pvprefix) \
#	    -cell $argArray(cellName) \
#	    -lib $argArray(libName) \
#	    -viewName $argArray(viewName) \
#	    -viewSchematicName $argArray(viewSchematicName) \
#	    -viewSchematicLibName $argArray(viewSchematicLibName) \
#	    -rundir $argArray(rundir) \
#	    -runset $argArray(runset) \
#	    -optionsFile $argArray(optionsFile) \
#	    -pinOptionsFile $argArray(pinOptionsFile) \
#	    -pcsOptionsFile $argArray(pcsOptionsFile) \
#	    -sourceFile $argArray(sourceFile) \
#	    -layermap $argArray(layermap) \
#	    -objectlayermap $argArray(objectLayermap) \
#	    -nettran $argArray(nettranOptions) \
#	    -gridOpts $argArray(gridOpts) \
#	    -gridOS $argArray(gridOS) \
#	    -gridProc $argArray(gridProc) \
#	    -calexOpts $argArray(calexOpts) \
#	    -calexFiles $argArray(calexFiles) \
#	    -calexExtraArg $argArray(calexExtraArg) \
#	    -stack $argArray(stack) \
#	    -gds $argArray(userGDS) \
#	    -netlist $argArray(userNetlist) \
#	    -netSearchList $argArray(netViewSearch) \
#	    -netStopList $argArray(netViewStop) \
#	    -mwdb $argArray(userMWDB) \
#	    -xcmdFile $argArray(xcmdFile) \
#	    -netlistPProcesor $argArray(netlistPProcesor) \
#	    -netlister $argArray(netlister) \
#	    -netlFormat $argArray(netlFormat) \
#	    -incNetlist $argArray(incNetlist) \
#	    -verifPostProc $argArray(verifPostProc) \
#	    -tcad $argArray(tcad) \
#	    -xmap $argArray(xmap) \
#	    -xPowerExtract $argArray(xPowerExtract) \
#	    -xtPowerNets $argArray(xtPowerNets) \
#	    -xSelNetsSRCCPCC $argArray(xSelNetsSRCCPCC) \
#	    -xSelNetsSCCPRCC $argArray(xSelNetsSCCPRCC) \
#	    -xSelNetsCCSSRCC $argArray(xSelNetsCCSSRCC) \
#	    -xInstFile $argArray(xInstFile) \
#	    -xOutdir $argArray(xOutdir) \
#	    -xFormat $argArray(xFormat) \
#	    -xTypes $argArray(xTypes) \
#	    -xTempSens $argArray(xTempSens) \
#	    -xReduction $argArray(xReduction) \
#	    -xSubExtraction $argArray(xSubExtraction) \
#	    -usercmdFile $argArray(usercmdFile) \
#	    -xFormatNet $argArray(xFormatNet) \
#	    -xDpNumCores $argArray(xDpNumCores) \
#	    -xAccuracy $argArray(xAccuracy) \
#	    -xAnalogSymmetricNets $argArray(xAnalogSymmetricNets) \
#	    -xCrossRef $argArray(xCrossRef) \
#	    -xCorner $argArray(xCorner) \
#	    -xInst $argArray(xInst) $argArray(xSubCkt) $argArray(xCase) $argArray(xrmFloat) $argArray(xrmDangling) $argArray(xHierSeparator) \
#	    -xWidgetsList $argArray(xWidgetsList) \
#	    -xPresmult $argArray(xPresmult) \
#	    -xPcapmult $argArray(xPcapmult) \
#	    -xUnflattenNetlist $argArray(xUnflattenNetlist) \
#	    -xAddx $argArray(xAddx) \
#	    -compressedGDS $argArray(compressedGDS) \
#	    -netlistBracketChange $argArray(netlistBracketChange) \
#	    -deleteEmptyCell $argArray(deleteEmptyCell) \
#	    -compressedLVSNetlist $argArray(compressedLVSNetlist) \
#	    -onlyGDS $argArray(onlyGDS) \
#	    -onlyNetlist $argArray(onlyNetlist) \
#	    -gdsExportTemplateFile $argArray(gdsExportTemplateFile) \
#	    -runHerculesServer $argArray(runHerculesServer) \
#	    -runCalibreServer $argArray(runCalibreServer) \
#	    -runICVServer $argArray(runICVServer) \
#	    -saveReportandData $argArray(saveReportandData) \
#	    -intDeliveries $argArray(intDeliveries) \
#	    -xGroundNode $argArray(xGroundNode) \
#	    -xSeparateExtract $argArray(xSeparateExtract) \
#	    -renameType $argArray(renameType) \
#	    -renameCell $argArray(renameCell) \
#	    -targetTopCell $argArray(targetTopCell) \
#	    -excludeList $argArray(excludeList) \
#	    -virtualConnect $argArray(virtualConnect) \
#	    -excludeCell $argArray(excludeCell) \
#	    -metalShort $argArray(metalShort) \
#	    -operatingTemp $argArray(operatingTemp) \
#	    -extractViaCaps $argArray(extractViaCaps) \
#	    -cTemplateFile $argArray(cTemplateFile) \
#	    -lpePreProcFile $argArray(lpePreProcFile) \
#	    -extractedNetlistPProcessor $argArray(extractedNetlistPProcessor) \
#	    -toolExtraArg $argArray(toolExtraArg) \
#	    -equivFile $argArray(equivFile) \
#	    -blackBoxConfigFile $argArray(blackBoxConfigFile) \
#	    -extrPreservedConfigFile $argArray(extrPreservedConfigFile) \
#	    -extrPreservedEquivFile $argArray(extrPreservedEquivFile) \
#	    -libFilteredList $argArray(libFilteredList) \
#	    -selectedNetList $argArray(selectedNetList) \
#	    -listOfDeleteSubs $argArray(listOfDeleteSubs) \
#	    -actionType $argArray(actionType) \
#	    -xnetSearchList $argArray(xnetSearchList) \
#	    -xnetStopList $argArray(xnetStopList) \
#	    -confirmRemoveJob $argArray(confirmRemoveJob) \
#	    -removeJob $argArray(removeJob) \
#	    -importFillLibraryName $argArray(importFillLibraryName) \
#	    -importFillLocation $argArray(importFillLocation) \
#	    -fillGDSType $argArray(fillGDSType) \
#	    -fillCellCopy $argArray(fillCellCopy) \
#	    -flatFillGDS $argArray(flatFillGDS) \
#	    -podPostProc $argArray(podPostProc) \
#	    -podPostProcOpt $argArray(podPostProcOpt)
#	#
#    }
##
#
#    proc runBBextract1 {args} {
#	global env
#
#	set pvprefix "RCXT"
#	## Pre-fill arg array with defaults.
#	set user $env(USER)
#	set prodName $env(MSIP_PRODUCT_NAME)
#	set projName $env(MSIP_PROJ_NAME)
#	set relName $env(MSIP_REL_NAME)
#	set CCS "/remote/proj/cad/$env(MSIP_CAD_PROJ_NAME)/$env(MSIP_CAD_REL_NAME)"
#
#	set argArray(stack) $env(METAL_STACK)
#	set projHome $env(PROJ_HOME)
#
#	for { set i 0 } { $i < [ llength $args ] } { incr i} {
#	    set theArg [lindex $args $i]
#	    if {[string index $theArg 0] == "-"} {
#		set argName [string trimleft $theArg "-"]
#		incr i
#		set argVal [lindex $args $i]
##		puts "Setting $argName = $argVal"
#		set argArray($argName) $argVal
#	    }
#	}
#
#	##  Check for the minimum set of required arguments
#	set argsOK 1
#	set argsOK [checkRequiredArg $args "-libName" $argsOK]
#	set argsOK [checkRequiredArg $args "-cellName" $argsOK]
##	set argsOK [checkRequiredArg $args "-xCorner" $argsOK]
#
#	set runSubdir "rcxt_icv"
#
#	if {![info exists argArray(rundir)]} {
#	    set argArray(rundir) "/slowfs/sgscratch/$user/$prodName/$projName/$relName/verification/$argArray(stack)/$argArray(libName)/$argArray(cellName)"
#	}
#
#	##  Make sure run directory exists.
#	set theRundir "$argArray(rundir)/$runSubdir"
#	if [file exists $theRundir] {
#	    if {![file isdirectory $theRundir]} {
#		puts "Error:  Run directory \"$theRundir\" exists but is not a directory"
#		return
#	    }
#	} else {
#	    ##  Create the work directory, if it doesn't exist.  We're going to put a hacked version of the runset as well as config and equiv files there.
#	    file mkdir $theRundir
#	}
#
#    	##  This creates the hacked runset
#	if {![info exists argArray(runset)]} {
#	    ##  runset is not specified;  Create and place in rundir
#	    set argArray(runset) [createHackedRunset  $argArray(rundir)]
#	}
#
#	#####  Generate config and equiv files, if necessary.
#	if {![info exists argArray(extrPreservedConfigFile)] || ![info exists argArray(extrPreservedEquivFile)]} {
#	    ##  Config or Equiv files not provided.  Create.
#	    puts "Generating stop list:"
#	    ##  Reads the project-level bbox list
#	    readBboxlist
#	    set stop [genStoplist $argArray(libName) $argArray(cellName)]
#	    foreach sl $stop {puts "\t$sl"}
#	    puts ""
#	}
#
#	if {![info exists argArray(extrPreservedConfigFile)]} {
#	    set argArray(extrPreservedConfigFile) "$argArray(rundir)/$argArray(cellName).config"
#	    puts "Creating $argArray(extrPreservedConfigFile)"
#	    set extrPreservedConfig ""
#	    set sep ""
#	    foreach sl $stop {
#		append extrPreservedConfig "$sep\"$sl\""
#		set sep ","
#	    }
#	    set config [open $argArray(extrPreservedConfigFile) w]
#	    puts $config $extrPreservedConfig
#	    close $config
#	}
#
#	if {![info exists argArray(extrPreservedEquivFile)]} {
#	    set argArray(extrPreservedEquivFile) "$argArray(rundir)/$argArray(cellName).equiv"
#	    puts "Creating $argArray(extrPreservedEquivFile)"
#	    set extrPreservedEquiv ""
#	    set sep ""
#	    foreach sl $stop {
#		append extrPreservedEquiv "$sep$sl"
#		set sep " "
#	    }
#	    puts ""
#	    set equiv [open $argArray(extrPreservedEquivFile) w]
#	    puts $equiv $extrPreservedEquiv
#	    close $equiv
#	}
#
#	set argArray(runFlat) {}
#	set argArray(extractedNetlistPProcessor) 0
#
#	##  Create the arg list for runExtract
#	set argList ""
#	foreach argName [array names argArray] {lappend argList "-$argName" $argArray($argName)}
#	## The "{*}" is "expansion syntax", breaking argList back into it's consituent pieces.
#	runExtract {*}$argList
#
#    }


#	pvbatch config switches:
#	tool:  icv, hercules, calibre.
#	calibreFlat: Default ""
#	runFlat:  Boolean. true for flat extracts, false for selectedNets. Default true.
#	icvOpts:  Default { -dp2 }
#	cellName:  Name of cell.  REQUIRED
#	$libName:  Name of lib. REQUIRED.
#	viewName:  Default layout
#	viewSchematicName:  Default schematic
#	viewSchematicLibName:  Default ""
#	rundir:  Default /slowfs/sgscratch/$user/$prodName/$projName/$relName/verification/$stack/$libName/$cellName"
#	runset:  The LVS runset.  Defaults to $IcvRunLVS; hacked for selectedNets
#	optionsFile:  Default $env(RCXTOptionsFile)
#	sourceFile: Default $env(RCXTSourceFile);  Hacked for selectedNets
#	layermap:  Default $env(layerMapFile)
#	objectLayermap:  Default ""
#	nettranOptions:  Default {-slash -cdl-a -mprop}
#	gridOpts: alpha::lpe default {-conf /remote/sge/cells/snps/common/settings.sh -dp4 -WS5.0 -quick -wait}
#	gridOS: alpha::lpe default: -WS5.0
#	gridProc: alpha::lpe default: -dp4
#	verifPostProc: Default false
#	calexOpts:  Default {--gds  --technology=$env(PROCESSNAME)}
#	calexFiles: Default ""
#	calexExtraArg: Default ""
#	stack: Defaults to project stack.
#	userGDS:  Use this to provide a specific gds.  Defaults to "" (stream out a fresh gds)
#	userNetlist: Use this to provide a specific cdl.  Defaults to "" (stream out a fresh cdl)
#	netViewSearch:  Default {cdl auCdl schematic symbol}  (Might include pcs override)
#	netViewStop: Default "".
#	userMWDB:  Default false
#	cmdFile:  Default $env(RCXTcmdFile)
#	usercmdFile:  Default 0
#	netlistPProc:  Normally $env(RCXTnetlistPostProc) for flat.  Set to "" for selectedNets
#	netlister:  Default CDL
#	incNetlist: Default $env(RCXTincludeNetlist)
#	TCADgrdFile: tcadgrd file for each corner.  Should never touch probably.
#	XTMapFile
#	xtPowerExtract
#	xtPowerNets
#	xtSelNetsSRCCPCC
#	xtSelNetsSCCPRCC
#	xtSelNetsCCSSRCC
#	xFile
#	outDir
#	xtFormat
#	[ list rcxtTypes ]
#	xTempSens
#	xReduction
#	xAccuracy
#	xAnalogSymmetricNets
#	xSubExtraction
#	xCrossRef
#	xCorner
#	xInst xSubCkt xCase xrmFloat xrmDangling xHierSeparator
#	xWidgetsList
#	xPresmult
#	xPcapmult
#	xUnflattenNetlist
#	xAddx
#	compressedGDS
#	netlistBracketChange
#	deleteEmptyCell
#	compressedLVSNetlist
#	onlyGDS
#	onlyNetlist
#	gdsExportTemplateFile
#	runHerculesServer
#	runCalibreServer
#	runICVServer
#	saveReportandData
#	intDeliveries
#	xtGroundNode
#	xtSeparateExtract
#	renameType
#	renameCell
#	targetTopCell
#	excludeCellList
#	virtualConnect
#	excludeCell
#	metalShortingName
#	toolExtraArg
#	blackBoxConfigFile
#	cTemplateFile
#	lpePreProcFile
#	pinOptionsFile
#	pcsOptionsFile
#	operatingTemp
#	extractedNetlistPProcessor
#	xtFormatNet
#	xDpNumCores
#	extractViaCaps
#	extrPreservedConfigFile
#	extrPreservedEquivFile
#	libFilteredList
#	listOfDeleteSubs
#	selectedNetList
#	actionType
#	xnetViewSearch
#	xnetViewStop
#	resultDialogConfirm
#	removeJobObject
#	importFillLibraryName
#	importFillLocation
#	fillGDSType
#	enableFillCellCopy
#	enableFillFlatGDS
#	podPostProc
#	podPostProcOpt

namespace eval ::alpha::pininfo {

    proc direction2NT {dir} {
        if {$dir == "I"} {return "input"} elseif {$dir == "O"} {return "output"} elseif {$dir == "IO"} {return "inout"} else {
            de::sendMessage "Unexpected direction \"$dir\"" -severity warning
            return "-"
        }
    }

    proc type2NT {type} {
        if {$type == "primary_power"} {return "PWR"} elseif {$type == "primary_ground"} {return "GND"} elseif {$type == "general_signal"} {return "-"} else {
            de::sendMessage "Unexpected type \"$type\"" -severity warning
            return "-"
        }
    }

    proc mergeBus {pinName} {
        ##  Merges bus spec's. Handles the case where buses split into multiple schematic pins

        global pinArray


        if {![lindex $pinArray($pinName) 3]} {return}
        set bitField [lindex $pinArray($pinName) 4]
        set toks [split $bitField ","]
        ## Check for simple bus.
        if {[llength $toks] == 1} {
            return
        }
        ##  Have more than one field.  Loop through them
        foreach field $toks {
            set bits [split $field ":"]
            set n [llength $bits]
            if {$n == 1} {
                ##  Single-bit
                set bitmap($bits) 1
            } elseif {$n == 2} {
                ## Normal range
                set msb [lindex $bits 0]
                set lsb [lindex $bits 1]
                if {$lsb > $msb} {
                    ##  Make sure msb is always largest
                    set x $msb
                    set msb $lsb
                    set lsb $x
                }
                for {set i $lsb} {$i <= $msb} {incr i} {set bitmap($i) 1}
            } else {puts "Weird bus spec"}
        }
        ##  At this point, we have a bitmap
        set bits [lsort -integer [array names bitmap]]
        set lsb [lindex $bits 0]
        set msb [lindex $bits end]
        ## Check for contiguous bits
        set expectedBit $lsb
        set nonContig false
        for {set i $lsb} {$i <= $msb} {incr i} {
            if [info exists lastBit] {
                set thisBit [lindex bits $i]
                if {$thisBit != $expectedBit} {set nonContig true}
                set expectedBit [expr {$thisBit+1}]
            }
        }
        if {$nonContig} {
            de::sendMessage "Bits for pin $pinName are non-contiguous" -severity warning
        }
        set pinArray($pinName) [lreplace $pinArray($pinName) 4 4 "$msb:$lsb"]
    }

    proc checkAutomatch {pinName automatchArgs default} {
        set attrPairs [split $automatchArgs ","]
        foreach attrPair $attrPairs {
            if {[llength $attrPair] == 2} {
                set patt [lindex $attrPair 0]
                set supply [lindex $attrPair 1]
                if [regexp $patt $pinName] {return $supply}
            } elseif {[llength $attrPair] > 2} {
                set supply [lindex $attrPair end]
                set patts  [lrange $attrPair 0 end-1]
                foreach patt $patts { if [regexp $patt $pinName] {return $supply}  }
            } else {
                set theError "Malformed automatch pair \"$attrPair\""
                de::sendMessage $theError -severity error
                #errorGui $theError
            }
        }
        return $default
    }

    proc replaceCsvField {line fieldName headers value} {

        set loc [lsearch -exact $headers $fieldName]
        if {$loc < 0} {
            de::sendMessage "Field \"$fieldName\" not found in CSV headers" -severity warning
            return $line
        }
        return [lreplace $line $loc $loc $value]
    }


    proc savePin {pinName direction pin_type related_power related_ground max_cap_load min_cap_load} {

        global pinArray


        set isBus 0
        set bitField "-"
        set rootName $pinName
        set lBkt ""
        set rBkt ""
        ## Strip off the bit field
        if [regexp "^(.*)(\[\[<\])(.*)(\[\]>\])" $pinName dummy rootName lBkt bitField rBkt] {
            ## This is a bus
            set isBus 1
            if [info exists pinArray($rootName)] {
                ##  Bus has been see before; bus is split between multiple pins.  Merge
                set oldBits [lindex $pinArray($rootName) 4]
                append bitField ",$oldBits"
            }
        }
        if [info exists ::forceBracket] {
            if {$::forceBracket == "square"} {
                set lBkt {[}
                set rBkt {]}
            } elseif {$::forceBracket == "pointy"} {
                set lBkt {<}
                set rBkt {>}
            } else {
                logMsg "Error:  Unrecognized bracket pattern \"$::forceBracket\""
            }

        }
        set rec [list $rootName $direction $pin_type $isBus $bitField $related_power $related_ground $lBkt $rBkt $max_cap_load $min_cap_load]
        set pinArray($rootName) $rec
    }

    proc firstAvailableFile {args} {
        foreach ff $args {
            if [file exists $ff] {return $ff}
        }
        puts "Error:  None of these exist:"
        foreach ff $args {puts "\t$ff"}
        return ""
    }

    proc genPininfo {libName cellName supplyPins groundPins args} {

        global pinArray

        if [info exists pinArray] {unset pinArray}
        ## The standard, old, pininfo headers
        set pininfoHeaders {name direction pin_type related_clock_pin related_ground_pin related_power_pin derating_factor desc donot_repeat is_bus is_true_core_ground lsb max_capacitive_load max_voltage min_capacitive_load msb nominal_voltage package_pin related_select_pin synlibchecker_waive cellname cell_x_dim_um cell_y_dim_um}

        # set pininfoHeaders {name cell_x_dim_um cell_y_dim_um cellname derating_factor desc direction donot_repeat is_bus is_true_core_ground lsb max_capacitive_load max_voltage min_capacitive_load msb nominal_voltage package_pin pin_type related_clock_pin related_ground_pin related_power_pin related_select_pin synlibchecker_waive}

        for { set i 0 } { $i < [ llength $args ] } { incr i} {
            set theArg [lindex $args $i]
            if {[string index $theArg 0] == "-"} {
                set argName [string trimleft $theArg "-"]
                incr i
                set argVal [lindex $args $i]
                set argArray($argName) $argVal
            }
        }

        if {![info exists  argArray(defaultRelatedPower)]} { set argArray(defaultRelatedPower) "-"}
        if {![info exists  argArray(defaultRelatedGround)]} { set argArray(defaultRelatedGround) "-"}

        set prBoundary [oa::PRBoundaryFind [oa::getTopBlock [oa::DesignOpen $libName $cellName layout "r"]]]
        if { $prBoundary eq "" } {
            set prBoundary [db::getShapes -of [db::getAttr design -of [oa::DesignOpen $libName $cellName layout "r"]] -lpp {prBoundary boundary} ]
            set boundaryType [db::getAttr type -of $prBoundary]
            if { $boundaryType eq "Polygon" } {
                set coords [ db::getAttr points -of $prBoundary ]
            } elseif { $boundaryType eq "Rect" } {
                set coords [ db::getAttr bBox -of $prBoundary ]
            }
            if { ![info exists coords] } { # Attempt to get prBoundary using a different way
                set prBoundary [db::getShapes -of [db::getAttr design -of [oa::DesignOpen $libName $cellName layout "r"]] -lpp {BOUNDARY placement} ]
                set boundaryType [db::getAttr type -of $prBoundary]
                if { $boundaryType eq "Polygon" } {
                    set coords [ db::getAttr points -of $prBoundary ]
                } elseif { $boundaryType eq "Rect" } {
                    set coords [ db::getAttr bBox -of $prBoundary ]
                }
            }
        } else { set coords [ db::getAttr bBox -of $prBoundary ] }

        set coords [ regsub -all "\{" $coords "" ]
        set coords [ regsub -all "\}" $coords "" ]
        regexp {([\-\d\.]+)\s([\-\d\.]+)\s([\-\d\.]+)\s([\-\d\.]+)} $coords to x1 y1 x2 y2
        if { [info exists x1] &&  [info exists x2] && [info exists y1] && [info exists y2] } {
            set x_dim [expr {$x2 - $x1}]
            set y_dim [expr {$y2 - $y1}]
        }

        if {[info exists argArray(cell_x_dim_um)]} { set cell_x_dim_um $argArray(cell_x_dim_um)
        } elseif {$x_dim ne ""} { set cell_x_dim_um $x_dim
        } else { set cell_x_dim_um "-" }
        if {[info exists argArray(cell_y_dim_um)]} {
            set cell_y_dim_um $argArray(cell_y_dim_um)
        } elseif {$y_dim ne ""} {
            set cell_y_dim_um $y_dim
        } else {
            set cell_y_dim_um "-"
        }

        if [info exists argArray(forceBracket)] {
            set ::forceBracket $argArray(forceBracket)
            de::sendMessage "Mapping brackets to $argArray(forceBracket)" -severity information
        } else {
            unset -nocomplain ::forceBracket
        }

        if {[oa::DesignExists $libName $cellName schematic]} {
            if {[info exists argArray(pininfoCSV)]} {
                set csvName $argArray(pininfoCSV)
                set CSV [open $csvName w]
                puts $CSV [regsub -all " " $pininfoHeaders ","]
            } elseif {[info exists argArray(pininfoOUT)]} {
                set designDir "$::env(MSIP_PROJ_ROOT)/$::env(MSIP_PRODUCT_NAME)/$::env(MSIP_PROJ_NAME)/$::env(MSIP_REL_NAME)/design"
                set legalRel [firstAvailableFile "$designDir/legalRelease.txt" "${designDir}_unrestricted/legalRelease.txt"]
                set relVer [exec grep -E "set\\s+rel\\s+" $legalRel]
                regexp {set\s+rel\s+\"(.*)\"} $relVer to relVer
                if { $argArray(pininfoOUT) eq "" || $argArray(pininfoOUT) == 1  } {
                    set csvDir "$designDir/pininfo/$relVer"
                } else {
                    set csvDir "$argArray(pininfoOUT)/pininfo/$relVer"
                }
                if {![file exists $csvDir]} {
                    file mkdir $csvDir
                }
                set csvName "$csvDir/$cellName.csv"
                set CSV [open $csvName w]
                puts $CSV [regsub -all " " $pininfoHeaders ","]
            }
            if {[info exists argArray(pininfoNT)]} {
                set NT [open $argArray(pininfoNT) w]
                puts $NT "##<cellname cell_x_dim_um cell_y_dim_um>"
                puts $NT "<$cellName $cell_x_dim_um $cell_y_dim_um>"
                puts $NT "##| name | direction | bus | msb | lsb | type | related_power_pin | related_ground_pin |"
            }
            set design [oa::DesignOpen $libName $cellName schematic r]
            set insts [db::getInsts -of $design]
            db::foreach oaInst $insts {
                set pin [db::getAttr pin -of $oaInst]
                if { $pin != ""} {
                    # puts [db::listAttrs -of $pin]
                    set term [db::getAttr term -of $pin]
                    # puts [db::listAttrs -of $term]
                    set pinName [db::getAttr name -of $term]
                    set numBits  [db::getAttr numBits -of $term]
                    set pinDir [db::getAttr termType -of $term]

                    ## Manage pin directions. "$direction" for traditional pininfo, "$nt_direction" for Nanotime pininfo
                    if {$pinDir == "input"} {
                        set direction I
                        set nt_direction "input"
                    } elseif {$pinDir == "output"} {
                        set direction O
                        set nt_direction "output"
                    } elseif {$pinDir == "inputOutput"} {
                        set direction IO
                        set nt_direction "inout"
                    } else {
                        puts "Oops:  Unexpected direction \"$pinDir\" on $pinName"
                    }

                    set related_power $argArray(defaultRelatedPower)
                    set related_ground $argArray(defaultRelatedGround)

                    ## Manage pin types
                    set max_cap_load "-"
                    set min_cap_load "-"

                    if {[lsearch -exact $supplyPins $pinName] >= 0} {
                        set pin_type "primary_power"
                        set related_power "-"
                        set related_ground "-"
                        set nt_type "PWR"
                    } elseif {[lsearch -exact $groundPins $pinName] >= 0} {
                        set pin_type "primary_ground"
                        set related_power "-"
                        set related_ground "-"
                        set nt_type "GND"
                    } else {
                        set pin_type "general_signal"
                        set nt_type "-"
                    }

                    ## Manage related_power/related_ground
                    if {[info exists argArray(relatedPowerAutomatch)]}  { set related_power  [checkAutomatch $pinName $argArray(relatedPowerAutomatch) $related_power] }
                    if {[info exists argArray(relatedGroundAutomatch)]} { set related_ground [checkAutomatch $pinName $argArray(relatedGroundAutomatch) $related_ground] }

                    ## Manage max_cap_load/min_cap_load
                    if {[info exists argArray(maxCapLoad)]} { set max_cap_load [checkAutomatch $pinName $argArray(maxCapLoad) $max_cap_load] }
                    if {[info exists argArray(minCapLoad)]} { set min_cap_load [checkAutomatch $pinName $argArray(minCapLoad) $min_cap_load] }

                    savePin $pinName $direction $pin_type $related_power $related_ground $max_cap_load $min_cap_load
                    #		if {$isBus} {set isBus "y"} else {set isBus "n"}
                    #		puts "$pinName:  $direction  $pin_type  $related_power $related_ground"
                }
            }

            foreach pin [lsort [array names pinArray]] {
                mergeBus $pin
                set direction [lindex $pinArray($pin) 1]
                set pin_type [lindex $pinArray($pin) 2]
                set isBus [lindex $pinArray($pin) 3]
                set bits [lindex $pinArray($pin) 4]
                set related_power [lindex $pinArray($pin) 5]
                set related_ground [lindex $pinArray($pin) 6]
                set lBkt [lindex $pinArray($pin) 7]
                set rBkt [lindex $pinArray($pin) 8]
                set max_cap_load [lindex $pinArray($pin) 9]
                set min_cap_load [lindex $pinArray($pin) 10]
                set pinName $pin
                set x [split $bits ":"]
                set msb [lindex $x 0]
                set lsb $msb
                if {[llength $x] == 2} {set lsb [lindex $x 1]}
                if {$isBus} { set pinName "$pin$lBkt$bits$rBkt" }
                if [info exists CSV] {
                    set line ""
                    ##  Pre-fill line with dashes
                    foreach hdr $pininfoHeaders {lappend line "-"}
                    set line [replaceCsvField $line "name" $pininfoHeaders $pinName]
                    set line [replaceCsvField $line "cell_x_dim_um" $pininfoHeaders $cell_x_dim_um]
                    set line [replaceCsvField $line "cell_y_dim_um" $pininfoHeaders $cell_y_dim_um]
                    set line [replaceCsvField $line "direction" $pininfoHeaders $direction]
                    set line [replaceCsvField $line "cellname" $pininfoHeaders $cellName]
                    set line [replaceCsvField $line "direction" $pininfoHeaders $direction]
                    if {$isBus} {set busField y} else {set busField n}
                    set line [replaceCsvField $line "is_bus" $pininfoHeaders $busField]
                    set line [replaceCsvField $line "msb" $pininfoHeaders $msb]
                    set line [replaceCsvField $line "lsb" $pininfoHeaders $lsb]
                    set line [replaceCsvField $line "pin_type" $pininfoHeaders $pin_type]
                    set line [replaceCsvField $line "related_power_pin" $pininfoHeaders $related_power]
                    set line [replaceCsvField $line "related_ground_pin" $pininfoHeaders $related_ground]
                    set line [replaceCsvField $line "max_capacitive_load" $pininfoHeaders $max_cap_load]
                    set line [replaceCsvField $line "min_capacitive_load" $pininfoHeaders $min_cap_load]
                    set line [regsub -all " " $line ","]
                    set line [regsub -all "\{" $line ""]
                    set line [regsub -all "\}" $line ""]
                    puts $CSV $line
                }
                if [info exists NT] {
                    set nt_direction [direction2NT $direction]
                    set nt_type [type2NT $pin_type]
                    if {$isBus} {set busField Y} else {set busField N}
                    set line "| $pinName | $nt_direction | $busField | $msb | $lsb | $nt_type | $related_power | $related_ground |"
                    puts $NT $line
                }
            }
            if [info exists CSV] {
                close $CSV
                de::sendMessage "Created $csvName" -severity information
            }
            if [info exists NT] {
                close $NT
                de::sendMessage "Created $argArray(pininfoNT)" -severity information
            }
        } else {
            set theError "$libName/$cellName does not exist"
            de::sendMessage $theError -severity error
            errorGui $theError
        }
    }
}

namespace eval ::alpha::util {

    variable verifList
    variable verifFileDepot

    proc submitVerifFile {args} {
        variable verifList
        variable verifFileDepot

        foreach line $verifList {puts $line}
        catch {exec p4 sync -q $verifFileDepot}
        set haveInfo ""
        catch {set haveInfo [exec p4 have $verifFileDepot]}
        if {$haveInfo == ""} {
            exec p4 add -t text $verifFileDepot
        } else {
            exec p4 edit $verifFileDepot
        }

        set verifFileClient ""
        catch {set verifFileClient [lindex [exec p4 where $verifFileDepot] 2]}
        if {[file exists $verifFileClient]} {
            set VF [open $verifFileClient w]
            foreach line $verifList {puts $VF $line}
            close $VF
            set submitInfo ""
            catch {set submitInfo [exec p4 submit -d "Auto-creation" $verifFileClient]}
            set openedInfo ""
            catch {set openedInfo [exec p4 opened $verifFileClient]}
            if {$openedInfo == ""} {
                ##  Normal.
                de::sendMessage "$submitInfo" -severity information
            } else {
                de::sendMessage "$submitInfo" -severity error
            }
        } else {
            de::sendMessage "Cannot open $verifFileClient for write" -severity error
        }
    }

    proc createVerifsFile {} {

        variable verifList
        variable verifFileDepot

        ##  Shamelessly copied from the hipre code. //wwcad/msip/internal_tools/CDtools/hipre/dev/main/bin/hipre_gui.tcl

        set addPVMenus $::env(addPVMenuList)
        if { [ expr {[ llength $addPVMenus ]%3} ] } {
            puts "The environment variable addPVMenuRunList is not valid"
            puts "The variable must be in the format <name of menu> <prefix> <type>, see Implementation Guid for Further Details"
        }
        set cornerCount 0
        set verifList [list]
        for { set i 1 } { $i <= [ expr {[ llength $addPVMenus ]/3} ] } { incr i } {

            set verType 		[ lindex $addPVMenus [ expr {3*$i-1} ] ]
            set verPrefix 		[ lindex [ lindex $addPVMenus [ expr {3*$i-2} ] ] 0 ]
            set userDefinedCascade  [ lindex [ lindex $addPVMenus [ expr {3*$i-2} ] ] 1 ]
            set verName     	[ lindex $addPVMenus [expr {3*$i-3 }] ]

            if { [ string tolower $userDefinedCascade ] eq "tapeout" || ([ string tolower $verPrefix ] eq "snps" && [ string tolower $userDefinedCascade ] eq "internal" ) || [ string tolower $userDefinedCascade ] eq "ccs"} {

                ##  Determine whether tool is enabled by presence of an associated runset.
                set toolList [list]
                set toolListEnabled [list]
                set enabledIcv 0
                set enabledCal 0
                set enabledHerc 0
                if [info exists ::env(${verPrefix}RunsetFile)] {
                    set runset $::env(${verPrefix}RunsetFile)
                    set rl [llength $runset]
                    for {set j 0} {$j < $rl} {incr j 2} {
                        set tool [lindex $runset $j]
                        set toolRunset [lindex $runset [expr {$j+1}]]
                        if {$tool == "icv"} {
                            set enabledIcv 1
                        } elseif {$tool == "calibre"} {
                            set enabledCal 1
                        } elseif {$tool == "hercules"} {
                            set enabledHerc 1
                        }
                        lappend toolListEnabled $tool
                    }
                } else {
                    de::sendMessage "No runset for $verPrefix" -severity warning
                }

                #		puts "!!!  MSIP${verPrefix}${userDefinedCascade}icvVerif MSIP${verPrefix}${userDefinedCascade}calVerif MSIP${verPrefix}${userDefinedCascade}hercVerif"

                ##  Check for the prefs that determine which tools will be used.
                ##  These prefs are typically non-existent, by default, but when the "Gen HIPRE Pkg" gui is opened for the first time, they will be set with default
                ##     values.  icv on, the others off.
                set icvPrefName MSIP${verPrefix}${userDefinedCascade}icvVerif
                set calPrefName MSIP${verPrefix}${userDefinedCascade}calVerif
                set hercPrefName MSIP${verPrefix}${userDefinedCascade}hercVerif
                if $enabledIcv {de::sendMessage "$userDefinedCascade/$verPrefix/icv use pref $icvPrefName" -severity information}
                if $enabledCal {de::sendMessage "$userDefinedCascade/$verPrefix/calibre use pref $calPrefName" -severity information}
                if $enabledHerc {de::sendMessage "$userDefinedCascade/$verPrefix/hercules use pref $hercPrefName" -severity information}


                if {[db::isEmpty [db::getPrefs $icvPrefName]] } {
                    ## No pref.  icv is used by default, except when not enabled.
                    if $enabledIcv {lappend toolList "icv"}
                } else {
                    if {$enabledIcv && [db::getPrefValue $icvPrefName]} {lappend toolList "icv"}
                }

                if {[db::isEmpty [db::getPrefs $calPrefName]] } {
                    ##  Not enabled by default.
                } else {
                    if {$enabledCal && [db::getPrefValue $calPrefName]} {lappend toolList "calibre"}
                }

                if {[db::isEmpty [db::getPrefs $hercPrefName]] } {
                    ##  Not enabled by default.
                } else {
                    if {$enabledHerc && [db::getPrefValue $hercPrefName]} {lappend toolList "hercules"}
                }

                set pvPrefix [string tolower $verPrefix]
                foreach t $toolList {
                    lappend verifList "[string tolower $t]/$pvPrefix"
                    if {$pvPrefix == "lvs"} {
                            ## HACK ALERT!..  If lvs, add erc as well.
                            lappend verifList "[string tolower $t]/erc"
                    }
                }
            }
        }
        ##  Make the legalVerif file.
        set verifFileDepot "//wwcad/msip/projects/$::env(MSIP_PRODUCT_NAME)/$::env(MSIP_PROJ_NAME)/$::env(MSIP_REL_NAME)/pcs/design/legalVerifs.txt"
        set dialog [gi::createDialog proceedDialog -title proceedDialog -showApply 0 -execProc [list alpha::util::submitVerifFile] -showHelp 0 ]
        gi::createLabel -parent $dialog -label "Creating $verifFileDepot.  Proceed?"
        set table [gi::createTable librariestable -parent $dialog  -readOnly 0 -allowSortColumns 1 -alternatingRowColors 1 -selectionModel "multipleRows"]
        set c1 [gi::createColumn -parent $table -label "Verifs" -stretch 1 -readOnly 1]
        foreach line $verifList {
            set r [gi::createRow -parent $table]
            db::setAttr value -of [gi::getCells -row $r -column $c1] -value $line
        }
    }
}

################################################################################
# No Linting Area
################################################################################

# nolint Main
# nolint Line 470: N Argument
# nolint Line 537: W Found constant
# nolint Line 1325: W Found constant
# nolint Line 2331: W Found constant
# nolint Line 1364: N Close brace not aligned
