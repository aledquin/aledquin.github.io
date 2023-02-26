# Copyright (c) 2004-2014 Synopsys, Inc. This Galaxy Custom Designer software
# and the associated documentation are confidential and proprietary to
# Synopsys, Inc. Your use or disclosure of this Galaxy Custom Designer software
# is subject to the terms and conditions of a written license agreement between
# you, or your company, and Synopsys, Inc.


# Project:      layout_editor
# File:         menus.tcl
# Description:  Menu definitions

namespace eval ::amd::_lsw {

variable lswWT amdLSW
variable lswConfigWT amdLeAMDLSWUpdateLayerList

proc amdCreateLSWWT {} {
    variable lswWT
    set wt [gi::getWindowTypes $lswWT]
    if {[db::isEmpty $wt]} {
        set wt [gi::createWindowType $lswWT \
        -title "" -createProc [namespace current]::amdLSWCreateWindowProc]
    }
    amdLeAMDLSW_CreateWindowMenu $wt
    return $wt
}

proc amdLeAMDLSW_CreateWindowMenu {wt} {
    set m [gi::createMenu amdLeAMDLSW_WindowMenu -title "Window"]
    gi::addActions {
        amdLeAMDLSW_WindowCloseItem
        amdLeAMDLSW_WindowConfigItem
    } -to $m    
    gi::addMenu $m -to $wt
    
    set m [gi::createMenu amdLeAMDLSW_HelpMenu -title "Help"]
    gi::addActions {
        AMDLSW
        AMDLSWSetLayerLists
    } -to $m    
    gi::addMenu $m -to $wt
}

proc amdCreateConfigWT {} {
    variable lswConfigWT
    set wt [gi::getWindowTypes $lswConfigWT]
    if {[db::isEmpty $wt]} {
        set wt [gi::createWindowType $lswConfigWT \
        -title "" -createProc [namespace current]::amdLSWConfigCreateWindowProc]
    }
    amdLeAMDLSWLayerSelect_CreateWindowMenu $wt    
    amdLeAMDLSWLayerSelect_CreateFileMenu $wt
    set m [gi::createMenu  amdCreateConfig_HelpMenu -title "Help"]
    gi::addActions {
        amdLeAMDLSWLayerSelect_WindowQuickStartFAQItem
    } -to $m    
    gi::addMenu $m -to $wt    
}

proc amdLeAMDLSWLayerSelect_CreateWindowMenu {wt} {
    set m [gi::createMenu amdLeAMDLSWLayerSelect_WindowMenu -title "Window"]
    gi::addActions {
        amdLeAMDLSWLayerSelect_WindowCloseItem
    } -to $m
    gi::addMenu $m -to $wt
}

proc amdLeAMDLSWLayerSelect_CreateFileMenu {wt} {
    set m [gi::createMenu amdLeAMDLSWLayerSelect_FileMenu -title "File"]
    gi::addActions {
        amdLeAMDLSWLayerSelect_FileRefreshItem
    } -to $m    
    gi::addMenu $m -to $wt
}

amdCreateLSWWT 
amdCreateConfigWT

}


