#!/usr/bin/tclsh
#################################################################################################
#	THIS SCRIPT IS DESIGNED TO CREATE A STANDALONE NT TESTCASE IN THE TIMING DIRECTORIES	#
#	THE SCRIPT HAS TO BE RUN FROM EITHER Run_<PVT>_internal or Run_<PVT>_etm DIRECTORY	#
#	PLEASE RUN THE SCRIPT WITH -HELP OPTION TO SEE THE USAGE OF THE SCRIPT.			#
#	FOR ANY ISSUES PLEASE CONTACT DIKSHANT ROHATGI:dikshant@synopsys.com			#
#	Update(09/10/20):Added functionality to copy .dec files					#
#################################################################################################


proc utils__script_usage_statistics {toolname version} {
    set prefix "ddr-da"
    set reporter "/remote/cad-rep/msip/tools/bin/msip_get_usage_info"
    set cmd ""
	append cmd "$reporter --tool_name  ${prefix}${toolname} --stage main --category ude_ext_1 --tool_path 'NA' --tool_version \"$version\""
	
    exec sh -c $cmd
}
utils__script_usage_statistics "alpha_createNTtestcase" "2022ww25"



if {$argv eq "-help"} {
	puts "HELP::"
	puts "\tPlease run the script from Run_<PVT>_etm or Run_<PVT>_internal directory present at [pwd]"
	puts "\tFor example,Go inside [pwd]/Run_<PVT>_etm/internal directory\n\tRun the script inside the directory.\n\tThe script will create a Nt_testcase directory which will contain all the files required to run the testcase" 
	exit
} 

if {[catch {glob -type f *} var]} {
	puts "Error : Please use the -help option to see the usage of the script!\n"
	exit
}
set files [glob -type f *\.tcl]
regexp -all {run_nt.+\.tcl} $files files
set files [split $files " "]
set files [lindex $files 0]


set pw [pwd]
if {[regexp {internal} $pw]} {
	set rf "run_nt_internal.tcl"
} elseif {[regexp {etm} $pw] } {
	set rf "run_nt_etm.tcl"
}


set fp [open "$files" r]
set dir "./Nt_testcase"

file mkdir $dir

puts "Copying the following files to Nt_testcase directory\n"
set pv [open "$dir/$files" w+]
while { [gets $fp data] >= 0 } {
	if { [regexp "^#.*" $data] } { 
		puts $pv "$data" 
	} else {
		if { [regexp "source" $data] } {
			if { [regexp "if" $data] } { 
				puts $pv "$data" 
			} else {
				if { [ regexp {source\s+(.*)} $data all value]} {
					if { [ regexp {^\.\/} $value] } { 
						source $value;
						if { [info exists PROJ_HOME ] } {
						set val ${PROJ_HOME} }
						if { [ info exists PVT ] } {
						set pvt ${PVT} }
						if { [ info exists pocv_variation_param ] } {
						set ocv ${pocv_variation_param} }
						if { [ info exists vectorFile ] } {
						set vec $vectorFile }
					}
					if { [ regexp {^\$.*} $value ] } {
						if { [ regexp {\$\{PROJ_HOME\}} $value ] } {
							regsub {\$\{PROJ_HOME\}} $value $val value1
							set value $value1
						} elseif { [ regexp {\$\{pocv_variation_param\}} $value ] } {
							regsub {\$\{pocv_variation_param\}} $value $ocv value1
							set value $value1
							if { [ regexp {\$\{PVT\}} $value ] } {
								regsub {\$\{PVT\}} $value $pvt value1
								set value $value1
							} 
						} elseif { [ regexp {vectorFile} $value ] } {
							regsub vectorFile $value $vec value1
							set value $value1
							set value [ string trimleft $value $]
							set value [ string trim $value ]

						} else {
							regsub {\$.*} $value {} value1
							set value $value1
						}	
					} 
					if { [ file exists $value ] } {
						puts "Info : Copying $value to Nt_testcase";
						set l [split $value "/" ]
						set l1 [ lindex $l end ]
						if { [llength $l] == 2 && [lindex $l 0] == "."  } { 
							puts $pv "source ./$l1" 
						} else {
						puts $pv "source ./$l1"
						}
						set fl [open "$value" r]
						set fo [open "$dir/$l1" w+]
						while { [gets $fl data] >= 0 } {
							if { [regexp {dds_vec\.tcl} $value]} {
								if {[regexp {(.*\-vector)\s+(.+?)\s+(\[.*)} $data all startL vFile endL]} {
								exec cp $vFile $dir/
								set temp [lindex [split $vFile "/"] end]
								set data "$startL ./$temp $endL"
								}
							}	
   							puts $fo "$data"
						}
						close $fl
						close $fo
						
					} else { 
						if { [ string compare $value false ] == 0  } { 
							regsub -all -line {source } $data {} data							
							puts "Warning : This file/ Linked file to it  don't exists : $data - Mentioned in $rf , Ignoring the file for Copying"
							puts $pv "source $data" 
						 } else {
						puts "Warning : This file/ Linked file to it  don't exists : $value - Mentioned in $rf, Ignoring the file for Copying" 
						puts $pv "$data" }
					}
				}
			}
		} else {
			puts $pv "$data"
		}
	}
}
close $fp
set extra_file [ list netlist.sp netlist_sub.sp run_nt.csh nt_tech.sp ]

foreach i $extra_file {
	if { [ file exists $i ] } {
		puts "Info : Copying $i to Nt_testcase"
		set fl1 [open "$i" r]
		set fo1 [open "$dir/$i" w+]
		while { [gets $fl1 data] >= 0 } {
   			puts $fo1 "$data"
		}
		close $fl1
		close $fo1
	} else {
		puts "Warning : This file/ Linked file to it doen't exists :$i Ignoring the file for copying"
	}
}

#To copy required blackbox libs to particular corner 
set curdir [pwd]
set tempdir $curdir
set tdir [ split $tempdir "/" ] ; #To split the absolute path of directory
set corner [ lindex $tdir end ]
set crnr [ lindex [ split $corner "_" ] 1 ] ; #To get exact corner name

catch {cd ../../subckts}
catch {
set c_files [glob *.lib ]
set user_lib [list]
   foreach name $c_files {
	if { [ regexp $crnr $name ] } {
	if { [file exists $name ] } {
	puts "Info : Copying $name to Nt_testcase"
	set user_lib [ lappend user_lib $name ]
	set fl11 [ open "$name" r]
	set fo11 [ open "$curdir/Nt_testcase/$name" w+]
	while { [ gets $fl11 data ] >= 0 } {
		puts $fo11 "$data"	
	}
	close $fl11
	close $fo11
	}
	}
    }
catch { cd $curdir }

#----------------------------------------To modify user_lib_include.tcl as it includes relative path------------------------#
set final [list]
set final1 [list]
foreach lib $user_lib {
		set lib1 [split $lib "_"]
		set lib1 [lindex $lib1 0]
		if {[string compare $lib1 rx] ==0} {
			set lib1 rx_
		}
		set fl2 [ open "Nt_testcase/user_lib_include.tcl" r] ; 
		while {[gets $fl2 data] >= 0} {
			if { [regexp {link_path.\/.*} $data] } {
				lappend final $data
			} elseif { [regexp  $lib1 $data] } {
				 if {[regexp {link_path} $data]} {
					regsub {.*} $data "lappend link_path \"./$lib\"" data
					lappend final $data
				} elseif { [regexp {read_lib} $data] } {
					regsub {.*} $data "read_lib \"./$lib\"" data
					lappend final1 $data
				} 
			} elseif { [regexp {read_db.*} $data] } {
				lappend final1 $data
			}  
		} 

}
set newlist {}
foreach i $final {
	if {[lsearch -exact $newlist $i] == -1} {
		lappend newlist $i
	}
}	
set fl2 [ open "Nt_testcase/user_lib_include.tcl" w+] 
foreach f $newlist {
	puts $fl2 $f
}
close $fl2
set newlist {}
foreach i $final1 {
	if {[lsearch -exact $newlist $i] == -1} {
		lappend newlist $i
	}
}		
set fl2 [ open "Nt_testcase/user_lib_include.tcl" a] 
foreach f $newlist {
	puts $fl2 $f
}
close $fl2
} err
if { [string length $err] > 0} {
	puts "Warning : Couldn't find .libs in subckts directory, Not updating user_lib_include.tcl"
	puts "Info : Moved the updated $rf with copied files to Nt_tetscase directory"
	puts "Info : Please move to Nt_tetscase directory to run $rf with modified file structure"
} else {	
#---------------------------------------------------------------------------------------------#
puts "Info : Updated user_lib_include.tcl files with all relative paths for macros in Nt_testacse directory"
puts "Info : Moved the updated $rf with copied files to Nt_tetscase directory"
puts "Info : Please move to Nt_tetscase directory to $rf with modified file structure"
}


