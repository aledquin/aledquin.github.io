#!/depot/tcl8.6.6/bin/tclsh
#################################################################################
#                             CHECK LAYOUT VIEW                                 #
#                             ##################                                #
#                                                                               #
# Authors   : Hesham fayez                                                      #
# Usage     : Check the availability of layout view to create it.               #
# Description   : Check if Layout view exists or not if not creates and opens   #
#         new view.                                                             #
#                                                                               #
#################################################################################




## Script Sequence ##

##################################################
##                                              ##
##  1. Check the layout view existance.         ##
##  2. Create layout view.                      ##
##  3. Create MIPLAST Layers.                   ##
##  4. Check MINT layer option.                 ##
##  5. Create MINT Layer.                       ##
##  6. Check AutoVia creation.                  ##
##  7. Create VIA.                              ##
##  8. Generate exit dialoge.                   ##
##                                              ##
##################################################

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

## Variables setting ##
set overWrite   [db::getPrefValue "overWrite"]
set libraryName [db::getPrefValue "preCoverCellLibraryName"]
set cellName    [db::getPrefValue "cellNameToGenerate"]
set viewName    [db::getPrefValue "preCoverCellViewName"]

## Running Lines ##
set oaLib [dm::getLibs $libraryName]
set oaCell [dm::getCells $cellName -lib $oaLib]

## Check the supplied MIPLAST/MINTLAST layers
set inputMiplastLayer    [db::getPrefValue "preCoverCellMIPLAST"]
set miplastLayerNumber   [regexp -inline {\d+} $inputMiplastLayer]
if {$miplastLayerNumber == ""} {
    error "The supplied MIPLAST layer is not valid. It should contain the metal number."
}
set miplastLayer "M$miplastLayerNumber"
set mintLayersSelected [db::getPrefValue "preCoverCellGenMINTLayers"]

if {$mintLayersSelected == 1} {
    set mintlastNumber [regexp -inline {\d+} [db::getPrefValue "mintlastLayer"]]
    if {$mintlastNumber == ""} {
        error "The supplied MINTLAST layer is not valid. It should contain the metal number."
    }
    # Get the number of the first MINT layer and check if the supplied MINT last
    # layer number is greater or equal to it.
    set mintfirstNumber [expr {$miplastLayerNumber + 1}]
    if {$mintfirstNumber > $mintlastNumber} {
        error "The supplied MINT last layer is lower than the first MINT layer."
    }
    # Create a list containing the MINT layers to be generated.
    for {set layerNumber $mintfirstNumber} {$layerNumber <= $mintlastNumber} {incr layerNumber} {
        lappend mintLayers "M$layerNumber"
    }
    # Check that the list was created successfully.
    if {![info exists mintLayers]} {
        error "No MINT layers generated."
    }
}

## check if cell is exsiting or not, if not create new cell ##
set emptyFlag [db::isEmpty $oaCell]
if {$emptyFlag == 1} {
    ## create new cell
    set oaCell [dm::createCell $cellName -lib $oaLib]
}

## Check layout existance and overwrite it if yes ##
if {$overWrite == 1} {
    ## check if View already exists or not ##
    set viewAlreadyExists [db::viewExists $viewName -of $oaCell]
    if {$viewAlreadyExists == 1} {
        ## update exisitng view ##
        set currentView [dm::getCellViews $viewName -cell $oaCell]
        db::destroy $currentView
        set newLayout [dm::createCellView $viewName -cell $oaCell -viewType maskLayout]
    } else {
        ## Create New View ##
        set newLayout [dm::createCellView $viewName -cell $oaCell -viewType maskLayout]
    }
} else {
    set newLayout [dm::createCellView $viewName -cell $oaCell -viewType maskLayout] 
}

########################
## set current design ##
########################
de::open $newLayout
set oaDesign [ed]

###################
## set variables ##
###################
set lefFile         [db::getPrefValue "lefFileInput"]
set boundaryLPP     "prBoundary boundary"
set fontSize        "0.2"
set labelPurpose    [db::getPrefValue "preCoverCellLabelPurpose"]

###########################################
## read lef file to extract info from it ##
###########################################
set fp [open $lefFile r]
set lines [split [read $fp] \n]
close $fp

#############################
## line by line operations ##
#############################
# Used to determine if the line in the lef belongs to pins or something else
set state "" 
set currentTerm ""
set currentPin ""
set minWidth [db::getAttr value -of [db::findConstraint minWidth -from $oaDesign -layers $miplastLayer]]
foreach line $lines {
    if {[regexp {ORIGIN (\S+) (\S+)} $line match match1 match2]} {
        set boundaryX1 $match1
        set boundaryY1 $match2
    } elseif {[regexp {SIZE (\S+) BY (\S+)} $line match match1 match2]} {
        set boundaryX2 $match1
        set boundaryY2 $match2
    } elseif {[regexp {PIN (\S+)} $line match match1]} {
        set currentPin $match1
        set state      "PIN"
        # Clear use and direction to ensure that they exist for the new pin.
        set currentUse       ""
        set currentDirection ""
        set currentTerm      ""
    } elseif {[regexp {DIRECTION (\S+)} $line match match1]} {
        set currentDirection [string tolower $match1]
        if {$currentDirection == "inout"} {
            set currentDirection "inputOutput"
        }
    } elseif {[regexp {USE (\S+)} $line match match1]} {
        set currentUse [string tolower $match1]
    } elseif {[regexp {LAYER (\S+)} $line match match1]} {
        set currentLayer $match1
    } elseif {[regexp {OBS} $line match]} {
        set state "OBS"
    } elseif {[regexp {RECT (\S+) (\S+) (\S+) (\S+)} $line match match1 match2 match3 match4]} {
        # Create the shapes for pins on MIPLAST only
        if {$state != "PIN" || $currentLayer != $inputMiplastLayer} {continue}

        set x1 $match1
        set y1 $match2
        set x2 $match3
        set y2 $match4
    
        ############################
        ## drawing MIPLAST layers ##
        ############################
        ## check the route orientation ##
        ## layout part to create pins and text label
        set lpp "$miplastLayer $labelPurpose"
        set xOrigin [expr {$x1 + ($x2-$x1)/2}]
        set yOrigin [expr {$y1 + ($y2-$y1)/2}]
        set textOrigin "$xOrigin $yOrigin"
        set Xwidth [expr {$x2 - $x1}]
        set Ywidth [expr {$y2 - $y1}]
        if { $Xwidth < $minWidth || $Ywidth < $minWidth } {
            set points "{$x1 $y1} {$x2 $y2}"
            set currentRect [le::createRectangle $points -design $oaDesign -lpp $miplastLayer -net $currentPin]
            le::convertToPath $currentRect
        } elseif { $Xwidth > $Ywidth} {
            set points "{$x1 $yOrigin} {$x2 $yOrigin}"
            set width [expr {$y2-$y1}]
            set currentPath [le::createPath $points -design $oaDesign -width $width -lpp $miplastLayer -net $currentPin]
        } else {
            set points "{$xOrigin $y1} {$xOrigin $y2}"
            set width [expr {$x2-$x1}]
            set currentPath [le::createPath $points -design $oaDesign -width $width -lpp $miplastLayer -net $currentPin]
        }
        # Create the term if this is the first time creating a shape with this
        # net.
        if {$currentTerm == ""} {
            set currentTerm [le::createTerm  -net $currentPin \
                                             -design $oaDesign \
                                             -type $currentDirection]
            db::setAttr currentTerm.net.sigType -value $currentUse
        }

        # Create the pin for the path.
        set pinLPP "$miplastLayer pin"
        set points "{$x1 $y1} {$x2 $y2}"
        set orient R0
        if {$Xwidth < $Ywidth} {
            set orient R90
        }
        set currentPinShape [le::createRectangle $points -design $oaDesign \
                                                         -lpp $pinLPP \
                                                         -net $currentPin]
        le::createPin -term $currentTerm -shapes $currentPinShape
        le::createLabel $currentPin -parent $currentPinShape -lpp $lpp \
                                    -origin $textOrigin -height $width \
                                    -orient $orient
    } elseif {[regexp {POLYGON (.*) ;} $line match match1]} {
    
        ############################
        ## drawing non Rect shape ##
        ############################
        set polyCoor "$match1"
        set counter 0
        set polyCoorPoints ""
        
        foreach item $polyCoor {
            set remainder [expr $counter % 2]
        
            if {$remainder == 0} {
                set point1 $item
                incr counter
            } else {
                set point2 $item
                set points "{$point1 $point2}"
                set polyCoorPoints "$polyCoorPoints $points"
                incr counter
            }
        }
        
        ## check current LPP layer for polygon drawing ##
        if {$currentLayer == $inputMiplastLayer} {
            set lpp "$miplastLayer pin"
            ## draw MIPLAST non-rect Pin ##
            le::createPolygon $polyCoorPoints -net $currentPin -design $oaDesign -lpp $lpp
            ## draw MIPLAST non-rect drawing layer##
            le::createPolygon $polyCoorPoints -net $currentPin -design $oaDesign -lpp $miplastLayer
        }
    }
}

#########################################
## Check if any shape has been created ##
#########################################
set getFiguresDepth 0
set searchFilter1 "%object.type=={Path} && %LPP.lpp=={$miplastLayer drawing}"
set searchFilter2 "%object.type=={Polygon} && %LPP.lpp=={$miplastLayer drawing}"

set miplastItems1 [de::getFigures -design $oaDesign -depth $getFiguresDepth -partial false -filter $searchFilter1]
set miplastItems2 [de::getFigures -design $oaDesign -depth $getFiguresDepth -partial false -filter $searchFilter2]

## check empty selection or not
set isEmptyFlag "[expr [db::isEmpty $miplastItems1] && [db::isEmpty $miplastItems2]]"
if {$isEmptyFlag == 1} {
    de::sendMessage "No MIPLAST shapes were found in the LEF." -severity "error"
    return
}

###########################
## draw prboundary shape ##
###########################
if {![info exists boundaryX1] || ![info exists boundaryX2] || \
    ![info exists boundaryY1] || ![info exists boundaryY2]} {
    de::sendMessage "Could not read the cell boundary coordinates." -severity "error"
} else {
    set boundaryPoints "{$boundaryX1 $boundaryY1} {$boundaryX2 $boundaryY2}"
    le::createRectangle $boundaryPoints -design $oaDesign -lpp $boundaryLPP
}

######################################################
## Check and Draw MINT layers and auto VIA creation ##
######################################################
## check if MINT layers are selected to be created or not
## check autoVia to be created or not



if {$mintLayersSelected == 1} {
    ## First get the minimum size for the via, later check if the
    ## path width is less than the via then skip creating MINT layers
    ## for it. Check the MINTLAST-1_MINTLASTp via as it will always be
    ## the largest one.
    set createAutoVia [db::getPrefValue "autoViaCreation"]
    if {$createAutoVia == 1} {
        set oaViaDef "[lindex $mintLayers end-1]_[lindex $mintLayers end]p"
        set origin {0 0}
        set params "{w 0.01u} {l 0.01u}"
        ######## Manual Via Creation ##########
        set testVia [le::createVia -design $oaDesign -definition $oaViaDef \
                                   -origin $origin -params $params -orient R0]
        set minViaWidth [db::getAttr w -of $testVia]
        le::delete $testVia
    }
    ## select all MIPLAST last drawing layers to replicate it for MINT layers
    ################### Current design contains MIPLAST drawing shapes to replicate for MINT layers ###################
    db::foreach item $miplastItems1 {
        ## get ATTR values of current MIPLAST path
        set currentNetName [db::getAttr object.net.name -of $item]
        set pointsForPath [db::getAttr object.points -of $item]
        set points [db::getAttr object.points -of $item]
        set width [db::getAttr object.width -of $item]

        if { $createAutoVia == 1 && $width < $minViaWidth } {
            set oaViaDef "[lindex $mintLayers end-1]_[lindex $mintLayers end]p"
            de::sendMessage "The path width is too narrow to fit $oaViaDef. This path will be skipped." \
                            -severity "error"
            puts "Path info:\n\tNet   : $currentNetName\n\tPoints: $pointsForPath\n\tWidth : $width\n\tMin Via Width: $minViaWidth"

            continue
        }
        
        foreach singleMintLayer $mintLayers {
            ## draw each MINT layer in the MINT layers
            set currentLPP "$singleMintLayer drawing"
            if { [catch {le::createPath $pointsForPath -design $oaDesign -width $width -lpp $currentLPP -net $currentNetName} err ] } {
                de::sendMessage $err -severity "error"
                puts "Path info:\n\tNet   : $currentNetName\n\tLayer : $singleMintLayer\n\tPoints: $pointsForPath\n\tWidth : $width"
            }
            
            ##############################
            ## Check to draw via or not ##
            ##############################
            if {$createAutoVia == 1} {
                ## setting Current oaVIA ##
                regexp {M(\S+)} $singleMintLayer match match1
                set singleMintLayerLower "M[expr $match1 - 1]"
                set oaViaDef "$singleMintLayerLower\_$singleMintLayer\p"
                
                ## set current Co-ordinates to get coordinates ##
                ## Setting Via Parameters ##
                regexp {\{(\S+) (\S+)\} \{(\S+) (\S+)\}} $points match x1 y1 x2 y2
                
                if {$x1 == $x2} {
                    set orient "R90"
                    set lengthOfVia $width
                    set offset [expr $width/2]
                    set newX [expr $x1 + $offset]
                    
                    if {$y1 > $y2} {
                        set widthOfVia [expr $y1 - $y2]
                        set origin "$newX $y2"
                    } else {
                        set widthOfVia [expr $y2 - $y1]
                        set origin "$newX $y1"
                    }
                    
                } else {
                    set orient "R0"
                    set lengthOfVia $width
                    set offset [expr $width/2]
                    set newY [expr $y1 - $offset]
                    
                    if {$x1 > $x2} {
                        set widthOfVia [expr $x1 - $x2]
                        set origin "$x2 $newY"
                    } else {
                        set widthOfVia [expr $x2 - $x1]
                        set origin "$x1 $newY"
                    }
                }
                set params "{w $widthOfVia\u} {l $lengthOfVia\u}"
                
                ######## Manual Via Creation ##########
                le::createVia -design $oaDesign -definition $oaViaDef -origin $origin -params $params -orient $orient

            }
        }
    }
        
    db::foreach item $miplastItems2 {
        ## get ATTR values of current MIPLAST path
        set currentNetName [db::getAttr object.net.name -of $item]
        set points [db::getAttr object.points -of $item]

        foreach singleMintLayer $mintLayers {
            ## draw each MINT layer in the MINT layers
            set currentLPP "$singleMintLayer drawing"
            le::createPolygon $points -design $oaDesign -lpp $currentLPP -net $currentNetName
        }
    }
}

########################################################
## Check Auto Via Creation and if true create autoVia ##
########################################################
set createAutoVia [db::getPrefValue "autoViaCreation"]
if {$createAutoVia == 1} {
    ################## Create auto Via option selected to generate auto Via between M drawing exisiting in current layout ##################
    le::autoVia -box $boundaryPoints -design $oaDesign -sameNetOnly 1 -allowExceed 0
}
de::save $oaDesign

####################################
## Exit Dialog Box to exit script ##
####################################

if {[expr [db::isEmpty $miplastItems2]] == 0} {
    de::sendMessage "No labels were created for the polygon pins." -severity "error"
}

################### GUI Dialog ###################
set dialog [gi::createDialog exitDialog \
-title "Status Dialog Box" \
-showApply false \
-showHelp false \
-styleSheet "abc" \
]

gi::createLabel -label "Pre-Covercell generation is complete" -parent $dialog


################################################################################
# No Linting Area
################################################################################

# nolint Main
