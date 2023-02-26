#!/depot/Python/Python-3.8.0/bin/python -E

'''


Written by Hemant Bisht

USAGE:    /remote/in01home12/hbisht/Scripts/lefCellListExtraction.py -lef <LefPath> -cell <CellListPath>


USAGE Example:      /remote/in01home12/hbisht/Scripts/lefCellListExtraction.py -lef /slowfs/in01dwt2p024/hbisht/p4_ws/products/ddrg3mphy/process/umc28hpc18/sstl/main/1P8M0B0T1A1U_FC/lef/dwc_d4mv_io.lef -cell /slowfs/in01dwt2p024/hbisht/p4_ws/products/ddrg3mphy/process/umc28hpc18/sstl/main/1P8M0B0T1A1U_FC/doc/cells.txt

WORKING:
    This Script extract a lef of cells mentioned in Cells.txt file separately in a directory
    Filtered out lef separately starting from "MACRO" to "END"
    This Script works on both .lef and  _merged.lef

POINT TO NOTE:

------> Make sure to sync depot directory in P4 Local path before running the script
        Example -->    Using p4 sync -f //depot/products/ddrg3mphy/process/umc28hpc18/sstl/main/1P8M0B0T1A1U_FC/... )
------> Make sure to create a directory where you want these separated lef to be generated
        Example -->
            hbisht@in01msemt085 [6:35pm] [~/p4_ws/D613_LEF_ALL/]/remote/in01home12/hbisht/Scripts/lefCellListExtraction.py -lef /slowfs/in01dwt2p024/hbisht/p4_ws/products/ddrg3mphy/process/umc28hpc18/sstl/main/1P8M0B0T1A1U_FC/lef/dwc_d4mv_io.lef -cell /slowfs/in01dwt2p024/hbisht/p4_ws/products/ddrg3mphy/process/umc28hpc18/sstl/main/1P8M0B0T1A1U_FC/doc/cells.txt



---> hbisht@synopsys.com

'''
import os
from os import path, listdir
import argparse
import sys
import pathlib

# ----------------------------------#
bindir = str(pathlib.Path(__file__).resolve().parent)
sys.path.append(bindir + '/../lib/python/Util')
sys.path.append(bindir + '/../lib/python')
# ----------------------------------#
from Misc import utils__script_usage_statistics, get_release_version
__version__ = get_release_version(bindir)

utils__script_usage_statistics(__file__, __version__)


def local_file_lst(local_path):
    local_file_lst_stdout = [x for x in listdir(local_path) if path.isfile(local_path + "/" + x)]
    return local_file_lst_stdout


def rel_local_macro_check(lef_path, cell_path, lef_suffix):
    global file_name, macro_name, lef_data
    lef_data = ""
    macro_name = []
    lef_stdout = open(lef_path, 'r').readlines()
    cell_stdout = open(cell_path, 'r').readlines()
    for cell in cell_stdout:
        cell = cell.split("\n")[0]
        startline = 'MACRO' + " " + cell
        endline = 'END' + " " + cell
        flag = False
        mylines = []
        for y in lef_stdout:
            if y.startswith(str(startline)):
                flag = not flag
            if flag:
                mylines.append(y)
                if y.startswith(str(endline)):
                    break
        file_context = "".join(mylines)
        cell_lef = cell + lef_suffix
        f = open(cell_lef, "w")
        f.write(file_context)
        f.close()
    print("INFO: LEF Files have been separated out from {} \n".format(str(lef_path)))
    (all_lef, directory, lef_data) = fillFiles(lef_suffix, lef_path)
    # print(lef_data)
    f = open(all_lef, "w+")
    f.write(lef_data)
    f.close()
    out_path = directory + "/" + all_lef
    print("INFO: ALL_LEF File have been created containing combined data of all Separted LEF in {}\n".format(
        str(out_path)))


def fillFiles(lef_suffix, lef_path):
    directory = os.getcwd()
    local_file = []
    local_file = local_file_lst(directory)
    lef_data = ""
    all_lef = "ALL_LEF" + lef_suffix
    for r_lef in local_file:
        lef_sep_path = directory + "/" + r_lef
        lef_infile = open(lef_sep_path, 'r').readlines()
        if str(lef_path).endswith("merged.lef") is True:
            r_lef_split = r_lef.split("_merged.lef")[0]
        else:
            r_lef_split = r_lef.split(".lef")[0]
        start_line = 'MACRO' + " " + r_lef_split
        end_line = 'END' + " " + r_lef_split
        f_flag = False
        newlines = []
        for y in lef_infile:
            if y.startswith(str(start_line)):
                f_flag = not f_flag
            if f_flag:
                newlines.append(y)
                if y.startswith(str(end_line)):
                    break
        file_context = "".join(newlines)
        lef_data = lef_data + "\n\n" + file_context
    return(all_lef, directory, lef_data)


def main():
    global lef_suffix
    ap = argparse.ArgumentParser()
    ap.add_argument("-lef", required=True,
                    help="LEF Path e.g., /slowfs/us01dwt2p373/hbisht/p4_ws/products/ddrg3mphy/process/umc28hpc18/sstl/main/1P8M0B0T1A1U_FC/lef/dwc_d4mv_io.lef")
    ap.add_argument("-cell", required=True,
                    help="Cell List Path e.g., /slowfs/in01dwt2p024/hbisht/p4_ws/products/ddrg3mphy/process/umc28hpc18/sstl/main/1P8M0B0T1A1U_FC/doc/cells.txt")
    args = vars(ap.parse_args())
    print("\n")
    if path.isfile(str(args['lef'])) is True:
        if str(args['lef']).endswith(".lef") is True:
            print("INFO: LEF Path {} is Correct \n".format(str(args['lef'])))
            if path.isfile(str(args['cell'])) is True:
                if str(args['lef']).endswith("merged.lef") is True:
                    lef_suffix = "_merged.lef"
                    rel_local_macro_check(str(args['lef']), str(args['cell']), lef_suffix)
                else:
                    lef_suffix = ".lef"
                    rel_local_macro_check(str(args['lef']), str(args['cell']), lef_suffix)
            else:
                print("ERROR: Cell List File Path {} is Incorrect \n".format(str(args['cell'])))
                sys.exit(2)
        else:
            print("ERROR: LEF Path {} exists but does not end with lef \n".format(str(args['lef'])))
            sys.exit(2)
    else:
        print("ERROR: LEF Path {} is Incorrect \n".format(str(args['lef'])))
        sys.exit(2)


if __name__ == '__main__':
    main()
