#!/bin/csh -f

         ###############################################
         # Setup env variables that you can immediately#
         # Clean the data you have to get useful data..#
         # Set next steps..............................#
         # Take action.................................#
         # Make a new script to use data results.......#
         ###############################################



# Get full_path to the encrypt file in IcvRunDRC 
# What is in the env file of certain metal slack 
# what we can find from the name given to add in 
# the Map tech file.

if ( "$1" == "" ) then
    echo "Add an tech file as argument" 
    exit 0
endif


# START HERE
set INDEX_DIRECTORY = "/slowfs/dcopt105/alvaro/GitLab/PROJ_STACKS_INDEX"
if (! -d ${INDEX_DIRECTORY}) then
    mkdir ${INDEX_DIRECTORY}
endif

set MSIP_PROJ_ROOT    = "/remote/cad-rep/projects" # Root Directory
set CAD_PROJ_ENV_NAME = "project.env"

set MSIP_CAD_PROJ_TECH = "$1" # CAD Project
    
set MSIP_CAD_PROJ_ROOT_GROUP = `find ${MSIP_PROJ_ROOT} -maxdepth 2 -mindepth 2 -name \*-${MSIP_CAD_PROJ_TECH}\[0-9-\]\*`

if (! -d ${INDEX_DIRECTORY}/${MSIP_CAD_PROJ_TECH}) then
    mkdir ${INDEX_DIRECTORY}/${MSIP_CAD_PROJ_TECH}
endif
    
foreach MSIP_CAD_PROJ_ROOT ($MSIP_CAD_PROJ_ROOT_GROUP)
    
    set MSIP_CAD_PROJ_NAME = `basename ${MSIP_CAD_PROJ_ROOT}`
    
    set MSIP_CAD_REL_ENV_NAME = `ls ${MSIP_CAD_PROJ_ROOT}/ -t1 | head -n 1`
    
    if ( "${MSIP_CAD_REL_ENV_NAME}" !~ "rel*") then
	continue
    endif

    set CAD_PROJ_ENV_PATH = "${MSIP_CAD_PROJ_ROOT}/${MSIP_CAD_REL_ENV_NAME}/cad/${CAD_PROJ_ENV_NAME}"
    
    # Get all Metal Slacks from the Project.env result for the specific project selected
    set TOOL = "/slowfs/dcopt105/alvaro/GitLab/scripts/index_of_tech_slack_encrypt_position.function.csh"
    set INDEX_PROJ = "${MSIP_CAD_PROJ_NAME}.txt"
    
    ${TOOL} ${CAD_PROJ_ENV_PATH} "${INDEX_DIRECTORY}/${MSIP_CAD_PROJ_TECH}/${INDEX_PROJ}"
 
end

# END HERE
