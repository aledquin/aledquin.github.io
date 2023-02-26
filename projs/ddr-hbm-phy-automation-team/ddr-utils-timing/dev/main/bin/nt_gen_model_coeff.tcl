##Generates the liberty timing model
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

reset_design -paths

set etm_tr_clk_nominal [expr $etm_tr_nominal*1.5]

set tr_idx [list [expr 0.25*$etm_tr_nominal/0.6] [expr 1.0*$etm_tr_nominal/0.6] [expr 2*$etm_tr_nominal/0.6] [expr 4*$etm_tr_nominal/0.6] [expr 10*$etm_tr_nominal/0.6]]
set tr_clk_idx [list [expr 0.1*$etm_tr_clk_nominal/0.6] [expr 0.5*$etm_tr_clk_nominal/0.6] [expr $etm_tr_clk_nominal/0.6] [expr 1.5*$etm_tr_clk_nominal/0.6] [expr 2*$etm_tr_clk_nominal/0.6]]


#Boon updated 1st cap value to be 0
set cap_idx [list [expr 0.0] [expr 1.0*$etm_cap_nominal] [expr 2*$etm_cap_nominal] [expr 4*$etm_cap_nominal] [expr 8*$etm_cap_nominal]]
#set cap_idx [list [expr 0.01*$etm_cap_nominal] [expr 1.0*$etm_cap_nominal] [expr 2*$etm_cap_nominal] [expr 4*$etm_cap_nominal] [expr 8*$etm_cap_nominal]]

#Boon added rail voltage dependencies for VDD inputs (DRVBE*) - 10/6/2015
##  Added extra check for non-empty lists in the following three.  jdc 3/31/2016
if [info exists INPUTS_VDD] {
    if {[llength $INPUTS_VDD] > 0} {
	set_model_input_transition_indexes -max -nominal [expr $etm_tr_nominal/0.6] $tr_idx $INPUTS_VDD -rail_voltage $VDD_val
	set_model_input_transition_indexes -min -nominal [expr $etm_tr_nominal/0.6] $tr_idx $INPUTS_VDD -rail_voltage $VDD_val
    }
}

#Octavian: add special transition range for clocks (assumed VDD)
if [info exists CLOCK_INPUTS] {
    if {[llength $CLOCK_INPUTS] > 0} {
	set_model_input_transition_indexes -max -nominal [expr $etm_tr_clk_nominal/0.6] $tr_clk_idx $CLOCK_INPUTS -rail_voltage $VDD_val
	set_model_input_transition_indexes -min -nominal [expr $etm_tr_clk_nominal/0.6] $tr_clk_idx $CLOCK_INPUTS -rail_voltage $VDD_val
    }
}

#Boon added rail voltage dependencies for VDDQ inputs (Clocktree macros) - 10/20/2015
if [info exists INPUTS_VDDQ] {
    if {[llength $INPUTS_VDDQ] > 0} {
	set_model_input_transition_indexes -max -nominal [expr $etm_tr_nominal/0.6] $tr_idx $INPUTS_VDDQ -rail_voltage $VDDQ_val
	set_model_input_transition_indexes -min -nominal [expr $etm_tr_nominal/0.6] $tr_idx $INPUTS_VDDQ -rail_voltage $VDDQ_val
    }

}

set_model_load_indexes -max $cap_idx [all_outputs]
set_model_load_indexes -min $cap_idx [all_outputs]

####################################################################
## Custom load ranges
####################################################################
if [info exists loadRangeCaps] {
    foreach loadID [array names loadRangeCaps] {
	set maxLoads "set_model_load_indexes -max \{$loadRangeCaps($loadID)\} \{$loadRangePins($loadID)\}"
	set minLoads "set_model_load_indexes -min \{$loadRangeCaps($loadID)\} \{$loadRangePins($loadID)\}"
	puts "Info: \"$maxLoads\""
	puts "Info: \"$minLoads\""
	eval $maxLoads
	eval $minLoads
    }
}


if {$INOUT_status == 1} {
    set_model_input_transition_indexes -max -nominal [expr $etm_tr_nominal/0.6] $tr_idx $INOUTS -rail_voltage $VDDQ_val
    set_model_input_transition_indexes -min -nominal [expr $etm_tr_nominal/0.6] $tr_idx $INOUTS -rail_voltage $VDDQ_val
}


# Added nominal idex per Vache's findings which will automactically add max_transition & max_capacitance at index 4 when user overwrite the default - Boon 8/3/2016
if [info exists loadRangeSlew] {
    foreach slewID [array names loadRangeSlew] {
        foreach pin_config $loadRangePins($slewID) { 
    	    set pin_config [regsub -all {[\(\)]} $pin_config ""]
    	    #set pin_config [regsub -all { } $pin_config ""]
	    #set rail_voltage $VDDQ_val
	    set found_rail_voltage 0

	    if [info exists INPUTS_VDD] {
        	foreach pin_source $INPUTS_VDD { 
        	    if {$pin_config == $pin_source} { 
			set rail_voltage $VDD_val
	    		set found_rail_voltage 1
        		break
        	    }
    		}
    	    }

	    if [info exists CLOCK_INPUTS] {
    		if {! $found_rail_voltage} { 
            	    foreach pin_source $CLOCK_INPUTS { 
	        	if {$pin_config == $pin_source} { 
			    set rail_voltage $VDD_val
	    		    set found_rail_voltage 1
        		    break
	        	}
        	    }
		}
	    }

	    if [info exists INOUTS_VDDQ] {
    		if {! $found_rail_voltage} { 
            	    foreach pin_source $INOUTS_VDDQ { 
	        	if {$pin_config == $pin_source} { 
			    set rail_voltage $VDDQ_val
	    		    set found_rail_voltage 1
        		    break
	        	}
        	    }
		}
	    }
	    

	    if [info exists INPUTS_VDDQ] {
    		if {! $found_rail_voltage} { 
            	    foreach pin_source $INPUTS_VDDQ { 
	        	if {$pin_config == $pin_source} { 
			    set rail_voltage $VDDQ_val
	    		    set found_rail_voltage 1
        		    break
	        	}
        	    }
		}
	    }

	    if { $found_rail_voltage } { 
                set maxSlews "set_model_input_transition_indexes -max -nominal [lindex $loadRangeSlew($slewID) 4] \{$loadRangeSlew($slewID)\} \{$pin_config\} -rail_voltage $rail_voltage"
		set minSlews "set_model_input_transition_indexes -min -nominal [lindex $loadRangeSlew($slewID) 4] \{$loadRangeSlew($slewID)\} \{$pin_config\} -rail_voltage $rail_voltage"
    		puts "Info: \"$maxSlews\""
    		puts "Info: \"$minSlews\""
    		eval $maxSlews
    		eval $minSlews
	    } else { 
        	set maxSlews "set_model_input_transition_indexes -max -nominal [lindex $loadRangeSlew($slewID) 4] \{$loadRangeSlew($slewID)\} \{$pin_config\}"
		set minSlews "set_model_input_transition_indexes -min -nominal [lindex $loadRangeSlew($slewID) 4] \{$loadRangeSlew($slewID)\} \{$pin_config\}"
    		puts "Info: \"$maxSlews\""
    		puts "Info: \"$minSlews\""
    		eval $maxSlews
    		eval $minSlews
	    }
        }
    }
}


if $ntEnablePbsa {
        #report_pbsa_calculation [get_timing_paths -max -max_paths 100] > max_pbsa.rpt
	#report_pbsa_calculation [get_timing_paths -min -max_paths 100] > min_pbsa.rpt
	extract_model -name ${cell}_${metal_stack}_${corner} -pbsa -keep_paths_within .005 -pocv -debug {lib paths} -non_sequential_arcs
} else {
	extract_model -name ${cell}_${metal_stack}_${corner}  -debug {lib paths} -non_sequential_arcs 
}

#Removing PBSA from ETM for Bit Slices - Boon 5/6/2015

## extend_outputs in extract_model to see if we can catch all the clock to Q in bbox model
##extract_model -name ${cell}_${corner} -pbsa -debug {lib} -extend_outputs {$OUTPUTS}
