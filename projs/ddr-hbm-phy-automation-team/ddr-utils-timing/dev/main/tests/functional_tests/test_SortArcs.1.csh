#!/bin/tcsh -f

set PerlScriptName="../../bin/SortArcs.pl"
set myDirName=`dirname $0`
pushd $myDirName >& /dev/null

if ( ! -e $PerlScriptName ) then
    echo "Unable to locate script $PerlScriptName !"
    popd >& /dev/null
    exit(1)
endif

set myScriptName=`basename $0`
echo "$PerlScriptName \
    ../data/dwc_lpddr5xmphy_zcalio_ew_15M_1X_h_1Xb_v_1Xe_h_1Ya_v_1Yb_h_5Y_vhvhv_2Yy2Z_ffg0p675v0c_pg.lib"

$PerlScriptName "../data/dwc_lpddr5xmphy_zcalio_ew_15M_1X_h_1Xb_v_1Xe_h_1Ya_v_1Yb_h_5Y_vhvhv_2Yy2Z_ffg0p675v0c_pg.lib" 
set ex=$status
if ($ex != 0) then
	echo "FAILED $PerlScriptName"
    echo " "
	popd >& /dev/null
	exit 1
endif

popd >& /dev/null

exit 0
