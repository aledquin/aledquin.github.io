#!/depot/tcl8.6.3/bin/tclsh8.6
# nolint Main
# nolint utils__script_usage_statistics

package ifneeded Messaging 1.0 [list source [file join $dir Util/Messaging.tcl]]
package ifneeded Misc 1.0 [list source [file join $dir Util/Misc.tcl]]
package ifneeded P4 0.1 [list source [file join $dir Util/P4.tcl]]
package ifneeded DA_widgets 1.0 [list source [file join $dir Util/DA_widgets.tcl]]
