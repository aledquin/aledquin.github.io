#!/bin/csh
set toolname = `basename $0`
set prefix = "ddr-da-ddr-utils-timing-"
/remote/cad-rep/msip/tools/bin/msip_get_usage_info --tool_name "$prefix$toolname" --stage main --category ude_ext_1 --tool_path $0 --tool_version "2022ww23"


set NTversion="nt"

##  The following allows local variables to be changed at runtime thus:  
##    run_int_etm.csh MODE=int
foreach arg ($argv)
    set $arg
end


module unload nt
module load $NTversion

nt_shell -f merge_nt.tcl > report.rpt
