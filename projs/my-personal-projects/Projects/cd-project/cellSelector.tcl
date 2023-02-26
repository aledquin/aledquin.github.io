###############################################################################################################
##
## Proc        : cellSelector
##
## Description : This procedure will list all of the instances in a design on a GUI, allowing the user to 
##               choose a particular cell(s) on the GUI, hit the Select button, and have them selected on the canvas
##
## Usage       : Its useful to define a bindkey to execute the script.  In this example, the "n" key is defined:
##               gi::createBinding -windowType leLayout -event n -command amd::userTools::cellSelector::init
##
## Author      : Marc Tareila marc.tareila@amd.com x28586
##
###############################################################################################################

namespace eval amd::userTools::cellSelector {

  # Top level proc
  proc init {} {

    # Get a collection of the instances in the design
    set insts [db::getInsts -of [ed]]
    if {[db::isEmpty $insts]} {
      de::sendMessage "No instances found in the design" -severity information
      return
    }

    # Get the unique cell names of the instances
    set cellNames {}
    db::foreach inst $insts {
      lappend cellNames [db::getAttr cellName -of $inst]
    }
    set cellNames [lsort -unique $cellNames]

    # Create the GUI
    set dialog [gi::createDialog dialog -title "Cells in current design" -showHelp false -extraButtons Select -buttonProc amd::userTools::cellSelector::selectCells]
    set listInput [gi::createListInput listInput -parent $dialog -items $cellNames -selectionModel multiple]
    db::setAttr geometry -of $dialog -value "350x440"
  }

  # This proc gets called when the Select button on the GUI is pressed
  proc selectCells {dialog button} {
    set cellNames [db::getAttr value -of [gi::findChild listInput -in $dialog]]
    if {$cellNames == ""} {
      de::sendMessage "Select cells on the GUI before clicking on the Select button" -severity information
      return
    }

    set cells [db::getInsts -of [ed] -filter {[lsearch $cellNames %cellName] != -1}]
    if {![db::isEmpty $cells]} {
      de::deselectAll [de::getActiveContext]
      de::select $cells
    }
  }
}
