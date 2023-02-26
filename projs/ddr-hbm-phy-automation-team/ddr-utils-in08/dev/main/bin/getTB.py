#!/depot/Python/Python-3.8.0/bin/python -E
# Gives list of macros and TBs in a specified P4 path
import subprocess
import os
import re
import sys
import getpass
import xlsxwriter

from colorama import init, Fore
import pathlib
import argparse
import atexit
__author__ = 'dikshant'
# ---------------------------------- #
bindir = str(pathlib.Path(__file__).resolve().parent)
# Add path to library that may be symbolically linked.
sys.path.append(bindir + '/../lib/Util')
# Add path to sharedlib's Python Utilities directory.
sys.path.append(bindir + '/../lib/python/Util')
# ---------------------------------- #

from Messaging import iprint
# Import logging routines
from Messaging import create_logger, footer, header
# Import run_system_cmd
from Misc import utils__script_usage_statistics, get_release_version
import CommonHeader

__version__ = get_release_version(bindir)
utils__script_usage_statistics(__file__, __version__)

init(autoreset=True)


def parse_args():

    # Always include -v, and -d
    parser = argparse.ArgumentParser(description='description here')
    parser.add_argument('-v', metavar='<#>', type=int, default=0,
                        help='verbosity')
    parser.add_argument('-d', metavar='<#>', type=int, default=0,
                        help='debug')

    # Add your custom arguments here
    # -------------------------------------
    parser.add_argument('-p', '--path',metavar='<#>', type=str, default=0,
                        help='debug')

    # -------------------------------------
    args = parser.parse_args()
    return args


def dependencyMap(path):
    # try:
    allFiles = subprocess.check_output("p4 files {}/... | grep '\\.bbSim' | sed -E 's/#.*//g'".format(path), shell=True, stderr=subprocess.STDOUT).decode("utf-8", 'ignore').rstrip()
    if 'no such file(s)' in allFiles:
        print(Fore.YELLOW + 'P4 Project Path {} is not valid. Exiting ...' .format(path))
        usage()
        sys.exit(2)
    else:
        allFiles = allFiles.split('\n')
        # print(allFiles)
    MasterFileList = {}
    MacroList = {}
    for eachFile in allFiles:
        try:
            macro = re.search("/design/sim/([a-z0-9-_.+]+)/", eachFile, re.IGNORECASE).group(1)
        except AttributeError:
            macro = '-'
        MacroList[macro] = path + '/' + macro + '/'
        MasterFileList[eachFile] = [macro, os.path.basename(eachFile)]
    return MasterFileList, MacroList


def usage():
    iprint('Usage: {} -p <project_path>'.format(sys.argv[0]))
    iprint(' -p  = <P4 project path>')
    iprint('Examples:')
    iprint('{} -p //wwcad/msip/projects/hbm3/d750-hbm3-tsmc5ff12/latest/design/sim/'.format(sys.argv[0]))


# Script starts here


def fillWorkbook():
    workbook = xlsxwriter.Workbook('TB_List.xlsx')
    worksheet_summary = workbook.add_worksheet('MacroList')

    cell_format_border = workbook.add_format()
    cell_format_border.set_border()

    cell_format_border_bold = workbook.add_format()
    cell_format_border_bold.set_bold()
    cell_format_border_bold.set_border()

    cell_format_border_merge = workbook.add_format()
    cell_format_border_merge.set_bold()
    cell_format_border_merge.set_border()
    cell_format_border_merge.set_align('center')
    cell_format_border_merge.set_valign('vcenter')

    cell_format_border_mergeflat = workbook.add_format()
    cell_format_border_mergeflat.set_border()
    cell_format_border_mergeflat.set_align('center')
    cell_format_border_mergeflat.set_valign('vcenter')

    cell_format_border_red = workbook.add_format()
    cell_format_border_red.set_border()
    cell_format_border_red.set_bg_color('orange')

    cell_format_border_yellow = workbook.add_format()
    cell_format_border_yellow.set_border()
    cell_format_border_yellow.set_bg_color('cyan')

    cell_format_border_green = workbook.add_format()
    cell_format_border_green.set_border()
    cell_format_border_green.set_bg_color('lime')

    cell_format_border_gray = workbook.add_format()
    cell_format_border_gray.set_border()
    cell_format_border_gray.set_bold()
    cell_format_border_gray.set_bg_color('silver')

    cell_format_border_wrap = workbook.add_format()
    cell_format_border_wrap.set_border()
    cell_format_border_wrap.set_text_wrap()
    cell_format_border_wrap.set_bg_color('orange')

    worksheet_summary.set_column(0, 0, 40)  # Width of column B set to 30.
    worksheet_summary.set_column(1, 1, 110)  # Width of column B set to 30.

    worksheet_summary.write('A1', 'Macro List', cell_format_border_gray)
    worksheet_summary.write('B1', 'P4 Path', cell_format_border_gray)
    return(worksheet_summary,workbook, cell_format_border_bold, cell_format_border, cell_format_border_gray)


def main():
    MasList, MacList = dependencyMap(path)
    (worksheet_summary,workbook, cell_format_border_bold, cell_format_border, cell_format_border_gray) = fillWorkbook()
    row_summary = 1
    col = 0

    for macro in sorted(MacList.keys()):
        worksheet_summary.write(row_summary, col, macro, cell_format_border_bold)
        worksheet_summary.write(row_summary, col + 1, MacList[macro], cell_format_border)
        row_summary += 1
        worksheet_TB = workbook.add_worksheet('{}' .format(macro))
        worksheet_TB.set_column(0, 0, 60)  # Width of column B set to 30.
        worksheet_TB.write('A1', 'Testbench List', cell_format_border_gray)
        row_tb = 1
        for tb in MasList:
            if MasList[tb][0] == macro:
                worksheet_TB.write(row_tb, col, MasList[tb][1], cell_format_border)
                row_tb += 1

    workbook.close()

    try:
        subprocess.call('echo "Script Summary:\n-----------------------------------------------\nTB List Script Details\nUser: {}\nP4 Path: {}\n-----------------------------------------------\n\nPlease find the report attached." | mail -s "TB List" -a TB_List.xlsx {}@synopsys.com'.format(getpass.getuser(), path, getpass.getuser()), shell=True)
    except subprocess.CalledProcessError as exxc:
        print("Status : FAIL {} {}".format(exxc.returncode, exxc.output))
    else:
        print(Fore.GREEN + "Run Complete.")


if __name__ == '__main__':

    args = parse_args()
    log_filename = os.getcwd() + '/' + os.path.basename(__file__) + '.log'
    logger = create_logger(log_filename)
    path = args.path                      
    # Create log file
    try:
        path
    except NameError:
        iprint(Fore.YELLOW + 'Path not defined. Exiting ...\n\n')
        usage()
        sys.exit(2)

    # Register exit function
    atexit.register(footer)

    # Initalise shared variables and run main
    CommonHeader.init(args, __author__, __version__)

    header()
    main()
    iprint(f"Log file: {log_filename}")
