#!/depot/tcl8.6.6/bin/tclsh
#nolint Main
#nolint utils__script_usage_statistics

package require tcltest 2.0
namespace import -force ::tcltest::*

package require try         ;# Tcllib.
package require cmdline 1.5 ;# First version with proper error-codes.
package require fileutil

set DEBUG      0
set VERBOSITY  0
set STDOUT_LOG ""
set AUTHOR     "Alvaro Quintana Carvacho"
set RealBin [file dirname [file normalize [info script]] ]
set RealScript [file tail [file normalize [info script]] ]

set PROGRAM_NAME "$RealScript"

set opt_fast ""
set opt_test ""
set opt_help ""
set opt_project ""

#lappend auto_path "$RealBin/../bin"
lappend auto_path "$RealBin/../../lib"

package require Messaging 1.0
namespace import ::Messaging::*

package require Misc 1.0
namespace import ::Misc::*



#######################################################################
# Your config here
#######################################################################

# set DA_RUNNING_UNIT_TESTS 0

# -verbose level -> Sets the type of output verbosity desired to level, 
#                   a list of zero or more of the elements body, pass, 
#                   skip, start, and error. Default value is {body error}. 
# Levels are defined as:
# body (b) -> Display the body of failed tests
# pass (p) -> Print output when a test passes
# skip (s) -> Print output when a test is skipped
# start (t)-> Print output whenever a test starts
# error (e)-> Print errorInfo and errorCode, if they exist, 
# when a test return code does not match its expected return code
# The single letter abbreviations noted above are also recognized so 
# that [configure -verbose pt] is the same as [configure -verbose {pass start}].
::tcltest::verbose bpse
::tcltest::debug 2

#######################################################################
# Create your procs here
#######################################################################





#######################################################################
# Create your tests here
#######################################################################

#######################################################################
## colored
#######################################################################

test Messaging-colored_t01 { Test: Messaging package: colored + no inputs} \
    -body { colored } \
    -returnCodes error \
    -result {wrong # args: should be "colored message color"} \
    -output {}











cleanupTests