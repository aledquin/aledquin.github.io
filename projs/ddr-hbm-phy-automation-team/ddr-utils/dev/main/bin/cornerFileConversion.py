#!/depot/Python/Python-3.8.0/bin/python
#####################################
# Revision History
#
# 10/06/2021 by angiez:
#  1) converted from scientific notation to numbers (i.e.3.6g to 3600000000) in the hashtable so that it is in the same format with that of the corner file
#  2) updated col_count in when encountering 'param' in the corner files
#  3) added in-line comments to the code
#
#####################################
# nolint main
import os
import shutil
import sys
from datetime import datetime
from pathlib import Path


BIN_DIR = str(Path(__file__).resolve().parent)
# Add path to sharedlib's Python Utilities directory.
sys.path.append(BIN_DIR + "/../lib/python/Util")

import Misc


Misc.utils__script_usage_statistics("cornerFileConversion", "2022ww12")

hash_table = {}
now = datetime.now()
dt_str = now.strftime("%d_%m_%Y_%H:%M:%S")
log_file = open('run.log' + dt_str, 'w')


def is_number(s):
    try:
        float(s)
        return True
    except ValueError:
        return False

# read the config_param file


def config_read(config_param):

    with open(config_param) as f:

        for line in f:
            # block titles for hash table keys
            if line.startswith('### ['):
                x = line.split(",")
                for i, word in enumerate(x):
                    # collect all of the titles
                    x[i] = word.split("[")[1].split("]")[0].lower()
                    hash_table[x[i]] = {}
                continue
            elif len(line.split()) == 0 or line.startswith('#') or line.startswith('proj_dir_noise'):
                continue
            w = line.split()
            # fill up the values for the hash table
            if is_number(w[1]):
                for i, word in enumerate(x):
                    # convert data type to float
                    hash_table[x[i]][float(w[1])] = w[0]

            else:
                # converting from letter to number for datarate
                if w[1].lower().endswith("meg"):
                    w[1] = float((w[1].lower()).replace("meg", "")) * 1e6
                elif w[1].lower().endswith("g"):
                    w[1] = float((w[1].lower()).replace("g", "")) * 1e9
                for i, word in enumerate(x):
                    hash_table[x[i]][w[1]] = w[0]

        f.close()

# read the corner files


def corners_read(corners_file):  # noqa: C901
    word_arr = []
    l_count = 0
    l2_count = 0
    col_count = 0
    # the output file
    file2 = open((corners_file + '_refs'), 'w')
    with open(corners_file) as f:
        for line in f:

            l2_count = l2_count + 1
            if not line.startswith('t'):
                continue
            # if the line starts with the technology name
            else:
                l_count = l_count + 1
                word_arr = line.split()

                for i, words in enumerate(word_arr):
                    word_arr[i] = words.replace("'", "")
                # replace tech name with 'tech'
                if word_arr[0] in hash_table['tech']:
                    word_arr[0] = hash_table['tech'][word_arr[0]]
                else:  # if the technology name isn't on config file
                    print('WARNING: ' + word_arr[0] + ' on line ' + str(l2_count) + ' of ' + corners_file + ' does not exist in the ' + config_file + '\n')
                    log_file.write('WARNING: ' + word_arr[0] + ' on line ' + str(l2_count) + ' of ' + corners_file + ' does not exist in the ' + config_file + '\n')
                # different categories based on what the word after the tech name is, update col_count
                if word_arr[1] == 'LIB':

                    for values in hash_table['lib']:

                        if values.split('/')[-1] == word_arr[2].split('/')[-2]:
                            index = word_arr[2].find(word_arr[2].split('/')[-2])
                            word_arr[2] = word_arr[2][index:]
                            word_arr[2] = word_arr[2].replace(word_arr[2].split('/')[-2], hash_table['lib'][values])
                    col_count = l_count

                elif word_arr[1] == 'TEMP':
                    hash_table['temp']['column'] = l_count
                    col_count = l_count

                elif word_arr[1] == 'MONTE':
                    col_count = l_count

                elif word_arr[1] == 'PARAM':
                    # added the line below to update col_count
                    col_count = l_count
                    if "aging" in corners_file and (word_arr[2] + "_aging").lower() in hash_table:
                        hash_table[(word_arr[2] + "_aging").lower()]['column'] = l_count
                    elif word_arr[2].lower() in hash_table:
                        hash_table[word_arr[2].lower()]['column'] = l_count
                        col_count = l_count
                    else:
                        col_count = l_count
                        print('WARNING: Parameter ' + word_arr[2] + ' on line ' + str(l2_count) + ' of ' + corners_file + ' does not exist in the ' + config_file + '\n')
                        print('  \u2022WARNING: There is no section  ###[' + word_arr[2].upper() + ']### in the config file\n')
                        log_file.write('WARNING: Parameter ' + word_arr[2] + ' on line ' + str(l2_count) + ' of ' + corners_file + ' does not exist in the ' + config_file + '\n')
                        log_file.write('  \u2022WARNING: There is no section  ###[' + word_arr[2].upper() + ']### in the config file\n')

                elif word_arr[1] == 'CORNER':
                    if len(word_arr) < (col_count + 2):

                        print('ERROR: Skipping line ' + str(l2_count) + ' in ' + f.name + ' as there are less columns than expected\n')
                        log_file.write('ERROR: Skipping line ' + str(l2_count) + ' in ' + f.name + ' as there are less columns than expected\n')
                        continue
                    elif len(word_arr) > (col_count + 2):

                        print('ERROR: Skipping line ' + str(l2_count) + ' in ' + f.name + ' as there are more columns than expected\n')
                        log_file.write('ERROR: Skipping line ' + str(l2_count) + ' in ' + f.name + ' as there are more columns than expected\n')
                        continue
                    for keys in hash_table:

                        if 'column' in hash_table[keys]:
                            index = hash_table[keys]['column'] + 1
                            if not (index >= 0 and index < len(word_arr)):
                                print('WARNING: Cannot find ' + keys + ' in line ' + str(l2_count) + ' in ' + f.name + '\n')
                                log_file.write('WARNING: Cannot find ' + keys + ' in line ' + str(l2_count) + ' in ' + f.name + '\n')
                                continue
                            orig = word_arr[index]
                            # converting datarate from letter notation to number
                            if (word_arr[index].lower()).endswith("meg"):
                                word_arr[index] = float((word_arr[index].lower()).replace("meg", "")) * 1e6
                                word_arr[index] = str(word_arr[index])
                            elif (word_arr[index].lower()).endswith("g"):
                                word_arr[index] = float((word_arr[index].lower()).replace("g", "")) * 1e9
                                word_arr[index] = str(word_arr[index])
                            # converting numbers in the last few columns with names
                            if is_number(word_arr[hash_table[keys]['column'] + 1]):
                                data = word_arr[hash_table[keys]['column'] + 1]
                                if float(data) in hash_table[keys]:
                                    word_arr[hash_table[keys]['column'] + 1] = hash_table[keys][float(word_arr[hash_table[keys]['column'] + 1])]
                                else:
                                    word_arr[index] = orig
                                    log_file.write('WARNING: The following ' + keys + ': ' + str(word_arr[hash_table[keys]['column'] + 1]) + ' was not found in the ' + keys + ' section of ' + config_file + ' line number ' + str(l2_count) + ' in ' + f.name + '\n')
                                    print('WARNING: The following ' + keys + ': ' + str(word_arr[hash_table[keys]['column'] + 1]) + ' was not found in the ' + keys + ' section of ' + config_file + ' line number ' + str(l2_count) + ' in ' + f.name + '\n')
                            else:

                                if (word_arr[hash_table[keys]['column'] + 1]) in hash_table[keys]:
                                    word_arr[hash_table[keys]['column'] + 1] = hash_table[keys][(word_arr[hash_table[keys]['column'] + 1])]
                                else:
                                    word_arr[index] = orig
                                    log_file.write('WARNING: The following ' + keys + ': ' + str(word_arr[hash_table[keys]['column'] + 1]) + ' was not found in the ' + keys + ' section of ' + config_file + ' line number ' + str(l2_count) + ' in ' + f.name + '\n')
                                    print('WARNING: The following ' + keys + ': ' + str(word_arr[hash_table[keys]['column'] + 1]) + ' was not found in the ' + keys + ' section of ' + config_file + ' line number ' + str(l2_count) + ' in ' + f.name + '\n')

                # form the line and write to the output file
                x = ' '.join(word_arr)
                file2.write(x)
                file2.write('\n')
    file2.close()
    cwd = os.getcwd()
    output_name = file2.name[:-5]
    src = cwd + '/' + file2.name
    dest = directory + '/' + output_name
    dest2 = directory + '/' + output_name + '.bk.' + dt_str
    # finished writing
    if os.path.exists(directory + '/' + output_name):
        print('INFO: The following file ' + dest + " was backed up as " + dest2 + '\n')
        log_file.write('INFO: The following file ' + dest + " was backed up as " + dest2 + '\n')
        shutil.move(dest, dest2)

    shutil.move(src, dest)
    print('INFO: Input corner file: ' + corners_file + ' , converted output corner file: ../corners_ref/' + output_name + '\n')
    log_file.write('INFO: Input corner file: ' + corners_file + ' , converted output corner file: ../corners_ref/' + output_name + '\n')


cwd = os.getcwd()
# if input is in wrong format
if len(sys.argv) < 2:  # noqa: C901
    print('USAGE: \n')
    print('\u2022cornerConversion.py -config <config file> \n   \u2022This will run on all the *.corners existing in the current directory \n')
    print('\u2022cornerConversion.py -cornerFile <corner files comma separated>  -config <config file> \n   \u2022Example: CornerConversion.py -cornerFile txrx_jitter.corners,rx.corners,por.corners -config config_param')

# run all corner files
elif sys.argv[1] == '-config' and len(sys.argv) == 3:
    config_file = sys.argv[2]

    directory = '../corners_ref'

    if not os.path.exists(directory):
        os.mkdir(directory)
    for files in os.listdir():
        if files.endswith('.corners'):
            config_read(config_file)
            corners_read(files)
    print('Please check the log file for any errors or warnings: ' + log_file.name + cwd)

# run selected corner file
elif sys.argv[1] == '-cornerFile':
    config_file = sys.argv[-1]
    directory = '../corners_ref'

    if not os.path.exists(directory):
        os.mkdir(directory)
    list_array = []
    for a in sys.argv[2:-2]:
        for part in a.split(","):
            if part.strip():
                list_array.append(part.strip())
    for files in list_array:
        if files.endswith('.corners'):
            config_read(config_file)
            corners_read(files)
    print('Please check the log file for any errors or warnings: ' + log_file.name + cwd)

elif sys.argv[1] == '-config' and sys.argv[3] == 'cornerFile':
    config_file = sys.argv[2]
    directory = '../corners_ref'

    if not os.path.exists(directory):
        os.mkdir(directory)
    list_array = []
    for a in sys.argv[4:]:
        for part in a.split(","):
            if part.strip():
                list_array.append(part.strip())

    for files in list_array:
        if files.endswith('.corners'):
            config_read(config_file)
            corners_read(files)
    print('Please check the log file for any errors or warnings: ' + log_file.name + cwd)
# if the input is cornerConversion.py -h (or -help)
elif sys.argv[1] == '-help' or sys.argv[1] == '-h':
    print('USAGE: \n')
    print('\u2022cornerConversion.py -config <config file> \n   \u2022This will run on all the *.corners existing in the current directory \n')
    print('\u2022cornerConversion.py -cornerFile <corner files comma separated>  -config <config file> \n   \u2022Example: CornerConversion.py -cornerFile txrx_jitter.corners,rx.corners,por.corners -config config_param')

else:
    print('USAGE: \n')
    print('\u2022cornerConversion.py -config <config file> \n   \u2022This will run on all the *.corners existing in the current directory \n')
    print('\u2022cornerConversion.py -cornerFile <corner files comma separated>  -config <config file> \n   \u2022Example: CornerConversion.py -cornerFile txrx_jitter.corners,rx.corners,por.corners -config config_param')


log_file.close()
