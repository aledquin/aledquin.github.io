#Script to setup verification files for multiple cells

proc utils__script_usage_statistics {toolname version} {
    set prefix "ddr-da-"
    set reporter "/remote/cad-rep/msip/tools/bin/msip_get_usage_info"
    set cmd ""
	append cmd "$reporter --tool_name  ${prefix}${toolname} --stage main --category ude_ext_1 --tool_path 'NA' --tool_version \"$version\""
	
    exec sh -c $cmd
}

#utils__script_usage_statistics "pv_all" "2022ww16"


set prod $::env(MSIP_PRODUCT_NAME)
set proj $::env(MSIP_PROJ_NAME)
set rel $::env(MSIP_REL_NAME)
set stack $::env(METAL_STACK)




proc verif_run {type prefix user libName cell1} {
	set prod $::env(MSIP_PRODUCT_NAME)
	set proj $::env(MSIP_PROJ_NAME)
	set rel $::env(MSIP_REL_NAME)
	set stack $::env(METAL_STACK)

	

	set log [open "/u/$user/${type}_all.csh" w]
	puts $log "#!/bin/csh"
	puts $log "module unload msip_cd_pv"
	
	set pv $::env(MSIP_CD_PV)
	set pv [lindex [split $pv "/"] end]
	
	puts $log "module load msip_cd_pv/$pv"
        
	if {$type == "drc" } {
	 puts $log "pvbatch  --projectType $prod --projectName $proj --releaseName $rel  --metalStack $stack  --type $type --prefix $prefix  --libName $libName --cellName $cell1  --tool icv --config /u/$user/run_all_drc.config --grid"
	} else {
	 puts $log "pvbatch  --projectType $prod --projectName $proj --releaseName $rel  --metalStack $stack  --type $type --prefix $prefix  --libName $libName --cellName $cell1  --tool icv --config /u/$user/run_all_lvs.config --grid"
	}

	close $log
	exec chmod +x "/u/$user/${type}_all.csh"

}



proc runSetup {pre libin args} {
	set user $::env(USER)
	set lib [dm::getLibs $libin]
	set cellList [list]
	set prod $::env(MSIP_PRODUCT_NAME)
	set proj $::env(MSIP_PROJ_NAME)
	set rel $::env(MSIP_REL_NAME)
	set stack $::env(METAL_STACK)
	set vri ""
	if {[lsearch $args "-virtual"] != -1} {
	    set idx [lsearch $args "-virtual"]
		set vri [lindex $args $idx+1]
		set args [lreplace $args $idx $idx+1]
		set vri [string toupper $vri]	
	}
	if {[lsearch $args "-fill"] != -1} {
	    set idx [lsearch $args "-fill"]
		set fill [lindex $args $idx+1]
		set args [lreplace $args $idx $idx+1]
		set fill [string toupper $fill]	
	}
	
	if { [string equal -nocase $pre "int"] || [string equal -nocase $pre "internal"]} {
		set lvs_prefix "LVSINT"
		set drc_prefix "DRCINT"
	} elseif { [string equal -nocase $pre "tapeout"] } {
		set lvs_prefix "LVS"
		set drc_prefix "DRC"
		
	} else {
		puts "-E- Error, no prefix specified, Please use either tapeout or int"
		return
	}	



	set libName [db::getAttr name -of $lib]
	
	foreach cll $args {
		set cell [dm::getCells $cll -lib $lib]

	
		db::foreach cell $cell {
			set cellName [db::getAttr name -of $cell]
			lappend cellList $cellName
		}
	}


	set fid1 [open "/u/$user/run_all_drc.config" w]
	set fid2 [open "/u/$user/run_all_lvs.config" w]
	
	#setting CellList
	puts -nonewline $fid1 "set cellNameList \"" 
	puts -nonewline $fid1 [join $cellList " "]
	puts -nonewline $fid2 "set cellNameList \"" 
	puts -nonewline $fid2 [join $cellList " "]
	puts $fid1 "\""
	puts $fid2 "\""
	
	#setting scratch path
	set pth $::env(udescratch)
	append pth "/$user/verification/$prod/$proj/$rel/$stack/$libName"
	set pth "set rundir \{$pth\}"
	puts $fid1 $pth
	puts $fid2 $pth
	
	#setting virtual connect
	puts $fid1 "set virtualConnect \{$vri\}"
	puts $fid2 "set virtualConnect \{$vri\}"
	
	
	#setting grid option
	puts $fid1 "set useGrid \{1\}"
	puts $fid2 "set useGrid \{1\}"
		
     if {$fill == "fill"}  {
	     puts $fid1 "set enableDRCFilling \{1\}"
	     puts $fid1 "set enableFEOLFilling \{1\}"
	     puts $fid1 "set enableBEOLFilling \{1\}"
	}

	close $fid1
	close $fid2

	
	verif_run "drc" $drc_prefix  $user $libName [lindex $cellList 0]
	puts "-I- DRC setup done. Please check /u/$user/drc_all.csh"
	verif_run "lvs" $lvs_prefix  $user $libName [lindex $cellList 0]
	puts "-I- LVS setup done. Please check /u/$user/lvs_all.csh"
	
#	puts "-I- Running DRC run script"
#	exec "/u/$user/drc_all.csh"
#	puts "-I- DRC run script ended"
	
#	puts "-I- Running LVS run script"
#	exec "/u/$user/lvs_all.csh"
#	puts "-I- LVS run script ended"

	

}


