#!/depot/Python/Python-3.8.0/bin/python -E

# Lists unnamed nets and improperly named cells in .sp netlist


import subprocess
import pathlib
import sys
# ----------------------------------#
bindir = str(pathlib.Path(__file__).resolve().parent)
sys.path.append(bindir + '/../lib/python/Util')
sys.path.append(bindir + '/../lib/python')
# ----------------------------------#
from Misc import utils__script_usage_statistics, get_release_version
__version__ = get_release_version(bindir)

utils__script_usage_statistics(__file__, __version__)


def net_check(args, day, dir):
    # net = subprocess.check_output('grep " net\|Library\|Cell" dwc_ddrphy_zcalana_tsmc7ff.sp | grep -v "net_"', shell=True)
    net = subprocess.check_output(r'grep " net0\| net1\| net2\| net3\| net4\| net5\| net6\| net7\| net8\| net9\|Library\|Cell" {} | grep -v "net_\|_net"' .format(str(args)), shell=True)
    # net = subprocess.check_output('grep " net[0:9]\|Library\|Cell" dwc_ddrphy_zcalana_tsmc7ff.sp', shell=True)
    net = net.decode('utf-8')
    # print(net)
    list_net = net.split('\n')
    list_net.pop()

    fin = []
    lib = []
    net_check_list = []

    for x in list_net:
        # net_count = 0
        list_line = x.split()
        if list_line[0] == '*':
            fin.append(list_line[-1])
        else:
            # print(list_line)

            for y in list_line:
                if 'net' in y and y not in net_check_list:
                    net_check_list.append(y)
                    a = [fin[-2], fin[-1], y]
                    # if a not in lib:
                    lib.append(a)

    # lib = set(lib)

    rep = open('net_check_{}_{}.csv'.format(str(dir), str(day)), 'a')
    rep.write('{}, , \n' .format(args))
    rep.close()

    for x in lib:
        rep = open('net_check_{}_{}.csv'.format(str(dir), str(day)), 'a')
        rep.write('{}, {}, {}\n'.format(str(x[0]), str(x[1]), str(x[2])))
        rep.close()
        # print(x)


def instance_check(args, day, dir, ign):
    net = subprocess.check_output(r'grep "xi0\|xi1\|xi2\|xi3\|xi4\|xi5\|xi6\|xi7\|xi8\|xi9\|Library\|Cell" {} | grep -v "xi_\|_xi"' .format(str(args)),shell=True)
    # net = subprocess.check_output('grep " net[0:9]\|Library\|Cell" dwc_ddrphy_zcalana_tsmc7ff.sp', shell=True)
    net = net.decode('utf-8')
    # print(net)
    list_net = net.split('\n')
    list_net.pop()

    fin = []
    lib = []
    inst_check_list = []
    # for x in list_net:
    #     print(x)
    for x in list_net:
        # net_count = 0
        list_line = x.split()
        if list_line[0] == '*':
            fin.append(list_line[-1])
        else:
            # print(list_line)
            for y in list_line:
                if 'xi' in y and list_line[2] != ign and y not in inst_check_list:
                    inst_check_list.append(y)
                    a = [fin[-2], fin[-1], list_line[-1], y]
                    # if a not in lib:
                    lib.append(a)

    # lib = set(lib)
    # print(inst_check_list)
    rep = open('instance_check_{}_{}.csv'.format(str(dir), str(day)), 'a')
    rep.write('{}, , , \n' .format(args))
    rep.close()

    for x in lib:
        rep = open('instance_check_{}_{}.csv'.format(str(dir), str(day)), 'a')
        rep.write('{}, {}, {}, {}\n'.format(str(x[0]), str(x[1]), str(x[2]), str(x[3])))
        rep.close()
        # print(x)


def main():

    date = subprocess.check_output("date +'%m%d%y' | tr -d '\n' ", shell=True)
    date = date.decode("utf-8")
    path = subprocess.check_output("pwd | tr -d '\n'", shell=True)
    path = path.decode("utf-8")
    temp_dir = path.split('/')[len(path.split('/')) - 4]
    # subprocess.call("ls -d */ | sed 's#/##'", shell=True)
    temp_mac = subprocess.check_output("ls *.sp | sed 's#/##'", shell=True)
    temp_mac = temp_mac.decode("utf-8")
    # print(type(macro_count))
    # print(path)
    # print(type(path))
    directory = temp_dir.replace('-','_')
    # print(directory)
    # print(type(directory))
    macros = temp_mac.split('\n')
    macros.pop()
    # print(temp_mac)
    # print(macros)

    ignore_lib = []
    # ignore = input('Enter Instance value to ignore: ')

    ignore = 'wire_cap'

    print('Usage:\nExecute the script in the path containing the all the netlists to be checked.\nIf no lib names are to be ignored, enter "0" in the "Enter number of library names to ignore" prompt. \n')

    while True:
        try:
            ignore_lib_num = input('Enter number of library names to ignore: ')
        except ValueError:
            print("Sorry, I didn't understand that.")
            continue
        if int(ignore_lib_num) < 0:
            print("Sorry, your response is not valid. Try again.")
            continue
        else:
            # age was successfully parsed, and we're happy with its value.
            # we're ready to exit the loop.
            break

    for x in range(int(ignore_lib_num)):
        z = input('Enter Library name/part of Library name(s) to ignore: ')
        ignore_lib.append(z)

    if ignore_lib_num == '0':
        print('No Libraries will be excluded from the check.')
    else:
        print('Following Library name/part of Library name(s) will be excluded from the check: ')
        print(*ignore_lib)

    report = open('net_check_{}_{}.csv' .format(str(directory), str(date)),'w+')
    report.write('Library, Cell, Net\n')
    report.close()

    instance = open('instance_check_{}_{}.csv' .format(str(directory), str(date)),'w+')
    instance.write('Library, Cell, Instance, Instance Name\n')
    instance.close()

    for x in macros:
        net_check(x, date, directory)

    for x in ignore_lib:
        subprocess.call("sed -i '/{}/d' net_check_{}_{}.csv".format(str(x), str(directory), str(date)), shell=True)

    for x in macros:
        instance_check(x, date, directory, ignore)


if __name__ == '__main__':
    main()
