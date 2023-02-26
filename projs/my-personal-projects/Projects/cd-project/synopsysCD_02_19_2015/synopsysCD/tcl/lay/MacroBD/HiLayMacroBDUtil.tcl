namespace eval amd::_MacroBD {
    
proc amdHiLayMacroBDUtil {context} {
    set win [db::getAttr context.window]
    
    if ![info exists ::amd::AMDPDKgvarLibList] {
        set defTemplatePath [db::getPrefValue amdPwrGrdDefTemplateFile] ;
        if [file exists $defTemplatePath] {
            set missingTemplateFile [::amd::_parsPwrGrdTemplate $context $defTemplatePath] 
        } else {
            set missingTemplateFile 1
        }
        if $missingTemplateFile {
            set readFile [gi::prompt "$defTemplatePath template file doesn't exist or has incorrect data.\nDo you want to continue?" \
                -buttons {Yes No} -icon question -parent $win -title "Read template file failed"];
            if {"No" == $readFile} {
                de::sendMessage "Process interrupted by user" -severity warning
                return            
            }
        }
    } 

    set projdef [split [db::getPrefValue amdMacroBDSTDCellView]]
    set deflib  [lindex $projdef 0]
    set defcell [lindex $projdef 1]
    set defview [lindex $projdef 2]


    set design [db::getAttr context.editDesign];
    set window [db::getAttr context.window];
    set libName   [db::getAttr design.libName]
    set cellName  [db::getAttr design.cellName]
    set viewName  [db::getAttr design.viewName]

    set dialog [gi::getDialogs amdHiLayMacroBDForm -parent $window];
    if ![db::isEmpty $dialog] {
        db::destroy $dialog
    }
    set dialog [gi::createDialog amdHiLayMacroBDForm -parent $window \
        -title "Macro Boundary Util" -execProc [list [namespace current]::amdHiLayMacroBD $context]];
    set target_field [gi::createTextInput target -parent $dialog -label "Target Cell" \
        -readOnly true -value [join [list $libName $cellName $viewName] :]];
    set lGroup [gi::createGroup lGroup -parent $dialog]
    set rGroup [gi::createGroup rGroup -parent $dialog];
    set bGroup [gi::createGroup bGroup -parent $dialog ];
    set brGroup [gi::createGroup brGroup -parent $bGroup -decorated false];
    set blGroup [gi::createGroup blGroup -parent $bGroup -decorated false];
    set cv_field [dm::createCellViewInput cvField  \
        -parent $rGroup -value [file join $deflib $defcell $defview] \
        -requireExisting true -required false ]
    set cell_bool [gi::createBooleanInput cellen -parent $lGroup \
        -label "Surround with cell" -value 1     
    set flip_bool [gi::createBooleanInput flipen -parent $lGroup \
        -label "Flip adjacent rows" -value 1];
    array set PdkEnv $::amd::PdkEnv
    set metals $PdkEnv(pwrgridMetals);
    if {[lindex $metals 0] == "M1" || [lindex $metals 0] == "M2"} {
        set metals [lsort -command [list ::amd::_sortLayerByMaskNumberDecr $design] $metals]
    }
    
    set pg_bool [gi::createBooleanInput pgen -parent $blGroup \
        -label "Surround with PG" -value 1 -valueChangeProc [namespace current]::checkpgen]
    set halo_field [gi::createNumberInput halo -parent $brGroup -value 5.0 -label "Surround of PG (in um)" -valueType float -width 5]
    set tlay_field [gi::createMutexInput toplayer -parent $brGroup \
        -label "Highest layer to use" -enum $metals -value [lindex $metals 0]]
    
    set template_file_label [gi::createLabel templateLabel -parent $dialog -label "Filename for non-default template"]]
        
    set template_file_field [gi::createFileInput templateName -parent $dialog -mode select ]
    if ![info exists  amd::AMDPDKgvarLibList] {
        db::setAttr template_file_field.required -value true
    } else {
        db::setAttr template_file_field.required -value false
    }    
        
    set createbd_bool [gi::createBooleanInput createbd -parent $dialog \
        -label "Create {cell}_BD" -value 1]
    gi::layout $lGroup -leftOf $rGroup -equalWidth true
    gi::layout $blGroup -leftOf $brGroup
    gi::layout $halo_field -justify right
    gi::layout $tlay_field -justify right
    gi::layout $target_field -justify right
    db::setAttr target_field.style.background -value #c0c0c0
}
    
    
proc checkpgen {widget} {
    set dialog [db::getAttr widget.parent.parent.parent];
    set template_file_field [gi::findChild templateName -in $dialog]
    if [db::getAttr widget.value] {
        db::setAttr template_file_field.required -value true
    } else {
           db::setAttr template_file_field.required -value false
    }
}
            

                
proc amdHiLayMacroBD {context dialog} {
    set cellen [gi::findChild cellen.value -in $dialog];
    set pgen   [gi::findChild pgen.value -in $dialog];
    set tcell  [gi::findChild cvField.value -in $dialog];
    set design    [db::getAttr context.editDesign ];
    set vhalo [gi::findChild halo.value -in $dialog];
    set hhalo [gi::findChild halo.value -in $dialog];
    set flipven [gi::findChild flipen.value -in $dialog]
    set template [gi::findChild templateName.value -in $dialog];
    set createbd [gi::findChild createbd.value -in $dialog]
    set toplayer [gi::findChild toplayer.value -in $dialog]
    
    if {!$pgen && !$cellen} {
        de::sendMessage "Both surround with PG and surround with cell were disabled" -severity warning
        return 0
    }
    if {$cellen && $tcell == ""} {
        de::sendMessage "No cell to tile around block" -severity warning
        return 0
    }

    #Grab the boundary object
    set cellbd [oa::PRBoundaryFind [oa::getTopBlock $design]]
    if {"" == $cellbd} {
        de::sendMessage "No prBoundary for cell - aborting..." -severity warning
        return
    }
    #If we're asked, create the bd cell and instantiate this cell in it...
    if $createbd {
        set libName [db::getAttr design.libName];
        set oldCellName [db::getAttr design.cellName];
        set cellName [join [list $oldCellName BD] _]
        set viewName [db::getAttr design.viewName];
        set cellView [dm::getCellViews layout -cell [dm::getCells $cellName -libName $libName]]
        if ![db::isEmpty $cellView] {
            set prompt [gi::prompt "$libName/$cellName/$viewName already exists.\nDo you want ot overwrite it?" \
                -icon warning -buttons {Yes No} -title "Already Exists"]
            if {"Yes" == $prompt} {
                db::destroy $cellView
            } else {
                return
            }
        }
        set cellView [dm::createCellView layout \
            -cell [dm::findCell $cellName -libName $libName] -viewType maskLayout];
        set ctx [de::open $cellView];
        set design [db::getAttr ctx.editDesign];
        de::copy $cellbd ; de::paste $design -point {0 0};
        le::createInst -design $design -origin {0 0} \
            -libName $libName -cellName $oldCellName -viewName $viewName  
    } else {
        set thegroup [oa::FigGroupFind [oa::getTopBlock [ed]] [oa::SimpleName [oa::CdbaNS] BoundaryDRCGroup]]
        if {"" != $thegroup} {
            set tr [de::startTransaction "Delete 1 FigGroup" -design  $design]
            oa::destroyFigs $thegroup
            oa::destroy $thegroup 
            de::endTransaction $tr
        }
    }
    #    ; Calculate where the power grids should end - use the halo to increase the extents of the bbox
    if $cellen {
        set tctx [de::open $tcell -readOnly true -headless true]    
        set tdesign [db::getAttr tctx.editDesign]
        set tprb [oa::PRBoundaryFind [oa::getTopBlock $tdesign]];
        if {"" == $tprb} {
            de::sendMessage "No prBoundary in tile cell - can't tile it around the boundary!" -severity warning 
            return 
        }    
        set stdbb [db::getAttr tprb.bBox];
        set stdw [expr [lindex $stdbb 1 0] - [lindex $stdbb 0 0]]
        set stdh [expr [lindex $stdbb 1 1] - [lindex $stdbb 0 1]]
        
        set hhalo [expr round($hhalo/$stdw)*$stdw]
        set vhalo [expr round($vhalo/$stdh)*$stdh]
    
        # ; Sanity check the prBound coordinates
        if ![[namespace current]::amdHiLayMacroBD_CheckBD $design $cellbd $stdh $stdw ] {
            return 
        }
    } else {
        set stdw 0;
        set stdh 0;
    }
    # ; Load up the template spec for the powergrid
    if $pgen {
        if {"" == $template} {
            set  spec  $amd::AMDPDKgvarLibList ;
        } else {
            de::sendMessage "Loading custom template... $template"    -severity information
            if ![::amd::_parsPwrGrdTemplate $context $template] {
                de::sendMessage "Custom template $template loaded"    -severity information
                set  spec  $amd::AMDPDKgvarLibList ;    
            } else {
                de::sendMessage "Incorrect template file... $template"    -severity error
                return
            }    
        }
        #; Changed track to drawing...
        #; also make a dummy netname to prevent via problems with old grid cell
        set spec [[namespace current]::amdHiLayMacroBD_fixspec $spec $design $toplayer];
    }
    #    ; create the halo'ed bounding box
    set cellbd_bb [db::getAttr cellbd.bBox]     
    set  lft_edge [expr [lindex $cellbd_bb 0 0] - $hhalo] ;
    set  rgt_edge [expr [lindex $cellbd_bb 1 0] + $hhalo] ;
    set  bot_edge [expr [lindex $cellbd_bb 0 1] - $vhalo] ;
    set  top_edge [expr [lindex $cellbd_bb  1 1] + $vhalo] ;
    set  halo_box [list [list $lft_edge  $bot_edge] [list $rgt_edge $top_edge]]
    set instLst [list]
    set tr [de::startTransaction "Create Macro Boundary" -design $design ]
    set rBoxes [[namespace current]::polygon2Rects $design $halo_box [db::getAttr cellbd.points]]
	if [db::checkVersion -atLeast J-2014.12] {
		set scale 1
	} else {
		set scale [db::getAttr design.dBUPerUU]
	}
    foreach rect $rBoxes  {
        set xmin [expr [lindex $rect 0]/$scale]
        set ymin [expr [lindex $rect 1]/$scale]
        set xmax [expr [lindex $rect 2]/$scale]
        set ymax [expr [lindex $rect 3]/$scale]
        # insert power grid
        if $pgen {
            lappend instLst [[namespace current]::amdHiLayMacroBD_InsertPG $design $xmin $ymin $xmax $ymax $spec]
        }
        # insert cells
        if $cellen {
            set rowmin [expr round($ymin/$stdh)]
            set rowmax [expr round($ymax/$stdh)]
            set colmin [expr round($xmin/$stdw)]                
            set colmax [expr round($xmax/$stdw)]
        
            for {set row $rowmin} {$row < $rowmax} {incr row} {
                for {set col $colmin} {$col < $colmax} {incr col} {
                    set ptx [expr $col*$stdw];
                    set pty [expr $row*$stdh]    
                    lappend instLst [[namespace current]::amdHiLayMacroBD_InsertCell $design $tdesign  [list $ptx $pty] $flipven $stdh  $stdw]
                }
            }
        }
    }
    if [llength $instLst] {
        set thegroup [oa::FigGroupCreate [oa::getTopBlock $design] [oa::SimpleName [oa::CdbaNS] BoundaryDRCGroup] 0] 
        oa::setOrigin $thegroup [oa::Point 0 0]
        oa::setOrient $thegroup [oa::Orient R0]
    }
    foreach inst $instLst {
        oa::FigGroupMemCreate $thegroup $inst
    }
    de::endTransaction $tr
}


proc amdHiLayMacroBD_InsertPG {cv minx miny maxx maxy spec} {
    array set PdkEnv $::amd::PdkEnv
    set lcv [split [db::getPrefValue amdPwrGrdCellView] /]
    array set AMDPDKgvarLibArray $spec;
    set gridDefSpec $AMDPDKgvarLibArray(defGridSpec);
    set mspecs [amd::_formatMspec $gridDefSpec];
    set mdirections [amd::formatMap $AMDPDKgvarLibArray(defGridDirs)];
    set stdViaList [amd::_formatLst $AMDPDKgvarLibArray(amdPwrGridVias)];
    set opts [amd::formatMap $AMDPDKgvarLibArray(defGridOpts)];
    set trans [de::startTransaction "Create Power Grid" -design $cv];
    set metallist [amd::_formatLst $PdkEnv(pwrgridMetals)];
    set inst [le::createInst -viewName [lindex $lcv 2] -cellName [lindex $lcv 1] -libName [lindex $lcv 0] \
        -design $cv -origin {0 0}];
    set app [oa::ParamArray]
    amd::_setAppValue app mspecs $mspecs
    amd::_setAppValue app mdirections $mdirections
    amd::_setAppValue app stdViaList $stdViaList 
    amd::_setAppValue app metallist $metallist
    amd::_setAppValue app opts $opts           
    oa::setParams $inst $app
    db::setParamValue minx -type float -value $minx -of $inst
    db::setParamValue miny -type float -value $miny -of $inst
    db::setParamValue maxx -type float -value $maxx -of $inst
    db::setParamValue maxy -type float -value $maxy -of $inst
    db::setParamValue enable -type string -value  toolPlaced -of $inst
    de::endTransaction $trans
    return $inst
}
    
        
proc amdHiLayMacroBD_InsertCell {cv tcell pt flipven stdh stdw} {
    set x [lindex $pt 0];
    set y [lindex $pt 1];
    
    set bd [oa::PRBoundaryFind  [oa::getTopBlock $tcell]];
    set tBBox [db::getAttr bd.bBox];
    set offset_x [lindex $tBBox 0 0];
    set offset_y [lindex $tBBox 0 1];

    set orient     R0;
    if $flipven {
        set row [expr int(round($y/$stdh))];
        if {[expr $row % 2] == 1 } { 
            set offset_y [expr 0 - [lindex $tBBox 1 0]];
            set orient MX
        }
    }
    set inst [le::createInst -design $cv -master $tcell \
        -origin [list [expr $x - $offset_x] [expr $y - $offset_y]] -orient $orient]
    return $inst
}    
        
        
proc amdHiLayMacroBD_fixspec {spec design {toplayer 0}} {
    set num 0;
    set stop 0
    set lres 0;
    array set specArray $spec
    array set gridSpecArray $specArray(defGridSpec);
    set metals [lsort -command [list ::amd::_sortLayerByMaskNumber $design] [array names gridSpecArray]];
    set ind [lsearch $metals $toplayer];
    set lspecLst [list]    
    set newSpec [list]    
    foreach layer [lrange $metals 0 $ind] {
        set lspec $gridSpecArray($layer);
        set tspecLst [list]
        foreach tspec [lindex $lspec 1] {
            set tspec_o $tspec
            if {"track" == [lindex $tspec_o 0]} {
                set tspec_o [lreplace $tspec_o 0 0 drawing]
            }
            if {"drawing" == [lindex $tspec_o 0] && [llength $tspec_o] < 6 && [lindex $tspec_o 5 0] != "name"} {
                set dummy [join [list dmy $num] _];
                incr num
                set tspec_o [linsert $tspec_o 5 [list name $dummy]]
            }
            lappend tspecLst $tspec_o
        }
        set lspecLst [lreplace $lspec 1 1 $tspecLst]
        lappend newSpec $layer     
        lappend newSpec $lspecLst    
    }
    set specArray(defGridSpec) $newSpec
    return [array get specArray]
}    

          
proc amdHiLayMacroBD_CheckBD {cv cellbd stdh stdw} {
    #; First delete all old markers 
    db::destroy [db::getMarkers -design $cv -tool amdHiLayMacroBD]
    set status 1
    set coords [db::getAttr cellbd.points];
    # ; Make sure each point is aligned to the tile cell width/height - must be within 1/2 grid (.0005)
    set tol 0.0005    
    set blk [oa::getTopBlock $cv];
    set msg "prBound not aligned to cell tiling"
    set tr [de::startTransaction "Add Makers" -design [ed]]    
    foreach pt $coords {
        set x [lindex $pt 0] ; set y [lindex $pt 1] ;
        set row [expr round($y/$stdh)]
        set col [expr round($x/$stdw)]
        if {[expr abs($row*$stdh-$y)] > $tol || [expr abs($col*$stdw-$x)] > $tol} {
            set pArray [oa::PointArray [oa::Box [expr $x-0.1] [expr $y - 0.1] [expr $x +0.1] [expr $y + 0.1]]];
            oa::MarkerCreate $blk $pArray $msg $msg amdHiLayMacroBD 1 1 warning 
            de::sendMessage "Coordinate of prBoundary $pt not alighned to fill-cell width/height" -severity warning
            set status 0;
        }
    }
    de::endTransaction $tr
    return $status
}


proc polygon2Rects {design box points} {
    set r [le::createRectangle $box -design $design -lpp M1]
    le::chop $r -points $points -copy false -regionType polygon 
    set p [db::getShapes -of $design];
    set boxLst [le::splitIntoBoxes $p -type maxY]
    le::delete $p
    return $boxLst
}

}            
                
            
    

            




            
        
            
