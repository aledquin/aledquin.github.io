#!/depot/Python/Python-3.8.0/bin/python
"""
Name    : std_template.py
Author  : your name here
Date    : creation date here
Purpose : description of the script.. can put on multiple lines
Modification History
    000 YOURNAME  CURRENT_DATE
        Created this script
    001 YOURNAME DATE_OF_YOUR_CHANGES
        Description of what you have changed.
"""

__author__ = "dikshant"
__tool_name__ = "ddr-utils-in08"  # Ex: ddr-da-tpl

import argparse
import atexit
import os
import pathlib
import sys
import pandas as pd
import re
from shutil import copyfile

bindir = str(pathlib.Path(__file__).resolve().parent)
# Add path to library that may be symbolically linked.
sys.path.append(bindir + "/../lib/Util")
# Add path to sharedlib's Python Utilities directory.
sys.path.append(bindir + "/../lib/python/Util")


# Import common constants
from CommonHeader import NONE
# Import messaging functions
from Messaging import (
    iprint,
    eprint,
)

# Import other logging functions
import Messaging

# Import miscellaneous utilities
import Misc
import CommonHeader


def parse_args() -> argparse.Namespace:
    """Parse command-line arguments."""
    # Always include -v, and -d
    parser = argparse.ArgumentParser(description="description here")
    parser.add_argument("-v", metavar="<#>", type=int, default=0, help="verbosity")
    parser.add_argument("-d", metavar="<#>", type=int, default=0, help="debug")

    # Add your custom arguments here
    # -------------------------------------

    # -------------------------------------
    parser.add_argument("-f", "--file", metavar="<#>", type=str, default=0, help="debug")
    parser.add_argument("-m", "--macro", metavar="<#>", type=str, default=0, help="debug")
    parser.add_argument("-p", "--path", metavar="<#>", type=str, default=0, help="debug")

    args = parser.parse_args()
    return args


def getVolFileName(filename,vol):
    if re.search(r'.+_post_mc|pre_mc',filename):
        vol_filename = re.sub(r'(.+)_(post_mc|pre_mc)\.bbSim','\\1_{}_\\2.bbSim', filename,re.S).format(vol)
    elif re.search(r'.+_post.*',filename):
        vol_filename = re.sub(r'(.+)_(post.*)\.bbSim','\\1_{}_\\2.bbSim', filename,re.S).format(vol)
    elif re.search(r'.+_pre.*',filename):
        vol_filename = re.sub(r'(.+)_(pre.*)\.bbSim','\\1_{}_\\2.bbSim', filename,re.S).format(vol)
    elif re.search(r'.+_mc.*',filename):
        vol_filename = re.sub(r'(.+)_(mc.*)\.bbSim','\\1_{}_\\2.bbSim', filename,re.S).format(vol)
    else:
        vol_filename = re.sub(r'(.+)\.bbSim','\\1_{}.bbSim', filename).format(vol)
    return(vol_filename)


def updateVoltageFile(vol_filename,vol):
    ffid = open(vol_filename,'r')
    corner_content = ffid.readlines()

    for count,line in enumerate(corner_content):
        if line != '' and re.search(r'CORNERS_LIST_FILE\s+',line):
            if re.search(r'_post_mc|pre_mc',line):
                corner_content[count] = re.sub(r'(.+)_(post_mc|pre_mc)\.corners','\\1_{}_\\2.corners', corner_content[count]).format(vol)
            elif re.search(r'.+_post.*',line):
                corner_content[count] = re.sub(r'(.+)_(post.*)\.corners','\\1_{}_\\2.corners', corner_content[count]).format(vol)
            elif re.search(r'.+_pre.*',line):
                corner_content[count] = re.sub(r'(.+)_(pre.*)\.corners','\\1_{}_\\2.corners', corner_content[count]).format(vol)
            elif re.search(r'.+_mc.*',line):
                corner_content[count] = re.sub(r'(.+)_(mc.*)\.corners','\\1_{}_\\2.corners', corner_content[count]).format(vol)

            else:
                corner_content[count] = re.sub(r'(.+)\.corners','\\1_{}.corners', corner_content[count]).format(vol)

    ffid.close()
    ffid = open(vol_filename,'w')
    for ll in corner_content:
        ffid.write(ll)
    ffid.close()
    return


def updateData(filename, tb_name, vdd):
    if os.path.isfile(filename) is False:
        eprint("Couldn't find {}. Please check\n".format(filename))
        return
    fid = open(filename, 'r')
    content = fid.readlines()
    for vol in vdd:
        vol = re.sub(r'\.','p', vol)
        vol_filename = getVolFileName(filename,vol)
        basename = pathlib.Path(vol_filename).stem
        iprint("Creating {}\n".format(vol_filename))
        copyfile(filename, vol_filename)
        updateVoltageFile(vol_filename,vol)
#        cmd0 = r"sed -r -i  '/CORNERS_LIST_FILE\s+/s/(.*)_(post|pre)\.corners/\1_{}_\2\.corners/g' {}".format(vol, vol_filename)
#        (stdout0, stderr0, ext_val0) = Misc.run_system_cmd(cmd0, NONE)
        cmd00 = r"sed -r -i  '/TESTBENCH/s/(TESTBENCH\s+)(.+)/\1{}/g' {}".format(basename, vol_filename)
        (stdout00, stderr00, ext_val00) = Misc.run_system_cmd(cmd00, NONE)

    for count,line in enumerate(content):
        line = line.strip()
        if line == '':
            continue
        if re.search(r'testbench',line,re.I):
            continue
        elif re.search(r'corners_list_file\s+.*', line, re.I):
            corner_file = re.search(r'.+\s+(.+)',line).group(1)
            if re.search(r'..\/corners\/', corner_file):
                fn = corner_file.split('/')[-1]
                corner_file = path + "/corners/" + fn
                corner_file.strip()
            elif re.search(r'\.corners$',corner_file,re.M):
                corner_file = path + "/corners/" + corner_file
                corner_file.strip()
            createCornerFile(path, corner_file, vdd)

    # print(file_list)


def createCornerFile(datapath, corner_file, vdd_list):
    tb_name = corner_file.split('/')[-1]

    for vol in vdd_list:

        voll = re.sub(r'\.','p',vol)
        vol = float(vol)

        if re.search(r'_post_mc|pre_mc',tb_name):
            tmp_name = re.sub(r'(.+)_(post_mc|pre_mc)\.corners','\\1_{}_\\2.corners', tb_name).format(voll)
        elif re.search(r'.+_post.*',tb_name):
            tmp_name = re.sub(r'(.+)_(post.*)\.corners','\\1_{}_\\2.corners', tb_name).format(voll)
        elif re.search(r'.+_pre.*',tb_name):
            tmp_name = re.sub(r'(.+)_(pre.*)\.corners','\\1_{}_\\2.corners', tb_name).format(voll)
        elif re.search(r'.+_mc.*',tb_name):
            tmp_name = re.sub(r'(.+)_(mc.*)\.corners','\\1_{}_\\2.corners', tb_name).format(voll)
        else:
            tmp_name = re.sub(r'(.+)\.corners','\\1_{}.corners', tb_name).format(voll)


#        if re.search(r'_post_mc|pre_mc|mc|post|pre',tb_name):
#            tmp_name = re.sub(r'(.*)_(post_mc|pre_mc|mc|post|pre)\.corners','\\1_{}_\\2.corners',tb_name).format(voll)
#        else:
#            tmp_name = re.sub(r'(.*)\.corners','\\1_{}.corners',tb_name).format(voll)

        tmp_name = datapath + "/corners/" + tmp_name
        corner_file = corner_file.strip()
        tmp_name = tmp_name.strip()
        if os.path.isfile(corner_file) is False:
            eprint("Couldn't find {}. No copy will be created for {}\n".format(corner_file,vol))
            continue
        copyfile(corner_file, tmp_name)

        iprint("Created {} from {}\n".format(tmp_name, tb_name))

        upper_bound = round((vol + (vol * 0.1)),3)
        lower_bound = round((vol - (vol * 0.1)), 3)

        cmd1 = "sed -i 's/0.75/{}/g' {}".format(vol,tmp_name)
        cmd2 = "sed -i 's/0.825/{}/g' {}".format(upper_bound, tmp_name)
        cmd3 = "sed -i 's/0.675/{}/g' {}".format(lower_bound,tmp_name)

        iprint("Updating 0.75v to {}\n".format(vol))
        (stdout1, stderr1, ext_val1) = Misc.run_system_cmd(cmd1, NONE)

        iprint("Updating 0.825v to {}\n".format(upper_bound))
        (stdout2, stderr2, ext_val2) = Misc.run_system_cmd(cmd2, NONE)

        iprint("Updating 0.675v to {}\n".format(lower_bound))
        (stdout3, stderr3, ext_val3) = Misc.run_system_cmd(cmd3, NONE)

    return


def main() -> None:
    xls = pd.ExcelFile(xlsx_file)
    df = pd.read_excel(xls,macro,index_col=None)
    df_update = df[(df.UPDATE == 'Y') | (df.UPDATE == 'y')]
    for index,row in df_update.iterrows():
        vdd = []
        tb_name = row['Testbench List']
        if type(row['VDD']) is float:
            v = str(row['VDD'])
            vdd.append(v)
        else:
            vdd = row['VDD'].split(' ')
        filename = path + '/bbSim/' + tb_name
        updateData(filename, tb_name, vdd)


if __name__ == "__main__":
    args = parse_args()
    filename = os.getcwd() + "/" + os.path.basename(__file__) + ".log"
    logger = Messaging.create_logger(filename)  # Create log file

    # Register exit function
    atexit.register(Messaging.footer)

    # Initalise shared variables and run main
    version = Misc.get_release_version()
    CommonHeader.init(args, __author__, version)

    Misc.utils__script_usage_statistics(__tool_name__, version)
    Messaging.header()
    global xlsx_file
    global macro
    global path
    xlsx_file = args.file
    macro = args.macro
    path = args.path
    main()
    iprint(f"Log file: {filename}")
