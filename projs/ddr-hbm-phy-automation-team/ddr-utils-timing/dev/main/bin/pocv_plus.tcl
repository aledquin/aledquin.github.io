#!/depot/tcl8.6.3/bin/tclsh8.6
# nolint Main
#######################################################################################
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
utils__script_usage_statistics $script_name "2022ww23"


source [file join [file dirname [info script]] general.tcl]

proc get_tx_sizes { args } {
  set results(-array) ""
  parse_proc_arguments -args $args results
  if { $results(-array) ne "" } {
	upvar 1 $results(-array) arr
  }
  foreach_in_collection cell [get_cells -hier * -filter "is_hierarchical == false"] {
	set attr [get_attribute $cell transistor_width]
	regexp "max_data:(\[0-9\.\-\]+)" $attr dummy width
	set attr [get_attribute $cell transistor_length]
	regexp "max_data:(\[0-9\.\-]+)" $attr dummy length
	set attr [get_attribute $cell transistor_model_name]
	regexp "max_data:(\[^ 	\]+)" $attr dummy name
	if { ![array exists arr] || ![info exists arr($name,$length,$width)] } {
		set arr($name,$length,$width)	1
	} else {
		incr arr($name,$length,$width)
	}
  }
  if { $results(-array) eq "" } {
	return [parray arr]
  }
}
define_proc_attributes -info "get all the widths" -define_args {
        { "-array"          "array to store tx sizes" "name" string optional}
        { "-debug"          "debug information" "" boolean optional}
} get_tx_sizes

proc report_tx_sizes { args } {
  global report_default_significant_digits
  global sh_product_version
  set results(-significant_digits) $report_default_significant_digits
  parse_proc_arguments -args $args results
  foreach_in_collection cell [get_cells -hier * -filter "is_hierarchical == false"] {
	set attr [get_attribute $cell transistor_width]
	regexp "max_data:(\[0-9\.\-\]+)" $attr dummy width
	set attr [get_attribute $cell transistor_length]
	regexp "max_data:(\[0-9\.\-]+)" $attr dummy length
	set attr [get_attribute $cell transistor_model_name]
	regexp "max_data:(\[^ 	\]+)" $attr dummy name
	if { ![array exists arr] || ![info exists arr($name,$length,$width)] } {
		set arr($name,$length,$width)	1
	} else {
		incr arr($name,$length,$width)
	}
  }
   echo " ****************************************"
   echo " Report : Transistor length/width/name cnt"
   echo " Design : [get_attribute [get_design] full_name]"
   echo " Version: $sh_product_version"
   echo " Date   : [date]"
   echo " ****************************************"
   echo ""
   echo " TxName    Length Width Count"

   set float_fmt "%10.$results(-significant_digits)f"
   echo [format "\n%15s %10s %10s %10s %10s" \
        "TxName" "Length(nm)" "Width(nm)" "Voltage" "Count"]
   echo [format "\n%15s %10s %10s %10s %10s" \
        "---------------" "----------" "----------" "----------" "----------"]
   foreach key [array names arr] {
	regexp "(\[^\,\]+),(\[^\,\]+),(\[^\,\]+)" $key dummy name length width
   	echo [format "%15s $float_fmt $float_fmt %10s $float_fmt" \
	$name [expr $length * 1000] [expr $width * 1000] "---" $arr($key)]
   }

}
define_proc_attributes -info "get all the widths" -define_args {
        { "-significant_digits"          "# of sign digits" "int" int optional}
        { "-debug"          "debug information" "" boolean optional}
} report_tx_sizes

proc report_paths_csv { args } {

  set cargs(-paths) ""
  set cargs(-min) 0
  set cargs(-max) 0
  set cargs(-path_ordered) 0
  set cargs(-file) ""
  set cargs(-sigma) 0
  parse_proc_arguments -args $args cargs
  if {$cargs(-file) ne "" } {
	set fout [open "$cargs(-file)" w]
  }
  if { $cargs(-paths) eq "" } {
	if { $cargs(-min) } {
        set paths [get_timing_paths -min -nworst 2 -max_paths  10000]
	} else {
        set paths [get_timing_paths -max -nworst 2 -max_paths  10000]
	}
  } else {
	set paths $cargs(-paths)
	if { $cargs(-min) } {	
		set paths [filter_collection $paths "path_type == min"]
	} else {
		set paths [filter_collection $paths "path_type == max"]
	}
  }
  array unset data_min
  array unset data_max
  foreach_in_collection tpath  $paths {
         # get edge type, path ccb count
        set points [get_attribute $tpath points]
        set cnt [expr [sizeof $points] -2]
        set endpoint [index_collection $points [expr [sizeof_collection $points] -1]]
        set endpoint_obj [get_attribute [index_collection $points [expr [sizeof_collection $points] -1]] object]
        set endpoint_name [get_attribute $endpoint_obj full_name]
        set endpoint_edge [string toupper [string index [get_attribute $endpoint rise_fall] 0]]
        set endpoint_edgerate [get_attribute $endpoint transition]
        set datav [get_attribute $tpath data_variation]
        set delay [get_attribute $tpath delay]
        set data($cnt,$endpoint_edge) "$endpoint_edgerate,[expr $delay - $datav],$delay"
	echo "Processing Path: ${endpoint_name}(${endpoint_edge})"
  }
	if { 0 } {
  foreach_in_collection tpath [filter_collection $paths "path_type == max"] {
         # get edge type, path ccb count
        set points [get_attribute $tpath points]
        set cnt [expr [sizeof $points] -2]
        set endpoint [index_collection $points [expr [sizeof_collection $points] -1]]
        set endpoint_obj [get_attribute [index_collection $points [expr [sizeof_collection $points] -1]] object]
        set endpoint_name [get_attribute $endpoint_obj full_name]
        set endpoint_edge [string toupper [string index [get_attribute $endpoint rise_fall] 0]]
        set endpoint_edgerate [get_attribute $endpoint transition]
        set datav [get_attribute $tpath data_variation]
        set delay [get_attribute $tpath delay]
        set data_max($cnt,$endpoint_edge) "$endpoint_edgerate,[expr $delay - $datav],$delay"
	echo "Processing Max Path: ${endpoint_name}(${endpoint_edge})"
  }
	}

  if { $cargs(-file) ne "" } {
  if { $cargs(-min) } {
  puts $fout "INDEX,EDGE,MINSLEW,MINMEAN,MIN3SIGDELAY"	
  } else {
  puts $fout "INDEX,EDGE,MAXSLEW,MAXMEAN,MAX3SIGDELAY"	
  }
  } else {
  if { $cargs(-min) } {
  echo "INDEX,EDGE,MINSLEW,MINMEAN,MIN3SIGDELAY"
  } else {
  echo "INDEX,EDGE,MAXSLEW,MAXMEAN,MAX3SIGDELAY"
  }
  }
  foreach key [array names data] {
 	lappend keylist [nt_split $key ","]
  }
  set sorted_keylist [lsort -index 0 -integer $keylist]
  if { $cargs(-path_ordered) } {
  foreach key $sorted_keylist {
	set index [lindex $key 0]
	set edge [lindex $key 1]
	if { [is_even $index] && ($edge == "R") } {
	if { $cargs(-file) ne "" } {
        puts $fout "$index,$edge,$data($index,$edge)"
	} else {
        echo "$index,$edge,$data($index,$edge)"
	}
	} elseif { ![is_even $index] && ($edge == "F") } {
	if { $cargs(-file) ne "" } {
        puts $fout "$index,$edge,$data($index,$edge)"
	} else {
        echo "$index,$edge,$data($index,$edge)"
	}
	}
  }
  foreach key $sorted_keylist {
	set index [lindex $key 0]
	set edge [lindex $key 1]
	if { [is_even $index] && ($edge == "F") } {
	if { $cargs(-file) ne "" } {
        puts $fout "$index,$edge,$data($index,$edge)"
	} else {
        echo "$index,$edge,$data($index,$edge)"
	}
	} elseif { ![is_even $index] && ($edge == "R") } {
	if { $cargs(-file) ne "" } {
        puts $fout "$index,$edge,$data($index,$edge)"
	} else {
        echo "$index,$edge,$data($index,$edge)"
	}
	}
  }
  } else {
  foreach key $sorted_keylist {
	set index [lindex $key 0]
	set edge [lindex $key 1]
	if { $edge == "R" } {
	if { $cargs(-file) ne "" } {
        puts $fout "$index,$edge,$data($index,$edge)"
	} else {
        echo "$index,$edge,$data($index,$edge)"
	}
	}
  }
  foreach key $sorted_keylist {
	set index [lindex $key 0]
	set edge [lindex $key 1]
	if { $edge == "F" } {
	if { $cargs(-file) ne "" } {
        puts $fout "$index,$edge,$data($index,$edge)"
	} else {
        echo "$index,$edge,$data($index,$edge)"
	}
	}
  }
  }
  if { $cargs(-file) ne "" } {
	close $fout
  }
	
}
define_proc_attributes -info "get all the widths" -define_args {
        { "-paths"          "timing_paths" "timing paths" string optional}
        { "-file"          "output file" "filename" string optional}
        { "-debug"          "debug information" "" boolean optional}
        { "-min"          "look at min paths" "" boolean optional}
        { "-max"          "look at max paths" "" boolean optional}
        { "-sigma"          "print out path based sigma = (+/-3sig - mean)/sqrt N" "" boolean optional}
        { "-path_ordered"          "alternating edge path ordering starting with falling at out#1" "" boolean optional}
} report_paths_csv


proc compare_txpocv_csv { args } {
  set cargs(-file1) ""
  set cargs(-file2) ""
  set cargs(-percent) 3	
#set file1 [glob *.NT.AOCV.csv]
#set file2 [glob *INV*load*.csv]
  parse_proc_arguments -args $args cargs
set file1 [glob $cargs(-file1)]
set file2 [glob $cargs(-file2)] 
if { ($file1 ne "") && ($file2 ne "") } {
		set 3sigmax -1
		set 3sigmin -1
		set edge -1
		set mean -1
set fin [open  "$file1" r]
        while {1} {
                set line [gets $fin]
                if {[eof $fin]} {
                        close $fin
                        break
                }
                set tokens [split $line ","]
                set token [lindex $tokens 0]
		if { [regexp "INDEX" $token] } {
		set i 0	
		while { $i < [llength $tokens] } {
                set token [lindex $tokens $i]
		if { [regexp -- "\\\+3sig" $token] } {
			set 3sigmax $i
		} elseif { [regexp -- "\\\-3sig" $token] } {
			set 3sigmin $i
		} elseif { [regexp "MAX3SIG" $token] } {
			set 3sigmax $i
		} elseif { [regexp "MIN3SIG" $token] } {
			set 3sigmin $i
		} elseif { [regexp "EDGE" $token] } {
			set edge $i
		} elseif { [regexp "MEAN" $token] } {
			set mean $i
		} 
		incr i
		}
		} elseif { [regexp "\[0-9\]+" $token] } {
			set index $token
			set rf [lindex $tokens $edge]
			set delay1($index,$rf,min) [lindex $tokens $3sigmin]
			set delay1($index,$rf,mean) [lindex $tokens $mean]
			set delay1($index,$rf,max) [lindex $tokens $3sigmax]
			set ratio1($index,$rf,min) [expr [lindex $tokens $3sigmin] / [lindex $tokens $mean]]
			set ratio1($index,$rf,max) [expr [lindex $tokens $3sigmax] / [lindex $tokens $mean]]
		} elseif { ($3sigmax > -1) || ($3sigmin > -1) || ($mean > -1) } {
			break
			close $fin
		}
	}
		set 3sigmax -1
		set 3sigmin -1
		set edge -1
		set mean -1
set fin [open  "$file2" r]
        while {1} {
                set line [gets $fin]
                if {[eof $fin]} {
                        close $fin
                        break
                }
                set tokens [split $line ","]
                set token [lindex $tokens 0]
		if { [regexp "INDEX" $token] } {
		set i 0	
		while { $i < [llength $tokens] } {
                set token [lindex $tokens $i]
		if { [regexp -- "\\\+3sig" $token] } {
			set 3sigmax $i
		} elseif { [regexp -- "\\\-3sig" $token] } {
			set 3sigmin $i
		} elseif { [regexp "MAX3SIG" $token] } {
			set 3sigmax $i
		} elseif { [regexp "MIN3SIG" $token] } {
			set 3sigmin $i
		} elseif { [regexp "EDGE" $token] } {
			set edge $i
		} elseif { [regexp "MEAN" $token] } {
			set mean $i
		} 
		incr i
		}
		} elseif { [regexp "\[0-9\]+" $token] } {
			set index $token
			set rf [lindex $tokens $edge]
			set delay2($index,$rf,min) [lindex $tokens $3sigmin]
			set delay2($index,$rf,mean) [lindex $tokens $mean]
			set delay2($index,$rf,max) [lindex $tokens $3sigmax]
			set ratio2($index,$rf,min) [expr [lindex $tokens $3sigmin] / [lindex $tokens $mean]]
			set ratio2($index,$rf,max) [expr [lindex $tokens $3sigmax] / [lindex $tokens $mean]]
		} elseif { ($3sigmax > -1) || ($3sigmin > -1) || ($mean > -1) } {
			break
			close $fin
		}
	}

parray ratio1
foreach key [array names ratio2] {
	if { [info exists ratio1($key)] } {
	if { $ratio1($key) > $ratio2($key) } {
		set diff [expr $ratio1($key) - $ratio2($key)]
		#set mult [expr $ratio1($key) + $ratio2($key)]
		set pctdiff  [expr $diff  * 100 ]
		if {$pctdiff > 3} {
			puts "Error:  INDEX: $key difference > 3% -- $ratio1($key) vs $ratio2($key)"	
		}
	} else {
		set diff [expr $ratio2($key) - $ratio1($key)]
		set pctdiff [expr $diff  * 100 ]
		if {$pctdiff > 3} {
			puts "Error:  INDEX: $key difference > 3% -- $ratio1($key) vs $ratio2($key)"	
		}
	}
	}
}
}
}
define_proc_attributes -info "compare txpocv +/-3sigma csv files" -define_args {
        { "-file1"          "csv1 file" "filename" string required}
        { "-file2"          "csv2 file" "filename" string required}
        { "-percent"          "percent comparison to trigger Error" "float" float optional}
} compare_txpocv_csv


#  store coeff by:  (min,max,type,tx_moyydel,length,voltage,width/nfin)

proc parse_set_variation_parameters { args } {
  set results(-array) ""
  set results(-data) ""
  parse_proc_arguments -args $args results
  if { $results(-array) ne "" } {
	upvar 1 $results(-array) arr
  }
		set line [string trim $results(-data)]
		set tokens [nt_split $line ", \t"]
                set token [lindex $tokens 0]
                set i 1
		set min 0
		set max 0
		set nfin ""
		set voltage ""
		set length ""
		set width ""
		set tmodel ""
		set nf ""
		set type ""
		set variation 1.0
                while { $i < [llength $tokens] } {
                set token [lindex $tokens $i]
                if { [regexp -- "-min" $token] } {
                        set min 0
                } elseif { [regexp -- "-max" $token] } {
                        set max 1
                } elseif { [regexp -- "-type" $token] } {
			incr i
                        set type [lindex $tokens $i]
                } elseif { [regexp -- "-length" $token] } {
			incr i
                        set length [lindex $tokens $i]
                } elseif { [regexp -- "-width" $token] } {
			incr i
                        set width [lindex $tokens $i]
                } elseif { [regexp -- "-voltage" $token] } {
			incr i
                        set voltage [lindex $tokens $i]
                } elseif { [regexp -- "-nfin" $token] } {
			incr i
                        set nfin [lindex $tokens $i]
                } elseif { [regexp -- "-nf" $token] } {
			incr i
                        set nf [lindex $tokens $i]
                } elseif { [regexp -- "-transistor_model" $token] } {
			incr i
                        set tx_model [lindex $tokens $i]
                } elseif { [regexp -- "-variation" $token] } {
			incr i
                        set variation [lindex $tokens $i]
                }
                incr i
                }
#  store coeff by:  (min,max,type,tx_model,length,voltage,width/nfin)
		if { $nfin ne "" } {	
		set arr($min,$max,$type,$tx_model,$length,$voltage,$nfin) $results(-data)
		} elseif { $width ne "" } {
		set arr($min,$max,$type,$tx_model,$length,$voltage,$width) $results(-data)
		} else  {
		set arr($min,$max,$type,$tx_model,$length,$voltage,$width) $results(-data)
		}
   if { $results(-array) eq "" } {
		return $arr
   }
}
define_proc_attributes -info "parse set_variation_parameters line" -define_args {
        { "-array"          "array to store data" "arrayname" string optional} 
	{ "-data"         "line of data withset_variation_parameters" filename string optional} 
} parse_set_variation_parameters

proc merge_set_variation_parameters { args } {
  set cargs(-files) ""
  set cargs(-inv) ""
  set cargs(-nand) ""
  set cargs(-nand2) ""
  set cargs(-nand3) ""
  set cargs(-nand4) ""
  set cargs(-nor) ""
  set cargs(-nor2) ""
  set cargs(-nor3) ""
  set cargs(-nor4) ""
  set cargs(-output) ""
  set cargs(-debug) 0

  parse_proc_arguments -args $args cargs

#set_variation_parameters -max -type nmos -transistor_model nch_ulvt_mac-nor4 -length .016 -nfin 1 -variation 0.08730352403003273
#set_variation_parameters -min -type nmos -transistor_model nch_ulvt_mac-nor4 -length .016 -nfin 1 -variation 0.08954203026565093
#set_variation_parameters -max -type pmos -transistor_model pch_ulvt_mac-nor4 -length .016 -nfin 1 -variation 0.05627405853662334
#set_variation_parameters -min -type pmos -transistor_model pch_ulvt_mac-nor4 -length .016 -nfin 1 -variation 0.05101796260249455

  array unset coeff_nand2
  array unset coeff_nand3
  array unset coeff_nand4
  array unset coeff_nand
  array unset coeff_nor2
  array unset coeff_nor3
  array unset coeff_nor4
  array unset coeff_nor
  array unset coeff

  if { $cargs(-files) ne "" } {
  set files [nt_split [glob $cargs(-files)]] 
  } else  {
  if { [info exists files] } {
  unset files
  }
  }
  if { $cargs(-inv) ne "" } {
  lappend files [nt_split [glob $cargs(-inv)]]
  }
  echo  "$files"
  foreach file $files {
     puts "Info: Parsing variation coefficient file: $file"
     set fin [open  "$file" r]
        while {1} {
                set line [gets $fin]
                if {[eof $fin]} {
                        close $fin
                        break
                }
		set line [string trim $line]
		set tokens [nt_split $line ", \t"]
                set token [lindex $tokens 0]
                if { [regexp "set_variation_parameters" $token] } {
		if { [regexp -- "\[\-\_\]*nor2\[\-\_\]*" $line] } {
			set line [regsub  -- "\[\-\_\]*nor2\[\-\_\]*" $line {}]
			parse_set_variation_parameters -data $line -array coeff_nor2
		} elseif { [regexp -- \[\-\_\]*"nor3\[\-\_\]*" $line] } {
			set line [regsub  -- "\[\-\_\]*nor3\[\-\_\]*" $line {}]
			parse_set_variation_parameters -data $line -array coeff_nor3
		} elseif { [regexp -- \[\-\_\]*"nor4\[\-\_\]*" $line] } {
			set line [regsub  -- "\[\-\_\]*nor4\[\-\_\]*" $line {}]
			parse_set_variation_parameters -data $line -array coeff_nor4
		} elseif { [regexp -- "\[\-\_\]*nor\[0-9\]\[\-\_\]*" $line] } {
			set line [regsub  -- "\[\-\_\]*nor\[0-9\]\[\-\_\]*" $line {}]
			parse_set_variation_parameters -data $line -array coeff_nor
		} elseif { [regexp -- "\[\-\_\]*nand2\[\-\_\]*" $line] } {
			set line [regsub  -- "\[\-\_\]*nand2\[\-\_\]*" $line {}]
			parse_set_variation_parameters -data $line -array coeff_nand2
		} elseif { [regexp -- "\[\-\_\]*nand3\[\-\_\]*" $line] } {
			set line [regsub  -- "\[\-\_\]*nand3\[\-\_\]*" $line {}]
			parse_set_variation_parameters -data $line -array coeff_nand3
		} elseif { [regexp -- "\[\-\_\]*nand4\[\-\_\]*" $line] } {
			set line [regsub  -- "\[\-\_\]*nand4\[\-\_\]*" $line {}]
			parse_set_variation_parameters -data $line -array coeff_nand4
		} elseif { [regexp -- "\[\-\_\]*nand\[0-9\]\[\-\_\]*" $line] } {
			set line [regsub  -- "\[\-\_\]*nand\[0-9\]\[\-\_\]*" $line {}]
			parse_set_variation_parameters -data $line -array coeff_nand
		} else {
			parse_set_variation_parameters -data $line -array coeff
		}
		}
	  }
  }
  foreach file [nt_split [glob $cargs(-nor2)]] {
     puts "Info: Parsing Nor2 variation coefficient file: $file"
     set fin [open  "$file" r]
        while {1} {
                set line [gets $fin]
                if {[eof $fin]} {
                        close $fin
                        break
                }
		set line [string trim $line]
		set tokens [nt_split $line ", \t"]
                set token [lindex $tokens 0]
                if { [regexp "set_variation_parameters" $token] } {
			if { $cargs(-debug) } {
			puts "	Adding nor2 variation coefficients: $line"
			}
			set line [regsub  -- "\[\-\_\]*nor2\[\-\_\]*" $line {}]
			parse_set_variation_parameters -data $line -array coeff_nor2 
		}
	}
   }
  foreach file [nt_split [glob $cargs(-nor3)]] {
     puts "Info: Parsing Nor3 variation coefficient file: $file"
     set fin [open  "$file" r]
        while {1} {
                set line [gets $fin]
                if {[eof $fin]} {
                        close $fin
                        break
                }
		set line [string trim $line]
		set tokens [nt_split $line ", \t"]
                set token [lindex $tokens 0]
                if { [regexp "set_variation_parameters" $token] } {
			if { $cargs(-debug) } {
			puts "	Adding nor3 variation coefficients: $line"
			}
			set line [regsub  -- "\[\-\_\]*nor3\[\-\_\]*" $line {}]
			parse_set_variation_parameters -data $line -array coeff_nor3 
		}
	}
   }
  foreach file [nt_split [glob $cargs(-nor4)]] {
     puts "Info: Parsing Nor4 variation coefficient file: $file"
     set fin [open  "$file" r]
        while {1} {
                set line [gets $fin]
                if {[eof $fin]} {
                        close $fin
                        break
                }
		set line [string trim $line]
		set tokens [nt_split $line ", \t"]
                set token [lindex $tokens 0]
                if { [regexp "set_variation_parameters" $token] } {
			if { $cargs(-debug) } {
			puts "	Adding nor4 variation coefficients: $line"
			}
			set line [regsub  -- "\[\-\_\]*nor4\[\-\_\]*" $line {}]
			parse_set_variation_parameters -data $line -array coeff_nor4
		}
	}
   }
  foreach file [nt_split [glob $cargs(-nor)]] {
     puts "Info: Parsing Nor variation coefficient file: $file"
     set fin [open  "$file" r]
        while {1} {
                set line [gets $fin]
                if {[eof $fin]} {
                        close $fin
                        break
                }
		set line [string trim $line]
		set tokens [nt_split $line ", \t"]
                set token [lindex $tokens 0]
                if { [regexp "set_variation_parameters" $token] } {
			if { $cargs(-debug) } {
			puts "	Adding norN variation coefficients: $line"
			}
			set line [regsub  -- "\[\-\_\]*nor\[0-9\]\[\-\_\]*" $line {}]
			parse_set_variation_parameters -data $line -array coeff_nor 
		}
	}
   }
  foreach file [nt_split [glob $cargs(-nand2)]] {
     puts "Info: Parsing Nand2 variation coefficient file: $file"
     set fin [open  "$file" r]
        while {1} {
                set line [gets $fin]
                if {[eof $fin]} {
                        close $fin
                        break
                }
		set line [string trim $line]
		set tokens [nt_split $line ", \t"]
                set token [lindex $tokens 0]
                if { [regexp "set_variation_parameters" $token] } {
			if { $cargs(-debug) } {
			puts "	Adding nand2 variation coefficients: $line"
			}
			set line [regsub  -- "\[\-\_\]*nand2\[\-\_\]*" $line {}]
			parse_set_variation_parameters -data $line -array coeff_nand2 
		}
	}
   }
  foreach file [nt_split [glob $cargs(-nand3)]] {
     puts "Info: Parsing Nand3 variation coefficient file: $file"
     set fin [open  "$file" r]
        while {1} {
                set line [gets $fin]
                if {[eof $fin]} {
                        close $fin
                        break
                }
		set line [string trim $line]
		set tokens [nt_split $line ", \t"]
                set token [lindex $tokens 0]
                if { [regexp "set_variation_parameters" $token] } {
			if { $cargs(-debug) } {
			puts "	Adding nand3 variation coefficients: $line"
			}
			set line [regsub  -- "\[\-\_\]*nand3\[\-\_\]*" $line {}]
			parse_set_variation_parameters -data $line -array coeff_nand3 
		}
	}
   }
  foreach file [nt_split [glob $cargs(-nand4)]] {
     puts "Info: Parsing Nand4 variation coefficient file: $file"
     set fin [open  "$file" r]
        while {1} {
                set line [gets $fin]
                if {[eof $fin]} {
                        close $fin
                        break
                }
		set line [string trim $line]
		set tokens [nt_split $line ", \t"]
                set token [lindex $tokens 0]
                if { [regexp "set_variation_parameters" $token] } {
			if { $cargs(-debug) } {
			puts "	Adding nand4 variation coefficients: $line"
			}
			set line [regsub  -- "\[\-\_\]*nand4\[\-\_\]*" $line {}]
			parse_set_variation_parameters -data $line -array coeff_nand4 
		}
	}
   }
  foreach file [nt_split [glob $cargs(-nand)]] {
     puts "Info: Parsing Nand variation coefficient file: $file"
     set fin [open  "$file" r]
        while {1} {
                set line [gets $fin]
                if {[eof $fin]} {
                        close $fin
                        break
                }
		set line [string trim $line]
		set tokens [nt_split $line ", \t"]
                set token [lindex $tokens 0]
                if { [regexp "set_variation_parameters" $token] } {
			if { $cargs(-debug) } {
			puts "	Adding nandN variation coefficients: $line"
			}
			set line [regsub  -- "\[\-\_\]*nand\[0-9\]\[\-\_\]*" $line {}]
			parse_set_variation_parameters -data $line -array coeff_nand  
		}
	}
   }
   puts "Info: Calculating coeff scale for -series2/-series3/-series4"
   foreach key [array names coeff_nand2x]] {
	if { [regexp -- ",nmos" $key] } {
	if { [info exists coeff($key)]} {
		regexp -- "-variation\[ \]+(\[0-9\.\]+)" $coeff($key) dummy coeff1
		regexp -- "-variation\[ \]+(\[0-9\.\]+)" $coeff_nand2($key) dummy coeff2
		set scale [expr $coeff1/$coeff2]
		if { $scale < 1.0 } {
		append coeff($key) " -series2 1.0"
		} elseif { $scale > 2.0 } {
		append coeff($key) " -series2 2.0"
		}  else {
		append coeff($key) " -series2 $scale"
		}
		if { $cargs(-debug) } {
			puts "Debug: $key: adding -series2 $scale"
		}
	} else {
		puts "Warning: unmatched $coeff_nand2($key)"
	}
	}
   }

   foreach key [array names coeff_nand3] {
	if { [regexp -- ",nmos" $key] } {
	if { [info exists coeff($key)] } {
		if { [array exists coeff_nand] && [info exists coeff_nand($key)] } {
		regexp -- "-variation\[ \]+(\[0-9\.\]+)" $coeff_nand($key) dummy coeff3
		regexp -- "-variation\[ \]+(\[0-9\.\]+)" $coeff_nand3($key) dummy coeff2
		regexp -- "-variation\[ \]+(\[0-9\.\]+)" $coeff($key) dummy coeff1
		if { $coeff2 > $coeff3 } {
		set scale [expr $coeff1/$coeff3]
		} else {
		set scale [expr $coeff1/$coeff2]
		}
		if { $scale < 1.0 } {
		append coeff($key) " -series3 1.0"
		} elseif { $scale > 3.0 } {
		append coeff($key) " -series3 3.0"
		}  else {
		append coeff($key) " -series3 $scale"
		}
		if { $cargs(-debug) } {
			puts "Debug: $key: adding -series3 $scale"
		}
		} else {	
		regexp -- "-variation\[ \]+(\[0-9\.\]+)" $coeff($key) dummy coeff1
		regexp -- "-variation\[ \]+(\[0-9\.\]+)" $coeff_nand3($key) dummy coeff2
		set scale [expr $coeff1/$coeff2]
		if { $scale < 1.0 } {
		append coeff($key) " -series3 1.0"
		} elseif { $scale > 3.0 } {
		append coeff($key) " -series3 3.0"
		} else {
		append coeff($key) " -series3 $scale"
		}
		if { $cargs(-debug) } {
			puts "Debug: $key: adding -series3 $scale"
		}
		}
	} else {
		puts "Warning: unmatched $coeff_nand3($key)"
	}
	}
   }
   foreach key [array names coeff_nand4] {
	if { [regexp -- ",nmos" $key] } {
	if { [info exists coeff($key)] } {
		if { [array exists coeff_nand] && [info exists coeff_nand($key)] } {
		regexp -- "-variation\[ \]+(\[0-9\.\]+)" $coeff_nand($key) dummy coeff3
		regexp -- "-variation\[ \]+(\[0-9\.\]+)" $coeff_nand4($key) dummy coeff2
		regexp -- "-variation\[ \]+(\[0-9\.\]+)" $coeff($key) dummy coeff1
		if { $coeff2 > $coeff3 } {
		set scale [expr $coeff1/$coeff3]
		} else {
		set scale [expr $coeff1/$coeff2]
		}
		if { $scale < 1.0 } {
		append coeff($key) " -series4 1.0"
		} elseif { $scale > 4.0 } {
		append coeff($key) " -series4 4.0"
		}  else {
		append coeff($key) " -series4 $scale"
		}
		if { $cargs(-debug) } {
			puts "Debug: $key: adding -series4 $scale"
		}
		} else {	
		regexp -- "-variation\[ \]+(\[0-9\.\]+)" $coeff($key) dummy coeff1
		regexp -- "-variation\[ \]+(\[0-9\.\]+)" $coeff_nand4($key) dummy coeff2
		set scale [expr $coeff1/$coeff2]
		if { $scale < 1.0 } {
		append coeff($key) " -series4 1.0"
		} elseif { $scale > 4.0 } {
		append coeff($key) " -series4 4.0"
		} else {
		append coeff($key) " -series4 $scale"
		}
		if { $cargs(-debug) } {
			puts "Debug: $key: adding -series4 $scale"
		}
		}
	} else {
		puts "Warning: unmatched $coeff_nand4($key)"
	}
	}
   }
   foreach key [array names coeff_nand] {
	if { [regexp -- ",nmos" $key] } {
	if { [info exists coeff($key)] } {
		if { [array exists coeff_nand4] && [info exists coeff_nand4($key)] } {
		} else {
		regexp -- "-variation\[ \]+(\[0-9\.\]+)" $coeff($key) dummy coeff1
		regexp -- "-variation\[ \]+(\[0-9\.\]+)" $coeff_nand($key) dummy coeff2
		set scale [expr $coeff1/$coeff2]
		if { $scale < 1.0 } {
		append coeff($key) " -series4 1.0"
		} elseif { $scale > 4.0 } {
		append coeff($key) " -series4 4.0"
		} else {
		append coeff($key) " -series4 $scale"
		}
		if { $cargs(-debug) } {
			puts "Debug: $key: adding -series4 $scale"
		}
		}
	}
	}
   }
   foreach key [array names coeff_nor2] {
	if { [regexp -- ",pmos" $key] } {
	if { [info exists coeff($key)] } {
		regexp -- "-variation\[ \]+(\[0-9\.\]+)" $coeff($key) dummy coeff1
		regexp -- "-variation\[ \]+(\[0-9\.\]+)" $coeff_nor2($key) dummy coeff2
		set scale [expr $coeff1/$coeff2]
		if { $scale < 1.0 } {
		append coeff($key) " -series2 1.0"
		} elseif { $scale > 2.0 } {
		append coeff($key) " -series2 2.0"
		} else {
		append coeff($key) " -series2 $scale"
		}
		if { $cargs(-debug) } {
			puts "Debug: $key: adding -series2 $scale"
		}
	} else {
		puts "Warning: unmatched $coeff_nor2($key)"
	}
	}
   }
   foreach key [array names coeff_nor3] {
	if { [regexp -- ",pmos" $key] } {
	if { [info exists coeff($key)] } {
		if { [array exists coeff_nor] && [info exists coeff_nor($key)] } {
		regexp -- "-variation\[ \]+(\[0-9\.\]+)" $coeff_nor($key) dummy coeff3
		regexp -- "-variation\[ \]+(\[0-9\.\]+)" $coeff_nor3($key) dummy coeff2
		regexp -- "-variation\[ \]+(\[0-9\.\]+)" $coeff($key) dummy coeff1
		if { $coeff2 > $coeff3 } {
		set scale [expr $coeff1/$coeff3]
		} else {
		set scale [expr $coeff1/$coeff2]
		}
		if { $scale < 1.0 } {
		append coeff($key) " -series3 1.0"
		} elseif { $scale > 3.0 } {
		append coeff($key) " -series3 3.0"
		} else {
		append coeff($key) " -series3 $scale"
		}
		if { $cargs(-debug) } {
			puts "Debug: $key: adding -series3 $scale"
		}
		} else {	
		regexp -- "-variation\[ \]+(\[0-9\.\]+)" $coeff($key) dummy coeff1
		regexp -- "-variation\[ \]+(\[0-9\.\]+)" $coeff_nor3($key) dummy coeff2
		set scale [expr $coeff1/$coeff2]
		if { $scale < 1.0 } {
		append coeff($key) " -series3 1.0"
		} elseif { $scale > 3.0 } {
		append coeff($key) " -series3 3.0"
		} else {
		append coeff($key) " -series3 $scale"
		}
		if { $cargs(-debug) } {
			puts "Debug: $key: adding -series3 $scale"
		}
		}
	} else {
		puts "Warning: unmatched $coeff_nor3($key)"
	}
	}
   }
   foreach key [array names coeff_nor4] {
	if { [regexp -- ",pmos" $key] } {
	if { [info exists coeff($key)] } {
		if { [array exists coeff_nor] && [info exists coeff_nor($key)] } {
		regexp -- "-variation\[ \]+(\[0-9\.\]+)" $coeff_nor($key) dummy coeff3
		regexp -- "-variation\[ \]+(\[0-9\.\]+)" $coeff_nor4($key) dummy coeff2
		regexp -- "-variation\[ \]+(\[0-9\.\]+)" $coeff($key) dummy coeff1
		if { $coeff2 > $coeff3 } {
		set scale [expr $coeff1/$coeff3]
		} else {
		set scale [expr $coeff1/$coeff2]
		}
		if { $scale < 1.0 } {
		append coeff($key) " -series4 1.0"
		} elseif { $scale > 4.0 } {
		append coeff($key) " -series4 4.0"
		} else {
		append coeff($key) " -series4 $scale"
		}
		if { $cargs(-debug) } {
			puts "Debug: $key: adding -series4 $scale"
		}
		} else {	
		regexp -- "-variation\[ \]+(\[0-9\.\]+)" $coeff($key) dummy coeff1
		regexp -- "-variation\[ \]+(\[0-9\.\]+)" $coeff_nor4($key) dummy coeff2
		set scale [expr $coeff1/$coeff2]
		if { $scale < 1.0 } {
		append coeff($key) " -series4 1.0"
		} elseif { $scale > 4.0 } {
		append coeff($key) " -series4 4.0"
		} else {
		append coeff($key) " -series4 $scale"
		}
		if { $cargs(-debug) } {
			puts "Debug: $key: adding -series4 $scale"
		}
		}
	} else {
		puts "Warning: unmatched $coeff_nor4($key)"
	}
	}
   }
   foreach key [array names coeff_nor] {
	if { [regexp -- ",pmos" $key] } {
	if { [info exists coeff($key)] } {
		if { [array exists coeff_nor4] && [info exists coeff_nor4($key)] } {
		} else {	
		regexp -- "-variation\[ \]+(\[0-9\.\]+)" $coeff($key) dummy coeff1
		regexp -- "-variation\[ \]+(\[0-9\.\]+)" $coeff_nor($key) dummy coeff2
		set scale [expr $coeff1/$coeff2]
		if { $scale < 1.0 } {
		append coeff($key) " -series4 1.0"
		} elseif { $scale > 4.0 } {
		append coeff($key) " -series4 4.0"
		} else {
		append coeff($key) " -series4 $scale"
		}
		if { $cargs(-debug) } {
			puts "Debug: $key: adding -series4 $scale"
		}
		}
	}
	}
   }
   if { $cargs(-output) ne "" } {
   set fout [open  "$cargs(-output)" w]
   puts "Info: Writing coefficient output file $cargs(-output)"
   foreach key [array names coeff] {
	puts $fout $coeff($key)
   }
   close $fout
   } else {
   foreach key [array names coeff] {
	eval $coeff($key)
	echo "Apply coeff: $coeff($key)"
   }
   }
}
define_proc_attributes -info "merge set_variation_parameter files" -define_args {
        { "-files"          "set_variation_parameter files" "filename" string optional} 
	{ "-output"         "save merged parameters to otuput file" filename string optional} 
        { "-nand4"          "nand4 chain variation parameter files" "filename" string optional}
        { "-nand3"          "nand3 chain variation parameter files" "filename" string optional}
        { "-nand2"          "nand2 chain variation parameter files" "filename" string optional}
        { "-nand"          "nand(more than 3 inputs) chain variation parameter files" "filename" string optional}
	{ "-nor4"	   "nor4 chain variation parameter files" "filename" string optional}
	{ "-nor3"	   "nor3 chain variation parameter files" "filename" string optional}
        { "-nor2"          "nor2 chain variation parameter files" "filename" string optional}
	{ "-nor"	   "nor(more than 3 inputs) chain variation parameter files" "filename" string optional}
	{ "-inv"	   "inv chain variation parameter files" "filename" string optional}
	{ "-debug"	   "add debug information" "" boolean optional}
} merge_set_variation_parameters
