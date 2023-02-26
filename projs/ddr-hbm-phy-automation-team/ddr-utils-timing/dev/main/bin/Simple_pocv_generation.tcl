#!/depot/tcl8.6.3/bin/tclsh8.6
# nolint Main
######################################################################################
#This Software and documentation if any (hereinafter, "Software") is an unpublished,  #
#unsupported, confidential, proprietary work of Synopsys, Inc.                        #
#                                                                                     #
#The Software IS NOT an item of Licensed Software or Licensed Product under any End   #
#User Software License Agreement or Agreement for Licensed Product with Synopsys or   #
#any supplement thereto. You are permitted to internally use and internally           #
#redistribute this Software in source and binary forms, with or without modification, #
#provided that redistributions of source code must retain this notice. You may not    #
#view, use, disclose, copy or distribute this file or any information contained       #
#herein except pursuant to this license grant from Synopsys. If you do not agree with #
#this notice, including the disclaimer below, then you are not authorized to use the  #
#Software.                                                                            #
#                                                                                     #
#THIS SOFTWARE IS BEING DISTRIBUTED BY SYNOPSYS SOLELY ON AN "AS IS" BASIS AND ANY    #
#EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES #
#OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE HEREBY DISCLAIMED. IN NO #
#EVENT SHALL SYNOPSYS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,        #
#EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF   #
#SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS             #
#INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,    #
#STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT #
#OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.      #
#######################################################################################




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


global POCV_SCRIPT_VERSION
set POCV_SCRIPT_VERSION 2.16


#source [file join [file dirname [info script]] general.tcl]

global __script_dir
if { [info exists __scriptdir] } {
set __script_dir $__scriptdir 
}

global __date

if { ![info exists __date] } {
  set __date [clock format [clock seconds] -format {%a %b %d %H:%M:%S %Z %Y}]
}

if { ([info procs parse_myproc_arguments] eq "") &&  ([info procs define_myproc_attributes] eq "") } {
  if { [info exists __script_dir] } {
    if { [file exists $__script_dir/general_pocv.tcl] } {
      source $__script_dir/general_pocv.tcl
    } elseif { [file exists $__script_dir/general_pocv.tbc] } {
      append auto_path " $__script_dir/tbcload"
      package require tbcload 1.4
      source $__script_dir/general_pocv.tbc
    } else {
      puts "MISSING general_pocv.tbc/.tcl scripts file"
      exit
    }
  } else {
    puts "MISSING general_pocv.tbc/.tcl scripts file(put all aocv script files in same directory)"
    exit
  }
}

if { [info proc snps_split] eq "" } {
proc snps_split { args } {
  set cargs(splitChars) " \t\n"
  set cargs(str) ""
  parse_myproc_arguments -args $args cargs
  set cargs(str) [string trim $cargs(str) $cargs(splitChars)]
  set cargs(str) [string trim $cargs(str) "\}\{"]
  regsub -all \[$cargs(splitChars)\]+ ${cargs(str)} { } cargs(str)
  return [split $cargs(str)]
}
define_myproc_attributes -info "split on multi slitChars" -define_args {
        { "str"         "string" "string" string required}
        { "splitChars"          "splitChars" "string" string optional}
} snps_split
echo "Defined procedure 'snps_split'."
}

if { [info proc snps_lappend] eq ""} {
proc snps_lappend { args } {
  set cargs(-nonewline) 0
  set cargs(string) ""
  parse_myproc_arguments -args $args cargs
  upvar $cargs(varname)  varname
  if { ($varname ne "" ) && $cargs(-nonewline)} {
      while { [regexp "^\[ \]*\{(\[^\}\]*)\[ \]*\}$" $cargs(string) dummy cargs(string)] } {
      regsub "^\[ \]*\[\{\](\[^\}\]*)\[\}\]\[ \]*$" $cargs(string) "" cargs(string)
      }
      append [lindex $varname end] " $cargs(string)"
  } else {
      while { [regexp "^\[ \]*\{(\[^\}\]*)\[ \]*\}$" $cargs(string) dummy cargs(string)] } {
      regsub "^\[ \]*\[\{\](\[^\}\]*)\[\}\]\[ \]*$" $cargs(string) "" cargs(string)
      }
      lappend varname $cargs(string)
  }
}
define_myproc_attributes -info "append with leading space" -define_args {
        { "varname"         "var name" "string" string required}
        { "string"      "string" "string" string required}
        { "-nonewline"      "no new line" "" boolean optional}
} snps_lappend
}

if { [info proc alias] eq "" } {
proc alias {alias target} {
    set fulltarget [uplevel [list namespace which $target]]
    if {$fulltarget eq {}} {
        return -code error [list {no such command} $target]
    }
    set save [namespace eval [namespace qualifiers $fulltarget] {
        namespace export}]
    namespace eval [namespace qualifiers $fulltarget] {namespace export *}
    while {[namespace exists [
        set tmpns [namespace current]::[info cmdcount]]]} {}
    set code [catch {set newcmd [namespace eval $tmpns [
        string map [list @{fulltarget} [list $fulltarget]] {
        namespace import @{fulltarget}
    }]]} cres copts]
    namespace eval [namespace qualifiers $fulltarget] [
        list namespace export {*}$save]
    if {$code} {
        return -options $copts $cres
    }
    uplevel [list rename ${tmpns}::[namespace tail $target] $alias]
    namespace delete $tmpns 
    return [uplevel [list namespace which $alias]]
}
}

### read spice deck and store some attributes
proc read_spice_cell_deck { args } {
  set cargs(-cell) ""
  set cargs(-array_name) ""
  set cargs(-spice_cells_dir) "./"
  set cargs(-find_direction) 0
  set cargs(-save_dir) ""
  set cargs(-pfet_regexp) "*pfet*"
  set cargs(-nfet_regexp) "*nfet*"

  if { [parse_myproc_arguments -args $args cargs] eq "0" } {
  	return 0
  }

  if {[string compare $cargs(-array_name) ""] != 0 } {
    upvar $cargs(-array_name) cellarray
  }

  set pwd [pwd]
  set pwd [string trim $pwd]
  if { $cargs(-cell) eq "" } {
    set cells "*"
  } else {
    set cells [split [regsub -all "\[ \t\]+" [join $cargs(-cell)] { }]]
  }

  if { ![regexp "^\[ \t]*\[\/\$\]" $cargs(-spice_cells_dir)] } {
    set cargs(-spice_cells_dir) "${pwd}/${cargs(-spice_cells_dir)}"
  }
  if { $cargs(-save_dir) ne "" } {
    if {![regexp "^\[ \t]*\[\/\$\]" $cargs(-save_dir)] } {
      set cargs(-save_dir) "${pwd}/$cargs(-save_dir)"
    }
  }
  if { $cargs(-spice_cells) eq "" } {
    die "Error: missing -spice_cells option to read_spice_cell_deck"
  }
  set files {}
  foreach file [split [string trim [regsub -all "\[ \t\]+" [join $cargs(-spice_cells)] { }]]] {
    if {![regexp "^\[ \t]*\[\/\$\]" $file] } {
      puts "Info: Parsing -spice_cell file: $cargs(-spice_cells_dir)/$file"
      set tmp [glob -nocomplain "$cargs(-spice_cells_dir)/$file"]
      foreach key1 $tmp {
        lappend files $key1
      }
    } else {
      puts "Info: Parsing -spice_cell file: $file"
      set tmp [glob -nocomplain "$file"]
	puts ">$tmp"
      foreach key1 $tmp {
        lappend files $key1
      }
    }
  }
	puts $files
  set read_spice_cells 0
  set read_files {}
  foreach cell $cells {
	if { [regexp "\\*" $cell] } {
		# check for wildcard in cell name
		set read_spice_cells 1
	} elseif { [llength [glob -nocomplain $cargs(-save_dir)/${cell}.spi]] > 0 } {
		# check if cell already saved
		lappend read_files $cargs(-save_dir)/${cell}.spi
	}  else {
		set read_spice_cells 1
	}
  }
  if { $read_spice_cells } {
	if { [info exists files] && ([llength $files] > 0)} {
	foreach file $files {
	lappend read_files $file
	}
	}
  }
  if { ! [info exists read_files] || ([llength $read_files] == 0 )} {
    die " Error: no -spice_cells file(s) are found/given"
  }
  if { [llength $cells] > 0 } {
  foreach file $read_files {
    if { $file ne ""} {
      if {[regexp ".gz$" $file] } {
      set fin [open [concat "|gzip -d -c $file"] r]
      } else {
      set fin [open "$file" r]
      }
      echo "Reading extracted spice deck file: $file"
      set subname ""
      array set subckt {}
      set line [gets $fin]
      while {![eof $fin]} {
	set nextline [gets $fin]
	while { ![eof $fin] && [regexp "^\[ \t\]*\\\+" $nextline] } {
		regsub "^\[ \t\]*\\\+" $nextline {} nextline	
		append line $nextline
		set nextline [gets $fin]
	}
        if { ($cargs(-save_dir) ne "" ) && ($subname ne "") && [defined -nocase subckt($subname)] } {
          #puts $fout $line
	  lappend sline $line
        }
        if {[regexp -nocase "^\[ \t\]*\[\.\]\[sS\]\[uU\]\[bB\]\[cC\]\[kK\]\[tT\]\[ \t\]+(\[^ \t\]+)" $line dum subname]} {
          set tline $line
	  set sline {}
          regsub -nocase "^\[ \t\]*\[\.\]\[sS\]\[uU\]\[bB\]\[cC\]\[kK\]\[tT\]\[ \t\]+(\[^ \t\]+)" $line {} line
          foreach key2 $cells {
            regsub -all -- "\\\*" $key2 ".\*" key2
            if {[regexp "^$key2$" $subname]} {
              set subckt($subname) 1
              while (1) {
                if {[regexp "^\[ \t\]*(\[^ \t\=\]+)\="  $line dum port]} {
			# param not port
			break
                } elseif {[regexp "^\[ \t\]*(\[^ \t\=\]+)"  $line dum port]} {
                  #set port [string tolower $port]
                  regsub "^\[ \t\]*(\[^ \t\=\]+)"  $line {} line
                  if {![info exists cellarray(cell,$subname,port_list)]} {
                    set cellarray(cell,$subname,port_list) $port
                  } elseif {([lsearch_nocase -nocase -exact cellarray(cell,$subname,port_list) $port] < 0) } {
                    lappend cellarray(cell,$subname,port_list) $port
                  }
                } else {
                  break
                }
              }
              puts "Parsing Spice Cell Deck for $subname"
              lappend sline "*extracted spice deck for cell $subname"
	      lappend sline $tline
              break
            }
          }
          if { ![defined -nocase subckt($subname)] } {
            while {1} {
              set line [gets $fin]
              if {[eof $fin]} {
                close $fin
                break
              }
              if {[regexp -nocase "^\[ \t\]*\[\.\]\[eE\]\[nN\]\[dD\]" $line]} {
                break
              }
            }
	  }
        } elseif {[regexp -nocase "^\[ \t\]*\[R\]\[^ \t\]*\[ \t\]*(\[^ \t\]+)\[ \t\]*(\[^ \t\]+)" $line dum key1 key2]} {
          lappend res($key1) [string tolower $key2]
          lappend res($key2) [string tolower $key1]
        } elseif {[regexp -nocase "^\[ \t\]*(\[XM\]\[^ \t\]*)\[ \t\]*(\[^ \t\]+)\[ \t\]*(\[^ \t\]+)\[ \t\]*(\[^ \t\]+)\[ \t\]*(\[^ \t\]+)" $line dum key1 key2 key3 key4 key5]} {
          lappend drn($key2) [string tolower $key1]
          lappend gate($key3) [string tolower $key1]
          lappend src($key4) [string tolower $key1]
          lappend body($key5) [string tolower $key1]
        } elseif {[regexp -nocase "^\[ \t\]*\[\.\]\[eE\]\[nN\]\[dD\]" $line]} {
          if {[defined -nocase subckt($subname)]} {
            foreach port $cellarray(cell,$subname,port_list) {
              if { ![defined -nocase cellarray(cell,$subname,supply,$port)]} {
                if { [defined -nocase cellarray(cell,-,supply,$port)] } {
                  set cellarray(cell,$subname,supply,$port) [array_get cellarray(cell,-,supply,$port)]
                }
              } else {
                if { [defined -nocase visited] } {
                  unset visited
                }
                lappend visited $port
                set index 0
                while { 1 } {
                  if {$index == [llength $visited] } {
                    break
                  }
                  set net [lindex $visited $index]
                  set net [string tolower $net]
                  if {[info exists body($net)]} {
                    if { ![defined -nocase cellarray(cell,$subname,supply,$port)]} {
                      if { [defined -nocase cellarray(cell,-,supply,$port)] } {
                        set cellarray(cell,$subname,supply,$port) [array_get cellarray(cell,-,supply,$port)]
                      } 
                    }
                    break
                  } elseif {[info exists gate($net)]} {
                    lappend cellarray(cell,$subname,pin,$port,txgates) $gate($net)
                    if { $cargs(-find_direction)} {
                      if { [lsearch_nocase cellarray(cell,$subname,input_list) $port] == -1 } {
                        lappend cellarray(cell,$subname,input_list) $port
                      }
                      lappend cellarray(cell,$subname,port_list) $port
                    }
                  } elseif {[info exists drn($net)] } {
                    lappend cellarray(cell,$subname,pin,$port,txdrns) $drn($net)
                    if { $cargs(-find_direction)} {
                      if { [lsearch_nocase cellarray(cell,$subname,output_list) $port] == -1 } {
                        lappend cellarray(cell,$subname,output_list) $port
                      }
                      lappend cellarray(cell,$subname,port_list) $port
                    }
                  } elseif {[defined -nocase src($net)] } {
                    lappend cellarray(cell,$subname,pin,$port,txsrcs) $src($net)
                    if { $cargs(-find_direction)} {
                      if { [lsearch_nocase cellarray(cell,$subname,output_list) $port] == -1 } {
                        lappend cellarray(cell,$subname,output_list) $port
                      }
                      lappend cellarray(cell,$subname,port_list) $port
                    }
                  }
                  if { [info exists res($net)] } {
                    foreach fanout $res($net) {
                      if { [lsearch_nocase -exact visited $fanout] == -1 } {
                        lappend visited $fanout
                      }
                    }
                  }
                  incr index
                }
              }
            }
            puts "Done Parsing Spice Cell Deck for $subname $cargs(-save_dir)"
	    # is this needed???
            if { ($cargs(-save_dir) ne "") && ![file exists $cargs(-save_dir)/${subname}.spi] } {
              set cellarray(cell,$subname,spice_file) "$cargs(-save_dir)/${subname}.spi"
                set fout [open  $cargs(-save_dir)/${subname}.spi w]
                puts "Writing Spice Cell Deck for cell: ${subname} to $cargs(-save_dir)/${subname}.spi"
		foreach opt $sline {	
		puts $fout $opt
		}
                close $fout
            }
	    if { ![defined -nocase cellarray(cell,$subname,spice_deck)] } {
                set cellarray(cell,$subname,spice_deck) $sline
	    }
          }
          set subname ""
        }
	set line $nextline
      }
      close $fin
    }
  }
  }
  if {[string compare $cargs(-array_name) ""] == 0 } {
    return $cellarray
  }
}
define_myproc_attributes read_spice_cell_deck \
-info "read the lib/db cell data " \
-define_args { \
  {-spice_cells "extracted spice cell file(s)" string string_list optional}
  {-spice_cells_dir "location of extracted spice cell file(s) directory" string string_list optional}
  {-save_dir "save extracted spice cell decks to individual files in working meas dir" string string optional}
  {-cell "name of cell to gather attributes for" string string optional}
  {-find_direction "determine direction of port based on transistor connection" "" boolean optional}
  {-array_name "array to store cell data" string string optional}
}
echo "Defined procedure 'read_spice_cell_deck'."

### generate hspice runscript for batch running hspice monte-carlo 
proc write_pocv_runscript { args } {
  global __script_dir
  global __date
  set cargs(-cell) ""
  set cargs(-db) ""
  set cargs(-library) ""
  set cargs(-array_name) ""
  set cargs(-spice_file) "*o-*.i-*.m-*.sp"
  set cargs(-nt_spice_file) "*o-*.i-*.NT.*.sp"
  set cargs(-hsp_runscript) "run_hsp_pocv"
  set cargs(-delay_runscript) "run_create_delay_variation"
  set cargs(-nt_coeff_runscript) "run_create_variation_coeff"
  set cargs(-nt_coeff_file) "nt_set_variation_parameter"
  set cargs(-nt_coeff_append) 0
  set cargs(-nt_coeff_max_logic_depth) 4
  set cargs(-nt_coeff_nmos) "nch_mac"
  set cargs(-nt_coeff_nmos_length) ".016"
  set cargs(-nt_coeff_nmos_width) ""
  set cargs(-nt_coeff_nmos_nfin) ""
  set cargs(-nt_coeff_nmos_nf) ""
  set cargs(-nt_coeff_pmos) "pch_mac"
  set cargs(-nt_coeff_pmos_length) ".016"
  set cargs(-nt_coeff_pmos_width) ""
  set cargs(-nt_coeff_pmos_nfin) ""
  set cargs(-nt_coeff_pmos_nf) ""
  set cargs(-mean_mode) "avg"
  set cargs(-sigma_mode) "avg"
  set cargs(-table_runscript) "run_create_aocv_table"
  set cargs(-setup_runscript) "run_create_pocv_setup"
  set cargs(-nt_runscript) "run_ntpocv"
  set cargs(-csv_runscript) "run_csv_compare"
  set cargs(-spice_path) ""
  set cargs(-spice_type) "hspice"
  set cargs(-nt_path) ""
  set cargs(-nt_tcl_script) "/slowfs/cae025/nt/bin/pocv_plus.tcl"
  set cargs(-nt_type) "nt_shell"
  set cargs(-force) 0
  set cargs(-vars) 0
  set cargs(-init_file) ""
  set cargs(-no_batch) 0
  set cargs(-no_nt_batch) 0
  set cargs(-submit) "qsub -V -P bnormal -cwd -b y -j y -m n -l mem_free=4G,mem_avail=4G,arch=glinux"
  set cargs(-nt_submit) ""
  set cargs(-pt_submit) ""
  set cargs(-no_predrvr_load) 0
  set cargs(-add_predrvr_cnt) 0
  set cargs(-no_predrvr_variation) 0
  set cargs(-nmos_only) 0
  set cargs(-pmos_only) 0
  set cargs(-disable_local_params) "mismatchflag=0"
  set cargs(-disable_predrvr_local_params) "mismatchflag=0"
  set cargs(-ref_spice_model) ""
  set cargs(-ref_spice_lib) ""
  set cargs(-local_params) ""
  set cargs(-global_params) ""
  set cargs(-spice_options) ""
  set cargs(-accurate) 0
  set cargs(-spice_cells) ""
  set cargs(-spice_cells_dir) ""
  set cargs(-spice_model) ""
  set cargs(-spice_lib) ""
  set cargs(-spice_output) ""
  set cargs(-spice_ext) "POCV.sp"
  set cargs(-tcl_ext) "NT.POCV.tcl"
  set cargs(-csv_ext) "NT.POCV.csv"
  set cargs(-paths_ext) "NT.POCV.paths"
  set cargs(-array_name) ""
  set cargs(-cell) ""
  set cargs(-pocv_dir) "."
  set cargs(-meas_dir) "."
  set cargs(-stage_fanout) 1
  set cargs(-max_logic_depth) 15
  set cargs(-spice_logic_depth) 4
  set cargs(-input) ""
  set cargs(-mis_input) ""
  set cargs(-add_stage_var) 0
  set cargs(-output) ""
  set cargs(-all_inputs) 0
  set cargs(-all_outputs) 0
  set cargs(-all_sensitizations) 0
  set cargs(-comp_output) ""
  set cargs(-port_list) ""
  set cargs(-ic) ""
  set cargs(-supply) ""
  set cargs(-no_supply_source) 0
  set cargs(-sensitization_data) ""
  set cargs(-max_fanin_trans) ""
  set cargs(-max_fanin_trans_fall) ""
  set cargs(-max_fanout_cap) ""
  set cargs(-max_fanout_cap_pct) 1
  set cargs(-predrvr_max_fanout_cap_pct) ""
  set cargs(-max_fanin_trans_pct) 1
  set cargs(-monte) 2000
  set cargs(-monte_split) 400
  set cargs(-temp) ""
  set cargs(-period) 4.0
  set cargs(-cycles) 2
  set cargs(-high_pulse) ""
  set cargs(-tran_start) 1.0
  set cargs(-tran_step) .001
  set cargs(-tran_stop) ""
  set cargs(-rccap) 1.0
  set cargs(-rcres) 10.0
  set cargs(-rcseg) 0
  set cargs(-meas_from_cross) 1
  set cargs(-meas_to_cross) 1
  set cargs(-meas_from_cross_rf_incr) 1
  set cargs(-meas_to_cross_rf_incr) 1
  set cargs(-meas_from_cross_rf_mult) 0
  set cargs(-meas_from_cross_rf_exp) 0
  set cargs(-meas_from_cross_rf_exp_mult) 0
  set cargs(-meas_from_cross_level_mult) 0
  set cargs(-meas_from_cross_level_exp) 0
  set cargs(-meas_from_cross_level_exp_mult) 0
  set cargs(-meas_from_edge) "CROSS"
  set cargs(-meas_td) ""
  set cargs(-upper_slew) ""
  set cargs(-lower_slew) ""
  set cargs(-delay_meas) ""
  set cargs(-inc_temp)  0
  set cargs(-inc_spice_cells)  0
  set cargs(-time_unit) ""
  set cargs(-cap_unit) "FF"
  # set sqrtN mode
  set cargs(-sqrtN) 0
  #analysis_modes "same_cell drive_cell alternate_cell"
  set cargs(-cell_chain_mode) "same_cell"
  # mean modes are "first last avg max min"
  set cargs(-sqrtN_mean_mode) "last"
  # vardiff modes are "first last avg max min"
  set cargs(-sqrtN_vardiff_mode) "last"
  # variation_modes: all_tx, switching_only, ignore_off
  set cargs(-variation_mode) "all_tx"
  set cargs(-fanout_cap_mode) "max_fanout_cap_pct"
  set cargs(-fanin_trans_mode) "max_fanin_trans_pct"
  set cargs(-meas_depth_list) {}
  set cargs(-input_pin_cap) {}


  set cargs(-measure_data_extension) ".mt0"
  set cargs(-max_value) "999999999999999"
  set cargs(-min_value) "-999999999999999"	
  set cargs(-dataarray) "sigdata"
  set cargs(-meas) ""
  set cargs(-stat_file) ""

  set cargs(-early_margin_pct) 0.0
  set cargs(-late_margin_pct) 0.0
  set cargs(-path_type) ""
  set cargs(-vdd) ""
  set cargs(-dataarray) ""
  set cargs(-refdataarray) ""
  set cargs(-pocv_file) ""
  set cargs(-object_type) "lib_cell"
  set cargs(-rf_type) "rise fall"
  set cargs(-delay_type) "cell"
  set cargs(-derate_type) ""
  set cargs(-object_spec) ""
  set cargs(-depth) ""
  set cargs(-qlo) ".00135"
  set cargs(-qhi) ".99865"
  set cargs(-no_curve_fit) 0
  set cargs(-append) 0
  set cargs(-force_pessimistic_monotonic) 0
  set cargs(-sig_digits) 5
  set cargs(-del_meas_var) "pocv_d_o#"
  set cargs(-rf_meas_var) "pocv_rf_o#"
  set cargs(-rf_sep) "_\\\[12\\\]"
  set cargs(-min_early_derate) ""
  set cargs(-max_early_derate) ""
  set cargs(-min_late_derate) ""
  set cargs(-max_late_derate) ""
  set cargs(-depth_scale) 1
  set cargs(-scripts_dir) ""
  set cargs(-drive_cell) ""
  set cargs(-vss)  0.0
  set cargs(-path_ordered) 0

  set cargs(-object_spec) ""

  set cargs(-nt) 0

  if { [parse_myproc_arguments -debug -args $args cargs] eq "0" } {
  	return 0
  }


  set was {}
  if {[string compare $cargs(-array_name) ""] != 0 } {
    upvar 1 $cargs(-array_name) cellarray
    append was " -array_name cellarray"
  }

  if { $cargs(-debug) } {
	append was " -debug"
  }

  if { $cargs(-scripts_dir) eq "" } {
    if  { [info exists __script_dir] } {
      set cargs(-scripts_dir) "$__script_dir"
    } else {
      set cargs(-scripts_dir) "./scripts"
    }
  }
	set cargs(-rf_sep) [string trim $cargs(-rf_sep) "\{\}\""]
	set cargs(-del_meas_var) [string trim $cargs(-del_meas_var) "\{\}\""]
	set cargs(-rf_meas_var) [string trim $cargs(-rf_meas_var) "\{\}\""]

  set pwd [pwd]
  set pwd [string trim $pwd]

  if { $cargs(-cell) eq "" } {
	puts "Error: missing -cell option"
	return 0
  }

  if { ($cargs(-spice_model) eq "") && ($cargs(-ref_spice_model) eq "" ) && ($cargs(-ref_spice_lib) eq "") && ($cargs(-spice_lib) eq "")  } {
    die "Error: no spice_model file given"
  }

  if { $cargs(-ref_spice_model) ne "" } {
  if { ![regexp "^\[ \t]*\[\/\$\]" $cargs(-ref_spice_model)] } {
    set cargs(-ref_spice_model) "${pwd}/$cargs(-ref_spice_model)"
  }
  }

  if { $cargs(-spice_model) ne "" } {
  if { ![regexp "^\[ \t]*\[\/\$\]" $cargs(-spice_model)] } {
    set cargs(-spice_model) "${pwd}/$cargs(-spice_model)"
  }
  }

  if { $cargs(-spice_cells) eq "" } {
    die "Error: no extracted spice_cells file given"
  }

  if { $cargs(-spice_cells_dir) eq "" } {
    set cargs(-spice_cells_dir) ${pwd}
  } 

  if { ![regexp "^\[ \t]*\[\/\$\]" $cargs(-scripts_dir)] } {
    set cargs(-scripts_dir) "${pwd}/$cargs(-scripts_dir)"
  }

  if { ![regexp "^\[ \t]*\[\/\$\]" $cargs(-meas_dir)] } {
    set cargs(-meas_dir) "${pwd}/$cargs(-meas_dir)"
  }
  if { ![file isdirectory $cargs(-meas_dir)] } {
    exec mkdir $cargs(-meas_dir)
  }
  if { ![regexp "^\[ \t]*\[\/\$\]" $cargs(-pocv_dir)] } {
    set cargs(-pocv_dir) "${pwd}/$cargs(-pocv_dir)"
  }
  if { ![file isdirectory $cargs(-pocv_dir)] } {
    exec mkdir $cargs(-pocv_dir)
  }

  if { ![regexp "^\[ \t]*\[\/\$\]" $cargs(-delay_runscript)] } {
	set cargs(-delay_runscript) "$cargs(-meas_dir)/$cargs(-delay_runscript)"
  }
  if { ![regexp "^\[ \t]*\[\/\$\]" $cargs(-nt_coeff_runscript)] } {
	set cargs(-nt_coeff_runscript) "$cargs(-meas_dir)/$cargs(-nt_coeff_runscript)"
  }
  if { ![regexp "^\[ \t]*\[\/\$\]" $cargs(-nt_coeff_file)] } {
	set cargs(-nt_coeff_file) "${pwd}/$cargs(-nt_coeff_file)"
  }
  if { ![regexp "^\[ \t]*\[\/\$\]" $cargs(-nt_tcl_script)] } {
	set cargs(-nt_tcl_script) "${pwd}/$cargs(-nt_tcl_script)"
  }
  if { ![regexp "^\[ \t]*\[\/\$\]" $cargs(-table_runscript)] } {
	set cargs(-table_runscript) "$cargs(-meas_dir)/$cargs(-table_runscript)"
  }
  if { ![regexp "^\[ \t]*\[\/\$\]" $cargs(-setup_runscript)] } {
	set cargs(-setup_runscript) "$cargs(-meas_dir)/$cargs(-setup_runscript)"
  }
  if { ![regexp "^\[ \t]*\[\/\$\]" $cargs(-hsp_runscript)] } {
	set cargs(-hsp_runscript) "$cargs(-meas_dir)/$cargs(-hsp_runscript)"
  }
  if { $cargs(-nt) && ![regexp "^\[ \t]*\[\/\$\]" $cargs(-nt_runscript)] } {
	set cargs(-nt_runscript) "$cargs(-meas_dir)/$cargs(-nt_runscript)"
  }
  if { $cargs(-nt) && ![regexp "^\[ \t]*\[\/\$\]" $cargs(-csv_runscript)] } {
	set cargs(-csv_runscript) "$cargs(-meas_dir)/$cargs(-csv_runscript)"
  }

  set mca {}
  set rmd {}
  set hrs {}
  set gat  "-no_curve_fit"
  set gsd {}
  set gdc {}
  set wnt {}

  foreach opt  [list no_curve_fit force_pessimistic_monotonic] {
  if { $cargs(-$opt) } {
  append mca " -$opt"
  }
  }
  foreach opt  [list append sqrtN] {
  if { $cargs(-$opt) } {
  append gat " -$opt"
  }
  }

   if {$cargs(-nt_coeff_append) } {
  append gdc " -max_logic_depth $cargs(-nt_coeff_max_logic_depth) -path_ordered -append"
   } else {
  append gdc " -max_logic_depth $cargs(-nt_coeff_max_logic_depth) -path_ordered"
   }
  append gdc " -mean_mode $cargs(-mean_mode) -sigma_mode $cargs(-sigma_mode)"
  foreach opt  [list nt_coeff_nmos nt_coeff_nmos_length nt_coeff_nmos_width nt_coeff_nmos_nfin nt_coeff_nmos_nf nt_coeff_pmos nt_coeff_pmos_length nt_coeff_pmos_width nt_coeff_pmos_nfin nt_coeff_pmos_nf supply] {
  if { $cargs(-$opt) ne "" } {
  set newopt [regsub "nt_coeff_" $opt {}]
  append  gdc " -$newopt \"$cargs(-$opt)\""
  }
  }
 if { $cargs(-vdd) ne "" } {
	append gdc " -nmos_vdd $cargs(-vdd)"
	append gdc " -pmos_vdd $cargs(-vdd)"
 } 

  if { $cargs(-sqrtN) } {
	append gat " -max_logic_depth $cargs(-max_logic_depth)"
	append gat " -max_read_logic_depth $cargs(-spice_logic_depth)"
  } else {
	append gat " -max_logic_depth $cargs(-max_logic_depth)"
  }
  append gsd " -max_logic_depth $cargs(-max_logic_depth)"

  if { $cargs(-path_ordered) } {
  append gsd " -path_ordered"
  }

  foreach opt  [list depth_scale max_late_derate min_late_derate max_early_derate min_early_derate sqrtN_vardiff_mode sqrtN_mean_mode cell_chain_mode rf_meas_var del_meas_var sig_digits max_value min_value qlo qhi depth vdd path_type early_margin_pct late_margin_pct library object_type rf_type delay_type derate_type object_spec rf_sep] {
  if { $cargs(-$opt) ne "" } {
  append  gat " -$opt \"$cargs(-$opt)\""
  }
  }

  #foreach opt  [list meas_dir measure_data_extension max_value min_value stat_file] 
  if { $cargs(-meas_dir) ne "" } {
  append  rmd " -meas_dir \"\$__meas_dir\""
  }
  foreach opt  [list measure_data_extension stat_file] {
  if { $cargs(-$opt) ne "" } {
  append  rmd " -$opt \"$cargs(-$opt)\""
  }
  }

  foreach opt [list nt_spice_file nt_path nt_submit nt_type meas_dir] {
  if { $cargs(-$opt) ne "" } {
  append  nrs " -$opt \"$cargs(-$opt)\""
  }
  }
  foreach opt [list force no_nt_batch] {
  if { $cargs(-$opt) } {
  append nrs " -$opt"
  }
  }


  foreach opt [list spice_file spice_path submit spice_type meas_dir] {
  if { $cargs(-$opt) ne "" } {
  append  hrs " -$opt \"$cargs(-$opt)\""
  }
  }
  foreach opt [list force no_batch] {
  if { $cargs(-$opt) } {
  append hrs " -$opt"
  }
  }

	# me_+write_ntpocv_tcl
  foreach opt [list inc_spice_cells debug] {
  if { $cargs(-$opt) } {
  append wnt " -$opt"
  }
  }
  foreach opt  [list spice_cells spice_cells_dir spice_output tcl_ext paths_ext csv_ext spice_ext port_list supply  period cycles high_pulse tran_start upper_slew lower_slew delay_meas time_unit cap_unit add_predrvr_cnt sig_digits nt_tcl_script max_fanin_trans_pct fanin_trans_mode nt_coeff_file meas_dir] {
  if { $cargs(-$opt) ne "" } {
  append wnt " -$opt \"$cargs(-$opt)\""
  }
  }

	# write_pocv_spice_deck
  foreach opt [list no_predrvr_load nmos_only pmos_only accurate inc_temp inc_spice_cells no_predrvr_variation no_supply_source nt debug] {
  if { $cargs(-$opt) } {
  append was " -$opt"
  }
  }
  

  if { $cargs(-sqrtN) } {
	append was " -max_logic_depth $cargs(-spice_logic_depth)"
  } else {
	append was " -max_logic_depth $cargs(-max_logic_depth)"
  }
  foreach opt [list pocv_dir meas_dir] {
	append was " -$opt \" \$__${opt}\""
  }
  foreach opt [list disable_local_params disable_predrvr_local_params local_params global_params spice_options spice_cells spice_cells_dir spice_output spice_ext stage_fanout comp_output port_list supply ic monte monte_split temp period cycles high_pulse tran_start tran_step tran_stop rcseg rccap rcres max_fanin_trans max_fanin_trans_fall max_fanout_cap max_fanout_cap_pct predrvr_max_fanout_cap_pct max_fanin_trans_pct meas_from_cross meas_to_cross meas_from_cross_rf_incr meas_to_cross_rf_incr meas_from_cross_rf_mult meas_from_cross_rf_exp meas_from_cross_rf_exp_mult meas_from_cross_level_mult meas_from_cross_level_exp meas_from_cross_level_exp_mult meas_from_edge meas_td upper_slew lower_slew delay_meas time_unit cap_unit cell_chain_mode variation_mode fanout_cap_mode fanin_trans_mode meas_depth_list input_pin_cap add_predrvr_cnt sig_digits vss mis_input] {
  if { $cargs(-$opt) ne "" } {
  append was " -$opt \"$cargs(-$opt)\""
  }
  }

  set all_cells [split [regsub -all "\[ \t\]+" [string trim [join $cargs(-cell)]] { }]]
  if { $cargs(-debug) } {
	puts "ALL_CELLS: $all_cells"
  }
 

  puts "\nCreating runscript($cargs(-setup_runscript)) for setting up pocv analysis"
  set fout [open $cargs(-setup_runscript) w]
  puts $fout "#!/bin/sh"
  puts $fout "# the next line restarts using tclsh \\"
  puts $fout "exec tclsh \"\$0\" \"\$\@\""

  puts $fout "set __script_dir $cargs(-scripts_dir)"
  puts $fout "global __script_dir"
  puts $fout "set __meas_dir $cargs(-meas_dir)"
  puts $fout "global __meas_dir"
  puts $fout "set __pocv_dir $cargs(-pocv_dir)"
  puts $fout "global __pocv_dir"

   puts $fout "set __date \[clock format \[clock seconds\] -format \{\%a \%b \%d \%H:\%M:\%S \%Z \%Y\}\]"
   puts $fout "global __date"
   if { $cargs(-init_file) ne "" } {
	puts $fout "source $carg(-init_file)"
   }


  set rdb ""
  foreach opt [list pt_submit] {
	append rdb " -pt_submit $cargs(-pt_submit)"
  }

   puts $fout "if \{ \[file exists \$__script_dir/Simple_pocv_generation.tcl\] \} \{"
   puts $fout "  source \$__script_dir/Simple_pocv_generation.tcl"
   puts $fout "\} else \{"
   puts $fout "  puts \"ERROR: Simple_pocv_generation.tcl not found(Please place all POCV script files in same directory)\""
   puts $fout "  exit"
   puts $fout "\}"
   puts $fout "if \{ \[file exists \$__script_dir/general_pocv.tcl\] \} \{"
   puts $fout "   source \$__script_dir/general_pocv.tcl"
   puts $fout "\} else \{"
   puts $fout "   puts \"ERROR: general_pocv.tcl not found(Please place all POCV script files in same directory)\""
   puts $fout "   exit"
   puts $fout "\}"
   puts $fout "if \{ \[file exists \$__script_dir/read_db_data.tcl\] \} \{"
   puts $fout "   source \$__script_dir/read_db_data.tcl"
   puts $fout "\} elseif \{ \[file exists \$__script_dir/read_db_data.tbc\] \} \{"
   puts $fout "   append auto_path \" \$__script_dir/tbcload\""
   puts $fout "   package require tbcload 1.4"
   puts $fout "   source \$__script_dir/read_db_data.tbc"
   puts $fout "\} else \{"
   puts $fout "   puts \"ERROR: read_db_data.tbc not found(Please place all POCV script files in same directory)\""
   puts $fout "   exit"
   puts $fout "\}"
   set cargs(-cell) [regsub -all "\[ \t\]+" [string trim [join $cargs(-cell)]] { }] 

   puts $fout "array set cellarray \{\}"
   # if DB/.lib is given then use the byte code to grab some attributes
   if { ($cargs(-db) ne "") } {
    ## check if DB defined -nocase
    puts $fout "if \{(\[info procs ::read_db_cell_data\] ne \"\")\} \{"
  if { [regexp "custom" $cargs(-cell_chain_mode)]} {
    puts $fout "eval ::read_db_cell_data -array_name cellarray -db \"$cargs(-db)\" -tmplt_dir \$__meas_dir -scripts_dir \$__script_dir -cell \"$cargs(-cell)\" -pwd [pwd] $rdb"
  } elseif { [regexp "drive" $cargs(-cell_chain_mode)]} {
    puts $fout "eval ::read_db_cell_data -array_name cellarray -db \"$cargs(-db)\" -tmplt_dir \$__meas_dir -scripts_dir \$__script_dir -cell \"$cargs(-cell)\" -pwd [pwd] $rdb"
    puts $fout "eval ::read_db_cell_data -array_name cellarray -db \"$cargs(-db)\" -tmplt_dir \$__meas_dir -scripts_dir \$__script_dir -cell \"$cargs(-drive_cell)\" -pwd [pwd] $rdb"
  } elseif { [regexp "same" $cargs(-cell_chain_mode)]} {
    puts $fout "eval ::read_db_cell_data -array_name cellarray -db \"$cargs(-db)\" -tmplt_dir \$__meas_dir -scripts_dir \$__script_dir -cell \"$cargs(-cell)\" -pwd [pwd] $rdb"
  } elseif { [regexp "alter" $cargs(-cell_chain_mode)]} {
    puts $fout "eval ::read_db_cell_data -array_name cellarray -db \"$cargs(-db)\" -tmplt_dir \$__meas_dir -scripts_dir \$__script_dir -cell \"$cargs(-cell)\" -pwd [pwd] $rdb"
    if { $cargs(-drive_cell) ne "" } {
    puts $fout "eval ::read_db_cell_data -array_name cellarray -db \"$cargs(-db)\" -tmplt_dir \$__meas_dir -scripts_dir \$__script_dir -cell \"$cargs(-drive_cell)\" -pwd [pwd] $rdb"
    }
  }
    puts $fout "\}"
   } elseif { ($cargs(-library) ne "") } {
    puts $fout "if \{(\[info procs ::read_db_cell_data\] ne \"\")\} \{"
  if { [regexp "custom" $cargs(-cell_chain_mode)]} {
    puts $fout "eval ::read_db_cell_data -array_name cellarray -library \"$cargs(-library)\" -tmplt_dir \$__meas_dir -scripts_dir \$__script_dir -cell \"$cargs(-cell)\" -pwd [pwd] $rdb"
  } elseif { [regexp "drive" $cargs(-cell_chain_mode)]} {
    puts $fout "eval ::read_db_cell_data -array_name cellarray -library \"$cargs(-library)\" -tmplt_dir \$__meas_dir -scripts_dir \$__script_dir -cell \"$cargs(-cell)\" -pwd [pwd] $rdb"
    puts $fout "eval ::read_db_cell_data -array_name cellarray -library \"$cargs(-library)\" -tmplt_dir \$__meas_dir -scripts_dir \$__script_dir -cell \"$cargs(-drive_cell)\" -pwd [pwd] $rdb"
  } elseif { [regexp "same" $cargs(-cell_chain_mode)]} {
    puts $fout "eval ::read_db_cell_data -array_name cellarray -library \"$cargs(-library)\" -tmplt_dir \$__meas_dir -scripts_dir \$__script_dir -cell \"$cargs(-cell)\" -pwd [pwd] $rdb"
  } elseif { [regexp "alter" $cargs(-cell_chain_mode)]} {
    puts $fout "eval ::read_db_cell_data -array_name cellarray -library \"$cargs(-library)\" -tmplt_dir \$__meas_dir -scripts_dir \$__script_dir -cell \"$cargs(-cell)\" -pwd [pwd] $rdb"
    if { $cargs(-drive_cell) ne "" } {
    puts $fout "eval ::read_db_cell_data -array_name cellarray -library \"$cargs(-library)\" -tmplt_dir \$__meas_dir -scripts_dir \$__script_dir -cell \"$cargs(-drive_cell)\" -pwd [pwd] $rdb"
    }
  }
    puts $fout "\}"
  }


  ## read spice decks
  if { [regexp "custom" $cargs(-cell_chain_mode)]} {
  puts $fout "     ::read_spice_cell_deck -cell \"$cargs(-cell)\"  -spice_cells \{ $cargs(-spice_cells)\}  -array_name cellarray -save_dir \$__meas_dir -spice_cells_dir $cargs(-spice_cells_dir)"
  } elseif {[regexp "drive"  $cargs(-cell_chain_mode)]} {
  puts $fout "     ::read_spice_cell_deck -cell \"$cargs(-cell)\"  -spice_cells \{ $cargs(-spice_cells)\}  -array_name cellarray -save_dir \$__meas_dir -spice_cells_dir $cargs(-spice_cells_dir)"
  puts $fout "     ::read_spice_cell_deck -cell \"$cargs(-drive_cell)\"  -spice_cells \{ $cargs(-spice_cells)\}  -array_name cellarray -save_dir \$__meas_dir -spice_cells_dir $cargs(-spice_cells_dir)"
  } elseif { [regexp "same" $cargs(-cell_chain_mode)]} {
  puts $fout "     ::read_spice_cell_deck -cell \"$cargs(-cell)\"  -spice_cells \{ $cargs(-spice_cells)\}  -array_name cellarray -save_dir \$__meas_dir -spice_cells_dir $cargs(-spice_cells_dir)"
  } elseif { [regexp "alter" $cargs(-cell_chain_mode)]} {
  puts $fout "     ::read_spice_cell_deck -cell \"$cargs(-cell)\"  -spice_cells \{ $cargs(-spice_cells)\}  -array_name cellarray -save_dir \$__meas_dir -spice_cells_dir $cargs(-spice_cells_dir)"
  if { $cargs(-drive_cell) ne "" } {
  puts $fout "     ::read_spice_cell_deck -cell \"$cargs(-drive_cell)\"  -spice_cells \{ $cargs(-spice_cells)\}  -array_name cellarray -save_dir \$__meas_dir -spice_cells_dir $cargs(-spice_cells_dir)"
  }
  }

  if { [regexp "custom" $cargs(-cell_chain_mode)]} {
  } elseif { [regexp "drive" $cargs(-cell_chain_mode)]} {
  puts $fout "  set drivecellname \[lindex \[split \"$cargs(-drive_cell)\"\] 0\]"
  puts $fout "  if \{ \[array exists cellarray\] && (\[llength \[keys cellarray(cell)\] \] \> 0 )\} \{"
  puts $fout "    set drivecells \[keys cellarray(cell)\]"
  puts $fout "  \} else \{"
  puts $fout "    set drivecells \$drivecellname"
  puts $fout "  \}"
  puts $fout "  set drivecell \[lindex \[lsearch \-all \-inline \$drivecells \$drivecellname\] 0\]"
  } elseif { [regexp "alter" $cargs(-cell_chain_mode)]} {
  if { $cargs(-drive_cell) ne "" } {
  puts $fout "  set drivecellname \[lindex \[split \"$cargs(-drive_cell)\"\] 0\]"
  puts $fout "  if \{ \[array exists cellarray\] && (\[llength \[keys cellarray(cell)\] \] \> 0 )\} \{"
  puts $fout "    set drivecells \[keys cellarray(cell)\]"
  puts $fout "  \} else \{"
  puts $fout "    set drivecells \$drivecellname"
  puts $fout "  \}"
  puts $fout "  set drivecell \[lindex \[lsearch \-all \-inline \$drivecells \$drivecellname\] 0\]"
  }
  }
  puts $fout "foreach cellname \[split \"$cargs(-cell)\"\] \{"
  puts $fout "  set cellname \[string trim \$cellname\]"
  puts $fout "  if \{ \[array exists cellarray\] && (\[llength \[keys cellarray(cell)\] \] \> 0 )\} \{"
  puts $fout "    set cells \[keys cellarray(cell)\]"
  puts $fout "  \} else \{"
  puts $fout "    set cells \$cellname"
  puts $fout "  \}"
  puts $fout "  foreach cell \[lsearch \-all \-inline \$cells \$cellname\] \{"
  puts $fout "    puts \"Processing Cell: \$cell\""

  if { ($cargs(-output) eq "") } {
	if { (($cargs(-db) ne "" ) || ($cargs(-library) ne "" )) } {
	if { $cargs(-all_outputs) } {
	puts $fout "if \{ \[array exists cellarray\] && \[info exists cellarray(cell,\$cell,output_list)\] \} \{"
	puts $fout "set outputs \$cellarray(cell,\$cell,output_list)"
	puts $fout "\} elseif \{ \[array exists cellarray\] && \[info exists cellarray(cell,\$cell,output)\] \} \{"
	puts $fout "set outputs \$cellarray(cell,\$cell,output)"
	puts $fout "\} else \{"
	puts $fout "puts \"Error: no output pin given or found, use -output option to specify\""
	puts $fout "return 0"
	puts $fout "\}"
	} else {
	puts $fout "if \{ \[array exists cellarray\] && \[info exists cellarray(cell,\$cell,output)\] \} \{"
	puts $fout "set outputs \$cellarray(cell,\$cell,output)"
	puts $fout "\} else \{"
	puts $fout "puts \"Error: no output pin given or found, use -output option to specify\""
	puts $fout "return 0"
	puts $fout "\}"
	}
	} else {
	puts "Error: no output pin given or found, use -output or -db/-library option to specify"
	return 0
	}
  } else {
	puts $fout "set outputs \"$cargs(-output)\""
  }
  if { ($cargs(-input) eq "") } {
	if { (($cargs(-db) ne "" ) || ($cargs(-library) ne "" )) } {
	if { $cargs(-all_inputs) } {
	puts $fout "if \{ \[array exists cellarray\] && \[info exists cellarray(cell,\$cell,input_list)\] \} \{"
	puts $fout "set inputs \$cellarray(cell,\$cell,input_list)"
	puts $fout "\} elseif \{ \[array exists cellarray\] && \[info exists cellarray(cell,\$cell,input)\] \} \{"
	puts $fout "set inputs \$cellarray(cell,\$cell,input)"
	puts $fout "\} else \{"
	puts $fout "puts \"Error: no input pin given or found, use -input option to specify\""
	puts $fout "return 0"
	puts $fout "\}"
	} else {
	puts $fout "if \{ \[array exists cellarray\] && \[info exists cellarray(cell,\$cell,input)\] \} \{"
	puts $fout "set inputs \$cellarray(cell,\$cell,input)"
	puts $fout "\} else \{"
	puts $fout "puts \"Error: no input pin given or found, use -input option to specify\""
	puts $fout "return 0"
	puts $fout "\}"
	}
	} else {
	puts "Error: no output pin given or found, use -input or -db/-library option to specify"
	return 0
	}
  } else {
	puts $fout "set inputs \"$cargs(-input)\""
  }
  puts $fout "set outputs \[regsub -all \"\\\[ \\t\\\]+\" \[string trim \[join \$outputs\]\] \{ \}\]"
  if { [regexp "same" $cargs(-cell_chain_mode)] } {
  puts $fout "if \{ \[regexp \"\$cell:\" \$outputs\] \} \{"
  puts $fout "   set list_outputs \"\$outputs\""
  puts $fout "\} else \{"
  puts $fout "   set list_outputs \[split \"\$outputs\"\]"
  puts $fout "\}"
  puts $fout "foreach output \$list_outputs \{"	
  puts $fout "   set cell_output \$output"
  } else {
  puts $fout "   set cell_output \$outputs"
  puts $fout "   set output \$outputs"
  }
  puts $fout "   if \{\[regexp \"\$cell\:\(\\\[^ \\\]+\)\" \$cell_output match output\]\} \{"
  puts $fout "   \} else \{"
  puts $fout "       set cell_output \$cell\:\$output"
  puts $fout "   \}"

  puts $fout "set inputs \[regsub -all \"\\\[ \\t\\\]+\" \[string trim \[join \$inputs\]\] \{ \}\]"
  if { [regexp "same" $cargs(-cell_chain_mode)] } {
  puts $fout "if \{ \[regexp \"\$cell:\" \$inputs\] \} \{"
  puts $fout "   set list_inputs \"\$inputs\""
  puts $fout "\} else \{"
  puts $fout "   set list_inputs \[split \"\$inputs\"\]"
  puts $fout "\}"
  puts $fout "foreach input \$list_inputs \{"
  puts $fout "   set cell_input \$input"
  } else {
  puts $fout "   set cell_input \$inputs"
  puts $fout "   set input \$inputs"
  }
  puts $fout "   if \{\[regexp \"\$cell\:\(\\\[^ \\\]+\)\" \$cell_input match input\]\} \{"
  puts $fout "   \} else \{"
  puts $fout "       set cell_input \$cell\:\$input"
  puts $fout "   \}"
  puts $fout "set scnt 0"
	#puts "HERE $cargs(-sensitization_data) [regexp -- \"\" $cargs(-sensitization_data)]"
  if { ![regexp -- "^\[\}\{\]*$" $cargs(-sensitization_data)] } {
	# ($cargs(-sensitization_data) ne "\{\}") && !(([llength $cargs(-sensitization_data)] == 1) && ([lindex $cargs(-sensitization_data) 0 ] ne  "\{\}")) 
	#puts "HERE $cargs(-sensitization_data)"
  if { $cargs(-all_sensitizations) } {
  puts $fout "set all_sensitizations 1"
  } else {
  puts $fout "set all_sensitizations 0"
  }
  puts $fout "foreach sensitize \[list $cargs(-sensitization_data)\] \{"
  puts $fout "   if \{\[regexp \-nocase \"\^\\\[ \\\]\*\$cell\\\[ \\\]\*\\\[:\\\]\\\[ \\\]*\$input\\\[ \\\]\+\$output\\\[ \\\]\+\" \$sensitize\]  \|\| \[regexp \-nocase \"\^\\\[ \\\]\*\$cell\\\[ \\\]\*\\\[:\\\]\\\[ \\\]*\$input\\\[ \\\]\+\" \$sensitize\] \|\| \[regexp \-nocase \"\^\\\[ \\\]\*\$input\\\[ \\\]\+\$output\\\[ \\\]\+\" \$sensitize\] \|\|  \[regexp \-nocase \"\^\\\[ \\\]\*\$input\\\[ \\\]\+\" \$sensitize\] \|\| \[regexp \"\^\\\[ \\\]\*\\\[\^ \\\=\\\]\+\\\[ \\\]\*\=\" \$sensitize\] \} \{"
  if { $cargs(-ref_spice_model) ne "" } {
  # write_pocv_spice -ref_spice_model ...
  if { $cargs(-nt) } {
  puts $fout "write_ntpocv_tcl -input \$cell_input -output \$cell_output -cell \"\$cell\"  -array_name cellarray -ref_spice_model $cargs(-ref_spice_model)  -spice_file \$cell.o-\$output.i-\$input.s-\$\{scnt\}.NT -tcl \$cell.o-\$output.i-\$input.s-\$\{scnt\} $wnt"
  }
  if { [regexp "custom" $cargs(-cell_chain_mode)]} {
  } elseif { [regexp "drive" $cargs(-cell_chain_mode)]} {
  puts $fout "write_pocv_spice_deck -cell \"\$cell \$drivecell\" -array_name cellarray -ref_spice_model $cargs(-ref_spice_model) -input \$cell_input -output \$cell_output -sensitization_data \"\$sensitize\" -spice_output \$cell.o-\$output.i-\$input.s-\$scnt.ref $was"
  } elseif { [regexp "same" $cargs(-cell_chain_mode)]} {
  puts $fout "write_pocv_spice_deck -cell \$cell -array_name cellarray -ref_spice_model $cargs(-ref_spice_model) -input \$cell_input -output \$cell_output -sensitization_data \"\$sensitize\" -spice_output \$cell.o-\$output.i-\$input.s-\$scnt.ref $was"
  } elseif { [regexp "alter" $cargs(-cell_chain_mode)]} {
  puts $fout "write_pocv_spice_deck -cell \"\$cell \$drivecell\" -array_name cellarray -ref_spice_model $cargs(-ref_spice_model) -input \$cell_input -output \$cell_output -sensitization_data \"\$sensitize\" -spice_output \$cell.o-\$output.i-\$input.s-\$scnt.ref $was"
  }
  } elseif { $cargs(-ref_spice_lib) ne "" } {
  # write_pocv_spice -ref_spice_lib ...
  if { $cargs(-nt) } {
  puts $fout "write_ntpocv_tcl -input \$cell_input -output \$cell_output -cell \"\$cell\"  -array_name cellarray -ref_spice_lib $cargs(-ref_spice_lib)  -spice_file \$cell.o-\$output.i-\$input.s-\$\{scnt\}.NT -tcl \$cell.o-\$output.i-\$input.s-\$\{scnt\} $wnt"
  }
  if { [regexp "custom" $cargs(-cell_chain_mode)]} {
  } elseif { [regexp "drive" $cargs(-cell_chain_mode)]} {
  puts $fout "write_pocv_spice_deck -cell \"\$cell \$drivecell\" -array_name cellarray -ref_spice_lib \"$cargs(-ref_spice_lib)\" -input \$cell_input -output \$cell_output -sensitization_data \"\$sensitize\" -spice_output \$cell.o-\$output.i-\$input.s-\$scnt.ref $was"
  } elseif { [regexp "same" $cargs(-cell_chain_mode)]} {
  puts $fout "write_pocv_spice_deck -cell \$cell -array_name cellarray -ref_spice_lib \"$cargs(-ref_spice_lib)\" -input \$cell_input -output \$cell_output -sensitization_data \"\$sensitize\" -spice_output \$cell.o-\$output.i-\$input.s-\$scnt.ref $was"
  } elseif { [rexpr "alter" $cargs(-cell_chain_mode)]} {
  puts $fout "write_pocv_spice_deck -cell \"\$cell \$drivecell\" -array_name cellarray -ref_spice_lib \"$cargs(-ref_spice_lib)\" -input \$cell_input -output \$cell_output -sensitization_data \"\$sensitize\" -spice_output \$cell.o-\$output.i-\$input.s-\$scnt.ref $was"
  }
  }
  if { $cargs(-spice_model) ne "" } {
  # write_pocv_spice -spice_model ...
  if { $cargs(-nt) } {
  puts $fout "write_ntpocv_tcl -input \$cell_input -output \$cell_output -cell \"\$cell\"  -array_name cellarray -spice_model $cargs(-spice_model)  -spice_file \$cell.o-\$output.i-\$input.s-\$\{scnt\}.NT -tcl \$cell.o-\$output.i-\$input.s-\$\{scnt\} $wnt"
  }
  if { [regexp "custom" $cargs(-cell_chain_mode)]} {
  } elseif { [regexp "drive" $cargs(-cell_chain_mode)]} {
  puts $fout "write_pocv_spice_deck -cell \"\$cell \$drivecell\" -array_name cellarray -spice_model $cargs(-spice_model) -input \$cell_input -output \$cell_output -sensitization_data \"\$sensitize\" -spice_output \$cell.o-\$output.i-\$input.s-\$scnt $was"
  } elseif { [regexp "same" $cargs(-cell_chain_mode)]} {
  puts $fout "write_pocv_spice_deck -cell \$cell -array_name cellarray -spice_model $cargs(-spice_model) -input \$cell_input -output \$cell_output -sensitization_data \"\$sensitize\" -spice_output \$cell.o-\$output.i-\$input.s-\$scnt $was"
  } elseif { [regexp "alter" $cargs(-cell_chain_mode)]} {
  puts $fout "write_pocv_spice_deck -cell \"\$cell \$drivecell\" -array_name cellarray -spice_model $cargs(-spice_model) -input \$cell_input -output \$cell_output -sensitization_data \"\$sensitize\" -spice_output \$cell.o-\$output.i-\$input.s-\$scnt $was"
  }
  } elseif { $cargs(-spice_lib) ne "" } {
  # write_pocv_spice -spice_lib ...
  if { $cargs(-nt) } {
  puts $fout "write_ntpocv_tcl -input \$cell_input -output \$cell_output -cell \"\$cell\"  -array_name cellarray -spice_lib \"$cargs(-spice_lib)\"  -spice_file \$cell.o-\$output.i-\$input.s-\$\{scnt\}.NT -tcl \$cell.o-\$output.i-\$input.s-\$\{scnt\} $wnt"
  }
  if { [regexp "custom" $cargs(-cell_chain_mode)]} {
  } elseif {[regexp "drive" $cargs(-cell_chain_mode)]} {
  puts $fout "write_pocv_spice_deck -cell \"\$cell \$drivecell\" -array_name cellarray -spice_lib \"$cargs(-spice_lib)\" -input \$cell_input -output \$cell_output -sensitization_data \"\$sensitize\" -spice_output \$cell.o-\$output.i-\$input.s-\$scnt $was"
  } elseif { [regexp "same" $cargs(-cell_chain_mode)]} {
  puts $fout "write_pocv_spice_deck -cell \$cell -array_name cellarray -spice_model $cargs(-spice_lib) -input \$cell_input -output \$cell_output -sensitization_data \"\$sensitize\" -spice_output \$cell.o-\$output.i-\$input.s-\$scnt $was"
  } elseif { [regexp "alter" $cargs(-cell_chain_mode)]} {
  puts $fout "write_pocv_spice_deck -cell \"\$cell \$drivecell\" -array_name cellarray -spice_lib \"$cargs(-spice_lib)\" -input \$cell_input -output \$cell_output -sensitization_data \"\$sensitize\" -spice_output \$cell.o-\$output.i-\$input.s-\$scnt $was"
  }
  }
  
  # create the runscripts for reading and generating pin specific AOCV tables and then merging them
  # read the measurement data
  puts $fout "   incr scnt"
  # end of if
  puts $fout "   if \{ !\$all_sensitizations \} \{"
  puts $fout "    break"
  puts $fout "   \}"
  puts $fout "   \}"
  # end of foreach sensitize
  puts $fout "\}"
  puts $fout "if \{ \$scnt == 0 \} \{"
  puts $fout "  puts \"Error: unable to match any sensitization vectors for cell: \$cell  input: \$input output: \$output\""
  puts $fout "  return 0;"
  puts $fout "\}"
  } elseif { ($cargs(-db) ne "") || ($cargs(-library) ne "") } {
  if { $cargs(-all_sensitizations) } {
  puts $fout "set all_sensitizations 1"
  } else {
  puts $fout "set all_sensitizations 0"
  }
  puts $fout "if \{ \[array exists cellarray\] && \[info exists cellarray(cell,\$cell,pin,\$output,sensitization,\$input,edge,r)\] \} \{"
  puts $fout "   set sensitization_data \$cellarray(cell,\$cell,pin,\$output,sensitization,\$input,edge,r)"
  puts $fout "   foreach sensitize \$sensitization_data \{"
  if { $cargs(-ref_spice_model) ne "" } {
  # write_pocv_spice -ref_spice_model ...
  if { $cargs(-nt) } {
  puts $fout "write_ntpocv_tcl -input \$cell_input -output \$cell_output -cell \"\$cell\"  -array_name cellarray -ref_spice_model \"$cargs(-ref_spice_model)\"  -spice_file \$cell.o-\$output.i-\$input.s-\$\{scnt\}.NT -tcl \$cell.o-\$output.i-\$input.s-\$\{scnt\} $wnt"
  }
  if { [regexp "custom" $cargs(-cell_chain_mode)]} {
  } elseif { [regexp "drive" $cargs(-cell_chain_mode)]} {
  puts $fout "      write_pocv_spice_deck -cell \"\$cell \$drivecell\" -array_name cellarray -ref_spice_model $cargs(-ref_spice_model) -input \$cell_input -output \$cell_output -sensitization_data \"\$cell:\$sensitize\" -spice_output \$cell.o-\$output.i-\$input.s-\$scnt.ref $was"
  } elseif { [regexp "same" $cargs(-cell_chain_mode)]} {
  puts $fout "      write_pocv_spice_deck -cell \$cell -array_name cellarray -ref_spice_model $cargs(-ref_spice_model) -input \$cell_input -output \$cell_output -sensitization_data \"\$cell:\$sensitize\" -spice_output \$cell.o-\$output.i-\$input.s-\$scnt.ref $was"
  } elseif { [regexp "alter" $cargs(-cell_chain_mode)]} {
  puts $fout "      write_pocv_spice_deck -cell \"\$cell \$drivecell\" -array_name cellarray -ref_spice_model $cargs(-ref_spice_model) -input \$cell_input -output \$cell_output -sensitization_data \"\$cell:\$sensitize\" -spice_output \$cell.o-\$output.i-\$input.s-\$scnt.ref $was"
  }
  } elseif { $cargs(-ref_spice_lib) ne "" } {
  if { $cargs(-nt) } {
  puts $fout "write_ntpocv_tcl -input \$cell_input -output \$cell_output -cell \"\$cell\"  -array_name cellarray -ref_spice_lib \"$cargs(-ref_spice_lib)\"  -spice_file \$cell.o-\$output.i-\$input.s-\$\{scnt\}.NT -tcl \$cell.o-\$output.i-\$input.s-\$\{scnt\} $wnt"
  }
  # write_pocv_spice -ref_spice_lib ...
  if { [regexp "custom" $cargs(-cell_chain_mode)]} {
  } elseif { [regexp "drive" $cargs(-cell_chain_mode)]} {
  puts $fout "      write_pocv_spice_deck -cell \"\$cell \$drivecell\" -array_name cellarray -ref_spice_lib $cargs(-ref_spice_lib) -input \$cell_input -output \$cell_output -sensitization_data \"\$cell:\$sensitize\" -spice_output \$cell.o-\$output.i-\$input.s-\$scnt.ref $was"
  } elseif { [regexp "same" $cargs(-cell_chain_mode)]} {
  puts $fout "      write_pocv_spice_deck -cell \$cell -array_name cellarray -ref_spice_lib $cargs(-ref_spice_lib) -input \$cell_input -output \$cell_output -sensitization_data \"\$cell:\$sensitize\" -spice_output \$cell.o-\$output.i-\$input.s-\$scnt.ref $was"
  } elseif { [regexp "alter" $cargs(-cell_chain_mode)]} {
  puts $fout "      write_pocv_spice_deck -cell \"\$cell \$drivecell\" -array_name cellarray -ref_spice_lib $cargs(-ref_spice_lib) -input \$cell_input -output \$cell_output -sensitization_data \"\$cell:\$sensitize\" -spice_output \$cell.o-\$output.i-\$input.s-\$scnt.ref $was"
  }
  }
  if { $cargs(-spice_model) ne "" } {
  # write_pocv_spice -spice_model ...
  if { $cargs(-nt) } {
  puts $fout "write_ntpocv_tcl -input \$cell_input -output \$cell_output -cell \"\$cell\"  -array_name cellarray -spice_model \"$cargs(-spice_model)\"  -spice_file \$cell.o-\$output.i-\$input.s-\$\{scnt\}.NT -tcl \$cell.o-\$output.i-\$input.s-\$\{scnt\} $wnt"
  }
  if { [regexp "custom" $cargs(-cell_chain_mode)]} {
  } elseif { [regexp "drive" $cargs(-cell_chain_mode)]} {
  puts $fout "      write_pocv_spice_deck -cell \"\$cell \$drivecell\" -array_name cellarray -spice_model $cargs(-spice_model) -input \$cell_input -output \$cell_output -sensitization_data \"\$cell:\$sensitize\" -spice_output \$cell.o-\$output.i-\$input.s-\$scnt $was"
  } elseif { [regexp "same" $cargs(-cell_chain_mode)]} {
  puts $fout "      write_pocv_spice_deck -cell \$cell -array_name cellarray -spice_model $cargs(-spice_model) -input \$cell_input -output \$cell_output -sensitization_data \"\$cell:\$sensitize\" -spice_output \$cell.o-\$output.i-\$input.s-\$scnt $was"
  } elseif { [regexp "alter" $cargs(-cell_chain_mode)]} {
  puts $fout "      write_pocv_spice_deck -cell \"\$cell \$drivecell\" -array_name cellarray -spice_model $cargs(-spice_model) -input \$cell_input -output \$cell_output -sensitization_data \"\$cell:\$sensitize\" -spice_output \$cell.o-\$output.i-\$input.s-\$scnt $was"
  }
  } elseif { $cargs(-spice_lib) ne "" } {
  # write_pocv_spice -spice_lib ...
  if { $cargs(-nt) } {
  puts $fout "write_ntpocv_tcl -input \$cell_input -output \$cell_output -cell \"\$cell\"  -array_name cellarray -spice_lib \"$cargs(-spice_lib)\"  -spice_file \$cell.o-\$output.i-\$input.s-\$\{scnt\}.NT -tcl \$cell.o-\$output.i-\$input.s-\$\{scnt\} $wnt"
  }
  if { [regexp "custom" $cargs(-cell_chain_mode)]} {
  } elseif { [regexp "drive" $cargs(-cell_chain_mode)]} {
  puts $fout "      write_pocv_spice_deck -cell \"\$cell \$drivecell\" -array_name cellarray -spice_lib \"$cargs(-spice_lib)\" -input \$cell_input -output \$cell_output -sensitization_data \"\$cell:\$sensitize\" -spice_output \$cell.o-\$output.i-\$input.s-\$scnt $was"
  } elseif { [regexp "same" $cargs(-cell_chain_mode)]} {
  puts $fout "      write_pocv_spice_deck -cell \$cell -array_name cellarray -spice_lib \"$cargs(-spice_lib)\" -input \$cell_input -output \$cell_output -sensitization_data \"\$cell:\$sensitize\" -spice_output \$cell.o-\$output.i-\$input.s-\$scnt $was"
  } elseif { [regexp "alter" $cargs(-cell_chain_mode)]} {
  puts $fout "      write_pocv_spice_deck -cell \"\$cell \$drivecell\" -array_name cellarray -spice_lib \"$cargs(-spice_lib)\" -input \$cell_input -output \$cell_output -sensitization_data \"\$cell:\$sensitize\" -spice_output \$cell.o-\$output.i-\$input.s-\$scnt $was"
  }
  }
  puts $fout "      incr scnt"
  puts $fout "      if \{ !\$all_sensitizations \} \{"
  puts $fout "       break"
  puts $fout "      \}"
  puts $fout "   \}"
  puts $fout "if \{ \$scnt == 0 \} \{"
  puts $fout "  puts \"Error: unable to match any sensitization vectors for cell: \$cell  input: \$input output: \$output\""
  puts $fout "  return 0;"
  puts $fout "\}"
  puts $fout "   # foreach sensitize"
  puts $fout "\} else \{"
  if { $cargs(-ref_spice_model) ne "" } {
  # add MIS to flow
  # write_pocv_spice -ref_spice_model ...
  if { $cargs(-nt) } {
  puts $fout "write_ntpocv_tcl -input \$cell_input -output \$cell_output -cell \"\$cell\"  -array_name cellarray -ref_spice_model \"$cargs(-ref_spice_model)\"  -spice_file \$cell.o-\$output.i-\$input.s-\$\{scnt\}.NT -tcl \$cell.o-\$output.i-\$input.s-\$\{scnt\} $wnt"
  }
  if { [regexp "custom" $cargs(-cell_chain_mode)]} {
  } elseif { [regexp "drive" $cargs(-cell_chain_mode)]} {
  puts $fout "   write_pocv_spice_deck -cell \"\$cell \$drivecell\" -array_name cellarray -ref_spice_model $cargs(-ref_spice_model) -input \$cell_input -output \$cell_output -spice_output \$cell.o-\$output.i-\$input.s-\$scnt.ref $was"
  } elseif { [regexp "same" $cargs(-cell_chain_mode)]} {
  puts $fout "   write_pocv_spice_deck -cell \$cell -array_name cellarray -ref_spice_model $cargs(-ref_spice_model) -input \$cell_input -output \$cell_output -spice_output \$cell.o-\$output.i-\$input.s-\$scnt.ref $was"
  } elseif { [regexp "alter" $cargs(-cell_chain_mode)]} {
  puts $fout "   write_pocv_spice_deck -cell \"\$cell \$drivecell\" -array_name cellarray -ref_spice_model $cargs(-ref_spice_model) -input \$cell_input -output \$cell_output -spice_output \$cell.o-\$output.i-\$input.s-\$scnt.ref $was"
  }
  } elseif { $cargs(-ref_spice_lib) ne "" } {
  # write_pocv_spice -ref_spice_lib ...
  if { $cargs(-nt) } {
  puts $fout "write_ntpocv_tcl -input \$cell_input -output \$cell_output -cell \"\$cell\"  -array_name cellarray -ref_spice_lib \"$cargs(-ref_spice_lib)\"  -spice_file \$cell.o-\$output.i-\$input.s-\$\{scnt\}.NT -tcl \$cell.o-\$output.i-\$input.s-\$\{scnt\} $wnt"
  }
  if { [regexp "custom" $cargs(-cell_chain_mode)]} {
  } elseif { [regexp "drive" $cargs(-cell_chain_mode)]} {
  puts $fout "   write_pocv_spice_deck -cell \"\$cell \$drivecell\" -array_name cellarray -ref_spice_lib \"$cargs(-ref_spice_lib)\" -input \$cell_input -output \$cell_output -spice_output \$cell.o-\$output.i-\$input.s-\$scnt.ref $was"
  } elseif { [regexp "same" $cargs(-cell_chain_mode)]} {
  puts $fout "   write_pocv_spice_deck -cell \$cell -array_name cellarray -ref_spice_lib \"$cargs(-ref_spice_lib)\" -input \$cell_input -output \$cell_output -spice_output \$cell.o-\$output.i-\$input.s-\$scnt.ref $was"
  } elseif { [regexp "alter" $cargs(-cell_chain_mode)]} {
  puts $fout "   write_pocv_spice_deck -cell \"\$cell \$drivecell\" -array_name cellarray -ref_spice_lib \"$cargs(-ref_spice_lib)\" -input \$cell_input -output \$cell_output -spice_output \$cell.o-\$output.i-\$input.s-\$scnt.ref $was"
  }
  }
  if { $cargs(-spice_model) ne "" } {
  # write_pocv_spice -spice_model ...
  if { $cargs(-nt) } {
  puts $fout "write_ntpocv_tcl -input \$cell_input -output \$cell_output -cell \"\$cell\"  -array_name cellarray -spice_model \"$cargs(-spice_model)\"  -spice_file \$cell.o-\$output.i-\$input.s-\$\{scnt\}.NT -tcl \$cell.o-\$output.i-\$input.s-\$\{scnt\} $wnt"
  }
  if { [regexp "custom" $cargs(-cell_chain_mode)]} {
  } elseif { [regexp "drive" $cargs(-cell_chain_mode)]} {
  puts $fout "      write_pocv_spice_deck -cell \"\$cell \$drivecell\" -array_name cellarray -spice_model $cargs(-spice_model) -input \$cell_input -output \$cell_output -spice_output \$cell.o-\$output.i-\$input.s-\$scnt $was"
  } elseif { [regexp "same" $cargs(-cell_chain_mode)]} {
  puts $fout "      write_pocv_spice_deck -cell \$cell -array_name cellarray -spice_model $cargs(-spice_model) -input \$cell_input -output \$cell_output -spice_output \$cell.o-\$output.i-\$input.s-\$scnt $was"
  } elseif { [regexp "alter" $cargs(-cell_chain_mode)]} {
  puts $fout "      write_pocv_spice_deck -cell \"\$cell \$drivecell\" -array_name cellarray -spice_model $cargs(-spice_model) -input \$cell_input -output \$cell_output -spice_output \$cell.o-\$output.i-\$input.s-\$scnt $was"
  }
  } elseif { $cargs(-spice_lib) ne "" } {
  # write_pocv_spice -spice_lib ...
  if { $cargs(-nt) } {
  puts $fout "write_ntpocv_tcl -input \$cell_input -output \$cell_output -cell \"\$cell\"  -array_name cellarray -spice_lib \"$cargs(-spice_lib)\"  -spice_file \$cell.o-\$output.i-\$input.s-\$\{scnt\}.NT -tcl \$cell.o-\$output.i-\$input.s-\$\{scnt\} $wnt"
  }
  if { [regexp "custom" $cargs(-cell_chain_mode)]} {
  } elseif { [regexp "drive" $cargs(-cell_chain_mode)]} {
  puts $fout "      write_pocv_spice_deck -cell \"\$cell \$drivecell\" -array_name cellarray -spice_lib \"$cargs(-spice_lib)\" -input \$cell_input -output \$cell_output -spice_output \$cell.o-\$output.i-\$input.s-\$scnt $was"
  } elseif { [regexp "same" $cargs(-cell_chain_mode)]} {
  puts $fout "      write_pocv_spice_deck -cell \$cell -array_name cellarray -spice_lib \"$cargs(-spice_lib)\" -input \$cell_input -output \$cell_output -spice_output \$cell.o-\$output.i-\$input.s-\$scnt $was"
  } elseif { [reexp "alter" $cargs(-cell_chain_mode)]} {
  puts $fout "      write_pocv_spice_deck -cell \"\$cell \$drivecell\" -array_name cellarray -spice_lib \"$cargs(-spice_lib)\" -input \$cell_input -output \$cell_output -spice_output \$cell.o-\$output.i-\$input.s-\$scnt $was"
  }
  }
  puts $fout "\}"
  puts $fout "# end of else for cellarray sensitization"
  } else {
  if { $cargs(-ref_spice_model) ne "" } {
  # write_pocv_spice -ref_spice_model ...
  if { $cargs(-nt) } {
  puts $fout "write_ntpocv_tcl -input \$cell_input -output \$cell_output -cell \"\$cell\"  -array_name cellarray -ref_spice_model \"$cargs(-ref_spice_model)\"  -spice_file \$cell.o-\$output.i-\$input.s-\$\{scnt\}.NT -tcl \$cell.o-\$output.i-\$input.s-\$\{scnt\} $wnt"
  }
  if { [regexp "custom" $cargs(-cell_chain_mode)]} {
  } elseif { [reexp "drive" $cargs(-cell_chain_mode)]} {
  puts $fout "write_pocv_spice_deck -cell \"\$cell \$drivecell\" -array_name cellarray -ref_spice_model $cargs(-ref_spice_model) -input \$cell_input -output \$cell_output -spice_output \$cell.o-\$output.i-\$input.s-\$scnt.ref $was"
  } elseif { [regexp "same" $cargs(-cell_chain_mode)]} {
  puts $fout "write_pocv_spice_deck -cell \$cell -array_name cellarray -ref_spice_model $cargs(-ref_spice_model) -input \$cell_input -output \$cell_output -spice_output \$cell.o-\$output.i-\$input.s-\$scnt.ref $was"
  } elseif { [regexp "alter" $cargs(-cell_chain_mode)]} {
  puts $fout "write_pocv_spice_deck -cell \"\$cell \$drivecell\" -array_name cellarray -ref_spice_model $cargs(-ref_spice_model) -input \$cell_input -output \$cell_output -spice_output \$cell.o-\$output.i-\$input.s-\$scnt.ref $was"
  }
  } elseif { $cargs(-ref_spice_lib) ne "" } {
  # write_pocv_spice -ref_spice_lib ...
  if { $cargs(-nt) } {
  puts $fout "write_ntpocv_tcl -input \$cell_input -output \$cell_output -cell \"\$cell\"  -array_name cellarray -ref_spice_lib \"$cargs(-ref_spice_lib)\"  -spice_file \$cell.o-\$output.i-\$input.s-\$\{scnt\}.NT -tcl \$cell.o-\$output.i-\$input.s-\$\{scnt\} $wnt"
  }
  if { [regexp "custom" $cargs(-cell_chain_mode)]} {
  } elseif { [regexp "drive" $cargs(-cell_chain_mode)]} {
  puts $fout "write_pocv_spice_deck -cell \"\$cell \$drivecell\" -array_name cellarray -ref_spice_lib \"$cargs(-ref_spice_lib)\" -input \$cell_input -output \$cell_output -spice_output \$cell.o-\$output.i-\$input.s-\$scnt.ref $was"
  } elseif { [regexp "same" $cargs(-cell_chain_mode)]} {
  puts $fout "write_pocv_spice_deck -cell \$cell -array_name cellarray -ref_spice_lib \"$cargs(-ref_spice_lib)\" -input \$cell_input -output \$cell_output -spice_output \$cell.o-\$output.i-\$input.s-\$scnt.ref $was"
  } elseif { [regexp "alter" $cargs(-cell_chain_mode)]} {
  puts $fout "write_pocv_spice_deck -cell \"\$cell \$drivecell\" -array_name cellarray -ref_spice_lib \"$cargs(-ref_spice_lib)\" -input \$cell_input -output \$cell_output -spice_output \$cell.o-\$output.i-\$input.s-\$scnt.ref $was"
  }
  }
  if { $cargs(-spice_model) ne "" } {
  # write_pocv_spice -spice_model ...
  if { $cargs(-nt) } {
  puts $fout "write_ntpocv_tcl -input \$cell_input -output \$cell_output -cell \"\$cell\"  -array_name cellarray -spice_model \"$cargs(-spice_model)\"  -spice_file \$cell.o-\$output.i-\$input.s-\$\{scnt\}.NT -tcl \$cell.o-\$output.i-\$input.s-\$\{scnt\} $wnt"
  }
  if { [regexp "custom" $cargs(-cell_chain_mode)]} {
  } elseif { [regexp "drive" $cargs(-cell_chain_mode)]} {
  puts $fout "write_pocv_spice_deck -cell \"\$cell \$drivecell\" -array_name cellarray -spice_model $cargs(-spice_model) -input \$cell_input -output \$cell_output -spice_output \$cell.o-\$output.i-\$input.s-\$scnt $was"
  } elseif { [regexp "same" $cargs(-cell_chain_mode)]} {
  puts $fout "write_pocv_spice_deck -cell \$cell -array_name cellarray -spice_model $cargs(-spice_model) -input \$cell_input -output \$cell_output -spice_output \$cell.o-\$output.i-\$input.s-\$scnt $was"
  } elseif { [regexp "alter" $cargs(-cell_chain_mode)]} {
  puts $fout "write_pocv_spice_deck -cell \"\$cell \$drivecell\" -array_name cellarray -spice_model $cargs(-spice_model) -input \$cell_input -output \$cell_output -spice_output \$cell.o-\$output.i-\$input.s-\$scnt $was"
  }
  } elseif { $cargs(-spice_lib) ne "" } {
  # write_pocv_spice -spice_lib ...
  if { $cargs(-nt) } {
  puts $fout "write_ntpocv_tcl -input \$cell_input -output \$cell_output -cell \"\$cell\" -array_name cellarray -spice_lib \"$cargs(-spice_lib)\"  -spice_file \$cell.o-\$output.i-\$input.s-\$\{scnt\}.NT -tcl \$cell.o-\$output.i-\$input.s-\$\{scnt\} $wnt"
  }
  if { [regexp "custom" $cargs(-cell_chain_mode)]} {
  } elseif {[regexp "drive"  $cargs(-cell_chain_mode)]} {
  puts $fout "write_pocv_spice_deck -cell \"\$cell \$drivecell\" -array_name cellarray -spice_lib \"$cargs(-spice_lib)\" -input \$cell_input -output \$cell_output -spice_output \$cell.o-\$output.i-\$input.s-\$scnt $was"
  } elseif { [regexp "same" $cargs(-cell_chain_mode)]} {
  puts $fout "write_pocv_spice_deck -cell \$cell -array_name cellarray -spice_lib \"$cargs(-spice_lib)\" -input \$cell_input -output \$cell_output -spice_output \$cell.o-\$output.i-\$input.s-\$scnt $was"
  } elseif { [regexp "alter" $cargs(-cell_chain_mode)]} {
  puts $fout "write_pocv_spice_deck -cell \"\$cell \$drivecell\" -array_name cellarray -spice_lib \"$cargs(-spice_lib)\" -input \$cell_input -output \$cell_output -spice_output \$cell.o-\$output.i-\$input.s-\$scnt $was"
  }
  }
  
  # create the runscripts for reading and generating pin specific AOCV tables and then merging them
  # read the measurement data
  }
  # end of foreach input
  if { [regexp "same" $cargs(-cell_chain_mode)] } {
  puts $fout "\}"
  puts $fout "# foreach input"
  }
  # end of foreach output
  if { [regexp "same" $cargs(-cell_chain_mode)] } {
  puts $fout "\}"
  puts $fout " # foreach output"
  }

  if { $cargs(-nt) } { 
  puts $fout "puts \"Creating runscript($cargs(-nt_runscript)) for running NT POCV\""
  if { $cargs(-nt_runscript) eq "" } {
  puts $fout "write_nt_runscript -cell \$cell -runscript run_ntpocv_\$cell $nrs"
  puts $fout "exec chmod 777 run_ntpocv_\$cell"
  } else {
  puts $fout "write_nt_runscript -cell \$cell -runscript $cargs(-nt_runscript) $nrs"
  puts $fout "exec chmod 777 $cargs(-nt_runscript)"
  }
  }

  # write the runscript for running hspice
  if { $cargs(-hsp_runscript) eq "" } {
  puts $fout "puts \"Creating runscript($cargs(-hsp_runscript)) for running HSPICE analysis\""
  puts $fout "write_hsp_runscript -cell \$cell -runscript run_hsp_aocv_\$cell $hrs"
  puts $fout "exec chmod 777 run_hsp_aocv_\$cell"
  } else {
  puts $fout "write_hsp_runscript -cell \$cell -runscript $cargs(-hsp_runscript) $hrs"
  puts $fout "exec chmod 777 $cargs(-hsp_runscript)"
  }

  # end of cell
  puts $fout "\}"
  puts $fout " # end of cell"
  # end of cellname
  puts $fout "\}"
  puts $fout "# end of cellname"
  close $fout
  exec chmod 777 $cargs(-setup_runscript)

  if { ($cargs(-table_runscript) ne "") && !$cargs(-nt)} {
  puts "Creating runscript($cargs(-table_runscript)) for generating POCV/AOCV tables from Measure data"
  # write the runscript for reading measure files & generating aocv tables
  set  fout [open $cargs(-table_runscript) w]
  puts $fout "#!/bin/sh"
  puts $fout "# the next line restarts using tclsh \\"
  puts $fout "exec tclsh \"\$0\" \"\$\@\""

  puts $fout "set __script_dir $cargs(-scripts_dir)"
  puts $fout "global __script_dir"
  puts $fout "set __meas_dir $cargs(-meas_dir)"
  puts $fout "global __meas_dir"
  puts $fout "set __pocv_dir $cargs(-pocv_dir)"
  puts $fout "global __pocv_dir"


   puts $fout "set __date \[clock format \[clock seconds\] -format \{\%a \%b \%d \%H:\%M:\%S \%Z \%Y\}\]"
   puts $fout "global __date"

   puts $fout "if \{ \[file exists \$__script_dir/Simple_pocv_generation.tcl\] \} \{"
   puts $fout "  source \$__script_dir/Simple_pocv_generation.tcl"
   puts $fout "\} else \{"
   puts $fout "  puts \"ERROR: Simple_pocv_generation.tcl not found(Please place all POCV script files in same directory)\""
   puts $fout "  exit"
   puts $fout "\}"
   puts $fout "if \{ \[file exists \$__script_dir/general_pocv.tcl\] \} \{"
   puts $fout "   source \$__script_dir/general_pocv.tcl"
   puts $fout "\} else \{"
   puts $fout "   puts \"ERROR: general_pocv.tcl not found(Please place all POCV script files in same directory)\""
   puts $fout "   exit"
   puts $fout "\}"
   puts $fout "if \{ \[file exists \$__script_dir/read_db_data.tcl\] \} \{"
   puts $fout "   source \$__script_dir/read_db_data.tcl"
   puts $fout "\} elseif \{ \[file exists \$__script_dir/read_db_data.tbc\] \} \{"
   puts $fout "   append auto_path \" \$__script_dir/tbcload\""
   puts $fout "   package require tbcload 1.4"
   puts $fout "   source \$__script_dir/read_db_data.tbc"
   puts $fout "\} else \{"
   puts $fout "   puts \"ERROR: read_db_data.tbc not found(Please place all POCV script files in same directory)\""
   puts $fout "   exit"
   puts $fout "\}"
   
   # if DB/.lib is given then use the byte code to grab some attributes
   if { ($cargs(-db) ne "") } {
    ## check if DB defined -nocase
    puts $fout "if \{(\[info procs ::read_db_cell_data\] ne \"\")\} \{"
    puts $fout "::read_db_cell_data -array_name cellarray -db \"$cargs(-db)\" -tmplt_dir \$__meas_dir -scripts_dir \$__script_dir -cell \"$cargs(-cell)\""
    puts $fout "\}"
   } elseif { ($cargs(-library) ne "")} {
    puts $fout "if \{(\[info procs ::read_db_cell_data\] ne \"\")\} \{"
    puts $fout "::read_db_cell_data -array_name cellarray -library \"$cargs(-library)\" -tmplt_dir \$__meas_dir -scripts_dir \$__script_dir -cell \"$cargs(-cell)\""
    puts $fout "\}" 
  }

  puts $fout "foreach cellname \[split \"$cargs(-cell)\"\] \{"
  puts $fout "  set cellname \[string trim \$cellname\]"
  puts $fout "  if \{ \[array exists cellarray\] && (\[llength \[keys cellarray(cell)\] \] \> 0 )\} \{"
  puts $fout "    set cells \[keys cellarray(cell)\]"
  puts $fout "  \} else \{"
  puts $fout "    set cells \$cellname"
  puts $fout "  \}"
  puts $fout "  foreach cell \[lsearch \-all \-inline \$cells \$cellname\] \{"
  puts $fout "    puts \"Processing Cell: \$cell\""
  if { ($cargs(-output) eq "") } {
     if { (($cargs(-db) ne "" ) || ($cargs(-library) ne "" )) } {
        if { $cargs(-all_outputs) } {
  puts $fout "    if \{ \[array exists cellarray\] && \[info exists cellarray(cell,\$cell,output_list)\] \} \{"
  puts $fout "    set outputs \$cellarray(cell,\$cell,output_list)"
  puts $fout "    \} elseif \{ \[array exists cellarray\] && \[info exists cellarray(cell,\$cell,output)\] \} \{"
  puts $fout "    set outputs \$cellarray(cell,\$cell,output)"
  puts $fout "    \} else \{"
  puts $fout "    puts \"Error: no output pin given or found, use -output option to specify\""
  puts $fout "    return 0"
  puts $fout "    \}"
	} else {
  puts $fout "    if \{ \[array exists cellarray\] && \[info exists cellarray(cell,\$cell,output)\] \} \{"
  puts $fout "    set outputs \$cellarray(cell,\$cell,output)"
  puts $fout "    \} else \{"
  puts $fout "    puts \"Error: no output pin given or found, use -output option to specify\""
  puts $fout "    return 0"
  puts $fout "    \}"
	}
     } else {
	puts "Error: no output pin given or found, use -output or -db/-library option to specify"
	return 0
     }
  } else {
        puts $fout "    set outputs \"$cargs(-output)\""
        puts $fout "    set tmp_outputs \"\""
	puts $fout "    while \{ \[ regexp \"\$cell\\\[ \\t\\\]*\\\:\\\[ \\t\\\]*\(\\\[^ \\t\\\}\\\{\\\]+\)\" \$outputs dum opt1\] \} \{"
	puts $fout "    regsub \"\$cell\\\[ \\t\\\]*\\\:\\\[ \\t\\\]*\(\\\[^ \\t\\\}\\\{\\\]+\)\" \$outputs \{\} outputs"
	puts $fout "    set tmp_outputs \$opt1"
	puts $fout "    \}"
	puts $fout "    if \{ \$tmp_outputs ne \"\" \} \{"
	puts $fout "    set outputs \$tmp_outputs"
	puts $fout "    \}"
  }
  if { ($cargs(-input) eq "") } {
     if { (($cargs(-db) ne "" ) || ($cargs(-library) ne "" )) } {
	if { $cargs(-all_inputs) } {
  puts $fout "    if \{ \[array exists cellarray\] && \[info exists cellarray(cell,\$cell,input_list)\] \} \{"
  puts $fout "    set inputs \$cellarray(cell,\$cell,input_list)"
  puts $fout "    \} elseif \{ \[array exists cellarray\] && \[info exists cellarray(cell,\$cell,input)\] \} \{"
  puts $fout "    set inputs \$cellarray(cell,\$cell,input)"
  puts $fout "    \} else \{"
  puts $fout "    puts \"Error: no input pin given or found, use -input option to specify\""
  puts $fout "    return 0"
  puts $fout "    \}"
	} else {
  puts $fout "    if \{ \[array exists cellarray\] && \[info exists cellarray(cell,\$cell,input)\] \} \{"
  puts $fout "    set inputs \$cellarray(cell,\$cell,input)"
  puts $fout "    \} else \{"
  puts $fout "    puts \"Error: no input pin given or found, use -input option to specify\""
  puts $fout "    return 0"
  puts $fout "    \}"
	}
     } else {
	puts "Error: no output pin given or found, use -input or -db/-library option to specify"
        return 0
     }
  } else {
        puts $fout "    set inputs \"$cargs(-input)\""
        puts $fout "    set tmp_inputs \"\""
	puts $fout "    while \{ \[ regexp \"\$cell\\\[ \\t\\\]*\\\:\\\[ \\t\\\]*\(\\\[^ \\t\\\}\\\{\\\]+\)\" \$inputs dum opt1\] \} \{"
	puts $fout "    regsub \"\$cell\\\[ \\t\\\]*\\\:\\\[ \\t\\\]*\(\\\[^ \\t\\\}\\\{\\\]+\)\" \$inputs \{\} inputs"
	puts $fout "    set tmp_inputs \$opt1"
	puts $fout "    \}"
	puts $fout "    if \{ \$tmp_inputs ne \"\" \} \{"
	puts $fout "    set inputs \$tmp_inputs"
	puts $fout "    \}"
  }
  puts $fout "    set outputs \[regsub -all \"\\\[ \\t\\\]+\" \[string trim \[join \$outputs\]\] \{ \}\]"
  puts $fout "    set inputs \[regsub -all \"\\\[ \\t\\\]+\" \[string trim \[join \$inputs\]\] \{ \}\]"
  puts $fout "    foreach output \[split \"\$outputs\"\] \{"
  puts $fout "       foreach input \[split \"\$inputs\"\] \{"
  if { $cargs(-all_sensitizations) } {
  puts $fout "         set all_sensitizations 1"
  } else {
  puts $fout "         set all_sensitizations 0"
  }
  puts $fout "         set scnt 0"
  if { ($cargs(-sensitization_data) ne "\{\}") && !(([llength $cargs(-sensitization_data)] == 1) && ([lindex $cargs(-sensitization_data) 0 ] ne  "\{\}")) } {
  puts $fout "         foreach sensitize \[list $cargs(-sensitization_data)\] \{"
  puts $fout "            set file \[lindex \[glob -nocomplain \$\{__meas_dir\}/\$cell*.o-\$output.i-\$input.s-\$scnt.*mt0*\] 0\]"
  puts $fout "            if \{(\$file eq \"\")\} \{"
  puts $fout "                puts \"Error: \$\{__meas_dir\}\$cell*.o-\$output.i-\$input.s-\$scnt.*mt0* not found\""
  puts $fout "                break"
  puts $fout "            \} elseif \{!\[file exists \"\$\{__pocv_dir\}/\$\{cell\}.o-\$output.i-\$input.s-\$scnt.POCV\"] || (\[file mtime \$file\] >  \[file mtime \"\$\{__pocv_dir\}/\${cell}.o-\$output.i-\$input.s-\$scnt.POCV\"\]) \} \{"
  puts $fout "            if \{ \[array size sigdata\] \} \{"
  puts $fout "               array unset sigdata"
  puts $fout "            \}"
  puts $fout "            read_measure_data_to_array -dataarray sigdata -meas \$\{__meas_dir\}/\$cell*.o-\$output.i-\$input.s-\$scnt.m-*.mt0* $rmd"
  if { ($cargs(-ref_spice_model) ne "") || ($cargs(-ref_spice_lib) ne "") } {
  puts $fout "            if \{ \[array size refsigdata\] \} \{"
  puts $fout "               array unset refsigdata"
  puts $fout "            \}"
  puts $fout "            read_measure_data_to_array -dataarray refsigdata -meas \$\{__meas_dir\}/\$cell*.o-\$output.i-\$input.s-\$scnt.*ref*.mt0* $rmd"
  puts $fout "            if \{ \[array size refsigdata\] \} \{"
  puts $fout "            generate_aocv_table_from_array -dataarray sigdata -refdataarray refsigdata -aocv_file \$\{__pocv_dir\}/\${cell}.o-\$output.i-\$input.s-\$scnt.POCV -object_spec \$cell $gat"
  puts $fout "            \} else \{"
}
  puts $fout "            generate_aocv_table_from_array -dataarray sigdata -aocv_file \$\{__pocv_dir\}/\${cell}.o-\$output.i-\$input.s-\$scnt.POCV -object_spec \$cell $gat"
  if { ($cargs(-ref_spice_model) ne "") || ($cargs(-ref_spice_lib) ne "") } {
  puts $fout "            \}"
  }
  puts $fout "            \}"
  puts $fout "            # end of if sigdata"
  puts $fout "            incr scnt"
  puts $fout "            if \{ !\$all_sensitizations \} \{"
  puts $fout "               break"
  puts $fout "            \}"
  puts $fout "          \}"
  puts $fout "          # end of foreach sensitize"
  puts $fout "if \{ \$scnt == 0 \} \{"
  puts $fout "  puts \"Error: unable to match any sensitization vectors for cell: \$cell  input: \$input output: \$output\""
  puts $fout "  return 0;"
  puts $fout "\}"
  } elseif { ($cargs(-db) ne "") || ($cargs(-library) ne "") } {
  puts $fout "          if \{ \[array exists cellarray\] && \[info exists cellarray(cell,\$cell,pin,\$output,sensitization,\$input,edge,r)\] \} \{"
  puts $fout "             set sensitization_data \$cellarray(cell,\$cell,pin,\$output,sensitization,\$input,edge,r)"
  puts $fout "             foreach sensitize \$sensitization_data \{"
  puts $fout "            set file \[lindex \[glob -nocomplain \$\{__meas_dir\}/\$cell*.o-\$output.i-\$input.s-\$scnt.*mt0*\] 0\]"
  puts $fout "            if \{(\$file eq \"\")\} \{"
  puts $fout "                puts \"Error: \$\{__meas_dir\}/\$cell*.o-\$output.i-\$input.s-\$scnt.*mt0* not found\""
  puts $fout "                break"
  puts $fout "            \} elseif \{!\[file exists \"\$\{__pocv_dir\}/\$\{cell\}.o-\$output.i-\$input.s-\$scnt.POCV\"] || (\[file mtime \$file\] >  \[file mtime \"\$\{__pocv_dir\}/\${cell}.o-\$output.i-\$input.s-\$scnt.POCV\"\]) \} \{"
  puts $fout "            if \{ \[array size sigdata\] \} \{"
  puts $fout "               array unset sigdata"
  puts $fout "            \}"
  puts $fout "            read_measure_data_to_array -dataarray sigdata -meas \$\{__meas_dir\}/\$cell*.o-\$output.i-\$input.s-\$scnt.m-*.mt0* $rmd"
  if { ($cargs(-ref_spice_model) ne "" ) || ($cargs(-ref_spice_lib) ne "") } {
  puts $fout "            if \{ \[array size refsigdata\] \} \{"
  puts $fout "               array unset refsigdata"
  puts $fout "            \}"
  puts $fout "            read_measure_data_to_array -dataarray refsigdata -meas \$\{__meas_dir\}/\$cell*.o-\$output.i-\$input.s-\$scnt.*ref*.mt0* $rmd"
  puts $fout "            if \{ \[array size refsigdata\] \} \{"
  puts $fout "            generate_aocv_table_from_array -dataarray sigdata -refdataarray refsigdata -aocv_file \$\{__pocv_dir\}/\${cell}.o-\$output.i-\$input.s-\$scnt.POCV -object_spec \$cell $gat"
  puts $fout "            \} else \{"
}
  puts $fout "            generate_aocv_table_from_array -dataarray sigdata -aocv_file \$\{__pocv_dir\}/\${cell}.o-\$output.i-\$input.s-\$scnt.POCV -object_spec \$cell $gat"
   if { ($cargs(-ref_spice_model) ne "") || ($cargs(-ref_spice_lib) ne "")} {
  puts $fout "            \}"
  puts $fout "            # end of refsigdata"
   }
  puts $fout "            \}"
  puts $fout "            # end of elseif sigdata"
  puts $fout "            incr scnt"
  puts $fout "            if \{ !\$all_sensitizations \} \{"
  puts $fout "               break"
  puts $fout "            \}"
  puts $fout "            \}"
  puts $fout "            # end of foreach sensitize"
  puts $fout "         \} else \{"
  puts $fout "            # else cellarray sensitization"
  puts $fout "            set file \[lindex \[glob -nocomplain \$\{__meas_dir\}/\$cell*.o-\$output.i-\$input.s-\$scnt.*mt0*\] 0\]"
  puts $fout "            if \{(\$file eq \"\")\} \{"
  puts $fout "                puts \"Error: \$\{__meas_dir\}/\$cell*.o-\$output.i-\$input.s-\$scnt.*mt0* not found\""
  puts $fout "                break"
  puts $fout "            \} elseif \{!\[file exists \"\$\{__pocv_dir\}/\$\{cell\}.o-\$output.i-\$input.s-\$scnt.POCV\"] || (\[file mtime \$file\] >  \[file mtime \"\${cell}.o-\$output.i-\$input.s-\$scnt.POCV\"\]) \} \{"
  puts $fout "            if \{ \[array size sigdata\] \} \{"
  puts $fout "               array unset sigdata"
  puts $fout "            \}"
  puts $fout "            read_measure_data_to_array -dataarray sigdata -meas \$\{__meas_dir\}/\$cell*.o-\$output.i-\$input.s-\$scnt.m-*.mt0* $rmd"
  if { ($cargs(-ref_spice_model) ne "") || ($cargs(-ref_spice_lib) ne "") } {
  puts $fout "            if \{ \[array size refsigdata\] \} \{"
  puts $fout "               array unset refsigdata"
  puts $fout "            \}"
  puts $fout "            read_measure_data_to_array -dataarray refsigdata -meas \$\{__meas_dir\}/\$cell*.o-\$output.i-\$input.s-\$scnt.*ref*.mt0* $rmd"
  puts $fout "            if \{ \[array size refsigdata\] \} \{"
  puts $fout "            generate_aocv_table_from_array -dataarray sigdata -refdataarray refsigdata -aocv_file \$\{__pocv_dir\}/\${cell}.o-\$output.i-\$input.s-\$scnt.POCV -object_spec \$cell $gat"
  puts $fout "           \} else \{"
}
  puts $fout "            generate_aocv_table_from_array -dataarray sigdata -aocv_file \$\{__pocv_dir\}/\${cell}.o-\$output.i-\$input.s-\$scnt.POCV -object_spec \$cell $gat"
   if { ($cargs(-ref_spice_model) ne "") || ($cargs(-ref_spice_lib) ne "") } {
  puts $fout "           \}"
  puts $fout "            # end of refsigdata"
  }
  puts $fout "           \}"
  puts $fout "           # end of elseif sigdata"
  puts $fout "        \}"
  puts $fout "        # end of else cellarray sensitize"
  puts $fout "if \{ \$scnt == 0 \} \{"
  puts $fout "  puts \"Error: unable to match any sensitization vectors for cell: \$cell  input: \$input output: \$output\""
  puts $fout "  return 0;"
  puts $fout "\}"
   } else {
  puts $fout "         set file \[lindex \[glob -nocomplain \$\{__meas_dir\}/\$cell*.o-\$output.i-\$input.s-\$scnt.*mt0*\] 0\]"
  puts $fout "         if \{(\$file eq \"\")\} \{"
  puts $fout "             puts \"Error: \$\{__meas_dir\}/\$cell*.o-\$output.i-\$input.s-\$scnt.*mt0* not found\""
  puts $fout "             break"
  puts $fout "         \} elseif \{!\[file exists \"\$\{__pocv_dir\}/\$\{cell\}.o-\$output.i-\$input.s-\$scnt.POCV\"] || (\[file mtime \$file\] >  \[file mtime \"\$\{__pocv_dir\}/\${cell}.o-\$output.i-\$input.s-\$scnt.POCV\"\] )\} \{"
  puts $fout "         if \{ \[array size sigdata\] \} \{"
  puts $fout "            array unset sigdata"
  puts $fout "         \}"
  puts $fout "         read_measure_data_to_array -dataarray sigdata -meas \$\{__meas_dir\}/\$cell*.o-\$output.i-\$input.s-\$scnt.m-*.mt0* $rmd"
   if { ($cargs(-ref_spice_model) ne "") || ($cargs(-ref_spice_lib) ne "") } {
  puts $fout "         if \{ \[array size refsigdata\] \} \{"
  puts $fout "            array unset refsigdata"
  puts $fout "         \}"
  puts $fout "         read_measure_data_to_array -dataarray refsigdata -meas \$\{__meas_dir\}/\$cell*.o-\$output.i-\$input.s-\$scnt.*ref.mt0* $rmd"
  puts $fout "         if \{ \[array size refsigdata\] \} \{"
  puts $fout "         generate_aocv_table_from_array -dataarray sigdata -refdataarray refsigdata -aocv_file \$\{__pocv_dir\}/\${cell}.o-\$output.i-\$input.s-\$scnt.POCV -object_spec \$cell $gat"
  puts $fout "        \} else \{"
   }
  puts $fout "         generate_aocv_table_from_array -dataarray sigdata -aocv_file \$\{__pocv_dir\}/\${cell}.o-\$output.i-\$input.s-\$scnt.POCV -object_spec \$cell $gat"
  puts $fout "         \}"
   if { ($cargs(-ref_spice_model) ne "") || ($cargs(-ref_spice_lib) ne "") } {
  puts $fout "         \}"
  puts $fout "          # end of refsigdata"
   }
  puts $fout "         \}"
  puts $fout "         # end of elseif"
   }
   puts $fout "      \}"
   puts $fout "      # end of foreach input"
   puts $fout "   \}"
   puts $fout "   # end of foreach output"
   puts $fout "   set file \[lindex \[glob -nocomplain \$\{__pocv_dir\}/\$cell*.o-*.i-*.s-*.POCV\] 0\]"
   puts $fout "   if \{(\$file eq \"\")\} \{"
   puts $fout "      puts \"Error: \$\{__pocv_dir\}/\$cell*.o-*.i-*.s-*.POCV not found\""
  puts $fout "       break"
   puts $fout "   \} elseif \{!\[file exists \"\$\{__pocv_dir\}/\$\{cell\}.POCV\"] || (\[file mtime \$file\] >  \[file mtime \"\\$\{__pocv_dir\}/\${cell}.POCV\"\] )\} \{"
   puts $fout "      merge_cell_aocv -output \$\{__pocv_dir\}/\${cell}.POCV -cell \${cell} -files \$\{__pocv_dir\}/\${cell}.o-*.i-*.*POCV -pocv_dir \$__pocv_dir $mca"
   puts $fout "   \} else \{"
   puts $fout "      puts \"\$cell.POCV generation is up to date\""
   puts $fout "   \}"
   puts $fout "   \}"
   puts $fout "    # end of foreach cell"
   puts $fout "\}"
   puts $fout "# end of foreach cellname"
   close $fout
   exec chmod 777 $cargs(-table_runscript)
  }

  if { $cargs(-nt_coeff_runscript) ne "" } {
  puts "Creating runscript($cargs(-nt_coeff_runscript)) for generating variation coeff data"
  # write the runscript for reading measure files & generating variation data
  set  fout [open $cargs(-nt_coeff_runscript) w]
  puts $fout "#!/bin/sh"
  puts $fout "# the next line restarts using tclsh \\"
  puts $fout "exec tclsh \"\$0\" \"\$\@\""

  puts $fout "set __script_dir $cargs(-scripts_dir)"
  puts $fout "global __script_dir"
  puts $fout "set __meas_dir $cargs(-meas_dir)"
  puts $fout "global __meas_dir"
  puts $fout "set __pocv_dir $cargs(-pocv_dir)"
  puts $fout "global __pocv_dir"


   puts $fout "set __date \[clock format \[clock seconds\] -format \{\%a \%b \%d \%H:\%M:\%S \%Z \%Y\}\]"
   puts $fout "global __date"

   puts $fout "if \{ \[file exists \$__script_dir/Simple_pocv_generation.tcl\] \} \{"
   puts $fout "  source \$__script_dir/Simple_pocv_generation.tcl"
   puts $fout "\} else \{"
   puts $fout "  puts \"ERROR: Simple_pocv_generation.tcl not found(Please place all POCV script files in same directory)\""
   puts $fout "  exit"
   puts $fout "\}"
   puts $fout "if \{ \[file exists \$__script_dir/general_pocv.tcl\] \} \{"
   puts $fout "   source \$__script_dir/general_pocv.tcl"
   puts $fout "\} else \{"
   puts $fout "   puts \"ERROR: general_pocv.tcl not found(Please place all POCV script files in same directory)\""
   puts $fout "   exit"
   puts $fout "\}"
   puts $fout "if \{ \[file exists \$__script_dir/read_db_data.tcl\] \} \{"
   puts $fout "   source \$__script_dir/read_db_data.tcl"
   puts $fout "\} elseif \{ \[file exists \$__script_dir/read_db_data.tbc\] \} \{"
   puts $fout "   append auto_path \" \$__script_dir/tbcload\""
   puts $fout "   package require tbcload 1.4"
   puts $fout "   source \$__script_dir/read_db_data.tbc"
   puts $fout "\} else \{"
   puts $fout "   puts \"ERROR: read_db_data.tbc not found(Please place all POCV script files in same directory)\""
   puts $fout "   exit"
   puts $fout "\}"

   # if DB/.lib is given then use the byte code to grab some attributes
   if { ($cargs(-db) ne "") } {
    ## check if DB defined -nocase
    puts $fout "if \{(\[info procs ::read_db_cell_data\] ne \"\")\} \{"
    puts $fout "::read_db_cell_data -array_name cellarray -db \"$cargs(-db)\" -tmplt_dir \$__meas_dir -scripts_dir \$__script_dir -cell \"$cargs(-cell)\""
    puts $fout "\}"
   } elseif { ($cargs(-library) ne "")} {
    puts $fout "if \{(\[info procs ::read_db_cell_data\] ne \"\")\} \{"
    puts $fout "::read_db_cell_data -array_name cellarray -library \"$cargs(-library)\" -tmplt_dir \$__meas_dir -scripts_dir \$__script_dir -cell \"$cargs(-cell)\""
    puts $fout "\}" 
  }

  puts $fout "foreach cellname \[split \"$cargs(-cell)\"\] \{"
  puts $fout "  set cellname \[string trim \$cellname\]"
  puts $fout "  if \{ \[array exists cellarray\] && (\[llength \[keys cellarray(cell)\] \] \> 0 )\} \{"
  puts $fout "    set cells \[keys cellarray(cell)\]"
  puts $fout "  \} else \{"
  puts $fout "    set cells \$cellname"
  puts $fout "  \}"
  puts $fout "  foreach cell \[lsearch \-all \-inline \$cells \$cellname\] \{"
  puts $fout "    puts \"Processing Cell: \$cell\""
  puts $fout "    set ext \"\""
  puts $fout "    regexp -nocase \"\$\{cell\}\(\\\[^ \\\]+\)$\" \$__meas_dir dummy ext"
  puts $fout "    if \{ \$ext eq \"\" \} \{"
  puts $fout "        set ext \[file tail \$__meas_dir\]"
  puts $fout "    \}"
  if { ($cargs(-output) eq "") } {
     if { (($cargs(-db) ne "" ) || ($cargs(-library) ne "" )) } {
        if { $cargs(-all_outputs) } {
  puts $fout "    if \{ \[array exists cellarray\] && \[info exists cellarray(cell,\$cell,output_list)\] \} \{"
  puts $fout "    set outputs \$cellarray(cell,\$cell,output_list)"
  puts $fout "    \} elseif \{ \[array exists cellarray\] && \[info exists cellarray(cell,\$cell,output)\] \} \{"
  puts $fout "    set outputs \$cellarray(cell,\$cell,output)"
  puts $fout "    \} else \{"
  puts $fout "    puts \"Error: no output pin given or found, use -output option to specify\""
  puts $fout "    return 0"
  puts $fout "    \}"
	} else {
  puts $fout "    if \{ \[array exists cellarray\] && \[info exists cellarray(cell,\$cell,output)\] \} \{"
  puts $fout "    set outputs \$cellarray(cell,\$cell,output)"
  puts $fout "    \} else \{"
  puts $fout "    puts \"Error: no output pin given or found, use -output option to specify\""
  puts $fout "    return 0"
  puts $fout "    \}"
	}
     } else {
	puts "Error: no output pin given or found, use -output or -db/-library option to specify"
	return 0
     }
  } else {
        puts $fout "    set outputs \"$cargs(-output)\""
        puts $fout "    set tmp_outputs \"\""
	puts $fout "    while \{ \[ regexp \"\$cell\\\[ \\t\\\]*\\\:\\\[ \\t\\\]*\(\\\[^ \\t\\\}\\\{\\\]+\)\" \$outputs dum opt1\] \} \{"
	puts $fout "    regsub \"\$cell\\\[ \\t\\\]*\\\:\\\[ \\t\\\]*\(\\\[^ \\t\\\}\\\{\\\]+\)\" \$outputs \{\} outputs"
	puts $fout "    set tmp_outputs \$opt1"
	puts $fout "    \}"
	puts $fout "    if \{ \$tmp_outputs ne \"\" \} \{"
	puts $fout "    set outputs \$tmp_outputs"
	puts $fout "    \}"
  }
  if { ($cargs(-input) eq "") } {
     if { (($cargs(-db) ne "" ) || ($cargs(-library) ne "" )) } {
	if { $cargs(-all_inputs) } {
  puts $fout "    if \{ \[array exists cellarray\] && \[info exists cellarray(cell,\$cell,input_list)\] \} \{"
  puts $fout "    set inputs \$cellarray(cell,\$cell,input_list)"
  puts $fout "    \} elseif \{ \[array exists cellarray\] && \[info exists cellarray(cell,\$cell,input)\] \} \{"
  puts $fout "    set inputs \$cellarray(cell,\$cell,input)"
  puts $fout "    \} else \{"
  puts $fout "    puts \"Error: no input pin given or found, use -input option to specify\""
  puts $fout "    return 0"
  puts $fout "    \}"
	} else {
  puts $fout "    if \{ \[array exists cellarray\] && \[info exists cellarray(cell,\$cell,input)\] \} \{"
  puts $fout "    set inputs \$cellarray(cell,\$cell,input)"
  puts $fout "    \} else \{"
  puts $fout "    puts \"Error: no input pin given or found, use -input option to specify\""
  puts $fout "    return 0"
  puts $fout "    \}"
	}
     } else {
	puts "Error: no output pin given or found, use -input or -db/-library option to specify"
        return 0
     }
  } else {
        puts $fout "    set inputs \"$cargs(-input)\""
        puts $fout "    set tmp_inputs \"\""
	puts $fout "    while \{ \[ regexp \"\$cell\\\[ \\t\\\]*\\\:\\\[ \\t\\\]*\(\\\[^ \\t\\\}\\\{\\\]+\)\" \$inputs dum opt1\] \} \{"
	puts $fout "    regsub \"\$cell\\\[ \\t\\\]*\\\:\\\[ \\t\\\]*\(\\\[^ \\t\\\}\\\{\\\]+\)\" \$inputs \{\} inputs"
	puts $fout "    set tmp_inputs \$opt1"
	puts $fout "    \}"
	puts $fout "    if \{ \$tmp_inputs ne \"\" \} \{"
	puts $fout "    set inputs \$tmp_inputs"
	puts $fout "    \}"
  }
  puts $fout "    set outputs \[regsub -all \"\\\[ \\t\\\]+\" \[string trim \[join \$outputs\]\] \{ \}\]"
  puts $fout "    set inputs \[regsub -all \"\\\[ \\t\\\]+\" \[string trim \[join \$inputs\]\] \{ \}\]"
  puts $fout "    foreach output \[split \"\$outputs\"\] \{"
  puts $fout "       foreach input \[split \"\$inputs\"\] \{"
  if { $cargs(-all_sensitizations) } {
  puts $fout "         set all_sensitizations 1"
  } else {
  puts $fout "         set all_sensitizations 0"
  }
  puts $fout "         set scnt 0"
  if { ($cargs(-sensitization_data) ne "\{\}") && !(([llength $cargs(-sensitization_data)] == 1) && ([lindex $cargs(-sensitization_data) 0 ] ne  "\{\}")) } {
  puts $fout "         foreach sensitize \[list $cargs(-sensitization_data)\] \{"
  puts $fout "            set file \[lindex \[glob -nocomplain \$\{__meas_dir\}/\$cell*.o-\$output.i-\$input.s-\$scnt.*mt0*\] 0\]"
  puts $fout "            if \{(\$file eq \"\")\} \{"
  puts $fout "                puts \"Error: \$\{__meas_dir\}/\$cell*.o-\$output.i-\$input.s-\$scnt.*mt0* not found\""
  puts $fout "                break"
  puts $fout "            \} else \{"
  puts $fout "            if \{ \[array size sigdata\] \} \{"
  puts $fout "               array unset sigdata"
  puts $fout "            \}"
  puts $fout "            read_measure_data_to_array -dataarray sigdata -meas \$\{__meas_dir\}/\$cell*.o-\$output.i-\$input.s-\$scnt.m-*.mt0* $rmd"
 if { ($cargs(-ref_spice_model) ne "") || ($cargs(-ref_spice_lib) ne "") } {
  puts $fout "            if \{ \[array size refsigdata\] \} \{"
  puts $fout "               array unset refsigdata"
  puts $fout "            \}"
  puts $fout "            read_measure_data_to_array -dataarray refsigdata -meas \$\{__meas_dir\}/\$cell*.o-\$output.i-\$input.s-\$scnt.*ref*.mt0* $rmd"
  puts $fout "            if \{ \[array size refsigdata\] \} \{"
  puts $fout "		  generate_delay_variation_coeff_from_array -dataarray sigdata -resultsarray resdata -coeff $cargs(-nt_coeff_file) $gdc"
  puts $fout "            \} else \{"
  puts $fout "		  generate_delay_variation_coeff_from_array -dataarray sigdata -resultsarray resdata -coeff $cargs(-nt_coeff_file) $gdc"
  puts $fout "            \}"
  puts $fout "            # end of if refsigdata"
} else {
  puts $fout "		  generate_delay_variation_coeff_from_array -dataarray sigdata -resultsarray resdata -coeff $cargs(-nt_coeff_file) $gdc"
}
  puts $fout "            \}"
  puts $fout "            # end of if sigdata"
  puts $fout "            incr scnt"
  puts $fout "            if \{ !\$all_sensitizations \} \{"
  puts $fout "               break"
  puts $fout "            \}"
  puts $fout "          \}"
  puts $fout "          # end of foreach sensitize"
  } elseif { ($cargs(-db) ne "") || ($cargs(-library) ne "") } {
  puts $fout "          if \{ \[array exists cellarray\] && \[info exists cellarray(cell,\$cell,pin,\$output,sensitization,\$input,edge,r)\] \} \{"
  puts $fout "             set sensitization_data \$cellarray(cell,\$cell,pin,\$output,sensitization,\$input,edge,r)"
  puts $fout "             foreach sensitize \$sensitization_data \{"
  puts $fout "            set file \[lindex \[glob -nocomplain \$\{__meas_dir\}/\$cell*.o-\$output.i-\$input.s-\$scnt.*mt0*\] 0\]"
  puts $fout "            if \{(\$file eq \"\")\} \{"
  puts $fout "                puts \"Error: \$\{__meas_dir\}/\$cell*.o-\$output.i-\$input.s-\$scnt.*mt0* not found\""
  puts $fout "                break"
  puts $fout "            \} else \{"
  puts $fout "            if \{ \[array size sigdata\] \} \{"
  puts $fout "               array unset sigdata"
  puts $fout "            \}"
  puts $fout "            read_measure_data_to_array -dataarray sigdata -meas \$\{__meas_dir\}/\$cell*.o-\$output.i-\$input.s-\$scnt.m-*.mt0* $rmd"
  if { ($cargs(-ref_spice_model) ne "" ) || ($cargs(-ref_spice_lib) ne "") } {
  puts $fout "            if \{ \[array size refsigdata\] \} \{"
  puts $fout "               array unset refsigdata"
  puts $fout "            \}"
  puts $fout "            read_measure_data_to_array -dataarray refsigdata -meas \$\{__meas_dir\}/\$cell*.o-\$output.i-\$input.s-\$scnt.*ref*.mt0* $rmd"
  puts $fout "            if \{ \[array size refsigdata\] \} \{"
  puts $fout "		  generate_delay_variation_coeff_from_array -dataarray sigdata -resultsarray resdata -coeff $cargs(-nt_coeff_file) $gdc"
  puts $fout "            \} else \{"
  puts $fout "		  generate_delay_variation_coeff_from_array -dataarray sigdata -resultsarray resdata -coeff $cargs(-nt_coeff_file) $gdc"
  puts $fout "            \}"
  puts $fout "            # end of refsigdata"
} else {
  puts $fout "		  generate_delay_variation_coeff_from_array -dataarray sigdata -resultsarray resdata -coeff $cargs(-nt_coeff_file) $gdc"
}
  puts $fout "            \}"
  puts $fout "            # end of elseif sigdata"
  puts $fout "            incr scnt"
  puts $fout "            if \{ !\$all_sensitizations \} \{"
  puts $fout "               break"
  puts $fout "            \}"
  puts $fout "            \}"
  puts $fout "            # end of foreach sensitize"
  puts $fout "         \} else \{"
  puts $fout "            # else cellarray sensitization"
  puts $fout "            set file \[lindex \[glob -nocomplain \$\{__meas_dir\}/\$cell*.o-\$output.i-\$input.s-\$scnt.*mt0*\] 0\]"
  puts $fout "            if \{(\$file eq \"\")\} \{"
  puts $fout "                puts \"Error: \$\{__meas_dir\}/\$cell*.o-\$output.i-\$input.s-\$scnt.*mt0* not found\""
  puts $fout "                break"
  puts $fout "            \} else \{"
  puts $fout "            if \{ \[array size sigdata\] \} \{"
  puts $fout "               array unset sigdata"
  puts $fout "            \}"
  puts $fout "            read_measure_data_to_array -dataarray sigdata -meas \$\{__meas_dir\}/\$cell*.o-\$output.i-\$input.s-\$scnt.m-*.mt0* $rmd"
  if { ($cargs(-ref_spice_model) ne "") || ($cargs(-ref_spice_lib) ne "") } {
  puts $fout "            if \{ \[array size refsigdata\] \} \{"
  puts $fout "               array unset refsigdata"
  puts $fout "            \}"
  puts $fout "            read_measure_data_to_array -dataarray refsigdata -meas \$\{__meas_dir\}/\$cell*.o-\$output.i-\$input.s-\$scnt.*ref*.mt0* $rmd"
  puts $fout "            if \{ \[array size refsigdata\] \} \{"
  puts $fout "		  generate_delay_variation_coeff_from_array -dataarray sigdata -resultsarray resdata -coeff $cargs(-nt_coeff_file) $gdc"
  puts $fout "           \} else \{"
  puts $fout "		  generate_delay_variation_coeff_from_array -dataarray sigdata -resultsarray resdata -coeff $cargs(-nt_coeff_file) $gdc"
  puts $fout "           \}"
  puts $fout "            # end of refsigdata"
  } else {
  puts $fout "		  generate_delay_variation_coeff_from_array -dataarray sigdata -resultsarray resdata -coeff $cargs(-nt_coeff_file) $gdc"
  }
  puts $fout "        \}"
  puts $fout "           # end of elseif sigdata"
  puts $fout "        \}"
  puts $fout "        # end of else cellarray sensitize"
   } else {
  puts $fout "         set file \[lindex \[glob -nocomplain \$\{__meas_dir\}/\$cell*.o-\$output.i-\$input.s-\$scnt.*mt0*\] 0\]"
  puts $fout "         if \{(\$file eq \"\")\} \{"
  puts $fout "             puts \"Error: \$\{__meas_dir\}/\$cell*.o-\$output.i-\$input.s-\$scnt.*mt0* not found\""
  puts $fout "                break"
  puts $fout "         \} else \{"
  puts $fout "         if \{ \[array size sigdata\] \} \{"
  puts $fout "            array unset sigdata"
  puts $fout "         \}"
  puts $fout "         read_measure_data_to_array -dataarray sigdata -meas \$\{__meas_dir\}/\$cell*.o-\$output.i-\$input.s-\$scnt.m-*.mt0* $rmd"
   if { ($cargs(-ref_spice_model) ne "") || ($cargs(-ref_spice_lib) ne "") } {
  puts $fout "         if \{ \[array size refsigdata\] \} \{"
  puts $fout "            array unset refsigdata"
  puts $fout "         \}"
  puts $fout "         read_measure_data_to_array -dataarray refsigdata -meas \$\{__meas_dir\}/\$cell*.o-\$output.i-\$input.s-\$scnt.*ref.mt0* $rmd"
  puts $fout "         if \{ \[array size refsigdata\] \} \{"
  puts $fout "		  generate_delay_variation_coeff_from_array -dataarray sigdata -resultsarray resdata -coeff $cargs(-nt_coeff_file) $gdc"
  puts $fout "        \} else \{"
  puts $fout "		  generate_delay_variation_coeff_from_array -dataarray sigdata -resultsarray resdata -coeff $cargs(-nt_coeff_file) $gdc"
  puts $fout "         \}"
  puts $fout "          # end of refsigdata"
   } else {
  puts $fout "		  generate_delay_variation_coeff_from_array -dataarray sigdata -resultsarray resdata -coeff $cargs(-nt_coeff_file) $gdc"
  }
  puts $fout "         \}"
  puts $fout "         # end of elseif"
   }
   puts $fout "      \}"
   puts $fout "      # end of foreach input"
   puts $fout "   \}"
   puts $fout "   # end of foreach output"
   puts $fout "   \}"
   puts $fout "    # end of foreach cell"
   puts $fout "\}"
   puts $fout "# end of foreach cellname"
   close $fout
   exec chmod 777 $cargs(-nt_coeff_runscript)
   }
   
  if { $cargs(-delay_runscript) ne "" } {
  puts "Creating runscript($cargs(-delay_runscript)) for generating variation data from Measure data"
  # write the runscript for reading measure files & generating variation data
  set  fout [open $cargs(-delay_runscript) w]
  puts $fout "#!/bin/sh"
  puts $fout "# the next line restarts using tclsh \\"
  puts $fout "exec tclsh \"\$0\" \"\$\@\""

  puts $fout "set __script_dir $cargs(-scripts_dir)"
  puts $fout "global __script_dir"
  puts $fout "set __meas_dir $cargs(-meas_dir)"
  puts $fout "global __meas_dir"
  puts $fout "set __pocv_dir $cargs(-pocv_dir)"
  puts $fout "global __pocv_dir"


   puts $fout "set __date \[clock format \[clock seconds\] -format \{\%a \%b \%d \%H:\%M:\%S \%Z \%Y\}\]"
   puts $fout "global __date"

   puts $fout "if \{ \[file exists \$__script_dir/Simple_pocv_generation.tcl\] \} \{"
   puts $fout "  source \$__script_dir/Simple_pocv_generation.tcl"
   puts $fout "\} else \{"
   puts $fout "  puts \"ERROR: Simple_pocv_generation.tcl not found(Please place all POCV script files in same directory)\""
   puts $fout "  exit"
   puts $fout "\}"
   puts $fout "if \{ \[file exists \$__script_dir/general_pocv.tcl\] \} \{"
   puts $fout "   source \$__script_dir/general_pocv.tcl"
   puts $fout "\} else \{"
   puts $fout "   puts \"ERROR: general_pocv.tcl not found(Please place all POCV script files in same directory)\""
   puts $fout "   exit"
   puts $fout "\}"
   puts $fout "if \{ \[file exists \$__script_dir/read_db_data.tcl\] \} \{"
   puts $fout "   source \$__script_dir/read_db_data.tcl"
   puts $fout "\} elseif \{ \[file exists \$__script_dir/read_db_data.tbc\] \} \{"
   puts $fout "   append auto_path \" \$__script_dir/tbcload\""
   puts $fout "   package require tbcload 1.4"
   puts $fout "   source \$__script_dir/read_db_data.tbc"
   puts $fout "\} else \{"
   puts $fout "   puts \"ERROR: read_db_data.tbc not found(Please place all POCV script files in same directory)\""
   puts $fout "   exit"
   puts $fout "\}"
   
   # if DB/.lib is given then use the byte code to grab some attributes
   if { ($cargs(-db) ne "") } {
    ## check if DB defined -nocase
    puts $fout "if \{(\[info procs ::read_db_cell_data\] ne \"\")\} \{"
    puts $fout "::read_db_cell_data -array_name cellarray -db \"$cargs(-db)\" -tmplt_dir \$__meas_dir -scripts_dir \$__script_dir -cell \"$cargs(-cell)\""
    puts $fout "\}"
   } elseif { ($cargs(-library) ne "")} {
    puts $fout "if \{(\[info procs ::read_db_cell_data\] ne \"\")\} \{"
    puts $fout "::read_db_cell_data -array_name cellarray -library \"$cargs(-library)\" -tmplt_dir \$__meas_dir -scripts_dir \$__script_dir -cell \"$cargs(-cell)\""
    puts $fout "\}" 
  }

  puts $fout "foreach cellname \[split \"$cargs(-cell)\"\] \{"
  puts $fout "  set cellname \[string trim \$cellname\]"
  puts $fout "  if \{ \[array exists cellarray\] && (\[llength \[keys cellarray(cell)\] \] \> 0 )\} \{"
  puts $fout "    set cells \[keys cellarray(cell)\]"
  puts $fout "  \} else \{"
  puts $fout "    set cells \$cellname"
  puts $fout "  \}"
  puts $fout "  foreach cell \[lsearch \-all \-inline \$cells \$cellname\] \{"
  puts $fout "    puts \"Processing Cell: \$cell\""
  puts $fout "    set ext \"\""
  puts $fout "    regexp -nocase \"\$\{cell\}\(\\\[^ \\\]+\)$\" \$__meas_dir dummy ext"
  puts $fout "    if \{ \$ext eq \"\" \} \{"
  puts $fout "        set ext \"HSP\""
  puts $fout "        #set ext \[file tail \$__meas_dir\]"
  puts $fout "    \}"
  if { ($cargs(-output) eq "") } {
     if { (($cargs(-db) ne "" ) || ($cargs(-library) ne "" )) } {
        if { $cargs(-all_outputs) } {
  puts $fout "    if \{ \[array exists cellarray\] && \[info exists cellarray(cell,\$cell,output_list)\] \} \{"
  puts $fout "    set outputs \$cellarray(cell,\$cell,output_list)"
  puts $fout "    \} elseif \{ \[array exists cellarray\] && \[info exists cellarray(cell,\$cell,output)\] \} \{"
  puts $fout "    set outputs \$cellarray(cell,\$cell,output)"
  puts $fout "    \} else \{"
  puts $fout "    puts \"Error: no output pin given or found, use -output option to specify\""
  puts $fout "    return 0"
  puts $fout "    \}"
	} else {
  puts $fout "    if \{ \[array exists cellarray\] && \[info exists cellarray(cell,\$cell,output)\] \} \{"
  puts $fout "    set outputs \$cellarray(cell,\$cell,output)"
  puts $fout "    \} else \{"
  puts $fout "    puts \"Error: no output pin given or found, use -output option to specify\""
  puts $fout "    return 0"
  puts $fout "    \}"
	}
     } else {
	puts "Error: no output pin given or found, use -output or -db/-library option to specify"
	return 0
     }
  } else {
        puts $fout "    set outputs \"$cargs(-output)\""
        puts $fout "    set tmp_outputs \"\""
	puts $fout "    while \{ \[ regexp \"\$cell\\\[ \\t\\\]*\\\:\\\[ \\t\\\]*\(\\\[^ \\t\\\}\\\{\\\]+\)\" \$outputs dum opt1\] \} \{"
	puts $fout "    regsub \"\$cell\\\[ \\t\\\]*\\\:\\\[ \\t\\\]*\(\\\[^ \\t\\\}\\\{\\\]+\)\" \$outputs \{\} outputs"
	puts $fout "    set tmp_outputs \$opt1"
	puts $fout "    \}"
	puts $fout "    if \{ \$tmp_outputs ne \"\" \} \{"
	puts $fout "    set outputs \$tmp_outputs"
	puts $fout "    \}"
  }
  if { ($cargs(-input) eq "") } {
     if { (($cargs(-db) ne "" ) || ($cargs(-library) ne "" )) } {
	if { $cargs(-all_inputs) } {
  puts $fout "    if \{ \[array exists cellarray\] && \[info exists cellarray(cell,\$cell,input_list)\] \} \{"
  puts $fout "    set inputs \$cellarray(cell,\$cell,input_list)"
  puts $fout "    \} elseif \{ \[array exists cellarray\] && \[info exists cellarray(cell,\$cell,input)\] \} \{"
  puts $fout "    set inputs \$cellarray(cell,\$cell,input)"
  puts $fout "    \} else \{"
  puts $fout "    puts \"Error: no input pin given or found, use -input option to specify\""
  puts $fout "    return 0"
  puts $fout "    \}"
	} else {
  puts $fout "    if \{ \[array exists cellarray\] && \[info exists cellarray(cell,\$cell,input)\] \} \{"
  puts $fout "    set inputs \$cellarray(cell,\$cell,input)"
  puts $fout "    \} else \{"
  puts $fout "    puts \"Error: no input pin given or found, use -input option to specify\""
  puts $fout "    return 0"
  puts $fout "    \}"
	}
     } else {
	puts "Error: no output pin given or found, use -input or -db/-library option to specify"
        return 0
     }
  } else {
        puts $fout "    set inputs \"$cargs(-input)\""
        puts $fout "    set tmp_inputs \"\""
	puts $fout "    while \{ \[ regexp \"\$cell\\\[ \\t\\\]*\\\:\\\[ \\t\\\]*\(\\\[^ \\t\\\}\\\{\\\]+\)\" \$inputs dum opt1\] \} \{"
	puts $fout "    regsub \"\$cell\\\[ \\t\\\]*\\\:\\\[ \\t\\\]*\(\\\[^ \\t\\\}\\\{\\\]+\)\" \$inputs \{\} inputs"
	puts $fout "    set tmp_inputs \$opt1"
	puts $fout "    \}"
	puts $fout "    if \{ \$tmp_inputs ne \"\" \} \{"
	puts $fout "    set inputs \$tmp_inputs"
	puts $fout "    \}"
  }
  puts $fout "    set outputs \[regsub -all \"\\\[ \\t\\\]+\" \[string trim \[join \$outputs\]\] \{ \}\]"
  puts $fout "    set inputs \[regsub -all \"\\\[ \\t\\\]+\" \[string trim \[join \$inputs\]\] \{ \}\]"
  puts $fout "    foreach output \[split \"\$outputs\"\] \{"
  puts $fout "       foreach input \[split \"\$inputs\"\] \{"
  if { $cargs(-all_sensitizations) } {
  puts $fout "         set all_sensitizations 1"
  } else {
  puts $fout "         set all_sensitizations 0"
  }
  puts $fout "         set scnt 0"
  if { $cargs(-sensitization_data) ne "" } {
  puts $fout "         foreach sensitize \[list $cargs(-sensitization_data)\] \{"
  puts $fout "            set file \[lindex \[glob -nocomplain \$\{__meas_dir\}/\$cell*.o-\$output.i-\$input.s-\$scnt.*mt0*\] 0\]"
  puts $fout "            if \{(\$file eq \"\")\} \{"
  puts $fout "                puts \"Error: \$\{__meas_dir\}/\$cell*.o-\$output.i-\$input.s-\$scnt.*mt0* not found\""
  puts $fout "                break"
  puts $fout "            \} else \{"
  puts $fout "            if \{ \[array size sigdata\] \} \{"
  puts $fout "               array unset sigdata"
  puts $fout "            \}"
  puts $fout "            read_measure_data_to_array -dataarray sigdata -meas \$\{__meas_dir\}/\$cell*.o-\$output.i-\$input.s-\$scnt.m-*.mt0* $rmd"
 if { ($cargs(-ref_spice_model) ne "") || ($cargs(-ref_spice_lib) ne "") } {
  puts $fout "            if \{ \[array size refsigdata\] \} \{"
  puts $fout "               array unset refsigdata"
  puts $fout "            \}"
  puts $fout "            read_measure_data_to_array -dataarray refsigdata -meas \$\{__meas_dir\}/\$cell*.o-\$output.i-\$input.s-\$scnt.*ref*.mt0* $rmd"
  puts $fout "            if \{ \[array size refsigdata\] \} \{"
  puts $fout "		  generate_slewdelay_variation_from_array -dataarray sigdata -resultsarray resdata -xcel \$\{__meas_dir\}/\${cell}.o-\$output.i-\$input.s-\$\{scnt\}.\$ext.csv $gsd -add_slew_var"
  puts $fout "            \} else \{"
  puts $fout "		  generate_slewdelay_variation_from_array -dataarray sigdata -resultsarray resdata -xcel \$\{__meas_dir\}/\${cell}.o-\$output.i-\$input.s-\$\{scnt\}.\$ext.csv $gsd -add_slew_var"
  puts $fout "            \}"
  puts $fout "            # end of if refsigdata"
} else {
  puts $fout "		  generate_slewdelay_variation_from_array -dataarray sigdata -resultsarray resdata -xcel \$\{__meas_dir\}/\${cell}.o-\$output.i-\$input.s-\$\{scnt\}.\$ext.csv $gsd -add_slew_var"
}
  puts $fout "            \}"
  puts $fout "            # end of if sigdata"
  puts $fout "            incr scnt"
  puts $fout "            if \{ !\$all_sensitizations \} \{"
  puts $fout "               break"
  puts $fout "            \}"
  puts $fout "          \}"
  puts $fout "          # end of foreach sensitize"
  } elseif { ($cargs(-db) ne "") || ($cargs(-library) ne "") } {
  puts $fout "          if \{ \[array exists cellarray\] && \[info exists cellarray(cell,\$cell,pin,\$output,sensitization,\$input,edge,r)\] \} \{"
  puts $fout "             set sensitization_data \$cellarray(cell,\$cell,pin,\$output,sensitization,\$input,edge,r)"
  puts $fout "             foreach sensitize \$sensitization_data \{"
  puts $fout "            set file \[lindex \[glob -nocomplain \$\{__meas_dir\}/\$cell*.o-\$output.i-\$input.s-\$scnt.*mt0*\] 0\]"
  puts $fout "            if \{(\$file eq \"\")\} \{"
  puts $fout "                puts \"Error: \$\{__meas_dir\}/\$cell*.o-\$output.i-\$input.s-\$scnt.*mt0* not found\""
  puts $fout "                break"
  puts $fout "            \} else \{"
  puts $fout "            if \{ \[array size sigdata\] \} \{"
  puts $fout "               array unset sigdata"
  puts $fout "            \}"
  puts $fout "            read_measure_data_to_array -dataarray sigdata -meas \$\{__meas_dir\}/\$cell*.o-\$output.i-\$input.s-\$scnt.m-*.mt0* $rmd"
  if { ($cargs(-ref_spice_model) ne "" ) || ($cargs(-ref_spice_lib) ne "") } {
  puts $fout "            if \{ \[array size refsigdata\] \} \{"
  puts $fout "               array unset refsigdata"
  puts $fout "            \}"
  puts $fout "            read_measure_data_to_array -dataarray refsigdata -meas \$\{__meas_dir\}/\$cell*.o-\$output.i-\$input.s-\$scnt.*ref*.mt0* $rmd"
  puts $fout "            if \{ \[array size refsigdata\] \} \{"
  puts $fout "		  generate_slewdelay_variation_from_array -dataarray sigdata -resultsarray resdata -xcel \$\{__meas_dir\}/\${cell}.o-\$output.i-\$input.s-\$\{scnt\}.\$ext.csv $gsd -add_slew_var"
  puts $fout "            \} else \{"
  puts $fout "		  generate_slewdelay_variation_from_array -dataarray sigdata -resultsarray resdata -xcel \$\{__meas_dir\}/\${cell}.o-\$output.i-\$input.s-\$\{scnt\}.\$ext.csv $gsd -add_slew_var"
  puts $fout "            \}"
  puts $fout "            # end of refsigdata"
} else {
  puts $fout "		  generate_slewdelay_variation_from_array -dataarray sigdata -resultsarray resdata -xcel \$\{__meas_dir\}/\${cell}.o-\$output.i-\$input.s-\$\{scnt\}.\$ext.csv $gsd -add_slew_var"
}
  puts $fout "            \}"
  puts $fout "            # end of elseif sigdata"
  puts $fout "            incr scnt"
  puts $fout "            if \{ !\$all_sensitizations \} \{"
  puts $fout "               break"
  puts $fout "            \}"
  puts $fout "            \}"
  puts $fout "            # end of foreach sensitize"
  puts $fout "         \} else \{"
  puts $fout "            # else cellarray sensitization"
  puts $fout "            set file \[lindex \[glob -nocomplain \$\{__meas_dir\}/\$cell*.o-\$output.i-\$input.s-\$scnt.*mt0*\] 0\]"
  puts $fout "            if \{(\$file eq \"\")\} \{"
  puts $fout "                puts \"Error: \$\{__meas_dir\}/\$cell*.o-\$output.i-\$input.s-\$scnt.*mt0* not found\""
  puts $fout "                break"
  puts $fout "            \} else \{"
  puts $fout "            if \{ \[array size sigdata\] \} \{"
  puts $fout "               array unset sigdata"
  puts $fout "            \}"
  puts $fout "            read_measure_data_to_array -dataarray sigdata -meas \$\{__meas_dir\}/\$cell*.o-\$output.i-\$input.s-\$scnt.m-*.mt0* $rmd"
  if { ($cargs(-ref_spice_model) ne "") || ($cargs(-ref_spice_lib) ne "") } {
  puts $fout "            if \{ \[array size refsigdata\] \} \{"
  puts $fout "               array unset refsigdata"
  puts $fout "            \}"
  puts $fout "            read_measure_data_to_array -dataarray refsigdata -meas \$\{__meas_dir\}/\$cell*.o-\$output.i-\$input.s-\$scnt.*ref*.mt0* $rmd"
  puts $fout "            if \{ \[array size refsigdata\] \} \{"
  puts $fout "		  generate_slewdelay_variation_from_array -dataarray sigdata -resultsarray resdata -xcel \$\{__meas_dir\}/${cell}.o-\$output.i-\$input.s-\$\{scnt\}.\$ext.csv $gsd -add_slew_var"
  puts $fout "           \} else \{"
  puts $fout "		  generate_slewdelay_variation_from_array -dataarray sigdata -resultsarray resdata -xcel \$\{__meas_dir\}/\${cell}.o-\$output.i-\$input.s-\$\{scnt\}.\$ext.csv $gsd -add_slew_var"
  puts $fout "           \}"
  puts $fout "            # end of refsigdata"
  } else {
  puts $fout "		  generate_slewdelay_variation_from_array -dataarray sigdata -resultsarray resdata -xcel \$\{__meas_dir\}/\${cell}.o-\$output.i-\$input.s-\$\{scnt\}.\$ext.csv $gsd -add_slew_var"
  }
  puts $fout "        \}"
  puts $fout "           # end of elseif sigdata"
  puts $fout "        \}"
  puts $fout "        # end of else cellarray sensitize"
   } else {
  puts $fout "         set file \[lindex \[glob -nocomplain \$\{__meas_dir\}/\$cell*.o-\$output.i-\$input.s-\$scnt.*mt0*\] 0\]"
  puts $fout "         if \{(\$file eq \"\")\} \{"
  puts $fout "             puts \"Error: \$\{__meas_dir\}/\$cell*.o-\$output.i-\$input.s-\$scnt.*mt0* not found\""
  puts $fout "                break"
  puts $fout "         \} else \{"
  puts $fout "         if \{ \[array size sigdata\] \} \{"
  puts $fout "            array unset sigdata"
  puts $fout "         \}"
  puts $fout "         read_measure_data_to_array -dataarray sigdata -meas \$\{__meas_dir\}/\$cell*.o-\$output.i-\$input.s-\$scnt.m-*.mt0* $rmd"
   if { ($cargs(-ref_spice_model) ne "") || ($cargs(-ref_spice_lib) ne "") } {
  puts $fout "         if \{ \[array size refsigdata\] \} \{"
  puts $fout "            array unset refsigdata"
  puts $fout "         \}"
  puts $fout "         read_measure_data_to_array -dataarray refsigdata -meas \$\{__meas_dir\}/\$cell*.o-\$output.i-\$input.s-\$scnt.*ref.mt0* $rmd"
  puts $fout "         if \{ \[array size refsigdata\] \} \{"
  puts $fout "		  generate_slewdelay_variation_from_array -dataarray sigdata -resultsarray resdata -xcel \$\{__meas_dir\}/\${cell}.o-\$output.i-\$input.s-\$\{scnt\}.\$ext.csv $gsd -add_slew_var"
  puts $fout "        \} else \{"
  puts $fout "		  generate_slewdelay_variation_from_array -dataarray sigdata -resultsarray resdata -xcel \$\{__meas_dir\}/\${cell}.o-\$output.i-\$input.s-\$\{scnt\}.\$ext.csv $gsd -add_slew_var"
  puts $fout "         \}"
  puts $fout "          # end of refsigdata"
   } else {
  puts $fout "		  generate_slewdelay_variation_from_array -dataarray sigdata -resultsarray resdata -xcel \$\{__meas_dir\}/\${cell}.o-\$output.i-\$input.s-\$\{scnt\}.\$ext.csv $gsd -add_slew_var"
  }
  puts $fout "         \}"
  puts $fout "         # end of elseif"
   }
   puts $fout "      \}"
   puts $fout "      # end of foreach input"
   puts $fout "   \}"
   puts $fout "   # end of foreach output"
   puts $fout "   \}"
   puts $fout "    # end of foreach cell"
   puts $fout "\}"
   puts $fout "# end of foreach cellname"
   close $fout
   exec chmod 777 $cargs(-delay_runscript)
   }
}
define_myproc_attributes write_pocv_runscript \
-info "write the runscript for pocv generation" \
-define_args { \
  {-cell "name of cell" string string_list required}
  {-drive_cell "name of cell to predrive cell under test" string string_list optional}
  {-array_name "name of hash for cell data array" string string optional}
  {-db "name of cell DB file" string string_list optional}
  {-lib "name of cell .lib file" string string_list optional}
  {-scripts_dir "dir of aocv scripts(def .)" string string_list optional}
  {-table_runscript "name of runscript for generating aocv tables" string string optional}
  {-aocv_runscript "name of runscript for setting aocv generation" string string optional}
  {-hsp_runscript "name of runscript for running hspice" string string optional}
  {-nt_runscript "name of runscript for running NT" string string optional}
  {-nt_coeff_runscript "name of runscript for generation NT coeff" string string optional}
  {-nt_coeff_file "name of file to save calculated NT variation coefficients" string string optional}
  {-nt_coeff_append "append to end of NT coefficients file:" "" boolean optional}
  {-nt_coeff_max_logic_depth "max_logic_depth to generate NT coefficients from" "int" int optional}
  {-nt_coeff_nmos "name of nmos model)(def nch_mac)" "string" string optional}
  {-nt_coeff_nmos_length "length of nmos model)(.016um)" "float" float optional}
  {-nt_coeff_nmos_width "width of nmos model)(no default)" "float" float optional}
  {-nt_coeff_nmos_nfin "nfin of nmos model)(no default)" "float" float optional}
  {-nt_coeff_nmos_nf "nf of nmos model)(def. 1)" "int" int optional}
  {-nt_coeff_pmos "name of pmos model)(def pch_mac)" "string" string optional}
  {-nt_coeff_pmos_length "length of pmos model)(.016um)" "float" float optional}
  {-nt_coeff_pmos_width "width of pmos model)(no default)" "float" float optional}
  {-nt_coeff_pmos_nfin "nfin of pmos model)(no default)" "float" float optional}
  {-nt_coeff_pmos_nf "nf of pmos model)(def. 1)" "int" int optional}
  {-sigma_mode "sigma mode(avg,best,worst,depth)" "string" string optional}
  {-mean_mode "mean mode(avg,best,worst,depth)" "string" string optional}
  {-csv_runscript "name of csv compare runscript" string string optional}
  {-spice_type "spice type(def: hspice)" string string optional}
  {-spice_path "path to spice exe" string string optional}
  {-spice_file "file naming convention for cells/multi-cells/design chains" string string optional}
  {-nt_spice_file "file naming convention for cells/multi-cells/design chains" string string optional}
  {-nt_tcl_script "nt tcl script to load into NT" string string optional}
  {-submit "batch submit script and options" string string optional}
  {-nt_submit "batch submit script and options" string string optional}
  {-pt_submit "batch PT submit script and options" string string optional}
  {-force "force runscript to be overwritten if it exists" "" boolean optional}
  {-vars  "use variable for runscripts options" "" boolean optional}
  {-no_batch "do not batch the hspice runs" "" boolean optional}
  {-no_nt_batch "do not batch the NT TX POCV runs" "" boolean optional}
  {-pocv_dir "aocv dir of aocv file(def .)" string string optional}
  {-nt_coeff_file "NT variation coefficient file" string string optional}
  {-meas_dir "meas dir of hspice file(def .)" string string optional}
  {-stage_fanout "stage fanout(def 1)" int int optional}
  {-spice_cells "extracted spice cell file(s)" string string_list optional}
  {-spice_cells_dir "extracted spice cell file(s) directory" string string_list optional}
  {-spice_model "spice cell model file(s)" string string_list optional}
  {-ref_spice_model "reference spice cell model file(s)" string string_list optional}
  {-spice_lib "spice cell model lib(s)"  string string_list optional}
  {-ref_spice_lib "reference spice cell model lib(s)" string string_list optional}
  {-spice_output "spice output file(s)" string string optional}
  {-spice_ext "spice file name extension" string string optional}
  {-tcl_ext "tcl file name extension" string string optional}
  {-csv_ext "csv file name extension" string string optional}
  {-paths_ext "paths file name extension" string string optional}
  {-input "input pin of cell being used" string string_list optional}
  {-mis_input "mis input pins of cell" string string_list optional}
  {-all_inputs "run all input pins of cell being used" "" boolean optional}
  {-all_outputs "run all output pins of cell being used" "" boolean optional}
  {-all_sensitizations "run all sensitizations of input->output arc of cell being used" "" boolean optional}
  {-output "output pin of cell being used" string string_list optional}
  {-comp_output "comp output pin of cell being used" string string_list optional}
  {-ic "list of ic for cell port=value" string string_list optional}
  {-supply "supply value on ports of cell port=value" string string_list optional}
  {-no_supply_source "no printing supply source in spice decks" "" boolean optional}
  {-sensitization_data "list of sensitization for input->output port=value" string string_list optional}
  {-port_list "list of ports of cell" string string_list optional}
  {-stage_fanout "stage fanout(def 1)" int int optional}
  {-max_logic_depth "max logic depth(def 15)" int int optional}
  {-max_read_logic_depth "max read logic depth(def -max_logic_depth)" int int optional}
  {-spice_logic_depth "spice logic depth(def 4)" int int optional}
  {-meas_depth_list "list of depths to measure at(def. is every level)" string string_list optional}
  {-max_fanin_trans "max transition of input waveform(def )" float float optional}
  {-max_fanin_trans_fall "max fall transition of input waveform(def )" float float optional}
  {-max_fanout_cap "use max cap per fanout load" float float optional}
  {-max_fanout_cap_pct "percentage of max cap per fanout load" float float_list optional}
  {-predrvr_max_fanout_cap_pct "percentage of predrvr max cap per fanout load" float float_list optional}
  {-fanout_cap_mode "fanout cap mode" string string optional}
  {-fanin_trans_mode "fanin trans mode" string string optional}
  {-max_fanin_trans_pct "percentage of max transition of fanin" float float optional}
  {-monte "number of monte carlo samples(def. 2000)" int int optional}
  {-monte_split "number of monte carlo samples split per file(def 400)" int int optional}
  {-temp "temperature of PVT" float float optional}
  {-vdd "voltage of PVT(or use -supply)" float float_list optional}
  {-period "period of input waveform(def 4ns)" float float optional}
  {-high_pulse "time of high pulse of input waveform(def 2ns)" float float optional}
  {-cycles "number of cycles of input waveform(def 2)" int int optional}
  {-tran_start "start time of input waveform(def 1ns)" float float optional}
  {-accurate ".option accurate in SPICE" "" boolean optional}
  {-spice_options ".option cmds for SPICE" string string_list optional}
  {-tran_step "transient time step for SPICE(def .001ns)" float float optional}
  {-tran_stop "transient stop time for SPICE(def period * (cycles + .5)" float float optional}
  {-upper_slew "upper slew measurement fraction(def .9)" float float optional}
  {-lower_slew "lower slew measurement fraction(def .1)" float float optional}
  {-delay_meas "delay meas measurement fraction(def .5)" float float optional}
  {-meas_from_cross "starting level meas edge of input waveform(def 1)" float float optional}
  {-meas_to_cross "starting meas edge at each level(def 1)" float float optional}
  {-meas_from_cross_rf_incr "next rf meas edge of input waveform(def 1)" float float optional}
  {-meas_to_cross_rf_incr "next rf meas edge  at each level(def 1)" float float optional}
  {-meas_from_cross_rf_mult "next rf meas edge multiplier of input waveform(def 0)" int int optional}
  {-meas_from_cross_rf_exp "next rf meas edge exponential of input waveform(def 0)" int int  optional}
  {-meas_from_cross_rf_exp_mult "multiplier for next rf meas edge exponential of input waveform(def 0)" int int  optional}
  {-meas_from_cross_level_mult "next logic depth level meas edge multiplier input waveform(def 0)" int int optional}
  {-meas_from_cross_level_exp "next logic depth level meas edge exponential input waveform(def 0)" int int optional}
  {-meas_from_cross_level_exp_mult "multipler for next logic depth level meas edge exponential input waveform(def 0)" int int optional}
  {-rccap "rc cap(def 1.0ff)" float float optional}
  {-rcres "rc res(def 10ohms)" float float optional}
  {-rcseg "rc seg res-cap-res(def 1)" float float optional}
  {-cell_chain_mode "mode of cell chain(def. same_cell)" string string optional}
  {-variation_mode "tx variation mode(def. all_tx)" string string optional}
  {-inc_temp "incl .temp to spice deck" "" boolean optional}
  {-inc_spice_cells "incl extracted spice cells" "" boolean optional}
  {-local_params "local_params monte carlo samplings: param=aguass(nom,abs_var,sigma)" string string_list optional}
  {-global_params "global_params monte carlo samplings: param=aguass(nom,abs_var,sigma)" string string_list optional}
  {-time_unit "time_unit(def db/lib/NS)" string string optional}
  {-cap_unit "cap_unit(def PF)" string string optional}
  {-nmos_only "local mismatch only on nmos" "" boolean optional}
  {-pmos_only "local mismatch only on pmos" "" boolean optional}
  {-disable_local_params "params to disable local mismatch" string string_list optional}
  {-no_predrvr_load "no predriver loading" "" boolean optional}
  {-no_predrvr_variation "no predriver variation" "" boolean optional}
  {-add_predrvr_cnt "number of pre driver cells(def. 10" "int" int optional}
  {-disable_predrvr_local_params "local variation disable param for predriver" string string optional}
  {-qlo "Low quantile value (between 0 and 1)" float float optional}
  {-qhi "High quantile value (between 0 and 1)" float float optional}
  {-del_meas_var "delay measurement variable prefix" string string optional}
  {-rf_meas_var "rf measurement variable prefix" string string optional}
  {-rf_sep "_\\\[12\\\]" string string optional}
  {-sig_digits "sig digits for data" int int optional}
  {-append "append to existing file" "" boolean optional}
  {-no_curve_fit "do not try to auto curve fit" "" boolean optional}
  {-force_pessimistic_monotonic "force derate to be pessimistically monotonic" "" boolean optional}
  {-cell_chain_mode "cell_chain_mode of cells(def. same_cell)" string string optional}
  {-sqrtN  "enable sqrtN mode" "" boolean optional}
  {-sqrtN_mean_mode "mean calculation mode for sqrtN(first,last,avg,min,max def: last)" string string optional}
  {-sqrtN_vardiff_mode "variation difference calculation mode for sqrtN(first,last,avg,min,max def: last)" string string optional}
  {-min_early_derate "minimum derate allowed for early derate" float float optional}
  {-max_early_derate "maximum derate allowed for early derate" float float optional}
  {-min_late_derate "minimum derate allowed for late derate" float float optional}
  {-max_late_derate "maximum derate allowed for late derate" float float optional }
  {-early_margin_pct "additional pct margin to add to early derate tables" float float optional}
  {-late_margin_pct "additional pct margin to add to late derate tables" float float optional}
  {-min_value "minimum value allowed for data" float float optional}
  {-max_value "maximum value allowed for data" float float optional}
  {-vdd "vdd value used in generating derate table" float float optional}
  {-path_type "path_type used for applying derate table" string string hidden}
  {-depth_scale "scale the depth index(default 1.0)" float float optional}
  {-meas_td "time delay before beginning measurements" string string optional}
  {-meas_from_edge "specific from measurement edge(rise|fall) def:(cross)" string string optional}
  {-stat_file "read_measure data stats file" string string optional}
  {-path_ordered "print delay variation path_ordered(def: edge_ordered)" "" boolean optional}
  {-debug "print some debug messages" "" boolean optional}
  {-vss "vss supply voltage(default: 0.0)" float float optional}
  {-nt "write out NT spice deck and tcl file for validation of NT TX POCV" "" boolean optional}
}
echo "Defined procedure 'write_pocv_runscript'."

### generate hspice runscript for batch running hspice monte-carlo 
proc write_nt_runscript { args } {
  global __date
  set cargs(-cell) "all"
  set cargs(-meas_dir) "./"
  set cargs(-nt_spice_file) "*o-*.i-*.*.NT.*.sp"
  set cargs(-runscript) "run_ntpocv"
  set cargs(-nt_path) ""
  set cargs(-nt_type) "nt_shell"
  set cargs(-force) 0
  set cargs(-no_nt_batch) 0
  set pwd [pwd]
  set pwd [string trim $pwd]
  set cargs(-nt_submit) ""


  if { [parse_myproc_arguments -args $args cargs] eq "0" } {
  	return 0
  }

   
  if { $cargs(-nt_type) ne "" } {
    set cargs(-nt_type) [join $cargs(-nt_type) " "]
  }
    #regsub -all "^\[ \t\]*\[\" \]+" $cargs(-submit) {} cargs(-submit)
  if { $cargs(-nt_submit) ne "" } {
    set cargs(-nt_submit) [join $cargs(-nt_submit) " "]
    #regsub "^\[ \t\]*\[\" \]+" $cargs(-submit) {} cargs(-submit)
    #regsub "\[\" \]+\[ \t\]*$" $cargs(-submit) {} cargs(-submit)
    #regsub "^\[ \t\]*\[\{ \]+" $cargs(-submit) {} cargs(-submit)
    #regsub "\[\} \]+\[ \t\]*$" $cargs(-submit) {} cargs(-submit)
  }

  if { ![regexp "^\[ \]*\/" $cargs(-meas_dir)] } {
	set cargs(-meas_dir) "$pwd\/$cargs(-meas_dir)"
  }

  if {! [file exists "$cargs(-runscript)"] || $cargs(-force) } {
    puts "Writing runscript: $cargs(-runscript)"
    set fnt [open $cargs(-runscript) w]
    puts $fnt "#!/bin/sh"
    puts $fnt "# the next line restarts using tclsh \\"
    puts $fnt "exec tclsh \"\$0\" \"$@\""
    puts $fnt "# $__date"
    puts $fnt "# script generated by create_pocv_setup to run NT on aocv spice decks"
    puts $fnt "cd $cargs(-meas_dir)"
    puts $fnt "set files \[glob -nocomplain \"$cargs(-nt_spice_file)\"\]"
    puts $fnt "foreach file \$files  \{"
    puts $fnt "   regexp \"^\\\[ \\t\\\]*(\\\[^ \\t\\\]+.NT\\\[^ \\t\\\]+).sp\\s*\$\" \$file dum base"
    puts $fnt "   set csv \"\""
    puts $fnt "   set sp \[file mtime \$file\]"
    puts $fnt "   if \{\[file exists \"\$\{base\}.csv\"\]\} \{"
    puts $fnt "        set csv \[file mtime \$\{base\}.csv\]"
    puts $fnt "   \} elseif \{\[file exists \"\$\{base\}.csv.gz\"\]\} \{"
    puts $fnt "        set csv \[file mtime \$\{base\}.csv.gz\]"
    puts $fnt "   \}"
    puts $fnt "   if \{(\[string compare \$csv \"\"\] == 0) || (\$sp > \$csv )\} \{"
    if {!$cargs(-no_nt_batch)} {
      puts $fnt "   set fnt \[open  \"__runnt_\$\{base\}\" w\]"
      puts $fnt "   puts \$fnt \"#\!/bin/csh -f\""
      if {[string compare $cargs(-nt_path) ""] != 0} {
        puts $fnt "   puts \$fnt \"$cargs(-nt_path)/$cargs(-nt_type) -f \$\{base\}.tcl\""
      } else {
        puts $fnt "   puts \$fnt \"$cargs(-nt_type) -f \$\{base\}.tcl\""
      }
      puts $fnt "   puts \$fnt \"exec gzip -f \$\{base\}.log \$\{base\}.csv\""
      puts $fnt "   puts \$fnt \"exec rm genie* nt_shell*\""
      puts $fnt "   close \$fnt"
      puts $fnt "   catch \{exec chmod 777 __runnt_\$\{base\}\}"
      puts $fnt "   catch \{exec rm \$\{base\}.csv\}"
      puts $fnt "   puts \"Submitting NT runscript __runnt_\$\{base\}\""
      if { $cargs(-nt_submit) ne "" } {
      puts $fnt "   set errorvar \"\""
      puts $fnt "   catch \{exec [join $cargs(-nt_submit)] __runnt_\$\{base\} errorvar\}"
      puts $fnt "   puts \$errorvar"
      } else {
      puts $fnt "   catch \{exec __runnt_\$\{base\}\} errorvar"
      puts $fnt "   puts \$errorvar"
      }
    } else {
      puts $fnt "  puts \"Running nt_shell on \$\{base\}.tcl\""
      if {[string compare $cargs(-nt_path) ""] != 0} {
        puts $fnt "catch \{exec $cargs(-nt_path)/$cargs(-nt_type) -f \$\{base\}.tcl\}"
      } else {
        puts $fnt "catch \{exec $cargs(-nt_type) -f \$\{base\}.tcl\}"
      }
      puts $fnt "  puts \"Completed Running nt_shell on \$\{base\}.tcl\""
      puts $fnt "catch \{exec gzip -f \$\{base\}.log \$\{base\}.csv\}"
      puts $fnt "catch \{exec rm genie* nt_shell*\}"
    }
    puts $fnt "   \} else \{"
    puts $fnt "      puts \"   \$\{base\}.csv is up-to-date\""
    puts $fnt "   \}"
    puts $fnt "\}"
    close $fnt
    exec chmod 777 $cargs(-runscript)
    puts "Done writing runscript: $cargs(-runscript)"
  }
}
define_myproc_attributes write_nt_runscript \
-info "write the runscript for NT TX POCV " \
-define_args { \
  {-runscript "name of runscript for running NT" string string optional}
  {-cell "name of cell for runscript" string string optional}
  {-nt_type "spice type(def:nt_shell)" string string optional}
  {-nt_path "path to nt_shell exe" string string optional}
  {-nt_spice_file "file naming convention for cells/multi-cells/design chains" string string optional}
  {-meas_dir  "path to meas/working directory" string string optional}
  {-nt_submit "batch submit script and options" string string optional}
  {-force "force runscript to be overwritten if it exists" "" boolean optional}
  {-no_nt_batch "do not batch the NT runs" "" boolean optional}
}
echo "Defined procedure 'write_nt_runscript'."

### generate hspice runscript for batch running hspice monte-carlo 
proc write_ntpocv_tcl { args } {
  set cargs(-debug) 0
  set cargs(-sig_digits) 5
  set cargs(-add_predrvr_cnt) 0
  set cargs(-ref_spice_model) ""
  set cargs(-ref_spice_lib) ""
  set cargs(-spice_cells) ""
  set cargs(-spice_cells_dir) "."
  set cargs(-spice_model) ""
  set cargs(-spice_lib) ""
  set cargs(-spice_output) ""
  set cargs(-spice_ext) "POCV.sp"
  set cargs(-array_name) ""
  set cargs(-cell) ""
  set cargs(-pocv_dir) "."
  set cargs(-nt_coeff_file) ""
  set cargs(-meas_dir) "."
  set cargs(-max_logic_depth) 15
  set cargs(-port_list) ""
  set cargs(-supply) ""
  set cargs(-no_supply_source) 0
  set cargs(-period) 4.0
  set cargs(-cycles) 2
  set cargs(-high_pulse) ""
  set cargs(-tran_start) 1.0
  set cargs(-upper_slew) ""
  set cargs(-lower_slew) ""
  set cargs(-delay_meas) ""
  set cargs(-inc_spice_cells)  0
  set cargs(-time_unit) ""
  set cargs(-cap_unit) "FF"
  set cargs(-debug) 0
  set cargs(-spice_file) ""
  set cargs(-spice_ext) "POCV.sp"
  set cargs(-tcl_ext) "NT.POCV.tcl"
  set cargs(-csv_ext) "NT.POCV.csv"
  set cargs(-paths_ext) "NT.POCV.paths"
  set cargs(-tcl) ""
  set cargs(-input) ""
  set cargs(-output) ""
  set cargs(-nt_tcl_script) ""
  set cargs(-fanin_trans_mode) "max_fanin_trans_pct"
  set cargs(-max_fanin_trans_pct) 1

  if { [parse_myproc_arguments -args $args cargs] eq "0" } {
  	return 0
  }


  if {[string compare $cargs(-array_name) ""] != 0 } {
    upvar 1 $cargs(-array_name) cellarray
  }

  set pwd [pwd]
  set pwd [string trim $pwd]

  if { ![regexp "^\[ \]*\/" $cargs(-meas_dir)] } {
        set cargs(-meas_dir) "$pwd\/$cargs(-meas_dir)"
  }

  if { ![file isdirectory $cargs(-meas_dir)] } {
    exec mkdir $cargs(-meas_dir)
  }
  if { ![regexp "^\[ \]*\/" $cargs(-tcl)] } {
    set cargs(-tcl) "$cargs(-meas_dir)/$cargs(-tcl)"
  }

    set cell $cargs(-cell)
    if { ($cargs(-ref_spice_model) ne "") || ($cargs(-ref_spice_lib) ne "") } {
    set FOUT [open "$cargs(-tcl).ref.$cargs(-tcl_ext)" w]
    puts "Writing NT TX POCV TCL($cargs(-tcl).ref.$cargs(-tcl_ext)) for SPICE deck: $cargs(-spice_file).ref.$cargs(-spice_ext) for cell: $cargs(-cell)"
    } else {
    set FOUT [open "$cargs(-tcl).$cargs(-tcl_ext)" w]
    puts "Writing NT TX POCV TCL($cargs(-tcl).$cargs(-tcl_ext)) for SPICE deck: $cargs(-spice_file).$cargs(-spice_ext) for cell: $cargs(-cell)"
    }
    puts $FOUT "#"

  if { $cargs(-nt_tcl_script) ne "" } {
	puts $FOUT "source -echo $cargs(-nt_tcl_script)"
  }

  if { ![regexp "^\[ \]*\/" $cargs(-meas_dir)] } {
	set cargs(-meas_dir) "$pwd\/$cargs(-meas_dir)"
  }

  array unset inputs 
  array unset outputs

  puts $FOUT "set link_case lower"
  
  ## determine cap units
  if {[defined -nocase cellarray(capacitance_load_unit)] && ($cellarray(capacitance_load_unit) eq "1e-12") } {
    puts $FOUT "set lib_capacitance_unit 1pf"
  } else {
    puts $FOUT "set lib_capacitance_unit 1ff"
  }	
## determine time units
  if {($cargs(-time_unit) eq "") && [info exists cellarray(time_unit)] && ($cellarray(time_unit) eq "1e-12") } {
    puts $FOUT "set lib_time_unit 1ps"
    set cargs(-time_unit) "PS"
  } elseif {($cargs(-time_unit) eq "") && [info exists cellarray(time_unit)] && (($cellarray(time_unit) eq "1e-9") || ($cellarray(time_unit) eq "1e-09")) } {
    set cargs(-time_unit) "NS"
  } elseif { $cargs(-time_unit) eq "" } {
    set cargs(-time_unit) "NS"
        puts "Warning: -time_unit not set defaulting to NS"
  } elseif { [string tolower $cargs(-time_unit)] eq "ps" } {
    puts $FOUT "set lib_time_unit 1ps"
  }
	

    if {([string tolower $cargs(-time_unit)] eq "ns") && $cargs(-period) > 300 } {
        puts "Warning: -time_unit == NS but -period > 300 time units, converting -period to NS"
        set cargs(-period) [expr $cargs(-period) / 1000]
    }
    if { ([string tolower $cargs(-time_unit)] eq "ns") && ($cargs(-high_pulse) ne "") && ($cargs(-high_pulse) > 300) } {
        puts "Warning: -time_unit == NS but -high_pulse > 300 time units, converting -high_pulse to NS"
        set cargs(-high_pulse) [expr $cargs(-high_pulse) / 1000]
    }
    if {([string tolower $cargs(-time_unit)] eq "ps") && $cargs(-period) < 300 } {
        puts "Warning: -time_unit == PS but -period < 300 time units, converting -period to PS"
        set cargs(-period) [expr $cargs(-period) * 1000]
    }
    if { ([string tolower $cargs(-time_unit)] eq "ps") && ($cargs(-high_pulse) ne "") && ($cargs(-high_pulse) < 300) } {
        puts "Warning: -time_unit == NS but -high_pulse < 300 time units, converting -high_pulse to PS"
        set cargs(-high_pulse) [expr $cargs(-high_pulse) * 1000]
    }

  puts "   TIME UNIT: $cargs(-time_unit)"


  set pvdd ""
  set vdd ""
  #add cell based support supply(<cellname>) ...
  array set supply {}
  if {$cargs(-supply) ne ""} {
      foreach key1 $cargs(-supply)  {
        while {[regexp "(\[^ \t\]+)\=(\[^ \t\]+)" $key1 dum port value] } {
           set supply([string tolower $port]) $value
          set cellarray(cell,__copt__,supply,[string tolower $port]) $value
        regsub "(\[^ \t\]+)\=(\[^ \t\]+)" $key1 {} key1
          if {($pvdd eq "") && ($value > 0.001)} {
            set pvdd "param_$port"
            set vdd [string tolower $port]
          }
        }
      }
    } elseif { [defined -nocase cellarray(cell,$cell,supply)] } {
      foreach key1 [keys -nocase cellarray(cell,$cell,supply)]  {
          set supply([string tolower $key1]) $cellarray(cell,$cell,supply,$key1)
        if {($pvdd eq "") && ($supply([string tolower $key1]) > 0.001)} {
          set pvdd "param_$key1"
          set vdd [string tolower $key1]
        }
      }
    } elseif { [defined -nocase cellarray(cell,-,supply)] } {
      foreach key1 [keys -nocase cellarray(cell,-,supply)]  {
          set supply([string tolower $key1]) $cellarray(cell,-,supply,$key1)
        if {($pvdd eq "") && ($cellarray(cell,-,supply,[string tolower $key1]) > 0.001)} {
          set pvdd "param_$key1"
          set vdd [string tolower $key1]
        }
      }
    }

 if { $cargs(-input) ne "" } {
    while {[regexp "\[ \t\{\]*(\[^ \t\=\:\]*)\[ \t\{\]*\[\:\]\[ \t\{\]*(\[^ \t\=\}\]+)" $cargs(-input) dum mcell key1]} {
    regsub "\[ \t\{\]*(\[^ \t\=\:\]*)\[ \t\{\]*\[\:\]\[ \t\{\]*(\[^ \t\=\}\]+)" $cargs(-input) {} cargs(-input)
    set inputs($mcell) $key1
    }
    if {[regexp "\[ \t\{\]*(\[^ \t\=\}\]+)" $cargs(-input) dum key1]} {
    set inputs(-) $key1
    }
  }
  if { $cargs(-output) ne "" } {
    while {[regexp "\[ \t\{\]*(\[^ \t\=\:\]*)\[ \t\{\]*\[\:\]\[ \t\{\]*(\[^ \t\=\}\]+)" $cargs(-output) dum mcell key1]} {
    regsub "\[ \t\{\]*(\[^ \t\=\:\]*)\[ \t\{\]*\[\:\]\[ \t\{\]*(\[^ \t\=\}\]+)" $cargs(-output) {} cargs(-output)
    set outputs($mcell) $key1
    }
    if {[regexp "\[ \t\{\]*(\[^ \t\=\}\]+)" $cargs(-output) dum key1]} {
    set outputs(-) $key1
    }
  }

#  change this to input(cellname)
  if { [defined -nocase inputs($cell)] } {
    set input $inputs($cell)
  } elseif { [defined -nocase inputs(-)] } {
    set input $inputs(-)
  } elseif { [defined -nocase cellarray(cell,$cell,input)] } {
    set input $cellarray(cell,$cell,input)
  } elseif { [defined -nocase cellarray(cell,-,input)] } {
    set input $cellarray(cell,-,input)
  } else {
    die "Error: could not determine input to use of cell: $cell"
  }

  if { [defined -nocase outputs($cell)] } {
    set output $outputs($cell)
  } elseif { [defined -nocase outputs(-)] } {
    set output $outputs(-)
  } elseif { [defined -nocase cellarray(cell,$cell,output)] } {
    set output $cellarray(cell,$cell,output)
  } elseif { [defined -nocase cellarray(cell,-,output)] } {
    set output $cellarray(cell,-,output)
  } else {
    die "Error: could not determine output to use of cell: $cell"
  }


  ## get the user thresholds
  if {$cargs(-lower_slew) ne ""} {
    set cellarray(cell,__copt__,lower_slew) $cargs(-lower_slew)
  }
  if {$cargs(-upper_slew) ne ""} {
    set cellarray(cell,__copt__,upper_slew) $cargs(-upper_slew)
  }
  if {$cargs(-delay_meas) ne ""} {
    set cellarray(cell,__copt__,delay_slew) $cargs(-delay_meas)
  }

  if { [defined -nocase cellarray(cell,__copt__,pin,lower_slew)]} {
    set lower_slew $cellarray(cell,__copt__,pin,$input,lower_slew)
  } elseif { [defined -nocase cellarray(cell,$cell,pin,$input,rc_slew_lower_threshold_pct_rise)]} {
    set lower_slew $cellarray(cell,$cell,pin,$input,rc_slew_lower_threshold_pct_rise)
  } elseif { [defined -nocase cellarray(cell,-,lower_slew)]} {
    set lower_slew $cellarray(cell,-,lower_slew)
  } elseif { [defined -nocase cellarray(slew_lower_threshold_pct_rise)]} {
    set lower_slew $cellarray(slew_lower_threshold_pct_rise)
  } else {
    set lower_slew 20
  }

  ## get the upper_slew threshold
  if { [defined -nocase cellarray(cell,__copt__,upper_slew)]} {
    set upper_slew $cellarray(cell,__copt__,upper_slew)
  } elseif { [defined -nocase cellarray(cell,$cell,pin,$input,rc_slew_upper_threshold_pct_rise)]} {
    set upper_slew $cellarray(cell,$cell,pin,$input,rc_slew_upper_threshold_pct_rise)
  } elseif { [defined -nocase cellarray(cell,-,upper_slew)]} {
    set upper_slew $cellarray(cell,-,upper_slew)
  } elseif { [defined -nocase cellarray(slew_upper_threshold_pct_rise)]} {
    set upper_slew $cellarray(slew_upper_threshold_pct_rise)
  } else {
    set upper_slew 80
  }


  ## get the delay measure thresh
  if { [defined -nocase cellarray(cell,__copt__,delay_meas)]} {
    set delay_meas $cellarray(cell,__copt__,delay_meas)
  } elseif { [defined -nocase cellarray(cell,$cell,pin,$input,rc_input_threshold_pct_rise)]} {
    set delay_meas $cellarray(cell,$cell,pin,$input,rc_input_threshold_pct_rise)
  } elseif { [defined -nocase cellarray(cell,-,delay_meas)]} {
    set delay_meas $cellarray(cell,-,delay_meas)
  } elseif { [defined -nocase cellarray(input_threshold_pct_rise)]} {
    set delay_meas $cellarray(input_threshold_pct_rise)
  } else {
    set delay_meas 50
  }


  if { $lower_slew > 1 } {
    set lower_slew [expr $lower_slew / 100.0]
  }
  if { $upper_slew > 1 } {
    set upper_slew [expr $upper_slew / 100.0]
  }
  if { $delay_meas > 1 } {
    set delay_meas [expr $delay_meas / 100.0]
  }


  # calculate initial rise/fall time if one not given
    if {[defined -nocase cellarray(cell,__copt__,max_transition)] } {
      set max_trans $cellarray(cell,__copt__,max_transition)
    } elseif {[defined -nocase cellarray(cell,$cell,pin,$input,max_transition)] } {
      set max_trans $cellarray(cell,$cell,pin,$input,max_transition)
    } elseif {[defined -nocase cellarray(cell,-,max_transition)] } {
      set max_trans $cellarray(cell,-,max_transition)
    } else {
      set max_trans .1
    }

    #get max trans for cell hash
    if {[defined -nocase cellarray(cell,__copt__,max_fall_transition)] } {
      set max_trans_fall $cellarray(cell,__copt__,max_fall_transition)
    } elseif {[defined -nocase cellarray(cell,__copt__,max_transition)] } {
      set max_trans_fall $cellarray(cell,__copt__,max_transition)
    } elseif {[defined -nocase cellarray(cell,$cell,pin,$input,max_fall_transition)] } {
      set max_trans_fall $cellarray(cell,$cell,pin,$input,max_fall_transition)
    } elseif {[defined -nocase cellarray(cell,$cell,pin,$input,max_transition)] } {
      set max_trans_fall $cellarray(cell,$cell,pin,$input,max_transition)
    } elseif {[defined -nocase cellarray(cell,-,max_fall_transition)] } {
      set max_trans_fall $cellarray(cell,-,max_fall_transition)
    } elseif {[defined -nocase cellarray(cell,-,max_transition)] } {
      set max_trans_fall $cellarray(cell,-,max_transition)
    } else {
      set max_trans_fall .1
    }


  if { ([string tolower $cargs(-time_unit)] eq "ps") && ($max_trans < 1) } {
        puts "Warning:  converting max_trans to PS"
        set max_trans [expr $max_trans * 1000]
  } elseif { ([string tolower $cargs(-time_unit)] eq "ns") && ($max_trans > 1) } {
        puts "Warning:  converting max_trans to NS"
        set max_trans [expr $max_trans / 1000]
  }
  if { ([string tolower $cargs(-time_unit)] eq "ps") && ($max_trans_fall < 1) } {
        puts "Warning:  converting max_trans_fall to PS"
        set max_trans_fall [expr $max_trans_fall * 1000]
  } elseif { ([string tolower $cargs(-time_unit)] eq "ns") && ($max_trans_fall > 1) } {
        puts "Warning:  converting max_trans_fall to NS"
        set max_trans_fall [expr $max_trans_fall / 1000]
  }


  if { $cargs(-fanin_trans_mode) eq "max_fanin_trans_pct"} {
    set max_trans [expr $max_trans * $cargs(-max_fanin_trans_pct)]
    set max_trans_fall [expr $max_trans_fall * $cargs(-max_fanin_trans_pct)]
  if { $cargs(-debug) } {
    puts "   SCALED_MAX_TRANS_RISE: $max_trans for cell: $cell"
    puts "   SCALED_MAX_TRANS_FALL: $max_trans_fall for cell: $cell"
  }
  }


#### find appropriate max_trans and max_trans_fall
  ##          check to make sure max trans does not exceed the max_trans of the cell
  if {[defined -nocase cellarray(cell,$cell,pin,$input,max_transition)] } {
    if { $max_trans > $cellarray(cell,$cell,pin,$input,max_transition) } {
      puts "Error: $max_trans > maximum transition: $cellarray(cell,$cell,pin,$input,max_transition) allowed on pin: $input of cell $cell"
      exit
    }
    if { $max_trans_fall > $cellarray(cell,$cell,pin,$input,max_transition) } {
      puts "Error: $max_trans_fall > maximum transition: $cellarray(cell,$cell,pin,$input,max_transition) allowed on pin: $input of cell $cell"
      exit
    }
  }

  puts $FOUT "set rc_slew_upper_threshold_pct_fall  [expr $upper_slew * 100]"
  puts $FOUT "set rc_slew_upper_threshold_pct_rise  [expr $upper_slew * 100]"

  puts $FOUT "set rc_slew_lower_threshold_pct_fall  [expr $lower_slew * 100]"
  puts $FOUT "set rc_slew_lower_threshold_pct_rise  [expr $lower_slew * 100]"
  
  puts $FOUT "set rc_input_threshold_pct_fall  [expr $delay_meas * 100]"
  puts $FOUT "set rc_input_threshold_pct_rise  [expr $delay_meas * 100]"
  puts $FOUT "set rc_output_threshold_pct_fall  [expr $delay_meas * 100]"
  puts $FOUT "set rc_output_threshold_pct_rise [expr $delay_meas * 100]"

#	puts "MAX : $max_trans MAX_FALL: $max_trans_fall  upper: $upper_slew  lower : $lower_slew"

  set max_trans [expr $max_trans/($upper_slew - $lower_slew)]
  set max_trans_fall [expr $max_trans_fall/($upper_slew - $lower_slew)]
  if { [defined -nocase cellarray(slew_derate_from_library)] } {
    set max_trans [expr $max_trans * $cellarray(slew_derate_from_library)]
    set max_trans_fall [expr $max_trans_fall * $cellarray(slew_derate_from_library)]
  }
 
  if { $cargs(-debug) } {
  puts "   MAX_TRANS_RISE: $max_trans for cell: $cell"
  puts "   MAX_TRANS_FALL: $max_trans_fall for cell: $cell"
  puts "   MAX_TRANS_PCT: $cargs(-max_fanin_trans_pct) for cell: $cell"
  puts "   MAX_TRANS_MODE: $cargs(-fanin_trans_mode) for cell: $cell"
  }


  if { ($cargs(-high_pulse) eq "") } {
        if {[expr ($cargs(-period) - $max_trans - $max_trans_fall )/2]  < 0 } {
    puts "Error: -period $cargs(-period) is too small for Scaled Trans Rise: $max_trans Scaled Trans Fall: $max_trans_fall"
    exit
        }
  } elseif { [expr ($cargs(-period) - $max_trans - $max_trans_fall )/2]  < $cargs(-high_pulse) } {
    puts "Error: -period $cargs(-period) is too small for High_Pulse: $cargs(-high_pulse) and Scaled Trans Rise: $max_trans Scaled Trans Fall: $max_trans_fall"
    exit
  }
    #### write out the rise/fall/period params
    set  float_format "\%.6f"
    puts $FOUT [format "set start_time  ${float_format}" $cargs(-tran_start)]
    puts $FOUT [format "set period  ${float_format}" $cargs(-period)]
    puts $FOUT [format "set rise_time  ${float_format}" $max_trans]
    puts $FOUT [format "set fall_time  ${float_format}" $max_trans_fall]
    if { $cargs(-high_pulse) eq "" } {
    puts $FOUT [format "set high_pulse  \[expr (\$period - \$rise_time - \$fall_time ) / 2\]"]
    } else {
    puts $FOUT [format "set high_pulse  ${float_format}" $cargs(-high_pulse)]
    }

    ### write out supplies
   if { $cargs(-no_supply_source) } {
   foreach key1 [array names supply] {
      if { $supply($key1) > .001 } {
	    puts $FOUT "append link_vdd_alias \" ${key1}\""
      } else {
	    puts $FOUT "append link_gnd_alias \" ${key1}\""
      }
   }
   } else {
   foreach key1 [array names supply] {
      if { $supply($key1) > .001 } {
	    puts $FOUT "append link_vdd_alias \" pocv_${key1}\""
      } else {
	    puts $FOUT "append link_gnd_alias \" pocv_${key1}\""
      }
   }
   }

        puts $FOUT "register_netlist -format spice $cargs(-spice_file).$cargs(-spice_ext)"
  if { $cargs(-inc_spice_cells) } {
        foreach key1 [split [regsub -all "\[ \t\]+" [string trim [join $cargs(-spice_cells)]] { }]]  {
          if { ![regexp "^\[ \t\]*\/" $key1] } {
            puts $FOUT "register_netlist -format spice  $cargs(-spice_cells_dir)/$key1"
          } else {
            puts $FOUT "register_netlist -format spice $key1"
          }
        }
  }

   #### include the subckt spice decks
    if { $cargs(-ref_spice_model) ne "" } {
        foreach key1 [split [regsub -all "\[ \t\]+" [string trim [join $cargs(-ref_spice_model)]] { }]]  {
        while { [regexp "^\[ \t\]*{(\[.\]+)}\[ \t\]*$" $key1 key2] } {
                regsub "^\[ \t\]*{(\[.\]+)}\[ \t\]*$" $key1 $key2 key1
        }
        if { ![regexp "^\[ \t\]*\/" $key1] } {
        puts $FOUT "register_netlist -format spice $cargs(-spice_cells_dir)/$key1"
        puts $FOUT "read_spice_models -name TECH $cargs(-spice_cells_dir)/$key1"
        } else {
        puts $FOUT "register_netlist -format spice $key1"
        puts $FOUT "read_spice_models -name TECH $key1"
        }
        }
    } elseif { $cargs(-ref_spice_lib) ne "" } {
        set key1 [string trim $cargs(-ref_spice_lib)]
        if { [regexp "\{\[^\{\}\]+\}" $key1] } {
        while { [regexp "\{(\[^\{\}\]+)\}" $key1 dum key2] } {
                regsub "\{\[^\{\}\]+\}" $key1 {} key1
                puts $FOUT "register_netlist -format spice $key2"
                puts $FOUT "read_spice_models -name TECH  $key2"
        }
        } else {
        foreach key2 $key1 {
                puts $FOUT "register_netlist -format spice $key2"
                puts $FOUT "read_spice_models -name TECH  $key2"
        }
        }

    } elseif { $cargs(-spice_model) ne "" } {
        foreach key1 [split [regsub -all "\[ \t\]+" [string trim [join $cargs(-spice_model)]] { }]]  {
        while { [regexp "^\[ \t\]*{(\[.\]+)}\[ \t\]*$" $key1 key2] } {
                regsub "^\[ \t\]*{(\[.\]+)}\[ \t\]*$" $key1 $key2 key1
        }
         if { ![regexp "^\[ \t\]*\/" $key1] } {
           puts $FOUT "register_netlist -format spice $cargs(-spice_cells_dir)/$key1"
           puts $FOUT "read_spice_model -name TECH $cargs(-spice_cells_dir)/$key1"
         } else {
           puts $FOUT "register_netlist -format spice $key1"
           puts $FOUT "read_spice_model -name TECH $key1"
         }
        }
    } elseif { $cargs(-spice_lib) ne "" } {
        set key1 [string trim $cargs(-spice_lib)]
        if { [regexp "\{\[^\{\}\]+\}" $key1] } {
        while { [regexp "\{(\[^\{\}\]+)\}" $key1 dum key2] } {
                regsub "\{\[^\{\}\]+\}" $key1 {} key1
                puts $FOUT "register_netlist -format spice $key1"
		puts $FOUT "read_spice_model -name TECH $key1"
        }
        } else {
        foreach key2 $key1 {
                puts $FOUT "register_netlist -format spice $key2"
		puts $FOUT "read_spice_model -name TECH $key2"
        }
        }
     }

     puts $FOUT "set si_enable_analysis true"

     puts $FOUT "link_design -keep"
     puts $FOUT "set_technology TECH"
     puts $FOUT "create_clock -name clk  -period \$period  -waveform \"0 \$high_pulse\""
     puts $FOUT "set_propagated_clock clk"

     puts $FOUT "create_port -input \[get_nets in*\]"
     puts $FOUT "set_input_delay -clock clk  0.0  \[get_ports in*\]"


     puts $FOUT "set_input_transition -rise \$rise_time  \[get_ports in*\]"
     puts $FOUT "set_input_transition -fall \$fall_time \[get_ports in*\]"

     puts $FOUT "create_port -output \[get_nets out*\]"
     puts $FOUT "set_output_delay -clock clk  0  \[get_ports out*\]"


     puts $FOUT "match_topology"
     puts $FOUT "set_transistor_direction -to tout* \[get_cells -quiet -of \[get_pins -quiet -leaf -of \[get_net tout*\] -filter \"lib_pin_name == \$link_transistor_source_pin_name \|\| lib_pin_name == \$link_transistor_drain_pin_name\"\]\]"
     puts $FOUT "foreach_in_collection cell \[get_cells -quiet -hier * -filter \"bidirection_related_to_floating_output  \=\= true\"\] \{"
     puts $FOUT "   set_transistor_direction -transistor bidi \$cell"
     puts $FOUT "   echo \"Setting TX direction of cell: \[get_attribute \$cell full_name] to user bidi\""
     puts $FOUT "\}"
     puts $FOUT "check_topology"

     puts $FOUT "set timing_save_pin_arrival_and_transition true"
     puts $FOUT "set trace_through_outputs  true"
     puts $FOUT "set trace_through_inputs  true"
#     puts $FOUT "set sim_cfg_min_rdiff    0"
     puts $FOUT "set sim_cfg_spd          0.01"
#     puts $FOUT "set sim_high_acc        true"
     puts $FOUT "set sim_miller_use_active_load true"
     puts $FOUT "set sim_miller_use_active_load_min true"
     puts $FOUT "set sim_miller_direction_check true"
#     puts $FOUT "set sim_miller_effort_level 1"
     puts $FOUT "set tech_match_length_pct .5"
     puts $FOUT "set tech_match_param_pct .5"
     puts $FOUT "set tech_match_width_pct .5"
     puts $FOUT "set timing_enable_mux_xor_pessimism_removal true"
     puts $FOUT "set trace_disable_switching_net_logic_check true"
     puts $FOUT "set timing_enable_multi_input_switching true"
     puts $FOUT "set timing_extended_sidebranch_analysis_level 2"
     puts $FOUT "set rc_reduction_max_net_delta_delay 0.0005"
     puts $FOUT "set rc_reduction_min_net_delta_delay 0.0005"
     puts $FOUT "set_nonlinear_waveform -samples 21 \[get_nets -hier *\] -mode accurate -threshold 1"
     puts $FOUT "set parasitics_min_capacitance 1e-9"

     puts $FOUT "check_design -complete_with zero"
	if { $cargs(-add_predrvr_cnt) > 0 } {
		puts $FOUT "set_delay_coefficient -delay 0.0 \[get_net in*\]"
		set i 1
		while { $i < $cargs(-add_predrvr_cnt) } {
			puts $FOUT "set_delay_coefficient -delay 0.0 \[get_net out#$i\]"
			incr i
		}
	}
     if { $cargs(-nt_coeff_file) ne "" } {
     puts $FOUT "if \{ \[file exists $cargs(-nt_coeff_file)\] \} \{"
     puts $FOUT "   source $cargs(-nt_coeff_file)"
     puts $FOUT "\}"
     }
     puts $FOUT "#set_variation -min -length 0.016000 -nfin 1 -type pmos -variation 0.06824"
     puts $FOUT "#set_variation -max -length 0.016000 -nfin 1 -type pmos -variation 0.06824"
     puts $FOUT "#set_variation -min -length 0.016000 -nfin 1 -type nmos -variation 0.06824"
     puts $FOUT "#set_variation -max -length 0.016000 -nfin 1 -type nmos -variation 0.06824"
     puts $FOUT "#set_variation -min -length 0.016000 -width .01 -type pmos -variation 0.06824"
     puts $FOUT "#set_variation -max -length 0.016000 -width .01 -type pmos -variation 0.06824"
     puts $FOUT "#set_variation -min -length 0.016000 -width .01 -type nmos -variation 0.06824"
     puts $FOUT "#set_variation -max -length 0.016000 -width .01 -type nmos -variation 0.06824"
     puts $FOUT "report_variation"
     puts $FOUT "set timing_pocv_sigma 3"



     puts $FOUT "trace_paths -pocv"
     puts $FOUT "report_paths -variation -max -max_paths 10 -path_type full_clock -net -trans \> $cargs(-tcl).$cargs(-paths_ext)"
     puts $FOUT "report_paths -variation -min -max_paths 10 -path_type full_clock -net -trans \>\> $cargs(-tcl).$cargs(-paths_ext)"
     puts $FOUT "report_paths_csv -path_ordered -min -file $cargs(-tcl).min.$cargs(-csv_ext)"
     puts $FOUT "report_paths_csv -path_ordered -max -file $cargs(-tcl).max.$cargs(-csv_ext)"
     puts $FOUT "reset_design -paths"
     puts $FOUT "set_model_input_transition_indexes  -rise \"\$rise_time \[expr \$rise_time + .0001\] \[expr \$rise_time + .0002\]\" -nominal \$rise_time \[get_ports *\]"
     puts $FOUT "set_model_input_transition_indexes  -fall \"\$fall_time \[expr \$fall_time + .0001\] \[expr \$fall_time + .0002\]\" -nominal \$fall_time \[get_ports *\]"
     puts $FOUT "extract_model -name $cargs(-tcl) -pocv -debug \{ lib paths \}"
     puts $FOUT "exit"
     close $FOUT
}
define_myproc_attributes write_ntpocv_tcl \
-info "write the NT POCV Tcl script " \
-define_args { \
  {-array_name "name of hash for cell data array" string string optional}
  {-cell "name of cell for validation" string string_list required}
  {-pocv_dir "aocv dir of pocv file(def .)" string string optional}
  {-meas_dir "meas/working dir of hspice file(def .)" string string optional}
  {-spice_cells "extracted spice cell file(s)" string string_list optional}
  {-spice_cells_dir "extracted spice cell file(s) directory" string string_list optional}
  {-spice_model "spice cell model file(s)" string string_list optional}
  {-ref_spice_model "reference spice cell model file(s)" string string_list optional}
  {-spice_lib "spice cell model lib(s)"  string string_list optional}
  {-ref_spice_lib "reference spice cell model lib(s)" string string_list optional}
  {-spice_file "spice file(s)" string string required}
  {-nt_tcl_script "NT TCL script to load into NT run" string string optional} 
  {-tcl "NT POCV TCL output file" string string required}
  {-spice_ext "spice file name extension" string string optional}
  {-tcl_ext "tcl file name extension" string string optional}
  {-csv_ext "csv file name extension" string string optional}
  {-nt_coeff_file "NT variation coeff file" string string optional}
  {-paths_ext "paths file name extension" string string optional}
  {-input "input pin of cell being used" string string_list optional}
  {-output "output pin of cell being used" string string_list optional}
  {-supply "supply value on ports of cell port=value" string string_list optional}
  {-vss "GND supply value on ports of cell" string string_list optional}
  {-port_list "list of ports of cell" string string_list optional}
  {-vdd "voltage of PVT(or use -supply)" float float optional}
  {-period "period of input waveform(def 4ns)" float float optional}
  {-high_pulse "time of high pulse of input waveform(def 2ns)" float float optional}
  {-cycles "number of cycles of input waveform(def 2)" int int optional}
  {-tran_start "start time of input waveform(def 1ns)" float float optional}
  {-upper_slew "upper slew measurement fraction(def .9)" float float optional}
  {-lower_slew "lower slew measurement fraction(def .1)" float float optional}
  {-delay_meas "delay meas measurement fraction(def .5)" float float optional}
  {-inc_spice_cells "incl extracted spice cells" "" boolean optional}
  {-time_unit "time_unit(def NS)" string string optional}
  {-cap_unit "cap_unit(def PF)" string string optional}
  {-add_predrvr_cnt "number of pre driver cells(def. 0)" "int" int optional}
  {-no_predrvr_variation "no predriver variation" "" boolean optional}
  {-sig_digits "number of NT sig digits(def 5)" int int optional}
  {-fanin_trans_mode "fanin trans mode" string string optional}
  {-max_fanin_trans_pct "percentage of max transition of fanin" float float optional}
  {-debug "debug NT Tcl generation" "" boolean optional}
}
echo "Defined procedure 'write_ntpocv_tcl'."
### generate hspice runscript for batch running hspice monte-carlo 
proc write_hsp_runscript { args } {
  global __date
  set cargs(-cell) "all"
  set cargs(-meas_dir) "./"
  set cargs(-spice_file) "*o-*.i-*.*m-*.sp"
  set cargs(-runscript) "run_hsp_aocv"
  set cargs(-spice_path) ""
  set cargs(-spice_type) "hspice"
  set cargs(-force) 0
  set cargs(-no_batch) 0
  set pwd [pwd]
  set pwd [string trim $pwd]
  set cargs(-submit) "qsub -V -P bnormal -cwd -b y -j y -m n -l mem_free=2G,mem_avail=2G,arch=glinux"


  if { [parse_myproc_arguments -args $args cargs] eq "0" } {
  	return 0
  }

   
  if { $cargs(-spice_type) ne "" } {
    set cargs(-spice_type) [join $cargs(-spice_type) " "]
  }
    #regsub -all "^\[ \t\]*\[\" \]+" $cargs(-submit) {} cargs(-submit)
  if { $cargs(-submit) ne "" } {
    set cargs(-submit) [join $cargs(-submit) " "]
    #regsub "^\[ \t\]*\[\" \]+" $cargs(-submit) {} cargs(-submit)
    #regsub "\[\" \]+\[ \t\]*$" $cargs(-submit) {} cargs(-submit)
    #regsub "^\[ \t\]*\[\{ \]+" $cargs(-submit) {} cargs(-submit)
    #regsub "\[\} \]+\[ \t\]*$" $cargs(-submit) {} cargs(-submit)
  }

  if { ![regexp "^\[ \]*\/" $cargs(-meas_dir)] } {
	set cargs(-meas_dir) "$pwd\/$cargs(-meas_dir)"
  }

  if {! [file exists "$cargs(-runscript)"] || $cargs(-force) } {
    puts "Writing runscript: $cargs(-runscript)"
    set fhsp [open $cargs(-runscript) w]
    puts $fhsp "#!/bin/sh"
    puts $fhsp "# the next line restarts using tclsh \\"
    puts $fhsp "exec tclsh \"\$0\" \"$@\""
    puts $fhsp "# $__date"
    puts $fhsp "# script generated by create_pocv_setup to run spice on aocv spice decks"
    puts $fhsp "cd $cargs(-meas_dir)"
    puts $fhsp "set files \[glob -nocomplain \"$cargs(-spice_file)\"\]"
    puts $fhsp "if  \[catch {set jobList \[open job.List \"a\"\]}\] {puts \"Error:  Cannot open job.List for append\n\"}"
    puts $fhsp "foreach file \$files  {"
    puts $fhsp "   regexp \"^\\\[ \\t\\\]*(\\\[^ \\t\\\]+).sp\\s*\$\" \$file dum base"
    puts $fhsp "   set mt0 \"\""
    puts $fhsp "   set sp \[file mtime \$file\]"
    puts $fhsp "   if {\[file exists \"\${base}.mt0\"\]} {"
    puts $fhsp "        set mt0 \[file mtime \${base}.mt0\]"
    puts $fhsp "   } elseif {\[file exists \"\${base}.mt0.gz\"\]} {"
    puts $fhsp "        set mt0 \[file mtime \${base}.mt0.gz\]"
    puts $fhsp "   }"
    puts $fhsp "   if {(\[string compare \$mt0 \"\"\] == 0) || (\$sp > \$mt0 )} {"
    if {!$cargs(-no_batch)} {
      puts $fhsp "   set fhsp \[open  \"__runhsp_\$base\"\ w]"
      puts $fhsp "   puts \$fhsp \"#\!/bin/csh -f\""
      if {[string compare $cargs(-spice_path) ""] != 0} {
        puts $fhsp "   puts \$fhsp \"$cargs(-spice_path)/$cargs(-spice_type) -i \$file -o \$base\""
      } else {
        puts $fhsp "   puts \$fhsp \"$cargs(-spice_type) -i \$file -o \$base\""
      }
      puts $fhsp "   puts \$fhsp \"exec gzip -f \${base}.lis \${base}.mt*\""
      puts $fhsp "   puts \$fhsp \"exec rm \${base}.ic* \${base}.st* \${base}.pa*\""
      puts $fhsp "   close \$fhsp"
      puts $fhsp "   catch \{exec chmod 777 __runhsp_\$base\}"
      puts $fhsp "   catch \{exec rm \${base}.mt*\}"
      puts $fhsp "   puts \"Submitting hspice runscript __runhsp_\$base\""
      if { $cargs(-submit) ne "" } {
      puts $fhsp "   set errorvar \"\""
      puts $fhsp "   set job \[exec [join $cargs(-submit)] __runhsp_\$base errorvar]"
      puts $fhsp "   puts \$jobList \[lindex \[split \$job \" \"\] 2\]"
      puts $fhsp "   puts \$errorvar"
      } else {
      puts $fhsp "   catch \{exec __runhsp_\$base\} errorvar"
      puts $fhsp "   puts \$errorvar"
      }
    } else {
      if {[string compare $cargs(-spice_path) ""] != 0} {
        puts $fhsp "catch \{exec $cargs(-spice_path)/$cargs(-spice_type) -i \$file -o \$base\}"
      } else {
        puts $fhsp "catch \{exec $cargs(-spice_type) -i \$file -o \$base\}"
      }
      puts $fhsp "catch \{exec gzip -f \${base}.lis \${base}.mt*\}"
      puts $fhsp "catch \{exec rm \${base}.ic* \${base}.st* \${base}.pa*\}"
    }
    puts $fhsp "   } else {"
    puts $fhsp "      puts \"   \${base}.mt0 is up-to-date\""
    puts $fhsp "   }"
    puts $fhsp "}"
    puts $fhsp "close \$jobList"
    close $fhsp
    exec chmod 777 $cargs(-runscript)
    puts "Done writing runscript: $cargs(-runscript)"
  }
}
define_myproc_attributes write_hsp_runscript \
-info "write the runscript for hspice " \
-define_args { \
  {-runscript "name of runscript for running hspice" string string optional}
  {-cell "name of cell for runscript" string string optional}
  {-spice_type "spice type(def: hspice)" string string optional}
  {-spice_path "path to spice exe" string string optional}
  {-spice_file "file naming convention for cells/multi-cells/design chains" string string optional}
  {-meas_dir  "path to meas/working directory" string string optional}
  {-submit "batch submit script and options" string string optional}
  {-force "force runscript to be overwritten if it exists" "" boolean optional}
  {-no_batch "do not batch the hspice runs" "" boolean optional}
}
echo "Defined procedure 'write_hsp_runscript'."

### generated aocv spice decks allowing monte-carlo local variation simulation
proc write_pocv_spice_deck {args} {

  set cargs(-debug) 0
  set cargs(-sig_digits) 5
  set cargs(-no_predrvr_load) 0
  set cargs(-add_predrvr_cnt) 0
  set cargs(-no_predrvr_variation) 0
  set cargs(-predrvr_max_fanout_cap_pct) ""
  set cargs(-disable_predrvr_local_params) "mismatchflag=0"
  set cargs(-add_stage_var_meas) 0
  set cargs(-nmos_only) 0
  set cargs(-pmos_only) 0
  set cargs(-disable_local_params) "mismatchflag=0"
  set cargs(-ref_spice_model) ""
  set cargs(-ref_spice_lib) ""
  set cargs(-local_params) ""
  set cargs(-global_params) ""
  set cargs(-spice_options) ""
  set cargs(-accurate) 0
  set cargs(-spice_cells) ""
  set cargs(-spice_cells_dir) "."
  set cargs(-spice_model) ""
  set cargs(-spice_lib) ""
  set cargs(-spice_output) ""
  set cargs(-spice_ext) "POCV.sp"
  set cargs(-array_name) ""
  set cargs(-cell) ""
  set cargs(-pocv_dir) "."
  set cargs(-meas_dir) "."
  set cargs(-stage_fanout) 1
  set cargs(-max_logic_depth) 15
  set cargs(-input) ""
  set cargs(-mis_input) ""
  set cargs(-output) ""
  set cargs(-comp_output) ""
  set cargs(-port_list) ""
  set cargs(-ic) ""
  set cargs(-supply) ""
  set cargs(-no_supply_source) 0
  set cargs(-sensitization_data) ""
  set cargs(-max_fanin_trans) ""
  set cargs(-max_fanin_trans_fall) -1.0
  set cargs(-max_fanout_cap) ""
  set cargs(-max_fanout_cap_pct) 1
  set cargs(-max_fanin_trans_pct) 1
  set cargs(-monte) 2000
  set cargs(-monte_split) 400
  set cargs(-temp) ""
  set cargs(-period) 4.0
  set cargs(-cycles) 2
  set cargs(-high_pulse) ""
  set cargs(-tran_start) 1.0
  set cargs(-tran_step) .001
  set cargs(-tran_stop) ""
  set cargs(-rccap) 1.0
  set cargs(-rcres) 10.0
  set cargs(-rcseg) 0
  set cargs(-meas_from_cross) 1
  set cargs(-meas_to_cross) 1
  set cargs(-meas_from_cross_rf_incr) 1
  set cargs(-meas_to_cross_rf_incr) 1
  set cargs(-meas_from_cross_rf_mult) 0
  set cargs(-meas_from_cross_rf_exp) 0
  set cargs(-meas_from_cross_rf_exp_mult) 0
  set cargs(-meas_from_cross_level_mult) 0
  set cargs(-meas_from_cross_level_exp) 0
  set cargs(-meas_from_cross_level_exp_mult) 0
  set cargs(-meas_td) ""
  set cargs(-meas_from_edge) "CROSS"
  set cargs(-upper_slew) ""
  set cargs(-lower_slew) ""
  set cargs(-delay_meas) ""
  set cargs(-inc_temp)  0
  set cargs(-inc_spice_cells)  0
  set cargs(-time_unit) ""
  set cargs(-cap_unit) "FF"
  #analysis_modes "same_cell, alternate_cell, drive_cell"
  set cargs(-cell_chain_mode) "same_cell"
  #variation_modes: all_tx, switching_only, ignore_off
  set cargs(-variation_mode) "all_tx"
  set cargs(-fanout_cap_mode) "max_fanout_cap_pct"
  set cargs(-fanin_trans_mode) "max_fanin_trans_pct"
  set cargs(-meas_depth_list) {}
  set cargs(-input_pin_cap) {}
  set cargs(-debug) 0
  set cargs(-vss) 0.0
  set cargs(-reverse) 0
  set max_fanout_cap_index 0
  set predrvr_max_fanout_cap_index 0
  set cargs(-nt) 0

  if { [parse_myproc_arguments -args $args cargs] eq "0" } {
  	return 0
  }
  if {[string compare $cargs(-array_name) ""] != 0 } {
    upvar 1 $cargs(-array_name) cellarray
  }

  set pwd [pwd]
  set pwd [string trim $pwd]

  if { ![file isdirectory $cargs(-meas_dir)] } {
    exec mkdir $cargs(-meas_dir)
  }


## determine cap units
  if {[defined -nocase cellarray(capacitance_load_unit)] && ($cellarray(capacitance_load_unit) eq "1e-12") } {
    set cargs(-cap_unit) "PF"
  } else {
    set cargs(-cap_unit) "FF"
  }


## determine time units
  if {($cargs(-time_unit) eq "") && [info exists cellarray(time_unit)] && ($cellarray(time_unit) eq "1e-12") } {
    set cargs(-time_unit) "PS"
  } elseif {($cargs(-time_unit) eq "") && [info exists cellarray(time_unit)] && (($cellarray(time_unit) eq "1e-9") || ($cellarray(time_unit) eq "1e-09")) } {
    set cargs(-time_unit) "NS"
  } elseif { $cargs(-time_unit) eq "" } {
    set cargs(-time_unit) "NS"
    puts "Warning: -time_unit not set defaulting to NS"
  }
	
    if { ([string tolower $cargs(-time_unit)] eq "ps") && ($cargs(-tran_step) < .01) } {
		set cargs(-tran_step) .1
	        puts "Warning: resetting -time_step to .1PS"
    } elseif { ([string tolower $cargs(-time_unit)] eq "ns") && ($cargs(-tran_step) < .00001) } {
		set cargs(-tran_step) .0001
	        puts "Warning: resetting -time_step to .0001NS"
    }

    if {([string tolower $cargs(-time_unit)] eq "ns") && $cargs(-period) > 300 } {
	puts "Warning: -time_unit == NS but -period > 300 time units, converting -period to NS"
        set cargs(-period) [expr $cargs(-period) / 1000]
    }
    if { ([string tolower $cargs(-time_unit)] eq "ns") && ($cargs(-high_pulse) ne "") && ($cargs(-high_pulse) > 300) } {
	puts "Warning: -time_unit == NS but -high_pulse > 300 time units, converting -high_pulse to NS"
        set cargs(-high_pulse) [expr $cargs(-high_pulse) / 1000]
    }
    if {([string tolower $cargs(-time_unit)] eq "ps") && $cargs(-period) < 300 } {
	puts "Warning: -time_unit == PS but -period < 300 time units, converting -period to PS"
        set cargs(-period) [expr $cargs(-period) * 1000]
    }
    if { ([string tolower $cargs(-time_unit)] eq "ps") && ($cargs(-high_pulse) ne "") && ($cargs(-high_pulse) < 300) } {
	puts "Warning: -time_unit == NS but -high_pulse < 300 time units, converting -high_pulse to PS"
        set cargs(-high_pulse) [expr $cargs(-high_pulse) * 1000]
    }

  puts "   TIME UNIT: $cargs(-time_unit)"

## determine tran_stop value
  if {$cargs(-tran_stop) eq ""} {
    set cargs(-tran_stop) [expr $cargs(-period) * [expr $cargs(-cycles) +  .5]]
  }

## determine -meas_depth list(based on mode)
  if {$cargs(-meas_depth_list) eq ""} {
	set key1 1
	while { $key1  <= $cargs(-max_logic_depth)} {
	lappend cargs(-meas_depth_list) $key1
	set depth_array($key1) 1
	incr key1
	}
	
  } else {
    foreach key1 [split [regsub -all "\[ \t\]+" [string trim [join $cargs(-meas_depth_list)]] { }]] {
	set depth_array($key1) 1
    }
  } 
  #based on mode choose which cell to put in list:
  # modes: same_cell, alternate_cell, drive_cell, custom

## create spice cell chain ordered list based on cell_chain_mode
  set cell_list {}
  array set unique_cells {}
  array set ic {}
  array set sensitization {}
  array set inputs {}
  array set outputs {}
  array set comp_outputs {}
  array set port_lists {}

  puts "   CELL CHAIN MODE: $cargs(-cell_chain_mode)"

  set cargs(-cell) [split [regsub -all "\[ \t\]+" [string trim [join $cargs(-cell)]] { }]]

 if { [regexp "custom" $cargs(-cell_chain_mode)] } {
     set cargs(-max_logic_depth) [llength $cargs(-cell)]
     set cell_list $cargs(-cell)
     lappend cell_list [lindex $cargs(-cell) end]
     lappend cell_list [lindex $cargs(-cell) end]
     set cell [lindex $cargs(-cell) 0]
 } elseif { [regexp "drive" $cargs(-cell_chain_mode)] } {
     if { $cargs(-add_predrvr_cnt) > 0 } {
     for {set i 0} { $i < $cargs(-add_predrvr_cnt)} {incr i} {
     lappend cell_list [lindex $cargs(-cell) end]
     }
     }

     for {set i 0} { $i < [expr $cargs(-max_logic_depth) -1]} {incr i} {
     lappend cell_list [lindex $cargs(-cell) end]
     }
     lappend cell_list [lindex $cargs(-cell) 0]
     lappend cell_list [lindex $cargs(-cell) end]
     lappend cell_list [lindex $cargs(-cell) end]
     set cell [lindex $cargs(-cell) 0]
 } elseif { [regexp "same" $cargs(-cell_chain_mode)] } {
     for {set i 0} { $i <= [expr $cargs(-max_logic_depth) + 2 + $cargs(-add_predrvr_cnt)]} {incr i} {
     lappend cell_list [lindex $cargs(-cell) 0]
     }
     set cell [lindex $cargs(-cell) 0]
 } elseif { [regexp "alter" $cargs(-cell_chain_mode)] } {
     set even 0
     for {set i 0} { $i <= [expr $cargs(-max_logic_depth) +2]} {incr i} {
     if { $even } {
     set even 0
     lappend cell_list [lindex $cargs(-cell) end]
     } else {
     incr even
     lappend cell_list [lindex $cargs(-cell) 0] 
     }
     }
     if { $cargs(-add_predrvr_cnt) > 0 } {
     set even 0
     for {set i 0} { $i < $cargs(-add_predrvr_cnt)} {incr i} {
     if { $even } {
     set even 0
     set cell_list [linsert $cell_list 0 [lindex $cargs(-cell) 0]]
     } else {
     incr even
     set cell_list [linsert $cell_list 0 [lindex $cargs(-cell) end]]
     }
     }
     }
     set cell [lindex $cargs(-cell) 0]
 }


 if { $cargs(-debug) } {
     puts "   ORDERED CELL LIST; $cell_list"
 }
      


## find unique cell list so that all data can be added to spice deck.
 foreach cell $cell_list {
     set unique_cells($cell) 1
 }

  #### check for supply definitions and find vdd value
  set pvdd ""
  set vdd ""
  #add cell based support supply(<cellname>) ...
  array set supply {}
  if {$cargs(-supply) ne ""} {
      foreach key1 $cargs(-supply)  {
        while {[regexp "(\[^ \t\]+)\=(\[^ \t\]+)" $key1 dum port value] } {
           set supply([string tolower $port]) $value
          set cellarray(cell,__copt__,supply,[string tolower $port]) $value
        regsub "(\[^ \t\]+)\=(\[^ \t\]+)" $key1 {} key1
          if {($pvdd eq "") && ($value > 0.001)} {
            set pvdd "param_$port"
            set vdd [string tolower $port]
          }
        }
      }
    } elseif { [defined -nocase cellarray(cell,$cell,supply)] } {
      foreach key1 [keys -nocase cellarray(cell,$cell,supply)]  {
          set supply([string tolower $key1]) $cellarray(cell,$cell,supply,$key1)
        if {($pvdd eq "") && ($supply([string tolower $key1]) > 0.001)} {
          set pvdd "param_$key1"
          set vdd [string tolower $key1]
        }
      }
    } elseif { [defined -nocase cellarray(cell,-,supply)] } {
      foreach key1 [keys -nocase cellarray(cell,-,supply)]  {
          set supply([string tolower $key1]) $cellarray(cell,-,supply,$key1)
        if {($pvdd eq "") && ($cellarray(cell,-,supply,[string tolower $key1]) > 0.001)} {
          set pvdd "param_$key1"
          set vdd [string tolower $key1]
        }
      }
    }

### parse sensitization input
  if { $cargs(-sensitization_data) ne "" } {
    foreach key1 $cargs(-sensitization_data)  {
      while {[regexp "\[ \t\{\]*(\[^ \t\=\:\]*)\[ \t\{\]*\[\:\]*\[ \t\{\]*(\[^ \t\=\:\{\]*)\[ \t\{\]*(\[^ \t\=\:\{\]*)\[ \t\{\]*(\[^ \t\]+)\=(\[rR\]+)" $key1 dum mcell in out port value] } {
	if {$mcell ne "" } {
        regsub "\[ \t\{\]*(\[^ \t\=\:\{\]*)\[ \t\{\]*(\[^ \t\=\:\{\]*)\[ \t\{\]*(\[^ \t\=\:\]*)\[ \t\{\]*\[\:\]\[ \t\{\]*(\[^ \t\]+)\=(\[rR\]+)" $key1 "${mcell}:" key1
          if {![defined cellarray(cell,$mcell,supply,$port] && ![defined cellarray(cell,$mcell,supply,[string tolower $port]] } {
          set value 0.0
          set value2 $supply($vdd)
          set sensitization($mcell,[string tolower $port]) "$value->$value2"
          }
	 } else {
        regsub "\[ \t\{\]*(\[^ \t\=\:\{\]*)\[ \t\{\]*(\[^ \t\=\:\{\]*)\[ \t\{\]*(\[^ \t\]+)\=(\[rR\]+)" $key1 {} key1
          if { ($cell ne "") && ![defined cellarray(cell,$cell,supply,$port] && ![defined cellarray(cell,$cell,supply,[string tolower $port]] } {
          set value 0.0
          set value2 $supply($vdd)
          set sensitization(-,[string tolower $port]) "$value->$value2"
          } elseif { ![defined cellarray(cell,-,supply,$port] && ![defined cellarray(cell,-,supply,[string tolower $port]] } {
          set value 0.0
          set value2 $supply($vdd)
          set sensitization(-,[string tolower $port]) "$value->$value2"
	  }
        }
      }
      while {[regexp "\[ \t\{\]*(\[^ \t\=\:\]*)\[ \t\{\]*\[\:\]*\[ \t\{\]*(\[^ \t\=\:\{\]*)\[ \t\{\]*(\[^ \t\=\:\{\]*)\[ \t\{\]*(\[^ \t\]+)\=(\[fF\]+)" $key1 dum mcell in out port value] } {
	if {$mcell ne "" } {
        regsub "\[ \t\{\]*(\[^ \t\=\:\{\]*)\[ \t\{\]*(\[^ \t\=\:\{\]*)\[ \t\{\]*(\[^ \t\=\:\]*)\[ \t\{\]*\[\:\]\[ \t\{\]*(\[^ \t\]+)\=(\[fF\]+)" $key1 "${mcell}:" key1
          if {![defined cellarray(cell,$mcell,supply,$port] && ![defined cellarray(cell,$mcell,supply,[string tolower $port]] } {
          set value 0.0
          set value2 $supply($vdd)
          set sensitization($mcell,[string tolower $port]) "$value->$value2"
          }
	 } else {
        regsub "\[ \t\{\]*(\[^ \t\=\:\{\]*)\[ \t\{\]*(\[^ \t\=\:\{\]*)\[ \t\{\]*(\[^ \t\]+)\=(\[fF\]+)" $key1 {} key1
          if { ($cell ne "") && ![defined cellarray(cell,$cell,supply,$port] && ![defined cellarray(cell,$cell,supply,[string tolower $port]] } {
          set value 0.0
          set value2 $supply($vdd)
          set sensitization(-,[string tolower $port]) "$value->$value2"
          } elseif { ![defined cellarray(cell,-,supply,$port] && ![defined cellarray(cell,-,supply,[string tolower $port]] } {
          set value 0.0
          set value2 $supply($vdd)
          set sensitization(-,[string tolower $port]) "$value->$value2"
	  }
        }
      }
      if { 0 } {
      while {[regexp "\[ \t\{\]*(\[^ \t\=\:\{\]*)\[ \t\{\]*(\[^ \t\=\:\{\]*)\[ \t\{\]*(\[^ \t\]+)\=(\[rR\]+)" $key1 dum in out port value] } {
        regsub "\[ \t\{\]*(\[^ \t\]+)\=(\[rR\]+)" $key1 {} key1
          if { ($cell ne "") && ![defined cellarray(cell,$cell,supply,$port] && ![defined cellarray(cell,$cell,supply,[string tolower $port]] } {
          set value 0.0
          set value2 $supply($vdd)
          set sensitization(-,[string tolower $port]) "$value->$value2"
          } elseif { ![defined cellarray(cell,-,supply,$port] && ![defined cellarray(cell,-,supply,[string tolower $port]] } {
          set value 0.0
          set value2 $supply($vdd)
          set sensitization(-,[string tolower $port]) "$value->$value2"
        }
      }
      while {[regexp "\[ \t\{\]*(\[^ \t\=\:\]*)\[ \t\{\]*\[\:\]*\[ \t\{\]*(\[^ \t\]+)\=(\[fF\]+)" $key1 dum mcell in out port value] } {
	  if { $mcell ne "" } {
        regsub "\[ \t\{\]*(\[^ \t\=\:\]*)\[ \t\{\]*\[\:\]*\[ \t\{\]*(\[^ \t\=\:\{\]*)\[ \t\{\]*(\[^ \t\=\:\{\]*)\[ \t\{\]*(\[^ \t\]+)\=(\[fF\]+)" $key1 "${mcell}:" key1
          if { ![defined cellarray(cell,$mcell,supply,$port] && ![defined cellarray(cell,$mcell,supply,[string tolower $port]] } {
          set value $supply($vdd)
          set value2 0
          set sensitization($mcell,[string tolower $port]) "$value->$value2"
          }
	  }
      }
      while {[regexp "\[ \t\{\]*(\[^ \t\=\:\]*)\[ \t\{\]*\[\:\]\[ \t\{\]*(\[^ \t\]+)\=(\[fF\]+)" $key1 dum port value] } {
        regsub "\[ \t\{\]*(\[^ \t\]+)\=(\[fF\]+)" $key1 {} key1
          if { ($cell ne "") && ![defined cellarray(cell,$cell,supply,$port] && ![defined cellarray(cell,$cell,supply,[string tolower $port]] } {
          set value $supply($vdd)
          set value2 0.0
          set sensitization(-,[string tolower $port]) "$value->$value2"
          } elseif { ![defined cellarray(cell,-,supply,$port] && ![defined cellarray(cell,-,supply,[string tolower $port]] } {
          set value $supply($vdd)
          set value2 0.0
          set sensitization(-,[string tolower $port]) "$value->$value2"
          }
      }
      }

      set delay {}
      set mcell {}
      set in {}
      set out {}
      set key1 " $key1"
      while  {[regexp "\[ \t\{\]*(\[^ \t\=\:\]*)\[ \t\{\]*\[\:\]*\[ \t\{\]*(\[^ \t\=\:\{\]*)\[ \t\{\]*(\[^ \t\=\:\{\]*)\[ \t\{\]+(\[^ \t\]+)\=\[ \t\{\]*\[\!\]+\[ \t\]*(\[^ \t\:\]+)\[:\]*(\[0-9\.\]*)" $key1 dum mcell in out port value delay] } {
          if { ($mcell ne "") } {
        	regsub "\[ \t\{\]*(\[^ \t\=\:\]*)\[ \t\{\]*\[\:\]*\[ \t\{\]*(\[^ \t\=\:\{\]*)\[ \t\{\]*(\[^ \t\=\:\{\]*)\[ \t\{\]+\[^ \t\]+\=\[ \t\{\]*\[\!\]+\[ \t\]*\[^ \t\:\]+\[:\]*\[0-9\.\]*" $key1 "$mcell: " key1
	  if {![defined cellarray(cell,$mcell,supply,$port] && ![defined cellarray(cell,$mcell,supply,[string tolower $port]] } {
	  if { $delay ne "" } {
          set sensitization($mcell,[string tolower $port]) "\!$value\:$delay"
	  } else {
          set sensitization($mcell,[string tolower $port]) "\!$value"
	  }
          }
	  } else {
        	regsub "\[ \t\{\]*(\[^ \t\=\:\{\]*)\[ \t\{\]*(\[^ \t\=\:\{\]*)\[ \t\{\]+\[^ \t\]+\=\[ \t\{\]*\[\!\]+\[ \t\]*\[^ \t\:\]+\[:\]*\[0-9\.\]*" $key1 " " key1
          if { ($cell ne "") && ![defined cellarray(cell,$cell,supply,$port] && ![defined cellarray(cell,$cell,supply,[string tolower $port]] } {
	  if { $delay ne "" } {
          set sensitization(-,[string tolower $port]) "\!$value\:$delay"
	  } else {
          set sensitization(-,[string tolower $port]) "\!$value"
	  }
        } elseif { ![defined cellarray(cell,-,supply,$port] && ![defined cellarray(cell,-,supply,[string tolower $port]] } {
	  if { $delay ne "" } {
          set sensitization(-,[string tolower $port]) "\!$value\:$delay"
	  } else {
          set sensitization(-,[string tolower $port]) "\!$value"
	  }
	  }
	  }
      }
      while  {[regexp "\[ \t\{\]*(\[^ \t\=\:\]*)\[ \t\{\]*\[\:\]*\[ \t\{\]*(\[^ \t\=\:\{\]*)\[ \t\{\]*(\[^ \t\=\:\{\]*)\[ \t\{\]+(\[^ \t\]+)\=\[ \t\]*(\[^ \t\:\]+)\[:\]*(\[0-9\.\]*)" $key1 dum mcell in out port value delay] } {
          if { ($mcell ne "") } {
	       regsub "\[ \t\{\]*(\[^ \t\=\:\]*)\[ \t\{\]*\[\:\]*\[ \t\{\]*(\[^ \t\=\:\{\]*)\[ \t\{\]*(\[^ \t\=\:\{\]*)\[ \t\{\]+(\[^ \t\]+)\=\[ \t\]*(\[^ \t\:\]+)\[:\]*(\[0-9\.\]*)" $key1 "$mcell: " key1
	  if {![defined cellarray(cell,$mcell,supply,$port] && ![defined cellarray(cell,$mcell,supply,[string tolower $port]] } {
	  if { $delay ne "" } {
          set sensitization($mcell,[string tolower $port]) "$value\:$delay"
	  } else {
          set sensitization($mcell,[string tolower $port]) "$value"
	  }
          }
	  } else {
	       regsub "\[ \t\{\]*(\[^ \t\=\:\]*)\[ \t\{\]*\[\:\]*\[ \t\{\]*(\[^ \t\=\:\{\]*)\[ \t\{\]*(\[^ \t\=\:\{\]*)\[ \t\{\]+(\[^ \t\]+)\=\[ \t\]*(\[^ \t\:\]+)\[:\]*(\[0-9\.\]*)" $key1 { } key1
        if { ($cell ne "") && ![defined cellarray(cell,$cell,supply,$port] && ![defined cellarray(cell,$cell,supply,[string tolower $port]] } {
	  if { $delay ne "" } {
          set sensitization(-,[string tolower $port]) "$value\:$delay"
	  } else {
          set sensitization(-,[string tolower $port]) "$value"
	  }
        } elseif { ![defined cellarray(cell,-,supply,$port] && ![defined cellarray(cell,-,supply,[string tolower $port]] } {
	  if { $delay ne "" } {
          set sensitization(-,[string tolower $port]) "$value\:$delay"
	  } else {
          set sensitization(-,[string tolower $port]) "$value"
	  }
	  }
	  }
      }
      if { 0 }  {
      set delay {}
      while  {[regexp "\[ \t\{\]*(\[^ \t\]+)\=\[\!\]+\[ \t\]*(\[^ \t\:\]+)\[:\]*(\[0-9\.\]*)" $key1 dum port value delay] } {
        regsub "\[ \t\{\]*\[^ \t\]+\=\[\!\]+\[ \t\]*\[^ \t\:\]+\[:\]*\[0-9\.\]*" $key1 {} key1
          if { ($cell ne "") && ![defined cellarray(cell,$cell,supply,$port] && ![defined cellarray(cell,$cell,supply,[string tolower $port]] } {
	  if { $delay ne "" } {
          set sensitization(-,[string tolower $port]) "\!$value\:$delay"
	  } else {
          set sensitization(-,[string tolower $port]) "\!$value"
	  }
        } elseif { ![defined cellarray(cell,-,supply,$port] && ![defined cellarray(cell,-,supply,[string tolower $port]] } {
	  if { $delay ne "" } {
          set sensitization(-,[string tolower $port]) "\!$value\:$delay"
	  } else {
          set sensitization(-,[string tolower $port]) "\!$value"
	  }
        }
      }
      set delay {}
      while  {[regexp "\[ \t\{\]*(\[^ \t\=\:\]*)\[ \t\]*\[\:\]\[ \t\]*(\[^ \=\t\]+)\=\[ \t\]*(\[^ \t\:\}\]+)\[\:\]*(\[0-9\.\]*)" $key1 dum mcell port value delay] } {
        regsub "\[ \t\{\]*(\[^ \t\=\:\]*)\[ \t\]*\[\:\]\[ \t\]*\[^ \t\]+\=\[ \t\]*\[^ \t\:\]+\[\:\]*\[0-9\.\]*" $key1 "$mcell:" key1
          if { ($mcell ne "") && ![defined cellarray(cell,$mcell,supply,$port] && ![defined cellarray(cell,$mcell,supply,[string tolower $port]] } {
	  if { $delay ne "" } {
          set sensitization($mcell,[string tolower $port]) "$value\:$delay"
	  } else {
          set sensitization($mcell,[string tolower $port]) "$value"
	  }
        }
      }
      set delay {}
      while  {[regexp "\[ \t\{\]*(\[^ \=\t\]+)\=\[ \t\]*(\[^ \t\:\}\]+)\[:\]*(\[0-9\.\]*)" $key1 dum port value delay] } {
        regsub "\[ \t\{\]*\[ \t\{\]*\[^ \t\]+\=\[ \t\]*\[^ \t\:\]+\[:\]*\[0-9\.\]*" $key1 {} key1
          if { ($cell ne "") && ![defined cellarray(cell,$cell,supply,$port] && ![defined cellarray(cell,$cell,supply,[string tolower $port]] } {
	  if { $delay ne "" } {
          set sensitization(-,[string tolower $port]) "$value\:$delay"
	  } else {
          set sensitization(-,[string tolower $port]) "$value"
	  }
        } elseif { ![defined cellarray(cell,-,supply,$port] && ![defined cellarray(cell,-,supply,[string tolower $port]] } {
	  if { $delay ne "" } {
          set sensitization(-,[string tolower $port]) "$value\:$delay"
	  } else {
          set sensitization(-,[string tolower $port]) "$value"
	  }
        }
     }
     }
    }
  }
  ###
  if { $cargs(-ic) ne "" } {
    while {[regexp "\[ \t\{\]*(\[^ \t\=\:\]*)\[ \t\{\]*\[\:\]\[ \t\{\]*(\[^ \t\=\]+)\[ \t\]*\=\[ \t\]*(\[^ \t\}\]+)" $cargs(-ic) dum mcell key1 value1] } {
       regsub "\[ \t\{\]*(\[^ \t\=\:\]*)\[ \t\{\]*\[\:\]\[ \t\{\]*(\[^ \t\=\]+)\[ \t\]*\=\[ \t\]*(\[^ \t\}\]+)" $cargs(-ic) "$mcell:" cargs(-ic)
      if { $value1 eq "1" } {
        set ic($mcell,[string tolower $key1]) $supply($vdd)
      } else {
        set ic($mcell,[string tolower $key1]) $value1
      }
    }
    while {[regexp "^\[ \t\{\]*(\[^ \t\=\]+)\[ \t\]*\=\[ \t\]*(\[^ \t\}\]+)" $cargs(-ic) dum key1 value1] } {
      regsub "^\[ \t\{\]*(\[^ \t\=\]+)\[ \t\]*\=\[ \t\]*(\[^ \t\}\]+)" $cargs(-ic) {} cargs(-ic)
      if { $value1 eq "1" } {
        set ic(-,[string tolower $key1]) $supply($vdd)
      } else {
        set ic(-,[string tolower $key1]) $value1
      }
    }
 ####     
  } 


  if { $cargs(-spice_output) eq ""} {
    if { $cargs(-ref_spice_model) ne "" } {
    set cargs(-spice_output) "$cargs(-meas_dir)/$cargs(-cell).o-${output}.i-${input}.ref"
    } else {
    set cargs(-spice_output) "$cargs(-meas_dir)/$cargs(-cell).o-${output}.i-${input}"
    }
  }
  if { ![regexp "^\[ \t\]*\[\/\$\]" $cargs(-spice_output)] } {
    set cargs(-spice_output) "$cargs(-meas_dir)/$cargs(-spice_output)"
  }

  ## add cell based support to all of these
  if { $cargs(-input) ne "" } {
    while {[regexp "\[ \t\{\]*(\[^ \t\=\:\]*)\[ \t\{\]*\[\:\]\[ \t\{\]*(\[^ \t\=\}\]+)" $cargs(-input) dum mcell key1]} {
    regsub "\[ \t\{\]*(\[^ \t\=\:\]*)\[ \t\{\]*\[\:\]\[ \t\{\]*(\[^ \t\=\}\]+)" $cargs(-input) {} cargs(-input)
    set inputs($mcell) $key1
    }
    if {[regexp "\[ \t\{\]*(\[^ \t\=\}\]+)" $cargs(-input) dum key1]} {
    set inputs(-) $key1
    }
  }
  if { $cargs(-mis_input) ne "" } {
    if { [regexp "\[ \t\{\]*(\[^ \t\=\:\]*)\[ \t\{\]*\[\:\]\[ \t\{\]*(\[^ \t\=\}\]+)" $cargs(-mis_input) dum mcell key1] } {
    while {[regexp "\[ \t\{\]*(\[^ \t\=\:\]*)\[ \t\{\]*\[\:\]\[ \t\{\]*(\[^ \t\=\}\]+)" $cargs(-mis_input) dum mcell key1]} {
    regsub "\[ \t\{\]*(\[^ \t\=\:\]*)\[ \t\{\]*\[\:\]\[ \t\{\]*(\[^ \t\=\}\]+)" $cargs(-mis_input) {} cargs(-mis_input)
    lappend mis_inputs($mcell) $key1
    }
    } elseif {[regexp "\[ \t\{\]*(\[^ \t\=\}\]+)" $cargs(-mis_input) dum key1]} {
	while {[regexp "\[ \t\{\]*(\[^ \t\=\}\]+)" $cargs(-mis_input) dum key1]} {
    	lappend mis_inputs(-) $key1
	regsub "\[ \t\{\]*\[^ \t\=\}\]+" $cargs(-mis_input) {} cargs(-mis_input)
	}
    }
  }
  if { $cargs(-output) ne "" } {
    while {[regexp "\[ \t\{\]*(\[^ \t\=\:\]*)\[ \t\{\]*\[\:\]\[ \t\{\]*(\[^ \t\=\}\]+)" $cargs(-output) dum mcell key1]} {
    regsub "\[ \t\{\]*(\[^ \t\=\:\]*)\[ \t\{\]*\[\:\]\[ \t\{\]*(\[^ \t\=\}\]+)" $cargs(-output) {} cargs(-output)
    set outputs($mcell) $key1
    }
    if {[regexp "\[ \t\{\]*(\[^ \t\=\}\]+)" $cargs(-output) dum key1]} {
    set outputs(-) $key1
    }
  }
  if { $cargs(-comp_output) ne "" } {
    while {[regexp "\[ \t\{\]*(\[^ \t\=\:\]*)\[ \t\{\]*\[\:\]\[ \t\{\]*(\[^ \t\=\}\]+)" $cargs(-comp_output) dum mcell key1]} {
    regsub "\[ \t\{\]*(\[^ \t\=\:\]*)\[ \t\{\]*\[\:\]\[ \t\{\]*(\[^ \t\=\}\]+)" $cargs(-comp_output) {} cargs(-comp_output)
    set comp_outputs($mcell) $key1
    }
    if {[regexp "\[ \t\{\]*\[\:\]*\[ \t\{\]*(\[^ \t\=\}\]+)" $cargs(-comp_output) dum key1]} {
    set comp_outputs(-) $key1
    }
  }

  if { $cargs(-port_list) ne "" } {
     while { [regexp "^\[ \t\]+(\[^ \t\:\]+)\[ \t\]*\:" [string trim [join $cargs(-port_list)]] dum mcell] } {
        regsub  "^\[ \t\]+(\[^ \t\:\]+)\[ \t\]*\:" [string trim [join $cargs(-port_list)]] {} cargs(-port_list]
        set port_lists($mcell) [split [regsub -all "\[ \t\]+" [string trim [join $cargs(-port_list)]] { }]]
     }
    
     if { [regexp "^\[ \t\]+(\[^ \t\:\]+)" [string trim [join $cargs(-port_list)]] dum mcell] } {
        set port_lists(-) [split [regsub -all "\[ \t\]+" [string trim [join $cargs(-port_list)]] { }]]
     }
   }

  ## get the user thresholds
  if {$cargs(-lower_slew) ne ""} {
    set cellarray(cell,__copt__,lower_slew) $cargs(-lower_slew)
  }
  if {$cargs(-upper_slew) ne ""} {
    set cellarray(cell,__copt__,upper_slew) $cargs(-upper_slew)
  }
  if {$cargs(-delay_meas) ne ""} {
    set cellarray(cell,__copt__,delay_slew) $cargs(-delay_meas)
  }

  if { $cargs(-max_fanin_trans) > 0 } {
    set cellarray(cell,__copt__,max_transition) $cargs(-max_fanin_trans)
  }
  if { $cargs(-max_fanin_trans_fall) > 0 } {
    set cellarray(cell,__copt__,max_fall_transition) $cargs(-max_fanin_trans_fall)
  }

  if { $cargs(-input_pin_cap) ne "" } {
    set cellarray(cell,__copt__,capacitance) $cargs(-input_pin_cap)
  }
  if { $cargs(-max_fanout_cap) ne "" } {
    set cellarray(cell,__copt__,max_capacitance) $cargs(-max_fanout_cap)
  }

  ## get operating temperature
  if { $cargs(-inc_temp) } {
    if {$cargs(-temp) eq ""} {
      if { [defined -nocase cellarray(temperature)]} {
        set cargs(-temp) $cellarray(temperature)
      } elseif { [defined -nocase cellarray(temperature_max)]} {
        set cargs(-temp) $cellarray(temperature_max)
      } elseif { [defined -nocase cellarray(temperature_min)]} {
        set cargs(-temp) $cellarray(temperature_min)
      } elseif { [defined -nocase cellarray(nom_temperature)]} {
        set cargs(-temp) $cellarray(nom_temperature)
      } else {
        die "Error: no temperature specified thru library or cmd line"
      }
    }
  }

  #  change this to input(cellname)
  if { [defined -nocase inputs($cell)] } {
    set input $inputs($cell)
  } elseif { [defined -nocase inputs(-)] } {
    set input $inputs(-)
  } elseif { [defined -nocase cellarray(cell,$cell,input)] } {
    set input $cellarray(cell,$cell,input)
  } elseif { [defined -nocase cellarray(cell,-,input)] } {
    set input $cellarray(cell,-,input)
  } else {
    die "Error: could not determine input to use of cell: $cell"
  }

  if { [defined -nocase outputs($cell)] } {
    set output $outputs($cell)
  } elseif { [defined -nocase outputs(-)] } {
    set output $outputs(-)
  } elseif { [defined -nocase cellarray(cell,$cell,output)] } {
    set output $cellarray(cell,$cell,output)
  } elseif { [defined -nocase cellarray(cell,-,output)] } {
    set output $cellarray(cell,-,output)
  } else {
    die "Error: could not determine output to use of cell: $cell"
  }


  if { [defined -nocase cellarray(cell,__copt__,pin,lower_slew)]} {
    set lower_slew $cellarray(cell,__copt__,pin,$input,lower_slew)
  } elseif { [defined -nocase cellarray(cell,$cell,pin,$input,rc_slew_lower_threshold_pct_rise)]} {
    set lower_slew $cellarray(cell,$cell,pin,$input,rc_slew_lower_threshold_pct_rise)
  } elseif { [defined -nocase cellarray(cell,-,lower_slew)]} {
    set lower_slew $cellarray(cell,-,lower_slew)
  } elseif { [defined -nocase cellarray(slew_lower_threshold_pct_rise)]} {
    set lower_slew $cellarray(slew_lower_threshold_pct_rise)
  } else {
    set lower_slew 20
  }

  ## get the upper_slew threshold
  if { [defined -nocase cellarray(cell,__copt__,upper_slew)]} {
    set upper_slew $cellarray(cell,__copt__,upper_slew)
  } elseif { [defined -nocase cellarray(cell,$cell,pin,$input,rc_slew_upper_threshold_pct_rise)]} {
    set upper_slew $cellarray(cell,$cell,pin,$input,rc_slew_upper_threshold_pct_rise)
  } elseif { [defined -nocase cellarray(cell,-,upper_slew)]} {
    set upper_slew $cellarray(cell,-,upper_slew)
  } elseif { [defined -nocase cellarray(slew_upper_threshold_pct_rise)]} {
    set upper_slew $cellarray(slew_upper_threshold_pct_rise)
  } else {
    set upper_slew 80
  }


  ## get the delay measure thresh
  if { [defined -nocase cellarray(cell,__copt__,delay_meas)]} {
    set delay_meas $cellarray(cell,__copt__,delay_meas)
  } elseif { [defined -nocase cellarray(cell,$cell,pin,$input,rc_input_threshold_pct_rise)]} {
    set delay_meas $cellarray(cell,$cell,pin,$input,rc_input_threshold_pct_rise)
  } elseif { [defined -nocase cellarray(cell,-,delay_meas)]} {
    set delay_meas $cellarray(cell,-,delay_meas)
  } elseif { [defined -nocase cellarray(input_threshold_pct_rise)]} {
    set delay_meas $cellarray(input_threshold_pct_rise)
  } else {
    set delay_meas 50
  }


  if { $lower_slew > 1 } {
    set lower_slew [expr $lower_slew / 100.0]
  }
  if { $upper_slew > 1 } {
    set upper_slew [expr $upper_slew / 100.0]
  }
  if { $delay_meas > 1 } {
    set delay_meas [expr $delay_meas / 100.0]
  }
  if { $cargs(-debug) } {
  puts "   UPPER SLEW MEAS: $upper_slew for cell: $cell"
  puts "   LOWER SLEW MEAS: $lower_slew for cell: $cell"
  puts "   DELAY MEAS: $delay_meas for cell: $cell"
  }

    # calculate initial rise/fall time if one not given 
    if {[defined -nocase cellarray(cell,__copt__,max_transition)] } {
      set max_trans $cellarray(cell,__copt__,max_transition)
    } elseif {[defined -nocase cellarray(cell,$cell,pin,$input,max_transition)] } {
      set max_trans $cellarray(cell,$cell,pin,$input,max_transition)
    } elseif {[defined -nocase cellarray(cell,-,max_transition)] } {
      set max_trans $cellarray(cell,-,max_transition)
    } else {
      set max_trans .1
    }

    #get max trans for cell hash
    if {[defined -nocase cellarray(cell,__copt__,max_fall_transition)] } {
      set max_trans_fall $cellarray(cell,__copt__,max_fall_transition)
    } elseif {[defined -nocase cellarray(cell,__copt__,max_transition)] } {
      set max_trans_fall $cellarray(cell,__copt__,max_transition)
    } elseif {[defined -nocase cellarray(cell,$cell,pin,$input,max_fall_transition)] } {
      set max_trans_fall $cellarray(cell,$cell,pin,$input,max_fall_transition)
    } elseif {[defined -nocase cellarray(cell,$cell,pin,$input,max_transition)] } {
      set max_trans_fall $cellarray(cell,$cell,pin,$input,max_transition)
    } elseif {[defined -nocase cellarray(cell,-,max_fall_transition)] } {
      set max_trans_fall $cellarray(cell,-,max_fall_transition)
    } elseif {[defined -nocase cellarray(cell,-,max_transition)] } {
      set max_trans_fall $cellarray(cell,-,max_transition)
    } else {
      set max_trans_fall .1
    }

  if { ([string tolower $cargs(-time_unit)] eq "ps") && ($max_trans < 1) } {
        puts "Warning:  converting max_trans to PS"	
	set max_trans [expr $max_trans * 1000]
  } elseif { ([string tolower $cargs(-time_unit)] eq "ns") && ($max_trans > 1) } {
        puts "Warning:  converting max_trans to NS"	
	set max_trans [expr $max_trans / 1000]
  }
  if { ([string tolower $cargs(-time_unit)] eq "ps") && ($max_trans_fall < 1) } {
        puts "Warning:  converting max_trans_fall to PS"	
	set max_trans_fall [expr $max_trans_fall * 1000]
  } elseif { ([string tolower $cargs(-time_unit)] eq "ns") && ($max_trans_fall > 1) } {
        puts "Warning:  converting max_trans_fall to NS"	
	set max_trans_fall [expr $max_trans_fall / 1000]
  }

  if { $cargs(-debug) } {
  puts "   MAX_TRANS_RISE: $max_trans for cell: $cell"
  puts "   MAX_TRANS_FALL: $max_trans_fall for cell: $cell"
  puts "   MAX_TRANS_PCT: $cargs(-max_fanin_trans_pct) for cell: $cell"
  puts "   MAX_TRANS_MODE: $cargs(-fanin_trans_mode) for cell: $cell"
  }
  if { $cargs(-fanin_trans_mode) eq "max_fanin_trans_pct"} {
    set max_trans [expr $max_trans * $cargs(-max_fanin_trans_pct)]
    set max_trans_fall [expr $max_trans_fall * $cargs(-max_fanin_trans_pct)]
  if { $cargs(-debug) } {
    puts "   SCALED_MAX_TRANS_RISE: $max_trans for cell: $cell"
    puts "   SCALED_MAX_TRANS_FALL: $max_trans_fall for cell: $cell"
  }
  }

  #### find appropriate max_trans and max_trans_fall
  ##          check to make sure max trans does not exceed the max_trans of the cell
  if {[defined -nocase cellarray(cell,$cell,pin,$input,max_transition)] } {
    if { $max_trans > $cellarray(cell,$cell,pin,$input,max_transition) } {
      puts "Error: $max_trans > maximum transition: $cellarray(cell,$cell,pin,$input,max_transition) allowed on pin: $input of cell $cell"
      exit
    }
    if { $max_trans_fall > $cellarray(cell,$cell,pin,$input,max_transition) } {
      puts "Error: $max_trans_fall > maximum transition: $cellarray(cell,$cell,pin,$input,max_transition) allowed on pin: $input of cell $cell"
      exit
    }
  }
  ## TBD: add a check for max_fall_trans?

  set max_trans [expr $max_trans/($upper_slew - $lower_slew)]
  set max_trans_fall [expr $max_trans_fall/($upper_slew - $lower_slew)]
  if { [defined -nocase cellarray(slew_derate_from_library)] } {
    if { $cargs(-debug) } {
    puts "   SLEW DERATE: $cellarray(slew_derate_from_library) for cell: $cell"
    }
    set max_trans [expr $max_trans * $cellarray(slew_derate_from_library)]
    set max_trans_fall [expr $max_trans_fall * $cellarray(slew_derate_from_library)]
  }
  if { $cargs(-debug) } {
  puts "   FULLSWING_MAX_TRANS_RISE: $max_trans for cell: $cell"
  puts "   FULLSWING_MAX_TRANS_FALL: $max_trans_fall for cell: $cell"
  }
  
  if { ($cargs(-high_pulse) eq "") } {
	if {[expr ($cargs(-period) - $max_trans - $max_trans_fall )/2]  < 0 } {
    puts "Error: -period $cargs(-period) is too small for Scaled Trans Rise: $max_trans Scaled Trans Fall: $max_trans_fall"
    exit
	}
  } elseif { [expr ($cargs(-period) - $max_trans - $max_trans_fall )/2]  < $cargs(-high_pulse) } {
    puts "Error: -period $cargs(-period) is too small for High_Pulse: $cargs(-high_pulse) and Scaled Trans Rise: $max_trans Scaled Trans Fall: $max_trans_fall"
    exit
  }
  

    set spicedata {}

    #### write out the temperature
    if {$cargs(-inc_temp) && ($cargs(-temp) ne "") } {
       snps_lappend spicedata ".temp $cargs(-temp)"
    }
    #### write out the rise/fall/period params
    set  float_format "\%.6f"
    snps_lappend spicedata [format ".param start_time = ${float_format}$cargs(-time_unit)" $cargs(-tran_start)]
    snps_lappend spicedata [format ".param period = ${float_format}$cargs(-time_unit)" $cargs(-period)]
    snps_lappend spicedata [format ".param rise_time = ${float_format}$cargs(-time_unit)" $max_trans]
    snps_lappend spicedata [format ".param fall_time = ${float_format}$cargs(-time_unit)" $max_trans_fall]
    if { $cargs(-high_pulse) eq "" } {
    snps_lappend spicedata [format ".param high_pulse = '( period - rise_time - fall_time ) / 2'"]
    } else {
    snps_lappend spicedata [format ".param high_pulse = ${float_format}$cargs(-time_unit)" $cargs(-high_pulse)]
    }
    if { $cargs(-meas_td) eq "" } {
	set cargs(-meas_td) "start_time"
    }


    #### write out the supplies
    set vss_defined 0
    snps_lappend spicedata "**** SUPPLIES ****"
    foreach key1 [array names supply] {
      snps_lappend spicedata ".param param_${key1} \= $supply($key1)"
      if { !$cargs(-no_supply_source) } {
      snps_lappend spicedata "V_pocv_${key1} ${key1} 0 DC param_$key1"
      snps_lappend spicedata ".global ${key1}"
      }
      if {  [string tolower $key1] eq "vss" } {
		set vss_defined 1
      }
    }
    if { ! $vss_defined } {
       snps_lappend spicedata ".param param_vss = $cargs(-vss)"
      if { !$cargs(-no_supply_source) } {
       snps_lappend spicedata "V_pocv_vss vss 0 DC param_vss"
       snps_lappend spicedata ".global pocv_vss"
       set supply(vss) 0.0
      }
    } 
    if { $pvdd eq "" } {
      puts "Warning: missing VDD value use -supply\n"
    }

    #### write out the sensitizations for each cell
    ## .param param_<cell>_${key} ...
    snps_lappend spicedata "******************************"
    snps_lappend spicedata "**** SENSITIZATION VECTOR ****"
    snps_lappend spicedata "******************************"
    foreach mcell [array names unique_cells] {
        # get output pin for each cell
  if { [defined -nocase outputs($mcell)] } {
    set output $outputs($mcell)
  } elseif { [defined -nocase outputs(-)] } {
    set output $outputs(-)
  } elseif { [defined -nocase cellarray(cell,$mcell,output)] } {
    set output $cellarray(cell,$mcell,output)
  } elseif { [defined -nocase cellarray(cell,-,output)] } {
    set output $cellarray(cell,-,output)
  } else {
    die "Error: could not determine output to use of cell: $mcell"
  }
        # check for user defined sensitization for cell sensitization(<cell>,<port>) <value>
    if { [defined -nocase sensitization($mcell)] } {
    foreach key1 [keys sensitization($mcell)] {
      if {[regexp "(\[^ \t\>\]+)\-\>(\[^ \t\>\]+)" $sensitization($mcell,$key1) dum value value2] } {
        snps_lappend spicedata "** ${mcell}_${key1} = $value -> $value2 **"
        snps_lappend spicedata ".param param_${mcell}_${key1}_1 \= $value"
        snps_lappend spicedata ".param param_${mcell}_${key1}_2 \= $value2"
        snps_lappend spicedata "V_${mcell}_${key1} ${mcell}_${key1} 0 PWL (0.0$cargs(-time_unit) param_${mcell}_${key1}_1 .1$cargs(-time_unit) param_${mcell}_${key1}_2)"
        snps_lappend spicedata ".global ${mcell}_${key1}"
      } elseif { [regexp "^\[ \t\]*(\[\-\.\+0-9\]+)\[ \t\]*" $sensitization($mcell,$key1) dum value] } {
        if  { $value  > 0.0 } {
          set value $supply($vdd)
        }
        snps_lappend spicedata "** ${mcell}_$key1 = $value **"
        snps_lappend spicedata ".param param_${mcell}_${key1} \= $value"
        snps_lappend spicedata "V_${mcell}_${key1} ${mcell}_${key1} 0 DC param_${mcell}_$key1"
        snps_lappend spicedata ".global ${mcell}_${key1}"
      }
    }
        # check for user defined sensitization for every cell
    } elseif { [defined -nocase sensitization(-)] } {
      foreach key1 [keys sensitization(-)] {
          set sensitization($mcell,[string tolower $key1]) $sensitization(-,$key1)
      if {[regexp "(\[^ \t\>\]+)\-\>(\[^ \t\>\]+)" $sensitization(-,$key1) dum value value2] } {
        snps_lappend spicedata "** ${mcell}_$key1 = $value -> $value2 **"
        snps_lappend spicedata ".param param_${mcell}_${key1}_1 \= $value"
        snps_lappend spicedata ".param param_${mcell}_${key1}_2 \= $value2"
        snps_lappend spicedata "V_${mcell}_${key1} ${mcell}_$key1 0 PWL (0.0$cargs(-time_unit) param_${mcell}_${key1}_1 .1$cargs(-time_unit) param_${mcell}_${key1}_2)"
        snps_lappend spicedata ".global $key1"
      } elseif { [regexp "^\[ \t\]*(\[\-\.\+0-9\]+)\[ \t\]*" $sensitization(-,$key1) dum value] } {
        if  { $value  > 0.0 } {
          set value $supply($vdd)
        }
        snps_lappend spicedata "** ${mcell}_$key1 = $value"
        snps_lappend spicedata ".param param_${mcell}_${key1} \= $value"
        snps_lappend spicedata "V_${mcell}_${key1} ${mcell}_$key1 0 DC param_${mcell}_$key1"
        snps_lappend spicedata ".global ${mcell}_$key1"
    }
      }
        # check for user defined sensitization from DB/lib data
    } elseif { [defined -nocase cellarray(cell,$mcell,pin,$output,sensitization)] } {
      foreach key1 [keys -nocase cellarray(cell,$mcell,pin,$output,sensitization] {
          set key2 $cellarray(cell,$mcell,pin,$output,sensitization,$key1,edge,r)
      while {[regexp "(\[^ \t\]+)\=(\[rR\]+)" $key2 dum port value] } {
        regsub "(\[^ \t\]+)\=(\[rR\]+)" $key2 {} key2
        if { ![defined cellarray(cell,-,supply,$port] && ![defined cellarray(cell,-,supply,[string tolower $port]] && ![defined cellarray(cell,$mcell,supply,$port] && ![defined cellarray(cell,$mcell,supply,[string tolower $port]] } {
          set value 0.0
          set value2 $supply($vdd)
          set sensitization($mcell,[string tolower $port]) "$value->$value2"
        snps_lappend spicedata "** ${mcell}_$key1 = $value -> $value2 **"
        snps_lappend spicedata ".param param_${mcell}_${key1}_1 \= $value"
        snps_lappend spicedata ".param param_${mcell}_${key1}_2 \= $value2"
        snps_lappend spicedata "V_${mcell}_${key1} ${mcell}_$key1 0 PWL (0.0$cargs(-time_unit) param_${mcell}_${key1}_1 .1$cargs(-time_unit) param_${mcell}_${key1}_2)"
        snps_lappend spicedata ".global ${mcell}_$key1"
        }
      }
      while  {[regexp "(\[^ \t\]+)\=(\[fF\]+)" $key2 dum port value] } {
        regsub "(\[^ \t\]+)\=(\[fF\]+)" $key2 {} key2
        if { ![defined cellarray(cell,-,supply,$port] && ![defined cellarray(cell,-,supply,[string tolower $port]] && ![defined cellarray(cell,$mcell,supply,$port] && ![defined cellarray(cell,$mcell,supply,[string tolower $port]] } {
          set value $supply($vdd)
          set value2 0
          set sensitization($mcell,[string tolower $port]) "$value->$value2"
        snps_lappend spicedata "** ${mcell}_$key1 = $value -> $value2 **"
        snps_lappend spicedata ".param param_${mcell}_${key1}_1 \= $value"
        snps_lappend spicedata ".param param_${mcell}_${key1}_2 \= $value2"
        snps_lappend spicedata "V_${mcell}_${key1} ${mcell}_$key1 0 PWL (0.0$cargs(-time_unit) param_${mcell}_${key1}_1 .1$cargs(-time_unit) param_${mcell}_${key1}_2)"
        snps_lappend spicedata ".global ${mcell}_$key1"
        }
      }
      set delay {}
      while  {[regexp "(\[^ \t\]+)\=\[\!\]+\[ \t\]*(\[^ \t\:\}\]+)\[:\]*(\[0-9\.\]*)" $key2 dum port value delay] } {
        regsub "\[^ \t\]+\=\[\!\]+\[ \t\]*\[^ \t\:\}\]+\[:\]*\[0-9\.\]*" $key2 {} key2
        if { ![defined cellarray(cell,-,supply,$port] && ![defined cellarray(cell,-,supply,[string tolower $port]] && ![defined cellarray(cell,$mcell,supply,$port] && ![defined cellarray(cell,$mcell,supply,[string tolower $port]] } {
	  if { $delay ne "" } {
          set sensitization($mcell,[string tolower $port]) "\!$value\:$delay"   
            # no param as value is another pin
	  } else {
          set sensitization($mcell,[string tolower $port]) "\!$value"
            # no param as value is another pin
	  }
        }
      }
      set delay {}
      while {[regexp "(\[^ \t\]+)\=(\[^ \t\:\}\]+)\[:\]*(\[0-9\.\]*)" $key2 dum port value delay]} {
        regsub "\[^ \t\]+\=\[^ \t\:\}\]+\[:\]*\[0-9\.\]*" $key2 {} key2
        if { ![defined cellarray(cell,-,supply,$port] && ![defined cellarray(cell,-,supply,[string tolower $port]] && ![defined cellarray(cell,$mcell,supply,$port] && ![defined cellarray(cell,$mcell,supply,[string tolower $port]] } {
          if { $value eq "1" } {
            set value $supply($vdd)
          }
	  if { $delay ne "" } {
          set sensitization($mcell,[string tolower $port]) "$value\:$delay"
	  } else {
          set sensitization($mcell,[string tolower $port]) $value
          if { [regexp "^\[0-9\.\-\]+$" $value] } {
        snps_lappend spicedata "** ${mcell}_$key1 = $value **"
        snps_lappend spicedata ".param param_${mcell}_${key1} \= $value"
        snps_lappend spicedata "V_${mcell}_${key1} ${mcell}_$key1 0 DC param_${mcell}_${key1}"
        snps_lappend spicedata ".global ${mcell}_$key1"
          }
      }
        }
      }
      while {[regexp "(\[^ \t\]+)\=(\[^ \t\>\]+)\-\>(\[^ \t\>\}\]+)" $key2 dum port value value2] } {
        regsub "(\[^ \t\]+)\=(\[^ \t\>\]+)\-\>(\[^ \t\>\}\]+)" $key2 {} key2
        if { ![defined cellarray(cell,-,supply,$port] && ![defined cellarray(cell,-,supply,[string tolower $port]] && ![defined cellarray(cell,$mcell,supply,$port] && ![defined cellarray(cell,$cell,supply,[string tolower $port]] } {
          if { $value eq "1" } {
            set value $supply($vdd)
          }
          if { $value2 eq "1" } {
            set value2 $supply($vdd)
          }
          set sensitization($mcell,[string tolower $port]) "$value->$value2"
        snps_lappend spicedata "** ${mcell}_$key1 = $value -> $value2 **"
        snps_lappend spicedata ".param param_${mcell}_${key1}_1 \= $value"
        snps_lappend spicedata ".param param_${mcell}_${key1}_2 \= $value2"
        snps_lappend spicedata "V_${mcell}_${key1} ${mcell}_$key1 0 PWL (0.0$cargs(-time_unit) param_${mcell}_${key1}_1 .1$cargs(-time_unit) param_${mcell}_${key1}_2)"
        snps_lappend spicedata ".global ${mcell}_$key1"
        }
      }
      }
        # check for generic sensitization used for any cell
    } elseif { [defined -nocase cellarray(cell,-,sensitization)] } {
      foreach key1 [array names cellarray(cell,-,sensitization)] {
          set sensitization($mcell,[string tolower $key1]) $cellarray(cell,-,sensitization,$key1)
      if {[regexp "(\[^ \t\>\]+)\-\>(\[^ \t\>\}\]+)" $cellarray(cell,-,sensitization,$key1) dum value value2] } {
        snps_lappend spicedata "** ${mcell}_$key1 = $value -> $value2 **"
        snps_lappend spicedata ".param param_${mcell}_${key1}_1 \= $value"
        snps_lappend spicedata ".param param_${mcell}_${key1}_2 \= $value2"
        snps_lappend spicedata "V_${mcell}_${key1} ${mcell}_$key1 0 PWL (0.0$cargs(-time_unit) param_${mcell}_${key1}_1 .1$cargs(-time_unit) param_${mcell}_${key1}_2)"
        snps_lappend spicedata ".global ${mcell}_$key1"
      } elseif { [regexp "^\[ \t\]*(\[\-\.\+0-9\]+)\[ \t\]*" $cellarray(cell,-,sensitization,$key1) dum value] } {
        snps_lappend spicedata "** ${mcell}_$key1 = $cellarray(cell,-,sensitization,$key1) **"
        snps_lappend spicedata ".param param_${mcell}_${key1} \= $cellarray(cell,-,sensitization,$key1)"
        snps_lappend spicedata "V_${mcell}_${key1} ${mcell}_$key1 0 DC param_${mcell}_$key1"
        snps_lappend spicedata ".global ${mcell}_$key1"
      }
      }
   }
  if { [defined -nocase ic($mcell)] } {
  } elseif { [defined -nocase ic(-)] } {
    foreach key1 [keys ic(-)] {
      set value1 $ic(-,$key1)
      if { $value1 eq "1" } {
        set ic($mcell,[string tolower $key1]) $supply($vdd)
      } else {
        set ic($mcell,[string tolower $key1]) $value1
      }
    }
  } elseif { [defined -nocase cellarray(cell,-,ic)] } {
    foreach key1 [keys cellarray(cell,-,ic)] {
      set value1 $cellarray(cell,-,ic,$key1)
      if { $value1 eq "1" } {
        set ic($mcell,[string tolower $key1]) $supply($vdd)
      } else {
        set ic($mcell,[string tolower $key1]) $value1
      }
    }
  }
   }
    snps_lappend spicedata "*"
    snps_lappend spicedata "******************************"
    ####

    #snps_lappend spicedata ".global vss vdd gnd vcc"
    snps_lappend spicedata ".prot"
    #### depending on variation mode may have to add global/local param definitions
    # directly include spice cells when cargs(-nmos_only) && cargs(-pmos_only) or  cargs(-variation_mode) ignore_off
    if {($cargs(-local_params) ne "") || ($cargs(-global_params) ne "") } {
      foreach key1 $cargs(-local_params) {
        while { [regexp "(\[^ \t\]+)\[ \t\]*=\[ \t\]*(\[AaGgUuSs\(\,\. 0-9\(\]+\[\)\])" $key1 dum param value] } {
			
          regsub -all "(\[^ \t\]+)\[ \t\]*=\[ \t\]*(\[AaGgUuSs\(\,\. 0-9\(\]+\[\)\])" $key1 {} key1
          snps_lappend spicedata ".param $param = $value"
        }
      }
      foreach key1 $cargs(-global_params) {
        while { [regexp "(\[^ \t\]+)\[ \t\]*=\[ \t\]*(\[AaGgUuSs\(\,\. 0-9\(\]+\[\)\])" $key1 dum param value] } {
			
          regsub -all "(\[^ \t\]+)\[ \t\]*=\[ \t\]*(\[AaGgUus\(\,\. 0-9\(\]+\[\)\])" $key1 {} key1
          snps_lappend spicedata ".param $param = $value"
        }
      }
    }

    #### depending on variation mode may have to modify spice subckt and append to spice deck.
    if {($cargs(-variation_mode) eq "ignore_off") || $cargs(-nmos_only) || $cargs(-pmos_only) } {
      foreach mcell [array names unique_cells] {
      foreach key1 [keys sensitization($mcell)]  {
	# is key1 == transistor instance?
        if {[regexp "\[ \t\]*\[\-\.\+0-9\]+\[ \t\]*$" $sensitization($mcell,$key1)]} {
          if { $sensitization($mcell,$key1) < .10 } {
            #add gate driven nfets.
            set ignore_inst($key1) 1
          } else {
            #add gate driven pfets.
            set ignore_inst($key1) 1
          }
        }
      }
      }
	set files {}
    set no_spice_cells 1
    foreach mcell [array names unique_cells] {
    if { [defined cellarray(cell,$mcell,spice_deck)] } {
      foreach line $cellarray(cell,$mcell,spice_deck)  {
        if {[regexp "^\[ \t\]*(\[XxMm\]\[^ \t\]*)\[ \t\]*(\[^ \t\]+)\[ \t\]*(\[^ \t\]+)\[ \t\]*(\[^ \t\]+)\[ \t\]*(\[^ \t\]+)\[ \t\]*(\[^ \t\]+)" $line dum key1 key2 key3 key4 key5 key6]} {
	  if {$cargs(-pmos_only) && [regexp "nmos|nfet|nch"  $key6]} {
            snps_lappend spicedata "$line $cargs(-disable_local_params)"
	  } elseif {$cargs(-nmos_only) && [regexp "pmos|pfet|pch"  $key6]} {
            snps_lappend spicedata "$line $cargs(-disable_local_params)"
          } elseif {[info exists ignore_inst($key1)]} {
            snps_lappend spicedata "$line $cargs(-disable_local_params)"
          } else {
            snps_lappend spicedata $line
          }
        } else {
          snps_lappend spicedata $line
        }
      }
	} elseif {[defined cellarray(cell,$mcell,spice_file)]} {
		lappend files $cellarray(cell,$mcell,spice_file)
	} elseif { $no_spice_cells }  {
		lappend files $cargs(-spice_cells)
        set no_spice_cells 0
    }
    } 
    if {[llength $files] < 1 } {
		set files $cargs(-spice_cells)
	}
        foreach file $files {
	    set fin [open $file]
          while {1 } {
             set line [gets $fin]
             if { [eof $fin]  } {
                 close $fin
                 break
             }
        if {[regexp "^\[ \t\]*(\[XxMm\]\[^ \t\]*)\[ \t\]*(\[^ \t\]+)\[ \t\]*(\[^ \t\]+)\[ \t\]*(\[^ \t\]+)\[ \t\]*(\[^ \t\]+)\[ \t\]*(\[^ \t\]+)" $line dum key1 key2 key3 key4 key5 key6]} {
	  if {$cargs(-pmos_only) && [regexp "nmos|nfet|nch"  $key6]} {
            snps_lappend spicedata "$line $cargs(-disable_local_params)"
	  } elseif {$cargs(-nmos_only) && [regexp "pmos|pfet|pch"  $key6]} {
            snps_lappend spicedata "$line $cargs(-disable_local_params)"
          } elseif {[info exists ignore_inst($key1)]} {
            snps_lappend spicedata "$line $cargs(-disable_local_params)"
          } else {
            snps_lappend spicedata $line
          }
        } else {
          snps_lappend spicedata $line
        }
	 }
      }
    } else {
      if { $cargs(-inc_spice_cells) } {
        foreach key1 [split [regsub -all "\[ \t\]+" [string trim [join $cargs(-spice_cells)]] { }]]  {
          if { ![regexp "^\[ \t\]*\/" $key1] } {
            snps_lappend spicedata ".inc \'$cargs(-spice_cells_dir)/$key1\'"
          } else {
            snps_lappend spicedata ".inc \'$key1\'"
          }
        }
      }
    }

    #### include the subckt spice decks
    if { $cargs(-ref_spice_model) ne "" } {
        foreach key1 [split [regsub -all "\[ \t\]+" [string trim [join $cargs(-ref_spice_model)]] { }]]  {
	while { [regexp "^\[ \t\]*{(\[.\]+)}\[ \t\]*$" $key1 key2] } {
		regsub "^\[ \t\]*{(\[.\]+)}\[ \t\]*$" $key1 $key2 key1
	}
    if { ![regexp "^\[ \t\]*\/" $key1] } {
      snps_lappend spicedata ".inc \'$cargs(-spice_cells_dir)/$key1\'"
    } else {
      snps_lappend spicedata ".inc \'$key1\'"
    }
    	snps_lappend spicedata ".option mcbrief=1" 
	}
    } elseif { $cargs(-ref_spice_lib) ne "" } {
	set key1 [string trim $cargs(-ref_spice_lib)]
	if { [regexp "\{\[^\{\}\]+\}" $key1] } {
	while { [regexp "\{(\[^\{\}\]+)\}" $key1 dum key2] } {
		regsub "\{\[^\{\}\]+\}" $key1 {} key1
		snps_lappend spicedata "$key2"
	}
	} else {
	foreach key2 $key1 {
		snps_lappend spicedata "$key2"
        }
	}
        #foreach key1 [split [regsub -all "\[ \t\]+" [string trim [join $cargs(-ref_spice_lib)]] { }]]  {
	#while { [regexp "^\[ \t\]*{(\[.\]+)}\[ \t\]*$" $key1 key2] } {
	#	regsub "^\[ \t\]*{(\[.\]+)}\[ \t\]*$" $key1 $key2 key1
	#}
    	#}
    } elseif { $cargs(-spice_model) ne "" } {
        foreach key1 [split [regsub -all "\[ \t\]+" [string trim [join $cargs(-spice_model)]] { }]]  {
	while { [regexp "^\[ \t\]*{(\[.\]+)}\[ \t\]*$" $key1 key2] } {
		regsub "^\[ \t\]*{(\[.\]+)}\[ \t\]*$" $key1 $key2 key1
	}
    if { ![regexp "^\[ \t\]*\/" $key1] } {
      snps_lappend spicedata ".inc \'$cargs(-spice_cells_dir)/$key1\'"
    } else {
      snps_lappend spicedata ".inc \'$key1\'"
    }
	}
    snps_lappend spicedata ".option mcbrief=1" 
    } elseif { $cargs(-spice_lib) ne "" } {
	set key1 [string trim $cargs(-spice_lib)]
	if { [regexp "\{\[^\{\}\]+\}" $key1] } {
	while { [regexp "\{(\[^\{\}\]+)\}" $key1 dum key2] } {
		regsub "\{\[^\{\}\]+\}" $key1 {} key1
		snps_lappend spicedata "$key2"
	}
	} else {
	foreach key2 $key1 {
		snps_lappend spicedata "$key2"
        }
	}
        #foreach key1 [split [regsub -all "\[ \t\]+" {
	#while { [regexp "^\[ \t\]*{(\[.\]+)}\[ \t\]*$" $key1 key2] } {
		#regsub "^\[ \t\]*{(\[.\]+)}\[ \t\]*$" $key1 $key2 key1
	#}
    	#}
    }

    snps_lappend spicedata ".option measdgt=$cargs(-sig_digits)"

    #### include some general .option cmds and any users supplied ones.
    snps_lappend spicedata ".unprot"
    snps_lappend spicedata ".option nopage nomod acct autostop noprobe"
    snps_lappend spicedata ".option LENNAM=1024"
    snps_lappend spicedata ".option dcon=1"
    snps_lappend spicedata ".option converge=1"
    if { $cargs(-accurate) } {
      snps_lappend spicedata ".option accurate"
    }
    if { $cargs(-spice_options) ne "" } {
      foreach key1 $cargs(-spice_options) {
      snps_lappend spicedata ".option $key1"
      }
    }

    

 #### START THE CELL CHAIN LOOP  ####
    lappend rcpts "in#1"
    lappend meas_pts "in#1"
    lappend comp_meas_pts "in#1"
    set start 1
    # iterate thru all the cells in the cell_list(max_logic_depth + predrvr_cell_cnt + 2)
    for {set j $start} {$j<=[expr $cargs(-max_logic_depth) + 2 + $cargs(-add_predrvr_cnt)]} {incr j} {
        # grab the next cell from the cell_list
      set cell [lindex $cell_list [expr $j - 1]]

  #### find the appropriate input/output/comp_output
  ##        add cell based support input/output/comp_output(<cellname>) ...
  if { [defined -nocase inputs($cell)] } {
    set input $inputs($cell)
  } elseif { [defined -nocase inputs(-)] } {
    set input $inputs(-)
  } elseif { [defined -nocase cellarray(cell,$cell,input)] } {
    set input $cellarray(cell,$cell,input)
  } elseif { [defined -nocase cellarray(cell,-,input)] } {
    set input $cellarray(cell,-,input)
  } else {
    die "Error: could not determine input to use of cell: $cell"
  }
  if { [defined -nocase outputs($cell)] } {
    set output $outputs($cell)
  } elseif { [defined -nocase outputs(-)] } {
    set output $outputs(-)
  } elseif { [defined -nocase cellarray(cell,$cell,output)] } {
    set output $cellarray(cell,$cell,output)
  } elseif { [defined -nocase cellarray(cell,-,output)] } {
    set output $cellarray(cell,-,output)
  } else {
    die "Error: could not determine output to use of cell: $cell"
  }
  if { [defined -nocase comp_outputs($cell)] } {
    set comp_output $comp_outputs($cell)
  } elseif { [defined -nocase comp_outputs(-)] } {
    set comp_output $comp_outputs(-)
  } elseif { [defined -nocase cellarray(cell,$cell,comp_output)] } {
    set comp_output $cellarray(cell,$cell,comp_output)
  } elseif { [defined -nocase cellarray(cell,-,comp_output)] } {
    set comp_output $cellarray(cell,-,comp_output)
  } else {
       set comp_output ""
  }

  if { [defined -nocase mis_inputs($cell)] } {
    set mis_input [string tolower $mis_inputs($cell)]
  } elseif { [defined -nocase mis_inputs(-)] } {
    set mis_input [string tolower $mis_inputs(-)]
  } else {
  set mis_input {}
  }

    if { $mis_input ne "" } {
     puts "   MIS_INPUTS: $mis_input"
    }

  ### add cell based support port_list(<cellname>) ...
  if { [defined -nocase port_lists($cell)] } {
      set port_list $port_lists($cell)
  } elseif { [defined -nocase port_lists(-)] } {
      set port_list $port_lists(-)
  } elseif { [defined -nocase cellarray(cell,$cell,port_list)] } {
    set port_list $cellarray(cell,$cell,port_list)
  } elseif { [defined -nocase cellarray(cell,-,port_list)] } {
    set port_list $cellarray(cell,-,port_list)
  } else {
    die "Error: missing port list for cell $cell"
  }


  # needs to be done on a per cell basis
  ## get/set cell input_pin_cap
	if { [defined -nocase cellarray(cell,__copt__,pin,$input,capacitance)] } {
	set input_pin_cap $cellarray(cell,__copt__,pin,$input,capacitance)
	} elseif { [defined -nocase cellarray(cell,$cell,pin,$input,capacitance)] } {
	set input_pin_cap $cellarray(cell,$cell,pin,$input,capacitance)
        } elseif { [defined -nocase cellarray(cell,-,capacitance)] } {
	set input_pin_cap $cellarray(cell,-,capacitance)
	} else {
	set input_pin_cap 0.0
	}
  ## get/set cell fanout_cap
  if { $cargs(-no_predrvr_load) && ($j <= $cargs(-add_predrvr_cnt)) } {
    set max_fanout_cap 0
  } elseif { [regexp "real_cell" $cargs(-fanout_cap_mode)] } {
    set max_fanout_cap -1
  } elseif { [regexp "input" $cargs(-fanout_cap_mode)] } {
    set max_fanout_cap [expr [expr $cargs(-stage_fanout) - 1] * $input_pin_cap]
  } else {
    if {[defined -nocase cellarray(cell,__copt__,max_capacitance)]} {
      set max_fanout_cap $cellarray(cell,__copt__,max_capacitance)
    } elseif {[defined -nocase cellarray(cell,$cell,pin,$output,max_capacitance)]} {
       set max_fanout_cap $cellarray(cell,$cell,pin,$output,max_capacitance)
    } elseif {[defined -nocase cellarray(cell,-,max_capacitance)]} {
      set max_fanout_cap $cellarray(cell,-,max_capacitance)
    } else {
      set max_fanout_cap 0
    }
    if { $cargs(-max_fanout_cap_pct) < 1 } {
      set cargs(-fanout_cap_mode) "max_fanout_cap_pct"
    }
  }
  
  if { $cargs(-debug) } {
  puts "   CELL_INPUT_PIN_CAP: $input_pin_cap for CELL: $cell"
  puts "   MAX_CAP: $max_fanout_cap for CELL: $cell"
  puts "   MAX_CAP_PCT: $cargs(-max_fanout_cap_pct) for CELL: $cell $max_fanout_cap_index [lindex $cargs(-max_fanout_cap_pct) $max_fanout_cap_index]"
  puts "   MAX_CAP_MODE: $cargs(-fanout_cap_mode) for CELL: $cell"
  puts "   STAGE_FANOUT: $cargs(-stage_fanout) for CELL: $cell"
  }
  if { ![regexp "input" $cargs(-fanout_cap_mode)] && ![regexp "real_cell" $cargs(-fanout_cap_mode)] } {
  if { ($max_fanout_cap > 0) && ($cargs(-predrvr_max_fanout_cap_pct) ne "" ) && ($j <= $cargs(-add_predrvr_cnt)) } {
    if { $predrvr_max_fanout_cap_index  >= [llength $cargs(-predrvr_max_fanout_cap_pct)] } {
	set predrvr_max_fanout_cap_index 0
    }
    set max_fanout_cap [expr $max_fanout_cap * [lindex $cargs(-predrvr_max_fanout_cap_pct) $predrvr_max_fanout_cap_index]]
    incr predrvr_max_fanout_cap_index
  } elseif { ($max_fanout_cap > 0) && ($cargs(-fanout_cap_mode) eq "max_fanout_cap_pct")} {
    if { $max_fanout_cap_index  >= [llength $cargs(-max_fanout_cap_pct)] } {
	set max_fanout_cap_index 0
    }
    set max_fanout_cap [expr $max_fanout_cap * [lindex $cargs(-max_fanout_cap_pct) $max_fanout_cap_index]]
    incr max_fanout_cap_index
    
  if { $cargs(-debug) } {
    puts "   SCALED_MAX_CAP: $max_fanout_cap for CELL: $cell"
  }
  }
  }

  #check to make sure max cap does not exceed the max_cap of the cell
  if { ($max_fanout_cap > 0 ) && [defined -nocase cellarray(cell,$cell,pin,$output,max_capacitance)] && ($max_fanout_cap > $cellarray(cell,$cell,pin,$output,max_capacitance)) } {
    puts "Error: $max_fanout_cap > maximum capacitance($cellarray(cell,$cell,pin,$output,max_capacitance) allowed on pin: $output of cell $cell"
    exit
  }


  ## subtract out the pin cap from the scaled max fanout cap
  if { ($max_fanout_cap > 0)} {
    if { [regexp "real_cell" $cargs(-fanout_cap_mode)] } {
      set max_fanout_cap [expr double($max_fanout_cap - $input_pin_cap * $cargs(-stage_fanout))]
    } elseif { [regexp "input" $cargs(-fanout_cap_mode)] && ( $cargs(-stage_fanout) > 1) } {
      #set max_fanout_cap [expr double($max_fanout_cap - $input_pin_cap * 1)]
    } else {
      set max_fanout_cap [expr double($max_fanout_cap - $input_pin_cap * 1)]
    }
  if { $cargs(-debug) } {
    puts "   PIN_CAP: $input_pin_cap for cell: $cell"
    puts "   SCALED_MAX_CAP_MINUS_PIN_CAP: $max_fanout_cap for cell: $cell"
  }
    if { [regexp "input" $cargs(-fanout_cap_mode)] && ($cargs(-stage_fanout) > 1)} {
    set max_fanout_cap [expr double($max_fanout_cap/[expr $cargs(-stage_fanout) - 1]) ]
    } elseif { ![regexp "real_cell" $cargs(-fanout_cap_mode)]} {
    set max_fanout_cap [expr double($max_fanout_cap/$cargs(-stage_fanout)) ]
    }
  if { $cargs(-debug) } {
    puts "   SCALED_MAX_CAP_MINUS_PIN_CAP_PER_STAGE_FANOUT: $max_fanout_cap for cell: $cell"
  }
  } else {
  }

    #get max trans for cell hash
    if {[defined -nocase cellarray(cell,__copt__,max_transition)] } {
      set max_trans $cellarray(cell,__copt__,max_transition)
    } elseif {[defined -nocase cellarray(cell,$cell,pin,$input,max_transition)] } {
      set max_trans $cellarray(cell,$cell,pin,$input,max_transition)
    } elseif {[defined -nocase cellarray(cell,-,max_transition)] } {
      set max_trans $cellarray(cell,-,max_transition)
    } else {
      set max_trans .1
    }

    #get max trans for cell hash
    if {[defined -nocase cellarray(cell,__copt__,max_fall_transition)] } {
      set max_trans_fall $cellarray(cell,__copt__,max_transition)
    } elseif {[defined -nocase cellarray(cell,$cell,pin,$input,max_transition)] } {
      set max_trans_fall $cellarray(cell,$cell,pin,$input,max_transition)
    } elseif {[defined -nocase cellarray(cell,-,max_fall_transition)] } {
      set max_trans_fall $cellarray(cell,-,max_transition)
    } else {
      set max_trans_fall .1
    }

  if { ([string tolower $cargs(-time_unit)] eq "ps") && ($max_trans < 1) } {
        puts "Warning:  converting max_trans to PS"
        set max_trans [expr $max_trans * 1000]
  } elseif { ([string tolower $cargs(-time_unit)] eq "ns") && ($max_trans > 1) } {
        puts "Warning:  converting max_trans to NS"
        set max_trans [expr $max_trans / 1000]
  }
  if { ([string tolower $cargs(-time_unit)] eq "ps") && ($max_trans_fall < 1) } {
        puts "Warning:  converting max_trans_fall to PS"
        set max_trans_fall [expr $max_trans_fall * 1000]
  } elseif { ([string tolower $cargs(-time_unit)] eq "ns") && ($max_trans_fall > 1) } {
        puts "Warning:  converting max_trans_fall to NS"
        set max_trans_fall [expr $max_trans_fall / 1000]
  }


  if { $cargs(-debug) } {
  puts "   MAX_TRANS_RISE: $max_trans for cell: $cell"
  puts "   MAX_TRANS_FALL: $max_trans_fall for cell: $cell"
  puts "   MAX_TRANS_PCT: $cargs(-max_fanin_trans_pct) for cell: $cell"
  puts "   MAX_TRANS_MODE: $cargs(-fanin_trans_mode) for cell: $cell"
  }

  if { $cargs(-fanin_trans_mode) eq "max_fanin_trans_pct"} {
    set max_trans [expr double($max_trans * $cargs(-max_fanin_trans_pct))]
    set max_trans_fall [expr double($max_trans_fall * $cargs(-max_fanin_trans_pct))]
  if { $cargs(-debug) } {
    puts "   SCALED_MAX_TRANS_RISE: $max_trans for cell: $cell"
    puts "   SCALED_MAX_TRANS_FALL: $max_trans_fall for cell: $cell"
  }
  }

  #### find appropriate max_trans and max_trans_fall
  ##          check to make sure max trans does not exceed the max_trans of the cell
  if {[defined -nocase cellarray(cell,$cell,pin,$input,max_transition)] } {
    if { $max_trans > $cellarray(cell,$cell,pin,$input,max_transition) } {
      puts "Error: $max_trans > maximum transition: $cellarray(cell,$cell,pin,$input,max_transition) allowed on pin: $input of cell $cell"
      exit
    }
    if { $max_trans_fall > $cellarray(cell,$cell,pin,$input,max_transition) } {
      puts "Error: $max_trans_fall > maximum transition: $cellarray(cell,$cell,pin,$input,max_transition) allowed on pin: $input of cell $cell"
      exit
    }
  }
  ## TBD: add a check for max_fall_trans?

  set max_trans [expr double($max_trans/($upper_slew - $lower_slew))]
  set max_trans_fall [expr double($max_trans_fall/($upper_slew - $lower_slew))]
  if { [defined -nocase cellarray(slew_derate_from_library)] } {
    if { $cargs(-debug) } {
    puts "   SLEW DERATE: $cellarray(slew_derate_from_library) for cell: $cell"
    }
    set max_trans [expr double($max_trans * $cellarray(slew_derate_from_library))]
    set max_trans_fall [expr double($max_trans_fall * $cellarray(slew_derate_from_library))]
  }
  if { $cargs(-debug) } {
  puts "   FULLSWING_MAX_TRANS_RISE: $max_trans for cell: $cell"
  puts "   FULLSWING_MAX_TRANS_FALL: $max_trans_fall for cell: $cell"
  }
  

    ##############################################################################
    ##############################################################################
    #### start the loop to generate SPICE decks, iterate per logic depth level
    ##############################################################################

      if { [array exists inst_ports] } {
        array unset inst_ports
      }
      set input [string tolower $input]
      set output [string tolower $output]
      if { $comp_output  ne "" } {
      set comp_output [string tolower $comp_output]
      }


    #  if { $j > 0 } {
      snps_lappend spicedata  "* POCV test circuit for logic_depth = $j stage_fanout = $cargs(-stage_fanout)"
      puts  "* POCV test circuit for logic_depth = $j stage_fanout = $cargs(-stage_fanout)"
    #  } else {
    #  snps_lappend spicedata  "* pre-drive cell POCV test circuit"
    #  puts  "* pre-drive cell for POCV test circuit"
    #  }
    
       # instance name for level $j
      set inst "X${j}_F#1"
      set cmd "X${j}_F#1"
      set m [expr $j -1 ]

      # process all the ports of the cell
      set has_input_conn {}
      set has_output_conn {}
      foreach key1 $port_list  {
        set lkey1 [string tolower $key1]
        
        # if port == input
        if { $input eq $lkey1 } {
          if {$j <= 1} {
            if {$cargs(-rcseg) > 0} {
              lappend rcpts "$inst:$key1"
              set inst_ports($key1) "$inst:$key1"
	      set has_input_conn  "$inst:$key1"
            } else {
	      #if { $j <= 0 } {
          #    set inst_ports($key1) "pre_in#[expr 1 - $j]"
	      #} else {
              set inst_ports($key1) "in#1"
	      set has_input_conn  "in#1"
	      #}
            }
          } elseif {$j > 1} {
	    if { $m > [expr $cargs(-max_logic_depth) + $cargs(-add_predrvr_cnt)]} {
            if {$comp_output ne ""} {
              lappend comp_meas_pts "toutc#$m"
              lappend comp_rcpts "toutc#$m"
            }
            lappend meas_pts "tout#$m"
            lappend rcpts "tout#$m"
            set inst_ports($key1) "tout#$m"
	    set has_input_conn  "tout#$m"
	    } else {
            if {$comp_output ne ""} {
              lappend comp_meas_pts "outc#$m"
              lappend comp_rcpts "outc#$m"
            }
            lappend meas_pts "out#$m"
            lappend rcpts "out#$m"
            set inst_ports($key1) "out#$m"
	    set has_input_conn  "out#$m"
	    }
          }
        # if port == output
        } elseif { $output eq $lkey1 } {
          if { $cargs(-rcseg) > 0 } {
            set inst_ports($key1) "$inst:$key1"
            set next_rcpt "$inst:$key1"
	    set has_output_conn "$inst:$key1"
          } else {
	    #if { $j < 0 } {
        #    set inst_ports($key1) "pre_in#[expr 1 - $j - 1]"
        #    set next_rcpt "pre_in#[expr 1 - $j - 1]"
	    #} elseif { $j == 0 } {
        #    set inst_ports($key1) "in#1"
        #    set next_rcpt "in#1"
	    #} else {
	    if { $j > [expr $cargs(-max_logic_depth) + $cargs(-add_predrvr_cnt)]} {
            set inst_ports($key1) "tout#$j"
            set next_rcpt "tout#$j"
	    set has_output_conn "tout#$j"
	    } else {
            set inst_ports($key1) "out#$j"
            set next_rcpt "out#$j"
	    set has_output_conn "out#$j"
	    }
	    #}
          }
        # if port == comp_output
        } elseif { ($comp_output ne "") && $comp_output eq $lkey1 } {
          if { $cargs(-rcseg) > 0 } {
            set inst($key1) "$inst:$key1"
            set inst_ports($key1) "$inst:$key1"
            set next_comp_rcpt "$inst:$key1"
          } else {
	    #if { $j == 0 } {
        #    set inst_ports($key1) "$inst:$key1"
	    #} else {
	    if { $j > [expr $cargs(-max_logic_depth) + $cargs(-add_predrvr_cnt)]} {
            set inst_ports($key1) "toutc#$j"
            set next_comp_rcpt "toutc#$j"
	    } else {
            set inst_ports($key1) "outc#$j"
            set next_comp_rcpt "outc#$j"
	    }
	    #}
          }
        } elseif { [info exists supply($lkey1)] } {
          #append cmd  " $key1"
	  if { $cargs(-no_supply_source) } {
          set inst_ports($key1) "$key1"
	  } else {
          set inst_ports($key1) "pocv_${key1}"
	  }
        } else {
          #append cmd " $inst:$key1"
          set inst_ports($key1) "$inst:$key1"
        }
      }
      if { $has_output_conn eq "" } {
		puts "Error: has no output connection point to portlist: $port_list --> $cmd"	
		return 0
      }
      if { $has_input_conn eq "" } {
		puts "Error: has no input connection point to portlist: $port_list --> $cmd"	
		return 0
      }
      #process port list looking to sensitization data
      foreach key1 $port_list  {
        set lkey1 [string tolower $key1]
	#check for mis 
	if { ([llength $mis_input] > 0) && ([lsearch -exact $mis_input $lkey1] > -1) }  {
        #check for sensitization input, function of input & output	
		append cmd " $inst:$key1"
		lappend esrc "E$inst:$key1 $inst:$key1 0 $has_input_conn 0 1"
        } elseif { [info exists sensitization($cell,$lkey1)]} {
		if { [regexp "^\[xX\]$" $sensitization($cell,$lkey1)] } {
			puts "Error: Sensitization undeterminable for CELL: $cell PORT: $key1 SENSE: $sensitization($cell,$lkey1)"
			snps_lappend spicedata ".end"
			return 0
		}
		  if {[regexp "^\[ \t\]*\[\-\.\+0-9\]+\-\>\[\-\.\+0-9\]+\[ \t\]*$" $sensitization($cell,$lkey1)]} {
			# sensitization is set through a param for that cell
		    append cmd  " ${cell}_$key1"
		  } elseif {[regexp "^\[ \t\]*\[\-\.\+0-9\]+\[ \t\]*$" $sensitization($cell,$lkey1)]} {
		    append cmd " ${cell}_$key1"
		  } else {
		    set found 0
		    foreach key2 $port_list  {
		      if {[regexp -nocase "^\[ \t\]*\[\!\]\[ \t\]*$key2\[\:\]*(\[\.0-9\]*)$" $sensitization($cell,$lkey1) dum delay]} {
			# sensitization is set through a DELAYed inverting connection to another port of the cell
			append cmd " $inst:$key1"
			if { $delay ne "" } {
			lappend esrc "E$inst:$key1 $inst:$key1:del $vdd $inst_ports($key2) 0 -1"
			lappend esrc "E$inst:$key1:del $inst:$key1 0 DELAY $inst:$key1:del 0 TD=$delay$cargs(-time_unit)"
			} else {
			lappend esrc "E$inst:$key1 $inst:$key1 $vdd $inst_ports($key2) 0 -1"
			}
			set found 1
			break
		      } elseif {[regexp -nocase "^\[ \t\]*$key2\[ \t\]*\[\:\]*(\[\.0-9\]*)$" $sensitization($cell,$lkey1) dum delay]} {
			# sensitization is set through a DELAYed non-inverting connection to another port of the cell
			if { $delay ne "" } {
			lappend esrc "E$inst:$key1 $inst:$key1:del 0 $inst_ports($key2) 0 1"
			lappend esrc "E$inst:$key1:del $inst:$key1 0 DELAY $inst:$key1:del 0 TD=$delay$cargs(-time_unit)"
			} else {
			lappend esrc "E$inst:$key1 $inst:$key1 0 $inst_ports($key2) 0 1"
			}
			append cmd " $inst:$key1"
			set found 1
			break
		      }
		    }
		    if {!$found} {
			# sensitization is set through whatever is set for that port
		      append cmd  " $sensitization($cell,$lkey1)"
		    }
		  }
	} else {
	  append cmd  " $inst_ports($key1)"
	}
      }

        # check if predriver variation is disabled
	      if {($j <= $cargs(-add_predrvr_cnt)) && $cargs(-no_predrvr_variation) && ($cargs(-disable_predrvr_local_params) ne "")} {
	      snps_lappend spicedata "$cmd $cell $cargs(-disable_predrvr_local_params)"
	      } else {
	      snps_lappend spicedata "$cmd $cell"
	      }
	      #process port list looking to apply .ic to inst
	      foreach key1 $port_list  {
		set lkey1 [string tolower $key1]
		if { [info exists ic($cell,$lkey1)] } {
		  snps_lappend spicedata ".ic $inst_ports($key1) $ic($cell,$lkey1)"
		}
	      }
	      if { [defined esrc] } {
		foreach item $esrc {
		  snps_lappend spicedata "$item"
		}
		unset esrc
	      }
	      set cmd ""
	      if { [array exists inst_ports] } {
		array unset inst_ports
	      }
	      
	      # process/determing cap loading on main path pin
	     
	      if { ($max_fanout_cap > 0 ) && ![regexp "input" $cargs(-fanout_cap_mode)]} {
		  if { $cargs(-rcseg) <= 0 } {
		  if {$j <= -1} {
		    snps_lappend spicedata [format "C_$inst pre_in#[expr 0 - $j] 0 %.6f$cargs(-cap_unit)\n" $max_fanout_cap]
		    #snps_lappend spicedata [format "C_$inst pre_in#[expr 1 - $j] 0 %.6f$cargs(-cap_unit)\n" $max_fanout_cap]
		  } elseif {$j == 0} {
		    snps_lappend spicedata [format "C_$inst in#1 0 %.6f$cargs(-cap_unit)\n" $max_fanout_cap]
		  } else {
		  #  snps_lappend spicedata [format "C_$inst out#$m 0 %.6f$cargs(-cap_unit)\n" $max_fanout_cap]
	    	    if { $j > [expr $cargs(-max_logic_depth) + $cargs(-add_predrvr_cnt)]} {
		    snps_lappend spicedata [format "C_$inst tout#$j 0 %.6f$cargs(-cap_unit)\n" $max_fanout_cap]
		    } else {
		    snps_lappend spicedata [format "C_$inst out#$j 0 %.6f$cargs(-cap_unit)\n" $max_fanout_cap]
		    }
		  }
		  }
	      }

	      # processs fanout loading for logic_depth =$j
	      if {($cargs(-stage_fanout) > 1) } {
		if {$j <= 0} {
		#snps_lappend spicedata  "\n* fanout for pre driver[expr 1 - $j]"
		snps_lappend spicedata  "\n* fanout for pre driver[expr 0 - $j]"
		} else {
		snps_lappend spicedata  "\n* fanout for logic_depth = $j stage_fanout = $cargs(-stage_fanout)"
		}
		for {set k 2} {$k<=$cargs(-stage_fanout)} {incr k} {
		  set inst "X${j}_F#$k"
		  if {$max_fanout_cap > 0} {
		    if { $cargs(-rcseg) <= 0 } {
		    append cmd  "C_$inst"
		    foreach key1 $port_list  {
		      set lkey1 [string tolower $key1]
		      if { $input eq $lkey1 } {
			if {$cargs(-rcseg) > 0 } {
			  lappend rcpts "$inst:$key1"
			  append cmd " $inst:$key1"
			} else {
			if {$j <= -1} {
			  append cmd  " pre_in#[expr 0 - $j]"
			} elseif {$j == 0} {
			  append cmd  " in#1"
			} else {
			  #append cmd  " out#$m"
	    	         if { $j > [expr $cargs(-max_logic_depth) + $cargs(-add_predrvr_cnt)]} {
			  append cmd  " tout#$j"
			 } else {
			  append cmd  " out#$j"
			 }
			}
			}
			break
		      }	
		    }
		    append cmd [format " 0 %.6f$cargs(-cap_unit)\n" $max_fanout_cap]
		    }
		  } else {
		    append cmd "$inst"
		    foreach key1 $port_list  {
		      set lkey1 [string tolower $key1]
		      if { $input eq $lkey1 } {
			if {$cargs(-rcseg) > 0 } {
			  lappend rcpts "$inst:$key1"
			  #append cmd " $inst:$key1"
			  set inst_ports($key1) "$inst:$key1"
			} else {
			  if { $j <= -1} {
			    #append cmd " pre_in#1"
			    set inst_ports($key1) "pre_in#[expr 0 - $j]"
			  } elseif { $j == 0} {
			    #append cmd " in#1"
			    set inst_ports($key1) "in#1"
			  } else {
			    #append cmd  " out#$m"
			    #set inst_ports($key1) "out#$m"
	    	         if { $j > [expr $cargs(-max_logic_depth) + $cargs(-add_predrvr_cnt)]} {
			    set inst_ports($key1) "tout#$j"
			 } else {
			    set inst_ports($key1) "out#$j"
			 }
			  }
			}
		      } elseif { $output eq $lkey1 } {
			if {$max_fanout_cap == -1} {
			  #append cmd " $inst:$key1"
			  set inst_ports($key1) "$inst:$key1"
			}
		      } elseif { [info exists  supply($lkey1)] } {
			if {$max_fanout_cap == -1} {
			  #append cmd " $key1"
	  		if { $cargs(-no_supply_source) } {
			  set inst_ports($key1) "$key1"
			} else {
			  set inst_ports($key1) "pocv_${key1}"
			}
			}
		      } else {
			#append cmd " $inst:$key1"
			set inst_ports($key1) "$inst:$key1"
		      }
		    }
		    #process port list looking to sensitization data


      foreach key1 $port_list  {
        set lkey1 [string tolower $key1]
	#check for mis 
	if { ([llength $mis_input] > 0) && ([lsearch -exact $mis_input $lkey1] > -1) }  {
        #check for sensitization input, function of input & output	
		append cmd " $inst:$key1"
		lappend esrc "E$inst:$key1 $inst:$key1 0 $has_input_conn 0 1"
        } elseif { [info exists sensitization($cell,$lkey1)]} {
		if { [regexp "^\[xX\]$" $sensitization($cell,$lkey1)] } {
			puts "Error: Sensitization undeterminable for CELL: $cell PORT: $key1 SENSE: $sensitization($cell,$lkey1)"
			snps_lappend spicedata ".end"
			return 0
		}
		  if {[regexp "^\[ \t\]*\[\-\.\+0-9\]+\-\>\[\-\.\+0-9\]+\[ \t\]*$" $sensitization($cell,$lkey1)]} {
			# sensitization is set through a param for that cell
		    append cmd  " ${cell}_$key1"
		  } elseif {[regexp "^\[ \t\]*\[\-\.\+0-9\]+\[ \t\]*$" $sensitization($cell,$lkey1)]} {
		    append cmd " ${cell}_$key1"
		  } else {
		    set found 0
		    foreach key2 $port_list  {
		      if {[regexp -nocase "^\[ \t\]*\[\!\]\[ \t\]*$key2\[\:\]*(\[\.0-9\]*)$" $sensitization($cell,$lkey1) dum delay]} {
			# sensitization is set through a DELAYed inverting connection to another port of the cell
			append cmd " $inst:$key1"
			if { $delay ne "" } {
			lappend esrc "E$inst:$key1 $inst:$key1:del $vdd $inst_ports($key2) 0 -1"
			lappend esrc "E$inst:$key1:del $inst:$key1 0 DELAY $inst:$key1:del 0 TD=$delay$cargs(-time_unit)"
			} else {
			lappend esrc "E$inst:$key1 $inst:$key1 $vdd $inst_ports($key2) 0 -1"
			}
			set found 1
			break
		      } elseif {[regexp -nocase "^\[ \t\]*$key2\[ \t\]*\[\:\]*(\[\.0-9\]*)$" $sensitization($cell,$lkey1) dum delay]} {
			# sensitization is set through a DELAYed non-inverting connection to another port of the cell
			if { $delay ne "" } {
			lappend esrc "E$inst:$key1 $inst:$key1:del 0 $inst_ports($key2) 0 1"
			lappend esrc "E$inst:$key1:del $inst:$key1 0 DELAY $inst:$key1:del 0 TD=$delay$cargs(-time_unit)"
			} else {
			lappend esrc "E$inst:$key1 $inst:$key1 0 $inst_ports($key2) 0 1"
			}
			append cmd " $inst:$key1"
			set found 1
			break
		      }
		    }
		    if {!$found} {
			# sensitization is set through whatever is set for that port
		      append cmd  " $sensitization($cell,$lkey1)"
		    }
		  }
	} else {
	  append cmd  " $inst_ports($key1)"
	}
      }

	    if { $cargs(-fanout_cap_mode) eq "real_cell_no_variation" } {
            append cmd  " $cell [string trim [join $cargs(-disable_local_params)]]\n"
	    } else { 
            append cmd  " $cell\n"
	    }
            #process port list looking to apply .ic to inst
            foreach key1 $port_list  {
              set lkey1 [string tolower $key1]
              if { [info exists ic($cell,$lkey1)] } {
                append cmd ".ic $inst_ports($key1) $ic($cell,$lkey1)\n"
              }
            }
            if { [defined esrc] } {
              foreach item $esrc {
                append cmd  "$item\n"
              }
              unset esrc
            }
            if { [array exists inst_ports] } {
              array unset inst_ports
            }
          }
        }
      }
       # add rcsegs to the spice netlists
      if {$cargs(-rcseg) > 0} {
	if { $cargs(-rccap) == 0 } {
		set rccap [expr $max_fanout_cap / $cargs(-rcseg)]
	} else {
		set rccap $cargs(-rccap)
 	}
        set inst [lindex $rcpts 0]
        set r 1
        while { $r  < [llength $rcpts] } {
          set prev_inst $inst
          set inst [lindex $rcpts $r]
          set n $cargs(-rcseg)
          while {$n > 0 } {
            snps_lappend spicedata [format "R_${inst}_RC#$n $prev_inst ${inst}_RC#$n %.6f" $cargs(-rcres)]
            snps_lappend spicedata [format "C_${inst}_RC#$n ${inst}_RC#$n 0 %.6f$cargs(-cap_unit)" $rccap]
            set  prev_inst "${inst}_RC#$n"
            decr n
          }
          snps_lappend spicedata [format "R_${inst}_RC#0 $prev_inst $inst %.6f" $cargs(-rcres)]
          incr r
        }
      } else {
      }
      if { $cmd ne "" } {
      snps_lappend spicedata "$cmd"
      }
      undef rcpts
      if {$cargs(-rcseg) > 0 } {
        lappend rcpts $next_rcpt
      }
      snps_lappend spicedata "*"
      set cmd ""

      ## add fanout for complementary output $j
      if {($comp_output ne "") && ($j > 1) } {
        if {$cargs(-stage_fanout) > 1} {
          snps_lappend spicedata "* fanout for complementary output logic_depth = $j"
          for {set k 1} {$k<=[expr $cargs(-stage_fanout)+0]} {incr k} {
            #fanout loading on comp_output
            set inst "X${j}_Fc#$k"
            if {$max_fanout_cap > 0} {
	      if { $cargs(-rcseg) <= 0 } {
              append cmd  "C_$inst"
              foreach key1 $port_list  {
                set lkey1 [string tolower $key1]
                if { $input eq $lkey1 } {
                if {$cargs(-rcseg) > 0 } {
                  lappend rcpts "$inst:$key1"
                  append cmd " $inst:$key1"
                } else {
                  #append cmd  " outc#$m"
                  append cmd  " outc#$j"
                }
                break
                }	
              }
              append cmd [format " 0 %.6f$cargs(-cap_unit)\n" $max_fanout_cap]
	      }
            } else {
              append cmd "$inst"
              foreach key1 $port_list {
                set lkey1 [string tolower $key1]
                if { $input eq $lkey1 } {
                  if {$k == 1} {
                    #append cmd " outc#$m"
                    #set inst_ports($key1) "outc#$m"
                    set inst_ports($key1) "outc#$j"
                  } else {
                    if {$cargs(-rcseg) > 0 } {
                      lappend comp_rcpts "$inst:$key1"
                      #append cmd " $inst:$key1"
                      set inst_ports($key1) "$inst:$key1"
                    } else {
                      #append cmd " outc#$m"
                      #set inst_ports($key1) "outc#$m"
                      set inst_ports($key1) "outc#$j"
                    }
                  }
                } elseif { $output eq $lkey1 } {
                  if {$max_fanout_cap == -1} {
                    #append cmd " $inst:$key1"
                    set inst_ports($key1) "$inst:$key1"
                  }
                } elseif { [info exists supply($lkey1)]} {
                  if {$max_fanout_cap == -1} {
                    #append cmd " $key1"
	  	if { $cargs(-no_supply_source) } {
                    set inst_ports($key1) "$key1"
   		} else {
                    set inst_ports($key1) "pocv_${key1}"
		}
                  }
                } else {
                  set inst_ports($key1) "$inst:$key1"
                }
              }
              #process port list looking to sensitization data
              foreach key1 $port_list  {
                set lkey1 [string tolower $key1]
                if { [info exists sensitization($cell,$lkey1)]} {
                  if {[regexp "^\[ \t\]*\[\-\+\.0-9\]+->\[\-\+\.0-9\]+\[ \t\]*$" $sensitization($cell,$lkey1)]} {
                    append cmd  " ${cell}_$key1"
                  } elseif {[regexp "\[ \t\]*\[\-\+\.0-9\]+\[ \t\]$" $sensitization($cell,$lkey1)]} {
                    append cmd " ${cell}_$key1"
                  } else {
                    set found 0
                    foreach key2 $port_list  {
                      if {[regexp -nocase "^\[ \t\]*\[\!\]\[ \t\]*$key2$" $sensitization($cell,$lkey1)]} {
                        append cmd " $inst:$key1"
                        lappend esrc "E$inst:$key1 $inst:$key1 $vdd $inst_ports($key2) 0 -1"
                        set found 1
                        break
                      } elseif { [regexp "^\[ \t\]*$sensitization($cell,$lkey1)\s*$" $key2]} {
                        append cmd " $inst_ports($key2)"
                        set found 1
                        break
                      }
                    }
                    if {!$found} {
                      append cmd " $sensitization($cell,$lkey1)"
                    }
                  }
                } else {
                  append cmd " $inst_ports($key2)"
                }
              }
              append cmd " $cell\n"

              #process port list looking to apply .ic to inst
              foreach key1 $port_list  {
                set lkey1 [string tolower $key1]
                if { [info exists ic($cell,$lkey1)] } {
                  append cmd ".ic $inst_ports($key1) $ic($cell,$lkey1)\n"
                }
              }
              if { [defined esrc] } {
                foreach item $esrc {
                  append cmd  "$item\n"
                }
                unset esrc
              }
              if { [array exists inst_ports] } {
                array unset inst_ports
              }
            }
          }
        } else {
          set inst "X${j}_F#1"
          if {$max_fanout_cap <= 0} {
          } else {
	    if { $cargs(-rcseg) <= 0 } {
            if {$j == 1} {
              append cmd [format "C_$inst in#1 0 %.6f$cargs(-cap_unit)\n" $max_fanout_cap]
            } else {
              append cmd [format "C_$inst outc#$m 0 %.6f$cargs(-cap_unit)\n" $max_fanout_cap]
            }
	    }
          }
        }
        if {$cargs(-rcseg) > 0} {
	if { $cargs(-rccap) == 0 } {
		set rccap [expr $max_fanout_cap / $cargs(-rcseg)]
	} else {
		set rccap $cargs(-rccap)
 	}
          set inst [lindex $comp_rcpts 0]
          set r 1
          while {$r < [llength $comp_rcpts]} {
            set prev_inst $inst
            set inst [lindex $comp_rcpts $r]
            set n $cargs(-rcseg)
            while {$n > 0 } {
              snps_lappend spicedata [format "R_${inst}_RC#$n $prev_inst ${inst}_RC#$n %.6f" $cargs(-rcres)]
              snps_lappend spicedata [format "C_${inst}_RC#$n ${inst}_RC#$n 0 %.6f$cargs(-cap_unit)" $rccap]
              set prev_inst "${inst}_RC#$n"
              decr n
            }
            snps_lappend spicedata [format "R_${inst}_RC#0 $prev_inst $inst %.6f" $rccap]
            incr r
          }
        }
        snps_lappend spicedata $cmd
      }
      if { $comp_output ne "" } {
        undef comp_rcpts
        lappend comp_rcpts $next_comp_rcpt
      }
      set cmd ""
#      snps_lappend spicedata "\n"
    }
#    snps_lappend spicedata  "\n"

### add to new proc
    snps_lappend spicedata  "* specify the input waveform"

    set  float_format "\%.6f"
	    if { $cargs(-cycles) > 1 } {
	    snps_lappend spicedata "Vpulse in#1 vss pulse (0 $pvdd start_time rise_time fall_time high_pulse period )"
    #snps_lappend spicedata "Vpulse in#1 vss pulse (t1=0 t2=$pvdd per=period pw=high_pulse tr=rise_time tf=fall_time td=start_time"
    #snps_lappend spicedata "+ )\n\n"
    } else {
    set h 1
    snps_lappend spicedata "Vpwl in#1 vss pwl (start_time 0 \`start_time + rise_time\` $pvdd \`start_time + rise_time + high_pulse\` $pvdd \`start_time + rise_time + high_pulse + fall_time\` 0 period 0.0"
    snps_lappend spicedata "+ )\n\n"
     }

    #while {$h < $cargs(-cycles)} {
    # snps_lappend spicedata " + \`$h * period + start_time\` 0 \`$h * period + start_time + rise_time\` $pvdd \`$h * period + start_time + rise_time + high_pulse\` $pvdd \`$h * period + start_time + rise_time + high_pulse + fall_time\` 0 \`$h * period + period\` 0.0"
    #  incr h
    #}


    set wsm ""
    append wsm " -vdd $pvdd"
    append wsm " -delay_meas $delay_meas"
    append wsm " -upper_slew $upper_slew"
    append wsm " -lower_slew $lower_slew"
    append wsm " -meas_from_cross $cargs(-meas_from_cross)"
    append wsm " -meas_to_cross $cargs(-meas_to_cross)"
    append wsm " -meas_from_cross_rf_incr $cargs(-meas_from_cross_rf_incr)"
    append wsm " -meas_from_cross_rf_exp $cargs(-meas_from_cross_rf_exp)"
    append wsm " -meas_from_cross_rf_exp_mult $cargs(-meas_from_cross_rf_exp_mult)"
    append wsm " -meas_from_cross_rf_mult $cargs(-meas_from_cross_rf_mult)"
    append wsm " -meas_to_cross_rf_incr $cargs(-meas_to_cross_rf_incr)"
    append wsm " -meas_from_cross_level_mult $cargs(-meas_from_cross_level_mult)"
    append wsm " -meas_from_cross_level_exp $cargs(-meas_from_cross_level_exp)"
    append wsm " -meas_from_cross_level_exp_mult $cargs(-meas_from_cross_level_exp_mult)"
    append wsm " -meas_from_edge $cargs(-meas_from_edge)"
    append wsm " -meas_td $cargs(-meas_td)"
	### create meas pt list with names!!!  
    # create a from_meas_pts list and to_meas_pts list
    #     same_cell: from == in#1, in#1, in#1, in#1 ...  to == out#1, out#2 ....
    #     predriver: from == in#1, out#1, out#2, ...     to == out#N, out#N ....
    #     alternating: from == in#1 out#1, in#1, out#1 ...  to=out#1, out#3, ....
    set from_meas_pts {}
    set to_meas_pts {}
    set to_comp_meas_pts {}
    if { [regexp "drive" $cargs(-cell_chain_mode)] ||  [regexp "custom" $cargs(-cell_chain_mode)] || ($cargs(-reverse) && [regexp "same" $cargs(-cell_chain_mode)]) || ($cargs(-reverse) && [regexp "alter" $cargs(-cell_chain_mode)])  } {
       if { $cargs(-add_predrvr_cnt) > 0 } {
       for {set j $cargs(-add_predrvr_cnt)} {$j<[expr $cargs(-max_logic_depth) + $cargs(-add_predrvr_cnt)]} {incr j} {
            lappend from_meas_pts [lindex $meas_pts [expr $cargs(-max_logic_depth) + $cargs(-add_predrvr_cnt) + $cargs(-add_predrvr_cnt) - $j - 1] ] 
            lappend to_meas_pts [lindex $meas_pts [expr $cargs(-max_logic_depth) + $cargs(-add_predrvr_cnt) ] ]
            if { $comp_meas_pts ne "" } {
            lappend to_comp_meas_pts [lindex $comp_meas_pts [expr $cargs(-max_logic_depth) + $cargs(-add_predrvr_cnt) ]]
            }
       }
       } else {
       for {set j 0} {$j<[expr $cargs(-max_logic_depth)]} {incr j} {
            lappend from_meas_pts [lindex $meas_pts $j]
            lappend to_meas_pts [lindex $meas_pts $cargs(-max_logic_depth)]
            if { $comp_meas_pts ne "" } {
            lappend to_comp_meas_pts [lindex $comp_meas_pts $cargs(-max_logic_depth)]
            }
       }
       }
    } elseif { [regexp "same" $cargs(-cell_chain_mode)] } {
       if { $cargs(-add_predrvr_cnt) > 0} {
       for {set j $cargs(-add_predrvr_cnt)} {$j<[expr $cargs(-max_logic_depth) + $cargs(-add_predrvr_cnt)]} {incr j} {
            lappend from_meas_pts [lindex $meas_pts $cargs(-add_predrvr_cnt)]
            lappend to_meas_pts [lindex $meas_pts [expr $j + 1]]
            if { $comp_meas_pts ne "" } {
            lappend to_comp_meas_pts [lindex $comp_meas_pts [expr $j + 1]]
            }
       }
       } else {
       for {set j 0} {$j<=[expr $cargs(-max_logic_depth)]} {incr j} {
            lappend from_meas_pts [lindex $meas_pts 0]
            lappend to_meas_pts [lindex $meas_pts [expr $j + 1]]
            if { $comp_meas_pts ne "" } {
            lappend to_comp_meas_pts [lindex $comp_meas_pts [expr $j + 1]]
            }
       }
       }
    } elseif { [regexp "alter" $cargs(-cell_chain_mode)] } {
       if { $cargs(-add_predrvr_cnt) > 0 } {
       for {set j $cargs(-add_predrvr_cnt)} {$j<[expr $cargs(-max_logic_depth) + $cargs(-add_predrvr_cnt)]} {incr j} {
            lappend from_meas_pts [lindex $meas_pts $cargs(-add_predrvr_cnt)]
            lappend to_meas_pts [lindex $meas_pts [expr $j + 1]]
            if { $comp_meas_pts ne "" } {
            lappend to_comp_meas_pts [lindex $comp_meas_pts [expr $j + 1]]
            }
       }
       } else {
       for {set j 0} {$j<=[expr $cargs(-max_logic_depth)]} {incr j} {
            lappend from_meas_pts [lindex $meas_pts 0]
            lappend to_meas_pts [lindex $meas_pts [expr $j + 1]]
            if { $comp_meas_pts ne "" } {
            lappend to_comp_meas_pts [lindex $comp_meas_pts [expr $j + 1]]
            }
	}
	}
    }
    if { $cargs(-debug) } {
    puts "FROM MEAS PTS: $from_meas_pts"
    puts "TO  MEAS  PTS: $to_meas_pts"
    }
    if {$comp_output eq ""} {
    set meas_data [eval add_measure_to_spice_deck $wsm -from_meas_pts \[list $from_meas_pts\] -to_meas_pts \[list $to_meas_pts\] -meas_depth_list \[list $cargs(-meas_depth_list)\] -both_edges]
    snps_lappend spicedata "$meas_data"
    unset to_meas_pts
    } else {
    set meas_data [eval add_measure_to_spice_deck $wsm -from_meas_pts \[list $from_meas_pts\] -to_meas_pts \[list $to_meas_pts\] -meas_depth_list \[list $cargs(-meas_depth_list)\]]
    snps_lappend spicedata "$meas_data"
    unset to_meas_pts
    set meas_data [eval add_measure_to_spice_deck $wsm -from_meas_pts \[list $from_meas_pts\] -to_meas_pts \[list $to_comp_meas_pts\] -meas_depth_list \[list $cargs(-meas_depth_list)\]]
    snps_lappend spicedata "$meas_data"
    unset comp_meas_pts
    }


  ###### start of each split spice deck file
  ## generating spice decks
  set monte_start 1
  set monte_end 1
  set monte_split_cnt 1
  set monte $cargs(-monte)
  if { $cargs(-monte) < $cargs(-monte_split) } {
	set cargs(-monte_split) $cargs(-monte)
  }

  ## splitting up spice decks
  while {$monte_start < $monte} {
    set monte_end [expr $monte_start+$cargs(-monte_split)-1]
    if {$monte_end > $monte} {
      set monte_end $monte
    }
    if { ($cargs(-ref_spice_model) ne "") || ($cargs(-ref_spice_lib) ne "") } {
    set FOUT [open "$cargs(-spice_output).$cargs(-spice_ext)" w]
    puts "Writing POCV Reference SPICE deck: $cargs(-spice_output).$cargs(-spice_ext) for cell: $cargs(-cell)"
    puts $FOUT "* reference stage based spice deck for $cargs(-cell)"
    } else {
    set FOUT [open "$cargs(-spice_output).m-${monte_split_cnt}.$cargs(-spice_ext)" w]
    puts "Writing POCV monte-carlo ($monte_start - $monte_end) SPICE deck: $cargs(-spice_output).m-${monte_split_cnt}.$cargs(-spice_ext) for cell: $cargs(-cell)"
    puts $FOUT "* aocv stage based spice deck for $cargs(-cell)"
    }
    puts $FOUT "*\n"
  
    #puts $FOUT [join $spicedata "\n"]
    foreach data $spicedata {
    puts $FOUT "$data"
    }
    if { ($cargs(-ref_spice_model) ne "") || ($cargs(-ref_spice_lib) ne "") } {
    puts $FOUT  [format ".tran $cargs(-tran_step)$cargs(-time_unit) ${float_format}$cargs(-time_unit)" $cargs(-tran_stop)]
    } else {
    puts $FOUT [format ".tran $cargs(-tran_step)$cargs(-time_unit) ${float_format}$cargs(-time_unit) sweep monte=$cargs(-monte_split) firstrun=$monte_start" $cargs(-tran_stop)]
   }
    if { ($cargs(-ref_spice_model) ne "") || ($cargs(-ref_spice_lib) ne "") } {
    puts "  Done writing POCV Reference SPICE deck: $cargs(-spice_output).ref.$cargs(-spice_ext) for cell: $cell"
    } else {
    puts "  Done writing POCV monte-carlo ($monte_start - $monte_end) SPICE deck: $cargs(-spice_output).m-${monte_split_cnt}.$cargs(-spice_ext) for cell: $cell"
    }
    puts $FOUT ".end"
    close $FOUT
    incr monte_split_cnt
    set monte_start [expr $monte_end+1]
    if { ($cargs(-ref_spice_model) ne "") || ($cargs(-ref_spice_lib) ne "") } {
		break
    }
  }
  if { $cargs(-nt) } {
    if { ($cargs(-ref_spice_model) ne "") || ($cargs(-ref_spice_lib) ne "") } {
    set FOUT [open "$cargs(-spice_output).NTref.$cargs(-spice_ext)" w]
    puts "Writing NT reference SPICE deck: $cargs(-spice_output).NTref.$cargs(-spice_ext) for cell: $cargs(-cell)"
    puts $FOUT "* pocv reference stage based spice deck for $cargs(-cell)"
    } else {
    set FOUT [open "$cargs(-spice_output).NT.$cargs(-spice_ext)" w]
    puts "Writing NT SPICE deck: $cargs(-spice_output).NT.$cargs(-spice_ext) for cell: $cargs(-cell)"
    puts $FOUT "* pocv stage based reference spice deck for $cargs(-cell)"
    }
    puts $FOUT "*\n"
    foreach data $spicedata {
    puts $FOUT "$data"
    }
    if { ($cargs(-ref_spice_model) ne "") || ($cargs(-ref_spice_lib) ne "") } {
    puts "  Done writing NT SPICE deck: $cargs(-spice_output).NTref.$cargs(-spice_ext) for cell: $cell"
    } else {
    puts "  Done writing NT SPICE deck: $cargs(-spice_output).NT.$cargs(-spice_ext) for cell: $cell"
    }
    puts $FOUT ".end"
    close $FOUT
  }
}
define_myproc_attributes write_pocv_spice_deck \
-info "write the SPICE deck to generate AOCV tables/verify variation on chain of cells " \
-define_args { \
  {-array_name "name of hash for cell data array" string string optional}
  {-cell "name of cell for validation" string string_list required}
  {-pocv_dir "aocv dir of aocv file(def .)" string string optional}
  {-meas_dir "meas/working dir of hspice file(def .)" string string optional}
  {-stage_fanout "stage fanout(def 1)" int int optional}
  {-spice_cells "extracted spice cell file(s)" string string_list optional}
  {-spice_cells_dir "extracted spice cell file(s) directory" string string_list optional}
  {-spice_model "spice cell model file(s)" string string_list optional}
  {-ref_spice_model "reference spice cell model file(s)" string string_list optional}
  {-spice_lib "spice cell model lib(s)"  string string_list optional}
  {-ref_spice_lib "reference spice cell model lib(s)" string string_list optional}
  {-spice_output "spice output file(s)" string string optional}
  {-spice_ext "spice file name extension" string string optional}
  {-input "input pin of cell being used" string string_list optional}
  {-mis_input "mis input pins of cell being used" string string_list optional}
  {-output "output pin of cell being used" string string_list optional}
  {-drive_input "input pin of cell being used" string string_list optional}
  {-drive_output "output pin of cell being used" string string_list optional}
  {-comp_output "comp output pin of cell being used" string string_list optional}
  {-ic "list of ic for cell port=value" string string_list optional}
  {-supply "supply value on ports of cell port=value" string string_list optional}
  {-vss "GND supply value on ports of cell" string string_list optional}
  {-no_supply_source "dont print supply sources in spice decks "" boolean optional}
  {-sensitization_data "list of sensitization for input->output port=value" string string_list optional}
  {-port_list "list of ports of cell" string string_list optional}
  {-drive_port_list "list of ports of cell" string string_list optional}
  {-stage_fanout "stage fanout(def 1)" int int optional}
  {-max_logic_depth "max logic depth(def 15)" int int optional}
  {-meas_depth_list "list of depths to measure at(def. is every level)" string string optional}
  {-max_fanin_trans "max transition of input waveform(def )" float float optional}
  {-max_fanin_trans_fall "max fall transition of input waveform(def )" float float optional}
  {-max_fanout_cap "use max cap per fanout load" float float optional}
  {-max_fanout_cap_pct "percentage of max cap per fanout load" float float_list optional}
  {-predrvr_max_fanout_cap_pct "percentage of predrvr max cap per fanout load" float float_list optional}
  {-fanout_cap_mode "fanout cap mode" string string optional}
  {-fanin_trans_mode "fanin trans mode" string string optional}
  {-max_fanin_trans_pct "percentage of max transition of fanin" float float optional}
  {-monte "number of monte carlo samples(def. 2000)" int int optional}
  {-monte_split "number of monte carlo samples split per file(def 400)" int int optional}
  {-temp "temperature of PVT" float float optional}
  {-vdd "voltage of PVT(or use -supply)" float float optional}
  {-period "period of input waveform(def 4ns)" float float optional}
  {-high_pulse "time of high pulse of input waveform(def 2ns)" float float optional}
  {-cycles "number of cycles of input waveform(def 2)" int int optional}
  {-tran_start "start time of input waveform(def 1ns)" float float optional}
  {-accurate ".option accurate in SPICE" "" boolean optional}
  {-spice_options ".option cmds for SPICE" string string optional}
  {-tran_step "transient time step for SPICE(def .001ns)" float float optional}
  {-tran_stop "transient stop time for SPICE(def period * (cycles + .5)" float float optional}
  {-upper_slew "upper slew measurement fraction(def .9)" float float optional}
  {-lower_slew "lower slew measurement fraction(def .1)" float float optional}
  {-delay_meas "delay meas measurement fraction(def .5)" float float optional}
  {-meas_from_cross "starting level meas edge of input waveform(def 1)" float float optional}
  {-meas_to_cross "starting meas edge at each level(def 1)" float float optional}
  {-meas_from_cross_rf_incr "next rf meas edge of input waveform(def 1)" float float optional}
  {-meas_to_cross_rf_incr "next rf meas edge  at each level(def 1)" int int optional}
  {-meas_from_cross_rf_mult "next rf meas edge multiplier of input waveform(def 0)" int int optional}
  {-meas_from_cross_rf_exp "next rf meas edge exponential of input waveform(def 0)" int int optional}
  {-meas_from_cross_rf_exp_mult "multiplier nex logic depth rf meas edge exponential of input waveform(def 0)" int int optional}
  {-meas_from_cross_level_mult "next logic depth level meas edge multiplier input waveform(def 0)" int int optional}
  {-meas_from_cross_level_exp "next logic depth level meas edge exponential input waveform(def 0)" int int optional}
  {-meas_from_cross_level_exp_mult "multipler for next logic depth level meas edge exponential input waveform(def 0)" int int optional}
  {-meas_td "time delay before beginning measurements" string string optional}
  {-meas_from_edge "specific from measurement edge(rise|fall) def:(cross)" string string optional}
  {-rccap "rc cap(def 1.0ff)" float float optional}
  {-rcres "rc res(def 10ohms)" float float optional}
  {-rcseg "rc seg res-cap-res(def 1)" float float optional}
  {-cell_chain_mode "mode of cell chain(def. same_cell, drive_cell)" string string optional}
  {-variation_mode "tx variation mode(def. all_tx)" string string optional}
  {-inc_temp "incl .temp to spice deck" "" boolean optional}
  {-inc_spice_cells "incl extracted spice cells" "" boolean optional}
  {-local_params "local_params monte carlo samplings: param=aguass(nom,abs_var,sigma)" string string_list optional}
  {-global_params "global_params monte carlo samplings: param=aguass(nom,abs_var,sigma)" string string_list optional}
  {-time_unit "time_unit(def NS)" string string optional}
  {-cap_unit "cap_unit(def PF)" string string optional}
  {-nmos_only "local mismatch only on nmos" "" boolean optional}
  {-pmos_only "local mismatch only on pmos" "" boolean optional}
  {-disable_local_params "params to disable local mismatch" string string_list optional}
  {-no_predrvr_load "no predriver cell loading" "" boolean optional}
  {-add_predrvr_cnt "number of pre driver cells(def. 0)" "int" int optional}
  {-no_predrvr_variation "no predriver variation" "" boolean optional}
  {-disable_predrvr_local_params "local variation disable param for predriver" string string optional}
  {-add_stage_var_meas "add per stage variation measurement cmds" "" boolean optional}
  {-sig_digits "number of HSPICE sig digits(def 5)" int int optional}
  {-reverse "reverse depth counting(def for drive & custom mode)" "" boolean optional}
  {-debug "debug write spice deck generation" "" boolean optional}
  {-nt "generate NT pocv spice decks" "" boolean optional}
}

echo "Defined procedure 'write_pocv_spice_deck'."

### add measure stms to spice decks
proc add_measure_to_spice_deck { args } {
  set cargs(-to_meas_pts) ""
  set cargs(-from_meas_pts) ""
  set cargs(-meas_depth_list) ""
  set cargs(-vdd) ""
  set cargs(-meas_from_cross) 1
  set cargs(-meas_to_cross) 1
  set cargs(-meas_from_cross_rf_incr) 1
  set cargs(-meas_to_cross_rf_incr) 1
  set cargs(-meas_from_cross_rf_mult) 0
  set cargs(-meas_from_cross_rf_exp) 0
  set cargs(-meas_from_cross_rf_exp_mult) 0
  set cargs(-meas_from_cross_level_mult) 0
  set cargs(-meas_from_cross_level_exp) 0
  set cargs(-meas_from_cross_level_exp_mult) 0
  set cargs(-upper_slew) .8
  set cargs(-lower_slew) .2
  set cargs(-delay_meas) .5
  set cargs(-spice_file) ""
  set cargs(-output_file) ""
  set cargs(-both_edges) 0
  set cargs(-add_end) 0
  set cargs(-meas_from_edge) "CROSS"
  set cargs(-meas_td) 0

  if { [parse_myproc_arguments -args $args cargs] eq "0" } {
  	return 0
  }

  set cargs(-meas_from_edge) [string toupper $cargs(-meas_from_edge)]

  if { ($cargs(-output_file) ne "") && ($cargs(-spice_file) ne "") } {
    file copy -force $cargs(-spice_file) $cargs(-output_file)
  }

  set cargs(-meas_depth_list) [split [regsub -all "\[ \t\]+" [string trim [join $cargs(-meas_depth_list)]] { }]] 
    set cargs(-to_meas_pts) [split [regsub -all "\[ \t\]+" [string trim [join $cargs(-to_meas_pts)]] { }]] 
    set cargs(-from_meas_pts) [split [regsub -all "\[ \t\]+" [string trim [join $cargs(-from_meas_pts)]] { }]] 
  if { $cargs(-meas_depth_list) eq ""} {
	set key1 1
 	while { $key1 <= [llength $cargs(-to_meas_pts)]} {
		set depth_array($key1) 1
		incr key1
	}
  } else {
	foreach key1 $cargs(-meas_depth_list) {
		set depth_array($key1) 1
	}
  }
    set meas_data  "\n* measure delays and transitions $cargs(-to_meas_pts)\n"
    if { $cargs(-vdd) eq "" } {
	puts "ERROR: no cmd line -vdd specified"
	return 
    } 
    set pvdd $cargs(-vdd)
   
    set m 0
    set from_meas $cargs(-meas_from_cross)
    set to_meas $cargs(-meas_to_cross)
    while {$m < [llength $cargs(-to_meas_pts)]} {
        set n [expr $m + 1]
      if { [defined depth_array($n)] } {
#      if { $m > 1 } {
#      set from_meas [expr $from_meas+$cargs(-meas_from_cross_level_mult)*$m+[expr $cargs(-meas_from_cross_level_exp_mult) * pow($cargs(-meas_from_cross_level_exp),[expr $m-1])]] 
#      } else {
#      set from_meas [expr $from_meas+$cargs(-meas_from_cross_level_mult)*$m+[expr $cargs(-meas_from_cross_level_exp_mult) * pow($cargs(-meas_from_cross_level_exp),[expr $m-1])]] 
#      #set from_meas [expr $from_meas+$cargs(-meas_from_cross_level_mult)*$m] 
#      }
      append meas_data [format ".MEASURE TRAN pocv_d_o#${n}_1 TRIG v([lindex $cargs(-from_meas_pts) $m]) VAL=\'$pvdd * $cargs(-delay_meas)\' $cargs(-meas_from_edge)=%0.5f TD=$cargs(-meas_td) TARG v([lindex $cargs(-to_meas_pts) $m ]) VAL=\'$pvdd * $cargs(-delay_meas)\' CROSS=%0.5f \n" [expr $from_meas+$cargs(-meas_from_cross_level_mult)*$n+[expr $cargs(-meas_from_cross_level_exp_mult) * pow($cargs(-meas_from_cross_level_exp),$m)]] $to_meas]
      append meas_data [format ".MEASURE TRAN pocv_rf_o#${n}_1 TRIG v([lindex $cargs(-to_meas_pts) $m]) VAL=\'$pvdd * $cargs(-lower_slew)\' CROSS=%0.5f TD=$cargs(-meas_td) TARG v([lindex $cargs(-to_meas_pts) $m]) VAL\='$pvdd * $cargs(-upper_slew)\' CROSS=%0.5f \n" $to_meas $to_meas]
      if {$cargs(-both_edges)} {
        append meas_data [format ".MEASURE TRAN pocv_d_o#${n}_2 TRIG v([lindex $cargs(-from_meas_pts) $m]) VAL=\'$pvdd * $cargs(-delay_meas)\' $cargs(-meas_from_edge)=%0.5f TD=$cargs(-meas_td) TARG v([lindex $cargs(-to_meas_pts) $m]) VAL='$pvdd * $cargs(-delay_meas)\' CROSS=%0.5f \n" [expr $from_meas+$cargs(-meas_from_cross_rf_incr)+ [expr $cargs(-meas_from_cross_rf_exp_mult) * pow($cargs(-meas_from_cross_rf_exp), $m )]+$cargs(-meas_from_cross_rf_mult)*$n] [expr $to_meas+$cargs(-meas_to_cross_rf_incr)]]
        append meas_data [format ".MEASURE TRAN pocv_rf_o#${n}_2 TRIG v([lindex $cargs(-to_meas_pts) $m]) VAL=\'$pvdd * $cargs(-lower_slew)\' CROSS=%0.5f TD=$cargs(-meas_td) TARG v([lindex $cargs(-to_meas_pts) $m]) VAL\='$pvdd * $cargs(-upper_slew)\' CROSS=%0.5f \n" [expr $to_meas+$cargs(-meas_to_cross_rf_incr)] [expr $to_meas+$cargs(-meas_to_cross_rf_incr)]]
      }
      }
      incr m
    }
      append meas_data [format ".MEASURE TRAN pocv_rf_o#0_1 TRIG v([lindex $cargs(-from_meas_pts) 0]) VAL=\'$pvdd * $cargs(-lower_slew)\' CROSS=%0.5f TD=$cargs(-meas_td) TARG v([lindex $cargs(-from_meas_pts) 0]) VAL\='$pvdd * $cargs(-upper_slew)\' CROSS=%0.5f \n" $to_meas $to_meas]
      if {$cargs(-both_edges)} {
        append meas_data [format ".MEASURE TRAN pocv_rf_o#0_2 TRIG v([lindex $cargs(-from_meas_pts) 0]) VAL=\'$pvdd * $cargs(-lower_slew)\' CROSS=%0.5f TD=$cargs(-meas_td) TARG v([lindex $cargs(-from_meas_pts) 0]) VAL\='$pvdd * $cargs(-upper_slew)\' CROSS=%0.5f \n" [expr $to_meas+$cargs(-meas_to_cross_rf_incr)] [expr $to_meas+$cargs(-meas_to_cross_rf_incr)]]
      }
  if { $cargs(-add_end) } {
	append meas_data ".end\n"
  }
  if { $cargs(-output_file) ne "" } {
    	set FOUT [open "$cargs(-output_file)" a]
	puts $FOUT $meas_data
	close $FOUT
  } elseif {$cargs(-spice_file) ne "" } {
    	set FOUT [open "$cargs(-spice_file)" a]
	puts $FOUT $meas_data
	close $FOUT
  } else {
	return $meas_data
  }
}
define_myproc_attributes add_measure_to_spice_deck \
-info "add measure stmts to write spice deck" \
-define_args { \
  {-spice_file "spice file to append .measure cmds" string string optional}
  {-output_file "spice file to save .measure cmds to" string string optional}
  {-vdd "voltage of PVT(or use -supply)" string string optional}
  {-upper_slew "upper slew measurement fraction(def .9)" float float optional}
  {-lower_slew "lower slew measurement fraction(def .1)" float float optional}
  {-delay_meas "delay meas measurement fraction(def .5)" float float optional}
  {-meas_from_cross "starting level meas edge of input waveform(def 1)" float float optional}
  {-meas_to_cross "starting meas edge at each level(def 1)" float float optional}
  {-meas_from_cross_rf_incr "next rf meas edge of input waveform(def 1)" float float optional}
  {-meas_to_cross_rf_incr "next rf meas edge  at each level(def 1)" float float optional}
  {-meas_from_cross_rf_mult "next rf meas edge multiplier of input waveform(def 0)" int int optional}
  {-meas_from_cross_rf_exp "next rf meas edge exponential of input waveform(def 0)" int int optional}
  {-meas_from_cross_rf_exp_mult "multipier for next rf meas edge exponential of input waveform(def 1)" int int optional}
  {-meas_from_cross_level_mult "next logic depth level meas edge multiplier input waveform(def 0)" int int optional}
  {-meas_from_cross_level_exp "next logic depth level meas edge exponential input waveform(def 0)" int int optional}
  {-meas_from_cross_level_exp_mult "multiplier for next logic depth level meas edge exponential input waveform(def 1)" int int optional}
  {-both_edges "setup measures for both edges on given nodes(default is one edge)" "" boolean optional}
  {-add_end "add a closing .end to spice deck" "" boolean optional}
  {-to_meas_pts "list of to meas_pt spice nets/nodes for .measure cmds" string string required}
  {-from_meas_pts "list of from meas_pt spice nets/nodes for .measure cmds" string string required}
  {-meas_depth_list "list of depths to measure at(def. is every level)" string string optional}
  {-meas_td "time delay before beginning measurements" string string optional}
  {-meas_from_edge "specific from measurement edge(rise|fall) def:(cross)" string string optional}
}
echo "Defined procedure 'add_measure_to_spice_deck'."

### read hspice measure data to a TCL array
proc read_measure_data_to_array { args } {
  set cargs(-meas_dir)  "."
  set cargs(-measure_data_extension) ".mt0"
  set cargs(-max_value) "999999999999999"
  set cargs(-min_value) "-999999999999999"	
  set cargs(-dataarray) ""
  set cargs(-meas) ""
  set cargs(-stat_file) ""
  set cargs(-debug) 0

  if { [parse_myproc_arguments -args $args cargs] eq "0"  } {
    return 0
  }
  if { $cargs(-dataarray) eq "" } {
    die "Must use -dataarray option to read_measure_data_to_array"
  }

  upvar 1 $cargs(-dataarray) sigdata

    echo "Processing Measure Files: $cargs(-meas)"
    set files_found 0
    foreach file [split [string trim [join $cargs(-meas)  " "]]] {
      if { ($cargs(-meas_dir) ne "") && ([string range $file 0 0] ne "/")} {
        set file "$cargs(-meas_dir)/$file"
      }
      foreach newfile [glob -nocomplain $file] {
        set files_found 1
        set newfile [regsub "\[ \t\]*$" $newfile {}]
        set newfile [regsub "^\[ \t\]*" $newfile {}]
        set newfile [regsub ".gz$" $newfile ""]
        set newfile [string range $newfile 0 end-[string length $cargs(-measure_data_extension)]]
	if { $cargs(-debug) } {
		puts "Info: (read_measure_data_to_array) parsing measaure data in file: $newfile"
	}
	if { $cargs(-stat_file) ne ""} {
        mc_read_measure_data_to_array -dataarray sigdata -base_filename $newfile -measure_data_extension $cargs(-measure_data_extension)  -scale_to_ns -min_value $cargs(-min_value) -max_value $cargs(-max_value) -stat_file $cargs(-stat_file)
	} else {
        mc_read_measure_data_to_array -dataarray sigdata -base_filename $newfile -measure_data_extension $cargs(-measure_data_extension)  -scale_to_ns -min_value $cargs(-min_value) -max_value $cargs(-max_value)
	}
	if { $cargs(-debug) } {
		parray sigdata
	}
	if { ![array exists sigdata] || ([array size sigdata] < 1) } {
	echo "Error:  Unable to find any good data in Measure files: $cargs(-meas)"	
    	return 0
	}
      }
    }
    if { !$files_found } {
    echo "Error: Unable to find any Measure files matching: $cargs(-meas)"
    return 0
    }
    echo "  Done Processing Measure Files: $cargs(-meas)"
    return 1
}
define_myproc_attributes -info "read hspice measure files to array" -define_args {
  {-dataarray "array to store measure data" string string required}
  {-meas_dir "measure/working file dir" string string optional}
  {-meas "list of hspice measure files" string string optional}
  {-measure_data_extension "measurement data file extension" "suffix" string optional}
  {-min_value "minimum value allowed for data" float float optional}
  {-max_value "maximum value allowed for data" float float optional}
  {-stat_file "filename " "file for measure failure stats" string optional}
  {-debug "add debug messages " "" boolean optional}
} read_measure_data_to_array
echo "Defined procedure 'read_measure_data_to_array'."

### calculate stddev of array 
proc generate_stddev_from_array { args } {
  set cargs(-cell) ""
  set cargs(-dataarray) ""
  set cargs(-max_value) "999999999999999"
  set cargs(-min_value) "-999999999999999"	
  set cargs(-meas_dir) "."
  set cargs(-sig_digits) 3
  set cargs(-del_meas_var) "\[ap\]ocv_d_o#"
  set cargs(-rf_meas_var) "\[ap\]ocv_rf_o#"
  set cargs(-rf_sep) "_\[1-2\]"
  set cargs(-max_logic_depth) 15
  if { [parse_myproc_arguments -args $args cargs] eq "0"  } {
    return 0
  }

  if { $cargs(-dataarray) eq "" } {
    die "Must use -dataarray option to generate_stage_stdev_from_array"
  }
  upvar 1 $cargs(-dataarray) sigdata
  array unset processed
	set cargs(-rf_sep) [string trim $cargs(-rf_sep) "\{\}\""]
	set cargs(-del_meas_var) [string trim $cargs(-del_meas_var) "\{\}\""]
	set cargs(-rf_meas_var) [string trim $cargs(-rf_meas_var) "\{\}\""]
      foreach refname [lsort [array names sigdata]] {
        #separate data into rise and fall data
        # look at both <del_meas_var><#>_2
        if { [regexp $cargs(-del_meas_var) $refname ] && ![info exists processed($refname)]} {
          regexp "$cargs(-del_meas_var)(\[0-9\]+)" $refname dum index
          if {$index <= $cargs(-max_logic_depth)} {
          # gather rise and fall data arrivals
        set rise {}
        set fall {}
          foreach ref [array names sigdata "$cargs(-del_meas_var)${index}$cargs(-rf_sep)"] {
          echo "Calculating StdDev for: $ref"
                set processed($ref) 1
                set rf_name [regsub $cargs(-del_meas_var) $ref $cargs(-rf_meas_var)]
                set i 0
                while { $i < [llength $sigdata($rf_name)] } {
		if { [lindex $sigdata($ref) $i] ne "fail" } {
                if { [lindex $sigdata($rf_name) $i] < 0} {
                        if { ([lindex $sigdata($ref) $i] > $cargs(-min_value)) && ([lindex $sigdata($ref) $i] < $cargs(-max_value)) } {
                        lappend fall [lindex $sigdata($ref) $i]
                        } else {
				puts "Error: (generate_stddev_from_array) Monte-Carlo data: [lindex $sigdata($ref) $i] < $cargs(-min_value) || > $cargs(-max_value)"
			}
                } else {
                        if { ([lindex $sigdata($ref) $i] > $cargs(-min_value)) && ([lindex $sigdata($ref) $i] < $cargs(-max_value)) } {
                        lappend rise [lindex $sigdata($ref) $i]
                        } else {
				puts "Error: (generate_stddev_from_array) Monte-Carlo data: [lindex $sigdata($ref) $i] < $cargs(-min_value) || > $cargs(-max_value)"
                        }
                }
		}
                incr i
                }
          }
	  if { [llength $rise] > 0 } {
          set data [calculate_sigma -datalist rise -min_value $cargs(-min_value) -max_value $cargs(-max_value)]
	  set mean [lindex $data 0]
	  set sigma [lindex $data 1]
	  puts "REF: $refname INDEX: $index EDGE: R MEAN: $mean STDDEV: $sigma"
	  }
	  if { [llength $fall] > 0 } {
          set data [calculate_sigma -datalist fall -min_value $cargs(-min_value) -max_value $cargs(-max_value)]
	  set mean [lindex $data 0]
	  set sigma [lindex $data 1]
	  puts "REF: $refname INDEX: $index EDGE: F MEAN: $mean STDDEV: $sigma"
	  }
	}
	}	
	}
}
define_myproc_attributes -info "generate statistical std deviation from array" -define_args {
  {-cell  "cell name string" "cell name string" string optional}
  {-meas_dir "measure/working file dir" string string optional}
  {-dataarray "array to store measure data" string string required}
  {-depth "list of depth indexes for aocv table" string string optional}
  {-max_logic_depth "max logic depth for Table depth used for cell_chain_mode==sqrtN" string string optional}
  {-del_meas_var "delay measurement variable prefix" string string optional}
  {-rf_meas_var "rf measurement variable prefix" string string optional}
  {-rf_sep "_\\\[12\\\]" string string optional}
} generate_stddev_from_array
echo "Defined procedure 'generate_stddev_from_array'."

### calculate stddev of stages  of array 
proc generate_stage_stddev_from_array { args } {
  set cargs(-cell) ""
  set cargs(-dataarray) ""
  set cargs(-max_value) "999999999999999"
  set cargs(-min_value) "-999999999999999"	
  set cargs(-meas_dir) "."
  set cargs(-sig_digits) 3
  set cargs(-del_meas_var) "\[ap\]ocv_d_o#"
  set cargs(-rf_meas_var) "\[ap\]ocv_rf_o#"
  set cargs(-rf_sep) "_\[1-2\]"
  set cargs(-max_logic_depth) 15
  if { [parse_myproc_arguments -args $args cargs] eq "0"  } {
    return 0
  }

  if { $cargs(-dataarray) eq "" } {
    die "Must use -dataarray option to generate_stage_stdev_from_array"
  }
  upvar 1 $cargs(-dataarray) sigdata
	set cargs(-rf_sep) [string trim $cargs(-rf_sep) "\{\}\""]
	set cargs(-del_meas_var) [string trim $cargs(-del_meas_var) "\{\}\""]
	set cargs(-rf_meas_var) [string trim $cargs(-rf_meas_var) "\{\}\""]
      array set stagedata {}
      foreach refname [lsort [array names sigdata]] {
        if { [regexp $cargs(-del_meas_var) $refname ] } {
          echo "Calculating Stage stddev for: ${refname}"
          regexp "$cargs(-del_meas_var)(\[0-9\]+)_(\[1-2\])" $refname dum index edge
          set rf_name [regsub $cargs(-del_meas_var) $refname $cargs(-rf_meas_var)] 
	  set preindex [expr $index - 1]
	  if { $index > 1 } {
          set prerefname [regsub "$cargs(-del_meas_var)(\[0-9]+\)" $refname "$cargs(-del_meas_var)${preindex}"] 
	  for { set i 0 } { $i < [llength $sigdata($refname)] } { incr i } {
	  lappend stagedata($refname) [expr [lindex $sigdata($refname) $i] - [lindex $sigdata($prerefname) $i]]
	  }
	  } else {
	  set stagedata($refname) $sigdata($refname)
          }
	}
     }
     array unset processed
     foreach refname [lsort [array names stagedata]] {
        set rise {}
        set fall {}
	if { !$processed($refname) } {
          foreach ref [array names stagedata "$cargs(-del_meas_var)${index}$cargs(-rf_sep)"] {
                set processed($ref) 1
                set rf_name [regsub $cargs(-del_meas_var) $ref $cargs(-rf_meas_var)]
                set i 0
                while { $i < [llength $sigdata($rf_name)] } {
		if { [lindex $sigdata($ref) $i] ne "fail" } {
                if { [lindex $sigdata($rf_name) $i] < 0} {
                        if { ([lindex $stagedata($ref) $i] > $cargs(-min_value)) && ([lindex $stagedata($ref) $i] < $cargs(-max_value)) } {
                        lappend fall [lindex $stagedata($ref) $i]
                        } else {
				puts "Error: (generate_stage_stddev_from_array) Monte-Carlo data: [lindex $stagedata($ref) $i] < $cargs(-min_value) || > $cargs(-max_value)"
                        }
                } else {
                        if { ([lindex $stagedata($ref) $i] > $cargs(-min_value)) && ([lindex $stagedata($ref) $i] < $cargs(-max_value)) } {
                        lappend rise [lindex $stagedata($ref) $i]
                        } else {
				puts "Error: (generate_stage_stddev_from_array) Monte-Carlo data: [lindex $stagedata($ref) $i] < $cargs(-min_value) || > $cargs(-max_value)"
                        }
                }
		}
                incr i
                }
	  }
	  if { [llength $rise] > 0 } {
          set data [calculate_sigma -datalist rise -min_value $cargs(-min_value) -max_value $cargs(-max_value)]
	  set mean [lindex $data 0]
	  set sigma [lindex $data 1]
	  puts "REF: ${prerefname}->$refname INDEX: $index EDGE: R STDDEV: $sigma"
	  }
	  if { [llength $rise] > 0 } {
          set data [calculate_sigma -datalist fall -min_value $cargs(-min_value) -max_value $cargs(-max_value)]
	  set mean [lindex $data 0]
	  set sigma [lindex $data 1]
	  puts "REF: ${prerefname}->$refname INDEX: $index EDGE: F STDDEV: $sigma"
	  }
	}
     }
}
define_myproc_attributes -info "generate statistical stddev of stages from array" -define_args {
  {-cell  "cell name string" "cell name string" string optional}
  {-meas_dir "measure/working file dir" string string optional}
  {-dataarray "array to store measure data" string string required}
  {-depth "list of depth indexes for aocv table" string string optional}
} generate_stage_stddev_from_array
echo "Defined procedure 'generate_stage_stddev_from_array'."


### calculate statistical correlation of two stages in array
proc generate_stage_correlation_from_array { args } {
  set cargs(-cell) ""
  set cargs(-dataarray) ""
  set cargs(-max_value) "999999999999999"
  set cargs(-min_value) "-999999999999999"	
  set cargs(-meas_dir) "."
  set cargs(-depth) ""
  set cargs(-max_logic_depth) 15
  set cargs(-qhi) ".99865"
  set cargs(-qlo) ".00135"
  set cargs(-sig_digits) 3
  set cargs(-del_meas_var) "\[ap\]ocv_d_o#"
  set cargs(-rf_meas_var) "\[ap\]ocv_rf_o#"
  set cargs(-rf_sep) "_\[1-2\]"
  set cargs(-stage_comparison_diff) 1

  if { [parse_myproc_arguments -args $args cargs] eq "0"  } {
    return 0
  }

  if { $cargs(-dataarray) eq "" } {
    die "Must use -dataarray option to generate_stage_correlation_from_array"

  }
  upvar 1 $cargs(-dataarray) sigdata
	set cargs(-rf_sep) [string trim $cargs(-rf_sep) "\{\}\""]
	set cargs(-del_meas_var) [string trim $cargs(-del_meas_var) "\{\}\""]
	set cargs(-rf_meas_var) [string trim $cargs(-rf_meas_var) "\{\}\""]

      foreach refname [lsort [array names sigdata]] {
        if { [regexp $cargs(-del_meas_var) $refname ] } {
          echo "Calculating Correlation for: ${refname}"
          regexp "$cargs(-del_meas_var)(\[0-9\]+)_(\[1-2\])" $refname dum index edge
          set rf_name [regsub $cargs(-del_meas_var) $refname $cargs(-rf_meas_var)] 
	  set preindex [expr $index - $cargs(-stage_comparison_diff)]
	  if { $index > $cargs(-stage_comparison_diff) } {
          set prerefname [regsub "$cargs(-del_meas_var)(\[0-9]+\)" $refname "$cargs(-del_meas_var)${preindex}"] 
          set covdata {}
	  for { set i 0 } { $i < [llength $sigdata($refname)] } { incr i } {
	  lappend covdata [expr [lindex $sigdata($refname) $i] * [lindex $sigdata($prerefname) $i]]
	  }
          set mean_xy [calculate_mean -datalist covdata -min_value $cargs(-min_value) -max_value $cargs(-max_value)]
          set data [calculate_sigma -datalist stagedata($refname) -min_value $cargs(-min_value) -max_value $cargs(-max_value)]
	  set mean_x [lindex $data 0]
	  set sigma_x [lindex $data 1]
          set data [calculate_sigma -datalist stagedata($prerefname) -min_value $cargs(-min_value) -max_value $cargs(-max_value)]
	  set mean_y [lindex $data 0]
	  set sigma_y [lindex $data 1]

          set cov [expr $mean_xy - $mean_x * $mean_y]
	  set cor [expr  $cov /($sigma_x * $sigma_y)]

          if { [lindex $sigdata($rf_name) 0] > 0 } {
	   # rising edge
	  puts "REF: ${prerefname}->$refname INDEX: $index EDGE: R COR: $cor"
	  } else {
	   # falling edge
	  puts "REF: ${prerefname}->$refname INDEX: $index EDGE: F COR: $cor"
	  }
	  }
        }
      }
}
define_myproc_attributes -info "generate stastical correlation of stages from array" -define_args {
  {-cell  "cell name string" "cell name string" string optional}
  {-meas_dir "measure/working file dir" string string optional}
  {-dataarray "array to store measure data" string string required}
  {-depth "list of depth indexes for aocv table" string string optional}
  {-max_logic_depth "max logic depth for Table depth used for cell_chain_mode==sqrtN" string string optional}
  {-stage_comparison_diff "difference between stages for covariance(def: 1)" "int" int optional}
  {-del_meas_var "delay measurement variable prefix" string string optional}
  {-rf_meas_var "rf measurement variable prefix" string string optional}
  {-rf_sep "_\\\[12\\\]" string string optional}
} generate_stage_correlation_from_array
echo "Defined procedure 'generate_stage_correlation_from_array'."

### calculate covariance of two consecutive_stages in array
proc generate_stage_covariance_from_array { args } {
  set cargs(-cell) ""
  set cargs(-dataarray) ""
  set cargs(-max_value) "999999999999999"
  set cargs(-min_value) "-999999999999999"	
  set cargs(-meas_dir) "."
  set cargs(-sig_digits) 3
  set cargs(-del_meas_var) "\[ap\]ocv_d_o#"
  set cargs(-rf_meas_var) "\[ap\]ocv_rf_o#"
  set cargs(-rf_sep) "_\[1-2\]"
  set cargs(-stage_comparison_diff) 1
  set cargs(-max_logic_depth) 15
  set cargs(-xcel) 0

  # mean modes are "first last avg max min"
  if { [parse_myproc_arguments -args $args cargs] eq "0"  } {
    return 0
  }

  if { $cargs(-dataarray) eq "" } {
    die "Must use -dataarray option to generate_stage_covariance_from_array"
  }
  upvar 1 $cargs(-dataarray) sigdata
	set cargs(-rf_sep) [string trim $cargs(-rf_sep) "\{\}\""]
	set cargs(-del_meas_var) [string trim $cargs(-del_meas_var) "\{\}\""]
	set cargs(-rf_meas_var) [string trim $cargs(-rf_meas_var) "\{\}\""]
      array unset processed
      foreach refname [lsort [array names sigdata]] {
        if { [regexp $cargs(-del_meas_var) $refname ]} {
          regexp "$cargs(-del_meas_var)(\[0-9\]+)_(\[1-2\])" $refname dum index edge
          set rf_name [regsub $cargs(-del_meas_var) $refname $cargs(-rf_meas_var)] 
	  set preindex [expr $index - $cargs(-stage_comparison_diff)]
	  if { $index > $cargs(-stage_comparison_diff) } {
          set prerefname [regsub "$cargs(-del_meas_var)(\[0-9]+\)" $refname "$cargs(-del_meas_var)${preindex}"] 
          set covdata {}
	  for { set i 0 } { $i < [llength $sigdata($refname)] } { incr i } {
	  lappend covdata [expr [lindex $sigdata($refname) $i] * [lindex $sigdata($prerefname) $i]]
	  }
          set mean_xy [calculate_mean -datalist covdata -min_value $cargs(-min_value) -max_value $cargs(-max_value)]
          set mean_x [calculate_mean -datalist sigdata($refname) -min_value $cargs(-min_value) -max_value $cargs(-max_value)]
          set mean_y [calculate_mean -datalist sigdata($prerefname) -min_value $cargs(-min_value) -max_value $cargs(-max_value)]
          set cov [expr $mean_xy - $mean_x * $mean_y]

          if { [lindex $sigdata($rf_name) 0] > 0 } {
	   # rising edge
          if { $cargs(-xcel) } {
	  puts "${prerefname}->$refname,$index,R,$cov"
	  } else {
	  puts "REF: ${prerefname}->$refname INDEX: $index EDGE: R COV: $cov"
	  }
	  } else {
	   # falling edge
          if { $cargs(-xcel) } {
	  puts "${prerefname}->$refname,$index,F,$cov"
	  } else {
	  puts "REF: ${prerefname}->$refname INDEX: $index EDGE: F COV: $cov"
	  }
	  }
	  }
        }
      }
}
define_myproc_attributes -info "generate stage covariance from array" -define_args {
  {-cell  "cell name string" "cell name string" string optional}
  {-meas_dir "measure/working file dir" string string optional}
  {-dataarray "array to store measure data" string string required}
  {-max_logic_depth "max read logic depth(def -max_logic_depth)" int int optional}
  {-del_meas_var "delay measurement variable prefix" string string optional}
  {-rf_meas_var "rf measurement variable prefix" string string optional}
  {-rf_sep "_\\\[12\\\]" string string optional}
  {-sig_digits "sig digits for data" int int optional}
  {-min_value "minimum value allowed for data" float float optional}
  {-max_value "maximum value allowed for data" float float optional}
  {-stage_comparison_diff "difference between stages for covariance(def: 1)" "int" int optional}
  {-xcel "xcel format" "" boolean optional}
} generate_stage_covariance_from_array
echo "Defined procedure 'generate_stage_covariance_from_array'."

proc is_even { var } {
	set num [expr ($var + 1) / 2]
	if { $num eq [expr int($var/2)] } {
		return 1
	} else {
		return 0
	}
}

### calculate delay variation from an array of samples
proc generate_delay_variation_coeff_from_array { args } {
  set cargs(-supply) ""
  set cargs(-cell) ""
  set cargs(-dataarray) ""
  set cargs(-resultsarray) ""
  set cargs(-max_value) "999999999999999"
  set cargs(-min_value) "-999999999999999"	
  set cargs(-meas_dir) "."
  set cargs(-depth) ""
  set cargs(-max_logic_depth) 15
  set cargs(-qhi) ".99865"
  set cargs(-qlo) ".00135"
  set cargs(-sig_digits) 3
  set cargs(-del_meas_var) "\[ap\]ocv_d_o#"
  set cargs(-rf_meas_var) "\[ap\]ocv_rf_o#"
  set cargs(-rf_sep) "_\[12\]"
  set cargs(-coeff) ""
  set cargs(-path_ordered) 1
  set cargs(-nmos) "nch_mac"
  set cargs(-pmos) "pch_mac"
  set cargs(-debug) 0
  set cargs(-nmos_vdd) ""
  set cargs(-pmos_vdd) ""
  set cargs(-nmos_length) ""
  set cargs(-pmos_length) ""
  set cargs(-nmos_width) ""
  set cargs(-pmos_width) ""
  set cargs(-nmos_nfin) ""
  set cargs(-pmos_nfin) ""
  set cargs(-nmos_nf) ""
  set cargs(-pmos_nf) ""
  set cargs(-append) 0
	# mean_mode == avg/depth/worst/best/first
	# sigma_mode == avg/depth/avg_at_each_depth/worst/best/first
  set cargs(-mean_mode) "avg"
  set cargs(-sigma_mode) "avg"
  # mean modes are "first last avg max min"
  if { [parse_myproc_arguments -args $args cargs] eq "0"  } {
    return 0
  }


  if { $cargs(-dataarray) eq "" } {
    die "Must use -dataarray option to generate_delay_variation_coeff_from_array"
  }
  upvar 1 $cargs(-dataarray) sigdata

  if { $cargs(-resultsarray) ne "" } {
  upvar 1 $cargs(-resultsarray) resdata
  } else {
	array unset resdata
  }

  set vdd ""
  if {$cargs(-supply) ne ""} {
      foreach key1 $cargs(-supply)  {
        while {[regexp "(\[^ \t\]+)\=(\[^ \t\]+)" $key1 dum port value] } {
           set supply([string tolower $port]) $value
           regsub "(\[^ \t\]+)\=(\[^ \t\]+)" $key1 {} key1
           if {($vdd eq "") && ($value > 0.001)} {
            set vdd $value
           }
        }
      }

   }
	set cargs(-rf_sep) [string trim $cargs(-rf_sep) "\{\}\""]
	set cargs(-del_meas_var) [string trim $cargs(-del_meas_var) "\{\}\""]
	set cargs(-rf_meas_var) [string trim $cargs(-rf_meas_var) "\{\}\""]

      array set dprocessed {}
      array set sprocessed {}
      foreach refname [lsort [array names sigdata]] {
        #separate data into rise and fall data
        # look at both <del_meas_var><#>_2
        if { [regexp $cargs(-del_meas_var) $refname ] && ![info exists dprocessed($refname)]} {
          regexp "$cargs(-del_meas_var)(\[0-9\]+)($cargs(-rf_sep))" $refname dum index rfsep
          if {$index <= $cargs(-max_logic_depth)} {
          echo "Calculating Quantile for: $refname"
          # gather rise and fall data arrivals
        set rise {}
        set fall {}
        array unset rf 
          foreach ref [array names sigdata "$cargs(-del_meas_var)${index}$cargs(-rf_sep)"] {
                set dprocessed($ref) 1
                set rf_name [regsub $cargs(-del_meas_var) $ref $cargs(-rf_meas_var)]
                regexp "$cargs(-del_meas_var)(\[0-9\]+)($cargs(-rf_sep))" $ref dum index rfsep
		if { $cargs(-path_ordered) } {
                     set i 0
                     while { $i < [llength $sigdata($ref)] } {
                        if { ([lindex $sigdata($ref) $i] > $cargs(-min_value)) && ([lindex $sigdata($ref) $i] < $cargs(-max_value)) } {
                        lappend rf($rfsep) [lindex $sigdata($ref) $i]
			}
                        incr i
		     }
		}
          }
        if { $cargs(-path_ordered) } {
	  foreach key [array names rf] {
          set data [calculate_quantile -qlo $cargs(-qlo) -qhi $cargs(-qhi) -datalist rf($key) -min_value $cargs(-min_value) -max_value $cargs(-max_value)]
          set mean [lindex $data 0]
          set lo [lindex $data 1]
          set hi [lindex $data 2]
	  set delay($key,$index) [list $mean $lo $hi]
          }
         }
	   }

         } elseif { [regexp $cargs(-rf_meas_var) $refname ] && ![info exists sprocessed($refname)]} {
          regexp "$cargs(-rf_meas_var)(\[0-9\]+)($cargs(-rf_sep))" $refname dum index rfsep
          if {$index <= $cargs(-max_logic_depth)} {
          echo "Calculating Quantile for: $refname"
          # gather rise and fall data arrivals
        set rise {}
        set fall {}
        array unset rf
          foreach ref [array names sigdata "$cargs(-rf_meas_var)${index}$cargs(-rf_sep)"] {
                regexp "$cargs(-rf_meas_var)(\[0-9\]+)($cargs(-rf_sep))" $ref dum index rfsep
                set sprocessed($ref) 1
                set rf_name [regsub $cargs(-rf_meas_var) $ref $cargs(-rf_meas_var)]
		if { $cargs(-path_ordered) } {
                     set i 0
                     while { $i < [llength $sigdata($ref)] } {
                        if { ([lindex $sigdata($ref) $i] > $cargs(-min_value)) && ([lindex $sigdata($ref) $i] < $cargs(-max_value)) } {
                        lappend rf($rfsep) [lindex $sigdata($ref) $i]
			}
                        incr i
		     }
		}
          }
        if { $cargs(-path_ordered) } {
	  foreach key [array names rf] {
          set data [calculate_quantile -qlo $cargs(-qlo) -qhi $cargs(-qhi) -datalist rf($key) -min_value $cargs(-min_value) -max_value $cargs(-max_value)]
          set mean [lindex $data 0]
          set lo [lindex $data 1]
          set hi [lindex $data 2]
	  set slew($key,$index) [list $mean $lo $hi]
          }
       }
	}
       }
     }
	if { $cargs(-coeff) ne "" } {
		echo "Generating variation coefficients with mean_mode=$cargs(-mean_mode) and sigma_mode=$cargs(-sigma_mode) using depths=$cargs(-max_logic_depth) and saving to file($cargs(-coeff))"

#
		if { $cargs(-append) } {
		set fout [open $cargs(-coeff) a]
		} else {
		set fout [open $cargs(-coeff) w]
		}
	        #puts $fout "INDEX,EDGE,SLEW_MEAN,DELAY_MEAN,DELAY-3sigma,DELAY+3sigma"
	        puts $fout "# variation coefficients created by Tcl script: generated_delay_variation_coeff_from_array"
		set pdata {}
		set nmos_cnt 0
		set pmos_cnt 0
		set nmos_coeff_min 0
		set nmos_coeff_max 0
		set pmos_coeff_min 0
		set pmos_coeff_max 0
		set nmos_coeff_min_cnt 0
		set nmos_coeff_max_cnt 0
		set pmos_coeff_min_cnt 0
		set pmos_coeff_max_cnt 0
		set nmos_coeff_max_avg 0
		set nmos_coeff_min_avg 0
		set pmos_coeff_max_avg 0
		set pmos_coeff_min_avg 0
		set nmos_mean 0
		set nmos_mean_cnt 0
		set pmos_mean 0
		set pmos_mean_cnt 0
 		set pmos_dep 0
 		set nmos_dep 0
		set pmos_mean_avg 0
		set nmos_mean_avg 0
#(1Sig_Delay(1)-Mean(1))^2= PMOS_mean*PMOS_var_coeff_max^2    (R)
#(1Sig_Delay(2)-Mean(2))^2= PMOS_mean*PMOS_var_coeff_max^2 + NMOS_mean*NMOS_var_coeff_max^2 (F)
#(1Sig_Delay(3)-Mean(3))^2= 2PMOS_mean*PMOS_var_coeff_max^2 + NMOS_mean*NMOS_var_coeff_max^2  (R)
#(1Sig_Delay(4)-Mean(4))^2= 2PMOS_mean*PMOS_var_coeff_max^2 + 2NMOS_mean*NMOS_var_coeff_max^2  (F)

#(1Sig_Delay(1)-Mean(1))^2= NMOS_mean*NMOS_var_coeff_max^2    (F)
#(1Sig_Delay(2)-Mean(2))^2= NMOS_mean*PMOS_var_coeff_max^2 + PMOS_mean*NMOS_var_coeff_max^2 (R)
#(1Sig_Delay(3)-Mean(3))^2= 2NMOS_mean*PMOS_var_coeff_max^2 + PMOS_mean*NMOS_var_coeff_max^2  (F)
#(1Sig_Delay(4)-Mean(4))^2= 2NMOS_mean*PMOS_var_coeff_max^2 + 2PMOS_mean*NMOS_var_coeff_max^2  (R)

#(Mean(1) - 1Sig_Delay(1))^2= PMOS_mean*PMOS_var_coeff_min^2    (R)
#(Mean(2) - 1Sig_Delay(2))^2= PMOS_mean*PMOS_var_coeff_min^2 + NMOS_mean*NMOS_var_coeff_min^2 (F)
#(Mean(3) - 1Sig_Delay(3))^2= 2PMOS_mean*PMOS_var_coeff_min^2 + NMOS_mean*NMOS_var_coeff_min^2  (R)
#(Mean(4) - 1Sig_Delay(4))^2= 2PMOS_mean*PMOS_var_coeff_min^2 + 2NMOS_mean*NMOS_var_coeff_min^2  (F)
                foreach ref [lsort -dict [array names delay ]] {
                        if { [info exists slew($ref)] } {
				# has slew rate
			regexp ",(\[^,\]+)$" $ref dummy index
			regsub ",(\[^,\]+)$" $ref {} key
			set prevind [expr $index - 1]
			set prevref "$key,$prevind"
			set path_var_max [expr (([lindex $delay($ref) 2] - [lindex $delay($ref) 0]) / 3 )]
			set path_var_max [expr $path_var_max * $path_var_max]
			set path_var_min [expr (([lindex $delay($ref) 0] - [lindex $delay($ref) 1]) / 3 )]
			set path_var_min [expr $path_var_min * $path_var_min]
			if { $cargs(-debug) } {
				puts "
path_var_max=$path_var_max path_var_min=$path_var_min"
			}

			if { $cargs(-path_ordered) } {
			if { ($slew($ref) > 0) } {
				# rising pmos varition
					if {[is_even $index] } {
						# path starting edge was rising input, depth=1 edge=fall, current edge is rising edge=rise
						set nmos_dep [expr $index/2]
						set pmos_dep [expr $index/2]
					} else {
						# path starting edge was fallng input, depth=1 edge=rise
						# calculate the active pmos and nmos depth for the path
						set nmos_dep [expr int([expr $index/2])]
						set pmos_dep [expr $index - $pmos_dep]
					}
			if { $cargs(-debug) } {
				puts "Processing Index=$index Key=$key Edge=R nmos_dep=$nmos_dep pmos_dep=$pmos_dep"
			}

				if { $cargs(-mean_mode) eq "worst" } {
				    if { $index > 1 } {
					set pmos_mean [expr [lindex $delay($ref) 0] - [lindex $delay($prevref) 0]]
				    } else { 
					set pmos_mean [lindex $delay($ref) 0]
				    }
				   if { ($pmos_mean_avg == 0) || ($pmos_mean > $pmos_mean_avg) } {
					set pmos_mean_avg $pmos_mean
				   }
				   incr pmos_mean_cnt
				} elseif { $cargs(-mean_mode) eq "best" } {
				    if { $index > 1 } {
					set pmos_mean [expr [lindex $delay($ref) 0] - [lindex $delay($prevref) 0]]
				    } else { 
					set pmos_mean [lindex $delay($ref) 0]
				    }
				   if { ($pmos_mean_avg == 0) || ($pmos_mean < $pmos_mean_avg) } {
					set pmos_mean_avg $pmos_mean
				   }
				   incr pmos_mean_cnt
				} elseif { $cargs(-mean_mode) eq "avg" } {
				    if { $index > 1 } {
					set pmos_mean [expr [lindex $delay($ref) 0] - [lindex $delay($prevref) 0]]
				    } else { 
					set pmos_mean [lindex $delay($ref) 0]
				    }
				   incr pmos_mean_cnt
				   set pmos_mean_avg [expr ([expr $pmos_mean_avg *  [expr $pmos_mean_cnt -1]] +  $pmos_mean)  / $pmos_mean_cnt]
				} elseif {$cargs(-mean_mode) eq "first" } {
				    if { $index > 1 } {
					set pmos_mean [expr [lindex $delay($ref) 0] - [lindex $delay($prevref) 0]]
				    } else { 
					set pmos_mean [lindex $delay($ref) 0]
				    }
					if { $index == 1 } {
					set pmos_mean_avg $pmos_mean
					}
				        incr pmos_mean_cnt
				} elseif {$cargs(-mean_mode) eq "depth" } {
				    if { $index > 1 } {
					set pmos_mean [expr [lindex $delay($ref) 0] - [lindex $delay($prevref) 0]]
				    } else { 
					set pmos_mean [lindex $delay($ref) 0]
				    }
					set pmos_mean_avg $pmos_mean
				        incr pmos_mean_cnt
				}

				if { $cargs(-sigma_mode) eq "avg"} {
						if { $index > 1 } {
                                                if { $nmos_coeff_max_cnt > 0 } {
                                                #set nmos_coeff_max_avg [expr $pmos_coeff_max / $pmos_coeff_max_cnt]
                                                set pmos_coeff_max  [expr ($path_var_max-($nmos_dep * $nmos_mean_avg * $nmos_mean_avg * $nmos_coeff_max))/($pmos_dep * $pmos_mean_avg * $pmos_mean_avg)]
                                                incr pmos_coeff_max_cnt
						set pmos_coeff_max_avg [expr ([expr $pmos_coeff_max_avg * [expr $pmos_coeff_max_cnt - 1]] + $pmos_coeff_max) / $pmos_coeff_max_cnt]
                                                } else {
                                                puts "Error: missing nmos_coeff_max to calculate pmos_coeff_max for depth=$index with edge=R"
                                                }
                                                if { $nmos_coeff_min_cnt > 0 } {
                                                #set nmos_coeff_min_avg [expr $pmos_coeff_min / $pmos_coeff_min_cnt]
                                                set pmos_coeff_min  [expr ($path_var_min-($nmos_dep * $nmos_mean_avg * $nmos_mean_avg * $nmos_coeff_min))/($pmos_dep * $pmos_mean_avg * $pmos_mean_avg)]
                                                incr pmos_coeff_min_cnt
						set pmos_coeff_min_avg [expr ([expr $pmos_coeff_min_avg * [expr $pmos_coeff_min_cnt - 1]] + $pmos_coeff_min) / $pmos_coeff_min_cnt]
                                                } else {
                                                puts "Error: missing nmos_coeff_min to calculate pmos_coeff_min for depth=$index with edge=R"
                                                }
						} else {

					set pmos_coeff_max [expr $path_var_max / ($pmos_mean_avg * $pmos_mean_avg)]
					incr pmos_coeff_max_cnt
						set pmos_coeff_max_avg [expr ([expr $pmos_coeff_max_avg * [expr $pmos_coeff_max_cnt - 1]] + $pmos_coeff_max) / $pmos_coeff_max_cnt]

					set pmos_coeff_min [expr $path_var_min / ($pmos_mean_avg * $pmos_mean_avg)]
					incr pmos_coeff_min_cnt
						set pmos_coeff_min_avg [expr ([expr $pmos_coeff_min_avg * [expr $pmos_coeff_min_cnt - 1]] + $pmos_coeff_min) / $pmos_coeff_min_cnt]

						}
				} elseif { $cargs(-sigma_mode) eq "avg_at_each_depth"} {
						if { $index > 1 } {
                                                if { $nmos_coeff_max_cnt > 0 } {
                                                #set nmos_coeff_max_avg [expr $pmos_coeff_max / $pmos_coeff_max_cnt]
                                                set pmos_coeff_max  [expr ($path_var_max-($nmos_dep * $nmos_mean_avg * $nmos_mean_avg * $nmos_coeff_max_avg))/($pmos_dep * $pmos_mean_avg * $pmos_mean_avg)]
                                                incr pmos_coeff_max_cnt
						set pmos_coeff_max_avg [expr ([expr $pmos_coeff_max_avg * [expr $pmos_coeff_max_cnt - 1]] + $pmos_coeff_max) / $pmos_coeff_max_cnt]
                                                } else {
                                                puts "Error: missing nmos_coeff_max to calculate pmos_coeff_max for depth=$index with edge=R"
                                                }
                                                if { $nmos_coeff_min_cnt > 0 } {
                                                #set nmos_coeff_min_avg [expr $pmos_coeff_min / $pmos_coeff_min_cnt]
                                                set pmos_coeff_min  [expr ($path_var_min-($nmos_dep * $nmos_mean_avg * $nmos_mean_avg * $nmos_coeff_min_avg))/($pmos_dep * $pmos_mean_avg * $pmos_mean_avg)]
                                                incr pmos_coeff_min_cnt
						set pmos_coeff_min_avg [expr ([expr $pmos_coeff_min_avg * [expr $pmos_coeff_min_cnt - 1]] + $pmos_coeff_min) / $pmos_coeff_min_cnt]
                                                } else {
                                                puts "Error: missing nmos_coeff_min to calculate pmos_coeff_min for depth=$index with edge=R"
                                                }
						} else {
					set pmos_coeff_max [expr $path_var_max / ($pmos_mean_avg * $pmos_mean_avg)]
					incr pmos_coeff_max_cnt
						set pmos_coeff_max_avg [expr ([expr $pmos_coeff_max_avg * [expr $pmos_coeff_max_cnt - 1]] + $pmos_coeff_max) / $pmos_coeff_max_cnt]
					set pmos_coeff_min [expr $path_var_min / ($pmos_mean_avg * $pmos_mean_avg)]
					incr pmos_coeff_min_cnt
						set pmos_coeff_min_avg [expr ([expr $pmos_coeff_min_avg * [expr $pmos_coeff_min_cnt - 1]] + $pmos_coeff_min) / $pmos_coeff_min_cnt]
						}
				} elseif { ($cargs(-sigma_mode) eq "worst")} {
						# have to determine use total variation and calculate the equivalent coeff using nmos and cmos 
						puts "index=$index nmos_depth=$nmos_dep pmos_depth=$pmos_dep"
						if { $index > 1 } {
                                                if { $nmos_coeff_max_cnt > 0 } {
                                                #set nmos_coeff_max_avg [expr $nmos_coeff_max / $nmos_coeff_max_cnt]
                                                set pmos_coeff_max  [expr ($path_var_max-($nmos_dep * $nmos_mean_avg * $nmos_mean_avg * $nmos_coeff_max))/($pmos_dep * $pmos_mean_avg * $pmos_mean_avg)]
                                                incr pmos_coeff_max_cnt
						if { ($pmos_coeff_max_avg == 0) || ( $pmos_coeff_max_avg < $pmos_coeff_max) } {
						set pmos_coeff_max_avg $pmos_coeff_max
						}
                                                } else {
                                                puts "Error: missing nmos_coeff_max to calculate pmos_coeff_max for depth=$index with edge=R"
                                                }
                                                if { $nmos_coeff_min_cnt > 0 } {
                                                #set nmos_coeff_min_avg [expr $nmos_coeff_min / $nmos_coeff_min_cnt]
                                                set pmos_coeff_min  [expr ($path_var_min-($nmos_dep * $nmos_mean_avg * $nmos_mean_avg * $nmos_coeff_min))/($pmos_dep * $pmos_mean_avg * $pmos_mean_avg)]
                                                incr pmos_coeff_min_cnt
						if { ($pmos_coeff_min_avg == 0) || ($pmos_coeff_min_avg < $pmos_coeff_min) } {
						set pmos_coeff_min_avg $pmos_coeff_min
						}
                                                } else {
                                                puts "Error: missing nmos_coeff_min to calculate pmos_coeff_min for depth=$index with edge=R"
                                                }
						} else {
					set pmos_coeff_max [expr $path_var_max / ($pmos_mean_avg * $pmos_mean_avg)]
					set pmos_coeff_min [expr $path_var_min / ($pmos_mean_avg * $pmos_mean_avg)]
					incr pmos_coeff_max_cnt
					incr pmos_coeff_min_cnt
						if { ($pmos_coeff_max_avg == 0) || ( $pmos_coeff_max_avg < $pmos_coeff_max) } {
					set pmos_coeff_max_avg $pmos_coeff_max
						}
						if { ($pmos_coeff_min_avg == 0) || ($pmos_coeff_min_avg < $pmos_coeff_min) } {
					set pmos_coeff_min_avg $pmos_coeff_min
						}
						}
				} elseif { ($cargs(-sigma_mode) eq "best")} {
						# have to determine use total variation and calculate the equivalent coeff using nmos and cmos 
						puts "index=$index nmos_depth=$nmos_dep pmos_depth=$pmos_dep"
						if { $index > 1 } {
                                                if { $nmos_coeff_max_cnt > 0 } {
                                                #set nmos_coeff_max_avg [expr $nmos_coeff_max / $nmos_coeff_max_cnt]
                                                set pmos_coeff_max  [expr ($path_var_max-($nmos_dep * $nmos_mean_avg * $nmos_mean_avg * $nmos_coeff_max))/($pmos_dep * $pmos_mean_avg * $pmos_mean_avg)]
                                                incr pmos_coeff_max_cnt
						if { ($pmos_coeff_max_avg == 0) || ( $pmos_coeff_max_avg > $pmos_coeff_max) } {
						set pmos_coeff_max_avg $pmos_coeff_max
						}
                                                } else {
                                                puts "Error: missing nmos_coeff_max to calculate pmos_coeff_max for depth=$index with edge=R"
                                                }
                                                if { $nmos_coeff_min_cnt > 0 } {
                                                #set nmos_coeff_min_avg [expr $nmos_coeff_min / $nmos_coeff_min_cnt]
                                                set pmos_coeff_min  [expr ($path_var_min-($nmos_dep * $nmos_mean_avg * $nmos_mean_avg * $nmos_coeff_min))/($pmos_dep * $pmos_mean_avg * $pmos_mean_avg)]
                                                incr pmos_coeff_min_cnt
						if { ($pmos_coeff_min_avg == 0) || ($pmos_coeff_min_avg > $pmos_coeff_min) } {
						set pmos_coeff_min_avg $pmos_coeff_min
						}
                                                } else {
                                                puts "Error: missing nmos_coeff_min to calculate pmos_coeff_min for depth=$index with edge=R"
                                                }
						} else {
					set pmos_coeff_max [expr $path_var_max / ($pmos_mean_avg * $pmos_mean_avg)]
					set pmos_coeff_min [expr $path_var_min / ($pmos_mean_avg * $pmos_mean_avg)]
					incr pmos_coeff_max_cnt
					incr pmos_coeff_min_cnt
						if { ($pmos_coeff_max_avg == 0) || ( $pmos_coeff_max_avg > $pmos_coeff_max) } {
					set pmos_coeff_max_avg $pmos_coeff_max
						}
						if { ($pmos_coeff_min_avg == 0) || ($pmos_coeff_min_avg > $pmos_coeff_min) } {
					set pmos_coeff_min_avg $pmos_coeff_min
						}
						}
				} elseif { ($cargs(-sigma_mode) eq "first")} {
						puts "index=$index nmos_depth=$nmos_dep pmos_depth=$pmos_dep"
						if { $index > 1 } {
                                                if { $nmos_coeff_max_cnt > 0 } {
                                                #set nmos_coeff_max_avg [expr $nmos_coeff_max / $nmos_coeff_max_cnt]
                                                set pmos_coeff_max  [expr ($path_var_max-($nmos_dep * $nmos_mean * $nmos_mean * $nmos_coeff_max))/($pmos_dep * $pmos_mean * $pmos_mean)]
                                                incr pmos_coeff_max_cnt
						if { $index == 1 } {
						set pmos_coeff_max_avg $pmos_coeff_max
						}
                                                } else {
                                                puts "Error: missing nmos_coeff_max to calculate pmos_coeff_max for depth=$index with edge=R"
                                                }
                                                if { $nmos_coeff_min_cnt > 0 } {
                                                #set nmos_coeff_min_avg [expr $nmos_coeff_min / $nmos_coeff_min_cnt]
                                                set pmos_coeff_min  [expr ($path_var_min-($nmos_dep * $nmos_mean * $nmos_mean * $nmos_coeff_min))/($pmos_dep * $pmos_mean * $pmos_mean)]
                                                incr pmos_coeff_min_cnt
						if { $index == 1 } {
						set pmos_coeff_min_avg $pmos_coeff_min
						}
                                                } else {
                                                puts "Error: missing nmos_coeff_min to calculate pmos_coeff_min for depth=$index with edge=R"
                                                }
						} else {
					set pmos_coeff_max [expr $path_var_max / ($pmos_mean_avg * $pmos_mean_avg)]
					set pmos_coeff_min [expr $path_var_min / ($pmos_mean_avg * $pmos_mean_avg)]
					incr pmos_coeff_max_cnt
					incr pmos_coeff_min_cnt
						if { $index == 1 } {
					set pmos_coeff_max_avg $pmos_coeff_max
					set pmos_coeff_min_avg $pmos_coeff_min
						}
						}
				} elseif { ($cargs(-sigma_mode) eq "depth")} {
						puts "index=$index nmos_depth=$nmos_dep pmos_depth=$pmos_dep"
						if { $index > 1 } {
                                                if { $nmos_coeff_max_cnt > 0 } {
                                                #set nmos_coeff_max_avg [expr $nmos_coeff_max / $nmos_coeff_max_cnt]
                                                set pmos_coeff_max  [expr ($path_var_max-($nmos_dep * $nmos_mean_avg * $nmos_mean_avg * $nmos_coeff_max))/($pmos_dep * $pmos_mean_avg * $pmos_mean_avg)]
                                                incr pmos_coeff_max_cnt
						if { $index == $cargs(-max_logic_depth) } {
						set pmos_coeff_max_avg $pmos_coeff_max
						}
                                                } else {
                                                puts "Error: missing nmos_coeff_max to calculate pmos_coeff_max for depth=$index with edge=R"
                                                }
                                                if { $nmos_coeff_min_cnt > 0 } {
                                                #set nmos_coeff_min_avg [expr $nmos_coeff_min / $nmos_coeff_min_cnt]
                                                set pmos_coeff_min  [expr ($path_var_min-($nmos_dep * $nmos_mean_avg * $nmos_mean_avg * $nmos_coeff_min))/($pmos_dep * $pmos_mean_avg * $pmos_mean_avg)]
                                                incr pmos_coeff_min_cnt
						if { $index == $cargs(-max_logic_depth) } {
						set pmos_coeff_min_avg $pmos_coeff_min
						}
                                                } else {
                                                puts "Error: missing nmos_coeff_min to calculate pmos_coeff_min for depth=$index with edge=R"
                                                }
						} else {
					set pmos_coeff_max [expr $path_var_max / ($pmos_mean_avg * $pmos_mean_avg)]
					set pmos_coeff_min [expr $path_var_min / ($pmos_mean_avg * $pmos_mean_avg)]
					incr pmos_coeff_max_cnt
					incr pmos_coeff_min_cnt
						if { $index == $cargs(-max_logic_depth) } {
					set pmos_coeff_max_avg $pmos_coeff_max
					set pmos_coeff_min_avg $pmos_coeff_min
						}
						}
				}


					if { $cargs(-debug) } {
						puts "Debug: depth=$index edge=R pmos_mean_avg=$pmos_mean_avg  nmos_mean_avg=$nmos_mean_avg"
						puts "Debug: pmos_coeff_max=$pmos_coeff_max pmos_coeff_min=$pmos_coeff_min"
						puts "Debug: nmos_coeff_max=$nmos_coeff_max nmos_coeff_min=$nmos_coeff_min"
						puts "Debug: pmos_coeff_max_avg=$pmos_coeff_max_avg pmos_coeff_min_avg=$pmos_coeff_min_avg"
						puts "Debug: nmos_coeff_max_avg=$nmos_coeff_max_avg nmos_coeff_min_avg=$nmos_coeff_min_avg"
					}

			} else {
				# falling nmos variation
					if {[is_even $index] } {
						# path starting edge was falling input, depth=1 edge=rise
						set nmos_dep [expr $index/2]
						set pmos_dep [expr $index/2]
					} else {
						# path starting edge was rising input, depth=1 edge=fall
						# calculate the active pmos and nmos depth for the path
						set pmos_dep [expr int([expr $index/2])]
						set nmos_dep [expr $index - $pmos_dep]
					}
			if { $cargs(-debug) } {
				puts "Processing Index=$index Key=$key Edge=F nmos_dep=$nmos_dep pmos_dep=$pmos_dep"
			}
				if { $cargs(-mean_mode) eq "worst" } {
				    if { $index > 1 } {
					set nmos_mean [expr [lindex $delay($ref) 0] - [lindex $delay($prevref) 0]]
				    } else { 
					set nmos_mean [lindex $delay($ref) 0]
				    }
				   if { ($nmos_mean_avg == 0) || ($nmos_mean > $nmos_mean_avg) } {
					set nmos_mean_avg $nmos_mean
				   }
				   incr nmos_mean_cnt
				} elseif { $cargs(-mean_mode) eq "best" } {
				    if { $index > 1 } {
					set nmos_mean [expr [lindex $delay($ref) 0] - [lindex $delay($prevref) 0]]
				    } else { 
					set nmos_mean [lindex $delay($ref) 0]
				    }
				   if { ($nmos_mean_avg == 0) || ($nmos_mean < $nmos_mean_avg) } {
					set nmos_mean_avg $nmos_mean
				   }
				   incr nmos_mean_cnt
				} elseif { $cargs(-mean_mode) eq "avg" } {
				    if { $index > 1 } {
					set nmos_mean [expr [lindex $delay($ref) 0] - [lindex $delay($prevref) 0]]
				    } else { 
					set nmos_mean [lindex $delay($ref) 0]
				    }
				   incr nmos_mean_cnt
				   set nmos_mean_avg [expr ([expr $nmos_mean_avg  * [expr $nmos_mean_cnt -1]] +  $nmos_mean) / $nmos_mean_cnt]
				} elseif {$cargs(-mean_mode) eq "first" } {
				    if { $index > 1 } {
					set nmos_mean [expr [lindex $delay($ref) 0] - [lindex $delay($prevref) 0]]
				    } else { 
					set nmos_mean [lindex $delay($ref) 0]
				    }
					if { $index == 1 } {
					set nmos_mean_avg $nmos_mean
					}
				   incr nmos_mean_cnt
				} elseif {$cargs(-mean_mode) eq "depth" } {
				    if { $index > 1 } {
					set nmos_mean [expr [lindex $delay($ref) 0] - [lindex $delay($prevref) 0]]
				    } else { 
					set nmos_mean [lindex $delay($ref) 0]
				    }
					set nmos_mean_avg $nmos_mean
				   incr nmos_mean_cnt
				}

				if { $cargs(-sigma_mode) eq "avg"} {
						if { $index > 1 } {
                                                if { $pmos_coeff_max_cnt > 0 } {
                                                #set pmos_coeff_max_avg [expr $pmos_coeff_max / $pmos_coeff_max_cnt]
                                                set nmos_coeff_max  [expr ($path_var_max-($pmos_dep * $pmos_mean_avg * $pmos_mean_avg * $pmos_coeff_max))/($nmos_dep * $nmos_mean_avg * $nmos_mean_avg)]
                                                incr nmos_coeff_max_cnt
						set nmos_coeff_max_avg [expr ([expr $nmos_coeff_max_avg  * [expr $nmos_coeff_max_cnt - 1]] + $nmos_coeff_max) / $nmos_coeff_max_cnt]
                                                } else {
                                                puts "Error: missing pmos_coeff_max to calculate nmos_coeff_max for depth=$index with edge=F"
                                                }
                                                if { $pmos_coeff_min_cnt > 0 } {
                                                #set pmos_coeff_min_avg [expr $pmos_coeff_min / $pmos_coeff_min_cnt]
                                                set nmos_coeff_min  [expr ($path_var_min-($pmos_dep * $pmos_mean_avg * $pmos_mean_avg * $pmos_coeff_min))/($nmos_dep * $nmos_mean_avg * $nmos_mean_avg)]
                                                incr nmos_coeff_min_cnt
						set nmos_coeff_min_avg [expr ([expr $nmos_coeff_min_avg * [expr $nmos_coeff_min_cnt - 1]] + $nmos_coeff_min) / $nmos_coeff_min_cnt]
                                                } else {
                                                puts "Error: missing pmos_coeff_min to calculate nmos_coeff_min for depth=$index with edge=F"
                                                }
						} else {
					set nmos_coeff_max [expr $path_var_max / ($nmos_mean_avg * $nmos_mean_avg)]
					incr nmos_coeff_max_cnt
						set nmos_coeff_max_avg [expr ([expr $nmos_coeff_max_avg * [expr $nmos_coeff_max_cnt - 1]] + $nmos_coeff_max) / $nmos_coeff_max_cnt]
					set nmos_coeff_min [expr $path_var_min / ($nmos_mean_avg * $nmos_mean_avg)]
					incr nmos_coeff_min_cnt
						set nmos_coeff_min_avg [expr ([expr $nmos_coeff_min_avg * [expr $nmos_coeff_min_cnt - 1]] + $nmos_coeff_min) / $nmos_coeff_min_cnt]
						}
				} elseif { $cargs(-sigma_mode) eq "avg_at_each_depth"} {
						if { $index > 1 } {
                                                if { $pmos_coeff_max_cnt > 0 } {
                                                #set pmos_coeff_max_avg [expr $pmos_coeff_max / $pmos_coeff_max_cnt]
                                                set nmos_coeff_max  [expr ($path_var_max-($pmos_dep * $pmos_mean_avg * $pmos_mean_avg * $pmos_coeff_max_avg))/($nmos_dep * $nmos_mean_avg * $nmos_mean_avg)]
                                                incr nmos_coeff_max_cnt
						set nmos_coeff_max_avg [expr ([expr $nmos_coeff_max_avg * [expr $nmos_coeff_max_cnt - 1]] + $nmos_coeff_max) / $nmos_coeff_max_cnt]
                                                } else {
                                                puts "Error: missing pmos_coeff_max to calculate nmos_coeff_max for depth=$index with edge=F"
                                                }
                                                if { $pmos_coeff_min_cnt > 0 } {
                                                #set pmos_coeff_min_avg [expr $pmos_coeff_min / $pmos_coeff_min_cnt]
                                                set nmos_coeff_min  [expr ($path_var_min-($pmos_dep * $pmos_mean_avg * $pmos_mean_avg * $pmos_coeff_min_avg))/($nmos_dep * $nmos_mean_avg * $nmos_mean_avg)]
                                                incr nmos_coeff_min_cnt
						set nmos_coeff_min_avg [expr ([expr $nmos_coeff_min_avg * [expr $nmos_coeff_min_cnt - 1]] + $nmos_coeff_min) / $nmos_coeff_min_cnt]
                                                } else {
                                                puts "Error: missing pmos_coeff_min to calculate nmos_coeff_min for depth=$index with edge=F"
                                                }
						} else {
					set nmos_coeff_max [expr $path_var_max / ($nmos_mean_avg * $nmos_mean_avg)]
					incr nmos_coeff_max_cnt
						set nmos_coeff_max_avg [expr ([expr $nmos_coeff_max_avg * [expr $nmos_coeff_max_cnt - 1]] + $nmos_coeff_max) / $nmos_coeff_max_cnt]
					set nmos_coeff_min [expr $path_var_min / ($nmos_mean_avg * $nmos_mean_avg)]
					incr nmos_coeff_min_cnt
						set nmos_coeff_min_avg [expr ([expr $nmos_coeff_min_avg * [expr $nmos_coeff_min_cnt - 1]] + $nmos_coeff_min) / $nmos_coeff_min_cnt]
						}
				} elseif { ($cargs(-sigma_mode) eq "worst")} {
						puts "index=$index nmos_depth=$nmos_dep pmos_depth=$pmos_dep"
						# have to determine use total variation and calculate the equivalent coeff using nmos and cmos 
						if { $index > 1 } {
                                                if { $pmos_coeff_max_cnt > 0 } {
                                                #set pmos_coeff_max_avg [expr $pmos_coeff_max / $pmos_coeff_max_cnt]
                                                set nmos_coeff_max  [expr ($path_var_max-($pmos_dep * $pmos_mean_avg * $pmos_mean_avg * $pmos_coeff_max))/($nmos_dep * $nmos_mean_avg * $nmos_mean_avg)]
                                                incr nmos_coeff_max_cnt
						if { ($nmos_coeff_max_avg == 0) || ($nmos_coeff_max_avg < $nmos_coeff_max) } {
						set nmos_coeff_max_avg $nmos_coeff_max
						}
                                                } else {
                                                puts "Error: missing pmos_coeff_max to calculate nmos_coeff_max for depth=$index with edge=F"
                                                }
                                                if { $pmos_coeff_min_cnt > 0 } {
                                                #set pmos_coeff_min_avg [expr $pmos_coeff_min / $pmos_coeff_min_cnt]
                                                set nmos_coeff_min  [expr ($path_var_min-($pmos_dep * $pmos_mean_avg * $pmos_mean_avg * $pmos_coeff_min))/($nmos_dep * $nmos_mean_avg * $nmos_mean_avg)]
                                                incr nmos_coeff_min_cnt
						if { ($nmos_coeff_min_avg == 0) || ($nmos_coeff_min_avg < $nmos_coeff_min) } {
						set nmos_coeff_min_avg $nmos_coeff_min
						}
                                                } else {
                                                puts "Error: missing pmos_coeff_min to calculate nmos_coeff_min for depth=$index with edge=F"
                                                }
						} else {
					set nmos_coeff_max [expr $path_var_max / ($nmos_mean * $nmos_mean)]
					set nmos_coeff_min [expr $path_var_min / ($nmos_mean * $nmos_mean)]
					incr nmos_coeff_max_cnt
					incr nmos_coeff_min_cnt
						if { ($nmos_coeff_max_avg == 0) || ($nmos_coeff_max_avg < $nmos_coeff_max) } {
					set nmos_coeff_max_avg $nmos_coeff_max
						}
						if { ($nmos_coeff_min_avg == 0) || ($nmos_coeff_min_avg < $nmos_coeff_min) } {
					set nmos_coeff_min_avg $nmos_coeff_min
						}
						}
				} elseif { ($cargs(-sigma_mode) eq "best")} {
						puts "index=$index nmos_depth=$nmos_dep pmos_depth=$pmos_dep"
						# have to determine use total variation and calculate the equivalent coeff using nmos and cmos 
						if { $index > 1 } {
                                                if { $pmos_coeff_max_cnt > 0 } {
                                                #set pmos_coeff_max_avg [expr $pmos_coeff_max / $pmos_coeff_max_cnt]
                                                set nmos_coeff_max  [expr ($path_var_max-($pmos_dep * $pmos_mean_avg * $pmos_mean_avg * $pmos_coeff_max))/($nmos_dep * $nmos_mean_avg * $nmos_mean_avg)]
                                                incr nmos_coeff_max_cnt
						if { ($nmos_coeff_max_avg == 0) || ($nmos_coeff_max_avg > $nmos_coeff_max) } {
						set nmos_coeff_max_avg $nmos_coeff_max
						}
                                                } else {
                                                puts "Error: missing pmos_coeff_max to calculate nmos_coeff_max for depth=$index with edge=F"
                                                }
                                                if { $pmos_coeff_min_cnt > 0 } {
                                                #set pmos_coeff_min_avg [expr $pmos_coeff_min / $pmos_coeff_min_cnt]
                                                set nmos_coeff_min  [expr ($path_var_min-($pmos_dep * $pmos_mean_avg * $pmos_mean_avg * $pmos_coeff_min))/($nmos_dep * $nmos_mean_avg * $nmos_mean_avg)]
                                                incr nmos_coeff_min_cnt
						if { ($nmos_coeff_min_avg == 0) || ($nmos_coeff_min_avg > $nmos_coeff_min) } {
						set nmos_coeff_min_avg $nmos_coeff_min
						}
                                                } else {
                                                puts "Error: missing pmos_coeff_min to calculate nmos_coeff_min for depth=$index with edge=F"
                                                }
						} else {
					set nmos_coeff_max [expr $path_var_max / ($nmos_mean * $nmos_mean)]
					set nmos_coeff_min [expr $path_var_min / ($nmos_mean * $nmos_mean)]
					incr nmos_coeff_max_cnt
					incr nmos_coeff_min_cnt
						if { ($nmos_coeff_max_avg == 0) || ($nmos_coeff_max_avg > $nmos_coeff_max) } {
					set nmos_coeff_max_avg $nmos_coeff_max
						}
						if { ($nmos_coeff_min_avg == 0) || ($nmos_coeff_min_avg > $nmos_coeff_min) } {
					set nmos_coeff_min_avg $nmos_coeff_min
						}
						}
				} elseif { ($cargs(-sigma_mode) eq "first")} {
						puts "index=$index nmos_depth=$nmos_dep pmos_depth=$pmos_dep"
						# have to determine use total variation and calculate the equivalent coeff using nmos and cmos 
						if { $index > 1 } {
                                                if { $pmos_coeff_max_cnt > 0 } {
                                                #set pmos_coeff_max_avg [expr $pmos_coeff_max / $pmos_coeff_max_cnt]
                                                set nmos_coeff_max  [expr ($path_var_max-($pmos_dep * $pmos_mean * $pmos_mean * $pmos_coeff_max))/($nmos_dep * $nmos_mean * $nmos_mean)]
                                                incr nmos_coeff_max_cnt
						if { $index == 1 } {
						set nmos_coeff_max_avg $nmos_coeff_max
						}
                                                } else {
                                                puts "Error: missing pmos_coeff_max to calculate nmos_coeff_max for depth=$index with edge=F"
                                                }
                                                if { $pmos_coeff_min_cnt > 0 } {
                                                #set pmos_coeff_min_avg [expr $pmos_coeff_min / $pmos_coeff_min_cnt]
                                                set nmos_coeff_min  [expr ($path_var_min-($pmos_dep * $pmos_mean * $pmos_mean * $pmos_coeff_min))/($nmos_dep * $nmos_mean * $nmos_mean)]
                                                incr nmos_coeff_min_cnt
						if { $index == 1 } {
						set nmos_coeff_min_avg $nmos_coeff_min
						}
                                                } else {
                                                puts "Error: missing pmos_coeff_min to calculate nmos_coeff_min for depth=$index with edge=F"
                                                }
						} else {
					set nmos_coeff_max [expr $path_var_max / ($nmos_mean * $nmos_mean)]
					set nmos_coeff_min [expr $path_var_min / ($nmos_mean * $nmos_mean)]
					incr nmos_coeff_max_cnt
					incr nmos_coeff_min_cnt
						if { $index == 1 } {
					set nmos_coeff_max_avg $nmos_coeff_max
					set nmos_coeff_min_avg $nmos_coeff_min
						}
						}
				} elseif { ($cargs(-sigma_mode) eq "depth")} {
						puts "index=$index nmos_depth=$nmos_dep pmos_depth=$pmos_dep"
						# have to determine use total variation and calculate the equivalent coeff using nmos and cmos 
						if { $index > 1 } {
                                                if { $pmos_coeff_max_cnt > 0 } {
                                                #set pmos_coeff_max_avg [expr $pmos_coeff_max / $pmos_coeff_max_cnt]
                                                set nmos_coeff_max  [expr ($path_var_max-($pmos_dep * $pmos_mean_avg * $pmos_mean_avg * $pmos_coeff_max))/($nmos_dep * $nmos_mean_avg * $nmos_mean_avg)]
                                                incr nmos_coeff_max_cnt
						if { $index == $cargs(-max_logic_depth) } {
						set nmos_coeff_max_avg $nmos_coeff_max
						}
                                                } else {
                                                puts "Error: missing pmos_coeff_max to calculate nmos_coeff_max for depth=$index with edge=F"
                                                }
                                                if { $pmos_coeff_min_cnt > 0 } {
                                                #set pmos_coeff_min_avg [expr $pmos_coeff_min / $pmos_coeff_min_cnt]
                                                set nmos_coeff_min  [expr ($path_var_min-($pmos_dep * $pmos_mean_avg * $pmos_mean_avg * $pmos_coeff_min))/($nmos_dep * $nmos_mean_avg * $nmos_mean_avg)]
                                                incr nmos_coeff_min_cnt
						if { $index == $cargs(-max_logic_depth) } {
						set nmos_coeff_min_avg $nmos_coeff_min
						}
                                                } else {
                                                puts "Error: missing pmos_coeff_min to calculate nmos_coeff_min for depth=$index with edge=F"
                                                }
						} else {
					set nmos_coeff_max [expr $path_var_max / ($nmos_mean * $nmos_mean)]
					set nmos_coeff_min [expr $path_var_min / ($nmos_mean * $nmos_mean)]
					incr nmos_coeff_max_cnt
					incr nmos_coeff_min_cnt
						if { $index == $cargs(-max_logic_depth) } {
					set nmos_coeff_max_avg $nmos_coeff_max
					set nmos_coeff_min_avg $nmos_coeff_min
						}
						}
				}

					if { $cargs(-debug) } {
						puts "Debug: depth=$index edge=F pmos_mean_avg=$pmos_mean_avg  nmos_mean_avg=$nmos_mean_avg"
						puts "Debug: pmos_coeff_max=$pmos_coeff_max pmos_coeff_min=$pmos_coeff_min"
						puts "Debug: nmos_coeff_max=$nmos_coeff_max nmos_coeff_min=$nmos_coeff_min"
						puts "Debug: pmos_coeff_max_avg=$pmos_coeff_max_avg pmos_coeff_min_avg=$pmos_coeff_min_avg"
						puts "Debug: nmos_coeff_max_avg=$nmos_coeff_max_avg nmos_coeff_min_avg=$nmos_coeff_min_avg"
					}

			}
			}
			}
                }
		set opt "-transistor_model $cargs(-nmos)"
		if { $cargs(-nmos_length) ne "" } {
		append opt " -length $cargs(-nmos_length)"
		} 
		if { $cargs(-nmos_vdd) ne "" } {
		append opt " -voltage $cargs(-nmos_vdd)"
		} elseif { $vdd ne "" } {
		append opt " -voltage $vdd"
		}
		if { $cargs(-nmos_width) ne "" } {
		append opt " -width $cargs(-nmos_width)"
		} elseif { $cargs(-nmos_nfin) ne "" } {
		append opt " -nfin $cargs(-nmos_nfin)"
		}	
		if { $cargs(-nmos_nf) ne "" } {
		append opt " -nf $cargs(-nmos_nf)"
		}

		if { $nmos_coeff_max_cnt > 0 } {
		puts " $nmos_coeff_max_cnt > 0 : nmos_coeff_max_cnt"
		puts " $nmos_coeff_max_avg : nmos_coeff_max_avg"
		set nmos_coeff_max [expr sqrt($nmos_coeff_max_avg)]
		puts $fout "set_variation_parameters -max -type nmos $opt -variation $nmos_coeff_max"
		}
		if { $nmos_coeff_min_cnt > 0 } {
		set nmos_coeff_min [expr sqrt($nmos_coeff_min_avg)]
		puts $fout "set_variation_parameters -min -type nmos $opt -variation $nmos_coeff_min"
		}

		set opt "-transistor_model $cargs(-pmos)"
		if { $cargs(-pmos_length) ne "" } {
		append opt " -length $cargs(-pmos_length)"
		} 
		if { $cargs(-pmos_vdd) ne "" } {
		append opt " -voltage $cargs(-pmos_vdd)"
		} elseif { $vdd ne "" } {
		append opt " -voltage $vdd"
		}
		if { $cargs(-pmos_width) ne "" } {
		append opt " -width $cargs(-pmos_width)"
		} elseif { $cargs(-pmos_nfin) ne "" } {
		append opt " -nfin $cargs(-pmos_nfin)"
		}	
		if { $cargs(-pmos_nf) ne "" } {
		append opt " -nf $cargs(-pmos_nf)"
		}	

		if { $pmos_coeff_max_cnt > 0 } {
		set pmos_coeff_max [expr sqrt($pmos_coeff_max_avg)]
		puts $fout "set_variation_parameters -max -type pmos $opt -variation $pmos_coeff_max"
		}
		if { $pmos_coeff_min_cnt > 0 } {
		set pmos_coeff_min [expr sqrt($pmos_coeff_min_avg)]
		puts $fout "set_variation_parameters -min -type pmos $opt -variation $pmos_coeff_min"
		}

		close $fout
	}
}
define_myproc_attributes -info "generate variation coefficient from array" -define_args {
  {-supply  "supply" "list of supplies" string optional}
  {-cell  "cell name string" "cell name string" string optional}
  {-meas_dir "measure/working file dir" string string optional}
  {-dataarray "array to store measure data" string string required}
  {-resultsarray "array to store calculated data" string string optional}
  {-depth "list of depth indexes for aocv table" string string optional}
  {-max_logic_depth "max logic depth for Table depth" string string optional}
  {-qlo "Low quantile value (between 0 and 1)" float float optional}
  {-qhi "High quantile value (between 0 and 1)" float float optional}
  {-rf_meas_var "rf measurement variable prefix" string string optional}
  {-rf_sep "_\\\[12\\\]" string string optional}
  {-sig_digits "sig digits for data" int int optional}
  {-min_value "minimum value allowed for data" float float optional}
  {-max_value "maximum value allowed for data" float float optional}
  {-coeff "coeff file" "filename" string optional}
  {-path_ordered "path ordered results(default)" "" boolean optional}
  {-add_slew_var "add slew variation to report" "" boolean optional}
  {-rf_meas_var "rf measurement variable prefix" string string optional}
  {-nmos "nmos name" string string optional}
  {-nmos_length "nmos length in um" float float optional}
  {-nmos_vdd "nmos vdd in volts" float float optional}
  {-nmos_width "nmos width in um" float float optional}
  {-nmos_nfin "nmos nfin in um" float float optional}
  {-nmos_nf "nmos nf" int int optional}
  {-pmos "pmos name" string string optional}
  {-pmos_length "pmos length in um" float float optional}
  {-nmos_vdd "pmos vdd in volts" float float optional}
  {-pmos_width "pmos width in um" float float optional}
  {-pmos_nfin "pmos nfin in um" float float optional}
  {-pmos_nf "pmos nf" int int optional}
  {-mean_mode "mode to calculate mean(avg/depth)" string string optional}
  {-sigma_mode "mode to calculate sigma(avg/depth/avg_at_each_depth)" string string optional}
  {-append "add variation information to end of coeff file" "" boolean optional}
  {-debug "add debug information" "" boolean optional}
} generate_delay_variation_coeff_from_array 
echo "Defined procedure 'generate_delay_variation_coeff_from_array'."

### calculate delay variation from an array of samples
proc generate_slewdelay_variation_from_array { args } {
  set cargs(-cell) ""
  set cargs(-dataarray) ""
  set cargs(-resultsarray) ""
  set cargs(-max_value) "999999999999999"
  set cargs(-min_value) "-999999999999999"	
  set cargs(-meas_dir) "."
  set cargs(-depth) ""
  set cargs(-max_logic_depth) 15
  set cargs(-qhi) ".99865"
  set cargs(-qlo) ".00135"
  set cargs(-sig_digits) 3
  set cargs(-del_meas_var) "\[ap\]ocv_d_o#"
  set cargs(-rf_meas_var) "\[ap\]ocv_rf_o#"
  set cargs(-rf_sep) "_\[12\]"
  set cargs(-xcel) ""
  set cargs(-add_slew_var) 0
  set cargs(-path_ordered) 0

  # mean modes are "first last avg max min"
  if { [parse_myproc_arguments -args $args cargs] eq "0"  } {
    return 0
  }

  if { $cargs(-dataarray) eq "" } {
    die "Must use -dataarray option to generate_delay_variation_from_array"
  }
  upvar 1 $cargs(-dataarray) sigdata

  if { $cargs(-resultsarray) ne "" } {
  upvar 1 $cargs(-resultsarray) resdata
  } else {
	array unset resdata
  }
	set cargs(-rf_sep) [string trim $cargs(-rf_sep) "\{\}\""]
	set cargs(-del_meas_var) [string trim $cargs(-del_meas_var) "\{\}\""]
	set cargs(-rf_meas_var) [string trim $cargs(-rf_meas_var) "\{\}\""]

      array set dprocessed {}
      array set sprocessed {}
      foreach refname [lsort [array names sigdata]] {
        #separate data into rise and fall data
        # look at both <del_meas_var><#>_2
        if { [regexp $cargs(-del_meas_var) $refname ] && ![info exists dprocessed($refname)]} {
          regexp "$cargs(-del_meas_var)(\[0-9\]+)($cargs(-rf_sep))" $refname dum index rfsep
          if {$index <= $cargs(-max_logic_depth)} {
          echo "Calculating Quantile for: $refname"
          # gather rise and fall data arrivals
        set rise {}
        set fall {}
        array unset rf 
          foreach ref [array names sigdata "$cargs(-del_meas_var)${index}$cargs(-rf_sep)"] {
                set dprocessed($ref) 1
                set rf_name [regsub $cargs(-del_meas_var) $ref $cargs(-rf_meas_var)]
                regexp "$cargs(-del_meas_var)(\[0-9\]+)($cargs(-rf_sep))" $ref dum index rfsep
		if { $cargs(-path_ordered) } {
                     set i 0
                     while { $i < [llength $sigdata($ref)] } {
                        if { ([lindex $sigdata($ref) $i] > $cargs(-min_value)) && ([lindex $sigdata($ref) $i] < $cargs(-max_value)) } {
                        lappend rf($rfsep) [lindex $sigdata($ref) $i]
			}
                        incr i
		     }
		} else {
                set i 0
                while { $i < [llength $sigdata($rf_name)] } {
		if { [lindex $sigdata($ref) $i] ne "fail" } {
                if { [lindex $sigdata($rf_name) $i] < 0} {
                        if { ([lindex $sigdata($ref) $i] > $cargs(-min_value)) && ([lindex $sigdata($ref) $i] < $cargs(-max_value)) } {
                        lappend fall [lindex $sigdata($ref) $i]
                        } else {
				puts "Error: (generate_slewdelay_variation_from_array) Monte-Carlo data: [lindex $sigdata($ref) $i] < $cargs(-min_value) || > $cargs(-max_value)"
                        }
                } else {
                        if { ([lindex $sigdata($ref) $i] > $cargs(-min_value)) && ([lindex $sigdata($ref) $i] < $cargs(-max_value)) } {
                        lappend rise [lindex $sigdata($ref) $i]
                        } else {
				puts "Error: (generate_slewdelay_variation_from_array) Monte-Carlo data: [lindex $sigdata($ref) $i] < $cargs(-min_value) || > $cargs(-max_value)"
                        }
                }
                }
                incr i
		}
		}
          }
	}
        if { $cargs(-path_ordered) } {
	  foreach key [array names rf] {
          set data [calculate_quantile -qlo $cargs(-qlo) -qhi $cargs(-qhi) -datalist rf($key) -min_value $cargs(-min_value) -max_value $cargs(-max_value)]
          set mean [lindex $data 0]
          set lo [lindex $data 1]
          set hi [lindex $data 2]
	  set delay($key,$index) [list $mean $lo $hi]
          }
        } else {
	  if { [llength $rise] > 0 } {
          set data [calculate_quantile -qlo $cargs(-qlo) -qhi $cargs(-qhi) -datalist rise -min_value $cargs(-min_value) -max_value $cargs(-max_value)]
          set mean [lindex $data 0]
          set lo [lindex $data 1]
          set hi [lindex $data 2]
	  set delay($index,R) [list $mean $lo $hi]
	  }
	  if { [llength $fall] > 0 } {
          set data [calculate_quantile -qlo $cargs(-qlo) -qhi $cargs(-qhi) -datalist fall -min_value $cargs(-min_value) -max_value $cargs(-max_value)]
          set mean [lindex $data 0]
          set lo [lindex $data 1]
          set hi [lindex $data 2]
	  set delay($index,F) [list $mean $lo $hi]
	  }
         }
         } elseif { [regexp $cargs(-rf_meas_var) $refname ] && ![info exists sprocessed($refname)]} {
          regexp "$cargs(-rf_meas_var)(\[0-9\]+)($cargs(-rf_sep))" $refname dum index rfsep
          if {$index <= $cargs(-max_logic_depth)} {
          echo "Calculating Quantile for: $refname"
          # gather rise and fall data arrivals
        set rise {}
        set fall {}
        array unset rf
          foreach ref [array names sigdata "$cargs(-rf_meas_var)${index}$cargs(-rf_sep)"] {
                regexp "$cargs(-rf_meas_var)(\[0-9\]+)($cargs(-rf_sep))" $ref dum index rfsep
                set sprocessed($ref) 1
                set rf_name [regsub $cargs(-rf_meas_var) $ref $cargs(-rf_meas_var)]
		if { $cargs(-path_ordered) } {
                     set i 0
                     while { $i < [llength $sigdata($ref)] } {
                        if { ([lindex $sigdata($ref) $i] > $cargs(-min_value)) && ([lindex $sigdata($ref) $i] < $cargs(-max_value)) } {
                        lappend rf($rfsep) [lindex $sigdata($ref) $i]
			}
                        incr i
		     }
		} else {
                set i 0
                while { $i < [llength $sigdata($rf_name)] } {
		if { [lindex $sigdata($ref) $i] ne "fail" } {
                if { [lindex $sigdata($rf_name) $i] < 0} {
                        if { ([lindex $sigdata($ref) $i] > $cargs(-min_value)) && ([lindex $sigdata($ref) $i] < $cargs(-max_value)) } {
                        lappend fall [lindex $sigdata($ref) $i]
                        } else {
				puts "Error: (generate_slewdelay_variation_from_array) Monte-Carlo data: [lindex $sigdata($ref) $i] < $cargs(-min_value) || > $cargs(-max_value)"
                        }
                } else {
                        if { ([lindex $sigdata($ref) $i] > $cargs(-min_value)) && ([lindex $sigdata($ref) $i] < $cargs(-max_value)) } {
                        lappend rise [lindex $sigdata($ref) $i]
                        } else {
				puts "Error: (generate_slewdelay_variation_from_array) Monte-Carlo data: [lindex $sigdata($ref) $i] < $cargs(-min_value) || > $cargs(-max_value)"
                        }
                }
                }
                incr i
		}
		}
          }
	}
        if { $cargs(-path_ordered) } {
	  foreach key [array names rf] {
          set data [calculate_quantile -qlo $cargs(-qlo) -qhi $cargs(-qhi) -datalist rf($key) -min_value $cargs(-min_value) -max_value $cargs(-max_value)]
          set mean [lindex $data 0]
          set lo [lindex $data 1]
          set hi [lindex $data 2]
	  set slew($key,$index) [list $mean $lo $hi]
          }
        } else {
	  if { [llength $rise] > 0 } {
          set data [calculate_quantile -qlo $cargs(-qlo) -qhi $cargs(-qhi) -datalist rise -min_value $cargs(-min_value) -max_value $cargs(-max_value)]
          set mean [lindex $data 0]
          set lo [lindex $data 1]
          set hi [lindex $data 2]
	  set slew(R,$index) [list $mean $lo $hi]
	  }
	  if { [llength $fall] > 0 } {
          set data [calculate_quantile -qlo $cargs(-qlo) -qhi $cargs(-qhi) -datalist fall -min_value $cargs(-min_value) -max_value $cargs(-max_value)]
          set mean [lindex $data 0]
          set lo [lindex $data 1]
          set hi [lindex $data 2]
	  set slew(F,$index) [list $mean $lo $hi]
	  }
	}
         }
       }
	if { $cargs(-xcel) ne "" } {
		echo "Generating Xcel file($cargs(-xcel)) with variation data"
		set fout [open $cargs(-xcel) w]
		if { $cargs(-add_slew_var) } {		
	        puts $fout "INDEX,EDGE,SLEW_MEAN,SLEW-3sigma,SLEW+3sigma,DELAY_MEAN,DELAY-3sigma,DELAY+3sigma"
		} else {
	        puts $fout "INDEX,EDGE,SLEW_MEAN,DELAY_MEAN,DELAY-3sigma,DELAY+3sigma"
		}
		set pdata {}
                foreach ref [lsort -dict [array names delay ]] {
                        if { [info exists slew($ref)] } {
			regsub "(\[^,\]+)," $ref {} key
			set prevkey [expr $key - 1]
			regsub ",$key" $ref ",$prevkey" prevref
			if { $cargs(-path_ordered) } {
			if { ($slew($ref) > 0) } {
				# rising
			if { $cargs(-add_slew_var) } {
                        puts $fout "$key,R,[lindex $slew($ref) 0],[lindex $slew($ref) 1],[lindex $slew($ref) 2],[lindex $delay($ref) 0],[lindex $delay($ref) 1],[lindex $delay($ref) 2]"
			} else {
                        puts $fout "$key,R,[lindex $slew($ref) 0],[lindex $delay($ref) 0],[lindex $delay($ref) 1],[lindex $delay($ref) 2]"
			}
			} else {
				# falling
			if { $cargs(-add_slew_var) } {
                        puts $fout "$key,F,[lindex $slew($ref) 0],[lindex $slew($ref) 1],[lindex $slew($ref) 2],[lindex $delay($ref) 0],[lindex $delay($ref) 1],[lindex $delay($ref) 2]"
			} else {
                        puts $fout "$key,F,[lindex $slew($ref) 0],[lindex $delay($ref) 0],[lindex $delay($ref) 1],[lindex $delay($ref) 2]"
			}
			}
			} else {
			if { ($slew($ref) > 0) } {
				# rising
			if { $cargs(-add_slew_var) } {
                        puts $fout "$key,R,[lindex $slew($ref) 0],[lindex $slew($ref) 1],[lindex $slew($ref) 2],[lindex $delay($ref) 0],[lindex $delay($ref) 1],[lindex $delay($ref) 2]"
			} else {
                        puts $fout "$key,R,[lindex $slew($ref) 0],[lindex $delay($ref) 0],[lindex $delay($ref) 1],[lindex $delay($ref) 2]"
			}
			} else {
			if { $cargs(-add_slew_var) } {
                        append pdata "$key,F,[lindex $slew($ref) 0],[lindex $slew($ref) 1],[lindex $slew($ref) 2],[lindex $delay($ref) 0],[lindex $delay($ref) 1],[lindex $delay($ref) 2]\n"
			} else {
                        append pdata "$key,F,[lindex $slew($ref) 0],[lindex $delay($ref) 0],[lindex $delay($ref) 1],[lindex $delay($ref) 2]\n"
			}
                        }
			}
                        } else {
                        if { [regexp ",F" $ref] } {
                        append pdata "$ref,,[lindex $delay($ref) 0],[lindex $delay($ref) 1],[lindex $delay($ref) 2]\n"
                        } else {
                        puts $fout "$ref,,[lindex $delay($ref) 0],[lindex $delay($ref) 1],[lindex $delay($ref) 2]"
                        }
                        }
                }
                puts $fout $pdata
		close $fout
	}
	
}
define_myproc_attributes -info "generate slew and delay variation from array" -define_args {
  {-cell  "cell name string" "cell name string" string optional}
  {-meas_dir "measure/working file dir" string string optional}
  {-dataarray "array to store measure data" string string required}
  {-resultsarray "array to store calculated data" string string optional}
  {-depth "list of depth indexes for aocv table" string string optional}
  {-max_logic_depth "max logic depth for Table depth" string string optional}
  {-qlo "Low quantile value (between 0 and 1)" float float optional}
  {-qhi "High quantile value (between 0 and 1)" float float optional}
  {-rf_meas_var "rf measurement variable prefix" string string optional}
  {-rf_sep "_\\\[12\\\]" string string optional}
  {-sig_digits "sig digits for data" int int optional}
  {-min_value "minimum value allowed for data" float float optional}
  {-max_value "maximum value allowed for data" float float optional}
  {-xcel "xcel file" "filename" string optional}
  {-path_ordered "path ordered results" "" boolean optional}
  {-add_slew_var "add slew variation to report" "" boolean optional}
} generate_slewdelay_variation_from_array
echo "Defined procedure 'generate_slewdelay_variation_from_array'."

### calculate delay variation from an array of samples
proc generate_equivalent_1sigma_variation_from_array { args } {
  set cargs(-cell) ""
  set cargs(-dataarray) ""
  set cargs(-resultsarray) ""
  set cargs(-max_value) "999999999999999"
  set cargs(-min_value) "-999999999999999"	
  set cargs(-meas_dir) "."
  set cargs(-depth) ""
  set cargs(-max_logic_depth) 15
  set cargs(-qhi) ".99865"
  set cargs(-qlo) ".00135"
  set cargs(-sig_digits) 3
  set cargs(-del_meas_var) "\[ap\]ocv_d_o#"
  set cargs(-rf_meas_var) "\[ap\]ocv_rf_o#"
  set cargs(-rf_sep) "_\[1-2\]"
  set cargs(-xcel) ""
  set cargs(-add_slew_var) 0
  set cargs(-path_ordered) 0

  # mean modes are "first last avg max min"
  if { [parse_myproc_arguments -args $args cargs] eq "0"  } {
    return 0
  }

  if { $cargs(-dataarray) eq "" } {
    die "Must use -dataarray option to generate_delay_variation_from_array"
  }
  upvar 1 $cargs(-dataarray) sigdata

  if { $cargs(-resultsarray) ne "" } {
  upvar 1 $cargs(-resultsarray) resdata
  } else {
	array unset resdata
  }

	set cargs(-rf_sep) [string trim $cargs(-rf_sep) "\{\}\""]
	set cargs(-del_meas_var) [string trim $cargs(-del_meas_var) "\{\}\""]
	set cargs(-rf_meas_var) [string trim $cargs(-rf_meas_var) "\{\}\""]

	   if { $cargs(-xcel) ne "" } {
		echo "Generating Xcel file($cargs(-xcel)) with variation data"
		set fout [open $cargs(-xcel) w]
	        puts $fout "INDEX,EDGE,DELAY_MEAN,DELAY-3sigma,DELAY+3sigma"
	   }
      array set processed {}
      foreach refname [lsort [array names sigdata]] {
        #separate data into rise and fall data
        # look at both <del_meas_var><#>_2
        if { [regexp $cargs(-del_meas_var) $refname ] && ![info exists processed($refname)]} {
          regexp "$cargs(-del_meas_var)(\[0-9\]+)" $refname dum index
          if {$index <= $cargs(-max_logic_depth)} {
	  if { ! $cargs(-xcel) } {
          echo "Calculating Quantile for: $refname"
	  }
          # gather rise and fall data arrivals
        set rise {}
        set fall {}
          foreach ref [array names sigdata "$cargs(-del_meas_var)${index}$cargs(-rf_sep)"] {
                set processed($ref) 1
                set rf_name [regsub $cargs(-del_meas_var) $ref $cargs(-rf_meas_var)]
                set i 0
                while { $i < [llength $sigdata($rf_name)] } {
		if { [lindex $sigdata($ref) $i] ne "fail" } {
                if { [lindex $sigdata($rf_name) $i] < 0} {
                        if { ([lindex $sigdata($ref) $i] > $cargs(-min_value)) && ([lindex $sigdata($ref) $i] < $cargs(-max_value)) } {
                        lappend fall [lindex $sigdata($ref) $i]
                        } else {
				puts "Error: (generate_delay_variation_from_array) Monte-Carlo data: [lindex $sigdata($ref) $i] < $cargs(-min_value) || > $cargs(-max_value)"
                        }
                } else {
                        if { ([lindex $sigdata($ref) $i] > $cargs(-min_value)) && ([lindex $sigdata($ref) $i] < $cargs(-max_value)) } {
                        lappend rise [lindex $sigdata($ref) $i]
                        } else {
				puts "Error: (generate_delay_variation_from_array) Monte-Carlo data: [lindex $sigdata($ref) $i] < $cargs(-min_value) || > $cargs(-max_value)"
                        }
                }
                }
                incr i
		}
          }
	}
	  if { [llength $rise] > 0 } {
          set data [calculate_quantile -qlo $cargs(-qlo) -qhi $cargs(-qhi) -datalist rise -min_value $cargs(-min_value) -max_value $cargs(-max_value)]
          set mean [lindex $data 0]
          set lo [lindex $data 1]
          set hi [lindex $data 2]
	  if { $cargs(-xcel) } {
	  puts $fout "$index,R,$mean,$lo,$hi"
          } elseif { $cargs(-resultsarray) ne "" } {
	  set resdata($index,R) [list $mean $lo $hi]
	  } else {
	  puts "REF: $refname INDEX: $index EDGE: R MEAN: $mean LO: $lo HI: $hi"
	  }
	  }
	  if { [llength $fall] > 0 } {
          set data [calculate_quantile -qlo $cargs(-qlo) -qhi $cargs(-qhi) -datalist fall -min_value $cargs(-min_value) -max_value $cargs(-max_value)]
          set mean [lindex $data 0]
          set lo [lindex $data 1]
          set hi [lindex $data 2]
	  if { $cargs(-xcel) } {
	  puts $fout "$index,F,$mean,$lo,$hi"
          } elseif { $cargs(-resultsarray) ne "" } {
	  set resdata($index,F) [list $mean $lo $hi]
	  } else {
	  puts "REF: $refname INDEX: $index EDGE: F MEAN: $mean LO: $lo HI: $hi"
	  }
	  }
        }
      }
        if { $cargs(-ntvfile) ne "" } {
		close $fout
	}
}
define_myproc_attributes -info "generate equivalent 1sigma variat given depth from array" -define_args {
  {-cell  "cell name string" "cell name string" string optional}
  {-meas_dir "measure/working file dir" string string optional}
  {-dataarray "array to store measure data" string string required}
  {-resultsarray "array to store calculated data" string string optional}
  {-depth "list of depth indexes for aocv table" string string optional}
  {-max_logic_depth "max logic depth for Table depth" string string optional}
  {-qlo "Low quantile value (between 0 and 1)" float float optional}
  {-qhi "High quantile value (between 0 and 1)" float float optional}
  {-rf_meas_var "rf measurement variable prefix" string string optional}
  {-rf_sep "_\\\[12\\\]" string string optional}
  {-sig_digits "sig digits for data" int int optional}
  {-min_value "minimum value allowed for data" float float optional}
  {-max_value "maximum value allowed for data" float float optional}
  {-ntvfile "variation file" "filename" string optional}
} generate_equivalent_1sigma_variation_from_array 
echo "Defined procedure 'generate_equivalent_1sigma_variation_from_array '."
### calculate delay variation from an array of samples
proc generate_delay_variation_from_array { args } {
  set cargs(-cell) ""
  set cargs(-dataarray) ""
  set cargs(-resultsarray) ""
  set cargs(-max_value) "999999999999999"
  set cargs(-min_value) "-999999999999999"	
  set cargs(-meas_dir) "."
  set cargs(-depth) ""
  set cargs(-max_logic_depth) 15
  set cargs(-qhi) ".99865"
  set cargs(-qlo) ".00135"
  set cargs(-sig_digits) 3
  set cargs(-del_meas_var) "\[ap\]ocv_d_o#"
  set cargs(-rf_meas_var) "\[ap\]ocv_rf_o#"
  set cargs(-rf_sep) "_\[1-2\]"
  set cargs(-xcel) ""
  set cargs(-add_slew_var) 0
  set cargs(-path_ordered) 0

  # mean modes are "first last avg max min"
  if { [parse_myproc_arguments -args $args cargs] eq "0"  } {
    return 0
  }

  if { $cargs(-dataarray) eq "" } {
    die "Must use -dataarray option to generate_delay_variation_from_array"
  }
  upvar 1 $cargs(-dataarray) sigdata

  if { $cargs(-resultsarray) ne "" } {
  upvar 1 $cargs(-resultsarray) resdata
  } else {
	array unset resdata
  }

	set cargs(-rf_sep) [string trim $cargs(-rf_sep) "\{\}\""]
	set cargs(-del_meas_var) [string trim $cargs(-del_meas_var) "\{\}\""]
	set cargs(-rf_meas_var) [string trim $cargs(-rf_meas_var) "\{\}\""]

	   if { $cargs(-xcel) ne "" } {
		echo "Generating Xcel file($cargs(-xcel)) with variation data"
		set fout [open $cargs(-xcel) w]
	        puts $fout "INDEX,EDGE,DELAY_MEAN,DELAY-3sigma,DELAY+3sigma"
	   }
      array set processed {}
      foreach refname [lsort [array names sigdata]] {
        #separate data into rise and fall data
        # look at both <del_meas_var><#>_2
        if { [regexp $cargs(-del_meas_var) $refname ] && ![info exists processed($refname)]} {
          regexp "$cargs(-del_meas_var)(\[0-9\]+)" $refname dum index
          if {$index <= $cargs(-max_logic_depth)} {
	  if { ! $cargs(-xcel) } {
          echo "Calculating Quantile for: $refname"
	  }
          # gather rise and fall data arrivals
        set rise {}
        set fall {}
          foreach ref [array names sigdata "$cargs(-del_meas_var)${index}$cargs(-rf_sep)"] {
                set processed($ref) 1
                set rf_name [regsub $cargs(-del_meas_var) $ref $cargs(-rf_meas_var)]
                set i 0
                while { $i < [llength $sigdata($rf_name)] } {
		if { [lindex $sigdata($ref) $i] ne "fail" } {
                if { [lindex $sigdata($rf_name) $i] < 0} {
                        if { ([lindex $sigdata($ref) $i] > $cargs(-min_value)) && ([lindex $sigdata($ref) $i] < $cargs(-max_value)) } {
                        lappend fall [lindex $sigdata($ref) $i]
                        } else {
				puts "Error: (generate_delay_variation_from_array) Monte-Carlo data: [lindex $sigdata($ref) $i] < $cargs(-min_value) || > $cargs(-max_value)"
                        }
                } else {
                        if { ([lindex $sigdata($ref) $i] > $cargs(-min_value)) && ([lindex $sigdata($ref) $i] < $cargs(-max_value)) } {
                        lappend rise [lindex $sigdata($ref) $i]
                        } else {
				puts "Error: (generate_delay_variation_from_array) Monte-Carlo data: [lindex $sigdata($ref) $i] < $cargs(-min_value) || > $cargs(-max_value)"
                        }
                }
                }
                incr i
		}
          }
	}
	  if { [llength $rise] > 0 } {
          set data [calculate_quantile -qlo $cargs(-qlo) -qhi $cargs(-qhi) -datalist rise -min_value $cargs(-min_value) -max_value $cargs(-max_value)]
          set mean [lindex $data 0]
          set lo [lindex $data 1]
          set hi [lindex $data 2]
	  if { $cargs(-xcel) } {
	  puts $fout "$index,R,$mean,$lo,$hi"
          } elseif { $cargs(-resultsarray) ne "" } {
	  set resdata($index,R) [list $mean $lo $hi]
	  } else {
	  puts "REF: $refname INDEX: $index EDGE: R MEAN: $mean LO: $lo HI: $hi"
	  }
	  }
	  if { [llength $fall] > 0 } {
          set data [calculate_quantile -qlo $cargs(-qlo) -qhi $cargs(-qhi) -datalist fall -min_value $cargs(-min_value) -max_value $cargs(-max_value)]
          set mean [lindex $data 0]
          set lo [lindex $data 1]
          set hi [lindex $data 2]
	  if { $cargs(-xcel) } {
	  puts $fout "$index,F,$mean,$lo,$hi"
          } elseif { $cargs(-resultsarray) ne "" } {
	  set resdata($index,F) [list $mean $lo $hi]
	  } else {
	  puts "REF: $refname INDEX: $index EDGE: F MEAN: $mean LO: $lo HI: $hi"
	  }
	  }
        }
      }
        if { $cargs(-xcel) ne "" } {
		close $fout
	}
}
	
define_myproc_attributes -info "generate delay variation from array" -define_args {
  {-cell  "cell name string" "cell name string" string optional}
  {-meas_dir "measure/working file dir" string string optional}
  {-dataarray "array to store measure data" string string required}
  {-resultsarray "array to store calculated data" string string optional}
  {-depth "list of depth indexes for aocv table" string string optional}
  {-max_logic_depth "max logic depth for Table depth" string string optional}
  {-qlo "Low quantile value (between 0 and 1)" float float optional}
  {-qhi "High quantile value (between 0 and 1)" float float optional}
  {-rf_meas_var "rf measurement variable prefix" string string optional}
  {-rf_sep "_\\\[12\\\]" string string optional}
  {-sig_digits "sig digits for data" int int optional}
  {-min_value "minimum value allowed for data" float float optional}
  {-max_value "maximum value allowed for data" float float optional}
  {-xcel "xcel file" "filename" string optional}
  {-path_ordered "path ordered results" "" boolean optional}
  {-add_slew_var "add slew variation to report" "" boolean optional}
} generate_delay_variation_from_array
echo "Defined procedure 'generate_delay_variation_from_array'."

### calculate slew variation from an array of samples
proc generate_slew_variation_from_array { args } {
  set cargs(-cell) ""
  set cargs(-dataarray) ""
  set cargs(-resultsarray) ""
  set cargs(-max_value) "999999999999999"
  set cargs(-min_value) "-999999999999999"	
  set cargs(-meas_dir) "."
  set cargs(-depth) ""
  set cargs(-max_logic_depth) 15
  set cargs(-qhi) ".99865"
  set cargs(-qlo) ".00135"
  set cargs(-sig_digits) 3
  set cargs(-del_meas_var) "\[ap\]ocv_d_o#"
  set cargs(-rf_meas_var) "\[ap\]ocv_rf_o#"
  set cargs(-rf_sep) "_\[1-2\]"
  set cargs(-xcel) ""
  set cargs(-path_ordered) 0

  # mean modes are "first last avg max min"
  if { [parse_myproc_arguments -args $args cargs] eq "0"  } {
    return 0
  }

  if { $cargs(-dataarray) eq "" } {
    die "Must use -dataarray option to generate_slew_variation_from_array"
  }
  upvar 1 $cargs(-dataarray) sigdata
  if { $cargs(-resultsarray) ne "" } {
  upvar 1 $cargs(-resultsarray) resdata
  } else {
	array unset resdata
  }

	set cargs(-rf_sep) [string trim $cargs(-rf_sep) "\{\}\""]
	set cargs(-del_meas_var) [string trim $cargs(-del_meas_var) "\{\}\""]
	set cargs(-rf_meas_var) [string trim $cargs(-rf_meas_var) "\{\}\""]

	   if { $cargs(-xcel) ne "" } {
		echo "Generating Xcel file($cargs(-xcel)) with variation data"
		set fout [open $cargs(-xcel) w]
	        puts $fout "INDEX,EDGE,SLEW_MEAN,SLEW-3sigma,SLEW+3sigma"
	   }

      array unset processed {}
      foreach refname [lsort [array names sigdata]] {
        #separate data into rise and fall data
        # look at both <del_meas_var><#>_2
        if { [regexp $cargs(-rf_meas_var) $refname ] && ![info exists processed($refname)]} {
          regexp "$cargs(-rf_meas_var)(\[0-9\]+)" $refname dum index
          if {$index <= $cargs(-max_logic_depth)} {
          echo "Calculating Quantile for: $refname"
          # gather rise and fall data arrivals
          set rise {}
          set fall {}
          foreach ref [array names sigdata "$cargs(-rf_meas_var)${index}$cargs(-rf_sep)"] {
                set processed($ref) 1
                set i 0
                while { $i < [llength $sigdata($ref)] } {
		if { [lindex $sigdata($ref) $i] ne "fail" } {
                if { [lindex $sigdata($ref) $i] < 0} {
                        if { ([lindex $sigdata($ref) $i] > $cargs(-min_value)) && ([lindex $sigdata($ref) $i] < $cargs(-max_value)) } {
                        lappend fall [lindex $sigdata($ref) $i]
                        } else {
				puts "Error: (generate_slew_variation_from_array) Monte-Carlo data: [lindex $sigdata($ref) $i] < $cargs(-min_value) || > $cargs(-max_value)"
                        }
                } else {
                        if { ([lindex $sigdata($ref) $i] > $cargs(-min_value)) && ([lindex $sigdata($ref) $i] < $cargs(-max_value)) } {
                        lappend rise [lindex $sigdata($ref) $i]
                        } else {
				puts "Error: (generate_slew_variation_from_array) Monte-Carlo data: [lindex $sigdata($ref) $i] < $cargs(-min_value) || > $cargs(-max_value)"
                        }
                }
		}
                incr i
                }
          }
	  if { [llength $rise] > 0 } {
          set data [calculate_quantile -qlo $cargs(-qlo) -qhi $cargs(-qhi) -datalist rise -min_value $cargs(-min_value) -max_value $cargs(-max_value)]
          set mean [lindex $data 0]
          set lo [lindex $data 1]
          set hi [lindex $data 2]
	  if { $cargs(-xcel) } {
	  puts $fout "$index,R,$mean,$lo,$hi"
          } elseif { $cargs(-resultsarray) ne "" } {
	  set resdata($index,R) [list $mean $lo $hi]
 	  } else {
	  puts "REF: $refname INDEX: $index EDGE: R MEAN: $mean LO: $lo HI: $hi"
	  }
	  }
	  if { [llength $fall] > 0 } {
          set data [calculate_quantile -qlo $cargs(-qlo) -qhi $cargs(-qhi) -datalist fall -min_value $cargs(-min_value) -max_value $cargs(-max_value)]
          set mean [lindex $data 0]
          set lo [lindex $data 1]
          set hi [lindex $data 2]
	  if { $cargs(-xcel) } {
	   puts $fout "$index,F,$mean,$lo,$hi"
          } elseif { $cargs(-resultsarray) ne "" } {
	  set resdata($index,F) [list $mean $lo $hi]
 	  } else {
	  puts "REF: $refname INDEX: $index EDGE: F MEAN: [expr 0 - $mean] LO: [expr 0 - $hi] HI: [expr 0 - $lo]"
	  }
	  }

	}
        }
      }
        if { $cargs(-xcel) ne "" } {
		close $fout
	}
}
define_myproc_attributes -info "generate slew variation from array" -define_args {
  {-cell  "cell name string" "cell name string" string optional}
  {-meas_dir "measure/working file dir" string string optional}
  {-dataarray "array to store measure data" string string required}
  {-resultsarray "array to store calculated data" string string optional}
  {-depth "list of depth indexes for aocv table" string string optional}
  {-max_logic_depth "max logic depth for Table depth" string string optional}
  {-qlo "Low quantile value (between 0 and 1)" float float optional}
  {-qhi "High quantile value (between 0 and 1)" float float optional}
  {-rf_meas_var "rf measurement variable prefix" string string optional}
  {-rf_sep "_\\\[12\\\]" string string optional}
  {-sig_digits "sig digits for data" int int optional}
  {-min_value "minimum value allowed for data" float float optional}
  {-max_value "maximum value allowed for data" float float optional}
  {-xcel "xcel file" "filename" string optional}
  {-path_ordered "path ordered results" "" boolean optional}
} generate_slew_variation_from_array
echo "Defined procedure 'generate_slew_variation_from_array'."

### calculate and write out an AOCV table
proc generate_stage_variation_from_array { args } {
  set cargs(-cell) ""
  set cargs(-dataarray) ""
  set cargs(-resultsarray) ""
  set cargs(-max_value) "999999999999999"
  set cargs(-min_value) "-999999999999999"	
  set cargs(-meas_dir) "."
  set cargs(-max_logic_depth) 15
  set cargs(-qhi) ".99865"
  set cargs(-qlo) ".00135"
  set cargs(-xcel) ""
  set cargs(-sig_digits) 3
  set cargs(-del_meas_var) "ocv_d_o#"
  set cargs(-rf_meas_var) "ocv_rf_o#"
  set cargs(-rf_sep) "_\[1-2\]"
  set cargs(-add_slew_var) 0
  set cargs(-path_ordered) 0

  # mean modes are "first last avg max min"
  if { [parse_myproc_arguments -args $args cargs] eq "0"  } {
    return 0
  }

  if { $cargs(-dataarray) eq "" } {
    die "Must use -dataarray option to generate_stage_variation_from_array"
  }
  upvar 1 $cargs(-dataarray) sigdata
  if { $cargs(-resultsarray) ne "" } {
  upvar 1 $cargs(-resultsarray) resdata
  } else {
	array unset resdata
  }

	set cargs(-rf_sep) [string trim $cargs(-rf_sep) "\{\}\""]
	set cargs(-del_meas_var) [string trim $cargs(-del_meas_var) "\{\}\""]
	set cargs(-rf_meas_var) [string trim $cargs(-rf_meas_var) "\{\}\""]

	   if { $cargs(-xcel) ne "" } {
		echo "Generating Xcel file($cargs(-xcel)) with variation data"
		set fout [open $cargs(-xcel) w]
	        puts $fout "INDEX,EDGE,STAGE_MEAN,STAGE-3sigma,STAGE+3sigma"
	   }

      array set stagedata {}
      foreach refname [lsort [array names sigdata "*$cargs(-del_meas_var)*"]] {
        # look at both <del_meas_var><#>_2
          regexp "($cargs(-del_meas_var))(\[0-9\]+)_(\[1-2\])" $refname dum var index edge
          if {$index <= $cargs(-max_logic_depth)} {
          echo "Calculating Quantile for: $refname"
          set rf_name [regsub $cargs(-del_meas_var) $refname $cargs(-rf_meas_var)] 
	  set preindex [expr $index - 1]
	  if { $index > 1 } {
          
          set prerefname [regsub "($cargs(-del_meas_var))(\[0-9\]+)" $refname "$var${preindex}"]

	  for { set i 0 } { $i < [llength $sigdata($refname)] } { incr i } {
	  lappend stagedata($refname) [expr [lindex $sigdata($refname) $i] - [lindex $sigdata($prerefname) $i]]
	  }
	  } else {
	  set stagedata($refname) $sigdata($refname)
	  }
	}
     }
      array unset processed
	# stagedata should have all delay data with reference
      foreach refname [lsort [array names stagedata]] {
	  puts "Processing $refname"
          regexp "($cargs(-del_meas_var))(\[0-9\]+)_(\[1-2\])" $refname dum var index edge
          set rf_name [regsub $cargs(-del_meas_var) $refname $cargs(-rf_meas_var)]
        set rise {}
        set fall {}
                set processed($refname) 1
                set i 0
                while { $i < [llength $sigdata($rf_name)] } {
		if { [lindex $sigdata($refname) $i] ne "fail" } {
                if { [lindex $sigdata($rf_name) $i] < 0} {
                        if { ([lindex $stagedata($refname) $i] > $cargs(-min_value)) && ([lindex $stagedata($refname) $i] < $cargs(-max_value)) } {
                        lappend fall [lindex $stagedata($refname) $i]
                        } else {
				puts "Error: (generate_stage_variation_from_array) Monte-Carlo data: [lindex $stagedata($refname) $i] < $cargs(-min_value) || > $cargs(-max_value)"
                        }
                } else {
                        if { ([lindex $stagedata($refname) $i] > $cargs(-min_value)) && ([lindex $stagedata($refname) $i] < $cargs(-max_value)) } {
                        lappend rise [lindex $stagedata($refname) $i]
                        } else {
				puts "Error: (generate_stage_variation_from_array) Monte-Carlo data: [lindex $stagedata($refname) $i] < $cargs(-min_value) || > $cargs(-max_value)"
                        }
                }
		}
                incr i
                }
         
	  if { [llength $rise] > 0 } {
          set data [calculate_quantile -qlo $cargs(-qlo) -qhi $cargs(-qhi) -datalist rise -min_value $cargs(-min_value) -max_value $cargs(-max_value)]
          set mean [lindex $data 0]
          set lo [lindex $data 1]
          set hi [lindex $data 2]
	  if { $cargs(-xcel) ne "" } {
		puts $fout "$index,R,$mean,$lo,$hi"
          } elseif { $cargs(-resultsarray) ne "" } {
	  set resdata($index,R) [list $mean $lo $hi]
	  } else {
	  puts "REF: $refname INDEX: $index EDGE: R MEAN: $mean LO: $lo HI: $hi MAX_VAR: [expr $hi - $mean] MIN_VAR: [expr $mean - $lo] "
	  }
	  }
	  if { [llength $fall] > 0 } {
          set data [calculate_quantile -qlo $cargs(-qlo) -qhi $cargs(-qhi) -datalist fall -min_value $cargs(-min_value) -max_value $cargs(-max_value)]
          set mean [lindex $data 0]
          set lo [lindex $data 1]
          set hi [lindex $data 2]
	  if { $cargs(-xcel) ne "" } {
		puts $fout "$index,F,$mean,$lo,$hi"
          } elseif { $cargs(-resultsarray) ne "" } {
	  set resdata($index,F) [list $mean $lo $hi]
	  } else {
	  puts "REF: $refname INDEX: $index EDGE: F MEAN: $mean LO: $lo HI: $hi MAX_VAR: [expr $hi - $mean] MIN_VAR: [expr $mean - $lo] "
  	  }
	  }
      }
        if { $cargs(-xcel) ne "" } {
		close $fout
	}
}
define_myproc_attributes -info "generate stage variation from array" -define_args {
  {-cell  "cell name string" "cell name string" string optional}
  {-meas_dir "measure/working file dir" string string optional}
  {-dataarray "array to store measure data" string string required}
  {-resultsarray "array to store calculated data" string string optional}
  {-depth "list of depth indexes for aocv table" string string optional}
  {-max_logic_depth "max logic depth for Table depth" string string optional}
  {-qlo "Low quantile value (between 0 and 1)" float float optional}
  {-qhi "High quantile value (between 0 and 1)" float float optional}
  {-del_meas_var "delay measurement variable prefix" string string optional}
  {-rf_meas_var "rf measurement variable prefix" string string optional}
  {-sig_digits "sig digits for data" int int optional}
  {-min_value "minimum value allowed for data" float float optional}
  {-max_value "maximum value allowed for data" float float optional}
  {-xcel "xcel file" "filename" string optional}
  {-path_ordered "path ordered results" "" boolean optional}
  {-add_slew_var "add slew variation to report" "" boolean optional}
} generate_stage_variation_from_array
echo "Defined procedure 'generate_stage_variation_from_array'."

### calculate and write out an AOCV table
proc generate_aocv_table_from_array { args } {
  set cargs(-rf_sep) "_\\\[12\\\]"
  set cargs(-cell) ""
  set cargs(-early_margin_pct) 0.0
  set cargs(-late_margin_pct) 0.0
  set cargs(-path_type) ""
  set cargs(-vdd) ""
  set cargs(-dataarray) ""
  set cargs(-refdataarray) ""
  set cargs(-aocv_file) ""
  set cargs(-max_value) "999999999999999"
  set cargs(-min_value) "-999999999999999"	
  set cargs(-library) ""
  set cargs(-object_type) "lib_cell"
  set cargs(-pocv_dir) "."
  set cargs(-meas_dir) "."
  set cargs(-rf_type) "rise fall"
  set cargs(-delay_type) "cell"
  set cargs(-derate_type) ""
  set cargs(-object_spec) ""
  set cargs(-depth) ""
  set cargs(-max_logic_depth) 15
  set cargs(-max_read_logic_depth) ""
  set cargs(-append) 0
  set cargs(-sigma) ""
  set cargs(-qhi) ".99865"
  set cargs(-qlo) ".00135"
  set cargs(-no_curve_fit) 0
  set cargs(-sig_digits) 3
  set cargs(-del_meas_var) "\[ap\]ocv_d_o#"
  set cargs(-rf_meas_var) "\[ap\]ocv_rf_o#"
  set cargs(-sqrtN) 0
  set cargs(-cell_chain_mode) "same_cell"
  # mean modes are "first last avg max min"
  set cargs(-sqrtN_mean_mode) "last"
  # vardiff modes are "first last avg max min"
  set cargs(-sqrtN_vardiff_mode) "last"
  set cargs(-force_pessimistic_monotonic) 0
  set cargs(-min_early_derate) ""
  set cargs(-max_early_derate) ""
  set cargs(-min_late_derate) ""
  set cargs(-max_late_derate) ""
  set cargs(-depth_scale) 1
  set cargs(-debug) 0

  if { [parse_myproc_arguments -args $args cargs] eq "0"  } {
    return 0
  }
  if {$cargs(-library) eq ""} {
	set cargs(-library) "*"
  }
  if { $cargs(-object_spec) eq "" } {
    if {$cargs(-cell) ne "" } {
    set cargs(-object_spec) "$cargs(-cell)"
    } else {
    set cargs(-object_spec) "*"
    }
  }

	set cargs(-rf_sep) [string trim $cargs(-rf_sep) "\{\}\""]
	set cargs(-del_meas_var) [string trim $cargs(-del_meas_var) "\{\}\""]
	set cargs(-rf_meas_var) [string trim $cargs(-rf_meas_var) "\{\}\""]
	
  if { $cargs(-dataarray) eq "" } {
    die "Must use -dataarray option to generate_aocv_table_from_array"
  }
  if { $cargs(-refdataarray) ne "" } {
  	upvar 1 $cargs(-refdataarray) refsigdata
  }

  upvar 1 $cargs(-dataarray) sigdata

 if { $cargs(-max_read_logic_depth) eq "" } {
	set cargs(-max_read_logic_depth) $cargs(-max_logic_depth)
 }
      if { ![regexp  "^\[ \]*\/" $cargs(-aocv_file)] } {
   	set cargs(-aocv_file) $cargs(-pocv_dir)/$cargs(-aocv_file)
      }
  
      array set processed {}
      foreach refname [lsort [array names sigdata]] {
	puts "REFNAME: $refname"
        #separate data into rise and fall data 
        # look at both <del_meas_var><#>_2
        if { [regexp $cargs(-del_meas_var) $refname ] && ![info exists processed($refname)]} {
          regexp "$cargs(-del_meas_var)(\[0-9\]+)" $refname dum index
          if {$index <= $cargs(-max_read_logic_depth)} {
          echo "Calculating Quantile for: $refname"
          # gather rise and fall data arrivals
        set rise {}
        set fall {}
        set mean_rise {}
        set mean_fall {}
          foreach ref [array names sigdata "$cargs(-del_meas_var)${index}$cargs(-rf_sep)"] {
                set processed($ref) 1
                set rf_name [regsub $cargs(-del_meas_var) $ref $cargs(-rf_meas_var)]
                set i 0
		if { [info exists sigdata($rf_name)] } {
                while { $i < [llength $sigdata($rf_name)] } {
		if { [lindex $sigdata($ref) $i] ne "fail" } {
                if { [lindex $sigdata($rf_name) $i] < 0} {
                        if { ([lindex $sigdata($ref) $i] > $cargs(-min_value)) && ([lindex $sigdata($ref) $i] < $cargs(-max_value)) } {
                        lappend fall [lindex $sigdata($ref) $i]
                        } else {
				puts "Error: (generate_aocv_table_from_array) Monte-Carlo data: [lindex $sigdata($ref) $i] < $cargs(-min_value) || > $cargs(-max_value)"
			}
                } else {
                        if { ([lindex $sigdata($ref) $i] > $cargs(-min_value)) && ([lindex $sigdata($ref) $i] < $cargs(-max_value)) } {
                        lappend rise [lindex $sigdata($ref) $i]
                        } else {
				puts "Error: (generate_aocv_table_from_array) Monte-Carlo data: [lindex $sigdata($ref) $i] < $cargs(-min_value) || > $cargs(-max_value)"
                        }
                }
		}
                incr i
                }
	        } else {
			puts "Error: missing edge rate data for $ref"
		}
          }

	 if { $cargs(-debug) } {
                puts "Info: (generate_aocv_table_from_array) $ref rise: $rise $index"
                puts "Info: (generate_aocv_table_from_array) $ref fall: $fall $index"
	 }
         
          # gather rise and fall ref arrivals if they exist
	      if { [array exists refsigdata] } {
             foreach ref [array names refsigdata "$cargs(-del_meas_var)${index}$cargs(-rf_sep)" ] {
                #puts "refname = $ref ref_sig_data: $refsigdata($ref) $index"
                set rf_name [regsub $cargs(-del_meas_var) $ref $cargs(-rf_meas_var)]
                set i 0
		if { [info exists refsigdata($rf_name)] } {
                while { $i < [llength $refsigdata($rf_name)] } {
		if { [lindex $refsigdata($ref) $i] ne "fail" } {
                if { [lindex $refsigdata($rf_name) $i] < 0} {
                        if { ([lindex $refsigdata($ref) $i] > $cargs(-min_value)) && ([lindex $refsigdata($ref) $i] < $cargs(-max_value)) } {
                        lappend mean_fall [lindex $refsigdata($ref) $i]
                        } else {
				puts "Error: (generate_aocv_table_from_array) Monte-Carlo data: [lindex $refsigdata($ref) $i] < $cargs(-min_value) || > $cargs(-max_value)"
                        }
                } else {
                        if { ([lindex $refsigdata($ref) $i] > $cargs(-min_value)) && ([lindex $refsigdata($ref) $i] < $cargs(-max_value)) } {
                        lappend mean_rise [lindex $refsigdata($ref) $i]
                        } else {
				puts "Error: (generate_aocv_table_from_array) Monte-Carlo data: [lindex $refsigdata($ref) $i] < $cargs(-min_value) || > $cargs(-max_value)"
                        }
                }
		}
                incr i
                }
	        } else {
			puts "Error: missing edge rate data for $ref"
		}
            }   
	 if { $cargs(-debug) } {
                puts "Info: (generate_aocv_table_from_array) $ref mean_rise: $mean_rise $index"
                puts "Info: (generate_aocv_table_from_array) $ref mean_fall: $mean_fall $index"
	 }
            } 
                # if sqrtN mode create mean rise & fall arrays
	    if { [llength $rise] > 0 } {
            set data [calculate_quantile -qlo $cargs(-qlo) -qhi $cargs(-qhi) -datalist rise -min_value $cargs(-min_value) -max_value $cargs(-max_value)]
            if { [array exists refsigdata] } {
            set mean [lindex $mean_rise 0]
            } else {
            set mean [lindex $data 0]
            }
            set lo [lindex $data 1]
            set hi [lindex $data 2]
	  if { $cargs(-derate_type) eq "invert_late" } {
             set min [expr  2.0 - $hi / $mean]
             set max [expr $hi / $mean]
	  } elseif { $cargs(-derate_type) eq "invert_early" } {
             set min [expr  $lo / $mean]
             set max [expr  2.0 - $lo / $mean]
	  } else {
             set min [expr  $lo / $mean]
             set max [expr $hi / $mean]
	  }
            if { $cargs(-sqrtN) } {
              #set mean [lindex $mean_rise 0]
              if { [array exists mean_rise_edge] && [info exists mean_rise_edge($index)] } {
                if { $mean_rise_edge($index) > $mean } {
                  set mean_rise_edge($index) $mean
                }
              } else {
                set mean_rise_edge($index) $mean
              }
            if { [array exists min_rise_edge] && [info exists min_rise_edge($index)] && ($cargs(-derate_type) ne "late") } {
                if { $min_rise_edge($index) > $lo  } {
                  set min_rise_edge($index)  $lo
                }
            }  else {
                set min_rise_edge($index)  $lo
            }
            if { [array exists max_rise_edge] && [info exists max_rise_edge($index)] && ($cargs(-derate_type) ne "early") } {
                if { $max_rise_edge($index) > $hi  } {
                  set max_rise_edge($index)  $hi
                }
            }  else {
                set max_rise_edge($index)  $hi
            }
            } else {
            if { [array exists min_rise_edge] && [info exists min_rise_edge($index)] && ($cargs(-derate_type) ne "late") } {
                if { $min_rise_edge($index) > $min  } {
                  set min_rise_edge($index)  $min
                }
            }  else {
                set min_rise_edge($index)  $min
            }
            if { [array exists max_rise_edge] && [info exists max_rise_edge($index)] && ($cargs(-derate_type) ne "early") } {
                if { $max_rise_edge($index) > $max  } {
                  set max_rise_edge($index)  $max
                }
            }  else {
                set max_rise_edge($index)  $max
            }

            }
	    puts "INDEX: $index EDGE: R MEAN: $mean LO: $lo HI: $hi MIN: $min MAX: $max"
	    }
	    if { [llength $fall] > 0 } {
            set data [calculate_quantile -qlo $cargs(-qlo) -qhi $cargs(-qhi) -datalist fall -min_value $cargs(-min_value) -max_value $cargs(-max_value)]
            if { [array exists refsigdata] } {
            set mean [lindex $mean_fall 0]
            } else {
            set mean [lindex $data 0]
            }
            set lo [lindex $data 1]
            set hi [lindex $data 2]
	  if { $cargs(-derate_type) eq "invert_late" } {
             set min [expr  2.0 - $hi / $mean]
             set max [expr $hi / $mean]
	  } elseif { $cargs(-derate_type) eq "invert_early" } {
             set min [expr  $lo / $mean]
             set max [expr  2.0 - $lo / $mean]
	  } else {
             set min [expr  $lo / $mean]
             set max [expr $hi / $mean]
	  }
            if { $cargs(-sqrtN) } {
             # set mean [lindex $mean_fall 0]
              if { [array exists mean_fall_edge] && [info exists mean_fall_edge($index)] } {
                 if { $mean_fall_edge($index) > $mean } {
                  set mean_fall_edge($index) $mean
                 }
              } else {
                set mean_fall_edge($index) $mean
              }
            if { [array exists min_fall_edge] && [info exists min_fall_edge($index)] && ($cargs(-derate_type) ne "late") } {
                if { $min_fall_edge($index) > $lo  } {
                  set min_fall_edge($index)  $lo
                }
            }  else {
                set min_fall_edge($index)  $lo
            }
            if { [array exists max_fall_edge] && [info exists max_fall_edge($index)] && ($cargs(-derate_type) ne "early") } {
                if { $max_fall_edge($index) > $hi  } {
                  set max_fall_edge($index)  $hi
                }
            }  else {
                set max_fall_edge($index)  $hi
            }
            } else {
            if { [array exists min_fall_edge] && [info exists min_fall_edge($index)] && ($cargs(-derate_type) ne "late") } {
                if { $min_fall_edge($index) > $min  } {
                  set min_fall_edge($index)  $min
                }
            }  else {
                set min_fall_edge($index)  $min
            }
            if { [array exists max_fall_edge] && [info exists max_fall_edge($index)] && ($cargs(-derate_type) ne "early") } {
                if { $max_fall_edge($index) > $max  } {
                  set max_fall_edge($index)  $max
                }
            }  else {
                set max_fall_edge($index)  $max
            }
            }
	    puts "INDEX: $index EDGE: F MEAN: $mean LO: $lo HI: $hi MIN: $min MAX: $max"
	    }

        }
        }
      }
	# 3sigma_derate = (mean + 3sigma_variation) / mean = 1 + 3sigma_variation/mean
  if { $cargs(-sqrtN)} {
    if { [defined mean] } {
      unset mean
    }
    if { [info exist mean_rise_edge] }  {
    if { $cargs(-sqrtN_mean_mode) eq "first" } {
	set mean $mean_rise_edge([lindex [lsort -integer [array names mean_rise_edge]] 0])
    } elseif { $cargs(-sqrtN_mean_mode) eq "last" } {
	set mean [expr $mean_rise_edge([lindex [lsort -integer [array names mean_rise_edge]] end]) / [lindex [lsort -integer [array names mean_rise_edge]] end]]
    } else {
    set summean 0
    foreach index [array names mean_rise_edge] {
	set tmp [expr $mean_rise_edge($index)/ $index]
      if {($cargs(-sqrtN_mean_mode) eq "avg")} {
      	set summean [expr $summean + $tmp]
      } elseif {($cargs(-sqrtN_mean_mode) eq "min")} {
        if { ![info exists mean] ||  ($mean > $tmp) } {
          set mean $tmp
        }
      } elseif {($cargs(-sqrtN_mean_mode) eq "max")} {
        if { ![info exists mean] ||  ($mean < $tmp) } {
          set mean $tmp
        }
      }
    }
    if {($cargs(-sqrtN_mean_mode) eq "avg")} {
    set mean [expr $summean/[llength [array names mean_rise_edge]]]
    }
    }

    if { $cargs(-derate_type) ne "late" } {
    # calculate the diff based on sqrtN_vardiff_mode
    if { [defined diff] } {
      unset diff
    }
    if { $cargs(-sqrtN_vardiff_mode) eq "first" } {
	set diff [expr $mean_rise_edge([lindex [lsort -integer [array names min_rise_edge]] 0]) - $min_rise_edge([lindex [lsort -integer [array names min_rise_edge]] 0])]
    } elseif { $cargs(-sqrtN_vardiff_mode) eq "last" } {
	set diff [expr ($mean_rise_edge([lindex [lsort -integer [array names min_rise_edge]] end]) - $min_rise_edge([lindex [lsort -integer [array names min_rise_edge]] end]))/ sqrt([lindex [lsort -integer [array names min_rise_edge]] end])]
    } else {
    set sumdiff 0
    foreach index [array names min_rise_edge] {
	set tmp [expr ($mean_rise_edge($index) - $min_rise_edge($index))/sqrt($index)]
      if {($cargs(-sqrtN_vardiff_mode) eq "avg")} {
      	set sumdiff [expr $sumdiff + $tmp]
      } elseif {($cargs(-sqrtN_vardiff_mode) eq "min")} {
        if { ![info exists diff] ||  ($diff > $tmp) } {
          set diff $tmp
        }
      } elseif {($cargs(-sqrtN_vardiff_mode) eq "max")} {
        if { ![info exists diff] ||  ($diff < $tmp) } {
          set diff $tmp
        }
      }
    }
    if {($cargs(-sqrtN_vardiff_mode) eq "avg")} {
    set diff [expr $sumdiff/[llength [array names min_rise_edge]]]
    }
    }


    set index 1
    while {$index  <= $cargs(-max_logic_depth) } {
      if { [defined mean_rise_edge($index)] } {	
        set min_rise_edge($index) [expr $min_rise_edge($index)/$mean_rise_edge($index)]
      } else {
        set min_rise_edge($index) [expr 1 - ($diff / sqrt($index) ) / $mean ]
      }
      incr index
    }
    }

    if { $cargs(-derate_type) ne "early" } {
    # calculate the diff based on sqrtN_vardiff_mode
    if { [defined diff] } {
      unset diff
    }
    if { $cargs(-sqrtN_vardiff_mode) eq "first" } {
	set diff [expr $max_rise_edge([lindex [lsort -integer [array names max_rise_edge]] 0]) - $mean_rise_edge([lindex [lsort -integer [array names max_rise_edge]] 0])]
    } elseif { $cargs(-sqrtN_vardiff_mode) eq "last" } {
	set diff [expr ($max_rise_edge([lindex [lsort -integer [array names max_rise_edge]] end]) - $mean_rise_edge([lindex [lsort -integer [array names max_rise_edge]] end]))/ sqrt([lindex [lsort -integer [array names max_rise_edge]] end])]
    } else {
    set sumdiff 0
    foreach index [array names max_rise_edge] {
	set tmp [expr ($max_rise_edge($index) - $mean_rise_edge($index))/sqrt($index)]
      if {($cargs(-sqrtN_vardiff_mode) eq "avg")} {
      	set sumdiff [expr $sumdiff + $tmp]
      } elseif {($cargs(-sqrtN_vardiff_mode) eq "min")} {
        if { ![info exists diff] ||  ($diff > $tmp) } {
          set diff $tmp
        }
      } elseif {($cargs(-sqrtN_vardiff_mode) eq "max")} {
        if { ![info exists diff] ||  ($diff < $tmp) } {
          set diff $tmp
        }
      }
    }
    if {($cargs(-sqrtN_vardiff_mode) eq "avg")} {
    set diff [expr $sumdiff/[llength [array names max_rise_edge]]]
    }
    }

    set index 1
    while {$index  <= $cargs(-max_logic_depth) } {
      if { [defined mean_rise_edge($index)] } {	
        set max_rise_edge($index) [expr $max_rise_edge($index)/$mean_rise_edge($index)]
      } else {
        set max_rise_edge($index) [expr 1 + ($diff / sqrt($index) ) / $mean ]
      }
      incr index
    }
    }
    } else {
           puts "ERROR: missing mean_rise_edge data, check if monte carlo results look reasonable"
    }

    if { [defined mean] } {
      unset mean
    }
    if { [info exist mean_fall_edge] }  {
    if { $cargs(-sqrtN_mean_mode) eq "first" } {
	set mean $mean_fall_edge([lindex [lsort -integer [array names mean_fall_edge]] 0])
    } elseif { $cargs(-sqrtN_mean_mode) eq "last" } {
	set mean [expr $mean_fall_edge([lindex [lsort -integer [array names mean_fall_edge]] end]) / [lindex [lsort -integer [array names mean_fall_edge]] end]]
    } else {
    set summean 0
    foreach index [array names mean_fall_edge] {
      set tmp [expr $mean_fall_edge($index)/ $index]
      if {($cargs(-sqrtN_mean_mode) eq "avg")} {
      	set summean [expr $summean + $tmp]
      } elseif {($cargs(-sqrtN_mean_mode) eq "min")} {
        if { ![info exists mean] ||  ($mean > $tmp) } {
          set mean $tmp
        }
      } elseif {($cargs(-sqrtN_mean_mode) eq "max")} {
        if { ![info exists mean] ||  ($mean < $tmp) } {
          set mean $tmp
        }
      }
    }
    if {($cargs(-sqrtN_mean_mode) eq "avg")} {
    set mean [expr $summean/[llength [array names mean_fall_edge]]]
    }
    }

    if { $cargs(-derate_type) ne "late" } {
    # calculate the diff based on sqrtN_vardiff_mode
    if { [defined diff] } {
      unset diff
    }
    if { $cargs(-sqrtN_vardiff_mode) eq "first" } {
	set diff [expr $mean_fall_edge([lindex [lsort -integer [array names min_fall_edge]] 0]) - $min_fall_edge([lindex [lsort -integer [array names min_fall_edge]] 0])]
    } elseif { $cargs(-sqrtN_vardiff_mode) eq "last" } {
	set diff [expr ($mean_fall_edge([lindex [lsort -integer [array names min_fall_edge]] end]) - $min_fall_edge([lindex [lsort -integer [array names min_fall_edge]] end]))/ sqrt([lindex [lsort -integer [array names min_fall_edge]] end])]
    } else {
    set sumdiff 0
    foreach index [array names min_fall_edge] {
	set tmp [expr ($mean_fall_edge($index) - $min_fall_edge($index))/sqrt($index)]
      if {($cargs(-sqrtN_vardiff_mode) eq "avg")} {
      	set sumdiff [expr $sumdiff + $tmp]
      } elseif {($cargs(-sqrtN_vardiff_mode) eq "min")} {
        if { ![info exists diff] ||  ($diff > $tmp) } {
          set diff $tmp
        }
      } elseif {($cargs(-sqrtN_vardiff_mode) eq "max")} {
        if { ![info exists diff] ||  ($diff < $tmp) } {
          set diff $tmp
        }
      }
    }
    if {($cargs(-sqrtN_vardiff_mode) eq "avg")} {
    set diff [expr $avgdiff/[llength [array names min_fall_edge]]]
    }
    }

    set index 1
    while {$index  <= $cargs(-max_logic_depth) } {
      if { [defined mean_fall_edge($index)] } {	
        set min_fall_edge($index) [expr $min_fall_edge($index)/$mean_fall_edge($index)]
      } else {
        set min_fall_edge($index) [expr 1 - ($diff / sqrt($index) ) / $mean ]
      }
      incr index
    }
    }
   
    if { $cargs(-derate_type) ne "early" } {
    # calculate the diff based on sqrtN_vardiff_mode
    if { [defined diff] } {
      unset diff
    }
    if { $cargs(-sqrtN_vardiff_mode) eq "first" } {
	set diff [expr ($max_fall_edge([lindex [lsort -integer [array names max_fall_edge]] end]) - $mean_fall_edge([lindex [lsort -integer [array names max_fall_edge]] end]))/ sqrt([lindex [lsort -integer [array names max_fall_edge]] end])]
    } elseif { $cargs(-sqrtN_vardiff_mode) eq "last" } {
	set diff [expr $max_fall_edge([lindex [lsort -integer [array names max_fall_edge]] 0]) - $mean_fall_edge([lindex [lsort -integer [array names max_fall_edge]] 0])]
    } else {
    set sumdiff 0
    foreach index [array names max_fall_edge] {
	set tmp [expr ($max_fall_edge($index) - $mean_fall_edge($index))/sqrt($index)]
      if {($cargs(-sqrtN_vardiff_mode) eq "avg")} {
      	set sumdiff [expr $sumdiff + $tmp)]
      } elseif {($cargs(-sqrtN_vardiff_mode) eq "min")} {
        if { ![info exists diff] ||  ($diff > $tmp) } {
          set diff $tmp
        }
      } elseif {($cargs(-sqrtN_vardiff_mode) eq "max")} {
        if { ![info exists diff] ||  ($diff < $tmp) } {
          set diff $tmp
        }
      }
    }
    if {($cargs(-sqrtN_vardiff_mode) eq "avg")} {
    set diff [expr $sumdiff/[llength [array names max_fall_edge]]]
    }
    }

    set index 1
    while {$index  <= $cargs(-max_logic_depth) } {
      if { [defined mean_fall_edge($index)] } {	
        set max_fall_edge($index) [expr $max_fall_edge($index)/$mean_fall_edge($index)]
      } else {
        set max_fall_edge($index) [expr 1 + ($diff / sqrt($index) ) / $mean ]
      }
      incr index
    }
    }
    } else {
           puts "ERROR: missing mean_fall_edge data, check if monte carlo results look reasonable"
    }

  }

  set watfa ""
  if { $cargs(-vdd) ne ""} {
	append watfa " -vdd $cargs(-vdd)"
  }
  if { $cargs(-path_type) ne "" } {
	if { [regexp "data|clock" $cargs(-path_type)] } {
	append watfa " -path_type $cargs(-vdd)"
	} else {
	puts "ERROR: invalid -path_type option, must be clock and/or data"
	return
	}
  }
  if { $cargs(-no_curve_fit) } {
    append  watfa " -no_curve_fit"
  } elseif {$cargs(-force_pessimistic_monotonic)} {
    append  watfa "  -force_pessimistic_monotonic"
  }
  if { $cargs(-early_margin_pct) ne "" } {
  append watfa " -early_margin_pct $cargs(-early_margin_pct)"
  }
  if { $cargs(-late_margin_pct) ne "" } {
  append watfa " -late_margin_pct $cargs(-early_margin_pct)"
  }
  if { $cargs(-sig_digits) ne "" } {
  append watfa " -sig_digits $cargs(-sig_digits)"
  }

  append watfa " -depth_scale $cargs(-depth_scale)"
	
  echo "Writing POCV Table in file $cargs(-aocv_file) for $cargs(-object_spec)"

    if { $cargs(-derate_type) ne "late" } {
    set derate ""
    if { $cargs(-max_early_derate) ne "" } {
	append derate " -max_depth_derate $cargs(-max_early_derate)"
    }
    if { $cargs(-min_early_derate) ne "" } {
	append derate " -min_depth_derate $cargs(-min_early_derate)"
    }
    if { $cargs(-rf_type) ne "fall" } {
  if { $cargs(-append) } {
    eval write_aocv_table_from_array  -file $cargs(-aocv_file) -derate_type early -rf_type rise -library $cargs(-library) -object_spec $cargs(-object_spec) -dataarray min_rise_edge -append -object_type lib_cell $watfa $derate
  } else {
    eval write_aocv_table_from_array  -file $cargs(-aocv_file) -derate_type early -rf_type rise -library $cargs(-library) -object_spec $cargs(-object_spec) -dataarray min_rise_edge -object_type lib_cell $watfa $derate
    set cargs(-append) 1
  }
  }
  if {($cargs(-rf_type) ne "rise")} {
  if { $cargs(-append) } {
  eval write_aocv_table_from_array  -file $cargs(-aocv_file) -derate_type early -rf_type fall -library $cargs(-library) -object_spec $cargs(-object_spec) -dataarray  min_fall_edge -append -object_type lib_cell $watfa $derate
  } else {
  eval write_aocv_table_from_array  -file $cargs(-aocv_file) -derate_type early -rf_type fall -library $cargs(-library) -object_spec $cargs(-object_spec) -dataarray  min_fall_edge -object_type lib_cell $watfa $derate
    set cargs(-append) 1
  }
    }
    }

    if { $cargs(-derate_type) ne "early" } {
    set derate ""
    if { $cargs(-max_late_derate) ne "" } {
	append derate " -max_depth_derate $cargs(-max_late_derate)"
    }
    if { $cargs(-min_late_derate) ne "" } {
	append derate " -min_depth_derate $cargs(-min_late_derate)"
    }
    if { $cargs(-rf_type) ne "fall" } {
  if { $cargs(-append) } {
    eval write_aocv_table_from_array  -file $cargs(-aocv_file) -derate_type late -rf_type rise -library $cargs(-library) -object_spec $cargs(-object_spec) -dataarray  max_rise_edge -append -object_type lib_cell $watfa $derate
  } else {
    eval write_aocv_table_from_array  -file $cargs(-aocv_file) -derate_type late -rf_type rise -library $cargs(-library) -object_spec $cargs(-object_spec) -dataarray  max_rise_edge -object_type lib_cell $watfa $derate
    set cargs(-append) 1
  }
  }
  if {($cargs(-rf_type) ne "rise")} {
  if { $cargs(-append) } {
  eval write_aocv_table_from_array  -file $cargs(-aocv_file) -derate_type late -rf_type fall -library $cargs(-library) -object_spec $cargs(-object_spec) -dataarray  max_fall_edge -append -object_type lib_cell $watfa $derate
  } else {
  eval write_aocv_table_from_array  -file $cargs(-aocv_file) -derate_type late -rf_type fall -library $cargs(-library) -object_spec $cargs(-object_spec) -dataarray  max_fall_edge -object_type lib_cell $watfa $derate
    set cargs(-append) 1
  }
    }
    }
}
define_myproc_attributes -info "generate aocv tables from array" -define_args {
  {-cell  "cell name string" "cell name string" string optional}
  {-aocv_file "aocv output file" string string required}
  {-pocv_dir "aocv dir" string string optional}
  {-meas_dir "measure/working file dir" string string optional}
  {-dataarray "array to store measure data" string string required}
  {-refdataarray "array to store reference measure data" string string optional}
  {-library "library for lib_cell object spec" string string optional}
  {-object_type "object type of aocv table" string string optional}
  {-object_spec "object spec to for aocv table to apply" string string optional}
  {-delay_type "delay type of aocv table" string string optional}
  {-rf_type "rf type of aocv table" string string optional}
  {-derate_type "derate type of aocv table(early|late|invert_late|invert_early)" string string optional}
  {-depth "list of depth indexes for aocv table" string string optional}
  {-max_logic_depth "max logic depth for Table depth " string string optional}
  {-max_read_logic_depth "max read logic depth for Table depth used for sqrtN" string string optional}
  {-table "list of aocv table data" string string optional}
  {-qlo "Low quantile value (between 0 and 1)" float float optional}
  {-qhi "High quantile value (between 0 and 1)" float float optional}
  {-del_meas_var "delay measurement variable prefix" string string optional}
  {-rf_meas_var "rf measurement variable prefix" string string optional}
  {-rf_sep "rf separtor for measurement data(def: _\[12\])" string string optional}
  {-sig_digits "sig digits for data" int int optional}
  {-append "append to existing file" "" boolean optional}
  {-no_curve_fit "do not try to auto curve fit" "" boolean optional}
  {-force_pessimistic_monotonic "force derate to be pessimistically monotonic" "" boolean optional}
  {-cell_chain_mode "cell_chain_mode of cells(def. same_cell)" string string optional}
  {-sqrtN "enable sqrtN mode" "" boolean optional}
  {-sqrtN_mean_mode "mean calculation mode for sqrtN(first,last,avg,min,max def: last)" string string optional}
  {-sqrtN_vardiff_mode "variation difference calculation mode for sqrtN(first,last,avg,min,max def: last)" string string optional}
  {-min_early_derate "minimum derate allowed for early derate" float float optional}
  {-max_early_derate "maximum derate allowed for early derate" float float optional}
  {-min_late_derate "minimum derate allowed for late derate" float float optional}
  {-max_late_derate "maximum derate allowed for late derate" float float optional }
  {-early_margin_pct "additional pct margin to add to early derate tables" float float optional}
  {-late_margin_pct "additional pct margin to add to late derate tables" float float optional}
  {-min_value "minimum value allowed for data" float float optional}
  {-max_value "maximum value allowed for data" float float optional}
  {-vdd "vdd value used in generating derate table" float float optional}
  {-path_type "path_type used for applying derate table" string string hidden}
  {-depth_scale "scale the depth index(default 1.0)" float float optional}
  {-debug "add debug messages" "" boolean optional}
} generate_aocv_table_from_array
echo "Defined procedure 'generate_aocv_table_from_array'."


proc create_generic_aocv_table { args } {
  set cargs(-vdd) ""
  set cargs(-aocv_file) ""
  set cargs(-object_type) "lib_cell"
  set cargs(-object_spec) "*"
  set cargs(-sigma2mean) ""
  set cargs(-incr_depth) 1
  set cargs(-max_logic_depth) 30
  set cargs(-input_file) ""
  set cargs(-path_type) ""

  if { [parse_myproc_arguments -args $args cargs] eq "0"  } {
    return 0
  }
  set watfa ""
  if { $cargs(-vdd) ne ""} {
	append watfa " -vdd $cargs(-vdd)"
  }
  if { $cargs(-path_type) ne "" } {
	if { [regexp "data|clock" $cargs(-path_type)] } {
	append watfa " -path_type $cargs(-vdd)"
	} else {
	puts "ERROR: invalid -path_type option, must be clock and/or data"
	return
	}
  }
	if { [regexp "^\/" $cargs(-aocv_file)] } {
		set dir "/"
	} else {
		set dir "./"
	}
  if { $cargs(-input_file) ne "" } {
	# parse input_file for all cells and such
        set fin [open "$cargs(-input_file)" r]
        while {1} {
                set line [gets $fin]
                if {[eof $fin]} {
                        close $fin
                        break
                }
		if { [regexp "^\[ \t\]*#" $line] } {
		} else {
                set tokens [snps_split $line " \t\n\{\}\""]
		if { [lindex $tokens 4] ne "" } {
			# object spec is defined
			eval generate_generic_aocv_table -aocv_dir $dir -aocv_file $cargs(-aocv_file) -incr [lindex $tokens 2] -max_logic_depth [lindex $tokens 3] -mean 1.0 -variation_delta [lindex $tokens 1]  -append -object_spec [lindex $tokens 4] -object_type [lindex $tokens 0] $watfa
		} elseif { [lindex $tokens 3] ne "" } {
			# general object type
			eval generate_generic_aocv_table -aocv_dir $dir -aocv_file $cargs(-aocv_file) -incr [lindex $tokens 2] -max_logic_depth [lindex $tokens 3] -mean 1.0 -variation_delta [lindex $tokens 1]  -append -object_spec {*} -object_type [lindex $tokens 0] $watfa
		}
		}
	}
		
# OBJECT_TYPE SIGMA_BY_MEAN_RATIO  INCR_DEPTH  MAX_DEPTH  [OBJECT_SPEC] 
#LIB_CELL 0.002 1 30 lib1/AND2
#LIB_CELL 0.001 1 30 lib1/AND4 
#LIB_CELL 0.1 1 30 lib7/INV2X
#NET  .002 5 50 DESIGN
		
  } else {
	foreach cell $cargs(-object_spec) {	
	eval generate_generic_aocv_table -aocv_dir $dir -aocv_file $cargs(-aocv_file) -incr $cargs(-incr_depth) -max_logic_depth $cargs(-max_logic_depth) -mean 1.0 -variation_delta $cargs(-sigma2mean) -append -object_spec $cell -object_type $cargs(-object_type) $watfa
	}
   }
}
define_myproc_attributes -info "create generic aocv tables using sigma2mean value" -define_args {
  {-object_type  "object_type of data(lib_cell, cell)" "string" string optional}
  {-object_spec  "lib cell name/pattern to apply derate" "string" string optional}
  {-aocv_file  "file aocv tables are written to" "string" string required}
  {-sig_digits "sig digits for data" int int optional}
  {-vdd "vdd value used in generating derate table" float float optional}
  {-incr_depth "incr depth" int int optional}
  {-max_logic_depth "max logic depth" int int optional}
  {-sigma2mean "sigma 2 mean value used in generating derate table" float float optional}
  {-path_type "path_type used for applying derate table" string string hidden}
  {-input_file "file for multiple lib_cell/cell entries" string string hidden}
} create_generic_aocv_table
echo "Defined procedure 'create_generic_aocv_table'."


proc generate_generic_aocv_table { args } {
  set cargs(-cell) ""
  set cargs(-early_margin_pct) 0.0
  set cargs(-late_margin_pct) 0.0
  set cargs(-path_type) ""
  set cargs(-vdd) ""
  set cargs(-aocv_file) ""
  set cargs(-library) ""
  set cargs(-object_type) "lib_cell"
  set cargs(-pocv_dir) "."
  set cargs(-rf_type) "rise fall"
  set cargs(-delay_type) "cell"
  set cargs(-derate_type) ""
  set cargs(-object_spec) ""
  set cargs(-depth) ""
  set cargs(-max_logic_depth) 15
  set cargs(-append) 0
  set cargs(-sig_digits) 3
  set cargs(-min_early_derate) ""
  set cargs(-max_early_derate) ""
  set cargs(-min_late_derate) ""
  set cargs(-max_late_derate) ""
  set cargs(-depth_scale) 1
  set cargs(-mean) ""
  set cargs(-variation_delta) ""
  set cargs(-incr) 1

  if { [parse_myproc_arguments -args $args cargs] eq "0"  } {
    return 0
  }

  if { $cargs(-mean) eq "" } {
	puts "Error: -mean not specified"
	return
  }
  if { $cargs(-variation_delta) eq "" } {
	puts "Error: -sigma not specified"
	return
  }
  if { ![file isdirectory $cargs(-pocv_dir)] } {
    exec mkdir $cargs(-pocv_dir)
  }
  if { $cargs(-object_spec) eq "" } {
    if {$cargs(-cell) ne "" } {
    set cargs(-object_spec) "$cargs(-cell)"
    } else {
    set cargs(-object_spec) "*"
    }
  }
    if { [regexp "rise" $cargs(-rf_type)] } {
    set index 1
    while {$index  <= $cargs(-max_logic_depth) } {
      if { $cargs(-derate_type) ne "late" } {
      set min_rise_edge($index) [expr 1 - ([expr $cargs(-variation_delta)/$cargs(-mean)] / sqrt($index) )]
      }
      if { $cargs(-derate_type) ne "early" } {
      set max_rise_edge($index) [expr 1 + ([expr $cargs(-variation_delta)/$cargs(-mean)] / sqrt($index) )]
      }
      set index [expr $index + $cargs(-incr)]
    }
    }
    if { [regexp "fall" $cargs(-rf_type)] } {
    set index 1
    while {$index  <= $cargs(-max_logic_depth) } {
      if { $cargs(-derate_type) ne "late" } {
      set min_fall_edge($index) [expr 1 - ([expr $cargs(-variation_delta)/$cargs(-mean)] / sqrt($index) )]
      }
      if { $cargs(-derate_type) ne "early" } {
      set max_fall_edge($index) [expr 1 + ([expr $cargs(-variation_delta)/$cargs(-mean)] / sqrt($index) )]
      }
      set index [expr $index + $cargs(-incr)]
    }
    }

  set watfa ""
  foreach opt [list vdd path_type early_margin_pct late_margin_pct sig_digits depth_scale library object_spec] {
	if { $cargs(-$opt) ne "" } {
		append watfa " -$opt $cargs(-$opt)"
	}
  }
  echo "Writing POCV Table in file $cargs(-aocv_file) for $cargs(-object_spec)"

    if { $cargs(-derate_type) ne "late" } {
    set derate ""
    if { $cargs(-max_early_derate) ne "" } {
	append derate " -max_depth_derate $cargs(-max_early_derate)"
    }
    if { $cargs(-min_early_derate) ne "" } {
	append derate " -min_depth_derate $cargs(-min_early_derate)"
    }
    if { $cargs(-rf_type) ne "fall" } {
  if { $cargs(-append) } {
    eval write_aocv_table_from_array  -file $cargs(-pocv_dir)/$cargs(-aocv_file) -derate_type early -rf_type rise -dataarray min_rise_edge -append -object_type lib_cell $watfa $derate
  } else {
    eval write_aocv_table_from_array  -file $cargs(-pocv_dir)/$cargs(-aocv_file) -derate_type early -rf_type rise -dataarray min_rise_edge -object_type lib_cell $watfa $derate
    set cargs(-append) 1
  }
  }
  if {($cargs(-rf_type) ne "rise")} {
  if { $cargs(-append) } {
  eval write_aocv_table_from_array  -file $cargs(-pocv_dir)/$cargs(-aocv_file) -derate_type early -rf_type fall -dataarray  min_fall_edge -append -object_type lib_cell $watfa $derate
  } else {
  eval write_aocv_table_from_array  -file $cargs(-pocv_dir)/$cargs(-aocv_file) -derate_type early -rf_type fall -dataarray  min_fall_edge -object_type lib_cell $watfa $derate
    set cargs(-append) 1
  }
    }
    }
    if { $cargs(-derate_type) ne "early" } {
    set derate ""
    if { $cargs(-max_late_derate) ne "" } {
	append derate " -max_depth_derate $cargs(-max_late_derate)"
    }
    if { $cargs(-min_late_derate) ne "" } {
	append derate " -min_depth_derate $cargs(-min_late_derate)"
    }
    if { $cargs(-rf_type) ne "fall" } {
  if { $cargs(-append) } {
    eval write_aocv_table_from_array  -file $cargs(-pocv_dir)/$cargs(-aocv_file) -derate_type late -rf_type rise -dataarray  max_rise_edge -append -object_type lib_cell $watfa $derate
  } else {
    eval write_aocv_table_from_array  -file $cargs(-pocv_dir)/$cargs(-aocv_file) -derate_type late -rf_type rise -dataarray  max_rise_edge -object_type lib_cell $watfa $derate
    set cargs(-append) 1
  }
  }
  if {($cargs(-rf_type) ne "rise")} {
  if { $cargs(-append) } {
  eval write_aocv_table_from_array  -file $cargs(-pocv_dir)/$cargs(-aocv_file) -derate_type late -rf_type fall -dataarray  max_fall_edge -append -object_type lib_cell $watfa $derate
  } else {
  eval write_aocv_table_from_array  -file $cargs(-pocv_dir)/$cargs(-aocv_file) -derate_type late -rf_type fall -library $cargs(-library) -object_spec $cargs(-object_spec) -dataarray  max_fall_edge -object_type lib_cell $watfa $derate
    set cargs(-append) 1
  }
    }
    }
}
define_myproc_attributes -info "generate generate aocv tables using sqrtN given a mean and sigma" -define_args {
  {-cell  "cell name string" "cell name string" string optional}
  {-aocv_file "aocv output file" string string required}
  {-pocv_dir "aocv dir" string string optional}
  {-library "library for lib_cell object spec" string string optional}
  {-object_type "object type of aocv table" string string optional}
  {-object_spec "object spec to for aocv table to apply" string string optional}
  {-delay_type "delay type of aocv table" string string optional}
  {-rf_type "rf type of aocv table" string string optional}
  {-derate_type "derate type of aocv table(early|late|invert_late|invert_early)" string string optional}
  {-max_logic_depth "max logic depth for Table depth " string string optional}
  {-sig_digits "sig digits for data" int int optional}
  {-incr "incr for depth cnt" int int optional}
  {-append "append to existing file" "" boolean optional}
  {-min_early_derate "minimum derate allowed for early derate" float float optional}
  {-max_early_derate "maximum derate allowed for early derate" float float optional}
  {-min_late_derate "minimum derate allowed for late derate" float float optional}
  {-max_late_derate "maximum derate allowed for late derate" float float optional }
  {-early_margin_pct "additional pct margin to add to early derate tables" float float optional}
  {-late_margin_pct "additional pct margin to add to late derate tables" float float optional}
  {-vdd "vdd value used in generating derate table" float float optional}
  {-path_type "path_type used for applying derate table" string string hidden}
  {-depth_scale "scale the depth index(default 1.0)" float float optional}
  {-mean "mean value of delay thru one level of cell" float float required}
  {-variation_delta "variation delta for one level of cell" float float required}
} generate_generic_aocv_table
echo "Defined procedure 'generate_generic_aocv_table'."

### write out aocv table from a given TCL array
proc write_aocv_table_from_array { args } {
  set cargs(-path_type) ""
  set cargs(-vdd) ""
  set cargs(-early_margin_pct) 0.0
  set cargs(-late_margin_pct) 0.0
  set cargs(-delay_type) "cell"
  set cargs(-derate_type) ""
  set cargs(-rf_type) rise_fall
  set cargs(-file) ""
  set cargs(-library) ""
  set cargs(-object_spec) ""	
  set cargs(-object_type) "lib_cell"	
  set cargs(-append) 0
  set cargs(-sig_digits) 3
  set cargs(-no_curve_fit) 0
  set cargs(-force_pessimistic_monotonic) 0
  set cargs(-max_depth_derate) ""
  set cargs(-min_depth_derate) ""
  set cargs(-depth_scale) 1
  if { [parse_myproc_arguments -args $args cargs] eq "0"} {
    return 0
  }
  upvar 1 $cargs(-dataarray) arrayname


  if { $cargs(-object_spec) eq "" } {
    set cargs(-object_spec) "*"
  }
 
  if { $cargs(-derate_type) eq "" } {
    die "Error: Must specify -derate_type"
  }

  if { [file dirname $cargs(-file)] ne "" } {
    if { ! [file isdirectory [file dirname $cargs(-file)]] } {
      die "Error: directory -- [file dirname $cargs(-file)] does not exists"
    }
  }
  if {$cargs(-append)} {
    if { ! [file exists $cargs(-file)] } {
    set fout [open $cargs(-file) w]
    puts $fout "version:   1.0\n"
    } else {
    set fout [open $cargs(-file) a+]
    }
  } else {
    set fout [open $cargs(-file) w]
    puts $fout "version:   1.0\n"
  }

  if { [array exists arrayname] } {
    if { [info exists ydata] } {
      unset ydata
    }
    if { [info exists newydata] } {
      unset newydata
    }
    set pre ""
    set val ""
    set mono 1
    set xdata [lsort -int [array names arrayname]]
    foreach cnt $xdata {		
      set val $arrayname($cnt)
      if { $cargs(-derate_type) eq "early" } {
        lappend ydata $val
        if { ($pre ne "") && ($val < $pre) } {
          set mono 0
        }
      } elseif { $cargs(-derate_type) eq "late" } {
        lappend ydata $val
        if { ($pre ne "") && ($val > $pre) } {
          set mono 0
        }
      }
      set pre $val
    }
    if  { ! $mono } {
      if { $cargs(-no_curve_fit) } {
        puts "WARNING: $cargs(-derate_type) $cargs(-rf_type) edge is non-monotonic, fix manually"
        set newydata $ydata
      } elseif { $cargs(-force_pessimistic_monotonic) } {
        puts "WARNING: $cargs(-derate_type) $cargs(-rf_type) edge is non-monotonic, forcing pessimistic monotonic"
        set newydata $ydata
        set i [expr [llength $ydata] - 2]
        while { $i >= 0 } {
	  if { $cargs(-derate_type) eq "early" } {
          if { [lindex $newydata $i] > [lindex $newydata [expr {$i + 1}]]} {
            lset newydata $i [lindex $newydata [expr {$i + 1}]]
          }
	  } elseif { $cargs(-derate_type) eq "late" } {
          if { [lindex $newydata $i] < [lindex $newydata [expr {$i + 1}]]} {
            lset newydata $i [lindex $newydata [expr {$i + 1}]]
          }
	  }
          decr i
        }
      } else {
        puts "WARNING: $cargs(-derate_type) $cargs(-rf_type) edge is non-monotonic, doing logarithmic curve fit"
        natural_logarithmic_curve_fit -xdatalist xdata -ydatalist ydata  -newydatalist newydata 
      }
    } else {
      set newydata $ydata
    }
	
    puts $fout "object_type: $cargs(-object_type)"
    puts $fout "delay_type: $cargs(-delay_type)"
    puts $fout "rf_type: $cargs(-rf_type)"
    puts $fout "derate_type: $cargs(-derate_type)"
    if { $cargs(-library) ne "" } {
    puts $fout "object_spec: $cargs(-library)/$cargs(-object_spec)"
    } else {
    puts $fout "object_spec: $cargs(-object_spec)"
    }
    if { $cargs(-vdd) ne "" } {
	puts $fout "voltage: $cargs(-vdd)"
    }
    if { $cargs(-path_type) ne "" } {
	if { [regexp "data|clock" $cargs(-path_type)] } {
	puts $fout "path_type: $cargs(-vdd)"
	} else {
	puts "ERROR: invalid -path_type option"
	return
	}
    }
    puts -nonewline $fout "depth:"
    foreach cnt $xdata {
      puts -nonewline $fout " [expr $cnt * $cargs(-depth_scale)]"
    }
    puts $fout "\ndistance:"
    puts -nonewline $fout "table:"
    foreach cnt $newydata {
      if { [regexp "early" $cargs(-derate_type)]  } {
	 set margin "-$cargs(-early_margin_pct)"
      } elseif { [regexp "late" $cargs(-derate_type)] } {
	 set margin $cargs(-late_margin_pct)
      } else {
	 set margin 0.0
      }

      if { ($cargs(-max_depth_derate) eq "") || ([expr $cnt + $margin] <= $cargs(-max_depth_derate)) } {
      if { ($cargs(-min_depth_derate) eq "") || ([expr $cnt + $margin] >= $cargs(-min_depth_derate)) } {
      puts -nonewline $fout [format " %.$cargs(-sig_digits)f" [expr $cnt + $margin]]
      } elseif { ([expr $cnt + $margin] < $cargs(-min_depth_derate)) } {
      puts "Error: (write_aocv_table_from_array): $cargs(-derate_type) POCV DERATE: [expr $cnt + $margin] < $cargs(-min_depth_derate)"
      } else {
      puts -nonewline $fout [format " %.$cargs(-sig_digits)f" $cargs(-min_depth_derate)]
      }
      } elseif { ([expr $cnt + $margin] > $cargs(-max_depth_derate)) } {
      puts "Error: (write_aocv_table_from_array): $cargs(-derate_type) POCV DERATE: [expr $cnt + $margin] > $cargs(-max_depth_derate)"
      } else {
      puts -nonewline $fout [format " %.$cargs(-sig_digits)f" $cargs(-max_depth_derate)]
      }
    }
    puts $fout "\n"
    close $fout
  } else {
	puts "Error: -dataarray $cargs(-dataarray) is not a valid TCL array"
	die
  }
}
define_myproc_attributes -info "write aocv file from array" -define_args {
  {-file "filename for AOCV table" string string required}
  {-rf_type "rf type of aocv table" string string optional}
  {-derate_type "derate type for aocv table" string string required}
  {-delay_type "delay type for aocv table" string string optional}
  {-dataarray "data array name" string string required}
  {-library "library for lib_cell object spec" string string optional}
  {-object_type "object type of aocv table" string string optional}
  {-object_spec "object spec to for aocv table to apply" string string optional}
  {-aocv_file "aocv output file" string string required}
  {-sig_digits "sig digits for data" int int optional}
  {-append "append to existing file" "" boolean optional}
  {-no_curve_fit "do not try to auto curve fit" "" boolean optional}
  {-force_pessimistic_monotonic "force derate to be pessimistically monotonic" "" boolean optional}
  {-min_depth_derate "force derate to be > than limit" float float optional}
  {-max_depth_derate "force derate to be < than limit" float float optional}
  {-early_margin_pct "additional pct margin to add to early derate tables" float float optional}
  {-late_margin_pct "additional pct margin to add to late derate tables" float float optional}
  {-vdd "vdd value used in generating derate table(2009.12)" float float optional}
  {-path_type "path_type used for applying derate table(2010.06)" string string hidden}
  {-depth_scale "scale the depth index(default 1.0)" float float optional}
} write_aocv_table_from_array
echo "Defined procedure 'write_aocv_table_from_array'."

### calculate the quantile value given a list of data
proc calculate_mean { args }  {
  set cargs(-max_value) 9999999999999999
  set cargs(-min_value) -9999999999999999
  if { [parse_myproc_arguments -args $args cargs] eq "0" } {
    return 0
  }
  upvar 1 $cargs(-datalist) data
  if {[llength $data] < 1} {
    echo "Error: Missing data in $cargs(-datalist)"
    return
  }
  set min 9999999999999
  set max -9999999999999
  set n 0
  set sum1 0
  foreach x $data {
    if {([string compare $x ""] != 0) && (![regexp "fail" $x])} {
      if {($x<=$cargs(-max_value)) && ($x>=$cargs(-min_value))} {
        lappend new_data $x
        incr n
        if {$x > $max} {
          set max $x
        }
        if {$x < $min} {
          set min $x
        }
        set sum1 [expr $x + $sum1]
      } else {
	puts "Error: (calculate_mean) Monte-Carlo data: $x < $cargs(-min_value) || > $cargs(-max_value)"
      }
    } else {
	puts "Error: (calculate_mean) invalid Monte-Carlo data: $x"
    }
  }
  set mean [expr $sum1/$n]
  return $mean
}
define_myproc_attributes calculate_mean \
-info "Calculate the mean of a list of data" \
-define_args {
  {-datalist "name of a list of data" list_name string optional}
  {-min_value "minimum value allowed for data" float float optional}
  {-max_value "maximum value allowed for data" float float optional}
}
echo "Defined procedure 'calculate_mean'."

### calculate the quantile value given a list of data
proc calculate_quantile { args }  {
  ### this routine uses a modified algorithm by Mendenhall & Sincich: index = $qhi * ($n - 1) of a sorted list
  ###   if index is not an integer, linear interpolation is done between the surrounding points.
  set cargs(-qhi) ".99865"
  set cargs(-qlo) ".00135"
  set cargs(-max_value) 9999999999999999
  set cargs(-min_value) -9999999999999999
  if { [parse_myproc_arguments -args $args cargs] eq "0" } {
    return 0
  }
  upvar 1 $cargs(-datalist) data
  if {[llength $data] < 1} {
    echo "Error: Missing data in $cargs(-datalist)"
    return
  }
  #sort the data:
  set min 9999999999999
  set max -9999999999999
  set n 0
  set sum1 0
  foreach x $data {
    if {([string compare $x ""] != 0) && (![regexp "fail" $x])} {
      if {($x<=$cargs(-max_value)) && ($x>=$cargs(-min_value))} {
        lappend new_data $x
        incr n
        if {$x > $max} {
          set max $x
        }
        if {$x < $min} {
          set min $x
        }
        set sum1 [expr $x + $sum1]
      } else {
	puts "Error: (calculate_quantile) Monte-Carlo data: $x < $cargs(-min_value) || > $cargs(-max_value)"
      }
    } else {
	puts "Error: (calculate_quantile) invalid Monte-Carlo data: $x"
    }
  }
  set mean [expr $sum1/$n]

  set sorted_data [lsort -real -increasing $new_data]
  set n [llength $sorted_data]
  set fold [expr ($n-1)*$cargs(-qhi)]
  set ifold [expr int(($n-1)*$cargs(-qhi))]

  if {($fold - $ifold) < .001} {
    set hi [lindex $sorted_data [expr $ifold]]
  } else {
    #$hi=$sorted_data[$ifold] + ($fold - $ifold) * ($sorted_data[$ifold+1] - $sorted_data[$ifold]);
    set hi [expr [lindex $sorted_data [expr $ifold]] + ($fold - $ifold) * ([lindex $sorted_data [expr $ifold+1]] - [lindex $sorted_data [expr $ifold]])]
  }
  set fold [expr ($n-1)*$cargs(-qlo)]
  set ifold [expr int(($n-1)*$cargs(-qlo))]
  if {($fold - $ifold) < .001} {
    set lo [lindex $sorted_data [expr $ifold]]
  } else {
    #set $lo=$sorted_data[$ifold] + ($fold - $ifold) * ($sorted_data[$ifold1+1] - $sorted_data[$ifold]);
    set lo [expr  [lindex $sorted_data [expr $ifold]] + ($fold - $ifold) * ([lindex $sorted_data [expr $ifold +1]] - [lindex $sorted_data [expr $ifold]])]
  }
  #echo "   MIN: $min MAX: $max MEAN: $mean QLO: $lo QHI: $hi"
  return [list $mean $lo $hi]
}
define_myproc_attributes calculate_quantile \
-info "Calculate the mean and low and high quantile of a list of data" \
-define_args {
  {-datalist "name of a list of data" list_name string optional}
  {-min_value "minimum value allowed for data" float float optional}
  {-max_value "maximum value allowed for data" float float optional}
  {-qlo "Low quantile value (between 0 and 1)" qval float optional}
  {-qhi "High quantile value (between 0 and 1)" qval float optional}
}
echo "Defined procedure 'calculate_quantile'."


### calculate sigma value of list of data
proc calculate_sigma { args } {
  set cargs(-max_value) 9999999999999999
  set cargs(-min_value) -9999999999999999
  set cargs(-datalist) ""
  if { [parse_myproc_arguments -args $args cargs] == "0" } {
    return 0
  }
  upvar 1 $cargs(-datalist) data
  echo "Calculating Sigma of Data"
  set n  0
  set sum1  0
  if {[llength $data] < 1} {
    echo "Error: Missing data in $cargs(-datalist)"
    return
  }
  set min 9999999999
  set max -9999999999
  if {[llength $data] > 1} {
    foreach x $data {
      if {([string compare $x ""] != 0) && (![regexp "fail" $x])} {
        if {($x<=$cargs(-max_value)) && ($x>=$cargs(-min_value))} {
          incr n
          if {$x > $max} {
            set max $x
          }
          if {$x < $min} {
            set min $x
          }
          set sum1 [expr $x + $sum1]
        } else {
	puts "Error: (calculate_sigma) Monte-Carlo data: $x < $cargs(-min_value) || > $cargs(-max_value)"
	}
      } else {
	puts "Error: (calculate_sigma) invalid Monte-Carlo data: $x"
      }
    }
    set mean [expr $sum1/$n]

    set sum2  0
    foreach x $data {
      if {([string compare $x ""] != 0) && (![regexp "fail" $x])} {
        if {($x<=$cargs(-max_value)) && ($x>=$cargs(-min_value))} {
          set sum2 [expr (($x - $mean)*($x - $mean)) + $sum2]
        } else {
	puts "Error: (calculate_sigma) Monte-Carlo data: $x < $cargs(-min_value) || > $cargs(-max_value)"
        }
      } else {
	puts "Error: (calculate_sigma) invalid Monte-Carlo data: $x"
      }
    }
  }
  set variance [expr $sum2/($n-1)]
  set sigma [expr sqrt($variance)]
  #echo "   MIN: $min MAX: $max MEAN: $mean SIGMA: $sigma\n"
  return [list $mean $sigma]
}
define_myproc_attributes calculate_sigma \
-info "Calculated the mean and sigma of a list of data" \
-define_args {
  {-datalist "name of a list of data" list_name string optional}
  {-min_value "minimum value allowed for data" float float optional}
  {-max_value "maximum value allowed for data" float float optional}
}

echo "Defined procedure 'calculate_sigma'."


### curve fit a list of data with a natural logarithmic equation
proc natural_logarithmic_curve_fit { args } {
  set cargs(-ydatalist) ""
  set cargs(-xdatalist) ""
  set cargs(-newydatalist) ""
  set cargs(-A) ""
  set cargs(-B) ""
  #formula = A + B*log(x)
  if { [parse_myproc_arguments -args $args cargs] eq "0" } {
    return 0
  }
  upvar 1 $cargs(-xdatalist) xdata
  upvar 1 $cargs(-ydatalist) ydata
  if { [string compare $cargs(-newydatalist) ""] != 0 } {
    upvar 1 $cargs(-newydatalist) newydata
  }
  if { [string compare $cargs(-A) ""] != 0 } {
    upvar 1 $cargs(-A) A
  }
  if { [string compare $cargs(-B) ""] != 0 } {
    upvar 1 $cargs(-B) B
  }
	
  set n [llength $ydata]
  set i 0
  set sumy 0
  set sumylnx 0
  set sumsqlnx 0
  set sumlnx 0

  ## force the curve to go thru the 0 and N pts. Create the A & B coefficients from there
  #B = (y0 - A)/log(x0)
  #A = (yN - y0 * log(xN)/log(x0))/(1-log(xN)/log(x0))
  #set tmp [expr log([lindex $xdata end])/log([lindex $xdata 0])]
  #set A  [expr [expr [lindex $ydata end] - [lindex $ydata 0]  * $tmp ] / [ expr 1 - $tmp]]
  #set B  [expr [expr [lindex $ydata 0] - A] / log([lindex $xdata 0])]

  while {$i < $n} {
    set sumylnx  [expr $sumylnx + [expr [lindex $ydata $i] * log([lindex $xdata $i])]]
    set sumy  [expr $sumy + [lindex $ydata $i]]
    set sumsqlnx  [expr $sumsqlnx + (log([lindex $xdata $i]) * log([lindex $xdata $i]))]
    set sumlnx  [expr $sumlnx + log([lindex $xdata $i])]
    incr i
  }

  #puts "sumylnx: $sumylnx"
  #puts "sumy: $sumy"
  #puts "sumsqlnx: $sumsqlnx"
  #puts "sumlnx: $sumlnx"
  #puts "n: $n"

  set B [expr [expr [expr $n * $sumylnx] - [expr $sumy * $sumlnx]]/ [expr [expr $n * $sumsqlnx] - [expr $sumlnx * $sumlnx]]]
  set A [expr [expr $sumy - ($B * $sumlnx)]/$n]
  set i 0
  while {$i < $n}  {
    lappend newydata [expr $A + $B * log([lindex $xdata $i])]
    incr i
  }
  if { [string compare $cargs(-newydatalist) ""] == 0 } {
    return $newydata
  }
}
define_myproc_attributes natural_logarithmic_curve_fit \
-info "curve fits a list of data"  \
-define_args \
{ 
  {-xdatalist "name of xdata list" "listname" string required}
  {-ydatalist "name of ydata list" "listname" string required}
  {-newydatalist "name of new ydata list" "listname" string optional}
  {-A "name of A var" "varname" string optional}
  {-B "name of B var" "varname" string optional}
}
echo "Defined procedure 'natural_logarithmic_curve_fit'."

### read monte-carlo measurement data to a TCL array
proc mc_read_measure_data_to_array {args} {
  set cargs(-base_filename)  "00000"
  set cargs(-dataarray) "data"
  set cargs(-measure_data_extension) ".mt0"
  set cargs(-pattern) "\[ap\]ocv_"
  set cargs(-scale_to_ps) 0
  set cargs(-scale_to_ns) 0
  set cargs(-max_value) 99999999999999
  set cargs(-min_value) -99999999999999 
  set cargs(-stat_file) ""
  if { [parse_myproc_arguments -args $args cargs] eq "0"} {
    return 0
  }

  upvar 1 $cargs(-dataarray) data
  array set max_fail {}
  array set min_fail {}
  array set fail {}
  array set total {}

  if { [file exists "${cargs(-base_filename)}$cargs(-measure_data_extension).gz"] } {
    set measure_file_name "${cargs(-base_filename)}$cargs(-measure_data_extension).gz"
    set measure_file [open [concat "|gzip -d -c ${cargs(-base_filename)}$cargs(-measure_data_extension).gz"] r]
    echo "Reading SPICE measure_file : $cargs(-base_filename)$cargs(-measure_data_extension).gz"
  } else {
    set measure_file_name "${cargs(-base_filename)}$cargs(-measure_data_extension)"
    set measure_file [open "${cargs(-base_filename)}$cargs(-measure_data_extension)"]
    echo "Reading SPICE measure_file : $cargs(-base_filename)$cargs(-measure_data_extension)"
  }
  set list [read $measure_file]
  close $measure_file

  regsub {.*\.TITLE[^\n]*\n} $list {} list
  regsub -all -- {\s+} $list { } list
  regsub -all -- {(^ | $)} $list {} list


  #first, get indices
  set indices {}
  set tindex 0
  while {1} {
    set item [lindex $list $tindex]
    #set list [lreplace $list 0 0]
    lappend indices $item
      incr tindex
    if {[string compare $item {alter#}] == 0} {
      break
    } elseif {[string compare $item {temper}] == 0} {
    } elseif {[string compare $item {index}] == 0} {
    } else {
    set total($item) 0
    set fail($item) 0
    set min_fail($item) 0
    set max_fail($item) 0
    }
  }
  #now, get data
  set len [llength $list]
  while { $tindex < $len} {
    #set this_data {}
    foreach index $indices {
      set item [lindex $list $tindex]
      if {[regexp "$cargs(-pattern)" $index]} {
        #set list [lreplace $list 0 0]
	incr total($index)
        if {[string is double $item]} {
          if { $cargs(-scale_to_ns) } {
            set item [expr {1e9*$item}]
          } elseif { $cargs(-scale_to_ps) } {
            set item [expr {1e12*$item}]
          } 
          if {($item > $cargs(-max_value))} {
		incr max_fail($index)
		puts "Warning: $index -> $item is > $cargs(-max_value)"
		lappend data($index) "fail"
	  } elseif {($item < $cargs(-min_value)) } {
		incr min_fail($index)
		puts "Warning: $index -> $item is < $cargs(-min_value)"
		lappend data($index) "fail"
	  } else {
            	lappend data($index) [list $item]
          }
        } else {
		incr fail($index)
	}
      }
      incr tindex
    }
  }
    echo "  Done Reading SPICE measure_file : $measure_file_name"
  if { $cargs(-stat_file) ne "" } {
    	set FOUT [open $cargs(-stat_file) a]
	foreach index [array names total] {
	puts $FOUT "$measure_file_name index=$index min_fail=$min_fail($index) max_fail=$max_fail($index) fail=$fail($index) total=$total($index) "
	}
	close $FOUT
  }

}
define_myproc_attributes mc_read_measure_data_to_array \
-info "read mc measurement data and store to an array" \
-define_args {\
  {-dataarray "array name for storing data" "array name" string required}
  {-base_filename "filename base for measurement files" "file base name" string optional}
  {-measure_data_extension "measurement data file extension" "suffix" string optional}
  {-pattern "regexp pattern of measure variable" "pattern_regexp" string optional}
  {-scale_to_ps 	"scale to ps" "" boolean optional}
  {-scale_to_ns 	"scale to ns" "" boolean optional}
  {-max_value 	"maximum value allowed" "float" float optional}
  {-min_value 	"minimum value allowed" "float" float optional}
  {-stat_file "filename " "file for measure failure stats" string optional}
}
echo "Defined procedure 'mc_read_measure_data_to_array'."


### read monte-carlo measurement data to a TCL list
proc mc_read_measure_data_to_list {args} {
  set cargs(-base_filename)  "00000"
  set cargs(-datalist) "data"
  set cargs(-measure_data_extension) ".mt0"
  set cargs(-pattern) "path_delay"
  set cargs(-scale_to_ps) 0
  set cargs(-scale_to_ns) 0
  set cargs(-max_value) 99999999999999
  set cargs(-min_value) -99999999999999 
  set cargs(-stat_file) ""
  if { [parse_myproc_arguments -args $args cargs] eq "0" } {
    return 0
  }

  upvar 1 $cargs(-datalist) data
  set data {}
  array set max_fail {}
  array set min_fail {}
  array set fail {}
  array set total {}

  if { [file exists "$cargs(-base_filename)$cargs(-measure_data_extension).gz"] } {
    set measure_file_name "${cargs(-base_filename)}$cargs(-measure_data_extension).gz"
    set measure_file [open [concat "|gzip -d -c ${cargs(-base_filename)}$cargs(-measure_data_extension).gz"] r]
    echo "Reading SPICE measure_file : $cargs(-base_filename)$cargs(-measure_data_extension).gz"
  } else {
    set measure_file_name "${cargs(-base_filename)}$cargs(-measure_data_extension)"
    set measure_file [open "${cargs(-base_filename)}$cargs(-measure_data_extension)"]
    echo "Reading SPICE measure_file : $cargs(-base_filename)$cargs(-measure_data_extension)"
  }
  set list [read $measure_file]
  close $measure_file

  regsub {.*\.TITLE[^\n]*\n} $list {} list
  regsub -all -- {\s+} $list { } list
  regsub -all -- {(^ | $)} $list {} list

  #first, get indices
  set indices {}
  set tindex 0
  while {1} {
    set item [lindex $list 0]
    set list [lreplace $list 0 0]
    lappend indices $item
      incr tindex
    if {[string compare $item {alter#}] == 0} {
      break
    } elseif {[string compare $item {temper}] == 0} {
    } elseif {[string compare $item {index}] == 0} {
    } else {
    set total($item) 0
    set fail($item) 0
    set min_fail($item) 0
    set max_fail($item) 0
    }
  }

  #now, get data
  while {[string compare $list {}] != 0} {
    set this_data {}
    foreach index $indices {
      set item [lindex $list 0]
      set list [lreplace $list 0 0]
      if {![string is double $item]} {
	incr fail
        continue
      }
      if {[string first $cargs(-pattern) $index] == 0} {
	incr total($index)
        if { $cargs(-scale_to_ns) } {
          set item [expr {1e9*$item}]
        } elseif { $cargs(-scale_to_ps) } {
          set item [expr {1e12*$item}]
        } 
        if {($item > $cargs(-max_value))} {
		incr max_fail($index)
	} elseif {($item < $cargs(-min_value))} {
		incr min_fail($index)
        } else {
          lappend this_data [list $index $item]
        }
      } else {
		incr fail($index)
      }
    }

    set data [concat $data $this_data]
  }
  echo "   Done Reading SPICE measure_file : $measure_file_name"
  if { $cargs(-stat_file) ne "" } {
    	set FOUT [open $cargs(-stat_file) a]
	foreach index [array names total] {
	puts $FOUT "$measure_file_name index=$index min_fail=$min_fail($index) max_fail=$max_fail($index) fail=$fail($index) total=$total($index) "
	}
	close $FOUT
  }
}
define_myproc_attributes mc_read_measure_data_to_list \
-info "read mc measurement data and store to a list" \
-define_args {\
  {-datalist "list name for storing data" "list name" string required}
  {-base_filename "filename base for measurement files" "file base name" string optional}
  {-measure_data_extension "measurement data file extension" "suffix" string optional}
  {-pattern "regexp pattern of measure variable" "pattern_regexp" string optional}
  {-scale_to_ps 	"scale to ps" "" boolean optional}
  {-scale_to_ns 	"scale to ns" "" boolean optional}
  {-max_value 	"maximum value allowed" "float" float optional}
  {-min_value 	"minimum value allowed" "float" float optional}
  {-stat_file "filename " "file for measure failure stats" string optional}
}
echo "Defined procedure 'mc_read_measure_data_to_list'."


### marge multiple AOCV tables into a single table
proc merge_cell_aocv { args } {
   set cargs(-output) ""
   set cargs(-early) 0
   set cargs(-late) 0
   set cargs(-rise) 0
   set cargs(-fall) 0
   set cargs(-cell) "*"
   set cargs(-aocv_dir) "./"
   set cargs(-aocv_suff) ".AOCV"
   set cargs(-use_value) "" 
   set cargs(-no_curve_fit) 0
   set cargs(-force_pessimistic_monotonic) 0
   set cargs(-pct) 1.0
   set cargs(-files) ""
   set cargs(-start_level) 1
   parse_myproc_arguments -args $args cargs

   set object_type ""
   set object_spec ""
   if { [string compare $cargs(-output) ""] == 0 } {
	set cargs(-output) "$cargs(-aocv_dir)/__design.$cargs(-aocv_suff)"
   }
   if { ! $cargs(-early) && ! $cargs(-late)} {
 	set cargs(-early) 1
 	set cargs(-late) 1
   }
   if { ! $cargs(-rise) && ! $cargs(-fall)} {
 	set cargs(-rise) 1
 	set cargs(-fall) 1
   }

	
   foreach cell $cargs(-cell) { 
   puts "Processing cell: $cell"
   if { [info exists depth] } {
	unset depth
   }
	if { $cargs(-files) eq "" } {
	set files [glob -nocomplain "$cargs(-pocv_dir)/${cell}\*$cargs(-aocv_suff)"]
	} else {
	set files {}
	foreach file [split [regsub -all "\[ \t\]+" [string trim [join $cargs(-files)]] { }]] {
	lappend files [glob -nocomplain $file]
        }
	}
	foreach  file  [split [regsub -all "\[ \t\]+" [string trim [join $files]] { }]] {
	puts "Processing AOCV file: $file"
	set fin [open "$file" r]
	while {1} {
    		set line [gets $fin]
    		if {[eof $fin]} {
        		close $fin
        		break
		}
    	set tokens [split $line " \t\n\{\}\""]
    	if {[string compare [lindex $tokens 0] "delay_type:"] == 0 } {
		if { [string compare [lindex $tokens 1] "cell"] == 0 } {
			set delay "cell"
		} else {
			set delay ""
		}
    	} elseif {[string compare [lindex $tokens 0] "object_spec:"] == 0 } {
		if { ($object_spec ne "") && ($object_spec ne [lindex $tokens 1]) } {
			set object_spec "*"
		} else {
			set object_spec [lindex $tokens 1]
		}
    	} elseif {[string compare [lindex $tokens 0] "object_type:"] == 0 } {
		if { ($object_type ne "") && ($object_type ne [lindex $tokens 1]) } {
			set object_type "design"
		} else {
			set object_type [lindex $tokens 1]
		}
    	} elseif {[string compare [lindex $tokens 0] "derate_type:"] == 0 } {
		if {[string compare [lindex $tokens 1] "early"] == 0} {
			set type "early"
		} elseif { [string compare [lindex $tokens 1] "late"] == 0} {
			set type "late"
		} else {
			set type ""
		}
    	} elseif {[string compare [lindex $tokens 0] "rf_type:"] == 0 } {
		if {[string compare [lindex $tokens 1] "rise"] == 0} {
			set rf "rise"
		} elseif { [string compare [lindex $tokens 1] "fall"] == 0} {
			set rf "fall"
		} else {
			set rf ""
		}
    	} elseif {[string compare [lindex $tokens 0] "table:"] == 0 } {
	if { [string compare $delay ""] != 0 } {
        set i 1	
	while {$i < [llength $tokens]} {
		if {[string is double [lindex $tokens $i]]} {
		set level [lindex $depth [expr $i -1]]

	if { $cargs(-late) && ([string compare $type "early"] != 0) } {
	if { $cargs(-rise) && ([string compare $rf "fall"] != 0) } {
		if { ![array exists late_rise_derate] || ![info exists late_rise_derate($level)] || ( [lindex $tokens $i] > $late_rise_derate($level))} {
		set late_rise_derate($level) [lindex $tokens $i]	
		}
	}
	if { $cargs(-fall) && ([string compare $rf "rise"] != 0) } { 
		if { ![array exists late_fall_derate] || ![info exists late_fall_derate($level)] || ( [lindex $tokens $i] > $late_fall_derate($level))} {
		set late_fall_derate($level) [lindex $tokens $i]	
		}
	}
	}	
	if { $cargs(-early) && ([string compare $type "late"] != 0)} {
	if { $cargs(-rise) && ([string compare $rf "fall"] != 0) } {
		if { ![array exists early_rise_derate] || ![info exists early_rise_derate($level)] || ( [lindex $tokens $i] < $early_rise_derate($level))} {
		set early_rise_derate($level) [lindex $tokens $i]	
		}
	}
	if { $cargs(-fall) && ([string compare $rf "rise"] != 0) } { 
		if { ![array exists early_fall_derate] || ![info exists early_fall_derate($level)] || ( [lindex $tokens $i] < $early_fall_derate($level))} {
		set early_fall_derate($level) [lindex $tokens $i]	
		}
	}
	}
		}
		incr i
	}
	}
    	} elseif {[string compare [lindex $tokens 0] "depth:"] == 0 } {
        set i 1	
	if { [info exists depth] } {
	unset depth
	}
	while {$i < [llength $tokens]} {
		if {[string is integer [lindex $tokens $i]]} {
			lappend depth [lindex $tokens $i]
		}
		incr i
	}
	}
	}
	}
   }

puts "Merging AOCV files: $files -> $cargs(-output)"
if {$cargs(-no_curve_fit)} {
} elseif { ($cargs(-use_value) eq "worst_per_level") || $cargs(-force_pessimistic_monotonic)} {
	if { $cargs(-early) && $cargs(-rise) } {
		set level_list [lsort -decreasing -real [array names early_rise_derate]]
		set i 0
		while { $i < [llength $level_list] } {
			set level [lindex $level_list $i]
			if { ($i > 0) && ($early_rise_derate($level) > $early_rise_derate($prelevel)) } {
				set early_rise_derate($level) [format "%.4f" $early_rise_derate($prelevel)]
			} else {
				set early_rise_derate($level) [format "%.4f" $early_rise_derate($level)]
			}
			set prelevel [lindex $level_list [expr $i]]
			incr i
		}
	}
	if { $cargs(-early) && $cargs(-fall) } {
		set level_list [lsort -decreasing -real [array names early_fall_derate]]
		set i 0
		while { $i < [llength $level_list] } {
			set level [lindex $level_list $i]
			if { ($i > 0) && ($early_fall_derate($level) > $early_fall_derate($prelevel)) } {
				set early_fall_derate($level) [format "%.4f" $early_fall_derate($prelevel)]
			} else {
				set early_fall_derate($level) [format "%.4f" $early_fall_derate($level)]
			}
			set prelevel [lindex $level_list [expr $i]]
			incr i
		}
	}
	if { $cargs(-late) && $cargs(-rise) } {
		set level_list [lsort -decreasing -real [array names late_rise_derate]]
		set i 0
		while { $i < [llength $level_list] } {
			set level [lindex $level_list $i]
			if { ($i > 0) && ($late_rise_derate($level) < $late_rise_derate($prelevel)) } {
				set late_rise_derate($level) [format "%.4f" $late_rise_derate($prelevel)]
			} else {
				set late_rise_derate($level) [format "%.4f" $late_rise_derate($level)]
			}
			set prelevel [lindex $level_list [expr $i]]
			incr i
		}
	}
	if { $cargs(-late) && $cargs(-fall) } {
		set level_list [lsort -decreasing -real [array names late_fall_derate]]
		set i 0
		while { $i < [llength $level_list] } {
			set level [lindex $level_list $i]
			if { ($i > 0) && ($late_fall_derate($level) < $late_fall_derate($prelevel)) } {
				set late_fall_derate($level) [format "%.4f" $late_fall_derate($prelevel)]
			} else {
				set late_fall_derate($level) [format "%.4f" $late_fall_derate($level)]
			}
			set prelevel [lindex $level_list [expr $i]]
			incr i
		}
	}
} elseif {$cargs(-use_value) eq ""} {
	# natural logarithmic fit: default
	if { $cargs(-early) && $cargs(-fall) } {
	set xdatalist {}
	set ydatalist {}
	set newydata {}
	foreach key [lsort -increasing -real [array names early_fall_derate]] {
		lappend xdatalist $key
		lappend ydatalist $early_fall_derate($key)	
	}
        natural_logarithmic_curve_fit -xdatalist xdatalist -ydatalist ydatalist  -newydatalist newydata 
	set i 0
	foreach key $xdatalist {
	set early_fall_derate($key) [format "%.4f" [lindex $newydata $i]]
	incr i
	}
	}
	if { $cargs(-early) && $cargs(-rise) } {
	set xdatalist {}
	set ydatalist {}
	set newydata {}
	foreach key [lsort -increasing -real [array names early_rise_derate]] {
		lappend xdatalist $key
		lappend ydatalist $early_rise_derate($key)	
	}
        natural_logarithmic_curve_fit -xdatalist xdatalist -ydatalist ydatalist  -newydatalist newydata 
	set i 0
	foreach key $xdatalist {
	set early_rise_derate($key) [format "%.4f" [lindex $newydata $i]]
	incr i
	}
	}
	if { $cargs(-late) && $cargs(-rise) } {
	set xdatalist {}
	set ydatalist {}
	set newydata {}
	foreach key [lsort -increasing -real [array names late_rise_derate]] {
		lappend xdatalist $key
		lappend ydatalist $late_rise_derate($key)	
	}
        natural_logarithmic_curve_fit -xdatalist xdatalist -ydatalist ydatalist  -newydatalist newydata 
	set i 0
	foreach key $xdatalist {
	set late_rise_derate($key) [format "%.4f" [lindex $newydata $i]]
	incr i
	}
	}
	if { $cargs(-late) && $cargs(-fall) } {
	set xdatalist {}
	set ydatalist {}
	set newydata {}
	foreach key [lsort -increasing -real [array names late_fall_derate]] {
		lappend xdatalist $key
		lappend ydatalist $late_fall_derate($key)	
	}
        natural_logarithmic_curve_fit -xdatalist xdatalist -ydatalist ydatalist  -newydatalist newydata 
	set i 0
	foreach key $xdatalist {
	set late_fall_derate($key) [format "%.4f" [lindex $newydata $i]]
	incr i
	}
	}
} elseif {[string compare $cargs(-use_value) "avg"] == 0} {
	if { $cargs(-early) && $cargs(-rise) } {
		set derate 0
		set cnt 0
		foreach level [lsort -increasing -real [array names early_rise_derate]] {
			set derate [expr $derate + $early_rise_derate($level)]
			incr cnt
		} 
		array unset early_rise_derate 
		set early_rise_derate(1) [format "%.4f" [expr $derate / $cnt]]
		set early_rise_derate(2) [format "%.4f" [expr $derate / $cnt]]
	}
	if { $cargs(-early) && $cargs(-fall) } {
		set derate 0
		set cnt 0
		foreach level [lsort -increasing -real [array names early_fall_derate]] {
			set derate [expr $derate + $early_fall_derate($level)]
			incr cnt
		} 
		array unset early_fall_derate 
		set early_fall_derate(1) [format "%.4f" [expr $derate / $cnt]]
		set early_fall_derate(2) [format "%.4f" [expr $derate / $cnt]]
	}
	if { $cargs(-late) && $cargs(-rise) } {
		set derate 0
		set cnt 0
		foreach level [lsort -increasing -real [array names late_rise_derate]] {
			set derate [expr $derate + $late_rise_derate($level)]
			incr cnt
		} 
		array unset late_rise_derate 
		set late_rise_derate(1) [format "%.4f" [expr $derate / $cnt]]
		set late_rise_derate(2) [format "%.4f" [expr $derate / $cnt]]
	}
	if { $cargs(-late) && $cargs(-fall) } {
		set late_fall_derate [expr $late_fall_derate_total / $late_fall_cnt]
		set derate 0
		set cnt 0
		foreach level [lsort -increasing -real [array names late_fall_derate]] {
			set derate [expr $derate + $late_fall_derate($level)]
			incr cnt
		} 
		array unset late_fall_derate 
		set late_fall_derate(1) [format "%.4f"  [expr $derate / $cnt]]
		set late_fall_derate(2) [format "%.4f" [expr $derate / $cnt]]
	}
} elseif {[string compare $cargs(-use_value) "worst"] == 0} {
	if { $cargs(-early) && $cargs(-rise) } {
		set derate 0
		set cnt 0
		foreach level [lsort -increasing -real [array names early_rise_derate]] {
			if { ![info exists derate] || ( $derate > $early_rise_derate($level))} {
			 set derate $early_rise_derate($level)
			}
			incr cnt
		} 
		array unset early_rise_derate 
		set early_rise_derate(1) [format "%.4f" $derate]
		set early_rise_derate(2) [format "%.4f" $derate]
	}
	if { $cargs(-early) && $cargs(-fall) } {
		set derate 0
		set cnt 0
		foreach level [lsort -increasing -real [array names early_fall_derate]] {
			if { ![info exists derate] || ( $derate > $early_fall_derate($level))} {
			 set derate $early_fall_derate($level)
			}
			incr cnt
		} 
		array unset early_fall_derate 
		set early_fall_derate(1) [format "%.4f" $derate]
		set early_fall_derate(2) [format "%.4f" $derate]
	}
	if { $cargs(-late) && $cargs(-rise) } {
		set derate 0
		set cnt 0
		foreach level [lsort -increasing -real [array names late_rise_derate]] {
			if { ![info exists derate] || ( $derate < $late_rise_derate($level))} {
			 set derate $late_rise_derate($level)
			}
			incr cnt
		} 
		array unset late_rise_derate 
		set late_rise_derate(1) [format "%.4f" $derate]
		set late_rise_derate(2) [format "%.4f" $derate]
	}
	if { $cargs(-late) && $cargs(-fall) } {
		set derate 0
		set cnt 0
		foreach level [lsort -increasing -real [array names late_fall_derate]] {
			if { ![info exists derate] || ( $derate < $late_fall_derate($level))} {
			 set derate $late_fall_derate($level)
			}
			incr cnt
		} 
		array unset late_fall_derate 
		set late_fall_derate(1) [format "%.4f" $derate]
		set late_fall_derate(2) [format "%.4f" $derate]
	}
}	
set fout [open $cargs(-output) w]
puts $fout "version:   1.0"
if { $cargs(-early) && $cargs(-rise) && [array exists early_rise_derate]} {
puts $fout   ""
if  { $object_type ne ""}  {
puts $fout "object_type: $object_type"
}  else {
puts $fout "object_type: design"
}
puts $fout "delay_type: cell"
puts $fout "rf_type: rise"
puts $fout "derate_type: early"
if { $object_spec ne "" } {
puts $fout "object_spec: $object_spec"
} else {
puts $fout "object_spec: *"
}
puts -nonewline $fout "depth:"
foreach level [lsort -increasing -real [array names early_rise_derate]] {
	if { $level >= $cargs(-start_level) } {
	puts -nonewline $fout " $level"
	}
}
puts $fout ""
puts $fout "distance:"
puts -nonewline $fout "table:"
foreach level [lsort -increasing -real [array names early_rise_derate]] {
	if { $level >= $cargs(-start_level) } {
	puts -nonewline $fout " $early_rise_derate($level)"
	}
}
puts $fout  ""
}
if { $cargs(-early) && $cargs(-fall) && [array exists early_fall_derate] } {
puts $fout  ""
if  { $object_type ne ""}  {
puts $fout "object_type: $object_type"
}  else {
puts $fout "object_type: design"
}
puts $fout "delay_type: cell"
puts $fout "rf_type: fall"
puts $fout "derate_type: early"
if { $object_spec ne "" } {
puts $fout "object_spec: $object_spec"
} else {
puts $fout "object_spec: *"
}
puts -nonewline $fout "depth:"
foreach level [lsort -increasing -real [array names early_fall_derate]] {
	if { $level >= $cargs(-start_level) } {
	puts -nonewline $fout " $level"
	}
}
puts $fout ""
puts $fout "distance:"
puts -nonewline $fout "table:"
foreach level [lsort -increasing -real [array names early_fall_derate]] {
	if { $level >= $cargs(-start_level) } {
	puts -nonewline $fout " $early_fall_derate($level)"
	}
}
puts $fout  ""
puts $fout  ""
}
if { $cargs(-late) && $cargs(-rise) && [array exists late_rise_derate] } {
puts $fout  ""
if  { $object_type ne "" } {
puts $fout "object_type: $object_type"
}  else {
puts $fout "object_type: design"
}
puts $fout "delay_type: cell"
puts $fout "rf_type: rise"
puts $fout "derate_type: late"
if { $object_spec ne "" } {
puts $fout "object_spec: $object_spec"
} else {
puts $fout "object_spec: *"
}
puts -nonewline $fout "depth:"
foreach level [lsort -increasing -real [array names late_rise_derate]] {
	if { $level >= $cargs(-start_level) } {
	puts -nonewline $fout " $level"
	}
}
puts $fout ""
puts $fout "distance:"
puts -nonewline $fout "table:"
foreach level [lsort -increasing -real [array names late_rise_derate]] {
	if { $level >= $cargs(-start_level) } {
	puts -nonewline $fout " $late_rise_derate($level)"
	}
}
puts $fout  ""
puts $fout  ""
}
if { $cargs(-late) && $cargs(-fall) && [array exists late_fall_derate] } {
puts $fout  ""
if  { $object_type ne ""}  {
puts $fout "object_type: $object_type"
}  else {
puts $fout "object_type: design"
}
puts $fout "delay_type: cell"
puts $fout "rf_type: fall"
puts $fout "derate_type: late"
if { $object_spec ne "" } {
puts $fout "object_spec: $object_spec"
} else {
puts $fout "object_spec: *"
}
puts -nonewline $fout "depth:"
foreach level [lsort -increasing -real [array names late_fall_derate]] {
	if { $level >= $cargs(-start_level) } {
	puts -nonewline $fout " $level"
	}
}
puts $fout ""
puts $fout "distance:"
puts -nonewline $fout "table:"
foreach level [lsort -increasing -real [array names late_fall_derate]] {
	if { $level >= $cargs(-start_level) } {
	puts -nonewline $fout " $late_fall_derate($level)"
	}
}
puts $fout  ""
puts $fout  ""
}
close $fout 
}
define_myproc_attributes -info "merge cell aocv tables" -define_args {
        { "-output"         "output name" "filename" string optional}
        { "-files"         "AOCV files to merge" "filename(s)" string optional}
        { "-cell"         "cell name string" "cell name string" string optional}
        { "-aocv_suff"         "suffix of AOCV tables" "AOCV table suffix" string optional}
        { "-aocv_dir"         "aocv dir" "aocv_dir" string required}
        { "-late"          "apply late derate only" "" boolean optional}
        { "-early"          "apply early derate only" "" boolean optional}
        { "-all"          "apply from all aocv cell tables" "" boolean optional}
        { "-pct"          "apply pct to use_value" float float optional}
        { "-no_curve_fit"          "keep raw values after merging" "" boolean optional}
        { "-force_pessimistic_monotonic" "force pessimistic monotonic values(ie: -use_value worst_per_level)" "" boolean optional}
        { "-use_value"    "choose value from cell tables(worst avg best)" string string optional}
        { "-start_level"    "choose starting level of cell tables" int int optional}
} merge_cell_aocv
echo "Defined procedure 'merge_cell_aocv'."

proc modify_cell_aocv { args } {
   set cargs(-output_ext) ".mod"
   set cargs(-files) ""
   set cargs(-start_level) 1
   set cargs(-aocv_dir) "."
   parse_myproc_arguments -args $args cargs
	if { $cargs(-files) eq "" } {
	set files [glob -nocomplain "$cargs(-aocv_dir)/${cell}\*$cargs(-aocv_suff)"]
	} else {
	set files {}
	foreach file [split [regsub -all "\[ \t\]+" [string trim [join $cargs(-files)]] { }]] {
	lappend files [glob -nocomplain $file]
        }
	}
	foreach  file  [split [regsub -all "\[ \t\]+" [string trim [join $files]] { }]] {
	puts "Processing AOCV file: $file"
	set fin [open "$file" r]
        set fout [open "${file}$cargs(-output_ext)" w]
	while {1} {
    		set line [gets $fin]
    		if {[eof $fin]} {
        		close $fin
        		break
		}
    	       set tokens [split $line " \t\n\{\}\""]
    	if {[string compare [lindex $tokens 0] "depth:"] == 0 } {
        set i 1	
        set exp ""
	while {$i < [llength $tokens]} {
		if {[string is integer [lindex $tokens $i]] && ([lindex $tokens $i] < $cargs(-start_level))} {
			append exp "\[ \]*\[0-9\.\-\]+"
		} elseif {([lindex $tokens $i] >= $cargs(-start_level))} {
			break
		}
		incr i
	}
		if { $exp ne "" } {
		regsub "$exp" $line "" line
		}
		puts $fout $line
    	} elseif {[string compare [lindex $tokens 0] "table:"] == 0 } {
		regsub "$exp" $line "" line
		puts $fout $line
	} else {
		puts $fout $line
	}
		
	}
       close $fout 
	}
}
define_myproc_attributes -info "modify aocv tables" -define_args {
        { "-output_ext"         "output name extension" "string" string optional}
        { "-files"         "AOCV files to merge" "filename(s)" string optional}
        { "-start_level"    "choose starting level of cell tables" int int optional}
        { "-aocv_dir"         "aocv dir" "aocv_dir" string required}
} modify_cell_aocv
echo "Defined procedure 'modify_cell_aocv'."

proc compare_aocv_tables { args } {
   set cargs(-aocv_dir) "."
   set cargs(-aocv1) ""
   set cargs(-aocv2) ""
   parse_myproc_arguments -args $args cargs
	read_aocv_table -aocv $cargs(-aocv1) -aocv_dir $cargs(-aocv_dir) -arrayname data1
	read_aocv_table -aocv $cargs(-aocv2) -aocv_dir $cargs(-aocv_dir) -arrayname data2
	if { [array exists data1] && [array exists data2] } {
	set array_names1 [array names data1 -regexp ".*table$"]
	set array_names2 [array names data2 -regexp ".*table$"]
	foreach key1 $array_names1 {
	set abs_diff {}
	set max_diff {}
	set min_diff {}
	set avg_diff {}
	set min_pct_diff {}
	set max_pct_diff {}
	set abs_pct_diff {}
	set avg_pct_diff {}
	set worst_diff_index {}
	set worst_pct_diff_index {}
	set sumdiff 0
	set sumpctdiff 0
		set key3 $key1
		regsub "^\[^\,\]*," $key1 {} key1
		set key2 [lsearch -regexp $array_names2 ".*,$key1"]
		if { $key2 != -1  } {
			set table1 $data1($key3)
			set table2 $data2([lindex $array_names2 $key2])
			# need to add a check for depth indexes being different
			set i 0
			while  { $i < [llength $table1] } {
				set diff [expr [lindex $table2 $i] - [lindex $table1 $i]]
				set sumdiff [expr $sumdiff + $diff]
				set absdiff [expr abs($diff)]
				set pctdiff [expr 200 * $diff/([lindex $table1 $i] + [lindex $table2 $i])]
				set abspctdiff [expr abs($pctdiff)]
				set sumpctdiff [expr $sumpctdiff + $pctdiff]
				if { ($min_diff eq "") || ($diff < $min_diff) } {
					set min_diff $diff
				}
				if { ($max_diff eq "") || ($diff > $max_diff) } {
					set max_diff $diff
				}
				if { ($abs_diff eq "") || ($absdiff > $abs_diff) } {
					set abs_diff $absdiff
					set worst_diff_index "INDEX: $i TABLE1: [lindex $table1 $i]  TABLE2: [lindex $table2 $i]"
				}
				if { ($min_pct_diff eq "") || ($pctdiff < $min_pct_diff) } {
					set min_pct_diff $pctdiff
				}
				if { ($max_pct_diff eq "") || ($pctdiff > $max_pct_diff) } {
					set max_pct_diff $pctdiff
				}
				if { ($abs_pct_diff eq "") || ($abspctdiff > $max_pct_diff) } {
					set abs_pct_diff $abspctdiff
					set worst_pct_diff_index "INDEX: $i TABLE1: [lindex $table1 $i]  TABLE2: [lindex $table2 $i]"
				}
				incr i
			}
		
	puts "TABLE: $cargs(-aocv1):$key3  vs $cargs(-aocv2):[lindex $array_names2 $key2]"
	puts "MIN DIFF: $min_diff"
	puts "MAX DIFF: $max_diff"
	puts "ABS DIFF: $abs_diff"
	puts "AVG DIFF: [expr $sumdiff / $i]"
	puts "MIN PCT DIFF: $min_pct_diff"
	puts "MAX PCT DIFF: $max_pct_diff"
	puts "ABS PCT DIFF: $abs_pct_diff"
	puts "AVG PCT DIFF: [expr $sumpctdiff/$i]"
		}
	}
      #  set refarray($object_spec,$delay_type,$object_type,$derate_type,$rf_type,depth) $depth
      #  set refarray($object_spec,$delay_type,$object_type,$derate_type,$rf_type,table) $table
      } elseif { [array exists data2] } {
	puts "Error: AOCV table $cargs(-aocv1) doesn't exist"
      } elseif { [array exists data1] } {
	puts "Error: AOCV table $cargs(-aocv2) doesn't exist"
      } else {
	puts "Error: AOCV table $cargs(-aocv1) doesn't exist"
	puts "Error: AOCV table $cargs(-aocv2) doesn't exist"
      }
}
define_myproc_attributes -info "compare aocv tables" -define_args {
        { "-aocv1"         "golden AOCV table file" "AOCV table suffix" string optional}
        { "-aocv2"         "AOCV table file to compare" "AOCV table suffix" string optional}
        { "-aocv_dir"         "aocv dir" "aocv_dir" string required}
} compare_aocv_tables
echo "Defined procedure 'compare_aocv_tables'."

proc read_aocv_table { args } {
   set cargs(-aocv) ""
   set cargs(-aocv_dir) "."
   set cargs(-object_spec) "\[^\,\]*"
   set cargs(-arrayname) ""
   set cargs(-debug) 0

   parse_myproc_arguments -args $args cargs

   upvar $cargs(-arrayname) refarray

   set object_type ""

	set files [glob -nocomplain "$cargs(-aocv_dir)/$cargs(-aocv)"]
	foreach  file  $files {
 	puts "Reading AOCV File: $file"	
	set fin [open "$file" r]
	while {1} {
    		set line [gets $fin]
    		if {[eof $fin]} {
        		close $fin
        		break
		}
    	set tokens [snps_split $line " \t\n\{\}\""]
    	if {[string compare [lindex $tokens 0] "delay_type:"] == 0 } {
		# cell net 
		set delay_type [lindex $tokens 1]
    	} elseif {[string compare [lindex $tokens 0] "object_spec:"] == 0 } {
		if { $cargs(-object_spec) eq "" } {
		set object_spec [lindex $tokens 1]
		} elseif { [regexp -- "$cargs(-object_spec)" [lindex $tokens 1]] } {
		set object_spec [lindex $tokens 1]
		} else {
		set object_spec ""
		}
    	} elseif {[string compare [lindex $tokens 0] "object_type:"] == 0 } {
		# cell, lib_cell
		set object_type [lindex $tokens 1]
    	} elseif {[string compare [lindex $tokens 0] "derate_type:"] == 0 } {
		# early late
		set derate_type [lindex $tokens 1]
    	} elseif {[string compare [lindex $tokens 0] "rf_type:"] == 0 } {
		# rise, fall, "rise fall"
		set rf_type [lindex $tokens 1]
    	} elseif {[string compare [lindex $tokens 0] "depth:"] == 0 } {
        set i 1	
	set depth {}
	while {$i < [llength $tokens]} {
		if {[string is integer [lindex $tokens $i]]} {
			lappend depth [lindex $tokens $i]
		}
		incr i
	}
    	} elseif {[string compare [lindex $tokens 0] "table:"] == 0 } {
        set i 1
        set table {}
        while {$i < [llength $tokens]} {
                if {[string is double [lindex $tokens $i]]} {
                        lappend table [lindex $tokens $i]
                }
                incr i
        }
        if { $cargs(-object_spec) ne "" } {
        set refarray($object_spec,$delay_type,$object_type,$derate_type,$rf_type,depth) $depth
        set refarray($object_spec,$delay_type,$object_type,$derate_type,$rf_type,table) $table
        }
        }
        }

 	puts "Done Reading AOCV File: $file"	
	}
}
define_myproc_attributes -info "read aocv tables" -define_args {
        { "-arrayname"        "array name to store aocv table data" string string required}
        { "-aocv"         "AOCV table file" "AOCV table suffix" string optional}
        { "-object_spec"  " match object_spec" "string" string optional}
        { "-aocv_dir"         "aocv dir" "aocv_dir" string required}
        { "-debug"         "add debug messages" "" boolean optional}
} read_aocv_table
echo "Defined procedure 'read_aocv_table'."


proc compare_aocv_csv { args } {
  set cargs(-file1) ""
  set cargs(-file2) ""
  set cargs(-percent) 3	
#set file1 [glob *.NT.POCV.csv]
#set file2 [glob *INV*load*.csv]
  parse_myproc_arguments -args $args cargs
set file1 [glob -nocomplain $cargs(-file1)]
set file2 [glob -nocomplain $cargs(-file2)] 
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
define_myproc_attributes -info "compare aocv +/-3sigma csv files" -define_args {
        { "-file1"          "csv1 file" "filename" string required}
        { "-file2"          "csv2 file" "filename" string required}
        { "-percent"          "percent comparison to trigger Error" "float" float optional}
} compare_aocv_csv
echo "Defined procedure 'compare_aocv_csv'."

proc calc_effective_sigma_from_variation { args } {
   set cargs(-csvfile)  ""
   set cargs(-outfile) ""
   set cargs(-depth) -1
   parse_myproc_arguments -args $args cargs
#	set file2 [glob *INV*load*.csv]
		set 3sigmax -1
		set 3sigmin -1
		set edge -1
		set mean -1
	set fin [open  "$cargs(-csvfile)" r]
	if { $cargs(-outfile) ne "" } {
		set fout [open $cargs(-outfile) w]
		puts $fout "INDEX,EDGE,MINSIG,MAXSIG"
	} else {
		puts "INDEX,EDGE,MINSIG,MAXSIG"
	}
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

		#puts "min3sig=$3sigmin  max3sig=$3sigmax"
		} elseif { [regexp "\[0-9\]+" $token] } {
			set index $token
			if { ($cargs(-depth) < 0) || ($cargs(-depth) == $index) } {
			set rf [lindex $tokens $edge]
			set maxsig [expr ([lindex $tokens $3sigmax] - [lindex $tokens $mean])/ [expr 3 * sqrt ( $index )]]
			set minsig [expr ([lindex $tokens $mean] - [lindex $tokens $3sigmin])/ [expr 3 * sqrt ( $index )]]
			if { $cargs(-outfile) ne "" } {
			puts $fout "$index,$rf,$minsig,$maxsig"
			} else {
			puts "$index,$rf,$minsig,$maxsig"
			}
			}
		} elseif { ($3sigmax > -1) || ($3sigmin > -1) || ($mean > -1) } {
			break
			close $fin
		}
	}
	if { $cargs(-outfile) ne "" } {
		close $fout
	}
}
define_myproc_attributes -info "calculate effective sigma per depth" -define_args {
        { "-csvfile"          "csv1 file" "filename" string required}
	{ "-depth "           "depth to calculate" "depth" int optional}
        { "-outfile"          "csv outfile" "filename" string optional}
} calc_effective_sigma_from_variation
echo "Defined procedure 'calc_effective_sigma_from_variation'"


#  store coeff by:  (min,max,type,tx_moyydel,length,voltage,width/nfin)

proc parse_set_variation_parameters { args } {
  set results(-array) ""
  set results(-data) ""
  parse_myproc_arguments -args $args results
  if { $results(-array) ne "" } {
	upvar 1 $results(-array) arr
  }
		set line [string trim $results(-data)]
		set tokens [snps_split $line ", \t"]
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
define_myproc_attributes -info "parse set_variation_parameters line" -define_args {
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

  parse_myproc_arguments -args $args cargs

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
  set files [snps_split [glob -nocomplain $cargs(-files)]] 
  } else  {
  if { [info exists files] } {
  unset files
  }
  }
  if { $cargs(-inv) ne "" } {
  if { ![info exist files] || ($files eq "")  } {
  set files [snps_split [glob -nocomplain $cargs(-inv)]]
  } else {
  lappend files [snps_split [glob -nocomplain $cargs(-inv)]]
  }
  }

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
		set tokens [snps_split $line ", \t"]
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
   if {$cargs(-nor2) ne ""} {
  foreach file [snps_split [glob -nocomplain $cargs(-nor2)]] {
     puts "Info: Parsing Nor2 variation coefficient file: $file"
     set fin [open  "$file" r]
        while {1} {
                set line [gets $fin]
                if {[eof $fin]} {
                        close $fin
                        break
                }
		set line [string trim $line]
		set tokens [snps_split $line ", \t"]
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
   }
   if {$cargs(-nor3) ne ""} {
  foreach file [snps_split [glob -nocomplain $cargs(-nor3)]] {
     puts "Info: Parsing Nor3 variation coefficient file: $file"
     set fin [open  "$file" r]
        while {1} {
                set line [gets $fin]
                if {[eof $fin]} {
                        close $fin
                        break
                }
		set line [string trim $line]
		set tokens [snps_split $line ", \t"]
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
   }
   if {$cargs(-nor4) ne ""} {
  foreach file [snps_split [glob -nocomplain $cargs(-nor4)]] {
     puts "Info: Parsing Nor4 variation coefficient file: $file"
     set fin [open  "$file" r]
        while {1} {
                set line [gets $fin]
                if {[eof $fin]} {
                        close $fin
                        break
                }
		set line [string trim $line]
		set tokens [snps_split $line ", \t"]
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
   }
   if {$cargs(-nor) ne ""} {
  foreach file [snps_split [glob -nocomplain $cargs(-nor)]] {
     puts "Info: Parsing Nor variation coefficient file: $file"
     set fin [open  "$file" r]
        while {1} {
                set line [gets $fin]
                if {[eof $fin]} {
                        close $fin
                        break
                }
		set line [string trim $line]
		set tokens [snps_split $line ", \t"]
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
   }
   if {$cargs(-nand2) ne ""} {
  foreach file [snps_split [glob -nocomplain $cargs(-nand2)]] {
     puts "Info: Parsing Nand2 variation coefficient file: $file"
     set fin [open  "$file" r]
        while {1} {
                set line [gets $fin]
                if {[eof $fin]} {
                        close $fin
                        break
                }
		set line [string trim $line]
		set tokens [snps_split $line ", \t"]
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
   }
   if {$cargs(-nand3) ne ""} {
  foreach file [snps_split [glob -nocomplain $cargs(-nand3)]] {
     puts "Info: Parsing Nand3 variation coefficient file: $file"
     set fin [open  "$file" r]
        while {1} {
                set line [gets $fin]
                if {[eof $fin]} {
                        close $fin
                        break
                }
		set line [string trim $line]
		set tokens [snps_split $line ", \t"]
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
   }
   if {$cargs(-nand4) ne ""} {
  foreach file [snps_split [glob -nocomplain $cargs(-nand4)]] {
     puts "Info: Parsing Nand4 variation coefficient file: $file"
     set fin [open  "$file" r]
        while {1} {
                set line [gets $fin]
                if {[eof $fin]} {
                        close $fin
                        break
                }
		set line [string trim $line]
		set tokens [snps_split $line ", \t"]
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
   }
   if {$cargs(-nand) ne ""} {
  foreach file [snps_split [glob -nocomplain $cargs(-nand)]] {
     puts "Info: Parsing Nand variation coefficient file: $file"
     set fin [open  "$file" r]
        while {1} {
                set line [gets $fin]
                if {[eof $fin]} {
                        close $fin
                        break
                }
		set line [string trim $line]
		set tokens [snps_split $line ", \t"]
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
   }
   puts "Info: Calculating coeff scale for -series2/-series3/-series4"
   foreach key [array names coeff_nand2] {
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
define_myproc_attributes -info "merge set_variation_parameter files" -define_args {
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



# nolint Line 4737: E Is array, was scalar
# nolint Line 9559: E Is scalar, was array