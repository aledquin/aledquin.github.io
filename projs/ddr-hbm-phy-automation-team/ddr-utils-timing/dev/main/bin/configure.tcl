# See SiliconSmart User Guide Appendix B for a complete list of parameters and definitions

#################################
# OPERATING CONDITIONS DEFINITION
#################################
#
# Create one or more operation conditions here.  Example:
#
#    create_operating_condition op_cond
#    set_opc_process op_cond {
#        {.lib "<LIB_NAME>" <TAG>}
#        {.lib "<LIB_NAME>" <TAG>}
#    }
#    add_opc_supplies op_cond VDD 1.1
#    add_opc_grounds op_cond VSS 0.0
#    set_opc_temperature op_cond 25
#


#################################
# GLOBAL CONFIGURATION PARAMETERS
#################################
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

define_parameters default {

    # List of operating conditions as defined by create_operation_condition
    set active_pvts { op_cond }

    # If using IBIS, one operating condition must be specified in ibis_typ_pvt
    # set ibis_typ_pvt op_cond

    # FINESIM
    set simulator finesim
    set simulator_cmd {finesim_spice -w <input_deck> -o <listing_file> >&/dev/null}

    # FINESIM EMBEDDED
    # set simulator finesim_embedded

    # HSPICE
    # set simulator hspice
    # set simulator_cmd {hspice <input_deck> -o <listing_file>}

    # HSPICE (client/server mode)
    # set simulator hspice_cs
    # set simulator_cmd {hspice -CC <input_deck> -port <port_num> -o <listing_file>}
    
    # Default simulator options for Finesim, Hspice
    set simulator_options {
        "common,finesim: finesim_mode=spicehd finesim_method=gear finesim_speed=0 finesim_dvmax=0.1"
	
	"common,hspice: probe=1 runlvl=5 numdgt=7 measdgt=7 acct=1 nopage"
	"power,hspice: method=gear” 
	"leakage,hspice: method=gear” 
    }

    # Simulation resolution
    set time_res_high 1e-12

    # Controls which supplies are measured for power consumption
    set power_meas_supplies { VDD }

    # list of ground supplies used (required for Functional Recognition)
    set power_meas_grounds { VSS }

    # specifies which multi-rail format to be used in Liberty model; none, v1, or v2.
    set liberty_multi_rail_format none

    # LOAD SHARE PARAMETERS
    #  job_scheduler: 'lsf' (Platform), 'grid' (SunGrid), or 'standalone' (local machine)
    set job_scheduler standalone
    set run_list_maxsize 1
    set normal_queue "lsf_queue_name"
}


############################
# DEFAULT PINTYPE PARAMETERS
############################
pintype default {

    set logic_high_name VDD
    set logic_high_threshold 0.8

    set logic_low_name VSS
    set logic_low_threshold 0.2

    set prop_delay_level 0.5

    # Number of slew and load indices
    # (when importing with -use_default_slews -use_default_loads)
    set numsteps_slew 5
    set numsteps_load 5
    set constraint_numsteps_slew 3

    # Operating load ranges
    set smallest_load 10e-15
    set largest_load 90e-15

    # Operating slew ranges
    set smallest_slew 10e-12
    set largest_slew 1.2e-9
    set max_tout 1.0e-9

    # Automatically determine largest_load based on max_tout; off or on
    set autorange_load off

    # Noise of points in for noise height
    set numsteps_height 8

    # Input noise width.
    set numsteps_width 5

    # driver model: pwl, emulated, active, active-waveform, custom
    set driver_mode pwl

    # driver cell name (relevant only when driver_mode is "active")
    set driver pwl
}


#####################################
# LIBERTY MODEL GENERATION PARAMETERS
#####################################
define_parameters liberty_model {
    # Add Liberty header attributes here for use with "model -create_new_model"
    set delay_model "table_lookup"
    set default_fanout_load 0.0
    set default_inout_pin_cap 0.0
    set default_input_pin_cap 0.0
    set default_output_pin_cap 0.0
    set default_cell_leakage_power 0.0
    set default_leakage_power_density  0.0
}


#######################
# VALIDATION PARAMETERS
#######################
define_parameters validation {
    # Add validation parameters here
}
