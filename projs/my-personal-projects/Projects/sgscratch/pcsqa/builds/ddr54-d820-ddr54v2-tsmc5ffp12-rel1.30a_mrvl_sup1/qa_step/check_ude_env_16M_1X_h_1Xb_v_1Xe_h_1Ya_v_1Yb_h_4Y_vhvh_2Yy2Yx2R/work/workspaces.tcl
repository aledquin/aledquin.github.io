if {[db::getCount [gi::getWorkspaces leLayout -windowType [gi::getWindowTypes leLayout]]] == 0 } {
gi::createWorkspace leLayout -title "Layout" -windowType leLayout -default true
}
if {[db::getCount [gi::getWorkspaces seSchematic -windowType [gi::getWindowTypes seSchematic]]] == 0 } {
gi::createWorkspace seSchematic -title "Schematic" -windowType seSchematic -default true
}
if {[db::getCount [gi::getWorkspaces teWorkspace -windowType [gi::getWindowTypes teText]]] == 0 } {
gi::createWorkspace teWorkspace -title "Text Editor Workspace" -windowType teText -default true
}
if {[db::getCount [gi::getWorkspaces lxChaining -windowType [gi::getWindowTypes lxSymbolicEditor]]] == 0 } {
gi::createWorkspace lxChaining -title "Chaining" -windowType lxSymbolicEditor -default false
}
if {[db::getCount [gi::getWorkspaces lxMatching -windowType [gi::getWindowTypes lxSymbolicEditor]]] == 0 } {
gi::createWorkspace lxMatching -title "Matching" -windowType lxSymbolicEditor -default false
}
if {[db::getCount [gi::getWorkspaces lxSDL -windowType [gi::getWindowTypes leLayout]]] == 0 } {
gi::createWorkspace lxSDL -title "SDL" -windowType leLayout -default false -doneProc ::lx::_impl::doneTool -initProc ::lx::_impl::initTool
}
if {[db::getCount [gi::getWorkspaces lxSDLseSchematic -windowType [gi::getWindowTypes seSchematic]]] == 0 } {
gi::createWorkspace lxSDLseSchematic -title "SDL" -windowType seSchematic -default false -doneProc ::lx::_impl::doneTool -initProc ::lx::_impl::initTool
}
if {[db::getCount [gi::getWorkspaces ueUDDWorkspace -windowType [gi::getWindowTypes leLayout]]] == 0 } {
gi::createWorkspace ueUDDWorkspace -title "UDD" -windowType leLayout -default false -initProc ::udd::initUDD
}
if {[db::getCount [gi::getWorkspaces deTemplateWorkspaceLayout -windowType [gi::getWindowTypes leLayout]]] == 0 } {
gi::createWorkspace deTemplateWorkspaceLayout -title "Template" -windowType leLayout -default false
}
if {[db::getCount [gi::getWorkspaces deTemplateWorkspaceSchematic -windowType [gi::getWindowTypes seSchematic]]] == 0 } {
gi::createWorkspace deTemplateWorkspaceSchematic -title "Template" -windowType seSchematic -default false
}
if {[db::getCount [gi::getWorkspaces dmLibraryManager -windowType [gi::getWindowTypes dmLibraryManager]]] == 0 } {
gi::createWorkspace dmLibraryManager -title "Library Manager" -windowType dmLibraryManager -default true
}
