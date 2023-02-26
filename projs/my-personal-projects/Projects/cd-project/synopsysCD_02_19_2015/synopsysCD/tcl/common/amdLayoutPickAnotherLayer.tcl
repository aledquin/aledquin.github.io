# Copyright (c) 2004-2014 Synopsys, Inc. This Galaxy Custom Designer software
# and the associated documentation are confidential and proprietary to
# Synopsys, Inc. Your use or disclosure of this Galaxy Custom Designer software
# is subject to the terms and conditions of a written license agreement between
# you, or your company, and Synopsys, Inc.

namespace eval ::amd::utils {

namespace export *

proc amdLayoutPickAnotherLayer {layerList} {
    if {[leGetEntryLayer]==$layerList} {
        db::foreach w [getLEWindows] {
            set oaDes [db::getAttr editDesign -of [de::getContexts -window $w]]
            set deLPP [db::getNext [de::getLPPs {unknown drawing} -from $oaDes]]
            if {""!=$deLPP} {
                db::setAttr valid -of $deLPP -value 1
                leSetEntryLayer {unknown drawing}
            } else {
                set deLPP [db::getNext [de::getLPPs {TEXTJNK drawing} -from $oaDes]]
                if {""!=$deLPP} {
                    db::setAttr valid -of $deLPP -value 1
                    leSetEntryLayer {TEXTJNK drawing}
                }                
            }
        }
    }
}

} 



