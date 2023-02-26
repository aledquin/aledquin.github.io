###############################################################################################################
## 
##  userUtils.tcl
## 
##  This file contains the following procedures:
## 
##  calculateBboxUnion        - returns the union of the bboxes passed in
##  lowerLeft                 - returns the lower left point of the bbox passed in
##  lowerRight                - returns the lower right point of the bbox passed in
##  upperLeft                 - returns the upper left point of the bbox passed in
##  upperRight                - returns the upper right point of the bbox passed in
##  centerBox                 - returns the point in the center of the bbox passed in
##  leftEdge                  - returns the x coord of the left edge of the bbox passed in
##  rightEdge                 - returns the x coord of the right edge of the bbox passed in
##  bottomEdge                - returns the y coord of the bottom edge of the bbox passed in
##  topEdge                   - returns the y coord of the top edge of the bbox passed in
##  getWidth                  - returns the width of the bbox passed in
##  getHeight                 - returns the height of the bbox passed in
##  isBboxHorizontal          - returns true if the bbox is horizontal or false if it isn't
##  isBboxVertical            - returns true if the bbox is vertical or false if it isn't
##  xCoord                    - returns the x coord of the point passed in
##  yCoord                    - returns the y coord of the point passed in
##  sizeBbox                  - sizes the bbox edges by the amounts passed in
##  convertBboxToPoints       - returns a list of points of the bbox passed in
##  getPolygonEdges           - returns a list of edges for the given points of a polygon
##  getVerticalPolygonEdges   - returns a list of vertical edges for the given points of a polygon
##  getHorizontalPolygonEdges - returns a list of horizontal edges for the given points of a polygon
##  isPointInsideBbox         - returns true if the point touches or is inside the bbox passed in or false if it isn't
##  isPointFullyInsidePolygon - returns true if the point is fully inside the polygon's points passed in or false if it isn't
##  isPointOnPolygonEdge      - returns true if the point touches an edge of the polygon or false if it doesn't
##  isEdgeCutByPolygon        - returns true if the edge is cut by one of the polygon's edges or false if it isn't
##  isEdgeInsidePolygon       - returns true if the edge touches or is inside the polygon's points or false if isn't
##  isPolygonInsidePolygon    - returns true if the polygon's points all touch or are inside the other's points or false if they're not
##  transformBbox             - returns the bbox adjusted by the transform
##  transformPoints           - returns a list of points adjusted by the transform
##  roundToGrid               - returns a number rounded to the grid
##  getSelectedObjects        - returns a unique collection of the selected objects
##  isSelected                - returns true if the given object is selected or false if it isn't
##  getParent                 - returns the object's parent object or -1 if the object doesn't have a parent
##  max                       - returns the max number from the numbers passed in
##  min                       - returns the min number from the numbers passed in
##  getActiveCellView         - returns the active cell view or -1 if an error occurs
##  openCellView              - opens a cellview for read or write.  Returns the cell view or -1 if an error occurs
##  createCellView            - creates a particular cellview. If it exists it will be overwritten
##  getCellsInHier            - returns the cell views in the hierarchy of the design
##  getLibsInHier             - returns the library names used in the hierarchy of the design
##  getPrBoundary             - returns the prBoundary for the cell or -1 if it doesn't exist
##  getTechFile               - returns the OA tech file pointer
##  getShapeLayer             - returns the layer name of the given shape
##  getShapePurpose           - returns the purpose name of the given shape
##  getShapeLpp               - returns the lpp of the given shape
##  isShapeOnLayer            - returns true if the given shape is on the given layer or false if it isn't
##  isShapeOnPurpose          - returns true if the given shape is on the given purpose or false if it isn't
##  isShapeOnLpp              - returns true if the given shape is on the given lpp or false if it isn't
##  isShapeVisible            - returns true if the given shape is visible or false if it isn't
##  getNextElement            - finds an element in a list and returns either the prior element or the next one
##  displayDialog             - displays a dialog of the type passed in (question, information, warning, error)
##  createGDS                 - runs the exportStream script to generate a GDS
## 
##  Procedures are wrapped in the namespace called: amd::userUtils
##  To call a procedure: amd::userUtils::procedureName arg
##
##  Procedures should return a -1 if an error occurs or if the item asked for can't be found
##
##  Author: Marc Tareila marc.tareila@amd.com x28586
##
###############################################################################################################

namespace eval amd::userUtils {

  ###############################################################################################################
  ## Proc        : calculateBboxUnion
  ## Description : returns the union of the bboxes passed in
  ###############################################################################################################
  proc calculateBboxUnion {bboxes} {

    set llx [amd::userUtils::leftEdge [lindex $bboxes 0]]
    set lly [amd::userUtils::bottomEdge [lindex $bboxes 0]]
    set urx [amd::userUtils::rightEdge [lindex $bboxes 0]]
    set ury [amd::userUtils::topEdge [lindex $bboxes 0]]

    foreach bbox [lrange $bboxes 1 end] {
      set llx [amd::userUtils::min $llx [amd::userUtils::leftEdge $bbox]]
      set lly [amd::userUtils::min $lly [amd::userUtils::bottomEdge $bbox]]
      set urx [amd::userUtils::max $urx [amd::userUtils::rightEdge $bbox]]
      set ury [amd::userUtils::max $ury [amd::userUtils::topEdge $bbox]]
    }

    return [list [list $llx $lly] [list $urx $ury]]
  }

  ###############################################################################################################
  ## Proc        : lowerLeft
  ## Description : returns the lower left point of the bbox passed in
  ###############################################################################################################
  proc lowerLeft {bbox} {
    set x0 [amd::userUtils::xCoord [lindex $bbox 0]]
    set x1 [amd::userUtils::xCoord [lindex $bbox 1]]
    set y0 [amd::userUtils::yCoord [lindex $bbox 0]]
    set y1 [amd::userUtils::yCoord [lindex $bbox 1]]

    
    if {$x1 < $x0} {
      set x0 $x1
    }
    if {$y1 < $y0} {
      set y0 $y1
    }

    return [list $x0 $y0]
  }

  ###############################################################################################################
  ## Proc        : lowerRight
  ## Description : returns the lower right point of the bbox passed in
  ###############################################################################################################
  proc lowerRight {bbox} {
    return [list [amd::userUtils::rightEdge $bbox] [amd::userUtils::bottomEdge $bbox]]
  }

  ###############################################################################################################
  ## Proc        : upperLeft
  ## Description : returns the upper left point of the bbox passed in
  ###############################################################################################################
  proc upperLeft {bbox} {
    return [list [amd::userUtils::leftEdge $bbox] [amd::userUtils::topEdge $bbox]]
  }

  ###############################################################################################################
  ## Proc        : upperRight
  ## Description : returns the upper right point of the bbox passed in
  ###############################################################################################################
  proc upperRight {bbox} {
    set x0 [amd::userUtils::xCoord [lindex $bbox 0]]
    set x1 [amd::userUtils::xCoord [lindex $bbox 1]]
    set y0 [amd::userUtils::yCoord [lindex $bbox 0]]
    set y1 [amd::userUtils::yCoord [lindex $bbox 1]]

    if {$x1 < $x0} {
      set x1 $x0
    }
    if {$y1 < $y0} {
      set y1 $y0
    }

    return [list $x1 $y1]
  }

  ###############################################################################################################
  ## Proc        : centerBox
  ## Description : returns the point in the center of the bbox passed in
  ###############################################################################################################
  proc centerBox {bbox} {
    return [list [amd::userUtils::roundToGrid [expr ([amd::userUtils::leftEdge $bbox] + [amd::userUtils::rightEdge $bbox]) / 2.0]] \
                 [amd::userUtils::roundToGrid [expr ([amd::userUtils::bottomEdge $bbox] + [amd::userUtils::topEdge $bbox]) / 2.0]]
    ]
  }

  ###############################################################################################################
  ## Proc        : leftEdge
  ## Description : returns the x coord of the left edge of the bbox passed in
  ###############################################################################################################
  proc leftEdge {bbox} {
    return [amd::userUtils::xCoord [amd::userUtils::lowerLeft $bbox]]
  }

  ###############################################################################################################
  ## Proc        : rightEdge
  ## Description : returns the x coord of the right edge of the bbox passed in
  ###############################################################################################################
  proc rightEdge {bbox} {
    return [amd::userUtils::xCoord [amd::userUtils::upperRight $bbox]]
  }

  ###############################################################################################################
  ## Proc        : bottomEdge
  ## Description : returns the y coord of the bottom edge of the bbox passed in
  ###############################################################################################################
  proc bottomEdge {bbox} {
    return [amd::userUtils::yCoord [amd::userUtils::lowerLeft $bbox]]
  }

  ###############################################################################################################
  ## Proc        : topEdge
  ## Description : returns the y coord of the top edge of the bbox passed in
  ###############################################################################################################
  proc topEdge {bbox} {
    return [amd::userUtils::yCoord [amd::userUtils::upperRight $bbox]]
  }

  ###############################################################################################################
  ## Proc        : getWidth
  ## Description : returns the width of the bbox passed in
  ###############################################################################################################
  proc getWidth {bbox} {
    return [expr [amd::userUtils::rightEdge $bbox] - [amd::userUtils::leftEdge $bbox]]
  }

  ###############################################################################################################
  ## Proc        : getHeight
  ## Description : returns the height of the bbox passed in
  ###############################################################################################################
  proc getHeight {bbox} {
    return [expr [amd::userUtils::topEdge $bbox] - [amd::userUtils::bottomEdge $bbox]]
  }

  ###############################################################################################################
  ## Proc        : isBboxHorizontal
  ## Description : returns true if the bbox is horizontal or false if it isn't
  ###############################################################################################################
  proc isBboxHorizontal {bbox} {
    if {[amd::userUtils::getWidth $bbox] >= [amd::userUtils::getHeight $bbox]} {
      return true
    } else {
      return false
    }
  }

  ###############################################################################################################
  ## Proc        : isBboxVertical
  ## Description : returns true if the bbox is vertical or false if it isn't
  ###############################################################################################################
  proc isBboxVertical {bbox} {
    if {[amd::userUtils::getHeight $bbox] >= [amd::userUtils::getWidth $bbox]} {
      return true
    } else {
      return false
    }
  }

  ###############################################################################################################
  ## Proc        : xCoord
  ## Description : returns the x coord of the point passed in
  ###############################################################################################################
  proc xCoord {point} {
    return [amd::userUtils::roundToGrid [lindex $point 0]]
  }

  ###############################################################################################################
  ## Proc        : yCoord
  ## Description : returns the y coord of the point passed in
  ###############################################################################################################
  proc yCoord {point} {
    return [amd::userUtils::roundToGrid [lindex $point 1]]
  }

  ###############################################################################################################
  ## Proc        : sizeBbox
  ## Description : sizes the bbox edges by the amounts passed in
  ###############################################################################################################
  proc sizeBbox {bbox left bot right top} {
    set lowerLeft [amd::userUtils::lowerLeft $bbox]
    set upperRight [amd::userUtils::upperRight $bbox]
    set x0 [amd::userUtils::xCoord $lowerLeft]
    set x1 [amd::userUtils::xCoord $upperRight]
    set y0 [amd::userUtils::yCoord $lowerLeft]
    set y1 [amd::userUtils::yCoord $upperRight]

    return [list [list [expr $x0-$left] [expr $y0-$bot]] \
                 [list [expr $x1+$right] [expr $y1+$top]] \
           ]
  }

  ###############################################################################################################
  ## Proc        : convertBboxToPoints
  ## Description : returns a list of points of the bbox passed in
  ###############################################################################################################
  proc convertBboxToPoints {bbox} {
    return [list [amd::userUtils::lowerLeft $bbox] \
                 [amd::userUtils::lowerRight $bbox] \
                 [amd::userUtils::upperRight $bbox] \
                 [amd::userUtils::upperLeft $bbox] \
           ]
  }

  ###############################################################################################################
  ## Proc        : getPolygonEdges
  ## Description : returns a list of edges for the given points of a polygon
  ###############################################################################################################
  proc getPolygonEdges {points} {
    set polygon [list]

    # Flatten the list of points into a single list of x y pairs
    foreach point $points {
      set polygon [concat $polygon [amd::userUtils::xCoord $point] [amd::userUtils::yCoord $point]]
    }

    set x0 [lindex $polygon 0 ]
    set y0 [lindex $polygon 1 ]
    foreach {x1 y1} [lrange [lappend polygon $x0 $y0] 2 end] {
      # Sort the X and Y coords: sx0=left sx1=right sy0=bottom sy1=top
      set sx0 $x0
      set sx1 $x1
      set sy0 $y0
      set sy1 $y1
      if {$sx0 > $sx1} {
        set tmp $sx0
        set sx0 $sx1
        set sx1 $tmp
      }
      if {$sy0 > $sy1} {
        set tmp $sy0
        set sy0 $sy1
        set sy1 $tmp
      }
      lappend edges [list [list $sx0 $sy0] [list $sx1 $sy1]]
      set x0 $x1
      set y0 $y1
    }
    return $edges
  }

  ###############################################################################################################
  ## Proc        : getVerticalPolygonEdges
  ## Description : returns a list of vertical edges for the given points of a polygon
  ###############################################################################################################
  proc getVerticalPolygonEdges {points} {
    set verticalEdges [list]

    foreach edge [amd::userUtils::getPolygonEdges $points] {
      set x0 [amd::userUtils::xCoord [lindex $edge 0]]
      set x1 [amd::userUtils::xCoord [lindex $edge 1]]
      set y0 [amd::userUtils::yCoord [lindex $edge 0]]
      set y1 [amd::userUtils::yCoord [lindex $edge 1]]

      # The xCoords of a vertical edge are equal
      if {$x0 == $x1} {
        lappend verticalEdges [list [list $x0 $y0] [list $x1 $y1]]
      }
    }

    return $verticalEdges
  }

  ###############################################################################################################
  ## Proc        : getHorizontalPolygonEdges
  ## Description : returns a list of horizontal edges for the given points of a polygon
  ###############################################################################################################
  proc getHorizontalPolygonEdges {points} {
    set horizontalEdges [list]

    foreach edge [amd::userUtils::getPolygonEdges $points] {
      set x0 [amd::userUtils::xCoord [lindex $edge 0]]
      set x1 [amd::userUtils::xCoord [lindex $edge 1]]
      set y0 [amd::userUtils::yCoord [lindex $edge 0]]
      set y1 [amd::userUtils::yCoord [lindex $edge 1]]

      # The yCoords of a horizontal edge are equal
      if {$y0 == $y1} {
        lappend horizontalEdges [list [list $x0 $y0] [list $x1 $y1]]
      }
    }

    return $horizontalEdges
  }

  ###############################################################################################################
  ## Proc        : isPointInsideBbox
  ## Description : returns true if the point touches or is inside the bbox passed in or false if it isn't
  ###############################################################################################################
  proc isPointInsideBbox {point bbox} {
    if {[amd::userUtils::xCoord $point] >= [amd::userUtils::leftEdge $bbox] && \
        [amd::userUtils::xCoord $point] <= [amd::userUtils::rightEdge $bbox] && \
        [amd::userUtils::yCoord $point] >= [amd::userUtils::bottomEdge $bbox] && \
        [amd::userUtils::yCoord $point] <= [amd::userUtils::topEdge $bbox]} {
      return true
    } else {
      return false
    }
  }

  ###############################################################################################################
  ## Proc        : isPointFullyInsidePolygon
  ## Description : returns true if the point is inside the polygon's points passed in or false if it isn't
  ##               If the point touches the polygon, return false
  ##               This uses the ray algorithm
  ##               If the ray drawn from the point cuts the polygon edges an even number of times, 
  ##               the point is outside the polygon, otherwise the point is inside the polygon.
  ##               In this code we are drawing the ray in the right direction,
  ##               i.e. if a point is on the left of the polygon edge, the ray will hit the edge.
  ###############################################################################################################
  proc isPointFullyInsidePolygon {point points} {
    set sidesCut 0
    set xp [amd::userUtils::xCoord $point]
    set yp [amd::userUtils::yCoord $point]

    foreach edge [amd::userUtils::getPolygonEdges $points] {

      # Return false if the point is on the edge
      if {[amd::userUtils::isPointOnPolygonEdge $point $edge]} {
        return false
      }

      set x0 [amd::userUtils::xCoord [lindex $edge 0]]
      set x1 [amd::userUtils::xCoord [lindex $edge 1]]
      set y0 [amd::userUtils::yCoord [lindex $edge 0]]
      set y1 [amd::userUtils::yCoord [lindex $edge 1]]

      # Vertical edge
      if {$x0 == $x1} {
        # See if the yCoord of the point falls within the yCoords of the vertical edge
        if {($yp >= $y0) && ($yp < $y1)} {
          # See if the ray hits the edge
          if {$xp < $x0} {
            incr sidesCut
          }
        }
      }
    }

    return [expr {$sidesCut % 2}]
  }

  ###############################################################################################################
  ## Proc        : isPointOnPolygonEdge
  ## Description : returns true if the point touches an edge of the polygon or false if it doesn't
  ###############################################################################################################
  proc isPointOnPolygonEdge {point points} {
    set xp [amd::userUtils::xCoord $point]
    set yp [amd::userUtils::yCoord $point]

    foreach edge [amd::userUtils::getPolygonEdges $points] {
      set x0 [amd::userUtils::xCoord [lindex $edge 0]]
      set x1 [amd::userUtils::xCoord [lindex $edge 1]]
      set y0 [amd::userUtils::yCoord [lindex $edge 0]]
      set y1 [amd::userUtils::yCoord [lindex $edge 1]]

      # Vertical edge
      if {$x0 == $x1} {
        # The xCoord of the point has to be the same as the xCoord of the edge
        # The yCoord of the point has to be somewhere within the yCoords of the edge
        if {($xp == $x0) && ($yp >= $y0) && ($yp <= $y1)} { 
          return true
        }

      # Horizontal edge
      } else {
        # The yCoord of the point has to be the same as the yCoord of the edge
        # The xCoord of the point has to be somewhere within the xCoords of the edge
        if {($yp == $y0) && ($xp >= $x0) && ($xp <= $x1)} {
          return true
        }
      }
    }
    return false
  }
 
  ###############################################################################################################
  ## Proc        : isEdgeCutByPolygon
  ## Description : returns true if the edge is cut by one of the polygon's edges or false if it isn't
  ###############################################################################################################
  proc isEdgeCutByPolygon {edge points} {

    set x0 [amd::userUtils::xCoord [lindex $edge 0]]
    set x1 [amd::userUtils::xCoord [lindex $edge 1]]
    set y0 [amd::userUtils::yCoord [lindex $edge 0]]
    set y1 [amd::userUtils::yCoord [lindex $edge 1]]
    set horizontalPolygonEdges [amd::userUtils::getHorizontalPolygonEdges $points]
    set verticalPolygonEdges [amd::userUtils::getVerticalPolygonEdges $points]

    # The edge passed in is vertical
    if {$x0 == $x1} {
      # Consider only horizontal edges of the polygon
      foreach horizontalPolygonEdge $horizontalPolygonEdges {
        set px0 [amd::userUtils::xCoord [lindex $horizontalPolygonEdge 0]]
        set px1 [amd::userUtils::xCoord [lindex $horizontalPolygonEdge 1]]
        set py0 [amd::userUtils::yCoord [lindex $horizontalPolygonEdge 0]]
        if {($x0 > $px0) && ($x0 < $px1) && ($y0 < $py0) && ($y1 > $py0)} {
          return true
        }
      }

    # The edge passed in is horizontal
    } else {
      # Consider only vertical edges of the polygon
      foreach verticalPolygonEdge $verticalPolygonEdges {
        set px0 [amd::userUtils::xCoord [lindex $verticalPolygonEdge 0]]
        set py0 [amd::userUtils::yCoord [lindex $verticalPolygonEdge 0]]
        set py1 [amd::userUtils::yCoord [lindex $verticalPolygonEdge 1]]
        if {($x0 < $px0) && ($x1 > $px0) && ($y0 > $py0) && ($y0 < $py1)} {
          return true
        }
      }
    }

    return false
  }

  ###############################################################################################################
  ## Proc        : isEdgeInsidePolygon
  ## Description : returns true if the edge touches or is inside the polygon's points or false if isn't
  ###############################################################################################################
  proc isEdgeInsidePolygon {edge points} {

    set pt1 [lindex $edge 0]
    set pt2 [lindex $edge 1]

    if {(![amd::userUtils::isPointOnPolygonEdge $pt1 $points]) && (![amd::userUtils::isPointFullyInsidePolygon $pt1 $points])} {
      return false
    }
    if {(![amd::userUtils::isPointOnPolygonEdge $pt2 $points]) && (![amd::userUtils::isPointFullyInsidePolygon $pt2 $points])} {
      return false
    }
    if {[amd::userUtils::isEdgeCutByPolygon $edge $points]} {
      return false
    }

    return true
  }

  ###############################################################################################################
  ## Proc        : isPolygonInsidePolygon
  ## Description : returns true if the polygon's points all touch or are inside the other's points or false if they're not
  ###############################################################################################################
  proc isPolygonInsidePolygon {points1 points2} {
    foreach edge [amd::userUtils::getPolygonEdges $points1] {
      if {![amd::userUtils::isEdgeInsidePolygon $edge $points2]} {
        return false
      }
    }
    return true
  }

  ###############################################################################################################
  ## Proc        : transformBbox
  ## Description : returns the bbox adjusted by the transform
  ###############################################################################################################
  proc transformBbox {bbox trans} {
    set oaBbox [oa::Box [lindex $bbox 0] [lindex $bbox 1]]
    set topBox [oa::Box $oaBbox $trans]
    return [list [oa::lowerLeft $topBox] [oa::upperRight $topBox]]
  }

  ###############################################################################################################
  ## Proc        : transformPoints
  ## Description : returns a list of points adjusted by the transform
  ###############################################################################################################
  proc transformPoints {points trans} {
    set transformedPoints {}
    foreach point $points {
      set transformedPoint [oa::transform [oa::Point [lindex $point 0] [lindex $point 1]] $trans]
      lappend transformedPoints $transformedPoint
    }
    return $transformedPoints
  }

  ###############################################################################################################
  ## Proc        : roundToGrid
  ## Description : returns a number rounded to the grid
  ###############################################################################################################
  proc roundToGrid {num {grid 0.001}} {
    return [expr {round($num / $grid) * $grid}]
  }

  ###############################################################################################################
  ## Proc        : getSelectedObjects
  ## Description : returns a unique collection of the selected objects
  ##               Objects with multiple partial edges selected will be returned once
  ###############################################################################################################
  proc getSelectedObjects {} {
    set selectedItems [de::getSelected -design [ed]]
    if {[db::getCount $selectedItems] != 0} {
      db::foreach item $selectedItems {
        lappend selectedObjects [db::getAttr object -of $item]
      }
      return [db::createCollection [lsort -unique $selectedObjects]]
    } else {
      return $selectedItems
    }
  }

  ###############################################################################################################
  ## Proc        : isSelected
  ## Description : returns true if the given object is selected or false if it isn't
  ###############################################################################################################
  proc isSelected {obj} {
    db::foreach selectedObj [de::getSelected -design [ed]] {
      if {[db::getAttr object -of $selectedObj] == $obj} {
        return true
      }
    }
    return false
  }

  ###############################################################################################################
  ## Proc        : getParent
  ## Description : returns the object's parent object or -1 if the object doesn't have a parent
  ###############################################################################################################
  proc getParent {obj} {
    if {[db::isEmpty [db::getAttr groupsOwnedBy -of $obj]] == 1} {
      return -1
    } 
    set parent [db::getAttr object -of [db::getAttr leader -of [db::getAttr groupsOwnedBy -of $obj]]]
    if {$parent == $obj} {
      return -1
    } else {
      return $parent
    }
  }

  ###############################################################################################################
  ## Proc        : max
  ## Description : returns the max number from the numbers passed in
  ###############################################################################################################
  proc max {args} {
    set m [lindex $args 0]
    for {set i 1} {$i < [llength $args]} {incr i} {
      set n [lindex $args $i]
      if {$n > $m} {
        set m $n
      }
    }
    return $m
  }

  ###############################################################################################################
  ## Proc        : min
  ## Description : returns the min number from the numbers passed in
  ###############################################################################################################
  proc min {args} {
    set m [lindex $args 0]
    for {set i 1} {$i < [llength $args]} {incr i} {
      set n [lindex $args $i]
      set m [expr $n > $m ? $m : $n]
    }
    return $m
  }

  ###############################################################################################################
  ## Proc        : getActiveCellView
  ## Description : returns the active cell view or -1 if an error occurs
  ###############################################################################################################
  proc getActiveCellView {{viewType maskLayout}} {

    if {[catch {set activeContext [de::getActiveContext]}]} {
      de::sendMessage "No active editor window exists" -severity error
      return -1
    }

    set cv [db::getAttr editDesign -of $activeContext]

    # Make sure the cell that is open is of the correct view type asked for
    if {[db::getAttr viewType -of $cv] != $viewType} {
      de::sendMessage "The active editor window is not of type $viewType" -severity error
      return -1
    }

    return $cv
  }

  ###############################################################################################################
  ## Proc        : openCellView
  ## Description : Opens a particular cellview for read or write.  Returns the cellview or -1 if an error occurs
  ##               The cell must exist
  ##               Mode Arg: r, w, a.  
  ##               r = read mode, cell must exist
  ##               a = append mode, cell must exist
  ##               w = over write mode, existing contents will be deleted, cell must exist
  ###############################################################################################################
  proc openCellView {libName cellName viewName {mode r}} {

    if {$viewName == "layout"} {
      set viewType maskLayout
    } else {
      set viewType schematic
    }

    if {$mode == "r"} {
      set readOnly true
    } else {
      set readOnly false
    }

    # Make sure the cellview exists
    if {[catch {set dmCellView [dm::getCellViews $viewName -cellName $cellName -libName $libName]}]} {
      return -1
    }
    if {[db::isEmpty $dmCellView]} {
      return -1
    }

    # If the mode is "w", delete the existing cellview and create it again
    if {$mode == "w"} {
      db::destroy $dmCellView
      set dmCellView [dm::createCellView $viewName -cell [dm::getCells $cellName -libName $libName] -viewType $viewType]
    }

    return [db::getAttr editDesign -of [de::createContext $dmCellView -readOnly $readOnly]]
  }

  ###############################################################################################################
  ## Proc        : createCellView
  ## Description : creates a particular cellview. If it exists it will be overwritten
  ###############################################################################################################
  proc createCellView {libName cellName viewName} {

    if {$viewName == "layout"} {
      set viewType maskLayout
    } else {
      set viewType schematic
    }

    # Get the cellview if it exists
    set dmCellView [amd::userUtils::openCellView $libName $cellName $viewName w]

    # If the cellview doesn't exist, create it
    if {$dmCellView == -1} {
      # Create the cell if it doesn't exist
      set dmCell [dm::getCells $cellName -libName $libName]
      if {[db::isEmpty $dmCell]} {
        set dmCell [dm::createCell $cellName -libName $libName]
      }
      # And now we create the cellview and return it
      if {[catch {set dmCellView [dm::createCellView $viewName -cell $dmCell -viewType $viewType]}]} {
        return -1
      } else {
        return [db::getAttr editDesign -of [de::createContext $dmCellView]]
      }
    }

    # The cellview already existed, return it
    return $dmCellView
  }

  ###############################################################################################################
  ## Proc        : getCellsInHier
  ## Description : returns the cell views in the hierarchy of the design
  ###############################################################################################################
  proc getCellsInHier {{cv false} {cellsInHier false}} {

    if {$cv == false} {
      set cv [ed]
    }

    if {$cellsInHier == false} {
      set cellsInHier [list $cv]
    }

    db::foreach inst [db::getInsts -of $cv] {
      set master [db::getAttr master -of $inst]
      if {[lsearch $cellsInHier $master] == -1} {
        set cellsInHier [linsert $cellsInHier end $master]
        set cellsInHier [amd::userUtils::getCellsInHier $master $cellsInHier]
      }
    }

    return $cellsInHier
  }

  ###############################################################################################################
  ## Proc        : getLibsInHier
  ## Description : returns the library names used in the hierarchy of the design
  ###############################################################################################################
  proc getLibsInHier {{context ""}} {
    set libNames {}
    if {$context == ""} {
      set context [de::getActiveContext]
    }
    he::foreach heContext [db::getAttr context.hierarchy] {
      lappend libNames [db::getAttr heContext.design.libName]
    }
    return [lsort -unique $libNames]
  }

  ###############################################################################################################
  ## Proc        : getPrBoundary
  ## Description : returns the prBoundary for the cell or -1 if it doesn't exist
  ###############################################################################################################
  proc getPrBoundary {cv} {
    set prBoundary [oa::PRBoundaryFind [oa::getTopBlock $cv]]
    if {$prBoundary == ""} {
      return -1
    } else {
      return $prBoundary
    }
  }

  ###############################################################################################################
  ## Proc        : getTechFile
  ## Description : returns the OA tech file pointer
  ###############################################################################################################
  proc getTechFile {} {
    set design  [ed]
    set libName [db::getAttr libName -of $design]
    return [oa::TechFind $libName] 
  }

  ###############################################################################################################
  ## Proc        : getShapeLayer
  ## Description : returns the layer name of the given shape
  ###############################################################################################################
  proc getShapeLayer {shape} {
    return [lindex [amd::userUtils::getShapeLpp $shape] 0]
  }

  ###############################################################################################################
  ## Proc        : getShapePurpose
  ## Description : returns the purpose name of the given shape
  ###############################################################################################################
  proc getShapePurpose {shape} {
    return [lindex [amd::userUtils::getShapeLpp $shape] 1]
  }

  ###############################################################################################################
  ## Proc        : getShapeLpp
  ## Description : returns the lpp of the given shape
  ###############################################################################################################
  proc getShapeLpp {shape} {
    set oaTech [amd::userUtils::getTechFile]
    if {[db::listAttrs object -of $shape] == "object"} {
      set object [db::getAttr object -of $shape]
    } else {
      set object $shape
    }
    set layerNum [db::getAttr layerNum -of $object]
    set layerName [oa::getName [oa::LayerFind $oaTech $layerNum]]
    set purposeNum [db::getAttr purposeNum -of $object]
    set purposeName [oa::getName [oa::PurposeFind $oaTech $purposeNum]]

    if {$layerName == "" || $purposeName == ""} {
      return -1
    } else {
      return [list $layerName $purposeName]
    }
  }

  ###############################################################################################################
  ## Proc        : isShapeOnLayer
  ## Description : returns true if the given shape is on the given layer or false if it isn't
  ###############################################################################################################
  proc isShapeOnLayer {shape layer} {
    if {[amd::userUtils::getShapeLayer $shape] == $layer} {
      return true
    } else {
      return false
    }
  }

  ###############################################################################################################
  ## Proc        : isShapeOnPurpose
  ## Description : returns true if the given shape is on the given purpose or false if it isn't
  ###############################################################################################################
  proc isShapeOnPurpose {shape purpose} {
    if {[amd::userUtils::getShapePurpose $shape] == $purpose} {
      return true
    } else {
      return false
    }
  }

  ###############################################################################################################
  ## Proc        : isShapeOnLpp
  ## Description : returns true if the given shape is on the given lpp or false if it isn't
  ##               The given lpp can have either the layer or the purpose missing such as [list "" drawing] or
  ##               [list M1 ""].  In these cases the proc will only check what is provided
  ###############################################################################################################
  proc isShapeOnLpp {shape lpp} {
    set layer [lindex $lpp 0]
    set purpose [lindex $lpp 1]

    if {$layer != ""} {
      if {[amd::userUtils::isShapeOnLayer $shape $layer]} {
        set flag true
      } else {
        return false
      }
    }

    if {$purpose != ""} {
      if {[amd::userUtils::isShapeOnPurpose $shape $purpose]} {
        set flag true
      } else {
        set flag false
      }
    }

    return $flag
  }

  ###############################################################################################################
  ## Proc        : isShapeVisible
  ## Description : returns true if the given shape is visible or false if it isn't
  ###############################################################################################################
  proc isShapeVisible {cv shape} {
    set lpp [amd::userUtils::getShapeLpp $shape]
    if {[db::getAttr visible -of [db::getNext [de::getLPPs $lpp -from $cv]]]} {
      return true
    } else {
      return false
    }
  }

  ###############################################################################################################
  ## Proc        : getNextElement
  ## Description : finds an element in a list and returns either the prior element or the next one
  ###############################################################################################################
  proc getNextElement {theList element {direction +}} {

    set index [lsearch $theList $element]
    if {$index == -1} {
      return -1
    }

    if {$direction == "+"} {
      set index [incr index 1]
    } else {
      set index [incr index -1]
    }

    set adjacentElement [lindex $theList $index]

    if {$adjacentElement != ""} {
      return $adjacentElement
    } else {
      return -1
    }
  }

  ###############################################################################################################
  ## Proc        : displayDialog
  ## Description : displays a dialog of the type passed in (question, information, warning, error)
  ###############################################################################################################
  proc displayDialog {type msg {parent ""}} {
    if {$parent == ""} {set parent [de::getActiveEditorWindow]}
    if {$type == "question"} {
     set buttons [list Yes No]
    } else {
     set buttons [list Ok]
    }

    de::sendMessage $msg -severity $type

    return [gi::prompt $msg -title "$type" -icon $type -buttons $buttons -parent $parent]
  }

  ###############################################################################################################
  ## Proc        : createGDS
  ## Description : runs the exportStream script to generate a GDS
  ###############################################################################################################
  proc createGDS {libName cellName viewName runDirName} {

    de::sendMessage "   Running stream out to generate the GDS..." -severity information
    update

    set startTime [clock seconds]

    set gdsFileName [file join $runDirName "$cellName.gds"]
    set logFileName [file join $runDirName "$cellName.streamOut.log"]
    set libDefFileName  [file join [exec pwd] "lib.defs"]
    if {![file readable $libDefFileName]} {
      amd::userUtils::displayDialog "error" "The lib.defs file can't be found or is not readable - script aborted"
      return -1
    }
    #set layerMapFileName [exec rexval cdesigner_env::layermap]
    #set layerMapFileName $::GVAR_amdRevRc([list cdesigner_env layermap])
    set layerMapFileName $::amd::GVAR_amdRevRc(cdesigner_env::layermap)
    if {![file readable $layerMapFileName]} {
      amd::userUtils::displayDialog "error" "The layerMap file can't be found or is not readable - script aborted"
      return -1
    }
    #set objectMapFileName [exec rexval cdesigner_env::objectmap]
    #set objectMapFileName $::GVAR_amdRevRc([list cdesigner_env objectmap])
    set objectMapFileName $::amd::GVAR_amdRevRc(cdesigner_env::objectmap)
    if {![file readable $objectMapFileName]} {
      amd::userUtils::displayDialog "error" "The objectMap file can't be found or is not readable - script aborted"
      return -1
    }

    # Create the template file to be used in the stream out script
    set templateFileName [file join $runDirName "$cellName.streamOut.template"]
    set templateFile [open $templateFileName w]
    puts $templateFile "lib              $libName"
    puts $templateFile "cell             $cellName"
    puts $templateFile "view             $viewName"
    puts $templateFile "layerMap         $layerMapFileName"
    puts $templateFile "objectMap        $objectMapFileName"
    puts $templateFile "gds              $gdsFileName"
    puts $templateFile "libDefFile       $libDefFileName"
    puts $templateFile "logFile          $logFileName"
    puts $templateFile "text             native"
    puts $templateFile "hierDepth        32"
    puts $templateFile "labelDepth       32"
    puts $templateFile "rectAsBoundary"
    puts $templateFile "mapAllText"
    close $templateFile

    # Run exportStream to generate the GDS
    if {[catch {exec exportStream -templateFile $templateFileName}]} {
      return -1
    }

    # Clean up any junk files left behind
    if {[file isfile [file join [exec pwd] strmOut.cell.automap]]} {exec rm strmOut.cell.automap}

    de::sendMessage "   Stream out completed in [expr [clock seconds] - $startTime] seconds" -severity information
    update

    return $gdsFileName
  }

  ###############################################################################################################
}

