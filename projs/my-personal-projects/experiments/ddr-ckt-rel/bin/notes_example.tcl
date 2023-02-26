#!/depot/tcl8.6.3/bin/tclsh8.6
# %% [markdown]
# # TCL unit tests notebook
# ## Intro TCL 

# %%
# %load_ext tclmagic

#  If the prev line doesnt work  install it using the next line in your unix terminal
#  /depot/Python/Python-3.8.0/bin/pip install -U tcl-magic
#  You can configure it to your ~/.local

# %% [markdown]
# ## Init libraries and packages

# %%
# %%tcl 

set SHELLTOOL_LOC "$env(HOME)/GitLab/ddr-hbm-phy-automation-team/"
lappend auto_path "$SHELLTOOL_LOC/sharedlib/tcl"
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

package require tcltest
namespace import -force ::tcltest::*
::tcltest::verbose bpste

# %% [markdown]
# ## 'test' format
# 
# ```bash
# test <name-test> {<description>} -setup {<setting everything to have this ready>} -body {<commands to run>} \
#    ?-returnCodes error? -result (1: {matched string} | 2: [call a command]) -output (1: {matched string} | 2: [call a command])
# ```
# 
# ## Summary Results
# 
# ```bash
# cleanupTests
# ```
# 
# ## Example

# %%
# %%tcl

test Messaging-colored_t01 { Test: Messaging package: colored + no inputs} \
    -body { colored } \
    -returnCodes error \
    -result {wrong # args: should be "colored message color"} \
    -output {}



cleanupTests

# %% [markdown]
# # Instructions
# 1. source the file where the methods are, if it is in a script, check if you can set `DDR_DA_UNIT_TEST` to `1`, so you can source it with no execution of the main procedure.
# ```sh
#     set DDR_DA_UNIT_TEST 1
#     source $RealBin/../../bin/alphaBuildMacroRelease.tcl
#     source $RealBin/../../bin/alphaHLDepotExportRtl.tcl
# ```
# 2. Copy the procedure to evaluate into the next cell and check if it needs to get rebuild
# 3. Write a simple explanation of what is the input and output
# 4. Create a test. You can follow the examples in the directory `$GITLAB/Sharedlib/tcl/tests`
# 5. When the tests are ready, share it with the conductor. 
# 6. When it has been validated, create a new file with all the unit test an name it as: `##_alphabuildMacroRelease_lib_<procedure>.test`
# 
# Each code block you want using TCL you have you type first `%%tcl` at the beggining of the code

# %%
# %%tcl

source $RealBin/alphabuildmacrorel_lib.tcl

# %%
# %%tcl 

proc get_max_changelist_number {p4fileslog} {

    set err 0
    foreach f [split $p4fileslog "\n"] {
        #puts "\"$f\""
        #Example: //depot/products/.../verilog/std_primitives.v#1 - add change 10257259 (text)
        if {[regexp {^(\S+)#(\d+)\D+(\d+)\s} $f dummy depotFile ver changelist ]} {
            set changelists($changelist) 1
            lappend p4fileList $depotFile
        } else {
            eprint "Failed to match '$f'"
            set err 1
        }

        set maxCL 0
        foreach cl [array names changelists] {
            if {$cl > $maxCL} {set maxCL $cl}
        }
    }

    viprint 1 "Changelists: [array names changelists], using $maxCL"
    if $err { myexit { 1 } }

    lappend p4fileList $maxCL
    return $p4fileList
}

# %% [markdown]
# ### TODO
# #### AI.1 Done
# Create a variable that contains more than one depot path 
# #### AI.2 Done
# Create a case for one variable and two to compare. 

# %%
# %%tcl

set variable_list "//depot/products/.../verilog/std_primitives.v#1 - add change 10257920 (text)"

# %%
# %%tcl

split $variable_list "\n"

# %% [markdown]
# 

# %%
# %%tcl

get_max_changelist_number $variable_list


# %%
# %%tcl
set two_dpt "//depot/products/.../verilog/std_primitives.v#1 - add change 10257920 (text)\n//depot/products/.../verilog/std_primitives.v#2 - add change 10257921 (text)"

# %%
# %%tcl

get_max_changelist_number $two_dpt

# %% [markdown]
# #### AI.3 Done
# Create the testcases

# %%
# %%tcl
test get_max_changelist_number_test0 {The proc does not have enough args} \
    -setup {} \
    -body {get_max_changelist_number} \
    -returnCodes error \
    -result {wrong # args: should be "get_max_changelist_number p4fileslog"} 

# %%
# %%tcl
test get_max_changelist_number_test1 {Check it working} \
    -setup {set variable_list "//depot/products/.../verilog/std_primitives.v#1 - add change 10257920 (text)"} \
    -body {get_max_changelist_number $variable_list} \
    -result {//depot/products/.../verilog/std_primitives.v 10257920} 

# %%
# %%tcl
test get_max_changelist_number_test2 {Comparing} \
    -setup {set variable_list "//depot/products/.../verilog/std_primitives.v#1 - add change 10257920 (text)\n//depot/products/.../verilog/std_primitives.v#3 - add change 10257923 (text)"} \
    -body {get_max_changelist_number $variable_list} \
    -result {//depot/products/.../verilog/std_primitives.v //depot/products/.../verilog/std_primitives.v 10257923} 

# %%
# %%tcl
cleanupTests


