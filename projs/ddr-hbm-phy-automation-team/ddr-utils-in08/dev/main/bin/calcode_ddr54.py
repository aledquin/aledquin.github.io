#!/depot/Python/Python-3.8.0/bin/python -E

import os
import pandas
import sys
from colorama import init, Fore
import atexit
import pathlib
import argparse
init(autoreset=True)
__author__ = 'DA WG'

# ---------------------------------- #
bindir = str(pathlib.Path(__file__).resolve().parent)
# Add path to library that may be symbolically linked.
sys.path.append(bindir + '/../lib/Util')
# Add path to sharedlib's Python Utilities directory.
sys.path.append(bindir + '/../lib/python/Util')
# ---------------------------------- #
import CommonHeader
from Misc import utils__script_usage_statistics, get_release_version
from Messaging import iprint
from Messaging import create_logger, print_footer, print_header

__version__ = get_release_version(bindir)
utils__script_usage_statistics(__file__, __version__)


pandas.set_option('display.max_rows', 500)
pandas.set_option('display.max_columns', 500)
pandas.set_option('display.width', 1000)


def func(x):
    if 'typ' in x:
        return 1
    elif 'min' in x:
        return 0
    elif 'max' in x:
        return 2


def usage():
    print(Fore.LIGHTRED_EX + 'Usage: {}'.format(sys.argv[0]))
    print(Fore.LIGHTRED_EX + ' Script needs to be executed in the ibis_cal_240_post report directory ONLY.')
    print('Examples:')
    print(Fore.LIGHTGREEN_EX + '{}'.format(sys.argv[0]))


def parse_args():

    # Always include -v, and -d
    parser = argparse.ArgumentParser(description='Script to calculate calcode values', add_help=False)
    parser.add_argument('-v', metavar='<#>', type=int, default=0,
                        help='verbosity')
    parser.add_argument('-d', metavar='<#>', type=int, default=0,
                        help='debug')
    parser.add_argument('-h', metavar='--help', type=int, default=0,
                        help=usage())

    # Add your custom arguments here
    # -------------------------------------

    # -------------------------------------
    args = parser.parse_args()
    return args


def get_reportpath():
    for path, subdirs, files in os.walk(os.getcwd()):
        for name in files:
            filename = os.path.join(path, name)
            if os.path.basename(filename).endswith('meas.html') and 'ibis_cal_240_post' in filename:
                report_path = filename
                break

    try:
        report_path
    except NameError:
        print(Fore.YELLOW + 'No meas.html file found. Exiting ...\n\n')
        usage()
        sys.exit(2)
    else:
        print(Fore.LIGHTGREEN_EX + 'Using {} to generate calcode file...' .format(report_path))

    return(report_path)


def main():    # noqa C901
    print("Running meas.html Search ...")
    report_path = get_reportpath()

    tables = pandas.read_html(report_path, header=1)
    tab_len = int(len(tables[1].columns))
    cleaned_table = tables[1].dropna(thresh=tab_len).drop_duplicates().reset_index(drop=True)
    cleaned_table.drop(cleaned_table[cleaned_table['Process'] == 'Process'].index, inplace=True)

    vddq_values = {}
    vdd_values_a = {}
    vdd_values_b = {}
    temp_values = {}
    code_master_a = {}
    code_master_b = {}
    temp_for_txt = {}

    for col in ['vddq', 'vdd', 'temp']:
        if col == 'vddq':
            vddq_array = sorted(list(cleaned_table[col].unique()))
        # print('VDDQ', vddq_array)
        # print vdd_array

            for val in vddq_array:
                comp_array = [round(float(x) / float(val), 2) for x in vddq_array]
            # print(val, comp_array)
            # print val,comp_array
                if float(1.06) in comp_array and float(0.97) in comp_array:
                    vddq_values[u'ddr5_vddq_typ'] = val
                    vddq_values[u'ddr5_vddq_max'] = vddq_array[comp_array.index(float(1.06))]
                    vddq_values[u'ddr5_vddq_min'] = vddq_array[comp_array.index(float(0.97))]
                if float(1.05) in comp_array and float(0.95) in comp_array:
                    vddq_values[u'ddr4_vddq_typ'] = val
                    vddq_values[u'ddr4_vddq_max'] = vddq_array[comp_array.index(float(1.05))]
                    vddq_values[u'ddr4_vddq_min'] = vddq_array[comp_array.index(float(0.95))]
        elif col == 'temp':
            temp_array = list(cleaned_table[col].unique())
            int_temp = map(int, temp_array)
            for temp in int_temp:
                if temp == min(int_temp):
                    temp_values[u'temp_max', u'ddr4_vddq_max', u'ddr4_vdd_max'] = temp_array[int_temp.index(temp)]
                    temp_values[u'temp_max', u'ddr4_vddq_min', u'ddr4_vdd_min'] = temp_array[int_temp.index(temp)]
                    temp_values[u'temp_max', u'ddr5_vddq_max', u'ddr5_vdd_max'] = temp_array[int_temp.index(temp)]
                    temp_values[u'temp_max', u'ddr5_vddq_min', u'ddr5_vdd_min'] = temp_array[int_temp.index(temp)]
                    temp_for_txt[u'temp_max'] = temp_array[int_temp.index(temp)]
                elif temp == max(int_temp):
                    temp_values[u'temp_min', u'ddr4_vddq_min', u'ddr4_vdd_min'] = temp_array[int_temp.index(temp)]
                    temp_values[u'temp_min', u'ddr5_vddq_min', u'ddr5_vdd_min'] = temp_array[int_temp.index(temp)]
                    temp_for_txt[u'temp_min'] = temp_array[int_temp.index(temp)]
                else:
                    temp_values[u'temp_typ', u'ddr4_vddq_typ', u'ddr4_vdd_typ'] = temp_array[int_temp.index(temp)]
                    temp_values[u'temp_typ', u'ddr5_vddq_typ', u'ddr5_vdd_typ'] = temp_array[int_temp.index(temp)]
                    temp_for_txt[u'temp_typ'] = temp_array[int_temp.index(temp)]
        elif col == 'vdd':
            vdd_array = list(cleaned_table[col].unique())
        # print('VDD', vdd_array)
        # print vdd_array

            for val in vdd_array:
                if val in ['0.75', '0.85']:
                    comp_array = [round(float(x) / float(val), 2) for x in vdd_array]
                # print(val, comp_array)
                # print val,comp_array
                    if float(1.1) in comp_array and float(0.9) in comp_array and val == '0.75':
                        vdd_values_a[u'ddr4_vdd_typ'] = val
                        vdd_values_a[u'ddr4_vdd_max'] = vdd_array[comp_array.index(float(1.1))]
                        vdd_values_a[u'ddr4_vdd_min'] = vdd_array[comp_array.index(float(0.9))]
                        vdd_values_a[u'ddr5_vdd_typ'] = val
                        vdd_values_a[u'ddr5_vdd_max'] = vdd_array[comp_array.index(float(1.1))]
                        vdd_values_a[u'ddr5_vdd_min'] = vdd_array[comp_array.index(float(0.9))]
                    # break
                    elif float(1.1) in comp_array and float(0.9) in comp_array and val == '0.85':
                        vdd_values_b[u'ddr4_vdd_typ'] = val
                        vdd_values_b[u'ddr4_vdd_max'] = vdd_array[comp_array.index(float(1.1))]
                        vdd_values_b[u'ddr4_vdd_min'] = vdd_array[comp_array.index(float(0.9))]
                        vdd_values_b[u'ddr5_vdd_typ'] = val
                        vdd_values_b[u'ddr5_vdd_max'] = vdd_array[comp_array.index(float(1.1))]
                        vdd_values_b[u'ddr5_vdd_min'] = vdd_array[comp_array.index(float(0.9))]
                    # break

    for key in sorted(temp_values.keys()):
        code_master_a[key[0], key[1], key[2], u'p'] = cleaned_table[(cleaned_table['vddq'] == vddq_values[key[1]]) & (cleaned_table['vdd'] == vdd_values_a[key[2]]) & (cleaned_table['temp'] == temp_values[key])]['pcode (CAL)'].values[0]
        code_master_a[key[0], key[1], key[2], u'n'] = cleaned_table[(cleaned_table['vddq'] == vddq_values[key[1]]) & (cleaned_table['vdd'] == vdd_values_a[key[2]]) & (cleaned_table['temp'] == temp_values[key])]['ncode (CAL)'].values[0]
        code_master_b[key[0], key[1], key[2], u'p'] = cleaned_table[(cleaned_table['vddq'] == vddq_values[key[1]]) & (cleaned_table['vdd'] == vdd_values_b[key[2]]) & (cleaned_table['temp'] == temp_values[key])]['pcode (CAL)'].values[0]
        code_master_b[key[0], key[1], key[2], u'n'] = cleaned_table[(cleaned_table['vddq'] == vddq_values[key[1]]) & (cleaned_table['vdd'] == vdd_values_b[key[2]]) & (cleaned_table['temp'] == temp_values[key])]['ncode (CAL)'].values[0]

    codename = {(u'temp_max', u'ddr5_vddq_max', u'ddr5_vdd_max', u'n'): 'n_ddr5_max',
                (u'temp_max', u'ddr5_vddq_max', u'ddr5_vdd_max', u'p'): 'p_ddr5_max',
                (u'temp_max', u'ddr5_vddq_min', u'ddr5_vdd_min', u'n'): 'n_ddr5_min_m40',
                (u'temp_max', u'ddr5_vddq_min', u'ddr5_vdd_min', u'p'): 'p_ddr5_min_m40',
                (u'temp_min', u'ddr5_vddq_min', u'ddr5_vdd_min', u'n'): 'n_ddr5_min',
                (u'temp_min', u'ddr5_vddq_min', u'ddr5_vdd_min', u'p'): 'p_ddr5_min',
                (u'temp_typ', u'ddr5_vddq_typ', u'ddr5_vdd_typ', u'n'): 'n_ddr5_typ',
                (u'temp_typ', u'ddr5_vddq_typ', u'ddr5_vdd_typ', u'p'): 'p_ddr5_typ',
                (u'temp_max', u'ddr4_vddq_max', u'ddr4_vdd_max', u'n'): 'n_ddr4_max',
                (u'temp_max', u'ddr4_vddq_max', u'ddr4_vdd_max', u'p'): 'p_ddr4_max',
                (u'temp_max', u'ddr4_vddq_min', u'ddr4_vdd_min', u'n'): 'n_ddr4_min_m40',
                (u'temp_max', u'ddr4_vddq_min', u'ddr4_vdd_min', u'p'): 'p_ddr4_min_m40',
                (u'temp_min', u'ddr4_vddq_min', u'ddr4_vdd_min', u'n'): 'n_ddr4_min',
                (u'temp_min', u'ddr4_vddq_min', u'ddr4_vdd_min', u'p'): 'p_ddr4_min',
                (u'temp_typ', u'ddr4_vddq_typ', u'ddr4_vdd_typ', u'n'): 'n_ddr4_typ',
                (u'temp_typ', u'ddr4_vddq_typ', u'ddr4_vdd_typ', u'p'): 'p_ddr4_typ'}

    comments_a = {}
    comments_b = {}
    for key in temp_values.keys():
        if key[0] == 'temp_max' and 'max' in key[1]:
            # print(vdd_values.keys())
            comments_a[key] = '*** FF / {}C / {}V / {}V'.format(temp_for_txt[key[0]], vddq_values[key[1]], vdd_values_a[key[2]])
            comments_b[key] = '*** FF / {}C / {}V / {}V'.format(temp_for_txt[key[0]], vddq_values[key[1]], vdd_values_b[key[2]])
        elif key[0] == 'temp_max' and 'min' in key[1]:
            comments_a[key] = '*** SS / {}C / {}V / {}V'.format(temp_for_txt[key[0]], vddq_values[key[1]], vdd_values_a[key[2]])
            comments_b[key] = '*** SS / {}C / {}V / {}V'.format(temp_for_txt[key[0]], vddq_values[key[1]], vdd_values_b[key[2]])
        elif key[0] == 'temp_min' and 'min' in key[1]:
            comments_a[key] = '*** SS / {}C / {}V / {}V'.format(temp_for_txt[key[0]], vddq_values[key[1]], vdd_values_a[key[2]])
            comments_b[key] = '*** SS / {}C / {}V / {}V'.format(temp_for_txt[key[0]], vddq_values[key[1]], vdd_values_b[key[2]])
        elif key[0] == 'temp_typ' and 'typ' in key[1]:
            comments_a[key] = '*** TT / {}C / {}V / {}V'.format(temp_for_txt[key[0]], vddq_values[key[1]], vdd_values_a[key[2]])
            comments_b[key] = '*** TT / {}C / {}V / {}V'.format(temp_for_txt[key[0]], vddq_values[key[1]], vdd_values_b[key[2]])

    with open('cal_code.txt', 'w+') as f:
        f.write('.PARAM\n\n')
        for key in sorted(temp_for_txt.keys(), key=func):
            f.write('+ {} = {}\n' .format(key, temp_for_txt[key]))
        f.write('\n***********************\n**** DDR4          ****\n***********************\n\n')
        for key in sorted(vdd_values_a.keys(), key=func):
            if 'ddr4' in key:
                f.write('+ {} = {}\n' .format(key, vdd_values_a[key]))
        f.write('\n')
        for key in sorted(vddq_values.keys(), key=func):
            if 'ddr4' in key:
                f.write('+ {} = {}\n' .format(key, vddq_values[key]))
        for key in sorted(temp_values.keys(), reverse=True):
            if 'ddr4' in key[1]:
                f.write('\n{}\n\n'.format(comments_a[key]))
                f.write('+ {} = {}\n'.format(codename[key[0], key[1], key[2], u'p'], code_master_a[key[0], key[1], key[2], u'p']))
                f.write('+ {} = {}\n'.format(codename[key[0], key[1], key[2], u'n'], code_master_a[key[0], key[1], key[2], u'n']))
        f.write('\n***********************\n**** DDR5          ****\n***********************\n\n')
        for key in sorted(vdd_values_a.keys(), key=func):
            if 'ddr5' in key:
                f.write('+ {} = {}\n' .format(key, vdd_values_a[key]))
        f.write('\n')
        for key in sorted(vddq_values.keys(), key=func):
            if 'ddr5' in key:
                f.write('+ {} = {}\n' .format(key, vddq_values[key]))
        for key in sorted(temp_values.keys(), reverse=True):
            if 'ddr5' in key[1]:
                f.write('\n{}\n\n'.format(comments_a[key]))
                f.write('+ {} = {}\n'.format(codename[key[0], key[1], key[2], u'p'], code_master_a[key[0], key[1], key[2], u'p']))
                f.write('+ {} = {}\n'.format(codename[key[0], key[1], key[2], u'n'], code_master_a[key[0], key[1], key[2], u'n']))
        f.write('\n***********************\n')

    with open('cal_code_b.txt', 'w+') as f:
        f.write('.PARAM\n\n')
        for key in sorted(temp_for_txt.keys(), key=func):
            f.write('+ {} = {}\n' .format(key, temp_for_txt[key]))
        f.write('\n***********************\n**** DDR4          ****\n***********************\n\n')
        for key in sorted(vdd_values_b.keys(), key=func):
            if 'ddr4' in key:
                f.write('+ {} = {}\n' .format(key, vdd_values_b[key]))
        f.write('\n')
        for key in sorted(vddq_values.keys(), key=func):
            if 'ddr4' in key:
                f.write('+ {} = {}\n' .format(key, vddq_values[key]))
        for key in sorted(temp_values.keys(), reverse=True):
            if 'ddr4' in key[1]:
                f.write('\n{}\n\n'.format(comments_b[key]))
                f.write('+ {} = {}\n'.format(codename[key[0], key[1], key[2], u'p'], code_master_b[key[0], key[1], key[2], u'p']))
                f.write('+ {} = {}\n'.format(codename[key[0], key[1], key[2], u'n'], code_master_b[key[0], key[1], key[2], u'n']))
        f.write('\n***********************\n**** DDR5          ****\n***********************\n\n')
        for key in sorted(vdd_values_b.keys(), key=func):
            if 'ddr5' in key:
                f.write('+ {} = {}\n' .format(key, vdd_values_b[key]))
        f.write('\n')
        for key in sorted(vddq_values.keys(), key=func):
            if 'ddr5' in key:
                f.write('+ {} = {}\n' .format(key, vddq_values[key]))
        for key in sorted(temp_values.keys(), reverse=True):
            if 'ddr5' in key[1]:
                f.write('\n{}\n\n'.format(comments_b[key]))
                f.write('+ {} = {}\n'.format(codename[key[0], key[1], key[2], u'p'], code_master_b[key[0], key[1], key[2], u'p']))
                f.write('+ {} = {}\n'.format(codename[key[0], key[1], key[2], u'n'], code_master_b[key[0], key[1], key[2], u'n']))
        f.write('\n***********************\n')

    iprint('Generated:')
    iprint(Fore.CYAN + '{}/cal_code.txt\n/{}/cal_code_b.txt' .format(os.getcwd(), os.getcwd()))


if __name__ == "__main__":
    args = parse_args()
    print(args)
    filename = os.getcwd() + '/' + os.path.basename(__file__) + '.log'
    logger = create_logger(filename)                       # Create log file

    # Register exit function
    atexit.register(print_footer)

    # Initalise shared variables and run main
    CommonHeader.init(args, __author__, __version__)

    print_header()
    main()
    iprint(f"Log file: {filename}")
