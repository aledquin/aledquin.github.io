# Copyright (c) 2004-2014 Synopsys, Inc. This Galaxy Custom Designer software
# and the associated documentation are confidential and proprietary to
# Synopsys, Inc. Your use or disclosure of this Galaxy Custom Designer software
# is subject to the terms and conditions of a written license agreement between
# you, or your company, and Synopsys, Inc.


# Project:      layout_editor
# File:         menus.tcl
# Description:  Menu definitions

namespace eval ::startup {

set wt [gi::getWindowTypes leLayout]

set beforeM [gi::getMenus -from $wt -filter {%title=="Window"}]

set m [gi::createMenu pwrGrdMenu -title "Pwr Grid Tools"];
gi::addActions {amdSelectTemplate
                giSeparator
                amdDrawPowerGrid
                amdEditPowerGrid} -to $m

gi::createAction amdPwrGridMenuAction \
-menu $m -title "Pwr Grid Tools"
    
set m [gi::createMenu leAMDMain -title "AMD Tools"]
gi::addMenu $m -before $beforeM -to $wt  

gi::addActions {
    amdZoomToPoint
    amdShowCenterPoint
    giSeparator
    amdShowArea
    amdConvertPathToPolygon
    amdConvertToPath
    amdLabelNet
    giSeparator
    amdLSW
    amdPwrGridMenuAction
    amdAutoPin
    amdAlignInst
    amdAreaCalc
    amdMacroBD
    amdDRT
    giSeparator
    amdDataExport
} -to $m


}
