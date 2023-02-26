#!/usr/bin/env tcsh

set PerlScriptName="../bin/inspector.pl"

# Test 1 : compare full BOM to the     gzip'd rel pkg -> are zero differences properly reported?
set myDirName=`dirname $0`
pushd $myDirName >& /dev/null

set myScriptName=`basename $0`
set myLogFileName="$myScriptName.log"

echo "# Test 1 : compare full BOM to the     gzip'd rel pkg -> are zero differences properly reported?"

echo "$PerlScriptName \
    -verbosity 3 \
    -bom bom--full.txt \
    -ref ../tdata/release.pkg.example--dwc_ap_lpddr4x_multiphy_tsmc16ffc18_2.00a_sup1.tar.gz" 

$PerlScriptName \
    -verbosity 3 \
    -bom "bom--full.txt" \
    -ref "../tdata/release.pkg.example--dwc_ap_lpddr4x_multiphy_tsmc16ffc18_2.00a_sup1.tar.gz" \
    -log $myScriptName

popd >& /dev/null
exit 0
