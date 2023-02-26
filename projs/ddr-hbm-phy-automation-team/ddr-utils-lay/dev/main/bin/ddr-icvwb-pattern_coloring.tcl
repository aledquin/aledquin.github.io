#!/depot/tcl8.6.6/bin/tclsh

set RealBin [file dirname [file normalize [info script]] ]
set RealScript [file tail [file normalize [info script]] ]

lappend auto_path "$RealBin/../bin"
lappend auto_path "$RealBin/../lib/tcl"

package require Messaging 1.0
namespace import ::Messaging::*

package require Misc 1.0
namespace import ::Misc::*

utils__script_usage_statistics $RealScript "2022ww38"

##################################################################################################################
##														##
## Usage: 	Simply run "source pattern_coloring.tcl" in ICWBEV/ICVWB console.				##
##		A replacement "VUE_n -> ActualNetName" (for example VUE_2 --> VSS_M8) should be done in ICWBEV	##
##		for all considered nets prior script run, 							##
##			otherwise										##
##		if some net names are different from default ones (BP_, VSS_, VDD_, VAA_, VDDQ_, VDDQLP_)	##
##		then they can be added in the list under the correspoding color					##
##														##
## Date:	09 February 2021  - Various net name support added, separated by color groups including 	##
##					special nets								## 
## Date:	25 January 2021   - Side cell brightness defined 75%						##
## Date:	02 September 2020 - Case insensitive net names supported					##
## Date:	22 August 2019	  - Created									##
##														##
##################################################################################################################
	
proc set_side_cells_visibility {visible} {
    foreach ss [cell side_cells] {
	cell side_cell display $ss [list visible $visible]
    }
}

set netsList  [cell side_cells]
set netcolor {}
set netSpecialcolor {}

# Green
set vssList {VSS DDR_VSS}
set vssColor "#ff00ff00"
lappend netcolor $vssList
lappend netcolor $vssColor

# Orange 
set vddList {VDD DDR_VDD VDD_D VDD_PLL VDDA}
set vddColor "#ffddaa55"
lappend netcolor $vddList
lappend netcolor $vddColor

# Brown
set vdd2hList {VDD2H}
set vdd2hColor "#ff990000"
lappend netcolor $vdd2hList
lappend netcolor $vdd2hColor

# Red
set vddqList {VDDQ DDR_VDDQ VDDQ_D5 VDDQ_LP5 }
set vddqColor  "#ffff0000"
lappend netcolor $vddqList
lappend netcolor $vddqColor

# LightBlue
set vddqlpList {VDDQLP DDR_VDDQLP VSH}
set vddqlpColor  "#ff0099ff"
lappend netcolor $vddqlpList
lappend netcolor $vddqlpColor

# Yellow
set vaaList {VAA DDR_VAA VAAD5 VAA_VDD2H}
set vaaColor  "#ffffff00"
lappend netcolor $vaaList
lappend netcolor $vaaColor

# Magenta
set signalList {PAD BP BP_A BP_D BP_ZN_SENSE BP_VREF BP_ZN BP_ALERT BP_MEMRESET DDR DDR_A DDR_D DDR_ZN_SENSE DDR_VREF DDR_B DDR_C DDR_M DDR_P DDR_Z DDR_ODT LPDDR IOPAD}
set signalColor "#ff990099"
lappend netcolor $signalList
lappend netcolor $signalColor

# Pink
set specialList {Pclk PwrOk Vref odprin VIO TIE}
set specialColor "#ffff00ff"
lappend netSpecialcolor $specialList
lappend netSpecialcolor $specialColor

# Grey
set otherList {AllNets missing RxStrobe}
set otherColor "#ffddddaa"
lappend netSpecialcolor $otherList
lappend netSpecialcolor $otherColor

foreach actualNet ${netsList} {
    set netColorSolid 0
    set netName  [regsub -nocase {(_M[0-9]+|_RDL|\*_|_\*_|_).*} ${actualNet} ""]
    for { set i 0} {$i < [llength ${netcolor} ]} {incr i 2} { 
        foreach tmp [lindex ${netcolor} $i] {
       	    if {[ string equal -nocase $tmp ${netName} ]} {
 	        set netColorSolid [lindex ${netcolor} [expr {$i + 1}]]
	        continue
	    }
	}	
    	if { ${netColorSolid} == 0} {
    	    echo "Net_name:Color pair is not found for net ${actualNet}. Check inputs!\n"
	    continue
    	}
    	cell side_cell display ${actualNet} [list color ${netColorSolid} ]
    	cell side_cell display ${actualNet} [list pattern solid] 
    	cell side_cell display ${actualNet} [list brightness 75]
    }
}

foreach actualNet ${netsList} {
    set netColorSolid 0
    for { set i 0} {$i < [llength ${netSpecialcolor} ]} {incr i 2} { 
        foreach tmp [lindex ${netSpecialcolor} $i] {
       	    if {[ string match -nocase *${tmp}* ${actualNet} ]} {
 	        set netColorSolid [lindex ${netSpecialcolor} [expr {$i + 1}]]
	        continue
	    }
	}	
    	if { ${netColorSolid} == 0} {
    	    echo "Net_name:Color pair is not found for net ${actualNet}. Check inputs!\n"
	    continue
    	}
    	cell side_cell display ${actualNet} [list color ${netColorSolid} ]
    	cell side_cell display ${actualNet} [list pattern solid] 
    	cell side_cell display ${actualNet} [list brightness 75]
    }
}


echo "set_side_cells_visibility 0 - Turn off visibility for All Side Cells"
echo "set_side_cells_visibility 1 - Turn on visibility for All Side Cells"

return 0

################################################################################
# No Linting Area
################################################################################
# nolint Main