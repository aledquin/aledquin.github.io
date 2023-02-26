#!/depot/Python-2.7.6/bin/python
import re,os
import subprocess
import sys,getopt,collections
from colorama import init, Fore, Back, Style

def utils__script_usage_statistics (toolname, version):
    prefix   = 'ddr-da-alpha_common-'
    reporter = '/remote/cad-rep/msip/tools/bin/msip_get_usage_info';
    cmd      =  [reporter, '--tool_name',  prefix+toolname, '--stage', 'main', '--category', 'ude_ext_1', '--tool_path', 'NA', '--tool_version', version]
    subprocess.run(cmd)

utils__script_usage_statistics( "defQA", "2022ww12")


def usage():
    print(Fore.LIGHTGREEN_EX + 'Usage: {} -c|-crr <crr file path>'.format(sys.argv[0]))
    print(Fore.CYAN + 'The script will sync all the def files mentioned in the crr file.\nScript flags all DEF instances with invalid coordinates\nScript flags all DEF instances that do not have a corresponding DEF file sub-cell or LIB/LEF sub-cell\nScript also flags all LIB/LEF cells that we not specified in any DEF file')
    print('Examples:')
    print(Fore.GREEN + '{} -c ckt_release_1.00a_pre1_crr.txt'.format(sys.argv[0]))

def main():
    try:
        opts,args = getopt.getopt(sys.argv[1:],"c:hnd:",["crr=","help","nosync","dFile="])
    except getopt.GetoptError:
        sys.exit(2)
    

    crrFile = ""
    nsync = False
    dFile = ""
    if opts:
        for opt,arg in opts:
            if opt in ('-c','--crr'):
                crrFile = arg
            elif opt in ('-d','--dFile'):
                if os.path.isfile(arg) == False:
                    print(Back.RED + "-E- Couldn't find {} file.\n Please check the file path\n".format(arg))
                    sys.exit(2)
                else:
                    dFile = arg
            elif opt in ('-n','--nosync'):
                if any('-d' in lst for lst in opts) or any('--d' in lst for lst in opts):
                    nsync = True
                else:
                    print(Back.RED + "-E- -d or --dFile option not used with {}. \nPlease run the script again with -d option and provide a file that contains paths for user's DEF file.\n".format(opt))
                    sys.exit(2)
            elif opt in ('-h','--help'):
                usage()
                sys.exit(2)
            else:
                print(Back.RED + "-E- Wrong args,Exiting")
                sys.exit(2)        
    else:
        print(Back.RED + "-E- Wrong args,pleae add -c or --crr option. Exiting")
        sys.exit(2)
    
    if     os.path.isfile(crrFile) == False:
        print("-E- {} is not a file,exiting".format(crrFile) + Style.RESET_ALL)
        sys.exit()
    libs = []
    defs = collections.defaultdict(dict)
    defs['Names'] = []
    defs['Paths'] = []
    lefs = []

    log = open("DefQA.log",'w')
    log.write("\t\t\t\t\t\tWelcome to DEF QA\n") 
    print("\t\t\t\t\t\tWelcome to DEF QA\n")
    with open(crrFile,'r') as crr:
        for line in crr:
            line = line.strip()
            if re.search(r'.+\.lib#\d+',line):
                libName = re.split('\s+',line)[-1]
                libName = re.match('\'(.+)#\d+\'',libName).group(1)
                libName = libName.split('/')[-1]
                libs.append(libName)
            elif re.search(r'.+\.def#\d+',line) and nsync == False:                 
                defName = re.split('\s+',line)[-1]
                defName = re.match('\'(.+)#\d+\'',defName).group(1)
                defBase = defName.split('/')[-1]
                defs['Paths'].append(defName)
                if re.search('_inst',defBase):
                    defBase = defBase.replace('_inst.def','')
                else:
                    defBase = defBase.replace('.def','')
                defs['Names'].append(defBase)
            elif re.search(r'.+\.lef#\d+',line):
                lefName = re.split('\s+',line)[-1]
                lefName = re.match('\'(.+)#\d+\'',lefName).group(1)
                lefName = lefName.split('/')[-1]
                lefs.append(lefName)
    if nsync:
        with open(dFile,'r') as df:
            for line in df:
                line = line.strip()
                if re.search(r'.+\.def',line) and nsync == True:                 
                    defName = re.split('\s+',line)[-1]
                    defName = re.match('(.+)',defName).group(1)
                    defBase = defName.split('/')[-1]
                    defs['Paths'].append(defName)
                    if re.search('_inst',defBase):
                        defBase = defBase.replace('_inst.def','')
                    else:
                        defBase = defBase.replace('.def','')
                    defs['Names'].append(defBase)
    
    defLefs = collections.defaultdict(dict)            
    if len(defs['Paths']) == 0:
        print("-E- Couldn't find any def file instance in {}.. Exiting\n".format(crrFile))
        log.write("-E- Couldn't find any def file instance in {}.. Exiting\n".format(crrFile))
        exit()
    elif len(libs) == 0:
        print("-E- Couldn't find any lib file instance in {}.. Exiting\n".format(crrFile))
        log.write("-E- Couldn't find any lib file instance in {}.. Exiting\n".format(crrFile))
        exit()
    elif len(lefs) == 0:
        print("-E- Couldn't find any lef file instance in {}.. Exiting\n".format(crrFile))
        log.write("-E- Couldn't find lef lib file instance in {}.. Exiting\n".format(crrFile))
        exit()
    
    lefs = [i for i in lefs if not re.search(r'merged',i)]
    for defFile in defs['Paths']:
        if nsync == False:
            filename = os.path.basename(defFile)
            con = os.popen("p4 where {}".format(defFile)).read().strip()
            remoteFile = re.split(r'\s+',con)[-1]
            if os.path.isfile(remoteFile) == False:
                print("-W- Couldn't find {} file in user P4 area,Syncing it\n".format(filename))
                log.write("-W- Couldn't find {} file in user P4 area,Syncing it\n".format(filename))
                op = subprocess.Popen(['p4','sync','-f',defFile],stdout = subprocess.PIPE,stderr = subprocess.PIPE).communicate()
                if re.search(r'no such file',op[-1],re.IGNORECASE):
                    print("-E- Couldn't sync {} file //depot. Please check the file name\n".format(filename))
                    log.write("-E- Couldn't sync {} file //depot. Please check the file name\n".format(filename))
                    continue
                else:
                    print("-I- Sync successful for file {}\n".format(filename))
                    log.write("-I- Sync successful for file {}\n".format(filename))
        else:
            filename = defFile
            remoteFile = defFile    
        print("-I- Checking {}\n".format(filename))
        log.write("-I- Checking {}\n".format(filename))
        if os.path.isfile(remoteFile) == False and nsync == False:
            print("-E- Couldn't find {},Please sync it manually\n".format(remoteFile))
            log.write("-E- Couldn't find {},Please sync it manually\n".format(remoteFile))
            continue
        elif os.path.isfile(remoteFile) == False and nsync == False:
            print("-E- Couldn't find {},Please provide correct filepath in {}\n".format(remoteFile,dFile))
            log.write("-E- Couldn't find {},Please provide correct filepath in {}\n".format(remoteFile,dFile))
            continue
        
        
        defLefs[filename] = []
        check = True
        try:
            dff = open(remoteFile,'r')
        except IOError:
            print("-E- Couldn't open {},Please check file presense\n".format(remoteFile))
            log.write("-E- Couldn't open {},Please check file presense \n".format(remoteFile))
            continue
        for line in dff.readlines():
            if line != '' and line.startswith('-'):
                subblock = line.split(' ')[2].strip()
                sublef = subblock + '.lef'
                if re.search('_top',subblock):
                    subdef = subblock.replace('_top','')                    
                if sublef in defLefs[filename]:
                    continue
                defLefs[filename].append(sublef)
                if subblock+'.lef' not in lefs and subblock+'.lib' not in libs and subdef not in defs['Names']:
                    log.write("-E- Couldn't find {} file from {} in {}\n".format(subblock,defFile,crrFile))
                    print("-E- Couldn't find {} file from {} in {}\n".format(subblock,defFile,crrFile))
                    check = False
                if re.search(r'.+fixed|placed|cover.+\(\d+\s+\d+\).+',line,re.IGNORECASE) == None:
                    log.write("-E- Found {} sub block with missing coordinates in {} file\n".format(subblock,defFile))
                    print("-E- Found {} sub block with missing coordinates in {} file\n".format(subblock,defFile))
                    check = False
                        
        if check == True:
            log.write("-I- {} DEF file is clean with all sub-block instances present in {} with valid coordinates\n".format(filename,crrFile))
            print("-I- {} DEF file is clean with all sub-block instances present in {} with valid coordinates\n".format(filename,crrFile))
                
                


    check = False
    for lef in lefs:
        for files in defLefs.keys():
            if lef in defLefs[files]:
                check = True
                break
            else:
                check = False
        if check == False:
            print("-E- {} file from CRR File not found in any def file\n".format(lef))
            log.write("-E- {} file from CRR File not found in any def file\n".format(lef))

        


if __name__ == "__main__":
    main() 
