# Copyright (c) 2004-2014 Synopsys, Inc. This Galaxy Custom Designer software
# and the associated documentation are confidential and proprietary to
# Synopsys, Inc. Your use or disclosure of this Galaxy Custom Designer software
# is subject to the terms and conditions of a written license agreement between
# you, or your company, and Synopsys, Inc.


# Project:      InstAlign 
# File:         startup.tcl
# Description:  

de::sendMessage "Begin sourcing InstAlign package: [info script]" -severity information

package provide amd::align 0.1
db::init lay/InstAlign/menus.tcl
db::init lay/InstAlign/leAlign.tcl
db::init lay/InstAlign/schAlign.tcl
db::init lay/InstAlign/utils.tcl

de::sendMessage "End sourcing InstAlign package" -severity information



