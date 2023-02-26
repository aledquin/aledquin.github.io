#!/depot/tcl8.5.12/bin/tclsh8.5

if {[namespace exists alpha::util]} {
    namespace delete alpha::util
}

set DEBUG      0
set VERBOSITY  0
set STDOUT_LOG ""
set RealBin        [file dirname [file normalize [info script]] ]

namespace eval ::alpha::util {
    global RealBin
    variable PROGRAM_NAME [file tail [file normalize [info script]] ]
    namespace eval _packages {
        global RealBin
        source "$RealBin/../lib/tcl/Util/Messaging.tcl"
        source "$RealBin/../lib/tcl/Util/Misc.tcl"
    }
    namespace import _packages::Messaging::*
    namespace import _packages::Misc::*
    foreach procName [namespace import] {
        rename $procName "_$procName"
    }
    # Get the version number
    variable VERSION [_get_release_version]
    _utils__script_usage_statistics $PROGRAM_NAME $VERSION

	
    proc printLabels {design fileName} {
	set fout [open $fileName w]
	db::foreach pin [db::getPins -of $design] {
	    set termName [db::getAttr pin.term.name]
	    set netName [db::getAttr pin.term.net.name]
	    set figs [db::getAttr pin.figs]
	    puts $fout "found pin on term: $termName, net: $netName with: [db::getCount $figs] pin shapes"
	    db::foreach fig $figs {
		if {[db::isEmpty [set g [db::filter [db::getAttr fig.groupsOwnedBy] -filter {%name=="__CDBA_PARENTCHILD_ONLY_GROUP"}]]]} {
		    puts $fout "    pinshape on term: $termName, on LPP: [db::getAttr fig.LPP.lpp] has no labels"
		} else {
		    db::foreach memberLabel [db::filter [db::getAttr g.members] -filter {[lsearch {AttrDisplay Text} %object.type]>=0}] {
			set label [db::getAttr memberLabel.object]
			puts $fout "    pinshape on term: $termName on LPP: [db::getAttr fig.LPP.lpp] with label: [db::getAttr label.text] on LPP: [db::getAttr label.LPP.lpp]"
		    }
		}
	    }
	}
	puts $fout ""
	db::foreach textObj [db::getShapes -of $design -filter {[lsearch {AttrDisplay Text} %type]>=0}] {
	    puts $fout "Label: [db::getAttr textObj.text] --> [db::getAttr textObj.LPP.lpp]"
	}
	close $fout
	xt::openTextViewer -files $fileName
    }


    proc legalMacroInfo {} {
		set pcsDesignDir "$::env(MSIP_PROJ_ROOT)/$::env(MSIP_PRODUCT_NAME)/$::env(MSIP_PROJ_NAME)/$::env(MSIP_REL_NAME)/design"
		set legalMacrosFile "$pcsDesignDir/legalMacros.txt"
		set MACROS [open $legalMacrosFile r]
		puts "<macro>, {Blockages} {#Figures} {#PrBoundary_Coord}\n"
		while {[gets $MACROS line] >= 0} {
            ## uncomment
            set line [regsub {\#.*} $line ""]
            set n [llength $line]
            if {$n == 0} { continue }
            if {$n > 1} {
                puts "Warning:  Unexpected tokens in \"$line\". Skipping"
                continue
            }
            ##  All good.  One token.
            set toks [split $line "/"]
            if {[llength $toks] != 2} {
                puts "Warning:  Unexpected formating: \"$line\""
                continue
            }
            set x 0
            set libName [lindex $toks 0]
            set cellName [lindex $toks 1]
			set points ""	
			set blockages [list ]
			if {[oa::DesignExists $libName $cellName layout]} {
				set layouts [dm::getCellViews -libName $libName -cellName $cellName -filter {%viewType=="maskLayout" && %name=="layout"}]
				set des [de::open $layouts -readOnly true -depth 1 -headless true]
				
				set oaDesign [db::getAttr topDesign -of $des]
				set selectedSet [de::getFigures -design $oaDesign]
				set obj [db::getCount $selectedSet]
				db::foreach sel $selectedSet {
					if {[db::getAttr sel.objType] == "Blockage"} {
						set blockages [lappend blockages [db::getAttr sel.object.layerHeader.layer.name]]
						set blockages [lsort -unique $blockages]
					} elseif {[db::getAttr sel.objType] == "Boundary"} {
						set points [db::getAttr sel.object.points]
					} 

				}
				puts "$cellName,{$blockages} {$obj} {$points}"
				de::close $des
			}
		}
    }
}


################################################################################
# No Linting Area
################################################################################

# nolint Main
