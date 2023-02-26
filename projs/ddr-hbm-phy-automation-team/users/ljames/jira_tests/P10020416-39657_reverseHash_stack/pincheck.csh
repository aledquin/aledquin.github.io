#!/bin/tcsh -f 

/remote/us01home50/ljames/GitLab/ddr-hbm-phy-automation-team/ddr-ckt-rel/dev/main/bin/alphaPinCheck.pl \
       -verbosity 2  \
       -debug 0 \
       -log ljames_dwc_ddrphy_por.pincheck  \
       -nousage -appendlog -macro dwc_ddrphy_por -tech  umc28hpcp-18  \
       -lefObsLayers 'ME1 ME2 ME3 ME4 ME5 ME6 OVERLAP'  \
       -lefPinLayers 'ME1 ME2 ME3 ME4 ME5 ME6 OVERLAP' -PGlayers 'ME6 ME4' -since '2022-12-30 15:26:25' -dateRef CDATE -bracket square  \
      -streamLayermap /remote/cad-rep/projects/cad/c514-umc28hpcp-1.8v/rel2.7.0/cad/1P10M2T0F2A0C_28kRDL/stream/STD/stream.layermap    \
      -lef /u/$USER/p4_ws/depot/products/ddr43_lpddr4_v2/project/d547-lpddr4mv2-umc28hpcp18/ckt/rel/dwc_ddrphy_por/1.50a/macro/lef/1P6M0T0D0F0A0C/dwc_ddrphy_por.lef   \
      -lef /u/$USER/p4_ws/depot/products/ddr43_lpddr4_v2/project/d547-lpddr4mv2-umc28hpcp18/ckt/rel/dwc_ddrphy_por/1.50a/macro/lef/1P6M0T0D0F0A0C/dwc_ddrphy_por_merged.lef   \
      -pinCSV /u/$USER/p4_ws/depot/products/ddr43_lpddr4_v2/project/d547-lpddr4mv2-umc28hpcp18/ckt/rel/dwc_ddrphy_por/1.50a/macro/pininfo/dwc_ddrphy_por.csv   \
  -liberty /u/$USER/p4_ws/depot/products/ddr43_lpddr4_v2/project/d547-lpddr4mv2-umc28hpcp18/ckt/rel/dwc_ddrphy_por/1.50a/macro/timing/1P6M0T0D0F0A0C/lib/dwc_ddrphy_por_1P10M2T0F2A0C_28kRDL_ffg0p99v0c.lib.gz   \
  -liberty /u/$USER/p4_ws/depot/products/ddr43_lpddr4_v2/project/d547-lpddr4mv2-umc28hpcp18/ckt/rel/dwc_ddrphy_por/1.50a/macro/timing/1P6M0T0D0F0A0C/lib/dwc_ddrphy_por_1P10M2T0F2A0C_28kRDL_ffg0p99v125c.lib.gz   \
  -liberty /u/$USER/p4_ws/depot/products/ddr43_lpddr4_v2/project/d547-lpddr4mv2-umc28hpcp18/ckt/rel/dwc_ddrphy_por/1.50a/macro/timing/1P6M0T0D0F0A0C/lib/dwc_ddrphy_por_1P10M2T0F2A0C_28kRDL_ffg0p99vn40c.lib.gz   \
  -liberty /u/$USER/p4_ws/depot/products/ddr43_lpddr4_v2/project/d547-lpddr4mv2-umc28hpcp18/ckt/rel/dwc_ddrphy_por/1.50a/macro/timing/1P6M0T0D0F0A0C/lib/dwc_ddrphy_por_1P10M2T0F2A0C_28kRDL_ffg1p05v0c.lib.gz   \
  -liberty /u/$USER/p4_ws/depot/products/ddr43_lpddr4_v2/project/d547-lpddr4mv2-umc28hpcp18/ckt/rel/dwc_ddrphy_por/1.50a/macro/timing/1P6M0T0D0F0A0C/lib/dwc_ddrphy_por_1P10M2T0F2A0C_28kRDL_ffg1p05v125c.lib.gz   \
  -liberty /u/$USER/p4_ws/depot/products/ddr43_lpddr4_v2/project/d547-lpddr4mv2-umc28hpcp18/ckt/rel/dwc_ddrphy_por/1.50a/macro/timing/1P6M0T0D0F0A0C/lib/dwc_ddrphy_por_1P10M2T0F2A0C_28kRDL_ffg1p05vn40c.lib.gz   \
  -liberty /u/$USER/p4_ws/depot/products/ddr43_lpddr4_v2/project/d547-lpddr4mv2-umc28hpcp18/ckt/rel/dwc_ddrphy_por/1.50a/macro/timing/1P6M0T0D0F0A0C/lib/dwc_ddrphy_por_1P10M2T0F2A0C_28kRDL_ssg0p81v0c.lib.gz   \
  -liberty /u/$USER/p4_ws/depot/products/ddr43_lpddr4_v2/project/d547-lpddr4mv2-umc28hpcp18/ckt/rel/dwc_ddrphy_por/1.50a/macro/timing/1P6M0T0D0F0A0C/lib/dwc_ddrphy_por_1P10M2T0F2A0C_28kRDL_ssg0p81v125c.lib.gz   \
  -liberty /u/$USER/p4_ws/depot/products/ddr43_lpddr4_v2/project/d547-lpddr4mv2-umc28hpcp18/ckt/rel/dwc_ddrphy_por/1.50a/macro/timing/1P6M0T0D0F0A0C/lib/dwc_ddrphy_por_1P10M2T0F2A0C_28kRDL_ssg0p81vn40c.lib.gz   \
  -liberty /u/$USER/p4_ws/depot/products/ddr43_lpddr4_v2/project/d547-lpddr4mv2-umc28hpcp18/ckt/rel/dwc_ddrphy_por/1.50a/macro/timing/1P6M0T0D0F0A0C/lib/dwc_ddrphy_por_1P10M2T0F2A0C_28kRDL_ssg0p9v0c.lib.gz   \
  -liberty /u/$USER/p4_ws/depot/products/ddr43_lpddr4_v2/project/d547-lpddr4mv2-umc28hpcp18/ckt/rel/dwc_ddrphy_por/1.50a/macro/timing/1P6M0T0D0F0A0C/lib/dwc_ddrphy_por_1P10M2T0F2A0C_28kRDL_ssg0p9v125c.lib.gz   \
  -liberty /u/$USER/p4_ws/depot/products/ddr43_lpddr4_v2/project/d547-lpddr4mv2-umc28hpcp18/ckt/rel/dwc_ddrphy_por/1.50a/macro/timing/1P6M0T0D0F0A0C/lib/dwc_ddrphy_por_1P10M2T0F2A0C_28kRDL_ssg0p9vn40c.lib.gz   \
  -liberty /u/$USER/p4_ws/depot/products/ddr43_lpddr4_v2/project/d547-lpddr4mv2-umc28hpcp18/ckt/rel/dwc_ddrphy_por/1.50a/macro/timing/1P6M0T0D0F0A0C/lib/dwc_ddrphy_por_1P10M2T0F2A0C_28kRDL_tt0p9v25c.lib.gz   \
  -liberty /u/$USER/p4_ws/depot/products/ddr43_lpddr4_v2/project/d547-lpddr4mv2-umc28hpcp18/ckt/rel/dwc_ddrphy_por/1.50a/macro/timing/1P6M0T0D0F0A0C/lib/dwc_ddrphy_por_1P10M2T0F2A0C_28kRDL_tt1p0v25c.lib.gz   \
  -liberty /u/$USER/p4_ws/depot/products/ddr43_lpddr4_v2/project/d547-lpddr4mv2-umc28hpcp18/ckt/rel/dwc_ddrphy_por/1.50a/macro/timing/1P6M0T0D0F0A0C/lib_pg/dwc_ddrphy_por_1P10M2T0F2A0C_28kRDL_ffg0p99v0c_pg.lib.gz   \
  -liberty /u/$USER/p4_ws/depot/products/ddr43_lpddr4_v2/project/d547-lpddr4mv2-umc28hpcp18/ckt/rel/dwc_ddrphy_por/1.50a/macro/timing/1P6M0T0D0F0A0C/lib_pg/dwc_ddrphy_por_1P10M2T0F2A0C_28kRDL_ffg0p99v125c_pg.lib.gz   \
  -liberty /u/$USER/p4_ws/depot/products/ddr43_lpddr4_v2/project/d547-lpddr4mv2-umc28hpcp18/ckt/rel/dwc_ddrphy_por/1.50a/macro/timing/1P6M0T0D0F0A0C/lib_pg/dwc_ddrphy_por_1P10M2T0F2A0C_28kRDL_ffg0p99vn40c_pg.lib.gz   \
  -liberty /u/$USER/p4_ws/depot/products/ddr43_lpddr4_v2/project/d547-lpddr4mv2-umc28hpcp18/ckt/rel/dwc_ddrphy_por/1.50a/macro/timing/1P6M0T0D0F0A0C/lib_pg/dwc_ddrphy_por_1P10M2T0F2A0C_28kRDL_ffg1p05v0c_pg.lib.gz   \
  -liberty /u/$USER/p4_ws/depot/products/ddr43_lpddr4_v2/project/d547-lpddr4mv2-umc28hpcp18/ckt/rel/dwc_ddrphy_por/1.50a/macro/timing/1P6M0T0D0F0A0C/lib_pg/dwc_ddrphy_por_1P10M2T0F2A0C_28kRDL_ffg1p05v125c_pg.lib.gz   \
  -liberty /u/$USER/p4_ws/depot/products/ddr43_lpddr4_v2/project/d547-lpddr4mv2-umc28hpcp18/ckt/rel/dwc_ddrphy_por/1.50a/macro/timing/1P6M0T0D0F0A0C/lib_pg/dwc_ddrphy_por_1P10M2T0F2A0C_28kRDL_ffg1p05vn40c_pg.lib.gz   \
  -liberty /u/$USER/p4_ws/depot/products/ddr43_lpddr4_v2/project/d547-lpddr4mv2-umc28hpcp18/ckt/rel/dwc_ddrphy_por/1.50a/macro/timing/1P6M0T0D0F0A0C/lib_pg/dwc_ddrphy_por_1P10M2T0F2A0C_28kRDL_ssg0p81v0c_pg.lib.gz   \
  -liberty /u/$USER/p4_ws/depot/products/ddr43_lpddr4_v2/project/d547-lpddr4mv2-umc28hpcp18/ckt/rel/dwc_ddrphy_por/1.50a/macro/timing/1P6M0T0D0F0A0C/lib_pg/dwc_ddrphy_por_1P10M2T0F2A0C_28kRDL_ssg0p81v125c_pg.lib.gz   \
  -liberty /u/$USER/p4_ws/depot/products/ddr43_lpddr4_v2/project/d547-lpddr4mv2-umc28hpcp18/ckt/rel/dwc_ddrphy_por/1.50a/macro/timing/1P6M0T0D0F0A0C/lib_pg/dwc_ddrphy_por_1P10M2T0F2A0C_28kRDL_ssg0p81vn40c_pg.lib.gz   \
  -liberty /u/$USER/p4_ws/depot/products/ddr43_lpddr4_v2/project/d547-lpddr4mv2-umc28hpcp18/ckt/rel/dwc_ddrphy_por/1.50a/macro/timing/1P6M0T0D0F0A0C/lib_pg/dwc_ddrphy_por_1P10M2T0F2A0C_28kRDL_ssg0p9v0c_pg.lib.gz   \
  -liberty /u/$USER/p4_ws/depot/products/ddr43_lpddr4_v2/project/d547-lpddr4mv2-umc28hpcp18/ckt/rel/dwc_ddrphy_por/1.50a/macro/timing/1P6M0T0D0F0A0C/lib_pg/dwc_ddrphy_por_1P10M2T0F2A0C_28kRDL_ssg0p9v125c_pg.lib.gz   \
  -liberty /u/$USER/p4_ws/depot/products/ddr43_lpddr4_v2/project/d547-lpddr4mv2-umc28hpcp18/ckt/rel/dwc_ddrphy_por/1.50a/macro/timing/1P6M0T0D0F0A0C/lib_pg/dwc_ddrphy_por_1P10M2T0F2A0C_28kRDL_ssg0p9vn40c_pg.lib.gz   \
  -liberty /u/$USER/p4_ws/depot/products/ddr43_lpddr4_v2/project/d547-lpddr4mv2-umc28hpcp18/ckt/rel/dwc_ddrphy_por/1.50a/macro/timing/1P6M0T0D0F0A0C/lib_pg/dwc_ddrphy_por_1P10M2T0F2A0C_28kRDL_tt0p9v25c_pg.lib.gz   \
  -liberty /u/$USER/p4_ws/depot/products/ddr43_lpddr4_v2/project/d547-lpddr4mv2-umc28hpcp18/ckt/rel/dwc_ddrphy_por/1.50a/macro/timing/1P6M0T0D0F0A0C/lib_pg/dwc_ddrphy_por_1P10M2T0F2A0C_28kRDL_tt1p0v25c_pg.lib.gz 
