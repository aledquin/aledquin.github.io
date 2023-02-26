#!/depot/Python/Python-3.8.0/bin/python
###############################################################################
#
# Name    : std_template.py
# Author  : your name here
# Date    : creation date here
# Purpose : description of the script.. can put on multiple lines
#
# Modification History
#     000 YOURNAME  CURRENT_DATE
#         Created this script
#     001 YOURNAME DATE_OF_YOUR_CHANGES
#         Description of what you have changed.
#
###############################################################################

__author__ = 'dikshant'

import argparse
import atexit
import pathlib
import sys
import configparser as cp
import pandas as pd
import os
import re
import xlsxwriter
import glob
# ----------------------------------#
bindir = str(pathlib.Path(__file__).resolve().parent)
sys.path.append(bindir + '/../lib/python/Util')
sys.path.append(bindir + '/../lib/python')
# ----------------------------------#

# Import messaging subroutines
from Messaging import iprint, eprint
# Import logging routines
from Messaging import create_logger, footer, header
# Import run_system_cmd
import CommonHeader
from Misc import utils__script_usage_statistics, get_release_version
__version__ = get_release_version(bindir)


def parse_args():

    # Always include -v, and -d
    parser = argparse.ArgumentParser(description='description here')
    parser.add_argument('-v', metavar='<#>', type=int, default=0,
                        help='verbosity')
    parser.add_argument('-d', metavar='<#>', type=int, default=0,
                        help='debug')

    # Add your custom arguments here
    # -------------------------------------
    parser.add_argument('-config', metavar='<#>',required=True,
                        help='config file with voltage information and testbench names')

    # -------------------------------------
    args = parser.parse_args()

    return args


def fill_code(vols, codes, tb, row,
              cleaned_table, res_u, cap_u, worksheet, col):

    for vol in vols:
        if vol in ['vddq','vddval','vdd2val']:
            continue
        codes[tb][vol] = {}
        codes[tb][vol]['ss_rdie'] = cleaned_table[(cleaned_table[vols[0]] == vol) & (cleaned_table.temp == '125') & (cleaned_table.mos == 'mos_ss') & (cleaned_table.res == 'res_s')][res_u].to_string(index=False)
        codes[tb][vol]['tt_rdie'] = cleaned_table[(cleaned_table[vols[0]] == vol) & (cleaned_table.temp == '25') & (cleaned_table.mos == 'mos_tt') & (cleaned_table.res == 'res_t')][res_u].to_string(index=False)
        codes[tb][vol]['ff_rdie'] = cleaned_table[(cleaned_table[vols[0]] == vol) & (cleaned_table.temp == '-40') & (cleaned_table.mos == 'mos_ff') & (cleaned_table.res == 'res_f')][res_u].to_string(index=False)

        codes[tb][vol]['ss_cdie'] = cleaned_table[(cleaned_table[vols[0]] == vol) & (cleaned_table.temp == '125') & (cleaned_table.mos == 'mos_ss') & (cleaned_table.cap == 'cap_s')][cap_u].to_string(index=False)
        codes[tb][vol]['tt_cdie'] = cleaned_table[(cleaned_table[vols[0]] == vol) & (cleaned_table.temp == '25') & (cleaned_table.mos == 'mos_tt') & (cleaned_table.cap == 'cap_t')][cap_u].to_string(index=False)
        codes[tb][vol]['ff_cdie'] = cleaned_table[(cleaned_table[vols[0]] == vol) & (cleaned_table.temp == '-40') & (cleaned_table.mos == 'mos_ff') & (cleaned_table.cap == 'cap_f')][cap_u].to_string(index=False)
        for x in codes[tb][vol].keys():
            codes[tb][vol][x] = re.sub(r'\n.+','',codes[tb][vol][x],re.S)
            if re.search(r'Series',codes[tb][vol][x],re.I):
                codes[tb][vol][x] = "NA"
        worksheet.write(row, col + 1, vol)
        worksheet.write(row, col + 2, codes[tb][vol]['ss_rdie'])
        worksheet.write(row, col + 3, codes[tb][vol]['ss_cdie'])
        worksheet.write(row, col + 4, codes[tb][vol]['tt_rdie'])
        worksheet.write(row, col + 5, codes[tb][vol]['tt_cdie'])
        worksheet.write(row, col + 6, codes[tb][vol]['ff_rdie'])
        worksheet.write(row, col + 7, codes[tb][vol]['ff_cdie'])
        row += 1
    return(codes, row)


def readConfig():
    config = cp.ConfigParser()
    config.read(args.config)
    # Reading variables from config file
    try:
        proj = config['DEFAULT']['project']
    except KeyError:
        eprint("Missing default variable project in config file. Please define it")
        sys.exit(0)

    try:
        cap = config['DEFAULT']['cap_unit']
    except KeyError:
        eprint("Missing default variable cap_unit in config file. Please define it")
        sys.exit(0)

    try:
        res = config['DEFAULT']['res_unit']
    except KeyError:
        eprint("Missing default variable res_unit in config file. Please define it")
        sys.exit(0)

    try:
        rel = config['DEFAULT']['rel']
    except KeyError:
        eprint("Missing default variable rel in config file. Please define it")
        sys.exit(0)

    return(proj, cap, res, rel, config)


def main():

    (proj, cap, res, rel, config) = readConfig()
    try:
        macro = config['DEFAULT']['macro']
    except KeyError:
        eprint("Missing default variable macro in config file. Please define it")
        sys.exit(0)

    res_u = "reff_200e6 ({})".format(res)
    cap_u = "ceff_200e6 ({})".format(cap)

    prod = proj.split('-')[1]

    doc_path = "/remote/proj/{}/{}/{}/documentation/reports/project/{}/".format(prod,proj,rel,macro)
    codes = {}
    workbook = xlsxwriter.Workbook('rdie_sheet.xlsx')
    worksheet = workbook.add_worksheet('rdie_cdie')
    row = 0
    col = 0
    cell_format = workbook.add_format()
    cell_format.set_bold()
    cell_format.set_align('center')
    worksheet.write(row,col,'TESTBENCH',cell_format)
    worksheet.write(row, col + 1, 'Voltage',cell_format)
    worksheet.write(row, col + 2, 'SS 125')
    worksheet.merge_range(row, col + 2, row, col + 3, 'SS 125',cell_format)
    worksheet.write(row, col + 4, 'TT 25')
    worksheet.merge_range(row, col + 4, row, col + 5, 'TT 25',cell_format)

    worksheet.write(row, col + 6, 'FF -40')
    worksheet.merge_range(row, col + 6, row, col + 7, 'FF -40',cell_format)
    row += 1

    row += 1
    for section in config.sections():
        if section == 'DEFAULT':
            continue
        testbench = config[section]['tb_names'].split(',')
        for tb in testbench:
            tb_path = glob.glob("{}/{}/simulation/measurements/*_meas.html".format(doc_path, tb))[0]
            if os.path.isfile(tb_path) is False:
                eprint("{} is not valid,continuing to next testbench".format(tb_path))
                continue
            else:
                tables = pd.read_html(tb_path, header=1,index_col=None)
                codes[tb] = {}
                iprint("Taking values from {}".format(tb_path))
                cleaned_table = tables[1].dropna(thresh=10).drop_duplicates().reset_index(drop=True)
                cleaned_table.drop(cleaned_table[cleaned_table['Process'] == 'Process'].index, inplace=True)
                cleaned_table.reset_index(drop=True,inplace=True)

                vols = config[section]['Voltage'].split(',')

                worksheet.write(row, col + 1,vols[0],cell_format)
                worksheet.write(row, col + 2, 'Rdie ({})'.format(res),cell_format)
                worksheet.write(row, col + 3, 'Cdie ({})'.format(cap),cell_format)

                worksheet.write(row, col + 4, 'Rdie ({})'.format(res),cell_format)
                worksheet.write(row, col + 5, 'Cdie ({})'.format(cap),cell_format)

                worksheet.write(row, col + 6, 'Rdie ({})'.format(res),cell_format)
                worksheet.write(row, col + 7, 'Cdie ({})'.format(cap),cell_format)
                row += 1

                worksheet.write(row, col, tb)
                worksheet.merge_range(row, col, row + 2, col, tb,cell_format)

                (codes, row) = fill_code(vols, codes, tb, row, cleaned_table, res_u, cap_u, worksheet, col)
        row += 3
    workbook.close()

    pass


if __name__ == '__main__':

    args = parse_args()
    filename = os.getcwd() + '/' + os.path.basename(__file__) + '.log'
    logger = create_logger(filename)                       # Create log file

    # Register exit function
    atexit.register(footer)
    utils__script_usage_statistics(filename, __version__)
    CommonHeader.init(args, __author__, __version__)        # Initalise shared variables and run main
    header()
    main()
    iprint(f"Log file: {filename}")
