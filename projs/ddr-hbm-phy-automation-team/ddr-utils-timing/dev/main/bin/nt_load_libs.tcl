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


lappend link_path "$STDLIBPATH/gf14nxgllogl14hdm078f/logic_synth/gf14nxgllogl14hdm078f_ulvl_$dbcorner"
lappend link_path "$STDLIBPATH/gf14nxgllogl14hdm078f/logic_synth/gf14nxgllogl14hdm078f_dlvl_$dbcorner"
lappend link_path "$STDLIBPATH/gf14nxgslogl14hdm078f/logic_synth/gf14nxgslogl14hdm078f_$dbcorner"
lappend link_path "$STDLIBPATH/gf14nxgslogl14hdm078f/logic_synth/gf14nxgslogl14hdm078f_dlvl_$dbcorner"
lappend link_path "$STDLIBPATH/gf14nxgslogl14hds078f/logic_synth/gf14nxgslogl14hds078f_$dbcorner"
lappend link_path "$STDLIBPATH/gf14nxgvlogl14hds078f/logic_synth/gf14nxgvlogl14hds078f_$dbcorner"
lappend link_path "$STDLIBPATH/gf14nxgllogl14hds078f/logic_synth/gf14nxgllogl14hds078f_$dbcorner"
lappend link_path "$STDLIBPATH/gf14nxgslogl16hds078f/logic_synth/gf14nxgslogl16hds078f_$dbcorner"

read_db "$STDLIBPATH/gf14nxgllogl14hdm078f/logic_synth/gf14nxgllogl14hdm078f_ulvl_$dbcorner"
read_db "$STDLIBPATH/gf14nxgllogl14hdm078f/logic_synth/gf14nxgllogl14hdm078f_dlvl_$dbcorner"
read_db "$STDLIBPATH/gf14nxgslogl14hdm078f/logic_synth/gf14nxgslogl14hdm078f_$dbcorner"
read_db "$STDLIBPATH/gf14nxgslogl14hdm078f/logic_synth/gf14nxgslogl14hdm078f_dlvl_$dbcorner"
read_db "$STDLIBPATH/gf14nxgslogl14hds078f/logic_synth/gf14nxgslogl14hds078f_$dbcorner"
read_db "$STDLIBPATH/gf14nxgvlogl14hds078f/logic_synth/gf14nxgvlogl14hds078f_$dbcorner"
read_db "$STDLIBPATH/gf14nxgllogl14hds078f/logic_synth/gf14nxgllogl14hds078f_$dbcorner"
read_db "$STDLIBPATH/gf14nxgslogl16hds078f/logic_synth/gf14nxgslogl16hds078f_$dbcorner"






