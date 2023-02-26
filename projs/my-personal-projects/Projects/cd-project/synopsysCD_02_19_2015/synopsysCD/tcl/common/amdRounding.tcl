# Copyright (c) 2004-2014 Synopsys, Inc. This Galaxy Custom Designer software
# and the associated documentation are confidential and proprietary to
# Synopsys, Inc. Your use or disclosure of this Galaxy Custom Designer software
# is subject to the terms and conditions of a written license agreement between
# you, or your company, and Synopsys, Inc.

namespace eval ::amd::utils {

namespace export *

variable amdTol 
variable amdGrd 0.001

# Calculate grid size for global tolerance - use 1/8 grid default
proc amdRounding_INIT {{oaTech ""}} {
    variable amdTol
    variable amdGrd 
    if {""!=$oaTech} {
        set amdGrd [techGetParam $oaTech "minGrid"]
    } else {
        set amdGrd [techGetParam [techGetTechFile $::amd::GVAR_amdEnvVariables(amdTechLibName)] "minGrid"]
    }
    if {""==$amdGrd} {
        set amdGrd "0.001"
    }
    set amdTol [expr $amdGrd/8.0]
    return ""
}

#; Rounding function
#; U/D have a bit of tolerance to not go to the next number if they're just
#; barely over the existing one
proc amdRnd {num {grid ""} {offset 0.0} } {
    variable amdGrd 
    if {""==$grid} {
        set grid $amdGrd
    }
    return [expr round($num/$grid)*$grid+$offset]
}

proc amdSnapPtToGrid {ptList {gridList ""} {offsetList ""}} {
    variable amdGrd 
    if {""==$gridList} {
        set gridList [list $amdGrd $amdGrd]
    }
    if {""==$offsetList} {
        set offsetList [list 0.0 0.0]
    }   
    return [list [amdRnd [car $ptList] [car $gridList] [car $offsetList]] [amdRnd [cadr $ptList] [cadr $gridList] [cadr $offsetList]]]
}

proc amdRndU {num {grid ""} {tol ""}} {
    variable amdGrd 
    if {""==$grid} {
        set grid $amdGrd
    }
    variable amdTol
    if {""==$tol} {
        set tol $amdTol
    }
    return [expr ceil($num/$grid-$tol)*$grid]
}

proc amdRndD {num {grid ""} {tol ""}} {
    variable amdGrd 
    if {$grid==""} {
        set grid $amdGrd
    }
    variable amdTol
    if {""==$tol} {
        set tol $amdTol
    }
    return [expr floor($num/$grid+$tol)*$grid]
}

# Comparison functions - with a bit of tolerance
proc amdLE {a b {tol ""}} {
    variable amdTol
    if {""==$tol} {
        set tol $amdTol
    }
    return [expr $a < $b+$tol]
}

proc amdLT {a b {tol ""} } {
    variable amdTol
    if {""==$tol} {
        set tol $amdTol
    }
    return [expr $a < $b-$tol]
}

proc amdEQ {a b {tol ""}} {
    variable amdTol
    if {""==$tol} {
        set tol $amdTol
    }
    return [expr abs($a-$b)<$tol]
}

proc amdGT {a b {tol "" }} {
    variable amdTol
    if {""==$tol} {
        set tol $amdTol
    }
    return [expr $a>$b+$tol]
}

proc amdGE {a b {tol ""}} {
    variable amdTol
    if {""==$tol} {
        set tol $amdTol
    }
    return [expr $a>$b-$tol]
}

proc amdIsNumOnGrid {num {grid ""}} {
    variable amdGrd
    if {""==$grid} {
        set grid $amdGrd
    }
    return [amdFloatEqual $num [amdRnd $num $grid]]
}

}
