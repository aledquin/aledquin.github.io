#!/depot/Python/Python-3.8.0/bin/python -E

import os
import collections
import re
import sys
import getopt
import pathlib

# ---------------------------------- #
bindir = str(pathlib.Path(__file__).resolve().parent)
# Add path to library that may be symbolically linked.
sys.path.append(bindir + '/../lib/Util')
# Add path to sharedlib's Python Utilities directory.
sys.path.append(bindir + '/../lib/python/Util')
# ---------------------------------- #


from Misc import utils__script_usage_statistics, get_release_version
__version__ = get_release_version(bindir)
utils__script_usage_statistics(__file__, __version__)
global eFile,spFile


def percentage(part, whole):
    return round((100 * float(part) / float(whole)), 1)


def devLength(eFile,spFile):
    # with open('output.txt', 'w+') as file:
    #     file.write('Script Output\n\n\n')
    fo = open(eFile,'r')
    co = [x.strip() for x in fo.readlines()]
    regex = re.compile(r'^#.*')
    co = [i for i in co if not regex.match(i)]
    content = [x.split()[-1] for x in co]

    data = []
    device_list = []
    lib_list = collections.defaultdict(dict)
    transistor_count = collections.defaultdict(dict)
    device_count = collections.defaultdict(dict)
    with open(spFile, 'r') as f:
        copy = False
        (copy,data) = readData(f,copy,content,lib_list,data)
        subckt_check = False
        (subckt_check,device_count) = processData(data,transistor_count,device_count,device_list)
    return(device_count)


def readData(f,copy,content,lib_list,data):
    for line in f:
        line = line.strip()
        if line != '':
            if(re.match(r'^\* Library',line)):
                lib = ""
                lib = re.match(r'^\* Library|^\* Cell',line).string
                lib = re.split(r'\s+',lib)[-1].lower()
            elif(re.match(r'^\* Cell',line)):
                cell = ""
                cell = re.match(r'^\* Cell',line).string
                cell = re.split(r'\s+',cell)[-1].lower()
                lib_list[cell] = lib

            if line.lower().startswith('.subckt'):
                cell_name = re.search(r'\.subckt\s+(.+?)\s+.*',line).group(1)
                if cell_name in content or lib_list[cell_name] in content:
                    copy = False
                else:
                    copy = True
            elif line.lower().startswith('.ends'):
                data.append(line)
                copy = False
            data = dumpData(copy,data,line)

    return(copy,data)


def dumpData(copy,data,line):
    if copy:
        if line.lower().startswith('*'):
            return
        elif line.startswith('+'):
            data.append(data.pop() + line.replace('+', ''))
        else:
            data.append(line)
    return(data)


def processData(data,transistor_count,device_count,device_list):
    for line in data:
        if line.lower().startswith('.subckt'):
            subckt_check = True
            if not data[data.index(line) + 1].lower().startswith('.ends'):
                device_list.append(line.split()[1])
                continue
        elif line.lower().startswith('.ends'):
            subckt_check = False
            continue
        elif subckt_check:
            if any(x in line.split() for x in device_list):
                found_element = next(element for element in line.split() if element in device_list)
                for key in transistor_count[found_element].keys():
                    if key not in transistor_count[device_list[-1]].keys():
                        transistor_count[device_list[-1]][key] = transistor_count[found_element][key]
                    else:
                        transistor_count[device_list[-1]][key] += transistor_count[found_element][key]
            else:
                grepDevice(line,device_count)
    return(subckt_check,device_count)


def grepDevice(line,device_count):
    if '_mac ' in line and 'l=' in line and 'nfin=' in line:
        device = re.search("([a-z0-9-_.+]+_mac )", line, re.IGNORECASE).group(1).strip()
        le = re.search(r'.*\s+l=([a-z0-9-_.+]+).*', line, re.IGNORECASE).group(1)
        if device not in device_count.keys():
            device_count[device] = []
        device_count[device].append(le)
    elif '_mac ' in line and 'l=' in line and 'nfin=' in line:
        device = re.search("([a-z0-9-_.+]+_mac )", line, re.IGNORECASE).group(1).strip()
        le = re.search(r'.*\s+l=([a-z0-9-_.+]+).*', line, re.IGNORECASE).group(1)
        if device not in device_count.keys():
            device_count[device] = []
        device_count[device].append(le)
    elif 'nmoscap' in line and 'lr=' in line and 'nfin=' in line and 'multi=' in line:
        device = line.split()[3]
        lr = re.search(".*lr=([a-z0-9-_.+]+).*", line, re.IGNORECASE).group(1)
        if device not in device_count.keys():
            device_count[device] = []
        device_count[device].append(lr)
    return(device_count)


def argParse():
    argv = sys.argv[1:]
    try:
        opts, args = getopt.getopt(argv,"he:s:",["efile=","sfile="])
    except getopt.GetoptError:
        print('devicelen.py -e <exclude File> -s <sp file>')
        sys.exit(2)
    for opt, arg in opts:
        if opt == '-h':
            print('devicelen.py -e <exlcude file> -s <sp file>')
            sys.exit()
        elif opt in ("-s", "--sfile"):
            spFile = arg
        elif opt in ("-e", "--efile"):
            eFile = arg
    return(eFile,spFile)


def main():
    (eFile,spFile) = argParse()
    if not spFile:
        print('No *.sp* files found in')
        sys.exit()
    device_count = devLength(eFile,spFile)
    opFile = './devicelength/project_devicelen.txt'

    if os.path.isfile(opFile) is False:
        fid = open(opFile,'w+')
    else:
        fid = open(opFile,'a+')

    spFile = spFile.split('/')[-1]
    macro = re.search(r'(.*)\.sp',spFile).group(1)

    fid.write('# {}\n'.format(macro))
    for key in device_count.keys():
        res = []
        res = list(set(device_count[key]))
        if re.search(r'dio',key):
            continue
        fid.write('{0}'.format(key))
        for r in res:
            fid.write(',l={0}'.format(r))
        fid.write('\n')

    fid.write('\n')
    fid.close()


if __name__ == '__main__':
    main()
