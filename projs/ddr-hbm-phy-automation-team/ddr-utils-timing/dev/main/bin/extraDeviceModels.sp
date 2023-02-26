*************************************************************************************************************
*  Hack to work around model problem
*  This model is used in the egncap model, but is implemented as verilog-A, which NT does not support.
*  This allows NT to run, but egncap's capacitance model will be wrong.  Most of the time, this only affects
*  decaps.  Cases which use this where it will affect timing should characterize some other way.
.subckt egmosvarcap A B
.ends egmosvarcap
*************************************************************************************************************
