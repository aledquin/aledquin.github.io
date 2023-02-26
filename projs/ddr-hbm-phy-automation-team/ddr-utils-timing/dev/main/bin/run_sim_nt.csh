set toolname = `basename $0`
set prefix = "ddr-da-ddr-utils-timing-"
/remote/cad-rep/msip/tools/bin/msip_get_usage_info --tool_name "$prefix$toolname" --stage main --category ude_ext_1 --tool_path $0 --tool_version "2022ww23"

echo "queueing <CORNER> NanoTime run script"
nt_shell -f run.nt > report.rpt

#qsub -P bnormal -A normal -l mem_free=2G -V -cwd -b y -N NT "nt_shell -f run.nt > timing.log"
#nt_shell -f run.nt
