#!/depot/Python/Python-3.8.0/bin/python
"""
Name    : method_priority_table.py
Author  : alvaro
Date    : 2023-01-23
Purpose : This script makes a CSV file to analyze priority level for methods being used.
Modification History
    000 alvaro  2023-01-23
        Created this script

"""

__author__ = "alvaro"
__tool_name__ = "user"  # Ex: ddr-da-tpl

import argparse
import atexit
import os
import pathlib
import sys

bindir = str(os.path.abspath(''))
# Add path to library that may be symbolically linked.
sys.path.append(bindir + "/../lib/Util")
# Add path to sharedlib's Python Utilities directory.
sys.path.append(bindir + "/../lib/python/Util")


# Import common constants
from CommonHeader import (NONE, INSANE, CRAZY, NFS, NULL_VAL, EMPTY_STR)

# Import messaging functions
from Messaging import (
    iprint,
    eprint,
    hprint,
    fatal_error,
    p4print,
    viprint,
    vhprint,
    vwprint,
    veprint,
    dprint,
)

# Import other logging functions
import Messaging

# Import miscellaneous utilities
import Misc
import CommonHeader

# Disable exiting when fatal_error is invoked
CommonHeader.FPRINT_NOEXIT = 1


def parse_args() -> argparse.Namespace:
    """Parse command-line arguments."""
    # Always include -v, and -d
    parser = argparse.ArgumentParser(description="description here")
    parser.add_argument("-v", metavar="<#>", type=int, default=0, help="verbosity")
    parser.add_argument("-d", metavar="<#>", type=int, default=0, help="debug")

    # Add your custom arguments here
    # -------------------------------------

    # -------------------------------------
    args = parser.parse_args()
    return args


def main() -> None:
    """Main function."""

    tool_dir = pathlib.Path



if __name__ == "__main__":
    args = parse_args()
    filename = os.getcwd() + "/" + os.path.basename(__file__) + ".log"
    logger = Messaging.create_logger(filename)  # Create log file

    # Register exit function
    atexit.register(Messaging.footer)

    # Initalise shared variables and run main
    version = Misc.get_release_version()
    CommonHeader.init(args, __author__, version)

    Misc.utils__script_usage_statistics(__tool_name__, version)
    Messaging.header()
    main()
    iprint(f"Log file: {filename}")
