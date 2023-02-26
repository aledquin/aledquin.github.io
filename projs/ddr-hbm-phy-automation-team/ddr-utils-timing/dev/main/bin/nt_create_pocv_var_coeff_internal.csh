#!/bin/csh
set toolname = `basename $0`
set prefix = "ddr-da-ddr-utils-timing-"
/remote/cad-rep/msip/tools/bin/msip_get_usage_info --tool_name "$prefix$toolname" --stage main --category ude_ext_1 --tool_path $0 --tool_version "2022ww24"

set MODE=batch
set NTversion="nt"
set QUEUE=normal
set MEM=2G
set VMEM=35G
set EXTRASGEARGS=""
set hspice_ver="NA"

##  The following allows local variables to be changed at runtime thus:  
##    run_int_etm.csh MODE=int
foreach arg ($argv)
    set $arg
end

set e="`echo $argv|egrep 'HSPICE'`"
if ($status == 0) then
	 set hspice_ver="`echo $arg|sed -sr 's/.+\=(.+)/\1/g'`"
endif


##  These files are used for tracking the status of the run without constantly querying qstat

module unload nt
module load $NTversion
module load tcl/8.6.4

if ($hspice_ver == "NA") then
    if ($MODE == "int") then
        rm -f statusPOCV_generation_Queued
        touch statusPOCV_generation_Running
        nt_shell -f nt_gen_pocv_variation_num_coeff.tcl > POCV_generation.rpt
        rm -f statusPOCV_generation_Running
        touch statusPOCV_generation_Complete
    endif

    if ($MODE == "batch") then
        unsetenv LS_COLORS
      
        qsub -P bnormal -A $QUEUE -l mem_free=$MEM,h_vmem=$VMEM $EXTRASGEARGS -V -cwd -b y -N NT -e POCV_generation.err -o POCV_generation.out "rm -f statusPOCV_generation_Queued; touch statusPOCV_generation_Running; nt_gen_pocv_variation_num_coeff.tcl > POCV_generation.log; rm -f statusPOCV_generation_Running; touch statusPOCV_generation_Complete"

    endif
else
    if ($MODE == "int") then
        rm -f statusPOCV_generation_Queued
        touch statusPOCV_generation_Running
        nt_shell -f nt_gen_pocv_variation_num_coeff.tcl $hspice_ver > POCV_generation.rpt
        rm -f statusPOCV_generation_Running
        touch statusPOCV_generation_Complete
    endif

    if ($MODE == "batch") then
        unsetenv LS_COLORS
      
        qsub -P bnormal -A $QUEUE -l mem_free=$MEM,h_vmem=$VMEM $EXTRASGEARGS -V -cwd -b y -N NT -e POCV_generation.err -o POCV_generation.out "rm -f statusPOCV_generation_Queued; touch statusPOCV_generation_Running; nt_gen_pocv_variation_num_coeff.tcl $hspice_ver > POCV_generation.log; rm -f statusPOCV_generation_Running; touch statusPOCV_generation_Complete"

    endif
endif
