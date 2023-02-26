#!/usr/bin/env  tcsh

#-------------------------------------------------------------------------------
# Author:  Manmit Muker
# Added to ddr-utils-lay July 2022
# For support, contact DDR DA team manager, Patrick Juliano

# Revision history:
# 2022ww38 - Fixed issue where area of shapes in subcells were only considered once. Fix uses bop layer.
#   - Enhancement to not include out of boundary shapes in density calculation.
#   - Enhancement for rectilinear boundary support. 
#-------------------------------------------------------------------------------

if ($#argv != 4) then
  echo Incorrect number of arguments.
  echo Usage: ddr-layer_density.tcsh \<GDS\> \<cell\> \<boundary layer\> \"\<layer\(s\)\>\"
  printf "\n"
  printf "%s \n" "-E- Incorrect number of arguments!"
  printf "\n"
  printf "%s \n" "-I- Usage: ddr-layer_density.tcsh <GDS> <cell> <boundary layer> <layer(s)>"
  printf "%s \n" "-I- Note: The <layer(s)> are cumulative list of layers to allow the addition"
  printf "%s \n" "    of BEOL fill layers to also be included in the total density. It should"
  printf "%s \n" "    be run individually for each layer required."
  printf "%s \n" "-I-   Example:"
  printf "%s \n" '        ddr-layer_density.tcsh dwc_ddrphyacx4_top_ew.gds.gz dwc_ddrphyacx4_top_ew 108:0 "45:80 45:81"'
  printf "\n"
  printf "%s \n\n" "-I- Correct above errors ... exiting!"
  exit 1;
endif

#-------------------------------------------------------------------------------
module unload icvwb
module load icvwb

# Create ICVWB script.
# Set find limit to unlimited.
echo default find_limit unlimited > icvwb_layer_density.mac

# Open layout and make editable.
echo layout open $1 $2 >> icvwb_layer_density.mac
echo cell edit_state 1 >> icvwb_layer_density.mac

# Find top level boundary area and create bop layer.
echo layout display filter_layer_hier 1 >> icvwb_layer_density.mac
echo layout display layer_hier_level 0 >> icvwb_layer_density.mac
echo find init -type shape -layer $3 >> icvwb_layer_density.mac
echo find table select \* >> icvwb_layer_density.mac
echo set boundary_area [shape area] >> icvwb_layer_density.mac
echo polygon -layer 10000:0 [cell object info boundary] >> icvwb_layer_density.mac
echo set boundaryBop [bop extract -layers 10000:0] >> icvwb_layer_density.mac

# Create bop layer for layers of interest.
echo layout display filter_layer_hier 0 >> icvwb_layer_density.mac
echo set layersBop [bop extract -layers \"$4\"] >> icvwb_layer_density.mac

# Remove shapes from bop layer that are outside boundary.
echo set layersBop [bop and \$layersBop \$boundaryBop] >> icvwb_layer_density.mac

# Find area of layers of interest.
echo bop insert \$layersBop 10001:0 >> icvwb_layer_density.mac
echo find init -type shape -layer 10001:0 >> icvwb_layer_density.mac
echo find table select \* >> icvwb_layer_density.mac
echo set layers_area [shape area] >> icvwb_layer_density.mac

# Calculate density.
echo set density [expr \$layers_area / \$boundary_area \* 100] >> icvwb_layer_density.mac
echo puts \"The density is \$density\" >> icvwb_layer_density.mac

echo exit >> icvwb_layer_density.mac

# Execute ICVWB script.
icvwb -run icvwb_layer_density.mac -nodisplay -log icvwb_layer_density.log

printf "%s \n" "-I- Done running ddr-layer_density.tcsh ... exiting."
exit 0;
