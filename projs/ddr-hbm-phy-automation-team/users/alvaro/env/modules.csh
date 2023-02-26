
if ($?USER == 0 || $?prompt == 0) exit

module use --append /remote/cad-rep/etc/modulefiles/msip

module unload msip_lynx_hipre
module   load msip_lynx_hipre/latest

module unload msip_shell_storage_utils
module   load msip_shell_storage_utils
      
module unload msip_shell_lay_utils
module   load msip_shell_lay_utils

module unload msip_shell_uge_utils
module   load msip_shell_uge_utils

module unload msip_hipre_lib_utils
module   load msip_hipre_lib_utils

module unload msip_hipre
module   load msip_hipre

module unload syn
module   load syn


# Common Tools

module unload git
module   load git/2.30.0

module unload vim
module   load vim

module unload tar
module   load tar






