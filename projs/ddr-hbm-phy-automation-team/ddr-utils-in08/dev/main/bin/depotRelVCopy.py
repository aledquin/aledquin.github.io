#!/depot/Python/Python-3.8.0/bin/python -E

'''


Written by Hemant Bisht

USAGE:	./depotRelVCopy.py -path <oldreleasemacro_path> -newpath <newreleasemacro_path> -desc <Description>

USAGE Example:
    ./depotRelVCopy.py -path /slowfs/us01dwt2p373/hbisht/p4_ws/products/hbm3/project/d750-hbm3-tsmc5ff12/ckt/rel/dwc_hbmphy_rxmd_ew/1.00a/macro
            -newpath /slowfs/us01dwt2p373/hbisht/p4_ws/products/hbm3/project/d750-hbm3-tsmc5ff12/ckt/rel/dwc_hbmphy_rxmd_ew/1.10a/macro
            -desc CopiedFromRel1.00

POINT TO NOTE:

------> Make sure to sync both new rel version and old version in P4 Local path before running the script
        Example -->	Using p4 sync -f //depot/products/hbm3/project/d750-hbm3-tsmc5ff12/ckt/rel/dwc_hbmphy_rxmd_ew/1.00a/macro/... )

WORKING:
- Copying old release files to new release and then uploading in P4 Depot
    Example, Copying REL1.00 to REL.1.10 and then uploading in P4 Depot path

---> hbisht@synopsys.com

'''

from os import path, mkdir, readlink, symlink, listdir
import argparse
import sys
import subprocess
import pathlib
import shutil
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


def local_file_list(local_path):
    local_file_list_stdout = [x for x in listdir(local_path) if path.isfile(local_path + "/" + x)]
    return local_file_list_stdout


def local_dir_list(local_path):
    local_dir_list_stdout = [x for x in listdir(local_path) if path.isdir(local_path + "/" + x)]
    return local_dir_list_stdout


def rel_local_macro_check(rel_path, rel_newpath, comment):
    macro_dir_list = []
    macro_dir_list = local_dir_list(rel_path)
    if "timing" in macro_dir_list:
        macro_dir_list.remove('timing')
    else:
        pass

    if path.exists(rel_newpath) and len(macro_dir_list) > 0:
        shutil.rmtree(rel_newpath)
        mkdir(str(rel_newpath))
        for array_dir in macro_dir_list:
            source_path = str(rel_path) + "/" + str(array_dir)
            new_rel_source_path = str(rel_newpath) + "/" + str(array_dir)
            mkdir(str(new_rel_source_path))
            file_arry = local_file_list(source_path)
            dir_arry = local_dir_list(source_path)
            if len(dir_arry) > 0:
                for d_arry in dir_arry:
                    sym_dir_path = str(source_path) + "/" + str(d_arry)
                    new_dir_path = str(new_rel_source_path) + "/" + str(d_arry)

                    if path.islink(sym_dir_path) is False:
                        copyP4(sym_dir_path,new_dir_path)
                    else:
                        linkto = readlink(sym_dir_path)
                        symlink(linkto, new_dir_path)
                        p4EditAdd(new_dir_path)
            else:
                pass

            if len(file_arry) > 0:
                for f_arry in file_arry:
                    sym_file_path = str(source_path) + "/" + str(f_arry)
                    new_file_path = str(new_rel_source_path) + "/" + str(f_arry)
                    if path.islink(sym_file_path):
                        linkto = readlink(sym_file_path)
                        symlink(linkto, new_file_path)
                    else:
                        p4_copy = subprocess.Popen(['cp', str(sym_file_path), str(new_rel_source_path) + "/."], stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
                        p4_copy_stdout, _ = p4_copy.communicate()
                    p4EditAdd(new_file_path)
            else:
                pass
    else:
        print("ERROR: No Directory Found")
        pass

    print("INFO: Files copied to new Release Directory \n")
    p4_submit_file = subprocess.Popen(['p4', 'submit', '-d', str(comment), rel_newpath + "/..."], stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    p4_submit_file_stdout, _ = p4_submit_file.communicate()
    p4_submit_file_stdout = str(p4_submit_file_stdout, 'utf-8')
    print(p4_submit_file_stdout)


def copyP4(sym_dir_path,new_dir_path):
    mkdir(str(new_dir_path))
    file_macro_arry = local_file_list(sym_dir_path)

    if len(file_macro_arry) > 0:
        # print(file_macro_arry)
        for f_mac_arry in file_macro_arry:
            old_f_mac_path = str(sym_dir_path) + "/" + str(f_mac_arry)
            f_mac_path = str(new_dir_path) + "/" + str(f_mac_arry)
            if path.islink(old_f_mac_path):
                linkto = readlink(old_f_mac_path)
                symlink(linkto, f_mac_path)
                p4_edit_file = subprocess.Popen(
                    ['p4', 'edit', str(f_mac_path)], stdout=subprocess.PIPE,
                    stderr=subprocess.STDOUT)
                p4_edit_file_stdout, _ = p4_edit_file.communicate()
                p4_edit_file_stdout = str(p4_edit_file_stdout, 'utf-8')
                if "file(s) not on client" in p4_edit_file_stdout:
                    p4_add_file = subprocess.Popen(['p4', 'add', str(f_mac_path)], stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
                    p4_add_file_stdout, _ = p4_add_file.communicate()
                    p4_add_file_stdout = str(p4_add_file_stdout, 'utf-8')
                    print(p4_add_file_stdout)
                else:
                    print(p4_edit_file_stdout)

            else:
                p4_copy = subprocess.Popen(['cp', str(old_f_mac_path), str(new_dir_path) + "/."], stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
                p4_copy_stdout, _ = p4_copy.communicate()
                p4EditAdd(f_mac_path)
    else:
        pass


def p4EditAdd(new_dir_path):
    p4_edit_file = subprocess.Popen(['p4', 'edit', str(new_dir_path)], stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    p4_edit_file_stdout, _ = p4_edit_file.communicate()
    p4_edit_file_stdout = str(p4_edit_file_stdout, 'utf-8')
    if "file(s) not on client" in p4_edit_file_stdout:
        p4_add_file = subprocess.Popen(['p4', 'add', str(new_dir_path)], stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        p4_add_file_stdout, _ = p4_add_file.communicate()
        p4_add_file_stdout = str(p4_add_file_stdout, 'utf-8')
        print(p4_add_file_stdout)
    else:
        print(p4_edit_file_stdout)


def main():
    global user_rel_path, p4_depot_rel_path, p4_ws_local_rel_path, qa_dir_local_rel_path, qa_dir_depot_rel_path, rel_log_file
    ap = argparse.ArgumentParser()
    ap.add_argument("-path", required=True, help="project path e.g., /slowfs/us01dwt2p373/hbisht/p4_ws/products/hbm3/project/d750-hbm3-tsmc5ff12/ckt/rel/dwc_hbmphy_clktx_ew/1.00a/macro")
    ap.add_argument("-newpath", required=True, help="project path e.g., /slowfs/us01dwt2p373/hbisht/p4_ws/products/hbm3/project/d750-hbm3-tsmc5ff12/ckt/rel/dwc_hbmphy_clktx_ew/1.10a/macro")
    ap.add_argument("-desc", required=True, help="e.g., copiedfromRel1_00")
    args = vars(ap.parse_args())
    print("\n")
    if path.exists(str(args['path'])):
        print("INFO: Path {} is Correct".format(str(args['path'])))
        if path.exists(str(args['newpath'])):
            print("INFO: New Release Path {} is Correct \n".format(str(args['newpath'])))
            rel_local_macro_check(str(args['path']), str(args['newpath']), str(args['desc']))
        else:
            print("ERROR: New Release Path {} is Incorrect \n".format(str(args['newpath'])))
            sys.exit(2)

    else:
        print("ERROR: Path {} is Incorrect \n".format(str(args['path'])))
        sys.exit(2)


if __name__ == '__main__':
    main()
