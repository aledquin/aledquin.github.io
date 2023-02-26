########################################################################################
# This Software and documentation if any (hereinafter, "Software") is an unpublished,  #
# unsupported, confidential, proprietary work of Synopsys, Inc.                        #
#                                                                                      #
# The Software IS NOT an item of Licensed Software or Licensed Product under any End   #
# User Software License Agreement or Agreement for Licensed Product with Synopsys or   #
# any supplement thereto. You are permitted to internally use and internally           #
# redistribute this Software in source and binary forms, with or without modification, #
# provided that redistributions of source code must retain this notice. You may not    #
# view, use, disclose, copy or distribute this file or any information contained       #
# herein except pursuant to this license grant from Synopsys. If you do not agree with #
# this notice, including the disclaimer below, then you are not authorized to use the  #
# Software.                                                                            #
#                                                                                      #
# THIS SOFTWARE IS BEING DISTRIBUTED BY SYNOPSYS SOLELY ON AN "AS IS" BASIS AND ANY    #
# EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES #
# OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE HEREBY DISCLAIMED. IN NO #
# EVENT SHALL SYNOPSYS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,        #
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF   #
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS             #
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,    #
# STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT #
# OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.      #
########################################################################################
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

set pm2nt_regexp_match_multi_hier "true"
set pm2nt_regexp_replace_bus_with_wildcard "false"
set wildcard "\*"
set bracket "\[\\\[\\\]\]"
set nowhitespace "\^ \t\n"
set whitespace "\t \n"
set dot "\."
set nt_integer "\[0-9\]+"

if { [string compare [info proc nt_split] ""] == 0 } {
proc nt_split { args } {
  set results(splitChars) " \t\n\\\}\\\{"
  parse_proc_arguments -args $args results
  set results(str) [string trim $results(str) $results(splitChars)]
  regsub -all \[$results(splitChars)\]+ ${results(str)} [string index $results(splitChars) 0] results(str)
  return [split $results(str) $results(splitChars)]
}
define_proc_attributes -info "split on multi slitChars" -define_args {
        { "str"         "string" "string" string required}
        { "splitChars"          "splitChars" "string" string optional}
} nt_split
}

proc is_odd  x {expr {($x % 2) != 0}}
proc is_even x {expr {($x % 2) == 0}}

proc unsetarray { array } {
        upvar 1 $array arr
        if { [array exists $arr] } {
           array unset $arr
        }
}
proc unsetlist { list } {
        upvar 1 $list mylist
        if { [info exists mylist] } {
           unset mylist
        }
}
proc unsetcollection { collection } {
        upvar 1 $collection mycoll
        if { [info exists mycoll] } {
           set mycoll [remove_from_collection $mycoll -intersect {}]
        }
}
proc lremove {listName what} {
    upvar 1 $listName list
    set pos  [lsearch $list $what]
    set list [lreplace $list $pos $pos]
}


proc ::min {args} {
set m Inf
foreach a $args {
if {$a < $m } {
set m $a
}
}
return $m
}

proc nt_append { args } {
  parse_proc_arguments -args $args results
  upvar 1 $results(var) var
  append $var " $results(str)"
}
define_proc_attributes -info "append str to var with space" -define_args {
	{ "var"		"variable" "string" string required}
	{ "str"		"string" "string" string required}
} nt_append

proc nt_prepend { args } {
  parse_proc_arguments -args $args results
  upvar 1 $results(var) var
  set $var "$results(str) ${var}"
}
define_proc_attributes -info "prepend str to var with space" -define_args {
	{ "var"		"variable" "string" string required}
	{ "str"		"string" "string" string required}
} nt_prepend

proc lsort-indices { args } {
   set results(-real) 1
   set results(-ascii) 0
   set results(-integer) 0
   set results(-increasing) 1
   set results(-decreasing) 0
   set results(itemL) [list]
   parse_proc_arguments -args $args results
    set pairL [list]
    # assigns pairL index values 0 - [llength $results(itemL) -1]
    foreach item $results(itemL) {
      lappend pairL [list $item [llength $pairL]]
    }
    set indexL [list]
    if { $results(-integer) } {
    if { $results(-decreasing) } {
    # assigns indexL to the -real sorted
    foreach pair [lsort -index 0 -integer -decreasing $pairL] {
      lappend indexL [lindex $pair 1]
    }
    } else {
    # assigns indexL to the -real sorted
    foreach pair [lsort -index 0 -integer -increasing $pairL] {
      lappend indexL [lindex $pair 1]
    }
    }
    } elseif { $results(-ascii) } {
    if { $results(-decreasing) } {
    # assigns indexL to the -ascii sorted
    foreach pair [lsort -index 0 -ascii -decreasing $pairL] {
      lappend indexL [lindex $pair 1]
    }
    } else {
    # assigns indexL to the -real sorted
    foreach pair [lsort -index 0 -ascii -increasing $pairL] {
      lappend indexL [lindex $pair 1]
    }
    }
    } else {
    if { $results(-decreasing) } {
    # assigns indexL to the -real sorted
    foreach pair [lsort -index 0 -real -decreasing $pairL] {
      lappend indexL [lindex $pair 1]
    }
    } else {
    # assigns indexL to the -real sorted
    foreach pair [lsort -index 0 -real -increasing $pairL] {
      lappend indexL [lindex $pair 1]
    }
    }
    }
     return $indexL
}
define_proc_attributes -info "sort List indices based on values instead of List values" -define_args {
   	{ "-decreasing"  "sort in decreasing order" "" boolean optional}
   	{ "-increasing"  "sort in increasing order(default)" "" boolean optional}
   	{ "-real"  "sort List values based on reals(default)" "" boolean optional}
   	{ "-integer"  "sort List values based on integer" "" boolean optional}
   	{ "-ascii"  "sort List values based on ascii" "" boolean optional}
	{ "itemL"   "item List name to sort" "itemL" list required}
} lsort-indices

proc report_nt_header { args } {
   global sh_product_version
   set results(-name) ""
   parse_proc_arguments -args $args results
   echo "****************************************"
   echo "Report : $results(-name)"
   echo "Design : [get_attribute [get_design] full_name]"
   echo "Version: $sh_product_version"
   echo "Date   : [date]"
   echo "****************************************"
}
define_proc_attributes -info "printout a report header" -define_args {
	{ "-name"   "report name to be added to header" "string" string required}
} report_nt_header

proc report_nt_dashline { args } {
   set results(-size) ""
   parse_proc_arguments -args $args results
   set i 0
   set format_str ""
   set dash_str ""
   while { $i < [llength $results(-size)] } {
	set size [lindex $results(-size) $i]
   	if { $format_str ne "" } {
		append format_str " "
		append dash_str " "
	}
	append format_str "%${size}s"
	append dash_str "\""
	set j 0
	while { $j < $size } {
	append dash_str "-"
	incr j
	}
	append dash_str "\""
	incr i
   }
        echo [eval format \"$format_str\" $dash_str]
}
define_proc_attributes -info "printout a labels for columns being reported" -define_args {
	{ "-size"   "list of char sizes for each label" "list of int" string required}
} report_nt_dashline

proc report_nt_labels { args } {
   set results(-label) ""
   set results(-size) ""
   parse_proc_arguments -args $args results
   set i 0
   set format_str ""
   set label_str ""
   while { $i < [llength $results(-size)] } {
   	if { $format_str ne "" } {
		append format_str " "
		append label_str " "
	}
	append format_str "%[lindex $results(-size) $i]s"
	append label_str "\"[lindex $results(-label) $i]\""
	incr i
   }
   echo [eval format \"$format_str\" $label_str]
}
define_proc_attributes -info "printout labels for columns being reported" -define_args {
	{ "-label"   "list of labels" "list of strings" string required}
	{ "-size"   "list of char sizes for each label" "list of int" string required}
} report_nt_labels
	
proc report_nt_dataline { args } {
   set results(-format) ""
   set results(-data) ""
   set results(-size) ""
   parse_proc_arguments -args $args results
   set i 0
   set format_str ""
   set data_str ""
   while { $i < [llength $results(-size)] } {
	set format [lindex $results(-format) $i]
	set size [lindex $results(-size) $i]
	set data [lindex $results(-data) $i]
   	if { $format_str ne "" } {
		append format_str " "
		append data_str " "
	}
	if { [regexp "str" $format] || ($format eq "") || ($data eq "") } {
		append format_str "%${size}s"
	} elseif { [regexp "flo\[^0-9\.\]*\[\.\]*(\[0-9\]*)" $format dummy sdigits]} {
		if { $sdigits ne "" } {
		if { $size <= $sdigits } {
			puts "Warning:  trying to printout more sig_digitsi($sdigits) then allocated column size($size)"
		}
		append format_str "% ${size}.${sdigits}f"
		} else {
		append format_str "% ${size}f"
		}
	} elseif { [regexp "int\[^0-9\.\]*\[\.\]*(\[0-9\]*)" $format dummy sdigits]} {
		append format_str "% ${size}d"
	} else {
		append format_str " %${size}s"
	}
	if { ($data eq  "") || [regexp "^\[ \]*$" $data] } {
		append data_str "-"
	} else {
		append data_str "\"$data\""
	}
	incr i
   }
   echo [eval format \"$format_str\" $data_str]
}
define_proc_attributes -info "printout data for each label column being reported" -define_args {
	{ "-format"   "list of formats for each label" "list of strings" string required}
	{ "-data"   "list of data to report for each label" "list of strings" string required}
	{ "-size"   "list of char sizes for each label" "list of int" string required}
} report_nt_dataline

proc get_object_name { args } {
  parse_proc_arguments -args $args results
  return [get_attribute $results(collection) full_name]
}
define_proc_attributes -info "Get the name of one object in collection" -define_args {
        { "collection"          "The collection" "collection" string required}
} get_object_name


proc get_object { args } {
  parse_proc_arguments -args $args results
  return [get_attribute $results(collection) object]
}
define_proc_attributes -info "Get the object in collection" -define_args {
        { "collection"          "The collection" "collection" string required}
} get_object


