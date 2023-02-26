

`timescale 1ps/1ps


module dwc_ddrphy_por (
input         Reset_X,            
output wire   PwrOk_VIO,         
output wire   PwrOkDlyd_VIO,     
input         SetDCTSanePulse,    
input         ClrPORMemReset,     
input         DCTMemReset,        
input         DFTDatSel,          


input         PwrOk_VMEMP, 
input         PwrOkDlyd, 

output wire   PORMemReset,
output wire   DCTSane,
`ifdef DWC_DDRPHY_ATPG_MODEL
output wire   MemResetLPullUp_VIO,    
output wire   MemResetLPullDown_VIO,
`else
output reg    MemResetLPullUp_VIO,    
output reg    MemResetLPullDown_VIO,  
`endif

input         VDDQ,
input         VSS,
input         VDD
);

`ifdef DWC_DDRPHY_ATPG_MODEL
  assign PwrOk_VIO                = 1'b1;
  assign PwrOkDlyd_VIO            = 1'b1;
  assign PORMemReset              = 1'b1;
  assign DCTSane = (SetDCTSanePulse) ? 1'b1 : (~Reset_X) ? 1'b0 : 1'bx; 
  assign MemResetLPullUp_VIO      = ~DCTMemReset;
  assign MemResetLPullDown_VIO    = DCTMemReset;
`else




wire Reset_VIO;
wire SetDCTSanePulse_VIOX;
wire ClrPORMemReset_VIOX;
wire ClrPORMemResetInt_VIOX;
wire DCTMemReset_VIOX;
wire DFTDatSel_VIOX;

wire Reset_VIOX;
wire SetDCTSanePulse_VIO;
wire ClrPORMemReset_VIO;
wire DCTMemReset_VIO;
wire DFTDatSel_VIO;
wire DCTSane_VIO;
reg  PORMemReset_VIO;

wire  VMEMP_Ok_VIO;
wire  PwrOk_int_VIOX;
wire  PwrOk_int_VIO;
wire  PwrOkDlyd_int_VIOX;

wire PwrOk_VIOX;
assign PwrOk_VIOX = ~PwrOk_VIO;



dwc_ddrphy_lsilhne1 LS_RESET_VIOX          (.out_vpwr2_l(Reset_VIO           ), .in_vpwr1(Reset_X        ), .vpwr1pwrok_vpwr2(PwrOk_int_VIO), .VPWR1(VDD), .VPWR2(VDDQ), .VSS(VSS));
dwc_ddrphy_lsilhne1 LS_SETDCTSANEPULSE_VIO (.out_vpwr2_l(SetDCTSanePulse_VIOX), .in_vpwr1(SetDCTSanePulse), .vpwr1pwrok_vpwr2(PwrOk_int_VIO), .VPWR1(VDD), .VPWR2(VDDQ), .VSS(VSS));
dwc_ddrphy_lsilhne1 LS_CLRPORMEMRESET_VIO  (.out_vpwr2_l(ClrPORMemReset_VIOX ), .in_vpwr1(ClrPORMemReset ), .vpwr1pwrok_vpwr2(PwrOk_int_VIO), .VPWR1(VDD), .VPWR2(VDDQ), .VSS(VSS));
dwc_ddrphy_lsilhne1 LS_DFTDATSEL_VIO       (.out_vpwr2_l(DFTDatSel_VIOX      ), .in_vpwr1(DFTDatSel      ), .vpwr1pwrok_vpwr2(PwrOk_int_VIO), .VPWR1(VDD), .VPWR2(VDDQ), .VSS(VSS));
dwc_ddrphy_lsilhne0 LS_DCTMEMRESET_VIO     (.out_vpwr2_l(DCTMemReset_VIOX    ), .in_vpwr1(DCTMemReset    ), .vpwr1pwrok_vpwr2(PwrOk_int_VIO), .VPWR1(VDD), .VPWR2(VDDQ), .VSS(VSS));


assign ClrPORMemResetInt_VIOX = (~VMEMP_Ok_VIO | ClrPORMemReset_VIOX )
                              ? 1'b1
                              : ( (~ClrPORMemReset_VIOX & VMEMP_Ok_VIO)  ? 1'b0 : 1'bx);

assign Reset_VIOX          = ~Reset_VIO           ;
assign SetDCTSanePulse_VIO = ~SetDCTSanePulse_VIOX;
assign ClrPORMemReset_VIO  = ~ClrPORMemResetInt_VIOX ;
assign DCTMemReset_VIO     = ~DCTMemReset_VIOX    ;
assign DFTDatSel_VIO       = ~DFTDatSel_VIOX      ;






dwc_ddrphy_gls I_DCTSane_VIO ( 
.S(SetDCTSanePulse_VIO),
.R(~Reset_VIOX),
.Q(DCTSane_VIO)
);




`ifndef DWC_DDRPHY_SIMPLE_MODEL
initial begin
  PORMemReset_VIO <= 1'b1;
end
`endif

wire VMEMIO_dlyd;
assign #1 VMEMIO_dlyd = VDDQ;

always @* begin
`ifndef DWC_DDRPHY_SIMPLE_MODEL
  if (~(VMEMIO_dlyd^~VMEMIO_dlyd)|~VMEMIO_dlyd) 
    PORMemReset_VIO <= 1'b1;
  else 
`endif
  if (ClrPORMemReset_VIO)
    PORMemReset_VIO <= 1'b0;
end



reg FinalMemReset_VIO;
always @* FinalMemReset_VIO = (DCTSane_VIO | DFTDatSel_VIO) ? DCTMemReset_VIO : PORMemReset_VIO;

always @* MemResetLPullUp_VIO   = ~FinalMemReset_VIO;
always @* MemResetLPullDown_VIO =  FinalMemReset_VIO;  






wire PwrOk_VMEMP_aft;
wire PwrOkDlyd_aft;
wire VMEMP_aft;

assign #1 PwrOk_VMEMP_aft = PwrOk_VMEMP;
assign #1 PwrOkDlyd_aft   = PwrOkDlyd;
assign #1 VMEMP_aft       = VDD;

dwc_ddrphy_ams_powersniffer dwc_ddrphy_ams_powersniffer (
   .VDDIN            (VDD), 
   .VDDOUT           (VDDQ), 
   .VSS              (VSS), 
   .VDDINOk          (VMEMP_Ok_VIO) 
   );

dwc_ddrphy_lsilheq1rst LS_PWROK_INT_VIOX (
   .out_vpwr2_l      (PwrOk_int_VIOX ),
   .in_vpwr1         (PwrOk_VMEMP_aft),   
   .vpwr1pwrok_vpwr2 (VMEMP_Ok_VIO),      
   .VPWR1            (VMEMP_aft),         
   .VPWR2            (VDDQ),
   .VSS              (VSS)
   ); 
   
assign   PwrOk_int_VIO =  ~PwrOk_int_VIOX;
assign   PwrOk_VIO     =   PwrOk_int_VIO;    


dwc_ddrphy_lsilheq1rst LS_PWROKDlyd_INT_VIOX (
   .out_vpwr2_l      (PwrOkDlyd_int_VIOX ),
   .in_vpwr1         (PwrOkDlyd_aft),     
   .vpwr1pwrok_vpwr2 (VMEMP_Ok_VIO),      
   .VPWR1            (VMEMP_aft),         
   .VPWR2            (VDDQ),
   .VSS              (VSS)
   ); 
   
assign   PwrOkDlyd_VIO =  ~PwrOkDlyd_int_VIOX;   
   

dwc_ddrphy_lsihlne0 LS_DCTSANE_VMEMP     (.out_vpwr2_l(DCTSane    ), .in_vpwr1(~DCTSane_VIO    ), .vpwr1pwrok_vpwr2(PwrOk_VMEMP), .VPWR1(VDDQ), .VPWR2(VDD), .VSS(VSS));
dwc_ddrphy_lsihlne0 LS_PORMEMRESET_VMEMP (.out_vpwr2_l(PORMemReset), .in_vpwr1(~PORMemReset_VIO), .vpwr1pwrok_vpwr2(PwrOk_VMEMP), .VPWR1(VDDQ), .VPWR2(VDD), .VSS(VSS));

`endif 

endmodule 
