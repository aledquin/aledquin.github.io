#!/bin/tcsh -f
#
set SOMETHING_FAILED = 0
set mydir = `/usr/bin/dirname $0`
set myScriptName  = `basename $0`
set tests = `\ls -1 $mydir/test_ViCi*.pl`

foreach test ($tests)
    set testname = `basename $test`
    set logName  = "${myScriptName}_${testname}.log"
    $test >& $mydir/$logName
    set abspath = `readlink -f $mydir/$logName`
    set ex = $?
    if ( $ex != 0 ) then
        echo "$test FAILED"
        echo "    See details in $abspath"
        echo " "
        set SOMETHING_FAILED = 1
    else
        # check for error messages in the log file '-E-'
        
        set err1 = `grep -iP -- 'Error|-F- |-E- ' $abspath`
        set ex1  = $?
        set err2 = `grep -iP 'uninitialized' $abspath`
        set ex2  = $?
        if ( $ex1 == 0 || $ex2 == 0 ) then
            echo "FAILED $test"
            echo "    $err1"
            echo "    $err2"
            echo "    See details in $abspath"
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
