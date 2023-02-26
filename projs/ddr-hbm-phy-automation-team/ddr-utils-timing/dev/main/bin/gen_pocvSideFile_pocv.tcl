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

set script_dirname [file dirname [file normalize [info script]]]
source ./pvt_setup.tcl
set corner $PVT





#configure -lvf
#characterize
#model -lvf  -pocv

print_ocv_side_files -input_lib ../../lib_pg/${cellName}_${metalStack}_${PVT}_pg.lib -output_path ../../pocv   -pocv
#print_ocv_side_files -input_lib ${cellName}_${metalStack}_${PVT}.lib -output_path ../../pocv   -pocv
#print_ocv_side_files -input_lib ./${cellName}_${metalStack}_${PVT}.lib -output_path ./pocv   -pocv
