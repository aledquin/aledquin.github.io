#!/bin/tcsh  -f
#
# Script  : find_func 
# Author  : James Laderoute
# Created : Feb 11 2022
#
# Purpose:
#   The DA team provides many scripts to the engineers and some of those
#   are perl modules which contain many functions. The engineer might want
#   to know where those functions come from. That is because many function
#   names do not indicate where they reside. So, this script is intended
#   to aid the engineer (and DA) which script contains that function 
#   definition.
#
# Usage:
#   ./find_func.csh <function-name>
#
# Example:
#   ./find_func.csh viprint
#
# Modifications:
#   002 ljames  3/16/2022
#       Fixed a minor issue that caused failure in the searches.
#   003 ljames  4/1/2022
#       No longer required to setenv SCRIPTS_AREA. The script now checks
#       to see where the script is being run from, and if it's under the
#       GitLab area, then we know that one directory above is where we want
#       to start our search.
#
#--

set SCRIPT_NAME = "find_func"
set EXCLUDES    = ".git|directory|^Binary"
set EXTENSIONS  = '\.pl|\.pm'

# Determine the absolute path of where this script is located
set rootdir = `dirname $0`
set abs_rootdir = `cd $rootdir && pwd`

# Get the name of the function that the user is searching for
if ( $#argv != 0 ) then
    set OPT = $argv[1]
    set FUNCTION = "sub\s+${OPT}"
else
    echo "Usage: $SCRIPT_NAME <function_name>"
    exit
endif

# search in person's area that holds all our scripts, can be in there local
# repo. They can set it to their GitLab workspace or where-ever our scripts
# reside.

if ( ! $?SCRIPTS_AREA ) then
    if ($abs_rootdir =~ '*ddr-hbm-phy-automation-team*' ) then
        cd $abs_rootdir
        cd ..
        set SCRIPTS_AREA = '.'
    else
        echo "This script does not know where your scripts are stored"
        echo ""
        echo "Please: setenv SCRIPTS_AREA <dir-path-where-scripts-are>"
        echo ""
        echo "For Example:"
        echo "    setenv SCRIPTS_AREA ~/GitLab/ddr-hbm-phy-automation-team"
        exit
    endif

endif

unalias find
unalias grep
unalias xargs

# do the actual search
find -P $SCRIPTS_AREA | grep -P ${EXTENSIONS} | grep -vP "${EXCLUDES}" | xargs grep --color -iP ${FUNCTION} | sort -u

exit

