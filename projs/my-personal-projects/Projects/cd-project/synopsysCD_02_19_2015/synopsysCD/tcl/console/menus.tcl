# Copyright (c) 2004-2014 Synopsys, Inc. This Galaxy Custom Designer software
# and the associated documentation are confidential and proprietary to
# Synopsys, Inc. Your use or disclosure of this Galaxy Custom Designer software
# is subject to the terms and conditions of a written license agreement between
# you, or your company, and Synopsys, Inc.


# Project:      console
# File:         menus.tcl
# Description:  Console window menus
namespace eval ::startup {

set wt [gi::getWindowTypes giConsole]
set beforeM [gi::getMenus -from $wt -filter {%title=="Window"}]
set m [db::getNext [gi::getMenus -from $wt -filter {%title=="AMD Tools"}]]
if {""==$m} {
    set m [gi::createMenu deAMDMain -title "AMD Tools"]
    gi::addMenu $m -before $beforeM -to $wt  
}

gi::addActions {
    amdDataExport
} -to $m 

}

