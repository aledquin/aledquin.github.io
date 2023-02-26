set start_icc2_dir /slowfs/dcopt105/alvaro/DCG_congestion/test1/SRMui_spg_test/dcg30_czr/pv_export/dcg_lWoOAh_22524/

set dcg_icc2_ref_libs [list \
/slowfs/pv_prj11/DC_PRS/suites/cong_suite/dcg30_czr/ndm/ngk_im1_memorylvt012v_C1V12S4_MAX.ndm \
/slowfs/pv_prj11/DC_PRS/suites/cong_suite/dcg30_czr/ndm/ngk_im1_stdlvt7g_C1V12S4_MAX.ndm \
/slowfs/pv_prj11/DC_PRS/suites/cong_suite/dcg30_czr/ndm/ngk_im1_stdmvt7g_C1V12S4_MAX.ndm \
/slowfs/pv_prj11/DC_PRS/suites/cong_suite/dcg30_czr/ndm/ngk_im1_stdslvt7g_C1V12S4_MAX.ndm \
 ]
if {[file exists /slowfs/dcopt105/alvaro/DCG_congestion/test1/SRMui_spg_test/dcg30_czr/pv_export/dcg_lWoOAh_22524/icc2_voZKET]} {
  file delete -force /slowfs/dcopt105/alvaro/DCG_congestion/test1/SRMui_spg_test/dcg30_czr/pv_export/dcg_lWoOAh_22524/icc2_voZKET
}
create_lib -technology ${start_icc2_dir}/data/des.tf -ref_libs ${dcg_icc2_ref_libs} /slowfs/dcopt105/alvaro/DCG_congestion/test1/SRMui_spg_test/dcg30_czr/pv_export/dcg_lWoOAh_22524/icc2_voZKET
open_lib /slowfs/dcopt105/alvaro/DCG_congestion/test1/SRMui_spg_test/dcg30_czr/pv_export/dcg_lWoOAh_22524/icc2_voZKET



if {[file exists ${start_icc2_dir}/data/des.v]} {
read_verilog -library /slowfs/dcopt105/alvaro/DCG_congestion/test1/SRMui_spg_test/dcg30_czr/pv_export/dcg_lWoOAh_22524/icc2_voZKET -top casez_rom ${start_icc2_dir}/data/des.v
}


if {[file exists ${start_icc2_dir}/data/des.fp.tcl/floorplan.tcl]} {
redirect -append ${start_icc2_dir}/data/des.fp.tcl/floorplan.tcl.log {source -continue_on_error -echo -verbose ${start_icc2_dir}/data/des.fp.tcl/floorplan.tcl}
}


if {[file exists ${start_icc2_dir}/data/des.scan.def]} {
read_def ${start_icc2_dir}/data/des.scan.def
}
read_parasitic_tech -tlup /slowfs/pv_scratch28/24x7/dcrt/spf_main_dcnt/xzchang/24disk_1/D20161213_3471304/Test/congestion_suite_setup/cong_suite/dc_cong_suite/MWLIBS/TECH/MAX.TLUplus -layermap /slowfs/pv_scratch28/24x7/dcrt/spf_main_dcnt/xzchang/24disk_1/D20161213_3471304/Test/congestion_suite_setup/cong_suite/dc_cong_suite/MWLIBS/TECH/layer_map.apollo -name max_tlup


## scenario mode: MAX
create_corner max_corner
current_corner max_corner
set_parasitics_parameters -corner [current_corner] -late_spec max_tlup -early_spec max_tlup


if {[file exists ${start_icc2_dir}/data/des.sdc.tcl.CORNER]} {
set_app_options -global {constraint.convert_from_bc_wc wc_only}
redirect -append -file ${start_icc2_dir}/data/des.sdc.tcl.CORNER.log {read_sdc -echo ${start_icc2_dir}/data/des.sdc.tcl.CORNER}
set_app_options -global {constraint.convert_from_bc_wc none}
}
report_parasitic_parameters
create_mode max_mode
current_mode max_mode


if {[file exists ${start_icc2_dir}/data/des.sdc.tcl.MODE]} {
set_app_options -global {constraint.convert_from_bc_wc wc_only}
redirect -append -file ${start_icc2_dir}/data/des.sdc.tcl.MODE.log {read_sdc -echo ${start_icc2_dir}/data/des.sdc.tcl.MODE}
set_app_options -global {constraint.convert_from_bc_wc none}
}
create_scenario -mode max_mode -corner max_corner -name MAX


if {[file exists ${start_icc2_dir}/data/casez_rom.MAX.PVT.tcl]} {
source -continue_on_error -echo -verbose ${start_icc2_dir}/data/casez_rom.MAX.PVT.tcl
}


if {[file exists ${start_icc2_dir}/data/des.sdc.tcl.SCENARIO]} {
set_app_options -global {constraint.convert_from_bc_wc wc_only}
redirect -append -file ${start_icc2_dir}/data/des.sdc.tcl.SCENARIO.log {read_sdc -echo ${start_icc2_dir}/data/des.sdc.tcl.SCENARIO}
set_app_options -global {constraint.convert_from_bc_wc none}
}
set_scenario_status MAX -active true -all

set_app_options -global {constraint.convert_from_bc_wc none}





## scenario mode: MIN
create_corner min_corner
current_corner min_corner
set_parasitics_parameters -corner [current_corner] -late_spec max_tlup -early_spec max_tlup


if {[file exists ${start_icc2_dir}/data/des.sdc.tcl.CORNER]} {
set_app_options -global {constraint.convert_from_bc_wc bc_only}
redirect -append -file ${start_icc2_dir}/data/des.sdc.tcl.CORNER.log {read_sdc -echo ${start_icc2_dir}/data/des.sdc.tcl.CORNER}
set_app_options -global {constraint.convert_from_bc_wc none}
}
report_parasitic_parameters
create_mode min_mode
current_mode min_mode


if {[file exists ${start_icc2_dir}/data/des.sdc.tcl.MODE]} {
set_app_options -global {constraint.convert_from_bc_wc bc_only}
redirect -append -file ${start_icc2_dir}/data/des.sdc.tcl.MODE.log {read_sdc -echo ${start_icc2_dir}/data/des.sdc.tcl.MODE}
set_app_options -global {constraint.convert_from_bc_wc none}
}
create_scenario -mode min_mode -corner min_corner -name MIN


if {[file exists ${start_icc2_dir}/data/casez_rom.MIN.PVT.tcl]} {
source -continue_on_error -echo -verbose ${start_icc2_dir}/data/casez_rom.MIN.PVT.tcl
}


if {[file exists ${start_icc2_dir}/data/des.sdc.tcl.SCENARIO]} {
set_app_options -global {constraint.convert_from_bc_wc bc_only}
redirect -append -file ${start_icc2_dir}/data/des.sdc.tcl.SCENARIO.log {read_sdc -echo ${start_icc2_dir}/data/des.sdc.tcl.SCENARIO}
set_app_options -global {constraint.convert_from_bc_wc none}
}
set_scenario_status MIN -active true -all

set_app_options -global {constraint.convert_from_bc_wc none}



save_lib -all

set_ignored_layers -rc_congestion_ignored_layers {M1 MB ZA } -min_routing_layer {M1} -max_routing_layer {ZA} -verbose
set_attribute [get_layer M1] routing_direction horizontal
set_attribute [get_layer M2] routing_direction vertical
set_attribute [get_layer M3] routing_direction horizontal
set_attribute [get_layer M4] routing_direction vertical
set_attribute [get_layer M5] routing_direction horizontal
set_attribute [get_layer M7] routing_direction vertical
set_attribute [get_layer MB] routing_direction horizontal
set_attribute [get_layer MC] routing_direction vertical
set_attribute [get_layer ZA] routing_direction horizontal


if {[file exists ${start_icc2_dir}//data/des.dont_use_touch.tcl]} {
redirect -append -file ${start_icc2_dir}//data/des.dont_use_touch.tcl.log {source -continue_on_error -echo -verbose ${start_icc2_dir}//data/des.dont_use_touch.tcl}
}


if {[file exists ${start_icc2_dir}/data/routing_rule.tcl]} {
redirect -append ${start_icc2_dir}/data/routing_rule.tcl.log {source -continue_on_error -echo -verbose ${start_icc2_dir}/data/routing_rule.tcl}
}
source  /slowfs/dcopt105/alvaro/DCG_congestion/test1/SRMui_spg_test/dcg30_czr/icc2.tcl
puts "Design Compiler Graphical Linking IC Compiler II..."
start_gui
