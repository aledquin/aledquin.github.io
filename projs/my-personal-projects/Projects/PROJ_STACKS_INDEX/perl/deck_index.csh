#!/bin/csh -f


if ("$1" == "") then
    echo "$0 [opt -u unlocked] <PROJECT_TECH_NAME_VOLTAGE_METAL_SLACK>"
    exit 1
else if ("$1" == "-u") then
    set PJT_V_MS = $2
    set DECK_PATH = `find /slowfs/dcopt105/alvaro/GitLab/PROJ_STACKS_INDEX/projects/ -name \*.txt | xargs grep $PJT_V_MS | cut -d' ' -f2 | sort -r | uniq`
    echo $PJT_V_MS $DECK_PATH
else if ("$2" == "-u") then
set PJT_V_MS = $1
    set DECK_PATH = `find /slowfs/dcopt105/alvaro/GitLab/PROJ_STACKS_INDEX/projects/ -name \*.txt | xargs grep $PJT_V_MS | cut -d' ' -f2 | sort -r | uniq`
    echo $PJT_V_MS $DECK_PATH
else
    set PJT_V_MS = $1
    set DECK_PATH = `find /slowfs/dcopt105/alvaro/GitLab/PROJ_STACKS_INDEX/projects/ -name \*.txt | xargs grep $PJT_V_MS | cut -d' ' -f2 | sort -r | uniq`
    echo $PJT_V_MS $DECK_PATH[1]
endif




