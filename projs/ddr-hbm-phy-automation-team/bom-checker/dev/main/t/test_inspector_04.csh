#!/usr/bin/env tcsh

set PerlScriptName="../bin/inspector.pl"

# Test 4 : compare partial BOM to the non-gzip'd rel pkg -> does script detect the differences properly
set myDirName=`dirname $0`
pushd $myDirName

set myScriptName=`basename $0`

echo "# Test 4 : compare partial BOM to the non-gzip'd rel pkg -> does script detect the differences properly" 

echo $PerlScriptName \
    -bom bom--partial.txt \
    -tar ../tdata/release.pkg.example--dwc_ap_lpddr4x_multiphy_tsmc16ffc18_2.00a_sup1.tar \
    -log $myScriptName 

$PerlScriptName \
    -bom bom--partial.txt \
    -tar ../tdata/release.pkg.example--dwc_ap_lpddr4x_multiphy_tsmc16ffc18_2.00a_sup1.tar \
    -log $myScriptName

popd 

exit 0
