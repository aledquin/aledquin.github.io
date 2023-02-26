#!/depot/Python/Python-3.8.0/bin/python
###############################################################################
#
# Author  : Maisha Aniqa
# Date    : 2022-12-09
# Purpose : Read config files that include all the required filenames for perc
#           and create empty files based on the filenames for each of the required hard macros.
#           Then, map all files to the depot and submit it.
#
###############################################################################

import argparse
import atexit
import os
import pathlib
import sys
from datetime import datetime
import inquirer
import yaml

bindir = str(pathlib.Path(__file__).resolve().parent)
sys.path.append(bindir + "/../lib/Util")
sys.path.append(bindir + "/../../../../sharedlib/python/Util")

from CommonHeader import NULL_VAL
from Messaging import (
    iprint,
    eprint,
    hprint,
    nprint,
    p4print,
    fatal_error,
    create_logger,
    footer,
)
from Misc import run_system_cmd, get_release_version
from P4Utils import da_p4_add_to_changelist, da_p4_create_instance
import CommonHeader
import Misc
import Messaging

__author__ = "maisha"
__version__ = get_release_version()


def parse_args():
    # Always include -v, and -d
    parser = argparse.ArgumentParser(
        description="This script creates empty files for perc and maps them to depot."
    )
    parser.add_argument("-v", metavar="<#>", type=int, default=0, help="verbosity")
    parser.add_argument("-d", metavar="<#>", type=int, default=0, help="debug")

    # Add your custom arguments here
    # ----------------------------------------------------------------------------------------------------------------------------
    parser.add_argument(
        "--project",
        required=True,
        help="Project format: <project number>-<hard macro family>-<tech node> \nExample: d910-ddr5-tsmc5ff-12",
    )
    parser.add_argument(
        "--rel_version_legalRelease",
        required=True,
        help="Release version for legalRelease.txt file. \nExample: rel1.00_cktpcs",
    )
    parser.add_argument(
        "--parent_directory",
        required=True,
        help="""The path to your P4 workspace where you would like to create a directory for each hard macro family.
        \nExample of path: ../../../../../../remote/us01home50/maisha/p4_ws/products/lpddr5x_ddr5_phy/lp5x/project/depot/perc/""",
    )
    parser.add_argument(
        "--config_file_path",
        required=True,
        help="""Depot path of the config file.
        \nExample of path: //depot/products/lpddr5x_ddr5_phy/ddr5/common/qms/templates/perc/ddr5.txt""",
    )
    parser.add_argument(
        "--rel_version",
        required=True,
        help="The version of the project (e.g. 1.00a, 2.00a, 2.10a)",
    )
    parser.add_argument(
        "--stack_value",
        required=True,
        help="The stack value (e.g. 11M_3Mx_4Cx_2Kx_2Gx_LB)",
    )
    parser.add_argument(
        "--hard_macro",
        required=True,
        help="The hard macro (e.g. dwc_ddrphydbyte_top_ew)",
    )
    parser.add_argument(
        "--icv_or_calibre",
        required=True,
        help="Choose between icv and calibre. Enter either 'icv' or 'calibre'",
    )
    parser.add_argument(
        "--submit_to_p4",
        action="store_true",
        help="Submit seeded files to p4",
    )
    # ----------------------------------------------------------------------------------------------------------------------------
    args = parser.parse_args()
    return args


def main():
    # Extracting metal stack covers from legalRelease.txt file based on the project inputted by the user
    proj_name = args.project
    proj_name_split = proj_name.split("-")
    hard_macro_family = proj_name_split[1]
    rel_ver_legalRelease = args.rel_version_legalRelease
    """
    Example:
        legal_release_file_path = //wwcad/msip/projects/ddr5/d910-ddr5-tsmc5ff-12/rel1.00_cktpcs/pcs/design/legalRelease.txt
    """
    legal_release_file_path = f"//wwcad/msip/projects/{hard_macro_family}/{proj_name}/{rel_ver_legalRelease}/pcs/design/legalRelease.txt"
    os.chdir()

    stack_values = []
    for line in Misc.read_file(legal_release_file_path):
        """
        Reading each line of legalRelease.txt file till the line starting with "set metal_stack_cover" is found
        Example of the line:
        set stack_metal_cover "15M_1X_h_1Xb_v_1Xe_h_1Ya_v_1Yb_h_5Y_vhvhv_2Yy2Z_SHDMIM 16M_1X_h_1Xb_v_1Xe_h_1Ya_v_1Yb_h_4Y_vhvh_2Yy2Yx2R_SHDMIM"
        """
        if "set metal_stack_cover" in line:
            # List comprehension to extract the stack values within quotations. Splits the set of stacks by whitespace to extract individial stack values
            stack_values = [x.strip('"') for x in line.split()[2:]]
            for x in stack_values:
                nprint(x)
            break

    if not stack_values:
        fatal_error("Can't find metal_stack_cover in the legalRelease.txt")

    # Using mkdir() method to create directories for each required hard macro family
    parent_dir = args.parent_directory
    hard_macro_families = ["ddr43", "ddr54", "lpddr54", "ddr5", "lpddr5x"]
    for dir in hard_macro_families:
        path = os.path.join(parent_dir, dir)
        try:
            os.makedirs(path, exist_ok=True)
            nprint("Directory '%s' created" % dir)
        except Exception as e:
            fatal_error("Failed to create directory '%s'. \nThe script in usage is perc_seeding.py. \n" % dir + str(e))

    create_perc_files(stack_values, hard_macro_families)

    """
    Mapping the files to depot
    Root path = //depot/products/<family>/project/<project>/ckt/rel/perc/<rel>/<stack>/PERC_<HM>/<icv|calibre>/perc_esd
    """
    rel_ver = args.rel_version
    stack = args.stack_value
    hm = args.hard_macro
    icv_calibre = args.icv_or_calibre

    # Set the depot path for the perc_esd folder
    depot_path = f"//depot/products/{hard_macro_family}/project/{proj_name}/ckt/rel/perc/{rel_ver}/{stack}/PERC_{hm}/{icv_calibre}/perc_esd"

    # Try submitting the empty files to P4
    if args.submit_to_p4:
        submit_to_p4(depot_path)


def create_perc_files(stack_values, hard_macro_families):

    # Reading config file based on the hard macro family and creating empty files
    for hard_macro_family in hard_macro_families:
        config_file_path_input = args.config_file_path
        config_file_path = f"{config_file_path_input}{hard_macro_family}.yaml"
        with open(config_file_path, "r") as file:
            config = yaml.safe_load(file)  # safe_load() parses a YAML file

        expected_keys = ["PERC_HM", "files"]  # sections in the YAML file
        missing_keys = [x for x in expected_keys if x not in config]
        if missing_keys:
            fatal_error(f"Missing key {missing_keys} in {config_file_path}")

        new_files = []
        # Replacing the 'PERC_HM' variable in the config files
        for perc_hm in config["PERC_HM"]:
            for file in config["files"]:
                new_files.append(file.replace("<PERC_HM>", perc_hm))

        # Replacing the 'stack' variable in the config files
        for stack_value in stack_values:
            for file in config["files"]:
                new_files.append(file.replace("<stack>", stack_value))

        # Comment out the for loop section to ensure the script doesn't create junk files, in case if it doesn't work
        for new_file in new_files:
            open(
                new_file, "a"
            ).close()
            nprint("Empty file created: ", new_file)


def submit_to_p4(depot_path):
    p4 = da_p4_create_instance()

    if p4 == NULL_VAL:
        fatal_error("Could not create P4 connection. Exiting.")

    now = datetime.now()
    date = now.strftime("%d-%m-%Y-%H_%M_%S")

    p4.connect()
    submit_command = f'p4 -c {p4.client} submit -d "Submitting from perc_seeding.py on {date}"'

    mapping = da_p4_add_to_changelist(p4, depot_path)

    if mapping is NULL_VAL:
        eprint("Could not create P4 mapping to workspace.")
        return NULL_VAL

    questions = [
        inquirer.List(
            "answer",
            message="Do you want to submit all files in the default changelist?",
            choices=["No", "Yes"],
        )
    ]
    answer = inquirer.prompt(questions)

    if answer["answer"] == "No":
        hprint(
            f"Changelist will not be submitted. Files added to default changelist for client: {p4.client}"
        )

    elif answer["answer"] == "Yes":
        # Execute a submit
        (out, err, ret) = run_system_cmd(submit_command, CommonHeader.VERBOSITY)
        if ret != 0:
            # add a fatal error saying sSububmitting to p4 failed
            fatal_error(f"Submitting to p4 failed.\n" f"Output {out}\n" f"Error {err}")
        else:
            p4print("Submitting to p4 passed!")


if __name__ == "__main__":
    args = parse_args()
    filename = os.getcwd() + "/" + os.path.basename(__file__) + ".log"
    logger = create_logger(filename)  # Create log file

    # Register exit function
    atexit.register(footer)

    # Initalise shared variables and run main
    CommonHeader.init(args, __author__, __version__)

    Misc.utils__script_usage_statistics("perc_seeding.py", "2022.12")
    Messaging.header()
    main()
    iprint(f"Log file: {filename}")
