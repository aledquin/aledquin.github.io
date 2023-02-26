#!/depot/tcl8.6.3/bin/tclsh8.6

##########################################################################################################################################
# Code to detect floating & dangling nets based on Net Connectivity startiong from MIPLAST                      			##
# Revision history.                                                         								##
# 20230128 - Check stream map link/file exist and use that one. define layout format by layout extention				##
# 20221210 - DDR_UTIL_LAY module requirements are implemented                                       					##
# 20221210 - Metal resistor cut is added for the tracing nets                                       					##
# 20210225 - Added TSMC05 & TSMC03 layer map support. Use additional option in command line:  -fab_node tsmc05[*] or tsmc03[*]      	##
# 20210126 - dummy shapes are excluded from checks                                          						##
# 20210111 - Option -nets  now is corrected.                                                						##
# 20201208 - Script catchs any metal shapes from MIPLAST till MTOP with missing VIA between all intermediate layers.            	##
#       "AllNets" name is used for tracing MINT*, MTOP* layers.                                 					##
#       Fixed net names are used for MIPLAST                                            						##
# 20201109 - Added default Pin names list (MIPLAST), separated as stand-alone script                            			##
# 20201102 - Started from exec_net_trace. Added missing Pin Connection support, " " replaced with "_" in nettrace _M/RDL ouptut     	##
# Created By : Sergey Chatrchyan : 20 November'2020                                         						##
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
    append msg "***** Script to trace metal shapes with missing VIA connection to top or bottom metal.By default a CKT net names are used for net labeling."
    append msg "\n\t  Example command lines:\n"
    append msg "\t\t  $PROGRAM_NAME -layout <GDS/OAS file> -cell <cellname> -layermap <layermap file> -layout_format <GDS|OAS> -bot_metal <lowest metal number to include for connectivity> \[-icv_version <version>\] \[-grid\] \[-cores <cores>\] \[-mem <memory>\] \[-fab_node <fabNode>\]\[-nets \"<net1> <net2> ...\"\]"
    append msg "\t\t\t\t    \[-edtext <edtext file>\] \[-text_depth <depth, where 0 is top>\]\n"
    append msg "\t\t  $PROGRAM_NAME -h \n"
    append msg "\n\t Valid command line options:\n"
    append msg "\t     -d/debug #       : verbosity of debug messaging.  Not supported\n"
    append msg "\t     -v/verbosity #   : verbosity of user messaging. Not supported\n"
    append msg "\t     -layout      	: input design file name\n"
    append msg "\t     -cell            : top cell name\n"
    append msg "\t     -layout_format   : input file format GDS|OAS\n"
    append msg "\t     -layermap    	: layermap file name with the path\n"
    append msg "\t     -bot_metal       : MIPLAST metal number\n"
    append msg "\t     -fab_node    	: advanced node name tsmc05|tsmc03 \n"
    append msg "\t     -nets        	: traced net names list (PG & Signals)\n"
    append msg "\t     -text_depth      : hierarchy level of looking for net names\n"
    append msg "\t     -edtext      	: File name with label coordinates\n"
    append msg "\t     -cores           : CPU core number\n"
    append msg "\t     -grid            : run on grid if given\n"
    append msg "\t     -icv_version     : ICV tool version  if specific one is needed\n"
    append msg "\t     -mem         	: booked memory size in Gb\n"
    append msg "Contact info: Sergey Chatrchyan (sergeych)"
    puts $msg
    return $msg
}

proc process_cmdline {} {

    set parameters {
        {verbosity.arg      "0"         "verbosity"}
        {v.arg              "0"         "verbosity"}
        {debug.arg          "0"         "debug"}
        {d.arg              "0"         "debug"}
        {h                              "help message"}
        {fab_node.arg                   "TSMC advanced node tsmc05 or tsmc03"}
        {bot_metal.arg      "1"         "bottom_metal"}
        {cell.arg           ""          "top-cell name"}
        {cores.arg          "1"         "number of CPU cores"}
        {edtext.arg         ""      	"input File with label coordinates"}
        {layout.arg         ""      	"input GDS/OASIS file"}
        {layout_format.arg  "OAS"       "OAS/GDS"}
        {grid                           "run on grid if defined"}
        {icv_version.arg        ""      "ICV tool version"}
        {layermap.arg           ""      "path to streamout.layermap file"}
        {mem.arg            "50G"       "memory requested"}
        {nets.arg               "VSS VDDQ VDDQLP VSH VDD VAA VAA_VDD2H VDD2H VDDRHV BP* VIO_* PAD* Pclk* PwrOk* Vref*"      "tracing net names"}
        {text_depth.arg     "0"         "hierarchy level for net names"}
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
    global edtext
    global layout
    global layout_format
    global grid
    global icv_version
    global layermap
    global mem
    global nets
    global text_depth

    set VERBOSITY [get_max_val $options(verbosity) $options(v)]
    set DEBUG [get_max_val $options(debug) $options(d)]

    set opt_help        $options(h)
    set fab_node        $options(fab_node)
    set bot_metal       $options(bot_metal)
    set cell        	$options(cell)
    set cores       	$options(cores)
    set edtext      	$options(edtext)
    set layout      	$options(layout)
    set layout_format   $options(layout_format)
    set grid        	$options(grid)
    set icv_version     $options(icv_version)
    set layermap        $options(layermap)
    set mem         	$options(mem)
    set nets        	$options(nets)
    set text_depth      $options(text_depth)

    dprint 1 "debug value     : $DEBUG"
    dprint 1 "verbosity value : $VERBOSITY"
    dprint 1 "help value      : $opt_help"
    dprint 1 "fab_node        : $fab_node"
    dprint 1 "bot_metal       : $bot_metal"
    dprint 1 "cell            : $cell"
    dprint 1 "cores           : $cores"
    dprint 1 "edtext          : $edtext"
    dprint 1 "grid            : $grid"
    dprint 1 "icv_version     : $icv_version"
    dprint 1 "layermap        : $layermap"
    dprint 1 "mem             : $mem"
    dprint 1 "nets            : $nets"
    dprint 1 "text_depth      : $text_depth"

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
    global bot_metal
    global cell
    global cores
    global edtext
    global layout
    global layout_format
    global grid
    global icv_version
    global layermap
    global mem
    global nets
    global text_depth

    process_cmdline

    # Process arguments and set variables.
    set script_name $PROGRAM_NAME
    set runset_name missing_Pin
    set allNets "AllNets"

    if {$cell == ""} {
        fatal_error "Top Cell name is not provided!"
    }
    if { ![file exists $layout]} {
        fatal_error "Layout file is not provided!"
    } else {
        set layout $layout
        ## Get extention and assign to layout format
        if  { [string match -nocase "*oas*" $layout]} {
            set layFormat "OASIS"
        } elseif { [string match -nocase "*gds*" $layout]} {
            set layFormat "GDSII"
        } else {
            fatal_error "Layout format is not recognized/specified!"
        }
    }
    ## This If block is kept for a backward compatibility
    if {(![info exists layout_format]) || ($layout_format == "GDS")} {
        set layout_format "GDSII"
    } elseif {$layout_format == "OAS"} {
        set layout_format "OASIS"
    } else {
        set layout_format $layFormat
    }
    set layout_format $layFormat
    if {[info exists grid]} {
        set grid "qsub -P bnormal -A quick -pe mt $cores -l mem_free=${mem},h_vmem=$mem -cwd -V"
    } else {
        set grid ""
    }
    if { $icv_version != ""} {
        set icv_version "/$icv_version"
    } else {
        set icv_version ""
    }
    if {![info exists fab_node]} {
        set fab_node "GENERIC"
    } elseif { [string match -nocase "tsmc05*" $fab_node] || [string match  -nocase "tsmc03*" $fab_node] } {
        set fab_node "TS5LIKE"
        iprint " TSMC advanced node MAP STYLE is used!"
    } else {
        set fab_node "GENERIC"
    }
    set top_metal $bot_metal

    # Parse layermap for layout database layers and datatypes.
    if {![file exists $layermap]} {
        if { [file exists "./stream.layermap"] } {
            set layermap ./stream.layermap
        } else {
            fatal_error "Layermap is not provided!"
        }
    }
    # Grab metal information from streamout.layermap file
    set fmap [read_file $layermap]
    set stream [split $fmap "\n"]
    foreach line $stream {
        if {[regexp {^M(\d+)(_WIDE)?\s+(dpl1|dpl2|dpl3|dpl4|drawing)\s+(\d+)\s+(\d+)} $line match metal name_ext purpose layer datatype]} {
            if {$metal > $top_metal} {
                set top_metal $metal
            }
            lappend m${metal} $layer
            lappend m${metal} $datatype
            continue
        }
        if {[regexp {^VIA(\d+)(_DPL1|_DPL2)?\s+(bar|bar_dpl1|bar_dpl2|bar_dpl3|bar_dpl4|dpl1|dpl2|dpl3|dpl4|drawing|large|large_dpl1|large_dpl2|large_dpl3)\s+(\d+)\s+(\d+)} $line match via name_ext purpose layer datatype]} {
            lappend v${via} $layer
            lappend v${via} $datatype
            continue
        }
        if {$fab_node == "TS5LIKE" } {
            if {[regexp {^RMDMY\s+m(\d+)\s+(\d+)\s+(\d+)} $line match metal layer datatype]} {
                lappend m${metal}_res $layer
                lappend m${metal}_res $datatype
                continue
            }
            if {[regexp {^M(\d+)\s+pin\s+(\d+)\s+(\d+)} $line match metal layer datatype]} {
                lappend m${metal}_txt $layer
                lappend m${metal}_txt $datatype
                continue
            }
            if {[regexp {^RV\s+(bar|drawing)\s+(\d+)\s+(\d+)} $line match purpose layer datatype]} {
                lappend rdlvia $layer
                lappend rdlvia $datatype
                continue
            }
            if {[regexp {^AP\s+(drawing)\s+(\d+)\s+(\d+)} $line match purpose layer datatype]} {
                lappend rdl $layer
                lappend rdl $datatype
                continue
            }
            if {[regexp {^AP\s+pin\s+(\d+)\s+(\d+)} $line match layer datatype]} {
                lappend rdl_txt $layer
                lappend rdl_txt $datatype
                continue
            }
        } else {
            if {[regexp {^M(\d+)RES\s+lvs\s+(\d+)\s+(\d+)} $line match metal layer datatype]} {
                lappend m${metal}_res $layer
                lappend m${metal}_res $datatype
                continue
            }
            if {[regexp {^M(\d+)\s+label\s+(\d+)\s+(\d+)} $line match metal layer datatype]} {
                lappend m${metal}_txt $layer
                lappend m${metal}_txt $datatype
                continue
            }
            if {[regexp {^RDLVIA\s+(bar|drawing)\s+(\d+)\s+(\d+)} $line match purpose layer datatype]} {
                lappend rdlvia $layer
                lappend rdlvia $datatype
                continue
            }
            if {[regexp {^RDL\s+(drawing)\s+(\d+)\s+(\d+)} $line match purpose layer datatype]} {
                lappend rdl $layer
                lappend rdl $datatype
                continue
            }
            if {[regexp {^RDL\s+label\s+(\d+)\s+(\d+)} $line match layer datatype]} {
                lappend rdl_txt $layer
                lappend rdl_txt $datatype
                continue
            }
        }
    }
    # Create working directory and change to it.
    file mkdir  $cell/$runset_name
    set  icvRunSet [file join $cell $runset_name ${runset_name}.rs ]
    iprint "$cell file is running"
    write_file ./$icvRunSet "#include <icv.rh>" w
    # Increase error limit and flatten violations.
    write_file ./$icvRunSet "error_options(error_limit_per_check = ERROR_LIMIT_MAX, flatten_violations = {\"*\"});" a+
    # Set text_options and add edtext file.
    write_file ./$icvRunSet "text_options(" a+
    write_file ./$icvRunSet "\t use_exploded_text={{{\"*\"}, {\"*\"}}}" a+
    if {[file exists $edtext]} {
        set edTextFile $edtext
        set f_edtext [read_file $edTextFile]
        write_file ./$icvRunSet "\t edtext = {$f_edtext\t}," a+
    }
    ###    write_file ./$icvRunSet  "\t text_depth = $text_depth" a+
    write_file ./$icvRunSet   ");"  a+
    # Special handling for square brackets in ICV.
    regsub -all {\[} $nets {\\\\\\\[} nets
    regsub -all {\]} $nets {\\\\\\\]} nets
    set nets_formatted ""
    foreach net $nets {
        set nets_formatted "$nets_formatted \"$net\","
    }
    write_file ./$icvRunSet "trace_nets : list of string = {${nets_formatted}};" a+
    regsub -all {\[} $allNets {\\\\\\\[} allNets
    regsub -all {\]} $allNets {\\\\\\\]} allNets
    set allNets_formatted ""
    foreach net $allNets {
        set allNets_formatted "$allNets_formatted \"$net\","
    }
    write_file ./$icvRunSet "trace_nets1 : list of string = {${allNets_formatted}};" a+
    # Set layer assignments.
    for {set j $bot_metal} {($j >= $bot_metal) && ($j <= ($top_metal - 1))} {incr j} {
        write_file ./$icvRunSet "m${j} = assign(\n\tldt_list = {" a+
        for {set i 0} {$i < [llength [set m${j}]]} {set i [expr $i + 2]} {
            write_file ./$icvRunSet "\t\t{layer_num_range = [lindex [set m${j}] $i], data_type_range = [lindex [set m${j}] [expr $i + 1]]}," a+
        }
        write_file ./$icvRunSet "\t}\n);" a+
        write_file ./$icvRunSet "m${j}_txt = assign_text(\n\tldt_list = {" a+
        for {set i 0} {$i < [llength [set m${j}_txt]]} {set i [expr $i + 2]} {
            write_file ./$icvRunSet "\t\t{layer_num_range = [lindex [set m${j}_txt] $i], data_type_range = [lindex [set m${j}_txt] [expr $i + 1]]}," a+
        }
        write_file ./$icvRunSet "\t}\n);" a+

        set vCon$j ""
        if { $fab_node == "TS5LIKE" } {
            write_file ./$icvRunSet "v${j} = assign(\n\tldt_list = {" a+
            for {set i 0} {$i < [llength [set v${j}]]} {set i [expr $i + 2]} {
                write_file ./$icvRunSet "\t\t{layer_num_range = [lindex [set v${j}] $i], data_type_range = [lindex [set v${j}] [expr $i + 1]]}," a+
                set temp "[lindex [set v${j}] $i]:[lindex [set v${j}] [expr $i + 1]] "
                if { [string match *$temp*  [set vCon$j]] } {
                    continue
                } else  {
                    append vCon${j} $temp
                }
            }
            write_file ./$icvRunSet "\t}\n);" a+
        } else {
            write_file ./$icvRunSet "v${j} = assign(\n\tldt_list = {" a+
            for {set i 0} {$i < [llength [set v${j}[expr $j + 1]]]} {set i [expr $i + 2]} {
                write_file ./$icvRunSet "\t\t{layer_num_range = [lindex [set v${j}[expr $j + 1]] $i], data_type_range = [lindex [set v${j}[expr $j + 1]] [expr $i + 1]]}," a+
                set temp "[lindex [set v${j}[expr $j + 1]] $i]:[lindex [set v${j}[expr $j + 1]] [expr $i + 1]] "
                if { [string match *$temp*  [set vCon$j ] ] } {
                    continue
                } else  {
                    append vCon${j} $temp
                }
            }
            write_file ./$icvRunSet "\t}\n);" a+
        }
        write_file ./$icvRunSet "m${j}_res = assign(\n\tldt_list = {" a+
        for {set i 0} {$i < [llength [set m${j}_res]]} {set i [expr $i + 2]} {
            write_file ./$icvRunSet "\t\t{layer_num_range = [lindex [set m${j}_res] $i], data_type_range = [lindex [set m${j}_res] [expr $i + 1]]}," a+
        }
        write_file ./$icvRunSet "\t}\n);" a+
    }
    write_file ./$icvRunSet "m${top_metal}_res = assign(\n\tldt_list = {" a+
    for {set i 0} {$i < [llength [set m${top_metal}_res]]} {set i [expr $i + 2]} {
        write_file ./$icvRunSet "\t\t{layer_num_range = [lindex [set m${top_metal}_res] $i], data_type_range = [lindex [set m${top_metal}_res] [expr $i + 1]]}," a+
    }
    write_file ./$icvRunSet "\t}\n);" a+
    write_file ./$icvRunSet "m${top_metal} = assign(\n\tldt_list = {" a+
    for {set i 0} {$i < [llength [set m${top_metal}]]} {set i [expr $i + 2]} {
        write_file ./$icvRunSet "\t\t{layer_num_range = [lindex [set m${top_metal}] $i], data_type_range = [lindex [set m${top_metal}] [expr $i + 1]]}," a+
    }
    write_file ./$icvRunSet "\t}\n);" a+
    write_file ./$icvRunSet "m${top_metal}_txt = assign_text(\n\tldt_list = {" a+
    for {set i 0} {$i < [llength [set m${top_metal}_txt]]} {set i [expr $i + 2]} {
        write_file ./$icvRunSet "\t\t{layer_num_range = [lindex [set m${top_metal}_txt] $i], data_type_range = [lindex [set m${top_metal}_txt] [expr $i + 1]]}," a+
    }
    write_file ./$icvRunSet "\t}\n);" a+
    write_file ./$icvRunSet "rdlvia = assign(\n\tldt_list = {" a+
    for {set i 0} {$i < [llength $rdlvia]} {set i [expr $i + 2]} {
        write_file ./$icvRunSet "\t\t{layer_num_range = [lindex $rdlvia $i], data_type_range = [lindex $rdlvia [expr $i + 1]]}," a+
    }
    write_file ./$icvRunSet "\t}\n);" a+
    write_file ./$icvRunSet "rdl = assign(\n\tldt_list = {" a+
    for {set i 0} {$i < [llength $rdl]} {set i [expr $i + 2]} {
        write_file ./$icvRunSet "\t\t{layer_num_range = [lindex $rdl $i], data_type_range = [lindex $rdl [expr $i + 1]]}," a+
    }
    write_file ./$icvRunSet "\t}\n);" a+
    write_file ./$icvRunSet "rdl_txt = assign_text(\n\tldt_list = {" a+
    for {set i 0} {$i < [llength $rdl_txt]} {set i [expr $i + 2]} {
        write_file ./$icvRunSet "\t\t{layer_num_range = [lindex $rdl_txt $i], data_type_range = [lindex $rdl_txt [expr $i + 1]]}," a+
    }
    write_file ./$icvRunSet "\t}\n);" a+
    # Cut metal shapes by metal Resistors
    for {set j $bot_metal} {($j >= $bot_metal) && ($j <= $top_metal )} {incr j} {
        write_file ./$icvRunSet "m${j} = not ( m${j} , m${j}_res);"  a+
    }
    # Floating Pin finding (MIPLAST)
    write_file ./$icvRunSet "\n" a+
    write_file ./$icvRunSet "foreach(trace_net in trace_nets)\{" a+
    write_file ./$icvRunSet "\t Missing_Pin_Connection @= \{ @ trace_net + \"_pin2Up_M${bot_metal}: \" + \" Texted MIPLAST metal without a VIA connection to an upper layer.\";" a+
    write_file ./$icvRunSet "\t\t mIPlastTxt = text_origin(m${bot_metal}_txt , 0.001, text=\{trace_net\}, cells=\{\"\*\"\} );" a+
    write_file ./$icvRunSet "\t\t tmp = not( enclosing(m${bot_metal}, mIPlastTxt), enclosing( enclosing(m${bot_metal}, mIPlastTxt), v${bot_metal}) );" a+
    write_file ./$icvRunSet "\t\t copy( tmp, \"Floating2UpperMIPLAST\");" a+
    write_file ./$icvRunSet "\t \};" a+
    write_file ./$icvRunSet "\};" a+
    # Floating Pin finding (MIINT* - MTOP-1)
    write_file ./$icvRunSet "foreach(trace_net in trace_nets1)\{" a+
    for {set i [expr $bot_metal + 1] } {($i > $bot_metal) && ($i < $top_metal)} {incr i} {
        write_file ./$icvRunSet "\n"  a+
        write_file ./$icvRunSet "\t Missing_Pin_Connection @= \{ @ trace_net + \"_pin2Up_M${i}: \" + \" Metal shape without a VIA connection to an upper layer.\";" a+
        write_file ./$icvRunSet "\t\t tmpU = not( m${i}, enclosing( m${i}, v${i} ) );" a+
        write_file ./$icvRunSet "\t\t copy( tmpU, \"Floating2Upper\");\n" a+
        write_file ./$icvRunSet "\t \};" a+
        write_file ./$icvRunSet "\t Missing_Pin_Connection @= \{ @ trace_net + \"_pin2Down_M${i}: \" + \" Metal shape without a VIA connection to below layer.\";\n" a+
        write_file ./$icvRunSet "\t\t tmpL = not( m${i}, enclosing( m${i}, v[expr ${i} - 1] ) );" a+
        write_file ./$icvRunSet "\t\t copy( tmpL, \"Floating2Below\");\n" a+
        write_file ./$icvRunSet "\t \};" a+
    }
    # Floating Pin finding (MTOP)
    write_file ./$icvRunSet "\t Missing_Pin_Connection @= \{ @ trace_net + \"_pin2Down_M${top_metal}: \" + \" MTOP metal shape without a VIA connection to below layer.\";\n" a+
    write_file ./$icvRunSet "\t\t tmp = not( m${top_metal}, enclosing( m${top_metal}, v[expr ${top_metal} - 1] ) );" a+
    write_file ./$icvRunSet "\t\t copy( tmp, \"Floating2BelowMTOP\");" a+
    write_file ./$icvRunSet "\t \};" a+
    write_file ./$icvRunSet "\};"  a+
    write_file ./$icvRunSet "\n"  a+
    # Run net_tracer runset.
    set fid [file join $cell $runset_name ${runset_name}.tcsh ]
    write_file ./$fid  "#!/bin/tcsh" a+
    write_file ./$fid "module unload icv; module load icv${icv_version}" a+
    write_file ./$fid "icv -norscache -host_init $cores -c $cell -f $layout_format -i ../../$layout -vue -vueshort ${runset_name}.rs" a+
    file attributes $fid -permissions +x
    cd $cell/$runset_name
    set cmd [list bash -c "source ~/.bashrc;  $grid ./${runset_name}.tcsh"]
    run_system_cmd $cmd 2
    cd ../../
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