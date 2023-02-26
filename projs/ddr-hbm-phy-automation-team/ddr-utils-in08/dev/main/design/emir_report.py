#!/depot/Python/Python-3.8.0/bin/python

__author__ = "Dikshant Rohatgi"
__tool_name__ = "emir_report.py"
__description__ = "Consolidated emir report script which provides violations across all ascii file in an xlsx format"
import os
import re
import glob
import pandas as pd
import getpass
import sys
import pathlib
import argparse
from typing import List
headr = ''

# ----------------------------------#
bindir = str(pathlib.Path(__file__).resolve().parent)
sys.path.append(bindir + '/../lib/python/Util')
sys.path.append(bindir + '/../lib/python')
# ----------------------------------#
import Misc
from CommonHeader import NONE
import Messaging


def _create_argparser() -> argparse.ArgumentParser:
    """Initialize an argument parser. Arguments are parsed in Misc.setup_script"""
    # Always include -v and -d arguments
    parser = argparse.ArgumentParser(description=__description__)
    parser.add_argument("-v", metavar="<#>", type=int, default=0, help="Verbosity")
    parser.add_argument("-d", metavar="<#>", type=int, default=0, help="Debug")
    parser.add_argument("--lcdl", metavar="<#>", type=int, default=0, help="lcdl option for running Emir\
                        report for lcdl")
    # Add your custom arguments here
    # -------------------------------------

    return parser


def runner(lcdl):
    try:
        tmideg_files = glob.glob("./*tmideg*")
        xa_devdt_files = glob.glob("./*devdt.xml*")
        iavg_files = ['xa-fr_vnet_she_iavg.ascii_', 'xa-@_she_iavg.ascii_', 'xa-vdd_she_iavg.ascii_', 'xa-vddq_she_iavg.ascii_', 'xa-vdd2h_she_iavg.ascii_', 'xa-vss_she_iavg.ascii_']
        irms_files = ['xa-fr_vnet_irms.ascii_', 'xa-@_irms.ascii_', 'xa-vdd_irms.ascii_', 'xa-vddq_irms.ascii_', 'xa-vdd2h_irms.ascii_', 'xa-vss_irms.ascii_']
        acpc_files = ['xa-fr_vnet_acpc.ascii_', 'xa-@_acpc.ascii_', 'xa-vdd_acpc.ascii_', 'xa-vddq_acpc.ascii_', 'xa-vdd2h_acpc.ascii_', 'xa-vss_acpc.ascii_']
        vmax_files = ['xa-vdd_vmax.ascii_', 'xa-vddq_vmax.ascii_', 'xa-vdd2h_vmax.ascii_', 'xa-vss_vmax.ascii_']

    except IOError:
        print("Error: Couldn't find current files in the directory, exiting")
        exit()
    block = os.getcwd().split('/')[-2]
    user = getpass.getuser()
    tb = os.getcwd().split('/')[-1]
    csv = 'emir_report.csv'
    txt_file = 'emir_violation.txt'
    fid1 = open(csv,'w')
    fid2 = open(txt_file,'w')
    fid1.write('BlOCK,{}, \nUSERNAME,{}, \nTESTBENCH,{}\n'.format(block,user,tb))

    corner_len = len(list(Misc.read_file("corners_list")))
    Messaging.iprint("Running emir report for {} corner ascii files".format(corner_len))

    [imax(x,fid1,fid2, corner_len) for x in iavg_files]

    [imax(x,fid1,fid2, corner_len) for x in irms_files]

    [imax(x,fid1,fid2,corner_len) for x in acpc_files]

    vMax(vmax_files,fid1,corner_len)

    maxDtmos(tmideg_files,fid1)
    if len(xa_devdt_files) == 1:
        maxDtmos_xml(xa_devdt_files,fid1)
    fid1.write('Report_dir,{}'.format(os.getcwd()))
    fid1.close()
    fid2.close()
    cmd = "sed -r -i 's/{}/\t/g' {}".format(r"\s{2,}",txt_file)
    (out1,status1,errval1) = Misc.run_system_cmd(cmd,NONE)

    df = pd.read_csv(csv,header=None,sep=',',skip_blank_lines=False,index_col=None)
    dft = pd.ExcelWriter('emir.xlsx')
    df = df.transpose()
    df.apply(lambda s:s.str.replace('"', ""))
    df.to_excel(dft,columns=None,index=False,header=False)
    dft.close()


def imax(file1,fi,fi2,corner_len):

    for i in range(0,corner_len):
        file11 = file1 + str(i)
        if os.path.isfile(file11) is False:
            fi.write('{},NA \n'.format(file11))
            return
        df = pd.read_csv(file11,delimiter=r'\s+',dtype='unicode',index_col=None,skiprows=range(1,6))

        df['I/Imax'] = df['I/Imax'].astype(float)
        idx = df['I/Imax'].idxmax()

        if re.search('iavg',file11) and re.search('she',file11) is None:
            fi.write('{},NA \n'.format(file11))
        else:
            fi.write('{},{}({})\n'.format(file11,df['I/Imax'].max(),df._get_value(idx,'Layer')))
        df_new = df[df['I/Imax'] >= 1]
        df_new = df_new.reset_index(drop=True)
        ascii_file = open(file11,'r')
        lines = ascii_file.readlines()
        if df_new.empty is False:

            fi2.write('{}\n{}{}\n\n'.format(file11,lines[0],lines[1]))
            df_new.to_csv(fi2,sep="\t",index=False,header=False)


def vMax(files,fi,corner_len):
    for file1 in files: 
        for i in range(0,corner_len):
            file11 = file1 + str(i)
            if os.path.isfile(file11) is False:
                fi.write('{},NA \n'.format(file11))
                continue
            vmax_list = ['me1_c','m1','m0','met_1','m0/via0','via0','metal1','metal2','m0/vd']
            df = pd.read_csv(file11,delimiter=r'\s+',dtype='unicode',index_col=None,skiprows=[i for i in range(1,4)])
            df = df[df['IRDrop(mV)'].isin(vmax_list)]
            df['name'] = df['name'].astype(float)
            idx = df['name'].idxmax()
            layer_name = df._get_value(idx,'IRDrop(mV)')
            fi.write('{},{}mV (at {})\n'.format(file11,df['name'].max(),layer_name))


def maxDtmos(files,fi):
    for file1 in files:
        if re.search('xml',file1):
            continue
        with open(file1,'r') as f:
            max_dtemp = 0
            inst_name = ''
            idtemp = 0
            for line in f:
                line = line.strip()
                if re.search('^Rank',line,re.IGNORECASE) or re.search(r'^\*',line,re.IGNORECASE) or line == '':
                    continue
                else:
                    idtemp = float(line.split()[2].strip())
                    if idtemp > max_dtemp:
                        max_dtemp = idtemp
                        inst_name = line.split()[1]
            fi.write('{},{} {}\n'.format(file1,max_dtemp,inst_name))


def maxDtmos_xml(files,fi):
    for file1 in files:
        df = pd.read_xml(file1)
        df['DeltaTemp'] = df['DeltaTemp'].astype(float)
        idx = df['DeltaTemp'].idxmax()
        layer_name = df._get_value(idx,'InstName')
        fi.write('{},{} (at {})\n'.format(file1,df['DeltaTemp'].max(),layer_name))


def main(cmdline_args: List[str] = None) -> None:
    argparser = _create_argparser()
    args = Misc.setup_script(argparser, __author__, __tool_name__, cmdline_args)

    runner(args.lcdl)


if __name__ == '__main__':
    main(sys.argv[1:])
