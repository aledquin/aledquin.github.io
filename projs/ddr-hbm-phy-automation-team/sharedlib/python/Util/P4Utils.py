"""
P4 functions
Author : Harsimrat Singh Wadhawan
"""
from P4 import P4
from Messaging import eprint, dprint
from CommonHeader import NULL_VAL, LOW, NONE, HIGH
from Misc import run_system_cmd
import Misc
from os.path import exists
import os
import re
import getpass


def da_p4_create_instance():
    """
    Returns a P4 object if successful.
    Otherwise, NULL_VAL is returned.
    """
    p4 = P4()  # Create the P4 instance

    try:
        p4.port = os.getenv("P4PORT")
    except AttributeError:
        eprint("Could not get P4PORT environment variable.")
        return NULL_VAL

    try:
        p4.client = os.getenv("P4CLIENT")
    except AttributeError:
        eprint("Could not get P4CLIENT environment variable.")
        return NULL_VAL

    p4.user = getpass.getuser()
    return p4


def da_p4_update_mapping(client, new_mapping):

    try:
        client["View"].append(new_mapping)
    except KeyError:
        client["View"] = [new_mapping]


def da_p4_add_to_changelist(p4, depotPath, file):
    """
    Add files to the default p4 changelist of a user
    p4 : Valid p4 object
    depotPath: Path in the depot where the file should be stored
    file: path of the file that needs to be added to the changelist
    """
    # -------------------------
    # Error checking
    # -------------------------

    if (exists(file) is False):
        eprint(f"Specified file does not exist at path: {file}")
        return NULL_VAL

    (out, err, ret) = run_system_cmd(f"p4 files {depotPath}/...", NONE)
    if ("no such file" in out or "no such file" in err):
        eprint(f"Depot path specified does not exist: {depotPath}")
        return NULL_VAL

    if (p4 is NULL_VAL or p4 is None or p4.connected() is False):
        eprint("P4 instance not initialised")
        return NULL_VAL
    else:
        dprint(HIGH, f"Connected to P4. {p4.client}")

    # -------------------------
    # Business Logic
    # -------------------------

    # Fetch client
    client = p4.fetch_client()

    # Obtain P4 client name
    client_name = p4.client

    try:
        root = client["Root"]
    except KeyError:
        eprint(f"Could not obtain workspace root for client {client_name}.")
        return NULL_VAL

    # Make directories matching the depotPath
    try:
        os.chdir(root)
        dprint(HIGH, f"Root client: {os.getcwd()}")
    except Exception as e:
        dprint(NONE, str(e))
        return NULL_VAL

    dir = re.sub(r"//", "", depotPath)
    dprint(LOW, dir)

    # Steps for submitting files to P4
    # 1. CD to the root.
    # 2. Add the log files to the appropriate depotPath.
    # 3. Submit changes.

    # Add the depotPath to the workspace map file
    target_dir = f"//{client_name}/{dir}"
    source_dir = f"//{dir}"

    # Create workspace mapping
    filename = os.path.basename(file)
    source_file = f"{source_dir}/{filename}"
    target_file = f"{target_dir}/{filename}"
    new_mapping = f"{source_file} {target_file}"

    # Update client mapping
    da_p4_update_mapping(client, new_mapping)
    p4.save_client(client)

    # Create directories for files
    Misc.create_matching_directories(dir)

    # Change directories for files
    Misc.change_to_directory(root, dir)

    # Copy and add file
    local_destination = f"{root}/{dir}/{filename}"
    add_command = f"p4 -c {client_name} add {filename}"
    edit_command = f"p4 -c {client_name} edit {filename}"
    sync_command = f"p4 sync {target_file}"

    # Synchronize the necessary files
    (out, err, ret) = run_system_cmd(sync_command, NONE)
    dprint(HIGH, f"err: '{err}'")
    dprint(HIGH, f"out: '{out}'")

    # If the file already exists in the depot, then it must be 'edit'ed.
    # Otherwise, it needs to be 'add'ed.
    (out, err, ret) = run_system_cmd(add_command, NONE)
    dprint(HIGH, f"err: '{err}'")
    dprint(HIGH, f"out: '{out}'")

    if ("not on client" in err or "not on client" in out or "can't add" in err or "can't add" in out):  # noqa E401
        (out, err, ret) = run_system_cmd(edit_command, NONE)
        dprint(HIGH, f"err: '{err}'")
        dprint(HIGH, f"out: '{out}'")

    # Copy the file to the temporary root directory and submit
    (out, err, ret) = run_system_cmd(f"cat {file} > {local_destination}", NONE)

    if (ret > 0):
        eprint(f"Error in copying file: {ret}")
        return NULL_VAL

    return new_mapping


def da_p4_print_p4_file(location, binary=False):
    """
    Print file specified via a P4 location.
    Inputs:
        location => p4 path of the file
        binary => (default value is False) if set to True, then the output will be
                    returned without being decoded as a string.
                    The binary option will return a byte array instead of a text
                    string. This is useful when you want to download files
                    from P4 that do not have an ASCII representation
                    (.pdf, .exe, .docx, etc.)
    Output:
        Standard output returned on success, otherwise NULL_VAL returned
        If the binary flag is set to True, then a byte_array of the standard
        output is returned
    """
    verbosity = NONE
    search_in_err = None
    search_in_out = None
    (std_out, std_err, return_val) = run_system_cmd(
        f"p4 print -q {location}", verbosity, binary=True)

    # Check to make sure that byte array can be decoded
    if (binary is False):

        try:
            std_out = std_out.decode('utf-8')
        except UnicodeDecodeError:
            dprint(HIGH, "Could not decode output byte array.")
            return NULL_VAL

        try:
            std_err = std_err.decode('utf-8')
        except UnicodeDecodeError:
            dprint(HIGH, "Could not decode error byte array.")
            return NULL_VAL

        search_in_err = re.search(r"no such file", std_err, re.IGNORECASE)
        search_in_out = re.search(r"no such file", std_out, re.IGNORECASE)

    dprint(HIGH, f"{std_err}\n")
    if (search_in_err or search_in_out):
        return NULL_VAL
    elif (return_val > 0):
        return NULL_VAL

    return std_out


def da_p4_files(location):
    """
    Print files in a P4 directory.
    Inputs:
        location => p4 path of the directory
    Output:
        Array of files found at the depot location
    """
    verbosity = NONE

    (std_out, std_err, return_val) = run_system_cmd(
        f"p4 files -e {location}", verbosity)
    search_in_err = re.search(r"no such file", std_err, re.IGNORECASE)
    search_in_out = re.search(r"no such file", std_out, re.IGNORECASE)

    dprint(HIGH, f"{std_err}\n")
    if (search_in_err or search_in_out):
        return NULL_VAL
    elif (return_val > 0):
        return NULL_VAL

    # Remove end-of-line comments
    return [re.sub(r'\#.*$', '', x) for x in std_out.splitlines()]


def da_p4_dirs(location):
    """
    Print directories in a P4 directory.
    Inputs:
        location => p4 path of the directory
    Output:
        Array of directories found at the depot location
    """
    verbosity = NONE

    (std_out, std_err, return_val) = run_system_cmd(
        f"p4 dirs {location}", verbosity)
    search_in_err = re.search(r"no such file", std_err, re.IGNORECASE)
    search_in_out = re.search(r"no such file", std_out, re.IGNORECASE)

    dprint(HIGH, f"{std_err}\n")
    if (search_in_err or search_in_out):
        return NULL_VAL
    elif (return_val > 0):
        return NULL_VAL

    # Remove end-of-line comments
    return [re.sub(r'\#.*$', '', x) for x in std_out.splitlines()]


def da_p4_dir_exists(path: str) -> bool:
    """Returns True if a directory exists in P4."""
    return not da_p4_dirs(path) == NULL_VAL


def da_p4_file_exists(path: str) -> bool:
    """Returns True if a file exists in P4."""
    return not da_p4_files(path) == NULL_VAL
