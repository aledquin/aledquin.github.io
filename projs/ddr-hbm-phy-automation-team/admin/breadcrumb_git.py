#!/depot/Python-3.6.2/bin/python3.6
'''
Purpose:
  To gather list of commits created since the last major release of a tool.
  This script will also look at the commit messages to look for jira
  numbers and list those at the end of the generated report file.

Args:
    --help     : To get help on this script.
    --testmode : To test this script without actually changing anything.
    --debug    : To enable hidden debug messages in the code
    --config   : Read a config file to update the global VARS list
    --out      : Where to write out the breadcrumb file
    --tool     : One of ddr-ckt-rel, ddr-utils, ddr-utils-in08, etc...
    -l         : Last release tag; This is how this script finds the commits.

Returns:
    Does not return anything but it does write out a file.

Updates:
  001 ljames  YYYY/MM/DD
      Created
  002 ljames  2022/05/13
      The git commands lines are now all tool specific.
'''

import os
from os import environ
import argparse
import re
import datetime
import subprocess

# Set some flags that will be used in this program

IN_TEST_MODE = 0
DEBUG = 0
GITCMD = '/global/freeware/Linux/3.10/git-2.30.0/bin/git'


# These are the application defaults. User can override these using a
# configuration file.

USER = environ.get('USER')
HOME = environ.get('HOME')
DEF_GIT_WORKSPACE_ROOTDIR = f"{HOME}/GitLab/ddr-hbm-phy-automation-team"
DEF_CONFIG_FILE = f"{HOME}/.breadcrumb_git.config"
DEF_LAST_RELEASE_TAG = "ddr-ckt-rel-2022.05"
DEF_TOOL = "ddr-ckt-rel"
DEF_OUTPUT_FILE = ".bread"

VARS = {
    "GIT_WORKSPACE_ROOTDIR": DEF_GIT_WORKSPACE_ROOTDIR,
    "TOOL": DEF_TOOL,
    "LAST_RELEASE_TAG": DEF_LAST_RELEASE_TAG,
    "OUTPUT_FILE": DEF_OUTPUT_FILE,
}


def main():
    '''this is the application's main() function entry point'''
    global IN_TEST_MODE
    global DEBUG
    global VARS

    if environ.get('INSTALL_IS_IN_TEST_MODE') is not None:
        IN_TEST_MODE = 1

    #
    # Load in the default configuration for this script
    #

    read_config_file(DEF_CONFIG_FILE)

    #
    # Check the command line arguments.
    #
    process_cmd_line_args()

    if IN_TEST_MODE == 1:
        print("\nNOTE: Test Mode is Enabled\n")
    if DEBUG:
        print("\nNOTE: Debug Mode is Enabled\n")

    # Going from GitLab tool to p4 area. Create the breadcrumb files
    # in the gitlab area; before copying files to Shelltools

    last_release_tag = VARS['LAST_RELEASE_TAG']
    commit_number = get_last_commit_number(
        VARS['GIT_WORKSPACE_ROOTDIR'],
        VARS['TOOL']
    )
    if commit_number == - 1:
        eprint("Unable to get lastest commit number!")
        exit(1)

    todays_date = get_todays_date()
    files_since = get_files_changed_since_last_release_tag(
        VARS['GIT_WORKSPACE_ROOTDIR'],
        VARS['TOOL'],
        commit_number,
        last_release_tag)
    jira_stories = get_jira_story_numbers(files_since)
    output_file = VARS['OUTPUT_FILE']

    write_breadcrumb(output_file, last_release_tag, commit_number,
                     todays_date, files_since, jira_stories)

    exit(0)
# end of main


def write_breadcrumb(filename, lr, cn, td, fs, js=""):
    '''Given an output filename, writes out the breadcrumb data'''
    f = open(filename, 'w')
    f.write(f"LastRelease {lr}\n")
    f.write(f"ThisCommit {cn}\n")
    f.write(f"TodaysDate {td}\n")
    f.write(f"AllCommits\n{fs}\n")
    f.write("JiraStories\n\n")
    for jnum in js:
        f.write(f"\t{jnum}\n")
    f.close()
    print(f"Created breadcrumb {filename}")


def read_config_file(filename):
    '''Given a config filename, this updates the global VARS'''
    global VARS

    if not os.path.exists(filename):
        if filename != DEF_CONFIG_FILE:
            print(f"\n**ERROR**: CONFIG_FILE '{filename}' is not present.\n")
            exit(1)
        return

    # The config file format is simply NAME value
    #
    # TOOL ddr-ckt-rel
    # LAST_RELEASE_TAG ddr-ckt-rel-YYYY.MM[-PATCH]
    #
    fileh = open(filename, 'r')
    for line in fileh:
        # skip comment lines
        if re.search('^\s*#', line):  # noqa: W605
            continue
        line_list = line.split()
        if len(line_list) == 2:
            VARS[line_list[0]] = line_list[1]
    fileh.close()
    return


def get_last_commit_number(git_root, tool):
    '''Returns the last commit sha1 hash value'''
    info = run_command_output(f"cd {git_root} ; {GITCMD} log -1 --stat {tool}")
    if info == "":
        eprint("get_last_commit_number failed")
        return -1

    commit_number = info.split()
    return commit_number[1].rstrip()


def get_todays_date():
    '''Returns todays date using syntax YEAR-MONTH-DAY'''
    today = datetime.date.today()
    return f"{today.year}-{today.month}-{today.day}"


def get_files_changed_since_last_release_tag(git_root, tool, last_commit,
                                             previous_tag):
    prev_commit = run_command_output(
        f"cd {git_root}; {GITCMD} rev-list -n 1 {previous_tag} {tool}")
    if prev_commit == "":
        eprint("Problem in get_files_changed_since_last_release_tag")
        return ""

    outstr = run_command_output(f"cd {git_root}; {GITCMD} log --oneline {prev_commit.rstrip()}..{last_commit} {tool}")
    return outstr


def get_jira_story_numbers(commits):
    '''given a list of commit strings, returns a list of Jira Ids'''
    all_jiras = re.findall('P10020416-\d+\s?', commits)  # noqa: W605
    all_jiras = map(str.strip, all_jiras)
    res_list = list(set(all_jiras))
    return(res_list)


def run_command(command_str):
    '''Invokes the given command_str command via os.system() call'''
    dprint(command_str)
    return os.system(command_str)


def run_command_output(command_str, nlines=1):
    dprint(f"system '{command_str}'")
    try:
        ret = subprocess.check_output(
            command_str, shell=True, universal_newlines=True)
    except:  # noqa: E722
        eprint(f"Failed system command {command_str}")
        return ""

    dprint(f"out> '{ret}'")
    return ret


def iprint(astr):
    '''Prefix the given string astr with "INFO: "'''
    print(f"INFO: {astr}")


def eprint(astr):
    '''Prefix the given string astr with "ERROR: "'''
    print(f"ERROR: {astr}")


def dprint(astr):
    '''Prefix the given string astr with "DEBUG: "'''
    global DEBUG
    if DEBUG > 0:
        print(f"DEBUG: {astr}")


def update_VARS():
    '''update the global VARS based on other VARS, if needed'''
    global VARS
    pass


def process_cmd_line_args():
    '''
    Fills in the global variable VARS based on command line arguments.
    
        Parameters:
            None

        Returns:
            None
    '''
    global VARS
    global IN_TEST_MODE
    global DEBUG

    my_parser = argparse.ArgumentParser(
        description='Create a breadcrumb file that contains all commits since'
        ' last release')

    my_parser.add_argument('--testmode', action='store_true',
                           help="Do not run cp, git, and p4 commands"
                           )
    my_parser.add_argument('--debug', action='store_true',
                           help="Allows internal dprint() calls to work"
                           )
    my_parser.add_argument('-c', '--config', metavar='CONFIGURATION',
                           required=False, type=str,
                           help="A config file to set required variables. "
                           f"Default is {DEF_CONFIG_FILE}"
                           )
    my_parser.add_argument('-o', '--out', metavar='OUTPUT_FILE',
                           required=False, type=str,
                           help=f"Where (filename) to write the breadcrumb "
                                f"out. Default is {DEF_OUTPUT_FILE}"
                           )
    my_parser.add_argument('-t', '--tool', metavar='TOOL', required=False,
                           type=str,
                           help='Tool name you wish to get breadcrumb info for'
                                '(eg. ddr-ckt-rel)'
                           )
    my_parser.add_argument('-l', '--last_release_tag',
                           metavar='LAST_RELEASE_TAG', required=False,
                           type=str,
                           help='The Git Tag of the last release for this tool'
                                '(eg. ddr-ckt-rel-2022.05)'
                           )
    args = my_parser.parse_args()

    if args.config:
        read_config_file(args.config)

    if args.out:
        VARS['OUTPUT_FILE'] = args.out
        update_VARS()

    if args.tool:
        VARS['TOOL'] = args.tool
        update_VARS()

    if args.last_release_tag:
        VARS['LAST_RELEASE_TAG'] = args.last_release_tag
        update_VARS()

    if args.testmode:
        IN_TEST_MODE = 1

    if args.debug:
        DEBUG = 1

    return


if __name__ == "__main__":
    main()
