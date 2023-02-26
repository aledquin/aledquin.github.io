#!/depot/Python/Python-3.8.0/bin/python
###############################################################################
#
# Name    : ibis.py
# Author  : Harsimrat Wadhawan
# Date    : 2022-04-12 12:50:04
# Purpose : Top level script. Run IBIS electrical, qualitative and calibration code checking at once.
#
# Modification History
#     000 Harsimrat Singh Wadhawan 2022-04-12 12:50:16
#         Created this script
#     001 Haashim Shahzada 2022-08-29 02:34:00
#         Commented out waiver functionality in regards to ticket P80001562-227146
#
###############################################################################

import argparse
import atexit
import glob
import inquirer
import os
import pathlib
import re
import sys
import json
from datetime import datetime

# ---------------------------------- #
bindir = str(pathlib.Path(__file__).resolve().parent)
sys.path.append(bindir)
sys.path.append(bindir + "/../lib/python/Util")
sys.path.append(bindir + "/../lib/python")
# ---------------------------------- #

from CommonHeader import LOW, NULL_VAL, MEDIUM, HIGH
from Messaging import iprint, dprint, fatal_error, eprint, hprint, p4print
from Messaging import vhprint
from Messaging import create_logger, footer, header
from Misc import (
    find_keys_missing_in_dict,
    run_system_cmd,
    get_release_version,
    read_legal_release,
    first_available_file,
)
from P4Utils import da_p4_add_to_changelist, da_p4_create_instance, da_p4_dir_exists
import CommonHeader
import Misc
import ibis_correlation_report
import ibis_impedance_spreadsheet

__author__ = "wadhawan"
__version__ = get_release_version()


DEFAULT_SEVERITY_LOCATION = f"{bindir}/../resources/severities.json"


def parse_args():

    # Always include -v, and -d
    parser = argparse.ArgumentParser(description="Parse Arguments")
    parser.add_argument(
        "-v",
        metavar="<#>",
        type=int,
        default=0,
        help="specify verbosity value (positive integer)",
    )
    parser.add_argument(
        "-d",
        metavar="<#>",
        type=int,
        default=0,
        help="specify debug value (positive integer)",
    )

    # Add your custom arguments here
    # -------------------------------------
    parser.add_argument("-macro", required=True, help="specify the macro name")
    parser.add_argument(
        "-p",
        "--project",
        required=True,
        help='specify the project spec "product/project/release"',
    )
    parser.add_argument(
        "-depotPath",
        help='specify the project location "product/project/release"',
    )
    parser.add_argument(
        "-p4",
        help="Upload log results to P4",
        action="store_true",
    )
    parser.add_argument(
        "-severity",
        default=DEFAULT_SEVERITY_LOCATION,
        help="Provide a custom severity configuration.",
    )
    parser.add_argument(
        "-test", help="Test the P4 submit commands", action="store_true"
    )
    parser.add_argument(
        "-correlation_file",
        help="Provide the path to the correlation file",
    )
    parser.add_argument(
        "-fast",
        help="Provide the percent change for the fast corner (optional for ibis_electrical)",
    )
    parser.add_argument(
        "-slow",
        help="Provide the percent change for the slow corner (optional for ibis_electrical)",
    )
    parser.add_argument(
        "-typ",
        help="Provide error percent threshold for the typ corner and vol/voh checks (optional for ibis_electrical)",
    )
    parser.add_argument(
        "-tol",
        help="Provide the maximum error percent threshold for the changed slow and fast corners (optional for ibis_electrical)",
    )
    # -------------------------------------
    args = parser.parse_args()
    return args


def validate_args(args: argparse.Namespace, release: str) -> None:
    """validates command line arguments"""
    family, project, release = Misc.parse_project_spec(args.project)

    da_p4_dir_exists(
        f"//depot/products/{family}/project/{project}/ckt/rel/{args.macro}/ckt/rel/{release}"
    )


def main():

    dprint(LOW, f"Debugger setting: {CommonHeader.DEBUG}")

    family = ""
    project = ""
    macro = args.macro
    release = ""

    answer = re.findall(r"^([^\/]+)\/([^\/]+)\/([^\/]+)$", args.project)
    dprint(MEDIUM, f"{answer}")
    if len(answer) > 0:
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
    release = parsed_legal_release["rel"]

    validate_args(args, release)

    # Set the depot path for the ibis folder
    depotPath = f"//depot/products/{family}/project/{project}/ckt/rel/{macro}/{release}/macro/ibis"

    if args.depotPath:
        depotPath = f"{args.depotPath}/ckt/rel/{macro}/{release}/macro/ibis"
    dprint(LOW, f"The depot path is: {depotPath}")

    # Run the 5 scripts
    if args.test:
        pass
    else:
        failed_correlation_models, failed_spreadsheet_models = run_commands(
            family, project, release, macro, args.correlation_file
        )

    # Get Analysis Results
    res = analyse_log_files()
    if res == NULL_VAL:
        fatal_error("Could not find the necessary log files.")

    analyse_correlation_models(failed_correlation_models, res)
    analyse_spreadsheet_models(failed_spreadsheet_models, res)

    fullpath = create_p4_file(res)
    hprint(f"Results analysed. IBIS LOG: {fullpath}")

    # Try submitting the log files to P4
    if args.p4:
        submit_to_p4(depotPath, fullpath)


def create_p4_file(res):

    filename = "ibis_check.log"

    header = [
        f"Date: {datetime.now()}",
        f"Runner: { os.getlogin( ) }",
        f"Version: { __version__ }\n" "",
    ]

    itemlist = [
        "ibis_electrical => " + res["electrical"]["verdict"],
        "ibis_quality => " + res["qualitative"]["verdict"],
        "compare_codes => " + res["calibration_codes"]["verdict"],
        "correlation_report => " + res["correlation_report"]["verdict"],
        "impedance_spreadsheet => " + res["impedance_spreadsheet"]["verdict"],
    ]

    # TICKET: P80001562-227146
    # COMMENT: option to add waivers (disabled due to miscommunication in current script goal)
    # KEYWORDS: waivers

    data = []

    # Opening JSON file
    try:
        f = open(args.severity)
        data = json.load(f)
        f.close()
    except Exception as e:
        eprint(
            f"Could not open JSON severity configuration file {args.severity}. {str(e)}"
        )

    if len(data) > 0:
        checkSeverities(data, header)

    with open(filename, "w") as outfile:
        outfile.write("\n".join(header))
        outfile.write("\n".join(itemlist))
    return os.path.abspath(filename)


def checkSeverities(data, array):
    tempArray = []
    for key in data:
        if data[key] != "HIGH":
            tempArray.append(f"{key} : {data[key]} priority.")
    if len(tempArray) == 0:
        array.append("Severities are all HIGH (default)\n\n")
    else:
        array.append("Severities are HIGH (default) except for the following:\n")
        array += tempArray
        array.append("\n")
    return array


def analyse_correlation_models(failed_models, res):
    if not failed_models:
        res["correlation_report"] = {"verdict": "PASS.\n"}
        return
    verdict = "FAIL: Detected the following:\n"
    res["correlation_report"] = {
        "verdict": f"{verdict} {len(failed_models)} models failed, see full list in ibis.py.log"
    }


def analyse_spreadsheet_models(failed_models, res):
    if not failed_models:
        res["impedance_spreadsheet"] = {"verdict": "PASS.\n"}
        return
    verdict = "FAIL: Detected the following:\n"
    res["impedance_spreadsheet"] = {
        "verdict": f"{verdict} {len(failed_models)} models failed, see full list in ibis.py.log"
    }


def analyse_log_files():

    # Get list of log files generated
    fullpath = []
    logs = glob.glob("*.log")

    if len(logs) == 0:
        return NULL_VAL

    # Store information about a particular script
    analysis_hash = {
        "electrical": {"verdict": ""},
        "qualitative": {"verdict": ""},
        "calibration_codes": {"verdict": ""},
    }

    for log in logs:

        full = os.path.abspath(log)
        fullpath.append(full)
        vhprint(HIGH, f"Checking file: {full}")

        strings_to_search = [
            "FAIL: ",
            "FAIL:CRITICAL:HIGH",
            "-F-",
            "FAIL:CRITICAL:MEDIUM",
            "FAIL:CRITICAL:LOW",
        ]

        if "ibis_electrical.pl" in log:
            lines = search_strings_starting_with(strings_to_search, log)
            analysis_hash["electrical"]["verdict"] = get_verdict(lines)
            pass

        elif "ibis_quality.pl" in log:
            lines = search_strings_starting_with(strings_to_search, log)
            analysis_hash["qualitative"]["verdict"] = get_verdict(lines)
            pass

        elif "compare_codes.pl" in log:
            lines = search_strings_starting_with(strings_to_search, log)
            analysis_hash["calibration_codes"]["verdict"] = get_verdict(lines)
            pass

    if find_keys_missing_in_dict(
        analysis_hash, ["calibration_codes", "qualitative", "electrical"]
    ):
        # TODO print missing keys?
        return NULL_VAL

    return analysis_hash


def get_verdict(lines):

    verdict = ""

    if len(lines) > 0:

        verdict = verdict + "FAIL: Detected the following:\n"
        for line in lines:

            if "WARNING" in line or "-W" in line or "could not" in line:
                verdict = verdict + (f"{line}")

            if "FAIL" in line or "-F" in line or "Exiting" in line:
                verdict = verdict + (f"{line}")

            if "-E" in line:
                verdict = verdict + (f"{line}")

    else:
        verdict = "PASS.\n"

    return verdict


def search_strings_starting_with(strings, file):

    answers = []
    with open(file) as f:
        dprint(HIGH, file)
        datafile = f.readlines()
        for line in datafile:
            for string in strings:
                if string in line:
                    answers.append(line)
                    dprint(HIGH, line)

    return answers


def submit_to_p4(depotPath, logfile):

    p4 = da_p4_create_instance()

    if p4 is NULL_VAL:
        fatal_error("Could not create P4 connection. Exiting.")

    now = datetime.now()
    date = now.strftime("%d-%m-%Y-%H_%M_%S")

    p4.connect()
    submit_command = f'p4 -c {p4.client} submit -d "Submitting from ibis.py on {date}"'

    mapping = da_p4_add_to_changelist(p4, depotPath, logfile)

    if mapping is NULL_VAL:
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

    if answer["answer"] == "No":
        hprint(
            f"Changelist will not be submitted. Files added to default changelist for client: {p4.client}"
        )

    elif answer["answer"] == "Yes":
        # Execute a submit
        (out, err, ret) = run_system_cmd(submit_command, CommonHeader.VERBOSITY)
        dprint(HIGH, f"err: '{err}'")
        hprint(out)


def run_correlation_analysis(correlation_file):
    if not correlation_file:
        return []

    hprint("Running IBIS correlation report check.\n")
    failed_correlation_models = ibis_correlation_report.run_correlation_report(
        correlation_file
    )
    if len(failed_correlation_models) == 0:
        p4print("NO FAILED MODELS DETECTED\n")
    else:
        eprint("NUMBER OF FAILED MODELS: " + str(len(failed_correlation_models)) + "\n")
        eprint("FAILED MODELS:" + str(failed_correlation_models) + "\n")

    return failed_correlation_models


def run_impedance_spreadsheet(args):

    hprint("Running IBIS impedance spreadsheet check.\n")

    missing_spreadsheet_models = ibis_impedance_spreadsheet.main(args)

    return missing_spreadsheet_models


def run_commands(family, project, release, macro, correlation_file):

    commands = ["", "", ""]
    if args.depotPath:
        commands[
            0
        ] = f"{bindir}/ibis_quality.pl    -p {family}/{project}/{release} -macro {macro} -depotPath {args.depotPath} -severity {args.severity}"
        commands[
            1
        ] = f"{bindir}/ibis_electrical.pl -p {family}/{project}/{release} -macro {macro} -depotPath {args.depotPath} -severity {args.severity} -typ {args.typ} -slow {args.slow} -fast {args.fast} -tol {args.tol}"
        commands[
            2
        ] = f"{bindir}/compare_codes.pl   -p {family}/{project}/{release} -macro {macro} -depotPath {args.depotPath} -severity {args.severity}"
    else:
        commands[
            0
        ] = f"{bindir}/ibis_quality.pl    -p {family}/{project}/{release} -macro {macro} -severity {args.severity}"
        commands[
            1
        ] = f"{bindir}/ibis_electrical.pl -p {family}/{project}/{release} -macro {macro} -severity {args.severity}"
        commands[
            2
        ] = f"{bindir}/compare_codes.pl   -p {family}/{project}/{release} -macro {macro} -severity {args.severity}"

    failed_correlation_models = run_correlation_analysis(correlation_file)

    missing_spreadsheet_models = run_impedance_spreadsheet(args)

    hprint("Running IBIS qualitative check.\n")
    (out, err, ret) = run_system_cmd(commands[0], CommonHeader.VERBOSITY)
    iprint(out)
    dprint(HIGH, err)

    hprint("Running IBIS electrical check.\n")
    (out, err, ret) = run_system_cmd(commands[1], CommonHeader.VERBOSITY)
    iprint(out)
    dprint(HIGH, err)

    hprint("Running IBIS calibration code check.\n")
    (out, err, ret) = run_system_cmd(commands[2], CommonHeader.VERBOSITY)
    iprint(out)
    dprint(HIGH, err)

    return failed_correlation_models, missing_spreadsheet_models


if __name__ == "__main__":

    args = parse_args()
    filename = os.getcwd() + "/" + os.path.basename(__file__) + ".log"
    logger = create_logger(filename)  # Create log file

    # Register exit function
    atexit.register(footer)

    # Initalise shared variables and run main
    CommonHeader.init(args, __author__, __version__)

    header()
    main()
    iprint(f"Log file: {filename}")

    if args.test:
        pass
    else:
        Misc.utils__script_usage_statistics("ibis.py", "2022ww15")
