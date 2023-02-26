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

set pbsa_KBmax 0.10
set pbsa_KBmin -0.10
set pbsa_KDmax 0.15
set pbsa_KDmin -0.15
set pbsa_KCmax 0.50
set pbsa_KCmin -0.10
set pbsa_KUsetup 1.00
set pbsa_KUhold 1.00

set lib_time_unit 1ps
set lib_capacitance_unit 1ff
set lib_current_unit 1uA
set timing_analysis_coverage 1

set timing_latch_hold_fall_margin  0
set timing_latch_hold_rise_margin  0
set timing_latch_setup_fall_margin  0
set timing_latch_setup_rise_margin  0

set timing_flip_flop_hold_fall_margin  0
set timing_flip_flop_hold_rise_margin  0
set timing_flip_flop_setup_fall_margin  0
set timing_flip_flop_setup_rise_margin  0

set si_enable_analysis true
set si_enable_noise_analysis true
set si_enable_noise_fanout_analysis true
set si_enable_aggressor_logic_pessimism_reduction true

set timing_enable_multi_input_switching true

append link_vdd_alias " vdd vddp VDD VDDP vp VMEMP VMEMIO VDDQ VDA VDS3 VDDQLP VAA BP_VREFDACREF_IN"
printvar link_vdd_alias
append link_gnd_alias " vss VSS gd VSH"
printvar link_gnd_alias

set timing_differential_iteration_count 2

set rc_slew_lower_threshold_pct_fall 20.0 
set rc_slew_upper_threshold_pct_fall 80.0 
set rc_slew_lower_threshold_pct_rise 20.0 
set rc_slew_upper_threshold_pct_rise 80.0


## topo_latch_setup_to 
## This variable specifies where NanoTime performs setup checking in latch circuits. It can be set to latch_net (the default), input, or output. 
## Setting the variable to output causes NanoTime to check for the arrival of data at the latch output rather than the latch node, resulting in a more conservative check. 
## Setting the variable to input results in a less restrictive check.

## topo_latch_hold_to
## This variable specifies where NanoTime performs hold checking in latch circuits. It can be set to either latch_net (the default) or input. 
## Setting the variable to input causes NanoTime to check for the arrival of data at the latch input rather than the latch node, resulting in a more conservative check.

set topo_latch_setup_to output
set topo_latch_hold_to input


####################################################################
## Set input slew to be 40ps (For internal timing only)
####################################################################

set input_slew 40

####################################################################
## Set CLK Freq
####################################################################

set period_3200 624
set ui_3200 312
set hui_3200 156

set period_3733 534
set ui_3733 267
set hui_3733 133

set period_4267 468
set ui_4267 234
set hui_4267 117

set period_4400 454
set ui_4400 227
set hui_4400 113

set period_6400 312.5
set ui_6400 156.25
set hui_6400 78.125


#######################################################################################
### The following was added based on discusstion with other teams using NT within SNPS
#######################################################################################

####################
# General variables
####################

# solves TIMI messages
#set trace_disable_switching_net_logic_check true
# times from when CCLK goes away if there is failing contention
set timing_precharge_contention_recovery true

#Save extra timing information
set timing_save_wire_delay true
set timing_save_pin_arrival_and_transition true

########################################################
# Adjusting slew thresholds to 80/20 (default is 90/10)
######################################################## 
#set rc_slew_upper_threshold_pct_fall $timing_hash(slew_upper_threshold_pct_fall)
#set rc_slew_upper_threshold_pct_rise $timing_hash(slew_upper_threshold_pct_rise)
#set rc_slew_lower_threshold_pct_fall $timing_hash(slew_lower_threshold_pct_fall)
#set rc_slew_lower_threshold_pct_rise $timing_hash(slew_lower_threshold_pct_rise)
# We don't want set_input_transition to use full transition! It should be 20-80!
set rc_input_threshold_full_transition false

#########################
# RC annotation settings
#########################
#Parasitics source/drain swapping allowed
set parasitics_enable_drain_source_swap "true"

##################################################
#Updated 6/13/2016 based on Prasanthi's findings
# @ - Calibre extraction
# _NETTRAN_- ICV extraction
##################################################
#Characters for fingered transistors
set parasitics_fingered_device_chars _NETTRAN_
#set parasitics_fingered_device_chars @


#Recognize RC subnodes have subnode numbers
set parasitics_accept_node_name_net_name true
#Controlling RC reduction
# turn RC reduction off by default
#set rc_reduction_max_net_delta_delay 0
#set rc_reduction_min_net_delta_delay 0
set rc_reduction_exclude_boundary_nets false
#Specifying transistor pin names
set link_transistor_drain_pin_name DRN
set link_transistor_source_pin_name SRC
set link_transistor_gate_pin_name GATE
set link_transistor_bulk_pin_name BULK
#set link_transistor_drain_pin_name d
#set link_transistor_source_pin_name s
#set link_transistor_gate_pin_name g
#set link_transistor_bulk_pin_name b

#Enable PODE devices recognition 
set parasitics_xref_layout_instance_prefix "ld_"


#############################################
# Accuracy Settings & Signoff Recommendations
#############################################

#Turning on Active Miller effect (default false)
set sim_miller_use_active_load true
set sim_miller_direction_check true
set sim_miller_use_active_load_max_only false
## added 8/4/2016
set sim_miller_use_active_load_min true 

#Enable extended miller loads to do less inverter simplification (8/4/2016)
set sim_miller_use_extended_load true

#Including more sidebranch transistors for delay calculation (default 0)
set timing_extended_sidebranch_analysis_level 1

#speed-versus-accuracy parameter for the delay calculator (default 0.05)
#set sim_cfg_spd 0.01

#Threshold for mapping transistors to unavailable transistor model bins (default 1)
#set tech_match_length_pct 0.5
#set tech_match_width_pct  0.5
#set tech_match_param_pct  0.5





#################################################
# Controlling clock propagation and path tracing
#################################################
set topo_auto_find_latch_clock true
set topo_clock_gate_depth 10000
set trace_through_inputs true
set trace_through_outputs true
set trace_transparent_loop_checking true
set trace_transparent_inverting_loops true
set topo_auto_find_latch_clock_thru_port true
#set trace_transparent_clock_gate_propagate_closing_edge true
#set trace_disable_switching_net_logic_check true
#set trace_latch_error_recovery false
#set transistor_stack_bidirectional_limit 3

#############################################
# Enabling Strict Analysis Flows in NanoTime 
#############################################
#Strictly check transistor direction during check_topology.
set topo_check_transistor_direction true
#waive bidirectional transistor that drives a floating output (cell attribute bidirection_related_to_floating_output)
set topo_waive_nondirectional_transistor true
#Strictly check storage node during check_topology.
#set topo_check_storage_node true
#Strictly check clock network during check_topology.
#set topo_check_clock_network true

## Added for 14nm & below recommendations
set find_clock_driven_data_inputs true
set topo_sequential_structure_strict_input_matching true
set topo_sequential_structure_install_extended_timing_check true
#Enable level based shaper detection of 2 input shapers/ pulsers
set topo_clock_gate_allow_reconvergent_clocks true
#Enable delay based shaper detection of 2 or more input shapers
set topo_clock_gate_timing_resolution true
#Enable strict clock shaper resolution
set topo_clock_gate_strict_checking true

# Enable the recognition of parallel stacks. (Default=false) - Added 8/10/2016
# With parallel stacks found, one stack is used as representative of the group & used for path tracing.
set topo_find_parallel_stack true


####################
# PBSA settings
####################
#Considering path arcs common only when they drive same net and have the same switching direction (during PBSA calculations)
set pbsa_same_common_switching_direction true
#Allow the common net occur beyond the first divergence if the data and clock paths converge later.
set pbsa_allow_reconvergent_common_net true
#Save a new pattern and associated commands in a user topology library
set topo_create_lib_topology false

#Allow common path removal across generated clocks
set pbsa_enable_chained_generated_clocks true
#Enable ONLY same edge reconvergence analysis -  mismatch edge has to take physically different paths, and different points of time �
set pbsa_same_edge_reconvergence_only true
#Enable ONLY 0 cycle SI common delta delay differences to be removed
set pbsa_include_common_si_deltas true
#Allow mismatch edge common path pessimism removal(min(R - R, F - F))
set pbsa_same_common_switching_direction false
set pbsa_common_net_use_same_direction_delays true 
#Allow pessimism removal on 0cycle same edge reconvergent paths only
set pbsa_same_edge_zero_cycle_reconvergence_only true

####################################################################
## Slew limits for edgerate check of internal nodes
####################################################################
set max_slew_limit 100
set min_slew_limit 10
set max_clock_slew_limit 100
set min_clock_slew_limit 10

###########################################################################
## Important 10nm/Advanced Nodes Settings for Accuracy (NT Fest July 2015) 
###########################################################################
#set sim_miller_use_active_load true
#set sim_miller_use_active_load_min true
#set parasitics_min_capacitance 
#set rc_reduction_max_net_delta_delay 0.0005
#set si_move_miller_caps_into_fets true

#############################
# Parasitics Recommendations
#############################
#Min parasitic capacitance allowed
set parasitics_min_capacitance "1e-09"
#Set RC reduction - min & max allowed delta delays per net during rc-reduction (smaller is better but leads to more runtime)
set rc_reduction_max_net_delta_delay 0.0005
set rc_reduction_min_net_delta_delay 0.00005
#Move parasitic device Miller Cap (across stage input and output) out of SI analsysis and directly into simulator
set si_move_miller_caps_into_fets true
#Use SKIP_CELL for blackboxes where ever possible
set parasitics_enable_mapping_unresolved_pins true
#Suppress schematic only params from being inherited by DPF
set parasitics_suppress_dpf_inheritance "multi nf nf_flat"

#Updated rail resistance option to new flow for NT M-2016.12 - 4/10/2017
#########################################################################
#(1) When the parasitics_enable_rail_contact_resistance variable is set to true, 
#    NanoTime calculates the single effective contact resistance value for each pin connected to the rail nets. 
#    This flow has limitations in handling of complex resistance topologies that arise from trench contacts used in modern FinFET technologies.
#(2) When the parasitics_enable_rail_net_resistance variable is set to true, 
#    NanoTime includes the complete set of back-annotated rail net resistances in path delay estimation. 
#    Complex resistance topologies including meshes, ladders, or loops are accurately modeled. 
#    Resistances on virtual rail nets are supported as well. For the correct back-annotation of resistances on virtual rail nets, 
#    make sure that power switch transistors are properly marked or recognized.

#set parasitics_enable_rail_contact_resistance true
set parasitics_enable_rail_net_resistance true

#Treat resistances greater that link_switch_resistors_open_resistance as opens.
#Added to avoid preceived power/ground shorts with the 'parancap' elements in ss10.
##  Removed per Boon request.
#set link_switch_resistors_as_switch_subckts true

###################################
## To be added in macro constraints
###################################

###Need to add in custom cell constraint file for multivoltage macros to accurately represent the waveforms between voltage domains
###set_nonlinear_waveform -threshold 1 -samples 21 [get_nets -hier *]

###Enable RC skew analysis between the fingers
###set_enable_input_spf_skew -threshold 0.5 [get_nets -hier *]


###################################
## POCV LVF Enablements
###################################

### Include transistor variation and systemic/global(PBSA) wire delay variation
#set timing_pocv_gate_delay_only true
#set timing_pbsa_gate_delay_only true
#set pbsa_K*wiremax "0.165"
#set pbsa_K*wiremin "-0.135"

### Control LVF variation format in ETM
set model_generate_pocv_lvf true

### Cmds to specify the sigma for setup and hold reporting  (recommended by R&D)
set timing_pocv_sigma 3
set timing_pocv_sigma_min 6
set model_enable_split_early_late_sigma false 
