#!/depot/tcl8.6.3/bin/tclsh8.6
# nolint Main

source setup_tsmc.tcl
############################  Begin tt0p85v25c  ############################
create_operating_condition tt0p85v25c
set_opc_process tt0p85v25c {
  {.lib "/remote/proj/ddr43/d519-ddr43-tsmc7ff18/rel0.30a/cad/models/hspice/bjt.lib" bip_t}
  {.lib "/remote/proj/ddr43/d519-ddr43-tsmc7ff18/rel0.30a/cad/models/hspice/cap.lib" cap_t}
  {.lib "/remote/proj/ddr43/d519-ddr43-tsmc7ff18/rel0.30a/cad/models/hspice/diode.lib" dio_t}
  {.lib "/remote/proj/ddr43/d519-ddr43-tsmc7ff18/rel0.30a/cad/models/hspice/momcap.lib" momcap_t}
  {.lib "/remote/proj/ddr43/d519-ddr43-tsmc7ff18/rel0.30a/cad/models/hspice/moscap_hv.lib" nmoscaphv_s}
  {.lib "/remote/proj/ddr43/d519-ddr43-tsmc7ff18/rel0.30a/cad/models/hspice/moscap.lib" nmoscap_s}
  {.lib "/remote/proj/ddr43/d519-ddr43-tsmc7ff18/rel0.30a/cad/models/hspice/mos_hv.lib" moshv_tt}
  {.lib "/remote/proj/ddr43/d519-ddr43-tsmc7ff18/rel0.30a/cad/models/hspice/mos_hvud.lib" moshvud_tt}
  {.lib "/remote/proj/ddr43/d519-ddr43-tsmc7ff18/rel0.30a/cad/models/hspice/mos.lib" mos_tt}
  {.lib "/remote/proj/ddr43/d519-ddr43-tsmc7ff18/rel0.30a/cad/models/hspice/mos_lvt.lib" moslvt_tt}
  {.lib "/remote/proj/ddr43/d519-ddr43-tsmc7ff18/rel0.30a/cad/models/hspice/mos_ulvt.lib"  mosulvt_tt}
  {.lib "/remote/proj/ddr43/d519-ddr43-tsmc7ff18/rel0.30a/cad/models/hspice/res.lib" res_t}
}
add_opc_supplies tt0p85v25c VDD 0.85 VDD12 1.2 VDD15 1.5 VDD18 1.8
add_opc_grounds tt0p85v25c VSS 
set_opc_default_voltage tt0p85v25c 0.85
set_opc_temperature tt0p85v25c 25
############################  End tt0p85v25c  ############################



set hspiceVersion hspice
set PVT tt0p85v25c
set outFile "tsmc7ff_${PVT}_noise.tech"
if [file exists $outFile] {file delete $outFile}

set vSupply [supplyVoltage $PVT VDD]

## resistor
charRes3t rhim_nw $PVT VDD {0.5u 1.0u 1.5u 2.0u 2.5u 3.0u} {0.5u 1.0u 1.5u 2.0u 2.5u 3.0u}


##  Thin oxide nfets,mpodes
foreach device {nch_lvt_mac nch_ulvt_mac nch_svt_mac} {
    charMos $device n $PVT VDD {4 6 8} {0.008u 0.011u 0.02u 0.036u 0.072u 0.24u} {0.002p 0.02p 0.2p} {0.2u 0.4u 0.8u}
}

## Thin-ox npode devices
foreach device {npode_lvt_mac npode_ulvt_mac npode_svt_mac} {
    charPode $device n $PVT VDD {4 6 8} {0.008u 0.011u 0.02u 0.036u 0.072u 0.24u} {0.002p 0.02p 0.2p} {0.2u 0.4u 0.8u}
}


##  Thin oxide pfets
foreach device {pch_lvt_mac pch_ulvt_mac pch_svt_mac} {
    charMos $device p $PVT VDD {4 6 8} {0.008u 0.011u 0.02u 0.036u 0.072u 0.24u} {0.002p 0.02p 0.2p} {0.2u 0.4u 0.8u}
}

## Thin-ox ppode devices
foreach device {ppode_lvt_mac ppode_ulvt_mac ppode_svt_mac} {
    charPode $device p $PVT VDD {4 6 8} {0.008u 0.011u 0.02u 0.036u 0.072u 0.24u} {0.002p 0.02p 0.2p} {0.2u 0.4u 0.8u}
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
