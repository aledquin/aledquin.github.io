#!/depot/Python/Python-3.8.0/bin/python -E
# Creates VT drift summary report for RXREPLICA
import pandas
import os
import sys
import getopt
import xlsxwriter
import re
import subprocess
from colorama import init, Fore
import pathlib
init(autoreset=True)

# pandas.set_option('display.max_rows', 500)
# pandas.set_option('display.max_columns', 500)
# pandas.set_option('display.width', 1000)


# ----------------------------------#
bindir = str(pathlib.Path(__file__).resolve().parent)
sys.path.append(bindir + '/../lib/python/Util')
sys.path.append(bindir + '/../lib/python')
# ----------------------------------#
from Misc import utils__script_usage_statistics, get_release_version
__version__ = get_release_version(bindir)

utils__script_usage_statistics(__file__, __version__)


def usage():
    print(Fore.RED + 'Usage: {} -m <check_type> -t <boost_mode> -p <path>'.format(sys.argv[0]))
    print(Fore.RED + ' -m  = [pre|post]')
    print(Fore.RED + ' -t  = [boost|nonboost]')
    print(Fore.RED + ' -f  = [path to rxreplica report directory]')
    print('Examples:')
    print(Fore.GREEN + '{} -m pre  -t boost    -p /slowfs/us01dwt2p374/lpddr54/d859-lpddr54-tsmc7ff18/rel_gr_lpddr54/documentation/reports/project/dwc_ddrphy_rxreplica_ns'.format(sys.argv[0]))
    print(Fore.GREEN + '{} -m post -t nonboost -p {}'.format(sys.argv[0], os.getcwd()))


mode_options = ['pre', 'post']
type_options = ['boost', 'nonboost']
options = ['lpd5_50voh', 'lp4x_60voh', 'lp4x_50voh', 'lpd4_33voh', 'lpd4_40voh']

try:
    opts, args = getopt.getopt(sys.argv[1:], 'p:m:t:h', ['path=', 'mode=', 'type=', 'help'])
except getopt.GetoptError:
    usage()
    sys.exit(2)

if opts:
    for opt, arg in opts:
        if opt in ('-h', '--help'):
            usage()
            sys.exit(2)
        elif opt in ('-m', '--mode') and arg.lower() in mode_options:
            mode = arg.lower()
        elif opt in ('-t', '--type') and arg.lower() in type_options:
            b_mode = arg.lower()
            if arg.lower() == 'boost':
                boost_mode = '0'
            elif arg.lower() == 'nonboost':
                boost_mode = '1'
            else:
                print(Fore.CYAN + 'Incorrect Boost Mode specified')
                usage()
                sys.exit(2)
        elif opt in ('-p', '--path') and os.path.exists(arg):
            report_path = arg
        else:
            usage()
            sys.exit(2)
else:
    usage()
    sys.exit(2)

try:
    mode
except NameError:
    print(Fore.CYAN + "Mode not defined.")
    usage()
    sys.exit(2)

try:
    boost_mode
except NameError:
    print(Fore.CYAN + "Boost Mode not defined.")
    usage()
    sys.exit(2)
try:
    report_path
except NameError:
    print(Fore.CYAN + "Report Path not defined.")
    usage()
    sys.exit(2)


def findFiles(report_path, all_reports):
    for path, subdirs, files in os.walk(report_path):
        for name in files:
            filename = os.path.join(path, name)
            if 'tb_rxreplica_' in str(filename).lower() and os.path.basename(filename).endswith('meas.html') and 'vtdrift_tap0_' in str(filename).lower() and mode in str(filename).lower():
                filetype = next(element for element in filename.split('/') if 'tb_' in element)
                result = re.search('tb_rxreplica_(.*)_vtdrift_tap0_*', filetype).group(1)
                if result in options:
                    all_reports[result] = filename
            if set(all_reports.keys()) == set(options):
                break


def main():
    all_reports = {}

    print("Running HTML file search ...")
    (all_reports, all_reports) = findFiles(report_path, all_reports)
    print("HTML File Search Complete.")

    # print(all_reports.keys())

    # for keys in all_reports:
    #     print("{}:\n{} " .format(keys, all_reports[keys]))

    master_dict = {}
    mos_type = ['mos_sf', 'mos_fs', 'mos_ss', 'mos_tt', 'mos_ff']

    workbook = xlsxwriter.Workbook('rxreplica_vtdrift_{}_{}_report.xlsx' .format(b_mode, mode))
    worksheet_summary = workbook.add_worksheet('Summary')

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
    cell_format_border_merge.set_bg_color('lime')

    worksheet_summary.merge_range('A1:F1', 'VT_track_error_tap0_vddql ({} summary)'.format(b_mode), cell_format_border_merge)
    worksheet_summary.merge_range('A8:F8', 'VT_track_error_tap0_vddqh ({} summary)'.format(b_mode), cell_format_border_merge)
    worksheet_summary.write('A2', 'Process', cell_format_border_bold)
    worksheet_summary.write('A9', 'Process', cell_format_border_bold)

    column = 0

    for files in all_reports:
        # tables = pandas.read_html(os.path.basename(all_reports[files]), header=1) # Windows Test Options
        tables = pandas.read_html(all_reports[files], header=1)
        cleaned_table = tables[1].dropna(thresh=10).drop_duplicates().reset_index(drop=True)
        cleaned_table.drop(cleaned_table[cleaned_table['Process'] == 'Process'].index, inplace=True)

        row = 1

        for mos in mos_type:
            master_dict[files, mos, 'vddql'] = cleaned_table[(cleaned_table['code0'] == boost_mode) & (cleaned_table['code1'] == boost_mode) & (cleaned_table['mos'] == mos)]['VT_track_error_tap0_vddql (ps)'].values[0]
            master_dict[files, mos, 'vddqh'] = cleaned_table[(cleaned_table['code0'] == boost_mode) & (cleaned_table['code1'] == boost_mode) & (cleaned_table['mos'] == mos)]['VT_track_error_tap0_vddqh (ps)'].values[0]

            if row == 1:
                worksheet_summary.write(row, column + 1, '{}'.format(files), cell_format_border_bold)
                worksheet_summary.write(row + 7, column + 1, '{}'.format(files), cell_format_border_bold)

            if column == 0:
                worksheet_summary.write(row + 1, column, '{}'.format(mos), cell_format_border_bold)
                worksheet_summary.write(row + 8, column, '{}'.format(mos), cell_format_border_bold)

            worksheet_summary.write(row + 1, column + 1, '{}'.format(master_dict[files, mos, 'vddql']), cell_format_border)
            worksheet_summary.write(row + 8, column + 1,'{}'.format(master_dict[files, mos, 'vddqh']), cell_format_border)

            row += 1
        column += 1

    workbook.close()

    # for dix in sorted(master_dict.keys()):
    #     print('{}: {}' .format(dix, master_dict[dix]))

    try:
        subprocess.call('libreoffice rxreplica_vtdrift_{}_{}_report.xlsx &' .format(b_mode, mode), stderr=subprocess.STDOUT, shell=True)
    except subprocess.CalledProcessError as exc:
        print("Open Failed. Please close all instances of Libreoffice before running script. Return Code: {} {}".format(exc.returncode, exc.output))
        # failed_files[files] = ['No FineSim Mode']
    else:
        print(Fore.GREEN + "Run Complete.")


if __name__ == '__main__':
    main()
