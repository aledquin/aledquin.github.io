set cdl_prune_cells "cvcp* cvpp* vflag* *MOMcap_Cp *MOMcap_Cc *MOMcap_pu1 *MOMcap_pux"
set ferel "1.00a" 
set layers "M0 M1 M2 M3 M4 D4 D5 D6 D7 D8 OVERLAP"
set layers_override(dwc_ddrphy_utility_blocks) "B1 B2 G1 G2 H1 H2 H3 H4 OI1 M17"
set layers_override(dwc_ddrphycover_dwc_ddrphyacx4_top_ns) "B1 B2 G1 G2 H1 H2 H3 H4 OI1 M17"
set layers_override(dwc_ddrphycover_dwc_ddrphydbyte_top_ns) "B1 B2 G1 G2 H1 H2 H3 H4 OI1 M17"
set layers_override(dwc_ddrphycover_dwc_ddrphymaster_top) "B1 B2 G1 G2 H1 H2 H3 H4 OI1 M17"
set layout_tag "Final Release"
set lef_diff_rel "1.00a"
set metal_stack "18M_4Mx_4Dx_4Hx_2Bx_2Gx_2UTM_ILB"
set metal_stack_cover "18M_4Mx_4Dx_4Hx_2Bx_2Gx_2UTM_ILB"
set metal_stack_ip "8M_4Mx_4Dx"
set p4_release_root "products/ddr54/project/d822-ddr54-ss7hpp-18"
set process "ss7hpp-18"
set reference_date_time "30 days ago"
set reference_gds(dwc_ddrphy_memreset_ens) {dwc_ddrphy_memreset_ns_analogTestVflag.gds.gz}
set reference_gds(dwc_ddrphy_txrxac_ns) {dwc_ddrphy_txrxac_ns_IntLoadFill.gds.gz dwc_ddrphy_txrxac_ns_InternalLoad.gds.gz}
set reference_gds(dwc_ddrphy_txrxdqs_ns) {dwc_ddrphydbyte_lcdlroutes_ns.gds.gz}
set rel "1.00a"
set releaseBranch "rel1.00_cktpcs_1.00a_rel_"
set releaseCtlMacro {dwc_ddrphy_lcdl dwc_ddrphy_txrxdq_ns dwc_ddrphy_txrxdqs_ns}
set releaseDefMacro {dwc_ddrphy_testbenches/dwc_ddrphyacx4_analog_inst_ns dwc_ddrphy_testbenches/dwc_ddrphydbyte_analog_inst_ns dwc_ddrphy_testbenches/dwc_ddrphymaster_analog_inst}
set releaseIgnoreMacro {dwc_ddrphy_rxac_ew dwc_ddrphy_rxdq_ew dwc_ddrphy_rxdqs_ew dwc_ddrphy_txfe_ew dwc_ddrphy_txfedqs_ew dwc_ddrphy_txbe_ew dwc_ddrphy_bdl dwc_ddrphy_dqsenreplica_ew}
set releaseMacro{dwc_ddrphy_utility_blocks} {dwc_ddrphy_decapvddq_dbyte_ns dwc_ddrphy_decapvddq_acx4_ns dwc_ddrphy_decapvddq_master}
set releaseMacro{dwc_ddrphy_utility_cells} {dwc_ddrphy_decapvddq_ew dwc_ddrphy_decapvddq_ns dwc_ddrphy_decapvddq_ld_ew dwc_ddrphy_decapvddq_ld_ns dwc_ddrphy_vddqclamp_ns} 
set releaseMailDist "sg-ddr-ckt-release@synopsys.com,ddr_di@synopsys.com,guttman,jfisher,dube,samy,aparik,eltokhi,hoda,saeidh,hghonie"
set releasePhyvMacro {dwc_ddrphy_vddqclamp_ns dwc_ddrphy_vaaclamp dwc_ddrphy_decapvaa_tile dwc_ddrphy_decapvdd_tile}
set releasePmMailDist "sg-ddr-ckt-release@synopsys.com,guttman,jfisher,dube,samy,hoda,saeidh,hghonie"
set release_gds_cdl "icv"
set repeater_name {dwc_ddrphy_clktree_repeater}
set supply_pins "D8"
set supply_pins_override(dwc_ddrphy_bdl) "M4"
set supply_pins_override(dwc_ddrphy_lcdl) "M4"
set supply_pins_override(dwc_ddrphy_techrevision) "M4"
set supply_pins_override(dwc_ddrphy_utility_blocks) "H1 H2 H3 H4 B1 B2 G1 G2 OI1 OI2 ILB MTOP MTOP-1"
set supply_pins_override(dwc_ddrphycover_dwc_ddrphyacx4_top_ns) "D8 G2 OI1 M17"
set supply_pins_override(dwc_ddrphycover_dwc_ddrphydbyte_top_ns) "D8 G2 OI1 M17"
set supply_pins_override(dwc_ddrphycover_dwc_ddrphymaster_top) "D8 G2 OI1 M17"
set timing_libs {lvf}
set utility_name {dwc_ddrphy_utility_cells dwc_ddrphy_utility_blocks}
set vcrel "1.00a"