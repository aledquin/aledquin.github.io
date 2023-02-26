#!/depot/tcl8.5.12/bin/tclsh8.5
#nolint Main
#nolint utils__script_usage_statistics
package provide P4 0.1

package require Messaging 1.0
package require Misc 1.0


namespace eval ::P4 {
    # Export commands
    namespace export    da_isa_p4_file \
                        da_p4_add_edit \
                        da_p4_is_checked_out \
                        da_p4_add_edit \
                        da_p4_list \
                        da_p4_dirs \
                        da_create_p4_client \
                        da_delete_p4_client \
                        da_p4_sync_root \
                        da_p4_submit \
                        da_p4_fstat \
                        da_p4_cmd

    namespace ensemble create -map {
        exists        ::P4::da_isa_p4_file 
        print         ::P4::print
        opened        ::P4::da_p4_is_checked_out
        edit          ::P4::da_p4_add_edit
        add           ::P4::da_p4_add_edit
        list          ::P4::da_p4_list
        dirs          ::P4::da_p4_dirs
        create_client ::P4::da_create_p4_client
        delete_client ::P4::da_delete_p4_client
        sync          ::P4::da_p4_sync_root
        sync_root     ::P4::da_p4_sync_root
        submit        ::P4::da_p4_submit
        fstat         ::P4::da_p4_fstat
        cmd           ::P4::da_p4_cmd

    }

    # Set up state
    variable exit_status

}


# %% [markdown]
# ::P4::print

# %%

# pe print has many options and it's better to keep it as it is
proc ::P4::print {args} {
    try {    
        lassign [run_system_cmd "p4 print $args"] rsc_out rsc_err status
    } on error {result options} {
        get_call_stack
        eprint $result
        eprint [dict get $options -errorstack]
    }
}

#-----------------------------------------------------------------


# %% [markdown]
# ::P4::da_isa_p4_file

# %%


proc ::P4::da_isa_p4_file {P4file} {
    try {
        lassign [run_system_cmd "p4 files -e $P4file"] ifexist ifnotexist status
        if {$ifexist == ""} {
            dprint LOW $ifnotexist
            return 0
        } elseif {$ifnotexist == ""} {
            dprint LOW $ifexist
            return 1
        } else {
            return 2
        }
    } on error {result options} {
        get_call_stack
        eprint $result
        eprint [dict get $options -errorstack]
    }
}


# %% [markdown]
# ::P4::da_p4_is_checked_out

# %%

# P4 opened
proc ::P4::da_p4_is_checked_out {P4file {$client ""}} {
    if {$client==""} {global client}
    if {[info exists client(NAME)]} {
        set opt(client) "-c $client(NAME)"
    } else {
        set opt(client) ""
    }
    try {
        lassign [run_system_cmd "p4 files $opt(client) opened $P4file"] ifexist ifnotexist status
        if {$ifexist == ""} {
            dprint LOW $ifnotexist
            return $ifnotexist
        } elseif {$ifnotexist == ""} {
            dprint LOW $ifexist
            return $ifexist
        } else {
            return 2
        }
    } on error {result options} {
        get_call_stack
        eprint $result
        eprint [dict get $options -errorstack]
    }
}

# %% [markdown]
# ::P4::da_p4_add_edit

# %%


proc ::P4::da_p4_add_edit {clientFile {client ""}} {
    if {$client==""} {global client}
    if {[info exists client]} {
        set opt(client) "-c $client(NAME)"
    } else {
        set opt(client) ""
    }
    try {
        if {[file exists $clientFile]} {
            lassign [run_system_cmd "p4 $opt(client) edit $clientFile"] rsc_out rsc_err status
            dprint HIGH $rsc_out
            dprint HIGH $rsc_err
            return $rsc_out
        } else {
            lassign [run_system_cmd "p4 $opt(client) add -t text $clientFile"] rsc_out rsc_err status
            dprint HIGH $rsc_out
            dprint HIGH $rsc_err
            return $rsc_out
        }
    } on error {result options} {
        get_call_stack
        eprint $result
        eprint [dict get $options -errorstack]
    }
    return 0
}

# %% [markdown]
# ::P4::da_p4_list

# %%

proc ::P4::da_p4_list {P4path} {
    try {
        lassign [run_system_cmd "p4 files -e $P4path"] ifexist ifnotexist status
        if {$ifexist == ""} {
            dprint LOW $ifnotexist
            return $ifnotexist
        } elseif {$ifnotexist == ""} {
            dprint LOW $ifexist
            return [split $ifexist "\n" ]
        } else {
            return 2
        }
    } on error {result options} {
        get_call_stack
        eprint $result
        eprint [dict get $options -errorstack]
    }
}

# %% [markdown]
# ::P4::da_p4_dirs

# %%

proc ::P4::da_p4_dirs {P4path} {
    try {
        lassign [run_system_cmd "p4 dirs $P4path"] ifexist ifnotexist status
        if {$ifexist == ""} {
            dprint LOW $ifnotexist
            return $ifnotexist
        } elseif {$ifnotexist == ""} {
            dprint LOW $ifexist
            return [split $ifexist "\n" ]
        } else {
            return 2
        }
    } on error {result options} {
        get_call_stack
        eprint $result
        eprint [dict get $options -errorstack]
    }
}

# %% [markdown]
# ::P4::da_create_p4_client

# %%



proc defined {var_name} {
    return [info exists $var_name]   
}

proc rmtree {pathname} {
    if {[file isdirectory $pathname]} {
        file delete -force -- $pathname
    }
    if {[file exists $pathname]} {
        return 0
    }
    return 1
}

proc mkdir {pathname} {
    return [file mkdir $pathname]
}

proc copy_array {newtbl_name oldtbl_name} {
    uplevel 1 newtbl_name newtbl oldtbl_name oldtbl
    foreach key [array names oldtbl] {
        set newtbl($key) $oldtbl($key)
    }
    return
}

proc ::P4::da_create_p4_client {_client(NAME) _client(ROOT) aref_viewList} {

    if { ![defined $_client(NAME)] || $_client(NAME) eq ""} {
        dprint HIGH "p4_create_client: invalid $_client(NAME)"
        return NULL_VAL;
    }
    if { ![defined $_client(ROOT)] || $_client(ROOT) eq ""} {
        dprint HIGH "p4_create_client: invalid $_client(ROOT)"
        return NULL_VAL;
    }
    if { ![defined $aref_viewList] || $aref_viewList eq ""} {
        dprint HIGH "p4_create_client: invalid $aref_viewList"
        return NULL_VAL;
    }

    set get_call_stack [get_call_stack]
    if { $verbosity >= [[namespace qualifiers [namespace current]]::Messaging::const_to_int FUNCTIONS] } then { [namespace qualifiers [namespace current]]::Messaging::iprint "Subroutine Call Stack: $get_call_stack" }

    set fail   [rmtree $_client(ROOT)]
    set passed [mdkir  $_client(ROOT)]

    if {$passed} {
        dprint HIGH "Created p4 Root directory: $_client(ROOT)"
    } else {
        return [eprint "$get_call_stack -> could not make directory: $_client(ROOT)"]
    }

    set username [get_username]
    lassign [run_system_cmd "p4 clients -u $username"] rscp rscerror status

    if {[string match $_client(NAME) $rscp]} {
        run_system_cmd "p4 client -d $_client(NAME)"
    }

    lassign [run_system_cmd "p4 -c $_client(NAME) client -o"] clientSpec rsc_err status
    
    set _client(DEPOT2CLIENT) {}
    set _client(CLIENT2DEPOT) {}

    global client
    copy_array client _client

    return $client

}



# %% [markdown]
# ::P4::da_delete_p4_client

# %%

 
proc ::P4::da_delete_p4_client {{client ""}} {
    if {$client==""} {global client}
    if {![defined $client]} {return error}

    try {
        lassign [run_system_cmd "p4 client -d $client(NAME)"] rsc_out rsc_err status
        rmtree $client(ROOT)
    } on error {result options} {
        get_call_stack
        eprint $result
        eprint [dict get $options -errorstack]
    } finally {
        if {$rsc_out == ""} {
            dprint LOW $rsc_err
            return $rsc_err
        } elseif {$rsc_err == ""} {
            dprint LOW $rsc_out
            return [split $rsc_out "\n" ]
        } else {
            return 2
        }        
    }

}

# %% [markdown]
# ::P4::da_p4_sync_root

# %%


proc ::P4::da_p4_sync_root {{client ""}} {
    if {$client==""} {global client}
    if {[info exists client]} {
        set opt(client) "-c $client(NAME)"
        set opt(root)   "-f $client(ROOT)"
    } else {
        set opt(client) ""
        set opt(root)   ""
    }
    try {
        lassign [run_system_cmd "p4 $opt(client) sync $opt(root) "] rsc_out rsc_err status
        dprint HIGH $rsc_out
        dprint HIGH $rsc_err
        return $rsc_out
    } on error {result options} {
        get_call_stack
        eprint $result
        eprint [dict get $options -errorstack]
    }
    return 0
}


# %% [markdown]
# ::P4::da_p4_submit

# %%


proc ::P4::da_p4_submit {description P4file {client ""}} {
    if {$client==""} {global client}
    if {[info exists client]} {
        set opt(client) "-c $client(NAME)"
    } else {
        set opt(client) ""
    }
    try {
            lassign [run_system_cmd "p4 $opt(client) submit -d \"$description\" $P4file "] rsc_out rsc_err status
            dprint HIGH $rsc_out
            dprint HIGH $rsc_err
            return $rsc_out
    } on error {result options} {
        get_call_stack
        eprint $result
        eprint [dict get $options -errorstack]
    }
    return 0    
}




# %% [markdown]
# ::P4::da_p4_fstat

# %%

proc ::P4::da_p4_fstat {P4file tags {spec_tag ""}} {
	# creating variations of tags
	set tags_by_comma [regsub -all {\,  |\, |   |  | } $tags ", " ]
	set tags_list [split $tags_by_comma ","]

    try {
		# check file exists
        lassign [run_system_cmd "p4 fstat $P4file"] noTag ifnotexist status
		if {$noTag} {
			return [eprint "Tag not found: $P4file. Abort."]
		}
		# look for those tags
        lassign [run_system_cmd "p4 fstat -T $tags_by_comma $P4file"] ifexist ifnotexist status
		#check if this work and return if not
		if {$ifexist == ""} {
            dprint LOW $ifnotexist
            return $ifnotexist
        } elseif {$ifnotexist == ""} {
            dprint LOW $ifexist
			set P4filelog $ifexist
        } else {
            return 2
        }
		if {$spec_tag != ""} {
			if {[regexp -nocase {$spec_tag (\S+)} $P4filelog -> tagvalue]} {
				return $tagvalue
			}
		}
		return [veprint LOW "No value of $spec_tag in $P4filelog"]

    } on error {result options} {
        get_call_stack
        eprint $result
        eprint [dict get $options -errorstack]
    }
}

# %% [markdown]
#  
#  # TODO
# 
#  - ~~create_p4_client~~
#  - ~~delete_p4_client~~
#  - ~~p4 sync /root~~
#  - ~~submit~~
#  - ~~fstat~~
#  - annotate
#  - revert
#  - where
#  - have
#  - filelog
#  

# %% [markdown]
# The ensemble is working!


 
proc ::P4::da_p4_cmd {cmd} {
    if {$client==""} {global client}
    set strcmd ""
    foreach partcmd $cmd {
        append strcmd $partcmd
    }

    try {
        lassign [run_system_cmd "p4 $trcmd"] rsc_out rsc_err status
    } on error {result options} {
        get_call_stack
        eprint $result
        eprint [dict get $options -errorstack]
    } finally {
        if {$rsc_out == ""} {
            dprint LOW $rsc_err
            return $rsc_err
        } elseif {$rsc_err == ""} {
            dprint LOW $rsc_out
            return [split $rsc_out "\n" ]
        } else {
            return [list $rsc_out $rsc_err]
        }        
    }

}


#
# ⠸⣷⣦⠤⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣀⣠⣤⠀⠀⠀
# ⠀⠙⣿⡄⠈⠑⢄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⠔⠊⠉⣿⡿⠁⠀⠀⠀
# ⠀⠀⠈⠣⡀⠀⠀⠑⢄⠀⠀⠀⠀⠀⠀⠀⠀⠀⡠⠊⠁⠀⠀⣰⠟⠀⠀⠀⣀⣀
# ⠀⠀⠀⠀⠈⠢⣄⠀⡈⠒⠊⠉⠁⠀⠈⠉⠑⠚⠀⠀⣀⠔⢊⣠⠤⠒⠊⠉⠀⡜
# ⠀⠀⠀⠀⠀⠀⠀⡽⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠩⡔⠊⠁⠀⠀⠀⠀⠀⠀⠇
# ⠀⠀⠀⠀⠀⠀⠀⡇⢠⡤⢄⠀⠀⠀⠀⠀⡠⢤⣄⠀⡇⠀⠀⠀⠀⠀⠀⠀⢰⠀
# ⠀⠀⠀⠀⠀⠀⢀⠇⠹⠿⠟⠀⠀⠤⠀⠀⠻⠿⠟⠀⣇⠀⠀⡀⠠⠄⠒⠊⠁⠀
# ⠀⠀⠀⠀⠀⠀⢸⣿⣿⡆⠀⠰⠤⠖⠦⠴⠀⢀⣶⣿⣿⠀⠙⢄⠀⠀⠀⠀⠀⠀
# ⠀⠀⠀⠀⠀⠀⠀⢻⣿⠃⠀⠀⠀⠀⠀⠀⠀⠈⠿⡿⠛⢄⠀⠀⠱⣄⠀⠀⠀⠀
# ⠀⠀⠀⠀⠀⠀⠀⢸⠈⠓⠦⠀⣀⣀⣀⠀⡠⠴⠊⠹⡞⣁⠤⠒⠉⠀⠀⠀⠀⠀
# ⠀⠀⠀⠀⠀⠀⣠⠃⠀⠀⠀⠀⡌⠉⠉⡤⠀⠀⠀⠀⢻⠿⠆⠀⠀⠀⠀⠀⠀⠀
# ⠀⠀⠀⠀⠀⠰⠁⡀⠀⠀⠀⠀⢸⠀⢰⠃⠀⠀⠀⢠⠀⢣⠀⠀⠀⠀⠀⠀⠀⠀
# ⠀⠀⠀⢶⣗⠧⡀⢳⠀⠀⠀⠀⢸⣀⣸⠀⠀⠀⢀⡜⠀⣸⢤⣶⠀⠀⠀⠀⠀⠀
# ⠀⠀⠀⠈⠻⣿⣦⣈⣧⡀⠀⠀⢸⣿⣿⠀⠀⢀⣼⡀⣨⣿⡿⠁⠀⠀⠀⠀⠀⠀
# ⠀⠀⠀⠀⠀⠈⠻⠿⠿⠓⠄⠤⠘⠉⠙⠤⢀⠾⠿⣿⠟⠋
#
