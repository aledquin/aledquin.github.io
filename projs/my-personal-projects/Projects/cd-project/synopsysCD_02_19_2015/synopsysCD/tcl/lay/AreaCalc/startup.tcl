# Copyright (c) 2004-2015 Synopsys, Inc. This Galaxy Custom Designer software
# and the associated documentation are confidential and proprietary to
# Synopsys, Inc. Your use or disclosure of this Galaxy Custom Designer software
# is subject to the terms and conditions of a written license agreement between
# you, or your company, and Synopsys, Inc.


# Project:      Area Calculator 
# File:         startup.tcl
# Description:  

de::sendMessage "Begin sourcing Area Calc package: [info script]" -severity information

package provide amd::ac 0.1
db::init lay/AreaCalc/areaCalc.tcl

de::sendMessage "End sourcing Area Calc package" -severity information



