**To measure the average currents through VDD, VDD2 in lp3 mode

.include '../circuit/project/dwc_lpddr5xphy_txrxcs_ew_post.dat'
*.include '/remote/cad-rep/projects/lpddr5x/d931-lpddr5x-tsmc3ff-12/rel1.00_cktpcs/design/15M_1X_h_1Xb_v_1Xc_h_1Xd_v_1Ya_h_1Yb_v_4Y_hvhv_2Yy2Z/netlist/sim/pro_lp5x_bitslice/dwc_lpddr5xphy_txrxcs_ew/dwc_lpddr5xphy_txrxcs_ew_tsmc3ff.sp'
*.include '/remote/cad-rep/projects/lpddr5x/d931-lpddr5x-tsmc3ff-12/rel1.00_cktpcs/design/15M_1X_h_1Xb_v_1Xc_h_1Xd_v_1Ya_h_1Yb_v_4Y_hvhv_2Yy2Z/netlist/extract/dwc_lpddr5xphy_txrxcs_ew/rcxt/checkout/abhinit/dwc_lpddr5xphy_txrxcs_ew_rcc_typical_15M_1X_h_1Xb_v_1Xc_h_1Xd_v_1Ya_h_1Yb_v_4Y_hvhv_2Yy2Z.spf'

.title TITLE
.lib 'MODELLIB' VARIANT
$---- finesim options for DQ-------------------------------------
.option post_version=2001
.option finesim_mode=spicead
** set output to tr0
.option finesim_output=tr0
.option finesim_dceffort=3
.options finesim_maxicout=0
.options probe dcon=1
$--- options ----------------------------------------------------------------
.option post=0
.option probe
.option accurate
.option dcon=1


$--------parameters----------------------------------------------------------
.TEMP 25
.param vdd_core= 0.75
.param vdd2val =1.05

.param freq= 4267Meg
.param tclk=(1/freq)
.param tr=20p
.param vdifp = vdd_core
.param vdifn = 0
.param vref = vdd_core/2
.param vrefq = vdd2val/2

.param txoeeven=0
.param txoeodd=0
.param coreloopbackmode =0
.param txbypassmodeint =0
.param txbypassoeint=0
.param txbypassdataint=0
.param txbypassmodeext =0
.param txbypassoeext=0
.param txbypassdataext=0
.param vio_forcedata=0
.param vio_forceenable=1
.param txmodectl2=0
.param txmodectl1=0
.param txmodectl0=0
.param txpowerdown1=0
.param txpowerdown0=0
.param iddq_mode=0
.param scan_mode=0

.param vio_pwrok=0

.param rxbypassen=0
.param rxbypassrcven=0

.param crdl=600f

Vtxoeeven txoeeven 0 (txoeeven*vdd_core)
Vtxoeodd txoeodd 0 (txoeodd*vdd_core)
VCoreloopbackmode csrcoreloopbackmode 0 (coreloopbackmode*vdd_core)

VTxbypassmodeint txbypassmodeint 0 (txbypassmodeint*vdd_core)
VTxbypassoeint txbypassoeint 0 (txbypassoeint*vdd_core)
VTxbypassdataint txbypassdataint 0 (txbypassdataint*vdd_core)

VTxbypassmodeext txbypassmodeext 0 (txbypassmodeext*vdd_core)
VTxbypassoeext txbypassoeext 0 (txbypassoeext*vdd_core)
VTxbypassdataext txbypassdataext 0 (txbypassdataext*vdd_core)

vvioforcedata vio_forcedata 0 (vio_forcedata*vdd2val)
vvioforceenable vio_forceenable 0 (vio_forceenable*vdd2val)
vrxbypassen rxbypasspaden 0 (rxbypassen*vdd_core)

vrxbypassrcven rxbypassrcven 0 (rxbypassrcven*vdd_core)

vscanmode scan_mode 0 (scan_mode*vdd_core)

viddqmode iddq_mode 0 (iddq_mode*vdd_core)
vvio_pwrok vio_pwrok 0 (vio_pwrok*vdd2val)

.param typsegR=50
.if (typsegR==400 )
vtxsegpu<3> csrtxseg120pu<3> 0 0
vtxsegpu<2> csrtxseg120pu<2> 0 0
vtxsegpu<1> csrtxseg120pu<1> 0 0
vtxsegpu<0> csrtxseg120pu<0> 0 vdd_core

vtxsegpd<3> csrtxseg120pd<3> 0 0
vtxsegpd<2> csrtxseg120pd<2> 0 0
vtxsegpd<1> csrtxseg120pd<1> 0 0
vtxsegpd<0> csrtxseg120pd<0> 0 vdd_core

.elseif (typsegR==100 )
vtxsegpu<3> csrtxseg120pu<3> 0 0
vtxsegpu<2> csrtxseg120pu<2> 0 0
vtxsegpu<1> csrtxseg120pu<1> 0 vdd_core
vtxsegpu<0> csrtxseg120pu<0> 0 vdd_core

vtxsegpd<3> csrtxseg120pd<3> 0 0
vtxsegpd<2> csrtxseg120pd<2> 0 0
vtxsegpd<1> csrtxseg120pd<1> 0 vdd_core
vtxsegpd<0> csrtxseg120pd<0> 0 vdd_core

.elseif (typsegR==66 )
vtxsegpu<3> csrtxseg120pu<3> 0 0
vtxsegpu<2> csrtxseg120pu<2> 0 vdd_core
vtxsegpu<1> csrtxseg120pu<1> 0 vdd_core
vtxsegpu<0> csrtxseg120pu<0> 0 vdd_core

vtxsegpd<3> csrtxseg120pd<3> 0 0
vtxsegpd<2> csrtxseg120pd<2> 0 vdd_core
vtxsegpd<1> csrtxseg120pd<1> 0 vdd_core
vtxsegpd<0> csrtxseg120pd<0> 0 vdd_core

.elseif (typsegR==50)
vtxsegpu<3> csrtxseg120pu<3> 0 vdd_core
vtxsegpu<2> csrtxseg120pu<2> 0 vdd_core
vtxsegpu<1> csrtxseg120pu<1> 0 vdd_core
vtxsegpu<0> csrtxseg120pu<0> 0 vdd_core

vtxsegpd<3> csrtxseg120pd<3> 0 vdd_core
vtxsegpd<2> csrtxseg120pd<2> 0 vdd_core
vtxsegpd<1> csrtxseg120pd<1> 0 vdd_core
vtxsegpd<0> csrtxseg120pd<0> 0 vdd_core

.endif


Vvdd vdd 0 vdd_core
Vvddq_vdd2h vdd2h 0 vdd2val
Vvss vss 0 0
Vvref vref 0 vref
Vvrefq vrefq 0 vrefq

XP BurnIn IDDQ_mode RxBypassData<1>
+ RxBypassData<0> RxBypassDataPad RxBypassPadEn RxBypassRcvEn RxClk RxDataEven
+ RxDataOdd RxFwdClkT RxPowerDown RxStrobeEn TIEHI TIELO TxBypassDataExt
+ TxBypassDataInt TxBypassModeExt TxBypassModeInt TxBypassOEExt TxBypassOEInt
+ TxClk TxClkDcdOut TxClkDcdSampleClk TxDataEven TxDataOdd TxFwdClk TxOEEven
+ TxOEOdd VDD VDD2H VIO_ForceData VIO_ForceEnable VIO_PAD VIO_PwrOk VIO_RxAcVref
+  VIO_TIEHI VIO_TIELO VSS csrCoreLoopBackMode csrRxAttenCtrl<3>
+ csrRxAttenCtrl<2> csrRxAttenCtrl<1> csrRxAttenCtrl<0> csrTxClkDcdMode<1>
+ csrTxClkDcdMode<0> csrTxClkDcdOffset<4> csrTxClkDcdOffset<3>
+ csrTxClkDcdOffset<2> csrTxClkDcdOffset<1> csrTxClkDcdOffset<0>
+ csrTxSeg120PD<3> csrTxSeg120PD<2> csrTxSeg120PD<1> csrTxSeg120PD<0>
+ csrTxSeg120PU<3> csrTxSeg120PU<2> csrTxSeg120PU<1> csrTxSeg120PU<0> scan_mode
+ scan_shift_cg dwc_lpddr5xphy_txrxcs_ew

Cpad vio_pad 0 c=crdl

vrxclk rxclk 0 0 
vrxpd rxpowerdown 0 vdd_core
vrxstrb rxstrobeen 0 0 
vrxref vio_rxacvref 0 vdd2val/6

vrxatt3 csrRxAttenCtrl<3> 0 0
vrxatt2 csrRxAttenCtrl<2> 0 0
vrxatt1 csrRxAttenCtrl<1> 0 vdd_core
vrxatt0 csrRxAttenCtrl<0> 0 vdd_core

vdcdmode1 csrTxClkDcdMode<1> 0 0
vdcdmode0 csrTxClkDcdMode<0> 0 0

vdcdoffset4 csrTxClkDcdOffset<4> 0 0
vdcdoffset3 csrTxClkDcdOffset<3> 0 0
vdcdoffset2 csrTxClkDcdOffset<2> 0 0
vdcdoffset1 csrTxClkDcdOffset<1> 0 0
vdcdoffset0 csrTxClkDcdOffset<0> 0 0

vscan_shift scan_shift_cg 0 0



VTxClk      TxClk      0 0 
VTxDataEven  TxDataEven  0 0
VTxDataOdd   TxDataOdd   0 0

*** initial condition
.ic v(XP.xfecs.xfecore.xfe_deq.xdata_slice.XIPuSer.XIdatFFEven.SFBN) = 'vdd_core'
.ic v(XP.xfecs.xfecore.xfe_deq.xdata_slice.XIPuSer.XIdatFFOdd.SFBN)  = 'vdd_core'
.ic v(XP.xfecs.xfecore.xfe_deq.xdata_slice.XIPDSer.XIdatFFEven.SFBN) = 'vdd_core'
.ic v(XP.xfecs.xfecore.xfe_deq.xdata_slice.XIPDSer.XIdatFFOdd.SFBN)  = 'vdd_core'

.ic v(XP.xfecs.xfecore.xfe_deq.xdata_slice.XIPuSer.XIdatFFEven.SFB)  = 0
.ic v(XP.xfecs.xfecore.xfe_deq.xdata_slice.XIPuSer.XIdatFFOdd.SFB)   = 0
.ic v(XP.xfecs.xfecore.xfe_deq.xdata_slice.XIPDSer.XIdatFFEven.SFB)  = 0
.ic v(XP.xfecs.xfecore.xfe_deq.xdata_slice.XIPDSer.XIdatFFOdd.SFB)   = 0

.ic v(XP.xfecs.xfecore.xfe_deq.xdata_slice.XIPuSer.XIdatFFEven.MFBN) = 'vdd_core'
.ic v(XP.xfecs.xfecore.xfe_deq.xdata_slice.XIPuSer.XIdatFFOdd.MFBN)  = 'vdd_core'
.ic v(XP.xfecs.xfecore.xfe_deq.xdata_slice.XIPDSer.XIdatFFEven.MFBN) = 'vdd_core'
.ic v(XP.xfecs.xfecore.xfe_deq.xdata_slice.XIPDSer.XIdatFFOdd.MFBN)  = 'vdd_core'

.ic v(XP.xfecs.xfecore.xfe_deq.xdata_slice.XIPuSer.XIdatFFEven.MFB)  = 0
.ic v(XP.xfecs.xfecore.xfe_deq.xdata_slice.XIPuSer.XIdatFFOdd.MFB)   = 0
.ic v(XP.xfecs.xfecore.xfe_deq.xdata_slice.XIPDSer.XIdatFFEven.MFB)  = 0
.ic v(XP.xfecs.xfecore.xfe_deq.xdata_slice.XIPDSer.XIdatFFOdd.MFB)   = 0

****Rx initial condition
.ic v(xp.xrxcs.xiafe.xiodd.sampn_p)= 0
.ic v(xp.xrxcs.xiafe.xiodd.sampp_p)= vdd_core
.ic v(xp.xrxcs.xiafe.xieven.sampn_p)= vdd_core
.ic v(xp.xrxcs.xiafe.xieven.sampp_p)= 0

.ic v(xp.xrxcs.xiafe.xiodd.qint) =vdd_core
.ic v(xp.xrxcs.xiafe.xiodd.qintx) =0
.ic v(xp.xrxcs.xiafe.xieven.qint) =0
.ic v(xp.xrxcs.xiafe.xieven.qintx)=vdd_core

.ic v(xp.xrxcs.xievenflop1.mfb) = 0
.ic v(xp.xrxcs.xievenflop1.mfbn)= vdd_core
.ic v(xp.xrxcs.xievenflop1.sfb) = 0
.ic v(xp.xrxcs.xievenflop1.sfbn)= vdd_core
.ic v(xp.xrxcs.xievenflop2.mfb) = vdd_core
.ic v(xp.xrxcs.xievenflop2.mfbn)= 0
.ic v(xp.xrxcs.xievenflop2.sfb) = vdd_core
.ic v(xp.xrxcs.xievenflop2.sfbn)= 0

.ic v(xp.xrxcs.xioddflop1.mfb) = 0
.ic v(xp.xrxcs.xioddflop1.mfbn)= vdd_core
.ic v(xp.xrxcs.xioddflop1.sfb) = 0
.ic v(xp.xrxcs.xioddflop1.sfbn)= vdd_core
.ic v(xp.xrxcs.xioddflop2.mfb) = vdd_core
.ic v(xp.xrxcs.xioddflop2.mfbn)= 0
.ic v(xp.xrxcs.xioddflop2.sfb) = vdd_core
.ic v(xp.xrxcs.xioddflop2.sfbn)= 0

.param dcck_flag=0
.if (dcck_flag ==1)
.include '../include/dynamic_circuit_check.inc'
*.include '../include/dynamic_circuit_check_powerdown.inc'
.endif
******************* Measures *****************
.meas tran iviopad_avg         avg par('(isub(vio_pad))')      from 'meas_begin' to 'meas_end'
.meas tran iviopad_rms         rms isub(vio_pad)                  from 'meas_begin' to 'meas_end'

.meas tran ixpvdd_avg_ua         avg par('(isub(XP.vdd))') 		from 'meas_begin' to 'meas_end'
.meas tran ixpvdd2_avg_ua        avg par('(isub(XP.vdd2h))') 		from 'meas_begin' to 'meas_end'
.meas tran ixpvss_avg_ua         avg par('-(isub(XP.vss))') 		from 'meas_begin' to 'meas_end'
.meas tran ixppad_avg_ua         avg par('-(isub(vio_pad))') 		from 'meas_begin' to 'meas_end'
.meas tran ixpvdd_rms_ua         rms ('abs(isub(XP.vdd))') 		from 'meas_begin' to 'meas_end'
.meas tran ixpvdd2_rms_ua        rms ('abs(isub(XP.vdd2h))') 		from 'meas_begin' to 'meas_end'
.meas tran ixpvss_rms_ua         rms ('abs(isub(XP.vss))')  		from 'meas_begin' to 'meas_end'
.meas tran ixppad_rms_ua         rms ('abs(isub(vio_pad))')  		from 'meas_begin' to 'meas_end'

$$$ final report value
.meas tran ivdd_avg param='ixpvdd_avg_ua'
.meas tran ivdd2h_avg param='ixpvdd2_avg_ua'
.meas tran ipad_avg param='ixppad_avg_ua'
.meas tran ivdd_rms param='ixpvdd_rms_ua'
.meas tran ivdd2_rms param='ixpvdd2_rms_ua'
.meas tran ipad_rms param='ixppad_rms_ua'

.param meas_begin   = '3*tclk/2'
.param meas_end     = '15*tclk/2'
$--- analysis ---------------------------------------------------------------
.tran .01n '10*tclk' 
.end
