#!/depot/Python/Python-3.8.0/bin/python
###############################################################################
#
# Name    : hspice.py
# Author  : Harsimrat Wadhawan
# Date    : 2022-04-12 12:50:04
# Purpose : Top level script. Run hspice encryption check and ic verify code checking at once.
#
# Modification History
#     000 Harsimrat Singh Wadhawan 2022-04-12 12:50:16
#         Created this script
#     001 Haashim Shahzada 2022-08-09 12:50:16
#         Creating meaningful hspice_check.log
#         All waiver comments are related to the same issue
#
###############################################################################

import argparse
import atexit
import glob
# from pickle import FALSE, TRUE
import inquirer
import os
import pathlib
import re
import sys
import subprocess
import json
from datetime import datetime

# ---------------------------------- #
bindir = str(pathlib.Path(__file__).resolve().parent)
sys.path.append(bindir + '/../lib/python/Util')
# ---------------------------------- #

# Add the noqa comment to ignore flake8 module at top of the script import
# errors

from CommonHeader import LOW, NULL_VAL, MEDIUM, HIGH  # noqa: E402
from Messaging import iprint, dprint, fatal_error, eprint, hprint  # noqa: E402
from Messaging import vhprint  # noqa: E402
from Messaging import create_logger, footer, header  # noqa: E402
from Misc import find_keys_missing_in_dict, run_system_cmd, get_release_version, read_legal_release, first_available_file  # noqa: E402
from P4Utils import da_p4_add_to_changelist, da_p4_create_instance  # noqa: E402
import CommonHeader  # noqa: E402

__author__ = 'wadhawan'
__version__ = get_release_version()


DEFAULT_SEVERITY_LOCATION = f"{bindir}/../resources/severities.json"


def parse_args():

    # Always include -v, and -d
    parser = argparse.ArgumentParser(description='Parse Arguments')
    parser.add_argument('-v', metavar='<#>', type=int, default=0,
                        help='specify verbosity value (positive integer)')
    parser.add_argument('-d', metavar='<#>', type=int, default=0,
                        help='specify debug value (positive integer)')

    # Add your custom arguments here
    # -------------------------------------
    parser.add_argument('-macro', required=True,
                        help='specify the macro name. (required)')
    parser.add_argument('-p', required=True,
                        help='specify the project spec "product/project/release" (required)')
    parser.add_argument('-depotPath', required=False,
                        help='specify the project location "product/project/release" (optional)')
    parser.add_argument('-p4', required=False,
                        help='Upload log results to P4 (optional)', action='store_true')
    parser.add_argument('-test', required=False,
                        help='Test the P4 submit commands', action='store_true')
    parser.add_argument('-severity', required=False,
                        default=DEFAULT_SEVERITY_LOCATION, help='Provide a custom severity configuration.')
    # -------------------------------------
    args = parser.parse_args()
    return args


def main():

    dprint(LOW, f"Debugger setting: {CommonHeader.DEBUG}")

    family = ""
    project = ""
    macro = args.macro
    release = ""

    answer = re.findall(r"^([^\/]+)\/([^\/]+)\/([^\/]+)$", args.p)
    dprint(MEDIUM, f"{answer}")
    if (len(answer) > 0):
        family = answer[0][0]
        project = answer[0][1]
        release = answer[0][2]
    else:
        fatal_error("Could not extract project string.")
    dprint(MEDIUM, f"{family} {project} {release} {macro}")

    legal_release = first_available_file([
        f"/remote/cad-rep/projects/{family}/{project}/{release}/design/legalRelease.yml",
        f"/remote/cad-rep/projects/{family}/{project}/{release}/design/legalRelease.txt",
    ])

    parsed_legal_release = read_legal_release(legal_release)
    release = parsed_legal_release['rel']
    # Set the depot path for the hspice folder
    depotPath = f"//depot/products/{family}/project/{project}/ckt/rel/{macro}/{release}/macro/hspice"

    if (args.depotPath):
        depotPath = f"{args.depotPath}/ckt/rel/{macro}/{release}/macro/hspice"
    dprint(LOW, f"The depot path is: {depotPath}")

    # Run the 3 scripts
    if (args.test):
        pass
    else:
        run_commands(family, project, release, macro)

    # Get Analysis Results
    res = analyse_log_files()

    if (res == NULL_VAL):
        fatal_error("Could not find the necessary log files.")

    fullpath = create_p4_file(res)
    hprint(f"Results analysed. HSPICE LOG: {fullpath}")

    # Try submitting the log files to P4
    if (args.p4):
        submit_to_p4(depotPath, fullpath)


def create_p4_file(res):

    filename = "hspice_check.log"

    header = [
        f"Date: {datetime.now()}",
        f"Runner: { os.getlogin( ) }",
        f"Version: { __version__ }\n"
        ""
    ]

    hspice_ic = [
        "hspice_ic => " + res["ic"]["verdict"]
    ]

    hspice_enc = [
        "hspice_enc => " + res["enc"]["verdict"]
    ]

    # TICKET: P80001562-266037
    # COMMENT: option to add waivers (disabled due to miscommunication in current script goal)
    # KEYWORDS: waivers

    # listnames = [hspice_ic, hspice_enc]
    # waiver = FALSE

    # for name in listnames:
    #     if (re.search("-WAIVE", str(name))):
    #         name[0] = re.sub("-WAIVE",'',name[0])
    #         waiver = TRUE

    data = []

    # Opening JSON file
    try:
        f = open(args.severity)
        data = json.load(f)
        f.close()
    except Exception as e:
        eprint(
            f"Could not open JSON severity configuration file {args.severity}. {str(e)}")

    if len(data) > 0:
        checkSeverities(data, header)

    # if (len(data) > 0 and waiver == TRUE):
    #      waiverAppend("hspice_enc", data, header)
    #      waiverAppend("hspice_enc", data, header)

    with open(filename, "w") as outfile:
        outfile.write("\n".join(header))
        outfile.write("\n".join(hspice_ic))
        outfile.write("\n".join(hspice_enc))
    return os.path.abspath(filename)


def checkSeverities(data, array):
    tempArray = []
    for keys in data.keys():
        for key in data[keys].keys():
            if (data[keys][key] != "HIGH"):
                tempArray.append(f"{key} : {data[keys][key]} priority.")
    if len(tempArray) == 0:
        array.append("Severities are all HIGH (default)\n\n")
    else:
        array.append("Severities are HIGH (default) except for the following:\n")
        array += tempArray
        array.append("\n")
    return array


# Unused due to comments above
def waiverAppend(listname, data, array):
    waiveCheck = []
    tempArray = []
    for keys in data.keys():
        if (re.search(listname,str(keys))):
            tempArray.append("---WAIVER---")
            tempArray.append("The following checks have been waived:")
            for key in data[keys].keys():
                if (data[keys][key] == "LOW" or data[keys][key] == "MEDIUM"):
                    tempArray.append(f"{key} : {data[keys][key]} priority.")
                    waiveCheck.append(f"{key}")
            tempArray.append("------------")
            tempArray.append("\n")
    if not waiveCheck:
        tempArray.clear()
    else:
        array += tempArray
    return array


def analyse_log_files():

    # Get list of log files generated
    fullpath = []
    logs = glob.glob('*.log')

    if (len(logs) == 0):
        return NULL_VAL

    # Store information about a particular script
    analysis_hash = {
        "enc": {
            "verdict": ""
        },
        "ic": {
            "verdict": ""
        },
        "calibration_codes": {
            "verdict": ""
        }
    }

    for log in logs:

        full = os.path.abspath(log)
        fullpath.append(full)
        vhprint(HIGH, f"Checking file: {full}")

        strings_to_search = ['-F','FAIL: ','FAIL:CRITICAL:HIGH']

        if ("hspice_enc_check.pl" in log):
            lines = search_strings_starting_with(strings_to_search, log)
            analysis_hash["enc"]["verdict"] = get_verdict(lines)
            pass

        elif ("hspice_ic_verif" in log):
            lines = search_strings_starting_with(strings_to_search, log)
            analysis_hash["ic"]["verdict"] = get_verdict(lines)
            pass

        elif ("compare_codes.pl" in log):
            lines = search_strings_starting_with(strings_to_search, log)
            analysis_hash["calibration_codes"]["verdict"] = get_verdict(lines)
            pass

    if find_keys_missing_in_dict(analysis_hash, ["calibration_codes", "enc", "ic"]):
        # TODO print which keys are missing?
        return NULL_VAL

    return analysis_hash


def get_verdict(lines):

    verdict = ""

    if (len(lines) > 0):

        verdict = verdict + "FAIL: Detected the following:\n"
        for line in lines:

            # if ("WAIVE" in line): # option to add waivers (related to comments above)
            #     verdict = "PASS.\n"

            if ("WARNING" in line or '-W' in line or 'could not' in line):
                verdict = verdict + (f"{line}")

            if ("FAIL" in line or '-F' in line or 'Exiting' in line):
                verdict = verdict + (f"{line}")

            if ("-E" in line):
                verdict = verdict + (f"{line}")

    else:
        verdict = "PASS.\n"

    return verdict


def search_strings_starting_with(strings, file):  # error_messages_starting_with or add a variable
    answers = []
    with open(file) as f:
        dprint(HIGH, file)
        datafile = f.readlines()
        for line in datafile:
            for string in strings:
                # related to comments above
                # if (re.search("FAIL:CRITICAL:MEDIUM",str(line)) or re.search("FAIL:CRITICAL:LOW",str(line));
                #     answers.append("-WAIVE")
                if string in line:
                    answers.append(line)
                    dprint(HIGH, line)
    return answers


def submit_to_p4(depotPath, logfile):

    p4 = da_p4_create_instance()

    if (p4 is NULL_VAL):
        fatal_error("Could not create P4 connection. Exiting.")

    now = datetime.now()
    date = now.strftime("%d-%m-%Y-%H_%M_%S")

    p4.connect()
    submit_command = f"p4 -c {p4.client} submit -d \"Submitting from hspice.py on {date}\""

    mapping = da_p4_add_to_changelist(p4, depotPath, logfile)

    if (mapping is NULL_VAL):
        eprint("Could not create P4 mapping to workspace.")
        return NULL_VAL

    questions = [
        inquirer.List(
            "answer",
            message="Do you want to submit all files in the default changelist?",
            choices=["No", "Yes"],
        ),
    ]
    answer = inquirer.prompt(questions)

    if (answer["answer"] == "No"):
        hprint(
            f"Changelist will not be submitted. Files added to default changelist for client: {p4.client}")

    elif (answer["answer"] == "Yes"):
        # Execute a submit
        (out, err, ret) = run_system_cmd(submit_command, CommonHeader.VERBOSITY)
        dprint(HIGH, f"err: '{err}'")
        hprint(out)


def run_commands(family, project, release, macro):

    commands = ["", "", ""]
    if (args.depotPath):
        commands[0] = f"{bindir}/hspice_ic_verif.pl    -proj {family}/{project}/{release} -macro {macro} -depotPath {args.depotPath}"
        commands[1] = f"{bindir}/hspice_enc_check.pl -proj {family}/{project}/{release} -macro {macro} -depotPath {args.depotPath}"
    else:
        commands[0] = f"{bindir}/hspice_ic_verif.pl    -proj {family}/{project}/{release} -macro {macro}"
        commands[1] = f"{bindir}/hspice_enc_check.pl -proj {family}/{project}/{release} -macro {macro}"

    hprint("Running hspice ic check.\n")
    (out, err, ret) = run_system_cmd(commands[0], CommonHeader.VERBOSITY)
    iprint(out)
    dprint(HIGH, err)

    hprint("Running hspice enc check.\n")
    (out, err, ret) = run_system_cmd(commands[1], CommonHeader.VERBOSITY)
    iprint(out)
    dprint(HIGH, err)


def utils__script_usage_statistics(toolname, version):
    prefix = 'ddr-da-ddr-utils-original-'
    reporter = '/remote/cad-rep/msip/tools/bin/msip_get_usage_info'
    cmd = [reporter,
           '--tool_name', prefix + toolname,
           '--stage', 'main',
           '--category', 'ude_ext_1',
           '--tool_path', 'NA',
           '--tool_version', version]
    subprocess.run(cmd)


if __name__ == '__main__':

    args = parse_args()
    filename = os.getcwd() + '/' + os.path.basename(__file__) + '.log'
    logger = create_logger(filename)                       # Create log file

    # Register exit function
    atexit.register(footer)

    # Initalise shared variables and run main
    CommonHeader.init(args, __author__, __version__)

    header()
    main()
    iprint(f"Log file: {filename}")

    if (args.test):
        pass
    else:
        utils__script_usage_statistics("hspice.py", "2022ww15")

################################################
