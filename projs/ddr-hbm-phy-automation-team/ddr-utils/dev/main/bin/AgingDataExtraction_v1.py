#!/depot/Python/Python-3.8.0/bin/python
# nolint main
import os
import tkinter as tk
import random
import xlsxwriter
import configparser
import xlrd
import pandas as pd
import json
import string
import sys
import xml.etree.ElementTree as ET
from collections import OrderedDict
from collections import Counter
import argparse
from argparse import RawTextHelpFormatter, SUPPRESS
import subprocess
from pathlib import Path
import getpass


BIN_DIR = str(Path(__file__).resolve().parent)
# Add path to sharedlib's Python Utilities directory.
sys.path.append(BIN_DIR + "/../lib/python/Util")

import Misc
version = Misc.get_release_version()

Misc.utils__script_usage_statistics("AgingDataExtraction_v1", version)


# Parses through the 'Generic' sheet of the Excel config file, stores the headers and values
def parse_hmf_generic(hmf_config):
    headers = list()
    generic_sheet = pd.read_excel(hmf_config, "Generic")
    for head in generic_sheet.head():
        headers.append(head)

    number_of_headers = int(len(headers))
    generic_info = [[] for i in range(number_of_headers)]
    for header in headers:
        header_index = headers.index(header)
        for element in generic_sheet.iloc[:, header_index].dropna():
            generic_info[header_index].append(element)

    generic_info_and_generic_headers = [generic_info, headers]

    return generic_info_and_generic_headers


# using hmf_config and hmf, returns list of 3 lists (headers, sheet_info and list_of_hmf_nodes)


def parse_hmf_config(hmf_config, hmf):
    headers = list()
    list_of_hmf_modes = list()
    hmf_sheet = pd.read_excel(hmf_config, hmf)

    for head in hmf_sheet.head():
        # print(head)
        replaced_head = head.replace(head.split()[0] + " ", "")
        headers.append(replaced_head)
        if head.split()[0] not in list_of_hmf_modes:
            list_of_hmf_modes.append(head.split()[0])

    # print('headers include: ' + str(headers))

    for element in hmf_sheet.iloc[:, 0].dropna():
        # print(element)
        element = str(element)
        if element.find(" ") > 0:
            list_of_hmf_modes.append(element.split()[0])

    # print('list_of_hmf_modes include: ' + str(list_of_hmf_modes))
    number_of_headers = int(len(headers))
    number_of_hmf_modes = int(len(list_of_hmf_modes))
    sheet_info = [[[] for j in range(number_of_hmf_modes)] for i in range(number_of_headers)]

    for header in headers:
        header_index = headers.index(header)
        mode_index = 0

        for element in hmf_sheet.iloc[:, header_index].dropna():
            element = str(element)
            mode_info = element.split()[0]
#            print("**", list_of_hmf_modes)
#            print("#",mode_index,"##",header_index,"##",element,"###",mode_info)
            if mode_info in list_of_hmf_modes:
                mode_index += 1
            else:
                sheet_info[header_index][mode_index].append(element)

    remove_whitespace_excel_corners(sheet_info)

    output_list = [headers, sheet_info, list_of_hmf_modes]

    return output_list


def remove_whitespace_excel_corners(sheet_info):
    """Removes whitespace at end and beginning of corners taken from excel config file"""
    length = len(sheet_info)
    for index in range(0, length):
        leng = len(sheet_info[index])
        for ind in range(0, leng):
            lengt = len(sheet_info[index][ind])
            for inde in range(0, lengt):
                sheet_info[index][ind][inde] = sheet_info[index][ind][inde].strip()


# using given variables to search for, returns a list of 4 lists and path containing unfound variables (dataset_all_measurements, variants_not_found, param_not_found, variant_value_not_found)


def read_xml(  # noqa: C901
    report_path,
    blocks,
    testbenches,
    measurements,
    list_of_variant_names,
    list_of_variant_values,
    stress_types,
    stress_mode_variable,
    list_of_stress_modes,
):
    foo = " "
    number_of_measurements = int(len(measurements))
    number_of_blocks = int(len(blocks))
    correct = bool()
    number_of_stress_types = int(len(stress_types))
    dataset_all_measurements = list()
    variant_stress_mode_index = str()
    number_of_measurements_per_tb = int(number_of_measurements / number_of_blocks)
    data = float()
    found_variants = list()
    variants_not_found = list()
    found_params = list()
    param_not_found = list()
    variant_value_found = list()
    variant_value_not_found = list()
    # create an empty list of lists
    dataset_all_measurements = [
        [foo for j in range(number_of_stress_types)] for i in range(number_of_measurements)
    ]

    for block_index in range(number_of_blocks):
        if blocks[block_index] == "None":
            continue
        block_dir = blocks[block_index]
        bench_dir = testbenches[block_index]

        low_index = block_index * number_of_measurements_per_tb
        high_index = min((block_index + 6) * number_of_measurements_per_tb, number_of_measurements)
        measurements_per_tb = measurements[low_index:high_index]

        # get process name from simulation.xml under report path to the testbench

        firstpath = (
            report_path
            + "/"
            + block_dir
            + "/"
            + bench_dir
            + "/simulation/measurements/data/simulation.xml"
        )

        try:
            open(firstpath)
        except FileNotFoundError:
            print("ERROR! The script did not run successfully!")
            print("Excel file was not generated...")
            print("Please check run.log")
            edit_log_file([], [], [], block_dir, bench_dir, firstpath, "")

            workbook.close()
            sys.exit()

        simulation_info = ET.parse(firstpath)
        simulation_root = simulation_info.getroot()
        process_name = simulation_root.find("process").find("name").text
        path = (
            report_path
            + "/"
            + block_dir
            + "/"
            + bench_dir
            + "/simulation/measurements/data/"
            + process_name
            + ".xml"
        )

        tree = ET.parse(path)
        root = tree.getroot()
        for process in root.findall("process"):
            correct = True
            for variant in process.findall("variant"):
                variant_name = variant.find("name").text
                if variant_name == stress_mode_variable:
                    variant_stress_mode_index = variant.find("value").text

                elif variant_name in list_of_variant_names:
                    # variant_index = list_of_variant_names.index(variant_name)
                    variant_value = variant.find("value").text
                    found_variants.append(variant_name)

                    if variant_value not in list_of_variant_values:
                        correct = False
                    else:
                        variant_value_found.append(variant_value)

                diff1 = Counter(list_of_variant_names) - Counter(found_variants)
                variants_not_found = list(diff1.elements())
                diff2 = Counter(list_of_variant_values) - Counter(variant_value_found)
                variant_value_not_found = list(diff2.elements())

            if correct:
                for parameter in process.findall("parameter"):
                    # print(parameter.find("name").text)
                    if parameter.find("name").text in measurements_per_tb:
                        param_name = parameter.find("name").text
                        found_params.append(param_name)

                        measurement_index = measurements_per_tb.index(parameter.find("name").text)

                        data = parameter.find("value").text
                        if data == "n/a" or data == "NA":
                            data = 0
                        data = float(data)
                        # print(list_of_stress_modes)
                        if variant_stress_mode_index in list_of_stress_modes:
                            # print(variant_stress_mode_index)
                            col_of_data = list_of_stress_modes.index(variant_stress_mode_index)
                            dataset_all_measurements[
                                block_index * number_of_measurements_per_tb + measurement_index
                            ][col_of_data] = data

                    diff3 = Counter(measurements) - Counter(found_params)

                    # print(measurements,"**",found_params)
                    if hmf == "LPDDR5X" and any(x in measurements for x in found_params):
                        param_not_found = []
                    else:
                        param_not_found = list(diff3.elements())

        if variant_value_not_found or param_not_found or variants_not_found:
            edit_log_file(
                variants_not_found,
                param_not_found,
                variant_value_not_found,
                block_dir,
                bench_dir,
                "",
                "",
            )
    # print(dataset_all_measurements,variants_not_found,param_not_found,variant_value_not_found,path,found_variants,variant_value_found)
    dataset_and_unfound_variants_and_params = [
        dataset_all_measurements,
        variants_not_found,
        param_not_found,
        variant_value_not_found,
        path,
        found_variants,
        variant_value_found,
    ]
    return dataset_and_unfound_variants_and_params


def read_srv(  # noqa: C901
    blocks,
    testbenches,
    measurements,
    list_of_variant_names,
    list_of_variant_values,
    stress_types,
    stress_mode_variable,
    list_of_stress_modes,
):
    foo = " "
    number_of_measurements = int(len(measurements))
    number_of_blocks = int(len(blocks))
    number_of_stress_types = int(len(stress_types))
    dataset_all_measurements = list()
    number_of_measurements_per_tb = int(number_of_measurements / number_of_blocks)
    found_variants = list()
    variants_not_found = list()
    found_params = list()
    param_not_found = list()
    variant_value_found = list()
    variant_value_not_found = list()

    product = report_path.split("/")[1]
    project = report_path.split("/")[2]
    release = report_path.split("/")[3]

    high_index = int(len(list_of_stress_modes) / number_of_blocks)
    list_of_stress_modes = list_of_stress_modes[0:high_index]
    # print(list_of_stress_modes)

    dataset_all_measurements = [
        [foo for j in range(number_of_stress_types)] for i in range(number_of_measurements)
    ]
    # print(dataset_all_measurements)

    for block_index in range(number_of_blocks):
        # print(block_index)
        if blocks[block_index] == "None":
            continue
        headers = list()
        data = list()
        columns = list()
        temp = list()

        block_dir = blocks[block_index]
        bench_dir = testbenches[block_index]

        # Getting the correct sub-list of measurements for corresponding block
        measurements_per_tb = measurements[
            block_index
            * number_of_measurements_per_tb:min(
                (block_index + 1) * number_of_measurements_per_tb, number_of_measurements
            )
        ]

        # excel = cwd + '/srv_reports/' + block_dir + '/' + bench_dir + '.xlsx'

        download_command = (
            "/remote/cad-rep/msip/tools/Shelltools/srv_utils/latest/bin/msip_srvGenerateXLSReport.pl --pr "
            + product
            + " -p "
            + project
            + " -r "
            + release
            + " -b "
            + block_dir.upper()
            + " -t "
            + bench_dir
            + " >/dev/null 2>&1"
        )
        # print(download_command)
        os.system(download_command)
        srv_output = (
            ""
            + product
            + " "
            + project
            + " "
            + release
            + " "
            + block_dir.upper()
            + " "
            + bench_dir
            + ".xlsx"
        )
        # print(srv_output)

        try:
            sheet = pd.read_excel(srv_output)
        except xlrd.XLRDError:
            print("ERROR!")
            print(
                "Please ensure you have specified the correct project, product, and release. You can verify with the SRV website at: https://de02-srv/"
            )
            os.remove(srv_output)
            workbook.close()
            sys.exit()

        number_of_columns = sheet.shape[1]

        # Clean up the headers
        for head in sheet.head(0):
            replaced_head = head.split(" ", 1)[0]
            headers.append(replaced_head)
        sheet.columns = headers

        # Storing all the data by columns ------------ i.e. The first row of the excel sheet are the 0th elements of each sublist
        for i in range(number_of_columns):
            for j in sheet.iloc[:, i]:
                columns.append(str(j))
            data.append(columns)
            columns = []

        # Checking if the variant names are the same in Excel config file and SRV report
        for variant in list_of_variant_names:
            if variant in headers:
                found_variants.append(variant)
        diff1 = Counter(list_of_variant_names) - Counter(found_variants)
        variants_not_found = list(diff1.elements())
        # print(variants_not_found)

        # Checking if the parameter names are the same in Excel config file and SRV report
        for parameter in measurements:
            if parameter in headers:
                found_params.append(parameter)
        diff2 = Counter(measurements) - Counter(found_params)
        param_not_found = list(diff2.elements())

        for stress_mode in list_of_stress_modes:  # Iterate through list_of_stress_modes
            if stress_mode == "X":
                continue
            indices = [
                i
                for i, x in enumerate(data[headers.index(stress_mode_variable)])
                if x == stress_mode
            ]  # Get row indices that contain the stress_mode
            # print(indices)

            for index in indices:  # Iterate through the indices
                for (
                    name
                ) in (
                    list_of_variant_names
                ):  # Iterate through the variant names to get their column indices in data[]
                    temp.append(
                        data[headers.index(name)][index]
                    )  # Appending the data from relevant columns and row
                for i in temp:
                    variant_value_found.append(i)  # Found values from SRV report
                if temp == list_of_variant_values:  # Comparing each row to given values
                    # print(index)
                    # print(temp)
                    for j in measurements_per_tb:  # Appending to all data if correct row
                        # print(j)
                        measurement_index = measurements_per_tb.index(j)
                        # print(block_index * number_of_measurements_per_tb + measurement_index)
                        # print(list_of_stress_modes.index(stress_mode))
                        # print(headers.index(j))
                        # print(index)

                        dataset_all_measurements[
                            block_index * number_of_measurements_per_tb + measurement_index
                        ][list_of_stress_modes.index(stress_mode)] = float(
                            data[headers.index(j)][index]
                        )
                        # dataset_all_measurements[measurements.index(j)][list_of_stress_modes.index(stress_mode)] = data[headers.index(j)][index]

                        # print(stress_mode)
                        # print(dataset_all_measurements)
                temp = list()
            diff3 = Counter(list_of_variant_values) - Counter(variant_value_found)
            variant_value_not_found = list(diff3.elements())
            # print(variant_value_not_found)
        if variant_value_not_found or param_not_found or variants_not_found:
            edit_log_file(
                variants_not_found,
                param_not_found,
                variant_value_not_found,
                block_dir,
                bench_dir,
                "",
                "",
            )
        os.remove(srv_output)
    return [dataset_all_measurements, variants_not_found, param_not_found, variant_value_not_found]


# writes stressed data in list_of_data_per_param into excel file according to given row and column


def write_stressed_data(row_start, col_start, list_of_data_per_param):
    row_counter = 0
    col_counter = 0
    for line_of_data in list_of_data_per_param:
        col_counter = 0
        for data in line_of_data:
            if "RX" in sheet_name and (hmf == "LPDDR54" or hmf == "LPDDR5XM" or hmf == "LPDDR5X"):
                worksheet.write(row_start + row_counter, col_start + col_counter, data, full_border)
            elif data == " ":
                worksheet.write(
                    row_start + row_counter, col_start + col_counter, data, empty_cell_format
                )
            else:
                worksheet.write(row_start + row_counter, col_start + col_counter, data, full_border)
            col_counter += 1
        row_counter += 1


# writes fresh data in list_of_data_per_param into excel file according to given row and column


def write_fresh_data(row_start, col_start, list_of_data_per_param):
    row_counter = 0
    for line_of_data in list_of_data_per_param:
        if line_of_data[0] == " ":
            worksheet.write(row_start + row_counter, col_start, line_of_data[0], empty_cell_format)
        else:
            worksheet.write(row_start + row_counter, col_start, line_of_data[0], fresh_data_color)
        row_counter += 1


# creates total delay list by appending elements in dataset to new list


def total_delay(dataset):
    total_delays = list()
    for i in range(int(len(dataset) / 2)):
        total_delay = []
        list1 = dataset[i * 2]
        list2 = dataset[i * 2 + 1]
        for j in range(len(list1)):
            if list1[j] == " " or list2[j] == " ":
                total_delay.append(" ")
            else:
                total_delay.append(list1[j] + list2[j])
        # total_delay = [ x + y for x,y in zip(list1, list2)]
        total_delays.append(total_delay)
    return total_delays


# writes total delay data into excel file according to given row and column


def write_total_delay(row_start, col_start, total_delay):
    row_counter = 0
    col_counter = 0
    for data in total_delay:
        if data == " ":
            worksheet.write(
                row_start + row_counter, col_start + col_counter, data, empty_cell_format
            )
        else:
            worksheet.write(row_start + row_counter, col_start + col_counter, data)
        col_counter += 1


# format empty cells on excel worksheet according to given parameters


def print_parameters(
    row_start,
    col_start,
    parameter_name,
    block_names,
    domain_names,
    number_of_stress_types,
    merge_format,
    parameters_color,
    is_lcdl,
):
    if is_lcdl:
        worksheet.write(row_start, col_start, "ph (ph code)", parameters_color)
    else:
        worksheet.write(row_start, col_start, "macro", parameters_color)

    write_starting_row = row_start + 1

    for block in block_names:
        worksheet.write(write_starting_row, col_start, block, parameters_color)
        write_starting_row += 1
    col_start += 1
    write_starting_row = row_start + 1

    worksheet.write(row_start, col_start, "domain", parameters_color)
    for domain in domain_names:
        worksheet.write(write_starting_row, col_start, domain, parameters_color)
        write_starting_row += 1
    col_start += 1
    write_starting_row = row_start + 1

    worksheet.write(row_start, col_start, "No Stress", parameters_color)
    col_start += 1
    write_starting_row = row_start + 1
    worksheet.merge_range(
        row_start,
        col_start,
        row_start,
        (col_start + number_of_stress_types),
        parameter_name,
        merge_format,
    )


# formats stress type data in excel worksheet according to given parameters
def print_stress_types(row_start, col_start, stress_types, stress_type_format, merging_format):
    col_counter = 0
    number_of_stress_types = int(len(stress_types))
    for stress_type in stress_types:
        worksheet.write(row_start, (col_start + col_counter), stress_type, stress_type_format)
        col_counter += 1
    worksheet.merge_range(
        row_start + 1,
        col_start,
        row_start + 1,
        (col_start - 1 + number_of_stress_types),
        "EOL",
        merging_format,
    )


# Writes to the log file if an errors are encountered during runtime
def edit_log_file(
    variant_not_found,
    param_not_found,
    variant_value_not_found,
    block,
    testbench,
    wrongpath,
    wrong_tb_name,
):
    # print(variant_value_not_found)
    print(param_not_found)
    # turn this off when testing, turn it on for normal use (alternatively could change to open file with w+)
    # open('run.log', 'w').close()
    f = open("run.log", "a+")

    if wrong_tb_name != "":
        f.write("ERROR!\n")
        f.write("Test-bench name should not contain '%s'" % wrong_tb_name)
        f.close()
        return

    if wrongpath != "":
        f.write("ERROR!\n")
        f.write("Cannot find the following directory: " + wrongpath + "\n")
        f.write(
            "Please ensure that the output report files exist saved in the following directory format: \n"
        )
        f.write(".../<testbench>_<drs|tmi>_<fresh|eol_stress>")

    if variant_not_found:  # the given list is not empty which implies there are errors to display
        f.write(
            "For macro "
            + block
            + " with testbench "
            + testbench
            + ", the following variants were not found in the XML report:\n"
        )
        for variant in variant_not_found:
            f.write(variant)
            f.write("\n")

    if (
        variant_value_not_found
    ):  # the given list is not empty which implies there are errors to display
        f.write("ERROR!\n")
        f.write(
            "For macro "
            + block
            + " with testbench "
            + testbench
            + ", the following values were not found in the XML report:\n"
        )
        for value in variant_value_not_found:
            f.write(value)
            f.write("\n")
        # for variant_index in range(int(len(variant_value_not_found))):
        # 	temp = list()
        # 	temp = [i for i, x in enumerate(list_of_variant_values) if x == variant_value_not_found[variant_index]]

        # 	for term in temp:
        # 		indices.append(term)
        # 	indices = list(dict.fromkeys(indices))
        #
        # for name_index in indices:
        # 	#f.write("%s " % name_index)
        # 	f.write("%s " % list_of_variant_names[name_index])
        # 	f.write("\n")
        f.write("\n")

    if param_not_found:
        f.write("ERROR!\n")
        f.write(
            "For macro "
            + block
            + " with testbench "
            + testbench
            + ", the following variable names in aging_data_harvesting_config.xlsx were not found in the XML report:\n"
        )
        # f.write("ERROR!\n")
        # f.write("In sheet:  %s \n" % sheet_name)
        # f.write("Incorrect parameter name(s)! \n")
        # f.write("The following parameter(s) cannot be found in XML report: \n")
        for param_index in range(int(len(param_not_found))):
            param_not_found = list(param_not_found)
            f.write("%s" % param_not_found[param_index])
            f.write("\n")
        f.write("\n")

    f.close()


# SANITY CHECKS

# Runs all the general checks for rise and fall delays on all modes and blocks


def sanity_check_general(
    row_start, col_start, fresh_data, stress_data, stress_types, parameter_name
):

    if parameter_name == "rise delay(psec)":
        check_eol_vs_bol = sanity_check_eol_vs_bol(
            row_start, col_start, fresh_data, stress_data, stress_types, parameter_name
        )
        sanity_check_rise_delay(row_start, col_start, stress_data, stress_types, check_eol_vs_bol)

    if parameter_name == "fall delay(psec)":
        check_eol_vs_bol = sanity_check_eol_vs_bol(
            row_start, col_start, fresh_data, stress_data, stress_types, parameter_name
        )
        sanity_check_fall_delay(row_start, col_start, stress_data, stress_types, check_eol_vs_bol)


# Checks if any rise delays are greater than static1 rise delay, writes in red if true


def sanity_check_rise_delay(
    row_start, col_start, list_of_data_per_param, stress_types, check_eol_vs_bol
):
    worst_case_index = stress_types.index("static 1")
    for list_counter in range(int(len(list_of_data_per_param))):
        ideal_worst_value = list_of_data_per_param[list_counter][worst_case_index]
        if ideal_worst_value == " ":
            return
        for internal_counter in range(int(len(stress_types))):
            current_value = list_of_data_per_param[list_counter][internal_counter]
            if current_value == " ":
                continue
            if (current_value > ideal_worst_value) and ideal_worst_value != " ":
                if check_eol_vs_bol[list_counter][internal_counter]:
                    worksheet.write(
                        row_start + list_counter,
                        col_start + internal_counter,
                        current_value,
                        cell_format_rise2,
                    )
                else:
                    worksheet.write(
                        row_start + list_counter,
                        col_start + internal_counter,
                        current_value,
                        cell_format_rise,
                    )


# Checks if any fall delays are greater than static0 fall delay, writes in orange if true
def sanity_check_fall_delay(
    row_start, col_start, list_of_data_per_param, stress_types, check_eol_vs_bol
):
    worst_case_index = stress_types.index("static 0")
    for list_counter in range(int(len(list_of_data_per_param))):
        ideal_worst_value = list_of_data_per_param[list_counter][worst_case_index]
        for internal_counter in range(int(len(stress_types))):
            current_value = list_of_data_per_param[list_counter][internal_counter]

            if current_value == " ":
                continue
            elif current_value > ideal_worst_value:
                if check_eol_vs_bol[list_counter][internal_counter]:
                    worksheet.write(
                        row_start + list_counter,
                        col_start + internal_counter,
                        current_value,
                        cell_format_fall2,
                    )
                else:
                    worksheet.write(
                        row_start + list_counter,
                        col_start + internal_counter,
                        current_value,
                        cell_format_fall,
                    )


# Checks stress delays against fresh delays, if any invalid flag in pink


def sanity_check_eol_vs_bol(
    row_start, col_start, fresh_data, stress_data, stress_types, parameter_name
):
    temp = list()
    temp2 = list()
    for i in range(len(fresh_data)):
        for j in range(len(stress_types)):
            if "delay" not in parameter_name:
                continue
            else:
                if stress_data[i][j] == " ":
                    temp2.append(False)
                elif stress_data[i][j] < fresh_data[i][0]:
                    worksheet.write(
                        row_start + i, col_start + j, stress_data[i][j], cell_format_eol_vs_bol
                    )
                    temp2.append(True)
                else:
                    temp2.append(False)
        temp.append(temp2)
        temp2 = list()
    return temp


# Checks for the two duty cycle requirements for LCDL & CLKTREE only
def sanity_check_dc(row_start, col_start, list_of_data_per_param, stress_types):
    # get the number of elements of the internal list #
    static1_index = stress_types.index("static 1")
    static0_index = stress_types.index("static 0")
    previous_delta_s1 = 0
    previous_delta_s0 = 0
    # print("ROW",row_start,"COL",col_start,list_counter,static0_index)
    for list_counter in range(int(len(list_of_data_per_param))):   
        if list_of_data_per_param[list_counter][static1_index] == " ":
            break
        if list_of_data_per_param[list_counter][static1_index] > 50:
            worksheet.write(
                row_start + list_counter,
                col_start + static1_index,
                list_of_data_per_param[list_counter][static1_index],
                cell_format_dc1,
            )

        if list_of_data_per_param[list_counter][static0_index] < 50:
            worksheet.write(
                row_start + list_counter,
                col_start + static0_index,
                list_of_data_per_param[list_counter][static0_index],
                cell_format_dc1,
            )

        delta_s1 = abs(list_of_data_per_param[list_counter][static1_index] - 50)
        if delta_s1 < previous_delta_s1:
            worksheet.write(
                row_start + list_counter,
                col_start + static1_index,
                list_of_data_per_param[list_counter][static1_index],
                cell_format_dc2,
            )
        previous_delta_s1 = delta_s1

        delta_s0 = abs(list_of_data_per_param[list_counter][static0_index] - 50)
        if delta_s0 < previous_delta_s0:
            worksheet.write(
                row_start + list_counter,
                col_start + static0_index,
                list_of_data_per_param[list_counter][static0_index],
                cell_format_dc2,
            )
        previous_delta_s0 = delta_s0


# Checks for vertically increasing rise and fall delays for LCDL & CLKTREE only


def sanity_check_increasing_fall_rise_vertically(row_start, col_start, list_of_data_per_param):
    internal_len = int(len(list_of_data_per_param[0]))
    for internal_counter in range(internal_len):
        for list_counter in range(int(len(list_of_data_per_param))):
            if list_counter != 0:
                previous_value = list_of_data_per_param[list_counter - 1][internal_counter]
                current_value = list_of_data_per_param[list_counter][internal_counter]
                if previous_value > current_value:
                    worksheet.conditional_format(
                        row_start + list_counter,
                        col_start + internal_counter,
                        row_start + internal_counter,
                        col_start + list_counter,
                        {
                            "type": "cell",
                            "criteria": "<=",
                            "value": previous_value,
                            "format": cell_format_increasing,
                        },
                    )


# Checks for vdd+vddq if rxdq > rxdqs for RX only


def sanity_check_RXDQ_RXDQS(row_start, col_start, list_of_data_per_param, block_names):
    if block_names.index("rxdq") == 0:
        RXDQ_index = block_names.index("rxdq")
        RXDQS_index = block_names.index("rxdqs") - 1
    elif block_names.index("rxdqs") == 0:
        RXDQ_index = block_names.index("rxdq") - 1
        RXDQS_index = block_names.index("rxdqs")
    internal_len = int(len(list_of_data_per_param[0]))
    for internal_counter in range(internal_len):
        RXDQ_value = list_of_data_per_param[RXDQ_index][internal_counter]
        RXDQS_value = list_of_data_per_param[RXDQS_index][internal_counter]
        if RXDQS_value == " " or RXDQ_value == " ":
            return
        if RXDQS_value > RXDQ_value:
            worksheet.conditional_format(
                row_start + internal_counter,
                col_start + [],  # TODO BUG: list_counter is undefined
                row_start + internal_counter,
                col_start + [],  # TODO BUG: list_counter is undefined
                {"type": "cell", "criteria": ">=", "value": RXDQ_value, "format": cell_format_rxdq},
            )


# Checks the min & max requirement for TX only


def sanity_check_MAX_MIN(row_start, col_start, list_of_data_per_param, stress_types):
    for internal_counter in range(int(len(stress_types))):
        list_of_col = list()
        for list_counter in range(int(len(list_of_data_per_param))):
            list_of_col.append(list_of_data_per_param[list_counter][internal_counter])
        if " " in list_of_col:
            continue
        col_max = max(list_of_col)
        col_min = min(list_of_col)
        max_index = list_of_col.index(col_max)
        min_index = list_of_col.index(col_min)
        min_max_ratio = (col_max - col_min) / col_max
        if min_max_ratio > 0.15:
            worksheet.conditional_format(
                row_start + max_index,
                col_start + internal_counter,
                row_start + max_index,
                col_start + internal_counter,
                {"type": "cell", "criteria": ">=", "value": 0, "format": cell_format_min_max},
            )
            worksheet.conditional_format(
                row_start + min_index,
                col_start + internal_counter,
                row_start + min_index,
                col_start + internal_counter,
                {"type": "cell", "criteria": ">=", "value": 0, "format": cell_format_min_max},
            )

# Runs the sanity checks required for LCDL & CLKTREE only


def sanity_check_LCDL_CLKTREE(
    row_start, col_start, parameter_name, list_of_data_per_param, stress_types
):
    # print('r',row_start,'c',col_start,'p',parameter_name,'l',list_of_data_per_param,'s',stress_types)
    if parameter_name == "rise delay(psec)":
        sanity_check_increasing_fall_rise_vertically(row_start, col_start, list_of_data_per_param)

    if parameter_name == "fall delay(psec)":
        sanity_check_increasing_fall_rise_vertically(row_start, col_start, list_of_data_per_param)

    if parameter_name == "DC(%)":
        sanity_check_dc(row_start, col_start, list_of_data_per_param, stress_types)


# Runs the sanity checks required for RX only


def sanity_check_RX(
    row_start,
    col_start,
    parameter_name,
    fresh_total_delays,
    stressed_total_delays,
    stress_types,
    block_names,
):
    sanity_check_RXDQ_RXDQS(row_start, col_start, stressed_total_delays, block_names)


# Runs the sanity checks required for TX only


def sanity_check_TX(
    row_start, col_start, parameter_name, fresh_total_delays, stressed_total_delays, stress_types
):
    sanity_check_MAX_MIN(row_start, col_start, stressed_total_delays, stress_types)


# Runs the ph1 - ph0 calculation on LCDL


def LCDL_calculation(fresh_data, stress_data, row_start_formula, col_start_data_fresh):
    for data in fresh_data:
        for i, _ in enumerate(data):
            if data[i] == " ":
                data[i] = 0
    for data in stress_data:
        for i, _ in enumerate(data):
            if data[i] == " ":
                data[i] = 0
    highlight = workbook.add_format({"bg_color": "#FFFF00", "border": 1})
    col_counter = 0
    fresh_difference = fresh_data[-1][0] - fresh_data[0][0]
    list_of_stress_difference = [a - b for a, b in zip(stress_data[-1], stress_data[0])]
    worksheet.write(row_start_formula, col_start_data_fresh, fresh_difference, fresh_data_color)
    for difference in list_of_stress_difference:
        if difference != 0:
            worksheet.write(
                row_start_formula, col_start_data_fresh + 1 + col_counter, difference, highlight
            )
        col_counter += 1
    worksheet.write(
        row_start_formula, col_start_data_fresh - 2, "ph(1UI) - ph(0)", stress_type_cell
    )

    # Filling in empty cells with color based on template requests
    worksheet.write(row_start_formula, col_start_data_fresh - 1, None, blank_cells_format)
    worksheet.write(row_start_formula - 1, col_start_data_fresh - 1, None, blank_cells_format)
    worksheet.write(row_start_formula - 1, col_start_data_fresh - 2, None, blank_cells_format)
    worksheet.write(row_start_formula - 1, col_start_data_fresh, None, fresh_data_color)


# Checks the given destination path and file name for validity and existance, returns if URL, directory, or current working directory


def check_path(string):  # noqa: C901
    string_split = string.rsplit("/", 1)[0]
    if not string.endswith(".xlsx") or string == ".xlsx":
        print("Error! Output file name must end in .xlsx")
        sys.exit()

    elif "/" not in string:
        if os.path.isfile(string):
            print(
                "The file "
                + string
                + " already exists in the current directory. Please rename or remove and try again"
            )
            sys.exit()
        else:
            return "cwd"

    elif "https://" in string:
        if "sp-sg" not in string:
            print("Please ensure destination URL is a valid Sharepoint path")
            sys.exit()
        else:
            f = open("url_check.txt", "w+")
            check = (
                "curl --ntlm -k --silent --user "
                + getpass.getuser()
                + ":"
                + "'"
                + getpass.getpass("Enter password:")
                + "'"
                + ' --head "'
                + string_split
                + '" --output url_check.txt'
            )
            os.system(check)
            unauthorized_count = 0
            line_counter = 0
            for line in f:
                line_counter += 1
                if " 200 " in line or " 302 " in line:
                    f.close()
                    os.remove("url_check.txt")
                    return "sharepoint"
                elif " 404 " in line:
                    f.close()
                    print(
                        string_split + " does not exist. Please double check the URL and try again"
                    )
                    sys.exit()
                elif " 401 " in line:
                    unauthorized_count += 1
                    if unauthorized_count == 2:
                        f.close()
                        print(
                            "You do not have permission at " + string_split + ". Please try again"
                        )
                        sys.exit()
            if line_counter == 0:
                print(string_split + " does not exist. Please double check the URL and try again")
                f.close()
                sys.exit()
            else:
                print("Error with destination path. Please double check the URL and try again")
                sys.exit()

    elif os.access(string_split, os.W_OK):
        if os.path.isfile(string):
            print(
                "The file "
                + string.rsplit("/", 1)[1]
                + " already exists in "
                + string_split
                + ". Please rename or remove and try again"
            )
            sys.exit()
        else:
            return "directory"

    elif not os.access(string_split, os.F_OK):
        print(
            string_split
            + " does not exist, or you do not have permission to write there. Please try again"
        )
        sys.exit()
    else:
        print(
            "Error with destination path. Please ensure that it is a valid Sharepoint URL or directory path, followed by /<output_name.xlsx>."
        )
        sys.exit()


# Outer frame of GUI


class ScrolledFrame(tk.Frame):
    def __init__(self, parent, vertical=True, horizontal=False):
        super().__init__(parent)

        # canvas for inner frame
        self._canvas = tk.Canvas(self)
        self._canvas.grid(row=0, column=0, sticky="news")  # changed

        # create right scrollbar and connect to canvas Y
        self._vertical_bar = tk.Scrollbar(self, orient="vertical", command=self._canvas.yview)
        if vertical:
            self._vertical_bar.grid(row=0, column=1, sticky="ns")
        self._canvas.configure(yscrollcommand=self._vertical_bar.set)

        # create bottom scrollbar and connect to canvas X
        self._horizontal_bar = tk.Scrollbar(self, orient="horizontal", command=self._canvas.xview)
        if horizontal:
            self._horizontal_bar.grid(row=1, column=0, sticky="we")
        self._canvas.configure(xscrollcommand=self._horizontal_bar.set)

        # inner frame for widgets
        self.inner = tk.Frame(self._canvas, bg="red")
        self._window = self._canvas.create_window((0, 0), window=self.inner, anchor="nw")

        # autoresize inner frame
        self.columnconfigure(0, weight=1)  # changed
        self.rowconfigure(0, weight=1)  # changed

        # resize when configure changed
        self.inner.bind("<Configure>", self.resize)
        self._canvas.bind("<Configure>", self.frame_width)

    def frame_width(self, event):
        # resize inner frame to canvas size
        canvas_width = event.width
        self._canvas.itemconfig(self._window, width=canvas_width)

    def resize(self, event=None):
        self._canvas.configure(scrollregion=self._canvas.bbox("all"))


# DISPLAYS HELP MESSAGE AND DETERMINES OPTIONAL PARAMETERS
description = """This script automatically extracts Aging simulation data from XML reports into Excel files for timing rollup. Details can be found at: https://sp-sg/sites/ddr-ckt-meth/SitePages/AgingScript.aspx#aging1

Description:
            The script requires you to provide the PVTs you wish to extract. By default, the script runs with the GUI.
            -config <config file> Runs the script with a config file. See below for an example.

            You will need to provide the GUI or the config file with the destination where you wish to save the output,
            in the form of either <URL>/<output_name.xlsx>, <directory>/<output_name.xlsx>, or <output_name.xlsx>.
            If you provide just the output name, the file will be saved in the current local directory.
Usage:
            AgingDataExtraction_v1.py [-config <config file>] [-h/--help]
            1. Enter your password
            2. Select the orientation for each block
Examples:
            AgingDataExtraction_v1.py
            AgingDataExtraction_v1.py -config <config file>"""

epilog = """
**************************
**  SAMPLE CONFIG FILE  **
**************************
[CONFIG]
destination=		https://sp-sg/sites/msip-eddr/proj/eddra/ckt/Shared%20Documents/CAD%20Docs/Aging/output.xlsx
hmf=			LPDDR54

[TX-LP5]
report_path= 		/slowfs/us01dwt2p374/meth_examples/aging/aging_data_harvesting/sample_reports/sample8
testbench_mode=		TMI
process_type=       	["tt","ss"]
fresh_vdd_setups=    	["0.765","0.675"]
fresh_vddq_setups=   	["0.45","0.45"]
fresh_temp_setups=   	["-40","-40"]
stress_vdd_setups=   	["0.8925","0.7875"]
stress_vddq_setups=  	["0.57","0.57"]
stress_temp_setups=  	["125","125"]
freq_setup=          	["3200","3200"]"""

parser = argparse.ArgumentParser(
    description=description, epilog=epilog, formatter_class=RawTextHelpFormatter, usage=SUPPRESS
)
parser.add_argument("-config", metavar="<config file>", help="Run with config file")
args = parser.parse_args()


# Run GUI if user did not specify config file
if not args.config:  # noqa: C901

    root = tk.Tk()
    window = ScrolledFrame(root)
    window.pack(expand=True, fill="both")
    root.wm_title("Aging Extraction")

    # lists to store variable names for convenience
    HMFS = ["LPDDR54", "DDR54", "LPDDR5XM", "HME", "HMD", "HMB", "HMA_PLUS", "HMA", "LPDDR5X"]

    Models = ["TMI", "MOSRA"]

    # Class for checklists that display the blocks and modes
    class Checkbar(tk.Frame):
        def __init__(self, parent=None, picks=[], side=tk.LEFT, anchor=tk.W):
            tk.Frame.__init__(self, parent)
            self.vars = []
            for pick in picks:
                var = tk.IntVar()
                chk = self.Checkbutton = tk.Checkbutton(self, text=pick, variable=var)
                chk.pack(side=side, anchor=anchor, expand=tk.YES)
                self.vars.append(var)

        def state(self):
            return map((lambda var: var.get()), self.vars)

    # Class that renders all the inputs in the GUI
    class Aging:
        def __init__(self, parent, bg="#a6a6a6"):
            self.report = tk.StringVar()  # to make it an instance variable, we need prefix .self
            self.destination = tk.StringVar()
            self.hmf = tk.IntVar()
            self.mode = tk.IntVar()
            self.process = tk.StringVar()
            self.fresh_vdd = tk.StringVar()
            self.fresh_vddq = tk.StringVar()
            self.fresh_temp = tk.StringVar()
            self.stress_vdd = tk.StringVar()
            self.stress_vddq = tk.StringVar()
            self.stress_temp = tk.StringVar()
            self.freq = tk.StringVar()
            self.table_nums = []
            self.tag_names = []
            self.a_process = []
            self.a_fresh_vdd = []
            self.a_fresh_vddq = []
            self.a_fresh_temp = []
            self.a_stress_vdd = []
            self.a_stress_vddq = []
            self.a_stress_temp = []
            self.a_freq = []
            self.lcdl_state = tk.IntVar()
            self.clktree_state = tk.IntVar()
            self.i = 0  # Counter
            self.parent = parent
            self.parent.configure(background="gray85")
            self.start()

        def start(self):
            # self.S1 = tk.Button(self.parent, text= "Start Over", command=self.StartOver).pack(anchor=tk.NE)

            self.Label = tk.Label(
                self.parent,
                text="Report Path:",
                justify=tk.LEFT,
                padx=20,
            ).pack()
            self.myEntry = tk.Entry(self.parent, textvariable=self.report, width=20)
            self.myEntry.focus()
            self.myEntry.pack(pady=(0, 10))

            self.Label = tk.Label(self.parent, text="Destination:", justify=tk.LEFT, padx=20).pack()
            self.myEntry = tk.Entry(self.parent, textvariable=self.destination, width=20)
            self.myEntry.focus()
            self.myEntry.pack(pady=(0, 10))

            self.Label = tk.Label(
                self.parent, text="""Choose a HMF:""", justify=tk.LEFT, padx=20
            ).pack()
            for val, HMF in enumerate(HMFS):
                self.Radiobutton = tk.Radiobutton(
                    self.parent, text=HMF, padx=20, variable=self.hmf, value=val
                ).pack(anchor=tk.W)

            self.B1 = tk.Button(self.parent, text="Enter", command=self.get_modes)
            self.B1.pack(anchor=tk.W)

        # def StartOver(self):
        # 	list_slave = self.parent.pack_slaves()
        # 	for l in list_slave:
        # 		l.destroy()
        # 	self.start()

        # Display modes based on what HMF user selected

        def get_modes(self):
            self.B1.destroy()

            if self.hmf.get() == 0:
                self.tx_list = ["TX-LP4", "TX-LP5", "TX-LP4X"]
                self.rx_list = ["RX-LP4", "RX-LP5", "RX-LP4X"]

            elif self.hmf.get() == 1:
                self.tx_list = ["TX-D5", "TX-D4"]
                self.rx_list = ["RX-D5", "RX-D4"]

            elif self.hmf.get() == 2:
                self.tx_list = ["TX-LP4", "TX-LP5", "TX-LP4X", "TX-D5"]
                self.rx_list = ["RX-LP4", "RX-LP5", "RX-LP4X", "RX-D5"]

            elif self.hmf.get() == 3:
                self.tx_list = ["TX-D4", "TX-LPD4X", "TX-LPD4", "TX-D3", "TX-D3L"]
                self.rx_list = ["RX-D4", "RX-LPD4X", "RX-LPD4", "RX-D3", "RX-D3L"]

            elif self.hmf.get() == 4:
                self.tx_list = ["TX-D4", "TX-LPD4", "TX-D3", "TX-D3L"]
                self.rx_list = ["RX-D4", "RX-LPD4", "RX-D3", "RX-D3L"]

            elif self.hmf.get() == 5:
                self.tx_list = ["TX-D4", "TX-LPD4", "TX-D3", "TX-D3L"]
                self.rx_list = ["RX-D4", "RX-LPD4", "RX-D3", "RX-D3L"]

            elif self.hmf.get() == 6:
                self.tx_list = ["TX-D4", "TX-LPD4", "TX-D3", "TX-D3L"]
                self.rx_list = ["RX-D4", "RX-LPD4", "RX-D3", "RX-D3L"]

            elif self.hmf.get() == 7:
                self.tx_list = ["TX-D4", "TX-LPD4", "TX-D3", "TX-D3L"]
                self.rx_list = ["RX-D4", "RX-LPD4", "RX-D3", "RX-D3L"]
            elif self.hmf.get() == 8:
                self.tx_list = ["TX-LP5"]
                self.rx_list = ["RX-LP5"]

            self.Label = tk.Label(
                self.parent, text="""Choose a Mode/Block:""", justify=tk.LEFT, padx=20
            ).pack()

            self.Checkbutton = tk.Checkbutton(self.parent, text="LCDL", variable=self.lcdl_state).pack(
                anchor=tk.W
            )
            self.Checkbutton = tk.Checkbutton(
                self.parent, text="CLKTREE", variable=self.clktree_state
            ).pack(anchor=tk.W)

            self.tx = Checkbar(self.parent, self.tx_list)
            self.tx.pack(side=tk.TOP, fill=tk.X)
            self.tx.config(relief=tk.GROOVE, bd=2)

            self.rx = Checkbar(self.parent, self.rx_list)
            self.rx.pack(side=tk.TOP, fill=tk.X)
            self.Button = tk.Button(
                self.parent, text="Enter", command=lambda: [self.get_states(), self.get_table_num()]
            )
            self.Button.pack(anchor=tk.W)

        # Check the states (0/1) of each checkbox
        def get_states(self):
            if self.lcdl_state.get() == 1:
                self.tag_names.append("LCDL")

            if self.clktree_state.get() == 1:
                self.tag_names.append("CLKTREE")

            self.tx_state = list(self.tx.state())
            self.rx_state = list(self.rx.state())

            for count, state in enumerate(self.tx_state):
                if state == 1:
                    self.tag_names.append(self.tx_list[count])

            for count, state in enumerate(self.rx_state):
                if state == 1:
                    self.tag_names.append(self.rx_list[count])

        # Asks for number of tables for each block/mode selected
        def get_table_num(self):
            self.Button.destroy()

            self.Label = tk.Label(
                self.parent, text="Number of Tables for: ", justify=tk.LEFT, padx=20
            ).pack()
            for tag in self.tag_names:
                num = tk.IntVar()
                self.Label = tk.Label(self.parent, text=tag + ":").pack()
                myEntry = tk.Entry(self.parent, width=20, textvariable=num)
                myEntry.pack()
                myEntry.delete(0, "end")
                self.table_nums.append(num)

            self.Button = tk.Button(self.parent, text="Enter", command=self.check_table_num).pack(
                anchor=tk.W
            )

        def check_table_num(self):
            try:
                if not all(num.get() % 2 == 0 for num in self.table_nums):
                    self.Label = tk.Label(
                        self.parent,
                        text="\nNumber of Tables must be even, please try again ",
                        justify=tk.LEFT,
                        padx=20,
                    ).pack()
                    print("ERROR!")
                else:
                    self.get_data()

            except tk.TclError:
                self.Label = tk.Label(self.parent, text="Number of tables cannot be blank").pack()

        def get_data(self):
            slave_list = self.parent.pack_slaves()
            for slave in slave_list:
                slave.destroy()

            self.Label = tk.Label(
                self.parent,
                text="Table Data for " + self.tag_names[self.i],
                justify=tk.LEFT,
                padx=20,
            ).pack(pady=(0, 10))

            self.Label = tk.Label(
                self.parent, text="Process (ex.: tt,ss,..):", justify=tk.LEFT, padx=20
            ).pack()
            self.myEntry = tk.Entry(self.parent, textvariable=self.process, width=20)
            self.myEntry.pack()
            self.myEntry.delete(0, "end")

            self.Label = tk.Label(self.parent, text="VDD_fresh:", justify=tk.LEFT, padx=20).pack()
            self.myEntry = tk.Entry(self.parent, textvariable=self.fresh_vdd, width=20)
            self.myEntry.pack()
            self.myEntry.delete(0, "end")

            self.Label = tk.Label(self.parent, text="VDDQ_fresh:", justify=tk.LEFT, padx=20).pack()
            self.myEntry = tk.Entry(self.parent, textvariable=self.fresh_vddq, width=20)
            self.myEntry.pack()
            self.myEntry.delete(0, "end")

            self.Label = tk.Label(self.parent, text="Temp_fresh:", justify=tk.LEFT, padx=20).pack()
            self.myEntry = tk.Entry(self.parent, textvariable=self.fresh_temp, width=20)
            self.myEntry.pack()
            self.myEntry.delete(0, "end")

            self.Label = tk.Label(self.parent, text="VDD_stress:", justify=tk.LEFT, padx=20).pack()
            self.myEntry = tk.Entry(self.parent, textvariable=self.stress_vdd, width=20)
            self.myEntry.pack()
            self.myEntry.delete(0, "end")

            self.Label = tk.Label(self.parent, text="VDDQ_stress:", justify=tk.LEFT, padx=20).pack()
            self.myEntry = tk.Entry(self.parent, textvariable=self.stress_vddq, width=20)
            self.myEntry.pack()
            self.myEntry.delete(0, "end")

            self.Label = tk.Label(self.parent, text="Temp_stress:", justify=tk.LEFT, padx=20).pack()
            self.myEntry = tk.Entry(self.parent, textvariable=self.stress_temp, width=20)
            self.myEntry.pack()
            self.myEntry.delete(0, "end")

            self.Label = tk.Label(self.parent, text="Freq/BR:", justify=tk.LEFT, padx=20).pack()
            self.myEntry = tk.Entry(self.parent, textvariable=self.freq, width=20)
            self.myEntry.pack()
            self.myEntry.delete(0, "end")

            tk.Label(self.parent, text="Model:", justify=tk.LEFT, padx=20).pack()
            for val, Model in enumerate(Models):
                self.Radiobutton = tk.Radiobutton(
                    self.parent, text=Model, padx=20, variable=self.mode, value=val
                ).pack(anchor=tk.N)

            if self.i == len(self.table_nums) - 1:
                self.Button = tk.Button(
                    self.parent, text="Submit", command=lambda: [self.result()]
                ).pack(anchor=tk.W)
            else:
                self.Button = tk.Button(
                    self.parent, text="Next Table", command=lambda: [self.result()]
                ).pack(anchor=tk.W)

        def result(self):
            self.a_process.append([x.strip() for x in self.process.get().split(",")])
            self.a_fresh_vdd.append([x.strip() for x in self.fresh_vdd.get().split(",")])
            self.a_stress_vdd.append([x.strip() for x in self.stress_vdd.get().split(",")])
            self.a_fresh_vddq.append([x.strip() for x in self.fresh_vddq.get().split(",")])
            self.a_stress_vddq.append([x.strip() for x in self.stress_vddq.get().split(",")])
            self.a_fresh_temp.append([x.strip() for x in self.fresh_temp.get().split(",")])
            self.a_stress_temp.append([x.strip() for x in self.stress_temp.get().split(",")])
            self.a_freq.append([x.strip() for x in self.freq.get().split(",")])

            if self.i == len(self.table_nums) - 1:
                root.destroy()
                return

            else:
                self.i += 1
                self.get_data()

    # main
    p = Aging(window.inner)
    root.geometry("500x600")
    root.mainloop()

    # getting hmf
    hmf = HMFS[p.hmf.get()]

    # geting modes
    tag_names = p.tag_names

    # geting mode
    if p.mode.get() == 0:
        mode = "TMI"
    else:
        mode = "MOSRA"


cwd = os.getcwd()  # current directory

# username = getpass.getuser()

hmf_excel = cwd + "/" + "aging_data_harvesting_config.xlsx"
# config_path = "https://sp-sg/sites/msip-eddr/proj/eddra/ckt/Shared%20Documents/CAD%20Docs/Aging/aging_data_harvesting_config.xlsx" #it cuts everything after .xlsx including itself
#
# Checks the existence of the config file entered
# if args.config:
# 	hmf_config = cwd + '/' + args.config
# 	hmf_config_exists = os.path.isfile(hmf_config)
# 	if not hmf_config_exists:
# 		print('The inputted config file does not exist, please try again')
# 		sys.exit()
#
# Checks password for access to Sharepoint
# incorrectattempts = 0
# while True:
# 	print ("Enter password for", username,":")
# 	pw = getpass.getpass("")
#
# 	f = open("passwordcheck.txt", "w+")
# 	check='curl --ntlm -k --silent --user '+username+':'+ "'" + pw + "'"+ ' --head --fail ' +config_path+ ' --output "passwordcheck.txt" '
# 	os.system(check)
# 	counter = 0
# 	for line in f:
# 		if ' 401 ' in line:
# 			counter += 1
# 	f.close()
#
# 	if counter >= 2:
# 		if incorrectattempts >= 3:
# 			print('WARNING! You have inputted an incorrect password 3 or more times, script wil now exit to prevent account lockout')
# 			sys.exit()
# 		else:
# 			print('ERROR! The inputted password is incorrect, or you do not have access to the Sharepoint. Please try again')
# 			incorrectattempts += 1
# 	else:
# 		break
#
# os.remove("passwordcheck.txt")


# If the config xlsx exists, remove
if os.path.isfile(hmf_excel):
    os.remove("aging_data_harvesting_config.xlsx")

subprocess.check_output(
    "p4 sync -f //wwcad/msip/projects/common_gr/ddr/aging/aging_data_harvesting_config.xlsx",
    shell=True,
)
subprocess_return = subprocess.check_output(
    "p4 where //wwcad/msip/projects/common_gr/ddr/aging/aging_data_harvesting_config.xlsx",
    shell=True,
    encoding="utf8",
)

xlsx_path = subprocess_return.split(" ")[2].rstrip()
os.system("cp " + xlsx_path + " .")

# Downloads the config xlsx from Sharepoint
# downloadfile = 'wget -q --user='+username+' --password='+ "'" + pw + "'" +' '+ config_path
# os.system(downloadfile)


if len(sys.argv) == 1:
    destination = p.destination.get()
    L = tag_names
    L = ["Aging Sim Condition"] + L

else:
    config = configparser.ConfigParser(interpolation=None)
    config.read(args.config)
    L = config.sections()
    destination = config.get("CONFIG", "destination")
    hmf = config.get("CONFIG", "hmf").upper()
    # hmf = hmf_name.upper()
    if hmf not in [
        "LPDDR54",
        "DDR54",
        "LPDDR5XM",
        "HME",
        "HMD",
        "HMB",
        "HMA_PLUS",
        "HMA",
        "DDR45LITE",
        "LPDDR5X",
    ]:
        print("ERROR! The inputted HMF name is invalid, please try again...")
        sys.exit()

    L = config.sections()
    L = ["Aging Sim Condition"] + L
    L.remove("CONFIG")


check_destination = check_path(destination)
if check_destination == "sharepoint" or check_destination == "directory":
    output_path = destination.rsplit("/", 1)[0]
    output_name = destination.rsplit("/", 1)[1]
elif check_destination == "cwd":
    output_name = destination


# EXCEL FILE GENERATED HERE, IF CATCH ERROR LATER PLEASE DELETE
workbook = xlsxwriter.Workbook(output_name)


# parse hmf config excel #
headers_and_sheet_info_and_modes = parse_hmf_config(hmf_excel, hmf)
headers = headers_and_sheet_info_and_modes[0]

hmf_info = headers_and_sheet_info_and_modes[1]

hmf_modes = headers_and_sheet_info_and_modes[2]
generic_info_and_generic_headers = parse_hmf_generic(hmf_excel)
generic_info = generic_info_and_generic_headers[0]
generic_headers = generic_info_and_generic_headers[1]

# define starting row/col for parameters and data #
row_start_param = 9
row_start_data = 10
row_start_formula = 14
col_start_param = 1
col_start_data_fresh = 3
col_start_data_stress = 4
stress_type_start_row = 7
stress_type_start_col = 4

# get generic information for each module #
duration_index = generic_headers.index("Duration")
stress_type_index = generic_headers.index("Stress Types")
TX_Parameter_index = generic_headers.index("TX Parameters")
RX_Parameter_index = generic_headers.index("RX Parameters")
LCDL_Parameter_index = generic_headers.index("LCDL Parameters")
CLKTREE_Parameter_index = generic_headers.index("CLKTREE Parameters")
duration = generic_info[duration_index][0]
stress_types = generic_info[stress_type_index]
number_of_stress_types = int(len(stress_types))


# define width of each table #
if number_of_stress_types < 5:
    number_of_stress_types_margin = 5
else:
    number_of_stress_types_margin = number_of_stress_types
stress_start_col = 4
width_of_table = stress_start_col + number_of_stress_types_margin


# get indices for each header #
blocks_index = headers.index("Block Name")
macro_names_index = headers.index("macros")
v_domains_index = headers.index("voltage domain")
fresh_v_variables_index = headers.index("vdd and vddq fresh variable")
stress_v_variables_index = headers.index("vdd and vddq stress variable")
rise_variables_index = headers.index("rise variables")
fall_variables_index = headers.index("fall variables")
dc_variables_index = headers.index("DC variables")
ddj_diff_variables_index = headers.index('ddj_diff variables')  # Requested to remove ddj_diff, commented in case needed in future;Uncommented ddj is needed
fresh_temp_variables_index = headers.index("Fresh temp variables")
stress_temp_variables_index = headers.index("Stress temp variables")
process_variables_index = headers.index("Process Variables")
BR_variables_index = headers.index("Bit Rate/Freq Variables")
stress_mode_index = headers.index("Stress Mode Variables")
mode_variables_index = headers.index("Mode Variables")
tb_index = headers.index("Table Test-Bench Name")
fresh_pattern_index = headers.index("Fresh (Toggle) Pattern")
stress_pattern_index = headers.index("Stress (Toggle) Pattern")


# set up formats for the spreadsheet #
full_border = workbook.add_format({"border": 1, "border_color": "#000000"})
bold = workbook.add_format({"bold": True})
merge_format_long = workbook.add_format()
merge_format_long.set_text_wrap()
cell_format_rise = workbook.add_format({"font_color": "red", "border": 1})
cell_format_rise2 = workbook.add_format({"font_color": "red", "bg_color": "#FFC7CE", "border": 1})
cell_format_fall = workbook.add_format({"font_color": "orange", "border": 1})
cell_format_fall2 = workbook.add_format(
    {"font_color": "orange", "bg_color": "#FFC7CE", "border": 1}
)
cell_format_eol_vs_bol = workbook.add_format({"bg_color": "#FFC7CE", "border": 1})  # light pink
cell_format_dc1 = workbook.add_format({"bg_color": "cyan", "border": 1})
cell_format_dc2 = workbook.add_format({"bg_color": "silver", "border": 1})
cell_format_rxdq = workbook.add_format({"bg_color": "magenta", "border": 1})
cell_format_increasing = workbook.add_format({"bg_color": "#CC99FF", "border": 1})  # light purple
cell_format_min_max = workbook.add_format({"bg_color": "lime", "border": 1})
empty_cell_format = workbook.add_format({"bg_color": "#FF6466", "border": 1})  # light red

# generate spreading sheets for each module #
for sheet_name in L:  # noqa: C901
    worksheet = workbook.add_worksheet(sheet_name)
    module_type = sheet_name.split("-", 1)[0]  # remove everything in sheet_name after '-'
    if sheet_name == "Aging Sim Condition":
        # generating info page for color code #
        counted_row = 0
        explanation_starting_row = 0
        worksheet.merge_range(
            explanation_starting_row + counted_row,
            1,
            explanation_starting_row + counted_row,
            12,
            "Sanity Check Failure Color Codes",
            bold,
        )
        counted_row += 1
        worksheet.merge_range(
            explanation_starting_row + counted_row,
            1,
            explanation_starting_row + counted_row,
            12,
            "General Requirements",
            bold,
        )
        counted_row += 1
        worksheet.merge_range(
            explanation_starting_row + counted_row,
            1,
            explanation_starting_row + counted_row,
            12,
            "Failure - Rise delay must be maximum for static1 as compared to all other patterns",
            cell_format_rise,
        )
        counted_row += 1
        worksheet.merge_range(
            explanation_starting_row + counted_row,
            1,
            explanation_starting_row + counted_row,
            12,
            "Failure - Fall delay must be maximum for static0 as compared to all other patterns",
            cell_format_fall,
        )
        counted_row += 1
        worksheet.merge_range(
            explanation_starting_row + counted_row,
            1,
            explanation_starting_row + counted_row,
            12,
            "Failure - EOL delay must be greater than BOL delay",
            cell_format_eol_vs_bol,
        )
        counted_row += 1
        worksheet.merge_range(
            explanation_starting_row + counted_row,
            1,
            explanation_starting_row + counted_row,
            12,
            " ",
            merge_format_long,
        )
        counted_row += 1
        worksheet.merge_range(
            explanation_starting_row + counted_row,
            1,
            explanation_starting_row + counted_row,
            12,
            " ",
            merge_format_long,
        )
        counted_row += 1
        worksheet.merge_range(
            explanation_starting_row + counted_row,
            1,
            explanation_starting_row + counted_row,
            12,
            "LCDL & CLKTREE",
            bold,
        )
        counted_row += 1
        worksheet.merge_range(
            explanation_starting_row + counted_row,
            1,
            explanation_starting_row + counted_row,
            12,
            "Failure due to non increasing rise & fall delay vertically",
            cell_format_increasing,
        )
        counted_row += 1
        worksheet.merge_range(
            explanation_starting_row + counted_row,
            1,
            explanation_starting_row + counted_row,
            12,
            "Failure due to delta from 50% not increasing vertically static1 & static0 (DC only)",
            cell_format_dc2,
        )
        counted_row += 1
        worksheet.merge_range(
            explanation_starting_row + counted_row,
            1,
            explanation_starting_row + counted_row,
            12,
            "Failure due to static1 > 50 or static0 < 50 (DC only)",
            cell_format_dc1,
        )
        counted_row += 1
        worksheet.merge_range(
            explanation_starting_row + counted_row,
            1,
            explanation_starting_row + counted_row,
            12,
            " ",
            merge_format_long,
        )
        counted_row += 1
        worksheet.merge_range(
            explanation_starting_row + counted_row,
            1,
            explanation_starting_row + counted_row,
            12,
            " ",
            merge_format_long,
        )
        counted_row += 1
        worksheet.merge_range(
            explanation_starting_row + counted_row,
            1,
            explanation_starting_row + counted_row,
            12,
            "TX (only vdd+vddq needs to be validated)",
            bold,
        )
        counted_row += 1
        worksheet.merge_range(
            explanation_starting_row + counted_row,
            1,
            explanation_starting_row + counted_row,
            12,
            "Failure of min & max requirement (max - min)/max < 15%",
            cell_format_min_max,
        )
        counted_row += 1
        worksheet.merge_range(
            explanation_starting_row + counted_row,
            1,
            explanation_starting_row + counted_row,
            12,
            " ",
            merge_format_long,
        )
        counted_row += 1
        worksheet.merge_range(
            explanation_starting_row + counted_row,
            1,
            explanation_starting_row + counted_row,
            12,
            " ",
            merge_format_long,
        )
        counted_row += 1
        worksheet.merge_range(
            explanation_starting_row + counted_row,
            1,
            explanation_starting_row + counted_row,
            12,
            "RX (only vdd+vddq needs to be validated)",
            bold,
        )
        counted_row += 1
        worksheet.merge_range(
            explanation_starting_row + counted_row,
            1,
            explanation_starting_row + counted_row,
            12,
            "Failure of rxdq & rxdqs requirement (rxdq > rxdqs)",
            cell_format_rxdq,
        )
        counted_row += 1
        worksheet.merge_range(
            explanation_starting_row + counted_row,
            1,
            explanation_starting_row + counted_row,
            12,
            " ",
            merge_format_long,
        )
        counted_row += 1
        worksheet.merge_range(
            explanation_starting_row + counted_row,
            1,
            explanation_starting_row + counted_row,
            12,
            " ",
            merge_format_long,
        )
        counted_row += 1
        worksheet.merge_range(
            explanation_starting_row + counted_row,
            1,
            explanation_starting_row + counted_row,
            12,
            "Missing data. Data must be present for compatibility with timing rollup",
            empty_cell_format,
        )
        counted_row = +1

    if sheet_name != "Aging Sim Condition":
        print("Extracting data for the " + sheet_name + " block...")

        # initialize list for variants are not found in report #
        unfound_variants = list()
        process_types = list()
        list_of_variant_values = list()
        # get data from config txt(GUI in the future) #
        if len(sys.argv) == 1:
            report_path = p.report.get()
            testbench_mode = mode
            process_types = p.a_process[L.index(sheet_name) - 1]
            fresh_vdd_setups = p.a_fresh_vdd[L.index(sheet_name) - 1]
            fresh_vddq_setups = p.a_fresh_vddq[L.index(sheet_name) - 1]
            fresh_temp_setups = p.a_fresh_temp[L.index(sheet_name) - 1]
            stress_vdd_setups = p.a_stress_vdd[L.index(sheet_name) - 1]
            stress_vddq_setups = p.a_stress_vddq[L.index(sheet_name) - 1]
            stress_temp_setups = p.a_stress_temp[L.index(sheet_name) - 1]
            freq_setups = p.a_freq[L.index(sheet_name) - 1]
            number_of_tables = len(process_types)
        else:
            report_path = config.get(sheet_name, "report_path")
            testbench_mode = config.get(sheet_name, "testbench_mode")
            process_types = json.loads(config.get(sheet_name, "process_type"))
            fresh_vdd_setups = json.loads(config.get(sheet_name, "fresh_vdd_setups"))
            fresh_vddq_setups = json.loads(config.get(sheet_name, "fresh_vddq_setups"))
            fresh_temp_setups = json.loads(config.get(sheet_name, "fresh_temp_setups"))
            stress_vdd_setups = json.loads(config.get(sheet_name, "stress_vdd_setups"))
            stress_vddq_setups = json.loads(config.get(sheet_name, "stress_vddq_setups"))
            stress_temp_setups = json.loads(config.get(sheet_name, "stress_temp_setups"))
            freq_setups = json.loads(config.get(sheet_name, "freq_setup"))
            number_of_tables = len(process_types)

        if report_path.startswith("srv") or report_path.startswith("SRV"):
            report = "srv"
        else:
            report = "xml"

        list_of_parameters = generic_info[generic_headers.index(module_type + " Parameters")]

#        if "ddj_dif" in list_of_parameters[-1]:
#            del list_of_parameters[-1]  # Requested to removed ddj_diff; Commenting this. ddj is needed

        # hard coded for RX in LPDDR54 and LPDDR5XM parameters #
        if module_type == "RX" and (hmf == "LPDDR54" or hmf == "LPDDR5XM" or hmf == "LPDDR5X"):
            list_of_parameters = ["rise delay(psec)", "fall delay(psec)"]
        number_of_param = int(
            len(list_of_parameters)
        )  # Taken from generic page of excel config file

        # parse hmf information from config excel #
        hmf_mode_index = hmf_modes.index(sheet_name)
        blocks = hmf_info[blocks_index][hmf_modes.index(sheet_name)]
        number_of_blocks = int(len(blocks))
        macro_names = hmf_info[macro_names_index][hmf_modes.index(sheet_name)]
        macro_names_no_duplicate = list(OrderedDict.fromkeys(macro_names))
        v_domain_names = hmf_info[v_domains_index][hmf_modes.index(sheet_name)]
        v_domain_names_dc = ["vdd+vddq" for m in range(int(len(macro_names_no_duplicate)))]
        v_domain_names_total_delay = ["vdd+vddq" for m in range(int(len(macro_names_no_duplicate)))]
        fresh_v_variables = hmf_info[fresh_v_variables_index][hmf_mode_index]
        stress_v_variables = hmf_info[stress_v_variables_index][hmf_mode_index]
        rise_variables = hmf_info[rise_variables_index][hmf_mode_index]
        fall_variables = hmf_info[fall_variables_index][hmf_mode_index]
        dc_variables = hmf_info[dc_variables_index][hmf_mode_index]
        ddj_diff_variables = hmf_info[ddj_diff_variables_index][hmf_mode_index]  # Requested to remove ddj_diff, commented in case needed in future;Uncommented, need ddj
        fresh_temp_variables = hmf_info[fresh_temp_variables_index][hmf_mode_index]
        fresh_temp_setup_variable = fresh_temp_variables[0]

        stress_temp_variables = hmf_info[stress_temp_variables_index][hmf_mode_index]
        stress_temp_setup_variable = stress_temp_variables[0]
        original_process_variables = hmf_info[process_variables_index][hmf_mode_index]

        # the one below removes the underscores from process variables read from excel config to match the actual variable names in the xml (not the grey headers on top)
        process_variables = [
            variable.replace("_", "")
            for variable in hmf_info[process_variables_index][hmf_mode_index]
        ]
        original_process_variable = original_process_variables[0]

        process_variable = process_variables[0]

        BR_variables = hmf_info[BR_variables_index][hmf_mode_index]
        freq_variable = BR_variables[0]

        stress_mode_variables = hmf_info[stress_mode_index][hmf_mode_index]
        stress_mode_variable = stress_mode_variables[0]
        mode_variables = hmf_info[mode_variables_index][hmf_mode_index]
        testbenches = hmf_info[tb_index][hmf_modes.index(sheet_name)]
        fresh_pattern = hmf_info[fresh_pattern_index][hmf_mode_index]
        stress_pattern = hmf_info[stress_pattern_index][hmf_mode_index]
        if len(stress_pattern) != 18:
            raise ValueError("Please put lowercase 'na' for empty toggle values")

        # print(stress_pattern)

        # GUI class for selecting orientation and macros

        class CreateList:
            def __init__(self, parent, bg="#a6a6a6"):
                self.parent = parent
                self.parent.configure(background="gray85")
                self.value1 = tk.StringVar()
                self.value2 = tk.StringVar()
                self.value3 = tk.StringVar()
                self.return_value = []
                self.createTitle()

            def createTitle(self):
                self.label = tk.Label(
                    self.parent, text="Choose the orientation for each block:"
                ).pack()

            def start(self, index):
                for block in temp_list:
                    if index == 0:
                        self.Radiobutton = tk.Radiobutton(
                            self.parent, text=block, variable=self.value1, value=block, padx=20
                        ).pack(anchor=tk.W)
                    elif index == 1:
                        self.Radiobutton = tk.Radiobutton(
                            self.parent, text=block, variable=self.value2, value=block, padx=20
                        ).pack(anchor=tk.W)
                    elif index == 2:
                        self.Radiobutton = tk.Radiobutton(
                            self.parent, text=block, variable=self.value3, value=block, padx=20
                        ).pack(anchor=tk.W)
                self.label = tk.Label(self.parent, text="").pack(pady=(10, 0))

            def enter(self):
                self.Button = tk.Button(self.parent, text="Enter", command=self.returnChoice).pack()

            def returnChoice(self):
                value1 = self.value1.get()
                value2 = self.value2.get()
                value3 = self.value3.get()
                if value1 != 0:
                    self.return_value.append(value1)
                    if value2 != 0:
                        self.return_value.append(value2)
                        if value3 != 0:
                            self.return_value.append(value3)
                root.destroy()

        root = tk.Tk()
        root.title(sheet_name)
        root.geometry("400x400")
        window = ScrolledFrame(root)
        window.pack(expand=True, fill="both")

        # Checks for duplicate block names to reduce redundancy in GUI
        unique_blocks = []
        for block in blocks:
            if block not in unique_blocks:
                unique_blocks.append(block)

        # Cleans up block names for consistency
        unique_blocks_cleaned = []
        for i in range(len(unique_blocks)):
            if unique_blocks[i].endswith("_ns") or unique_blocks[i].endswith("_ew"):
                unique_blocks_cleaned.append(unique_blocks[i].rsplit("_", 1)[0])
            else:
                unique_blocks_cleaned.append(unique_blocks[i])

        # Creates the GUI for orientation selection
        a = CreateList(window.inner)

        # Creates a list of options for the GUI
        for block in unique_blocks_cleaned:
            temp_list = []
            temp_list.append(block)
            temp_list.append(block + "_ns")
            temp_list.append(block + "_ew")
            temp_list.append("None")
            a.start(unique_blocks_cleaned.index(block))

        # Creates the enter button
        a.enter()

        # Preselects the default values
        a.value1.set(unique_blocks[0])
        if len(unique_blocks) == 2:
            a.value2.set(unique_blocks[1])
        if len(unique_blocks) == 3:
            a.value3.set(unique_blocks[2])
            a.value2.set(unique_blocks[1])

        # Runs the GUI
        window.mainloop()

        # Returns the list of options chosen from GUI
        return_list = a.return_value

        # Replaces elements in blocks with chosen ones from GUI
        for j in range(len(blocks)):
            blocks[j] = return_list[unique_blocks.index(blocks[j])]

        # If user selects None for all blocks, error out
        if all(x == "None" for x in blocks):
            print("ERROR! You must select at least one block!")
            workbook.close()
            os.remove(output_name)
            sys.exit()

        # Checks if any options were none to print out a warning
        if "None" in blocks:
            warning = True
        else:
            warning = False

        # Prints a warning on top of each sheet
        warning_format = workbook.add_format(
            {"bold": True, "font_color": "red", "font_size": 20, "align": "center"}
        )
        if warning:
            for i in range(int(number_of_tables / 2)):
                worksheet.merge_range(
                    0,
                    1 + i * 20,
                    0,
                    19 + i * 20,
                    "THIS IS AN INCOMPLETE TABLE. DATA FOR ALL BLOCKS MUST BE AUTOFILLED USING THE SCRIPT FOR TIMING ROLLUP",
                    warning_format,
                )
        else:
            for i in range(int(number_of_tables / 2)):
                worksheet.merge_range(
                    0,
                    1 + i * 20,
                    0,
                    19 + i * 20,
                    "PLEASE DO NOT MANUALLY MODIFY THIS SHEET AND THE SHEET NAME FOR COMPATIBILITY WITH TIMING ROLLUP",
                    warning_format,
                )

        # generate tables for each module #
        for i in range(number_of_tables):

            # Check if testbench is named incorrectly in excel config file
            should_not_contain = ["_tmi_", "_TMI_", "_drs_", "_DRS_"]

            for s in should_not_contain:
                if any(s in tb_name for tb_name in testbenches):
                    print("ERROR!")
                    print("Test-bench name should not contain '%s'" % s.replace("_", ""))
                    edit_log_file([], [], [], "", "", "", s.replace("_", ""))
                    workbook.close()
                    os.remove(output_name)
                    sys.exit()

            if testbench_mode == "TMI":
                stress_testbenches = [s + "_tmi_eol_stress" for s in testbenches]
                fresh_testbenches = [s + "_tmi_fresh" for s in testbenches]

            elif testbench_mode == "MOSRA":
                stress_testbenches = [s + "_drs_eol_stress" for s in testbenches]
                fresh_testbenches = [s + "_drs_fresh" for s in testbenches]

            else:
                print("ERROR!")
                print("Test-bench mode not found!")
                sys.exit()

            # list_of_variant_values
            process_type = process_types[i].lower().strip("\u200b")
            process_value = (process_variable + "_" + process_type).strip("\u200b")
            fresh_vdd_setup = fresh_vdd_setups[i].strip("\u200b")
            fresh_vddq_setup = fresh_vddq_setups[i].strip("\u200b")
            fresh_temp_setup = str(fresh_temp_setups[i]).strip("\u200b")
            stress_vdd_setup = stress_vdd_setups[i].strip("\u200b")
            stress_vddq_setup = stress_vddq_setups[i].strip("\u200b")
            stress_temp_setup = stress_temp_setups[i].strip("\u200b")
            freq_setup = freq_setups[i].strip("\u200b")

            # set up formats for each table #
            headers_color = workbook.add_format()
            parameters_color = workbook.add_format()

            worksheet.set_column((1 + i * width_of_table), (1 + i * width_of_table), 14)

            # Hex values for colors - colors to make tables more distinct
            if (i % 2) == 0:
                dark_color = "#E26B0A"
                light_color = "#FABF8F"
                fresh_color = "#FCD5B4"
            else:
                dark_color = "#76933C"
                light_color = "#C4D79B"
                fresh_color = "#D8E4BC"

            headers_color.set_bg_color(dark_color)
            headers_merge_format = workbook.add_format({"align": "center", "bg_color": dark_color})
            parameters_color.set_bg_color(light_color)
            parameters_merge_format = workbook.add_format(
                {"align": "center", "bg_color": light_color}
            )
            fresh_data_color = workbook.add_format({"bg_color": fresh_color, "border": 1})
            stress_type_cell = workbook.add_format(
                {"align": "vjustify", "bg_color": light_color, "border": 1}
            )

            sheet_name_format = workbook.add_format(
                {"align": "left", "valign": "bottom", "bg_color": light_color}
            )

            # generate title for each corner #
            worksheet.write(1, (1 + i * width_of_table), "Mode", headers_color)
            worksheet.write(2, (2 + i * width_of_table), "corner", headers_color)
            worksheet.write(2, (5 + i * width_of_table), "corner", headers_color)
            worksheet.write(3, (2 + i * width_of_table), "VDD", headers_color)
            worksheet.write(3, (5 + i * width_of_table), "VDD", headers_color)
            worksheet.write(4, (2 + i * width_of_table), "Temp.", headers_color)
            worksheet.write(4, (5 + i * width_of_table), "Temp.", headers_color)
            worksheet.write(5, (2 + i * width_of_table), "VDDQ", headers_color)
            worksheet.write(5, (5 + i * width_of_table), "VDDQ", headers_color)
            worksheet.write(9, (3 + i * width_of_table), "No Stress")
            worksheet.merge_range(
                1,
                (2 + i * width_of_table),
                1,
                (4 + i * width_of_table),
                "No Stress and EOL Condition",
                headers_merge_format,
            )
            worksheet.merge_range(
                1,
                (5 + i * width_of_table),
                1,
                (9 + i * width_of_table),
                "Stress Condition",
                headers_merge_format,
            )
            worksheet.merge_range(
                2, (1 + i * width_of_table), 3, (1 + i * width_of_table), hmf, headers_merge_format
            )
            worksheet.merge_range(
                6,
                (4 + i * width_of_table),
                6,
                (4 + number_of_stress_types - 1 + i * width_of_table),
                "Stress Type",
                parameters_merge_format,
            )
            print_stress_types(
                stress_type_start_row,
                (stress_type_start_col + i * width_of_table),
                stress_types,
                stress_type_cell,
                parameters_merge_format,
            )

            # add PVT setups to title #
            worksheet.merge_range(
                2,
                (3 + i * width_of_table),
                2,
                (4 + i * width_of_table),
                process_types[i],
                headers_merge_format,
            )
            worksheet.merge_range(
                2,
                (6 + i * width_of_table),
                2,
                (9 + i * width_of_table),
                process_types[i],
                headers_merge_format,
            )

            worksheet.write(4, (1 + i * width_of_table), duration, headers_color)
            worksheet.write(5, (1 + i * width_of_table), freq_setup, headers_color)
            worksheet.merge_range(
                6,
                (1 + i * width_of_table),
                8,
                (1 + i * width_of_table),
                sheet_name,
                sheet_name_format,
            )
            worksheet.merge_range(
                4,
                (3 + i * width_of_table),
                4,
                (4 + i * width_of_table),
                fresh_temp_setup,
                headers_merge_format,
            )
            worksheet.merge_range(
                5,
                (6 + i * width_of_table),
                5,
                (9 + i * width_of_table),
                stress_vddq_setup,
                headers_merge_format,
            )
            worksheet.merge_range(
                3,
                (3 + i * width_of_table),
                3,
                (4 + i * width_of_table),
                fresh_vdd_setup,
                headers_merge_format,
            )
            worksheet.merge_range(
                5,
                (3 + i * width_of_table),
                5,
                (4 + i * width_of_table),
                fresh_vddq_setup,
                headers_merge_format,
            )
            worksheet.merge_range(
                3,
                (6 + i * width_of_table),
                3,
                (9 + i * width_of_table),
                stress_vdd_setup,
                headers_merge_format,
            )
            worksheet.merge_range(
                4,
                (6 + i * width_of_table),
                4,
                (9 + i * width_of_table),
                stress_temp_setup,
                headers_merge_format,
            )

            # Color in blanks
            blank_cells_format = workbook.add_format({"bg_color": light_color, "border": 1})
            worksheet.merge_range(
                6, (2 + i * width_of_table), 7, (2 + i * width_of_table), None, blank_cells_format
            )
            worksheet.merge_range(
                6, (3 + i * width_of_table), 7, (3 + i * width_of_table), None, blank_cells_format
            )
            worksheet.write(8, (2 + i * width_of_table), None, blank_cells_format)
            worksheet.write(8, (3 + i * width_of_table), None, blank_cells_format)

            # POTENTIAL LOCATION TO FIX UNFOUND VALUES DUE TO BLOCK DIFFERENCES
            if ("TX" in sheet_name and sheet_name != "TX-LP4") or (
                "RX" in sheet_name and (hmf != "LPDDR54" or hmf != "LPDDR5XM" or hmf != "LPDDR5X")
            ):
                fresh_vddq_setup_variable = fresh_v_variables[0]
                fresh_vdd_setup_variable = fresh_v_variables[1]
                stress_vddq_setup_variable = stress_v_variables[0]
                stress_vdd_setup_variable = stress_v_variables[1]
                list_of_variant_names = [
                    original_process_variable,
                    fresh_vddq_setup_variable,
                    fresh_vdd_setup_variable,
                    stress_vddq_setup_variable,
                    stress_vdd_setup_variable,
                    fresh_temp_setup_variable,
                    stress_temp_setup_variable,
                    freq_variable,
                ]
                list_of_variant_values = [
                    process_value,
                    fresh_vddq_setup,
                    fresh_vdd_setup,
                    stress_vddq_setup,
                    stress_vdd_setup,
                    fresh_temp_setup,
                    stress_temp_setup,
                    freq_setup,
                ]

            else:
                fresh_vdd_setup_variable = fresh_v_variables[0]
                stress_vdd_setup_variable = stress_v_variables[0]
                list_of_variant_names = [
                    original_process_variable,
                    fresh_vdd_setup_variable,
                    stress_vdd_setup_variable,
                    fresh_temp_setup_variable,
                    stress_temp_setup_variable,
                    freq_variable,
                ]
                list_of_variant_values = [
                    process_value,
                    fresh_vdd_setup,
                    stress_vdd_setup,
                    fresh_temp_setup,
                    stress_temp_setup,
                    freq_setup,
                ]

            if "TX" in sheet_name:
                # Requested to remove ddj_diff, commented in case needed in future; Uncommented, need ddj
                list_of_all_measurements = [rise_variables, fall_variables, rise_variables, fall_variables, dc_variables, ddj_diff_variables]
                list_of_all_measurements = [
                    rise_variables,
                    fall_variables,
                    rise_variables,
                    fall_variables,
                    dc_variables,
                    ddj_diff_variables
                ]
            elif "RX" in sheet_name:
                list_of_all_measurements = [
                    rise_variables,
                    fall_variables,
                    rise_variables,
                    fall_variables,
                    ddj_diff_variables
                ]
            else:
                list_of_all_measurements = [rise_variables, fall_variables, dc_variables,ddj_diff_variables]

            # EMPTY LOG FILE FIRST
            open("run.log", "w+").close()
            for j in range(int(number_of_param)):
                number_of_testbenches = int(len(stress_testbenches))
                measurements = list_of_all_measurements[j]
                stressed_total_delays = list()

                if report == "srv":
                    fresh_data = read_srv(
                        blocks,
                        fresh_testbenches,
                        measurements,
                        list_of_variant_names,
                        list_of_variant_values,
                        stress_types,
                        stress_mode_variable,
                        stress_pattern,
                    )[0]

                    data = read_srv(
                        blocks,
                        stress_testbenches,
                        measurements,
                        list_of_variant_names,
                        list_of_variant_values,
                        stress_types,
                        stress_mode_variable,
                        stress_pattern,
                    )
                    stress_data = data[0]
                    unfound_variants = data[1]
                    param_not_found = data[2]
                    variant_value_not_found = data[3]

                else:
                    fresh_data = read_xml(
                        report_path,
                        blocks,
                        fresh_testbenches,
                        measurements,
                        list_of_variant_names,
                        list_of_variant_values,
                        stress_types,
                        stress_mode_variable,
                        stress_pattern,
                    )[0]
                    data = read_xml(
                        report_path,
                        blocks,
                        stress_testbenches,
                        measurements,
                        list_of_variant_names,
                        list_of_variant_values,
                        stress_types,
                        stress_mode_variable,
                        stress_pattern,
                    )
                    # print(fresh_data, "***",data)
                    stress_data = data[0]
                    unfound_variants = data[1]
                    param_not_found = data[2]
                    variant_value_not_found = data[3]

                # add info before listing errors
                if param_not_found or variant_value_not_found:

                    print("ERROR! The script did not run successfully!")
                    print("Excel file was not generated...")
                    print("Please check run.log")
                    workbook.close()
                    os.remove(output_name)
                    sys.exit()

                # write data
                if sheet_name == "LCDL":
                    is_lcdl = True
                else:
                    is_lcdl = False

                if (
                    list_of_parameters[j] != "rise delay(psec)"
                    and list_of_parameters[j] != "fall delay(psec)"
                ):
                    if "total" in list_of_parameters[j]:
                        print_parameters(
                            row_start_param,
                            (col_start_param + i * width_of_table),
                            list_of_parameters[j],
                            macro_names_no_duplicate,
                            v_domain_names_total_delay,
                            number_of_stress_types - 1,
                            parameters_merge_format,
                            parameters_color,
                            is_lcdl,
                        )

                        stressed_total_delays = total_delay(stress_data)
                        fresh_total_delays = total_delay(fresh_data)
                        write_stressed_data(
                            row_start_data,
                            (col_start_data_stress + i * width_of_table),
                            stressed_total_delays,
                        )
                        write_fresh_data(
                            row_start_data,
                            (col_start_data_fresh + i * width_of_table),
                            fresh_total_delays,
                        )
                        param_margin = int(len(macro_names_no_duplicate)) + 2
                    else:
                        print_parameters(
                            row_start_param,
                            (col_start_param + i * width_of_table),
                            list_of_parameters[j],
                            macro_names_no_duplicate,
                            v_domain_names_dc,
                            number_of_stress_types - 1,
                            parameters_merge_format,
                            parameters_color,
                            is_lcdl,
                        )
                        write_stressed_data(
                            row_start_data,
                            (col_start_data_stress + i * width_of_table),
                            stress_data,
                        )
                        write_fresh_data(
                            row_start_data, (col_start_data_fresh + i * width_of_table), fresh_data
                        )
                        param_margin = int(len(macro_names_no_duplicate)) + 2

                else:
                    print_parameters(
                        row_start_param,
                        (col_start_param + i * width_of_table),
                        list_of_parameters[j],
                        macro_names,
                        v_domain_names,
                        number_of_stress_types - 1,
                        parameters_merge_format,
                        parameters_color,
                        is_lcdl,
                    )
                    write_stressed_data(
                        row_start_data, (col_start_data_stress + i * width_of_table), stress_data
                    )
                    write_fresh_data(
                        row_start_data, (col_start_data_fresh + i * width_of_table), fresh_data
                    )
                    param_margin = int(len(macro_names)) + 2

                # sanity checks #

                sanity_check_general(
                    row_start_data,
                    (col_start_data_stress + i * width_of_table),
                    fresh_data,
                    stress_data,
                    stress_types,
                    list_of_parameters[j],
                )
                if "total" in list_of_parameters[j]:
                    if "TX" in sheet_name and not warning:
                        sanity_check_TX(
                            row_start_data,
                            (col_start_data_stress + i * width_of_table),
                            list_of_parameters[j],
                            fresh_total_delays,
                            stressed_total_delays,
                            stress_types,
                        )
                    if "RX" in sheet_name and not warning:
                        sanity_check_RX(
                            row_start_data,
                            (col_start_data_stress + i * width_of_table),
                            list_of_parameters[j],
                            fresh_total_delays,
                            stressed_total_delays,
                            stress_types,
                            macro_names,
                        )

                if sheet_name == "LCDL":
                    sanity_check_LCDL_CLKTREE(
                        row_start_data,
                        (col_start_data_stress + i * width_of_table),
                        list_of_parameters[j],
                        stress_data,
                        stress_types,
                    )

                    if j != 2:  # Don't do calculation for DC
                        LCDL_calculation(
                            fresh_data,
                            stress_data,
                            row_start_formula,
                            (col_start_data_fresh + i * width_of_table),
                        )

                    param_margin = int(len(macro_names)) + 3

                if sheet_name == "CLKTREE":
                    sanity_check_LCDL_CLKTREE(
                        row_start_data,
                        (col_start_data_stress + i * width_of_table),
                        list_of_parameters[j],
                        stress_data,
                        stress_types,
                    )

                row_start_data += param_margin
                row_start_param += param_margin
                row_start_formula += param_margin
            # reset starting row #
            row_start_param = 9
            row_start_data = 10
            row_start_formula = 14

            worksheet.conditional_format("A1:AO50", {"type": "no_blanks", "format": full_border})
            # indicate completion of a table
            print("The script ran successfully for current table...")
    worksheet.protect(
        "".join(
            random.SystemRandom().choice(
                string.ascii_uppercase + string.ascii_lowercase + string.digits
            )
            for _ in range(10)
        )
    )
# final message signalling completion of script
# print ("Script has finished running successfully!")
# print ("Output file name: " + output_name)
open("run.log", "w+").close()
workbook.close()


# Saves the output where the user chose
if check_destination == "cwd":  # noqa: C901
    print(output_name + " saved in current directory")

elif check_destination == "directory":
    # In case the user puts full path of current directory
    if os.path.isfile(output_path + "/" + output_name):
        os.system("cp -f " + output_name + " " + output_name + "1")
        os.system("rm -f " + output_name)
        os.system("mv -f " + output_name + "1" + " " + output_name)
    else:
        os.system("mv -f " + output_name + " " + output_path)
    print(output_name + " saved at " + output_path)
elif check_destination == "sharepoint":
    f = open("upload_check.txt", "w+")
    os.system(
        "curl --ntlm --silent --output upload_check.txt --user "
        + getpass.getuser()
        + ":"
        + "'"
        + getpass.getpass("Enter password for upload:")
        + "'"
        + " --head  -k --upload-file "
        + cwd
        + "/"
        + output_name
        + ' "'
        + output_path
        + '/"'
    )
    count = 0
    success = False
    for line in f:
        if " 201 " in line or " 200 " in line:
            print(output_name + " uploaded to " + output_path)
            os.remove(output_name)
            f.close()
            success = True
            break

        elif " 401 " in line:
            count += 1
            if count == 2:
                print(
                    "You do not have permission to upload to "
                    + output_path
                    + ". "
                    + output_name
                    + " has been saved in the current directory."
                )
                success = True
                break
        elif " 400 " in line:
            print(
                "The upload to Sharepoint failed. The URL may be too long. "
                + output_name
                + " has been saved in the current directory."
            )
            success = True
            break
    f.close()
    os.remove("upload_check.txt")
    if not success:
        print(
            "The upload to Sharepoint failed. Please ensure that the URL is correct and you have authorization. "
            + output_name
            + " has been saved in the current directory."
        )

print("Script has finished running successfully!")
