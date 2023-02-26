############################################################
#  Constants to be used in all new scripts
#  Author : Harsimrat Singh Wadhawan
############################################################
import re
import sys
from datetime import datetime
import __main__
import argparse

# ------------------------
# Debug Diagnostic Levels
# ------------------------
NONE = 0
LOW = 1
MEDIUM = 2
FUNCTIONS = 3
HIGH = 4
SUPER = 5
CRAZY = 6
INSANE = 100


# ------------------------
# Debug Diagnostic Levels
# ------------------------
NULL_VAL = "N/A"
NFS = re.compile("[^/]+")
EMPTY_STR = ""
TRUE = True
FALSE = False
DEBUG = NONE
VERBOSITY = NONE


class RunTimeStats:
    """Container for 'global' runtime statistics like start/end time."""

    start_time: datetime = datetime.now()
    _end_time: datetime = None

    @staticmethod
    def end_time() -> datetime:
        """Sets end_time to "now" and returns it."""
        if RunTimeStats._end_time is not None:
            return RunTimeStats._end_time
        RunTimeStats._end_time = datetime.now()
        return RunTimeStats._end_time

    @staticmethod
    def elapsed_time() -> datetime:
        """Returns the time elapsed between start_time."""
        return RunTimeStats.end_time() - RunTimeStats.start_time


def program_name() -> str:
    """Returns the name of the currently executed program (script)."""
    if "PROGRAM_NAME" in globals() and PROGRAM_NAME:
        return PROGRAM_NAME
    return __main__.__file__


def init(args: argparse.Namespace, __author__: str, __version__: str) -> None:
    """Define shared variables."""
    global DEBUG
    global VERBOSITY
    global PROGRAM_NAME
    global VERSION
    global AUTHOR
    global FPRINT_NOEXIT

    DEBUG = args.d
    VERBOSITY = args.v
    PROGRAM_NAME = sys.argv[0]
    VERSION = __version__
    AUTHOR = __author__
