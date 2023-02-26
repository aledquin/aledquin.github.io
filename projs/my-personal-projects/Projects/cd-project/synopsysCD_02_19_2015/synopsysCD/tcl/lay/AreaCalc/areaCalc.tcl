# Copyright (c) 2004-2014 Synopsys, Inc. This Galaxy Custom Designer software
# and the associated documentation are confidential and proprietary to
# Synopsys, Inc. Your use or disclosure of this Galaxy Custom Designer software
# is subject to the terms and conditions of a written license agreement between
# you, or your company, and Synopsys, Inc.

namespace eval ::amd::_ac {

namespace export *
namespace import -force ::amd::utils::*
namespace import -force ::amd::amdLibrary::*
namespace import -force ::amd::amdLayLibrary::*


proc AMD_ICMFracObj {obj} {
    set grid [oa::getDefaultManufacturingGrid [db::getAttr obj.design.tech]]
    switch -- [db::getAttr type -of $obj] {
        "Rect" {
            return [list [db::getAttr bBox -of $obj]]
        }
        "ScalarInst" -
        "VectorInstBit" - 
        "ArrayInst" {
            return [list [db::getAttr bBox -of $obj]]
        }  
        "Polygon" {
            return [dbLayerTile $obj $grid]
        }
        "Path" {
            return [dbLayerTile $obj $grid]
        }
        "PathSeg" {
            return [dbLayerTile $obj $grid]
        }
        "Text" -
        "AttrDisplay" - 
        "PropDisplay" {
            return [list [list [db::getAttr origin -of $obj]] [list [db::getAttr origin -of $obj]] ]
        }
    }
}

proc dbLayerTile {obj grid} {
    set res {}
    set boxes [le::splitIntoBoxes $obj]
    foreach bBox $boxes {
        lappend res [list [list [expr $grid*[lindex $bBox 0]] [expr $grid*[lindex $bBox 1]]] [list [expr $grid*[lindex $bBox 2]] [expr $grid*[lindex $bBox 3]]]]
    }
    return $res
}

proc AMD_ICMGetBboxArea {bBox} {
    return [expr abs(([lindex $bBox 1 0] - [lindex $bBox 0 0])*([lindex $bBox 1 1] - [lindex $bBox 0 1]))]
}


proc AMD_ICMGetShapeArea {shape} {
    switch -- [db::getAttr type -of $obj] {
        "ScalarInst" -
        "VectorInstBit" - 
        "ArrayInst" -
        "Rect" {
            return [AMD_ICMGetBboxArea [db::getAttr bBox -of $obj]]
        }  
        "Polygon" {
            return [oa::getArea [oa::getPoints $s]]
        }
        "Path" - 
        "PathSeg" {
            return [oa::getArea [oa::getBoundary $s]]
        }
        "Text" -
        "AttrDisplay" - 
        "PropDisplay" {
            return 0
        }
        default {
            return 0
        }
    }    
}


proc amdLeDensity {cv box hierLevels} {
    set boxLP {y1 drawing}
    set includeLp {y2 drawing}
    set resultsLp {y3 drawing}
    set base "zpcellscratch_"
   
    set dlgName "calcAreaDensity"
    set dlg [db::getNext [gi::getDialogs $dlgName]]
    if {""==$dlg} {
        return 0
    }

    set _incLay [gi::findChild amdIncludeLay.value -in $dlg]
    set incLay {}
    set _incPurp [gi::findChild amdIncludePurp.value -in $dlg]
    set incPurp {}
    set _excLay [gi::findChild amdExcludeLay.value -in $dlg]
    set excLay {}
    set _excPurp [gi::findChild amdExcludePurp.value -in $dlg]
    set excPurp {}
    
    foreach lName $_incLay {
        lappend incLay [getLayerNumber $lName $cv]
    }
    foreach pName $_incPurp {
        lappend incPurp [getPurposeNumber $pName $cv]
    }
    foreach lName $_excLay {
        lappend excLay [getLayerNumber $lName $cv]
    }
    foreach pName $_excPurp {
        lappend excPurp [getPurposeNumber $pName $cv]
    }
    
    set includeLNum [getLayerNumber [lindex $includeLp 0] $cv]
    set includePNum [getPurposeNumber [lindex $includeLp 1] $cv] 
    set resultsLNum [getLayerNumber [lindex $resultsLp 0] $cv]
    set resultsPNum [getPurposeNumber [lindex $resultsLp 1] $cv] 
    
    set libName [db::getAttr libName -of $cv]
    # Find an available scratch cell
    set index 0
    
    db::foreach c [dm::getCells -libName $libName -filter {%name=~/^$base\[0-9\]+$/ && [db::getCount [dm::getCellViews layout -cell %this]]}] {
        if {[regexp "^${base}(\\d+)$" [db::getAttr name -of $c] match i]} {
            set index [max $index $i]
        }
    }
    incr index
    set c [dm::createCell ${base}${index} -libName $libName]
    set cv2 [dm::createCellView layout -cell $c -viewType maskLayout]
    
    #set ctx [de::open $cv2]
    set ctx [de::createContext $cv2]
    set oaDes2 [db::getAttr editDesign -of $ctx]
    set tb [oa::getTopBlock $oaDes2]
    set tr [de::startTransaction "getDensity" -design $oaDes2]
    le::createInst -master $cv -origin {0 0} -design $oaDes2
    set rect [le::createRectangle $box -design $oaDes2 -lpp $boxLP]
    set boxArea [amdGetArea $rect]

    db::setPrefValue leStopLevel -value [expr $hierLevels+1] -scope $ctx 

    set mode 1
    
    if {$mode} {
        # STAR 9000837387 workaround
        set boxLeft [lindex $box 0 0]
        set tmpRectRight [expr $boxLeft - 0.01]
        set tmpRectLeft [expr $boxLeft - 0.02]
        set tmpRectBottom 0
        set tmpRectTop 0.01
        
        set TIME_start_main [clock clicks -milliseconds]
        set allLayerFigs {}
        foreach lName $_incLay {
            set area 0
            foreach pName $_incPurp {
                # STAR 9000837387 workaround
                if {""==[getLayerNumber $lName $cv] || ""==[getPurposeNumber $pName $cv]} {
                    de::sendMessage "Could not find \{$lName $pName\} LPP" -severity warning
                    continue
                }
                le::createRectangle [list [list $tmpRectLeft $tmpRectBottom] [list $tmpRectRight $tmpRectTop]] -design $oaDes2 -lpp [list $lName $pName]
                set currentFigs [le::generateShapes [de::getFigures [db::getAttr bBox -of $oaDes2] -design $oaDes2] \
                -lpp1 $boxLP -lpp2 [list $lName $pName] -lpp $includeLp \
                -operation and -levels [expr $hierLevels+1]]
                db::foreach f [db::getAttr object -of $currentFigs] {
                    set area [expr $area + [amdGetArea $f]]
                    lappend allLayerFigs $f
                }            
            }
            if {""!=[getLayerNumber $lName $cv]} {
                puts "Layer $lName density [expr $area/$boxArea]"         
            }
        }
        set area 0
        lappend allLayerFigs $rect
        set mergedFigs [le::generateShapes [db::createCollection $allLayerFigs] \
        -lpp1 $boxLP -lpp2 $includeLp -lpp $includeLp -operation and]
        db::foreach f $mergedFigs {
            set area [expr $area + [amdGetArea $f]]
        } 
        puts "Merged density [expr $area/$boxArea]"
        
        set excFigs {}
        foreach lName $_excLay {
            foreach pName $_excPurp {
                # STAR 9000837387 workaround
                le::createRectangle [list [list $tmpRectLeft $tmpRectBottom] [list $tmpRectRight $tmpRectTop]] -design $oaDes2 -lpp [list $lName $pName]
                set currentFigs [le::generateShapes [de::getFigures [db::getAttr bBox -of $oaDes2] -design $oaDes2] \
                -lpp1 $boxLP -lpp2 [list $lName $pName] -lpp $resultsLp \
                -operation and -levels [expr $hierLevels+1]]
                db::foreach f [db::getAttr object -of $currentFigs] {
                    lappend excFigs $f
                }            
            }
        }        
        
        set area 0
        if {[llength $excFigs]} {
            set allFigs [db::add [db::createCollection $excFigs] -to $mergedFigs]
        } else {
            set allFigs $mergedFigs
        }
        
        if {![db::isEmpty $allFigs]} {
            set resultsFigs [le::generateShapes $allFigs -lpp1 $includeLp -lpp2 $resultsLp -lpp $resultsLp  -operation andnot]
            db::foreach f $resultsFigs {
                set area [expr $area + [amdGetArea $f]]
            } 
        }
        set density [expr $area/$boxArea]
        puts "Density of merged layers ANDNOT cut areas: $density"
        
        de::endTransaction $tr
        set t [expr [clock clicks -milliseconds] - $TIME_start_main]
        #puts "t = $t"  
        #de::save $ctx
        de::close $ctx
        db::destroy $c
        return [format "%.6f" $density]
    }

   
    set TIME_start_main [clock clicks -milliseconds]
    array set objects {}
    array set trCache {}
    set figs [de::getFigures $box -design $oaDes2 -depth [expr $hierLevels+1] -touch true -filter {(%objType=="Rectangle" || %objType=="Path" || %objType=="Polygon" || %objType=="PathSeg")}]
    db::foreach f $figs {
        if { -1!=[lsearch $incLay [db::getAttr layerNum -of [db::getAttr object -of $f]]] &&  -1!=[lsearch $incPurp [db::getAttr purposeNum -of [db::getAttr object -of $f]]]} {
            set linLevels [db::getAttr f.lineage.levels]
            set transform [getHierarchicalTransform trCache $linLevels]
            set obj [oa::copy [db::getAttr object -of $f] $transform $tb]
            oa::setLPP $obj $includeLNum $includePNum
            lappend objects([db::getAttr layerNum -of [db::getAttr object -of $f]]) $obj
        }
    }
    
    set allLayerFigs {}
    foreach lName $_incLay {
        set key [getLayerNumber $lName $cv]
        set area 0
        if {[info exist objects($key)]} {
            lappend objects($key) $rect
            set currentFigs [le::generateShapes [db::createCollection $objects($key)] -lpp1 $boxLP -lpp2 $includeLp -lpp $includeLp -operation and]
            set allLayerFigs [concat $allLayerFigs [db::createList $currentFigs]]
            db::foreach f $currentFigs {
                set area [expr $area + [amdGetArea $f]]
            }
        }
        puts "Layer $lName density [expr $area/$boxArea]"        
    }
    
    set area 0
    lappend allLayerFigs $rect
    set mergedFigs [le::generateShapes [db::createCollection $allLayerFigs] -lpp1 $boxLP -lpp2 $includeLp -lpp $includeLp -operation and]
    #set mergedFigs [le::merge [db::createCollection $allLayerFigs]]
    db::foreach f $mergedFigs {
        set area [expr $area + [amdGetArea $f]]
    } 
    puts "Merged density [expr $area/$boxArea]"
    
    # Promote exclude shapes to level 0
    set excFigs {}
    db::foreach f $figs {
        if { -1!=[lsearch $excLay [db::getAttr layerNum -of [db::getAttr object -of $f]]] &&  -1!=[lsearch $excPurp [db::getAttr purposeNum -of [db::getAttr object -of $f]]]} {
            set linLevels [db::getAttr f.lineage.levels]
            set transform [getHierarchicalTransform trCache $linLevels]
            set obj [oa::copy [db::getAttr object -of $f] $transform $tb]
            oa::setLPP $obj $resultsLNum $resultsPNum
            lappend excFigs $obj
        }
    }    
    
    # Final processing
    set area 0
    if {[llength $excFigs]} {
        set allFigs [db::add [db::createCollection $excFigs] -to $mergedFigs]
    } else {
        set allFigs $mergedFigs
    }
    
    if {![db::isEmpty $allFigs]} {
        set resultsFigs [le::generateShapes $allFigs -lpp1 $includeLp -lpp2 $resultsLp -lpp $resultsLp -operation andnot]
        db::foreach f $resultsFigs {
            set area [expr $area + [amdGetArea $f]]
        } 
    }
    set density [expr $area/$boxArea]
    puts "Density of merged layers ANDNOT cut areas: $density"
    
    de::endTransaction $tr
    set t [expr [clock clicks -milliseconds] - $TIME_start_main]
    #puts "t = $t"  
    #de::save $ctx
    de::close $ctx
    db::destroy $c
    return [format "%.6f" $density]    
}



proc AMDLeCalcShapeDensityGUI {{forceLoad 1}} {
    if {[catch {set oaDes [ed]}]} {
        return 0
    } 
    set ns [namespace current]
    set dlgName "calcAreaDensity"
    set dlg [db::getNext [gi::getDialogs $dlgName]]
    set lppNames [AMD_ICMDensityLayersInitVal]
    set m1LppNames {}
    set layerChoice {}
    
    foreach nn $lppNames {
        if {[car $nn]==[amdLeGetMetalLayerName "m1"]} {
            lappend m1LppNames $nn
        }
    }
    foreach nn $m1LppNames {
        if {"drawing"==[cadr $nn] || "e1"==[cadr $nn] || "e2"==[cadr $nn]} {
            lappend layerChoice $nn
        }
    }
                   
    if {""==$dlg} {
        catch {de::registerHelp -helpID areaCalc -type url -target "http://twiki.amd.com/twiki/bin/view/Cadteam_ER/CadenceAreaCalculatorFormHelp"}
        set dlg [gi::createDialog $dlgName -title "AMD Density Calculator" -showApply false -topicId "areaCalc"]
        set forceLoad 1
    } else {
        gi::setActiveDialog $dlg
    }
    
    if {$forceLoad} {
        db::destroy [db::getAttr children -of $dlg]
        set amdIncludeLay [gi::createTextInput amdIncludeLay -parent $dlg -value [car [db::getAttr lpp -of  [de::getActiveLPP -design $oaDes]]] -label "Merge Layer(s)"]
        set amdIncludePurp [gi::createTextInput amdIncludePurp -parent $dlg -value [cadr [db::getAttr lpp -of  [de::getActiveLPP -design $oaDes]]] -label "Merge Purposes(s)"]
        set amdExcludeLay [gi::createTextInput amdExcludeLay -parent $dlg -value "" -label "Cut Layer(s)"]
        set amdExcludePurp [gi::createTextInput amdExcludePurp -parent $dlg -value "" -label "Cut Purposes(s)"]
        set amdAreaCalcMode [gi::createMutexInput amdAreaCalcMode -parent $dlg -enum {"Enter" "SelPrB" "Coords"} -valueChangeProc ${ns}::AMDAreaCalcModeCB -label "Mode" -value "SelPrB"]
        set bboxCoord [gi::createTextInput bboxCoord -parent $dlg -label "bBox Coords" -value {{ {0 0} {1 1} }}]
        db::setAttr bboxCoord.enabled -value 0
        #db::setAttr bboxCoord.style.background -value #CCCCCC
        
        set hierLevels [gi::createNumberInput hierLevels -parent $dlg -label "Levels of Hierarchy to Evaluate" -value 32 -minValue 0 -maxValue 32 -width 10]
        set amdCalcDensity [gi::createPushButton amdCalcDensity -parent $dlg -label "Calculate Density" -execProc ${ns}::AMD_ICMCalcDensityCB]
        set reportDensity [gi::createTextInput reportDensity -parent $dlg -value "" -readOnly true -label "Density = "]
        db::setAttr style.background -of $reportDensity -value #CCCCCC
    }
}


#*******************************************************************************
#* AMDAreaCalcModeCB
#* Description: Callback from 'Mode' field in AMD Density Calculator form
#*******************************************************************************
proc AMDAreaCalcModeCB {w} {
    set dlg [getParentDialog $w]
    set bboxCoord [gi::findChild bboxCoord -in $dlg]
    set val [db::getAttr w.value]
    switch $val {
        "Coords" {
            db::setAttr bboxCoord.enabled -value 1
        }
        "Enter" {
            db::setAttr bboxCoord.enabled -value 0
        }  
        "SelPrB" {
            db::setAttr bboxCoord.enabled -value 0
        }         
    }
}

#*******************************************************************************
#* AMD_ICMCalcDensityCB
#* Description: Callback from Density button
#*******************************************************************************
proc AMD_ICMCalcDensityCB {w} {
    set ns [namespace current]
    set dlg [getParentDialog $w]
    set reportDensity [gi::findChild reportDensity -in $dlg]
    if {[catch {set oaDes [ed]}]} {
        de::sendMessage "No Current Cellview" -severity error
        return 0
    }    
    set hierLevels [gi::findChild hierLevels.value -in $dlg]
    set amdAreaCalcMode [gi::findChild amdAreaCalcMode.value -in $dlg]
    set bboxCoord [gi::findChild bboxCoord -in $dlg]
    set tb [oa::getTopBlock $oaDes]

    switch $amdAreaCalcMode {
        "SelPrB" {
            set bndry [oa::PRBoundaryFind $tb]
            if {""==$bndry} {
                de::sendMessage "AMD_ICMCalcDensity: cell [db::getAttr oaDes.libName]([db::getAttr oaDes.cellName]) has no boundary" -severity error
                return                 
            }
            set bBox [db::getAttr bBox -of $bndry]
        }
        "Enter" {
            set bBox [lindex [db::getAttr bboxCoord.value] 0]
            set promtDlg [gi::createDialog enterbb -title "Enter a bounding box" -parent $dlg -showApply 0 -execProc ${ns}::getEnteredCoord]
            set left [gi::createNumberInput left -valueType float -parent $promtDlg -label Left -value [lindex $bBox 0 0]]
            set bottom [gi::createNumberInput bottom -valueType float -parent $promtDlg -label Bottom -value [lindex $bBox 0 1]]
            set right [gi::createNumberInput right -valueType float -parent $promtDlg -label Right -value [lindex $bBox 1 0]]
            set top [gi::createNumberInput top -valueType float -parent $promtDlg -label Top -value [lindex $bBox 1 1]]
            gi::layout $right -rightOf $left
            gi::layout $top -rightOf $bottom
            gi::layout $right -align $top
            set r [gi::execDialog $promtDlg]
            if {$r} {
                set bBox [list [list [db::getAttr left.value] [db::getAttr bottom.value]] [list [db::getAttr right.value] [db::getAttr top.value]]]
                db::setAttr bboxCoord.value -value [list $bBox]
            } else {
                return 0
            }
        }
        "Coords" {
            set bBox [lindex [db::getAttr bboxCoord.value] 0]
        }
    }
    
    #---------------------------------------------------------------------
    # Get hierarchical shapes overlapping the area, then calculate 
    # density of given layer in the area
    #--------------------------------------------------------------------- 
    if {[llength $bBox]!=2 || [catch {set tmpBox [oa::Box [lindex $bBox 0 0] [lindex $bBox 0 1] [lindex $bBox 1 0] [lindex $bBox 1 1]] } ] } {
        de::sendMessage "Please specify bBox in correct format: {{l b} {r t}}" -severity error
        return 0
    }
    set density [amdLeDensity $oaDes $bBox $hierLevels]    
    db::setAttr reportDensity.value -value $density 
}

proc getEnteredCoord {dlg} {
}

#******************************************************************************
#* AMD_ICMDensityLayersInitVal
#* Description: Code to create initial value of hiLayerField with only layers
#*              in the open layout cellView
#*******************************************************************************
proc AMD_ICMDensityLayersInitVal {} {
    if {[catch {set oaDes [ed]}]} {
        de::sendMessage "AMD_ICMDensityForm: No Cell in Current Window." -sverity error
        return 0
    }    
    set choicesList [db::createList [db::getAttr lpp -of [de::getLPPs -from $oaDes]]]
    return $choicesList
}

proc getHierarchicalTransform {trCacheName linLevels} {
    upvar $trCacheName trCache
    if {[info exist trCache($linLevels)]} {
        set transform $trCache($linLevels)
    } else {
        set levels {}
        foreach level $linLevels {
            set levels [linsert $levels 0 $level]
        }        
        set transform [oa::Transform 0 0 R0]
        foreach level $levels {
            set inst [lindex $level 0]
            if {"ArrayInst"==[db::getAttr type -of $inst]} {
                set dX [expr [lindex $level 2] * [db::getAttr dX -of $inst]]
                set dY [expr [lindex $level 1] * [db::getAttr dY -of $inst]]
                set transform [oa::concat [oa::Transform $dX $dY R0] $transform]
            }
            set transform [oa::concat $transform [db::getAttr transform -of $inst]]
        }
        set trCache($linLevels) $transform
    }
    return $transform
}

}

