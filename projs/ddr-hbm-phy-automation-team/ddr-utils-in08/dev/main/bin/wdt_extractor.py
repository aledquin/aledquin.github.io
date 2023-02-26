#!/depot/Python/Python-3.8.0/bin/python -E
# Batch extracts 'wdt_ascii' files from .tar.gz files
import subprocess
import os
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


allFiles = []

print("Running...")


def findFiles():
    for path, subdirs, files in os.walk(os.getcwd()):
        for name in files:
            filename = os.path.join(path, name)
            if os.path.basename(filename).endswith('.tar.gz') or os.path.basename(filename).endswith('.tar'):
                allFiles.append(filename)
        return(allFiles)


def main():

    allFiles = findFiles()
    print('Script will extract from the following files:')
    for files in allFiles:
        print(files)

    for files in allFiles:
        if files.endswith('.tar.gz'):
            filename = os.path.basename(files)
            dirname = os.path.dirname(files)
        elif files.endswith('.tar'):
            filename = os.path.basename(files)
            dirname = os.path.dirname(files)

        fileList = ''

        try:
            lessFiles = subprocess.check_output(r"tar -ztvf {} | grep 'wdt.ascii_0\|xa.tmideg_0'".format(filename), shell=True, cwd=dirname).decode("utf-8").rstrip()  # for tar files which dont extract
        except subprocess.CalledProcessError as exc:
            print("Check Failed. Return Code: {} {}".format(exc.returncode, exc.output))
        else:
            lessFiles = lessFiles.split('\n')
            print('Following files are found for {} in {}' .format(filename, dirname))
            for files in lessFiles:
                extract = files.split()[-1]
                print(extract)
                fileList += " " + extract

        try:
            # calls = subprocess.call("tar -xvf {}{}".format(filename, fileList), stderr=subprocess.STDOUT, shell=True, cwd=dirname) # for binary file error
            subprocess.call("tar -zxvf {}{}".format(filename, fileList), stderr=subprocess.STDOUT, shell=True, cwd=dirname)
        except subprocess.CalledProcessError as exc:
            print("Check Failed. Return Code: {} {}".format(exc.returncode, exc.output))
        else:
            print('Run complete for all files for {} in {}' .format(filename, dirname))

    print('Run Complete.')
