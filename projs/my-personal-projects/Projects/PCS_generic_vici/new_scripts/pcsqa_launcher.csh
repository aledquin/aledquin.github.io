#!/bin/tcsh

set LOC_DIR = "/slowfs/dcopt105/alvaro/GitLab/PCS_generic_vici"
set PCSQA_WORK_DIR  = "/slowfs/dcopt103/alvaro/sgscratch/pcsqa"
setenv PCSQA_WORK_DIR "/slowfs/dcopt103/alvaro/sgscratch/pcsqa"

set data_file =  "$LOC_DIR/new_scripts/input_data.csh"
source "$data_file"

set PCS_CCS_INFO = "${PRODUCT_LINE} ${PCS_NAME} ${PCS_REL_VERSION} ${CCS_NAME} ${CCS_REL_VERSION}"

set MOD_QA = "msip_lynx_pcsqa"
set TOOL = "pcsqa"

set CCS_PATH = "${PRODUCT_LINE}/${PCS_NAME}/${PCS_REL_VERSION}"

module load ${MOD_QA}

set PROJ_FILE = "pcsqa_file-1"
rm -f ${PROJ_FILE}
touch ${PROJ_FILE}

echo "${CCS_PATH}" >> ${PROJ_FILE}

${TOOL} ${PROJ_FILE}