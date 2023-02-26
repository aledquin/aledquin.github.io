##Generates the liberty timing model
# nolint utils__script_usage_statistics
reset_design -paths

set tr_idx [list [expr 0.25*$etm_tr_nominal/0.6] [expr 1.0*$etm_tr_nominal/0.6] [expr 2*$etm_tr_nominal/0.6] [expr 4*$etm_tr_nominal/0.6] [expr 10*$etm_tr_nominal/0.6]]

#Boon updated 1st cap value to be 0
set cap_idx [list [expr 0.0] [expr 1.0*$etm_cap_nominal] [expr 2*$etm_cap_nominal] [expr 4*$etm_cap_nominal] [expr 8*$etm_cap_nominal]]
#set cap_idx [list [expr 0.01*$etm_cap_nominal] [expr 1.0*$etm_cap_nominal] [expr 2*$etm_cap_nominal] [expr 4*$etm_cap_nominal] [expr 8*$etm_cap_nominal]]

set_model_input_transition_indexes -max -nominal [expr $etm_tr_nominal/0.6] $tr_idx $INPUTS
set_model_input_transition_indexes -min -nominal [expr $etm_tr_nominal/0.6] $tr_idx $INPUTS
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
    set_model_input_transition_indexes -max -nominal [expr $etm_tr_nominal/0.6] $tr_idx $INOUTS
    set_model_input_transition_indexes -min -nominal [expr $etm_tr_nominal/0.6] $tr_idx $INOUTS
}

if $ntEnablePbsa {
	extract_model -name ${cell}_${metal_stack}_${corner} -pbsa -debug {lib}
} else {
	extract_model -name ${cell}_${metal_stack}_${corner}  -debug {lib}
}

#Removing PBSA from ETM for Bit Slices - cheah 5/6/2015

## extend_outputs in extract_model to see if we can catch all the clock to Q in bbox model
##extract_model -name ${cell}_${corner} -pbsa -debug {lib} -extend_outputs {$OUTPUTS}
