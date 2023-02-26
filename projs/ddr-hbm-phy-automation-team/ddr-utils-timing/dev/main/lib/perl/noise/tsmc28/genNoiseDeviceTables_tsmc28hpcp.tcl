#!/depot/tcl8.6.3/bin/tclsh8.6
#--------------------------------------------------------------------#

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

source setup_tsmc28.tcl

############################  Begin tt0p9v25c  ############################
create_operating_condition tt0p9v25c
set_opc_process tt0p9v25c {  {.lib "/remote/cad-rep/projects/lpddr4mv2/d537-lpddr4mv2-tsmc28hpcp18/rel1.00a/cad/models/hspice_mc/bjt.lib" bip_t}
  {.lib "/remote/cad-rep/projects/lpddr4mv2/d537-lpddr4mv2-tsmc28hpcp18/rel1.00a/cad/models/hspice_mc/cap.lib" cap_t}
  {.lib "/remote/cad-rep/projects/lpddr4mv2/d537-lpddr4mv2-tsmc28hpcp18/rel1.00a/cad/models/hspice_mc/diode.lib" dio_t}
  {.lib "/remote/cad-rep/projects/lpddr4mv2/d537-lpddr4mv2-tsmc28hpcp18/rel1.00a/cad/models/cvpp_models/NXTGRD_5x1z_ver1.1a/devices_tsmc28hp-18_CLUB28_pPDK_E201209-1-v3/cvpp/cvpp.lib" cvpp_t}
  {.lib "/remote/cad-rep/projects/lpddr4mv2/d537-lpddr4mv2-tsmc28hpcp18/rel1.00a/cad/models/hspice_mc/momcap.lib" momcap_t}
  {.lib "/remote/cad-rep/projects/lpddr4mv2/d537-lpddr4mv2-tsmc28hpcp18/rel1.00a/cad/models/hspice_mc/moscap_hv.lib" nmoscaphv_t}
  {.lib "/remote/cad-rep/projects/lpddr4mv2/d537-lpddr4mv2-tsmc28hpcp18/rel1.00a/cad/models/hspice_mc/moscap.lib" nmoscap_t}
  {.lib "/remote/cad-rep/projects/lpddr4mv2/d537-lpddr4mv2-tsmc28hpcp18/rel1.00a/cad/models/hspice_mc/mos_hv.lib" moshv_tt}
  {.lib "/remote/cad-rep/projects/lpddr4mv2/d537-lpddr4mv2-tsmc28hpcp18/rel1.00a/cad/models/hspice_mc/mos_hvt.lib" moshvt_tt}
  {.lib "/remote/cad-rep/projects/lpddr4mv2/d537-lpddr4mv2-tsmc28hpcp18/rel1.00a/cad/models/hspice_mc/mos_hvud12.lib" moshvud_tt}
  {.lib "/remote/cad-rep/projects/lpddr4mv2/d537-lpddr4mv2-tsmc28hpcp18/rel1.00a/cad/models/hspice_mc/mos_hvud.lib" moshvud_tt}
  {.lib "/remote/cad-rep/projects/lpddr4mv2/d537-lpddr4mv2-tsmc28hpcp18/rel1.00a/cad/models/hspice_mc/mos.lib" mos_tt}
  {.lib "/remote/cad-rep/projects/lpddr4mv2/d537-lpddr4mv2-tsmc28hpcp18/rel1.00a/cad/models/hspice_mc/mos_lvt.lib" moslvt_tt}
  {.lib "/remote/cad-rep/projects/lpddr4mv2/d537-lpddr4mv2-tsmc28hpcp18/rel1.00a/cad/models/hspice_mc/mos_ehvt.lib" mosehvt_tt}
  {.lib "/remote/cad-rep/projects/lpddr4mv2/d537-lpddr4mv2-tsmc28hpcp18/rel1.00a/cad/models/hspice_mc/res.lib" res_t}
}
add_opc_supplies tt0p9v25c VDD 0.9 VDD12 1.2 VDD15 1.5 VDD18 1.8
add_opc_grounds tt0p9v25c VSS 
set_opc_default_voltage tt0p9v25c 0.9
set_opc_temperature tt0p9v25c 25
############################  End tt0p9v25c  ############################

set hspiceVersion hspice
set PVT tt0p9v25c
set outFile "tsmc28hpcp_${PVT}_noise.tech"
if [file exists $outFile] {file delete $outFile}

set vSupply [supplyVoltage $PVT VDD]

## resistor
charRes3t rupolym_m $PVT VDD {0.5u 1.0u 1.5u 2.0u 2.5u 3.0u} {0.5u 1.0u 1.5u 2.0u 2.5u 3.0u}

##  Thin oxide nfets,mpodes
foreach device {nch_lvt_mac nch_mac} {
    charMos $device n $PVT VDD {0.10u 0.20u 0.30u 0.40u 0.50u 1.0u 2.0u 3.0u} {0.03u 0.035u 0.04u 0.05u 0.06u 0.08u 0.09u 0.10u 0.25u 0.5u 1.0u} {0.002p 0.02p 0.2p} {0.2u 0.4u 0.8u}
}

##  Thin oxide pfets
foreach device {pch_lvt_mac pch_mac} {
    charMos $device p $PVT VDD {0.10u 0.20u 0.30u 0.40u 0.50u 1.0u 2.0u 3.0u} {0.03u 0.035u 0.04u 0.05u 0.06u 0.08u 0.09u 0.10u 0.25u 0.5u 1.0u} {0.002p 0.02p 0.2p} {0.2u 0.4u 0.8u}
}

##  hv Nfets
charMos nch_18_mac        n $PVT VDD18 {0.32u 0.5u 1.0u 1.0u 2.0u 3.0u 5.0u 10.0u} {0.15u 0.20u 0.30u 0.40u 0.50u 1.0u 2.0u}  {0.002p 0.02p 0.2p} {0.2u 0.4u 0.8u}
charMos nch_18ud15_mac    n $PVT VDD15 {0.32u 0.5u 1.0u 1.0u 2.0u 3.0u 5.0u 10.0u} {0.105u 0.20u 0.30u 0.40u 0.50u 1.0u 2.0u}   {0.002p 0.02p 0.2p} {0.2u 0.4u 0.8u}
charMos nch_18ud12_mac    n $PVT VDD12 {0.32u 0.5u 1.0u 1.0u 2.0u 3.0u 5.0u 10.0u} {0.90u 0.20u 0.30u 0.40u 0.50u 1.0u 2.0u}   {0.002p 0.02p 0.2p} {0.2u 0.4u 0.8u}

##  hv Pfets
charMos pch_18_mac       p $PVT VDD18 {0.32u 0.5u 1.0u 1.0u 2.0u 3.0u 5.0u 10.0u} {0.15u 0.20u 0.30u 0.40u 0.50u 1.0u 2.0u}  {0.002p 0.02p 0.2p} {0.2u 0.4u 0.8u}
charMos pch_18ud15_mac   p $PVT VDD15 {0.32u 0.5u 1.0u 1.0u 2.0u 3.0u 5.0u 10.0u} {0.105u 0.20u 0.30u 0.40u 0.50u 1.0u 2.0u}   {0.002p 0.02p 0.2p} {0.2u 0.4u 0.8u}
charMos pch_18ud12_mac   p $PVT VDD12 {0.32u 0.5u 1.0u 1.0u 2.0u 3.0u 5.0u 10.0u} {0.09u 0.20u 0.30u 0.40u 0.50u 1.0u 2.0u}   {0.002p 0.02p 0.2p} {0.2u 0.4u 0.8u}

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
