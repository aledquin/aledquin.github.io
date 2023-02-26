#!/depot/tcl8.6.3/bin/tclsh8.6
###############################################################################
#
# Name    : std_template.tcl
# Author  : your name here
# Date    : creation date here
# Purpose : description of the script.. can put on multiple lines
#
# Modification History
#     000 YOURNAME  CURRENT_DATE
#         Created this script
#     001 YOURNAME DATE_OF_YOUR_CHANGES
#         Description of what you have changed.
#
###############################################################################

package require try         ;# Tcllib.
package require cmdline 1.5 ;# First version with proper error-codes.
package require fileutil

set DEBUG      0
set VERBOSITY  0
set STDOUT_LOG ""
set AUTHOR     "Manmit Muker (mmuker), Patrick Juliano (juliano), Alvaro Quintana Carvacho"
set RealBin [file dirname [file normalize [info script]] ]
set RealScript [file tail [file normalize [info script]] ]
set PROGRAM_NAME $RealScript
set LOGFILE "[pwd]/$PROGRAM_NAME.log"

# Declare cmdline opt vars here, so they are global
set opt_fast ""
set opt_test ""
set opt_help ""
set opt_project ""

lappend auto_path "$RealBin/../lib/tcl"
package require Messaging 1.0
namespace import ::Messaging::*
package require Misc 1.0
namespace import ::Misc::*

#####################################################################################
#	THIS SCRIPT IS DESIGNED TO CREATE A STANDALONE SiS TESTCASE IN THE TIMING DIRECTORIES.
#	THE SCRIPT HAS TO BE RUN FROM EITHER Char_<corner> DIRECTORY
#	PLEASE RUN THE SCRIPT WITH -HELP OPTION TO SEE THE USAGE OF THE SCRIPT.
#	FOR ANY ISSUES PLEASE CONTACT DIKSHANT ROHATGI:dikshant@synopsys.com
####################################################################################







if {$argv eq "-help"} {
	puts "HELP::"
	puts "\tPlease run the script from Char_<corner>s directory present at [pwd]"
	puts "\tFor example,Go inside [pwd]/Char_<corner> directory\n\tRun the script inside the directory.\n\tThe script will create a SiS_testcase directory which will contain all the files required to run the testcase"
	exit
}


#This script is used for SiS timing directory which moves all the necessary files to a new SiS directory

#Creating new Directory with Name SiS_testcase"


proc Main {} {

	set dir "./SiS_testcase"
	set macro_file [glob run*.tcl]
	#Checking if SiS directory is already there, if yes removing and making new directory"
	if {[file exists $dir]} {
		exec rm -rf $dir
		file mkdir $dir
	} else {
		file mkdir $dir
	}

	set fid [open "$macro_file" r]
	set fid1 [open "$dir/$macro_file" w]
	puts "INFO: Moving $macro_file to SiS directory"
	while {[gets $fid l1]>=0} {
		puts $fid1 $l1
	}
	close $fid
	close $fid1

	#Copying commonSetup.tcl from current directory to SiS directory
	set fid [open "commonSetup.tcl" r]
	set fid1 [open "$dir/commonSetup.tcl" w+]
	puts "INFO: Moving commonSetup.tcl to SiS directory"
	while {[gets $fid l1]>=0} {
		puts $fid1 $l1
	}
	close $fid
	close $fid1
	#file copy char char_temp
	#Updating the path of the file sourced in commonSetup.tcl"
	set lst [list]
	set fin [open "$dir/commonSetup.tcl" r]
	while {[gets $fin l] >=0 } {
		if {[regexp "#.*" $l] == 0} {
			if {[regexp {source\s+\/(.*)} $l var var1]} {
				set var1 [lindex [split $var1 "/"] end]
				lappend lst "\tsource ./$var1"
			}  else {
				lappend lst $l
			}
		}  else {
			lappend lst $l
		}
	}
	set fop [open "$dir/commonSetup.tcl" w+]
	foreach i $lst {
		puts $fop $i
	}
	close $fop
	close $fin

	#Copying the run_char.sh file to SiS directory
	regsub {\.tcl$} $macro_file ".csh" run_macro_file
	puts "INFO: Moving $macro_file to SiS directory"
	file copy ../$run_macro_file ./$dir
	exec chmod +xrw "$dir/$run_macro_file"
	#cd $dir
	set ll [list]

	set fin [open "$dir/$run_macro_file" r]
	while {[gets $fin line]>=0} {
		#set file_name ""
		#set dir_name ""
		if {[regexp "\s+\.+\/.*" $line] || [regexp {\.[a-z]+} $line]} {

			if {[regexp {\-} $line]} {
				if {[regexp {\/} $line]} {
					regsub -all {\s+} $line " " dir_name
					set dir_name [lindex [split $dir_name " "] 2]
					regsub  {^\.+\/+\.*\/*} $dir_name "" dir_name
					set file_name [lindex [split "$dir_name" "/"] 1]
					set fid1 [open "../../$dir_name" r]
					set fid2 [open "$dir/$file_name" w]
					puts "INFO: Moving $file_name to SiS Directory"
					while {[gets $fid1 l] >=0} {
						puts $fid2 $l
					}
					close $fid1
					close $fid2
					exec chmod +xr "$dir/$file_name"
				} elseif {![regexp {/} $line]} {
					if {[regexp {\$} $line]} {
						set MACRO [lindex [split [pwd] "/"] end-1]
						regsub  {(.*)\$.+\}(.*)} $line "\\1$MACRO\\2" line
					}
					regsub -all {\s+} $line " " dir_name
					set file_name [lindex [split "$dir_name" " "] 2]

					set fid1 [open "$file_name" r]
					#set file_name [lindex [split "$dir_name" "/"] 2]
					regsub {\\} $file_name "" file_name
					set fid2 [open "$dir/$file_name" w]
					puts "INFO: Moving $file_name to SiS Directory"
					while {[gets $fid1 l] >=0} {
						puts $fid2 $l
					}
					close $fid1
					close $fid2
					exec chmod +xr "$dir/$file_name"
				}
			} else {

				regsub -all {\s+} $line " " line
				regsub {\\} $line "" line
				regsub {\s+} $line "" line
				set file_name [lindex [split $line "/"] end]

				#regsub -all {\\} $dir_name "" dir_name
				#set file_name [lindex [split "$dir_name" "/"] 2]
				#regsub " " $dir_name "" dir_name
				set fid1 [open "../$line" r]
				set fid2 [open "$dir/$file_name" w]
				puts "INFO: Moving $file_name to SiS Directory"
				while {[gets $fid1 l] >=0} {
					puts $fid2 $l
				}
				close $fid1
				close $fid2
				exec chmod +wxr "$dir/$file_name"
			}
		}

	}

	close $fin
	set fin [open "$dir/$run_macro_file" r]
	#Changing the path in run_char.csh file to SiS directory
	while {[gets $fin line]>=0} {
		if {[regexp {\/} $line]} {
			regsub {\.+\/+.*/(.*)} $line "./\\1" file_name
			lappend ll "$file_name"
		} else {
			lappend ll $line
		}
	}
	close $fin
	set fop [open "$dir/$run_macro_file" w]
	foreach con $ll {
		puts $fop $con
	}
	close $fop
	#Changing the permission of the files
	#cd ..

	#Moving the required files to SiS directory
	set fin [open "commonSetup.tcl" r]
	while {[gets $fin l] >=0} {
		if {[regexp ".*#.*" $l]==0} {
			#Checking the lines which are not commented out
			if {[regexp {source} $l]} {
				regexp {source\s+(.*)} $l var1 var2
				if {[regexp {\/.*} $var2]} {
					set pth $var2
					set var2 [lindex [split "$var2" "/"] end]
					puts "INFO: Moving $var2 to SiS Directory"
					set fid1 [open "$dir/$var2" w+]
					set fid2 [open $pth r]
					while {[gets $fid2 l1]>=0} {
						puts $fid1 $l1
					}
					close $fid1
					close $fid2
					exec chmod +x "$dir/$var2"
				}
			}

		}
	}
	close $fin


	set names [glob $dir/*]
	regsub -all "$dir/" $names ""  a
	regsub  {\{\}} $a ""  a
	set na [split $a " "]

	foreach f $names {
		set fin [open "$f" r]
		set lst [list]
		while {[gets $fin l] >=0 } {

			if {[regexp "#.*" $l] ==0} {
				foreach c $na {
					if {[regexp "/$c" $l avr]} {
						set file_name [lindex [split $l "/"] end]
						regsub {(.*\s+)/.*} $l "\\1 [pwd]/SIS_testcase/$file_name" str
						lappend lst "$str"
						regsub {.*\s+(/.*)} $l "\\1" pth
						set flag 0
						break
					} else {
						set flag 1
						continue
					}
				}
				if {$flag ==1} {
					lappend lst $l
				}
			} else {
				lappend lst $l
			}

		}
		close $fin
		set fop [open "$f" w+]
		foreach i $lst {
			puts $fop $i
		}
		close $fop
	}


	set lst [glob "../*.inst"]
	set file_name [lindex $lst 0]
	set lst1 {}
	set fid [open "$file_name" r]
	while {[gets $fid l] >=0} {
		if {[regexp {\.ic$} $l]} {
			set pth [lindex [split $l " "] 1]
			#set fil_name [lindex [split $pth "/"] end]
			set fin [open $pth r]
			set fil_name [lindex [split $l "/"] end]
			if {![file exists "$dir/$fil_name"] } {
				set fop [open "$dir/$fil_name" w]
				puts "INFO: Moving $fil_name to SiS Directory"
				while {[gets $fin g] >= 0} {
					puts $fop $g
				}
				close $fin
				close $fop
				set temp [lindex [split $l " "] 0]
				lappend lst1 "$temp ./$fil_name"
			}
		} else {
			lappend lst1 $l
		}
	}
	close $fid
	regsub {..\/} $file_name "" file_name

	set fid [open "$dir/$file_name" w]
	foreach cont $lst1 {
		puts $fid $cont
	}
	close $fid
	cd $dir




	puts "\n*************Script has ran successfully Please Move to SiS directory!*********\n"


}




try {
	header
	set exitval [Main]
} on error {results options} {
	set exitval [fatal_error [dict get $options -errorinfo]]
} finally {
	footer
	write_stdout_log $LOGFILE
}


# 11-07-2022: monitor usage is in header now
# nolint utils__script_usage_statistics