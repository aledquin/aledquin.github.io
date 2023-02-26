#!/depot/Python/Python-3.8.0/bin/python
###############################################################################
#
# Name    : test_ibis_correlation_report.py
# Author  : Raneem Khalil
# Date     : 2022-07-13 14:24:12
# Purpose : Test the IBIS Quality script on different inputs.
###############################################################################

__author__ = 'Raneem Khalil'
__version__ = '2022ww28'

import argparse
import atexit
import os
import pathlib
import sys
# nolint utils__script_usage_statistics

# ---------------------------------- #
bindir = str(pathlib.Path(__file__).resolve().parent)
sys.path.append(bindir + '../../lib/python/Util')
sys.path.append(bindir + '../../lib/python')
sys.path.append(bindir + '../data')
# ---------------------------------- #

# Import script containing testcases
import test_create_spreadsheet
# Import constants
from CommonHeader import NONE
# Import messaging subroutines
from Messaging import iprint, hprint
# Import logging routines
from Messaging import create_logger, footer, header
# Import run_system_cmd
from Misc import run_system_cmd
import CommonHeader


def parse_args():
    # Always include -v, and -d
    parser = argparse.ArgumentParser(description='Script runs tescases for ibis_correlation_report.py script')
    parser.add_argument('-v', metavar='<#>', type=int, default=0, help='verbosity')
    parser.add_argument('-d', metavar='<#>', type=int, default=0, help='debug')
    args = parser.parse_args()
    return args


def print_test_results(output: str) -> None:
    """Prints tests results from output if return code is not 0."""
    for result in output:
        if result != 0:
            iprint(str(result))


# YOUR CODE goes in Main #
def main():
    verbosity = NONE

    os.chdir(bindir + '/../bin')
    wb, ws = test_create_spreadsheet.create_workbook()
    test_create_spreadsheet.write_to_spreadsheet_correct_format(ws, wb)
    command = 'ibis_correlation_report.py -correlationFile correlationReport.xlsx'
    hprint('Running: ' + command)
    output = run_system_cmd(command, verbosity)
    print_test_results(output)
    iprint("Finished command\n\n")

    os.chdir(bindir + '/../bin')
    wb, ws = test_create_spreadsheet.create_workbook()
    test_create_spreadsheet.save_html(ws, wb)
    command = 'ibis_correlation_report.py -correlationFile correlationReport.html'
    hprint('Running: ' + command)
    output = run_system_cmd(command, verbosity)
    print_test_results(output)
    iprint("Finished command\n\n")

    os.chdir(bindir + '/../bin')
    wb = test_create_spreadsheet.create_workbook_incorrect_sheet_name()
    command = 'ibis_correlation_report.py -correlationFile correlationReportIncorrectSheetName.xlsx'
    hprint('Running: ' + command)
    output = run_system_cmd(command, verbosity)
    print_test_results(output)
    iprint("Finished command\n\n")

    os.chdir(bindir + '/../bin')
    wb, ws = test_create_spreadsheet.create_workbook()
    test_create_spreadsheet.write_to_spreadsheet_no_ibis_columns(ws, wb)
    command = 'ibis_correlation_report.py -correlationFile correlationReportNoIbisColumns.xlsx'
    hprint('Running: ' + command)
    output = run_system_cmd(command, verbosity)
    print_test_results(output)
    iprint("Finished command\n\n")

    os.chdir(bindir + '/../bin')
    wb, ws = test_create_spreadsheet.create_workbook()
    test_create_spreadsheet.write_to_spreadsheet_missing_columns(ws, wb)
    command = 'ibis_correlation_report.py -correlationFile correlationReportMissingColumns.xlsx'
    output = run_system_cmd(command, verbosity)
    hprint('Running: ' + command)
    print_test_results(output)
    iprint("Finished command\n\n")

    os.chdir(bindir + '/../bin')
    wb, ws = test_create_spreadsheet.create_workbook()
    test_create_spreadsheet.write_to_spreadsheet_failed_models(ws, wb)
    command = 'ibis_correlation_report.py -correlationFile correlationReportFailedModels.xlsx'
    output = run_system_cmd(command, verbosity)
    hprint('Running: ' + command)
    print_test_results(output)
    iprint("Finished command\n\n")


if __name__ == '__main__':

    args = parse_args()
    filename = os.getcwd() + '/' + os.path.basename(__file__) + '.log'
    # Create log file
    logger = create_logger(filename)

    # Register exit function
    atexit.register(footer)
    # Initalise shared variables and run main
    CommonHeader.init(args, __author__, __version__)

    header()
    main()
    iprint(f"Log file: {filename}")
