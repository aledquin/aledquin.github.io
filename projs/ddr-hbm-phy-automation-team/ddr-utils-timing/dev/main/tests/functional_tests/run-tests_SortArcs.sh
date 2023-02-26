#!/bin/tcsh -f
set SOMETHING_FAILED = 0
set mydir = `/usr/bin/dirname $0`
set myScriptName  = `basename $0`
set tests = `\ls -1 $mydir/test_SortArcs*.csh`
foreach test ($tests)
    set testname = `basename $test`
    set logName  = "${myScriptName}_${testname}.log"
    $test >& $mydir/$logName
    set ex = $?
    if ( $ex != 0 ) then
        echo "$test FAILED"
        echo "    See details in $mydir/$logName"
        echo " "
        set SOMETHING_FAILED = 1
    else
        set SECOND_CHECK_FAILED=0
        # check for error messages in the log file '-E-'
        set err1 = `grep -iP -- 'Error|-E- ' $mydir/$logName`
        set ex1  = $?
        set err2 = `grep -iP 'uninitialized' $mydir/$logName`
        set ex2  = $?

        if ( $ex1 == 0 || $ex2 == 0 ) then
            echo "$test FAILED"
            set SOMETHING_FAILED = 1
            set SECOND_CHECK_FAILED = 1
        endif

        if ( $ex1 == 0 ) then
            echo "    'Error' or '-E-' spotted."
        endif

        if ( $ex2 == 0 ) then
            echo "    'uninitialized' warnings found."
        endif

        if ( 0 == $SECOND_CHECK_FAILED ) then
            echo "$test PASSED"
            if ( -e $mydir/$logName ) then
                rm -f $mydir/$logName
            endif
        else
            echo "    See details in $mydir/$logName"
        endif
    endif
end

exit( $SOMETHING_FAILED )

