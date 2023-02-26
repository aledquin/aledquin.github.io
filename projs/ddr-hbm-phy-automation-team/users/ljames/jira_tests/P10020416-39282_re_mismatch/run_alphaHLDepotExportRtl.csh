#!/bin/tcsh -f
#
#
unsetenv DDR_CKT_REL
unsetenv DDR_DA_MAIN
unsetenv DDR_DA_DEFAULT_P4WS
unsetenv GITROOT
unsetenv DDR_DA_COVERAGE     1
unsetenv DDR_DA_COVERAGE_DB

#
#The ExportRTL command seems broken.
# 
# I tried to run the following:
# 
# alphaHLDepotExportRtl.tcl -p ddr5/d912-ddr5-tsmc3eff-12/rel1.00_cktpcs
# 
# The script printed out a bunch of garbage for D931. The log is here:
# 
# /slowfs/us01dwt2p373/guttman/p4_ws/wwcad/msip/projects/ddr5/d912-ddr5-tsmc3eff-12/rel1.00_cktpcs/pcs/design/exportrtl.log
# 
# Let me know if anything else is required (there is a workaround by using an older module – 2022.05, so setting to high priority)

# using default /u/$USER/p4_ws area
set p4ws               = p4_ws
set p4client           = msip_cd_${USER}
set p4_root            = `realpath ~/${p4ws}`
set project_family     = "ddr5"
set macro              = ""
set project            = "d912-ddr5-tsmc3eff-12"
set release            = "rel1.00_cktpcs"
set proj_spec          = "${project_family}/${project}/${release}"
set p4_path            = "wwcad/msip/projects/${project_family}/${project}/${release}"
set p4_view_dir        = "//${p4_path}"
set p4_disk_dir        = "${p4_root}/${p4_path}"
set gitlab_root        = `realpath ~/GitLab/ddr-hbm-phy-automation-team`
set exe_dir            = ${gitlab_root}/ddr-ckt-rel/dev/main/bin
set script             = ${exe_dir}/alphaHLDepotExportRtl.tcl
set script_options     = "-p ${proj_spec} -d 2"
set run_prefix         = ""

set test_options       = ""
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
    set found = `p4 client -o  | grep $p4client | grep $project_family `
    if ( "$found" == "" ) then
        echo "    Nothing Found!"
        echo "    You need to add the following to your p4 views."
        echo "    ${p4_view_dir}/... //msip_cd_ljames/${p4_path}/..."
    endif
    echo "Try p4 sync -f $p4_view_dir/..."
    exit -1
endif

# 024319b68 (juliano                  2022-08-22 13:45:49 -0700 128)         if [regexp {^(\S+)#(\d+) .* (\d+) \([0-9a-z_\+]+\)} $f dummy depotFile ver changelist] {
# git diff 024319b68..HEAD


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

