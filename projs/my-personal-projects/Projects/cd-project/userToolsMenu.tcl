# This script creates a User Tools pulldown menu and places it before the Window menu
namespace eval amd::userToolsMenu {

  set wt [gi::getWindowTypes leLayout]

  # Find the Window menu
  set windowMenu [gi::getMenus -from $wt -filter {%title=="Window"}]

  # If we found the Window menu, continue
  if {![db::isEmpty $windowMenu]} {

    # Create the User Tools menu
    set userToolsMenu [gi::createMenu userToolsMenu -title "User Tools"]

    # Create the actions to be placed on the User Tools menu and add them to the menu
    gi::createAction "dcapPlacer" -title "Dcap Placer" -command "amd::dcapPlacer::initTool %c %w"
    gi::addActions dcapPlacer -to $userToolsMenu

    # Add the User Tools menu next to the Window pulldown
    gi::addMenu $userToolsMenu -before $windowMenu -to $wt
  }
}
