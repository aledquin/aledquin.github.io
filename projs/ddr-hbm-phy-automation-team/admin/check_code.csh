#!/bin/tcsh -f
#
# NOTE: This script "check_code.csh" should reside in the 'admin'
#       folder of the repository using it.
#
## HISTORY:
#  001 ljames 8/2/2022
#      Added -short option. Will run perl_lint.pl with -short option
#  002 ljames 8/3/2022
#      Added -type VALUE option. Example:  -type python
#      This would treat the file as a python script even if it isn't 
#      recognized as a python script.
#  003 ljames 8/3/2022 2:30pm
#      Added -help option
#  004 ljames 10/17/2022 12:20pm
#      Added -symlink -nosymlink option
#  005 seguinn 01/26/2023 3:06pm
#      Added -printerrors option
#
set PERL      = /depot/perl-5.14.2/bin/perl
set PYTHON    = /depot/Python/Python-3.8.0/bin/python
set FAILED    = 0
set DEBUG     = 0
set PRINT_ERRORS = 0
# Set rootdir to find the absolute directory name of this script
set ROOTDIR   = `/bin/dirname $0`       # may be relative path
set ROOTDIR   = `cd $ROOTDIR && pwd`    # ensure absolute path
set GITROOT   = "$ROOTDIR/.."
set LINT_ARGS = ""

# If no args passed then print help
if ( $#argv == 0 ) then
    goto HELP_OUTPUT_AND_EXIT
endif

# Parse command line arguments
set narg = 1
set get_type = 0
set force_type = ""
# nosymlink=0 means -symlink which means include symlinks
# nosymlink=1 means skip symlinks
# the default is process symlinks don't skip them
set nosymlink = 0 

foreach arg ($argv)
    if ( "$arg" == "-nosymlink" ) then
        set nosymlink = 1
        set LINT_ARGS = "$LINT_ARGS -nosymlink"
        @ narg = $narg + 1
    endif
    if ( "$arg" == "-symlink" ) then
        set nosymlink = 0
        @ narg = $narg + 1
    endif

    if ( "$arg" == "-short" ) then
        set LINT_ARGS = "$LINT_ARGS -short"
        @ narg = $narg + 1
    endif
    if ( "$arg" == "-type" ) then
        @ narg = $narg + 1
        set get_type = 1
    endif
    if ( "$arg" == "-help" ) then
        goto HELP_OUTPUT_AND_EXIT
    endif
    if ( "$arg" == "-debug" ) then
        @ narg = $narg + 1
        set DEBUG = 1
    endif
    if ( "$arg" == "-printerrors" ) then
        @ narg = $narg + 1
        set PRINT_ERRORS = 1
    endif
    if ( $get_type == 1 ) then
        set force_type = $argv[$narg]
        set get_type = 0
        @ narg = $narg + 1
    endif
end

set file = $argv[$narg]
if ( ! -e $file ) then
    echo "-E- Unable to locate file '$file'"
    exit
endif

# if force_type was specified let us lowercase it for comparison reasons
if ( $force_type != "" ) then
    set force_type = `echo "$force_type" | tr '[A-Z]' '[a-z]'`
endif

if ( ! -e $GITROOT/admin/perl_lint.pl ) then
    echo "Ooops -  I dont' see perl_lint.pl at $GITROOT/admin/perl_lint.pl"
    echo "See check_code.csh around line 86"
    exit
endif

set PERL_LINT = "$GITROOT/admin/perl_lint.pl ${LINT_ARGS}"
set realfile = `realpath $file`
set opt="-L"
if ( $nosymlink ) then
    set opt=""
endif

# if this is a perl script then run the perl checks on it
set isperl = `file $opt $file | grep Perl`
if ($status == 0 || "$force_type" == "perl" ) then
    goto PERL_CHECKS
endif


# if this is a python script then run the python checks on it
set ispython = `file $opt $file | grep Python`
if ($status == 0 || "$force_type" == "python" ) then
    goto PYTHON_CHECKS
endif

set istcl = `file $opt $file | grep -iP 'tclsh|wish'`
if ($status == 0) then
    goto TCL_CHECKS
endif
# This might still be a .tcl script but without a hash-bang because it's
# used within another tool and sourced within that tool. We can look at
# the filename extension to see if it's a tcl script.
set istcl = `echo $file | grep -iP '\.tcl$'`
if ( $status == 0 ) then
    goto TCL_SOURCE_CHECKS
endif


goto UNSUPPORTED_CHECKS

# Start Perl Validation
PERL_CHECKS:
    if ( $DEBUG == 1) echo "PERL_CHECKS:"

    $PERL -c $file >& /dev/null
    set compile_status = $status
    if ( $compile_status != 0 ) then
        echo "FAILED COMPILE check '$realfile' return status=$compile_status"
        set FAILED = 1
    endif
    set WARN_SKIPFILES = 'qa_edit_gold|qa_edit_iterative'
    set WARN_NOHELP_SKIPFILES = 'CopyXMLFiles|netlist_rcupdate|dcck_config_update|dcck_reports|Misc\.pm'
    set skip = `echo $file | grep -P $WARN_SKIPFILES `
    set skip_warn_status = $status
    if ( $skip_warn_status != 0 ) then
        set fail_warning_help_log=/tmp/${USER}_warning_help$$.log
        if ( $DEBUG == 1) echo "$PERL -w $file -help"
        $PERL -w $file -help >& $fail_warning_help_log 
        set whstatus = $status
        if ( $whstatus != 0 ) then
            set skip = `echo $file | grep -P $WARN_NOHELP_SKIPFILES `
            set skip_warn_nohelp_status = $status
            if ( $skip_warn_nohelp_status != 0 ) then
                set fail_log=/tmp/${USER}_warning_nohelp$$.log
                if ( $DEBUG == 1 ) echo "$PERL -w $file"
                $PERL -w $file >&  $fail_log
                set wstatus = $status
                if ( $wstatus != 0) then
                    echo "FAILED COMPILE warning -help check '$realfile' return status=$whstatus"
                    echo "FAILED COMPILE warnings check '$realfile' return status=$wstatus"
                    echo "    See $fail_warning_help_log for details"
                    echo "    See $fail_log for details"
                    if ( $PRINT_ERRORS == 1 ) then
                        cat $fail_warning_help_log
                        cat $fail_log
                    endif
                    set FAILED = 1
                endif
            endif
        else
            # Check the help log; see if it mentions Undefined subroutine
            set find_undefined = `grep 'Undefined subroutine' $fail_warning_help_log`
            set undefstatus = $status
            if ( $undefstatus == 0 ) then
                echo "FAILED COMPILE warning -help check '$realfile' return status=$undefstatus"
                echo "    See $fail_warning_help_log for details"
                if ( $PRINT_ERRORS == 1 ) then
                    cat $fail_warning_help_log
                endif
                set FAILED = 1
            endif
        endif
    endif

    set lint_log = /tmp/ddr_da_lint_$$.log
    $PERL_LINT $file >& $lint_log
    if ( $status != 0 ) then
        echo "FAILED LINT checks '$realfile'. See $lint_log"
        if ( $PRINT_ERRORS == 1 ) then
            cat $lint_log
        endif
        set FAILED = 1
    else
        echo "PASSED LINT checks '$realfile'."
    endif

    if ( $FAILED == 1 ) then
        exit -1
    else
        echo "PASSED '$realfile'"
    endif

exit 0

# Start Python Validation
PYTHON_CHECKS:
    #echo "Compiling Python file."
    set compile_log = /tmp/py_compile_$$.log
    $PYTHON -m py_compile $file >& $compile_log
    if ( $status != 0 ) then
        echo "FAILED COMPILE check '$realfile'. See $compile_log"
        if ( $PRINT_ERRORS == 1 ) then
            cat $compile_log
        endif
        set FAILED = 1
    else
        echo "PASSED COMPILE check '$realfile'"
        rm -f $compile_log
    endif

    set python_lint = "$GITROOT/admin/python_lint.pl"
    set lint_log = /tmp/ddr_da_lint_py_$$.log
    $python_lint $file $LINT_ARGS >& $lint_log
    if ( $status != 0 ) then
        echo "FAILED LINT '$realfile'. See $lint_log"
        if ( $PRINT_ERRORS == 1 ) then
            cat $lint_log
        endif
        set FAILED = 1
    else
        echo "PASSED LINT '$realfile'."
        rm -f $lint_log
    endif

    if ( $FAILED == 1 ) then
        exit -1
    endif 

exit

TCL_CHECKS:
    set tcl_lint = "$GITROOT/admin/tcl_lint.pl"
    set lint_log = /tmp/ddr_da_lint_tcl_$$.log
    $tcl_lint $file >& $lint_log
    if ( $status != 0 ) then
        echo "FAILED TCL LINT checks '$realfile'. See $lint_log"
        if ( $PRINT_ERRORS == 1 ) then
            cat $lint_log
        endif
        set FAILED = 1
    else
        echo "PASSED TCL LINT checks '$realfile'. See $lint_log"
    endif

    if ( $FAILED == 1 ) then
        exit -1
    endif
exit

TCL_SOURCE_CHECKS:
    set tcl_lint = "$GITROOT/admin/tcl_lint.pl -source"
    set lint_log = /tmp/ddr_da_lint_tcl_sourcechecks_$$.log
    $tcl_lint $file >& $lint_log
    if ( $status != 0 ) then
        echo "FAILED TCL LINT source_checks '$realfile'. See $lint_log"
        if ( $PRINT_ERRORS == 1 ) then
            cat $lint_log
        endif
        set FAILED = 1
    else
        echo "PASSED TCL LINT source_checks '$realfile'. See $lint_log"
    endif

    if ( $FAILED == 1 ) then
        exit -1
    endif
exit

HELP_OUTPUT_AND_EXIT:
    echo "Usage:"
    echo "  check_code.csh [-short] [-[no]symlink] [-type python|perl|tcl] [-printerrors] [-help] filename"
    echo ""
    exit


UNSUPPORTED_CHECKS:
    # If this was a symbolic link to antoher file, we don't need to say
    # anything.
    set is_symbolic = `file $opt $file | grep 'symbolic link'`
    if ($status != 0) then
        # If the file is actually a directory, then we don't need to say anything
        if (! -d $file ) then
            echo "check_code.csh does not support this file type: '$realfile' "
        endif
    endif
EXIT_CHECKS:
exit

