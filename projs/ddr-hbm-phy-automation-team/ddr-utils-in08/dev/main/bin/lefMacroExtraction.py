#!/depot/Python/Python-3.8.0/bin/python -E

'''


Written by Hemant Bisht

USAGE:    /remote/in01home12/hbisht/Scripts/lefMacroExtraction.py -lef <LefPath>


USAGE Example:      /remote/in01home12/hbisht/Scripts/lefMacroExtraction.py -lef /slowfs/in01dwt2p024/hbisht/p4_ws/products/ddrg3mphy/process/umc28hpc18/sstl/main/1P8M0B0T1A1U_FC/lef/dwc_d4mv_io.lef



POINT TO NOTE:

------> Make sure to sync depot directory in P4 Local path before running the script
        Example -->    Using p4 sync -f //depot/products/ddrg3mphy/process/umc28hpc18/sstl/main/1P8M0B0T1A1U_FC/... )
------> Make sure to create a directory where you want these separated lef to be generated
        Example -->
            hbisht@in01msemt085 [6:35pm] [~/p4_ws/D613_LEF_ALL/]/remote/in01home12/hbisht/Scripts/lefMacroExtraction.py -lef /slowfs/in01dwt2p024/hbisht/p4_ws/products/ddrg3mphy/process/umc28hpc18/sstl/main/1P8M0B0T1A1U_FC/lef/dwc_d4mv_io.lef


WORKING:
   - This Script extract lefs inside a combined lef file separately in a directory
   - Filtered out ** ALL **  the cell lefs separately starting from "MACRO" to "END"
   - This Script works on both .lef and  _merged.lef

---> hbisht@synopsys.com

'''

from os import path
import argparse
import sys
import re
import pathlib

# ----------------------------------#
bindir = str(pathlib.Path(__file__).resolve().parent)
sys.path.append(bindir + '/../lib/python/Util')
sys.path.append(bindir + '/../lib/python')
# ----------------------------------#
from Misc import utils__script_usage_statistics, get_release_version
__version__ = get_release_version(bindir)

utils__script_usage_statistics(__file__, __version__)


def rel_local_macro_check(lef_path, lef_suffix):
    global file_name, macro_name
    macro_name = []
    lef_stdout = open(lef_path, 'r').readlines()
    for line in lef_stdout:
        if line.startswith('MACRO'):
            macro_name.append(re.split(r'MACRO', line)[1].split("\n")[0].strip())
    for z in macro_name:
        startline = 'MACRO' + " " + z
        endline = 'END' + " " + z
        flag = False
        mylines = []
        for y in lef_stdout:
            if y.startswith(startline):
                flag = not flag
            if flag:
                mylines.append(y)
                if y.startswith(endline):
                    break
        file_context = "".join(mylines)
        file_name_output = z + lef_suffix
        f = open(file_name_output, "w")
        f.write(file_context)
        f.close()
    print("INFO: LEFs separated\n")


def main():
    global lef_suffix
    ap = argparse.ArgumentParser()
    ap.add_argument("-lef", required=True,
                    help="LEF Path e.g., /slowfs/us01dwt2p373/hbisht/p4_ws/products/ddrg3mphy/process/umc28hpc18/sstl/main/1P8M0B0T1A1U_FC/lef/dwc_d4mv_io.lef")
    args = vars(ap.parse_args())
    print("\n")
    if path.isfile(str(args['lef'])) is True:
        if str(args['lef']).endswith(".lef") is True:
            print("INFO: LEF Path {} is Correct \n".format(str(args['lef'])))
            if str(args['lef']).endswith("merged.lef") is True:
                lef_suffix = "_merged.lef"
                rel_local_macro_check(str(args['lef']), lef_suffix)
            else:
                lef_suffix = ".lef"
                rel_local_macro_check(str(args['lef']), lef_suffix)
        else:
            print("ERROR: LEF Path {} exists but does not end with lef \n".format(str(args['lef'])))
            sys.exit(2)
    else:
        print("ERROR: LEF Path {} is Incorrect \n".format(str(args['lef'])))
        sys.exit(2)


if __name__ == '__main__':
    main()
