namespace eval ::amd::utils {

namespace export *

proc amdLeIsTrackLayer {layers} {
    set track [amdLeGetTrackLayers]
    set trackStr [join $track]
    set trackStr [string map {\" ""} $trackStr]   
    set newLayers {}
    foreach l $layers {
        if {-1!=[string first $l $trackStr] && [car $l]!="stretch"} {
            lappend newLayers $l
        }
    }
    return $newLayers
}


proc amdLeGetTrackLayers {} {
    if {[info exist ::amd::GVAR_amdLayVariables(amdLayoutAlias,track)]} {
        return $::amd::GVAR_amdLayVariables(amdLayoutAlias,track)
    }
    return ""
}

################################################################################
# Description: Return the name of the layer for this "canonical" name.
#              If no argument, return a list of all the metal layers.  
#
#              The "canonical" name is "m"+<layernumber>
# Usage: amdLeGetMetalLayerName() => ("M01" "M02" "M03" "M04" "M05" 
#                                     "M06" "M07" "M08" "M09" "M10" "M11")
#                                     
#        amdLeGetMetalLayerName("m1") => "M01" (amd13s)
#                                     => "M1"  (gf29G)
#
################################################################################

proc amdLeGetMetalLayerName {{layerName ""}} {
    if {""!=$layerName} {
        if {[regexp -nocase {m(\d+)} $layerName match lNum]} {
            return [lindex $::amd::GVAR_amdLayVariables(amdMetLayers) [expr $lNum-1]]
        } else {
            de::sendMessage "amdLeGetMetalLayerName takes an argument of the form \"m<layer number>\"" -severit error
        }
    } else {
        return $::amd::GVAR_amdLayVariables(amdMetLayers)
    }
}



}
