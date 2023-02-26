# Copyright (c) 2004-2015 Synopsys, Inc. This Galaxy Custom Designer software
# and the associated documentation are confidential and proprietary to
# Synopsys, Inc. Your use or disclosure of this Galaxy Custom Designer software
# is subject to the terms and conditions of a written license agreement between
# you, or your company, and Synopsys, Inc.

namespace eval ::amd::amdLayLibrary {

namespace export *
namespace import -force ::amd::utils::*
namespace import -force ::amd::amdLibrary::*

proc amdGetArea {obj} {
    set area 0
    if {[db::isObject $obj]} {
        switch [db::getAttr type -of $obj] {
            Path {
                set area [oa::getArea [oa::getBoundary $obj]]
                return $area
                
                set points [db::getAttr points -of $obj] 
                set width [db::getAttr width -of $obj] 
                set len [expr [llength $points]-1]
                for {set i 0} {$i < $len} {incr i} {
                    set p1 [lindex $points $i]
                    set p2 [lindex $points [expr $i + 1]]
                    set length [amdGetDistance $p1 $p2]
                    set area [expr $area + $length*$width]
                }
                # calculate area of end cap, possible value: truncateExtend, extendExtend, roundRound, varExtendExtend
                switch [db::getAttr style -of $obj] {
                    "extend" {
                        set area [expr $area + $width*$width]
                    }
                    "variable" {
                        set area [expr $area + $width*[db::getAttr beginExt -of $obj] + $width*[db::getAttr endExt -of $obj]]
                    }
                }
            }
            Polygon {
                set area [oa::getArea [oa::getPoints $obj]]
                return $area
                
                set points [db::getAttr points -of $obj] 
                set len [llength $points]
                for {set i 0} {$i < $len} {incr i} {
                    set j [expr ($i+1)%$len]
                    set area [expr $area + [xCoord [lindex $points $i]] * [yCoord [lindex $points $j]]]
                    set area [expr $area - [yCoord [lindex $points $i]] * [xCoord [lindex $points $j]]]
                }
                set area [expr abs($area/2)]
            }
            default {
                set area [amdGetBBoxArea [db::getAttr bBox -of $obj]]
            }
        } 
        return $area       
    } else {
        de::sendMessage "amdGetArea: Not a valid object." -severity warning
    }
}


# get the distance between 2 points
proc amdGetDistance {fp lp} {
    return [expr sqrt( pow([xCoord $lp] - [xCoord $fp],2) + pow([yCoord $lp] - [yCoord $fp],2))]
}


proc amdGetBBoxArea {bBox} {
    #return area = width x height
    return [expr [amdGetBBoxWidth $bBox]*[amdGetBBoxHeight $bBox]]
}


proc amdGetBBoxWidth {bBox} {
    return [expr [xCoord [lindex $bBox 1]] - [xCoord [lindex $bBox 0]]]
}


proc amdGetBBoxHeight {bBox} {
    return [expr [yCoord [lindex $bBox 1]] - [yCoord [lindex $bBox 0]]]
}


proc amdSetLayersVisible {layers visible} {
    set oaDes [::ed]
    if {$visible} {
        set firstLPP ""
        foreach lpp $layers {
            set deLPP [db::getNext [de::getLPPs $lpp -from $oaDes]]
            if {""!=$deLPP} {
                db::setAttr valid -of $deLPP -value true
                db::setAttr visible -of $deLPP -value true
                if {""==$firstLPP} {
                    set firstLPP $deLPP
                }
            }
        }
        if {""!=$firstLPP} {
            de::setActiveLPP $firstLPP
        }
    } else {
        set activeLPP [db::getAttr lpp -of [de::getActiveLPP -design $oaDes]]
        if {[member $activeLPP $layers]} {
            de::setActiveLPP [de::getLPPs $::amd::GVAR_amdLayVariables(entryLayer) -from $oaDes]
        }
        foreach lpp $layers {
            set deLPP [db::getNext [de::getLPPs $lpp -from $oaDes]]
            if {""!=$deLPP} {
                db::setAttr visible -of $deLPP -value false
            }
        }        
    }
    
    amdSyncObjectAssistant 
    de::redraw    
}


proc amdSyncObjectAssistant {} {
    set oaDes [ed]
    set oaTech [db::getAttr tech -of $oaDes]
    # update the visibility of via objects
    set visible 0
    foreach via [amdGetViaLayers $oaTech] {
        set deLPP [de::getLPPs "$via drawing" -from $oaDes]
        if {[db::getAttr visible -of $deLPP]} {
            set visible 1
        }
    }
    db::setAttr visible -of [de::getObjectFilters leVia -from $oaDes] -value $visible
}


proc amdGetTechFile {libName} {
    set oaLib [dm::getLibs $libName]
    return [oa::TechFind $oaLib]
}


# get via layers from the tech file
proc amdGetViaLayers {oaTech} {
    set vias {}
    set viaDefs  [db::getAttr viaDefs -of $oaTech]
    set viaDefs [db::filter $viaDefs -filter {%type=="StdViaDef"}]
    
    db::foreach vd $viaDefs {
        set params [db::getAttr params -of $vd]
        set cutLayerName [oa::getName [oa::LayerFind $oaTech [oa::getCutLayer $params]]]
        if {![member $cutLayerName $vias]} {
            lappend vias $cutLayerName
        }
    }
    return $vias
}

proc amdToggleObject {objName} {
    set of [db::getNext [de::getObjectFilters objName]]
    if {""!=$of} {
        db::setAttr visible -of $of -value [db::getAttr visible -of $of]
        return [db::getAttr visible -of $of]
    }
    return ""
}


proc amdZoomToPoint {{winId ""}} {
    set dlgName amdZoomToPointForm
    if {""==$winId || [db::isObject $winId]} {
        set winId [db::getAttr id -of [de::getActiveEditorWindow]]
    }
    set win [gi::getWindows $winId]
    set dlg [db::getNext [gi::getDialogs $dlgName -parent $win]]
    if {""==$dlg} {
        set ns [namespace current]
        set dlg [gi::createDialog $dlgName -parent $win -title "Zoom To Point" -execProc "${ns}::amdZoomToPoint"]
        gi::createLabel prompt -parent $dlg -label "Enter the x, y coordinate and the window size (default: 10) e.g. 100 205.35 50"
        gi::createTextInput input -parent $dlg -label "x y \[window_size\]"
    } else {
        set input [gi::findChild input.value -in $dlg]
        scan $input "%d %d %d" x y size
        if {![info exist size]} {
            set size 10
        }
        if {[info exist x] && [info exist y]} {
            de::setViewport -window $winId -box [list [list [expr $x - $size] [expr $y - $size]] [list [expr $x + $size] [expr $y + $size]]]
            set oaDes [db::getAttr editDesign -of [de::getContexts -window $winId]]
            set tr [de::startTransaction "Set Viewport" -design $oaDes]
            db::createLinearRuler [list [list $x $y] [list [expr $x+$size] [expr $y+$size]]] -design $oaDes
            db::createLinearRuler [list [list $x $y] [list [expr $x+$size] [expr $y-$size]]] -design $oaDes
            db::createLinearRuler [list [list $x $y] [list [expr $x-$size] [expr $y+$size]]] -design $oaDes
            db::createLinearRuler [list [list $x $y] [list [expr $x-$size] [expr $y-$size]]] -design $oaDes
            de::endTransaction $tr
        } else {
            de::sendMessage "Zoom failed! Make sure the input field is filled properly." -severity warning
        }
    }
}


proc amdShowCenterPoint {{winId ""}} {
    if {""==$winId} {
        set winId [db::getAttr id -of [de::getActiveEditorWindow]]
    }
    set oaDes [db::getAttr editDesign -of [de::getContexts -window $winId]]
    set s [de::getSelected -design $oaDes]
    if {![db::isEmpty $s]} {
        set tr [de::startTransaction "Show Center Point" -design $oaDes]
        db::foreach bBox [db::getAttr object.bBox -of $s] {
            if {""!=$bBox} {
                set llx [lindex $bBox 0 0]
                set lly [lindex $bBox 0 1]
                set urx [lindex $bBox 1 0]
                set ury [lindex $bBox 1 1]
                
                set x [expr $llx + ($urx-$llx)/2]
                set y [expr $lly + ($ury-$lly)/2]
                db::createLinearRuler [list [list $x $lly] [list $x $ury]] -design $oaDes
                db::createLinearRuler [list [list $llx $y] [list $urx $y]] -design $oaDes
            }
        }
        de::endTransaction $tr
        return 1
    } else {
        de::sendMessage "Nothing selected!" -severity warning
        return 0
    }
}

proc amdShowArea {{winId ""}} {
    if {""==$winId} {
        set winId [db::getAttr id -of [de::getActiveEditorWindow]]
    }
    set oaDes [db::getAttr editDesign -of [de::getContexts -window $winId]]
    set s [de::getSelected -design $oaDes -partial false -filter {%objType!="LinearRuler" && %objType!="CoordinateMark" && %objType!="CircularRuler" && %objType!="MPP"}]
    if {[db::getCount $s]<30} {
        set output ""
        db::foreach obj [db::getAttr object -of $s] {
            set area [amdGetArea $obj]
            set skip 0

            switch [db::getAttr type -of $obj] {
                "ScalarInst" {
                    set name [db::getAttr cellName -of $obj]
                }
                "ArrayInst" {
                    set name [format "%s (%d cols, %d rows)" [db::getAttr cellName -of $obj] [db::getAttr numCols -of $obj] [db::getAttr numRows -of $obj]]
                }        
                "StdVia" {
                    set name [db::getAttr viaDef.name -of $obj]
                }
                "LayerBlockage" {
                    set name [format "Blockage (%s %s)" [getLayerName [db::getAttr layerNum -of $obj] $oaDes] [db::getAttr blockageType -of $obj]]
                }
                default {
                    if {[catch {set name [getLayerName  [db::getAttr layerNum] $oaDes]}]} {
                        set name [db::getAttr type -of $obj]
                    }
                }
            }
            
            switch [db::getAttr type -of $obj] {
                "Path" -
                "PathSeg" {
                    set width [db::getAttr width -of $obj]
                    set length [expr $area / $width]
                    set square [expr $length / $width]
                    set info [format " (%.3f * %.3f, %.3f squares)" $width $length $square]
                }
                "Rect" -
                "ScalarInst" - 
                "ArrayInst" {
                    set width [amdGetBBoxWidth [db::getAttr bBox -of $obj]]
                    set length [amdGetBBoxHeight [db::getAttr bBox -of $obj]]
                    set info [format " (%.3f * %.3f)" $width $length]
                }        
                default {
                    set info ""
                }
            }   
            # format area
            set unit "u"
            set format "%.10f"
            
            if {$area >=1000000} {
                set area [expr $area/1000000]
                set unit "m"
            } elseif {$area < 0.01} {
                set format "%.10g"
            }
            set area [string trimright [format $format $area] 0]
            set area [format "$area ${unit}m\u00B2"]
            append output [format "%s:\t%s%s\n" $name $area $info]
        }
        set status [gi::prompt $output -title "Area" -buttons "Close"]
    } else {
        set status [gi::prompt "Please select up to 30 objects only." -title "Area" -buttons "Close"]
    }
}

proc amdWarn {message {parent ""} {title "Warning"}} {
    if {[db::isObject $parent] && ("giDialog"==[db::getAttr parent.type] || "giWidnow"==[db::getAttr parent.type])} {
        gi::prompt $message -title $title -buttons "Ok" -icon "warning" -parent $parent
    } else {
        gi::prompt $message -title $title -buttons "Ok" -icon "warning"
    }
}


proc amdConvertPathToPolygon {{refId ""}} {
    set oaDes [findDesign $refId]
    if {![amdReadOnlyWarning $oaDes]} {
        set tr [de::startTransaction "Convert Path to Polygon" -design $oaDes]
        set figs [de::getSelected -design $oaDes -filter {%objType=="Path"}]
        if {![db::isEmpty $figs]} {
            set figs [le::convertToPolygon $figs]
        }
        db::foreach f $figs {
            set obj [db::getAttr object -of $f]
            set children [detachObjectsFromGroup $obj]
            
            db::setAttr points -of $obj -value [amdSnapPointsToGrid [db::getAttr points -of $obj]]
            set obj [amdConvertPolygonToRect $obj]
            
            # make sure 45 degree is achieved where required (DRC)
            if {"Rect"!=[db::getAttr type -of $obj]} {
                set len [db::getAttr numPoints -of $obj]
                set points [db::getAttr points -of $obj]
                for {set i 0} {$i<$len} {incr i} {
                    # reference point, will not be adjusted (except the last point)
                    set p0 [amdNth $i $points]
                    # the next to reference point, will be adjusted if required
                    set p1 [amdNth [expr $i + 1] $points]
                    # next next point, used to calculate whether p1 adjustment should be done in x or y-direction    
                    set p2 [amdNth [expr $i + 2] $points]
                    
                    set x [xCoord $p0]
                    set y [yCoord $p0]
                    set x1 [xCoord $p1]
                    set y1 [yCoord $p1]                        
                    set x2 [xCoord $p2]
                    set y2 [yCoord $p2]                        
                    set dx [expr $x1 - $x]
                    set dy [expr $y1 - $y]
                    
                    if {0!=$dx} {
                        # make sure no division by zero!
                        set m [expr $dy/$dx]
                    } else {
                        # to signify infinity, this m will not be used anyway
                        set m 9999.99
                    }
                    
                    # detect 45 degree point pairs and calculate the "correct" x and y for the next point
                    if {[expr abs($m)] >= 0.9 && [expr abs($m)<=1.1]} {
                        # to -1 or 1
                        set m [expr round($m)]
                        set xc [expr $x + $dy/$m]
                        set yc [expr $y + $m*$dx]
                        # construct the "correct" point pc by replacing old x or y with xc or yc, depending on p2 direction
                        if {$i!=[expr $len - 1]} {
                            if {0==[expr $x2-$x1]} {
                                set pc [list $x1 $yc]
                            } else {
                                # other cases i.e. 45 degree -> can either move y, fix x or move x, fix y
                                if {0==[expr $y2-$y1]} {
                                    set pc [list $xc $y1]
                                } else {
                                    if {[expr abs(1 - abs(($y2-$yc)/($x2-$x1)))] < [expr abs(1 - abs(($y2-$y1)/($x2-$xc)))]} {
                                        set pc [list $x1 $yc]
                                    } else {
                                        set pc [list $xc $y1]   
                                    }
                                }
                            }
                            set points [amdReplaceListItem $points $p1 $pc]
                        } else {
                            # it is the last point, so adjust itself to fit the starting point
                            set pc [list [expr $x+$x1-$xc] [expr $y+$y1-$yc]]
                            # update the object with newly adjusted point
                            set points [amdReplaceListItem $points $p0 $pc]
                        }
                    }
                }
                db::setAttr points -of $obj -value $points
            }
            attachObjectsToGroup $obj $children
            de::select $obj
        }
        de::endTransaction $tr
    }
    return 1
}



# replace one specified item from the list and return the new list; if more than one item are found, replace the first one
proc amdReplaceListItem {li el new_e} {
    set index [lsearch $li $el]
    if {-1!=$index} {
        lset li $index $new_e
    }
    return $li
}


# extended version of nth function which supports cyclic indexing (i.e. it works with indexes out of regular range)
proc amdNth {i li} {
    # limit the range of index to be <= len-1 and >= -len
    set i [expr $i%[llength $li]] 
    #; handle negative index
    if {$i<0} {
        # map negative index to positive index i.e. regular index
        set i [expr $i + [llength $li]]
    }
    return [lindex $li $i]
}


# give warning if layout is in read only mode (return t upon dialog close)
proc amdReadOnlyWarning {{oaDes ""}} {
    if {""==$oaDes} {
        set oaDes [ed]
    }
    if {"r"==[db::getAttr mode -of $oaDes]} {
        set status [gi::prompt "Layout must be opened with write permission." -title "Layout Editor" -buttons "Close"]
        return 1
    }
    return 0
}

           
# amdConvertPolygonToRect() function is called by amdConvertPathToPolygon()
proc amdConvertPolygonToRect {obj} {
    if {[oa::isRectangle [oa::getPoints $obj]]} {
        set oaDes [db::getAttr design -of $obj]
        set bBox [db::getAttr bBox -of $obj]
        set lpp [db::getAttr LPP.lpp -of $obj]
        db::destroy $obj
        set obj [le::createRectangle $bBox -design $oaDes -lpp $lpp]
    }
    return $obj
}


# snap a single point to grid according to environment variable xSnapSpacing
proc amdSnapPointToGrid {point {scope user}} {
    if {"user"==$scope && [catch {set scope [de::getActiveContext]}]} {
        set scope "user" 
    }
    set grid [db::getPrefValue leSnapSpacing -scope $scope]
    set gridX [lindex $grid 0]
    set gridY [lindex $grid 1]
    set res 0.001
    set factor [expr $gridX/$res]
    if {$gridX!=$gridY} {
        de::sendMessage "amdSnapPointToGrid" "x and y snap spacing is not the same!" -severity error
        return 0
    }
    set x [amdRound [xCoord $point] 3]
    set y [amdRound [yCoord $point] 3]
    
    set nx 0
    set ny 0
    # handle negative value since mod and delta below assume positive integer
    if {$x < 0} {
        set nx 1
        set x [expr -$x]
    }
    if {$y < 0} {
        set ny 1
        set y [expr -$y]
    }
    set mod_x [expr round($x/$res)%round($factor)] 
    set mod_y [expr round($y/$res)%round($factor)] 
    
    if {$mod_x>0} {
        if {$mod_x <= [expr floor($factor/2)]} {
            set delta [expr $mod_x*$res]
            set x [expr $x - $delta]
        } else {
            set delta [expr ($factor - $mod_x)*$res]
            set x [expr $x + $delta]
        }
    }
    
    if {$mod_y>0} {
        if {$mod_y <= [expr floor($factor/2)]} {
            set delta [expr $mod_y*$res]
            set y [expr $y - $delta]
        } else {
            set delta [expr ($factor - $mod_y)*$res]
            set y [expr $y + $delta]
        }
    } 
    
    if {$nx} {
        set x [expr -$x]
    }
    if {$ny} {
        set y [expr -$y]
    }    
    
    return [list $x $y]
}


# round floating number to desired number of decimal point
proc amdRound {num decimal} {
    set r [format [format "%%.%df" $decimal] [expr $num*1.0]]
    return $r
}


# snap multiple points to grid using amdSnapPointToGrid() function
proc amdSnapPointsToGrid {points} {
    set res {}
    foreach p $points {
        lappend res [amdSnapPointToGrid $p]
    }
    return $res
}


proc amdConvertToPath {{refId ""}} {
    set oaDes [findDesign $refId]
    set tr [de::startTransaction "Convert to Path" -design $oaDes]
    db::foreach obj [db::getAttr object -of [de::getSelected -design $oaDes -filter {%objType=="Polygon" || %objType=="Rectangle"}]] {
        switch [db::getAttr type -of $obj] {
            "Polygon" {
                amdConvertPolygonToPath $obj
            }
            "Rect" {
                amdConvertRectToPath $obj
            }
        }
    }
    de::endTransaction $tr
}


#amdConvertPolygonToPath() function is called by amdConvertToPath()
proc amdConvertPolygonToPath {obj} {
    set oaDes [db::getAttr design -of $obj]
    set points [db::getAttr points -of $obj]
    set lpp [db::getAttr LPP.lpp -of $obj]
    set count [db::getAttr numPoints -of $obj]
    if {[expr $count%2]} {
        de::sendMessage "amdConvertPolygonToPath" "Polygon cannot be converted into path!" -severity error
        return 0
    }

    set tr [de::startTransaction "Convert Polygon to Path" -design $oaDes]
    set i 0
    set found 0
    while {!$found && $i<$count} {
        set path_points {}
        set shifted_points [amdShiftList $points $i]
        incr i
        set width [amdGetDistance [lindex $shifted_points 0] [lindex $shifted_points end]]
        for {set point 0} {$point<=[expr ($count-2)/2]} {incr point} {
            set x [xCoord [lindex $shifted_points $point]]
            set y [yCoord [lindex $shifted_points $point]]
            set x1 [xCoord [lindex $shifted_points [expr $count - 1 - $point]]]
            set y1 [yCoord [lindex $shifted_points [expr $count - 1 - $point]]]
            lappend path_points [list [expr $x + ($x1-$x)/2] [expr $y + ($y1-$y)/2]]
        }
        
        # first and last segment should be larger than half of path width
        if {[amdGetMinDistance $path_points] > [expr $width/2]} {
            if {![catch {set oaPath [amdCreatePath $oaDes $lpp $path_points $width [db::getAttr net -of $obj]]} res]} {
                if {[amdGetArea $oaPath] > 0.8*[amdGetArea $obj] && [amdGetArea $oaPath] < 1.2*[amdGetArea $obj] } {
                    # test bBox area to ensure the path is not "distorted"
                    # this is because in some cases path area = polygon area but the path does not follow the polygon's direction                
                    if {[amdGetBBoxArea [db::getAttr bBox -of $oaPath]]> 0.8*[amdGetBBoxArea [db::getAttr bBox -of $obj]] && [amdGetBBoxArea [db::getAttr bBox -of $oaPath]] < 1.2*[amdGetBBoxArea [db::getAttr bBox -of $obj]]} {
                        # success, now handle attached objects
                        attachObjectsToGroup $oaPath [detachObjectsFromGroup $obj]
                        db::destroy $obj
                        de::select $oaPath
                        set found 1
                    }
                }
                if {!$found} {
                    db::destroy $oaPath
                }   
            }
        }
    }
    de::endTransaction $tr
}

# get the minimum distance between adjacent points
proc amdGetMinDistance {points} {
    set count [llength $points]
    if {$count < 2} {
        error "Not enough points to get minimum distance!"
    }
    set fp [lindex $points 0]
    set lp [lindex $points end]
    set minimum [amdGetDistance $fp $lp]

    for {set count 0} {$count<=[expr $count - 2]} {incr count} {
        set d [amdGetDistance [lindex $points $i] [lindex $points [expr $i+1]]]
        if {$d<$minimu} {
            set minimum $d
        }
    }
    return $minimum
}


proc amdShiftList {li pos} {
    set len [llength $li]
    set pos [expr int($pos)]
    if {[expr abs($pos)>$len]} {
        set pos [expr $pos%$len]
    }
    if {$pos>0} {
        return [concat [lrange $li [expr $len-$pos] end] [lrange $li 0 [expr $len-1-$pos]]]
    } elseif {$pos<0} {
        set pos [expr abs($pos)]
        return [concat [lrange $li $pos end] [lrange $li 0 [expr $pos-1]]]
    } else {
        return $li
    }    
}

# amdConvertRectToPath() function is called by amdConvertToPath()
proc amdConvertRectToPath {obj} {
    if {"Rect"!=[db::getAttr type -of $obj]} {
        de::sendMessage "amdConvertRectToPath" "The current object type is not rect!" -severity error
        return 0
    }
    set oaDes [db::getAttr design -of $obj]
    set tr [de::startTransaction "Convert Rect to Path" -design $oaDes]
    set bBox [db::getAttr bBox -of $obj]
    set ll [lowerLeft $bBox]
    set ur [upperRight $bBox]
    set x [xCoord $ll]
    set y [yCoord $ll]
    set x1 [xCoord $ur]
    set y1 [yCoord $ur]
    set dx [expr $x1 - $x]
    set dy [expr $y1 - $y]
    
    if {[expr abs($dx)] < [expr abs($dy)]} {
        set width $dx
        set pathPoints [list [list [expr $x+$dx/2] $y] [list [expr $x+$dx/2] $y1]]
    } else {
        set width $dy
        set pathPoints [list [list $x [expr $y+$dy/2]] [list $x1 [expr $y+$dy/2]]]
    }
    
    set path [amdCreatePath $oaDes [db::getAttr LPP.lpp -of $obj] $pathPoints $width]
    attachObjectsToGroup $path [detachObjectsFromGroup $obj]
    db::destroy $obj
    de::select $path  
    de::endTransaction $tr
}

# create an on-grid path by snapping path points to grid and rounding path width
# also check for close to but not exactly 45 degree points. Once found, make sure they are exactly 45 degree
proc amdCreatePath {oaDes lpp points width {net ""}} {
    set points [amdSnapPointsToGrid $points]
    set width [amdRound $width 3]
    # checks for 45 degree path, the following code is taken from part of the code found in amdConvertPathToPolygon() function
    
    set len [expr [llength $points] - 1]
    for {set i 0} {$i<$len} {incr i} {
        # reference point, will not be adjusted (except the last point)
        set p0 [lindex $points $i]
        # the next to reference point, will be adjusted if required
        set p1 [lindex $points [expr $i + 1]]
        
        set x [xCoord $p0]
        set y [yCoord $p0]
        set x1 [xCoord $p1]
        set y1 [yCoord $p1]                        
        set dx [expr $x1 - $x]
        set dy [expr $y1 - $y]
        
        if {0!=$dx} {
            # make sure no division by zero!
            set m [expr $dy/$dx]
        } else {
            # to signify infinity, this m will not be used anyway
            set m 9999.99
        }
        
        # detect 45 degree point pairs and calculate the "correct" x and y for the next point
        if {[expr abs($m)] >= 0.9 && [expr abs($m)<=1.1]} {
            # to -1 or 1
            set m [expr round($m)]
            set xc [expr $x + $dy/$m]
            set yc [expr $y + $m*$dx]
            # construct the "correct" point pc by replacing old x or y with xc or yc, depending on p2 direction
            # unless the reference point is the 2nd to last point i.e. p0 = 2nd to last, p1 = last, p2 = N/A
            if {$i<[expr $len - 2]} {
                set p2 [lindex $points [expr $i+2]]
                set x2 [xCoord $p2]
                set y2 [yCoord $p2]
                if {0==[expr $x2-$x1]} {
                    set pc [list $x1 $yc]
                } else {
                    # other cases i.e. 45 degree -> can either move y, fix x or move x, fix y
                    if {0==[expr $y2-$y1]} {
                        set pc [list $xc $y1]
                    } else {
                        if {[expr abs(1 - abs(($y2-$yc)/($x2-$x1)))] < [expr abs(1 - abs(($y2-$y1)/($x2-$xc)))]} {
                            set pc [list $x1 $yc]
                        } else {
                            set pc [list $xc $y1]   
                        }
                    }
                }
                
            } else {
                # 2nd to last path point, either move y, fix x or move x, fix y gives little difference
                set pc [list $x1 $yc]
            }
            set points [amdReplaceListItem $points $p1 $pc]
        }
    }
    set cmd [list le::createPath $points -design $oaDes -width $width -lpp $lpp]
    if {""!=$net} {
        lappend cmd -net
        lappend cmd $net
    }
    return [eval $cmd]
}


proc amdLabelNet {{refId ""}} {
    set oaDes [findDesign $refId]
    if {![amdReadOnlyWarning $oaDes]} {    
        set tr [de::startTransaction "Add Label to Nets" -design $oaDes]
        db::foreach obj [db::getAttr object -of [de::getSelected -design $oaDes -filter {%objType=="Path" || %objType=="PathSeg"}]] {
            set oaNet [db::getAttr net -of $obj]
            if {""!=$oaNet} {
                set netName [db::getAttr name -of $oaNet]
                set lpp [db::getAttr LPP.lpp -of $obj]
                set height [amdRound [expr 0.5*[db::getAttr width -of $obj]] 3]
                set font "roman"
                set labels {}
                # use "label" purpose for GF28SHP
                if {[info exist amd::GVAR_amdLayVariables(process)] && $amd::GVAR_amdLayVariables(process) == "GF28SHP"} {
                    set lpp [list [lindex $lpp 0] "label"]
                }
                set gMems [getGroupMembers $obj]
                if {""!=$gMems} {
                    db::foreach gm $gMems {
                        if {"AttrDisplay"==[db::getAttr type -of $gm]} {
                            db::destroy $gm
                        }
                    }
                }
                set points [db::getAttr points -of $obj]
                # get begin, end point
                set pts [list [lindex $points 0] [lindex $points end]]

                # get center point
                if {[xCoord [car $pts]]==[xCoord [cadr $pts]] || [yCoord [car $pts]]==[yCoord [cadr $pts]]} {
                    set pts [concat [centerBox [list [car $pts] [cadr $pts]]] $pts]
                }
                # label at both ends, then center
                foreach p $pts {
                    set info [amdGetPathSegmentInfo $points [db::getAttr width -of $obj] $p]
                    set direction [car $info]

                    if { ""!= $direction} {
                        set bBox [cadr $info]
                        set ll [lowerLeft $bBox]
                        set ur [upperRight $bBox]
                        set x [xCoord $ll]
                        set y [yCoord $ll]
                        set x1 [xCoord $ur]
                        set y1 [yCoord $ur]
                    }
                    if {0==$direction} {
                        if {[expr abs($x - [xCoord $p])] > [expr abs($x1 - [xCoord $p])]} {
                            set justify "centerRight"
                            set orient R0
                        } else {
                            set justify "centerLeft"
                            set orient R0
                        }
                    }
                    if {1==$direction} {
                        if {[expr abs($y - [yCoord $p])] > [expr abs($y1 - [yCoord $p])]} {
                            set justify "centerRight"
                            set orient R90
                        } else {
                            set justify "centerLeft"
                            set orient R90
                        }
                    }
                    #; handle center point
                    if {3==[llength $pts] && $p == [car $pts]} {
                        set justify "centerCenter"
                    }
                    set oaText [le::createAttributeLabel netName -parent $obj -valueOnly true -lpp $lpp -origin $p -just $justify -orient $orient -font $font -height $height]
                    lappend labels $oaText 
                }
                set lastLabel [lindex $labels end]
                db::foreach obj [db::getAttr object -of [de::getFigures [db::getAttr bBox -of $lastLabel] -type rectangle -design $oaDes -depth 0 -touch true]] {
                    if {[member $obj $labels] && $obj!=$lastLabel} {
                        db::destroy $obj
                    }
                }
            }
        }
        de::endTransaction $tr
    }
}


# get the direction (x = 0, y = 1, others = nil) of a path section and the bBox forming it at the reference point
proc amdGetPathSegmentInfo {path_points width ref_point} {
    set direction ""
    set bBox ""
    set prev ""
    set xr [xCoord $ref_point]
    set yr [yCoord $ref_point]
    
    foreach point $path_points {
        if { ""==$prev} {
            set prev $point
        } else {
            set x [xCoord $prev]
            set y [yCoord $prev]
            set x1 [xCoord $point]
            set y1 [yCoord $point]
            set dx [expr $x1-$x]
            set dy [expr $y1-$y]

            set prev $point
            # p = larger value, q = smaller value
            if {0==$dx} {
                if {[expr abs($xr - $x)] < [expr $width/2]} {
                    if {$y1 > $y} {
                        set p $y1
                        set q $y
                    } else {
                        set p $y
                        set q $y1
                    }
                    if {$yr <= $p && $yr >=$q} {
                        set direction 1
                        set bBox [list [list [expr $x-$width/2] $q] [list [expr $x+$width/2] $p]]
                    }
                }
            } elseif {0==$dy} {
                if {[expr abs($yr - $y)] < [expr $width/2]} {
                    if {$x1 > $x} {
                        set p $x1
                        set q $x
                    } else {
                        set p $x
                        set q $x1
                    }
                    if {$xr <= $p && $xr >=$q} {
                        set direction 0
                        set bBox [list [list $q [expr $y-$width/2] ] [list $p [expr $y+$width/2] ]]
                    }
                }
            }
        }
    }
    return [list $direction $bBox]
}

# get the file directory from a file path
proc amdGetDirFromPath {filePath} {
    if {![file exist $filePath]} {
        error "$filePath: Invalid file path!"
    }
    set filePath [file normalize $filePath]
    if {[file isdir $filePath]} {
        return $filePath
    } else {
        return [file dir $filePath]
    }
}

proc amdRun {cmd} {
    set exe [lindex $cmd 0]
    if {[catch {exec which $exe}]} {
        return ""
    }
    if {"p4"==$exe && [db::getPrefValue amdDisableVersionControlIntegration]} {
        return ""
    }
    set res [eval "exec $cmd"]
    return $res
}


proc amdDisplaySchematic {{libName ""} {cellName ""} {viewName ""}} {
    if {[catch {set oaDes [ed]}]} {
        return 
    }
    
    if {""==$libName} {
        set libName [db::getAttr oaDes.libName]
        set cellName [db::getAttr oaDes.cellName]
        set viewName [db::getAttr oaDes.viewName]
    }
    set ctx [db::getNext [de::getContexts -filter {%window!="" && %editDesign.libName==$libName && %editDesign.cellName==$cellName && %editDesign.viewName==$viewName}]]
    if {""!=$ctx} {
        gi::setActiveWindow [db::getAttr ctx.window]
        gi::setActiveWindow [db::getAttr ctx.window] -raise true
    } else {
        de::open [dm::getCellViews $viewName -cellName $cellName -libName $libName -readOnly true]
    }
}

proc amdDisplayLayout {{libName ""} {cellName ""} {viewName ""}} {
    amdDisplaySchematic $libName $cellName $viewName
}

db::createPref amdDisableVersionControlIntegration \
    -type bool -value 0 \
    -description "Disable Version Control Integration"

}


