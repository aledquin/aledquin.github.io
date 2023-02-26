# Copyright (c) 2004-2015 Synopsys, Inc. This Galaxy Custom Designer software
# and the associated documentation are confidential and proprietary to
# Synopsys, Inc. Your use or disclosure of this Galaxy Custom Designer software
# is subject to the terms and conditions of a written license agreement between
# you, or your company, and Synopsys, Inc.


# Project:      console
# File:         actions.tcl
# Description:  Console actions

namespace eval ::startup {

gi::createAction "amdDataExport" \
    -toolTip "Data Export" \
    -prompt "Data Export" \
    -title "Data Export..." \
    -command "::amd::_de::exportCreateForm" 
    
}
