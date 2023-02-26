set toolname = `basename $0`
set prefix = "ddr-da-ddr-utils-timing-"
/remote/cad-rep/msip/tools/bin/msip_get_usage_info --tool_name "$prefix$toolname" --stage main --category ude_ext_1 --tool_path $0 --tool_version "2022ww24"

setenv DK_MODELS /remote/cad-rep/fab/f123-GF/14nm/logic/LPP/models/verS00-V1.0.0.0/hspice

module unload hspice
module unload cx
module unload finesim
module unload xa
module unload nt
module unload pt

module load hspice
module load cx
module load finesim
module load xa
module load nt
module load pt

