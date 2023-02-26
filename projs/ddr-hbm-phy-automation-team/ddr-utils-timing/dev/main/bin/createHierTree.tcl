proc utils__script_usage_statistics {toolname version} {
    set prefix "ddr-da-"
    set reporter "/remote/cad-rep/msip/tools/bin/msip_get_usage_info"
    set cmd ""
    set script_dirname [file dirname [file normalize [info script]]]
    append cmd "$reporter --tool_name  \"${prefix}${toolname}\" "
    append cmd "--stage main --category ude_ext_1 "
    append cmd "--tool_path \"$script_dirname\" --tool_version \"$version\""

    exec sh -c $cmd
}

set script_name [file tail [file rootname [file normalize [info script]]]]
utils__script_usage_statistics $script_name "2022ww23"


namespace eval ::$env(USER)_hierarchy {

    variable LEVEL 0
    variable STOPLEVEL 32
    variable fp 
    proc generateTree {} {
        variable STOPLEVEL 
        global env
        set dlgName "hierarchyTree"
        set dlgTitle "Hierarchy Tree"
        set dlg [gi::createDialog $dlgName -title $dlgTitle -parent [gi::getActiveWindow] \
                -showHelp false -showApply false -execProc "$env(USER)_hierarchy::getStopLevel"]
        gi::createNumberInput stopLevel -parent $dlg -minValue 0 -stepValue 1 -label "Stop Level"
        gi::setField stopLevel -in $dlg -value $STOPLEVEL

    }

    proc getStopLevel {dlg} {
        variable STOPLEVEL 
        set dlgName [db::getAttr name -of $dlg]
        set stopLevel [db::getAttr value -of [gi::findChild /stopLevel -in $dlg]]
        set STOPLEVEL $stopLevel
        exportToTextFile 
    }

    proc exportToTextFile {} {
        variable fp
        set design [ed]
        set libName [db::getAttr libName -of $design]
        set cellName [db::getAttr cellName -of $design]
        set viewName [db::getAttr viewName -of $design]
        set fp [open "${libName}_${cellName}_${viewName}.tree" w]
        getCellData $design "" 
        close $fp
        xt::openTextViewer -files "${libName}_${cellName}_${viewName}.tree"
    }

    proc getCellData { design {count 0}} {
        variable STOPLEVEL 
        variable LEVEL 
        variable fp
        set libName [db::getAttr libName -of $design]
        set cellName [db::getAttr cellName -of $design]
        set viewName [db::getAttr viewName -of $design]
        set instHeaders [db::getAttr instHeaders -of $design]
        set insts [db::getAttr insts -of $design]
        if {[catch {puts $fp "[string repeat { |} $LEVEL] - $libName $cellName $viewName "} err]} {
            puts $err
        } else {
            if {$LEVEL <= $STOPLEVEL} {
                getInstancesHier $instHeaders
            }
        }
    }

    proc getInstancesHier {instMasters } {
        variable LEVEL
        variable fp
        set LEVEL [expr $LEVEL+1] 
        if {($instMasters != {}) && ([db::getCount $instMasters]>0)} {
            db::foreach inst $instMasters {
                set count [db::getCount [db::getAttr insts -of $inst]]
                set libName [db::getAttr libName -of $inst]
                set cellName [db::getAttr cellName -of $inst]
                set viewName [db::getAttr viewName -of $inst]
                if {[catch {
                        #set dmCellView [dm::findCellView $viewName -cellName $cellName -libName $libName]
                        #set cv [de::open $dmCellView -headless true -readOnly true]
                        #set design [db::getAttr topDesign -of $cv]
                        if {$viewName == "symbol"} {
                            set design [oa::DesignOpen $libName $cellName schematic r]
                        } else {
                            set design [oa::DesignOpen $libName $cellName $viewName r]
                        }
                        set count [db::getCount [db::getAttr insts -of $inst]]
                    } err] } {
                        puts $err
                        puts $fp "[string repeat { |} $LEVEL] - $libName $cellName $viewName "
                } else {
                    getCellData $design $count
                }
            }

        }
        set LEVEL [expr $LEVEL-1] 
    }

}

set action [gi::createAction hierTree                                                    \
                -command "$env(USER)_hierarchy::generateTree"                                   \
                -title "Tree"                                                              \
                -label "Tree"                                                       \
                -prompt "Tree"]

gi::addActions $action \
            -to [gi::getMenus leDesignHierarchyCascade] \
            -after [gi::getActions deReturnToTop]
gi::addActions $action \
            -to [gi::getMenus seHierarchyCascade] \
            -after [gi::getActions deReturnToTop]
