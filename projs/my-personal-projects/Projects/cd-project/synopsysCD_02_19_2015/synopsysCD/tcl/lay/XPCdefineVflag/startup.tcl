# Copyright (c) 2004-2014 Synopsys, Inc. This Galaxy Custom Designer software
# and the associated documentation are confidential and proprietary to
# Synopsys, Inc. Your use or disclosure of this Galaxy Custom Designer software
# is subject to the terms and conditions of a written license agreement between
# you, or your company, and Synopsys, Inc.


# Project:      XPCdefineVflag 
# File:         startup.tcl
# Description:  

de::sendMessage "Begin sourcing XPC package: [info script]" -severity information

package provide amd::XPC 0.1
db::init lay/XPCdefineVflag/XPCdefineVflag.tcl
db::init lay/XPCdefineVflag/XPCdrawVflag.tcl
db::init lay/XPCdefineVflag/XPCconnectivityUtils.tcl
db::init lay/XPCdefineVflag/XPCpcellUtils.tcl
de::sendMessage "End sourcing XPC" -severity information

