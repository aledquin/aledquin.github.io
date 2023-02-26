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
utils__script_usage_statistics $script_name "2022ww23"
##override the check net for non-transparent latches here
if {[info exists slavelat_list]} {
	set_timing_check_attachment -setup_to latch_net [get_topology -of_object $slavelat_list -structure_type latch]
}

set_nonlinear_waveform -samples 20 -mode accurate [get_nets -hier *]

# To get rid of "TECH-021 violations" where macro model parasitics found - Boon 07/10/2015
check_design -complete_with zero

##override the check to use 65%-35% transition points for more margin
set tchecks [get_timing_checks -quiet -hold -filter "label=~\"*latch hold*\""]
foreach_in_collection tcheck $tchecks {
        set_timing_check_attribute -of $tcheck [list [list 1.0 1.0 0.3] [list 2.0 1.0 0.45] [list 1.0 2.0 0.45] [list 2.0 2.0 0.6]]
}

set tchecks [get_timing_checks -quiet -setup -filter "label=~\"*latch setup*\""]
foreach_in_collection tcheck $tchecks {
        set_timing_check_attribute -of $tcheck [list [list 1.0 1.0 0.15] [list 2.0 1.0 0.3] [list 1.0 2.0 0.15] [list 2.0 2.0 0.3]]
}
