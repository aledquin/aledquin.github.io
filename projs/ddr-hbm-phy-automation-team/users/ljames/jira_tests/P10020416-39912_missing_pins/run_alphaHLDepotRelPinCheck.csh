#!/bin/tcsh -f
#
# https://jira.internal.synopsys.com/browse/P10020416-39912

unsetenv DDR_CKT_REL
unsetenv DDR_DA_MAIN
unsetenv DDR_DA_DEFAULT_P4WS
unsetenv GITROOT
unsetenv DDR_DA_COVERAGE     1
unsetenv DDR_DA_COVERAGE_DB

# using default /u/$USER/p4_ws area
# alphaHLDepotRelPinCheck -macros dwc_hbmphy_clkio -p hbm3/d763-hbm3-v2-tsmc3eff-12-ew/rel1.00
# p4 sync -f //depot/products/hbm3_v2/project/d763-hbm3-v2-tsmc3eff12/ckt/rel/dwc_hbmphy_clkio/1.00a/
#
set p4ws               = p4_ws
set p4client           = msip_cd_${USER}
set p4_root            = `realpath ~/${p4ws}`
set project_family_cad = "hbm3"
set project_family     = "hbm3_v2"
set macro              = "dwc_hbmphy_clkio"
set project            = "d763-hbm3-v2-tsmc3eff12"
set project_cad        = "d763-hbm3-v2-tsmc3eff-12-ew"
set release_cad        = "rel1.00"
set release_ver        = "1.00a"
set proj_spec          = "${project_family_cad}/${project_cad}/${release_cad}"
set p4_path            = "products/${project_family}/project/${project}/ckt/rel"
set p4_path_cad        = "products/${project_family_cad}/project/${project_cad}/ckt/rel"
set p4_view_dir        =          "//depot/${p4_path}/${macro}/${release_ver}"
set p4_disk_dir        = "${p4_root}/depot/${p4_path}/${macro}/${release_ver}"
set p4_cad_disk_dir    = "${p4_root}/wwcad/msip/${p4_path_cad}/${macro}/${release_cad}"
set gitlab_root        = `realpath ~/GitLab/ddr-hbm-phy-automation-team`
set exe_dir            = ${gitlab_root}/ddr-ckt-rel/dev/main/bin
set script             = ${exe_dir}/alphaHLDepotRelPinCheck
set script_options     = "-macros ${macro} -p ${proj_spec}"
set run_prefix         = ""

set test_options       = "" #" -debug 1 -verbosity 5"
if ( $#argv != 0 ) then
    set test_options = "$*"
endif

if ( ! -e $p4_root ) then
    echo "-F- This will not run because your p4 root path could not be found. p4_root='$p4_root' "
    exit -1
endif

if ( ! -e $p4_disk_dir) then
    echo "-F- This probably won't run because you don't have the VIEW synced."
    echo "    ${p4_disk_dir}"
    echo "Looking in your p4 client views grepping for '$project_family' finds:"
    set found = `p4 client -o  | grep $p4client | grep $project_family | grep $macro`
    if ( "$found" == "" ) then
        echo "    Nothing Found!"
        echo "    You need to add the following to your p4 views."
        echo "    ${p4_view_dir}/... //${p4client}/depot/${p4_path}/${macro}/${release_ver}/..."
    endif
    echo "Try p4 sync -f $p4_disk_dir/..."
    exit -1
endif

set cmd = "p4 sync -f $p4_disk_dir/... "
echo "running $cmd"
set ok = `$cmd`
sleep 2

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


$run_prefix $script $script_options $test_options

FIND_MISSING:
set echo
grep -P "missing in" ${p4_root}/depot/${p4_path}/${macro}/${release_ver}/macro/${macro}.pincheck
unset echo


