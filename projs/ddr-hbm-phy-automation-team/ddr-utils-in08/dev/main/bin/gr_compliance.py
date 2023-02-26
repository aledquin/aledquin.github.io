#!/depot/Python/Python-3.8.0/bin/python -E

import subprocess
import os
import re
import sys
import xlrd
import csv
import getpass
import time
import xlsxwriter
import getopt
from colorama import init, Fore, Back
import collections
import operator
import pathlib
init(autoreset=True)

# ----------------------------------#
bindir = str(pathlib.Path(__file__).resolve().parent)
sys.path.append(bindir + '/../lib/python/Util')
sys.path.append(bindir + '/../lib/python')
# ----------------------------------#
from Misc import utils__script_usage_statistics, get_release_version
__version__ = get_release_version(bindir)

utils__script_usage_statistics(__file__, __version__)


def main():    # noqa C901
    project = re.search(".*/([a-z0-9-_.+]+)/.*/design/sim", os.getcwd(), re.IGNORECASE).group(1)

    allFiles = getFiles()

    start = time.time()
    dependentFiles = dependencyMap(os.getcwd() + '/', 0, allFiles)
    end = time.time()

    print('Time taken to calculate dependant files is {} second(s).'.format(round(end - start, 2)))

    gr_root = gr_check(hmf)

    # for key in dependentFiles:
    #     print(key, dependentFiles[key])

    # report_start = time.time()
    # reportFiles = report_check(allFiles, gr_root)
    # report_end = time.time()
    #
    # print('Time taken to get reports is {} second(s).'.format(round(report_end - report_start, 2)))
    #
    # for key in reportFiles:
    #     print(key, reportFiles[key])

    finalTable = makeTree(hmf, gr_root, dependentFiles)

    # for key in gr_root:
    #     print(key, gr_root[key])

    comp_start = time.time()
    compareFiles = p4_compare(finalTable)
    comp_end = time.time()

    print('Time taken to diff files is {} second(s).'.format(round(comp_end - comp_start, 2)))

    # for key in compareFiles:
    #     print(key, compareFiles[key])

    col = 0

    workbook = xlsxwriter.Workbook('golden_reference_compliance_report.xlsx')
    worksheet_summary = workbook.add_worksheet('Summary')
    worksheet_detail = workbook.add_worksheet('Detail')
    worksheet_p4compare = workbook.add_worksheet('P4Diff')
    # worksheet_reports = workbook.add_worksheet('Reports')
    worksheet_missing = workbook.add_worksheet('Missing TBs')
    worksheet_missing_macros = workbook.add_worksheet('Non-GR Macros')

    cell_format_border = workbook.add_format()
    cell_format_border.set_border()

    cell_format_border_bold = workbook.add_format()
    cell_format_border_bold.set_bold()
    cell_format_border_bold.set_border()

    cell_format_border_merge = workbook.add_format()
    cell_format_border_merge.set_bold()
    cell_format_border_merge.set_border()
    cell_format_border_merge.set_align('center')
    cell_format_border_merge.set_valign('vcenter')

    cell_format_border_mergeflat = workbook.add_format()
    cell_format_border_mergeflat.set_border()
    cell_format_border_mergeflat.set_align('center')
    cell_format_border_mergeflat.set_valign('vcenter')

    cell_format_border_red = workbook.add_format()
    cell_format_border_red.set_border()
    cell_format_border_red.set_bg_color('orange')

    cell_format_border_yellow = workbook.add_format()
    cell_format_border_yellow.set_border()
    cell_format_border_yellow.set_bg_color('cyan')

    cell_format_border_green = workbook.add_format()
    cell_format_border_green.set_border()
    cell_format_border_green.set_bg_color('lime')

    cell_format_border_gray = workbook.add_format()
    cell_format_border_gray.set_border()
    cell_format_border_gray.set_bold()
    cell_format_border_gray.set_bg_color('silver')

    cell_format_border_wrap = workbook.add_format()
    cell_format_border_wrap.set_border()
    cell_format_border_wrap.set_text_wrap()
    cell_format_border_wrap.set_bg_color('orange')

    worksheet_detail.merge_range('A1:D1', '{} GR Compliance Detail'.format(project), cell_format_border_merge)
    worksheet_detail.write('A2', 'GR TBs', cell_format_border_green)
    worksheet_detail.write('B2', 'Non-GR TBs', cell_format_border_yellow)
    worksheet_detail.write('C2', 'Present dependent files', cell_format_border_green)
    worksheet_detail.write('D2', 'Missing dependent files', cell_format_border_red)
    worksheet_detail.write('A3', 'Macro', cell_format_border_gray)
    worksheet_detail.write('B3', 'Filename', cell_format_border_gray)
    worksheet_detail.write('C3', 'HMF', cell_format_border_gray)
    worksheet_detail.write('D3', 'Path', cell_format_border_gray)

    row_detail = 3
    # files[filename, macro] = ['Present/Missing/GR/Non-GR', hmf, fullpath]

    for files in sorted(finalTable.keys(), key=operator.itemgetter(0, 1)):
        if finalTable[files][0] == 'GR':
            worksheet_detail.write(row_detail, col, files[1], cell_format_border_green)
            worksheet_detail.write(row_detail, col + 1, files[0], cell_format_border_green)
            worksheet_detail.write(row_detail, col + 2, finalTable[files][1], cell_format_border_green)
            worksheet_detail.write(row_detail, col + 3, finalTable[files][2], cell_format_border_green)
            row_detail += 1
        elif finalTable[files][0] == 'Non-GR':
            worksheet_detail.write(row_detail, col, files[1], cell_format_border_yellow)
            worksheet_detail.write(row_detail, col + 1, files[0], cell_format_border_yellow)
            worksheet_detail.write(row_detail, col + 2, finalTable[files][1], cell_format_border_yellow)
            worksheet_detail.write(row_detail, col + 3, finalTable[files][2], cell_format_border_yellow)
            row_detail += 1
        elif finalTable[files][0] == 'Present':
            worksheet_detail.write(row_detail, col, files[1], cell_format_border_green)
            worksheet_detail.write(row_detail, col + 1, files[0], cell_format_border_green)
            worksheet_detail.write(row_detail, col + 2, finalTable[files][1], cell_format_border_green)
            worksheet_detail.write(row_detail, col + 3, finalTable[files][2], cell_format_border_green)
            row_detail += 1
        elif finalTable[files][0] == 'Missing':
            worksheet_detail.write(row_detail, col, files[1], cell_format_border_red)
            worksheet_detail.write(row_detail, col + 1, files[0], cell_format_border_red)
            worksheet_detail.write(row_detail, col + 2, finalTable[files][1], cell_format_border_red)
            worksheet_detail.write(row_detail, col + 3, finalTable[files][2], cell_format_border_red)
            row_detail += 1

    worksheet_p4compare.merge_range('A1:G1', '{} P4 Diff Report'.format(project), cell_format_border_merge)
    worksheet_p4compare.write('A2', 'Macro', cell_format_border_gray)
    worksheet_p4compare.write('B2', 'Testbench', cell_format_border_gray)
    worksheet_p4compare.write('C2', 'workspaceVSproject', cell_format_border_gray)
    worksheet_p4compare.write('D2', 'projectVSgolden', cell_format_border_gray)
    worksheet_p4compare.write('E2', 'Local Path', cell_format_border_gray)
    worksheet_p4compare.write('F2', 'P4 Project Path', cell_format_border_gray)
    worksheet_p4compare.write('G2', 'GR Path', cell_format_border_gray)

    # p4compare_result[filename, macro] = [p4 filename, workspaceVSproject, gr filename, projectVSgolden]
    row_compare = 2

    for files in sorted(compareFiles.keys(), key=operator.itemgetter(0, 1)):
        worksheet_p4compare.write(row_compare, col, files[1], cell_format_border)
        worksheet_p4compare.write(row_compare, col + 1, os.path.basename(files[0]), cell_format_border)
        worksheet_p4compare.write(row_compare, col + 4, files[0], cell_format_border)
        worksheet_p4compare.write(row_compare, col + 5, compareFiles[files][0], cell_format_border)
        worksheet_p4compare.write(row_compare, col + 6, compareFiles[files][2], cell_format_border)
        if 'up-to-date' in compareFiles[files][1]:
            worksheet_p4compare.write(row_compare, col + 2, compareFiles[files][1], cell_format_border_green)
        else:
            worksheet_p4compare.write(row_compare, col + 2, compareFiles[files][1], cell_format_border_wrap)
        if 'up-to-date' in compareFiles[files][3]:
            worksheet_p4compare.write(row_compare, col + 3, compareFiles[files][3], cell_format_border_green)
        else:
            worksheet_p4compare.write(row_compare, col + 3, compareFiles[files][3], cell_format_border_wrap)
        row_compare += 1

    # reportdir_result[files, macro] = ['Missing', str(report + '/' + macro + '/' + tb + '/index.xml')]
    #
    # worksheet_reports.merge_range('A1:D1', '{} Reports Detail'.format(project), cell_format_border_merge)
    # worksheet_reports.write('A2', 'Macro', cell_format_border_gray)
    # worksheet_reports.write('B2', 'Testbench', cell_format_border_gray)
    # worksheet_reports.write('C2', 'TB Type', cell_format_border_gray)
    # worksheet_reports.write('D2', 'Report Path', cell_format_border_gray)
    #
    # row_report = 2
    #
    # for files in sorted(reportFiles.keys(), key=operator.itemgetter(0, 1)):
    #     if reportFiles[files][0] == 'Present':
    #         worksheet_reports.write(row_report, col, files[1], cell_format_border_green)
    #         worksheet_reports.write(row_report, col + 1, os.path.basename(files[0]), cell_format_border_green)
    #         worksheet_reports.write(row_report, col + 2, reportFiles[files][2], cell_format_border_green)
    #         worksheet_reports.write(row_report, col + 3, reportFiles[files][1], cell_format_border_green)
    #         row_report += 1
    #     elif reportFiles[files][0] == 'Missing':
    #         worksheet_reports.write(row_report, col, files[1], cell_format_border_red)
    #         worksheet_reports.write(row_report, col + 1, os.path.basename(files[0]), cell_format_border_red)
    #         worksheet_reports.write(row_report, col + 2, reportFiles[files][2], cell_format_border_red)
    #         worksheet_reports.write(row_report, col + 3, reportFiles[files][1], cell_format_border_red)
    #         row_report += 1

    macro_list_gr = []

    for key in gr_root.keys():
        if key[1] not in macro_list_gr:
            macro_list_gr.append(key[1])

    # print(macro_list_gr)

    macroGR = {}
    listGR = {}

    for mac in macro_list_gr:
        macroGR[mac] = {'pre': 0, 'post': 0, 'none': 0}
        listGR[mac] = []
        for key in gr_root:

            if key[1] == mac:
                if mode == 'pre' and '_pre' in key[0]:
                    listGR[mac].append(key[0])
                    macroGR[mac]['pre'] += 1
                elif mode == 'post' and '_post' in key[0]:
                    listGR[mac].append(key[0])
                    macroGR[mac]['post'] += 1
                elif mode == 'full':
                    listGR[mac].append(key[0])

                else:
                    macroGR[mac]['none'] += 1

    # for key in sorted(macroGR.keys()):
    #     print(key, macroGR[key])

    macro_list_proj = []

    for key in finalTable:
        if key[1] not in macro_list_proj:
            macro_list_proj.append(key[1])
        # if key[1].endswith('_ew') and key[1] not in macro_list_gr:
        #     if key[1].replace('_ew', '_ns') in macro_list_gr:
        #         macro_list_proj.append(key[1].replace('_ew', '_ns'))
        #     elif key[1].replace('_ew', '') in macro_list_gr:
        #         macro_list_proj.append(key[1].replace('_ew', ''))
        # else:
        #     macro_list_proj.append(key[1])
    #
    # macro_list_proj = list(dict.fromkeys(macro_list_proj))

    # print(macro_list_proj)

    # report_num = {}
    macroPROJ = {}
    listPROJ = {}

    for mac in macro_list_proj:
        macroPROJ[mac] = {'pre-gr': 0, 'post-gr': 0, 'none-gr': 0, 'pre-local': 0, 'post-local': 0, 'none-local': 0}
        # report_num[mac] = {'pre-gr': 0, 'post-gr': 0, 'none-gr': 0, 'pre-local': 0, 'post-local': 0, 'none-local': 0}
        listPROJ[mac] = []

        # for key in finalTable:
        #     if key[1] == mac or key[1].replace('_ew', '_ns') == mac or key[1].replace('_ew', '') == mac:
        #         listPROJ[mac].append(key[0])
        #         if finalTable[key][0] == 'GR':
        #             if '_pre' in key[0]:
        #                 macroPROJ[mac]['pre-gr'] += 1
        #             elif '_post' in key[0]:
        #                 macroPROJ[mac]['post-gr'] += 1
        #                 # print key
        #             else:
        #                 macroPROJ[mac]['none-gr'] += 1
        #         elif finalTable[key][0] == 'Non-GR':
        #             if key[1].endswith('_ew') and key[1] not in macro_list_gr:
        #                 if key[1].replace('_ew', '_ns') in macro_list_gr:
        #                     if '_pre' in key[0]:
        #                         macroPROJ[mac]['pre-gr'] += 1
        #                     elif '_post' in key[0]:
        #                         macroPROJ[mac]['post-gr'] += 1
        #                         # print key
        #                     else:
        #                         macroPROJ[mac]['none-gr'] += 1
        #                     # macro_list_proj.append(key[1].replace('_ew', '_ns'))
        #                 elif key[1].replace('_ew', '') in macro_list_gr:
        #                     if '_pre' in key[0]:
        #                         macroPROJ[mac]['pre-gr'] += 1
        #                     elif '_post' in key[0]:
        #                         macroPROJ[mac]['post-gr'] += 1
        #                         # print key
        #                     else:
        #                         macroPROJ[mac]['none-gr'] += 1
        #                     # macro_list_proj.append(key[1].replace('_ew', ''))
        #             else:
        #                 # macro_list_proj.append(key[1])
        #                 if '_pre' in key[0]:
        #                     macroPROJ[mac]['pre-local'] += 1
        #                 elif '_post' in key[0]:
        #                     macroPROJ[mac]['post-local'] += 1
        #                 else:
        #                     macroPROJ[mac]['none-local'] += 1

        for key in finalTable:
            if key[1] == mac:
                listPROJ[mac].append(key[0])
                if finalTable[key][0] == 'GR':
                    if '_pre' in key[0]:
                        macroPROJ[mac]['pre-gr'] += 1
                    elif '_post' in key[0]:
                        macroPROJ[mac]['post-gr'] += 1
                        # print key
                    else:
                        macroPROJ[mac]['none-gr'] += 1
                elif finalTable[key][0] == 'Non-GR':
                    if '_pre' in key[0]:
                        macroPROJ[mac]['pre-local'] += 1
                    elif '_post' in key[0]:
                        macroPROJ[mac]['post-local'] += 1
                    else:
                        macroPROJ[mac]['none-local'] += 1

        # for key in reportFiles:
        #     if key[1] == mac and reportFiles[key][0] == 'Present':
        #         if reportFiles[key][2] == 'GR':
        #             if '_pre' in os.path.basename(key[0]):
        #                 report_num[mac]['pre-gr'] += 1
        #             elif '_post' in os.path.basename(key[0]):
        #                 report_num[mac]['post-gr'] += 1
        #                 # print key
        #             else:
        #                 report_num[mac]['none-gr'] += 1
        #         elif reportFiles[key][2] == 'Non-GR':
        #             if '_pre' in os.path.basename(key[0]):
        #                 report_num[mac]['pre-local'] += 1
        #             elif '_post' in os.path.basename(key[0]):
        #                 report_num[mac]['post-local'] += 1
        #             else:
        #                 report_num[mac]['none-local'] += 1

    # for key in report_num:
    #     print(key, report_num)

    # for key in sorted(macroPROJ.keys()):
    #     print(key, macroPROJ[key])

    worksheet_summary.merge_range('A1:E1', '{} GR Compliance Summary'.format(hmf), cell_format_border_merge)
    worksheet_summary.write('A2', 'Path:', cell_format_border_bold)
    worksheet_summary.merge_range('B2:E2', str(os.getcwd()), cell_format_border_mergeflat)
    worksheet_summary.write('A3', 'Command:', cell_format_border_bold)
    worksheet_summary.merge_range('B3:E3', str(" ".join(sys.argv)), cell_format_border_mergeflat)
    worksheet_summary.write('A4', 'Macro', cell_format_border_gray)
    worksheet_summary.write('B4', 'Local TBs Proj', cell_format_border_gray)
    worksheet_summary.write('C4', 'GR TBs Proj', cell_format_border_gray)
    worksheet_summary.write('D4', 'GR TBs Total', cell_format_border_gray)
    worksheet_summary.write('E4', 'GR List Compliance %age', cell_format_border_gray)

    row_summary = 4

    for macro in sorted(macroPROJ.keys()):
        if mode == 'pre' and macro in macroGR.keys():
            worksheet_summary.write(row_summary, col, macro, cell_format_border)
            worksheet_summary.write(row_summary, col + 1, str(macroPROJ[macro]['pre-local']), cell_format_border)

            worksheet_summary.write(row_summary, col + 2, str(macroPROJ[macro]['pre-gr']), cell_format_border)

            worksheet_summary.write(row_summary, col + 3, str(macroGR[macro]['pre']), cell_format_border)
            if macroGR[macro]['pre'] != 0:
                worksheet_summary.write(row_summary, col + 4, '{}%'.format(str(percentage(macroPROJ[macro]['pre-gr'], macroGR[macro]['pre']))), cell_format_border)
            else:
                worksheet_summary.write(row_summary, col + 4, '-', cell_format_border)
            row_summary += 1

        elif mode == 'post' and macro in macroGR.keys():
            worksheet_summary.write(row_summary, col, macro, cell_format_border)
            worksheet_summary.write(row_summary, col + 1, str(macroPROJ[macro]['post-local']), cell_format_border)

            worksheet_summary.write(row_summary, col + 2, str(macroPROJ[macro]['post-gr']), cell_format_border)

            worksheet_summary.write(row_summary, col + 3, str(macroGR[macro]['post']), cell_format_border)
            if macroGR[macro]['post'] != 0:
                worksheet_summary.write(row_summary, col + 4, '{}%'.format(str(percentage(macroPROJ[macro]['post-gr'], macroGR[macro]['post']))), cell_format_border)
            else:
                worksheet_summary.write(row_summary, col + 4, '-', cell_format_border)
            row_summary += 1

        elif mode == 'full' and macro in macroGR.keys():
            worksheet_summary.write(row_summary, col, macro, cell_format_border)

            full_local = str(macroPROJ[macro]['post-local'] + macroPROJ[macro]['pre-local'] + macroPROJ[macro]['none-local'])
            worksheet_summary.write(row_summary, col + 1, full_local, cell_format_border)

            full_gr = str(macroPROJ[macro]['post-gr'] + macroPROJ[macro]['pre-gr'] + macroPROJ[macro]['none-gr'])
            worksheet_summary.write(row_summary, col + 2, full_gr, cell_format_border)

            full = str(macroGR[macro]['post'] + macroGR[macro]['pre'] + macroGR[macro]['none'])
            worksheet_summary.write(row_summary, col + 3, full, cell_format_border)

            if full != 0:
                worksheet_summary.write(row_summary, col + 4, '{}%'.format(str(percentage(full_gr, full))), cell_format_border)
            else:
                worksheet_summary.write(row_summary, col + 4, '-', cell_format_border)
            row_summary += 1

    missingTB = {}
    missingMACRO = []

    for mac in macro_list_proj:
        if mac in listGR.keys():
            common_tb = set(listGR[mac]).intersection(listPROJ[mac])
            missingTB[mac] = list(set(listGR[mac]) - common_tb)
        else:
            missingMACRO.append(mac)
            # print(Fore.RED + '{} macro not found in Official GR Excel Sheet'.format(mac))

    worksheet_missing.merge_range('A1:B1', '{} Missing Testbench List'.format(project), cell_format_border_merge)
    worksheet_missing.write('A2', 'Macro', cell_format_border_gray)
    worksheet_missing.write('B2', 'Missing GR TB', cell_format_border_gray)

    row_missing = 2

    for macro in sorted(missingTB.keys()):
        for tb in sorted(missingTB[macro]):
            worksheet_missing.write(row_missing, col, macro, cell_format_border)
            worksheet_missing.write(row_missing, col + 1, str(tb), cell_format_border)
            row_missing += 1

    worksheet_missing_macros.write('A1', 'Non-GR Macros List (Macros present in rel_gr but not in the Official GR Excel Sheet)', cell_format_border_gray)

    row_missing_macro = 1

    for macro in sorted(missingMACRO):
        worksheet_missing_macros.write(row_missing_macro, col, macro, cell_format_border)
        row_missing_macro += 1
    workbook.close()

    try:
        subprocess.call("libreoffice golden_reference_compliance_report.xlsx &", stderr=subprocess.STDOUT, shell=True)
    except subprocess.CalledProcessError as exc:
        print("Open Failed. Please close all instances of Libreoffice before running script. Return Code: {} {}".format(exc.returncode, exc.output))
        # failed_files[files] = ['No FineSim Mode']
    else:
        try:
            subprocess.call('echo "Script Summary:\n-----------------------------------------------\nOfficial GR Excel Validity Check\nUser: {}\nPath: {}\nHMF: {}\nMode: {}\n-----------------------------------------------\n\nPlease find the report attached." | mail -s "gr_compliance_check_{}_{} result" -a golden_reference_compliance_report.xlsx {}@synopsys.com'.format(GCFG['username'], str(os.getcwd()), hmf, mode, hmf, mode, GCFG['username']), shell=True)
        except subprocess.CalledProcessError as exxc:
            print("Status : FAIL {} {}".format(exxc.returncode, exxc.output))
        else:
            print(Fore.GREEN + "Run Complete.")


def getFiles():
    main = []
    root = os.getcwd()
    if 'p4_ws' not in root:
        print(Fore.RED + "Please run the script inside p4 workspace project area\n")
        sys.exit()
    else:
        exclude = {'lib', 'reports', 'esp', 'cck', 'netlist_testbench', 'data', 'Monitoring', 'batch_sim', '~', 'share'}

        for path, subdirs, files in os.walk(root, topdown=True, followlinks=True):
            subdirs[:] = [d for d in subdirs if d not in exclude]
            for name in files:
                if os.path.splitext(name)[1] in ['.bbSim', '.tcl', '.v', '.py', '.inc', '.sp', '.corners', '.variants', '.sh', '.vec', '.measure', '.plot', '.pl', '.raw', '.dat']:
                    line = os.path.join(path, name)
                    main.append(line)
        return main


# returns list of all files present


def getProcess(corner, isP4):
    if not isP4:
        return subprocess.check_output(r"grep LIB {} | head -n1 | sed -E 's/\s.*//g' ".format(corner), shell=True).decode("utf-8", 'ignore').rstrip()
    else:
        return subprocess.check_output(r"p4 grep -e LIB {} | sed -E 's/^.*#[0-9]+://g' | head -n1 | sed -E 's/\s.*//g' ".format(corner), shell=True).decode("utf-8", 'ignore').rstrip()


def getP4Name(filename):  # gets absolute p4 path from relative local path
    abs_path = os.path.abspath(filename)
    return re.split(r'\s+', subprocess.check_output("p4 have {} 2>&1".format(abs_path), shell=True).decode("utf-8", 'ignore'))[0]


def dependencyMap(path, isP4, LocalFiles):    # noqa 42
    if not isP4:
        allFiles = LocalFiles
    else:
        if 'wwcad' in path:
            wwcad_path = '/' + re.search(r"(/wwcad.*)", path).group(0)
        elif 'p4_ws/projects/' in path:
            wwcad_path = '//wwcad/msip' + re.search(r"(/projects.*)", path).group(0)
        allFiles = subprocess.check_output("p4 files {}... | grep -v 'delete change' | grep -v '/esp/' | grep -v '/cck/' | grep -v '/emir/'| grep -v '/data/' | grep -v '/audit/' | grep -v 'batch_sim' | sed -E 's/#.*//g'".format(wwcad_path), shell=True).decode("utf-8", 'ignore').rstrip()
        allFiles = allFiles.split('\n')

    allCorners = [x for x in allFiles if '.corners' in x and x != ""]
    try:
        tech = getProcess(allCorners[0], isP4)
    except IndexError:
        tech = 'process'

    allPos = r'source|\.tcl|\.v|\.py|\.inc|\.sp|\.corners|\.variants|\.sh|\.vec|\.measure|\.plot|\.pl|\.raw|\.dat|INCLUDE|CORNERS_LIST|SPICE_COMMAND|PLOT_CONFIG|MEASURE_CONFIG|_REPORT|VARIANTS_|GDS'
    unFoundFiles = []
    woP = []
    resultSet = {}
    for eachFile in allFiles:
        # print eachFile
        if 'design/sim' in eachFile:
            woP.append(eachFile.replace(re.search("^(/.*/design/sim/)", eachFile, re.IGNORECASE).group(1), ""))

    for eachFile in allFiles:
        if ('sp' in os.path.splitext(eachFile)[1][1:] and '/project/' in eachFile) or (os.path.splitext(eachFile)[1][1:] == 'raw' and '/project/' in eachFile) or ('/scripts/' not in eachFile and os.path.splitext(eachFile)[1] == '') or (os.path.splitext(eachFile)[1][1:] == 'txt') or ('log' in os.path.splitext(eachFile)[1][1:]) or ('/netlist' in eachFile):  # or ('scripts' not in eachFile and eachFile is not None)
            continue
        # print eachFile
        try:
            macro = re.search("/design/sim/([a-z0-9-_.+]+)/", eachFile, re.IGNORECASE).group(1)
        except AttributeError:
            macro = '-'

        if not isP4:
            try:
                calls = subprocess.check_output(r"grep -E '{}' {} | sed '/^$\|#\|^*\|USAGE\|^-\|\.data\|^file.*\|Binary.*\|:\|;\|[\|]\|<\|>\|(\|)/Id'".format(allPos, eachFile), stderr=subprocess.STDOUT, shell=True).decode("utf-8", 'ignore').rstrip()
            except subprocess.CalledProcessError as exc:
                unFoundFiles.append("Status : FAIL", exc.returncode, exc.output, eachFile)
            else:
                calls = calls.split('\n')
                calls = list(dict.fromkeys(calls))
        else:
            try:
                calls = subprocess.check_output(r"p4 grep -e '{}' {} | sed -E 's/^.*#[0-9]+://g' | sed '/^$\|#\|^*\|USAGE\|^-\|\.data\|^file.*\|Binary.*\|:\|;\|[\|]\|<\|>\|(\|)/Id'".format(allPos, eachFile), stderr=subprocess.STDOUT, shell=True).decode("utf-8", 'ignore').rstrip()
            except subprocess.CalledProcessError as exc:
                unFoundFiles.append("Status : FAIL", exc.returncode, exc.output, eachFile)
            else:
                calls = calls.split('\n')
                calls = list(dict.fromkeys(calls))

        if all('' == s or s.isspace() for s in calls):
            continue

        # bbSim
        if '.bbSim'.lower() in eachFile.lower():
            # print 'bbSim', eachFile, calls
            dep = 0
            while dep < len(calls):
                if 'INCLUDE' in calls[dep] and 'all' in calls[dep]:
                    calls[dep] = re.sub(r"INCLUDE.*all\s+(.*)", r"\1", calls[dep])
                    allIncs = calls[dep].split()  # \s+ is to split string for one or more spaces
                    # print allIncs
                    for aI in range(len(allIncs)):
                        if not calls[dep].startswith('/'):
                            # allIncs[aI] = allIncs[aI].split('/')[-1]
                            allIncs[aI] = os.path.basename(allIncs[aI])
                    del calls[dep]
                    calls[dep:dep] = allIncs
                    dep = dep + len(allIncs)
                    # print calls[dep], "if dep: ", dep
                else:
                    calls[dep] = calls[dep].split()[-1]
                    if not calls[dep].startswith('/'):
                        # calls[dep] = calls[dep].split('/')[-1]
                        calls[dep] = os.path.basename(calls[dep])
                    dep = dep + 1
        elif '/scripts/'.lower() in eachFile.lower():
            # print 'scripts', eachFile, calls
            for dep in range(len(calls)):
                nc = calls[dep].split()
                new = [x for x in nc if (('.pl' in x.lower()) or ('.sh' in x.lower()) or ('.py' in x.lower()) or ('.tc' in x.lower()) or ('.c' in x.lower()))]
                if new:
                    calls[dep] = new[0]
                    if ')' in calls[dep] or '(' in calls[dep]:
                        calls[dep] = ''
                        continue
                    if not calls[dep].startswith('/'):
                        # calls[dep] = calls[dep].split('/')[-1]
                        calls[dep] = os.path.basename(calls[dep])
        else:
            # print 'allelse', eachFile, calls
            dep = 0
            while dep < len(calls):
                if '.option' in calls[dep]:
                    newC = calls[dep].split()
                    newC = [x for x in newC if (('.tc' in x.lower()) or ('.va' in x.lower()) or ('.py' in x.lower()) or ('.inc' in x.lower()) or ('.sp' in x.lower()) or ('.corners' in x.lower()) or ('.variants' in x.lower()) or ('.sh' in x.lower()) or ('.vec' in x.lower()) or ('.measure' in x.lower()) or ('.vec' in x.lower()) or ('.plot' in x.lower()) or ('.pl' in x.lower()) or ('.raw' in x.lower()) or ('.dat' in x.lower()) or ('.tcl' in x.lower()))]
                    for nC in range(len(newC)):
                        newC[nC] = newC[nC].replace('"', '').replace('=', '')
                        if not newC[nC].startswith('/'):
                            newC[nC] = os.path.basename(newC[nC])
                    del calls[dep]
                    calls[dep:dep] = newC
                    dep = dep + len(newC)
                else:
                    if 'source' in calls[dep] and not calls[dep].startswith('source'):
                        calls[dep] = ''
                        continue
                    if 'SUBCKT' in calls[dep].upper() or ':' in calls[dep] or '=' in calls[dep]:
                        calls[dep] = ''
                        continue
                    calls[dep] = re.sub(r'source\s+(.*)', r"\1", calls[dep], re.IGNORECASE)
                    calls[dep] = re.sub(r"\.inc.*\'(.*)\'.*", r"\1", calls[dep], re.IGNORECASE)
                    calls[dep] = re.sub(r"\.vec.*\'(.*)\'.*", r"\1", calls[dep], re.IGNORECASE)
                    calls[dep] = re.sub(r'\.inc.*\"(.*)\".*', r"\1", calls[dep], re.IGNORECASE)
                    calls[dep] = re.sub(r'\.vec.*\"(.*)\".*', r"\1", calls[dep], re.IGNORECASE)
                    if not calls[dep].startswith('/'):
                        # calls[dep] = calls[dep].split('/')[-1]
                        calls[dep] = os.path.basename(calls[dep])
                    dep = dep + 1
            # print 'allelsepost', eachFile, calls
        # main body

        calls = list(dict.fromkeys(calls))
        calls = [x for x in calls if '' != x]
        fileStatus = []
        for dep in range(len(calls)):
            calls[dep] = re.sub(r'\s+', '', calls[dep])
            if '=' in calls[dep] or calls[dep].startswith('.measure') or calls[dep].startswith('$*'):
                calls[dep] = ''
                continue
            temp = calls[dep]
            calls[dep] = re.sub(r'\s+', r'', calls[dep])
            calls[dep] = calls[dep].replace('_process.sp', '_{}.sp'.format(tech))
            if not calls[dep].startswith('/'):
                temp = calls[dep]
                # print dep, calls[dep]
                try:
                    calls[dep] = [x for x in woP if macro in x and os.path.basename(calls[dep]) == os.path.basename(x)][0]
                    # calls[dep] = [x for x in woP if macro in x and calls[dep] in x][0]
                except IndexError:
                    # print 'after', dep, calls[dep]
                    # if not calls[dep]:
                    #     print("MISSING {} from {} \n" .format(temp, eachFile))
                    fileStatus.append(['M', temp])

                else:
                    # print("PRESENT {} from {} \n".format(temp, eachFile))
                    fileStatus.append(['P', path + calls[dep]])
            else:
                theFile = os.path.isfile(calls[dep])
                if theFile:
                    # print("Present {} from {} \n".format(calls[dep], eachFile))
                    fileStatus.append(['P', calls[dep]])
                else:
                    # print("Missing {} from {} \n".format(calls[dep], eachFile))
                    fileStatus.append(['M', calls[dep]])
        # calls = [x for x in calls if '' != x]
        resultSet[eachFile] = [macro, fileStatus]
    return resultSet


def fillp4_list(diff2, rowData, gr_file):
    if '==== content' in diff2:
        rowData.append(gr_file)
        grdiff = diff2.split('==== content')[-1]
        rowData.append(grdiff)
    elif '==== types' in diff2:
        rowData.append(gr_file)
        rowData.append('content up-to-date')
    elif '==== identical' in diff2:
        rowData.append(gr_file)
        rowData.append('file up-to-date')
    elif '<none>' in diff2:
        rowData.append(gr_file)
        rowData.append('gr file missing')
    return(rowData)


# returns { filename : [ macro, [[dependent file #1 status, dependent file #1], [dependent file #1 status, dependent file #1]]]}

def p4_compare(selected_items):
    # files[filename, macro] = ['Present/Missing/GR/Non-GR', hmf, fullpath]
    p4compare_result = {}
    cwd = os.getcwd()
    for files in selected_items:
        # status = getP4Name(files)
        if selected_items[files][0] == 'Missing' and cwd not in selected_items[files][2]:
            continue
        try:
            status = subprocess.check_output("p4 have {} 2>&1".format(selected_items[files][2]), shell=True).decode("utf-8", 'ignore').rstrip()
        except subprocess.CalledProcessError:
            p4compare_result[selected_items[files][2], files[1]] = ['Path not in client root', 'Path not in client root', 'Path not in client root', 'Path not in client root']
            return p4compare_result

        if 'not on client' in status:
            p4compare_result[selected_items[files][2], files[1]] = ['File not on client', 'File not on client', 'File not on client', 'File not on client']
            return p4compare_result
        else:
            status = status.split(' - ')[0]
            rowData = []
            diff1 = str((subprocess.check_output("p4 diff {} 2>&1".format(status), shell=True).decode("utf-8", 'ignore')).rstrip())
            if 'file(s) up-to-date' in diff1:
                rowData.append(status)
                rowData.append('file up-to-date')
            else:
                rowData.append(status)
                p4diff = diff1.split('====')[-1]
                rowData.append(p4diff)

            gr_file = GCFG[selected_items[files][1]] + '/design/sim/' + re.search(".*/design/sim/(.*)#.*", status, re.IGNORECASE).group(1)
            diff2 = str((subprocess.check_output("p4 diff2 {} {} 2>&1".format(status, gr_file), shell=True).decode("utf-8", 'ignore'))).rstrip()

            p4compare_result[selected_items[files][2], files[1]] = fillp4_list(diff2, rowData, gr_file)

        return p4compare_result


def dumpData(report, macro, tb, files, excelRoot, reportdir_result):
    if os.path.isfile(str(report + '/' + macro + '/' + tb + '/index.xml')):
        if macro.endswith('_ns'):
            if (os.path.basename(files), macro[:-len('_ns')]) in excelRoot.keys():
                reportdir_result[files, macro[:-len('_ns')]] = ['Present', str(report + '/' + macro + '/' + tb + '/index.xml'), 'GR']
            else:
                reportdir_result[files, macro[:-len('_ns')]] = ['Present', str(report + '/' + macro + '/' + tb + '/index.xml'), 'Non-GR']
        else:
            if (os.path.basename(files), macro) in excelRoot.keys():
                reportdir_result[files, macro] = ['Present', str(report + '/' + macro + '/' + tb + '/index.xml'), 'GR']
            else:
                reportdir_result[files, macro] = ['Present', str(report + '/' + macro + '/' + tb + '/index.xml'), 'Non-GR']
    else:
        if macro.endswith('_ns'):
            if (os.path.basename(files), macro[:-len('_ns')]) in excelRoot.keys():
                reportdir_result[files, macro[:-len('_ns')]] = ['Missing', str(report + '/' + macro + '/' + tb + '/index.xml'), 'GR']
            else:
                reportdir_result[files, macro[:-len('_ns')]] = ['Missing', str(report + '/' + macro + '/' + tb + '/index.xml'), 'Non-GR']
        else:
            if (os.path.basename(files), macro) in excelRoot.keys():
                reportdir_result[files, macro] = ['Missing', str(report + '/' + macro + '/' + tb + '/index.xml'), 'GR']
            else:
                reportdir_result[files, macro] = ['Missing', str(report + '/' + macro + '/' + tb + '/index.xml'), 'Non-GR']
    return(reportdir_result)


def report_check(selected_items, excelRoot):
    reportdir_result = {}
    report = ''
    tb = ''

    for files in selected_items:
        if 'p4_ws' in files and os.path.splitext(files)[1] == '.bbSim' and 'emir' not in files:
            try:
                calls = subprocess.check_output("grep -iE '^REPORT_DIR|^TESTBENCH' {}".format(str(files)), stderr=subprocess.STDOUT, shell=True).decode("utf-8", 'ignore').rstrip()
            except subprocess.CalledProcessError as exc:
                reportdir_result[files] = ("Check Failed. Return Code: {} {}".format(exc.returncode, exc.output))
            else:
                calls = calls.split('\n')
                calls = list(dict.fromkeys(calls))
            for check in range(len(calls)):
                if (calls[check].split()[0]).lower() == 'testbench':
                    tb = calls[check].split()[-1]
                elif (calls[check].split()[0]).lower() == 'report_dir':
                    report = calls[check].split()[-1]
                    if report.startswith('/'):
                        continue
                    else:
                        newpath = os.path.split(files)[0] + '/' + report
                        report = str(os.path.abspath(newpath))
                else:
                    tb = '<ERROR>'
                    report = '<ERROR>'
            macro = re.search("/design/sim/([a-z0-9-_.+]+)/", files, re.IGNORECASE).group(1)

            reportdir_result = dumpData(report, macro, tb, files, excelRoot, reportdir_result)
    return reportdir_result


def gr_check(hmf):
    excelRoot = {}
    hmf_Root = {}
    with open('official_golden_reference_list.csv', 'r') as csvfile:
        reader = csv.DictReader(csvfile)
        for row in reader:
            # excelRoot[bbSim File, macro name] = [ category (0), ownership (1), HMA (2), HMD (3), HME (4), DDR45LITE (5), LPDDR54 (6)]
            if row['postfix'].strip() == 'na' and row['postfix'].strip() != '':
                excelRoot[row['[GR file root name]'].strip() + '.bbSim', row['[GR Macro name]'].strip()] = [row['category'].strip(), row['ownership'].strip(), row['HMA CRR '].strip(), row['HMD CRR'].strip(), row['HME CRR'].strip(), row['DDR45LITE CRR'].strip(), row['LPDDR54 CRR'].strip(), row['DDR54 CRR'].strip()]
            elif row['postfix'].strip() == 'pre' and row['postfix'].strip() != '':
                excelRoot[row['[GR file root name]'].strip() + '_pre.bbSim', row['[GR Macro name]'].strip()] = [row['category'].strip(), row['ownership'].strip(), row['HMA CRR '].strip(), row['HMD CRR'].strip(), row['HME CRR'].strip(), row['DDR45LITE CRR'].strip(), row['LPDDR54 CRR'].strip(), row['DDR54 CRR'].strip()]
            elif row['postfix'].strip() == 'post' and row['postfix'].strip() != '':
                excelRoot[row['[GR file root name]'].strip() + '_post.bbSim', row['[GR Macro name]'].strip()] = [row['category'].strip(), row['ownership'].strip(), row['HMA CRR '].strip(), row['HMD CRR'].strip(), row['HME CRR'].strip(), row['DDR45LITE CRR'].strip(), row['LPDDR54 CRR'].strip(), row['DDR54 CRR'].strip()]
            elif row['postfix'].strip() == 'both' and row['postfix'].strip() != '':
                excelRoot[row['[GR file root name]'].strip() + '_pre.bbSim', row['[GR Macro name]'].strip()] = [row['category'].strip(), row['ownership'].strip(), row['HMA CRR '].strip(), row['HMD CRR'].strip(), row['HME CRR'].strip(), row['DDR45LITE CRR'].strip(), row['LPDDR54 CRR'].strip(), row['DDR54 CRR'].strip()]
                excelRoot[row['[GR file root name]'].strip() + '_post.bbSim', row['[GR Macro name]'].strip()] = [row['category'].strip(), row['ownership'].strip(), row['HMA CRR '].strip(), row['HMD CRR'].strip(), row['HME CRR'].strip(), row['DDR45LITE CRR'].strip(), row['LPDDR54 CRR'].strip(), row['DDR54 CRR'].strip()]

    GR = {'HMA': 2, 'HMD': 3, 'HME': 4, 'DDR45LITE': 5, 'LPDDR54': 6, 'DDR54': 7}
    hmf_gr = {'gr_hma': 'HMA', 'gr_hmd': 'HMD', 'gr_hme': 'HME', 'gr_ddr45lite': 'DDR45LITE', 'gr_lpddr54': 'LPDDR54', 'gr_ddr54': 'DDR54'}
    for bbSimFile in excelRoot:
        if excelRoot[bbSimFile][GR[hmf]] != '' and excelRoot[bbSimFile][GR[hmf]] != 'na':
            hmf_Root[bbSimFile] = hmf_gr[excelRoot[bbSimFile][GR[hmf]]]
    return hmf_Root


def makeTree(default_hmf, excelRoot, dependentFiles):
    fTable = collections.defaultdict(dict)
    for files in dependentFiles:
        if '.bbSim' in files:
            # excelRoot[bbSim File] = [macro name (0), category (1), ownership (2), HMA (3), HMD (4), HME (5), DDR45LITE (6), LPDDR54 (7)]

            if dependentFiles[files][0].endswith('_ew'):
                if (os.path.basename(files), dependentFiles[files][0].replace('_ew', '_ns')) in excelRoot.keys():
                    # print(excelRoot[os.path.basename(files)])
                    fTable[os.path.basename(files), dependentFiles[files][0].replace('_ew', '_ns')] = ['GR', excelRoot[os.path.basename(files), dependentFiles[files][0].replace('_ew', '_ns')], files]
                    populateTree(fTable, dependentFiles, files, excelRoot[os.path.basename(files), dependentFiles[files][0].replace('_ew', '_ns')])
                elif (os.path.basename(files), dependentFiles[files][0].replace('_ew', '')) in excelRoot.keys():
                    # print(excelRoot[os.path.basename(files)])
                    fTable[os.path.basename(files), dependentFiles[files][0].replace('_ew', '')] = ['GR', excelRoot[os.path.basename(files), dependentFiles[files][0].replace('_ew', '')], files]
                    populateTree(fTable, dependentFiles, files, excelRoot[os.path.basename(files), dependentFiles[files][0].replace('_ew', '')])
                else:
                    fTable[os.path.basename(files), dependentFiles[files][0]] = ['Non-GR', default_hmf, files]
                    populateTree(fTable, dependentFiles, files, default_hmf)
            else:
                if (os.path.basename(files), dependentFiles[files][0]) in excelRoot.keys():
                    # print(excelRoot[os.path.basename(files)])
                    fTable[os.path.basename(files), dependentFiles[files][0]] = ['GR', excelRoot[os.path.basename(files), dependentFiles[files][0]], files]
                    populateTree(fTable, dependentFiles, files, excelRoot[os.path.basename(files), dependentFiles[files][0]])
                else:
                    fTable[os.path.basename(files), dependentFiles[files][0]] = ['Non-GR', default_hmf, files]
                    populateTree(fTable, dependentFiles, files, default_hmf, dependentFiles)
    return fTable


def populateTree(finTab, depFiles, files, hmf, dependentFiles):
    for dependent in depFiles[files][1]:
        if dependent[0] == 'M':
            finTab[os.path.basename(dependent[1]), dependentFiles[files][0]] = ['Missing', hmf, dependent[1]]
        else:
            try:
                if depFiles[str(dependent[1])][1]:
                    if any(str(dependent[1]) in sublist for sublist in depFiles[str(dependent[1])][1]):
                        finTab[os.path.basename(dependent[1]), dependentFiles[files][0]] = ['Present', hmf, dependent[1]]
                        continue
                    else:
                        populateTree(finTab, depFiles, dependent[1], hmf)
            except KeyError:
                finTab[os.path.basename(dependent[1]), dependentFiles[files][0]] = ['Present', hmf, dependent[1]]
                continue
            else:
                finTab[os.path.basename(dependent[1]), dependentFiles[files][0]] = ['Present', hmf, dependent[1]]


# files[filename, macro] = ['Present/Missing/GR/Non-GR', hmf, fullpath]

def setup_scratch(username, password):
    try:
        code = subprocess.call('wget -O official_golden_reference_list.xlsx --user={} --password={} {}'.format(str(username), str(password), str(GCFG['GR_XLSX'])), shell=True, stdout=open(os.devnull, 'wb'), stderr=open(os.devnull, 'wb'))
    except ValueError:
        print(Fore.RED + "Sorry, I didn't understand that.")
    if code == 0:
        with xlrd.open_workbook('official_golden_reference_list.xlsx') as wb:
            sh = wb.sheet_by_index(0)  # or wb.sheet_by_name('name_of_the_sheet_here')
            with open('official_golden_reference_list.csv', 'w+') as f:
                c = csv.writer(f)
                for r in range(sh.nrows):
                    c.writerow(sh.row_values(r))
        print(Fore.GREEN + 'CSV Generated.')
        return 1
    else:
        print(Fore.RED + 'Login Failed. Check Password/Sharepoint Access.')
        return 0


def percentage(part, whole):
    return round((100 * float(part) / float(whole)), 1)


def usage():
    print(Fore.RED + 'Usage: {} -m <check_type> -f <family>'.format(sys.argv[0]))
    print(Fore.RED + ' -m  = [PRE|POST|FULL]')
    print(Fore.RED + ' -f  = [HMA|HMD|HME|DDR45LITE|LPDDR54|DDR54]')
    print('Examples:')
    print(Fore.GREEN + '{} -m PRE -f HMA'.format(sys.argv[0]))
    print(Fore.GREEN + '{} -m FULL -f LPDDR54'.format(sys.argv[0]))


GCFG = {}
hmf_options = ['HMA', 'HMD', 'HME', 'DDR45LITE', 'LPDDR54', 'DDR54']
mode_options = ['pre', 'post', 'full']
GCFG['GR_XLSX'] = 'https://sp-sg/sites/msip-eddr/proj/eddra/ckt/Shared%20Documents/Golden%20Reference%20All%20Hard%20Macro%20Families/GR_official/official_golden_reference_list.xlsx'
GCFG['username'] = getpass.getuser()
GCFG['HMA'] = '//wwcad/msip/projects/alpha/y006-alpha-sddrphy-ss14lpp-18/rel_gr_hma'
GCFG['HMD'] = '//wwcad/msip/projects/ddr43/d523-ddr43-ss10lpp18/rel_gr_hmd'
GCFG['HME'] = '//wwcad/msip/projects/lpddr4xm/d551-lpddr4xm-tsmc16ffc18/rel_gr_hme'
GCFG['DDR45LITE'] = '//wwcad/msip/projects/ddr54/d589-ddr45-lite-tsmc7ff18/rel_gr_ddr45lite'
GCFG['LPDDR54'] = '//wwcad/msip/projects/lpddr54/d859-lpddr54-tsmc7ff18/rel_gr_lpddr54'
GCFG['DDR54'] = '//wwcad/msip/projects/ddr54/d809-ddr54-tsmc7ff18/rel_gr_ddr54'

# exit if script not run in design sim directory

if not os.getcwd().endswith('/design/sim'):
    print(Fore.RED + "Please run the script inside <project_path>/design/sim\n")
    sys.exit()

try:
    opts, args = getopt.getopt(sys.argv[1:], 'f:m:h', ['hmf=', 'mode=', 'help'])
except getopt.GetoptError:
    usage()
    sys.exit(2)

# print("opts: {}, args: {}" .format(opts, args))

if opts:
    for opt, arg in opts:
        if opt in ('-h', '--help'):
            usage()
            sys.exit(2)
        elif opt in ('-m', '--mode'):
            if arg.lower() in mode_options:
                mode = arg.lower()
            else:
                usage()
                sys.exit(2)
        elif opt in ('-f', '--hmf'):
            if arg.upper() in hmf_options:
                hmf = arg.upper()
            else:
                usage()
                sys.exit(2)
        else:
            usage()
            sys.exit(2)
else:
    usage()
    sys.exit(2)

login_attempts = 4

while login_attempts > 0:
    login_attempts -= 1
    if login_attempts == 0:
        print(Back.LIGHTRED_EX + 'Terminating Script .... ')
        sys.exit()
    else:
        GCFG['password'] = getpass.getpass('Enter password for {}: '.format(GCFG['username']))
        run = setup_scratch(GCFG['username'], GCFG['password'])
        if run:
            break
        else:
            continue


if __name__ == '__main__':
    main()
