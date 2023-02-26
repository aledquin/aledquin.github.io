#!/bin/tcsh -f

         ###############################################
         # Setup env variables that you can immediately#
         # Clean the data you have to get useful data..#
         # Set next steps..............................#
         # Take action.................................#
         # Make a new script to use data results.......#
         ###############################################



#START HERE

# STEP 0: CHECK INPUTS
source /usr/share/Modules/init/tcsh
set WHOIAM = `whoami`

# set ENV_FLOW = ""
#source -e -v ${ENV_FLOW}

set PCSQA_WORK_DIR = "/slowfs/dcopt103/alvaro/sgscratch/${WHOIAM}"
setenv PCSQA_WORK_DIR "/slowfs/dcopt103/alvaro/sgscratch/${WHOIAM}"

mkdir ${PCSQA_WORK_DIR}
# STEP 1: 

set PRODUCT_LINE = "$1"
set PCS_NAME = "$2"
set PCS_REL_VERSION = "$3"
set CCS_NAME = "$4"
set CCS_REL_VERSION = "$5"
set STAR_ID = "$6"

set PCS_CCS_INFO = "${PRODUCT_LINE} ${PCS_NAME} ${PCS_REL_VERSION} ${CCS_NAME} ${CCS_REL_VERSION}"
# OTk3NTMyMDc0MDA5OrWJqdao7+qlsO9eUACNxR2iSm/6
set MOD_SHELL = "msip_shell_pcs_manager"
set TOOL_MIGRATION = "msip_pcs_ude3_migrateCadSetup"

module load ${MOD_SHELL}

set P1MS3 = "/slowfs/dcopt105/alvaro/GitLab/PCS_generic_vici/env/P1MS3.t"
echo `cat $P1MS3` | ${TOOL_MIGRATION} ${PCS_CCS_INFO} -star ${STAR_ID} -submit

echo "Go to http://vici/site/index"
echo " This part is manual work."


# STEP 2: PCSQA

set PCSQA_ROOT = "/slowfs/dcopt103/alvaro/sgscratch/${WHOIAM}"
cd ${PCSQA_ROOT}

set MOD_QA = "msip_lynx_pcsqa"
set TOOL_QA = "pcsqa"

set CCS_PATH = "${PRODUCT_LINE}/${PCS_NAME}/${PCS_REL_VERSION}"

set PROJ_FILE = "${PCSQA_ROOT}/pcsqa_file-1"

module load ${MOD_QA}

rm -f ${PROJ_FILE}
touch ${PROJ_FILE}
echo "${CCS_PATH}" >> ${PROJ_FILE}

${TOOL_QA} ${PROJ_FILE}
echo "${TOOL_QA} ${PROJ_FILE}"

# STEP 3: WAIVER

set CCS_DASH = "${PRODUCT_LINE}-${PCS_NAME}-${PCS_REL_VERSION}"
set EVALUATE_STATUS_ROOT = "/remote/cad-rep/projects/${CCS_PATH}/cad"
set PCSQA_STATUS = "${EVALUATE_STATUS_ROOT}/.PCSQA_STATUS"

set PCSQA_STATUS_VALUE = `cat ${PCSQA_STATUS} | head -1 | cut -d':' -f2`

if (${PCSQA_STATUS_VALUE} != "PASS" ) then  
    
    set MESSAGE_beta = ";WAIVE\;${STAR_ID}\;KEEP"
    echo "$MESSAGE_beta"
    gvim ${PCSQA_STATUS}
     
    echo "Please open it in P4V or sync and submit. "
    echo "${EVALUATE_STATUS_ROOT}/.PCSQA_STATUS"
    echo "//wwcad/msip/projects/${CCS_PATH}/pcs/cad/.PCSQA_STATUS"
    
    echo "${TOOL_QA} ${PROJ_FILE} -site us01" > ${PCSQA_ROOT}run_us01.csh
    echo "Use ${PCSQA_ROOT}run_us01.csh"
     
endif

# STEP 6: GENERATE REPORTS

set mail_path = "${PCSQA_ROOT}/mail.txt"
set table_file = "${PCSQA_ROOT}/table_file.html"
rm -f $table_file
touch $table_file

set subject = "PCS: Updating ${PCS_NAME} ${PCS_REL_VERSION} : ${PCSQA_STATUS_VALUE}"
set from_user = ${WHOIAM}
set to_users = "${WHOIAM}@synopsys.com,alvaro@synopsys.com"

rm -f ${mail_path} 
touch ${mail_path}
echo "Subject: $subject" >> ${mail_path}
echo "FROM: $from_user"  >> ${mail_path}
echo "To: $to_users"     >> ${mail_path}
echo "Content-Type: text/html; charset=us-ascii" >> ${mail_path}
echo >> ${mail_path}

echo '<html>' >> $table_file
echo '<table style="height: 186px; width: 463px;"> ' >> $table_file
echo '<thead> <tr style="height: 18px;"> <td style="height: 18px; width: 138.141px;">&nbsp;</td> <td style="height: 18px; width: 308.859px;">Description</td> </tr> </thead>' >> $table_file
echo '<tbody>' >> $table_file
echo '<tr style="height: 22px;"> <td style="height: 22px; width: 138.141px;"><strong>Product Line</strong></td> <td style="height: 22px; width: 308.859px;">'${PRODUCT_LINE}'</td> </tr>' >> $table_file
echo '<tr style="height: 22px;"> <td style="height: 22px; width: 138.141px;"><strong>PCS Name</strong></td> <td style="height: 22px; width: 308.859px;">'${PCS_NAME}'</td> </tr>' >> $table_file
echo '<tr style="height: 22px;"> <td style="height: 22px; width: 138.141px;"><strong>Release Version</strong></td> <td style="height: 22px; width: 308.859px;">'${PCS_REL_VERSION}'</td> </tr>' >> $table_file
echo '<tr style="height: 22px;"> <td style="height: 22px; width: 138.141px;"><strong>CCS Name</strong></td> <td style="height: 22px; width: 308.859px;">'${CCS_NAME}'</td> </tr>' >> $table_file
echo '<tr style="height: 36px;"> <td style="height: 36px; width: 138.141px;"><strong>CSS Release Version</strong></td> <td style="height: 36px; width: 308.859px;">'${CCS_REL_VERSION}'</td> </tr>' >> $table_file
echo '<tr style="height: 22px;"> <td style="height: 22px; width: 138.141px;"><strong>Jira STAR</strong></td> <td style="height: 22px; width: 308.859px;"><a title="'$STAR_ID'" href="https://jira.internal.synopsys.com/browse/'$STAR_ID'">'$STAR_ID'</a></td> </tr>' >> $table_file
echo '<tr style="height: 22px;"> <td style="width: 138.141px; height: 22px;"><strong>STATUS</strong></td> <td style="width: 308.859px; height: 22px;">'$PCSQA_STATUS_VALUE'</td> </tr>' >> $table_file
echo '</tbody> </table> </html>' >> $table_file

/usr/sbin/sendmail $to_users < ${mail_path}


# END HERE
