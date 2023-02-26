###############################################################################
# Python Messaging Module
# Author: Harsimrat Singh Wadhawan
#
# -Based on ddr sharedlib's Messaging.pm
###############################################################################

import os
from pathlib import Path
import sys
import logging
from enum import Enum
import re
import inspect
from contextlib import contextmanager
import getpass

import CommonHeader

# WARNING: DO NOT _LOGGER USE DIRECTLY!
_LOGGER = logging.getLogger(__name__)


class Color(Enum):
    """Helper class for ANSI color codes."""

    RESET = "\033[0m"
    RED = "\033[31m"
    GREEN = "\033[32m"
    YELLOW = "\033[33m"
    MAGENTA = "\33[35m"
    CYAN = "\033[36m"
    FAIL = "\033[37;41m"  # Red background, white text

    def __str__(self) -> str:
        """Use the color code as string value."""
        return self.value


def dprint(dbg, msg: str) -> None:
    if CommonHeader.DEBUG >= dbg:
        # Check debug instead
        _LOGGER.info(f"{Color.CYAN}-D- {msg}{Color.RESET}")


def viprint(dbg, msg: str) -> None:
    if CommonHeader.VERBOSITY >= dbg:
        _LOGGER.info("-I- " + msg)


def vhprint(dbg, msg: str) -> None:
    if CommonHeader.VERBOSITY >= dbg:
        _LOGGER.info(f"{Color.CYAN}-H- {msg}{Color.RESET}")


def vwprint(dbg, msg: str) -> None:
    if CommonHeader.VERBOSITY >= dbg:
        _LOGGER.info(f"{Color.YELLOW}-W- {msg}{Color.RESET}")


def veprint(dbg, msg: str) -> None:
    if CommonHeader.VERBOSITY >= dbg:
        _LOGGER.info(f"{Color.RED}-E- {msg}{Color.RESET}")


def iprint(msg: str) -> None:
    _LOGGER.info("-I- " + msg)


def nprint(msg: str) -> None:
    _LOGGER.info(msg)


def hprint(msg: str) -> None:
    _LOGGER.info(f"{Color.CYAN}-H- {msg}{Color.RESET}")


def wprint(msg: str) -> None:
    _LOGGER.info(f"{Color.YELLOW}-W- {msg}{Color.RESET}")


def eprint(msg: str) -> None:
    _LOGGER.info(f"{Color.RED}-E- {msg}{Color.RESET}")


def fatal_error(msg: str, exit_status: int = 1) -> None:
    _LOGGER.info(f"{Color.FAIL}-F- {msg}{Color.RESET}")

    if not hasattr(CommonHeader, "FPRINT_NOEXIT") or not CommonHeader.FPRINT_NOEXIT:  # noqa E401
        sys.exit(exit_status)  # [1 --> Error], [0 --> success]


def fprint(msg: str, exit_status: int = 1) -> None:
    _LOGGER.info(f"{Color.FAIL}-F- {msg}{Color.RESET}")


def p4print(msg: str) -> None:
    _LOGGER.info(f"{Color.GREEN}{msg}{Color.RESET}")


def gprint(msg: str) -> None:
    """Prints a message in GREEN."""
    _LOGGER.info(f"{Color.GREEN}{msg}{Color.RESET}")


def sysprint(msg: str) -> None:
    """Print a system call (regular print with '-S-' prefix."""
    _LOGGER.info(f"{Color.MAGENTA}-S- {msg}{Color.RESET}")


def header() -> None:
    """
    Print a standardized header. Make sure to call header() at the start of your script.
    """
    program_and_args = " ".join(sys.argv)
    author = "ddr-da team"
    version = CommonHeader.VERSION  # TODO: Use Misc.get_release_version
    user = getpass.getuser()

    # TODO need? Util::Misc::da_is_script_in_list_of_obsolete_versions( $scriptBin );
    delimiter_size = 55
    msg = (
        f"\n\n{'#'*delimiter_size}\n"
        f"###  Date , Time     : '{CommonHeader.RunTimeStats.start_time}'\n"
        f"###  Launch args     : '{program_and_args}'\n"
        f"###  Author          : '{author}'\n"
        f"###  Release Version : '{version}'\n"
        f"###  User            : '{user}'\n"
        f"{'#'*delimiter_size}\n\n"
    )
    nprint(msg)


def footer() -> None:
    """
    Print a standardized footer. Make sure to call footer() at the end of your script.
    """
    program_name = CommonHeader.program_name()
    version = CommonHeader.VERSION  # TODO: Use Misc.get_release_version

    delimiter_size = 55
    msg = (
        f"\n\n{'#'*delimiter_size}\n"
        f"###  Goodbye World\n"
        f"###  Date , Time     : '{CommonHeader.RunTimeStats.end_time()}'\n"
        f"###  End Running     : '{program_name}'\n"
        f"###  Elapsed (sec)   : '{CommonHeader.RunTimeStats.elapsed_time()}\n"
        f"###  Release Version : '{version}'\n"
        f"###  Log file path   : '{log_file_path()}'\n"
        f"{'#'*delimiter_size}\n\n"
    )
    nprint(msg)


class LogFileFormatter(logging.Formatter):
    """Removes ANSI color codes from logged messages."""

    def format(self, record: logging.LogRecord) -> str:
        """Remove color codes with regex."""
        record.msg = re.sub(r"\x1b\[[0-9;]*m", "", str(record.msg))

        if CommonHeader.DEBUG >= CommonHeader.HIGH:
            caller_info = self._caller_info()

            # Prevent adding caller info twice (happens with pytest)
            if not record.msg.startswith(caller_info):
                record.msg = self._caller_info() + record.msg

        return super().format(record)

    @staticmethod
    def _caller_info() -> str:
        """Finds info about the function that called a Messaging function."""
        caller_index = 11  # Skip calls to logger private functions
        call_stack = inspect.stack(context=0)
        if len(call_stack) >= caller_index:
            # TODO Add ALL levels of context
            caller = call_stack[caller_index]
            return f"{os.path.basename(caller.filename)}:{caller.function}:{caller.lineno} "
        return ""


@contextmanager
def no_stdout(logger: logging.Logger) -> None:
    """
    Context manager that disables stdout logging and then
    renables it.
    """
    disable_stdout(logger)
    yield
    enable_stdout(logger)


def log_file_path() -> Path:
    """Returns path to log file used by current logger."""
    if not _LOGGER or not _LOGGER.handlers or len(_LOGGER.handlers) < 2:
        return None
    return _LOGGER.handlers[1].baseFilename


def disable_stdout(logger: logging.Logger) -> None:
    """
    Disables stdout logging via StreamHandler
    """
    for handler in logger.handlers:
        if isinstance(handler,logging.StreamHandler):
            handler.setLevel(CommonHeader.INSANE)
        if isinstance(handler,logging.FileHandler):
            handler.setLevel(CommonHeader.NONE)


def enable_stdout(logger: logging.Logger) -> None:
    """
    Enables stdout logging via StreamHandler
    """
    for handler in logger.handlers:
        handler.setLevel(CommonHeader.NONE)


def create_logger(log_file: str) -> logging.Logger:
    """
    Returns a logger that prints to the terminal (with color)
    and logs to a file (without color codes).
    """
    global _LOGGER
    new_logger = logging.getLogger()
    new_logger.setLevel(CommonHeader.NONE)
    new_logger.handlers.clear()

    # Log to terminal
    stdout_handler = logging.StreamHandler(stream=sys.stdout)
    stdout_handler.setLevel(CommonHeader.NONE)
    new_logger.addHandler(stdout_handler)

    # Log to file and strip ANSI color codes
    log_file_handler = logging.FileHandler(log_file, mode="w")
    log_file_handler.setLevel(CommonHeader.NONE)
    log_file_handler.setFormatter(LogFileFormatter())
    new_logger.addHandler(log_file_handler)

    _LOGGER = new_logger
    return new_logger
