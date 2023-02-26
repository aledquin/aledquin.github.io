# Copyright (c) 2004-2014 Synopsys, Inc. This Galaxy Custom Designer software
# and the associated documentation are confidential and proprietary to
# Synopsys, Inc. Your use or disclosure of this Galaxy Custom Designer software
# is subject to the terms and conditions of a written license agreement between
# you, or your company, and Synopsys, Inc.

namespace eval ::amd::_align {
variable amdPDKGrd 0.001
variable amdTol    0.000125

namespace export *
namespace import -force ::amd::utils::*
namespace import -force ::amd::amdLibrary::*
namespace import -force ::amd::amdLayLibrary::*

proc amdPDKGetGateSnapWidth {instId} {
    set w [db::getParamValue w -of $instId]
    set nf [db::getParamValue fingers -of $instId]
    if {""==$w || ""==$nf} {
        return 0.0
    } else {
        return [expr [atof [amdPDKConvertToMicrons $w]]/$nf]
    }
}

proc amdPDKGetGateSnapLength {instId} {
    set l [db::getParamValue l -of $instId]
    if {""==$l} {
        set l [db::getParamValue ln0 -of $instId]
    }
    if {""==$l} {
        return 0.0
    } else {
        return [return [atof [amdPDKConvertToMicrons $l]]]
    }
}

proc amdPDKConvertToMicrons {str} {
    if {[regexp {^[0-9]*[.]*[0-9][0-9]*[munf]} $str]} {
        set value [db::sciToEng $str -suffix u]
    } else {
        if {[regexp {[-+]?([0-9]+\.?[0-9]*|\.[0-9]+)([eE][-+]?[0-9]+)?} $str fvalue]} {
            set fvalue [expr $fvalue*1e-6]
            set value [db::sciToEng $fvalue -suffix u]
        } else {
            set value "0.0u"
        }
    }
    return $value
}

proc amdPDKRndD {num {grid ""} {tol ""}} {
    variable amdPDKGrd
    variable amdTol
    if {""==$grid} {
        set grid $amdPDKGrd
    }
    if {""==$tol} {
        set tol $amdTol
    }    
    return [expr floor($num/$grid+$tol)*$grid]
}


# General bounding box calculator for pcells (for alignment purposes)
# Dispatches to the proper function by cell name
proc amdPDKPcellCalcAlgnBox {inst} {
    if {[regexp {^(n|p)fin.*} [db::getAttr cellName -of $inst]] || [regexp {^(n|p)mos.*} [db::getAttr cellName -of $inst]] } {
        amdPDKMosPCCalcAlgnBox $inst
    } else {
        amdPDKAlgnBorder $inst
    }
}


proc amdPDKAlgnBorder {inst} {
    set mDes [db::getAttr master -of $inst]
    
    set prBoundary [oa::PRBoundaryFind [oa::getTopBlock $mDes]]
    if {""!=$prBoundary } {
        return [db::getAttr bBox -of $prBoundary]
    }  
    return [db::getAttr bBox -of $mDes]
}

proc amdPDKMosPCCalcAlgnBox {inst} {
    set oaDes [db::getAttr design -of $inst]
    set oaTech [techGetTechFile $oaDes]
    set mfgGrid [db::getAttr defaultManufacturingGrid -of $oaTech]
    set mfgGrid [expr round($mfgGrid/0.001)*0.001]
    set minL [amdPDKTechGetSpacingRule $oaTech "minWidth" "POLY"]
    set minW $mfgGrid

    if {[db::isEmpty [db::getParams w -of $inst]]} {
        set myW $minW
    } else {
        set w [db::engToSci [db::getParamValue  w -of $inst -evalType full -context [db::getAttr hierarchy -of [de::getActiveContext]]]]
        set w [expr $w*1e+6]
        set myW [amdPDKSnapNumToGridNear [max $w $minW] $mfgGrid]
    }
    
    if {[db::isEmpty [db::getParams l -of $inst]]} {
        set myL $minL
    } else {
        set l [db::engToSci [db::getParamValue  l -of $inst -evalType full -context [db::getAttr hierarchy -of [de::getActiveContext]]]]
        set l [expr $l*1e+6]
        set myL [max $l $minL]
    }
    
    set bBox ""
    set firtsIteration 1
    
    set shapes [db::getShapes -lpp {instance drawing} -of [db::getAttr master -of $inst]] 
    if {![db::isEmpty $shapes]} {
        return [mergeObjBBoxes $shapes]
    }
    
    set shapes [db::getShapes -lpp {POLY drawing} -of [db::getAttr master -of $inst]] 
    if {![db::isEmpty $shapes]} {
        return [mergeObjBBoxes $shapes]
    }    
    return $bBox
}


proc amdPDKTechGetParam {oaTech param {def ""}} {
    return [techGetParam $oaTech $param]
}


proc amdPDKTechGetSpacingRule {oaTech rule layer} {
    return [techGetSpacingRule $oaTech $rule $layer]
}

proc amdPDKSnapNumToGridNear {num mfgGrid} {
    return [expr round($num/$mfgGrid)*$mfgGrid]
}

}



