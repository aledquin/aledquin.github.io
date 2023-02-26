Contact info:
Sergey Chatrchyan (sergeych)

Description:
Script to trace nets in a layout database using ICV. Nets are specified with their netname. Netnames can be labels in the layout database or provided in an edtext file. Standard SNPS net names are considered by default.
ICV run directory is created in <cellname>/missing_Pin. VUE file can be loaded with ICWB, ICWBEV, Custom Compiler, etc.

Files:
-exec_missing_pin.tcl - Main script file to run from terminal.
-GDS_floating_pin_New_script_flow.pdf - Manual 

Usage:
exec_missing_pin.tcl -layout <GDS/OAS file> -cell <cellname> -layermap <layermap file> [-layout_format <GDS|OAS>] [-bot_metal <lowest metal number to include for connectivity>] [-text_depth <depth, where 0 is top>] [-icv_version <version>] [-grid] [-cores <cores>] [-mem <memory>] [-fab_node <fabNode>] [-nets "<net1> <net2> ..."] [-edtext <edtext file>]


Required arguments:
-cell <cellname> - Cellname for the cell whose nets are being traced.
-layermap <layermap file> - Custom Compiler layermap file for the technology node.
-layout <GDS/OAS file> - GDS/OAS layout database containing the cell whose nets are being traced.


Optional arguments:
-bot_metal <lowest metal number to include for connectivity> - Sets the bottom metal to consider for connectivity. For example, to only trace nets using M7 and above, specify "-bot_metal 7". Default is 1.
-text_depth <depth> - Set how deep in the hierarchy to use texts for identifying nets. Default is 0, which is the top cell.
-cores <cores> - Specify the number of cores to use for the ICV job, i.e., sets the ICV -host_init argument. Also requests the number of cores for the grid if the -grid argument is used. Default is 1.
-grid - Switch to run ICV job on the grid. Default is to run ICV on the local machine.
-icv_version <version> - To specify a particular ICV version to use. Default is the latest version available.
-layout_format <GDS|OAS> - Layout database format. Default is GDS.
-mem <memory> - Specify the amount of memory for a grid job. Only relevant if used in conjunction with the -grid argument. Default is 50G.
-fab_node <fabNode> - additional parameter to support TS05 or TS03 streamout layer maps. Possible values  tsmc05(*) or tsmc03(*) where * means non-mandatory extention
-nets "<net1> <net2> ..." - List of net names to trace, enclosed in quotation marks and separated by a space. Default is "VAA VDD VDDQ VDDQLP VSS".
-edtext <edtext file> - File to specify additional labels that are not in the layout database. Useful to trace internal nets that are not pinned at the top level. See edtext_sample for required format. Note that nets must also be specified with the -nets argument.
