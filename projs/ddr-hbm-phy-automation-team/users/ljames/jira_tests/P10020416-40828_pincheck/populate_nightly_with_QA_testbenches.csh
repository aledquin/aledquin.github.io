#!/bin/tcsh -f

set qapath=QA_test_plan/QA_testbenches/alphaPinCheck/alphaPinCheck_002/QA_dwc_lpddr5xphy_txrxdq_ew_lpddr5x
set targetdir=/u/ljames/p4_nightly_runs/$qapath
set srctop=/slowfs/us01dwt3p213/us01dwt3p216/shakthi
unset noclobber

mkdir -p $targetdir
if ( ! -e $targetdir ) then
    echo "Failed to create $targetdir !"
    exit 1
endif

cp -Rf $srctop/$qapath/lef    $targetdir/
if ( -e $srctop/$qapath/lib_pg ) then
    echo "copying the lib_pg to $targetdir/"
    cp -Rf $srctop/$qapath/lib_pg $targetdir/
    if ( ! -e $targetdir/lib_pg ) then
        echo "NOT CREATED: $targetdir/lib_pg/"
    endif
endif

cp -Rf $srctop/$qapath/lib    $targetdir/


# Test line
#
set macro       = dwc_lpddr5xphy_txrxdq_ew
set lefpath     = $targetdir/lef/dwc_lpddr5xphy_txrxdq_ew_merged.lef
set libpath1    = $targetdir/lib_pg/dwc_lpddr5xphy_txrxdq_ew_15M_1X_h_1Xb_v_1Xe_h_1Ya_v_1Yb_h_5Y_vhvhv_2Yy2Z_ffgnp0p715v0c_pg.lib
# NOTE:  if you remove this 2nd path, you won't see any errors. But Sanjana believes it should complain about missing PG pins.
set libpath2    = $targetdir/lib_pg/dwc_lpddr5xphy_txrxdq_ew_15M_1X_h_1Xb_v_1Xe_h_1Ya_v_1Yb_h_5Y_vhvhv_2Yy2Z_ffgnp0p6v85c_pg.lib
set nopglibpath = $targetdir/lib/dwc_lpddr5xphy_txrxdq_ew_15M_1X_h_1Xb_v_1Xe_h_1Ya_v_1Yb_h_5Y_vhvhv_2Yy2Z_ffgnp0p715v0c.lib
echo ""
echo "alphaPinCheck.pl -macro $macro -lef $lefpath -liberty $libpath1 -liberty $libpath2 -libertynopg $nopglibpath" |& tee test01_alphaPinCheck.csh
echo "alphaPinCheck.pl -macro $macro -lef $lefpath -liberty $libpath1                    -libertynopg $nopglibpath" |& tee test02_alphaPinCheck.csh


