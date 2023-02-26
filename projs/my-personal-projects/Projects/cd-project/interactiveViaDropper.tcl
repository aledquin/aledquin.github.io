# amdPdkLoadTclFiles /home/jhiatt/p4/CircuitCad/dk/technology/generic/synopsys/tcl
source /proj/tcoe_skill/cdesigner/userUtils.tcl

# Preference definitions
# Should be defined in the CAD startup script - define them here for now
db::createPref ivdReplaceExisting -type bool -value 1
db::createPref ivdExtendPastMetal -type bool -value 1
db::createPref ivdMatchMetalWidth -type bool -value 1

namespace eval amd::interactiveViaDropper {

  # Global variable definitions
  global pdkenv
  variable viaDefinitions {Highest}
  foreach viaDef $pdkenv(vias) {
    if {[llength [split $viaDef _ ]] == 3} {
      lappend viaDefinitions $viaDef
    }
  }
  # variable metals $pdkenv(validRoutingLayers)
  variable metals {M0POLY M0DIFF2 M1 M2 M3 M4 M5 M6 M7 M8 M9 M10 M11 M12}
  variable purposes {drawing dpl1 dpl2 vbb vdd clock vddco vddh vddio vddm vddr vldt vmemio vmemp vss vssco vtt}

  # Proc that initializes the interactiveViaDropper command
  proc init {command context} {

    if {[db::getAttr context.editDesign.viewType] != "maskLayout"} {
      error "The via placer only works in a layout view"
    }

    db::setAttr command.engine -value [de::createShapeEngine -shapeType point -completeProc [list amd::interactiveViaDropper::placeVia $command $context]]
    db::setAttr command.prompt -value "Click on metal intersection to place via"
    db::setAttr command.supportsInfix -value false
  }

  proc viaDefinitionInput {window} {
    return [gi::createMutexInput viaDefinition -label "Definition" -enum $amd::interactiveViaDropper::viaDefinitions]
  }

  proc viaTypeInput {window} {
    return [gi::createMutexInput viaType -label " Type" -enum [list Auto Square Bar Large] -enabled false]
  }

  proc constraintGroupInput {window} {
    return [gi::createMutexInput constraintGroup -label " Constraint group" -viewType combo -enum [list Default] -enabled false]
  }

  proc replaceExistingInput {window} {
    return [gi::createBooleanInput replaceExisting -label "Replace existing via" -prefName ivdReplaceExisting]
  }

  proc extendPastMetalInput {window} {
    return [gi::createBooleanInput extendPastMetal -label "Extend past existing metal" -prefName ivdExtendPastMetal]
  }

  proc matchMetalWidthInput {window} {
    return [gi::createBooleanInput matchMetalWidth -label "Match metal width" -prefName ivdMatchMetalWidth]
  }

  proc space {window} {
    return [gi::createLabel -label " "]
  }

  # Proc that creates the interactiveViaDropper command
  proc registerCommand {} {
    de::createCommand amd::interactiveViaDropper -type interactive -requiresWriteMode true -category layout \
      -description "AMD Interactive Via Dropper" -label "AMD Via Dropper"

    gi::createAction viaDefinition -widgetProc amd::interactiveViaDropper::viaDefinitionInput
    gi::createAction viaType -widgetProc amd::interactiveViaDropper::viaTypeInput
    gi::createAction constraintGroup -widgetProc amd::interactiveViaDropper::constraintGroupInput
    gi::createAction space -widgetProc amd::interactiveViaDropper::space
    gi::createAction replaceExisting -widgetProc amd::interactiveViaDropper::replaceExistingInput
    gi::createAction extendPastMetal -widgetProc amd::interactiveViaDropper::extendPastMetalInput
    gi::createAction matchMetalWidth -widgetProc amd::interactiveViaDropper::matchMetalWidthInput
    gi::addActions {viaDefinition viaType constraintGroup space replaceExisting extendPastMetal matchMetalWidth} -to [gi::getToolbars amdInteractiveViaDropperOptions]
    gi::createBinding -windowType leLayout -event alt-o -command {amd::interactiveViaDropper}
  }

  # Create the interactiveViaDropper command
  amd::interactiveViaDropper::registerCommand


  ###############################################################################################################
  ## Proc        : placeVia
  ## Description : This proc gets called when the user clicks on the canvas to place a via
  ###############################################################################################################
  proc placeVia {command context engine} {

    set cv [db::getAttr editDesign -of $context]
    set point [list [lindex [db::getAttr engine.points -of $command] 0]]
 
    # Get the options from the command toolbar
    set toolbar [gi::getToolbars deCommandOptions -from [db::getAttr window -of $context]]
    set viaDefinition [db::getAttr widget.value -of [gi::getActions viaDefinition -from $toolbar]]
    set replaceExisting [db::getAttr widget.value -of [gi::getActions replaceExisting -from $toolbar]]
    set extendPastMetal [db::getAttr widget.value -of [gi::getActions extendPastMetal -from $toolbar]]
    if {$extendPastMetal == 1} {
      set extendPastMetal true
    } else {
      set extendPastMetal false
    }
    set matchMetalWidth [db::getAttr widget.value -of [gi::getActions matchMetalWidth -from $toolbar]]
    if {$matchMetalWidth == 1} {
      set matchMetalWidth true
    } else {
      set matchMetalWidth false
    }

    # Undo support
    set transaction [de::startTransaction interactiveViaDropper -design $cv]

    # Get all the potential vias that could be placed at the point
    # The proc returns a sorted (highest cut layer to lowest) list of via information
    # Each element in the list returned is another list consisting of:
    #   0. the via name
    #   1. the via's top layer name
    #   2. the via's cut layer name
    #   3. the via's bottom layer name
    #   4. the bbox of the overlap in which to place the via
    #   5. the bbox of the top layer
    #   6. the bbox of the bottom layer
    #   7. the direction of the top layer
    #   8. the direction of the bottom layer
    #   9. the width of the top layer
    #  10. the width of the bottom layer
    set status [catch {set viaIntersections [amd::interactiveViaDropper::findViaIntersections $cv $point]} result]
    if {$status != 0} {
      de::endTransaction $transaction
      return -code $status $result
    }
    if {$viaIntersections == false} {
      de::endTransaction $transaction
      return
    }

    # If the user wants to place the "Highest" possible via, loop through the list of vias checking to see
    # if there is already a via of that layer placed in the area.  If there isn't a via already placed, place
    # it.  If there is an existing via found, see if the user wants to replace it.  If the user wants to 
    # replace it, then delete the existing via and place the new one.  If the user doesn't want to replace it, 
    # move to the next via lower in the stack and repeat
    foreach viaIntersection $viaIntersections {
      set placeVia false
      set viaName  [lindex $viaIntersection 0]
      set topLayer [lindex $viaIntersection 1]
      set cutLayer [lindex $viaIntersection 2]
      set botLayer [lindex $viaIntersection 3]
      set viaBbox  [lindex $viaIntersection 4]
      set topBbox  [lindex $viaIntersection 5]
      set botBbox  [lindex $viaIntersection 6]
      set topDir   [lindex $viaIntersection 7]
      set botDir   [lindex $viaIntersection 8]
      set topWidth [lindex $viaIntersection 9]
      set botWidth [lindex $viaIntersection 10]

      if {$viaDefinition == "Highest" || $viaDefinition == $viaName} {
        # See if there is an existing via already placed
        set existingVias [de::getFigures $viaBbox -design $cv -depth 32 -touch true -filter {[amd::userUtils::getShapeLayer %this] == $cutLayer}]
        if {[db::isEmpty $existingVias]} {
          set placeVia true
          break
        }
        # See if the user wants to replace the existing via
        # Only flat shapes at the top level or vias placed at the top level will be replaced
        if {$replaceExisting} {
          set numberOfViasToDelete [db::getCount $existingVias]
          set viasToDelete {}
          db::foreach existingVia $existingVias {
            # Top level shape, save it for deletion
            if {[db::getAttr lineage.depth -of $existingVia] == 0} {
              lappend viasToDelete $existingVia
            }
            # Look for Std and Custom vias placed at the top level of hierarchy
            if {[db::getAttr lineage.depth -of $existingVia] == 1} {
              set existingViaName [db::getAttr object.design.cellName -of $existingVia]
              # Std via, save it for deletion 
              if {[string match $viaName* $existingViaName]} {
                set stdVia [lindex [lindex [db::getAttr lineage.levels -of $existingVia] 0] 0]
                lappend viasToDelete $stdVia
              }
              # Custom ppdk via, save it for deletion
              # Custom via cell names have the format botLayer_topLayerp
              # We'll get the two layers and compare them with the via we're trying to place
              set existingViaBotLayer [lindex [split $existingViaName _] 0]
              set existingViaTopLayer [lindex [split $existingViaName _] 1]
              set existingViaTopLayer [lindex [split $existingViaTopLayer p] 0]; # Get rid of the "p" at the end
              set viaBotLayer [lindex [amd::interactiveViaDropper::getViaInfoFromName $viaName] 1]
              set viaTopLayer [lindex [amd::interactiveViaDropper::getViaInfoFromName $viaName] 3]
              if {$existingViaBotLayer == $viaBotLayer && $existingViaTopLayer == $viaTopLayer} {
                set stdVia [lindex [lindex [db::getAttr lineage.levels -of $existingVia] 0] 0]
                lappend viasToDelete $stdVia
              }
            }
          }
          if {[db::getCount $existingVias] == [llength $viasToDelete]} {
            le::delete [db::createCollection $viasToDelete]
            puts "Existing vias were replaced"
            set placeVia true
            break
          } else {
            puts "Existing vias will not be replaced because they aren't at the current level of hierarchy"
            de::endTransaction $transaction
            return
          }
        } else {
          # The user doesn't want to replace existing vias
          # If the via definition is set to Highest, move on to the next via on the list
          if {$viaDefinition != "Highest"} {
            de::endTransaction $transaction
            return
          }
        }
      }
    }

    if {!$placeVia} {
      puts "Vias will not be placed. Either the intersection doesn't support the via definition chosen, or it contains existing vias that weren't replaced"
      de::endTransaction $transaction
      return
    }

    # Debug stuff
    # puts ""
    # puts "Via name: $viaName"
    # puts "Via bbox: $viaBbox"
    # puts "Cut layer: $cutLayer"
    # puts "Top layer: $topLayer"
    # puts "Top layer bbox: $topBbox"
    # puts "Top layer direction: $topDir"
    # puts "Top layer width: $topWidth"
    # puts "Bot layer: $botLayer"
    # puts "Bot layer bbox: $botBbox"
    # puts "Bot layer direction: $botDir"
    # puts "Bot layer width: $botWidth"
    # puts ""
    # le::createRectangle $viaBbox -design $cv -lpp "hilite drawing1"
    # le::createRectangle $topBbox -design $cv -lpp "hilite drawing2"
    # le::createRectangle $botBbox -design $cv -lpp "hilite drawing3"

    if {[info proc ::amdPdkCreateStdViaByBbox] != ""} {
      set createStdViaByBbox amdPdkCreateStdViaByBbox
    } else {
      set createStdViaByBbox fto::createStdViaByBbox
    }
    set status [catch {$createStdViaByBbox \
      -cvid $cv \
      -viaName  $viaName \
      -bbox     $viaBbox \
      -topBbox  $topBbox \
      -botBbox  $botBbox \
      -topDir   $topDir \
      -botDir   $botDir \
      -topWidth $topWidth \
      -botWidth $botWidth \
      -pastExistingMetals $extendPastMetal \
      -matchWidths $matchMetalWidth \
      -toolUsingStdViaCode "interactiveViaDropper" \
      } result \
    ]
    if {$status != 0} {
      de::endTransaction $transaction
      return -code $status $result
    }

    # Undo support
    de::endTransaction $transaction
  }


  ###############################################################################################################
  ## Proc        : findViaIntersections
  ## Description : Returns a list of all the potential via locations based on metal overlaps at the given point
  ##               Each element of the list is a list consisting of:
  ##               {viaName topLayer cutLayer botLayer viaBbox topLayerBbox botLayerBbox topLayerDirection 
  ##               botLayerDirection topLayerWidth botLayerWidth}
  ###############################################################################################################
  proc findViaIntersections {cv point} {

    set viaIntersections {}

    # Get any metal shapes under the given point
    # The result will be a list of lists sorted from highest layer to lowest
    # [list [list layer objectType points width] [list layer objectType points width] ...]
    set metalShapesFound [amd::interactiveViaDropper::getMetalsUnderPoint $cv $point]
    if {$metalShapesFound == {}} {
      de::sendMessage "No visible metal shapes found at $point" -severity information
      return false
    }

    # Get a list of all the unique metal layers for the shapes found
    # These will be sorted in decreasing order from highest to lowest
    set metalLayersFound {}
    foreach metalShape $metalShapesFound {
      lappend metalLayersFound [lindex $metalShape 0]
    }
    set metalLayersFound [lsort -dictionary -decreasing -unique $metalLayersFound]

    # Go through the metal layers for the shapes that were found 
    foreach metalLayer $metalLayersFound {

      # Get the next lower layer on the list
      set lowerLayer [amd::userUtils::getNextElement $amd::interactiveViaDropper::metals $metalLayer -]

      # There are 2 layers lower than M1: M0DIFF2 and M0POLY
      # See if either were found
      if {$lowerLayer == "M0DIFF2" && [lsearch $metalLayersFound $lowerLayer] == -1} {
        set lowerLayer M0POLY
      }
 
      # See if we found a metal shape on the layer directly below this one
      # This means we found two overlapping shapes on adjacent layers
      if {$lowerLayer != -1 && [lsearch $metalLayersFound $lowerLayer] != -1} {

        # Get the overlap of the shapes on this layer and the lower layer
        set viaIntersection [amd::interactiveViaDropper::getOverlap $cv $point $metalLayer $lowerLayer $metalShapesFound]
        lappend viaIntersections $viaIntersection
      }
    }

    if {$viaIntersections == {}} {
      de::sendMessage "No valid visible metal intersections found at $point" -severity information
      return false
    } else {
      return $viaIntersections
    } 
  }


  ###############################################################################################################
  ## Proc        : getMetalsUnderPoint
  ## Description : This proc searches through the hierarchy for shapes on metal layers under the given point
  ##               and returns a list of the shape's layer, type, transformed points, and width
  ##
  ##               A couple of rules:
  ##                 1. The hierarchy depth to search is based on the window's stop level
  ##                 2. The lpp being searched for needs to be visible
  ##                 3. The metal layer being searched for needs to be a member of the amd::interactiveViaDropper::metals list
  ##                 4. The metal purpose being searched for needs to be a member of the amd::interactiveViaDropper::purposes list
  ###############################################################################################################
  proc getMetalsUnderPoint {cv point} {

    set shapesInHier {}

    # Get a collection of visible metal shapes in the hierarchy under the point
    set shapes [de::getFigures $point -design $cv -depth [db::getPrefValue leStopLevel -scope [de::getActiveContext]] \
      -filter { \
        (%object.type == "Rect" || %object.type == "Path" || %object.type == "Polygon" || %object.type == "PathSeg") && \
        [lsearch $amd::interactiveViaDropper::metals [amd::userUtils::getShapeLayer %this]] != -1 && \
        [lsearch $amd::interactiveViaDropper::purposes [amd::userUtils::getShapePurpose %this]] != -1 && \
        [amd::userUtils::isShapeVisible $cv %this] \
      }
    ]

    db::foreach shape $shapes {
      set object [db::getAttr object -of $shape]
      set objectType [db::getAttr type -of $object]
      set objectTransform [db::getAttr lineage.transform -of $shape]
      set layer [amd::userUtils::getShapeLayer $shape]

      switch $objectType {
        "Rect" {
          set points [amd::userUtils::transformBbox [db::getAttr object.bBox -of $shape] $objectTransform]
          set width ""
        }
        "PathSeg" {
          set points [amd::userUtils::transformPoints [db::getAttr object.points -of $shape] $objectTransform]
          set width [db::getAttr object.width -of $shape]
        }
        "Path" {
          set points [amd::userUtils::transformPoints [db::getAttr object.points -of $shape] $objectTransform]
          set width [db::getAttr object.width -of $shape]
        }
        "Polygon" {
          set points [amd::userUtils::transformPoints [db::getAttr object.points -of $shape] $objectTransform]
          set width ""
        }
      }

      lappend shapesInHier [list $layer $objectType $points $width]
    }

    # Put the list of shapes in decreasing order from highest metal to lowest
    set shapesInHier [lsort -dictionary -decreasing -index 0 $shapesInHier]

    return $shapesInHier
  }
 

  ###############################################################################################################
  ## Proc        : getOverlap
  ## Description : This proc determines the overlap of shapes on two adjacent layers
  ##               Returns a list: {viaName topLayer cutLayer botLayer viaBbox topLayerBbox botLayerBbox 
  ##               topLayerDirection botLayerDirection topLayerWidth botLayerWidth}
  ###############################################################################################################
  proc getOverlap {cv point topLayer botLayer shapes} {

    global pdkenv
    set tempShapes {}
    set polygonShapes {}
    set viaName  [lindex [amd::interactiveViaDropper::getViaInfoFromLayers $botLayer $topLayer] 0]
    set cutLayer [lindex [amd::interactiveViaDropper::getViaInfoFromLayers $botLayer $topLayer] 2]

    # Create temp shapes on the top and bottom layers at the top level of hierarchy
    # These shapes will all be created with the drawing purpose
    foreach layer [list $topLayer $botLayer] {
      foreach shape $shapes {
        set shapeLayer [lindex $shape 0]
        set type    [lindex $shape 1]
        set points  [lindex $shape 2]
        set width   [lindex $shape 3]
        if {$layer == $shapeLayer} {
          switch $type {
            "Rect"    {lappend tempShapes [le::createRectangle $points -design $cv -lpp $shapeLayer]}
            "PathSeg" {lappend tempShapes [le::createPathSeg $points -design $cv -lpp $shapeLayer -width $width]}
            "Path"    {lappend tempShapes [le::createPath $points -design $cv -lpp $shapeLayer -width $width]}
            "Polygon" {lappend tempShapes [le::createPolygon $points -design $cv -lpp $shapeLayer]}
          }
        }
      }
    }

    # Merge all of the temp shapes with the same layer together and convert them to polygons
    set mergedShapes [le::merge [db::createCollection $tempShapes]]
    db::foreach shape $mergedShapes {
      if {[db::getAttr type -of $shape] != "Polygon"} {
        lappend polygonShapes [db::getNext [le::convertToPolygon $shape]]
      } else {
        lappend polygonShapes $shape
      }
    }
    set polygonShapes [db::createCollection $polygonShapes]

    # And the two polygon shapes together to get the overlap of the top and bottom layers 
    set overlaps [le::generateShapes $polygonShapes -lpp "hilite drawing1" -lpp1 "$topLayer drawing" -lpp2 "$botLayer drawing" -operation and]

    # If there are multiple overlaps, only get the one under the point
    db::foreach overlap $overlaps {
      if {[oa::contains [oa::getPoints $overlap] [oa::Point [lindex $point 0]] 1]} {
        break
      }
    }

    # Need to make sure the overlap is a rectangle
    if {[db::getAttr numPoints -of $overlap] == 4} {
      set viaBbox [db::getAttr bBox -of $overlap]
    } else { 
      # The overlap is a wierd shape (not a simple rectangle)
      # Convert it to a bunch of rectangles and find the largest one under the point clicked on
      set boxListsX [le::splitIntoBoxes $overlap -type maxX]
      set boxListsY [le::splitIntoBoxes $overlap -type maxY]
      set boxListsT [concat $boxListsX $boxListsY]
      set boxesUnderPoint {}
      foreach boxList $boxListsT {
        set boxBbox [list [list [lindex $boxList 0] [lindex $boxList 1]] [list [lindex $boxList 2] [lindex $boxList 3]]]
        if {[amd::userUtils::isPointInsideBbox [lindex $point 0] $boxBbox]} {
          lappend boxesUnderPoint $boxBbox
        }
      }
      # Now find the biggest one
      # There will be only two boxes under the point, one for maxX and one for maxY
      set box1 [lindex $boxesUnderPoint 0]
      set boxArea1 [expr [amd::userUtils::getWidth $box1]*[amd::userUtils::getHeight $box1]]
      set box2 [lindex $boxesUnderPoint 1]
      set boxArea2 [expr [amd::userUtils::getWidth $box2]*[amd::userUtils::getHeight $box2]]
      if {$boxArea1 >= $boxArea2} {
        set viaBbox $box1
      } else {
        set viaBbox $box2
      }
    }

    # Determine the directions and widths of the metal shapes
    db::foreach shape $polygonShapes {
      # If the metal shape has 4 points (a rectangle), this is easy - just use the bbox of the shape
      if {[db::getAttr numPoints -of $shape] == 4} {
        set bbox [db::getAttr bBox -of $shape]
      } else {
        # The shape is not a rectangle.  
        # Grow the overlap in the direction of the metal until we either hit the max overlap rule for the via or go outside of the metal
        # The overlap is a rectangle and can then be used to determine the metal direction after it's been grown
        if {[info proc ::amdPdkGetViaMaxMetalOverlap] != ""} {
          set getViaMaxMetalOverlap amdPdkGetViaMaxMetalOverlap
        } else {
          set getViaMaxMetalOverlap fto::getViaMaxMetalOverlap
        }
        set maxOverlap [$getViaMaxMetalOverlap -viaName $viaName -botLayer 1 -topLayer 1]
        set bbox [amd::interactiveViaDropper::growOverlap $viaBbox $shape  $maxOverlap]
      }

      # Top Layer
      if {[amd::userUtils::getShapeLayer $shape] == $topLayer} {
        set topLayerBbox $bbox
        if {[amd::userUtils::isBboxHorizontal $bbox]} {
          set topLayerDirection horizontal
          set topLayerWidth [amd::userUtils::getHeight $bbox]
        } else {
          set topLayerDirection vertical
          set topLayerWidth [amd::userUtils::getWidth $bbox]
        }
      }

      # Bottom Layer
      if {[amd::userUtils::getShapeLayer $shape] == $botLayer} {
        set botLayerBbox $bbox
        if {[amd::userUtils::isBboxHorizontal $bbox]} {
          set botLayerDirection horizontal
          set botLayerWidth [amd::userUtils::getHeight $bbox]
        } else {
          set botLayerDirection vertical
          set botLayerWidth [amd::userUtils::getWidth $bbox]
        }
      }
    }

    # Remove all of the temp shapes that were created
    le::delete $polygonShapes
    le::delete $overlaps

    return [list $viaName $topLayer $cutLayer $botLayer $viaBbox $topLayerBbox $botLayerBbox \
                 $topLayerDirection $botLayerDirection $topLayerWidth $botLayerWidth \
           ]
  }


  ###############################################################################################################
  ## Proc        : growOverlap
  ## Description : This proc will grow the edges of a bbox by a grid increment
  ##               until it either falls outside of the points of the shape passed in
  ##               or is grown more than the max amount passed in
  ###############################################################################################################
  proc growOverlap {bbox shape max} {

    global pdkenv
    set grid $pdkenv(grid)

    array set edgeOffsets {left 0 bot 0 right 0 top 0}
    foreach edge [array names edgeOffsets] {
      # Reset the offsets to 0 and then increment the one we're working on
      set tempBbox $bbox
      set amountGrown 0
      set edgeOffsets(left) 0
      set edgeOffsets(bot) 0
      set edgeOffsets(right) 0
      set edgeOffsets(top) 0
      set edgeOffsets($edge) $grid
      while {1} {
        # Grow the edge of the bbox by a grid
        set tempBbox [amd::userUtils::sizeBbox $tempBbox $edgeOffsets(left) $edgeOffsets(bot) $edgeOffsets(right) $edgeOffsets(top)]
        set amountGrown [expr $amountGrown + $grid]
        # See if the bbox still lies inside the shape passed in
        set tempOaBox [oa::Box [lindex $tempBbox 0 0] [lindex $tempBbox 0 1] [lindex $tempBbox 1 0] [lindex $tempBbox 1 1]]
        if {[oa::contains [oa::getPoints $shape] $tempOaBox] && $amountGrown <= $max} {
          # The growth looks good, save it
          set bbox $tempBbox
        } else {
          break
        }
      }
    }

    return $bbox
  }


  ###############################################################################################################
  ## Proc        : getViaInfoFromLayers
  ## Description : Given a bottom and top layer, return the matching via information or false if a via can't be determined
  ##               The output is returned as a list: {viaName bottomLayer cutLayer topLayer}
  ###############################################################################################################
  proc getViaInfoFromLayers {bottomLayer topLayer} {
    global pdkenv

    foreach viaInfo $pdkenv(stdViaInfo) {
      set viaName [lindex $viaInfo 0]
      set viaBotLayer [lindex $viaInfo 1]
      set viaCutLayer [lindex $viaInfo 2]
      set viaTopLayer [lindex $viaInfo 3]
      if {$bottomLayer == $viaBotLayer && $topLayer == $viaTopLayer} {
        return [list $viaName $viaBotLayer $viaCutLayer $viaTopLayer]
      }
    }
    return false
  }

  ###############################################################################################################
  ## Proc        : getViaInfoFromName
  ## Description : Given a via name, return the matching via information or false if a via can't be determined
  ##               The output is returned as a list: {viaName bottomLayer cutLayer topLayer}
  ###############################################################################################################
  proc getViaInfoFromName {name} {
    global pdkenv

    foreach viaInfo $pdkenv(stdViaInfo) {
      set viaName [lindex $viaInfo 0]
      set viaBotLayer [lindex $viaInfo 1]
      set viaCutLayer [lindex $viaInfo 2]
      set viaTopLayer [lindex $viaInfo 3]
      if {$name == $viaName} {
        return [list $viaName $viaBotLayer $viaCutLayer $viaTopLayer]
      }
    }
    return false
  }

}

