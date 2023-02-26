#!/depot/tcl8.6.6/bin/tclsh

set DEBUG      0
set VERBOSITY  0
set STDOUT_LOG ""
set TIMESTAMP  1
set AUTHOR "Manmit Muker (mmuker)"
set RealBin [file dirname [file normalize [info script]] ]
set RealScript [file tail [file normalize [info script]] ]

lappend auto_path "$RealBin/../bin"
lappend auto_path "$RealBin/../lib/tcl"

package require Messaging 1.0
namespace import ::Messaging::*

package require Misc 1.0
namespace import ::Misc::*

set VERSION [get_release_version]
# Revision history:
# 2022.08-1 - Added command line inputs.
# 2022.08 - Initial release.

package require cmdline

set script_name [file tail [file rootname [file normalize [info script]]]]
utils__script_usage_statistics $script_name $VERSION

# Process the command line
set parameters {
	{icv.arg	""	"List of ICV checks: Example -icv \"drc erc\" or -icv drc or -icv erc"}
	{calibre.arg	""	"List of Calibre checks: Example -calibre \"drc erc\" or -calibre drc or -calibre erc"}
	{stack.arg	""	"List of Metal Stacks: Example -stack \"8M_5X2Z 10M_5X2Y2R\" or -stack 8M_5X2Z"}
	{path.arg	""	"Depot/Local report path: Example -path //depot/products/lpddr54/project/d856-lpddr54-tsmc12ffc18/ckt/rel/crd_testcases/2.00a or -path /slowfs/project/crd_testcases/"}
}
set usage ": ddr-crd_abutment_report.tcl \[options]
					\nExample:
					\n\tddr-crd_abutment_report.tcl -icv \"drc erc\" -calibre \"drc erc\" -stack \"8M_5X2Z 10M_5X2Y2R\" -path //depot/products/lpddr54/project/d856-lpddr54-tsmc12ffc18/ckt/rel/crd_testcases/2.00a
					\n\tddr-crd_abutment_report.tcl -icv \"drc erc\" -stack \"8M_5X2Z 10M_5X2Y2R\" -path //depot/products/lpddr54/project/d856-lpddr54-tsmc12ffc18/ckt/rel/crd_testcases/2.00a
					\n\tddr-crd_abutment_report.tcl -icv drc -calibre \"drc erc\" -stack 8M_5X2Z -path //depot/products/lpddr54/project/d856-lpddr54-tsmc12ffc18/ckt/rel/crd_testcases/2.00a
					\noptions:"
if {[catch {array set options [cmdline::getoptions ::argv $parameters $usage]}]} {
	puts [cmdline::usage $parameters $usage]
		exit	
} else {
# Only drc and erc checks are allowed
	if {[regexp {(^|\s)drc(\s|$)|(^|\s)erc(\s|$)} $options(icv)] || [regexp {(^|\s)drc(\s|$)|(^|\s)erc(\s|$)} $options(calibre)]} {
		puts "INFO: ICV Checks: $options(icv) ."
		puts "INFO: Calibre Checks: $options(calibre) ."
	} else {
		puts "ERROR: -icv or -calibre input is not valid. Valid -icv or -calibre inputs are drc/erc or both. Try ddr-crd_abutment_report.tcl -help for details."
		exit
	}
# Checking report path is not empty
	if {[string length $options(path)] > 0} {
		puts "INFO: Depot/Local report path: $options(path) ."
	} else {
		puts "ERROR: -path input is empty. Try ddr-crd_abutment_report.tcl -help for details."
		exit
	}
# Checking metal stack is not empty
	if {[string length $options(stack)] > 0} {
		puts "INFO: Metal Stacks: $options(stack) ."
	} else {
		puts "ERROR: -stack input is empty. Try ddr-crd_abutment_report.tcl -help for details."
		exit
	}
}
set Tools "icv calibre"
set metalStack $options(stack)
set crd_report_path $options(path)
set script_dir [pwd]
array set checks {
	icv $options(icv)
	calibre $options(calibre)
}
# Array containing testcase and report path
array set ErrorFileList {}
# Array containing icv errors and description
array set ICVErrorList {}
# Array containing calibre errors and description
array set CalErrorList {}

# Open crd_abutment_report.html
if {[catch {open crd_abutment_report.html w} HTML_Fid]} {
	puts "***** $HTML_Fid"
	exit
}
# crd_abutment_report.html writing proc
proc Write_HTML {log_text} {
	global HTML_Fid
	puts $HTML_Fid $log_text
}
# Checking if path is a local/depot path. If depot sync 
if { [regexp {^//depot/} $crd_report_path] } {
	puts "\nINFO: Using depot path $crd_report_path to create [array names checks] report for $metalStack metal stack."
	puts "\nINFO: Syncing [array names checks] reports for $metalStack metal stack from p4 path to ./perforce_files."
	file mkdir perforce_files
	cd perforce_files
	foreach tool $Tools {
		foreach check $options($tool) {
			catch { exec p4 -p p4p-us01:1999 print -o crd_testcases/\.\.\./$tool/$check/\.\.\.\.rpt $crd_report_path/\.\.\./$tool/$check/\.\.\.\.rpt } report
			puts "$report\n"
		}
	}	
	cd ..
# Setting crd_report_path to local synced path
	set crd_report_path "$script_dir/perforce_files/crd_testcases"
} elseif { [file exists $crd_report_path] } {
	puts "\nINFO: Using depot path $crd_report_path to create [array names checks] report for $metalStack metal stack.\n"
} else {
	puts "\nERROR: Path does not exist $crd_report_path .\n"
	exit
}
cd $crd_report_path
# Getting all the directory(testcase) names from local synced path, this is the list of testcases
set testcases [glob -nocomplain -type d * ]
# Change to current working dir
cd $script_dir
foreach testcase $testcases {
	foreach tool $Tools {
		foreach check $options($tool) {
			foreach stack $metalStack {
				if { [glob -nocomplain -directory $crd_report_path/$testcase/$tool/$check -type f /${check}_${testcase}_${stack}.rpt ] == "" } {
					puts "WARNING: Report file $crd_report_path/$testcase/$tool/$check/${check}_${testcase}_${stack}.rpt not found."
				} else {
					set ErrorFileList(${testcase}-${tool}-${check}-${stack}) [glob -nocomplain -directory $crd_report_path/$testcase/$tool/$check -type f /${check}_${testcase}_${stack}.rpt]
				}
			}
		}
	}
}
#Parsing each repot file
foreach {testcase rptfile} [array get ErrorFileList] {
#Assigning array for each testcases to store error name and error count
	array set $testcase {}
################################################################################
#Parsing icv report
#Example reports:
#
# DM2.S.1.1 : Space of DM2_O (Except ICOVL) >= 0.08 um
#   not_inside ......................................... 246 violations found.
#
# LUP.WARN.2 : Voltage text or voltage marker layer 
#  must exist in bond pad in chip level (Except 
#  SEALRING_ALL) When turn on option 
#  'define_pad_by_text,' DRC checks voltage text on 
#  power/ground/signal virtual pad for IP level and 
#  all of bond pad for chip level. When turn off option 
#  'define_pad_by_text,' DRC checks this rule only when 
#  it is chip level
#    not ................................................ 58543 violations found.
#        Error limit exceeded.  Details only available for first 7318.
#    not ................................................ 410550 violations found.
#        Error limit exceeded.  Details only available for first 5865.
#    not ................................................ 1 violation found.
#
#  HIA.17g : ALL ACTIVE OD inside same HIA_DUMMY should 
#  be in the same net
#    interacting ........................................ 1 violation found.
#    interacting ........................................ 1 violation found.
#
#################################################################################
	if { [lindex [split $testcase -] 1] == "icv" } {
		set result ""
		set summary ""
		set summary_list {}
		set var ""
		set err_list {}
#Getting result status ERRORS/CLEAN
		catch { exec grep "LAYOUT ERRORS RESULTS:" < $rptfile } result
		set result [lindex [split $result " "] end]
		if { $result == "ERRORS" } {
#Getting ERROR SUMMARY
			catch { exec sed -n {/ERROR SUMMARY/,/ERROR DETAILS/p} < $rptfile | tail -n +2 } summary
			set summary_list [split $summary \n]
			foreach err $summary_list {
				if { $err != "" } {
					append var $err
				} elseif { $var != "" } {
					if {[regexp -all {\S+\s\.+\s[1-9]\d*\sviolation[s]?\sfound\.} $var]} {
						lappend err_list "$var"
					} else {
						puts "\nWARNING: Found 0 violations or Check Not executed."
					}
					set var ""
				}
			}
			foreach err_dis $err_list {
			set count_string_list {}
			set err_name ""
			set count_list {}
			set temp_err_dis "" 
#Getting error count
					set count_string_list [regexp -all -inline {\S+\s\.+\s[1-9]\d*\sviolation[s]?\sfound\.} $err_dis]
					if {[llength $count_string_list] != 0} {
						foreach count $count_string_list {
							lappend count_list "[lindex $count 0] [lindex $count 2]"
						}
					} else {
						puts "\tERROR: Not able to get Check count $count_string_list ."
						exit
					}
#Getting error name
					set err_name [lindex [split $err_dis " "] 1]
					if {$err_name != ""} {
					} else {
						puts "\tERROR: Not able to get Check name $err_name ."
						exit
					}
#Getting error description
					regsub -all {\S+\s\.+\s[0-9]\d*\sviolation[s]?\sfound\.} $err_dis "" temp_err_dis
					regsub -all {[\s+]?Error\slimit\sexceeded\.\s+Details\sonly\savailable\sfor\sfirst\s[1-9]\d*\.[\s+]?} $temp_err_dis "" temp_err_dis
					regsub -all {\s+$} $temp_err_dis "" temp_err_dis
					if {$temp_err_dis != ""} {
						if {[lsearch [array names ICVErrorList] $err_name] <= 0} {
							set ICVErrorList($err_name) $temp_err_dis
						}
					} else {
						puts "\tERROR: Not able to get Check description."
						exit
					}
					set ${testcase}($err_name) "$count_list"
			}
		} elseif {$result == "CLEAN"} {
			set ${testcase}(LAYOUT_CLEAN) "{COUNT 0}"
			set ICVErrorList(LAYOUT_CLEAN) "CLEAN"
		} else {
			puts "ERROR: RESULTS UNKNOWN, please check $rptfile ."
			exit
		}
################################################################################
#Parsing calibre report
#Example reports:
# DRC:
#  RULECHECK DM4.S.7:IP_TIGHTEN_BOUNDARY ................................................. TOTAL Result Count = 0  (0)
#  RULECHECK DM5.S.7:IP_TIGHTEN_BOUNDARY ................................................. TOTAL Result Count = 0  (0)
#  RULECHECK DM6.S.7:IP_TIGHTEN_BOUNDARY ................................................. TOTAL Result Count = 0  (0)
#  RULECHECK DM7.S.7:IP_TIGHTEN_BOUNDARY ................................................. TOTAL Result Count = 0  (0)
#  ----------------------------------------------------------------------------------
#  --- SUMMARY
#  ---
#  TOTAL CPU Time:                  478
#  TOTAL REAL Time:                 490
#  TOTAL Original Layer Geometries: 1366057 (3048551)
#  TOTAL DRC RuleChecks Executed:   5674
#  TOTAL DRC Results Generated:     24 (104)
#  TOTAL DFM RDB Results Generated: 402 (507)
# 
# ERC:
#  RULECHECK ppvdd49 ................. TOTAL Result Count = 0 (0)
#  RULECHECK LVSDMY4_DNW_CHECK ....... TOTAL Result Count = 0 (0)
#  RULECHECK PODE.R.9.2_P ............ TOTAL Result Count = 0 (0)
#  RULECHECK PODE.R.9.2_N ............ TOTAL Result Count = 0 (0)
#  ----------------------------------------------------------------------------------
#  --- SUMMARY
#  ---
#  TOTAL CPU Time:                              86
#  TOTAL REAL Time:                             92
#  TOTAL Original Layer Geometries:             1277409 (2619589)
#  TOTAL ERC RuleChecks Executed:               13
#  TOTAL ERC RuleCheck Results Generated:       1 (2)
# 
#################################################################################
	} elseif { [lindex [split $testcase -] 1] == "calibre" } {
			catch { exec grep -E {^TOTAL\s(DRC|ERC\sRuleCheck)\sResults\sGenerated} < $rptfile } result
			if {[regexp {Results\sGenerated:\s+0\s\(0\)} $result]} {
				set ${testcase}(LAYOUT_CLEAN) "{COUNT 0}"
				set CalErrorList(LAYOUT_CLEAN) "CLEAN"
			} elseif { [regexp {Results\sGenerated:\s+[1-9]\d*\s\([1-9]\d*\)} $result]} {
				catch { exec sed -n {/--- RULECHECK RESULTS STATISTICS/,/--- SUMMARY/p} < $rptfile | tail -n +2 } summary
				set summary_list [split $summary \n]
				foreach err $summary_list {
					set err_name ""
					set err_count 0
					set count_list {}
					if {[regexp {^RULECHECK\s\S*\s\.+\sTOTAL\sResult\sCount\s=\s[1-9]\d*\s+\([1-9]\d*\)} $err]} {
						set err_name [lindex [split $err " "] 1]
						set err_count [lindex [split $err " "] 7]
						lappend count_list "count $err_count"
						set ${testcase}($err_name) "$count_list"
						if {[lsearch [array names CalErrorList] $err_name] <= 0} {
							set CalErrorList($err_name) "No description"
						} 
					}
				}
			} else {
				puts "\nERROR: RESULTS UNKNOWN, please check $result ."
				exit
			}
	}
}

#Creating crd_abutment_waiver
if {[file exists ./crd_abutment_waiver]} {
	puts "INFO: Waiver file crd_abutment_waiver exist."
	puts "INFO: Sourcing Waiver file crd_abutment_waiver."
	source crd_abutment_waiver
} else {
	if {[catch {open ./crd_abutment_waiver w} Waive_Fid]} {
		puts "***** $HTML_Fid"
		exit
	}
puts "INFO: Creating Waiver file crd_abutment_waiver."
puts $Waive_Fid "#!/usr/local/bin/tclsh"
foreach test $testcases {
	foreach tool $Tools {
			foreach check $options($tool) {
				foreach metal $metalStack {
					if [array exists $test-$tool-$check-$metal] {
						puts $Waive_Fid "\narray set waiver-$test-$tool-$check-$metal {"
							foreach {err count} [array get $test-$tool-$check-$metal] {
								if {[string equal $err "LAYOUT_CLEAN"]} {
									puts $Waive_Fid "$err\t\"CLEAN\""
								} else {
									puts $Waive_Fid "$err\t\"None\""
								}
							}
							puts $Waive_Fid "}"
					}
				}
			}
	}
}
close $Waive_Fid
puts "INFO: Sourcing Waiver file crd_abutment_waiver."
source crd_abutment_waiver
}

#Creating crd_abutment_report.html content
Write_HTML "<!DOCTYPE html>\n<html lang=\"en\">\n<head>\n\t<meta charset=\"UTF-8\">\n\t<meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">\n\t<title>crd abutment report</title>"
Write_HTML "\t<style>"
Write_HTML "\t\tdiv.Main\n\t\t{\n\t\t\tfont-size:10px;\n\t\t\tposition:relative;\n\t\t}"
Write_HTML "\t\tdiv.TestcasesListMenu\n\t\t{\n\t\t\tborder:2px solid #78AD21;\n\t\t\theight:90vh;\n\t\t\twidth:15vw;\n\t\t\toverflow:auto;\n\t\t\tposition:absolute;\n\t\t}"
Write_HTML "\t\tdiv\[class^=\"Testcase-\"\]\n\t\t{\n\t\t\tborder:2px solid #78AD21;\n\t\t}"
Write_HTML "\t\tdiv\[class^=\"ErrorTestcase-\"\]\n\t\t{\n\t\t\theight:90vh;\n\t\t\twidth:83vw;\n\t\t\tbackground-color:#c7dbf0;\n\t\t\tposition:absolute;\n\t\t\tleft:16vw;\n\t\t\tborder:2px solid #78AD21;\n\t\t\tdisplay:none;\n\t\t\tfont-size:15px;\n\t\t\toverflow:auto;\n\t\t}"
Write_HTML "\t\tbutton\[class^=\"ToolButton-\"\]\n\t\t{\n\t\t\tdisplay:none;\n\t\t}"
Write_HTML "\t\ttd\[class^=\"ErrorTable\"\],td\[class^=\"ErrorTableWaive\"\],th\n\t\t{\n\t\t\tborder:2px solid;\n\t\t\tborder-collapse:collapse;\n\t\t}"
Write_HTML "\t\ttd.ErrorTableCount\n\t\t{\n\t\t\tborder:none;\n\t\t\twhite-space: nowrap;\n\t\t}"
Write_HTML "\t</style>"
Write_HTML "</head>"
Write_HTML "<body>"
Write_HTML "<div class=\"Main\">"
Write_HTML "\t<h1>CRD Abutment Results:</h1>" 
Write_HTML "\t<h2>Path:$options(path)</h2>" 
Write_HTML "\t<div class=\"TestcasesListMenu\">"

#Creating testcase button and sub sections buttons
foreach test $testcases {
	Write_HTML "\t\t<div class=\"Testcase-$test\">"
	Write_HTML "\t\t\t<button id=\"TestcaseButton-$test\" type=\"button\" value=\"ToolButton-$test\" onclick=\"myFunction1(this.value)\">$test</button>"
	foreach tool $Tools {
		foreach check $options($tool) {
			foreach metal $metalStack {
				if [array exists $test-$tool-$check-$metal] {
					Write_HTML "\t\t\t<button id=WaiveTestcase-${test}-${tool}-${check}-${metal} class=\"ToolButton-${test}\" type=\"button\" value=\"ErrorTestcase-${test}-${tool}-${check}-${metal}\" onclick=\"myFunction1(this.value)\">${tool}:${check}:${metal}</button>"
				} else {
				} 
			}
		}
	}
Write_HTML "\t\t</div>"
}
#Creating Summary button and sub sections buttons
Write_HTML "\t\t<div class=\"Testcase-Summary\">"
Write_HTML "\t\t\t<button id=\"TestcaseButton-Summary\" type=\"button\" value=\"ToolButton-Summary\" onclick=\"myFunction1(this.value)\">Summary</button>"
Write_HTML "\t\t\t<button id=\"WaiveTestcase-Summary\" class=\"ToolButton-Summary\" type=\"button\" value=\"ErrorTestcase-SummaryTable\" onclick=\"myFunction1(this.value)\">SummaryTable</button>"
Write_HTML "\t\t</div>"
Write_HTML "\t</div>"
#Creating Error table for each testcase sub sections 
foreach test $testcases {
	foreach tool $Tools {
		foreach check $options($tool) {
			foreach metal $metalStack {
				if [array exists $test-$tool-$check-$metal] {
					Write_HTML "\t<div class=\"ErrorTestcase-${test}-${tool}-${check}-${metal}\">"
					Write_HTML "\t\t<p>Test case: ${test}-${tool}-${check}-${metal}</p>"
					Write_HTML "\t\t<p>File path: $options(path)/${test}/${tool}/${check}/${check}_${test}_${metal}.rpt</p>"
					Write_HTML "\t\t<table>"
					Write_HTML "\t\t\t<tr>"
					Write_HTML "\t\t\t<th>ERROR</th>"
					Write_HTML "\t\t\t<th>COMMAND</th>"
					Write_HTML "\t\t\t<th>TOTAL COUNT</th>"
					Write_HTML "\t\t\t<th>ERROR DESCRIPTION</th>"
					Write_HTML "\t\t\t<th>COMMENT</th>"
					Write_HTML "\t\t\t</tr>"
					foreach {err count} [array get $test-$tool-$check-$metal] {
						set num 0							
						Write_HTML "\t\t\t<tr>"
						Write_HTML "\t\t\t\t<td class=\"ErrorTable\">$err</td>"
						Write_HTML "\t\t\t\t<td class=\"ErrorTable\">"
						Write_HTML "\t\t\t\t<table>"
							foreach ct $count {
								Write_HTML "\t\t\t\t\t<tr>"
								Write_HTML "\t\t\t\t\t\t<td class=\"ErrorTableCount\">$ct</td>"
								Write_HTML "\t\t\t\t\t</tr>"
								set num [expr {$num + [lindex [split $ct " "] 1]}]
							}
						Write_HTML "\t\t\t\t</table>"
						Write_HTML "\t\t\t\t</td>"
						Write_HTML "\t\t\t\t<td class=\"ErrorTable\">$num</td>"
						if {[info exists ICVErrorList($err)]} {
							Write_HTML "\t\t\t\t<td class=\"ErrorTable\">$ICVErrorList($err)</td>"
						} elseif {[info exists CalErrorList($err)]} {
							Write_HTML "\t\t\t\t<td class=\"ErrorTable\">$CalErrorList($err)</td>"
						} else {
							puts "ERROR: Error description not found."
							exit
						}
						if {[info exists waiver-$test-$tool-$check-$metal]} {
							if {[lsearch [array names waiver-$test-$tool-$check-$metal] $err] >= 0} {
								foreach {vio wvr} [array get waiver-$test-$tool-$check-$metal] {
									if {[string equal $vio $err]} {
										Write_HTML "\t\t\t\t<td class=\"ErrorTableWaive-${test}-${tool}-${check}-${metal}\">$wvr</td>"
									}
								}
							} else {
								puts "\nERROR: Waiver for $err is not found in waiver-$test-$tool-$check-$metal inside crd_abutment_waiver file. Add waiver for $err manually inside crd_abutment_waiver."
								exit
							}
						} else {
								Write_HTML "\t\t\t\t<td class=\"ErrorTableWaive-${test}-${tool}-${check}-${metal}\">None</td>"
								puts "\nERROR: Waiver for $test-$tool-$check-$metal does not exist in crd_abutment_waiver file. Add below lines manually inside crd_abutment_waiver file."
								puts "array set waiver-$test-$tool-$check-$metal {"
								puts "$err \"None\""
								puts "}"
								exit
						}					
						Write_HTML "\t\t\t</tr>"
					}
					Write_HTML "\t\t</table>"
					Write_HTML "\t</div>"
				} else {
				} 
			}
		}
	}
}

#Summary table content
Write_HTML "\t<div class=\"ErrorTestcase-SummaryTable\">"
Write_HTML "\t\t<table>"
Write_HTML "\t\t\t<tr>"

#Error
Write_HTML "\t\t\t<th>Error"
Write_HTML "\t\t\t\t<br>"
Write_HTML "\t\t\t\t<select class=\"Error\" onchange=\"filter_rows()\">"
Write_HTML "\t\t\t\t\t<option value=\"all\">all</option>"
foreach err [lsort -unique [concat [array names ICVErrorList] [array names CalErrorList]]] {
	Write_HTML "\t\t\t\t\t<option value=\"$err\">$err</option>"
}
Write_HTML "\t\t\t\t</select>"
Write_HTML "\t\t\t</th>"

#TecatCase
Write_HTML "\t\t\t<th>TecatCase"
Write_HTML "\t\t\t\t<br>"
Write_HTML "\t\t\t\t<select class=\"TecatCase\" onchange=\"filter_rows()\">"
Write_HTML "\t\t\t\t\t<option value=\"all\">all</option>"
foreach case $testcases {
	Write_HTML "\t\t\t\t\t<option value=\"$case\">$case</option>"
}
Write_HTML "\t\t\t\t</select>"
Write_HTML "\t\t\t</th>"

#Metalstack
Write_HTML "\t\t\t<th>Metalstack"
Write_HTML "\t\t\t\t<br>"
Write_HTML "\t\t\t\t<select class=\"Metalstack\" onchange=\"filter_rows()\">"
Write_HTML "\t\t\t\t\t<option value=\"all\">all</option>"
foreach met $metalStack {
	Write_HTML "\t\t\t\t\t<option value=\"$met\">$met</option>"
}
Write_HTML "\t\t\t\t</select>"
Write_HTML "\t\t\t</th>"

#Check
Write_HTML "\t\t\t<th>Check"
Write_HTML "\t\t\t\t<br>"
Write_HTML "\t\t\t\t<select class=\"Check\" onchange=\"filter_rows()\">"
Write_HTML "\t\t\t\t\t<option value=\"all\">all</option>"
set chklist {}
foreach tool $Tools {
	set chklist [concat $chklist $options($tool)]
}	
foreach chk [lsort -unique $chklist] {
	Write_HTML "\t\t\t\t\t<option value=\"$chk\">$chk</option>"
}
Write_HTML "\t\t\t\t</select>"
Write_HTML "\t\t\t</th>"

#Tool
Write_HTML "\t\t\t<th>Tool"
Write_HTML "\t\t\t\t<br>"
Write_HTML "\t\t\t\t<select class=\"Tool\" onchange=\"filter_rows()\">"
Write_HTML "\t\t\t\t\t<option value=\"all\">all</option>"
foreach tool $Tools {
	Write_HTML "\t\t\t\t\t<option value=\"$tool\">$tool</option>"
}
Write_HTML "\t\t\t\t</select>"
Write_HTML "\t\t\t</th>"

#Waiver
Write_HTML "\t\t\t<th>Waiver</th>"
Write_HTML "\t\t\t</tr>"

#All errors in Summary table
foreach {test rptfile} [array get ErrorFileList] {
	set test_name [lindex [split $test "-"] 0]
	set tool_name [lindex [split $test "-"] 1]
	set check_name [lindex [split $test "-"] 2]
	set metal_name [lindex [split $test "-"] 3]
	foreach {err dis} [array get $test] {
		Write_HTML "\t\t\t<tr>"
		Write_HTML "\t\t\t\t<td class=\"ErrorTableSummary\">$err</td>"
		Write_HTML "\t\t\t\t<td class=\"ErrorTableSummary\">$test_name</td>"
		Write_HTML "\t\t\t\t<td class=\"ErrorTableSummary\">$metal_name</td>"
		Write_HTML "\t\t\t\t<td class=\"ErrorTableSummary\">$check_name</td>"
		Write_HTML "\t\t\t\t<td class=\"ErrorTableSummary\">$tool_name</td>"
		if {[info exists waiver-$test_name-$tool_name-$check_name-$metal_name]} {
			foreach {vio wvr} [array get waiver-$test_name-$tool_name-$check_name-$metal_name] {
				if {[string equal $vio $err]} {
					Write_HTML "\t\t\t\t<td class=\"ErrorTableWaive-Summary\">$wvr</td>"
				}
			}
		} else {
			puts "\nERROR: RESULTS UNKNOWN, please check $result ."
			exit
		}
		Write_HTML "\t\t\t</tr>"
	}
}
Write_HTML "\t\t</table>"
Write_HTML "\t</div>"
#End Summary table
Write_HTML "</div>"

#Script section for color coding depending on waivers and filtering errors in Summary table
Write_HTML "<script>"

#Function display and hide testcase buttons
Write_HTML "\tfunction myFunction1(val) {"
Write_HTML "\t\tlet sp = val.split(\"-\"\)\[0\];"
Write_HTML "\t\tif (sp == 'ToolButton') {"
Write_HTML "\t\t\tlet elems = document.querySelectorAll('\[class^=ToolButton-\]');"
Write_HTML "\t\t\tfor (let i = 0; i < elems.length; i++) {"
Write_HTML "\t\t\t\telems\[i\].style.display = '';"
Write_HTML "\t\t\t}"
Write_HTML "\t\t}"
Write_HTML "\t\tif (sp == 'ErrorTestcase') {"
Write_HTML "\t\t\tlet elems = document.querySelectorAll('\[class^=ErrorTestcase-\]');"
Write_HTML "\t\t\tfor (let i = 0; i < elems.length; i++) {"
Write_HTML "\t\t\t\telems\[i\].style.display = '';"
Write_HTML "\t\t\t}"
Write_HTML "\t\t}"
Write_HTML "\t\tlet element = document.getElementsByClassName(val);"
Write_HTML "\t\tfor (let i = 0; i < element.length; i++) {"
Write_HTML "\t\t\tlet display = element\[i\].style.display;"
Write_HTML "\t\t\tif (display === '') {"
Write_HTML "\t\t\t\telement\[i\].style.display = 'block';"
Write_HTML "\t\t\t} else {"
Write_HTML "\t\t\t\telement\[i\].style.display = '';"
Write_HTML "\t\t\t}"
Write_HTML "\t\t}"
Write_HTML "\t}"

#script to color code the waived/non waived errors
Write_HTML "\tlet WaiveTable = document.querySelectorAll('\[class^=ErrorTableWaive-\]');"
Write_HTML "\tfor (let tbl = 0; tbl < WaiveTable.length; tbl++) {"
Write_HTML "\t\tif (WaiveTable\[tbl\].innerHTML == \"None\") {"
Write_HTML "\t\t\tWaiveTable\[tbl\].style.backgroundColor = 'yellow';"
Write_HTML "\t\t\tlet cls = WaiveTable\[tbl\].className;"
Write_HTML "\t\t\tcls = cls.split(\"-\")\[1\];"
Write_HTML "\t\t\tcls = \"TestcaseButton-\" + cls;"
Write_HTML "\t\t\tlet btn = document.getElementById(cls);"
Write_HTML "\t\t\tbtn.style.color = 'red';"
Write_HTML "\t\t\tcls = WaiveTable\[tbl\].className;"
Write_HTML "\t\t\tcls= cls.replace('ErrorTableWaive', 'WaiveTestcase');"
Write_HTML "\t\t\tbtn = document.getElementById(cls);"
Write_HTML "\t\t\tbtn.style.color = 'red';"
Write_HTML "\t\t}"
Write_HTML "\t}"

#Function to filter Summary table
Write_HTML "\tfunction filter_rows() {"
Write_HTML "\t\tlet filter = document.querySelectorAll(\".Error\");"
Write_HTML "\t\tlet filter_error =  filter\[0\].value;"
Write_HTML "\t\tfilter = document.querySelectorAll(\".TecatCase\");"
Write_HTML "\t\tlet filter_test =  filter\[0\].value;"
Write_HTML "\t\tfilter = document.querySelectorAll(\".Metalstack\");"
Write_HTML "\t\tlet filter_metal =  filter\[0\].value;"
Write_HTML "\t\tfilter = document.querySelectorAll(\".Check\");"
Write_HTML "\t\tlet filter_check =  filter\[0\].value;"
Write_HTML "\t\tfilter = document.querySelectorAll(\".Tool\");"
Write_HTML "\t\tlet filter_tool =  filter\[0\].value;"
Write_HTML "\t\tlet SmryTbl = document.querySelectorAll('\[class=ErrorTableSummary\]');"
Write_HTML "\t\tfor (let i = 0; i < SmryTbl.length; i++) {"
Write_HTML "\t\t\tif ((SmryTbl\[i\].parentNode.cells\[0\].innerHTML == filter_error || filter_error == \"all\") && (SmryTbl\[i\].parentNode.cells\[1\].innerHTML == filter_test || filter_test == \"all\") && (SmryTbl\[i\].parentNode.cells\[2\].innerHTML == filter_metal || filter_metal == \"all\") && (SmryTbl\[i\].parentNode.cells\[3\].innerHTML == filter_check || filter_check == \"all\") && (SmryTbl\[i\].parentNode.cells\[4\].innerHTML == filter_tool || filter_tool == \"all\")) {"
Write_HTML "\t\t\t\tSmryTbl\[i\].parentNode.style.display = '';"
Write_HTML "\t\t\t} else {"
Write_HTML "\t\t\t\tSmryTbl\[i\].parentNode.style.display = 'none';"
Write_HTML "\t\t\t}"
Write_HTML "\t\t}"
Write_HTML "\t}"
Write_HTML "</script>"
#End script section
Write_HTML "</body>"
Write_HTML "</html>"
#Closing crd_abutment_report.html
close $HTML_Fid
puts "\nINFO: Script finished."

################################################################################
# No Linting Area
################################################################################

# nolint Main
