# Copyright (c) 2004-2014 Synopsys, Inc. This Galaxy Custom Designer software
# and the associated documentation are confidential and proprietary to
# Synopsys, Inc. Your use or disclosure of this Galaxy Custom Designer software
# is subject to the terms and conditions of a written license agreement between
# you, or your company, and Synopsys, Inc.

#puts "amdLeAlign.tcl"
namespace eval ::amd::_align {
namespace export *
namespace import -force ::amd::utils::*
namespace import -force ::amd::amdLibrary::*
namespace import -force ::amd::amdLayLibrary::*


proc amdSchLayStretch {obj cv xfrm} {
    if {"ScalarInst"==[db::getAttr type -of $obj] && "schematic" == [db::getAttr viewType -of $cv]} {
        amdSchStretchInstWires $obj $cv $xfrm
    }
    set dx [lindex $xfrm 0]
    set dy [lindex $xfrm 1]
    set r [lindex $xfrm 2]
    if {"maskLayout" == [db::getAttr viewType -of $cv]} {
        le::move $obj -dx $dx -dy $dy -rotate $r
        #oa::move $obj [oa::Transform $dx $dy $r]
    } else {
        se::move $obj -dx $dx -dy $dy -rotate $r
    }
}


}



