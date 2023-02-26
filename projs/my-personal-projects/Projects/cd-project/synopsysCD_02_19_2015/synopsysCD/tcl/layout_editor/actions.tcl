# Copyright (c) 2004-2014 Synopsys, Inc. This Galaxy Custom Designer software
# and the associated documentation are confidential and proprietary to
# Synopsys, Inc. Your use or disclosure of this Galaxy Custom Designer software
# is subject to the terms and conditions of a written license agreement between
# you, or your company, and Synopsys, Inc.


# Project:      layout_editor
# File:         actions.tcl
# Description:  GUI actions for use in menus and toolbars

namespace eval ::startup {

set ns ::amd::amdLayLibrary

gi::createAction "amdZoomToPoint" \
    -title "Zoom to Point..." \
    -command "${ns}::amdZoomToPoint %w"
    
gi::createAction "amdShowCenterPoint" \
    -title "Show Center Point..." \
    -command "${ns}::amdShowCenterPoint %w"
    
gi::createAction "amdShowArea" \
    -title "Show Area..." \
    -command "${ns}::amdShowArea %w" 
        
gi::createAction "amdConvertPathToPolygon" \
    -title "Convert Path to Polygon..." \
    -command "${ns}::amdConvertPathToPolygon %w"          
    
gi::createAction "amdConvertToPath" \
    -title "Convert to Path..." \
    -command "${ns}::amdConvertToPath %w"  
    
gi::createAction "amdLabelNet" \
    -title "Add Label to Net..." \
    -command "${ns}::amdLabelNet %w"

gi::createAction amdSelectTemplate  \
    -toolTip "Select Template File" \
    -prompt "Select Template File" \
    -title "Select Template"  \
    -command [list amd::_amdPwrGridTemplate %w %c]   

gi::createAction "amdDrawPowerGrid"  \
    -toolTip "Create Power Grid" \
    -prompt "Create Power Grid" \
    -title "Create"  \
    -command amd::drawPDKLePwrGrid

gi::createAction "amdEditPowerGrid" \
    -toolTip "Modify Power Grid" \
    -prompt "Modify Power Grid" \
    -title "Modify Selected"  \
    -command "amd::editPDKLePwrGrid"

gi::createAction "amdLSW" \
    -toolTip "AMD LSW" \
    -prompt "AMD LSW" \
    -title "AMD LSW..."  \
    -command "amd::_lsw::amdLayoutLSWDisplay"

gi::createAction "amdAutoPin" \
    -toolTip "Pin Tool" \
    -prompt "Pin Placer" \
    -title "Pin Tool..." \
    -icon visible \
    -command "::amd::_autoPin::amdLePinGuiForm %w %c"    

gi::createAction "amdAlignInst" \
    -toolTip "Align and Compact" \
    -prompt "Align and Compact" \
    -title "Align and Compact..." \
    -command "::amd::_align::amdAlignInstancesForm"    

gi::createAction "amdAreaCalc" \
    -toolTip "Density Calculator" \
    -prompt "Density Calculator" \
    -title "Density Calculator..." \
    -command "::amd::_ac::AMDLeCalcShapeDensityGUI"    

gi::createAction "amdMacroBD" \
    -toolTip "Creates Macro Boundary" \
    -prompt "Creates Macro Boundary" \
    -title "Macro Boundary DRC Util..." \
    -command "::amd::_MacroBD::amdHiLayMacroBDUtil %c"    
    
gi::createAction "amdDRT" \
    -toolTip "Design Review Tool" \
	-prompt "AMD Design Review Tool" \
    -title "Design Review Tool..."  \
	-command "::amd::_designReview::amdDesignReview %c" 
        
}

