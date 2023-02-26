#!/depot/tcl8.6.6/bin/tclsh

######################################
# Auto setup checklist (Mantis: 0022915)
# Description: 
# Collects data and cross-checks environment setup parameters including tool versions, spice models, global corners, std cell IRL, etc. 
# Provides pcs, bbsim, and latest tool versions for tech leads.
# Excel spreadsheet path: https://sp-sg/sites/msip-eddr/proj/eddra/ckt/Shared%20Documents/Golden%20Reference%20All%20Hard%20Macro%20Families/Working_Docs/Initial%20Setup%20Auto%20Checklist/Setup_Check_v1.1.xlsm
#
# Sample Command
# ude3 --projectType ddr43 --projectName d524-ddr43-ss14lpp18 --releaseName rel1.00 --metalStack 10M_3Mx_4Cx_2Kx_1Gx_LB --command "source /slowfs/us01dwt2p278/alpha/alpha_common/bin/setupCheck.tcl"
#
# Contact: Rishabh Pathak rishabp@synopsys.com
# 
# Revision History:
# Version | Date | Who | What
# 2.0 | 08/2017 | mengdih | Updated bbSim HSpice version and SPICE path checks; Added checks for HSpice/FineSim/SiS latest versions.
#
########################################
package require try         ;# Tcllib.
#package require cmdline 1.5 ;# First version with proper error-codes.
#package require fileutil

#set DEBUG      0
#set VERBOSITY  0
#set STDOUT_LOG ""
#set AUTHOR     "Manmit Muker (mmuker), Patrick Juliano (juliano), Alvaro Quintana Carvacho"
#set RealBin [file dirname [file normalize [info script]] ]
#set RealScript [file tail [file normalize [info script]] ]
#set PROGRAM_NAME $RealScript
#set LOGFILE "[pwd]/$PROGRAM_NAME.log"

# Declare cmdline opt vars here, so they are global
#set opt_fast ""
#set opt_test ""
#set opt_help ""
#set opt_project ""

#lappend auto_path "$RealBin/../lib/tcl"
#package require Messaging 1.0
#namespace import ::Messaging::*
##package require Misc 1.0
#namespace import ::Misc::*

#proc Main {sisversion} {
#array set argsArray $argv
puts "$stablesis"
puts "$stablent"
#set argErr 0
#    if { [ info exists argsArray(-stablesis) ] } {
#	set stablesis $argsArray(-stablesis)
#    } else {
#	puts "Error:  Required arg \"stablesis\" missing"
#	set argErr 1
#    }
proc uniqueList {list} {
  set new {}
  foreach item $list {
    if {[lsearch $new $item] < 0} {
      lappend new $item
    }
  }
  return $new
}
    set CSV [open ~/trial.csv w]
    set LOG [open ~/out.csv w]
    set logfile [open ~/autosetup.log w]
    puts $CSV "check,,timing setup,status,"
    puts $logfile "check,,timing setup,status,"
    puts "Comparison check \n"
    ##reading commonsetup.tcl script as per jira: P10020416-37188
    set commonsetup "//wwcad/msip/projects/$env(MSIP_PRODUCT_NAME)/$env(MSIP_PROJ_NAME)/$env(MSIP_REL_NAME)/design/timing/sis\*/common_source/commonSetup.tcl"
    #set valid [catch {exec p4 print -o snehar_commonsetup.tmp $commonsetup}]
    #if {!$valid} {    
        set cin [open "snehar_commonsetup.tmp" "r"]
        while {[gets $cin line] >= 0} {
            if {[regexp -line {^set siliconsmartVersion\s*(.+)$} $line -> sisver]} {}
            if {[regexp -line {^set finesimVersion\s*(.+)$} $line -> fmver]} {}
            if {[regexp -line {^set hspiceVersion\s*(.+)$} $line -> hspicever]} {}
        }
    #}else { puts "\"commonSetup.tcl setup file does not exist. Source: $commonsetup\""}

    #HSpice - pcs version
    set hspicestatus "FAIL"
    if {[info exists ::env(MSIP_HSPICE_VERSION)]} {
        set udehspice "$env(MSIP_HSPICE_VERSION)"
        puts $logfile "ude hspice version: $hspicever"
        puts $logfile "common setup hspice version: $udehspice"
        puts $LOG "$udehspice"
        if {[string equal $hspicever $udehspice]} {
            set hspicestatus "PASS"
        }
    } else {puts $LOG "\"HSpice version not found in PCS\""}
    puts $CSV "Comparison of Hspice ude version with timing setup,$udehspice,$hspicever,$hspicestatus"
    puts "Comparison of Hspice ude version with timing setup,$udehspice,$hspicever,$hspicestatus"

    set shellScript "load.csh"
    set SCR [open $shellScript w]
    puts $SCR "\#!/bin/csh"
    puts $SCR "module unload hspice"
    puts $SCR "module load hspice"
    puts $SCR "echo | which hspice"
    puts $SCR "module unload finesim"
    puts $SCR "module load finesim"
    puts $SCR "echo | which finesim"
    puts $SCR "module unload siliconsmart"
    puts $SCR "module load siliconsmart"
    puts $SCR "echo | which siliconsmart"
    puts $SCR "exit"
    close $SCR
    file attributes $shellScript -permissions "+x"
    catch {exec "./$shellScript"} out
    set output [split $out "\n"]
    foreach line $output {
        if {[regexp -nocase {hspice_([a-zA-Z0-9.-]*[^/])} $line -> verHS]} {
            puts $LOG "$verHS"
            set flagHS 1
        }
        if {[regexp -nocase {finesim_([a-zA-Z0-9.-]*[^/])} $line -> verFS]} {set flagFS 1}

        if {[regexp -nocase {siliconsmart_([a-zA-Z0-9.-]*[^/])} $line -> verSiS]} {set flagSiS 1}

    }
    #if [file exists $shellScript] {file delete $shellScript}
    if {!$flagHS} {puts $LOG "\"HSpice latest version not found.\""} 

    ##HSpice - bbsim
    set bbSimSetup "//wwcad/msip/projects/$env(MSIP_PRODUCT_NAME)/$env(MSIP_PROJ_NAME)/latest/design/sim/share/bbSim/bbSim.setup"
    set flagHS1 0
    set flagFS1 0
    set invalid [catch {exec p4 print -o simSetup.tmp $bbSimSetup}]
    #set invalid 0
    if {!$invalid} {
        
        set fIn [open "simSetup.tmp" "r"]
        set bbsimhspicestat "FAIL"    
        while {[gets $fIn line] >= 0} { 
            if {[regexp -nocase {^ENV\s*MSIP_HSPICE_VERSION\s*(.+)$} $line -> verHS1]} {
                if {[string equal $hspicever $verHS1]} {
                    set bbsimhspicestat "PASS"
                }
                puts $LOG "$verHS1"
                puts $logfile "HSpice bbSim version: $verHS1"
                puts $CSV "Comparison of HSpice version bbsim setup with timing setup,$verHS1,$hspicever,$bbsimhspicestat"
                puts "Comparison of HSpice version bbsim setup with timing setup,$verHS1,$hspicever,$bbsimhspicestat"
                set flagHS1 1
            }
            set bbsimfmstat "FAIL"
            if {[regexp -nocase {^ENV\s*MSIP_FINESIM_VERSION\s*(.+)$} $line -> verFS1]} {
                if {[string equal $fmver $verFS1]} {
                    set bbsimfmstat "PASS"
                }
                
                puts $CSV "Comparison of finesim version bbsim setup with timing setup,$verFS1,$fmver,$bbsimfmstat"
                puts "Comparison of finesim version bbsim setup with timing setup,$verFS1,$fmver,$bbsimfmstat"
                set flagFS1 1}
        }
        close $fIn
    } else { puts "\"bbSim setup file does not exist. Source: $bbSimSetup\""}

    if {!$flagHS1} {puts $LOG "\"bbSim HSpice version not found. Source: $bbSimSetup\""}
    

    ##FineSim - pcs version
    set fmstatus "FAIL"
    if {[info exists ::env(MSIP_FINESIM_VERSION)]} {
        set pcsfmver $env(MSIP_FINESIM_VERSION)
        puts $LOG $pcsfmver
        if {[string equal $fmver $pcsfmver]} {
            set fmstatus "PASS"
        }
    } else {puts $LOG "\"FineSim version not found in PCS\""}
    puts $logfile "\nude finesim version: $pcsfmver"
    puts $logfile "common setup finesim version: $fmver"
    puts $logfile "Finesim bbSim version: $verFS1"
    puts $CSV "Comparison of finesim ude version with timing setup,$pcsfmver,$fmver,$fmstatus"
    puts "Comparison of finesim ude version with timing setup,$pcsfmver,$fmver,$fmstatus"

    ##FineSim - latest version
    if {$flagFS} {
        puts $LOG "$verFS"
    } else {puts $LOG "\"FineSim latest version not found.\""}


    ##FineSim- bbsim
    if {$flagFS1} {
        puts $LOG "$verFS1"
    } else {puts $LOG "\"FineSim bbSim version not found. Source: $bbSimSetup\""}

    ##SPICE - path
    if {[file exists $env(MSIP_PROJ_ENV_PATH)/models/hspice_mc]} {
        puts $LOG $env(MSIP_PROJ_ENV_PATH)/models/hspice_mc
    } elseif {[file exists $env(MSIP_PROJ_ENV_PATH)/models/hspice]} {
        puts $LOG $env(MSIP_PROJ_ENV_PATH)/models/hspice
    } else {
        puts $LOG "\"Error:  Missing either of required directory $env(MSIP_PROJ_ENV_PATH)/models/hspice_mc or $env(MSIP_PROJ_ENV_PATH)/models/hspice\""
    }
    ##SPICE - matches bbsim
    #set l [glob -nocomplain -directory $env(PROJ_HOME)/design/sim "*/corners/*/*.corners"]
    #puts "$env(PROJ_HOME)/design/sim */corners/*.corners"
    set l [glob -nocomplain -directory $env(PROJ_HOME)/design/sim "*/corners/*.corners"]
    #puts $LOG "\$l is $l"
    set first [lindex $l 0]
    if {[file exists $first]} {
        set inFile [open $first "r"]
        set existsfile 1
        if {[info exists ::env(MSIP_PROJECT_ROOT)]} {
            set pattern1 $env(MSIP_PROJECT_ROOT)/$env(MSIP_PRODUCT_NAME)/$env(MSIP_PROJ_NAME)/$env(MSIP_REL_NAME)/cad/models/hspice_mc/*.lib
            puts $pattern1
        } elseif {[info exists ::env(MSIP_PROJ_ROOT)]} {
            set pattern1 $env(MSIP_PROJ_ROOT)/$env(MSIP_PRODUCT_NAME)/$env(MSIP_PROJ_NAME)/$env(MSIP_REL_NAME)/cad/models/hspice_mc/.*lib
        #    puts $LOG "$pattern1"
            set pattern $env(MSIP_PROJ_ROOT)/$env(MSIP_PRODUCT_NAME)/$env(MSIP_PROJ_NAME)/$env(MSIP_REL_NAME)/cad/models/hspice/.*lib
        #    puts $LOG "$pattern"
        } else {puts $LOG "\"env(MSIP_PROJECT_ROOT) or env(MSIP_PROJ_ROOT) not found in PCS/CCS.\""; exit 1}
        #set pattern $env(MSIP_PROJECT_ROOT)/$env(MSIP_PRODUCT_NAME)/$env(MSIP_PROJ_NAME)/$env(MSIP_REL_NAME)/cad/models/hspice/.*lib
        #set pattern1 $env(MSIP_PROJ_ROOT)/$env(MSIP_PRODUCT_NAME)/$env(MSIP_PROJ_NAME)/$env(MSIP_REL_NAME)/cad/models/hspice/.*lib
        set flagSP 0
        while {[gets $inFile line] >= 0} {
            if {[regexp -nocase $pattern1 $line]} {
                puts $LOG "\"SPICE model matches bbsim\""
                set flagSP 1
                break
            } elseif {[regexp -nocase $pattern $line]} {
                puts $LOG "\"SPICE model matches bbsim\""
                set flagSP 2
                break
            }
        } 
        
        
        if {!$flagSP} {
            if {[info exists ::env(MSIP_PROJECT_ROOT)]} {
                set pattern $env(MSIP_PROJECT_ROOT)/$env(MSIP_PRODUCT_NAME)/$env(MSIP_PROJ_NAME)/$env(MSIP_REL_NAME)/cad/models/hspice/.*lib
            } elseif {[info exists ::env(MSIP_PROJ_ROOT)]} {
                set pattern $env(MSIP_PROJ_ROOT)/$env(MSIP_PRODUCT_NAME)/$env(MSIP_PROJ_NAME)/$env(MSIP_REL_NAME)/cad/models/hspice/.*lib
            }
            set flagSP 0
            if {[info exists $inFile]} {
                while {[gets $inFile line] >= 0} {
                    if {[regexp -nocase $pattern $line]} {
                        puts $LOG "\"SPICE model matches bbsim\""
                        set flagSP 1
                        break
                    } elseif {[regexp -nocase $pattern1 $line]} {
                        puts $LOG "\"SPICE model matches bbsim\""
                        set flagSP 2
                        break
                    }
                }
            }
        }
        close $inFile
        if {!$flagSP} {
            puts $LOG "\"bbsim SPICE model does not match $pattern1 or $pattern\""
        }
    } else {
        puts $LOG "Error: Corner file not found in $env(PROJ_HOME)/design/sim"
        set existsfile 0
    }





    #SiS - version
    set sisstatus "FAIL"
    if {$flagSiS} {
        puts $LOG "$verSiS"

    } else {puts $LOG "\"SiS latest version not found.\""}
    if {[info exists ::env(MSIP_SIS_VERSION)]} {
        set udesisver $env(MSIP_SIS_VERSION)
        if {[string equal $sisver $udesisver]} {
            set sisstatus "PASS"
        }
    puts $logfile "\nsis verison in ude: $sisver"
    puts $logfile "sis verison in common setup: $udesisver"
    puts $CSV "Comparison of sis ude version with timing setup,$udesisver,$sisver,$sisstatus"
    puts "Comparison of sis ude version with timing setup,$udesisver,$sisver,$sisstatus"
    
    #SiS stable version
    set sisstablecheck "FAIL"
    if {[string equal $sisver $stablesis]} {
            set sisstablecheck "PASS"
    }
    puts $CSV "Comparison of sis stable version with timing setup,$stablesis,$sisver,$sisstablecheck"
    puts "Comparison of sis stable version with timing setup,$stablesis,$sisver,$sisstablecheck"

    #SiS - global corners
    set gCornerS 0
    set fileExists 0
    set sisglobcorner "FAIL"
    set pvtfilestatus "FAIL"
    set projdetails [split  $env(MSIP_PROJ_NAME) "-"]
    set projname [lindex $projdetails 0]
    set found_hspice_line 0
    #set pathS [glob -nocomplain -directory $env(PROJ_HOME)/design/timing/sis/common_source/ "SiS_configure_*_pvt.tcl"]
    #set pathPCS [glob -nocomplain -directory $env(PROJ_HOME)/pcs/design/timing/sis/common_source/ "SiS_configure_*_pvt.tcl"]
    set pathS [glob -nocomplain -directory /remote/proj/$env(MSIP_PRODUCT_NAME)/$env(MSIP_PROJ_NAME)/$env(MSIP_REL_NAME)/design/timing/sis/ "SiS_configure_${projname}_pvt.tcl"]
    set pathPCS [glob -nocomplain -directory /remote/proj/$env(MSIP_PRODUCT_NAME)/$env(MSIP_PROJ_NAME)/$env(MSIP_REL_NAME)/pcs/design/timing/sis/ "SiS_configure_${projname}_pvt.tcl"]
    set product $env(MSIP_PRODUCT_NAME)
    if {[file exists $pathS]} {
        set fileExists 1
        set configurefile $pathS
    } elseif {[file exists $pathPCS]}  {
        set fileExists 1
        set configurefile $pathPCS
        
    }

    if {[$fileExists == 1]} {        
        set pvtfilestatus "PASS"
        set inFile [open $configurefile "r"]
        while {[gets $inFile line] >= 0} {
            set fileExists 1
            if {[regexp -nocase {ssg|ffg|psss|pfff} $line]} {
                set gCornerS 1
                set sisglobcorner "PASS"
            }
            if {[regexp  -line -nocase {^\s*\{\.lib\s*\"(.*hspice_mc)} $line -> mc]} { set found_hspice_line 1 }
        }  
        close $inFile

    }
   
     
    if {$gCornerS && $fileExists} {
        puts $LOG "\"global corners\""
        } elseif {!$fileExists} {
            puts $LOG "\"File does not exist SiS_configure_*_pvt.tcl\""
        } else {puts $LOG "\"Not global corners\""}
        
    #SiS - softlinked
    set sisLinked 1
    set sisLinkedstat "FAIL"
    foreach f [glob -nocomplain -directory $env(PROJ_HOME)/design/timing/sis/common_source/ "*"] {
        if {[file type $f] != "link"} {
            set sisLinked 0 
            # uncomment line below to check unlinked files
            # puts -nonewline $LOG "\"$f - type is [file type $f]\""
        }
    }
    if {$sisLinked} {
        puts $LOG "softlinked"
        set sisLinkedstat "PASS"
    } else {puts $LOG "\"Warning: some SiS files are not softlinked\""}

    set hspice_mc_status "FAIL"
    set hspice_mc_path "/remote/proj/$env(MSIP_PRODUCT_NAME)/$env(MSIP_PROJ_NAME)/$env(MSIP_REL_NAME)/cad/models/hspice_mc"
    if {[file exists "$hspice_mc_path"] && [$found_hspice_line == 1]} {
        puts $logfile "hspic_mc path: $hspice_mc_path"
        puts $logfile "SiS pvt hspice_mc path: $mc"
        if {[string equal $hspice_mc_path $mc]} { set hspice_mc_status "PASS" }
    }
    puts "Comparison of spice model path in PCS with SiS setup,$hspice_mc_path,$mc,$hspice_mc_status"
    puts $CSV "Comparison of spice model path in PCS with SiS setup,$hspice_mc_path,$mc,$hspice_mc_status"




    
    #NT - version 
    set fileExists 0
    set gCornerN 0
    set ntfilexiststat "FAIL"
    set ntglobalcorners "FAIL"
    set ntfilverstat "FAIL"
    set nt_hpice_mc_status "FAIL"
    set ntconfig "$env(PROJ_HOME)/design/timing/nt/ntFiles/alphaNT.config"
    set ntconfigPCS "$env(PROJ_HOME)/pcs/design/timing/nt/ntFiles/alphaNT.config"
    set createliststd {}
    if {[file exists $ntconfig]} {
        set fileExists 1
        set ntfilename $ntconfig
    } elseif {[file exists $ntconfigPCS]} {
        set fileExists 1
        set ntfilename $ntconfigPCS
    }
    if {[$fileExists == 1]} {
        set ntfilexiststat "PASS"
        puts $logfile "Config file used in nt: $ntfilename\n"
        set inFile1 [open "$ntfilename" "r"]
        while {[gets $inFile1 line] >= 0} {
            set fileExists 1
            if {[regexp -nocase {ntVersion} $line]} {
                if {[regexp {^#.*} $line ]} {
                } else {
                    set ntverconfig [lindex $line end]
                puts $LOG [lindex $line end]
                #break
                }
            }
            if {[regexp -nocase {^set\s*modelDir\s*(.*)$} $line -> config_mc]} {
                puts $logfile "Hspice_mc in alphaNT.config: $config_mc" }
                     
            if { [regexp -nocase {^lappend\s*stdCellLibList\s*.*stdcell\/(.*)$} $line -> std] } { 
                set l4 [split $std "\/"]
                set firststdindex [lindex $l4 0]
                set secondstdindex [lindex $l4 1]
                lappend createliststd "$firststdindex/$secondstdindex"
                #get IRL
            }
            if {[regexp -nocase {ssg|ffg|psss|pfff} $line]} {
                set gCornerN 1
                set ntglobalcorners "PASS"
            }
        }  
        close $inFile1
    
    } else {
        puts $LOG "\"Error:  Missing required file alphaNT.config\""
        puts $logfile "\"Error:  Missing required file alphaNT.config\""
    }
    
    ##nt hspice_mc check
    set hspice_mc_path_nt "\$PROJ_HOME/cad/models/hspice_mc"
    if {[string equal $config_mc $hspice_mc_path_nt]} { set nt_hpice_mc_status "PASS"}
    puts "Comparison of hspice_mc in pcs w.r.t alphaNT.config,$hspice_mc_path_nt,$config_mc,$nt_hpice_mc_status"
    puts $CSV "Comparison of hspice_mc in pcs w.r.t alphaNT.config,$hspice_mc_path_nt,$config_mc,$nt_hpice_mc_status"
    #NT version check 
    if {[info exists ::env(MSIP_NT_VERSION)]} {
        set udentver "nt/$env(MSIP_NT_VERSION)"
        if {[string equal $ntverconfig $udentver]} {
            set ntfilverstat "PASS"
        }    
    }
    puts $logfile "\nnt verison in ude: $udentver"
    puts $logfile "nt version in common alphaNT.config: $ntverconfig"
    puts $CSV  "Comparison of NT ude version with timing setup,$udentver,$ntverconfig,$ntfilverstat"
    puts "Comparison of NT ude version with timing setup,$udentver,$ntverconfig,$ntfilverstat"
    

    #nt stable version
    set ntstablecheck "FAIL"
    if {[string equal $ntverconfig $stablent]} {
            set ntstablecheck "PASS"
    }
    puts $CSV "Comparison of NT stable version with timing setup,$stablent,$ntverconfig,$ntstablecheck"
    puts "Comparison of NT stable version with timing setup,$stablent,$ntverconfig,$ntstablecheck"


    set createlistirl {}
    set IRLstatus "FAIL"
    if {[file exists $libdef]} {
        puts $logfile "lib.def found here: $libdef"
        set libdefin [open "$libdef" "r"]
        while {[gets $libdefin line] >= 0} {
                if {[regexp -line {^DEFINE\s*.*\s*(IRL[a-zA-Z0-9].*)$} $line -> irlval]} {
                    set l5 [split $irlval "\/"]
                    set firstindex [lindex $l5 0]
                    set secondindex [lindex $l5 1]
                    lappend createlistirl "$firstindex/$secondindex"
            }
        }
    
    set uniqlistirl [lsort -unique $createlistirl]
    puts $logfile "\nirl in lib.def: $uniqlistirl"
    set i [llength $uniqlistirl]
    set uniqliststd [lsort -unique $createliststd]
#   set uniqliststd_proc [uniqueList $createliststd]
    puts $logfile "std in config:$uniqliststd"
    set j [llength $uniqliststd]
    set difference [ListComp $uniqlistirl $uniqliststd]
} else { puts $logfile "Error: lib.def doesnot exist in path : $libdef" }

#    set difference ""
if {[llength $difference]} {
    set IRLstatus "FAIL"
} else { set IRLstatus "PASS" }

    puts $CSV "Comparison of STD cell IRL in lib.def wrt timing setup,,,$IRLstatus"
    puts "Comparison of STD cell IRL in lib.def wrt timing setup,,,$IRLstatus"

################################################################################# existence ###########################################################################################


puts $CSV "\n\n\nExistence check"
puts "\nExistence check"
#    puts $CSV "\n\n\nExistence of SiS file corner,,,$sisglobcorner"
#    puts "Existence of SiS file corner,,,$sisglobcorner"
        
    #NT - global corners
    if {$fileExists && $gCornerN} {
        puts $LOG "\"global corners\""
        } else {puts $LOG "\"Not global corners\""}
        puts $CSV  "Existence of global setup files in NT,,,$ntglobalcorners"
        puts "Existence of global setup files in NT,,,$ntglobalcorners"
    #NT - softlinked
    set ntLinked 1
    set ntsoftlinkstat "FAIL"
    foreach f [glob -nocomplain -directory $env(PROJ_HOME)/design/timing/nt/ntFiles "*"] {
        if {[regexp -nocase {alphaNT.*config*} $f]} {
            continue
        }
        if {[file type $f] != "link"} {
            set ntLinked 0
            puts -nonewline $LOG "\"$f - type is [file type $f]\""
#            set ntsoftlinkstat "PASS $f"
        }
    }
    if {$ntLinked} {
        puts $LOG "softlinked"
        set ntsoftlinkstat "PASS"
    }
    puts $CSV "Are NT file softlinked (except for alphaNT.config),,,$ntsoftlinkstat"
    puts "Are NT file softlinked (except for alphaNT.config),,,$ntsoftlinkstat"
        #PV - version 
        if {[info exists ::env(MSIP_CD_PV)]} {
            regexp -nocase {pv/(\d+.*)} $env(MSIP_CD_PV) -> ver
            puts $LOG "$ver" 
        } else { puts $LOG "PV version not found in PCS" } 


    #ICV - version 
    if {[info exists ::env(MSIP_ICV_VERSION)]} {
        puts $LOG $env(MSIP_ICV_VERSION)
#    puts $CSV "ICV version,latest,$env(MSIP_ICV_VERSION),need discussion"
    } else {puts $LOG "ICV version not found in PCS"}
    

    #STAR_RCXT - version
    if {[info exists ::env(MSIP_STARRCXT_VERSION)]} {
        puts $LOG $env(MSIP_STARRCXT_VERSION)
    } else {puts $LOG "STARRCXT version not found in PCS"}

        puts $LOG "Not checking BDL anymore."

     puts "Existence of sis pvt file,$configurefile,,$pvtfilestatus"
   puts $CSV "Existence of sis pvt file,$configurefile,,$pvtfilestatus"
        
    #Timing PCS area
    set timingpcsstatus "PASS"
    if {[file exists /remote/proj/$env(MSIP_PRODUCT_NAME)/$env(MSIP_PROJ_NAME)/$env(MSIP_REL_NAME)/design/timing]} {
        set timing_path /remote/proj/$env(MSIP_PRODUCT_NAME)/$env(MSIP_PROJ_NAME)/$env(MSIP_REL_NAME)/design/timing
        puts $LOG $timing_path
    } elseif {[file exists $env(PROJ_HOME)/pcs/design/timing]} {
        set timing_path $env(PROJ_HOME)/pcs/design/timing
        puts $LOG $timing_path
    } elseif {[file exists $env(PROJ_HOME)/design/timing_ew]} {
        set timing_path $env(PROJ_HOME)/design/timing_ew
        puts $LOG $timing_path
    } elseif {[file exists $env(PROJ_HOME)/pcs/design/timing_ew]} {
        set timing_path $env(PROJ_HOME)/pcs/design/timing_ew
        puts $LOG $timing_path
    } else {
        puts $LOG "\"Error:Missing required directory $env(PROJ_HOME)/pcs/design/timing\""
        puts $LOG '-'
        set timingpcsstatus "FAIL"
    }
    puts $CSV "Are SiS file softlinked,$env(PROJ_HOME)/design/timing/sis/common_source/,,$sisLinkedstat"
    puts "Are SiS file softlinked,$env(PROJ_HOME)/design/timing/sis/common_source/,,$sisLinkedstat"
    puts $CSV "Existence of timing PCS directory,$timing_path,,$timingpcsstatus"
    puts "Existence of timing PCS directory,$timing_path,,$timingpcsstatus"
    puts $CSV  "Existence of Global nt config file,$ntfilename,,$ntfilexiststat"
    puts  "Existence of Global nt config file,$ntfilename,,$ntfilexiststat"

    #Bbox List
    set bboxpathstatus "PASS"
    if {[file exists /remote/proj/$env(MSIP_PRODUCT_NAME)/$env(MSIP_PROJ_NAME)/$env(MSIP_REL_NAME)/design/bboxList.txt]} {
        set bbox_path "/remote/proj/$env(MSIP_PRODUCT_NAME)/$env(MSIP_PROJ_NAME)/$env(MSIP_REL_NAME)/design/bboxList.txt"
        puts $LOG "$bbox_path"    
    } elseif {[file exists $env(PROJ_HOME)/design/bboxList.txt]} {
        set bbox_path $env(PROJ_HOME)/design/bboxList.txt
        puts $LOG "$bbox_path"    
    } elseif {[file exists /remote/proj/$env(MSIP_PRODUCT_NAME)/$env(MSIP_PROJ_NAME)/$env(MSIP_REL_NAME)/pcs/design/bboxList.txt]} {
        set bbox_path /remote/proj/$env(MSIP_PRODUCT_NAME)/$env(MSIP_PROJ_NAME)/$env(MSIP_REL_NAME)/pcs/design/bboxList.txt
        puts $LOG "$bbox_path"    
    } elseif {[file exists $env(PROJ_HOME)/pcs/design/bboxList.txt]} {
        set bbox_path $env(PROJ_HOME)/pcs/design/bboxList.txt
        puts $LOG "$bbox_path"    
    } elseif {[file exists /remote/proj/$env(MSIP_PRODUCT_NAME)/$env(MSIP_PROJ_NAME)/$env(MSIP_REL_NAME)/design_unrestricted/bboxList.txt]} {
        set bbox_path /remote/proj/$env(MSIP_PRODUCT_NAME)/$env(MSIP_PROJ_NAME)/$env(MSIP_REL_NAME)/design_unrestricted/bboxList.txt
        puts $LOG "$bbox_path"    
    } elseif {[file exists $env(PROJ_HOME)/design_unrestricted/bboxList.txt]} {
        set bbox_path $env(PROJ_HOME)/design_unrestricted/bboxList.txt
        puts $LOG "$bbox_path"    
    } elseif {[file exists /remote/proj/$env(MSIP_PRODUCT_NAME)/$env(MSIP_PROJ_NAME)/$env(MSIP_REL_NAME)/pcs/design_unrestricted/bboxList.txt]} {
        set bbox_path /remote/proj/$env(MSIP_PRODUCT_NAME)/$env(MSIP_PROJ_NAME)/$env(MSIP_REL_NAME)/pcs/design_unrestricted/bboxList.txt
        puts $LOG "$bbox_path"    
    } elseif {[file exists $env(PROJ_HOME)/pcs/design_unrestricted/bboxList.txt]} {
        set bbox_path $env(PROJ_HOME)/pcs/design_unrestricted/bboxList.txt
        puts $LOG "$bbox_path"    
    }  else {
        puts $LOG "\"Error: Missing required file bboxList.txt\""
        set bbox_path "-"
        set bboxpathstatus "FAIL"
    }
    puts $CSV "Existence of bboxList.txt file,$bbox_path,,$bboxpathstatus"
    puts "Existence of bboxList.txt file,$bbox_path,,$bboxpathstatus"
    close $LOG
    close $CSV
    close $logfile

proc compare_lists {lst1 lst2 added_el_lst removed_el_lst} {
    upvar $added_el_lst added_lst
    upvar $removed_el_lst removed_lst
    array unset arr
    foreach n $lst1 {
        set arr($n) 0
    }
    foreach n $lst2 {
        if {[info exists arr($n)]} {
            set arr($n) 1
        } else {
            lappend added_lst $n
        }
    }
    foreach n [array names arr] {
        if {$arr($n) == 0} {
            lappend removed_lst $n
        }
    }
}


proc ListComp { List1 List2 } {
   set DiffList {}
   foreach Item $List1 {
      if { [ lsearch -exact $List2 $Item ] == -1 } {
         lappend DiffList $Item
      }
   }
   foreach Item $List2 {
      if { [ lsearch -exact $List1 $Item ] == -1 } {
         if { [ lsearch -exact $DiffList $Item ] == -1 } {
            lappend DiffList $Item
         }
      }
   }
   return $DiffList
}

proc uniqueList {list} {
  set new {}
  foreach item $list {
    if {[lsearch $new $item] < 0} {
      lappend new $item
    }
  }
  return $new
}
    ##exit -force 1
#}

#try {
#    utils__script_usage_statistics $PROGRAM_NAME $VERSION
#    header 
#    set exitval [Main]
#} on error {results options} {
#    set exitval [fatal_error [dict get $options -errorinfo]]
#} finally {
#    footer
#    write_stdout_log $LOGFILE
#}

# nolint Main
# nolint utils__script_usage_statistics
    #
    #
    #
    #
    #
#

