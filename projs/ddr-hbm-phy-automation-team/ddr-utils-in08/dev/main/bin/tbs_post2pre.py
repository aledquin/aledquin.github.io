#!/depot/Python/Python-3.8.0/bin/python -E
# Developed by Dikshant Rohatgi(dikshant@synopsys.com)
import subprocess
import os
import re
import sys
from colorama import init, Fore
import glob
import shutil
import getopt
import pathlib
import time

# sys.setdefaultencoding('utf8')
init(autoreset=True)


# ----------------------------------#
bindir = str(pathlib.Path(__file__).resolve().parent)
sys.path.append(bindir + '/../lib/python/Util')
sys.path.append(bindir + '/../lib/python')
# ----------------------------------#
from Misc import utils__script_usage_statistics, get_release_version
__version__ = get_release_version(bindir)

utils__script_usage_statistics(__file__, __version__)

path = os.getcwd()
path = path + '/bbSim/*.bbSim'
bbSim_files = glob.glob(path)
path = os.getcwd()
flag = 0
dat = 0


def usage():
    print('The script is used to convert Post bbSim files to pre bbSim.')
    print('To convert dat file, use -d option')


try:
    opts, args = getopt.getopt(sys.argv[1:], 'h:d', ['help','dat'])
except getopt.GetoptError:
    usage()
    sys.exit(2)


if opts:
    for opt, arg in opts:
        if opt in ('-h', '--help'):
            usage()
            sys.exit(2)
        elif opt in ('-d', '--dat'):
            dat = 1


def main():    # noqa C901
    logFile = path + "/post2pre.log"
    log = open(logFile,'w')
    print('\033[1m' + '\t\t\t\t\tStarting Post to Pre conversion')
    log.write('\t\t\t\t\tStarting Post to Pre conversion\n')
    time.sleep(3)
    for files in bbSim_files:
        filename = os.path.basename(files)
        if re.search(r'_post\.bbSim|_post_mc\.bbSim|_post_monte\.bbSim',filename):
            nfile = re.sub(r'post','pre',filename)
            if os.path.isfile(path + '/bbSim/' + nfile) is False:
                print(Fore.LIGHTMAGENTA_EX + "-I- Couldn't find {} , creating it".format(nfile))
                log.write("-I- Couldn't find {} , creating it\n".format(nfile))
                shutil.copy(files,path + '/bbSim/' + nfile)
                nfile = path + '/bbSim/' + nfile
                fin = open(nfile,'r')
                content = fin.readlines()
                for index,line in enumerate(content):
                    if re.search(r'^testbench',line,re.IGNORECASE):
                        content[index] = re.sub(r'post','pre',line)
                    elif re.search(r'^spice|ADD_CORNERS.*',line,re.IGNORECASE):
                        content[index] = re.sub(r'post','pre',line)
                        spfile = re.split(r'\s+',line.strip())[-1]
                        if re.search(r'^spice',line,re.I):
                            spfilepath = path + "/" + spfile if re.search(r'circuit',spfile) else path + '/circuit/' + spfile
                        elif re.search(r'ADD_CORNERS.*',line,re.I):
                            spfilepath = path + "/" + spfile if re.search(r'corners',spfile) else path + '/corners/' + spfile
                        nspfile = re.sub(r'post','pre',spfilepath)
                        if os.path.isfile(spfilepath) is True:
                            shutil.copy(spfilepath,nspfile)
                            flag = 1
                            subprocess.Popen(['sed','-i','s/post/pre/g',nspfile],stderr=subprocess.PIPE,stdout=subprocess.PIPE).communicate()
                            if dat == 1:
                                fsp = open(nspfile,'r')
                                sp_content = fsp.readlines()
                                for sindex,sline in enumerate(sp_content):
                                    if re.search(r'include.*\.dat',sline):
                                        #                                    sp_content[sindex] = re.sub(r'post','pre',sline)
                                        dat_filename = re.split(r'\s+',sline.strip())[-1]
                                        dat_filename = re.sub(r'\'+','',dat_filename)
                                        if re.search(r'circuit\/project',dat_filename):
                                            dat_filename = dat_filename.split('/')[-1]
                                        if re.search('pre',dat_filename):
                                            dat_filename = re.sub('pre','post',dat_filename)
                                        newdat_filename = re.sub(r'post','pre',dat_filename)
                                        print(Fore.YELLOW + "-I_ Creating new dat file , Please check {}/circuit/project/{}".format(path,newdat_filename))
                                        log.write("-I_ Creating new dat file , Please check {}/circuit/project/{}\n".format(path,newdat_filename))
                                        try:
                                            shutil.copy(path + '/circuit/project/' + dat_filename, path + '/circuit/project/' + newdat_filename)
                                        except FileNotFoundError:
                                            print(Fore.LIGHTRED_EX + "-E- Couldn't find {}".format(path + '/circuit/project/' + dat_filename))
                                            log.write("-E- Couldn't find {}\n".format(path + '/circuit/project/' + dat_filename))
                                        sp_content[sindex] = re.sub(r'post','pre',sline)
                                        break
                                fout = open(nspfile,'w')
                                fout.writelines(sp_content)
                                fout.close()
                        else:
                            print(Fore.LIGHTRED_EX + "-W- Couldn't find {}, Skipping bbSim file\n".format(spfilepath))
                            log.write("-W- Couldn't find {}, Skipping bbSim file\n".format(spfilepath))
                            flag = 0
                    elif re.search(r'^include|^plot',line,re.I) and re.search(r'post',line,re.I):
                        content[index] = re.sub(r'post','pre',line)
                        spfile = re.split(r'\s+',line.strip())[-1]
                        if re.search(r'^include',line,re.I):
                            flag = 1
                            spfilepath = path + "/" + spfile if re.search(r'circuit',spfile) else path + '/include/' + spfile
                        elif re.search(r'plot.*',line,re.I):
                            flag = 1
                            spfilepath = path + "/" + spfile if re.search(r'corners',spfile) else path + '/bbSim/plot/' + spfile
                        nspfile = re.sub(r'post','pre',spfilepath)
                        if os.path.isfile(spfilepath) is True:
                            shutil.copy(spfilepath,nspfile)
                            if re.search(r'plot.*',line,re.I):
                                subprocess.Popen(['sed','-i','s/post/pre/g',nspfile],stderr=subprocess.PIPE,stdout=subprocess.PIPE).communicate()

                if flag == 1:
                    fo = open(nfile,'w')
                    for c in content:
                        fo.write(c)
                    fo.close()
                    print(Fore.GREEN + "-I- Created file {}\n".format(nfile))
                    log.write("-I- Created file {}\n".format(nfile))
                    time.sleep(0.5)

    log.close()


if __name__ == '__main__':
    main()
