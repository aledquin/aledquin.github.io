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

###########################################################################################################################################
##														   			 ##
## Usage: 	1) Prepare input file according to the pattern:.(GroupName)\t(GroupColor)\t(GroupCellList(separated by commas)) 	 ##
##		   Name of groups , and number of cells within each group is flexible and could be defined based on the exact GDS	 ##
##		   or could be common (generic) which includes all HM.									 ##
##		   Example(file HMcoloringGroups.txt): DECAP_acx4\t#FF990099\tdwc_ddrphy_decapvddq_acx4_ew,dwc_ddrphy_decapvddq_dbyte_ew ##
##		2) The input file can be placed either in common place (if it includes all posssible HM cell names    			 ##
##	   	   or locally with the reviewd gds , or whatever else									 ##
##		3) Source the script in command line in icwbev 										 ##
##			source HM_coloring_v3.tcl											 ##
##		4) Run command:  read_info ( Choice ),  where choise is one of the keywords c(ontour) | f(ill) 	 			 ##
##		        read_info  c(ontour)  ,  if you aimed to outline HM groups with corresponding colors only 			 ##
##		   or															 ##
##			read_info  f(ill),  if you aimed to fill HM groups with corresponding colors + Cell orientation			 ##
##		   or															 ##
##			read_info  m(onochrome),  if you aimed to fill HM groups monochromely	 					 ##
##		   or															 ##
##			read_info  v(iacalc),  if you aimed to run via_calk (will create a HM csv files with the coordinates)		 ##
##		5) To delete colored highlights or fillings run command:								 ##
##			delete_highlighted (groupName | * )										 ##
##		   where groupName is the name of deleting group or "'''*" for all groups deletion					 ##
##																	 ##
## Note:       	1) The total number of each type of HM cells  within each group will be printed out after read_info...  command run	 ##
## Date:	12 March 2020														 ##
##																	 ##
## Updates:    	Added a menu Item to get point coordinates by mouse click (in um)							 ##
## Date:	12 March 2020														 ##
##																	 ##
## Updates:     By defauld the  groupCellsSelection.txt is looking for initially in current dir, then (if not found incript folder	 ##
##	           so user  can use the common file or define its personal if needed							 ##
## Date:	09 June 2020														 ##
##																	 ##
## Updates:	Added a monochrome colore support  (Neha Pal)										 ##
## Date:	20 October 2021														 ##
##																	 ##
## Updates:	Bunch of .csv files with coordinates of Hard Macros is created to support via_calc(-format option can affect on the 	 ##
##		  postscript 					 									 ##
## Date:	22 November 2021													 ##
##																	 ##
## Updates:	Cell name checking in upper/lower-case simultaneously . Keep lower-case  manes in the .txt file		 		 ##
## Date:	10 March  2022														 ##
##																	 ##
## Updates:     Global variable site is defined                                                                                          ##
## Date:        21 March  2022                                                                                                           ##
##																	 ##
## Updates:     Hard Macro orientation information(text) is added in fill mode. 					                 ##
## Date:        13 May  2022                                                                                                             ##
##                                                                                                                                       ##
## Updates:     Find table entry number is increased up to 5000			. 					                 ##
## Date:        12 July  2022                                                                                                            ##
##                                                                                                                                       ##
###########################################################################################################################################

################################## Declarations  ########################### 
#Since now the ICWBEV specific xcommands are used
#
# do not show highlight names
layout display show_markup_names none
#
# do not hide small highlights
layout display filter_geom_size 0
#
# hide all layers
layer hide *

echo "  Usage: HM_coloring_v3.tcl "
echo "  Prepare input file according to pattern: (GroupName)\t(GroupColor)\t(GroupCellList(separated by commas)) "
echo "  Example: DECAP_acx4\t#FF990099\tdwc_ddrphy_decapvddq_acx4_ew,dwc_ddrphy_decapvddq_dbyte_ew"  
echo "  Source the script from ICWBEV command line"
echo "  Run read_info Choice, where choise is one of c(ontour) | f(ill) :"
echo "  	read_info c(ontour)"
echo "  or "
echo "  	read_info f(ill)"
echo "  or "
echo "  	read_info m(onochrome)"
echo "  or "
echo "  	read_info v(iacalc)"
echo "  To delete  highlighted contours:"
echo "  	delete_highlighted (groupName | * )"

global groupDel 
variable site 
set site "us01dwt2p843"
#############################  Procedures  ##################################
# Create a .csv files with coordinates of each Hard Macros for via_calc
proc create_csv {group_name cell_names} {
     puts "DEBUG: Create CSV "
     set activCellName [cell active]
     foreach cell $cell_names {
        find init -type ref -string $cell -nocase 
	find table export ./$activCellName/$cell.csv -filter -format csv
     }
     return 1
}


# Highlight cell's contour
proc highlight_contour {group_name color cell_names} {
     foreach cell $cell_names {
           set hid [cell highlight $cell]
           highlight color $hid $color
           foreach id $hid {
                highlight name $id $group_name/$cell 
           }
     }
     return $hid
}

# Highlight cells with fill
proc highlight_fill {group_name outline_color fill_color cell_names width} {
     foreach cell $cell_names {
     	   find init -type ref -string $cell -nocase 
           set cid {} 
           set hid [cell highlight $cell]
	   set indx 1
	   set angle 9
	   set mirror 10
           foreach id $hid {
	         if { ([table cell modify 1:1:$angle:$indx] == 0 ) && ([table cell modify 1:1:$mirror:$indx] == false ) } {
		   set orientation "R0"
	         } elseif { ([table cell modify 1:1:$angle:$indx] == 0 ) && ([table cell modify 1:1:$mirror:$indx] == true ) } {
		   set orientation "MX"
	         } elseif { ([table cell modify 1:1:$angle:$indx] == 180 ) && ([table cell modify 1:1:$mirror:$indx] == false ) } {
		   set orientation "R180"
	         } elseif { ([table cell modify 1:1:$angle:$indx] == 180 ) && ([table cell modify 1:1:$mirror:$indx] == true ) } {
		   set orientation "MY"
	         } elseif { ([table cell modify 1:1:$angle:$indx] == 90 ) && ([table cell modify 1:1:$mirror:$indx] == false ) } {
		   set orientation "R90"
	         } elseif { ([table cell modify 1:1:$angle:$indx] == 90 ) && ([table cell modify 1:1:$mirror:$indx] == true ) } {
		   set orientation "MY90"
	         } elseif { ([table cell modify 1:1:$angle:$indx] == 270 ) && ([table cell modify 1:1:$mirror:$indx] == false ) } {
		   set orientation "R270"
	         } elseif { ([table cell modify 1:1:$angle:$indx] == 270 ) && ([table cell modify 1:1:$mirror:$indx] == true ) } {
		   set orientation "MX90"
	         } else {
		   set orientation "UNKNOWN ORIENTATION"     
		 }	
                 lassign [highlight coords $id] x1 y1 x2 y2
                 set coords [list $x1 $y1 $x2 $y2 $x1 $y1 $x1 $y1 $x1 $y2] 
                 set cid [lappend cid  [callout add [list coords $coords arrowType none fillColor $fill_color charHeight 12 lineColor $outline_color lineWidth 1 outlineWidth $width charHeight 10000 text $orientation name "$group_name/$cell"]]]
		 set indx [expr $indx + 1]
           }
           highlight delete $hid
      }
      return $cid 
}


#  Read file and prepare fields 
proc read_info {choice} {
variable site 
    set groupSelectionFile "/slowfs/${site}/GDSreviews/scripts/icwbev/common"
    set groupSelectionFileTxt "HMcoloringGroups_all.txt"
    set currentDir [pwd]
    default find_limit 5000
    puts "${currentDir} ${groupSelectionFile} ${groupSelectionFileTxt}" 
    if { [catch {open ${currentDir}/${groupSelectionFileTxt} r} fh] == 1 } {
    	if { [catch {open ${groupSelectionFile}/${groupSelectionFileTxt} r} fh] } {
    	    puts $outFile "ERROR! Grop selection File:  ${topCellsTxt} file  does not find. Execution interrupted!"
    	    puts "ERROR! Grop selection File:  ${topCellsTxt} file  does not find. Execution interrupted!"
   	    return 1
	}
    }	    

    global groupDel
    set groupDel {}  	
    while {[gets $fh data] >= 0} {
	if {[string index $data 1 ] == "#"} {
	    continue
	}
	lassign [split $data "\t | "] groupName colorIndex cellsStr
	set cellAll [split $cellsStr ,]
	set cellNames {}
	foreach cellNoEmpty $cellAll { 
	    if {[catch {layout child_to_parent $cellNoEmpty} err] != 0 } {
	    	if {[catch {layout child_to_parent [string toupper $cellNoEmpty]} err] != 0} {
		
		    continue
		} else { 
		    set cellNames [lappend cellNames [string toupper $cellNoEmpty]]
		}          
	         continue
	    } else {   
	    	set cellNames [lappend cellNames $cellNoEmpty]
	    }    
	}
	if {$cellNames == ""} {
	    continue
	}
	if { [string match "c*" $choice ] } {
	    if {[catch { set groupID [highlight_contour $groupName  $colorIndex  $cellNames]} err] != 0 } {
	         continue
	    } else { 
	        echo "Selected  [llength $groupID ] of $cellNames cell"  
	    	set groupID [lappend groupID $groupName]
	    }	    
	} elseif { [string match "m*" $choice ] } {
            if {[catch { set groupID [highlight_contour $groupName  #ffffff  $cellNames] } err] != 0 } {
                 continue
            } else {
                echo "Selected  [llength $groupID ] of $cellNames cell"
                set groupID [lappend groupID $groupName]
            }
        } elseif { [ string match "f*" $choice ] } { 
	    if {[catch {set groupID [highlight_fill $groupName $colorIndex $colorIndex $cellNames 1 ]} err] != 0 } {
	         continue
	    } else {   
	        echo "Selected  [llength $groupID ]  of $cellNames cell"  
	    	set groupID [lappend groupID $groupName]
	    }	    	    
	} elseif { [string match "v*" $choice ] } {
            if {[catch { set groupID [create_csv $groupName $cellNames]} err] != 0 } {
                 continue
            } else {
                echo "Selected  [llength $groupID ] of $cellNames cell"
##                set groupID [lappend groupID $groupName]
            }
	} else {
	     echo "Keyword $choice is not defined. Nothinq to do"
	     return -1
	}
        global set groupDel [lappend groupDel $groupID]
    }
    close $fh
    return $groupDel	
}

# Delete highlighted 
proc delete_highlighted {groupName} {
    global groupDel
    if { $groupName == "*"} {
        foreach delID $groupDel {
            for { set i 0} { $i < [llength $delID] - 1 } {incr i} {
	        if {[catch {set xx [select delete [lindex $delID $i] ]} err] != 0 } {
	    	    continue
	    	}
	    }    
	}
    } else {
    	foreach delGroup $groupDel {
	    if { [lindex $delGroup end] == $groupName} {
	        for { set i 0} { $i < [llength $delGroup] - 1 } {incr i} {
	            if {[catch {set xx [select delete [lindex $delGroup $i] ]} err] != 0 } {
	    	    	continue
	    	    }
		}    
	    } else {
	        echo "Group $groupName not found." 
	    	continue
	    }
	} 
    }
}

#############################  Main Programm ################################

##gui treeview tearoff "/Layout Files/[file tail [layout filename [layout active]]] \[[layout active]\]/Open Cells/[cell active ]/Highlights"

gui cellview menu add -in default -label getXY -command {echo "[expr %1/1000.0] [expr %2/1000.0]"}

################################################################################
# No Linting Area
################################################################################
# nolint Main