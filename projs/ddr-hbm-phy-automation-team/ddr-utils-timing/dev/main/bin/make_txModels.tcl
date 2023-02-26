#!/usr/local/bin/tclsh 
proc utils__script_usage_statistics {toolname version} {
    set prefix "ddr-da-"
    set reporter "/remote/cad-rep/msip/tools/bin/msip_get_usage_info"
    set cmd ""
    set script_dirname [file dirname [file normalize [info script]]]
    append cmd "$reporter --tool_name  \"${prefix}${toolname}\" "
    append cmd "--stage main --category ude_ext_1 "
    append cmd "--tool_path \"$script_dirname\" --tool_version \"$version\""

    exec sh -c $cmd
}

set script_name [file tail [file rootname [file normalize [info script]]]]
utils__script_usage_statistics $script_name "2022ww24"

proc get_model {hspicemodel} {
set i 0
set j 0
if  [catch {set RDnetlist [open $hspicemodel "r"]}] {puts "Error:  Cannot open $hspicemodel for read\n"}
while {[gets $RDnetlist line] >= 0 } {
	if {[regexp -nocase {^.model\s+(.*).global\s+nmos} $line int model ]} {
		set ntransistor($j) $model
		if {[regexp -nocase {lmin(.*)lmax} $line length ]} {
		set nlengthtransistor($j) $length
		}
		set j [expr $j+1]	
		
		
		}	
	if {[regexp -nocase {^.model\s+(.*).global\s+pmos} $line int model ]} {
		set ptransistor($i) $model
		if {[regexp -nocase {lmin(.*)lmax} $line length ]} {
		set plengthtransistor($i) $length
		}
		set i [expr $i+1]
		}	
			}
	
close $RDnetlist

if  [catch {set userfile [open userFile "w"]}] {puts "Error:  Cannot open userFile for read\n"}
for {set i 0} {$i < [array size ptransistor]} {incr i} {
puts $userfile "$ptransistor($i)  $ntransistor($i)"
}


close $userfile

}

get_model [lindex $argv 0]
