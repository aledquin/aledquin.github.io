#!/bin/tcsh 
#
# You can pass this script 3 optional arguments. You must supply them
# in the following order and can't specify the last without the first few.
#
# update_tool_coverage.csh <tool> <savelog> <gitlab-root>
#
#-

module use --append /remote/cad-rep/etc/modulefiles/msip
# Load specific versions of common tools
module unload git
module unload vim
module unload tar

module load git/2.30.0
module load vim/8.0
module load tar

set BRMAIN = main 
#set BRMAIN = main
set DEFAULT_TOOL = ddr-ckt-rel
set TOOL         = $DEFAULT_TOOL
set PERLBINDIR   = /depot/perl-5.14.2/bin
if ( $?USER ) then
    set USER = "ljames"
endif

set tempdir = /tmp/$USER
if ( ! -e $tempdir ) then
    mkdir -p $tempdir
endif

#
# set default settings for savelog and gitlab root dir
#
set savelog = $tempdir/update_${TOOL}_coverage_$$.log
set gitlab = $tempdir/gitlab

if ( $#argv > 0 ) then
    set TOOL = $argv[1]
endif
if ( $#argv > 1 ) then
    set savelog = $argv[2]
endif
if ( $#argv > 2 ) then
    set gitlab = $argv[3]
endif

setenv GITROOT $gitlab/ddr-hbm-phy-automation-team

echo "update_tool_coverage.csh Tool:'$TOOL' for User:'$USER'"


# The setting of this env DDR_DA_TESTING_NOUSAGE tells the Misc.pm's 
# subroutine that issues the Kibana usage call to skip it and just
# return without doing anything.
#
setenv DDR_DA_TESTING_NOUSAGE 1
setenv DDR_DA_COVERAGE 1
if ( ! $?DDR_DA_COVERAGE_DB ) then
    setenv DDR_DA_COVERAGE_DB  "$GITROOT/${TOOL}_cover_db"
endif

# DEFAULT_WORKSPACE tells our testing scripts to use this as the p4_ws
# instead of the default ~/p4_ws

setenv DEFAULT_WORKSPACE p4_nightly_runs

# Tell this script where to dump the html files

set COVERAGE_HTMLDIR=/u/$USER/public_html/coverage
set HTMLDIR=$COVERAGE_HTMLDIR/${TOOL}-tests

# set the timezone to EST (where James lives)
set TZ = EST
#set gitlab=/u/$USER/GitLab

#
# Create a new clone to run tests in (if one isn't already there)
#
if ( ! -e $gitlab ) then
    mkdir -p $gitlab
    cd $gitlab
    git clone git@snpsgit.internal.synopsys.com:ddr-hbm/ddr-hbm-phy-automation-team.git
    cd ddr-hbm-phy-automation-team
    git config pull.rebase false
else
    cd $gitlab/ddr-hbm-phy-automation-team
    git pull origin $BRMAIN 
endif


# The generated folder named 'TOOL_cover_db' ends up getting created in the 
# gitlab root directory. If this was called by nightly_runs, then the 
# folder will already exist and be pre-populated with sharedlib coverage info.
cd ${GITROOT}/${TOOL}/dev/main
make coverage |& tee $savelog

if ( ! -e $savelog ) then
    echo "FAILED... where is the $TOOL $savelog ?"
    #mail -s"FAILED: $TOOL functional testing coverage results" ${USER}@synopsys.com  < /dev/null
endif
if ( ! -e ${GITROOT}/${TOOL}_cover_db ) then
    echo "FAILED... where is the ${TOOL}_cover_db/  dir?"
    #mail -s"FAILED: $TOOL testing coverage missing cover_db" ${USER}@synopsys.com  < $savelog
    exit -1
endif

# Read the tool_cover_db data and produce the html reports
echo "Running cover to create the $TOOL coverage reports"
cd ${GITROOT}
$PERLBINDIR/cover ${TOOL}_cover_db

if ( ! -e $HTMLDIR) then
    mkdir -p $HTMLDIR
else
    \rm -fR $HTMLDIR
    sleep 1
    mkdir -p $HTMLDIR
endif

# Now copy the created cover_db to the public_html area
unset noclobber
if ( -e ${TOOL}_cover_db ) then
    \cp -f -v -- ${TOOL}_cover_db/* $HTMLDIR/
    \cp -f -v -- $HTMLDIR/coverage.html $HTMLDIR/index.html
endif

# Update the coverage/index.html to put the date for these
# ddr-ckt-rel functional tests in there
#
set thedate=`date`
$PERLBINDIR/perl -i -p -e 's/(^.*'"$TOOL"'-tests.*)\[.*\](.*$)/\1\['"$thedate"'\]\2/g'  $COVERAGE_HTMLDIR/index.html 

echo "Done post processing coverage/index.html"

exit 0

