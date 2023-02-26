#!/depot/Python/Python-3.8.0/bin/python -BE
# Developed by Dikshant Rohatgi(dikshant@synopsys.com)
# The script is used to extract gate oxide values of the devices mentioned in chkdevop file from .SPF file
import glob
import re
import pathlib
import sys

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


def extract(spf_file,chk_file):
    fd1 = open(chk_file,'r')
    devices = []

    print("Info: Reading {} ".format(chk_file))
    for line in fd1.readlines():
        if not (re.search(r'^\*',line)):
            device_name = line.split()[0]
            z = re.search(r'^xp\.(.*)\.main$',device_name)
            if(z):
                device_name = z.groups()[0]
            devices.append(device_name)

    temp_set = set(devices)
    devices = list(temp_set)

    try:
        print("Info: Reading {} ".format(spf_file))
        fd2 = open(spf_file,'rt')
        content = fd2.readlines()
    except FileNotFoundError:
        print("Could Open {}. Please Check your File".format(spf_file))
        exit()

    num1 = 0
    num2 = 0

    main = []

    for num,con in enumerate(content):
        if re.search(r'^\*\s+Instance Section',con):
            num1 = num
        elif re.search(r'\.ENDS',con):
            num2 = num
            break
        else:
            continue

    fo = open("Device_Info.csv",'w+')
    print("Info: Generating Device_Info.csv")
    fo.write("Extracted Device info from {} and {}\n\n".format(spf_file,chk_file))
    fo.write("Device Name,fet,cpp,fpitch,l,m,nf,nfin\n")
    main = createData(devices,num1,num2,content)
    del content
    del devices
    dumpData(main,fo)
    del main
    fd1.close()
    fd2.close()


def createData(devices,num1,num2,content):
    for d in devices:
        for i in range(num1,num2):
            if re.search(r'^\*',content[i]):
                continue
            elif re.match(d,content[i],re.I):
                z = re.match(r'.*SRC(.*nfin=\d+).*',content[i])
                if(z):
                    main.append(z.groups()[0])
    return(main)


def dumpData(main,fo):
    for m in main:
        t = m.split()
        for con in t:
            if re.search("=",con):
                r = con.split("=")[-1]
                fo.write(r)
                fo.write(",")
            else:
                fo.write(con)
                fo.write(",")
        fo.write("\n")
    fo.close()


def main():
    chk_file = glob.glob("*.chkdevop_0")[0]

    try:
        spf_file = glob.glob("./include/*.spf")[0]
    except IndexError:
        print("Error: Couldn't find .spf file inside include folder,Exiting")
        exit()

    try:
        chk_file = glob.glob("*.chkdevop_0")[0]
    except IndexError:
        print("Error: Couldn't find .chkdevop_0 file, Exiting")
        exit()

    extract(spf_file,chk_file)
    print("Run Complete, Please Check Device_Info.csv")


if __name__ == '__main__':
    main()
