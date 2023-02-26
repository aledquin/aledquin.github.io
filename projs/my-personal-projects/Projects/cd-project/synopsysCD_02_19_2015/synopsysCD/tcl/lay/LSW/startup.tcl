# Copyright (c) 2004-2014 Synopsys, Inc. This Galaxy Custom Designer software
# and the associated documentation are confidential and proprietary to
# Synopsys, Inc. Your use or disclosure of this Galaxy Custom Designer software
# is subject to the terms and conditions of a written license agreement between
# you, or your company, and Synopsys, Inc.


# Project:      amdLSW 
# File:         startup.tcl
# Description:  

de::sendMessage "Begin sourcing LSW package: [info script]" -severity information

package provide amd::lsw 0.1
db::init lay/LSW/actions.tcl
db::init lay/LSW/menus.tcl
db::init lay/LSW/lsw.tcl

de::sendMessage "End sourcing LSW package" -severity information



