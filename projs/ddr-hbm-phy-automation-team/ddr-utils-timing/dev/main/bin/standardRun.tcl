#!/depot/tcl8.6.3/bin/tclsh8.6
# nolint Main

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
#

#  Script to run the standard flow, picking up the macro name from the .inst and .sp files in the run dir.
source commonSetup.tcl
if [file exists macroSetup.tcl] {source macroSetup.tcl}
standardFlowDefault
exit

