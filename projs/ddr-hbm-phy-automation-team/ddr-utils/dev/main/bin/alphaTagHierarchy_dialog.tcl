#!/depot/tk8.6.1/bin/wish

##  This script it used to handle interactive dialogs used by the alphaTagHierarchy.tcl script.
## 

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
utils__script_usage_statistics $script_name "2022ww16" 

proc errorOut {message} {
    puts "ERROR $message"
    exit
}

proc doIgnoreAndProceed {} {
    ##  Ignore button pressed
    puts "IGNORE"
    exit
}

proc doSync {} {
    ##  Sync button
    global selectedTag
    set ver [lindex $selectedTag 0]
    puts "SYNC  $ver"
    exit
}

proc doProceed {} {
    ##  Sync button
    puts "PROCEED"
    exit
}

proc doClose {} {
    ##  Sync button
    puts "CLOSE"
    exit
}

proc doAbort {} {
    ##  Abort button was pressed
    puts "ABORT"
    exit
}


if {$argc < 2} {ErrorOut "Usage:  alphaTagHierarchy_dialog.tcl type configFile"}

set type [lindex $argv 0]
set configFile [lindex $argv 1]
if [file exists $configFile] {
    ##  Read config file
    source $configFile
} else {errorOut "Config file \"$config\" not found"}

wm geometry . +200+200
if [info exists title] {wm title . $title}

if {$type == "errorReview"} {
    ##  Using to review errors.
    if {![info exists errorList]} {errorOut "errorList array not defined"}
    frame .bf
    pack [button .bf.ignoreAndProceed -text "IgnoreAndProceed" -command "doIgnoreAndProceed"] -side left
    pack [button .bf.cancel -text "Abort" -command "doAbort"] -side left
    pack .bf -side top

    frame .ef
    canvas .ef.cnv -width 1500 -height 500 -yscrollcommand [list .ef.yscroll set] -xscrollcommand [list .ef.xscroll set]
    scrollbar .ef.xscroll -orient horizontal -command [list .ef.cnv xview]
    scrollbar .ef.yscroll -orient vertical -command [list .ef.cnv yview]
    grid .ef.cnv .ef.yscroll -sticky news
    grid .ef.xscroll -stick news

    set winFrame [frame .ef.cnv.win]
    .ef.cnv create window 0 0 -anchor nw -window $winFrame
    
    frame .ef.cnv.win.errors
    foreach errNum [lsort -integer [array names errorList]] {
	set err $errorList($errNum)
	set libName [lindex $err 0]
	set cellView [lindex $err 1]
	set fileName [lindex $err 2]
	set fileInfo [lindex $err 3]
	set fn .ef.cnv.win.errors.err$errNum
	frame $fn
	pack [entry $fn.libName -width 20 -justify center] -side left
	$fn.libName insert end $libName
	$fn.libName configure -state readonly
	pack [entry $fn.cellView -width 40 -justify center] -side left
	$fn.cellView insert end $cellView
	$fn.cellView configure -state readonly
	pack [entry $fn.fileName -width 40 -justify center] -side left
	$fn.fileName insert end $fileName
	$fn.fileName configure -state readonly
	pack [entry $fn.fileInfo -width 40 -justify center] -side left
	$fn.fileInfo insert end $fileInfo
	$fn.fileInfo  configure -state readonly
	pack $fn -side top
    }
    pack .ef.cnv.win.errors -side top
    pack .ef
    ##  Without the following wait, the winfo width/height just return 1
    tkwait visibility .ef
    .ef.cnv configure -scrollregion [list 0 0 [winfo width .ef.cnv.win] [winfo height .ef.cnv.win]]
    
} elseif {$type == "selectTag"} {
    
    if {![info exists tagList]} {errorOut "tagLib array not defined"}
    
    set listVar {}
    foreach tagNum [lsort -integer [array names tagList]] {
	set tag $tagList($tagNum)
	set ver [lindex $tag 0]
	set date [lindex $tag 2]
	set user [lindex $tag 3]
	set desc [lindex $tag 4]

	set line [format {%3d   %-10s   %-10s   %-40s} $ver $date $user $desc]
	lappend listVar $line
	#	puts $line
    }
    
    ##  Set default font as courier to keep things lined up.
    set TkDefaultFontAttr [font actual TkDefaultFont]
    set TkTextFontAttr [font actual TkTextFont]
    font create MyDefaultFont {*}$TkDefaultFontAttr
    font configure MyDefaultFont -family Courier
    font configure MyDefaultFont -size 10

    frame .sb
    set header [format {%3s   %-10s   %-10s   %-40s} ver date user description]
    pack [label .sb.label -text "Tag Files" -font MyDefaultFont]  -side top 
    pack [label .sb.header -text $header -justify left -font MyDefaultFont]  -side top -anchor w
    frame .sb.list
    pack [listbox .sb.list.lb -height 20 -width 100 -yscrollcommand ".sb.list.scroll set" -listvariable listVar -selectmode single -relief sunken -font MyDefaultFont] -side left
    pack [scrollbar .sb.list.scroll -command ".sb.list.lb yview"] -side left -fill y
    pack .sb.list
    pack .sb
    
    frame .bf
    pack [button .bf.sync -text "Sync" -command "doSync" -state disabled]
    pack [button .bf.cancel -text "Abort" -command "doAbort"]
    pack .bf 
    bind .sb.list.lb  <ButtonRelease-1> {
	## Something has been selected.
	set selectedTag [selection get]
	.bf.sync configure -state active
    }

} elseif {$type == "runConfirmation"} {
    ##  Simple one that presents a run confirmation dialog.
    if [info exists message] {
	frame .mf
	pack [label .mf.label -text $message]  -side top
	pack .mf -side top
    }
    frame .bf
    pack [button .bf.proceed -text "Proceed" -command "doProceed"] -side left
    pack [button .bf.cancel -text "Abort" -command "doAbort"] -side left
    pack .bf -side top
    
} elseif {$type == "errorMsg"} {
    if [info exists message] {
	frame .mf
	pack [label .mf.label -text $message]  -side top
	pack .mf -side top
    }
    frame .bf
    pack [button .bf.proceed -text "Close" -command "doClose"] -side bottom
    pack .bf -side top

} else {errorOut "Unrecognized type \"$type\""}

################################################################################
# No Linting Area
################################################################################

# nolint Main
# nolint Line 143: W Found constant
# nolint Line 701: W Found constant
# nolint Line 991: N Suspicious variable name