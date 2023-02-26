# Copyright (c) 2004-2014 Synopsys, Inc. This Galaxy Custom Designer software
# and the associated documentation are confidential and proprietary to
# Synopsys, Inc. Your use or disclosure of this Galaxy Custom Designer software
# is subject to the terms and conditions of a written license agreement between
# you, or your company, and Synopsys, Inc.

#puts "amdLePinGui.tcl"
namespace eval ::amd::_autoPin {

namespace export *
namespace import -force ::amd::utils::*
namespace import -force ::amd::amdLibrary::*
namespace import -force ::amd::_align::*

# Procedure for main GUI
proc amdLePinGuiForm {winId ctx} {
    if {[catch {set design [ed]}]} {
        return 
    }   
    amd::utils::amdRounding_INIT [db::getAttr tech -of $design]

    set buttonStylesheet "height: 10px"
    set amdLayoutPinGuiWindow [db::getNext [gi::getDialogs amdLayoutPinGuiWindow]]
    if {""!=$amdLayoutPinGuiWindow} {
        gi::setActiveDialog $amdLayoutPinGuiWindow
        return
    }
    set amdLayoutPinGuiWindow [gi::createDialog amdLayoutPinGuiWindow \
        -title "Pin Tools" ]
#   *******************************************************************
#                       PIN ALIGN SECTION                             *
#   *******************************************************************
    set ns [namespace current]
    set pinAlignGrp [gi::createGroup pinAlignGrp -label "PIN ALIGN"\
                        -parent $amdLayoutPinGuiWindow]
    set pinAlgnSrc [gi::createMutexInput amdPaSrc -label "Align to" \
                    -parent $pinAlignGrp -viewType radio -enum "Child Parent"]
    set pinUBtn [gi::createPushButton pinUBtn -parent $pinAlignGrp  -icon "arrow_up" \
                -execProc [list ${ns}::amdAlignPins "U"] ]
    set pinDBtn [gi::createPushButton pinDBtn -parent $pinAlignGrp -icon "arrow_down" \
                -execProc [list ${ns}::amdAlignPins "D"] ]
    set pinLBtn [gi::createPushButton pinLBtn -parent $pinAlignGrp -icon "arrow_left" \
                -execProc [list ${ns}::amdAlignPins "L"] ]
    set pinCBtn [gi::createPushButton pinCBtn -parent $pinAlignGrp  -icon "arrows_up_down" \
                -execProc [list ${ns}::amdAlignPins "c"] ]
    set pinRBtn [gi::createPushButton pinRBtn -parent $pinAlignGrp -icon "arrow_right" \
                -execProc [list ${ns}::amdAlignPins "R"] ]
    gi::layout $pinLBtn -leftOf $pinCBtn
    gi::layout $pinRBtn -rightOf $pinCBtn
    gi::layout $pinUBtn -align $pinCBtn
    gi::layout $pinDBtn -align $pinCBtn -after $pinCBtn

    set pinReplBtn [gi::createPushButton pinReplBtn -label "Auto-create" \
                    -parent $pinAlignGrp \
                -execProc [list ${ns}::amdLeAutoPins] ]
    db::setAttr pinReplBtn.styleSheet -value $buttonStylesheet

    gi::layout $pinReplBtn -align $pinCBtn
#   *******************************************************************
#                           REWORK SECTION                            *
#   *******************************************************************
    set reworkGrp [gi::createGroup reworkGrp -label "REWORK"\
                        -parent $amdLayoutPinGuiWindow]
    gi::layout $reworkGrp -rightOf $pinAlignGrp
    set pins [list LSW]
    set pins [concat $pins $amd::GVAR_amdLayVariables(amdMetLayers)]
    set dirs [list "R0" "R90" "Left" "Right" "Top" "Bottom"]
    set layerCyc [gi::createMutexInput layerCyc -parent $reworkGrp \
                    -enum $pins -viewType combo]
    set layerBtn [gi::createPushButton layerBtn -label "Layer" \
                  -parent $reworkGrp \
                  -execProc "${ns}::amdPGChangeLayerCB"]
    db::setAttr layerBtn.styleSheet -value $buttonStylesheet
    gi::layout $layerBtn -rightOf $layerCyc
    set alignCyc [gi::createMutexInput alignCyc -parent $reworkGrp \
                    -enum $dirs -viewType combo]
    set alignBtn [gi::createPushButton alignBtn -label "Lbl Align" \
                  -parent $reworkGrp \
                  -execProc "${ns}::amdPGChangeAlignCB"]
    db::setAttr alignBtn.styleSheet -value $buttonStylesheet
    gi::layout $alignBtn -rightOf $alignCyc
    set dimTextWidth 10
    set widthFld [gi::createTextInput widthFld -parent $reworkGrp \
                    -value 0.0 -width $dimTextWidth]
    set widthBtn [gi::createPushButton widthBtn -label "Width" \
                  -parent $reworkGrp \
                  -execProc [list ${ns}::amdPGChangeWidth] ]
    db::setAttr widthBtn.styleSheet -value $buttonStylesheet
    set heightFld [gi::createTextInput heightFld -parent $reworkGrp \
                    -value 0.0 -width $dimTextWidth]
    set heightBtn [gi::createPushButton heightBtn -label "Height" \
                  -parent $reworkGrp \
                  -execProc [list ${ns}::amdPGChangeHeight]]
    db::setAttr heightBtn.styleSheet -value $buttonStylesheet
    set bothBtn [gi::createPushButton bothBtn -label "Both" \
                  -parent $reworkGrp \
                  -execProc [list ${ns}::amdPGChangeBoth]]

    db::setAttr bothBtn.styleSheet -value $buttonStylesheet
    gi::layout $widthBtn -rightOf $widthFld
    gi::layout $bothBtn -rightOf $heightFld
    

    gi::layout $alignBtn -align $layerBtn 
    gi::layout $widthBtn -align $layerBtn 
    gi::layout $bothBtn -align $layerBtn 
    gi::layout $heightBtn -align $layerBtn 
    
    set expandBtn [gi::createPushButton expandBtn -label "Expand Pins" \
                  -parent $reworkGrp \
                  -execProc "${ns}::amdLeExpandPins"]
    db::setAttr styleSheet -of $expandBtn -value $buttonStylesheet


}

# This procedure lives in amdLeAlign.il file
proc amdAlignPins {side widget} {
    if {[catch {set des [ed]}]} {
        return 
    }
    if {"r"==[db::getAttr mode -of $des]} {
        de::sendMessage "[getLCV $des] is opened in read-only mode. Please reopen in write mode, before running pin utility." -severity error
        return 
    }    
    set dialog [db::getAttr parent.parent -of $widget]
    set src [db::getAttr value -of [gi::findChild amdPaSrc -in $dialog]]
    set sel [de::getSelected -design $des]
    set t [de::startTransaction "Align pins" -design $des]
    db::foreach thing $sel {
        amdAlignPin [db::getAttr thing.object] $side $src
    }
    de::endTransaction $t
}

# A sorta generic auto-pinning utility for layout
# Planned behavior:
# The user can select either instances or pins (or both) to process.
# When a pin is selected, the existing pin is destroyed and it will be
# recreated.  When an instance is selected, all inst-terms that hook to
# terminals in the schematic (but not yet in the layout) will be created.
# If nothing is selected, all schematic terminals that don't yet exist in
# layout will be pinned.
#
# If there is metal attached to the net being pinned, a piece of the highest
# metal layer touching the border will be pinned, with the pin created touching
# the border at the wire width and going min-width deep into the cell.
# If no shapes touch the border, the highest level shapes will be pinned over
# the whole area.
# If no shapes touch the net at all, the pin will be copied up from an instTerm
# with priority given to instances that were originally selected.

proc amdLeAutoPins {widget} {
    if {[catch {set lcv [ed]}]} {
        return 
    }  

    if {"r"==[db::getAttr mode -of $lcv]} {
        de::sendMessage "[getLCV $lcv] is opened in read-only mode. Please reopen in write mode, before running pin utility." -severity error
        return 
    } 
    set transaction [de::startTransaction "Pin auto create." -design $lcv]
    set libName [db::getAttr libName -of $lcv]
    set cellName [db::getAttr cellName -of $lcv]
    set viewName [db::getAttr viewName -of $lcv]

    # Find schematic pins
    set vnm "schematic" ; # Is there smart way to get schematic of layout, SDL?
    set scell [dm::getCellViews $vnm -libName $libName -cellName $cellName]
    set spins [list]
    # If there is no schematic view, use layout view 
    if {[catch {set scv [db::getAttr editDesign -of [de::createContext $scell]]}]} {
        set scv $lcv
    }
    set spins [db::createList [db::getAttr name -of [db::getTerms -of $scv]]]
    
    # Find layout pins
    set lpins [db::createList [db::getAttr name -of [db::getTerms -of $lcv]]]
    
    #Find missing pins in layout that exist in the schematic
    set mpins [list]
    set cpins [list] ; #Hold net names for which pin is created
    foreach spin $spins {
        if {-1==[lsearch $lpins $spin]} {
            lappend mpins $spin
        }
    }
#   Get the boundary bBox
    set cbox [amdReturnContextBBox $lcv]
    set sel [de::getSelected -design $lcv]
#   If nothing selected, work on all missing pins
    if {0==[db::getCount $sel]} {
        set nets [db::createList [setof [db::getNets -of $lcv] {[member %name $mpins]}]]
    } else {
#       Find the nets selected to work on
        set figs [setof $sel \
                    {(%object.type=="Polygon" || %object.type=="Rect"|| \
                      %object.type=="Path") && %object.pin!="" }]
        set nets [db::createList [db::getAttr object.pin.term.net -of $figs] ]
#       Find the instances selected
        set insts [db::getAttr object -of [setof $sel {%objType=="Inst"}]]
#       Now grab every pin thats on an instance, but missing from the layout
        db::foreach inst $insts {
            db::foreach it [db::getAttr instTerms -of $inst] {
                if {[catch {set nn [db::getAttr it.net.name]}]} {
                    de::sendMessage "Instance terminal [db::getAttr it.name] doesn't have net assigned to it." \
                     -severity warning
                     continue
                }
                if {[member $nn $mpins]} {
                    set nets [cons [db::getAttr net -of $it] $nets]
                }
            }
        }
    }
#   Got all the nets to process, now do them
    foreach net [lsort -unique $nets] { ;# Net is oaNet
        set newpin ""
        set bordPin ""; #flag to bord pin, bord pin will not be expaned to entire shape
#       Make sure the term for this net has same direction as schematic
#        set snets [setof \
                           [db::getNets -of $scv] \
                            [member [db::getAttr name -of $net] nn~>signals~>name]]
        set netName [db::getAttr name -of $net]
        if {[db::getAttr net.type] == "BusNetBit"} {
            set baseName [getBaseName $netName]
            set snets [db::getNets $netName<*> -of $scv]
        } else {
            set snets [db::getNets $netName -of $scv]
        }
        set sTermDir ""
        set term ""

        db::foreach nn $snets {
            set term [db::getNext [db::getAttr terms -of $nn]]
            set sTermDir [db::getAttr termType -of $term]
        }
        if {""!=$sTermDir} {
            if {0!=[db::getCount $snets] && \
                0==[db::getCount [db::getAttr terms -of $net]]} {
                    set lTerm [le::createTerm $netName -net $netName \
                                -type $sTermDir -design $lcv]
            } else {
                set lTerm [db::getNext [db::getAttr terms -of $net]]
                set lTermDir [db::getAttr termType -of $lTerm]
                if {$lTermDir!=$sTermDir} {
                    db::setAttr termType -of $lTerm -value $sTermDir
                }
            }
        } ; ## if $sTermDir ##

        # See if we can find a highest piece of metal thats not a pin
        # This will not consoder shapes in vias.
        set shapes [db::filter [db::getAttr shapes -of $net] \
                    -filter {[member [lindex [split %LPP.lpp] 0] [amdLeGetRoutingLayers]]}]
        set netVias [db::getVias -of $lcv -filter {%net.name == $netName}]
        if {0!=[db::getCount $shapes] || 0!=[db::getCount $netVias] } {
#          If we've got any shapes touching the border, grab the highest
           set bshapes [db::filter $shapes -filter {[amdLeGetBorderPinshape %this] !=""}]
           if {0!=[db::getCount $bshapes]} {
               set retVal [_createBorderPin $netName $lcv $bshapes]
               set newpin [lindex $retVal 0]
               set newPinObj [lindex $retVal 1]
               set bordPin "true"
           } else {
               set layerNames [list]
               set viaShapes [list]
               # to get the metal in Via Obj
               db::foreach via $netVias {
                   switch [db::getAttr via.type] {
                       "CustomVia" -
                       "StdVia" {
                           set transform [list [db::getAttr via.origin] \
                                       [db::getAttr via.orientation] ]
                           db::foreach ff [db::getAttr via.header.master.shapes] {
                               set layerName [getLayerName [db::getAttr ff.layerNum] $lcv]
                               if {[member $layerName [amdLeGetRoutingLayers] ]} {
                                   lappend viaShapes [list $ff $transform]
                               }
                           }
                       }
                   }
               }
               db::foreach s $shapes {
                   set shpName [getLayerName [db::getAttr s.layerNum] $lcv]
                   if {![member $shpName $layerNames]} {
                       lappend layerNames $shpName
                   }
               }
               set hlayer [lindex [lsort -command [list sortByLayer $lcv] $layerNames ] end]
               # See if there is a via shape higher than hlayer
               set viaLayersShapes [list]
               foreach viaShape $viaShapes {
                   set s [lindex $viaShape 0]
                   set tr [lindex $viaShape 1]
                   set r [dbTransformBBox [db::getAttr s.bBox] $tr]
                   set shpName [getLayerName [db::getAttr s.layerNum] $lcv]
                   lappend viaLayersShapes [list $r $shpName]  
               }
               set viaShapesSorted [lsort -index 1 -command [list sortByLayer $lcv] $viaLayersShapes ]
               set viahlayer [lindex $viaShapesSorted end end]
               set tech [db::getAttr lcv.tech]
               if {($hlayer!="" && [alphalessp $hlayer $viahlayer]) || $viahlayer=="" } {
                   set shape  [db::getNext \
                       [db::filter $shapes -filter {[getShapeLayerName %this]=="$hlayer"}] ]
                   set newpin [dbCopyFig $shape $lcv [list [list 0 0] "R0"]]                   
                   set newpin [figToRect $newpin $netName $lcv]  
                } else {
                   set rect [lindex $viaShapesSorted end 0]
                   set newpin [le::createRectangle $rect -design $lcv -lpp [list $viahlayer "pin"]]
                }
      
               set newPinObj [le::createPin -term $netName -shapes $newpin]
           } ; # end if bshapes
       } else {
           # Okay, no shapes - find a inst term instead
           set shapes [list]
           # This net may have instTerms on multiple instances
           set netInstTerms [db::getInstTerms -of $net]
           set netVias [db::getVias -of $lcv -filter {%net.name == $netName}]
           db::foreach it $netInstTerms {
               # Each instTerm may have multiple pin figs
               set pinFigs [db::getAttr it.term.pins.figs]
               # to get the metal in Via Obj
               db::foreach via $netVias {
                   switch [db::getAttr via.type] {
                       "CustomVia" -
                       "StdVia" {
                           set transform [list [db::getAttr via.origin] \
                                       [db::getAttr via.orientation] ]
                           db::foreach ff [db::getAttr via.header.master.shapes] {
                               set layerName [getLayerName [db::getAttr ff.layerNum] $lcv]
                               if {[member $layerName [amdLeGetRoutingLayers] ]} {
                                   lappend shapes [list $ff $transform]
                               }

                           }
                       }
                   }
               }
               db::foreach ff $pinFigs {
                   if {[member \
                       [getLayerName [db::getAttr ff.layerNum] $lcv] \
                           [amdLeGetRoutingLayers] ]} {
                            lappend shapes [list $ff [db::getAttr it.inst.transform]]
                   }
               }
           }; #end foreach netInstTerms
#            Check and see if any of those were on the selected insts
            set instsMasters [list]
            foreach shape $shapes {
                set s [lindex $shape 0]
                if {[info exists insts]} {
                    lappend instsMasters [db::createList [db::getAttr master -of $insts]]
                } 
                if {[member [db::getAttr s.design] $instsMasters]} {
                    set fig $s
                    set tr [lindex $shape 1]
                    set lpp [list [getLayerName [db::getAttr fig.layerNum] $lcv] \
                        "pin" ]
                    set rect [dbTransformBBox [db::getAttr fig.bBox] $tr]
                    set newpin [le::createRectangle $rect -design $lcv -lpp $lpp]
                    # Reshape its bBox if it is an edge pin
                     set bBox [amdLeGetBorderPinshape $newpin]
                     if {""!=$bBox} {
                         set bordPin true
                         db::setAttr bBox -of $newpin -value $bBox
                        }
                        set newPinObj [le::createPin -term $netName -shapes $newpin]
                        break
                }
            } ; #end foreach 
#            ;; If we haven't created a pin yet ...
            if {""==$newpin} {
#                        ;; 'shapes' is a list of: list(shapeId transform)
#                        ;; Loop thru 'shapes' and keep the one that has highest metal level
                set shape [lindex $shapes 0]       
                set bndPinShp ""
                foreach shp $shapes {
                    set fig [lindex $shp 0]
                    set tr  [lindex $shp 1]
#                   If higher level metal found
                    set bndPinShp1 [amdLeGetBorderPinshape $fig $tr $cbox]  
                    set shapeLayerName [getLayerName \
                                           [db::getAttr layerNum -of [lindex $shape 0]] $lcv]
                    set shpLayerName [getLayerName \
                                          [db::getAttr layerNum -of [lindex $shp 0]]    $lcv]
                    if { (""==$bndPinShp && ""!=$bndPinShp1) || \
                         ""!=$bndPinShp1 && \
                         [alphalessp $shapeLayerName $shpLayerName] || \
                         $shapeLayerName == $shpLayerName} {
                            set shape $shp
                            set bndPinShp $bndPinShp1
                    }
                    if {""==$bndPinShp && [alphalessp $shapeLayerName $shpLayerName] || \
                        $shapeLayerName == $shpLayerName} {
                        set shape $shp
                    }
                } ; #foreach shp
                if {""!=$shape} {
                    set fig [lindex $shape 0]
                    set tr [lindex $shape 1]
                    set lpp [list [getLayerName [db::getAttr fig.layerNum] $lcv] \
                        "pin" ]

                    if {""!=$bndPinShp} {
                        set bordPin true
                        set newpin [le::createRectangle $bndPinShp -design $lcv -lpp $lpp]
                    } else {
                        set rect [dbTransformBBox [db::getAttr fig.bBox] $tr]
                        set newpin [le::createRectangle $rect -design $lcv -lpp $lpp]
                    }
                    set newPinObj [le::createPin  -term $netName -shapes $newpin]
                } ; #when shape
            } ; #unless newpin
       }  ; # end if shapes
#       If we created a new pin, wipe out the old one(s), del children, recreate textDisplay,chnage to pin layer
        if {""!=$newpin} {
            # Delete all other pins for that net
            db::foreach p [db::getPins -of $lcv -filter {%this.term.name==$netName}] {
                if {$p!=$newPinObj} {
                    db::destroy [db::getAttr p.figs]
                }
            }
            # Expand pins to max merged shape 
            if {""!=$bordPin} {
                if {[db::getAttr type -of $newpin]=="Path" && \
                    [llength [db::getAttr points -of $newpin]]==2} {
                        set rect [le::createRectangle [car [amdLePath2Rects $newpin]] \
                            -design $lcv -lpp [db::getAttr LPP.lpp -of $newpin]]
                        set newPinObj [le::createPin  -term $netName -shapes $rect ]
                }
                if {[lindex [db::getAttr LPP.lpp -of $newpin] 1] != "pin"} {
                    db::setAttr purposeNum -of $newpin -value [getPurposeNumber "pin" $lcv]
                }
                amdLeAddPinLabel $newpin
                amdLeAutoAdjustPinLabel $newpin
                de::select $newpin
            } else {
                db::setAttr purposeNum -of $newpin -value [getPurposeNumber "pin" $lcv]
                amdLeExpandPin  $newpin $lcv
                amdLeAddPinLabel $newpin
                de::select $newpin
            }
            lappend cpins $netName
        }; # at this point e must have deleted old pin stuff 
    }; # end of main loop through nets
    if {[llength $cpins]!=0} {
        de::sendMessage "Created the following pins:\n $cpins"
    } else {
        de::sendMessage "No pins created." -severity warning
    }
    de::endTransaction $transaction 
}


proc _createBorderPin {netName oaDesign bshapes} {
    set layerNames [list]
    db::foreach s $bshapes {
        lappend layerNames [getShapeLayerName $s]
    }
    set hlayer [lindex [lsort -unique $layerNames] end]
    set shape  [db::getNext \
               [db::filter $bshapes -filter {[getShapeLayerName %this]=="$hlayer"}] ]
    set rect [amdLeGetBorderPinshape $shape]
    set newpin [le::createRectangle $rect -design $oaDesign -lpp [db::getAttr LPP.lpp -of $shape]]
    return [list $newpin [le::createPin -term $netName -shapes $newpin]]
}

proc amdLeAddPinLabel {pinshape} {
    set height ""
    set font ""
    set justify  ""
    set drafting ""
    set overbar ""
    set orient ""
    set xy ""
    set termName ""
    set td ""
    set newLabel ""
    set purpose ""
    # Convert the pinshape to a polygon
#    if {[db::getAttr pinshape.type] == "Path"} {
#        set pinshape [dbConvertPathToPolygon $pinshape]
#    }
    # pinshape is either a rect or polygon
    switch [db::getAttr pinshape.type] {
        "Rect" {
            set xy [centerBox [db::getAttr pinshape.bBox]]
        }
        "Polygon" {
            set xy [amdFindPointInsidePolygon [db::getAttr pinshape.points]]
        }
        default {
            return
        }
    }

    set height [envGetVal "layout" "labelHeight"]
    set font [envGetVal "layout" "labelFontStyle"]
    set justify [envGetVal "layout" "labelJustify"]
    set drafting [envGetVal "layout" "labelDrafting"]
    set overbar [envGetVal "layout" "labelOverbar"]
    set orient "R0"

    set termName [db::getAttr pinshape.pin.term.name]
    set purpose [envGetVal "layout" "pinTextPurpose"]
    if {$purpose==""} {
        set purpose "label"
    }
    set pinLayerName [getShapeLayerName $pinshape]
    set pinLPP [list $pinLayerName $purpose]

    set parent [db::getNext [db::filter [db::getAttr pin.figs -of $pinshape] \
                    -filter {[getShapeLayerName %this]==$pinLayerName && \
                        %this.bBox==[db::getAttr pinshape.bBox]}]]
    set newLabel [le::createAttributeLabel termName -valueOnly true \
                                            -parent $parent \
                                            -lpp $pinLPP \
                                            -origin $xy -just $justify -orient $orient \
                                            -font $font -height $height]

} ; #** procedure amdLeAddPinLabel **

proc envGetVal {tool param} {
    if {[info exists amd::GVAR_amdEnvVariables($tool,$param) ]} {
        return $amd::GVAR_amdEnvVariables($tool,$param)
    } else {
        return ""
    }
}

###############################################################################
#;to auto abjust pin label; 
#;Top pins =     label should be "center right" justified  with r90 orientation 
#;Bottomn pins = label should be "center left"  justified  with r90 orientation 
#;Right Pins =   label should be "center right" justified
#;Left Pins =    label should be "center left"  justified
#;Pins that don't touch any edge or that touch two edges should follow the same
#;direction of the metal the pin is on.   
#;horizontal metal = center justified r0 orentation
#;vertical metal =   center justified r90 orientation
#;AUTHOR: Pengwei Qian

proc amdLeAutoAdjustPinLabel {pin {css ""} } {
    set pinSide ""
    if {[db::getAttr pin -of $pin]!=""} {
        set pinSide [amdLeGetPinSide $pin]
        amdLeAdjustPinLabel $pin $pinSide
    } else {
        de::sendMessage "This program only works for pins.\n"
    }

} ;# ** procedure amdLeAutoAdjustPinLabel **

proc amdLeGetPinSide {pin} {
    if {[catch {set des [ed]}]} {
        return 
    }
    set border [amdReturnContextBBox $des]
    if {[db::getAttr pin -of $pin]==""} {
        de::sendMessage "amdLeGetPinSide program only works for pins.\n"
        return ""
    }
    set left  [caar $border]
    set right [caadr $border]
    set top [cadadr $border]
    set bottom  [cadar $border]

    set pinBox  [db::getAttr pin.bBox]

    set pin_left  [caar $pinBox]
    set pin_right [caadr $pinBox]
    set pin_top  [cadadr $pinBox]
    set pin_bottom  [cadar $pinBox]

    set pinW  [expr $pin_right - $pin_left]
    set pinH  [expr $pin_top - $pin_bottom]

    if { [amdEQ $left $pin_left] && [amdEQ $top $pin_top] } { #;;corner pin, 
        if { [amdLE $pinH $pinW]} {
            return "L"
        } else {
            return "U"
        }
    }

    if { [amdEQ $left $pin_left] && [amdEQ $bottom $pin_bottom] } {  
        if { [amdLE $pinH $pinW]} {
            return "L"
        } else {
            return "D"
       }
    }
    
    if { [amdEQ $right $pin_right] && [amdEQ $top $pin_top] } {
        if { [amdLE $pinH $pinW] } {
            return "R"
        } else {
            return "U"
        }
    }

    if { [amdEQ  $right $pin_right] && [amdEQ $bottom $pin_bottom] } {  
        if { [amdLE $pinH $pinW]} {
            return "R"
        } else {
            return "D"
        } 
    }

    if { [amdEQ  $left $pin_left]} {
        return "L"
    }
    if { [amdEQ  $right $pin_right]} {
        return "R"
    }


    if { [amdEQ $top $pin_top] } {
        return "U"
    }

    if { [amdEQ $bottom $pin_bottom]} {
        return "D"
    }

    if { [amdLE $pinH $pinW] } {
        return "H" ; #horizontal
    } else {
        return "V" ; #vertical
    }
}

proc amdLeAdjustPinLabel {pin pinSide} {
# Need to know what is CD equiv for pin->children
    set mems [getGroupMembers $pin]
    if {""!=$mems} {
        set pinLabel [setof [getGroupMembers $pin] {%type == "Text" || %type == "AttrDisplay"} ]
    }
    if {$mems=="" || 0 == [db::getCount $pinLabel]} {
        amdLeAddPinLabel $pin
    }
    set pinLabel [db::getNext [setof [getGroupMembers $pin] \
                                {%type == "Text" || %type == "AttrDisplay"}]]
    switch $pinSide {
            
        "L" {
             db::setAttr pinLabel.orient -value "R0"
             db::setAttr pinLabel.alignment -value "centerLeft"
             return
            }
        "R" {
             db::setAttr pinLabel.orient  -value "R0"
             db::setAttr pinLabel.alignment -value "centerRight"
             return
            }

        "U" {
             db::setAttr pinLabel.orient  -value "R90"
             db::setAttr pinLabel.alignment  -value "centerRight"
             return
            }
        "D" {
             db::setAttr pinLabel.orient -value  "R90"
             db::setAttr pinLabel.alignment -value  "centerLeft"
             return
            }
         "H" {
             db::setAttr pinLabel.orient -value "R0"
             db::setAttr pinLabel.alignment -value  "centerCenter"
             return
            }
         "V" {
             db::setAttr pinLabel.orient  -value "R90"
             db::setAttr pinLabel.alignment -value  "centerCenter"
             return
            }
         default {
             return 
            }
        } ; #** case pinSide **

} ; #** procedure amdLeAdjustPinLabel **


###############################################################################
#
# AUTHOR: Sze Tom
# DATE: 09/18/2007
# DESCRIPTION: Find a point inside a polygon to place a lable. Takes the nth
#   and nth+2 points from polygon point list. This should be a box. Find center
#   of box and see if it is inside polygon.
# USAGE:
#
###############################################################################
proc amdFindPointInsidePolygon {ptList} {
    for {set i 1} {$i < [expr [llength $ptList]-2]} {incr i} {
        set pt1 [lindex $ptList [expr $i-1] ]
        set pt2 [lindex $ptList [expr $i+1] ]
        set ctr [centerBox [list $pt1 $pt2]]
        if { [amd::amdLibrary::amdIsPointFullyInsidePolygon $ctr $ptList] } {
            set ctr [list [amdRnd [car $ctr]] [amdRnd [cadr $ctr]]]
            return $ctr
        }
    }
}

###############################################################################
# AUTHOR: Sze Tom
# DATE: 05/30/2008
# DESCRIPTION: Return a rectange for a pin where the shape hits the border, 
#   or nil if it doesn't. Depth of the rectangle will be min-metal width as 
#   given by techfile. 
# USAGE:
#   shape is shape id. Can be rect, path, or polygon
#   xform is transform to be apply to shape (optional)
#   bBox is bBox to check if shape touches (optional)
#
###############################################################################
proc amdLeGetBorderPinshape {shape {xform ""} {bBox ""}} {
    if {[catch {set design [ed]}]} {
        return 
    }
    set tf [techGetTechFile $design]
    set layerName [getShapeLayerName $shape]
    set mw [techGetSpacingRule $tf "minWidth" [list $layerName "drawing"]]
    if {""==$xform} {
        set xform [list {0.0 0.0} "R0"]
    }
    if {""==$bBox} {
        set bndBBox [amdReturnContextBBox $design]
    } else {
        set bndBBox $bBox
    }
#   Now, test if shape touch boundary box
    set shapeType [db::getAttr type -of $shape]
    switch $shapeType {
        "Rect" -
        "PathSeg" {
            return \
                [amdLeGetBorderRectRect \
                    $bndBBox [db::getAttr shape.bBox] $mw $xform \
                ]
        }
        "Path" -
        "Polygon" {
            return [amdLeGetBorderRect \
                    $bndBBox $shape $mw $xform \
                   ]
        }
    }
    return ""
}

# Give the rectangular pin that intersects the border box when given a rect
# NOTE:  Corner intersections are rejected.
# Use len provided unless feedthrough (then give the whole thing)
# UBTS FIX #267666:  Ignores l now - square off pins making depth equal to w
proc amdLeGetBorderRectRect {bbox rbox l  {xform ""}} {
    if {$xform!=""} {
        set rbox [dbTransformBBox $rbox $xform]
    }
    # Left edge pin
    if {[amdLE [leftEdge $rbox] [leftEdge $bbox]] && \
        [amdLT [rightEdge $rbox] [rightEdge $bbox]] && \
        [amdLT [topEdge $rbox] [topEdge $bbox]] && \
        [amdGT [bottomEdge $rbox] [bottomEdge $bbox]] } {
            #Calculate length to square pin
            set l [expr [topEdge $rbox] - [bottomEdge $rbox] ]
            return [list [list [leftEdge $bbox] [bottomEdge $rbox]] \
                         [list [expr [leftEdge $bbox]+$l] [topEdge $rbox]] ]
    }
    # Right edge pin
    if {[amdGT [leftEdge $rbox] [leftEdge $bbox]] && \
        [amdGE [rightEdge $rbox] [rightEdge $bbox]] && \
        [amdLT [topEdge $rbox] [topEdge $bbox]] && \
        [amdGT [bottomEdge $rbox] [bottomEdge $bbox] ]} {
            set l [expr [topEdge $rbox] - [bottomEdge $rbox]] ;# Calculate length to square pin
            return [list [list [expr [rightEdge $bbox]-$l] [bottomEdge $rbox]] \
                         [list [rightEdge $bbox] [topEdge $rbox]] ]
    }
    # Horizontal feedthrough
    if {[amdLE [leftEdge $rbox]  [leftEdge $bbox]]  && \
        [amdGE [rightEdge $rbox] [rightEdge $bbox]] && \
        [amdLT [topEdge $rbox]   [topEdge $bbox]]   && \
        [amdGT [bottomEdge $rbox] [bottomEdge $bbox]] } {
            return [list [list [leftEdge $bbox] [bottomEdge $rbox]] \
                [list [rightEdge $bbox] [topEdge $rbox]] ]
    }

    # Bottom edge pin
    if {[amdGT [leftEdge $rbox] [leftEdge $bbox]] && \
        [amdLT [rightEdge $rbox] [rightEdge $bbox]] && \
        [amdLT [topEdge $rbox] [topEdge $bbox]] && \
        [amdLE [bottomEdge $rbox] [bottomEdge $bbox]]} {
            set width [expr [rightEdge $rbox]-[leftEdge $rbox]]
            set height [expr [topEdge $rbox]-[bottomEdge $rbox]]
            if {[amdLT $width $height]} {
                set l [expr [rightEdge $rbox]-[leftEdge $rbox]] ;# Calculate length to square pin
                return [list [list [leftEdge $rbox]  [bottomEdge $bbox] ] \
                         [list [rightEdge $rbox] [expr [bottomEdge $bbox]+$l]] ]
            }
    }
    # Top edge pin
    if {[amdGT [leftEdge $rbox] [leftEdge $bbox]] && \
        [amdLT [rightEdge $rbox] [rightEdge $bbox]] && \
        [amdGE [topEdge $rbox] [topEdge $bbox]] && \
        [amdGT [bottomEdge $rbox] [bottomEdge $bbox]]} {
            set width [expr [rightEdge $rbox]-[leftEdge $rbox]]
            set height [expr [topEdge $rbox]-[bottomEdge $rbox]]
            if {[amdLT $width $height]} {
                set l [expr [rightEdge $rbox]-[leftEdge $rbox]] ;# Calculate length to square pin
                    return [list [list [leftEdge $rbox] [expr [topEdge $bbox]-$l]] \
                         [list [rightEdge $rbox] [topEdge $bbox]]]
            }
    }
    # Vertical Feedthrough
    if {[amdGT [leftEdge $rbox] [leftEdge $bbox]] && \
        [amdLT [rightEdge $rbox] [rightEdge $bbox]] && \
        [amdGE [topEdge $rbox] [topEdge $bbox]] && \
        [amdLE [bottomEdge $rbox] [bottomEdge $bbox]]} {
            return [list [list [leftEdge $rbox] [bottomEdge $bbox]] \
                         [list [rightEdge $rbox] [topEdge $bbox]]]
    }
    # -- Added the following two conditions to check if a shape
    # -- is overlapping the bottom edge or top edge of prBoundary

    if {[amdGT [topEdge $rbox] [bottomEdge $bbox]] && \
        [amdLT [bottomEdge $rbox] [bottomEdge $bbox]] && \
        [amdGE [leftEdge $rbox] [leftEdge $bbox]] && \
        [amdLE [rightEdge $rbox] [rightEdge $bbox]] } {
            return [list [list [leftEdge $rbox] [bottomEdge $rbox]] \
                         [list [rightEdge $rbox] [topEdge $rbox]] ]
    }
    if {[amdGT [topEdge $rbox] [topEdge $bbox]] && \
        [amdLT [bottomEdge $rbox] [topEdge $bbox]] && \
        [amdGE [leftEdge $rbox]  [leftEdge $bbox]] && \
        [amdLE [rightEdge $rbox] [rightEdge $bbox]]} {
            return [list [list [leftEdge $rbox] [bottomEdge $rbox]] \
                         [list [rightEdge $rbox] [topEdge $rbox]]]
    }
    return ""
}

###############################################################################
#
# AUTHOR: Sze Tom
# DATE: 05/30/2008
# DESCRIPTION: Given a shape that is either a path of polygon, fracture it 
#   into rectangles. Test each rectangle to see if it touche the boundary
#   bBox. If it does, return a new bBox whose length from boundary is l.
# USAGE:
#   bbox is boundary bBox
#   shape is shape id
#   l is length of new edge shape
#   xform is transform to be apply to shape
#
###############################################################################
proc amdLeGetBorderRect {bbox shape l {xform ""}} {
    switch [db::getAttr shape.type] {
        "Path" {
            set boxList [amdLePath2Rects $shape] 
        }
        "Polygon" {
            set boxList [getPolygonRectPoints $shape]
        }
        default {
            return ""
        }
    }
    foreach rect $boxList {
        set edgeRect [amdLeGetBorderRectRect $bbox $rect $l $xform]
        if {""!=$edgeRect} {
            return $edgeRect
        }
    }
    return ""
}

# This may not work correctly for all cases, but for typical cases can be ok.
proc getPolygonRectPoints {p} {
    set pa [db::getAttr p.points]
    set rects [list]
    # Sort by x
    set s [lindex [lsort -increasing -index 0  $pa] 0]
    set i [lsearch $pa $s]
    set pan [concat [lrange $pa $i end] [lrange $pa 0 [expr $i-1]]]
    set anchor [lindex $pan 0]
    for {set i 2} {$i<[llength $pan]} {set i [expr $i+2]} {
        set upright [lindex $pan $i]
        lappend rects [list $anchor $upright]
    }
    return $rects
 }

#; Return a set of rectangles repressenting the path
#; Doesn't work for path that are non-manhattan
#      set p [db::getAttr object -of [de::getSelected -design [ed]]]
#      amd::autoPin::amdLePath2Rects $p
proc amdLePath2Rects {path} {
    set hwid [amdRndD [expr [db::getAttr path.width]/2]]
    # extensions for start/end - do different things for dif path types
    set type [db::getAttr path.type]
    set rects [list]
    switch $type {
        "Path" {
            switch [db::getAttr path.style] {
                "extend" {
                    set ext $hwid
                }
                "truncate" {
                    set ext 0
                }
                default {
                    set ext 0
                }
            }
        }
        "PathSeg" {
            lappend rects [db::getAttr path.bBox]
            return $rects
        }
    }
    set points [db::getAttr path.points]
    for {set i 0} {$i<[expr [llength $points]-1]} {set i [expr $i+1]} {
        # Get the two adjacent points
        set pt1 [lindex $points $i]
        set pt2 [lindex $points [expr $i+1]]
        # Figure out if they're endpoints - if so use their extensions
        # rather than halfwidth
        if {0==$i} {
            set ext1 $ext
        } else {
            set ext1 $hwid
        }
        if {[expr [llength $points]-2]==$i} {
            set ext2 $ext
        } else {
            set ext2 $hwid
        }
        # Okay, now calc the rectangle
        # Going North
        set rect ""
        if {[amdEQ [xCoord $pt1] [xCoord $pt2]] && \
            [amdLT [yCoord $pt1] [yCoord $pt2]] } {
                set rect [list [list [expr [xCoord $pt1]-$hwid] [expr [yCoord $pt1]-$ext1]] \
                               [list [expr [xCoord $pt2]+$hwid] [expr [yCoord $pt2]+$ext2]] ]
        }
        # Going South
        if {[amdEQ [xCoord $pt1] [xCoord $pt2]] && [amdGT [yCoord $pt1] [yCoord $pt2]]} {
            set rect [list [list [expr [xCoord $pt2]-$hwid] [expr [yCoord $pt2]-$ext2]] \
                           [list [expr [xCoord $pt1]+$hwid] [expr [yCoord $pt1]+$ext1]] ]
        }
        # Going East
        if {[amdEQ [yCoord $pt1] [yCoord $pt2]] && [amdLT [xCoord $pt1] [xCoord $pt2]]} {

            set rect [list [list [expr [xCoord $pt1]-$ext1] [expr [yCoord $pt1]-$hwid]] \
                           [list [expr [xCoord $pt2]+$ext2] [expr [yCoord $pt2]+$hwid]] ]
        }
        #Going West
        if {[amdEQ [yCoord $pt1] [yCoord $pt2]] && [amdGT [xCoord $pt1] [xCoord $pt2]]} {
            
            set rect [list [list [expr [xCoord $pt2]-$ext2] [expr [yCoord $pt2]-$hwid]] \
                           [list [expr [xCoord $pt1]+$ext1] [expr [yCoord $pt1]+$hwid]] ]
        }
        if {""!=$rect} {
            lappend rects $rect
        }


    } ; # end of for loop
    return $rects

}

proc amdLeGetRoutingLayers {} {
    if {[catch {set des [ed]}]} {
        return 
    }
    if {[info exists amd::GVAR_amdLayVariables(routingLayers)]} {
        set val $amd::GVAR_amdLayVariables(validRoutingLayers)
    } else {
        set val [db::getAttr value -of \
            [cm::getConstraints validRoutingLayers -of $des -local false]]
        if {$val==""} {
            de::sendMessage "No valid routing layers" -severity error
            return [list]
        }
    }
    return $val
}
proc amdPGChangeLayerCB {widget} {
    if {[catch {set des [ed]}]} {
        return 
    }

    if {"r"==[db::getAttr mode -of $des]} {
        de::sendMessage "[getLCV $des] is opened in read-only mode. Please reopen in write mode, before running pin utility." -severity error
        return 
    }
    set sel [de::getSelected -design $des -filter {%this.object.pin!=""}]
    set dialog [db::getAttr parent.parent -of $widget]
    set layerCyc [gi::findChild layerCyc -in $dialog]
    set metalLayerName [db::getAttr value -of $layerCyc]
    if {$metalLayerName=="LSW"} {
        set metalLayerName [car [leGetEntryLayer]]
    }
    set t [de::startTransaction "Change layer to $metalLayerName" -design $des]
    db::foreach s $sel {
        set shape [db::getAttr s.object]
        set mems [getGroupMembers $shape]
        if {$mems!=""} {
            db::foreach m $mems {
                if {[oa::isShape $m]} {
                    db::setAttr m.layerNum -value [getLayerNumber $metalLayerName $des]
                }
            }
        } else {
            db::setAttr shape.layerNum -value [getLayerNumber $metalLayerName $des]
        }
    }
    de::endTransaction $t
}

proc amdPGChangeAlignCB {widget} {
    if {[catch {set des [ed]}]} {
        return 
    }

    if {"r"==[db::getAttr mode -of $des]} {
        de::sendMessage "[getLCV $des] is opened in read-only mode. Please reopen in write mode, before running pin utility." -severity error
        return 
    }
    set sel [de::getSelected -design $des -filter {%object.pin!="" || \
                                                   %object.type=="AttrDisplay" || \
                                                   %object.type=="Text"}]
    set dialog [db::getAttr parent.parent -of $widget]
    set alignCyc [gi::findChild alignCyc -in $dialog]
    set val [db::getAttr value -of $alignCyc]
    set tran [de::startTransaction "Label Align" -design $des]
    db::foreach s $sel {
        set shape [db::getAttr s.object]
        set mems [getGroupMembers $shape]
        if {$mems==""} {
            continue
        }
        db::foreach m $mems {
            if {"AttrDisplay"==[db::getAttr m.type] || "Text"==[db::getAttr m.type] } {
                switch $val {
                    "R0" -
                    "R90" {
                        db::setAttr m.orient -value $val
                        db::setAttr m.alignment -value "centerCenter"
                        continue
                    }
                    "Left" {
                        db::setAttr m.orient -value "R0"
                        db::setAttr m.alignment -value "centerLeft"
                        continue
                    }
                    "Right" {
                        db::setAttr m.orient -value "R0"
                        db::setAttr m.alignment -value "centerRight"
                        continue
                    }
                    "Top" {
                        db::setAttr m.orient -value "R90"
                        db::setAttr m.alignment -value "centerRight"
                        continue
                    }
                    "Bottom" {
                        db::setAttr m.orient -value "R90"
                        db::setAttr m.alignment -value "centerLeft"
                        continue
                    }
                    default {
                        de::sendMessage "Unknown alignement $val." \
                            -severity error
                        continue
                    }

                }
            }
        }; # end foreach mem
    }
    de::endTransaction $tran
}

proc amdPGChangeWidth {widget} {
    if {[catch {set des [ed]}]} {
        return 
    }

    if {"r"==[db::getAttr mode -of $des]} {
        de::sendMessage "[getLCV $des] is opened in read-only mode. Please reopen in write mode, before running pin utility." -severity error
        return 
    }
    set sel [de::getSelected -design $des -filter {%this.object.pin!=""}]
    set dialog [db::getAttr parent.parent -of $widget]
    set width [db::getAttr value -of [gi::findChild widthFld -in $dialog]]
    set t [de::startTransaction "Change pin width" -design $des]
    amdPAChangeSize $des $width
    de::endTransaction $t
}

proc amdPGChangeHeight {widget} {
    if {[catch {set des [ed]}]} {
        return 
    }

    if {"r"==[db::getAttr mode -of $des]} {
        de::sendMessage "[getLCV $des] is opened in read-only mode. Please reopen in write mode, before running pin utility." -severity error
        return 
    }
    set sel [de::getSelected -design $des -filter {%this.object.pin!=""}]
    set dialog [db::getAttr parent.parent -of $widget]
    set height [db::getAttr value -of [gi::findChild heightFld -in $dialog]]
    set t [de::startTransaction "Change pin height" -design $des]
    amdPAChangeSize $des "" $height
    de::endTransaction $t
}

proc amdPGChangeBoth {widget} {
    if {[catch {set des [ed]}]} {
        return 
    }

    if {"r"==[db::getAttr mode -of $des]} {
        de::sendMessage "[getLCV $des] is opened in read-only mode. Please reopen in write mode, before running pin utility." -severity error
        return 
    }
    set t [de::startTransaction "Change pin width and height" -design $des]
    amdPGChangeHeight $widget
    amdPGChangeWidth  $widget
    de::endTransaction $t
}


proc amdLeExpandPins {widget} {
    if {[catch {set des [ed]}]} {
        return 
    }

    if {"r"==[db::getAttr mode -of $des]} {
        de::sendMessage "[getLCV $des] is opened in read-only mode. Please reopen in write mode, before running pin utility." -severity error
        return 
    }
    set sel [de::getSelected -design $des -filter {%this.object.pin!="" && \
                                                    %this.object.type=="Rect"}]
    db::foreach s $sel {
        amdLeExpandPin [db::getAttr s.object] $des
    }
}

proc amdLeExpandPin {pinShape cv} {
    set termName [db::getAttr pinShape.pin.term.name]
    set accessDir [db::getAttr pinShape.pin.accessDir]
    set status [db::getAttr pinShape.pin.placementStatus]
    set transaction [de::startTransaction "Expand pin $termName" -design $cv]
    set trueOverlaps [getOverlapedShapes $pinShape $cv]
    if {[llength $trueOverlaps]==0} {
        de::sendMessage "There is nothing to expand the pin." -severity warning
        de::endTransaction $transaction
        return
    }
    set  connected [db::createCollection $trueOverlaps]
    set plist [list]
    db::foreach fig $connected {
        set type [db::getAttr fig.object.type]
        set depth  [db::getAttr fig.lineage.depth]
        set inst [lindex [db::getAttr fig.lineage.levels] [expr $depth-1] 0]
        if {$inst!="" && ([db::getAttr inst.type]=="StdVia" || [db::getAttr inst.type]=="CustomVia")} {
            continue
        }
        if {$inst!="" && \
            [db::getCount [de::getContexts -filter {%editDesign == [db::getAttr inst.master]}]]==0} {
            set cell [dm::getCellViews [db::getAttr inst.viewName] \
                -libName [db::getAttr inst.libName] -cellName [db::getAttr inst.cellName]]
            de::createContext $cell -readOnly true
        }
        
        set tr [db::getAttr fig.lineage.transform]
        set box [db::getAttr fig.object.bBox ];
        set point  [oa::transform [oa::Point [lindex $box 0 0] [lindex $box 0 1]] $tr]	
        le::yank [ db::getAttr fig.object ] -points $box -levels 1  \
            -regionType rectangle -anchor {0 0}
        lappend plist [db::getNext [de::paste [ed] -point $point -orient [db::getAttr fig.lineage.transform.orient]]]
    }
    if {[llength $plist]!=0} {
        set  cp [db::createCollection $plist]
    } else {
        de::endTransaction $transaction
        return 
    }

    db::destroy $pinShape
    if {[db::getCount $cp]>1} {
        set newpin [db::getAttr object -of [db::getNext [le::merge $cp]]]
    } else {
        set newpin [db::getAttr object -of $cp]
    }
    switch [db::getAttr newpin.type] {
        "Path" {
            if {[llength [db::getAttr points -of $newpin]]==2} {
                set rect [le::createRectangle [car [amdLePath2Rects $newpin]] \
                    -design $cv -lpp [db::getAttr LPP.lpp -of $newpin]]
                db::destroy $newpin
                db::setAttr purposeNum -of $rect -value [getPurposeNumber "pin" $cv]
                set newPinObj [le::createPin  -term $termName -shapes $rect \
                            -accessDir $accessDir -status $status ]
                amdLeAutoAdjustPinLabel $rect
                de::select $rect
            } else {
                set rectShapes [amdLePath2Rects $newpin]
                set rects [list]
                foreach rectShape $rectShapes {
                    set rect [le::createRectangle $rectShape \
                        -design $cv -lpp [db::getAttr LPP.lpp -of $newpin]]
                    lappend rects $rect
                }
                set coll [db::createCollection $rects]
                set newpin [le::merge $coll]
                set newPinObj [le::createPin  -term $termName -shapes $newpin \
                            -accessDir $accessDir -status $status ]

                db::setAttr purposeNum -of $newpin -value [getPurposeNumber "pin" $cv]
                amdLeAutoAdjustPinLabel $newpin
                de::select $newpin
            }
        }
        "PathSeg" {
            set rect [le::createRectangle [db::getAttr newpin.bBox] \
                    -design $cv -lpp [db::getAttr LPP.lpp -of $newpin]]
            db::destroy $newpin
            db::setAttr purposeNum -of $rect -value [getPurposeNumber "pin" $cv]
            set newPinObj [le::createPin  -term $termName -shapes $rect \
                        -accessDir $accessDir -status $status ]
            amdLeAutoAdjustPinLabel $rect
            de::select $rect
        }
        "Polygon" {
            set rect $newpin
            if {[llength [db::getAttr newpin.points]]==4} {
                set rect [le::createRectangle [db::getAttr newpin.bBox] \
                    -design $cv -lpp [db::getAttr LPP.lpp -of $newpin]]
                db::destroy $newpin

            }
            db::setAttr purposeNum -of $rect -value [getPurposeNumber "pin" $cv]
            set newPinObj [le::createPin  -term $termName -shapes $rect \
                    -accessDir $accessDir -status $status ]
            amdLeAutoAdjustPinLabel $rect
            de::select $rect
        }
        "Rect" {
            db::setAttr purposeNum -of $newpin -value [getPurposeNumber "pin" $cv]
            set newPinObj [le::createPin  -term $termName -shapes $newpin \
                    -accessDir $accessDir -status $status ]
            amdLeAutoAdjustPinLabel $newpin
            de::select $newpin
        }

    }
    de::endTransaction $transaction
}


proc figToRect {newpin termName cv} { 
    set origShape $newpin
    switch [db::getAttr newpin.type] {
        "Path" {
            if {[llength [db::getAttr points -of $newpin]]==2} {
                set newpin [le::createRectangle [car [amdLePath2Rects $newpin]] \
                    -design $cv -lpp [db::getAttr LPP.lpp -of $newpin]]
            } else {
                set rectShapes [amdLePath2Rects $newpin]
                set rects [list]
                foreach rectShape $rectShapes {
                    set rect [le::createRectangle $rectShape \
                        -design $cv -lpp [db::getAttr LPP.lpp -of $newpin]]
                    lappend rects $rect
                }
                set coll [db::createCollection $rects]
                set newpin [le::merge $coll]
            }
            db::destroy $origShape
        }
        "Polygon" {
            if {[llength [db::getAttr points -of $newpin]]==4} {
                set newpin [le::createRectangle [db::getAttr newpin.bBox] \
                    -design $cv -lpp [db::getAttr LPP.lpp -of $newpin]]
                db::destroy $origShape
            }
        }
    }
    return $newpin
}


proc getOverlapedShapes {shape cv} {
    set allFigs [list]
    set tr [oa::Transform 0 0 "R0"]
    set shapes [list [list $shape $tr]]
    set tmp [list [db::getAttr shape.bBox]]

    for {set i 0} {$i<[llength $shapes]} {incr i} {
        set shape [lindex $shapes $i 0]
        set tr [lindex $shapes $i 1] 
        set bBox [dbTransformBBox [db::getAttr shape.bBox] $tr]
        set layer [db::getAttr shape.layerNum]
        set purpose [db::getAttr shape.purposeNum]
        set lpp [list [getLayerName $layer $cv] [getPurposeName $purpose $cv]]

        set figs [de::getFigures $bBox \
            -type rectangle \
            -design $cv \
            -touch true \
            -depth -1 \
            -filter {[isShapeOnLayer %object $layer] && \
                %object.pin=="" && %object.type!="Text" \
                    && %object.bBox!=$bBox \
                    && %object.type!="AttrDisplay" }]
        db::foreach fig $figs {
            set o [db::getAttr fig.object]
            set t [db::getAttr fig.lineage.transform]
            set b [dbTransformBBox [db::getAttr o.bBox] $t]
            if {![member $b $tmp]} {
                lappend shapes [list $o $t]
                lappend tmp $bBox
                lappend allFigs $fig
            } 
        } 
    }
    if {[llength $allFigs]!=0} {
        return $allFigs
    } else {
        return ""
    }
}

proc isShapeOnLayer { oaFig layerNum } {
        if { ![oa::isShape $oaFig] } { return 0 }
        if { [db::getAttr layerNum -of $oaFig] != $layerNum } { return 0 }
        return 1
    }

}
