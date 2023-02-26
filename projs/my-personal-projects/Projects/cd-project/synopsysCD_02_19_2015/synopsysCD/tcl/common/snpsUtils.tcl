# Copyright (c) 2004-2014 Synopsys, Inc. This Galaxy Custom Designer software
# and the associated documentation are confidential and proprietary to
# Synopsys, Inc. Your use or disclosure of this Galaxy Custom Designer software
# is subject to the terms and conditions of a written license agreement between
# you, or your company, and Synopsys, Inc.

namespace eval ::amd::utils {

namespace export *

proc sigNames {oaNet} {
    set netList {}
    for {set i 0} {$i<[db::getAttr numBits -of $oaNet]} {incr i} {
        set netName [db::getAttr name -of [oa::getBit $oaNet $i]]
        lappend netList $netName
    }
    return $netList
}


proc signals {oaNet} {
    set netList {}
    for {set i 0} {$i<[db::getAttr numBits -of $oaNet]} {incr i} {
        set net [oa::getBit $oaNet $i]
        lappend netList $net
    }
    return [db::createCollection $netList]
}


proc getBaseName {name } {
    set k [string first "\[" $name ]
    if { $k < 0 } {
        set k [string first "\<" $name]
        if { $k < 0 } {
            set k [string first "\(" $name]
            if { $k < 0} {
                return $name
            }
        }
    }
    return [string range $name 0 [expr $k -1]]
}


proc getIndex { name } {
    set k [string first "\[" $name ]
    if { $k < 0 } {
        set k [string first "\<" $name]
        if { $k < 0 } {
            set k [string first "\(" $name]
            if {$k < 0} {
                return -1
            }
        }
    }
    set name [string trim $name]
    return [string range $name [expr $k +1] [expr [string length $name]-2]]
}



proc logicalAND {arg1 arg2} {
    if {$arg2} {
        if {"nil"!=$arg1 && 0!=$arg1} {
            return 1
        }
    }
    return 0
}


proc logicalOR {arg1 arg2} {
    if {$arg2} {
        return 1
    }
    if {"nil"!=$arg1 && 0!=$arg1} {
            return 1
    }
    return 0
}


proc getPropValue {oaProp} {
    set propType [oa::getName [oa::getType $oaProp]]
    if { $propType == "AppProp" } {
        return [getAppPropValFromProp $oaProp]
    } else {
        return [oa::getValue $oaProp]
    }    
}


proc getAppPropValFromProp { oaProp } {
    set propValAsBA [oa::getValue $oaProp]
    set byteArraySize [expr [oa::getSize $propValAsBA]]
    return [getStringFromByteArray $propValAsBA $byteArraySize]
}


proc getStringFromByteArray { byteArray byteArraySize } {
    set byteArrayVal ""
    for {set i 0} {$i < $byteArraySize} {incr i} {
        if {0!=[format %d [oa::get $byteArray $i]]} {
            append byteArrayVal [format %c [oa::get $byteArray $i]]
        }
    }
    return $byteArrayVal
}


proc getCell {libName cellName} {
    if { [catch {set dmCell [dm::getCells $cellName -libName $libName]} ] } {
        return ""
    }
    if { [db::isEmpty $dmCell]} {
        return ""
    } else {
        return $dmCell
    }
}


proc getCellView {libName cellName viewName} {
    if { [catch {set dmCellView [dm::getCellViews $viewName \
    -cellName $cellName -libName $libName]} ] } {
        return ""
    }
    if {[db::isEmpty $dmCellView]} {
        return ""
    } else {
        return $dmCellView
    }
}
    
    
proc createCell {libName cellName {overwrite 0}} {
    oa::getAccess [oa::LibFind $libName] write 1
    set dmCell [getCell $libName $cellName]
    if {$overwrite && $dmCell!=""} {
        db::destroy $dmCell
    }
    if {$dmCell=="" || $overwrite} {
        set dmCell [dm::createCell $cellName -libName $libName]
    }
    oa::releaseAccess [oa::LibFind $libName]
    return $dmCell
}


proc createCellView {libName cellName viewName viewType {overwrite 0}} {
    createCell $libName $cellName
    oa::getAccess [oa::LibFind $libName] write 1
    set dmCellView [getCellView $libName $cellName $viewName]
    if {$overwrite && $dmCellView!=""} {
        db::destroy $dmCellView
    }
    if {$dmCellView=="" || $overwrite} {
        set dmCellView [dm::createCellView $viewName \
        -cell [dm::getCells $cellName -libName $libName] -viewType $viewType]
    }
    oa::releaseAccess [oa::LibFind $libName]
    return $dmCellView
} 


proc car {inputList} {
    return [lindex $inputList 0]
}


proc cdr {inputList} {
    return [lrange $inputList 1 end]
}


proc cadr {inputList} {
    return [car [cdr $inputList]]
}

proc caar {inputList} {
    return [car [car $inputList]]
}


proc cdar {inputList} {
    return [cdr [car $inputList]]
}


proc cddr {inputList} {
    return [cdr [cdr $inputList]]
}


proc caadr {inputList} {
    return [car [car [cdr $inputList]]]
}


proc cdadr {inputList} {
    return [cdr [car [cdr $inputList]]]
}


proc cadar {inputList} {
    return [car [cdr [car $inputList]]]
}

proc cadadr {inputList} {
    return [car [cdr [car [cdr $inputList]]]]
}

proc cons {elem inputList} {
    return [linsert $inputList 0 $elem]
}

proc caddr {inputList} {
    return [car [cdr [cdr $inputList]]]
}

proc cadddr {inputList} {
    return [car [cdr [cdr [cdr $inputList]]]]
}


proc reverse {inputList} {
    set r {}
    set i [llength $inputList]

    while {$i} {lappend r [lindex $inputList [incr i -1]]}
    return $r
}


proc box2oaBox {bBox} {
    return [oa::Box [lindex $bBox 0 0] [lindex $bBox 0 1] [lindex $bBox 1 0] [lindex $bBox 1 1]]
}


proc centerBox {bBox} {
    return [oa::getCenter [box2oaBox $bBox]]
}


proc lowerLeft {bBox} {
    return [lindex $bBox 0]
}

proc upperRight {bBox} {
    return [lindex $bBox 1]
}

proc leftEdge {bBox} {
    return [lindex $bBox 0 0]
}

proc bottomEdge {bBox} {
    return [lindex $bBox 0 1]
}

proc rightEdge {bBox} {
    return [lindex $bBox 1 0]
}

proc topEdge {bBox} {
    return [lindex $bBox 1 1]
}


proc dbTransformBBox {bBox transList} {
    if {[llength $transList] == 2} {
        set offset [oa::Point [caar $transList] [cdar $transList]]
        set trans [oa::Transform $offset [oa::Orient [cadr $transList]]]
    } else {
        set trans $transList
    }
    return [oa::transform [box2oaBox $bBox] $trans]    
}

proc dbTransformPoint {point transList} {
    if {[llength $transList] == 2} {
        set offset [oa::Point [caar $transList] [cdar $transList]]
        set trans [oa::Transform $offset [oa::Orient [cadr $transList]]]
    } else {
        set trans $transList
    }
#    set pa [oa::PointArray]
#    oa::append $pa [oa::Point [car $point] [cdr $point]]
    set dp [oa::DoublePoint [car $point] [cdr $point]]

    return [oa::transform $dp $trans] 
}

proc transformPoint {point transList} {
    if {[llength $transList] == 2} {
        set offset [oa::Point [caar $transList] [cdar $transList]]
        set trans [oa::Transform $offset [oa::Orient [cadr $transList]]]
    } else {
        set trans $transList
    }
    return [oa::transform [oa::Point [lindex $point 0] [lindex $point 1]] $trans]    
}


proc dbConcatTransform {transform1 transform2} {
    set trans [oa::concat $transform1 $transform2]
    set orient [oa::getName [oa::orient $trans]]
    return [list [list [oa::xOffset $trans] [oa::yOffset $trans]] $orient]
}


proc max {args} {
    set m [lindex $args 0]
    for {set i 1} {$i < [llength $args]} {incr i} {
        set n [lindex $args $i]
        if {$n > $m} {
            set m $n
        }
    }
    return $m
}


proc min {args} {
    set m [lindex $args 0]
    for {set i 1} {$i < [llength $args]} {incr i} {
        set n [lindex $args $i]
        set m [expr $n > $m ? $m : $n]
    }
    return $m
}


proc getCurrentTime {} {
    set systemTime [clock seconds]
    return [clock format $systemTime -format "%b %d %H:%M:%S %Y"]      
}


proc timeToString {t} {
    return [clock format $t -format "%b %d %H:%M:%S %Y"]      
}

proc compareTime {t1 t2} {
    set t1sec [clock scan $t1]
    set t2sec [clock scan $t2]
    return [expr $t1sec - $t2sec]
}



proc dbGetDatabaseType {} {
    return "OpenAccess"
}


proc getInstBBox {oaInst} {
    set bBox [db::getAttr bBox -of $oaInst]
    
    set isBound [oa::isBound $oaInst]
    if {$isBound} {
        set master [db::getAttr master -of $oaInst]        
        set shapes [db::getShapes -of $master -filter { %layerNum == 236 && %purposeNum == -1}]
        set firtsIteration 1
        db::foreach a $shapes {
            set selectionShapeBBox [db::getAttr bBox -of $a]
            if {$firtsIteration} {    
                set firtsIteration 0
                set tOABox [box2oaBox $selectionShapeBBox]
            } else {
                set sOABox [box2oaBox $selectionShapeBBox]
                set bBox [oa::merge $sOABox $tOABox]
                set tOABox [box2oaBox $bBox]
            }
        }    
        set oaTransform [db::getAttr transform -of $oaInst]   
        set bBox [oa::transform $tOABox $oaTransform]
        return $bBox            
    }    
    
    return $bBox
}


proc replaceProp {oaObj propName propValue {propType "string"}} {
    set oaProp [oa::PropFind $oaObj $propName]
    if {""!=$oaProp} {
        db::destroy $oaProp
    }
    createProp $oaObj $propName $propValue $propType
}


proc createProp {oaObj propName propValue {propType "string"}} {
    switch -exact -- $propType  {
        "string" { oa::StringPropCreate $oaObj $propName $propValue }
        "int"    -
        "integer"    { oa::IntPropCreate $oaObj $propName $propValue }
        "double" { oa::DoublePropCreate $oaObj $propName $propValue }
        "float"  { oa::FloatPropCreate $oaObj $propName $propValue }
        default  {
            set oaByteArray [oa::ByteArray]
            for {set i 0} {$i<[string length $propValue]} {incr i} {
                set char [string index $propValue $i]
                scan $char %c ascii
                oa::append $oaByteArray $ascii
            }
            oa::AppPropCreate $oaObj $propName $propType $oaByteArray        
        }
    }    
}


proc openDesign {args} {
    if {[llength $args]<=2} {
        set lcv [split [lindex $args 0] "/"]
        set libName [lindex $lcv 0]
        set cellName [lindex $lcv 1]
        set viewName [lindex $lcv 2]
        
        set mode [lindex $args 1]
        if {""==$mode} {
            set mode r
        }
    } else {
        set libName [lindex $args 0]
        set cellName [lindex $args 1]
        set viewName [lindex $args 2]
        
        set mode [lindex $args 4]
        if {""==$mode} {
            set mode r
        }        
    }
    set oaDes [oa::DesignFind $libName $cellName $viewName]
    if {"" == $oaDes} {
        set oaDes [oa::DesignOpen $libName $cellName $viewName $mode]
    }
    return $oaDes
}


proc getLayerName {layerNum oaDesign} {
    set libName     [db::getAttr libName -of $oaDesign]
    set oaTech      [oa::TechFind $libName] 
    set oaLayer     [oa::LayerFind $oaTech $layerNum]
    if {""!=$oaLayer} {
        return [oa::getName $oaLayer]
    } else {
        return ""
    }     
}


proc getShapeLayerNameLPP {oaShape} {
    return [lindex [db::getAttr LPP.lpp -of $oaShape] 0]
}


proc getShapesLayerNames {shapes} {
    set names [list]
    db::foreach shape $shapes {
        lappend names [getShapeLayerName $shape]
    }
    return $names
}


proc getLayerNumber {layerName oaDesign} {
    set libName     [db::getAttr libName -of $oaDesign]
    set oaTech      [oa::TechFind $libName] 
    set oaLayer     [oa::LayerFind $oaTech $layerName]
    if {""!=$oaLayer} {
        return [oa::getNumber $oaLayer]
    } else {
        return ""
    }    
}


proc getPurposeName {purposeNum oaDesign} {
    set libName     [db::getAttr libName -of $oaDesign]
    set oaTech      [oa::TechFind $libName]
    set oaPurpose   [oa::PurposeFind $oaTech $purposeNum]
    if {""!=$oaPurpose} {
        return [oa::getName $oaPurpose]
    } else {
        return ""
    }
}


proc getPurposeNumber {purposeName oaDesign} {
    set libName     [db::getAttr libName -of $oaDesign]
    set oaTech      [oa::TechFind $libName]
    set oaPurpose   [oa::PurposeFind $oaTech $purposeName]
    if {""!=$oaPurpose} {
        return [oa::getNumber $oaPurpose]
    } else {
        return ""
    }
}   


proc getShapeLayerName {oaShape} {
    set layerNum [db::getAttr layerNum -of $oaShape]
    set oaDes [db::getAttr design -of $oaShape]
    return [getLayerName $layerNum $oaDes]
}


proc getShapePurposeName {oaShape} {
    set purposeNum [db::getAttr purposeNum -of $oaShape]
    set oaDes [db::getAttr design -of $oaShape]
    return [getPurposeName $purposeNum $oaDes]
}


proc isValidLPP { layerName purposeName oaDes } {
    set r1 [getLayerNumber $layerName $oaDes]
    set r2 [getPurposeNumber $purposeName $oaDes]
    if {""!=$r1 && ""!=$r2} {
        return 1
    } else {
        return 0
    }
}


proc getParentDialog { widget } {
    if {"" == $widget} {
        return ""
    }
    if {"giDialog" == [db::getAttr type -of $widget]} {
        return $widget
    }
    while {"" != [set widget [db::getAttr parent -of $widget]]} {
        if {"giDialog" == [db::getAttr type -of $widget]} {
            return $widget
        }
    }
    return ""
}


proc getParentWindow { widget } {
    if {"" == $widget} {
        return ""
    }
    if {"giWindow" == [db::getAttr type -of $widget]} {
        return $widget
    }
    while {"" != [set widget [db::getAttr parent -of $widget]]} {
        if {"giWindow" == [db::getAttr type -of $widget]} {
            return $widget
        }
    }
    return ""
}


proc assoc {key lst} {
    return [findElement $key $lst 0]
}


proc findElement {key lst idx} {
    set i 0
    foreach sublist $lst {
        if {[string equal [lindex $sublist $idx] $key]} {
            return $sublist
        }
        incr i
    }
    return ""
}


proc putprop {symbol value property} {
    if {-1==[lsearch [db::listAttrs -of $symbol] $property]} {
        #db::addAttr $property -of $symbol -value $value
        db::addAttr $property -of $symbol -value [db::createObject]
    }
    set obj [db::getAttr $property -of $symbol]
    if {""==$value} {
        db::setAttr $property -of $symbol -value [db::createObject]
    }
    db::addAttr value -of $obj -value $value
    #db::setAttr $property -of $symbol -value $value
}


proc get {symbol property} {
    if {![catch {db::getAttr type -of $symbol}]} {
        if {![catch {db::getAttr $property -of $symbol} result]} {
            return $result
        }
    } else {
        set index [lsearch $symbol $property]
        if {-1!=$index && ![expr [llength $symbol]%2]} {
            return [lindex $symbol [expr $index + 1]]
        }
    }
    return ""
}


proc null {val} {
    if {""==$val || "nil" == $val} {
        return 1
    }
    return 0
}


proc member {value inputList} {
    return [expr [lsearch $inputList $value]>-1 ? 1 : 0]
}


proc remove_old {value inputList} {
    set idx [lsearch $inputList $value]
    set inputList [lreplace $inputList $idx $idx]    
    return $inputList
}


proc remove {args} {
    if {[llength $args] < 2} {
        puts stderr {Wrong # args: should be "lremove ?-all? list pattern"}
    }
    set element [lindex $args end-1]
    set inputList [lindex $args end]     
    if [string match -all [lindex $args 0]] {
        set inputList [lsearch -all -inline -not -exact $inputList $element]
    } else {
        set idx [lsearch $inputList $element]
        set inputList [lreplace $inputList $idx $idx]
    }
    return $inputList
}


proc luniq {inputList} {
    # removes duplicates without sorting the input list
    set t [list]
    foreach i $inputList {if {[lsearch -exact $t $i]==-1} {lappend t $i}}
    return $t
}


proc getMaxLength {inputList} {
    set maxL 0
    foreach item $inputList {
        set l [string length $item]
        if {$l>$maxL} {
            set maxL $l
        }
    }
    return $maxL
}


proc hiCloseWindow {w} {
    db::destroy [gi::getWindows $w]
}


proc allignWidgetsTable {fields parent} {
    array set columns {}
    foreach row $fields {
        set rightW [lindex $row 0]
        lappend columns(0) [db::getAttr name -of $rightW]
        for {set i 1} {$i<[llength $row]} {incr i} {
            if {""!=[lindex $row $i]} {
                gi::layout [lindex $row $i] -rightOf $rightW -equalWidth 0 
                set rightW [lindex $row $i]
                lappend columns($i) [db::getAttr name -of [lindex $row $i]]
            }
        }
    }
    foreach key [array name columns] {
        set column $columns($key)
        set firstWidget [gi::findChild [lindex $column 0] -in $parent]
        for {set i 1} {$i<[llength $column]} {incr i} {
            gi::layout [gi::findChild [lindex $column $i] -in $parent] -align $firstWidget
        }
    }        
}


proc makeTempFileName {prefix {suffix ""}} {
    set chars "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    set nrand_chars 10
    set maxtries 10
    set access [list RDWR CREAT EXCL TRUNC]
    set permission 0600
    set channel ""
    set checked_dir_writable 0
    set mypid [pid]
    for {set i 0} {$i < $maxtries} {incr i} {
        set newname $prefix
        for {set j 0} {$j < $nrand_chars} {incr j} {
            append newname [string index $chars \
                    [expr ([clock clicks] ^ $mypid) % 62]]
        }
        append newname $suffix
        if {[file exists $newname]} {
            after 1
        } else {
            if {[catch {open $newname $access $permission} channel]} {
                if {!$checked_dir_writable} {
                    set dirname [file dirname $newname]
                    if {![file writable $dirname]} {
                        error "Directory $dirname is not writable"
                    }
                    set checked_dir_writable 1
                }
            } else {
                # Success
                close $channel
                return $newname
            }
        }
    }
    if {[string compare $channel ""]} {
        error "Failed to open a temporary file: $chanel"
    } else {
        error "Failed to find an unused temporary file name"
    }
}


proc getLogin {} {
    return $::tcl_platform(user)
}


proc getDirFiles {dirName} {
    set files [glob -directory $dirName -nocomplain *]
    set files [concat $files [glob -types {hidden} -directory $dirName -nocomplain *]]
    return $files
}


proc createConfigTemplate {name viewSearchLis viewStopList} {
    set tmpFile [makeTempFileName "/tmp/configtemplate"]
    set ff [open $tmpFile "w"]
    puts $ff "<config version=\"1\" >"
    puts $ff "<stop_list>$viewStopList</stop_list>"
    puts $ff "<view_search_list>$viewSearchLis</view_search_list>"
    puts $ff "</config>"
    close $ff
    he::createConfigTemplate $name -filePath $tmpFile 
}


proc xCoord {p} {
    return [lindex $p 0]
}


proc yCoord {p} {
    return [lindex $p 1]
}


proc attachObjectToGroup {lead obj} {
    set oaGroups [db::getAttr groupMems.group -of $lead]
    set oaGroup [db::getNext [db::filter $oaGroups -filter {%name=="__CDBA_PARENTCHILD_ONLY_GROUP"}]]
    set oaDes [db::getAttr design -of $lead]
    if {""!=$oaGroup} {
        oa::GroupMemberCreate $oaGroup $obj
    } else {
        set oaGroup [oa::GroupCreate $oaDes __CDBA_PARENTCHILD_ONLY_GROUP [oa::GroupType set] 0 0 [oa::GroupDeleteWhen onLast]]
        oa::GroupMemberCreate $oaGroup $lead 1
        oa::GroupMemberCreate $oaGroup $obj    
    }
} 


proc getGroupMembers {obj} {
    set oaGroups [db::getAttr groupMems.group -of $obj]
    set oaGroup [db::getNext [db::filter $oaGroups -filter {%name=="__CDBA_PARENTCHILD_ONLY_GROUP"}]]
    if {""!=$oaGroup} {
        return [db::getAttr members.object -of $oaGroup]
    }
    return ""    
}


proc detachObjectsFromGroup {lead} {
    set objL {}
    set oaGroups [db::getAttr groupMems.group -of $lead]
    set oaGroup [db::getNext [db::filter $oaGroups -filter {%name=="__CDBA_PARENTCHILD_ONLY_GROUP"}]]
    if {""!=$oaGroup} {
        if {[db::getAttr leader.object -of $oaGroup]==$lead} {
            db::foreach m [db::getAttr members -of $oaGroup] {
                if {![oa::isLeader $m]} {
                    set obj [db::getAttr object -of $m]
                    lappend objL $obj
                    oa::destroy $m
                }
            }
        }
    }
    if {![llength $objL]} {
        return $objL
    }
    return [db::createCollection $objL]
}


proc attachObjectsToGroup {lead objects} {
    if {""==$objects} {
        return 
    }
    set oaGroups [db::getAttr groupMems.group -of $lead]
    set oaGroup [db::getNext [db::filter $oaGroups -filter {%name=="__CDBA_PARENTCHILD_ONLY_GROUP"}]]
    set oaDes [db::getAttr design -of $lead]
    if {""==$oaGroup} {
        set oaGroup [oa::GroupCreate $oaDes __CDBA_PARENTCHILD_ONLY_GROUP [oa::GroupType set] 0 0 [oa::GroupDeleteWhen onLast]]
        oa::GroupMemberCreate $oaGroup $lead 1
    }
    db::foreach obj $objects {
        oa::GroupMemberCreate $oaGroup $obj 
    }
}


proc findDesign {refId} {
    if {[db::isObject $refId] && "Design"==[db::getAttr type -of $refId]} {
        set oaDes $refId
    } else {
        set winId $refId
        if {""==$winId} {
            set winId [db::getAttr id -of [de::getActiveEditorWindow]]
        }
        set oaDes [db::getAttr editDesign -of [de::getContexts -window $winId]]
    }
    return $oaDes
}

# Usage of setof procedure:
#    set m1 [setof $shapes {%LPP.lpp=="M1 drawing" || %LPP.lpp=="M2 drawing"}]
#    set a  [setof $coll {[member %name [lll]]}]
proc setof {coll predicate} {
    return [db::filter $coll -filter "$predicate"]
}


proc dbCreateFigGroup {oaDes unknownArg1 unknownArg2 origin orient} {
    set figGroup [oa::FigGroupCreate [oa::getTopBlock $oaDes]]
    oa::setOrigin $figGroup [oa::Point [split $origin :]]
    oa::setOrient $figGroup [oa::Orient $orient]
    return $figGroup
}


proc dbCreatePin {oaNet shape} {
    set term [le::createTerm -net $oaNet]
    le::createPin -term $term -shapes $shape
}

proc dbCopyFig {srcFig oaDes l_transform} {
    set origin [lindex $l_transform 0]
    set orient [lindex $l_transform 1]
    le::copy $srcFig  -anchor $origin -rotate $orient -dest $oaDes
}


proc techGetTechFile {obj} {
    if {[db::isObject $obj] && "Design"==[db::getAttr type -of $obj]} {
        return [db::getAttr tech -of $obj]
    }
    set oaTech [oa::TechFind $obj]
    if {""==$oaTech} {
        if {[catch {set oaTech [oa::TechOpen $obj "r"]}]} {
            error "The reference library $obj not found. Can't read tech data."
        }
    }
    return $oaTech
}

#Valid Values for layer: the layer name, the layer number, a list containing
#the layer name and purpose
proc techGetSpacingRule {oaTech rule layer} {
    set layerName [lindex $layer 0]
    if {[string is double $layerName]} { 
        set layerNum $layer
    } else {
        set layerNum [oa::getNumber [oa::LayerFind $oaTech $layerName]]
    }
    set dbuPerUU [oa::getDBUPerUU $oaTech [oa::ViewTypeGet maskLayout]]
    set oaCG [oa::ConstraintGroupFind $oaTech foundry]
    set oaLCD [oa::LayerConstraintDefGet minWidth]
    set oaLC [oa::LayerConstraintFind $oaCG $layerNum $oaLCD]
    set minWidth [expr [oa::get [db::getAttr value -of $oaLC]]/double($dbuPerUU)]
    return $minWidth
}

proc techGetParam {oaTech param} {
    set techParamsGroup [oa::getGroupsByName $oaTech techParams]
    if {""==$techParamsGroup} {return ""}
    if {![catch {set val [db::getAttr $param -of $techParamsGroup] }]} {
        return $val
    } else {
        return ""
    }
}

proc leGetValidLayerList {{oaTech ""}} {
    if {![catch {set oaDes [ed]}]} {
        if {"maskLayout"==[db::getAttr viewType -of $oaDes]} {
            return [db::createList [db::getAttr lpp -of [de::getLPPs -from $oaDes -filter {%valid}]]]
        }
    }
    db::foreach oaDes [oa::DesignGetOpenDesigns] {
        if {![catch {set lppList [db::createList [db::getAttr lpp -of [de::getLPPs -from $oaDes -filter {%valid}]]]}]} {
            return $lppList
        }
    }
    return ""
}


proc getLEWindows {} {
    if {[db::getPrefValue amdLeAMDLSWApllyActiveDesignOnly]} {
        if {![catch {set ctx [de::getActiveContext]}]} {
            if {"leLayout"==[db::getAttr window.windowType.name -of $ctx]} {
                return [db::createCollection [db::getAttr window -of $ctx]]
            }
        }
        return [gi::getWindows -filter {%windowType.name=="dummyWT"}]
    } else {
        return [gi::getWindows -filter {%windowType.name=="leLayout"}]
    }
}


proc applyOLPGroup {olpGr} {
    db::foreach w [getLEWindows] {
        set ctx [de::getContexts -window $w]
        de::applyOLPGroup $olpGr -to $ctx
    }
}

proc leSetOLPGroupAllLayerVisible {val olpGr} {
    db::foreach lpp [de::getLPPs -from $olpGr] {
        if {$val} {
            db::setAttr selectable -of $lpp -value 1
        } else {
            db::setAttr visible -of $lpp -value 0
        }
    }
}

proc leSetAllLayerVisible {val} {
    #db::foreach w [getLEWindows] {
    #    set ctx [de::getContexts -window $w]
    #    set activeLPP [db::getAttr lpp -of [de::getActiveLPP -design $ctx]]
    #    db::setAttr visible -of [de::getLPPs -from $ctx -filter {%lpp!=$activeLPP && %visible!=$val}] -value $val
    #}
    #return
    db::foreach w [getLEWindows] {
        set ctx [de::getContexts -window $w]
        set activeLPP [db::getAttr lpp -of [de::getActiveLPP -design $ctx]]
        set a [gi::getAssistants leObjectLayerPanel -from $w]
        set activeTab [gi::getActiveTab {tabs} -in $a]
        gi::setActiveTab {tabs} -tabName {OLPLPPTab} -in $a
        if {$val} {
            if {[db::getPrefValue amdLeAMDLSWMakeLPPsInvalid]} {
                gi::executeAction leOLPApplyGroupDesignLPPs -in $a
            } else {
                gi::executeAction leOLPSetAllSelectable -in $a            
            }
        } else {
            if {[db::getPrefValue amdLeAMDLSWMakeLPPsInvalid]} {
                #gi::executeAction leOLPApplyGroupDesignLPPs -in $a
                db::setAttr valid -of [de::getLPPs -from $ctx -filter {%lpp!=$activeLPP && %valid==1}] -value 0
            } else {
                gi::executeAction leOLPSetAllInvisible -in $a
            }
        }
        gi::setActiveTab {tabs} -tabName $activeTab -in $a
    }    
}


proc leSetAllLayerSelectable {val} {
    #db::foreach w [getLEWindows] {
        #set ctx [de::getContexts -window $w]
        #db::setAttr selectable -of [de::getLPPs -from $ctx -filter {%selectable!=$val}] -value $val
    #}
    #return
    db::foreach w [getLEWindows] {
        set a [gi::getAssistants leObjectLayerPanel -from $w]
        set activeTab [gi::getActiveTab {tabs} -in $a]
        gi::setActiveTab {tabs} -tabName {OLPLPPTab} -in $a
        if {$val} {
            gi::executeAction leOLPSetAllSelectable -in $a
        } else {
            gi::executeAction leOLPSetAllUnselectable -in $a
        }
        gi::setActiveTab {tabs} -tabName $activeTab -in $a
    }    
}

    
proc leSetEntryLayer {lpp} {
    set lpp [string map {\" ""} $lpp] 
    if {""!=$lpp} {
        db::foreach w [getLEWindows] {
            set ctx [de::getContexts -window $w]
            set deLPP [db::getNext [de::getLPPs $lpp -from $ctx]]
            if {""!=$deLPP} {
                de::setActiveLPP $deLPP
            }
        }        
    }
}


proc leGetEntryLayer {} {
    db::foreach w [getLEWindows] {
        set ctx [de::getContexts -window $w]
        return [db::getAttr lpp -of [de::getActiveLPP -design $ctx]]
    } 
    return ""
}

proc leIsLayerVisible {lpp} {
    set lpp [string map {\" ""} $lpp]  
    db::foreach w [getLEWindows] {
        set ctx [de::getContexts -window $w]
        set deLPP [db::getNext [de::getLPPs $lpp -from $ctx]]
        if {""!=$deLPP} {
            return [db::getAttr visible -of $deLPP]
        }
    }
    return 0
}


proc leGetVisibleLPPs {} {
    set w [db::getNext [getLEWindows]]
    if {""!=$w} {
        set ctx [de::getContexts -window $w]
        return [db::createList [db::getAttr lpp -of [de::getLPPs -from $ctx -filter {%visible}]]]
    }
    return {}
}

proc leIsLayerSelectable {lpp} {
    db::foreach w [getLEWindows] {
        set ctx [de::getContexts -window $w]
        set deLPP [db::getNext [de::getLPPs $lpp -from $ctx]]
        if {""!=$deLPP} {
            return [db::getAttr selectable -of $deLPP]
        }
    }
    return 0
}

proc deFindContext {oaDes} {
    set ctx ""
    db::foreach context [de::getContexts] {
        if { [set window [db::getAttr window -of $context]] == "" } continue
        if { [db::getAttr context.editDesign.libName] != [db::getAttr oaDes.libName] } continue
        if { [db::getAttr context.editDesign.cellName] != [db::getAttr oaDes.cellName] } continue
        if { [db::getAttr context.editDesign.viewName] != [db::getAttr oaDes.viewName] } continue
        set ctx $context
    }
    return $ctx
}


proc leGetSelectableLPPs {} {
    set w [db::getNext [getLEWindows]]
    if {""!=$w} {
        set ctx [de::getContexts -window $w]
        return [db::createList [db::getAttr lpp -of [de::getLPPs -from $ctx -filter {%selectable}]]]
    }
    return {}
}

proc leSetLayerVisible {lpp val} {
    db::foreach w [getLEWindows] {
        set ctx [de::getContexts -window $w]
        set deLPP [db::getNext [de::getLPPs $lpp -from $ctx]]
        set activeLPP [db::getAttr lpp -of [de::getActiveLPP -design $ctx]]
        if {""!=$deLPP} {
            if {[db::getPrefValue amdLeAMDLSWMakeLPPsInvalid]} {
                if {[db::getAttr valid -of $deLPP]!=$val && $activeLPP!=$lpp} {
                    db::setAttr valid -of $deLPP -value $val
                }
            } else {
                if {$val && ![db::getAttr selectable -of $deLPP]} {
                    db::setAttr selectable -of $deLPP -value $val
                } elseif {$activeLPP!=[db::getAttr lpp -of $deLPP] && [db::getAttr visible -of $deLPP]!=$val} {
                    db::setAttr visible -of $deLPP -value $val
                }
            }
        }
    }
}


proc leSetLayerSelectable {lpp val} {
    db::foreach w [getLEWindows] {
        set ctx [de::getContexts -window $w]
        set deLPP [db::getNext [de::getLPPs $lpp -from $ctx]]
        if {""!=$deLPP} {
            db::setAttr selectable -of $deLPP -value $val
        }
    }
}


proc leSetObjectVisible {filterName val} {
    db::setAttr visible -of [de::getObjectFilters $filterName] -value $val
    db::foreach w [getLEWindows] {
        set ctx [de::getContexts -window $w]
        db::setAttr visible -of [de::getObjectFilters $filterName -from $ctx] -value $val
    }    
}


proc alphaNumCmp {arg1 arg2 {exp 0}} {
    if {$exp && [string is double $arg1] && [string is double $arg2]} {
        if {$arg1>$arg2} {
            return 1
        } elseif {$arg1<$arg2} {
            return -1
        } else {
            return 0
        }
    } else {
        return [string compare $arg1 $arg2]
    }
}

proc alphalessp {str1 str2} {
    set val [string compare $str1 $str2]
    if {$val==-1} {
        return true
    } else {
        return false
    }
}

proc getPinFigsFromShape {pinShape design} {
    if {[db::getAttr pinShape.pin]==""} {
        return 
    }
    set netName [db::getAttr pinShape.pin.term.net.name]
    set pins [db::getPins -of $design -filter {%this.term.net.name==$netName}]
    set pinFigs [list]
    db::foreach pin $pins {
        set figs [db::getAttr pin.figs]
        db::foreach fig $figs {
            lappend pinFigs $fig
        }
    }
    return [db::createCollection $pinFigs]
}


proc getTermPinsFigs {instTerm design} {
    set pins [db::getAttr instTerm.term.pins]
    set figs [list]
    db::foreach pin $pins {
        db::foreach f [db::getAttr pin.figs] {
            lappend figs $f
        }
    }
    if {[llength $figs]!=0} {
        return [db::createCollection $figs]
    } else {
        return ""
    }
}


proc dbDestroyMarkers {markers} {
    db::foreach m $markers {
        db::destroy $m
    }
}

proc giGetDynamicListSelectedItems {w} {
    set res {}
    set value [db::getAttr value -of $w]
    set selection [lsort -integer [db::getAttr selection -of $w]]
    foreach index $selection {
        lappend res [lindex $value $index]
    }
    return $res
}


proc giSetDynamicListValue {w val} {
    db::setAttr readOnly -of $w -value false
    db::setAttr value -of $w -value $val
    db::setAttr readOnly -of $w -value true    
}


proc sortByLayer {d a b} {
    set tech [db::getAttr d.tech]
    set m1 [oa::getMaskNumber [oa::LayerFind $tech $a]]
    set m2 [oa::getMaskNumber [oa::LayerFind $tech $b]]
    if {$m1 < $m2} {
        return -1
    } else {
        return 1
    }
}


proc giEnableWidget {dlg widgetName {en 0}} {
    set w [gi::findChild /$widgetName -in $dlg]
    db::setAttr enabled -of $w -value $en    
}

proc mergeObjBBoxes {objs} {
    set firtsIteration 1
    set bBox {{0 0} {0 0}}
    db::foreach s $objs {
        if {$firtsIteration} {    
            set firtsIteration 0
            set bBox [db::getAttr bBox -of $s]
        } else {
            set sOABox [box2oaBox [db::getAttr bBox -of $s]]
            set bBox [oa::merge $sOABox [box2oaBox $bBox]]
        }
    }  
    return $bBox
}

proc atof {str} {
    if {[regexp {[-+]?([0-9]+\.?[0-9]*|\.[0-9]+)([eE][-+]?[0-9]+)?} $str match]} {
        return [expr $match*1.0]
    } else {
        return ""
    }
}

proc getLCV {oaDes} {
    if {[db::isObject $oaDes] && "Design"==[db::getAttr type -of $oaDes]} {
        return "[db::getAttr libName -of $oaDes]/[db::getAttr cellName -of $oaDes]/[db::getAttr viewName -of $oaDes]"
    }
    return ""
}

proc getAllRefLibNames {oaDes} {
    set techHeaders [oa::getTechHeaders [db::getAttr oaDes.tech]]
    set techRefs {}
    for {set i 0} {$i<[oa::getSize $techHeaders]} {incr i} {
        lappend techRefs [db::getAttr libName -of [oa::getRefTech [oa::get $techHeaders $i]]]
    }
    lappend techRefs [db::getAttr oaDes.tech.libName]
    set techRefs [lsort -unique $techRefs] 
    return $techRefs
}

}
