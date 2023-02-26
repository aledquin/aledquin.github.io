#!/bin/tcsh -f 

set pincheck = "$PWD/dwc_ddrphy_repeater_blocks.pincheck"
rm $pincheck


/remote/us01home50/ljames/GitLab/ddr-hbm-phy-automation-team/ddr-ckt-rel/dev/main/bin/alphaPinCheck.pl\
     -verbosity 1 \
     -log $pincheck\
     -nousage\
     -appendlog\
     -macro dwc_ddrphy_rpt1ch_ns\
     -tech tsmc12ffcll-18\
     -lefObsLayers 'M1 M2 M3 M4 M5 M6 M7 M8 M9 M10 M11 MTOP MTOP-1 OVERLAP'\
     -lefPinLayers 'M1 M2 M3 M4 M5 M6 M7 M8 M9 M10 M11 MTOP MTOP-1 OVERLAP'\
     -PGlayers 'M8 M9 M10 M11 MTOP MTOP-1'\
     -since '2022-11-28 17:33:00'\
     -dateRef CDATE\
     -bracket square\
     -streamLayermap /remote/cad-rep/projects/cad/c243-tsmc12ffcll-1.8v/rel6.0.1/cad/9M_2Xa1Xd_h_3Xe_vhv_2Z/stream/STD/stream.layermap\
     -verilog /u/$USER/p4_ws/depot/products/lpddr54/project/d856-lpddr54-tsmc12ffc18/ckt/rel/dwc_ddrphy_repeater_blocks/2.00a/macro/behavior/dwc_ddrphy_repeater_blocks.v\
     -gds /u/$USER/p4_ws/depot/products/lpddr54/project/d856-lpddr54-tsmc12ffc18/ckt/rel/dwc_ddrphy_repeater_blocks/2.00a/macro/gds/9M_2Xa1Xd_h_3Xe_vhv_2Z/dwc_ddrphy_repeater_blocks.gds.gz\
     -verilog /u/$USER/p4_ws/depot/products/lpddr54/project/d856-lpddr54-tsmc12ffc18/ckt/rel/dwc_ddrphy_repeater_blocks/2.00a/macro/interface/dwc_ddrphy_repeater_blocks_interface.v\
     -lef /u/$USER/p4_ws/depot/products/lpddr54/project/d856-lpddr54-tsmc12ffc18/ckt/rel/dwc_ddrphy_repeater_blocks/2.00a/macro/lef/9M_2Xa1Xd_h_3Xe_vhv_2Z/dwc_ddrphy_repeater_blocks.lef\
     -lef /u/$USER/p4_ws/depot/products/lpddr54/project/d856-lpddr54-tsmc12ffc18/ckt/rel/dwc_ddrphy_repeater_blocks/2.00a/macro/lef/9M_2Xa1Xd_h_3Xe_vhv_2Z/dwc_ddrphy_repeater_blocks_merged.lef\
     -cdl /u/$USER/p4_ws/depot/products/lpddr54/project/d856-lpddr54-tsmc12ffc18/ckt/rel/dwc_ddrphy_repeater_blocks/2.00a/macro/netlist/9M_2Xa1Xd_h_3Xe_vhv_2Z/dwc_ddrphy_repeater_blocks.cdl\
     -liberty /u/$USER/p4_ws/depot/products/lpddr54/project/d856-lpddr54-tsmc12ffc18/ckt/rel/dwc_ddrphy_repeater_blocks/2.00a/macro/timing/9M_2Xa1Xd_h_3Xe_vhv_2Z/lib/dwc_ddrphy_repeater_blocks_ff0p88v0c.lib.gz\
     -liberty /u/$USER/p4_ws/depot/products/lpddr54/project/d856-lpddr54-tsmc12ffc18/ckt/rel/dwc_ddrphy_repeater_blocks/2.00a/macro/timing/9M_2Xa1Xd_h_3Xe_vhv_2Z/lib/dwc_ddrphy_repeater_blocks_ff0p88v125c.lib.gz\
     -liberty /u/$USER/p4_ws/depot/products/lpddr54/project/d856-lpddr54-tsmc12ffc18/ckt/rel/dwc_ddrphy_repeater_blocks/2.00a/macro/timing/9M_2Xa1Xd_h_3Xe_vhv_2Z/lib/dwc_ddrphy_repeater_blocks_ff0p88vn40c.lib.gz\
     -liberty /u/$USER/p4_ws/depot/products/lpddr54/project/d856-lpddr54-tsmc12ffc18/ckt/rel/dwc_ddrphy_repeater_blocks/2.00a/macro/timing/9M_2Xa1Xd_h_3Xe_vhv_2Z/lib/dwc_ddrphy_repeater_blocks_ss0p72v0c.lib.gz\
     -liberty /u/$USER/p4_ws/depot/products/lpddr54/project/d856-lpddr54-tsmc12ffc18/ckt/rel/dwc_ddrphy_repeater_blocks/2.00a/macro/timing/9M_2Xa1Xd_h_3Xe_vhv_2Z/lib/dwc_ddrphy_repeater_blocks_ss0p72v125c.lib.gz\
     -liberty /u/$USER/p4_ws/depot/products/lpddr54/project/d856-lpddr54-tsmc12ffc18/ckt/rel/dwc_ddrphy_repeater_blocks/2.00a/macro/timing/9M_2Xa1Xd_h_3Xe_vhv_2Z/lib/dwc_ddrphy_repeater_blocks_ss0p72vn40c.lib.gz\
     -liberty /u/$USER/p4_ws/depot/products/lpddr54/project/d856-lpddr54-tsmc12ffc18/ckt/rel/dwc_ddrphy_repeater_blocks/2.00a/macro/timing/9M_2Xa1Xd_h_3Xe_vhv_2Z/lib/dwc_ddrphy_repeater_blocks_tt0p8v25c.lib.gz\
     -liberty /u/$USER/p4_ws/depot/products/lpddr54/project/d856-lpddr54-tsmc12ffc18/ckt/rel/dwc_ddrphy_repeater_blocks/2.00a/macro/timing/9M_2Xa1Xd_h_3Xe_vhv_2Z/lib_pg/dwc_ddrphy_repeater_blocks_ff0p88v0c_pg.lib.gz\
     -liberty /u/$USER/p4_ws/depot/products/lpddr54/project/d856-lpddr54-tsmc12ffc18/ckt/rel/dwc_ddrphy_repeater_blocks/2.00a/macro/timing/9M_2Xa1Xd_h_3Xe_vhv_2Z/lib_pg/dwc_ddrphy_repeater_blocks_ff0p88v125c_pg.lib.gz\
     -liberty /u/$USER/p4_ws/depot/products/lpddr54/project/d856-lpddr54-tsmc12ffc18/ckt/rel/dwc_ddrphy_repeater_blocks/2.00a/macro/timing/9M_2Xa1Xd_h_3Xe_vhv_2Z/lib_pg/dwc_ddrphy_repeater_blocks_ff0p88vn40c_pg.lib.gz\
     -liberty /u/$USER/p4_ws/depot/products/lpddr54/project/d856-lpddr54-tsmc12ffc18/ckt/rel/dwc_ddrphy_repeater_blocks/2.00a/macro/timing/9M_2Xa1Xd_h_3Xe_vhv_2Z/lib_pg/dwc_ddrphy_repeater_blocks_ss0p72v0c_pg.lib.gz\
     -liberty /u/$USER/p4_ws/depot/products/lpddr54/project/d856-lpddr54-tsmc12ffc18/ckt/rel/dwc_ddrphy_repeater_blocks/2.00a/macro/timing/9M_2Xa1Xd_h_3Xe_vhv_2Z/lib_pg/dwc_ddrphy_repeater_blocks_ss0p72v125c_pg.lib.gz\
     -liberty /u/$USER/p4_ws/depot/products/lpddr54/project/d856-lpddr54-tsmc12ffc18/ckt/rel/dwc_ddrphy_repeater_blocks/2.00a/macro/timing/9M_2Xa1Xd_h_3Xe_vhv_2Z/lib_pg/dwc_ddrphy_repeater_blocks_ss0p72vn40c_pg.lib.gz\
     -liberty /u/$USER/p4_ws/depot/products/lpddr54/project/d856-lpddr54-tsmc12ffc18/ckt/rel/dwc_ddrphy_repeater_blocks/2.00a/macro/timing/9M_2Xa1Xd_h_3Xe_vhv_2Z/lib_pg/dwc_ddrphy_repeater_blocks_tt0p8v25c_pg.lib.gz \
         
#grep 'N/A' $pincheck
grep -i -B 3 'missing in' $pincheck

##/remote/us01home50/ljames/GitLab/ddr-hbm-phy-automation-team/ddr-ckt-rel/dev/main/bin/alphaPinCheck.pl ## -debug 1 -log /u/$USER/p4_ws/depot/products/lpddr54/project/d856-lpddr54-tsmc12ffc18/ckt/rel/dwc_ddrphy_repeater_blocks/2.00a/macro/dwc_ddrphy_repeater_blocks.pincheck -nousage -appendlog -macro dwc_ddrphy_rpt2ch_ns -tech tsmc12ffcll-18 -lefObsLayers 'M1 M2 M3 M4 M5 M6 M7 M8 M9 M10 M11 MTOP MTOP-1 OVERLAP' -lefPinLayers 'M1 M2 M3 M4 M5 M6 M7 M8 M9 M10 M11 MTOP MTOP-1 OVERLAP' -PGlayers 'M8 M9 M10 M11 MTOP MTOP-1' -since '2022-11-28 17:33:00' -dateRef CDATE -bracket square ## -streamLayermap /remote/cad-rep/projects/cad/c243-tsmc12ffcll-1.8v/rel6.0.1/cad/9M_2Xa1Xd_h_3Xe_vhv_2Z/stream/STD/stream.layermap -verilog /u/$USER/p4_ws/depot/products/lpddr54/project/d856-lpddr54-tsmc12ffc18/ckt/rel/dwc_ddrphy_repeater_blocks/2.00a/macro/behavior/dwc_ddrphy_repeater_blocks.v -gds /u/$USER/p4_ws/depot/products/lpddr54/project/d856-lpddr54-tsmc12ffc18/ckt/rel/dwc_ddrphy_repeater_blocks/2.00a/macro/gds/9M_2Xa1Xd_h_3Xe_vhv_2Z/dwc_ddrphy_repeater_blocks.gds.gz -verilog /u/$USER/p4_ws/depot/products/lpddr54/project/d856-lpddr54-tsmc12ffc18/ckt/rel/dwc_ddrphy_repeater_blocks/2.00a/macro/interface/dwc_ddrphy_repeater_blocks_interface.v -lef /u/$USER/p4_ws/depot/products/lpddr54/project/d856-lpddr54-tsmc12ffc18/ckt/rel/dwc_ddrphy_repeater_blocks/2.00a/macro/lef/9M_2Xa1Xd_h_3Xe_vhv_2Z/dwc_ddrphy_repeater_blocks.lef -lef /u/$USER/p4_ws/depot/products/lpddr54/project/d856-lpddr54-tsmc12ffc18/ckt/rel/dwc_ddrphy_repeater_blocks/2.00a/macro/lef/9M_2Xa1Xd_h_3Xe_vhv_2Z/dwc_ddrphy_repeater_blocks_merged.lef -cdl /u/$USER/p4_ws/depot/products/lpddr54/project/d856-lpddr54-tsmc12ffc18/ckt/rel/dwc_ddrphy_repeater_blocks/2.00a/macro/netlist/9M_2Xa1Xd_h_3Xe_vhv_2Z/dwc_ddrphy_repeater_blocks.cdl -liberty /u/$USER/p4_ws/depot/products/lpddr54/project/d856-lpddr54-tsmc12ffc18/ckt/rel/dwc_ddrphy_repeater_blocks/2.00a/macro/timing/9M_2Xa1Xd_h_3Xe_vhv_2Z/lib/dwc_ddrphy_repeater_blocks_ff0p88v0c.lib.gz -liberty /u/$USER/p4_ws/depot/products/lpddr54/project/d856-lpddr54-tsmc12ffc18/ckt/rel/dwc_ddrphy_repeater_blocks/2.00a/macro/timing/9M_2Xa1Xd_h_3Xe_vhv_2Z/lib/dwc_ddrphy_repeater_blocks_ff0p88v125c.lib.gz -liberty /u/$USER/p4_ws/depot/products/lpddr54/project/d856-lpddr54-tsmc12ffc18/ckt/rel/dwc_ddrphy_repeater_blocks/2.00a/macro/timing/9M_2Xa1Xd_h_3Xe_vhv_2Z/lib/dwc_ddrphy_repeater_blocks_ff0p88vn40c.lib.gz -liberty /u/$USER/p4_ws/depot/products/lpddr54/project/d856-lpddr54-tsmc12ffc18/ckt/rel/dwc_ddrphy_repeater_blocks/2.00a/macro/timing/9M_2Xa1Xd_h_3Xe_vhv_2Z/lib/dwc_ddrphy_repeater_blocks_ss0p72v0c.lib.gz -liberty /u/$USER/p4_ws/depot/products/lpddr54/project/d856-lpddr54-tsmc12ffc18/ckt/rel/dwc_ddrphy_repeater_blocks/2.00a/macro/timing/9M_2Xa1Xd_h_3Xe_vhv_2Z/lib/dwc_ddrphy_repeater_blocks_ss0p72v125c.lib.gz -liberty /u/$USER/p4_ws/depot/products/lpddr54/project/d856-lpddr54-tsmc12ffc18/ckt/rel/dwc_ddrphy_repeater_blocks/2.00a/macro/timing/9M_2Xa1Xd_h_3Xe_vhv_2Z/lib/dwc_ddrphy_repeater_blocks_ss0p72vn40c.lib.gz -liberty /u/$USER/p4_ws/depot/products/lpddr54/project/d856-lpddr54-tsmc12ffc18/ckt/rel/dwc_ddrphy_repeater_blocks/2.00a/macro/timing/9M_2Xa1Xd_h_3Xe_vhv_2Z/lib/dwc_ddrphy_repeater_blocks_tt0p8v25c.lib.gz -liberty /u/$USER/p4_ws/depot/products/lpddr54/project/d856-lpddr54-tsmc12ffc18/ckt/rel/dwc_ddrphy_repeater_blocks/2.00a/macro/timing/9M_2Xa1Xd_h_3Xe_vhv_2Z/lib_pg/dwc_ddrphy_repeater_blocks_ff0p88v0c_pg.lib.gz -liberty /u/$USER/p4_ws/depot/products/lpddr54/project/d856-lpddr54-tsmc12ffc18/ckt/rel/dwc_ddrphy_repeater_blocks/2.00a/macro/timing/9M_2Xa1Xd_h_3Xe_vhv_2Z/lib_pg/dwc_ddrphy_repeater_blocks_ff0p88v125c_pg.lib.gz -liberty /u/$USER/p4_ws/depot/products/lpddr54/project/d856-lpddr54-tsmc12ffc18/ckt/rel/dwc_ddrphy_repeater_blocks/2.00a/macro/timing/9M_2Xa1Xd_h_3Xe_vhv_2Z/lib_pg/dwc_ddrphy_repeater_blocks_ff0p88vn40c_pg.lib.gz -liberty /u/$USER/p4_ws/depot/products/lpddr54/project/d856-lpddr54-tsmc12ffc18/ckt/rel/dwc_ddrphy_repeater_blocks/2.00a/macro/timing/9M_2Xa1Xd_h_3Xe_vhv_2Z/lib_pg/dwc_ddrphy_repeater_blocks_ss0p72v0c_pg.lib.gz -liberty /u/$USER/p4_ws/depot/products/lpddr54/project/d856-lpddr54-tsmc12ffc18/ckt/rel/dwc_ddrphy_repeater_blocks/2.00a/macro/timing/9M_2Xa1Xd_h_3Xe_vhv_2Z/lib_pg/dwc_ddrphy_repeater_blocks_ss0p72v125c_pg.lib.gz -liberty /u/$USER/p4_ws/depot/products/lpddr54/project/d856-lpddr54-tsmc12ffc18/ckt/rel/dwc_ddrphy_repeater_blocks/2.00a/macro/timing/9M_2Xa1Xd_h_3Xe_vhv_2Z/lib_pg/dwc_ddrphy_repeater_blocks_ss0p72vn40c_pg.lib.gz -liberty /u/$USER/p4_ws/depot/products/lpddr54/project/d856-lpddr54-tsmc12ffc18/ckt/rel/dwc_ddrphy_repeater_blocks/2.00a/macro/timing/9M_2Xa1Xd_h_3Xe_vhv_2Z/lib_pg/dwc_ddrphy_repeater_blocks_tt0p8v25c_pg.lib.gz 
##/remote/us01home50/ljames/GitLab/ddr-hbm-phy-automation-team/ddr-ckt-rel/dev/main/bin/alphaPinCheck.pl ## -debug 1 -log /u/$USER/p4_ws/depot/products/lpddr54/project/d856-lpddr54-tsmc12ffc18/ckt/rel/dwc_ddrphy_repeater_blocks/2.00a/macro/dwc_ddrphy_repeater_blocks.pincheck -nousage -appendlog -macro dwc_ddrphy_rpt1ch_ew -tech tsmc12ffcll-18 -lefObsLayers 'M1 M2 M3 M4 M5 M6 M7 M8 M9 M10 M11 MTOP MTOP-1 OVERLAP' -lefPinLayers 'M1 M2 M3 M4 M5 M6 M7 M8 M9 M10 M11 MTOP MTOP-1 OVERLAP' -PGlayers 'M8 M9 M10 M11 MTOP MTOP-1' -since '2022-11-28 17:33:00' -dateRef CDATE -bracket square ## -streamLayermap /remote/cad-rep/projects/cad/c243-tsmc12ffcll-1.8v/rel6.0.1/cad/9M_2Xa1Xd_h_3Xe_vhv_2Z/stream/STD/stream.layermap -verilog /u/$USER/p4_ws/depot/products/lpddr54/project/d856-lpddr54-tsmc12ffc18/ckt/rel/dwc_ddrphy_repeater_blocks/2.00a/macro/behavior/dwc_ddrphy_repeater_blocks.v -gds /u/$USER/p4_ws/depot/products/lpddr54/project/d856-lpddr54-tsmc12ffc18/ckt/rel/dwc_ddrphy_repeater_blocks/2.00a/macro/gds/9M_2Xa1Xd_h_3Xe_vhv_2Z/dwc_ddrphy_repeater_blocks.gds.gz -verilog /u/$USER/p4_ws/depot/products/lpddr54/project/d856-lpddr54-tsmc12ffc18/ckt/rel/dwc_ddrphy_repeater_blocks/2.00a/macro/interface/dwc_ddrphy_repeater_blocks_interface.v -lef /u/$USER/p4_ws/depot/products/lpddr54/project/d856-lpddr54-tsmc12ffc18/ckt/rel/dwc_ddrphy_repeater_blocks/2.00a/macro/lef/9M_2Xa1Xd_h_3Xe_vhv_2Z/dwc_ddrphy_repeater_blocks.lef -lef /u/$USER/p4_ws/depot/products/lpddr54/project/d856-lpddr54-tsmc12ffc18/ckt/rel/dwc_ddrphy_repeater_blocks/2.00a/macro/lef/9M_2Xa1Xd_h_3Xe_vhv_2Z/dwc_ddrphy_repeater_blocks_merged.lef -cdl /u/$USER/p4_ws/depot/products/lpddr54/project/d856-lpddr54-tsmc12ffc18/ckt/rel/dwc_ddrphy_repeater_blocks/2.00a/macro/netlist/9M_2Xa1Xd_h_3Xe_vhv_2Z/dwc_ddrphy_repeater_blocks.cdl -liberty /u/$USER/p4_ws/depot/products/lpddr54/project/d856-lpddr54-tsmc12ffc18/ckt/rel/dwc_ddrphy_repeater_blocks/2.00a/macro/timing/9M_2Xa1Xd_h_3Xe_vhv_2Z/lib/dwc_ddrphy_repeater_blocks_ff0p88v0c.lib.gz -liberty /u/$USER/p4_ws/depot/products/lpddr54/project/d856-lpddr54-tsmc12ffc18/ckt/rel/dwc_ddrphy_repeater_blocks/2.00a/macro/timing/9M_2Xa1Xd_h_3Xe_vhv_2Z/lib/dwc_ddrphy_repeater_blocks_ff0p88v125c.lib.gz -liberty /u/$USER/p4_ws/depot/products/lpddr54/project/d856-lpddr54-tsmc12ffc18/ckt/rel/dwc_ddrphy_repeater_blocks/2.00a/macro/timing/9M_2Xa1Xd_h_3Xe_vhv_2Z/lib/dwc_ddrphy_repeater_blocks_ff0p88vn40c.lib.gz -liberty /u/$USER/p4_ws/depot/products/lpddr54/project/d856-lpddr54-tsmc12ffc18/ckt/rel/dwc_ddrphy_repeater_blocks/2.00a/macro/timing/9M_2Xa1Xd_h_3Xe_vhv_2Z/lib/dwc_ddrphy_repeater_blocks_ss0p72v0c.lib.gz -liberty /u/$USER/p4_ws/depot/products/lpddr54/project/d856-lpddr54-tsmc12ffc18/ckt/rel/dwc_ddrphy_repeater_blocks/2.00a/macro/timing/9M_2Xa1Xd_h_3Xe_vhv_2Z/lib/dwc_ddrphy_repeater_blocks_ss0p72v125c.lib.gz -liberty /u/$USER/p4_ws/depot/products/lpddr54/project/d856-lpddr54-tsmc12ffc18/ckt/rel/dwc_ddrphy_repeater_blocks/2.00a/macro/timing/9M_2Xa1Xd_h_3Xe_vhv_2Z/lib/dwc_ddrphy_repeater_blocks_ss0p72vn40c.lib.gz -liberty /u/$USER/p4_ws/depot/products/lpddr54/project/d856-lpddr54-tsmc12ffc18/ckt/rel/dwc_ddrphy_repeater_blocks/2.00a/macro/timing/9M_2Xa1Xd_h_3Xe_vhv_2Z/lib/dwc_ddrphy_repeater_blocks_tt0p8v25c.lib.gz -liberty /u/$USER/p4_ws/depot/products/lpddr54/project/d856-lpddr54-tsmc12ffc18/ckt/rel/dwc_ddrphy_repeater_blocks/2.00a/macro/timing/9M_2Xa1Xd_h_3Xe_vhv_2Z/lib_pg/dwc_ddrphy_repeater_blocks_ff0p88v0c_pg.lib.gz -liberty /u/$USER/p4_ws/depot/products/lpddr54/project/d856-lpddr54-tsmc12ffc18/ckt/rel/dwc_ddrphy_repeater_blocks/2.00a/macro/timing/9M_2Xa1Xd_h_3Xe_vhv_2Z/lib_pg/dwc_ddrphy_repeater_blocks_ff0p88v125c_pg.lib.gz -liberty /u/$USER/p4_ws/depot/products/lpddr54/project/d856-lpddr54-tsmc12ffc18/ckt/rel/dwc_ddrphy_repeater_blocks/2.00a/macro/timing/9M_2Xa1Xd_h_3Xe_vhv_2Z/lib_pg/dwc_ddrphy_repeater_blocks_ff0p88vn40c_pg.lib.gz -liberty /u/$USER/p4_ws/depot/products/lpddr54/project/d856-lpddr54-tsmc12ffc18/ckt/rel/dwc_ddrphy_repeater_blocks/2.00a/macro/timing/9M_2Xa1Xd_h_3Xe_vhv_2Z/lib_pg/dwc_ddrphy_repeater_blocks_ss0p72v0c_pg.lib.gz -liberty /u/$USER/p4_ws/depot/products/lpddr54/project/d856-lpddr54-tsmc12ffc18/ckt/rel/dwc_ddrphy_repeater_blocks/2.00a/macro/timing/9M_2Xa1Xd_h_3Xe_vhv_2Z/lib_pg/dwc_ddrphy_repeater_blocks_ss0p72v125c_pg.lib.gz -liberty /u/$USER/p4_ws/depot/products/lpddr54/project/d856-lpddr54-tsmc12ffc18/ckt/rel/dwc_ddrphy_repeater_blocks/2.00a/macro/timing/9M_2Xa1Xd_h_3Xe_vhv_2Z/lib_pg/dwc_ddrphy_repeater_blocks_ss0p72vn40c_pg.lib.gz -liberty /u/$USER/p4_ws/depot/products/lpddr54/project/d856-lpddr54-tsmc12ffc18/ckt/rel/dwc_ddrphy_repeater_blocks/2.00a/macro/timing/9M_2Xa1Xd_h_3Xe_vhv_2Z/lib_pg/dwc_ddrphy_repeater_blocks_tt0p8v25c_pg.lib.gz 
##/remote/us01home50/ljames/GitLab/ddr-hbm-phy-automation-team/ddr-ckt-rel/dev/main/bin/alphaPinCheck.pl ## -debug 1 -log /u/$USER/p4_ws/depot/products/lpddr54/project/d856-lpddr54-tsmc12ffc18/ckt/rel/dwc_ddrphy_repeater_blocks/2.00a/macro/dwc_ddrphy_repeater_blocks.pincheck -nousage -appendlog -macro dwc_ddrphy_rpt2ch_ew -tech tsmc12ffcll-18 -lefObsLayers 'M1 M2 M3 M4 M5 M6 M7 M8 M9 M10 M11 MTOP MTOP-1 OVERLAP' -lefPinLayers 'M1 M2 M3 M4 M5 M6 M7 M8 M9 M10 M11 MTOP MTOP-1 OVERLAP' -PGlayers 'M8 M9 M10 M11 MTOP MTOP-1' -since '2022-11-28 17:33:00' -dateRef CDATE -bracket square ## -streamLayermap /remote/cad-rep/projects/cad/c243-tsmc12ffcll-1.8v/rel6.0.1/cad/9M_2Xa1Xd_h_3Xe_vhv_2Z/stream/STD/stream.layermap -verilog /u/$USER/p4_ws/depot/products/lpddr54/project/d856-lpddr54-tsmc12ffc18/ckt/rel/dwc_ddrphy_repeater_blocks/2.00a/macro/behavior/dwc_ddrphy_repeater_blocks.v -gds /u/$USER/p4_ws/depot/products/lpddr54/project/d856-lpddr54-tsmc12ffc18/ckt/rel/dwc_ddrphy_repeater_blocks/2.00a/macro/gds/9M_2Xa1Xd_h_3Xe_vhv_2Z/dwc_ddrphy_repeater_blocks.gds.gz -verilog /u/$USER/p4_ws/depot/products/lpddr54/project/d856-lpddr54-tsmc12ffc18/ckt/rel/dwc_ddrphy_repeater_blocks/2.00a/macro/interface/dwc_ddrphy_repeater_blocks_interface.v -lef /u/$USER/p4_ws/depot/products/lpddr54/project/d856-lpddr54-tsmc12ffc18/ckt/rel/dwc_ddrphy_repeater_blocks/2.00a/macro/lef/9M_2Xa1Xd_h_3Xe_vhv_2Z/dwc_ddrphy_repeater_blocks.lef -lef /u/$USER/p4_ws/depot/products/lpddr54/project/d856-lpddr54-tsmc12ffc18/ckt/rel/dwc_ddrphy_repeater_blocks/2.00a/macro/lef/9M_2Xa1Xd_h_3Xe_vhv_2Z/dwc_ddrphy_repeater_blocks_merged.lef -cdl /u/$USER/p4_ws/depot/products/lpddr54/project/d856-lpddr54-tsmc12ffc18/ckt/rel/dwc_ddrphy_repeater_blocks/2.00a/macro/netlist/9M_2Xa1Xd_h_3Xe_vhv_2Z/dwc_ddrphy_repeater_blocks.cdl -liberty /u/$USER/p4_ws/depot/products/lpddr54/project/d856-lpddr54-tsmc12ffc18/ckt/rel/dwc_ddrphy_repeater_blocks/2.00a/macro/timing/9M_2Xa1Xd_h_3Xe_vhv_2Z/lib/dwc_ddrphy_repeater_blocks_ff0p88v0c.lib.gz -liberty /u/$USER/p4_ws/depot/products/lpddr54/project/d856-lpddr54-tsmc12ffc18/ckt/rel/dwc_ddrphy_repeater_blocks/2.00a/macro/timing/9M_2Xa1Xd_h_3Xe_vhv_2Z/lib/dwc_ddrphy_repeater_blocks_ff0p88v125c.lib.gz -liberty /u/$USER/p4_ws/depot/products/lpddr54/project/d856-lpddr54-tsmc12ffc18/ckt/rel/dwc_ddrphy_repeater_blocks/2.00a/macro/timing/9M_2Xa1Xd_h_3Xe_vhv_2Z/lib/dwc_ddrphy_repeater_blocks_ff0p88vn40c.lib.gz -liberty /u/$USER/p4_ws/depot/products/lpddr54/project/d856-lpddr54-tsmc12ffc18/ckt/rel/dwc_ddrphy_repeater_blocks/2.00a/macro/timing/9M_2Xa1Xd_h_3Xe_vhv_2Z/lib/dwc_ddrphy_repeater_blocks_ss0p72v0c.lib.gz -liberty /u/$USER/p4_ws/depot/products/lpddr54/project/d856-lpddr54-tsmc12ffc18/ckt/rel/dwc_ddrphy_repeater_blocks/2.00a/macro/timing/9M_2Xa1Xd_h_3Xe_vhv_2Z/lib/dwc_ddrphy_repeater_blocks_ss0p72v125c.lib.gz -liberty /u/$USER/p4_ws/depot/products/lpddr54/project/d856-lpddr54-tsmc12ffc18/ckt/rel/dwc_ddrphy_repeater_blocks/2.00a/macro/timing/9M_2Xa1Xd_h_3Xe_vhv_2Z/lib/dwc_ddrphy_repeater_blocks_ss0p72vn40c.lib.gz -liberty /u/$USER/p4_ws/depot/products/lpddr54/project/d856-lpddr54-tsmc12ffc18/ckt/rel/dwc_ddrphy_repeater_blocks/2.00a/macro/timing/9M_2Xa1Xd_h_3Xe_vhv_2Z/lib/dwc_ddrphy_repeater_blocks_tt0p8v25c.lib.gz -liberty /u/$USER/p4_ws/depot/products/lpddr54/project/d856-lpddr54-tsmc12ffc18/ckt/rel/dwc_ddrphy_repeater_blocks/2.00a/macro/timing/9M_2Xa1Xd_h_3Xe_vhv_2Z/lib_pg/dwc_ddrphy_repeater_blocks_ff0p88v0c_pg.lib.gz -liberty /u/$USER/p4_ws/depot/products/lpddr54/project/d856-lpddr54-tsmc12ffc18/ckt/rel/dwc_ddrphy_repeater_blocks/2.00a/macro/timing/9M_2Xa1Xd_h_3Xe_vhv_2Z/lib_pg/dwc_ddrphy_repeater_blocks_ff0p88v125c_pg.lib.gz -liberty /u/$USER/p4_ws/depot/products/lpddr54/project/d856-lpddr54-tsmc12ffc18/ckt/rel/dwc_ddrphy_repeater_blocks/2.00a/macro/timing/9M_2Xa1Xd_h_3Xe_vhv_2Z/lib_pg/dwc_ddrphy_repeater_blocks_ff0p88vn40c_pg.lib.gz -liberty /u/$USER/p4_ws/depot/products/lpddr54/project/d856-lpddr54-tsmc12ffc18/ckt/rel/dwc_ddrphy_repeater_blocks/2.00a/macro/timing/9M_2Xa1Xd_h_3Xe_vhv_2Z/lib_pg/dwc_ddrphy_repeater_blocks_ss0p72v0c_pg.lib.gz -liberty /u/$USER/p4_ws/depot/products/lpddr54/project/d856-lpddr54-tsmc12ffc18/ckt/rel/dwc_ddrphy_repeater_blocks/2.00a/macro/timing/9M_2Xa1Xd_h_3Xe_vhv_2Z/lib_pg/dwc_ddrphy_repeater_blocks_ss0p72v125c_pg.lib.gz -liberty /u/$USER/p4_ws/depot/products/lpddr54/project/d856-lpddr54-tsmc12ffc18/ckt/rel/dwc_ddrphy_repeater_blocks/2.00a/macro/timing/9M_2Xa1Xd_h_3Xe_vhv_2Z/lib_pg/dwc_ddrphy_repeater_blocks_ss0p72vn40c_pg.lib.gz -liberty /u/$USER/p4_ws/depot/products/lpddr54/project/d856-lpddr54-tsmc12ffc18/ckt/rel/dwc_ddrphy_repeater_blocks/2.00a/macro/timing/9M_2Xa1Xd_h_3Xe_vhv_2Z/lib_pg/dwc_ddrphy_repeater_blocks_tt0p8v25c_pg.lib.gz 
