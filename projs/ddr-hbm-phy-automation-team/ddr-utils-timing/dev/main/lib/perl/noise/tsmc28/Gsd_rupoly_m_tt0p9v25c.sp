*** Testing tt0p9v25c rupoly_m
.lib "/remote/cad-rep/projects/lpddr4mv2/d538-lpddr4mv2-tsmc28hpc18/rel1.00a/cad/models/hspice_mc/bjt.lib" bip_t
.lib "/remote/cad-rep/projects/lpddr4mv2/d538-lpddr4mv2-tsmc28hpc18/rel1.00a/cad/models/hspice_mc/cap.lib" cap_t
.lib "/remote/cad-rep/projects/lpddr4mv2/d538-lpddr4mv2-tsmc28hpc18/rel1.00a/cad/models/hspice_mc/diode.lib" dio_t
.lib "/remote/cad-rep/projects/lpddr4mv2/d538-lpddr4mv2-tsmc28hpc18/rel1.00a/cad/models/cvpp_models/NXTGRD_5x1z_ver1.1a/devices_tsmc28hp-18_CLUB28_pPDK_E201209-1-v3/cvpp/cvpp.lib" cvpp_t
.lib "/remote/cad-rep/projects/lpddr4mv2/d538-lpddr4mv2-tsmc28hpc18/rel1.00a/cad/models/hspice_mc/momcap.lib" momcap_t
.lib "/remote/cad-rep/projects/lpddr4mv2/d538-lpddr4mv2-tsmc28hpc18/rel1.00a/cad/models/hspice_mc/moscap_hv.lib" nmoscaphv_t
.lib "/remote/cad-rep/projects/lpddr4mv2/d538-lpddr4mv2-tsmc28hpc18/rel1.00a/cad/models/hspice_mc/moscap.lib" nmoscap_t
.lib "/remote/cad-rep/projects/lpddr4mv2/d538-lpddr4mv2-tsmc28hpc18/rel1.00a/cad/models/hspice_mc/mos_hv.lib" moshv_tt
.lib "/remote/cad-rep/projects/lpddr4mv2/d538-lpddr4mv2-tsmc28hpc18/rel1.00a/cad/models/hspice_mc/mos_hvt.lib" moshvt_tt
.lib "/remote/cad-rep/projects/lpddr4mv2/d538-lpddr4mv2-tsmc28hpc18/rel1.00a/cad/models/hspice_mc/mos_hvud12.lib" moshvud_tt
.lib "/remote/cad-rep/projects/lpddr4mv2/d538-lpddr4mv2-tsmc28hpc18/rel1.00a/cad/models/hspice_mc/mos_hvud.lib" moshvud_tt
.lib "/remote/cad-rep/projects/lpddr4mv2/d538-lpddr4mv2-tsmc28hpc18/rel1.00a/cad/models/hspice_mc/mos.lib" mos_tt
.lib "/remote/cad-rep/projects/lpddr4mv2/d538-lpddr4mv2-tsmc28hpc18/rel1.00a/cad/models/hspice_mc/mos_lvt.lib" moslvt_tt
.lib "/remote/cad-rep/projects/lpddr4mv2/d538-lpddr4mv2-tsmc28hpc18/rel1.00a/cad/models/hspice_mc/res.lib" res_t
vVDD VDD 0 dc 0.9
vVDD12 VDD12 0 dc 1.2
vVDD15 VDD15 0 dc 1.5
vVDD18 VDD18 0 dc 1.8
vVSS VSS 0 dc 0
Xdut_0 VSS T2_0 VSS rupoly_m lr=0.5u wr=0.5u  nf=1 rcoflag=1
vSource_0 T2_0 0 DC vsw
.measure DC i_0 find i(vSource_0) at=0.18000000000000002
.measure DC g_0 param 'abs(i_0/0.18000000000000002)'
.probe i(vSource_0)
Xdut_1 VSS T2_1 VSS rupoly_m lr=1.0u wr=0.5u  nf=1 rcoflag=1
vSource_1 T2_1 0 DC vsw
.measure DC i_1 find i(vSource_1) at=0.18000000000000002
.measure DC g_1 param 'abs(i_1/0.18000000000000002)'
.probe i(vSource_1)
Xdut_2 VSS T2_2 VSS rupoly_m lr=1.5u wr=0.5u  nf=1 rcoflag=1
vSource_2 T2_2 0 DC vsw
.measure DC i_2 find i(vSource_2) at=0.18000000000000002
.measure DC g_2 param 'abs(i_2/0.18000000000000002)'
.probe i(vSource_2)
Xdut_3 VSS T2_3 VSS rupoly_m lr=2.0u wr=0.5u  nf=1 rcoflag=1
vSource_3 T2_3 0 DC vsw
.measure DC i_3 find i(vSource_3) at=0.18000000000000002
.measure DC g_3 param 'abs(i_3/0.18000000000000002)'
.probe i(vSource_3)
Xdut_4 VSS T2_4 VSS rupoly_m lr=2.5u wr=0.5u  nf=1 rcoflag=1
vSource_4 T2_4 0 DC vsw
.measure DC i_4 find i(vSource_4) at=0.18000000000000002
.measure DC g_4 param 'abs(i_4/0.18000000000000002)'
.probe i(vSource_4)
Xdut_5 VSS T2_5 VSS rupoly_m lr=3.0u wr=0.5u  nf=1 rcoflag=1
vSource_5 T2_5 0 DC vsw
.measure DC i_5 find i(vSource_5) at=0.18000000000000002
.measure DC g_5 param 'abs(i_5/0.18000000000000002)'
.probe i(vSource_5)
Xdut_6 VSS T2_6 VSS rupoly_m lr=0.5u wr=1.0u  nf=1 rcoflag=1
vSource_6 T2_6 0 DC vsw
.measure DC i_6 find i(vSource_6) at=0.18000000000000002
.measure DC g_6 param 'abs(i_6/0.18000000000000002)'
.probe i(vSource_6)
Xdut_7 VSS T2_7 VSS rupoly_m lr=1.0u wr=1.0u  nf=1 rcoflag=1
vSource_7 T2_7 0 DC vsw
.measure DC i_7 find i(vSource_7) at=0.18000000000000002
.measure DC g_7 param 'abs(i_7/0.18000000000000002)'
.probe i(vSource_7)
Xdut_8 VSS T2_8 VSS rupoly_m lr=1.5u wr=1.0u  nf=1 rcoflag=1
vSource_8 T2_8 0 DC vsw
.measure DC i_8 find i(vSource_8) at=0.18000000000000002
.measure DC g_8 param 'abs(i_8/0.18000000000000002)'
.probe i(vSource_8)
Xdut_9 VSS T2_9 VSS rupoly_m lr=2.0u wr=1.0u  nf=1 rcoflag=1
vSource_9 T2_9 0 DC vsw
.measure DC i_9 find i(vSource_9) at=0.18000000000000002
.measure DC g_9 param 'abs(i_9/0.18000000000000002)'
.probe i(vSource_9)
Xdut_10 VSS T2_10 VSS rupoly_m lr=2.5u wr=1.0u  nf=1 rcoflag=1
vSource_10 T2_10 0 DC vsw
.measure DC i_10 find i(vSource_10) at=0.18000000000000002
.measure DC g_10 param 'abs(i_10/0.18000000000000002)'
.probe i(vSource_10)
Xdut_11 VSS T2_11 VSS rupoly_m lr=3.0u wr=1.0u  nf=1 rcoflag=1
vSource_11 T2_11 0 DC vsw
.measure DC i_11 find i(vSource_11) at=0.18000000000000002
.measure DC g_11 param 'abs(i_11/0.18000000000000002)'
.probe i(vSource_11)
Xdut_12 VSS T2_12 VSS rupoly_m lr=0.5u wr=1.5u  nf=1 rcoflag=1
vSource_12 T2_12 0 DC vsw
.measure DC i_12 find i(vSource_12) at=0.18000000000000002
.measure DC g_12 param 'abs(i_12/0.18000000000000002)'
.probe i(vSource_12)
Xdut_13 VSS T2_13 VSS rupoly_m lr=1.0u wr=1.5u  nf=1 rcoflag=1
vSource_13 T2_13 0 DC vsw
.measure DC i_13 find i(vSource_13) at=0.18000000000000002
.measure DC g_13 param 'abs(i_13/0.18000000000000002)'
.probe i(vSource_13)
Xdut_14 VSS T2_14 VSS rupoly_m lr=1.5u wr=1.5u  nf=1 rcoflag=1
vSource_14 T2_14 0 DC vsw
.measure DC i_14 find i(vSource_14) at=0.18000000000000002
.measure DC g_14 param 'abs(i_14/0.18000000000000002)'
.probe i(vSource_14)
Xdut_15 VSS T2_15 VSS rupoly_m lr=2.0u wr=1.5u  nf=1 rcoflag=1
vSource_15 T2_15 0 DC vsw
.measure DC i_15 find i(vSource_15) at=0.18000000000000002
.measure DC g_15 param 'abs(i_15/0.18000000000000002)'
.probe i(vSource_15)
Xdut_16 VSS T2_16 VSS rupoly_m lr=2.5u wr=1.5u  nf=1 rcoflag=1
vSource_16 T2_16 0 DC vsw
.measure DC i_16 find i(vSource_16) at=0.18000000000000002
.measure DC g_16 param 'abs(i_16/0.18000000000000002)'
.probe i(vSource_16)
Xdut_17 VSS T2_17 VSS rupoly_m lr=3.0u wr=1.5u  nf=1 rcoflag=1
vSource_17 T2_17 0 DC vsw
.measure DC i_17 find i(vSource_17) at=0.18000000000000002
.measure DC g_17 param 'abs(i_17/0.18000000000000002)'
.probe i(vSource_17)
Xdut_18 VSS T2_18 VSS rupoly_m lr=0.5u wr=2.0u  nf=1 rcoflag=1
vSource_18 T2_18 0 DC vsw
.measure DC i_18 find i(vSource_18) at=0.18000000000000002
.measure DC g_18 param 'abs(i_18/0.18000000000000002)'
.probe i(vSource_18)
Xdut_19 VSS T2_19 VSS rupoly_m lr=1.0u wr=2.0u  nf=1 rcoflag=1
vSource_19 T2_19 0 DC vsw
.measure DC i_19 find i(vSource_19) at=0.18000000000000002
.measure DC g_19 param 'abs(i_19/0.18000000000000002)'
.probe i(vSource_19)
Xdut_20 VSS T2_20 VSS rupoly_m lr=1.5u wr=2.0u  nf=1 rcoflag=1
vSource_20 T2_20 0 DC vsw
.measure DC i_20 find i(vSource_20) at=0.18000000000000002
.measure DC g_20 param 'abs(i_20/0.18000000000000002)'
.probe i(vSource_20)
Xdut_21 VSS T2_21 VSS rupoly_m lr=2.0u wr=2.0u  nf=1 rcoflag=1
vSource_21 T2_21 0 DC vsw
.measure DC i_21 find i(vSource_21) at=0.18000000000000002
.measure DC g_21 param 'abs(i_21/0.18000000000000002)'
.probe i(vSource_21)
Xdut_22 VSS T2_22 VSS rupoly_m lr=2.5u wr=2.0u  nf=1 rcoflag=1
vSource_22 T2_22 0 DC vsw
.measure DC i_22 find i(vSource_22) at=0.18000000000000002
.measure DC g_22 param 'abs(i_22/0.18000000000000002)'
.probe i(vSource_22)
Xdut_23 VSS T2_23 VSS rupoly_m lr=3.0u wr=2.0u  nf=1 rcoflag=1
vSource_23 T2_23 0 DC vsw
.measure DC i_23 find i(vSource_23) at=0.18000000000000002
.measure DC g_23 param 'abs(i_23/0.18000000000000002)'
.probe i(vSource_23)
Xdut_24 VSS T2_24 VSS rupoly_m lr=0.5u wr=2.5u  nf=1 rcoflag=1
vSource_24 T2_24 0 DC vsw
.measure DC i_24 find i(vSource_24) at=0.18000000000000002
.measure DC g_24 param 'abs(i_24/0.18000000000000002)'
.probe i(vSource_24)
Xdut_25 VSS T2_25 VSS rupoly_m lr=1.0u wr=2.5u  nf=1 rcoflag=1
vSource_25 T2_25 0 DC vsw
.measure DC i_25 find i(vSource_25) at=0.18000000000000002
.measure DC g_25 param 'abs(i_25/0.18000000000000002)'
.probe i(vSource_25)
Xdut_26 VSS T2_26 VSS rupoly_m lr=1.5u wr=2.5u  nf=1 rcoflag=1
vSource_26 T2_26 0 DC vsw
.measure DC i_26 find i(vSource_26) at=0.18000000000000002
.measure DC g_26 param 'abs(i_26/0.18000000000000002)'
.probe i(vSource_26)
Xdut_27 VSS T2_27 VSS rupoly_m lr=2.0u wr=2.5u  nf=1 rcoflag=1
vSource_27 T2_27 0 DC vsw
.measure DC i_27 find i(vSource_27) at=0.18000000000000002
.measure DC g_27 param 'abs(i_27/0.18000000000000002)'
.probe i(vSource_27)
Xdut_28 VSS T2_28 VSS rupoly_m lr=2.5u wr=2.5u  nf=1 rcoflag=1
vSource_28 T2_28 0 DC vsw
.measure DC i_28 find i(vSource_28) at=0.18000000000000002
.measure DC g_28 param 'abs(i_28/0.18000000000000002)'
.probe i(vSource_28)
Xdut_29 VSS T2_29 VSS rupoly_m lr=3.0u wr=2.5u  nf=1 rcoflag=1
vSource_29 T2_29 0 DC vsw
.measure DC i_29 find i(vSource_29) at=0.18000000000000002
.measure DC g_29 param 'abs(i_29/0.18000000000000002)'
.probe i(vSource_29)
Xdut_30 VSS T2_30 VSS rupoly_m lr=0.5u wr=3.0u  nf=1 rcoflag=1
vSource_30 T2_30 0 DC vsw
.measure DC i_30 find i(vSource_30) at=0.18000000000000002
.measure DC g_30 param 'abs(i_30/0.18000000000000002)'
.probe i(vSource_30)
Xdut_31 VSS T2_31 VSS rupoly_m lr=1.0u wr=3.0u  nf=1 rcoflag=1
vSource_31 T2_31 0 DC vsw
.measure DC i_31 find i(vSource_31) at=0.18000000000000002
.measure DC g_31 param 'abs(i_31/0.18000000000000002)'
.probe i(vSource_31)
Xdut_32 VSS T2_32 VSS rupoly_m lr=1.5u wr=3.0u  nf=1 rcoflag=1
vSource_32 T2_32 0 DC vsw
.measure DC i_32 find i(vSource_32) at=0.18000000000000002
.measure DC g_32 param 'abs(i_32/0.18000000000000002)'
.probe i(vSource_32)
Xdut_33 VSS T2_33 VSS rupoly_m lr=2.0u wr=3.0u  nf=1 rcoflag=1
vSource_33 T2_33 0 DC vsw
.measure DC i_33 find i(vSource_33) at=0.18000000000000002
.measure DC g_33 param 'abs(i_33/0.18000000000000002)'
.probe i(vSource_33)
Xdut_34 VSS T2_34 VSS rupoly_m lr=2.5u wr=3.0u  nf=1 rcoflag=1
vSource_34 T2_34 0 DC vsw
.measure DC i_34 find i(vSource_34) at=0.18000000000000002
.measure DC g_34 param 'abs(i_34/0.18000000000000002)'
.probe i(vSource_34)
Xdut_35 VSS T2_35 VSS rupoly_m lr=3.0u wr=3.0u  nf=1 rcoflag=1
vSource_35 T2_35 0 DC vsw
.measure DC i_35 find i(vSource_35) at=0.18000000000000002
.measure DC g_35 param 'abs(i_35/0.18000000000000002)'
.probe i(vSource_35)
.param vsw=0
.DC vsw 0 0.9 0.045
.option post=1
.option probe
.option measdgt=8
.end
