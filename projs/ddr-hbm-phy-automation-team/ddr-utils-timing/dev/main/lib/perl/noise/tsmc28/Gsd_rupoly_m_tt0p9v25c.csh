#!/bin/csh
cd .
module purge
module load hspice
hspice Gsd_rupoly_m_tt0p9v25c.sp > Gsd_rupoly_m_tt0p9v25c.log
