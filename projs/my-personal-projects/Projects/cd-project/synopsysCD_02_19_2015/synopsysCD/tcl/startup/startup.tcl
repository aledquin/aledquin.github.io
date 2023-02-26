# Copyright (c) 2004-2014 Synopsys, Inc. This Galaxy Custom Designer software
# and the associated documentation are confidential and proprietary to
# Synopsys, Inc. Your use or disclosure of this Galaxy Custom Designer software
# is subject to the terms and conditions of a written license agreement between
# you, or your company, and Synopsys, Inc.


# Project:      startup
# File:         startup.tcl
# Description:  Startup package initialization
namespace eval ::amd {
proc _validatePrefValue {name value} {
    switch  $name {
        amdPwrGrdSliceOption {
            set validList {zeroPullbacks zeroExceptCutPullbacks leavePullbacks}
            if {[lsearch $validList $value] < 0 } {
                de::sendMessage "Preference amdPwrGrdSliceOption value must be from the following set: {zeroPullbacks | zeroExceptCutPullbacks | leavePullbacks} " \
                    -severity error
                return 0
            }
            return 1
        }
    }
}    
}

namespace eval ::startup {

# LSW Preferences
db::createPref amdLayoutAMDLSWWindowLastLoc -value ""
db::createPref amdLeAMDLSWLayerSortFoldField -value 0
db::createPref amdLeAMDLSWLayerSortField -value "Name"
db::createPref amdLeAMDLSWLayerSortSetsField -value 0
db::createPref amdLeAMDLSWLayerSortSetsChoiceField -value "ALL"
db::createPref amdLeAMDLSWLayerChooselayerSetName -value ""
db::createPref amdLeAMDLSWLayerButtonFileField -value ""
db::createPref amdLeAMDLSWLayerButtonFileField -value ""

db::createPref amdLeAMDLSWShowToggle -value 1 -type bool
db::createPref amdLeAMDLSWShowApllyActiveDesignOnlyButton -value 0 -type bool
db::createPref amdLeAMDLSWApllyActiveDesignOnly -value 0 -type bool
db::createPref amdLeAMDLSWRedraw -value 1 -type bool
db::createPref amdLeAMDLSWMakeLPPsInvalid -value 0 -type bool

# Power Grid Preferences
db::createPref amdPwrGrdBottomMetal -defaultScope cellview -description "Power Grid Bottom Metal" -type string -value ""
db::createPref amdPwrGrdTopMetal -defaultScope cellview -description "Power Grid Top Metal" -type string -value ""
db::createPref amdPwrGrdRows -defaultScope cellview -description "Power Grid Rows" -type int -value 1
db::createPref amdPwrGrdCols -defaultScope cellview -description "Power Grid Columns" -type int -value 1
db::createPref amdPwrGrdTemplateFile -description "Power Grid Template File" -type string -value ""
db::createPref amdPwrGrdTemplateDir -description "Initial directory for Power Grid Template File" -type string -value "./"
db::createPref amdPwrGrdDefTemplateFile -description "Power Grid Default Template File" -type string -value ""

db::createPref amdPwrGrdSliceOption -defaultScope cellview -value zeroPullbacks -validationProc ::amd::_validatePrefValue \
    -description "Controls how to set Pullbacks on Power Grid slices. Posible values: zeroPullbacks | zeroExceptCutPullbacks | leavePullbacks"

db::createPref amdPwrGrdCreateMode -description "Power Grid Create Mode" -type bool -value false

db::createPref amdPwrGrdCellView -description "Power Grid LCV" -value amd_ginfLib/customPGv1/layout
db::createPref amdPwrgridPurposes -description "Power Grid Purposes" \
    -value {"drawing" "vss" "vdd" "vddio" "vldt" "vtt" "vmemp" "vmemio" "vddr" "track"}
db::createPref amdMacroBDSTDCellView  -description "MacroBD STD LCV"  -value stdcell/fillerx2/layout 
# Align Inst Preferences
db::createPref amdAlignAlt -value 0 -type bool
db::createPref amdAlignSame -value 0 -type bool
db::createPref amdAlignIncr -value 0 -type bool
db::createPref amdAlignDec -value 0 -type bool
db::createPref amdAlignXGrid -value 0.0 -type float
db::createPref amdAlignXOff -value 0.0 -type float
db::createPref amdAlignYGrid -value 0.0 -type float
db::createPref amdAlignYOff -value 0.0 -type float


set auto_path [linsert $auto_path 1 [file join [file dirname [file dirname [info script]]] lay]]
set auto_path [linsert $auto_path 1 [file join [file dirname [file dirname [info script]]] sch]]

db::setPrefValue giShowDialogsAsWindows -value 0
}


