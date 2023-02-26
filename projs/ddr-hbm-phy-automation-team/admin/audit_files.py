#!/bin/python3.6
#
# o accept an arguments to this script that specifies the root folder
# o crawl down the directory tree looking for files 
#   o for each file 
#       - categorize it as perl,tcl,python etc...
#       - count the number of lines in the file
#       - find out how many revisions have been made for this file
#       - find the date of the last revision
#       - find out who did the last checkin to perforce
# o Display a header row followed by the information gathered per file
#   PathToFile  FileType  TotalLines  TotalRevisions  LastRevised  LastPerson
#
# Here is the URL for the p4python API
#     https://www.perforce.com/manuals/p4python/p4python.pdf 
#
# History:
#   001     ljames      6/17/2022
#           Handle some edge conditions so the script does not crash.
#   002     ljames      6/17/2022
#           Add GitLab column. Shows the path of the script under our GitLab
#           repository.
#
import os
from os import environ
from pathlib import Path
import re
import sys
import argparse
import subprocess

#------------------------------------------------------------------------------
#  Global Variables
#------------------------------------------------------------------------------

P4_ROOT_DEFAULT = '/slowfs/us01dwt2p893/ljames/p4_ws/wwcad/msip/alpha_common/'
VISITED = {} # Hash table to hold 'p4 files' results per filename
DEBUG = False

gitlab_dir = '/u/ljames/GitLab/ddr-hbm-phy-automation-team'
#gitlab_dir = '/tmp/ljames/gitlab/ddr-hbm-phy-automation-team'
gitlab_dict = {}
build_the_gitlab_table = True 

#------------------------------------------------------------------------------

def main():
    global DEBUG

    my_parser = argparse.ArgumentParser(description='Audit changes in perforce')
    my_parser.add_argument( '-r', '--root' 
        , metavar='P4_ROOT'
        , required=False
        , type=str
        , default=P4_ROOT_DEFAULT
        , help = 'The starting directory. Somewhere in your p4 workspace'
    )
    my_parser.add_argument( '-d', '--debug' 
        , action='store_true'
        , help = 'Enable Debug Messages'
    )
    args = my_parser.parse_args()

    if ( args.debug ):
        DEBUG = True

    if ( not requirements_ok( args.root ) ):
        eprint('Failed requirements')
        exit(-1)
    
    dprint( f"root_folder is {args.root }" )

    #
    # The following files should not even get looked at,
    # also some of these are binary files so how many lines
    # it has doesn't make sense.
    #
    skip_list = [   '.git',  '__pycache__', '.pptx', '.xls'
                  , '.xlsx'
                  , '.xlsm', '.vsdx',       '.jpg',  '.log'
                  , '.tar',  '.oa',         '.tag',  '.docx' 
                  , '.pdf',  '.pyc',        '.Linux', 'README' ]
    files_found = gather_all_files( args.root, skip_list )
    print("FileName, Git, User, Ext, nLines, P4-Rev, P4-Date, P4-CL")
    for file_name in files_found:
        file_extension = get_extension( file_name)
        gitlab_dir     = get_gitlab_dir( file_name )
        line_count     = get_total_lines( file_name)
        revision_count = get_total_revisions( args.root, file_name)
        last_rev_num   = get_last_rev_number( args.root, file_name)
        last_rev_date  = get_last_rev_date( args.root, file_name)
        change_number  = get_change_number( args.root, file_name)
        last_person    = get_last_person_who_checked_in( args.root, file_name)
        print(f"{file_name}, {gitlab_dir}, {last_person}, {file_extension}, {line_count}, {revision_count}, {last_rev_date}, {change_number}")

def requirements_ok( root_folder : str ) -> int:
    requirements_passed = True
    required_envs = [ 'P4PORT', 'P4CLIENT', 'P4CONFIG']
    for env in required_envs:
        if None == environ.get(env):
            eprint(f"Missing a required env variable '{env}'!")
            requirements_passed = False

    if not os.path.isdir( root_folder ):
        eprint(f"The P4_ROOT='{root_folder}' you are using is not present or not a directory.")
        requirements_passed = False
        
    return requirements_passed

def gather_all_files(root_folder: str, skip_list: list ) -> list:
    list_of_filenames = []
    for root, dirs, files in os.walk( root_folder ):
        pattern_found = False
        for pattern in skip_list:
            if pattern in root:
                pattern_found = True
        if pattern_found:
            continue
        for filename in files:
            pattern_found = False
            for pattern in skip_list:
                if pattern in filename:
                    pattern_found = True
            if pattern_found:
                continue
            list_of_filenames.append( root + '/' + filename )
    return list_of_filenames

def get_gitlab_dir(file_name: str ) -> str:
    global build_the_gitlab_table
    global gitlab_dict

    if build_the_gitlab_table:
        build_the_gitlab_table = False
        construct_gitlab_file_dict()
    #print(f"get_gitlab_dir '{file_name}' key")
    fname = os.path.basename( file_name )
    if gitlab_dict.get(fname) == None:
        return "None" 
    else:
        dirpath = os.path.dirname( gitlab_dict[fname] )
        # we can trim the path down even more by removing /dev/main
        trimmed = dirpath.partition("/dev/main") 
        return trimmed[0]

def construct_gitlab_file_dict():
    global gitlab_dict
    global gitlab_dir

    cwd = os.getcwd()
    os.chdir( gitlab_dir )
    cmd = f"git ls-files {gitlab_dir}"
    stream = os.popen( cmd )
    output = stream.read()
    parts_list = output.split()
    for filename in parts_list:
        if re.search( 'users/', filename ):
            continue
        fname = os.path.basename( filename )
        gitlab_dict[fname] = filename
    os.chdir(cwd)

def get_extension(file_name: str ) -> str:
    extension = os.path.splitext( file_name )[1]
    return extension

def get_total_lines(file_name: str ) -> int :
    total_lines = 0
    try:
        afile = open(file_name, "r")
        for line in afile:
            total_lines += 1
        afile.close()
    except:
        eprint(f"File open('{file_name}') Failed");
    
    return total_lines


#
# returns a list [ date, user ]
#
def p4_filelog(root: str, file_name: str, rev: str) -> list:
    # To run p4 commands you need to be in your perforce root
    cwd = os.getcwd()
    os.chdir(root)
    rev_spec = f"#{rev}"
    p4exe = '/remote/cad-rep/msip/tools/bin/p4'
    p4op  = 'filelog'

    cmd = f"{p4exe} {p4op} -m 2 {file_name}{rev_spec}"
    
    stream = os.popen( cmd )
    output = stream.read()
    dprint(f"The command {cmd} returned {output}")
    parts_list = output.split()
    if parts_list:
        dprint(f"The parts_list is {parts_list}")
        date = parts_list[7]
        user = parts_list[9]
        dprint(f"date={date} user={user}")
    else:
        date = "?"
        user = "?"

    return [ date, user ]

#
# These are indexes into the returned list from p4_files()
#
K_FNAME  = 0
K_REV    = 1
K_CHANGE = 2
K_ACTION = 3
K_DATE   = 4
K_USER   = 5

# Example output of 'p4 files' command
#   //wwcad/msip/projects/alpha/alpha_common/bin/stanSiSFlow.pl#12 - edit change 3314396 (text+x)
#
# returns a list [ fname, rev_number, change_list, action, date, user ]
#
def p4_files(root: str, file_name: str) -> list:
    global VISITED

    if file_name in VISITED:
        return VISITED[file_name]

    # To run p4 commands you need to be in your perforce root
    cwd = os.getcwd()
    dprint(f"Current working directory is: {cwd}")
    os.chdir( root )
    dprint(f"changed directory to {root}")
    cmd = f"p4 files {file_name}"
    dprint(f"Issuing command: {cmd}")
    
    stream = os.popen( cmd )
    output = stream.read()
    dprint(f"The command {cmd} returned {output}")
    parts_list = output.split()
    if parts_list:
        file_and_rev = parts_list[0].split('#')
        action = parts_list[2] # add, edit, delete, branch, etc
        change_list = parts_list[4]
    else:
        file_and_rev = ["?","?"]
        action = "?"
        change_list = "?"

    # To get even more information we can use p4 filelog
    if file_and_rev != "?":
        filelog_list = p4_filelog(root, file_name, file_and_rev[1])
        date = filelog_list[0]
        user = filelog_list[1]
    else:
        date = "?"
        user = "?"

    VISITED[file_name] = [file_and_rev[0], file_and_rev[1], change_list, action, date, user]
    return VISITED[file_name] 
    
def get_change_number(root: str, file_name: str ) -> str:
    p4_info_list = p4_files(root, file_name)
    return p4_info_list[K_CHANGE]

def get_total_revisions(root: str, file_name: str ) -> str:
    p4_info_list = p4_files(root, file_name)
    return p4_info_list[K_REV]

def get_last_rev_number(root: str, file_name: str ) -> str:
    p4_info_list = p4_files(root, file_name)
    return p4_info_list[K_REV] 

def get_last_rev_date(root: str, file_name: str ) -> str:
    p4_info_list = p4_files(root, file_name)
    return p4_info_list[K_DATE]

def get_last_person_who_checked_in(root: str, file_name: str ) -> str:
    p4_info_list = p4_files(root, file_name)
    userName = p4_info_list[K_USER]
    # p4 usernames are actually USERNAME@P4_REPO, I want to strip off '@...'
    parts = userName.partition("@")

    return parts[0] 

#-----------------------------------------------------------------------------
# Some Utility Functions
#-----------------------------------------------------------------------------


def what_script_am_i() -> str:
    return os.path.realpath(__file__)

def dprint(*args, **kwargs):
    if DEBUG==True:
        print("-DEBUG- ", file=sys.stderr, end='', flush=True)
        print(*args, file=sys.stderr, **kwargs)
        
def eprint(*args, **kwargs):
    print("-E- ", file=sys.stderr, end='', flush=True)
    print(*args , file=sys.stderr, **kwargs)

#-----------------------------------------------------------------------------
# run main(), this is the standard way of doing this in python
#-----------------------------------------------------------------------------

if __name__ == "__main__":
    main()

