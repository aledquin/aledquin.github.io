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
utils__script_usage_statistics $script_name "2022ww24"


enable_api pub

proc scrubPinDriverWaveformRise {} {
    ##  Removes the "function" attribute from each pin.
    global active_pvts
    global cellList
    foreach pvt $active_pvts {
	foreach cellObj [ pub::get_obj_list $cellList($pvt) ] { 
	    set objType [pub::get_obj_type $cellObj]
	    if {($objType == "pin") || ($objType == "bus")} {
		pub::unset_obj_attr $cellObj "driver_waveform_rise"
	    }
	}
    }
}

proc scrubPinDriverWaveformFall {} {
    ##  Removes the "function" attribute from each pin.
    global active_pvts
    global cellList
    foreach pvt $active_pvts {
	foreach cellObj [ pub::get_obj_list $cellList($pvt) ] { 
	    set objType [pub::get_obj_type $cellObj]
	    if {($objType == "pin") || ($objType == "bus")} {
		pub::unset_obj_attr $cellObj "driver_waveform_fall"
	    }
	}
    }
}


proc scrubPinFunction {} {
    ##  Removes the "function" attribute from each pin.
    global active_pvts
    global cellList
    foreach pvt $active_pvts {
	foreach cellObj [ pub::get_obj_list $cellList($pvt) ] { 
	    set objType [pub::get_obj_type $cellObj]
	    if {($objType == "pin") || ($objType == "bus")} {
		pub::unset_obj_attr $cellObj "function"
	    }
	}
    }
}

proc loadLibs {loc macro} {
##  Reads all libs for a given location and macro into memory for mods
    global active_pvts
    global libList
    global cellList
    foreach pvt $active_pvts {
	set libName "$loc/models/liberty/cells/${macro}_${pvt}.lib.gz"
	if [file exists $libName] {
	    set libList($pvt) [pub::read_model -liberty $libName]
	    set cellList($pvt) [pub::get_obj $libList($pvt) cell $macro]
	} else {
	    puts "$libName not found"
	}
    }
}

proc filterPGpins {PGlist} {
##  Processes all libs and removes any pg_pin not on the list provided.
    global active_pvts
    global libList
    global cellList
    foreach pvt $active_pvts {
	foreach cellObj [ pub::get_obj_list $cellList($pvt) ] { 
	    set objType [pub::get_obj_type $cellObj]
	    if {$objType == "pg_pin"} {
		set pin_name [pub::get_obj_name $cellObj]
		if {[lsearch $PGlist $pin_name] < 0} {
		    pub::del_obj $cellObj 
		    puts "Deleted invalid pg_pin $pin_name from $pvt lib"
		}
	    }
	}
    }
}

proc convertPGpins {direction} {
##  Processes all libs and converts any pg_pin to a normal pin using the direction. Also removes related_power, related_ground and voltage_map attributes.
    global active_pvts
    global libList
    global cellList
    foreach pvt $active_pvts {
	##  Remove voltage_map attributes from library.
	pub::unset_obj_attr $libList($pvt) "voltage_map"
	foreach cellObj [ pub::get_obj_list $cellList($pvt) ] { 
	    set objType [pub::get_obj_type $cellObj]
	    ##  Remove related_power and related_grounds from each pin.
	    if {$objType == "pin"} {
		pub::unset_obj_attr $cellObj "related_power_pin"
		pub::unset_obj_attr $cellObj "related_ground_pin"
	    }
	    ##  Delete pg_pin and replace with simple pin.
	    if {$objType == "pg_pin"} {
		set pin_name [pub::get_obj_name $cellObj]
		pub::del_obj $cellObj 
		pub::add_obj $cellList($pvt) pin $pin_name "direction $direction"
	    }
	    if {$objType == "bus"} {
		pub::unset_obj_attr $cellObj "related_power_pin"
		pub::unset_obj_attr $cellObj "related_ground_pin"
		foreach busObj [ pub::get_obj_list $cellObj ] { 
		    ##  Remove related_power and related_grounds from each pin.
		    if {[pub::get_obj_type $busObj] == "pin"} {
			pub::unset_obj_attr $busObj "related_power_pin"
			pub::unset_obj_attr $busObj "related_ground_pin"
		    }
		}
	    }
	}
    }
}


proc addDate {} {
## Addes the date attribute 
    global active_pvts
    global libList
    global cellList
    set TheDate "[exec date]"
    lappend DateAttr "date" "$TheDate"
    foreach pvt $active_pvts {
	pub::set_obj_attr $libList($pvt) $DateAttr 
    }
}

proc fixRelated {related_from related_to} {
##  Remaps related_power or related_ground
    global active_pvts
    global libList
    global cellList
    foreach pvt $active_pvts {
	foreach cellObj [ pub::get_obj_list $cellList($pvt) ] { 
	    if {[pub::get_obj_type $cellObj] == "pin"} {
		set pin_name [pub::get_obj_name $cellObj]
		set related_power [pub::get_obj_attr $cellObj related_power_pin]
		set related_ground [pub::get_obj_attr $cellObj related_ground_pin]
		puts "$pin_name:  $related_power/$related_ground"
		if {$related_power == $related_from} {
		    puts "Changing related_power from $related_from to $related_to"
		    pub::set_obj_attr $cellObj "related_power_pin $related_to"
		}
		if {$related_ground == $related_from} {
		    puts "Changing related_ground from $related_from to $related_to"
		    pub::set_obj_attr $cellObj "related_ground_pin $related_to"
		}
	    }
	}
    }
}

proc fixDownto {} {
    ##  Processes all libs and fixes the cases where the "downto" attribute is wrong.
    ##  If bit_from > bit_to, downto should be "true";
    global active_pvts
    global libList
    global cellList
    foreach pvt $active_pvts {
	foreach cellObj [ pub::get_obj_list $libList($pvt) ] { 
	    set objType [pub::get_obj_type $cellObj]
#	    puts $objType
	    if {$objType == "type"} {
		set objName [pub::get_obj_name $cellObj]
		set attrs [pub::get_obj_attr $cellObj]
		set n [llength $attrs]
		for {set i 0} {$i < $n} {incr i 2} {set attrArray([lindex $attrs $i]) [lindex $attrs [expr $i+1]]}

		if [info exists attrArray(base_type)] {set base_type $attrArray(base_type)} else {set base_type ""}
		if [info exists attrArray(bit_from)] {set bit_from $attrArray(bit_from)} else {set bit_from ""}
		if [info exists attrArray(bit_to)] {set bit_to $attrArray(bit_to)} else {set bit_to ""}
		if [info exists attrArray(downto)] {set downto $attrArray(downto)} else {set downto ""}
		if {($base_type == "array") && ($bit_from > $bit_to)} {pub::set_obj_attr $cellObj {downto true}}
	    }
	}
    }
}

proc addPinCap {pin cap} {
    ##  Adds a pin capacitance
    global active_pvts
    global cellList
    foreach pvt $active_pvts {
	foreach cellObj [ pub::get_obj_list $cellList($pvt) ] { 
	    set objType [pub::get_obj_type $cellObj]
	    if {$objType == "pin"} {
		if {[pub::get_obj_name $cellObj] == $pin} {
		    pub::set_obj_attr $cellObj "capacitance $cap"
		}
	    }
	}
    }
}

proc writeLibs {loc subdir macro prefix suffix} {
##  Writes libs back to disk if modified
    global active_pvts
    global libList
    global cellList
    set writepath "$loc/models/liberty/cells/$subdir"
    if {[file exists $writepath] == 0} {exec mkdir $writepath}
    foreach pvt $active_pvts {
	set libName "$writepath/${macro}${prefix}_${pvt}${suffix}.lib.gz"
	set libNameNogz "$writepath/${macro}${prefix}_${pvt}${suffix}.lib"
	pub::write_model $libList($pvt) $libNameNogz
	#  exec gzip $libNameNogz
    }
}

proc writeLibs1 {loc macro prefix suffix} {
##  Writes libs back to disk if modified.  Writes exactly to the user-specified location
    global active_pvts
    global libList
    global cellList
    set writepath "$loc"
    if {[file exists $writepath] == 0} {exec mkdir $writepath}
    foreach pvt $active_pvts {
	set libName "$writepath/${macro}${prefix}_${pvt}${suffix}.lib.gz"
	set libNameNogz "$writepath/${macro}${prefix}_${pvt}${suffix}.lib"
	pub::write_model $libList($pvt) $libNameNogz
	#  exec gzip $libNameNogz
    }
}

proc removeLibraryObject {args} {
    ##  Removes a library object
    ## Args:
    ##   objType: The object type, required
    ##   objName: The object name, optional.  Defaults to "*"
    global active_pvts
    global libList
    global cellList
    set numArgs [llength $args]
    if {$numArgs < 1} {
	puts "Error: Missing objectName in removeLibraryObject"
	return
    }
    set objTypeArg [lindex $args 0]
    if {$numArgs > 1} {set objNameArg [lindex $args 1]} else {set objNameArg "*"}
    if {$numArgs > 2} {puts "Warning:  Extraneous args in removeLibraryObject; ignoring"}
#    puts ">>> $objTypeArg $objNameArg"
    
    foreach pvt $active_pvts {
	foreach libObj [ pub::get_obj_list $libList($pvt) ] { 
	    set objType [pub::get_obj_type $libObj]
	    set objName [pub::get_obj_name $libObj]
#	    puts ">>> $objType $objName"
	    
	    if {[string match $objTypeArg $objType] && [string match $objNameArg $objName]} {
		puts "Info:  Removing library object $objType\($objName\)"
		pub::del_obj $libObj
	    }
	}
    }
}


proc checkMosLibOrder {} {
    ##  Checks to make sure that mos.lib is first
    global active_pvts

    set OK 1
    set badPvts {}
    foreach pvt $::active_pvts {
	set libs [get_opc_process $pvt]
	set i [lsearch $libs "*/mos.lib*"]
	if {$i > 0} {
	    set OK 0
	    lappend badPvts $pvt
	}
    }

    if {!$OK} {
	puts "ERROR:  mos.lib is not first for these pvts:"
	foreach pvt $badPvts {puts "\t$pvt"}
	puts "Aborting"
	exit;
    }
}

proc standardFlow {args} {
    
    global cellName
    global metalStack

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
    
    if [file exists commonSetupProj.tcl] {source commonSetupProj.tcl}
    if [file exists commonSetupMacro.tcl] {source commonSetupMacro.tcl}
    if [file exists commonPostproc.tcl] {source commonPostproc.tcl}
    
    if [info exists argArray(macro)] {
	set MACRO $argArray(macro)
    } else {
	puts "Error:  Arg \"macro\" undefined in standardFlow"
	return
    }
    
    if [info exists argArray(config)] {
	set config $argArray(config)
    } else {
	#	set config "$::env(MSIP_PROJ_ROOT)/$::projectType/$::projectName/$::releaseName/design/timing/sis/SiS_configure.tcl"
	##  Looks for config in the run dir by default
	set config [file normalize "configure.tcl"]
    }
    if {![file exists $config]} {
	puts "Error:  $config does not exist"
	return
    }
    
    if [info exists argArray(inst)] {
	set inst $argArray(inst)
    } else {
	set inst [file normalize "./$MACRO.inst"]
    }
    if {![file exists $inst]} {
	puts "Error:  $inst does not exist"
	return
    }
    
    if [info exists argArray(netlist)] {
	set netlist $argArray(netlist)
    } else {
	set netlist [file normalize "./$MACRO.spf"]
    }
    if {![file exists $netlist]} {
	puts "Error:  $netlist does not exist"
	return
    }
	
	
    puts "Info:  Macro = $MACRO"
    puts "Info:  Config = $config"
    puts "Info:  Inst = $inst"
    puts "Info:  Netlist = $netlist"
    ##  Set the root name of the netlist so the .inst file can use it.
    set ::netlistName [file tail $netlist]
    
    exec rm -rf char
    create char
    exec cp $config char/config/configure.tcl
    
    #exec cp ../common_source/configure_ddrd511.tcl char/config/configure.tcl
    
    set_location char
    if [file exists macroRunConfig.tcl] {
	puts "Info:  Sourcing macroRunConfig.tcl"
	source macroRunConfig.tcl
    }
    import -netlist $netlist $MACRO
    #import -netlist  ${MACRO}_c_typical_$::STACK.spf $MACRO
    #import -netlist ${MACRO}_gf14lpp.sp $MACRO
    exec cp $inst char/control/$MACRO.inst
    #Added to average pin cap calculation
    set_config_opt model_pin_cap_calc ave
    configure -timing  $MACRO
    characterize $MACRO
    model -timing  -lib_name ${MACRO}_$::metalStack  $MACRO
    
    ##  Do the postprocessing stuff
    #source /remote/proj/alpha/alpha_common/flows/SiS/alphaUtilsSiS.tcl
#    source /remote/cad-rep/projects/alpha/alpha_common/bin/alphaUtilsSiS.tcl
    
    puts "Info:  Running lib post-process"
    puts "Info:  Pvts = $::active_pvts"
    #  Load the generated libs
    loadLibs char ${MACRO}
    #  Add the date.  hiprelynx will want this.
    addDate

    #  Remove redundant output function added by add_function of internal pins
    scrubPinFunction

    #Processes all loaded libs and removes any pg_pin not on the list provided
    filterPGpins { VDDQ VDD VSS }

    #### to remove extra lines that stops u from compliling correctly
    scrubPinDriverWaveformRise
    scrubPinDriverWaveformFall
    removeLibraryObject normalized_driver_waveform
    removeLibraryObject lu_table_template ndw_*

    #  Process macro-specific post-processing commands
    if [info exists argArray(postProc)] {
	set pp [file normalize $argArray(postProc)]
	if [file exists $pp] {
	    source $pp
	} else {
	    puts "Error:  $pp does not exist"
	}
    }

    if {![info exists pp]} {
	## postproc script not specified directly.  Look for default one:
	if [file exists "${MACRO}_postproc.tcl"] {
	    source "${MACRO}_postproc.tcl"
	}
    } else {
	puts "Info:  No postproc script found"
    }
    
    if [file exists macroPostProc.tcl] {
	puts "Info:  Sourcing macroPostProc.tcl"
	source macroPostProc.tcl
    }

    ##  Write the modified libs as "pg" libs (in direcory char/models/liberty/cells/final_pg)
    writeLibs char final_pg $MACRO "_$::metalStack" "_pg"
    if [file exists liberty] {
	writeLibs1 liberty/lib_pg $MACRO "_$::metalStack" "_pg"
    }
    #  Convert pg_pins to normal pins, removing voltage_map and related_power/related_ground.  
    #  The single argument is the direction of the power/ground pins; 
    #  should match verilog
    convertPGpins input
    #  Write the final non-PG libs, (in direcory char/models/liberty/cells/final)
    writeLibs char final ${MACRO} "_$::metalStack" ""
    if [file exists liberty] {
	writeLibs1 liberty/lib ${MACRO} "_$::metalStack" ""
    }
 }

proc standardFlowDefault {} {
    ## Invokes the standard flow, picking up the macro name from the existing .inst file.

    set instList [glob "*.inst"]
    set spList [glob "*.spf"]
    if {([llength $instList] == 1) && ([llength $spList] == 1) } {
	## Just one inst file and netlist
	regexp {(\S+)\.inst$} $instList dmy macroNameInst
	regexp {(\S+)\.spf$} $spList dmy macroNameSp
	if {$macroNameInst == $macroNameSp} {
	    ##  Good to go
	    standardFlow -macro $macroNameInst
	    return
	}
    }
    puts "Error: Could not determine macro name from inst and sp files"
    return
}
