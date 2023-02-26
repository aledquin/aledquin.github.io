#!/depot/tcl8.6.6/bin/tclsh
##################################################################################################################################################
# Code to merge the PYDB databases from net_tracer & missingPin sub_folders.Should be run after ddr-net_tracer.tcl & ddr-missing_pins.tcl 	##
# One/many  GDS files are required for input:-cell "list of Top cell names" , Read from file  FileNames						##
# Note: uses icv_pydb utility. ICV module is loaded automaticly within script									##
# Revision history.																##
# 20230125 - DDR_UTIL_LAY module requirements are implemented, Use  "" for multiple top cell names, 						##
#	     ICV tool version grabbed from already generated .vue files in nettracer and missing pins						##
# 20211007 - allow to define multiple databases for merging (expand the list MERGINGDIRS) 							##
# 20211005 - read dir names from current folder and use these names for merging (default) or 							##
#	     the folder names can be define in the command line											##
# 20210930 - ,vue fileconent is corrected.Now vue file can be loaded from current/oas dir							##
# 20210925 - Initial version created														##
# Created By : Sergey Chatrchyan : 25 September 2021												##
##################################################################################################################################################

#--------------------------------------------------------------------#
set VERSION "2022ww35" ;
#--------------------------------------------------------------------#

package require try         ;# Tcllib.
package require cmdline 1.5 ;# First version with proper error-codes.
package require fileutil

set DEBUG      0
set VERBOSITY  0
set STDOUT_LOG ""
set AUTHOR     "Sergey Chatrchyan (sergeych), Patrick Juliano (juliano), Alvaro Quintana Carvacho"
set RealBin [file dirname [file normalize [info script]] ]
set RealScript [file tail [file normalize [info script]] ]
set PROGRAM_NAME $RealScript
set LOGFILE "[pwd]/$PROGRAM_NAME.log"

# Declare cmdline opt vars here, so they are global
set opt_help ""

if {[file isdirectory "$RealBin/../lib/tcl"]} {
    lappend auto_path "$RealBin/../lib/tcl"
} else {
    set SHELLTOOL_LOC "/remote/cad-rep/msip/tools/Shelltools"
    lappend auto_path "$SHELLTOOL_LOC/ddr-utils-lay/dev/lib/tcl"
    set RealBin       "$SHELLTOOL_LOC/ddr-utils-lay/dev/bin"
}
##lappend auto_path "$RealBin/../bin"
##lappend auto_path "$RealBin/../lib/tcl"

package require Messaging 1.0
namespace import ::Messaging::*
package require Misc 1.0
namespace import ::Misc::*

#-----------------------------------------------------------------
# Show the script usage details to the user
#-----------------------------------------------------------------
proc showUsage {} {
    global PROGRAM_NAME
    set msg "\nUsage:  $PROGRAM_NAME "
    append msg "***** Script to merge the PYDB databases from net_tracer & missingPin sub_folders."
    append msg "\n\t  Example command lines:\n"
    append msg "\t\t  $PROGRAM_NAME  \[-cell <Gtop cell name>\] \[-icv_version <version>\] \[-grid\] \[-cores <cores>\] \[-mem <memory>\]\n"
    append msg "\t\t  $PROGRAM_NAME -h \n"
    append msg "\n\t Valid command line options:\n"
    append msg "\t     -d/debug #       : verbosity of debug messaging.  Not supported\n"
    append msg "\t     -v/verbosity #   : verbosity of user messaging. Not supported\n"
    append msg "\t     -cell        	: top cell name\n"
    append msg "\t     -cores       	: CPU core number\n"
    append msg "\t     -grid        	: run on grid if given\n"
    append msg "\t     -mem 	   	: booked memory size in Gb\n"
    append msg "Contact info: Sergey Chatrchyan (sergeych)"
    puts $msg
    return $msg
}

proc process_cmdline {} {

    set parameters {
        {verbosity.arg  	"0"    		"verbosity"}
        {v.arg          	"0"    		"verbosity"}
        {debug.arg      	"0"    		"debug"}
        {d.arg          	"0"    		"debug"}
        {h                     			"help message"}
        {cell.arg       	""     		"top-cell name"}
        {cores.arg      	"1"  	  	"number of CPU cores"}
        {grid                  			"run on grid if defined"}
        {mem.arg        	"50G"  		"memory requested"}
    }
    set usage {showUsage}
    try {
        array set options [::cmdline::getoptions ::argv $parameters $usage ]
        # test: iprint [array names options]
    } trap {CMDLINE USAGE} {msg o} {
        # Trap the usage signal, print the message, and exit the application.
        # Note: Other errors are not caught and passed through to higher levels!
        eprint "Invalid Command line options provided!"
        showUsage
        myexit 1
    }

    global VERBOSITY
    global DEBUG
    global opt_help
    global fab_node
    global bot_metal
    global cell
    global cores
    global grid
    global mem

    set VERBOSITY [get_max_val $options(verbosity) $options(v)]
    set DEBUG [get_max_val $options(debug) $options(d)]

    set opt_help    	$options(h)
    set cell    	$options(cell)
    set cores    	$options(cores)
    set grid    	$options(grid)
    set mem    		$options(mem)

    dprint 1 "debug value     : $DEBUG"
    dprint 1 "verbosity value : $VERBOSITY"
    dprint 1 "help value      : $opt_help"
    dprint 1 "cell            : $cell"
    dprint 1 "cores           : $cores"
    dprint 1 "grid            : $grid"
    dprint 1 "mem             : $mem"

    if { $opt_help } {
        showUsage
        myexit 0
    }

    return true
}

#-----------------------------------------------------------------
# Code
#-----------------------------------------------------------------

proc Main {} {
    global PROGRAM_NAME
    global RealBin
    global opt_help
    global cell
    global cores
    global grid
    global mem

    process_cmdline
    set READFILENAMES "RunDir"
    set MERGINGDIRS {"missing_Pin" "net_tracer"}
    set PYDB_large "PYDB"
    set PYDB_small "pydb"
    set MERGED "merged_PYDB"
    set VUE ".vue"
    set OAS ".oas"
    if {[info exists grid]} {
        set grid "qsub -P bnormal -A quick -pe mt $cores -l mem_free=${mem},h_vmem=$mem -cwd -V"
    } else {
        set grid ""
    }
    if {$cell == ""} {
        set runDirs [glob -nocomplain -directory ./ -types d *]
        foreach dirName $runDirs {
            write_file ./$READFILENAMES [split [string trim "$dirName" "./"] ] a+
        }
    } else {
        write_file ./$READFILENAMES "$cell" w
    }
    ## Merging PYDB from netTracer and missingPins (can be expanded for any number of runsets)
    if {[file exists $READFILENAMES] && [file size $READFILENAMES] != 0} {
        set layF [read_file $READFILENAMES]
        foreach cellName [split [string trim $layF ] ] {
            iprint "Merging $PYDB_large for layout: $cellName"
            set icvVersion ""
            set cmdLine "icv_pydb"
            foreach mergingNames $MERGINGDIRS {
                lappend cmdLine  "-i"
                set tempPath [file join "./" $cellName $mergingNames run_details $PYDB_small $PYDB_large\_$cellName]
                lappend cmdLine $tempPath
                ## get ICV tool version here
                set layR [read_file  [file join "./" $cellName $mergingNames $cellName$VUE] ]
                set stream [split $layR "\n"]
                foreach line $stream {
                    if  {[regexp -nocase {^ICV_HOME_DIR\s+=\s+/global/apps/icv_([\-.0-9SP]+)} $line all version] } {
                        set icvVersion /$version
                        continue
                    }
                }
            }
            iprint "ICV Tool version is $icvVersion"
            lappend cmdLine  "-o"
            set outputPath [file join "./" $cellName $MERGED run_details $PYDB_small $PYDB_large\_$cellName]
            lappend cmdLine $outputPath
            lappend cmdLine "-vue"
            set outputVUE  [file join "./" $cellName$VUE]
            lappend cmdLine $outputVUE
            set cmd [list bash -c "source ~/.bashrc; module unload icv; module load icv$icvVersion; $cmdLine >temp" ]
            run_system_cmd $cmd 2
            file delete ./temp -force
        }
    } else {
        fatal_error "$READFILENAMES not found. Merging not possible!"
    }
    ## Post-processing of VUE file
    if {[file exists $READFILENAMES] && [file size $READFILENAMES] != 0} {
        set layF [read_file $READFILENAMES]
        foreach cellName [split [string trim $layF] ] {
            set layR [read_file  $cellName$VUE]
            set stream [split $layR "\n"]
            foreach line $stream {
                if { [string match "*INLIB *" $line ] } {
                    set line [regsub -all {../../} $line {./}]
                }
                write_file $cellName$VUE.tmp "$line" a+
            }
            file rename -force "$cellName$VUE.tmp" "$cellName$VUE"
        }
    } else {
        fatal_error "$READFILENAMES.$VUE not found!"
    }
    return 0
}

try {
    header
    set exitval [Main]
} on error {results options} {
    set exitval [fprint [dict get $options -errorinfo]]
} finally {
    footer
    write_stdout_log $LOGFILE
}
myexit $exitval
# monitor usage is in header
# nolint utils__script_usage_statistics