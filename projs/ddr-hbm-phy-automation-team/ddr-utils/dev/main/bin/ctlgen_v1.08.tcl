#!/depot/tcl/bin/tclsh

######################################################################
#
#                                  ctlgen
#                  Copyright (c) 2004-2015 by Synopsys, Inc.
#                             ALL RIGHTS RESERVED
#
#
# This program is proprietary and confidential information of Synopsys, Inc.
# and may be used and disclosed only as authorized in a license agreement
# controlling such use and disclosure.
#
# Disclaimer: This software is provided as an aide to Synopsys customers
# who need CTL test models for DFT Compiler. It is not an "official"
# product. All ctlgen generated CTL models should be verified for correctness.
#
######################################################################
#
#              Contains the following tcl procedures:
#
# ctlgen - Generate a CTL test model
# set_ctlgen_signal - Define signal for ctlgen
# remove_ctlgen_signal - Remove ctlgen signal
# report_ctlgen_signal - Report signals for ctlgen
# set_ctlgen_path - Define scan path for ctlgen
# remove_ctlgen_path - Remove ctlgen path
# report_ctlgen_path - Report paths for ctlgen
# define_ctlgen_mode - Define a test mode for ctlgen
# remove_ctlgen_mode - Remove ctlgen test mode
# report_ctlgen_mode - Report the ctlgen test mode
# current_ctlgen_mode - Set current ctlgen test mode
#
######################################################################
#
# Version History:
#
# 1.08 - 10/30/2015, scleary
#      - Fixed issue with _si/_so signal group creation when there
#        were no scan chain paths declared
#      - Changed how signal lists were collected in order to put in
#        a check for duplicate names. Duplicate pin/port names could
#        be seen when using -library and multiple copies of the
#        library loaded in memory. Not a common situation, but not an
#        issue any more just the same. Duplicate signals are ignored
#
# 1.07 - 10/28/2014, scleary
#      - Changed the signal group for bidirectional signals from
#        all_bidir to all_bidirectionals to be consistent with DFTC
#      - Fixed issue where bidirectional signals were not included
#        in the Timing WaveFormTable section
#      - Added support for the test_default_bidir_delay variable
#        when specifying timing for bidirectional signals
#      - Added a warning message that support of compression modes
#        may be removed from CTLGEN in a future release. I doubt that
#        anyone is relying on that feature but wanted to provide some
#        warning before removing it
#
# 1.06 - 07/28/2014, scleary
#      - Fixed issue with -usage clock_gating. Needed to put the
#        description for those types of ScanEnable signals in the
#        all_dft section and add quotes to the datatype. The all_dft
#        section is then "inherited" by the individual mode sections.
#      - Added a new command option for set_ctlgen_signal, -autofix.
#        This option is to identify signals that were created by
#        AutoFix so they can be promoted up to the top-level
#        automatically in HSS flows. This is somewhat of a corner-
#        case and should not need to be used in most flows.
#      - Added a Mission_mode section to the CTL to support the
#        AutoFix signals mentioned above. Currently, only putting
#        the minimum info regarding the AutoFix signals in the
#        Mission_mode section.
#      - Made various minor tweaks to the CTL format to bring it
#        more in line with the CTL from DFT Compiler.
#      - Added more consistency checking. Check that no two chains
#        share the same ScanDataOut signal. Check that the same number
#        of scanins scanouts and paths are defined in each mode.
#      - Added detailed usage information for each CTLGEN command via
#        the -man command option. For example "ctlgen -man".
#
# 1.05 - 02/10/2014, scleary
#      - Fixed issue with -library option on lib cells with bussed
#        ports
#      - Added feature to allow a CTL model to be generated even if
#        there are no scan chains defined. I.e. the test model only
#        contains pass-through signals.
#
# 1.04 - 07/29/2011, scleary
#      - Fixed port name issue when -library is used and the library
#        has "." or "-" in the name
#      - Added support for bussed clock signals, i.e., clk[0]
#      - Removed limitations on clock mixing. Can now specify 
#        negedge->negedge and negedge->posedge chains with different
#        clocks. E.g., ~clk1+~clk2 and ~clk1+clk2.
#      - Added an all_dft mode declaration to make DFTC happy
#      - Create "multi_clock" capture procedures to match the default
#        capture procedures produced by DFTC.
#      - Added a warning disclaimer when compressed modes are defined.
#        Only a simple compression architecture is supported (i.e. high
#        x-tolerance and other advanced compression solutions are not
#        supported). 
#      - Changed how the compression mode is architected. It's still
#        just an arbitrary basic compression mode.
#      - Added support for -usage with set_ctlgen_signal. It is to be
#        used for the ScanEnable signal type only. It indicates if a
#        ScanEnable signal is use only for scan or only as the clock
#        gating control. By default, a ScanEnable can be used for both.
#      - Fixed issue with LSSD designs where the scan master and slave
#        clocks were not being pulsed during shift
#      - Added CaptureClock and LaunchClock information to the scanin
#        and scanout signal descriptions for LSSD designs to match DFTC
#      - Added ActiveState info to the environment section when a
#        ScanClock or MasterClock signal is specified
#
# 1.03 - 09/25/2007, scleary
#      - Added support for "-type Expect" with set_ctlgen_signal. The
#        "expect" signals are output ports that are expected to
#        drive *Constant* logic values.
#
# 1.02 - 04/04/2007, scleary
#      - Added support for inout signals
#      - Fixed an issue with a define_ctlgen_mode Error message.
# 
# 1.01 - 10/18/2006, scleary
#      - Fixed issue with Reset Datatype in CTL Environment section.
#      - Added the ability to specify -timing option on Reset signals.
#      - Added type checking for Reset signal types with respect to
#        consistency between the active_state and timing options.
#      - Fixed issue with missing active state for Constant and
#        TestMode Dataypes in Environment section.
#      - For ScanMasterClock and ScanSlave Clock datatypes, added
#        active state to report_ctlgen_signal report to better match
#        the set_dft_signal report for LSSD signals.
#      - For non-clock signals in the report_ctlgen_signal report, 
#        removed the "-" in the Timing column to better match the
#        set_dft_signal report. 
#
# 1.00 - 8/15/2006, scleary
#      - New UI, ctlgen "XG mode". New UI patterned after DFTC whereas
#        previous versions resembled TetraMAX. Added many new features.
#      - Added support for pass-through signals with the -connected
#        option of the set_ctlgen_signal command.
#      - Added support for multi-mode test models. Created several new
#        commands to support multi-mode.
#      - Added support for compression mode CTL models
#      - Added a -repeat option to the set_ctlgen_path command to
#        simplify the specification of compression mode chains.
#      - Added support for terminal lockup latches with the
#        -termninal_lockup option of the set_ctlgen_path command.
#      - Added support for "mixed clock" chains. Done with the
#        set_ctlgen_path command. I.e. "-scan_master_clock clk1+clk2".
#      - Added support for ordered elements with the -ordered_elements
#        option of the set_ctlgen_path command.
#      - Enhanced the reporting commands to report by test_mode.
#      - Added a -check option to ctlgen to simplify the model
#        verification process some.
#      - Added more type checking and error checking throughout
#        the script.
#
# 0.03 - 2/10/2005, scleary
#      - Added some more error/type checking. Force integer timing values
#        when used the "default" variables for timing definition.
#
# 0.02 - 1/10/2005, scleary
#      - Another shot at feedback. Pre-release version for evaluation
#
# 0.01 - 10/20/2004, scleary
#      - Pre-release version for evaluation
#
######################################################################


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
utils__script_usage_statistics $script_name "2022ww16"



# Disable the new variable messages, save previous value, if it exists
if { [info exists sh_new_variable_message] } {
    if { $sh_new_variable_message } {
        set sh_new_variable_message "false"
        set new_var_restore "true" 
    } else {
        set new_var_restore "false" 
    }
}
set version "1.08"

# Initialize the datastructure indexes
set signal_index 0
set path_index 0
set mode_index 0

# Create a default mode, Internal_scan
set mode_data(name,$mode_index) "Internal_scan"
set mode_data(type,$mode_index) "Scan"
set current_ctlgen_mode "Internal_scan"
incr mode_index


######################################################################
#
# Procedure to define the ctlgen signals
#
######################################################################
proc set_ctlgen_signal {args} {
    parse_proc_arguments -args $args results

    global signal_data signal_index
    global mode_data mode_index
    global test_default_period
    global current_ctlgen_mode
    global man_data

    # Print detailed usage info
    if { [info exists results(-man)] } {
	echo $man_data(set_ctlgen_signal)
	return 1
    }

    # Check for required arguments
    if { ![info exists results(-port)] || ![info exists results(-type)] } {
	if { ![info exists results(-port)] } {
	    echo "Error: Required argument \'-port\' was not found. Disregarding command."
	}
	if { ![info exists results(-type)] } {
	    echo "Error: Required argument \'-type\' was not found. Disregarding command."
	}
	return 0
    }

    # Do some error checking
    set signal_errors 0

    # Check the signal type, set to CTL standard type
    if { [regexp -nocase {Reset} $results(-type)] } {
	set results(-type) "Reset"
    } elseif { [regexp -nocase {Constant} $results(-type)] } {
	set results(-type) "Constant"
    } elseif { [regexp -nocase {(Test)?Mode} $results(-type)] } {
	set results(-type) "TestMode"
    } elseif { [regexp -nocase {TestData} $results(-type)] } {
	# TestData not used yet
	set results(-type) "TestData"
    } elseif { [regexp -nocase {(ScanDataIn|ScanIn)} $results(-type)] } {
	set results(-type) "ScanDataIn"
    } elseif { [regexp -nocase {(ScanDataOut|ScanOut)} $results(-type)] } {
	set results(-type) "ScanDataOut"
    } elseif { [regexp -nocase {ScanMasterClock} $results(-type)] } {
	set results(-type) "ScanMasterClock"
    } elseif { [regexp -nocase {ScanSlaveClock} $results(-type)] } {
	set results(-type) "ScanSlaveClock"
    } elseif { [regexp -nocase {(Scan)?Enable} $results(-type)] } {
	set results(-type) "ScanEnable"
    } elseif { [regexp -nocase {InOutControl} $results(-type)] } {
	# InOutControl not used yet
	set results(-type) "InOutControl"
    } elseif { [regexp -nocase {MasterClock} $results(-type)] } {
	set results(-type) "MasterClock"
    } elseif { [regexp -nocase {SlaveClock} $results(-type)] } {
	set results(-type) "SlaveClock"
    } elseif { [regexp -nocase {ScanClock} $results(-type)] } {
	set results(-type) "ScanClock"
    } elseif { [regexp -nocase {TestClock} $results(-type)] } {
	set results(-type) "ScanClock"
    } elseif { [regexp -nocase {IsConnected} $results(-type)] } {
	set results(-type) "IsConnected"
    } elseif { [regexp -nocase {Expect} $results(-type)] } {
	set results(-type) "Expect"
    } else {
	set signal_errors 1
	echo "Error: Unrecognized port type \($results(-type)\)."
    }

    # Test mode is optional, default test_mode is current_ctlgen_mode
    if { [info exists results(-test_mode)] } {
	# Convert "all" to "all_dft"
	if { $results(-test_mode) == "all" } {
	    set results(-test_mode) "all_dft"
	}
    } else {
	set results(-test_mode) $current_ctlgen_mode
    }

    # Look for the specified test_mode in the list of defined modes
    for {set index 0} {$index < $mode_index} {incr index} {
	# Look for the current_mode in the mode database
	if { $mode_data(name,$index) == $results(-test_mode) } {
	    set mode_found 1
	}
    }

    # If the mode was not found in the section above, then the requested mode is not valid
    if { ![info exists mode_found] && $results(-test_mode) != "all_dft" } {
	set signal_errors 1
	echo "Error: Requested test mode ($results(-test_mode)) is not a ctlgen test mode. Declare with the \"define_ctlgen_mode\" command."
    }

    # Active state is optional, check the state value
    if { [info exists results(-active_state)] } {
	if { ![regexp -nocase {^(0|1)$} $results(-active_state)] } {
	    set signal_errors 1
	    echo "Error: Unrecognized port active state value \($results(-active_state)\)."
	}
    }

    # Usage is optional, check the value
    if { [info exists results(-usage)] } {
	if { ![regexp -nocase {^(scan|clock_gating)$} $results(-usage)] } {
	    set signal_errors 1
	    echo "Error: Unrecognized usage value \($results(-active_state)\). Valid values are \"scan\" or \"clock_gating\"."
	}
    }

    # Check to see if the port was already defined in the current mode or in "all_dft"
    # Look for the signal
    for {set index 0} {$index < $signal_index} {incr index} {
	# Look for the signal 
	if { $signal_data(port,$index) == $results(-port) } {
	    # See if signal is defined in the current mode or "all_dft"
	    if { $results(-test_mode) == $signal_data(test_mode,$index) || $results(-test_mode) == "all_dft" || $signal_data(test_mode,$index) == "all_dft" } {
		set signal_errors 1
		echo "Error: Port ($results(-port)) has already been declared in test_mode ($results(-test_mode)) or in \"all_dft\"."
	    }
	}
    }

    # Check the timing option
    if { [info exists results(-timing)] } {
	# Make sure the list is two elements long
	if { [llength $results(-timing)] != 2 } {
	    set signal_errors 1
	    echo "Error: The -timing option should be a TCL list with two elements. I.e. \"-timing {45 95}\"."
	} else {
	    # Check for consistancy between active_state and timing
	    foreach { clk_up clk_dwn } $results(-timing) {break}
	    if { [info exists results(-active_state)] } {
		if { $clk_up < $clk_dwn } {
		    if { $results(-active_state) != 1 } {
			set signal_errors 1
			echo "Error: Timing ($results(-timing)) inconsistent with active_state ($results(-active_state))."
		    }
		} else {
		    if { $results(-active_state) != 0 } {
			set signal_errors 1
			echo "Error: Timing ($results(-timing)) inconsistent with active_state ($results(-active_state))."
		    }
		}
	    } else {
		# If no active_state on a Reset signal, figure it out from the Timing waveform 
		if { [regexp {(Reset)} $results(-type)] } {
		    if { $clk_up < $clk_dwn } {
			set results(-active_state) 1
		    } else {
			set results(-active_state) 0
		    }
		}
	    }
	}
    }

    # If IsConnected is used, then a -connected signal needs to be identified
    if { [regexp {(IsConnected)} $results(-type)] } {
	if { ![info exists results(-connected)] } {
	    set signal_errors 1
	    echo "Error: An IsConnected signal type must also use -connected to identify the connection."
	}
    }

    # If no errors, put the values in the signal_data record
    if { $signal_errors == 0 } {
		
	# Put values in signal_data record
	set signal_data(port,$signal_index) $results(-port)
	set signal_data(type,$signal_index) $results(-type)
	set signal_data(test_mode,$signal_index) $results(-test_mode)

	# Keep separate track of scan in/out signals per mode for later checks	
	if { [regexp {(ScanDataIn)} $results(-type)] } {
	    lappend signal_data(sin,$results(-test_mode)) $results(-port)
	}
	if { [regexp {(ScanDataOut)} $results(-type)] } {
	    lappend signal_data(sout,$results(-test_mode)) $results(-port)
	}

	# Active state is optional, will use "1" as the default
	if { [info exists results(-active_state)] } {
	    if { [regexp {(ScanEnable|Reset|Constant|TestMode|IsConnected|Expect)} $results(-type)] } {
		set signal_data(active_state,$signal_index) $results(-active_state)
	    } else {
		echo "Warning: Active state is not meaningful for port type \($results(-type)\), ignoring active state specification ..."
	    }
	} else {
	    if { [regexp {(ScanEnable|Reset|Constant|TestMode|IsConnected|Expect)} $results(-type)] } {
		set results(-active_state) 1
		set signal_data(active_state,$signal_index) 1
	    }
	}

	# Timing is optional, default is 45% of the period for leading edge, and 95% for trailing edge
	if { [info exists results(-timing)] } {
	    if { [regexp {(ScanMasterClock|ScanSlaveClock|MasterClock|SlaveClock|ScanClock|Reset)} $results(-type)] } {
		set signal_data(timing,$signal_index) $results(-timing)
	    } else {
		echo "Warning: The -timing option is not meaningful for port type \($results(-type)\), ignoring -timing specification ..."
	    }
	
	} else {
	    if { [regexp {(ScanMasterClock|ScanSlaveClock|MasterClock|SlaveClock|ScanClock|Reset)} $results(-type)] } {
		if { [info exists results(-active_state)] && $results(-active_state) == 0 } {
		    set signal_data(timing,$signal_index) [list [expr {int($test_default_period * 95 / 100)}] [expr {int($test_default_period * 45 / 100)}] ]
		} else {
		    set signal_data(timing,$signal_index) [list [expr {int($test_default_period * 45 / 100)}] [expr {int($test_default_period * 95 / 100)}] ]
		}
	    }
	}

	# Connected port is optional
	if { [info exists results(-connected)] } {
	    if { [regexp {IsConnected} $results(-type)] } {
		set signal_data(connected,$signal_index) $results(-connected)
	    } else {
		echo "Warning: The -connected option is not meaningful for port type \($results(-type)\), ignoring -connected specification ..."
	    }
	}

	# Usage is optional
	if { [info exists results(-usage)] } {
	    if { [regexp {ScanEnable} $results(-type)] } {
		set signal_data(usage,$signal_index) $results(-usage)
	    } else {
		echo "Warning: The -usage option is not meaningful for port type \($results(-type)\), ignoring -usage specification ..."
	    }
	}

	# Autofix is optional
	if { [info exists results(-autofix)] } {
	    if { [regexp {ScanClock|TestMode|Reset} $results(-type)] } {
		set signal_data(autofix,$signal_index) $results(-autofix)
	    } else {
		echo "Warning: The -autofix option is not meaningful for port type \($results(-type)\), ignoring -autofix specification ..."
	    }
	}
	
	echo "Accepted ctlgen signal for port \($results(-port)\) in mode: \($results(-test_mode)\)."
	incr signal_index
	return 1
    } else {
	echo "Error: Signal \($results(-port)\) rejected because of errors ..."
	return 0
    }
}
define_proc_attributes set_ctlgen_signal -info "Define signal for ctlgen" -define_args {
    {"-port" "Port Name" <port_name> string optional}
    {"-type" "Port Type" <port_type> string optional}
    {"-active_state" "Active State" <0/1> int optional}
    {"-timing" "Timing Waveform" "<<RE> <FE>>" list optional}
    {"-connected" "Connected Port Name" <port_name> string optional}
    {"-test_mode" "Test Mode Name" <mode_name> string optional}
    {"-usage" "ScanEnable Usage" <scan|clock_gating> string optional}
    {"-autofix" "Autofix Signal" "" boolean optional}
    {"-help" "Print usage information" "" boolean optional}
    {"-man" "Print more detailed usage information" "" boolean optional}
}

######################################################################
#
# Procedure to define the ctlgen scan paths
#
######################################################################
proc set_ctlgen_path {args} {
    parse_proc_arguments -args $args results

    global path_data path_index
    global signal_data signal_index
    global mode_data mode_index
    global test_default_period
    global current_ctlgen_mode
    global man_data

    # Print detailed usage info
    if { [info exists results(-man)] } {
	echo $man_data(set_ctlgen_path)
	return 1
    }

    # Check for required arguments
    if { ![info exists results(-name)] || ![info exists results(-length)] || ![info exists results(-scan_master_clock)] } {
	if { ![info exists results(-name)] } {
	    echo "Error: Required argument \'-name\' was not found. Disregarding command."
	}
	if { ![info exists results(-length)] } {
	    echo "Error: Required argument \'-length\' was not found. Disregarding command."
	}
	if { ![info exists results(-scan_master_clock)] } {
	    echo "Error: Required argument \'-scan_master_clock\' was not found. Disregarding command."
	}
	return 0
    }

    # Do some error checking
    set path_errors 0

    # Check for duplicate chain names, in any mode
    for {set index 0} {$index < $path_index} {incr index} {
	if { $path_data(name,$index) == $results(-name) } {
	    set path_errors 1
	    echo "Error: Duplicate chain name found ($results(-name)), chain names must be unique."
	    break
	}
    }

    # Test mode is optional, default test_mode is current_ctlgen_mode
    if { [info exists results(-test_mode)] } {
	# Convert "all" to "all_dft"
	if { $results(-test_mode) == "all" } {
	    set results(-test_mode) "all_dft"
	}
    } else {
	set results(-test_mode) $current_ctlgen_mode
    }

    # The -scan_enable and -scan_slave_clock are mutually exclusive
    if { [info exists results(-scan_slave_clock)] && [info exists results(-scan_enable)] } {
	set path_errors 1
	echo "Error: The options -scan_enable and -scan_slave_clock cannot both be specified."
    }

    # Check for signal in the requested mode, if not defined, call set_ctlgen_signal to define (if no errors)
    set si_found 0
    set so_found 0
    set se_found 0
    set clk_found 0
    set capture_found 0
    set launch_found 0
    for {set index 0} {$index < $signal_index} {incr index} {
	# If the signal is not active in the requested mode (or all_dft), skip it
	if { $signal_data(test_mode,$index) != $results(-test_mode) && $signal_data(test_mode,$index) != "all_dft" } {
	    continue
	}
	# If one is specified, look for the scan_data_in port in the signals list
	if { [info exists results(-scan_data_in)] && $signal_data(port,$index) == $results(-scan_data_in) } {
	    set si_found 1
	}
	# If one is specified, look for the scan_data_out port in the signals list
	if { [info exists results(-scan_data_out)] && $signal_data(port,$index) == $results(-scan_data_out) } {
	    set so_found 1
	}
	# If one is specified, look for the scan_enable port in the signals list
	if { [info exists results(-scan_enable)] && $signal_data(port,$index) == $results(-scan_enable) } {
	    set se_found 1
	}
	# If the scan_master_clock is "mixed clock", look for both clocks in the signals list
	if { [regexp {[\w\[\]\~\!]+\+[\w\[\]\~\!]+} $results(-scan_master_clock)] } {
	    # A "+" in the middle signifies a "Mixed clock" chain
	    foreach { capture launch } [split $results(-scan_master_clock) \+] {break}
	    if { $signal_data(port,$index) == [regsub {^[\~\!\+]} $capture ""] } {
		set capture_found 1
	    }
	    if { $signal_data(port,$index) == [regsub {^[\~\!\+]} $launch ""] } {
		set launch_found 1
	    }
	} else {
	    if { $signal_data(port,$index) == [regsub {^[\~\!\+]} $results(-scan_master_clock) ""] } {
		set clk_found 1
	    }
	}
    }

    # Check if the test_mode is a compression mode. If yes, si/so are not needed. If not, si/so are required.
    for {set index 0} {$index < $mode_index} {incr index} {
	# Look for the current_mode in the mode database
	if { $mode_data(name,$index) == $results(-test_mode) } {
	    # See if the mode is a compression mode
	    if { $mode_data(type,$index) == "Compression" } {
		set mode_type "Compression"
		if { [info exists results(-scan_data_in)] || [info exists results(-scan_data_out)] } {
		    echo "Info: The \"-scan_data_in\" and/or \"-scan_data_out\" specifications are not meaningful for \"Compression\" mode types."
		}
	    } else {
		set mode_type "Scan"
		# If not a compression mode, the scan_data_in and scan_data_out options are required
		if { ![info exists results(-scan_data_in)] || ![info exists results(-scan_data_out)] } {
		    set path_errors 1
		    echo "Error: The \"-scan_data_in\" and \"-scan_data_out\" specifications are requred for \"Scan\" mode types."
		}
		# The -repeat option is not meant to be used for "Scan" modes
		if { [info exists results(-repeat)] } {
		    echo "Warning: The \"-repeat\" option is not meant to be used with \"Scan\" mode types. Ignoring repeat."
		    set results(-repeat) 1
		}
	    }
	}
    }

    # If repeat is not found, the default is 1
    if { ![info exists results(-repeat)] } {
	set results(-repeat) 1
    }

    # If the mode_type was not found in the section above, then the requested mode is not valid
    if { ![info exists mode_type] } {
	set path_errors 1
	echo "Error: Requested test mode ($results(-test_mode)) is not a ctlgen test mode. Declare with the \"define_ctlgen_mode\" command."
    }

    # If no errors, add the path
    if { $path_errors == 0 } {
		
	# Call set_ctlgen_signal for missing si, so, se, or clock signals that weren't previously defined.
	if { $mode_type == "Scan" && $si_found == 0 } {
	    echo "Info: Signal $results(-scan_data_in) not defined in test_mode $results(-test_mode), adding signal now ..."
	    set_ctlgen_signal -type ScanDataIn -port $results(-scan_data_in) -test_mode $results(-test_mode)
	}
	if { $mode_type == "Scan" && $so_found == 0 } {
	    echo "Info: Signal $results(-scan_data_out) not defined in test_mode $results(-test_mode), adding signal now ..."
	    set_ctlgen_signal -type ScanDataOut -port $results(-scan_data_out) -test_mode $results(-test_mode)
	}
	if { [info exists results(-scan_enable)] && $se_found == 0 } {
	    echo "Info: Signal $results(-scan_enable) not defined in test_mode $results(-test_mode), adding signal now ..."
	    set_ctlgen_signal -type ScanEnable -port $results(-scan_enable) -test_mode $results(-test_mode)
	}
	if { [regexp {[\w\[\]\~\!]+\+[\w\[\]\~\!]+} $results(-scan_master_clock)] } {
	    foreach { capture launch } [split $results(-scan_master_clock) \+] {break}
	    if { $capture_found == 0 } {
		echo "Info: Signal $capture not defined in test_mode $results(-test_mode), adding signal now ..."
		set_ctlgen_signal -type ScanClock -port $capture -test_mode $results(-test_mode)
	    }
	    if { $launch_found == 0 } {
		echo "Info: Signal $launch not defined in test_mode $results(-test_mode), adding signal now ..."
		set_ctlgen_signal -type ScanClock -port $launch -test_mode $results(-test_mode)
	    }
	} else {
	    if { $clk_found == 0 } {
		echo "Info: Signal $results(-scan_master_clock) not defined in test_mode $results(-test_mode), adding signal now ..."
		set_ctlgen_signal -type ScanClock -port $results(-scan_master_clock) -test_mode $results(-test_mode)
	    }
	}

	# Put values in path_data record
	# Repeat the specification as necessary (repeat is only for "Compression" modes)
	for {set index 0} {$index < $results(-repeat)} {incr index} {
	    # If doing a repeated path, create a unique path name
	    if { $results(-repeat) > 1 } {
		# If the given name end in a number, increment the number
		if { [regexp {^(.+)(\d+)$} $results(-name) match root_name path_number] } {
		    # Increment the path number
		    incr path_number $index
		    # Rebuild the path name
		    set path_name "$root_name$path_number"
		} else {
		    # Otherwise add a number to the root name given
		    set path_number [expr {$index + 1}]
		    # Rebuild the path name
		    set path_name "$results(-name)$path_number"
		}
	    } else {
		set path_name $results(-name)
	    }
	    set path_data(name,$path_index) $path_name
	    if { [info exists results(-scan_data_in)] } {
		set path_data(scan_data_in,$path_index) $results(-scan_data_in)
	    } else {
		set path_data(scan_data_in,$path_index) "-"
	    }
	    if { [info exists results(-scan_data_out)] } {
		set path_data(scan_data_out,$path_index) $results(-scan_data_out)
	    } else {
		set path_data(scan_data_out,$path_index) "-"
	    }
	    set path_data(length,$path_index) $results(-length)
	    if { [info exists results(-scan_enable)] } {
		set path_data(scan_enable,$path_index) $results(-scan_enable)
	    }
	    set path_data(test_mode,$path_index) $results(-test_mode)
	    set path_data(scan_master_clock,$path_index) $results(-scan_master_clock)
	    
	    # Scan slave clock is optional (indicates an LSSD design)
	    if { [info exists results(-scan_slave_clock)] } {
		set path_data(scan_slave_clock,$path_index) $results(-scan_slave_clock)
	    }
	    
	    # Ordered elements are optional, by default dummy cells will be generated
	    if { [info exists results(-ordered_elements)] } {
		set path_data(ordered_elements,$path_index) $results(-ordered_elements)
	    }
	    
	    # Terminal lockup latch is optional
	    if { [info exists results(-terminal_lockup)] } {
		set path_data(terminal_lockup,$path_index) $results(-terminal_lockup)
	    }

	    # Keep track of path names per mode
	    lappend path_data(names,$results(-test_mode)) $results(-name)
	    
	    echo "Accepted ctlgen path for chain \($path_name\) in mode: \($results(-test_mode)\)."
	    incr path_index
	}
	return 1
    } else {
	echo "Error: Path \($results(-name)\) rejected because of errors ..."
	return 0
    }
}
define_proc_attributes set_ctlgen_path -info "Define scan path for ctlgen" -define_args {
    {"-name" "Scan Chain Name" <chain_name> string optional}
    {"-scan_data_in" "Scan Chain Input" <port_name> string optional}
    {"-scan_data_out" "Scan Chain Output" <port_name> string optional}
    {"-length" "Scan Chain Length" <int> int optional}
    {"-scan_master_clock" "Scan Chain Clock" <port_name> string optional}
    {"-scan_slave_clock" "Scan Chain Clock" <port_name> string optional}
    {"-scan_enable" "Scan Chain Enable" <port_name> string optional}
    {"-ordered_elements" "Scan Chain Cells" <cells> list optional}
    {"-terminal_lockup" "Chain Has A Terminal Lockup Latch" "" boolean optional}
    {"-repeat" "Repeat Path Specification" <int> int optional}
    {"-test_mode" "Test Mode Name" <mode_name> string optional}
    {"-help" "Print usage information" "" boolean optional}
    {"-man" "Print more detailed usage information" "" boolean optional}
}

######################################################################
#
# Procedure to report the ctlgen signals
#
######################################################################
proc report_ctlgen_signal {args} {
    parse_proc_arguments -args $args results

    global signal_data signal_index

    global test_default_delay
    global test_default_bidir_delay
    global test_default_period
    global test_default_strobe
    global product_version version
    global man_data

    # Print detailed usage info
    if { [info exists results(-man)] } {
	echo $man_data(report_ctlgen_signal)
	return 1
    }

    # Report all signal data defined for ctlgen
    echo "****************************************"
    echo "Report : ctlgen signals"
    echo "Version: $product_version, (ctlgen: $version)"
    echo "Date   :" [date]
    echo "****************************************"

    echo "\nDefaults: test_default_period = $test_default_period, test_default_delay = $test_default_delay, test_default_bidir_delay = $test_default_bidir_delay, test_default_strobe = $test_default_strobe"
    
    # Get a list of all the modes referenced
    set test_modes {}
    for {set index 0} {$index < $signal_index} {incr index} {
	if { [lsearch -exact $test_modes $signal_data(test_mode,$index)] == -1 } {
	    lappend test_modes $signal_data(test_mode,$index)
	}
    }
    
    # Report the signals for each test_mode
    foreach mode $test_modes {
	echo "\n========================================"
	echo "TEST MODE: $mode"
	echo "========================================\n"

	echo  [format "%-15s %-15s %-10s %-10s" "Port" "Type" "Active" "Timing"]
	echo  [format "%-15s %-15s %-10s %-10s" "--------------" "--------------" "---------" "---------"]
	if { [array exists signal_data] } {
	    for {set index 0} {$index < $signal_index} {incr index} {

		# Only display the targeted mode
		if { $mode != $signal_data(test_mode,$index) } {
		    continue
		}

		# See if signal has an active state
		if { ![info exists signal_data(active_state,$index)] } {
		    # For clock signals, figure out the active state to report
		    if { [regexp {(ScanMasterClock|ScanSlaveClock|MasterClock|SlaveClock|ScanClock)} $signal_data(type,$index)] } {
			foreach { clk_up clk_dwn } $signal_data(timing,$index) {break}
			if { $clk_dwn > $clk_up } {
			    set tmp_active 1
			} else {
			    set tmp_active 0
			}		    
		    } else {
			set tmp_active "-"
		    }
		} else {
		    set tmp_active $signal_data(active_state,$index)
		}
		
		# See if signal has timing
		if { ![info exists signal_data(timing,$index)] } {
		    set tmp_timing ""
		} else {
		    set tmp_timing "{$signal_data(timing,$index)}"
		}
		
		# If type IsConnected, put the connected port in the "Timing" column
		if { [regexp -nocase {IsConnected} $signal_data(type,$index)] } {
		    echo  [format "%-15s %-15s %-10s %-10s" $signal_data(port,$index) $signal_data(type,$index) $tmp_active $signal_data(connected,$index)]
		} else {
		    echo  [format "%-15s %-15s %-10s %-10s" $signal_data(port,$index) $signal_data(type,$index) $tmp_active $tmp_timing]
		}
	    }
	}
    }
    return 1
}
define_proc_attributes report_ctlgen_signal -info "Report signals for ctlgen" -define_args {
    {"-help" "Print usage information" "" boolean optional}
    {"-man" "Print more detailed usage information" "" boolean optional}
}

######################################################################
#
# Procedure to report the ctlgen path
#
######################################################################
proc report_ctlgen_path {args} {
    parse_proc_arguments -args $args results

    global path_data path_index
    global product_version version
    global man_data

    # Print detailed usage info
    if { [info exists results(-man)] } {
	echo $man_data(report_ctlgen_path)
	return 1
    }

    # Report all scan path data defined for ctlgen
    echo "****************************************"
    echo "Report : ctlgen scan paths"
    echo "Version: $product_version, (ctlgen: $version)"
    echo "Date   :" [date]
    echo "****************************************"

    # Get a list of all the modes referenced
    set test_modes {}
    for {set index 0} {$index < $path_index} {incr index} {
	if { [lsearch -exact $test_modes $path_data(test_mode,$index)] == -1 } {
	    lappend test_modes $path_data(test_mode,$index)
	}
    }
    
    # Report the paths for each test_mode
    foreach mode $test_modes {
	echo "\n========================================"
	echo "TEST MODE: $mode"
	echo "========================================\n"

	echo  [format "%-15s %-5s %-12s %-12s %-12s %-12s %-12s" "Name" "Len" "ScanDataIn" "ScanDataOut" "ScanEnable" "MasterClock" "SlaveClock"]
	echo  [format "%-15s %-5s %-12s %-12s %-12s %-12s %-12s" "--------------" "-----" "-----------" "-----------" "-----------" "-----------" "-----------"]
	if { [array exists path_data] } {
	    for {set index 0} {$index < $path_index} {incr index} {
		
		# Only display the targeted mode
		if { $mode != $path_data(test_mode,$index) } {
		    continue
		}
		
		# See if path has a scan enable (Mux-D)
		if { ![info exists path_data(scan_enable,$index)] } {
		    set tmp_scan_enable "-"
		} else {
		    set tmp_scan_enable $path_data(scan_enable,$index)
		}

		# See if path has a slave clock (LSSD)
		if { ![info exists path_data(scan_slave_clock,$index)] } {
		    set tmp_scan_slave_clock "-"
		} else {
		    set tmp_scan_slave_clock $path_data(scan_slave_clock,$index)
		}
		
		echo  [format "%-15s %-5s %-12s %-12s %-12s %-12s %-12s" $path_data(name,$index) $path_data(length,$index) $path_data(scan_data_in,$index) $path_data(scan_data_out,$index) $tmp_scan_enable $path_data(scan_master_clock,$index) $tmp_scan_slave_clock]
	    }
	}
    }
    return 1
}
define_proc_attributes report_ctlgen_path -info "Report paths for ctlgen" -define_args {
    {"-help" "Print usage information" "" boolean optional}
    {"-man" "Print more detailed usage information" "" boolean optional}
}

######################################################################
#
# Procedure to remove a previously defined ctlgen signals
#
######################################################################
proc remove_ctlgen_signal {args} {
    parse_proc_arguments -args $args results

    global signal_data signal_index
    global current_ctlgen_mode
    global man_data

    # Print detailed usage info
    if { [info exists results(-man)] } {
	echo $man_data(remove_ctlgen_signal)
	return 1
    }

    # If a test_mode is specified by itself, build a list of ports to be removed
    if { [info exists results(-test_mode)] && ![info exists results(-port)] } {
	# Look through list of signals
	for {set index 0} {$index < $signal_index} {incr index} {
	    # See if the current port matches the test_mode specified for removal
	    if { [lsearch -exact $results(-test_mode) $signal_data(test_mode,$index)] != -1 } {
		# Build a list of ports to pass to the removal section below
		lappend results(-port) $signal_data(port,$index)
	    }
	}
	if { ![info exists results(-port)] } {
	    echo "Warning: No ports to remove in test_mode ($results(-test_mode))."
	    return 0
	}
    }

    # Reset all data
    if { [info exists results(-all)] } {
	echo "Info: All ctlgen signals removed."
	set signal_index 0
	if { [array exists signal_data] } {
	    unset signal_data
	}
	return 1
    } elseif { [info exists results(-port)] } {
	# If modes are specified with the port, use them, else use current test_mode
	if { [info exists results(-test_mode)] } {
	    set test_modes $results(-test_mode)
	} else {
	    set test_modes $current_ctlgen_mode
	}

	# Go through the signal list for each targeted port
	foreach port $results(-port) {
	    for {set index 0} {$index < $signal_index} {incr index} {
		# See if the current port matches one of the ports targetted for removal
		if { $port == $signal_data(port,$index) && [lsearch -exact $test_modes $signal_data(test_mode,$index)] != -1 } {
		    echo "Info: Removing signal \'$port\' in mode: ($signal_data(test_mode,$index)) ..."
		    
		    # Check if we are down to the last signal index
		    if { $signal_index <= 1 } {
			# Remove the whole signal array
			if { [array exists signal_data] } {
			    set signal_index 0
			    unset signal_data
			    break
			}
		    } else {
			
			# Move all signals down one position in the indexed data structure
			for {set shift_index [expr {$index + 1}]} {$shift_index < $signal_index} {incr shift_index} {
			    
			    # Set down_index to the index below the shift index
			    set down_index [expr {$shift_index -1}]
			    
			    # Overwrite the signal at down_index with the shift_index
			    set signal_data(port,$down_index) $signal_data(port,$shift_index)
			    set signal_data(type,$down_index) $signal_data(type,$shift_index)
			    set signal_data(test_mode,$down_index) $signal_data(test_mode,$shift_index)
			    
			    # Active state, timing and connected are optional, so extra work is required
			    if { [info exists signal_data(active_state,$shift_index)] } {
				set signal_data(active_state,$down_index) $signal_data(active_state,$shift_index)
			    } elseif { [info exists signal_data(active_state,$down_index)] } {
				unset signal_data(active_state,$down_index)
			    }
			    if { [info exists signal_data(timing,$shift_index)] } {
				set signal_data(timing,$down_index) $signal_data(timing,$shift_index)
			    } elseif { [info exists signal_data(timing,$down_index)] } {
				unset signal_data(timing,$down_index)
			    }
			    if { [info exists signal_data(connected,$shift_index)] } {
				set signal_data(connected,$down_index) $signal_data(connected,$shift_index)
			    } elseif { [info exists signal_data(connected,$down_index)] } {
				unset signal_data(connected,$down_index)
			    }
			}
			# After shifting down all the signals decrement the signal index
			incr signal_index -1
			incr index -1
		    }
		}
	    }
	}
	return 1
    } else {
	echo "Error: Need to provide one of the following arguments: -all or -port <port_list> ..."
	return 0
    }
}
define_proc_attributes remove_ctlgen_signal -info "Remove ctlgen signal" -define_args {
    {"-all" "Remove All Signals" "" boolean optional}
    {"-port" "Remove Specified Port(s)" <port_list> list optional}
    {"-test_mode" "Remove Signals For Specified Test Modes" <test_modes> list optional}
    {"-help" "Print usage information" "" boolean optional}
    {"-man" "Print more detailed usage information" "" boolean optional}
}

######################################################################
#
# Procedure to remove a previously defined ctlgen path
#
######################################################################
proc remove_ctlgen_path {args} {
    parse_proc_arguments -args $args results

    global path_data path_index
    global man_data

    # Print detailed usage info
    if { [info exists results(-man)] } {
	echo $man_data(remove_ctlgen_path)
	return 1
    }

    # If a test_mode is specified, build a list of ports to be removed
    if { [info exists results(-test_mode)] } {
	# Look through list of paths
	for {set index 0} {$index < $path_index} {incr index} {
	    # See if the current path matches the test_mode specified for removal
	    if { [lsearch -exact $results(-test_mode) $path_data(test_mode,$index)] != -1 } {
		# Build a list of paths to pass to the removal section below
		lappend results(-name) $path_data(name,$index)
	    }
	}
	if { ![info exists results(-name)] } {
	    echo "Warning: No paths to remove in test_mode ($results(-test_mode))."
	    return 0
	}
    }

    # Reset all data
    if { [info exists results(-all)] } {
	echo "Info: All ctlgen paths removed."
	set path_index 0
	if { [array exists path_data] } {
	    unset path_data
	}
	return 1
    } elseif { [info exists results(-name)] } {
	# Go through the chain list for each targeted path
	foreach path $results(-name) {
	    for {set index 0} {$index < $path_index} {incr index} {
		# See if the current chain name matches one of the chains targetted for removal
		if { $path == $path_data(name,$index) } {
		    echo "Info: Removing path \'$path\' in test_mode ($path_data(test_mode,$index)) ..."

		    # Check if we are down to the last path index
		    if { $path_index <= 1 } {
			# Remove the whole path array
			if { [array exists path_data] } {
			    set path_index 0
			    unset path_data
			    break
			}
		    } else {

			# Move all paths down one position in the indexed data structure
			for {set shift_index [expr {$index + 1}]} {$shift_index < $path_index} {incr shift_index} {
			    
			    # Set down_index to the index below the shift index
			    set down_index [expr {$shift_index -1}]
			    
			    # Overwrite the path data at down_index with the data at shift_index
			    set path_data(name,$down_index) $path_data(name,$shift_index)
			    set path_data(scan_data_in,$down_index) $path_data(scan_data_in,$shift_index)
			    set path_data(scan_data_out,$down_index) $path_data(scan_data_out,$shift_index)
			    set path_data(length,$down_index) $path_data(length,$shift_index)
			    set path_data(scan_enable,$down_index) $path_data(scan_enable,$shift_index)
			    set path_data(scan_master_clock,$down_index) $path_data(scan_master_clock,$shift_index)
			    set path_data(test_mode,$down_index) $path_data(test_mode,$shift_index)

			    # Scan slave clock and ordered elements are optional, so extra work is required
			    if { [info exists path_data(scan_slave_clock,$shift_index)] } {
				set path_data(scan_slave_clock,$down_index) $path_data(scan_slave_clock,$shift_index)
			    } elseif { [info exists path_data(scan_slave_clock,$down_index)] } {
				unset path_data(scan_slave_clock,$down_index)
			    }
			    if { [info exists path_data(ordered_elements,$shift_index)] } {
				set path_data(ordered_elements,$down_index) $path_data(ordered_elements,$shift_index)
			    } elseif { [info exists path_data(ordered_elements,$down_index)] } {
				unset path_data(ordered_elements,$down_index)
			    }
			}
			# After shifting down all the paths decrement the path index
			incr path_index -1
			incr index -1
		    }
		}
	    }
	}
	return 1
    } else {
	echo "Error: Need to provide one of the following arguments: -all, -name <chain_list>, or -test_mode <test_modes> ..."
	return 0
    }
}
define_proc_attributes remove_ctlgen_path -info "Remove ctlgen path" -define_args {
    {"-all" "Remove All Paths" "" boolean optional}
    {"-name" "Remove Specified Chain" <chain_list> list optional}
    {"-test_mode" "Remove Paths For Specified Test Modes" <test_modes> list optional}
    {"-help" "Print usage information" "" boolean optional}
    {"-man" "Print more detailed usage information" "" boolean optional}
}

######################################################################
#
# Procedure to define a ctlgen test mode
#
######################################################################
proc define_ctlgen_mode {args} {
    parse_proc_arguments -args $args results

    global mode_data mode_index
    global signal_data signal_index
    global man_data

    # Print detailed usage info
    if { [info exists results(-man)] } {
	echo $man_data(define_ctlgen_mode)
	return 1
    }

    # Check for required arguments
    if { ![info exists results(-name)] } {
	echo "Error: Required argument \'-name\' was not found. Disregarding command."
	return 0
    }

    # Do some error checking
    set mode_errors 0

    # Check for duplicate mode name
    for {set index 0} {$index < $mode_index} {incr index} {
	if { $mode_data(name,$index) == $results(-name) } {
	    set mode_errors 1
	    echo "Error: Duplicate mode name. ($results(-name)) already defined, specification ignored."
	    break
	}
    }

    # Mode type is optional, check the value
    if { [info exists results(-type)] } {
	if { ![regexp -nocase {^(Scan|Compression)$} $results(-type)] } {
	    set mode_errors 1
	    echo "Error: Unrecognized mode type value \($results(-type)\)."
	}
    }

    # Check the mode values
    if { [info exists results(-mode_values)] } {
	foreach value $results(-mode_values) {
	    if { ![regexp -nocase {^(0|1)$} $value] } {
		set mode_errors 1
		echo "Error: Unrecognized mode port value \($value\), must be 0 or 1."
	    }
	}
    }

    # Check that the mode_ports list and the mode_values lists are the same length
    if { [info exists results(-mode_ports)] && [info exists results(-mode_values)] } {
	if { [llength $results(-mode_ports)] != [llength $results(-mode_values)] } {
 	    set mode_errors 1
	    echo "Error: The -mode_ports list and -mode_values lists are not the same length."
	}
    } elseif { [info exists results(-mode_ports)] || [info exists results(-mode_values)] } {
	set mode_errors 1
	echo "Error: The -mode_ports and -mode_values options need to be used together."
    }


    # If no errors, put the values in the mode_data record
    if { $mode_errors == 0 } {

	# Put values in mode_data record
	set mode_data(name,$mode_index) $results(-name)

	# Mode type is optional, will use "Scan" as the default
	if { ![info exists results(-type)] || [regexp -nocase {^(Scan)$} $results(-type)]} {
	    set mode_data(type,$mode_index) "Scan"
	} else {
	    set mode_data(type,$mode_index) "Compression"
	    echo "Warning: CTLGEN provides only a basic (and arbitrary) compression mode architecture. Use at your own discretion."
	    echo "         ***** Support of compression modes by CTLGEN may be removed in a future release. *****"
	    echo "         ***** If your flow requires this feature, please contact Synopsys support. *****"
	}   

	echo "Accepted ctlgen test mode: \($results(-name)\), Type: ($mode_data(type,$mode_index))."
	incr mode_index

	# Mode ports/values are optional. They are only used as a shortcut for defining TestMode signals. They don't need to be stored with the mode_data.
	if { [info exists results(-mode_ports)] } {
	    # Check for mode signals, if not defined, call set_ctlgen_signal to define
	    set i 0
	    foreach port $results(-mode_ports) {
		set mode_found 0
		for {set index 0} {$index < $signal_index} {incr index} {
		    if { $signal_data(port,$index) == $port && $signal_data(test_mode,$index) == $results(-name)} {
			set mode_found 1
		    }
		}
		if { $mode_found == 0 } {
		    echo "Warning: Mode signal ($port) not defined as type TestMode in test_mode ($results(-name)), adding signal now .."
		    set_ctlgen_signal -type TestMode -port $port -active_state [lindex $results(-mode_values) $i] -test_mode $results(-name)
		}
		incr i
	    }
	}
	return 1
    } else {
	echo "Error: Mode \($results(-name)\) rejected because of errors ..."
	return 0
    }
}
define_proc_attributes define_ctlgen_mode -info "Define a test mode for ctlgen" -define_args {
    {"-name" "Test Mode Name" <mode_name> string optional}
    {"-type" "Test Mode Type" <Scan|Compression> string optional}
    {"-mode_ports" "Test Mode Ports" <list_of_ports> list optional}
    {"-mode_values" "Values For Mode Ports" <list_of_0/1_values> list optional}
    {"-help" "Print usage information" "" boolean optional}
    {"-man" "Print more detailed usage information" "" boolean optional}
}

######################################################################
#
# Procedure to remove a previously defined test mode
#
######################################################################
proc remove_ctlgen_mode {args} {
    parse_proc_arguments -args $args results

    global mode_data mode_index
    global man_data

    # Print detailed usage info
    if { [info exists results(-man)] } {
	echo $man_data(remove_ctlgen_mode)
	return 1
    }

    # Reset all data
    if { [info exists results(-all)] } {
	echo "Info: All ctlgen modes removed."
	set mode_index 0
	if { [array exists mode_data] } {
	    unset mode_data
	}
	return 1
    } elseif { [info exists results(-name)] } {
	# Go through the mode list for each targetted mode
	foreach mode $results(-name) {
	    for {set index 0} {$index < $mode_index} {incr index} {
		# See if the current port matches one of the ports targetted for removal
		if { $mode == $mode_data(name,$index) } {
		    echo "Info: Removing test_mode \'$mode\' ..."
		    
		    # Check if we are down to the last mode index
		    if { $mode_index <= 1 } {
			# Remove the whole mode array
			if { [array exists mode_data] } {
			    set mode_index 0
			    unset mode_data
			    break
			}
		    } else {
			
			# Move all modes down one position in the indexed data structure
			for {set shift_index [expr {$index + 1}]} {$shift_index < $mode_index} {incr shift_index} {
			    
			    # Set down_index to the index below the shift index
			    set down_index [expr {$shift_index - 1}]
			    
			    # Overwrite the mode at down_index with the shift_index
			    set mode_data(name,$down_index) $mode_data(name,$shift_index)
			    set mode_data(type,$down_index) $mode_data(type,$shift_index)
			}
			# After shifting down all the modes decrement the mode index
			incr mode_index -1
			incr index -1
		    }
		}
	    }
	}
	return 1
    } else {
	echo "Error: Need to provide one of the following arguments: -all or -name <mode_list> ..."
	return 0
    }
}
define_proc_attributes remove_ctlgen_mode -info "Remove ctlgen test mode" -define_args {
    {"-all" "Remove All Test Modes" "" boolean optional}
    {"-name" "Remove Specified Test Modes" <mode_list> list optional}
    {"-help" "Print usage information" "" boolean optional}
    {"-man" "Print more detailed usage information" "" boolean optional}
}

######################################################################
#
# Procedure to report the defined ctlgen test modes
#
######################################################################
proc report_ctlgen_mode {args} {
    parse_proc_arguments -args $args results

    global mode_data mode_index
    global product_version version
    global man_data

    # Print detailed usage info
    if { [info exists results(-man)] } {
	echo $man_data(report_ctlgen_mode)
	return 1
    }

    # Report the test modes
    echo "****************************************"
    echo "Report : ctlgen modes"
    echo "Version: $product_version, (ctlgen: $version)"
    echo "Date   :" [date]
    echo "****************************************"

    # Print the modes
    echo  [format "%-20s %-12s" "Mode" "Type"]
    echo  [format "%-20s %-12s" "-------------------" "-----------"]
    for {set index 0} {$index < $mode_index} {incr index} {
	echo  [format "%-20s %-12s" $mode_data(name,$index) $mode_data(type,$index)]
    }

    return 1
}
define_proc_attributes report_ctlgen_mode -info "Report the ctlgen test modes" -define_args {
    {"-help" "Print usage information" "" boolean optional}
    {"-man" "Print more detailed usage information" "" boolean optional}
}

######################################################################
#
# Procedure to set or report the current ctlgen test mode
#
######################################################################
proc current_ctlgen_mode {args} {
    parse_proc_arguments -args $args results

    global mode_data mode_index
    global current_ctlgen_mode
    global man_data

    # Print detailed usage info
    if { [info exists results(-man)] } {
	echo $man_data(current_ctlgen_mode)
	return 1
    }

    if { $args != "" } {
	if { $args == "all" } {
	    set args "all_dft"
	}
	set current_ctlgen_mode $args
	echo "Info: Setting current CTLGEN test_mode to \'$current_ctlgen_mode\'"
    } else {
	echo "Info: Current CTLGEN test_mode is \'$current_ctlgen_mode\'"
    }

    return 1
}
define_proc_attributes current_ctlgen_mode -info "Set current ctlgen test mode" -define_args {
    {args "Test Mode Name" <mode_name> string optional}
    {"-help" "Print usage information" "" boolean optional}
    {"-man" "Print more detailed usage information" "" boolean optional}
}

######################################################################
#
# Procedure to generate the CTL test model
#
# Note: by default the script works at the current_design level. This 
# how it gets the port information. To base a ctl test model on a
# library cell, use the -library option of ctlgen.
#
######################################################################
proc ctlgen {args} {
    parse_proc_arguments -args $args results

    global version

    global signal_data signal_index
    global path_data path_index
    global mode_data mode_index
    global comp_data

    global current_design
    global test_default_delay
    global test_default_bidir_delay
    global test_default_period
    global test_default_strobe
    global ctlgen_single_clock
    global man_data

    # Print detailed usage info
    if { [info exists results(-man)] } {
	echo $man_data(ctlgen)
	return 1
    }

    # Check for required arguments
    if { ![info exists results(-output)] } {
	echo "Error: Required argument \'-output\' was not found. Disregarding command."
	return 0
    }

    # Setup some variables for the port commands
    set my_date [date]
    set library_path ""
    if { [info exists results(-library)] } {
	set library_path $results(-library)
	regexp {\/([\w\-\.]*)} $library_path match design_name
	set ports_cmd "get_lib_pins $library_path/"
	set in_ports_cmd "get_lib_pins -of_objects $library_path -filter {@port_direction == in}"
	set out_ports_cmd "get_lib_pins -of_objects $library_path -filter {@port_direction == out}"
	set inout_ports_cmd "get_lib_pins -of_objects $library_path -filter {@port_direction == inout}"
    } else {
	set design_name $current_design
	set ports_cmd "get_ports "
	set in_ports_cmd "get_ports \"*\" -filter {@port_direction == in}"
	set out_ports_cmd "get_ports \"*\" -filter {@port_direction == out}"
	set inout_ports_cmd "get_ports \"*\" -filter {@port_direction == inout}"
    }

    # Do some data prep
    if { [info exists results(-library)] } {
	ctlgen_data_prep "library" $ports_cmd
    } else {
	ctlgen_data_prep "design" $ports_cmd
    }
    
    # Get a list of all the modes referenced by signal declarations
    set test_modes {}
    for {set index 0} {$index < $signal_index} {incr index} {
	if { [lsearch -exact $test_modes $signal_data(test_mode,$index)] == -1 } {
	    lappend test_modes $signal_data(test_mode,$index)
	}
    }

    # Do some error checking
    set ctlgen_errors 0

    # Check for the existence of each specified port in the design.
    #Done here becuase we don't know to look in current_design or in a library for the ports until now.
    for {set index 0} {$index < $signal_index} {incr index} {
	if { [sizeof_collection [eval $ports_cmd$signal_data(port,$index)]] == 0 } {
	    echo "Error: The $signal_data(type,$index) port \"$signal_data(port,$index)\" not found, respecify with \"set_ctlgen_signal\" command."
	    incr ctlgen_errors
	}
    }

    # Check that at least one scan signal was specified
    if { $signal_index < 1 } {
	echo "Error: Must specify at least one signal for the test model."
	incr ctlgen_errors
    }

    # Check if any scan chains were specified
    if { $path_index < 1 } {
	echo "Warning: No CTLGEN scan chains were declared for the test model."
    }

    # Check to ensure that no chains have the same ScanDataOut
    set regular_modes {}
    lappend regular_modes "all_dft"
    for {set mindex 0} {$mindex < $mode_index} {incr mindex} {
	set sout_sigs {}
	# See if the mode is a compression mode, if so, skip the check
	if { $mode_data(type,$mindex) == "Compression" } {
	    continue
	}
	lappend regular_modes $mode_data(name,$mindex)
	if { [array exists path_data] } {
	    for {set index 0} {$index < $path_index} {incr index} {
		# Only look at the targeted mode
		if { $mode_data(name,$mindex) != $path_data(test_mode,$index) } {
		    continue
		}
		if { [lsearch $sout_sigs $path_data(scan_data_out,$index)] != -1 } {
		    echo "Error: ScanDataOut ($path_data(scan_data_out,$index)) was used with multiple chains."
		    incr ctlgen_errors
		} else {
		    lappend sout_sigs $path_data(scan_data_out,$index)
		}
	    }
	}
    }

    # Check to ensure that there are the same number of ScanDataIns ScanDataOut and chains in each mode
    foreach mode $test_modes {
	# Don't check all_dft mode
	if { $mode == "all_dft" } {
	    continue
	}
	# Don't check modes with no scan chains
	if { $path_index < 1 } {
	    continue
	}	
	# List of scan ins
	if { [info exists signal_data(sin,$mode)] && [info exists signal_data(sin,all_dft)] } {
	    set sin_list($mode) [lsort [concat $signal_data(sin,$mode) $signal_data(sin,all_dft)]]
	} elseif { [info exists signal_data(sin,$mode)] } {
	    set sin_list($mode) [lsort $signal_data(sin,$mode)]
	} else {
	    set sin_list($mode) [lsort $signal_data(sin,all_dft)]
	}
	# List of scan outs
	if { [info exists signal_data(sout,$mode)] && [info exists signal_data(sout,all_dft)] } {
	    set sout_list($mode) [lsort [concat $signal_data(sout,$mode) $signal_data(sout,all_dft)]]
	} elseif { [info exists signal_data(sout,$mode)] } {
	    set sout_list($mode) [lsort $signal_data(sout,$mode)]
	} else {
	    set sout_list($mode) [lsort $signal_data(sout,all_dft)]
	}
	# List of scan paths
	if { [info exists path_data(names,$mode)] && [info exists path_data(names,all_dft)] } {
	    set path_list($mode) [lsort [concat $path_data(names,$mode) $path_data(names,all_dft)]]
	} elseif { [info exists path_data(names,$mode)] } {
	    set path_list($mode) [lsort $path_data(names,$mode)]
	} else {
	    set path_list($mode) [lsort $path_data(names,all_dft)]
	}
	# Check the lengths
	if { [llength $sin_list($mode)] != [llength $path_list($mode)] || [llength $sout_list($mode)] != [llength $path_list($mode)] } {
	    # Skip Error message for compressed modes
	    if { [regexp -nocase {$mode} $regular_modes]} {
		echo "Error: The \# of ScanDataIns ([llength $sin_list($mode)]) or ScanDataOuts ([llength $sout_list($mode)]) not equal to \# of scan paths ([llength $path_list($mode)]) in mode $mode (plus all_dft)"
	    }
	}
    }

    # If there's no errors, generate the CTL
    if { $ctlgen_errors == 0 } {

	# Check for the existence of a compression mode
	for {set mindex 0} {$mindex < $mode_index} {incr mindex} {
	    # Look for the Compression mode
	    if { $mode_data(type,$mindex) == "Compression" } {
		set comp_data(test_mode) $mode_data(name,$mindex)
	    }
	}
	# If a compression mode is found, get some info about it
	if { [info exists comp_data(test_mode)] } {
	    # Initialize the comp_data variables
	    set comp_data(scan_data_in) {}
	    set comp_data(scan_data_out) {}
	    set comp_data(scan_chains) {}
	    # Get the get external and internal chain counts for compression
	    for {set mindex 0} {$mindex < $mode_index} {incr mindex} {
		if { $mode_data(type,$mindex) == "Compression" } {
		    # Count the compression chains
		    set comp_chains 0
		    for {set i 0} {$i < $path_index} {incr i} {
			# Look for chains in the right mode
			if { $path_data(test_mode,$i) == $mode_data(name,$mindex) || $path_data(test_mode,$i) == "all_dft" } {
			    incr comp_chains
			}
		    }
		    set comp_data(int_chains) $comp_chains
		} else {
		    # Count the external chains
		    set ext_chains 0
		    set comp_data(ext_chains) 0
		    for {set i 0} {$i < $path_index} {incr i} {

			# Ignore si/so for compression mode chains
			if { $path_data(test_mode,$i) == $comp_data(test_mode) } {
			    continue
			}

			# Look for the matching scan_in in the right mode
			if { $path_data(test_mode,$i) == $mode_data(name,$mindex) || $path_data(test_mode,$i) == "all_dft" } {
			    incr ext_chains
			}
			# Build list of external scan_in and scan_outs
			if { [lsearch -exact $comp_data(scan_data_in) $path_data(scan_data_in,$i)] == -1 } {
			    lappend comp_data(scan_data_in) $path_data(scan_data_in,$i)
			}
			if { [lsearch -exact $comp_data(scan_data_out) $path_data(scan_data_out,$i)] == -1 } {
			    lappend comp_data(scan_data_out) $path_data(scan_data_out,$i)
			}
		    }
		    if { $ext_chains > $comp_data(ext_chains) } {
			set comp_data(ext_chains) $ext_chains
		    }
		}
	    }
#	    echo "Comp mode: $comp_data(test_mode)"
#	    echo "Comp int chains: $comp_data(int_chains)"
#	    echo "Comp ext chains: $comp_data(ext_chains)"
	}

	# Default scan style is Mux-D
	set scan_style "muxd"
	# Check for a signal that will indicate a LSSD design
	for {set index 0} {$index < $signal_index} {incr index} {
	    if { [regexp -nocase {ScanSlaveClock} $signal_data(type,$index)] } {
		set scan_style "lssd"
		break
	    }
	}

	# Open output file
	set ctlout [open $results(-output) w+]
	echo "Writing test model file \'$results(-output)\' for \'$design_name\' ..."

	# Print Header section
	puts $ctlout "STIL 1.0 \{\n    CTL P2001.10;\n    Design P2001.01;\n\}"
	puts $ctlout "Header \{\n    Title \"CTL model for '$design_name'\";\n    Date \"$my_date\";"
	puts $ctlout "    Source \"CTLGEN Script, Version: $version\";\n\}"

	# Print Signals section
	puts $ctlout "Signals \{"
	# Input ports
	set in_count 0
	set tmp_count 0
	set in_signals ""
	foreach_in_collection port [eval $in_ports_cmd] {
	    set port_name [regsub -all {[\w\-\.]+\/} [get_object_name $port] ""]
	    # Check for duplicate
	    if { [lsearch $in_signals $port_name] == -1 } {
		puts $ctlout "  \"$port_name\" In;"
		incr in_count
		incr tmp_count
		append in_signals "\"$port_name\""
		append in_signals " + "
		if {$tmp_count == 5} {
		    append in_signals "\n                     "
		    set tmp_count 0
		}
	    }
	}
	# Output ports
	set out_count 0
	set tmp_count 0
	set out_signals ""
	foreach_in_collection port [eval $out_ports_cmd] {
	    set port_name [regsub -all {[\w\-\.]+\/} [get_object_name $port] ""]
	    # Check for duplicate
	    if { [lsearch $out_signals $port_name] == -1 } {
		puts $ctlout "  \"$port_name\" Out;"
		incr out_count
		incr tmp_count
		append out_signals "\"$port_name\""
		append out_signals " + "
		if {$tmp_count == 5} {
		    append out_signals "\n                     "
		    set tmp_count 0
		}
	    }
	}

	# InOut ports
	set inout_count 0
	set tmp_count 0
	set inout_signals ""
	foreach_in_collection port [eval $inout_ports_cmd] {
	    set port_name [regsub -all {[\w\-\.]+\/} [get_object_name $port] ""]
	    # Check for duplicate
	    if { [lsearch $out_signals $port_name] == -1 } {
		puts $ctlout "  \"$port_name\" InOut;"
		incr inout_count
		incr tmp_count
		append inout_signals "\"$port_name\""
		append inout_signals " + "
		if {$tmp_count == 5} {
		    append inout_signals "\n                     "
		    set tmp_count 0
		}
	    }
	}
	
	# If there's a compression mode, declare the Pseudo signals
	if { [info exists comp_data(test_mode)] } {
	    for {set i 0} {$i < $path_index} {incr i} {
		# Look for chains in the right mode
		if { $path_data(test_mode,$i) == $comp_data(test_mode) || $path_data(test_mode,$i) == "all_dft" } {
		    # For each compression chain, there's two Pseudo signals
		    set last_element [expr {$path_data(length,$i) - 1}]
		    puts $ctlout "  \"sc_$path_data(name,$i)_0/SI\" Pseudo;"
		    puts $ctlout "  \"sc_$path_data(name,$i)_$last_element/Q\" Pseudo;"
		}
	    }
	    
	}
	
	puts $ctlout "\}"
	
	# Remove last "+" and white space from the signal lists
	regsub {\s+\+\s+$} $in_signals {} in_signals
	regsub {\s+\+\s+$} $out_signals {} out_signals
	regsub {\s+\+\s+$} $inout_signals {} inout_signals

	# Print SignalGroups section
	puts $ctlout "SignalGroups  \{"
	puts $ctlout "    \"all_inputs\"  = '$in_signals';"
	puts $ctlout "    \"all_outputs\" = '$out_signals';"
	if { $inout_count != 0 } {
	    puts $ctlout "    \"all_bidirectionals\" = '$inout_signals';"
	    puts $ctlout "    \"all_ports\"   = '\"all_inputs\" + \"all_outputs\" + \"all_bidirectionals\"';"
	} else {
	    puts $ctlout "    \"all_ports\"   = '\"all_inputs\" + \"all_outputs\"';"
	}
	puts $ctlout "    \"_pi\"         = '$in_signals';"
	puts $ctlout "    \"_po\"         = '$out_signals';"
	puts $ctlout "\}"

	# Print mode specific SignalGroups section

	# ScanIn ports
	foreach mode $test_modes {
	    if { $mode == "all_dft" } {
		continue
	    }
	    # Don't make si group if no scan chains
	    if { $path_index < 1 } {
		continue
	    }	
	    set tmp_count 0
	    set tot_count 0
	    set sin_signals($mode) ""
	    foreach sin $sin_list($mode) {
		incr tmp_count
		incr tot_count
		append sin_signals($mode) "\"$sin\""
		if {$tot_count != [llength $sin_list($mode)] } {
		    append sin_signals($mode) " + "
		    if {$tmp_count == 5} {
			append sin_signals($mode) "\n                     "
			set tmp_count 0
		    }
		}
	    }
	}

	# ScanOut ports

	foreach mode $test_modes {
	    if { $mode == "all_dft" } {
		continue
	    }
	    # Don't make so group if no scan chains
	    if { $path_index < 1 } {
		continue
	    }	
	    set tmp_count 0
	    set tot_count 0
	    set sout_signals($mode) ""
	    foreach sout $sout_list($mode) {
		incr tmp_count
		incr tot_count
		append sout_signals($mode) "\"$sout\""
		if {$tot_count != [llength $sout_list($mode)] } {
		    append sout_signals($mode) " + "
		    if {$tmp_count == 5} {
			append sout_signals($mode) "\n                     "
			set tmp_count 0
		    }
		}
	    }
	}

	# Print SignalGroups section
	for {set mindex 0} {$mindex < $mode_index} {incr mindex} {
	    puts $ctlout "SignalGroups $mode_data(name,$mindex) \{"
	    if { $path_index > 0 } {
		puts $ctlout "    \"_si\"  = '$sin_signals($mode_data(name,$mindex))' {\n        ScanIn;\n    }"
		puts $ctlout "    \"_so\" = '$sout_signals($mode_data(name,$mindex))' {\n        ScanOut;\n    }"
	    }
	    puts $ctlout "\}"
	}

	# Print ScanStructures section
	# With multiple-modes, each mode will have a ScanStructures section
	if { $path_index > 0 } {
	    for {set mindex 0} {$mindex < $mode_index} {incr mindex} {
		# Track chain count for later
		set chain_count($mode_data(name,$mindex)) 0
		
		# Add mode name to ScanStructures call when there's more than one mode
		if { $mode_index > 1 } {
		    puts $ctlout "ScanStructures $mode_data(name,$mindex) \{"
		} else {
		    puts $ctlout "ScanStructures \{"
		}
		
		# Look for the path (by mode)
		for {set index 0} {$index < $path_index} {incr index} {
		    # Do some prep work on the clock(s)
		    # For scan_master_clock, look for character to signify the clock edge, default is leading edge
		    # A "+" in the middle signifies a "Mixed clock" chain, i.e. launch and capture clocks are provided
		    # "~" and "!" signify a Trailing edge chain, "+" signifies  a "Mixed" chain (negedge followed by posedge)
		    if { [regexp {[\w\[\]\~\!]+\+[\w\[\]\~\!]+} $path_data(scan_master_clock,$index)] } {
			# A "+" in the middle signifies a "Mixed clock" chain
			foreach { capture launch } [split $path_data(scan_master_clock,$index) \+] {break}
			# Do the capture clock
			if { [regexp {^[\!\~].*} $capture] } {
			    regexp {^[\!\~](.*)} $capture match clock_name
			    # A leading "!" or "~" signifies a negedge capture (on ScanDataIn)
			    set clock_data(capture,$index) $clock_name
			    set clock_data(capture_edge,$index) "Trailing"
			} else {
			    set clock_data(capture,$index) $capture
			    set clock_data(capture_edge,$index) "Leading"
			}
			# Do the launch clock
			if { [regexp {^[\!\~].*} $launch] } {
			    regexp {^[\!\~](.*)} $launch match clock_name
			    # A leading "!" or "~" signifies a negedge launch (on ScanDataOut)
			    set clock_data(launch,$index) $clock_name
			    set clock_data(launch_edge,$index) "Trailing"
			} else {
			    set clock_data(launch,$index) $launch
			    set clock_data(launch_edge,$index) "Leading"
			}
			set clock_data(list,$index) "$clock_data(capture,$index)\" \"$clock_data(launch,$index)"
		    } elseif { [regexp {^[\!\~\+]} $path_data(scan_master_clock,$index)] } {
			# If not a mixed clock chain, but special characters are used, get the clock info
			# Get the root clock name and set the launch and capture clocks
			regexp {^[\!\~\+](.*)} $path_data(scan_master_clock,$index) match clock_name
			set clock_data(capture,$index) $clock_name
			set clock_data(launch,$index) $clock_name
			set clock_data(list,$index) $clock_name
			if { [regexp {^[\!\~].*} $path_data(scan_master_clock,$index)] } {
			    # A leading "!" or "~" signifies a negedge chain
			    set clock_data(capture_edge,$index) "Trailing"
			    set clock_data(launch_edge,$index) "Trailing"
			} else {
			    # A leading "+" signifies a "Mixed edge" chain
			    set clock_data(capture_edge,$index) "Trailing"
			    set clock_data(launch_edge,$index) "Leading"
			}
		    } else {
			# If no special characters, set normal values
			set clock_data(capture,$index) $path_data(scan_master_clock,$index)
			set clock_data(launch,$index) $path_data(scan_master_clock,$index)
			set clock_data(capture_edge,$index) "Leading"
			set clock_data(launch_edge,$index) "Leading"
			set clock_data(list,$index) $path_data(scan_master_clock,$index)
		    }
		    
		    set sc_inst ""
		    # If the scan chain in active in that mode or in all_dft, add it
		    if { $path_data(test_mode,$index) == $mode_data(name,$mindex) || $path_data(test_mode,$index) == "all_dft" } {
			incr chain_count($mode_data(name,$mindex))
			puts $ctlout "    ScanChain \"$path_data(name,$index)\" \{"
			puts $ctlout "        ScanLength $path_data(length,$index);"
			if { [info exists path_data(ordered_elements,$index)] } {
			    puts $ctlout "        ScanCells $path_data(ordered_elements,$index);"
			} else {
			    for {set i 0} {$i < $path_data(length,$index)} {incr i} {
				append sc_inst "\"sc_$path_data(name,$index)_$i\" "
			    }
			    puts $ctlout "        ScanCells $sc_inst;"
			}
			# If a compression mode, use the pseudo signals for scan_in/scan_out
			if { [info exists comp_data(test_mode)] && $mode_data(name,$mindex) == $comp_data(test_mode) } {
			    set last_element [expr {$path_data(length,$index) - 1}]
			    puts $ctlout "        ScanIn \"sc_$path_data(name,$index)_0/SI\";"
			    puts $ctlout "        ScanOut \"sc_$path_data(name,$index)_$last_element/Q\";"
			    lappend comp_data(scan_chains) "$path_data(name,$index)"
			} else {
			    puts $ctlout "        ScanIn \"$path_data(scan_data_in,$index)\";"
			    puts $ctlout "        ScanOut \"$path_data(scan_data_out,$index)\";"
			}
			# Specify a scan_enable, if it exists
			if { [info exists path_data(scan_enable,$index)] } {
			    puts $ctlout "        ScanEnable \"$path_data(scan_enable,$index)\";"
			}
			puts $ctlout "        ScanMasterClock \"$clock_data(list,$index)\";"
			if { [info exists path_data(scan_slave_clock,$index)] } {
			    puts $ctlout "        ScanSlaveClock \"$path_data(scan_slave_clock,$index)\";"
			}
			puts $ctlout "    \}"
		    }
		}
		if { [info exists comp_data(test_mode)] && $mode_data(name,$mindex) == $comp_data(test_mode) } {
		    set count 0
		    # Declare the external Scan In pins for compression
		    foreach si $comp_data(scan_data_in) {
			puts $ctlout "    ScanChain \"sccompin$count\" \{\n        ScanIn \"$si\";\n    \}"
			incr count
		    }
		    set count 0
		    # Declare the external Scan Out pins for compression
		    foreach so $comp_data(scan_data_out) {
			puts $ctlout "    ScanChain \"sccompout$count\" \{\n        ScanOut \"$so\";\n    \}"
			incr count
		    }
		    # Declare the internal scan groups for compression
		    puts $ctlout "    ScanChainGroups \{\n        core_group \{"
		    for {set count 0} {$count < $comp_data(int_chains)} {incr count} {
			puts $ctlout [format "            \"%s\";" [lindex $comp_data(scan_chains) $count]]
		    }
		    puts $ctlout "        \}"
		    
		    # Declare the load_group for compression
		    puts $ctlout "        load_group \{"
		    for {set count 0} {$count < [expr {$comp_data(ext_chains) - 0}]} {incr count} {
			puts $ctlout "            \"sccompin$count\";"
		    }
		    puts $ctlout "        \}"
		    # Declare the unload_group for compression
		    puts $ctlout "        unload_group \{"
		    for {set count 0} {$count < [expr {$comp_data(ext_chains) - 0}]} {incr count} {
			puts $ctlout "            \"sccompout$count\";"
		    }
		    puts $ctlout "        \}"
		    # Declare the mode_group for compression
		    puts $ctlout "        mode_group \{"
		    #               # Not declaring modes at this time
		    #		for {set count [expr $comp_data(ext_chains) - 2]} {$count < $comp_data(ext_chains)} {incr count} {
		    #		    puts $ctlout "            \"sccompin$count\";"
		    #		}
		    puts $ctlout "        \}"
		    puts $ctlout "    \}"
		}
		puts $ctlout "\}"
		
		if { [info exists comp_data(test_mode)] && $mode_data(name,$mindex) == $comp_data(test_mode) } {
		    # Declare the decompressor
		    puts $ctlout "CoreType \"${design_name}_SCCOMP_DECOMPRESSOR\" \{\n    Signals \{"
		    for {set count 0} {$count < [expr {$comp_data(ext_chains) - 0}]} {incr count} {
			puts $ctlout "        \"din\[$count\]\" In;"
		    }
		    for {set count 0} {$count < $comp_data(int_chains)} {incr count} {
			puts $ctlout "        \"dout\[$count\]\" Out;"
		    }
		    #		puts $ctlout "        \"sel\[1\]\" In;"
		    #		puts $ctlout "        \"sel\[0\]\" In;"
		    puts $ctlout "    \}\n    SignalGroups  \{\n    \}\n\}"
		    puts $ctlout "CoreInstance \"${design_name}_SCCOMP_DECOMPRESSOR\" \{"
		    puts $ctlout "    \"${design_name}_U_decompressor\";\n\}"
		    
		    # Declare the compressor
		    puts $ctlout "CoreType \"${design_name}_SCCOMP_COMPRESSOR\" \{\n    Signals \{"
		    for {set count 0} {$count < $comp_data(int_chains)} {incr count} {
			puts $ctlout "        \"din\[$count\]\" In;"
		    }
		    for {set count 0} {$count < $comp_data(ext_chains)} {incr count} {
			puts $ctlout "        \"dout\[$count\]\" Out;"
		    }
		    puts $ctlout "    \}\n    SignalGroups  \{\n    \}\n\}"
		    puts $ctlout "CoreInstance \"${design_name}_SCCOMP_COMPRESSOR\" \{"
		    puts $ctlout "    \"${design_name}_U_compressor\";\n\}"
		}
	    }
	}
	
	# Prepare for Timing section by creating strings for "all clocks off" and for "all clocks pulse"
	set clk_off ""
	set clk_pulse ""
	set mo_pulse ""
	for {set index 0} {$index < $signal_index} {incr index} {
	    if { [regexp {(ScanMasterClock|ScanSlaveClock|MasterClock|SlaveClock|ScanClock|Reset)} $signal_data(type,$index)] } {
		foreach { clk_up clk_dwn } $signal_data(timing,$index) {break}
		if { $clk_dwn > $clk_up } {
		    set clock_off($index) 0
		    set clock_active($index) "ForceUp"
		} else {
		    set clock_off($index) 1
		    set clock_active($index) "ForceDown"
		}		    
		append clk_off "\"$signal_data(port,$index)\" = $clock_off($index); "
		# Clock types MasterClock, SlaveClock (functional clocks), and Reset (disturb) are not pulsed during shift
		if {  [regexp {(ScanMasterClock|ScanSlaveClock|ScanClock)} $signal_data(type,$index)] } {
		    append clk_pulse "\"$signal_data(port,$index)\" = P; "
		} else {
		    append clk_pulse "\"$signal_data(port,$index)\" = $clock_off($index); "
		}
		# For master_observe, only the ScanSlaveClock is pulsed
		if { [regexp {(ScanSlaveClock)} $signal_data(type,$index)] } {
		    append mo_pulse "\"$signal_data(port,$index)\" = P; "
		} else {
		    append mo_pulse "\"$signal_data(port,$index)\" = $clock_off($index); "
		}
	    }
	}

	# Print Timing section
	if { $path_index > 0 } {
	    puts $ctlout "Timing  \{\n    WaveformTable \"_default_WFT_\" \{"
	    puts $ctlout [format "        Period '%dns';\n        Waveforms \{" [expr {int($test_default_period)}]]
	    puts $ctlout "            \"all_inputs\" \{"
	    puts $ctlout [format "                01ZN \{ '%dns' D/U/Z/N; \}\n            \}" [expr {int($test_default_delay)}]]
	    puts $ctlout "            \"all_outputs\" \{"
	    puts $ctlout [format "                XHTL \{ '%dns' X/H/T/L; \}\n            \}" [expr {int($test_default_strobe)}]]
	    if { $inout_count != 0 } {
		puts $ctlout "            \"all_bidirectionals\" \{"
		puts $ctlout [format "                01ZN \{ '%dns' D/U/Z/N; \}\n            \}" [expr {int($test_default_bidir_delay)}]]
		puts $ctlout "            \"all_bidirectionals\" \{"
		puts $ctlout [format "                XHTL \{ '%dns' X/H/T/L; \}\n            \}" [expr {int($test_default_strobe)}]]
	    }	    
	    for {set index 0} {$index < $signal_index} {incr index} {
		# Look for clocks and resets to setup the pulse timing
		if { [regexp {(ScanMasterClock|ScanSlaveClock|MasterClock|SlaveClock|ScanClock|Reset)} $signal_data(type,$index)] } {
		    puts $ctlout "            \"$signal_data(port,$index)\" \{"
		    if { $clock_off($index) == "0" } {
			# RTZ waveform
			foreach { clk_up clk_dwn } $signal_data(timing,$index) {break}
			puts $ctlout "                P \{ '0ns' D; '${clk_up}ns' U; '${clk_dwn}ns' D; \}\n            \}"
		    } else {
			# RTO waveform
			foreach { clk_up clk_dwn } $signal_data(timing,$index) {break}
			puts $ctlout "                P \{ '0ns' U; '${clk_dwn}ns' D; '${clk_up}ns' U; \}\n            \}"
		    }
		}
	    }
	    puts $ctlout "        \}\n    \}\n\}"
	}

	# Prepare for the Procedures section by creating strings with "all pi constraints" and "all se ports active"
	# With multiple-modes, each mode will have a ScanStructures section
	for {set mindex 0} {$mindex < $mode_index} {incr mindex} {

	    # Do the pi constraints string. This string is mode dependent
	    set pi_cons($mode_data(name,$mindex)) ""
	    for {set index 0} {$index < $signal_index} {incr index} {
		# Convert signal types Constant and TestMode to effectively "pi constraints"
		if { [regexp {(Constant|TestMode)} $signal_data(type,$index)] } {
		    # Only add the constraint if it's valid in the current mode
		    if { $signal_data(test_mode,$index) == $mode_data(name,$mindex) || $signal_data(test_mode,$index) == "all_dft" } {
			append pi_cons($mode_data(name,$mindex)) "\"$signal_data(port,$index)\" = $signal_data(active_state,$index); "
		    }
		}
	    }
	    # Do the se active string
	    set se_active ""
	    for {set index 0} {$index < $signal_index} {incr index} {
		# Look for all the scan enables
		if { [regexp {(ScanEnable)} $signal_data(type,$index)] } {
		    # Only add the se signal if it's valid in the current mode
		    if { $signal_data(test_mode,$index) == $mode_data(name,$mindex) || $signal_data(test_mode,$index) == "all_dft" } {
			append se_active "\"$signal_data(port,$index)\" = $signal_data(active_state,$index); "
		    }
		}
	    }
	
	    # Print Procedures section
	    if { $path_index > 0 } {
		if { !([info exists ctlgen_single_clock] && $ctlgen_single_clock == "true") } {
		    # Print "multi_clock" capture procedures
		    if { $mode_index > 1 } {
			puts $ctlout "Procedures $mode_data(name,$mindex) \{"
		    } else {
			puts $ctlout "Procedures \{"
		    }
		    # Print capture procedures
		    foreach clock_proc {multiclock_capture allclock_capture allclock_launch allclock_launch_capture} {
			# Add each allclock procedure to the CTL
			puts $ctlout "    \"$clock_proc\" \{\n        W \"_default_WFT_\";"
			if { $pi_cons($mode_data(name,$mindex)) != "" } {
			    puts $ctlout "        F \{ $pi_cons($mode_data(name,$mindex))\}"
			}
			puts $ctlout "        V \{ \"_pi\" = \\r${in_count} \#; \"_po\" = \\r${out_count} \#; \}\n    \}"
		    }
		} else {
		    # Print legacy "single_clock" capture procedures
		    # Add mode name to Procedures call when there's more than one mode
		    if { $mode_index > 1 } {
			puts $ctlout "Procedures $mode_data(name,$mindex) \{\n    \"capture\" \{\n        W \"_default_WFT_\";"
		    } else {
			puts $ctlout "Procedures \{\n    \"capture\" \{\n        W \"_default_WFT_\";"
		    }
		    if { $pi_cons($mode_data(name,$mindex)) != "" } {
			puts $ctlout "        F \{ $pi_cons($mode_data(name,$mindex))\}"
		    }
		    puts $ctlout "        V \{ \"_pi\" = \\r${in_count} \#; \"_po\" = \\r${out_count} \#; \}\n    \}"
		    # Capture procedures
		    for {set index 0} {$index < $signal_index} {incr index} {
			if { [regexp {(ScanMasterClock|ScanSlaveClock|MasterClock|SlaveClock|ScanClock|Reset)} $signal_data(type,$index)] } {
			    # Only add the capture procedure if the port valid in the current mode
			    if { $signal_data(test_mode,$index) == $mode_data(name,$mindex) || $signal_data(test_mode,$index) == "all_dft" } {
				puts $ctlout "    \"capture_$signal_data(port,$index)\" \{\n        W \"_default_WFT_\";"
				if { $pi_cons($mode_data(name,$mindex)) != "" } {
				    puts $ctlout "        F \{ $pi_cons($mode_data(name,$mindex))\}"
				}
				puts $ctlout "        V \{ \"_pi\" = \\r${in_count} \#; \"_po\" = \\r${out_count} \#; \"$signal_data(port,$index)\" = P; \}\n    \}"
			    }
			}
		    }
		}
		# Master observe procedure
		if { $scan_style == "lssd" } {
		    puts $ctlout "    \"master_observe\" {\n        W \"_default_WFT_\";"
		    puts $ctlout "        V { $mo_pulse }\n    }"
		}
		# Load_unload procedure
		puts $ctlout "    \"load_unload\" \{\n        W \"_default_WFT_\";"
		if { $pi_cons($mode_data(name,$mindex)) != "" } {
		    puts $ctlout "        V \{ $clk_off$pi_cons($mode_data(name,$mindex))\"_si\" = \\r$chain_count($mode_data(name,$mindex)) N; \"_so\" = \\r$chain_count($mode_data(name,$mindex)) X; $se_active\}"
		} else {
		    puts $ctlout "        V \{ $clk_off\"_si\" = \\r$chain_count($mode_data(name,$mindex)) N; \"_so\" = \\r$chain_count($mode_data(name,$mindex)) X; $se_active\}"
		}
		puts $ctlout "        Shift \{\n            V \{ $clk_pulse\"_si\" = \\r$chain_count($mode_data(name,$mindex)) \#; \"_so\" = \\r$chain_count($mode_data(name,$mindex)) \#; \}"
		puts $ctlout "        \}\n    \}\n\}"
	    }
	}

	# Print MacroDefs section
	# With multiple-modes, each mode will have a MacroDefs section
	if { $path_index > 0 } {
	    for {set mindex 0} {$mindex < $mode_index} {incr mindex} {
		
		# Add mode name to MacroDefs call when there's more than one mode
		if { $mode_index > 1 } {
		    puts $ctlout "MacroDefs $mode_data(name,$mindex) \{\n    \"test_setup\" \{\n        W \"_default_WFT_\";"
		} else {
		    puts $ctlout "MacroDefs \{\n    \"test_setup\" \{\n        W \"_default_WFT_\";"
		}
		
		if { $inout_count != 0 } {
		    puts $ctlout "        C \{\"all_inputs\" = \\r$in_count N; \"all_outputs\" = \\r$out_count X; \"all_bidirectionals\" = \\r$inout_count N; \}"
		} else {
		    puts $ctlout "        C \{\"all_inputs\" = \\r$in_count N; \"all_outputs\" = \\r$out_count X; \}"
		}
		puts $ctlout "        V \{ $clk_off$pi_cons($mode_data(name,$mindex))\}\n    \}\n\}"
	    }
	}
	
	# Declare CompressorStructures if there is a compession mode
	if { $path_index > 0 } {
	    if { [info exists comp_data(test_mode)] } {
		
		puts $ctlout "CompressorStructures ScanCompression_mode \{"
		puts $ctlout "    ScanStructures ScanCompression_mode;"
		puts $ctlout "    Compressor module_tc_U_decompressor \{"
		puts $ctlout "        ModeGroup mode_group;"
		puts $ctlout "        LoadGroup load_group;"
		puts $ctlout "        CoreGroup core_group;"
		# Only declare 1 mode, for simplicity
		puts $ctlout "        Modes 1;"
		puts $ctlout "        Mode 0 \{"
		puts $ctlout "            ModeControls \{"
		#	    puts $ctlout [format "                \"%s\" =0;" [lindex $comp_data(scan_data_in) [expr {[llength $comp_data(scan_data_in)] - 2}]]]
		#	    puts $ctlout [format "                \"%s\" =0;" [lindex $comp_data(scan_data_in) [expr {[llength $comp_data(scan_data_in)] - 1}]]]
		puts $ctlout "            \}"
		# Make up some arbitrary connections, not trying to emulate the real decompressor connections
		set start 0
		set extra_chain [expr {$comp_data(int_chains) % $comp_data(ext_chains)}]
		for {set count 0} {$count < [expr {$comp_data(ext_chains) - 0}]} {incr count} {
		    if { $count < $extra_chain } {
			set add_chain 1
		    } else {
			set add_chain 0
		    }
		    puts -nonewline $ctlout "            Connection $count"
		    for {set j $start} {$j < [expr {$start + ($comp_data(int_chains) / $comp_data(ext_chains)) + $add_chain}]} {incr j} {
			puts -nonewline $ctlout [format " \"%s\"" [lindex $comp_data(scan_chains) $j]]
			# Remember the decompressor connections to replicate the same connection on the compressor
			set connect($j) $count
		    }
		    set start [expr {$start + ($comp_data(int_chains) / $comp_data(ext_chains)) + $add_chain}]
		    puts $ctlout ";"
		}
		puts $ctlout "        \}\n    \}"
		puts $ctlout "    Compressor ${design_name}_U_compressor \{"
		puts $ctlout "        UnloadGroup unload_group;\n        CoreGroup core_group;\n        Mode \{"
		# Make up some arbitrary connections, not trying to emulate the real compressor connections
		for {set j 0} {$j < $comp_data(int_chains) } {incr j} {
		    puts $ctlout [format "            Connection \"%s\" $connect($j);" [lindex $comp_data(scan_chains) $j]]
		}
		puts $ctlout "        \}\n    \}\n\}"
	    }
	}

	# Print Environment section
	puts $ctlout "Environment \"$design_name\" \{\n    CTL  \{\n    \}"

	# Add all_dft mode declaration to make DFTC happy
	puts $ctlout "    CTL all_dft \{\n        TestMode ForInheritOnly;\n        Internal \{"
	# Check for a ScanEnable signals that specify the "usage" and describe in the "all_dft" section
	for {set index 0} {$index < $signal_index} {incr index} {
	    if { [regexp -nocase {ScanEnable} $signal_data(type,$index)] } {
		if { [info exists signal_data(usage,$index)] } {
		    # If usage data exists put ScanEnable info in all_dft
		    puts $ctlout "            \"$signal_data(port,$index)\" \{"
		    set usage_data ""
		    if { [info exists signal_data(usage,$index)] && $signal_data(usage,$index) == "scan" } {
			append usage_data "User \"ScanEnableForScan\" "
		    }
		    # The extra quotes around the "ScanEnableForClockGating" data type is required by the CTL reader, for some reason
		    if { [info exists signal_data(usage,$index)] && $signal_data(usage,$index) == "clock_gating" } {
			append usage_data "User \"ScanEnableForClockGating\" "
		    }
		    puts $ctlout "                DataType $usage_data\{"
		    if { [info exists signal_data(active_state,$index)] && $signal_data(active_state,$index) == 0 } {
			puts $ctlout "                    ActiveState ForceDown;\n                \}\n            \}"
		    } else {
			puts $ctlout "                    ActiveState ForceUp;\n                \}\n            \}"
		    }
		}
	    }
	}
	puts $ctlout "        \}\n    \}"

	# With multiple-modes, each mode will have a mode defined in the Environment section
	for {set mindex 0} {$mindex < $mode_index} {incr mindex} {
	    puts $ctlout "    CTL $mode_data(name,$mindex) \{\n        TestMode InternalTest;"
	    if { [info exists comp_data(test_mode)] && $mode_data(name,$mindex) == $comp_data(test_mode) } {
		puts $ctlout "        Family SNPS_SCAN_COMPRESSION;"
		puts $ctlout "        Focus Top \{\n        \}"
		puts $ctlout "        Focus CoreInstance \"${design_name}_U_decompressor\" \{"
		puts $ctlout "            TestMode Control;"
		puts $ctlout "            CTL \"${design_name}_U_decompressor\" decompress;\n        \}"
		puts $ctlout "        Focus CoreInstance \"${design_name}_U_compressor\" \{"
		puts $ctlout "            TestMode Control;"
		puts $ctlout "            CTL \"${design_name}_U_compressor\" compress;\n        \}"
	    } else {
		puts $ctlout "        Focus Top \{\n        \}"
	    }
	    puts $ctlout "        Inherit all_dft;"

	    # Add DomainReference call when there's more than one mode
	    puts $ctlout "        DomainReferences \{\n            SignalGroups $mode_data(name,$mindex);"
	    if { $mode_index > 1 } {
		puts $ctlout "            ScanStructures $mode_data(name,$mindex);"
		puts $ctlout "            MacroDefs $mode_data(name,$mindex);"
		puts $ctlout "            Procedures $mode_data(name,$mindex);"
	    }
	    puts $ctlout "        \}\n        Internal \{"
	
	    for {set index 0} {$index < $signal_index} {incr index} {
		
		# If the signal is not active in the current_mode (or all_dft), skip it
		if { $signal_data(test_mode,$index) != $mode_data(name,$mindex) && $signal_data(test_mode,$index) != "all_dft" } {
		    continue
		}

		if { [regexp -nocase {Reset} $signal_data(type,$index)] } {
		    # Resets
		    puts $ctlout "            \"$signal_data(port,$index)\" \{"
		    # If an autofix signal, add TestData
		    if { [info exists signal_data(autofix,$index)] } {
			puts $ctlout "                DataType Reset TestData \{"
		    } else {
			puts $ctlout "                DataType Reset \{"
		    }
		    if { [info exists signal_data(active_state,$index)] && $signal_data(active_state,$index) == 0 } {
			puts $ctlout "                    ActiveState ForceDown;"
		    } else {
			puts $ctlout "                    ActiveState ForceUp;"
		    }
		    puts $ctlout "                \}\n            \}"
		} elseif { [regexp -nocase {Constant} $signal_data(type,$index)] } {
		    # Constants
		    puts $ctlout "            \"$signal_data(port,$index)\" \{"
		    puts $ctlout "                DataType Constant \{"
		    if { [info exists signal_data(active_state,$index)] && $signal_data(active_state,$index) == 0 } {
			puts $ctlout "                    ActiveState ForceDown;"
		    } else {
			puts $ctlout "                    ActiveState ForceUp;"
		    }
		    puts $ctlout "                \}\n            \}"
		} elseif { [regexp -nocase {Expect} $signal_data(type,$index)] } {
		    # Expects
		    puts $ctlout "            \"$signal_data(port,$index)\" \{"
		    puts $ctlout "                DataType Constant \{"
		    if { [info exists signal_data(active_state,$index)] && $signal_data(active_state,$index) == 0 } {
			puts $ctlout "                    ActiveState ExpectLow;"
		    } else {
			puts $ctlout "                    ActiveState ExpectHigh;"
		    }
		    puts $ctlout "                \}\n            \}"
		} elseif { [regexp -nocase {TestMode} $signal_data(type,$index)] } {
		    # TestMode
		    puts $ctlout "            \"$signal_data(port,$index)\" \{"
		    # If an autofix signal, add TestData
		    if { [info exists signal_data(autofix,$index)] } {
			puts $ctlout "                DataType TestMode TestData \{"
		    } else {
			puts $ctlout "                DataType TestMode \{"
		    }
		    if { [info exists signal_data(active_state,$index)] && $signal_data(active_state,$index) == 0 } {
			puts $ctlout "                    ActiveState ForceDown;"
		    } else {
			puts $ctlout "                    ActiveState ForceUp;"
		    }
		    puts $ctlout "                \}\n            \}"
		} elseif { [regexp -nocase {TestData} $signal_data(type,$index)] } {
		    # TestData ???
		} elseif { [regexp -nocase {ScanDataIn} $signal_data(type,$index)] } {
		    # ScanDataIn
		    puts $ctlout "            \"$signal_data(port,$index)\" \{"
		    
		    # Look for the scanin in a path definition to figure out the capture clock
		    for {set i 0} {$i < $path_index} {incr i} {
			# Look for the matching scan_in in the right mode
			if { $path_data(scan_data_in,$i) == $signal_data(port,$index) } {
			    # If a compression mode, take the first matching scan_in, otherwise match the mode as well
			    if { ([info exists comp_data(test_mode)] && $mode_data(name,$mindex) == $comp_data(test_mode)) || ($path_data(test_mode,$i) == $mode_data(name,$mindex)) } {
				puts $ctlout "                CaptureClock \"$clock_data(capture,$i)\" \{"
				puts $ctlout "                    $clock_data(capture_edge,$i)Edge;\n                \}"
				break
			    }
			}
		    }
		    puts $ctlout "                DataType ScanDataIn \{"
		    puts $ctlout "                    ScanDataType Internal;\n                \}"
		    if { $scan_style == "muxd" } {
			puts $ctlout "                ScanStyle MultiplexedData;\n            \}"
		    } else {
			# LSSD
			puts $ctlout "                ScanStyle MultiplexedClock LevelSensitive;\n            \}"
		    }
		} elseif { [regexp -nocase {ScanDataOut} $signal_data(type,$index)] } {
		    # ScanDataOut
		    puts $ctlout "            \"$signal_data(port,$index)\" \{"
		    # Look for the scanout in a path definition to figure out the launch clock
		    for {set i 0} {$i < $path_index} {incr i} {
			# Look for the matching scan_in in the right mode
			if { $path_data(scan_data_out,$i) == $signal_data(port,$index) } {
			    # If a compression mode, take the first matching scan_out, otherwise match the mode as well
			    if { ([info exists comp_data(test_mode)] && $mode_data(name,$mindex) == $comp_data(test_mode)) || ($path_data(test_mode,$i) == $mode_data(name,$mindex)) } {
				puts $ctlout "                LaunchClock \"$clock_data(launch,$i)\" \{"
				puts $ctlout "                    $clock_data(launch_edge,$i)Edge;\n                \}"
				if { [info exists path_data(terminal_lockup,$i)] } {
				    puts $ctlout "                OutputProperty SynchLatch;"
				}
				break
			    }
			}
		    }
		    puts $ctlout "                DataType ScanDataOut \{"
		    puts $ctlout "                    ScanDataType Internal;\n                \}"
		    if { $scan_style == "muxd" } {
			puts $ctlout "                ScanStyle MultiplexedData;\n            \}"
		    } else {
			# LSSD
			puts $ctlout "                ScanStyle MultiplexedClock LevelSensitive;\n            \}"
		    }
		} elseif { [regexp -nocase {ScanMasterClock} $signal_data(type,$index)] } {
		    # ScanMasterClock
		    puts $ctlout "            \"$signal_data(port,$index)\" \{"
		    puts $ctlout "                DataType ScanMasterClock {"
		    puts $ctlout "                    ActiveState $clock_active($index);\n                }\n            \}"
		} elseif { [regexp -nocase {ScanSlaveClock} $signal_data(type,$index)] } {
		    # ScanSlaveClock
		    puts $ctlout "            \"$signal_data(port,$index)\" \{"
		    puts $ctlout "                DataType ScanSlaveClock {"
		    puts $ctlout "                    ActiveState $clock_active($index);\n                }\n            \}"
		} elseif { [regexp -nocase {ScanEnable} $signal_data(type,$index)] } {
		    # ScanEnables
		    # A ScanEnable that is specified for "clock_gating is only to be described in the "all_dft" section
		    if { !([info exists signal_data(usage,$index)] && $signal_data(usage,$index) == "clock_gating") } {
			puts $ctlout "            \"$signal_data(port,$index)\" \{"
			puts $ctlout "                DataType ScanEnable \{"
			if { [info exists signal_data(active_state,$index)] && $signal_data(active_state,$index) == 0 } {
			    puts $ctlout "                    ActiveState ForceDown;\n                \}\n            \}"
			} else {
			    puts $ctlout "                    ActiveState ForceUp;\n                \}\n            \}"
			}
		    }
		} elseif { [regexp -nocase {InOutControl} $signal_data(type,$index)] } {
		    # InOutControl ???
		} elseif { [regexp -nocase {MasterClock} $signal_data(type,$index)] } {
		    # MasterClock
		    puts $ctlout "            \"$signal_data(port,$index)\" \{"
		    puts $ctlout "                DataType MasterClock {"
		    puts $ctlout "                    ActiveState $clock_active($index);\n                }\n            \}"
		} elseif { [regexp -nocase {SlaveClock} $signal_data(type,$index)] } {
		    # SlaveClock
		    puts $ctlout "            \"$signal_data(port,$index)\" \{"
		    puts $ctlout "                DataType SlaveClock;\n            \}"
		} elseif { [regexp -nocase {ScanClock} $signal_data(type,$index)] } {
		    # Scan clocks
		    puts $ctlout "            \"$signal_data(port,$index)\" \{"
		    # If an autofix signal, add TestData
		    if { [info exists signal_data(autofix,$index)] } {
			puts $ctlout "                DataType ScanMasterClock MasterClock TestData \{"
		    } else {
			puts $ctlout "                DataType ScanMasterClock MasterClock \{"
		    }
		    puts $ctlout "                    ActiveState $clock_active($index);\n                \}\n            \}"
		} elseif { [regexp -nocase {IsConnected} $signal_data(type,$index)] } {
		    # IsConnected
		    puts $ctlout "            \"$signal_data(port,$index)\" \{"
		    puts $ctlout "                IsConnected Out \{\n                    Signal \"$signal_data(connected,$index)\";"
		    if { [info exists signal_data(active_state,$index)] && $signal_data(active_state,$index) == 0 } {
			puts $ctlout "                    Transform \{\n                        Invert;\n                    \}"
		    }		    
		    puts $ctlout "                \}"
		    puts $ctlout "                DataType Functional;\n            \}"
		}
	    }
	    puts $ctlout "        \}\n    \}"
	}

	# Add a Mission_mode section to describe Autofix signals
	puts $ctlout "    CTL Mission_mode \{\n        TestMode Normal;"
	puts $ctlout "        Inherit all_dft;"
	puts $ctlout "        Internal \{"
	for {set index 0} {$index < $signal_index} {incr index} {
	    # If an autofix signal, add TestData info
	    if { [regexp -nocase {Reset} $signal_data(type,$index)] && [info exists signal_data(autofix,$index)] } {
		# Resets
		puts $ctlout "            \"$signal_data(port,$index)\" \{"
		puts $ctlout "                DataType Reset TestData Functional \{"
		if { [info exists signal_data(active_state,$index)] && $signal_data(active_state,$index) == 0 } {
		    puts $ctlout "                    ActiveState ForceDown;"
		} else {
		    puts $ctlout "                    ActiveState ForceUp;"
		}
		puts $ctlout "                \}\n            \}"
	    } elseif { [regexp -nocase {TestMode} $signal_data(type,$index)] && [info exists signal_data(autofix,$index)] } {
		# TestMode
		puts $ctlout "            \"$signal_data(port,$index)\" \{"
		puts $ctlout "                DataType TestMode TestData \{"
		if { [info exists signal_data(active_state,$index)] && $signal_data(active_state,$index) == 0 } {
		    puts $ctlout "                    ActiveState ForceDown;"
		} else {
		    puts $ctlout "                    ActiveState ForceUp;"
		}
		puts $ctlout "                \}\n            \}"
	    } elseif { [regexp -nocase {ScanClock} $signal_data(type,$index)] && [info exists signal_data(autofix,$index)] } {
		# Scan clocks
		puts $ctlout "            \"$signal_data(port,$index)\" \{"
		puts $ctlout "                DataType TestData TestClock Functional;\n            \}"
	    }
	}
	puts $ctlout "        \}\n    \}"
	    
	puts $ctlout "\}"
	
	# Print dftSpec section
	puts $ctlout "Environment dftSpec \{\n    CTL  \{\n    \}"
	puts $ctlout "    CTL all_dft \{\n        TestMode ForInheritOnly;\n    \}"
	for {set mindex 0} {$mindex < $mode_index} {incr mindex} {
	    puts $ctlout "    CTL $mode_data(name,$mindex) \{\n        TestMode InternalTest;\n        Inherit all_dft;\n    \}"
	}
	puts $ctlout "    CTL Mission_mode \{\n        TestMode InternalTest;\n        Inherit all_dft;\n    \}\n\}"

	close $ctlout

	# After CTL is generated optionally check the CTL by reading it in are reporting the results
	if { [info exists results(-check)] } {
	    # Report all signal data defined for ctlgen
	    echo "\n****************************************"
	    echo "CTLGEN : Check the generated CTL model"
	    echo "****************************************\n"
	    echo "\nCTLGEN : Read the generated CTL model"
	    if { [info exists results(-library)] } {
		echo "read_test_model -f ctl -design $design_name $results(-output)"
		read_test_model -f ctl -design $design_name $results(-output)
		echo "current_design $design_name"
		current_design $design_name
	    } else {
		echo "read_test_model -f ctl -design $design_name $results(-output)"
		read_test_model -f ctl -design $design_name $results(-output)
	    }
	    echo "\nCTLGEN : Report CTL models"
	    echo "report_test_model"
	    report_test_model
	    echo "\nCTLGEN : Report the existing DFT signals"
	    echo "report_dft_signal -test_mode all -view existing_dft"
	    report_dft_signal -test_mode all -view existing_dft
	    echo "\nCTLGEN : Report the existing scan chains"
	    echo "report_scan_path -test_mode all -view existing_dft -chain all"
	    report_scan_path -test_mode all -view existing_dft -chain all
	}

	return 1
    } else {
	echo "Errors found ($ctlgen_errors) , CTL test model NOT generated."
	return 0
    }
}
define_proc_attributes ctlgen -info "Generate CTL Test Model (ver: $version)" -define_args {
    {"-output" "CTL Output File" <file_name> string optional}
    {"-library" "Create CTL From A Library Cell" <lib_path> string optional}
    {"-check" "Check CTL After Generation" "" boolean optional}
    {"-help" "Print usage information" "" boolean optional}
    {"-man" "Print more detailed usage information" "" boolean optional}
}

######################################################################
#
# Procedure to generate an ATPG netlist
#
# Note: by default the script works at the current_design level. This 
# how it gets the port information. To base a ctl test model on a
# library cell, use the -library option of ctlgen.
#
#
# Note: This procedure is under construction and not ready for use
#
######################################################################
proc write_atpg_netlist {args} {
    parse_proc_arguments -args $args results

    global version

    global signal_data signal_index
    global path_data path_index
    global mode_data mode_index
    global prep_data

    global current_design

    # Check that it is a valid test_mode

    set my_date [date]
    if { [info exists results(-library)] } {
	ctlgen_data_prep "library"
    } else {
	ctlgen_data_prep "design"
    }
    
    # Do some error checking
    set ctlgen_errors 0

    # Check for the existence of each specified port in the design.
    #Done here becuase we don't know to look in current_design or in a library for the ports until now.
    for {set index 0} {$index < $signal_index} {incr index} {
	if { [sizeof_collection [eval $prep_data(ports_cmd)$signal_data(port,$index)]] == 0 } {
	    echo "Error: The $signal_data(type,$index) port \"$signal_data(port,$index)\" not found, respecify with \"set_ctlgen_signal\" command."
	    incr ctlgen_errors
	}
    }

    # If there's no errors, generate the CTL
    if { $ctlgen_errors == 0 } {

	set netout [open $results(-output) w+]
	echo "Writing ATPG netlist \'$results(-output)\' for \'$prep_data(design_name)\' ..."

	# Print module declaration
	puts $netout "module $prep_data(design_name) ("

	# Print port list
	foreach  port $prep_data(port_name) {
	    if { $port == [lindex $prep_data(port_name) end] } {
		puts $netout "               $port );\n"
	    } else {
		puts $netout "               $port,"
	    }
	}

	# Declare the ports
	foreach  port $prep_data(port_name) {
	    # Check for an arrayed port
	    if { [info exists prep_data($port,array_h)] } {
		puts $netout "     $prep_data($port,direction) \[$prep_data($port,array_h):$prep_data($port,array_l)\] $port;"
	    } else {
		puts $netout "     $prep_data($port,direction) $port;"
	    }
	}

    }
    close $netout
}
define_proc_attributes write_atpg_netlist -info "Write ATPG Netlist (ver: $version)" -define_args {
    {"-output" "ATPG Netlist Output File" <file_name> string required}
    {"-library" "Create Netlist For A Library Cell" <lib_path> string optional}
    {"-test_mode" "Test Mode Name" <mode_name> string optional}
    {"-help" "Print usage information" "" boolean optional}
}

######################################################################
#
# Procedure to do some data prep
#
######################################################################
proc ctlgen_data_prep { design_or_lib ports_cmd } {

    global signal_data signal_index
    global path_data path_index
    global mode_data mode_index
    global prep_data
    global current_design

    # Unset first to clear the old prep data
    if { [array exists prep_data] } {
        unset prep_data
    }

    # Check for the existence of a compression mode
    for {set mindex 0} {$mindex < $mode_index} {incr mindex} {
	# Look for the Compression mode
	if { $mode_data(type,$mindex) == "Compression" } {
	    set comp_data(test_mode) $mode_data(name,$mindex)
	}
    }
    # If a compression mode is found, get some info about it
    if { [info exists comp_data(test_mode)] } {
	# Initialize the comp_data variables
	set comp_data(scan_data_in) {}
	set comp_data(scan_data_out) {}
	set comp_data(scan_chains) {}
	# Get the get external and internal chain counts for compression
	for {set mindex 0} {$mindex < $mode_index} {incr mindex} {
	    if { $mode_data(type,$mindex) == "Compression" } {
		# Count the compression chains
		set comp_chains 0
		for {set i 0} {$i < $path_index} {incr i} {
		    # Look for chains in the right mode
		    if { $path_data(test_mode,$i) == $mode_data(name,$mindex) || $path_data(test_mode,$i) == "all_dft" } {
			incr comp_chains
		    }
		}
		set comp_data(int_chains) $comp_chains
	    } else {
		# Count the external chains
		set ext_chains 0
		set comp_data(ext_chains) 0
		for {set i 0} {$i < $path_index} {incr i} {
		    
		    # Ignore si/so for compression mode chains
		    if { $path_data(test_mode,$i) == $comp_data(test_mode) } {
			continue
		    }
		    
		    # Look for the matching scan_in in the right mode
		    if { $path_data(test_mode,$i) == $mode_data(name,$mindex) || $path_data(test_mode,$i) == "all_dft" } {
			incr ext_chains
		    }
		    # Build list of external scan_in and scan_outs
		    if { [lsearch -exact $comp_data(scan_data_in) $path_data(scan_data_in,$i)] == -1 } {
			lappend comp_data(scan_data_in) $path_data(scan_data_in,$i)
		    }
		    if { [lsearch -exact $comp_data(scan_data_out) $path_data(scan_data_out,$i)] == -1 } {
			lappend comp_data(scan_data_out) $path_data(scan_data_out,$i)
		    }
		}
		if { $ext_chains > $comp_data(ext_chains) } {
		    set comp_data(ext_chains) $ext_chains
		}
	    }
	}
	#	    echo "Comp mode: $comp_data(test_mode)"
	#	    echo "Comp int chains: $comp_data(int_chains)"
	#	    echo "Comp ext chains: $comp_data(ext_chains)"
    }

    # Collect some info on the ports for later user
    #
    # prep_data(port): list of all unique ports
    # prep_data(port_name): list of all unique port names
    # prep_data(<port>,direction): direction of the port
    # prep_data(<port>,index_h): MSB of arrayed port
    # prep_data(<port>,index_l): LSB of arrayed port
    foreach_in_collection port [eval ${ports_cmd}*] {
	set porti [regsub -all {[\w\-\.]+\/} [get_object_name $port] ""]
	
	# Save the port in the port list
	lappend prep_data(port) $porti
	
	# See if it's an arrayed port
        if { [regexp {(\w+)\[(\d+)\]} $porti match port_name array] } {
	    if { ![info exists prep_data($port_name,array_h)] } {	
		# If the array_h value doesn't exist, save the port name and initialize the array values
		lappend prep_data(port_name) $port_name
		set prep_data($port_name,array_h) $array
		set prep_data($port_name,array_l) $array
	    } else {
		# If seen this port before, expand the array
		if { $array > $prep_data($port_name,array_h) } {
		    set prep_data($port_name,array_h) $array
		}
		if { $array < $prep_data($port_name,array_l) } {
		    set prep_data($port_name,array_l) $array
		}
	    }
	} else {
	    # If not an arrayed port, the port and port_name are the same
	    set port_name $porti
	    lappend prep_data(port_name) $porti
	}

	# Find the direction of the port
	if { [get_attribute $port port_direction] == "in" } {
	    set direction "input"
	} elseif { [get_attribute $port port_direction] == "out" } {
	    set direction "output"
	} elseif { [get_attribute $port port_direction] == "inout" } {
	    set direction "inout"
	} else {
	    set direction ""
	    echo "Warning: unexpected port direction for port ($porti)."
	}
	# Save the port direction
	set prep_data($porti,direction) $direction
	set prep_data($port_name,direction) $direction
    }
}

# Set man page info

# ctlgen man page
set man_data(ctlgen) "ctlgen - Generate a CTL test model

The ctlgen command is the command that actually generates the CTL test model. It is run after the
test model is described with the set_ctlgen_signal and set_ctlgen_path commands. 

By default ctlgen works at the \"current_design\" level. Therefore the targeting design needs to
be read in and set as the current_design. The target design that is read in doesn't need to be a
complete or functional design. The design is only needed to get the port list. Therefore a
\"black box\" or \"shell\" model of the design will work just as well for the purposes of ctlgen. 

Usage:

 ctlgen               # Generate CTL Test Model (ver: $version)
   -output <file_name>       (CTL Output File)
   \[-library <lib_path>\]     (Create CTL From A Library Cell)
   \[-check\]                  (Check CTL After Generation)
   \[-help\]                   (Print usage information)
   \[-man\]                    (Print more detailed usage information)

Arguments:

-output <file_name>
Specifies the output file for the generated CTL test model. This is a required argument.

\[-library <lib_path>\]
Used when the target for test model generation is a library element and not a design module.
The full path to the library element should be specified.
For example: \"-library <library_name>/<library_element>\".

\[-check\]
This option will optionally \"check\" the generated model by automatically running some DFTC
commands after the model is generated. These commands should demonstrate whether the CTL
model was generated correctly. It's up to the user to inspect the results. The -check option
runs the following commands:
	read_test_model -f ctl -design <design_name> <model_name>
	report_test_model
	report_dft_signal -test_mode all -view existing_dft
	report_scan_path -test_mode all -view existing_dft -chain all

\[-help\]
Print usage information.

Examples:

Generate a CTL test model for a design module and \"check\" the results.
> ctlgen -output ex1.ctl -check

Generate a CTL test model for a library element
> ctlgen -library tsmc18synPtypV180T025/SDFFRX1 -output ex2.ctl
"

# set_ctlgen_signal man page
set man_data(set_ctlgen_signal) "set_ctlgen_signal - Declare a signal for ctlgen

The set_ctlgen_signal command is used to describe a test interface signal to ctlgen. 

Usage:

 set_ctlgen_signal    # Define signal for ctlgen
   -port <port_name>         (Port Name)
   -type <port_type>         (Port Type)
   \[-active_state <0/1>\]     (Active State)
   \[-timing <<LE> <TE>>\]     (Timing Waveform)
   \[-connected <port_name>\]  (Connected Port Name)
   \[-test_mode <mode_name>\]  (Test Mode Name)
   \[-usage <scan|clock_gating>\] (ScanEnable Usage)
   \[-autofix\]                (Autofix Signal)
   \[-help\]                   (Print usage information)
   \[-man\]                    (Print more detailed usage information)

Arguments:

-port <port_name>
The port name of the test signal declared to ctlgen. This is a required argument.

-type <port_type>
The port \"type\" of the test signal declared to ctlgen. This is a required argument. The port
type names are not case sensitive. The types name are the same as found in the set_dft_signal
command. The valid port types are:

	Reset - (CTL has no \"Set\" type, use the \"Reset\" type for \"Set\" signals)
	Constant
	TestMode - (can also use Mode)
	ScanDataIn - (can also use ScanIn)
	ScanDataOut - (can also use ScanOut)
	ScanEnable - (for Mux-D designs)
	ScanClock - (can also use TestClock, for Mux-D designs)
	ScanMasterClock - (for LSSD designs)
	ScanSlaveClock - (for LSSD designs)
	MasterClock - (for LSSD designs)
	SlaveClock - (for LSSD designs)
	IsConnected - (for specifying pass-through signals)
	Expect - (for specifying output signals driven to a constant value)

\[-active_state <0/1>\]
Specifies the active state of the declared port. This argument is optional and is only valid
for the following signal types: ScanEnable, Reset, Constant, TestMode, and IsConnected. If
the -active_state option is omitted; the default active state is \"1\". 

\[-timing <<RE> <FE>>\]
Specifies the timing waveform for clock signals. This argument is optional and is only valid
for the following signal types: ScanMasterClock, ScanSlaveClock, MasterClock, SlaveClock,
ScanClock, and Reset. If the -timing option is omitted; the default timing is 45% and 95% of the
test_default_period variable. The timing is always specified as {<rising_edge> <falling_edge>}.
So if \"rising_edge\" is greater than \"falling_edge\", you get a \"return-to-one\" (RTO)
waveform (off state of \"1\").

\[-connected <port_name>\]
Used is conjunction with the \"IsConnected\" port type. This optional argument specifies the
source of the combinational connection. If there is an inversion between the source and the
output (specified by the -port option), the -active_state should be set to \"0\".

\[-test_mode <mode_name>\]
Specifies the test_mode for the declared signal. This is an optional argument. The default
test_mode is the value of current_ctlgen_mode. The default value of current_ctlgen_mode is
\"Internal_scan\".

\[-usage <scan|clock_gating>\]
Specify the usage of a ScanEnable signal. By default, ScanEnable signals are used for both
scan and for clock_gating. This option can be used to specify that the ScanEnable signal
was implemented with one type of usage. This option can only be used when declaring a
ScanEnable type signal.

\[-autofix\]
Specify that a signal was used by AutoFix. This will cause CTLGEN to create some
additional declarations in the Mission_mode section of the CTL to support automatic
promotion of AutoFix signals in HSS flow. This enables a flow that is in many ways a
corner case. In the vast majority of flows, this option should not be used. This option
is valid only when declaring TestMode, ScanClock, or Reset signals.

\[-help\]
Print usage information.

\[-man\]
Print more detailed usage information (i.e. this info).

Examples:

Declare a scan enable port:
> set_ctlgen_signal -type ScanEnable   -port se -active 1

Declare a scan clock port:
> set_ctlgen_signal -type scanclock    -port clk2 -timing {65 85}

Declare a pass-through port:
> set_ctlgen_signal -type IsConnected  -port clk_out -connected clk
"

# set_ctlgen_path man page
set man_data(set_ctlgen_path) "set_ctlgen_path - Define a scan path for ctlgen

The set_ctlgen_path command is used to define a scan path for the CTL test model. 

Usage:

 set_ctlgen_path      # Define scan path for ctlgen
   -name <chain_name>        (Scan Chain Name)
   \[-scan_data_in <port_name>\] (Scan Chain Input)
   \[-scan_data_out <port_name>\] (Scan Chain Output)
   -length <int>             (Scan Chain Length)
   -scan_master_clock <port_name> (Scan Chain Clock)
   \[-scan_slave_clock <port_name>\] (Scan Chain Clock)
   -scan_enable <port_name>  (Scan Chain Enable)
   \[-ordered_elements <cells>\] (Scan Chain Cells)
   \[-terminal_lockup\]        (Chain Has A Terminal Lockup Latch)
   \[-repeat <int>\]           (Repeat Path Specification)
   \[-test_mode <mode_name>\]  (Test Mode Name)
   \[-help\]                   (Print usage information)
   \[-man\]                    (Print more detailed usage information)

Arguments:

-name <chain_name>
Specifies the name of the chain. Chain names must be unique. This is a required argument.

\[-scan_data_in <port_name>\]
Specifies the scan chain input port for this chain. This option is required for \"Scan\"
test modes and should be omitted for \"Compression\" test modes. If the port declared by
the -scan_data_in option hasn't been declared by set_ctlgen_signal (in the given
test_mode), a message will be reported and ctlgen will automatically declare the port.

\[-scan_data_out <port_name>\]
Specifies the scan chain output port for this chain. This option is required for \"Scan\"
test modes and should be omitted for \"Compression\" test modes. If the port declared by
the -scan_data_out option hasn't been declared by set_ctlgen_signal (in the given
test_mode), a message will be reported and ctlgen will automatically declare the port.

-length <int>
Specifies the length of the declared scan chain. This is a required argument.

-scan_master_clock <port_name>
Specifies the scan master clock for the scan chain. This is a required argument. To
specify a \"negedge\" chain, the <port_name> should be prefixed with a \"~\" or \"!\".
For example: \"~clk\" or \"!clk2\". To specify a \"mixed edge\" chain (both negedge and
posedge elements on a single chain), the <port_name> should be prefixed with a \"+\".
For example: \"+clk\". To specify a \"mixed clock\" chain (multiple clocks on a single
chain), the clocks should be listed with a \"+\" between them. For example \"clk+clk2\".
Only the first (near the SI) and last (near the SO) clocks are significant for the CTL
test model.

\[-scan_slave_clock <port_name>\]
Specifies the scan slave clock for the scan chain. This is an optional argument and
should only be used for LSSD designs.

\[-scan_enable <port_name>\]
Specifies the scan enable port for the scan chain. This is an optional argument and
should only be used for Mux-D designs.

\[-ordered_elements <cells>\]
Specifies an ordered list of cells to use instead of the default ctlgen cell names.
If you choose to use the -ordered_elements option, you should specify the elements
for an entire chain.

\[-terminal_lockup\]
Specifies to add a lockup latch at the end of the specified scan chain. This is an
optional argument.

\[-repeat <int>\]
Specifies to repeat the given scan chain specification <int> number of times. For
example \"-repeat 8\" means a total of 8 chains will be declare by that command.
The chain \"name\" will have a number added to it. If the declared chain name ends
in a number, the number will be increment for each repeated chain declared.  This
optional argument should only be used when declaring Compressed mode chains.

\[-test_mode <mode_name>\]
Specifies the test_mode for the declared scan chain path. This is an optional
argument. The default test_mode is the value of current_ctlgen_mode. The default
value of current_ctlgen_mode is \"Internal_scan\".

\[-help\]
Print usage information.

\[-man\]
Print more detailed usage information (i.e. this info).

Examples:

Declare a scan chain path (Mux-D)
> set_ctlgen_path -name chain_1 -scan_data_in si1 -scan_data_out so1 -length 5 \\\ 
-scan_master_clock clk -scan_enable se

Declare a scan chain path (LSSD)
> set_ctlgen_path -name lssd_chain -scan_data_in si -scan_data_out so -length 50 \\\ 
-scan_master_clock aclk -scan_slave_clock bclk

Declare a compression mode scan chain (with -repeat)
> set_ctlgen_path -name comp -length 27 -scan_master_clock clk -scan_enable se \\\ 
-test_mode ScanCompression_mode -repeat 8
"

# report_ctlgen_signal man page
set man_data(report_ctlgen_signal) "report_ctlgen_signal - Report the signals declared for ctlgen

The report_ctlgen_signal command reports the currently define ctlgen signals. The signals
are reported for every defined ctlgen test_mode. The default test_mode is \"Internal_scan\".
It's recommended to report the signal prior to running ctlgen to ensure they match what is expected. 

Usage:

 report_ctlgen_signal # Report signals for ctlgen
   \[-help\]                   (Print usage information)
   \[-man\]                    (Print more detailed usage information)

Arguments

\[-help\]
 Print usage information.

\[-man\]
Print more detailed usage information (i.e. this info).

Example:

Report the currently defined ctlgen signals
> report_ctlgen_signal
****************************************
Report : ctlgen signals
Version: I-2013.12-SP1, (ctlgen: 1.05)
Date   : Mon Feb 10 11:35:24 2014
****************************************

Defaults: test_default_period = 100.0, test_default_delay = 0.0, test_default_bidir_delay = 0.0, test_default_strobe = 45.0

========================================
TEST MODE: Internal_scan
========================================

Port            Type            Active     Timing    
--------------  --------------  ---------  --------- 
clk             ScanClock       -          {45 95}   
clk2            ScanClock       -          {65 85}   
tm              TestMode        1                    
reset           Reset           1          {45 95}   
se              ScanEnable      1                    
si1             ScanDataIn      -                    
si2             ScanDataIn      -                    
so1             ScanDataOut     -                    
so2             ScanDataOut     -                    
1
"

# report_ctlgen_path man page
set man_data(report_ctlgen_path) "report_ctlgen_path - Report paths declared for ctlgen

The report_ctlgen_path command reports the currently define ctlgen paths. The paths are
reported for every defined ctlgen test_mode. The default test_mode is \"Internal_scan\".
It's recommended to report the paths prior to running ctlgen to ensure they match what
is expected. 

Usage:

 report_ctlgen_path   # Report paths for ctlgen
   \[-help\]                   (Print usage information)
   \[-man\]                    (Print more detailed usage information)

Arguments:

\[-help\]
 Print usage information.

\[-man\]

Print more detailed usage information (i.e. this info).

Example:

Report the declared scan chain paths
> report_ctlgen_path
****************************************
Report : ctlgen scan paths
Version: I-2013.12-SP1, (ctlgen: 1.05)
Date   : Mon Feb 10 11:35:24 2014
****************************************

========================================
TEST MODE: Internal_scan
========================================

Name            Len   ScanDataIn   ScanDataOut  ScanEnable   MasterClock  SlaveClock  
--------------  ----- -----------  -----------  -----------  -----------  ----------- 
chain_1         5     si1          so1          se           clk          -           
chain_2         2     si2          so2          se           clk2         -           
1
"

# remove_ctlgen_signal man page
set man_data(remove_ctlgen_signal) "remove_ctlgen_signal - Remove a ctlgen signal

The remove_ctlgen_signal command is used to remove previously defined ctlgen signals. If
generating multiple CTL test models with ctlgen in the same DC session, it is recommended
to run \"remove_ctlgen_signal -all\" between the runs. 

Usage:

 remove_ctlgen_signal # Remove ctlgen signal
   \[-all\\]                    (Remove All Signals)
   \[-port <port_list>\]       (Remove Specified Port(s))
   \[-test_mode <test_modes>\] (Remove Signals For Specified Test Modes)
   \[-help\]                   (Print usage information)
   \[-man\]                    (Print more detailed usage information)

Arguments:

\[-all\]
Remove all declared port in all modes. This wipes the slate clean as far as the signals
are concerned.

\[-port <port_list>\]
Remove the specified ports. Can be a single port or a list of ports. The ports will be
removed from the test_mode specified with current_ctlgen_mode. Can optionally use the
-test_mode option to explicitly declare which test_mode to remove the signals from.

\[-test_mode <test_modes>\]
When used in conjunction with the -port option, this argument specifies the test_mode
in which to remove the specified port(s). When used by itself, it specifies to remove
all the declared ports for the given test_mode.

\[-help\]
Print usage information.

\[-man\]
Print more detailed usage information (i.e. this info).

Examples:

Remove all ctlgen signals
> remove_ctlgen_signal -all

Remove selected port
> remove_ctlgen_signal -port \{clk clk2 se\}

Remove all ports of a given test_mode
> remove_ctlgen_signal -test_mode Internal_scan
"

# remove_ctlgen_path man page
set man_data(remove_ctlgen_path) "remove_ctlgen_path - Remove a ctlgen path

The remove_ctlgen_path command is used to remove previously defined ctlgen scan paths.
If generating multiple CTL test models with ctlgen in the same DC session, it is
recommended to run \"remove_ctlgen_path -all\" between the runs. 

Usage:

 remove_ctlgen_path   # Remove ctlgen path
   \[-all\]                    (Remove All Paths)
   \[-name <chain_list>\]     (Remove Specified Chain)
   \[-test_mode <test_modes>\] (Remove Paths For Specified Test Modes)
   \[-help\]                   (Print usage information)
   \[-man\]                    (Print more detailed usage information)

Arguments:

\[-all\]
Remove all declared scan chain paths in all modes. This wipes the slate clean as far as
the paths are concerned.

\[-name <chain_list>\]
Remove the specified paths. Can be a single path or a list of scan chain paths. The paths
will be removed from the test_mode specified with current_ctlgen_mode. Can optionally use
the -test_mode option to explicitly declare which test_mode to remove the paths from.

\[-test_mode <test_modes>\]
When used in conjunction with the -port option, this argument specifies the test_mode in
which to remove the specified path(s). When used by itself, it specifies to remove all
the declared paths for the given test_mode.

\[-help\]
Print usage information.

\[-man\]
Print more detailed usage information (i.e. this info).

Examples:

Remove all ctlgen paths
> remove_ctlgen_path -all

Remove selected scan chains
> remove_ctlgen_path -name \{chain_1 chain_2 chain_3\}

Remove all scan chain paths of a given test_mode
> remove_ctlgen_path -test_mode Internal_scan
"

# define_ctlgen_mode man page
set man_data(define_ctlgen_mode) "define_ctlgen_mode - Define a test mode for ctlgen

The define_ctlgen_mode command defines a test mode for ctlgen. It is required to define
the test model with define_ctlgen_mode prior to referring to a test_mode with the
set_ctlgen_signal or set_ctlgen_path commands. This command is only required for
specifying multi-mode test models. The default ctlgen test mode is \"Internal_scan\". 

The \"all_dft\" mode is a special mode that covers all modes. It's used for signals
that have the same specification in all modes. This mode can be abbreviated as \"all\"
in the set_ctlgen_signal and set_ctlgen_path commands.

Usage:

 define_ctlgen_mode   # Define a test mode for ctlgen
   -name <mode_name>         (Test Mode Name)
   \[-type <Scan|Compression>\] (Test Mode Type)
   \[-mode_ports <list_of_ports>\] (Test Mode Ports)
   \[-mode_values <list_of_0/1_values>\] (Values For Mode Ports)
   \[-help\]                   (Print usage information)
   \[-man\]                    (Print more detailed usage information)

Arguments:

-name <mode_name>
Specifies the name of the ctlgen mode. This is a required argument.

\[-type <Scan|Compression>\]
Specifies the type of mode. This is an optional argument. The default is \"Scan\".

\[-mode_ports <list_of_ports>\]
Specifies mode ports associated with the defined ctlgen mode. This is an optional
argument. It is to be used in conjunction with the -mode_values argument. The
set_ctlgen_signal command will be called to declare the mode_ports as type TestMode
for the given test_mode and the mode_value as the active_state.

\[-mode_values <list_of_0/1_values>\]
Specifies mode values associated with the defined ctlgen mode. This is an optional
argument. It is to be used in conjunction with the -mode_ports argument. A value
needs to be declared for each mode_ports specified. 

\[-help\]
Print usage information.

\[-man\]
Print more detailed usage information (i.e. this info).

Examples:

Declare a new scan mode
> define_ctlgen_mode -name single_chain

Declare a new compression mode
> define_ctlgen_mode -name ScanCompression_mode -type Compression

Declare a scan mode with mode values
> define_ctlgen_mode -name my_scan_mode -mode_ports {tm1 tm2} -mode_values {0 1}
"

# remove_ctlgen_mode man page
set man_data(remove_ctlgen_mode) "remove_ctlgen_mode - Remove a ctlgen test mode

The remove_ctlgen_mode command removes a previously defined test mode. 

Usage:

 remove_ctlgen_mode   # Remove ctlgen test mode
   \[-all\]                    (Remove All Test Modes)
   \[-name <mode_list>\]       (Remove Specified Test Modes)
   \[-help\]                   (Print usage information)
   \[-man\]                    (Print more detailed usage information)

Arguments:

\[-all\]
Remove all declared ctlgen modes. This wipes the slate clean as far as the modes are concerned.

\[-name <mode_list>\]
Remove the specified modes. Can be a single mode or a list of modes. 

\[-help\]
Print usage information.

\[-man\]
Print more detailed usage information (i.e. this info).

Examples:

Remove all ctlgen modes
> remove_ctlgen_mode -all

Remove selected mode
> remove_ctlgen_mode -name Internal_scan
"

# report_ctlgen_mode man page
set man_data(report_ctlgen_mode) "report_ctlgen_mode - Report the ctlgen test mode

The report_ctlgen_mode command reports the previously defined ctlgen test modes. 

Usage:

 report_ctlgen_mode  # Report the ctlgen test modes
   \[-help\]                   (Print usage information)
   \[-man\]                    (Print more detailed usage information)

Arguments:

\[-help\]
Print usage information.

\[-man\]
Print more detailed usage information (i.e. this info).

Example:

Report the currently define ctlgen mode
> report_ctlgen_mode
****************************************
Report : ctlgen modes
Version: I-2013.12, (ctlgen: 1.05)
Date   : Mon Feb 10 11:35:24 2014
****************************************
Mode                 Type        
-------------------  ----------- 
scan_mode            Scan        
single_chain         Scan        
1
"

# report_ctlgen_mode man page
set man_data(current_ctlgen_mode) "current_ctlgen_mode - Set or report the current ctlgen test mode

The current_ctlgen_mode command is set to set or to report the current_ctlgen_mode to
be used with the set_ctlgen_signal and set_ctlgen_path commands.

Usage:

 current_ctlgen_mode  # Set current ctlgen test mode
   \[<mode_name>\]             (Test Mode Name)
   \[-help\]                   (Print usage information)
   \[-man\]                    (Print more detailed usage information)

Arguments:

\[<mode_name>\]
The mode name to set as the current mode. The mode must already have been defined using
the define_ctlgen_mode command. This is an optional argument. If no arguments are given,
the command will return the current setting of current_ctlgen_mode. The \"all_dft\" mode
is a special undefined mode that covers all modes. It's used for signals that have the
same specification in all modes. The \"all_dft\" mode can be abbreviated as \"all\" in
the set_ctlgen_signal and set_ctlgen_path commands. 

\[-help\]
Print usage information.

\[-man\]
Print more detailed usage information (i.e. this info).

Examples:

Report the state of current_ctlgen_mode
> current_ctlgen_mode
Info: Current CTLGEN test_mode is \'Internal_scan\'
1

Set the current_ctlgen_mode to \"all_dft\"
> current_ctlgen_mode all_dft
Info: Setting current CTLGEN test_mode to \'all_dft\'
1
"

# Reset CTLGEN data when the script is sourced
if { [info exists new_var_restore] } {
    redirect /dev/null  {set sh_new_variable_message $new_var_restore}
}




# nolint Main

# nolint Line 1386: W Found constant
# nolint Line 1923: N Expr called in expression
# nolint Line 1929: N Expr called in expression
# nolint Line 1947: N Expr called in expression
# nolint Line 2110: N Unescaped close brace
# nolint Line 2165: N Expr called in expression
# nolint Line 2172: N Expr called in expression
# nolint Line 2360: N Unescaped close brace
# nolint Line 2365: N Unescaped close brace
# nolint Line 2384: N Unescaped close brace
# nolint Line 2528: E Wrong number of arguments
# nolint Line 2530: E Wrong number of arguments