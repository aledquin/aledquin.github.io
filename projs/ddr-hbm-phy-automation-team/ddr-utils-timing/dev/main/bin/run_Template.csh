#!/bin/tcsh

##### This is a tempalate for "run_{macro_name}.csh. 
set toolname = `basename $0`
set prefix = "ddr-da-ddr-utils-timing-"
/remote/cad-rep/msip/tools/bin/msip_get_usage_info --tool_name "$prefix$toolname" --stage main --category ude_ext_1 --tool_path $0 --tool_version "2022ww26"


##### Please update the "Technology_name" accordingly, like d930, d569 etc.
##### Tool version {Siliconsmart, Finesim/ Hspice etc.}
##### -pvtNum  1,2,3,4 

set runfile = `pwd`
set MACRO = `basename $runfile`
#note: if you want a non-standard location, just overwrite the MACRO var

   ../common_source/alphaSiSpvtRunSeparate.pl \
    -macro ${MACRO} \
    -commonSetup ../common_source/commonSetup.tcl \
    -pvtconfig  ../common_source/SiS_configure_{Technology_name}_pvt.tcl \
    -config ../common_source/configure_{Technology_name}.tcl \
    -netlist ${MACRO}.spf \
    -inst  ${MACRO}.inst \
    -runscript run_${MACRO}.tcl \
    -postProc ${MACRO}_postproc.tcl \
    -libDir ./ \
    -siliconsmartVersion 2019.06-3 \
    -finesimVersion 2021.09-SP1 \
    -submit \
    -nomail \
    -qsubArgs "-A normal" \
    -pvtNum {total number of PVTs separated by commma. 1,2,3,4}

