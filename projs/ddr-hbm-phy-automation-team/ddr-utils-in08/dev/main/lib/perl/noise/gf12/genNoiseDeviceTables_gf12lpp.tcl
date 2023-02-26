#!/depot/tcl8.6.3/bin/tclsh8.6
# nolint Main

source setup_gf12lpp.tcl
############################  Begin tt1p80v25c  ############################
create_operating_condition tt1p80v25c
set_opc_process tt1p80v25c {
  {.lib "/remote/cad-rep/projects/cad/c146-gf12lpp-1.8v/rel2.3.1/cad/models/hspice/bjt.lib" bip_t}
  {.lib "/remote/cad-rep/projects/cad/c146-gf12lpp-1.8v/rel2.3.1/cad/models/hspice/cap.lib" cap_t}
  {.lib "/remote/cad-rep/projects/cad/c146-gf12lpp-1.8v/rel2.3.1/cad/models/hspice/diode.lib" dio_t}
  {.lib "/remote/cad-rep/projects/cad/c146-gf12lpp-1.8v/rel2.3.1/cad/models/hspice/moscap_hv.lib" nmoscaphv_t}
  {.lib "/remote/cad-rep/projects/cad/c146-gf12lpp-1.8v/rel2.3.1/cad/models/hspice/moscap.lib" nmoscap_t}
  {.lib "/remote/cad-rep/projects/cad/c146-gf12lpp-1.8v/rel2.3.1/cad/models/hspice/mos_hv.lib" moshv_tt}
  {.lib "/remote/cad-rep/projects/cad/c146-gf12lpp-1.8v/rel2.3.1/cad/models/hspice/mos.lib" mos_tt}
  {.lib "/remote/cad-rep/projects/cad/c146-gf12lpp-1.8v/rel2.3.1/cad/models/hspice/res.lib" res_t}
}
add_opc_supplies tt1p80v25c vph 1.80 
#VDDQ 1.2 VDD18 1.8 VDD15 1.5 VDD12 1.2
add_opc_grounds tt1p80v25c gd
set_opc_default_voltage tt1p80v25c 1.80
set_opc_temperature tt1p80v25c 25
############################  End tt1p80v25c  ############################


set hspiceVersion hspice
set PVT tt1p80v25c
set outFile "gf12lpp_${PVT}_noise.tech"
if [file exists $outFile] {file delete $outFile}

set vSupply [supplyVoltage $PVT vph]

## resistor
charRes3t rmres $PVT vph {0.4u 1.0u 2.0u 4.0u 8.0u 16u 32u 50u} {0.184u 0.4u 1u 2u 4u 8u 16u}

##  Thin oxide nfets,mpodes
foreach device {egnfet} {
    charMos $device n $PVT vph {2 4 6 8 10 12} {0.15u 0.20u} {0.002p } {0.2u}
}

## Thin-ox npode devices
foreach device {egpfet} {
    charMos $device p $PVT vph {2 4 6 8 10 12} {0.15u 0.20u} {0.002p} {0.2u}
}


#commented by kuldeep
##  Thin oxide pfets
#foreach device {pch_lvt_mac pch_ulvt_mac pch_svt_mac pch_mpodelvt_mac pch_mpodeulvt_mac pch_mpodesvt_mac} {
#    charMos $device p $PVT VDD {2 4 6 8 10 12} {0.016u 0.018u 0.02u 0.036u 0.072u 0.24u} {0.002p 0.02p 0.2p} {0.2u 0.4u 0.8u}
#}

## Thin-ox ppode devices
#foreach device {ppode_lvt_mac ppode_ulvt_mac ppode_svt_mac} {
#    charPode $device p $PVT VDD {2 4 6 8 10 12} {0.016u 0.018u 0.02u 0.036u 0.072u 0.24u} {0.002p 0.02p 0.2p} {0.2u 0.4u 0.8u}
#}


##  hv Nfets
#charMos nch_18_mac        n $PVT VDD18 {4 8 16 20} {0.135u 0.17u 0.205u 0.240u}  {0.002p 0.02p 0.2p} {0.2u 0.4u 0.8u}
#charMos nch_18ud15_mac    n $PVT VDD15 {4 8 16 20} {0.086u 0.14u 0.19u 0.240u}   {0.002p 0.02p 0.2p} {0.2u 0.4u 0.8u}
#charMos nch_18ud12_mac    n $PVT VDD12 {4 8 16 20} {0.081u 0.128u 0.184u 0.240u} {0.002p 0.02p 0.2p} {0.2u 0.4u 0.8u}
#charPode npode_18_mac     n $PVT VDD18 {4 8 16 20} {0.135u 0.17u 0.205u 0.240u}  {0.002p 0.02p 0.2p} {0.2u 0.4u 0.8u}
#charPode npode_18ud15_mac n $PVT VDD15 {4 8 16 20} {0.086u 0.14u 0.19u 0.240u}   {0.002p 0.02p 0.2p} {0.2u 0.4u 0.8u}
#charPode npode_18ud12_mac n $PVT VDD12 {4 8 16 20} {0.081u 0.128u 0.184u 0.240u} {0.002p 0.02p 0.2p} {0.2u 0.4u 0.8u}
#
###  hv Pfets
#charMos pch_18_mac       p $PVT VDD18 {4 8 16 20} {0.135u 0.17u 0.205u 0.240u}  {0.002p 0.02p 0.2p} {0.2u 0.4u 0.8u}
#charMos pch_18ud15_mac   p $PVT VDD15 {4 8 16 20} {0.086u 0.14u 0.19u 0.240u}   {0.002p 0.02p 0.2p} {0.2u 0.4u 0.8u}
#charMos pch_18ud12_mac   p $PVT VDD12 {4 8 16 20} {0.081u 0.128u 0.184u 0.240u} {0.002p 0.02p 0.2p} {0.2u 0.4u 0.8u}
#charPode ppode_18_mac     p $PVT VDD18 {4 8 16 20} {0.135u 0.17u 0.205u 0.240u}  {0.002p 0.02p 0.2p} {0.2u 0.4u 0.8u}
#charPode ppode_18ud15_mac p $PVT VDD15 {4 8 16 20} {0.086u 0.14u 0.19u 0.240u}   {0.002p 0.02p 0.2p} {0.2u 0.4u 0.8u}
#charPode ppode_18ud12_mac p $PVT VDD12 {4 8 16 20} {0.081u 0.128u 0.184u 0.240u} {0.002p 0.02p 0.2p} {0.2u 0.4u 0.8u}

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
