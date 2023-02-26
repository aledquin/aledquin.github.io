########################################################################################
# This Software and documentation if any (hereinafter, "Software") is an unpublished,  #
# unsupported, confidential, proprietary work of Synopsys, Inc.                        #
#                                                                                      #
# The Software IS NOT an item of Licensed Software or Licensed Product under any End   #
# User Software License Agreement or Agreement for Licensed Product with Synopsys or   #
# any supplement thereto. You are permitted to internally use and internally           #
# redistribute this Software in source and binary forms, with or without modification, #
# provided that redistributions of source code must retain this notice. You may not    #
# view, use, disclose, copy or distribute this file or any information contained       #
# herein except pursuant to this license grant from Synopsys. If you do not agree with #
# this notice, including the disclaimer below, then you are not authorized to use the  #
# Software.                                                                            #
#                                                                                      #
# THIS SOFTWARE IS BEING DISTRIBUTED BY SYNOPSYS SOLELY ON AN "AS IS" BASIS AND ANY    #
# EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES #
# OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE HEREBY DISCLAIMED. IN NO #
# EVENT SHALL SYNOPSYS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,        #
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF   #
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS             #
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,    #
# STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT #
# OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.      #
########################################################################################

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


set VERSION 2.8

package require Tcl 8.4

proc read_cell_data { args } {
	set cargs(-library) ""
	lappend cargs(-cell) ""
	set cargs(-array_name) ""
	set cargs(-debug) 0

	if { [parse_myproc_arguments -args $args cargs] eq "0" } {
		return 0
	}

	if { $cargs(-cell) eq ""} {
		lappend cargs(-cell) "*"
	}

	if {[string compare $cargs(-array_name) ""] != 0 } {
		upvar $cargs(-array_name) cellarray
	}

	if { $cargs(-library) eq "" } {
		die "Error: missing -library option to read_cell_data"
	}

	foreach file [glob -nocomplain $cargs(-library)]  {
		echo "Reading Synopsys Liberty file: $file"
		set in_timing 0
		set timing_data "0"
		set sense  ""
		set type ""
		set when  ""
		set sdf_cond  ""
		set fin [open "$file" r]
		while {1} {
			set line [gets $fin]
			if {[eof $fin]} {
				close $fin
				break
			}
			if {[regexp "^\[ \t\]*library\[ \t\]*\\\(\[ \t\]*\[\"\]*\[ \t\]*(\[^\; \"\(\)\]+)\[ \t\]*\[\"\]*\[ \t\]*\\\)" $line dum key1]} {
				set cellarray(library)  $key1
			} elseif {[regexp "^\[ \t\]*cell\[ \t\]*\\\(\[ \t\]*\[\"\]*\[ \t\]*(\[^\; \"\(\)\]+)\[ \t\]*\[\"\]*\[ \t\]*\\\)" $line dum key1]} {
				set cellname $key1
				if {[defined -nocase cellarray(cell,$cellname,input)]} {
					set user_input 1
				} else {
					set user_input 0
				}
				if {[defined -nocase cellarray(cell,$cellname,output)]} {
					set user_output 1
				} else {
					set user_output 0
				}
				if {[defined -nocase cellarray(cell,$cellname,sensitization)]} {
					set user_sensitization 1
				} else {
					set user_sensitization 0
				}
				foreach key1  $cargs(-cell) {
					regsub -all -- "\\\*" $key1 ".\*" key1
					if {[regexp "^$key1$" $cellname]} {
						puts "Parsing Lib Cell $cellname\n"
						set cellmatch($cellname) $cellname
						set cellarray(cell,$cellname,is_sequential) 0
					}
				}
			} elseif {[regexp "^\[ \t\]*pin\[ \t\]*\\\(\[ \t\]*\[\"\]*\[ \t\]*(\[^\; \"\(\)\]+)\[ \t\]*\[\"\]*\[ \t\]*\\\)" $line dum key1]} {
				set pin  $key1
				set cellarray(cell,$cellname,pin,$pin,is_rise_edge_triggered_output_pin) "false"
				set cellarray(cell,$cellname,pin,$pin,is_clock_pin) "false"
				set cellarray(cell,$cellname,pin,$pin,direction) ""
			} elseif {[regexp "^\[ \t\]*rc_input_threshold_pct_rise\[ \t\]*\:\[ \t\]*\[\"\]*\[ \t\]*(\[^\;\" \]+)\[ \t\]*\[\"\]*\[ \t\]*;" $line dum key1]} {
				if {[defined -nocase cellmatch($cellname)]} {
					set cellarray(cell,$cellname,pin,$pin,rc_input_threshold_pct_rise) $key1
				}
			} elseif {[regexp "^\[ \t\]*rc_input_threshold_pct_fall\[ \t\]*\:\[ \t\]*\[\"\]*\[ \t\]*(\[^\;\" \]+)\[ \t\]*\[\"\]*\[ \t\]*;" $line dum key1]} {
				if {[defined -nocase cellmatch($cellname)]} {
					set cellarray(cell,$cellname,pin,$pin,rc_input_threshold_pct_fall) $key1
				}
			} elseif {[regexp "^\[ \t\]*rc_slew_upper_threshold_pct_rise\[ \t\]*\:\[ \t\]*\[\"\]*\[ \t\]*(\[^\;\" \]+)\[ \t\]*\[\"\]*\[ \t\]*;" $line dum key1]} {
				if {[defined -nocase cellmatch($cellname)]} {
					set cellarray(cell,$cellname,pin,$pin,rc_slew_upper_threshold_pct_rise) $key1
				}
			} elseif {[regexp "^\[ \t\]*rc_slew_upper_threshold_pct_fall\[ \t\]*\:\[ \t\]*\[\"\]*\[ \t\]*(\[^\;\" \]+)\[ \t\]*\[\"\]*\[ \t\]*;" $line dum key1]} {
				if {[defined -nocase cellmatch($cellname)]} {
					set cellarray(cell,$cellname,pin,$pin,rc_slew_upper_threshold_pct_fall) $key1
				}
			} elseif {[regexp "^\[ \t\]*rc_slew_lower_threshold_pct_rise\[ \t\]*\:\[ \t\]*\[\"\]*\[ \t\]*(\[^\;\" \]+)\[ \t\]*\[\"\]*\[ \t\]*;" $line dum key1]} {
				if {[defined -nocase cellmatch($cellname)]} {
					set cellarray(cell,$cellname,pin,$pin,rc_slew_lower_threshold_pct_rise) $key1
				}
			} elseif {[regexp "^\[ \t\]*rc_slew_lower_threshold_pct_fall\[ \t\]*\:\[ \t\]*\[\"\]*\[ \t\]*(\[^\;\" \]+)\[ \t\]*\[\"\]*\[ \t\]*;" $line dum key1]} {
				if {[defined -nocase cellmatch($cellname)]} {
					set cellarray(cell,$cellname,pin,$pin,rc_slew_lower_threshold_pct_fall) $key1
				}
			} elseif {[regexp "^\[ \t\]*max_transition\[ \t\]*\:\[ \t\]*\[\"\]*\[ \t\]*(\[^\;\" \]+)\[ \t\]*\[\"\]*\[ \t\]*;" $line dum key1]} {
				if {[defined -nocase cellmatch($cellname)]} {
					set cellarray(cell,$cellname,pin,$pin,max_transition) $key1
				}
			} elseif {[regexp "^\[ \t\]*max_capacitance\[ \t\]*\:\[ \t\]*\[\"\]*\[ \t\]*(\[^\;\" \]+)\[ \t\]*\[\"\]*\[ \t\]*;" $line dum key1]} {
				set cellarray(cell,$cellname,pin,$pin,max_capacitance) $key1
				if {[defined -nocase cellmatch($cellname)]} {
					if {!$user_output && ( $cellarray(cell,$cellname,pin,$pin,direction) ne "in") && ![defined -nocase cellarray(cell,-,supply,$pin)] && ![defined -nocase cellarray(cell,$cellname,supply,$pin)]} {
						if {![defined -nocase cellarray(cell,$cellname,output)]} {
							set cellarray(cell,$cellname,output) $pin
						} elseif { $cellarray(cell,$cellname,pin,$pin,is_clock_pin) eq "false"} {
							set key2  $cellarray(cell,$cellname,output)
							if {$cellarray(cell,$cellname,pin,$key2,max_capacitance) <  $key1 } {
								set cellarray(cell,$cellname,output) $pin
							}
						}
					}
				}
			} elseif {[regexp "^\[ \t\]*pin_capacitance\[_max|_min\]*\[_rise|_fall\]*\[ \t\]*\:\[ \t\]*\[\"\]*\[ \t\]*(\[^\;\" \]+)\[ \t\]*\[\"\]*\[ \t\]*;" $line dum key1]} {
				if {[defined -nocase cellmatch($cellname)]} {
					if { ![defined -nocase cellarray(cell,$cellname,pin,$pin,capacitance)]} {
						set cellarray(cell,$cellname,pin,$pin,capacitance) $key1
					} elseif {$cellarray(cell,$cellname,pin,$pin,capacitance) > $key1} {
						set cellarray(cell,$cellname,pin,$pin,capacitance) $key1
					}
					set cellarray(cell,$cellname,pin,$pin,pin_capacitance) $key1
					if {!$user_input && ($cellarray(cell,$cellname,pin,$pin,direction) ne "out") && [defined -nocase cellarray(cell,$cellname,pin,direction] && ($cellarray(cell,$cellname,pin,direction) eq "in") && ![defined -nocase cellarray(cell,-,supply,$pin)] && ![defined -nocase cellarray(cell,$cellname,supply,$pin)]} {
						if {![defined -nocase cellarray(cell,$cellname,input)]} {
							set cellarray(cell,$cellname,input) $pin
						} elseif { $cellarray(cell,$cellname,pin,$pin,is_clock_pin) eq "false"} {
							set key2  $cellarray(cell,$cellname,input)
							if {$cellarray(cell,$cellname,pin,$key2,capacitance) >  $key1 } {
								set cellarray(cell,$cellname,input) $pin
							}
						}
					}
				}
			} elseif {[regexp "^\[ \t\]*min_capacitance\[ \t\]*\:\[ \t\]*\[\"\]*\[ \t\]*(\[^\;\" \]+)\[ \t\]*\[\"\]*\[ \t\]*;" $line dum key1]} {
				if {[defined -nocase cellmatch($cellname)]} {
					set cellarray(cell,$cellname,pin,$pin,min_capacitance) $key1
				}
			} elseif {[regexp "^\[ \t\]*direction\[ \t\]*\:\[ \t\]*\[\"\]*\[ \t\]*(\[^\;\" \]+)\[ \t\]*\[\"\]*\[ \t\]*;" $line dum key1]} {
				if {[defined -nocase cellmatch($cellname)]} {
					set cellarray(cell,$cellname,pin,$pin,direction) $key1
					if { ($key1 eq "in") && ![defined -nocase cellarray(cell,-,supply,$pin)] && ![defined -nocase cellarray(cell,$cellname,supply,$pin)]} {
						lappend cellarray(cell,$cellname,input_list) $pin
						if { !$user_input} {
							if  {($cellarray(cell,$cellname,pin,$pin,is_clock_pin) eq "true") } {
								set cellarray(cell,$cellname,input) $pin
							} else {
								if {![defined -nocase cellarray(cell,$cellname,input)]} {
									set cellarray(cell,$cellname,input) $pin
								} elseif { $cellarray(cell,$cellname,pin,$pin,is_clock_pin) eq "false"} {
									set key2 $cellarray(cell,$cellname,input)
									if {$cellarray(cell,$cellname,pin,$key2,capacitance) >  $key1 } {
										set cellarray(cell,$cellname,input) $pin
									}
								}
							}
						}
					} elseif { $key1 eq "internal" } {
					} elseif { ![defined -nocase cellarray(cell,-,supply,$pin)] && ![defined -nocase cellarray(cell,$cellname,supply,$pin)] } {
						lappend cellarray(cell,$cellname,output_list) $pin
						if { !$user_output && ($cellarray(cell,$cellname,pin,$pin,is_clock_pin) eq "true")} {
							set cellarray(cell,$cellname,output) $pin
						}
					}
					#lappend cellarray(cell,$cellname,lib_ports) $pin
				}
			} elseif {[regexp "^\[ \t\]*is_clock_pin\[ \t\]*\:\[ \t\]*\[\"\]*\[ \t\]*(\[^\;\" \]+)\[ \t\]*\[\"\]*\[ \t\]*;" $line dum key1]} {
				if {[defined -nocase cellmatch($cellname)]} {
					set cellarray(cell,$cellname,pin,$pin,is_clock_pin)  $key1
				}
				if { !$user_input && ($key1 eq "true") && ($cellarray(cell,$cellname,pin,$pin,direction) eq "in") } {
					set cellarray(cell,$cellname,input) $pin
				} elseif { !$user_output && ($key1 eq "true") && [regexp {(*out)} $cellarray(cell,$cellname,pin,$pin,direction) -] } {
					set cellarray(cell,$cellname,output) $pin
				}
			} elseif {[regexp "^\[ \t\]*is_rise_edge_triggered_clock_pin\[ \t\]*\:\[ \t\]*\[\"\]*\[ \t\]*(\[^\;\" \]+)\[ \t\]*\[\"\]*\[ \t\]*;" $line dum key1]} {
				if {[defined -nocase cellmatch($cellname)]} {
					set cellarray(cell,$cellname,pin,$pin,is_rise_edge_triggered_clock_pin) $key1
					if {$key1 eq "true"} {
						set cellarray(cell,$cellname,is_sequential) 1
					}
					if { !$user_input && ($key1 eq "true") && ($cellarray(cell,$cellname,pin,$pin,direction) eq "in") } {
						set cellarray(cell,$cellname,input) $pin
					}
				}
			} elseif {[regexp "^\[ \t\]*is_fall_edge_triggered_clock_pin\[ \t\]*\:\[ \t\]*\[\"\]*\[ \t\]*(\[^\;\" \]+)\[ \t\]*\[\"\]*\[ \t\]*;" $line dum key1]} {
				if {[defined -nocase cellmatch($cellname)]} {
					set cellarray(cell,$cellname,pin,$pin,is_fall_edge_triggered_clock_pin) $key1
					if {$key1 eq "true"} {
						set cellarray(cell,$cellname,is_sequential) 1
					}
					if { !$user_input && ($key1 eq "true") && ($cellarray(cell,$cellname,pin,$pin,direction) eq "in") } {
						set cellarray(cell,$cellname,input) $pin
					}
				}
			} elseif {[regexp "^\[ \t\]*is_rise_edge_triggered_data_pin\[ \t\]*\:\[ \t\]*\[\"\]*\[ \t\]*(\[^\;\" \]+)\[ \t\]*\[\"\]*\[ \t\]*;" $line dum key1]} {
				if {[defined -nocase cellmatch($cellname)]} {
					set cellarray(cell,$cellname,pin,$pin,is_rise_edge_triggered_data_pin) $key1
					if {$key1 eq "true"} {
						set cellarray(cell,$cellname,is_sequential) 1
					}
				}
			} elseif {[regexp "^\[ \t\]*is_fall_edge_triggered_data_pin\[ \t\]*\:\[ \t\]*\[\"\]*\[ \t\]*(\[^\;\" \]+)\[ \t\]*\[\"\]*\[ \t\]*;" $line dum key1]} {
				if {[defined -nocase cellmatch($cellname)]} {
					set cellarray(cell,$cellname,pin,$pin,is_fall_edge_triggered_data_pin) $key1
					if {$key1 eq "true"} {
						set cellarray(cell,$cellname,is_sequential) 1
					}
				}
			} elseif {[regexp "^\[ \t\]*is_clear_pin\[ \t\]*\:\[ \t\]*\[\"\]*\[ \t\]*(\[^\;\" \]+)\[ \t\]*\[\"\]*\[ \t\]*;" $line dum key1]} {
				if {[defined -nocase cellmatch($cellname)]} {
					set cellarray(cell,$cellname,pin,$pin,is_clear_pin)  $key1
				}
			} elseif {[regexp "^\[ \t\]*is_preset_pin\[ \t\]*\:\[ \t\]*\[\"\]*\[ \t\]*(\[^\;\" \]+)\[ \t\]*\[\"\]*\[ \t\]*;" $line dum key1]} {
				if {[defined -nocase cellmatch($cellname)]} {
					set cellarray(cell,$cellname,pin,$pin,is_preset_pin) $key1
				}
			} elseif {[regexp "^\[ \t\]*nom_process\[ \t\]*\:\[ \t\]*\[\"\]*\[ \t\]*(\[^\;\" \]+)\[ \t\]*\[\"\]*\[ \t\]*;" $line dum key1]} {
				set cellarray(nom_process) $key1
			} elseif {[regexp "^\[ \t\]*process_max\[ \t\]*\:\[ \t\]*\[\"\]*\[ \t\]*(\[^\;\" \]+)\[ \t\]*\[\"\]*\[ \t\]*;" $line dum key1]} {
				set cellarray(process_max) $key1
			} elseif {[regexp "^\[ \t\]*nom_temperature\[ \t\]*\:\[ \t\]*\[\"\]*\[ \t\]*(\[^\;\" \]+)\[ \t\]*\[\"\]*\[ \t\]*;" $line dum key1]} {
				set cellarray(nom_temperature) $key1
			} elseif {[regexp "^\[ \t\]*temperature_max\[ \t\]*\:\[ \t\]*\[\"\]*\[ \t\]*(\[^\;\" \]+)\[ \t\]*\[\"\]*\[ \t\]*;" $line dum key1]} {
				set cellarray(temperature_max) $key1
			} elseif {[regexp "^\[ \t\]*nom_voltage\[ \t\]*\:\[ \t\]*\[\"\]*\[ \t\]*(\[^\;\" \]+)\[ \t\]*\[\"\]*\[ \t\]*;" $line dum key1]} {
				set cellarray(nom_voltage) $key1
			} elseif {[regexp "^\[ \t\]*voltage_max\[ \t\]*\:\[ \t\]*\[\"\]*\[ \t\]*(\[^\;\" \]+)\[ \t\]*\[\"\]*\[ \t\]*;" $line dum key1]} {
				set cellarray(voltage_max) $key1
			} elseif {[regexp "^\[ \t\]*voltage_unit\[ \t\]*\:\[ \t\]*\[\"\]*\[ \t\]*(\[^;\" \]+)\[ \t\]*\[\"\]*\[ \t\]*;" $line dum key1]} {
				if {[regexp "\[mM\]\[Vv\]$" $2 dum key1]} {
					set cellarray(voltage_unit) "1e-3"
				} else {
					set cellarray(voltage_unit) 1
				}
			} elseif {[regexp "^\[ \t\]*capacitance_load_unit\[ \t\]*\\\(\[ \t\]*(\[^\[ \t\]\,\]+)\[ \t\]*,\[ \t\]*\[\"\]*\[ \t\]*(\[^\;\" \]+)\[ \t\]*\[\"\]*\[ \t\]*\\\)\[ \t\]*;" $line dum 1 2]} {
				if {[regexp "[pP][fF]" $2 dum key1]} {
					set cellarray(capacitance_load_unit) "1e-12"
				} elseif {[regexp "[fF][fF]" $2 dum key1]} {
					set cellarray(capacitance_load_unit) "1e-15"
				}
			} elseif {[regexp "^\[ \t\]*time_unit\[ \t\]*\:\[ \t\]*\[\"\]*\[ \t\]*(\[^;\" \]+)\[ \t\]*\[\"\]*\[ \t\]*;" $line dum key1]} {
				if {[regexp "\[pP\]\[Ss\]$" $2 dum key1]} {
					set cellarray(time_unit) "1e-12"
				} elseif {[regexp "\[nN\]\[Ss\]$" $2 dum key1]} {
					set cellarray(time_unit) "1e-9"
				}
			} elseif {[regexp "^\[ \t\]*slew_lower_threshold_pct_rise\[ \t\]*\:\[ \t\]*\[\"\]*\[ \t\]*(\[^;\" \]+)\[ \t\]*\[\"\]*\[ \t\]*;" $line dum key1]} {
				set cellarray(slew_lower_threshold_pct_rise) $key1
			} elseif {[regexp "^\[ \t\]*slew_lower_threshold_pct_fall\[ \t\]*\:\[ \t\]*\[\"\]*\[ \t\]*(\[^;\" \]+)\[ \t\]*\[\"\]*\[ \t\]*;" $line dum key1]} {
				set cellarray(slew_lower_threshold_pct_fall) $key1
			} elseif {[regexp "^\[ \t\]*slew_upper_threshold_pct_rise\[ \t\]*\:\[ \t\]*\[\"\]*\[ \t\]*(\[^;\" \]+)\[ \t\]*\[\"\]*\[ \t\]*;" $line dum key1]} {
				set cellarray(slew_upper_threshold_pct_rise) $key1
			} elseif {[regexp "^\[ \t\]*slew_upper_threshold_pct_fall\[ \t\]*\:\[ \t\]*\[\"\]*\[ \t\]*(\[^;\" \]+)\[ \t\]*\[\"\]*\[ \t\]*;" $line dum key1]} {
				set cellarray(slew_upper_threshold_pct_fall) $key1
			} elseif {[regexp "^\[ \t\]*input_threshold_pct_rise\[ \t\]*\:\[ \t\]*\[\"\]*\[ \t\]*(\[^;\" \]+)\[ \t\]*\[\"\]*\[ \t\]*;" $line dum key1]} {
				set cellarray(input_threshold_pct_rise) $key1
			} elseif {[regexp "^\[ \t\]*input_threshold_pct_fall\[ \t\]*\:\[ \t\]*\[\"\]*\[ \t\]*(\[^;\" \]+)\[ \t\]*\[\"\]*\[ \t\]*;" $line dum key1]} {
				set cellarray(input_threshold_pct_fall) $key1
			} elseif {[regexp "^\[ \t\]*slew_derate_from_library\[ \t\]*\:\[ \t\]*\[\"\]*\[ \t\]*(\[^;\" \]+)\[ \t\]*\[\"\]*\[ \t\]*;" $line dum key1]} {
				set cellarray(slew_derate_from_library) $key1
			} elseif {[regexp "^\[ \t\]*function\[ \t\]*\:\[ \t\]*\[\"\]*\[ \t\]*(\[^\;\"\]+)\"*\[ \t\]*;" $line dum key1]} {
				set function $key1
				if {[defined -nocase cellmatch($cellname)]} {
					set cellarray(cell,$cellname,pin,$pin,function) $key1
				}
			} elseif {[regexp "^\[ \t\]*operating_condition\[ \t\]*\:\[ \t\]*\[\"\]*\[ \t\]*(\[^\;\" \]+)\[ \t\]*\[\"\]*\[ \t\]*;" $line dum key1]} {
				set line [gets $fin]
				while {! [eof $fin] && ![regexp "^\[ \t\]*\}" $line dum key1]} {
					if {[regexp "^\[ \t\]*process*\:\[ \t\]*\[\"\]*\[ \t\]*(\[^\;\" \]+)\[ \t\]*\[\"\]*\[ \t\]*;" $line dum key1]} {
						set cellarray(process) $key1
					} elseif {[regexp "^\[ \t\]*voltage\:\[ \t\]*(\[^\;\" \]+)\[ \t\]*;" $line dum key1]} {
						set cellarray(voltage) $key1
					} elseif {[regexp "^\[ \t\]*temperature*\:\[ \t\]*(\[^\;\" \]+)\[ \t\]*;" $line dum key1]} {
						set cellarray(temperature) $key1
					}
					set line [gets $fin]
				}
			} elseif {[regexp "^\[ \t\]*capacitance_unit_in_farad\[ \t\]*\:\[ \t\]*\[\"\]*\[ \t\]*(\[^;\" \]+)\[ \t\]*\[\"\]*\[ \t\]*;" $line dum key1]} {
				set cellarray(capacitance_load_unit) $key1
			} elseif {[regexp "^\[ \t\]*time_unit_in_second\[ \t\]*\:\[ \t\]*\[\"\]*\[ \t\]*(\[^;\" \]+)\[ \t\]*\[\"\]*\[ \t\]*;" $line dum key1]} {
				set cellarray(time_unit) $key1
			} elseif {[regexp "^\[ \t\]*voltage_unit_in_volt\[ \t\]*\:\[ \t\]*\[\"\]*\[ \t\]*(\[^;\" \]+)\[ \t\]*\[\"\]*\[ \t\]*;" $line dum key1]} {
				set cellarray(voltage_unit) $key1
			} elseif {[regexp "^\[ \t\]*timing\[ \t\]*\\\(\[ \t\]*\S*\[ \t\]*\\\)" $line dum key1]} {
				set in_timing 1
				set timing_data "0"
			} elseif {[regexp "^\[ \t\]*related_pin\[ \t\]*:\[ \t\]*\[\"\]*\[ \t\]*(\[^;\" \]+)\[ \t\]*\[\"\]*\[ \t\]*;" $line dum key1]} {
				set related_pin $key1
			} elseif {[regexp "^\[ \t\]*sense\[ \t\]*:\[ \t\]*\[\"\]*\[ \t\]*(\[^;\" \]+)\[ \t\]*\[\"\]*\[ \t\]*;" $line dum key1]} {
				if {[regexp "rising_edge" $line dum key1]} {
					set cellarray(cell,$cellname,pin,$pin,is_rise_edge_triggered_output_pin) "true"
				} elseif {[regexp "falling_edge" $line dum key1]} {
					set cellarray(cell,$cellname,pin,$pin,is_fall_edge_triggered_output_pin) "true"
				}
				set timing_data "1"
			} elseif {[regexp "^\[ \t\]*timing_sense\[ \t\]*:\[ \t\]*\[\"\]*\[ \t\]*(\[^;\" \]+)\[ \t\]*\[\"\]*\[ \t\]*;" $line dum key1]} {
				if {[regexp "rising_edge" $line dum key1]} {
					set cellarray(cell,$cellname,pin,$pin,is_rise_edge_triggered_output_pin) "true"
				} elseif {[regexp "falling_edge" $line dum key1]} {
					set cellarray(cell,$cellname,pin,$pin,is_fall_edge_triggered_output_pin) "true"
				}
				set timing_data "1"
			} elseif {[regexp "^\[ \t\]*type\[ \t\]*:\[ \t\]*\[\"\]*\[ \t\]*(\[^;\" \]+)\[ \t\]*\[\"\]*\[ \t\]*;" $line dum key1]} {
				set type $key1
				set timing_data "1"
			} elseif {[regexp "^\[ \t\]*timing_type\[ \t\]*:\[ \t\]*\[\"\]*\[ \t\]*(\[^;\" \]+)\[ \t\]*\[\"\]*\[ \t\]*;" $line dum key1]} {
				set type $key1
				set timing_data "1"
			} elseif {[regexp "^\[ \t\]*when\[ \t\]*:\[ \t\]*\[\"\]*\[ \t\]*(\[^;\" \]+)\[ \t\]*\[\"\]*\[ \t\]*;" $line dum key1]} {
				set when  $key1
				set timing_data "1"
			} elseif {[regexp "^\[ \t\]*sdf_cond\[ \t\]*:\[ \t\]*\[\"\]*\[ \t\]*(\[^;\" \]+)\[ \t\]*\[\"\]*\[ \t\]*;" $line dum key1]} {
				set sdf_cond  $key1
				set timing_data "1"
			} elseif {[regexp "^\[ \t\]*sensitization\[ \t\]*\{" $line dum key1]} {
				if {[defined -nocase cellmatch($cellname)]} {
					array unset inputs
					array unset outputs
					array unset switching_inputs
					array unset switching_outputs
					array unset non_switching_inputs
					array unset non_switching_outputs
					array unset ports
					set first 1
					set line [gets $fin]
					while {! [eof $fin] && ![regexp "\}" $line dum key1]} {
						set input 1
						if {$first} {
							while {1} {
								if {[regsub "^\[ \t\]*\:" $line {} line]} {
									set input 0
								} elseif {[regsub "^\[ \t\]*\," $line {} line]} {
								} elseif {[regexp "^\[ \t\]*\;" $line dum key1]} {
									break
								} elseif {[regexp "(\[^ \t\,\:\]+)" $line dum key1]} {
									regsub "\[^ \t\,\:\]+" $line {} line
									lappend ports $key1
									if {$input} {
										set inputs($key1) 1
									} else {
										set outputs($key1) 1
										set output $key1
									}
								}
							}
							set first 0
						} else {
							set i 0
							while {$i < [llength $ports]} {
								if {[regsub "^\[ \t\]*\:" $line {} line]} {
									set input 0
								} elseif {[regsub "^\[ \t\]*\," $line {} line]} {
								} elseif {[regexp "^\[ \t\]*\;" $line dum key1]} {
									break
								} elseif {[regexp  "(\[^ \t\,\:\]+)" $line dum key1]} {
									regsub "\[^ \t\,\:\]+" $line {} line
									set port [lindex $ports $i]
									if {$key1 eq "01"} {
										set edge  "r"
										if {$input} {
											set switching_inputs($port) $edge
										} else {
											set switching_outputs($port) $edge
										}
									} elseif {$key1 eq "10"} {
										set edge  "f"
										if {$input} {
											set switching_inputs($port) $edge
										} else {
											set switching_outputs($port) $edge
										}
									} elseif {$key1 eq "0"} {
										if {$input} {
											set non_switching_inputs($port) 0
										} else {
											set non_switching_outputs($port) 0
										}
									} elseif {$key1 eq "1"} {
										if {$input} {
											set non_switching_inputs($port) 1
										} else {
											set non_switching_outputs($port) 1
										}
									} elseif {$key1 eq "f"} {
										set edge  "f"
										if {$input} {
											set switching_inputs($port) $edge
										} else {
											set switching_outputs($port) $edge
										}
									} elseif {$key1 eq "r"} {
										set edge  "r"
										if {$input} {
											set switching_inputs($port) $edge
										} else {
											set switching_outputs($port) $edge
										}
									} elseif {$key1 eq "x"} {
										if {$input} {
											set non_switching_inputs($port) "x"
										} else {
											set non_switching_outputs($port) "x"
										}
									} elseif {$key1 eq "X"} {
										if {$input} {
											set non_switching_inputs($port) "x"
										} else {
											set non_switching_outputs($port) "x"
										}
									} elseif {$key1 eq "*"} {
										if {$input} {
											set non_switching_inputs($port) "*"
										} else {
											set non_switching_outputs($port) "*"
										}
									}
									incr i
								}
							}
							if {$cellname eq  ""} {
								foreach key1 [keys cellmatch] {
									foreach key2 [array names switching_outputs] {
										foreach key3 [array names switching_inputs] {
											set cmd  ""
											foreach key4 [array names non_switching_inputs] {
												append cmd  " $key4=$non_switching_inputs($key4)"
											}
											lappend cellarray(cell,$key1,pin,$key2,sensitization,$key3,edge,$switching_outputs($key2)) $cmd
										}
									}
								}
							} else {
								if {[defined -nocase cellmatch($cellname)]} {
									foreach key2 [array names switching_outputs] {
										foreach key3 [array names switching_inputs] {
											set cmd  ""
											if { [array exists non_switching_inputs] && ([llength [array names non_switching_inputs] ] > 0) } {
												foreach key4 [array names non_switching_inputs] {
													append cmd " $key4=$non_switching_inputs($key4)"
												}
												lappend cellarray(cell,$cellname,pin,$key2,sensitization,$key3,edge,$switching_outputs($key2)) $cmd
											}
										}
									}
									undef switching_inputs
									undef switching_outputs
									undef non_switching_inputs
								}
							}
						}
						set line [gets $fin]
					}
				}
			} elseif {[regexp "^\[ \t\]*ff\[ \t\]*\{" $line dum key1]} {
				#\}
				if {[defined -nocase cellmatch($cellname)]} {
					#convert ff into sensitization
				}
				#\{
			} elseif {[regexp "^\[ \t\]*\}\[ \t\]*$" $line dum key1]} {
				if {$in_timing && $timing_data} {
					lappend cellarray(cell,$cellname,pin,$pin,timing,$related_pin,sense) $sense
					lappend cellarray(cell,$cellname,pin,$pin,timing,$related_pin,type) $type
					lappend cellarray(cell,$cellname,pin,$pin,timing,$related_pin,when) $when
					lappend cellarray(cell,$cellname,pin,$pin,timing,$related_pin,sdf_cond) $sdf_cond
					set in_timing 0
					set timing_data "0"
					set sense  ""
					set type ""
					set when  ""
					set sdf_cond  ""
				}
			}
		}
		if { [defined -nocase cellarray(cell,$cellname,output_list)] } {
			foreach pin $cellarray(cell,$cellname,output_list) {
				foreach mpin [lsearch -all -glob -inline $cellarray(cell,$cellname,output_list) "${pin}*"] {
					if { [string compare $mpin $pin] != 0 } {
						set cellarray(cell,$cellname,pin,$pin,comp_output) $mpin
						set cellarray(cell,$cellname,pin,$mpin,comp_output) $pin
					}
				}
			}
		}
		puts "  Done Reading Synopsys Liberty file: $file\n"
		if { [string compare $cargs(-array_name) ""] == 0  } {
			return $cellarray
		}
	}
}
define_myproc_attributes read_cell_data \
	-info "read the lib/db cell data " \
	-define_args { \
		{-library "library file to read" string string required}
	{-cell "name of cell to gather attributes for" string string optional}
	{-array_name "array to store cell data" string string optional}
	{-debug "debug messages" "" boolean optional}
}


proc read_db_cell_data { args } {
	global __procs
	global __scriptdir

	set cargs(-pt_submit) ""
	set cargs(-pt_exec) "pt_shell -f"
	set cargs(-cell) ""
	set cargs(-meas_dir) "./"
	set cargs(-array_name) ""
	set cargs(-db) ""
	set cargs(-library) ""
	set cargs(-pwd) "./"
	set cargs(-scripts_dir) ""

	if { [parse_myproc_arguments -args $args cargs] eq "0"} {
		return 0
	}
	if { ($cargs(-library) eq "") && ($cargs(-db) eq "") } {
		puts "Error: missing -db or -library"
		return 0
	}

	if {[string compare $cargs(-array_name) ""] != 0 } {
		upvar $cargs(-array_name) cellarray
	}

	set pwd [pwd]
	set pwd [string trim $pwd]

	if { $cargs(-scripts_dir) eq "" } {
		if  { [info exists __scriptdir] } {
			set cargs(-scripts_dir) "$__scriptdir"
		} else {
			set cargs(-scripts_dir) "."
		}
	}

	if { $cargs(-tmplt_dir) eq "" } {
		set cargs(-tmplt_dir) "."
	}

	if { ![regexp "^\[ \t]*\/" $cargs(-scripts_dir)] } {
		set cargs(-scripts_dir) "$cargs(-pwd)/$cargs(-scripts_dir)"
	}
	if { ![regexp "^\[ \t]*\/" $cargs(-db)] } {
		set cargs(-db) "$cargs(-pwd)/$cargs(-db)"
	}
	if { ![regexp "^\[ \t]*\/" $cargs(-library)] } {
		set cargs(-library) "$cargs(-pwd)/$cargs(-library)"
	}


	foreach cell [split [regsub -all "\[ \t\]+" [string trim [join $cargs(-cell)]] { }]] {
		set cell [string trim $cell]
		if { [llength [glob -nocomplain $cargs(-tmplt_dir)/${cell}.lib_tmplt]] <= 0}  {
			set FOUT [open "_read_db_data.pt" w]
			puts $FOUT "set __scriptdir $cargs(-scripts_dir)"
			puts $FOUT "append auto_path \" \$__scriptdir/tbcload\""
			puts $FOUT "package require tbcload"
			puts $FOUT "if \{ \[file exists $cargs(-scripts_dir)/general_aocv.tcl\] \} \{"
			puts $FOUT "source $cargs(-scripts_dir)/general_aocv.tcl"
			puts $FOUT "\} else \{"
			puts $FOUT "puts \"Error: missing general_aocv.tcl file(Please place all AOCV tcl files in the same directory)\""
			puts $FOUT "exit"
			puts $FOUT "\}"
			puts $FOUT "if \{ \[file exists $cargs(-scripts_dir)/read_db_data.tcl\] \} \{"
			puts $FOUT "source $cargs(-scripts_dir)/read_db_data.tcl"
			puts $FOUT "\} elseif \{ \[file exists $cargs(-scripts_dir)/read_db_data.tbc\] \} \{"
			puts $FOUT "source $cargs(-scripts_dir)/read_db_data.tbc"
			puts $FOUT "\} else \{"
			puts $FOUT "puts \"Error: missing read_db_data.tbc/.tcl file(Please place all AOCV tcl files in the same directory)\""
			puts $FOUT "exit"
			puts $FOUT "\}"
			puts $FOUT "if \{ \[info procs ::read_db_data\] ne \"\"\} \{"
			if { $cargs(-db) ne "" } {
				puts $FOUT "read_db_data -cells \[join $cell\] -db \"$cargs(-db)\" -tmplt_dir $cargs(-tmplt_dir) -pwd $cargs(-pwd)"
			} elseif { $cargs(-library) ne "" } {
				puts $FOUT "read_db_data -cells \[join $cell\] -library \"$cargs(-library)\" -tmplt_dir $cargs(-tmplt_dir) -pwd $cargs(-pwd)"
			}
			puts $FOUT "\} else \{"
			puts $FOUT "   puts \"Error: unable to find TCL proc: read_db_data, Please check installation setup\""
			puts $FOUT "\}"
			puts $FOUT "quit\n"
			close $FOUT
			if { [file exists "$cargs(-db)"] || [file exists "$cargs(-library)"]} {
				if { [file exists "$cargs(-db)"] } {
					puts "Gathering attributes from $cargs(-db)"
				} elseif { [file exists "$cargs(-library)"]} {
					puts "Gathering attributes from $cargs(-library)"
				}
				if { [file exists _read_db_data.pt] } {
					if { $cargs(-pt_submit) ne "" } {
						set FPT [open "__runpt" w]
						puts $FPT "set errorvar \"\""
						puts $FPT "catch \{ exec $cargs(-pt_exec) _read_db_data.pt > _read_db_data.log\} errorvar"
						puts $FPT "puts $errorvar"
						close $FPT
						catch "exec [join $cargs(-pt_submit)] __runpt" errorvar
						puts $errorvar
					} else {
						catch "exec $cargs(-pt_exec) _read_db_data.pt > _read_db_data.log" errorvar
						puts $errorvar
					}
				}
				if { [file exists "_read_db_data.log"] } {
					set fin [open "_read_db_data.log"]
					while {1 } {
						set line [gets $fin]
						if { [eof $fin]  } {
							close $fin
							break
						}
						if { [regexp "^\[ \\t\]*Fatal:" $line] } {
							puts $line
						} elseif { [regexp "^\[ \t\]*Warning:" $line] } {
							puts $line
						} elseif { [regexp "^\[ \t\]*Error:" $line] } {
							puts $line
						} elseif { [regexp "^\[ \t\]*Info:" $line] } {
							puts $line
						} elseif { [regexp "^\[ \t\]*Information:" $line] } {
							puts $line
						} elseif { [regexp "The tool has just encountered a fatal error:" $line] } {
							puts $line
						} elseif { [regexp "Release = " $line] } {
							puts $line
						}
					}
				}
			}
		}
		if { $cargs(-db) ne "" } {
			puts "Done Gathering attributes from $cargs(-db) for cell: $cell"
		} elseif { $cargs(-library) ne "" } {
			puts "Done Gathering attributes from $cargs(-library) for cell: $cell"
		}
		if { [file exists $cargs(-tmplt_dir)/${cell}.lib_tmplt] } {
			read_cell_data -library $cargs(-tmplt_dir)/${cell}.lib_tmplt -cell $cell -array_name cellarray
		} else {
			puts "Warning: $cargs(-tmplt_dir)/${cell}.lib_tmplt was not created"
		}

	}
}
define_myproc_attributes read_db_cell_data \
	-info "read db cell file and print out lib cell data" \
	-define_args \
	{
		{-scripts_dir "scripts dir" string string optional}
	{-array_name "Array name for storing data" string string optional}
	{-cell "cell_list" cell_list string_list optional}
	{-tmplt_dir "tmplt dir where .lib TMPL is stored " dir string optional}
	{-db "DB file" file string optional}
	{-library "Library file" file string optional}
	{-pt_exec "PT shell exec script" string string optional}
	{-pt_submit "PT submit exec script" string string optional}
	{-pwd "PWD dir " dir string optional}
}


proc read_db_data  { args } {
	global link_path
	global search_path
	set cargs(-db) ""
	set cargs(-library) ""
	set cargs(-tmplt_dir) "./"
	set cargs(-cells) "*"
	set cargs(-pwd) "./"
	set cargs(-debug) 0

	parse_myproc_arguments -args $args cargs

	if { $cargs(-debug) } {
		set debug "-debug"
	} else {
		set debug ""
	}

	if { $cargs(-db) ne "" } {
		foreach db [split [regsub -all "\[ \t\]+" [string trim [join $cargs(-db)]] { }]] {
			if  { [regexp "^\[ \]*\/" $db]} {
				read_db $db
				append link_path " $db"
			} else {
				read_db $cargs(-pwd)/$db
				append link_path " $cargs(-pwd)/$db"
			}
		}
	} elseif { $cargs(-library) ne "" } {
		foreach db [split [regsub -all "\[ \t\]+" [string trim [join $cargs(-library)]] { }]] {
			if  { [regexp "^\[ \]*\/" $db]} {
				read_lib $db
				append link_path " [file rootname $db]"
			} else {
				read_lib $cargs(-pwd)/$db
				append link_path " [file rootname $db]"
			}
		}
	} else {
		puts "Error: missing -db/-library cmd line option"
		return 0
	}

	append search_path " . *"

	set libs [get_lib *]
	set lib_cells {}
	foreach_in_collection lib $libs  {
		append_to_collection lib_cells [get_lib_cells [get_attribute -quiet $lib full_name]/$cargs(-cells) -quiet]
	}
	if { [sizeof_collection $lib_cells] < 1 } {
		puts "Error: no cells in library([get_attribute $lib full_name]) matching cells: $cargs(-cells)"
		return 0
	}

	foreach_in_collection lib_cell $lib_cells {
		set lib_cell_name [get_attribute -quiet $lib_cell base_name]
		puts "   Reading attributes of $lib_cell_name"
		set lib [get_lib -of $lib_cell]
		if {! [file isdirectory $cargs(-tmplt_dir)] } {
			file mkdir $cargs(-tmplt_dir)
		}
		puts "Info: creating lib_tmplt: $cargs(-tmplt_dir)/${lib_cell_name}.lib_tmplt"
		set fout [open "$cargs(-tmplt_dir)/${lib_cell_name}.lib_tmplt"  {w}]
		puts $fout "library (\"[get_attribute -quiet $lib_cell full_name]\") \{"
		foreach attr [list capacitance_unit_in_farad time_unit_in_second voltage_unit_in_volt is_sequential is_rise_edge_triggered is_fall_edge_triggered function_id user_function_class ] {
			set attr_value [get_attribute -quiet $lib $attr]
			if { [string compare $attr_value ""] != 0 } {
				puts $fout "   $attr : \"$attr_value\" ;"
				#puts $fout "\'$attr\'=>\'$attr_value\',"
			}
		}
		unset -nocomplain inout_pin_list
		unset -nocomplain output_pin_list
		unset -nocomplain input_pin_list
		unset -nocomplain pin_list
		unset -nocomplain ipin_list
		unset -nocomplain opin_list
		# lib cell attributes
		#time_unit_in_second
		#voltage_unit_in_volt
		set foutv [open __celltest.v w]
		puts -nonewline $foutv "module ${lib_cell_name}_test ("
		set first 1;
		foreach_in_collection lib_pin [get_lib_pins -quiet -of $lib_cell] {
			set lib_pin_name [get_attribute -quiet $lib_pin base_name]
			if  {[string compare [get_attribute -quiet $lib_pin direction] "internal" ] == 0 } {
			} else {
				if {$first} {
					puts -nonewline $foutv " \\$lib_pin_name"
					set first 0
				} else {
					puts -nonewline $foutv  " , \\$lib_pin_name"
				}
				if  {[string compare [get_attribute -quiet $lib_pin direction] "inout" ] == 0 } {
					lappend ipin_list $lib_pin
					lappend opin_list $lib_pin
					lappend inout_pin_list  "$lib_pin_name"
					lappend pin_list  "$lib_pin_name"
				} elseif  {[string compare [get_attribute -quiet $lib_pin direction] "out" ] == 0 } {
					lappend output_pin_list  "$lib_pin_name"
					lappend opin_list $lib_pin
					lappend pin_list  "$lib_pin_name"
				} elseif  {[string compare [get_attribute -quiet $lib_pin direction] "in" ] == 0 } {
					lappend ipin_list $lib_pin
					lappend input_pin_list  "$lib_pin_name"
					lappend pin_list  "$lib_pin_name"
				}
			}
		}
		puts $foutv " );"
		# generate verilog netlist of one cell
		if {[info exists "input_pin_list"]} {
			foreach pin $input_pin_list {
				puts $foutv "  input \\$pin ;"
			}
		}
		if {[info exists "output_pin_list"]} {
			foreach pin $output_pin_list {
				puts $foutv "  output \\$pin ;"
			}
		}
		if {[info exists "inout_pin_list"]} {
			foreach pin $inout_pin_list {
				puts $foutv "  inout \\$pin ;"
			}
		}
		puts -nonewline $foutv "$lib_cell_name Xtest ("
		set first 1
		if { [info exists pin_list] } {
			foreach pin $pin_list {
				if {$first} {
					puts -nonewline $foutv " \."
					puts -nonewline $foutv "\\$pin ( \\$\{pin\} )"
					set first 0
				} else {
					puts -nonewline $foutv ",  \."
					puts -nonewline $foutv "\\$pin ( \\$\{pin\} )"
				}
			}
		}
		puts $foutv " );"
		puts $foutv "endmodule"
		close $foutv
		read_verilog __celltest.v
		link_design

		# design attributes

		set design [get_design]
		foreach attr [list process_max temperature_max voltage_max rc_slew_derate_from_library rc_slew_upper_threshold_pct_rise rc_slew_lower_threshold_pct_rise rc_slew_upper_threshold_pct_fall rc_slew_lower_threshold_pct_fall rc_input_threshold_pct_fall rc_input_threshold_pct_rise rc_output_threshold_pct_fall rc_output_threshold_pct_rise ] {
			set attr_value [get_attribute -quiet $design $attr]
			if { [string compare $attr_value ""] != 0 } {
				regsub "^rc_" $attr {} attr
				puts $fout "   $attr : \"$attr_value\" ;"
			}
		}
		puts $fout "   cell (\"$lib_cell_name\") \{"
		foreach attr [list slew_lower_threshold_pct_rise slew_upper_threshold_pct_rise max_transition min_transition max_capacitance min_capacitance max_process max_temperature max_voltage slew_derate_from_library] {
			set attr_value [get_attribute -quiet $lib_cell $attr]
			if { [string compare $attr_value ""] != 0 } {
				puts $fout "      $attr : \"$attr_value\" ;"
				#puts $fout "\'$attr\'=>\'$attr_value\',"
			}
		}
		foreach_in_collection lib_pin [get_lib_pins -quiet -of $lib_cell] {

			set lib_pin_name [get_attribute -quiet $lib_pin base_name]
			puts "      Reading attributes of pin: $lib_pin_name"
			# pin attributes
			puts $fout "      pin (\"$lib_pin_name\") \{"
			foreach attr [list original_pin direction pin_direction capacitance max_transition min_transition max_fanout min_fanout load_of_pin_capitance max_capacitance min_capacitance pin_capacitance pin_capacitance_max_fall pin_capacitance_min_fall pin_capacitance_max_rise pin_capacitance_min_rise is_clock_pin is_async_pin is_clear_pin is_preset_pin is_mux_select_pin is_unbuffered_pin is_three_state_enable_pin is_three_state_output_pin function rc_slew_upper_threshold_pct_rise rc_slew_lower_threshold_pct_rise rc_slew_upper_threshold_pct_fall rc_slew_lower_threshold_pct_fall rc_input_threshold_pct_fall rc_input_threshold_pct_rise rc_output_threshold_pct_fall rc_output_threshold_pct_rise rc_slew_derate_from_library is_rise_edge_triggered_clock_pin is_rise_edge_triggered_data_pin is_fall_edge_triggered_clock_pin is_fall_edge_triggered_data_pin] {

				set attr_value [get_attribute -quiet $lib_pin $attr]
				if { [string compare $attr_value ""] != 0 } {
					#puts $fout "\'cell\'=>  \{ '$lib_cell_name' =>  \{ \'$lib_pin_name\' => \{\'$attr\'=> \'$attr_value\'\}\}\},";
					puts $fout "         $attr : \"$attr_value\" ;"
				}
			}
			# get arcs to this pin.
			foreach_in_collection ga [get_timing_arc -to [get_pin -quiet -of [all_instances -hier $lib_cell_name] -filter "lib_pin_name == [get_attribute -quiet $lib_pin base_name]"]] {
				# get sdf_cond, sense, when, mode of each arc
				puts $fout "         timing () \{"
				foreach attr [list sense when mode sdf_cond] {
					set attr_value [get_attribute -quiet $ga $attr]
					if { [string compare $attr_value ""] != 0 } {
						puts $fout "         $attr : \"$attr_value\" ;"
					}
				}
				foreach attr [list from_pin] {
					set attr_value [get_attribute -quiet [get_attribute -quiet $ga $attr] lib_pin_name]
					if { [string compare $attr_value ""] != 0 } {
						puts $fout "         related_pin : \"$attr_value\" ;"
					}
				}
				puts $fout "         # end of timing"
				puts $fout "         \}"
			}
			puts $fout "      # end of pin"
			puts $fout "      \}"
		}

		#operating_condition_max
		#operating_condition_min
		# borrowed from Robert landy's TCL code
		set cell [all_instances -hier $lib_cell_name]
		if { [info exists "ipin_list"] && [info exists "opin_list"]} {
			unset -nocomplain ilist
			unset -nocomplain olist
			puts $fout "      sensitization \{"
			foreach lib_ipin $ipin_list {
				lappend ilist [get_attribute -quiet $lib_ipin base_name]
			}
			foreach lib_opin $opin_list {
				lappend olist [get_attribute -quiet $lib_opin base_name]
			}
			puts -nonewline $fout "       "
			puts $fout "[write_sensitization_entry -inputs_list ilist -outputs_list olist -header] ;"
			set saved_states {}
			foreach lib_ipin $ipin_list {
				set ipin_name [get_attribute -quiet $lib_ipin base_name]
				set ipin [get_pin -quiet -of $cell -filter "lib_pin_name == $ipin_name"]
				foreach lib_opin $opin_list {
					set opin_name [get_attribute -quiet $lib_opin base_name]
					set opin [get_pin -quiet -of $cell -filter "lib_pin_name == $opin_name"]
					set gta [get_timing_arc -from $ipin -to $opin]
					set pflag 0
					set nflag 0
					set uflag 0
					foreach_in_collection ga $gta {
						set sense [get_attribute -quiet $ga sense]
						set type [get_attribute -quiet $ga type]
						set sdf_cond [get_attribute -quiet $ga sdf_cond]
						set when     [get_attribute -quiet $ga when]
						puts "         Arc Found: $ipin_name -> $opin_name Sense: $sense Sdf_cond: $sdf_cond When: $when"
						if {[string compare $sense "clear_low"] == 0} {
							if { $when ne "" } {
								set gsvs [get_sensitization_from_when_cond $when]
							} else {
								set gsvs [list "[get_sensitization_vector -from $ipin -to $opin -from_transition fall -to_transition fall]"]
							}
							foreach gsv $gsvs {
								unset -nocomplain state
								regsub "rise" $gsv "r" gsv
								regsub "fall" $gsv "f" gsv
								if { $cargs(-debug) } {
									puts "Debug: GSV: $gsv"
								}
								if { [string compare $gsv ""] != 0 } {
									array set state [string trimleft $gsv]
								}
								set state($ipin_name) "f"
								set state($opin_name) "f"
								set states {}
								set states [expand_states -new_state state -inputs_list ilist $debug]
								foreach key1 $states {
									array set key2 $key1
									if { ![is_state_saved -saved_states saved_states -new_state key2 $debug]} {
										puts -nonewline $fout "       "
										puts $fout "[write_sensitization_entry -inputs_list ilist -outputs_list olist -state key2] ;"
										lappend saved_states [array get key2]
									}
								}
							}
						} elseif {[string compare $sense "clear_high"] == 0} {
							if { $when ne "" } {
								set gsvs [get_sensitization_from_when_cond $when]
							} else {
								set gsvs [list "[get_sensitization_vector -from $ipin -to $opin -from_transition rise -to_transition fall]"]
							}
							foreach gsv $gsvs {
								unset -nocomplain state
								regsub "rise" $gsv "r" gsv
								regsub "fall" $gsv "f" gsv
								if { [string compare $gsv ""] != 0 } {
									array set state [string trimleft $gsv]
								}
								set state($ipin_name) "r"
								set state($opin_name) "f"
								set states {}
								set states [expand_states -new_state state -inputs_list ilist $debug]
								foreach key1 $states {
									array set key2 $key1
									if { ![is_state_saved -saved_states saved_states -new_state key2 $debug]} {
										puts -nonewline $fout "       "
										puts $fout "[write_sensitization_entry -inputs_list ilist -outputs_list olist -state key2] ;"
										lappend saved_states [array get key2]
									}
								}
							}
						} elseif {[string compare $sense "fall_to_fall"] == 0} {
							if { $when ne "" } {
								set gsvs [get_sensitization_from_when_cond $when]
							} else {
								set gsvs [list "[get_sensitization_vector -from $ipin -to $opin -from_transition fall -to_transition fall]"]
							}
							foreach gsv $gsvs {
								unset -nocomplain state
								regsub "rise" $gsv "r" gsv
								regsub "fall" $gsv "f" gsv
								if { [string compare $gsv ""] != 0 } {
									array set state [string trimleft $gsv]
								}
								set state($ipin_name) "f"
								set state($opin_name) "f"
								set states {}
								set states [expand_states -new_state state -inputs_list ilist $debug]
								foreach key1 $states {
									array set key2 $key1
									if { ![is_state_saved -saved_states saved_states -new_state key2 $debug]} {
										puts -nonewline $fout "       "
										puts $fout "[write_sensitization_entry -inputs_list ilist -outputs_list olist -state key2] ;"
										lappend saved_states [array get key2]
									}
								}
							}
						} elseif {[string compare $sense "rise_to_rise"] == 0} {
							if { $when ne "" } {
								set gsvs [get_sensitization_from_when_cond $when]
							} else {
								set gsvs [list "[get_sensitization_vector -from $ipin -to $opin -from_transition rise -to_transition rise]"]
							}
							foreach gsv $gsvs {
								unset -nocomplain state
								regsub "rise" $gsv "r" gsv
								regsub "fall" $gsv "f" gsv
								if { [string compare $gsv ""] != 0 } {
									array set state [string trimleft $gsv]
								}
								set state($ipin_name) "r"
								set state($opin_name) "r"
								set states {}
								set states [expand_states -new_state state -inputs_list ilist $debug]
								foreach key1 $states {
									array set key2 $key1
									if { ![is_state_saved -saved_states saved_states -new_state key2 $debug]} {
										puts -nonewline $fout "       "
										puts $fout "[write_sensitization_entry -inputs_list ilist -outputs_list olist -state key2] ;"
										lappend saved_states [array get key2]
									}
								}
							}
						} elseif {[string compare $sense "fall_to_rise"] == 0} {
							if { $when ne "" } {
								set gsvs [get_sensitization_from_when_cond $when]
							} else {
								set gsvs [list "[get_sensitization_vector -from $ipin -to $opin -from_transition fall -to_transition rise]"]
							}
							foreach gsv $gsvs {
								unset -nocomplain state
								regsub "rise" $gsv "r" gsv
								regsub "fall" $gsv "f" gsv
								if { [string compare $gsv ""] != 0 } {
									array set state [string trimleft $gsv]
								}
								set state($ipin_name) "f"
								set state($opin_name) "r"
								set states {}
								set states [expand_states -new_state state -inputs_list ilist $debug]
								foreach key1 $states {
									array set key2 $key1
									if { ![is_state_saved -saved_states saved_states -new_state key2 $debug]} {
										puts -nonewline $fout "       "
										puts $fout "[write_sensitization_entry -inputs_list ilist -outputs_list olist -state key2] ;"
										lappend saved_states [array get key2]
									}
								}
							}
						} elseif {[string compare $sense "rise_to_fall"] == 0} {
							if { $when ne "" } {
								set gsvs [get_sensitization_from_when_cond $when]
							} else {
								set gsvs [list "[get_sensitization_vector -from $ipin -to $opin -from_transition rise -to_transition fall]"]
							}
							foreach gsv $gsvs {
								unset -nocomplain state
								regsub "rise" $gsv "r" gsv
								regsub "fall" $gsv "f" gsv
								if { [string compare $gsv ""] != 0 } {
									array set state [string trimleft $gsv]
								}
								set state($ipin_name) "r"
								set state($opin_name) "f"
								set states {}
								set states [expand_states -new_state state -inputs_list ilist $debug]
								foreach key1 $states {
									array set key2 $key1
									if { ![is_state_saved -saved_states saved_states -new_state key2 $debug]} {
										puts -nonewline $fout "       "
										puts $fout "[write_sensitization_entry -inputs_list ilist -outputs_list olist -state key2] ;"
										lappend saved_states [array get key2]
									}
								}
							}
						} elseif {[string compare $sense "disable_low"] == 0} {
							puts "DISABLE_LOW: NOT SUPPORTED"
						} elseif {[string compare $sense "disable_high"] == 0} {
							puts "DISABLE_HIGH: NOT SUPPORTED"
						} elseif {[string compare $sense "enable_low"] == 0} {
							if { $when ne "" } {
								set gsvs [get_sensitization_from_when_cond $when]
							} else {
								set gsvs [list "[get_sensitization_vector -from $ipin -to $opin -from_transition fall -to_transition fall]"]
							}
							foreach gsv $gsvs {
								unset -nocomplain state
								regsub -all "fall" $gsv "f" gsv
								if { [string compare $gsv ""] != 0 } {
									array set state [string trimleft $gsv]
								}
								set state($ipin_name) "f"
								set state($opin_name) "f"
								set states {}
								set states [expand_states -new_state state -inputs_list ilist $debug]
								foreach key1 $states {
									array set key2 $key1
									if { ![is_state_saved -saved_states saved_states -new_state key2 $debug]} {
										puts -nonewline $fout "       "
										puts $fout "[write_sensitization_entry -inputs_list ilist -outputs_list olist -state key2] ;"
										lappend saved_states [array get key2]
									}
								}
							}
							if { $when ne "" } {
								set gsvs [get_sensitization_from_when_cond $when]
							} else {
								set gsvs [list "[get_sensitization_vector -from $ipin -to $opin -from_transition fall -to_transition rise]"]
							}
							foreach gsv $gsvs {
								unset -nocomplain state
								regsub "fall" $gsv "f" gsv
								regsub "rise" $gsv "r" gsv
								if { [string compare $gsv ""] != 0 } {
									array set state [string trimleft $gsv]
								}
								set state($ipin_name) "f"
								set state($opin_name) "r"
								set states {}
								set states [expand_states -new_state state -inputs_list ilist $debug]
								foreach key1 $states {
									array set key2 $key1
									if { ![is_state_saved -saved_states saved_states -new_state key2 $debug]} {
										puts -nonewline $fout "       "
										puts $fout "[write_sensitization_entry -inputs_list ilist -outputs_list olist -state key2] ;"
										lappend saved_states [array get key2]
									}
								}
							}
						} elseif {[string compare $sense "enable_high"] == 0} {
							if { $when ne "" } {
								set gsvs [get_sensitization_from_when_cond $when]
							} else {
								set gsvs [list "[get_sensitization_vector -from $ipin -to $opin -from_transition rise -to_transition fall]"]
							}
							foreach gsv $gsvs {
								unset -nocomplain state
								regsub "rise" $gsv "r" gsv
								regsub "fall" $gsv "f" gsv
								if { [string compare $gsv ""] != 0 } {
									array set state [string trimleft $gsv]
								}
								set state($ipin_name) "r"
								set state($opin_name) "f"
								set states {}
								set states [expand_states -new_state state -inputs_list ilist $debug]
								foreach key1 $states {
									array set key2 $key1
									if { ![is_state_saved -saved_states saved_states -new_state key2 $debug]} {
										puts -nonewline $fout "       "
										puts $fout "[write_sensitization_entry -inputs_list ilist -outputs_list olist -state key2] ;"
										lappend saved_states [array get key2]
									}
								}
							}
							if { $when ne "" } {
								set gsvs [get_sensitization_from_when_cond $when]
							} else {
								set gsvs [list "[get_sensitization_vector -from $ipin -to $opin -from_transition rise -to_transition rise]"]
							}
							foreach gsv $gsvs {
								unset -nocomplain state
								regsub -all "rise" $gsv "r" gsv
								if { [string compare $gsv ""] != 0 } {
									array set state [string trimleft $gsv]
								}
								set state($ipin_name) "r"
								set state($opin_name) "r"
								set states {}
								set states [expand_states -new_state state -inputs_list ilist $debug]
								foreach key1 $states {
									array set key2 $key1
									if { ![is_state_saved -saved_states saved_states -new_state key2 $debug]} {
										puts -nonewline $fout "       "
										puts $fout "[write_sensitization_entry -inputs_list ilist -outputs_list olist -state key2] ;"
										lappend saved_states [array get key2]
									}
								}
							}
						} elseif {[string compare $sense "preset_high"] == 0} {
							if { $when ne "" } {
								set gsvs [get_sensitization_from_when_cond $when]
							} else {
								set gsvs [list "[get_sensitization_vector -from $ipin -to $opin -from_transition rise -to_transition rise]"]
							}
							foreach gsv $gsvs {
								unset -nocomplain state
								regsub "rise" $gsv "r" gsv
								regsub "fall" $gsv "f" gsv
								if { [string compare $gsv ""] != 0 } {
									array set state [string trimleft $gsv]
								}
								set state($ipin_name) "r"
								set state($opin_name) "r"
								set states {}
								set states [expand_states -new_state state -inputs_list ilist $debug]
								foreach key1 $states {
									array set key2 $key1
									if { ![is_state_saved -saved_states saved_states -new_state key2 $debug]} {
										puts -nonewline $fout "       "
										puts $fout "[write_sensitization_entry -inputs_list ilist -outputs_list olist -state key2] ;"
										lappend saved_states [array get key2]
									}
								}
							}
						} elseif {[string compare $sense "preset_low"] == 0} {
							if { $when ne "" } {
								set gsvs [get_sensitization_from_when_cond $when]
							} else {
								set gsvs [list "[get_sensitization_vector -from $ipin -to $opin -from_transition fall -to_transition rise]"]
							}
							foreach gsv $gsvs {
								unset -nocomplain state
								regsub "rise" $gsv "r" gsv
								regsub "fall" $gsv "f" gsv
								if { [string compare $gsv ""] != 0 } {
									array set state [string trimleft $gsv]
								}
								set state($ipin_name) "f"
								set state($opin_name) "r"
								set states {}
								set states [expand_states -new_state state -inputs_list ilist $debug]
								foreach key1 $states {
									array set key2 $key1
									if { ![is_state_saved -saved_states saved_states -new_state key2 $debug]} {
										puts -nonewline $fout "       "
										puts $fout "[write_sensitization_entry -inputs_list ilist -outputs_list olist -state key2] ;"
										lappend saved_states [array get key2]
									}
								}
							}
						} elseif {[string compare $sense "rising_edge"] == 0} {
							if { $when ne "" } {
								set gsvs [get_sensitization_from_when_cond $when]
							} else {
								set gsvs [list "[get_sensitization_vector -from $ipin -to $opin -from_transition rise -to_transition rise]"]
							}
							foreach gsv $gsvs {
								unset -nocomplain state
								regsub "rise" $gsv "r" gsv
								regsub "fall" $gsv "f" gsv
								if { [string compare $gsv ""] != 0 } {
									array set state [string trimleft $gsv]
								}
								set state($ipin_name) "r"
								set state($opin_name) "r"
								set states {}
								set states [expand_states -new_state state -inputs_list ilist $debug]
								foreach key1 $states {
									array set key2 $key1
									if { ![is_state_saved -saved_states saved_states -new_state key2 $debug]} {
										puts -nonewline $fout "       "
										puts $fout "[write_sensitization_entry -inputs_list ilist -outputs_list olist -state key2] ;"
										lappend saved_states [array get key2]
									}
								}
							}
							if { $when ne "" } {
								set gsvs [get_sensitization_from_when_cond $when]
							} else {
								set gsvs [list "[get_sensitization_vector -from $ipin -to $opin -from_transition rise -to_transition fall]"]
							}
							foreach gsv $gsvs {
								unset -nocomplain state
								regsub "rise" $gsv "r" gsv
								regsub "fall" $gsv "f" gsv
								if { [string compare $gsv ""] != 0 } {
									array set state [string trimleft $gsv]
								}
								set state($ipin_name) "r"
								set state($opin_name) "f"
								set states {}
								set states [expand_states -new_state state -inputs_list ilist $debug]
								foreach key1 $states {
									array set key2 $key1
									if { ![is_state_saved -saved_states saved_states -new_state key2 $debug]} {
										puts -nonewline $fout "       "
										puts $fout "[write_sensitization_entry -inputs_list ilist -outputs_list olist -state key2] ;"
										lappend saved_states [array get key2]
									}
								}
							}
						} elseif {[string compare $sense "falling_edge"] == 0} {
							if { $when ne "" } {
								set gsvs [get_sensitization_from_when_cond $when]
							} else {
								set gsvs [list "[get_sensitization_vector -from $ipin -to $opin -from_transition fall -to_transition rise]"]
							}
							foreach gsv $gsvs {
								unset -nocomplain state
								regsub "rise" $gsv "r" gsv
								regsub "fall" $gsv "f" gsv
								if { [string compare $gsv ""] != 0 } {
									array set state [string trimleft $gsv]
								}
								set state($ipin_name) "f"
								set state($opin_name) "r"
								set states {}
								set states [expand_states -new_state state -inputs_list ilist $debug]
								foreach key1 $states {
									array set key2 $key1
									if { ![is_state_saved -saved_states saved_states -new_state key2 $debug]} {
										puts -nonewline $fout "       "
										puts $fout "[write_sensitization_entry -inputs_list ilist -outputs_list olist -state key2] ;"
										lappend saved_states [array get key2]
									}
								}
							}
							if { $when ne "" } {
								set gsvs [get_sensitization_from_when_cond $when]
							} else {
								set gsvs [list "[get_sensitization_vector -from $ipin -to $opin -from_transition fall -to_transition fall]"]
							}
							foreach gsv $gsvs {
								unset -nocomplain state
								regsub "rise" $gsv "r" gsv
								regsub "fall" $gsv "f" gsv
								if { [string compare $gsv ""] != 0 } {
									array set state [string trimleft $gsv]
								}
								set state($ipin_name) "f"
								set state($opin_name) "f"
								set states {}
								set states [expand_states -new_state state -inputs_list ilist $debug]
								foreach key1 $states {
									array set key2 $key1
									if { ![is_state_saved -saved_states saved_states -new_state key2 $debug]} {
										puts -nonewline $fout "       "
										puts $fout "[write_sensitization_entry -inputs_list ilist -outputs_list olist -state key2] ;"
										lappend saved_states [array get key2]
									}
								}
							}
						} elseif {[string compare $sense "negative_unate"] == 0} {
							if { $when ne "" } {
								set gsvs [get_sensitization_from_when_cond $when]
							} else {
								set gsvs [list "[get_sensitization_vector -from $ipin -to $opin -from_transition rise -to_transition fall]"]
							}
							foreach gsv $gsvs {
								unset -nocomplain state
								regsub "rise" $gsv "r" gsv
								regsub "fall" $gsv "f" gsv
								if { [string compare $gsv ""] != 0 } {
									array set state [string trimleft $gsv]
								}
								set state($ipin_name) "r"
								set state($opin_name) "f"
								set states [expand_states -new_state state -inputs_list ilist $debug]
								foreach key1 $states {
									array set key2 $key1
									if { ![is_state_saved -saved_states saved_states -new_state key2 $debug]} {
										puts -nonewline $fout "       "
										puts $fout "[write_sensitization_entry -inputs_list ilist -outputs_list olist -state "key2"] ;"
										lappend saved_states [array get key2]
									}
								}
								set state($ipin_name) "f"
								set state($opin_name) "r"
								set states [expand_states -new_state state -inputs_list ilist $debug]
								foreach key1 $states {
									array set key2 $key1
									if { ![is_state_saved -saved_states saved_states -new_state key2 $debug] } {
										puts -nonewline $fout "       "
										puts $fout "[write_sensitization_entry -inputs_list ilist -outputs_list olist -state "key2"] ;"
										lappend saved_states [array get key2]
									}
								}
							}
						} elseif {[string compare $sense "positive_unate"] == 0} {
							if { $when ne "" } {
								set gsvs [get_sensitization_from_when_cond $when]
							} else {
								set gsvs [list "[get_sensitization_vector -from $ipin -to $opin -from_transition rise -to_transition rise]"]
							}
							foreach gsv $gsvs {
								unset -nocomplain state
								regsub "rise" $gsv "r" gsv
								regsub "fall" $gsv "f" gsv
								if { [string compare $gsv ""] != 0 } {
									array set state [string trimleft $gsv]
								}
								set state($ipin_name) "r"
								set state($opin_name) "r"
								set states {}
								set states [expand_states -new_state state -inputs_list ilist $debug]
								foreach key1 $states {
									array set key2 $key1
									if { ![is_state_saved -saved_states saved_states -new_state key2 $debug]} {
										puts -nonewline $fout "       "
										puts $fout "[write_sensitization_entry -inputs_list ilist -outputs_list olist -state key2] ;"
										lappend saved_states [array get key2]
									}
								}
								set state($ipin_name) "f"
								set state($opin_name) "f"
								set states {}
								set states [expand_states -new_state state -inputs_list ilist $debug]
								foreach key1 $states {
									array set key2 $key1
									if { ![is_state_saved -saved_states saved_states -new_state key2 $debug]} {
										puts -nonewline $fout "       "
										puts $fout "[write_sensitization_entry -inputs_list ilist -outputs_list olist -state key2] ;"
										lappend saved_states [array get key2]
									}
								}
							}
						} elseif {[string compare $sense "non_unate"] == 0} {
							if { $when ne "" } {
								set gsvs [get_sensitization_from_when_cond $when]
							} else {
								set gsvs [list "[get_sensitization_vector -from $ipin -to $opin -from_transition rise -to_transition rise]"]
							}
							foreach gsv $gsvs {
								unset -nocomplain state
								regsub "rise" $gsv "r" gsv
								regsub "fall" $gsv "f" gsv
								if { [string compare $gsv ""] != 0 } {
									array set state [string trimleft $gsv]
								}
								set state($ipin_name) "r"
								set state($opin_name) "r"
								set states {}
								set states [expand_states -new_state state -inputs_list ilist $debug]
								foreach key1 $states {
									array set key2 $key1
									if { ![is_state_saved -saved_states saved_states -new_state key2 $debug]} {
										puts -nonewline $fout "       "
										puts $fout "[write_sensitization_entry -inputs_list ilist -outputs_list olist -state key2 $debug] ;"
										lappend saved_states [array get key2]
									}
								}
								set state($ipin_name) "f"
								set state($opin_name) "f"
								set states {}
								set states [expand_states -new_state state -inputs_list ilist $debug]
								foreach key1 $states {
									array set key2 $key1
									if { ![is_state_saved -saved_states saved_states -new_state key2 $debug]} {
										puts -nonewline $fout "       "
										puts $fout "[write_sensitization_entry -inputs_list ilist -outputs_list olist -state key2 $debug] ;"
										lappend saved_states [array get key2]
									}
								}
								set state($ipin_name) "r"
								set state($opin_name) "f"
								set states [expand_states -new_state state -inputs_list ilist $debug]
								foreach key1 $states {
									array set key2 $key1
									if { ![is_state_saved -saved_states saved_states -new_state key2 $debug]} {
										puts -nonewline $fout "       "
										puts -nonewline $fout "       "
										puts $fout "[write_sensitization_entry -inputs_list ilist -outputs_list olist -state key2] ;"
										lappend saved_states [array get key2]
									}
								}
								set state($ipin_name) "f"
								set state($opin_name) "r"
								set states [expand_states -new_state state -inputs_list ilist $debug]
								foreach key1 $states {
									array set key2 $key1
									if { ![is_state_saved -saved_states saved_states -new_state key2 $debug]} {
										puts -nonewline $fout "       "
										puts -nonewline $fout "       "
										puts $fout "[write_sensitization_entry -inputs_list ilist -outputs_list olist -state key2 $debug] ;"
										lappend saved_states [array get key2]
									}
								}
							}
						} else {
							puts "Error: unknown sensitization for arc $ipin_name -> $opin_name"
							exit
						}
					}

				}
			}
			puts $fout "      \}"
		}
		#reset_design
		puts $fout "   \}"
		puts $fout "\}"
		close $fout
	}
}
define_myproc_attributes read_db_data \
	-info "read db file and print out lib cell data" \
	-define_args \
	{
		{-cells "cell_list" cell_list string optional}
	{-tmplt_dir "TMPL dir " dir string optional}
	{-db "DB file" file string optional}
	{-library "Library file" file string optional}
	{-pwd "PWD dir " dir string optional}
	{-debug "debug " "" boolean optional}
}

proc binary2int {args} {
	parse_myproc_arguments -args $args cargs
	set res 0
	regsub "\[ \]*" $cargs(binary) {} cargs(binary)
	foreach i [split $cargs(binary) ""] {
		set res [expr {$cargs(binary)*2+$i}]
	}
	return [set res]
}
define_myproc_attributes binary2int \
	-info "convert binary string to integer" \
	-define_args {
		{"binary" "binary string" string string required}
}

proc int2binary {args} {
	parse_myproc_arguments -args $args cargs
	set res {}
	while {$cargs(int) > 0} {
		set res [expr {$cargs(int)%2}]$res
		set cargs(int) [expr {$cargs(int)/2}]
	}
	append d [string repeat 0 $cargs(digits)] $res
	set res [string range $d [string length $res] end]
	return [split $res ""]
}
define_myproc_attributes int2binary \
	-info "convert integer to binary list" \
	-define_args {
		{"int" "integer" int int required}
	{"digits" "integer" int int required}
}


proc expand_states { args } {
	set cargs(-debug) 0
	parse_myproc_arguments -args $args cargs
	upvar $cargs(-new_state) new_state
	upvar $cargs(-inputs_list) inputs_list
	array set state [array get new_state]
	set names [array names state]

	set new_inputs {}
	set states {}
	if { $cargs(-debug) } {
		puts "Debug: INPUTS_LIST: $inputs_list"
	}
	foreach key1 $inputs_list {
		if { [lsearch -exact $names $key1 ] == -1 } {
			lappend new_inputs $key1
		}
	}
	if { $new_inputs ne "" } {
		if { $cargs(-debug) } {
			puts "Debug: NEW INPUTS: $new_inputs"
		}
		set new_len [llength $new_inputs]
		set pwr [expr pow(2, $new_len)]
		set i 0
		while { $i < $pwr } {
			set binary [int2binary $i $new_len]
			set j 0
			while { $j < $new_len} {
				set state([lindex $new_inputs $j]) [lindex $binary $j]
				incr j
			}
			lappend states [array get state]
			incr i
		}
		if { $cargs(-debug) } {
			puts "Debug: STATES:$states"
		}
		return $states
	} else {
		return [list  [array get new_state]]
	}
}
define_myproc_attributes expand_states \
	-info "expand states of all input pins" \
	-define_args {
		{-new_state "array with a new state to expand" string string required}
	{-inputs_list "list of inputs" string string required}
	{-debug "debug states" "" boolean optional}
}

proc is_state_saved { args } {
	set cargs(-debug) 0
	parse_myproc_arguments -args $args cargs
	upvar $cargs(-new_state) state
	upvar $cargs(-saved_states) saved_states
	set saved 0
	if { [info exists saved_states] && ([llength $saved_states] > 0)} {
		set saved 1
		foreach saved_state $saved_states {
			if { $cargs(-debug) }  {
				puts "Debug: SAVED_STATE: $saved_state"
			}
			set saved 1
			foreach key1 [array names state] {
				if { $cargs(-debug) } {
					puts "Debug: STATE: $key1 -> $state($key1)"
				}
				if { ![regexp "\[ \]*$key1 $state($key1)\[ \]*" $saved_state] } {
					set saved 0
					break
				}
			}
			if { $saved } {
				return $saved
			}
		}
	}
	return $saved
}
define_myproc_attributes is_state_saved \
	-info " check if new state has already been saved" \
	-define_args {
		{-new_state "new state to check" string string required}
	{-saved_states "list of states already saved" string string required}
	{-debug "debug states" "" boolean optional}
}

proc write_sensitization_entry { args } {
	set cargs(-fout) ""
	set cargs(-header) 0
	set cargs(-state) ""
	set cargs(-debug) 0
	parse_myproc_arguments -args $args cargs
	if { [string compare $cargs(-state) ""] != 0} {
		upvar $cargs(-state) pinstate
	}
	upvar $cargs(-inputs_list) inputs_list
	upvar $cargs(-outputs_list) outputs_list
	set first 1
	foreach pin [split [regsub -all "\[ \t\]+" [string trim [join $inputs_list]] { }]] {
		if { [string compare $cargs(-state) ""] != 0 } {
			if {[info exists "pinstate($pin)"] } {
				if {$first} {
					append line " $pinstate($pin)"
					set first 0
				} else {
					append line ", $pinstate($pin)"
				}
			} else {
				if {$first} {
					append line " x"
					set first 0
				} else {
					append line ", x"
				}
			}
		} else {
			if {$cargs(-header)} {
				if {$first} {
					append line " $pin"
					set first 0
				} else {
					append line ", $pin"
				}
			} else {
				if {$first} {
					append line " x"
					set first 0
				} else {
					append line ", x"
				}
			}
		}
	}
	set first 1
	foreach pin [split [regsub -all "\[ \t\]+" [string trim [join $outputs_list]] { }]] {
		if {[string compare $cargs(-state) ""] != 0} {
			if {[info exists "pinstate($pin)"] } {
				if {$first} {
					append line " : $pinstate($pin)"
					set first 0
				} else {
					append line ", $pinstate($pin)"
				}
			} else {
				if {$first} {
					append line " : x"
					set first 0
				} else {
					append line ", x"
				}
			}
		} else {
			if {$cargs(-header)} {
				if {$first} {
					append line " : $pin"
					set first 0
				} else {
					append line ", $pin"
				}
			} else {
				if {$first} {
					append line " : x"
					set first 0
				} else {
					append line ", x"
				}
			}
		}
	}
	if { [string compare $cargs(-fout) ""] != 0 } {
		set fout [open "$cargs(-fout)"  {a}]
		if { $cargs(-debug) } {
			puts "Debug: (write_sensitization_entry) $line"
		}
		puts $fout $line
		close($fout)
	} else {
		return $line
	}
}
define_myproc_attributes write_sensitization_entry \
	-info "write sensitization entry" \
	-define_args \
	{
		{-inputs_list "inputs_list" inputs_list string required}
	{-outputs_list "outputs_list" outputs_list string required}
	{-state   "state array"  state_array  string optional}
	{-header "write just the header"  "" boolean optional}
	{-fout "sensitization file" file string optional}
	{-debug "debug states" "" boolean optional}
}

proc get_sensitization_from_when_cond { when } {

	set state {}
	while { [regexp "\\((\[^\(\&\*\!\+\)\]+)\\)" $when dum key1] } {
		regsub "\\(\[^\&\*\!\+\(\)\]+\\)" $when "$key1" when
	}
	set c1 [regsub -all "\[&\*\]" $when " "]
	foreach key1 [split $c1 "+"] {
		set rcond ""
		if {[regexp "^\[ \]*\\((\[^\(\)\]+)\\)\[ \]*$" $key1 dum key2]} {
			regsub "^\[ \]*\\(\[^\(\)\]+\\)\[ \]*$" $key1 $key2 key1
		}
		regsub -all "\[ \]+" $key1 " " key1
		set cstate ""
		foreach sp [split $key1 " "] {
			#  set sp [string trim $sp "\("]
			#  set sp [string trim $sp "\)"]
			regsub -all  "\!\[ \]*" $sp "\!" sp
			set sp_check [split $sp "!"]
			set sp_check_len [llength $sp_check]


			if { $sp_check_len == 2 } {
				set pin [lindex $sp_check 1]
				set cstate [concat $cstate $pin]
				set cstate [concat $cstate " 0"]
				#append rcond [concat $rcond $cstate]
			} elseif { $sp_check_len == 1 } {
				set pin [lindex $sp 0]
				set cstate [concat $cstate $pin]
				set cstate [concat $cstate " 1"]
				#append rcond [concat $rcond $cstate]
			}
		}
		lappend state $cstate
	}
	return $state
}


# nolint Line 214: E Bad regexp