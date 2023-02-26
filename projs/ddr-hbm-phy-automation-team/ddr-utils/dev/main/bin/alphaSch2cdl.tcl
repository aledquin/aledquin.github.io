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

#######!/depot/tcl8.5.12/bin/tclsh8.5


namespace eval ::alpha::netlist {
    
    variable subckts
    variable currentSubcktName
    variable instanceExternalSubckts

    ##  List of patterns to be filtered out entirely
    lappend filterLinePatterns {^\.global\s+gnd!}

    proc fileDeleteWarn {theFile} {
	if [file exists $theFile] {
	    file delete $theFile
	} else {
	    puts "Warning:  Expected file $theFile not found"
	}
    }

    proc filterOutLine {line} {
	##  Check to see if line should be filtered out.
	if [info exists alpha::netlist::filterLinePatterns] {
	    foreach patt $alpha::netlist::filterLinePatterns { 
		if [regexp -nocase $patt $line] {return true}
	    }
	    return false
	} else {
	    return false
	}
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
		if [info exists alpha::netlist::instanceExternalSubckts($subName)] {
		    ##  This cell is referenced herein.  Write it.
		    puts "Info:  Including cell $subName in header"
		    puts $OUT $line
		    set writing 1
		} else {
		    ##  Header cell is not used. Skip it.
		    puts "Info:  Excluding cell $subName from header"
		    puts $OUT "**  INFO:  Excluding unused cell $subName"
		    set writing 0
		}
	    } elseif {$id == ".ENDS"} {
		if $writing {puts $OUT $line}
		set writing 1
	    } else {
		if $writing {puts $OUT $line}
	    }
	}
	puts $OUT "** alpha::netlist::sch2Cdl header complete"
	close $IN
	close $OUT
    }

    proc processCdlPhase1Line {line bktMap flattenInc OUT} {
	##  Create version with continuations removed
	set bfr [regsub -all {\n\+} $line " "]
	set t0 [string tolower [lindex $bfr 0]]

	if [filterOutLine $bfr] { 
	    puts $OUT "** $line"
	    return
	}
	if {$t0 == ".subckt"} {
	    set subcktName [lindex $bfr 1]
	    set alpha::netlist::subckts($subcktName) 1
	    puts $OUT $line
	} elseif {$t0 == ".include"} {
	    if $flattenInc {
		puts $OUT "** $bfr"
		set incName [regsub -all {[\'\"]} [lindex $bfr 1] ""]
		processCdlPhase1 $incName $bktMap $flattenInc $OUT
	    } else {puts $OUT $line}
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
		if [info exists bfr] {processCdlPhase1Line $bfr $bktMap $flattenInc $OUT}
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
	    if {[expr {$lineLen+$ll}] > $maxLen} {
		append bfr "\n+"
		set lineLen 0
	    }
	    append bfr $sep$t
	    incr lineLen $ll
	    set sep " "
	}
	puts $file $bfr

    }

    proc processCdlPhase2Line {line cellName prefix noCvcp OUT} {
	##  Process renames
	set bfr [regsub -all {\n\+} $line " "]
	set t0 [string tolower [lindex $bfr 0]]
#	puts $line
	if {$t0 == ".subckt"} {
	    set subcktName [lindex $bfr 1]
	    if {[info exists alpha::netlist::subckts($subcktName)] && ($subcktName != $cellName)} {
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
	    if [info exists alpha::netlist::currentSubcktName] {puts $OUT ".ends $alpha::netlist::currentSubcktName"} else {puts $OUT ".ends"}
	} elseif {[string index $t0 0] == "x"} {
	    ##  A subckt instance
	    set parIdx [lsearch -glob $bfr "*=*"]
	    if {$parIdx == -1} {set subIdx [expr {[llength $bfr]-1}]} else {set subIdx [expr {$parIdx-1}]}
	    set subName [lindex $bfr $subIdx]
	    if {[info exists alpha::netlist::subckts($subName)] && ($subName != $cellName)} {
#		puts "Found inst of $subName, idx=$subIdx"
		set newSubckt "${prefix}$subName"
		set bfr [lreplace $bfr $subIdx $subIdx $newSubckt]
		dumpLine $bfr $OUT 180
	    } else {
		##  An instance not defined in this netlist.
		set alpha::netlist::instanceExternalSubckts($subName) 1
		puts $OUT $line
	    }
	} elseif {[string index $t0 0] == "c"} {
	    ##  A capacitor  See if it's a cvcp
	    if { (([string tolower [lindex $bfr 3]] == "cvcp") && $noCvcp) } {
		puts $OUT "** Removing cvcp  device"
		set l [regsub -all {\n\+} $line "\n* "]
		puts $OUT "* $l"
	    } else {puts $OUT $line}
	    
	} else {puts $OUT $line}
    }

    proc processCdlPhase2 {netlist cellName prefix noCvcp OUT} {

	set IN [open $netlist r]

	while {[gets $IN line] >= 0} {
	    if {[string index $line 0] == "+"} {
		append bfr "\n$line"
	    } else {
		if [info exists bfr] {processCdlPhase2Line $bfr $cellName $prefix $noCvcp $OUT}
		set bfr "$line"
	    }
	}
	processCdlPhase2Line $bfr $cellName $prefix $noCvcp $OUT
	close $IN
    }

    proc sch2cdlUsage {} {
	puts "Usage: alpha::netlist::sch2cdl -libName <libName> -cellName <cellName> \\"
	puts "       \[-flattenInc true|false\] \[-forceBracket square|pointy\] \[-prepend <prefix>\] \[-includeHeader true|false\]"
	puts ""
	puts "Arguments:" 
	puts "\tlibName:  Name of the library in which the cell abides.  Required." 
	puts "\tcellName:  Name of the cell.  Required." 
	puts "\t-flattenInc: Set to true to flatten out any .include statements.  Default=true "
	puts "\t-forceBracket square|pointy: Force brackets in the netlist to a particular flavor. Default: Disabled "
	puts "\t-prepend:  Add the specified prefix to subckts (definition and instance), but only if defined in this netlist."
	puts "\t\tDoes not affect the top-level subckt definition.  Default:  Disabled"
	puts "\t-includeHeader true|false:  Include the lvs header in the generated netlist.  Default: Disabled"
    }


    proc sch2cdl { args } {
	
	if {$args == ""} {
	    sch2cdlUsage
	    return
	}
	array set argsArray $args

	set argErr 0
	if { [ info exists argsArray(-libName) ] } {
	    set libName $argsArray(-libName)
	} else {
	    puts "Error:  Required arg \"libName\" missing"
	    set argErr 1
	}
	
	if { [ info exists argsArray(-cellName) ] } {
	    set cellName $argsArray(-cellName)
	} else {
	    puts "Error:  Required arg \"cellName\" missing"
	    set argErr 1
	}
	if $argErr {
	    puts "Aborting on missing required arg"
	    return
	}

	
	set expNetlist "./$cellName.cdl.raw"

	if { [ info exists argsArray(-skipNetlist) ] } {
	    set skipNetlist $argsArray(-skipNetlist)
	} else {set skipNetlist false}

	if { [ info exists argsArray(-flattenInc) ] } {
	    set flattenInc $argsArray(-flattenInc)
	} else {set flattenInc true}

	if { [ info exists argsArray(-includeHeader) ] } {
	    set includeHeader $argsArray(-includeHeader)
	} else {set includeHeader false}
	
	if { [ info exists argsArray(-prepend) ] } {
	    set prepend $argsArray(-prepend)
	} else {set prepend ""}

	
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

	set noCvcp true
	if { [ info exists argsArray(-noCvcp) ] } { set noCvcp $argsArray(-noCvcp) }

	if {!$skipNetlist} {
	    if {![oa::DesignExists $libName $cellName schematic]} {
		puts "Error: $libName/$cellName does not exist"
		return
	    }
	    if [file exists $expNetlist] {file delete $expNetlist}
	    ude::genNetlist::execute  \
		-libName $libName \
		-cellName $cellName \
		-cellView schematic \
		-netlistFormat CDL \
		-viewSearchList {cdl auCdl schematic symbol} \
		-viewStopList use_cd_default \
		-includeCIR {} \
		-processName $::env(PROCESSNAME) \
		-postProcess false \
		-compress false \
		-openInViewer false \
		-openInEditor false \
		-caseSensitive true \
		-runDir ./ \
		-fileName $cellName.cdl.raw \
		-reference false
	}

	if {![file exists $expNetlist]} {
	    puts "Error:  Netlisting appears to have failed; $expNetlist not created"
	    return
	}
	
	set OUT [open "./$cellName.cdl.tmp" w]
	processCdlPhase1 $expNetlist  $bktMap $flattenInc $OUT
	close $OUT

	set OUT [open  "./$cellName.cdl.tmp1" w]
	processCdlPhase2 "./$cellName.cdl.tmp"  $cellName $prepend $noCvcp $OUT
	close $OUT

	if $includeHeader {
	    if [info exists ::env(LVSincludeNetlist)] {
		if [file exists $::env(LVSincludeNetlist)] {
		    ##  Everything appears to be in place.
		    puts "Info: Adding header"
#		    file copy -force $::env(LVSincludeNetlist) "./$cellName.cdl"
#		    file attributes "./$cellName.cdl" -permissions "+w"
		    processHeader $::env(LVSincludeNetlist) "./$cellName.cdl"
		    set OUT [open "./$cellName.cdl" a]
		    set IN [open "./$cellName.cdl.tmp1" r]
		    while {[gets $IN line] >= 0} {puts $OUT $line}
		    close $IN
		    close $OUT
		} else {
		    puts "Error:  LVS header file \"$::env(LVSincludeNetlist)\" missing"
		    file copy -force "./$cellName.cdl.tmp1" "./$cellName.cdl"
		}
	    } else {
		puts "Error:  Environment variable \"LVSincludeNetlist\" is undefined.  Skipping header"
		file copy -force "./$cellName.cdl.tmp1" "./$cellName.cdl"
	    }
	} else {
	    file copy -force "./$cellName.cdl.tmp1" "./$cellName.cdl"
	}

	fileDeleteWarn $expNetlist
	fileDeleteWarn "./$cellName.cdl.tmp"
	fileDeleteWarn "./$cellName.cdl.tmp1"
	if [file exists "./cnl"] {file delete -force "./cnl"}
    }
}


################################################################################
# No Linting Area
################################################################################

# nolint Main
# nolint Line 129: N Expr called in expression
