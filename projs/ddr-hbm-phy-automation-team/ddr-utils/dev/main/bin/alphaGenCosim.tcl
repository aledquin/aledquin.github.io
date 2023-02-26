#!/depotbld/RHEL5.5/tcl8.5.2/bin/tclsh8.5

# TODO: rename to ddr-cc-*
if {[namespace exists alpha::cosim]} {
    namespace delete alpha::cosim
}

set DEBUG      0
set VERBOSITY  0
set STDOUT_LOG ""
set RealBin        [file dirname [file normalize [info script]] ]

namespace eval ::alpha::cosim {
    global RealBin
    variable PROGRAM_NAME [file tail [file normalize [info script]] ]
    ##  Script to auto-generate cosim netlists.
    ##  Required files:
    ##     pcs/design/legalRelease.txt:  Interpreted as tcl, defines "rel" and "process" variables.
    ##     pcs/design/legalMacros.txt:  Simple list of libName/cellName.  Comments OK.
	namespace eval _packages {
        global RealBin
		source "$RealBin/../lib/tcl/Util/Messaging.tcl"
		source "$RealBin/../lib/tcl/Util/Misc.tcl"
	}
	namespace import _packages::Messaging::*
	namespace import _packages::Misc::*
	foreach procName [namespace import] {
		rename $procName "_$procName"
	}
	# Get the version number
	variable VERSION [_get_release_version]
	_utils__script_usage_statistics $PROGRAM_NAME $VERSION
    
    proc firstAvailableFile {args} {
    
        foreach ff $args {
            if [file exists $ff] {return $ff}
        }
        puts "Error:  None of these exist:"
        foreach ff $args {puts "\t$ff"}
        return ""

    }

    proc genCosim { {inputMacros {}} } {

        set pcsDesignDir "$::env(MSIP_PROJ_ROOT)/$::env(MSIP_PRODUCT_NAME)/$::env(MSIP_PROJ_NAME)/$::env(MSIP_REL_NAME)/design"

        set legal_release_file $::env(MSIP_PROJ_ROOT)/$::env(MSIP_PRODUCT_NAME)/$::env(MSIP_PROJ_NAME)/$::env(MSIP_REL_NAME)/design/legalRelease.txt 
        set legal_release_file_unrestrcited $::env(MSIP_PROJ_ROOT)/$::env(MSIP_PRODUCT_NAME)/$::env(MSIP_PROJ_NAME)/$::env(MSIP_REL_NAME)/design_unrestricted/legalRelease.txt

        set legalReleaseFile [ firstAvailableFile "$legal_release_file" "$legal_release_file_unrestrcited" ]

        set topcells_file $::env(MSIP_PROJ_ROOT)/$::env(MSIP_PRODUCT_NAME)/$::env(MSIP_PROJ_NAME)/$::env(MSIP_REL_NAME)/design/topcells.txt 
        set topcells_file_unrestricted $::env(MSIP_PROJ_ROOT)/$::env(MSIP_PRODUCT_NAME)/$::env(MSIP_PROJ_NAME)/$::env(MSIP_REL_NAME)/design_unrestricted/topcells.txt 

        set legalMacrosFile [ firstAvailableFile "$topcells_file" "$topcells_file_unrestricted" ]
            
        set argOK 1
        if {![file exists $legalReleaseFile]} {
            puts "Error:  Missing required file $legalReleaseFile"
            set argOK 0
        }
        if {![file exists $legalMacrosFile]} {
            puts "Error:  Missing required file $legalMacrosFile"
            set argOK 0
        }
        
        if {!$argOK} {
            puts "Info:  Aborting on missing required files"
            return
        }
        
        ## Defines these:  "rel", "process", perhaps some others
        set varOK 1
        source $legalReleaseFile
        if {![info exists rel]} {
            puts "Error:  Missing required variable \"rel\""
            set varOK 0
        }
        if {![info exists process]} {
            puts "Error:  Missing required variable \"process\""
            set varOK 0
        }
        
        if {!$varOK} {
            puts "Info:  Aborting on missing required variable(s)"
            return
        }
        
        set destDir "$pcsDesignDir/cosim/$rel"    
        if {![file exists $destDir]} {file mkdir $destDir}
        if {![file isdirectory $destDir]} {
            puts "Error:  $destDir exists, not directory"
            return
        }
    
        ## Determine includeCIR. This is lifted from netlist_gen/utils.tcl
        set projRoot $::env(MSIP_PROJ_ROOT)
        set productName $::env(MSIP_PRODUCT_NAME)
        set projName $::env(MSIP_PROJ_NAME)
        set relName $::env(MSIP_REL_NAME)
        set stack $::env(METAL_STACK)
        
        set cadProductName $::env(MSIP_CAD_PRODUCT_NAME)
        set cadProjName $::env(MSIP_CAD_PROJ_NAME)
        set cadRelName $::env(MSIP_CAD_REL_NAME)
        if { [info exists env(CAD_METAL_STACK)] } {
            set cadStack $::env(CAD_METAL_STACK)
        } else {
            set cadStack $stack
        }
        if { [file exists "$projRoot/$productName/$projName/$relName/cad"] } {
            set cadFlag "true"
        } else {
            set cadFlag "false"
        }
        
        if { $cadFlag == "true" } {
            if { [file exists "$projRoot/$productName/$projName/$relName/cad/$stack/template/sim.include.cdl"] } {
            set includeCIR "$projRoot/$productName/$projName/$relName/cad/$stack/template/sim.include.cdl"
            } elseif { [file exists "$projRoot/$productName/$projName/$relName/cad/template/sim.include.cdl"] } {
            set includeCIR "$projRoot/$productName/$projName/$relName/cad/template/sim.include.cdl"
            } elseif { [file exists "$projRoot/$cadProductName/$cadProjName/$cadRelName/cad/${cadStack}/template/sim.include.cdl"] } {
            set includeCIR "$projRoot/$cadProductName/$cadProjName/$cadRelName/cad/${cadStack}/template/sim.include.cdl"
            } elseif { [file exists "$projRoot/$cadProductName/$cadProjName/$cadRelName/cad/template/sim.include.cdl"] } {
            set includeCIR "$projRoot/$cadProductName/$cadProjName/$cadRelName/cad/template/sim.include.cdl"
            } else {
            set includeCIR ""
            puts "Warning:  sim.include.cdl not found"
            }
        } else {
            if { [file exists "$projRoot/$productName/$projName/$relName/$stack/template/sim.include.cdl"] } {
            set includeCIR "$projRoot/$productName/$projName/$relName/$stack/template/sim.include.cdl"
            } elseif { [file exists "$projRoot/$productName/$projName/$relName/$stack/template/sim.include.cdl"] } {
            set includeCIR "$projRoot/$productName/$projName/$relName/template/sim.include.cdl"
            } elseif { [file exists "$projRoot/$cadProductName/$cadProjName/$cadRelName/${cadStack}/template/sim.include.cdl"] } {
            set includeCIR "$projRoot/$cadProductName/$cadProjName/$cadRelName/${cadStack}/template/sim.include.cdl"
            } elseif { [file exists "$projRoot/$cadProductName/$cadProjName/$cadRelName/template/sim.include.cdl"] } {
            set includeCIR "$projRoot/$cadProductName/$cadProjName/$cadRelName/template/sim.include.cdl"
            } else {
            set includeCIR ""
            puts "Warning:  sim.include.cdl not found"
            }
        }
    
        set MACROS [open $legalMacrosFile r]
        set macrosList {}
        while {[gets $MACROS line] >= 0} {
            ## uncomment
            set line [regsub {\#.*} $line ""]
            set n [llength $line]
            if {$n == 0} { continue }
            if {$n > 1} {
                puts "Warning:  Unexpected tokens in \"$line\". Skipping"
                continue
            }
            ## Strip whitespace
            set line [string trim $line " \t"]
            if {$line != ""} {
                if [regexp {\[LAY\]} $line] { continue }
                if [regexp {\/layout} $line] { continue }
                set line [regsub {\[SCH\]} $line ""]
                set line [regsub {\/schematic} $line ""]
            } else { continue }
            ##  All good.  One token.
            set toks [split $line "/"]
            if {[llength $toks] != 2} {
                puts "Warning:  Unexpected formating: \"$line\""
                continue
            }
            set libName [lindex $toks 0]
            set cellName [lindex $toks 1]

            if {[llength $inputMacros] > 0} {
                foreach macro $inputMacros {
                    if {[lsearch $toks "*$macro*"] > -1} {
                        lappend macrosList $toks
                    }
                }
            } else {
                lappend macrosList $toks
            }
        }
        close $MACROS

        if {[llength $macrosList] == 0} {
            puts "Error: no macros found."
            return
        }
        puts "List of macros for Cosim generation:"
        puts "\t[join $macrosList "\n\t"]"
    
        set info {}
        foreach macro $macrosList {
            set libName [lindex $macro 0]
            set cellName [lindex $macro 1]

            if [oa::DesignExists $libName $cellName schematic] {
                
                puts "Info:  Generating Cosim netlist for $libName:$cellName"
                set intNetlist "$cellName.raw.sp"
                set destNetlist "$destDir/${cellName}_${process}.sp"
                if [file exists $intNetlist] {file delete $intNetlist}
                if [file exists $destNetlist] {file delete $destNetlist}
                
                ##  Get current state of createTopAsModule attr
                set createTopAsModule_save [db::getAttr createTopAsModule -of [nl::getNetlisters HSPICE]]
                ##  Force to 1 for this netlist.
                db::setAttr createTopAsModule -of [nl::getNetlisters HSPICE] -value 1
                ude::genNetlist \
                    -libName $libName \
                    -cellName $cellName \
                    -cellView schematic \
                    -netlistFormat HSPICE \
                    -viewSearchList "veriloga hspice hspiceD schematic symbol" \
                    -viewStopList "use_cd_default" \
                    -includeCIR $includeCIR \
                    -processName $::env(PROCESSNAME) \
                    -postProcess false \
                    -openInViewer false \
                    -openInEditor false \
                    -caseSensitive true \
                    -compress false \
                    -runDir ./ \
                    -fileName $intNetlist
    
                ##  This is an alternative netlist command that fills in some of the above args, but lacks all the
                ##  necessary controls, like runDir and caseSensitive.
                #  ude::genNetlistBatch -netlistFormat HSPICE -cellName $cellName -libName $libName
                #   ude::genNetlist::execute  \
                #    -libName $libName \
                #    -cellName $cellName \
                #    -cellView schematic \
                #    -netlistFormat HSPICE \
                #    -viewSearchList {cdl auCdl schematic symbol} \
                #    -viewStopList use_cd_default \
                #    -includeCIR {} \
                #    -processName $::env(PROCESSNAME) \
                #    -postProcess false \
                #    -compress false \
                #    -runDir ./ \
                #    -fileName $intNetlist \
                #    -reference false

                ##  Restore state.
                db::setAttr createTopAsModule -of [nl::getNetlisters HSPICE] -value $createTopAsModule_save
    
                if [file exists $intNetlist] {
                    ##  All good.
                    set IN [open $intNetlist r]
                    set OUT [open $destNetlist w]
                    puts $OUT "** Cosim netlist for macro $cellName, Release $rel, for project $::env(MSIP_PRODUCT_NAME)/$::env(MSIP_PROJ_NAME)"                   
                    while {[gets $IN line] >= 0} {
                        set line [string map {< [ > ]} $line]
                        puts $OUT $line
                    }
                    close $IN
                    close $OUT
                    file delete $intNetlist
                    lappend info "Info:  [file normalize $destNetlist] created"
                } else {
                    file copy -force netlist.log "netlist_$cellName.log"
                    lappend info "Error:  Netlist failed.  See [file normalize netlist_$cellName.log] for details."
                }
            } else {
                puts "Error:  $libName/$cellName/schematic does not exist."
            }
        }
        foreach line $info {puts $line}
    }
}



################################################################################
# No Linting Area
################################################################################

# nolint Main
