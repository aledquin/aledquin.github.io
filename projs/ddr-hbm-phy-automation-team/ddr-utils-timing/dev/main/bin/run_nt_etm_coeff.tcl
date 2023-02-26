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

source ./pvt_setup.tcl
set corner $PVT
set mode 1
set cell $cellName
##source ../stdlib_version.txt   ##   Need to figure out how stdcell libs are to be managed.
set dbcorner $PVT.db
#set currcorner ffg_minR_minC_1p0v_n40
set metal_stack $metalStack
#set lib_suffix $libSuffix
#set vcore $VDD_val
#set vio $VDDQ_val

#########################################
##global settings
############################################
source ${PROJ_HOME}/nt_global_settings.tcl
source ../../src/user_setting.tcl
source ${PROJ_HOME}/nt_functions.tcl


### control lvf variation format in ETM
set model_generate_pocv_lvf true

### cmds to specify the sigma for setup and hold reporting (recommended by R&D)
set timing_pocv_sigma 3
set timing_pocv_sigma_min 6


################################################################
## Load any timing libs if available or needed
################################################################
set link_path " * "

if {$mode == 1} {
      source ../../src/model_port.tcl
#  ntManager flow puts all lib/db references into user_lib_include.tcl    
#      if {$use_stdcells == 1} {
#            source ${PROJ_HOME}/design/timing/nt/ntFiles/nt_load_libs.tcl
#      }
      source ../../src/user_lib_include.tcl
} else {
      set link_prefer_model_port *
}

##################################################################
## Read spice models
##################################################################
register_netlist -format spice nt_tech.sp
if {$mode == 1} {
      register_netlist -format spice {netlist.sp netlist_sub.sp} 
} else {
      register_netlist -format spice netlist.sp
}
read_spice_model -name $PVT nt_tech.sp
set search_path { . }
set oc_global_voltage $OC_GLOBAL_VOLTAGE
set model_apply_oc_global_voltage true


###################################################################
## Prelink phase
###################################################################

##################################################################
# Setting all power supply aliases for the design
##################################################################
# To get rid of "TECH-021 violations" where macro model parasitics found - Boon 07/10/2015
set link_enable_wrapper_subckt_parasitics false

link_design $cell -keep_capacitive_coupling

# Setting the technology corner and power rail voltage for analysis
set_technology $PVT

#setup ports
source ../../src/port_setup.tcl

# Setting supply voltages for analysis
source ../../src/pwr_supply.tcl

# Input and output port directions
set_port_direction -input $INPUTS
set_port_direction -output $OUTPUTS
if {${INOUT_status} == 1} {
    set_port_direction -inout $INOUTS
}

###########################################################
## Topology setup stage
###########################################################
source ${PROJ_HOME}/nt_topology.tcl

###########################################################
## Prematch - Put your constraints here
###########################################################

if [info exists ntGlobalConstraints] { source $ntGlobalConstraints }
source ../../src/constraints.tcl

if [info exists ntGlobalPrematchtopo] { source $ntGlobalPrematchtopo }
source ../../src/prematchtopo.tcl

match_topology

if [info exists ntGlobalPrechecktopo] { source $ntGlobalPrechecktopo }
source ../../src/prechecktopo.tcl

##########################################################
## Check Topology 
##########################################################
source ${PROJ_HOME}/nt_check_topology.tcl

##########################################################
## Check Design
##########################################################
## Timing exceptions go here
if [info exists ntGlobalExceptions] { source $ntGlobalExceptions }
source ../../src/exceptions.tcl

if [info exists ntGlobalPrecheck] { source $ntGlobalPrecheck }
source ../../src/precheck.tcl

##################################
# Add POCV variation coeffcients
##################################

source /slowfs/us01dwt3p207/cheah/d519_pocv_lvf/xtor_variations/set_variation_parameters.tcl


source ${PROJ_HOME}/nt_check_design.tcl

##################################
# Report variation
##################################
report_variation > variation.rpt
#return


########################################################
## Timing Lib Creating
########################################################
#source ${PROJ_HOME}/design/timing/nt/ntFiles/nt_gen_model.tcl

source /slowfs/us01dwt3p207/cheah/d523_pocv_lvf/nt_scripts/nt_gen_model.tcl

#save_session -replace ${cell}_${corner}
exit

