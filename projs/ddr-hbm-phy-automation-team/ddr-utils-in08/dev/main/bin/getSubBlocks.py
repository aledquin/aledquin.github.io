#!/depot/Python/Python-3.8.0/bin/python -E
# Gives the list of different cells in a .cdl/.sp netlist file
import os
import subprocess
import collections
import getpass
import sys
import xlsxwriter
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

from Messaging import iprint, eprint
# Import logging routines
from Messaging import create_logger, footer, header
# Import run_system_cmd
from Misc import run_system_cmd, utils__script_usage_statistics,get_release_version
import CommonHeader

__version__ = get_release_version(bindir)
utils__script_usage_statistics(__file__, __version__)

global all_netlists, release, rel
all_netlists = []
release = str(input('Enter version: '))
rel = '/{}/'.format(release)


def parse_args():

    # Always include -v, and -d
    parser = argparse.ArgumentParser(description='description here')
    parser.add_argument('-v', metavar='<#>', type=int, default=0,
                        help='verbosity')
    parser.add_argument('-d', metavar='<#>', type=int, default=0,
                        help='debug')

    # Add your custom arguments here
    # -------------------------------------

    # -------------------------------------
    args = parser.parse_args()
    return args


def fillWorkbook(final_list):
    workbook = xlsxwriter.Workbook('cdl_SubBlocks.xlsx')
    worksheet_summary = workbook.add_worksheet('SubBlock Details')

    cell_format_border = workbook.add_format()
    cell_format_border.set_border()

    cell_format_border_bold = workbook.add_format()
    cell_format_border_bold.set_bold()
    cell_format_border_bold.set_border()

    cell_format_border_gray = workbook.add_format()
    cell_format_border_gray.set_border()
    cell_format_border_gray.set_bold()
    cell_format_border_gray.set_bg_color('silver')

    cell_format_border_mergeflat = workbook.add_format()
    cell_format_border_mergeflat.set_border()
    cell_format_border_mergeflat.set_align('center')
    cell_format_border_mergeflat.set_valign('vcenter')
    worksheet_summary.write('A1', 'SubBlock Details', cell_format_border_bold)
    worksheet_summary.merge_range('B1:C1', str(os.getcwd()), cell_format_border_mergeflat)
    worksheet_summary.write('A2', 'MACRO', cell_format_border_gray)
    worksheet_summary.write('B2', 'LIBRARY', cell_format_border_gray)
    worksheet_summary.write('C2', 'CELLS', cell_format_border_gray)

    row = 2
    col = 0

    for macro in sorted(final_list.keys()):
        worksheet_summary.write(row, col, macro, cell_format_border)
        for cell in sorted(final_list[macro]):
            worksheet_summary.write(row, col + 1, cell[0], cell_format_border)
            worksheet_summary.write(row, col + 2, cell[1], cell_format_border)
            row += 1

    workbook.close()


def fillData(f,device_list):
    for linenum in range(len(f)):
        if f[linenum].startswith('*') and 'Library' in f[linenum] and 'Cell' in f[linenum + 1]:
            line1 = f[linenum].split()
            line2 = f[linenum + 1].split()
            device_list.append((line1[-1], line2[-1]))
    return(device_list)


def getFiles():
    for path, subdirs, files in os.walk(os.getcwd()):
        for name in files:
            filename = os.path.join(path, name)
            if os.path.basename(filename).endswith('.cdl') or os.path.basename(filename).endswith('.sp') and rel in filename:
                all_netlists.append(filename)
    return(all_netlists)


def main():
    iprint("Running .cdl/.sp file search ...")
    all_netlists = getFiles()

    iprint(".cdl/.sp file search complete.\n")
    iprint('Found files:')
    for net in all_netlists:
        iprint(net)

    final_list = collections.defaultdict(list)

    if not all_netlists:
        eprint('No *.cdl/.sp* files found in {} and its subdirectories. Exiting ...\n'.format(str(os.getcwd())))
        sys.exit()
        for files in sorted(all_netlists):
            device_list = []

            f = []
            with open(files, 'r') as infile:
                for line in infile:
                    if line.startswith('*') and 'Library' in line:
                        f.append(line)
                        continue
                    elif line.startswith('*') and 'Cell' in line:
                        f.append(line)
                        continue

            device_list = fillData(f,device_list)
            final_list[os.path.splitext(os.path.basename(files))[0]] = device_list
#
#

    fillWorkbook(final_list)
    try:
        (stdout,stderr,stdval) = run_system_cmd('echo "Script Summary:\n-----------------------------------------------\ngetSubBlocks Script Summary\nUser: {}\nPath: {}\nRelease: {}\n-----------------------------------------------\n\nPlease find the report attached." | mail -s "getSubBlocks Report" -a cdl_SubBlocks.xlsx {}@synopsys.com'.format(getpass.getuser(), str(os.getcwd()), release, getpass.getuser()), 0)
    except subprocess.CalledProcessError as exxc:
        eprint("Status : FAIL {} {}".format(exxc.returncode, exxc.output))
    else:
        iprint("Run Complete.")


if __name__ == '__main__':

    args = parse_args()
    log_filename = os.getcwd() + '/' + os.path.basename(__file__) + '.log'
    logger = create_logger(log_filename)                       # Create log file

    # Register exit function
    atexit.register(footer)

    # Initalise shared variables and run main
    CommonHeader.init(args, __author__, __version__)

    header()
    main()
    iprint(f"Log file: {log_filename}")
