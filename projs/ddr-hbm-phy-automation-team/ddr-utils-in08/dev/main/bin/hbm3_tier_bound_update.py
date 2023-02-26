#!/depot/Python/Python-3.8.0/bin/python -E
# Adds Tier and Bound/Full Definition to macro files.

import os
import sys
import csv
import getopt
from colorama import init, Fore
import pandas as pd
import itertools
import pathlib
init(autoreset=True)


# ----------------------------------#
bindir = str(pathlib.Path(__file__).resolve().parent)
sys.path.append(bindir + '/../lib/python/Util')
sys.path.append(bindir + '/../lib/python')
# ----------------------------------#
from Misc import utils__script_usage_statistics, get_release_version
__version__ = get_release_version(bindir)

utils__script_usage_statistics(__file__, __version__)


def drange(start, stop, step):
    r = start
    while r < stop:
        yield r
        r += step


def bound_list(tb_list):
    result_set = []
    for rows in tb_list[1:-1]:
        row = rows.lower()
        if row != 'na' and row != '':
            if 'm40' in row:
                result_set.append(row.replace('m40', '-40').split('/'))
            else:
                result_set.append(row.split('/'))
    final_set = list(itertools.product(*result_set))

    return final_set


def find_each_and_replace_by(string, substring, separator='x'):
    """
    list(find_each_and_replace_by('8989', '89', 'x'))
    # ['x89', '89x']
    list(find_each_and_replace_by('9999', '99', 'x'))
    # ['x99', '9x9', '99x']
    list(find_each_and_replace_by('9999', '89', 'x'))
    # []
    """
    index = 0
    while True:
        index = string.find(substring, index)
        if index == -1:
            return
        yield string[:index] + separator + string[index + len(substring):]
        index += 1


def contains_all_without_overlap(string, numbers):
    """
    contains_all_without_overlap("45892190", [89, 90])
    # True
    contains_all_without_overlap("45892190", [89, 90, 4521])
    # False
    """
    if len(numbers) == 0:
        return True
    substrings = [str(number) for number in numbers]
    substring = substrings.pop()
    return any(contains_all_without_overlap(shorter_string, substrings)
               for shorter_string in find_each_and_replace_by(string, substring, 'x'))


def bound_check(bound_list, line, reverse):
    found_flag = False
    for bounds in bound_list:
        if bounds:
            if contains_all_without_overlap(line, list(bounds)):
                found_flag = True
                break
            else:
                continue
    if reverse == 0:
        return found_flag
    else:
        return not found_flag


def gr_check(filepath):
    excelRoot = {}
    with open(filepath, 'r') as csvfile:
        reader = csv.DictReader(csvfile)
        for row in reader:
            if row['Testbench List'].strip() != '':
                if row['TIER'].strip() == '1':
                    excelRoot[row['Testbench List'].strip()] = [row['TIER'].strip(), row['Process'].strip(), row['Temp'].strip(), row['res'].strip(), row['vdd/vdd2val/vddnom/vddval'].strip(), row['swing'].strip()]
                else:
                    excelRoot[row['Testbench List'].strip()] = [row['TIER'].strip(), 'na', 'na', 'na', 'na', 'na']
    return excelRoot


def setup_scratch(filepath):
    columns = pd.read_excel(filepath).columns
    converters = {col: str for col in columns}  # Convert all fields to strings
    # converters = {col: str for col in (0, 13)}
    data_xls = pd.read_excel(filepath, converters=converters, index_col=None)
    data_xls.to_csv('{}.csv' .format(os.path.splitext(filepath)[0]), encoding='utf-8', index=False)
    #
    # with xlrd.open_workbook('lpddr54_common_gr_tier_definition.xlsx') as wb:
    #     sh = wb.sheet_by_index(0)  # or wb.sheet_by_name('name_of_the_sheet_here')
    #     with open('common_gr_tier_definition.csv', 'w+') as f:
    #         c = csv.writer(f)
    #         for r in range(sh.nrows):
    #             # c.writerow(sh.row_values(r))
    #             c.writerow([unicode(val).encode('utf8') for val in sh.row_values(r)])
    print('CSV Generated.')


def usage():
    print(Fore.RED + 'Usage: {} -f <excel file>'.format(sys.argv[0]))
    print(Fore.RED + ' -f  = <path to excel file with tier and bound corner definition>')
    print('Examples:')
    print(Fore.GREEN + '{} -f config.xlsx'.format(sys.argv[0]))


try:
    opts, args = getopt.getopt(sys.argv[1:], 'f:h', ['file=', 'help'])
except getopt.GetoptError:
    usage()
    sys.exit(2)

# print("opts: {}, args: {}" .format(opts, args))

if opts:
    for opt, arg in opts:
        if opt in ('-h', '--help'):
            usage()
            sys.exit(2)
        elif opt in ('-f', '--file'):
            if os.path.isfile(arg):
                filepath = arg
                run = setup_scratch(filepath)
            else:
                print(Fore.YELLOW + 'Invalid Excel File option. Exiting ...\n\n')
                usage()
                sys.exit(2)
        else:
            usage()
            sys.exit(2)
else:
    usage()
    sys.exit(2)

try:
    filepath
except NameError:
    print(Fore.YELLOW + 'Filepath not defined. Exiting ...\n\n')
    usage()
    sys.exit(2)


def main():    # noqa C901
    gr_root = gr_check('{}.csv' .format(os.path.splitext(filepath)[0]))

    count_update = 0
    count_unchanged = 0
    count_missing = 0

    for key in gr_root:
        # print(key, gr_root[key])
        filename = os.getcwd() + '/bbSim/' + key
        if os.path.isfile(filename):
            skip_flag = 0
            original_bbSim = []
            with open(filename, 'r') as infile:
                for line in infile:
                    commands = line.split()
                    if commands and commands[0] == 'TIER':
                        print(Fore.LIGHTBLUE_EX + 'File not updated. Tier already defined in file: {}'.format(filename))
                        skip_flag = 1
                        count_unchanged += 1
                    original_bbSim.append(line)
            with open(filename, 'w') as outfile:
                for line in original_bbSim:
                    commands = line.split()
                    if commands:
                        if commands[0] == 'TESTBENCH':
                            outfile.write(line)
                            if gr_root[key][0] != '' and skip_flag == 0:
                                outfile.write('\nTIER\t\t\t{}\n' .format(gr_root[key][0]))
                                print(Fore.LIGHTGREEN_EX + 'TIER {} added to file: {}'.format(gr_root[key][0], key))
                                count_update += 1
                            elif gr_root[key][0] == '' and skip_flag == 0:
                                print(Fore.LIGHTMAGENTA_EX + 'File not updated. No Tier defined in Excel Sheet for file: {}'.format(key))
                                count_unchanged += 1
                        else:
                            outfile.write(line)
                    else:
                        outfile.write(line)

        else:
            print(Fore.LIGHTRED_EX + 'File does not exist. Skipping for: {}' .format(filename))
            count_missing += 1

    print('\n\nTier Definition added to .bbSim Files:')
    print(Fore.LIGHTGREEN_EX + 'Files updated:     {}' .format(count_update))
    print(Fore.LIGHTMAGENTA_EX + 'Files unchanged:   {}' .format(count_unchanged))

    print('\n\nStarting bound/full update.\n')

    for key in sorted(gr_root.keys()):    # noqa C901
        # print(key, gr_root[key])
        filename = os.getcwd() + '/bbSim/' + key
        # print(filename)
        if os.path.isfile(filename) and gr_root[key][0] == '1':
            print('Exists : {}' .format(key))
            bounds = bound_list(gr_root[key])
            # print(bounds)
            if bounds[0]:
                # print('not empty')
                reverse = 0
            else:
                # print('empty')
                reverse = 1
            with open(filename, 'r') as infile:
                for line in infile:
                    commands = line.split()
                    if commands:
                        if commands[0] == 'SPICE_COMMAND_FILE':
                            spice = os.path.basename(commands[1])
                            spice_path = os.path.dirname(os.path.dirname(filename)) + '/circuit/' + spice
                            if os.path.isfile(spice_path):
                                print(Fore.LIGHTMAGENTA_EX + 'Spice File exists: {}'.format(spice_path.replace(os.getcwd(), '')))
                            else:
                                print('Spice File missing: {}'.format(spice_path))
                        elif commands[0] == 'CORNERS_LIST_FILE':
                            corner = os.path.basename(commands[1])
                            corner_path = os.path.dirname(os.path.dirname(filename)) + '/corners/' + corner
                            if os.path.isfile(corner_path):
                                print(Fore.LIGHTMAGENTA_EX + 'Corner File exists: {}'.format(corner_path.replace(os.getcwd(), '')))
                            else:
                                print(Fore.LIGHTMAGENTA_EX + 'Corner File missing: {}'.format(corner_path))

            if os.path.isfile(spice_path) and os.path.isfile(corner_path):
                print(Fore.LIGHTGREEN_EX + '.sp and .corner file found. Updating bound condition.')

                original_sp = []
                sp_skip_flag = 0
                with open(spice_path, 'r') as infile:
                    for line in infile:
                        if line.lower().startswith('.param bound_condition = bound'):
                            sp_skip_flag = 1
                        original_sp.append(line)
                with open(spice_path, 'w') as outfile:
                    for line in original_sp:
                        if line.lower().startswith('.end') and not line.lower().startswith('.endif') and sp_skip_flag == 0:
                            outfile.write('\n.param bound_condition = bound\n\n')
                            outfile.write(line)
                        else:
                            outfile.write(line)
                print(Fore.LIGHTBLUE_EX + 'Updated spice file with bound_condition parameter.')

                original_corner = []
                param_added = 0
                corner_skip_flag = 0
                with open(corner_path, 'r') as infile:
                    for line in infile:
                        if ' param ' in line.lower():
                            comm = line.split()
                            if line.lower().startswith('{} param bound_condition' .format(comm[0])):
                                corner_skip_flag = 1
                        original_corner.append(line)
                bound_count = 0
                full_count = 0
                with open(corner_path, 'w') as outfile:
                    for line in original_corner:
                        if 'corner' in line.lower():
                            if not line.startswith('*') and not line.startswith('#'):
                                if param_added == 0:
                                    if corner_skip_flag == 0:
                                        comm = line.split()
                                        outfile.write('\n{} PARAM bound_condition\n\n' .format(comm[0]))
                                        param_added = 1

                                        line_check = line.lower()

                                        if bound_check(bounds, line_check, reverse):
                                            if ' full' in line:
                                                outfile.write(line.strip().replace(' full', ' bound\n'))
                                                bound_count += 1
                                            elif ' bound' in line:
                                                outfile.write(line)
                                                bound_count += 1
                                            else:
                                                outfile.write(line.strip() + '   bound\n')
                                                bound_count += 1
                                        else:
                                            if ' bound' in line:
                                                outfile.write(line.strip().replace(' bound', ' full\n'))
                                                full_count += 1
                                            elif ' full' in line:
                                                outfile.write(line)
                                                full_count += 1
                                            else:
                                                outfile.write(line.strip() + '   full\n')
                                                full_count += 1
                                    else:
                                        param_added = 1
                                        line_check = line.lower()

                                        if bound_check(bounds, line_check, reverse):
                                            if ' full' in line:
                                                outfile.write(line.strip().replace(' full', ' bound\n'))
                                                bound_count += 1
                                            elif ' bound' in line:
                                                outfile.write(line)
                                                bound_count += 1
                                            else:
                                                outfile.write(line.strip() + '   bound\n')
                                                bound_count += 1
                                        else:
                                            if ' bound' in line:
                                                outfile.write(line.strip().replace(' bound', ' full\n'))
                                                full_count += 1
                                            elif ' full' in line:
                                                outfile.write(line)
                                                full_count += 1
                                            else:
                                                outfile.write(line.strip() + '   full\n')
                                                full_count += 1
                                else:
                                    line_check = line.lower()

                                    if bound_check(bounds, line_check, reverse):
                                        if ' full' in line:
                                            outfile.write(line.strip().replace(' full', ' bound\n'))
                                            bound_count += 1
                                        elif ' bound' in line:
                                            outfile.write(line)
                                            bound_count += 1
                                        else:
                                            outfile.write(line.strip() + '   bound\n')
                                            bound_count += 1
                                    else:
                                        if ' bound' in line:
                                            outfile.write(line.strip().replace(' bound', ' full\n'))
                                            full_count += 1
                                        elif ' full' in line:
                                            outfile.write(line)
                                            full_count += 1
                                        else:
                                            outfile.write(line.strip() + '   full\n')
                                            full_count += 1
                            else:
                                outfile.write(line)

                        else:
                            outfile.write(line)
                print(Fore.LIGHTYELLOW_EX + 'Updated corner file with bound_condition parameter.\nCorners marked "bound": {}\nCorners marked "full": {}\n' .format(bound_count, full_count))
            else:
                print(Fore.LIGHTRED_EX + 'Skipping File: {}' .format(key))
        else:
            count_missing += 1

    print('Run Complete.')
