###############################################################################################################
##
## Proc        : dcapPlacer
##
## Description : This tool will automatically place dcap cells into empty areas in the design.  A schematic 
##               and symbol can be created to match the finished layout.
##
## Usage       : There should be a menu item for the tool either on the AMD Tools menu or the User Tools menu
##               This menu item will bring up the dcap placer GUI
##
## Author      : Marc Tareila marc.tareila@amd.com x28586
##
## Revisions   : 10/24/14 - Initial version
##               11/05/14 - Used the dbExportStreamLayerMapFile preference to define the layer map file
##               11/05/14 - Used the dbExportStreamObjectMapFile preference to define the object map file
##               11/06/14 - Added support for a help page
##               11/07/14 - Updated the allow layer to the correct lpp (DCAP_ALLOW drawing)
##               11/24/14 - Created the dialog as a child of the window it was invoked from
##               04/01/15 - Added revrc support to define the dcap cell to be placed
##
## To Do:
## - Get the dcap calibre tech file through revrc.  It used to be called here:  GVAR_amdRevRc[list("alias2path" "decap_tech_file")]
## - Determine if any cells in hierarchy need to be saved when generating the gds
##
###############################################################################################################

namespace eval amd::dcapPlacer {

  ###############################################################################################################
  ## Proc        : initTool
  ## Description : This is the top level proc
  ##               This is meant to be called from a menu action, for example:
  ##               gi::createAction "dcapPlacer" -title "Dcap Placer" -command "amd::dcapPlacer::initTool %c"
  ###############################################################################################################
  proc initTool {context parentWindow} {

    set cv [db::getAttr editDesign -of $context]

    # Create and display the GUI
    set dialog [amd::dcapPlacer::createGUI $cv $parentWindow]
  }

  ###############################################################################################################
  ## Proc        : createGUI
  ## Description : This proc creates the dcap placer GUI and is called from the initTool proc
  ###############################################################################################################
  proc createGUI {cv parentWindow} {

    if {![catch {set dcapLibCellView $::amd::GVAR_amdRevRc(cdesigner_env::dcapPlacerCell)}]} {
      set dcapLibName [lindex [split $dcapLibCellView] 0]
      set dcapCellName [lindex [split $dcapLibCellView] 1]
      set dcapViewName [lindex [split $dcapLibCellView] 2]
    } else {
      set dcapLibName ""
      set dcapCellName ""
      set dcapViewName ""
    }
 
    set libName  [db::getAttr libName -of $cv]
    set cellName [db::getAttr cellName -of $cv]
    set viewName [db::getAttr viewName -of $cv]

    # If the GUI is currently open, close it and build it again
    if {[set dcapPlacerGUI [db::getNext [gi::getDialogs dcapPlacerGUI]]] != ""} {
      gi::closeWindows $dcapPlacerGUI
    }
 
    # Create the dialog that contains all of the widgets
    set dcapPlacerGUI [gi::createDialog dcapPlacerGUI -title "AMD Dcap Placer" -execProc amd::dcapPlacer::execProc \
           -topicId amdDcapPlacer -parent $parentWindow]

    # Design Source Widgets
    set designGroup [gi::createGroup designGroup -parent $dcapPlacerGUI -label "Design source data"]
    set designLibrary [gi::createTextInput designLibrary -parent $designGroup -label "Library" -width 16 -value $libName]
    set designCell [gi::createTextInput designCell -parent $designGroup -label "Cell" -width 30 -value $cellName]
    set designView [gi::createTextInput designView -parent $designGroup -label "View" -width 6 -value $viewName]
    gi::layout $designCell -rightOf $designLibrary
    gi::layout $designView -rightOf $designCell

    # Input Widgets
    set inputGroup [gi::createGroup inputGroup -parent $dcapPlacerGUI -label "Specify the dcap cell to place"]
    set dcapLibrary [gi::createTextInput dcapLibrary -parent $inputGroup -label "Library" -width 16 -value $dcapLibName]
    set dcapCell [gi::createTextInput dcapCell -parent $inputGroup -label "Cell" -width 30 -value $dcapCellName]
    set dcapView [gi::createTextInput dcapView -parent $inputGroup -label "View" -width 6 -value $dcapViewName]
    gi::layout $dcapCell -rightOf $dcapLibrary
    gi::layout $dcapView -rightOf $dcapCell

    # Output Widgets
    set outputGroup [gi::createGroup outputGroup -parent $dcapPlacerGUI -label "Specify the output holding cell"]
    set outputLibrary [gi::createTextInput outputLibrary -parent $outputGroup -label "Library" -width 16 -value $libName]
    set outputCell [gi::createTextInput outputCell -parent $outputGroup -label "Cell" -width 30 -value ${cellName}_dcapPlacer]
    set outputView [gi::createTextInput outputView -parent $outputGroup -label "View" -width 6 -value $viewName]
    gi::layout $outputCell -rightOf $outputLibrary
    gi::layout $outputView -rightOf $outputCell

    # Options Widgets
    set optionsGroup [gi::createGroup optionsGroup -parent $dcapPlacerGUI -label "Options"]
    set runDirName [file join [exec pwd] "dcapPlacer"]
    if {![file isdir $runDirName]} {
      file mkdir $runDirName
    }
    set runDir [gi::createFileInput runDir -parent $optionsGroup -label "Run dir" -fileType directory -value $runDirName]
    gi::layout $runDir -justify right
    set gdsBoolean [gi::createBooleanInput gdsBoolean -parent $optionsGroup -label "Use existing GDS"]
    gi::layout $gdsBoolean -justify right
    set gdsFileName [file join $runDirName "$cellName.gds"]
    set gdsFile [gi::createFileInput gdsFile -parent $optionsGroup -value $gdsFileName]
    gi::layout $gdsFile -rightOf $gdsBoolean -justify right
    set keepoutLayersLabel [gi::createLabel keepoutLayersLabel -parent $optionsGroup -label "Keepout layers:"]
    set keepoutLayers [list BELOW_M1 UPTO_M1 UPTO_M2 UPTO_M3 UPTO_M4]
    set keepoutLayersCyclic [gi::createMutexInput keepoutLayersCyclic -parent $optionsGroup -viewType combo -enum $keepoutLayers -value UPTO_M1]
    set xBloatNumber [gi::createNumberInput xBloatNumber -parent $optionsGroup -label "   XBloat" -valueType float -width 5]
    set yBloatNumber [gi::createNumberInput yBloatNumber -parent $optionsGroup -label "   YBloat" -valueType float -width 5]
    gi::layout $keepoutLayersLabel -justify right
    gi::layout $keepoutLayersCyclic -rightOf $keepoutLayersLabel
    gi::layout $xBloatNumber -rightOf $keepoutLayersCyclic
    gi::layout $yBloatNumber -rightOf $xBloatNumber
    set rowFlip [gi::createBooleanInput rowFlip -parent $optionsGroup -label "Flip every other row" -value true]
    set rowOrient [gi::createMutexInput rowOrient -parent $optionsGroup -label "First row orientation" -viewType combo -enum [list R0 MX]]
    set colFlip [gi::createBooleanInput colFlip -parent $optionsGroup -label "Flip every other column"]
    set colOrient [gi::createMutexInput colOrient -parent $optionsGroup -label "First column orientation" -viewType combo -enum [list R0 MY]]
    gi::layout $rowOrient -rightOf $rowFlip -align $yBloatNumber 
    gi::layout $colOrient -rightOf $colFlip -align $rowOrient
    set createSch [gi::createBooleanInput createSch -parent $optionsGroup -label "Create schematic" -value true]

    # Register the help procedure
    catch {de::registerHelp -helpID amdDcapPlacer -type url -target http://twiki.amd.com/twiki/bin/view/Layout/DcapPlacerHelp}

    return $dcapPlacerGUI
  }

  ###############################################################################################################
  ## Proc        : execProc
  ## Description : This proc is called when the user clicks on the Ok or Apply button and does the following:
  ##
  ##  1. Verifies that the information on the GUI is correct
  ##  2. Checks that everything needed for a successful run is all accounted for
  ##  3. Calls createGDS to run stream out if needed
  ##  4. Calls runCalibre to run calibre in order to generate legal areas for dcaps 
  ##  5. Calls placeDcapsFromCalibreResults to place the dcaps into the legal areas from the Calibre run
  ##  5. Instantiates the output holding cell in the top cell
  ##  6. Optionally calls createSchematic to create a schematic and symbol matching the holding cell
  ###############################################################################################################
  proc execProc {dialog} {

    de::sendMessage "Running the AMD Dcap Placer..." -severity information
    update

    set startTime [clock seconds]

    # Get the top cell to process
    set libName [db::getAttr value -of [gi::findChild designLibrary -in $dialog]]
    set cellName [db::getAttr value -of [gi::findChild designCell -in $dialog]]
    set viewName [db::getAttr value -of [gi::findChild designView -in $dialog]]
    set cv [amd::userUtils::openCellView $libName $cellName $viewName a]
    if {$cv == -1} {
      amd::userUtils::displayDialog "error" "The design source cell ($libName $cellName $viewName) can't be opened - script aborted" $dialog
      return
    }
    
    # Make sure there is a PR Boundary in the design - The Calibre job needs it
    if {[set prBoundary [amd::userUtils::getPrBoundary $cv]] == -1} {
      amd::userUtils::displayDialog "error" "The PR Boundary object is missing from the design cell - script aborted" $dialog
      return
    }

    # Make sure there are shapes in the design on the allow layer - The Calibre job needs it
    set allowLPP {DCAP_ALLOW drawing}
    if {[db::isEmpty [db::getShapes -of $cv -lpp $allowLPP]]} {
      amd::userUtils::displayDialog "error" "No shapes on the allow lpp $allowLPP were found in the design - script aborted" $dialog
      return
    }
 
    # Open the dcap cell to be placed
    set dcapLibName [db::getAttr value -of [gi::findChild dcapLibrary -in $dialog]]
    set dcapCellName [db::getAttr value -of [gi::findChild dcapCell -in $dialog]]
    set dcapViewName [db::getAttr value -of [gi::findChild dcapView -in $dialog]]
    set dcapCellView [amd::userUtils::openCellView $dcapLibName $dcapCellName $dcapViewName]
    if {$dcapCellView == -1} {
      amd::userUtils::displayDialog "error" "The dcap cell ($dcapLibName $dcapCellName $dcapViewName) can't be opened - script aborted" $dialog
      return
    }

    # Get the prBoundary in the dcap cell.  This will be used to calculate the stepping dimensions
    if {[set prBoundary [amd::userUtils::getPrBoundary $dcapCellView]] == -1} {
      amd::userUtils::displayDialog "error" "The PR Boundary object is missing from the dcap cell - script aborted" $dialog
      return
    }
    set dcapCellWidth [amd::userUtils::getWidth [db::getAttr bBox -of $prBoundary]]
    set dcapCellHeight [amd::userUtils::getHeight [db::getAttr bBox -of $prBoundary]]

    # Verify the output holding cell.  If it doesn't exist it will be created.  If it exists it will be overwritten
    set outputLibName [db::getAttr value -of [gi::findChild outputLibrary -in $dialog]]
    set outputCellName [db::getAttr value -of [gi::findChild outputCell -in $dialog]]
    set outputViewName [db::getAttr value -of [gi::findChild outputView -in $dialog]]
    set outputCellView [amd::userUtils::createCellView $outputLibName $outputCellName $outputViewName]
    if {$outputCellView == -1} {
      amd::userUtils::displayDialog "error" "The output holding cell ($outputLibName $outputCellName $outputViewName) can't be opened - script aborted" $dialog
      return
    }

    # Make sure the output holding cell is not already instantiated in the top cell. If it is, delete it
    db::foreach outputInst [db::getInsts -of $cv -filter {%cellName == $outputCellName}] {
      de::sendMessage "   An instance of the output holding cell was found in the design - it has been removed" -severity information
      update
      le::delete $outputInst
      de::save $cv
    }

    # Verify the run directory:  It needs to exist and be writable
    set runDirName [db::getAttr value -of [gi::findChild runDir -in $dialog]]
    if {![file writable $runDirName]} {
      amd::userUtils::displayDialog "error" "The run directory doesn't exist or is not writable - script aborted" $dialog
      return
    }

    # Verify the existing GDS if specified
    if {[db::getAttr value -of [gi::findChild gdsBoolean -in $dialog]]} {
      set gdsFileName [db::getAttr value -of [gi::findChild gdsFile -in $dialog]]
      if {![file readable $gdsFileName]} {
        amd::userUtils::displayDialog "error" "The GDS file can't be found - script aborted" $dialog
        return
      }
    } else {
      # The user didn't specify to use an existing GDS. Run stream out
      # First make sure the top cell is saved
      if {[db::getAttr modified -of $cv]} {
        amd::userUtils::displayDialog "error" "The layout needs to be saved before writing the GDS - script aborted" $dialog
        return
      }
      # And now run stream out to generate the gds
      set gdsFileName [amd::userUtils::createGDS $libName $cellName $viewName $runDirName]
      # Make sure the GDS was written 
      if {$gdsFileName == -1} {
        amd::userUtils::displayDialog "error" "Error writing the GDS - script aborted" $dialog
        return
      }
    }

    # Get some info from the GUI and Run Calibre
    set xBloat [db::getAttr value -of [gi::findChild xBloatNumber -in $dialog]]
    set yBloat [db::getAttr value -of [gi::findChild yBloatNumber -in $dialog]]
    set m1 0; set m2 0; set m3 0; set m4 0
    switch [db::getAttr value -of [gi::findChild keepoutLayersCyclic -in $dialog]] {
      "UPTO_M1" {set m1 1}
      "UPTO_M2" {set m1 1; set m2 1}
      "UPTO_M3" {set m1 1; set m2 1; set m3 1}
      "UPTO_M4" {set m1 1; set m2 1; set m3 1; set m4 1}
    }
    set calibreResultsFileName [amd::dcapPlacer::runCalibre \
      $cellName $runDirName $gdsFileName $dcapCellWidth $dcapCellHeight $xBloat $yBloat $m1 $m2 $m3 $m4 \
    ]
    # Make sure Calibre ran successfully
    if {$calibreResultsFileName == -1} {
      amd::userUtils::displayDialog "error" "Error running Calibre - script aborted" $dialog
      return
    }

    # Read the Calibre results file and instantiate dcap cells
    set dcapCells [amd::dcapPlacer::placeDcapsFromCalibreResults $outputCellView $dcapCellView $calibreResultsFileName $dialog]

    if {$dcapCells > 0} {
      # Instantiate the output holding cell in the top cell
      if {![catch {le::createInst -design $cv -master $outputCellView -origin {0 0}}]} {
        de::sendMessage "   Instantiating the holding cell..." -severity information
        update
        de::save $cv
      }

      # Create the schematic
      if {[db::getAttr value -of [gi::findChild createSch -in $dialog]]} {
        amd::dcapPlacer::createSchematic $outputLibName $outputCellName $dcapLibName $dcapCellName $dcapCells
      }
    }

    de::sendMessage "AMD Dcap Placer completed in [expr [clock seconds] - $startTime] seconds" -severity information
  }

  ###############################################################################################################
  ## Proc        : runCalibre
  ## Description : This proc builds the Calibre tech file and runs the calibre job
  ###############################################################################################################
  proc runCalibre {cellName runDirName gdsFileName dcapWidth dcapHeight xBloat yBloat m1 m2 m3 m4} {

    de::sendMessage "   Generating the dcap placer Calibre tech file..." -severity information
    update

    # Create the header section of the Calibre dcap placer tech file
    set summaryFileName [file join $runDirName "$cellName.dcapPlacer.summary"]
    set logFileName [file join $runDirName "$cellName.dcapPlacer.log"]
    set resultsFileName [file join $runDirName "$cellName.dcapPlacer.results"]
    set dcapTechFileName [file join $runDirName "dcapPlacer.tech"]
    set dcapTechFile [open $dcapTechFileName w]
    puts $dcapTechFile "//"
    puts $dcapTechFile "// Settings generated from the dcapPlacer tcl script"
    puts $dcapTechFile "//"
    puts $dcapTechFile "LAYOUT PATH \"$gdsFileName\""
    puts $dcapTechFile "LAYOUT PRIMARY $cellName"
    puts $dcapTechFile "DRC RESULTS DATABASE \"$resultsFileName\""
    puts $dcapTechFile "DRC SUMMARY REPORT \"$summaryFileName\" REPLACE HIER"
    puts $dcapTechFile "VARIABLE dcap_width $dcapWidth"
    puts $dcapTechFile "VARIABLE dcap_height $dcapHeight"
    if {$dcapWidth > $dcapHeight} {
      set keepout $dcapWidth
    } else {
      set keepout $dcapHeight
    }
    puts $dcapTechFile "VARIABLE keepout $keepout"
    puts $dcapTechFile "VARIABLE xbloat $xBloat"
    puts $dcapTechFile "VARIABLE ybloat $yBloat"
    # puts $dcapTechFile "#DEFINE DEBUG"
    if {$m1} {puts $dcapTechFile "#DEFINE KEEPOUT_M1"}
    if {$m2} {puts $dcapTechFile "#DEFINE KEEPOUT_M2"}
    if {$m3} {puts $dcapTechFile "#DEFINE KEEPOUT_M3"}
    if {$m4} {puts $dcapTechFile "#DEFINE KEEPOUT_M4"}
    puts $dcapTechFile ""
    puts $dcapTechFile ""
    close $dcapTechFile

    # Determine the PDK calibre dcap placer tech file
    # Eventually we should get the tech file officially released and pointed to through revrc
    # Right now the tech files are located in /proj/tcoe_skill/cdesigner/phyv_runsets
    if {[lindex [split $::env(SNPS_PDK) /] 4] == "GF"} {
      set dcapPdkTechFileName "/proj/tcoe_skill/cdesigner/phyv_runsets/dcapPlacer.GF14LPP_11M_3Mx_4Cx_2Kx_2Gx_LB.tech"
    } else {
      set dcapPdkTechFileName "/proj/tcoe_skill/cdesigner/phyv_runsets/dcapPlacer.TSMC16FFplus_1P11M2XA1XD3XE2Y2R.tech"
    }

    # Append the Calibre dcap placer tech file from the PDK to the file created above
    if {![file readable $dcapPdkTechFileName]} {
      amd::userUtils::displayDialog "error" "The Dcap tech file can't be found - script aborted"
      return -1
    }
    if {[catch {exec cat $dcapPdkTechFileName >> $dcapTechFileName}]} {
      amd::userUtils::displayDialog "error" "Error creating the dcap tech file - script aborted"
      return -1
    }

    de::sendMessage "   Running Calibre..." -severity information
    update

    set startTime [clock seconds]

    # Remove any calibre files from previous runs
    if {[file writable $summaryFileName]} {exec rm $summaryFileName}
    if {[file writable $logFileName]} {exec rm $logFileName}
    if {[file writable $resultsFileName]} {exec rm $resultsFileName}
    #set projrev [exec rexval global::projrev_version]
    set projrev $::amd::GVAR_amdRevRc(global::projrev_version)
    catch {exec /tool/amd/rex/bin/calibre -projrev $projrev -drc $dcapTechFileName > $logFileName}
    if {![file isfile $resultsFileName]} {
      return -1
    }

    de::sendMessage "   Calibre job completed in [expr [clock seconds] - $startTime] seconds" -severity information
    update
    return $resultsFileName
  }

  ###############################################################################################################
  ## Proc        : placeDcapsFromCalibreResults
  ## Description : This proc parses the Calibre output results and places dcap instances
  ###############################################################################################################
  proc placeDcapsFromCalibreResults {cv dcapCv resultsFileName dialog} {

    de::sendMessage "   Generating instances based on Calibre results..." -severity information
    update

    set dcapsPlaced 0
    set startTime [clock seconds]

    # Get the orientation info from the GUI
    set flipRows [db::getAttr value -of [gi::findChild rowFlip -in $dialog]]
    set firstRowOrient [db::getAttr value -of [gi::findChild rowOrient -in $dialog]]
    set flipColumns [db::getAttr value -of [gi::findChild colFlip -in $dialog]]
    set firstColumnOrient [db::getAttr value -of [gi::findChild colOrient -in $dialog]]

    # Determine the orientations from the 16 combinations of options on the GUI
    if {$flipRows  && $flipColumns  && $firstRowOrient == "R0" && $firstColumnOrient == "R0"} {set orientList [list R0 MY MX R180]}
    if {$flipRows  && $flipColumns  && $firstRowOrient == "R0" && $firstColumnOrient == "MY"} {set orientList [list MY R0 R180 MX]}
    if {$flipRows  && $flipColumns  && $firstRowOrient == "MX" && $firstColumnOrient == "R0"} {set orientList [list MX R180 R0 MY]}
    if {$flipRows  && $flipColumns  && $firstRowOrient == "MX" && $firstColumnOrient == "MY"} {set orientList [list R180 MX MY R0]}
    if {$flipRows  && !$flipColumns && $firstRowOrient == "R0" && $firstColumnOrient == "R0"} {set orientList [list R0 R0 MX MX]}
    if {$flipRows  && !$flipColumns && $firstRowOrient == "R0" && $firstColumnOrient == "MY"} {set orientList [list MY MY R180 R180]}
    if {$flipRows  && !$flipColumns && $firstRowOrient == "MX" && $firstColumnOrient == "R0"} {set orientList [list MX MX R0 R0]}
    if {$flipRows  && !$flipColumns && $firstRowOrient == "MX" && $firstColumnOrient == "MY"} {set orientList [list R180 R180 MY MY]}
    if {!$flipRows && $flipColumns  && $firstRowOrient == "R0" && $firstColumnOrient == "R0"} {set orientList [list R0 MY R0 MY]}
    if {!$flipRows && $flipColumns  && $firstRowOrient == "R0" && $firstColumnOrient == "MY"} {set orientList [list MY R0 MY R0]}
    if {!$flipRows && $flipColumns  && $firstRowOrient == "MX" && $firstColumnOrient == "R0"} {set orientList [list MX R180 MX R180]}
    if {!$flipRows && $flipColumns  && $firstRowOrient == "MX" && $firstColumnOrient == "MY"} {set orientList [list R180 MX R180 MX]}
    if {!$flipRows && !$flipColumns && $firstRowOrient == "R0" && $firstColumnOrient == "R0"} {set orientList [list R0 R0 R0 R0]}
    if {!$flipRows && !$flipColumns && $firstRowOrient == "R0" && $firstColumnOrient == "MY"} {set orientList [list MY MY MY MY]}
    if {!$flipRows && !$flipColumns && $firstRowOrient == "MX" && $firstColumnOrient == "R0"} {set orientList [list MX MX MX MX]}
    if {!$flipRows && !$flipColumns && $firstRowOrient == "MX" && $firstColumnOrient == "MY"} {set orientList [list R180 R180 R180 R180]}

    # The Calibre results could contain output from 4 separate checks with the following names:
    #   legalDcaps_00 - Represent dcaps in row 0, column 0. Use the first index in the orient list
    #   legalDcaps_01 - Represent dcaps in row 0, column 1. Use the second index in the orient list
    #   legalDcaps_10 - Represent dcaps in row 1, column 0. Use the third index in the orient list
    #   legalDcaps_11 - Represent dcaps in row 1, column 1. Use the fourth index in the orient list
    #
    # All of the cells in a check will have the same orientation as the rest of the cells in that same check
    #
    # Each calibre result is a rectangle that will represent the coords for the prBoundary rectangle of the dcap instance
    #
    # There are four coordinate pairs that represent the four corners of the rectangle
    # Each coordinate pair is on its own line
    # The lowerLeft coord is on the first line
    # The lowerRight coord is on the next line
    # The upperRight coord is on the next line
    # The upperLeft coord is on the next line

    set resultsFile [open $resultsFileName r]
    while {[gets $resultsFile fileLine] >= 0} {
      set line [split $fileLine]

      switch [lindex $line 0] {
        legalDcaps_00 {set orient [lindex $orientList 0]}
        legalDcaps_01 {set orient [lindex $orientList 1]}
        legalDcaps_10 {set orient [lindex $orientList 2]}
        legalDcaps_11 {set orient [lindex $orientList 3]}
      }

      # Look for a line containing the letter p and two numbers after it with the second number always being 4 such as:  p # 4
      # The coords are the 4 lines after this line.  The coords need to be divided by 1000
      if {[lindex $line 0] == "p" && [llength $line] == 3 && [lindex $line 2] == 4} {
        set lowerLeft  [split [gets $resultsFile]]
        set lowerRight [split [gets $resultsFile]]
        set upperRight [split [gets $resultsFile]]
        set upperLeft  [split [gets $resultsFile]]

        switch $orient {
          R0 {set point $lowerLeft}
          MY {set point $lowerRight}
          R180 {set point $upperRight}
          MX {set point $upperLeft}
        }
        set origin [list [expr [lindex $point 0] / 1000.00] [expr [lindex $point 1] / 1000.00]]        

        # Place the instance
        if {![catch {le::createInst -design $cv -master $dcapCv -origin $origin -orient $orient}]} {
          incr dcapsPlaced
        }
      }
    }

    close $resultsFile
    de::save $cv

    de::sendMessage "   Placed $dcapsPlaced dcaps in [expr [clock seconds] - $startTime] seconds" -severity information
    update
    return $dcapsPlaced
  }

  ###############################################################################################################
  ## Proc        : createSchematic
  ## Description : This proc creates the schematic and symbol for the holding cell
  ###############################################################################################################
  proc createSchematic {libName cellName dcapLibName dcapCellName dcapCells} {

    de::sendMessage "   Generating the schematic and symbol for the $cellName holding cell..." -severity information
    update
    set startTime [clock seconds]

    # Make sure the symbol for the dcap exists
    set dcapSymbol [amd::userUtils::openCellView $dcapLibName $dcapCellName symbol]
    if {$dcapSymbol == -1} {
      amd::userUtils::displayDialog "error" "The dcap symbol can't be opened - schematic creation aborted" 
      return -1
    }

    # Open the schematic for the holding cell
    # If it doesn't exist, create it
    set cv [amd::userUtils::createCellView $libName $cellName schematic]
    if {$cv == -1} {
      amd::userUtils::displayDialog "error" "The output holding cell schematic ($libName $cellName schematic) can't be opened - schematic creation aborted"
      return -1
    }

    # Delete any existing objects in the schematic
    catch {se::delete [db::getInsts -of $cv]}
    catch {se::delete [db::getShapes -of $cv]}

    # Instantiate the dcap symbol
    set instName DC<[expr $dcapCells - 1]:0>
    set inst [se::createInst $instName -design $cv -master $dcapSymbol -origin {0 0}]
    set instBbox [db::getAttr bBox -of $inst]

    # Create wire stubs on the dcap instance
    # The wireStub command needs a collection of figures as it's input
    # The only figure in the design is the instance that we just placed
    se::createWireStubs [de::getFigures [db::getAttr bBox -of $cv] -design $cv] -wireLabel pinName -size 5

    # Create toplevel pins for each of the wire stubs created
    # These will be created above the dcap instance
    set xCoord [amd::userUtils::xCoord [amd::userUtils::centerBox $instBbox]]
    set yCoord [expr {[amd::userUtils::yCoord [amd::userUtils::upperLeft $instBbox]] + .4}]
    db::foreach wire [db::getShapes -of $cv -filter {%type == "Line"}] {
      set netName [db::getAttr net.name -of $wire]
      set point [list $xCoord $yCoord]
      set pinType [db::getAttr termType -of [db::getNext [db::filter [db::getAttr master.terms -of $inst] -filter {%this.name == $netName}]]]
      se::createPin $netName -design $cv -type $pinType -points [list $point] -shape custom
      # The next pin will be created a little higher than the previous one
      set yCoord [expr {$yCoord + .2}]
    }

    de::save $cv

    # Create a symbol for the schematic
    # Use the schematic as a source for interface information and symbol generator default options
    set symbolCv [dm::findCellView symbol -libName $libName -cellName $cellName]
    set os [db::getGenOptionSets default -filter {%setType == "symbolGenerator"}]
    set is [db::getCellViewInterface -src [dm::findCellView schematic -libName $libName -cellName $cellName]]
    se::generateSymbol -interface $is -dest $symbolCv -update false -options $os

    de::sendMessage "   Schematic and symbol created in [expr [clock seconds] - $startTime] seconds" -severity information
    update
    return 1
  }
}

