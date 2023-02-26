#!/bin/python3.6
#
# Usage:
#       install_tool_from_gitlab_to_shelltools [-t TOOLNAME] [-tag NAME] [-c CONFIG] [--testmode]
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
# Updates:
#   001 3/24/2022   ljames
#       Created this script
#   002 3/31/2022   ljames
#       Enable testing after install is done
#   003 4/08/2022   ljames
#       Do not copy .log files
#       If it's a new file then will need 'p4 add' to take place
#   004 4/11/2022   ljames
#       Add a tag to git automatically
#   005 4/13/2022   ljames
#       Prompt before running tests, ask user if they want to run the tests
#       Updated VARNAMES[tag] when tag exists and asks user for new tag
#   006 4/15/2022   ljames
#       Creates the required /modulefiles/tool/ files.
#       cd() function stores the last cd into global LAST_CD
#       Added some color to the *print() commands
#   007 5/16/2022   ljames
#       Added a --pick option. When doing copy operations it will ask you
#       first.
#   008 7/28/2022  ljames
#       Added IGNORE option, to NOT copy files mentioned in this list
#       The value is a string which is interpreted as a regular expression.
#       So to include more than one filename check you can use the pipe.
#       Example:   IGNORE  "pincheck.py|oldMakefile"
#       If we encounter either pincheck.py or oldMakefile, then they will
#       be ignored (ie. not copied)
#   009 9/23/2022  ljames
#       install now looks for .version file and if it sees it, it will
#       compare the content of that file with the Target Release Version.
#       If they differ then a warning will be printed and the user will be
#       asked if they want to abort the install or not.
#   010 10/03/2022   ljames
#       Do not copy .LOG files
#-
import os
from os import environ
import sys
import argparse
import glob
import re
import hashlib
from pathlib import Path

##############################################################################
# STEP #0:  setup some variables to point to your p4_ws and GitLab areas
##############################################################################

# Set some flags that will be used in this program

P4_IN_EDIT_MODE = 0
IN_TEST_MODE    = 0
DEBUG           = 0
BRMAIN          = 'main'

# These are the application defaults. User can override these using a
# configuration file.
 
USER    = environ.get('USER')
HOME    = environ.get('HOME')
GITAPP  = '/global/freeware/Linux/3.10/git-2.30.0/bin/git'
LAST_CD = ''

DEF_P4_WORKSPACE_ROOTDIR    = os.path.realpath( f"/u/{USER}/p4_ws" )
DEF_GIT_WORKSPACE_ROOTDIR   = f"/u/{USER}/GitLab/ddr-hbm-phy-automation-team"
DEF_TOOL                    = "ddr-ckt-rel"
DEF_TARGET_RELEASE          = f"TARGETRELEASE"
DEF_TAG                     = f"NONE"
DEF_PICK                    = False
DEF_LAST_RELEASE_TAG        = f"NONE"
DEF_SHELLTOOLS              = 'wwcad/msip/internal_tools/Shelltools'
DEF_MODULEFILES             = 'wwcad/msip/internal_tools/modulefiles'
DEF_SHELLTOOLS_REL_VERSION  = 'dev'
DEF_P4_SHELLTOOLS_TOOL_ROOT = f"{DEF_P4_WORKSPACE_ROOTDIR}/{DEF_SHELLTOOLS}/{DEF_TOOL}"
DEF_GIT_SOURCE_TOOL_ROOT    = f"{DEF_GIT_WORKSPACE_ROOTDIR}/{DEF_TOOL}/dev/main"
DEF_GIT_SOURCE_TOOL_DOC     = f"{DEF_GIT_WORKSPACE_ROOTDIR}/{DEF_TOOL}/dev/main/doc"
DEF_BREADCRUMB_APP          = f"{DEF_GIT_WORKSPACE_ROOTDIR}/admin/breadcrumb_git.py"
DEFAULT_CONFIG_FILE         = f"{HOME}/.install_tool_from_gitlab_to_shelltools.config"
GIT_OPS_ALLOWED             = False
MODULEFILES_NEED_SUBMIT     = False
VARNAMES                = { 
        "P4_WORKSPACE_ROOTDIR":DEF_P4_WORKSPACE_ROOTDIR,
        "GIT_WORKSPACE_ROOTDIR":DEF_GIT_WORKSPACE_ROOTDIR, 
        "TOOL":DEF_TOOL, 
        "TAG":DEF_TAG,
        "IGNORE":"",
        "LAST_RELEASE_TAG":DEF_LAST_RELEASE_TAG,
        "TARGET_RELEASE":DEF_TARGET_RELEASE,
        "SHELLTOOLS":DEF_SHELLTOOLS ,
        "MODULEFILES":DEF_MODULEFILES ,
        "SHELLTOOLS_REL_VERSION":DEF_SHELLTOOLS_REL_VERSION, 
        "P4_SHELLTOOLS_TOOL_ROOT":DEF_P4_SHELLTOOLS_TOOL_ROOT, 
        "GIT_SOURCE_TOOL_ROOT": DEF_GIT_SOURCE_TOOL_ROOT,
        "GIT_SOURCE_TOOL_DOC": DEF_GIT_SOURCE_TOOL_DOC,
        "BREADCRUMB_APP": DEF_BREADCRUMB_APP,
        "PICK": DEF_PICK,
    }

VERIFY_VARS = [
        'TOOL',
        'TAG',
        'TARGET_RELEASE',
        'LAST_RELEASE_TAG',
        ]

REQUIRED_DIRS = [ 
        'P4_WORKSPACE_ROOTDIR',
        'GIT_WORKSPACE_ROOTDIR',
        ]

# COPIED is a dictionary to keep track of the files that get copied to p4
COPIED = {}

def main():
    global VARNAMES
    global IN_TEST_MODE
    global DEBUG
    global GIT_OPS_ALLOWED

    if environ.get('INSTALL_IS_IN_TEST_MODE') != None:
        IN_TEST_MODE = 1

    #
    # Load in the default configuration for this script.
    # this will update the VARNAMES global variable.
    #
    read_config_file( DEFAULT_CONFIG_FILE )
    update_varnames()
    #
    # Check the command line arguments. 
    #
    process_cmd_line_args()
    update_varnames()

    if IN_TEST_MODE:
        print("\nNOTE: Test Mode is Enabled\n")
    if DEBUG:
        print("\nNOTE: Debug Mode is Enabled\n")

    print( "*-------- Verifying Settings --------*")

    user_verify_settings()

    #
    # Now verify that the specified directories actually exist.
    #
    verify_root_dirs_exist()

    #
    # Make sure that the git root dir has a .git directory. If not then this
    # isn't really a Git repo.  If it does have a .git directory then check
    # which branch the user is in. He/she must be in the 'main' branch for
    # the git operations to work.
    #
    GIT_OPS_ALLOWED = is_valid_git( VARNAMES['GIT_WORKSPACE_ROOTDIR'] )
    if GIT_OPS_ALLOWED == False:
        wprint("NOTE: Git Tagging will not be done.\n")

    ##############################################################################
    # STEP #1 -- update P4 and GITLAB with latest changes
    ##############################################################################

    update_p4_and_gitlab()

    ##########################################################################
    # TAG git repo everytime we updated the p4 dev area
    ##########################################################################

    tag_git()

    ###########################################################################
    # Create the breadcrumb file and based on which tool is being installed
    # copy it to the correct /doc folder
    ###########################################################################
    
    create_breadcrumb()

    ##############################################################################
    # STEP #2 - start copying the TOOL's files to P4
    ##############################################################################

    check_outdated_in_p4()
   
    git_cleanup()

    copy_git_to_p4()

    ##############################################################################
    # STEP #3 - Update the modules area
    ##############################################################################

    has_error = update_shelltools_modules()
    if has_error:
        eprint("You will need to fixup the modulefiles area by hand.")
            

    ##############################################################################
    # STEP #4 - Run the standard set of tests      
    ##############################################################################

    if is_makefile_present(VARNAMES['P4_SHELLTOOLS_TOOL_ROOT'] ):
        ANSWER = prompt_user_yesno("Do you want to run the tests?", "Y")
        if ANSWER == "Y":
            has_error = run_tests()
            if has_error:
                eprint("Your testing had an error, please investigate")

    ##############################################################################
    #  STEP #5 - Submit your changes
    ##############################################################################

    submit_shelltools_changes()

    ##############################################################################
    # STEP #6 - Notify folks about the installation
    ##############################################################################

    # TBD: we can use Email or maybe there is an API I can use to put it into
    #      Teams...  Or maybe we should have a JIRA ticket to request a release
    #      and I believe there is an API to JIRA where we can then update the
    #      Story when the install is done.

    email_status()
    print("Done.\n")
    print_copied()
    print_settings()
    save_current_settings_exit()
    # end of Main

def check_outdated_in_p4():
    global VARNAMES
    
    # (1) Look at all the files in the P4 Shelltools TOOL/dev/main/... area
    # (2) do those files also exist in our GitLab TOOL/dev/main/... area?
    #    if not; then it's an extra p4 file and it's a candidate to get
    #    deleted.
    p4path  = VARNAMES['P4_SHELLTOOLS_TOOL_ROOT']
    gitpath = VARNAMES['GIT_SOURCE_TOOL_ROOT']

    p4_files  = find_files( p4path )
    git_files = find_files( gitpath )

    # look to see if the p4_files also exist in git_files ; if the p4_file is not
    # present in git_files, then flag that file. It probably should be removed.

    p4_to_delete = []
    for p4_fname in ( p4_files ):
        short_p4_fname = p4_fname.replace( p4path, "")
        isMissingFromGit = True
        for git_fname in ( git_files ):
            short_git_fname = git_fname.replace( gitpath, "")
            if short_git_fname == short_p4_fname:
                isMissingFromGit = False
                continue
        if isMissingFromGit:
            p4_to_delete.append(p4_fname )

    if len(p4_to_delete) > 0 :
        print(f"Obsolete Files Found in Shelltools:")
        for long_fname in ( p4_to_delete ):
            print(f"\t{long_fname}")
        ANSWER = prompt_user_yesno("Delete All?", "Y")
        for fname in ( p4_to_delete ):
            if ANSWER == "Y":
                if IN_TEST_MODE:
                    tprint(f"p4 delete {fname}")
                    tprint(f"os.remove({fname})")
                else:
                    status = run_command( f"p4 delete {fname}" )
                    if status != 0:
                        eprint(f"p4 delete {fname} FAILED!")
                    if os.path.exists(fname):
                        os.remove( fname )


def is_valid_git( git_root_dir ):
    global BRMAIN

    dprint("is_valid_git")

    if not os.path.exists( f"{git_root_dir}/.git" ):
        wprint("Your GIT_WORKSPACE_ROOTDIR does not have a '.git' folder")
        print( "\tIf that is expected for this install then no worries.")
        print( "\tIf you were expecting it to be a git repo, then exit and")
        print( "\tfigure out what is wrong with your directory.")
        print(f"\tGIT_WORKSPACE_ROOTDIR is pointing to {VARNAMES['GIT_WORKSPACE_ROOTDIR']}")
        return False
    # So, it is a real git repo but does the branch point to the main or master 
    git_root = VARNAMES['GIT_WORKSPACE_ROOTDIR']
    # The first thing printed from git status -s -b is the branch
    # it's in the form of  "## master...origin/master"
    (output, status) = run_command_output( f"cd {git_root}; {GITAPP} status -s -b") 
    dprint(f"{GITAPP} status output is {output}")
    output_ary = output.split()
    branch_name = output_ary[1]
    dprint(f"branch_name is {branch_name}")
    if re.search( f"{BRMAIN}\.\.\.", branch_name):
        dprint("return True")
        return True
    if re.search( 'main\.\.\.', branch_name):
        dprint("return True")
        return True
    wprint( "Your git repository's branch is not the main branch." )
    print( f"\tYour branch is: '{branch_name}'" )
    print(  "\tThat is unexpected!" )
    ANSWER = prompt_user_yesno("Do you wish to continue anyways?", 'N' )
    if ANSWER == "N":
       user_exit()
    return False


# this updates some VARNAMES that depend on other VARNAMES that might have
# changed.
def update_varnames():
    global VARNAMES
    
    p4_workspace_rootdir    = VARNAMES['P4_WORKSPACE_ROOTDIR']
    git_workspace_rootdir   = VARNAMES['GIT_WORKSPACE_ROOTDIR']
    tool                    = VARNAMES['TOOL']
    shelltools              = DEF_SHELLTOOLS
    p4_shelltools_tool_root = f"{p4_workspace_rootdir}/{shelltools}/{tool}"
    git_source_tool_root    = f"{git_workspace_rootdir}/{tool}/dev/main"
    git_source_tool_doc     = f"{git_workspace_rootdir}/{tool}/dev/main/doc"

    VARNAMES['P4_SHELLTOOLS_TOOL_ROOT'] = p4_shelltools_tool_root
    VARNAMES['GIT_SOURCE_TOOL_ROOT']    = git_source_tool_root
    VARNAMES['GIT_SOURCE_TOOL_DOC']     = git_source_tool_doc
    return



def create_breadcrumb():
    if GIT_OPS_ALLOWED == False:
        wprint("NOTE: no breadcrumb will be created\n")
        return

    dprint("create_breadcrumb");

    toolname    = VARNAMES['TOOL']
    tooldoc     = VARNAMES['GIT_SOURCE_TOOL_DOC']
    appExe      = VARNAMES['BREADCRUMB_APP']
    lastRelease = VARNAMES['LAST_RELEASE_TAG']

    if lastRelease == DEF_LAST_RELEASE_TAG:
        wprint("NOTE: no breadcrumb will be created, requires --last_release_tag")
        return

    if os.path.exists( tooldoc ):
        cdcmd   = f"cd {tooldoc}"
        outfile = f"{tooldoc}/GITLAB_INFO"
        pid     = os.getpid()

        if IN_TEST_MODE:
            outfile = f"/tmp/breadcrumb_{USER}_{toolname}_{pid}"
            # odds are extremely low that this file will already exist
            if os.path.exists(outfile):
                os.remove(outfile)

        cmd = f"{cdcmd} ; {appExe} --tool {toolname} -l {lastRelease} --out {outfile}"
        status = run_command( cmd )
        if status:
            eprint( f"Something appeared to go wrong with {appExe} status={status}" )
        else:
            iprint( f"Breadcrumb was Created and written to {outfile}" )

    return


def tag_git():
    global VARNAMES
    global GIT_OPS_ALLOWED

    if GIT_OPS_ALLOWED == False:
        wprint("No Git Operations allowed - not git tag will get created\n")
        return

    dprint("tag_git")

    tag = VARNAMES['TAG'].strip()
    if tag == DEF_TAG:
        iprint("No Tag Was Created")
        return
    git_area       = VARNAMES['GIT_WORKSPACE_ROOTDIR']
    tool           = VARNAMES['TOOL']
    target_release = VARNAMES['TARGET_RELEASE']

    if target_release == DEF_TARGET_RELEASE:
        target_release = ''

    # does this TAG already exist in your Git Repo?
    while tag_exists( tag ):
        wprint(f"The tag {tag} already exists. Enter a new tag or NONE for no tag.")
        tag = input("> ").strip()

    if tag.upper() == "NONE":
        return

    VARNAMES['TAG'] = tag

    tag_comment = f"'{target_release} Beta Release for {tool}'"
    if IN_TEST_MODE:
        tprint( f"{GITAPP} tag -a '{tag}' -m {tag_comment}")
    else:
        status = run_command(f"cd {git_area}; {GITAPP} tag -a '{tag}' -m {tag_comment}")
        if status:
            eprint("Something appeared to go wrong with the 'git tag' creation command")
        else:
            ANSWER = prompt_user_yesno("Do you want to push the tag to the remote?", "Y")
            if ANSWER == "Y":
                status = run_command( f"cd {git_area}; {GITAPP} push --tags" )

def tag_exists( tagname ):
    dprint( f"Checking if tag {tagname} already exists.") 
    git_root = VARNAMES['GIT_WORKSPACE_ROOTDIR'] 
    (output, status) = run_command_output( f"cd {git_root}; {GITAPP} tag" )
    dprint( f"Listing all tags: {output}\n" )
    for tname in ( output.split('\n') ):
        if tname == tagname:
            return True
    return False

def submit_modules_changes():
    ws_root      = VARNAMES['P4_WORKSPACE_ROOTDIR']
    modulefiles  = VARNAMES['MODULEFILES']
    tool         = VARNAMES['TOOL']
    version      = VARNAMES['SHELLTOOLS_REL_VERSION']
    modules_area = f"{ws_root}/{modulefiles}/{tool}"
    return_cd    = LAST_CD
    logfile      = f"{HOME}/{tool}_{version}_modules_install_status"
    DESCRIPTION  = f"Updating Shelltools modulefiles for tool {tool}"

    cd( modules_area )
    print(" ")
    pwd()
    ANSWER = prompt_user_yesno("Continue with modulefiles 'p4 submit'?", 'N')
    if ANSWER == 'N':
        cd( return_cd )
        return

    if IN_TEST_MODE == 1:
        tprint( f"p4 submit -d '{DESCRIPTION}' ")
        cd( return_cd )
        return

    status = run_command( f"p4 submit -d '{DESCRIPTION}' |& tee {logfile}" )
    if status != 0:
        wprint( "**WARNING** It appears that the p4 sumbit has failed.")
        print( f"\tPlease review the log located at {logfile}")
        print( "")
        ANSWER = prompt_user_yesno("Do you wish to continue anyways?", "N")
        if ANSWER == "N":
            user_exit()

    cd( return_cd )
    return

def update_shelltools_modules():
    global MODULEFILES_NEED_SUBMIT

    ws_root      = VARNAMES['P4_WORKSPACE_ROOTDIR']
    modulefiles  = VARNAMES['MODULEFILES']
    tool         = VARNAMES['TOOL']
    version      = VARNAMES['SHELLTOOLS_REL_VERSION']
    modules_area = f"{ws_root}/{modulefiles}/{tool}"
    path_hidden_tool    = f"{modules_area}/.{tool}"
    hidden_tool         = f".{tool}"
    path_ver_symlink    = f"{modules_area}/{version}"
    ver_symlink         = f"{version}"
    hidden_version_file = f"{modules_area}/.version"
    return_cd           = LAST_CD

    cd_modules_stat = cd( modules_area )
    if cd_modules_stat == 0:
        pwd()
    print( f"\nLooking at modulefiles area. {modules_area}")
    print( f"\tThis area is required for 'module load' to work with {tool}")
    print( f"\tThe dir should contain files:")
    print( f"\t\t'.{tool}'\n\t\t'dev->{tool}' symlink\n\t\t'.version' to pick the default release")

    if not os.path.exists( modules_area ):
        wprint(f"Missing modulesfiles area {modules_area}")
        ANSWER = prompt_user_yesno( f"Create it?", "Y") 
        if ANSWER == "Y":
            if IN_TEST_MODE:
                tprint( f"Create directory {modules_area}") 
            else:
                create_dir( modules_area )
                if not os.path.exists( modules_area ):
                    eprint(f"Unable to create the '{modules_area}'. Sorry.")
                    cd( return_cd )
                    return 1
                cd( modules_area )
        else:
            cd( return_cd  )
            return 1

    if not os.path.exists( path_hidden_tool ):
        wprint(f"The required modulesfile '{hidden_tool}' file is missing.")
        ANSWER = prompt_user_yesno( f"Create it?", "Y")
        if ANSWER == "Y":
            if IN_TEST_MODE:
                tprint( f"Create {modules_area}/.{tool} file")
                tprint( f"p4 add {path_hidden_tool}" ) 
                MODULEFILES_NEED_SUBMIT = True
            else:
                create_module_dot_file( modules_area , tool )
                if not os.path.exists( path_hidden_tool ):
                    eprint(f"Unable to create the '{hidden_tool}'. Sorry.")
                    cd( return_cd )
                    return 1
                status = run_command( f"p4 add {path_hidden_tool}" )
                if status != 0:
                    eprint(f"p4 add {path_hidden_tool} FAILED!")
                    cd( return_cd )
                    return 1
                MODULEFILES_NEED_SUBMIT = True
        else:
            cd( return_cd )
            return 1

    if not os.path.exists( hidden_version_file ):
        wprint(f"The hidden .version file is missing!")
        ANSWER = prompt_user_yesno( f"Create it?", "Y")
        if ANSWER == "Y":
            cmd =  f"p4 add {hidden_version_file}"
            if IN_TEST_MODE:
                tprint( f"Create {hidden_version_file}")
                tprint( f"{cmd}" )
                MODULEFILES_NEED_SUBMIT = True
            else:
                create_module_version_file( hidden_version_file )
                if not os.path.exists( hidden_version_file ):
                    eprint(f"Unable to create the '.version' file. Sorry.")
                    cd( return_cd )
                    return 1
                run_command( cmd )
                MODULEFILES_NEED_SUBMIT = True
        else:
            cd( return_cd )
            return 0

    if not os.path.exists( path_ver_symlink ):
        wprint(f"The symlink {ver_symlink} is missing.")
        ANSWER = prompt_user_yesno("Create it for you?", "Y")
        if ANSWER == "Y":
            if IN_TEST_MODE:
                pwd()
                tprint( f"Create symlink file {ver_symlink} -> {hidden_tool}")
                tprint( f"p4 add -t symlink {ver_symlink}")
            else:
                # To create a symlink using these relative names requires that
                # our default directory be in the modulesfiles area for this tool
                # ver_symlink is 'dev';  hidden_tool is '.TOOLNAME' 
                create_symlink(ver_symlink, hidden_tool)
                if not os.path.exists( path_ver_symlink ):
                    eprint(f"Unable to create the {ver_symlink}. Sorry.")
                    cd( return_cd )
                    return 1
                else:
                    # first time created this dev symlink file so we will need
                    # to do a p4 add -t symlink
                    cmd =  f"p4 add -t symlink {ver_symlink}"
                    if IN_TEST_MODE:
                        tprint(cmd)
                    else:
                        status = run_command( cmd )
                        if status != 0:
                            eprint( f"{cmd} Failed!")
                            pwd("p4 add failed and your cwd is")
                            cd( return_cd )
                            return 1
                        MODULEFILES_NEED_SUBMIT = True
                    cd( return_cd )
                    return 0
        cd( return_cd )
        return 1
    # 
    cd( return_cd )
    return 0

def create_symlink( mylink , target):
    dprint( f"Try Path( '{mylink}' ).symlink_to( '{target}' )")
    Path( mylink ).symlink_to( target )

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

def is_makefile_present( tool_root ):
    if not os.path.exists( f"{tool_root}/Makefile" ):
        return 0

def run_tests():
    print("\nRunning Tests\n")
    cd( tool_root )
    pwd()
    cmd = "make test"
    if IN_TEST_MODE:
        tprint( cmd )
        return 0
    else:
        status = run_command( cmd )
        return status

def email_status():
    print("email_status() TO BE DONE {@TBD@}")
    return

def print_settings():
    print( "")
    print( "These are the settings used for this install.")
    print( "---------------------------------------------")
    for VARNAME in VARNAMES :
        VARVALUE = VARNAMES[VARNAME]
        print( f"\t{VARNAME}  {VARVALUE}")

def print_copied():
    global COPIED
    for p4copy in COPIED:
        value = COPIED[f"{p4copy}"]
        print(f"COPIED: {p4copy} {value}")

def fatal_error_exit():
    print_settings()
    print_copied()
    if P4_IN_EDIT_MODE == 1:
        ask_revert_exit()
    save_current_settings_exit()
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
    cmd = "p4 revert ..."

    print( "" )
    print( "Your perforce tool may have it's p4 edit done already." )
    print( "If you wish I can do a p4 revert ... now" )
    ANSWER = prompt_user_yesno("Do the p4 revert?", "N")
    if ANSWER == "Y":
        cd( VARNAMES['P4_SHELLTOOLS_TOOL_ROOT'] )
        pwd()
        if IN_TEST_MODE == 1: 
            tprint( cmd ) 
        else:
            status = run_command( cmd )
            print( f"{cmd} status = {status}" )
    exit(0)

def save_current_settings_exit():
    logfile = f"{HOME}/.install_tool_from_gitlab_to_shelltools_last_settings"
    if os.path.exists(logfile):
         os.remove(logfile)
    fileh = open( logfile, "w")

    for VARNAME in VARNAMES: 
        VARVALUE = VARNAMES[VARNAME] 
        fileh.write( f"{VARNAME}  {VARVALUE}\n")

    fileh.close()
    print( f"\nWrote {logfile}" )
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
    # GIT_WORKSPACE_ROOTDIR /remote/us01home50/joeuser/GitLab/ddr-hbm-phy-automation-team
    # TOOL ddr-ckt-rel
    # SHELLTOOLS_REL_VERSION dev|YYYY.MM-PATCH
    #
    if os.path.exists(filename) :
        fileh = open(filename, 'r')
        for line in fileh:
            # skip comment lines
            if re.search( '^\s*#', line):
                continue
            line_list = line.split()
            if len(line_list) == 2:
                VARNAMES[line_list[0]] = line_list[1]
        fileh.close()
    return

def run_command( command_str ):
    dprint(command_str)
    return os.system( command_str )

# run the command and return the stdout contents
def run_command_output( command_str ):
    dprint(f"run_command_output {command_str}")
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
    if dirname == "":
        return 0
    
    if not os.path.exists(dirname):
        eprint(f"cd failed because {dirname} does not exist!")
        return 1

    os.chdir( dirname )
    LAST_CD = dirname
    return 0

def touch( filename ):
    fileh = open(logfile, "w")
    fileh.close()
    return

def pwd():
    print("cwd:", os.getcwd() )
    return

def find_files( top_folder ):
    pys = []
    for p, d, f in os.walk( top_folder, followlinks=True ):
        for file in f:
            pys.append(f"{p}/{file}")
    return pys 

def submit_shelltools_changes():
    global VARNAMES

    if MODULEFILES_NEED_SUBMIT:
        submit_modules_changes()

    p4root = VARNAMES['P4_SHELLTOOLS_TOOL_ROOT'] 
    status = cd( p4root )
    print( " ")
    pwd()
    ANSWER = prompt_user_yesno("Continue with Shelltools 'p4 submit'?", 'N')
    if ANSWER == "Y":
        tool = VARNAMES['TOOL']
        shelltools_rel_version = VARNAMES['SHELLTOOLS_REL_VERSION']

        logfile = f"{HOME}/{tool}_{shelltools_rel_version}_install_status"
        print("")
        iprint( "Now doing a p4 status... to look for new files that should get added")
        status = run_command( f"p4 status >& {logfile}" )
        files_toadd = grep(f"reconcile to add", logfile, 0) 
        if len(files_toadd) > 0 :
            # something new is there and will need to be added
            print( "\nNew Files in %s" % os.getcwd() )
            for ITEM in ( files_toadd ):
                print( f"\t{ITEM}")
            print( "")

            ANSWER = prompt_user_yesno("p4 add the files listed?", "N")
            if ANSWER == "Y":
                for ITEM in ( files_toadd ):
                    add_arg = ''
                    if os.path.islink( ITEM ):
                        add_arg = ' -t symlink '
                    if IN_TEST_MODE == 1:
                        tprint( f"p4 add {add_arg} {ITEM}")
                    else:
                        status = run_command( f"p4 add {add_arg} {ITEM}" )
                        if status != 0:
                            fatal_error("p4 add {add_arg} {ITEM} failed")
                            fatal_error_exit()


        print( "")
        print( "Please specify a description for your submit. You should include")
        print( "a JIRA number, the person who made the modification(s) and info")
        print( "about why this is being submitted.")
        print( "")
        print( "Example:")
        print( "")
        print( "> P10020416-33554 kevinxie fixed title in oasis layermap file")
        print( "")
        DESCRIPTION = input("Description> ").strip()
        while DESCRIPTION == "":
            print( "")
            print( "ERROR: A description is required.")
            print( "If you changed your mind about doing the submit, enter EXIT")
            print( "")
            DESCRIPTION = input("Description> ").strip()

        if DESCRIPTION.upper() == "EXIT":
            user_exit()

        if IN_TEST_MODE == 1:
            tprint( f"p4 submit -d '{DESCRIPTION}' ")
        else:
            # -I shows you a progress indicator
            # -d allows you to specify the description
            #
            tool = VARNAMES["TOOL"] 
            shelltools_rel_version = VARNAMES["SHELLTOOLS_REL_VERSION"]
            logfile = f"{HOME}/{tool}_{shelltools_rel_version}_submit_output"
            status = run_command( f"p4 submit -d '{DESCRIPTION}' |& tee {logfile}" )
            if status != 0:
                wprint( "**WARNING** It appears that the p4 sumbit has failed.")
                print( f"\tPlease review the log located at {logfile}")
                print( "")
                ANSWER = prompt_user_yesno("Do you wish to continue anyways?", "N")
                if ANSWER == "N":
                    user_exit()
            else:
                # if you reached here then things have been submitted and we
                # can now clear the flag that some things may be in edit mode in p4
                P4_IN_EDIT_MODE = 0
                print(f"FYI: Created {logfile}")

    return

def update_p4_and_gitlab():
    global VARNAMES
    global GIT_OPS_ALLOWED

    dprint("update_p4_and_gitlab")

    p4root           = VARNAMES['P4_WORKSPACE_ROOTDIR'] 
    p4internal_tools = f"{p4root}/wwcad/msip/internal_tools"
    p4alpha_common   = f"{p4root}/wwcad/msip/alpha_common"
    status = cd( p4internal_tools )
    if status != 0:
        fatal_error( f"Something went wrong trying to 'cd' to '{p4internal_tools}'")
        fatal_error_exit()

    print( "")
    pwd()
    ANSWER = prompt_user_yesno("Continue with 'p4 sync'?", "Y")
    if ANSWER == "N":
       pass 
    else:
        ###################### p4 sync ... ###################################
        if IN_TEST_MODE == 1 :
            tprint( "p4 sync alpha_common")
            tprint( "p4 sync internal_tools")
        else:
            status = run_command(f"cd {p4alpha_common}; p4 sync ...")
            print( f"p4 sync alpha_common status={status}")
            status = run_command(f"cd {p4internal_tools}; p4 sync ...")
            print( f"p4 sync internal_tools status={status}")

    status = cd( VARNAMES['GIT_WORKSPACE_ROOTDIR'] )
    if status != 0 :
        fatal_error( f"Something went wrong trying to 'cd' to '{GIT_WORKSPACE_ROOTDIR}'")
        fatal_error_exit()


    if GIT_OPS_ALLOWED == True :
        print( "")
        pwd()
        ANSWER = prompt_user_yesno("Continue with 'git pull'?", "Y")
        if ANSWER == "n" or ANSWER == "N":
            pass
        else:
            ###################### git pull ... ###################################
            if IN_TEST_MODE == 1 :
                tprint( f"{GITAPP} pull")
            else:
                status = run_command(f"{GITAPP} pull")
                print( f"{GITAPP} pull status={status}")
    return

def git_cleanup():
    global VARNAMES
    global HOME
    global USER

    print(" ")
    iprint("Cleaning up your Git area. Removing logs generated from tests.")
    git_root    = VARNAMES['GIT_WORKSPACE_ROOTDIR']
    git_cleanup = f"/u/{USER}/bin/git_cleanup"
    if os.path.exists(git_cleanup):
        if IN_TEST_MODE == 1:
            tprint(f"{git_cleanup}")
        else:
            run_command( git_cleanup )
    if IN_TEST_MODE == 1:
        tprint(f"cd {git_root}; {GITAPP} clean -xf")
    else:
        run_command(f"cd {git_root}; {GITAPP} clean -xf")

        
def copy_git_to_p4():
    global VARNAMES
    global COPIED

    tool = VARNAMES['TOOL']
    pick = VARNAMES['PICK']
    git_workspace_rootdir = VARNAMES['GIT_WORKSPACE_ROOTDIR']
#    VARNAMES['GIT_SOURCE_TOOL_ROOT'] = f"{git_workspace_rootdir}/{tool}/dev/main"
    status = cd( VARNAMES['GIT_SOURCE_TOOL_ROOT'] )
    if status != 0:
        print( f"ERROR:  unable to cd into {VARNAMES['GIT_SOURCE_TOOL_ROOT']}")
        fatal_error_exit()

    print(" ")
    pwd()
    ANSWER = prompt_user_yesno("\nContinue with the COPY operations?", "Y")
    if ANSWER == "Y":
        gitpath   = VARNAMES['GIT_SOURCE_TOOL_ROOT']
        p4path    = VARNAMES['P4_SHELLTOOLS_TOOL_ROOT']
        git_files = find_files( "." )
        for fname in ( git_files ):
            from_git = f"{gitpath}/{fname}"
            just_fname = os.path.basename( fname )
            if warn_if_version_incorrect( just_fname, from_git, VARNAMES['TARGET_RELEASE'].rstrip() ):
                ANSWER = prompt_user_yesno("\nDo you wish to abort this install?", "Y")
                if ANSWER == "Y":
                    save_current_settings_exit()

        for fname in ( git_files ):
            # exclude/exclusion of some files from being copied
            if ignore(fname) or skip_file( fname ) or skip_path( f"{gitpath}/{fname}") :
                dprint(f"Skipping or Ignoring: {fname}")
                continue
            from_git       = f"{gitpath}/{fname}"
            to_p4          = f"{p4path}/{fname}"
            to_p4_relative = f"{fname}"

            isMissingInP4  = not os.path.exists( to_p4 ) 
            isSame         = exact_same_file( from_git, to_p4)
            if IN_TEST_MODE == 1:
                if is_dev_main_bin_symlink( from_git ):
                    cp_arg = '-d'
                else:
                    cp_arg = ''

                if isSame:
                    pass #tprint( f"{to_p4_relative} No Copy Needed, they are the same files" )
                elif isMissingInP4:
                    tprint( f"{to_p4_relative} copy and p4 add required")
                    COPIED[f"{to_p4}"] = "copy|p4 add" 
                else:
                    tprint( f"{to_p4_relative} copied")
                    COPIED[f"{to_p4}"] = "copy" 
            else:
                # If the md5sum hashes are the same between the file in git
                # and the target then no need to update the target.
                confirmed = True 
                keeplink = ''
                if isSame:
                    status = 0
                else:
                    if pick:
                        confirmed = "Y" == prompt_user_yesno(f"Copy {to_p4_relative}?", "N")

                    status = cd( p4path )
                    if status != 0:
                        fatal_error( f"Something went wrong trying to 'cd'to '{p4path}'" )
                        fatal_error_exit()
                    if os.path.exists( to_p4 ):
                        if confirmed:
                            dprint(f"p4 edit {to_p4_relative}")
                            status = run_command(f"p4 edit {to_p4_relative}")
                            dprint(f"p4 edit status={status}")
                            if status != 0:
                                fatal_error(f"p4 edit {to_p4_relative}")
                                fatal_error_exit()
                        
                    status = cd( VARNAMES['GIT_WORKSPACE_ROOTDIR'] )
                    if status != 0:
                        fatal_error( f"Something went wrong trying to 'cd'to '{GIT_WORKSPACE_ROOTDIR}'" )
                        fatal_error_exit()
                    # if we are making a copy from /bin we want to preserve the
                    # symlinks in there. We don't want to preserve Util symlinks
                    p4symlink = ''
                    if is_dev_main_bin_symlink( from_git ):
                        keeplink = '-d'
                        p4symlink = ' -t symlink'
                    dprint(f"cp {keeplink} --preserve {from_git} {to_p4}")
                    if confirmed:
                        status = run_command( f"cp {keeplink} --preserve {from_git} {to_p4}" )
                        COPIED[f"{to_p4}"] = "copy" 
                        if status == 0 and isMissingInP4 :
                            # This is a new file in GitLab source area that is not
                            # yet in the Shelltools area. We need to 'p4 add' it
                            status = cd( p4path )

                            dprint(f"p4 add{p4symlink} {to_p4_relative}")
                            status = run_command( f"p4 add{p4symlink} {to_p4_relative}")
                            if status != 0:
                                fatal_error(f"p4 add {to_p4_relative}")
                                fatal_error_exit()
                            COPIED[f"{to_p4}"] = "copy|p4 add"

                if confirmed and status != 0:
                    # Maybe the destination folder of the file does not yet
                    # exist and maybe we need to create it. Let's check if 
                    # that is the issue and then prompt the user if they wish
                    # to create that directory.
                    
                    check_dirpath = os.path.dirname( to_p4 ) 
                    if not os.path.exists( check_dirpath ):
                        print( f"Missing target directory {check_dirpath} .")
                        ANSWER = prompt_user_yesno( f"Create it?", "Y")
                        if ANSWER == 'Y':
                            create_dir( check_dirpath )
                            status = run_command(f"cp {keeplink} --preserve {from_git} {to_p4}")
                            if status != 0:
                                eprint(f"Tried copy {fname} for the 2nd time and it failed")
                            else:
                                # copy worked; if this is a new file then p4 add
                                COPIED[f"{to_p4}"] = "copy"
                                if isMissingInP4:
                                    p4_add_status = run_command( f"p4 add {to_p4_relative}")
                                    COPIED[f"{to_p4}"] = "copy|p4 add"

                        else:
                            COPIED[f"{to_p4}"] = "copy|failed"
                            print( f"FAILED: Unable to copy; please fix issue and try again!")
                            fatal_error_exit()
    return

def get_md5_hex( fname ):
    if not os.path.exists( fname ):
        return 'FFFFFFFFFFFFFF'

    md5_hash = hashlib.md5()
    with open(fname, "rb") as f:
        for byte_block in iter(lambda: f.read(4096),b""):
            md5_hash.update(byte_block)
        return md5_hash.hexdigest()

def is_dev_main_bin_symlink( from_file ):
    is_a_symlink = False
    # we only want to look at files, not directories. If a directory
    # was passed to this function, then return False
    if os.path.isdir( from_file ):
        return False
    # Search for pattern to see if the passed in file is in /dev/main/bin
    # and that the pattern matches a valid filename
    result = re.search( 'dev/main/(./)?bin/[-_.A-Za-z0-9]*$', from_file )
    if result != None:
        # we know that this is a file in dev/main/bin but is it a symlink?
        is_a_symlink = os.path.islink( from_file )
        # some files we want to copy and not preserve the symlink
        if is_a_symlink:
            resolved_symlink = os.readlink( from_file )
            dprint(f"resolved_symlink = {resolved_symlink}")
            if re.search( '/admin/', resolved_symlink):
                is_a_symlink = False
                dprint("set is_a_symlink to False")

    return is_a_symlink 

def exact_same_file( f1, f2):
    hex_f1 = get_md5_hex(f1)
    hex_f2 = get_md5_hex(f2)
    return hex_f1 == hex_f2

def get_file_version( fullpath ):
    dprint(f"get_file_version {fullpath}")
    fileh = open( fullpath, 'r' )
    file_version = '' 
    for line in fileh: 
        if re.search( '^\s*#', line):
            continue
        if re.search( '^\s*$', line):
            continue
        file_version = line.rstrip()

    return file_version

def warn_if_version_incorrect( filename, fullpath, target_version ):
    # is this filename a .version file ?
    if filename != '.version':
        return 0

    dprint(f"warn_if_version_incorrect: '{filename}'")
    # this is a .version file - does it contain the correct VERSION number?
    file_version = get_file_version( fullpath )
    if file_version:
        if file_version != target_version:
            wprint(f"Your Tool's .version file '{file_version}' does not match your target version '{target_version}'")            
            return 1

    return 0
 
def process_cmd_line_args():
    global VARNAMES
    global IN_TEST_MODE
    global DEBUG

    my_parser = argparse.ArgumentParser(
            description='Install tool from git to p4 shelltools')

    my_parser.add_argument( '--testmode' 
        , action='store_true'
        , help = f"Do not run cp, p4, and git commands"
    )
    my_parser.add_argument( '--debug' 
        , action='store_true'
        , help = f"Allows internal dprint() calls to work"
    )
    my_parser.add_argument( '--pick' 
        , action='store_true'
        , help = f"Prompts for each copy operation. Lets you pick which files to copy."
    )

    my_parser.add_argument( '-c', '--config' 
        , metavar='CONFIGURATION'
        , required=False
        , type=str
        , help = f"A config file to set required variables. Default is {DEFAULT_CONFIG_FILE}"
    )
    my_parser.add_argument( '--tool' 
        , metavar='TOOL'
        , required=False
        , type=str
        , help = 'Tool name you wish to install (eg. ddr-ckt-rel)'
    )
    my_parser.add_argument( '--tag' 
        , metavar='TAG'
        , required=False
        , type=str
        , help = 'TAG name to apply to the commit.'
    )
    my_parser.add_argument( '--release' 
        , metavar='TARGET_RELEASE'
        , required=False
        , type=str
        , help = 'The release you are targeting. (eg. YYYY.MM[-PATCH] ).'
    )
    my_parser.add_argument( '-l', '--last_release_tag' 
        , metavar='LAST_RELEASE_TAG'
        , required=False
        , type=str
        , help = 'The Git Tag of the last release for this tool (eg. ddr-ckt-rel-2022.05)'
    )
#    my_parser.add_argument( '-v', '--version'
#        , metavar='SHELLTOOLS_REL_VERSION'
#        , required=False
#        , type=str
#        , help = 'The Shelltools Release Version (eg. 2022.03)'
#    )
    args = my_parser.parse_args()

    if args.config:
        read_config_file( args.config )

    if args.pick:
        VARNAMES['PICK'] = True

    if args.tool:
        VARNAMES['TOOL'] = args.tool
        VARNAMES['GIT_SOURCE_TOOL_ROOT'] = \
            f"{VARNAMES['GIT_WORKSPACE_ROOTDIR']}/{VARNAMES['TOOL']}/dev/main"
        VARNAMES['GIT_SOURCE_TOOL_DOC'] = \
            f"{VARNAMES['GIT_WORKSPACE_ROOTDIR']}/{VARNAMES['TOOL']}/dev/main/doc"

# 4/13/2022 - we dont' want to be able to change version; should always be 'dev'
#    if args.version:
#        VARNAMES['SHELLTOOLS_REL_VERSION'] = args.version

    if args.tag:
        VARNAMES['TAG'] = args.tag

    if args.testmode:
        IN_TEST_MODE = 1

    if args.debug:
        DEBUG = 1
       
    if args.last_release_tag:
        VARNAMES['LAST_RELEASE_TAG'] = args.last_release_tag

    if args.release:
        VARNAMES['TARGET_RELEASE'] = args.release

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

    dprint("verify_root_dirs_exist")

    if not os.path.exists( VARNAMES['P4_WORKSPACE_ROOTDIR'] ):
        print( f"**FAILED** Can't find P4_WORKSPACE_ROOTDIR {VARNAMES['P4_WORKSPACE_ROOTDIR']}")
        fatal_error_exit()

    if not os.path.exists(VARNAMES['GIT_WORKSPACE_ROOTDIR']):
        print( f"**FAILED** Can't find GIT_WORKSPACE_ROOTDIR {VARNAMES['GIT_WORKSPACE_ROOTDIR']}")
        fatal_error_exit()

    if not os.path.exists( f"{VARNAMES['GIT_SOURCE_TOOL_ROOT']}"):
        print( f"**FAILED** Can't find GIT_SOURCE_TOOL_ROOT {VARNAMES['GIT_SOURCE_TOOL_ROOT']}")
        fatal_error_exit()

    p4_shelltools_tool_root = VARNAMES['P4_SHELLTOOLS_TOOL_ROOT']
    if not os.path.exists( p4_shelltools_tool_root ):
        print( f"Can't find {p4_shelltools_tool_root}")
        ANSWER = prompt_user_yesno( f"Do you want to create {p4_shelltools_tool_root}", "N")
        if ANSWER == 'Y':
            status = create_dir( p4_shelltools_tool_root )
    return

def create_module_version_file( filename ):
    file_contents = "#%Module1.0\nset ModulesVersion \"dev\""
    if IN_TEST_MODE == 1:
        tprint("create the .version file")
        dprint(file_contents)
        return

    fh = open( f"{filename}", "w")
    fh.write( file_contents.strip() )
    fh.close()
    return

def create_module_dot_file( modules_folder, tool_name):
    placeholder_str = 'PLACEHOLDER_TOOLNAME'
    dot_file_contents = """
#%Module1.0

# This module file is intended to be minimal for MSIP Shelltools use.
# No need to modify when a new version is added, just make the new symlink.
# It should be simple to modify this file for any non-binary app that
# gets released under Shelltools or SharedLib or CDtools.
#
# It will also autodetect if your MODULEPATH points to your p4 workspace
# and attempt to switch the global(app,prefix) to point at your workspace
# accordingly.

### Edit these two lines and the last two lines as required to map the
### modulefile to a new tool.
set global(app,tooltype) "Shelltools"
set global(app,tooldir) "PLACEHOLDER_TOOLNAME"
#
# Generic content
set global(install,wwcad_email) "sg-ww-cad@synopsys.com"
set global(install,installer_info) "Synopsys Worldwide CAD <sg-ww-cad@synopsys.com>"

# Path to modulefile comes in, process for name/version.
set list [ split $ModulesCurrentModulefile / ]
set global(install,abbr_app_name) [ lindex $list end-1 ]
set global(install,version_number) [ lindex $list end-0 ]

# For info and help
set global(app,vendor) "Synopsys_SG_MSIP"
set global(install,app_title) "SG MSIP $global(install,abbr_app_name)"

# Source /global/etc/modules/modulesrc
set global(module,global) "$env(MODULES_RC)"
if { [ file exists $global(module,global) ] } {
   source $global(module,global)
} else {
   puts stderr "Cannot locate \$MODULES_RC variable: cannot continue."
   exit
}

### If the modulefile is in cad-rep, put the app in cad-rep.
### Else if the modulefile appears to in a personal p4 workspace, point the app at the
### workspace branch if it exists, else dev/main.
if { [regexp {^/remote/cad-rep/etc/modulefiles/msip} "$ModulesCurrentModulefile"] } {
   set global(app,prefix) "/remote/cad-rep/msip/tools/$global(app,tooltype)/$global(app,tooldir)/$global(install,version_number)"
} elseif { [regexp {^.*/internal_tools/} "$ModulesCurrentModulefile" global(app,toolroot)] } {
   if { [file isdirectory "$global(app,toolroot)$global(app,tooltype)/$global(app,tooldir)/releases/$global(install,version_number)"] } {
      set global(app,prefix) "$global(app,toolroot)$global(app,tooltype)/$global(app,tooldir)/releases/$global(install,version_number)"
   } else {
      set global(app,prefix) "$global(app,toolroot)$global(app,tooltype)/$global(app,tooldir)/dev/main"
   }
} else {
   ### Eeek, give up and make the app location /dev/null so it fails below.
   set global(app,prefix) "/dev/null"
}

# Sanity check app directory
if { [file isdirectory "$global(app,prefix)"] } {
   file stat $global(app,prefix) prefix
   set global(install,install_date) [ clock format $prefix(mtime) -format "%b %d, %Y" ]
} else {
   puts stderr $global(install,error)
   return
}

set global(app,help) "

This module file sets up the environment for $global(install,app_title).
Version: $global(install,version_number)

For configuration info, type:
   % module display $global(install,abbr_app_name)/$global(install,version_number)

For all assistance, please send e-mail to:
   $global(install,wwcad_email)

"

set global(app,display) "
$global(install,app_title) $global(install,version_number)

For help, type:
   % module help $global(install,abbr_app_name)
"

proc ModulesHelp { } {
   global global
   puts stderr "$global(app,help)"
}

proc ModulesDisplay { } {
   global global
   puts stderr "$global(app,display)"
}

module-whatis "$global(install,app_title)"

### Actual payload here, modify for your Shelltool/CDtool as required.
prepend-path PATH $global(app,prefix)/bin
"""

    # Substitute the placeholder in the above string with the tool_name
    file_contents = dot_file_contents.replace( placeholder_str, tool_name)

    if IN_TEST_MODE == 1:
        tprint(f"Created {modules_folder}/.{tool_name}")
        dprint(file_contents)
        return

    fh = open( f"{modules_folder}/.{tool_name}", "w")
    fh.write( file_contents.strip() )
    fh.close()
    iprint( f"Created {modules_folder}/.{tool_name}" )
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

    dprint("user_verify_settings")

    for VARNAME in REQUIRED_DIRS :
        print( "")
        VARVALUE = VARNAMES[VARNAME]
        print( f"{VARNAME} : {VARVALUE}")
        print( "Hit RETURN to accept, otherwise enter a new value")
        ANSWER = input("> ").strip()
        while ANSWER != "" and not os.path.exists(ANSWER): 
            print( f"**ERROR** Directory '{ANSWER}' does not exist, try again please")
            ANSWER = input("> ").strip()
        
        if ANSWER != "":
            VARNAMES[VARNAME] = ANSWER

    for VARNAME in VERIFY_VARS:
        print( "")
        VARVALUE = VARNAMES[VARNAME]
        print( f"{VARNAME} : {VARVALUE}")
        print( "Hit RETURN to accept, otherwise enter a new value")
        if VARNAME == 'TARGET_RELEASE':
            print( "Note: this is only used in the comment for the git tag")
        ANSWER = input("> ").strip()
        if ANSWER != "":
            VARNAMES[VARNAME] = ANSWER

    p4_workspace_rootdir   = VARNAMES['P4_WORKSPACE_ROOTDIR']
    git_workspace_rootdir  = VARNAMES['GIT_WORKSPACE_ROOTDIR']
    shelltools             = VARNAMES['SHELLTOOLS']
    tool                   = VARNAMES['TOOL']
    shelltools_rel_version = VARNAMES['SHELLTOOLS_REL_VERSION']

    VARNAMES['P4_SHELLTOOLS_TOOL_ROOT'] = f"{p4_workspace_rootdir}/{shelltools}/{tool}"
    VARNAMES['GIT_SOURCE_TOOL_ROOT']    = f"{git_workspace_rootdir}/{tool}/dev/main"
    
    p4_shelltools_tool_root = VARNAMES['P4_SHELLTOOLS_TOOL_ROOT']

    if shelltools_rel_version == "dev" or shelltools_rel_version == "patch":
        VARNAMES['P4_SHELLTOOLS_TOOL_ROOT'] = f"{p4_shelltools_tool_root}/{shelltools_rel_version}/main"
        p4_shelltools_tool_root = VARNAMES['P4_SHELLTOOLS_TOOL_ROOT']
    else:
        fatal_error(f"You are not allowed to modify the Release Version for this script!!")
        fatal_error_exit()
    return

def ignore( fname ):
    global VARNAMES

    if VARNAMES['IGNORE'] == "":
        dprint("VARNAMES IGNORE is empty")
        return False

    dprint(f"re.search( VARNAMES['IGNORE']:'{VARNAMES['IGNORE']}', fname:'{fname}'")
    result = re.search( VARNAMES['IGNORE'] , fname )
    if result != None:
        dprint(f"Ignore File {fname}")
        return True
    
# Some files we don't want to copy over to Shelltools
#   tags  files - generated from gvim to help jump around in the code editor
#   .log? files - result of running test scripts
#   .p4   files - result of running test scripts
#   __pycache__ - seems to get created when running python scripts
#   .bread      - when running breadcrumb_git.py
#   .nfs.*      - sometimes this exists when a file isn't unlocked
#
def skip_file( fname ):
    result = re.search( '\.nfs[0-9a-f]+$', fname )
    if result != None:
        dprint(f"Skip File {fname}")
        return True
    result = re.search( 'README.md', fname )
    if result != None:
        dprint(f"Skip File {fname}")
        return True
    result = re.search( '\.log[0-9]?$', fname )
    if result != None:
        dprint(f"Skip File {fname}")
        return True
    result = re.search( '\.LOG[0-9]?$', fname )
    if result != None:
        dprint(f"Skip File {fname}")
        return True
    result = re.search( '\.tdy$', fname )
    if result != None:
        dprint(f"Skip File {fname}")
        return True
    result = re.search( '\.p4$', fname )
    if result != None:
        dprint(f"Skip File {fname}")
        return True
    result = re.search( 'cover_db', fname )
    if result != None:
        dprint(f"Skip File {fname}")
        return True
    result = re.search( '__pycache__', fname )
    if result != None:
        dprint(f"Skip File {fname}")
        return True
    result = re.search( '\.pytest_cache', fname )
    if result != None:
        dprint(f"Skip File {fname}")
        return True
    result = re.search( '\.bread', fname )
    if result != None:
        dprint(f"Skip File {fname}")
        return True
    result = re.search( 'tags$', fname)
    if result != None:
        dprint(f"Skip File {fname}")
        return True
    result = re.search( '\.swp$', fname)
    if result != None:
        dprint(f"Skip File {fname}")
        return True
    result = re.search( '\.swo$', fname)
    if result != None:
        dprint(f"Skip File {fname}")
        return True
    result = re.search( '\.swn$', fname)
    if result != None:
        dprint(f"Skip File {fname}")
        return True
    result = re.search( '\.swp$', fname)
    if result != None:
        dprint(f"Skip File {fname}")
        return True
    result = re.search( '\.old$', fname)
    if result != None:
        dprint(f"Skip File {fname}")
        return True
    result = re.search( '\.vscode$', fname)
    if result != None:
        dprint(f"Skip File {fname}")
        return True


def skip_path( path ):
    path = os.path.abspath(path)
    #dprint(f"abspath is '{path}'")
    result = re.search( 'main/tests/', path )
    if result != None:
        dprint(f"Skip Folder {path}")
        return True
    result = re.search( 'main/t/', path )
    if result != None:
        dprint(f"Skip Folder {path}")
        return True
    result = re.search( 'main/tdata/', path )
    if result != None:
        dprint(f"Skip Folder {path}")
        return True
    result = re.search( 'tcl/tests/', path )
    if result != None:
        dprint(f"Skip Folder {path}")
        return True
    result = re.search( 'perl/tests/', path )
    if result != None:
        dprint(f"Skip Folder {path}")
        return True
    result = re.search( 'python/tests/', path )
    if result != None:
        dprint(f"Skip Folder {path}")
        return True
    result = re.search( '/\.pytest_cache', path )
    if result != None:
        dprint(f"Skip Folder {path}")
        return True


    return False 

if __name__ == "__main__":
    main()

