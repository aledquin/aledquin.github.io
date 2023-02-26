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


# GOAL : CREATE OUTLINE WITH NAME AND DECK
# REQ : project.env location CAD_PROJ_ENV_PATH
# DEFAULT : metal env file name, pcs projects root
# ISSUE : CHOOSING A METAL SLACK `ls | echo [0-9]*`
# START HERE

echo `basename "$2"`


# echo "STEP 0: Check input"
if ( "$1" == "") then 
	echo $0 ' <project.env path> <output file (optional)>'
	exit 1
endif


# echo "STEP 1: SETUP"

set CAD_PROJ_ENV_PATH = $1

if ( "$2" == "") then 
set OUTPUT_LIB = "/slowfs/dcopt105/alvaro/GitLab/scripts/index_metal_encrypt.txt"
else 
set OUTPUT_LIB = $2
endif

rm -f ${OUTPUT_LIB}
touch ${OUTPUT_LIB}

set LOG_ROOT = `dirname ${OUTPUT_LIB}`
set OUT_NAME = `basename ${OUTPUT_LIB} | sed "s/\.txt//"`

set LOG_FILE = "${LOG_ROOT}/001-INFO.LOG"
set ERROR_LOG_FILE = "${LOG_ROOT}/002-ERROR.LOG"  

set PCS_PROJ_ROOT 	 = "/remote/cad-rep/proj"
set METAL_SLACK_ENV_NAME = "env.tcl"

set DECK_VAR_NAME = "IcvRunDRC"


# echo "STEP 2: Getting Project information"

# Get first lines and from project.env to get the third element, separated by spaces.
set MSIP_CAD_PROJ_NAME = `cat ${CAD_PROJ_ENV_PATH} | head -1 | cut -d' ' -f3`
set MSIP_CAD_REL_NAME =  `cat ${CAD_PROJ_ENV_PATH} | head -2 | tail -1 | cut -d' ' -f3` 

# Get values separating the MSIP_CAD_PROJ_NAME by dashes (-) 
set MSIP_CAD_PROJ_TECH = `echo ${MSIP_CAD_PROJ_NAME} | cut -d'-' -f2`
set MSIP_CAD_PROJ_V = `echo ${MSIP_CAD_PROJ_NAME} | cut -d'-' -f3 | sed "s/\.//" | sed "s/v//"`

echo "INFO: ${MSIP_CAD_PROJ_TECH} ${MSIP_CAD_PROJ_V} ${MSIP_CAD_REL_NAME}"

if ( "${MSIP_CAD_REL_NAME}" !~ "rel*") then
    rm -f ${OUTPUT_LIB}
    echo "INFO: SKIPPED. NOT RELEASE VESION."
    echo ""
    exit
endif


# echo "STEP 3: Getting Metal slacks names"

set METAL_SLACK_GROUP = `cd ${PCS_PROJ_ROOT}/${MSIP_CAD_PROJ_NAME}/${MSIP_CAD_REL_NAME}/cad;\
                         ls | echo [0-9]*; cd -`


#echo "STEP 4: Appending data"

foreach METAL_SLACK_NAME ( $METAL_SLACK_GROUP )
    
    set METAL_SLACK_ROOT = "${PCS_PROJ_ROOT}/${MSIP_CAD_PROJ_NAME}/${MSIP_CAD_REL_NAME}/cad/${METAL_SLACK_NAME}"
    set METAL_SLACK_ENV_PATH = "${METAL_SLACK_ROOT}/${METAL_SLACK_ENV_NAME}"
    
    # Get var name 
    set PROJ_TECH_METAL_SLACK_NAME = "${MSIP_CAD_PROJ_TECH}-${MSIP_CAD_PROJ_V}_${METAL_SLACK_NAME}" 

    if (! -f ${METAL_SLACK_ENV_PATH}) then
        echo "ERROR: NOT FOUND: $METAL_SLACK_ENV_PATH"
        if (! -f ${ERROR_LOG_FILE}) then 
            touch ${ERROR_LOG_FILE}
            echo "${MSIP_CAD_PROJ_NAME} : ${CAD_PROJ_ENV_PATH}" >> ${ERROR_LOG_FILE}
        endif
        echo "${PROJ_TECH_METAL_SLACK_NAME} : ${METAL_SLACK_ENV_PATH}" >> ${ERROR_LOG_FILE}
        continue
    endif

    # Open env.tcl METAL_SLACK_ENV_PATH
    # Get value of IcvRunDRC without quotes
    set ICVRUNDRC_DECK = `cat ${METAL_SLACK_ENV_PATH} | grep " ${DECK_VAR_NAME} " | cut -d'"' -f2`
    if ( "${ICVRUNDRC_DECK}" == "" || "${ICVRUNDRC_DECK}" == "NA") then 
        echo "ERROR: IcvRunDRC not defined."
        echo "${PROJ_TECH_METAL_SLACK_NAME} : ${METAL_SLACK_ENV_PATH}"
        if (! -f ${ERROR_LOG_FILE}) then  
            echo "${MSIP_CAD_PROJ_NAME} : ${CAD_PROJ_ENV_PATH}" > ${ERROR_LOG_FILE} 
        endif 
        echo "${PROJ_TECH_METAL_SLACK_NAME} : ${METAL_SLACK_ENV_PATH}" >> ${ERROR_LOG_FILE} 
        continue 
    endif  
    # Make line
    set OUT_LINE = "${PROJ_TECH_METAL_SLACK_NAME}      ${ICVRUNDRC_DECK}"
     
    # export and save somewhere
    echo ${OUT_LINE} >> ${OUTPUT_LIB}
    
    set LOG_INFO = "/slowfs/dcopt105/alvaro/GitLab/PROJ_STACKS_INDEX/LOG_INFO"
    touch "${LOG_INFO}/100-ACUM.LOG"
    echo "${PROJ_TECH_METAL_SLACK_NAME}:${MSIP_CAD_REL_NAME}:${ICVRUNDRC_DECK}" >> "${LOG_INFO}/100-ACUM.LOG"


end


# END HERE

# REPORTS
#
touch ${LOG_FILE}
echo "${MSIP_CAD_PROJ_TECH} : ${MSIP_CAD_REL_NAME} : $MSIP_CAD_PROJ_V : ${OUT_NAME}" >> ${LOG_FILE}
sort ${LOG_FILE} --reverse --output=${LOG_FILE}
sort "${LOG_INFO}/100-ACUM.LOG" --reverse --output="${LOG_INFO}/100-ACUM.LOG" | uniq
echo "INFO: DONE"
echo ""


