#!/bin/tcsh -f

set mydir=`/usr/bin/dirname $0`

$mydir/test_alphaVerifyTimingCollateral.1.csh >& /dev/null

set ex=$?


if ($ex != 0) then
    echo "FAILED $0"
	exit 1
else
    echo "PASSED $0"
endif


