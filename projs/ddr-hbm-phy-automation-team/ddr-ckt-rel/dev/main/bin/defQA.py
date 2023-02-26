#!/depot/Python/Python-3.8.0/bin/python -E
# 04-19-2022 Dikshant: Updated p4 sync to p4 print,
#                      so it doesn't sync data in user's directory.
#                      Updated log statements
# 07-13-2022 Dikshant: Updated script to grep data from legalRelease
#                      file to ignore certain macros
#                      that are not part of CRR.txt.
#                      Updated script to read subdef macros.
#                      Also added new option called --legal
#################################################################
import argparse
import re
import os
import sys
import collections
from pathlib import Path
from typing import List, Dict, Tuple

BIN_DIR = str(Path(__file__).resolve().parent)
# Add path to sharedlib's Python Utilities directory.
sys.path.append(BIN_DIR + "/../lib/python/Util")

import P4Utils
import CommonHeader
import Misc
import Messaging


class CommonHeaderArgs:
    """Helper used for initializing CommonHeader"""

    d = 0
    v = 0
    __author__ = "unittest"
    __version__ = "1.00"


CommonHeader.init(CommonHeaderArgs, CommonHeaderArgs.__author__, CommonHeaderArgs.__version__)


Misc.utils__script_usage_statistics("defQA", "2022ww34")


def _parse_command_line_args() -> argparse.Namespace:
    """Parses, validates, and returns command-line arguments."""

    parser = argparse.ArgumentParser(
        description="Syncs all the def files mentioned in the crr file.\n"
        "defQA.py flags all DEF instances with invalid coordinates.\n"
        "defQA.py flags all DEF instances that do not have a corresponding DEF file sub-cell or LIB/LEF sub-cell.\n"
        "defQA.py also flags all LIB/LEF cells that we not specified in any DEF file."
    )
    parser.add_argument(
        "-c",
        "--crr",
        type=Path,
        required=True,
        help="Path to CRR file. Example: ckt_release_1.00a_pre1_crr.txt",
    )
    parser.add_argument(
        "-d",
        "--dFile",
        type=Path,
        help="Path to dFile.",  # TODO: Find example
    )
    parser.add_argument(
        "-l",
        "--legal",
        type=Path,
        help="Path to legal release file.",
    )
    parser.add_argument(
        "-n",
        "--nosync",
        action="store_true",
        help="Disable syncing user's DEF file. Note: must be used with -d|--dFile argument.",
    )

    args = parser.parse_args()

    if args.nosync and args.dFile is None:
        parser.error("Argument -n|--nosync must be used with argument -d|--dFile")

    if not args.crr.is_file():
        parser.error(f"Path to CRR file '{args.crr}' does not exist. Please provide a valid path.")
    if args.dFile is not None and not args.dFile.is_file():
        parser.error(
            f"Path to DEF file '{args.dFile}' does not exist. Please provide a valid path."
        )
    return args


def main():
    args = _parse_command_line_args()

    Messaging.create_logger("defQA.log")
    Messaging.nprint("Welcome to DEF QA")

    crrFile = args.crr

    def_ignore = _find_ignored_def_files(args.legal)
    libs, defs, lefs = _find_libs_defs_lefs_in_crr(args.crr, args.nosync, args.dFile)

    if not defs["Paths"]:
        Messaging.eprint("Couldn't find any def file instance in {}.. Exiting".format(crrFile))
        exit(1)
    if not libs:
        Messaging.eprint("-E- Couldn't find any lib file instance in {}.. Exiting".format(crrFile))
        exit(1)
    if not lefs:
        Messaging.eprint("Couldn't find lef lib file instance in {}.. Exiting".format(crrFile))
        exit(1)

    defLefs = collections.defaultdict(dict)
    lefs = [i for i in lefs if not re.search(r"merged", i)]
    for def_file in defs["Paths"]:
        _process_def_file(def_file, args.nosync, args.crr, def_ignore, defLefs, defs, lefs, libs)

    _check_all_lef_files_found_in_defs(lefs, defLefs)


def _find_ignored_def_files(legal_release: Path) -> List[str]:
    """Finds ignored DEF files from the legal release."""
    if not legal_release:
        # No legal release provided, return no ignored files
        return []

    def_ignore, _, _ = Misc.run_system_cmd(f"egrep -i defignore {legal_release}", 0)
    def_ignore = def_ignore.strip()

    if re.search(r"#", def_ignore):
        Messaging.wprint("defIgnore param is commented out in legalRelease file.")
        return []

    search_found = re.search(r"\{(.+)\}", def_ignore)
    if search_found is None:
        return []

    def_ignore = search_found.groups(1)[0].split(" ")
    if len(def_ignore) == 0:
        Messaging.wprint("Couldn't find defIgnore param in legalRelease file")
    return def_ignore


def _find_libs_defs_lefs_in_crr(
    crr_file: Path, nosync: bool, def_file: Path
) -> Tuple[List, Dict, List]:
    """Finds libs, defs and lefs from CRR file."""
    libs = []
    defs = collections.defaultdict(dict)
    defs["Names"] = []
    defs["Paths"] = []
    lefs = []

    with open(crr_file, "r") as crr:
        for line in crr:
            line = line.strip()
            if re.search(r".+\.lib(?:\.gz)?#\d+", line):
                libName = re.split(r"\s+", line)[-1]
                libName = re.match(r"\'(.+)#\d+\'", libName).group(1)
                libName = libName.split("/")[-1]
                libs.append(libName)
            elif re.search(r".+\.def#\d+", line) and not nosync:
                defName = re.split(r"\s+", line)[-1]
                defName = re.match(r"\'(.+)#\d+\'", defName).group(1)
                defBase = defName.split("/")[-1]
                defs["Paths"].append(defName)
                if re.search("_inst", defBase):
                    defBase = defBase.replace("_inst.def", "")
                else:
                    defBase = defBase.replace(".def", "")
                defs["Names"].append(defBase)
            elif re.search(r".+\.lef#\d+", line):
                lefName = re.split(r"\s+", line)[-1]
                lefName = re.match(r"\'(.+)#\d+\'", lefName).group(1)
                lefName = lefName.split("/")[-1]
                lefs.append(lefName)

    if nosync:
        for line in Misc.read_file(def_file):
            if re.search(r".+\.def", line):
                defName = re.split(r"\s+", line)[-1]
                defName = re.match("(.+)", defName).group(1)
                defBase = defName.split("/")[-1]
                defs["Paths"].append(defName)
                if re.search("_inst", defBase):
                    defBase = defBase.replace("_inst.def", "")
                else:
                    defBase = defBase.replace(".def", "")
                defs["Names"].append(defBase)
    return libs, defs, lefs


def _process_def_file(
    defFile: str, nosync: bool, crrFile: Path, def_ignore, defLefs: Dict, defs, lefs, libs
) -> None:
    """Process a single DEF file."""
    if not nosync:
        filename = os.path.basename(defFile)
        Messaging.iprint("Reading {} file from p4 server".format(filename))
        op = P4Utils.da_p4_print_p4_file(defFile)
    else:
        filename = defFile
    Messaging.iprint("Checking {}".format(filename))
    #        if os.path.isfile(remoteFile) == False and args.nosync == False:
    #            print("-E- Couldn't find {},Please sync it manually\n".format(remoteFile))
    #            Messaging.nprint("-E- Couldn't find {},Please sync it manually\n".format(remoteFile))
    #            continue
    #        elif os.path.isfile(remoteFile) == False and args.nosync == False:
    #            print("-E- Couldn't find {},Please provide correct filepath in {}\n".format(remoteFile,dFile))
    #            Messaging.nprint("-E- Couldn't find {},Please provide correct filepath in {}\n".format(remoteFile,dFile))
    #            continue

    defLefs[filename] = []
    check = True
    for line in op.splitlines():
        if re.search(r"END\s+COMPONENTS", line, re.IGNORECASE):
            break
        if line.startswith("-"):
            line_check = _process_def_file_line(
                line, defFile, filename, def_ignore, crrFile, defLefs, defs, lefs, libs
            )
            if not line_check:
                check = False

    if check:
        Messaging.iprint(
            "{} DEF file is clean with all sub-block instances present in {} with valid coordinates\n".format(
                filename, os.path.basename(crrFile)
            )
        )


def _process_def_file_line(
    line, defFile, filename, def_ignore, crrFile, defLefs, defs, lefs, libs
) -> bool:
    """Processes a single line from a def file. Returns True if all checks passed."""
    subdef = ""
    check = True

    try:
        subblock = line.split(" ")[2].strip()
        if re.match(r"^\_", subblock):
            subblock = re.sub(r"^_", "", subblock)
    except IndexError:
        Messaging.eprint(
            f"Found '{line}' sub block with missing coordinates in def file '{defFile}'"
        )
        return False
    sublef = subblock + ".lef"
    if re.search("_top", subblock):
        subdef = subblock.replace("_top", "")
    else:
        subdef = subblock.split("_")
        if len(subdef) > 3:
            subdef = subdef[0] + "_" + subdef[1] + subdef[2] + "_" + subdef[3]
        else:
            subdef = "".join(subdef)
    if sublef in defLefs[filename]:
        return check
    defLefs[filename].append(sublef)
    if subblock + ".lef" not in lefs and subblock + ".lib" not in libs and subdef not in defs["Names"]:
        if subblock in def_ignore:
            Messaging.wprint(
                "Ignoring {} file from {} in {} as block is mentioned in defIgnore param in legalRelease.txt".format(
                    subblock, os.path.basename(defFile), os.path.basename(crrFile)
                )
            )
        else:
            Messaging.eprint(
                "Couldn't find {} file from {} in {}\n".format(
                    subblock, os.path.basename(defFile), os.path.basename(crrFile)
                )
            )
        check = False
    if re.search(r".+fixed|placed|cover.+\(\d+\s+\d+\).+", line, re.IGNORECASE) is None:
        Messaging.eprint(
            "-E- Found {} sub block with missing coordinates in {} file".format(
                subblock, os.path.basename(defFile)
            )
        )
        check = False
    return check


def _check_all_lef_files_found_in_defs(lefs: List, defLefs: Dict) -> None:
    """Checks if all lef files were found in def files."""
    for lef in lefs:
        if not any(x for x in defLefs.values() if lef in x):
            Messaging.eprint("{} file from CRR File not found in any def file".format(lef))


if __name__ == "__main__":
    main()
