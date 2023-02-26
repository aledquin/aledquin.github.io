#!/bin/python3.6
#
# Usage:
#       release_shelltools_dev_to_version [-t TOOLNAME] [-v VERSION] [-c CONFIG]
#
# Arguments:
#
#   TOOLNAME: 
#       Optional, this script will read the name of your tool from your 
#       config file or will default to ddr-ckt-rel and will prompt you and 
#       allow you to change the tool name.
#                 
# Description:
#
# Notes:
#
#   You can put the entire script into TESTMODE by setting an env variable.
#
#   $ setenv INSTALL_IS_IN_TEST_MODE
#
# Author:  James Laderoute
# Created: 3/24/2022
#
#-
import os
from os import environ
import sys
import argparse
import glob
import re
from pathlib import Path

##############################################################################
# STEP #0:  setup some variables to point to your p4_ws areas
##############################################################################

# Set some flags that will be used in this program

P4_IN_EDIT_MODE = 0
IN_TEST_MODE    = 0
DEBUG           = 0

# These are the application defaults. User can override these using a
# configuration file.

USER    = environ.get('USER')
HOME    = environ.get('HOME')
LAST_CD = ""

DEF_P4_WORKSPACE_ROOTDIR    = f"/u/{USER}/p4_ws"
DEF_TOOL                    = "ddr-ckt-rel"
DEF_SHELLTOOLS              = 'wwcad/msip/internal_tools/Shelltools'
DEF_MODULEFILES             = 'wwcad/msip/internal_tools/modulefiles'
DEF_REL_VERSION             = 'YYYY.MM[-PATCH]'
DEF_P4_SHELLTOOLS_TOOL_ROOT = f"{DEF_P4_WORKSPACE_ROOTDIR}/{DEF_SHELLTOOLS}/{DEF_TOOL}"
DEF_P4_SOURCE_TOOL_ROOT     = f"{DEF_P4_SHELLTOOLS_TOOL_ROOT}/dev/main"
DEF_P4_TARGET_TOOL_ROOT     = f"{DEF_P4_SHELLTOOLS_TOOL_ROOT}/releases/{DEF_REL_VERSION}"
DEFAULT_CONFIG_FILE         = f"{HOME}/.release_shelltools_dev_to_version.config"

VARNAMES                = { 
        "P4_WORKSPACE_ROOTDIR":DEF_P4_WORKSPACE_ROOTDIR,
        "TOOL":DEF_TOOL, 
        "REL_VERSION":DEF_REL_VERSION, 
        "P4_SHELLTOOLS_TOOL_ROOT":DEF_P4_SHELLTOOLS_TOOL_ROOT, 
        "P4_SOURCE_TOOL_ROOT": DEF_P4_SOURCE_TOOL_ROOT,
        "P4_TARGET_TOOL_ROOT": DEF_P4_TARGET_TOOL_ROOT,
    }

REQUIRED_DIRS = [
        'P4_WORKSPACE_ROOTDIR'
        ]

ALLOWED_TO_MODIFY = [ 
        'P4_WORKSPACE_ROOTDIR',
        'TOOL',
        'REL_VERSION',
        ] 

def main():
    global VARNAMES
    global IN_TEST_MODE
    global DEBUG
   
    # convert path P4_WORKSPACE_ROOTDIR to an absolute path name
    VARNAMES["P4_WORKSPACE_ROOTDIR"] = get_abs_path( VARNAMES["P4_WORKSPACE_ROOTDIR"] )
    update_varnames()

    if environ.get('INSTALL_IS_IN_TEST_MODE') != None:
        IN_TEST_MODE = 1

    #
    # Load in the default configuration for this script
    #

    read_config_file( DEFAULT_CONFIG_FILE )

    #
    # Check the command line arguments. 
    #
    process_cmd_line_args()

    if IN_TEST_MODE == 1:
        print("\nNOTE: Test Mode is Enabled\n")
    if DEBUG:
        print("\nNOTE: Debug Mode is Enabled\n")

    print( "*-------- Verifying Settings --------*")

    user_verify_settings()

    #
    # Now verify that the specified directories actually exist.
    #
    verify_root_dirs_exist()

    ##############################################################################
    # STEP #1 -- update P4 by doing a p4 sync
    ##############################################################################

    sync_p4()

    ##############################################################################
    # STEP #2 - See if any files are currently locked
    ##############################################################################

    p4_any_locked_files()

    ##############################################################################
    # STEP #3 - start copying the TOOL's files 
    ##############################################################################

    copy_dev_to_releases()

    ##############################################################################
    # STEP #4 - Update the modules area
    ##############################################################################

    has_error = update_shelltools_modules()
    if has_error:
        eprint("You will need to fixup the modulefiles area by hand.")
            

    ##############################################################################
    #  STEP #5 - Submit your changes
    ##############################################################################

    submit_changes()

    ##############################################################################
    # STEP #6 - Notify folks about the installation
    ##############################################################################

    # TBD: we can use Email or maybe there is an API I can use to put it into
    #      Teams...  Or maybe we should have a JIRA ticket to request a release
    #      and I believe there is an API to JIRA where we can then update the
    #      Story when the install is done.

    email_status()
    print("Done.\n")
    print_settings()
    # end of Main

def update_varnames():
    global VARNAMES
    
    p4_workspace_rootdir    = VARNAMES['P4_WORKSPACE_ROOTDIR']
    tool                    = VARNAMES['TOOL']
    shelltools              = DEF_SHELLTOOLS
    rel_version             = VARNAMES['REL_VERSION']
    p4_shelltools_tool_root = f"{p4_workspace_rootdir}/{shelltools}/{tool}"

    VARNAMES['P4_SHELLTOOLS_TOOL_ROOT'] = p4_shelltools_tool_root
    VARNAMES['P4_SOURCE_TOOL_ROOT']     = f"{p4_shelltools_tool_root}/dev/main"
    VARNAMES['P4_TARGET_TOOL_ROOT']     = f"{p4_shelltools_tool_root}/releases/{rel_version}"

def update_shelltools_modules():

    ws_root      = VARNAMES['P4_WORKSPACE_ROOTDIR']
    modulefiles  = DEF_MODULEFILES 
    tool         = VARNAMES['TOOL']
    version      = VARNAMES['REL_VERSION']
    return_stat  = 0
    modules_area = f"{ws_root}/{modulefiles}/{tool}"
    path_hidden_tool    = f"{modules_area}/.{tool}"
    hidden_tool         = f".{tool}"
    path_ver_symlink    = f"{modules_area}/{version}"
    ver_symlink         = f"{version}"
    hidden_version_file = f"{modules_area}/.version"
    last_cd             = LAST_CD
    
    print("\nThis script is now making sure that the /modulefiles/ area is correct.\n")
    cd( modules_area )

    if not os.path.exists( modules_area ):
        eprint(f"Missing modulesfiles area {modules_area}")
        cd( last_cd )
        return 1
    if not os.path.exists( path_hidden_tool ):
        eprint(f"The {hidden_tool} file is missing.")
        cd( last_cd )
        return 1
    if not os.path.exists( hidden_version_file ):
        eprint(f"The hidden .version file is missing!")
        cd( last_cd )
        return 1
    if not os.path.exists( path_ver_symlink ):
        wprint(f"The symlink {ver_symlink} to {hidden_tool} is missing.")
        ANSWER = prompt_user_yesno("Create it for you?", "Y")
        if ANSWER == "Y":
            if IN_TEST_MODE == 1:
                tprint("Creating symlink {path_ver_symlink} -> {hidden_tool}")
                tprint("p4 add -t symlink {ver_symlink}")
                return_stat = 0
            else:
                create_symlink( path_ver_symlink, hidden_tool )
                if not os.path.exists( path_ver_symlink ):
                    eprint(f"Unable to create the symlink. Sorry.")
                    return_stat = 1
                else:
                    run_command( f"p4 add -t symlink {ver_symlink}" ) 
                    return_stat = 0 
        else:
            return_stat = 1 

    cd( last_cd ) 
    wprint(f"You will need to hand edit the .version file in {modules_area}")
    print(f"\tin order to update the default release to {ver_symlink}")
    return return_stat

def create_symlink( frompath, topath):
    p = Path(frompath)
    p.symlink_to( topath )

def wprint(*args, **kwargs):
    print('\033[33mWARNING:\033[0m', *args, file=sys.stderr, **kwargs)

def tprint(*args, **kwargs):
    print('\033[36mTESTMODE:\033[0m ', *args, file=sys.stderr, **kwargs)

def iprint(*args, **kwargs):
    print('INFO:', *args, file=sys.stderr, **kwargs)

def fatal_error(*args, **kwargs):
    print('\033[37;41mFATAL:\033[0m', *args, file=sys.stderr, **kwargs)

def eprint(*args, **kwargs):
    print('\033[31mERROR:\033[0m', *args, file=sys.stderr, **kwargs)


def dprint(*args, **kwargs):
    if DEBUG==True:
        print('DEBUG:', *args, file=sys.stderr, **kwargs)

def email_status():
    print("email_status() TO BE DONE {@TBD@}")
    return

def print_settings():
    print( "")
    print( "These are the settings used for this release.")
    print( "---------------------------------------------")
    for VARNAME in VARNAMES :
        VARVALUE = VARNAMES[VARNAME]
        print( f"\t{VARNAME}  {VARVALUE}")

def fatal_error_exit():
    print_settings()
    if P4_IN_EDIT_MODE == 1:
        ask_revert_exit()
    exit(-1)

def user_exit():
    if P4_IN_EDIT_MODE == 1:
        ask_revert_exit()
        exit(0)
    print( "Installation completed")
    save_current_settings_exit()
    exit(0)

def ask_revert_exit():
    global VARNAMES

    print( "" )
    print( "Your perforce tool may have it's p4 edit done already." )
    print( "If you wish I can do a p4 revert ... now" )
    ANSWER = prompt_user_yesno("Do the p4 revert?", "N")
    if ANSWER == "Y":
        cd( VARNAMES['P4_SHELLTOOLS_TOOL_ROOT'] )
        pwd("")
        if IN_TEST_MODE == 1: 
            tprint( "p4 revert ..." )
        else:
            status = run_command( 'p4 revert ...' )
            print( f"p4 revert status = {status}" )
    exit(0)

def save_current_settings_exit():
    logfile = f"{DEFAULT_CONFIG_FILE}_last"
    if os.path.exists(logfile):
         os.remove(logfile)
    fileh = open( logfile, "w")

    for VARNAME in VARNAMES: 
        VARVALUE = VARNAMES[VARNAME] 
        fileh.write( f"{VARNAME} {VARVALUE}")

    fileh.close()
    print( f"Created {logfile}" )
    exit(0)

def read_config_file( filename ):
    global VARNAMES

    if not os.path.exists( filename ):
        if filename != DEFAULT_CONFIG_FILE:
            print(f"\n**ERROR**: CONFIG_FILE '{filename}' is not present.\n")
            exit(1)
        return

    # The config file format is simply NAME value
    #
    # P4_WORKSPACE_ROOTDIR /remote/us01home50/joeuser/p4_ws
    # TOOL ddr-ckt-rel
    # REL_VERSION YYYY.MM-PATCH
    #
    fileh = open(filename, 'r')
    for line in fileh:
        # skip comment lines
        if re.search( '^\s*#', line):
            continue
        line_list = line.split()
        if len(line_list) == 2:
            if line_list[0] == "P4_WORKSPACE_ROOTDIR":
                line_list[1] = get_abs_path( line_list[1] ) 
            VARNAMES[line_list[0]] = line_list[1]
    fileh.close()
    return

def run_command( command_str ):
    return os.system( command_str )

def run_command_output( command_str ):
    ret = os.popen( command_str )
    return ( ret.read(), 0)

def grep( pattern, filename, column ):
    return_list = []
    fileh = open(filename, "r")
    for line in fileh: 
        if re.search( pattern, line):
            string_list = line.split()
            return_list.append( string_list[column] )
    fileh.close()
    return return_list

def cd( dirname ):
    global LAST_CD

    if not os.path.exists(dirname):
        eprint(f"{dirname} does not exist!")
        return 1
    os.chdir( dirname )
    LAST_CD = dirname
    return 0

def pwd( prefix ):
    if not prefix:
        prefix = "cwd:"

    print(prefix , os.getcwd() )
    return

def submit_changes():
    global VARNAMES

    status = cd( VARNAMES['P4_SHELLTOOLS_TOOL_ROOT'] )
    print( " ")
    pwd("")
    ANSWER = prompt_user_yesno("Continue with 'p4 submit'?", 'N')
    if ANSWER == "Y":
        tool = VARNAMES['TOOL']
        rel_version = VARNAMES['REL_VERSION']

        logfile = f"{HOME}/{tool}_{rel_version}_install_status"
        print( "Doing a p4 status... to look for new files that should get added")
        status = run_command( f"p4 status >& {logfile}" )
        print( f"Created file {logfile}" )
        files_toadd = grep(f"reconcile to add", logfile, 0) 
        if len(files_toadd) > 0 :
            # something new is there and will need to be added
            print( "New Files in %s" % os.getcwd() )
            for ITEM in ( files_toadd ):
                print( f"\t{ITEM}")

            print( "")
            ANSWER = prompt_user_yesno("p4 add the files listed?", "N")
            if ANSWER == "Y":
                for ITEM in ( files_toadd ):
                    if IN_TEST_MODE == 1:
                        tprint( f"p4 add {ITEM}")
                    else:
                        status = run_command( f"p4 add {ITEM}" )

        print( "")
        print( "Please specify a description for your submit. You should include")
        print( "a JIRA number, the person who made the modification(s) and info")
        print( "about why this is being submitted. ")
        print( "" )
        wprint( "do not enter single quotes or double quotes, it will.")
        print( "break this flow.")
        print( "")
        print( "Example:")
        print( "")
        print( "> P10020416-33554 kevinxie fixed title in oasis layermap file")
        print( "")
        DESCRIPTION = input("Description> ").strip()
        print( DESCRIPTION )
        while DESCRIPTION == "":
            print( "")
            print( "ERROR: A description is required.")
            print( "If you changed your mind about doing the submit, enter EXIT")
            print( "")
            DESCRIPTION = input("Description> ").strip()
            print( DESCRIPTION )
        if DESCRIPTION.upper() == "EXIT":
            user_exit()

        if IN_TEST_MODE == 1:
            tprint( f"p4 submit -d '{DESCRIPTION}' ")
        else:
            # -I shows you a progress indicator
            # -d allows you to specify the description
            #
            tool = VARNAMES["TOOL"] 
            rel_version = VARNAMES["REL_VERSION"]
            logfile = f"{HOME}/{tool}_{rel_version}_submit_output"
            status = run_command( f"p4 -I submit -d '{DESCRIPTION}' |& tee {logfile}" )
            if status != 0:
                print( "**WARNING** It appears that the p4 sumbit has failed.")
                print( f"Please review the log located at {logfile}")
                print( "")
                ANSWER = prompt_user_yesno("Do you wish to continue anyways?", "N")
                if ANSWER == "N":
                    user_exit()
            else:
                # if you reached here then things have been submitted and we
                # can now clear the flag that some things may be in edit mode in p4
                P4_IN_EDIT_MODE = 0
                print( f"FYI: Created {logfile}")
    return

def sync_p4():
    global VARNAMES
    status = cd( VARNAMES['P4_WORKSPACE_ROOTDIR'] )
    if status != 0:
        print( f"-F- Something went wrong trying to 'cd' to '{L_P42S}'")
        fatal_error_exit()

    print("")
    pwd("")
    ANSWER = prompt_user_yesno("Continue with 'p4 sync'?", "Y")
    if ANSWER == "Y":
        ###################### p4 sync ... ###################################
        if IN_TEST_MODE == 1 :
            tprint( "p4 sync")
        else:
            status = run_command('cd ./wwcad/msip/internal_tools/Shelltools; p4 sync ...')
            print( f"p4 sync status={status}")
            status = run_command('cd ./wwcad/msip/internal_tools/modulefiles; p4 sync ...')
            print( f"p4 sync status={status}")
    return

def p4_any_locked_files():
    (locked, status) = run_command_output('p4 opened -a ... |& grep locked')
    if locked != "":
        print( "\n-W- There are some locked files present.")
        print( locked )
        ANSWER = prompt_user_yesno("Continue anyways?", "N")
        if ANSWER == "N":
            user_exit()
        return True
    return False

#
# This routine will do a p4 copy operation to copy the files from dev to
# the releases area.
#
def copy_dev_to_releases():
    global VARNAMES

    tool = VARNAMES['TOOL']
    p4_workspace_rootdir = VARNAMES['P4_WORKSPACE_ROOTDIR']
    shelltools = DEF_SHELLTOOLS
    VARNAMES['P4_SOURCE_TOOL_ROOT'] = f"{p4_workspace_rootdir}/{shelltools}/{tool}/dev/main"
    status = cd( VARNAMES['P4_SOURCE_TOOL_ROOT'] )
    if status != 0:
        print( f"ERROR:  unable to cd into {VARNAMES['P4_SOURCE_TOOL_ROOT']}")
        fatal_error_exit()

    print( " ")
    pwd('From:')
    ANSWER = prompt_user_yesno("Continue with the 'p4 copy' operations?", "Y")
    if ANSWER == "Y":
        src_path = VARNAMES['P4_SOURCE_TOOL_ROOT']
        tgt_path = VARNAMES['P4_TARGET_TOOL_ROOT']
        cmd = f"p4 copy {src_path}/... {tgt_path}/..."
        if IN_TEST_MODE == 1:
            tprint(f"p4 copy {src_path}/... {tgt_path}/...")
            status = 0
        else:
            print(f"Issuing this command: {cmd}")
            status   = run_command(cmd)
        
        if status != 0:
            # Maybe the destination folder of the file does not yet
            # exist and maybe we need to create it. Let's check if 
            # that is the issue and then prompt the user if they wish
            # to create that directory.
            check_dirpath = os.path.dirname( tgt_path ) 
            if not os.path.exists( check_dirpath ):
                print( f"Missing target directory {check_dirpath} .")
                ANSWER = prompt_user_yesno( f"Create it?", "Y")
                if ANSWER == 'Y':
                    create_dir( check_dirpath )
                    status = run_command(f"p4 copy {src_path}/... {tgt_path}/...")
                    if status != 0:
                        eprint(f"Tried 'p4 copy' {src_path}/... {tgt_path}/... for the 2nd time and it failed")
                        fatal_error_exit() 
                else:
                    print( f"ERROR: Unable to continue without a target directory." )
                    fatal_error_exit()
            else:
                print( f"ERROR: Some problem occured during '{cmd}' operation'")
                fatal_error_exit()
    return

def process_cmd_line_args():
    global VARNAMES
    global IN_TEST_MODE
    global DEBUG

    my_parser = argparse.ArgumentParser(
            description='Install Shelltools from dev to releases')

    my_parser.add_argument( '--testmode' 
        , action='store_true'
        , help = f"Do not run cp and p4 commands"
    )
    my_parser.add_argument( '--debug' 
        , action='store_true'
        , help = f"Allows internal dprint() calls to work"
    )
    my_parser.add_argument( '-c', '--config' 
        , metavar='CONFIGURATION'
        , required=False
        , type=str
        , help = f"A config file to set required variables. Default is {DEFAULT_CONFIG_FILE}"
    )
    my_parser.add_argument( '-t', '--tool' 
        , metavar='TOOL'
        , required=False
        , type=str
        , help = 'Tool name you wish to install (eg. ddr-ckt-rel)'
    )
    my_parser.add_argument( '-v', '--version'
        , metavar='REL_VERSION'
        , required=False
        , type=str
        , help = 'The Shelltools Release Version (eg. 2022.03)'
    )
    args = my_parser.parse_args()

    if args.config:
        read_config_file( args.config )

    if args.tool:
        VARNAMES['TOOL'] = args.tool
        update_varnames()
        
    if args.version:
        VARNAMES['REL_VERSION'] = args.version
        update_varnames()

    if args.testmode:
        IN_TEST_MODE = 1

    if args.debug:
        DEBUG = 1

    return

def prompt_user_yesno(message, default_value ):
    yesno = "yn"
    if default_value.upper() == 'Y':
        yesno = "Yn"
    elif default_value.upper() == 'N':
        yesno = "yN"

    answer = input( f"{message} [{yesno}] > ").upper().strip()
    if answer == "":
        return default_value.upper()

    while answer != "Y" and answer != "N":
        print( f"'{answer}' is not Y or N. Please try again.")
        answer = input( f"[{yesno}] > " ).upper().strip()
        if answer == "":
            return default_value.upper()

    return answer.upper()


def verify_root_dirs_exist():
    dprint("enter verify_root_dirs_exist")

    if not os.path.exists( VARNAMES['P4_WORKSPACE_ROOTDIR'] ):
        fatal_error( f"Can't find P4_WORKSPACE_ROOTDIR '{VARNAMES['P4_WORKSPACE_ROOTDIR']}'")
        fatal_error_exit()

    p4_shelltools_tool_root = VARNAMES['P4_SHELLTOOLS_TOOL_ROOT']
    if not os.path.exists( p4_shelltools_tool_root ):
        wprint( f"Can't find {p4_shelltools_tool_root}")
        ANSWER = prompt_user_yesno( f"Do you want create {p4_shelltools_tool_root}", "N")
        if ANSWER == 'Y':
            if IN_TEST_MODE == 1:
                tprint(f"Create Dir {p4_shelltools_tool_root}") 
            else:
                status = create_dir( p4_shelltools_tool_root )

    if not os.path.exists( f"{VARNAMES['P4_SOURCE_TOOL_ROOT']}"):
        fatal_error( f"Can't find P4_SOURCE_TOOL_ROOT '{VARNAMES['P4_SOURCE_TOOL_ROOT']}'")
        fatal_error_exit()

    p4_target_tool_root = VARNAMES['P4_TARGET_TOOL_ROOT']
    if not os.path.exists( p4_target_tool_root ):
        wprint( f"Can't find P4_TARGET_TOOL_ROOT '{VARNAMES['P4_TARGET_TOOL_ROOT']}'")
        ANSWER = prompt_user_yesno( f"Do you want create '{p4_target_tool_root}'", "N")
        if ANSWER == 'Y':
            if IN_TEST_MODE == 1:
                tprint(f"Creating Dir {p4_target_tool_root}")
            else:
                status = create_dir( p4_target_tool_root )
                if status != 0:
                    fatal_error(f"Problems trying to create dir '{p4_target_tool_root}' !")
                    fatal_error_exit()

    return

def create_dir( dirpath ):
    dir_list = dirpath.split('/')
    buildpath = ''
    attempted = False 
    for dirpart in (dir_list):
        if dirpart == "":
            continue
        buildpath = buildpath + '/' + dirpart
        if not os.path.exists( buildpath ):
            if buildpath != dirpath:
                ANSWER = prompt_user_yesno( f"Create Dir: {buildpath}?" , "Y")
                if ANSWER == 'Y':
                    mode = 0o770
                    os.mkdir( buildpath, mode)
                    attempted = True
                    continue
            else:
                mode = 0o770
                os.mkdir( buildpath, mode)
                attempted = True
            break

    if attempted and not os.path.exists( dirpath ):
        fatal_error( f"Unable to create '{dirpath}'")
        fatal_error_exit()

    return 0

def user_verify_settings():
    global VARNAMES

    for VARNAME in ALLOWED_TO_MODIFY :
        print( "")
        VARVALUE = VARNAMES[VARNAME]
        print( f"{VARNAME} : {VARVALUE}")
        print( "Hit RETURN to accept, otherwise enter a new value")
        ANSWER = input("> ").strip()
        if ANSWER != "":
            VARNAMES[VARNAME] = ANSWER

    update_varnames()

    return

def get_abs_path(somepath):
    cd(somepath)
    retpath = os.path.abspath(somepath)
    (output, status) = run_command_output(f"/bin/tcsh -c cd {retpath}; echo $PWD")
    os.chdir(LAST_CD)
    return output.strip()


if __name__ == "__main__":
    main()

