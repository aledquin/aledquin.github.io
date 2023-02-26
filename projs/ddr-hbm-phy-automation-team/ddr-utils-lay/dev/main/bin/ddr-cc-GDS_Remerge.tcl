#!/depot/tcl8.6.3/bin/tclsh8.6
###############################################################################
#
# Name    : ddr-cc-GDS_remerge.tcl
# Author  : Ahmed Hesham(ahmedhes)
# Date    : 11/07/2022
# Purpose : Automates the GDS remerge flow. It takes a DI GDS and a list of 
#           macros. It will generate the GDS for the macros list, and merge them
#           into the DI GDS. It can also prefix the top level macros when 
#           merging them. It will run DRC on both the original GDS and the
#           merged GDS and compare the results. It can also generate the CDL for
#           the macros and merge them into the DI CDL. 
#
# Modification History
#     000 ahmedhes  11/07/2022
#         Created a prototype for the dialog
#     001 YOURNAME DATE_OF_YOUR_CHANGES
#         Description of what you have changed.
#     
###############################################################################

# nolint utils__script_usage_statistics
if {[namespace exists GDS_remerge]} {
    namespace delete GDS_remerge
}

set RealBin [file dirname [file normalize [info script]] ]
set DEBUG 0
namespace eval ::GDS_remerge {
    variable AUTHOR     "Ahmed Hesham(ahmedhes)"
    variable RealBin   [file dirname [file normalize [info script]] ]
    variable PROGRAM_NAME [file tail [file normalize [info script]] ]
   
    package require try         ;# Tcllib.
    # Source DA packages into the namespace

    # Import the procs and hide them from the user.
    # Now, all of the imported procs are prefixed with "_"
    namespace eval _packages {
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

    # Create the required prefs used by the GUI
   db::createPref "GDSREMERGErunDir"              -value ""  -description "Run directory"
   db::createPref "GDSREMERGEinputGds"            -value ""  -description "Input GDS file"
   db::createPref "GDSREMERGEinputCdl"            -value ""  -description "Input CDL file"
   db::createPref "GDSREMERGEtopcellPrefixEnable" -value "0" -description "The enable for topcell prefixing"
   db::createPref "GDSREMERGEtopcellPrefix"       -value ""  -description "Prefix to add to the topcell"
   db::createPref "GDSREMERGEremergeCdl"          -value "0" -description "Remerge CDL"
   db::createPref "GDSREMERGEtopcellName"         -value "0" -description "The topcell name of the current GDS file"
   db::createPref "GDSREMERGElibName"             -value "" -description "The selected library from the list"
   db::createPref "GDSREMERGEcellName"            -value "" -description "The selected cell from the list"
   db::createPref "GDSREMERGEviewName"            -value "" -description "The selected view from the list"
}

#-----------------------------------------------------------------
# This is the actual Main procedure, all of the code should go in here.
# This proc is hidden from the user by the "_" prefix.
#-----------------------------------------------------------------
proc ::GDS_remerge::_Main {} {
    _create_dialog
    return
}


#-----------------------------------------------------------------
# Delete the current namespace and forget the command
#-----------------------------------------------------------------
proc ::GDS_remerge::_delete {} {
    namespace delete [namespace current]
    rename GDS_remerge ""
}

#-----------------------------------------------------------------
# Creates the dialog
#-----------------------------------------------------------------
proc ::GDS_remerge::_create_dialog {} {
    global env
    # Create the dialog
    set dialog   [gi::createDialog gdsRemergeDialog \
                                   -title "GDS Remerge" \
                                   -execProc [namespace code [list _dialog_execute_proc]] \
                                   ]
    # Create the tabgroup
    set tabGroup [gi::createTabGroup tabGroup -parent $dialog]
    # Create the main tab
    set mainTab [gi::createGroup mainTab \
                                 -parent $tabGroup \
                                 -label "main"]
    set runDir [gi::createFileInput widgetRunDir \
                                    -parent $mainTab \
                                    -label "Run Directory:" \
                                    -fileType "directory" \
                                    -required true \
                                    -prefName "GDSREMERGErunDir" \
                                    -mode save \
                                    ]
    set sourceGroup [gi::createGroup widgetSourceGroup \
                                     -parent $mainTab \
                                     -label "Source Files" \
                                     ]
    set sourceGdsFile [gi::createFileInput widgetSourceGdsFile \
                                           -parent $sourceGroup \
                                           -label "GDS:" \
                                           -fileMasks "*.gds*" \
                                           -required true \
                                           -prefName "GDSREMERGEinputGds" \
                                           ]
    set sourceCdlFile [gi::createFileInput widgetSourceCdlFile \
                                           -parent $sourceGroup \
                                           -label "CDL:" \
                                           -fileMasks "*.cdl*" \
                                           -required true \
                                           -prefName "GDSREMERGEinputCdl" \
                                           ]
    set prefixGroup [gi::createCheckableGroup widgetPrefixGroup \
                                              -parent $mainTab \
                                              -label "Top cell prefix" \
                                              -prefName "GDSREMERGEtopcellPrefixEnable" \
                                              ]
    set prefixEntry [gi::createTextInput widgetPrefixInput \
                                         -parent $prefixGroup \
                                         -prefName "GDSREMERGEtopcellPrefix" \
                                         ]
    set runGroup [gi::createGroup widgetRunGroup \
                                  -parent $mainTab \
                                  -label "PV Options:" \
                                  ]
    set drcConfig [ gi::createPushButton widgetDrcConfig \
                                         -label "DRC Config" \
                                         -parent $runGroup \
                                         -execProc [namespace code [list _show_config_dialog drc DRC Tapeout]] \
                                         ]
    set lvsConfig [ gi::createPushButton widgetLvsConfig \
                                         -label "LVS Config" \
                                         -parent $runGroup \
                                         -execProc [namespace code [list _show_config_dialog lvs LVS Tapeout]] \
                                         ]
    # Create the macros tab
    set macrosTab [gi::createGroup macrosTab \
                                   -parent $tabGroup \
                                   -label "macros"]
    set libNameList  [gi::createListInput  widgetLibNameList \
                                          -parent $macrosTab \
                                          -items [_getLibsList] \
                                          -value "" \
                                          -valueChangeProc [namespace code updateCellNameList] \
                                          -prefName "GDSREMERGElibName" \
                                          -header "Library" \
                                          -allowSort true \
                                          -showFilter true]
    set cellNameList [gi::createListInput  widgetCellNameList \
                                          -parent $macrosTab \
                                          -items "" \
                                          -value "" \
                                          -valueChangeProc [namespace code updateViewNameList] \
                                          -prefName "GDSREMERGEcellName" \
                                          -header "Cell" \
                                          -allowSort true \
                                          -showFilter true]
    set viewNameList [gi::createListInput  widgetViewNameList \
                                          -parent $macrosTab \
                                          -items "" \
                                          -value "" \
                                          -prefName "GDSREMERGEviewName" \
                                          -header "View" \
                                          -doubleClickProc [namespace code [list add_view_double_click]] \
                                          -allowSort true \
                                          -showFilter true]
    gi::layout $cellNameList -rightOf $libNameList
    gi::layout $viewNameList -rightOf $cellNameList
    set addView [ gi::createPushButton widgetAddView \
                                       -label "Add" \
                                       -parent $macrosTab \
                                       -execProc [namespace code [list add_view]] \
                                       ]
    set selectedViewsTable [gi::createTable widgetViewsTable \
                                            -parent $macrosTab \
                                            -alternatingRowColors true \
                                            -selectionModel multipleRows \
                                            -readOnly true]
    set numberCol [gi::createColumn -parent $selectedViewsTable \
                                    -readOnly true]
    set libCol [gi::createColumn -parent $selectedViewsTable \
                                 -label "Library" \
                                 -stretch true \
                                 -readOnly true]
    set cellCol [gi::createColumn -parent $selectedViewsTable \
                                  -label "Cell" \
                                  -stretch true \
                                  -readOnly true]
    set viewCol [gi::createColumn -parent $selectedViewsTable \
                                  -label "View" \
                                  -stretch true \
                                  -readOnly true]
    set removeView [ gi::createPushButton widgetRemoveView \
                                          -label "Remove" \
                                          -parent $macrosTab \
                                          -execProc [namespace code [list remove_view]] \
                                          ]
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
    return
}

#-----------------------------------------------------------------
# Gets the list of available libs
#-----------------------------------------------------------------
proc ::GDS_remerge::_getLibsList {} {
    set libsCollection [dm::getLibs]
    while { [set lib [db::getNext $libsCollection]] ne "" } {
        lappend libsList [db::getAttr lib.name]
    }
    return $libsList
}

#-----------------------------------------------------------------
# Gets the list of cells in a given library
#-----------------------------------------------------------------
proc ::GDS_remerge::_getCellsList {libName} {
    set cellsCollection [dm::getCells -libName $libName]
    while { [set cell [db::getNext $cellsCollection]] ne "" } {
        lappend cellsList [db::getAttr cell.name]
    }
    return $cellsList
}

#-----------------------------------------------------------------
# Gets the list of views for a given cell in a given library
#-----------------------------------------------------------------
proc ::GDS_remerge::_getViewsList {libName cellName} {
    set viewsCollection [dm::getCellViews -libName $libName \
                                          -cellName $cellName \
                                          -filter {%name=~/schematic|layout/} ]
    set viewList [list]
    while { [set view [db::getNext $viewsCollection]] ne "" } {
        lappend viewsList [db::getAttr view.name]
    }
    return $viewsList
}

#-----------------------------------------------------------------
# Updates the list of cells according to the selected library
#-----------------------------------------------------------------
proc ::GDS_remerge::updateCellNameList { widget } {
    set dialog  [db::getAttr parent -of $widget]
    set libName [db::getAttr value  -of [gi::findChild widgetLibNameList -in $dialog]]
    # Update the version list variable
    db::setAttr items -of [gi::findChild widgetCellNameList -in $dialog] \
                      -value [_getCellsList $libName]
    updateViewNameList $widget
}

#-----------------------------------------------------------------
# Updates the list of cells according to the selected library
#-----------------------------------------------------------------
proc ::GDS_remerge::updateViewNameList { widget } {
    set dialog   [db::getAttr parent -of $widget]
    set libName  [db::getAttr value  -of [gi::findChild widgetLibNameList -in $dialog]]
    set cellName [db::getAttr value  -of [gi::findChild widgetCellNameList -in $dialog]]
    # Update the version list variable
    if {$cellName == ""} {
        db::setAttr items -of [gi::findChild widgetViewNameList -in $dialog] \
                          -value ""
    } else {
        db::setAttr items -of [gi::findChild widgetViewNameList -in $dialog] \
                          -value [_getViewsList $libName $cellName]
    }
}

#-----------------------------------------------------------------
# Adds the selected view to the table
#-----------------------------------------------------------------
proc ::GDS_remerge::add_view { widget } {
    set dialog   [db::getAttr parent -of $widget]
    set libName  [db::getAttr value  -of [gi::findChild widgetLibNameList -in $dialog]]
    set cellName [db::getAttr value  -of [gi::findChild widgetCellNameList -in $dialog]]
    set viewName [db::getAttr value  -of [gi::findChild widgetViewNameList -in $dialog]]
    if {$libName == ""}  { error "Please select a library, a cell, and a view before trying to add to the table."}
    if {$cellName == ""} { error "Please select a cell, and a view before trying to add to the table."}
    if {$viewName == ""} { error "Please select a view before trying to add to the table."}


    set table [gi::findChild widgetViewsTable -in $dialog]
    set libCol  [gi::getColumns -parent $table -filter {%label == "Library"}] 
    set cellCol [gi::getColumns -parent $table -filter {%label == "Cell"}] 
    set viewCol [gi::getColumns -parent $table -filter {%label == "View"}] 
    set newRow [gi::createRow -parent $table]
    db::setAttr value -of [gi::getCells -row $newRow -column $libCol] \
                      -value $libName
    db::setAttr value -of [gi::getCells -row $newRow -column $cellCol] \
                      -value $cellName
    db::setAttr value -of [gi::getCells -row $newRow -column $viewCol] \
                      -value $viewName
    update_table $table
}

#-----------------------------------------------------------------
# Adds the double clicked view to the table
#-----------------------------------------------------------------
proc ::GDS_remerge::add_view_double_click { widget viewName} {
    set dialog   [db::getAttr parent -of $widget]
    set libName  [db::getAttr value  -of [gi::findChild widgetLibNameList -in $dialog]]
    set cellName [db::getAttr value  -of [gi::findChild widgetCellNameList -in $dialog]]
    if {$libName == ""}  { error "Please select a library, a cell, and a view before trying to add to the table."}
    if {$cellName == ""} { error "Please select a cell, and a view before trying to add to the table."}


    set table [gi::findChild widgetViewsTable -in $dialog]
    set libCol  [gi::getColumns -parent $table -filter {%label == "Library"}] 
    set cellCol [gi::getColumns -parent $table -filter {%label == "Cell"}] 
    set viewCol [gi::getColumns -parent $table -filter {%label == "View"}] 
    set newRow [gi::createRow -parent $table]
    db::setAttr value -of [gi::getCells -row $newRow -column $libCol] \
                      -value $libName
    db::setAttr value -of [gi::getCells -row $newRow -column $cellCol] \
                      -value $cellName
    db::setAttr value -of [gi::getCells -row $newRow -column $viewCol] \
                      -value $viewName
    update_table $table
}

#-----------------------------------------------------------------
# Updates the entries to the table, ensureing that they're all unqiue and that
# their numbering is correct
#-----------------------------------------------------------------
proc ::GDS_remerge::update_table { table } {
    set viewsList [get_table_entries $table]

    set numberCol [gi::getColumns -parent $table -filter {%label == ""}] 
    set libCol    [gi::getColumns -parent $table -filter {%label == "Library"}] 
    set cellCol   [gi::getColumns -parent $table -filter {%label == "Cell"}] 
    set viewCol   [gi::getColumns -parent $table -filter {%label == "View"}] 
    set ind 0
    foreach view $viewsList {
        lassign [split $view "/"] libName cellName viewName
        set newRow [gi::createRow -parent $table]
        db::setAttr value -of [gi::getCells -row $newRow -column $numberCol] \
                          -value [incr ind]
        db::setAttr value -of [gi::getCells -row $newRow -column $libCol] \
                          -value $libName
        db::setAttr value -of [gi::getCells -row $newRow -column $cellCol] \
                          -value $cellName
        db::setAttr value -of [gi::getCells -row $newRow -column $viewCol] \
                          -value $viewName
    }
}

#-----------------------------------------------------------------
# Get the list of entries in the table
#-----------------------------------------------------------------
proc ::GDS_remerge::get_table_entries { table } {
    set libCol  [gi::getColumns -parent $table -filter {%label == "Library"}] 
    set cellCol [gi::getColumns -parent $table -filter {%label == "Cell"}] 
    set viewCol [gi::getColumns -parent $table -filter {%label == "View"}] 
    set rowCollection [gi::getRows -parent $table -filter {%shown == 1}]
    set viewsList [list]
    while {[set row [db::getNext $rowCollection]] != ""} {
        set libName  [db::getAttr value -of [gi::getCells -row $row -column $libCol]]
        set cellName [db::getAttr value -of [gi::getCells -row $row -column $cellCol]]
        set viewName [db::getAttr value -of [gi::getCells -row $row -column $viewCol]]
        lappend viewsList "$libName/$cellName/$viewName"
        db::setAttr shown -of $row -value false
    }

    return [lsort -unique $viewsList]
}

#-----------------------------------------------------------------
# Removes the selected views from the table
#-----------------------------------------------------------------
proc ::GDS_remerge::remove_view { widget } {
    set dialog   [db::getAttr parent -of $widget]

    set table [gi::findChild widgetViewsTable -in $dialog]
   	set selectedRows [db::getAttr selection -of $table]
    db::foreach row $selectedRows {
        db::setAttr shown -of $row -value false
    }

    update_table $table
}

#-----------------------------------------------------------------
# Show the PV config dialog. Create a cellview if needed.
#-----------------------------------------------------------------
proc ::GDS_remerge::_show_config_dialog {type prefix menuName widget} {
    global env
    set dialog [db::getAttr root -of $widget]
    # Get the topcell name
    set runDir  [db::getAttr value -of [gi::getChildren widgetRunDir -parent $dialog]]
    set gdsFile [db::getAttr value -of [gi::getChildren widgetSourceGdsFile -parent $dialog]]
    if {$runDir == ""} {
        error "Please specify the run directory before opening the PV config dialog"
    }
    if {$gdsFile == ""} {
        error "Please specify the GDS file path before opening the PV config dialog"
    }
    set curDir [pwd]
    # The proc creates a log file in the current directory, so cd to the runDir
    # first. Create the runDir if it doesn't exist.
    if {![file exists $runDir]} {
        file mkdir $runDir
    }
    cd $runDir
    set topcell [ude::pv::gdsGetCellName $gdsFile]
    cd $curDir
    if {$topcell == ""} {
        error "Unable to get the topcell name for the GDS! Check $runDir/msip_layGdsGetTopCellName.log"
    }
    # Create the cellViews if needed
    _createCellViews $topcell [db::getAttr root -of $widget]
    # Show the dialog
    if {[regexp {pv/2020\.04$|pv/2020\.03$|pv/2020\.04\-1$} $env(MSIP_CD_PV)]} {
        MSIP_PV::openVerifWindow $type $prefix $menuName 0 $widget
    } else {
        MSIP_PV::openVerifWindow $type $prefix $menuName $widget
    }
}

#-----------------------------------------------------------------
# Create a new cell with the current GDS topcell name in the GDS_Remerge library
# and create an empty layout and schematic views for it.
#-----------------------------------------------------------------
proc ::GDS_remerge::_createCellViews {cellName dialog} {
    set libName "GDS_Remerge"
    set viewName "layout"
    # Referesh the libdefs to ensure that the GDS_remerge library exists
    dm::refreshLibs
    # Create the GDS_Remerge library if needed
    if {[db::isEmpty [dm::getLibs $libName]]} {
        _createGdsRemergeLib $dialog
    }
    if {[db::isEmpty [dm::getCells $cellName -libName ${libName}]]} {
        if {[catch { dm::createCell $cellName -libName ${libName} }]} {
            error "GDS_REMERGE: Failed to create $cellName under ${libName} - $err"
        } else {
            de::sendMessage "GDS_REMERGE: Successfully created $cellName under ${libName}"
            set dmCell [dm::getCells $cellName -libName ${libName}]
            # --> Create "layout" Cell View
            if {[catch { dm::createCellView layout -cell $dmCell -viewType "maskLayout" }]} {
                error "GDS_REMERGE: Failed to create layout view under ${libName}/$cellName - $err"
            } else {
                de::sendMessage "GDS_REMERGE: Successfully created the layout view under ${libName}/${cellName}"
                # --> Create "schematic" Cell View
                if {[catch { dm::createCellView schematic -cell $dmCell -viewType "schematic" }]} {
                    error "GDS_REMERGE: Failed to create the schematic view under ${libName}/$cellName - $err"
                } else {
                    de::sendMessage "GDS_REMERGE: Successfully created the schematic view under ${libName}/${cellName}"
                    set cxt [de::open [dm::getCellViews $viewName -libName $libName -cellName $cellName] -headless 0 -readOnly 0]
                    set des [db::getAttr topDesign -of $cxt]
                    oa::save $des
                }
            }
        }
    } else {
        set found 0
        db::foreach con [de::getContexts] {
            set topDesign [db::getAttr topDesign -of $con]
            set currLib [db::getAttr libName -of $topDesign]
            set currCell [db::getAttr cellName -of $topDesign]
            set currView [db::getAttr viewName -of $topDesign]
            if {$libName eq $currLib && $cellName eq $currCell && $viewName eq $currView} {
                gi::setActiveWindow [db::getAttr window -of $con] -raise true
                set found 1
                break
            }
        }
        if {$found == 0} {
            set cxt [de::open [dm::getCellViews $viewName -libName $libName -cellName $cellName] -headless 0 -readOnly 0]
        }
    }
}

#-----------------------------------------------------------------
# Create a library for the GDS_Remerge cells. The cells will allow the usage
# of MSIP_PV procs and to keep the preferences for each run.
#-----------------------------------------------------------------
proc ::GDS_remerge::_createGdsRemergeLib {dialog} { 
    global env
    set libName "GDS_Remerge"
    set runDir  [db::getAttr value -of [gi::getChildren widgetRunDir -parent $dialog]]
    if {[db::isEmpty [dm::getLibs $libName]]} {
        if {[catch { dm::createLib "$libName" -path "${runDir}/$libName" } err]} {
            error "GDS_REMERGE: Failed to create $libName under $runDir - $err"
        } else {
            db::attachTech $libName -refLibName $env(MSIP_PVBATCH_ATTACH_TECH)
            de::sendMessage "GDS_REMERGE: Successfully created $libName under $runDir"
        }
    }
}


#-----------------------------------------------------------------
# Prepares the data dict and then passes the control to the job
# scheduler
#-----------------------------------------------------------------
proc ::GDS_remerge::_dialog_execute_proc {dialog} {
    # First create the data dict
    set dataDict [_create_data_dict $dialog]
    # Open/Create the cellview if it was not done already
    _createCellViews [dict get $dataDict topcell] $dialog
    # Create a job group for the run
    set jobGroup "GDS_Remerge_[dict get $dataDict topcell]"
    set currentDesc "GDS Remerge for [dict get $dataDict topcell]"
    set actionFlag "false"
    if { ![db::isEmpty [xt::getJobGroups $jobGroup]]} {
        db::destroy [xt::getJobGroups $jobGroup]
    }
    xt::createJobGroup $jobGroup -expanded true -showProgress true -trackProgress true -runDesc $currentDesc
    dict set dataDict "jobGroup" $jobGroup
    _print_header_to_log $dataDict
    _export_gds $dataDict
    _generate_netlist $dataDict
}

#-----------------------------------------------------------------
# Formats the data required for all of the commands in the flow into an dict
# and returns it. When a job is done, the next command is called based on the
# remaining items in the data dict.
#-----------------------------------------------------------------
proc ::GDS_remerge::_create_data_dict {dialog} {
    global exportCmd env
    variable PROGRAM_NAME
    # Get the data from the dialog
    # Get the list of views from the table
    set exportLayoutViews ""
    set netlistSchematicViews ""
    set table [gi::findChild widgetViewsTable -in $dialog]
    set libCol  [gi::getColumns -parent $table -filter {%label == "Library"}] 
    set cellCol [gi::getColumns -parent $table -filter {%label == "Cell"}] 
    set viewCol [gi::getColumns -parent $table -filter {%label == "View"}] 
    set rowCollection [gi::getRows -parent $table -filter {%shown == 1}]
    while {[set row [db::getNext $rowCollection]] != ""} {
        set libName  [db::getAttr value -of [gi::getCells -row $row -column $libCol]]
        set cellName [db::getAttr value -of [gi::getCells -row $row -column $cellCol]]
        set viewName [db::getAttr value -of [gi::getCells -row $row -column $viewCol]]
        set viewPath "$libName/$cellName/$viewName"
        if {[regexp -nocase {.*layout.*} $viewName]} {
            lappend exportLayoutViews $viewPath
        } else {
            lappend netlistSchematicViews $viewPath
        }
    }
    if {$exportLayoutViews == ""} {
        error "No layout views were selected!"
    }
    # Run directory
    set runDir [db::getPrefValue GDSREMERGErunDir]
    # Input Files
    set originalCdl [db::getPrefValue GDSREMERGEinputCdl]
    set originalGds [db::getPrefValue GDSREMERGEinputGds]
    set curDir [pwd]
    # First, create the runDir if it doesn't exist.
    if {![file exists $runDir]} {
        file mkdir $runDir
    }
    cd $runDir
    set topcell [ude::pv::gdsGetCellName $originalGds]
    cd $curDir
    if {$topcell == ""} {
        error "Unable to get the topcell name for the GDS! Check $runDir/msip_layGdsGetTopCellName.log"
    }
    set runDir "$runDir/$topcell"
    if {[file exists $runDir]} {
        file delete -force -- $runDir
    }
    file mkdir $runDir
    # Create an export directory
    set exportDir "$runDir/exported_files"
    file mkdir "$exportDir/logs"
    # Create a directory for pv runs
    set pvDir "$runDir/PV"
    file mkdir "$pvDir/logs"
    set resultsDir "$runDir/results"
    file mkdir "$resultsDir"
    # Prefix option
    if {[db::getPrefValue GDSREMERGEtopcellPrefixEnable]} {
        set topcellPrefix [db::getPrefValue GDSREMERGEtopcellPrefix]
    } else {
        set topcellPrefix ""
    }
    # Get the export options
    set exportOptions [_set_export_options]
    # Netlisting lists
    set searchList [db::getPrefValue "MSIPLVSviewSearchList"]
    set includeNetlist $env(LVSincludeNetlist)
    set deleteSubckts  [db::getPrefValue "MSIPLVSdelSubckt"]
    # Create a log file
    set logFile "$runDir/$PROGRAM_NAME.log"
    # Create the Dict
    set dataDict [dict create "runDir" $runDir \
                              "pvDir" $pvDir \
                              "exportDir" $exportDir \
                              "resultsDir" $resultsDir \
                              "originalGds" $originalGds \
                              "originalCdl" $originalCdl \
                              "topcellPrefix" $topcellPrefix \
                              "exportCmd" $exportCmd \
                              "exportOptions" $exportOptions \
                              "exportLayoutViews" $exportLayoutViews \
                              "netlistSchematicViews" $netlistSchematicViews \
                              "searchList" $searchList \
                              "includeNetlist" $includeNetlist \
                              "deleteSubckts" $deleteSubckts \
                              "topcell" $topcell \
                              "topView" "layout" \
                              "logFile" $logFile \
                              ]
    return $dataDict
}

#-----------------------------------------------------------------
# Returns a string with export options common to all views.
#-----------------------------------------------------------------
proc ::GDS_remerge::_set_export_options {} {
    global env
    # Map Color Locks
    if { [info exists env(UDE_CC_MAP_COLOR)] } {
        set mapColorLocks "$env(UDE_CC_MAP_COLOR)"
    } else {
        if { ( [db::checkVersion -atLeast L-2016.06-3] ) } {
                set mapColorLocks "-colorMapping honor"
        } elseif { ( [db::checkVersion -atLeast L-2016.06] ) } {
                set mapColorLocks "-mapColorLocks"
        } else {
                set mapColorLocks ""
        }
    }
    # Convert Brackets
    set convertBrackets true
    set topLevelOnly false
    if {$convertBrackets && !$topLevelOnly && [db::checkVersion -atLeast L-2017.12]} {
        set convertBrakcetsString "-convertTextBrackets square"
        set convertBrackets 0
    } else {
        set convertBrakcetsString ""
    }
    # Convert path to polygon
    set pathToPolygon ""
    #set pathToPolygon "-pathToPolygon"
    # Filter zero width
    set filterZeroWidth "-filterZeroWidth"
    # Export depth
    set currentDepth [ db::getPrefValue dbExportStreamDepth ]
    if { $currentDepth == "" } { set currentDepth 20 }
    # layermap
    set verifMap $env(LayerMapFile)
    # Object Layer Map
    if {[info exists env(ojbectLayerMapFile)] && [file exists $env(ObjectLayerMapFile)]} {
        set objectlayermapString "-objectMap $env(ObjectLayerMapFile)"
    } else {
        set objectlayermapString ""
    }
    # GDSdbuPerUU
    set GDSdbuPerUUString ""
    if { [ info exists env(GDSdbuPerUU) ] } {
        set GDSdbuPerUUString "-dbuPerUU $env(GDSdbuPerUU)"
    } else {
        if {[db::isEmpty [db::getPrefs dbExportStreamDbuPerUU]] } {
            set GDSdbuPerUUString ""
            set GDSdbuPerUU ""
        } else {
            set GDSdbuPerUU [ db::getPrefValue dbExportStreamDbuPerUU ]
            if { $GDSdbuPerUU != "" } {
                set GDSdbuPerUUString "-dbuPerUU $GDSdbuPerUU"
            }
        }
    }   
    # Join the options list into a single string
    set exportOptions [join [list "-libDefFile [dm::getTopLibDefPath]" \
                                  "-layerMap" $verifMap \
                                  "-hierDepth" $currentDepth \
                                  "-text cdba" \
                                  $objectlayermapString \
                                  $GDSdbuPerUUString \
                                  $mapColorLocks \
                                  $convertBrakcetsString \
                                  $pathToPolygon \
                                  $filterZeroWidth \
                                  "-ver 3"
                            ] " "]
    return $exportOptions
}

proc ::GDS_remerge::_print_header_to_log {dataDict} {
    variable VERSION
    set messageDisplay "========================================================================================================================"
    _write_file [dict get $dataDict logFile] $messageDisplay "w"
    set messageDisplay "Starting GDS Remerge on [dict get $dataDict topcell]"
    _write_file [dict get $dataDict logFile] [_add_timestamp "-I- $messageDisplay"] "a"
    set messageDisplay "GDS_REMERGE Version: $VERSION"
    _write_file [dict get $dataDict logFile] [_add_timestamp "-I- $messageDisplay"] "a"
    set messageDisplay "GDS File: [dict get $dataDict originalGds]"
    _write_file [dict get $dataDict logFile] [_add_timestamp "-I- $messageDisplay"] "a"
    set messageDisplay "CDL File: [dict get $dataDict originalCdl]"
    _write_file [dict get $dataDict logFile] [_add_timestamp "-I- $messageDisplay"] "a"
    set messageDisplay "Run Directory: [dict get $dataDict runDir]"
    _write_file [dict get $dataDict logFile] [_add_timestamp "-I- $messageDisplay"] "a"
    if {[dict get $dataDict topcellPrefix] != ""} {
        set messageDisplay "Topcell Prefix: [dict get $dataDict topcellPrefix]"
        _write_file [dict get $dataDict logFile] [_add_timestamp "-I- $messageDisplay"] "a"
    }
    set messageDisplay "Selected Layout Views:"
    _write_file [dict get $dataDict logFile] [_add_timestamp "-I- $messageDisplay"] "a"
    foreach cell [dict get $dataDict exportLayoutViews] {
        set messageDisplay "\t$cell"
        _write_file [dict get $dataDict logFile] [_add_timestamp "-I- $messageDisplay"] "a"
    }
    set messageDisplay "GDS Export Options: [dict get $dataDict exportOptions]"
    _write_file [dict get $dataDict logFile] [_add_timestamp "-I- $messageDisplay"] "a"
    if {[llength [dict get $dataDict netlistSchematicViews]] != 0} {
        set messageDisplay "Selected Schematic Views:"
        _write_file [dict get $dataDict logFile] [_add_timestamp "-I- $messageDisplay"] "a"
        foreach cell [dict get $dataDict netlistSchematicViews] {
            set messageDisplay "\t$cell"
            _write_file [dict get $dataDict logFile] [_add_timestamp "-I- $messageDisplay"] "a"
        }
        set messageDisplay "Include Netlist: [dict get $dataDict includeNetlist]"
        _write_file [dict get $dataDict logFile] [_add_timestamp "-I- $messageDisplay"] "a"
        set messageDisplay "Delete Subckts: [dict get $dataDict deleteSubckts]"
        _write_file [dict get $dataDict logFile] [_add_timestamp "-I- $messageDisplay"] "a"
    }
    set messageDisplay "========================================================================================================================"
    _write_file [dict get $dataDict logFile] $messageDisplay "a"
}
#-----------------------------------------------------------------
# Generates the GDS for the specified layout view.
#-----------------------------------------------------------------
proc ::GDS_remerge::_export_gds {dataDict} {
    # Export all of the entries in parallel
    foreach currentEntry [dict get $dataDict exportLayoutViews] {
        lassign [split $currentEntry "/"] libName cellName viewName
        dict set dataDict "libName"  $libName
        dict set dataDict "cellName" $cellName
        dict set dataDict "viewName" $viewName
        # Prepare the job arguments
        set runDesc "Streaming out ${cellName}.gds"
        set messageDisplay "GDS_REMERGE: Streaming out ${cellName}.gds in [dict get $dataDict exportDir]."
        _write_file [dict get $dataDict logFile] [_add_timestamp "-I- $messageDisplay"] "a"
        set gdsFile "[dict get $dataDict exportDir]/${cellName}.gds"
        set logFiles "[dict get $dataDict exportDir]/logs/${cellName}_exportStream.log"
        set exitProc "::GDS_remerge::_export_gds_exit_proc"
        dict set dataDict "gdsFile" $gdsFile
        set jobName "${cellName}_GDS_Generation"
        set jobGroup [xt::getJobGroups [dict get $dataDict jobGroup]]
        # Delete the old gds file
        if {[file exists $gdsFile]} {
            file delete $gdsFile
        }
        # Prepare the jobCmd
        set jobCmd "cd [dict get $dataDict exportDir]; [dict get $dataDict exportCmd] -logFile logs/${cellName}.exportStream.log \
                    -gds $gdsFile \
                    -lib $libName \
                    -cell $cellName \
                    -view $viewName \
                    [dict get $dataDict exportOptions] \
                   "
        # Create the Job
        xt::createJob $jobName \
                      -type "batch" \
                      -cmdLine $jobCmd \
                      -runDesc $runDesc \
                      -files $logFiles \
                      -exitProc $exitProc \
                      -group $jobGroup \
                      -data $dataDict
    }
}

#-----------------------------------------------------------------
# Check that the export_gds job finished successfully and that the gds file
# exists. Calls the compress_gds proc afterwards.
#-----------------------------------------------------------------
proc ::GDS_remerge::_export_gds_exit_proc {xtJobObj} {
    # Check the exit status for the job
    set jobStatus [db::getAttr status -of $xtJobObj]
    set dataDict [db::getAttr data -of $xtJobObj]
    if { [db::getAttr status -of $xtJobObj] == "FINISHED" && [file exists [dict get $dataDict gdsFile]]} {
        set messageDisplay "GDS_REMERGE: Compressing [dict get $dataDict gdsFile] file."
        de::sendMessage $messageDisplay -severity information
        _write_file [dict get $dataDict logFile] [_add_timestamp "-I- $messageDisplay"] "a"
       _compress_gds $xtJobObj
    } else {
        set messageDisplay "GDS_REMERGE: ERROR [db::getAttr name -of $xtJobObj] failed check log: [db::getAttr files -of $xtJobObj]"
        de::sendMessage $messageDisplay -severity error
        _write_file [dict get $dataDict logFile] [_add_timestamp "-E- $messageDisplay"] "a"
    }
}

#-----------------------------------------------------------------
# Calls a job that compresses the GDS
#-----------------------------------------------------------------
proc ::GDS_remerge::_compress_gds {xtJobObj} {
    # Get the gds/.gz file name
    set dataDict [db::getAttr data -of $xtJobObj]
    dict set dataDict gzFile "[dict get $dataDict gdsFile].gz"
    # Check that a file with the same name doesn't exist
    if {[file exists [dict get $dataDict gzFile]]} {
        file delete [dict get $dataDict gzFile]
    }
    # Prepare the job arguments
    set runDesc "Compressing [dict get $dataDict gdsFile] file"
    set logFiles "[dict get $dataDict exportDir]/logs/[dict get $dataDict cellName]_gzipGDS.stdout"
    set jobName "[dict get $dataDict cellName]_GDS_Compress"
    set exitProc "::GDS_remerge::_compress_gds_exit_proc"
    set jobGroup [xt::getJobGroups [dict get $dataDict jobGroup]]
    # Prepare the jobCmd
    set jobCmd "gzip -v [dict get $dataDict gdsFile] > $logFiles 2>&1"
    xt::createJob $jobName \
                  -type "batch" \
                  -cmdLine $jobCmd \
                  -runDesc $runDesc \
                  -files $logFiles \
                  -exitProc $exitProc \
                  -group $jobGroup \
                  -data $dataDict
}

#-----------------------------------------------------------------
# Check that gzip finished successfully and return to the scheduler
#-----------------------------------------------------------------
proc ::GDS_remerge::_compress_gds_exit_proc {xtJobObj} {
    # Check the exit status for the job
    set jobStatus [db::getAttr status -of $xtJobObj]
    set dataDict [db::getAttr data -of $xtJobObj]
    if { [db::getAttr status -of $xtJobObj] == "FINISHED" && [file exists [dict get $dataDict gzFile]]} {
        set messageDisplay "GDS_REMERGE: Finished compressing [dict get $dataDict gdsFile] file sucessfully."
        de::sendMessage $messageDisplay -severity information
        _write_file [dict get $dataDict logFile] [_add_timestamp "-I- $messageDisplay"] "a"
       _check_gds $xtJobObj
    } else {
        set messageDisplay "GDS_REMERGE: ERROR [db::getAttr name -of $xtJobObj] failed check log: [db::getAttr files -of $xtJobObj]"
        de::sendMessage $messageDisplay -severity error
        _write_file [dict get $dataDict logFile] [_add_timestamp "-E- $messageDisplay"] "a"
    }
}

#-----------------------------------------------------------------
# Check the GDS for duplicate cells and that its dbu is correct, remove empty
# cells, fix none GDS characters
#-----------------------------------------------------------------
proc ::GDS_remerge::_check_gds {xtJobObj} {
    global env
    # Get the dataDict
    set dataDict [db::getAttr data -of $xtJobObj]
    # Prepare the check arguments
    set gzFile [dict get $dataDict gzFile]
    set exportedGds [regsub {\.gds\.gz} $gzFile {_original.gds.gz}]
    set gdsCheckArgs "$exportedGds [dict get $dataDict cellName]"
    append gdsCheckArgs " -rd [dict get $dataDict exportDir]/logs -o $gzFile"
    append gdsCheckArgs " -getDup -fixNoneGdsChars -rmEmpty"
    if {[info exists env(GDSdbuPerUU)]} {
        append gdsCheckArgs " -dbu $env(GDSdbuPerUU)"
    }
    # Create the job arguments
    set jobName "[dict get $dataDict cellName]_GDS_Check"
    set logFiles "[dict get $dataDict exportDir]/logs/msip_layHipreGdsManipulation.log"
    set runDesc "Checking the exported GDS using msip_layHipreGdsManipulation"
    set jobCmd "mv $gzFile $exportedGds; ${::MSIP_PV_HIPRE::hipreLayUtils}/bin/msip_layHipreGdsManipulation $gdsCheckArgs 2> [dict get $dataDict exportDir]/logs/msip_layHipreGdsManipulation.log.stderr"
    set jobGroup [xt::getJobGroups [dict get $dataDict jobGroup]]
    set exitProc "::GDS_remerge::_check_gds_exit_proc"
    xt::createJob $jobName \
                  -type "batch" \
                  -cmdLine $jobCmd \
                  -runDesc $runDesc \
                  -files $logFiles \
                  -exitProc $exitProc \
                  -group $jobGroup \
                  -data $dataDict
}

#-----------------------------------------------------------------
# Parse the log files for the checks and see if there were any issues
#-----------------------------------------------------------------
proc ::GDS_remerge::_check_gds_exit_proc {xtJobObj} {
    # Check the exit status for the job
    set jobStatus [db::getAttr status -of $xtJobObj]
    set dataDict [db::getAttr data -of $xtJobObj]
    if { [db::getAttr status -of $xtJobObj] == "FINISHED" && [file exists [dict get $dataDict gzFile]] \
         && [ file exists "[dict get $dataDict exportDir]/logs/msip_layHipreGdsManipulation.log.stderr"] \
         &&  [file size "[dict get $dataDict exportDir]/logs/msip_layHipreGdsManipulation.log.stderr"] == 0} {
        set messageDisplay "GDS_REMERGE: The checks on [dict get $dataDict gzFile] finished with status: PASS."
        de::sendMessage $messageDisplay -severity information
        _write_file [dict get $dataDict logFile] [_add_timestamp "-I- $messageDisplay"] "a"
        # Check that the all of the export operations are done
        set jobGroup [xt::getJobGroups [dict get $dataDict jobGroup]]
        set jobCol [db::getAttr jobs -of $jobGroup]
        set exportedGdsFiles ""
        while {[set job [db::getNext $jobCol]] != ""} {
            if {![regexp {GDS_Check} [db::getAttr name -of $job]]} {continue}
            if {[regexp {FINISHED} [db::getAttr status -of $job]]} {
                lappend exportedGdsFiles [dict get [db::getAttr data -of $xtJobObj] gzFile]
            } else {
                return
            }
        }
        # Check that all of the views have been exported
        if {[llength $exportedGdsFiles] == [llength [dict get $dataDict exportLayoutViews]]} {
            # Add the list of exported GDS files to the data dict
            dict set dataDict gdsFilesList $exportedGdsFiles
            # Unset the info related to this run from the dict
            dict unset dataDict [dict keys $dataDict *File]
            dict unset dataDict [dict keys $dataDict *Name]
            _merge_gds $dataDict
        }
    } else {
        set messageDisplay "GDS_REMERGE: The checks on [db::getAttr name -of $xtJobObj] finished with status: FAIL. For more information check the log: [db::getAttr files -of $xtJobObj]"
        de::sendMessage $messageDisplay -severity error
        _write_file [dict get $dataDict logFile] [_add_timestamp "-E- $messageDisplay"] "a"
    }
}

#-----------------------------------------------------------------
# Create a script that merges the original GDS file with the exported
# GDS files in overwrite mode.
#-----------------------------------------------------------------
proc ::GDS_remerge::_merge_gds {dataDict} {
    set runDir [dict get $dataDict runDir]
    set originalGds [dict get $dataDict originalGds]
    set originalGdsName [regsub {\..*$} [file tail $originalGds] {}]
    set mergedGds "$runDir/${originalGdsName}_merged.gds.gz"
    dict set dataDict "mergedGds" $mergedGds
    set icvwbScript [list "default layout_cache off"]
    lappend icvwbScript "set originalGdsFile \"$originalGds\""
    lappend icvwbScript "set mergedGdsFile \"$mergedGds\""
    lappend icvwbScript "# Open the original gds to get the dbu"
    lappend icvwbScript "set originalID \[layout open \$originalGdsFile\]"
    lappend icvwbScript "set dbu \[layout dbu -layout \$originalID\]"
    lappend icvwbScript "# Rename all of the cells as required"
    lappend icvwbScript "set gdsFilesList \"[dict get $dataDict gdsFilesList]\""
    if {[dict get $dataDict topcellPrefix] != ""} {
        lappend icvwbScript "set prefix [dict get $dataDict topcellPrefix]"
        lappend icvwbScript "set macros {}"
        lappend icvwbScript "foreach gdsFile \$gdsFilesList \{"
        lappend icvwbScript "\tlappend macros \"layout \[layout open \$gdsFile\]\""
        lappend icvwbScript "\tset cellName \[layout root cells\]"
        lappend icvwbScript "\tcell open \$cellName"
        lappend icvwbScript "\tcell edit_state 1"
        lappend icvwbScript "\tlayout cell rename \$cellName \$prefix\$cellName"
        lappend icvwbScript "\tlayout save -rename \[regsub {\.gdz\.gz} \$gdsFile {_renamed.gz.gz}\] -format gds.gz"
        lappend icvwbScript "\}"
    } else {
        lappend icvwbScript "set macros {}"
        lappend icvwbScript "foreach gdsFile \$gdsFilesList \{"
        lappend icvwbScript "\tlappend macros \"layout \$gdsFile\""
        lappend icvwbScript "\}"
    }
    lappend icvwbScript "layout merge overwrite \"layout \$originalGdsFile\" \[join \$macros \" \"\] -dbu \$dbu -format gds.gz -output \$mergedGdsFile"
    lappend icvwbScript "layout close *"
    lappend icvwbScript "exit"
    set icvwbScriptFile "$runDir/icvwb_merge.mac"
    _write_file $icvwbScriptFile [join $icvwbScript "\n"]
    # Create a shell script to execute the icvwb script
    set logFiles "$runDir/icvwb_merge.log"
    set shellScript "#!/bin/bash"
    lappend shellScript "source /remote/cad-rep/etc/.bashrc"
    lappend shellScript "module unload icvwb"
    lappend shellScript "module load icvwb"
    lappend shellScript "icvwb -nodisplay -run $icvwbScriptFile -exitOnError -log $logFiles"
    set shellScriptFile "$runDir/icvwb_merge.sh"
    _write_file $shellScriptFile [join $shellScript "\n"]
    # Create a job to execute the shell script
    set jobName "Merging_GDS"
    set runDesc "Merging the GDS files using ICVWB"
    set messageDisplay "GDS_REMERGE: Merging the exported layout views into $originalGds and writing the merged view to $mergedGds"
    de::sendMessage $messageDisplay -severity information
    _write_file [dict get $dataDict logFile] [_add_timestamp "-I- $messageDisplay"] "a"
    set exitProc "::GDS_remerge::_merge_gds_exit_proc"
    set jobGroup [xt::getJobGroups [dict get $dataDict jobGroup]]
    set jobCmd "cd $runDir; chmod 775 $shellScriptFile; $shellScriptFile"
    xt::createJob $jobName \
                  -type "batch" \
                  -cmdLine $jobCmd \
                  -runDesc $runDesc \
                  -files $logFiles \
                  -exitProc $exitProc \
                  -group $jobGroup \
                  -data $dataDict
}

#-----------------------------------------------------------------
# Check the exit status for merge_gds job
#-----------------------------------------------------------------
proc ::GDS_remerge::_merge_gds_exit_proc {xtJobObj} {
    # Check the exit status for the job
    set jobStatus [db::getAttr status -of $xtJobObj]
    set dataDict [db::getAttr data -of $xtJobObj]
    if { [db::getAttr status -of $xtJobObj] == "FINISHED" && [file exists [dict get $dataDict mergedGds]]} {
        set messageDisplay "GDS_REMERGE: Finished merging the files. [dict get $dataDict mergedGds] file was created successfully."
        de::sendMessage $messageDisplay -severity information
        _write_file [dict get $dataDict logFile] [_add_timestamp "-I- $messageDisplay"] "a"
        _run_lvl $dataDict
        _call_pv_jobs $dataDict
    } else {
        set messageDisplay "GDS_REMERGE: ERROR [db::getAttr name -of $xtJobObj] failed check log: [db::getAttr files -of $xtJobObj]"
        de::sendMessage $messageDisplay -severity error
        _write_file [dict get $dataDict logFile] [_add_timestamp "-E- $messageDisplay"] "a"
    }
}

#-----------------------------------------------------------------
# Call LVL
#-----------------------------------------------------------------
proc ::GDS_remerge::_run_lvl {dataDict} {
    global env
    set lvlDir "[dict get $dataDict pvDir]/LVL"
    file mkdir $lvlDir
    dict set dataDict "lvlDir" $lvlDir
    set lvlLines "#!/bin/bash"
    lappend lvlLines "source /remote/cad-rep/etc/.bashrc"
    lappend lvlLines "cd $lvlDir"
    lappend lvlLines "module unload icv"
    set icv [lsearch -inline [split $env(LOADEDMODULES) ":"] "icv*"]
    if {$icv == ""} {
        set icv "icv"
    }
    lappend lvlLines "module load $icv"
    lappend lvlLines "icv_lvl [dict get $dataDict originalGds] [dict get $dataDict mergedGds] -c [dict get $dataDict topcell]"
    set lvlFile "[dict get $dataDict pvDir]/lvl.sh"
    _write_file $lvlFile [join $lvlLines "\n"]
    # Create a job to execute the shell script
    set jobName "Running_LVL"
    set runDesc "Running LVL using the original and the merged GDS files"
    set messageDisplay "GDS_REMERGE: Running LVL between [dict get $dataDict originalGds] and [dict get $dataDict mergedGds] from $lvlDir"
    de::sendMessage $messageDisplay -severity information
    _write_file [dict get $dataDict logFile] [_add_timestamp "-I- $messageDisplay"] "a"
    set exitProc "::GDS_remerge::_run_lvl_exit_proc"
    set jobGroup [xt::getJobGroups [dict get $dataDict jobGroup]]
    set jobCmd "chmod 775 $lvlFile; $lvlFile"
    xt::createJob $jobName \
                  -type "batch" \
                  -cmdLine $jobCmd \
                  -runDesc $runDesc \
                  -exitProc $exitProc \
                  -group $jobGroup \
                  -data $dataDict
}

#-----------------------------------------------------------------
# Check the LVL exit status
#-----------------------------------------------------------------
proc ::GDS_remerge::_run_lvl_exit_proc {xtJobObj} {
    # Check the exit status for the job
    set jobStatus [db::getAttr status -of $xtJobObj]
    set dataDict [db::getAttr data -of $xtJobObj]
    xt::startPvDebugger -job drc -rundir [dict get $dataDict lvlDir]
    if { [db::getAttr status -of $xtJobObj] == "FINISHED"} {
        set messageDisplay "GDS_REMERGE: Finished running LVL"
        de::sendMessage $messageDisplay -severity information
        _write_file [dict get $dataDict logFile] [_add_timestamp "-I- $messageDisplay"] "a"
        set cmd "ln -s [dict get $dataDict lvlDir] [dict get $dataDict resultsDir]/LVL"
        _run_system_cmd $cmd
    } else {
        set messageDisplay "GDS_REMERGE: LVL failed!"
        de::sendMessage $messageDisplay -severity error
        _write_file [dict get $dataDict logFile] [_add_timestamp "-E- $messageDisplay"] "a"
    }
}

#-----------------------------------------------------------------
# Generates the netlist for the specified schematic view.
#-----------------------------------------------------------------
proc ::GDS_remerge::_generate_netlist {dataDict} {
    global env
    # Create a dummy job if no schematic views were selected, otherwise
    # generate the netlists in parallel
    if {[llength [dict get $dataDict netlistSchematicViews]] == 0} {
        dict set dataDict mergedCdl [dict get $dataDict originalCdl]
        set jobName "Merging_CDL"
        set runDesc "Merging the CDL files"
        set exitProc "::GDS_remerge::_merge_cdl_exit_proc"
        set jobGroup [xt::getJobGroups [dict get $dataDict jobGroup]]
        set jobCmd ""
        # Create the Job
        xt::createJob $jobName \
                      -type "batch" \
                      -cmdLine $jobCmd \
                      -runDesc $runDesc \
                      -exitProc $exitProc \
                      -group $jobGroup \
                      -data $dataDict

    } else {
        foreach currentEntry [dict get $dataDict netlistSchematicViews] {
            lassign [split $currentEntry "/"] libName cellName viewName
            dict set dataDict "libName"  $libName
            dict set dataDict "cellName" $cellName
            dict set dataDict "viewName" $viewName
            set cdlFile "[dict get $dataDict exportDir]/${cellName}.cdl"
            dict set dataDict "cdlFile"  $cdlFile
            # Delete the old cdl file
            if {[file exists $cdlFile]} {
                file delete $cdlFile
            }
            # Generate the netlist
            set cellView [dm::findCellView $viewName -cellName $cellName -libName $libName]
            set doneNetlisting [nl::runNetlister [db::getNext [nl::getNetlisters CDL]] \
                                                 -cellView $cellView \
                                                 -filePath $cdlFile \
                                                 -viewSearchList [dict get $dataDict searchList]]
            # Prepare the job arguments
            set runDesc "Generating netlist using netlister"
            set messageDisplay "GDS_REMERGE: Generating ${cellName}.cdl in [dict get $dataDict exportDir]."
            de::sendMessage $messageDisplay -severity information
            _write_file [dict get $dataDict logFile] [_add_timestamp "-I- $messageDisplay"] "a"
            set exitProc "::GDS_remerge::_generate_netlist_exit_proc"
            set jobName "${cellName}_Netlisting"
            set jobGroup [xt::getJobGroups [dict get $dataDict "jobGroup"]]
            # Create a job to append the include netlist file in the CDL
            if {!$doneNetlisting} {
                dict set dataDict "jobName" $jobName
                _generate_netlist_exit_proc "" $dataDict
            }
            set shellScript "#!/bin/bash"
            lappend shellScript "source /remote/cad-rep/etc/.bashrc"
            lappend shellScript "cd [dict get $dataDict exportDir];"
            if {[dict exists $dataDict includeNetlist]} {
                lappend shellScript "# Add the include netlist file at the top"
                lappend shellScript "echo \"*Source [dict get $dataDict includeNetlist]\" > ${cdlFile}_tmp;"
                lappend shellScript "cat [dict get $dataDict includeNetlist] >> ${cdlFile}_tmp;"
                lappend shellScript "cat $cdlFile >> ${cdlFile}_tmp;"
                lappend shellScript "mv -f ${cdlFile}_tmp $cdlFile;"
            }
            if {[dict exists $dataDict deleteSubckts]} {
                regexp {.*/(.*)$} $env(MSIP_SHELL_SCH_UTILS) "" sch_utils_version
                lappend shellScript "# Remove subckts"
                lappend shellScript "module unload msip_shell_sch_utils"
                lappend shellScript "module load msip_shell_sch_utils/$sch_utils_version"
                lappend shellScript "msip_schRemoveSubckts -inputNetlist $cdlFile -rmSubcktsList [dict get $dataDict deleteSubckts]  -rd [dict get $dataDict exportDir] > [dict get $dataDict exportDir]/${cellName}_msip_schRemoveSubckts.log 2> [dict get $dataDict exportDir]/${cellName}_msip_schRemoveSubckts.err"
            }
            set shellScriptFile "[dict get $dataDict exportDir]/${cellName}_netlist_manipulation.sh"
            _write_file $shellScriptFile [join $shellScript "\n"]
            set logFiles "[dict get $dataDict exportDir]/${cellName}_netlist_manipulation.log"
            set jobCmd "chmod 775 $shellScriptFile; $shellScriptFile 2>&1 $logFiles"
            # Create the Job
            xt::createJob $jobName \
                          -type "batch" \
                          -cmdLine $jobCmd \
                          -runDesc $runDesc \
                          -exitProc $exitProc \
                          -files $logFiles \
                          -group $jobGroup \
                          -data $dataDict
        }
    }
}

#-----------------------------------------------------------------
# Check that netlist was generated successfully and return to the scheduler
#-----------------------------------------------------------------
proc ::GDS_remerge::_generate_netlist_exit_proc {xtJobObj {dataDict ""}} {
    # Check the exit status for the job
    if {$xtJobObj != ""} {
        set jobStatus [db::getAttr status -of $xtJobObj]
        set dataDict [db::getAttr data -of $xtJobObj]
        if { [db::getAttr status -of $xtJobObj] == "FINISHED" && [file exists [dict get $dataDict cdlFile]]} {
            set messageDisplay "GDS_REMERGE: Finished generating the netlist [dict get $dataDict cdlFile] file sucessfully."
            de::sendMessage $messageDisplay -severity information
            _write_file [dict get $dataDict logFile] [_add_timestamp "-I- $messageDisplay"] "a"
            # Check that all of the netlisting operations are done
            set jobGroup [xt::getJobGroups [dict get $dataDict jobGroup]]
            set jobCol [db::getAttr jobs -of $jobGroup]
            set generatedCdlFiles ""
            while {[set job [db::getNext $jobCol]] != ""} {
                if {![regexp {Netlisting} [db::getAttr name -of $job]]} {continue}
                if {[regexp {FINISHED} [db::getAttr status -of $job]]} {
                    lappend generatedCdlFiles [dict get [db::getAttr data -of $xtJobObj] cdlFile]
                } else {
                    return
                }
            }
            # Check that all of the views have been exported
            if {[llength $generatedCdlFiles] == [llength [dict get $dataDict netlistSchematicViews]]} {
                # Add the list of exported GDS files to the data dict
                dict set dataDict cdlFilesList $generatedCdlFiles
                # Unset the info related to this run from the dict
                dict unset dataDict [dict keys $dataDict *File]
                dict unset dataDict [dict keys $dataDict *Name]
                _merge_cdl $dataDict
            }
        } else {
            set messageDisplay "GDS_REMERGE: ERROR [db::getAttr name -of $xtJobObj] failed."
            de::sendMessage $messageDisplay -severity error
            _write_file [dict get $dataDict logFile] [_add_timestamp "-E- $messageDisplay"] "a"
        }
    } else {
        set messageDisplay "GDS_REMERGE: ERROR [dict get $dataDict jobName] failed."
        de::sendMessage $messageDisplay -severity error
        _write_file [dict get $dataDict logFile] [_add_timestamp "-E- $messageDisplay"] "a"
    }
}

#-----------------------------------------------------------------
# Prefix the cdl, then swap it into the original CDL
#-----------------------------------------------------------------
proc ::GDS_remerge::_merge_cdl {dataDict} {
    global env
    set originalCdl [dict get $dataDict originalCdl]
    set prefix [dict get $dataDict topcellPrefix]
    set exportDir [dict get $dataDict exportDir]
    set mergedCdl "[dict get $dataDict runDir]/[dict get $dataDict topcell]_merged.cdl"
    dict set dataDict "mergedCdl" $mergedCdl
    set mergeCdlLines "#!/bin/bash"
    lappend mergeCdlLines "cd $exportDir"
    lappend mergeCdlLines "source /remote/cad-rep/etc/.bashrc"
    lappend mergeCdlLines "unset PYTHONPATH"
    lappend mergeCdlLines "unset PYTHONHOME"
    lappend mergeCdlLines "module unload msip_shell_sch_utils"
    lappend mergeCdlLines "module load msip_shell_sch_utils"
    # Prefix the cells
    set index 1
    set swapNetlistCmd ""
    if {$prefix == ""} {
        foreach cdlFile [dict get $dataDict cdlFilesList] {
            set cellName [file rootname [file tail $cdlFile]]
            append swapNetlistCmd " -swapNetlist$index $cdlFile -swapTop$index $cellName"
            incr index
        }
    } else {
        foreach cdlFile [dict get $dataDict cdlFilesList] {
            set cellName [file rootname [file tail $cdlFile]]
            set prefixedCdl "$exportDir/prefixed_$cellName.cdl"
            lappend mergeCdlLines "sed 's/\\b$cellName\\b/$prefix$cellName/' $cdlFile > $prefixedCdl"
            append swapNetlistCmd " -swapNetlist$index $prefixedCdl -swapTop$index $prefix$cellName"
            incr index
        }
    }
    lappend mergeCdlLines "msip_schSwapNetlist -mainNetlist $originalCdl $swapNetlistCmd -o $mergedCdl"
    set mergeFile "$exportDir/merge_cdl.sh"
    _write_file $mergeFile [join $mergeCdlLines "\n"]
    # Create a job to execute the shell script
    set jobName "Merging_CDL"
    set runDesc "Merging the CDL files"
    set messageDisplay "GDS_REMERGE: Merging the extracted netlist views into $originalCdl and writing the merged view to $mergedCdl"
    de::sendMessage $messageDisplay -severity information
    _write_file [dict get $dataDict logFile] [_add_timestamp "-I- $messageDisplay"] "a"
    set exitProc "::GDS_remerge::_merge_cdl_exit_proc"
    set logfile "$exportDir/schSwapNetlist.log"
    set jobGroup [xt::getJobGroups [dict get $dataDict jobGroup]]
    set jobCmd "chmod 775 $mergeFile; $mergeFile"
    xt::createJob $jobName \
                  -type "batch" \
                  -cmdLine $jobCmd \
                  -runDesc $runDesc \
                  -files $logfile \
                  -exitProc $exitProc \
                  -group $jobGroup \
                  -data $dataDict
}

#-----------------------------------------------------------------
# Check the exit status for merge_cdl job
#-----------------------------------------------------------------
proc ::GDS_remerge::_merge_cdl_exit_proc {xtJobObj} {
    # Check the exit status for the job
    set jobStatus [db::getAttr status -of $xtJobObj]
    set dataDict [db::getAttr data -of $xtJobObj]
    if { [db::getAttr status -of $xtJobObj] == "FINISHED" && [file exists [dict get $dataDict mergedCdl]]} {
        set messageDisplay "GDS_REMERGE: Finished merging the files. [dict get $dataDict mergedCdl] file was created successfully."
        de::sendMessage $messageDisplay -severity information
        _write_file [dict get $dataDict logFile] [_add_timestamp "-I- $messageDisplay"] "a"
        _call_pv_jobs $dataDict
    } else {
        set messageDisplay "GDS_REMERGE: ERROR [db::getAttr name -of $xtJobObj] failed check log: [db::getAttr files -of $xtJobObj]"
        de::sendMessage $messageDisplay -severity error
        _write_file [dict get $dataDict logFile] [_add_timestamp "-E- $messageDisplay"] "a"
    }
}

#-----------------------------------------------------------------
# Creates the files required for the PV runs and creates a job for each run
# in parallel.
#-----------------------------------------------------------------
proc ::GDS_remerge::_call_pv_jobs {dataDict} {
    set jobGroup [xt::getJobGroups [dict get $dataDict jobGroup]]
    # Check if the GDS and the CDL are ready
    set jobCol [db::getAttr jobs -of $jobGroup]
    set exportedGdsFiles ""
    while {[set job [db::getNext $jobCol]] != ""} {
        if {[regexp {Merging_GDS} [db::getAttr name -of $job]]} {
            if {[regexp {FINISHED} [db::getAttr status -of $job]]} {
                dict set dataDict mergedGds [dict get [db::getAttr data -of $job] mergedGds]
            } else {
                return
            }
        }
        if {[regexp {Merging_CDL} [db::getAttr name -of $job]]} {
            if {[regexp {FINISHED} [db::getAttr status -of $job]]} {
                dict set dataDict mergedCdl [dict get [db::getAttr data -of $job] mergedCdl]
            } else {
                return
            }
        }
    }
    if {![dict exists $dataDict mergedGds] || ![dict exists $dataDict mergedCdl]} {
        return
    }
    set messageDisplay "GDS_REMERGE: Starting PV runs on [dict get $dataDict topcell]!"
    de::sendMessage $messageDisplay -severity information
    _write_file [dict get $dataDict logFile] [_add_timestamp "-I- $messageDisplay"] "a"
    # Create a directory for the original and merged PV runs
    set pvDir [dict get $dataDict pvDir]
    set originalDir "$pvDir/original"
    file mkdir $originalDir
    set mergedDir "$pvDir/merged"
    file mkdir $mergedDir
    # Create the config files
    set commonConfigLines [list "set exportFormat GDS"]
    lappend commonConfigLines "set netlistBracketChange 0"
    lappend commonConfigLines "set deleteEmptyCell 0"
    lappend commonConfigLines "set cdlCheckboxWidget 0"
    lappend commonConfigLines "set saveReportandData 0"
    lappend commonConfigLines "set tapeoutCustomRel 0"
    lappend commonConfigLines "set useGrid 0"
    # Original GDS DRC config file
    set originalConfigLines $commonConfigLines
    set tool "icv"
    set verifs [list "DRC"]
    set verifsList "set verifList \"$tool $verifs\""
    lappend originalConfigLines $verifsList
    lappend originalConfigLines "set userGDS [dict get $dataDict originalGds]"
    lappend originalConfigLines "set rundir $originalDir"
    set originalConfigFile "$originalDir/pv_config"
    _write_file $originalConfigFile [join $originalConfigLines "\n"]
    # Merged GDS DRC config file
    set mergedConfigLines $commonConfigLines
    set verifs [list DRC LVS]
    set tool "icv"
    lappend tool $verifs
    set verifsList "set verifList \"$tool\""
    lappend mergedConfigLines $verifsList
    lappend mergedConfigLines "set userGDS [dict get $dataDict mergedGds]"
    lappend mergedConfigLines "set userNetlist [dict get $dataDict mergedCdl]"
    lappend mergedConfigLines "set rundir $mergedDir"
    set mergedConfigFile "$mergedDir/pv_config"
    _write_file $mergedConfigFile [join $mergedConfigLines "\n"]
    # Call the PV runs
    MSIP_PV::runBatchParallelMultipleVerification "type" \
                                                  "prefix" \
                                                  "GDS_Remerge" \
                                                  [dict get $dataDict topcell] \
                                                  [dict get $dataDict topView] \
                                                  "tool" \
                                                  $originalConfigFile
    MSIP_PV::runBatchParallelMultipleVerification "type" \
                                                  "prefix" \
                                                  "GDS_Remerge" \
                                                  [dict get $dataDict topcell] \
                                                  [dict get $dataDict topView] \
                                                  "tool" \
                                                  $mergedConfigFile
    set jobRegex ".*GDS_Remerge-[dict get $dataDict topcell]-[dict get $dataDict topView].*"
    set allJobs [xt::getJobs -filter {%group.name=~/$jobRegex/}]
    # Get the list of job groups
    while {[set xtJobObj [db::getNext $allJobs]] != ""} {
        set jobGroup [db::getAttr group -of $xtJobObj]
        if {[db::getAttr status -of $jobGroup] == "RUNNING"} {
            lappend pvGroups [db::getAttr name -of $jobGroup]
        }
    }
    set pvGroups [lsort -unique $pvGroups]
    dict set dataDict "pvGroups" $pvGroups
    dict set dataDict "originalDrc" "$originalDir/[dict get $dataDict topcell]/drc_icv_di"
    dict set dataDict "mergedDrc" "$mergedDir/[dict get $dataDict topcell]/drc_icv_di"
    dict set dataDict "mergedLvs" "$mergedDir/[dict get $dataDict topcell]/lvs_icv_di"
    foreach jobGroupName $pvGroups {
        set jobGroup [xt::getJobGroups $jobGroupName]
        db::setAttr exitProc -of $jobGroup -value [namespace code [list _pv_exit_proc $dataDict]]
    }
}

#-----------------------------------------------------------------
# Check that the PV run has finished successfully
#-----------------------------------------------------------------
proc ::GDS_remerge::_pv_exit_proc {dataDict xtJobObj} {
    set failed false
    set running false
    # Get the list of job groups
    foreach jobGroupName [dict get $dataDict pvGroups] {
        set jobGroup [xt::getJobGroups $jobGroupName]
        # Check if there is a job group that's still running
        if {[db::getAttr status -of $jobGroup] == "RUNNING"} {
            return
        }
        # Check if the jobs for the PV run, if it doesn't exists, then the job groups is not done yet
        set run false
        set jobCol [db::getAttr jobs -of $jobGroup]
        while {[set job [db::getNext $jobCol]] != ""} {
            if {![regexp {RUNNING|FINISHED} [db::getAttr status -of $job]]} {
                set failed true
            }
            if {[regexp "[dict get $dataDict topcell]" [db::getAttr name -of $job]]} {
                set run true
            }
        }
        if {!$run} {
            set running true
        }
    }
    if {$failed} {
        set messageDisplay "GDS_REMERGE: One of the PV jobs failed! Aborting."
        _write_file [dict get $dataDict logFile] [_add_timestamp "-E- $messageDisplay"] "a"
        error $messageDisplay
    }
    set messageDisplay "GDS_REMERGE: All PV runs have been successfully completeted for [dict get $dataDict topcell]."
    de::sendMessage $messageDisplay -severity information
    _write_file [dict get $dataDict logFile] [_add_timestamp "-I- $messageDisplay"] "a"
    set cmd "ln -s [dict get $dataDict originalDrc] [dict get $dataDict resultsDir]/original_drc_icv"
    _run_system_cmd $cmd
    set cmd "ln -s [dict get $dataDict mergedDrc] [dict get $dataDict resultsDir]/merged_drc_icv"
    _run_system_cmd $cmd
    set cmd "ln -s [dict get $dataDict mergedLvs] [dict get $dataDict resultsDir]/merged_lvs_icv"
    _run_system_cmd $cmd
    if {$running} {return}
    _process_results $dataDict
}

#-----------------------------------------------------------------
# Creates a summary file for the violations for each DRC run,
# and compares them.
#-----------------------------------------------------------------
proc ::GDS_remerge::_process_results {dataDict} {
    set pvDir [dict get $dataDict pvDir]
    set cellName [dict get $dataDict topcell]
    set originalResultsFile "$pvDir/original/$cellName/drc_icv_di/$cellName.RESULTS"
    set originalResultsSummary "$pvDir/original_drc_summary"
    set mergedResultsFile "$pvDir/merged/$cellName/drc_icv_di/$cellName.RESULTS"
    set mergedResultsSummary "$pvDir/merged_drc_summary"

    # Create a script to parse the results
    set shellLines "#!/bin/bash"
    lappend shellLines "sed -n 's/v =/,/p' $originalResultsFile > $originalResultsSummary"
    lappend shellLines "sed -n 's/v =/,/p' $mergedResultsFile > $mergedResultsSummary"
    # Create awk script to compare results
    set awkLines "#!/bin/awk -f"
    lappend awkLines ""
    lappend awkLines "BEGIN {FS=\"\\\\s*,\\\\s*\";OFS=\",\";findex=1;}"
    lappend awkLines ""
    lappend awkLines "findex == 1 {OF\[\$1\]=\$2;next}"
    lappend awkLines "!(\$1 in OF) {missing\[\$1\];next}"
    lappend awkLines "OF\[\$1\]!=\$2 {mismatch1\[\$1\]=OF\[\$1\];mismatch2\[\$1\]=\$2;delete OF\[\$1\];next}"
    lappend awkLines "OF\[\$1\]==\$2 {delete OF\[\$1\]}"
    lappend awkLines "ENDFILE \{findex++;\}"
    lappend awkLines ""
    lappend awkLines "END \{"
    lappend awkLines "\tif (length(OF) > 0){"
    lappend awkLines "\t\tprint \"Completely fixed errors:\""
    lappend awkLines "\t\tfor (key in OF){"
    lappend awkLines "\t\t\tprint \"\\t\"key"
    lappend awkLines "\t\t}"
    lappend awkLines "\t} else {"
    lappend awkLines "\t\tprint \"No errors were completely fixed!\""
    lappend awkLines "\t}"
    lappend awkLines "\tif (length(missing) > 0){"
    lappend awkLines "\t\tprint \"New errors:\""
    lappend awkLines "\t\tfor (key in missing){"
    lappend awkLines "\t\t\tprint \"\\t\"key"
    lappend awkLines "\t\t}"
    lappend awkLines "\t} else {"
    lappend awkLines "\t\tprint \"No new errors!\""
    lappend awkLines "\t}"
    lappend awkLines "\tif (length(mismatch1) > 0){"
    lappend awkLines "\t\tprint \"Error count changes:\""
    lappend awkLines "\t\tfor (key in mismatch1){"
    lappend awkLines "\t\t\tprint \"\\t\"key,\" Original(\"mismatch1\[key\]\"), Merged(\"mismatch2\[key\]\")\""
    lappend awkLines "\t\t}"
    lappend awkLines "\t} else {"
    lappend awkLines "\tprint \"No errors had a different count!\""
    lappend awkLines "\t}"
    lappend awkLines "\}"
    set awkFile "$pvDir/compare_drc_results.awk"
    _write_file $awkFile [join $awkLines "\n"]
    lappend shellLines "awk -f $awkFile $originalResultsSummary $mergedResultsSummary > $pvDir/drc_comparison_summary"
    set shellFile "$pvDir/compare_drc_results.sh"
    _write_file $shellFile [join $shellLines "\n"]
    # Prepare the job arguments
    set runDesc "Comparing the DRC results"
    set logFiles "$pvDir/drc_comparison_summary"
    set jobName "${cellName}_DRC_Compare"
    set exitProc "::GDS_remerge::_process_results_exit_proc"
    set jobGroup [xt::getJobGroups [dict get $dataDict jobGroup]]
    set messageDisplay "GDS_REMERGE: Starting DRC results comparison for [dict get $dataDict topcell]!"
    de::sendMessage $messageDisplay -severity information
    _write_file [dict get $dataDict logFile] [_add_timestamp "-I- $messageDisplay"] "a"
    # Prepare the jobCmd
    set jobCmd "chmod 775 $shellFile; $shellFile"
    xt::createJob $jobName \
                  -type "batch" \
                  -cmdLine $jobCmd \
                  -runDesc $runDesc \
                  -files $logFiles \
                  -exitProc $exitProc \
                  -group $jobGroup \
                  -data $dataDict
}

#-----------------------------------------------------------------
# Check that the results processing was completed and open the log file
#-----------------------------------------------------------------
proc ::GDS_remerge::_process_results_exit_proc {xtJobObj} {
    # Check the exit status for the job
    set jobStatus [db::getAttr status -of $xtJobObj]
    set dataDict [db::getAttr data -of $xtJobObj]
    set logfile [db::getAttr files -of $xtJobObj]
    if { [db::getAttr status -of $xtJobObj] == "FINISHED" && [file exists $logfile]} {
        set messageDisplay "GDS_REMERGE: Finished processing the results."
        de::sendMessage $messageDisplay -severity information
        _write_file [dict get $dataDict logFile] [_add_timestamp "-I- $messageDisplay"] "a"
        set messageDisplay "GDS_REMERGE: The results summary can be found at $logfile"
        de::sendMessage $messageDisplay -severity information
        _write_file [dict get $dataDict logFile] [_add_timestamp "-I- $messageDisplay"] "a"
        set cmd "ln -s $logfile [dict get $dataDict resultsDir]/drc_comparison_summary"
        _run_system_cmd $cmd
        xt::openTextViewer -files $logfile
        set messageDisplay "GDS_REMERGE: Finished the GDS Remerge on [dict get $dataDict topcell]!"
        de::sendMessage $messageDisplay -severity information
        _write_file [dict get $dataDict logFile] [_add_timestamp "-I- $messageDisplay"] "a"
    } else {
        set messageDisplay "GDS_REMERGE: ERROR [db::getAttr name -of $xtJobObj] failed!"
        de::sendMessage $messageDisplay -severity error
        _write_file [dict get $dataDict logFile] [_add_timestamp "-E- $messageDisplay"] "a"
    }
}

#-----------------------------------------------------------------
# This proc is automatically called by the de::createCommand, it parses the
# arguments and calls the main proc within a try block to ensure that
# the log file is written even if the tool fails.
#-----------------------------------------------------------------
proc ::GDS_remerge::execute {args} {
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
    # Call the actual Main proc
    try {
        global TIMESTAMP
        set TIMESTAMP true
        set exitval [_Main]
    } on error {results errorOptions} {
        set exitval [_fprint [dict get $errorOptions -errorinfo]]
    } finally {
        #set fileName "$verifPath/[namespace tail [namespace current]]_$cellName.log"
        #_write_stdout_log $fileName
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
de::createCommand GDS_remerge \
                  -category ddr_utils \
                  -arguments $args \
                  -description [join [list "Automates the GDS remerge flow. It takes a DI GDS and a list of macros. It" \
                                           "will generate the GDS for the macros list, and merge them into the DI GDS." \
                                           "It can also prefix the top level macros when merging them. It will run DRC" \
                                           "on both the original GDS and the merged GDS and compare the results. It can" \
                                           "also generate the CDL for the macros and merge them into the DI CDL."] \
                                      "\n\t"]

# nolint Main
# nolint Line 150: E Wrong number of arguments
# nolint Line 151: E Wrong number of arguments
# nolint Line 156: E Wrong number of arguments
# nolint Line 165: E Wrong number of arguments
# nolint Line 176: E Wrong number of arguments
