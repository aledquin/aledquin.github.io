#!/bin/tcsh -f

./bin/alphaPinCheck.pl \
	-log /u/ljames/p4_ws/depot/products/hbm3_v2/project/d763-hbm3-v2-tsmc3eff12/ckt/rel/dwc_hbmphy_clkio/1.00a/macro/dwc_hbmphy_clkio.pincheck \
	-nousage \
	-appendlog \
	-macro dwc_hbmphy_clkio \
	-tech tsmc3eff-12 \
	-lefObsLayers M0 M1 M2 M3 M4 M5 M6 M7 M8 M9 M10 OVERLAP \
	-lefPinLayers M0 M1 M2 M3 M4 M5 M6 M7 M8 M9 M10 OVERLAP \
	-PGlayers M10 \
	-since 2022-12-29 13:47:46 \
	-dateRef CDATE \
	-bracket square \
	-streamLayermap /remote/cad-rep/projects/cad/c269-tsmc3eff-1.2v/rel4.0.1/cad/15M_1Xa_h_1Xb_v_1Xc_h_1Xd_v_1Ya_h_1Yb_v_4Y_hvhv_2Yy2Z/stream/STD/stream.layermap \
	-verilog /u/ljames/p4_ws/depot/products/hbm3_v2/project/d763-hbm3-v2-tsmc3eff12/ckt/rel/dwc_hbmphy_clkio/1.00a/macro/behavior/dwc_hbmphy_clkio.v \
	-cdl /u/ljames/p4_ws/depot/products/hbm3_v2/project/d763-hbm3-v2-tsmc3eff12/ckt/rel/dwc_hbmphy_clkio/1.00a/macro/cosim/dwc_hbmphy_clkio.sp \
	-gds /u/ljames/p4_ws/depot/products/hbm3_v2/project/d763-hbm3-v2-tsmc3eff12/ckt/rel/dwc_hbmphy_clkio/1.00a/macro/gds/10M_1Xa_h_1Xb_v_1Xc_h_1Xd_v_1Ya_h_1Yb_v_3Y_hvh/dwc_hbmphy_clkio.gds.gz \
	-verilog /u/ljames/p4_ws/depot/products/hbm3_v2/project/d763-hbm3-v2-tsmc3eff12/ckt/rel/dwc_hbmphy_clkio/1.00a/macro/interface/dwc_hbmphy_clkio_interface.v \
	-lef /u/ljames/p4_ws/depot/products/hbm3_v2/project/d763-hbm3-v2-tsmc3eff12/ckt/rel/dwc_hbmphy_clkio/1.00a/macro/lef/10M_1Xa_h_1Xb_v_1Xc_h_1Xd_v_1Ya_h_1Yb_v_3Y_hvh/dwc_hbmphy_clkio.lef \
	-lef /u/ljames/p4_ws/depot/products/hbm3_v2/project/d763-hbm3-v2-tsmc3eff12/ckt/rel/dwc_hbmphy_clkio/1.00a/macro/lef/10M_1Xa_h_1Xb_v_1Xc_h_1Xd_v_1Ya_h_1Yb_v_3Y_hvh/dwc_hbmphy_clkio_merged.lef \
	-cdl /u/ljames/p4_ws/depot/products/hbm3_v2/project/d763-hbm3-v2-tsmc3eff12/ckt/rel/dwc_hbmphy_clkio/1.00a/macro/netlist/10M_1Xa_h_1Xb_v_1Xc_h_1Xd_v_1Ya_h_1Yb_v_3Y_hvh/dwc_hbmphy_clkio.cdl \
	-pinCSV /u/ljames/p4_ws/depot/products/hbm3_v2/project/d763-hbm3-v2-tsmc3eff12/ckt/rel/dwc_hbmphy_clkio/1.00a/macro/pininfo/dwc_hbmphy_clkio.csv \
	-liberty /u/ljames/p4_ws/depot/products/hbm3_v2/project/d763-hbm3-v2-tsmc3eff12/ckt/rel/dwc_hbmphy_clkio/1.00a/macro/timing/10M_1Xa_h_1Xb_v_1Xc_h_1Xd_v_1Ya_h_1Yb_v_3Y_hvh/lib_lvf/dwc_hbmphy_clkio_15M_1Xa_h_1Xb_v_1Xc_h_1Xd_v_1Ya_h_1Yb_v_4Y_hvhv_2Yy2Z_ffg0p825v0c.lib.gz \
	-liberty /u/ljames/p4_ws/depot/products/hbm3_v2/project/d763-hbm3-v2-tsmc3eff12/ckt/rel/dwc_hbmphy_clkio/1.00a/macro/timing/10M_1Xa_h_1Xb_v_1Xc_h_1Xd_v_1Ya_h_1Yb_v_3Y_hvh/lib_lvf/dwc_hbmphy_clkio_15M_1Xa_h_1Xb_v_1Xc_h_1Xd_v_1Ya_h_1Yb_v_4Y_hvhv_2Yy2Z_ffg0p825v125c.lib.gz \
	-liberty /u/ljames/p4_ws/depot/products/hbm3_v2/project/d763-hbm3-v2-tsmc3eff12/ckt/rel/dwc_hbmphy_clkio/1.00a/macro/timing/10M_1Xa_h_1Xb_v_1Xc_h_1Xd_v_1Ya_h_1Yb_v_3Y_hvh/lib_lvf/dwc_hbmphy_clkio_15M_1Xa_h_1Xb_v_1Xc_h_1Xd_v_1Ya_h_1Yb_v_4Y_hvhv_2Yy2Z_ffg0p825vn40c.lib.gz \
	-liberty /u/ljames/p4_ws/depot/products/hbm3_v2/project/d763-hbm3-v2-tsmc3eff12/ckt/rel/dwc_hbmphy_clkio/1.00a/macro/timing/10M_1Xa_h_1Xb_v_1Xc_h_1Xd_v_1Ya_h_1Yb_v_3Y_hvh/lib_lvf/dwc_hbmphy_clkio_15M_1Xa_h_1Xb_v_1Xc_h_1Xd_v_1Ya_h_1Yb_v_4Y_hvhv_2Yy2Z_ssg0p675v0c.lib.gz \
	-liberty /u/ljames/p4_ws/depot/products/hbm3_v2/project/d763-hbm3-v2-tsmc3eff12/ckt/rel/dwc_hbmphy_clkio/1.00a/macro/timing/10M_1Xa_h_1Xb_v_1Xc_h_1Xd_v_1Ya_h_1Yb_v_3Y_hvh/lib_lvf/dwc_hbmphy_clkio_15M_1Xa_h_1Xb_v_1Xc_h_1Xd_v_1Ya_h_1Yb_v_4Y_hvhv_2Yy2Z_ssg0p675v125c.lib.gz \
	-liberty /u/ljames/p4_ws/depot/products/hbm3_v2/project/d763-hbm3-v2-tsmc3eff12/ckt/rel/dwc_hbmphy_clkio/1.00a/macro/timing/10M_1Xa_h_1Xb_v_1Xc_h_1Xd_v_1Ya_h_1Yb_v_3Y_hvh/lib_lvf/dwc_hbmphy_clkio_15M_1Xa_h_1Xb_v_1Xc_h_1Xd_v_1Ya_h_1Yb_v_4Y_hvhv_2Yy2Z_ssg0p675vn40c.lib.gz \
	-liberty /u/ljames/p4_ws/depot/products/hbm3_v2/project/d763-hbm3-v2-tsmc3eff12/ckt/rel/dwc_hbmphy_clkio/1.00a/macro/timing/10M_1Xa_h_1Xb_v_1Xc_h_1Xd_v_1Ya_h_1Yb_v_3Y_hvh/lib_lvf/dwc_hbmphy_clkio_15M_1Xa_h_1Xb_v_1Xc_h_1Xd_v_1Ya_h_1Yb_v_4Y_hvhv_2Yy2Z_tt0p75v25c.lib.gz \
	-liberty /u/ljames/p4_ws/depot/products/hbm3_v2/project/d763-hbm3-v2-tsmc3eff12/ckt/rel/dwc_hbmphy_clkio/1.00a/macro/timing/10M_1Xa_h_1Xb_v_1Xc_h_1Xd_v_1Ya_h_1Yb_v_3Y_hvh/lib_pg_lvf/dwc_hbmphy_clkio_15M_1Xa_h_1Xb_v_1Xc_h_1Xd_v_1Ya_h_1Yb_v_4Y_hvhv_2Yy2Z_ffg0p825v0c_pg.lib.gz \
	-liberty /u/ljames/p4_ws/depot/products/hbm3_v2/project/d763-hbm3-v2-tsmc3eff12/ckt/rel/dwc_hbmphy_clkio/1.00a/macro/timing/10M_1Xa_h_1Xb_v_1Xc_h_1Xd_v_1Ya_h_1Yb_v_3Y_hvh/lib_pg_lvf/dwc_hbmphy_clkio_15M_1Xa_h_1Xb_v_1Xc_h_1Xd_v_1Ya_h_1Yb_v_4Y_hvhv_2Yy2Z_ffg0p825v125c_pg.lib.gz \
	-liberty /u/ljames/p4_ws/depot/products/hbm3_v2/project/d763-hbm3-v2-tsmc3eff12/ckt/rel/dwc_hbmphy_clkio/1.00a/macro/timing/10M_1Xa_h_1Xb_v_1Xc_h_1Xd_v_1Ya_h_1Yb_v_3Y_hvh/lib_pg_lvf/dwc_hbmphy_clkio_15M_1Xa_h_1Xb_v_1Xc_h_1Xd_v_1Ya_h_1Yb_v_4Y_hvhv_2Yy2Z_ffg0p825vn40c_pg.lib.gz \
	-liberty /u/ljames/p4_ws/depot/products/hbm3_v2/project/d763-hbm3-v2-tsmc3eff12/ckt/rel/dwc_hbmphy_clkio/1.00a/macro/timing/10M_1Xa_h_1Xb_v_1Xc_h_1Xd_v_1Ya_h_1Yb_v_3Y_hvh/lib_pg_lvf/dwc_hbmphy_clkio_15M_1Xa_h_1Xb_v_1Xc_h_1Xd_v_1Ya_h_1Yb_v_4Y_hvhv_2Yy2Z_ssg0p675v0c_pg.lib.gz \
	-liberty /u/ljames/p4_ws/depot/products/hbm3_v2/project/d763-hbm3-v2-tsmc3eff12/ckt/rel/dwc_hbmphy_clkio/1.00a/macro/timing/10M_1Xa_h_1Xb_v_1Xc_h_1Xd_v_1Ya_h_1Yb_v_3Y_hvh/lib_pg_lvf/dwc_hbmphy_clkio_15M_1Xa_h_1Xb_v_1Xc_h_1Xd_v_1Ya_h_1Yb_v_4Y_hvhv_2Yy2Z_ssg0p675v125c_pg.lib.gz \
	-liberty /u/ljames/p4_ws/depot/products/hbm3_v2/project/d763-hbm3-v2-tsmc3eff12/ckt/rel/dwc_hbmphy_clkio/1.00a/macro/timing/10M_1Xa_h_1Xb_v_1Xc_h_1Xd_v_1Ya_h_1Yb_v_3Y_hvh/lib_pg_lvf/dwc_hbmphy_clkio_15M_1Xa_h_1Xb_v_1Xc_h_1Xd_v_1Ya_h_1Yb_v_4Y_hvhv_2Yy2Z_ssg0p675vn40c_pg.lib.gz \
	-liberty /u/ljames/p4_ws/depot/products/hbm3_v2/project/d763-hbm3-v2-tsmc3eff12/ckt/rel/dwc_hbmphy_clkio/1.00a/macro/timing/10M_1Xa_h_1Xb_v_1Xc_h_1Xd_v_1Ya_h_1Yb_v_3Y_hvh/lib_pg_lvf/dwc_hbmphy_clkio_15M_1Xa_h_1Xb_v_1Xc_h_1Xd_v_1Ya_h_1Yb_v_4Y_hvhv_2Yy2Z_tt0p75v25c_pg.lib.gz 

