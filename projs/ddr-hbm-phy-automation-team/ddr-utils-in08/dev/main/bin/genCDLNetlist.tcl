proc utils__script_usage_statistics {toolname version} {
    set prefix "ddr-da-"
    set reporter "/remote/cad-rep/msip/tools/bin/msip_get_usage_info"
    set cmd ""
	append cmd "$reporter --tool_name  ${prefix}${toolname} --stage main --category ude_ext_1 --tool_path 'NA' --tool_version \"$version\""
	
    exec sh -c $cmd
}

utils__script_usage_statistics "genCDLNetlist" "2022ww15"


proc genCDL {libin args} {	
	set user $::env(USER)
	set lib [dm::getLibs $libin]
	set cir "/remote/cad-rep/projects/cad/c253-tsmc5ff-1.2v/rel9.2.0/cad/15M_1X_h_1Xb_v_1Xe_h_1Ya_v_1Yb_h_5Y_vhvhv_2Yy2Z/template/lvs.include.cdl"
	set prod $::env(MSIP_PRODUCT_NAME)
	set proj $::env(MSIP_PROJ_NAME)
	set rel $::env(MSIP_REL_NAME)
	set stack $::env(METAL_STACK)
	
	set libName [db::getAttr name -of $lib]
	set cells [dm::getCells * -lib $lib]
	
	db::foreach cell $cells {
		set cellName [db::getAttr name -of $cell]
		set var 0	
		if { [ lsearch $args $cellName] != -1} {
			catch {ude::genNetlist -libName "$libName" -cellName "$cellName" -netlistFormat CDL -runDir /u/$user/ -fileName "${cellName}.cdl" -viewSearchList "auCdl schematic symbol"} var
			puts "LIB $libName CELL $cellName"
			if {$var == 1} {
				puts "-I- Netlist generated for $cellName. Please check /u/$user/${cellName}.cdl"
			} else {
				puts "-E- Error: Couldn't generate netlist for $libName/$cellName due to $var"
			}

		} 	 
		
	}
}


proc genCDL_file {filename} {	
	set user $::env(USER)
	set cir "/remote/cad-rep/projects/cad/c253-tsmc5ff-1.2v/rel9.2.0/cad/15M_1X_h_1Xb_v_1Xe_h_1Ya_v_1Yb_h_5Y_vhvhv_2Yy2Z/template/lvs.include.cdl"
	set prod $::env(MSIP_PRODUCT_NAME)
	set proj $::env(MSIP_PROJ_NAME)
	set rel $::env(MSIP_REL_NAME)
	set stack $::env(METAL_STACK)
	
	set fid [open $filename r]
	
	while { [gets $fid line] >=0} {
		set libpat [lindex [split $line "="] 0]
		set cellpat [lindex [split  $line "="] 1]	
		set lib [dm::getLibs ${libpat} ]
		set libName [db::getAttr name -of $lib]
		set cells [dm::getCells ${cellpat} -lib $lib]
	
		db::foreach cell $cells {
			set cellName [db::getAttr name -of $cell]
			set var 0
			puts "LIB $libName CELL $cellName"	
			catch {ude::genNetlist -libName "$libName" -cellName "$cellName" -netlistFormat CDL -runDir /u/$user/ -fileName "${cellName}.cdl" -viewSearchList "auCdl schematic symbol"} var
			if {$var == 1} {
				puts "-I- Netlist generated for $cellName. Please check /u/$user/${cellName}.cdl"
			} else {
				puts "-E- Error: Couldn't generate netlist for $libName/$cellName due to $var"
			}

		}	 
		
	}
}
