#!/depot/Python/Python-3.8.0/bin/python
###############################################################################
#
# Name    : pin_check__ckt_specs.py
# Author  : Mehak Kalra
# Date    : 20 July 2022
# Purpose : Script to extract pin check tables from specs
#
###############################################################################

import argparse
import atexit
import os
import pathlib
import pandas as pd
import numpy as np
from math import isnan
import docx
import re
import sys

# ---------------------------------- #
bindir = str(pathlib.Path(__file__).resolve().parent)
# Add path to library that may be symbolically linked.
# sys.path.append(bindir + '/../lib/Util')
# Add path to sharedlib's Python Utilities directory.
sys.path.append(bindir + "/../lib/python/Util")
# ---------------------------------- #


from Messaging import iprint, fatal_error, eprint, dprint, nprint, hprint
from Messaging import create_logger, no_stdout, footer, header
from P4Utils import da_p4_create_instance
from Misc import (
    run_system_cmd,
    utils__script_usage_statistics,
    get_release_version,
)
from P4 import P4Exception
import CommonHeader
from CommonHeader import NULL_VAL, LOW, MEDIUM, HIGH, CRAZY


__author__ = "Mehak Kalra"
__version__ = get_release_version()


def parse_args():

    # Always include -v, and -d
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "-v", metavar="<#>", type=int, default=0, help="verbosity"
    )
    parser.add_argument("-d", metavar="<#>", type=int, default=0, help="debug")

    # Add your custom arguments here
    # -------------------------------------
    parser.add_argument(
        "path_spec", metavar="path_spec", help="Path of the spec file"
    )
    parser.add_argument(
        "pin_path", metavar="pin_path", help="Path of the pin info csv file"
    )

    args = parser.parse_args()

    # -------------------------------------
    if len(sys.argv) < 2:
        parser.print_help()
        sys.exit(1)

    return args


def main(args):
    try:
        dprint(LOW, "Verifying input arguments")
        spec_p4, pin_p4 = verify_args(args.pin_path, args.path_spec)
        dprint(MEDIUM, f"Spec path p4? {spec_p4}, Pin info path p4? {pin_p4}")
        if spec_p4 is True:
            verify_p4_path(args.path_spec)
        else:
            verify_local_path(os.path.abspath(args.path_spec))
        if pin_p4 is True:
            verify_p4_path(args.pin_path)
        else:
            verify_local_path(os.path.abspath(args.pin_path))
        dprint(LOW, "Input paths exist")
        macro, header_row = macro_name(args.pin_path, args.path_spec)
        iprint(f"Analyzing '{macro.upper()}' pin list and pin info")

        dprint(LOW, "Retrieving spec and pin info files")
        if spec_p4 is True:
            spec_path = p4_file(args.path_spec, "spec", "docx")
        else:
            spec_path = os.path.abspath(args.path_spec)
        if pin_p4 is True:
            pin_info_path = p4_file(args.pin_path, "pin_info", "csv")
        else:
            pin_info_path = os.path.abspath(args.pin_path)

        document = docx.Document(spec_path)

        analyze_document(document, macro, header_row, pin_info_path)
    finally:
        rm_temp_files()


def analyse_excel_table(table, pin_path, header_row):
    errors = []
    df = [
        ["" for i in range(len(table.columns))] for j in range(len(table.rows))
    ]
    for i, row in enumerate(table.rows):
        for j, cell in enumerate(row.cells):
            if cell.text:
                df[i][j] = cell.text.replace("\n", "")
    dprint(HIGH, f"TABLE CONTENTS: {df}")
    dfs = pd.DataFrame(df)
    dfs.drop_duplicates(subset=None, keep="first", inplace=False)
    dfs.columns = dfs.iloc[header_row]
    dfs.columns = dfs.columns.str.upper()
    dfs = dfs.drop(labels=0, axis=0)
    dprint(HIGH, f"Pin List data before dropping NaN rows:\n{dfs}")
    rename_cols(dfs)
    try:
        sub1 = dfs[["DIRECTION", "PIN NAME", "SIGNAL WIDTH"]]
    except KeyError as missing:
        eprint(
            f"Invalid SPEC doc Pin List, {missing}. "
            "Please update the pin list to include and "
            "populate the missing column"
        )
        hprint(
            "For more info on the script input requirements: "
            "https://jiradocs.internal.synopsys.com/x/1RVfEQ"
        )
        fatal_error("Exiting...")

    # removing rows that contain header row text aside from header itself
    d_str = ["direction", "i/o"]
    sub1 = sub1[
        ~sub1["DIRECTION"].str.contains("|".join(d_str), case=False, na=False)
    ]
    sub1 = sub1[
        ~sub1["PIN NAME"].str.contains("pin name", case=False, na=False)
    ]
    w_str = ["signal width", "width"]
    sub1 = sub1[
        ~sub1["SIGNAL WIDTH"].str.contains(
            "|".join(w_str), case=False, na=False
        )
    ]
    # Stripping whitespace from entire sub1 dataframe
    sub = sub1.apply(lambda x: x.str.strip() if x.dtype == "object" else x)
    for value in sub["PIN NAME"]:
        if not value.upper() == "PIN NAME":
            if not re.match("^[A-Za-z0-9_\\[\\]:<>]*$", value):
                errors.append("Pin Name Error")
                eprint(
                    f"Invalid pin name: '{value}'\n"
                    "Only Alphabets (A-Z, a-z), "
                    "Numbers (0-9) or a few special characters "
                    "(_,[,],<,>,:) are allowed in the Pin Name"
                )

    errors = check_direction(sub, errors)

    errors = check_width(sub, errors)

    error = read_excel(sub, errors, pin_path)
    validate(error)
    if not error == []:
        # only prints the list if there are errors
        eprint(f"List of errors: {error}")
    return error


def check_width(sub, errors):
    width = ["SIGNAL WIDTH", "WIDTH"]
    i = 0
    for no in sub["SIGNAL WIDTH"]:
        msg = (
            f'PIN NAME: {sub["PIN NAME"].iloc[i - 1].ljust(40)}'
            f"SIGNAL WIDTH: {str(no)}"
        )
        i = i + 1
        dprint(CRAZY, f"Number {no}")
        if [no] == [np.NaN]:
            errors.append("Signal Width Error")
            eprint(f"{msg}\n" "    Signal width can only be a positive number")
        elif not no.upper() in width and not no.isdigit():
            errors.append("Signal Width Error")
            eprint(f"{msg}\n" "    Signal width can only be a positive number")
    return errors


def check_direction(sub, errors):
    direct_list = ["INPUT", "OUTPUT", "INOUT", "I", "O", "IO"]
    head_list = ["DIRECTION", "I/O"]
    if "DIRECTION" in sub:
        i = 0
        for direc in sub["DIRECTION"]:
            msg = (
                f'PIN NAME: {sub["PIN NAME"].iloc[i - 1].ljust(37)}'
                f"DIRECTION: {direc}"
            )
            i = i + 1
            if direc.upper() not in head_list:
                if direc.upper() not in direct_list:
                    errors.append("Direction Error")
                    eprint(
                        f"{msg}\n"
                        "    Direction can only be out of 'Input', "
                        "'Output', 'Inout', 'I', 'O' or 'IO'"
                    )
    return errors


def validate(error):

    if len(error) > 0:
        iprint("ERRORS FOUND")

    else:
        iprint("NO ERRORS FOUND")

    return error


def read_excel(sub, errors, pin_path):

    with pd.ExcelWriter(
        "temp_spec_excel__pin_check.xlsx", engine="xlsxwriter"
    ) as writer:
        sub.to_excel(writer, sheet_name="Sheet1", index=False)

    df_spec = pd.read_excel("temp_spec_excel__pin_check.xlsx")

    # reading pin info csv file
    df_pin = pd.read_csv(pin_path, header=0)
    # printing a csv from perforce adds an extra header line
    df_pin.columns = df_pin.columns.str.upper()
    if "I/O" in df_pin.columns:
        df_pin.rename(columns={"I/O": "DIRECTION"}, inplace=True)
    if "PIN NAME" in df_pin.columns:
        df_pin.rename(columns={"PIN NAME": "NAME"}, inplace=True)
    try:
        df_pin = df_pin[["NAME", "DIRECTION"]]
    except KeyError as error:
        eprint(
            f"Invalid Pininfo csv: {error}. "
            "Please update the pininfo to include and "
            "populate the missing column"
        )
        hprint(
            "For more info on the script input requirements: "
            "https://jiradocs.internal.synopsys.com/x/1RVfEQ"
        )
        fatal_error("Exiting...")

    errors = check_match_width(df_spec, df_pin, errors)
    errors = check_missing(df_spec, df_pin, errors)
    errors = check_match_direction(df_spec, df_pin, errors)
    return errors


def check_match_width(df_spec, df_pin, errors):
    spec_name = df_spec["PIN NAME"]
    pin_name = df_pin["NAME"]

    for val in spec_name:
        dprint(HIGH, f"Spec pin name to match: {val}")
        for pin in pin_name:
            if "<" in pin:
                spl = pin.split("<")
            else:
                spl = pin.split("[")
            bus_width = 0
            lis = []
            dprint(CRAZY, f"Pin info pin name: {spl[0]}")

            if spl[0].lower() == val.lower():
                if len(spl) > 1:
                    letters = list(spl[1])

                    bus_width = int(letters[0]) - int(letters[2]) + 1
                else:
                    bus_width = 1
                msg = (
                    f"Pin Name: {spl[0].ljust(40)}"
                    f"Signal Width: {str(bus_width)}"
                )

                with no_stdout(logger):
                    nprint(msg)

                sig = df_spec.loc[df_spec["PIN NAME"] == val, "SIGNAL WIDTH"]

                lis = sig.tolist()
                dprint(MEDIUM, f"CSV width: {bus_width} SPEC width: {lis}")
                if isnan(float(lis[0])):
                    dprint(HIGH, "Skipping check for NaN width")
                    pass
                elif int(bus_width) != int(lis[0]):
                    errors.append("Pin Info Error")
                    eprint(
                        f"'{spl[0]}' signal width mismatch"
                        f"\n\tSignal Width from Pin Info: {bus_width}"
                        f"\n\tSignal Width from Spec Doc: {lis[0]}"
                    )
                break
    return errors


def check_match_direction(df_spec, df_pin, errors):
    pin_sub = df_pin.iloc[:, 0:2]
    pin_sub = pin_sub.replace({"(?i)Inout": "IO"}, regex=True)
    pin_sub = pin_sub.replace({"(?i)Input": "I"}, regex=True)
    pin_sub = pin_sub.replace({"(?i)Output": "O"}, regex=True)

    df_spec = df_spec.replace({"(?i)Inout": "IO"}, regex=True)
    df_spec = df_spec.replace({"(?i)Input": "I"}, regex=True)
    df_spec = df_spec.replace({"(?i)Output": "O"}, regex=True)
    spec_sub = df_spec[["PIN NAME", "DIRECTION"]]

    pininfo_list = pin_sub.values.tolist()
    dprint(HIGH, f"Pin info:\n{pininfo_list}")

    spec_list = spec_sub.values.tolist()
    dprint(HIGH, f"Spec:\n{spec_list}")

    new_pininfo_list = []
    new_spec_list = []
    for pair in pininfo_list:
        if "<" in pair[0]:
            pair[0] = pair[0].split("<")[0]
        else:
            pair[0] = pair[0].split("[")[0]
        new_pininfo_list.append(pair)
    for pair in spec_list:
        if "<" in pair[0]:
            pair[0] = pair[0].split("<")[0]
        else:
            pair[0] = pair[0].split("[")[0]
        new_spec_list.append(pair)
    dprint(HIGH, f"Stripped [:]/<:> Pin info:\n{new_pininfo_list}")
    dprint(HIGH, f"Stripped [:]/<:> Spec:\n{new_spec_list}")
    for pin in new_pininfo_list:
        for spec_pin in new_spec_list:
            if spec_pin[0].lower() == pin[0].lower() and spec_pin[1] != pin[1]:
                errors.append("Direction Mismatch Error")
                eprint(
                    (
                        f"{pin[0]} directions from "
                        "spec and pin info do not match\n"
                        f"Spec direction: {spec_pin[1]}\n"
                        f"Pin info direction: {pin[1]}"
                    )
                )
    return errors


def check_missing(df_spec, df_pin, errors):
    spec_names = df_spec["PIN NAME"]
    pin_names = df_pin["NAME"]

    spec_list = []
    pin_list = []
    for pin in pin_names:
        if "<" in pin:
            p_spl = pin.split("<")
        else:
            p_spl = pin.split("[")
        pin_list.append(p_spl[0])
    dprint(HIGH, f"Pin info:\n{pin_list}")
    for pin in spec_names:
        if "<" in pin:
            s_spl = pin.split("<")
        else:
            s_spl = pin.split("[")
        spec_list.append(s_spl[0])
    dprint(HIGH, f"Spec:\n{spec_list}")

    for pin in pin_list:
        if not any(spec_pin.lower() == pin.lower() for spec_pin in spec_list):
            errors.append("Spec Missing Pin Error")
            eprint(f"Missing '{pin}' from SPEC DOCUMENT pin list")
    for pin in spec_list:
        if not any(info_pin.lower() == pin.lower() for info_pin in pin_list):
            errors.append("Pin Info Missing Pin Error")
            eprint(f"Missing '{pin}' from PIN INFO")
    return errors


def rename_cols(dfs):
    dprint(LOW, f"Pin List Columns: {dfs.columns}")
    if "I/O" in dfs.columns:
        dfs.rename(columns={"I/O": "DIRECTION"}, inplace=True)

    if "WIDTH" in dfs.columns:
        dfs.rename(columns={"WIDTH": "SIGNAL WIDTH"}, inplace=True)

    try:
        dfs[dfs["DIRECTION"].str.strip().astype(bool)]
    except KeyError as missing:
        eprint(
            f"Invalid SPEC doc Pin List, missing {missing} column. "
            "Please update the pin list to include and "
            "populate the missing column"
        )
        hprint(
            "For more info on the script input requirements: "
            "https://jiradocs.internal.synopsys.com/x/1RVfEQ"
        )
        fatal_error("Exiting...")

    dprint(LOW, f"Pin List Columns after rename:\n {dfs.columns}")
    dfs = dfs.replace("[^\x00-\x7F]+", "", regex=True)
    dfs = dfs.replace("", np.NaN).dropna(how="all")
    dprint(MEDIUM, f"Pin List data:\n{dfs}")


def verify_args(pin_path, spec_path):
    spec_p4 = True
    pin_p4 = True
    pin_split = pin_path.split(".")
    pin_ext = pin_split[len(pin_split) - 1]
    spec_split = spec_path.split(".")
    spec_ext = spec_split[len(spec_split) - 1]

    if not spec_path.startswith("//"):
        dprint(MEDIUM, f'Local spec path "{os.path.abspath(spec_path)}"')
        spec_p4 = False
        if not spec_path.endswith(".docx"):
            fatal_error(
                f"Spec should be a word (.docx) document => {spec_path}"
            )
    elif not spec_ext.startswith("docx"):
        fatal_error(f"Spec should be a word (.docx) document => {spec_path}")

    if not pin_path.startswith("//"):
        dprint(MEDIUM, f'Local pin info path "{os.path.abspath(pin_path)}"')
        pin_p4 = False
        if not pin_path.endswith(".csv"):
            fatal_error(f"Pin info should be a .csv file => {pin_path}")
    elif not pin_ext.startswith("csv"):
        fatal_error(f"Pin info should be a .csv file => {pin_path}")

    return spec_p4, pin_p4


def verify_p4_path(file_path):

    try:
        p4 = da_p4_create_instance()
        p4.connect()
        dprint(HIGH, f"File path: {file_path}")
        file_exist = run_system_cmd(f"p4 files {file_path}", 0)
        dprint(MEDIUM, f"Output of p4 files {file_path}: {file_exist}")
        if file_exist[1].endswith("no such file(s).\n") or file_exist[
            1
        ].startswith("Invalid"):
            fatal_error(
                (
                    "Perforce file does not exist. "
                    "Please check for typos in the path.\n"
                    f"'{file_path}'"
                )
            )
        else:
            p4.disconnect()
    except P4Exception:
        for e in p4.errors:  # Display errors
            print(e)


def verify_local_path(file_path):
    if not os.path.isfile(file_path):
        fatal_error(
            (
                "Local file does not exist. "
                "Please check for typos in the path.\n"
                f"'{file_path}'"
            )
        )


def macro_name(pin_path, spec_path):

    pin = pin_path.split("/")
    pin_filename = pin[len(pin) - 1].split(".")[0]
    pin_macroname = pin_filename.split("_")

    spec = spec_path.split("/")
    spec_filename = spec[len(spec) - 1].split(".")[0]
    spec_macroname = spec_filename.split("_")

    pin_macros = isolate_macro(pin_macroname)
    spec_macros = isolate_macro(spec_macroname)
    if len(pin_macros) > 1:
        pin_macros = ["_".join(pin_macros)]
    if len(pin_macros) == 0:
        fatal_error(f"No macro names in {pin_filename}")
        sys.exit(1)
    if len(spec_macroname) == 0:
        fatal_error(f"No macro names in {spec_filename}")
        sys.exit(1)
    dprint(LOW, f"Macro name extracted from pin info: {pin_macros}")
    dprint(LOW, f"Macro names extracted from spec doc: {spec_macros}")
    if pin_macros == spec_macros:
        header_row = 0
    else:
        header_row = 1
    macro_name = match_macro(pin_macros, spec_macros)
    dprint(LOW, f"Matching macro name from both files: '{macro_name}'")
    return macro_name, header_row


def match_macro(pin_macros, spec_macros):

    pin_macro = pin_macros[0]
    macro = NULL_VAL
    for i in range(len(spec_macros)):
        if spec_macros[i] == pin_macro.replace("_", ""):
            macro = pin_macro
    if macro == NULL_VAL:
        fatal_error(
            (
                f"Spec document macro name(s), '{spec_macros}', "
                f"do not match pin info macro name'{pin_macro}'"
            )
        )
    return macro


def isolate_macro(array):
    ignore_list = ["spec", "ew"]
    # list of common strings that are not macro names
    # original ignore_list = ['spec', 'ew']

    macro = []
    for i in range(len(array[2:])):
        content = array[2:]
        end = content[i].endswith(tuple(ignore_list))
        start = content[i].startswith(tuple(ignore_list))
        dprint(HIGH, f"Discarding from file name split list: {content}")
        if not (content[i] in ignore_list or end or start):
            macro.append(content[i])
            dprint(MEDIUM, f"Extracted macro names: {macro}")
    return macro


def header_macro(macro, tex):
    in_header = False
    split1 = tex.split("_", 2)
    split_len = len(split1)
    dprint(HIGH, f"split: {split1}")
    head_macro = split1[split_len - 1]
    head_macro = re.sub(r"[^\x00-\x7F]+", "", head_macro)
    if macro.lower() == head_macro.lower():
        in_header = True
    dprint(HIGH, f"header macro: {in_header}")
    return in_header


def p4_file(perforce_path, name, ext):
    try:
        p4 = da_p4_create_instance()
        p4.connect()  # Connect to the Perforce server
        dprint(
            LOW,
            f"p4 print -q {perforce_path} > temp_{name}_file__pin_check.{ext}",
        )
        run_system_cmd(
            f"p4 print -q {perforce_path} > temp_{name}_file__pin_check.{ext}",
            0,
        )
        new_path = os.path.abspath(f"temp_{name}_file__pin_check.{ext}")
        p4.disconnect()  # Disconnect from the server
    except P4Exception:
        for e in p4.errors:  # Display errors
            print(e)
    return new_path


def analyze_document(document, macro, header_row, pin_info_path):
    analyze_count = 0

    for req in document.tables:
        data = req.rows[0].cells
        tex = data[0].text
        dprint(HIGH, f"Current header row cell: {tex}")
        dprint(MEDIUM, f"Header row: {header_row}")
        dprint(LOW, f"Table Rows? {len(req.rows)}")
        if len(req.rows) > 1:
            dprint(HIGH, f"Cell 0: {req.rows[header_row].cells[0].text}")
            for cell in req.rows[header_row].cells:
                val = cell.text.lower()
                dprint(CRAZY, f"Is marco in cell? {header_macro(macro,tex)}")
                dprint(HIGH, f"Current cell: {val}")
                if val == "pin name":
                    if header_macro(macro, tex) and header_row == 1:
                        dprint(LOW, f"Analyzing '{macro}' pin lists only")
                        analyse_excel_table(req, pin_info_path, header_row)
                        analyze_count += 1
                    elif header_row == 0:
                        dprint(LOW, f"Analyzing '{macro}' pin list")
                        analyse_excel_table(req, pin_info_path, header_row)
                        analyze_count += 1
                    break
        if analyze_count > 0 and header_row == 0:
            break
    if analyze_count == 0:
        eprint(
            f"Zero(0) tables analyzed for '{macro}'. "
            "Please check if the spec document has pin list tables "
            "or if the two files contain the same macro. "
            "\nIf the spec document contains multiple macros, "
            "the pin lists must have an extra row on the top "
            "that contains corresponding the macro name"
        )


def rm_temp_files():
    dprint(LOW, "Removing temp files")
    if os.path.isfile(os.getcwd() + "/temp_pin_info_file__pin_check.csv"):
        os.unlink(os.getcwd() + "/temp_pin_info_file__pin_check.csv")
    if os.path.isfile(os.getcwd() + "/temp_spec_file__pin_check.docx"):
        os.unlink(os.getcwd() + "/temp_spec_file__pin_check.docx")
    if os.path.isfile(os.getcwd() + "/temp_spec_excel__pin_check.xlsx"):
        os.unlink(os.getcwd() + "/temp_spec_excel__pin_check.xlsx")


if __name__ == "__main__":

    args = parse_args()
    RealScript = os.path.basename(__file__)
    filename = os.getcwd() + "/" + os.path.basename(__file__) + ".log"
    logger = create_logger(filename)  # Create log file

    # Register exit function
    atexit.register(footer)

    # Initalise shared variables and run main
    CommonHeader.init(args, __author__, __version__)

    header()
    da_p4_create_instance()
    main(args)
    iprint(f"Log file: {filename}")

    utils__script_usage_statistics(RealScript, __version__)
