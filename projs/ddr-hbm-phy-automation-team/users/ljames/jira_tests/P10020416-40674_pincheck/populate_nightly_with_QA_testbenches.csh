#!/bin/tcsh -f
set qapath=QA_test_plan/QA_testbenches/alphaPinCheck/alphaPinCheck_002/QA_dwc_ddrphy_txrxdq_ns_ddr54
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
set macro       = dwc_ddrphy_txrxdq_ns 
set lefpath     = $targetdir/lef/dwc_ddrphy_txrxdq_ns_merged.lef
set libpath1    = $targetdir/lib_pg/dwc_ddrphy_txrxdq_ns_18M_4Mx_4Dx_4Hx_2Bx_2Gx_2UTM_ILB_fsg0p675v125c_pg.lib
# NOTE:  if you remove this 2nd path, you won't see any errors. But Sanjana believes it should complain about missing PG pins.
set libpath2    = $targetdir/lib_pg/dwc_ddrphy_txrxdq_ns_18M_4Mx_4Dx_4Hx_2Bx_2Gx_2UTM_ILB_sspg0p675vn40c_pg.lib
set nopglibpath = $targetdir/lib/dwc_ddrphy_txrxdq_ns_18M_4Mx_4Dx_4Hx_2Bx_2Gx_2UTM_ILB_fsg0p675v125c.lib
echo ""
echo "alphaPinCheck.pl -macro $macro -lef $lefpath -liberty $libpath1 -liberty $libpath2 -libertynopg $nopglibpath" |& tee test01_alphaPinCheck.csh
#echo "alphaPinCheck.pl -macro $macro -lef $lefpath -liberty $libpath1                    -libertynopg $nopglibpath" |& tee test02_alphaPinCheck.csh


