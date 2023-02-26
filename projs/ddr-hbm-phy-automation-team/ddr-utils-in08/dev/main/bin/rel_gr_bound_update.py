#!/depot/Python/Python-3.8.0/bin/python -E
# Bound corner update script for LP54
import subprocess
import os
import re
import sys
import csv
import getpass
import itertools
import getopt
from colorama import init, Fore, Back
import pandas as pd
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


GCFG = {}
hmf_options = ['HMA', 'HMD', 'HME', 'DDR45LITE', 'LPDDR54', 'DDR54']
ownership_options = ['DDL', 'DML', 'ESD', 'TX', 'RX', 'ALL']
GCFG['GR_XLSX'] = 'https://sp-sg/sites/msip-eddr/proj/eddra/ckt/Shared%20Documents/Golden%20Reference%20All%20Hard%20Macro%20Families/GR_official/lpddr54_common_gr_tier_definition.xlsx'
GCFG['username'] = getpass.getuser()
GCFG['HMA'] = '//wwcad/msip/projects/alpha/y006-alpha-sddrphy-ss14lpp-18/rel_gr_hma/design/sim/'
GCFG['HMD'] = '//wwcad/msip/projects/ddr43/d523-ddr43-ss10lpp18/rel_gr_hmd/design/sim/'
GCFG['HME'] = '//wwcad/msip/projects/lpddr4xm/d551-lpddr4xm-tsmc16ffc18/rel_gr_hme/design/sim/'
GCFG['DDR45LITE'] = '//wwcad/msip/projects/ddr54/d589-ddr45-lite-tsmc7ff18/rel_gr_ddr45lite/design/sim/'
GCFG['LPDDR54'] = '//wwcad/msip/projects/lpddr54/d859-lpddr54-tsmc7ff18/rel_gr_lpddr54/design/sim/'
# GCFG['LPDDR54'] = '//wwcad/msip/projects/lpddr54/d859-lpddr54-tsmc7ff18/latest_gr_lpddr54/design/sim/'
GCFG['DDR54'] = '//wwcad/msip/projects/ddr54/d809-ddr54-tsmc7ff18/rel_gr_ddr54/design/sim/'


def drange(start, stop, step):
    r = start
    while r < stop:
        yield r
        r += step

# i0=drange(0.0, 1.0, 0.1)


def getlocalpath(p4path):
    try:
        localPath = subprocess.check_output("p4 where {}...".format(p4path), shell=True).decode("utf-8", 'ignore').rstrip()
    except subprocess.CalledProcessError as exc:
        print(Fore.YELLOW + "Status : FAIL\n Return Code: {} Output: {}" .format(exc.returncode, exc.output))
        sys.exit(2)
    else:
        localPath = localPath.split()[-1]
        if '/...' in localPath:
            localPath = localPath.replace('/...', '/')
        elif '...' in localPath:
            localPath = localPath.replace('...', '')
        return localPath


def bound_list(tb_list):
    result_set = []
    for rows in tb_list[1:-1]:
        row = rows.lower()
        if row != 'na' and row != '':
            if 'm40' in row:
                result_set.append(row.replace('m40', '-40').split('/'))
            else:
                result_set.append(row.split('/'))
    typ_set = []
    if tb_list[-1] != 'na' and tb_list[-1] != '':
        row = tb_list[-1].lower()
        row_split = row.split('|')
        for keys in row_split:
            if 'm40' in keys:
                typ_set.append(keys.replace('m40', '-40').split('/'))
            else:
                typ_set.append(keys.split('/'))
    final_set = list(itertools.product(*result_set))
    final_set.extend(list(itertools.product(*typ_set)))

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


def bound_check(bound_list, line):
    found_flag = False
    for bounds in bound_list:
        if bounds:
            if contains_all_without_overlap(line, list(bounds)):
                found_flag = True
                break
            else:
                continue
    return found_flag


def gr_check(own, hmf):
    excelRoot = {}
    with open('common_gr_tier_definition.csv', 'r') as csvfile:
        reader = csv.DictReader(csvfile)
        for row in reader:
            if row['Testbench'].strip() != '':
                # print(row['Testbench'].strip())
                if row['Macro'].strip() != '':
                    # print(row['Macro'].strip())
                    # print(row['tier'].strip())
                    if row['tier'].strip() == '1' and row['Process'].strip() != '':
                        # print(row['tier'].strip())
                        if own != 'ALL':
                            if row['ownership'].strip() == own:
                                # print(row['ownership'].strip())
                                if '_pre' in row['Testbench'].strip() or '_post' in row['Testbench'].strip():
                                    excelRoot[row['Macro'].strip() + '/bbSim/' + row['Testbench'].strip() + '.bbSim'] = [row['corners'].strip(), row['Process'].strip(), row['Temp'].strip(), row['res'].strip(), row['vdd/vdd2val/vddnom/vddval'].strip(), row['eye_amp/vrefval/vrefdacref/vddq/vddqval'].strip(), row['vcenter/vdd2/vrefval/vcm/vdd2val/vaa_vdd2val/vcmval'].strip(), row['bitrate/zapv/freq'].strip(), row['D/dfe/seont/tstop/vddqval/dfeon'].strip(), row['slew/torc/tramp/kb_en'].strip(), row['lb_en/deltav'].strip(), row['Typical PVT'].strip()]
                                else:
                                    excelRoot[row['Macro'].strip() + '/bbSim/' + row['Testbench'].strip() + '.bbSim'] = [row['corners'].strip(), row['Process'].strip(), row['Temp'].strip(), row['res'].strip(), row['vdd/vdd2val/vddnom/vddval'].strip(), row['eye_amp/vrefval/vrefdacref/vddq/vddqval'].strip(), row['vcenter/vdd2/vrefval/vcm/vdd2val/vaa_vdd2val/vcmval'].strip(), row['bitrate/zapv/freq'].strip(), row['D/dfe/seont/tstop/vddqval/dfeon'].strip(), row['slew/torc/tramp/kb_en'].strip(), row['lb_en/deltav'].strip(), row['Typical PVT'].strip()]
                                    excelRoot[row['Macro'].strip() + '/bbSim/' + row['Testbench'].strip() + '_pre.bbSim'] = [row['corners'].strip(), row['Process'].strip(), row['Temp'].strip(), row['res'].strip(), row['vdd/vdd2val/vddnom/vddval'].strip(), row['eye_amp/vrefval/vrefdacref/vddq/vddqval'].strip(), row['vcenter/vdd2/vrefval/vcm/vdd2val/vaa_vdd2val/vcmval'].strip(), row['bitrate/zapv/freq'].strip(), row['D/dfe/seont/tstop/vddqval/dfeon'].strip(), row['slew/torc/tramp/kb_en'].strip(),
                                                                                                                             row['lb_en/deltav'].strip(), row['Typical PVT'].strip()]
                                    excelRoot[row['Macro'].strip() + '/bbSim/' + row['Testbench'].strip() + '_post.bbSim'] = [row['corners'].strip(), row['Process'].strip(), row['Temp'].strip(), row['res'].strip(), row['vdd/vdd2val/vddnom/vddval'].strip(), row['eye_amp/vrefval/vrefdacref/vddq/vddqval'].strip(), row['vcenter/vdd2/vrefval/vcm/vdd2val/vaa_vdd2val/vcmval'].strip(), row['bitrate/zapv/freq'].strip(), row['D/dfe/seont/tstop/vddqval/dfeon'].strip(), row['slew/torc/tramp/kb_en'].strip(),
                                                                                                                              row['lb_en/deltav'].strip(), row['Typical PVT'].strip()]

                        else:
                            if row['ownership'].strip() != '':
                                if '_pre' in row['Testbench'].strip() or '_post' in row['Testbench'].strip():
                                    excelRoot[row['Macro'].strip() + '/bbSim/' + row['Testbench'].strip() + '.bbSim'] = [row['corners'].strip(), row['Process'].strip(), row['Temp'].strip(), row['res'].strip(), row['vdd/vdd2val/vddnom/vddval'].strip(), row['eye_amp/vrefval/vrefdacref/vddq/vddqval'].strip(), row['vcenter/vdd2/vrefval/vcm/vdd2val/vaa_vdd2val/vcmval'].strip(), row['bitrate/zapv/freq'].strip(), row['D/dfe/seont/tstop/vddqval/dfeon'].strip(), row['slew/torc/tramp/kb_en'].strip(), row['lb_en/deltav'].strip(), row['Typical PVT'].strip()]
                                else:
                                    excelRoot[row['Macro'].strip() + '/bbSim/' + row['Testbench'].strip() + '.bbSim'] = [row['corners'].strip(), row['Process'].strip(), row['Temp'].strip(), row['res'].strip(), row['vdd/vdd2val/vddnom/vddval'].strip(), row['eye_amp/vrefval/vrefdacref/vddq/vddqval'].strip(), row['vcenter/vdd2/vrefval/vcm/vdd2val/vaa_vdd2val/vcmval'].strip(), row['bitrate/zapv/freq'].strip(), row['D/dfe/seont/tstop/vddqval/dfeon'].strip(), row['slew/torc/tramp/kb_en'].strip(), row['lb_en/deltav'].strip(), row['Typical PVT'].strip()]
                                    excelRoot[row['Macro'].strip() + '/bbSim/' + row['Testbench'].strip() + '_pre.bbSim'] = [row['corners'].strip(), row['Process'].strip(), row['Temp'].strip(), row['res'].strip(), row['vdd/vdd2val/vddnom/vddval'].strip(), row['eye_amp/vrefval/vrefdacref/vddq/vddqval'].strip(), row['vcenter/vdd2/vrefval/vcm/vdd2val/vaa_vdd2val/vcmval'].strip(), row['bitrate/zapv/freq'].strip(), row['D/dfe/seont/tstop/vddqval/dfeon'].strip(), row['slew/torc/tramp/kb_en'].strip(),
                                                                                                                             row['lb_en/deltav'].strip(), row['Typical PVT'].strip()]
                                    excelRoot[row['Macro'].strip() + '/bbSim/' + row['Testbench'].strip() + '_post.bbSim'] = [row['corners'].strip(), row['Process'].strip(), row['Temp'].strip(), row['res'].strip(), row['vdd/vdd2val/vddnom/vddval'].strip(), row['eye_amp/vrefval/vrefdacref/vddq/vddqval'].strip(), row['vcenter/vdd2/vrefval/vcm/vdd2val/vaa_vdd2val/vcmval'].strip(), row['bitrate/zapv/freq'].strip(), row['D/dfe/seont/tstop/vddqval/dfeon'].strip(), row['slew/torc/tramp/kb_en'].strip(),
                                                                                                                              row['lb_en/deltav'].strip(), row['Typical PVT'].strip()]

    return excelRoot


def setup_scratch(username, password):
    try:
        code = subprocess.call('wget -O lpddr54_common_gr_tier_definition.xlsx --user={} --password={} {}'.format(str(username), str(password), str(GCFG['GR_XLSX'])), shell=True, stdout=open(os.devnull, 'wb'), stderr=open(os.devnull, 'wb'))
    except ValueError:
        print(Fore.RED + "Sorry, I didn't understand that.")
    if code == 0:
        converters = {col: str for col in (0, 13)}
        data_xls = pd.read_excel('lpddr54_common_gr_tier_definition.xlsx', converters=converters, index_col=None)
        data_xls.to_csv('common_gr_tier_definition.csv', encoding='utf-8', index=False)
        #
        # with xlrd.open_workbook('lpddr54_common_gr_tier_definition.xlsx') as wb:
        #     sh = wb.sheet_by_index(0)  # or wb.sheet_by_name('name_of_the_sheet_here')
        #     with open('common_gr_tier_definition.csv', 'w+') as f:
        #         c = csv.writer(f)
        #         for r in range(sh.nrows):
        #             # c.writerow(sh.row_values(r))
        #             c.writerow([unicode(val).encode('utf8') for val in sh.row_values(r)])
        print('CSV Generated.')
        return 1
    else:
        print(Fore.RED + 'Login Failed. Check Password/Sharepoint Access.')
        return 0


def main():     # noqa C901
    gr_root = gr_check(owner, hmf)

    local_gr = []

    count_missing = 0

    match = re.search("(.*/[a-z0-9-_.+]+/.*/design/sim/)", getlocalpath(GCFG[hmf]), re.IGNORECASE)
    if match:
        print('Searching for files to modify in: {}' .format(match.group(1)))
        for path, subdirs, files in os.walk(match.group(1)):
            for name in files:
                filename = os.path.join(path, name)
                if os.path.basename(filename).endswith('.bbSim'):
                    local_gr.append(filename)
    else:
        print(Fore.LIGHTRED_EX + 'Cannot find local rel_gr area for {}\nExiting...' .format(GCFG[hmf]))
        sys.exit(2)

    # print(gr_root)

    for key in sorted(gr_root.keys()):
        # print(key, gr_root[key])
        filename = match.group(1) + key
        # print(filename)
        if os.path.isfile(filename):
            print('Exists : {}' .format(key))
            bounds = bound_list(gr_root[key])
            # for key in bounds:
            #     print(key)
            # actual_gr.append(filename)
            # original_bbSim = []
            with open(filename, 'r') as infile:
                for line in infile:
                    commands = line.split()
                    if commands:
                        if commands[0] == 'SPICE_COMMAND_FILE':
                            spice = os.path.basename(commands[1])
                            spice_path = os.path.dirname(os.path.dirname(filename)) + '/circuit/' + spice
                            if os.path.isfile(spice_path):
                                print('Spice File exists: {}'.format(spice_path.replace(match.group(1), '')))
                            else:
                                print('Spice File missing: {}'.format(spice_path))
                        elif commands[0] == 'CORNERS_LIST_FILE':
                            corner = os.path.basename(commands[1])
                            corner_path = os.path.dirname(os.path.dirname(filename)) + '/corners/' + corner
                            if os.path.isfile(corner_path):
                                print('Corner File exists: {}'.format(corner_path.replace(match.group(1), '')))
                            else:
                                print('Corner File missing: {}'.format(corner_path))

            if os.path.isfile(spice_path) and os.path.isfile(corner_path):
                print('.sp and .corner file found. Updating bound condition.')

                original_sp = []
                sp_skip_flag = 0
                with open(spice_path, 'r') as infile:
                    for line in infile:
                        if line.lower().startswith('.param bound_condition = bound'):
                            sp_skip_flag = 1
                        original_sp.append(line)
                with open(spice_path, 'w') as outfile:
                    for line in original_sp:
                        if line.lower().startswith('.end') and sp_skip_flag == 0:
                            outfile.write('\n.param bound_condition = bound\n\n')
                            outfile.write(line)
                        else:
                            outfile.write(line)
                print('Updated spice file with bound_condition parameter.')

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

                                        if bound_check(bounds, line_check):
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

                                        if bound_check(bounds, line_check):
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

                                    if bound_check(bounds, line_check):
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
                print('Updated corner file with bound_condition parameter.\nCorners marked "bound": {}\nCorners marked "full": {}\n' .format(bound_count, full_count))
            else:
                print('Skipping File: {}' .format(key))
        else:
            # print(Fore.LIGHTRED_EX + 'DNE : {}' .format(key))
            count_missing += 1
        # print(os.path.isfile(filename), filename)
        # print(GCFG[hmf] + '/design/sim/' + key[1] + '/bbSim/' + key[0], getlocalpath(GCFG[hmf] + '/design/sim/' + key[1] + '/bbSim/' + key[0]))

    #
    # common_tb = set(local_gr).intersection(actual_gr)
    # missing_gr = list(set(local_gr) - common_tb)
    #
    # count_extra = 0
    #
    # print(Fore.CYAN + 'Following files are present in rel_gr area but are not mentioned in Official GR Excel Sheet:')
    # for files in missing_gr:
    #     print(Fore.LIGHTYELLOW_EX + '{}' .format(files))
    #     count_extra += 1

    print('Run Complete. Please check-in the updated files in P4.')
    # print(Fore.LIGHTGREEN_EX + 'Files updated in rel_gr:\t\t\t{}' .format(count_update))
    # print(Fore.LIGHTMAGENTA_EX + 'Files unchanged in rel_gr:\t\t\t{}' .format(count_unchanged))
    # print(Fore.LIGHTRED_EX + 'Files in GR Excel Sheet but missing in rel_gr:\t{}' .format(count_missing))
    # print(Fore.LIGHTYELLOW_EX + 'Files in rel_gr but missing in GR Excel Sheet:\t{}' .format(count_extra))


def usage():
    print(Fore.RED + 'Usage: {} -f <family> -o <ownership_group>'.format(sys.argv[0]))
    print(Fore.RED + ' -f  = [HMA|HMD|HME|DDR45LITE|LPDDR54|DDR54]')
    print(Fore.RED + ' -o  = [DDL|DML|ESD|TX|RX|ALL]')
    print('Examples:')
    print(Fore.GREEN + '{} -f HMA -o DDL'.format(sys.argv[0]))
    print(Fore.GREEN + '{} -o ALL -f LPDDR54'.format(sys.argv[0]))


try:
    opts, args = getopt.getopt(sys.argv[1:], 'f:o:h', ['hmf=', 'ownership=', 'help'])
except getopt.GetoptError:
    usage()
    sys.exit(2)

# print("opts: {}, args: {}" .format(opts, args))

if opts:
    for opt, arg in opts:
        if opt in ('-h', '--help'):
            usage()
            sys.exit(2)
        elif opt in ('-o', '--ownership'):
            if arg.upper() in ownership_options:
                owner = arg.upper()
            else:
                print(Fore.YELLOW + 'Invalid Ownership Group option. Exiting ...\n\n')
                usage()
                sys.exit(2)
        elif opt in ('-f', '--hmf'):
            if arg.upper() in hmf_options:
                hmf = arg.upper()
            else:
                print(Fore.YELLOW + 'Invalid HMF option. Exiting ...\n\n')
                usage()
                sys.exit(2)
        else:
            usage()
            sys.exit(2)
else:
    usage()
    sys.exit(2)

try:
    hmf
except NameError:
    print(Fore.YELLOW + 'HMF not defined. Exiting ...\n\n')
    usage()
    sys.exit(2)

try:
    owner
except NameError:
    print(Fore.YELLOW + 'Ownership Group File not defined. Exiting ...\n\n')
    usage()
    sys.exit(2)


login_attempts = 4

while login_attempts > 0:
    login_attempts -= 1
    if login_attempts == 0:
        print(Back.LIGHTRED_EX + 'Terminating Script .... ')
        sys.exit()
    else:
        GCFG['password'] = getpass.getpass('Enter password for {}: '.format(GCFG['username']))
        run = setup_scratch(GCFG['username'], GCFG['password'])
        if run:
            break
        else:
            continue


if __name__ == '__main__':
    main()
