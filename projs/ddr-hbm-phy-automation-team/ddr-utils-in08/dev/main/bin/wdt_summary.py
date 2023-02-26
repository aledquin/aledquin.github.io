#!/depot/Python/Python-3.8.0/bin/python -E


import os
import subprocess
import sys
import xlsxwriter
import getpass
import xml.etree.ElementTree as ET
import re
import pathlib

# ----------------------------------#
bindir = str(pathlib.Path(__file__).resolve().parent)
sys.path.append(bindir + '/../lib/python/Util')
sys.path.append(bindir + '/../lib/python')
# ----------------------------------#
from Misc import utils__script_usage_statistics, get_release_version
__version__ = get_release_version(bindir)

utils__script_usage_statistics(__file__, __version__)


def sort_list(list_name,n):
    list_xml = []
    for f in list_name:
        if f.endswith("_" + str(n)):
            list_xml.append(f)
    return(list_xml)


def main():  # noqa C901
    allFiles = []
    tmiFiles = []
    xmlFiles = []
    print("Running...")

    mode0 = 0
    mode1 = 0
    xmlmode0 = 0
    xmlmode1 = 0
    for path, subdirs, files in os.walk(os.getcwd()):
        for name in files:
            filename = os.path.join(path, name)
            if re.match(r".*wdt\.ascii.*",filename):
                if filename not in allFiles:
                    allFiles.append(filename)
                mode0 = 1
                mode1 = 1
            elif str(os.path.basename(filename)) == 'xa.tmideg_0' or str(os.path.basename(filename)) == 'xa.tmideg_1':
                if os.path.basename('xa.tmideg_0'):
                    mode0 = 1
                    if filename not in tmiFiles:
                        tmiFiles.append(filename)
                if os.path.basename('xa.tmideg_1'):
                    mode1 = 1
                    if filename not in tmiFiles:
                        tmiFiles.append(filename)
            elif re.match(r'.*devdt\.xml_\d+',filename):
                if filename not in xmlFiles:
                    xmlFiles.append(filename)
                xmlmode0 = 1
                xmlmode1 = 1

    dTmetal_all = {}
    dTjoul_all = {}
    dTod_all = {}
    dTcoupl_all = {}
    heatsource_all = {}
    if not allFiles:
        print('No *wdt.ascii* files found in {} and its subdirectories. Exiting ...\n' .format(str(os.getcwd())))
        sys.exit()
    else:
        for files in allFiles:
            print('Processing {} file ...'.format(files.replace(os.getcwd(), '.')))
            with open(files, 'r') as f:
                copy = False
                LineCount = 0
                for line in f:
                    LineCount += 1
                    # print('for  found for {}'.format(os.path.basename(files)))
                    device = line.strip()
                    device = re.sub(r'\(\s+(.*),\s+','(\\1,',device)
                    if device != '' and device.split() != ['um', 'uA', 'C', 'C', 'C', 'C']:
                        device = re.split(r'\s+',device.lower())
                        device = [x.strip() for x in device]
                        if device[0].startswith('metallayer'):
                            # print('MetalLayer found for {}' .format(os.path.basename(files)))
                            copy = True
                            # print('{}' .format(str(files)))
                            # print('dTmetal index: {}' .format(device.index('dtmetal')))
                            # print('dTjoul index: {}'.format(device.index('dtjoul')))
                            # print('dTod index: {}'.format(device.index('dtod')))
                            # print('dTcoupl index: {}'.format(device.index('dtcoupl')))
                            dTmetal_index = device.index('dtmetal')
                            dTjoul_index = device.index('dtjoul')
                            dTod_index = device.index('dt_heatsource')
                            dTcoupl_index = device.index('dtcoupl')
                            metallayer_index = device.index('metallayer')
                            irms_index = device.index('irms')
                            xycord_index = device.index('x/y_coord')
                            netname_index = device.index('netname')
                            nodename_index = device.index('nodename')
                            status_index = device.index('status')
                            dTmetal_all[files] = [-10000, '<METALLAYER_NONE>', '<IRMS_NONE>','<0 0>','<NETNAME_NONE>','<NODENAME_NONE>']
                            dTjoul_all[files] = [-10000, '<METALLAYER_NONE>', '<IRMS_NONE>','<0 0>','<NETNAME_NONE>','<NODENAME_NONE>']
                            dTod_all[files] = [-10000, '<METALLAYER_NONE>', '<IRMS_NONE>','<0 0>','<NETNAME_NONE>','<NODENAME_NONE>']
                            dTcoupl_all[files] = [-10000, '<METALLAYER_NONE>','<STATUS>','<IRMS_NONE>','<0 0>','<NETNAME_NONE>','<NODENAME_NONE>']
                            heatsource_all[files] = {'od_ov':[-10000,'NA','NA','NA','NA','NA','NA'],'hir_ov':[-10000,'NA','NA','NA','NA','NA','NA'],'od_conn':[-10000,'NA','NA','NA','NA','NA','NA']}
                            continue
                        elif copy:
                            try:
                                if float(device[dTmetal_index]) > float(dTmetal_all[files][0]):
                                    dTmetal_all[files][0] = device[dTmetal_index]
                                    dTmetal_all[files][1] = device[metallayer_index]
                                    dTmetal_all[files][2] = device[irms_index]
                                    dTmetal_all[files][3] = device[xycord_index]
                                    dTmetal_all[files][4] = device[netname_index]
                                    dTmetal_all[files][5] = device[nodename_index]
                            except ValueError:
                                print('dTmetal has wrong value "{}" for comparison with "{}" at line {}' .format(device[dTmetal_index], dTmetal_all[files][0], LineCount))

                            try:
                                if float(device[dTjoul_index]) > float(dTjoul_all[files][0]):
                                    dTjoul_all[files][0] = device[dTjoul_index]
                                    dTjoul_all[files][1] = device[metallayer_index]
                                    dTjoul_all[files][2] = device[irms_index]
                                    dTjoul_all[files][3] = device[xycord_index]
                                    dTjoul_all[files][4] = device[netname_index]
                                    dTjoul_all[files][5] = device[nodename_index]

                            except ValueError:
                                print('dTjoul has wrong value "{}" for comparison with "{}" at line {}'.format(device[dTjoul_index], dTjoul_all[files][0], LineCount))

                            try:
                                if float(device[dTod_index]) > float(dTod_all[files][0]):
                                    dTod_all[files][0] = device[dTod_index]
                                    dTod_all[files][1] = device[metallayer_index]
                                    dTod_all[files][2] = device[irms_index]
                                    dTod_all[files][3] = device[xycord_index]
                                    dTod_all[files][4] = device[netname_index]
                                    dTod_all[files][5] = device[nodename_index]

                            except ValueError:
                                print('dt_heatsource has wrong value "{}" for comparison with "{}" at line {}'.format(device[dTod_index], dTod_all[files][0], LineCount))

                            try:
                                if float(device[dTcoupl_index]) > float(dTcoupl_all[files][0]):
                                    dTcoupl_all[files][0] = device[dTcoupl_index]
                                    dTcoupl_all[files][1] = device[metallayer_index]
                                    dTcoupl_all[files][2] = device[irms_index]
                                    dTcoupl_all[files][3] = device[xycord_index]
                                    dTcoupl_all[files][4] = device[netname_index]
                                    dTcoupl_all[files][5] = device[nodename_index]

                            except ValueError:
                                print('dTcoupl has wrong value "{}" for comparison with "{}" at line {}'.format(device[dTcoupl_index], dTcoupl_all[files][0], LineCount))

                            try:
                                if device[status_index] != 'n/a' and float(device[dTod_index]) > float(heatsource_all[files][device[status_index]][0]):
                                    heatsource_all[files][device[status_index]][1] = device[metallayer_index]
                                    heatsource_all[files][device[status_index]][2] = device[irms_index]
                                    heatsource_all[files][device[status_index]][3] = device[xycord_index]
                                    heatsource_all[files][device[status_index]][4] = device[netname_index]
                                    heatsource_all[files][device[status_index]][5] = device[nodename_index]
                                    heatsource_all[files][device[status_index]][0] = device[dTod_index]

                            except ValueError:
                                print('dt_heatsource has wrong value "{}" for comparison with "{}" at line {}'.format(device[dTod_index], dTod_all[files][0], LineCount))

    tmideg_all = {}
    xml_list = {}
    if xmlmode0 == 1 or xmlmode1 == 1:
        for files in xmlFiles:
            root = ET.parse(files).getroot()
            filename = str(os.path.basename(files))
            maxID = 0
            maxDTmp = float(-100)
        # if os.path.basename(files).endswith('.xml_0'):
        # elif os.path.basename(files).endswith('.xml_1'):
            # f1.write('{}\t{}\t{}\t{}\n'.format("Device_ID",root[0][0].tag,root[0][1].tag,root[0][5].tag))

            for child in root:
                maxID = int(child.attrib['ID'])

            for i in range(maxID):
                if maxDTmp <= float(root[i][5].text):
                    maxDTmp = float(root[i][5].text)
            # xml_dict = {maxDTmp: {root[i][0].tag:root[i][0].text,root[i][1].tag:root[i][1].text}
            for i in range(maxID):
                if maxDTmp == float(root[i][5].text):
                    xml_list[files] = [i + 1,filename,root[i][0].text,root[i][1].text,maxDTmp]
        # for i in range(0,len(xml_list.(keys)))
    elif tmiFiles:
        if mode0 == 1 and mode1 == 1:
            f0 = open("wdt.summary_0", "w+")
            f0.write('macro         testbench         wdt_file         tmideg_file         dTmos         dTmos_instance         dTmos_model         dT_heatsource          dTod_MetalLayer         dTod_Irms\n')
            f1 = open("wdt.summary_1", "w+")
            f1.write('macro         testbench         wdt_file         tmideg_file         dTmos         dTmos_instance         dTmos_model         dT_heatsource          dTod_MetalLayer         dTod_Irms\n')
        elif mode0 == 0 and mode1 == 1:
            f1 = open("wdt.summary_1", "w+")
            f1.write('macro         testbench         wdt_file         tmideg_file         dTmos         dTmos_instance         dTmos_model         dT_heatsource          dTod_MetalLayer         dTod_Irms\n')
        elif mode0 == 1 and mode1 == 0:
            f0 = open("wdt.summary_0", "w+")
            f0.write('macro         testbench         wdt_file         tmideg_file         dTmos         dTmos_instance         dTmos_model         dT_heatsource          dTod_MetalLayer         dTod_Irms\n')
        elif mode0 == 0 and mode1 == 0:
            print('No 0/1 corner files found. Exiting ...')
            sys.exit()

        for files in tmiFiles:
            print('Processing {} file ...'.format(files.replace(os.getcwd(), '.')))
            with open(files, 'r') as f:
                for line in f:
                    device = line.strip()
                    if device != '':
                        device = device.lower().split()
                        if device[0] == '1':
                            # filename = [temp, instance, devicename]
                            # print(device[2], device[1], device[3])
                            tmideg_all[files] = [device[2], device[1], device[3]]
                            break

    workbook = xlsxwriter.Workbook('{}_wdt_summary.xlsx' .format(str(getpass.getuser())))
    worksheet = workbook.add_worksheet('{}_summary' .format(str(getpass.getuser())))

    cell_format_border = workbook.add_format()
    cell_format_border.set_border()

    cell_format_border_bold = workbook.add_format()
    cell_format_border_bold.set_bold()
    cell_format_border_bold.set_border()

    cell_format_border_red = workbook.add_format()
    cell_format_border_red.set_border()
    cell_format_border_red.set_bg_color('#F96307')

    cell_format_border_yellow = workbook.add_format()
    cell_format_border_yellow.set_border()
    cell_format_border_yellow.set_bg_color('#FFC000')

    cell_format_border_green = workbook.add_format()
    cell_format_border_green.set_border()
    cell_format_border_green.set_bg_color('#92D050')

    row = 9
    col = 4
    dTmetal_red = 0
    dTmetal_yellow = 0
    dTmetal_green = 0
    dTjoul_red = 0
    dTjoul_yellow = 0
    dTjoul_green = 0
    dTod_red = 0
    dTod_yellow = 0
    dTod_green = 0
    dTcoupl_red = 0
    dTcoupl_yellow = 0
    dTcoupl_green = 0
    allkeys = dTmetal_all.keys()

    # allkeys.sort()
    sorted(allkeys)

    for files in allkeys:
        if (str(os.path.dirname(files)) + '/xa.tmideg_0' in tmideg_all.keys()) or (str(os.path.dirname(files)) + '/xa.tmideg_1' in tmideg_all.keys()):
            tmiFile0 = str(os.path.dirname(files)) + '/xa.tmideg_0'
            tmiFile1 = str(os.path.dirname(files)) + '/xa.tmideg_1'

            if tmiFile0 in tmideg_all.keys() and tmiFile1 in tmideg_all.keys():
                if '-@_' in str(os.path.basename(files)):
                    worksheet.write(row, col - 1, str(os.path.basename(tmiFile0)), cell_format_border)
                    worksheet.write(row, col, '{} Instance: {} Model: {}'.format(tmideg_all[tmiFile0][0], tmideg_all[tmiFile0][1], tmideg_all[tmiFile0][2]), cell_format_border)

                    worksheet.write(row + 1, col - 1, str(os.path.basename(tmiFile1)), cell_format_border)
                    worksheet.write(row + 1, col, '{} Instance: {} Model: {}'.format(tmideg_all[tmiFile1][0], tmideg_all[tmiFile1][1], tmideg_all[tmiFile1][2]), cell_format_border)
                if files.endswith('_0'):
                    f0.write('{}  {}  {}  {}  {}  {}  {}  {}  {}  {}\n'.format(str(os.path.basename(os.path.dirname(os.path.dirname(os.path.dirname(files))))), str(os.path.basename(os.path.dirname(files))), str(os.path.basename(files)), str(os.path.basename(tmiFile0)), tmideg_all[tmiFile0][0], tmideg_all[tmiFile0][1], tmideg_all[tmiFile0][2], dTod_all[files][0], dTod_all[files][1], dTod_all[files][2]))
                elif files.endswith('_1'):
                    f1.write('{}  {}  {}  {}  {}  {}  {}  {}  {}  {}\n'.format(str(os.path.basename(os.path.dirname(os.path.dirname(os.path.dirname(files))))), str(os.path.basename(os.path.dirname(files))), str(os.path.basename(files)), str(os.path.basename(tmiFile1)), tmideg_all[tmiFile1][0], tmideg_all[tmiFile1][1], tmideg_all[tmiFile1][2], dTod_all[files][0], dTod_all[files][1], dTod_all[files][2]))

            elif tmiFile0 in tmideg_all.keys() and tmiFile1 not in tmideg_all.keys():
                if '-@_' in str(os.path.basename(files)):
                    worksheet.write(row, col - 1, str(os.path.basename(tmiFile0)), cell_format_border)
                    worksheet.write(row, col, '{} Instance: {} Model: {}'.format(tmideg_all[tmiFile0][0], tmideg_all[tmiFile0][1], tmideg_all[tmiFile0][2]), cell_format_border)
                if files.endswith('_0'):
                    f0.write('{}  {}  {}  {}  {}  {}  {}  {}  {}  {}\n'.format(str(os.path.basename(os.path.dirname(os.path.dirname(os.path.dirname(files))))), str(os.path.basename(os.path.dirname(files))), str(os.path.basename(files)), str(os.path.basename(tmiFile0)), tmideg_all[tmiFile0][0], tmideg_all[tmiFile0][1], tmideg_all[tmiFile0][2], dTod_all[files][0], dTod_all[files][1], dTod_all[files][2]))
            elif tmiFile0 not in tmideg_all.keys() and tmiFile1 in tmideg_all.keys():
                if '-@_' in str(os.path.basename(files)):
                    worksheet.write(row, col - 1, str(os.path.basename(tmiFile1)), cell_format_border)
                    worksheet.write(row, col, '{} Instance: {} Model: {}'.format(tmideg_all[tmiFile1][0], tmideg_all[tmiFile1][1], tmideg_all[tmiFile1][2]), cell_format_border)
                if files.endswith('_1'):
                    f1.write('{}  {}  {}  {}  {}  {}  {}  {}  {}  {}\n'.format(str(os.path.basename(os.path.dirname(os.path.dirname(os.path.dirname(files))))), str(os.path.basename(os.path.dirname(files))), str(os.path.basename(files)), str(os.path.basename(tmiFile1)), tmideg_all[tmiFile1][0], tmideg_all[tmiFile1][1], tmideg_all[tmiFile1][2], dTod_all[files][0], dTod_all[files][1], dTod_all[files][2]))

        # if str(os.path.dirname(files)) + '/xa.tmideg_0' in tmideg_all.keys() and files.endswith('_0'):
        #     tmiFile = str(os.path.dirname(files)) + '/xa.tmideg_0'
        #
        #
        # if str(os.path.dirname(files)) + '/xa.tmideg_1' in tmideg_all.keys() and files.endswith('_1'):
        #     tmiFile = str(os.path.dirname(files)) + '/xa.tmideg_1'
        #

        # if (str(os.path.dirname(files)) + '/xa.tmideg_1' not in tmideg_all.keys()) and (str(os.path.dirname(files)) + '/xa.tmideg_0' not in tmideg_all.keys()):
        #     worksheet.write(row, col - 1, '<tmideg File Not Found>', cell_format_border)
        #     worksheet.write(row, col, '<tmideg File Not Found>', cell_format_border)
        #
        #     f.write('{} <tmideg File Not Found>\n' .format(str(os.path.dirname(files)) + '/xa.tmideg_{0/1}'))
        if float(dTmetal_all[files][0]) > 5:
            # print 'No Mode: ', files
            dTmetal_red += 1
            worksheet.write(row, col - 4, str(os.path.basename(os.path.dirname(os.path.dirname(os.path.dirname(files))))), cell_format_border)
            worksheet.write(row, col - 3, str(os.path.basename(os.path.dirname(files))), cell_format_border)
            worksheet.write(row, col - 2, str(os.path.basename(files)), cell_format_border)
            worksheet.write(row, col + 1, '{} Metal: {} Irms: {}' .format(dTmetal_all[files][0], dTmetal_all[files][1], dTmetal_all[files][2]), cell_format_border_red)
            # worksheet.write(row, col + 2, '<NONE>', cell_format_border_red)

            # f.write('Filename: {} dTmos: {} Instance: {} Model: {}\n' .format(files, dTmetal_all[files][0], dTmetal_all[files][1], dTmetal_all[files][2]))

        elif 4 < float(dTmetal_all[files][0]) < 5:
            # print 'No Mode: ', files
            dTmetal_yellow += 1
            worksheet.write(row, col - 4, str(os.path.basename(os.path.dirname(os.path.dirname(os.path.dirname(files))))), cell_format_border)
            worksheet.write(row, col - 3, str(os.path.basename(os.path.dirname(files))), cell_format_border)
            worksheet.write(row, col - 2, str(os.path.basename(files)), cell_format_border)
            worksheet.write(row, col + 1, '{} Metal: {} Irms: {}' .format(dTmetal_all[files][0], dTmetal_all[files][1], dTmetal_all[files][2]), cell_format_border_yellow)

            # f.write('Filename: {} dTmos: {} Instance: {} Model: {}\n'.format(files, dTmetal_all[files][0], dTmetal_all[files][1], dTmetal_all[files][2]))

        elif float(dTmetal_all[files][0]) < 4:
            # print 'No Mode: ', files
            dTmetal_green += 1
            worksheet.write(row, col - 4, str(os.path.basename(os.path.dirname(os.path.dirname(os.path.dirname(files))))), cell_format_border)
            worksheet.write(row, col - 3, str(os.path.basename(os.path.dirname(files))), cell_format_border)
            worksheet.write(row, col - 2, str(os.path.basename(files)), cell_format_border)
            worksheet.write(row, col + 1, '{} Metal: {} Irms: {}' .format(dTmetal_all[files][0], dTmetal_all[files][1], dTmetal_all[files][2]), cell_format_border_green)

            # f.write('Filename: {} dTmos: {} Instance: {} Model: {}\n'.format(files, dTmetal_all[files][0], dTmetal_all[files][1], dTmetal_all[files][2]))
            # f.write('Filename: {} dTmos: {} Instance: {} Model: {}\n'.format(files, ))

        if float(dTjoul_all[files][0]) > 5:
            dTjoul_red += 1
            worksheet.write(row, col + 2, '{} Metal: {} Irms: {}' .format(dTjoul_all[files][0], dTjoul_all[files][1], dTjoul_all[files][2]), cell_format_border_red)
            # f.write('Filename: {} dTjoul: {} Instance: {} Model: {}\n'.format(files, dTjoul_all[files][0], dTjoul_all[files][1], dTjoul_all[files][2]))
        elif 4 < float(dTjoul_all[files][0]) < 5:
            dTjoul_yellow += 1
            worksheet.write(row, col + 2, '{} Metal: {} Irms: {}' .format(dTjoul_all[files][0], dTjoul_all[files][1], dTjoul_all[files][2]), cell_format_border_yellow)
            # f.write('Filename: {} dTjoul: {} Instance: {} Model: {}\n'.format(files, dTjoul_all[files][0], dTjoul_all[files][1], dTjoul_all[files][2]))
        elif float(dTjoul_all[files][0]) < 4:
            dTjoul_green += 1
            worksheet.write(row, col + 2, '{} Metal: {} Irms: {}' .format(dTjoul_all[files][0], dTjoul_all[files][1], dTjoul_all[files][2]), cell_format_border_green)
            # f.write('Filename: {} dTjoul: {} Instance: {} Model: {}\n'.format(files, dTjoul_all[files][0], dTjoul_all[files][1], dTjoul_all[files][2]))
        if float(dTod_all[files][0]) > 5:
            dTod_red += 1
            if re.search(r'NA',heatsource_all[files]['hir_ov'][1]):
                worksheet.write(row, col + 3, 'NA')
            else:
                worksheet.write(row, col + 3, '{} Metal: {} Irms: {}' .format(heatsource_all[files]['hir_ov'][0], heatsource_all[files]['hir_ov'][1], heatsource_all[files]['hir_ov'][2]), cell_format_border_red)

            if re.search(r'NA',heatsource_all[files]['od_ov'][1]):
                worksheet.write(row, col + 4, 'NA')
            else:
                worksheet.write(row, col + 4, '{} Metal: {} Irms: {}' .format(heatsource_all[files]['od_ov'][0], heatsource_all[files]['od_ov'][1], heatsource_all[files]['od_ov'][2]), cell_format_border_red)

            if re.search(r'NA',heatsource_all[files]['od_conn'][1]):
                worksheet.write(row, col + 5, 'NA')
            else:
                worksheet.write(row, col + 5, '{} Metal: {} Irms: {}' .format(heatsource_all[files]['od_conn'][0], heatsource_all[files]['od_conn'][1], heatsource_all[files]['od_conn'][2]), cell_format_border_red)

        elif 4 < float(dTod_all[files][0]) < 5:
            dTod_yellow += 1
            if re.search(r'NA',heatsource_all[files]['hir_ov'][1]):
                worksheet.write(row, col + 3, 'NA')
            else:
                worksheet.write(row, col + 3, '{} Metal: {} Irms: {}' .format(heatsource_all[files]['hir_ov'][0], heatsource_all[files]['hir_ov'][1], heatsource_all[files]['hir_ov'][2]), cell_format_border_yellow)

            if re.search(r'NA',heatsource_all[files]['od_ov'][1]):
                worksheet.write(row, col + 4, 'NA')
            else:
                worksheet.write(row, col + 4, '{} Metal: {} Irms: {}' .format(heatsource_all[files]['od_ov'][0], heatsource_all[files]['od_ov'][1], heatsource_all[files]['od_ov'][2]), cell_format_border_yellow)

            if re.search(r'NA',heatsource_all[files]['od_conn'][1]):
                worksheet.write(row, col + 5, 'NA')
            else:
                worksheet.write(row, col + 5, '{} Metal: {} Irms: {}' .format(heatsource_all[files]['od_conn'][0], heatsource_all[files]['od_conn'][1], heatsource_all[files]['od_conn'][2]), cell_format_border_yellow)

            # if files.endswith('_0'):
            #     f0.write('{}  {}  {}\n'.format(dTod_all[files][0], dTod_all[files][1], dTod_all[files][2]))
            # elif files.endswith('_1'):
            #     f1.write('{}  {}  {}\n'.format(dTod_all[files][0], dTod_all[files][1], dTod_all[files][2]))
        elif float(dTod_all[files][0]) < 4:
            dTod_green += 1
            if re.search(r'NA',heatsource_all[files]['hir_ov'][1]):
                worksheet.write(row, col + 3, 'NA')
            else:
                worksheet.write(row, col + 3, '{} Metal: {} Irms: {}' .format(heatsource_all[files]['hir_ov'][0], heatsource_all[files]['hir_ov'][1], heatsource_all[files]['hir_ov'][2]), cell_format_border_green)
            if re.search(r'NA',heatsource_all[files]['od_ov'][1]):
                worksheet.write(row, col + 4, 'NA')
            else:
                worksheet.write(row, col + 4, '{} Metal: {} Irms: {}' .format(heatsource_all[files]['od_ov'][0], heatsource_all[files]['od_ov'][1], heatsource_all[files]['od_ov'][2]), cell_format_border_green)
            if re.search(r'NA',heatsource_all[files]['od_conn'][1]):
                worksheet.write(row, col + 5, 'NA')
            else:
                worksheet.write(row, col + 5, '{} Metal: {} Irms: {}' .format(heatsource_all[files]['od_conn'][0], heatsource_all[files]['od_conn'][1], heatsource_all[files]['od_conn'][2]), cell_format_border_green)

        if float(dTcoupl_all[files][0]) > 5:
            dTcoupl_red += 1
            worksheet.write(row, col + 6, '{} Metal: {} Irms: {}' .format(dTcoupl_all[files][0], dTcoupl_all[files][1], dTcoupl_all[files][2]), cell_format_border_red)
            # f.write('Filename: {} dTcoupl: {} Instance: {} Model: {}\n'.format(files, dTcoupl_all[files][0], dTcoupl_all[files][1], dTcoupl_all[files][2]))
        elif 4 < float(dTcoupl_all[files][0]) < 5:
            dTcoupl_yellow += 1
            worksheet.write(row, col + 6, '{} Metal: {} Irms: {}' .format(dTcoupl_all[files][0], dTcoupl_all[files][1], dTcoupl_all[files][2]), cell_format_border_yellow)
            # f.write('Filename: {} dTcoupl: {} Instance: {} Model: {}\n'.format(files, dTcoupl_all[files][0], dTcoupl_all[files][1], dTcoupl_all[files][2]))
        elif float(dTcoupl_all[files][0]) < 4:
            dTcoupl_green += 1
            worksheet.write(row, col + 6, '{} Metal: {} Irms: {}' .format(dTcoupl_all[files][0], dTcoupl_all[files][1], dTcoupl_all[files][2]), cell_format_border_green)
            # f.write('Filename: {} dTcoupl: {} Instance: {} Model: {}\n'.format(files, dTcoupl_all[files][0], dTcoupl_all[files][1], dTcoupl_all[files][2]))

        row += 1

    if xmlmode0 == 1 or xmlmode1 == 1:
        xml_keys = xml_list.keys()
        xml_keys.sort()
        worksheet.write(row + 1, 0, 'Macro', cell_format_border_bold)
        worksheet.write(row + 1, 1, 'Testbench', cell_format_border_bold)
        worksheet.write(row + 1, 2, 'xmlFile', cell_format_border_bold)
        worksheet.write(row + 1, 3, 'dTmos', cell_format_border_bold)

        for xmlFile in xml_keys:
            worksheet.write(row + 2, col - 4, str(os.path.basename(os.path.dirname(os.path.dirname(os.path.dirname(xmlFile))))), cell_format_border)
            worksheet.write(row + 2, col - 3, str(os.path.basename(os.path.dirname(xmlFile))), cell_format_border)
            if os.path.exists("xa.devdt.xml_0") or os.path.exists("xa.devdt.xml_1"):
                worksheet.write(row + 2, col - 2, str(os.path.basename(xmlFile)), cell_format_border)
                worksheet.write(row + 2, col - 1, '{} Instance: {} Model: {}'.format(xml_list[xmlFile][4],xml_list[xmlFile][2], xml_list[xmlFile][3]), cell_format_border)
                row = row + 1

        corner_num = len(open("corners_list",'r').readlines())

        for num in range(0,corner_num):
            filename = "wdt.summary_" + str(num)
            f0 = open(filename, "w+")
            xml_file = os.getcwd() + "/xa.devdt.xml_" + str(num)
            f0.write('{}\t{}\t{}\t{}\t{}\n'.format("Device_ID","FileName","InstName","Model","dTmos"))

            f0.write('{}\t{}\t{}\t{}\t{}\n\n'.format(xml_list[xml_file][0],xml_list[xml_file][1],xml_list[xml_file][2],xml_list[xml_file][3],xml_list[xml_file][4]))

            f0.write('\n{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}\n' .format("macro","testbench","wdt_file","dTjoul","dTjoul_MetalLayer","dTjoul_x/ycoord","dTjoul_NetName","dTjoul_NodeName","dTmetal","dTmetal_MetalLayer","dTmetal_x/ycoord","dTmetal_NetName","dTmetal_NodeName"))
        for files in sort_list(allkeys,num):
            f0.write('{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}\n' .format(str(os.path.basename(os.path.dirname(os.path.dirname(os.path.dirname(files))))), str(os.path.basename(os.path.dirname(files))),str(os.path.basename(files)),dTjoul_all[files][0], dTjoul_all[files][1],dTjoul_all[files][3],dTjoul_all[files][4],dTjoul_all[files][5], dTmetal_all[files][0],dTmetal_all[files][1],dTmetal_all[files][3],dTmetal_all[files][4],dTmetal_all[files][5]))

        f0.close()

    '''if xmlmode0 == 0 and xmlmode1 == 0:
        if mode0 == 1 and mode1 == 1:
        f0.close()
        f1.close()
        elif mode0 == 0 and mode1 == 1:
        f1.close()
        elif mode0 == 1 and mode1 == 0:
        f0.close()
    else:
        if xmlmode0 ==1 and xmlmode1 == 0:
            f0.close()
        elif xmlmode0 == 0 and xmlmode1 == 1:
            f1.close()
        elif xmlmode0 == 1 and xmlmode1 == 1:
            f1.close()
        f0.close()
    '''
    worksheet.write('A1', 'Summary', cell_format_border_bold)
    worksheet.write('B1', 'Run Dir: {}' .format(str(os.getcwd())), cell_format_border)
    worksheet.write('A2', 'Category', cell_format_border_bold)
    worksheet.write('B2', '>5', cell_format_border_red)
    worksheet.write('C2', '4-5', cell_format_border_yellow)
    worksheet.write('D2', '<4', cell_format_border_green)
    worksheet.write('A3', 'dTmetal Summary', cell_format_border)
    worksheet.write('B3', dTmetal_red, cell_format_border_bold)
    worksheet.write('C3', dTmetal_yellow, cell_format_border_bold)
    worksheet.write('D3', dTmetal_green, cell_format_border_bold)
    worksheet.write('A4', 'dTjoul Summary', cell_format_border)
    worksheet.write('B4', dTjoul_red, cell_format_border_bold)
    worksheet.write('C4', dTjoul_yellow, cell_format_border_bold)
    worksheet.write('D4', dTjoul_green, cell_format_border_bold)
    worksheet.write('A5', 'dT_heatsource Summary', cell_format_border)
    worksheet.write('B5', dTod_red, cell_format_border_bold)
    worksheet.write('C5', dTod_yellow, cell_format_border_bold)
    worksheet.write('D5', dTod_green, cell_format_border_bold)
    worksheet.write('A6', 'dTcoupl Summary', cell_format_border)
    worksheet.write('B6', dTcoupl_red, cell_format_border_bold)
    worksheet.write('C6', dTcoupl_yellow, cell_format_border_bold)
    worksheet.write('D6', dTcoupl_green, cell_format_border_bold)

    worksheet.write('A9', 'Macro', cell_format_border_bold)
    worksheet.write('B9', 'Testbench', cell_format_border_bold)
    worksheet.write('C9', 'File', cell_format_border_bold)
    if tmiFiles:
        worksheet.write('D9', 'tmideg File', cell_format_border_bold)
        worksheet.write('E9', 'dTmos', cell_format_border_bold)
        worksheet.write('F9', 'dTmetal', cell_format_border_bold)
        worksheet.write('G9', 'dTjoul', cell_format_border_bold)
        worksheet.write('I8', 'dT_heatsource', cell_format_border_bold)
        worksheet.write('H9', 'HiR_ov', cell_format_border_bold)
        worksheet.write('I9', 'OD_ov', cell_format_border_bold)
        worksheet.write('J9', 'OD_conn', cell_format_border_bold)
        worksheet.write('K9', 'dTcoupl', cell_format_border_bold)
    else:
        worksheet.write('D9', 'dTmetal', cell_format_border_bold)
        worksheet.write('E9', 'dTjoul', cell_format_border_bold)
        worksheet.write('F9', 'dT_heatsource', cell_format_border_bold)
        worksheet.write('G9', 'dTcoupl', cell_format_border_bold)
    workbook.close()

    #
    #
    # for key in dTcoupl_all:
    #     print key, dTmetal_all[key], dTjoul_all[key], dTod_all[key], dTcoupl_all[key]

    print('Run Complete.\n')

    try:
        subprocess.call("libreoffice {}_wdt_summary.xlsx &" .format(str(getpass.getuser())), stderr=subprocess.STDOUT, shell=True)
    except subprocess.CalledProcessError:
        print('Error opening output files. Please check the run directory for the file {}.' .format(str(getpass.getuser())))
    else:
        pass


if __name__ == '__main__':
    main()
