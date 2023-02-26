 
setenv HELPFILES     $HOME/bin/help
setenv USER_GIT_REPO $HOME/GitLab/ddr-hbm-phy-automation-team
setenv GITROOT       $HOME/GitLab/ddr-hbm-phy-automation-team
setenv SHELLTOOLS    $HOME/p4_ws/wwcad/msip/internal_tools/Shelltools
setenv DDR_CKT_REL   $HOME/GitLab/ddr-hbm-phy-automation-team/ddr-ckt-rel/dev/main
setenv SHAREDLIB     $HOME/GitLab/ddr-hbm-phy-automation-team/sharedlib/lib/Util


setenv USER_P4_REPO $HOME/p4_ws
setenv P4PORT "p4p-`/usr/local/bin/siteid`:1999"
setenv P4CLIENT msip_cd_$USER
setenv P4CONFIG .p4config-`/usr/local/bin/siteid`
setenv P4EDITOR gvim
setenv HIPRELYNX_WORK_DIR /u/$USER/lynx_workspace
set clientview = 1


setenv PSQL_ORG_DB /u/juliano/jenkins/notify/weekly/psql.orgdata.txt
setenv WARREN_ORG_DB /u/juliano/jenkins/notify/weekly/warren.org.txt

setenv TZ "EST5EDT"
# setenv TZ America/Toronto

subenv PATH .

extenv PATH /depot/local/bin 
extenv PATH $HOME/bin
extenv PATH $HOME/.local/bin

preenv PATH /remote/proj/alpha/y006-alpha-sddrphy-ss14lpp-18/verif/global_tools/perforce
preenv PATH $USER_GIT_REPO/admin

setenv TCLLIBPATH "/slowfs/dcopt103/alvaro/Gitlab/dd*/tcl/lib/Util"

# setenv PATH "/slowfs/dcopt103/alvaro/opt/ActivateTcl-8.6/bin:$PATH"


set host=`hostname`
set symlinks='chase'
set history=( 1000 "%h %W/%D/%Y %T %R\n" )


