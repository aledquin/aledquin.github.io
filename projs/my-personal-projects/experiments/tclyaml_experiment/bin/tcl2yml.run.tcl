#!/depot/tcl8.6.3/bin/tclsh8.6
# %%
# %load_ext tclmagic

#  If the prev line doesnt work  install it using the next line in your unix terminal
#  /depot/Python/Python-3.8.0/bin/pip install -U tcl-magic
#  You can configure it to ~/.local/

# %%
# %%tcl

set SHELLTOOL_LOC "$env(HOME)/GitLab/ddr-hbm-phy-automation-team"
lappend auto_path "$SHELLTOOL_LOC/sharedlib/tcl/lib"
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

# %%
# %%tcl
set tcl2yml "$SHELLTOOL_LOC/ddr-ckt-rel/dev/main/bin/ddr-da-tcl2yml.tcl"
set key_word "legalRelease"
set suffix_format {.txt}
set DIR_LOC "$SHELLTOOL_LOC/ddr-ckt-rel/dev/main/tdata"

# %%
# %%tcl
proc get_legal_release_list {key_word suffix_format} {
    return [exec find . -type f | grep $key_word | grep $suffix_format ]
}

# %% [markdown]
# checking it worked


# %%
# %%tcl
proc remove_suffix {path_list suffix} {
    foreach path $path_list {
        lappend output_list [string trimright $path $suffix]
    }
    return $output_list
}

# %%
# %%tcl
cd $DIR_LOC
set clean_list [remove_suffix [get_legal_release_list $key_word $suffix_format] $suffix_format]

# %% [markdown]
# getting the path without suffix as it is needed,

# %%
# %%tcl

proc Main {key_word suffix_format} {
    global DIR_LOC
    global tcl2yml
    cd $DIR_LOC
    set legalReleaseList [get_legal_release_list $key_word $suffix_format]
    set count 0
    set list_size [llength [split $legalReleaseList "\n"]]
    foreach legalReleaseFile $legalReleaseList {
        set count [expr $count + 1]
        viprint LOW "\[$count\/$list_size\]"
        try {
            exec $tcl2yml -i "$DIR_LOC/$legalReleaseFile" -o "$DIR_LOC/[remove_suffix $legalReleaseFile $suffix_format].yml"
        } on error {results options} {
             set exitval 2
        }
    } 
}
set VERBOSITY 5
Main $key_word $suffix_format

# %%
# %%
