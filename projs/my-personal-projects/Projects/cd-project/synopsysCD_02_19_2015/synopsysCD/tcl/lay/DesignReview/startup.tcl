# Copyright (c) 2004-2015 Synopsys, Inc. This Galaxy Custom Designer software
# and the associated documentation are confidential and proprietary to
# Synopsys, Inc. Your use or disclosure of this Galaxy Custom Designer software
# is subject to the terms and conditions of a written license agreement between
# you, or your company, and Synopsys, Inc.


# Project:      amdReviewGui 
# File:         startup.tcl
# Description:  

de::sendMessage "Begin sourcing reviewDesign package: [info script]" -severity information

package provide amd::reviewDesign 0.1
db::init lay/DesignReview/prefs.tcl
db::init lay/DesignReview/reviewGui.tcl

de::sendMessage "End sourcing reviewDesign package" -severity information



