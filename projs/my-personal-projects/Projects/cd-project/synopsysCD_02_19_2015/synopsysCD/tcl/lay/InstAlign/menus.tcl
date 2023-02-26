# Copyright (c) 2004-2014 Synopsys, Inc. This Galaxy Custom Designer software
# and the associated documentation are confidential and proprietary to
# Synopsys, Inc. Your use or disclosure of this Galaxy Custom Designer software
# is subject to the terms and conditions of a written license agreement between
# you, or your company, and Synopsys, Inc.


# Project:      layout_editor
# File:         menus.tcl
# Description:  Menu definitions

namespace eval ::amd::_align {

variable alignWT alignWT

proc amdCreateAlignWT {} {
    variable alignWT
    set wt [gi::getWindowTypes $alignWT]
    if {[db::isEmpty $wt]} {
        set wt [gi::createWindowType $alignWT \
        -title "AMD Align and Compact" -createProc [namespace current]::amdAlignCreateWindowProc]
    }
    return $wt
}

amdCreateAlignWT 

}


