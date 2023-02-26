#!/depot/tcl8.6.3/bin/tclsh8.6
############################################################################
# File       : ddr_utils_loader.tcl
# Author     : Ahmed Hesham(ahmedhes)
# Date       : 06/08/2022
# Description: provides procedures for loading ddr_utils scripts
############################################################################
proc utils__script_usage_statistics {toolname version} {
    set prefix "ddr-da-"
    set reporter "/remote/cad-rep/msip/tools/bin/msip_get_usage_info"
    set cmd ""
    set script_dirname [file dirname [file normalize [info script]]]
    append cmd "$reporter --tool_name  \"${prefix}${toolname}\" "
    append cmd "--stage main --category ude_ext_1 "
    append cmd "--tool_path \"$script_dirname\" --tool_version \"$version\""

    exec sh -c $cmd &
}

set script_name [file tail [file rootname [file normalize [info script]]]]
utils__script_usage_statistics $script_name "2022ww30"

namespace eval ::ddr_utils {
    # Variables
    variable rootPath "/remote/cad-rep/msip/tools/Shelltools"
    variable toolPath ""
    # The current path as defined by the choice of the tool and version
    variable currentPath     ""
    variable toolNamesList   {ddr-utils ddr-utils-in08 ddr-utils-lay ddr-utils-timing}
    variable toolVersionList {}
    variable scriptsList     {}
    variable scriptDescription ""
    #Prefs definitions
    db::createPref ddrUtilsToolName    -value "" -description "tool name"
    db::createPref ddrUtilsToolVersion -value "" -description "tool version"
    db::createPref ddrUtilsScriptName  -value "" -description "script name"

    # CLI procs
    # load_utils: The procedure allows the user to load a script without using
    #             dialog. It can also be used to load a script at startup. 
    #             Can be used to load a script with a specific version.
    #             If the version is not passed, then the latest version will be
    #             loaded. If the tool has only one version, then that version 
    #             will be used instead.
    #             If the script name is not passed, then the list of scripts
    #             available for that tool is printed for the latest version.
    proc load_utils { toolName {scriptName ""} {toolVersion ""} } {
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
            de::sendMessage "Illegal version for $toolName. Please select one of the following" \
                            -severity "error"
            puts "\t\t[join $versionList "\n\t\t"]"
            puts "or leave it blank to use the latest version."
            return
        }
        # Get the path for the script and source it
        set currentPath "$toolPath/$toolVersion/bin"
        set script "$currentPath/$scriptName"
        set retVal [_source_script $script]
        if {$is_version_specified} {
            return
        }
        # If the script failed to be sourced, and the version was not specified,
        # try to load an earlier version
        set index [expr {[llength $versionList]-3}]
        while {$retVal == -1 && $index > -1} {
            set toolVersion [lindex $versionList $index]
            set currentPath "$toolPath/$toolVersion/bin"
            set script "$currentPath/$scriptName"
            de::sendMessage "Attempting to source an earlier version: $toolVersion" \
                            -severity "information"
            set retVal [_source_script $script]
            incr index -1
        }
        if {$retVal == -2} {
            de::sendMessage "Unable to find a working version for $scriptName" -severity "warning"
        }
        return
    }

    # _source_script: Sources the script at the global level. Catches the error
    #                 if the sourcing failed and returns -1. Returns -2 if the file
    #                 does not exist. Returns 0 for success
    proc _source_script {script} {
        variable currentPath
        if {![file exists $script]} {
            set scriptName [file tail $script]
            de::sendMessage "$scriptName does not exist in $currentPath." \
                            -severity "error"
            return -2
        } elseif {[catch {uplevel #0 source $script} err]} {
            de::sendMessage "Failed to source $script: $err" -severity "error"
            return -1
        } else {
            de::sendMessage "Sourced $script" -severity "information"
            return 0
        }
    }

    # _check_tool_name: Checks if the toolName exists in the list of legal tool names.
    #                   If it doesn't exists, then return from the caller proc.
    proc _check_tool_name {toolName} {
        variable toolNamesList
        if {[lsearch -exact $toolNamesList $toolName] == -1} {
            de::sendMessage "Illegal toolname $toolName. Please select one of the following" \
                            -severity "error"
            puts "\t[join $toolNamesList "\n\t"]"
            return -level 2
        }
        return
    }

    # list_utils: Prints the list of scripts available for the tool in the
    #             selected version. If a version is not passed, then the latest
    #             version will be used.
    proc list_utils { toolName {toolVersion ""} } {
        if {[lsearch -exact $::ddr_utils::toolNamesList $toolName] == -1} {
            de::sendMessage "Illegal toolname. Please select one of the following" \
                            -severity "error"
            puts "\t[join $::ddr_utils::toolNamesList "\n\t"]"
            return
        }
        set ::ddr_utils::toolPath "$::ddr_utils::rootPath/$toolName"
        
        set versionList [lsort [glob -tails -directory $::ddr_utils::toolPath "*"] ]
        if {$toolVersion == ""} {
            if {[llength $versionList] > 1} {
                set toolVersion [lindex $versionList end-1]
            } else {
                set toolVersion [lindex $versionList end]
            }
        } elseif {[lsearch -exact $versionList $toolVersion] == -1 } {
            de::sendMessage "Illegal version for $toolName. Please select one of the following" \
                            -severity "error"
            puts "\t[join $versionList "\n\t"]"
            puts "or leave it blank to use the latest version."
            return
        }
        set ::ddr_utils::currentPath "$::ddr_utils::toolPath/$toolVersion/bin"
        de::sendMessage "List of scripts:" -severity "information"
        puts "\t[join [glob -tails -directory $::ddr_utils::currentPath *.tcl] "\n\t"]"
    }

    # GUI procs
    # gui: Creates the dialog. It will call different procs according to the 
    #      user's interaction with the dialog.
    proc gui {} {
        set dialog      [gi::createDialog     ddrUtilsLoader \
                                             -title "DDR Utils Loader" \
                                             -execProc [namespace current]::load_utils_gui]
        set toolNames   [gi::createListInput  widgetToolNamesList \
                                             -parent $dialog \
                                             -items $::ddr_utils::toolNamesList \
                                             -value "" \
                                             -valueChangeProc [namespace current]::updateVersionList \
                                             -prefName ddrUtilsToolName \
                                             -header "Tools" \
                                             -allowSort false \
                                             -showFilter true]
        set toolVersion [gi::createListInput  widgetToolVersionList \
                                             -parent $dialog \
                                             -items "" \
                                             -value "" \
                                             -valueChangeProc [namespace current]::updateScriptList \
                                             -prefName ddrUtilsToolVersion \
                                             -header "Versions" \
                                             -allowSort false \
                                             -showFilter true]
        set scriptNames [gi::createListInput  widgetScriptsList \
                                             -parent $dialog \
                                             -items "" \
                                             -value "" \
                                             -prefName ddrUtilsScriptName \
                                             -header "Scripts" \
                                             -allowSort false \
                                             -required true \
                                             -showFilter true]
        gi::layout $toolVersion -rightOf $toolNames
        gi::layout $scriptNames -rightOf $toolVersion

        gi::_update
        set geom [db::getAttr geometry -of $dialog]
        lassign [split $geom "+"] tmp xoff yoff
        lassign [split $tmp "x"] x y
        if {$x < 760} {
            set x 760
        }
        if {$y < 300} {
            set y 300
        }
        db::setAttr geometry -of $dialog -value "$x\x$y+$xoff+$yoff"
    }

    # updateVersionList: Updates the list of versions for the tool when the user
    #                    selects a new tool from the dialog. The latest version
    #                    is automatically selected when the user switches to a
    #                    different tool.
    proc updateVersionList { widget } {
        set dialog   [db::getAttr parent -of $widget]
        set toolName [db::getAttr value  -of [gi::findChild widgetToolNamesList -in $dialog]]
        set ::ddr_utils::toolPath "$::ddr_utils::rootPath/$toolName"
        # Update the version list variable
        set ::ddr_utils::toolVersionList [lreverse [lsort [glob -nocomplain -tails -directory $::ddr_utils::toolPath "*"] ] ]
        db::setAttr items -of [gi::findChild widgetToolVersionList -in $dialog] \
                          -value $::ddr_utils::toolVersionList
        db::setAttr value -of [gi::findChild widgetToolVersionList -in $dialog] \
                          -value [lindex $::ddr_utils::toolVersionList 1]
        updateScriptList $widget
    }

    # updateScriptList: Updates the list of scripts for the selected tool and
    #                   the selected version. It's called when the user selects
    #                   a version from the dialog.
    proc updateScriptList {widget} {
        set dialog      [db::getAttr parent -of $widget]
        set toolVersion [db::getAttr value  -of [gi::findChild widgetToolVersionList -in $dialog]]
        if {$toolVersion eq "" } { return }
        set ::ddr_utils::currentPath "$::ddr_utils::toolPath/$toolVersion/bin"
        # Update the version list variable
        set ::ddr_utils::scriptsList [lsort -nocase [glob -nocomplain -tails \
                                                          -directory $::ddr_utils::currentPath *.tcl]]
        db::setAttr items -of [gi::findChild widgetScriptsList -in $dialog] \
                          -value $::ddr_utils::scriptsList
    }

    # load_utils_gui: Sources the script that the user selected fromt the
    #                 dialog.
    proc load_utils_gui { widget } {
        set scriptName [string trim [db::getPrefValue ddrUtilsScriptName]]
        set script "$::ddr_utils::currentPath/$scriptName"
        # source the script at top-level
        uplevel #0 source $script
        de::sendMessage "Sourced $script" -severity "information"
    }

    # create_menu: Creates a menu left to help in the layout and schematic views
    #              that contains the call to:
    #              ddr-utils loader dialog(gui proc)
    proc create_menu {} {
        set ddrUtilsMenu [gi::createMenu widgetDDRUtilsMenu -title "DDR-Utils"]
        gi::addMenu [gi::getMenus widgetDDRUtilsMenu] -to [gi::getWindowTypes leLayout] \
                                                -before [gi::getMenus giHelpMenu]
        gi::addMenu [gi::getMenus widgetDDRUtilsMenu] -to [gi::getWindowTypes seSchematic] \
                                                -before [gi::getMenus giHelpMenu]
        set ddrUtilsGUI [gi::createAction widgetDDRUtilsGUI -title "DDR Utils Loader" \
                                                      -command {ddr_utils::gui}]
        set ddrUtilsActions [gi::addActions widgetDDRUtilsGUI -to $ddrUtilsMenu]

        # Create a hidden menu for the ddr-utils-lay. It will be unhidden when
        # a scripts uses it.
        set ddrUtilsLayMenu [gi::createMenu widgetDdrUtilsLayMenu \
                                            -title "ddr-utils-lay" \
                                            -shown false]
        gi::createAction widgetDdrUtilsLayMenuAction \
                         -menu $ddrUtilsLayMenu \
                         -title "ddr-utils-lay"
        gi::addActions widgetDdrUtilsLayMenuAction -to $ddrUtilsMenu
        # Adding a return prevents the proc from printing the pointer.
        return
    }
}

# Create the menu when the script is sourced.
::ddr_utils::create_menu

if {[info exists ::ddr_utils::autoLoadList]} {
    unset ::ddr_utils::autoLoadList
}

# List of scripts to load for all projects.
lappend ::ddr_utils::autoLoadList {ddr-utils alphaLibCheck.tcl}
lappend ::ddr_utils::autoLoadList {ddr-utils alphaExtractUtils.tcl}
lappend ::ddr_utils::autoLoadList {ddr-utils alphaTagHierarchy.tcl}
lappend ::ddr_utils::autoLoadList {ddr-utils alphaCdUtils.tcl}
lappend ::ddr_utils::autoLoadList {ddr-utils alphaGenCosim.tcl}
lappend ::ddr_utils::autoLoadList {ddr-utils alphaGenSchemCsv.tcl}

if {[info exists ::ddr_utils::autoLoadList]} {
    foreach script $::ddr_utils::autoLoadList {
        ::ddr_utils::load_utils {*}$script
    }
}


################################################################################
# No Linting Area
################################################################################
# nolint Main
