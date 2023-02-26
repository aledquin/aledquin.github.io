#!/bin/tcsh -f

set P4_WS='/u/kevinxie/p4_ws'

# NOTE:  Run with these settings first
set SCRIPT = /remote/cad-rep/msip/tools/Shelltools/ddr-ckt-rel/2022.06-02/bin/alphaPinCheck.pl
set LOG    = ./dwc_ddrphy_vddqclamp_dq_ew.pincheck_20220602

# NOTE: Then (2nd) uncomment these two lines and run again. Then you can do a tkdiff of
#       The two different log files.
#       
#set SCRIPT = ~ljames/GitLab/ddr-hbm-phy-automation-team/ddr-ckt-rel/dev/main/bin/alphaPinCheck.pl
#set LOG    = ./dwc_ddrphy_vddqclamp_dq_ew.pincheck_ljames_gitlab

#	-log $P4_WS/depot/products/ddr54/project/d839-ddr54v2-tsmc7ff18/ckt/rel/dwc_ddrphy_vddqclamp_dq_ew/1.00a/macro/dwc_ddrphy_vddqclamp_dq_ew.pincheck  \
$SCRIPT \
	-log $LOG \
	-macro dwc_ddrphy_vddqclamp_dq_ew  \
	-tech tsmc7ff-18  \
	-lefObsLayers M0 M1 M2 M3 M4 M5 M6 M7 M8 M9 M10 M11 M12 M13 OVERLAP  \
	-lefPinLayers M0 M1 M2 M3 M4 M5 M6 M7 M8 M9 M10 M11 M12 M13 OVERLAP \
	-PGlayers M8 \
	-since 2022-05-23 14:26:04 \
	-dateRef CDATE \
	-bracket square \
	-streamLayermap /remote/cad-rep/projects/ddr54/d839-ddr54v2-tsmc7ff18/rel1.00_cktpcs/cad/13M_1X_h_1Xa_v_1Ya_h_5Y_vhvhv_2Yy2Z/stream/stream.layermap \
	-verilog $P4_WS/depot/products/ddr54/project/d839-ddr54v2-tsmc7ff18/ckt/rel/dwc_ddrphy_vddqclamp_dq_ew/1.00a/macro/behavior/dwc_ddrphy_vddqclamp_dq_ew.v \
	-cdl $P4_WS/depot/products/ddr54/project/d839-ddr54v2-tsmc7ff18/ckt/rel/dwc_ddrphy_vddqclamp_dq_ew/1.00a/macro/cosim/dwc_ddrphy_vddqclamp_dq_ew.sp \
	-gds $P4_WS/depot/products/ddr54/project/d839-ddr54v2-tsmc7ff18/ckt/rel/dwc_ddrphy_vddqclamp_dq_ew/1.00a/macro/gds/8M_2X_hv_1Ya_h_4Y_vhvh/dwc_ddrphy_vddqclamp_dq_ew.gds.gz \
	-verilog $P4_WS/depot/products/ddr54/project/d839-ddr54v2-tsmc7ff18/ckt/rel/dwc_ddrphy_vddqclamp_dq_ew/1.00a/macro/interface/dwc_ddrphy_vddqclamp_dq_ew_interface.v \
	-lef $P4_WS/depot/products/ddr54/project/d839-ddr54v2-tsmc7ff18/ckt/rel/dwc_ddrphy_vddqclamp_dq_ew/1.00a/macro/lef/8M_2X_hv_1Ya_h_4Y_vhvh/dwc_ddrphy_vddqclamp_dq_ew.lef \
	-lef $P4_WS/depot/products/ddr54/project/d839-ddr54v2-tsmc7ff18/ckt/rel/dwc_ddrphy_vddqclamp_dq_ew/1.00a/macro/lef/8M_2X_hv_1Ya_h_4Y_vhvh/dwc_ddrphy_vddqclamp_dq_ew_merged.lef \
	-cdl $P4_WS/depot/products/ddr54/project/d839-ddr54v2-tsmc7ff18/ckt/rel/dwc_ddrphy_vddqclamp_dq_ew/1.00a/macro/netlist/8M_2X_hv_1Ya_h_4Y_vhvh/dwc_ddrphy_vddqclamp_dq_ew.cdl \
	-pinCSV $P4_WS/depot/products/ddr54/project/d839-ddr54v2-tsmc7ff18/ckt/rel/dwc_ddrphy_vddqclamp_dq_ew/1.00a/macro/pininfo/dwc_ddrphy_vddqclamp_dq_ew.csv \
	-liberty $P4_WS/depot/products/ddr54/project/d839-ddr54v2-tsmc7ff18/ckt/rel/dwc_ddrphy_vddqclamp_dq_ew/1.00a/macro/timing/8M_2X_hv_1Ya_h_4Y_vhvh/lib_lvf/dwc_ddrphy_vddqclamp_dq_ew_15M_2X_hv_1Ya_h_5Y_vhvhv_2Yy2Yx2R_ffg0p825v0c.lib \
	-liberty $P4_WS/depot/products/ddr54/project/d839-ddr54v2-tsmc7ff18/ckt/rel/dwc_ddrphy_vddqclamp_dq_ew/1.00a/macro/timing/8M_2X_hv_1Ya_h_4Y_vhvh/lib_lvf/dwc_ddrphy_vddqclamp_dq_ew_15M_2X_hv_1Ya_h_5Y_vhvhv_2Yy2Yx2R_ffg0p825v110c.lib \
	-liberty $P4_WS/depot/products/ddr54/project/d839-ddr54v2-tsmc7ff18/ckt/rel/dwc_ddrphy_vddqclamp_dq_ew/1.00a/macro/timing/8M_2X_hv_1Ya_h_4Y_vhvh/lib_lvf/dwc_ddrphy_vddqclamp_dq_ew_15M_2X_hv_1Ya_h_5Y_vhvhv_2Yy2Yx2R_ffg0p935v0c.lib  \
	-liberty $P4_WS/depot/products/ddr54/project/d839-ddr54v2-tsmc7ff18/ckt/rel/dwc_ddrphy_vddqclamp_dq_ew/1.00a/macro/timing/8M_2X_hv_1Ya_h_4Y_vhvh/lib_lvf/dwc_ddrphy_vddqclamp_dq_ew_15M_2X_hv_1Ya_h_5Y_vhvhv_2Yy2Yx2R_ffg0p935v110c.lib \
	-liberty $P4_WS/depot/products/ddr54/project/d839-ddr54v2-tsmc7ff18/ckt/rel/dwc_ddrphy_vddqclamp_dq_ew/1.00a/macro/timing/8M_2X_hv_1Ya_h_4Y_vhvh/lib_lvf/dwc_ddrphy_vddqclamp_dq_ew_15M_2X_hv_1Ya_h_5Y_vhvhv_2Yy2Yx2R_ssg0p675v0c.lib \
	-liberty $P4_WS/depot/products/ddr54/project/d839-ddr54v2-tsmc7ff18/ckt/rel/dwc_ddrphy_vddqclamp_dq_ew/1.00a/macro/timing/8M_2X_hv_1Ya_h_4Y_vhvh/lib_lvf/dwc_ddrphy_vddqclamp_dq_ew_15M_2X_hv_1Ya_h_5Y_vhvhv_2Yy2Yx2R_ssg0p675v110c.lib \
	-liberty $P4_WS/depot/products/ddr54/project/d839-ddr54v2-tsmc7ff18/ckt/rel/dwc_ddrphy_vddqclamp_dq_ew/1.00a/macro/timing/8M_2X_hv_1Ya_h_4Y_vhvh/lib_lvf/dwc_ddrphy_vddqclamp_dq_ew_15M_2X_hv_1Ya_h_5Y_vhvhv_2Yy2Yx2R_ssg0p8v0c.lib \
	-liberty $P4_WS/depot/products/ddr54/project/d839-ddr54v2-tsmc7ff18/ckt/rel/dwc_ddrphy_vddqclamp_dq_ew/1.00a/macro/timing/8M_2X_hv_1Ya_h_4Y_vhvh/lib_lvf/dwc_ddrphy_vddqclamp_dq_ew_15M_2X_hv_1Ya_h_5Y_vhvhv_2Yy2Yx2R_ssg0p8v110c.lib \
	-liberty $P4_WS/depot/products/ddr54/project/d839-ddr54v2-tsmc7ff18/ckt/rel/dwc_ddrphy_vddqclamp_dq_ew/1.00a/macro/timing/8M_2X_hv_1Ya_h_4Y_vhvh/lib_lvf/dwc_ddrphy_vddqclamp_dq_ew_15M_2X_hv_1Ya_h_5Y_vhvhv_2Yy2Yx2R_tt0p75v25c.lib \
	-liberty $P4_WS/depot/products/ddr54/project/d839-ddr54v2-tsmc7ff18/ckt/rel/dwc_ddrphy_vddqclamp_dq_ew/1.00a/macro/timing/8M_2X_hv_1Ya_h_4Y_vhvh/lib_lvf/dwc_ddrphy_vddqclamp_dq_ew_15M_2X_hv_1Ya_h_5Y_vhvhv_2Yy2Yx2R_tt0p85v25c.lib \
	-liberty $P4_WS/depot/products/ddr54/project/d839-ddr54v2-tsmc7ff18/ckt/rel/dwc_ddrphy_vddqclamp_dq_ew/1.00a/macro/timing/8M_2X_hv_1Ya_h_4Y_vhvh/lib_pg_lvf/dwc_ddrphy_vddqclamp_dq_ew_15M_2X_hv_1Ya_h_5Y_vhvhv_2Yy2Yx2R_ffg0p825v0c_pg.lib \
	-liberty $P4_WS/depot/products/ddr54/project/d839-ddr54v2-tsmc7ff18/ckt/rel/dwc_ddrphy_vddqclamp_dq_ew/1.00a/macro/timing/8M_2X_hv_1Ya_h_4Y_vhvh/lib_pg_lvf/dwc_ddrphy_vddqclamp_dq_ew_15M_2X_hv_1Ya_h_5Y_vhvhv_2Yy2Yx2R_ffg0p825v110c_pg.lib \
	-liberty $P4_WS/depot/products/ddr54/project/d839-ddr54v2-tsmc7ff18/ckt/rel/dwc_ddrphy_vddqclamp_dq_ew/1.00a/macro/timing/8M_2X_hv_1Ya_h_4Y_vhvh/lib_pg_lvf/dwc_ddrphy_vddqclamp_dq_ew_15M_2X_hv_1Ya_h_5Y_vhvhv_2Yy2Yx2R_ffg0p935v0c_pg.lib \
	-liberty $P4_WS/depot/products/ddr54/project/d839-ddr54v2-tsmc7ff18/ckt/rel/dwc_ddrphy_vddqclamp_dq_ew/1.00a/macro/timing/8M_2X_hv_1Ya_h_4Y_vhvh/lib_pg_lvf/dwc_ddrphy_vddqclamp_dq_ew_15M_2X_hv_1Ya_h_5Y_vhvhv_2Yy2Yx2R_ffg0p935v110c_pg.lib \
	-liberty $P4_WS/depot/products/ddr54/project/d839-ddr54v2-tsmc7ff18/ckt/rel/dwc_ddrphy_vddqclamp_dq_ew/1.00a/macro/timing/8M_2X_hv_1Ya_h_4Y_vhvh/lib_pg_lvf/dwc_ddrphy_vddqclamp_dq_ew_15M_2X_hv_1Ya_h_5Y_vhvhv_2Yy2Yx2R_ssg0p675v0c_pg.lib \
	-liberty $P4_WS/depot/products/ddr54/project/d839-ddr54v2-tsmc7ff18/ckt/rel/dwc_ddrphy_vddqclamp_dq_ew/1.00a/macro/timing/8M_2X_hv_1Ya_h_4Y_vhvh/lib_pg_lvf/dwc_ddrphy_vddqclamp_dq_ew_15M_2X_hv_1Ya_h_5Y_vhvhv_2Yy2Yx2R_ssg0p675v110c_pg.lib \
	-liberty $P4_WS/depot/products/ddr54/project/d839-ddr54v2-tsmc7ff18/ckt/rel/dwc_ddrphy_vddqclamp_dq_ew/1.00a/macro/timing/8M_2X_hv_1Ya_h_4Y_vhvh/lib_pg_lvf/dwc_ddrphy_vddqclamp_dq_ew_15M_2X_hv_1Ya_h_5Y_vhvhv_2Yy2Yx2R_ssg0p8v0c_pg.lib \
	-liberty $P4_WS/depot/products/ddr54/project/d839-ddr54v2-tsmc7ff18/ckt/rel/dwc_ddrphy_vddqclamp_dq_ew/1.00a/macro/timing/8M_2X_hv_1Ya_h_4Y_vhvh/lib_pg_lvf/dwc_ddrphy_vddqclamp_dq_ew_15M_2X_hv_1Ya_h_5Y_vhvhv_2Yy2Yx2R_ssg0p8v110c_pg.lib \
	-liberty $P4_WS/depot/products/ddr54/project/d839-ddr54v2-tsmc7ff18/ckt/rel/dwc_ddrphy_vddqclamp_dq_ew/1.00a/macro/timing/8M_2X_hv_1Ya_h_4Y_vhvh/lib_pg_lvf/dwc_ddrphy_vddqclamp_dq_ew_15M_2X_hv_1Ya_h_5Y_vhvhv_2Yy2Yx2R_tt0p75v25c_pg.lib \
	-liberty $P4_WS/depot/products/ddr54/project/d839-ddr54v2-tsmc7ff18/ckt/rel/dwc_ddrphy_vddqclamp_dq_ew/1.00a/macro/timing/8M_2X_hv_1Ya_h_4Y_vhvh/lib_pg_lvf/dwc_ddrphy_vddqclamp_dq_ew_15M_2X_hv_1Ya_h_5Y_vhvhv_2Yy2Yx2R_tt0p85v25c_pg.lib 
    
# -I- Current time is Mon Jun 13 14:26:08 2022
