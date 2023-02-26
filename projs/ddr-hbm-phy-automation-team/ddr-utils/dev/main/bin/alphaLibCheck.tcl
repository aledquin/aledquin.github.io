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

##  This has two purposes at present:
##     1.  Check all used libraries against a master legalLibraries list and warn when there are references 
##         to other libraries
##     2.  Check for references for a given cell in more than one library.
##
##  The list of legal libraries is:  /remote/proj/alpha/$proj/$rel/design/legalLibs.txt
##
##  Usage:  alpha::libCheck <lib-name> <cell-name>
##          Creates ./<cell-name>.libCheck (also opens for viewing

namespace eval alpha {

    proc libCheckCell {topLibName topCellName viewName path} {
	global cellList
	global libList
	global OK
	if {$path == ""} {puts "\nChecking $topLibName/$topCellName/$viewName"}
	set aggCellName "$topLibName/$topCellName/$viewName"
	set libList($topLibName) 1
	registerCell $topLibName $topCellName
#	puts "Checking $path:  $topLibName/$topCellName/$viewName"
	if [oa::DesignExists $topLibName $topCellName $viewName] {
	    set design [oa::DesignOpen $topLibName $topCellName $viewName r]
	    set insts [db::getInsts -of $design]
	    db::foreach oaInst $insts {
		set pin [db::getAttr pin -of $oaInst]
		set isPin [string compare $pin ""]
		set libName [db::getAttr libName -of $oaInst]
		set cellName [db::getAttr cellName -of $oaInst]
		set instName [db::getAttr name -of $oaInst]
		set instAggCellName "$libName/$cellName/$viewName"
		if (![info exists cellList($instAggCellName)]) {
		    if [oa::DesignExists $libName $cellName $viewName] {
			libCheckCell $libName $cellName $viewName "$path.$instName"
		    } else {
			if (![info exists missingCellList($instAggCellName)]) {
			    puts "Warning:  $libName/$cellName/$viewName does not exist"
			    set missingCellList($instAggCellName)  1
			}
		    }
		}
		set cellList($aggCellName)  1
	    }
	} else {if {$path == ""} {
	    puts "$topLibName/$topCellName not found"}
	    return 0
	}
	return 1
    }
    
    proc registerCell {libName cellName} {
	global cellLibList
	##  Keep track of what lib's a cell is referenced in to check for multiple library references
	if [info exists cellLibList($cellName)] {
	    if { [lsearch -exact $cellLibList($cellName) $libName] >= 0 } { return }
	    lappend $cellLibList($cellName) $libName
	} else { set cellLibList($cellName) $libName }
    }
    
    proc libCheckLegal {viewName fp} {
	global libList
	global legalLibList
	
	set OK 1
	set keys [array names libList]
	puts $fp "\nChecking for illegal library references for view $viewName:"
	foreach libName $keys {
	    if {![info exists legalLibList($libName)]} {
		set OK 0
		puts $fp "\t$libName"
	    }
	}
	if {$OK} {puts $fp "CLEAN!"}
    }
    
    proc libCheck {topLibName topCellName} {
	
	global libList
	global cellList
	global legalLibList
	global cellLibList
	
	set proj $::env(MSIP_PROJ_NAME)
	set rel $::env(MSIP_REL_NAME)
	set prod $::env(MSIP_PRODUCT_NAME)
	set legalLibsFile "/remote/proj/$prod/$proj/$rel/design/legalLibs.txt"
	#    set legalLibsFile "/remote/us01home45/clouser/legalLibs.txt"
	#    puts $legalLibsFile
	if [info exists legalLibList] {unset legalLibList}
	if {![file exists $legalLibsFile]} {
	    puts "Error:  Cannot file $legalLibsFile"
	    return
	}
	set fp [open $legalLibsFile r]
	set legalData [read $fp]
	close $fp
	set data [split $legalData "\n"]
	foreach line $data {
	    ##  Uncomment and strip leading/trailing whitespace
	    set line [regsub {\#.*} $line ""]
	    set line [regsub {^\s+} $line ""]
	    set line [regsub {\s+$} $line ""]
	    foreach libName $line { 
		set legalLibList($libName) 1 
		#	    puts $libName
	    }
	}
	
	set outfile "$topCellName.libCheck"
	set fp [open $outfile w]
	
	puts $fp "Library Check for cell $topLibName/$topCellName:"
	
	##  Check schmematic libs
	if [info exists cellList] {unset cellList}
	if [info exists libList] {unset libList} 
	if [info exists cellLibList] {unset cellLibList}
	if {![libCheckCell $topLibName $topCellName schematic ""]} { 
	    close $fp
	    return 
	}
	libCheckLegal schematic $fp
	
	##  Check layout libs
	if [info exists cellList] {unset cellList}
	if [info exists libList] {unset libList}
	if {![libCheckCell $topLibName $topCellName layout ""]} { 
	    close $fp
	    return 
	}
	libCheckLegal layout $fp
	
	puts $fp "\nChecking for multi-library references:"
	set OK 1
	foreach cellName [array names cellLibList] {
	    if {[llength cellLibList]!=1} { 
		puts $fp "Multiple library references for $cellName:  $cellLibList($cellName)"
		set OK 0
	    }
	}
	if ($OK) {puts $fp "CLEAN!"}
	close $fp
	puts "alpha::libCheck complete. See $outfile"
	xt::openTextViewer -files $outfile
    }

    proc listLegalLibs {} {
		global legalLibList

		puts "Legal Libraries:"
		foreach key [array names legalLibList] { 
			puts "\t$key" 
		}
    }
}

################################################################################
# No Linting Area
################################################################################

# nolint Main
# nolint Line  73: N Suspicious variable
# nolint Line 153: W Found constant