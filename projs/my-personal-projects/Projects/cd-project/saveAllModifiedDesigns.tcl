namespace eval amd::userTools {

  proc saveAllModifiedDesigns { } {
    db::foreach design [oa::DesignGetOpenDesigns] {
      if {[oa::getMode $design] != "a" } continue
      if {![oa::isModified $design] } continue
      de::sendMessage "Saving design: [oa::getLibName $design] [oa::getCellName $design] [oa::getViewName $design]"
      oa::save $design
    }
  }

}

