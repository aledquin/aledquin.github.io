#!/depot/Python/Python-3.8.0/bin/python
###############################################################################
#
# Name    : variation_coeffQA.py
# Author  : Dikshant Rohatgi
# Date    : 07/21/2022
# Purpose : QA script for variation coeff.
#           Makes sure that coeff are generated for all devices with
#           their repective legnths.
#           Also makes sure that the coeff series
#           are complete and are increaing.
#
# Modification History
#     000 Dikshant Rohatgi  07/21/2022
#         Created this script
#
#
###############################################################################

__author__ = 'dikshant'
__version__ = '2022ww34'

import argparse
import os
import pathlib
import sys
import re

# ----------------------------------#
bindir = str(pathlib.Path(__file__).resolve().parent)
sys.path.append(bindir + '/../lib/python/Util')
sys.path.append(bindir + '/../lib/python')
# ----------------------------------#

# Import constants
# Import messaging subroutines
from Messaging import iprint, eprint
# Import logging routines
from Messaging import create_logger

from Misc import utils__script_usage_statistics, get_release_version
__version__ = get_release_version(bindir)

utils__script_usage_statistics(__file__, __version__)


def parse_args():

    # Always include -v, and -d
    parser = argparse.ArgumentParser(description='description here')
    parser.add_argument('-v', metavar='<#>', type=int,
                        default=0, help='verbosity')
    parser.add_argument('-d', metavar='<#>', type=int,
                        default=0, help='debug')
    parser.add_argument('-variation', metavar='<#>', required=True,
                        type=str, default='',
                        help='Variation directory path.Should be local')

    parser.add_argument('-config', metavar='<#>', required=True,
                        type=str, default='',
                        help="alphaNT.config file path.local/project one")

    args = parser.parse_args()
    return args


def getParameterFilePath(corner_list, var_path):
    path_list = []
    for crnr in corner_list.keys():
        for vol in corner_list[crnr]:
            param_path = var_path + "/" + vol
            param_path += "/timing/Run_{}_etm/xtor_variations".format(crnr)
            param_path += "/set_variation_parameters.tcl"
            path_list.append(param_path)
    return(path_list)


def checkIncr(var_dict, le, dev, path):
    param_list = ["-variation","-series2","-series3","-series4"]
    check = all(item in var_dict.keys() for item in param_list)
    if check:
        v1 = float(var_dict["-variation"])
        v2 = float(var_dict["-series2"])
        v3 = float(var_dict["-series3"])
        v4 = float(var_dict["-series4"])
        if v2 > v1 and v3 > v2 and v4 > v3:
            return
        else:
            eprint("Device {}/{}/{} in {} variation series is not incremental".
                   format(dev, le, var_dict['set_variation_parameters'],
                          path))
            return
    else:
        eprint("Device {}/{}/{} in {} variation series is not complete".
               format(dev, le, var_dict['set_variation_parameters'],
                      path))


def checkSeries(var_dict, name, dev, path):
    if name not in var_dict.keys() or float(var_dict[name]) < 0:
        eprint("Device {}/{} in {} {} is missing or is less than equal to 0.".
               format(dev, var_dict['set_variation_parameters'],
                      name, path))
    return


def checkLengthVoltage(dev, device_list,
                       corner_list, var_dict,
                       vol, corner, path):
    if var_dict['-length'] not in device_list[dev]:
        eprint("Device {} in {}, length is unspecified"
               "in userFile. Found length = {}".
               format(dev, path, var_dict['-length']))
    if var_dict['-voltage'] != corner_list[corner][vol]:
        eprint("Device {} in {}, voltage is unspecified"
               "in config file. Found voltage = {}".
               format(dev, path, var_dict['-voltage']))


def checkParameter(corner_list, var_path, device_list, path, dev):
    corner = path.split('/')[-3].split('_')[1]
    vol = path.split('/')[-5]
    for le in device_list[dev]:
        min_flag = False
        max_flag = False
        # f = open(path, 'r')
        patt = r'^\w+.+{}.+-length\s+{}.+'.format(dev, le)
        patt = re.compile(patt)
        with open(path, 'r') as f:
            for line in f:
                if patt.search(line):
                    line = line.strip()
                    itr = iter(line.split(' '))
                    var_dict = dict(zip(itr, itr))
                    cv = corner_list[corner][vol]
                    al = var_dict['-length']
                    av = var_dict['-voltage']
                    vp = var_dict['set_variation_parameters']
                    if al in device_list[dev] and av == cv and vp == "-min":
                        min_flag = True
                        if min_flag and max_flag:
                            break
                    if al in device_list[dev] and av == cv and vp == "-max":
                        max_flag = True
                        if min_flag and max_flag:
                            break
                    checkLengthVoltage(dev, device_list, corner_list,
                                       var_dict, vol, corner, path)
                    checkSeries(var_dict, "-variation", dev, path)
                    checkSeries(var_dict, "-series2", dev, path)
                    checkSeries(var_dict, "-series3", dev, path)
                    checkSeries(var_dict, "-series4", dev, path)
                    checkIncr(var_dict, le, dev, path)
        if not min_flag:
            eprint("Device {}/{} min parameter was not found in {}".
                   format(dev, le, path))
        if not max_flag:
            eprint("Device {}/{} max parameter was not found in {}".
                   format(dev, le, path))


def main():

    corner_list = {}
    with open(args.config, 'r') as f:
        for line in f:
            if line != '' and re.search(r'cornerData', line):
                if re.search(r'^#cornerData',line):
                    next
                match = re.search(r'cornerData\((.+)\)\s+\{(.*)\,Temp',
                                  line, re.I)
                corner = match.group(1)
                vols = match.group(2)
                vol_dict = dict(x.split(" ") for x in vols.split(","))
                corner_list[corner] = vol_dict
    device_list = {}
    with open(args.variation + "/sourcefiles/userFile", 'r') as v:
        for line in v:
            if line != '':
                line = line.strip()
                dev1 = line.split(' ')[0]
                dev2 = line.split(' ')[1]
                le = line.split(' ')[2]
                if all(key not in device_list.keys() for key in (dev1, dev2)):
                    device_list[dev1] = []
                    device_list[dev2] = []
                device_list[dev1].append(le)
                device_list[dev2].append(le)
    param_paths = getParameterFilePath(corner_list, args.variation)
    for path in param_paths:
        for dev in device_list.keys():
            if not os.path.isfile(path):
                eprint("Can't find {}".format(path))
                break
            checkParameter(corner_list, args.variation, device_list, path, dev)
    pass


if __name__ == '__main__':

    args = parse_args()
    filename = os.getcwd() + '/' + os.path.basename(__file__) + '.log'
    logger = create_logger(filename)                       # Create log file

    # Register exit function
    # atexit.register(footer)

    # header()
    main()
    iprint(f"Log file: {filename}")
