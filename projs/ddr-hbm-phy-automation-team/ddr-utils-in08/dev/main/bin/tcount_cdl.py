#!/depot/Python/Python-3.8.0/bin/python -E
# Transistor count script for .cdl files
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


def findFiles():
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

    return(all_netlists)


def main():    # noqa C901
    all_netlists = findFiles()

    final_count = {}
    final_element_count = collections.defaultdict(dict)
    element_key = {'flop': ['_fdp', '_fsd'],
                   'latch': ['_ld', 'latch'],
                   'schmitt_trigger': ['schmitt'],
                   'power_sniffer': ['_ps'],
                   'sampler': ['sampler'],
                   'phase_detector': ['phase_detector']
                   }

    if not all_netlists:    # noqa C901
        print('No *.cdl* files found in {} and its subdirectories. Exiting ...\n'.format(str(os.getcwd())))
        sys.exit()
    else:
        # with open('output.txt', 'w+') as file:
        #     file.write('Script Output\n\n\n')
        for files in sorted(all_netlists):

            data = []
            device_list = []

            with open(files, 'r') as f:
                copy = False
                for line in f:
                    line = line.lower().strip()
                    if line != '':
                        if line.startswith('.subckt'):
                            copy = True
                        elif line.startswith('.ends'):
                            data.append(line)
                            copy = False

                        if copy:
                            if line.startswith('*'):
                                continue
                            elif line.startswith('+'):
                                data.append(data.pop() + line.replace('+', ''))
                            else:
                                data.append(line)
                subckt_check = False
                transistor_count = collections.defaultdict(dict)
                element_count = {}
                for elems in element_key:
                    element_count[elems] = collections.defaultdict(dict)
                for line in data:
                    if line.lower().startswith('.subckt'):
                        subckt_check = True
                        if not data[data.index(line) + 1].startswith('.ends'):
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
                            # print(found_element)
                            if "m=" in line or ("fingers=" in line and 'rows=' in line):
                                if "fingers=" in line and 'rows=' in line:
                                    fings = int(re.search(".*fingers=([a-z0-9-_.+]+).*", line, re.IGNORECASE).group(1))
                                    rowes = int(re.search(".*rows=([a-z0-9-_.+]+).*", line, re.IGNORECASE).group(1))
                                    m = rowes * fings
                                else:

                                    m = int(re.search(".*m=([a-z0-9-_.+]+).*", line, re.IGNORECASE).group(1))

                                for elems in element_key:
                                    if any(ele in found_element for ele in element_key[elems]):
                                        if found_element in element_count[elems][device_list[-1]].keys():
                                            element_count[elems][device_list[-1]][found_element] += 1 * m
                                            # print('hdb here', found_element, device_list[-1])
                                        else:
                                            element_count[elems][device_list[-1]][found_element] = 1 * m

                                    if any(x in line.split() for x in element_count[elems].keys()):
                                        found_std = next(element for element in line.split() if element in element_count[elems].keys())
                                        for key in element_count[elems][found_std].keys():
                                            if key not in element_count[elems][device_list[-1]].keys():
                                                element_count[elems][device_list[-1]][key] = element_count[elems][found_std][key] * m
                                            else:
                                                element_count[elems][device_list[-1]][key] += element_count[elems][found_std][key] * m

                                for key in transistor_count[found_element].keys():
                                    if key not in transistor_count[device_list[-1]].keys():
                                        transistor_count[device_list[-1]][key] = transistor_count[found_element][key] * m
                                    else:
                                        transistor_count[device_list[-1]][key] += transistor_count[found_element][key] * m

                            else:

                                for elems in element_key:
                                    if any(ele in found_element for ele in element_key[elems]):
                                        if found_element in element_count[elems][device_list[-1]].keys():
                                            element_count[elems][device_list[-1]][found_element] += 1
                                            # print('hdb here', found_element, device_list[-1])
                                        else:
                                            element_count[elems][device_list[-1]][found_element] = 1

                                    if any(x in line.split() for x in element_count[elems].keys()):
                                        found_std = next(element for element in line.split() if element in element_count[elems].keys())
                                        for key in element_count[elems][found_std].keys():
                                            if key not in element_count[elems][device_list[-1]].keys():
                                                element_count[elems][device_list[-1]][key] = element_count[elems][found_std][key]
                                            else:
                                                element_count[elems][device_list[-1]][key] += element_count[elems][found_std][key]

                                for key in transistor_count[found_element].keys():
                                    if key not in transistor_count[device_list[-1]].keys():
                                        transistor_count[device_list[-1]][key] = transistor_count[found_element][key]
                                    else:
                                        transistor_count[device_list[-1]][key] += transistor_count[found_element][key]

                        else:
                            # device
                            if '_mac ' in line and 'l=' in line and 'nfin=' in line and 'm=' in line and "nf=" in line:
                                device = re.search("([a-z0-9-_.+]+_mac )", line, re.IGNORECASE).group(1).strip()
                                le = re.search(".*l=([a-z0-9-_.+]+).*", line, re.IGNORECASE).group(1)
                                nfin = re.search(".*nfin=([a-z0-9-_.+]+).*", line, re.IGNORECASE).group(1)
                                nf = re.search(".*nf=([a-z0-9-_.+]+).*", line, re.IGNORECASE).group(1)
                                if 'rows*fingers' in line.lower():
                                    # m = rows*fingers
                                    m = 1
                                else:
                                    m = re.search(".*m=([a-z0-9-_.+]+).*", line, re.IGNORECASE).group(1)
                                    if m[-1] == 'k':
                                        m = int(float(m[0:-1]) * 1000)

                                # typ = '{}/{}/{}' .format(device, l, nfin)

                                if 'dum' in line.lower().split()[0] or 'dmy' in line.lower().split()[0]:
                                    typ = 'dum_{}/{}/{}'.format(device, le, nfin)
                                else:
                                    typ = '{}/{}/{}'.format(device, le, nfin)

                                if typ not in transistor_count[device_list[-1]].keys():
                                    transistor_count[device_list[-1]][typ] = 1 * int(nf) * int(m)
                                else:
                                    transistor_count[device_list[-1]][typ] += 1 * int(nf) * int(m)

                            elif '_mac ' in line and 'l=' in line and 'nfin=' in line and 'm=' in line and "nf=" not in line:
                                device = re.search("([a-z0-9-_.+]+_mac )", line, re.IGNORECASE).group(1).strip()
                                le = re.search(".*l=([a-z0-9-_.+]+).*", line, re.IGNORECASE).group(1)
                                nfin = re.search(".*nfin=([a-z0-9-_.+]+).*", line, re.IGNORECASE).group(1)

                                if 'rows*fingers' in line.lower():
                                    # m = rows*fingers
                                    m = 1
                                else:
                                    m = re.search(".*m=([a-z0-9-_.+]+).*", line, re.IGNORECASE).group(1)
                                    if m[-1] == 'k':
                                        m = int(float(m[0:-1]) * 1000)

                                # typ = '{}/{}/{}' .format(device, l, nfin)

                                if 'dum' in line.lower().split()[0] or 'dmy' in line.lower().split()[0]:
                                    typ = 'dum_{}/{}/{}'.format(device, le, nfin)
                                else:
                                    typ = '{}/{}/{}'.format(device, le, nfin)

                                if typ not in transistor_count[device_list[-1]].keys():
                                    transistor_count[device_list[-1]][typ] = 1 * int(m)
                                else:
                                    transistor_count[device_list[-1]][typ] += 1 * int(m)

                            elif 'nmoscap' in line and 'lr=' in line and 'nfin=' in line and 'm=' in line:
                                # print('in')
                                device = line.split()[3]
                                # device = re.search("([a-z0-9-_.+]+cap_18 )", line, re.IGNORECASE).group(1).strip()
                                lr = re.search(".*lr=([a-z0-9-_.+]+).*", line, re.IGNORECASE).group(1)
                                nfin = re.search(".*nfin=([a-z0-9-_.+]+).*", line, re.IGNORECASE).group(1)
                                if 'rows*fingers' in line.lower():
                                    # m = rows*fingers
                                    m = 1
                                else:
                                    m = re.search(".*m=([a-z0-9-_.+]+).*", line, re.IGNORECASE).group(1)
                                    if m[-1] == 'k':
                                        m = int(float(m[0:-1]) * 1000)
                                # print int(m)
                                # typ = '{}/{}/{}'.format(device, lr, nfin)

                                if 'dum' in line.lower().split()[0] or 'dmy' in line.lower().split()[0]:
                                    typ = 'dum_{}/{}/{}'.format(device, lr, nfin)
                                else:
                                    typ = '{}/{}/{}'.format(device, lr, nfin)
                                # print(m, typ, device_list[-1])
                                if typ not in transistor_count[device_list[-1]].keys():
                                    transistor_count[device_list[-1]][typ] = 1 * int(m)
                                else:
                                    transistor_count[device_list[-1]][typ] += 1 * int(m)

            # print(files)
            # print(device_list[-1])
            # print(element_count)
            # if len(device_list) != 0:
            #     for elems in element_count:
            #         print(elems, element_count[elems])
            #         for key in element_count[elems][device_list[-1]]:
            #             print("{} : {}".format(key, element_count[elems][device_list[-1]][key]))
            #     print("\n")

            if format(os.path.splitext(os.path.basename(files))[0]) not in final_count.keys():
                if len(device_list) == 0:
                    #     for tran in sorted(transistor_count.keys()):
                    #         print(tran, transistor_count[tran])
                    #
                    #     print(device_list)
                    print('No devices in {}'.format(format(os.path.splitext(os.path.basename(files))[0])))
                else:
                    final_count[format(os.path.splitext(os.path.basename(files))[0])] = transistor_count[device_list[-1]]
                    for elem in element_key:
                        final_element_count[format(os.path.splitext(os.path.basename(files))[0])][elem] = element_count[elem][device_list[-1]]
            else:
                # for tran in sorted(transistor_count.keys()):
                #     print(tran, transistor_count[tran])
                #
                # print(device_list)
                print('More than one .cdl netlist found with name {}. Script will show results for only one netlist.'.format(format(os.path.splitext(os.path.basename(files))[0])))

    workbook = xlsxwriter.Workbook('transistor_count_cdl.xlsx')
    worksheet_summary = workbook.add_worksheet('Transistor Count Summary')
    worksheet_feedback = workbook.add_worksheet('Feedback Elements Summary')
    worksheet_fbdetail = workbook.add_worksheet('Feedback Elements Count Detail')
    worksheet_detail = workbook.add_worksheet('Transistor Count Detail')

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

    worksheet_feedback.write('A1', 'Feedback Element Count Summary', cell_format_border_bold)
    worksheet_feedback.write('B1', str(os.getcwd()), cell_format_border)
    worksheet_feedback.write('A3', 'macro', cell_format_border_gray)
    worksheet_feedback.write('B3', 'feedback element', cell_format_border_gray)
    worksheet_feedback.write('C3', 'count', cell_format_border_gray)

    worksheet_detail.write('A1', 'Transistor Count Detail', cell_format_border_bold)
    worksheet_detail.write('B1', str(os.getcwd()), cell_format_border)
    worksheet_detail.write('A3', 'macro', cell_format_border_gray)
    worksheet_detail.write('B3', 'device', cell_format_border_gray)
    worksheet_detail.write('C3', 'length', cell_format_border_gray)
    worksheet_detail.write('D3', 'nfin', cell_format_border_gray)
    worksheet_detail.write('E3', 'count', cell_format_border_gray)

    worksheet_fbdetail.write('A1', 'Feedback Element Count Detail', cell_format_border_bold)
    worksheet_fbdetail.write('B1', str(os.getcwd()), cell_format_border)
    worksheet_fbdetail.write('A3', 'macro', cell_format_border_gray)
    worksheet_fbdetail.write('B3', 'element type', cell_format_border_gray)
    worksheet_fbdetail.write('C3', 'element name', cell_format_border_gray)
    worksheet_fbdetail.write('D3', 'count', cell_format_border_gray)

    row_summary = 3
    row_detail = 3
    row_feedback = 3
    row_fbdetail = 3
    col = 0

    # for key in sorted(final_element_count.keys()):
    #     tcount = 0
    #     # print('\n\n{}:' .format(key))
    #     for innerkey in sorted(final_element_count[key].keys()):
    #         for inmost in sorted(final_element_count[key][innerkey].keys()):
    #             print("{}\t{}\t{}\t{}".format(key, innerkey, inmost, final_element_count[key][innerkey][inmost]))
    #             tcount += final_element_count[key][innerkey][inmost]
    #     print ('{}:\t{}' .format(key, tcount))

    for macro in sorted(final_element_count.keys()):
        tcount = 0
        # print('\n\n{}:' .format(key))
        devices = {'flop': 0, 'latch': 0, 'schmitt_trigger': 0, 'power_sniffer': 0, 'sampler': 0, 'phase_detector': 0}
        for innerkey in sorted(final_element_count[macro].keys()):
            for inmost in sorted(final_element_count[macro][innerkey].keys()):
                # print("{}\t{}\t{}\t{}".format(macro, innerkey, inmost, final_element_count[macro][innerkey][inmost]))

                if tcount == 0:
                    worksheet_feedback.write(row_feedback, col, macro, cell_format_border_gray)
                    worksheet_fbdetail.write(row_fbdetail, col, macro, cell_format_border)
                worksheet_fbdetail.write(row_fbdetail, col + 1, innerkey, cell_format_border)
                worksheet_fbdetail.write(row_fbdetail, col + 2, inmost, cell_format_border)
                worksheet_fbdetail.write(row_fbdetail, col + 3, final_element_count[macro][innerkey][inmost], cell_format_border)
                row_fbdetail += 1
                devices[innerkey] += final_element_count[macro][innerkey][inmost]
                tcount += final_element_count[macro][innerkey][inmost]

        # print ('{}:\t{}\t{}' .format(macro, tcount, devices))

        if tcount != 0:
            worksheet_feedback.write(row_feedback, col + 1, 'total', cell_format_border_gray)
            worksheet_feedback.write(row_feedback, col + 2, tcount, cell_format_border_gray)
            row_feedback += 1

            for sum_key in sorted(devices.keys()):
                worksheet_feedback.write(row_feedback, col + 1, sum_key, cell_format_border)
                worksheet_feedback.write(row_feedback, col + 2, devices[sum_key], cell_format_border)
                row_feedback += 1

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
        subprocess.call("libreoffice transistor_count_cdl.xlsx &", stderr=subprocess.STDOUT, shell=True)
    except subprocess.CalledProcessError as exc:
        print("Open Failed. Please close all instances of Libreoffice before running script. Return Code: {} {}".format(exc.returncode, exc.output))
        # failed_files[files] = ['No FineSim Mode']
    else:
        print("Run Complete.")

    # os.startfile('transistor_count_cdl.xlsx')


if __name__ == '__main__':
    main()
