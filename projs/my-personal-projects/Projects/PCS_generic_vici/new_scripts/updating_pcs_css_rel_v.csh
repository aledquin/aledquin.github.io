#!/bin/tcsh

set LOC_DIR = "/slowfs/dcopt105/alvaro/GitLab/PCS_generic_vici"

set data_file =  "$LOC_DIR/new_scripts/input_data.csh"
source "$data_file"

set PCSQA_WORK_DIR = "/slowfs/dcopt103/alvaro/sgscratch/pcsqa"
setenv PCSQA_WORK_DIR "/slowfs/dcopt103/alvaro/sgscratch/pcsqa"

set PCS_CCS_INFO = "${PRODUCT_LINE} ${PCS_NAME} ${PCS_REL_VERSION} ${CCS_NAME} ${CCS_REL_VERSION}"

set MOD_SHELL = "msip_shell_pcs_manager"
set TOOL      = "msip_pcs_ude3_migrateCadSetup"

module load ${MOD_SHELL}

set P1MS3 = "/slowfs/dcopt105/alvaro/GitLab/PCS_generic_vici/env/P1MS3.t"
echo `cat $P1MS3`

${TOOL} ${PCS_CCS_INFO} -star ${STAR_ID} -submit

