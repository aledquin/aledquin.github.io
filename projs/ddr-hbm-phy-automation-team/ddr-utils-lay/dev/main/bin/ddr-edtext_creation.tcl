#!/depot/tcl8.6.3/bin/tclsh8.6
##########################################################################################################################################
# Code to read RDL/MTOP  layer:datatype from stream.layermap file and create *.edtext file with Pin names and coordinates		##
# One/many  GDS files are required for input												##
# Note: uses gds2gdt utility.(GDT-4.0.4 package ) & gds2oasis (ICV package)								##
# Revision history.															##
# 20230128 - Core/Grid/Mem features added (implementation will be done for all scripts simultaneously)					##
# 20221208 - DDR_UTIL_LAY module requirements are implemented										##
# 20220901 - TSMC05/03 map style suppooorted, help  printout option  added								##
# 20210913 - Looking for RDL and if not found then for MTOP. Multi GDS file run corrected. GDS->OAS translation				##
# 20210804 - missing datatype handling corrected											##
# 20210704 - Final (closing) comma  removed												##
# 20210625 - Get GDT or transfer GDS2GDT then create a edtext fil for each input file							##
# 20210625 - Initial version created													##
# Created By : Sergey Chatrchyan : 25 June 2021												##
##########################################################################################################################################

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
    append msg "***** Code to read RDL/MTOP  layer:datatype from stream.layermap file and create .edtext file with Pin names and coordinatese.Translate GDS to OAS"
    append msg "\n\t  Example command lines:\n"
    append msg "\t\t  $PROGRAM_NAME  \[-fab_node <fabNode>\] \n"
    # append msg "\t\t  $PROGRAM_NAME -debug 1000 -verbosity 5 \n"
    append msg "\t\t  $PROGRAM_NAME -h \n"
    append msg "\n\t Valid command line options:\n"
    append msg "\t     -d/debug #       : verbosity of debug messaging.  Not supported\n"
    append msg "\t     -v/verbosity #   : verbosity of user messaging. Not supported\n"
    append msg "\t     -fab_node <node> : specifies the advanced fab node (currently tsmc05 (TS05 or TS04) or tsmc03 (TS03)\n"
    append msg "\t     -cores       	: CPU core number\n"
    append msg "\t     -grid        	: run on grid if given\n"
    append msg "\t     -mem 	   	: booked memory size in Gb\n"
    append msg "Contact info: Sergey Chatrchyan (sergeych)"
    puts $msg
    return $msg
}

proc process_cmdline {} {

    set parameters {
        {verbosity.arg 	"0" 	"verbosity"}
        {v.arg  	"0" 	"verbosity"}
        {debug.arg 	"0" 	"debug"}
        {d.arg  	"0" 	"debug"}
        {h             		"help message"}
        {fab_node.arg	""	"tsmc05 or tsmc03"}
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
    global cores
    global grid
    global mem


    set VERBOSITY [get_max_val $options(verbosity) $options(v)]
    set DEBUG [get_max_val $options(debug) $options(d)]

    set opt_help    $options(h)
    set fab_node    $options(fab_node)
    set cores    	$options(cores)
    set grid    	$options(grid)
    set mem    		$options(mem)

    dprint 1 "help value      : $opt_help"
    dprint 1 "debug value     : $DEBUG"
    dprint 1 "verbosity value : $VERBOSITY"
    dprint 1 "fab_node        : $fab_node"
    dprint 1 "cores           : $cores"
    dprint 1 "grid            : $grid"
    dprint 1 "mem             : $mem"

    if { $opt_help } {
        showUsage
        myexit 0
    }

    return true
}

proc Main {} {
    global PROGRAM_NAME
    global RealBin
    global opt_help
    global fab_node
    global cores
    global grid
    global mem

    process_cmdline

    if {![info exists fab_node]} {
        set RDLNAME "RDL"
        set PURPOSE "label"
    } else {
        if { [string match -nocase "tsmc05*" $fab_node] || [string match  -nocase "tsmc03*" $fab_node] } {
            iprint "TSMC 5nm MAP STYLE is used !"
            set RDLNAME "AP"
            set PURPOSE "pin"
        } else {
            set RDLNAME "RDL"
            set PURPOSE "label"
        }
    }
    set MTOPNAME "MTOP"
    set PATH2STREAM "."
    set STREAMFILENAME "stream.layermap"
    set TEXTGDS "gdt"
    set GDSII   "gds"
    set OASIS   "oas"
    set PATH2GDT "$RealBin/../lib/tcl/GDT-4.0.4"
    set GDTSCRIPT "gds2gdt.Linux"
    set EDTEXT "edtext"

    set RDLfound 0
    set MTOPfound 0
    set streamFile $PATH2STREAM/$STREAMFILENAME

    set mapSearchExpr $PURPOSE
    append mapSearchExpr {\s+(\d+)\s+(\d+).*}
    set rdlSearch {^(}
    append rdlSearch $RDLNAME
    append rdlSearch {)\s+}
    append rdlSearch $mapSearchExpr
    set mtopSearch {^(}
    append mtopSearch $MTOPNAME
    append mtopSearch {)\s+}
    append mtopSearch $mapSearchExpr

    set layF [read_file $streamFile]
    set stream [split $layF "\n"]  
    foreach line $stream {
        if {[regexp $rdlSearch $line all RDLlayerName RDLlayerNumber RDLdataType] } {
            set RDLfound 1
            break
        }
    }
    if { $RDLfound ==1} {
        iprint "$RDLlayerName $RDLlayerNumber $RDLdataType"
    } else {
        iprint "$RDLNAME : $PURPOSE is not Found in layerMap file! Try to change a fab_node."
    }

    foreach line $stream {
        if {[regexp $mtopSearch $line all MTOPlayerName MTOPlayerNumber MTOPdataType] } {
            set MTOPfound 1
            break
        }
    }
    if { $MTOPfound ==1} {
        iprint "$MTOPlayerName $MTOPlayerNumber $MTOPdataType"
    } else {
        iprint "$MTOPNAME : $PURPOSE is not Found in layerMap file! Try to change a fab_node."
    }

    set inputFileListGDT [glob -types f -nocomplain *.$TEXTGDS]
    if { [ llength ${inputFileListGDT} ]  < 1 } {
        set inputFileListGDS [glob -types f -nocomplain *.$GDSII]
        if { [ llength ${inputFileListGDS} ]  < 1 } {
            fatal_error "No .$TEXTGDS or .$GDSII  files were detected! Exit."
        } else {
            iprint "$GDSII files are  detected: ${inputFileListGDS}\n"
            set inputFileExt 0
            foreach removeExth $inputFileListGDS {
                set fileName [file rootname $removeExth]
                append inputFileList " $fileName"
            }
            foreach fileInput ${inputFileList} {
                set scriptReturn [list bash -c "source ~/.bashrc; $PATH2GDT/$GDTSCRIPT $fileInput.$GDSII $fileInput.$TEXTGDS"]
                run_system_cmd $scriptReturn 2
            	iprint "$fileInput file preparation is done. Wait until the OASIS file is created"
                lappend  inputFileListGDT " $fileInput.$TEXTGDS"
            }
        }
    } else {
        iprint "$TEXTGDS files are detected: ${inputFileListGDT}\n"
        set inputFileExt 1
        foreach removeExth $inputFileListGDT {
            set fileName [file rootname $removeExth]
            append inputFileList " $fileName"
        }
    }
    if { [llength ${inputFileList}] != 0 } {
        write_file ./FileNames "${inputFileList}\n"
    }
##    iprint  ${inputFileList}
    foreach gdsName $inputFileList {
        set gdtFile $gdsName.$TEXTGDS
        set outFile $gdsName.$EDTEXT
        if { [check_file $gdtFile r] } {
	        set gdtF [open $gdtFile]
    	} else { 
	        fatal_error "No .$gdtFile files exist! Exit."
    	}
        if {[file exists $outFile]} {
            file delete $outFile
        }
        set textString ""
        iprint "$gdsName file is running"
        while {-1 != [gets $gdtF line]} {
           if {![string match "t\{*" $line]} {
                continue
            }    		    
            if  {[regexp {^t\{(\d+)\s+.*tt(\d+)\s+.*xy\(([\-.0-9]+)\s+([\-.0-9]+)\)\s+'(\S+)'.*\}} $line all t1 t2 x y t4] } {
                if { $t1 == $RDLlayerNumber && $t2 == $RDLdataType } {
                    if { $textString != "" } {
	            		write_file ./$outFile "$textString ," a+
                    }
                    set textString "{\"$gdsName\", \"$t4\", $t1 , $t2, $x , $y }"
                } elseif { $t1 == $MTOPlayerNumber && $t2 == $MTOPdataType } {
                    if { $textString != "" } {
            			write_file ./$outFile "$textString ," a+
                    }
                    set textString "{\"$gdsName\", \"$t4\", $t1 , $t2, $x , $y }"
                } else {
                    #		puts "RDL or MTOP are not found"
                }
            } elseif {[regexp {^t\{(\d+)\s+.*xy\(([\-.0-9]+)\s+([\-.0-9]+)\)\s+'(\S+)'.*\}} $line all t1 x y t4] } {
                if { $t1 == $RDLlayerNumber} {
                    if { $textString !="" } {
			            write_file ./$outFile "$textString ," a+
                    }
                    set textString "{\"$gdsName\", \"$t4\", $t1 , 0, $x , $y }"
                } elseif { $t1 == $MTOPlayerNumber} {
                    if { $textString !="" } {
            			write_file ./$outFile "$textString ," a+
                    }
                    set textString "{\"$gdsName\", \"$t4\", $t1 , 0, $x , $y }"
                } else {
                    #		puts "RDL or MTOP are not found"
                }
            }
        }
    	write_file ./$outFile "$textString" a+
    } 
    foreach gdsName $inputFileList {
	set cmd [list bash -c "source ~/.bashrc; module unload icvwb; module load icvwb; gds2oasis  $gdsName.$GDSII $gdsName.$OASIS"]
        run_system_cmd $cmd 2
        file delete {*} [glob -nocomplain $gdsName.$TEXTGDS]
        iprint "File $gdsName.$TEXTGDS is deleted"
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

# nolint utils__script_usage_statistics
# it is included in header
# nolint Line 269: N Standalone