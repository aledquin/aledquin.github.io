#!/bin/csh -fx

         ###############################################
         # Setup env variables that you can immediately#
         # Clean the data you have to get useful data..#
         # Set next steps..............................#
         # Take action.................................#
         # Make a new script to use data results.......#
         ###############################################



#START HERE

# STEP 0: CHECK INPUTS
source /usr/share/Modules/init/csh
set WHOIAM = `whoami`

#set ENV_FLOW = ""
#source -e -v ${ENV_FLOW}

set PCSQA_WORK_DIR = "/slowfs/dcopt103/alvaro/sgscratch"
setenv PCSQA_WORK_DIR "/slowfs/dcopt103/alvaro/sgscratch"

mkdir ${PCSQA_WORK_DIR}

set P1MS3 = `cat "/slowfs/dcopt105/alvaro/GitLab/alvaro/PCS_generic_vici/env/P1MS3.t"`

# STEP 1:
# msip_pcs_ude3_clonePCS <prodLine> <projName> <projRel> <SOURCE_PCS_CLONE NAME> <SOURCE_PCS_CLONE RELEASE> [ <-client
# userP4Client> <-star starNumber> ]]

set PRODUCT_LINE = "lpddr5x"
set OLD_PCS_NAME = "d930-lpddr5x-tsmc5ff12"
set OLD_PCS_RV = "rel0.80"
set NEW_PCS_NAME = "d930-lpddr5x-tsmc5ff12"
set NEW_PCS_RV = "rel0.90_tc"
set STAR_ID = "P10023532-44310"

set PCS_CCS_INFO = "${PRODUCT_LINE} ${NEW_PCS_NAME} ${NEW_PCS_RV} ${OLD_PCS_NAME} ${OLD_PCS_RV}"

set MOD_SHELL = "msip_shell_pcs_manager"
set TOOL_CLONE = "msip_pcs_ude3_clonePCS"

module load ${MOD_SHELL}
yes ${P1MS3} | ${TOOL_CLONE} ${PCS_CCS_INFO} -star ${STAR_ID} -submit

echo "Go to http://vici/site/index"
echo " This part is manual work."