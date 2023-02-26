#!/depot/tcl8.6.3/bin/tclsh8.6
############################################################################
# File       : ddr-icvwb_loader.tcl
# Author     : Ahmed Hesham(ahmedhes)
# Date       : 01/11/2023
# Description: provides procedures for loading ddr_utils scripts in ICVWB
############################################################################

if {[namespace exists ddr_utils]} {
    namespace delete ddr_utils
}

global RealBin DEBUG
set RealBin [file dirname [file normalize [info script]] ]
set DEBUG 0
namespace eval ::ddr_utils {
    variable AUTHOR     "Ahmed Hesham(ahmedhes)"
    variable PROGRAM_NAME [file tail [file normalize [info script]] ]


    # Source DA packages into the namespace
    namespace eval _packages {
        source "$RealBin/../lib/tcl/Util/Messaging.tcl"
        source "$RealBin/../lib/tcl/Util/Misc.tcl"
    }
    # Import the procs and hide them from the user.
    # Now, all of the imported procs are prefixed with "_"
    namespace import _packages::Messaging::*
    namespace import _packages::Misc::*
    foreach procName [namespace import] {
        rename $procName "_$procName"
    }
    # Get the version number
    variable VERSION [_get_release_version]
    _utils__script_usage_statistics $PROGRAM_NAME $VERSION
   
    # Variables
    variable rootPath "/remote/cad-rep/msip/tools/Shelltools"
    variable toolPath ""
    # The current path as defined by the choice of the tool and version
    variable currentPath     ""
    variable toolNamesList   {ddr-utils ddr-utils-in08 ddr-utils-lay ddr-utils-timing}
    variable toolVersionList {}
    variable scriptsList     {}
}

    # CLI procs
    # load_utils: The procedure allows the user to load a script without using
    #             dialog. It can also be used to load a script at startup. 
    #             Can be used to load a script with a specific version.
    #             If the version is not passed, then the latest version will be
    #             loaded. If the tool has only one version, then that version 
    #             will be used instead.
    #             If the script name is not passed, then the list of scripts
    #             available for that tool is printed for the latest version.
proc ::ddr_utils::load_utils { toolName {scriptName ""} {toolVersion ""} } {
    variable currentPath
    variable toolPath
    variable rootPath
    variable toolNamesList
    # If no script is specified, print the list of scripts in the latest version
    # for the tool
    if {$scriptName == ""} {
        list_utils $toolName
        return
    }
    # Check that the toolName is valid, returns from this level if it was invalid
    _check_tool_name $toolName
    # Set the toolPath
    set toolPath "$rootPath/$toolName"
    # Get the list of versions 
    set versionList [lsort [glob -tails -directory $toolPath "*"] ]
    # Check if the specified version exists for this tool or get the latest
    # version if it wasn't specified.
    set is_version_specified true
    if {$toolVersion == ""} {
        set is_version_specified false
        # If the tool has more than 1 version, i.e. dev and a release, then
        # use the latest release. Otherwise, use dev.
        if {[llength $versionList] > 1} {
            set toolVersion [lindex $versionList end-1]
        } else {
            set toolVersion [lindex $versionList end]
        }
    } elseif {[lsearch -exact $versionList $toolVersion] == -1 } {
        echo "Illegal version for $toolName. Please select one of the following" -error
        echo "\t\t[join $versionList "\n\t\t"]"
        echo "or leave it blank to use the latest version."
        return
    }
    # Get the path for the script and source it
    set currentPath "$toolPath/$toolVersion/bin"
    set script "$currentPath/$scriptName"
    set retVal [_source_script $script]
    return
}

# _source_script: Sources the script at the global level. Catches the error
#                 if the sourcing failed and returns -1. Returns -2 if the file
#                 does not exist. Returns 0 for success
proc ::ddr_utils::_source_script {script} {
    variable currentPath
    if {![file exists $script]} {
        set scriptName [file tail $script]
        echo "$scriptName does not exist in $currentPath." -error
    } elseif {[catch {uplevel #0 source $script} err]} {
        echo "Failed to source $script: $err" -error
    } else {
        echo "Sourced $script" -severity "information"
    }
}

# _check_tool_name: Checks if the toolName exists in the list of legal tool names.
#                   If it doesn't exists, then return from the caller proc.
proc ::ddr_utils::_check_tool_name {toolName} {
    variable toolNamesList
    if {[lsearch -exact $toolNamesList $toolName] == -1} {
        echo "Illegal toolname $toolName. Please select one of the following" -error
        echo "\t[join $toolNamesList "\n\t"]"
        return -level 2
    }
    return
}

# list_utils: Prints the list of scripts available for the tool in the
#             selected version. If a version is not passed, then the latest
#             version will be used.
proc ::ddr_utils::list_utils { toolName {toolVersion ""} } {
    variable toolNamesList
    variable rootPath
    variable toolPath
    variable currentPath
    if {[lsearch -exact $toolNamesList $toolName] == -1} {
        echo "Illegal toolname. Please select one of the following" -error
        echo "\t[join $toolNamesList "\n\t"]"
        return
    }
    set toolPath "$rootPath/$toolName"
    
    set versionList [lsort [glob -tails -directory $toolPath "*"] ]
    if {$toolVersion == ""} {
        if {[llength $versionList] > 1} {
            set toolVersion [lindex $versionList end-1]
        } else {
            set toolVersion [lindex $versionList end]
        }
    } elseif {[lsearch -exact $versionList $toolVersion] == -1 } {
        echo "Illegal version for $toolName. Please select one of the following" -error
        echo "\t[join $versionList "\n\t"]"
        echo "or leave it blank to use the latest version."
        return
    }
    set currentPath "$toolPath/$toolVersion/bin"
    echo "List of scripts:"
    echo "\t[join [glob -tails -directory $currentPath *.tcl] "\n\t"]"
}

if {[info exists ::ddr_utils::autoLoadList]} {
    unset ::ddr_utils::autoLoadList
}

# List of scripts to load for all projects.
lappend ::ddr_utils::autoLoadList {ddr-utils-lay ddr-icvwb-HM_coloring.tcl}
lappend ::ddr_utils::autoLoadList {ddr-utils-lay ddr-icvwb-pattern_coloring.tcl}
 
if {[info exists ::ddr_utils::autoLoadList]} {
    foreach script $::ddr_utils::autoLoadList {
        ::ddr_utils::load_utils {*}$script
    }
}

################################################################################
# No Linting Area
################################################################################
# nolint Main
