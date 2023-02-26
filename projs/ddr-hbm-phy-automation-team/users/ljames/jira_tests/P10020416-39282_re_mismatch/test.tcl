#!/depot/tcl8.6.3/bin/tclsh8.6
set oldf {//depot/products/lpddr5x_ddr5_phy/ddr5/project/d912-ddr5-tsmc3eff-12/fe/rel/1.01a/dwc_ddr5phyzcal_top/views/rtl/dwc_ddr5phy_rtl_syn_stdlib.v#1 - add change 11609705}
set f "//depot/products/lpddr5x_ddr5_phy/ddr5/project/d912-ddr5-tsmc3eff-12/fe/rel/1.01a/dwc_ddr5phyzcal_top/views/rtl/dwc_ddr5phy_regs_HMZCAL.v#1 - add change 11609705 (text)"
puts "f='$f'"
if [ regexp {^(\S+)#(\d+)\D+(\d+)} $f match depotFile ver changelist  ] {
    puts "match=$match"
    puts "a=$depotFile"
    puts "b=$ver"
    puts "c=$changelist"
} else { puts "RE no match" }




