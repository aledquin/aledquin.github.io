# Copyright (c) 2004-2014 Synopsys, Inc. This Galaxy Custom Designer software
# and the associated documentation are confidential and proprietary to
# Synopsys, Inc. Your use or disclosure of this Galaxy Custom Designer software
# is subject to the terms and conditions of a written license agreement between
# you, or your company, and Synopsys, Inc.


# Project:      amdHiLayMacroBD 
# File:         startup.tcl
# Description:  

de::sendMessage "Begin sourcing HiLayMacroBD package: [info script]" -severity information

package provide amd::HiLayMacroBD 0.1
db::init lay/MacroBD/HiLayMacroBDUtil.tcl
de::sendMessage "End sourcing HiLayMacroBD package" -severity information



