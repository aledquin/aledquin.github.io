#!/bin/csh -f

         ###############################################
         # Setup env variables that you can immediately#
         # Clean the data you have to get useful data..#
         # Set next steps..............................#
         # Take action.................................#
         # Make a new script to use data results.......#
         ###############################################



#START HERE

# STEP 0: CHECK INPUTS

set WHOIAM = `whoami`

set ENV_FLOW = ""
source -e -v ${ENV_FLOW}


# STEP 1: 

set PRODUCT_LINE = "$1"
set PROJECT_CAD_NAME = "$2"
set REL_VERSION = "$3"
set STAR_ID = "$4"

set CCS_INFO = "${PRODUCT_LINE} ${PROJECT_CAD_NAME} ${REL_VERSION}"

set MOD_SHELL = "msip_shell_pcs_manager"
set TOOL_MIGRATION = "msip_pcs_ude3_migrateCadSetup"

module load ${MOD_SHELL}

yes `cat /slowfs/sgscratch/${WHOIAM}/pcsqa/P1MS3.t` | ${TOOL_MIGRATION} ${CCS_INFO} \
		  -star ${STAR_ID} \
		  -submit

echo "Go to http://vici/site/index"
echo " This part is manual work."
echo " "
echo "If you want to stop use Ctrl+C" 
echo "Are you ready for the next step? Press Enter"
set USER_ALLOW = $<

# STEP 2: PCSQA

set PCSQA_ROOT = "/slowfs/sgscratch/${WHOIAM}/pcsqa"
cd ${PCSQA_ROOT}

set MOD_QA = "msip_lynx_pcsqa"
set TOOL_QA = "pcsqa"

set CCS_PATH = "${PRODUCT_LINE}/${PROJECT_CAD_NAME}/${REL_VERSION}"

set PROJ_FILE = "pcsqa_file-1"


module load ${MOD_QA}

rm -f ${PROJ_FILE}
touch ${PROJ_FILE}
echo "${CCS_PATH}" >> ${PROJ_FILE}

${TOOL_QA} ${PROJ_FILE} -site us01




# STEP 3: WAIVER

set CCS_DASH = "${PRODUCT_LINE}-${PROJECT_CAD_NAME}-${REL_VERSION}"
set EVALUATE_STATUS_ROOT = "${PCSQA_ROOT}/builds/${CCS_DASH}/qa_step/evaluate_status"
set PCSQA_STATUS = "${EVALUATE_STATUS_ROOT}/work/.PCSQA_STATUS"

set MESSAGE_beta = ";WAIVE\;${STAR_ID}\;KEEP"
echo "$MESSAGE_beta"
gvim ${PCSQA_STATUS}


echo "Please open it in P4V or sync and submit. "
echo "//wwcad/msip/projects/${CCS_PATH}/pcs/cad/.PCSQA_STATUS"
echo "If you want to stop use Ctrl+C"
echo "Are you ready for the next step? Press Enter"
echo "We will repeat the previous step of PCSQA"
set USER_ALLOW = $<

${TOOL_QA} ${PROJ_FILE} -site us01




# STEP 4: DEFINE RESULTS TO GET - TAKE ACTION

# STEP 5: GET RESULTS

# STEP 6: GENERATE REPORTS

# END HERE
