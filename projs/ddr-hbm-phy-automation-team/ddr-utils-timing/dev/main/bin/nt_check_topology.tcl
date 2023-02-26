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

complete_net_parasitics -complete_with zero
check_topology
report_topology > topology.rpt
report_topology -structure latch -verbose -nosplit >> topology.rpt
report_topology -structure flip_flop -verbose -nosplit >> topology.rpt
report_topology -structure differential_synchronizer -verbose -nosplit >> topology.rpt
report_topology -structure tgate -verbose -nosplit >> topology.rpt
report_topology -structure mux -verbose -nosplit >> topology.rpt
report_transistor_direction -nosplit > transistor_direction.rpt
report_transistor_direction -bidirectional -nosplit >> transistor_direction.rpt
report_transistor_direction -nondirectional -nosplit >> transistor_direction.rpt

