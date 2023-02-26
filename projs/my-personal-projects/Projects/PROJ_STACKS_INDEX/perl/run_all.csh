#!/bin/csh -f 


set LOC_DIR = "/slowfs/dcopt105/alvaro/GitLab/PROJ_STACKS_INDEX"

set LOG_INFO = "${LOC_DIR}/LOG_INFO"
set TOOL = "${LOC_DIR}/csh/index_of_tech_slack_encrypt_position.csh"

set PJCT_LIST = "${LOC_DIR}/data_set/project_list.txt"

if (! -d $LOG_INFO ) then
    mkdir $LOG_INFO
endif 

foreach i (`cat $PJCT_LIST`)
    touch $LOG_INFO/$i
    $TOOL $i >& "${LOG_INFO}/${i}"
    echo "$i : Done"
end

