#!/depot/tcl8.6.3/bin/tclsh8.6


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

package require try
lappend auto_path "$RealBin/../lib/tcl"
package require Messaging 1.0
namespace import ::Messaging::*
package require Misc 1.0
namespace import ::Misc::*

variable args

proc logMsg {fp msg} {
	puts $msg
	if {$fp == "-" } {return "" }
	puts $fp $msg
}

proc readNetlistInstancesLine {line} {

	set id [string tolower [lindex $line 0]]
	if {[string index $id 0] == "x"} {
		set ports ""
		foreach tok [lreplace $line 0 0] {
			if {[string first "=" $tok] == -1} {lappend ports $tok}
		}
		set cellName [lindex $ports end]
		set ::cellInstances($cellName) 1
	}
}


proc readNetlistInstances {netlist} {
	##  Checks the ports (subckt and instance) against the ports as defined in the spiceNetlist
	if {![file exists $netlist]} {
		logMsg - "Error: checkExtractedNetlistPorts cannot open $netlist\n"
		return
	}

	set IN [open $netlist r]
	set bfr ""
	while {[gets $IN line] >= 0} {
		set line [string trimleft $line]
		if {[string index $line 0] == "+"} {
			## Continuation line
			append bfr " [string range $line 1 end]"
		} else {
			##  New line
		    readNetlistInstancesLine $bfr
			set bfr "$line"
		}
	}
	readNetlistInstancesLine $bfr
	close $IN
}

proc checkConfig {netlist} {
	#  Checks netlist for instances of all cells in the config file.
	if [info exists ::runExtractType] {
		if {$::runExtractType != "selectedNets"} {
			return "Info:  Not bbox extract; Skipping instance check\n"
		}
	} else {
		return "Info:  Restart your ude session to enable reliable runExtract type recognition"
	}
	set output "Info:  Checking bbox cells in $netlist\n"
	array unset ::cellInstances
	readNetlistInstances $netlist
	# [array names ::cellInstances]

	if [info exists ::extrPreservedEquivFile] {
		set bboxCells ""
		if [file exists $::extrPreservedEquivFile] {
			set fp [open $::extrPreservedEquivFile r]
			set s [gets $fp bboxCells]
			close $fp
		} else {
			append output "Error:  $::extrPreservedEquivFile missing\n"
			return $output
		}
	} elseif [info exists ::blackBoxConfigFile] {
		set bboxCells ""
		if [file exists $::blackBoxConfigFile] {
			set fp [open $::blackBoxConfigFile r]
			while {[gets $fp bbc] >= 0} {lappend bboxCells $bbc}
			close $fp
		} else {
			append output "Error:  $::extrPreservedEquivFile missing\n"
			return $output
		}
	} else {
		append output  "Error: Black-box extract but no config found. Tell John\n"
		return $output
	}

	foreach cellName $bboxCells {
		if {[info exists ::cellInstances($cellName)]} {
			append output "\tInfo:  Instance of $cellName found\n"
		} else {
			append output "\tError:  Instance of $cellName missing\n"
			set ::success 0
		}
	}

	return $output
}


proc checkRequiredArg {argName OK_in} {
	global args
	if [info exists args($argName)] {return $OK_in} else {
		puts "Error:  Missing required arg \"$argName\""
		return false
	}
}


proc runBboxNetlistqa {rundir refTime netlist configFile stdcell xtGroundNode xTypes xtPowerExtract xReduction xTempSens xtPowerNets} {
    set oldLog "$rundir/bbox_netlist_qa.pl.log"
    set oldLogExists [file exists $oldLog]
    if {$oldLogExists} {
        set mtimeLogs [file mtime $oldLog]
        if {$mtimeLogs < $refTime} {
            file delete $oldLog
            set oldBboxLog "$rundir/bbox_qa.log"
            file delete $oldBboxLog 
            set oldExtrLog "$rundir/extraction_qa.log"
            file delete $oldExtrLog
            set oldCompareLog "$rundir/stdcell_compare.log"
            file delete $oldCompareLog
        }
    }
    set run_cmd "bbox_netlist_qa.pl"
    append run_cmd " -config $configFile"
    append run_cmd " -netlist $netlist"
    if {$xtGroundNode != ""} {
        append run_cmd " -xtGroundNode \'$xtGroundNode\'"
    }
    if {$xTypes != ""} {
        append run_cmd " -xTypes $xTypes"
    }
    if {$xtPowerExtract != ""} {
        append run_cmd " -xtPowerExtract \'$xtPowerExtract\'"
    }
    if {$xReduction != ""} {
        append run_cmd " -xReduction $xReduction"
    }
    if {$xTempSens != ""} {
        append run_cmd " -xTempSens $xTempSens"
    }
    if {$xtPowerNets != ""} {
        append run_cmd " -xtPowerNets \'$xtPowerNets\'"
    }
    append run_cmd " -stdcell $stdcell"
    set cmd "bash -c \"source ~/.bashrc;cd $rundir; module unload ddr-utils-timing; module load ddr-utils-timing; $run_cmd\""
    lassign [run_system_cmd "$cmd"] stdout1 stderr1 status1
}


proc submitBboxNetlist {newdir ogNetlist netlistName} {
    file mkdir $newdir
    set copiedNetlist "$newdir/$netlistName"
    set nlHaveCmd ""
    catch {set nlHaveCmd [exec p4 have $copiedNetlist]}
    if {$nlHaveCmd == ""} {
        exec cp $ogNetlist $copiedNetlist
        exec p4 add $copiedNetlist
    } else {
        catch {exec p4 sync $copiedNetlist}
        exec p4 edit $copiedNetlist
        exec cp $ogNetlist $copiedNetlist
    }
    catch {exec p4 submit -d 'Submit extracted black-box netlist' $copiedNetlist}
}


proc submitBboxqaFiles {qadir rundir} {
    file mkdir $qadir
    set logDir $rundir
    set bboxLog "$logDir/bbox_qa.log"
    set extrLog "$logDir/extraction_qa.log"
    set compareLog "$logDir/stdcell_compare.log"
    set copiedbboxLog "$qadir/bbox_qa.log"
    set copiedextrLog "$qadir/extraction_qa.log"
    set copiedcompareLog "$qadir/stdcell_compare.log"

    if {[file exists $bboxLog]} {
        set bboxqaHaveCmd ""
        catch {set bboxqaHaveCmd [exec p4 have $copiedbboxLog]}
        if {$bboxqaHaveCmd == ""} {
            exec cp $bboxLog $copiedbboxLog
            exec p4 add $copiedbboxLog
        } else {
            catch {exec p4 sync $copiedbboxLog}
            exec p4 edit $copiedbboxLog
            exec cp $bboxLog $copiedbboxLog
        }
        catch {exec p4 submit -d 'Submit bbox_qa.log' $copiedbboxLog}
    }
    if {[file exists $extrLog]} {
        set extrHaveCmd ""
        catch {set extrHaveCmd [exec p4 have $copiedextrLog]}
        if {$extrHaveCmd == ""} {
            exec cp $extrLog $copiedextrLog
            exec p4 add $copiedextrLog
        } else {
            catch {exec p4 sync $copiedextrLog}
            exec p4 edit $copiedextrLog
            exec cp $extrLog $copiedextrLog
        }
        catch {exec p4 submit -d 'Submit extraction_qa.log' $copiedextrLog}
    }
    if {[file exists $compareLog]} {
        set compareHaveCmd ""
        catch {set compareHaveCmd [exec p4 have $copiedcompareLog]}
        if {$compareHaveCmd == ""} {
            exec cp $compareLog $copiedcompareLog
            exec p4 add $copiedcompareLog
        } else {
            catch {exec p4 sync $copiedcompareLog}
            exec p4 edit $copiedcompareLog
            exec cp $compareLog $copiedcompareLog
        }
        catch {exec p4 submit -d 'Submit stdcell_compare.log' $copiedcompareLog}
    }
}


proc Main {} {
    global argc argv args env success
	if {$argc == 0} {
		puts "Usage:"
		exit
	}

	for {set i 0} {$i < $argc} {incr i} {
		set argName [lindex $argv $i]
		if {[string range $argName 0 1] == "--"} {
			##  Argname detected
			set argName [string replace $argName 0 1]
			if {[incr i] < $argc} {
				set args($argName) [lindex $argv $i]
			} else {
				puts "Error:  Missing arg value for \"$argName\""
				exit
			}
		}
	}


	set OK true
	set config $args(config)
	if [file exists $config] {
		source $config
        # Get the parameters into the global level as well because they may be
        # used in other procs
        uplevel #0 "source $config"
	} else {
		puts "Error:  Cannot open $config"
		set OK false
	}

    global LOGFILE PROGRAM_NAME
	if {![info exists rundir]} {
		##  Define rundir, if not in config
		set rundir "$env(udescratch)/$user/$args(projectType)/$args(projectName)/$args(releaseName)/verification/$args(metalStack)/$args(libName)/$args(cellName)"
    }
    set LOGFILE "$rundir/$PROGRAM_NAME.log"

	set OK [checkRequiredArg projectType $OK]
	set OK [checkRequiredArg projectName $OK]
	set OK [checkRequiredArg releaseName $OK]
	set OK [checkRequiredArg metalStack $OK]
	set OK [checkRequiredArg type $OK]
	set OK [checkRequiredArg prefix $OK]
	set OK [checkRequiredArg libName $OK]
	set OK [checkRequiredArg cellName $OK]
	set OK [checkRequiredArg tool $OK]
	set OK [checkRequiredArg config $OK]
	set OK [checkRequiredArg scriptArgs $OK]

	if (!$OK) {
		puts "Aborting on missing required argument(s)"
		exit
	}

	set sumFile "$rundir/$args(cellName).pvbatch.sum"
	set SUM [open $sumFile w]

	##  Overall success flag
	set success 1

	##  Figure out what types are expected.
	if {[info exists rcxtTypes]} {
		##  Build up a simple array of the type extract names expected
		set rcxtTypeNames [list r c cc rc rcc srccpcc sccprcc ccssrcc]
		set extractTypes ""
		set i 0
		foreach x $rcxtTypes {
			if {$x} {lappend extractTypes [lindex $rcxtTypeNames $i]}
			incr i
		}

	} else {
		set extractTypes rcc
	}


	set corners ""
	if {[info exists operatingTemp]} {
		set toks [split $operatingTemp ","]
		foreach tok $toks {
			set beolCorner [string tolower [lindex $tok 0]]
			for {set i 1} {$i<[llength $tok]} {incr i} {
				set beolTemp [lindex $tok $i]
				set MSIP${runExtractType}operatingTemp($beolCorner) $beolTemp
				lappend corners "${beolCorner}_t$beolTemp"
			}
		}
	} elseif [info exists cornerVal] {
		foreach c $cornerVal {
			if [info exists runExtractOperatingTemp($c)] {
				if {$runExtractOperatingTemp($c) != ""} {lappend corners "${c}_t$runExtractOperatingTemp($c)"} else {lappend corners $c}
			} else {
				lappend corners $c
			}
		}
	} else {
		set corners typical
	}

	set prefix [string tolower $args(prefix)]
	set scriptArgs "alpha::lpe::runExtract $args(scriptArgs)"
	set user $env(USER)
	set tool $args(tool)
	if {[info exists runFlat]} {
		if {$runFlat} {set flat "_flat"} else {set flat ""}
	} else {
		set flat "_flat"
	}
	set subdir "${prefix}_${tool}$flat"

	logMsg $SUM "LVS Results:\n"
	set lvsResults "$rundir/$subdir/$cellName.RESULTS"
	set fillDir "$rundir/${prefix}${flat}_${tool}_fill"
	set rcxtDir "$rundir/$subdir"


	#puts $lvsResults

	if [file exists $lvsResults] {
		set fp [open $lvsResults r]
		#    set print_on true
		while {[gets $fp line] >= 0} {
			#	if $print_on {logMsg $SUM $line}
			if {[string match "*LVS Compare Results*" $line] || [string match "*DRC and Extraction Results*" $line]} {logMsg $SUM $line}
			#	if {[string index $line 0] == "="} {set print_on false}
		}
	} else {
		logMsg $SUM "$lvsResults missing"
		set success 0
	}
	logMsg $SUM "\nCommand: $scriptArgs"
	logMsg $SUM "\nChecking for expected netlists:"
	logMsg $SUM "Extraction types: $extractTypes"
	logMsg $SUM "Extraction corners:  $corners"

	if {![info exists outDir]} {
		set outDir "$env(MSIP_PROJ_ROOT)/$args(projectType)/$args(projectName)/$args(releaseName)/design/$args(metalStack)/netlist/extract/$args(cellName)"
	}


	if {![info exists xtFormat]} {set xtFormat "spf"}

	if [info exists alphaNetlistDir] {set netlistDir $alphaNetlistDir } else {set netlistDir $outDir/$prefix}
	set userName $env(USER)

	logMsg $SUM "Netlist directory: $netlistDir"

	set refTime [file mtime $config]

	##  Deal with the p4 tagging.
	set checkinTag 0
	if {[info exists tag] && [info exists tagFile]} {
		#    logmsg $sum "\ninfo:  tag and tagfile are defined.\n"
		## both tag and tagfile are defined in the config file.
		set tagfileinfo [exec p4 opened $tagFile 2> /dev/null]
		if {$tagfileinfo == ""} {
			logMsg $SUM "\nWarning:  tag file $tagFile is not open."
			set tagErr "/u/$user/cd_lib/$args(projectType)/$args(projectName)/$args(releaseName)/design/$args(libName)_$args(cellName)_tag.err"
			if { [file exists $tagErr] } {
				set tagerrs [open $tagErr r]
				while { [gets $tagerrs line] >= 0 } {
					if { $line ne "" } { logMsg $SUM "\t--> $line\n" }
				}
			}
		} else {
			##  get the exact depot file name
			set reason [lindex $tagfileinfo 2]
			if {($reason == "add") || ($reason == "edit")} {
				##  Expected reason for an opened file.  Assuming all went well, check in the tag file.
				set tagFileDepot [lindex [exec p4 where $tagFile] 0]
				set checkinTag 1
			} else {
				logMsg $SUM "Error:  Unexpected open reason \"$reason\".  Aborting submit"
			}
		}
	}

	set rawFiles [glob -nocomplain "$netlistDir/ideal_*.raw"]
	array unset rawMap

	if {![info exists $rawFiles]} {
		set rawFiles [glob -nocomplain "$netlistDir/*ideal_*.raw"]
		foreach rawFile {$rawFiles} {
			set rawMap($rawFile) $rawFile
		}

	} else {
		foreach rawFile $rawFiles {set rawMap([string tolower $rawFile]) $rawFile}
	}

	## Build map of .raw files, mapping to all lowercase for more robust deletion
	foreach eType $extractTypes {
		if {[info exists uncommentRawNetlistSubckt]} {
			if {$uncommentRawNetlistSubckt} {
				##   We need to find the raw file and uncomment the top subckt
				set idealFile [string tolower "$netlistDir/ideal_$eType.raw"]
				if {![info exists $idealFile]} {
					set idealFile [lsearch -regexp -nocase -inline $rawFiles {^.*[_$eType].*}]
				}

				if {[info exists rawMap($idealFile)]} {
					logMsg $SUM "Info:  Uncommenting top level subckt in $rawMap($idealFile)"
					exec sed -r -iorig "s/^\\*\\.subckt\\s+$cellName/\\.subckt $cellName/i;s/^\\*\\.ends\\s+$cellName/\\.ends $cellName/i" $rawMap($idealFile)
				} else {
					logMsg $SUM "********************************************\nWarning: Uncommenting top level subckt in .raw file failed! Please uncomment manually and report to bhuvanc@synopsys.com\n********************************************"
				}
			}
		}
		foreach corner $corners {
			set corner [string tolower $corner]
			set expectedFile "${cellName}_${eType}_${corner}_${stack}.$xtFormat"
			set expectedFileFull "$netlistDir/${cellName}_${eType}_${corner}_${stack}.$xtFormat"
			set expectedFileFullGzip "$expectedFileFull.gz"
			set configCheckResults ""



			##  Deal with the possibility that the extract may have produced a gzipped netlist.
			set expExists [file exists $expectedFileFull]
			set expGzipExists [file exists $expectedFileFullGzip]
			if {$expGzipExists && !$expExists} {
				##  Flow created gzipped file.
				set mtime [file mtime $expectedFileFullGzip]
				exec gunzip $expectedFileFullGzip
			} elseif {!$expGzipExists && $expExists} {
				set mtime [file mtime $expectedFileFull]
				##  Flow created unzipped netlist. Nothing to do.
			} elseif {$expGzipExists && $expExists} {
				##  Both exist.  One probably old.
				set mtime [file mtime $expectedFileFull]
				set mtimeGzip [file mtime $expectedFileFullGzip]
				if {$mtime > $mtimeGzip} {
					## Unzipped is newer.  Get rid of gzipped file.
					file delete $expectedFileFullGzip
				} else {
					## Unzipped is older.  Get rid of it.
					file delete $expectedFileFull
					set mtime mtimeGzip
					exec gunzip $expectedFileFullGzip
				}
			}

			if {[file exists $expectedFileFull]} {
				## Make sure expected files are created after the config was created.
				if {$mtime > $refTime} {
					set exists "OK"
				} else {
					set exists "STALE"
					set success 0
				}
				if {$success} {
					set configCheckResults [checkConfig $expectedFileFull]
					lappend netlistList $expectedFileFull
				} else {
					set configCheckResults "Info:  Netlist instance check skipped\n"
				}
			} else {
				set exists "MISSING"
				set success 0
			}
			logMsg $SUM  "\t$expectedFile\[.gz\]  $exists"
			logMsg $SUM $configCheckResults
		}
	}
    
	if {$::success} {
        logMsg $SUM "Extract was successful.\n"
        if {[info exists args(bbox_qa)]} {
            set configFile $args(bboxConfig)
            set expectedFileFull "$netlistDir/$args(cellName)_$args(xTypes)_$args(cornerVal)_$args(metalStack).$xtFormat"
            set expectedFileFullGzip "$expectedFileFull.gz"
            if {[file exists $expectedFileFull]} {
                set reqNetlist $expectedFileFull
            } elseif {[file exists $expectedFileFullGzip]} {
            set reqNetlist $expectedFileFullGzip
            }
            set xtGroundNode ""
            if {[info exists args(xtGroundNode)]} {
                set xtGroundNode $args(xtGroundNode)
            }
            set xTypes ""
            if {[info exists args(xTypes)]} {
                set xTypes $args(xTypes)   
            }
            set xtPowerExtract ""
            if {[info exists args(xtPowerExtract)]} {
                set xtPowerExtract $args(xtPowerExtract)
            }
            set xReduction ""
            if {[info exists args(xReduction)]} {
                set xReduction $args(xReduction)
            }
            set xTempSens ""
            if {[info exists args(xTempSens)]} {
                set xTempSens $args(xTempSens)
            }
            set xtPowerNets ""
            if {[info exists args(xtPowerNets)]} {
                set xtPowerNets $args(xtPowerNets)
            }
            set stdcell $args(stdcell)
            runBboxNetlistqa $rundir $refTime $reqNetlist $configFile $stdcell $xtGroundNode $xTypes $xtPowerExtract $xReduction $xTempSens $xtPowerNets
        }
        
        if {[info exists args(checkIn)]} {
            set clientRoot [exec p4 -F %clientRoot% -ztag info]
            set clientRootList [split $clientRoot /]
            set listLen [llength $clientRootList]
            set lastItem [lindex $clientRootList $listLen-1]
            set secondLastItem [lindex $clientRootList $listLen-2]
            set expectedFileFull "$netlistDir/$args(cellName)_$args(xTypes)_$args(cornerVal)_$args(metalStack).$xtFormat"
            set expectedFileFullGzip "$expectedFileFull.gz"
            if {[file exists $expectedFileFull]} {
                set reqNetlist $expectedFileFull
                set netlistName "$args(cellName)_$args(xTypes)_$args(cornerVal)_$args(metalStack).$xtFormat"
            } elseif {[file exists $expectedFileFullGzip]} {
                set reqNetlist $expectedFileFullGzip
                set netlistName "$args(cellName)_$args(xTypes)_$args(cornerVal)_$args(metalStack).$xtFormat.gz"
            }
            set nlPath "projects/$args(projectType)/$args(projectName)/latest/design/timing/netlist/$args(cellName)"
            if {$lastItem == "msip" && $secondLastItem == "wwcad"} {
                set newdir "$clientRoot/$nlPath"
            } elseif {$lastItem == "wwcad"} {
                set newdir "$clientRoot/msip/$nlPath"
            } else {
                set newdir "$clientRoot/wwcad/msip/$nlPath"
            }
            submitBboxNetlist $newdir $reqNetlist $netlistName
            
            if {[info exists args(bbox_qa)]} {
                set qaPath "projects/$args(projectType)/$args(projectName)/latest/design/timing/netlist/$args(cellName)/bbox_qa"
                if {$lastItem == "msip" && $secondLastItem == "wwcad"} {
                    set qadir "$clientRoot/$qaPath"
                } elseif {$lastItem == "wwcad"} {
                    set qadir "$clientRoot/msip/$qaPath"
                } else {
                    set qadir "$clientRoot/wwcad/msip/$qaPath"
                }

                submitBboxqaFiles $qadir $rundir
            }    
        }

		if $checkinTag {
			set submitInfo ""
			catch {set submitInfo [exec p4 submit -d "$tag" $tagFileDepot]}
			if [info exists submitExtraFiles] {
				foreach subFile $submitExtraFiles {catch {exec p4 submit -d "$tag" $subFile}}
			}
			set patt "(\\S+) $tagFileDepot#(\\d+)"
			if [regexp $patt $submitInfo dummy action version] {
				set exactTag "$tagFileDepot#$version"
				set openStatus [exec p4 opened $tagFileDepot 2> /dev/null]
				## expect this to return nothing.
				if {$openStatus == ""} {
					logMsg $SUM "Tag file:  $exactTag\n"
					##  Add tagFile info to each netlist
					foreach netlist $netlistList {
						set nl [open $netlist a]
						puts $nl "\n***  tagFile:  $exactTag"
						close $nl
					}
				} else {
					logMsg $SUM "Error:  Tag file submit appears to have failed"
				}
			} else {
				logMsg $SUM "Error:  Submit of $tagFileDepot may have failed"
				logMsg $SUM $submitInfo
			}
		}
		foreach netlist $netlistList {
			exec gzip $netlist
			if {[info exists args(rsync)]} {
				set rsyncArg [split $args(rsync) " "]
				set site [lindex $rsyncArg 0]
				set loc [lindex $rsyncArg 1]
				set hosts [exec grep $site /remote/cad-rep/msip/admin/config/hosts/site_login_hosts]
				regexp {^.*\s([0-9a-z]+)\.internal.*} $hosts to hosts
				catch {exec rsync -e "/usr/bin/ssh -q -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no" --recursive $netlist.gz ${userName}@$hosts:$loc/$userName/} rsyncOut
				regsub -all {stty: standard input: Invalid argument} $rsyncOut {} rsyncOut
				regsub -all {\\n^$} $rsyncOut {} rsyncOut
				if { $rsyncOut != "" } {
					set errC 0
					set spliterr [split $rsyncOut "\n"]
					set rsyncErr ""
					foreach err $spliterr {
						if {$err != ""} {
							set errC [expr {$errC+1}]
							set rsyncErr "$rsyncErr\t$err\n"
						}
					}
					if {$errC != 0 } {
						logMsg $SUM "\n\nNetlist remote copy:\nStatus: FAILED\nSite: $site\nLocation: $loc\nReason:"
						logMsg $SUM "$rsyncErr"
					} else {
						logMsg $SUM "\n\nNetlist remote copy:\nStatus: SUCCESS\nSite: $site\nLocation: $loc/$userName/$expectedFile\[.gz\]\n"
					}
				} else {
					logMsg $SUM "\n\nNetlist remote copy:\nStatus: SUCCESS\nSite: $site\nLocation: $loc/$userName/$expectedFile\[.gz\]\n"
				}
			} elseif { [regexp rsync $args(scriptArgs)] } {
				logMsg $SUM "\n\nNetlist remote copy:\nStatus: SKIPPED\nReason: Current site and target site are same. rsync ignored to avoid multiple copies\n"
			}
		}
		if {[info exists cleanUpOnSuccess]} {
			if { $cleanUpOnSuccess == 1 } {
				catch { file delete -force $rcxtDir } err
				catch { file delete -force $fillDir } err
				logMsg $SUM "Directories cleaned:\n"
				logMsg $SUM "\t$rcxtDir\n\t$fillDir\n"
			}
		}

	} elseif {[info exists tagFileDepot]} {
		logMsg $SUM "Extract failed.  Reverting tag file"
		set revertInfo [exec p4 revert $tagFileDepot]
		if {[info exists submitExtraFiles]} {
			foreach subFile $submitExtraFiles {catch {exec p4 revert $subFile}}
		}
		logMsg $SUM $revertInfo
	} else {
		logMsg $SUM "Extract failed."
	}

	if { [info exists alphaCheckResults] && ($runExtractType == "selectedNets")} {
		##  Results of alpha checks passed along from runExtract
		logMsg $SUM "\nResults of SNPS_checks checks:"
		foreach l $alphaCheckResults {logMsg $SUM "\t$l"}
		logMsg $SUM "\n"
	}

	logMsg $SUM "\nExtraction details:"
	logMsg $SUM "Config file ($config):"
	set fp [open $config r]
	while {[gets $fp line] >= 0} {logMsg $SUM "\t$line"}
	close $fp
	logMsg $SUM "Extraction directory:"
	logMsg $SUM "\t$rundir/$subdir/"

	close $SUM
	#if [file exists $expectedFileFull] { exec gzip $expectedFileFull }
	if [info exists mailDist] {set mailDist "$mailDist,$user@synopsys.com"} else {set mailDist "$user@synopsys.com"}
	##  If extract failed, mail to just user.
	if {!$::success} {set mailDist "$user@synopsys.com"}
	exec mail -s "\[$args(projectName)\] Extraction results for $args(libName)/$args(cellName)" $mailDist < $sumFile

}



proc showUsage {} {
	global RealScript
	global RealBin
	set msg {
		This directory contains a program built to check the bumpout of an HBM phy vs. the bumps on its interposer.

		Usage:
		$RealBin/$RealScript \
			--phyGds <phyGdsFile> \
			--intGds <intGds> \
			--phyPinTextLayer <pohyPinTextLayer> \
			--intPinTextLayer <intPinTextLayer> \
			--phyCell <phjyCell> \
			--intCell <intCell> \
			--phyOrientation <phyOrientation> \
			--phyOrigin <phyOrigin> \
			--pinMapfile <pinMapFile> \
			--phyBoundaryLayer <phyBoundaryLayer> \
			--phyUnconnOkFile <phyUnconnectedOkCsvFile> \
			--damnCloseOkFile <damnCloseOkCsvFile> \
			--mapPrefix <prefix>
		--outFileRoot <output-file-root-name>
		--help

		All command arguments are required except --help.

		Functional Description:
		The purpose of this program is to check the bump connectivity between an hbm phy and its
		associated interposer.  It operates entirely based on the top-level text in each (phy and
		interposer), as top-level geometries aren't always available and to traverse the layout
		hierarchies seeking out usable geometries is more complex than I currently have time for.
		Connectivity is established by looking within a fixed window around the PHY texts (hardcoded
		as +/-5.0u) for corresponding texts in the interposer. (Could easily be added as a command
		arg if desired).

		Note that string matches are case-insensitive.

		Outputs:
		<outFileRoot>.bumpcheck.log     Run log file; duplicate of what's printed to stdout
		<outFileRoot>.damnClose.txt     Listing of unwaived very-close bump matches
		<outFileRoot>.exact.txt         Listing of exact bump matches
		<outFileRoot>.matched.txt       Listing of all matched bumps
		<outFileRoot>.notClose.txt      Listing of coarsely (with 5u) matched bumps
		<outFileRoot>.unmatched.txt     Listing of unwaived unmatched phy bumps.


		Arguments:
		phyGds:  The gds file containing the phy.  Must be uncompressed.
		intGds:  The gds file containing the interposer.  Must be uncompressed.
		phyPinTextLayer:  The layer;purpose spec for the pin text in the phy. Of the format
		"layer;datatype".  Example "202;74"
		intPinTextLayer:  The layer;purpose spec for the pin text in the interposer.
		Of the format "layer;datatype".  Example "125;0"
		phyCell:  Name of the top-level phy cell.
		intCell;  Name of the top-level interposer cell.
		phyOrientation:  Orientation spec for the phy.  Specifically, how the phy is flipped
		to line up with the interposer.  Any of MX, MY, R0 or R180.
		MX: indicates than the phy is flipped in the Y direction,
		MY: indicates than the phy is flipped in the X direction,
		R0:  No rotation or mirroring
		R180:  180 rotation, flipping the sign of both X and Y coords.
		phyOrigin:  Location of the phy instance in interposer coordinate space.
		pinMapfile: Map file that specifies the mapping between bump names in the phy and
		interposer.  If no mapping is specified, match is assumed to be exact.
		phyBoundaryLayer:  The layer that marks the extent of the phy. Limitation: Only simple
		rectangles allowed.
		phyUnconnOkFile:  A csv file listing the phy bumps, "name,x,y", that are OK to be
		unconnected.  x,y should be in microns, in phy coordinate space.
		Coordinate matching is exact; comments (#...) are allowed
		damnCloseOkFile:  A csv file listing the phy bumps, "name,x,y", that are OK to be
		very close (withing 1gds unit) of the interposer bump label.
		x,y should be in microns, in phy coordinate space.
		Coordinate matching is exact; comments (#...) are allowed
		mapPrefix:        Alternative method of mapping phy pin to interposer pin.
		If no mapFile mapping exists, and prefix is specified,
		the mapped name is the phy pin name prefixed.
		outFileRoot:      Root name for all output files.  Defaults to phyCell_VS_intCell

		What it checks:
		1. Matching between phy and interposer bump names, as defined in the mapfile.
		2. More than one text within the matching window, both in the phy and interposer.
		3. More than one phy boundary polygon. (Exact duplicates are allowed, any others
		result in an abort.)
		4. Unconnected phy bumps.
		5. Unconnected interposer bumps within phy footprint, as defined by the phyBoundaryLayer.

	}
	puts $msg
	return $msg
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
# nolint Line 298: W Found constant
# nolint Line 489: W Found constant
# nolint Line 286: N Close brace not aligned
# nolint Line 335: N Suspicious variable name
# nolint Line 448: N Suspicious variable name
# nolint Line 432: N Suspicious variable name
