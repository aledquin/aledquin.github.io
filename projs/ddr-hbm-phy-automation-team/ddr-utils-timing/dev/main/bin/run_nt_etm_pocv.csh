#!/bin/csh
set toolname = `basename $0`
set prefix = "ddr-da-ddr-utils-timing-"
/remote/cad-rep/msip/tools/bin/msip_get_usage_info --tool_name "$prefix$toolname" --stage main --category ude_ext_1 --tool_path $0 --tool_version "2022ww24"


set MODE=batch
set NTversion="nt"
set QUEUE=normal
set MEM=2G
set VMEM=35G
set SISversion="siliconsmart"
set EXTRASGEARGS=""



##  The following allows local variables to be changed at runtime thus:  
##    run_int_etm.csh MODE=int
foreach arg ($argv)
    set $arg
end

##  These files are used for tracking the status of the run without constantly querying qstat
module unload siliconsmart
module load $SISversion

module unload nt
module load $NTversion

if ($MODE == "int") then
    rm -f statusQueued
    touch statusRunning
    nt_shell -f run_nt_etm.tcl > report_etm.rpt
    rm -f statusRunning
    touch statusComplete
endif

if ($MODE == "batch") then
    unsetenv LS_COLORS
    qsub -P bnormal -A $QUEUE -l mem_free=$MEM,h_vmem=$VMEM $EXTRASGEARGS -V -cwd -b y -N NT -e NT.err -o NT.out "rm -f statusQueued; touch statusRunning; nt_shell -f run_nt_etm.tcl > timing.log; rm -f statusRunning; touch statusComplete; touch statusSIDEFILEstart; siliconsmart  gen_pocvSideFile.tcl > siliconsmart.log;  rm -f statusSIDEFILEstart; touch statusSIDEFILEComplete"
endif
