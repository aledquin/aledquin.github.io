#!/depot/tcl8.6.6/bin/tclsh
#########################################################################################
#                                PRE_COVERCELL_GEN                                      #
#                                #################                                      #
#                                                                                       #
# Authors   :   Hesham fayez                                                            #
#                                                                                       #
# Usage     :   Generate custom compiler PRE_COVERCELL_GEN dialog box to set            #
#               the data script input and generate cover cells view.                    #
#                                                                                       #
# Description   : Input type                                                            #
#       - File -> an existing LEF file.                                                 #
#       - Layout view parameters -> set view, cell and library names                    #
#       - MINT layers gen -> set whether to generate MINT layers or not.                #
#                                                                                       #
#                                                                                       #
#########################################################################################

##########################################################
## First GUI interface with the following features:     ##
## 1. Import LEF FIle.                                  ##
## 2. Library.                                          ##
## 3. Cell/Macro.                                       ##
## 4. View.                                             ##
## 5. Binary options                                    ##
##  - Create MIPLAST                                    ##
##  - Create MINTLAYERS                                 ##
##  - Auto VIA Creation                                 ##
##  - Overwrite Existing View                           ##
##########################################################

proc tutils__script_usage_statistics {toolname version} {
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
tutils__script_usage_statistics $script_name "2022ww27" 

set thisScript [file normalize [info script]]
set thisScriptDir [file dirname $thisScript]

################### Data base prefrences to set ###################
## lef file PREF
db::createPref "lefFileInput"              -value ""                -description "input file by user"

## Library, cell and view PREFs
db::createPref "preCoverCellLibraryName"   -value "dwc_ddrphycover" -description "coverCell library"
db::createPref "cellNameToGenerate"        -value ""                -description "CoverCell cell name"
db::createPref "preCoverCellViewName"      -value "layout"          -description "coverCell view name"

## MIPLAST & MINT layers PREFs
db::createPref "preCoverCellMIPLAST"       -value ""                -description "MTOP layer"
db::createPref "mintlastLayer"             -value ""                -description "Last MINT layers to be generated"

## Binary Options PREFs
db::createPref "createMIPLASTLayers"       -value false             -description "Use MTOP yes/no option"
db::createPref "preCoverCellGenMINTLayers" -value false             -description "Option whether to create MINT layers YES/NO"
db::createPref "autoViaCreation"           -value true              -description "Create auto Via for layout view"
db::createPref "overWrite"                 -value false             -description "Overwrite existing layout view"
db::createPref "preCoverCellLabelPurpose"  -value "label"           -description "Label purpose"
############################ Dialoge box generation ############################

proc basicDialogBox {} {
    ################### GUI Dialog ###################
    set dialog [gi::createDialog preCoverCellGen \
    -title "PRE_COVERCELL_GEN" \
    -showApply false \
    -showHelp false \
    -execProc pushButton]
    
    ################### GUI Interface tabs construction ###################
    set inputGroup      [gi::createGroup          -parent $dialog \
                                                  -label "Input LEF"
                                                  ]
    set lefFile         [gi::createFileInput      -parent $inputGroup \
                                                  -label "Import LEF File:" \
                                                  -fileMasks "*.lef" \
                                                  -required true \
                                                  -prefName lefFileInput
                                                  ]
    set outputGroup     [gi::createGroup          -parent $dialog \
                                                  -label "Output View"
                                                  ]
    set libraryName     [dm::createLibInput       -parent $outputGroup \
                                                  -label "Library:" \
                                                  -prefName preCoverCellLibraryName
                                                  ]
    set cellName        [gi::createTextInput      -parent $outputGroup \
                                                  -label "Cell/Macro:" \
                                                  -required true \
                                                  -prefName cellNameToGenerate
                                                  ]
    set viewName        [gi::createTextInput      -parent $outputGroup \
                                                  -label "View:" \
                                                  -required true \
                                                  -prefName preCoverCellViewName
                                                  ]
    set miplastGroup    [gi::createGroup -parent  $dialog \
                                                  -label "Create MIPLAST Pin/Layer"
                                                  ]
    set miplastText     [gi::createTextInput      -parent $miplastGroup \
                                                  -required true \
                                                  -prefName preCoverCellMIPLAST
                                                  ]
    set labelPurpose   [gi::createMutexInput     -parent $miplastGroup \
                                                  -label "Label LPP" \
                                                  -viewType "radio" \
                                                  -enum "pin label" \
                                                  -prefName preCoverCellLabelPurpose ] 
    set mintGroup       [gi::createCheckableGroup -parent $dialog \
                                                  -label "Create MINT Layers" \
                                                  -prefName preCoverCellGenMINTLayers
                                                  ]
    set mintText        [gi::createTextInput      -parent $mintGroup \
                                                  -toolTip "All of the layers between MIPLAST and this layer will be generated." \
                                                  -label "MINTLAST layer:" \
                                                  -required true \
                                                  -prefName mintlastLayer
                                                  ]
    set autoViaCreation [gi::createBooleanInput   -parent $dialog \
                                                  -label "Auto VIA Creation" \
                                                  -prefName autoViaCreation
                                                  ]
    set overWrite       [gi::createBooleanInput   -parent $dialog \
                                                  -label "Overwrite Existing View" \
                                                  -prefName overWrite
                                                  ]
    gi::layout $autoViaCreation -align $miplastGroup
    gi::layout $overWrite       -align $miplastGroup
    
    gi::_update
    set geometry [db::getAttr geometry -of $dialog]
    lassign [split $geometry "+"] tmp xoff yoff
    lassign [split $tmp "x"] x y
    if {$x < 460} {
        set x 460
    }
    db::setAttr geometry -of $dialog -value "$x\x$y+$xoff+$yoff"
}

############################ Procedure to the final okay button on the dialog box ############################


proc pushButton { d } {
    global thisScriptDir
    set fileDir [db::getPrefValue "lefFileInput"]
    if {[regexp {.lef} $fileDir]} {
        ##debugging line
        #puts "LEF File: $fileDir"
        ##valid file, source creation script
        source $thisScriptDir/ddr-PreCovercellGen_creation.tcl
    } else {
        ## End script with invalid lef file message
        error "Invalid .lef file"
    }   
}

## run
basicDialogBox



################################################################################
# No Linting Area
################################################################################

# nolint Main
# nolint Line 146: W Found constant
