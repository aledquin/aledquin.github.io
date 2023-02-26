#!/bin/tcsh
#
# Updates:
# 001: I copied guttman's p4_ws/wwcad/msip/products/lpddr5x_ddr5_phy/ddr5/project/d910-ddr5-tsmc5ff-12/ckt/... area to my p4_ws area; using cp recursive
# 002: I see that my view map was from /depot/products and not wwcad/msip/products ... fixed at 10:00am
# 003: This macro is passed to alphaPinCheck.pl "dwc_ddr5phydx4_notcoil_ew" is
#      it in my views? How do I search for it?
# 004: After copying guttman's area to mine; noticed that projspace is a symlink
#      into guttman's area: /slowfs/us01dwt2p373/guttman/p4_ws/wwcad/msip/projects/ddr5/d910-ddr5-tsmc5ff-12/rel1.00_cktpcs/pcs/design
#      So instead of using a symlink, I copied his area to projspace area.
#      NOTE: projspace is ${view_dir}/rel/projspace
#
unsetenv DDR_CKT_REL
unsetenv DDR_DA_MAIN
unsetenv DDR_DA_DEFAULT_P4WS
unsetenv GITROOT
unsetenv DDR_DA_COVERAGE     1
unsetenv DDR_DA_COVERAGE_DB


# using default /u/$USER/p4_ws area
set p4ws               = p4_ws
set p4client           = msip_cd_${USER}
set p4_root            = `realpath ~/${p4ws}`
set view_dir           = ${p4_root}/wwcad/msip/products/lpddr5x_ddr5_phy/ddr5/project/d910-ddr5-tsmc5ff-12/ckt
set view_projspace_dir = ${view_dir}/rel/projspace
set gitlab_root        = `realpath ~/GitLab/ddr-hbm-phy-automation-team`
set exe_dir            = ${gitlab_root}/ddr-ckt-rel/dev/main/bin
set script             = ${exe_dir}/alphaHLDepotRelPinCheck
set script_options     = "-p4ws $p4ws -p ddr5/d910-ddr5-tsmc5ff-12/rel1.00_cktpcs -macros dwc_ddr5phy_utility_blocks -verbosity 1"
set run_prefix         = ""

if ( ! -e $p4_root ) then
    echo "-F- This won't run because your p4 path couldn't be found. p4_root='$p4_root'"
    exit -1
endif

echo "p4_root:'$p4_root'"
exit


# Setup basic env variables to run this test; but also to run our functional
# tests if we wish.

setenv GITROOT  "${gitlab_root}"
setenv TOOL     "ddr-ckt-rel"
setenv P4CLIENT "$p4client"

if ( $?FUNCTIONAL_TESTS ) then
    setenv DDR_DA_MAIN         "${git_root}/ddr-ckt-rel/dev/main/"
    setenv DDR_DA_DEFAULT_P4WS "${p4ws}"
endif

# To enable code coverage

if ( $?ADD_COVERAGE ) then
    setenv DDR_DA_COVERAGE     1
    setenv DDR_DA_COVERAGE_DB  "${GITROOT}/${TOOL}_cover_db"

    # erase that last coverage databse
    if ( -e $DDR_DA_COVERAGE_DB) then
        echo "Remove existing $DDR_DA_COVERAGE_DB"
        rm -Rf $DDR_DA_COVERAGE_DB
    endif

    set run_prefix   = "/depot/perl-5.14.2/bin/perl -MDevel::Cover=-db,${DDR_DA_COVERAGE_DB} "
endif

$run_prefix $script $script_options

