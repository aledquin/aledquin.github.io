#!/bin/bash

source /remote/cad-rep/etc/.bashrc

module unload msip_lynx_pcsqa

 module load msip_lynx_pcsqa/2022.06-beta

/bin/rm -rf /slowfs/dcopt103/alvaro/sgscratch/pcsqa_beta/.rtm_shell.lock
pcsqa /slowfs/dcopt103/alvaro/sgscratch/pcsqa_beta/pcsqaFile_20220718161326750203