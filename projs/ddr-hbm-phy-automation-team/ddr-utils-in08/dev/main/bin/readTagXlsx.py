#!/depot/Python/Python-3.8.0/bin/python -E
import os
import re
import pandas as pd
import sys
import getopt
import pathlib

# ----------------------------------#
bindir = str(pathlib.Path(__file__).resolve().parent)
sys.path.append(bindir + '/../lib/python/Util')
sys.path.append(bindir + '/../lib/python')
# ----------------------------------#
from Misc import utils__script_usage_statistics, get_release_version
__version__ = get_release_version(bindir)

utils__script_usage_statistics(__file__, __version__)


def usage():
    print('Usage: {} -f <excel file>'.format(sys.argv[0]))
    print(' -f  = <path to tag excel file >')
    print('Examples:')
    print('{} -f config.xlsx'.format(sys.argv[0]))


try:
    opts, args = getopt.getopt(sys.argv[1:], 'f:s:h', ['file=','sheetname=','help'])
except getopt.GetoptError:
    usage()
    sys.exit(2)

filepath = ""
sheetname = ""
if opts:
    for opt, arg in opts:
        if opt in ('-h', '--help'):
            usage()
            sys.exit(2)
        elif opt in ('-f', '--file'):
            if os.path.isfile(arg):
                filepath = arg
                # run = setup_scratch(filepath)
            else:
                print('Invalid Excel File option. Exiting ...\n\n')
                usage()
                sys.exit(2)
        elif opt in ('-s','--sheetname'):
            sheetname = arg
else:
    usage()
    sys.exit(2)

try:
    filepath
except NameError:
    print('Filepath not defined. Exiting ...\n\n')
    usage()
    sys.exit(2)


def main():
    xls = pd.ExcelFile(filepath)

    df = pd.read_excel(xls,sheetname,index_col=None,usecols=[0,1,2])
    df.columns = df.columns.str.lower()
    df.to_csv('tag.csv',encoding='utf-8',index=False)
    csv = open('tag.csv','r')
    copy = False
    lst = []
    for line in csv.readlines():
        if re.search(r'macro/cell name',line,re.IGNORECASE):
            copy = True
            lst.append(line)
        elif copy:
            lst.append(line)
    csv.close()
    csv = open('tag.csv','w')
    for line in lst:
        csv.write('{}\n'.format(line))

    csv.close()

    df = pd.read_csv('tag.csv',index_col=None,header=0)
    df.columns = df.columns.str.lower()

    df_nt = df[(df.flow == "NT") | (df.flow == "nt")]
    libs_nt = df_nt["lib name"].replace(r'\n','',regex=True).tolist()
    libs_nt = [x.encode('ascii').strip().decode('utf-8') for x in libs_nt]
    cells_nt = df_nt["macro/cell name"].replace(r'\n','',regex=True).tolist()
    cells_nt = [x.encode('ascii').strip().decode('utf-8') for x in cells_nt]
    libs_nt = ",".join(map(str,libs_nt))
    cells_nt = ",".join(map(str,cells_nt))
    print('NT {}|{}\n'.format(libs_nt,cells_nt))

    df_sis = df[(df.flow == "SiS") | (df.flow == "sis")]
    libs_sis = df_sis["lib name"].replace(r'\n','',regex=True).tolist()
    libs_sis = [x.encode('utf-8').strip().decode('utf-8') for x in libs_sis]
    cells_sis = df_sis["macro/cell name"].replace(r'\n','',regex=True).tolist()
    cells_sis = [x.encode('utf-8').strip().decode('utf-8') for x in cells_sis]
    libs_sis = ",".join(map(str,libs_sis))
    cells_sis = ",".join(map(str,cells_sis))
    print('SiS {}|{}'.format(libs_sis,cells_sis))


if __name__ == "__main__":
    main()
