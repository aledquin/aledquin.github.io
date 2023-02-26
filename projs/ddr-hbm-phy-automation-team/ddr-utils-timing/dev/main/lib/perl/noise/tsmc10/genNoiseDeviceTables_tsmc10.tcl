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

    source setup_tsmc.tcl
    ############################  Begin tt0p85v100c  ############################
    create_operating_condition tt0p85v100c
    set_opc_process tt0p85v100c {
        {.lib "/remote/proj/ddr43/d515-ddr43-tsmc10ff18/rel1.00a/cad/models/hspice/bjt.lib" bip_t}
        {.lib "/remote/proj/ddr43/d515-ddr43-tsmc10ff18/rel1.00a/cad/models/hspice/cap.lib" cap_t}
        {.lib "/remote/proj/ddr43/d515-ddr43-tsmc10ff18/rel1.00a/cad/models/hspice/diode.lib" dio_t}
        {.lib "/remote/proj/ddr43/d515-ddr43-tsmc10ff18/rel1.00a/cad/models/hspice/mbscr.lib" mbscr_tt}
        {.lib "/remote/proj/ddr43/d515-ddr43-tsmc10ff18/rel1.00a/cad/models/hspice/momcap.lib" momcap_t}
        {.lib "/remote/proj/ddr43/d515-ddr43-tsmc10ff18/rel1.00a/cad/models/hspice/moscap_hv.lib" nmoscaphv_t}
        {.lib "/remote/proj/ddr43/d515-ddr43-tsmc10ff18/rel1.00a/cad/models/hspice/moscap.lib" nmoscap_t}
        {.lib "/remote/proj/ddr43/d515-ddr43-tsmc10ff18/rel1.00a/cad/models/hspice/mos_hv.lib" moshv_tt}
        {.lib "/remote/proj/ddr43/d515-ddr43-tsmc10ff18/rel1.00a/cad/models/hspice/mos_hvud.lib" moshvud_tt}
        {.lib "/remote/proj/ddr43/d515-ddr43-tsmc10ff18/rel1.00a/cad/models/hspice/mos.lib" mos_tt}
        {.lib "/remote/proj/ddr43/d515-ddr43-tsmc10ff18/rel1.00a/cad/models/hspice/mos_lvt.lib" moslvt_tt}
        {.lib "/remote/proj/ddr43/d515-ddr43-tsmc10ff18/rel1.00a/cad/models/hspice/mos_ulvt.lib"  mosulvt_tt}
        {.lib "/remote/proj/ddr43/d515-ddr43-tsmc10ff18/rel1.00a/cad/models/hspice/res.lib" res_t}
    }
    add_opc_supplies tt0p85v100c VDD 0.85 VDD18 1.8 VDD15 1.5 VDD12 1.2 VDD10 1.0
    add_opc_grounds tt0p85v100c VSS
    set_opc_temperature tt0p85v100c 100
    ############################  End tt0p85v100c  ############################

    #source /remote/proj/ddr43/d515-ddr43-tsmc10ff18/rel1.00a/design/timing/sis/SiS_configure_d515_pvt.tcl



    set hspiceVersion hspice
    set PVT tt0p85v100c
    set outFile "tsmc10ff_${PVT}_noise.tech"
    if [file exists $outFile] {file delete $outFile}

    set vSupply [supplyVoltage $PVT VDD]

    ## resistor
    charRes3t rhim_m $PVT VDD {0.5u 1.0u 1.5u 2.0u 2.5u 3.0u} {0.5u 1.0u 1.5u 2.0u 2.5u 3.0u}


    ##  Thin oxide nfets,mpodes
    foreach device {nch_lvt_mac nch_ulvt_mac nch_svt_mac nch_mpodelvt_mac nch_mpodeulvt_mac nch_mpodesvt_mac} {
        charMos $device n $PVT VDD {4 6 8} {0.01u 0.014u 0.02u 0.036u 0.072u 0.24u} {0.002p 0.02p 0.2p} {0.2u 0.4u 0.8u}
    }

    ## Thin-ox npode devices
    foreach device {npode_lvt_mac npode_ulvt_mac npode_svt_mac} {
        charPode $device n $PVT VDD {4 6 8} {0.01u 0.014u 0.02u 0.036u 0.072u 0.24u} {0.002p 0.02p 0.2p} {0.2u 0.4u 0.8u}
    }


    ##  Thin oxide pfets
    foreach device {pch_lvt_mac pch_ulvt_mac pch_svt_mac pch_mpodelvt_mac pch_mpodeulvt_mac pch_mpodesvt_mac} {
        charMos $device p $PVT VDD {4 6 8} {0.01u 0.014u 0.02u 0.036u 0.072u 0.24u} {0.002p 0.02p 0.2p} {0.2u 0.4u 0.8u}
    }

    ## Thin-ox ppode devices
    foreach device {ppode_lvt_mac ppode_ulvt_mac ppode_svt_mac} {
        charPode $device p $PVT VDD {4 6 8} {0.01u 0.014u 0.02u 0.036u 0.072u 0.24u} {0.002p 0.02p 0.2p} {0.2u 0.4u 0.8u}
    }

    ##  hv Nfets
    charMos nch_18_mac        n $PVT VDD18 {4 8 16} {0.135u 0.17u 0.205u 0.240u}  {0.002p 0.02p 0.2p} {0.2u 0.4u 0.8u}
    charMos nch_18ud15_mac    n $PVT VDD15 {4 8 16} {0.086u 0.14u 0.19u 0.240u}   {0.002p 0.02p 0.2p} {0.2u 0.4u 0.8u}
    charMos nch_18ud12_mac    n $PVT VDD12 {4 8 16} {0.072u 0.128u 0.184u 0.240u} {0.002p 0.02p 0.2p} {0.2u 0.4u 0.8u}
    charPode npode_18_mac     n $PVT VDD18 {4 8 16} {0.135u 0.17u 0.205u 0.240u}  {0.002p 0.02p 0.2p} {0.2u 0.4u 0.8u}
    charPode npode_18ud15_mac n $PVT VDD15 {4 8 16} {0.086u 0.14u 0.19u 0.240u}   {0.002p 0.02p 0.2p} {0.2u 0.4u 0.8u}
    charPode npode_18ud12_mac n $PVT VDD12 {4 8 16} {0.072u 0.128u 0.184u 0.240u} {0.002p 0.02p 0.2p} {0.2u 0.4u 0.8u}

    ##  hv Pfets
    charMos pch_18_mac       p $PVT VDD18 {4 8 16} {0.135u 0.17u 0.205u 0.240u}  {0.002p 0.02p 0.2p} {0.2u 0.4u 0.8u}
    charMos pch_18ud15_mac   p $PVT VDD15 {4 8 16} {0.086u 0.14u 0.19u 0.240u}   {0.002p 0.02p 0.2p} {0.2u 0.4u 0.8u}
    charMos pch_18ud12_mac   p $PVT VDD12 {4 8 16} {0.072u 0.128u 0.184u 0.240u} {0.002p 0.02p 0.2p} {0.2u 0.4u 0.8u}
    charPode ppode_18_mac     p $PVT VDD18 {4 8 16} {0.135u 0.17u 0.205u 0.240u}  {0.002p 0.02p 0.2p} {0.2u 0.4u 0.8u}
    charPode ppode_18ud15_mac p $PVT VDD15 {4 8 16} {0.086u 0.14u 0.19u 0.240u}   {0.002p 0.02p 0.2p} {0.2u 0.4u 0.8u}
    charPode ppode_18ud12_mac p $PVT VDD12 {4 8 16} {0.072u 0.128u 0.184u 0.240u} {0.002p 0.02p 0.2p} {0.2u 0.4u 0.8u}


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