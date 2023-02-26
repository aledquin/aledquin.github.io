#!/bin/bash

source /remote/cad-rep/etc/.bashrc

module unload msip_lynx_pcsqa

 module load msip_lynx_pcsqa

/bin/rm -rf /slowfs/dcopt103/alvaro/sgscratch/pcsqa/.rtm_shell.lock
pcsqa /slowfs/dcopt103/alvaro/sgscratch/pcsqa/pcsqaFile_20220722153826318990