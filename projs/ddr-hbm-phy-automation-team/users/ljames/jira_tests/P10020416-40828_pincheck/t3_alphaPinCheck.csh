#!/bin/tcsh -f
# This also should complain; but doesn't according to Sanjala
# It should register the GLOBAL pin from the .lef file  (VDDQ)

set exedir=/u/ljames/GitLab/ddr-hbm-phy-automation-team/ddr-ckt-rel/dev/main/bin

${exedir}/alphaPinCheck.pl \
    -verbosity 2 \
    -debug 1 \
    -macro dwc_lpddr5xphy_txrxdq_ew \
    -lef /u/ljames/p4_nightly_runs/QA_test_plan/QA_testbenches/alphaPinCheck/alphaPinCheck_002/QA_dwc_lpddr5xphy_txrxdq_ew_lpddr5x/lef/dwc_lpddr5xphy_txrxdq_ew_merged.lef \
    -liberty /u/ljames/p4_nightly_runs/QA_test_plan/QA_testbenches/alphaPinCheck/alphaPinCheck_002/QA_dwc_lpddr5xphy_txrxdq_ew_lpddr5x/lib_pg/dwc_lpddr5xphy_txrxdq_ew_15M_1X_h_1Xb_v_1Xe_h_1Ya_v_1Yb_h_5Y_vhvhv_2Yy2Z_ffgnp0p715v0c_pg.lib \
    -libertynopg /u/ljames/p4_nightly_runs/QA_test_plan/QA_testbenches/alphaPinCheck/alphaPinCheck_002/QA_dwc_lpddr5xphy_txrxdq_ew_lpddr5x/lib/dwc_lpddr5xphy_txrxdq_ew_15M_1X_h_1Xb_v_1Xe_h_1Ya_v_1Yb_h_5Y_vhvhv_2Yy2Z_ffgnp0p715v0c.lib

grep 'missing in' alphaPinCheck.pl.log

