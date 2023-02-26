#!/depot/Python/Python-3.8.0/bin/python -BE
# Get names of cell libraries present in differen .sp files  Updated to cover missing cases
import os
import re
import sys
import pathlib
import argparse
info = {}
temp = {}
final = []
cell_name = ""

# ---------------------------------- #
bindir = str(pathlib.Path(__file__).resolve().parent)
# Add path to library that may be symbolically linked.
sys.path.append(bindir + '/../lib/Util')
# Add path to sharedlib's Python Utilities directory.
sys.path.append(bindir + '/../lib/python/Util')
# ---------------------------------- #

from Misc import utils__script_usage_statistics, run_system_cmd, get_release_version
__version__ = get_release_version(bindir)
utils__script_usage_statistics(__file__, __version__)


def parse_args():

    # Always include -v, and -d
    parser = argparse.ArgumentParser(description='description here')
    parser.add_argument('-c', type=int, default=False,
                        help='Convert <> into []',required=False)
    parser.add_argument('--netlist', type=str, default="",
                        help='NetList names seprated by ,',required=True)

    # Add your custom arguments here
    # -------------------------------------

    # -------------------------------------
    args = parser.parse_args()
    return args


def cellReport(netlist_names):
    info = {}
    temp = {}
    final = []
    cell_name = ""

    if len(netlist_names) < 2:
        print('No .Sp file given as input, exiting')
        exit()
    else:
        if 'NetList_summary' in netlist_names:
            netlist_names.remove('NetList_summary')
    fout = open("NetList_summary",'w')
    (info,temp) = extractData(netlist_names,temp)
    for c in info.keys():
        flag = checkKeys(info,c)

        if(flag == 0):
            fout.write('Found Cell {} in following Libraries\n'.format(c))
            for f in info[c].keys():
                fo = open(f,'r')
                content = fo.readlines()
                final = content
                index = [a for a,elem in enumerate(content) if(re.search(c,elem))]
                for v in range(len(info[c][f])):
                    fout.write('=> {}\t{}\t{}\n'.format(f,c,info[c][f][v]))
                    cell_name = c + "_" + info[c][f][v]
                    rgx = re.compile(r'.*%s_\d+' % c,re.A)

                    cc = 0
                    for count in index:
                        if count == "":
                            continue
                        else:
                            (index,final) = finalExtract(index,count,content,final,rgx,cell_name,c,cc,f)
                    fo.close()
                fo = open(f,'w')
                for fi in final:
                    fo.write(fi)
                fo.close()

    fout.write("\n")


def extractData(netlist_names,temp):
    j = 0
    for i in netlist_names:
        fp = open(i,'r')
        print("Extracting Info from ",i)
        line_num = 0
        content = fp.readlines()
        for line in content:
            line_num += 1
            if(re.match(r'^\* Library',line)):
                lib = ""
                lib = re.match(r'^\* Library|^\* Cell',line).string
                lib = re.split(r'\s+',lib)[-2]
            elif(re.match(r'^\* Cell',line)):
                cell = ""
                cell = re.match(r'^\* Cell',line).string
                cell = re.split(r'\s+',cell)[-2]
                if cell not in info:
                    info[cell] = {i: []}
                    info[cell][i].append(lib)
                else:
                    if i not in info[cell]:
                        temp = {i: []}
                        info[cell].update(temp)
                        j = 1
                    else:
                        temp = {i:info[cell][i]}
                        j += 1
                    temp[i].append(lib)

                    info[cell].update(temp)
    fp.close()
    return(info,temp)


def checkKeys(info,c):
    flag = 0
    if(len(info[c]) > 1):
        nn = iter(info[c])
        next_key1 = next(nn)
        next_key2 = next(nn)

        for j in range(len(info[c].keys())):
            if(next_key2 == -1):
                flag = 1
                break
            if(info[c][next_key1][0] in info[c][next_key2]):
                flag = 1
                next_key1 = next_key2
                next_key2 = next(nn,-1)
                continue

            if(not(info[c][next_key1][0] == info[c][next_key2])):
                flag = 0
                break
            else:
                next_key1 = next_key2
                next_key2 = next(nn,-1)
                flag = 1
    return(flag)


def finalExtract(index,count,content,final,rgx,cell_name,c,cc,f):
    if(re.search(r'^\*\s+Cell',content[count])):
        t = re.search(r'^\*\s+Lib.*:\s+(\w+)\s+',content[int(count) - 1])
        le = t.group(1)
        c_n = c + "_" + le
        final[count] = re.subn(c,c_n,content[count],2)[0]
        cc = index.index(count)
        index[cc] = ""
    if((not re.search(rgx,content[count])) and (not re.search(r'^\*\s+Cell',content[count],re.M))):
        final[count] = re.subn(c,cell_name,content[count],2)[0]
        cc = index.index(count)
        index[cc] = ""
    elif((rgx.search(content[count])) and (not re.search(r'^\*\s+Cell',content[count],re.M))):
        regex = ".*" + c + "_([0-9]+)"
        z = re.search(regex,content[count])
        num = z.group(1)
        num = int(num)
        if num != len(info[c][f]):
            num = len(info[c][f])
        c_n = c + "_" + info[c][f][num - 1]
        final[count] = re.subn(c,c_n,content[count],2)[0]
        cc = index.index(count)
        index[cc] = ""
    return(index,final)


def convertBracket(netlist_names):
    if 'NetList_summary' in netlist_names:
        netlist_names.remove('NetList_summary')
    for nl in netlist_names:
        (stdout, stderr, stdval) = run_system_cmd("sed -i -r 's/</[/g' {}".format(nl),0)
        (stdout1, stderr1, stdva1l) = run_system_cmd("sed -i -r 's/>/]/g' {}".format(nl),0)
    return


def main():

    if os.path.exists('NetList_summary'):
        print('NetList_summary file exists, deleting it')
        os.remove("NetList_summary")

    cellReport(netlist_names)
    if(con):
        convertBracket(netlist_names)


if __name__ == "__main__":
    args = parse_args()
    con = args.c
    netlist_names = args.netlist
    netlist_names = [str(item) for item in args.netlist.split(',')]
    main()
