#!/depot/Python/Python-3.8.0/bin/python
"""
Name    : gen_runExtract.py
Author  : Angelina Chan
Date    : Dec 08, 2022
Purpose : Generates runExtract_design.tcl and runExtract_timing.tcl based on
          the runExtract_*.tcl Golden References and project information.
"""
from __future__ import annotations
from typing import List, Tuple

__author__ = "Angelina Chan"
__tool_name__ = "gen_runExtract"

import argparse
import atexit
import os
import pathlib
import sys
import re

# from typing import Dict, Tuple
from P4 import P4Exception, P4

bindir = str(pathlib.Path(__file__).resolve().parent)
# Add path to library that may be symbolically linked.
sys.path.append(bindir + "/../lib/Util")
# Add path to sharedlib's Python Utilities directory.
sys.path.append(bindir + "/../lib/python/Util")


# Import messaging functions
from Messaging import iprint, fatal_error, dprint, hprint, eprint

# Import other logging functions
import Messaging as Msg

# Import miscellaneous utilities
import Misc
import CommonHeader as CH
from P4Utils import da_p4_create_instance, da_p4_add_to_changelist


def parse_args() -> argparse.Namespace:
    """Parse command-line arguments."""
    parser = argparse.ArgumentParser(
        description=(
            "Generates runExtract_design.tcl and runExtract_timing.tcl"
            " based on the runExtract_*.tcl Golden References and "
            "project information."
        )
    )
    parser.add_argument(
        "-v", metavar="<#>", type=int, default=0, help="verbosity"
    )
    parser.add_argument("-d", metavar="<#>", type=int, default=0, help="debug")

    # Custom arguments
    # -------------------------------------
    parser.add_argument(
        "-g",
        "--GR",
        metavar="<PATH>",
        type=str,
        help=(
            "Golden Reference path for 'runExtract_*.tcl'."
            " Example: //wwcad/msip/projects/<product>/tb/<gen>/design/extract"
            "ion/runExtract_*.tcl"
        ),
        required=True,
    )
    parser.add_argument(
        "-n",
        "--netlist",
        metavar="<PATH>",
        type=str,
        help=(
            "Project path up to the metal stack folder "
            "where netlist is saved. Replaces 'PROJECT_NETLIST_PATH' in GR."
            " Example: /remote/proj/ddr5/d910-ddr5"
            "-tsmc5ff-12/rel1.00_cktpcs/design/15M_1X_h_1Xb_v_1Xe_h_1Ya_v_1Y"
            "b_h_5Y_vhvhv_2Yy2Z"
        ),
        required=True,
    )
    parser.add_argument(
        "-m",
        "--maildist",
        metavar="<str>",
        type=str,
        help=(
            "Default mailing list. Replaces 'DEFAULT_MAILDIST' in GR"
            " Example: jfisher,yamin,chengj,rashoyan."
        ),
        required=True,
    )
    parser.add_argument(
        "-o",
        "--output",
        metavar="<PATH>",
        type=str,
        help=(
            "Output location where the generated runExtract files"
            " will be saved. Perforce or local directory path."
        ),
        required=True,
    )
    # -------------------------------------
    args = parser.parse_args()
    return args


def main(args: argparse.Namespace) -> None:
    """Main function."""
    # get info from user
    GR_path = args.GR
    netlist = args.netlist
    maildist = args.maildist
    output = args.output
    try:
        p4 = p4_connect()
        # check user inputs
        check_netlist(netlist)
        check_GR(GR_path)
        check_output(output)

        if not GR_path.startswith("//"):
            GR_path = os.path.abspath(GR_path)
        if not netlist.startswith("//"):
            netlist = os.path.abspath(netlist)
        if not output.startswith("//"):
            output = os.path.abspath(output)

        # grab GR runExtract_*.tcl from P4
        GR_data = get_GR(GR_path)
        # for now just grab from '/remote/us01home44/dma/runExtract_D5'
        #   temp files to store p4 files

        # replace 'PROJECT_NETLIST_PATH' and 'DEFAULT_MAILDIST'
        rE_data = replace_var(GR_data, netlist, maildist)

        # export newly created runExtract files
        #   default to p4
        export_runExtract(rE_data, output, p4)
    except P4Exception:
        eprint("P4 errors:")
        for e in p4.errors:  # Display errors
            print(e)
        fatal_error("Exiting...")
    finally:
        # remove temp files
        rm_temp_files()
        p4.disconnect()


def check_netlist(netlist: str) -> None:
    """
    Checks the netlist project path given by user from cmd line
    """
    if os.path.isdir(netlist):
        dprint(CH.LOW, f"Netlist dir '{os.path.abspath(netlist)}' exists")
        pass
    else:
        fatal_error(
            f"Netlist directory does not exist or is not readable: {netlist}"
        )


def check_output(output: str) -> None:
    """
    Checks the output path given by user from cmd line
    """
    if output.startswith("//"):
        dprint(CH.LOW, "Perforce path output")
        # da_p4_add_to_changelist already checks if directory exists
        pass
    else:
        if os.path.isdir(output):
            dprint(CH.LOW, f"Output dir '{os.path.abspath(output)}' exists")
            pass
        else:
            fatal_error(
                f"Output path does not exist or is not readable: {output}"
            )


def check_GR(GR_path: str) -> None:
    """
    Checks the Golden Reference runExtract_*.tcl path.
    """
    if GR_path.startswith("//"):
        missing = 0
        if GR_path.endswith("/"):
            GR_path = GR_path[:-1]

            dprint(CH.HIGH, f"File path: {GR_path}")
            design_exist = Misc.run_system_cmd(
                f"p4 files {GR_path}/runExtract_design.tcl", CH.VERBOSITY
            )
            timing_exist = Misc.run_system_cmd(
                f"p4 files {GR_path}/runExtract_timing.tcl", CH.VERBOSITY
            )
        dprint(CH.MEDIUM, f"Output of p4 files {GR_path}: {design_exist}")
        dprint(CH.MEDIUM, f"Output of p4 files {GR_path}: {timing_exist}")
        if not check_p4_files(design_exist):
            eprint(
                "GR runExtract_design.tcl does not exist or is not readable."
            )
            missing += 1
        if not check_p4_files(timing_exist):
            eprint(
                "GR runExtract_timing.tcl does not exist or is not readable."
            )
            missing += 1
        if missing >= 1:
            fatal_error("Exiting...")
    else:
        if os.path.isdir(GR_path):
            dprint(CH.LOW, f"GR dir '{os.path.abspath(GR_path)}' exists")
        else:
            fatal_error(f"GR does not exist or is not readable: {GR_path}")


def check_p4_files(output: Tuple[str, str, int]) -> bool:
    """
    Checks the output of P4Utils.p4_files for no files/invalid path.
    """
    for out in output:
        out = str(out)
        con1 = re.search("^Invalid(.*)", out)
        con2 = out.endswith("no such file(s).\n")
        con3 = re.search("^Path '(.*)' is not", out)
        if con1 or con2 or con3:
            return False
    return True


def get_GR(GR_path: str) -> runExtract:
    """
    Grabs the Golden Reference runExtract_*.tcl files from Perforce.
    """
    dprint(CH.LOW, "Obtaining GR...")
    if GR_path.startswith("//"):
        dprint(CH.LOW, "P4 GR")
        design, timing = print_GR(GR_path)
    else:
        dprint(CH.LOW, "Local GR")
        design_path = os.path.join(GR_path, "runExtract_design.tcl")
        timing_path = os.path.join(GR_path, "runExtract_timing.tcl")
        design = list(Misc.read_file(design_path))
        timing = list(Misc.read_file(timing_path))

    GR_data = runExtract(design, timing)
    dprint(CH.HIGH, f"Design:\n{GR_data.design}")
    dprint(CH.HIGH, f"Timing:\n{GR_data.timing}")
    return GR_data


def print_GR(output: str) -> Tuple[str, str]:
    if output.endswith("/"):
        output = output[:-1]
    if output.endswith("/..."):
        output = output[:-4]
    if output.endswith("..."):
        output = output[:-3]
    design_p4 = output + "/runExtract_design.tcl"
    timing_p4 = output + "/runExtract_timing.tcl"
    design_path = p4_file("GR_runExtract_design", "tcl", design_p4)
    timing_path = p4_file("GR_runExtract_design", "tcl", timing_p4)
    return design_path, timing_path


def p4_file(name: str, ext: str, perforce_path: str):
    """
    Prints a file from P4 into a temporary file in the current working
    directory.
    """
    dprint(
        CH.LOW,
        f"p4 print {perforce_path} > temp_{name}.{ext}",
    )
    Misc.run_system_cmd(
        f"p4 print {perforce_path} > temp_{name}.{ext}", CH.VERBOSITY
    )
    new_path = os.path.abspath(f"temp_{name}.{ext}")
    return new_path


class runExtract:
    """
    Class to store the runExtract_*.tcl data.
    """

    def __init__(self, design: List[str], timing: List[str]) -> None:
        self.timing = timing
        self.design = design


def replace_var(GR: runExtract, netlist: str, maildist: str) -> runExtract:
    """
    Replaces 'PROJECT_NETLIST_PATH' and 'DEFAULT_MAILDIST' in the
    runExtract_*.tcl Golden Reference.
    """
    dprint(CH.LOW, "Replacing project path and mailing list...")
    if netlist.endswith("/"):
        netlist = netlist[:-1]

    design = GR.design
    design = [
        d if d.startswith("#") else d.replace("PROJECT_NETLIST_PATH", netlist)
        for d in design
    ]

    design = [
        d if d.startswith("#") else d.replace("DEFAULT_MAILDIST", maildist)
        for d in design
    ]
    dprint(CH.HIGH, f"Design:\n{design}")

    timing = GR.timing
    timing = [
        t if t.startswith("#") else t.replace("PROJECT_NETLIST_PATH", netlist)
        for t in timing
    ]
    timing = [
        t if t.startswith("#") else t.replace("DEFAULT_MAILDIST", maildist)
        for t in timing
    ]
    dprint(CH.HIGH, f"Timing:\n{timing}")

    rE_data = runExtract(design, timing)
    return rE_data


def export_runExtract(rE_data: runExtract, output: str, p4: P4) -> None:
    """
    Exports runExtract_*.tcl files to output location.
    In order to submit to P4 the file must exist in the local directory.
    Submitting to P4 will generate the runExtract_*.tcl files in the current
    working directory and then submit to P4.
    """
    dprint(CH.LOW, "Exporting...")
    if output.startswith("//"):
        user_input = input(
            "Submit all files in the default changelist to P4? [Y/N]\n"
        ).lower()
        if user_input in ["y", "yes"]:
            submit = True
        else:
            submit = False
        dprint(CH.LOW, "P4 output")
        depotPath = output

        dprint(CH.LOW, "Writing files...")
        design_path = os.path.join(os.getcwd(), "runExtract_design.tcl")
        with open(design_path, "w") as f:
            for line in rE_data.design:
                f.write(f"{line}\n")

        timing_path = os.path.join(os.getcwd(), "runExtract_timing.tcl")
        with open(timing_path, "w") as f:
            for line in rE_data.timing:
                f.write(f"{line}\n")

        description = "Generated runExtract_design.tcl using gen_runExtract.py"
        submit_to_p4(p4, depotPath, design_path, description, submit)

        description = "Generated runExtract_timing.tcl using gen_runExtract.py"
        submit_to_p4(p4, depotPath, timing_path, description, submit)

    else:
        dprint(CH.LOW, "Local output")
        design_path = os.path.abspath(
            os.path.join(output, "runExtract_design.tcl")
        )
        with open(design_path, "w") as f:
            for line in rE_data.design:
                f.write(f"{line}\n")
        timing_path = os.path.abspath(
            os.path.join(output, "runExtract_timing.tcl")
        )
        with open(timing_path, "w") as f:
            for line in rE_data.timing:
                f.write(f"{line}\n")
        hprint(f"Generated runExtract_design.tcl: '{design_path}'")
        hprint(f"Generated runExtract_timing.tcl: '{timing_path}'")


def submit_to_p4(
    p4: P4, depotPath: str, file: str, description: str, submit: bool
) -> None:
    """
    Submits a file to P4.
    """
    file_name = file.split("/")[len(file.split("/")) - 1]
    if submit:
        iprint(f"Submitting '{file_name}' to P4...")
    else:
        iprint(
            f"Not submitting '{file_name}' to P4, "
            "local copy created in P4 workspace..."
        )

    submit_command = f'p4 -c {p4.client} submit -d "{description}"'
    dprint(CH.LOW, "Executing da_p4_add_to_changelist...")
    mapping = da_p4_add_to_changelist(p4, depotPath, file)
    dprint(CH.MEDIUM, f"Mapping: {mapping}")

    if mapping is CH.NULL_VAL:
        fatal_error("Could not create P4 mapping to workspace.")

    if submit:
        # Execute a submit
        out, err, ret = Misc.run_system_cmd(submit_command, CH.VERBOSITY)
        dprint(CH.HIGH, f"err: '{err}'")
        hprint(out)
    else:
        hprint(
            "Changelist will not be submitted. "
            f"Files added to DEFAULT changelist for client: {p4.client}"
        )


def p4_connect() -> P4:
    """
    Try to connect to the P4 server and exit script if it fails.
    """
    p4 = da_p4_create_instance()
    if p4 == CH.NULL_VAL:
        fatal_error("Could not create P4 connection. Exiting...")
    p4.connect()
    return p4


def rm_temp_files() -> None:
    """
    Removes the temporary files generated by the script.
    """
    dprint(CH.LOW, "Removing temp files")
    if os.path.isfile(os.getcwd() + "/temp_GR_runExtract_design.tcl"):
        os.unlink(os.getcwd() + "/temp_GR_runExtract_design.tcl")
    if os.path.isfile(os.getcwd() + "/temp_GR_runExtract_timing.tcl"):
        os.unlink(os.getcwd() + "/temp_GR_runExtract_timing.tcl")


if __name__ == "__main__":
    args = parse_args()
    filename = os.getcwd() + "/" + os.path.basename(__file__) + ".log"
    logger = Msg.create_logger(filename)  # Create log file

    # Register exit function
    atexit.register(Msg.footer)

    # Initalise shared variables and run main
    version = Misc.get_release_version()
    CH.init(args, __author__, version)

    Misc.utils__script_usage_statistics(__tool_name__, version)
    Msg.header()
    main(args)
    iprint(f"Log file: {filename}")
