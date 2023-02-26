# Colors
set     red="%{\033[1;31m%}"
set   green="%{\033[1;32m%}"
set  yellow="%{\033[1;33m%}"
set    blue="%{\033[1;34m%}"
set magenta="%{\033[1;35m%}"
set    cyan="%{\033[1;36m%}"
set   white="%{\033[1;37m%}"
set     end="%{\033[1m%}"
set     non="%{\033[0m%}"

set GT0MSG  = 0
set FULLMSG = 0

# Execute
set GIT_BRANCH_CMD = `sh -c 'git branch --no-color 2> /dev/null' | sed -e '/^[^*]/d' -e 's/* \(.*\)/(\1) /'`
set CURRDIR = `pwd`

# Check Level
if ($show_status > 1) then 
    set FULLMSG = 1
else if ($show_status > 0) then
    set GT0MSG = 1
else 
    if ($PREVDIR != $CURRDIR) set GT0MSG  = 1
    if ($GIT_CB != $GIT_BRANCH_CMD) set GT0MSG  = 1
endif

set PREVDIR = "$CURRDIR"
set GIT_CB  = "$GIT_BRANCH_CMD"

if (-f $HOME/.prompts-runner.$USER) then
    # Prompt Customization
    ## Use this if you want to customize the prompt
    ## Recommendation: Use MSGs and Display MSG as template :)
    source $HOME/.prompts-runner.$USER
else
    # MSGs
    set NMSG   = "${magenta}\| USER: %n \t\|\n"
    set MMSG   = "${magenta}\| HOST: %m \t\|\n"
    set P4MSG  = "${magenta}\| P4Client: $P4CLIENT \t\|\n"
    set DIRMSG = "${green}\[ ${red}%/ ${green}\] \n"
    set GITMSG = ""
    if ($GIT_BRANCH_CMD != "") set GITMSG = "${green}$GIT_BRANCH_CMD\n"
    set SMBOL  = "${red}\⌲ ${non} "

    # Display MSG
    set prompt = "$SMBOL"
    if ($FULLMSG) then
        set prompt = "$NMSG$MMSG$P4MSG$DIRMSG$GITMSG$SMBOL"
    else if ($GT0MSG) then 
        set prompt = "$DIRMSG$GITMSG$SMBOL"
    endif
endif

# Reset
if ($show_status > 0) then
    setenv show_status 0 
endif
