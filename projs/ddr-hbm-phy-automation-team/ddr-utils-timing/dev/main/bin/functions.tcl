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
utils__script_usage_statistics $script_name "2022ww23"


##add prefix and suffix to every element in list:
proc add_pre_suf {prefix suffix mylist } {
    set x {}
    foreach y $mylist { lappend x ${prefix}${y}$suffix }
    return $x
}


proc add_pre {prefix mylist } {
    set x {}
    foreach y $mylist { lappend x ${prefix}${y} }
    return $x
}


proc get_gates { net } { get_pins -leaf -of $net -filter "lib_pin_name==g" }

proc serdes_common_mark_diff_flop {flopinst topinst inputnets outputnets} {
	set_differential $inputnets
	set_differential [add_pre ${topinst}${flopinst}. {mdb md}]
	set_differential [add_pre ${topinst}${flopinst}. {mdqb mdbq}]
	set_differential [add_pre ${topinst}${flopinst}. {mdq mdbqb}]
	set_differential [add_pre ${topinst}${flopinst}. {sq sqb}]
	set_differential $outputnets

	set x [add_pre_suf ${topinst}${flopinst}. .main { xmmpmdfb xmmpmdfbckb xmmnmdfbck xmmnmdfb xmmpmdbfb xmmpmdqfbckb xmmnmdbfbck xmmnmdbfb }]

	mark_differential_synchronizer -transistors $x

	set x [add_pre_suf ${topinst}${flopinst}. .main { xmmpsqfb xmmpsqck xmmnsqckb xmmnsqfb xmmpsqbfb xmmpsqbck xmmnsqbckb xmmnsqbfb }]

	mark_differential_synchronizer -transistors $x

	set ckpinsp [get_pins [add_pre_suf ${topinst}${flopinst}. .main.g { xmmnmdbckb xmmpmdbck }]]
	set ckpinsn [get_pins [add_pre_suf ${topinst}${flopinst}. .main.g { xmmnmdckb xmmpmdck }]]

	mark_latch -latch_net [get_nets ${topinst}${flopinst}.mdqb] -inputs [get_nets [lindex $inputnets 0]] -clock $ckpinsp
	mark_latch -latch_net [get_nets ${topinst}${flopinst}.mdbq] -inputs [get_nets [lindex $inputnets 1]] -clock $ckpinsn

	set ckpinsp [get_pins [add_pre_suf ${topinst}${flopinst}. .main.g { xmmpmdqckb xmmnmdqck }]]
	set ckpinsn [get_pins [add_pre_suf ${topinst}${flopinst}. .main.g { xmmnmdbqbck xmmpmdbqbckb}]]

	mark_latch -latch_net [get_nets ${topinst}${flopinst}.sq] -inputs [get_nets ${topinst}${flopinst}.mdqb] -clock $ckpinsp
	mark_latch -latch_net [get_nets ${topinst}${flopinst}.sqb] -inputs [get_nets ${topinst}${flopinst}.mdbq] -clock $ckpinsn

	mark_flip_flop -master_latch [get_nets ${topinst}${flopinst}.mdqb] -slave_latch [get_nets ${topinst}${flopinst}.sq]
	mark_flip_flop -master_latch [get_nets ${topinst}${flopinst}.mdbq] -slave_latch [get_nets ${topinst}${flopinst}.sqb]

}

proc serdes_common_mark_diff_latch {flopinst topinst inputnets outputnets} {
	set_differential $inputnets
	set_differential [add_pre ${topinst}${flopinst}. {mdq mdbqb}]
	set_differential [add_pre ${topinst}${flopinst}. {sq sqb}]
	set_differential $outputnets

	set x [add_pre_suf ${topinst}${flopinst}. .main { xmmpsqfb xmmpsqck xmmnsqckb xmmnsqfb xmmpsqbfb xmmpsqbck xmmnsqbckb xmmnsqbfb }]

	mark_differential_synchronizer -transistors $x

	set ckpinsp [get_pins [add_pre_suf ${topinst}${flopinst}. .main.g { xmmpmdqckb xmmnmdqck }]]
	set ckpinsn [get_pins [add_pre_suf ${topinst}${flopinst}. .main.g { xmmnmdbqbck xmmpmdbqbckb}]]

	mark_latch -latch_net [get_nets ${topinst}${flopinst}.sq] -inputs [get_nets [lindex $inputnets 0]] -clock $ckpinsp
	mark_latch -latch_net [get_nets ${topinst}${flopinst}.sqb] -inputs [get_nets [lindex $inputnets 1]] -clock $ckpinsn

}

proc serdes_common_diff_flop_gclk {name edges flopinst topinst} {

	mark_clock_network -no_pulse [get_nets [add_pre ${topinst}${flopinst}. {sq sqb}] ] 
	mark_clock_network -stop [get_nets [add_pre ${topinst}${flopinst}. {mdq mdbqb}] ]

	set srcclkpins [get_pins [add_pre_suf ${topinst}${flopinst}. .main.g { xmmnmdqck xmmnmdbqbck }] ]
	
	create_generated_clock -name $name -edges $edges -source $srcclkpins [get_pins [add_pre_suf ${topinst}${flopinst}. .main.g {xmmpqb xmmnqb}] ]

	set_differential [get_pins [add_pre_suf ${topinst}${flopinst}. .main.g {xmmpqb xmmpq}] ]
	set_differential [get_pins [add_pre_suf ${topinst}${flopinst}. .main.g {xmmnqb xmmnq}] ]

	set_differential [get_pins [add_pre_suf ${topinst}${flopinst}. .main.g {xmmnmdqck xmmpmdbqbckb}] ]
	set_differential [get_pins [add_pre_suf ${topinst}${flopinst}. .main.g {xmmnmdbqbck xmmpmdqckb}] ]

}

proc serdes_common_diff_latch_gclk {name edges flopinst topinst} {

	mark_clock_network -no_pulse [get_nets [add_pre ${topinst}${flopinst}. {sq sqb}] ] 
	mark_clock_network -stop [get_nets [add_pre ${topinst}${flopinst}. {mdq mdbqb}] ]

	set srcclkpins [get_pins [add_pre_suf ${topinst}${flopinst}. .main.g { xmmnmdqck xmmnmdbqbck }] ]
	
	create_generated_clock -name $name -edges $edges -source $srcclkpins [get_pins [add_pre_suf ${topinst}${flopinst}. .main.g {xmmpqb xmmnqb}] ]

	set_differential [get_pins [add_pre_suf ${topinst}${flopinst}. .main.g {xmmpqb xmmpq}] ]
	set_differential [get_pins [add_pre_suf ${topinst}${flopinst}. .main.g {xmmnqb xmmnq}] ]

	set_differential [get_pins [add_pre_suf ${topinst}${flopinst}. .main.g {xmmnmdqck xmmpmdbqbckb}] ]
	set_differential [get_pins [add_pre_suf ${topinst}${flopinst}. .main.g {xmmnmdbqbck xmmpmdqckb}] ]

}

