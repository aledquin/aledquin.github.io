#!/bin/tcsh -f
#
set SOMETHING_FAILED = 0
set mydir = `/usr/bin/dirname $0`
set myScriptName  = `basename $0`
set tests = `\ls -1 $mydir/test_inspector*.csh`

foreach test ($tests)
    set testname = `basename $test`
    set logName  = "${myScriptName}_${testname}.log"
    $test >& $mydir/$logName
    set ex = $?
    if ( $ex == 1 ) then
        echo "$test FAILED"
        echo "    See details in $mydir/$logName"
        echo " "
        set SOMETHING_FAILED = 1
    else
        # check for error messages in the log file '-E-'
        set err1 = `grep -iP -- 'Error|-F- |-E- ' $mydir/$logName`
        set ex1  = $?
        set err2 = `grep -iP 'uninitialized' $mydir/$logName`
        set ex2  = $?
        if ( $ex1 == 0 || $ex2 == 0 ) then
            echo "FAILED $test"
            echo "    $err1"
            echo "    $err2"
            echo "    See details in $mydir/$logName"
            set SOMETHING_FAILED = 1
        else
            echo "PASSED $test"
            if ( -e $mydir/$logName ) then
                rm -f $mydir/$logName
            endif
        endif
    endif
end

exit( $SOMETHING_FAILED )
