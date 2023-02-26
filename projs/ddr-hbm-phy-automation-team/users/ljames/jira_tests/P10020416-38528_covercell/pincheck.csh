#!/bin/tcsh -f

./bin/alphaPinCheck.pl \
    -verbosity 1 \
    -debug 0 \
	-log dwc_lpddr5xphycover_acx2_top_ew.pincheck \
	-nousage \
	-appendlog \
	-macro dwc_lpddr5xphycover_acx2_top_ew \
	-tech tsmc3eff-12 \
	-lefObsLayers M10 M11 M12 M13 M14 M15 MTOP MTOP-1 \
	-lefPinLayers M10 M11 M12 M13 M14 M15 MTOP MTOP-1 \
	-PGlayers M10 M14 M15 MTOP MTOP-1 \
	-since 2022-12-30 09:51:04 \
	-dateRef CDATE \
	-bracket square \
	-streamLayermap /remote/cad-rep/projects/cad/c269-tsmc3eff-1.2v/rel4.0.1/cad/15M_1Xa_h_1Xb_v_1Xc_h_1Xd_v_1Ya_h_1Yb_v_4Y_hvhv_2Yy2Z_SHDMIM/stream/STD/stream.layermap \
	-gds /u/ljames/p4_ws/depot/products/lpddr5x_ddr5_phy/lp5x/project/d931-lpddr5x-tsmc3eff-12/ckt/rel/dwc_lpddr5xphycover_acx2_top_ew/2.00a_pre3/macro/gds/15M_1Xa_h_1Xb_v_1Xc_h_1Xd_v_1Ya_h_1Yb_v_4Y_hvhv_2Yy2Z_SHDMIM/dwc_lpddr5xphycover_acx2_top_ew.gds.gz \
	-lef /u/ljames/p4_ws/depot/products/lpddr5x_ddr5_phy/lp5x/project/d931-lpddr5x-tsmc3eff-12/ckt/rel/dwc_lpddr5xphycover_acx2_top_ew/2.00a_pre3/macro/lef/15M_1Xa_h_1Xb_v_1Xc_h_1Xd_v_1Ya_h_1Yb_v_4Y_hvhv_2Yy2Z_SHDMIM/dwc_lpddr5xphycover_acx2_top_ew.lef \
	-lef /u/ljames/p4_ws/depot/products/lpddr5x_ddr5_phy/lp5x/project/d931-lpddr5x-tsmc3eff-12/ckt/rel/dwc_lpddr5xphycover_acx2_top_ew/2.00a_pre3/macro/lef/15M_1Xa_h_1Xb_v_1Xc_h_1Xd_v_1Ya_h_1Yb_v_4Y_hvhv_2Yy2Z_SHDMIM/dwc_lpddr5xphycover_acx2_top_ew_merged.lef \
	-cdl /u/ljames/p4_ws/depot/products/lpddr5x_ddr5_phy/lp5x/project/d931-lpddr5x-tsmc3eff-12/ckt/rel/dwc_lpddr5xphycover_acx2_top_ew/2.00a_pre3/macro/netlist/15M_1Xa_h_1Xb_v_1Xc_h_1Xd_v_1Ya_h_1Yb_v_4Y_hvhv_2Yy2Z_SHDMIM/dwc_lpddr5xphycover_acx2_top_ew.cdl \
	-pinCSV /u/ljames/p4_ws/depot/products/lpddr5x_ddr5_phy/lp5x/project/d931-lpddr5x-tsmc3eff-12/ckt/rel/dwc_lpddr5xphycover_acx2_top_ew/2.00a_pre3/macro/pininfo/dwc_lpddr5xphycover_acx2_top_ew.csv
