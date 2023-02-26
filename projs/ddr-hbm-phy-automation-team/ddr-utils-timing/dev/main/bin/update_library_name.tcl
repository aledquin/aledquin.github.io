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
utils__script_usage_statistics $script_name "2023.01"


 proc rename_library_to_match_filename { path_to_lib } {
     catch { enable_api pub }
     set lib_id [pub::read_model -liberty $path_to_lib]
     pub::set_obj_name $lib_id [file rootname [file tail $path_to_lib]]
     pub::write_model $lib_id $path_to_lib
  }
