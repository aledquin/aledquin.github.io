#!/depot/local/bin/tcsh -f
#
# Author: James Laderoute
# Created: Feb 17 2022
# Purpose: To ensure all tests pass before you commit/push your changes
# 
# This script should be run before you do a push. More frequently is even
# better. Like after you make a set of changes, no matter how small you 
# want to do your best to ensure it isn't broken and doesn't break other 
# scripts.
#
# Example:
#    cd ~/GitLab/ddr-hbm-phy-automation-team/
#    ./full_regression_test_run.csh
#
# If anything does not PASS then please investigate why and repair the issue.
#test
#
# HISTORY:
#   001 ljames  6/22/2022
#       We no longer support bom-checker, so filter it out.
#   002 ljames  7/26/2022
#       We are able to remove the LINT set of checks, they are now built into
#       the Makefile runs. We also removed the COMPILE checks, they are now
#       built into the Makefile runs.
#-

#onintr -
unset noclobber
unalias test
unalias pwd
unalias rm
unalias echo

if ( ! $?USER ) then
    set USER = ljames
endif

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

#
# If you need to jump to a certain section (to help debug this script)
# then you can just add this 'goto LABEL' statement to get to that section.
#
#  goto TOOL_MAKE 

###############################################################################
TOOL_MAKE:
echo "Running each tool's Makefile for testing"
echo " "
set tool_log_ending = "_run_before_checkin_make.log"

pushd $GITDIR >& /dev/null
set tools = `ls -1 -d */ | awk -F/ '{print $1}'`
set skip_tools = ( notify bom-checker sharedlib )
foreach tool ( $tools )
    set runmake = 1
    foreach skip_pattern ( $skip_tools )
        set cond = `expr "$tool" : "^.*$skip_pattern"`
        if ( $cond != 0 ) then
            set runmake = 0
        endif
    end
    if ( $runmake == 1 ) then
        set tool_log = $TMPDIR/${tool}${tool_log_ending}
        set condition_file = $TMPDIR/${tool}.condition.$$
        ($GITDIR/run_makefile_for_tool.csh $tool $tool_log >& $condition_file &)  >& /dev/null
    endif
end

#
# I thought the tcsh builtin 'wait' command would wait for all the background
# processes of this process to finish.  But doesn't seem to be doing that for
# me 9/2/2022 1:14pm James.  So, instead I will look at which processes are
# running and keep looping until I see no more "run_makefile_for_tool" in
# the output.
#
# Seems when putting your background job in parens ( exe & ) , the wait command
# can't see it.
#
echo "before" > /u/$USER/before

set proc = `ps -f -u $USER | grep -v 'grep' | grep 'run_makefile_f'`
set check_status = $status
set num = 0
while ( $check_status == 0 )
    sleep 10
    set proc = `ps -f -u $USER | grep -v 'grep' | grep 'run_makefile_f'`
    set check_status = $status
    echo "middle $num status=$check_status proc=$proc" > /u/$USER/middle
    @ num = $num + 1
end

echo "after" > /u/$USER/after

# now check on the status of each makefile run
foreach tool ( $tools )
    set tool_log = $TMPDIR/${tool}${tool_log_ending}
    set condition_file = $TMPDIR/${tool}.condition.$$
    if ( -e $tool_log ) then
        set passed = `grep PASSED $condition_file`
        set grep_status = $status
        if ( $grep_status == 0 ) then
            set condition = "PASSED"
        else
            set condition = "FAILED"
        endif

        echo "$condition makefile for $tool"
        echo "    See $tool_log for details"
        echo " "
    endif
end


###############################################################################
UTIL:
echo "Running sharedlib Tests"
cd $GITDIR/sharedlib
set makefile = $GITDIR/sharedlib/Makefile
set tool_log = /tmp/${USER}_sharedlib.log.$$
make --keep-going -f $makefile test >& $tool_log
set last_status = $status
if ( $last_status != 0 ) then
    set HAS_ANYTHING_FAILED=1
    echo "FAILED 'make --keep-going -f $makefile'"
    echo "    See $tool_log for details"
    echo " "
else
    # Because --keep-going was used, it's possible that one of
    # the many targets has actually failed, but because the very
    # last target may have passed, the return status is 0. We need
    # to look in the tool_log file for anything that looks like it
    # failed (to be confident it passed). Note that when something
    # fails, it usually writes out "^FAILED.*" to the log. We can
    # look for those.
    set searchForFailed = `grep -P '^FAILED' $tool_log`
    if ( $status == 0 ) then
        set HAS_ANYTHING_FAILED=1
        echo "FAILED 'make --keep-going -f $makefile' - grep found FAILED in the log"
        echo "    See $tool_log for details"
        echo " "
    else
        echo "PASSED 'make --keep-going -f $makefile' ."
        echo "    See $tool_log for details"
        echo " "
    endif
endif

wait

if ( $HAS_ANYTHING_FAILED == 1 ) then
    echo " "
    echo "FAILURES have happened while running run_before_checkin.csh. "
    echo " "
else
    echo " "
    echo "All Tests run by run_before_checkin.csh have PASSED!  YAY!"
    echo " "
endif


###############################################################################
# If we made it this far then return success status
#
exit(0)
