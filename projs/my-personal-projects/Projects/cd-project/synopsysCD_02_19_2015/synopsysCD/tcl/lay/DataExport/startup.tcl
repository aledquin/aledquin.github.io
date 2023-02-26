# Copyright (c) 2004-2015 Synopsys, Inc. This Galaxy Custom Designer software
# and the associated documentation are confidential and proprietary to
# Synopsys, Inc. Your use or disclosure of this Galaxy Custom Designer software
# is subject to the terms and conditions of a written license agreement between
# you, or your company, and Synopsys, Inc.


# Project:      Data Export Tool 
# File:         startup.tcl
# Description:  

de::sendMessage "Begin sourcing Data Export package: [info script]" -severity information

package provide amd::dataExport 0.1
db::init lay/DataExport/prefs.tcl
db::init lay/DataExport/dataExport.tcl

de::sendMessage "End sourcing Data Export package" -severity information



