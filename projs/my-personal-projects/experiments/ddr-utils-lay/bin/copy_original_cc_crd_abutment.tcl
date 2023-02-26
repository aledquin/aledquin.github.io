# Description: Custom Compiler script to generate CRD abutment and boundary decap testcases within OA libraries.

# Revision history:
# 2022.08 - Still in development.

namespace eval cc_crd_abutment {

  variable scriptDir [file dirname [info script]]

  proc CRDTestcaseCreationExecProc {dialog} {
    variable scriptDir
    
    # Capture inputs.
    set destlib [gi::findChild destlibInput.value -in $dialog]
    set testcases [gi::findChild testcasesInput.value -in $dialog]
    set reflibs [gi::findChild reflibsInput.value -in $dialog]
    set bottomHalo [gi::findChild bottomHaloInput.value -in $dialog]
    set leftHalo [gi::findChild leftHaloInput.value -in $dialog]
    set rightHalo [gi::findChild rightHaloInput.value -in $dialog]
    set topHalo [gi::findChild topHaloInput.value -in $dialog]
    set layers [gi::findChild layersInput.value -in $dialog]
    
    # Source floorplans array from crd_abutment_floorplans.tcl file in same directory as script.
    source [file join $scriptDir crd_abutment_floorplans.tcl]
    
    # Get list of macros and find libraries.
    foreach testcase $testcases {
      foreach {macro columns rows d_x d_y x y angle mirror} $floorplans($testcase) {
        lappend macros $macro
      }
    }
    set macros [lsort -unique $macros]
    foreach macro $macros {
      foreach lib $reflibs {
        # First check that cell exists in lib, then check if layout view exists.
        if {![db::isEmpty [dm::getCells $macro -libName $lib]] && ![db::isEmpty [dm::getCellViews layout -cellName $macro -libName $lib]]} {
          set libraries($macro) $lib
          break
        }
      }
    }
   
    # Confirm lib found for all cells, otherwise return.
    foreach macro $macros {
      if {[array names libraries -exact $macro] == ""} {
        de::sendMessage "No reference library found for $macro. Exiting." -severity error
        return
      }
    }
    
    # Get macro sizes.
    foreach macro $macros {
      set context [de::open [dm::getCellViews layout -cellName $macro -libName $libraries($macro)] -readOnly true -headless true]
      set design [db::getAttr editDesign -of $context]
      set block [oa::getTopBlock $design]
      set boundary [oa::PRBoundaryFind $block]
      #set widths($macro) [lindex [db::getAttr bBox -of $boundary] 1 0]
      set x_$macro [lindex [db::getAttr bBox -of $boundary] 1 0]
      #set heights($macro) [lindex [db::getAttr bBox -of $boundary] 1 1]
      set y_$macro [lindex [db::getAttr bBox -of $boundary] 1 1]
      de::close $context
    }
    
    # Generate testcase.
    foreach testcase $testcases {
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

  

  # main procedure to launch after sourcing script.
  proc launchCRDTestcaseCreation {} {
    variable scriptDir
    
    # Source floorplans array from crd_abutment_floorplans.tcl file in same directory as script.
    source [file join $scriptDir crd_abutment_floorplans.tcl]
    
    # Get list of libraries.
    set libs [db::createList [db::getAttr name -of [dm::getLibs]]]
    
    # Generate GUI dialog box.
    set crdDialog [gi::createDialog crdDialog -title "CRD Testcase Creation" -showHelp 0 -execProc cc_crd_abutment::CRDTestcaseCreationExecProc]
    set destlibInput [dm::createLibInput destlibInput -parent $crdDialog -label "Destination Library"]
    set testcasesInput [gi::createListInput testcasesInput -parent $crdDialog -label "Testcases to Generate" -header "Testcases" -items [array names floorplans] -showFilter -selectionModel multiple -viewType checkbox]
    set reflibsInput [gi::createListInput reflibsInput -parent $crdDialog -label "Reference Libraries" -header "Available Selected" -items $libs -selectionModel multiple -viewType dualList]
    set haloInputs [gi::createInlineGroup haloInputs -parent $crdDialog -label "Boundary Upsize (Halo) (um)"]
    foreach side {bottom left right top} {
      set ${side}HaloInput [gi::createNumberInput ${side}HaloInput -parent $haloInputs -label [string toupper $side 0 0] -valueType float -value 5]
    }
    set layersInput [gi::createListInput layersInput -parent $crdDialog -label "Layers for Pin Propagation" -header "Layers" -items "M0 M1 M2 M3 M4 M5 M6 M7 M8 M9 M10 M11 M12 M13 M14 M15 M16 M17 M18 MTOP-1 MTOP RDL" -selectionModel multiple -viewType checkbox]
    
    
  }
  
  launchCRDTestcaseCreation
  
}
