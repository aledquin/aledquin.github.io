###############################################################################################################
##
## Proc        : describeSelected
##
## Description : This procedure will report info on the objects that are selected in the console
##
## Usage       : Its useful to define a bindkey to execute the script.  In this example, the "d" key is defined:
##               gi::createBinding -event d -command {amd::userTools::describeSelected}
##
## Author      : Marc Tareila marc.tareila@amd.com x28586
##
###############################################################################################################

namespace eval amd::userTools {

  proc describeSelected {} {

    set prBoundary false
    set oaTech [amd::userUtils::getTechFile]

    set selectedObjects [amd::userUtils::getSelectedObjects]

    puts ""

    switch [db::getCount $selectedObjects] {
      0 {puts "No objects are selected"; return}
      1 {puts "The following object is selected:"}
      default {puts "The following objects are selected:"}
    }

    db::foreach object $selectedObjects {
      set objectType [db::getAttr type -of $object]
      switch -regexp $objectType {
        "Rect" {incr rects([db::getAttr LPP.lpp -of $object])}
        "Path" {incr paths([db::getAttr LPP.lpp -of $object])}
        "PathSeg" {incr pathsegs([db::getAttr LPP.lpp -of $object])}
        "Polygon" {incr polygons([db::getAttr LPP.lpp -of $object])}
        "Ellipse" {incr ellipses([db::getAttr LPP.lpp -of $object])}
        "(Text|AttrDisplay)" {incr labels([list [db::getAttr text -of $object] [db::getAttr LPP.lpp -of $object]])}
        "StdVia" {incr stdvias([db::getAttr name -of $object])}
        "CustomVia" {incr customvias([db::getAttr name -of $object])}
        "ScalarInst" {incr instances([db::getAttr cellName -of $object])}
        "ArrayInst" {incr arrays([db::getAttr cellName -of $object])}
        "LayerBlockage" {
          set layerName [oa::getName [oa::LayerFind $oaTech [db::getAttr layerNum -of $object]]]
          incr blockages($layerName)
        }
        "PRBoundary" {set prBoundary true}
        default {incr unknowns($objectType)}
      }
    }

    foreach textLpp [array names labels] {
      puts "$labels($textLpp) label(s) with text [lindex $textLpp 0] on lpp [lindex $textLpp 1]"
    }
    foreach lpp [array names rects] {
      puts "$rects($lpp) rectangle(s) on lpp $lpp"
    }
    foreach lpp [array names paths] {
      puts "$paths($lpp) path(s) on lpp $lpp"
    }
    foreach lpp [array names pathsegs] {
      puts "$pathsegs($lpp) pathseg(s) on lpp $lpp"
    }
    foreach lpp [array names polygons] {
      puts "$polygons($lpp) polygon(s) on lpp $lpp"
    }
    foreach lpp [array names ellipses] {
      puts "$ellipses($lpp) ellipse(s) on lpp $lpp"
    }
    foreach via [array names stdvias] {
      puts "$stdvias($via) $via stdvia(s)"
    }
    foreach via [array names customvias] {
      puts "$customvias($via) $via customvia(s)"
    }
    foreach cell [array names instances] {
      puts "$instances($cell) instance(s) of cell $cell"
    }
    foreach cell [array names arrays] {
      puts "$arrays($cell) array(s) of cell $cell"
    }
    foreach layerName [array names blockages] {
      puts "$blockages($layerName) blockage(s) on layer $layerName"
    }
    if {$prBoundary} {
      puts "1 prBoundary object"
    }
    foreach type [array names unknowns] {
      puts "$unknowns($type) object(s) of type $type"
    }
  }
}
