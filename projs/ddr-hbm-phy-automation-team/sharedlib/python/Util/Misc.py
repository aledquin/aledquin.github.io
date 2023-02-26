#!/depot/Python/Python-3.8.0/bin/python
"""
Miscellaneous Utility Functions
"""
import __main__
import stat
import getpass
from typing import Dict, List, Iterator, Union, Tuple, Any
import subprocess
import os
import grp
from pathlib import Path
from datetime import datetime
import inspect
import re
import sys
import argparse
import atexit
import yaml
import json
import jsonschema

import Messaging
from Messaging import eprint, iprint, dprint, viprint, wprint, sysprint, fatal_error, Color
import CommonHeader
from CommonHeader import LOW, FUNCTIONS, HIGH, INSANE, EMPTY_STR, NULL_VAL


def setup_script(argparser: argparse.ArgumentParser, author: str, tool_name: str, cmdline_args: List[str] = None) -> argparse.Namespace:
    """
    Initial setup for a Python script.
    Parses command-line arguments using the given argparse.ArgumentParser
    See std_template.py for usage example.
    """
    args = argparser.parse_args(cmdline_args)
    log_file = f"{os.getcwd()}/{os.path.basename(__main__.__file__)}.log"
    Messaging.create_logger(log_file)  # Create log file

    # Register exit function
    atexit.register(Messaging.footer)

    version = get_release_version()
    CommonHeader.init(args, author, version)
    utils__script_usage_statistics(tool_name, version)

    Messaging.header()
    return args


def utils__script_usage_statistics(tool_name: str, version: str = None) -> None:
    """
    Gather run statistics for the script.
    """
    # Skip gathering usage info if environment variable is set
    # Usage should not be gathered for unit tests
    if os.environ.get("DDR_DA_SKIP_USAGE", None):
        return
    # Find version if not given
    if version is None:
        version = get_release_version()

    prefix = "ddr-da-"  # Prefix tool name to make it easier to find our scripts
    reporter = "/remote/cad-rep/msip/tools/bin/msip_get_usage_info"

    # Log launch arguments in Kibana
    launch_args = ' '.join(sys.argv[1:])
    launch_args = launch_args.replace('"', '\"').replace("'", "\'")  # Escape quotes
    launch_args = f'"{launch_args}"'

    tool_path = os.path.dirname(sys.argv[0])
    cmd = [
        reporter,
        "--tool_name",
        f"{prefix}{tool_name}",
        "--stage",
        "main",
        "--category",
        "ude_ext_1",
        "--tool_path",
        tool_path,  # TODO, figure out tool path;
        "--tool_version",
        version,
        "--command",
        launch_args,
    ]
    run_system_cmd(' '.join(cmd), CommonHeader.NONE)


# Aliases to built-ins to mirror Perl and TCL libs
get_max_val = max
get_min_val = min


def _print_system_cmd_diagnostics(verbosity: int, command: str, stdout: str, stderr: str, exit_val: int) -> None:
    """Print diagnostic info after running a system command."""
    if verbosity >= LOW and exit_val == 0:

        if stdout is not EMPTY_STR:
            iprint("\tStdOut ==> stdout\n")

        if stderr is not EMPTY_STR:
            eprint("\tStdErr ==> stderr\n")

        iprint("Success!\n")

    # Dump information based on defined LOW verbosity
    if verbosity >= LOW and verbosity < HIGH and exit_val != 0:

        if exit_val < 0:  # Failed to start program
            eprint(f"Negative return status. '{command}': {stderr}\n")

        else:  # Check for non-zero signal
            eprint(f"'{command}' died with return code {exit_val}\n")

    # Dump information based on defined HIGH verbosity
    if verbosity >= HIGH and exit_val != 0:
        eprint(
            f"System CMD failed!\n\tCmd\t===>'{command}'\n"
            + f"\tStdOut\t===>'{stdout}'\n\tStdErr\t===>'{stderr}'\n"  # noqa W504
            + f"\tExit Val===>'{exit_val}'\n"  # noqa W504
        )


def run_system_cmd(command: str, verbosity: int, binary: bool = False) -> Tuple[str, str, int]:
    """
    Run a system command and return stdout, stderr and the return code.
    Set 'binary' to True to keep stdout and stderr in binary format (not decoded).
    """
    if type(verbosity) != int:
        return (NULL_VAL, NULL_VAL, CommonHeader.NONE)

    if command is EMPTY_STR:
        return (NULL_VAL, NULL_VAL, CommonHeader.NONE)

    if verbosity >= LOW:
        sysprint(f"Running system command: '{command}' ...")
    if verbosity >= FUNCTIONS:
        call_stack = '\n'.join([f"\t{x.filename}, line {x.lineno}, in {x.function}" for x in reversed(get_call_stack())])
        sysprint(f"Call stack:\n{call_stack}")

    completed_process = subprocess.run(command, capture_output=True, text=not binary, shell=True)

    # Obtain the exit value and standard output and error
    exit_val = completed_process.returncode
    stdout = completed_process.stdout
    stderr = completed_process.stderr
    _print_system_cmd_diagnostics(verbosity, command, stdout, stderr, exit_val)

    return (stdout, stderr, exit_val)


def get_call_stack() -> List[inspect.FrameInfo]:
    """
    Returns the last 3 stack frames (excluding this function)
    Each frame has the following available:
        frame, filename, lineno, function, code_context, index
    """
    return inspect.stack(0)[1:4]


def get_subroutine_name() -> str:
    """Returns the name of the calling function."""
    return inspect.stack(0)[-2].function


def get_caller_sub_name() -> str:
    """Returns the name of the function that called the function that called get_caller_sub_name()"""
    return inspect.stack(0)[-1].function


def find_keys_missing_in_dict(dictionary: Dict, keys: List) -> List:
    """Returns a list of all keys in dictionary that are not in 'keys'."""
    return [k for k in keys if k not in dictionary]


def read_file(
    file_path: os.PathLike, error_message_prefix: str = "Unable to read file:"
) -> Iterator[str]:
    """
    Read a file and return an iterator to the file's lines.
    Note: lines are read on demand. To use read_file() as a list directly,
          do this: list(read_file("example.txt"))
    """
    # Convert to Path object in case file_path is a str
    if not isinstance(file_path, Path):
        file_path = Path(file_path)

    dprint(INSANE + 100, f"Reading file: '{file_path}'")

    if not file_path.exists():
        eprint(f"{error_message_prefix} File does not exist: {file_path}")
        return

    if not file_path.is_file():
        eprint(f"{error_message_prefix} Path does not lead to a file: {file_path}")
        return

    if not os.access(file_path, os.R_OK):
        permissions = oct(os.stat(file_path)[stat.ST_MODE])
        groups = [grp.getgrgid(g).gr_name for g in os.getgroups()]
        eprint(
            f"{error_message_prefix} "
            f"File is not readable: {file_path}\n"
            f"The permissions for this file are: {permissions[-3:]}\n"
            f"You are user: {get_username()} and are in groups: {groups}\n"
            f'Please change permissions using the command "chmod ug+r {file_path}"'
        )
        return

    try:
        with file_path.open("r") as fh:
            # TODO: handle encoding errors?
            for line in fh:
                yield line.rstrip()
    except Exception as exception:
        eprint(f"{error_message_prefix} {file_path}")
        dprint(
            HIGH,
            f"Something went wrong when reading file '{file_path}'\n"
            f"Error: {exception}\n"
            f"Please contact a developer.",
        )
        return NULL_VAL
    viprint(LOW, f"File read successful: {file_path}")


def write_file(
    contents: Union[str, List[str]],
    file_path: os.PathLike,
    mkdir: bool = False,
) -> None:
    """
    Writes 'contents' to a file at 'file_path'. 'contents' can be a string or a list of strings.
    If 'mkdir' is True, the file's parent directories will be created.
    If the file already exists, the file is overwritten.
    """
    # TODO: from Misc.pm: print_function_header()
    # TODO: writeOptions?
    # Convert to Path object in case file_path is a str
    if not isinstance(file_path, Path):
        file_path = Path(file_path)

    dprint(INSANE + 100, f"Writing file: '{file_path}'")

    if not file_path.parent.is_dir():
        # Parent dir(s) don't exist
        if not mkdir:
            raise Exception(
                f"Cannot write to file at '{file_path}'\n"
                f"Parent directories do not exist.\n"
                f"Set 'mkdir' to True to create parent directories."
            )
        file_path.parent.mkdir(parents=True, exist_ok=True)

    # If contents is a string, split on newline
    if isinstance(contents, str):
        contents = contents.splitlines(keepends=True)

    if file_path.is_file():
        wprint(f"File already exists... overwriting: '{file_path}'")

    try:
        with file_path.open("w") as fh:
            fh.writelines(contents)
    except Exception as exception:
        raise Exception(
            f"Unable to write to file '{file_path}'\nError: {exception}"
        ) from exception

    viprint(LOW, f"File write successful: {file_path}")


def get_username() -> str:
    """
    Returns the user running the script.
    Looks for the user name in the following env variables:
        $LOGNAME, $USER, $LNAME, $USERNAME
    If the user still cannot be found, the user tied to the process is used.
    """
    return getpass.getuser()


def _find_script_bin_dir() -> Path:
    """
    Returns the path to the current script's directory.
    Example:
        Current script = $REPO_TOP/ddr-ckt-rel/dev/main/bin/example.py
        Script bin dir = $REPO_TOP/ddr-ckt-rel/dev/main/bin
    """
    return Path(__main__.__file__).resolve().parent


def get_release_version(script_bin_dir: os.PathLike = None) -> str:
    """
    Returns the release version of the current toolset.
    Uses an external Perl script to find a ".version" file in the "bin" directory.
    Set script_bin_dir to force using a specific "bin" directory
    """
    release_version_finder = "{0}/da_get_release_version.pl {0}"
    if script_bin_dir is not None:
        release_version_finder = release_version_finder.format(script_bin_dir)
    else:
        # Attempt to find bin directory
        bin_dir = _find_script_bin_dir()
        release_version_finder = release_version_finder.format(bin_dir)

    if not os.path.isfile(release_version_finder.split()[0]):
        eprint(
            f"Could not find release version helper script. "
            f"Command: {release_version_finder}"
        )

    latest_release_version, _, _ = run_system_cmd(release_version_finder, LOW)
    return latest_release_version.strip()


def get_the_date() -> List[str]:
    """
    Returns the current date as a list of strings.
    For more information on datetime string format:
        https://docs.python.org/3/library/datetime.html#strftime-strptime-behavior
    Example:
        now = Wed Sep 28 16:34:08 2022
        returns ['Wed', 'Sep', '28', '16:34:08', '2022']
    """
    now = datetime.now().strftime("%a %b %d %H:%M:%S %Y")
    return now.split()


def prompt_before_continue(halt_level: int = None) -> None:
    """Prompt the user before continuing the program."""
    if os.environ.get("DA_RUNNING_UNIT_TESTS", None):
        return

    if halt_level is None:
        halt_level = CommonHeader.NONE

    if CommonHeader.DEBUG >= halt_level:
        print(f"{Color.RED}Hit ENTER to continue ...{Color.RESET}")
        input()


def create_matching_directories(dir: str) -> None:
    """Creates a directory and its parent directories."""
    try:
        os.makedirs(dir)
    except FileExistsError:
        dprint(HIGH, f"Directory {dir} already exists.")


def change_to_directory(root: str, dir: str) -> None:
    """Changes current working dir to 'root'/'dir'."""
    try:
        os.chdir(f"{root}/{dir}")
        dprint(HIGH, f"Changed CWD to: {os.getcwd()}")
    except Exception as e:
        fatal_error(str(e))


def first_available_file(file_paths: List[os.PathLike]) -> Path:
    """
    Returns the first file path that exists in the given list.
    Raises FileNotFoundError if no files exist
    """
    for file_path in file_paths:
        if not isinstance(file_path, Path):
            file_path = Path(file_path)

        if file_path.suffix == '.yml' and os.environ.get("DDR_DA_SKIP_YAML_FIRSTAVAILABLEFILE", None):
            # Skip YAML files
            continue

        if file_path.is_file():
            return file_path

    raise FileNotFoundError(f"No files exist in list: {', '.join([str(x) for x in file_paths])}")


def _legalReleaseParse(legal_release: os.PathLike) -> Tuple[str]:
    """
    DEPRECATED -- Please use read_legal_release() instead!
    This function performs parsing of the legalrelease file and finds the rel number and
    p4_release_root, returning it in a tuple
    """
    info = {}

    if not isinstance(legal_release, Path):
        legal_release = Path(legal_release)

    f = read_file(legal_release)
    for line in f:
        rel = re.findall(r"set rel\s+\"(\d\S+\w)\"", line)
        if rel:  # test regex grouping
            info["rel"] = rel[0]
        root = re.findall(r"set p4_release_root \"(products\/.+\d)\"", line)
        if root:
            info["p4_release_root"] = root[0]
        if len(info) > 2:
            break
    return info


def read_legal_release(legal_release_path: os.PathLike, validate: bool = False) -> Dict[str, Any]:
    """
    Reads a legal release file in YAML or TCL format.
    Returns a dictionary representation of the legal release.
    """
    if not isinstance(legal_release_path, Path):
        legal_release_path = Path(legal_release_path)

    if not legal_release_path.is_file():
        raise FileNotFoundError(f"Could not find legal release file at '{legal_release_path}'")

    if legal_release_path.suffix not in [".yml", ".yaml"]:
        # Use old TCL parsing function
        loaded_legal_release = _legalReleaseParse(legal_release_path)
    else:
        with open(legal_release_path, "r") as yaml_file:
            try:
                loaded_legal_release = yaml.safe_load(yaml_file)
            except Exception as exception:
                raise Exception(
                    f"Failed to load YAML legal release at {legal_release_path}\n"
                    f"See 'admin/samples/legalRelease.yml' for an example.\n"
                    f"\t{exception}"
                ) from exception

    if validate:
        _validate_legal_release(loaded_legal_release, legal_release_path)
    return loaded_legal_release


def _validate_legal_release(loaded_legal_release: Dict, legal_release_path: os.PathLike) -> None:
    """Validates an already loaded legal release using a JSON schema"""
    repo_top = Path(__file__).resolve().parent.parent.parent.parent
    legal_release_schema = repo_top / "admin/samples/legalReleaseSchema.json"

    with open(legal_release_schema, "r") as schema_file:
        loaded_schema = json.load(schema_file)

    try:
        jsonschema.validate(loaded_legal_release, schema=loaded_schema)
    except jsonschema.ValidationError as exception:
        fatal_error(
            f"Legal release schema validation failed!\n"
            f"\tLegal release: '{legal_release_path}'\n"
            f"\tSchema       : '{legal_release_schema}'\n\n"
            f"{exception}"
        )


def parse_project_spec(project_string: str) -> Tuple[str, str, str]:
    """
    Parses a project string into three parts:
        1. Project type (family)
        2. Project name
        3. PCS release
    Example project string: lpddr54/d890-lpddr54-tsmc5ff-12/rel1.00_cktpcs
        1. lpddr54
        2. d890-lpddr54-tsmc5ff-12
        3. rel1.00_cktpcs
    """
    try:
        family, project, release = project_string.split("/")
    except ValueError as exception:
        raise ValueError(
            "Invalid project string, expected format 'family/project/release'. "
            "Example: lpddr54/d890-lpddr54-tsmc5ff-12/rel1.00_cktpcs"
        ) from exception

    return family, project, release
