namespace eval ::amd::utils {

namespace export *

proc amdSnapLabels {grid {offset 0.0} {cv ""}} {
    if {""==$cv} {
        if {[catch {set cv [ed]}]} {
            return 0
        }
    }
    if {1==[llength $grid]} {
        if {[string is double $grid]} {
            set gridList [list $grid $grid]
        } else {
            de::sendMessage "Illegal grid specification, must be a list of floats/ints or a float/int - $grid\nExiting..."
            return 0
        }
    } else {
        set gridList $grid
    }
    
    if {1==[llength $offset]} {
        if {[string is double $offset]} {
            set offsetList [list $offset $offset]
        } else {
            de::sendMessage "Illegal offset specification, must be a list of floats/ints or a float/int - $offset\nExiting..."
            return 0
        }
    } else {
        set offsetList $offset
    }

    set tr [de::startTransaction "Snap Labels to Grid" -design $cv]
    db::foreach s [db::getShapes -of $cv -filter {%type=="Text" || %type=="PropDisplay" || %type=="AttrDisplay" || %type=="EvalText"}] {
        set newOrigin [amdSnapPtToGrid [db::getAttr origin -of $s] $gridList $offsetList]
        if {[xCoord [db::getAttr origin -of $s]]!=[xCoord $newOrigin] || [yCoord [db::getAttr origin -of $s]]!=[yCoord $newOrigin]} {
            db::setAttr origin -of $s -value $newOrigin
        }
    }
    de::endTransaction $tr
    return 1
}



}