##################################################################
##  Created by: Design Compiler (R) NXT (Topographical)
##  Version: P-2019.03-SP1-VAL
##  Design: casez_rom
##  Date: Fri May 17 12:31:28 2019
##  Command: write_floorplan
##################################################################
set _dirName__0 [file dirname [file normalize [info script]]]


################################################################################
# Read DEF
################################################################################


read_def -allow_cell_creation ${_dirName__0}/floorplan.def


################################################################################
# Bounds
################################################################################




################################################################################
# Route guides
################################################################################




################################################################################
# Blockages
################################################################################




################################################################################
# Voltage areas
################################################################################




################################################################################
# RP groups
################################################################################


if {[file exists ${_dirName__0}/rp.tcl]} {
source ${_dirName__0}/rp.tcl
}


################################################################################
# User Shapes
################################################################################




################################################################################
# Routing directions
################################################################################


set_ignored_layers -rc_congestion_ignored_layers {M1 MB ZA } -min_routing_layer {M1} -max_routing_layer {ZA} -verbose
set_attribute [get_layer M1] routing_direction horizontal
set_attribute [get_layer M2] routing_direction vertical
set_attribute [get_layer M3] routing_direction horizontal
set_attribute [get_layer M4] routing_direction vertical
set_attribute [get_layer M5] routing_direction horizontal
set_attribute [get_layer M7] routing_direction vertical
set_attribute [get_layer MB] routing_direction horizontal
set_attribute [get_layer MC] routing_direction vertical
set_attribute [get_layer ZA] routing_direction horizontal


################################################################################
# Routing Rules
################################################################################


# option added by compile_layer_aware_optimization edit if necessary
source ${_dirName__0}/routing_rule.lao.tcl
source ${_dirName__0}/routing_rule.tcl
source ${_dirName__0}/routing_rule.net.tcl
source ${_dirName__0}/routing_rule.layer.tcl
