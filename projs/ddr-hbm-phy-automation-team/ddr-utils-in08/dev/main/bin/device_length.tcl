#Custom Compiler compliant script
#Used to generate netlist and calculate device length for NT blocks.
#Takes 2 input, bbox_list.txt and tag_xlsx
#Developed by Dikshant Rohatgi(dikshant@synopsys.com)


proc utils__script_usage_statistics {toolname version} {
    set prefix "ddr-da-"
    set reporter "/remote/cad-rep/msip/tools/bin/msip_get_usage_info"
    set cmd ""
    append cmd "$reporter --tool_name  ${prefix}${toolname} --stage main --category ude_ext_1 --tool_path 'NA' --tool_version \"$version\""

    exec sh -c $cmd
}


utils__script_usage_statistics "device_length" "2022.12"
set thisScript [file normalize [info script]]
proc devLen {execFile macroFile sheetname} {
    global thisScript
    set thisScriptDir [file dirname $thisScript]
    set op [exec "$thisScriptDir/readTagXlsx.py" -f $macroFile -s $sheetname]
    regexp -line {NT(.*)\|(.*)\n} $op var1 libs cells
    regexp -line {SiS(.*)\|(.*)} $op var2 libs2 cells2

    set libs_list [split  $libs ","]
    set cells_list [split $cells ","]
    #set cells_sis [split $cells2 ","]


    set path [pwd]
    if {[file isdirectory "devicelength"] } {
        file delete -force "./devicelength"
} 
file mkdir "devicelength"

set log [open "./devicelength/devicelen.log" w]
foreach cellName $cells_list libName $libs_list {
    set nl [nl::createNetlister mhspice3 -type hspice]
    set cv [dm::findCellView schematic -cellName $cellName -libName $libName]
    set status [catch {nl::runNetlister $nl -cellView $cv -filePath "./devicelength/${cellName}.sp" -viewSearchList "hspice hspiceD cmos.sch cmos_sch schematic veriloga"} var]
    puts $log "STATUS $status $var $libName/$cellName \n";
    if {$var == 1} {
        db::destroy $nl
        puts "-I- Netlist generated for $cellName, Removing SiS cells from $cellName.sp."
        puts $log "-I- Netlist generated for $cellName, Removing SiS cells from $cellName.sp."

        exec msip_schRemoveSubckts -in "./devicelength/${cellName}.sp" -traceCut2 -rmSubcktsList $cells2
        puts "-I- Removed SiS cells from $cellName.sp.\n"
        puts $log "-I- Removed SiS cells from $cellName.sp.\n"


        puts  "-I- Running Device length script on $cellName.sp."
        puts $log "-I- Running Device length script on $cellName.sp."
        exec  "$thisScriptDir/devicelen.py" -s "$path/devicelength/${cellName}.sp" -e $execFile

        puts "-I- Done. Please check '${path}/devicelength/project_devicelen.txt'"
        puts $log "-I- Done. Please check '${path}/devicelength/project_devicelen.txt'"
        } else {
            db::destroy $nl
            puts "-E- Error: Couldn't generate netlist for $libName/$cellName due to $var"
            puts $log "-E- Error: Couldn't generate netlist for $libName/$cellName due to $var"
        }
}
set fid [open "./devicelength/project_devicelen.txt" r+]
set proj [lindex [split $path "/"] end-2]
set fout [open "./devicelength/${proj}_devicelen.txt" w+]
set dev [dict create]
while {[gets $fid line]!=-1} {
    if {[string equal $line ''] == 0} {
        if {[regexp "^#" $line]} {continue}
        set lst [split $line ","]
        set device [lindex $lst 0]
        for {set i 1} {$i< [llength $lst]} {incr i} {
            set len [lindex $lst $i]

            if {[dict exists $dev $device] == 0} {
                dict lappend dev $device $len
                continue
        }
        if { [string equal [dict get $dev $device] $len] } {
            continue
        } else {
            if {$len ni [dict get $dev $device]} {
                dict lappend dev $device $len
            }
        }
    }
    }	
}

foreach {key value} $dev { puts $fout "$key,$value" }

close $log
close $fid
close $fout
#file delete "./devicelength/project_devicelen.txt"
}





