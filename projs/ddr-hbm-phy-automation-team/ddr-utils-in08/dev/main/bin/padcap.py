#!/depot/Python/Python-3.8.0/bin/python -E

import subprocess
import sys
import getpass
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


def main():
    username = getpass.getuser()
    filename = sys.argv[1]

    print("Running....")

    try:
        allFiles = subprocess.check_output("grep -i ' BP_' {} | grep -vF ':' ".format(filename), shell=True).decode("utf-8").rstrip()
    except subprocess.CalledProcessError as e:
        raise RuntimeError("command '{}' return with error (code {}): {}".format(e.cmd, e.returncode, e.output))
    else:
        allFiles = allFiles.split('\n')

    padcaps = {}

    for files in allFiles:
        padcaps[re.split(r'\s+', files)[0]] = re.split(r'\s+', files)[1]

    # for keys in padcaps:
    #     print keys, " : ", padcaps[keys]

    try:
        allCons = subprocess.check_output("grep -A1 -B2 '^*CONN' {}" .format(filename), shell=True).decode("utf-8").rstrip()
    except subprocess.CalledProcessError as e:
        raise RuntimeError("command '{}' return with error (code {}): {}".format(e.cmd, e.returncode, e.output))
    else:
        allCons = allCons.split('\n')

    dnet = {}

    for cons in range(len(allCons)):
        if allCons[cons].startswith('*D_NET'):
            # dnet["*" + (re.search(".*\*([a-z0-9-_.+]+)\:.*", allCons[cons+3], re.IGNORECASE).group(1))] = re.split('\s+', allCons[cons])[2]
            dnet[((allCons[cons + 3].split())[1].split(":"))[0]] = re.split(r'\s+', allCons[cons])[2]
        else:
            continue

    report = open('pad_cap_{}.csv' .format(str(filename)), 'w+')
    report.write('Signal,DNET Value\n')

    for keys in dnet:
        if keys in padcaps.keys():
            report.write("{},{},\n" .format(padcaps[keys], dnet[keys]))

    report.close()

    subprocess.call('echo "Signal Pad Cap Script Summary:\n-----------------------------------------------\nUser: {}\n-----------------------------------------------\n\nPlease find the report attached." | mail -s "signal pad cap report {}" -a pad_cap_{}.csv {}@synopsys.com' .format(str(username), str(filename), str(filename), str(username)), shell=True)

    print("Done.")


if __name__ == '__main__':
    main()
