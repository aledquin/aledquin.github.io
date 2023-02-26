#!/bin/tcsh
#
# Usage:
#
#   update_sharedlib_coverage.csh  [gitlab_top]
#


module use --append /remote/cad-rep/etc/modulefiles/msip
# Load specific versions of common tools
module unload git
module unload vim
module unload tar

module load git/2.30.0
module load vim/8.0
module load tar

if ( $?USER ) then
    set USER = "ljames"
endif

# The setting of this env DDR_DA_TESTING_NOUSAGE tells the Misc.pm's 
# subroutine that issues the Kibana usage call to skip it and just
# return without doing anything.
#
setenv DDR_DA_TESTING_NOUSAGE 1

# DEFAULT_WORKSPACE tells our testing scripts to use this as the p4_ws
# instead of the default ~/p4_ws

setenv DEFAULT_WORKSPACE p4_nightly_runs

# Tell this script where to dump the html files

set COVERAGE_HTMLDIR=/u/$USER/public_html/coverage
set HTMLDIR=$COVERAGE_HTMLDIR/sharedlib

set BRMAIN = main 
#set BRMAIN = main

# set the timezone to EST (where James lives)
set TZ=EST
set tempdir=/tmp/$USER
if ( ! -e $tempdir ) then
    mkdir -p $tempdir
endif

set savelog=$tempdir/update_sharedlib_coverage_$$.log
set gitlab=$tempdir/gitlab

if ( $#argv > 0 ) then
    set gitlab=$argv[1]
endif

setenv GITROOT ${gitlab}/ddr-hbm-phy-automation-team
setenv DDR_DA_COVERAGE 1
if ( ! $?DDR_DA_COVERAGE_DB ) then
    setenv DDR_DA_COVERAGE_DB "$GITROOT/sharedlib_cover_db"
endif

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
    cd $GITROOT
    git pull origin $BRMAIN 
endif

if ( -e $GITROOT/sharedlib_cover_db ) then
    rm -Rf $GITROOT/sharedlib_cover_db
endif

cd $GITROOT/sharedlib

# Run coverage by using the sharedlib  Makefile target named coverage
# This will create sharedlib_cover_db in $GITROOT
make coverage |& tee $savelog
cd $GITROOT
if ( ! -e $GITROOT/sharedlib_cover_db ) then
    echo "FAILED... where is the sharedlib_cover_db/  dir?"
    mail -s'FAILED: sharedlib testing coverage missing sharedlib_cover_db' $USER@synopsys.com  < $savelog
    exit -1
endif

# Read the cover_db data and produce the html reports
echo "Running cover to create the reports"
cd $GITROOT
cp -Rf sharedlib_cover_db   only_sharedlib_cover_db
/depot/perl-5.14.2/bin/cover only_sharedlib_cover_db

if ( ! -e $HTMLDIR) then
    mkdir -p $HTMLDIR
else
    \rm -fR $HTMLDIR/*
    mkdir -p $HTMLDIR
endif


# Now copy the created cover_db to the public_html area
\cp -f -v only_sharedlib_cover_db/* $HTMLDIR
\cp -f -v $HTMLDIR/coverage.html $HTMLDIR/index.html

# Remove the temporary cover_db
rm -Rf $GITROOT/only_sharedlib_cover_db

set email_log = "/tmp/nightly_coverage_sharedlib_log_$$"
if ( -e $email_log ) then
    \rm $email_log
endif

set team_email = "ljames@synopsys.com juliano@synopsys.com alvaro@synopsys.com dikshant@synopsys.com seguinn@synopsys.com"
#touch $email_log
#echo "Nightly Sharedlib Coverage Results"               >> $email_log
#echo "                                                " >> $email_log
#echo " Link: https://lamp/~ljames/coverage/index.html " >> $email_log
#echo "                                                " >> $email_log
#echo "                                                " >> $email_log
#echo "Trying to email $email_log to $team_email"
#
#if ( $?JAMES_TEST_NIGHTLY ) then
#    set team_email = "ljames@synopsys.com"
#endif

# Update the coverage/index.html to put the date for these
# ddr-ckt-rel functional tests in there
#
set thedate=`date`
perl -i -p -e 's/(^.*Sharedlib.*)\[.*\](.*$)/\1\['"$thedate"'\]\2/g'  $COVERAGE_HTMLDIR/index.html 

#mailx -s'Nightly_SharedLib_Coverage_Results' $team_email  < $email_log

sleep 2

if ( -e $email_log ) then
    \rm $email_log
endif

exit 0

