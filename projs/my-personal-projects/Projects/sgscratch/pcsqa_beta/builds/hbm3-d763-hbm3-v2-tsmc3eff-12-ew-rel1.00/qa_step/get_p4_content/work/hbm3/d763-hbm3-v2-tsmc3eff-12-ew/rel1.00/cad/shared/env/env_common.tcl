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

##P10023532-44492
## For MQA-SNPS check
db::createPref SNPSSourceFile -value "$env(PROJ_HOME)/cad/$env(METAL_STACK)/icv/SNPS/SNPS_sourceme" -description "The SNPS_Check source file" -defaultScope cell

set bboxList $env(PROJ_HOME)/design/bboxList.txt
if [file exists $bboxList] {
   db::createPref SNPSlowerLevelCellList -value $bboxList -description "Lower Level Cell List file needed for the SNPS check" -defaultScope cell
}

