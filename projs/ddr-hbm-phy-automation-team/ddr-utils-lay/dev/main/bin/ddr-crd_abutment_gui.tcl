#!/depot/tk8.6.1/bin/wish
###############################################################################
# File       : ddr-crd_abutment_gui.tcl
# Author     : Ahmed Hesham(ahmedhes)
# Date       : 08/17/2022
# Description: The script will offer a GUI for the crd abutment parameters file.
#              The GUI can load and save the parameters file, and can call the
#              crd_abutment script when all of the parameters have been set.
# Usage      : Call the script to see the dialog
###############################################################################
set dir [file dirname [file normalize [info script]]]
lappend auto_path [file join $dir "../lib/tcl"]

package require DA_widgets
package require Misc
package require Messaging
namespace import ::Misc::*
namespace import ::Messaging::*
#namespace import ::DA_widgets::*

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
utils__script_usage_statistics $script_name "2022ww42"

array set parameters {}
array set paths {}
array set macros {}
array set covercells {}
array set manualKpt {}

array set testcases {}
array set utilityTestcases {}

set projectTypeList [lsort [list cad ddr43 lpddr4mv2 lpddr4xm lpddr5x lpddr54 lpddr5xm ddr54 ddr5]]
set projectNameList [list]
set releaseNameList [list]
set metalStackList  [list]
set parametersFile ""

proc main {} {
    tk_setPalette snow
    # Create the dialog with tabs
    ttk::notebook .nb -width 600 -height 550
    pack .nb -fill both -expand true
    set buttonsF [createTopBs .buttonsF]
    pack $buttonsF 
    createMainTab      .nb
    createMacrosTab    .nb
    createStdcellsTab  .nb
    createTestcasesTab .nb
    createPVTab        .nb
    
    wm title . "CRD Abutment Parameters"
}

proc createTopBs {framePath} {
    frame $framePath
    set saveFile [::DA_widgets::fileEntry $framePath.saveF \
                                          -variable parametersFile \
                                          -text "Output Parameters File:" \
                                          -mode save]
    grid $saveFile -column 0 -row 0 -columnspan 4
    button $framePath.load -text "Load" -width 12 -command "loadParameters"
    grid $framePath.load -column 0 -row 1
    button $framePath.save -text "Save" -width 12 -command "save $saveFile.selectB true"
    grid $framePath.save -column 1 -row 1
    button $framePath.run -text "Save and Run" -width 12 -command "run $saveFile.selectB"
    grid $framePath.run -column 2 -row 1
    button $framePath.close -text "Close" -width 12 -command "exit"
    grid $framePath.close -column 3 -row 1

    grid columnconfigure $framePath {0 1 2 3} -weight 1

    return $framePath
}

proc createMainTab {nb} {
    # Create the Main tab
    set mainTab [frame $nb.mainTab]
    $nb add $mainTab -text "Main"
    set mainF [::DA_widgets::scrollFrame $mainTab]

    set sections ""
    # Create a frame for UDE parameters
    lappend sections [createUdeFrame $mainF]
    # Create a frame for process parameters
    lappend sections [createProcessFrame $mainF]
    # Create a frame for abutment parameters
    lappend sections [createAbutmentFrame $mainF]
    # Create a frame for text parameters
    lappend sections [createTextFrame $mainF]

    pack {*}$sections -fill x -expand true
}

proc createUdeFrame {mainTab} {
    global parameters paths
    set udeF [frame $mainTab.ude \
                    -relief ridge \
                    -borderwidth 4 \
                    -padx 4 \
                    -pady 4]
    # Create project type text box
    label $udeF.projectTypeL -text "Project Type"
    grid $udeF.projectTypeL -column 0 -row 0
    set projectTypeSLB [frame $udeF.projectTypeSLB]
    DA_widgets::searchListbox $projectTypeSLB \
                              -valuesvariable projectTypeList \
                              -selectvariable parameters(project_type) \
                              -width 10 \
                              -height 10
    grid $projectTypeSLB -column 0 -row 1
    set paths(project_type) $projectTypeSLB
    trace add variable parameters(project_type) write "updateProjectNameList"
    # Create project name text box
    label $udeF.projectNameL -text "Project Name"
    grid $udeF.projectNameL -column 1 -row 0
    set projectNameSLB [frame $udeF.projectNameSLB]
    DA_widgets::searchListbox $projectNameSLB \
                              -valuesvariable projectNameList \
                              -selectvariable parameters(project_name) \
                              -width 20 \
                              -height 10
    grid $projectNameSLB -column 1 -row 1
    set paths(project_name) $projectNameSLB
    set parameters(project_name) ""
    trace add variable parameters(project_name) write "updateReleaseNameList"
    # Create release name text box
    label $udeF.releaseNameL -text "Release Name"
    grid $udeF.releaseNameL -column 2 -row 0
    set releaseNameSLB [frame $udeF.releaseNameSLB]
    DA_widgets::searchListbox $releaseNameSLB \
                              -valuesvariable releaseNameList \
                              -selectvariable parameters(release_name) \
                              -width 20 \
                              -height 10
    grid $releaseNameSLB -column 2 -row 1
    set paths(release_name) $releaseNameSLB
    set parameters(release_name) ""
    trace add variable parameters(release_name) write "updateMetalStackList"
    # Create metal stack text box
    label $udeF.metalStackL -text "Metal Stack"
    grid $udeF.metalStackL -column 0 -row 2 -columnspan 3
    set metalStackSLB [frame $udeF.metalStackSLB]
    DA_widgets::searchListbox $metalStackSLB \
                              -valuesvariable metalStackList \
                              -selectvariable parameters(metal_stack) \
                              -width 60 \
                              -height 10
    grid $metalStackSLB -column 0 -row 3 -columnspan 3
    set paths(metal_stack) $metalStackSLB
    set parameters(metal_stack) ""
    # Let the boxes fill the width of the frame
    grid columnconfigure $udeF {0 1} -weight 1
    return $udeF
}

proc updateProjectTypeList {{args ""}} {
    global parameters paths projectTypeList
    if {[lsearch -exact $projectTypeList $parameters(project_type)] == -1} {
        set parameters(project_type) ""
    }
    # Update the select variable to trigger the trace command to update the
    # selection
    set temp $projectTypeList
    set projectTypeList $parameters(project_type)
    set projectTypeList $temp
}

proc updateProjectNameList {{args ""}} {
    global parameters paths projectTypeList projectNameList
    if {[lsearch -exact $projectTypeList $parameters(project_type)] == -1} {
        set parameters(project_type) ""
    }
    if {$parameters(project_type) == ""} {
        set projectNameList [list]
    } else {
        # Get the project list using the project type
        set projectTypeDir "/remote/cad-rep/projects/$parameters(project_type)"
        if {![file isdirectory $projectTypeDir]} {
            error "The directory '$projectTypeDir' doesn't exist!"
        }
        set projectNameList [lsort [glob -tails -directory $projectTypeDir -types d *]]
    }
    updateReleaseNameList
}

proc updateReleaseNameList {{args ""}} {
    global parameters paths projectNameList releaseNameList
    if {$parameters(project_type) == "" || $parameters(project_name) == ""} {
        set releaseNameList [list]
    } else {
        # Get the release list using the project name
        set projectNameDir "/remote/cad-rep/projects/$parameters(project_type)/$parameters(project_name)"
        if {![file isdirectory $projectNameDir]} {
            error "The directory '$projectNameDir' doesn't exist!"
        }
        set releaseNameList [lsort [glob -tails -directory $projectNameDir -types d *]]
    }
    updateMetalStackList
}

proc updateMetalStackList {{args ""}} {
    global parameters paths projectNameList metalStackList
    if {$parameters(project_type) == "" || $parameters(project_name) == "" || $parameters(release_name) == ""} {
        set metalStackList [list]
    } else {
        # Get the release list using the project name
        set dir "/remote/cad-rep/projects/$parameters(project_type)/$parameters(project_name)/$parameters(release_name)/cad"
        if {![file isdirectory $dir]} {
            error "The directory '$dir' doesn't exist!"
        }
        set dirList [lsort [glob -tails -directory $dir -types d *]]
        set metalStackList [regexp -all -inline {\d+M_\S+} $dirList]
    }
}

proc createProcessFrame {mainTab} {
    global paths
    set processF [frame $mainTab.process -relief ridge \
                                                     -borderwidth 4 \
                                                     -padx 4 \
                                                     -pady 4]
    # Create boundary layer text box
    label $processF.boundaryLayerL -text "Boundary Layer: "
    grid $processF.boundaryLayerL -column 0 -row 0 -sticky e
    entry $processF.boundaryLayerE \
          -background white \
          -width 40 \
          -textvariable parameters(boundary_layer)
    grid $processF.boundaryLayerE -column 1 -row 0
    set paths(boundary_layer) $processF.boundaryLayerE
    # Create dbu text box
    label $processF.dbuL -text "DBU: "
    grid $processF.dbuL -column 0 -row 1 -sticky e
    entry $processF.dbuE \
          -background white \
          -width 40 \
          -textvariable parameters(dbu)
    grid $processF.dbuE -column 1 -row 1
    set paths(dbu) $processF.dbuE
    # Create tap distance text box
    label $processF.tapDistanceL -text "Tap Distance: "
    grid $processF.tapDistanceL -column 0 -row 2 -sticky e
    entry $processF.tapDistanceE \
          -background white \
          -width 40 \
          -textvariable parameters(tap_distance)
    grid $processF.tapDistanceE -column 1 -row 2
    set paths(tap_distance) $processF.tapDistanceE
    # Create icc2 gds layermap text box
    set icc2LayermapFE [::DA_widgets::fileEntry $processF.icc2LayermapFE \
                                          -variable "parameters(icc2_gds_layer_map)" \
                                          -text "ICC2 GDS Layermap:" \
                                          -width 37]
    grid $processF.icc2LayermapFE -column 0 -row 3 -columnspan 3
    set paths(icc2_gds_layer_map) $icc2LayermapFE.fileE
    # Create icc2 tech file text box
    set icc2TechFileFE [::DA_widgets::fileEntry $processF.icc2TechFileFE \
                                          -variable "parameters(icc2_techfile)" \
                                          -text "ICC2 Tech File: " \
                                          -width 41]
    grid $processF.icc2TechFileFE -column 0 -row 4 -columnspan 3
    set paths(icc2_techfile) $icc2TechFileFE.fileE
    # Let the boxes fill the width of the frame
    grid columnconfigure $processF {2} -weight 1
    return $processF
}

proc createAbutmentFrame {mainTab} {
    global paths
    set abutmentF [frame $mainTab.abutment -relief ridge \
                                           -borderwidth 4 \
                                           -padx 4 \
                                           -pady 4]
    set boundaryF [::DA_widgets::checkFrame $abutmentF \
                                            -variable parameters(generate_boundary) \
                                            -text "Generate Boundary"]
    set vcmd "isDouble"
    # Top
    label $boundaryF.boundaryTopL -text "Top"
    grid $boundaryF.boundaryTopL -column 4 -row 0 -columnspan 2
    entry $boundaryF.boundaryTopE \
          -textvariable parameters(generate_boundary_upsize_t) \
          -state disabled \
          -validate key \
          -validatecommand "$vcmd %P" \
          -invalidcommand bell \
          -width 7 \
          {*}$::DA_widgets::entrySettings
    grid $boundaryF.boundaryTopE -column 4 -row 1 -columnspan 2
    set paths(generate_boundary_upsize_t) $boundaryF.boundaryTopE
    # Bottom
    label $boundaryF.boundaryBottomL -text "Bottom"
    grid $boundaryF.boundaryBottomL -column 4 -row 4 -columnspan 2
    entry $boundaryF.boundaryBottomE \
          -textvariable parameters(generate_boundary_upsize_b) \
          -state disabled \
          -validate key \
          -validatecommand "$vcmd %P" \
          -invalidcommand bell \
          -width 7 \
          {*}$::DA_widgets::entrySettings
    grid $boundaryF.boundaryBottomE -column 4 -row 3 -columnspan 2
    set paths(generate_boundary_upsize_b) $boundaryF.boundaryBottomE
    # Left
    label $boundaryF.boundaryLeftL -text "Left"
    grid $boundaryF.boundaryLeftL -column 1 -row 2 -columnspan 2
    entry $boundaryF.boundaryLeftE \
          -textvariable parameters(generate_boundary_upsize_l) \
          -state disabled \
          -validate key \
          -validatecommand "$vcmd %P" \
          -invalidcommand bell \
          -width 7 \
          {*}$::DA_widgets::entrySettings
    grid $boundaryF.boundaryLeftE -column 3 -row 2 -columnspan 2
    set paths(generate_boundary_upsize_l) $boundaryF.boundaryLeftE
    # Right
    label $boundaryF.boundaryRightL -text "Right"
    grid $boundaryF.boundaryRightL -column 7 -row 2 -columnspan 2
    entry $boundaryF.boundaryRightE \
          -textvariable parameters(generate_boundary_upsize_r) \
          -state disabled \
          -validate key \
          -validatecommand "$vcmd %P" \
          -invalidcommand bell \
          -width 7 \
          {*}$::DA_widgets::entrySettings
    grid $boundaryF.boundaryRightE -column 5 -row 2 -columnspan 2
    set paths(generate_boundary_upsize_r) $boundaryF.boundaryRightE
    # Text
    label $boundaryF.text -text "Boundary upsize parameters (um)"
    grid $boundaryF.text -column 2 -row 5 -columnspan 6
    # Add filler columns
    grid columnconfigure $boundaryF {0 9} -weight 1
    return $abutmentF
}

proc createTextFrame {mainTab} {
    global paths
    set textF [frame $mainTab.text \
                     -relief ridge \
                     -borderwidth 4 \
                     -padx 4 \
                     -pady 4]
    # Create covercell text layer text box
    label $textF.covercellTextLayerL -text "Covercell Text Layer:"
    grid $textF.covercellTextLayerL -column 0 -row 0
    entry $textF.covercellTextLayerE \
          -background white \
          -textvariable parameters(covercell_text_layers)
    grid $textF.covercellTextLayerE -column 1 -row 0
    set paths(covercell_text_layers) $textF.covercellTextLayerE
    # Create macro text layer text box
    label $textF.macroTextLayerL -text "Macro Text Layer:"
    grid $textF.macroTextLayerL -column 0 -row 1
    entry $textF.macroTextLayerE \
          -background white \
          -textvariable parameters(macro_text_layers)
    grid $textF.macroTextLayerE -column 1 -row 1
    set paths(macro_text_layers) $textF.macroTextLayerE
    # Let the boxes fill the width of the frame
    grid columnconfigure $textF {2} -weight 1
    return $textF
}

proc createMacrosTab {nb} {
    set macrosTab [frame $nb.macrosTab]
    $nb add $macrosTab -text "Macros"
    set macrosF [::DA_widgets::scrollFrame $macrosTab]
    set sections ""
    # Macros section
    lappend sections [createMacrosFrame $macrosF]
    # Covercell Section
    lappend sections [createCovercellsFrame $macrosF]

    pack {*}$sections -fill x
}

proc createMacrosFrame {macrosOF} {
    global paths
    set macrosF [labelframe $macrosOF.macros -text "Macros"]
    set macrosConstructorProc "[namespace current]::macroConstructor"
    ::DA_widgets::itemsFrame $macrosF \
                             -command $macrosConstructorProc \
                             -variable macros \
                             -collapsible
    set paths(macros) $macrosF.addB
    return $macrosF
}

proc macroConstructor {path itemsArrayName index} {
    upvar #0 $itemsArrayName itemsArray

    # Create the frame
    set itemF [frame $path \
                     -relief ridge \
                     -borderwidth 2 \
                     -padx 4 \
                     -pady 4]
    # Add the remove button path to the array
    regsub {itemF} $path "removeB" removeBPath
    set itemsArray($index,remove,path) $removeBPath
    #Add the macro entry
    set macroEntryF [frame $path.macroEF]
    label $macroEntryF.macroL -text "Macro:"
    grid $macroEntryF.macroL -column 0 -row 0
    entry $macroEntryF.macroE \
          -textvariable "${itemsArrayName}($index,macro)" \
          {*}$::DA_widgets::entrySettings
    grid $macroEntryF.macroE -column 1 -row 0
    set itemsArray($index,collapseLabelVar) "${itemsArrayName}($index,macro)"
    pack $macroEntryF -fill x
    set itemsArray($index,macro,path) $macroEntryF.macroE
    # Add the CDL
    set cdlF [::DA_widgets::fileEntry $path.cdlF \
                                      -variable "${itemsArrayName}($index,cdl)" \
                                      -text "CDL" \
                                      -checkable \
                                      -checkVariable "${itemsArrayName}($index,cdl,toggle)"]
    $cdlF.checkB invoke
    $cdlF.checkB invoke
    pack $cdlF -fill x
    set itemsArray($index,cdl,path) $path.cdlF.innerF.fileE
    set itemsArray($index,cdl,path,toggle) $path.cdlF.checkB
    # Add the DEF
    set defF [::DA_widgets::fileEntry $path.defF \
                                      -variable "${itemsArrayName}($index,def)" \
                                      -text "DEF" \
                                      -checkable \
                                      -checkVariable "${itemsArrayName}($index,def,toggle)"]
    $defF.checkB invoke
    $defF.checkB invoke
    pack $defF -fill x
    set itemsArray($index,def,path) $path.defF.innerF.fileE
    set itemsArray($index,def,path,toggle) $path.defF.checkB
    # Add the GDS
    set gdsF [::DA_widgets::fileEntry $path.gdsF \
                                      -variable "${itemsArrayName}($index,gds)" \
                                      -text "GDS" \
                                      -checkable \
                                      -checkVariable "${itemsArrayName}($index,gds,toggle)"]
    $gdsF.checkB invoke
    $gdsF.checkB invoke
    pack $gdsF -fill x
    set itemsArray($index,gds,path) $path.gdsF.innerF.fileE
    set itemsArray($index,gds,path,toggle) $path.gdsF.checkB
    # Add the LEF
    set lefF [::DA_widgets::fileEntry $path.lefF \
                                      -variable "${itemsArrayName}($index,lef)" \
                                      -text "LEF" \
                                      -checkable \
                                      -checkVariable "${itemsArrayName}($index,lef,toggle)"]
    $lefF.checkB invoke
    $lefF.checkB invoke
    pack $lefF -fill x
    set itemsArray($index,lef,path) $path.lefF.innerF.fileE
    set itemsArray($index,lef,path,toggle) $path.lefF.checkB
    return $itemF
}

proc createCovercellsFrame {covercellsOF} {
    global paths
    set covercellsF [labelframe $covercellsOF.covercells -text "Covercells"]
    set covercellsConstructorProc "[namespace current]::covercellConstructor"
    ::DA_widgets::itemsFrame $covercellsF \
                             -command $covercellsConstructorProc \
                             -variable covercells \
                             -collapsible
    set paths(covercells) $covercellsF.addB
    return $covercellsF
}

proc covercellConstructor {path itemsArrayName index} {
    upvar #0 $itemsArrayName itemsArray

    # Create the frame
    set itemF [frame $path]
    # Add the remove button path to the array
    regsub {itemF} $path "removeB" removeBPath
    set itemsArray($index,remove,path) $removeBPath
    # Add the macro entry
    set macroEntryF [frame $path.macroEF]
    label $macroEntryF.macroL -text "Macro:"
    grid $macroEntryF.macroL -column 0 -row 0
    entry $macroEntryF.macroE \
          -textvariable "${itemsArrayName}($index,macro)" \
          {*}$::DA_widgets::entrySettings
    grid $macroEntryF.macroE -column 1 -row 0
    set itemsArray($index,collapseLabelVar) "${itemsArrayName}($index,macro)"
    set itemsArray($index,macro,path) $path.macroE
    pack $macroEntryF -fill x
    # Add the GDS
    set gdsF [::DA_widgets::fileEntry $path.gdsF \
                                      -variable "${itemsArrayName}($index,gds)" \
                                      -text "GDS"]
    pack $gdsF -fill x
    set itemsArray($index,gds,path) $path.gdsF.innerF.fileE
    return $itemF
}

proc createStdcellsTab {nb} {
    set stdcellsTab [frame $nb.stdcellsTab]
    $nb add $stdcellsTab -text "Stdcells"
    set stdcellsF [::DA_widgets::scrollFrame $stdcellsTab]
    set sections ""
    # Boundary Section
    lappend sections [createBoundaryFrame $stdcellsF]
    # Parameters Section
    lappend sections [createStdcellsParametersFrame $stdcellsF]
    # Kpt Section
    lappend sections [createKptFrame $stdcellsF]
    # Tap Section
    lappend sections [createTapFrame $stdcellsF]

    pack {*}$sections -fill x
}

proc createBoundaryFrame {stdcellsF} {
    set boundaryF [labelframe $stdcellsF.boundaryF -text "Boundary"]
    # Boundary Bottom
    label $boundaryF.bL -text "Bottom"
    grid $boundaryF.bL -column 1 -row 0 -sticky e
    entry $boundaryF.bE \
          -textvariable parameters(boundary_bottom) \
          -width 23 \
          {*}$::DA_widgets::entrySettings
    grid $boundaryF.bE -column 2 -row 0
    # Boundary Bottom Left Inside Corner
    label $boundaryF.blicL -text "Bottom left inside corner"
    grid $boundaryF.blicL -column 1 -row 1 -sticky e
    entry $boundaryF.blicE \
          -textvariable parameters(boundary_bottom_left_inside_corner) \
          -width 23 \
          {*}$::DA_widgets::entrySettings
    grid $boundaryF.blicE -column 2 -row 1
    # Boundary Bottom Left Inside Horizontal Abutment
    label $boundaryF.blihaL -text "Bottom left inside horizontal abutment"
    grid $boundaryF.blihaL -column 1 -row 2 -sticky e
    entry $boundaryF.blihaE \
          -textvariable parameters(boundary_bottom_left_inside_horizontal_abutment) \
          -width 23 \
          {*}$::DA_widgets::entrySettings
    grid $boundaryF.blihaE -column 2 -row 2
    # Boundary Bottom Left Outside Corner
    label $boundaryF.blocL -text "Bottom left outside corner"
    grid $boundaryF.blocL -column 1 -row 3 -sticky e
    entry $boundaryF.blocE \
          -textvariable parameters(boundary_bottom_left_outside_corner) \
          -width 23 \
          {*}$::DA_widgets::entrySettings
    grid $boundaryF.blocE -column 2 -row 3
    # Boundary Bottom Right Inside Corner
    label $boundaryF.bricL -text "Bottom right inside corner"
    grid $boundaryF.bricL -column 1 -row 4 -sticky e
    entry $boundaryF.bricE \
          -textvariable parameters(boundary_bottom_right_inside_corner) \
          -width 23 \
          {*}$::DA_widgets::entrySettings
    grid $boundaryF.bricE -column 2 -row 4
    # Boundary Bottom Right Inside Horizontal Abutment
    label $boundaryF.brihaL -text "Bottom right inside horizontal abutment"
    grid $boundaryF.brihaL -column 1 -row 5 -sticky e
    entry $boundaryF.brihaE \
          -textvariable parameters(boundary_bottom_right_inside_horizontal_abutment) \
          -width 23 \
          {*}$::DA_widgets::entrySettings
    grid $boundaryF.brihaE -column 2 -row 5
    # Boundary Bottom Right Outside Corner
    label $boundaryF.brocL -text "Bottom right outside corner"
    grid $boundaryF.brocL -column 1 -row 6 -sticky e
    entry $boundaryF.brocE \
          -textvariable parameters(boundary_bottom_right_outside_corner) \
          -width 23 \
          {*}$::DA_widgets::entrySettings
    grid $boundaryF.brocE -column 2 -row 6
    # Boundary Left
    label $boundaryF.lL -text "Left"
    grid $boundaryF.lL -column 1 -row 7 -sticky e
    entry $boundaryF.lE \
          -textvariable parameters(boundary_left) \
          -width 23 \
          {*}$::DA_widgets::entrySettings
    grid $boundaryF.lE -column 2 -row 7
    # Boundary Right
    label $boundaryF.rL -text "Right"
    grid $boundaryF.rL -column 1 -row 8 -sticky e
    entry $boundaryF.rE \
          -textvariable parameters(boundary_right) \
          -width 23 \
          {*}$::DA_widgets::entrySettings
    grid $boundaryF.rE -column 2 -row 8
    # Boundary Top
    label $boundaryF.tL -text "Top"
    grid $boundaryF.tL -column 1 -row 9 -sticky e
    entry $boundaryF.tE \
          -textvariable parameters(boundary_top) \
          -width 23 \
          {*}$::DA_widgets::entrySettings
    grid $boundaryF.tE -column 2 -row 9
    # Boundary Top Left Inside Corner
    label $boundaryF.tlicL -text "Top left inside corner"
    grid $boundaryF.tlicL -column 1 -row 10 -sticky e
    entry $boundaryF.tlicE \
          -textvariable parameters(boundary_top_left_inside_corner) \
          -width 23 \
          {*}$::DA_widgets::entrySettings
    grid $boundaryF.tlicE -column 2 -row 10
    # Boundary Top Left Outside Corner
    label $boundaryF.tlocL -text "Top left outside corner"
    grid $boundaryF.tlocL -column 1 -row 11 -sticky e
    entry $boundaryF.tlocE \
          -textvariable parameters(boundary_top_left_outside_corner) \
          -width 23 \
          {*}$::DA_widgets::entrySettings
    grid $boundaryF.tlocE -column 2 -row 11
    # Boundary Top Right Inside Corner
    label $boundaryF.tricL -text "Top right inside corner"
    grid $boundaryF.tricL -column 1 -row 12 -sticky e
    entry $boundaryF.tricE \
          -textvariable parameters(boundary_top_right_inside_corner) \
          -width 23 \
          {*}$::DA_widgets::entrySettings
    grid $boundaryF.tricE -column 2 -row 12
    # Boundary Top Right Outside Corner
    label $boundaryF.trocL -text "Top right outside corner"
    grid $boundaryF.trocL -column 1 -row 13 -sticky e
    entry $boundaryF.trocE \
          -textvariable parameters(boundary_top_right_outside_corner) \
          -width 23 \
          {*}$::DA_widgets::entrySettings
    grid $boundaryF.trocE -column 2 -row 13

    return $boundaryF
}

proc createStdcellsParametersFrame {stdcellsF} {
    global paths
    set paraF [labelframe $stdcellsF.paraF -text "Parameters"]
    # Stdcell drive strength
    label $paraF.dsL -text "Drive strength:"
    grid $paraF.dsL -column 1 -row 0 -sticky e
    entry $paraF.dsE \
          -textvariable parameters(stdcell_drive_strength) \
          -width 42 \
          {*}$::DA_widgets::entrySettings
    grid $paraF.dsE -column 2 -row 0
    set paths(stdcell_drive_strength) $paraF.dsE
    # Stdcell GDS
    set gdsF [::DA_widgets::fileEntry $paraF.gdsF \
                                      -variable "parameters(stdcell_gds)" \
                                      -text "Stdcell GDS:" \
                                      -width 35]
    grid $paraF.gdsF -column 1 -row 1 -columnspan 2
    set paths(stdcell_gds) $paraF.gdsF.innerF.fileE
    # Stdcell NDM
    set ndmF [::DA_widgets::directoryEntry $paraF.ndmF \
                                      -variable "parameters(stdcell_ndm)" \
                                      -text "Stdcell NDM:" \
                                      -width 35]
    grid $paraF.ndmF -column 1 -row 2 -columnspan 2
    set paths(stdcell_ndm) $paraF.ndmF.innerF.fileE
    return $paraF
}

proc createKptFrame {stdcellsF} {
    global paths
    set kptF [labelframe $stdcellsF.kptF -text "kpt"]
    # kpt Bottom
    label $kptF.bL -text "kpt bottom:"
    grid $kptF.bL -column 1 -row 0 -sticky e
    entry $kptF.bE \
          -textvariable parameters(stdcell_kpt_b) \
          -width 30 \
          {*}$::DA_widgets::entrySettings
    grid $kptF.bE -column 2 -row 0
    set paths(stdcell_kpt_b) $kptF.bE
    # kpt left
    label $kptF.lL -text "kpt left:"
    grid $kptF.lL -column 1 -row 1 -sticky e
    entry $kptF.lE \
          -textvariable parameters(stdcell_kpt_l) \
          -width 30 \
          {*}$::DA_widgets::entrySettings
    grid $kptF.lE -column 2 -row 1
    set paths(stdcell_kpt_l) $kptF.lE
    # kpt right
    label $kptF.rL -text "kpt right:"
    grid $kptF.rL -column 1 -row 2 -sticky e
    entry $kptF.rE \
          -textvariable parameters(stdcell_kpt_r) \
          -width 30 \
          {*}$::DA_widgets::entrySettings
    grid $kptF.rE -column 2 -row 2
    set paths(stdcell_kpt_r) $kptF.rE
    # kpt top
    label $kptF.tL -text "kpt top:"
    grid $kptF.tL -column 1 -row 3 -sticky e
    entry $kptF.tE \
          -textvariable parameters(stdcell_kpt_t) \
          -width 30 \
          {*}$::DA_widgets::entrySettings
    grid $kptF.tE -column 2 -row 3
    set paths(stdcell_kpt_t) $kptF.tE
    # inner kpt bottom
    label $kptF.ibL -text "inner kpt bottom:"
    grid $kptF.ibL -column 1 -row 4 -sticky e
    entry $kptF.ibE \
          -textvariable parameters(stdcell_inner_kpt_b) \
          -width 30 \
          {*}$::DA_widgets::entrySettings
    grid $kptF.ibE -column 2 -row 4
    set paths(stdcell_inner_kpt_b) $kptF.ibE
    # inner kpt left
    label $kptF.ilL -text "inner kpt left:"
    grid $kptF.ilL -column 1 -row 5 -sticky e
    entry $kptF.ilE \
          -textvariable parameters(stdcell_inner_kpt_l) \
          -width 30 \
          {*}$::DA_widgets::entrySettings
    grid $kptF.ilE -column 2 -row 5
    set paths(stdcell_inner_kpt_l) $kptF.ilE
    # inner kpt right
    label $kptF.irL -text "inner kpt right:"
    grid $kptF.irL -column 1 -row 6 -sticky e
    entry $kptF.irE \
          -textvariable parameters(stdcell_inner_kpt_r) \
          -width 30 \
          {*}$::DA_widgets::entrySettings
    grid $kptF.irE -column 2 -row 6
    set paths(stdcell_inner_kpt_r) $kptF.irE
    # inner kpt top
    label $kptF.itL -text "inner kpt top:"
    grid $kptF.itL -column 1 -row 7 -sticky e
    entry $kptF.itE \
          -textvariable parameters(stdcell_inner_kpt_t) \
          -width 30 \
          {*}$::DA_widgets::entrySettings
    grid $kptF.itE -column 2 -row 7
    set paths(stdcell_inner_kpt_t) $kptF.itE
    # Manual kpt
    set manualKptF [labelframe $kptF.manualKpt -text "Manual Kpt"]
    set manualKptConstructorProc "[namespace current]::manualKptConstructor"
    ::DA_widgets::itemsFrame $manualKptF \
                             -command $manualKptConstructorProc \
                             -variable manualKpt \
                             -collapsible
    grid $kptF.manualKpt -column 1 -row 8 -columnspan 2
    set paths(manualKpt) $manualKptF.addB

    grid columnconfigure $kptF {0 3} -weight 1
    return $kptF
}

proc manualKptConstructor {path itemsArrayName index} {
    upvar #0 $itemsArrayName itemsArray

    # Create the frame
    set itemF [frame $path]
    # Add the remove button path to the array
    regsub {itemF} $path "removeB" removeBPath
    set itemsArray($index,remove,path) $removeBPath
    # Add the macro entry
    set macroEntryF [frame $path.macroEF]
    label $macroEntryF.macroL -text "Macro/Testcase:"
    grid $macroEntryF.macroL -column 0 -row 0
    entry $macroEntryF.macroE \
          -textvariable "${itemsArrayName}($index,macro)" \
          {*}$::DA_widgets::entrySettings
    grid $macroEntryF.macroE -column 1 -row 0
    set itemsArray($index,collapseLabelVar) "${itemsArrayName}($index,macro)"
    set itemsArray($index,macro,path) $path.macroE
    pack $macroEntryF -fill x
    # Add the GDS
    set gdsF [::DA_widgets::fileEntry $path.gdsF \
                                      -variable "${itemsArrayName}($index,gds)" \
                                      -text "GDS"]
    pack $gdsF -fill x
    set itemsArray($index,gds,path) $path.gdsF.innerF.fileE
    return $itemF
}

proc createTapFrame {stdcellsF} {
    global path
    set tapF [labelframe $stdcellsF.tapF -text "Tap"]
    # tap Bottom
    label $tapF.tL -text "Tap"
    grid $tapF.tL -column 1 -row 0 -sticky e
    entry $tapF.tE \
          -textvariable parameters(stdcell_tap) \
          -width 30 \
          {*}$::DA_widgets::entrySettings
    grid $tapF.tE -column 2 -row 0 -sticky e
    set path(stdcell_tap) $tapF.tE
    # The list of n entries name and description
    set nList [list [list stdcell_tap_boundary_wall_cell_n_fill_wall "n fill wall:"]]
    lappend nList [list stdcell_tap_boundary_wall_cell_n_fill_wall_replacement "n fill wall replacement:"]
    lappend nList [list stdcell_tap_boundary_wall_cell_n_inner_corner_boundary "n inner corner boundary:"]
    lappend nList [list stdcell_tap_boundary_wall_cell_n_left_tap "n left tap:"]
    lappend nList [list stdcell_tap_boundary_wall_cell_n_right_tap "n right tap:"]
    lappend nList [list stdcell_tap_boundary_wall_cell_n_ntap_inner_corner_boundary "n ntap inner corner boundary:"]
    lappend nList [list stdcell_tap_boundary_wall_cell_n_ptap_inner_corner_boundary "n ptap inner corner boundary:"]
    lappend nList [list stdcell_tap_boundary_wall_cell_n_tap "n tap:"]
    lappend nList [list stdcell_tap_boundary_wall_cell_n_tap_wall "n tap wall:"]
    lappend nList [list stdcell_tap_boundary_wall_cell_n_tb_boundary "n tb boundary:"]
    lappend nList [list stdcell_tap_boundary_wall_cell_n_tb_corner_boundary "n tb corner boundary:"]
    lappend nList [list stdcell_tap_boundary_wall_cell_n_tb_corner_tap "n tb corner tap:"]
    lappend nList [list stdcell_tap_boundary_wall_cell_n_tb_tap "n tb tap:"]
    lappend nList [list stdcell_tap_boundary_wall_cell_n_tb_tap_wall "n tb tap wall:"]
    lappend nList [list stdcell_tap_boundary_wall_cell_n_tb_wall "n tb wall:"]
    set nF [labelframe $tapF.nF -text "Tap boundary wall cell n"]
    set row 0
    foreach item $nList {
        lassign $item var descript
        regsub {_} $var "/" name
        label $nF.${name}L -text $descript
        grid $nF.${name}L -column 1 -row $row -sticky e
        entry $nF.${name}E \
              -textvariable parameters($var) \
              -width 30 \
              {*}$::DA_widgets::entrySettings
        grid $nF.${name}E -column 2 -row $row
        set path($var) $nF.{$name}E
        incr row
    }
    set pF [labelframe $tapF.pF -text "Tap boundary wall cell p"]
    set row 0
    foreach item $nList {
        lassign $item var descript
        regsub {_n_} $var "_p_" var
        regsub {^n } $descript "p " descript
        regsub {_} $var "/" name
        label $pF.${name}L -text $descript
        grid $pF.${name}L -column 1 -row $row -sticky e
        entry $pF.${name}E \
              -textvariable parameters($var) \
              -width 30 \
              {*}$::DA_widgets::entrySettings
        grid $pF.${name}E -column 2 -row $row
        set path($var) $pF.{$name}E
        incr row
    }
    grid $nF -column 1 -row 1 -columnspan 2
    grid $pF -column 1 -row 2 -columnspan 2
    return $tapF
}

proc createTestcasesTab {nb} {
    global testcases macros
    readFloorplans
    set testcasesTab [frame $nb.testcasesTab]
    $nb add $testcasesTab -text "Testcases"
    # Update the testcases list whenever the testcases tab is selected
    bind $nb <<NotebookTabChanged>> {checkSelectedTab %W}
    set testcasesF [::DA_widgets::scrollFrame $testcasesTab]
    set sections ""
    # Common Section
    lappend sections [createTestcasesControlFrame $testcasesF]
    # Abutment Testcases Section
    lappend sections [createAbutmentTestcasesFrame $testcasesF]
    # Abutment Stdcell Testcases Section
    lappend sections [createAbutmentStdcellTestcasesFrame $testcasesF]
    # Abutment Wrapper Testcases Section
    lappend sections [createAbutmentWrapperTestcasesFrame $testcasesF]
    # Wrapper Testcases Section
    lappend sections [createWrapperTestcasesFrame $testcasesF]
    # Stdcell Testcases Section
    lappend sections [createStdcellTestcasesFrame $testcasesF]
    # PV Only Testcases Section
    lappend sections [createPvTestcasesFrame $testcasesF]
    # Stdcell Fill Testcases Section
    lappend sections [createStdcellFillTestcasesFrame $testcasesF]
    # Utility Testcases Section
    lappend sections [createUtilityTestcasesFrame $testcasesF]

    pack {*}$sections -fill x
}

proc checkSelectedTab {nb} {
    # Update the testcases list whenever the testcases tab is selected
    if {[regexp -nocase {testcases} [$nb select]]} {
        updateTestcasesListboxes
    }
}

proc readFloorplans {} {
    global dir testcases
    # Read the list of testcases from the floorplans file
    set floorplansFile "$dir/../cfg/crd_abutment_floorplans.cfg"
    set lines [split [read_file $floorplansFile] "\n"]
    set cfgTestcasesList [list]
    foreach line $lines {
        if {[regexp {^set floorplans\((.*)\)} $line - testcase]} {
            lappend cfgTestcasesList $testcase
        }
    }
    set cfgTestcasesList [lsort -nocase $cfgTestcasesList]
    
    set testcases(testcases_abutment)         $cfgTestcasesList
    set testcases(testcases_abutment_stdcell) $cfgTestcasesList
    set testcases(testcases_abutment_wrapper) [list]
    set testcases(testcases_pv_only)          [list]
    set testcases(testcases_stdcell)          [list]
    set testcases(testcases_stdcell_fill)     [list]
    set testcases(testcases_utility_1)        [list]
    set testcases(testcases_wrapper)          [list]
}

proc updateTestcasesListboxes {{args ""}} {
    global macros testcases macrosGDS macrosDEF
    # Get the list of valid indices
    set validIndices [list]
    foreach item [array names macros "*,valid"] {
        if {$macros($item)} {
            lappend validIndices [regexp -inline {^\d+} $item]
        }
    }
    # Get the lists of macros with GDS/DEF
    set macrosGds [list]
    set macrosDef [list]
    foreach index $validIndices {
        if {[regexp {^\s*$} $macros($index,macro)]} {
            continue
        }
        if {$macros($index,gds,toggle) == 1} {
            lappend macrosGds $macros($index,macro)
        }
        if {$macros($index,def,toggle) == 1} {
            lappend macrosDef $macros($index,macro)
        }
    }
    set macrosGds [lsort -unique $macrosGds]
    set macrosDef [lsort -unique $macrosDef]
    set wrapperList [regexp -all -inline -nocase {\S*wrapper\S*} $macrosGds]
    # Update the abutment_wrapper and wrapper testcases with macrosGds
    updateTestcaseList testcases_abutment_wrapper $wrapperList
    updateTestcaseList testcases_wrapper $wrapperList
    # Update the stdcell and PV only testcases with macrosGds
    updateTestcaseList testcases_stdcell $macrosGds
    updateTestcaseList testcases_pv_only $macrosGds
    # Update the stdcell_fill testcases with macrosGds
    updateTestcaseList testcases_stdcell_fill $macrosDef
}

proc updateTestcaseList {type newList} {
    global testcases paths
    # Get the selected items
    set selectedTestcases [getTestcaseListSelection $type]
    # Clear the selection
    $paths($type) selection clear 0 end
    # Update the list
    set testcases($type) $newList
    # Re-select the valid entries
    foreach item $selectedTestcases {
        set index [lsearch $newList $item]
        if {$index != -1} {
            $paths($type) selection set $index
        }
    }
}

proc createTestcasesControlFrame {tcF} {
    global paths parameters
    set controlF [labelframe $tcF.control -text "Testcases Control Parameters"]
    # Generate CDL
    checkbutton $controlF.generateCdl \
                -text "Generate CDL" \
                -variable parameters(generate_cdl) \
                -borderwidth 0 \
                -relief flat \
                -highlightthickness 0
    grid $controlF.generateCdl -column 1 -row 0 -columnspan 2 -sticky w
    # Generate LEF
    checkbutton $controlF.generateLef \
                -text "Generate LEF" \
                -variable parameters(generate_lef) \
                -borderwidth 0 \
                -relief flat \
                -highlightthickness 0
    grid $controlF.generateLef -column 1 -row 1 -columnspan 2 -sticky w
    # Test covercells
    checkbutton $controlF.testCovercells \
                -text "Test Covercells" \
                -variable parameters(test_covercells) \
                -borderwidth 0 \
                -relief flat \
                -highlightthickness 0
    grid $controlF.testCovercells -column 1 -row 2 -columnspan 2 -sticky w
    # Test macros
    checkbutton $controlF.testMacros \
                -text "Test Macros" \
                -variable parameters(test_macros) \
                -borderwidth 0 \
                -relief flat \
                -highlightthickness 0
    grid $controlF.testMacros -column 1 -row 3 -columnspan 2 -sticky w
    # Output Format
    set outputFormatF [frame $controlF.outputForamt \
                                 -borderwidth 0 \
                                 -padx 4 \
                                 -pady 4]
    grid $outputFormatF -column 1 -row 4 -columnspan 2 -sticky w
    label $outputFormatF.label -text "Output Format"
    grid $outputFormatF.label -column 0 -row 0
    radiobutton $outputFormatF.gds \
                -text "GDS" \
                -variable parameters(output_layout_format) \
                -value GDS
    grid $outputFormatF.gds -column 1 -row 0
    radiobutton $outputFormatF.oasis \
                -text "OASIS" \
                -variable parameters(output_layout_format) \
                -value OASIS
    grid $outputFormatF.oasis -column 2 -row 0
    set paths(output_layout_format) $outputFormatF
    # Set GDS as the default option
    $outputFormatF.gds invoke
    # Uniquify input CDL
    set uniquifyInputCdlF \
          [::DA_widgets::fileEntry $controlF.uniquifyFilterFile \
                                   -text "Uniquify Input CDL" \
                                   -variable "parameters(uniquify_input_cdl_filter_file)" \
                                   -checkable \
                                   -checkVariable "parameters(uniquify_input_cdl)" \
                                   -width 25]
    grid $uniquifyInputCdlF -column 1 -row 5 -columnspan 2 -sticky w
    set paths(uniquify_input_cdl_filter_file) $uniquifyInputCdlF.fileE
    $uniquifyInputCdlF.checkB invoke
    $uniquifyInputCdlF.checkB invoke
    # Uniquify input GDS
    checkbutton $controlF.uniquifyInputGds \
                -text "Uniquify Input GDS" \
                -variable parameters(uniquify_input_gds) \
                -borderwidth 0 \
                -relief flat \
                -highlightthickness 0
    grid $controlF.uniquifyInputGds -column 1 -row 6 -columnspan 2 -sticky w
    # Uniquify signal pins
    checkbutton $controlF.uniquifySignalPins \
                -text "Uniquify Signal Pins" \
                -variable parameters(uniquify_signal_pins) \
                -borderwidth 0 \
                -relief flat \
                -highlightthickness 0
    grid $controlF.uniquifySignalPins -column 1 -row 7 -columnspan 2 -sticky w
    # Cell Substitution
    label $controlF.cellSubL -text "Cell Substitution:"
    grid $controlF.cellSubL -column 1 -row 8 -sticky e
    entry $controlF.cellSubE \
          -textvariable parameters(cell_substitution) \
          -width 30 \
          {*}$::DA_widgets::entrySettings
    grid $controlF.cellSubE -column 2 -row 8
    set paths(cell_substitution) $controlF.cellSubE
    # Tcoil Unit Width
    label $controlF.tcoilWidthL -text "tcoil unit width:"
    grid $controlF.tcoilWidthL -column 1 -row 9 -sticky e
    entry $controlF.tcoilWidthE \
          -textvariable parameters(tcoil_unit_width) \
          -width 30 \
          {*}$::DA_widgets::entrySettings
    grid $controlF.tcoilWidthE -column 2 -row 9
    set paths(tcoil_unit_width) $controlF.tcoilWidthE
    # Adjust filler columns
    grid columnconfigure $controlF {3} -weight 1

    # Default Values
    set parameters(tcoil_unit_width) 5
    return $controlF
}

proc createAbutmentTestcasesFrame {tcF} {
    global paths
    set abutF [labelframe $tcF.abutTestF -text "Abutment Testcases"]
    ::DA_widgets::multiSelectList $abutF \
                                  -variable testcases(testcases_abutment) \
                                  -width 50 \
                                  -height 20 
    set paths(testcases_abutment) $abutF.listF.listLB
    return $abutF        
}

proc createAbutmentStdcellTestcasesFrame {tcF} {
    global paths
    set asF [labelframe $tcF.abutStdTestF -text "Abutment Stdcell Testcases"]
    ::DA_widgets::multiSelectList $asF \
                                  -variable testcases(testcases_abutment_stdcell) \
                                  -width 50 \
                                  -height 20 
    set paths(testcases_abutment_stdcell) $asF.listF.listLB
    return $asF        
}

proc createAbutmentWrapperTestcasesFrame {tcF} {
    global paths
    set awF [labelframe $tcF.abutWrapTestF -text "Abutment Wrapper Testcases"]
    ::DA_widgets::multiSelectList $awF \
                                  -variable testcases(testcases_abutment_wrapper) \
                                  -width 50 \
                                  -height 20 
    set paths(testcases_abutment_wrapper) $awF.listF.listLB
    return $awF        
}

proc createPvTestcasesFrame {tcF} {
    global paths
    set pvF [labelframe $tcF.pvTestF -text "PV Only Testcases"]
    ::DA_widgets::multiSelectList $pvF \
                                  -variable testcases(testcases_pv_only) \
                                  -width 50 \
                                  -height 20 
    set paths(testcases_pv_only) $pvF.listF.listLB
    return $pvF        
}

proc createStdcellTestcasesFrame {tcF} {
    global paths
    set stdF [labelframe $tcF.stdTestF -text "Stdcell Testcases"]
    ::DA_widgets::multiSelectList $stdF \
                                  -variable testcases(testcases_stdcell) \
                                  -width 50 \
                                  -height 20 
    set paths(testcases_stdcell) $stdF.listF.listLB
    return $stdF        
}

proc createStdcellFillTestcasesFrame {tcF} {
    global paths
    set stdFillF [labelframe $tcF.stdFillTestF -text "Stdcell Fill Testcases"]
    ::DA_widgets::multiSelectList $stdFillF \
                                  -variable testcases(testcases_stdcell_fill) \
                                  -width 50 \
                                  -height 20 
    set paths(testcases_stdcell_fill) $stdFillF.listF.listLB
    return $stdFillF        
}

proc createUtilityTestcasesFrame {tcF} {
    global paths
    set utilityF [labelframe $tcF.utilityTestF -text "Utility Testcases"]
    set utilityConstructorProc "[namespace current]::utilityConstructor"
    ::DA_widgets::itemsFrame $utilityF \
                             -command $utilityConstructorProc \
                             -variable utilityTestcases
    set paths(utilityTestcases) $utilityF.addB
    return $utilityF        
}

proc utilityConstructor {path itemsArrayName index} {
    upvar #0 $itemsArrayName itemsArray

    # Create the frame
    set itemF [frame $path \
                     -relief ridge \
                     -borderwidth 2 \
                     -padx 4 \
                     -pady 4]
    # Add the remove button path to the array
    regsub {itemF} $path "removeB" removeBPath
    set itemsArray($index,remove,path) $removeBPath
    # Add the testcase entry
    set testcaseEntryF [frame $path.testcaseEF]
    label $testcaseEntryF.testcaseL -text "Testcase:"
    grid $testcaseEntryF.testcaseL -column 0 -row 0
    entry $testcaseEntryF.testcaseE \
          -textvariable "${itemsArrayName}($index,testcase)" \
          -width 42 \
          {*}$::DA_widgets::entrySettings
    grid $testcaseEntryF.testcaseE -column 1 -row 0 -columnspan 2
    pack $testcaseEntryF -fill x
    set itemsArray($index,testcase,path) $testcaseEntryF.testcaseE
    # Mode
    label $testcaseEntryF.modeL -text "Mode:"
    grid $testcaseEntryF.modeL -column 0 -row 1
    radiobutton $testcaseEntryF.full \
                -text "full" \
                -variable "${itemsArrayName}($index,mode)" \
                -value full
    grid $testcaseEntryF.full -column 1 -row 1
    radiobutton $testcaseEntryF.block_ew \
                -text "block_ew" \
                -variable "${itemsArrayName}($index,mode)" \
                -value block_ew
    grid $testcaseEntryF.block_ew -column 2 -row 1
    # Set GDS as the default option
    $testcaseEntryF.full invoke
    # Testcase value
    label $testcaseEntryF.valueL -text "Value:"
    grid $testcaseEntryF.valueL -column 0 -row 2
    entry $testcaseEntryF.valueE \
          -textvariable "${itemsArrayName}($index,value)" \
          -width 42 \
          {*}$::DA_widgets::entrySettings
    grid $testcaseEntryF.valueE -column 1 -row 2 -columnspan 2
    set itemsArray($index,value,path) $testcaseEntryF.valueE
    return $itemF
}

proc createWrapperTestcasesFrame {tcF} {
    global paths
    set wrapperF [labelframe $tcF.wrapperTestF -text "Wrapper Testcases"]
    ::DA_widgets::multiSelectList $wrapperF \
                                  -variable testcases(testcases_wrapper) \
                                  -width 50 \
                                  -height 20 
    set paths(testcases_wrapper) $wrapperF.listF.listLB
    return $wrapperF        
}

proc createPVTab {nb} {
    set pvTab [frame $nb.pvTab]
    $nb add $pvTab -text "PV"
    set pvF [::DA_widgets::scrollFrame $pvTab]
    set sections ""
    # Common Section
    lappend sections [createPvCommonFrame $pvF]
    # DRC Section
    lappend sections [createDrcFrame $pvF]
    # LVS Section
    lappend sections [createLvsFrame $pvF]
    # PERCCNOD Section
    lappend sections [createPerccnodFrame $pvF]
    # PERCCD Section
    lappend sections [createPerccdFrame $pvF]
    # PERCLDL Section
    lappend sections [createPercldlFrame $pvF]
    # PERCP2P Section
    lappend sections [createPercp2pFrame $pvF]
    # PERCTOPO Section
    lappend sections [createPerctopoFrame $pvF]
    # PERCTOPOLA Section
    lappend sections [createPerctopolaFrame $pvF]

    pack {*}$sections -fill x
}

proc createPvCommonFrame {pvF} {
    global paths parameters
    set commonF [labelframe $pvF.common -text "PV Parameters"]
    # msip_cd_pv version
    label $commonF.pvVersionL -text "MSIP_CD_PV Version:"
    grid $commonF.pvVersionL -column 0 -row 0 -sticky e
    entry $commonF.pvVersionE \
          -textvariable parameters(msip_cd_pv_version) \
          -width 37 \
          {*}$::DA_widgets::entrySettings
    grid $commonF.pvVersionE -column 1 -row 0
    set paths(msip_cd_pv_version) $commonF.pvVersionE
    # Grid
    checkbutton $commonF.pvGrid \
                -text "Grid" \
                -variable parameters(grid) \
                -borderwidth 0 \
                -relief flat \
                -highlightthickness 0
    grid $commonF.pvGrid -column 0 -row 1 -sticky w
    set paths(grid) $commonF.pvGrid
    # ICV Virtual Connect
    set icvVirtualOF  [frame $commonF.icvVirtual \
                             -borderwidth 0 \
                             -padx 4 \
                             -pady 4]
    grid $icvVirtualOF -column 0 -row 2 -columnspan 2 -sticky w
    set icvVirtualF [::DA_widgets::checkFrame $icvVirtualOF \
                                              -variable "parameters(virtual_connect_icv,toggle)" \
                                              -text "ICV Virtual Connect:" \
                                              -inline]
    ttk::combobox $icvVirtualF.icvVirtualConnectE \
                  -textvariable parameters(virtual_connect_icv) \
                  -values [list "ON" "OFF" "FOUNDRY_DEFAULT"]
    pack $icvVirtualF.icvVirtualConnectE -fill x
    $icvVirtualOF.checkB invoke
    $icvVirtualOF.checkB invoke
    set paths(virtual_connect_icv) $commonF.icvVirtualConnectE
    # calibre Virtual Connect
    set calibreVirtualOF  [frame $commonF.calibreVirtual \
                             -borderwidth 0 \
                             -padx 4 \
                             -pady 4]
    grid $calibreVirtualOF -column 0 -row 3 -columnspan 2 -sticky w
    set calibreVirtualF [::DA_widgets::checkFrame $calibreVirtualOF \
                                                  -variable "parameters(virtual_connect_calibre,toggle)" \
                                                  -text "Calibre Virtual Connect:" \
                                                  -inline]
    ttk::combobox $calibreVirtualF.calibreVirtualConnectE \
                  -textvariable parameters(virtual_connect_calibre) \
                  -values [list "ALL" "OFF"]
    pack $calibreVirtualF.calibreVirtualConnectE -fill x
    $calibreVirtualOF.checkB invoke
    $calibreVirtualOF.checkB invoke
    set paths(virtual_connect_calibre) $commonF.calibreVirtualConnectE
    # Adjust filler columns
    grid columnconfigure $commonF {2} -weight 1

    # Set defaults
    set parameters(grid) 1

    return $commonF
}

proc createDrcFrame {pvTab} {
    global paths
    # Create DRC Frame
    set drcOuterF [frame $pvTab.drc \
                             -relief ridge \
                             -borderwidth 4 \
                             -padx 4 \
                             -pady 4]
    set drcF [::DA_widgets::checkFrame $drcOuterF \
                                       -variable parameters(drc) \
                                       -text "DRC" \
                                       -collapsible]
    set paths(drc) $drcOuterF.checkB
    # Create Common options
    set commonF [createDrcCommonFrame $drcF]
    # Create ICV Frame
    set icvF [createDrcIcvFrame $drcF]
    # Create CALIBRE Frame
    set calibreF [createDrcCalibreFrame $drcF]

    pack $commonF $icvF $calibreF -fill x

    $drcOuterF.checkB invoke
    $drcOuterF.checkB invoke

    return $drcOuterF
}

proc createDrcCommonFrame {drcF} {
    global paths parameters
    set commonF [frame $drcF.common]
    # DRC Prefix
    label $commonF.prefixL -text "Prefix:"
    grid $commonF.prefixL -column 0 -row 0 -sticky e
    entry $commonF.prefixE \
          -textvariable parameters(drc_prefix) \
          -width 43 \
          {*}$::DA_widgets::entrySettings
    grid $commonF.prefixE -column 1 -row 0
    set paths(drc_prefix) $commonF.prefixE
    # DRC Fill
    checkbutton $commonF.feol \
                -text "FEOL Fill" \
                -variable parameters(drc_feol_fill) \
                -borderwidth 0 \
                -relief flat \
                -highlightthickness 0
    grid $commonF.feol -column 0 -row 1 -sticky w
    set paths(drc_feol_fill) $commonF.feol
    checkbutton $commonF.beol \
                -text "BEOL Fill" \
                -variable parameters(drc_beol_fill) \
                -borderwidth 0 \
                -relief flat \
                -highlightthickness 0
    grid $commonF.beol -column 0 -row 2 -sticky w
    set paths(drc_beol_fill) $commonF.beol
    # DRC Error Limit
    label $commonF.errorLimitL -text "Error Limit:"
    grid $commonF.errorLimitL -column 0 -row 3 -sticky e
    entry $commonF.errorLimitE \
          -textvariable parameters(drc_error_limit) \
          -validate key \
          -validatecommand "isInteger %P" \
          -invalidcommand bell \
          -width 43 \
          {*}$::DA_widgets::entrySettings
    grid $commonF.errorLimitE -column 1 -row 3
    set paths(drc_error_limit) $commonF.errorLimitE

    # Set defaults
    set parameters(drc_prefix) DRC

    return $commonF
}

proc createDrcIcvFrame {drcF} {
    global paths parameters
    set icvOuterF [frame $drcF.icv \
                             -relief sunken \
                             -borderwidth 2 \
                             -padx 4 \
                             -pady 4]
    set icvF [::DA_widgets::checkFrame $icvOuterF \
                                       -variable "parameters(drc_icv)" \
                                       -text "ICV" \
                                       -collapsible]
    # DRC ICV Number of grid processes
    label $icvF.gridProcessesL -text "Number of Grid Processes:"
    grid $icvF.gridProcessesL -column 0 -row 0 -sticky e
    entry $icvF.gridProcessesE \
          -textvariable parameters(drc_icv_grid_processes) \
          -validate key \
          -validatecommand "isInteger %P" \
          -invalidcommand bell \
          -width 30 \
          {*}$::DA_widgets::entrySettings
    grid $icvF.gridProcessesE -column 1 -row 0
    set paths(drc_icv_grid_processes) $icvF.gridProcessesE
    # DRC ICV Options file
    set optionsFileFE [::DA_widgets::fileEntry $icvF.optionsFileFE \
                                          -variable "parameters(drc_icv_options_file)" \
                                          -text "Options File:" \
                                          -width 30 \
                                          -checkable]
    grid $icvF.optionsFileFE -column 0 -row 1 -columnspan 2
    set paths(drc_icv_options_file) $icvF.optionsFileFE
    # DRC ICV Runset file
    set runsetFE [::DA_widgets::fileEntry $icvF.runsetFE \
                                          -variable "parameters(drc_icv_runset)" \
                                          -text "Runset File:" \
                                          -width 30 \
                                          -checkable]
    grid $icvF.runsetFE -column 0 -row 2 -columnspan 2
    set paths(drc_icv_runset) $icvF.runsetFE
    # DRC ICV Unselect rules
    label $icvF.unselectRulesL -text "Unselect Rules:"
    grid $icvF.unselectRulesL -column 0 -row 3 -sticky e
    entry $icvF.unselectRulesE \
          -textvariable parameters(drc_icv_unselect_rule_names) \
          -width 30 \
          {*}$::DA_widgets::entrySettings
    grid $icvF.unselectRulesE -column 1 -row 3
    set paths(drc_icv_unselect_rule_names) $icvF.unselectRulesE
    
    # Set defaults
    set parameters(drc_icv_grid_processes) 8

    return $icvOuterF
}

proc createDrcCalibreFrame {drcF} {
    global paths
    set calibreOuterF [frame $drcF.calibre \
                                 -relief sunken \
                                 -borderwidth 2 \
                                 -padx 4 \
                                 -pady 4]
    set calibreF [::DA_widgets::checkFrame $calibreOuterF \
                                           -variable parameters(drc_calibre) \
                                           -text "CALIBRE" \
                                           -collapsible]
    # DRC CALIBRE Extra arugments
    label $calibreF.extraArgsL -text "Extra arguments:"
    grid $calibreF.extraArgsL -column 1 -row 0
    entry $calibreF.extraArgsE \
          -textvariable parameters(drc_calex_extra_arguments) \
          -width 37 \
          {*}$::DA_widgets::entrySettings
    grid $calibreF.extraArgsE -column 2 -row 0
    set paths(drc_calex_extra_arguments) $calibreF.extraArgsE

    return $calibreOuterF
}

proc createLvsFrame {pvTab} {
    global paths
    # Create LVS Frame
    set lvsOuterF [frame $pvTab.lvs \
                             -relief ridge \
                             -borderwidth 4 \
                             -padx 4 \
                             -pady 4]
    set lvsF [::DA_widgets::checkFrame $lvsOuterF \
                                       -variable parameters(lvs) \
                                       -text "LVS" \
                                       -collapsible]
    set paths(lvs) $lvsOuterF.checkB
    # Create Common options
    set commonF [createLvsCommonFrame $lvsF]
    # Create ICV Frame
    set icvF [createLvsIcvFrame $lvsF]
    # Create CALIBRE Frame
    set calibreF [createLvsCalibreFrame $lvsF]

    pack $commonF $icvF $calibreF -fill x

    $lvsOuterF.checkB invoke
    $lvsOuterF.checkB invoke

    return $lvsOuterF
}

proc createLvsCommonFrame {lvsF} {
    global paths parameters
    set commonF [frame $lvsF.common]
    # LVS Prefix
    label $commonF.prefixL -text "Prefix:"
    grid $commonF.prefixL -column 0 -row 0
    entry $commonF.prefixE \
          -textvariable parameters(lvs_prefix) \
          -width 47 \
          {*}$::DA_widgets::entrySettings
    grid $commonF.prefixE -column 1 -row 0
    set paths(lvs_prefix) $commonF.prefixE

    # Set defaults
    set parameters(lvs_prefix) LVS

    return $commonF
}

proc createLvsIcvFrame {lvsF} {
    global paths parameters
    set icvOuterF [frame $lvsF.icv \
                             -relief sunken \
                             -borderwidth 2 \
                             -padx 4 \
                             -pady 4]
    set icvF [::DA_widgets::checkFrame $icvOuterF \
                                       -variable "parameters(lvs_icv)" \
                                       -text "ICV" \
                                       -collapsible]
    # LVS ICV Number of grid processes
    label $icvF.gridProcessesL -text "Number of Grid Processes:"
    grid $icvF.gridProcessesL -column 0 -row 0 -sticky e
    entry $icvF.gridProcessesE \
          -textvariable parameters(lvs_icv_grid_processes) \
          -validate key \
          -validatecommand "isInteger %P" \
          -invalidcommand bell \
          -width 31 \
          {*}$::DA_widgets::entrySettings
    grid $icvF.gridProcessesE -column 1 -row 0
    set paths(lvs_icv_grid_processes) $icvF.gridProcessesE
    
    # Set defaults
    set parameters(lvs_icv_grid_processes) 4
    
    return $icvOuterF
}

proc createLvsCalibreFrame {lvsF} {
    global paths
    set calibreOuterF [frame $lvsF.calibre \
                                 -relief sunken \
                                 -borderwidth 2 \
                                 -padx 4 \
                                 -pady 4]
    set calibreF [::DA_widgets::checkFrame $calibreOuterF \
                                           -variable parameters(lvs_calibre) \
                                           -text "CALIBRE" \
                                           -collapsible]
    # LVS CALIBRE Extra arugments
    label $calibreF.extraArgsL -text "Extra arguments:"
    grid $calibreF.extraArgsL -column 0 -row 0
    entry $calibreF.extraArgsE \
          -textvariable parameters(lvs_calex_extra_arguments) \
          -width 37 \
          {*}$::DA_widgets::entrySettings
    grid $calibreF.extraArgsE -column 1 -row 0
    set paths(lvs_calex_extra_arguments $calibreF.extraArgsE

    return $calibreOuterF
}

proc createPerccnodFrame {pvTab} {
    global paths
    # Create PERCCNOD Frame
    set perccnodOuterF [frame $pvTab.perccnod \
                             -relief ridge \
                             -borderwidth 4 \
                             -padx 4 \
                             -pady 4]
    set perccnodF [::DA_widgets::checkFrame $perccnodOuterF \
                                            -variable parameters(perccnod) \
                                            -text "PERCCNOD" \
                                            -collapsible]
    set paths(perccnod) $perccnodOuterF.checkB
    # Create Common options
    set commonF [createPerccnodCommonFrame $perccnodF]
    # Create ICV Frame
    set icvF [createPerccnodIcvFrame $perccnodF]
    # Create CALIBRE Frame
    set calibreF [createPerccnodCalibreFrame $perccnodF]

    pack $commonF $icvF $calibreF -fill x

    $perccnodOuterF.checkB invoke
    $perccnodOuterF.checkB invoke

    return $perccnodOuterF
}

proc createPerccnodCommonFrame {perccnodF} {
    global paths parameters
    set commonF [frame $perccnodF.common]
    # PERCCNOD Prefix
    label $commonF.prefixL -text "Prefix:"
    grid $commonF.prefixL -column 0 -row 0
    entry $commonF.prefixE \
          -textvariable parameters(perccnod_prefix) \
          -width 47 \
          {*}$::DA_widgets::entrySettings
    grid $commonF.prefixE -column 1 -row 0
    set paths(perccnod_prefix) $commonF.prefixE

    # Set defaults
    set parameters(perccnod_prefix) "PERCCNOD"

    return $commonF
}

proc createPerccnodIcvFrame {perccnodF} {
    global paths parameters
    set icvOuterF [frame $perccnodF.icv \
                             -relief sunken \
                             -borderwidth 2 \
                             -padx 4 \
                             -pady 4]
    set icvF [::DA_widgets::checkFrame $icvOuterF \
                                       -variable "parameters(perccnod_icv)" \
                                       -text "ICV" \
                                       -collapsible]
    # PERCCNOD ICV Number of grid processes
    label $icvF.gridProcessesL -text "Number of Grid Processes:"
    grid $icvF.gridProcessesL -column 0 -row 0 -sticky e
    entry $icvF.gridProcessesE \
          -textvariable parameters(perccnod_icv_grid_processes) \
          -validate key \
          -validatecommand "isInteger %P" \
          -invalidcommand bell \
          -width 31 \
          {*}$::DA_widgets::entrySettings
    grid $icvF.gridProcessesE -column 1 -row 0
    set paths(perccnod_icv_grid_processes) $icvF.gridProcessesE

    # Set defaults
    set parameters(perccnod_icv_grid_processes) 4
    
    return $icvOuterF
}

proc createPerccnodCalibreFrame {perccnodF} {
    global paths
    set calibreOuterF [frame $perccnodF.calibre \
                                 -relief sunken \
                                 -borderwidth 2 \
                                 -padx 4 \
                                 -pady 4]
    set calibreF [::DA_widgets::checkFrame $calibreOuterF \
                                           -variable parameters(perccnod_calibre) \
                                           -text "CALIBRE" \
                                           -collapsible]
    # PERCCNOD CALIBRE Extra arugments
    label $calibreF.extraArgsL -text "Extra arguments:"
    grid $calibreF.extraArgsL -column 0 -row 0
    entry $calibreF.extraArgsE \
          -textvariable parameters(perccnod_calex_extra_arguments) \
          -width 37 \
          {*}$::DA_widgets::entrySettings
    grid $calibreF.extraArgsE -column 1 -row 0
    set paths(perccnod_calex_extra_arguments) $calibreF.extraArgsE

    return $calibreOuterF
}

proc createPerccdFrame {pvTab} {
    global paths
    # Create PERCCD Frame
    set perccdOuterF [frame $pvTab.perccd \
                             -relief ridge \
                             -borderwidth 4 \
                             -padx 4 \
                             -pady 4]
    set perccdF [::DA_widgets::checkFrame $perccdOuterF \
                                          -variable parameters(perccd) \
                                          -text "PERCCD" \
                                          -collapsible]
    set paths(perccd) $perccdOuterF.checkB
    # Create Common options
    set commonF [createPerccdCommonFrame $perccdF]
    # Create ICV Frame
    set icvF [createPerccdIcvFrame $perccdF]
    # Create CALIBRE Frame
    set calibreF [createPerccdCalibreFrame $perccdF]

    pack $commonF $icvF $calibreF -fill x

    $perccdOuterF.checkB invoke
    $perccdOuterF.checkB invoke

    return $perccdOuterF
}

proc createPerccdCommonFrame {perccdF} {
    global paths parameters
    set commonF [frame $perccdF.common]
    # PERCCD Prefix
    label $commonF.prefixL -text "Prefix:"
    grid $commonF.prefixL -column 0 -row 0
    entry $commonF.prefixE \
          -textvariable parameters(perccd_prefix) \
          -width 47 \
          {*}$::DA_widgets::entrySettings
    grid $commonF.prefixE -column 1 -row 0
    set paths(perccd_prefix) $commonF.prefixE

    # Set defaults
    set parameters(perccd_prefix) "PERCCD"

    return $commonF
}

proc createPerccdIcvFrame {perccdF} {
    global paths parameters
    set icvOuterF [frame $perccdF.icv \
                             -relief sunken \
                             -borderwidth 2 \
                             -padx 4 \
                             -pady 4]
    set icvF [::DA_widgets::checkFrame $icvOuterF \
                                       -variable "parameters(perccd_icv)" \
                                       -text "ICV" \
                                       -collapsible]
    # PERCCD ICV Number of grid hosts
    label $icvF.gridHostsL -text "Number of grid hosts:"
    grid $icvF.gridHostsL -column 0 -row 0 -sticky e
    entry $icvF.gridHostsE \
          -textvariable parameters(perccd_icv_grid_hosts) \
          -validate key \
          -validatecommand "isInteger %P" \
          -invalidcommand bell \
          -width 27 \
          {*}$::DA_widgets::entrySettings
    grid $icvF.gridHostsE -column 1 -row 0
    set paths(perccd_icv_grid_hosts) $icvF.gridHostsE
    # PERCCD ICV Number of grid cores per host
    label $icvF.coresPerHostL -text "Number of grid cores per host:"
    grid $icvF.coresPerHostL -column 0 -row 1 -sticky e
    entry $icvF.coresPerHostE \
          -textvariable parameters(perccd_icv_grid_cores_per_host) \
          -validate key \
          -validatecommand "isInteger %P" \
          -invalidcommand bell \
          -width 27 \
          {*}$::DA_widgets::entrySettings
    grid $icvF.coresPerHostE -column 1 -row 1
    set paths(perccd_icv_grid_cores_per_host) $icvF.coresPerHostE
    # PERCCD ICV grid h_vmem
    label $icvF.hvmemL -text "h v_mem"
    grid $icvF.hvmemL -column 0 -row 2 -sticky e
    entry $icvF.hvmemE \
          -textvariable parameters(perccd_icv_grid_h_vmem) \
          -width 27 \
          {*}$::DA_widgets::entrySettings
    grid $icvF.hvmemE -column 1 -row 2
    set paths(perccd_icv_grid_h_vmem) $icvF.hvmemE

    # Set defaults
    set parameters(perccd_icv_grid_hosts) 4
    set parameters(perccd_icv_grid_cores_per_host) 4
    set parameters(perccd_icv_grid_h_vmem) "1000G"
    
    return $icvOuterF
}

proc createPerccdCalibreFrame {perccdF} {
    global paths parameters
    set calibreOuterF [frame $perccdF.calibre \
                                 -relief sunken \
                                 -borderwidth 2 \
                                 -padx 4 \
                                 -pady 4]
    set calibreF [::DA_widgets::checkFrame $calibreOuterF \
                                           -variable "parameters(perccd_calibre)" \
                                           -text "CALIBRE" \
                                           -collapsible]
    # PERCCD CALIBRE Extra arugments
    label $calibreF.extraArgsL -text "Extra arguments:"
    grid $calibreF.extraArgsL -column 0 -row 0
    entry $calibreF.extraArgsE \
          -textvariable parameters(perccd_calex_extra_arguments) \
          -width 37 \
          {*}$::DA_widgets::entrySettings
    grid $calibreF.extraArgsE -column 1 -row 0
    set paths(perccd_calex_extra_arguments) $calibreF.extraArgsE

    # Set defaults
    set parameters(perccd_calex_extra_arguments) "--long"

    return $calibreOuterF
}

proc createPercldlFrame {pvTab} {
    global paths
    # Create PERCLDL Frame
    set percldlOuterF [frame $pvTab.percldl \
                             -relief ridge \
                             -borderwidth 4 \
                             -padx 4 \
                             -pady 4]
    set percldlF [::DA_widgets::checkFrame $percldlOuterF \
                                           -variable parameters(percldl) \
                                           -text "PERCLDL" \
                                           -collapsible]
    set paths(percldl) $percldlOuterF.checkB
    # Create Common options
    set commonF [createPercldlCommonFrame $percldlF]
    # Create ICV Frame
    set icvF [createPercldlIcvFrame $percldlF]
    # Create CALIBRE Frame
    set calibreF [createPercldlCalibreFrame $percldlF]

    pack $commonF $icvF $calibreF -fill x

    $percldlOuterF.checkB invoke
    $percldlOuterF.checkB invoke

    return $percldlOuterF
}

proc createPercldlCommonFrame {percldlF} {
    global paths parameters
    set commonF [frame $percldlF.common]
    # PERCLDL Prefix
    label $commonF.prefixL -text "Prefix:"
    grid $commonF.prefixL -column 0 -row 0
    entry $commonF.prefixE \
          -textvariable parameters(percldl_prefix) \
          -width 47 \
          {*}$::DA_widgets::entrySettings
    grid $commonF.prefixE -column 1 -row 0
    set paths(percldl_prefix) $commonF.prefixE

    # Set defaults
    set parameters(percldl_prefix) "PERCLDL"

    return $commonF
}

proc createPercldlIcvFrame {percldlF} {
    global paths parameters
    set icvOuterF [frame $percldlF.icv \
                             -relief sunken \
                             -borderwidth 2 \
                             -padx 4 \
                             -pady 4]
    set icvF [::DA_widgets::checkFrame $icvOuterF \
                                       -variable "parameters(percldl_icv)" \
                                       -text "ICV" \
                                       -collapsible]
    # PERCLDL ICV Number of grid processes
    label $icvF.gridProcessesL -text "Number of Grid Processes:"
    grid $icvF.gridProcessesL -column 0 -row 0
    entry $icvF.gridProcessesE \
          -textvariable parameters(percldl_icv_grid_processes) \
          -validate key \
          -validatecommand "isInteger %P" \
          -invalidcommand bell \
          -width 31 \
          {*}$::DA_widgets::entrySettings
    grid $icvF.gridProcessesE -column 1 -row 0
    set paths(percldl_icv_grid_processes) $icvF.gridProcessesE

    # Set defaults
    set parameters(percldl_icv_grid_processes) 4
    
    return $icvOuterF
}

proc createPercldlCalibreFrame {percldlF} {
    global paths
    set calibreOuterF [frame $percldlF.calibre \
                                 -relief sunken \
                                 -borderwidth 2 \
                                 -padx 4 \
                                 -pady 4]
    set calibreF [::DA_widgets::checkFrame $calibreOuterF \
                                           -variable parameters(percldl_calibre) \
                                           -text "CALIBRE" \
                                           -collapsible]
    # PERCLDL CALIBRE Extra arugments
    label $calibreF.extraArgsL -text "Extra arguments:"
    grid $calibreF.extraArgsL -column 0 -row 0
    entry $calibreF.extraArgsE \
          -textvariable parameters(percldl_calex_extra_arguments) \
          -width 37 \
          {*}$::DA_widgets::entrySettings
    grid $calibreF.extraArgsE -column 1 -row 0
    set paths(percldl_calex_extra_arguments) $calibreF.extraArgsE

    return $calibreOuterF
}

proc createPercp2pFrame {pvTab} {
    global paths
    # Create PERCP2P Frame
    set percp2pOuterF [frame $pvTab.percp2p \
                             -relief ridge \
                             -borderwidth 4 \
                             -padx 4 \
                             -pady 4]
    set percp2pF [::DA_widgets::checkFrame $percp2pOuterF \
                                           -variable parameters(percp2p) \
                                           -text "PERCP2P" \
                                           -collapsible]
    set paths(percp2p) $percp2pOuterF.checkB
    # Create Common options
    set commonF [createPercp2pCommonFrame $percp2pF]
    # Create ICV Frame
    set icvF [createPercp2pIcvFrame $percp2pF]
    # Create CALIBRE Frame
    set calibreF [createPercp2pCalibreFrame $percp2pF]

    pack $commonF $icvF $calibreF -fill x

    $percp2pOuterF.checkB invoke
    $percp2pOuterF.checkB invoke

    return $percp2pOuterF
}

proc createPercp2pCommonFrame {percp2pF} {
    global paths parameters
    set commonF [frame $percp2pF.common]
    # PERCP2P Prefix
    label $commonF.prefixL -text "Prefix:"
    grid $commonF.prefixL -column 0 -row 0
    entry $commonF.prefixE \
          -textvariable parameters(percp2p_prefix) \
          -width 47 \
          {*}$::DA_widgets::entrySettings
    grid $commonF.prefixE -column 1 -row 0
    set paths(percp2p_prefix) $commonF.prefixE

    # Set defaults
    set parameters(percp2p_prefix) "PERCP2P"

    return $commonF
}

proc createPercp2pIcvFrame {percp2pF} {
    global paths parameters
    set icvOuterF [frame $percp2pF.icv \
                             -relief sunken \
                             -borderwidth 2 \
                             -padx 4 \
                             -pady 4]
    set icvF [::DA_widgets::checkFrame $icvOuterF \
                                       -variable "parameters(percp2p_icv)" \
                                       -text "ICV" \
                                       -collapsible]
    # PERCP2P ICV Number of grid hosts
    label $icvF.gridHostsL -text "Number of grid hosts:"
    grid $icvF.gridHostsL -column 0 -row 0
    entry $icvF.gridHostsE \
          -textvariable parameters(percp2p_icv_grid_hosts) \
          -validate key \
          -validatecommand "isInteger %P" \
          -invalidcommand bell \
          -width 27 \
          {*}$::DA_widgets::entrySettings
    grid $icvF.gridHostsE -column 1 -row 0
    set paths(percp2p_icv_grid_hosts) $icvF.gridHostsE
    # PERCP2P ICV Number of grid cores per host
    label $icvF.coresPerHostL -text "Number of grid cores per host:"
    grid $icvF.coresPerHostL -column 0 -row 1
    entry $icvF.coresPerHostE \
          -textvariable parameters(percp2p_icv_grid_cores_per_host) \
          -validate key \
          -validatecommand "isInteger %P" \
          -invalidcommand bell \
          -width 27 \
          {*}$::DA_widgets::entrySettings
    grid $icvF.coresPerHostE -column 1 -row 1
    set paths(percp2p_icv_grid_cores_per_host) $icvF.coresPerHostE
    # PERCP2P ICV grid h_vmem
    label $icvF.hvmemL -text "h v_mem"
    grid $icvF.hvmemL -column 0 -row 2
    entry $icvF.hvmemE \
          -textvariable parameters(percp2p_icv_grid_h_vmem) \
          -width 27 \
          {*}$::DA_widgets::entrySettings
    grid $icvF.hvmemE -column 1 -row 2
    set paths(percp2p_icv_grid_h_vmem) $icvF.hvmemE

    # Set defaults
    set parameters(percp2p_icv_grid_hosts) 4
    set parameters(percp2p_icv_grid_cores_per_host) 4
    set parameters(percp2p_icv_grid_h_vmem) "1000G"
    
    return $icvOuterF
}

proc createPercp2pCalibreFrame {percp2pF} {
    global paths parameters
    set calibreOuterF [frame $percp2pF.calibre \
                                 -relief sunken \
                                 -borderwidth 2 \
                                 -padx 4 \
                                 -pady 4]
    set calibreF [::DA_widgets::checkFrame $calibreOuterF \
                                           -variable "parameters(percp2p_calibre)" \
                                           -text "CALIBRE" \
                                           -collapsible]
    # PERCP2P CALIBRE Extra arugments
    label $calibreF.extraArgsL -text "Extra arguments:"
    grid $calibreF.extraArgsL -column 0 -row 0
    entry $calibreF.extraArgsE \
          -textvariable parameters(percp2p_calex_extra_arguments) \
          -width 37 \
          {*}$::DA_widgets::entrySettings
    grid $calibreF.extraArgsE -column 1 -row 0
    set paths(percp2p_calex_extra_arguments) $calibreF.extraArgsE

    # Set defaults
    set parameters(percp2p_calex_extra_arguments) "--long"

    return $calibreOuterF
}

proc createPerctopoFrame {pvTab} {
    global paths
    # Create PERCTOPO Frame
    set perctopoOuterF [frame $pvTab.perctopo \
                             -relief ridge \
                             -borderwidth 4 \
                             -padx 4 \
                             -pady 4]
    set perctopoF [::DA_widgets::checkFrame $perctopoOuterF \
                                            -variable parameters(perctopo) \
                                            -text "PERCTOPO" \
                                            -collapsible]
    set paths(perctopo) $perctopoOuterF.checkB
    # Create Common options
    set commonF [createPerctopoCommonFrame $perctopoF]
    # Create ICV Frame
    set icvF [createPerctopoIcvFrame $perctopoF]
    # Create CALIBRE Frame
    set calibreF [createPerctopoCalibreFrame $perctopoF]

    pack $commonF $icvF $calibreF -fill x

    $perctopoOuterF.checkB invoke
    $perctopoOuterF.checkB invoke

    return $perctopoOuterF
}

proc createPerctopoCommonFrame {perctopoF} {
    global paths parameters
    set commonF [frame $perctopoF.common]
    # PERCTOPO Prefix
    label $commonF.prefixL -text "Prefix:"
    grid $commonF.prefixL -column 0 -row 0
    entry $commonF.prefixE \
          -textvariable parameters(perctopo_prefix) \
          -width 47 \
          {*}$::DA_widgets::entrySettings
    grid $commonF.prefixE -column 1 -row 0
    set paths(perctopo_prefix) $commonF.prefixE

    # Set defaults
    set parameters(perctopo_prefix) "PERCTOPO"

    return $commonF
}

proc createPerctopoIcvFrame {perctopoF} {
    global paths parameters
    set icvOuterF [frame $perctopoF.icv \
                             -relief sunken \
                             -borderwidth 2 \
                             -padx 4 \
                             -pady 4]
    set icvF [::DA_widgets::checkFrame $icvOuterF \
                                       -variable "parameters(perctopo_icv)" \
                                       -text "ICV" \
                                       -collapsible]
    # PERCTOPO ICV Number of grid processes
    label $icvF.gridProcessesL -text "Number of Grid Processes:"
    grid $icvF.gridProcessesL -column 0 -row 0
    entry $icvF.gridProcessesE \
          -textvariable parameters(perctopo_icv_grid_processes) \
          -validate key \
          -validatecommand "isInteger %P" \
          -invalidcommand bell \
          -width 31 \
          {*}$::DA_widgets::entrySettings
    grid $icvF.gridProcessesE -column 1 -row 0
    set paths(perctopo_icv_grid_processes) $icvF.gridProcessesE

    # Set defaults
    set parameters(perctopo_icv_grid_processes) 4
    
    return $icvOuterF
}

proc createPerctopoCalibreFrame {perctopoF} {
    global paths
    set calibreOuterF [frame $perctopoF.calibre \
                                 -relief sunken \
                                 -borderwidth 2 \
                                 -padx 4 \
                                 -pady 4]
    set calibreF [::DA_widgets::checkFrame $calibreOuterF \
                                           -variable parameters(perctopo_calibre) \
                                           -text "CALIBRE" \
                                           -collapsible]
    # PERCTOPO CALIBRE Extra arugments
    label $calibreF.extraArgsL -text "Extra arguments:"
    grid $calibreF.extraArgsL -column 0 -row 0
    entry $calibreF.extraArgsE \
          -textvariable parameters(perctopo_calex_extra_arguments) \
          -width 37 \
          {*}$::DA_widgets::entrySettings
    grid $calibreF.extraArgsE -column 1 -row 0
    set paths(perctopo_calex_extra_arguments) $calibreF.extraArgsE

    return $calibreOuterF
}

proc createPerctopolaFrame {pvTab} {
    global paths
    # Create PERCTOPOLA Frame
    set perctopolaOuterF [frame $pvTab.perctopola \
                             -relief ridge \
                             -borderwidth 4 \
                             -padx 4 \
                             -pady 4]
    set perctopolaF [::DA_widgets::checkFrame $perctopolaOuterF \
                                              -variable parameters(perctopola) \
                                              -text "PERCTOPOLA" \
                                              -collapsible]
    set paths(perctopola) $perctopolaOuterF.checkB
    # Create Common options
    set commonF [createPerctopolaCommonFrame $perctopolaF]
    # Create ICV Frame
    set icvF [createPerctopolaIcvFrame $perctopolaF]
    # Create CALIBRE Frame
    set calibreF [createPerctopolaCalibreFrame $perctopolaF]

    pack $commonF $icvF $calibreF -fill x

    $perctopolaOuterF.checkB invoke
    $perctopolaOuterF.checkB invoke

    return $perctopolaOuterF
}

proc createPerctopolaCommonFrame {perctopolaF} {
    global paths parameters
    set commonF [frame $perctopolaF.common]
    # PERCTOPOLA Prefix
    label $commonF.prefixL -text "Prefix:"
    grid $commonF.prefixL -column 0 -row 0
    entry $commonF.prefixE \
          -textvariable parameters(perctopola_prefix) \
          -width 47 \
          {*}$::DA_widgets::entrySettings
    grid $commonF.prefixE -column 1 -row 0
    set paths(perctopola_prefix) $commonF.prefixE

    # Set defaults
    set parameters(perctopola_prefix) "PERCTOPOLA"

    return $commonF
}

proc createPerctopolaIcvFrame {perctopolaF} {
    global paths parameters
    set icvOuterF [frame $perctopolaF.icv \
                             -relief sunken \
                             -borderwidth 2 \
                             -padx 4 \
                             -pady 4]
    set icvF [::DA_widgets::checkFrame $icvOuterF \
                                       -variable "parameters(perctopola_icv)" \
                                       -text "ICV" \
                                       -collapsible]
    # PERCTOPOLA ICV Number of grid processes
    label $icvF.gridProcessesL -text "Number of Grid Processes:"
    grid $icvF.gridProcessesL -column 0 -row 0
    entry $icvF.gridProcessesE \
          -textvariable parameters(perctopola_icv_grid_processes) \
          -validate key \
          -validatecommand "isInteger %P" \
          -invalidcommand bell \
          -width 31 \
          {*}$::DA_widgets::entrySettings
    grid $icvF.gridProcessesE -column 1 -row 0
    set paths(perctopola_icv_grid_processes) $icvF.gridProcessesE

    # Set defaults
    set parameters(perctopola_icv_grid_processes) 4
    
    return $icvOuterF
}

proc createPerctopolaCalibreFrame {perctopolaF} {
    global paths
    set calibreOuterF [frame $perctopolaF.calibre \
                                 -relief sunken \
                                 -borderwidth 2 \
                                 -padx 4 \
                                 -pady 4]
    set calibreF [::DA_widgets::checkFrame $calibreOuterF \
                                           -variable parameters(perctopola_calibre) \
                                           -text "CALIBRE" \
                                           -collapsible]
    # PERCTOPOLA CALIBRE Extra arugments
    label $calibreF.extraArgsL -text "Extra arguments:"
    grid $calibreF.extraArgsL -column 0 -row 0
    entry $calibreF.extraArgsE \
          -textvariable parameters(perctopola_calex_extra_arguments) \
          -width 37 \
          {*}$::DA_widgets::entrySettings
    grid $calibreF.extraArgsE -column 1 -row 0
    set paths(perctopola_calex_extra_arguments) $calibreF.extraArgsE

    return $calibreOuterF
}

proc isDouble {value} {
    if {![string is double $value]} {
        return 0
    } else {
        return 1
    }
}

proc isInteger {value} {
    if {![string is integer $value]} {
        return 0
    } else {
        return 1
    }
}

proc save {path {dialog false}} {
    global parametersFile
    if {$parametersFile == ""} {
        $path invoke
    }
    if {$parametersFile == ""} {
        error "The save file path cannot be left empty!"
    }

    set fileContent ""
    lappend fileContent [join [saveMainTab] "\n"]
    lappend fileContent [join [saveMacrosTab] "\n"]
    lappend fileContent [join [saveStdcellsTab] "\n"]
    # Update the testcases listboxes to ensure that any edit in the macros tab was
    # accounted for (in case a testcases is no longer available but was selected
    # previously).
    updateTestcasesListboxes
    lappend fileContent [join [saveTestcasesTab] "\n"]
    lappend fileContent [join [savePvTab] "\n"]
    write_file $parametersFile [join $fileContent "\n"]
    if {$dialog} {
        tk_dialog .saveSucess "Save Successful" "Saved the entries sucessfully!" \
                  questhead 0 ok
    }
}

proc run {path} {
    global parametersFile
    save $path
    set runDir [file dirname [file normalize $parametersFile]]
    destroy .
    exec bash -c "cd $runDir; source ~/.bashrc; module unload ddr-utils-lay; module load ddr-utils-lay; ddr-crd_abutment.tcl -params $parametersFile | tee /dev/tty"
}

proc saveMainTab {} {
    global parameters
    set mainTabContent [list]
    # UDE Parameters
    lappend mainTabContent "#UDE Parameters"
    set udeList [list project_type project_name release_name metal_stack]
    foreach item $udeList {
        lappend mainTabContent [addIfNotEmpty $item]
    }
    # Process Parameters
    lappend mainTabContent "\n#Process Parameters"
    set processList [list boundary_layer dbu tap_distance icc2_gds_layer_map \
                          icc2_techfile ]
    foreach item $processList {
        lappend mainTabContent [addOptionally $item]
    }
    # Abutment Parameters
    lappend mainTabContent "\n#Abutment Parameters"
    lappend mainTabContent "generate_boundary,$parameters(generate_boundary)"
    set abutmentList [list generate_boundary_upsize_b \
                           generate_boundary_upsize_l \
                           generate_boundary_upsize_r \
                           generate_boundary_upsize_t]
    if {$parameters(generate_boundary) == 1} {
        foreach item $abutmentList {
            if {$parameters($item) != ""} {
                lappend mainTabContent "$item,$parameters($item)"
            } else {
                lappend mainTabContent "$item,0"
            }
        }
    } else {
        foreach item $abutmentList {
            lappend mainTabContent "#$item,$parameters($item)"
        }
    }
    # Text Parameters
    lappend mainTabContent "\n#Text Parameters"
    set textList [list covercell_text_layers macro_text_layers]
    foreach item $textList {
        lappend mainTabContent [addOptionally $item]
    }
    return $mainTabContent
}

proc addIfNotEmpty {item} {
    global parameters paths
    if {[info exists parameters($item)] && $parameters($item) != ""} {
        return "$item,$parameters($item)"
    } else {
        regexp {(\.[^\.]+)(\.[^\.]+)} $paths($item) - notebook tabname
        $notebook select $notebook$tabname
        focus $paths($item)
        error "The entry for $item cannot be left empty!"
    }
}

proc saveMacrosTab {} {
    global macros covercells
    set macrosTabContent [list]
    # Macro Entries
    set validIndices [list]
    foreach item [array names macros "*,valid"] {
        if {$macros($item)} {
            set index [regexp -inline {^\d+} $item]
            lappend validIndices $index
            checkMacroName $index "macros"
        }
    }
    # Macros CDL Parameters
    lappend macrosTabContent "\n#Macro CDL Parameters"
    foreach index $validIndices {
        if {[checkItemEntry $index cdl "macros"]} {
            lappend macrosTabContent "cdl_$macros($index,macro),$macros($index,cdl)"
        }
    }
    # Macros DEF Parameters
    lappend macrosTabContent "\n#Macro DEF Parameters"
    foreach index $validIndices {
        if {[checkItemEntry $index def "macros"]} {
            lappend macrosTabContent "def_$macros($index,macro),$macros($index,def)"
        }
    }
    # Macros GDS Parameters
    lappend macrosTabContent "\n#Macro GDS Parameters"
    foreach index $validIndices {
        if {[checkItemEntry $index gds "macros"]} {
            lappend macrosTabContent "gds_$macros($index,macro),$macros($index,gds)"
        }
    }
    # Macros LEF Parameters
    lappend macrosTabContent "\n#Macro LEF Parameters"
    foreach index $validIndices {
        if {[checkItemEntry $index lef "macros"]} {
            lappend macrosTabContent "lef_$macros($index,macro),$macros($index,lef)"
        }
    }
    # Covercell Entries
    regsub -all {,\S+} [array names covercells] "" indicesList
    set indicesList [lsort -unique $indicesList]
    set validIndices [list]
    foreach index $indicesList {
        if {$covercells($index,valid) == true} {
            lappend validIndices $index
            checkMacroName $index "covercells"
        }
    }
    # Macros GDS Parameters
    lappend macrosTabContent "\n#Covercell GDS Parameters"
    foreach index $validIndices {
        if {[info exists covercells($index,gds)] && $covercells($index,gds) != ""} {
            lappend macrosTabContent "gds_dwc_ddrphycover_$covercells($index,macro),$covercells($index,gds)"
        } else {
            regexp {(\.[^\.]+)(\.[^\.]+)} $covercells($index,gds,path) - notebook tabname
            $notebook select $notebook$tabname
            focus $covercells($index,gds,path)
            error "The entry for GDS for $covercells($index,macro) cannot be left empty!"
        }
    }
    return $macrosTabContent
}

proc checkMacroName {index varName {testcase 0}} {
    upvar #0 $varName itemsArray
    if {![info exists itemsArray($index,macro)] || $itemsArray($index,macro) == ""} {
        regexp {(\.[^\.]+)(\.[^\.]+)} $itemsArray($index,macro,path) - notebook tabname
        $notebook select $notebook$tabname
        focus $itemsArray($index,macro)
        if {$testcase != 1} {
            error "The macro name cannot be left empty!"
        } else {
            error "The macro/testcase name cannot be left empty!"
        }
    }
}

proc checkItemEntry {index item varName} {
    upvar #0 $varName itemsArray
    if {$itemsArray($index,$item,toggle)} {
        if {![info exists itemsArray($index,$item)] || $itemsArray($index,$item) == ""} {
            regexp {(\.[^\.]+)(\.[^\.]+)} $itemsArray($index,$item,path) - notebook tabname
            $notebook select $notebook$tabname
            focus $itemsArray($index,$item,path)
            error "The entry for [string toupper $item] for $itemsArray($index,macro) cannot be left empty!"
        } else {
            return 1
        }
    } else {
        return 0
    }
}

proc saveStdcellsTab {} {
    global parameters manualKpt
    set stdcellsTabContent [list]
    # Stdcell Parameters
    lappend stdcellsTabContent "\n#Standard cell Parameters"
    set stdcellsList [list boundary_bottom boundary_bottom_left_inside_corner \
                           boundary_bottom_left_inside_horizontal_abutment \
                           boundary_bottom_left_outside_corner \
                           boundary_bottom_right_inside_corner \
                           boundary_bottom_right_inside_horizontal_abutment \
                           boundary_bottom_right_outside_corner \
                           boundary_left boundary_right boundary_top \
                           boundary_top_left_inside_corner \
                           boundary_top_left_outside_corner \
                           boundary_top_right_inside_corner \
                           boundary_top_right_outside_corner \
                           stdcell_drive_strength stdcell_gds \
                           stdcell_inner_kpt_b stdcell_inner_kpt_l \
                           stdcell_inner_kpt_r stdcell_inner_kpt_t \
                           stdcell_kpt_b stdcell_kpt_l stdcell_kpt_r \
                           stdcell_kpt_t stdcell_ndm stdcell_tap \
                           stdcell_tap_boundary_wall_cell_n_fill_wall \
                           stdcell_tap_boundary_wall_cell_n_fill_wall_replacement \
                           stdcell_tap_boundary_wall_cell_n_inner_corner_boundary \
                           stdcell_tap_boundary_wall_cell_n_left_tap \
                           stdcell_tap_boundary_wall_cell_n_right_tap \
                           stdcell_tap_boundary_wall_cell_n_ntap_inner_corner_boundary \
                           stdcell_tap_boundary_wall_cell_n_ptap_inner_corner_boundary \
                           stdcell_tap_boundary_wall_cell_n_tap \
                           stdcell_tap_boundary_wall_cell_n_tap_wall \
                           stdcell_tap_boundary_wall_cell_n_tb_boundary \
                           stdcell_tap_boundary_wall_cell_n_tb_corner_boundary \
                           stdcell_tap_boundary_wall_cell_n_tb_corner_tap \
                           stdcell_tap_boundary_wall_cell_n_tb_tap \
                           stdcell_tap_boundary_wall_cell_n_tb_tap_wall \
                           stdcell_tap_boundary_wall_cell_n_tb_wall \
                           stdcell_tap_boundary_wall_cell_p_fill_wall \
                           stdcell_tap_boundary_wall_cell_p_fill_wall_replacement \
                           stdcell_tap_boundary_wall_cell_p_inner_corner_boundary \
                           stdcell_tap_boundary_wall_cell_p_left_tap \
                           stdcell_tap_boundary_wall_cell_p_right_tap \
                           stdcell_tap_boundary_wall_cell_p_ntap_inner_corner_boundary \
                           stdcell_tap_boundary_wall_cell_p_ptap_inner_corner_boundary \
                           stdcell_tap_boundary_wall_cell_p_tap \
                           stdcell_tap_boundary_wall_cell_p_tap_wall \
                           stdcell_tap_boundary_wall_cell_p_tb_boundary \
                           stdcell_tap_boundary_wall_cell_p_tb_corner_boundary \
                           stdcell_tap_boundary_wall_cell_p_tb_corner_tap \
                           stdcell_tap_boundary_wall_cell_p_tb_tap \
                           stdcell_tap_boundary_wall_cell_p_tb_tap_wall \
                           stdcell_tap_boundary_wall_cell_p_tb_wall]
    foreach item $stdcellsList {
        lappend stdcellsTabContent [addOptionally $item]
    }
    # Manual Kpt Entries
    regsub -all {,\S+} [array names manualKpt] "" indicesList
    set indicesList [lsort -unique $indicesList]
    set validIndices [list]
    foreach index $indicesList {
        if {$manualKpt($index,valid) == true} {
            lappend validIndices $index
            checkMacroName $index manualKpt 1
        }
    }
    foreach index $validIndices {
        if {[info exists manualKpt($index,gds)] && $manualKpt($index,gds) != ""} {
            lappend stdcellsTabContent "stdcell_manual_kpt_$manualKpt($index,macro),$manualKpt($index,gds)"
        } else {
            regexp {(\.[^\.]+)(\.[^\.]+)} $manualKpt($index,gds,path) - notebook tabname
            $notebook select $notebook$tabname
            focus $manualKpt($index,gds,path)
            error "The entry for GDS for $manualKpt($index,macro) cannot be left empty!"
        }
    }
    return $stdcellsTabContent
}

proc saveTestcasesTab {} {
    global parameters paths testcases utilityTestcases
    set testcasesTabContent [list]
    # Testing Control Parameters
    lappend testcasesTabContent "\n#Testing Control Parameters"
    set controlList [list cell_substitution generate_cdl generate_lef \
                          tcoil_unit_width \
                          test_covercells test_macros uniquify_input_cdl \
                          uniquify_input_cdl_filter_file uniquify_input_gds \
                          uniquify_signal_pins]
    if {$parameters(uniquify_input_cdl) == 1} {
        if { ![info exists parameters(uniquify_input_cdl_filter_file)] \
              || $parameters(uniquify_input_cdl_filter_file) == ""} {
            regexp {(\.[^\.]+)(\.[^\.]+)} $paths(uniquify_input_cdl_filter_file) - notebook tabname
            $notebook select $notebook$tabname
            focus $paths(uniquify_input_cdl_filter_file)
            error "The entry for the CDL filter file cannot be left empty!"
        }
    }

    foreach item $controlList {
        lappend testcasesTabContent [addOptionally $item]
    }
    lappend testcasesTabContent [addIfNotEmpty output_layout_format]

    # Testcases Lists
    lappend testcasesTabContent "\n#Testcase Parameters"
    set testcasesTypes [list testcases_abutment testcases_abutment_stdcell \
                             testcases_abutment_wrapper testcases_wrapper \
                             testcases_stdcell testcases_pv_only \
                             testcases_stdcell_fill]
    foreach type $testcasesTypes {
        lappend testcasesTabContent "$type,[join [getTestcaseListSelection $type] " "]"
    }

    # Save the utility testcases
    set validIndices [list]
    foreach item [array names utilityTestcases "*,valid"] {
        if {$utilityTestcases($item)} {
            set index [regexp -inline {^\d+} $item]
            lappend validIndices $index
            checkTestcaseName $index "utilityTestcases"
        }
    }
    foreach index $validIndices {
        if {[info exists utilityTestcases($index,value)] && $utilityTestcases($index,value) != ""} {
            lappend testcasesTabContent "testcases_utility_$utilityTestcases($index,testcase),$utilityTestcases($index,mode):$utilityTestcases($index,value)"
        } else {
            regexp {(\.[^\.]+)(\.[^\.]+)} $utilityTestcases($index,value,path) - notebook tabname
            $notebook select $notebook$tabname
            focus $utilityTestcases($index,value,path)
            error "The entry for the value for $utilityTestcases($index,testcase) cannot be left empty!"
        }
    }
    return $testcasesTabContent
}

proc getTestcaseListSelection {listName} {
    global testcases paths
    set selection [$paths($listName) curselection]
    set selectedEntries [list]
    foreach item $selection {
        lappend selectedEntries [lindex $testcases($listName) $item]
    }
    return $selectedEntries
}

proc checkTestcaseName {index varName} {
    upvar #0 $varName itemsArray
    if {![info exists itemsArray($index,testcase)] || $itemsArray($index,testcase) == ""} {
        regexp {(\.[^\.]+)(\.[^\.]+)} $itemsArray($index,testcase,path) - notebook tabname
        $notebook select $notebook$tabname
        focus $itemsArray($index,testcase)
        error "The testcase name cannot be left empty!"
    }
}

proc savePvTab {} {
    global parameters
    set pvTabContent [list]
    # PV Parameters
    lappend pvTabContent "\n#PV Parameters"
    lappend pvTabContent [addOptionally msip_cd_pv_version]
    lappend pvTabContent [addIfNotEmpty grid]
    if {[info exists parameters(virtual_connect_icv,toggle)] \
          && $parameters(virtual_connect_icv,toggle)} {
        lappend pvTabContent [addIfNotEmpty virtual_connect_icv]
    } else {
        lappend pvTabContent [addCommented virtual_connect_icv]
    }
    if {[info exists parameters(virtual_connect_calibre,toggle)] \
          && $parameters(virtual_connect_calibre,toggle)} {
        lappend pvTabContent [addIfNotEmpty virtual_connect_calibre]
    } else {
        lappend pvTabContent [addCommented virtual_connect_calibre]
    }

    # DRC Parameters
    lappend pvTabContent "\n#DRC Parameters"
    if {!$parameters(drc)} {
        set parameters(drc_icv) 0
        set parameters(drc_calibre) 0
    }
    set drcList [list drc_icv drc_calibre drc_icv_grid_processes \
                      drc_icv_options_file drc_icv_runset \
                      drc_icv_unselect_rule_names drc_calex_extra_arguments \
                      drc_feol_fill drc_beol_fill drc_error_limit]
    foreach item $drcList {
        lappend pvTabContent [addOptionally $item]
    }
    if {$parameters(drc)} {
        lappend pvTabContent [addIfNotEmpty drc_prefix]
    } else {
        lappend pvTabContent [addCommented drc_prefix]
    }

    # LVS Parameters
    lappend pvTabContent "\n#LVS Parameters"
    if {!$parameters(lvs)} {
        set parameters(lvs_icv) 0
        set parameters(lvs_calibre) 0
    }
    set lvsList [list lvs_icv lvs_calibre lvs_icv_grid_processes \
                      lvs_calex_extra_arguments]
    foreach item $lvsList {
        lappend pvTabContent [addOptionally $item]
    }
    if {$parameters(lvs)} {
        lappend pvTabContent [addIfNotEmpty lvs_prefix]
    } else {
        lappend pvTabContent [addCommented lvs_prefix]
    }

    # PERCCNOD Parameters
    lappend pvTabContent "\n#PERCCNOD Parameters"
    if {!$parameters(perccnod)} {
        set parameters(perccnod_icv) 0
        set parameters(perccnod_calibre) 0
    }
    set perccnodList [list perccnod_icv perccnod_calibre \
                           perccnod_icv_grid_processes \
                           perccnod_calex_extra_arguments]
    foreach item $perccnodList {
        lappend pvTabContent [addOptionally $item]
    }
    if {$parameters(perccnod)} {
        lappend pvTabContent [addIfNotEmpty perccnod_prefix]
    } else {
        lappend pvTabContent [addCommented perccnod_prefix]
    }

    # PERCCD Parameters
    lappend pvTabContent "\n#PERCCD Parameters"
    if {!$parameters(perccd)} {
        set parameters(perccd_icv) 0
        set parameters(perccd_calibre) 0
    }
    set perccdList [list perccd_icv perccd_calibre perccd_icv_grid_hosts \
                         perccd_icv_grid_cores_per_host \
                         perccd_icv_grid_h_vmem \
                         perccd_calex_extra_arguments]
    foreach item $perccdList {
        lappend pvTabContent [addOptionally $item]
    }
    if {$parameters(perccd)} {
        lappend pvTabContent [addIfNotEmpty perccd_prefix]
    } else {
        lappend pvTabContent [addCommented perccd_prefix]
    }

    # PERCLDL Parameters
    lappend pvTabContent "\n#PERCLDL Parameters"
    if {!$parameters(percldl)} {
        set parameters(percldl_icv) 0
        set parameters(percldl_calibre) 0
    }
    set percldlList [list percldl_icv percldl_calibre \
                          percldl_icv_grid_processes \
                          percldl_calex_extra_arguments]
    foreach item $percldlList {
        lappend pvTabContent [addOptionally $item]
    }
    if {$parameters(percldl)} {
        lappend pvTabContent [addIfNotEmpty percldl_prefix]
    } else {
        lappend pvTabContent [addCommented percldl_prefix]
    }

    # PERCP2P Parameters
    lappend pvTabContent "\n#PERCP2P Parameters"
    if {!$parameters(percp2p)} {
        set parameters(percp2p_icv) 0
        set parameters(percp2p_calibre) 0
    }
    set percp2pList [list percp2p_icv percp2p_calibre percp2p_icv_grid_hosts \
                          percp2p_icv_grid_cores_per_host \
                          percp2p_icv_grid_h_vmem \
                          percp2p_calex_extra_arguments]
    foreach item $percp2pList {
        lappend pvTabContent [addOptionally $item]
    }
    if {$parameters(percp2p)} {
        lappend pvTabContent [addIfNotEmpty percp2p_prefix]
    } else {
        lappend pvTabContent [addCommented percp2p_prefix]
    }

    # PERCTOPO Parameters
    lappend pvTabContent "\n#PERCTOPO Parameters"
    if {!$parameters(perctopo)} {
        set parameters(perctopo_icv) 0
        set parameters(perctopo_calibre) 0
    }
    set perctopoList [list perctopo_icv perctopo_calibre \
                           perctopo_icv_grid_processes \
                           perctopo_calex_extra_arguments]
    foreach item $perctopoList {
        lappend pvTabContent [addOptionally $item]
    }
    if {$parameters(perctopo)} {
        lappend pvTabContent [addIfNotEmpty perctopo_prefix]
    } else {
        lappend pvTabContent [addCommented perctopo_prefix]
    }

    # PERCTOPOLA Parameters
    lappend pvTabContent "\n#PERCTOPOLA Parameters"
    if {!$parameters(perctopola)} {
        set parameters(perctopola_icv) 0
        set parameters(perctopola_calibre) 0
    }
    set perctopolaList [list perctopola_icv perctopola_calibre \
                             perctopola_icv_grid_processes \
                             perctopola_calex_extra_arguments]
    foreach item $perctopolaList {
        lappend pvTabContent [addOptionally $item]
    }
    if {$parameters(perctopola)} {
        lappend pvTabContent [addIfNotEmpty perctopola_prefix]
    } else {
        lappend pvTabContent [addCommented perctopola_prefix]
    }

    return $pvTabContent
}

# If the item doesn't exists, add it as an empty entry
proc addOptionally {item} {
    global parameters
    if {[info exists parameters($item)] && $parameters($item) != ""} {
        return "$item,$parameters($item)"
    } else {
        return "$item,"
    }
}

# If the item doesn't exist, add it as a commented entry
proc addCommented {item} {
    global parameters
    if {[info exists parameters($item)] && $parameters($item) != ""} {
        return "$item,$parameters($item)"
    } else {
        return "#$item,"
    }
}

proc loadParameters {} {
    global parameters paths
    # Dialog to ask whether to clear the entries or append to it when loading the file.
    set reply [tk_dialog .ask "Append or Clear" "Append to the existing entries or clear all entries?" \
                         questhead 0 Append Clear]
    # Get the file path
    set filePath [tk_getOpenFile]
    if {$filePath == ""} { return }

    # Read the file
    set lines [split [read_file $filePath] "\n"]

    # Specifiy different entry types criteria
    set simpleEntries [list project_type project_name release_name \
                            metal_stack boundary_layer dbu \
                            icc2_gds_layer_map icc2_techfile tap_distance \
                            generate_boundary generated_boundary_upsize_b \
                            generated_boundary_upsize_l \
                            generated_boundary_upsize_r \
                            generated_boundary_upsize_t \
                            covercell_text_layers macro_text_layers \
                            boundary_bottom \
                            boundary_bottom_left_inside_corner \
                            boundary_bottom_left_inside_horizontal_abutment \
                            boundary_bottom_left_outside_corner \
                            boundary_bottom_right_inside_corner \
                            boundary_bottom_right_inside_horizontal_abutment \
                            boundary_bottom_right_outside_corner \
                            boundary_left boundary_right boundary_top \
                            boundary_top_left_inside_corner \
                            boundary_top_left_outside_corner \
                            boundary_top_right_inside_corner \
                            boundary_top_right_outside_corner \
                            stdcell_drive_strength \
                            stdcell_gds stdcell_inner_kpt_b \
                            stdcell_inner_kpt_l stdcell_inner_kpt_r \
                            stdcell_inner_kpt_t stdcell_kpt_b \
                            stdcell_kpt_l stdcell_kpt_r stdcell_kpt_t \
                            stdcell_ndm stdcell_tap \
                            stdcell_tap_boundary_wall_cell_n_fill_wall \
                            stdcell_tap_boundary_wall_cell_n_fill_wall_replacement \
                            stdcell_tap_boundary_wall_cell_n_inner_corner_boundary \
                            stdcell_tap_boundary_wall_cell_n_left_tap \
                            stdcell_tap_boundary_wall_cell_n_right_tap \
                            stdcell_tap_boundary_wall_cell_n_ntap_inner_corner_boundary \
                            stdcell_tap_boundary_wall_cell_n_ptap_inner_corner_boundary \
                            stdcell_tap_boundary_wall_cell_n_tap \
                            stdcell_tap_boundary_wall_cell_n_tap_wall \
                            stdcell_tap_boundary_wall_cell_n_tb_boundary \
                            stdcell_tap_boundary_wall_cell_n_tb_corner_boundary \
                            stdcell_tap_boundary_wall_cell_n_tb_corner_tap \
                            stdcell_tap_boundary_wall_cell_n_tb_tap \
                            stdcell_tap_boundary_wall_cell_n_tb_tap_wall \
                            stdcell_tap_boundary_wall_cell_n_tb_wall \
                            stdcell_tap_boundary_wall_cell_p_fill_wall \
                            stdcell_tap_boundary_wall_cell_p_fill_wall_replacement \
                            stdcell_tap_boundary_wall_cell_p_inner_corner_boundary \
                            stdcell_tap_boundary_wall_cell_p_left_tap \
                            stdcell_tap_boundary_wall_cell_p_right_tap \
                            stdcell_tap_boundary_wall_cell_p_ntap_inner_corner_boundary \
                            stdcell_tap_boundary_wall_cell_p_ptap_inner_corner_boundary \
                            stdcell_tap_boundary_wall_cell_p_tap \
                            stdcell_tap_boundary_wall_cell_p_tap_wall \
                            stdcell_tap_boundary_wall_cell_p_tb_boundary \
                            stdcell_tap_boundary_wall_cell_p_tb_corner_boundary \
                            stdcell_tap_boundary_wall_cell_p_tb_corner_tap \
                            stdcell_tap_boundary_wall_cell_p_tb_tap \
                            stdcell_tap_boundary_wall_cell_p_tb_tap_wall \
                            stdcell_tap_boundary_wall_cell_p_tb_wall \
                            cell_substitution generate_cdl generate_lef \
                            output_layout_format tcoil_unit_width \
                            test_covercells test_macros uniquify_input_cdl \
                            uniquify_input_cdl_filter_file \
                            uniquify_input_gds uniquify_signal_pins \
                            msip_cd_pv_version grid virtual_connect_icv \
                            virtual_connect_calibre \
                            drc_icv drc_calibre drc_icv_grid_processes \
                            drc_icv_options_file drc_icv_runset \
                            drc_icv_unselect_rule_names \
                            drc_calex_extra_arguments drc_prefix \
                            drc_feol_fill drc_beol_fill drc_error_limit \
                            lvs_icv lvs_calibre lvs_icv_grid_processes \
                            lvs_calex_extra_arguments lvs_prefix \
                            perccnod_icv perccnod_calibre \
                            perccnod_icv_grid_processes \
                            perccnod_calex_extra_arguments \
                            perccnod_prefix perccd_icv perccd_calibre \
                            perccd_icv_grid_hosts \
                            perccd_icv_grid_cores_per_host \
                            perccd_icv_grid_h_vmem \
                            perccd_calex_extra_arguments perccd_prefix \
                            percldl_icv percldl_calibre \
                            percldl_icv_grid_processes \
                            percldl_calex_extra_arguments percldl_prefix \
                            percp2p_icv percp2p_calibre \
                            percp2p_icv_grid_hosts \
                            percp2p_icv_grid_cores_per_host \
                            percp2p_icv_grid_h_vmem \
                            percp2p_calex_extra_arguments \
                            percp2p_prefix perctopo_icv perctopo_calibre \
                            perctopo_icv_grid_processes \
                            perctopo_calex_extra_arguments \
                            perctopo_prefix perctopola_icv \
                            perctopola_calibre \
                            perctopola_icv_grid_processes \
                            perctopola_calex_extra_arguments \
                            perctopola_prefix]

    # Clear all of the entires as per the user's choice
    if {$reply == 1} {
        clearEntries $simpleEntries
    }
    # Itemized Entries Regex
    set itemizedRegex "^cdl_|^def_|^gds_|^lef_|^stdcell_manual_kpt_"
    set itemizedEntries [list]

    # Testcases Entries
    set testcasesTypes [list testcases_abutment testcases_abutment_stdcell \
                             testcases_abutment_wrapper testcases_pv_only \
                             testcases_stdcell testcases_stdcell_fill \
                             testcases_wrapper]
    set itemizedTestcasesRegex "^testcases_utility_"
    set itemizedTestcasesEntries [list]
    set testcasesEntries [dict create]

    # Parse the file
    foreach line $lines {
        # Skip blank and commented lines
        if {[regexp {^\s*$|^#} $line]} {continue}

        lassign [split $line ","] entryName entryValue
        if {[lsearch $simpleEntries $entryName] != -1} {
            if {  [regexp {(^[^_]*)_icv$|(^[^_]*)_calibre$} $entryName - verif] \
                  && $entryValue == ""} {
                set entryValue 0
            }
            set parameters($entryName) $entryValue
            # If a verif is set to run, toggle the whole verif section
            if {  [regexp {(^[^_]*)_icv$|(^[^_]*)_calibre$} $entryName - verif] \
                  && $entryValue == 1 && $parameters($verif) == 0} {
                $paths($verif) invoke
            }
        } elseif {[regexp $itemizedRegex $entryName]} {
            lappend itemizedEntries [list $entryName $entryValue]
        } elseif {[lsearch $testcasesTypes $entryName] != -1} {
            dict set testcasesEntries $entryName $entryValue
        } elseif {[regexp $itemizedTestcasesRegex $entryName]} {
            lappend itemizedTestcasesEntries [list $entryName $entryValue]
        }
    }
    addItemizedEntries $itemizedEntries
    updateTestcasesListboxes
    foreach testcase [dict keys $testcasesEntries] {
        parseTestcasesEntry $testcase [dict get $testcasesEntries $testcase]
    }
    addItemizedTestcasesEntries $itemizedTestcasesEntries
    updateProjectTypeList
}

proc addItemizedEntries {entriesList} {
    set manualKptIndex [getLastIndex manualKpt]
    set covercellsIndex [getLastIndex coercells]

    set macrosDict [dict create]

    foreach item $entriesList {
        lassign $item entryName value
        if {[regexp {^stdcell_manual_kpt_(.*)} $entryName - name]} {
            addManualKptItem $name $value "manualKptIndex"
        } elseif {[regexp {^gds_dwc_ddrphycover_(.*)} $entryName - name]} {
            addCovercellsItem $name $value "covercellsIndex"
        } else {
            regexp {([^_]+)_(.*)} $entryName - fileType macroName
            dict set macrosDict $macroName $fileType $value
        }
    }
    addMacroEntries $macrosDict
}

proc addManualKptItem {name value varName} {
    global paths manualKpt
    upvar 1 $varName index
    incr index

    # Add a new item
    $paths(manualKpt) invoke
    set manualKpt($index,macro) $name
    set manualKpt($index,gds) $value
}

proc addCovercellsItem {name value varName} {
    global paths covercells
    upvar 1 $varName index
    incr index

    # Add a new item
    $paths(covercells) invoke
    set covercells($index,macro) $name
    set covercells($index,gds) $value
}

proc addMacroEntries {macroDict} {
    global paths macros
    
    set index [getLastIndex macros]
    dict for {macro entries} $macroDict {
        incr index
        $paths(macros) invoke
        set macros($index,macro) $macro
        dict for {type value} $entries {
            $macros($index,$type,path,toggle) invoke
            set macros($index,$type) $value
        }
    }
}

proc getLastIndex {arrayName} {
    upvar #0 $arrayName arr
    set itemsList [array names arr "*,valid"]
    if {$itemsList == ""} {
        return 0
    } else {
        set indiciesList [regexp -all -inline -- {\d+} $itemsList]
        return [lindex [lsort $indiciesList] end]
    }
}

proc parseTestcasesEntry {name value} {
    global paths testcases

    # Get index of the items read from the file and select them
    foreach item $value {
        set index [lsearch $testcases($name) $item]
        if {$index != -1 } {
            $paths($name) selection set $index $index
        }
    }
}

proc addItemizedTestcasesEntries {entriesList} {
    global paths utilityTestcases
    # Add a new item
    set index [getLastIndex utilityTestcases]
    incr index
    foreach item $entriesList {
        lassign $item fullName combinedValue
        regexp {^testcases_utility_(.*)} $fullName - name
        lassign [split $combinedValue ":"] mode value
        if {[regexp {^full$|^block_ew$} $mode]} {
            $paths(utilityTestcases) invoke
            set utilityTestcases($index,testcase) $name
            set utilityTestcases($index,mode) $mode
            set utilityTestcases($index,value) $value
            incr index
        }
    }
}

proc clearEntries {simpleEntries} {
    global parameters paths
    global macros covercells manualKpt utilityTestcases

    # Clear all entries
    # The checkboxes would be put in a tristate
    foreach item $simpleEntries {
        set parameters($item) ""
    }
    updateProjectTypeList

    # Clear the testcases selection
    set testcasesLists [list testcases_abutment_wrapper testcases_wrapper \
                             testcases_stdcell testcases_pv_only testcases_stdcell_fill]
    foreach type $testcasesLists {
        $paths($type) selection clear 0 end
    }

    # Invoke the remove button for all of the itemized entries
    set itemizedEntries [list macros covercells manualKpt utilityTestcases]
    foreach arrayName $itemizedEntries {
        upvar 0 $arrayName arr
        foreach item [array names arr "*,remove,path"] {
            $arr($item) invoke
        }
    }
}

main




# nolint Main
