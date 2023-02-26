#!/depot/tcl8.6.3/bin/tclsh8.6
# nolint Main
# Reason: module script
# linear-model
#    Determine the coefficients for a linear regression between
#    two series of data (the model: Y = A + B*X)
#
# Arguments:
#    xdata        Series of independent (X) data
#    ydata        Series of dependent (Y) data
#    intercept    Whether to use an intercept or not (optional)
#
# Result:
#    List of the following items:
#    - (Estimate of) Intercept A
#    - (Estimate of) Slope B
#    - Standard deviation of Y relative to fit
#    - Correlation coefficient R2
#    - Number of degrees of freedom df
#    - Standard error of the intercept A
#    - Significance level of A
#    - Standard error of the slope B
#    - Significance level of B
#
#
proc linear-model { xdata ydata {intercept 1} } {
    variable TOOFEWDATA
    
    if { [llength $xdata] < 3 } {
	return -code error -errorcode ARG "TOOFEWDATA: not enough independent data"
    }
    if { [llength $ydata] < 3 } {
	return -code error -errorcode ARG "TOOFEWDATA: not enough dependent data"
    }
    if { [llength $xdata] != [llength $ydata] } {
	return -code error -errorcode ARG "TOOFEWDATA: number of dependent data differs from number of independent data"
    }

#    puts "lr: {$xdata} {$ydata}"
    
    set sumx  0.0
    set sumy  0.0
    set sumx2 0.0
    set sumy2 0.0
    set sumxy 0.0
    set df    0
    foreach x $xdata y $ydata {
	if { $x != "" && $y != "" } {
	    set sumx  [expr {$sumx+$x}]
	    set sumy  [expr {$sumy+$y}]
	    set sumx2 [expr {$sumx2+$x*$x}]
	    set sumy2 [expr {$sumy2+$y*$y}]
	    set sumxy [expr {$sumxy+$x*$y}]
	    incr df
	}
    }
    
    if { $df <= 2 } {
	return -code error -errorcode ARG "$TOOFEWDATA: too few valid data"
    }
    if { $sumx2 == 0.0 } {
	return -code error -errorcode ARG "$TOOFEWDATA: independent values are all the same"
    }
    
    #
    # Calculate the intermediate quantities
    #
    set sx  [expr {$sumx2-$sumx*$sumx/$df}]
    set sy  [expr {$sumy2-$sumy*$sumy/$df}]
    set sxy [expr {$sumxy-$sumx*$sumy/$df}]
    
    #
    # Calculate the coefficients
    #
    if { $intercept } {
	set B [expr {$sxy/$sx}]
	set A [expr {($sumy-$B*$sumx)/$df}]
    } else {
	set B [expr {$sumxy/$sumx2}]
	set A 0.0
    }
    
    #
    # Calculate the error estimates
    #
    set stdevY 0.0
    set varY   0.0
    
    if { $intercept } {
	set ve [expr {$sy-$B*$sxy}]
	if { $ve >= 0.0 } {
	    set varY [expr {$ve/($df-2)}]
	}
    } else {
	set ve [expr {$sumy2-$B*$sumxy}]
	if { $ve >= 0.0 } {
	    set varY [expr {$ve/($df-1)}]
	}
    }
    set seY [expr {sqrt($varY)}]
    
    ##  These extra thingies have trouble for a line with slope of 0.  Don't need them here.
    if 0 {
	if { $intercept } {
	    set R2    [expr {$sxy*$sxy/($sx*$sy)}]
	    set seA   [expr {$seY*sqrt(1.0/$df+$sumx*$sumx/($sx*$df*$df))}]
	    set seB   [expr {sqrt($varY/$sx)}]
	    set tA    {}
	    set tB    {}
	    if { $seA != 0.0 } {
		set tA    [expr {$A/$seA*sqrt($df-2)}]
	    }
	    if { $seB != 0.0 } {
		set tB    [expr {$B/$seB*sqrt($df-2)}]
	    }
	} else {
	    set R2    [expr {$sumxy*$sumxy/($sumx2*$sumy2)}]
	    set seA   {}
	    set tA    {}
	    set tB    {}
	    set seB   [expr {sqrt($varY/$sumx2)}]
	    if { $seB != 0.0 } {
		set tB    [expr {$B/$seB*sqrt($df-1)}]
	    }
	}
    }
    
    #
    # Return the list of parameters
    #
#    puts "$A $B"
#    return [list $A $B $seY $R2 $df $seA $tA $seB $tB]
    return [list $A $B]
}


proc SpiceNumToReal {InStr} {
    
    if [regexp {(([-+])?(\d+)?(\.)?(\d+)([e][-+]?\d+)?)([a-z]+)?} $InStr dummy t1 t2 t3 t4 t5 t6 t7] {
	set mul 1.0;
	set mulstr [string tolower $t7]
	
	if {$mulstr != ""} {
	    set mulstr1 [string range $mulstr 0 0]
	    if {$mulstr1 == "a"} {
		    set mul 1e-18
	    } elseif {$mulstr1 == "f"} {
		    set mul 1e-15
	    } elseif {$mulstr1 == "p"} {
		    set mul 1e-12
	    } elseif {$mulstr1 == "n"} {
	    	set mul 1e-09
	    } elseif {$mulstr1 == "u"} {
		    set mul 1e-06
	    } elseif {$mulstr1 == "m"} { 
    		set mul 1e-03
    		if {[string range $mulstr 0 2] == "meg"} {
    		    set mul 1e+6
    		}
	    } elseif {$mulstr1 == "k"} {
		    set mul 1e+03
	    } elseif {$mulstr1 == "x"} {
		    set mul 1e+06
	    } elseif {$mulstr1 == "g"} {
		    set mul 1e+09
	    } elseif {$mulstr1 == "t"} {
		    set mul 1e+12
	    } else {set mul 1.0}
	}
	
	set value [expr {$t1*$mul}]
#	puts "$InStr: $value"
	return $value
    } else {
	puts  "Error: SpiceNumToReal: Could not parse $InStr"
	return ""
    }
}

proc set_device_node_caps {device args} {
    
    foreach arg $args {lappend ::deviceNodeCaps($device) $arg}

}
proc set_opc_process {corner libs} {
    set ::process($corner) $libs
}

proc add_opc_supplies {corner args} {
    set ::supplies($corner) $args
}

proc add_opc_grounds {corner args} {
    set ::grounds($corner) $args
}

proc set_opc_default_voltage {corner voltage} {
    set ::defaultVoltage($corner) $voltage
}

proc set_opc_temperature {corner temp} {
    set ::temperature($corner) $temp
}

proc set_device_nodes {device nodes} {
    set ::deviceNodes($device) $nodes
}

proc set_device_params {device params} {
    set ::deviceParams($device) $params
}
proc create_operating_condition {corner} {
}

proc supplyVoltage {corner supplyName} {
    set i [lsearch -exact $::supplies($corner) $supplyName]
    if {$i >= 0} {return [lindex $::supplies($corner) [expr {$i+1}]]} else {
	puts "Error:  Supply $supplyName not defined for corner $corner"
	return 0
    }
}

proc set_node_supply {args} {
    ##  "args" is expected to be a list or lists, each consisting of a name/value pair.
    foreach paramList $args {
	set l [llength $paramList]
	if {$l < 2} {
	    puts "Error:  Insufficient tokens in set_node_supply{$paramList}"
	    return
	} elseif {$l > 2} {
	    puts "Error:  Extraneous tokens in set_node_supply {$paramList}"
	    return
	}
	set ::nodeSupplies([lindex $paramList 0])  [lindex $paramList 1]
    }
}

proc set_measurement_node {node} {
    set ::measurementNode $node
}

proc set_param {args} {
    ##  "args" is expected to be a list or lists, each consisting of a name/value pair.
    foreach paramList $args {
	set l [llength $paramList]
	if {$l < 2} {
	    puts "Error:  Insufficient tokens in set_param {$paramList}"
	    return
	} elseif {$l > 2} {
	    puts "Error:  Extraneous tokens in set_param {$paramList}"
	    return
	}
#	puts "set_param [lindex $paramList 0] [lindex $paramList 1]"
	set ::params([lindex $paramList 0])  [lindex $paramList 1]
    }
}

proc permute {pList idx l} {
    ##  Recursive function to build up a list of param permutations
    ##  pList is a list of the lists to permute. Like this:  {{a1 a2} {b1 b2}}.  
    ##  The above case will return {{a1 b1} {a1 b2} {a2 b1} {a2 b2}}
    set max [llength $pList]
    set ll {}
    if {$idx == $max} {
	set l [string trim $l]
	return [list $l]
    } else {
	foreach val [lindex $pList $idx]  {
	    set nv "$val"
	    set ll [concat $ll [permute $pList [expr {$idx+1}] [concat $l $nv]]]
	}
    }
    return $ll
}

proc genParamPermutes {} {
    ## Builds a list of the parameter permutations
    set ::paramList [array names ::params]
    set ::paramNum [llength $::paramList]
#    set ::paramPermutes {}

    foreach p $::paramList {lappend pl $::params($p)}
    set ::paramPermutes [permute $pl 0 {}]
}

proc placeDevice {fp device pList idx} {

    ## Process nodes
    set devNodes {}
    foreach node $::deviceNodes($device) {
	if [info exists ::nodeSupplies($node)] {
	    lappend devNodes "$::nodeSupplies($node)"
	} else {
	    lappend devNodes "${node}_$idx"
	}
    }

    ##  Process params
    set devParams $::deviceParams($device)
    set i 0
    foreach pName $::paramList {
	set pVal [lindex $pList $i]
	set devParams [regsub "=$pName" $devParams "=$pVal"]
	incr i
    }

    puts $fp "Xdut_$idx $devNodes $device $devParams"
}

proc placeMeasurementSource {fp idx offset} {
    puts $fp "voffset_$idx offset_$idx 0 dc $offset"
    puts $fp "vSource_$idx ${::measurementNode}_$idx offset_$idx AC 1"
    puts $fp ".measure AC iac_$idx FIND i(vSource_$idx) AT=100Meg"
    puts $fp ".measure AC c_$idx param 'iac_$idx/628Meg'"
    puts $fp ".probe i(vSource_$idx)"
}

proc placeResMeasurementSource {fp idx supplyV} {
    set measPt [expr {$supplyV*0.2}]
    puts $fp "vSource_$idx ${::measurementNode}_$idx 0 DC vsw"
    puts $fp ".measure DC i_$idx find i(vSource_$idx) at=$measPt"
    puts $fp ".measure DC g_$idx param 'abs(i_$idx/$measPt)'"
    puts $fp ".probe i(vSource_$idx)"
}

proc getParam {pList paramName} {
    set i [lsearch -nocase $::paramList "$paramName"]
     if {$i < 0} {
	puts "Error: Could not file param \"$paramName\" {$pList}"
	return ""
    } else {
	return [lindex $pList $i]
    }
}

proc writeOutput {buffer} {
    if [info exists ::outFile] {
	set fp [open $::outFile a]
	puts $fp $buffer
	close $fp
    } else {
	puts $buffer
    }
}


proc readMeas {measFile} {

    ##  Reads measurements from the provided file into ::meas()
    set MEAS [open $measFile r]
    gets $MEAS line0
    gets $MEAS line1
    set measData {}
    if {[regexp {^\$DATA1} $line0] && [regexp {^\.TITLE} $line1]} {
	while {[gets $MEAS line] >= 0} {
	    set measData [concat $measData $line]
	}
	set measNameList {}
	set measValList {}
	set doName 1
	foreach m $measData {
	    if $doName {
		lappend measNameList $m
		if {$m == "alter\#"} {set doName 0}
	    } else {
		lappend measValList $m
	    }
	    set i 0
	}
	close $MEAS
	foreach measName $measNameList {
	    set measVal [lindex $measValList $i]
	    incr i
	    lappend measList $measName $measVal
	}
	array set ::meas $measList
    } else {
	close $MEAS
	puts "Error:  $measFile doesn't look right"
	return
    }
}

proc stdNumFormat {values} {

    foreach val $values {lappend fmt [format "%.6e" $val]}
    return $fmt

}

##  Table Format:
##  {
##      {type device {tableParams} rowVar}      (Header row)
##      {{tableParamValues} value}              (Data row)
##      {{tableParamValues} value}              (Data row)
##      {{tableParamValues} value}              (Data row)
##      {{tableParamValues} value}              (Data row)
##      .
##      .
##      .
##  }
##
##    type:  One of an enumerated list of the type of capacitance being measured
##    device:  The device model name (ex: nch_svt_mac)
##    tableParams:  List of parameters.  At writing, just L or nothing.
##    rowVar:  The parameter against which cap values are normalized.  Typically W (device width), NFIN (similar), AD (diffusion area), etc..
##

proc writeTable {table} {
    ##  Assuming that ::paramList ::paramPermutes and ::meas are all set up.

    set tableHdr [lindex $table 0]
    set type [lindex $tableHdr 0]
    set device [lindex $tableHdr 1]
    set params [lindex $tableHdr 2]
    set rowVar [lindex $tableHdr 3]
    writeOutput ".TABLE $tableHdr"
    writeOutput "\#\#  $type table for device $device"
    writeOutput "\#\#  Table params: $params"
    writeOutput "\#\#  Row param: $rowVar"
    set tableData [lindex $table 1]
    foreach line $tableData {writeOutput $line}

    writeOutput ".END"
}

proc subTable {subType table parName parValue} {
    ##  Extracts a subtable based on the parName/parVal provided.
    set tableHdr [lindex $table 0]
    set type [lindex $tableHdr 0]
    set device [lindex $tableHdr 1]
    set parList [lindex $tableHdr 2]
    set rowVar [lindex $tableHdr 3]
    set valId [lindex $tableHdr 1]

    set i [lsearch -exact $parList $parName]
    set subTableData {}
    if {$i < 0} {
	puts "Error:  subTable param $parName not found"
	return
    }
    ##  Remove parName from header
    set subParList [lreplace $parList $i $i]
    set subTableHdr [list $subType $device $subParList $rowVar]
    set tableData [lindex $table 1]
    foreach line $tableData {
	set lineParams [lindex $line 0]
	set lineValue [lindex $line 1]
	set pVal [lindex $lineParams $i]
	if [fEq $parValue $pVal] {
	    ##  Param matched.  Remove value from lineParams and append line
	    set lineParams [lreplace $lineParams $i $i]
	    lappend subTableData [list $lineParams $lineValue]
	}
    }
    return [list $subTableHdr $subTableData]
}

proc fEq {a b} {
    ##  Floating point compare.  Format to 8 places and string compare.
    if {[string compare [format "%.8e" $a] [format "%.8e" $b]] == 0} {return 1} else {return 0}
}

proc genTable {type device tableParams {divParam ""} } {
    ##  Generates a table structure:  [list [list tableParams] [list result]]
    ## If divParam is defined, resultant table value will be Cap/$divParam (like Cap/deviceWidth, for instance)

    ## Generate permutes from tableParams, to get a rationally sorted table.
    foreach p $tableParams {lappend pl $::params($p)}
    set tablePermutes [permute $pl 0 {}]

    set i 0
    ##  Loop through all combinations of sim parameter permutations, collecting measured caps
    foreach pList $::paramPermutes {
	set pLine {}
	## pLine includes just the tableParams
	foreach parName $tableParams {
	    set parValue [getParam $pList $parName]
	    lappend pLine $parValue
	}
	##  Pick up measured cap for this permutaion
	set c $::meas(c_$i)
	##  If divParam is defined save it.
	if {$divParam != ""} {
	    set dp [getParam $pList $divParam]
	    lappend dpTable($pLine) [SpiceNumToReal $dp]
	}
	incr i
	##  Caps saved as a list.
	lappend tableVal($pLine) $c
    }

    ##  Do a linear fit, if required.
    foreach pLine [array names tableVal] {
	set lr {}
	set val $tableVal($pLine)
	if [info exists dpTable($pLine)] {
	    ##  Doing a linear fit.  Replace list of values with linear slope.
	    set lr [linear-model $dpTable($pLine) $tableVal($pLine) 1]
	    set intercept [lindex $lr 0]
	    set slope [lindex $lr 1]
	    set tableVal($pLine) $slope
	}
    }

    ##  To this point, params have been kept in the format originally specified.
    ##  Build up final table format, formatting along the way
    set tableHdr {} 
    set tableData {} 
    set tableHdr [list $type $device $tableParams $divParam]
    foreach pid $tablePermutes {
	set pp {}
	foreach p $pid {lappend pp [stdNumFormat [SpiceNumToReal $p]]}
	set val [stdNumFormat $tableVal($pid)]
	lappend tableData [list $pp $val]
    }
    set table [list $tableHdr $tableData]
#    foreach line $table {puts $line}
    return $table
}

proc genResTable {type device tableParams {divParam ""} } {
    ##  Generates a table structure:  [list [list tableParams] [list result]]
    ## If divParam is defined, resultant table value will be Cap/$divParam (like Cap/deviceWidth, for instance)

    ## Generate permutes from tableParams, to get a rationally sorted table.
    foreach p $tableParams {lappend pl $::params($p)}
    set tablePermutes [permute $pl 0 {}]

    set i 0
    ##  Loop through all combinations of sim parameter permutations, collecting measured caps
    foreach pList $::paramPermutes {
	set pLine {}
	## pLine includes just the tableParams
	foreach parName $tableParams {
	    set parValue [getParam $pList $parName]
	    lappend pLine $parValue
	}
	##  Pick up measured cap for this permutaion
	set g $::meas(g_$i)
	##  If divParam is defined save it.
	if {$divParam != ""} {
	    set dp [getParam $pList $divParam]
	    lappend dpTable($pLine) [SpiceNumToReal $dp]
	}
	incr i
	##  Caps saved as a list.
	lappend tableVal($pLine) $g
    }

    ##  Do a linear fit, if required.
    foreach pLine [array names tableVal] {
	set lr {}
	set val $tableVal($pLine)
	if [info exists dpTable($pLine)] {
	    ##  Doing a linear fit.  Replace list of values with linear slope.
	    set lr [linear-model $dpTable($pLine) $tableVal($pLine) 1]
	    set intercept [lindex $lr 0]
	    set slope [lindex $lr 1]
	    set tableVal($pLine) $slope
	}
    }

    ##  To this point, params have been kept in the format originally specified.
    ##  Build up final table format, formatting along the way
    set tableHdr {} 
    set tableData {} 
    set tableHdr [list $type $device $tableParams $divParam]
    foreach pid $tablePermutes {
	set pp {}
	foreach p $pid {lappend pp [stdNumFormat [SpiceNumToReal $p]]}
	set val [stdNumFormat $tableVal($pid)]
	lappend tableData [list $pp $val]
    }
    set table [list $tableHdr $tableData]
#    foreach line $table {puts $line}
    return $table
}

proc genSimulation {id device corner} {
    
    puts "Running $id/$device/$corner"
    set runName "${id}_${device}_$corner"
    global ${runName}_meas
    
    set simPath "."
#    set simPath $simPath
    foreach file [glob -nocomplain $simPath/$runName.*] {file delete $file}
    set OUT [open "$simPath/$runName.sp" "w"]
    
    puts $OUT "*** Testing $corner $device"
    
    ## Dump libs
    foreach line $::process($corner) {puts $OUT $line}
    
    #  Dump supplies
    set n [llength $::supplies($corner)]
    for {set i 0} {$i<$n} {incr i 2} {
	set supplyName [lindex $::supplies($corner) $i]
	set supplyValue [lindex $::supplies($corner) [expr {$i+1}]]
	puts $OUT "v$supplyName $supplyName 0 dc $supplyValue"
    }

    # Dump grounds
    set n [llength $::grounds($corner)]
    for {set i 0} {$i<$n} {incr i} {
	set supplyName [lindex $::grounds($corner) $i]
	puts $OUT "v$supplyName $supplyName 0 dc 0"
    }

    genParamPermutes
    
    set i 0
    foreach pList $::paramPermutes {
	placeDevice $OUT $device $pList $i
	set offset [getParam $pList OFFSET]
	placeMeasurementSource $OUT $i $offset
	incr i
    }

    puts $OUT ".AC DEC 3 10Meg 1000Meg"
    puts $OUT ".option post=1"
    puts $OUT ".option probe"
    puts $OUT ".option measdgt=8"
    puts $OUT ".end"

    close $OUT

    set CSH [open "$simPath/$runName.csh" "w"]
    puts $CSH "\#!/bin/csh"
    if [info exists ::hspiceVersion] {set hsv $::hspiceVersion} else {set hsv "hspice"}
    puts $CSH "cd $simPath"
    puts $CSH "module purge"
    puts $CSH "module load $hsv"
    puts $CSH "hspice $runName.sp > $runName.log"
    close $CSH
    file attributes $simPath/$runName.csh -permissions "+x"
    ##  hspice dumps its completion message to stderr, hence the redirection.
    exec $simPath/$runName.csh 2> /dev/null

    if [file exists $simPath/$runName.ma0] {
	array unset ::meas
	readMeas $simPath/$runName.ma0
	foreach file [glob -nocomplain $simPath/$runName.*] {file delete $file}
    } else {
	puts "Error:  $runName appears to have failed.  See $runName.log"
    }
}

proc genResSimulation {id device corner supplyV} {
    
    puts "Running $id/$device/$corner"
    set runName "${id}_${device}_$corner"
    global ${runName}_meas
    
    set simPath "."
#    set simPath $simPath
    foreach file [glob -nocomplain $simPath/$runName.*] {file delete $file}
    set OUT [open "$simPath/$runName.sp" "w"]
    
    puts $OUT "*** Testing $corner $device"
    
    ## Dump libs
    foreach line $::process($corner) {puts $OUT $line}
    
    #  Dump supplies
    set n [llength $::supplies($corner)]
    for {set i 0} {$i<$n} {incr i 2} {
	set supplyName [lindex $::supplies($corner) $i]
	set supplyValue [lindex $::supplies($corner) [expr {$i+1}]]
	puts $OUT "v$supplyName $supplyName 0 dc $supplyValue"
    }

    # Dump grounds
    set n [llength $::grounds($corner)]
    for {set i 0} {$i<$n} {incr i} {
	set supplyName [lindex $::grounds($corner) $i]
	puts $OUT "v$supplyName $supplyName 0 dc 0"
    }

    genParamPermutes
    
    set supplyName [lindex $::supplies($corner) $i]
    set supplyValue [lindex $::supplies($corner) [expr {$i+1}]]
    set i 0
    foreach pList $::paramPermutes {
	placeDevice $OUT $device $pList $i
	placeResMeasurementSource $OUT $i $supplyV
	incr i
    }

    set step [expr {$supplyV/20}]
    puts $OUT ".param vsw=0"
    puts $OUT ".DC vsw 0 $supplyV $step"
    puts $OUT ".option post=1"
    puts $OUT ".option probe"
    puts $OUT ".option measdgt=8"
    puts $OUT ".end"

    close $OUT

    set CSH [open "$simPath/$runName.csh" "w"]
    puts $CSH "\#!/bin/csh"
    if [info exists ::hspiceVersion] {set hsv $::hspiceVersion} else {set hsv "hspice"}
    puts $CSH "cd $simPath"
    puts $CSH "module purge"
    puts $CSH "module load $hsv"
    puts $CSH "hspice $runName.sp > $runName.log"
    close $CSH
    file attributes $simPath/$runName.csh -permissions "+x"
    ##  hspice dumps its completion message to stderr, hence the redirection.
    exec $simPath/$runName.csh 2> /dev/null

    if [file exists $simPath/$runName.ms0] {
	array unset ::meas
	readMeas $simPath/$runName.ms0
	foreach file [glob -nocomplain $simPath/$runName.*] {file delete $file}
    } else {
	puts "Error:  $runName appears to have failed.  See $runName.log"
    }
}

proc reset_sim {} {
    if [info exists ::param] {array unset ::param}
    if [info exists ::nodeSupplies] {array unset ::nodeSupplies}
    if [info exists ::measurementNode] {unset ::measurementNode}

}

proc genTables {type device pvt supply paramList rowParam} {

    set supplyV [supplyVoltage $pvt $supply]
    genSimulation $type $device $pvt
    set table [genTable $type $device $paramList $rowParam]
    set table0 [subTable ${type}0 $table OFFSET 0]
    set table1 [subTable ${type}1 $table OFFSET $supplyV]
#    writeTable $table0
#    writeTable $table1
    lappend ::deviceCapTables($device) $table0
    lappend ::deviceCapTables($device) $table1
    set ::deviceList($device) 1
}

proc genResTables {type device pvt supply paramList rowParam} {

    set supplyV [supplyVoltage $pvt $supply]
    genResSimulation $type $device $pvt $supplyV
    set table [genResTable $type $device $paramList $rowParam]
    lappend ::deviceResTables($device) $table
    set ::deviceList($device) 1
}

proc perlList {tclList {lbkt {[}} {rbkt {]}}} {
    set perlList $lbkt
    set sep ""
    foreach x $tclList {
	append perlList "$sep\'$x\'"
	set sep ","
    }
    append perlList $rbkt
}

proc writePerlTables {} {
    writeOutput "\$deviceTables = \{"
    set t "    "
    foreach device [array names ::deviceList] {
	writeOutput "$t\'$device\' => \{"
	if [info exists ::deviceType($device)] {
	    writeOutput "$t$t\'TYPE' => '[string toupper $::deviceType($device)]',"
	    if {$::deviceType($device) == "MOS"} {
		if [info exists ::mosType($device)] {
		    writeOutput "$t$t\'MOSTYPE' => '[string toupper $::mosType($device)]',"
		} else {
		    puts "Error:  Undefined MOS type for $device"
		}
		if [info exists ::wVar($device)] {set wvar [string toupper $::wVar($device)]} else {set wvar "W"}
		if [info exists ::lVar($device)] {set lvar [string toupper $::lVar($device)]} else {set lvar "L"}
		writeOutput "$t$t\'WVAR' => '$wvar',"
		writeOutput "$t$t\'LVAR' => '$lvar',"
	    }
	} else {
	    puts "Error:  Undefined device type for $device"
	}
	set devNodes [perlList $::deviceNodes($device)]
	writeOutput "$t$t\'NODES' => $devNodes,"	
	if [info exists ::deviceNodeCaps($device)] {
	    writeOutput "$t$t\'NODECAPS' => \{"
	    foreach dc $::deviceNodeCaps($device) {
		set node [lindex $dc 0]
		set caps [perlList [lindex $dc 1]]
		writeOutput "$t$t$t\'$node' => $caps,"
	    }
	    writeOutput "$t$t\},"
	}
	
	if [info exists ::deviceCapTables($device)] {
	    writeOutput "$t$t\'CAPS' => \{"
	    foreach table $::deviceCapTables($device) {
		set hdr [lindex $table 0]
		set type [lindex $hdr 0]
		set tableParams [perlList [lindex $hdr 2]]
		set rowVar [lindex $hdr 3]
		set data [lindex $table 1]
		
		writeOutput "$t$t$t\'$type\' => \{"
		writeOutput "$t$t$t$t'tableParams\' => $tableParams,"
		writeOutput "$t$t$t$t'rowVar\' => \'$rowVar\'\,"
		writeOutput "$t$t$t$t'DATA\' => \["
		foreach line $data {
		    set params [lindex $line 0]
		    set val [lindex $line 1]
		    set d [concat $params $val]
		    set d [perlList $d]
		    writeOutput "$t$t$t$t$t$d,"
		}
		writeOutput "$t$t$t$t\],"
		writeOutput "$t$t$t\},"
		
	    }
	    writeOutput "$t$t\},"
	}
	if [info exists ::deviceResTables($device)] {
	    writeOutput "$t$t\'RES' => \{"
	    foreach table $::deviceResTables($device) {
		set hdr [lindex $table 0]
		set type [lindex $hdr 0]
		set tableParams [perlList [lindex $hdr 2]]
		set rowVar [lindex $hdr 3]
		set data [lindex $table 1]
		
		writeOutput "$t$t$t\'$type\' => \{"
		writeOutput "$t$t$t$t'tableParams\' => $tableParams,"
		writeOutput "$t$t$t$t'rowVar\' => \'$rowVar\'\,"
		writeOutput "$t$t$t$t'DATA\' => \["
		foreach line $data {
		    set params [lindex $line 0]
		    set val [lindex $line 1]
		    set d [concat $params $val]
		    set d [perlList $d]
		    writeOutput "$t$t$t$t$t$d,"
		}
		writeOutput "$t$t$t$t\],"
		writeOutput "$t$t$t\},"
		
	    }
	    writeOutput "$t$t\},"
	}
	writeOutput "$t\},"
    }
    writeOutput "\};"
}

proc charRes3t {device PVT supply w l} {
    set ::wVar($device) WR
    set ::lVar($device) LR
    set ::deviceType($device) RES

    set_device_nodes $device {T1 T2 B}
    set_device_params $device {lr=LR wr=WR  nf=1 rcoflag=1}
    set vSupply [supplyVoltage $PVT $supply]

    ##  R sims
    reset_sim
    set_node_supply [list T1 VSS] [list B VSS]
    set_measurement_node T2
    set_param [list WR $w] [list LR $l]
    genResTables Gsd $device $PVT $supply {LR} WR
}

## Procedure to run a standard 4 terminal mosfet.
proc charMos {device type PVT supply nfin l diffA diffP} {

    if {[string first "pode" $device] < 0} {
	##  MOS device
	set ::deviceType($device) MOS
    } else {
	##  PODE device
	set ::deviceType($device) PODE
    }
    set ::mosType($device) $type
    set ::wVar($device) NFIN
    set ::lVar($device) L

    set_device_nodes $device {D G S B}
    set_device_node_caps $device {G Cg} {D {Csd Cad Cpd}} {S {Csd Cas Cps}} {B}
    set_device_params $device {l=L nfin=NFIN  nf=1 multi=1 ccosflag=0 ccodflag=0 rgflag=1 rcosflag=1 rcodflag=1 ad=AD as=AS pd=PD ps=PS}
    set vSupply [supplyVoltage $PVT $supply]

    set type [string tolower $type]
    if {$type == "n"} {
	set VS VSS
	set VD $supply
    } elseif {$type == "p"} {
	set VS $supply
	set VD VSS
    }

    ##  Single l,nfin used for diff sims
    set oneL [lindex $l 0]
    set oneNfin [lindex $nfin 0]

    ##  R sims
    reset_sim
    set_node_supply [list S $VS] [list G $VD] [list B $VS] 
    set_measurement_node D
    set_param [list NFIN $nfin] [list L $l] {PS 0} {AS 0} {PD 0} {AD 0}
    genResTables Gsd $device $PVT $supply {L} NFIN

    ##  Cgate sims
    reset_sim
    set_node_supply [list S $VS] [list D $supply] [list B $VS]
    set_measurement_node G
    set_param [list OFFSET [list 0 $vSupply]] [list NFIN $nfin] [list L $l] {PS 0} {AS 0} {PD 0} {AD 0}
    genTables Cg $device $PVT $supply {OFFSET L} NFIN

    ##  Cdrain sims
    reset_sim
    set_node_supply [list S $VS] [list G $VS] [list B $VS] 
    set_measurement_node D
    set_param [list OFFSET [list 0 $vSupply]] [list NFIN $nfin] [list L $l] {PS 0} {AS 0} {PD 0} {AD 0}
    genTables Csd $device $PVT $supply {OFFSET L} NFIN

    ##  Diff area (ad) sims
    reset_sim
    set_node_supply [list S $VS] [list G $VS] [list B $VS] 
    set_measurement_node D
    set_param [list OFFSET [list 0 $vSupply]] [list NFIN $oneNfin] [list L $oneL] {PS 0} {AS 0} {PD 0} [list AD $diffA]
    genTables Cad $device $PVT $supply {OFFSET} AD

    ##  Diff periphery (pd) sims
    reset_sim
    set_node_supply [list S $VS] [list G $VS] [list B $VS] 
    set_measurement_node D
    set_param [list OFFSET [list 0 $vSupply]] [list NFIN $oneNfin] [list L $oneL] {PS 0} {AS 0} {AD 0} [list PD $diffP]
    genTables Cpd $device $PVT $supply {OFFSET} PD

    ##  Diff area (as) sims
    reset_sim
    set_node_supply [list S $VS] [list G $VS] [list B $VS] 
    set_measurement_node S
    set_param [list OFFSET [list 0 $vSupply]] [list NFIN $oneNfin] [list L $oneL] {PS 0} {AD 0} {PD 0} [list AS $diffA]
    genTables Cas $device $PVT $supply {OFFSET} AS

    ##  Diff periphery (ps) sims
    reset_sim
    set_node_supply [list S $VS] [list G $VS] [list B $VS] 
    set_measurement_node S
    set_param [list OFFSET [list 0 $vSupply]] [list NFIN $oneNfin] [list L $oneL] {PD 0} {AS 0} {AD 0} [list PS $diffP]
    genTables Cps $device $PVT $supply {OFFSET} PS

}

## Procedure to run a standard 3 terminal mpode
proc charPode {device type PVT supply nfin l diffA diffP} {

    set ::deviceType($device) PODE
    set ::mosType($device) $type
    set ::wVar($device) NFIN
    set ::lVar($device) L

    set_device_nodes $device {G S B}
    set_device_node_caps $device {G Cg} {S {Csd Cas Cps}} {B}
    set_device_params $device {l=L nfin=NFIN  nf=1 multi=1 ccosflag=0 ccodflag=0 rgflag=1 rcosflag=1 rcodflag=1 pd=PD ps=PS}
    set vSupply [supplyVoltage $PVT $supply]

    set type [string tolower $type]
    if {$type == "n"} {
	set VS VSS
	set VD $supply
    } elseif {$type == "p"} {
	set VS $supply
	set VD VSS
    }

    ##  Single l,nfin used for diff sims
    set oneL [lindex $l 0]
    set oneNfin [lindex $nfin 0]

    ##  Cgate sims
    reset_sim
    set_node_supply [list S $VS] [list B $VS]
    set_measurement_node G
    set_param [list OFFSET [list 0 $vSupply]] [list NFIN $nfin] [list L $l] {PS 0} {AS 0}
    genTables Cg $device $PVT $supply {OFFSET L} NFIN

    ##  Cdrain sims
    reset_sim
    set_node_supply [list S $VS] [list G $VS] [list B $VS] 
    set_measurement_node S
    set_param [list OFFSET [list 0 $vSupply]] [list NFIN $nfin] [list L $l] {PS 0} {AS 0}
    genTables Csd $device $PVT $supply {OFFSET L} NFIN

    ##  Diff area (as) sims
    reset_sim
    set_node_supply [list S $VS] [list G $VS] [list B $VS] 
    set_measurement_node S
    set_param [list OFFSET [list 0 $vSupply]] [list NFIN $oneNfin] [list L $oneL] {PS 0} [list AS $diffA]
    genTables Cas $device $PVT $supply {OFFSET} AS

    ##  Diff periphery (ps) sims
    reset_sim
    set_node_supply [list S $VS] [list G $VS] [list B $VS] 
    set_measurement_node S
    set_param [list OFFSET [list 0 $vSupply]] [list NFIN $oneNfin] [list L $oneL] {AS 0} [list PS $diffP]
    genTables Cps $device $PVT $supply {OFFSET} PS

}

proc utils__script_usage_statistics {toolname version} {
    set prefix "ddr-da-"
    set reporter "/remote/cad-rep/msip/tools/bin/msip_get_usage_info"
    set cmd ""
    set script_dirname [file dirname [file normalize [info script]]]
    append cmd "$reporter --tool_name  \"${prefix}${toolname}\" "
    append cmd "--stage main --category ude_ext_1 "
    append cmd "--tool_path \"$script_dirname\" --tool_version \"$version\""

    exec sh -c $cmd
}

set script_name [file tail [file rootname [file normalize [info script]]]]
utils__script_usage_statistics $script_name "2022ww16"
