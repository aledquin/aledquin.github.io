puts "Loading AMD Layout User Code..."

  puts "  Sourcing scripts..."
  source /proj/tcoe_skill/cdesigner/userUtils.tcl; 				# Library of user written procedures shared in many user scripts
  source /proj/tcoe_skill/cdesigner/flipObjectsInPlace.tcl;			# Procedures that mirror multiple selected objects in place
  source /proj/tcoe_skill/cdesigner/fullySelectAllSelectedObjects.tcl;		# Selects currently selected objects in full selection mode
  source /proj/tcoe_skill/cdesigner/toggleAngleMode.tcl;			# Toggles the angle mode between any and orthogonal
  source /proj/tcoe_skill/cdesigner/nudgeObjects.tcl;				# Moves selected objects in 1nm increments
  source /proj/tcoe_skill/cdesigner/toggleSnapGrid.tcl;				# Toggles through a list of snapping grids
  source /proj/tcoe_skill/cdesigner/dcapPlacer.tcl;				# Dcap placer tool
  source /proj/tcoe_skill/cdesigner/interactiveViaDropper.tcl;			# Alt/O via dropper tool
  source /proj/tcoe_skill/cdesigner/abortNestedCommands.tcl;			# Escapes out of the entire command stack
  source /proj/tcoe_skill/cdesigner/saveAllModifiedDesigns.tcl;			# Saves all cells in the session that are modified
  source /proj/tcoe_skill/cdesigner/describeSelected.tcl;			# Reports the objects that are selected in the console
  source /proj/tcoe_skill/cdesigner/cellSelector.tcl;				# Cell selector tool
  source /proj/tcoe_skill/cdesigner/updateRoutesWithNoNets.tcl;			# Clean up script that fixes an issue preventing connectivity depth to be increased
  source /proj/tcoe_skill/cdesigner/highlightFlightlineFigs.tcl;		# Adds synced highlight and flightline functionality to the design navigator
  source /proj/tcoe_skill/cdesigner/openLePlus.tcl;				# Automatically invokes lePlus
  source /proj/tcoe_skill/cdesigner/copyClonePrefs.tcl;				# Always disables the Group and Sync options for the copy command


  puts "  Defining key bindings..."
  gi::createBinding -windowType leLayout -event f1          -command {de::deselectAll %c}
  gi::createBinding -windowType leLayout -event shift-f2    -command {amd::userTools::saveAllModifiedDesigns}
  gi::createBinding -windowType leLayout -event f12         -command {ile::highlightConnected}
  gi::createBinding -windowType leLayout -event shift-f12   -command {de::clearHighlights -context [de::getActiveContext]}
  gi::createBinding -windowType leLayout -event .           -command {msip::CDtools::adhoc::msip_le_toolBar::showSelectedSet}
  gi::createBinding -windowType leLayout -event ,           -command {msip::CDtools::adhoc::msip_le_toolBar::stretch_on}
  gi::createBinding -windowType leLayout -event alt-h       -command {amd::userTools::flipObjectsInPlace group horizontally}
  gi::createBinding -windowType leLayout -event shift-h     -command {amd::userTools::flipObjectsInPlace single horizontally}
  gi::createBinding -windowType leLayout -event alt-v       -command {amd::userTools::flipObjectsInPlace group vertically}
  gi::createBinding -windowType leLayout -event shift-v     -command {amd::userTools::flipObjectsInPlace single vertically}
  gi::createBinding -windowType leLayout -event j           -command {amd::userTools::fullySelectAllSelectedObjects}
  gi::createBinding -windowType leLayout -event n           -command {amd::userTools::toggleAngleMode}
  gi::createBinding -windowType leLayout -event ctrl-up     -command {amd::userTools::nudgeObjects up}
  gi::createBinding -windowType leLayout -event ctrl-left   -command {amd::userTools::nudgeObjects left}
  gi::createBinding -windowType leLayout -event ctrl-right  -command {amd::userTools::nudgeObjects right}
  gi::createBinding -windowType leLayout -event ctrl-down   -command {amd::userTools::nudgeObjects down}
  gi::createBinding -windowType leLayout -event alt-g       -command {amd::userTools::toggleSnapGrid}
  gi::createBinding -windowType leLayout -event alt-x       -command {ide::descendIntoGroup}
  gi::createBinding -windowType leLayout -event escape      -command {amd::userTools::abortNestedCommands %w}
  gi::createBinding -windowType leLayout -event space       -command {gi::executeAction deCycleSelectNext -in %w; amd::userTools::describeSelected}
  gi::createBinding                      -event z           -command {ide::setViewport %w -direction in}


  puts "  Defining preferences..."
  db::setPrefValue  lxViewSearchList -value "layout abstract schematic"
  db::setPrefValue  lxViewStopList -value "layout abstract"
  db::setPrefValue  leRoutingPurposeList -value "drawing vdd vss dpl1 dpl2 vddr vldt vtt vddio vmemp vmemio vddh vddm vddco vbb vssco clock"
  db::setPrefValue  leInterconnectAdjustStartEnd -value true
  db::setPrefValue  dbImportStreamLayerMapFile  -value $env(SNPS_PDK)/AMD_PDK_Package/StreamMapFiles/stream.layermap
  db::setPrefValue  dbImportStreamObjectMapFile -value $env(SNPS_PDK)/AMD_PDK_Package/StreamMapFiles/object.map

  puts "  Defining the User Tools menu..."
  source /proj/tcoe_skill/cdesigner/userToolsMenu.tcl

puts "Finished loading AMD Layout User Code..."
