#!/depot/Python/Python-3.8.0/bin/python


__author__ = "Harsimrat Singh Wadhawan"
__tool_name__ = "ddr-da-ibis-extract-codes"

import argparse
import sys
import pathlib
from typing import List

import pandas
import json

# ----------------------------------#
bindir = str(pathlib.Path(__file__).resolve().parent)
# sys.path.append(bindir + '/../lib/python')
sys.path.append(bindir + '/../lib/python/Util')
sys.path.append(bindir + '/../')
# ----------------------------------#

from Messaging import iprint, fatal_error
import Misc


def _create_argparser() -> argparse.ArgumentParser:
    """Initialize an argument parser. Arguments are parsed in Misc.setup_script"""
    parser = argparse.ArgumentParser(
        description="Extract calibration codes from a testbench measurement spreadsheet based on a given configuration."
    )
    parser.add_argument("-v", metavar="<#>", type=int,
                        default=0, help="verbosity")
    parser.add_argument("-d", metavar="<#>", type=int, default=0, help="debug")
    parser.add_argument("-cfg", required=True)
    parser.add_argument("-source", required=True)

    return parser


def main(cmdline_args: List[str] = None) -> None:
    """Main function."""
    argparser = _create_argparser()
    args = Misc.setup_script(argparser, __author__, __tool_name__, cmdline_args)

    # Load JSON file
    file_name = args.cfg
    try:
        file = open(file_name, "r")
    except IOError:
        fatal_error("Could not open JSON configuration file. Exiting.")

    config = json.loads(file.read())
    tables = load_data(args.source)

    expected_keys = [
        "p_column", "n_column", "vdd_column", "vddq_column",
        "temp_column", "transistor_column", "resistor_column", "config"
    ]
    missing_keys = Misc.find_keys_missing_in_dict(config, expected_keys)
    if missing_keys:
        iprint(
            f"The following keys are missing from the config file: "
            f"{', '.join(missing_keys)}\n"
            f"Expected keys: {' ,'.join(expected_keys)}.\n"
            f"Exiting."
        )
        exit(1)

    # COLUMN NAMES FOR CALCODES
    # ----------------------------------#
    pcol = config["p_column"]
    ncol = config["n_column"]
    vdd = config["vdd_column"]
    vddq = config["vddq_column"]
    temp = config["temp_column"]
    transistor = config["transistor_column"]
    res = config["resistor_column"]
    # ----------------------------------#

    # Get the total number of columns
    tab_len = int(len(tables.columns))
    # Drop N/A values
    cleaned_table = (
        tables.dropna(thresh=tab_len).drop_duplicates().reset_index(drop=True)
    )
    # Drop the header repeated line
    cleaned_table.drop(
        cleaned_table[cleaned_table["Process"] == "Process"].index, inplace=True
    )

    # Ensure that the necessary columns exist inside the html table
    col_array = [vddq, vdd, temp, transistor, res, pcol, ncol]

    if ensure_columns_exist(cleaned_table, col_array) is False:
        iprint(
            f"One of the following keys was not found in the HTML table: {col_array}"
        )
        exit(1)

    # convert to numeric data types and ignore any errors
    cleaned_table[vddq] = cleaned_table[vddq].astype(float)
    cleaned_table[vdd] = cleaned_table[vdd].astype(float)
    cleaned_table[temp] = cleaned_table[temp].astype(float)

    # Find results
    answers = extract_data(cleaned_table, config)

    # Create output files
    if len(answers) > 0:

        hspice_array = create_hspice_file(answers)
        write_file(hspice_array, "cal_code.txt")

        excel_array = create_excel_table(answers)
        write_excel_file(excel_array, "cal_code.xlsx")

        iprint("Files written: cal_code.txt, and cal_code.xlsx")


def write_excel_file(answers, name):
    df = pandas.DataFrame(answers)
    df.to_excel(excel_writer=name)


def create_hspice_file(answer):

    line_array = []
    line_array.append(".PARAM")

    # write vdd values
    line_array += append_comment("VDD VALUES")
    for item in answer:
        corner = item[0]
        vdd = corner["vdd"]
        name = corner["name"]
        line_array.append(f"+ {name}_vdd = {vdd}")

    # write vddq values
    line_array += append_comment("VDDQ VALUES")
    for item in answer:
        corner = item[0]
        vddq = corner["vddq"]
        name = corner["name"]
        line_array.append(f"+ {name}_vddq = {vddq}")

    line_array += append_comment("TEMPERATURE VALUES")
    for item in answer:
        corner = item[0]
        temp = corner["temperature"]
        name = corner["name"]
        line_array.append(f"+ {name}_temp = {temp}")

    line_array += append_comment("CALCODES")
    for item in answer:

        corner = item[0]
        process = (corner["corner"]).upper()
        name = corner["name"]
        temp = corner["temperature"]
        vddq = corner["vddq"]
        vdd = corner["vdd"]
        pcode = str("{:.0f}".format(float(corner["pcode"])))
        ncode = str("{:.0f}".format(float(corner["ncode"])))
        line_array.append(f"*** {process} / {temp} / {vddq} / {vdd}")
        line_array.append(f"+ {name}_pcode = {pcode}")
        line_array.append(f"+ {name}_ncode = {ncode}")
        line_array.append("")

    return line_array


def append_comment(heading):
    array = []
    array.append("\n****************")
    array.append(f"*{heading}*")
    array.append("****************\n")
    return array


def create_excel_table(answer):

    line_array = []
    line_array.append(["mos", "res", "vddq", "vdd",
                       "temp", "pcode", "ncode", "name"])

    for item in answer:

        corner = item[0]
        process = (corner["corner"]).upper()
        name = corner["name"]
        temp = corner["temperature"]
        vddq = corner["vddq"]
        vdd = corner["vdd"]
        pcode = corner["pcode"]
        ncode = corner["ncode"]

        line_array.append(
            [process, process, vddq, vdd, temp, pcode, ncode, name])

    return line_array


def write_file(array, filename):
    with open(filename, "w") as f:
        for item in array:
            f.write("%s\n" % item)


def extract_data(cleaned_table, configfile):

    # ----------------------------------#
    # COLUMN NAMES FOR CALCODES
    # ----------------------------------#
    pcol = configfile["p_column"]
    ncol = configfile["n_column"]
    vdd = configfile["vdd_column"]
    vddq = configfile["vddq_column"]
    temp = configfile["temp_column"]
    transistor = configfile["transistor_column"]
    res = configfile["resistor_column"]
    # ----------------------------------#

    config = configfile["config"]
    answers = []

    for corner in config:

        # Ensure that the necessary keys exist inside the json object
        expected_keys = ["vddq", "vdd", "temperature", "corner", "name"]
        missing_keys = Misc.find_keys_missing_in_dict(corner, expected_keys)
        if not missing_keys:
            iprint(
                f"Looking for {corner['vddq']} {corner['vdd']} {corner['temperature']} {corner['corner']}"
            )

        else:
            iprint(
                f"The following key(s) not found in {corner}: {', '.join(missing_keys)}.\n"
                f"Expected keys: {', '.join(expected_keys)}\n"
                f"Skipping corner."
            )
            continue

        # set conditions for searching inside a Pandas DataFrame
        condition_a = cleaned_table[vddq] == float(corner["vddq"])
        condition_b = cleaned_table[vdd] == float(corner["vdd"])
        condition_c = cleaned_table[temp] == float(corner["temperature"])
        condition_d = cleaned_table[transistor].str.contains(
            f"{corner['corner']}")
        condition_e = cleaned_table[res].str.contains(f"{corner['corner']}")

        # check for those conditions
        matched_rows = cleaned_table[condition_a & condition_b & condition_c & condition_d & condition_e]  # noqa E501

        if matched_rows.shape[0] > 0:

            for index, matched_row in matched_rows.iterrows():

                corner["pcode"] = str(
                    "{:.0f}".format(float(matched_row[pcol])))
                corner["ncode"] = str(
                    "{:.0f}".format(float(matched_row[ncol])))
                answers.append([corner, matched_row])
                iprint(f"Found the following codes: {corner}\n")

        else:
            iprint("Nothing found.\n")

    return answers


def ensure_columns_exist(df, keys):

    cols = df.columns.to_list()

    for key in keys:
        try:
            cols.index(key)
        except ValueError:
            return False

    return True


def load_data(source):

    if "xlsx" in source:
        m_tables = pandas.read_excel(source, header=0, engine="openpyxl")

    if "html" in source:
        m_tables = pandas.read_html(source, header=1)
        m_tables = m_tables[1]

    return m_tables


if __name__ == "__main__":
    main(sys.argv[1:])
