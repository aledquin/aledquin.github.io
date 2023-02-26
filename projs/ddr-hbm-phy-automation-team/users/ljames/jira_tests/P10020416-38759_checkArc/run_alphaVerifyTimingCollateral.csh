#!/bin/tcsh
#
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
set project_family     = "ddr54"
set macro              = "rxdqs_diffmux"
set p4_view_dir        = "//wwcad/msip/projects/${project_family}/d822-ddr54-ss7hpp-18/latest/design/timing/sis_lvf/${macro}/"
set view_dir           = "${p4_root}/wwcad/msip/projects/${project_family}/d822-ddr54-ss7hpp-18"
set gitlab_root        = `realpath ~/GitLab/ddr-hbm-phy-automation-team`
set exe_dir            = ${gitlab_root}/ddr-ckt-rel/dev/main/bin
set script             = ${exe_dir}/alphaVerifyTimingCollateral.pl
set script_options     = "-project ddr54/d822-ddr54-ss7hpp-18/rel1.00_cktpcs -macros ${macro} -metalStack 18M_4Mx_4Dx_4Hx_2Bx_2Gx_2UTM_ILB -timingRel latest -ui 266.66 -lvf "
set run_prefix         = ""

if ( ! -e $p4_root ) then
    echo "-F- This won't run because your p4 path couldn't be found. p4_root='$p4_root'"
    exit -1
endif

if ( ! -e $view_dir ) then
    echo "-F- This probably won't run because you don't have the VIEW synced."
    echo "    ${view_dir}"
    echo "Looking in your p4 client views grepping for '$project_family' finds:"
    set found = `p4 client -o  | grep $p4client | grep $project_family | grep $macro`
    if ( "$found" == "" ) then
        echo "You need to add the following to your p4 views."
        echo "//wwcad/msip/projects/${project_family}/d822-ddr54-ss7hpp-18/rel1.00_cktpcs/pcs/design/timing/... //msip_cd_ljames/wwcad/msip/projects/${project_family}/d822-ddr54-ss7hpp-18/rel1.00_cktpcs/pcs/design/timing/..."
    endif
    exit -1
endif



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

