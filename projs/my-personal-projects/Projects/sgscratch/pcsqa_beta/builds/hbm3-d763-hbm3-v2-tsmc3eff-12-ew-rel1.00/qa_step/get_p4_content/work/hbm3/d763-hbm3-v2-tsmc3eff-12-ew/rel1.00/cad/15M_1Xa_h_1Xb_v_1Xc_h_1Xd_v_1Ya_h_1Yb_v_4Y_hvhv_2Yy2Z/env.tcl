source $env(MSIP_PROJ_ROOT)/cad/$env(MSIP_CAD_PROJ_NAME)/$env(MSIP_CAD_REL_NAME)/cad/$env(METAL_STACK)/env.tcl

if { [file exists "$env(PROJ_HOME)/cad/shared/env/env_common.tcl"] } {
	de::sendMessage "Sourcing PCS mstack common customization - START"
	source "$env(PROJ_HOME)/cad/shared/env/env_common.tcl"
	de::sendMessage "Sourcing PCS mstack common customization - END"
}

##
## If necessary add PCS customization code below
##
