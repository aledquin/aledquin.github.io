## list of settings for present release
set rel "1.00a"
set vcrel "1.00a"
set ferel "fe_weekly"
set layout_tag "D910 Final Release"
set p4_release_root "products/lpddr5x_ddr5_phy/ddr5/project/d910-ddr5-tsmc5ff-12 products/lpddr5x_ddr5_phy/lp5x/project/d930-lpddr5x-tsmc5ff12"
set releaseBranch "rel1.00_cktpcs_1.00a_rel_"
set process "tsmc5ff-12"
set metal_stack "15M_1X_h_1Xb_v_1Xe_h_1Ya_v_1Yb_h_5Y_vhvhv_2Yy2Z"
#set metal_stack_ip "15M_1X_h_1Xb_v_1Xe_h_1Ya_v_1Yb_h_5Y_vhvhv_2Yy2Z"
set metal_stack_ip "10M_1X_h_1Xb_v_1Xe_h_1Ya_v_1Yb_h_4Y_vhvh"
set metal_stack_cover "15M_1X_h_1Xb_v_1Xe_h_1Ya_v_1Yb_h_5Y_vhvhv_2Yy2Z"
## legal pin layers
set layers "M0 M1 M2 M3 M4 M5 M6 M7 M8 M9 M10 OVERLAP"
## legal supply pin layers
set supply_pins "M10"
set supply_pins_override(dwc_ddr5phy_lcdl) "M4"
set supply_pins_override(dwc_ddr5phy_techrevision) "M5"
set supply_pins_override(dwc_ddr5phy_tcoil_ew) "M14 M15 M16 MTOP MTOP-1"
set supply_pins_override(dwc_ddr5phy_zcalio_ew) "M10 M12"
set supply_pins_override(dwc_ddr5phy_txrxac_ew) "M10 M12"
set supply_pins_override(dwc_ddr5phy_txrxdq_ew) "M10 M12"
set supply_pins_override(dwc_ddr5phy_txrxdqs_ew) "M10 M12"
set supply_pins_override(dwc_ddr5phy_por_ew) "M6 M10"
set supply_pins_override(dwc_ddr5phycover_acx2_top_ew)      "M10 M14 M15 M16 MTOP MTOP-1"
set supply_pins_override(dwc_ddr5phycover_ckx2_top_ew)      "M10 M14 M15 M16 MTOP MTOP-1"
set supply_pins_override(dwc_ddr5phycover_cmosx2_top_ew)    "M10 M14 M15 M16 MTOP MTOP-1"
set supply_pins_override(dwc_ddr5phycover_dx4_top_ew)       "M10 M14 M15 M16 MTOP MTOP-1"
set supply_pins_override(dwc_ddr5phycover_master_top_ew)    "M10 M14 M15 M16 MTOP MTOP-1"
set supply_pins_override(dwc_ddr5phycover_zcal_top_ew)      "M10 M14 M15 M16 MTOP MTOP-1"
set supply_pins_override(dwc_ddr5phy_utility_blocks)        "M10 M14 M15 M16 MTOP MTOP-1 AP"
set supply_pins_override(dwc_ddr5phydx4_tcoil_ap2c4d_ew)    "M10 M14 M15 M16 MTOP MTOP-1 AP"

set layers_override(dwc_ddr5phy_utility_blocks)     "M0 M1 M2 M3 M4 M5 M6 M7 M8 M9 M10 M11 M12 M13 M14 M15 M16 MTOP MTOP-1 AP"
set layers_override(dwc_ddr5phydx4_tcoil_ap2c4d_ew) "M0 M1 M2 M3 M4 M5 M6 M7 M8 M9 M10 M11 M12 M13 M14 M15 M16 MTOP MTOP-1 AP"
set layers_override(dwc_ddr5phycover_acx2_top_ew)   "M10 M11 M12 M13 M14 M15 M16 MTOP MTOP-1"
set layers_override(dwc_ddr5phycover_ckx2_top_ew)   "M10 M11 M12 M13 M14 M15 M16 MTOP MTOP-1"
set layers_override(dwc_ddr5phycover_cmosx2_top_ew) "M10 M11 M12 M13 M14 M15 M16 MTOP MTOP-1"
set layers_override(dwc_ddr5phycover_dx4_top_ew)    "M10 M11 M12 M13 M14 M15 M16 MTOP MTOP-1"
set layers_override(dwc_ddr5phycover_master_top)    "M10 M11 M12 M13 M14 M15 M16 MTOP MTOP-1"
set layers_override(dwc_ddr5phycover_zcal_top_ew)   "M10 M11 M12 M13 M14 M15 M16 MTOP MTOP-1"
set layers_override(dwc_ddr5phy_tcoil_ew)           "M14 M15 M16 MTOP MTOP-1"
## reference GDS files for DI
#set reference_gds(dwc_ddrphy_txrxac_ew) {dwc_ddrphy_txrxac_ew_IntLoadFill.gds.gz dwc_ddrphy_txrxac_ew_InternalLoad.gds.gz dwc_ddrphy_txrxac_ew_LUPblock.gds.gz}
#set reference_gds(dwc_ddrphy_txrxdqs_ew) {dwc_ddrphydbyte_lcdlroutes_ew.gds.gz}
## days since release files were created, for pin check/timing collateral validation
set reference_date_time "21 days ago"
## macros to release ctl
set releaseCtlMacro {dwc_ddr5phy_lcdl dwc_ddr5phy_lstx_acx2_ew dwc_ddr5phy_lstx_dx4_ew dwc_ddr5phy_lstx_zcal_ew dwc_ddr5phy_pclk_master dwc_ddr5phy_pclk_rxdca dwc_ddr5phy_rxreplica_ew dwc_ddr5phy_txrxac_ew dwc_ddr5phy_txrxdq_ew dwc_ddr5phy_txrxdqs_ew dwc_ddr5phy_vregdac_ew}
## list of timing releases (other than nldm)
set timing_libs {lvf}
## release GDS/CDL, default 'calibre'
##   allows using 'icv' GDS/CDL files for release, **only** applies to TSMC N7 where Calibre is waived
##   allows using 'HIPRE' GDS/CDL files from GenHiprePkg
set release_gds_cdl "HIPRE"
#set release_gds_cdl "icv"
## release GDS of shim macros, default 'drcint'
#set release_gds_shim "drcint"
## version for LEF comparison
set lef_diff_rel "1.00a_pre3"
## cells to prune from CDL
set cdl_prune_cells "cvcp* cvpp* vflag* vsync"
## macros that are PHYV only and can have autogen Verilog/LIB files
set releasePhyvMacro {dwc_ddr5phy_vaaclamp_ew dwc_ddr5phy_vddqclamp_ew dwc_ddr5phy_decapvaa_tile dwc_ddr5phy_decapvddhd_ew dwc_ddr5phy_decapvddhd_3p5x_ew dwc_ddr5phy_decapvddhd_mon_ew dwc_ddr5phy_decapvddq_mon_ew}
## macros that are only shims, only LEF/GDS
set releaseShimMacro {dwc_ddr5phycmosx2_top_ew_shim}
## macros to ignore for CKT release to DI
## macros that are TC only
set releaseTCMacro {dwc_lpddr5xphy_hbm_ew dwc_ddr5phy_decapvddhd_3p5x_ew dwc_ddr5phydx4_tcoil_ap2c4d_ew dwc_ddr5phy_decapvddq_mon_ew dwc_ddr5phy_decapvddhd_mon_ew dwc_ddr5phy_decapvddhd_ew dwc_lpddr5xphy_rxdqs_tc_ew dwc_lpddr5xphy_txrxcs_tc_ew dwc_lpddr5xphy_hbm_ew dwc_lpddr5xphy_vddqclamp_x2_ew}
## name of UTILITY library macro for CKT release to customer, defaults to dwc_ddrphy_utility_cells
set utility_name {dwc_ddr5phy_utility_cells dwc_ddr5phy_utility_blocks}
set repeater_name {dwc_ddr5phy_repeater_cells}
## contents of UTILITY library macros for CKT release to customer
set releaseMacro{dwc_ddr5phy_utility_cells} {dwc_ddr5phy_decapvddq_ew dwc_ddr5phy_decapvddq_ns dwc_ddr5phy_decapvddq_ld_ew dwc_ddr5phy_decapvddq_ld_ns dwc_ddr5phy_vddqclamp_ew}
set releaseMacro{dwc_ddr5phy_utility_blocks} {dwc_ddr5phy_pclk_routing_ac_ew dwc_ddr5phy_pclk_routing_dx_ew dwc_ddr5phy_pclk_routing_decap_ew dwc_ddr5phy_decapvddq_ac_ew dwc_ddr5phy_decapvddq_master_ew dwc_ddr5phy_decapvddq_dx4_ew dwc_ddr5phy_decapvddq_zcal_ew dwc_ddr5phy_decapvddq_ld_ac_ew dwc_ddr5phy_decapvddq_ld_master_ew dwc_ddr5phy_decapvddq_ld_dx4_ew dwc_ddr5phy_decapvddq_ld_zcal_ew dwc_ddr5phy_decapvsh_ac_ew dwc_ddr5phy_decapvsh_dx4_ew dwc_ddr5phy_decapvsh_zcal_ew dwc_ddr5phy_decapvsh_ld_ac_ew dwc_ddr5phy_decapvsh_ld_dx4_ew dwc_ddr5phy_decapvsh_ld_zcal_ew dwc_ddr5phydx4_tcoil_ew dwc_ddr5phydx4_notcoil_ew}
set releaseMacro{dwc_ddr5phy_repeater_cells} {dwc_ddr5phy_pclk_rptx1}
# releasing floorplans
set releaseDefMacro {pro_hard_macro/dwc_ddr5phymaster_ew_inst pro_hard_macro/dwc_ddr5phyzcal_ew_inst pro_hard_macro/dwc_ddr5phydx4_ew_inst pro_hard_macro/dwc_ddr5phyacx2_ew_inst pro_hard_macro/dwc_ddr5phyckx2_ew_inst pro_hard_macro/dwc_ddr5phycmosx2_ew_inst pro_hard_macro/dwc_ddr5phydqx1_ew_inst pro_hard_macro/dwc_ddr5phydqsx1_ew_inst}
## layers to tag in UTILITY library macro for CKT release to customer
##   Note -tsmc read from 'process' variable, so not necessary for TSMC processes unless needing extra layers
#set utility_tag_layers "63:63 60:63"
## email list for CKT release to DI
set releaseMailDist "ddr_di@synopsys.com,sg-ddr-ckt-release@synopsys.com,vthareja,hdavid,aparik,elgaid,mennatul,eltokhi,guttman,jfisher,vilas,baanu,rinshar,annmary,rarunac,dpatil,deepakgs,chetana,pmorris"
## email list for CKT release of HSPICE, IBIS, and UTILITY release
set releasePmMailDist "vthareja,hdavid,guttman,jfisher,vilas,sheraida,plagiann,davies,baanu,rarunac,dpatil"
set releaseTCMailDist "vthareja,hdavid,guttman,jfisher,vilas,sheraida,plagiann,davies,finn"
set calibre_verifs "true"