#!/bin/tcsh

#+
# Purpose:
#   To perform a "build" of your tool.
#
# Details:
#   This script gets invoked by a Jenkins Project Build.
#   The Jenkins Build is triggered via GitLab when a push or merge-request happens.
#   
# Author:
#   James Laderoute (ljames)
#
# Example Of How To Run:
#   build_via_jenkins.csh 
#
# Required Location:
#   This script needs to reside in the GitLab /admin folder.  The Jenkins build
#   script is expected to look for it there.
#
# Required Env Vars:
#   The following environment variables are expected to be defined by the 
#   parent process. This script relies on these to work as expected. The 
#   Jenkins server where this will run will set these up for you. Some of
#   the other required env vars will be setup by the GitLab plugin installed
#   on the Jenkins server.
#
#   ENV VAR NAME            EXAMPLE VALUE
#   -------------------------------------------------------------------------
#   WORKSPACE               /localdev/web/jenkins/war/workspace/ljames/ddr-hbm-phy-automation-team_freestyle
#   WORKSPACE_TMP           ${WORKSPACE}@tmp
#   BUILD_NUMBER            135  (Jenkins build number)
#   PWD                     same as WORKSPACE
#   GIT_COMMIT              32047b...aa89 (the SHA1 hash commit id)
#   GIT_PREVIOUS_COMMIT     32047b...aa89 (the SHA1 hash previous commit id)
#   GIT_PREVIOUS_SUCCESSFUL_COMMIT
#                           42f520...c7fe (the SHA1 hash commit id)
#   GIT_BRANCH              origin/master
#   gitlabSourceRepoURL     git@snpsgit.internal.synopsys.com:ddr-hbm/ddr-hbm-phy-automation-team.git 
#   gitlabActionType        MERGE|PUSH
#   gitlabSourceBranch      ljames-master-patch-23884
#   gitlabTargetBranch      master
#   gitlabMergedByUser      ljames
#   gitlabUserName          ljames
#   gitlabUserEmail         ljames@synopsys.com
#   gitlabMergeRequestLastCommit
#                           ae5821...1046 (the SHA1 hash commit id)
#
# Potentially Useful Env Vars:
#
#   ENV VAR NAME            EXAMPLE VALUE
#   -------------------------------------------------------------------------
#   gitlabSourceRepoName    DDR-HBM PHY Automation Team
#   gitlabMergeRequestId    8575
#   HUDSON_HOME             /localdev/web/jenkins/war
#   JOB_BASE_NAME           ddr-hbm-phy-automation-team_freestyle
#   udescratch              /remote/scratch
#   MAIL                    /var/spool/mail/sgjenkins
#   USER                    sgjenkins
#   LOGNAME                 sgjenkins
#   HOME                    /u/sgjenkins
#   GROUP                   synopsys
#   gitlabTargetNamespace   ddr-hbm
#   gitlabMergeRequestIid   255
#   ROOT_BUILD_CAUSE        SCMTRIGGER
#   udeproj                 /remote/proj
#   MSIP_SHELL_UDE_DEF      /remote/cad-rep/msip/tools/Shelltools/ude/ude/2022.06
#   gitlabMergeRequestState merged
#   MSIP_ROOT               /remote/cad-rep/msip
#   MSIP_SCRIPTS_ROOT       /remote/cad-rep/msip/scripts
#   MSIP_PROJ_ROOT          /remote/proj
#   PERL5LIB                /remote/cad-rep/...:
#
# Updates:
# 001   ljames  7/22/2022
#       Created this script.
#
#-

# ignore all errors and keep on going
onintr -

MAIN:
    # List of supported tools. Tool:ConductorName 
    set knownTools = ('ddr-ckt-rel,ljames,alvaro,juliano' \
                      'ddr-utils,alvaro,ljames,juliano' \
                      'ddr-utils-in08,seguinn,dikshant,juliano' \
                      'ddr-utils-lay,alvaro,seguinn,juliano' \
                      'ddr-utils-timing,dikshant,ljames,juliano' \
                      'notify,juliano' \
                      'ibis,alvaro,seguinn,juliano' \
                      'sharedlib,ljames,alvaro,dikshant,seguinn,juliano' \
                      )
    set envNames = ('BUILD_NUMBER' 'BUILD_CAUSE' 'WORKSPACE' \
        'WORKSPACE_TMP' 'GIT_COMMIT' 'GIT_PREVIOUS_COMMIT' \
        'GIT_PREVIOUS_SUCCESSFUL_COMMIT' 'gitlabActionType' 'gitlabBefore' \
        'gitlabAfter' 'gitlabBranch' 'gitlabSourceBranch' \
        'gitlabTargetBranch' 'gitlabUserName' 'gitlabUserEmail' \
        'gitlabMergeRequestLastCommit' )

    set email_users = ( "ljames" "juliano" )

    # Echo some of the expected env variables
    # ( for debugging mostly )
    echo "Environment Variables:"
    echo "----------------------"
    foreach varname ( $envNames )
        set b='$'$varname
        set value=`eval echo $b`
        if ( $status == 0 ) then
            echo "    $varname $value"
        endif
    end

    # We would like to use git version 2.8.3 for our git ops. See if
    # that version currently exists. If it does then setup an alias for it.
    if ( -e /depot/git-2.8.3/bin/git ) then
        alias git /depot/git-2.8.3/bin/git
    endif

    # Which Tool(s) need their Makefile invoked?

    # filesModifiedList:
    # 	admin/build_via_jenkins.csh
    # 	admin/test__build_via_jenkins.csh

    set build_failed = 0
    set tried_build = 0
    set filesModifiedList=()
    set debug_to_log=()

    if ( $?gitlabAfter && $?gitlabBefore ) then
        if ( "$gitlabBefore" != "0000000000000000000000000000000000000000") then
            set debug_to_log = ( $debug_to_log "git#diff#--name-only#gitlabBefore:$gitlabBefore#gitlabAfter:$gitlabAfter")
            echo "git diff --name-only $gitlabBefore $gitlabAfter"
            set filesModifiedList = `git diff --name-only $gitlabBefore $gitlabAfter`
            echo "filesModifiedList: $filesModifiedList"
        else
            set debug_to_log = ( $debug_to_log "git#show#--name-only#--name-only#gitlabAfter:$gitlabAfter")
            echo "git show --name-only --format='' $gitlabAfter"
            set filesModifiedList = `git show --name-only --format="" $gitlabAfter`
            echo "filesModifiedList: $filesModifiedList"
        endif
    else 
        if ( "$gitlabActionType" == "MERGE") then
            if ( $?gitlabMergeRequestLastCommit &&  $?GIT_COMMIT  ) then
                set debug_to_log = ( $debug_to_log "git#diff#--name-only#gitlabMergeRequestLastCommit:$gitlabMergeRequestLastCommit#GIT_COMMIT:$GIT_COMMIT")
                echo "git diff --name-only $gitlabMergeRequestLastCommit $GIT_COMMIT"
                set filesModifiedList = `git diff --name-only $gitlabMergeRequestLastCommit  $GIT_COMMIT`
                echo "filesModifiedList: $filesModifiedList"
            endif
        endif
    endif

    set buildStatusList=()

    # Setting this env var prevents the usage stats call from being invoked
    setenv DA_RUNNING_UNIT_TESTS 1

    foreach fpath ($filesModifiedList)
        # if $fpath does not exist as a file (which could be in case of a git
        # command returning text other than filenames. Just skip it if it's
        # not a real file.
        if ( -e $fpath ) then
            set dirpath = `/bin/dirname $fpath`
            set tool    = `echo $dirpath | awk -F/ '{print $1}'`
            set fname   = `/bin/basename $fpath`
            set ftype   = `file $fpath`
            set build   = 0
            set build_status = 0
            set printStatus = "?"

            # does this file reside in one of our GITLAB tools that we release
            # to Shelltools ?
            foreach knownToolUsers ( $knownTools )
                # knownToolUsers =>  "toolname,user1,user2"
                #echo "knownToolUsers=>$knownToolUsers"
                set alist = `echo $knownToolUsers | sed 's/,/ /g'`
                #echo "alist=>$alist"
                set count = 1
                set knownTool = "unknown"
                set conductors = ()
                foreach i ( $alist )
                    if ( $count == 1 ) then
                        set knownTool = $alist[$count]
    @                   count = $count + 1
                    else
                        set fullist = "$conductors $email_users"
                        set username = "$alist[$count]"
                        set isfound = `echo "$fullist" | grep -i "$username"`
                        set gstatus = $status
                        if ( $gstatus != 0) then
                            set conductors = ( $conductors $username )
                        endif
    @                   count = $count + 1
                    endif
                end

                if ( $knownTool == $tool ) then
                    set build = 1
                    set email_users = ( $email_users $conductors )
                endif
            end

            if ( $build == 1 ) then
               echo "\tTool:'$tool' path='$dirpath' file='$fname' fileType='$ftype'"
               @ tried_build = $tried_build + 1
               $WORKSPACE/admin/check_code.csh -short $fpath
               set build_status = $status
               set printStatus = "FAILED"
               if ( $build_status == 0) then
                   set printStatus = "PASSED"
               endif
            else
                set printStatus = "NOT_BUILDABLE"
            endif

            set buildStatusList = ( $buildStatusList "${printStatus}:${fpath}")

            if ( $build_status != 0 ) then
                set build_failed = 1
            endif
        endif
    end

    # send email to the person who did the PUSH/MERGE request; let them
    # know the status of the build. And let ljames know.

    set status_text = "PASSED"
    if ( $build_failed == 1 ) then
        set status_text = "FAILED"
    endif

    ##------------------------------------------------------------------
    ## Computing the string for the email field 'Subject'
    ## <STATUS> : GitLab push <src> <target> : <user>
    ## <STATUS> : GitLab MergeRequest ID<#> : <src> <target> : <user> 
    ##------------------------------------------------------------------
    set email_subject = "$status_text : GitLab : $gitlabActionType $gitlabSourceBranch->$gitlabTargetBranch : $gitlabUserName "

    if ( -e $WORKSPACE_TMP/log_of_build ) then
        rm -f $WORKSPACE_TMP/log_of_build
    endif
    touch $WORKSPACE_TMP/log_of_build
    echo "                                     "         >> $WORKSPACE_TMP/log_of_build
    echo "Status:$status_text"                           >> $WORKSPACE_TMP/log_of_build
    echo "Action:$gitlabActionType"                      >> $WORKSPACE_TMP/log_of_build
    echo "User  :$gitlabUserName"                        >> $WORKSPACE_TMP/log_of_build
    if ( $?gitlabUserEmail ) then
        echo "Email :$gitlabUserEmail"                   >> $WORKSPACE_TMP/log_of_build
    endif
    echo "GitLab:$gitlabSourceRepoURL"                   >> $WORKSPACE_TMP/log_of_build
    echo "Commit:$GIT_COMMIT"                            >> $WORKSPACE_TMP/log_of_build
    echo "SrcBranch->TargetBranch: $gitlabSourceBranch->$gitlabTargetBranch" >> $WORKSPACE_TMP/log_of_build
    echo "                                     "         >> $WORKSPACE_TMP/log_of_build
    #    echo "+------------------------------------"         >> $WORKSPACE_TMP/log_of_build
    #    echo "| File List for BUILD #$BUILD_NUMBER"           >> $WORKSPACE_TMP/log_of_build
    #    echo "+------------------------------------"         >> $WORKSPACE_TMP/log_of_build
    #    foreach fpath ($filesModifiedList)
    #        echo "\t$fpath"                                  >> $WORKSPACE_TMP/log_of_build
    #    end
    echo "+--------------------------------------------" >> $WORKSPACE_TMP/log_of_build
    echo "| Build Status per File for BUILD #$BUILD_NUMBER" >> $WORKSPACE_TMP/log_of_build
    echo "+--------------------------------------------" >> $WORKSPACE_TMP/log_of_build
    foreach buildStat ($buildStatusList)
        echo "\t$buildStat"                              >> $WORKSPACE_TMP/log_of_build
    end
    echo "                                     "         >> $WORKSPACE_TMP/log_of_build
    echo "--------------NOTE-------------------"         >> $WORKSPACE_TMP/log_of_build
    echo "                                     "         >> $WORKSPACE_TMP/log_of_build
    echo "For the scripts that failed, you can see details by running" >> $WORKSPACE_TMP/log_of_build
    echo "                                     "         >> $WORKSPACE_TMP/log_of_build
    echo "    ~/GitLab/ddr*/admin/check_code.csh FILE "  >> $WORKSPACE_TMP/log_of_build
    echo "                                     "         >> $WORKSPACE_TMP/log_of_build
    echo "---------- DEBUG INFO SECTION ------ "         >> $WORKSPACE_TMP/log_of_build       
    echo "                                     "         >> $WORKSPACE_TMP/log_of_build
    foreach debugStatement ( $debug_to_log )                                
        set aline = `echo $debugStatement | sed 's/#/ /g'` 
        echo "    $aline"                                >> $WORKSPACE_TMP/log_of_build
    end

    if ( $?gitlabUserEmail ) then
        set email_account = $gitlabUserEmail
    else
        set email_account = "${gitlabUserName}@synopsys.com"
    endif

    foreach email_user ( $email_users )
        set email_account = "$email_account ${email_user}@synopsys.com"
    end

    echo "-D- tried_build is '$tried_build'"
    echo "-D- email_account is '$email_account'"

    if ( $tried_build > 0 ) then
        /bin/mailx -s"$email_subject" $email_account < $WORKSPACE_TMP/log_of_build
    endif
     
    if ( $build_failed == 1 ) then
        exit(-1)  # return fail
    endif
    exit(0)  # return success

