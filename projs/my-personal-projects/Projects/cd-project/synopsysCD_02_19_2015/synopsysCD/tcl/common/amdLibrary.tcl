# Copyright (c) 2004-2014 Synopsys, Inc. This Galaxy Custom Designer software
# and the associated documentation are confidential and proprietary to
# Synopsys, Inc. Your use or disclosure of this Galaxy Custom Designer software
# is subject to the terms and conditions of a written license agreement between
# you, or your company, and Synopsys, Inc.

#puts "amdLibrary"
namespace eval ::amd::amdLibrary {

namespace export *
namespace import -force ::amd::utils::*

# Round dimension up/down/to-nearest grid
proc amdSnapNumToGrid {num mfgGrid {direction ""}} {
    switch $direction {
        "nil" -
        "" {
            set ret [expr round($num/$mfgGrid)*$mfgGrid]
        }
        "up" {
            set ret [expr ceil($num/$mfgGrid)*$mfgGrid]
        }
        "down" {
            set ret [expr floor($num/$mfgGrid)*$mfgGrid]
        }
    }
    return $ret
}

# ** less than **
proc AMDalphaNumLessp {arg1 arg2 {exp 1}} {
    if {[alphaNumCmp $arg1 $arg2 $exp] == -1} {
        return -1
    }
    return 1
}

# ** less than or equal **
proc AMDalphaNumLeqp {arg1 arg2 {exp 1}} {
    if {[alphaNumCmp $arg1 $arg2 $exp] != 1} {
        return -1
    }
    return 1
}

# ** greater than **
proc AMDalphaNumGreaterp {arg1 arg2 {exp 1}} {
    if {[alphaNumCmp $arg1 $arg2 $exp] == 1} {
        return -1
    }
    return 1
}

# ** less than for sorting on car of 2 item lists (LPPs) **
proc AMDalphaNumLesspCar {arg1 arg2 {exp 1}} {
    if {([car $arg1]==[car $arg2] && [alphaNumCmp [cadr $arg1] [cadr $arg2] $exp]==-1) || [alphaNumCmp [car $arg1] [car $arg2] $exp]==-1} {
        return -1
    }
    return 1
}

# ** less than or equal on car of 2 item lists (LPPs) **
proc AMDalphaNumLeqpCar {arg1 arg2 {exp 1}} {
    if {([car $arg1]==[car $arg2] && [alphaNumCmp [cadr $arg1] [cadr $arg2] $exp]!=1) || [alphaNumCmp [car $arg1] [car $arg2] $exp]!=1} {
        return -1
    }
    return 1
}

# ** greater than on car of 2 item lists (LPPs) **
proc AMDalphaNumGreaterpCar {arg1 arg2 {exp 1}} {
    if {([car $arg1]==[car $arg2] && [alphaNumCmp [cadr $arg1] [cadr $arg2] $exp]==1) || [alphaNumCmp [car $arg1] [car $arg2] $exp]==1} {
        return -1
    }
    return 1
}

# ** less than for sorting on cadr of 2 item lists (LPPs) **
proc AMDalphaNumLesspCadr {arg1 arg2 {exp 1}} {
    if {([cadr $arg1]==[cadr $arg2] && [alphaNumCmp [car $arg1] [car $arg2] $exp]==-1) || [alphaNumCmp [cadr $arg1] [cadr $arg2] $exp]==-1} {
        return -1
    }
    return 1
}

# ** less than or equal on cadr of 2 item lists (LPPs) **
proc AMDalphaNumLeqpCadr {arg1 arg2 {exp 1}} {
    if {([cadr $arg1]==[cadr $arg2] && [alphaNumCmp [car $arg1] [car $arg2] $exp]!=-1) || [alphaNumCmp [cadr $arg1] [cadr $arg2] $exp]!=-1} {
        return -1
    }
    return 1
}

# ** greater than on cadr of 2 item lists (LPPs) **
proc AMDalphaNumGreaterpCadr {arg1 arg2 {exp 1}} {
    if {([cadr $arg1]==[cadr $arg2] && [alphaNumCmp [car $arg1] [car $arg2] $exp]==1) || [alphaNumCmp [cadr $arg1] [cadr $arg2] $exp]==1} {
        return -1
    }
    return 1
}

# ** less than Folded**
proc AMDalphaNumLesspFold {arg1 arg2 {exp 1}} {
    if {[alphaNumCmp [string tolower $arg1] [string tolower $arg2] $exp] == -1} {
        return -1
    }
    return 1
}

# ** less than or equal Folded **
proc AMDalphaNumLeqpFold {arg1 arg2 {exp 1}} {
    if {[alphaNumCmp [string tolower $arg1] [string tolower $arg2] $exp] != 1} {
        return -1
    }
    return 1
}

# ** greater than  Folded **
proc AMDalphaNumGreaterpFold {arg1 arg2 {exp 1}} {
    if {[alphaNumCmp [string tolower $arg1] [string tolower $arg2] $exp] == 1} {
        return -1
    }
    return 1
}

# ** less than for sorting on car of 2 item lists (LPPs)  Folded **
proc AMDalphaNumLesspCarFold {arg1 arg2 {exp 1}} {
    set arg1 [string tolower $arg1]
    set arg2 [string tolower $arg2]
    if {([car $arg1]==[car $arg2] && [alphaNumCmp [cadr $arg1] [cadr $arg2] $exp]==-1) || [alphaNumCmp [car $arg1] [car $arg2] $exp]==-1} {
        return -1
    }
    return 1
}

# ** less than or equal on car of 2 item lists (LPPs)  Folded **
proc AMDalphaNumLeqpCarFold {arg1 arg2 {exp 1}} {
    set arg1 [string tolower $arg1]
    set arg2 [string tolower $arg2]
    if {([car $arg1]==[car $arg2] && [alphaNumCmp [cadr $arg1] [cadr $arg2] $exp]!=1) || [alphaNumCmp [car $arg1] [car $arg2] $exp]!=1} {
        return -1
    }
    return 1
}

# ** greater than on car of 2 item lists (LPPs)  Folded **
proc AMDalphaNumGreaterpCarFold {arg1 arg2 {exp 1}} {
    set arg1 [string tolower $arg1]
    set arg2 [string tolower $arg2]
    if {([car $arg1]==[car $arg2] && [alphaNumCmp [cadr $arg1] [cadr $arg2] $exp]==1) || [alphaNumCmp [car $arg1] [car $arg2] $exp]==1} {
        return -1
    }
    return 1
}

# ** less than for sorting on cadr of 2 item lists (LPPs)  Folded **
proc AMDalphaNumLesspCadrFold {arg1 arg2 {exp 1}} {
    set arg1 [string tolower $arg1]
    set arg2 [string tolower $arg2]
    if {([cadr $arg1]==[cadr $arg2] && [alphaNumCmp [car $arg1] [car $arg2] $exp]==-1) || [alphaNumCmp [cadr $arg1] [cadr $arg2] $exp]==-1} {
        return -1
    }
    return 1
}

# ** less than or equal on cadr of 2 item lists (LPPs)  Folded **
proc AMDalphaNumLeqpCadrFold {arg1 arg2 {exp 1}} {
    set arg1 [string tolower $arg1]
    set arg2 [string tolower $arg2]
    if {([cadr $arg1]==[cadr $arg2] && [alphaNumCmp [car $arg1] [car $arg2] $exp]!=1) || [alphaNumCmp [cadr $arg1] [cadr $arg2] $exp]!=1} {
        return -1
    }
    return 1
}

# ** greater than on cadr of 2 item lists (LPPs)  Folded **
proc AMDalphaNumGreaterpCadrFold {arg1 arg2 {exp 1}} {
    set arg1 [string tolower $arg1]
    set arg2 [string tolower $arg2]
    if {([cadr $arg1]==[cadr $arg2] && [alphaNumCmp [car $arg1] [car $arg2] $exp]==1) || [alphaNumCmp [cadr $arg1] [cadr $arg2] $exp]==1} {
        return -1
    }
    return 1
}

# This function inverts the given transform
proc amdReverseTransform {transform} {
    if {![catch {db::getAttr transform.type}]} {
        set isObj 1
    } else {
        set isObj 0
    }

    if {$isObj} {
        set x  [oa::xOffset $transform] 
        set y  [oa::yOffset $transform]
        set orient [oa::getName [oa::orient $transform]]
        set mag 1
    } else {
            set xy [car $transform]
            set x  [car $xy]
            set y  [cadr $xy]
            set orient [cadr $transform]
            if {[llength $transform] == 3} {
                set mag [caddr $transform]
            } else {
                set mag 1
            }
    }
    switch $orient {
        "R0"  {
            set inv [list [list [expr -1*$x] [expr -1*$y] ] "R0" $mag]
        }
        "R90" {
            set inv [list [list [expr -1*$y] $x] "R270" $mag]
        }
        "R180" {
            set inv [list [list $x $y] "R180" $mag]
        }
        "R270" {
            set inv [list [list $y [expr -1*$x]] "R90" $mag]
        }
        "MY" {
            set inv [list [list $x [expr -1*$y]] "MY" $mag]
        }
        "MYR90" {
            set inv [list [list $y $x] "MYR90" $mag]
        }
        "MX" {
            set inv [list [list [expr -1*$x] $y] "MX" $mag]
        }
        "MXR90" {
            set inv [list [list [expr -1*y] [expr -1*$x]] "MXR90" $mag]
        }
    }
    return [oa::Transform [lindex $inv 0 0] [lindex $inv 0 1] [lindex $inv 1]]
            
}

# Add two points
proc AMDAddPts {pt1 pt2} {
        return [list [expr [lindex $pt1 0]+[lindex $pt2 0]] \
                     [expr [lindex $pt1 1]+[lindex $pt2 1]] ]
}

# Subtract two points
proc AMDSubPts {pt1 pt2} {
        return [list [expr [lindex $pt1 0]-[lindex $pt2 0]] \
                     [expr [lindex $pt1 1]-[lindex $pt2 1]] ]
}

# Add a point offset to both coordinates of a bbox
proc AMDIncrBBoxByPt {bbox pt} {
        return [list [AMDAddPts [lowerLeft $bbox] $pt] \
                     [AMDAddPts [upperRight $bbox] $pt]]
}


proc amdFormHelpFunc {helpTitle helpText} {
    gi::prompt $helpText -title $helpTitle -buttons "Close" -default "Close" -cancel "Close" -icon information
}

proc amdUniqList {lst {sortby ""}} {
    if {""==$sortby} {
        return [lsort -unique $lst]
    } else {
        return [lsort -unique -command $sortBy $lst]
    }
}

proc amdFloatEqual {pt1 pt2 {tol 1e-8}} {
    if {[expr abs($pt1 - $pt2)] < $tol} {
        return 1
    }
    return 0
}

proc amdFloatGreater {pt1 pt2 {tol 1e-8}} {
    if {$pt1 > $pt2 + $tol} {
        return 1
    }
    return 0
}

proc amdFloatLess {pt1 pt2 {tol 1e-8}} {
    if {$pt1 < $pt2 - $tol} {
        return 1
    }
    return 0
}

proc amdFloatGreaterOrEqual {pt1 pt2 {tol 1e-8}} {
    if {$pt1 >= $pt2 + $tol} {
        return 1
    }
    return 0
}

proc amdFloatLessOrEqual {pt1 pt2 {tol 1e-8}} {
    if {$pt1 <= $pt2 - $tol} {
        return 1
    }
    return 0
}

proc amdIsPointFullyInsidePolygon {point polygon} {
    set count 0
    foreach side [sides $polygon] {
        if {[ray_intersects_line $point $side]} {
            incr count
        }
    }
    expr {$count % 2} ;#-- 1 = odd = true, 0 = even = false
}
proc sides {listPolygon} {
    set polygon [list]
    foreach p $listPolygon {
        set polygon [concat $polygon $p]
    }
    set x0 [lindex $polygon 0 ]
    set y0 [lindex $polygon 1 ]
    foreach {x y} [lrange [lappend polygon $x0 $y0] 2 end] {
        lappend res [list $x0 $y0 $x $y]
        set x0 $x
        set y0 $y
    }
    return $res
}
proc ray_intersects_line {point line} {
    set Px [lindex $point 0]
    set Py [lindex $point 1]
    set Ax [lindex $line 0]
    set Ay [lindex $line 1]
    set Bx [lindex $line 2]
    set By [lindex $line 3]
    # Reverse line direction if necessary
    if {$By < $Ay} {
    set Ax [lindex $line 2]
    set Ay [lindex $line 3]
    set Bx [lindex $line 0]
    set By [lindex $line 1]

    }
    # Add epsilon to
    if {$Py == $Ay || $Py == $By} {
    set Py [expr {$Py + abs($Py)/1e6}]
    }
    # Bounding box checks
    if {$Py < $Ay || $Py > $By || $Px > [max $Ax $Bx]} {
    return 0
    } elseif {$Px < [min $Ax $Bx]} {
    return 1
    }
    # Compare dot products to compare (cosines of) angles
    set mRed [expr {$Ax != $Bx ? ($By-$Ay)/($Bx-$Ax) : [Inf]}]
    set mBlu [expr {$Ax != $Px ? ($Py-$Ay)/($Px-$Ax) : [Inf]}]
    return [expr {$mBlu >= $mRed}]
}

proc Inf {} {
    return "999999999"
}

}


