# Copyright (c) 2004-2014 Synopsys, Inc. This Galaxy Custom Designer software
# and the associated documentation are confidential and proprietary to
# Synopsys, Inc. Your use or disclosure of this Galaxy Custom Designer software
# is subject to the terms and conditions of a written license agreement between
# you, or your company, and Synopsys, Inc.

namespace eval ::amd::_align {
namespace export *
namespace import -force ::amd::utils::*
namespace import -force ::amd::amdLibrary::*
namespace import -force ::amd::amdLayLibrary::*


#;;       ********** INSTANCE MOVER **********
#;; NOTE:  The compactor is slightly broken right now - sometimes when you have a 2d array of cells
#;;        packing horizontally and then vertically will result in the vertical stack not fully packing
#;;        because the corners end up preventing compaction - probably due to numerical inaccuracy.
proc amdMoveInstances { {insts ""} {edge ""} {addGapPerInst 0.0} \
                        {allowOverlaps "false"} {orderFrom "None"} \
                        {orderDirection "incr"} {relorient ""} \
                        {cellViewType "maskLayout"} } {

    if {[catch {set cv [ed]}]} {
        return 
    }
    if {"r"==[db::getAttr mode -of $cv]} {
        de::sendMessage "[getLCV $cv] is opened in read-only mode. Please reopen in write mode, before running align and compact utility." -severity error
        return 
    }     
    set coordSorted ""
    if {$insts==""} {set insts [de::getSelected -design $cv]}
    set paredInstList [db::filter $insts -filter {%objType=="Inst" \
                      || %object.type=="FigGroup" \
                      || %object.type=="Text"  || %object.type=="AttrDisplay" \
    }]

    if {[db::getAttr cv.viewType]!=$cellViewType} {
        de::sendMessage [format "Cannot do instance compaction on anything except a %s view. Currently you are working on %s %s %s" $cellViewType \
            [db::getAttr cv.libName] [db::getAttr cv.cellName] [db::getAttr cv.viewName] ] \
            -severity error
        return 0
    }

    if {![member $edge { "right" "top" "bottom" "left"}] } {
        return 0 
    }
    if {[db::getCount $paredInstList]==0} {
        de::sendMessage "You do not have any instances selected. This function aligns/compacts the instances that you have selected in the layout"
        return 0
    }

    set tr [de::startTransaction "Move Instances" -design $cv]
    set ns [namespace current]

    switch $edge {
        "left" {
            set coordSorted [dbSort [db::createList [db::getAttr object -of $paredInstList]] ${ns}::amdSortLayInstByWestEdge]
            set refInst [car $coordSorted]
            set lastXrefCoord [caar [amdReturnContextBBox $refInst]]
            if {$orderFrom!="None"} {
                if {$orderDirection=="Ascending" || $orderDirection=="incr"} {
                    set coordSorted [reverse [amdSortInstancesFromSchematic $coordSorted "EW"]]
                } else {
                    set coordSorted [amdSortInstancesFromSchematic $coordSorted "EW"]
                }
            }
            set yCoordList [list]
            foreach inst $coordSorted {
                set reforient ""
                set bBox [amdReturnContextBBox $inst]
                set topEdge [cadadr $bBox]
                set leftEdge [caar $bBox]
                set rightEdge [caadr $bBox]
                set bottomEdge [cadar $bBox]           
                set xCoordDelta [expr $lastXrefCoord - $leftEdge]
                if {!$allowOverlaps} {
                    set targetX $lastXrefCoord
                    foreach instEdges $yCoordList {
                        set instBottomEdge [car $instEdges]
                        set instTopEdge [cadr $instEdges]
                        if {($bottomEdge>=$instBottomEdge && $bottomEdge<$instTopEdge) || \
                            ($topEdge>$instBottomEdge && $topEdge<=$instTopEdge) || \
                            ($bottomEdge<=$instBottomEdge && $topEdge>=$instTopEdge) } {
                            #; We have a inst overlap.  Increase the target Y if it is larger.
                            if { [caddr $instEdges]>$targetX} {
                                set targetX [caddr $instEdges]
                                set reforient [cadddr $instEdges]
                            }      
                        } 
                        # ** when bottomEdge **
                    } 
                    #** foreach instEdges **
                    set xCoordDelta [expr $targetX - $leftEdge]
                }
                #; Move the instance
                amdSchLayStretch $inst $cv [list $xCoordDelta 0 "R0"]
                if {$relorient!="" && $reforient!=""} {
                    amdSetRelOrient $cv $inst $reforient $relorient "H"
                }

                if {!$allowOverlaps} {
                    set rightEdge [caadr [amdReturnContextBBox $inst]]
                    #;  Add the current instance window and give the target Y as it's bottom.
                    lappend yCoordList [list \
                                         $bottomEdge \
                                         $topEdge \
                                         [expr $rightEdge+$addGapPerInst*1.0] \
                                         [oa::getName [oa::getOrient $inst]] \
                                        ]
                }
            } 
            # ** foreach inst **
        }
        "right" {
            set coordSorted [dbSort [db::createList [db::getAttr object -of $paredInstList]] ${ns}::amdSortLayInstByEastEdge]
            set refInst [car $coordSorted]
            set lastXrefCoord [caadr [amdReturnContextBBox $refInst]]
            if {$orderFrom!="None"} {
                if {$orderDirection=="Ascending" || $orderDirection=="incr"} {
                    set coordSorted [amdSortInstancesFromSchematic $coordSorted "EW"]                    
                } else {
                    set coordSorted [reverse [amdSortInstancesFromSchematic $coordSorted "EW"]]                    
                }
            }
            set yCoordList [list]
            foreach inst $coordSorted {
                set reforient ""
                set bBox [amdReturnContextBBox $inst]
                set topEdge [cadadr $bBox]
                set leftEdge [caar $bBox]
                set rightEdge [caadr $bBox]
                set bottomEdge [cadar $bBox]           
                set xCoordDelta [expr $lastXrefCoord - $rightEdge]
                if {!$allowOverlaps} {
                    set targetX $lastXrefCoord
                    foreach instEdges $yCoordList {
                        set instBottomEdge [car $instEdges]
                        set instTopEdge [cadr $instEdges]
                        if {$bottomEdge>=$instBottomEdge && $bottomEdge<$instTopEdge || \
                            $topEdge>$instBottomEdge && $topEdge<=$instTopEdge || \
                            $bottomEdge<=$instBottomEdge && $topEdge>=$instTopEdge } {
                            #; We have a inst overlap.  Increase the target Y if it is larger.
                            if { [caddr $instEdges]<$targetX} {
                                set targetX [caddr $instEdges]
                                set reforient [cadddr $instEdges]
                            }      
                        } 
                        # ** when bottomEdge **
                    } 
                    #** foreach instEdges **
                    set xCoordDelta [expr $targetX - $rightEdge]
                }
                #; Move the instance
                amdSchLayStretch $inst $cv [list $xCoordDelta 0 "R0"]
                if {$relorient!="" && $reforient!=""} {
                    amdSetRelOrient $cv $inst $reforient $relorient "H"
                }

                if {!$allowOverlaps} {
                    set leftEdge [caar [amdReturnContextBBox $inst]]
                    #;  Add the current instance window and give the target Y as it's bottom.
                    lappend yCoordList [list \
                                         $bottomEdge \
                                         $topEdge \
                                         [expr $leftEdge-$addGapPerInst*1.0] \
                                         [oa::getName [oa::getOrient $inst]] \
                                        ]
                }
            } 
            # ** foreach inst **
        }
        "top" {
            set coordSorted [dbSort [db::createList [db::getAttr object -of $paredInstList]] ${ns}::amdSortLayInstByNorthEdge]
            set refInst [car $coordSorted]
            set lastYrefCoord [cadadr [amdReturnContextBBox $refInst]]
            if {$orderFrom!="None"} {
                if {$orderDirection=="Ascending" || $orderDirection=="incr"} {
                    set coordSorted [amdSortInstancesFromSchematic $coordSorted "NS"]                    
                } else {
                    set coordSorted [reverse [amdSortInstancesFromSchematic $coordSorted "NS"]]                    
                }
            }
            set xCoordList [list]
            foreach inst $coordSorted {
                set reforient ""
                set bBox [amdReturnContextBBox $inst]
                set topEdge [cadadr $bBox]
                set leftEdge [caar $bBox]
                set rightEdge [caadr $bBox]
                set bottomEdge [cadar $bBox] 
                set yCoordDelta [expr $lastYrefCoord - $topEdge]
                if {!$allowOverlaps} {
                    set targetY $lastYrefCoord
                    foreach instEdges $xCoordList {
                        set instLeftEdge [car $instEdges]
                        set instRightEdge [cadr $instEdges]
                        if {$leftEdge>=$instLeftEdge && $leftEdge<$instRightEdge || \
                            $rightEdge>$instLeftEdge && $rightEdge<=$instRightEdge || \
                            $leftEdge<=$instLeftEdge && $rightEdge>=$instRightEdge } {
                            #; We have a inst overlap.  Increase the target Y if it is larger.
                            if { [caddr $instEdges]<$targetY} {
                                set targetY [caddr $instEdges]
                                set reforient [cadddr $instEdges]
                            }      
                        } 
                    } 
                    #** foreach instEdges **
                    set yCoordDelta [expr $targetY - $topEdge]
                }
                #; Move the instance
                amdSchLayStretch $inst $cv [list 0 $yCoordDelta "R0"]
                if {$relorient!="" && $reforient!=""} {
                    amdSetRelOrient $cv $inst $reforient $relorient "V"
                }

                if {!$allowOverlaps} {
                    set bottomEdge [cadar [amdReturnContextBBox $inst]]
                    #;  Add the current instance window and give the target Y as it's bottom.
                    lappend xCoordList [list \
                                         $leftEdge \
                                         $rightEdge \
                                         [expr $bottomEdge-$addGapPerInst*1.0] \
                                         [oa::getName [oa::getOrient $inst]] \
                                        ]
                }
            } 
            # ** foreach inst **
        } 
        "bottom" {
            set coordSorted [dbSort [db::createList [db::getAttr object -of $paredInstList]] ${ns}::amdSortLayInstBySouthEdge]
            set refInst [car $coordSorted]
            set lastYrefCoord [cadar [amdReturnContextBBox $refInst]]
            if {$orderFrom!="None"} {
                if {$orderDirection=="Ascending" || $orderDirection=="incr"} {
                    set coordSorted [reverse [amdSortInstancesFromSchematic $coordSorted "NS"]]
                } else {
                    set coordSorted [amdSortInstancesFromSchematic $coordSorted "NS"]
                }
            }
            set xCoordList [list]
            foreach inst $coordSorted {
                set reforient ""
                set bBox [amdReturnContextBBox $inst]
                set topEdge [cadadr $bBox]
                set leftEdge [caar $bBox]
                set rightEdge [caadr $bBox]
                set bottomEdge [cadar $bBox]           
                set yCoordDelta [expr $lastYrefCoord - $bottomEdge]
                if {!$allowOverlaps} {
                    set targetY $lastYrefCoord
                    foreach instEdges $xCoordList {
                        set instLeftEdge [car $instEdges]
                        set instRightEdge [cadr $instEdges]
                        if {($leftEdge>=$instLeftEdge && $leftEdge<$instRightEdge) || \
                            ($rightEdge>$instLeftEdge && $rightEdge<=$instRightEdge) || \
                            ($leftEdge<=$instLeftEdge && $rightEdge>=$instRightEdge) } {
                            #; We have a inst overlap.  Increase the target Y if it is larger.
                            if { [caddr $instEdges]>$targetY} {
                                set targetY [caddr $instEdges]
                                set reforient [cadddr $instEdges]
                            }      
                        } 
                    } 
                    #** foreach instEdges **
                    set yCoordDelta [expr $targetY - $bottomEdge]
                }
                #; Move the instance
                amdSchLayStretch $inst $cv [list 0 $yCoordDelta "R0"]
                if {$relorient!="" && $reforient!=""} {
                    amdSetRelOrient $cv $inst $reforient $relorient "V"
                }

                if {!$allowOverlaps} {
                    set topEdge [cadadr [amdReturnContextBBox $inst]]
                    #;  Add the current instance window and give the target Y as it's bottom.
                    lappend xCoordList [list \
                                         $leftEdge \
                                         $rightEdge \
                                         [expr $topEdge+$addGapPerInst*1.0] \
                                         [oa::getName [oa::getOrient $inst]] \
                                        ]
                }
            } 
            # ** foreach inst **
        }  
    }
    # end switch edge
    de::endTransaction $tr
    if {""!=$coordSorted} {
        return 1
    }
    return 0
} 
# end amdMoveInstances

proc amdSetRelOrient {cv inst reforient relorient dir} {
    set obox [amdReturnContextBBox $inst]
    set iflipped [amdGetFlipped [oa::getName [oa::getOrient $inst]] $dir]
    set rflipped [amdGetFlipped $reforient $dir]
    if {("alt"==$relorient && $iflipped==$rflipped) || ("same"==$relorient && $iflipped!=$rflipped)} {
        if {"H"==$dir} {
            amdSchLayStretch $inst $cv [list 0 0 MY]
        } else {
            amdSchLayStretch $inst $cv [list 0 0 MX]
        }
        set nbox [amdReturnContextBBox $inst]
        amdSchLayStretch $inst $cv [list [expr [leftEdge $obox] - [leftEdge $nbox]] [expr [bottomEdge $obox] - [bottomEdge $nbox]] "R0"]
    }
}


proc amdGetFlipped {orient dir} {
    set r 1
    switch ${dir}${orient} {
        "HR0" {set r 0}
        "HR90" {set r 0}
        "HR180" {set r 1}
        "HR270" {set r 1}
        "HMX" {set r 0}
        "HMY" {set r 1}
        "HMXR90" {set r 1}
        "HMYR90" {set r 0}
        "VR0" {set r 0}
        "VR90" {set r 0}
        "VR180" {set r 1}
        "VR270" {set r 1}
        "VMX" {set r 1}
        "VMY" {set r 0}
        "VMXR90" {set r 0}
        "VMYR90" {set r 1}
        default {de::sendMessage "Unknown orientation ${orient}${dir} in amdGetFlipped" -severity warning}
    }
    return $r
}


proc dbSort {l sortProc} {
    return [lsort -command $sortProc $l]
}

#;; SORT INSTANCES BY LEFT EDGE OF BOUNDARY SHAPE
#;;

#;  ???  If the instances have the same west edge it should then sort using the south edge.
proc amdSortLayInstByWestEdge {list1 list2 } {
    if {[caar [amdReturnContextBBox $list1]] < [caar [amdReturnContextBBox $list2]]} {
        return -1
    } else {
        return 1
    }
}

#;;
#;; SORT INSTANCES BY RIGHT EDGE OF BOUNDARY SHAPE
#;;
#;  ???  If the instances have the same east edge it should then sort using the south edge.
proc amdSortLayInstByEastEdge {list1 list2 } {
    if {[caadr [amdReturnContextBBox $list1]] > [caadr [amdReturnContextBBox $list2]]} {
        return -1
    } else {
        return 1
    }
}

#;;
#;; SORT INSTANCES BY TOP EDGE OF BOUNDARY SHAPE
#;;

#;  ???  If the instances have the same north edge it should then sort using the west edge.
proc amdSortLayInstByNorthEdge {list1 list2} {
    if {[cadadr [amdReturnContextBBox $list1]] > [cadadr [amdReturnContextBBox $list2]]} {
        return -1
    } else {
        return 1
    }
}

#;;
#;; SORT INSTANCES BY BOTTOM EDGE OF BOUNDARY SHAPE
#;;

#;;  ???  If the instances have the same south edge it should then sort using the west edge.
proc amdSortLayInstBySouthEdge {list1 list2} {
    if { [cadar [amdReturnContextBBox $list1]] < [cadar [amdReturnContextBBox $list2]]} {
        return -1
    } else {
        return 1
    }
}


# This function takes a list of layout instances and the direction that they should be sorted by.  Either NS or EW
# Then it gets the schematic locations and sorted them so the final list is descending.
proc amdSortInstancesFromSchematic {layoutInstances direction} {
    set msg ""
    if {![llength $layoutInstances]} {
        set msg "No layout instances selected"
        de::sendMessage $msg -severity error
        return {}        
    }
    if {$direction!="NS" && $direction!="EW"} {
        set msg "Alignment direction must be NS or EW"
        de::sendMessage $msg -severity error
        return {}        
    }
    if {[catch {set cv [db::getAttr design -of [lindex $layoutInstances 0]]}]} {
        set msg "Unable to get current cellview"
        de::sendMessage $msg -severity error
        return {}        
    }
    
    set schCv ""
    set lxInt [oa::PropFind $cv "lxInternal"]
    if {""!=$lxInt} {
        set source [oa::PropFind $lxInt "source"]
        if {""==$source} {
            set msg "Unable to get source property. To use incr/decr, please have a schematic associated with this layout"
            de::sendMessage $msg -severity error
            return {}        
        }    
        set lib [oa::PropFind $source "lib"]
        if {""==$lib} {
            set msg "Unable to get library name"
            de::sendMessage $msg -severity error
            return {}        
        }    
        set cell [oa::PropFind $source "cell"]
        if {""==$cell} {
            set msg "Unable to get cell name"
            de::sendMessage $msg -severity error
            return {}
        }   
        set view [oa::PropFind $source "view"]
        if {""==$view} {
            set msg "Unable to get view name"
            de::sendMessage $msg -severity error
            return {}        
        }
        set libName [db::getAttr value -of $lib]
        set cellName [db::getAttr value -of $cell]
        set viewName [db::getAttr value -of $view]
        if {[catch {set schCv [oa::DesignOpen $libName $cellName $viewName "r"]}]} {
            set msg "Unable to open cellview $libName/$cellName/$viewName.\nTo use incr/decr, please have a schematic associated with this layout"
            de::sendMessage $msg -severity error
            return {}
        }        
    } else {
        set oaDes [db::getAttr design -of [lindex $layoutInstances 0]]
        set libName [db::getAttr libName -of $oaDes]
        set cellName [db::getAttr cellName -of $oaDes]
        set viewName "schematic"
        if {[oa::DesignExists $libName $cellName $viewName]} {
            set schCv [oa::DesignOpen $libName $cellName $viewName "r"]
        }
    } 


    set sortList [list]
    set coordSorted [list]
    if {""!=$schCv} {
        # Now build a sort structure with the info we need to sort on.
        foreach inst $layoutInstances {
            set name [db::getAttr inst.name]
            set results [amdGetSchCoord $schCv $name]
            set baseName [car $results]
            set busIndex [cadr $results]
            set xy [caddr $results]
            lappend sortList [list $xy $baseName $busIndex $inst]
        }
        oa::close $schCv
    
        set ns [namespace current]
        # Now sort the list on either x or y depending on dir
        if {$direction=="NS"} {
            set sortList [dbSort $sortList ${ns}::amdSortInstancesFromSchematicY]
        }
        if {$direction=="EW"} {
            set sortList [dbSort $sortList ${ns}::amdSortInstancesFromSchematicX]
        }

        if {[llength $sortList]} {
            foreach entry $sortList {
                lappend coordSorted [cadddr $entry]
            }
        }
        return $coordSorted 
    } else {
        foreach inst $layoutInstances {
            set instName [db::getAttr inst.name]
            set instName [regsub {\(} $instName "<"]
            set instName [regsub {\)} $instName ">"]
            lappend sortList [list $instName $inst]
        }
        set sortList [lsort -dictionary -index 0 -decreasing $sortList]
        foreach entry $sortList {
            lappend coordSorted [lindex $entry 1]
        }
        return $coordSorted       
    }    
}


proc amdGetSchCoord {cv instName} {
    set instName [regsub {\(} $instName "<"]
    set instName [regsub {\)} $instName ">"]
    set baseName [getBaseName $instName]
    set results [list "" "" ""]
    if {[regexp {\|} $instName]} {
        de::sendMessage "The instance alignment code does not work on hier" -severity error
    } else {
        set inst [db::getNext [db::getInsts $instName -of $cv]]    
        if {""!=$inst} {
            set busIndex [getIndex $instName]
            set results [list $baseName $busIndex [db::getAttr origin -of $inst]]
        }
        
    }
    return $results
}


proc amdSortInstancesFromSchematicY {list1 list2} {
    if {""==[car $list1] || ""==[car $list2]} {
        return -1
    }
    if {[amdFloatEqual [yCoord [car $list1]] [yCoord [car $list2]]]} {
        if {[string compare [cadr $list1] [cadr $list2]]==0} {
            if {[caddr $list1] < [caddr $list2] } {
                return 1
            } else {
                return -1
            }
        } else {
            return [string compare [cadr $list1] [cadr $list2]]
        }
    } else {
        if {[yCoord [car $list1]]<[yCoord [car $list2]]} {
            return 1
        } else {
           return -1
        }
    }
}

proc amdSortInstancesFromSchematicX {list1 list2} {
    if {""==[car $list1] || ""==[car $list2]} {
        return -1
    }
    if {[amdFloatEqual [xCoord [car $list1]] [xCoord [car $list2]]]} {
        if {[string compare [cadr $list1] [cadr $list2]]==0} {
            if {[caddr $list1] < [caddr $list2] } {
                return 1
            } else {
                return -1
            }
        } else {
            return [string compare [cadr $list1] [cadr $list2]]
        }
    } else {
        if {[xCoord [car $list1]]<[xCoord [car $list2]]} {
            return 1
        } else {
           return -1
        }
    }
}


# CALCULATE THE 'IN CONTEXT' BOUNDING BOX ( BASED ON LPP )
#
# Use template's bounding box if there's no border?  How to do this...
proc amdReturnContextBBox {db_inst} {
    variable GVAR_amdLayVariables
    set cv [db::getAttr design -of $db_inst]
    set techFile [db::getAttr tech -of $cv]
    set mfgGrid [oa::getDefaultManufacturingGrid $techFile]    
    
    switch [db::getAttr type -of $db_inst] {
        "FigGroup" {
            return [amdFigGroupAlignBox $db_inst]
        }
        "ScalarInst" -
        "VectorInstBit" {
            set obj [db::getAttr master -of $db_inst]
            set tr [db::getAttr transform -of $db_inst]
        }
        "Design" {
            set obj $db_inst
            set tr [oa::Transform 0 0 "R0"]
            # Next try to get the PRBoundary object as the box (NA: from design). 
        }
        "Rect" -
        "Path" -
        "PathSeg" -
        "AttrDisplay" -
        "Text" {
            return [db::getAttr bBox -of $db_inst]
        }
        "ArrayInst" {
             return [db::getAttr bBox -of $db_inst]
        }
        default {
            set obj ""
            set tr [oa::Transform 0 0 "R0"]
        }
    }; #End of switch

    set prBoundary [oa::PRBoundaryFind [oa::getTopBlock $obj]]
    if {""!=$prBoundary } {
        return [amdRoundBBox [dbTransformBBox  \
            [db::getAttr bBox -of $prBoundary] $tr] $mfgGrid ]
    }
            
    if {![info exists ::amd::GVAR_amdLayVariables(amdLayoutBorderLPP)]} {
        de::sendMessage "The border LPP to use is not defined for this project.  Please fix.\n" -severity error
        de::sendMessage "     : VAR: GVAR_amdLayVariables(\"amdLayoutBorderLPP\")\n"
        return 
    }
   
    # Special case for gate & fet pcells.
    # Made this so it will fail gracefully if the PDK doesn't define the functions...
    if { ""!=[info proc amdPDK_isgate] && ""!=[info proc amdPDK_gateAlignBox] \
        && [amdPDK_isgate $db_inst] } { 
        return [dbTransformBBox \
                [amdPDK_gateAlignBox $db_inst] [db::getAttr transform -of $db_inst] \
                ]
    }
        
    if { ""!=[info proc amdPDK_isfet] && ""!=[info proc amdPDK_fetAlignBox] \
        && [amdPDK_isfet $db_inst] } {
            return [dbTransformBBox \
                [amdPDK_fetAlignBox $db_inst] [db::getAttr transform -of $db_inst]
                ]
    }
    
    if {[amdDbInstIsPcell $db_inst]} {
        set bBox [amdPDKPcellCalcAlgnBox $db_inst]
        set bBox [amdRoundBBox [dbTransformBBox $bBox [db::getAttr transform -of $db_inst]] $mfgGrid]
        return $bBox
    }

    # Next see if we can find the LPP shape.  Print a error and state
    # that we will be using the bbox if we could not find the shape.
    set l_lpp  $::amd::GVAR_amdLayVariables(amdLayoutBorderLPP)
    set targetShapes [db::getShapes -of $obj -filter {%layerNum==[getLayerNumber [lindex $l_lpp 0] $obj] && %purposeNum==[getPurposeNumber [lindex $l_lpp 1] $obj]}]
    if {![db::isEmpty $targetShapes]} {
        # ??? Need to deal with polygon borders....
        set targetShape [db::getNext $targetShapes]
        if {[db::getCount $targetShapes]>1} {
            de::sendMessage [format "WARNING: Found more than 1 border shape in %s.  \
                Using the first one." [db::getAttr cellName -of $db_inst]]
        }
        return [amdRoundBBox [dbTransformBBox [db::getAttr bBox -of $targetShape] $tr ] $mfgGrid]
    }
    # No LPP shape - if there's a template cell, use its border
    db::foreach inst [db::getInsts -of $obj] {
        if { [db::getAttr inst.cellName] == "ska_stdcell_template" } {
            return [amdRoundBBox \
                [dbTransformBBox [amdReturnContextBBox $inst] $tr ] $mfgGrid]
        }
        if {[db::getAttr inst.cellName] == "lib45_stdcell_template"} {
            return [amdRoundBBox
                [dbTransformBBox [amdReturnContextBBox $inst] $tr ] $mfgGrid]
        }
    } ; #** foreach inst **

    return [db::getAttr bBox -of $db_inst] 

}

proc  amdFigGroupAlignBox {group} {
    if {[db::getAttr group.type]!="FigGroup"} {return ""}
    set bbox ""
    db::foreach thing [db::getAttr group.members] {
        set tb [amdReturnContextBBox $thing]
        if {$tb!=""} {
            if {$bbox==""} {
                set bbox $tb
            } else {
                set bbox [list \
                        [list [min [leftEdge $tb] [leftEdge $bbox]] [min [bottomEdge $tb] [bottomEdge $bbox]]] \
                        [list [max [rightEdge $tb] [rightEdge $bbox]] [max [topEdge $tb] [topEdge $bbox]]] \
                        ]
            }
        }
    } ; #** foreach thing **
    return $bbox
} 


# Round an entire bounding box
proc amdRoundBBox {bbox mfgGrid} {
    set l [amdSnapNumToGrid [leftEdge $bbox] $mfgGrid]
    set b [amdSnapNumToGrid [bottomEdge $bbox] $mfgGrid]
    set r [amdSnapNumToGrid [rightEdge $bbox]  $mfgGrid]
    set t [amdSnapNumToGrid [topEdge $bbox]    $mfgGrid]
    return [list [list $l $b] [list $r $t]]
}

proc amdPAChangeSize {cv {width ""} {height ""} {square ""} {sel ""} } {
    set tf [techGetTechFile $cv]
    if {""==$sel} {
        set sel [de::getSelected -design $cv]
    }
    if {""!=$square} {
        set width  $square
        set height $square
    }

    set objs [db::filter $sel -filter {%this.object.pin!="" && %this.object.type=="Rect"}]
    db::foreach obj $objs {
        set pin [db::getAttr object -of $obj]
        set box [db::getAttr pin.bBox]
        set center [centerBox $box]
        set minw [techGetSpacingRule $tf "minWidth" [getShapeLayerName $pin]]
        if {$height!=""} {
            if {$minw!=""} {
                set height [max $minw $height]
            }
        } else {
            set height [expr [topEdge $box]-[bottomEdge $box]]
        }
        if {$width!=""} {
            if {$minw!=""} {
                    set width [max $minw $width]
            }
        } else {
            set width [expr [rightEdge $box]-[leftEdge $box]]
        }
        # UBTS #377505: Calculate points as offset from
        # center, but snap result to grid.
        set ll [amdSnapPointToGrid \
                [list [expr [xCoord $center]-double($width)/2] \
                      [expr [yCoord $center]-double($height)/2] ] \
                [de::getActiveContext]
                ]
        set ur [amdSnapPointToGrid [list \
                                       [expr [xCoord $ll]+$width] \
                                       [expr [yCoord $ll]+$height]] \
                [de::getActiveContext] ]
        set box [list $ll $ur]
        db::setAttr pin.bBox -value $box
    }
}

# Align pins on edge to inst term
proc amdAlignPin {pin side src} {
    set loc ""
    set design [db::getAttr pin.design]
    set border [amdReturnContextBBox $design]
    set pinType [db::getAttr type -of $pin]
    if {$pinType!="Rect" || [db::getAttr pin.pin]==""} {
        de::sendMessage "amdAlignPin: Pin type ($pinType) must be Rect and it must have a pin object."
            return 
    }
    set layer [getLayerName [db::getAttr pin.layerNum] $design]
    set locs [amdFindPinLocs $pin $src]
    set prune [list]
    foreach loc $locs {
        if {[lindex $loc 0]==$layer} {
            lappend prune $loc
        }
    }
    if {[llength $prune]!=0} {
        set loc [cadr [car $prune]]
    } else {
        set loc [cadr [car $locs]]
    }
    if {""!=$loc} {
        set pinCenter [centerBox [db::getAttr pin.bBox]]
        set delt [AMDSubPts $loc $pinCenter]
        # Move pin
        le::move $pin -dx [lindex $delt 0] -dy [lindex $delt 1] -rotate "R0"
    }
    # Now align with the correct edge
    set delt {0.0 0.0}
    set pinBbox [db::getAttr pin.bBox]
    switch $side {
        "L" {
            set delt [list [expr [leftEdge $border]-[leftEdge $pinBbox]] 0]
        }
        "R" {
            set delt [list [expr [rightEdge $border]-[rightEdge $pinBbox]] 0]
        }
        "U" {
            set delt [list 0 [expr [topEdge $border]-[topEdge $pinBbox]]]
        }
        "D" {
            set delt [list 0 [expr [bottomEdge $border]-[bottomEdge $pinBbox]]]
        }
    }
    le::move $pin -dx [lindex $delt 0] -dy [lindex $delt 1] -rotate "R0"
    if {$side=="c" || $side=="C"} {
        ::amd::_autoPin::amdLeAutoAdjustPinLabel $pin
    } else {
        ::amd::_autoPin::amdLeAdjustPinLabel $pin $side 
    }
}


# Find pin locations
# If searching children, look for instance terms
# If searching parents, look for pins and other instance terms
# FIXME: currently broken for mosaics and arrays
# added AMDIsOAVersion() to use "allInstTerms" and "...pins~>figs"
proc amdFindPinLocs {pin {src "Child"} } {
    set locs [list]
    if {[catch {set design [ed]}]} {
        return 
    }  

    switch $src {
        "Child" {
            set net [db::getAttr pin.pin.term.net]
            set instTerms [db::getInstTerms -of $net]
            db::foreach it $instTerms {
                set tr [db::getAttr it.inst.transform]
                set pinFigs [getTermPinsFigs $it $design]
                if {$pinFigs==""} {
                    continue
                }
                db::foreach fig $pinFigs {
                    lappend locs [list \
                        [getLayerName [db::getAttr fig.layerNum] $design] \
                        [dbTransformPoint [centerBox [db::getAttr fig.bBox]] $tr] \
                        $fig \
                        $tr\
                        ]
                }
            }
            return $locs
        }
        "Parent" {
            set tmp [amdGeGetParentAndInst]
            if {$tmp==""} {
                de::sendMessage "Editting at top level, can't do alignment with parent\n"
                return ""
            }
            set inst [lindex $tmp 1]
            set terms [setof [db::getAttr inst.instTerms]\
                             {%name==[db::getAttr pin.pin.term.name]} ]
            if {0==[db::getCount $terms]} {return ""}
            set net [db::getAttr net -of [db::getNext $terms]]
            set terms [db::getInstTerms -of $net -filter {%inst!=$inst} ]
            db::foreach term $terms {
                set tr [dbConcatTransform [db::getAttr term.inst.transform] \
                                          [amdReverseTransform [db::getAttr inst.transform]]]
                set pinFigs [getTermPinsFigs $term $design]
                db::foreach fig $pinFigs { 
                     lappend locs [list \
                         [getLayerName [db::getAttr fig.layerNum] $design] \
                         [dbTransformPoint [centerBox [db::getAttr fig.bBox]] $tr] \
                         $fig \
                         $tr]
                }
            } ; #** foreach term **
            db::foreach pp [db::getPins -of $net] {
                if {[db::getAttr pp.figs] !="" } {
                    set tr [amdReverseTransform [db::getAttr inst.transform]]
                    db::foreach fig [db::getAttr pp.figs] {
                        lappend locs [list \
                            [getLayerName [db::getAttr fig.layerNum] $design] \
                            [dbTransformPoint [centerBox [db::getAttr fig.bBox]] $tr] \
                            $fig\
                            $tr]
                    }
                }
            }
            return $locs
        }
    }
}

#;; Return the cellview of the parent and the instance of the current edited cellview
#;; or nil if there's no parent (editing top level)
proc amdGeGetParentAndInst {} {
    if {[catch {set ctx [de::getActiveContext]}]} {
        return 
    }  
    set path [db::getAttr ctx.hierarchy.occurrence]
    # Check nad see if we're at the top level - if so, return nil
    if {[db::getAttr ctx.hierarchy.isRoot]} {
        return ""
    }
    # Find the parent cellview
    set parent [db::getAttr ctx.hierarchy.parentInst.design]
    # Find the instance
    set inst [db::getAttr ctx.hierarchy.parentInst]
    return [list $parent $inst]
}


proc amdAlignCreateWindowProc {w} {
}

proc amdGetAlignWinInstance {} {
    variable alignWT
    set w [db::getNext [gi::getWindows -filter {%windowType.name=="$alignWT"}]]
    return $w
}

proc amdAlignInstancesForm {} {
    variable alignWT
    set win [amdGetAlignWinInstance]
    if {""==$win} {
        set ns [namespace current]
        set win [gi::createWindow -windowType [gi::getWindowTypes $alignWT]]
        set tab [gi::createTabGroup tabGroup -parent $win]
        set gr1 [gi::createGroup page1 -parent $tab -label "Build"]
        set gr2 [gi::createGroup page2 -parent $tab -label "Compact"]
        set gr3 [gi::createGroup page3 -parent $tab -label "Snap"]
        
        # GROUP 1
        set buttonsgr1 [gi::createGroup -parent $gr1 -decorated true]
        amdAlignGuiButtons $buttonsgr1

        set buttonsgr2 [gi::createGroup -parent $gr1 -decorated false]
        set groupBtn [gi::createPushButton -parent $buttonsgr2 -label "Group" -execProc  "${ns}::amdMakeLayoutGroup"]
        set ungrpBtn [gi::createPushButton -parent $buttonsgr2 -label "Ungroup" -execProc  "${ns}::amdUnmakeLayoutGroup"]
        gi::layout $ungrpBtn -rightOf $groupBtn
        gi::createNumberInput amdLayoutInstAlignGap -parent $buttonsgr2 -label "Gap" -valueType float -value 0.0

        set altBtn [gi::createBooleanInput altbtn -parent $buttonsgr2 -label "alt" -valueChangeProc "${ns}::amdLayoutInstFormCB" -prefName amdAlignAlt ]
        set sameBtn [gi::createBooleanInput samebtn -parent $buttonsgr2 -label "same" -valueChangeProc "${ns}::amdLayoutInstFormCB" -prefName amdAlignSame ]
        set incrBtn [gi::createBooleanInput incrbtn -parent $buttonsgr2 -label "incr" -valueChangeProc "${ns}::amdLayoutInstFormCB" -prefName amdAlignIncr ]
        set decrBtn [gi::createBooleanInput decrbtn -parent $buttonsgr2 -label "decr" -valueChangeProc "${ns}::amdLayoutInstFormCB" -prefName amdAlignDec ]
        gi::layout $sameBtn -rightOf $altBtn
        gi::layout $decrBtn -rightOf $incrBtn -align $sameBtn

        set undoBtn [gi::createPushButton -parent $buttonsgr2 -label "Undo" -execProc  "${ns}::amdUndo"]
        gi::layout $buttonsgr2 -rightOf $buttonsgr1

        # GROUP 2
        set buttonsgr1 [gi::createGroup -parent $gr2 -decorated true -label "Align"]
        amdAlignGuiButtonsCompact $buttonsgr1 "amdAlignInstances"
        set buttonsgr2 [gi::createGroup -parent $gr2 -decorated true -label "Compact"]
        amdAlignGuiButtonsCompact $buttonsgr2 "amdCompactInstances"
        gi::layout $buttonsgr2 -rightOf $buttonsgr1

        set buttonsgr3 [gi::createGroup -parent $gr2 -decorated false]
        set groupBtn [gi::createPushButton -parent $buttonsgr3 -label "Group" -execProc  "${ns}::amdMakeLayoutGroup"]
        set ungrpBtn [gi::createPushButton -parent $buttonsgr3 -label "Ungroup" -execProc  "${ns}::amdUnmakeLayoutGroup"]
        gi::layout $ungrpBtn -rightOf $groupBtn
        gi::createNumberInput amdLayoutInstAlignGap -parent $buttonsgr3 -label "Gap" -valueType float -value 0.0

        set altBtn [gi::createBooleanInput altbtn -parent $buttonsgr3 -label "alt" -valueChangeProc "${ns}::amdLayoutInstFormCB" -prefName amdAlignAlt ]
        set sameBtn [gi::createBooleanInput samebtn -parent $buttonsgr3 -label "same" -valueChangeProc "${ns}::amdLayoutInstFormCB" -prefName amdAlignSame ]
        set incrBtn [gi::createBooleanInput incrbtn -parent $buttonsgr3 -label "incr" -valueChangeProc "${ns}::amdLayoutInstFormCB" -prefName amdAlignIncr ]
        set decrBtn [gi::createBooleanInput decrbtn -parent $buttonsgr3 -label "decr" -valueChangeProc "${ns}::amdLayoutInstFormCB" -prefName amdAlignDec ]
        gi::layout $sameBtn -rightOf $altBtn
        gi::layout $decrBtn -rightOf $incrBtn -align $sameBtn

        set undoBtn [gi::createPushButton -parent $buttonsgr3 -label "Undo" -execProc  "${ns}::amdUndo"]
        gi::layout $buttonsgr3 -rightOf $buttonsgr2

        # GROUP 3
        set xGridFld [gi::createNumberInput xGridFld -parent $gr3 -label "X Grid" -valueType float -prefName amdAlignXGrid]
        set xOffFld [gi::createNumberInput xOffFld -parent $gr3 -label "X Off" -valueType float -prefName amdAlignXOff]
        set yGridFld [gi::createNumberInput yGridFld -parent $gr3 -label "Y Grid" -valueType float -prefName amdAlignYGrid]
        set yOffFld [gi::createNumberInput yOffFld -parent $gr3 -label "Y Off" -valueType float -prefName amdAlignYOff]
        gi::layout $yGridFld -rightOf $xGridFld
        gi::layout $yOffFld -rightOf $xOffFld -align $yGridFld
        db::setAttr shown -of [db::getAttr statusbar -of $win] -value 0

        set snapCellBtn [gi::createPushButton -parent $gr3 -label "Snap Cells" -execProc "${ns}::amdLayoutInstancesSnapCells"]
        set snapLblBtn [gi::createPushButton -parent $gr3 -label "Snap Labels" -execProc "${ns}::amdLayoutInstancesSnapLabels"]
        set undoBtn [gi::createPushButton -parent $gr3 -label "Undo" -execProc "${ns}::amdUndo"]
        gi::layout $snapLblBtn -rightOf $snapCellBtn -align $yGridFld
        db::setAttr undoBtn.styleSheet -value "QPushButton {width: 250;}"
        db::setAttr shown -of $gr3 -value false
        after idle [list db::setAttr geometry -of $win -value "494x100+70%+10%"]
    } else {
        gi::setActiveWindow $win -raise true
        db::setAttr iconified -of $win -value false    
    }
}

proc amdAlignGuiButtonsCompact {gr procName} {
    set ns [namespace current]
 
    set lbl1 [gi::createLabel -parent $gr -label ""]
    set btn1 [gi::createPushButton -parent $gr -icon "arrow_up" -execProc "${ns}::${procName} top"]
    set lbl2 [gi::createLabel -parent $gr -label ""]
    
    set btn2 [gi::createPushButton -parent $gr -icon "arrow_left" -execProc "${ns}::${procName} left"]
    set lbl3 [gi::createLabel -parent $gr -label ""]
    set btn3 [gi::createPushButton -parent $gr -icon "arrow_right" -execProc "${ns}::${procName} right"]

    set lbl4 [gi::createLabel -parent $gr -label ""]
    set btn4 [gi::createPushButton -parent $gr -icon "arrow_down" -execProc "${ns}::${procName} bottom"]
    set lbl5 [gi::createLabel -parent $gr -label ""]

    gi::layout $btn1 -rightOf $lbl1 -align $lbl3
    gi::layout $lbl2 -rightOf $btn1 -align $btn3

    gi::layout $btn2 -align $lbl1
    gi::layout $lbl3 -rightOf $btn2 -align $btn1
    gi::layout $btn3 -rightOf $lbl3 -align $lbl2

    gi::layout $btn4 -rightOf $lbl4 -align $lbl3
    gi::layout $lbl5 -rightOf $btn4
}


proc amdAlignGuiButtons {gr} {
    set ns [namespace current]
 
    set lbl1 [gi::createLabel -parent $gr -label ""]
    set btn1 [gi::createPushButton -parent $gr -label "" -execProc "${ns}::amdAlignObjects right Low/Left"]
    db::setAttr btn1.styleSheet -value "QPushButton {border-image: url([lindex [db::resolve images/arrow_u_r_icon.xpm] 0]); width: 15; height: 40; padding: 0; margin: 0;}"
    set btn2 [gi::createPushButton -parent $gr -label "" -execProc "${ns}::amdAlignObjects left Low/Left"]
    db::setAttr btn2.styleSheet -value "QPushButton {border-image: url([lindex [db::resolve images/arrow_u_l_icon.xpm] 0]); width: 15; height: 40; padding: 0; margin: 0;}"
    set lbl2 [gi::createLabel -parent $gr -label ""]
    
    set btn3 [gi::createPushButton -parent $gr -label "" -execProc "${ns}::amdAlignObjects bottom Up/Right"]
    db::setAttr btn3.styleSheet -value "QPushButton {border-image: url([lindex [db::resolve images/arrow_l_b_icon.xpm] 0]); width: 40; height: 15; padding: 0; margin: 0;}"
    set btn4 [gi::createPushButton -parent $gr -label "" -execProc "${ns}::amdAlignObjects top Up/Right"]
    db::setAttr btn4.styleSheet -value "QPushButton {border-image: url([lindex [db::resolve images/arrow_l_u_icon.xpm] 0]); width: 40; height: 15; padding: 0; margin: 0;}"
    set lbl3 [gi::createLabel -parent $gr -label ""]
    set btn5 [gi::createPushButton -parent $gr -label "" -execProc "${ns}::amdAlignObjects bottom Low/Left"]
    db::setAttr btn5.styleSheet -value "QPushButton {border-image: url([lindex [db::resolve images/arrow_r_b_icon.xpm] 0]); width: 40; height: 15; padding: 0; margin: 0;}"
    set btn6 [gi::createPushButton -parent $gr -label "" -execProc "${ns}::amdAlignObjects top Low/Left"]
    db::setAttr btn6.styleSheet -value "QPushButton {border-image: url([lindex [db::resolve images/arrow_r_u_icon.xpm] 0]); width: 40; height: 15; padding: 0; margin: 0;}"

    set lbl4 [gi::createLabel -parent $gr -label ""]
    set btn7 [gi::createPushButton -parent $gr -label "" -execProc "${ns}::amdAlignObjects right Up/Right"]
    db::setAttr btn7.styleSheet -value "QPushButton {border-image: url([lindex [db::resolve images/arrow_d_r_icon.xpm] 0]); width: 15; height: 40; padding: 0; margin: 0;}"
    set btn8 [gi::createPushButton -parent $gr -label "" -execProc "${ns}::amdAlignObjects left Up/Right"]
    db::setAttr btn8.styleSheet -value "QPushButton {border-image: url([lindex [db::resolve images/arrow_d_l_icon.xpm] 0]); width: 15; height: 40; padding: 0; margin: 0;}"
    set lbl5 [gi::createLabel -parent $gr -label ""]

    gi::layout $btn1 -rightOf $lbl1 -align $lbl3
    gi::layout $btn2 -rightOf $btn1
    gi::layout $lbl2 -rightOf $btn2 -align $btn5

    gi::layout $btn3 -align $lbl1
    gi::layout $btn4 -align $lbl1
    gi::layout $lbl3 -rightOf $btn3 -align $btn1
    gi::layout $btn5 -rightOf $lbl3 -align $lbl2

    gi::layout $btn6 -align $btn5 -rightOf $btn4

    gi::layout $btn7 -rightOf $lbl4 -align $lbl3
    gi::layout $btn8 -rightOf $btn7
    gi::layout $lbl5 -rightOf $btn8 -align $btn5
}

# this is a main function that get envoked on all compact directions buttons
proc amdAlignObjects {direction justify_value w} {
    if {[catch {set oaDes [ed]}]} {
        return 
    }
    if {"r"==[db::getAttr mode -of $oaDes]} {
        de::sendMessage "[getLCV $oaDes] is opened in read-only mode. Please reopen in write mode, before running align and compact utility." -severity error
        return 
    }
    set altValue ""
    set sortValue ""
    set success 1
    set win [getParentWindow $w]
    de::abortCommand
    set page1 [gi::findChild page1 -in $win]
    set gapValue [gi::findChild amdLayoutInstAlignGap.value -in $page1]

    if {[db::getPrefValue amdAlignAlt]} {
        set altValue "alt"
    } elseif  {[db::getPrefValue amdAlignSame]} {
        set altValue "same"
    } 
    if {[db::getPrefValue amdAlignIncr]} {
        set sortValue "incr"
    } elseif  {[db::getPrefValue amdAlignDec]} {
        set sortValue "decr"
    } 
    # first justify all the instances to the edge if needed
    # Usage of the  amdMoveInstances : edge "top" "addGapPerInst" 0.0 "allowOverlaps" nil "orderFrom" "None" "orderDirection" "Ascending")

    set tr [de::startTransaction "Align Objects" -design $oaDes]
    if {![amdMoveInstances "" $direction 0.0 1 "None" ""]} {
        return 
    }

    # We just did justification so lets figure out in which direction to compact
    set dir $direction
    switch $dir {
        "top" {
            switch $justify_value {
                "Low/Left" { set dir "left"}
                "Up/Right" { set dir "right"}
            }
        }
        "right" {
            switch $justify_value {
                "Low/Left" { set dir "bottom"}
                "Up/Right" { set dir "top"}
            }
        }
        "bottom" {
            switch $justify_value {
                "Low/Left" { set dir "left"}
                "Up/Right" { set dir "right"}
            }
        }
        "left" {
            switch $justify_value {
                "Low/Left" { set dir "bottom"}
                "Up/Right" { set dir "top"}
            }
        }
    }

    if {""!=$sortValue} {
        set orderForm "Schematic"
    } else {
        set orderForm "None"
    }
    set success [amdMoveInstances "" $dir $gapValue 0 $orderForm $sortValue $altValue]
    
    # Get bbox of that group that was just compacted
    set setbBox [amdLayoutCalcSetBBox]
    
    set xl [leftEdge $setbBox]
    set yl [bottomEdge $setbBox]
    set xh [rightEdge $setbBox]
    set yh [topEdge $setbBox]
    

    # Decide which corner to use as the reference point of the move
    switch $direction {
        "top" {
            switch $justify_value {
                "Low/Left" { 
                    set xr $xl
                    set yr $yh
                 }
                "Up/Right" { 
                    set xr $xh
                    set yr $yh
                 }
            }
        }
        "right" {
            switch $justify_value {
                "Low/Left" {
                    set xr $xh
                    set yr $yl
                 }
                "Up/Right" { 
                    set xr $xh
                    set yr $yh
                 }
            }
        }
        "bottom" {
            switch $justify_value {
                "Low/Left" { 
                    set xr $xl
                    set yr $yl
                 }
                "Up/Right" { 
                    set xr $xh
                    set yr $yl
                 }
            }
        }
        "left" {
            switch $justify_value {
                "Low/Left" { 
                    set xr $xl
                    set yr $yl
                 }
                "Up/Right" { 
                    set xr $xl
                    set yr $yh
                 }
            }
        }
    }
    de::endTransaction $tr
    if {$success} {
        ile::move
        de::addPoint [list $xr $yr]
    }    
}


# Calculates bbox of the selected set
proc amdLayoutCalcSetBBox {{cv ""}} {
    if {""==$cv} {
        if {[catch {set cv [ed]}]} {
            return 
        }
    }
    set bbox {}
    db::foreach obj [db::getAttr object -of [de::getSelected -design $cv]] {
        if {""==$bbox} {
            set bbox [db::getAttr bBox -of $obj]
        } else {
            set bbox [oa::merge [box2oaBox [db::getAttr bBox -of $obj]] [box2oaBox $bbox]]
        }
    }
    return $bbox
}


# Make a layout group
proc amdMakeLayoutGroup {w} {
    if {[catch {set cv [ed]}]} {
        return 
    }
    if {"r"==[db::getAttr mode -of $cv]} {
        de::sendMessage "[getLCV $cv] is opened in read-only mode. Please reopen in write mode, before running align and compact utility." -severity error
        return 
    }    
    set sel [de::getSelected -design $cv]
    if {[db::isEmpty $sel]} {
        return ""
    }
    set tr [de::startTransaction "Create FigGroup" -design $cv]
    set fg [oa::FigGroupCreate [oa::getTopBlock $cv]]
    le::addToFigGroup $sel -to $fg
    # set origin to lower-left
    set bbox [amdFigGroupAlignBox $fg]
    if {""!=$bbox} {
        oa::setOrigin $fg [oa::Point [lowerLeft $bbox]]
    }
    de::select $fg
    de::endTransaction $tr
    return $fg
}


# Unmake a layout group
proc amdUnmakeLayoutGroup {w} {
    if {[catch {set cv [ed]}]} {
        return 
    }
    if {"r"==[db::getAttr mode -of $cv]} {
        de::sendMessage "[getLCV $cv] is opened in read-only mode. Please reopen in write mode, before running align and compact utility." -severity error
        return 
    }    
    set sel [db::getAttr object -of [de::getSelected -design $cv -filter {%objType=="FigGroup"}]]
    set tr [de::startTransaction "Destroy FigGroup" -design $cv]
    db::foreach obj $sel {
        set fgMembers [db::getAttr members -of $obj]
        db::destroy $obj
        de::select $fgMembers
    }
    de::endTransaction $tr
}


proc amdUndo {w} {
    if {[catch {set cv [ed]}]} {
        return 
    }
    if {"r"==[db::getAttr mode -of $cv]} {
        de::sendMessage "[getLCV $cv] is opened in read-only mode. Please reopen in write mode, before running align and compact utility." -severity error
        return 
    }     
    de::undoTransaction -design $cv
}

proc amdLayoutInstFormCB {w} {
    switch [db::getAttr name -of $w] {
        "altbtn" {
            if {[db::getAttr value -of $w]} {
                db::setPrefValue amdAlignSame -value 0
            }        
        }
        "samebtn" {
            if {[db::getAttr value -of $w]} {
                db::setPrefValue amdAlignAlt -value 0
            }          
        }
        "incrbtn" {
            if {[db::getAttr value -of $w]} {
                db::setPrefValue amdAlignDec -value 0
            }
        }
        "decrbtn" {
            if {[db::getAttr value -of $w]} {
                db::setPrefValue amdAlignIncr -value 0
            }        
        }
    }
}

###############################################################################
# amdCompactInstances and amdAlignInstances are called from the Compact tab.
# They are just wrappers to amdMoveInstances that capture the GUI settings.
###############################################################################
proc amdAlignInstances {edge w} {
    set relorient ""
    set sortorder ""
    set orderForm ""
    if {[db::getPrefValue amdAlignAlt]} {
        set relorient "alt"
    } elseif  {[db::getPrefValue amdAlignSame]} {
        set relorient "same"
    } 
    if {[db::getPrefValue amdAlignIncr]} {
        set sortorder "incr"
    } elseif  {[db::getPrefValue amdAlignDec]} {
        set sortorder "decr"
    }  
    set win [getParentWindow $w]
    set page2 [gi::findChild page2 -in $win]
    set gapValue [gi::findChild amdLayoutInstAlignGap.value -in $page2]
    
    if {""!=$sortorder} {
        set orderForm "Schematic"
    } else {
        set orderForm "None"
    }
    
    amdMoveInstances "" $edge $gapValue 1 $orderForm $sortorder $relorient
}


proc amdCompactInstances {edge w} {
    set relorient ""
    set sortorder ""
    set orderForm ""
    if {[db::getPrefValue amdAlignAlt]} {
        set relorient "alt"
    } elseif  {[db::getPrefValue amdAlignSame]} {
        set relorient "same"
    } 
    if {[db::getPrefValue amdAlignIncr]} {
        set sortorder "incr"
    } elseif  {[db::getPrefValue amdAlignDec]} {
        set sortorder "decr"
    }  
    set win [getParentWindow $w]
    set page2 [gi::findChild page2 -in $win]
    set gapValue [gi::findChild amdLayoutInstAlignGap.value -in $page2]
    
    if {""!=$sortorder} {
        set orderForm "Schematic"
    } else {
        set orderForm "None"
    }
    
    amdMoveInstances "" $edge $gapValue 0 $orderForm $sortorder $relorient
}

proc amdLayoutInstancesSnapLabels {w} {
    if {[catch {set cv [ed]}]} {
        return 0
    }
    set gridList [list [db::getPrefValue amdAlignXGrid] [db::getPrefValue amdAlignYGrid]]
    set offsetList [list [db::getPrefValue amdAlignXOff] [db::getPrefValue amdAlignYOff]]
    amdSnapLabels $gridList $offsetList $cv
}

proc amdLayoutInstancesSnapCells {w} {
    if {[catch {set cv [ed]}]} {
        return 0
    }
    
    set xSnap [db::getPrefValue amdAlignXGrid]
    set ySnap [db::getPrefValue amdAlignYGrid]
    set xOffset [db::getPrefValue amdAlignXOff]
    set yOffset [db::getPrefValue amdAlignYOff]

    set paredInstList [de::getSelected -design $cv -filter {%objType=="Inst"}]
    if {![db::isEmpty $paredInstList]} {
        if {[db::getAttr cv.viewType]!="maskLayout"} {
            de::sendMessage [format "Cannot do instance compaction on anything except a layout view. Currently you are working on %s %s %s" \
                [db::getAttr cv.libName] [db::getAttr cv.cellName] [db::getAttr cv.viewName] ]
                -severity error
            return 0
        }
        
        set tr [de::startTransaction "Snap Insts" -design $cv]
        db::foreach inst [db::getAttr object -of $paredInstList] {
            set adjOrig [oa::transform [oa::Point [expr [amdPDKGetGateSnapLength $inst]/2.0] [expr [amdPDKGetGateSnapWidth $inst]/2.0]] [db::getAttr transform -of $inst]]
            set xInstSnap $xSnap
            set yInstSnap $ySnap
            
            # If a cell defines its own snap, use that....
            set xSnap [db::getParamValue xSnap -of $inst]
            if {![catch {set xSnap [db::engToSci $xSnap]}]} {
                set xInstSnap $xSnap
            }
            set ySnap [db::getParamValue ySnap -of $inst]
            if {![catch {set ySnap [db::engToSci $ySnap]}]} {
                set yInstSnap $ySnap
            }
            
            # Calculate the snapped x & y
            if {![amdFloatEqual $xInstSnap 0.0]} {
                set nexX [expr round(([xCoord $adjOrig] - $xOffset)/$xInstSnap)*$xInstSnap + $xOffset]
            } else {
                set newX [xCoord $adjOrig]
            }
            if {![amdFloatEqual $yInstSnap 0.0]} {
                set newY [expr round(([yCoord $adjOrig] - $yOffset)/$yInstSnap)*$yInstSnap + $yOffset]
            } else {
                set newY [yCoord $adjOrig]
            }
            # Now move the instance correctly - adjusting for the adjusted origin
            # Note - we'll always round down.  This should make gates with odd lengths
            # behave predictably, since the adjOrig is offgrid.  If we rounded earlier,
            # we might push gates that are flipped horizontally the other direction.
            # Also makes odd widths behave better too... 
            set xy [db::getAttr origin -of $inst]
            db::setAttr origin -of $inst -value [list [expr [amdPDKRndD [xCoord $xy]] + $newX - [xCoord $adjOrig]] [expr [amdPDKRndD [yCoord $xy]] + $newY - [yCoord $adjOrig]]]
        }
        de::endTransaction $tr
    }
}


proc amdToggleXSnapGrid {{toggleList ""}} {
    if {[catch {set cv [ed]}]} {
        return 0
    }
    set mfgGrid [db::getAttr tech.defaultManufacturingGrid -of $cv]
    set mfgGrid [amdSnapNumToGrid $mfgGrid $mfgGrid]
    set ctx [de::getActiveContext]
    set snapSpacing [db::getPrefValue leSnapSpacing -scope $ctx]
    set xSnapSpacing [lindex $snapSpacing 0]
    set currSnap [amdSnapNumToGrid $xSnapSpacing $mfgGrid]
    if {""==$toggleList} {
        set gridMultiple [db::getPrefValue leMajorGridMult -scope $ctx]
        set gridSpacing [db::getPrefValue leMinorGridMult -scope $ctx]
        set i 1
        while {$i < $gridMultiple} {
            lappend toggleList [amdSnapNumToGrid [expr $i*$mfgGrid] $mfgGrid]
            set i [expr $i*2]
        }
        lappend toggleList [amdSnapNumToGrid [expr $gridMultiple*$mfgGrid] $mfgGrid]
    }
    set nextSnap ""
    puts "Current xSnap: $currSnap"          
    puts "Toggle list: $toggleList"
    for {set j 0} {$j<[llength $toggleList]} {incr j} {
        if {$currSnap==[amdSnapNumToGrid [lindex $toggleList $j] $mfgGrid]} {
            if {$j==[expr [llength $toggleList]-1]} {
                set nextSnap [amdSnapNumToGrid [lindex $toggleList 0] $mfgGrid]
            } else {
                set nextSnap [amdSnapNumToGrid [lindex $toggleList [expr $j+1]] $mfgGrid]
            }
        }
    }
    if {""==$nextSnap} {
        de::sendMessage "Could not toggle Snap, current xSnap not in Toggle List -> reverting to default" -severity error
        db::setPrefValue leSnapSpacing -scope $ctx -value [list $mfgGrid [lindex $snapSpacing 1]]
    } else {
        puts "Setting Snap to: $nextSnap"
        db::setPrefValue leSnapSpacing -scope $ctx -value [list $nextSnap [lindex $snapSpacing 1]]
    }
}

proc amdToggleXYSnapGrid {{toggleList ""}} {
    if {[catch {set cv [ed]}]} {
        return 0
    }
    
    set ctx [de::getActiveContext]
    set defToggleList [list "0.001 0.001" "0.002 0.002" "0.048 0.002" "0.096 0.002" "0.192 0.002"]
    if {""==$toggleList} {
        set toggleList $defToggleList
    }

    set mfgGrid [db::getAttr tech.defaultManufacturingGrid -of $cv]
    set mfgGrid [amdSnapNumToGrid $mfgGrid $mfgGrid] 
    
    for {set i 0} {$i < [llength $toggleList]} {incr i} {
        set tg [lindex $toggleList $i]
        lset toggleList $i "[amdSnapNumToGrid [xCoord $tg] $mfgGrid] [amdSnapNumToGrid [yCoord $tg] $mfgGrid]"
    }
        
    set currSnap [db::getPrefValue leSnapSpacing -scope $ctx]
    set currSnap "[amdSnapNumToGrid [xCoord $currSnap] $mfgGrid] [amdSnapNumToGrid [yCoord $currSnap] $mfgGrid]"
    
    puts "Current Snap: $currSnap"
    puts "Toggle list: $toggleList"
    set nextSnap ""
    for {set j 0} {$j<[llength $toggleList]} {incr j} {
        if {$currSnap==[lindex $toggleList $j] } {
            if {$j==[expr [llength $toggleList]-1]} {
                set nextSnap [lindex $toggleList 0]
            } else {
                set nextSnap [lindex $toggleList [expr $j+1]]
            }
        }
    }
    if {""==$nextSnap} {
        de::sendMessage "Could not toggle Snap, current xSnap not in Toggle List -> reverting to default" -severity error
        set nextSnap [car $toggleList]
    }
    puts "Setting Snap to: $nextSnap"
    db::setPrefValue leSnapSpacing -scope $ctx -value $nextSnap 
}

proc amdDbInstIsPcell {obj} {
    if {[db::isObject $obj]} {
        set objType [db::getAttr type -of $obj]
        if {"ScalarInst"==$objType || "ArrayInst"==$objType || "VectorInstBit"==$objType} {
             return [oa::isSubMaster [db::getAttr master -of $obj]]
        }
    }
    return 0
}

# Wrapper around geSave called for Layout to print out the message if saved
proc amdGeSave {} {
    if {[catch {set cv [ed]}]} {
        return 0
    }
    de::save $cv
    puts "[db::getAttr cv.libName] [db::getAttr cv.cellName] [db::getAttr cv.viewName] saved"
}


# These procs are no need any more
# Keep them for getting right statistic
proc amdAlignPins {} {
}
proc amdPAChangeHeight {} {
}
proc amdPAChangeWidth {} {
}
proc amdPAChangeLayerCB {} {
}
proc amdPAChangeLayer {} {
}
proc amdPAChangeAlignCB {} {
}
proc amdPAChangeAlign {} {
}
proc amdLeReplPins {} {
}
proc amdPAFixLabels {} {
}
proc amdInstIsPcell {} {
}
proc amdLayoutPinChangeForm {} {
}
proc amdLayoutInstanceAlignChangeOrderFrom {} {
}
proc amdGetMosPcellBorder {} {
}
proc amdLeRenamePinsCB {} {
}
proc amdLayoutPinChange {} {
}
proc amdLayoutPinChangeFormMetalLayer {} {
}

}



