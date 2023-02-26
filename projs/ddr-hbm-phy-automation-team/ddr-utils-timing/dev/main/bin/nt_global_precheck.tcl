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
#####################################################################################################################################
## Overwrite CLK margin from 10%->15% & DATA margin from 15%->20% based on http://mantis-ca09/mantisbt/view.php?id=17206 
## For Cmax_factor, CKT team already use 50% hence no overwriting required.
#####################################################################################################################################


set_pbsa_override -from [get_ports *] -to [get_ports *] -Bmax_factor 0.15 -Bmin_factor -0.15 -Cmin_factor -0.15 -Dmax_factor 0.20 -Dmin_factor -0.20
