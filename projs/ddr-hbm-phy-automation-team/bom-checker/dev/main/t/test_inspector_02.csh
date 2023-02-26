#!/usr/bin/env tcsh

set PerlScriptName="../bin/inspector.pl"

# Test 2 : compare full BOM to the non-gzip'd rel pkg -> are zero differences properly reported?
set myDirName=`dirname $0`
pushd $myDirName

set myScriptName=`basename $0`

echo "# Test 2 : compare full BOM to the non-gzip'd rel pkg -> are zero differences properly reported?"

echo $PerlScriptName \
    -bom "bom--full.txt" \
    -tar "../tdata/release.pkg.example--dwc_ap_lpddr4x_multiphy_tsmc16ffc18_2.00a_sup1.tar" \
    -log $myScriptName 

$PerlScriptName \
    -bom "bom--full.txt" \
    -tar "../tdata/release.pkg.example--dwc_ap_lpddr4x_multiphy_tsmc16ffc18_2.00a_sup1.tar" \
    -log $myScriptName

popd 

exit 0
