#!/usr/bin/env tcsh

set PerlScriptName="../bin/inspector.pl"

# Test 5 : compare fully bogus (random file names only) BOM to the non-gzip'd rel pkg -> does script detect the differences properly and write to BOM only log file?
set myDirName=`dirname $0`
pushd $myDirName

set myScriptName=`basename $0`

echo "# Test 5 : compare fully bogus (random file names only) BOM to the non-gzip'd rel pkg -> does script detect the differences properly and write to BOM only log file?" 

echo $PerlScriptName \
    -bom bom--fully-bogus.txt \
    -tar ../tdata/release.pkg.example--dwc_ap_lpddr4x_multiphy_tsmc16ffc18_2.00a_sup1.tar \
    -log $myScriptName

$PerlScriptName \
    -bom bom--fully-bogus.txt \
    -tar ../tdata/release.pkg.example--dwc_ap_lpddr4x_multiphy_tsmc16ffc18_2.00a_sup1.tar \
    -log $myScriptName

popd 

exit 0
