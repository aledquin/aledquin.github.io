#!/depot/Python/Python-3.8.0/bin/python -E
# Gives cumulative width and length of devices in .cdl files (Tweaked for different device name)
# nolint main
import os
import subprocess
import collections
import re
import sys
import xlsxwriter
import pathlib
all_netlists = []

# ----------------------------------#
bindir = str(pathlib.Path(__file__).resolve().parent)
sys.path.append(bindir + '/../lib/python/Util')
sys.path.append(bindir + '/../lib/python')
# ----------------------------------#
from Misc import utils__script_usage_statistics, get_release_version
__version__ = get_release_version(bindir)

utils__script_usage_statistics(__file__, __version__)


def percentage(part, whole):
    return round((100 * float(part) / float(whole)), 1)


print("Running .cdl file search ...")

for path, subdirs, files in os.walk(os.getcwd()):
    for name in files:
        filename = os.path.join(path, name)
        if os.path.basename(filename).endswith('.cdl'):
            all_netlists.append(filename)

print(".cdl file search complete.\n")
print('Found files:')
for net in all_netlists:
    print(net)
print('\n')

final_count = {}

if not all_netlists:    # noqa C901
    print('No *.cdl* files found in {} and its subdirectories. Exiting ...\n'.format(str(os.getcwd())))
    sys.exit()
else:
    # with open('output.txt', 'w+') as file:
    #     file.write('Script Output\n\n\n')
    for files in all_netlists:
        data = []
        device_list = []
        transistor_count = collections.defaultdict(dict)
        with open(files, 'r') as f:
            copy = False
            for line in f:
                line = line.strip()
                line = line.lower()
                if line != '':
                    if line.lower().startswith('.subckt'):
                        copy = True
                    elif line.lower().startswith('.ends'):
                        data.append(line)
                        copy = False

                    if copy:
                        if line.lower().startswith('*'):
                            continue
                        elif line.startswith('+'):
                            data.append(data.pop() + line.replace('+', ''))
                        else:
                            data.append(line)
            subckt_check = False
            for line in data:

                if line.lower().startswith('.subckt'):
                    subckt_check = True
                    if not data[data.index(line) + 1].lower().startswith('.ends'):
                        device_list.append(line.split()[1])
                        continue
                elif line.lower().startswith('.ends'):
                    subckt_check = False
                    continue
                elif subckt_check:
                    if any(x in line.split() for x in device_list):
                        # instance
                        # pass
                        found_element = next(element for element in line.split() if element in device_list)
                        if "m=" in line:
                            m = int(re.search(".*m=([a-z0-9-_.+]+).*", line, re.IGNORECASE).group(1))
                            for key in transistor_count[found_element].keys():
                                if key not in transistor_count[device_list[-1]].keys():
                                    transistor_count[device_list[-1]][key] = transistor_count[found_element][key] * m
                                else:
                                    transistor_count[device_list[-1]][key] += transistor_count[found_element][key] * m
                        else:
                            for key in transistor_count[found_element].keys():
                                if key not in transistor_count[device_list[-1]].keys():
                                    transistor_count[device_list[-1]][key] = transistor_count[found_element][key]
                                else:
                                    transistor_count[device_list[-1]][key] += transistor_count[found_element][key]
                    else:
                        # device
                        devlist = ['p_1p8ud1p5', 'n_1p8ud1p5', 'n_svt', 'p_svt', 'n_lvt', 'p_lvt', 'n_1p8', 'rhr_sckt']
                        if any(x in line.split() for x in devlist) and 'l=' in line and 'w=' in line and 'm=' in line:
                            device = next(element for element in line.split() if element in devlist)
                            le = re.search(".*l=([a-z0-9-_.+]+).*", line, re.IGNORECASE).group(1)
                            nfin = re.search(".*w=([a-z0-9-_.+]+).*", line, re.IGNORECASE).group(1)
                            # nf = re.search(".*nf=([a-z0-9-_.+]+).*", line, re.IGNORECASE).group(1)
                            m = re.search(".*m=([a-z0-9-_.+]+).*", line, re.IGNORECASE).group(1)
                            if m[-1] == 'k':
                                m = int(float(m[0:-1]) * 1000)

                            typ = '{}/{}/{}' .format(device, le, nfin)

                            # if 'dum' in line.lower().split()[0] or 'dmy' in line.lower().split()[0]:
                            #     typ = 'dum_{}/{}/{}'.format(device, l, nfin)
                            # else:
                            #     typ = '{}/{}/{}'.format(device, l, nfin)

                            if typ not in transistor_count[device_list[-1]].keys():
                                transistor_count[device_list[-1]][typ] = 1 * int(m)
                            else:
                                transistor_count[device_list[-1]][typ] += 1 * int(m)

                        # elif '_mac ' in line and 'l=' in line and 'nfin=' in line and 'm=' in line and "nf=" not in line:
                        #     device = re.search("([a-z0-9-_.+]+_mac )", line, re.IGNORECASE).group(1).strip()
                        #     l = re.search(".*l=([a-z0-9-_.+]+).*", line, re.IGNORECASE).group(1)
                        #     nfin = re.search(".*nfin=([a-z0-9-_.+]+).*", line, re.IGNORECASE).group(1)
                        #     m = re.search(".*m=([a-z0-9-_.+]+).*", line, re.IGNORECASE).group(1)
                        #     if m[-1] == 'k':
                        #         m = int(float(m[0:-1]) * 1000)
                        #
                        #     typ = '{}/{}/{}' .format(device, l, nfin)
                        #
                        #     # if 'dum' in line.lower().split()[0] or 'dmy' in line.lower().split()[0]:
                        #     #     typ = 'dum_{}/{}/{}'.format(device, l, nfin)
                        #     # else:
                        #     #     typ = '{}/{}/{}'.format(device, l, nfin)
                        #
                        #     if typ not in transistor_count[device_list[-1]].keys():
                        #         transistor_count[device_list[-1]][typ] = 1 * int(m)
                        #     else:
                        #         transistor_count[device_list[-1]][typ] += 1 * int(m)

                        elif ' ncap_1p8_sckt ' in line and 'lf=' in line and 'wf=' in line and 'm=' in line:
                            # print('in')
                            device = 'ncap_1p8_sckt'
                            # device = re.search("([a-z0-9-_.+]+cap_18 )", line, re.IGNORECASE).group(1).strip()
                            lr = re.search(".*lf=([a-z0-9-_.+]+).*", line, re.IGNORECASE).group(1)
                            nfin = re.search(".*wf=([a-z0-9-_.+]+).*", line, re.IGNORECASE).group(1)
                            m = re.search(".*m=([a-z0-9-_.+]+).*", line, re.IGNORECASE).group(1)
                            if m[-1] == 'k':
                                m = int(float(m[0:-1]) * 1000)
                            # print int(m)
                            typ = '{}/{}/{}'.format(device, lr, nfin)

                            # if 'dum' in line.lower().split()[0] or 'dmy' in line.lower().split()[0]:
                            #     typ = 'dum_{}/{}/{}'.format(device, lr, nfin)
                            # else:
                            #     typ = '{}/{}/{}'.format(device, lr, nfin)

                            if typ not in transistor_count[device_list[-1]].keys():
                                transistor_count[device_list[-1]][typ] = 1 * int(m)
                            else:
                                transistor_count[device_list[-1]][typ] += 1 * int(m)

        # print(files)

        # for tran in sorted(transistor_count.keys()):
        #     print(tran, transistor_count[tran])

        # for tran in sorted(flop_count.keys()):
        #     print(tran, flop_count[device_list[-1]])
        # print(files)
        # # print(device_list)
        # # print(device_list[-1])
        # print("##################")
        # print(transistor_count[device_list[-1]])
        # print("##################")
        # print("\n")

        if format(os.path.splitext(os.path.basename(files))[0]) not in final_count.keys():
            if device_list:
                final_count[format(os.path.splitext(os.path.basename(files))[0])] = transistor_count[device_list[-1]]
        else:
            print('Transistor count Fail {}'.format(format(os.path.splitext(os.path.basename(files))[0])))


# for key in final_std_tran_count:
#     print(key, final_std_tran_count[key])

workbook = xlsxwriter.Workbook('gate_oxide_cdl.xlsx')
worksheet_summary = workbook.add_worksheet('Summary')
worksheet_detail = workbook.add_worksheet('Detail')

cell_format_border = workbook.add_format()
cell_format_border.set_border()

cell_format_border_bold = workbook.add_format()
cell_format_border_bold.set_bold()
cell_format_border_bold.set_border()

cell_format_border_gray = workbook.add_format()
cell_format_border_gray.set_border()
cell_format_border_gray.set_bold()
cell_format_border_gray.set_bg_color('silver')

bold = workbook.add_format({'bold': True})

worksheet_summary.write('A1', 'Transistor Count Summary', cell_format_border_bold)
worksheet_summary.merge_range('B1:D1', str(os.getcwd()), cell_format_border)
worksheet_summary.write('A3', 'macro', cell_format_border_gray)
worksheet_summary.write('B3', 'device', cell_format_border_gray)
worksheet_summary.write('C3', 'length', cell_format_border_gray)
worksheet_summary.write('D3', 'count', cell_format_border_gray)

worksheet_detail.write('A1', 'Transistor Count Detail', cell_format_border_bold)
worksheet_detail.merge_range('B1:E1', str(os.getcwd()), cell_format_border)
worksheet_detail.write('A3', 'macro', cell_format_border_gray)
worksheet_detail.write('B3', 'device', cell_format_border_gray)
worksheet_detail.write('C3', 'length', cell_format_border_gray)
worksheet_detail.write('D3', 'width', cell_format_border_gray)
worksheet_detail.write('E3', 'count', cell_format_border_gray)
# worksheet_detail.write('F3', 'count', cell_format_border_gray)
# worksheet_detail.write('G3', 'cumulative width (um)', cell_format_border_gray)

row_summary = 3
row_detail = 3
col = 0

# for key in sorted(final_count.keys()):
#     tcount = 0
#     # print('\n\n{}:' .format(key))
#     for innerkey in sorted(final_count[key].keys()):
#         print("{}\t{}".format(innerkey, final_count[key][innerkey]))
#         tcount += final_count[key][innerkey]
#     print ('{}:\t{}' .format(key, tcount))

for macro in sorted(final_count.keys()):
    tcount = 0
    width_sum = {}
    device_list = {}
    for inner_key in sorted(final_count[macro].keys()):
        split = inner_key.split('/')
        if split[0] not in device_list.keys():
            device_list[split[0]] = final_count[macro][inner_key]
        else:
            device_list[split[0]] += final_count[macro][inner_key]
        if tcount == 0:
            worksheet_summary.write(row_summary, col, macro, cell_format_border_gray)
            worksheet_detail.write(row_detail, col, macro, cell_format_border)
        worksheet_detail.write(row_detail, col + 1, split[0], cell_format_border)
        worksheet_detail.write(row_detail, col + 2, split[1], cell_format_border)
        worksheet_detail.write(row_detail, col + 3, split[2], cell_format_border)
        # worksheet_detail.write(row_detail, col + 4, (int(split[2])*30 - 22), cell_format_border)
        worksheet_detail.write(row_detail, col + 4, final_count[macro][inner_key], cell_format_border)
        # worksheet_detail.write(row_detail, col + 5, float(((float(split[2])*30 - 22)*float(final_count[macro][inner_key]))/1000000), cell_format_border)
        row_detail += 1
        if (split[0], split[1]) not in width_sum.keys():
            width_sum[(split[0], split[1])] = final_count[macro][inner_key]
        else:
            width_sum[(split[0], split[1])] += final_count[macro][inner_key]
        tcount += final_count[macro][inner_key]

    # worksheet_summary.write(row_summary, col + 1, 'total', cell_format_border_gray)
    # worksheet_summary.write(row_summary, col + 2, tcount, cell_format_border_gray)

    # row_summary += 1
    for sum_key in sorted(width_sum.keys(), key=lambda element: (element[0], float(''.join(filter(str.isdigit, element[1]))))):
        worksheet_summary.write(row_summary, col + 1, sum_key[0], cell_format_border)
        worksheet_summary.write(row_summary, col + 2, sum_key[1], cell_format_border)
        worksheet_summary.write(row_summary, col + 3, width_sum[sum_key], cell_format_border)
        row_summary += 1
workbook.close()

try:
    subprocess.call("libreoffice gate_oxide_cdl.xlsx &", stderr=subprocess.STDOUT, shell=True)
except subprocess.CalledProcessError as exc:
    print("Open Failed. Please close all instances of Libreoffice before running script. Return Code: {} {}".format(exc.returncode, exc.output))
    # failed_files[files] = ['No FineSim Mode']
else:
    print("Run Complete.")

# os.startfile('transistor_count_cdl.xlsx')
