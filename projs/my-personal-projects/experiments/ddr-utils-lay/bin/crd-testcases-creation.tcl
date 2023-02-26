namespace eval cc_crd_abutment {

    variable scriptDir [file dirname [info script]]

    proc invoke_floorplan {scriptDir {floorplan_file "crd_abutment_floorplans.tcl"}} {
        variable $scriptDir
        return [source [file join $scriptDir $floorplan_file]]
    }

    proc check_cells_libs {macros} {
        foreach macro $macros {
            if {[array names libraries -exact $macro] == ""} {
                de::sendMessage "No reference library found for $macro. Exiting." -severity error
                return -level [info level] 1
            }
        }
    }

    proc get_macros_from_testcases {testcases} {
        foreach testcase $testcases {
            variable floorplans
            foreach {macro columns rows d_x d_y x y angle mirror} $floorplans($testcase) {
                lappend macros $macro
            }
        }
        return $macros
    }

    proc check_lib_layoutview {macros reflibs} {
        set macros [lsort -unique $macros]
        foreach macro $macros {
            foreach lib $reflibs {
                # First check that cell exists in lib, then check if layout view exists.
                if {![db::isEmpty  [dm::getCells $macro -libName $lib]] && ![db::isEmpty [dm::getCellViews layout -cellName $macro -libName $lib]]} {
                    variable libraries($macro) $lib
                    break
                }
            }
        }
    }

    proc get_macro_sizes {macros} {
        foreach macro $macros {
            variable libraries
            set context [de::open [dm::getCellViews layout -cellName $macro -libName $libraries($macro)] -readOnly true -headless true]
            set design [db::getAttr editDesign -of $context]
            set block [oa::getTopBlock $design]
            set boundary [oa::PRBoundaryFind $block]
            #set widths($macro) [lindex [db::getAttr bBox -of $boundary] 1 0]
            variable x_$macro [lindex [db::getAttr bBox -of $boundary] 1 0]
            #set heights($macro) [lindex [db::getAttr bBox -of $boundary] 1 1]
            variable y_$macro [lindex [db::getAttr bBox -of $boundary] 1 1]
            de::close $context
        }
    }

    proc generate_testcases {testcases destlib} {
        foreach testcase $testcases {
            variable floorplans
            set cell [dm::createCell $testcase -libName $destlib]
            set cellView [dm::createCellView layout -cell $cell -viewType maskLayout]
            set context [de::open [dm::getCellViews layout -cellName $testcase -libName $destlib] -headless true]
            set design [db::getAttr editDesign -of $context]

            foreach {macro columns rows dx dy x y angle mirror} $floorplans($testcase) {
                switch -- "$angle $mirror" {
                    "0 0"   {set orientation R0}
                    "0 1"   {set orientation MX}
                    "180 1" {set orientation MY}
                    "180 0" {set orientation R180}
                }
                le::createInst -libName $libraries($macro) -cellName $macro -viewName layout -design $design -orient $orientation -origin "[expr $x] [expr $y]" -rows $rows -cols $columns -dx [expr $dx] -dy [expr $dy]
            }
            
            de::save $context
            de::close $context
        }
    }

    proc launchCRDTestcaseCreation {} {
        variable scriptDir

        source [file join $scriptDir "crd_abutment_floorplans.tcl"]

        # Get list of libraries.
        set libs [db::createList [db::getAttr name -of [dm::getLibs]]]

        # Generate GUI dialog box.
        set crdDialog       [gi::createDialog crdDialog -title "CRD Testcase Creation" -showHelp 0 -execProc cc_crd_abutment::CRDTestcaseCreationExecProc]
        set destlibInput    [dm::createLibInput destlibInput -parent $crdDialog -label "Destination Library"]
        set testcasesInput  [gi::createListInput testcasesInput -parent $crdDialog -label "Testcases to Generate" -header "Testcases" -items [array names floorplans] -showFilter -selectionModel multiple -viewType checkbox]
        set reflibsInput    [gi::createListInput reflibsInput -parent $crdDialog -label "Reference Libraries" -header "Available Selected" -items $libs -selectionModel multiple -viewType dualList]
        set haloInputs      [gi::createInlineGroup haloInputs -parent $crdDialog -label "Boundary Upsize (Halo) (um)"]

        foreach side {bottom left right top} {
            set ${side}HaloInput [gi::createNumberInput ${side}HaloInput -parent $haloInputs -label [string toupper $side 0 0] -valueType float -value 5]
        }

        set layersInput [gi::createListInput layersInput -parent $crdDialog -label "Layers for Pin Propagation" -header "Layers" -items "M0 M1 M2 M3 M4 M5 M6 M7 M8 M9 M10 M11 M12 M13 M14 M15 M16 M17 M18 MTOP-1 MTOP RDL" -selectionModel multiple -viewType checkbox]
    }

    proc add_boundary_layer {macros halo_size} {
        lassign $halo_size halo(x1) halo(y1) halo(x2) halo(y2)
        puts add_boundary_layer
        foreach macro $macros {
            variable libraries($macro)
            set context [de::open [dm::getCellViews layout -cellName $macro -libName $libraries($macro)] -readOnly true -headless true]
            set design [db::getAttr editDesign -of $context]

            lassign [db::getAttr bBox -of $design] pointOne pointTwo
            lassign $pointOne point(x1) point(y1)
            lassign $pointOne point(x2) point(y2

            set new_points [list [list  [expr {$point(x1) - $halo(x1)}] \
                [expr {$point(y1) - $halo(y1)}] ] \
                [list  [expr {$point(x2) + $halo(x2)}] \
                [expr {$point(y2) + $halo(y2)}] ] ]

            le:createBoundary $new_points -design $design -type pr
            de::close $context
        }

    }

    proc CRDTestcaseCreationExecProc {dialog} {

        variable scriptDir [file dirname [info script]]

        # Capture inputs.
        set destlib    [gi::findChild destlibInput.value    -in $dialog]
        set testcases  [gi::findChild testcasesInput.value  -in $dialog]
        set reflibs    [gi::findChild reflibsInput.value    -in $dialog]
        set bottomHalo [gi::findChild bottomHaloInput.value -in $dialog]
        set leftHalo   [gi::findChild leftHaloInput.value   -in $dialog]
        set rightHalo  [gi::findChild rightHaloInput.value  -in $dialog]
        set topHalo    [gi::findChild topHaloInput.value    -in $dialog]
        set layers     [gi::findChild layersInput.value     -in $dialog]

        source [file join $scriptDir "crd_abutment_floorplans.tcl"]

        set macros [get_macros_from_testcases $testcases]

        check_lib_layoutview $macros $reflibs

        get_macros_sizes $macros

        add_boundary_layer $macros [list $leftHalo $bottomHalo $rightHalo $topHalo]

        generate_testcases $testcases $destlib

    }

    launchCRDTestcaseCreation

}