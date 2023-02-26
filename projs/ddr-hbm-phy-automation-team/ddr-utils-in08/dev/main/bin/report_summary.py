#!/depot/Python/Python-3.8.0/bin/python -E
# Creates summary report of all XML simulation reports TBs in runpath

import subprocess
import os
import pandas as pd
import getpass
import pathlib
import sys
#
#


# ----------------------------------#
bindir = str(pathlib.Path(__file__).resolve().parent)
sys.path.append(bindir + '/../lib/python/Util')
sys.path.append(bindir + '/../lib/python')
# ----------------------------------#
from Misc import utils__script_usage_statistics, get_release_version
__version__ = get_release_version(bindir)

utils__script_usage_statistics(__file__, __version__)

pd.set_option('display.max_rows', 500)
pd.set_option('display.max_columns', 500)
pd.set_option('display.width', 1000)


all_reports = {}

print("Running reports file search ...")
# include = {'dwc', 'tb', 'hspice', 'simulation', 'measurements'}


def main():
    for path, subdirs, files in os.walk(os.getcwd()):
        # subdirs[:] = [d for d in subdirs if any(x in d for x in include)]
        # print subdirs
        for name in files:
            filename = os.path.join(path, name)
            if os.path.basename(filename).endswith('.xlsx'):
                file_id = filename.replace(os.getcwd() + '/', ''). replace('/simulation/measurements/tsmc7ff18_meas.xlsx', '')
                all_reports[file_id] = filename

    print("Report File Search Complete.")

    new_file = 0

    filepath = os.getcwd() + '/{}_summary.csv'.format(os.path.basename(os.getcwd()))

    for key in sorted(all_reports.keys()):
        # print(key, all_reports[key])
        if os.path.exists(all_reports[key]):
            df = pd.read_excel(all_reports[key])
            summary_table = df.tail(10).dropna(axis=1, thresh=2).transpose()
            if new_file == 0:
                fileout = open(filepath, 'w')
                fileout.write('\n{},,,,,,,,,\n'.format(key))
                fileout.close()
                summary_table.to_csv(filepath, header=False, index=False, mode='a')
                new_file = 1
            else:
                fileout = open(filepath, 'a')
                fileout.write('\n{},,,,,,,,,\n'.format(key))
                fileout.close()
                summary_table.to_csv(filepath, header=False, index=False, mode='a')

            # print(summary_table)

    try:
        subprocess.call('echo "Report Script Summary:\n-----------------------------------------------\nUser: {}\nPath: {}\n-----------------------------------------------\n\nPlease find the report attached." | mail -s "{}_run_result" -a {}_summary.csv {}@synopsys.com'.format(getpass.getuser(), str(os.getcwd()), str(os.path.basename(os.getcwd())), str(os.path.basename(os.getcwd())), getpass.getuser()), shell=True)
    except subprocess.CalledProcessError as exxc:
        print("Status : FAIL {} {}".format(exxc.returncode, exxc.output))
    else:
        print("Run Complete.")


if __name__ == '__main__':
    main()
