#!/depot/Python/Python-3.8.0/bin/python -E
import os
import re
import sys
import collections
import subprocess
from colorama import Fore
import webbrowser
import argparse
import pathlib

# ----------------------------------#
bindir = str(pathlib.Path(__file__).resolve().parent)
sys.path.append(bindir + '/../lib/python/Util')
sys.path.append(bindir + '/../lib/python')
# ----------------------------------#
from Misc import utils__script_usage_statistics, get_release_version
__version__ = get_release_version(bindir)

utils__script_usage_statistics(__file__, __version__)


def parse_args():

    # Always include -v, and -d
    parser = argparse.ArgumentParser(description='description here')

    parser.add_argument('-l','--list', metavar='<#>', required=True,
                        type=str, default='',
                        help='Macro list')

    parser.add_argument('-r', '--rel',metavar='<#>', required=True,
                        type=str, default='',
                        help="Release number")
    parser.add_argument('-d','--dir', metavar='<#>', required=True,
                        type=str, default='',
                        help='Data directory')

    parser.add_argument('-m', '--metal',metavar='<#>', required=True,
                        type=str, default='',
                        help="MetalStack")
    parser.add_argument('-L','--local', metavar='<#>', required=False,
                        type=str, default='',
                        help='Local run')

    parser.add_argument('-e', '--error',metavar='<#>', required=False,
                        type=str, default='',
                        help="Error list file")

    args = parser.parse_args()
    return(args.list, args.rel, args.dir, args.metal, args.local, args.error)


def createDir():
    if os.path.isdir("./PHYv_dash"):
        subprocess.Popen(['rm','-r','-f',"./PHYv_dash"]).communicate()
    os.mkdir("./PHYv_dash")
    os.chdir("PHYv_dash/")


def getMacroDir(dropdir, macro_name, rel, user, user_dropdir):
    if user == 0:
        dirname = dropdir + "/" + macro_name + "/" + rel + "/..."
        macroDir = user_dropdir + "/" + macro_name + "/" + rel + "/" + "macro/"
        if os.path.isdir(macroDir) is False:
            subprocess.Popen(['p4','sync',dirname],stdout=subprocess.PIPE).communicate()

    elif user == 1:
        macroDir = dropdir + "/" + macro_name + "/" + rel + "/" + "macro/"
    return(macroDir)


def main():
    macroList = ""
    rel = ""
    dropdir = ""
    metal = ""
    user = 0
    global err
    err = "NA"

    (macroList, rel, dropdir, metal, user, err) = parse_args()
    check_list = collections.defaultdict(dict)

    if user:
        user_dropdir = dropdir
    else:
        depotview = subprocess.Popen(['p4', 'where', dropdir],stdout=subprocess.PIPE)
        depotview = depotview.communicate()[0].decode('utf-8')
        depotview = depotview.split()
        depotview = depotview[-1]

        user_dropdir = depotview

    mf = open(macroList,'r')
    filenames = mf.readlines()
    createDir()
    html = open('./PHYv_checks.htm','w')
    print('\033[1m' + '\t\t\t\t\tBuiling dashboad...')

    error_list = []
    if err != "NA":
        eid = open(err,'r')
        error_list = eid.readlines()
        error_list = [x.strip() for x in error_list]

    chk_names = collections.defaultdict(dict)
    chk_names['ERC'] = []
    chk_names['DRC'] = []
    chk_names['LVS'] = []
    chk_names['ANT'] = []

    for files in filenames:
        macro_name = files.strip()
        if macro_name.startswith("#"):
            continue
        check_list[macro_name]['LVS'] = {}
        check_list[macro_name]['ERC'] = {}
        check_list[macro_name]['ANT'] = {}
        check_list[macro_name]['DRC'] = {}

        macroDir = getMacroDir(dropdir, macro_name, rel, user, user_dropdir)

        print(Fore.GREEN + "\nCreating directory{}\n".format(macro_name))
        os.mkdir(macro_name)

        print(Fore.GREEN + "Checking LVS rpt  file...")
        check_list = LVS(macro_name, check_list, macroDir, metal)

        print(Fore.GREEN + "Checking EXTRACTION rpt  file...")
        check_list,chk_names = ERC(macro_name,check_list, macroDir, metal, chk_names)

        print(Fore.GREEN + "Checking DRC rpt file...")
        check_list,chk_names = DRC(macro_name,check_list, macroDir, metal, chk_names, error_list)

        print(Fore.GREEN + "Checking ANT rpt file...")
        check_list,chk_names = ANT(macro_name, check_list, macroDir, metal, chk_names)
    for macro in check_list.keys():
        for pv in check_list[macro].keys():
            count = 0

            if pv == 'LVS' or pv == 'ANT':
                continue
            for c in chk_names[pv]:
                if c not in check_list[macro][pv].keys():
                    check_list[macro][pv][c] = "-"
            count = collections.Counter(check_list[macro][pv].values())['Yes']
            check_list[macro][pv]['OTHER {}'.format(pv)] = count

    html.write(html_builder(macro_name,check_list,chk_names,error_list))
    html.close()
    print('\033[1m' + "-I- Run complete. Please check PHYv_dash/PHYv_checks.htm file")
    print('\033[1m' + '\t\t\t\t\tDashboard Created,Opening in browser\n')
    webbrowser.open_new_tab('PHYv_checks.htm')
    print("\n")
    sys.stdout.flush()
    os.chdir("../")


def LVS(macro, cl, dirpath, metal):
    check = 0
    filename = dirpath + "icv" + "/"
    filename += "lvs" + "/" + "lvs_" + macro
    filename += "_" + metal + ".rpt"
    if not os.path.isfile(filename):
        cl[macro]['LVS']['CLEAN/DIRTY'] = "RPT file not found"
        return(cl)
    with open(filename, 'r') as f:
        for line in f:
            line = line.strip()
            if line != '' and re.search('Final comparison result:FAIL', line, re.IGNORECASE):
                check = 1
                cl[macro]['LVS']['CLEAN/DIRTY'] = "Dirty"
    if check == 0:
        cl[macro]['LVS']['CLEAN/DIRTY'] = "Clean"
    return(cl)


def ERC(macro, cl, dirpath, metal, cn):
    count = 0
    copy = False
    erc = []
    filename = dirpath + "icv" + "/" + "erc" + "/" + "erc_" + macro + "_" + metal + ".rpt"
    if os.path.isfile(filename) is False:
        cl[macro]['ERC']['CLEAN/DIRTY'] = "RPT file not found"
        return(cl)
    os.chdir(macro)
    subprocess.Popen(["pvcomp_results",'-f',filename,'-l','e','--ct','erc'],stdout=subprocess.PIPE,stderr=subprocess.PIPE).communicate()
    op_file = macro + "_e_drc_errorList.csv"
    # with open(op_file,'r') as f:
    f = open(op_file, 'r').readlines()
    for line in f:
        line = line.strip()
        if line != '' and not line.startswith("*") and re.search(r'rule',line,re.IGNORECASE):
            copy = True
        elif line != '' and not line.startswith("*") and copy and re.search(r'\w+',line) and not re.search('total*',line,re.IGNORECASE):
            chk_name = line.split(",")[0]
            erc.append(chk_name)
            count += 1
        if line != '' and not line.startswith("*") and re.search(r'TOTAL violations,',line,re.IGNORECASE):
            copy = False

    for chk in erc:
        if chk not in cn['ERC']:
            cn['ERC'].append(chk)
    for c in erc:
        cl[macro]['ERC'][c] = "-"
        if c in erc:
            cl[macro]['ERC'][c] = "Yes"

    os.chdir("../")
    return(cl,cn)


def ANT(macro, cl, dirpath, metal, cn):
    count = 0
    copy = False
    ant = []
    filename = dirpath + "icv" + "/" + "ant" + "/" + "ant_" + macro + "_" + metal + ".rpt"
    if os.path.isfile(filename) is False:
        cl[macro]['ANT']['CLEAN/DIRTY'] = "RPT file not found"
        return(cl)
    os.chdir(macro)
    subprocess.Popen(["pvcomp_results",'-f',filename,'-l','a','--ct','ant'],stdout=subprocess.PIPE,stderr=subprocess.PIPE).communicate()
    op_file = macro + "_a_drc_errorList.csv"
    with open(op_file,'r') as f:
        for line in f:
            line = line.strip()
            if line != '' and not line.startswith("*"):
                if re.search(r'rule',line,re.IGNORECASE):
                    copy = True
                elif copy and re.search(r'\w+',line) and not re.search('total*',line,re.IGNORECASE):
                    chk_name = line.split(",")[0]
                    ant.append(chk_name)
                    count += 1
                if re.search(r'TOTAL violations,',line,re.IGNORECASE):
                    copy = False

    if len(ant) > 0:
        cl[macro]['ANT']['CLEAN/DIRTY'] = "Dirty"
    else:
        cl[macro]['ANT']['CLEAN/DIRTY'] = "Clean"

    os.chdir("../")
    print(cl)
    return(cl,cn)


def DRC(macro, cl, dirpath, metal, cn, error_list):
    count = 0
    copy = False
    drc = []
    filename = dirpath + "icv" + "/" + "drc" + "/" + "drc_" + macro + "_" + metal + ".rpt"
    if os.path.isfile(filename) is False:
        cl[macro]['DRC']['CLEAN/DIRTY'] = "RPT file not found"
        return(cl)
    os.chdir(macro)
    subprocess.Popen(["pvcomp_results",'-f',filename,'-l','d','--ct','drc'],stdout=subprocess.PIPE,stderr=subprocess.PIPE).communicate()
    op_file = macro + "_d_drc_errorList.csv"
    with open(op_file,'r') as f:
        for line in f:
            line = line.strip()
            if line != '' and not line.startswith("*") and re.search(r'rule',line,re.IGNORECASE):
                copy = True
            elif line != '' and not line.startswith("*") and copy and re.search(r'\w+',line) and not re.search('total*',line,re.IGNORECASE):
                chk_name = line.split(",")[0]
                if re.search(r'Density',chk_name,re.IGNORECASE) or re.search(r'\.DN\.',chk_name,re.IGNORECASE) and 'Density' not in drc:
                    drc.append("Density")
                elif re.search(r'boundary',chk_name,re.IGNORECASE) and 'IP_TIGHTEN' not in drc:
                    drc.append("IP_TIGHTEN")
                else:
                    chk_name = chk_name.split(' ')[-1]
                    if chk_name not in drc:
                        drc.append(chk_name)
                        count += 1
            if line != '' and not line.startswith("*") and re.search(r'TOTAL violations,',line,re.IGNORECASE):
                copy = False
    (cl, cn) = getDRC(drc, cn, cl, macro, error_list)

    os.chdir("../")
    return(cl,cn)


def getDRC(drc, cn, cl, macro, error_list):
    for chk in drc:
        if chk not in cn['DRC']:
            cn['DRC'].append(chk)
    if "OTHER DRC" not in cn['DRC']:
        cn['DRC'].append('OTHER DRC')
    for c in drc:
        if err != "NA" and c in error_list:
            cl[macro]['DRC'][c] = "Yes"
        else:
            cl[macro]['DRC'][c] = "Yes"
    return(cl, cn)


def colLen(cn, chk):
    ll = 0
    if len(cn[chk]) > 0 and len(cn[chk]) < 5:
        ll = len(cn[chk]) + 1
    elif len(cn[chk]) > 5:
        ll = 6
    elif len(cn[chk]) == 0:
        ll = 2
    return(ll)


def html_builder(macro,cl,cn,error_list):    # noqa C901

    count = 0
    html_str = '<table border="1" class="dataframe" style="background-color:#F5F5DC" width=80%; ">'
    html_str += '<tr><th>Macro Name</th><th colspan=1>LVS Status</th><th colspan={}>Extraction Status</th><th colspan=1>ANT Status</th><th colspan=11>DRC Status</th></tr>'.format(colLen(cn,'ERC'))

    html_str += '<tr><th> </th>'

    html_str += ''.join(['<th  width="60%">{}</th>'.format(x) for x in cl[macro]['LVS'].keys()])
    for x in cl[macro]['ERC'].keys():
        if x == 'OTHER ERC':
            continue

        count = count + 1
        if count > 4:
            break
        else:
            html_str += '' + '<th  width="60%">{}</th>'.format(x)

    html_str += '' + '<th  width="60%">OTHER ERC</th>'
    count = 0

    count = 0
    html_str += ''.join(['<th width="60%">{}</th>'.format(x) for x in cl[macro]['ANT'].keys()])
    for x in sorted(cl[macro]['DRC'].keys()):
        count += 1
        if count > 10 and err == "NA":
            break
        if x == "OTHER DRC":
            continue
        if x in error_list and err != "NA":
            html_str += '' + '<th  width="60%">{}</th>'.format(x)
        elif err == "NA":
            html_str += '' + '<th  width="60%">{}</th>'.format(x)
    html_str += '' + '<th  width="60%">Other DRC</th>'
    html_str += '</tr>'
    for m in cl.keys():

        html_str += '<tr><th>{}</th>'.format(m)
        html_str += ''.join(['<td width="60%">{}</td>'.format(x) for x in cl[m]['LVS'].values()])

        count = 0
        for x1,x2 in cl[m]['ERC'].items():
            if x1 == 'OTHER ERC':
                continue
            count = count + 1
            if count > 4:
                break
            else:
                html_str += '' + '<th  width="60%">{}</th>'.format(x2)
        if cl[m]['ERC']['OTHER ERC'] > count:
            html_str += '' + '<th  width="60%">{} Other DRC error present</th>'.format(cl[m]['ERC']['OTHER ERC'] - count)
        else:
            html_str += '' + '<th  width="60%">Clean</th>'

        html_str += ''.join(['<td width="60%">{}</td>'.format(x) for x in cl[m]['ANT'].values()])

        count = 0
        for x2 in sorted(cl[m]['DRC'].keys()):
            count = count + 1
            if count > 10 and err == "NA":
                break
            elif x2 in error_list and err != "NA":
                if x2 == "OTHER DRC":
                    continue
                html_str += '' + '<th  width="60%">{}</th>'.format(cl[m]['DRC'][x2])
            elif err == "NA":
                if x2 == "OTHER DRC":
                    continue
                html_str += '' + '<th  width="60%">{}</th>'.format(cl[m]['DRC'][x2])
        html_str += '' + '<th  width="60%">{} Other DRCs are present</th>'.format(cl[m]['DRC']['OTHER DRC'])

    html_str += '</tr>'

    return(html_str)


if __name__ == "__main__":
    main()
