# Copyright (c) 2004-2014 Synopsys, Inc. This Galaxy Custom Designer software
# and the associated documentation are confidential and proprietary to
# Synopsys, Inc. Your use or disclosure of this Galaxy Custom Designer software
# is subject to the terms and conditions of a written license agreement between
# you, or your company, and Synopsys, Inc.


# Project:      layout_editor
# File:         actions.tcl
# Description:  GUI actions for use in menus and toolbars

namespace eval ::amd::_lsw {
    
set ns [namespace current]
    
gi::createAction "amdSetAllVisible" \
    -toolTip "Set All LPPs visible" \
    -prompt "Set All LPPs visible" \
    -title "AV" \
    -icon visible \
    -command "${ns}::amdAVCB"
    
gi::createAction "amdSetAllInvisible" \
    -toolTip "Set All LPPs invisible" \
    -prompt "Set All LPPs invisible" \
    -title "NV" \
    -icon invisible \
    -command "${ns}::amdNVCB"
    
gi::createAction "amdSetAllSelectable" \
    -toolTip "Set All LPPs selectable" \
    -prompt "Set All LPPs selectable" \
    -title "AS" \
    -icon selectable \
    -command "${ns}::amdASCB"    
        
gi::createAction "amdSetAllUnselectable" \
    -toolTip "Set All LPPs unselectable" \
    -prompt "Set All LPPs unselectable" \
    -title "NS" \
    -icon unselectable \
    -command "${ns}::amdNSCB"   

    
gi::createAction "amdApplyActiveDesign" \
    -toolTip "Apply Active Design Only" \
    -prompt "Apply Active Design Only" \
    -title "Apply Active Design Only" \
    -icon abstract \
    -checkProc "${ns}::amdToggleApplyActive"   

    
gi::createAction "amdLeAMDLSW_WindowCloseItem" \
    -toolTip "Close" \
    -prompt "Close" \
    -title "Close" \
    -command "${ns}::amdLayoutLSWCloseWindowMenuCB %w" 
    
gi::createAction "amdLeAMDLSW_WindowConfigItem" \
    -toolTip "Open Configuration Window" \
    -prompt "Open Configuration Window" \
    -title "Open Configuration Window" \
    -command "${ns}::amdLeAMDLSWConfig %w" 
    
gi::createAction "AMDLSW" \
    -toolTip "Help on TWIKI" \
    -prompt "Help on TWIKI" \
    -title "Help on TWIKI" \
    -command "amd::amdHelpRoutines::amdHelpDisplayTwiki AMDLSW" 
    
gi::createAction "AMDLSWSetLayerLists" \
    -toolTip "AMDLSWSetLayerLists" \
    -prompt "AMDLSWSetLayerLists" \
    -title "AMDLSWSetLayerLists" \
    -command "amd::amdHelpRoutines::amdHelpDisplayTwiki AMDLSWSetLayerLists" 

    
gi::createAction "amdLeAMDLSWLayerSelect_WindowCloseItem" \
    -toolTip "Close" \
    -prompt "Close" \
    -title "Close" \
    -command "${ns}::amdLeAMDLSWLayerSelect_CloseWindow %w"
   
gi::createAction "amdLeAMDLSWLayerSelect_FileRefreshItem" \
    -toolTip "Refresh File List from Disk" \
    -prompt "Refresh File List from Disk" \
    -title "Refresh File List from Disk" \
    -command "${ns}::amdLeAMDLSWLayerUpdateUserOwnedFileListField 1"   
   
gi::createAction "amdLeAMDLSWLayerSelect_WindowQuickStartFAQItem" \
    -toolTip "QuickStart FAQ" \
    -prompt "QuickStart FAQ" \
    -title "QuickStart FAQ" \
    -command "${ns}::amdLeAMDLSWLayerSelectQuickStartFAQ"
   
}
 
 
             
            
             
            