#!/depot/tcl8.6.3/bin/tclsh8.6
# %%


#  If the prev line doesnt work  install it using the next line in your unix terminal
#  /depot/Python/Python-3.8.0/bin/pip install -U tcl-magic
#  /depot/Python/Python-3.8.0/bin/pip install -U notebook
#  You can configure it to ~/.local/ 

# %%


set SHELLTOOL_LOC "/remote/cad-rep/msip/tools/Shelltools"
lappend auto_path "$SHELLTOOL_LOC/ddr-utils-lay/dev/lib/tcl"
lappend auto_path "/depot/tcl8.6.3/lib"

set RealBin [file dirname [file normalize [info script]] ]
set RealScript [file tail [file normalize [info script]] ]
set PROGRAM_NAME $RealScript
set LOGFILE "[pwd]/log-$PROGRAM_NAME.log"

package require Messaging 1.0
namespace import ::Messaging::*
package require Misc 1.0
namespace import ::Misc::*

package require cmdline
package require try
package require yaml

# %% [markdown]
# # AI
# 
# - DONE: convert releaseMacro to a dictionary
# - DONE: convert lists in lists...
# 

# %%



proc get_variables_from_file {__file} {
    source $__file
    unset __file
    return [info locals]
}

# %%


proc create_dict_from_file {__file} {

    source $__file

    set sv [get_variables_from_file $__file]
    
    foreach ssv $sv {
        if [regexp {(\S+)\{(\S+)\}} $ssv full dictname keyname] {
            viprint MEDIUM $full
            viprint MEDIUM "dictname = $dictname"
            viprint MEDIUM "keyname  = $keyname"
            foreach dict_values [set $full] {
                lappend list_values "- $dict_values"
            }
            set [set dictname]($keyname) $list_values
            unset list_values
            if {$dictname ni $sv} {lappend new_sv $dictname}
        } else {
            lappend new_sv $ssv
        }
    }

    foreach varname $new_sv {
        viprint LOW $varname
        if {[array exists $varname]} {
            foreach {ark arv} [array get $varname] {
                viprint LOW "$varname $ark --> $arv"
                dict set legal_release $varname "$ark: " "\{$arv\}"
            }
        } else {
            if {[llength [set $varname]]>1} {
                if {![regexp {(date|prune|layers|utility_name|repeater_name|tag|supply_pins)} $varname match]} {
                    foreach litvalue [set $varname] {
                        lappend varvalue "- $litvalue"  
                    }
                } else {
                    set varvalue [set $varname]
                }
            } else {
                set varvalue [set $varname]
            }
            
            dict set legal_release $varname $varvalue
            unset varname
            unset varvalue
        }
        
        
    }
    return $legal_release
}


# %%

proc save_cleaned_yml_to_file {sample_path {file_name "yml-cleaned.yml"}} {

    set legal_release [create_dict_from_file $sample_path]
    set yaml_format [yaml::dict2yaml $legal_release 4 100]

    set cleaned_format [regsub -all {\: \} \{} $yaml_format ": "]
    set cleaned_format [regsub -all {\} \{|\|-\n    \{|>\n    } $cleaned_format "\n    " ]
    
    set cleaned_values [regsub -all {\: \{} $cleaned_format ": " ]
    set cleaned_values [regsub -all {\}\n} [regsub -all {\}\n} $cleaned_values "\n" ] "\n" ]
    write_file $file_name [regsub -all {\}} [regsub -all {: \{-} $cleaned_values ":\n    -" ] "" ]
 
}








# 

# %%

set SHELLTOOL_LOC "$env(HOME)/GitLab/ddr-hbm-phy-automation-team"
set tcl2yml "$SHELLTOOL_LOC/ddr-ckt-rel/dev/main/bin/ddr-da-tcl2yml.tcl"
set key_word "legal_release"
set suffix_format {}
set DIR_LOC "$SHELLTOOL_LOC/ddr-ckt-rel/dev/main/tests"

# %%
# 
proc get_legal_release_list {key_word suffix_format} {
    return [exec find . -type f | grep $key_word | grep $suffix_format ]
}

# %% [markdown]
# checking it worked


# %%
# 
proc remove_suffix {path_list suffix} {
    foreach path $path_list {
        lappend output_list [string trimright $path $suffix]
    }
    return $output_list
}

# %%
# 
cd $DIR_LOC
set clean_list [remove_suffix [get_legal_release_list $key_word $suffix_format] $suffix_format]

# %% [markdown]
# getting the path without suffix as it is needed,

# %%
# 

proc Main {key_word suffix_format} {
    global DIR_LOC
    global tcl2yml
    cd $DIR_LOC
    set legalReleaseList [get_legal_release_list $key_word $suffix_format]
    set count 0
    set list_size [llength [split $legalReleaseList "\n"]]
    foreach legalReleaseFile $legalReleaseList {
        set count [expr $count + 1]
        nprint "\[$count\/$list_size\] Result--> $DIR_LOC/[remove_suffix $legalReleaseFile $suffix_format].yml"
        try {
            save_cleaned_yml_to_file "$DIR_LOC/$legalReleaseFile" "$DIR_LOC/[remove_suffix $legalReleaseFile $suffix_format].yml"
        } on error {results options} {
             set exitval 2
        }
        
    } 
}
set VERBOSITY 0 
Main $key_word $suffix_format

# %%



