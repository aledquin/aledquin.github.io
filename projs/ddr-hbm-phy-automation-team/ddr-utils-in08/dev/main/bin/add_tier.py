#!/depot/Python/Python-3.8.0/bin/python -E

import os
import re
import sys
import getopt
import subprocess
import collections
import pathlib

# ----------------------------------#
bindir = str(pathlib.Path(__file__).resolve().parent)
sys.path.append(bindir + '/../lib/python/Util')
sys.path.append(bindir + '/../lib/python')
# ----------------------------------#
from Misc import utils__script_usage_statistics, get_release_version
__version__ = get_release_version(bindir)

utils__script_usage_statistics(__file__, __version__)


argv = sys.argv[1:]
src_path = ""
trg_path = ""
try:
    opts, args = getopt.getopt(argv,"ht:s:",["src=","s="])
except getopt.GetoptError:
    print('devicelen.py -e <exclude File> -s <sp file>')
    sys.exit(2)
for opt, arg in opts:
    if opt == '-h':
        print(' add_tier -s|--src <source path> -t|--target <target path>')
        sys.exit()
    elif opt in ("-s", "--src"):
        src_path = arg
    elif opt in ("-t", "--target"):
        trg_path = arg


def main():
    srcFiles = subprocess.Popen(['p4','files','-e','{}...'.format(src_path)],stdout=subprocess.PIPE,stderr=subprocess.PIPE,universal_newlines=True).communicate()
    srcFiles = srcFiles[0].split('\n')
    srcFiles = list(filter(lambda x:re.search('/bbSim/',x),srcFiles))
    srcFiles = list(filter(lambda x:re.search(r'\.bbSim',x),srcFiles))
    srcproj = src_path.split('/')[-5]

    dstFiles = subprocess.Popen(['p4','files','-e','{}...'.format(trg_path)],stdout=subprocess.PIPE,stderr=subprocess.PIPE,universal_newlines=True).communicate()
    dstFiles = dstFiles[0].split('\n')
    dstFiles = list(filter(lambda x:re.search('/bbSim/',x),dstFiles))
    dstFiles = list(filter(lambda x:re.search(r'\.bbSim',x),dstFiles))
    dstproj = trg_path.split('/')[-5]

    dstFiles = [re.sub(r'#.*','',i) for i in dstFiles]
    srcFiles = [re.sub(r'#.*','',i) for i in srcFiles]

    tier_dict = collections.defaultdict(dict)

    for src in srcFiles:
        filename = src.split('/')[-1]
        param = subprocess.Popen(['p4','grep','-e','TIER|tier',src],stdout=subprocess.PIPE,stderr=subprocess.PIPE).communicate()
        if param != '':
            match = re.match(r'.*:.*TIER\W+(.*)',param[0].decode('utf-8'),re.I)
            if match:
                tier_dict[filename] = match.group(1)
            else:
                tier_dict[filename] = "None"
    log = open('add_tier.log','w')
    csv = open('missing_tbs.csv','w')

    for dst in dstFiles:
        filename = dst.split('/')[-1]
        paramm = subprocess.Popen(['p4','grep','-e','TIER|tier',dst],stdout=subprocess.PIPE,stderr=subprocess.PIPE).communicate()[0].decode('utf-8')
        if re.match(r'.*TIER.*',paramm,re.I):
            continue
        localpath = subprocess.Popen(['p4','sync','-f',dst],stdout=subprocess.PIPE,stderr=subprocess.PIPE).communicate()[0].decode('utf-8')
        localpath = re.search(r'.*added as|refreshing\s+(.*)',localpath).group(1)
#        op = subprocess.Popen(['p4','where',dst],stdout=subprocess.PIPE,stderr=subprocess.PIPE,universal_newlines=True).communicate()
#        localpath = op[0].split(' ')[-1].strip()
        subprocess.call(['chmod','+w',localpath])
        f = open(localpath, "r")
        contents = f.readlines()
        if filename in tier_dict.keys() and tier_dict[filename] != 'None' and len(tier_dict[filename]) != 0:
            print(tier_dict[filename],filename)
            contents.insert(2,"TIER\t\t\t\t{}\n".format(tier_dict[filename]))
            with open(localpath, "w") as f:
                contents = "".join(contents)
                f.write(contents)
            log.write('Updated {}\n'.format(localpath))
    log.close()

    srcFiles = [x.split('/')[-3] + "/" + os.path.basename(x) for x in srcFiles]
    dstFiles = [x.split('/')[-3] + "/" + os.path.basename(x) for x in dstFiles]
    op_list = set(srcFiles) - set(dstFiles)
    for o in op_list:
        csv.write('{},present in {},absent in {}\n'.format(o,srcproj,dstproj))
    op_list = set(dstFiles) - set(srcFiles)
    csv.write('\n')
    for o in op_list:
        csv.write('{},present in {},absent in {}\n'.format(o,dstproj,srcproj))

    csv.close()


if __name__ == "__main__":
    main()
