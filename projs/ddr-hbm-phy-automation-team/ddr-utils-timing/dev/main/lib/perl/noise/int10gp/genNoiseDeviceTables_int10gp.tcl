#!/depot/tcl8.6.3/bin/tclsh8.6


package require try         ;# Tcllib.
package require cmdline 1.5 ;# First version with proper error-codes.
package require fileutil

set DEBUG      0
set VERBOSITY  0
set STDOUT_LOG ""
set AUTHOR     "Manmit Muker (mmuker), Patrick Juliano (juliano), Alvaro Quintana Carvacho"
set RealBin [file dirname [file normalize [info script]] ]
set RealScript [file tail [file normalize [info script]] ]
set PROGRAM_NAME $RealScript
set LOGFILE "[pwd]/$PROGRAM_NAME.log"

# Declare cmdline opt vars here, so they are global
set opt_fast ""
set opt_test ""
set opt_help ""
set opt_project ""

lappend auto_path "$RealBin/../lib/tcl"
package require Messaging 1.0
namespace import ::Messaging::*
package require Misc 1.0
namespace import ::Misc::*

proc Main {} {
    source setup_int10gp.tcl
    ############################  Begin tt0p8v85c  ############################
    create_operating_condition tt0p8v85c
    set_opc_process tt0p8v85c {
        {.lib "/remote/cad-rep/projects/hbm2/d730-hbm2-int10-18/rel0.12/cad/models/hspice/common_corners.lib" tttt}
        {.include "/remote/cad-rep/projects/hbm2/d730-hbm2-int10-18/rel0.12/cad/models/hspice/custom/intel75custom.hsp"}
    }
    add_opc_supplies tt0p8v85c VDD 0.8 VDDQ 1.2 VAA 1.8 VINN3 0.4 VINP3 0.4 VINN4 0.8 VREF3 0.6 VREF4 1 VDDI 1.2 ext_high 0.8 ext_low 0.4 VBIAS_DQ 0.8 VSTG2_DQ 0.8
    add_opc_grounds tt0p8v85c VSS
    set_opc_default_voltage tt0p8v85c 0.8
    set_opc_temperature tt0p8v85c 85
    ############################  End tt0p8v85c  ############################


    set hspiceVersion hspice/2015.06-SP2
    set PVT tt0p8v85c
    set outFile "int10gp_${PVT}_noise.tech"

    ##   Commands to be included in the shell file prior to invoking hspice
    lappend hspiceSourceCommands {setenv INTEL_PDK              ${udecadrep}/fab/f124-Intel/10nm/GP/FDK_msip/pdk/pdk756_r1.2.3_snps}
    lappend hspiceSourceCommands {setenv hspice_lib_models      ${INTEL_PDK}/cmi/hspice/cmi/lnx86/64bit}
    lappend hspiceSourceCommands {setenv PDMI_LIB               ${INTEL_PDK}/cmi/hspice/pdmi/lnx86/64bit/pdmi.so}

    set hspiceOptionsFile "$env(udecadrep)/fab/f124-Intel/10nm/GP/FDK_msip/pdk/pdk756_r1.2.3_snps/models/hspice/hspice_options"

    if [file exists $outFile] {file delete $outFile}

    set vSupply [supplyVoltage $PVT VDD]

    ## resistor
    charRes3tFixed f8xlrescpru1basqt2hnx $PVT VDD
    charRes3tFixed e8xltfrlrvu2topxn2unx $PVT VDD

    ##  Thin oxide nfets
    foreach device {n nhvt nslvt nsvt} {
        charMos $device n $PVT VDD {34n 68n 102n 136n 170n 204n 238n 272n} {20n} {0.002p 0.02p 0.2p} {0.2u 0.4u 0.8u}
    }


    #  Thin oxide pfets
    foreach device {p phvt pslvt psvt} {
        charMos $device p $PVT VDD {34n 68n 102n 136n 170n 204n 238n 272n} {20n} {0.002p 0.02p 0.2p} {0.2u 0.4u 0.8u}
    }

    ##  hv Nfets
    charMos ntg n $PVT VDD {34n 68n 102n 136n 170n 204n 238n 272n} {160n} {0.002p 0.02p 0.2p} {0.2u 0.4u 0.8u}
    charMos ptg p $PVT VDD {34n 68n 102n 136n 170n 204n 238n 272n} {160n} {0.002p 0.02p 0.2p} {0.2u 0.4u 0.8u}

    writePerlTables
}

try {
    header 
    set exitval [Main]
} on error {results options} {
    set exitval [fatal_error [dict get $options -errorinfo]]
} finally {
    footer
    write_stdout_log $LOGFILE
}

# 11-07-2022: monitor usage is in header now
# nolint utils__script_usage_statistics