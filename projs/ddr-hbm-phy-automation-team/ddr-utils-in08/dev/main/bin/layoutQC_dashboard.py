#!/depot/Python/Python-3.8.0/bin/python -E

import os
import re
import glob
import sys
import argparse
import collections
import subprocess
from colorama import Fore
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

    args = parser.parse_args()
    return(args.list, args.rel, args.dir, args.metal, args.local)


def main():
    (macroList, rel, dropdir, metal, user) = parse_args()

    subprocess.run(['/bin/csh','-c','module unload msip_shell_lef_utils'],stderr=subprocess.PIPE)
    subprocess.run(['/bin/csh','-c','module unload msip_shared_lib'],stderr=subprocess.PIPE)

    subprocess.run(['/bin/csh','-c','module load msip_shell_lef_utils'],stderr=subprocess.PIPE)
    subprocess.run(['/bin/csh','-c','module load msip_shared_lib'],stderr=subprocess.PIPE)

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
    if os.path.isdir("./QC_dash"):
        subprocess.Popen(['rm','-r','-f',"./QC_dash"]).communicate()
    os.mkdir("./QC_dash")
    os.chdir("QC_dash/")
    log = open("./layoutQC_dashbboard.log",'w')
    html = open('./lefQC.htm','w')
    print('\033[1m' + '\t\t\t\t\tBuiling dashboad...')

    print('-I- Loading current lef utils and shared lib module')
    log.write('\n-I- Loading current lef utils and shared lib module\n')

    for files in filenames:
        macro_name = files.strip()
        if macro_name.startswith("#"):
            continue
        check_list[macro_name]['LEF'] = {}
        check_list[macro_name]['LVG'] = {}
        check_list[macro_name]['LVV'] = {}
        check_list[macro_name]['LVL'] = {}
        check_list[macro_name]['PC'] = {}
        check_list[macro_name]['EF'] = {}

        if user == 0:
            dirname = dropdir + "/" + macro_name + "/" + rel + "/..."
            macroDir = user_dropdir + "/" + macro_name + "/" + rel + "/" + "macro/"
            if os.path.isdir(macroDir) is False:
                subprocess.Popen(['p4','sync',dirname],stdout=subprocess.PIPE).communicate()

        elif user == 1:
            macroDir = dropdir + "/" + macro_name + "/" + rel + "/" + "macro/"
        lefFile = macroDir + "lef/" + metal + "/" + macro_name + ".lef"
        print(Fore.GREEN + "\n-I- Creating directory{}\n".format(macro_name))
        log.write("\n-I- Creating directory{}\n".format(macro_name))
        os.mkdir(macro_name)

        print(Fore.GREEN + "-I- Running lefQC  with msip_lefVerify check...")
        check_list = LefQC(check_list,macro_name,macroDir,lefFile,metal)
        log.write("\n-I- Running lefQC  with msip_lefVerify check...")

        print(Fore.GREEN + "-I- Running lefvsGds  with msip_lefVsGds check...")
        check_list = lefVsGds(macro_name,check_list,macroDir,lefFile,metal)
        log.write("\n-I- Running lefvsGds  with msip_lefVsGds check...")

        print(Fore.GREEN + "-I- Running lefvsVerilog  with msip_lefVsVerilog check...")
        check_list = lefVsVerilog(macro_name,check_list,macroDir,lefFile)
        log.write("\n-I- Running lefvsVerilog  with msip_lefVsVerilog check...")

        print(Fore.GREEN + "-I- Running lefVsLib with msip_lefVsLib check...")
        check_list = lefVsLib(macro_name,check_list,macroDir,lefFile,metal)
        log.write("\n-I- Running lefVsLib with msip_lefVsLib check...")

        print(Fore.GREEN + "-I- Checking pincheck file...")
        check_list = pinChek(macro_name,check_list,macroDir)
        log.write("\n-I- Checking pincheck file...")

        print(Fore.GREEN + "-I- Checking empty files...")
        check_list = emptyFiles(macro_name,check_list,macroDir)
        log.write("\n-I- Checking empty files...")

    html.write(html_builder(macro_name,check_list))
    html.close()
    print('\033[1m' + '-I-\t\t\t\t\tDashboard Created,Opening in browser\n')
    os.system("firefox lefQC.htm &")
    print("\n")
    log.close()
    sys.stdout.flush()
    os.chdir("../")


def LefQC(check_list,macro,dirpath,lefFile,metal):    # noqa C901
    content = {}
    check_list[macro]['LEF']['BLOCK'] = "Failed"
    check_list[macro]['LEF']['ORIGIN'] = "Failed"
    check_list[macro]['LEF']['SIZE'] = "Failed"
    check_list[macro]['LEF']['SYMMETRY'] = "Failed"
    check_list[macro]['LEF']['PIN TYPE'] = "Failed"
    check_list[macro]['LEF']['PIN DIRECTION'] = "Failed"

    if os.path.isfile(lefFile) is False:
        check_list[macro]['LEF']['BLOCK'] = "Lef file not found"
        check_list[macro]['LEF']['ORIGIN'] = "Lef file not found"
        check_list[macro]['LEF']['SIZE'] = "Lef file not found"
        check_list[macro]['LEF']['SYMMETRY'] = "Lef file not found"
        check_list[macro]['LEF']['PIN TYPE'] = "Lef file not found"
        check_list[macro]['LEF']['PIN DIRECTION'] = "Lef file not found"

        return(check_list)

    os.chdir(macro)
    op = subprocess.Popen(['msip_lefVerify',lefFile],stdout=subprocess.PIPE,stderr=subprocess.PIPE).communicate()[0].decode('utf-8')
    if re.search(r'^Error',op[0],re.IGNORECASE):
        check_list[macro]['LEF']['BLOCK'] = "msip_lefVerify exited with error"
        check_list[macro]['LEF']['ORIGIN'] = "msip_lefVerify exited with error"
        check_list[macro]['LEF']['SIZE'] = "msip_lefVerify exited with error"
        check_list[macro]['LEF']['SYMMETRY'] = "msip_lefVerify exited with error"
        check_list[macro]['LEF']['PIN TYPE'] = "msip_lefVerify exited with error"
        check_list[macro]['LEF']['PIN DIRECTION'] = "msip_lefVerify exited with error"
        os.chdir("../")
        return(check_list)

    verif = collections.defaultdict(dict)
    vF = open("msip_lefVerify.log",'r')
    for lline in vF.readlines():
        if re.search(r'.*\?',lline):
            q = re.split(r'\?\.+\s+',lline)[0].strip()
            verif[q] = re.split(r'\?\.+\s+',lline)[-1].strip()
        elif re.search(r'^Detected.*:',lline):
            q = re.split(r':\s+',lline)[0].strip()
            verif[q] = re.split(r':\s+',lline)[-1].strip()

    vF.close()
    with open(lefFile,'r') as f:
        copy = False
        for line in f:
            line = line.strip()
            if line != '':
                if line.lower().startswith('pin'):
                    copy = True
                    pin_name = re.match(r'pin\s+(.+)',line,re.IGNORECASE).group(1)
                    content[pin_name] = []
                elif line.lower().startswith('end'):
                    copy = False

                if copy:
                    content[pin_name].append(line)

                if line.lower().startswith('class'):
                    class_name = re.match(r'class\s+(.+)\s?;',line,re.IGNORECASE).group(1).strip()
                    if class_name != 'BLOCK' or verif['Is MACRO CLASS defined as BLOCK'] != 'YES.':
                        check_list[macro]['LEF']['BLOCK'] = "Failed"
                    else:
                        check_list[macro]['LEF']['BLOCK'] = "Passed"

                if line.lower().startswith('origin'):
                    class_name = re.match(r'origin\s+(.+)\s?;',line,re.IGNORECASE).group(1).strip()
                    if class_name != '0 0' or verif['Detected Macro Origin'] != '0 0':
                        check_list[macro]['LEF']['ORIGIN'] = "Failed"
                    else:
                        check_list[macro]['LEF']['ORIGIN'] = "Passed"

                if line.lower().startswith('symmetry'):
                    class_name = re.match(r'symmetry\s+(.+)\s?;',line,re.IGNORECASE).group(1).strip()
                    if class_name != 'X Y':
                        check_list[macro]['LEF']['SYMMETRY'] = "Failed"
                    else:
                        check_list[macro]['LEF']['SYMMETRY'] = "Passed"

                if line.lower().startswith('size'):
                    class_name = re.match(r'size\s+(.+)\s?;',line,re.IGNORECASE).group(1).strip()
                    check_list[macro]['LEF']['SIZE'] = class_name
    pwr_pin = ['VDD','VDDQ','VAA','VSS']
    pwr_sig = ['POWER','GROUND','SIGNAL']
    direct = ['INPUT','OUTPUT','INOUT']
    check_list[macro]['LEF']['PIN TYPE'] = "Passed"
    check_list[macro]['LEF']['PIN DIRECTION'] = "Passed"
    for pin in content.keys():
        for con in content[pin]:
            if con.lower().startswith('direction'):
                if re.match(r'DIRECTION\s+(.+)\s?;',con,re.IGNORECASE).group(1).strip() not in direct and pin in pwr_pin:
                    check_list[macro]['LEF']['PIN DIRECTION'] = "Failed"
                elif re.match(r'DIRECTION\s+(.+)\s?;',con,re.IGNORECASE).group(1).strip() not in direct:
                    check_list[macro]['LEF']['PIN DIRECTION'] = "Failed"
            elif con.lower().startswith('use'):
                sig = re.match(r'USE\s+(.+)\s?;',con,re.IGNORECASE).group(1).strip()

                if sig in pwr_sig:
                    if pin in ['VDD','VDDQ','VAA'] and sig != "POWER":
                        check_list[macro]['LEF']['PIN TYPE'] = "Failed"
                    elif pin == 'VSS' and sig != "GROUND":
                        check_list[macro]['LEF']['PIN TYPE'] = "Failed"
                elif sig not in pwr_sig:
                    check_list[macro]['LEF']['PIN TYPE'] = "Failed"
    os.chdir("../")
    return(check_list)


def lefVsGds(macro,gds,dirpath,lefFile,metal):
    check = 0
    filename = dirpath + "gds/" + metal + "/" + macro + ".gds.gz"
    gds[macro]['LVG']['LVG OBS'] = "Failed"
    gds[macro]['LVG']['PinVsMetal'] = "Failed"
    gds[macro]['LVG']['PinVsPin'] = "Failed"

    if os.path.isfile(lefFile) is False:
        gds[macro]['LVG']['LVG OBS'] = "Lef file not found"
        gds[macro]['LVG']['PinVsMetal'] = "Lef file not found"
        gds[macro]['LVG']['PinVsPin'] = "Lef file not found"
        return(gds)
    elif os.path.isfile(filename) is False:
        gds[macro]['LVG']['LVG OBS'] = "Gds file not found"
        gds[macro]['LVG']['PinVsMetal'] = "Gds file not found"
        gds[macro]['LVG']['PinVsPin'] = "Gds file not found"
        return(gds)

    os.chdir(macro)

    foundary = dirpath.split('/')[-7].split('-')
    foundary = '-'.join(foundary[2:])
    map_file = "/remote/cad-rep/msip/ude_conf/lef_vs_gds/" + foundary + "/msip_lefVsGds.map"
    if os.path.isfile(map_file) is False:
        match = match = re.search(r'(\w+?\d+\w+?)(\d+)',foundary)
        foundary = match.group(1) + "-" + match.group(2)
        map_file = "/remote/cad-rep/msip/ude_conf/lef_vs_gds/" + foundary + "/msip_lefVsGds.map"
    op = subprocess.Popen(['msip_lefVsGds',filename,lefFile,map_file, "-checkOBS", "-duppins", "-maskExplode","-extractlayers"],stdout=subprocess.PIPE,stderr=subprocess.PIPE).communicate()[0].decode('utf-8')

    if re.search(r'^Error',op[0],re.IGNORECASE):
        gds[macro]['LVG']['LVG OBS'] = "msip_lefVsGds exited with error"
        gds[macro]['LVG']['PinVsMetal'] = "msip_lefVsGds exited with error"
        gds[macro]['LVG']['PinVsPin'] = "msip_lefVsGds exited with error"
        os.chdir("../")
        return(gds)
    (gds, check) = checkGdsLog(gds, macro)
    check = 0
    if os.path.isfile('./{0}/{0}.uef'.format(macro)) is False:
        gds[macro]['LVG']['PinVsPin'] = "Failed"
    else:
        with open('./{0}/{0}.uef'.format(macro),'r') as ff:
            for lline in ff:
                lline = lline.strip()
                if lline != '':
                    if re.search(r'ERR Violations.*',lline,re.IGNORECASE):
                        check = 1
                        gds[macro]['LVG']['PinVsPin'] = "Failed"
                        break
    if check == 0:
        gds[macro]['LVG']['PinVsPin'] = "Passed"
    os.chdir("../")
    return(gds)


def checkGdsLog(gds, macro):
    with open('./msip_lefVsGds.log','r') as f:
        for line in f:
            line = line.strip()
            if line != '':
                if re.search(r'LVG OBS Check Failed!',line,re.IGNORECASE):
                    check = 1
                    gds[macro]['LVG']['LVG OBS'] = "Failed"
                elif re.search(r'LVG OBS Check Succeed!',line,re.IGNORECASE):
                    gds[macro]['LVG']['LVG OBS'] = "Passed"

                elif re.search(r'LVG pinVSmetal Check Failed!',line,re.IGNORECASE):
                    check = 1
                    gds[macro]['LVG']['PinVsMetal'] = "Failed"
                elif re.search(r'LVG pinVSmetal Check Succeed!',line,re.IGNORECASE):
                    gds[macro]['LVG']['PinVsMetal'] = "Passed"
    return(gds, check)


def lefVsVerilog(macro,cl,dirpath,lefFile):
    check = 0
    filename1 = dirpath + "interface/" + macro + "_interface.v"
    filename2 = dirpath + "behavior/" + macro + ".v"
    cl[macro]['LVV']['INTERFACE'] = "Failed"
    cl[macro]['LVV']['BEHAVIOR'] = "Failed"

    if os.path.isfile(lefFile) is False:
        cl[macro]['LVV']['INTERFACE'] = "Lef file not found"
        cl[macro]['LVV']['BEHAVIOR'] = "Lef file not found"
        check = 1
        return(cl)
    elif os.path.isfile(filename1) is False:
        cl[macro]['LVV']['INTERFACE'] = "Verilog file not found"
        check = 1
    elif os.path.isfile(filename2) is False:
        cl[macro]['LVV']['BEHAVIOR'] = "Verilog file not found"
        check = 1
    if check:
        return(cl)

    os.chdir(macro)

    if os.path.isfile(filename1) is False:
        cl[macro]['LVV']['INTERFACE'] = "Interface Verilog file not found"
        check = 1
    else:
        op = subprocess.Popen(['msip_lefVsVerilog',lefFile,filename1],stdout=subprocess.PIPE,stderr=subprocess.PIPE).communicate()[0].decode('utf-8')
        if len(op) > 0 and re.search(r'^Error',op[0],re.IGNORECASE):
            cl[macro]['LVV']['INTERFACE'] = "msip_lefVsverilog exited with error"
            os.chdir("../")
            return(cl)

        subprocess.Popen(['mv','msip_lefVsVerilog.log','msip_lefVsVerilog_interface.log']).communicate()
        fl = os.getcwd()
        fl += "/msip_lefVsVerilog_interface.log"
        cl[macro]['LVV']['INTERFACE'] = "Passed"
        cl[macro]['LVV']['BEHAVIOR'] = "Passed"
        (cl, check) = checkVerilogLog(cl, macro, 'INTERFACE')

    if os.path.isfile(filename2) is False:
        cl[macro]['LVV']['BEHAVIOR'] = "Verilog file not found"
        check = 1
    else:
        op = subprocess.Popen(['msip_lefVsVerilog',lefFile,filename2],stdout=subprocess.PIPE,stderr=subprocess.PIPE).communicate()[0].decode('utf-8')
        if len(op) > 0 and re.search(r'^Error',op[0],re.IGNORECASE):
            cl[macro]['LVV']['BEHAVIOR'] = "msip_lefVsverilog exited with error"
            os.chdir("../")
            return(cl)
        subprocess.Popen(['mv','msip_lefVsVerilog.log','msip_lefVsVerilog_behavior.log']).communicate()
        (cl, check) = checkVerilogLog(cl, macro, 'BEHAVIOR')

    os.chdir("../")
    return(cl)


def checkVerilogLog(cl, macro, typeC):
    with open('msip_lefVsVerilog_interface.log','r') as f:
        for line in f:
            line = line.strip()
            if line != '' and re.split(r'\s+',line)[-1] == 'WRONG':
                check = 1
                cl[macro]['LVV'][typeC] = "Failed"
        return(cl, check)


def lefVsLib(macro,cl,dirpath,lefFile,metal):
    check = 0
    filepath = dirpath + "timing/" + metal + "/lib_pg_lvf/"
    cl[macro]['LVL']['Pin Clean/Dirty'] = "Failed"
    cl[macro]['LVL']['Area'] = "Failed"

    for filename in glob.glob('{}/*.lib*'.format(filepath)):
        if filename.endswith(r'\.gz'):
            subprocess.Popen(['gunzip',filename],stdout=subprocess.PIPE,stderr=subprocess.PIPE).communicate()[0].decode('utf-8')
            filename = re.sub(r'gz','',filename)
            break
        else:
            filename = filename
            break
    print(filename)
    if os.path.isfile(lefFile) is False:
        cl[macro]['LVL']['Pin Clean/Dirty'] = "Lef file not found"
        cl[macro]['LVL']['Area'] = "Lef file not found"
        return(cl)
    elif os.path.isfile(filename) is False:
        cl[macro]['LVL']['Pin Clean/Dirty'] = "Lib file not found"
        cl[macro]['LVL']['Area'] = "Lib file not found"
        return(cl)

    os.chdir(macro)

    op = subprocess.Popen(['msip_lefVsLib',lefFile,filename],stdout=subprocess.PIPE,stderr=subprocess.PIPE).communicate()[0].decode('utf-8')

    if len(op) > 0 and (re.search(r'^Error',op[0],re.IGNORECASE) or re.search(r"^Can't",op[1],re.IGNORECASE)):
        cl[macro]['LVL']['Pin Clean/Dirty'] = "msip_lefVsLib exited with error"
        cl[macro]['LVL']['Area'] = "msip_lefVsLib exited with error"
        os.chdir("../")
        return(cl)
    (cl, check) = checkLibLog(cl, macro)

    os.chdir("../")
    return(cl)


def getAreaPinInfo(content):
    content_pin = []
    content_area = []
    copy = False
    for line in content:
        line = line.strip()
        if line != '' and re.search(r'Comparing LEF and Lib pins',line):
            copy = True
        elif copy:
            content_pin .append(line)
        elif re.search(r'^#+',line):
            copy = False
    copy = False
    for line in content:
        line = line.strip()
        if line != '' and re.search(r'Comparing Lib and LEF cell areas',line):
            copy = True
            content_area.append(line)
        elif copy:
            content_area.append(line)
        elif re.search(r'msip_lefVsLib finished',line):
            copy = False
    return(content_pin, content_area)


def checkLibLog(cl, macro):
    f = open('./msip_lefVsLib.log','r')
    content = f.readlines()
    content_pin = []
    content_area = []
    (content_pin, content_area) = getAreaPinInfo(content)

    for line in content_pin:
        line = line.strip()
        if line != '' and re.split(r'\s+',line)[-1] == 'WRONG':
            check = 1
            cl[macro]['LVL']['Pin Clean/Dirty'] = "Failed"
            break
    if check == 0:
        cl[macro]['LVL']['Pin Clean/Dirty'] = "Passed"

    check = 0

    for line in content_area:
        if re.search(r'{0}:\d+.\d+\s+{0}:\d+.\d+\s+\w+.'.format(macro),line):
            match = re.search(r'{0}:(\d+.\d+)\s+{0}:(\d+.\d+)\s+(\w+)'.format(macro),line)
            if match.group(3) == "WRONG":
                check = 1
                cl[macro]['LVL']['Area'] = "Failed"
                break
    if check == 0:
        cl[macro]['LVL']['Area'] = "Passed"
    return(cl, check)


def pinChek(macro,cl,dirpath):
    check = 0
    filename = dirpath + macro + '.pincheck'
    if os.path.isfile(filename) is False:
        cl[macro]['PC']['CLEAN/DIRTY'] = "Pincheck file not found"
        return(cl)
    with open(filename,'r') as f:
        for line in f:
            line = line.strip()
            if line != '' and re.search('dirty',line,re.IGNORECASE):
                check = 1
                cl[macro]['PC']['CLEAN/DIRTY'] = "Failed"
    if check == 0:
        cl[macro]['PC']['CLEAN/DIRTY'] = "Passed"
    return(cl)


def emptyFiles(macro,cl,dirpath):
    check = 0
    count = 0

    try:
        for path, subdirs, files in os.walk(dirpath):
            for name in files:
                filepath = os.path.join(path, name)
                if os.stat(filepath).st_size == 0 and os.path.islink(filepath) is False:
                    check = 1
                    count += 1
                    cl[macro]['EF']['COUNT'] = count
                else:
                    check = 0
    except OSError:
        cl[macro]['EF']['COUNT'] = "Failed"
    if check == 0 and count == 0:
        cl[macro]['EF']['COUNT'] = "Clean"
    return(cl)


def html_builder(macro,cl):
    html_str = '<table border="1" class="dataframe" style="background-color:#F5F5DC;">'
    html_str += '<tr><th>Macro Name</th><th colspan="6">LEF Status</th><th colspan="3">LefVsGds</th><th colspan="2">LefVsVerilog</th><th colspan="2">LefVsLib</th><th colspan="1">PinCheck</th><th colspan="1">Empty Files</th></tr>'

    html_str += '<tr><th> </th>'

    html_str += ''.join(['<th>{}</th>'.format(x) for x in cl[macro]['LEF'].keys()])
    html_str += ''.join(['<th>{}</th>'.format(x) for x in cl[macro]['LVG'].keys()])
    html_str += ''.join(['<th>{}</th>'.format(x) for x in cl[macro]['LVV'].keys()])
    html_str += ''.join(['<th>{}</th>'.format(x) for x in cl[macro]['LVL'].keys()])
    html_str += ''.join(['<th>{}</th>'.format(x) for x in cl[macro]['PC'].keys()])
    html_str += ''.join(['<th>{}</th>'.format(x) for x in cl[macro]['EF'].keys()])
    html_str += '</tr>'

    for m in cl.keys():

        html_str += '<tr><th>{}</th>'.format(m)

        html_str += ''.join(['<th style="color:red">{}</th>'.format(x) if x == "Failed" else '<th>{}</th>'.format(x) for x in cl[m]['LEF'].values()])
        html_str += ''.join(['<th style="color:red">{}</th>'.format(x) if x == "Failed" else '<th>{}</th>'.format(x)for x in cl[m]['LVG'].values()])
        html_str += ''.join(['<th style="color:red">{}</th>'.format(x) if x == "Failed" else '<th>{}</th>'.format(x)for x in cl[m]['LVV'].values()])
        html_str += ''.join(['<th style="color:red">{}</th>'.format(x) if x == "Failed" else '<th>{}</th>'.format(x)for x in cl[m]['LVL'].values()])
        html_str += ''.join(['<th style="color:red">{}</th>'.format(x) if x == "Failed" else '<th>{}</th>'.format(x)for x in cl[m]['PC'].values()])
        html_str += ''.join(['<th style="color:red">{}</th>'.format(x) if x == "Failed" else '<th>{}</th>'.format(x)for x in cl[m]['EF'].values()])
        html_str += '</tr>'

    return(html_str)


if __name__ == "__main__":
    main()
