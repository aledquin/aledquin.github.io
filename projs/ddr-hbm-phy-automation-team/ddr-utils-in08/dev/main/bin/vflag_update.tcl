#!/usr/bin/tclsh
#Script to update Vflag values in a design
#Developed by Dikshant Rohatgi

proc utils__script_usage_statistics {toolname version} {
    set prefix "ddr-da-"
    set reporter "/remote/cad-rep/msip/tools/bin/msip_get_usage_info"
    set cmd ""
	append cmd "$reporter --tool_name  ${prefix}${toolname} --stage main --category ude_ext_1 --tool_path 'NA' --tool_version \"$version\""
	
    exec sh -c $cmd
}

utils__script_usage_statistics "vflag_update" "2022ww15"


proc getVflagValues {inst cell lib fid view} {
	db::foreach i $inst {
		if {[string equal [db::getAttr cellName -of $i] "vflaghl"] && [string equal [db::getAttr libName -of $i] "vflags"]} {
			set netname [db::getAttr name -of [db::getAttr net -of [db::getInstTerms -of $i]]]
			if {[string equal $netname "VDDQ"]} {
				set vhigh [db::getAttr vhigh -of $i]
				set vlow [db::getAttr vlow -of $i]
				
				if {[string equal $vhigh "0.7"] == 0} { 
					db::setAttr "vhigh" -value {0.7} -of $i
					puts $fid "*INFO: In LIB $lib for $cell/$view ,changed $netname vflag(high) value from $vhigh to 0.7"
				} elseif {[string equal $vhigh "0.7"] == 1} {puts $fid "*INFO: In LIB $lib for $cell/$view ,$netname vflag(high) value is already set to  0.7"}
				if {[string equal $vlow "0" ] == 0} {	
					db::setAttr "vlow" -value {0} -of $i
					puts $fid "*INFO: In LIB $lib for $cell/$view changed $netname vflag(low) value from $vlow to 0"
				} elseif {[string equal $vlow "0"] == 1} {puts $fid "*INFO: In LIB $lib for $cell/$view , $netname vflag(low) value is already set to  0"}
			} elseif {[string equal $netname "VDD"] || [string equal $netname "VDDR"]} {
				set vhigh [db::getAttr vhigh -of $i]
				set vlow [db::getAttr vlow -of $i]

				if {[string equal $vhigh "0.9"] == 0} { 
					db::setAttr "vhigh" -value {0.9} -of $i
					puts $fid "*INFO: In LIB $lib for $cell/$view ,changed $netname vflag(high) value from $vhigh to 0.9"
				} elseif {[string equal $vhigh "0.9"] == 1} {puts $fid "*INFO: In LIB $lib for $cell/$view ,$netname vflag(high) value is already set to  0.9"}
				if {[string equal $vlow "0" ] == 0} {	
					db::setAttr "vlow" -value {0} -of $i
					puts $fid "*INFO: In LIB $lib for $cell/$view changed $netname vflag(low) value from $vlow to 0"
				} elseif {[string equal $vlow "0"] == 1} {puts $fid "*INFO: In LIB $lib for $cell/$view , $netname vflag(low) value is already set to  0"}	

			} elseif {[string equal $netname "VDD2H"] || [string equal $netname "VIO_PwrOk"]} {
				set vhigh [db::getAttr vhigh -of $i]
				set vlow [db::getAttr vlow -of $i]

				if {[string equal $vhigh "1.2"] == 0} { 
					db::setAttr "vhigh" -value {1.2} -of $i
					puts $fid "*INFO: In LIB $lib for $cell/$view ,changed $netname vflag(high) value from $vhigh to 1.2"
				} elseif {[string equal $vhigh "1.2"] == 1} {puts $fid "*INFO: In LIB $lib for $cell/$view ,$netname vflag(high) value is already set to  1.2"}
				if {[string equal $vlow "0" ] == 0} {	
					db::setAttr "vlow" -value {0} -of $i
					puts $fid "*INFO: In LIB $lib for $cell/$view changed $netname vflag(low) value from $vlow to 0"
				} elseif {[string equal $vlow "0"] == 1} {puts $fid "*INFO: In LIB $lib for $cell/$view , $netname vflag(low) value is already set to  0"}	

			} elseif {[string equal $netname "VSS"]} {
				set vhigh [db::getAttr vhigh -of $i]
				set vlow [db::getAttr vlow -of $i]
				if {[string equal $vhigh "0"] == 0} { 
					db::setAttr "vhigh" -value {0} -of $i
					puts $fid "*INFO: In LIB $lib for $cell/$view ,changed $netname vflag(high) value from $vhigh to 0"
				} elseif {[string equal $vhigh "0"] == 1} {puts $fid "*INFO: In LIB $lib for $cell/$view ,$netname vflag(high) value is already set to  0"}
				if {[string equal $vlow "0" ] == 0} {	
					db::setAttr "vlow" -value {0} -of $i
					puts $fid "*INFO: In LIB $lib for $cell/$view changed $netname vflag(low) value from $vlow to 0"
				} elseif {[string equal $vlow "0"] == 1} {puts $fid "*INFO: In LIB $lib for $cell/$view , $netname vflag(low) value is already set to  0"}	

			} else {
				continue
			}	
		} else {
			continue
		}
	}
}

array set opts {}
proc VflagUpdate {args} {
    # Assigning key-value pair into array
    # If odd number of arguments passed, then it should throw error
	global opts
	if {[catch {array set opts $args} msg]} {
        return $msg
    }

	set tmp [join [lreplace [lreplace [split $::env(PROJ_HOME) "/"] 0 2] end end "latest"] "/"]
	set projpth $::env(PROJ_P4_ROOT)
	append projpth "/$tmp"
	set libPat $opts(-lib)
	set libs [dm::getLibs ${libPat}]
	db::foreach lib $libs {
		set libName [db::getAttr name -of $lib]
		
		set logFile "vflag_update_${libName}.log"
		set path [pwd]
		if {[file exists $path/$logFile]} {file delete "$path/$logFile"}
		set fid [open $path/$logFile w]
		puts $fid "\t\t\tVFLAG UPDATE LOG\n"
		
		set cells [dm::getCells * -lib $lib]
		db::foreach cell $cells { 
				set cellName [db::getAttr name -of $cell]
				set cellviewS [dm::getCellViews -cell $cell -filter %viewType=~/^schematic$/]
				dm::syncToVersion $cellviewS
				dm::checkOut $cellviewS
				if { [catch {set design [db::openDesign $libName/$cellName/schematic]} err] == 0 } { 			
					set inst [db::getInsts * -of $design]
					getVflagValues $inst $cellName $libName $fid "schematic"
	#				set instv [db::getInsts vflag* -of $design]
	#				getVflagValues $instv
					db::saveDesign $design
					db::closeDesign $design
				} elseif { [catch {set design [db::openDesign $libName/$cellName/schematic]} err] == 1 } {puts $fid "*WARNING: No schematic view present for $cellName in $libName"}
	#			dm::checkIn $cellviewS
				set cellviewL [dm::getCellViews -cell $cell -filter %viewType=~/^maskLayout$/]
				dm::syncToVersion $cellviewL
				dm::checkOut $cellviewL
				if { [catch {set design [db::openDesign $libName/$cellName/maskLayout]} errr] == 0 } { 			
					set inst [db::getInsts * -of $design]
					getVflagValues $inst $cellName $libName $fid "layout"
	#				set instv [db::getInsts vflag* -of $design]
	#				getVflagValues $instv
					db::saveDesign $design
					db::closeDesign $design
				} elseif {[catch {set design [db::openDesign $libName/$cellName/maskLayout]} errr] == 1 } { puts $fid "*WARNING: No layout view present for $cellName in $libName"} 
			}
			exec p4 submit -d "Updated Vflag values" "$projpth/lib/$libName/..."

			puts $fid "\n\t\t\tEND"
			close $fid
			puts "Updates done, Please check $path/$logFile"
	}

}


