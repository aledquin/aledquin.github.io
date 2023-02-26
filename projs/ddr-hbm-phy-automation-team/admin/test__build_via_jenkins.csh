#!/bin/tcsh -f

# Setup some env vars that would be setup if this was called
# via the Jenkins Job ...

if ( ! $?WORKSPACE ) then
    setenv WORKSPACE /u/$USER/GitLab/ddr-hbm-phy-automation-team
endif

if ( ! -e $WORKSPACE ) then
    echo "******** Test is unable to run because your WORKSPACE does not exist"
    echo "         Your Workspace is expected to be: $WORKSPACE "
    exit -1
endif

setenv WORKSPACE_TMP /tmp/$USER/workspace_tmp
if ( ! -e $WORKSPACE_TMP ) then
    mkdir -p $WORKSPACE_TMP
endif

set BRMAIN = main 

setenv PWD                            $WORKSPACE
setenv GIT_COMMIT                     'e8a9868166fa75f5279cbc60fa844147151a4bd6'
setenv gitlabAfter                    'e8a9868166fa75f5279cbc60fa844147151a4bd6'
setenv GIT_PREVIOUS_COMMIT            '60ab7f51d1e4ae249c68ea8ae8031344e66f474f'
setenv GIT_PREVIOUS_SUCCESSFUL_COMMIT '60ab7f51d1e4ae249c68ea8ae8031344e66f474f'
setenv gitlabBefore                   '60ab7f51d1e4ae249c68ea8ae8031344e66f474f'
setenv GIT_BRANCH                     "origin/${BRMAIN}"
setenv gitlabSourceRepoURL            'git@snpsgit.internal.synopsys.com:ddr-hbm/ddr-hbm-phy-automation-team.git'
setenv gitlabActionType               'PUSH'
setenv gitlabBranch                   $BRMAIN
setenv gitlabSourceBranch             $BRMAIN 
setenv gitlabTargetBranch             $BRMAIN
setenv gitlabMergedByUser             'ljames'
setenv gitlabUserName                 'James Laderoute'
setenv gitlabUserEmail                'ljames@synopsys.com'
setenv gitlabMergeRequestLastCommit   'e8a9868166fa75f5279cbc60fa844147151a4bd6'
setenv BUILD_NUMBER                   '158'
setenv BUILD_CAUSE                    'SCMTRIGGER'

cd $WORKSPACE

$WORKSPACE/admin/build_via_jenkins.csh

echo "return status is '$status'"


