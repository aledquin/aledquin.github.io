#!/depot/Python/Python-3.8.0/bin/python -E
# Reports the finesim mode (spicead/hd) in .sp file
import subprocess
import xlsxwriter
import os
import pathlib
import sys
# dir = os.listdir(os.getcwd())


# ----------------------------------#
bindir = str(pathlib.Path(__file__).resolve().parent)
sys.path.append(bindir + '/../lib/python/Util')
sys.path.append(bindir + '/../lib/python')
# ----------------------------------#
from Misc import utils__script_usage_statistics, get_release_version
__version__ = get_release_version(bindir)

utils__script_usage_statistics(__file__, __version__)


def fileExtract():
    only_sp_files = [f for f in os.listdir(os.getcwd()) if os.path.isfile(os.path.join(os.getcwd(), f)) and (os.path.splitext(os.path.join(os.getcwd(), f))[1]).lower() == '.sp' and 'emir' not in f.lower() and 'xara' not in f.lower()]

    failed_files = {}

    for files in only_sp_files:
        try:
            calls = subprocess.check_output("grep -ni '^.option finesim_mode' {}".format(str(files)), stderr=subprocess.STDOUT, shell=True).decode("utf-8").rstrip()
        except subprocess.CalledProcessError:
            # print("Check Failed. Return Code: {} {} {}".format(files, exc.returncode, exc.output))
            failed_files[files] = ['No FineSim Mode']
        else:
            calls = calls.split('\n')
            if len(calls) > 1:
                result = list()
                for option in range(len(calls)):
                    calls[option] = calls[option].replace(' ', '')
                    calls[option] = calls[option].lower()
                    mode = calls[option].split('=')[-1]
                    linenum = calls[option].split(':')[0]
                    result.append([str(linenum), str(mode)])
                failed_files[files] = ['FineSim Mode set more than once', result]

            # print files, ":", calls
            else:
                calls = calls[0].replace(" ", "")
                calls = calls.lower()
                mode = calls.split('=')[-1]
                linenum = calls.split(':')[0]
                if str(mode.lower()) == 'spicead' or str(mode.lower()) == 'spicehd':
                    failed_files[files] = ['FineSim Mode spicead/spicehd', [linenum, mode]]

                else:
                    failed_files[files] = ['FineSim Mode not spicead/spicehd', [linenum, mode]]
    return(failed_files)


def main():

    failed_files = fileExtract()
    workbook = xlsxwriter.Workbook('spice_mode.xlsx')
    worksheet = workbook.add_worksheet('FineSim Mode')

    cell_format_border = workbook.add_format()
    cell_format_border.set_border()

    cell_format_border_bold = workbook.add_format()
    cell_format_border_bold.set_bold()
    cell_format_border_bold.set_border()

    cell_format_border_red = workbook.add_format()
    cell_format_border_red.set_border()
    cell_format_border_red.set_bg_color('red')

    cell_format_border_yellow = workbook.add_format()
    cell_format_border_yellow.set_border()
    cell_format_border_yellow.set_bg_color('yellow')

    cell_format_border_green = workbook.add_format()
    cell_format_border_green.set_border()
    cell_format_border_green.set_bg_color('green')

    row = 8
    col = 0

    error = 0
    double = 0
    wrong = 0
    correct = 0

    for files in failed_files:
        if failed_files[files][0] == 'No FineSim Mode':
            # print 'No Mode: ', files
            error += 1
            worksheet.write(row, col, files, cell_format_border)
            worksheet.write(row, col + 1, '-', cell_format_border_red)
            worksheet.write(row, col + 2, '<NONE>', cell_format_border_red)
            row += 1
        elif failed_files[files][0] == 'FineSim Mode set more than once':
            double += 1
            # print 'More than once: ', files
            worksheet.write(row, col, files, cell_format_border)
            for name in failed_files[files][1]:
                worksheet.write(row, col + 1, name[0], cell_format_border_yellow)
                worksheet.write(row, col + 2, name[1], cell_format_border_yellow)
                row += 1
                # print 'Line: ', name[0], 'Mode: ', name[1]
        elif failed_files[files][0] == 'FineSim Mode not spicead/spicehd':
            # print 'File Not AD/HD: ', files, 'Line: ', failed_files[files][1][0], 'Mode: ', failed_files[files][1][1]
            wrong += 1
            worksheet.write(row, col, files, cell_format_border)
            worksheet.write(row, col + 1, failed_files[files][1][0], cell_format_border_red)
            worksheet.write(row, col + 2, failed_files[files][1][1], cell_format_border_red)
            row += 1
        elif failed_files[files][0] == 'FineSim Mode spicead/spicehd':
            # print 'File AD/HD: ', files, 'Line: ', failed_files[files][1][0], 'Mode: ', failed_files[files][1][1]
            correct += 1
            worksheet.write(row, col, files, cell_format_border)
            worksheet.write(row, col + 1, failed_files[files][1][0], cell_format_border_green)
            worksheet.write(row, col + 2, failed_files[files][1][1], cell_format_border_green)
            row += 1

    worksheet.write('A1', 'Summary', cell_format_border_bold)
    worksheet.write('B1', str(os.getcwd()), cell_format_border)
    worksheet.write('A2', 'Files with no FineSim Mode', cell_format_border)
    worksheet.write('B2', error, cell_format_border_bold)
    worksheet.write('A3', 'Files with FineSim Mode set more than once', cell_format_border)
    worksheet.write('B3', double, cell_format_border_bold)
    worksheet.write('A4', 'Files with FineSim Mode not spicead/spicehd', cell_format_border)
    worksheet.write('B4', wrong, cell_format_border_bold)
    worksheet.write('A5', 'Files with FineSim Mode as spicead/spicehd', cell_format_border)
    worksheet.write('B5', correct, cell_format_border_bold)

    worksheet.write('A8', 'Filename', cell_format_border_bold)
    worksheet.write('B8', 'Line Number', cell_format_border_bold)
    worksheet.write('C8', 'Mode', cell_format_border_bold)

    workbook.close()

    try:
        subprocess.call("libreoffice spice_mode.xlsx &", stderr=subprocess.STDOUT, shell=True)
    except subprocess.CalledProcessError as exc:
        print("Open Failed. Please close all instances of Libreoffice before running script. Return Code: {} {}".format(exc.returncode, exc.output))
        # failed_files[files] = ['No FineSim Mode']
    else:
        print("Run Complete.")


if __name__ == '__main__':
    main()
