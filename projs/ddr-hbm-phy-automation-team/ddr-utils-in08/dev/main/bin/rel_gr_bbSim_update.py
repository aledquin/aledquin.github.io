#!/depot/Python/Python-3.8.0/bin/python -E
# Tier Definition update script

import subprocess
import os
import re
import sys
import xlrd
import csv
import getpass
import getopt
from colorama import init, Fore, Back
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
GCFG['GR_XLSX'] = 'https://sp-sg/sites/msip-eddr/proj/eddra/ckt/Shared%20Documents/Golden%20Reference%20All%20Hard%20Macro%20Families/GR_official/official_golden_reference_list.xlsx'
GCFG['username'] = getpass.getuser()
# GCFG['HMA'] = '//wwcad/msip/projects/alpha/y006-alpha-sddrphy-ss14lpp-18/rel_gr_hma'
# GCFG['HMD'] = '//wwcad/msip/projects/ddr43/d523-ddr43-ss10lpp18/rel_gr_hmd'
# GCFG['HME'] = '//wwcad/msip/projects/lpddr4xm/d551-lpddr4xm-tsmc16ffc18/rel_gr_hme'
# GCFG['DDR45LITE'] = '//wwcad/msip/projects/ddr54/d589-ddr45-lite-tsmc7ff18/rel_gr_ddr45lite'
# GCFG['LPDDR54'] = '//wwcad/msip/projects/lpddr54/d859-lpddr54-tsmc7ff18/rel_gr_lpddr54'
# GCFG['DDR54'] = '//wwcad/msip/projects/ddr54/d809-ddr54-tsmc7ff18/rel_gr_ddr54'

GCFG['HMA'] = '//wwcad/msip/projects/alpha/y006-alpha-sddrphy-ss14lpp-18/latest_gr_hma'
GCFG['HMD'] = '//wwcad/msip/projects/ddr43/d523-ddr43-ss10lpp18/latest_gr_hmd'
GCFG['HME'] = '//wwcad/msip/projects/lpddr4xm/d551-lpddr4xm-tsmc16ffc18/latest_gr_hme'
GCFG['DDR45LITE'] = '//wwcad/msip/projects/ddr54/d589-ddr45-lite-tsmc7ff18/latest_gr_ddr45lite'
GCFG['LPDDR54'] = '//wwcad/msip/projects/lpddr54/d859-lpddr54-tsmc7ff18/latest_gr_lpddr54'
GCFG['DDR54'] = '//wwcad/msip/projects/ddr54/d809-ddr54-tsmc7ff18/latest_gr_ddr54'


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


def gr_check(own, hmf):
    excelRoot = {}
    hmf_Root = {}
    with open('official_golden_reference_list.csv', 'r') as csvfile:
        reader = csv.DictReader(csvfile)
        for row in reader:
            # excelRoot[bbSim File, macro name] = [ category (0), ownership (1), HMA (2), HMD (3), HME (4), DDR45LITE (5), LPDDR54 (6), DDR54 (7), Tier Definition (8)]
            if row['postfix'].strip() == 'na' and row['postfix'].strip() != '':
                excelRoot[row['[GR file root name]'].strip() + '.bbSim', row['[GR Macro name]'].strip()] = [row['category'].strip(), row['ownership'].strip(), row['HMA CRR '].strip(), row['HMD CRR'].strip(), row['HME CRR'].strip(), row['DDR45LITE CRR'].strip(), row['LPDDR54 CRR'].strip(), row['DDR54 CRR'].strip(), row['Tier Definition'].strip()]
            elif row['postfix'].strip() == 'pre' and row['postfix'].strip() != '':
                excelRoot[row['[GR file root name]'].strip() + '_pre.bbSim', row['[GR Macro name]'].strip()] = [row['category'].strip(), row['ownership'].strip(), row['HMA CRR '].strip(), row['HMD CRR'].strip(), row['HME CRR'].strip(), row['DDR45LITE CRR'].strip(), row['LPDDR54 CRR'].strip(), row['DDR54 CRR'].strip(), row['Tier Definition'].strip()]
            elif row['postfix'].strip() == 'post' and row['postfix'].strip() != '':
                excelRoot[row['[GR file root name]'].strip() + '_post.bbSim', row['[GR Macro name]'].strip()] = [row['category'].strip(), row['ownership'].strip(), row['HMA CRR '].strip(), row['HMD CRR'].strip(), row['HME CRR'].strip(), row['DDR45LITE CRR'].strip(), row['LPDDR54 CRR'].strip(), row['DDR54 CRR'].strip(), row['Tier Definition'].strip()]
            elif row['postfix'].strip() == 'both' and row['postfix'].strip() != '':
                excelRoot[row['[GR file root name]'].strip() + '_pre.bbSim', row['[GR Macro name]'].strip()] = [row['category'].strip(), row['ownership'].strip(), row['HMA CRR '].strip(), row['HMD CRR'].strip(), row['HME CRR'].strip(), row['DDR45LITE CRR'].strip(), row['LPDDR54 CRR'].strip(), row['DDR54 CRR'].strip(), row['Tier Definition'].strip()]
                excelRoot[row['[GR file root name]'].strip() + '_post.bbSim', row['[GR Macro name]'].strip()] = [row['category'].strip(), row['ownership'].strip(), row['HMA CRR '].strip(), row['HMD CRR'].strip(), row['HME CRR'].strip(), row['DDR45LITE CRR'].strip(), row['LPDDR54 CRR'].strip(), row['DDR54 CRR'].strip(), row['Tier Definition'].strip()]

    GR = {'HMA': 2, 'HMD': 3, 'HME': 4, 'DDR45LITE': 5, 'LPDDR54': 6, 'DDR54': 7}
    hmf_gr = {'gr_hma': 'HMA', 'gr_hmd': 'HMD', 'gr_hme': 'HME', 'gr_ddr45lite': 'DDR45LITE', 'gr_lpddr54': 'LPDDR54', 'gr_ddr54': 'DDR54'}
    tier_key = {'1.0': '1', '2.0': '2', '3.0': 3, 'DFM': 'DFM', '': ''}
    for bbSimFile in excelRoot:
        if excelRoot[bbSimFile][GR[hmf]] != '' and excelRoot[bbSimFile][GR[hmf]] != 'na':
            if own == 'ALL':
                hmf_Root[bbSimFile] = [hmf_gr[excelRoot[bbSimFile][GR[hmf]]], tier_key[excelRoot[bbSimFile][8]], excelRoot[bbSimFile][1]]
            else:
                if excelRoot[bbSimFile][1] == own:
                    hmf_Root[bbSimFile] = [hmf_gr[excelRoot[bbSimFile][GR[hmf]]], tier_key[excelRoot[bbSimFile][8]], excelRoot[bbSimFile][1]]
    return hmf_Root


def setup_scratch(username, password):
    try:
        code = subprocess.call('wget -O official_golden_reference_list.xlsx --user={} --password={} {}'.format(str(username), str(password), str(GCFG['GR_XLSX'])), shell=True, stdout=open(os.devnull, 'wb'), stderr=open(os.devnull, 'wb'))
    except ValueError:
        print(Fore.RED + "Sorry, I didn't understand that.")
    if code == 0:
        with xlrd.open_workbook('official_golden_reference_list.xlsx') as wb:
            sh = wb.sheet_by_index(0)  # or wb.sheet_by_name('name_of_the_sheet_here')
            with open('official_golden_reference_list.csv', 'w+') as f:
                c = csv.writer(f)
                for r in range(sh.nrows):
                    c.writerow(sh.row_values(r))
        print(Fore.GREEN + 'CSV Generated.')
        return 1
    else:
        print(Fore.RED + 'Login Failed. Check Password/Sharepoint Access.')
        return 0


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


def getFiles(path, local_gr):
    for path, subdirs, files in os.walk(path):
        for name in files:
            filename = os.path.join(path, name)
            if os.path.basename(filename).endswith('.bbSim'):
                local_gr.append(filename)
    return(local_gr)


def main():
    gr_root = gr_check(owner, hmf)

    local_gr = []
    actual_gr = []

    match = re.search("(.*/[a-z0-9-_.+]+/.*/design/sim/)", getlocalpath(GCFG[hmf]), re.IGNORECASE)
    if match:
        print(Fore.LIGHTBLUE_EX + 'Searching for files to modify in: {}' .format(match.group(1)))
        local_gr = getFiles(match.group(1), local_gr)
    else:
        print(Fore.LIGHTRED_EX + 'Cannot find local rel_gr area for {}\nExiting...' .format(GCFG[hmf]))
        sys.exit(2)

    count_update = 0
    count_unchanged = 0
    count_missing = 0

    for key in gr_root:
        # print(key, gr_root[key])
        filename = getlocalpath(GCFG[hmf] + '/design/sim/' + key[1] + '/bbSim/' + key[0])
        if os.path.isfile(filename):
            skip_flag = 0
            actual_gr.append(filename)
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
                    if commands and commands[0] == 'TESTBENCH':
                        outfile.write(line)
                        if gr_root[key][1] != '' and skip_flag == 0:
                            outfile.write('\nTIER\t\t\t{}\n' .format(gr_root[key][1]))
                            print(Fore.LIGHTGREEN_EX + 'TIER {} added to file: {}'.format(gr_root[key][1], filename))
                            count_update += 1
                        elif gr_root[key][1] == '' and skip_flag == 0:
                            print(Fore.LIGHTMAGENTA_EX + 'File not updated. No Tier defined in GR Excel Sheet for file: {}'.format(filename))
                            count_unchanged += 1
                    else:
                        outfile.write(line)

        else:
            print(Fore.LIGHTRED_EX + 'File does not exist. Skipping for: {}' .format(filename))
            count_missing += 1

    common_tb = set(local_gr).intersection(actual_gr)
    missing_gr = list(set(local_gr) - common_tb)

    print(Fore.CYAN + 'Following files are present in rel_gr area but are not mentioned in Official GR Excel Sheet:')
    print(Fore.LIGHTYELLOW_EX + '{}' .format(*missing_gr), sep="\n")

    print('Run Complete. Please check-in the updated files in P4.')
    print(Fore.LIGHTGREEN_EX + 'Files updated in rel_gr:\t\t\t{}' .format(count_update))
    print(Fore.LIGHTMAGENTA_EX + 'Files unchanged in rel_gr:\t\t\t{}' .format(count_unchanged))
    print(Fore.LIGHTRED_EX + 'Files in GR Excel Sheet but missing in rel_gr:\t{}' .format(count_missing))
    print(Fore.LIGHTYELLOW_EX + 'Files in rel_gr but missing in GR Excel Sheet:\t{}' .format(len(missing_gr)))


if __name__ == '__main__':
    main()
