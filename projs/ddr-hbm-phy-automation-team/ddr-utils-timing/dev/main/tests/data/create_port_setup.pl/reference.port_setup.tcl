# /depot/tcl8.6.6/bin/tclsh
# nolint Main
# nolint utils__script_usage_statistics
set NON_CLOCK_INPUTS { csrOdtSeg120PD[2:0] csrOdtSeg120PU[2:0] csrTxClkDcdMode[1:0] csrTxClkDcdOffset[4:0]
 }
set OUTPUTS { VIO_TIELO
 }
set INPUTS { csrOdtSeg120PD[2:0] csrOdtSeg120PU[2:0] csrTxClkDcdMode[1:0] csrTxClkDcdOffset[4:0]
 }
set INOUTS { VIO_PAD
 }
set POWERNET { VDD VDDQ
 }
