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
utils__script_usage_statistics $script_name "2022ww23"

    if $ntEnablePOCV {

    report_path -variation -show_path_index -show_path_id -max -max_paths 2000 -nets -nosplit > max_timing.rpt
    report_path -variation -show_path_index -show_path_id -max -max_paths 2000 -path_type full_clock_expanded -nets -trans -full_transition_time -cap -rail_voltage -final_voltage -crosstalk_delta -wire_delay -nosplit >> max_timing.rpt
    report_path -variation -show_path_index -show_path_id -min -max_paths 2000 -nets -nosplit > min_timing.rpt
    report_path -variation -show_path_index -show_path_id -min -max_paths 2000 -path_type full_clock_expanded -nets -trans -full_transition_time -cap -rail_voltage -final_voltage -crosstalk_delta -wire_delay -nosplit >> min_timing.rpt


    } else {

    report_path -show_path_index -show_path_id -max -max_paths 2000 -nets -nosplit > max_timing.rpt
    report_path -show_path_index -show_path_id -max -max_paths 2000 -path_type full_clock_expanded -nets -trans -full_transition_time -cap -rail_voltage -final_voltage -crosstalk_delta -wire_delay -nosplit >> max_timing.rpt
    report_path -show_path_index -show_path_id -min -max_paths 2000 -nets -nosplit > min_timing.rpt
    report_path -show_path_index -show_path_id -min -max_paths 2000 -path_type full_clock_expanded -nets -trans -full_transition_time -cap -rail_voltage -final_voltage -crosstalk_delta -wire_delay -nosplit >> min_timing.rpt

    }

    report_pbsa_calculation [get_timing_paths -max -max_paths 100] > max_pbsa.rpt
    report_pbsa_calculation [get_timing_paths -min -max_paths 100] > min_pbsa.rpt

    if $ntEnablePOCV {

    ### report POCV calculation on critical max & min path
    report_variation_calculation [get_timing_paths -max -max_paths 100] > max_pocv.rpt
    report_variation_calculation [get_timing_paths -min -max_paths 100] > min_pocv.rpt

    }

    report_analysis_coverage -status_details untested -sort_by check_type -nosplit > coverage.rpt

    report_clock -nosplit > clock.rpt
    report_clock_arrivals -nosplit > clock_arrivals.rpt
    report_clock_arrivals -tree -nets -nosplit >  clock_tree_nets.rpt
    report_clock_arrivals -tree -nosplit >  clock_tree_pins.rpt
    report_clock_network -errors -verbose > clock_network.rpt

    #################################
    ### Report max arrival time and transitions 
    #################################
    report_arrivals -max -all -nosplit > ./max_arrival.rpt
    report_arrivals -min -all -nosplit > ./min_arrival.rpt
    report_arrivals -max -transition_greater_than 50 -all -nosplit > ./max_arrival_transition_over_50ps.rpt
    report_arrivals -min -transition_greater_than 50 -all -nosplit > ./min_arrival_transition_over_50ps.rpt
    report_arrivals -max -transition_greater_than 90 -all -nosplit > ./max_arrival_transition_over_90ps.rpt
    report_arrivals -min -transition_greater_than 90 -all -nosplit > ./min_arrival_transition_over_90ps.rpt


    #source $PROJ_HOME/design/timing/nt/ntFiles/proc_write_load_and_tran_cons_files.nt
    set utils_version $env(DDR_UTILS_TIMING_VERSION)
    source /remote/cad-rep/msip/tools/Shelltools/ddr-utils-timing/$utils_version/bin/proc_write_load_and_tran_cons_files.nt

    write_load_and_tran_cons_files -cell $cell 


    #################################
    ### SI reports
    #################################
    report_si_convergence > ./SI_convergence.rpt

    set nt_report_si_nets_max_nets 50
    report_si_nets -max -related_nets -transition_time -max_nets $nt_report_si_nets_max_nets > ./max_SI_nets.rpt

    set nt_report_crosstalk_delay_sources_max_aggressors 10
    set nt_report_crosstalk_delay_sources_max_nets 100

    report_crosstalk_delay_sources -max_aggressors $nt_report_crosstalk_delay_sources_max_aggressors -max_nets $nt_report_crosstalk_delay_sources_max_nets -max -aggressor_contributions -nosplit > si_delay_max.rpt
    report_crosstalk_delay_sources -max_aggressors $nt_report_crosstalk_delay_sources_max_aggressors -max_nets $nt_report_crosstalk_delay_sources_max_nets -min -aggressor_contributions -nosplit > si_delay_min.rpt

    update_noise
    report_noise -nworst 200 -nosplit > noise.rpt
    report_noise_violation_sources -nworst 100 -max_aggressors 5 -nosplit > noise_sources.rpt
    report_fanout_noise -nworst 100 -shape -nosplit > fanout.rpt


    report_constraint -max_capacitance -verbose > maxcap.rpt
    report_constraint -max_transition -verbose > maxtrans.rpt
    report_constraint -min_pulse_width -verbose > minpulse.rpt

    report_annotated_parasitics -check > parasitics_summary.rpt
    report_annotated_parasitics -list_annotated -max_nets 10000 > parasitics_annotated.rpt
    report_annotated_parasitics -list_not_annotated -max_nets 10000 > parasitics_not_annotated.rpt

    report_annotated_device_parameters -max_transistors 100000 -list_not_annotated > transistors_not_annotated_all

    if {[info exists par_rpt_nets]} {
    report_annotated_parasitics -list_annotated -max_nets 10000 $par_rpt_nets > custom_parasitics.rpt
    }

    report_simulation -verbose > simulation.rpt


    #########################
    #variationrpt generation
    ########################

    if $ntEnablePOCV {

    report_variation > variation.rpt


    }
