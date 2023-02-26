#!/depot/Python/Python-3.8.0/bin/python -E
# Transistor count script for ideal rcc raw files
import os
import subprocess
import re
import sys
import collections
import xlsxwriter

import pathlib
# ----------------------------------#
bindir = str(pathlib.Path(__file__).resolve().parent)
sys.path.append(bindir + '/../lib/python/Util')
sys.path.append(bindir + '/../lib/python')
# ----------------------------------#
from Misc import utils__script_usage_statistics, get_release_version
__version__ = get_release_version(bindir)

utils__script_usage_statistics(__file__, __version__)


def main():    # noqa C901
    all_netlists = []
    final_count = {}
    for path, subdirs, files in os.walk(os.getcwd()):
        for name in files:
            filename = os.path.join(path, name)
            if os.path.basename(filename).endswith('.raw'):
                all_netlists.append(filename)

    print(".raw file search complete.\n")

    if not all_netlists:
        print('No *.raw* files found in {} and its subdirectories. Exiting ...\n'.format(str(os.getcwd())))
        sys.exit()
    else:
        for files in all_netlists:
            with open(files, 'r') as data:
                subckt_check = False
                for line in data:
                    if '.subckt ' in line.lower():
                        subckt_check = True
                        macro_name = line.split()[1]
                        transistor_count = collections.defaultdict(dict)
                        continue
                    elif '.ends ' in line.lower():
                        subckt_check = False
                        break
                    elif subckt_check:
                        if '_mac ' in line and 'l=' in line and 'nfin=' in line and "nf=" in line and 'pode' not in line:
                            device = re.search("([a-z0-9-_.+]+_mac )", line, re.IGNORECASE).group(1).strip()
                            le = re.search(" l=([a-z0-9-_.+]+).*", line, re.IGNORECASE).group(1)
                            nfin = re.search(".*nfin=([a-z0-9-_.+]+).*", line, re.IGNORECASE).group(1)
                            nf = re.search(".*nf=([a-z0-9-_.+]+).*", line, re.IGNORECASE).group(1)

                            typ = '{}/{}/{}'.format(device, le, nfin)
                            if typ not in transistor_count.keys():
                                transistor_count[typ] = 1 * int(nf)
                            else:
                                transistor_count[typ] += 1 * int(nf)

                        elif '_mac ' in line and 'l=' in line and 'nfin=' in line and "nf=" not in line and 'pode' not in line:
                            device = re.search("([a-z0-9-_.+]+_mac )", line, re.IGNORECASE).group(1).strip()
                            le = re.search(" l=([a-z0-9-_.+]+).*", line, re.IGNORECASE).group(1)
                            nfin = re.search(".*nfin=([a-z0-9-_.+]+).*", line, re.IGNORECASE).group(1)

                            typ = '{}/{}/{}'.format(device, le, nfin)
                            if typ not in transistor_count.keys():
                                transistor_count[typ] = 1
                            else:
                                transistor_count[typ] += 1

                        elif 'cap_18 ' in line and 'lr=' in line and 'nfin=' in line and 'pode' not in line:
                            device = re.search("([a-z0-9-_.+]+cap_18 )", line, re.IGNORECASE).group(1).strip()
                            lr = re.search(" lr=([a-z0-9-_.+]+).*", line, re.IGNORECASE).group(1)
                            nfin = re.search(".*nfin=([a-z0-9-_.+]+).*", line, re.IGNORECASE).group(1)

                            typ = '{}/{}/{}'.format(device, lr, nfin)
                            if typ not in transistor_count.keys():
                                transistor_count[typ] = 1
                            else:
                                transistor_count[typ] += 1

            if macro_name not in final_count.keys():
                final_count[macro_name] = transistor_count

    workbook = xlsxwriter.Workbook('transistor_count_raw.xlsx')
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

    worksheet_summary.write('A1', 'Transistor Count Summary', cell_format_border_bold)
    worksheet_summary.write('B1', str(os.getcwd()), cell_format_border)
    worksheet_summary.write('A3', 'macro', cell_format_border_gray)
    worksheet_summary.write('B3', 'device', cell_format_border_gray)
    worksheet_summary.write('C3', 'count', cell_format_border_gray)

    worksheet_detail.write('A1', 'Transistor Count Detail', cell_format_border_bold)
    worksheet_detail.write('B1', str(os.getcwd()), cell_format_border)
    worksheet_detail.write('A3', 'macro', cell_format_border_gray)
    worksheet_detail.write('B3', 'device', cell_format_border_gray)
    worksheet_detail.write('C3', 'length', cell_format_border_gray)
    worksheet_detail.write('D3', 'nfin', cell_format_border_gray)
    worksheet_detail.write('E3', 'count', cell_format_border_gray)

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
            worksheet_detail.write(row_detail, col + 4, final_count[macro][inner_key], cell_format_border)
            row_detail += 1
            tcount += final_count[macro][inner_key]

        worksheet_summary.write(row_summary, col + 1, 'total', cell_format_border_gray)
        worksheet_summary.write(row_summary, col + 2, tcount, cell_format_border_gray)
        row_summary += 1
        for sum_key in sorted(device_list.keys()):
            worksheet_summary.write(row_summary, col + 1, sum_key, cell_format_border)
            worksheet_summary.write(row_summary, col + 2, device_list[sum_key], cell_format_border)
            row_summary += 1

    workbook.close()

    try:
        subprocess.call("libreoffice transistor_count_raw.xlsx &", stderr=subprocess.STDOUT, shell=True)
    except subprocess.CalledProcessError as exc:
        print("Open Failed. Please close all instances of Libreoffice before running script. Return Code: {} {}".format(exc.returncode, exc.output))
        # failed_files[files] = ['No FineSim Mode']
    else:
        print("Run Complete.")


if __name__ == '__main__':
    main()
