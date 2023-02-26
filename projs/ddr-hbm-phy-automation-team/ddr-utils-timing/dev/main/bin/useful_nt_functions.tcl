#!/depot/tcl8.6.3/bin/tclsh8.6
# nolint Main


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

# add prefix and suffix to every element in list:
proc add_pre_suf {prefix suffix mylist } {
    set x {}
    foreach y $mylist { lappend x ${prefix}${y}$suffix }
    return $x
}

proc get_gates { net } { get_pins -leaf -of $net -filter "lib_pin_name==g" }

## FLAT VERSION - DIRK (full - including clocked fb)
## create a generated clock at serdes_common latch
#proc sdcla_genclk {name edges inst} {
#    mark_clock_network -stop [list $inst/mdbqb $inst/mdq $inst/sd*]
#    #mark_clock_network -stop [list $inst/mdbqb $inst/mdq]
#    #mark_clock_network -no_pulse [list $inst/sqb $inst/sq]
#    create_generated_clock -name $name -edges $edges -source   \
#        [get_pins [add_pre_suf X$inst/ /main/g                 \
#            {MPmdqckb MPmdbqbckb MNsqckb MNsqbckb} ] ]        \
#        [get_pins [add_pre_suf X$inst/ /main/g {MPQB MNQB MPsqfb MNsqfb} ] ]
#    set_differential [add_pre_suf X$inst/ /main/g {MPmdbqbckb MNmdqck} ]
#    set_differential [add_pre_suf X$inst/ /main/g {MPmdqckb MNmdbqbck} ]
#    set_differential [add_pre_suf X$inst/ /main/g {MNsqckb MPsqbck} ]
#    set_differential [add_pre_suf X$inst/ /main/g {MNsqbckb MPsqck} ]
#    set_differential [add_pre_suf X$inst/ /main/g {MPQB MPQ} ]
#    set_differential [add_pre_suf X$inst/ /main/g {MNQB MNQ} ]
#    set_differential [add_pre_suf X$inst/ /main/g {MPsqfb MPsqbfb} ]
#    set_differential [add_pre_suf X$inst/ /main/g {MNsqfb MNsqbfb} ]
#}
## FLAT VERSION - DIRK (reduced)
## create a generated clock at serdes_common latch
#proc sdcla_genclk {name edges inst} {
#    mark_clock_network -stop [list $inst/mdbqb $inst/mdq $inst/sd*]
#    mark_clock_network -no_pulse [list $inst/sqb $inst/sq]
#    #mark_clock_network -stop [list $inst/sqb $inst/sq]
#    #mark_clock_network -stop [list $inst/sqb $inst/sq]
#    #mark_instance -dont_search_thru_gate [get_cells [add_pre_suf X$inst/ "" \
#    #    {MPsqck MNsqckb MPsqbck MNsqbckb} ] ]
#    create_generated_clock -name $name -edges $edges -source   \
#        [get_pins [add_pre_suf X$inst/ /main/g                 \
#            {MPmdqckb MPmdbqbckb} ] ]        \
#        [get_pins [add_pre_suf X$inst/ /main/g {MPQB MNQB} ] ]
#    set_differential [add_pre_suf X$inst/ /main/g {MPmdbqbckb MNmdqck} ]
#    set_differential [add_pre_suf X$inst/ /main/g {MPmdqckb MNmdbqbck} ]
#    set_differential [add_pre_suf X$inst/ /main/g {MPQB MPQ} ]
#    set_differential [add_pre_suf X$inst/ /main/g {MNQB MNQ} ]
#}
# FLAT VERSION - CHRIS LIKE
# create a generated clock at serdes_common latch
proc sdcla_genclk {name edges inst} {
    mark_clock_network -no_pulse [list $inst/sqb $inst/sq]
    mark_clock_network -stop [list $inst/mdbqb $inst/mdq]
    create_generated_clock -name $name -edges $edges -source   \
        [get_pins [add_pre_suf X$inst/ /main/g                 \
            {MNmdqck MPmdqckb} ] ]        \
        [get_pins [add_pre_suf X$inst/ /main/g {MPQB MNQB} ] ]
    set_differential [add_pre_suf X$inst/ /main/g {MNmdqck  MPmdbqbckb} ]
    set_differential [add_pre_suf X$inst/ /main/g {MPmdqckb MNmdbqbck} ]
    set_differential [add_pre_suf X$inst/ /main/g {MPQB MPQ} ]
    set_differential [add_pre_suf X$inst/ /main/g {MNQB MNQ} ]
    #set_differential [add_pre_suf X$inst/ /main/g {MPsqfb MPsqbfb} ]
    #set_differential [add_pre_suf X$inst/ /main/g {MNsqfb MNsqbfb} ]
}

# create a generated clock at serdes_common flop (single-ended D)
proc sdcmsfqb_genclk {name edges inst} {
    create_generated_clock -name $name -edges $edges -source \
        [get_pins X$inst/MNsinck/main/g] \
        [get_pins [list X$inst/MNQB/main/g X$inst/MPQB/main/g]]
    set_differential [get_pins [list X$inst/MNsinck/main/g X$inst/MPsinckb/main/g]]
}

# create a generated clock at cpc_diff_latch latch
proc cpc_diff_latch_genclk {name edges inst} {
    #mark_clock_network -stop [list $inst/mdbqb $inst/mdq $inst/sd*]
    mark_clock_network -no_pulse [list $inst/inax $inst/ina]
    create_generated_clock -name $name -edges $edges -source   \
        [get_pins [add_pre_suf X$inst/ /main/g                 \
            {I0/MP0 I5/MP0} ] ]        \
        [get_pins [add_pre_suf X$inst/ /main/g {X10_m1/MP0 X10_m1/MN0} ] ]
    # Clocked gates:
    set_differential [add_pre_suf X$inst/ /main/g {I0/MP0 I0/MN0} ]
    set_differential [add_pre_suf X$inst/ /main/g {I5/MP0 I5/MN0} ]
    # Output drivers Q/Qb:
    set_differential [add_pre_suf X$inst/ /main/g {X10_m1/MP0 X2_m1/MP0} ]
    set_differential [add_pre_suf X$inst/ /main/g {X10_m1/MN0 X2_m1/MN0} ]
}

proc mark_pll_clkbuf_en {inst clk_out_pos clk_out_neg} {
    # mark positive side (pos input, neg output):
    mark_clock_gate -clock [list X$inst/X0/MN0/main/g X$inst/X0/MP0/main/g] -output $clk_out_neg \
        -positive_enable [list X$inst/X0/MN1/main/g X$inst/MP7/main/g] -negative_enable X$inst/X0/MP1/main/g
    # mark negative side:
    mark_clock_gate -clock [list X$inst/X3/MN0/main/g X$inst/X3/MP0/main/g] -output $clk_out_pos \
        -positive_enable X$inst/X3/MN1/main/g -negative_enable [list X$inst/X3/MP1/main/g X$inst/MN8/main/g]
    #set_differential [list $clk_out_pos $clk_out_neg]
}
#mark_pll_clkbuf_en I4 clk_in_buf[1] clk_in_buf[0]

proc mark_pll_mux2 {inst} {
    mark_mux -output $inst/outx -select_pins [list \
        X$inst/X0[*]/MN0/main/g X$inst/X0[*]/MP0/main/g \
        X$inst/X1[*]/MN0/main/g X$inst/X1[*]/MP0/main/g ]
}

proc mark_pll_div_mux {inst} {
    mark_mux -output $inst/outx -select_pins \
    [list X$inst/MP0/main/g X$inst/MN0/main/g X$inst/MP2/main/g X$inst/MN2/main/g]
}
