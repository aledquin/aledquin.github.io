
#P10023532-44418
#source $env(MSIP_PROJ_ROOT)/alpha/alpha_common/bin/p4_hierarchal_tag.tcl
source $env(MSIP_PROJ_ROOT)/alpha/alpha_common/bin/alphaExtractUtils.tcl
##  Automatic tagging
alpha::lpe::setDefaultArg -type selectedNets tag {AutoGen-Successful SNE by the alphaRunExtract script}
alpha::lpe::setDefaultArg -type flat tag {AutoGen-Successful flat extract by the alphaRunExtract script}

