# Copyright (c) 2004-2015 Synopsys, Inc. This Galaxy Custom Designer software
# and the associated documentation are confidential and proprietary to
# Synopsys, Inc. Your use or disclosure of this Galaxy Custom Designer software
# is subject to the terms and conditions of a written license agreement between
# you, or your company, and Synopsys, Inc.

namespace eval ::amd {
variable AMDPDKgvarLibList
gi::createDataType sliceOptions -toDisplayProc [namespace current]::_toDisplay \
    -toValueProc   [namespace current]::_toValue
proc _toDisplay {value} {
    switch $value {
        zeroPullbacks             {return "Zero Pullbacks"}
        zeroExceptCutPullbacks    {return "Zero Pullbacks Except to Cut"}
        leavePullbacks            {return "Leave Pullbacks After Slicing"}
    }
}
proc _toValue {display} {
    switch $display {
        "Zero Pullbacks"                 {return zeroPullbacks}
        "Zero Pullbacks Except to Cut"     {return zeroExceptCutPullbacks}
        "Leave Pullbacks After Slicing"    {return leavePullbacks}
    }
}

proc _min {a b} {
    if {$b < $a} {
        return $b
    } else {
        return $a
    }
}

proc _max {a b} {
    if {$b > $a} {
        return $b
    } else {
        return $a
    }
}

proc _sortLayerByMaskNumber {d a b} {
    set tech [db::getAttr d.tech]
    set m1 [oa::getMaskNumber [oa::LayerFind $tech $a]]
    set m2 [oa::getMaskNumber [oa::LayerFind $tech $b]]
    if {$m1 < $m2} {
        return -1
    } else {
        return 1
    }
} 

proc _sortLayerByMaskNumberDecr {d a b} {
    set tech [db::getAttr d.tech]
    set m1 [oa::getMaskNumber [oa::LayerFind $tech $a]]
    set m2 [oa::getMaskNumber [oa::LayerFind $tech $b]]
    if {$m1 < $m2} {
        return 1
    } else {
        return -1
    }
} 


proc _amdPwrGridTemplate {w c} {
    variable AMDPDKgvarLibList
    set initialDir [db::getPrefValue amdPwrGrdTemplateDir]    
    set filePath [xt::getOpenFile -window $w -title "Specify Template File" \
    -initialDir $initialDir -fileTypes {{*} {*.template} {*.*} }];
    if {"" == $filePath} {return 1}
    db::setPrefValue amdPwrGrdTemplateFile -value $filePath
    if [[namespace current]::_parsPwrGrdTemplate $c $filePath] {return 1}
    db::setPrefValue amdPwrGrdTemplateFile -value $filePath
    db::setPrefValue amdPwrGrdTemplateDir -value [file dirname $filePath];
    de::sendMessage "$filePath is selected" -severity information   
    return 0       
}
    
   
proc _parsPwrGrdTemplate {context fileName} {
    variable AMDPDKgvarLibList
    set defGridSpec [list];
    set defGridDirs [list];
    set defGridOpts [list];
    set amdPwrGridVias [list];
    set fd [open $fileName r];
    set buffer [split [read $fd] \n];
    close $fd
    set state IDLE
    foreach line $buffer {
        switch $state {
            IDLE {
               if [regexp {LAYER[\s]+([a-z_A-Z0-9]+)[\s]+Pitch=([0-9.]+)} $line _a layerName pitch] {
                   if {[lsearch $defGridSpec $layerName] > -1} continue
                   lappend defGridSpec $layerName
                   set layerSpec $pitch;
                   set wires [list];
                   set state WIRE
               }
               if [regexp {^VIA[\s+]} $line] {
                  lappend amdPwrGridVias [lindex $line 1]
               }
               if [regexp {^DIR[\s]+} $line] {
                   if {[lsearch $defGridDirs [lindex $line 1]] > -1} continue
                   lappend defGridDirs [lindex $line 1] 
                   lappend defGridDirs [lindex $line 2]        
               }
               if [regexp {^OPTION[\s]+} $line] {
#lappend defGridOpts [lindex $line 1]
				  lappend defGridOpts "fullBorder"	  
                  lappend defGridOpts t
               }
            }
            WIRE {
                if [regexp {ENDLAYER} $line] {
                   lappend layerSpec [lsort -unique $wires];
                      lappend defGridSpec $layerSpec                
                   set state IDLE
                }       
                if [regexp {WIRE[\s]+([a-z]+)[\s]+(.+)} $line _q purp rest] {
                    set wireSpec [list]
                    set stub [list]
                    set name ""    
                    foreach item $rest {
                        set field [split $item =];
                        switch [lindex $field 0] {
                            Wid     { set width  [expr double([lindex $field 1])] }
                            Pos     { set pos    [expr double([lindex $field 1])] }
                            Net     { set name   [lindex $field 1] }
                            PullBL  { set pullBL [expr double([lindex $field 1])] }
                            PullTR  { set pullTR [expr double([lindex $field 1])] }
                            Stub    { set sfield [split [lindex $field 1] :]
                                      set off    [expr double([lindex $sfield 0])] 
                                      set len    [expr double([lindex $sfield  1])]
                                      set spitch [expr double([lindex $sfield  2])] 
                                      set minl   [expr double([lindex $sfield  3])]
                                      set stub   [list $off $len $spitch $minl] }
                        }
                    }
                    if {"" != $name } {
                        set wireSpec [list $purp $width $pos [list pullBL $pullBL] [list pullTR $pullTR] [list name $name]];
                    } else {
                        set wireSpec [list $purp $width $pos [list pullBL $pullBL] [list pullTR $pullTR]];
                    }
                    if [llength $stub] {
                       lappend wireSpec [list stub $stub]
                    }
                    lappend wires $wireSpec
                }
            }
        }
    }
    set d [db::getAttr context.editDesign ];
    if ![llength $defGridSpec] {
        de::sendMessage "$fileName does not have layer definitions, not selected." -severity warning  ;
        return 1
    }
    array set defGridSpecArray $defGridSpec
    set sortedMetals [lsort  -command [list [namespace current]::_sortLayerByMaskNumber $d] [array names defGridSpecArray]] ;
    foreach metal $sortedMetals    {
        lappend sDefGridSpec $metal;
        lappend sDefGridSpec $defGridSpecArray($metal)
    }
    set AMDPDKgvarLibList [list defGridSpec $sDefGridSpec defGridDirs $defGridDirs defGridOpts $defGridOpts amdPwrGridVias $amdPwrGridVias];
    return 0
}


proc _formatLst {lst} {
    set glist \(
    foreach i $lst {
        set glist [format "%s \"%s\"" $glist $i];
    }
    set glist [format "%s\)" $glist];
    return [string map {"\( " "\("} $glist]
}
proc formatMap {map} {
    set glist \( ;
    foreach {m d} $map {
        set glist [format "%s \(\"%s\" \"%s\"\)" $glist $m $d];
    }
    set glist [format "%s\)" $glist];
    return [string map {"\( " "\("} $glist]
}
        
proc _formatMspec {tbl} {
    array set myArray $tbl;
    set glist \(
        
    foreach name [array names myArray] {
        set mlist [format "\(\"%s\"" $name] ;
        set mlist [format "%s %5.3f" $mlist [lindex $myArray($name) 0]];
        set wlist [list];
        if ![llength [lindex $myArray($name) 1]] {
            set mlist [format "%s %s" $mlist nil]
        } else {
            set mlist [format "%s %s" $mlist \( ] 
            foreach wire [lindex $myArray($name) 1] {
                set stub [list]
                set net ""       
                foreach item $wire {
                    switch [lindex $item 0] {
                        name {set net [lindex $item 1]}
                        pullTR {set pullTR [lindex $item 1]}
                        pullBL {set pullBL [lindex $item 1]}
                        stub {set stub [lindex $item 1]}
                    }
                }
                set mlist [format "%s \(\"%s\" %s %s \(\"pullTR\" %s\) \(\"pullBL\" %s\)" $mlist  [lindex $wire 0] [lindex $wire 1] [lindex $wire 2] $pullTR  $pullBL];
                if {"" != $net} {
                    set mlist [format "%s \(\"name\" \"%s\"\)" $mlist $net]
                }
                if [llength $stub] {
                    set mlist [format "%s \(\"stub\" \(\%s\)\)\)" $mlist $stub]
                } else { 
                    set mlist [format "%s\)" $mlist]
                }
                        
            }
            set mlist [format "%s\)" $mlist]
        }
        set mlist [format "%s\)" $mlist]
        set glist [format "%s %s" $glist $mlist]
    }
    
    set glist [string map {"\( \(" "\(\("} [format "%s%s" $glist \)]];
    return $glist
        
}
proc _setAppValue {app param str} {
    upvar $app arr;
    set byte [oa::ByteArray]
    for { set j 0 } { $j < [string bytelength $str] } {incr j} {
        scan [string index $str $j] %c ascii
        oa::append $byte $ascii
    }
    set p [oa::Param $param ILList [oa::getSize $byte] $byte ]
    oa::append $arr $p
}

}    

namespace eval ::amd::drawPDKLePwrGrid {

proc init {self context {args ""}} {
   if {"maskLayout" != [db::getAttr context.editDesign.viewType]} {
       error "Can only drawing power grid in a layout view"
   }
   set win [db::getAttr context.window]
     array set PdkEnv $::amd::PdkEnv
   de::deselectAll $context
   if ![info exists  amd::AMDPDKgvarLibList] {
       set defTemplatePath [db::getPrefValue amdPwrGrdDefTemplateFile] ;
       if [file exists $defTemplatePath] {
          set missingTemplateFile [::amd::_parsPwrGrdTemplate $context $defTemplatePath] 
       } else {
          set missingTemplateFile 1
       }
       if $missingTemplateFile {
           set readFile [gi::prompt "$defTemplatePath template file doesn't exist or has incorrect data.\nDo you want to load another template file?" \
               -buttons {Yes No} -icon question -parent $win -title "Read template file failed"];
           if {"Yes" == $readFile} {
              if [amd::_amdPwrGridTemplate $win $context] {
                  error "Incorrect template file" 
              }
           } else {
              error "Template file is not selected" 
           }
       }
   } 
               
    if [info exists  amd::AMDPDKgvarLibList] {
        array set  AMDPDKgvarLibArray  $amd::AMDPDKgvarLibList ; 
    } else {
        array set  AMDPDKgvarLibArray [list];
    }
    if [info exists AMDPDKgvarLibArray(defGridSpec)] {
        set defGridSpecList $AMDPDKgvarLibArray(defGridSpec);
    } else {
        set defGridSpecList [list]
    }
    set AMDPDKgvarLibArray(metals) [list]
    if [info exists AMDPDKgvarLibArray(defGridSpec)] {
        foreach {metal def} $AMDPDKgvarLibArray(defGridSpec) {
            lappend AMDPDKgvarLibArray(metals) $metal
        }
    } else {
        set AMDPDKgvarLibArray(metals) $PdkEnv(pwrgridMetals);
    }
    array set defGridDirArray $PdkEnv(metalRoutingDirections);
    if [info exists AMDPDKgvarLibArray(defGridDirs)] {
        array set replacementArray $AMDPDKgvarLibArray(defGridDirs)
        foreach metal [array names defGridDirArray] {
            if [info exists replacementArray($metal)] { 
                set defGridDirArray($metal) $replacementArray($metal)
            }    
        }
    }
    set AMDPDKgvarLibArray(defGridDirs)    [array get defGridDirArray]
    foreach metal $AMDPDKgvarLibArray(metals) {
        if [info exists defGridDirsArray($metal)] {
           set AMDPDKgvarLibArray([join [list PG $metal _dir]]) $defGridDirsArray($metal);
        } else {
           set AMDPDKgvarLibArray([join [list PG $metal _dir]]) horisontal
        }
        set AMDPDKgvarLibArray([join [list PG $metal _viastyle]]) 2x2
    }
#    if [info exists AMDPDKgvarLibArray(amdPwrGridVias)] {
        set AMDPDKgvarLibArray(amdPwrGridVias)  $PdkEnv(pwrgridVias)
#    } 
    if ![info exists AMDPDKgvarLibArray(defGridOpts)] {
        set AMDPDKgvarLibArray(defGridOpts) nil
    }
        
        
    db::setAttr self.engine -value \
        [de::createShapeEngine \
        -shapeType rectangle \
        -pointsChangedProc [list [namespace current]::shapeModify $self] \
        -completeProc [list [namespace current]::amdPDKLePwrGridDraw $self $context]];
    set prompt "Click origin point of power grid cell";
    db::setAttr self.prompt -value $prompt;
    set AMDPDKgvarLibArray(defGridSpec) $defGridSpecList
    db::setAttr self.clientData -value [array get AMDPDKgvarLibArray];
}
proc toolbarCreated {self cot} {
    set context [db::getNext [db::getAttr self.contexts]]
    set d [db::getAttr context.editDesign]    

    set cot [gi::getToolbars deCommandOptions -from [db::getAttr context.window]];
    set cots [gi::getToolbars deCommandOptions -from [db::getAttr self.contexts.window]]
    array set AMDPDKgvarLibArray [db::getAttr self.clientData];
    set metals [lsort  -command [list ::amd::_sortLayerByMaskNumber $d] $AMDPDKgvarLibArray(metals)] ;

#    set metals $AMDPDKgvarLibArray(metals);        
    set bottomMetalAct [gi::getActions bottomMetalInput -from $cots];
    set bottomMetalInput [db::getAttr bottomMetalAct.widget ];
    db::setAttr bottomMetalInput.enum -value $metals;
    db::setAttr bottomMetalInput.value -value [lindex $metals 0];
    set topMetalAct [gi::getActions topMetalInput -from $cots];
    set bottomMetalInput [db::getAttr topMetalAct.widget];
    db::setAttr bottomMetalInput.enum -value $metals;
    db::setAttr bottomMetalInput.value -value [lindex $metals end];
    set pgCreateByRowCol [gi::getActions pgCreateByRowCol -from $cot]
    set rcAction [gi::getActions pgRC* -from $cots];
    if [db::getAttr pgCreateByRowCol.widget.value] {
        db::setAttr rcAction.widget.enabled -value true
        db::setAttr self.engine -value \
            [de::createShapeEngine \
            -shapeType point \
            -pointsChangedProc [list [namespace current]::shapeModify $self] \
            -completeProc [list [namespace current]::amdPDKLePwrGridDrawRC $self $context]];
        set prompt "Click origin point of power grid cell";
        db::setAttr self.prompt -value $prompt;
    } else {
        db::setAttr rcAction.widget.enabled -value false
        db::setAttr self.engine -value \
            [de::createShapeEngine \
            -shapeType rectangle \
            -pointsChangedProc [list [namespace current]::shapeModify $self] \
            -completeProc [list [namespace current]::amdPDKLePwrGridDraw $self $context]];
            set prompt "Click origin point of power grid cell";
            db::setAttr self.prompt -value $prompt;
    }


}

proc shapeModify {self engine} { ; # Prompt on status bar 
    set prompt "Draw outline of power grid cell"
    db::setAttr self.prompt -value $prompt;
}

proc amdPDKLePwrGridDrawRC {self context engine} {
    array set PdkEnv $::amd::PdkEnv
    db::setAttr self.prompt -value "Click origin point of power grid cell"
    set value1 [db::getPrefValue     amdPwrGrdBottomMetal -scope [de::getActiveContext]];
      set value2 [db::getPrefValue     amdPwrGrdTopMetal -scope [de::getActiveContext]];
    set cot [gi::getToolbars deCommandOptions -from [db::getAttr context.window]];
    set act1 [gi::getActions topMetal -from $cot ]
    set act2 [gi::getActions topMetal -from $cot ];
    set pgRCRows     [gi::getActions pgRCRows -from $cot ];
    set pgRCCols    [gi::getActions pgRCCols -from $cot ];
    set pgRCRowPitch [gi::getActions pgRCRowPitch -from $cot ];
    set pgRCColPitch [gi::getActions pgRCColPitch -from $cot ];
    set rows [db::getAttr pgRCRows.widget.value];
    set cols [db::getAttr pgRCCols.widget.value];
    set rPitch [db::getAttr pgRCRowPitch.widget.value];
    set cPitch [db::getAttr pgRCColPitch.widget.value];
    set mList [db::getAttr act1.widget.enum];
    if {[lsearch $mList $value1] > [lsearch $mList $value2] } return
    if {![db::getAttr pgRCRowPitch.widget.valid] || ![db::getAttr pgRCColPitch.widget.valid]} return

    set design [db::getAttr context.editDesign ];
    set points [db::getAttr points -of [db::getAttr engine -of $self]];
    set lx [lindex $points 0 0];
    set by [lindex $points 0 1];
    set rx [expr $lx + $cPitch * $cols]
    set ty [expr ($by + $rPitch * $rows)]    
    set lcv [split [db::getPrefValue amdPwrGrdCellView] /]
    array set AMDPDKgvarLibArray [db::getAttr self.clientData];
    if [info exists AMDPDKgvarLibArray(defGridSpec)] {
        set gridDefSpec $AMDPDKgvarLibArray(defGridSpec);
        set ind1 [lsearch $gridDefSpec $value1];
        set ind2 [lsearch $gridDefSpec $value2];
        set gridSpec [lrange $gridDefSpec $ind1 [incr ind2]];
        set mspecs [amd::_formatMspec $gridSpec];
    } else {
        set mspecs nil
        set gridSpec [list]
        set opts nil    
    }
    set mdirections [amd::formatMap $AMDPDKgvarLibArray(defGridDirs)]
#    set metallist [amd::_formatLst $AMDPDKgvarLibArray(metals)]
    set metallist [amd::_formatLst $PdkEnv(pwrgridMetals)]    
    set stdViaList [amd::_formatLst $AMDPDKgvarLibArray(amdPwrGridVias)];
    set opts [amd::formatMap $AMDPDKgvarLibArray(defGridOpts)];
    set trans [de::startTransaction "Create Power Grid" -design [db::getAttr context.editDesign]]; 
    set inst [le::createInst -viewName [lindex $lcv 2] -cellName [lindex $lcv 1] -libName [lindex $lcv 0] \
    -design $design -origin {0 0}];


    set app [oa::ParamArray]
    amd::_setAppValue app mspecs $mspecs
    amd::_setAppValue app mdirections $mdirections
    amd::_setAppValue app stdViaList $stdViaList 
    amd::_setAppValue app metallist $metallist
    amd::_setAppValue app opts $opts           
       oa::setParams $inst $app
    db::setParamValue minx -type float -value  $lx -of $inst
    db::setParamValue miny -type float -value  $by -of $inst
    db::setParamValue maxx -type float -value  $rx -of $inst
    db::setParamValue maxy -type float -value  $ty -of $inst


    db::setParamValue enable -type string -value  toolPlaced -of $inst
    de::endTransaction $trans
    set instName [db::getAttr inst.name];
    set AMDPDKgvarLibArray(gridSpec) $gridSpec;
    set AMDPDKgvarLibArray(instName) $instName;
   de::select [db::getInsts $instName -of $design] -replace true
    db::setAttr self.clientData -value [array get AMDPDKgvarLibArray];
   after idle [namespace current]::runEdit $design $AMDPDKgvarLibArray(instName) [list $gridSpec]

}

proc runEdit {design instName gridSpec} {
     de::select [db::getInsts $instName -of $design] -replace true;
   amd::editPDKLePwrGrid -instName $instName -gridSpec $gridSpec
}


proc amdPDKLePwrGridDraw {self context engine} {
    array set PdkEnv $::amd::PdkEnv
    db::setAttr self.prompt -value "Click origin point of power grid cell"
    set value1 [db::getPrefValue     amdPwrGrdBottomMetal -scope [de::getActiveContext]];
      set value2 [db::getPrefValue     amdPwrGrdTopMetal -scope [de::getActiveContext]];
    set cot [gi::getToolbars deCommandOptions -from [db::getAttr context.window]];
    set act1 [gi::getActions topMetal -from $cot ]
    set act2 [gi::getActions topMetal -from $cot ];
    set mList [db::getAttr act1.widget.enum];
    if {[lsearch $mList $value1] > [lsearch $mList $value2] } return    
    set design [db::getAttr context.editDesign ];
    set points [db::getAttr points -of [db::getAttr engine -of $self]];
    set lcv [split [db::getPrefValue amdPwrGrdCellView] /]
    array set AMDPDKgvarLibArray [db::getAttr self.clientData];
    if [info exists AMDPDKgvarLibArray(defGridSpec)] {
        set gridDefSpec $AMDPDKgvarLibArray(defGridSpec);
        set ind1 [lsearch $gridDefSpec $value1];
        set ind2 [lsearch $gridDefSpec $value2];
        set gridSpec [lrange $gridDefSpec $ind1 [incr ind2]];
        set mspecs [amd::_formatMspec $gridSpec];
    } else {
        set mspecs nil
        set gridSpec [list]
        set opts nil    
    }
    set mdirections [amd::formatMap $AMDPDKgvarLibArray(defGridDirs)]
#    set metallist [amd::_formatLst $AMDPDKgvarLibArray(metals)]
    set metallist [amd::_formatLst $PdkEnv(pwrgridMetals)]    
    set stdViaList [amd::_formatLst $AMDPDKgvarLibArray(amdPwrGridVias)];
    set opts [amd::formatMap $AMDPDKgvarLibArray(defGridOpts)];
    set trans [de::startTransaction "Create Power Grid" -design [db::getAttr context.editDesign]]; 
    set inst [le::createInst -viewName [lindex $lcv 2] -cellName [lindex $lcv 1] -libName [lindex $lcv 0] \
    -design $design -origin {0 0}];


    set app [oa::ParamArray]
    amd::_setAppValue app mspecs $mspecs
    amd::_setAppValue app mdirections $mdirections
    amd::_setAppValue app stdViaList $stdViaList 
    amd::_setAppValue app metallist $metallist
    amd::_setAppValue app opts $opts           
       oa::setParams $inst $app
    db::setParamValue minx -type float -value [lindex $points 0 0] -of $inst
    db::setParamValue miny -type float -value  [lindex $points 1 1] -of $inst
    db::setParamValue maxx -type float -value  [lindex $points 2 0] -of $inst
    db::setParamValue maxy -type float -value  [lindex $points 0 1] -of $inst


    db::setParamValue enable -type string -value  toolPlaced -of $inst
    de::endTransaction $trans
    set instName [db::getAttr inst.name];
    set AMDPDKgvarLibArray(gridSpec) $gridSpec;
    set AMDPDKgvarLibArray(instName) $instName;
    db::setAttr self.clientData -value [array get AMDPDKgvarLibArray];
    de::select [db::getInsts $instName -of $design] -replace true
    after idle [namespace current]::runEdit $design $AMDPDKgvarLibArray(instName) [list $gridSpec]
}
      
proc _checkMetallSelected {pos widget} {
  set wName [db::getAttr widget.name];
  set cmd [de::getActiveCommand];
  set context [db::getNext [db::getAttr cmd.contexts]]
  set cot [gi::getToolbars deCommandOptions -from [db::getAttr context.window]];
  set act2 [gi::getActions -from $cot -filter {"" != %widget && "giMutexInput" == %widget.type && "$wName" != %widget.name}];
  set widget2 [db::getAttr act2.widget];
  set mList [db::getAttr widget.enum];
  set value1 [db::getPrefValue     amdPwrGrdBottomMetal -scope [de::getActiveContext]];
  set value2 [db::getPrefValue     amdPwrGrdTopMetal -scope [de::getActiveContext]];
  if {[lsearch $mList $value1] > [lsearch $mList $value2] } {
      db::setAttr widget.valid -value false;
      db::setAttr widget2.valid -value false;
  } else {
      db::setAttr widget.valid -value true;
      db::setAttr widget2.valid -value true;
  }
}

proc _selectPGCreateMethod {widget} {
    set self [de::getActiveCommand];
    if {"amd::drawPDKLePwrGrid" != [db::getAttr self.name]} return
    set context [db::getNext [db::getAttr self.contexts]];
    set bar [gi::getToolbars {deCommandOptions} -from [db::getAttr context.window]];
    set rcAction [gi::getActions pgRC* -from $bar];
    if [db::getAttr widget.value] {
        db::setAttr rcAction.widget.enabled -value true
        db::setAttr self.engine -value \
            [de::createShapeEngine \
            -shapeType point \
            -pointsChangedProc [list [namespace current]::shapeModify $self] \
            -completeProc [list [namespace current]::amdPDKLePwrGridDrawRC $self $context]];
        set prompt "Click origin point of power grid cell";
        db::setAttr self.prompt -value $prompt;
    } else {
        db::setAttr rcAction.widget.enabled -value false
        db::setAttr self.engine -value \
            [de::createShapeEngine \
            -shapeType rectangle \
            -pointsChangedProc [list [namespace current]::shapeModify $self] \
            -completeProc [list [namespace current]::amdPDKLePwrGridDraw $self $context]];
            set prompt "Click origin point of power grid cell";
            db::setAttr self.prompt -value $prompt;
    }
}
proc _validPitch {widget} {
    set value [db::getAttr widget.value]
    if {0 == $value} {
        db::setAttr widget.valid -value false
    } else {
        set cmd [de::getActiveCommand];
          set ctx [db::getNext [db::getAttr cmd.contexts]];
        set grid [db::getAttr ctx.editDesign.tech.defaultManufacturingGrid]
        db::setAttr widget.value -value [expr round($value/$grid)*$grid]
    }
}    
        
    
        
    
proc _bottomMetalInput {action} {
     return [gi::createMutexInput buttomMetal -enum {} -label "Bottom Metal" -viewType combo \
      -toolTip "Power Grid bottom metal" -prefName amdPwrGrdBottomMetal \
      -valueChangeProc [list [namespace current]::_checkMetallSelected -1]]
}

proc _topMetalInput {action} {
     return [gi::createMutexInput topMetal -enum {} -label "Top Metal" -viewType combo \
      -toolTip "Power Grid top metal" -prefName amdPwrGrdTopMetal \
      -valueChangeProc [list [namespace current]::_checkMetallSelected 1]]
}
proc _pgRowInput {action} {
    return [gi::createNumberInput pgRows -label "Rows" -prefName amdPwrGrdRows \
      -minValue 1 -maxValue 999 -valueType int -width 4]
}
proc _pgColInput {action} {
    return [gi::createNumberInput pgCols -label "Cols" -prefName amdPwrGrdCols \
      -minValue 1 -maxValue 999 -valueType int -width 4]
}
proc _pgRowPitchInput {action} {
    array set PdkEnvArray $::amd::PdkEnv
    return [gi::createNumberInput pgRowPitch -label "Pitch"  -valueType float -width 8 \
    -value [lindex $PdkEnvArray(pwrgridPitch) 0] -valueChangeProc [namespace current]::_validPitch ]
}
proc _pgColPitchInput {action} {
    array set PdkEnvArray $::amd::PdkEnv
    return [gi::createNumberInput pgColPitch -label "Pitch"  -valueType float -width 8 \
    -value [lindex $PdkEnvArray(pwrgridPitch) 1] -valueChangeProc [namespace current]::_validPitch]
}
proc _pgCreateByRowCol {action} {
    return [gi::createBooleanInput pgCreateByRowCol -valueChangeProc [namespace current]::_selectPGCreateMethod -prefName amdPwrGrdCreateMode]
}
proc _pgModeLabel {action} {
    return [gi::createLabel -label "By Row/Column"]
}    
    
proc registerCommand {} {
    de::createCommand amd::drawPDKLePwrGrid -type interactive -requiresWriteMode true \
        -description "Create Power Grid" -category layout -label "Create Power Grid" ;
    gi::createAction bottomMetalInput -widgetProc amd::drawPDKLePwrGrid::_bottomMetalInput;
    gi::createAction topMetalInput -widgetProc amd::drawPDKLePwrGrid::_topMetalInput;

    gi::createAction pgRCRows -widgetProc amd::drawPDKLePwrGrid::_pgRowInput
    gi::createAction pgRCCols -widgetProc amd::drawPDKLePwrGrid::_pgColInput 
    gi::createAction pgRCRowPitch -widgetProc amd::drawPDKLePwrGrid::_pgRowPitchInput
    gi::createAction pgRCColPitch -widgetProc amd::drawPDKLePwrGrid::_pgColPitchInput 
    gi::createAction pgModeLabel -widgetProc amd::drawPDKLePwrGrid::_pgModeLabel
    gi::createAction pgCreateByRowCol -widgetProc amd::drawPDKLePwrGrid::_pgCreateByRowCol

    gi::addActions {bottomMetalInput
                    topMetalInput 
                    giSeparator 
                    pgModeLabel
                    pgCreateByRowCol
                    giSeparator 
                    pgRCRows 
                    pgRCRowPitch
                    giSeparator
                    pgRCCols 
                    pgRCColPitch} -to [gi::getToolbars amdDrawPDKLePwrGridOptions] 
}
   
registerCommand
}




