#!/depot/Python/Python-3.8.0/bin/python
###############################################################################
#
# Author  : Haashim Shahzada
# Purpose : Generate PERC and EMIR files and upload corresponding PERC/EMIR files to depot
#
###############################################################################

import argparse
import atexit
# import logging
import os
import pathlib
import sys
import fnmatch
# import subprocess
# import inquirer
# from datetime import datetime
import re

# ----------------------------------
bindir = str(pathlib.Path(__file__).resolve().parent)
# Add path to sharedlib's Python Utilities directory.
sys.path.append(bindir + '/../lib/python/Util')
# ----------------------------------

from CommonHeader import NULL_VAL, MEDIUM, HIGH
from os.path import exists
from Messaging import eprint, fatal_error, iprint, hprint, dprint
from Messaging import create_logger, footer, header
from Misc import run_system_cmd, utils__script_usage_statistics, get_release_version
# from P4Utils import da_p4_add_to_changelist, da_p4_create_instance, da_p4_update_mapping
from P4Utils import da_p4_create_instance
import CommonHeader

__author__ = 'Maisha'
__version__ = get_release_version()

# Disable exiting when fatal_error is invoked
CommonHeader.fatal_error_NOEXIT = 1


def parse_args():

    # Always include -v, and -d
    parser = argparse.ArgumentParser(description='description here')
    parser.add_argument('-v', metavar='<#>', type=int, default=0,
                        help='verbosity')
    parser.add_argument('-d', metavar='<#>', type=int, default=0,
                        help='debug')

    # Add your custom arguments here
    # -------------------------------------
    parser.add_argument('-macro', required=True, help='specify the macro name. (required)')
    parser.add_argument('-p', required=True, help='specify the project string "product/project/release" (required)')
    parser.add_argument('--path', required=True, type=str, help='The Path of the files that you would like to upload')
    # path to the files that will be uploaded
    parser.add_argument('--type', required=True, nargs=1, choices=['EMIR', 'PERC'], help='Select which type of files are being uploaded')
    # the type of files being uploaded
    # -------------------------------------
    args = parser.parse_args()
    return args


def find(pattern, path):  # recursively searches the path for the files and returns an array of file names
    result = []
    for root, dirs, files in os.walk(path):
        for name in files:
            if fnmatch.fnmatch(name, pattern):
                result.append(os.path.join(root, name))
    return result


def main():

    file_path = args.path
    upload_type = args.type[0]

    family = ""
    project = ""
    macro = args.macro
    release = ""

    answer = re.findall(r"^([^\/]+)\/([^\/]+)\/([^\/]+)$", args.proj)
    dprint(MEDIUM, f"{answer}")
    if (len(answer) > 0):
        family = answer[0][0]
        project = answer[0][1]
        release = answer[0][2]
    else:
        fatal_error("Could not extract project string.")
    dprint(MEDIUM, f"{family} {project} {release} {macro}")

    if not os.path.exists(file_path):
        eprint("Path to file does not exist!")
        exit()

    file_results = []

    if upload_type == 'PERC':

        # finds log file for perc
        # log_file = find('*.log', file_path)[0]

        # with open(log_file) as f:
        # lines = f.readlines()
        # grabs project type, name, rel from log file
        # for line in lines:
        # if 'project_type' in line:
        # project_type = line.split(',')[1]
        # elif 'project_name' in line:
        # project_name = line.split(',')[1]
        # elif 'release_name' in line:
        # release_name = line.split(',')[1]

        # arrays that find file names
        verification_types = ['lvs', 'drc', 'erc', 'ant', 'perc_ldl', 'perc_p2p']
        CRD_categories = ['abutment', 'stdcell_ring', 'decap_boundary', 'array', 'ckt_hm']

        # depotPath =

        gdsResult = find('*gds.gz', file_path)  # finds all of the gds.gz files
        file_results += gdsResult  # adds it to the the array of files

        percResult = []

        for curr_type in verification_types:  # looks for every combination of file paths
            for curr_category in CRD_categories:

                file_name = curr_type + '_' + curr_category + '*'
                result = find(file_name, file_path)
                percResult += result

        file_results += percResult
        print(percResult)
        submit_to_p4(gdsResult, f"//depot/products/{family}/project/{project}/ckt/rel/perc/{release}/metal_stack/perc_HM/perc_wrapper")
        submit_to_p4(percResult, f"//depot/products/{family}/project/{project}/ckt/rel/crd_testcases/{release}/crd_testbench/view/test")

    elif upload_type == 'EMIR':

        analysis = ['acpc', 'she_iavg', 'irms', 'wdt']
        emirResult = []

        for curr_analysis in analysis:

            file_name = 'xa-*_' + curr_analysis + '.ascii_*'
            result = find(file_name, file_path)
            emirResult += result

        file_results += emirResult

        print(emirResult)
        submit_to_p4(emirResult, f"//depot/products/{family}/project/{project}/qms/rel/{release}/ckts")


def mapFiles(family, project, release, file_results):
    (out, err, ret) = run_system_cmd("p4 info | grep 'Client root:' | cut -d ' ' -f 3-", CommonHeader.VERBOSITY)
    for file in file_results:
        filename = re.findall(r"xa-\S+\W\w+", file)
        source_file = f"{out}/depot/products/{family}/project/{project}/qms/rel/{release}/ckts/emir/{filename[0]}"
        if exists(source_file):
            # remove -proj and add -rel
            # copyFiles = f"cp -f {file} {out}/depot/products/{family}/project/{project}/qms/rel/{release}/ckts/emir/{filename[0]}"
            run_system_cmd(f"p4 add -f  {source_file}", CommonHeader.VERBOSITY)
            dprint(HIGH, f"err: {err}")
        else:
            fatal_error("Please seed the required EMIR files and map them to your workspace before running the script", 1)
        hprint(out)


def submit_to_p4(file_results, depotPath):
    p4 = da_p4_create_instance()

    if (p4 is NULL_VAL):
        fatal_error("Could not create P4 connection. Exiting.")

    # now = datetime.now()
    # date = now.strftime("%d-%m-%Y-%H_%M_%S")

    p4.connect()
    # submit_command = f"p4 -c {p4.client} add -f \"\""

    for file in file_results:
        # file = re.sub("%", "%25", file)
        # file = re.sub("@", "at", file)
        # file = re.sub("#", "%23", file)
        eprint(f"{file}")
        # file = re.sub("*", "%2A", file)

    # questions = [
    #     inquirer.List(
    #         "answer",
    #         message="Do you want to submit all files in the default changelist?",
    #         choices=["No", "Yes"],
    #     ),
    # ]

    answer = input("Do you want to submit all files in the default changelist?")

    if (answer == "No"):
        hprint(
            f"Changelist will not be submitted. Files added to default changelist for client: {p4.client}")

    elif (answer == "Yes"):
        # Execute a submit
        # (out, err, ret) = run_system_cmd(submit_command, CommonHeader.VERBOSITY)
        # dprint(HIGH, f"err: '{err}'")
        # hprint(out)
        eprint("success!")


if __name__ == '__main__':

    args = parse_args()
    filename = os.path.basename(__file__) + '.log'
    logger = create_logger(filename)            # Create log file

    # Register exit function
    atexit.register(footer)

    CommonHeader.init(args, __author__, __version__)  # Initalise shared variables and run main

    utils__script_usage_statistics("file_renaming.py", "2022.12")
    header()
    main()
    iprint(f"Log file: {filename}")

# #######################
# Goal of script:
# - pick up all files under the naming convention
# - cycle through array and add to changelist
# - upload to corresponding emir/perc/icv folder in depot
# #######################
