#!/depot/tcl8.6.3/bin/tclsh8.6

set DEBUG      0
set VERBOSITY  0
set STDOUT_LOG ""

set RealBin      [file dirname [file normalize [info script]] ]
set PROGRAM_NAME [file tail [file normalize [info script]] ]

package require try         ;# Tcllib.

lappend auto_path "$RealBin/../lib/tcl"
package require Messaging 1.0
package require Misc 1.0
namespace import ::Messaging::*
namespace import ::Misc::*
# Get the version number
set VERSION [get_release_version]
utils__script_usage_statistics $PROGRAM_NAME $VERSION

namespace eval ::alpha::netlist {

    variable subckts
    variable instCells
    variable isTopcell
    variable currentSubcktName
    variable instanceExternalSubckts
    variable skipPrefixCells
    variable patternType
    variable removeSubcktList
    variable subcktsRemoved
    
    ##  Must be regex, glob, or wildcard (latter two synonymous)
    set patternType "regex"
    
    lappend filterLinePatterns {^\.global\s+gnd!}
    
    proc fileDeleteWarn {theFile} {
	if {[file exists $theFile]} {
	    file delete $theFile
	} else {
	    puts "Warning:  Expected file $theFile not found"
	}
    }
    
    proc mapHeader {headerFile} {
	if {$headerFile == ""} {return}
	set HDR [open $headerFile r]
	set bfr [read $HDR]
	close $HDR
	##  get rid of line continuations
	set bfr [regsub -all {\n\+} $bfr " "]
	set hdrLines [split $bfr "\n"]
	set currentSubckt ""
	
	foreach line $hdrLines {
	    if {[llength $line] == 0} {continue}
	    set id [string toupper [lindex $line 0]]
	    set fc [string range $id 0 0]
	    if {$id == ".SUBCKT"} {
		set currentSubckt [lindex $line 1]
#		puts "Subckt $currentSubckt:"
		##  Using subCells array to get unique list
		array unset subCells
	    } elseif {$id == ".ENDS"} {
		set ::headerMap($currentSubckt) [array names subCells]
	    } elseif {$fc == "X"} {
		##  A subckt instance
		set prev ""
		set next false
		foreach tok $line {
		    ##  Go through the tokens looking for first one after  "/" or last before a parameter
		    if {$next} {
			##  Previous token was a "/"
			set subCells($tok) 1
			break
		    } elseif {$tok == "/"} {
			set next true
		    } elseif {[string first "=" $tok] >= 0} {
			##  A parameter.
			set subCells($prev) 1
			break
		    } else {
			set prev $tok
		    }
		}
	    }
	}
#	foreach cell [array names ::headerMap] { puts "$cell:  {$::headerMap($cell)}" }
    }

    proc processHeader {headerFile outputNetlist} {

	set IN [open $headerFile r]
	set OUT [open $outputNetlist w]
	set writing 1
	puts $OUT "** alpha::netlist::sch2Cdl adding lvs header $headerFile"
	while {[gets $IN line] >= 0} {
	    set id [string toupper [lindex $line 0]]
	    if {$id == ".SUBCKT"} {
		set subName [lindex $line 1]
		if {[info exists alpha::netlist::instanceExternalSubckts($subName)]} {
		    if {[info exists headerSubcktAdded($subName)]} {
			##  An apparentl duplicate
			puts "Warning: Skipping duplicate subckt $subName"
			puts $OUT "**  INFO:  Skipping duplicate subckt $subName"
			set writing 0
		    } else {
			##  This cell is referenced herein.  Write it.
			puts "Info:  Including cell $subName in header"
			puts $OUT $line
			set writing 1
			set headerSubcktAdded($subName) 1
		    }
		} else {
		    ##  Header cell is not used. Skip it.
		    puts "Info:  Excluding cell $subName from header"
		    puts $OUT "**  INFO:  Excluding unused cell $subName"
		    set writing 0
		}
	    } elseif {$id == ".ENDS"} {
		if {$writing} {puts $OUT $line}
		set writing 1
	    } else {
		if {$writing} {puts $OUT $line}
	    }
	}
	puts $OUT "** alpha::netlist::sch2Cdl header complete"
	close $IN
	close $OUT
    }
    
    proc filterOutLine {line} {
	##  Check to see if line should be filtered out.
	if {[info exists alpha::netlist::filterLinePatterns]} {
	    foreach patt $alpha::netlist::filterLinePatterns { 
		if {[regexp -nocase $patt $line]} {return true}
	    }
	    return false
	} else {
	    return false
	}
    }

    proc processCdlPhase1Line {line bktMap flattenInc OUT} {
	##  Create version with continuations removed
	set bfr [regsub -all {\n\+} $line " "]
	set t0 [string tolower [lindex $bfr 0]]
	#	puts $line
	if {[filterOutLine $bfr]} { 
	    puts $OUT "** $line"
	    return
	}
	if {$t0 == ".subckt"} {
	    set subcktName [lindex $bfr 1]
	    set alpha::netlist::subckts($subcktName) 1
	    puts $OUT $line
	} elseif {$t0 == ".include"} {
	    if {$flattenInc} {
		puts $OUT "** $bfr"
		set incName [regsub -all {[\'\"]} [lindex $bfr 1] ""]
		processCdlPhase1 $incName $bktMap $flattenInc $OUT
	    } else {puts $OUT $line}
	} elseif {[string index $t0 0] == "x"} {
	    ##  A subckt instance
	    set parIdx [lsearch -glob $bfr "*=*"]
	    if {$parIdx == -1} {set subIdx [expr {[llength $bfr]-1}]} else {set subIdx [expr {$parIdx-1}]}
	    set subName [lindex $bfr $subIdx]
	    set alpha::netlist::instCells($subName) 1
	    puts $OUT $line
	} else {puts $OUT $line}
    }
    
    proc processCdlPhase1 {netlist bktMap flattenInc OUT} {
	
	set IN [open $netlist r]
	
	while {[gets $IN line] >= 0} {
	    set line [string trimleft $line]
	    if {$bktMap != ""} {set line [string map $bktMap $line]}
	    if {[string index $line 0] == "+"} {
		append bfr "\n$line"
	    } else {
		if {[info exists bfr]} {processCdlPhase1Line $bfr $bktMap $flattenInc $OUT}
		set bfr "$line"
	    }
	}
	processCdlPhase1Line $bfr $bktMap $flattenInc $OUT
	close $IN
    }
    
    proc dumpLine {line file maxLen} {
	set sep ""
	set bfr ""
	
	set lineLen 0
	foreach t $line {
	    set ll [string length $t]
        set totalLineLength [expr {$lineLen+$ll}]
	    if {$totalLineLength > $maxLen} {
		    append bfr "\n+"
		    set lineLen 0
	    }
	    append bfr $sep$t
	    incr lineLen $ll
	    set sep " "
	}
	puts $file $bfr
	
    }
    
    proc skipPrefix {name} {

	
	foreach patt $alpha::netlist::skipPrefix {
	    if {$alpha::netlist::patternType == "regex"} {
		##  Regular expressions.
		if {[regexp -nocase "^$patt\$" $name]} {
		    #		puts "Info:  Skipping prefix of $name"
		    set alpha::netlist::skipPrefixCells($name) 1
		    return 1
		}
	    } else {
		##  Globs.
		if {[string match -nocase $patt $name]} {
		    set alpha::netlist::skipPrefixCells($name) 1
		    return 1
		}
	    }
	}
	return 0
	
    }

    proc markExternalSubckts {subckt} {
	## Marks a subckt, and all cells with instances therein, as external references, so they will be added from the header.
	set alpha::netlist::instanceExternalSubckts($subckt) 1
	if {[info exists ::headerMap($subckt)]} {
	    foreach subcell $::headerMap($subckt) {markExternalSubckts $subcell}
	}
    }

    proc checkRemoveSubckt {removeSubckt subName} {
	variable removeSubcktList
	variable subcktsRemoved

	if {$removeSubckt} {
	    foreach rs $removeSubcktList {
		if {[string match -nocase $rs $subName]} {
		    ##  Skipping this instance
		    if {![info exists subcktsRemoved($subName)]} {
			## Only print message for the first one
			puts "Info:  Removing instance of $subName"
			set subcktsRemoved($subName) 1
		    }
		    return 1
		}
	    }
	}
	return 0
    }

    proc processCdlPhase2Line {line cellName prefix removeSubckt OUT} {
	variable removeSubcktList
	##  Process renames
	set bfr [regsub -all {\n\+} $line " "]
	set t0 [string tolower [lindex $bfr 0]]
	set c0 [string index $t0 0]
	#	puts $line
	if {$t0 == ".subckt"} {
	    set subcktName [lindex $bfr 1]
	    if {[info exists alpha::netlist::subckts($subcktName)] && ($subcktName != $cellName) && ![skipPrefix $subcktName]} {
		##  Subckt defined in this file.  Prefix
		##  Doing this causes tokens containing "[]" to get bracketed.  Have to handle individually, but there must be a better way.
		set newSubckt "${prefix}$subcktName"
		set bfr [lreplace $bfr 1 1 $newSubckt]
		dumpLine $bfr $OUT 180
		set alpha::netlist::currentSubcktName $newSubckt
	    }  else {
		set alpha::netlist::currentSubcktName $subcktName
		puts $OUT $line 
	    }
	} elseif {$t0 == ".ends"} {
	    if {[info exists alpha::netlist::currentSubcktName]} {puts $OUT ".ends $alpha::netlist::currentSubcktName"} else {puts $OUT ".ends"}
	} elseif {$c0 == "x"} {
	    ##  A subckt instance
	    set parIdx [lsearch -glob $bfr "*=*"]
	    if {$parIdx == -1} {set subIdx [expr {[llength $bfr]-1}]} else {set subIdx [expr {$parIdx-1}]}
	    set subName [lindex $bfr $subIdx]
	    if {[checkRemoveSubckt $removeSubckt $subName]} return
	    if {[info exists alpha::netlist::subckts($subName)] && ($subName != $cellName) && ![skipPrefix $subName]} {
#		puts "Found inst of $subName, prefixing"
		set newSubckt "${prefix}$subName"
		set bfr [lreplace $bfr $subIdx $subIdx $newSubckt]
		dumpLine $bfr $OUT 180
	    } else {
		##  An instance not defined in this netlist.
#		puts "Found inst of $subName, not prefixing"
		markExternalSubckts $subName
		puts $OUT $line
	    }
	} elseif {($c0 == "c") || ($c0 == "r")} {
	    ## Check resistors and caps for instances to scrub.
	    set subName [string tolower [lindex $bfr 3]]
	    if {[checkRemoveSubckt $removeSubckt $subName]} {
		return
	    } else {puts $OUT $line}
	    
	} else {puts $OUT $line}
    }
    
    proc processCdlPhase2 {netlist cellName prefix removeSubckt OUT} {
	
	set IN [open $netlist r]
	
	while {[gets $IN line] >= 0} {
	    if {[string index $line 0] == "+"} {
		append bfr "\n$line"
	    } else {
		if {[info exists bfr]} {processCdlPhase2Line $bfr $cellName $prefix $removeSubckt $OUT}
		set bfr "$line"
	    }
	}
	processCdlPhase2Line $bfr $cellName $prefix $removeSubckt $OUT
	close $IN
    }
    
    proc sch2cdlUsage {} {
	puts "Usage: alphaCdlPrep.tcl -cdlIn <cdl input netlist> -cellName <cellName> \\"
	puts "       \[-flattenInc true|false\] \[-forceBracket square|pointy\] \[-prepend <prefix>\] \[-includeHeader true|false\]"
	puts "       \[-lvsHeader <lvs header file>\] \[-cdlOut <cdl output netlist>\] \[-noCvcp true|false\] \[-removeSubckt \"subckt-list\"\]"
	puts ""
	puts "Arguments:" 
	puts "\tcdlIn:  Name of the input netlist.  Required." 
	puts "\tcellName:  Name of the cell.  Required." 
	puts "\tcdlOut:  Name of the output netlist. Defaults to \$cellName.prepped.cdl" 
	puts "\t-flattenInc: Set to true to flatten out any .include statements.  Default=true "
	puts "\t-forceBracket square|pointy: Force brackets in the netlist to a particular flavor. Default: Disabled "
	puts "\t-prepend:  Add the specified prefix to subckts (definition and instance), but only if defined in this netlist."
	puts "\t-skipPrefixFile:  File containing a list of cells, interpreted as patterns, to skip prefixing"
	puts "\t-skipPrefixList:  List containing a list of cells, interpreted as patterns, to skip prefixing"
	puts "\t-patternType (regex|glob|wildcard):  Specifies the pattern type to use.  Default is regex."
	puts "\t-noCvcp:  Filter out cvcp* devices.  Default:  true"
	puts "\t-removeSubckt:  List of subckts to remove the instances of.  Useful for removing cvcp vflag instances"
	puts "\t-includeHeader true|false:  Include the lvs header in the generated netlist.  Default: Disabled"
	puts "\t-lvsHeader <lvs header file>:  Filename of lvs header. Typically MSIP_PROJ_ROOT/cad/CCS-NAME/CCS-REL/METAL_STACK/template/lvs.include.cdl."
	puts "\t\tRequired if -includeHeader is enabled."
    }
    

    if {$argv == ""} {
	sch2cdlUsage
	exit
    }
    array set argsArray $argv
    
    set argErr 0
    if { [ info exists argsArray(-cdlIn) ] } {
	set cdlIn $argsArray(-cdlIn)
    } else {
	puts "Error:  Required arg \"cdlIn\" missing"
	set argErr 1
    }
    
    if { [ info exists argsArray(-cellName) ] } {
	set cellName $argsArray(-cellName)
    } else {
	puts "Error:  Required arg \"cellName\" missing"
	set argErr 1
    }
    if {$argErr} {
	puts "Aborting on missing required arg"
	exit
    }
    
    if {![file exists $cdlIn]} {
	puts "Error: Cannot open input netlist \"$cdlIn\""
	exit
    }
    
    if { [ info exists argsArray(-cdlOut) ] } {
	set cdlOut $argsArray(-cdlOut)
    } else {set cdlOut "./$cellName.prepped.cdl"}

    if { [ info exists argsArray(-flattenInc) ] } {
	set flattenInc $argsArray(-flattenInc)
    } else {set flattenInc true}
    
    if { [ info exists argsArray(-includeHeader) ] } {
	set includeHeader $argsArray(-includeHeader)
    } else {set includeHeader false}
    
    if { [ info exists argsArray(-prepend) ] } {
	set prepend $argsArray(-prepend)
    } else {set prepend ""}
    

    if { [ info exists argsArray(-patternType) ] } {
	set patternType [string tolower $argsArray(-patternType)]
	if {$patternType == "regex"} {
	    ## OK
	} elseif {$patternType == "glob"} {
	    ## OK
	} elseif {$patternType == "wildcard"} {
	    set patternType "glob"
	} else {
	    puts "Error:  Unrecognized patternType \"$patternType\""
	    exit
	}
    }


    set lvsHeader ""
    if { [ info exists argsArray(-lvsHeader) ] } {
	set lvsHeader $argsArray(-lvsHeader)
    }
    
    ## This is a list of the cells to skip prefixing.
    set skipPrefix {}
    if { [ info exists argsArray(-skipPrefixFile) ] } {
	##  A file that contains cells to not prefix
	set skipPrefixFile $argsArray(-skipPrefixFile)
	if {[file exists $skipPrefixFile]} {
	    set spf [open $skipPrefixFile r]
	    while {[gets $spf line] >= 0} {
		##  Uncomment using either # or //
		set line [regsub "\#.*" $line ""]
		set line [regsub "//.*" $line ""]
		foreach p $line {lappend skipPrefix $p}
	    }
	    close $spf
	} else {
	    puts "Error:  $skipPrefixFile does not exist"
	}
    }

    if { [ info exists argsArray(-skipPrefixList) ] } {
	##  A list that contains cells to not prefix
	set skipPrefixList $argsArray(-skipPrefixList)
	foreach p $skipPrefixList {lappend skipPrefix $p}
    }

    ##  Generates a map of the header
    mapHeader $lvsHeader

    set bktMap {}
    if { [ info exists argsArray(-forceBracket) ] } {
	set forceBracket $argsArray(-forceBracket)
	if {$forceBracket == "square"} {
	    set bktMap { < [ > ] }
	} elseif {$forceBracket == "pointy"} {
	    set bktMap { [ < ] > }
	} else {
	    set bktMap {}
	    puts "Error:  Unrecognized bracket pattern {$forceBracket}"
	}
    }
    
    set removeSubcktList {}
    set removeSubckt 0
    if { [ info exists argsArray(-removeSubckt) ] } {
	set rl $argsArray(-removeSubckt)
	##  Treat commas as blanks.
	set removeSubcktList [regsub -all {,} $rl " "]
	set removeSubckt 1
    }

    if { [ info exists argsArray(-noCvcp) ] } {
	if {$argsArray(-noCvcp)} {
	    lappend removeSubcktList "cvcp*"
	    set removeSubckt 1
	}
    }
    
    
    set OUT [open "./$cellName.cdl.tmp" w]
    processCdlPhase1 $cdlIn  $bktMap $flattenInc $OUT
    close $OUT

    ##  Determine the toplevel cells.
    foreach c [array names alpha::netlist::subckts] {
	if {![info exists instCells($c)]} {
	    ##  A subckt that has no instance in this cdl.
#	    puts "Info:  $c is identified as a toplevel cell"
	    set alpha::netlist::isTopcell($c) 1
	}
    }

    set OUT [open  "./$cellName.cdl.tmp1" w]
    processCdlPhase2 "./$cellName.cdl.tmp"  $cellName $prepend $removeSubckt $OUT
    close $OUT

    if {[info exists skipPrefixCells]} {
	puts "Info:  Skipped prefixing for:"
	foreach c [array names skipPrefixCells] {puts "\t$c"}
    }
    
    if {$includeHeader} {
	if {[info exists lvsHeader]} {
	    if {[file exists $lvsHeader]} {
		##  Everything appears to be in place.
		puts "Info: Adding header"
		processHeader $lvsHeader $cdlOut
		set OUT [open $cdlOut a]
		set IN [open "./$cellName.cdl.tmp1" r]
		while {[gets $IN line] >= 0} {puts $OUT $line}
		close $IN
		close $OUT
	    } else {
		puts "Error:  LVS header file \"$lvsHeader\" cannot be opened for read.  Skipping header."
		file copy -force "./$cellName.cdl.tmp1" "./$cellName.cdl"
	    }
	} else {
	    puts "Error: lvsHeader is undefined.  Skipping header"
	    file copy -force "./$cellName.cdl.tmp1" "./$cellName.cdl"
	}
    } else {
	file copy -force "./$cellName.cdl.tmp1" $cdlOut
    }
    
    fileDeleteWarn "./$cellName.cdl.tmp"
    fileDeleteWarn "./$cellName.cdl.tmp1"
    if {[file exists "./cnl"]} {file delete -force "./cnl"}
}




################################################################################
# No Linting Area
################################################################################

# nolint Main
# nolint Line 181: N Expr called in expression
