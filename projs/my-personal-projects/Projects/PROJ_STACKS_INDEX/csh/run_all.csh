#!/bin/csh -f 

set LOG_INFO = "/slowfs/dcopt105/alvaro/GitLab/PROJ_STACKS_INDEX/LOG_INFO"
set TOOL = "/slowfs/dcopt105/alvaro/GitLab/PROJ_STACKS_INDEX/scripts/index_of_tech_slack_encrypt_position.csh"

set PJCT_LIST = "/slowfs/dcopt105/alvaro/GitLab/PROJ_STACKS_INDEX/scripts/project_list.txt"

if (! -d $LOG_INFO ) then
    mkdir $LOG_INFO
endif 

foreach i (`cat $PJCT_LIST`)
    touch $LOG_INFO/$i
    $TOOL $i >& "${LOG_INFO}/${i}"
    echo "$i : Done"
end

