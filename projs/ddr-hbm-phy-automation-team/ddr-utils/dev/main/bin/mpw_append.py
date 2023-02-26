#!/depot/Python/Python-3.8.0/bin/python
"""
Name    : mpw_append.py
Author  : Angelina Chan
Date    : July 25, 2022
Purpose : Script for appending seperate MPW '.csv' files in a directory or
          multiple directories into one '.csv' or '.xlsx' file.
"""

import argparse
import atexit
import os
import pathlib
import sys
import glob

import pandas as pd

# ---------------------------------- #
bindir = str(pathlib.Path(__file__).resolve().parent)
# Add path to library that may be symbolically linked.
sys.path.append(bindir + "/../lib/Util")
# Add path to sharedlib's Python Utilities directory.
sys.path.append(bindir + "/../lib/python/Util")
# ---------------------------------- #

from CommonHeader import LOW, MEDIUM, HIGH
from CommonHeader import NULL_VAL
from Messaging import iprint, hprint, fatal_error, wprint
from Messaging import dprint
from Messaging import create_logger, footer, header
from Misc import utils__script_usage_statistics, get_release_version, write_file
import CommonHeader
from P4Utils import da_p4_create_instance, da_p4_files, da_p4_print_p4_file

__author__ = "Angelina Chan"
__tool_name__ = "mpw_append"


def parse_args():

    # Always include -v, and -d
    parser = argparse.ArgumentParser(
        description=(
            "Script for appending all seperate MPW '.csv' files "
            "in a folder into one '.csv' or '.xlsx' file"
        ),
        usage='use "--help" for more information',
    )
    parser.add_argument(
        "-v",
        metavar="<#>",
        type=int,
        default=0,
        help="Enables verbosity messages. LOW = 1, MEDIUM = 2, HIGH = 4",
    )
    parser.add_argument(
        "-d",
        metavar="<#>",
        type=int,
        default=0,
        help="Enables debug messages. LOW = 1, MEDIUM = 2, HIGH = 4",
    )

    # Add your custom arguments here
    # -------------------------------------
    parser.add_argument(
        "-i",
        "--input",
        nargs="+",
        help=(
            "REQUIRED. Local or Perforce input folder path(s). "
            "Can parse multiple input directories and inputs with *."
            "Usage example: "
            "/depot/Python/Python-3.8.0/bin/python mpw_append.py"
            " -i to/path1 to/path2"
        ),
        required=True,
    )
    parser.add_argument(
        "-o",
        "--output",
        default=None,
        help=(
            "OPTIONAL. Output file directory. "
            "Default output directory is the"
            "directory where the script was run"
        ),
        required=False,
    )
    parser.add_argument(
        "-n",
        "--name",
        default=None,
        help="OPTIONAL. Output file name, default name is MPW.csv",
        required=False,
    )
    parser.add_argument(
        "--overwrite",
        help=(
            "OPTIONAL. Enables overwriting files with the same name as"
            "the output file in the output directory, disabled by default"
        ),
        required=False,
        action="store_true",
    )
    parser.add_argument(
        "-e",
        "--excel",
        help=(
            "OPTIONAL. Changes output file type to excel,"
            " default file type is .csv"
        ),
        required=False,
        action="store_true",
    )
    # -------------------------------------
    args = parser.parse_args()
    return args


def main(args):

    input_paths = args.input
    overwrite = args.overwrite
    file_type = args.excel

    output_path, file_name = default_values(args)

    check_overwrite(output_path, file_name, overwrite)

    p4_path, is_file = try_path(input_paths, output_path)

    dataframe = concatenate_data(input_paths, p4_path, is_file)

    export_file(dataframe, output_path, file_name, file_type)

    hprint(f"Complete: {file_name} created at '{os.path.abspath(output_path)}'")


def default_values(args):
    if args.output is None:
        wprint(
            f"Output path not specified, defaulting to '{os.getcwd()}'",
        )
        output_path = os.getcwd()
    else:
        output_path = args.output

    if args.name is None:
        if args.excel == 0:
            wprint(
                "Output file name not specified, defaulting to 'MPW.csv'",
            )
            file_name = "MPW.csv"
        else:
            wprint(
                "Output file name not specified, defaulting to 'MPW.xlsx'",
            )
            file_name = "MPW.xlsx"
    else:
        file_name = file_extension(args.name, args.excel)
    return output_path, file_name


def is_file_local(input_path):
    # check if the path provided is a directory or a file,
    # if file then append only the file and not whole folder
    if (os.path.isfile(input_path)) or input_path.endswith(
        (".csv", ".xlsx")
    ):  # check local file
        # is file
        dprint(HIGH, f"\tos.path.isfile: {os.path.isfile(input_path)}")
        is_file = True
        dprint(HIGH, f"\tis_file: {is_file}")
    else:
        # is directory
        dprint(HIGH, f"\tos.path.isfile: {os.path.isfile(input_path)}")
        is_file = False
        dprint(HIGH, f"\tis_file: {is_file}")
    return is_file


def is_file_p4(input_path):
    # check if the path provided is a directory or a file,
    # if file then append only the file and not whole folder
    file = da_p4_print_p4_file(input_path)
    condition = NULL_VAL != file and not input_path.endswith("...")
    if condition or input_path.endswith((".csv", ".xlsx")):
        # is file
        is_file = True
    else:
        # is directory
        is_file = False
    return is_file


def check_path(input_path, output_path):
    # checks if paths exist
    if os.path.isdir(input_path) and os.path.isdir(output_path):
        dprint(HIGH, "Checking for .csv files in directory")
        if not any(fname.endswith(".csv") for fname in os.listdir(input_path)):
            raise FileNotFoundError(
                f"Input directory, '{input_path}', does not contain .csv files"
            )
    if not (os.path.isdir(input_path) or os.path.isdir(output_path)):
        raise FileNotFoundError("Input and output directories do not exist")
    elif os.path.isdir(output_path):
        raise FileNotFoundError(
            f"Input directory, '{input_path}', does not exist"
        )
    else:
        raise FileNotFoundError(
            f"Output directory, '{output_path}', does not exist"
        )


def p4_dir(input_path):
    if input_path.endswith("/..."):
        p4_path = input_path
        # P4 path needs to end with /... to list files in directory
    elif input_path.endswith("/"):
        p4_path = input_path + "..."
    else:
        p4_path = input_path + "/..."
    return p4_path


def check_p4(input_path, output_path):
    p4_path = p4_dir(input_path)
    files = da_p4_files(p4_path)
    if (not os.path.isdir(output_path)) and (NULL_VAL == files):
        raise FileNotFoundError("Input and output directories do not exist")
    elif NULL_VAL == files:
        # when path does not exist, da_p4_files() will return NULL_VAL
        raise FileNotFoundError(
            f"Perforce input directory, '{input_path}', does not exist"
        )
    elif not os.path.isdir(output_path):
        raise FileNotFoundError(
            f"Output directory, '{output_path}', does not exist"
        )
    else:
        dprint(HIGH, "Checking for .csv files in p4 directory")
        count = 0
        for file in files:
            file_split = file.split(".")
            file_ext = file_split[len(file_split) - 1]
            if file_ext.endswith("csv") or file_ext.startswith("csv"):
                dprint(HIGH, f"\t.csv file found, {file}")
                count += 1
        if count == 0:
            raise FileNotFoundError(
                f"Input directory, '{input_path}', does not contain .csv files"
            )


def check_file(input_path, output_path):
    if not (os.path.isfile(input_path) or os.path.isdir(output_path)):
        raise FileNotFoundError("Input file and output directory do not exist")
    elif not os.path.isfile(input_path):
        raise FileNotFoundError(f"Input file, '{input_path}', does not exist")
    elif not os.path.isdir(output_path):
        raise FileNotFoundError(
            f"Output directory, '{output_path}', does not exist"
        )


def check_file_p4(input_path, output_path):
    file = da_p4_print_p4_file(input_path)
    if (not os.path.isdir(output_path)) and (NULL_VAL == file):
        raise FileNotFoundError("Input file and output directory do not exist")
    elif NULL_VAL == file:
        # when path does not exist, da_p4_files() will return NULL_VAL
        raise FileNotFoundError(
            f"Input perforce file, '{input_path}', does not exist"
        )
    elif not os.path.isdir(output_path):
        raise FileNotFoundError(
            f"Output directory, '{output_path}', does not exist"
        )


def try_path(input_paths, output_path):
    p4_path = []
    is_file = []
    for path in range(len(input_paths)):
        try:
            if input_paths[path].startswith("//"):
                dprint(
                    HIGH,
                    (
                        f"{input_paths[path]} is file?"
                        f" {is_file_p4(input_paths[path])}"
                    ),
                )
                if is_file_p4(input_paths[path]) is False:
                    check_p4(input_paths[path], output_path)
                else:
                    check_file_p4(input_paths[path], output_path)
                p4_path.append(True)
                is_file.append(is_file_p4(input_paths[path]))
            else:
                dprint(
                    HIGH,
                    (
                        f"{input_paths[path]} is file?"
                        f" {is_file_local(input_paths[path])}"
                    ),
                )
                if is_file_local(input_paths[path]) is False:
                    check_path(input_paths[path], output_path)
                else:
                    check_file(input_paths[path], output_path)
                p4_path.append(False)
                is_file.append(is_file_local(input_paths[path]))
        except FileNotFoundError as error:
            fatal_error(f"Fatal error. {repr(error)}. Exiting...")
    return p4_path, is_file


def check_overwrite(output_path, file_name, overwrite):
    file_output = os.path.join(output_path, file_name)
    dprint(MEDIUM, f"Overwrite enabled? {overwrite}")
    dprint(MEDIUM, f"Output file exists already? {os.path.isfile(file_output)}")
    try:
        if os.path.isfile(file_output) and (overwrite is False):
            raise FileExistsError(f"File '{file_name}' exists: '{file_output}'")
        elif os.path.isfile(file_output):
            wprint(f"File '{file_name}' exists. Overwriting...")
    except FileExistsError as error:
        fatal_error(
            (
                f"Fatal error. {str(error)}\n"
                "Please choose a different file name or enable overwriting"
                "in the command line with '--overwrite'. Exiting..."
            ),
        )


def export_file(dataframe, output_path, file_name, file_type):
    # Export file
    if file_type is False:
        dataframe.to_csv(os.path.join(output_path, file_name), index=False)
    else:
        dataframe.to_excel(os.path.join(output_path, file_name), index=False)


def concatenate_data(input_path, p4_path, is_file):
    all_data = []
    for path in range(len(input_path)):
        # Variable to hold the data from input files in input one directory
        data = []
        if not p4_path[path]:
            dprint(HIGH, f"Local input path: '{input_path[path]}'")
            if not is_file[path]:
                for f in glob.glob(os.path.join(input_path[path], "*.csv")):
                    data.append(pd.read_csv(f, header=0))  # Appending data
                    data_f = pd.concat(data)
            else:
                data.append(pd.read_csv(input_path[path], header=0))
                data_f = pd.concat(data)
        else:
            dprint(HIGH, f"Perforce input path: '{input_path[path]}'")
            if not is_file[path]:
                data = p4_data_dir(input_path[path])
            else:
                data = p4_data_file(input_path[path])
            data_f = pd.concat(data)
        all_data.append(data_f)
    dataframe = pd.concat(all_data, ignore_index=True)
    return dataframe


def p4_data_dir(input_path):
    # if input path is directory
    dprint(LOW, f"{input_path} is a directory")
    data = []
    temp = "temp_file_mpw.csv"
    p4_path = p4_dir(input_path)

    # array of all the paths to all the files in 'input_path'
    file_list = da_p4_files(p4_path)

    # when path does not exist, da_p4_files() will return NULL_VAL
    if NULL_VAL == file_list:
        fatal_error(f"Perforce path '{p4_path}' does not exist")

    dprint(HIGH, f"List of files in '{p4_path}':\n{file_list}")
    csv_list = []
    for file in file_list:
        file_split = file.split(".")
        file_ext = file_split[len(file_split) - 1]
        if file_ext.endswith("csv") or file_ext.startswith("csv"):
            dprint(HIGH, f"\t.csv file found, {file}")
            csv_list.append(file)
    for csv in csv_list:
        file_contents = da_p4_print_p4_file(csv)
        # when path does not exist, da_p4_files() will return NULL_VAL
        if NULL_VAL == file_contents:
            fatal_error(f"Failed to print '{csv}'")
        else:
            write_file(file_contents, temp)
            dprint(MEDIUM, f"temporary file '{temp}' created/overwritten")
            new_path = os.path.abspath(f"{temp}")
            data.append(pd.read_csv(new_path, header=0))
            remove_file(temp)
    return data


def p4_data_file(input_path):
    # if input path is a file
    data = []
    temp = "temp_file_mpw.csv"
    file_content = da_p4_print_p4_file(input_path)
    # when file does not exist or cannot be accessed,
    # da_p4_print_p4_file() will return NULL_VAL
    if NULL_VAL == file_content:
        remove_file(temp)
        fatal_error(f"Failed to print '{input_path}'")
    else:
        write_file(file_content, temp)
        dprint(MEDIUM, f"temporary file '{temp}' created/overwritten")
        new_path = os.path.abspath(temp)
        data.append(pd.read_csv(new_path, header=0))
        remove_file(temp)
    return data


def remove_file(file_name):
    file_path = os.path.join(os.getcwd(), file_name)
    if os.path.isfile(file_path):
        os.unlink(file_path)
        dprint(LOW, f"removed temporary file '{file_path}'")


def file_extension(file_name, excel):
    if excel == 0:
        dprint(MEDIUM, "Output file will be '.csv'")
        if file_name.endswith(".csv"):
            return file_name
        else:
            return file_name + ".csv"
    else:
        dprint(MEDIUM, "Output file will be '.xlsx'")
        if not file_name.endswith(".xlsx"):
            file_name = file_name + ".xlsx"
    return file_name


if __name__ == "__main__":

    args = parse_args()
    filename = os.path.basename(__file__) + ".log"
    logger = create_logger(filename)  # Create log file

    # Register exit function
    atexit.register(footer)

    # Initalise shared variables and run main
    version = get_release_version()
    CommonHeader.init(args, __author__, version)

    header()
    da_p4_create_instance()
    dprint(MEDIUM, "P4 instance created")
    main(args)
    iprint(f"Log file: {filename}")

    utils__script_usage_statistics(__tool_name__, version)
