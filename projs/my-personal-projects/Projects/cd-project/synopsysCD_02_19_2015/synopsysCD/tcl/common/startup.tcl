# Copyright (c) 2004-2014 Synopsys, Inc. This Galaxy Custom Designer software
# and the associated documentation are confidential and proprietary to
# Synopsys, Inc. Your use or disclosure of this Galaxy Custom Designer software
# is subject to the terms and conditions of a written license agreement between
# you, or your company, and Synopsys, Inc.


# Project:      utils 
# File:         startup.tcl
# Description:  

de::sendMessage "Begin sourcing snpsutils package: [info script]" -severity information

package provide amd::snpsutils 0.1
db::init common/snpsUtils.tcl
db::init common/tools.tcl
db::init common/amdLibrary.tcl
db::init common/amdRounding.tcl
db::init common/amdLayLibrary.tcl
db::init common/amdHelpRoutines.tcl
db::init common/amdLeLayerUtils.tcl
db::init common/amdLayoutPickAnotherLayer.tcl
db::init common/amdSnapLabels.tcl

de::sendMessage "End sourcing snpsutils package" -severity information



