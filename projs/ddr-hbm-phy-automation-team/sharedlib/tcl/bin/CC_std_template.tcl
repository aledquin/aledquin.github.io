#!/depot/tcl8.6.3/bin/tclsh8.6
###############################################################################
#
# Name    : CC_std_template.tcl
# Author  : Ahmed Hesham(ahmedhes)
# Date    : creation date here
# Purpose : description of the script.. can put on multiple lines
#
# Modification History
#     000 YOURNAME  CURRENT_DATE
#         Created this script
#     001 YOURNAME DATE_OF_YOUR_CHANGES
#         Description of what you have changed.
#     
###############################################################################

# nolint utils__script_usage_statistics
if {[namespace exists CC_std_template]} {
    namespace delete CC_std_template
}
set RealBin [file dirname [file normalize [info script]] ]
namespace eval ::CC_std_template {
    variable AUTHOR     "Ahmed Hesham(ahmedhes)"
    global RealBin
    variable PROGRAM_NAME [file tail [file normalize [info script]] ]
    # Optional if the script is to be called from a design
    variable oaDesign
    
    package require try         ;# Tcllib.
    # Source DA packages into the namespace

    # Import the procs and hide them from the user.
    # Now, all of the imported procs are prefixed with "_"
    namespace eval _packages {
        global RealBin
        source "$RealBin/../lib/tcl/Util/Messaging.tcl"
        source "$RealBin/../lib/tcl/Util/Misc.tcl"
    }
    namespace import _packages::Messaging::*
    namespace import _packages::Misc::*
    foreach procName [namespace import] {
        rename $procName "_$procName"
    }
    # Get the version number
    variable VERSION [_get_release_version]
    _utils__script_usage_statistics $PROGRAM_NAME $VERSION
}

#-----------------------------------------------------------------
# This is the actual Main procedure, all of the code should go in here.
# This proc is hidden from the user by the "_" prefix.
# nolint Main
#-----------------------------------------------------------------
proc ::CC_std_template::_Main {} {
    _iprint "Typical user message ... information only"
    _wprint "Typical user message ... warning only"
    _eprint "Typical user message ... error only"
    _dprint LOW "Typical debug message ... only if DEBUG exceeds first arg"
    _viprint LOW "Typical user message ... only if VERBOSITY exceeds first arg"
    lassign [_run_system_cmd "bash -c \"echo A\""] stdout stderr status
    #_fprint "FATAL mesage to user ... then exit with val '1'"
    return
}


#-----------------------------------------------------------------
# Delete the current namespace and forget the command
#-----------------------------------------------------------------
proc ::CC_std_template::_delete {} {
    namespace delete [namespace current]
    rename CC_std_template ""
}

#-----------------------------------------------------------------
# This proc is automatically called by the de::createCommand, it parses the
# arguments and calls the main proc within a try block to ensure that
# the log file is written even if the tool fails.
#-----------------------------------------------------------------
proc ::CC_std_template::execute {args} {
    array set myArgs $args
    # Save the old values for global variables if they exists
    global STDOUT_LOG VERBOSITY DEBUG
    if {[info exists STDOUT_LOG]} {
        set old_STDOUT_LOG $STDOUT_LOG
        set old_VERBOSITY  $VERBOSITY
        set old_DEBUG      $DEBUG
    }
    set STDOUT_LOG ""
    # Update the VERBOSITY and DEBUG
    set VERBOSITY $myArgs(-verbosity)
    set DEBUG $myArgs(-debug)
    # Get the design
    variable oaDesign
    if {[info exists myArgs(-design)]} {
        set oaDesign $myArgs(-design)
    } else {
        set oaDesign [ed]
    }
    # Call the actual Main proc
    try {
        set exitval [_Main]
    } on error {results errorOptions} {
        set exitval [_fprint [dict get $errorOptions -errorinfo]]
    } finally {
        global RUN_DIR_ROOT
        variable oaDesign

        set libName [db::getAttr libName -of $oaDesign]
        set cellName [db::getAttr cellName -of $oaDesign]
        set verifPath "$RUN_DIR_ROOT/$libName/$cellName"
        if {![file exists $verifPath]} {
            file mkdir $verifPath
        }
        set fileName "$verifPath/[namespace tail [namespace current]]_$cellName.log"
        _write_stdout_log $fileName
        if {[info exists old_STDOUT_LOG]} {
            set STDOUT_LOG $old_STDOUT_LOG
            set VERBOSITY  $old_VERBOSITY
            set DEBUG      $old_DEBUG
        } else {
            unset STDOUT_LOG
            unset VERBOSITY
            unset DEBUG
        }
        return
    }
}

set args [list]
lappend args [de::createArgument -verbosity \
                                -description "verbosity of user messaging" \
                                -optional true \
                                -default 0 \
                                -types int]
lappend args [de::createArgument -debug \
                                -description "verbosity of debug messaging" \
                                -optional true \
                                -hidden true \
                                -default 0 \
                                -types int]
lappend args [de::createArgument -design \
                                -description "The design used by the script." \
                                -optional true \
                                -types oaDesign]
de::createCommand CC_std_template \
                  -category ddr_utils \
                  -arguments $args \
                  -description "The std_template for CC tcl scripts."
