#!/depot/local/bin/tcsh -f
#
# Author: James Laderoute
# Created: Sep 1 2022
# Purpose: To run the makefile and check for errors
# 
# Example:
#    cd ~/GitLab/ddr-hbm-phy-automation-team/
#    ./run_makefile_for_tool.csh ddr-ckt-rel
#
# If anything does not PASS then please investigate why and repair the issue.
# test
#
# HISTORY:
#   001 ljames  9/1/2022
#       created this script
#-
onintr -
unset noclobber
unalias test
unalias pwd
unalias rm
unalias echo

set TMPDIR=/tmp/$USER/tests_output
if ( ! -e $TMPDIR ) then
    mkdir -p $TMPDIR
endif
#
# The setting of this env DA_TEST_NOGUI is a hint to all tests that it
# should not popup a gui that would halt testing.
# 
setenv DA_TEST_NOGUI 1

#
# The setting of this env DDR_DA_SKIP_USAGE tells the Misc.pm's 
# subroutine that issues the Kibana usage call to skip it and just
# return without doing anything.
#
setenv DDR_DA_SKIP_USAGE 1

set GITDIR = `realpath .`
set HAS_ANYTHING_FAILED = 0
if ( $#argv == 0 ) then
    echo "You need to specify a tool name like ddr-ckt-rel"
    exit -1
endif

set tool = $argv[1]
setenv DDR_DA_MAIN $GITDIR/${tool}/dev/main

if ( $#argv > 1) then
    set tool_log = $argv[2] # eg. /tmp/${USER}_${tool}.log.$$
else
    set tool_log = $TMPDIR/${tool}_run_makefile_for_tool.log
endif

set makefile = $GITDIR/${tool}/dev/main/Makefile

if ( -e $makefile ) then
    pushd $GITDIR/${tool}/dev/main >& /dev/null
    # Cleanup previous tool_log file. Small chance of having the
    # same file because the filename is using the PID.
    if ( -e $tool_log ) then
        rm -f $tool_log
    endif
    make --keep-going -f $makefile >& $tool_log
    set last_status = $status
    set result_fail = `grep 'Result: FAIL' $tool_log`
    set grep_status = $status
    set result_fail = `grep 'FAILED:' $tool_log`
    set grep_failed_status = $status
    if ( $last_status != 0 || $grep_status == 0 || $grep_failed_status == 0) then
        set HAS_ANYTHING_FAILED=1
        echo "FAILED"
    else
        # Because --keep-going was used, it's possible that one of
        # the many targets has actually failed, but because the very
        # last target may have passed, the return status is 0. We need
        # to look in the tool_log file for anything that looks like it
        # failed (to be confident it passed). Note that when something
        # fails, it usually writes out "^FAILED.*" to the log. We can
        # look for those.
        set searchForFailed = `grep -P '^FAILED\s' $tool_log`
        if ( $status == 0 ) then
            set HAS_ANYTHING_FAILED=1
            echo "FAILED"
        else
            echo "PASSED"
        endif
    endif
    popd >& /dev/null
endif

if ( $HAS_ANYTHING_FAILED == 1 ) then
    exit(1)
endif

exit(0)

