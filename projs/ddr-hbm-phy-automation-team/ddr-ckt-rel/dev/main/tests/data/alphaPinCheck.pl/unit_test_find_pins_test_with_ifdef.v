
`timescale 1ps / 1ps

`celldefine
module dwc_lpddr5xphy_pclk_rptx1 (PclkIn, PclkOut 
`ifdef DWC_LPDDR5XPHY_PG_PINS
,VDD,VSS
`endif
);
    
   input PclkIn;
   output PclkOut;

`ifdef DWC_LPDDR5XPHY_PG_PINS
   input VDD;
   input VSS;
 

  

   bufif1 instp00  (PclkIn_org, 1'bx, ((VDD !== 1'b1) || (VSS !== 1'b0)));
   bufif0 instp10  (PclkIn_org, PclkIn, ((VDD !== 1'b1) || (VSS !== 1'b0)));



     
    buf instt0  (PclkOut, PclkIn_org);

 `else


     
    buf instt0  (PclkOut, PclkIn);

`endif
  
    specify
        (PclkIn +=> PclkOut)=(0, 0);	
    endspecify

endmodule


`endcelldefine
