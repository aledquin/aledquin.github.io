#!/depot/Python/Python-3.10/bin/python
"""
<SHORT SCRIPT DESCRIPTION>
"""

__author__ = "<YOUR USERNAME>"
__tool_name__ = "ddr-da-standard-template-py"  # Replace "standard-template-py" with your tool's name
__description__ = "<DOCUMENT PURPOSE AND USAGE OF THIS SCRIPT>"

import argparse
import pathlib
import sys
from typing import List

BIN_DIR = str(pathlib.Path(__file__).resolve().parent)
# Add path to Python sharedlib
sys.path.append(BIN_DIR + "/../lib/Util")
sys.path.append(BIN_DIR + "/../lib/python/Util")

import CommonHeader
import Misc
import Messaging


def _create_argparser() -> argparse.ArgumentParser:
    """Initialize an argument parser. Arguments are parsed in Misc.setup_script"""
    # Always include -v and -d arguments
    parser = argparse.ArgumentParser(description=__description__)
    parser.add_argument("-v", metavar="<#>", type=int, default=0, help="Verbosity")
    parser.add_argument("-d", metavar="<#>", type=int, default=0, help="Debug")

    # Add your custom arguments here
    # -------------------------------------

    return parser


def main(cmdline_args: List[str] = None) -> None:
    """Main function."""
    argparser = _create_argparser()
    args = Misc.setup_script(argparser, __author__, __tool_name__, cmdline_args)

    # ----------  YOUR CODE GOES HERE  ----------


if __name__ == "__main__":
    main(sys.argv[1:])
