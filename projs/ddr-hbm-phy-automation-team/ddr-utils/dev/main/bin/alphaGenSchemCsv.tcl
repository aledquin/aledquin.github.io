#!/depot/tcl8.5.12/bin/tclsh8.5

if {[namespace exists alpha::genSchemCsvs]} {
    namespace delete alpha::genSchemCsvs
}
set DEBUG      0
set VERBOSITY  0
set STDOUT_LOG ""

set RealBin        [file dirname [file normalize [info script]] ]

namespace eval alpha::genSchemCsvs {
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
	
    proc execute {args} {
	global uniqueCellCounts
	global totalCellCounts
	global macroInstCounts
	global macroList
	global currentMacro
	
	array unset uniqueCellCounts
	array unset totalCellCounts
	set instCountList {}
	
	##  Find the legalMacros file
	set macroList {}
	set legalMacrosFile "$::env(PROJ_HOME)/design/legalMacros.txt"
	if [file exists $legalMacrosFile] {
	    set m [open $legalMacrosFile "r"]
	    while {[gets $m line] >= 0} {
		##  Uncomment
		set line [regsub {\#.*} $line ""]
		##  Strip whitespace
		set line [string trim $line " \t"]
		if {$line != ""} {
		    set toks [split $line "/"]
		    if {[llength $toks] == 2} {
			set libName [lindex $toks 0]
			set macroName [lindex $toks 1]
			lappend macroList "$libName/$macroName"
		    } else {
			puts "Error:  Bad line in $legalMacros:"
			puts "\t\"$line\""
		    }
		}
	    }
	    close $m
	} else {
	    puts "Error:  $legalMacrosFile does not exist"
	}

	array set myArgs $args
	set stopLibs $myArgs(-stopLibs)
	set rootName "$::env(MSIP_PRODUCT_NAME)_$::env(MSIP_PROJ_NAME)_$::env(MSIP_REL_NAME)"
	set hierFileName ${rootName}_hier.csv
	set cellFileName ${rootName}_cells.csv
	set HIER [open $hierFileName w]
	set CELL [open $cellFileName w]

	foreach macro $macroList {
	    set macroInstCounts($macro) {}
	    set xx [split $macro "/"]
	    set libName [lindex $xx 0]
	    set cellName [lindex $xx 1]
	    set currentMacro $macro
	    puts "Info:  Processing $macro"
	    update
	    dumpHier $HIER $libName $cellName schematic $stopLibs "" 1 1
#	    puts $CELL "!!!  $macro:  $macroInstCounts($macro)"
	}
	close $HIER

	set outLine "libName,cellName,Total-UI,Total-TI"
	foreach macro $macroList {append outLine ",${macro}-UI,${macro}-TI"}
	puts $CELL $outLine
	foreach cell [lsort [array names uniqueCellCounts]] {
	    set xx [split $cell "/"]
	    set libName [lindex $xx 0]
	    set cellName [lindex $xx 1]
	    set ui $uniqueCellCounts($cell)
	    set ti $totalCellCounts($cell)
	    set outLine "$libName,$cellName,$ui,$ti"
	    foreach macro $macroList {
		set i [lsearch -exact $macroInstCounts($macro) $cell]
		if {$i >= 0} {
		    incr i
		    set cellUi [lindex $macroInstCounts($macro) $i]
		    incr i
		    set cellTi [lindex $macroInstCounts($macro) $i]
		} else {
		    set cellTi 0
		    set cellUi 0
		}
		append outLine ",$cellUi,$cellTi"
	    }
	    puts $CELL $outLine
	}
	close $CELL
	puts "Info:  Created [file normalize $hierFileName]"
	puts "Info:  Created [file normalize $cellFileName]"
	
    }

    proc dumpHier {HIER topLibName topCellName topViewName stopLibs indent flatMul checkExists} {
#	puts "${indent}!!$topLibName $topCellName"
	#	puts "Checking $topLibName/$topCellName"
	global macroInstCounts
	global currentMacro
	global uniqueCellCounts
	global totalCellCounts
	
	set cellId "$topLibName/$topCellName"
	if [info exists uniqueCellCounts($cellId)] {
	    incr uniqueCellCounts($cellId)
	    set dup "DUP"
	} else {
	    set uniqueCellCounts($cellId) 1
	    set dup ""
	}

	if [info exists totalCellCounts($cellId)] {
	    incr totalCellCounts($cellId) $flatMul
	} else {
	    set totalCellCounts($cellId) $flatMul
	}


	if {$HIER != 0} {puts $HIER "$indent$topLibName/$topCellName/$topViewName,$dup"}
	if [oa::DesignExists $topLibName $topCellName schematic] {
#	    puts "${indent}exists"
	    set design [oa::DesignOpen $topLibName $topCellName schematic r]
	    set insts [db::getInsts -of $design]
	    db::foreach oaInst $insts {
		set HIERx $HIER
		set pin [db::getAttr pin -of $oaInst]
		set isPin [string compare $pin ""]
		set libName [db::getAttr libName -of $oaInst]
		set viewName [db::getAttr viewName -of $oaInst]
		set cellName [db::getAttr cellName -of $oaInst]
		set instName [db::getAttr name -of $oaInst]
#		puts "${indent}inst $libName $cellName"
		if $isPin continue
		if { [lsearch -exact $stopLibs $libName] >= 0} {set HIERx 0}
		if [regexp {[\[<](\d+):(\d+)[\]>]} $instName dummy msb lsb] {
		    set ti [expr abs($msb-$lsb)+1]
		} else {set ti 1}
		#	    puts [db::listAttrs  -of $oaInst]
		set flatCount [expr $flatMul*$ti]
#		addInstCounts "$libName/$cellName" $currentMacro $flatCount
		##  Add instance counts to macro
		set instId "$libName/$cellName"
		set i [lsearch -exact $macroInstCounts($currentMacro) $instId]
		if {$i >= 0} {
		    ##  Instance already in list
		    incr i
		    set macroUI [lindex $macroInstCounts($currentMacro) $i]
		    incr macroUI
		    set j [expr $i+1]
		    set macroTI [lindex $macroInstCounts($currentMacro) $j]
		    incr macroTI $flatCount
		    set macroInstCounts($currentMacro) [lreplace $macroInstCounts($currentMacro) $i $j $macroUI $macroTI]
		} else {
		    lappend macroInstCounts($currentMacro) $instId 1 $ti
		}
		dumpHier $HIERx $libName $cellName $viewName $stopLibs "  $indent" $flatCount 0
	    }
	} else {if {$checkExists == 1} {
	    puts "Warning: $topLibName/$topCellName/schematic not found"}
	    return
	}
	return
    }
}

set args [list]
#lappend args [de::createArgument -libName  	  -optional false   -description "Library Name"]
#lappend args [de::createArgument -cellName  	  -optional false   -description "Cell Name"]
lappend args [de::createArgument -stopLibs        -optional true    -description "Libraries to stop at" -default "" ]

de::createCommand alpha::genSchemCsvs  -category schematic -arguments $args -description "Opens each cell of library, initializes the MSIP_CURRENT_CONTEXT global variable, creates pins"



################################################################################
# No Linting Area
################################################################################

# nolint Main
