#!/usr/bin/env tcsh

set PerlScriptName="../../bin/alphaVerifyTimingCollateral.pl"

set Product="lpddr5x"
set Project="d930-lpddr5x-tsmc5ff12"
set Macro="dwc_lpddr5xphy_ato_ew"
set MetalStack="15M_1X_h_1Xb_v_1Xe_h_1Ya_v_1Yb_h_5Y_vhvhv_2Yy2Z"
set Release="rel1.00_cktpcs"

# Test 1 : comment here
#
set myDirName=`dirname $0`
pushd $myDirName


if ( ! -e $PerlScriptName ) then
    echo "Unable to locate script $PerlScriptName !"
    exit(1)
endif

set myScriptName=`basename $0`
set myLogFileName="$myScriptName.log"


echo "# Test 1 : some comment " > $myLogFileName

echo "$PerlScriptName \
     -project ${Product}/${Project}/${Release} \
	 -timingRel ${Release} \
	 -macros ${Macro} \
	 -metalStack ${MetalStack} \
	 -ui 117.19 \
	 -nop4Logs \
	 -lvf \
"
$PerlScriptName \
     -project ${Product}/${Project}/${Release} \
	 -timingRel ${Release} \
	 -macros ${Macro} \
	 -metalStack ${MetalStack} \
	 -ui 117.19 \
	 -nop4Logs \
	 -lvf \
>>& $myLogFileName

set ex=$status

if ($ex == 1) then
	echo "$PerlScriptName Failed"
	popd
	exit 1
endif
# clean up logs
if ( -e $myLogFileName ) then
    rm -f $myLogFileName
endif
if ( -e "${myScriptName}_${Macro}.log" ) then
    rm -f "${myScriptName}_${Macro}.log"
endif

popd
exit 0
