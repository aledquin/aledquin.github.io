#!/depot/tcl8.6.3/bin/tclsh8.6
#nolint Main
#nolint utils__script_usage_statistics
package provide DA_widgets 1.0
package require Tk
namespace eval ::DA_widgets {
    namespace export *

    variable entrySettings
    set entrySettings [join [list "-background white " \
                                  "-disabledbackground lightgrey" \
                                  "-disabledforeground darkgrey"]]
}

proc ::DA_widgets::scrollFrame {outerF} {
    # Create the canvas embeded in the outer frame
    set innerCanvas [canvas $outerF.canvas -xscrollcommand "$outerF.xScroll set" \
                                           -yscrollcommand "$outerF.yScroll set" \
                                           -borderwidth 0 \
                                           -relief flat \
                                           -highlightthickness 0]

    # Create the scrollbars and connect them to the canvas
    set xScroll [ttk::scrollbar $outerF.xScroll -command "$innerCanvas xview" \
                                                -orient horizontal]
    set yScroll [ttk::scrollbar $outerF.yScroll -command "$innerCanvas yview" \
                                                -orient vertical]

    # Pack the scrollbars and the canvas
    pack $xScroll -side bottom -fill x
    pack $yScroll -side right  -fill y
    pack $innerCanvas -side top -fill y -expand yes

    # Create the inner frame and attach it to the canvas as a window
    set innerF [frame $innerCanvas.innerF -bg black]
    set windowID [$innerCanvas create window 0 0 -anchor nw -window $innerF]

    # Add/remove the scroll bars whenever a change in gemoetry occurs
    bind $innerF <Configure> [namespace code [list scrollFrameResizeFrame %W]]
    bind $innerCanvas <Configure> [namespace code [list scrollFrameResizeCanvas %W %w %h]]

    # Scroll up/down according to the mousewheel movment
    bind $outerF <Button-4> {%W.canvas yview scroll -3 units}
    bind $outerF <Button-5> {%W.canvas yview scroll 3 units}
    return $innerF
}

proc ::DA_widgets::scrollFrameResizeCanvas {path eventWidth eventHeight} {
    # Get the outer frame path to control the scroll widgets
    set outerF [regsub {\.[^\.]+$} $path ""]
    # Compare the new width with the inner frame requested width and add/remove
    # the scrollbar accordingly
    if {[winfo reqwidth $path.innerF] > $eventWidth} {
        pack $outerF.xScroll -side bottom -fill x
    } else {
        pack forget $outerF.xScroll
    }
    # Do something similiar for the height
    if {[winfo reqheight $path.innerF] > $eventHeight} {
        pack $outerF.yScroll -fill y -side right -before $path
    } else {
        pack forget $outerF.yScroll
    }
    return
}

proc ::DA_widgets::scrollFrameResizeFrame {path} {
    # If the inner frame size changes update the scroll area
    set canvasPath [regsub {\.[^\.]+$} $path ""]
    $canvasPath configure -scrollregion [$canvasPath bbox all]
    $canvasPath configure -width [winfo reqwidth $path]
    # Also check if the status of the scrollbars
    event generate $canvasPath <Configure>
    return
}

proc ::DA_widgets::checkFrame {outerF {args ""}} {
    # Parse the args
    while {[llength $args]} {
        switch -- [lindex $args 0] {
            "-text"     {set args [lassign $args - toggleText]}
            "-variable" {set args [lassign $args - varName]}
            "-collapsible" {set collapseFlag 1; set args [lrange $args 1 end]}
            "-inline"   {set inlineFlag 1; set args [lrange $args 1 end]}
            default     {error "Uknown option [lindex $args 0]"}
        }
    }
    # The text and variable arguments must exist
    if {![info exists toggleText]} {error "Missing option -text"}
    if {![info exists varName]}    {error "Missing option -variable"}
    if {[info exists collapseFlag] && [info exists inlineFlag]} {
        error "The checkFrame cannot be inline and collapsable."
    }
    # Create the inner frame that holds the inner widgets
    set innerF [frame $outerF.innerF]
    if {[info exists inlineFlag]} {
        grid $innerF -column 1 -row 0 -sticky news
    } else {
        grid $innerF -column 0 -row 1 -columnspan 3 -sticky news
    }
    # Add the check button
    set checkB [checkbutton $outerF.checkB \
                            -text "$toggleText" \
                            -variable $varName \
                            -command [namespace code [list toggleFrame $outerF]] \
                            -borderwidth 0 \
                            -relief flat \
                            -highlightthickness 0]
    grid $checkB -column 0 -row 0
    # Add the collapse button
    if {[info exists collapseFlag]} {
        set collapseB [button $outerF.collapseB \
                              -text "-" \
                              -textvariable $outerF.collapseB \
                              -command [namespace code [list collapseFrame $outerF]] \
                              -borderwidth 0 \
                              -relief flat \
                              -highlightthickness 0]
        grid $collapseB -column 2 -row 0
    }
    # The inner frame should take-up the extra space
    grid columnconfigure $outerF {1} -weight 1

    return $innerF
}

proc ::DA_widgets::toggleFrame {framePath} {
    # Get the updated check button status
    upvar #0 [$framePath.checkB cget -variable] status
    # Update the outer frame children status recursively
    updateChildrenState $framePath.innerF $status
}

proc ::DA_widgets::updateChildrenState {widget status} {
    # If this is an entry/checkbutton/combobox update its status
    if {[regexp {Entry|Checkbutton|TCombobox} [winfo class $widget]]} {
        if {$status} {
            $widget configure -state normal
        } else {
            $widget configure -state disabled
        }
    # If this is a frame, check its children.
    } elseif {[regexp {Frame} [winfo class $widget]]} {
        # If the frame is a checkFrame, the status of its children should depend
        # on the status of its checkbox too.
        if {[winfo exists $widget.checkB] && [winfo exists $widget.innerF]} {
            updateChildrenState $widget.checkB $status
            upvar #0 [$widget.checkB cget -variable] frameStatus
            # Check if the frame is in tristate after clear with an empty status
            if {$frameStatus == ""} {
                set frameStatus 0
            }
            set status [expr {$status && $frameStatus}]
            set widget $widget.innerF
            foreach child [winfo children $widget] {
                updateChildrenState $child $status
            }
        } else {
            foreach child [winfo children $widget] {
                updateChildrenState $child $status
            }
        }
    }
}

proc ::DA_widgets::collapseFrame {framePath} {
    upvar #0 [$framePath.collapseB cget -textvariable] status
    if {$status == "-"} {
        set status "+"
        grid forget $framePath.innerF
    } else {
        set status "-"
        grid $framePath.innerF -column 0 -row 1 -columnspan 3 -sticky news
    }
}

proc ::DA_widgets::fileEntry {framePath {args ""}} {
    set checkFlag 0
    # Parse the args
    while {[llength $args]} {
        switch -- [lindex $args 0] {
            "-text"           {set args [lassign $args - labelText]}
            "-variable"       {set args [lassign $args - varName]}
            "-mode"           {set args [lassign $args - mode]}
            "-width"           {set args [lassign $args - width]}
            "-checkable"      {set checkFlag 1; set args [lrange $args 1 end]}
            "-checkVariable"  {set args [lassign $args - checkVarName]}
            default           {error "Uknown option [lindex $args 0]"}
        }
    }
    # The text and variable arguments must exist
    if {![info exists labelText]}  {error "Missing option -text"}
    if {![info exists varName]}    {error "Missing option -variable"}
    if {![info exists mode]} {
        set mode "open"
    } elseif {![regexp {open|save} $mode]} {
        error "Illegal mode: '$mode'; shoud be open or save."
    }
    if {![info exists width]} {set width 20}
    variable entrySettings


    # Choose which proc to invoke when pressing the browse button.
    if {$mode == "open"} {
        set cmd [namespace code [list openFileSelector $varName]]
    } else {
        set cmd [namespace code [list saveFileSelector $varName]]
    }
    # Create the frame, label, and entry widgets
    frame $framePath
    if {$checkFlag == 1} {
        if {![info exists checkVarName]} {set checkVarName $framePath.checkB}
        set innerF [::DA_widgets::checkFrame $framePath \
                                             -text $labelText \
                                             -variable $checkVarName \
                                             -inline]
        entry $innerF.fileE \
              -textvariable $varName \
              -width $width \
              {*}$entrySettings
        grid $innerF.fileE -column 0 -row 0
        # Add the browse button
        button $innerF.selectB -text "Browse" -command $cmd
        grid $innerF.selectB -column 1 -row 0
    } else {
        label $framePath.fileL -text $labelText
        grid $framePath.fileL -column 0 -row 0
        entry $framePath.fileE \
              -textvariable $varName \
              -width $width \
              {*}$entrySettings
        grid $framePath.fileE -column 1 -row 0
        # Add the browse button
        button $framePath.selectB -text "Browse" -command $cmd
        grid $framePath.selectB -column 2 -row 0
    }

    #grid columnconfigure $framePath {0} -weight 1

    return $framePath
}

proc ::DA_widgets::openFileSelector {varName} {
    upvar #0 $varName filePath
    set filePath [tk_getOpenFile]
}

proc ::DA_widgets::saveFileSelector {varName} {
    upvar #0 $varName filePath
    set filePath [tk_getSaveFile]
}

proc ::DA_widgets::directoryEntry {framePath {args ""}} {
    # Parse the args
    while {[llength $args]} {
        switch -- [lindex $args 0] {
            "-text"     {set args [lassign $args - labelText]}
            "-variable" {set args [lassign $args - varName]}
            "-collapseable" {set collapseFlag 1; set args [lrange $args 1 end]}
            "-width"           {set args [lassign $args - width]}
            default     {error "Uknown option [lindex $args 0]"}
        }
    }
    # The text and variable arguments must exist
    if {![info exists labelText]}  {error "Missing option -text"}
    if {![info exists varName]}    {error "Missing option -variable"}
    if {![info exists width]} {set width 20}
    upvar #0 $varName filePath
    variable entrySettings

    # Create the frame, label, and entry widgets
    frame $framePath
    label $framePath.directoryL -text $labelText
    grid $framePath.directoryL -column 0 -row 0
    entry $framePath.directoryE \
          -textvariable $varName \
          -width $width \
          {*}$entrySettings
    grid $framePath.directoryE -column 1 -row 0

    # Add the browse button
    set cmd [namespace code [list directorySelector $varName]]
    button $framePath.selectB -text "browse" -command $cmd
    grid $framePath.selectB -column 2 -row 0

    grid columnconfigure $framePath {0} -weight 1

    return $framePath
}

proc ::DA_widgets::directorySelector {varName} {
    upvar #0 $varName filePath
    set filePath [tk_chooseDirectory]
}

proc ::DA_widgets::itemsFrame {outerF {args ""}} {
    set collapseFlag 0
    # Parse the args
    while {[llength $args]} {
        switch -- [lindex $args 0] {
            "-command"  {set args [lassign $args - itemConstructorProc]}
            "-variable" {set args [lassign $args - itemsArrayName]}
            "-collapsible" {set collapseFlag 1; set args [lrange $args 1 end]}
            default     {error "Uknown option [lindex $args 0]"}
        }
    }
    # The command and variable arguments must exist
    if {![info exists itemConstructorProc]} {error "Missing option -command"}
    if {![info exists itemsArrayName]}      {error "Missing option -variable"}
    set cmd [namespace code [list addItem $outerF $itemConstructorProc $itemsArrayName $collapseFlag]]
    set addB [button $outerF.addB -text "Add" -command $cmd]
    pack $addB -anchor se
}

proc ::DA_widgets::addItem {outerF itemConstructorProc itemsArrayName collapseFlag} {
    # Get the global array
    upvar #0 $itemsArrayName itemsArray
    # Get the last index, if the array is empty start at 1
    regsub -all {,\S+} [array names itemsArray] "" arrayIndcies
    if {[llength $arrayIndcies] == 0} {
        set index 1
    } else {
        set index [expr {[lindex [lsort -integer -unique $arrayIndcies] end] + 1}]
    }
    # Set the valid flag for the item to true
    set itemsArray($index,valid) true
    # Create the item's outer frame and place it at the end
    set itemOuterF [frame $outerF.item$index]
    pack $itemOuterF -before $outerF.addB -fill x
    # Add the remove button
    set rmCmd [namespace code [list removeItem $itemOuterF $itemsArrayName $index]]
    set removeB   [button $itemOuterF.removeB \
                          -text "x" \
                          -command $rmCmd \
                          -borderwidth 0 \
                          -relief flat \
                          -highlightthickness 0]
    grid $removeB -sticky ne -row 0 -column 2
    # Add the collapse button if collapsable
    if {$collapseFlag == 1} {
        set collapseCmd [namespace code [list collapseItem $itemOuterF $itemsArrayName $index]]
        set collapseB [button $itemOuterF.collapseB \
                              -text "-" \
                              -textvariable "${itemsArrayName}($index,collapse)" \
                              -command $collapseCmd \
                              -borderwidth 0 \
                              -relief flat \
                              -highlightthickness 0]
        grid $collapseB -sticky nw -row 0 -column 0
        label $itemOuterF.collapseL -textvariable "${itemsArrayName}($index,collapseLabel)"
    }

    # Construct the frame inside the item's outer frame
    set itemF [$itemConstructorProc $itemOuterF.itemF $itemsArrayName $index]
    grid $itemF -sticky news -row 1 -column 0 -columnspan 3 
    # The item's inner frame should take-up the extra space.
    grid columnconfigure $itemOuterF {1} -weight 1

    return $itemOuterF
}

proc ::DA_widgets::removeItem {itemOuterF itemsArrayName index} {
    upvar #0 $itemsArrayName itemsArray

    # Forget and invalidate
    pack forget $itemOuterF
    set itemsArray($index,valid) false
}

proc ::DA_widgets::collapseItem {framePath itemsArrayName index} {
    upvar #0 $itemsArrayName itemsArray
    upvar #0 ${itemsArrayName}($index,collapse) status
    if {$status == "-"} {
        set status "+"
        grid forget $framePath.itemF
        grid forget $framePath.removeB
        upvar #0 $itemsArray($index,collapseLabelVar) labelValue
        set itemsArray($index,collapseLabel) $labelValue
        grid $framePath.collapseL -column 1 -row 0 -sticky news
    } else {
        set status "-"
        grid forget $framePath.collapseL
        grid $framePath.removeB -column 2 -row 0 -sticky nw
        grid $framePath.itemF -column 0 -row 1 -columnspan 3 -sticky news
    }
}

proc ::DA_widgets::multiSelectList {outerF {args ""}} {
    # Parse the args
    while {[llength $args]} {
        switch -- [lindex $args 0] {
            "-variable"  {set args [lassign $args - varName]}
            "-width"     {set args [lassign $args - width]}
            "-height"    {set args [lassign $args - height]}
            default      {error "Uknown option [lindex $args 0]"}
        }
    }
    # The variable arguments must exist
    if {![info exists varName]}    {error "Missing option -variable"}
    if {![info exists width]} {set width 10}
    if {![info exists height]} {set height 40}

    # Create the searchbox
    set listF [frame $outerF.listF]
    set lb [listbox $listF.listLB \
                    -listvariable $varName \
                    -selectmode extended \
                    -exportselection 0 \
                    -yscrollcommand "$listF.yScroll set" \
                    -xscrollcommand "$listF.xScroll set" \
                    -width $width \
                    -height $height \
                    -selectbackground blue \
                    -selectforeground white] 
    set yS [scrollbar $listF.yScroll -orient vertical -command "$lb yview"]
    set xS [scrollbar $listF.xScroll -orient horizontal -command "$lb xview"]
    pack $yS -side right -fill y
    pack $lb
    pack $xS -side bottom -fill x
    grid $listF -row 0 -column 0 -columnspan 2

    set clearCmd "$lb selection clear 0 end"
    set selectAllCmd "$lb selection set 0 end"
    set clearB [button $outerF.clearB -text "Clear" -command $clearCmd]
    set selectAllB [button $outerF.selectAllB -text "Select All" -command $selectAllCmd]
    grid $clearB -row 1 -column 0
    grid $selectAllB -row 1 -column 1

    return $outerF
}

proc ::DA_widgets::searchListbox {outerF {args ""}} {
    # Parse the args
    while {[llength $args]} {
        switch -- [lindex $args 0] {
            "-valuesvariable" {set args [lassign $args - valuesVarName]}
            "-selectvariable" {set args [lassign $args - selectVarName]}
            "-width"          {set args [lassign $args - width]}
            "-height"         {set args [lassign $args - height]}
            "-selectmode"     {set args [lassign $args - selectmode]}
            default           {error "Uknown option [lindex $args 0]"}
        }
    }
    # The variable arguments must exist
    if {![info exists valuesVarName]} {error "Missing option -valuevariable"}
    if {![info exists selectVarName]} {error "Missing option -selectvariable"}
    if {![info exists width]}         {set width 10}
    if {![info exists height]}        {set height 10}
    if {![info exists selectmode]}    {set selectmode browse}

    # Create the searchbox
    entry $outerF.searchE \
          -width [expr {$width+2}] \
          -background white
    bind $outerF.searchE <KeyRelease> [namespace code [list searchList %W $selectVarName]]
    grid $outerF.searchE -row 0 -column 0
    # Create the shown listbox whose items can be a filtered set from the complete
    # list
    set listF [frame $outerF.listF]
    set lb [listbox $listF.listLB \
                    -listvariable ${valuesVarName}_shown \
                    -selectmode $selectmode \
                    -exportselection 0 \
                    -yscrollcommand "$listF.yScroll set" \
                    -xscrollcommand "$listF.xScroll set" \
                    -width $width \
                    -height $height \
                    -selectbackground blue \
                    -selectforeground white] 
    set yS [scrollbar $listF.yScroll -orient vertical -command "$lb yview"]
    set xS [scrollbar $listF.xScroll -orient horizontal -command "$lb xview"]
    pack $yS -side right -fill y
    pack $lb
    pack $xS -side bottom -fill x
    grid $listF -row 1 -column 0
    # Create the hidden listbox that contains the complete values and selection
    # lists.
    set hlb [listbox $outerF.l \
                     -listvariable $valuesVarName \
                     -selectmode $selectmode \
                     -exportselection 0 \
                     -width $width \
                     -height $height \
                     -selectbackground blue \
                     -selectforeground white]
    # Add a trace to the hidddn list values variable, so that when it changes,
    # the selection and the shown list are updated as well.
    upvar #0 ${valuesVarName}_shown shownVar
    upvar #0 $valuesVarName hiddenVar
    upvar #0 $selectVarName selectVar
    set shownVar $hiddenVar
    trace add variable hiddenVar write [namespace code [list searchList $outerF.searchE $selectVarName]]
    # Bind the selection of the shown list to update the selection of the hidden list
    bind $lb <<ListboxSelect>> [namespace code [list updateSelection %W $selectVarName]]
    return $outerF
}

proc ::DA_widgets::searchList {path selectVarName {args ""}} {
    set searchEntry [$path get]
    # Get the path for both listboxes and their variables
    regsub {[^\.]+$} $path "l" hiddenLB
    # Update the hiddenList selection
    set hiddenVarName [$hiddenLB cget -listvariable]
    upvar #0 $hiddenVarName hiddenVar
    regsub {[^\.]+$} $path "listF.listLB" shownLB
    set shownVarName [$shownLB cget -listvariable]
    upvar #0 $shownVarName shownVar
    # Update the hidden listbox selection
    upvar #0 $selectVarName selected
    $hiddenLB selection clear 0 end
    set newSelected [list]
    foreach item $selected {
        if {[set index [lsearch $hiddenVar $item]] > -1} {
            $hiddenLB selection set $index $index
            lappend newSelected $item
        }
    }
    set selected $newSelected
    # Clear the shown listbox selection
    $shownLB selection clear 0 end
    # Update the shown listbox values according to the search entry
    set shownVar [lsearch -all -inline $hiddenVar "*$searchEntry*"]
    # Update the shown listbox selection
    foreach item $selected {
        if {[set index [lsearch $shownVar $item]] > -1} {
            $shownLB selection set $index $index
        }
    }
    return true
}

proc ::DA_widgets::updateSelection {shownLB selectVarName} {
    upvar #0 $selectVarName selected
    # Get the path for hidden listbox
    regsub {[^\.]+\.[^\.]+$} $shownLB "l" hiddenLB
    # Get the variables for both listboxes
    set hiddenVarName [$hiddenLB cget -listvariable]
    upvar #0 $hiddenVarName hiddenVar
    set shownList [$shownLB get 0 end]
    # Clear the hidden list selection for single/browse modes
    set selectionMode [$shownLB cget -selectmode]
    if {[regexp {single|browse} $selectionMode]} {
        $hiddenLB selection clear 0 end
    }
    # Get the selected and unselected entries
    set selectedIndices [lsort -decreasing [$shownLB curselection]]
    set selectedEntries [list]
    foreach index $selectedIndices {
        lappend selectedEntries [lindex $shownList $index]
        set shownList [lreplace $shownList $index $index]
    }
    # Update the hidden listbox selection
    foreach item $selectedEntries {
        set index [lsearch $hiddenVar $item]
        $hiddenLB selection set $index $index
    }
    foreach item $shownList {
        set index [lsearch $hiddenVar $item]
        $hiddenLB selection clear $index $index
    }
    #Update the value of the selected variable
    set selectedIndices [$hiddenLB curselection]
    set selected [list]
    foreach index $selectedIndices {
        lappend selected [lindex $hiddenVar $index]
    }
}


# nolint Line  43: E Strange command 
# nolint Line  44: E Strange command 
# nolint Line 103: N Suspicious varia
# nolint Line 113: N Suspicious varia
# nolint Line 217: N Suspicious varia
# nolint Line 228: N Suspicious varia
# nolint Line 275: N Suspicious varia
# nolint Line 349: N Suspicious varia
# nolint Line 343: N Suspicious varia
# nolint Line 399: N Suspicious varia
