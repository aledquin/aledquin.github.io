********************************************************************************
* Library          : POCV
* Cell             : inverter
* View             : schematic
* View Search List : veriloga hspice hspiceD schematic symbol
* View Stop List   :
********************************************************************************
.subckt inverter a out vdd vss 
*.PININFO a:I out:O vdd:I vss:I
xmP1 out a vdd vdd pmos_type l=Xn nfin=1  nf=1 multi=1 ccosflag=1 ccodflag=1
+ rgflag=1 rcosflag=1 rcodflag=1 dfm_flag=1 
xmN1 out a vss vss nmos_type l=Xn nfin=1  nf=1 multi=1 ccosflag=1 ccodflag=1
+ rgflag=1 rcosflag=1 rcodflag=1 dfm_flag=1 
.ends inverter
********************************************************************************
* Library          : POCV
* Cell             : NAND_2
* View             : schematic
* View Search List : veriloga hspice hspiceD schematic symbol
* View Stop List   :
********************************************************************************
.subckt NAND_2 a b out vdd vss
*.PININFO a:I b:I out:O vdd:I vss:I
xmn3 net13 b vss vss nmos_type l=Xn nfin=1  nf=1 multi=1 ccosflag=1 ccodflag=1
+ rgflag=1 rcosflag=1 rcodflag=1 dfm_flag=1
xmn0 out a net13 vss nmos_type l=Xn nfin=1  nf=1 multi=1 ccosflag=1 ccodflag=1
+ rgflag=1 rcosflag=1 rcodflag=1 dfm_flag=1
xmp2 out b vdd vdd pmos_type l=Xn nfin=1  nf=1 multi=1 ccosflag=1 ccodflag=1
+ rgflag=1 rcosflag=1 rcodflag=1 dfm_flag=1
xmp1 out a vdd vdd pmos_type l=Xn nfin=1  nf=1 multi=1 ccosflag=1 ccodflag=1
+ rgflag=1 rcosflag=1 rcodflag=1 dfm_flag=1
.ends NAND_2



********************************************************************************
* Library          : POCV
* Cell             : NAND_3
* View             : schematic
* View Search List : veriloga hspice hspiceD schematic symbol
* View Stop List   :
********************************************************************************
.subckt NAND_3 a b c out vdd vss
*.PININFO a:I b:I c:I out:O vdd:I vss:I
xmn4 net4 c net5 vss nmos_type l=Xn nfin=1  nf=1 multi=1 ccosflag=1 ccodflag=1
+ rgflag=1 rcosflag=1 rcodflag=1 dfm_flag=1
xmn3 net5 b vss vss nmos_type l=Xn nfin=1  nf=1 multi=1 ccosflag=1 ccodflag=1
+ rgflag=1 rcosflag=1 rcodflag=1 dfm_flag=1
xmn0 out a net4 vss nmos_type l=Xn nfin=1  nf=1 multi=1 ccosflag=1 ccodflag=1
+ rgflag=1 rcosflag=1 rcodflag=1 dfm_flag=1
xmp3 out c vdd vdd pmos_type l=Xn nfin=1  nf=1 multi=1 ccosflag=1 ccodflag=1
+ rgflag=1 rcosflag=1 rcodflag=1 dfm_flag=1
xmp2 out b vdd vdd pmos_type l=Xn nfin=1  nf=1 multi=1 ccosflag=1 ccodflag=1
+ rgflag=1 rcosflag=1 rcodflag=1 dfm_flag=1
xmp1 out a vdd vdd pmos_type l=Xn nfin=1  nf=1 multi=1 ccosflag=1 ccodflag=1
+ rgflag=1 rcosflag=1 rcodflag=1 dfm_flag=1
.ends NAND_3


********************************************************************************
* Library          : POCV
* Cell             : NAND_4
* View             : schematic
* View Search List : veriloga hspice hspiceD schematic symbol
* View Stop List   :
********************************************************************************
.subckt NAND_4 a b c d out vdd vss
*.PININFO a:I b:I c:I d:I out:O vdd:I vss:I
xmn1 net7 d net6 vss nmos_type l=Xn nfin=1  nf=1 multi=1 ccosflag=1 ccodflag=1
+ rgflag=1 rcosflag=1 rcodflag=1 dfm_flag=1
xmn4 net6 c net2 vss nmos_type l=Xn nfin=1  nf=1 multi=1 ccosflag=1 ccodflag=1
+ rgflag=1 rcosflag=1 rcodflag=1 dfm_flag=1
xmn3 net2 b vss vss nmos_type l=Xn nfin=1  nf=1 multi=1 ccosflag=1 ccodflag=1
+ rgflag=1 rcosflag=1 rcodflag=1 dfm_flag=1
xmn0 out a net7 vss nmos_type l=Xn nfin=1  nf=1 multi=1 ccosflag=1 ccodflag=1
+ rgflag=1 rcosflag=1 rcodflag=1 dfm_flag=1
xmp0 out d vdd vdd pmos_type l=Xn nfin=1  nf=1 multi=1 ccosflag=1 ccodflag=1
+ rgflag=1 rcosflag=1 rcodflag=1 dfm_flag=1
xmp3 out c vdd vdd pmos_type l=Xn nfin=1  nf=1 multi=1 ccosflag=1 ccodflag=1
+ rgflag=1 rcosflag=1 rcodflag=1 dfm_flag=1
xmp2 out b vdd vdd pmos_type l=Xn nfin=1  nf=1 multi=1 ccosflag=1 ccodflag=1
+ rgflag=1 rcosflag=1 rcodflag=1 dfm_flag=1
xmp1 out a vdd vdd pmos_type l=Xn nfin=1  nf=1 multi=1 ccosflag=1 ccodflag=1
+ rgflag=1 rcosflag=1 rcodflag=1 dfm_flag=1
.ends NAND_4


********************************************************************************
* Library          : POCV
* Cell             : NOR_2
* View             : schematic
* View Search List : veriloga hspice hspiceD schematic symbol
* View Stop List   :
********************************************************************************
.subckt NOR_2 a b out vdd vss
*.PININFO a:I b:I out:O vdd:I vss:I
xmn3 out b vss vss nmos_type l=Xn nfin=1  nf=1 multi=1 ccosflag=1 ccodflag=1
+ rgflag=1 rcosflag=1 rcodflag=1 dfm_flag=1
xmn0 out a vss vss nmos_type l=Xn nfin=1  nf=1 multi=1 ccosflag=1 ccodflag=1
+ rgflag=1 rcosflag=1 rcodflag=1 dfm_flag=1
xmp0 net5 b vdd vdd pmos_type l=Xn nfin=1  nf=1 multi=1 ccosflag=1 ccodflag=1
+ rgflag=1 rcosflag=1 rcodflag=1 dfm_flag=1
xmp1 out a net5 vdd pmos_type l=Xn nfin=1  nf=1 multi=1 ccosflag=1 ccodflag=1
+ rgflag=1 rcosflag=1 rcodflag=1 dfm_flag=1
.ends NOR_2


********************************************************************************
* Library          : POCV
* Cell             : NOR_3
* View             : schematic
* View Search List : veriloga hspice hspiceD schematic symbol
* View Stop List   :
********************************************************************************
.subckt NOR_3 a b c out vdd vss
*.PININFO a:I b:I c:I out:O vdd:I vss:I
xmn1 out c vss vss nmos_type l=Xn nfin=1  nf=1 multi=1 ccosflag=1 ccodflag=1
+ rgflag=1 rcosflag=1 rcodflag=1 dfm_flag=1
xmn3 out b vss vss nmos_type l=Xn nfin=1  nf=1 multi=1 ccosflag=1 ccodflag=1
+ rgflag=1 rcosflag=1 rcodflag=1 dfm_flag=1
xmn0 out a vss vss nmos_type l=Xn nfin=1  nf=1 multi=1 ccosflag=1 ccodflag=1
+ rgflag=1 rcosflag=1 rcodflag=1 dfm_flag=1
xmp2 net6 c net5 vdd pmos_type l=Xn nfin=1  nf=1 multi=1 ccosflag=1 ccodflag=1
+ rgflag=1 rcosflag=1 rcodflag=1 dfm_flag=1
xmp0 net5 b vdd vdd pmos_type l=Xn nfin=1  nf=1 multi=1 ccosflag=1 ccodflag=1
+ rgflag=1 rcosflag=1 rcodflag=1 dfm_flag=1
xmp1 out a net6 vdd pmos_type l=Xn nfin=1  nf=1 multi=1 ccosflag=1 ccodflag=1
+ rgflag=1 rcosflag=1 rcodflag=1 dfm_flag=1
.ends NOR_3


********************************************************************************
* Library          : POCV
* Cell             : NOR_4
* View             : schematic
* View Search List : veriloga hspice hspiceD schematic symbol
* View Stop List   :
********************************************************************************
.subckt NOR_4 a b c d out vdd vss
*.PININFO a:I b:I c:I d:I out:O vdd:I vss:I
xmn2 out d vss vss nmos_type l=Xn nfin=1  nf=1 multi=1 ccosflag=1 ccodflag=1
+ rgflag=1 rcosflag=1 rcodflag=1 dfm_flag=1
xmn1 out c vss vss nmos_type l=Xn nfin=1  nf=1 multi=1 ccosflag=1 ccodflag=1
+ rgflag=1 rcosflag=1 rcodflag=1 dfm_flag=1
xmn3 out b vss vss nmos_type l=Xn nfin=1  nf=1 multi=1 ccosflag=1 ccodflag=1
+ rgflag=1 rcosflag=1 rcodflag=1 dfm_flag=1
xmn0 out a vss vss nmos_type l=Xn nfin=1  nf=1 multi=1 ccosflag=1 ccodflag=1
+ rgflag=1 rcosflag=1 rcodflag=1 dfm_flag=1
xmp3 net6 d net5 vdd pmos_type l=Xn nfin=1  nf=1 multi=1 ccosflag=1 ccodflag=1
+ rgflag=1 rcosflag=1 rcodflag=1 dfm_flag=1
xmp2 net5 c net1 vdd pmos_type l=Xn nfin=1  nf=1 multi=1 ccosflag=1 ccodflag=1
+ rgflag=1 rcosflag=1 rcodflag=1 dfm_flag=1
xmp0 net1 b vdd vdd pmos_type l=Xn nfin=1  nf=1 multi=1 ccosflag=1 ccodflag=1
+ rgflag=1 rcosflag=1 rcodflag=1 dfm_flag=1
xmp1 out a net6 vdd pmos_type l=Xn nfin=1  nf=1 multi=1 ccosflag=1 ccodflag=1
+ rgflag=1 rcosflag=1 rcodflag=1 dfm_flag=1
.ends NOR_4

********************************************************************************
* Library          : POCV
* Cell             : top
* View             : schematic
* View Search List : veriloga hspice hspiceD schematic symbol
* View Stop List   :
********************************************************************************
.subckt top a b c d out vdd vss
*.PININFO a:I b:I c:I d:I out:O vdd:I vss:I
Xinv1 a out vdd vss inverter
Xnand2 a b out vdd vss NAND_2
Xnand3 a b c out vdd vss NAND_3
Xnand4 a b c d out vdd vss NAND_4
Xnor2 a b out vdd vss NOR_2
Xnor3 a b c out vdd vss NOR_3
Xnor4 a b c d out vdd vss NOR_4
.ends top

