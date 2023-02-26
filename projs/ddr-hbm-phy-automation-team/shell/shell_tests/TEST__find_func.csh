#!/bin/tcsh -f
#
# ScriptName : TEST__find_func.csh
# Author     : James Laderoute
# Created    : Feb 11 2022
#
#--

onintr -
unset noclobber

set this_script = "TEST__find_func"

setenv SCRIPTS_AREA "../../"
setenv LOG_NOW      "$PWD/${this_script}.out"
setenv LOG_GOLDEN   "$PWD/golden_output/${this_script}.out"
setenv LOG_DIFF     "$PWD/${this_script}.diff"

unalias echo
unalias test
unalias diff
unalias rm

set testing_status = 0

if ( -e $LOG_NOW ) then
    rm -f $LOG_NOW
endif


echo -n "${this_script} Part #1 "
#############################################################################

../find_func.csh hprint >& $LOG_NOW 

test -s $LOG_NOW

if ($status == 1 )  then
    echo "FAILED"
    echo "    Was expecting some output but got none."
    echo "    Maybe your SCRIPTS_AREA env is wrong?"
    echo "    SCRIPTS_AREA = $SCRIPTS_AREA"
    echo "    LOG_NOW = $LOG_NOW"
    set testing_status = 1
else
    echo "PASSED"
endif

echo -n "${this_script} Part #2 "
#############################################################################
../find_func.csh        >>& $LOG_NOW
if ($status == 1) then
    echo "FAILED"
    set testing_status = 1
else
    echo "PASSED"
endif

#
# Now check to see if the output of this test script matches what it
# used to output. 
#
if (  -e $LOG_GOLDEN ) then
    diff $LOG_NOW $LOG_GOLDEN >& $LOG_DIFF
    set diff_status = $status
    if ($diff_status == 1) then
        echo "$this_script has failures!"
        echo "\tThe diff between the output now and the golden output has failed"
        echo "\tGolden Log: $LOG_GOLDEN"
        echo "\tDiff Log: $LOG_DIFF"
        set testing_status = 1
    endif
else
    set testing_status = 1
    echo "$this_script could not run a diff because the expected golden file is missing"
    echo "\tWhere is $LOG_GOLDEN ?"
endif

if ( $testing_status == 0) then
    rm -f $LOG_DIFF
    rm -f $LOG_NOW
    echo "************************* PASSED  **********************************"
else
    echo "************************* FAILURE **********************************"
endif


exit( $testing_status )

