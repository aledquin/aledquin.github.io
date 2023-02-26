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


set VERSION 2.8

package require Tcl 8.4

if { [string compare [info proc define_myproc_attributes] ""] == 0 } {
proc define_myproc_attributes { args } {
	global __procs
	set i 0
	while { $i < [llength $args]} {
	if { [string compare [lindex $args $i] "-hidden"] == 0 } {
		set hidden 1	
	} elseif { [string compare [lindex $args $i] "-info"] == 0 } {
		incr i
		lappend cinfo [lindex $args $i]
	} elseif { [string compare [lindex $args $i] "-define_args"] == 0 } {
		incr i
		lappend cmd_args [lindex $args $i]
	} else {
		lappend proc [lindex $args $i]
	}
	incr i
	}
	if { [info exists proc] } {
		set proc [lindex $proc 0]
		if { [info exists cinfo] } {
			set __procs($proc,info) [lindex $cinfo 0]
		}
		if { [info exists hidden] } {
			set __procs($proc,hidden) 1
		} else {
			set __procs($proc,hidden) 0
		}
		if { [info exists cmd_args] } {	
			foreach carg [lindex $cmd_args 0] {
                if { [regexp -- "^\[ \t\]*(\[^ \t\]+)" $carg dum opt ] } {
                	regsub -- "^\[ \t\]*(\[^ \t\]+)" $carg {} carg
		}
		set opt [string trim $opt {\"}]
		if { [string compare [string range $opt 0 0] "-"] != 0 } {
			lappend __procs($proc,optorder) $opt
		}
                if { [regexp -- "^\[ \t\]*\[\"\](\[^\"\]+)\[\"\]" $carg dum info ] } {
                regsub -- "^\[ \t\]*\[\"\](\[^\"\]+)\[\"\]\[ \t\]*"  $carg {} carg
		} elseif { [regexp -- "^\[ \t\]*\{(\[^\{\}\]+)\}" $carg dum info ] } {
                regsub -- "^\[ \t\]*\{(\[^\{\}]+)\}\[ \t\]*" $carg {} carg
		} elseif { [regexp -- "^\[ \t\]*(\[^ \t\]+)" $carg dum info ] } {
                regsub -- "^\[ \t\]*(\[^ \t\]+)\[ \t\]*" $carg {} carg
		}
		set __procs($proc,opt,$opt,info) $info

                if { [regexp -- "^\[ \t\]*\[\"\](\[^\"\]+)\[\"\]" $carg dum arg ] } {
                regsub -- "^\[ \t\]*\[\"\](\[^\"\]+)\[\"\]\[ \t\]*" $carg {} carg
		} elseif { [regexp -- "^\[ \t\]*\{(\[^\{\}\]+)\}" $carg dum arg ] } {
                regsub -- "^\[ \t\]*\{(\[^\{\}\]+)\}\[ \t\]*" $carg {} carg
		} elseif { [regexp -- "^\[ \t\]*(\[^ \t\]+)" $carg dum arg ] } {
                regsub -- "^\[ \t\]*(\[^ \t\]+)\[ \t\]*" $carg {} carg
		}
		set __procs($proc,opt,$opt,arg) $arg

                if { [regexp -- "^\[ \t\]*\[\"\](\[^\"\]+)\[\"\]" $carg dum type ] } {
                regsub -- "^\[ \t\]*\[\"\](\[^\"\]+)\[\"\]\[ \t\]*" $carg {} carg
		} elseif { [regexp -- "^\[ \t\]*\{(\[^\{\}\]+)\}" $carg dum type ] } {
                regsub -- "^\[ \t\]*\{(\[^\{\}\]+)\}\[ \t\]*" $carg {} carg
		} elseif { [regexp -- "^\[ \t\]*(\[^ \t\]+)" $carg dum type ] } {
                regsub -- "^\[ \t\]*(\[^ \t\]+)\[ \t\]*" $carg {} carg
		}
		set __procs($proc,opt,$opt,type) $type

                if { [regexp -- "^\[ \t\]*\[\"\](\[^\"\]+)\[\"\]" $carg dum req] } {
                regsub -- "^\[ \t\]*\[\"\](\[^\"\]+)\[\"\]\[ \t\]*" $carg {} carg
		} elseif { [regexp -- "^\[ \t\]*\{(\[^\{\}\]+)\}" $carg dum req ] } {
                regsub -- "^\[ \t\]*\{(\[^\{\}\]+)\}\[ \t\]*" $carg {} carg
		} elseif { [regexp -- "^\[ \t\]*(\[^ \t\]+)" $carg dum req ] } {
                regsub -- "^\[ \t\]*(\[^ \t\]+)\[ \t\]*" $carg {} carg
		}
		set __procs($proc,opt,$opt,req) $req
			}
		}

	}
	proc __enter_$proc {args} { 
	global __procs
	set proc [lindex [lindex $args 0] 0]
	set __procs(__current_proc) $proc
	}
	uplevel #0 trace add execution $proc {enter} __enter_$proc
}
}


if { [string compare [info proc parse_myproc_arguments] ""] == 0 } {
proc parse_myproc_arguments { args } {
	global __procs
	set proc $__procs(__current_proc)
	regsub "^\[:\]*" $proc {} proc
	#puts "Parsing arguments of Proc: $proc -- $args"
	if { [regexp -- "-help" $args] } {
		if { ! $__procs($proc,hidden) } {
		puts "Usage:"
		puts " $proc       # $__procs($proc,info)" 
		foreach opt [keys __procs($proc,opt)] {
			if { $__procs($proc,opt,$opt,req) ne "hidden" } {
			puts "   \[$opt\]   \($__procs($proc,opt,$opt,info)\)"
			}
		}
		}
		return 0
	} else {
	if { [regexp -- "-debug" $args] } {
	#regsub -- "-debug\[ \]*" $args {} args
	puts "$proc: ARGS --> $args"
	}
	set i 0
	while { $i < [llength $args] } {
	if { [string compare [lindex $args $i] "-args"] == 0 } {
		incr i
		set myargs [lindex $args $i]
	} else {
		set opt [lindex $args $i]
		upvar [lindex $args $i] results
	}
	incr i
	}
	if { [array exists parsed_opts] } {
		array unset parsed_opts
	}
	foreach opt [keys __procs($proc,opt)] {
	if {[string compare $__procs($proc,opt,$opt,type) "boolean"] == 0 } {
		set results($opt) 0
	}
	}
	set i 0
	set index 0
	set opts ""

	foreach opt $myargs {
		set opt [string trim $opt]
		if { [regexp "^\-" $opt] } {
		append opts " $opt"
		} elseif { [regexp "^\{" $opt] && [regexp "\}$" $opt] } {
		if { [regexp -all "\{" $opt] > 1 } {
		append opts " \{$opt\}"
		} else {
		append opts " $opt"
		}
		} elseif { [regexp "^\"" $opt] && [regexp "\"$" $opt] } {
		append opts " \{$opt\}"
		} elseif { [regexp "^\"" $opt] && ([regexp -all "\"" $opt] == 1)} {
		append opts " \{$opt"
		} elseif { [regexp "\"$" $opt] && ([regexp -all "\"" $opt] == 1)} {
		append opts " $opt\}"
		} elseif { [regexp "\"" $opt] } {
		regsub -all "\"" $opt "\\\"" opt
		append opts " \{$opt\}"
		} elseif { [regexp "^\{" $opt] } {
		append opts " $opt"
		} elseif { [regexp "\}$" $opt] } {
		append opts " $opt"
		} else {
		append opts " \{$opt\}"
		}
	}
		while {$opts ne ""} {
		if { [regexp -- "^\[ \t\]+" $opts] } {
			regsub -- "^\[ \t\]+" $opts {} opts
		} elseif { [regexp -- "^(-\[^ \t\]+)" $opts dum opt] } {
			regsub -- "^(-\[^ \t\]+)\[ \t\]*" $opts {} opts
			if { ![defined __procs($proc,opt,$opt)] } {
				die "Error: invalid option $opt to proc: $proc"
			}
			if {[string compare $__procs($proc,opt,$opt,type) "boolean"] == 0 } {
			set results($opt) 1
			} elseif {[string compare $__procs($proc,opt,$opt,type) "int_list"] == 0 } {
			if { [regexp "^(\[\{ \t\]*\[0-9\]+\[ \t\}\]*)" $opts dum value] } {
			   while { [regexp "^(\[\{ \t\]*\[0-9\]+\[ \t\}\]*)" $opts dum value] } {
				set tmp $value	
				regsub -- "^\[\{ \t\]*(\[0-9\]+)\[ \t\}\]*" $opts {} opts
				while { ($opts ne "") && ($value ne "") && ([regexp -all "\{" $tmp] != [regexp -all "\}" $tmp]) } {
					regexp "^(\[^\}\]*\})" $opts dum value
					regsub -- "^\[^\}\]*\}" $opts {} opts
					append tmp "$value"
				} 
				while { [regexp -all "^\[ \t\]*\{\[^\}\]+\}\[ \t\]*$" $tmp] } {
					set tmp [string trim $tmp "\{\} \t"]
				}
				set tmp [string trim $tmp]
				foreach item [split_to_list $tmp] {
			if { [defined parsed_opts] && ([lsearch -exact $parsed_opts $opt] != -1) } {
			lappend results($opt) $item
			} else {
			lappend results($opt) {}
			lappend results($opt) $item
			lappend parsed_opts $opt
			}
				}
			    }
			} else {
			die "Error: cmd line value for option $opt not of type int"	
			}
				
			} elseif {[string compare $__procs($proc,opt,$opt,type) "int"] == 0 } {
			if { [regexp "^(\[\{ \t\]*\[0-9\]+\[ \t\}\]*)" $opts dum value] } {
				set tmp $value	
				regsub -- "^\[\{ \t\]*(\[0-9\]+)\[ \t\}\]*" $opts {} opts
				while { ($opts ne "") && ($value ne "") && ([regexp -all "\{" $tmp] != [regexp -all "\}" $tmp]) } {
					regexp "^(\[^\}\]*\})" $opts dum value
					regsub -- "^\[^\}\]*\}" $opts {} opts
					append tmp "$value"
				} 
				while { [regexp -all "^\[ \t\]*\{\[^\}\]+\}\[ \t\]*$" $tmp] } {
					set tmp [string trim $tmp "\{\} \t"]
				}
				set tmp [string trim $tmp]
			if { [defined parsed_opts] && ([lsearch -exact $parsed_opts $opt] != -1) } {
			set results($opt) $tmp
			} else {
			set results($opt) $tmp
			lappend parsed_opts $opt
			}
			} else {
			die "Error: cmd line value for option $opt not of type int"	
			}
			} elseif {[string compare $__procs($proc,opt,$opt,type) "float_list"] == 0 } {
			if  { [regexp "^(\[\{ \t\]*\[\-\+\]*\[\.0-9\]+\[ \t\}\]*)" $opts dum value] } {
			    while { [regexp "^(\[\{ \t\]*\[\-\+\]*\[\.0-9\]+\[ \t\}\]*)" $opts dum value] } {
				set tmp $value	
				regsub -- "^\[\{ \t\]*\[\-\+\]*\[\.0-9\]+\[ \t\}\]*" $opts {} opts
				while { ($opts ne "") && ($value ne "") && ([regexp -all "\{" $tmp] != [regexp -all "\}" $tmp]) } {
					regexp "^(\[^\}\]*\})" $opts dum value
					regsub -- "^\[^\}\]*\}" $opts {} opts
					append tmp " $value"
				} 
				while { [regexp -all "^\[ \t\]*\{\[^\}\]+\}\[ \t\]*$" $tmp] } {
					set tmp [string trim $tmp "\{\} \t"]
				}
				set tmp [string trim $tmp]
				foreach item [split_to_list $tmp] {
			if { [defined parsed_opts] && ([lsearch -exact $parsed_opts $opt] != -1)} {
			lappend results($opt) $item
			} else {
			set results($opt) {}
			lappend results($opt) $item
			lappend parsed_opts $opt
			}
				}
			   }
			} else {
			die "Error: cmd line value for option $opt not of type float"	
			}
			} elseif {[string compare $__procs($proc,opt,$opt,type) "float"] == 0 } {
			if { [regexp "^(\[\{ \t\]*\[\-\+\]*\[\.0-9\]+\[ \t\}\]*)" $opts dum value] } {
				set tmp $value	
				regsub -- "^\[\{ \t\]*\[\-\+\]*\[\.0-9\]+\[ \t\}\]*" $opts {} opts
				while { ($opts ne "") && ($value ne "") && ([regexp -all "\{" $tmp] != [regexp -all "\}" $tmp]) } {
					regexp "^(\[^\}\]*\})" $opts dum value
					regsub -- "^\[^\}\]*\}" $opts {} opts
					append tmp "$value"
				} 
				while { [regexp -all "^\[ \t\]*\{\[^\}\]+\}\[ \t\]*$" $tmp] } {
					set tmp [string trim $tmp "\{\} \t"]
				}
				set tmp [string trim $tmp]
			if { [defined parsed_opts] && ([lsearch -exact $parsed_opts $opt] != -1)} {
			set results($opt) $tmp
			} else {
			set results($opt) $tmp
			lappend parsed_opts $opt
			}
			} else {
			die "Error: cmd line value for option $opt not of type float"	
			}
			} elseif {[string compare $__procs($proc,opt,$opt,type) "string_list"] == 0 } {
			if { [regexp -- "^\"(\[^\"\]+)\"" $opts dum value] } {
			#set tmp [list "$value"]
			set tmp $value
			regsub -- "^\"(\[^\"\]+)\"\[ \t]*" $opts {} opts 
			if { [defined parsed_opts] && ([lsearch -exact $parsed_opts $opt] != -1)} {
			lappend results($opt) $tmp
			} else {
			set results($opt) {}
			lappend results($opt) $tmp
			lappend parsed_opts $opt
			}
			} elseif { [regexp -- "^(\{\[^\}\]+\})" $opts dum value] } {
			#set tmp [list "$value"]
			   while  { [regexp -- "^(\{\[^\}\]+\})" $opts dum value] } {
				set tmp $value	
				regsub -- "^\{\[^\}\]+\}\[ \t\]*" $opts {} opts
				while { ($opts ne "") && ($value ne "") && ([regexp -all "\{" $tmp] != [regexp -all "\}" $tmp]) } {
					regexp "^(\[^\}\]*\})" $opts dum value
					regsub -- "^\[^\}\]*\}" $opts {} opts
					append tmp "$value"
				} 
				while { [regexp -all "^\[ \t\]*\{\[^\}\]+\}\[ \t\]*$" $tmp] } {
					set tmp [string trim $tmp "\{\} \t"]
				}
				set tmp [string trim $tmp]
			if { [defined parsed_opts] && ([lsearch -exact $parsed_opts $opt] != -1) } {
			lappend results($opt) $tmp
			} else {
			set results($opt) {}
			lappend results($opt) $tmp
			lappend parsed_opts $opt
			}
			     }
			} elseif { [regexp -- "^(\[^ \t\]+)" $opts dum value]} {
			regsub -- "^\[^ \t\]+\[ \t]*" $opts {} opts
			if { [defined parsed_opts] && ([lsearch -exact $parsed_opts $opt] != -1) } {
			lappend results($opt) $value
			} else {
			set results($opt) {}
			lappend results($opt) $value
			lappend parsed_opts $opt
			}
			}
			} elseif {[string compare $__procs($proc,opt,$opt,type) "string"] == 0 } {
			if { [regexp -- "^\"(\[^\"\]+)\"" $opts dum value] } {
			#set tmp [list "$value"]
			set tmp $value
			regsub -- "^\"(\[^\"\]+)\"\[ \t]*" $opts {} opts 
			if { [defined parsed_opts] && ([lsearch -exact $parsed_opts $opt] != -1)} {
		        set results($opt) $tmp
			} else {
			set results($opt) $tmp
			lappend parsed_opts $opt
			}
			} elseif { [regexp -- "^(\{\[^\}\]+\})" $opts dum value] } {
			#set tmp [list "$value"]
				set tmp $value	
				regsub -- "^\{\[^\}\]+\}" $opts {} opts
				while { ($opts ne "") && ($value ne "") && ([regexp -all "\{" $tmp] != [regexp -all "\}" $tmp]) } {
					regexp "^(\[^\}\]*\})" $opts dum value
					regsub -- "^\[^\}\]*\}" $opts {} opts
					append tmp "$value"
				} 
				while { [regexp -all "^\[ \t\]*\{\[^\}\]+\}\[ \t\]*$" $tmp] } {
					set tmp [string trim $tmp "\{\} \t"]
				}
				set tmp [string trim $tmp]
			if { [defined parsed_opts] && ([lsearch -exact $parsed_opts $opt] != -1) } {
			set results($opt) $tmp
			} else {
			set results($opt) $tmp
			lappend parsed_opts $opt
			}
			} elseif { [regexp -- "^(\[^ \t\]+)" $opts dum value]} {
			regsub -- "^\[^ \t\]+\[ \t]*" $opts {} opts
			if { [defined parsed_opts] && ([lsearch -exact $parsed_opts $opt] != -1) } {
			set results($opt) $value
			} else {
			set results($opt) $value
			lappend parsed_opts $opt
			}
			}
			} 
		} elseif { [regexp "^\[ \t\]*\{\[ \t\]*\}" $opts] } {
			regsub "^\[ \t\]*\{\[ \t\]*\}" $opts {} opts
		} elseif { [regexp "^\[ \t\]*\[^ \t\]+" $opts] } {
			if { [defined __procs($proc,optorder)]  && ($index < [llength $__procs($proc,optorder)])} {
			set opt [lindex $__procs($proc,optorder) $index]
			incr index
			## need to check if it is boolean ##
			if {[string compare $__procs($proc,opt,$opt,type) "boolean"] == 0 } {
			set results($opt) 1
			} elseif {[string compare $__procs($proc,opt,$opt,type) "int_list"] == 0 } {
			if { [regexp "^(\[\{ \t\]*\[0-9\]+\[ \t\}\]*)" $opts dum value] } {
			   while { [regexp "^(\[\{ \t\]*\[0-9\]+\[ \t\}\]*)" $opts dum value] } {
				set tmp $value	
				regsub -- "^\[\{ \t\]*\[0-9\]+\[ \t\}\]*" $opts {} opts
				while { ($opts ne "") && ($value ne "") && ([regexp -all "\{" $tmp] != [regexp -all "\}" $tmp]) } {
					regexp "^(\[^\}\]*\})" $opts dum value
					regsub -- "^\[^\}\]*\}" $opts {} opts
					append tmp "$value"
				} 
				while { [regexp -all "^\[ \t\]*\{\[^\}\]+\}\[ \t\]*$" $tmp] } {
					set tmp [string trim $tmp "\{\} \t"]
				}
				set tmp [string trim $tmp]
				foreach item [split_to_list $tmp] {
			if { [defined parsed_opts] && ([lsearch -exact $parsed_opts $opt] != -1) } {
			lappend results($opt) $item
			} else {
			set results($opt) {}
			lappend results($opt) $item
			lappend parsed_opts $opt
			}
				}
			    }
			} else {
			die "Error: cmd line value for option $opt not of type int"	
			}
			} elseif {[string compare $__procs($proc,opt,$opt,type) "int"] == 0 } {
			if { [regexp "^(\[\{ \t\]*\[0-9\]+\[ \t\}\]*)" $opts dum value] } {
				set tmp $value	
				regsub -- "^\[\{ \t\]*\[0-9\]+\[ \t\}\]*" $opts {} opts
				while { ($opts ne "") && ($value ne "") && ([regexp -all "\{" $tmp] != [regexp -all "\}" $tmp]) } {
					regexp "^(\[^\}\]*\})" $opts dum value
					regsub -- "^\[^\}\]*\}" $opts {} opts
					append tmp "$value"
				} 
				while { [regexp -all "^\[ \t\]*\{\[^\}\]+\}\[ \t\]*$" $tmp] } {
					set tmp [string trim $tmp "\{\} \t"]
				}
				set tmp [string trim $tmp]
			if { [defined parsed_opts] && ([lsearch -exact $parsed_opts $opt] != -1) } {
			set results($opt) $tmp
			} else {
			set results($opt) $tmp
			lappend parsed_opts $opt
			}
			} else {
			die "Error: cmd line value for option $opt not of type int"	
			}
			} elseif {[string compare $__procs($proc,opt,$opt,type) "float_list"] == 0 } {
			if { [regexp "^(\[\{ \t\]*\[\-\+\]*\[\.0-9\]+\[ \t\}\]*)" $opts dum value] } {
			   while {[regexp "^(\[\{ \t\]*\[\-\+\]*\[\.0-9\]+\[ \t\}\]*)" $opts dum value] } {
				set tmp $value	
				regsub -- "^\[\{ \t\]*\[\-\+\]*\[\.0-9\]+\[ \t\}\]*" $opts {} opts
				while { ($opts ne "") && ($value ne "") && ([regexp -all "\{" $tmp] != [regexp -all "\}" $tmp]) } {
					regexp "^(\[^\}\]*\})" $opts dum value
					regsub -- "^\[^\}\]*\}" $opts {} opts
					append tmp "$value"
				} 
				while { [regexp -all "^\[ \t\]*\{\[^\}\]+\}\[ \t\]*$" $tmp] } {
					set tmp [string trim $tmp "\{\} \t"]
				}
				set tmp [string trim $tmp]
				foreach item [split_to_list $tmp] {
			if { [defined parsed_opts] && ([lsearch -exact $parsed_opts $opt] != -1) } {
			lappend results($opt) $item
			} else {
			set results($opt) {}
			lappend results($opt) $item
			lappend parsed_opts $opt
			}	
				}
			    }
			} else {
			die "Error: cmd line value for option $opt not of type float"	
			}
			} elseif {[string compare $__procs($proc,opt,$opt,type) "float"] == 0 } {
			if { [regexp "^(\[\{ \t\]*\[\-\+\]*\[\.0-9\]+\[ \t\}\]*)" $opts dum value] } {
				set tmp $value	
				regsub -- "^\[\{ \t\]*\[\-\+\]*\[\.0-9\]+\[ \t\}\]*" $opts {} opts
				while { ($opts ne "") && ($value ne "") && ([regexp -all "\{" $tmp] != [regexp -all "\}" $tmp]) } {
					regexp "^(\[^\}\]*\})" $opts dum value
					regsub -- "^\[^\}\]*\}" $opts {} opts
					append tmp "$value"
				} 
				while { [regexp -all "^\[ \t\]*\{\[^\}\]+\}\[ \t\]*$" $tmp] } {
					set tmp [string trim $tmp "\{\} \t"]
				}
				set tmp [string trim $tmp]
			if { [defined parsed_opts] && ([lsearch -exact $parsed_opts $opt] != -1) } {
			set results($opt) $tmp
			} else {
			set results($opt) $tmp
			lappend parsed_opts $opt
			}
			} else {
			die "Error: cmd line value for option $opt not of type float"	
			}
			} elseif {[string compare $__procs($proc,opt,$opt,type) "string_list"] == 0 } {
			if { [regexp -- "^\"(\[^\"\]+)\"" $opts dum value] } {
			#set tmp [list "$value"]
			set tmp $value
			regsub -- "^\"(\[^\"\]+)\"" $opts {} opts
			if { [defined parsed_opts] && ([lsearch -exact $parsed_opts $opt] != -1) } {
			lappend results($opt) $tmp
			} else {
			set results($opt) {}
			lappend results($opt) $tmp
			lappend parsed_opts $opt
			}
			} elseif { [regexp -- "^(\{\[^\}\]+\})" $opts dum value] } {
			#set tmp [list "$value"]
			    while { [regexp -- "^(\{\[^\}\]+\})" $opts dum value] } {
				set tmp $value	
				regsub -- "^\{\[^\}\]+\}" $opts {} opts
				while { ($opts ne "") && ($value ne "") && ([regexp -all "\{" $tmp] != [regexp -all "\}" $tmp]) } {
					regexp "^(\[^\}\]*\})" $opts dum value
					regsub -- "^\[^\}\]*\}" $opts {} opts
					append tmp "$value"
				} 
				while { [regexp -all "^\[ \t\]*\{\[^\}\]+\}\[ \t\]*$" $tmp] } {
					set tmp [string trim $tmp "\{\} \t"]
				}
				set tmp [string trim $tmp]
			if { [defined parsed_opts] && ([lsearch -exact $parsed_opts $opt] != -1 ) } {
			lappend results($opt) $tmp
			} else {
			set results($opt) {}
			lappend results($opt) $tmp
			lappend parsed_opts $opt
			}
			    }
			} elseif { [regexp -- "^(\[^ \t\]+)" $opts dum value]} {
			regsub -- "^\[^ \t\]+\[ \t]*" $opts {} opts
			if { [defined parsed_opts] && ([lsearch -exact $parsed_opts $opt] != -1 ) } {
			lappend results($opt) $value
			} else {
			set results($opt) {}
			lappend results($opt) $value
			lappend parsed_opts $opt
			}
			}
			} elseif {[string compare $__procs($proc,opt,$opt,type) "string"] == 0 } {
			if { [regexp -- "^\"(\[^\"\]+)\"" $opts dum value] } {
			#set tmp [list "$value"]
			set tmp $value
			regsub -- "^\"(\[^\"\]+)\"" $opts {} opts
			if { [defined parsed_opts] && ([lsearch -exact $parsed_opts $opt] != -1) } {
			set results($opt) $tmp
			} else {
			set results($opt) $tmp
			lappend parsed_opts $opt
			}
			} elseif { [regexp -- "^(\{\[^\}\]+\})" $opts dum value] } {
			#set tmp [list "$value"]
				set tmp $value	
				regsub -- "^\{\[^\}\]+\}" $opts {} opts
				while { ($opts ne "") && ($value ne "") && ([regexp -all "\{" $tmp] != [regexp -all "\}" $tmp]) } {
					regexp "^(\[^\}\]*\})" $opts dum value
					regsub -- "^\[^\}\]*\}" $opts {} opts
					append tmp "$value"
				} 
				while { [regexp -all "^\[ \t\]*\{\[^\}\]+\}\[ \t\]*$" $tmp] } {
					set tmp [string trim $tmp "\{\} \t"]
				}
				set tmp [string trim $tmp]
			if { [defined parsed_opts] && ([lsearch -exact $parsed_opts $opt] != -1 ) } {
			set results($opt) $tmp
			} else {
			set results($opt) $tmp
			lappend parsed_opts $opt
			}
			} elseif { [regexp -- "^(\[^ \t\]+)" $opts dum value]} {
			regsub -- "^\[^ \t\]+\[ \t]*" $opts {} opts
			if { [defined parsed_opts] && ([lsearch -exact $parsed_opts $opt] != -1 ) } {
			set results($opt) $value
			} else {
			set results($opt) $value
			lappend parsed_opts $opt
			}
			}
			} else {
				#parray __procs "$proc,*"
				die "Error: Proc: $proc has unknown cmd line option(s): $opts"
			}
		        } else {
				die "Error: Proc: $proc has unknown cmd line options: $opts"
			}
		} else {
			break
		}
		}
	}
}
}

if { [string compare [info proc help] ""] == 0 } {
proc help { args } {
	global __procs
	set i 0
	set verbose 0
	if { [llength $args] > 0 } {
	while { $i < [llength $args]} {	
		if { [regexp -- "-v" [lindex $args $i]] } {
			set verbose 1
		} else {
			lappend cmds [lindex $args $i]	
		}
		incr i
	}
	foreach cmd $cmds {
		set cmd [string trim $cmd ":"]
		foreach mcmd [array names __procs "${cmd},info"] {
		regsub ",info$" $mcmd {} mcmd
		if { !$__procs(${mcmd},hidden) } {
		puts " $mcmd       # $__procs($mcmd,info)" 
		if { [info exists __procs(${mcmd},info)] } {
			if { $verbose } {
		foreach opt [keys __procs($mcmd,opt)] {
			if { $__procs($mcmd,opt,$opt,req) ne "hidden" } {
			puts "   \[$opt\]   \($__procs($mcmd,opt,$opt,info)\)"
			}
		}
			} else { 
				echo " $mcmd \t# $__procs(${mcmd},info)"
			}
		} else {
			echo " $mcmd \# TCL builtin"
		}
		} else {
			echo " $mcmd \# hidden"
		}
		}
	}
	}
}
}

if { [string compare [info proc quit] ""] == 0 } {
proc quit { args } {
	exit
}
}


## (keys %{$cell_data{cell}{"$cell"}{"inputs"} }

proc keys { args } {
# return a list of keys that match for that array, based on the
set array_name_regexp "^ \t\)\("
set space " \t"
set args [string trim [join $args]]
set debug 0
set nocase 0
if  { [regexp -- "^\[ \t\]*-debug" $args] } {
 regsub -- "-debug" $args {} args
 set debug 1
}
if  { [regexp -- "^\[ \t\]*-nocase" $args] } {
 regsub -- "-nocase" $args {} args
 set nocase 1
}
regexp "^\[$space\]*(\[$array_name_regexp\]+)\[\(\]*(\[$array_name_regexp\]*)\[\)\]*" $args dum name key
if { [info exists name] && ($name ne "") } {
upvar $name array_name
} else {
	return
}
	#regsub "\[\*\]" $key {\\*} key
if { [array exists array_name] } {
	foreach item [array names array_name] {
	set match ""
        if { $nocase } {
	regexp -nocase -- "^${key}\[,\](\[^,\]+)" $item dum match
	} else {
	regexp "^${key}\[,\](\[^,\]+)" $item dum match
	}
	if { ([info exists match]) && ([string compare $match ""] != 0)} {
	lappend key_list $match
	}
	} 
	if {[info exists key_list]} {
	set key_list [lsort -unique $key_list]
	return [lsort -unique $key_list]
	} else {
		return
	}
} else {
	return
}
}

proc pop { args } {
set array_name_regexp "^ \t\)\("
set space " \t"
# find the array name
regexp "^\[$space\]*(\[$array_name_regexp\]+)\[\(\]*(\[$array_name_regexp\]*)\[\)\]*" $args dum name key
upvar $name array_name
regsub "^\[$space\]*\[$array_name_regexp\]+\[\(\]*(\[$array_name_regexp\]+)\[\)\]*" $args {} value
if { [array exists array_name] } {
	regsub "\[\*\]" $key {\\*} key
	foreach item [array names array_name] {
	set match ""
	regexp "^${key},*(\[0-9\]+)" $item dum match
	if { ([info exists match]) && ([string compare $match ""] != 0)} {
	lappend key_list $match
	}
	}
	if {[info exists key_list]} {
	set key_list [lsort -unique $key_list]
	set key_length [expr [llength $key_list] - 1]
	if { [string compare $key ""] != 0 } {
	set value $array_name($key,$key_length)
	array unset array_name "$key,$key_length"
	} else {
	set value $array_name($key_length)
	array unset array_name "$key_length"
	}
	return $value
	} else {
	 	return 
	}
} else {
	return 
}
}

proc push { args } {
# add a value to an array
set array_name_regexp "^ \t\)\("
set space " \t"
# find the array name
regexp "^\[$space\]*(\[$array_name_regexp\]+)\[\(\]*(\[$array_name_regexp\]*)\[\)\]*" $args dum name key
upvar $name array_name
regsub "^\[$space\]*\[$array_name_regexp\]+\[\(\]*(\[$array_name_regexp\]+)\[\)\]*" $args {} value
if { [array exists array_name] } {
	regsub "\[\*\]" $key {\\*} key
	foreach item [array names array_name] {
	regexp "^$key\[,\]*(\[0-9\]+)" $item dum match
	if { ([info exists match]) && ([string compare $match ""] != 0)} {
	lappend key_list $match
	}
	}
	if {[info exists key_list]} {
	set key_list [lsort -unique $key_list]
	set key_length [llength $key_list]
	if { [string compare $key ""] != 0 } {
	set array_name($key,$key_length) $value
	} else {
	set array_name($key_length) $value
	}
	} else {
	if { [string compare $key ""] != 0 } {
	set array_name($key,0) $value
	} else {
	set array_name(0) $value
	}
	}
} else {
	set array_name(0) $value
}
}

proc echo {args} {	
	puts [lindex $args 0]
}

proc print {args} {	
	regsub "\\n\"$" $args {\"} args
	if { [regexp "^\[ \t\]*(\[^ \t\$\"\]+)" $args dum file] } {
		upvar $file fout
		regsub "^\[ \t\]*\[^ \t\$\"\]+" $args {} args
	}
	if {([info exist fout]) && ([string compare $fout ""] != 0)} {
	puts $fout $args 
	} else {
	puts $args
	}
}

proc undef {args} {
  upvar $args var
  if { [array exists var] } {
	array unset var
  } elseif { [info exists var] } {
	unset var
  }
}

proc die {args} {
	puts [lindex $args 0]
	exit
}

proc decr {args} {
  upvar $args var
  set var [expr $var - 1]
}

proc array_get { args } {
set array_name_regexp "^ \t\)\("
set nocase 0
set args [string trim [join $args]]
if  { [regexp -- "\[^,\(\)\]+-nocase\[^,\(\)\]*" $args] } {
 regsub -- "\[^,\(\)\]+-nocase\[^,\(\)\]*" $args {\1\2} args
 set nocase 1
} elseif  { [regexp -- "^\[ \t\]*-nocase" $args] } {
 regsub -- "^\[ \t\]*-nocase" $args {} args 
 set nocase 1
}
set args [string trim $args]
regexp "^(\[$array_name_regexp\]+)\[\(\]*(\[$array_name_regexp\]*)\[\)\]*\[ \t\]*" $args dum name key1
if { [info exists name] && ($name ne "") } {
upvar $name array_name
} else {
	return 0
}
if { [info exists array_name] } {
	if { [info exists key1] && ($key1 ne "")} {
		foreach key [array names array_name] { 
	if { $nocase } {
	if { [string tolower $key1] eq [string tolower [regsub "\[\*\]" $key {\\*}]] } {
			return $array_name($key)
	}
 	} else {
	if {  $key1 eq $key } {
			return $array_name($key)
 	}	
	}
		}
		return ""
	} else {
		return ""
	}
} else {
	return ""
}
}

proc defined { args } {
set array_name_regexp "^ \t\)\("
set debug 0
set nocase 0
# find the array name
#puts [time {
set args [string trim [join $args]]
if  { [regexp -- "\[^,\(\)\]+-debug\[^,\(\)\]*" $args] } {
 regsub -- "(\[^,\(\)\]+)-debug(\[^,\(\)\]*)" $args {\1\2} args
 set debug 1
} elseif  { [regexp -- "^\[ \t\]*-debug" $args] } {
 regsub -- "^\[ \t\]*-debug" $args {} args 
 set debug 1
}
if  { [regexp -- "\[^,\(\)\]+-nocase\[^,\(\)\]*" $args] } {
 regsub -- "\[^,\(\)\]+-nocase\[^,\(\)\]*" $args {\1\2} args
 set nocase 1
} elseif  { [regexp -- "^\[ \t\]*-nocase" $args] } {
 regsub -- "^\[ \t\]*-nocase" $args {} args 
 set nocase 1
}


set args [string trim $args]
regexp "^(\[$array_name_regexp\]+)\[\(\]*(\[$array_name_regexp\]*)\[\)\]*\[ \t\]*" $args dum name key1
if { [info exists name] && ($name ne "") } {
upvar $name array_name
} else {
	return 0
}

	#regsub "\[\*\]" $key1 {\\*} key1
if { [info exists array_name] } {
	if { [info exists key1] && ($key1 ne "")} {
		foreach key [array names array_name] { 
if { $debug } {
	puts "NAME: $name KEY: $key1 KEY: $key"
}
	#regsub "\[\*\]" $key {\\*} key
	if { $nocase } {
	if { [string tolower $key1] eq [string tolower [regsub "\[\*\]" $key {\\*}]] } {
			return 1
	} elseif {[regexp -nocase -- "^${key1}\[,\]\[^,\]+\[,\]" $key] } {
				return 1
	} elseif {[regexp -nocase -- "^${key1}\[,\]\[^,\]+$" $key] } {
				return 1
	}
 	} else {
	if { $key1 eq $key } {
			return 1
	} elseif {[regexp -- "^${key1}\[,\]\[^,\]+\[,\]" $key] } {
				return 1
	} elseif {[regexp -- "^${key1}\[,\]\[^,\]+$" $key] } {
				return 1
	}
	}
		}
		return 0
	} else {
	return 1
	}
} else {
	return 0
}
#}]
}

proc lremove {listName what} {
    upvar 1 $listName list
    set pos  [lsearch $list $what]
    set list [lreplace $list $pos $pos]
}

if { [string compare [info proc syn_split] ""] == 0 } {
proc syn_split { args } {
  set cargs(splitChars) " \t\n"
  parse_myproc_arguments -args $args cargs
  set cargs(str) [string trim $cargs(str) $cargs(splitChars)]
  set cargs(str) [string trim $cargs(str) "\}\{"]
  regsub -all \[$cargs(splitChars)\]+ $cargs(str) { }
  return [split $cargs(str)]
}
define_myproc_attributes -info "split on multi slitChars" -define_args {
        { "str"         "string" "string" string required}
        { "splitChars"          "splitChars" "string" string optional}
} syn_split
echo "Defined procedure 'syn_split'."
}

if { [string compare [info proc lsearch_index] ""] == 0 } {
proc lsearch_index { args } {
	set cargs(list) ""
	set cargs(pattern) ""
	set cargs(-index) ""
	set cargs(-all) 0
	set cargs(-exact) 0
	set cargs(-inline) 0
	set cargs(-start) ""
        parse_myproc_arguments -args $args cargs
	upvar $cargs(list) list
	if { ![info exists list] } {
		echo "Error: list $cargs(list) does not exist"
		return	
	}
	foreach item [list all exact inline] {
		if { $cargs(-$item) } {
		append larg " -$item"
		}
	}
	foreach item [list start] {
		if { [string compare $cargs(-$item) ""] != 0 } {
			append larg " -start $cargs(-$item)"
		}
	}
	set returnv ""
	if { [string compare $cargs(-index) ""] != 0  } {
		set index 0
		foreach item $list {
			set tmp [eval lsearch $larg [list [lindex $item $cargs(-index)]] $cargs(pattern)]
			if { [string compare $tmp ""] != 0 } {
				if {$cargs(-inline) }  {
					lappend returnv $item
				} else {
					lappend returnv $index
					if { !$cargs(-all) } {
						break
					}
				}
			}
			incr index
		}
		if { [string compare $returnv  ""] == 0 } {
			return -1
		} else {
			return  $returnv
		}
	} else {
		return [eval lsearch $larg $list $cargs(pattern)]
	}
}
define_myproc_attributes -info "lsearch with -index/-indices as in tcl8.5a1" -define_args {
        { "-inline"          "inline" "" boolean optional}
        { "-all"          "all" "" boolean optional}
        { "-exact"          "exact" "" boolean optional}
        { "-start"          "exact" "integer" int optional}
        { "-index"          "index of sublist" "int" int optional}
        { "list"         "list" "list" string required}
        { "pattern"         "pattern" "pattern" string required}
} lsearch_index
echo "Defined procedure 'lsearch_index'."
}

if { [string compare [info proc string_equal] ""] == 0 } {
proc string_equal  { args } {
 global __procs
 set cargs(-nocase) 0
 set cargs(-notrim) 0
 set cargs(string1) ""
 set cargs(string2) ""
 if { [parse_myproc_arguments -args $args cargs] eq "0" } {
		return 0
 }
 if { !$cargs(-nocase)} {
	set cargs(string1) [string tolower $cargs(string1)]
	set cargs(string2) [string tolower $cargs(string2)]
 } 
 if { !$cargs(-notrim)} {
	regsub "^\[ \"\{\t\]*" $cargs(string1) {} cargs(string1)
	regsub "^\[ \"\{\t\]*" $cargs(string2) {} cargs(string2)
	regsub "\[ \"\}\t\]*$" $cargs(string1) {} cargs(string1)
	regsub "\[ \"\}\t\]*$" $cargs(string2) {} cargs(string2)
 }
if { ($cargs(string1) eq $cargs(string2)) } {
	return 1
} else {
	return 0
}
}
define_myproc_attributes string_equal \
 -info " compare if two strings equal" \
 -define_args { \
	{ "-nocase"       "no case" "" boolean optional}
	{ "-notrim"       "no trim" "" boolean optional}
        { "string1"         "string2" "string" string required}
        { "string2"         "string1" "string" string required}
}
}

proc split_to_list { args } {
return [split [regsub -all "\[ \t\]+" [string trim [string tolower [join $args]]] { }]] 
}


if { [string compare [info proc lsearch_nocase] ""] == 0 } {
proc lsearch_nocase { args } {
	global __procs
	set results(list) ""
	set results(pattern) ""
	set results(-index) ""	
	set results(-nocase) 0
	set results(-all) 0
	set results(-exact) 0
	set results(-inline) 0
	set results(-start) ""

        parse_myproc_arguments -args $args results

	upvar $results(list) mylist
	if { ![info exists mylist] } {
		echo "Error: list $results(list) does not exist"
		return	
	}
	foreach item [list all exact inline] {
		if { $results(-$item) } {
		append larg " -$item"
		}
	}
	foreach item [list start] {
		if { [string compare $results(-$item) ""] != 0 } {
			append larg " -start $results(-$item)"
		}
	}
	set returnv ""
	if { [string compare $results(-nocase) ""] != 0 } {
		foreach key1 $mylist {
			lappend tmplist [string tolower $key1]
		}
		set results(pattern) [string tolower $results(pattern)]
	} else {
		set tmplist $mylist
	}
	if { [string compare $results(-index) ""] != 0  } {
		set index 0
		foreach item $tmplist {
			set tmp [eval lsearch $larg [list [lindex $item $results(-index)]] $results(pattern)]
			if { [string compare $tmp ""] != 0 } {
				if {$results(-inline) }  {
					lappend returnv $item
				} else {
					lappend returnv $index
					if { !$results(-all) } {
						break
					}
				}
			}
			incr index
		}
		if { [string compare $returnv  ""] == 0 } {
			return -1
		} else {
			return  $returnv
		}
	} else {
		if { $results(-inline) } {
			set index_list [lsearch $larg $tmplist $results(pattern)]
			if { $index_list ne -1 }  {
			foreach index $index_list {
			return [eval lsearch $larg $tmplist $results(pattern)]
			}
			} else {
			return -1
			}
		} else {
			
			return [eval lsearch $larg [list $tmplist] $results(pattern)]
		}
	}
}
define_myproc_attributes \
-info "lsearch with -index/-indices & -nocase as in tcl8.5a1" \
-define_args {
        { "-inline"       "inline" "" boolean optional}
        { "-all"          "all" "" boolean optional}
        { "-exact"          "exact" "" boolean optional}
        { "-nocase"          "case insensitive" "" boolean optional}
        { "-start"          "start index" "integer" int optional}
        { "-index"          "index of sublist" "int" int optional}
        { "list"         "list" "list" string required}
        { "pattern"         "pattern" "pattern" string required}
} lsearch_nocase
echo "Defined procedure 'lsearch_nocase'."
}

## regexp syntaxes ##
## space \[ \t\] \s=[\[ \t\]] \S(not a space)=[![:space]] ##
## blank [:blank:]  ##
## alpha [:alpha:] ##
## digit [:digit:]  \d  \D(not a digit) ##
## alnum [:alnum:] \w [[:alnum]_] \W(not a alnum) ##
## nongreedy: \(.+?) and (.*?)  default is greedy ##


# nolint Line 228: E Is scalar, was array
# nolint Line 254: E Is scalar, was array
# nolint Line 278: E Is scalar, was array
# nolint Line 303: E Is scalar, was array
# nolint Line 317: E Is scalar, was array
# nolint Line 338: E Is scalar, was array
# nolint Line 348: E Is scalar, was array
# nolint Line 361: E Is scalar, was array
# nolint Line 380: E Is scalar, was array
# nolint Line 388: E Is scalar, was array
# nolint Line 420: E Is scalar, was array
# nolint Line 445: E Is scalar, was array
# nolint Line 469: E Is scalar, was array
# nolint Line 494: E Is scalar, was array
# nolint Line 508: E Is scalar, was array
# nolint Line 529: E Is scalar, was array
# nolint Line 539: E Is scalar, was array
# nolint Line 552: E Is scalar, was array
# nolint Line 571: E Is scalar, was array
# nolint Line 579: E Is scalar, was array
# nolint Line 1098: E Wrong number of arguments