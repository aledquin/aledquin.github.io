#!/bin/tcsh -f
set p4_root        = `readlink -f /u/$USER/p4_ws`
set git_root       = `readlink -f /u/$USER/GitLab/ddr-hbm-phy-automation-team`
set normal_log_dir = "${p4_root}/depot/products/lpddr5x_ddr5_phy/ddr5/project/d910-ddr5-tsmc5ff-12/ckt/rel/dwc_ddr5phy_utility_blocks/1.10a/macro/pincheck/15M_1X_h_1Xb_v_1Xe_h_1Ya_v_1Yb_h_5Y_vhvhv_2Yy2Z_SHDMIM/dwc_ddr5phy_utility_blocks.pincheck"
set UBLOCK         = "${p4_root}/depot/products/lpddr5x_ddr5_phy/ddr5/project/d910-ddr5-tsmc5ff-12/ckt/rel/dwc_ddr5phy_utility_blocks"

# To get coverage
setenv GITROOT             "${git_root}"
setenv TOOL                "ddr-ckt-rel"
setenv DDR_DA_COVERAGE     1
setenv DDR_DA_DEFAULT_P4WS "p4_ws"
#setenv DDR_DA_MAIN         "${git_root}/ddr-ckt-rel/dev/main/"
unsetenv DDR_DA_MAIN
set prefix = ""
# you need P4CLIENT to be set to the one that belongs to p4_ws

goto NO_COVERAGE
COVERAGE:
    # Need to choose where the coverage database gets written to
    set cover_db = "${GITROOT}/${TOOL}_cover_db"
    setenv DDR_DA_COVERAGE_DB "${cover_db}"
    # erase that last coverage databse
    if ( -e $cover_db ) then
        echo "Remove existing $cover_db"
        rm -Rf $cover_db
    endif
    set prefix   = "/depot/perl-5.14.2/bin/perl -MDevel::Cover=-db,${cover_db}"

NO_COVERAGE:
${prefix} ${git_root}/${TOOL}/dev/main/bin/alphaPinCheck.pl \
     -log $PWD/output_log.pincheck \
     -nousage \
     -appendlog \
     -macro dwc_ddr5phy_decapvddq_dx4_ew \
     -tech  tsmc5ff-12 \
     -lefObsLayers 'M0 M1 M2 M3 M4 M5 M6 M7 M8 M9 M10 M11 M12 M13 M14 M15 M16 MTOP MTOP-1 AP' \
     -lefPinLayers 'M0 M1 M2 M3 M4 M5 M6 M7 M8 M9 M10 M11 M12 M13 M14 M15 M16 MTOP MTOP-1 AP' \
     -PGlayers 'M10 M14 M15 M16 MTOP MTOP-1 AP' \
     -since '2022-11-09 14:24:34'\
     -dateRef CDATE\
     -bracket square \
     -streamLayermap /remote/cad-rep/projects/ddr5/d910-ddr5-tsmc5ff-12/rel1.00_cktpcs/cad/15M_1X_h_1Xb_v_1Xe_h_1Ya_v_1Yb_h_5Y_vhvhv_2Yy2Z_SHDMIM/stream/stream.layermap  \
     -verilog ${UBLOCK}/1.10a/macro/behavior/dwc_ddr5phy_utility_blocks.v  \
     -gds ${UBLOCK}/1.10a/macro/gds/15M_1X_h_1Xb_v_1Xe_h_1Ya_v_1Yb_h_5Y_vhvhv_2Yy2Z_SHDMIM/dwc_ddr5phy_utility_blocks.gds.gz  \
     -verilog ${UBLOCK}/1.10a/macro/interface/dwc_ddr5phy_utility_blocks_interface.v  \
     -lef ${UBLOCK}/1.10a/macro/lef/15M_1X_h_1Xb_v_1Xe_h_1Ya_v_1Yb_h_5Y_vhvhv_2Yy2Z_SHDMIM/dwc_ddr5phy_utility_blocks.lef  \
     -lef ${UBLOCK}/1.10a/macro/lef/15M_1X_h_1Xb_v_1Xe_h_1Ya_v_1Yb_h_5Y_vhvhv_2Yy2Z_SHDMIM/dwc_ddr5phy_utility_blocks_merged.lef  \
     -cdl ${UBLOCK}/1.10a/macro/netlist/15M_1X_h_1Xb_v_1Xe_h_1Ya_v_1Yb_h_5Y_vhvhv_2Yy2Z_SHDMIM/dwc_ddr5phy_utility_blocks.cdl  \
     -liberty ${UBLOCK}/1.10a/macro/timing/15M_1X_h_1Xb_v_1Xe_h_1Ya_v_1Yb_h_5Y_vhvhv_2Yy2Z_SHDMIM/lib_lvf/dwc_ddr5phy_utility_blocks_ff0p825v0c.lib.gz  \
     -liberty ${UBLOCK}/1.10a/macro/timing/15M_1X_h_1Xb_v_1Xe_h_1Ya_v_1Yb_h_5Y_vhvhv_2Yy2Z_SHDMIM/lib_lvf/dwc_ddr5phy_utility_blocks_ff0p825v125c.lib.gz  \
     -liberty ${UBLOCK}/1.10a/macro/timing/15M_1X_h_1Xb_v_1Xe_h_1Ya_v_1Yb_h_5Y_vhvhv_2Yy2Z_SHDMIM/lib_lvf/dwc_ddr5phy_utility_blocks_ff0p825vn40c.lib.gz  \
     -liberty ${UBLOCK}/1.10a/macro/timing/15M_1X_h_1Xb_v_1Xe_h_1Ya_v_1Yb_h_5Y_vhvhv_2Yy2Z_SHDMIM/lib_lvf/dwc_ddr5phy_utility_blocks_ss0p675v0c.lib.gz  \
     -liberty ${UBLOCK}/1.10a/macro/timing/15M_1X_h_1Xb_v_1Xe_h_1Ya_v_1Yb_h_5Y_vhvhv_2Yy2Z_SHDMIM/lib_lvf/dwc_ddr5phy_utility_blocks_ss0p675v125c.lib.gz  \
     -liberty ${UBLOCK}/1.10a/macro/timing/15M_1X_h_1Xb_v_1Xe_h_1Ya_v_1Yb_h_5Y_vhvhv_2Yy2Z_SHDMIM/lib_lvf/dwc_ddr5phy_utility_blocks_ss0p675vn40c.lib.gz  \
     -liberty ${UBLOCK}/1.10a/macro/timing/15M_1X_h_1Xb_v_1Xe_h_1Ya_v_1Yb_h_5Y_vhvhv_2Yy2Z_SHDMIM/lib_lvf/dwc_ddr5phy_utility_blocks_tt0p75v25c.lib.gz  \
     -liberty ${UBLOCK}/1.10a/macro/timing/15M_1X_h_1Xb_v_1Xe_h_1Ya_v_1Yb_h_5Y_vhvhv_2Yy2Z_SHDMIM/lib_lvf/dwc_ddr5phy_utility_blocks_tt0p75v85c.lib.gz  \
     -liberty ${UBLOCK}/1.10a/macro/timing/15M_1X_h_1Xb_v_1Xe_h_1Ya_v_1Yb_h_5Y_vhvhv_2Yy2Z_SHDMIM/lib_pg_lvf/dwc_ddr5phy_utility_blocks_ff0p825v0c_pg.lib.gz  \
     -liberty ${UBLOCK}/1.10a/macro/timing/15M_1X_h_1Xb_v_1Xe_h_1Ya_v_1Yb_h_5Y_vhvhv_2Yy2Z_SHDMIM/lib_pg_lvf/dwc_ddr5phy_utility_blocks_ff0p825v125c_pg.lib.gz  \
     -liberty ${UBLOCK}/1.10a/macro/timing/15M_1X_h_1Xb_v_1Xe_h_1Ya_v_1Yb_h_5Y_vhvhv_2Yy2Z_SHDMIM/lib_pg_lvf/dwc_ddr5phy_utility_blocks_ff0p825vn40c_pg.lib.gz  \
     -liberty ${UBLOCK}/1.10a/macro/timing/15M_1X_h_1Xb_v_1Xe_h_1Ya_v_1Yb_h_5Y_vhvhv_2Yy2Z_SHDMIM/lib_pg_lvf/dwc_ddr5phy_utility_blocks_ss0p675v0c_pg.lib.gz  \
     -liberty ${UBLOCK}/1.10a/macro/timing/15M_1X_h_1Xb_v_1Xe_h_1Ya_v_1Yb_h_5Y_vhvhv_2Yy2Z_SHDMIM/lib_pg_lvf/dwc_ddr5phy_utility_blocks_ss0p675v125c_pg.lib.gz  \
     -liberty ${UBLOCK}/1.10a/macro/timing/15M_1X_h_1Xb_v_1Xe_h_1Ya_v_1Yb_h_5Y_vhvhv_2Yy2Z_SHDMIM/lib_pg_lvf/dwc_ddr5phy_utility_blocks_ss0p675vn40c_pg.lib.gz  \
     -liberty ${UBLOCK}/1.10a/macro/timing/15M_1X_h_1Xb_v_1Xe_h_1Ya_v_1Yb_h_5Y_vhvhv_2Yy2Z_SHDMIM/lib_pg_lvf/dwc_ddr5phy_utility_blocks_tt0p75v25c_pg.lib.gz  \
     -liberty ${UBLOCK}/1.10a/macro/timing/15M_1X_h_1Xb_v_1Xe_h_1Ya_v_1Yb_h_5Y_vhvhv_2Yy2Z_SHDMIM/lib_pg_lvf/dwc_ddr5phy_utility_blocks_tt0p75v85c_pg.lib.gz

