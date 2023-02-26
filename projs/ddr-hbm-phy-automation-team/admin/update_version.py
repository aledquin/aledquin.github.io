#!/depot/Python/Python-3.8.0/bin/python

'''
Purpose:
    To update the global VERSION string in scripts to whatever is specified by
    the caller of this script.

Args:
    --help     : To get help on this script.
    --dryrun   : To test this script without actually changing anything.
    --debug    : To enable hidden debug messages in the code
    --file     : The input file you want to update
    --version  : The value you want to change VERSION to (eg. 2022.10 )

Returns:
    Does not return anything but it does update the file if it needs to.

Updates:
  001 ljames  2022/09/22
      Created
  002 ljames  2022/10/27
      Updated perl RE to handle get_release_version() || '2022.11'
'''

import os
from os import environ
import argparse
import re
import shutil

# nolint utils__script_usage_statistics
# Set some flags that will be used in this program

IN_DRYRUN_MODE = False
DEBUG = 0
GITCMD = '/global/freeware/Linux/3.10/git-2.30.0/bin/git'
PERLCMD = '/depot/perl-5.14.2/bin/perl'

# These are the application defaults. User can override these using a
# configuration file.

USER = environ.get('USER')
HOME = environ.get('HOME')
DEF_GIT_WORKSPACE_ROOTDIR = f"{HOME}/GitLab/ddr-hbm-phy-automation-team"
DEF_CONFIG_FILE = f"{HOME}/.update_version.config"
DEF_NEW_RELEASE_VERSION = "2022.12"
DEF_FILE = "filename.ext"
SUPPORTED_LANGUAGES = ['perl', 'python', 'tcl']
VARNAMES = {
    'perl': "VERSION",
    'python': "__version__",
    'tcl': "VERSION",
}

VARS = {
    "GIT_WORKSPACE_ROOTDIR": DEF_GIT_WORKSPACE_ROOTDIR,
    "FILE": DEF_FILE,
    "CONFIG_FILE": DEF_CONFIG_FILE,
    "VERSION": DEF_NEW_RELEASE_VERSION,
}


def main():
    '''this is the application's main() function entry point'''
    global IN_DRYRUN_MODE
    global DEBUG
    global VARS

    #
    # Load in the default configuration for this script
    #
    read_config_file(DEF_CONFIG_FILE)

    #
    # Check the command line arguments.
    #
    process_cmd_line_args()

    if IN_DRYRUN_MODE is True:
        print("NOTE: Dryrun Mode is Enabled")
    if DEBUG:
        print("NOTE: Debug Mode is Enabled")

    #
    # We are going to look for "VERSION" in the file and see what it's
    # value is. If it matches VARS['VERSION'] then we leave the file alone.
    # If it does not match VARS['VERSION'] then we change it.
    # If "VERSION" is not in the file, then print a warning and leave it alone
    #
    filename = VARS['FILE']
    value = VARS['VERSION']
    language = VARS['LANGUAGE']  # ie. "perl"
    varname = VARNAMES[language]

    if not os.path.exists(filename):
        eprint(f"**ERROR**: FILE '{filename}' is not present.\n")
        exit(1)
        return

    # a temporary file is created and if any changes had to be made,
    # such as changing VERSION.  By changing this bool you can leave
    #
    cleanup_temp = True

    errors = search_and_replace(language, filename, varname, value, cleanup_temp)
    if errors:
        eprint(f"**ERROR**: Failed to find '{varname}' in '{filename}'")

    exit(0)
# end of main


def modify_line_with_version_var(oline, varname, newvalue, language):
    expressions = {
        'perl': rf"^\s*our\s+\${varname}\s*=.*['\"](\d\d\d\d\.\d\d)['\"].*;$",
        'python': rf"^\s*{varname}\s*=\s*['\"](.*)['\"].*$",
        'tcl': rf"^\s*set\s+{varname}\s*['\"](.*)['\"].*$",
    }
    modified_code_line = ''

    trimLine = oline.rstrip()
    reFound = re.search(expressions[language], trimLine)
    if reFound:
        dprint(f"Match found line is {trimLine}.")
        oldvalue = reFound.group(1)
        if oldvalue != newvalue:
            modified_code_line = oline.replace(oldvalue, newvalue)
    return modified_code_line


def process_lines(language, filename, fileh, newf, varname, value):
    lineno = 0
    updated_newfile = False
    for oline in fileh:
        lineno = lineno + 1
        if re.search(r'^\s*#', oline):  # noqa: W605
            newf.write(f"{oline}")
            continue

        updated_line = modify_line_with_version_var(oline, varname, value, language)
    
        if updated_line != "":
            dprint(f"Updated file: '{filename}'\n")
            updated_newfile = True
            oline = updated_line

        newf.write(f"{oline}")

    return updated_newfile


def search_and_replace(language, filename, varname, value, cleanup_temp):
    fileh = open(filename, 'r')
    if not fileh:
        return -1

    name = os.path.basename(filename)
    newfile = f"/tmp/{USER}_{name}.new"
    if os.path.exists(newfile):
        os.remove(newfile)

    try:
        newf = open(newfile, 'w')
    except IOError as E:
        eprint(f"Unable to open file {newfile}: {E.strerror}")
        return 1

    updated_newfile = process_lines(language, filename, fileh, newf, varname, value)

    newf.close()
    fileh.close()

    if not updated_newfile:
        os.remove(newfile)
        dprint(f"Did not find variable {varname} in '{filename}'.")
    else:
        tmpfile = f"/tmp/{name}.old"
        if IN_DRYRUN_MODE is True:
            tprint(f"copy {filename} {tmpfile}")
            tprint(f"copy {newfile}  {filename}")
        else:
            # the newfile was created and we are not in testmode. Move the
            # original file out of the way and replace it with the new file
            shutil.copyfile(filename, tmpfile)
            shutil.copyfile(newfile, filename)
            if cleanup_temp:
                os.remove(tmpfile)

    return 0  # any errors, 0=success no errors found


def iprint(astr):
    '''Prefix the given string astr with "INFO: "'''
    print(f"INFO: {astr}")

def wprint(astr):
    '''Prefix the given string astr with "WARNING: "'''
    print(f"WARNING: {astr}")

def eprint(astr):
    '''Prefix the given string astr with "ERROR: "'''
    print(f"ERROR: {astr}")

def tprint(astr):
    '''Prefix the given string astr with "DRYRUN: "'''
    print(f"DRYRUN: {astr}")


def dprint(astr):
    '''Prefix the given string astr with "DEBUG: "'''
    global DEBUG
    if DEBUG > 0:
        print(f"DEBUG: {astr}")


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


def process_cmd_line_args():
    '''
    Fills in the global variable VARS based on command line arguments.

        Parameters:
            None

        Returns:
            None
    '''
    global VARS
    global IN_DRYRUN_MODE
    global DEBUG

    my_parser = argparse.ArgumentParser(
        description='Updates the VERSION string in the specified file')

    my_parser.add_argument('-f', '--file', metavar='FILE', required=True,
                           help='File name you wish to update'
                           )
    my_parser.add_argument('-v', '--version',
                           metavar='VERSION', required=True,
                           help='The version you want to change it to.'
                                '(eg. 2022.10)'
                           )
    my_parser.add_argument('--dryrun', action='store_true',
                           help="Do not run rm, cp, git, or p4 commands"
                           )
    my_parser.add_argument('--debug', action='store_true',
                           help="Allows internal dprint() calls to work"
                           )
    my_parser.add_argument('-c', '--config', metavar='CONFIGURATION',
                           help="A config file to set required variables. "
                           f"Default is {DEF_CONFIG_FILE}"
                           )
    my_parser.add_argument('-l', '--language', metavar='LANGUAGE',
                           choices=SUPPORTED_LANGUAGES,
                           help='Specify the code language'
                           )

    args = my_parser.parse_args()

    if args.config:
        read_config_file(args.config)

    if args.file:
        VARS['FILE'] = args.file

    if args.version:
        VARS['VERSION'] = args.version

    if args.language:
        VARS['LANGUAGE'] = args.language
    else:
        file_extension = os.path.splitext(VARS['FILE'])[1].lstrip('.')
        try:
            VARS['LANGUAGE'] = {
                'pl': 'perl',
                'pm': 'perl',
                'py': 'python',
                'tcl': 'tcl'
            }[file_extension]
        except KeyError as exception:
            raise Exception(f"Cannot determine language from file extension '{file_extension}'. Please use argument --language instead.") from exception

    if args.dryrun:
        IN_DRYRUN_MODE = True

    if args.debug:
        DEBUG = 1

    return


if __name__ == "__main__":
    main()
