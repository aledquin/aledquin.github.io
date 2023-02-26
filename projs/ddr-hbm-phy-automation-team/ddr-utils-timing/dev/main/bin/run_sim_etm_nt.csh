#!/bin/csh
set toolname = `basename $0`
set prefix = "ddr-da-ddr-utils-timing-"
/remote/cad-rep/msip/tools/bin/msip_get_usage_info --tool_name "$prefix$toolname" --stage main --category ude_ext_1 --tool_path $0 --tool_version "2022ww23"

echo "queueing <CORNER> NanoTime run script"
nt_shell -f run.nt > report.rpt
if (-r ../src/Munge_nanotime.cfg) then
echo "Munging <CELL>_<CORNER>.lib"
../Munge_nanotime.pl -lib ./<CELL>_<METALSTACK>_<CORNER>.lib -c ../src/Munge_nanotime.cfg
ln -s ../timing/<DIR>/<CELL>_<METALSTACK>_<CORNER>_pg.libcleaned ../../libs/<CELL>_<METALSTACK>_<CORNER>_pg.lib
else
echo "Munge_nanotime.cfg doesn't exist"
endif
#qsub -P bnormal -A normal -l mem_free=2G -V -cwd -b y -N NT "nt_shell -f run.nt > timing.log"
#nt_shell -f run.nt

