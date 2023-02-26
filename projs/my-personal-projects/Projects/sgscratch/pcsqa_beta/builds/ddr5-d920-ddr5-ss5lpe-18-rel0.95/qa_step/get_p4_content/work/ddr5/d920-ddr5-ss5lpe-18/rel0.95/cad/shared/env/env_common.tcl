#===============================================================================
##COMMON BLOCK of env.tcl  
#===============================================================================

##File used to configure PV/HIPRE Mapping at PCS Level.

#if { [catch {db::createPref MSIPHIPREPvPrefixMappingConfFilePCS -value "$env(PROJ_HOME)/cad/shared/hipre/pv-prefix-hipre_mapping.conf"}] } { 
#	db::setPrefValue MSIPHIPREPvPrefixMappingConfFilePCS "$env(PROJ_HOME)/cad/shared/hipre/pv-prefix-hipre_mapping.conf" 
#}

##File used to configure PV/HIPRE Mapping at PCS Level. Please uncomment if your projec is a Child PCS.

#if { [catch {db::createPref MSIPHIPREPvPrefixMappingConfFileChildPCS -value "$env(PROJ_HOME)/cad/shared/hipre/pv-prefix-hipre_mapping.conf"}] } { 
#	db::setPrefValue MSIPHIPREPvPrefixMappingConfFileChildPCS "$env(PROJ_HOME)/cad/shared/hipre/pv-prefix-hipre_mapping.conf" 
#}
ude::pv::pvMenu -name "DRC"	            	   -prefix "DRC"	 	 -type "drc"   -extraCascade "Tapeout"    -mode "remove"
ude::pv::pvMenu -name "DRC"	            	   -prefix "DRC"	 	 -type "drc"   -extraCascade "Internal"    -mode "append"

