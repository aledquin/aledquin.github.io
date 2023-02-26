set rulesnotapplicable(std) [list \
"1.2" \
"2.1b" \
"2.1s" \
"2.1jj" \
"2.1ss" \
"2.1iii" \
"2.1c" \
"2.1w" \
"2.1kk" \
"2.1uu" \
"2.1uu2" \
"2.1jjj" \
"2.1d" \
"2.1x" \
"2.1ll" \
"2.1vv" \
"2.1lll" \
"2.1e" \
"2.1e1" \
"2.1e2" \
"2.1e3" \
"2.1e4" \
"2.1e5" \
"2.1y" \
"2.1mm" \
"2.1yy" \
"2.1mmm" \
"2.1f" \
"2.1z" \
"2.1nn" \
"2.1aaa" \
"2.1nnn" \
"2.1i" \
"2.1ee" \
"2.1ee1" \
"2.1ee2" \
"2.1oo" \
"2.1bbb" \
"2.1k" \
"2.1ff" \
"2.1pp" \
"2.1ccc" \
"2.1o" \
"2.1gg" \
"2.1qq" \
"2.1fff" \
"2.1r" \
"2.1hh" \
"2.1rr" \
"2.1ggg" \
"2.1ggg-c" \
"2.1.1a" \
"2.1.1b" \
"2.1.1c" \
"2.1.1d" \
"2.1.1e" \
"2.1.1f" \
"2.1.1g" \
"2.1.1h" \
"2.1.1i" \
"2.1.1j" \
"2.1.1k" \
"2.1.1l" \
"2.1.1m" \
"2.1.1p" \
]

proc ruleApplicable { rulemessage } {
	global SVAR
	global rulesnotapplicable

	set rule $rulemessage
	set firstspace [string first " " $rulemessage]
	if { $firstspace != -1 } {
		incr firstspace -1
		set firstdash [string first "-" $rulemessage]
		if { $firstdash != -1 } {
			incr firstdash
		} else {
			set firstdash 0
		}
		set rule [string range $rulemessage $firstdash $firstspace]
		set rule [string trimright $rule )]
	}
	
	set product ddr54
	if { [info exists rulesnotapplicable($product)] &&
	     [lsearch -exact $rulesnotapplicable($product) $rule] != -1 } {
		return 0
	}
	if { [info exists rulesapplicable($product)] } {
		if { [lsearch -exact $rulesapplicable($product) $rule] != -1 } {
			return 1
		} else {
			return 0
		}	
	}
	
	return 1
}

proc ruleWarningApplicable { warningmessage } {
	if { [ruleApplicable $warningmessage] } {
		puts "SNPS_WARNING: $warningmessage"
	}
}

proc ruleErrorApplicable { errormessage } {
	if { [ruleApplicable $errormessage] } {
		if { [string first "PCSQA-1" $errormessage] != -1 } {
			## PCSQA-1.x -> PCSQA-1
			catch { exec sh -c "echo '$errormessage' | sed -e 's/PCSQA\\-1\\.\[0-9\]/PCSQA-1/'" } errormessage
		}
		puts "SNPS_ERROR  : $errormessage"
	}
}

## -----------------------------------------------------------------------------
## HEADER $Id: //sps/flow/iprel/scripts_global/bob/multi_something.tcl#2 $
## HEADER_MSG    Lynx Design System: Production Flow
## HEADER_MSG    Version 2011.09-SP3
## HEADER_MSG    Copyright (c) 2012 Synopsys
## HEADER_MSG    Perforce Label: lynx_flow_2011.09-SP3
## HEADER_MSG
## -----------------------------------------------------------------------------
## DESCRIPTION:
## * This is the standard decision script for data management.
## * The decision being made is promote vs restore.
## -----------------------------------------------------------------------------

## -----------------------------------------------------------------------------
## HISTORY
##
## 01/13/2015, ahogenhu
##             Rule 2.1e is also applicable for includes of cad/lib.defs (STAR 9000848417)
##             An error in case of inside the scope of a PCS, a warning in case of outside.
##             Rule 2.2d is also applicable for includes of design/lib.defs
##             Replacement of PROJ_HOME after CAD_PROJ_HOME
##             Replacement of MSIP_PROJ_HOME and udecadrep
##             Support of dirname as prefix at includes and defines if the original definition does not exist
##             Check installation issues with p4, take then perforce instead		
##
## 02/11/2015, ahogenhu
## 	       Rule 2.1jk: Module checking is not treating letter case properly (STAR 9000861108)
##
## 02/12/2015, ahogenhu
##             Rule-2.1jk: pt01 outputing strange output (STAR 9000862020)
##
## 03/04/2015, ahogenhu
##             Fix: only expansion of METAL_STACK macro in cad/lib.defs, use in referred files only the
##                  applicable metal stack. 
##
## 03/05/2015, ahogenhu
##             Fix: expansion of CAD_METAL_STACK for recursive analysis (inside CCS) of cad/lib.defs at rule 2.1e
##
## 04/03/2015, ahogenhu
##             PCSQA not dealling correctly with 3 number CCSs (STAR 9000873515)
##             Support of setenv MSIP_CAD_PROJ_NAME and MSIP_CAD_REL_NAME in project.env at updating CCS to relX.Y.Z
##
## 04/03/2015, ahogenhu
##             Do not accept at checking links a CCS with postfix: 
##             character after refccs in target has to be '/' (STAR 9000881908)
##
## 04/16/2015, ahogenhu
##             Use always synopsys group in case of synopsys group id (STAR 9000887094)
##
## 06/09/2015, ahogenhu
##             Insensitive for space after (INCLUDE) statements (STAR 9000910452)
##
## 06/09/2015, ahogenhu
##             Support of PCS Parent/Child relationship in project.env (PCS QA specification 4.1 2.1a) (STAR 9000897886)
##             If design directory in PCS is link, then it must be a link to /remote/proj/<PCS>/design (PCS QA specification 4.1 2.1i)
##
## 06/16/2015, ahogenhu
##             Design directory in PCS has to have ug+r & o+r & go-w & g+s permissions (PCS QA specification 4.1 2.1i)
##
## 06/17/2015, ahogenhu
##             If design directory in PCS is link to /remote/proj/<PCS>/design
##             then design directory has to have ug+rw & o+r & o-w & g+s permissions (PCS QA specification 4.1 2.1i)
##
## 06/18/2015, ahogenhu
##             Fix at PCSQA-2.1n: definition of $udecadrep/proj/ as prefix of CCS path to distinguish
##                                from $udecadrep/projects as prefix of ude3 PCS path
##
## 06/29/2015, ahogenhu
##             If design directory in PCS is link, then link to /remote/proj/<PCS>/design/ is also supported
##             (PCS QA specification 4.1 2.1i) (STAR 9000920272)
##
## 06/29/2015, ahogenhu
##             Fall back on /usr/local/bin/p4,
##             if module load p4 or perforce does not exist anymore (CCT 2000739921)
##
## 01/25/2016, ahogenhu
##             PCSQA-2.1ee1 (PCS QA specification 5.1)
## -----------------------------------------------------------------------------




if { [info command getWorkDir] != "getWorkDir" } {
	proc getWorkDir { checksourcedir } {
		set workdir ../$checksourcedir
		if { [file exists $workdir] && [file isdirectory $workdir] } {
			## until Lynx 2018.06-SP1
			return $workdir
		}
		set workdir ../../$checksourcedir/work
		if { [file exists $workdir] && [file isdirectory $workdir] } {
			## since Lynx 2018.06-SP1
			return $workdir
		}
		return ""
	}
}

set uniqueprefix alvaro_ddr54_d820-ddr54v2-tsmc5ffp12_rel1.30a_mrvl_sup1_

set checks 0

set udeproj   $::env(udeproj)
set ude3proj  $::env(udecadrep)/projects

proc gettargetfile { file } {
	## the error from ls -l, if file is not permitted to access, will not result in link
	## this prevent fatal tcl error at readlink
	## in this case original file is returned
	catch { exec sh -c "ls -l $file 2> /dev/null | awk '{print \$11}' | head -1" } link
	if { $link != "" } {
		catch { exec sh -c "dirname $file" } dirlink
		cd $dirlink
		set file [file normalize [file readlink $file]]
	}
	return $file
}

proc matchpermissions { actpermissions reqpermissions } {
	if { [string length $reqpermissions] != 9 } {
   	     	puts "SNPS_ERROR  : (PCSQA) Internal error: required permissions at proc matchpermissions not length of 9"
		return 1
	}

	set ugopermissions [string range $actpermissions [expr [string length $actpermissions] - 3] [expr [string length $actpermissions] - 1]]
	set revbinugopermissions ""	
	for { set i 0 } { $i <= 2 } { incr i } {
		set elperm [string index $ugopermissions $i]
		binary scan $elperm b3 binperm
		set revbinugopermissions "$binperm${revbinugopermissions}"
	}
	set binugopermissions ""	
	for { set i 8 } { $i >= 0 } { incr i -1 } {
		set binperm [string index $revbinugopermissions $i]
		set binugopermissions "${binugopermissions}$binperm"		
	}
	
	set match 1
	for { set i 0 } { $i <= 8 } { incr i } {
		set reqbinperm [string index $reqpermissions $i]
		if { $reqbinperm == "x" } {
			continue
		} else {
			set actbinperm [string index $binugopermissions $i]
			if { $actbinperm != $reqbinperm } {
				set match 0
				break
			}			
		}
	}

	return $match	
}

proc pcsqa21e_msg { file msgtext } {

  	global pcs
	
	if { [string equal -length [string length $pcs] $pcs $file] == 1 } {
   	     	ruleErrorApplicable "$msgtext"
	} else {
   	     	ruleWarningApplicable "$msgtext"
	}
}

proc checkpermissions { typefile file parentfile } {

  	
	global checks
	global udeproj
	global ude3proj

	set cadrepproj "$::env(udecadrep)/proj"
	set projcad    "$udeproj/cad"
	set cadrepfab  "$::env(udecadrep)/fab"
	set cadrepmsip "$::env(udecadrep)/msip"
	set cadrepmsippdklegacy "$cadrepmsip/cd/pdk/pPDK/libraries_legacy"
	set cadrepmsippdklibraries "$cadrepmsip/cd/pdk/pPDK/libraries"

	set targetfile [gettargetfile $file]

	## set fileowner  [file attributes $file -owner]
	## get the owner via ls --author !
	## the tcl file statement gives/can give the temporary (?) user from the ACL list
	set filegroup     [file attributes $targetfile -group]
	if { [file isdirectory $file] } {
		catch { exec sh -c "ls -dl --author $targetfile | awk '{ print \$5 }'" } fileowner
		catch { exec sh -c "ls -dn $targetfile | awk '{ print \$4 }'" } filegroupid
	} else {  
		catch { exec sh -c "ls -l --author $targetfile | awk '{ print \$5 }'" } fileowner
		catch { exec sh -c "ls -n  $targetfile | awk '{ print \$4 }'" } filegroupid
	}
	set synopsys	  31
	if { $filegroupid == $synopsys } {
		set filegroup "synopsys"
	}
	set sg_pdks 	  65859
	set cad_sga_rel	  22938
	set root	  0
	set wwcad         66067	
	set permissions   [file attributes $targetfile -permissions]
	set gopermissions [string range $permissions [expr [string length $permissions] - 2] [expr [string length $permissions] - 1]]
	set gomw_gopr_permissions     "xxx10x10x"
	set gomw_gopr_permissions_txt "go-w & go+r"
	set gomw_gpr_permissions      "xxx10xx0x"
	set gomw_gpr_permissions_txt  "go-w & g+r"
	if { [string compare -length [string length $cadrepproj] $cadrepproj $file] == 0 || [string compare -length [string length $projcad ] $projcad $file] == 0 } {
		incr checks
		if { $fileowner != "csadmin" } {
   	     		pcsqa21e_msg $file "(PCSQA-2.1e1 in01) $typefile in $parentfile is not owned by csadmin: $file ($fileowner:$filegroup)"
   		}
		incr checks
		if { $filegroupid != $sg_pdks } {
   	     		pcsqa21e_msg $file "(PCSQA-2.1e1 in01) $typefile in $parentfile file does not belong to $sg_pdks (sg_pdks) group ID: $file ($fileowner:$filegroupid\($filegroup\))"
   		}
		incr checks
   		if { [matchpermissions $permissions $gomw_gopr_permissions] == 0 } {
   	     		pcsqa21e_msg $file "(PCSQA-2.1e1 in01) $typefile in $parentfile file has not $gomw_gopr_permissions_txt permissions: $file (x$gopermissions)"
   		}
	} else {
		if { [string compare -length [string length $cadrepfab] $cadrepfab $file] == 0 } {
			incr checks
			if { $fileowner != "csadmin" } {
   	     			pcsqa21e_msg $file "(PCSQA-2.1e2 in01) $typefile in $parentfile is not owned by csadmin: $file ($fileowner:$filegroup)"
   			}
			incr checks
			if { $filegroupid != $sg_pdks } {
   	     			pcsqa21e_msg $file "(PCSQA-2.1e2 in01) $typefile in $parentfile file does not belong to $sg_pdks (sg_pdks) group ID: $file ($fileowner:$filegroupid\($filegroup\))"
   			}
			incr checks
   			if { [matchpermissions $permissions $gomw_gpr_permissions] == 0 } {
   	     			pcsqa21e_msg $file "(PCSQA-2.1e2 in01) $typefile in $parentfile file has not $gomw_gpr_permissions_txt permissions: $file (x$gopermissions)"
   			}
		} else {
			if { [string compare -length [string length $cadrepmsip] $cadrepmsip $file] == 0 } {
				set node ""
				if { [string compare -length [string length $cadrepmsippdklibraries] $cadrepmsippdklibraries $file] == 0 } {
					set nodeendindex [expr [string first / $file [expr [string length $cadrepmsippdklibraries] + 1]] - 1] 
					set node [string range $file 0 $nodeendindex]
				}
				if { [string compare -length [string length $cadrepmsippdklegacy] $cadrepmsippdklegacy $file] == 0 ||
				     ( $node != "" && [file type $node] == "link" ) } { ## node link to cadrepmsippdklegacy
					incr checks
					if { $fileowner != "root" } {
   	     					pcsqa21e_msg $file "(PCSQA-2.1e3 in01) $typefile in $parentfile is not owned by root: $file ($fileowner:$filegroup)"
   					}
					incr checks
					if { $filegroupid != $root } {
   	     					pcsqa21e_msg $file "(PCSQA-2.1e3 in01) $typefile in $parentfile file does not belong to $root (root) group ID: $file ($fileowner:$filegroupid\($filegroup\))"
   					}
					incr checks
					if { [matchpermissions $permissions $gomw_gopr_permissions] == 0 } {
   	     					pcsqa21e_msg $file "(PCSQA-2.1e3 in01) $typefile in $parentfile file has not $gomw_gopr_permissions_txt permissions: $file (x$gopermissions)"
   					}
				} else {
					incr checks
					if { $fileowner != "csadmin" } {
   	     					pcsqa21e_msg $file "(PCSQA-2.1e3 in01) $typefile in $parentfile is not owned by csadmin: $file ($fileowner:$filegroup)"
   					}
					incr checks
					if { $filegroupid != $wwcad } {
   	     					pcsqa21e_msg $file "(PCSQA-2.1e3 in01) $typefile in $parentfile file does not belong to $wwcad (wwcad) group ID: $file ($fileowner:$filegroupid\($filegroup\))"
   					}
					incr checks
					if { [matchpermissions $permissions $gomw_gpr_permissions] == 0 } {
   	     					pcsqa21e_msg $file "(PCSQA-2.1e3 in01) $typefile in $parentfile file has not $gomw_gpr_permissions_txt permissions: $file (x$gopermissions)"
   					}
				}
			} else {
				if { [string compare -length [string length "/global"] "/global" $file] == 0 } {
					incr checks
					if { $fileowner != "root" && $fileowner != "ids_cm" } {
   	     					pcsqa21e_msg $file "(PCSQA-2.1e4 in01) $typefile in $parentfile is not owned by root or ids_cm: $file ($fileowner:$filegroup)"
   					}
					set opermissions [string range $permissions [expr [string length $permissions] - 1] [expr [string length $permissions] - 1]]
					incr checks
    					if { [matchpermissions $permissions "xxxxxx1xx"] == 0 } {
   	     					pcsqa21e_msg $file "(PCSQA-2.1e4 in01) $typefile in $parentfile file has not o+r permissions: $file (xx$opermissions)"
   					}
				} else {
					if { [string compare -length [string length "dummy"] "dummy" $file] != 0 &&
					     ( [string compare -length [string length $::env(PCSQA_PROJ_ROOT)] $::env(PCSQA_PROJ_ROOT) $file] != 0 ||
					       ( [string compare -length [string length $::env(PCSQA_PROJ_ROOT)] $::env(PCSQA_PROJ_ROOT) $file] == 0 && 
					         $::env(PCSQA_PROJ_ROOT) == $ude3proj ) ) } {
						incr checks
						if { $fileowner != "csadmin" } {
   	     						pcsqa21e_msg $file "(PCSQA-2.1e5 in01) $typefile in $parentfile is not owned by csadmin: $file ($fileowner:$filegroup)"
   						}
						incr checks
						if { $filegroupid != $sg_pdks } {
   	     						pcsqa21e_msg $file "(PCSQA-2.1e5 in01) $typefile in $parentfile file does not belong to $sg_pdks (sg_pdks) group ID: $file ($fileowner:$filegroupid\($filegroup\))"
   						}
						set permissions [string range $permissions [expr [string length $permissions] - 3] [expr [string length $permissions] - 1]]
						incr checks
   						if { [matchpermissions $permissions $gomw_gpr_permissions] == 0 } {
   	     						pcsqa21e_msg $file "(PCSQA-2.1e5 in01) $typefile in $parentfile file has not $gomw_gpr_permissions_txt permissions: $file ($permissions)"
   						}
					}
				}
			}
		}
	}
}

set run_dir $::env(udescratch)/$::env(USER)/pcsqa/tmp
cd $run_dir


if { [exec uname] == "SunOS" } {
  set exec_cmd bash
} else {
  set exec_cmd sh
}

catch { exec $exec_cmd -c "/usr/local/bin/siteid" } siteid

set getp4contentwork [getWorkDir get_p4_content]
set p4root [file normalize $getp4contentwork]

set pcs $::env(PCSQA_PROJ_ROOT)/ddr54/d820-ddr54v2-tsmc5ffp12/rel1.30a_mrvl_sup1
set msipprojroot $ude3proj
if { [file isdirectory $pcs] == 0 } {
	set pcs [file normalize $getp4contentwork/ddr54/d820-ddr54v2-tsmc5ffp12/rel1.30a_mrvl_sup1]
	set msipprojroot [file normalize $getp4contentwork]
}

if { $siteid == "in01" } {
	set pcsdesign $pcs/design
	if { [file isdirectory $pcsdesign] && [file type $pcsdesign] != "link" } {
		if { "in01" != "de02" && "in01" != "us01" && "in01" != "in01" } {
			puts "SNPS_WARNING: PCSQA is not applicable for site in01, because design directory in PCS is no link"
			exit 0
		} else {
			puts "SNPS_WARNING: design directory in PCS for site in01 is no link"
		}
	}
} 

set projectenv $pcs/cad/project.env
set msip_parentchild_type ""
set msip_parentchild_type_values [list "PARENT" "CHILD_CAD_SETUP" "CHILD_RnD_LIBS" "CHILD_ALL"]
if { [file exists $projectenv] } {
	catch { exec $exec_cmd -c "cat $projectenv | grep -v -e ^\[\[:blank:\]\]*# -e unsetenv | grep setenv | grep MSIP_PARENTCHILD_TYPE | head -1 | awk '{print \$3}' | sed -e 's/\"//g'" } msip_parentchild_type
	if { $msip_parentchild_type != "" && [lsearch -exact $msip_parentchild_type_values $msip_parentchild_type] == -1 } {
		## reset in case of non-valid value
		set msip_parentchild_type ""
	}
}

set proj_home $pcs

set refccsmatchprojectenv 0
set refccsmatchlibdefs    0
set refccsredefined       0
## gets remotely value from lynx2tcl before remote submission
set refccs "/remote/cad-rep/projects/cad/c253-tsmc5ff-1.2v/rel9.3.1"
set refccstxt [getWorkDir ref_ccs]/ref_ccs.txt
if { [file exists $refccstxt] } {
	catch { exec $exec_cmd -c "cat $refccstxt | head -1" } refccs
}

set msip_cad_rel_name  MSIP_CAD_REL_NAME
set msip_cad_proj_name MSIP_CAD_PROJ_NAME
set cad_proj_home      $udeproj/cad/REFCCS/REFCCSVERSION
if { $refccs != "" } {
	set msip_cad_rel_name  [file tail $refccs]
	set msip_cad_proj_name [file tail [file dirname $refccs]]
	set cad_proj_home      $udeproj/cad/$msip_cad_proj_name/$msip_cad_rel_name
} else {
    if { [file exists $projectenv] } {
	catch { exec $exec_cmd -c "cat $projectenv | grep -v -e ^\[\[:blank:\]\]*# -e unsetenv | grep setenv | grep MSIP_CAD_PROJ_NAME | head -1 | awk '{print \$3}' | sed -e 's/\"//g'" } msip_cad_proj_name
	if { $msip_cad_proj_name == "" } {
		set msip_cad_proj_name MSIP_CAD_PROJ_NAME
	}
	catch { exec $exec_cmd -c "cat $projectenv | grep -v -e ^\[\[:blank:\]\]*# -e unsetenv | grep setenv | grep MSIP_CAD_REL_NAME  | head -1 | awk '{print \$3}' | sed -e 's/\"//g'" } msip_cad_rel_name
	if { $msip_cad_rel_name == "" } {
		set msip_cad_rel_name  MSIP_CAD_REL_NAME
	}
    }
}

## gets remotely value from lynx2tcl before remote submission
set parentpcs ""
set parentpcstxt [getWorkDir ref_ccs]/parent_pcs.txt
if { [file exists $parentpcstxt] } {
	catch { exec $exec_cmd -c "cat $parentpcstxt | head -1" } parentpcs
}

set msip_parent_pcs_rel_name      MSIP_PARENT_PCS_REL_NAME
set msip_parent_pcs_proj_name     MSIP_PARENT_PCS_PROJ_NAME
set msip_parent_pcs_product_name  MSIP_PARENT_PCS_PRODUCT_NAME
set parent_pcs_proj_home          $ude3proj/PARENTPCSPRODUCT/PARENTPCS/PARENTPCSVERSION
if { $parentpcs != "" } {
	set msip_parent_pcs_rel_name  [file tail $parentpcs]
	set msip_parent_pcs_proj_name [file tail [file dirname $parentpcs]]
	set msip_parent_pcs_product_name [file tail [file dirname [file dirname $parentpcs]]] 
	set parent_pcs_proj_home      $parentpcs
} else {
    if { [file exists $projectenv] } {
	catch { exec $exec_cmd -c "cat $projectenv | grep -v -e ^\[\[:blank:\]\]*# -e unsetenv | grep setenv | grep MSIP_PARENT_PCS_PRODUCT_NAME | head -1 | awk '{print \$3}' | sed -e 's/\"//g'" } msip_parent_pcs_product_name
	if { $msip_parent_pcs_product_name == "" } {
		set msip_parent_pcs_product_name  MSIP_PARENT_PCS_PRODUCT_NAME	
	}
	catch { exec $exec_cmd -c "cat $projectenv | grep -v -e ^\[\[:blank:\]\]*# -e unsetenv | grep setenv | grep MSIP_PARENT_PCS_PROJ_NAME    | head -1 | awk '{print \$3}' | sed -e 's/\"//g'" } msip_parent_pcs_proj_name
	if { $msip_parent_pcs_proj_name == "" } {
		set msip_parent_pcs_proj_name     MSIP_PARENT_PCS_PROJ_NAME
	}
	catch { exec $exec_cmd -c "cat $projectenv | grep -v -e ^\[\[:blank:\]\]*# -e unsetenv | grep setenv | grep MSIP_PARENT_PCS_REL_NAME     | head -1 | awk '{print \$3}' | sed -e 's/\"//g'" } msip_parent_pcs_rel_name
	if { $msip_parent_pcs_rel_name == "" } {
		set msip_parent_pcs_rel_name      MSIP_PARENT_PCS_REL_NAME
	}
    }	
}

## gets remotely value from lynx2tcl before remote submission
set vicipinsversion ""
set pinsversiontxt [getWorkDir ref_ccs]/pins_version.txt
if { [file exists $pinsversiontxt] } {
	catch { exec $exec_cmd -c "grep \"Pin product version:\" $pinsversiontxt | head -1 | awk '{ print \$4 }'" } vicipinsversion
}

## determine SYNOPSYS_CUSTOM_INSTALL
set msip_cd_version ""
set fid_loadmodules [open ${uniqueprefix}loadmodules w]
puts $fid_loadmodules "module load msip_ude/latest 2> /dev/null"
puts $fid_loadmodules "module load msip_eda_tools  2> /dev/null"
close $fid_loadmodules
if { $refccs != "" && [file exists $refccs/design/project.env] } {
	catch { exec $exec_cmd -c "cat $refccs/design/project.env | grep -v '^\[\[:blank:\]\]*#' | grep -e module | grep -e customdesigner >> ${uniqueprefix}loadmodules" } dummy
	catch { exec $exec_cmd -c "cat $refccs/design/project.env | grep -v '^\[\[:blank:\]\]*#' | grep -e unsetenv | grep -e MSIP_CD_VERSION | sed -e 's/unsetenv\\s*MSIP_CD_VERSION\[^\\n\]*/module unload customdesigner/g' >> ${uniqueprefix}loadmodules" } dummy
	catch { exec $exec_cmd -c "cat $refccs/design/project.env | grep -v '^\[\[:blank:\]\]*#' | grep -e setenv | grep -v unsetenv | grep -e MSIP_CD_VERSION | sed -e 's/setenv\\s*MSIP_CD_VERSION\\s*/module load customdesigner\\//g' -e 's/\"//g' >> ${uniqueprefix}loadmodules" } dummy
	catch { exec $exec_cmd -c "cat $refccs/design/project.env | grep -v '^\[\[:blank:\]\]*#' | grep -e setenv | grep -v unsetenv | grep -e MSIP_CD_VERSION | wc -l" } msip_cd_version_lines
	if { $msip_cd_version_lines > 0 } {
		catch { exec $exec_cmd -c "cat $refccs/design/project.env | grep -v '^\[\[:blank:\]\]*#' | grep -e setenv | grep -v unsetenv | grep -e MSIP_CD_VERSION | awk '{print \$3}' | tail -1 | sed -e 's/\"//g'" } msip_cd_version
	}
}
if { [file exists $projectenv] } {
	catch { exec $exec_cmd -c "cat $projectenv | grep -v '^\[\[:blank:\]\]*#' | grep -e module | grep -e customdesigner >> ${uniqueprefix}loadmodules" } dummy
	catch { exec $exec_cmd -c "cat $projectenv | grep -v '^\[\[:blank:\]\]*#' | grep -e unsetenv | grep -e MSIP_CD_VERSION | sed -e 's/unsetenv\\s*MSIP_CD_VERSION\[^\\n\]*/module unload customdesigner/g' >> ${uniqueprefix}loadmodules" } dummy
	catch { exec $exec_cmd -c "cat $projectenv | grep -v '^\[\[:blank:\]\]*#' | grep -e setenv | grep -v unsetenv | grep -e MSIP_CD_VERSION | sed -e 's/setenv\\s*MSIP_CD_VERSION\\s*/module load customdesigner\\//g' -e 's/\"//g' >> ${uniqueprefix}loadmodules" } dummy
	catch { exec $exec_cmd -c "cat $projectenv | grep -v '^\[\[:blank:\]\]*#' | grep -e setenv | grep -v unsetenv | grep -e MSIP_CD_VERSION | wc -l" } msip_cd_version_lines
	if { $msip_cd_version_lines > 0 } {
		catch { exec $exec_cmd -c "cat $projectenv | grep -v '^\[\[:blank:\]\]*#' | grep -e setenv | grep -v unsetenv | grep -e MSIP_CD_VERSION | awk '{print \$3}' | tail -1 | sed -e 's/\"//g'" } msip_cd_version
	}
}
catch { exec $exec_cmd -c "source $::env(MODULESHOME)/init/bash 2> /dev/null && module purge 2> /dev/null && chmod u+x ${uniqueprefix}loadmodules && source ${uniqueprefix}loadmodules 2> /dev/null && which cdesigner" } cdesigner 
if { [file exists $cdesigner] } {
	set cddir [file dirname [file dirname $cdesigner]]
	set synopsyscustominstall $cddir/auxx
	if { $msip_cd_version == "" } {
		catch { exec $exec_cmd -c "basename $cddir | sed 's/customdesigner_//g'" } msip_cd_version
	}
} else {
	set synopsyscustominstall SYNOPSYS_CUSTOM_INSTALL
}
if { $msip_cd_version == "" } {
	set msip_cd_version MSIP_CD_VERSION
}

set macroreplace "sed -e 's/\"//g' -e 's#siteid#$siteid#g' -e 's#udecadrep#$::env(udecadrep)#g' -e 's/MSIP_CD_VERSION/$msip_cd_version/g' -e 's#SYNOPSYS_CUSTOM_INSTALL#$synopsyscustominstall#g' -e 's#MSIP_PROJ_HOME#$proj_home#g' -e 's#MSIP_PROJ_ROOT#$msipprojroot#g' -e 's#MSIP_PRODUCT_NAME#ddr54#g' -e 's#MSIP_PROJ_NAME#d820-ddr54v2-tsmc5ffp12#g' -e 's#MSIP_REL_NAME#rel1.30a_mrvl_sup1#g' -e 's#\\\$env##g' -e 's#\[(\]##g' -e 's#\[)\]##g' -e 's#\\\$##g' -e 's#\{##g' -e 's#\}##g'"
## Replace of PROJ_HOME after CAD_PROJ_HOME
set ccsreplace         "-e 's#CAD_PROJ_HOME#$cad_proj_home#g' -e 's#MSIP_CAD_REL_NAME#$msip_cad_rel_name#g' -e 's#MSIP_CAD_PROJ_NAME#$msip_cad_proj_name#g' -e 's#PROJ_HOME#$proj_home#g'"
set parentpcsreplace   "-e 's#MSIP_PARENT_PCS_PRODUCT_NAME#$msip_parent_pcs_product_name#g' -e 's#MSIP_PARENT_PCS_REL_NAME#$msip_parent_pcs_rel_name#g' -e 's#MSIP_PARENT_PCS_PROJ_NAME#$msip_parent_pcs_proj_name#g'"

proc matchccs { refccs pcsccs } {

	if { [string compare -length [string length $refccs] $refccs $pcsccs] == 0 &&
	     [expr [string length $refccs] + 2] == [string length $pcsccs] &&
	     [string index $pcsccs [expr [string length $pcsccs] - 2]] == "." &&
	     [string is digit [string index $pcsccs [expr [string length $pcsccs] - 1]]] } {
	     	return 1
	} else {
		return 0
	}

}

if { $siteid == "in01" } {
incr checks
if { [file exists $projectenv] } {
	catch { exec $exec_cmd -c "cat $projectenv | grep -v -e ^\[\[:blank:\]\]*# -e unsetenv | grep setenv | grep MSIP_PARENT_PCS_PRODUCT_NAME | head -1 | awk '{print \$3}' | sed -e 's/\"//g'" } msip_parent_pcs_product_name
	catch { exec $exec_cmd -c "cat $projectenv | grep -v -e ^\[\[:blank:\]\]*# -e unsetenv | grep setenv | grep MSIP_PARENT_PCS_PROJ_NAME    | head -1 | awk '{print \$3}' | sed -e 's/\"//g'" } msip_parent_pcs_proj_name
	catch { exec $exec_cmd -c "cat $projectenv | grep -v -e ^\[\[:blank:\]\]*# -e unsetenv | grep setenv | grep MSIP_PARENT_PCS_REL_NAME     | head -1 | awk '{print \$3}' | sed -e 's/\"//g'" } msip_parent_pcs_rel_name
	if { $msip_parentchild_type != "CHILD_RnD_LIBS" && $msip_parentchild_type != "PARENT" && $msip_parent_pcs_product_name != "" && $msip_parent_pcs_proj_name != "" && $msip_parent_pcs_rel_name != "" } {
		## Support of PCS Parent/Child relationship (PCS QA specification 4.1)
		catch { exec $exec_cmd -c "cat $projectenv | grep -v -e ^\[\[:blank:\]\]*# -e setenv | sed -e '/^\\s*$/d' -e 's/\\s\\s*$//g' | head -1 | awk '{print \$2}' | sed -e 's#MSIP_PROJ_ROOT#$ude3proj#g' | $macroreplace -e 's/MSIP_PARENT_PCS_PRODUCT_NAME/$msip_parent_pcs_product_name/g' -e 's/MSIP_PARENT_PCS_PROJ_NAME/$msip_parent_pcs_proj_name/g' -e 's/MSIP_PARENT_PCS_REL_NAME/$msip_parent_pcs_rel_name/g'" } parentprojectenv
		set refparentprojectenv "$ude3proj/$msip_parent_pcs_product_name/$msip_parent_pcs_proj_name/$msip_parent_pcs_rel_name/cad/project.env"
		if { $parentprojectenv != $refparentprojectenv } {
			if { $msip_parentchild_type == "CHILD_CAD_SETUP" } {
				ruleErrorApplicable "(PCSQA-2.1.1e in01) First line of PCS project.env file is not source of a Parent PCS project.env: $parentprojectenv"
			} else {
				ruleErrorApplicable "(PCSQA-2.1a in01) First line of PCS project.env file is not source of a Parent PCS project.env: $parentprojectenv"
			}
		}
	} else {
	if { ( $msip_parentchild_type == "" || $msip_parentchild_type != "CHILD_CAD_SETUP" ) && $refccs != "" } {
	set refccsprojectenv "$refccs/design/project.env"
	if { [file exists $refccsprojectenv] } {
		set refccsprojectenv [file normalize $refccsprojectenv] 
	}
	catch { exec $exec_cmd -c "cat $projectenv | grep -v -e ^\[\[:blank:\]\]*# -e unsetenv | grep setenv | grep MSIP_CAD_PROJ_NAME | head -1 | awk '{print \$3}' | sed -e 's/\"//g'" } msip_cad_proj_name
	catch { exec $exec_cmd -c "cat $projectenv | grep -v -e ^\[\[:blank:\]\]*# -e unsetenv | grep setenv | grep MSIP_CAD_REL_NAME  | head -1 | awk '{print \$3}' | sed -e 's/\"//g'" } msip_cad_rel_name
	if { $msip_cad_proj_name == "" || $msip_cad_rel_name == "" } {
		set msip_cad_rel_name  [file tail $refccs]
		set msip_cad_proj_name [file tail [file dirname $refccs]]
	}
	set cad_proj_home $udeproj/cad/$msip_cad_proj_name/$msip_cad_rel_name
	set ccsreplace    "-e 's#CAD_PROJ_HOME#$cad_proj_home#g' -e 's#MSIP_CAD_REL_NAME#$msip_cad_rel_name#g' -e 's#MSIP_CAD_PROJ_NAME#$msip_cad_proj_name#g' -e 's#PROJ_HOME#$proj_home#g'"
	catch { exec $exec_cmd -c "cat $projectenv | grep -v -e ^\[\[:blank:\]\]*# -e setenv | sed -e '/^\\s*$/d' -e 's/\\s\\s*$//g' | head -1 | awk '{print \$2}' | $macroreplace $ccsreplace" } ccsprojectenv
	if { [file exists $ccsprojectenv] } {
		set ccsprojectenv [file normalize $ccsprojectenv] 
	}
	incr checks
	if { $ccsprojectenv != $refccsprojectenv } {
		set ccsmatch 0
		if { [file exists $refccsprojectenv] && [file exists $ccsprojectenv] && $refccsredefined == 0 } {
			catch { exec $exec_cmd -c "dirname \$(dirname $refccsprojectenv)" } normrefccs
			catch { exec $exec_cmd -c "dirname \$(dirname $ccsprojectenv)" } normpcsccs
			set ccsmatch [matchccs $normrefccs $normpcsccs]
		}

		if { $ccsmatch == 0 } {
			catch { exec $exec_cmd -c "cat $projectenv | grep -v -e ^\[\[:blank:\]\]*# -e setenv | sed -e '/^\\s*$/d' -e 's/\\s\\s*$//g' | head -1 | $macroreplace $ccsreplace" } firstline
			ruleErrorApplicable "(PCSQA-2.1a in01) First line of PCS project.env file is not source of CCS project.env: $firstline"
		} else {
			## redefine refccs
			## Support of setenv MSIP_CAD_PROJ_NAME and MSIP_CAD_REL_NAME in project.env 
			catch { exec $exec_cmd -c "cat $projectenv | grep -v -e ^\[\[:blank:\]\]*# -e unsetenv | grep setenv | grep MSIP_CAD_PROJ_NAME | head -1 | awk '{print \$3}' | sed -e 's/\"//g'" } msip_cad_proj_name
			catch { exec $exec_cmd -c "cat $projectenv | grep -v -e ^\[\[:blank:\]\]*# -e unsetenv | grep setenv | grep MSIP_CAD_REL_NAME  | head -1 | awk '{print \$3}' | sed -e 's/\"//g'" } msip_cad_rel_name
			catch { exec $exec_cmd -c "cat $projectenv | grep -v -e ^\[\[:blank:\]\]*# -e setenv | sed -e '/^\\s*$/d' -e 's/\\s\\s*$//g' | head -1 | awk '{print \$2}' | sed -e 's/\${MSIP_CAD_PROJ_NAME}/$msip_cad_proj_name/g' -e 's/\$MSIP_CAD_PROJ_NAME/$msip_cad_proj_name/g' -e 's/\${MSIP_CAD_REL_NAME}/$msip_cad_rel_name/g' -e 's/\$MSIP_CAD_REL_NAME/$msip_cad_rel_name/g'" } ccsprojectenv
			catch { exec $exec_cmd -c "dirname \$(dirname $ccsprojectenv)" } refccs
			catch { exec $exec_cmd -c "basename \$(dirname $refccs)" } msip_cad_proj_name 
			set msip_cad_rel_name  [file tail $refccs]
			set cad_proj_home      $udeproj/cad/$msip_cad_proj_name/$msip_cad_rel_name
			set refccs 	       $cad_proj_home
			set ccsreplace         "-e 's#CAD_PROJ_HOME#$cad_proj_home#g' -e 's#MSIP_CAD_REL_NAME#$msip_cad_rel_name#g' -e 's#MSIP_CAD_PROJ_NAME#$msip_cad_proj_name#g' -e 's#PROJ_HOME#$proj_home#g'"
			puts "Reference CCS redefined to $refccs due to PCS project.env"
			set refccsredefined 1
		}		
	} else {
		set refccsmatchprojectenv 1
		incr checks
		catch { exec $exec_cmd -c "grep ^\[\[:blank:\]\]*setenv\[\[:blank:\]\]*RUN_DIR_ROOT $projectenv | grep -v ^\[\[:blank:\]\]*# | wc -l" } rundirrootavailable
		if { $rundirrootavailable > 0 } {
			catch { exec $exec_cmd -c "grep ^\[\[:blank:\]\]*setenv\[\[:blank:\]\]*RUN_DIR_ROOT $projectenv | grep -v ^\[\[:blank:\]\]*# | tail -1 | awk '{print \$3}' | sed -e 's/\"//g' -e 's/\{//g' -e 's/\}//g'" } rundirrootvalue
##			if { $msip_parentchild_type == "PARENT" } {
##				set refvalue "\$udescratch/\$USER/verification/\$MSIP_PARENT_PCS_PRODUCT_NAME/\$MSIP_PARENT_PCS_PROJ_NAME/\$MSIP_PARENT_PCS_REL_NAME/\$METAL_STACK"
##			} else {
				set refvalue "\$udescratch/\$USER/verification/\$MSIP_PRODUCT_NAME/\$MSIP_PROJ_NAME/\$MSIP_REL_NAME/\$METAL_STACK"
##			}
			if { $rundirrootvalue != $refvalue } {
				ruleErrorApplicable "(PCSQA-2.1v in01) Value of redefinition of RUN_DIR_ROOT in PCS project.env file is '$rundirrootvalue' and not '$refvalue'"		
			}
		} 
##		Not mandatory any more since PCS QA spec 14.1
##		else {
##			ruleErrorApplicable "(PCSQA-2.1v in01) No redefinition of RUN_DIR_ROOT in PCS project.env file is available"		
##		}
	}
	set msip_cad_rel_name  [file tail $refccs]
	set msip_cad_proj_name [file tail [file dirname $refccs]]
	set cad_proj_home      $udeproj/cad/$msip_cad_proj_name/$msip_cad_rel_name
	set ccsreplace         "-e 's#CAD_PROJ_HOME#$cad_proj_home#g' -e 's#MSIP_CAD_REL_NAME#$msip_cad_rel_name#g' -e 's#MSIP_CAD_PROJ_NAME#$msip_cad_proj_name#g' -e 's#PROJ_HOME#$proj_home#g'"
	}
	}
	if { [file exists $pcs/design/project.env] } {
		catch { exec $exec_cmd -c "ls -l $pcs/design/project.env 2> /dev/null | awk '{print \$11}'" } projectenvtarget
		incr checks
		if { $projectenvtarget != "" } {
			cd $pcs/design
			set projectenvtarget [file normalize [file readlink $pcs/design/project.env]]
			if { $projectenvtarget != [file normalize $projectenv] } {
				ruleErrorApplicable "(PCSQA-2.1l in01) design/project.env is no link to cad/project.env"
			}
		} else {
			ruleErrorApplicable "(PCSQA-2.1l in01) design/project.env is no link to cad/project.env"
		}		
	}
} else {
	ruleErrorApplicable "(PCSQA-1.1 in01) No project.env file found at $projectenv"
} 

proc checkdefines { file parentfile usemetalstack } {

	global pcs
	global macroreplace 
	global ccsreplace
	global parentpcsreplace
	global checks

	catch { exec sh -c "cat $file | grep -v ^\[\[:blank:\]\]*# | grep DEFINE | grep -v -e UNDEFINE -e PROJ_P4_ROOT | awk '{print \$3}' | $macroreplace $ccsreplace $parentpcsreplace" } defines
	set defines [split $defines \n]
	foreach define $defines {
		if { [file isdirectory $define] == 0 || [string index $define 0] == "." } {
			## try dirname of file as prefix 
			catch { exec sh -c "dirname $file" } dirname
			set dirnamedefine "$dirname/$define"
			if { [file isdirectory $dirnamedefine] } {
				set define $dirnamedefine
			}
		}
		if { [file isdirectory $define] == 0 } {
			incr checks
			if { [string first METAL_STACK $define] == -1 } {
				pcsqa21e_msg $define "(PCSQA-2.1e in01) Refered library in $parentfile file does not exists: $define"
			} else {
				if { $usemetalstack == "all" } {
					set envtcls [glob -nocomplain $pcs/cad/*/env.tcl]
				} else {
					if { [file exists $pcs/cad/$usemetalstack/env.tcl] } {
						set envtcls [list "$pcs/cad/$usemetalstack/env.tcl"]
					} else {
						set envtcls [list]
					}
				}
				foreach envtcl $envtcls {
					catch { exec sh -c "basename \$(dirname $envtcl)" } metalstack
					catch { exec sh -c "echo '$define' | sed -e 's#\$\{CAD_METAL_STACK\}#$metalstack#g' -e 's#CAD_METAL_STACK#$metalstack#g' -e 's#\$\{METAL_STACK\}#$metalstack#g' -e 's#METAL_STACK#$metalstack#g'" } metaldefine
					incr checks
					if { [file isdirectory $metaldefine] == 0 } {
						pcsqa21e_msg $metaldefine "(PCSQA-2.1e in01) Refered library in $parentfile file does not exists: $metaldefine"
					} else {
						set metaldefine [gettargetfile $metaldefine]
						checkpermissions "Refered library" $metaldefine $parentfile
					}
				}
			}
		} else {
			set define [gettargetfile $define]
			checkpermissions "Refered library" $define $parentfile
		}
	}	

}

## ensure the files visited by checkincludes will be treated once
set filesvisited [list]

proc checkincludes { file parentfile usemetalstack } {

	global pcs
	global macroreplace 
	global ccsreplace
	global parentpcsreplace
	global checks
	global filesvisited

	catch { exec sh -c "cat $file | grep -v ^\[\[:blank:\]\]*# | grep INCLUDE     | grep -v -e PROJ_P4_ROOT -e SOFTINCLUDE | awk '{print \$2}' | $macroreplace $ccsreplace $parentpcsreplace" } includes
	catch { exec sh -c "cat $file | grep -v ^\[\[:blank:\]\]*# | grep SOFTINCLUDE | grep -v -e PROJ_P4_ROOT                | awk '{print \$2}' | $macroreplace $ccsreplace $parentpcsreplace" } softincludes
	set includes [split $includes \n]
	set softincludes [split $softincludes \n]
	set soft 0
	while { $soft <= 1 } {

	if { $soft == 0 } {
		set includeslist $includes
	} else {
		set includeslist $softincludes
	}
	
	foreach include $includeslist {
		if { [file exists $include] == 0 } {
			## try dirname of file as prefix 
			catch { exec sh -c "dirname $file" } dirname
			set dirnameinclude "$dirname/$include"
			if { [file exists $dirnameinclude] } {
				set include $dirnameinclude
			}
		}
		if { [file exists $include] == 0 } {
			incr checks
			if { [string first METAL_STACK $include] == -1 } {
				if { $soft == 0 } {
					pcsqa21e_msg $include "(PCSQA-2.1e in01) Include file in $parentfile file does not exists: $include"
				}
			} else {
				if { $usemetalstack == "all" } {
					set envtcls [glob -nocomplain $pcs/cad/*/env.tcl]
				} else {
					if { [file exists $pcs/cad/$usemetalstack/env.tcl] } {
						set envtcls [list "$pcs/cad/$usemetalstack/env.tcl"]
					} else {
						set envtcls [list]
					}
				}
				foreach envtcl $envtcls {
					catch { exec sh -c "basename \$(dirname $envtcl)" } metalstack
					catch { exec sh -c "echo '$include' | sed -e 's#\$\{CAD_METAL_STACK\}#$metalstack#g' -e 's#CAD_METAL_STACK#$metalstack#g' -e 's#\$\{METAL_STACK\}#$metalstack#g' -e 's#METAL_STACK#$metalstack#g'" } metalinclude
					incr checks
					if { [file exists $metalinclude] == 0 } {
						if { $soft == 0 } {
							pcsqa21e_msg $metalinclude "(PCSQA-2.1e in01) Include file in $parentfile file does not exists: $metalinclude"
						}
					} else {
						set metalinclude [gettargetfile $metalinclude]
						checkpermissions "Include file" $metalinclude $parentfile
						if { [lsearch -exact $filesvisited $metalinclude] == -1 } {
							lappend filesvisited $metalinclude
							checkincludes    $metalinclude  $metalinclude $metalstack
							checkdefines     $metalinclude  $metalinclude $metalstack
						}
					}
				}
			}
		} else {
			set include [gettargetfile $include]
			checkpermissions "Include file" $include $parentfile 
			if { [lsearch -exact $filesvisited $include] == -1 } {
				lappend filesvisited $include
				checkincludes    $include $include $usemetalstack
				checkdefines     $include $include $usemetalstack
			}
		}
	}	

	incr soft
	}

}

set libdefs $pcs/cad/lib.defs
incr checks
if { [file exists $libdefs] } {
	if { ( ( $msip_parentchild_type == "" || ( $msip_parentchild_type != "CHILD_CAD_SETUP" && $msip_parentchild_type != "CHILD_ALL" ) ) && $refccs != "" ) ||
	     ( ( $msip_parentchild_type == "CHILD_CAD_SETUP" || $msip_parentchild_type == "CHILD_ALL" ) && $parentpcs != "" ) } {
	if { ( $msip_parentchild_type == "" || ( $msip_parentchild_type != "CHILD_CAD_SETUP" && $msip_parentchild_type != "CHILD_ALL" ) ) && $refccs != "" } { 	     
		set refccslibdefs "$refccs/design/lib.defs"
		set addparentpcsreplace ""
	} else {
		set refccslibdefs "$parentpcs/cad/lib.defs"
		set addparentpcsreplace $parentpcsreplace
	}
	if { [file exists $refccslibdefs] } {
		set refccslibdefs [file normalize $refccslibdefs]
	}
	catch { exec $exec_cmd -c "cat $libdefs | grep -v ^\[\[:blank:\]\]*# | sed -e '/^\\s*$/d' -e 's/\\s\\s*$//g' | head -1 | awk '{print \$2}' | sed -e 's/\"//g' | $macroreplace $ccsreplace $addparentpcsreplace" } ccslibdefs
	if { [file exists $ccslibdefs] } {
		set ccslibdefs [file normalize $ccslibdefs]
	}
	incr checks
	if { $ccslibdefs != $refccslibdefs } {
		if { $msip_parentchild_type != "CHILD_CAD_SETUP" && $msip_parentchild_type != "CHILD_ALL" } {
		set refccslibdefs "$refccs/design/lib_common.defs"
		if { [file exists $refccslibdefs] } {
			set refccslibdefs [file normalize $refccslibdefs]
		} else {
			## try matchccs with ref CCS lib.defs
			set refccslibdefs "$refccs/design/lib.defs"
			if { [file exists $refccslibdefs] } {
				set refccslibdefs [file normalize $refccslibdefs]
			}
		}
		}
		if { $ccslibdefs != $refccslibdefs } {
			set ccsmatch 0
			if { [file exists $refccslibdefs] && [file exists $ccslibdefs] && $refccsredefined == 0 } {
				catch { exec $exec_cmd -c "dirname \$(dirname $refccslibdefs)" } normrefccs
				catch { exec $exec_cmd -c "dirname \$(dirname $ccslibdefs)" } normpcsccs
				if { $msip_parentchild_type != "CHILD_CAD_SETUP" && $msip_parentchild_type != "CHILD_ALL" } {
					set ccsmatch [matchccs $normrefccs $normpcsccs]
				} else {
					if { [string compare $normrefccs $normpcsccs] == 0 } {
						set ccsmatch 1
					}
				}
			}

			if { $ccsmatch == 0 } {	
				catch { exec $exec_cmd -c "cat $libdefs | grep -v ^\[\[:blank:\]\]*# | sed -e '/^\\s*$/d' -e 's/\\s\\s*$//g' | head -1 | $macroreplace $ccsreplace $addparentpcsreplace" } firstline
				if { $msip_parentchild_type != "CHILD_CAD_SETUP" && $msip_parentchild_type != "CHILD_ALL" } {
					ruleErrorApplicable "(PCSQA-2.1b in01) First line of PCS lib.defs file is no INCLUDE of CCS lib\[_common\].defs: $firstline"
				} else {
					ruleErrorApplicable "(PCSQA-2.1.1f in01) First line of PCS lib.defs file is no INCLUDE of Parent PCS lib.defs: $firstline"
				}
			} else {
				if { $msip_parentchild_type != "CHILD_CAD_SETUP" && $msip_parentchild_type != "CHILD_ALL" } {
				
				if { $refccsmatchprojectenv == 1 } {
					ruleErrorApplicable "(PCSQA-2.1n in01) Inconsistent CCS $refccs used in PCS project.env; redefinition in PCS lib.defs"
				}

				## redefine refccs
				catch { exec $exec_cmd -c "cat $libdefs | grep -v ^\[\[:blank:\]\]*# | sed -e '/^\\s*$/d' -e 's/\\s\\s*$//g' | head -1 | awk '{print \$2}' | sed -e 's/\"//g' | $macroreplace $ccsreplace" } ccslibdefs
				catch { exec $exec_cmd -c "dirname \$(dirname $ccslibdefs)" } refccs
				set msip_cad_rel_name  [file tail $refccs]
				set cad_proj_home      $udeproj/cad/$msip_cad_proj_name/$msip_cad_rel_name
				set refccs 	       $cad_proj_home
				set ccsreplace         "-e 's#CAD_PROJ_HOME#$cad_proj_home#g' -e 's#MSIP_CAD_REL_NAME#$msip_cad_rel_name#g' -e 's#MSIP_CAD_PROJ_NAME#$msip_cad_proj_name#g' -e 's#PROJ_HOME#$proj_home#g'"
				puts "Reference CCS redefined to $refccs due to PCS lib.defs"
				set refccsredefined 1
				
				}
			}			
		}		
	} else {
		set refccsmatchlibdefs 1
	}
	}

	lappend filesvisited $libdefs
	checkincludes $libdefs "PCS lib.defs" "all"
	checkdefines  $libdefs "PCS lib.defs" "all"

} else {
	ruleErrorApplicable "(PCSQA-1.2 in01) No lib.defs file found at $libdefs"
}
}

set p4errors 0
if { $siteid == "in01" } {
	set p4libdefs $run_dir/${uniqueprefix}lib.defs
} else {
	## resync to get p4 updates (like .PCSQA_STATUS file)
	cd $p4root
	set perforceapps [list "p4" "perforce"]
	set perforce ""
	foreach perforceapp $perforceapps {
		catch { exec $exec_cmd -c ". $::env(MODULESHOME)/init/bash && module avail $perforceapp > p4avail 2>&1" } dummy
		if { [file size p4avail] == 0 } {
			continue
		} else {
			catch { exec $exec_cmd -c ". $::env(MODULESHOME)/init/bash && module load $perforceapp > p4load 2>&1" } dummy
			catch { exec $exec_cmd -c "grep -e \"There is an installation issue for\" -e \"Unable to locate a modulefile for\" p4load | wc -l" } issues
			if { $issues > 0 } {
				continue
			} else {
				set perforce $perforceapp
				break
			}
		}
	}
	catch { exec $exec_cmd -c "rm -f p4avail p4load" } dummy
	if { $perforce != "" } {
		set p4 "p4"
		set moduleloadperforce "&& module load $perforce"
	} else {
		set p4 "/usr/local/bin/p4"
		set moduleloadperforce ""
	}

	if { [file exists msip_pcsqa_template] } {
		catch { exec $exec_cmd -c "grep \"^Client\" msip_pcsqa_template | awk '{ print \$2 }'" } clientname
		catch { exec $exec_cmd -c ". $::env(MODULESHOME)/init/bash $moduleloadperforce && $p4 client -i < msip_pcsqa_template" } dummy 
		catch { exec $exec_cmd -c ". $::env(MODULESHOME)/init/bash $moduleloadperforce && export P4CONFIG=\".p4config\" && $p4 sync -f ddr54/d820-ddr54v2-tsmc5ffp12/rel1.30a_mrvl_sup1/..." } p4message 
		if { $p4message == "ddr54/d820-ddr54v2-tsmc5ffp12/rel1.30a_mrvl_sup1/... - protected namespace - access denied." } {			
			## get p4 content via account csadmin to bypass restricted access
			catch { exec $exec_cmd -c "chmod -R 777 ddr54" } dummy
			set SSH "export PASSWORD=$::env(PCSQA_PASSWORD); $SEV(gscript_dir)/qa_scripts/sshaskpass ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no csadmin@$::env(HOST)"
			catch { exec bash -c "$SSH \"cd $p4root && export P4CONFIG=.p4config && /usr/local/bin/p4 sync -f ddr54/d820-ddr54v2-tsmc5ffp12/rel1.30a_mrvl_sup1/...\"" } p4message
			catch { exec $exec_cmd -c "chmod -R 755 ddr54" } dummy
		}	 
		catch { exec $exec_cmd -c ". $::env(MODULESHOME)/init/bash $moduleloadperforce && $p4 client -d $clientname" } dummy 
	}
	cd $run_dir
	set p4libdefs $p4root/ddr54/d820-ddr54v2-tsmc5ffp12/rel1.30a_mrvl_sup1/design/lib.defs
}

proc checkp4defines { file parentfile usemetalstack } {

	global pcs
	global macroreplace 
	global ccsreplace
	global parentpcsreplace
	global checks

	catch { exec sh -c "cat $file | grep -v ^\[\[:blank:\]\]*# | grep DEFINE | grep -v -e UNDEFINE -e PROJ_P4_ROOT | awk '{print \$3}' | $macroreplace $ccsreplace $parentpcsreplace" } defines
	set defines [split $defines \n]
	foreach define $defines {
		if { [file isdirectory $define] == 0 || [string index $define 0] == "." } {
			## try dirname of file as prefix 
			catch { exec sh -c "dirname $file" } dirname
			set dirnamedefine "$dirname/$define"
			if { [file isdirectory $dirnamedefine] } {
				set define $dirnamedefine
			}
		}
		if { [file isdirectory $define] == 0 } {
			incr checks
			if { [string first METAL_STACK $define] == -1 } {
				ruleWarningApplicable "(PCSQA-2.2d in01) Refered library in $parentfile file does not exists: $define"
			} else {
				if { $usemetalstack == "all" } {
					set envtcls [glob -nocomplain $pcs/cad/*/env.tcl]
				} else {
					if { [file exists $pcs/cad/$usemetalstack/env.tcl] } {
						set envtcls [list "$pcs/cad/$usemetalstack/env.tcl"]
					} else {
						set envtcls [list]
					}
				}
				foreach envtcl $envtcls {
					catch { exec sh -c "basename \$(dirname $envtcl)" } metalstack
					catch { exec sh -c "echo '$define' | sed -e 's#\$\{CAD_METAL_STACK\}#$metalstack#g' -e 's#CAD_METAL_STACK#$metalstack#g' -e 's#\$\{METAL_STACK\}#$metalstack#g' -e 's#METAL_STACK#$metalstack#g'" } metaldefine
					incr checks
					if { [file isdirectory $metaldefine] == 0 } {
						ruleWarningApplicable "(PCSQA-2.2d in01) Refered library in $parentfile file does not exists: $metaldefine"
					} else {
						set metaldefine  [gettargetfile $metaldefine]
						set permissions  [file attributes $metaldefine -permissions]
						set gpermissions [string range $permissions [expr [string length $permissions] - 2] [expr [string length $permissions] - 2]]					
						incr checks
						if { [string compare $gpermissions "4" ] == -1 } {
							ruleWarningApplicable "(PCSQA-2.2d in01) Refered library in $parentfile file has not at least read permission for group: $metaldefine"
						}
					}
				}
			}
		} else {
			set targetdefine [gettargetfile $define]
			set permissions  [file attributes $targetdefine -permissions]
			set gpermissions [string range $permissions [expr [string length $permissions] - 2] [expr [string length $permissions] - 2]]					
			incr checks
			if { [string compare $gpermissions "4" ] == -1 } {
				ruleWarningApplicable "(PCSQA-2.2d in01) Refered library in $parentfile file has not at least read permission for group: $define"
			}
		}
	}

}

proc checkatp4depot { include parentfile } {
	if { [string first PROJ_P4_ROOT $include] != -1 || [string first MSIP_PROJ_P4WS_ROOT  $include] != -1 } {
		catch { exec sh -c "echo '$include' | sed -e 's#\$\{PROJ_P4_ROOT\}#//wwcad/msip#g' -e 's#PROJ_P4_ROOT#//wwcad/msip#g' -e 's#\$\{MSIP_PROJ_P4WS_ROOT\}#//wwcad/msip#g' -e 's#MSIP_PROJ_P4WS_ROOT#//wwcad/msip#g'" } p4include
		catch { exec sh -c "p4 files -e $p4include" } p4result
		if { [string first "no such file" $p4result] != -1 } {
			ruleWarningApplicable "(PCSQA-2.2d in01) Include file in $parentfile file does not exists in p4: $include as $p4include in p4"
		}
	} else {
		ruleWarningApplicable "(PCSQA-2.2d in01) Include file in $parentfile file does not exists: $include"
	}
}

## ensure the files visited by checkp4includes will be treated once
set filesvisited [list]

proc checkp4includes { file parentfile usemetalstack } {

	global pcs
	global macroreplace 
	global ccsreplace
	global parentpcsreplace
	global checks
	global filesvisited

	catch { exec sh -c "cat $file | grep -v ^\[\[:blank:\]\]*# | grep INCLUDE | awk '{print \$2}' | $macroreplace $ccsreplace $parentpcsreplace" } includes
	set includes [split $includes \n]
	foreach include $includes {
		if { [file exists $include] == 0 } {
			## try dirname of file as prefix 
			catch { exec sh -c "dirname $file" } dirname
			set dirnameinclude "$dirname/$include"
			if { [file exists $dirnameinclude] } {
				set include $dirnameinclude
			}
		}
		if { [file exists $include] == 0 } {
			incr checks
			if { [string first METAL_STACK $include] == -1 } {
				checkatp4depot $include $parentfile
				## ruleWarningApplicable "(PCSQA-2.2d in01) Include file in $parentfile file does not exists: $include"
			} else {
				if { $usemetalstack == "all" } {
					set envtcls [glob -nocomplain $pcs/cad/*/env.tcl]
				} else {
					if { [file exists $pcs/cad/$usemetalstack/env.tcl] } {
						set envtcls [list "$pcs/cad/$usemetalstack/env.tcl"]
					} else {
						set envtcls [list]
					}
				}
				foreach envtcl $envtcls {
					catch { exec sh -c "basename \$(dirname $envtcl)" } metalstack
					catch { exec sh -c "echo '$include' | sed -e 's#\$\{CAD_METAL_STACK\}#$metalstack#g' -e 's#CAD_METAL_STACK#$metalstack#g' -e 's#\$\{METAL_STACK\}#$metalstack#g' -e 's#METAL_STACK#$metalstack#g'" } metalinclude
					incr checks
					if { [file exists $metalinclude] == 0 } {
						checkatp4depot $include $parentfile
						## ruleWarningApplicable "(PCSQA-2.2d in01) Include file in $parentfile file does not exists: $metalinclude"
					} else {
						set targetmetalinclude [gettargetfile $metalinclude]
						set permissions  [file attributes $targetmetalinclude -permissions]
						set gpermissions [string range $permissions [expr [string length $permissions] - 2] [expr [string length $permissions] - 2]]					
						incr checks
						if { [string compare $gpermissions "4" ] == -1 } {
							ruleWarningApplicable "(PCSQA-2.2d in01) Include file in $parentfile file has not at least read permission for group: $metalinclude"
						}
						if { [lsearch -exact $filesvisited $metalinclude] == -1 } {
							lappend filesvisited $metalinclude
							checkp4includes $metalinclude $metalinclude $metalstack
							checkp4defines  $metalinclude $metalinclude $metalstack
						}
					}
				}
			}
		} else {
			set targetinclude [gettargetfile $include]
			set permissions  [file attributes $targetinclude -permissions]
			set gpermissions [string range $permissions [expr [string length $permissions] - 2] [expr [string length $permissions] - 2]]					
			incr checks
			if { [string compare $gpermissions "4" ] == -1 } {
				ruleWarningApplicable "(PCSQA-2.2d in01) Include file in $parentfile file has not at least read permission for group: $include"
			}
			if { [lsearch -exact $filesvisited $include] == -1 && "$include" != "$pcs/cad/lib.defs" } { ## $pcs/cad/lib.defs already checked by 2.1e
				lappend filesvisited $include
				checkp4includes $include $include $usemetalstack
				checkp4defines  $include $include $usemetalstack
			}
		}
	}
		
}

if { [file exists $p4libdefs] } {
	if { $siteid != "in01" } {

	catch { exec $exec_cmd -c "cat $p4libdefs | grep -v ^\[\[:blank:\]\]*# | sed -e '/^\\s*$/d' -e 's/\\s\\s*$//g' -e 's/\\s\\s*/ /g' | head -1" } firstline
	set reffirstline  "INCLUDE \${PROJ_HOME}/cad/lib.defs"
	set reffirstline2 "INCLUDE \$PROJ_HOME/cad/lib.defs"
	incr checks
	if { $firstline != $reffirstline && $firstline != $reffirstline2 } {
		ruleErrorApplicable "(PCSQA-2.1d) First line of p4 PCS design/lib.defs is not equal to: $reffirstline"	
		if { [ruleApplicable "2.1d"] } {
			puts "SNPS_ERROR  :              First line is: $firstline"	
			incr p4errors
		}
	}	

	} else {

	lappend filesvisited $p4libdefs
	checkp4includes	$p4libdefs "p4 PCS design/lib.defs" "all"
	checkp4defines	$p4libdefs "p4 PCS design/lib.defs" "all"
	
	}	
}

if { $siteid == "in01" } {
if { ( ( $msip_parentchild_type == "" || ( $msip_parentchild_type != "CHILD_CAD_SETUP" && $msip_parentchild_type != "CHILD_ALL" ) ) && $refccs != "" ) ||
     ( ( $msip_parentchild_type == "CHILD_CAD_SETUP" || $msip_parentchild_type == "CHILD_ALL" ) && $parentpcs != "" ) } {
set envtcls [glob -nocomplain $pcs/cad/*/env.tcl]
foreach envtcl $envtcls {
	catch { exec $exec_cmd -c "basename \$(dirname $envtcl)" } metalstack
	incr checks
	if { $msip_parentchild_type != "CHILD_CAD_SETUP" && $msip_parentchild_type != "CHILD_ALL" } {
		set parentstack $refccs/cad/$metalstack
		set addparentpcsreplace ""
	} else {
		set parentstack $parentpcs/cad/$metalstack
		set addparentpcsreplace $parentpcsreplace
	}
	if { [file isdirectory $parentstack] } {
		set refccsenvtcl "$parentstack/env.tcl"
		catch { exec $exec_cmd -c "cat $envtcl | grep -v ^\[\[:blank:\]\]*# | sed -e '/^\\s*$/d' -e 's/\\s\\s*$//g' | head -1 | awk '{print \$2}' | $macroreplace $ccsreplace $addparentpcsreplace | sed -e 's#CAD_METAL_STACK#$metalstack#g' -e 's#METAL_STACK#$metalstack#g'" } ccsenvtcl
		if { $ccsenvtcl != $refccsenvtcl } {
			catch { exec $exec_cmd -c "cat $envtcl | grep -v ^\[\[:blank:\]\]*# | sed -e '/^\\s*$/d' -e 's/\\s\\s*$//g' | head -1 | $macroreplace $ccsreplace $addparentpcsreplace | sed -e 's#CAD_METAL_STACK#$metalstack#g' -e 's#METAL_STACK#$metalstack#g'" } firstline
			incr checks
			if { [file exists $ccsenvtcl] } {
				set ccsenvtcl    [file normalize $ccsenvtcl]
				set refccsenvtcl [file normalize $refccsenvtcl]
				if { $ccsenvtcl != $refccsenvtcl } {
					set ccsmatch 0
					if { [file exists $refccsenvtcl] && [file exists $ccsenvtcl] && $refccsredefined == 0 } {
						catch { exec $exec_cmd -c "dirname \$(dirname \$(dirname $refccsenvtcl))" } normrefccs
						catch { exec $exec_cmd -c "dirname \$(dirname \$(dirname $ccsenvtcl))" } normpcsccs
						if { $msip_parentchild_type != "CHILD_CAD_SETUP" && $msip_parentchild_type != "CHILD_ALL" } {
							set ccsmatch [matchccs $normrefccs $normpcsccs]
						} else {
							if { [string compare $normrefccs $normpcsccs] == 0 } {
								set ccsmatch 1
							}
						}
					}

					if { $ccsmatch == 0 } {	
						if { $msip_parentchild_type != "CHILD_CAD_SETUP" && $msip_parentchild_type != "CHILD_ALL" } {
							ruleErrorApplicable "(PCSQA-2.1c in01) First line of PCS cad/$metalstack/env.tcl file is no source of CCS env.tcl: $firstline"
						} else {
							ruleErrorApplicable "(PCSQA-2.1.1g in01) First line of PCS cad/$metalstack/env.tcl file is no source of Parent PCS env.tcl: $firstline"
						}
					} else {
						if { $msip_parentchild_type != "CHILD_CAD_SETUP" && $msip_parentchild_type != "CHILD_ALL" } {

						if { $refccsmatchprojectenv == 1 } {
							ruleErrorApplicable "(PCSQA-2.1n in01) Inconsistent CCS $refccs used in PCS project.env; redefinition in PCS cad/$metalstack/env.tcl"
							set refccsmatchprojectenv 0
						}
						if { $refccsmatchlibdefs == 1 } {
							ruleErrorApplicable "(PCSQA-2.1n in01) Inconsistent CCS $refccs used in PCS lib.defs; redefinition in PCS cad/$metalstack/env.tcl"
							set refccsmatchlibdefs 0
						}

						## redefine refccs
						catch { exec $exec_cmd -c "cat $envtcl | grep -v ^\[\[:blank:\]\]*# | sed -e '/^\\s*$/d' -e 's/\\s\\s*$//g' | head -1 | awk '{print \$2}' | $macroreplace $ccsreplace | sed -e 's#CAD_METAL_STACK#$metalstack#g' -e 's#METAL_STACK#$metalstack#g'" } ccsenvtcl
						catch { exec $exec_cmd -c "dirname \$(dirname \$(dirname $ccsenvtcl))" } refccs
						set msip_cad_rel_name  [file tail $refccs]
						set cad_proj_home      $udeproj/cad/$msip_cad_proj_name/$msip_cad_rel_name
						set refccs 	       $cad_proj_home
						set ccsreplace         "-e 's#CAD_PROJ_HOME#$cad_proj_home#g' -e 's#MSIP_CAD_REL_NAME#$msip_cad_rel_name#g' -e 's#MSIP_CAD_PROJ_NAME#$msip_cad_proj_name#g' -e 's#PROJ_HOME#$proj_home#g'"
						puts "Reference CCS redefined to $refccs due to PCS cad/$metalstack/env.tcl"
						set refccsredefined 1
						
						}
					}			
				}
			} else {
				if { $msip_parentchild_type != "CHILD_CAD_SETUP" && $msip_parentchild_type != "CHILD_ALL" } {
					ruleErrorApplicable "(PCSQA-2.1c in01) First line of PCS cad/$metalstack/env.tcl file is no source of CCS env.tcl: $firstline"
				} else {
					ruleErrorApplicable "(PCSQA-2.1.1g in01) First line of PCS cad/$metalstack/env.tcl file is no source of Parent PCS env.tcl: $firstline"
				}
			}					
		} else {		
			if { $msip_parentchild_type != "CHILD_CAD_SETUP" && $msip_parentchild_type != "CHILD_ALL" } {
			
			catch { exec $exec_cmd -c "cat $envtcl | grep -v -e ^\[\[:blank:\]\]*# -e ^source | sed -e '/^\\s*$/d' -e 's/\\s\\s*$//g' | wc -l" } morecodelines
			incr checks
			if { $morecodelines > 0 } {
				ruleWarningApplicable "(PCSQA-2.2a in01) There is additional code in PCS cad/$metalstack/env.tcl file other than source of CCS env.tcl"					
			}
			
			}
		}
	} else {
		if { $msip_parentchild_type != "CHILD_CAD_SETUP" && $msip_parentchild_type != "CHILD_ALL" } {
			ruleErrorApplicable "(PCSQA-2.1f in01) PCS metal stack $metalstack does not exists in CCS $refccs/cad"
		} else {
			ruleErrorApplicable "(PCSQA-2.1.1g in01) PCS metal stack $metalstack does not exists in Parent PCS $parentpcs/cad"
		}		
	}
}
}

proc checkcadpermissions { file } {

		global checks

		set diroption "d"
		if { [file isdirectory $file] } {
			set filetype "directory"
		} else {
			set filetype "file"
			set diroption ""
		}

		set targetfile [gettargetfile $file]

		## set cadowner [file attributes $file -owner]
		## get the owner via ls --author !
		## the tcl file statement gives/can give the temporary (?) user from the ACL list
		catch { exec sh -c "ls -${diroption}l --author $targetfile | awk '{ print \$5 }'" } cadowner
		incr checks
		if { $cadowner != "csadmin" } {
			ruleErrorApplicable "(PCSQA-2.1h in01) $file $filetype in PCS is not owned by csadmin, but $cadowner"
		}
		set sg_pdks 65859
		catch { exec sh -c "ls -${diroption}n $targetfile | awk '{ print \$4 }'" } filegroupid
		incr checks
		if { $filegroupid != $sg_pdks } {
			ruleErrorApplicable "(PCSQA-2.1h in01) $file $filetype in PCS does not belong to $sg_pdks (sg_pdks) group ID, but $filegroupid"
		}
		set cadpermissions [file attributes $targetfile -permissions]
		set gomw_gopr_permissions     "xxx10x10x"
		set gomw_gopr_permissions_txt "go-w & go+r & g+s"
		if { [file isdirectory $file] } {
			set gs_cadpermissions 	      [string range $cadpermissions 0 2]
			set gs_cadpermissions         "000$gs_cadpermissions"
			set gs_permissions            "xxxxxxx1x"
			set gs_check 		      [matchpermissions $gs_cadpermissions $gs_permissions]
		} else {
			set gomw_gopr_permissions_txt "go-w & go+r"
			set gs_check 		      1
		}
		incr checks
		if { [matchpermissions $cadpermissions $gomw_gopr_permissions] == 0 || $gs_check == 0 } {
			set cadugopermissions [string range $cadpermissions [expr [string length $cadpermissions] - 3] [expr [string length $cadpermissions] - 1]]
			if { $gs_check == 0 } {
				set cadugopermissions "$cadugopermissions and no group sticky"
			}
			ruleErrorApplicable "(PCSQA-2.1h in01) $file $filetype in PCS has not $gomw_gopr_permissions_txt permissions, but $cadugopermissions"
		}

		set subfiles [glob -nocomplain $file/*]		
		foreach subfile $subfiles {
			catch { exec sh -c "ls -dl $subfile 2> /dev/null | awk '{ print \$11 }'" } link
			if { ( [file isdirectory $subfile] || [file isfile $subfile] ) && $link == "" } {
				checkcadpermissions $subfile
			}
		}
}

if { [file exists $projectenv] } {
   catch { exec $exec_cmd -c "cat $projectenv | grep -v '^\[\[:blank:\]\]*#' | grep -e setenv | grep -v unsetenv | grep -e MSIPRunDirRestrict\[\[:blank:\]\] | awk '{ print \$3 }' | sed -e 's/\"//g'" }  msiprundirrestrictvalue
   if { $msiprundirrestrictvalue != "" && 
        [file isdirectory $pcs/design_unrestricted] == 0 } {
	ruleErrorApplicable "(PCSQA-2.1jj in01) No design_unrestricted folder, despite of MSIPRunDirRestrict restriction in project.env"	
   }

   if { $msiprundirrestrictvalue == "" &&
        [string compare -length [string length $ude3proj] $ude3proj $pcs] == 0 } {
   
   	## Rule 2.1i is not applicable, if MSIPRunDirRestrict is defined, see rule 2.1mm
	if { [file exists $pcs/cad] } {
		if { [file type $pcs/cad] == "link" } {
			checkcadpermissions [string trimright [file readlink $pcs/cad] /]
		} else {
			checkcadpermissions $pcs/cad
		}
	}

	set pcsdesign $pcs/design
	set pcsdesignlink 0
	if { [file isdirectory $pcsdesign] && [file type $pcsdesign] == "link" } {
		set pcsdesign [string trimright [file readlink $pcsdesign] /]
		set refpcsdesign "/remote/proj/ddr54/d820-ddr54v2-tsmc5ffp12/rel1.30a_mrvl_sup1/design"
		if { $pcsdesign != $refpcsdesign } {
			ruleErrorApplicable "(PCSQA-2.1i in01) design directory in PCS is no link to $refpcsdesign, but to $pcsdesign"
		} else {
			set pcsdesignlink 1
		}		
	}
	
	if { [file isdirectory $pcsdesign] } {
		set sg_pdks 65859
		catch { exec sh -c "ls -dn $pcsdesign | awk '{ print \$4 }'" } filegroupid
		incr checks
		if { $filegroupid != $sg_pdks } {
			ruleErrorApplicable "(PCSQA-2.1i in01) design directory in PCS does not belong to $sg_pdks (sg_pdks) group ID, but $filegroupid"
		}
		set designpermissions    [file attributes $pcsdesign -permissions]
		set gs_designpermissions [string range $designpermissions 0 2]
		set gs_designpermissions "000$gs_designpermissions"
		set gs_permissions       "xxxxxxx1x"
		set gs_check 		 [matchpermissions $gs_designpermissions $gs_permissions]
		incr checks
		if { $pcsdesignlink == 0 } {
			set refdesignpermissions    "11x10x10x"
			set refdesignpermissionstxt "ug+r & o+r & go-w"
		} else {
			set refdesignpermissions    "11x11x10x"
			set refdesignpermissionstxt "ug+rw & o+r & o-w"
		}
		if { [matchpermissions $designpermissions $refdesignpermissions] == 0 || $gs_check == 0 } {
			set designugopermissions [string range $designpermissions [expr [string length $designpermissions] - 3] [expr [string length $designpermissions] - 1]]
			if { $gs_check == 0 } {
				set designugopermissions "$designugopermissions and no group sticky"
			}
			ruleErrorApplicable "(PCSQA-2.1i in01) design directory in PCS has not $refdesignpermissionstxt & g+s permissions, but $designugopermissions"
		}
	}

    }
}


proc version2int { version } {
       set versioncp $version
       if { $version != "" &&
            [string first - $version] != -1 &&
            [string first - $version] == 
            [expr [string length $version] - 2] } {
            ## replace YYYY.MM-1 by YYYY.MM-01
            set versioncp [string map {- "-0"} $version]
       }
       set versionint [string map {. "" - ""} $versioncp]
       return $versionint
}

if { [file exists $projectenv] } {
catch { exec $exec_cmd -c "grep 'module\[\[:space:\]\]' $projectenv | grep -v -e ^\[\[:blank:\]\]*# -e '^\[\[:space:\]\]*echo' -e unload -e msip -e ude_internal_tools -e helic | wc -l" } edamodules
incr checks
if { $edamodules > 0 } {
	catch { exec $exec_cmd -c "grep 'module\[\[:space:\]\]' $projectenv | grep -v -e ^\[\[:blank:\]\]*# -e '^\[\[:space:\]\]*echo' -e unload -e msip -e ude_internal_tools -e helic | awk '{print \$3}' | tr '\\n' ',' | sed -e 's/,/, /g' -e 's/, $//g'" } edamodules
	ruleErrorApplicable "(PCSQA-2.1j in01) The following EDA tools are not set by environment variable in project.env: $edamodules"
}
catch { exec $exec_cmd -c "grep setenv $projectenv | grep -v -e ^\[\[:blank:\]\]*# -e unsetenv | grep MSIP_ | grep _VERSION | wc -l" } edamodules
incr checks
if { $edamodules > 0 } {
	catch { exec $exec_cmd -c "grep setenv $projectenv | grep -v -e ^\[\[:blank:\]\]*# -e unsetenv | grep MSIP_ | grep _VERSION | awk '{print \$2}' | tr '\\n' ',' | sed -e 's/,/, /g' -e 's/, $//g'" } edamodules
	ruleWarningApplicable "(PCSQA-2.2b in01) The following EDA tools are set in project.env with non default version: $edamodules"
}

catch { exec $exec_cmd -c "grep 'module\[\[:space:\]\]' $projectenv | grep -v ^\[\[:blank:\]\]*# | grep -e load -e msip | wc -l" } msipmodules
if { $msipmodules > 0 } {

	## determine creation of PCS
	set p4port "export P4PORT=p4p-$siteid:1999"
	set pcstriple ddr54/d820-ddr54v2-tsmc5ffp12/rel1.30a_mrvl_sup1
	catch { exec $exec_cmd -c "$p4port && p4 changes //wwcad/msip/projects/$pcstriple/pcs/... | tail -1 | awk '{print \$4}'" } creationdatepcs
	catch { exec $exec_cmd -c "date +%s -d $creationdatepcs" } creationdatesecpcs
	if { [string is digit $creationdatesecpcs] == 0 } {
		set creationdatesecpcs 0
	}
	
	set creationdatesecparentpcs 0
	if { ( $msip_parentchild_type == "CHILD_CAD_SETUP" ||
	       $msip_parentchild_type == "CHILD_ALL" ) &&
	     $parentpcs != "" } {
		set parentpcstriple $msip_parent_pcs_product_name/$msip_parent_pcs_proj_name/$msip_parent_pcs_rel_name
		catch { exec $exec_cmd -c "$p4port && p4 changes //wwcad/msip/projects/$parentpcstriple/pcs/... | tail -1 | awk '{print \$4}'" } creationdateparentpcs
		catch { exec $exec_cmd -c "date +%s -d $creationdateparentpcs" } creationdatesecparentpcs
		if { [string is digit $creationdatesecparentpcs] == 0 } {
			set creationdatesecparentpcs 0
		}
	}


	set moduleloadwarning 0
	catch { exec $exec_cmd -c "grep 'module\[\[:space:\]\]' $projectenv | grep -v -e ^\[\[:blank:\]\]*# -e unload | grep msip | sed -e 's#/# #g' | awk '{print \$3}'" } msipmodules

	## PCSQA specification version 19.1
	## set mandatorynoversionmoduleslist [list "msip_cd_ceqi_dataIntegrity" "msip_cd_perforce" "msip_shell_calex" "msip_cd_ude_utils"]
	## To check this subset of ude_internal_tools to be default was a mistake.
	## ude_internal_tools should be default after PCS setup 2020, sept 1st
	set mandatorynoversionmoduleslist [list]
	set allowednoversionmoduleslist [list "msip_cd_layoutMQA"]

	set mandatorynoversionmodules ""
	set noversionmodules ""
	set wrongversionmodules ""
	set mandatorynoversionmoduleloaderror 0
	set noversionmoduleloadwarning 0
	set wrongversionmoduleloaderror 0
	set msipmodules [split $msipmodules \n]
	foreach msipmodule $msipmodules {
		catch { exec $exec_cmd -c "grep $msipmodule $projectenv | grep -v ^\[\[:blank:\]\]*# | grep module | grep load   | grep -v unload | wc -l" } moduleloads
		catch { exec $exec_cmd -c "grep $msipmodule $projectenv | grep -v ^\[\[:blank:\]\]*# | grep module | grep unload | wc -l" } moduleunloads
		incr checks
		if { $moduleloads != $moduleunloads } {
			ruleErrorApplicable "(PCSQA-2.1k in01) The internal tool $msipmodule is not set by module unload/load in project.env"
		}
		catch { exec $exec_cmd -c "grep $msipmodule $projectenv | grep -v ^\[\[:blank:\]\]*# | grep module | grep load | grep -v unload | grep \"/\" | wc -l" } moduleversionload
		incr checks
		if { [lsearch -exact $mandatorynoversionmoduleslist $msipmodule] != -1 } {
			if { $moduleversionload != 0 } {
				set mandatorynoversionmoduleloaderror 1
				set mandatorynoversionmodules "$mandatorynoversionmodules $msipmodule"
			}
		} else {
			if { $moduleversionload == 0 &&
			     [lsearch -exact $allowednoversionmoduleslist $msipmodule] == -1 } {
				set noversionmoduleloadwarning 1
				set noversionmodules "$noversionmodules $msipmodule"
			}
		}
		catch { exec $exec_cmd -c "grep $msipmodule $projectenv | grep -v ^\[\[:blank:\]\]*# | grep module | grep load | grep -v unload | grep -e \"/testing$\" -e \"/latest$\" -e \"/dev$\" | wc -l" } modulewrongversionload
		incr checks
		if { $modulewrongversionload > 0 } {
			set wrongversionmoduleloaderror 1
			set wrongversionmodules "$wrongversionmodules $msipmodule"
		}
	}
	if { $mandatorynoversionmoduleloaderror == 1 } {
		ruleErrorApplicable "(PCSQA-2.1k in01) project.env contains internal tools settings with fixed version, which should be default:$mandatorynoversionmodules"
	}
	if { $noversionmoduleloadwarning == 1 } {
		## ruleErrorApplicable "(PCSQA-2.1k in01) project.env contains internal tools settings with non default versions"
		## ruleWarningApplicable "(PCSQA-2.2b in01) project.env contains internal tools settings with non default versions"
		ruleWarningApplicable "(PCSQA-2.1k in01) project.env contains internal tools settings with default versions:$noversionmodules"
	}
	if { $wrongversionmoduleloaderror == 1 } {
		ruleErrorApplicable "(PCSQA-2.1k in01) project.env contains internal tools settings with testing, latest or dev versions:$wrongversionmodules"
	}
	

	catch { exec $exec_cmd -c "date +%s -d 2020/09/01" } sept1sec
	if { $creationdatesecpcs >= $sept1sec && 
             ( $creationdatesecparentpcs == 0 ||
	       $creationdatesecparentpcs >= $sept1sec ) } {
		set reftools [list \
				"ude_internal_tools" \
				"ude_internal_tools_falcon" \
				"msip_cd_layoutMQA" \
				"msip_cd_pv" \
				"msip_cd_lef_gen" \
				"msip_cd_hipre" \
				"msip_shared_lib" \
				"msip_cd_pPDK_utils" \
				"msip_cd_cck_gui" \
			     ]
		
		## select ude_internal_tools(_falcon) for this PCS based on CCS setting
		if { $refccs != "" && [file exists $refccs/design/project.env] } {
			catch { exec $exec_cmd -c "grep '^\[\[:space:\]\]*module\[\[:space:\]\]\[\[:space:\]\]*load\[\[:space:\]\]' $refccs/design/project.env | grep ude_internal_tools_falcon | wc -l" } ccssetfalcon
			if { $ccssetfalcon > 0 } {
				set idx [lsearch $reftools "ude_internal_tools"]
				set reftools [lreplace $reftools $idx $idx]
			} else {
				## no ude_internal_tools_falcon set
				## check previous ude_internal_tools/yyyy.mm-falcon variant
				catch { exec $exec_cmd -c "grep '^\[\[:space:\]\]*module\[\[:space:\]\]\[\[:space:\]\]*load\[\[:space:\]\]' $refccs/design/project.env | grep ude_internal_tools | awk '{ print \$3 }' | sed -e 's#/# #g' | awk '{ print \$2 }'" } ude_internal_tools_version
				if { [string first "falcon" $ude_internal_tools_version] != -1 } {
					set idx [lsearch $reftools "ude_internal_tools"]
					set reftools [lreplace $reftools $idx $idx]
				} else {
					set idx [lsearch $reftools "ude_internal_tools_falcon"]
					set reftools [lreplace $reftools $idx $idx]
				}
			}
		} else {
			set idx [lsearch $reftools "ude_internal_tools_falcon"]
			set reftools [lreplace $reftools $idx $idx]
		}

		## determine default version of all reftools at $creationdatepcs
		foreach reftool $reftools {
			catch { exec $exec_cmd -c "$p4port && p4 print //wwcad/msip/internal_tools/modulefiles/$reftool/.version@$creationdatepcs | grep ModulesVersion | awk '{ print \$3 }' | sed -e 's/\"//g'" } version
			if { $version != "" } {
				set refversion($reftool) $version
			}
		}
		## overule versions of packages in reftools, which appear in ude_tools_hipre
		catch { exec $exec_cmd -c "$p4port && p4 print //wwcad/msip/internal_tools/modulefiles/ude_tools_hipre/.version@$creationdatepcs | grep ModulesVersion | awk '{ print \$3 }' | sed -e 's/\"//g'" } ude_tools_hipre_version
		catch { exec $exec_cmd -c "source $::env(MODULESHOME)/init/bash 2> /dev/null && module purge 2> /dev/null && module show ude_tools_hipre/$ude_tools_hipre_version 2>&1 | grep ^module > $run_dir/${uniqueprefix}ude_tools_hipre_packages" } dummy
		foreach reftool $reftools {
			catch { exec $exec_cmd -c "grep $reftool $run_dir/${uniqueprefix}ude_tools_hipre_packages | wc -l" } hipre_reftool
			if { $hipre_reftool > 0 } {
				catch { exec $exec_cmd -c "grep $reftool $run_dir/${uniqueprefix}ude_tools_hipre_packages | awk '{ print \$3 }' | sed -e 's#/# #g' | awk '{ print \$2 }'" } version
				if { $version != "" } {
					set refversion($reftool) $version
				}
			}
		}
		catch { exec $exec_cmd -c "rm -f $run_dir/${uniqueprefix}ude_tools_hipre_packages" } dummy		

		if { [lsearch $reftools "ude_internal_tools"] != -1 } {
			set refversion(ude_internal_tools)        [list "unload" ""]
		}
		if { [lsearch $reftools "ude_internal_tools_falcon"] != -1 } {
			set refversion(ude_internal_tools_falcon) [list "unload" ""]
		}
		set layoutMQAdatenoversion "2021/07/18"
		catch { exec $exec_cmd -c "date +%s -d $layoutMQAdatenoversion" } layoutMQAdatenoversionsec
		## foreach reftool [array names refversion] {
		##	puts "refversion($reftool)=$refversion($reftool)"
		## }
		
		## crosscheck refversion($reftool) with version in project.env at $creationdatepcs
		set grepreftools ""
		foreach reftool $reftools {
			catch { exec $exec_cmd -c "cat $projectenv | grep '^\[\[:space:\]\]*module\[\[:space:\]\]\[\[:space:\]\]*load\[\[:space:\]\]' | grep $reftool | wc -l" } msipmodulesversions
			if { $msipmodulesversions > 1 &&
			     ( ( $reftool != "ude_internal_tools" && $reftool != "ude_internal_tools_falcon" ) || 
                               ( ( $reftool == "ude_internal_tools" || $reftool == "ude_internal_tools_falcon" ) && 
			         $msipmodulesversions > 2 ) ) } {
				ruleErrorApplicable "(PCSQA-2.1k in01) $reftool is multiple loaded in project.env"
			}
			set grepreftools "$grepreftools -e $reftool"
		}
		set parentprojectenvtxt ""	
		set parentprojectenv "$ude3proj/$msip_parent_pcs_product_name/$msip_parent_pcs_proj_name/$msip_parent_pcs_rel_name/cad/project.env"
		if { [file exists $parentprojectenv] &&
		      ( $msip_parentchild_type == "CHILD_ALL" ||
		        $msip_parentchild_type == "CHILD_CAD_SETUP" ) } {
			## Parent PCS and PCS project.env
			set msipmodulesversions [list]
			foreach reftool $reftools {
				set last 1
                              	if { $reftool == "ude_internal_tools" ||
				     $reftool == "ude_internal_tools_falcon" } {
					set last 2
				} 
				catch { exec $exec_cmd -c "cat $parentprojectenv $projectenv | \
				                                grep '^\[\[:space:\]\]*module\[\[:space:\]\]\[\[:space:\]\]*load\[\[:space:\]\]' | \
		                                                grep $reftool | tail -$last | awk '{ print \$3 }' | sed -e 's#/# #g'" } inheritmsipmodulesversions
				set inheritmsipmodulesversions [split $inheritmsipmodulesversions "\n"]
				foreach msipmodulesversion $inheritmsipmodulesversions {
					if { $msipmodulesversion != "" } {
						lappend msipmodulesversions "$msipmodulesversion"
					}
				}
			}
			set parentprojectenvtxt "(Parent PCS project.env or) PCS "			
		} else {
			## PCS project.env
			catch { exec $exec_cmd -c "cat $projectenv | \
			                                grep '^\[\[:space:\]\]*module\[\[:space:\]\]\[\[:space:\]\]*load\[\[:space:\]\]' | \
		                                        grep $grepreftools | awk '{ print \$3 }' | sed -e 's#/# #g'" } msipmodulesversions
			set msipmodulesversions [split $msipmodulesversions "\n"]
		}
		foreach msipmodulesversion $msipmodulesversions {
			catch { exec $exec_cmd -c "echo $msipmodulesversion | awk '{ print \$1 }'" } msipmodule
			catch { exec $exec_cmd -c "echo $msipmodulesversion | awk '{ print \$2 }'" } msipmoduleversion
			if { $msipmodule != "" && [lsearch $reftools $msipmodule] != -1 } {
				## wait for 1ms to prevent execute to fast on remote sites
				after 1
				if { $msipmodule == "ude_internal_tools" ||
				     $msipmodule == "ude_internal_tools_falcon" } {
					if { [lsearch -exact $refversion($msipmodule) $msipmoduleversion] == -1 } {
						ruleErrorApplicable "(PCSQA-2.1k in01) $msipmodule has incorrect version '$msipmoduleversion' setting instead of 'unload and default' at creation date $creationdatepcs of PCS in ${parentprojectenvtxt}project.env"
					} else {
						if { [info exists available($msipmodule)] == 0 } {
							set available($msipmodule) [list]
						}
						lappend available($msipmodule) $msipmoduleversion
					}
				} else {
					if { $msipmodule == "msip_cd_layoutMQA" &&
					     $creationdatesecpcs >= $layoutMQAdatenoversionsec && 
             	     			     ( $creationdatesecparentpcs == 0 ||
		       			       $creationdatesecparentpcs >= $layoutMQAdatenoversionsec ) } {
						if { $msipmoduleversion != "" } {
							ruleErrorApplicable "(PCSQA-2.1k in01) $msipmodule has incorrect version '$msipmoduleversion' setting instead of 'default' (after $layoutMQAdatenoversion) at creation date $creationdatepcs of PCS in ${parentprojectenvtxt}project.env"
						} 
						set available($msipmodule) 1
						continue
					}
								
					set msipmoduleversionint [version2int $msipmoduleversion]
					set refversionint 0
					if { [info exists refversion($msipmodule)] } {
						set refversionint [version2int $refversion($msipmodule)]
					}
					## ensure msipmoduleversionint and refversionint equal integer length
					if { $msipmoduleversion != "" &&
					     [string is integer $msipmoduleversionint] &&
					     [string is integer $refversionint] } {
						while { [string length $msipmoduleversionint] < 
					                [string length $refversionint] } {
							set msipmoduleversionint [expr $msipmoduleversionint * 10]
						}
					}
					if { [info exists refversion($msipmodule)] &&
					     [string is integer $msipmoduleversionint] &&
					     [string is integer $refversionint] } {
						while { [string length $refversionint] < 
					                [string length $msipmoduleversionint] } {
							set refversionint [expr $refversionint * 10]
						}
					}
					if { $msipmoduleversion == "" ||
					     ( [info exists refversion($msipmodule)] &&
					       [string is integer $msipmoduleversionint] &&
					       [string is integer $refversionint] &&
					       $msipmoduleversionint < $refversionint ) } {
						if { $msipmoduleversion == "" } {
							set msipmoduleversiontxt "default"
						} else {
							set msipmoduleversiontxt $msipmoduleversion
						}
						set allowviolation 0
						##  msip_cd_layoutMQA default version is allowed for projects created before July 18, 2021
						if { $msipmodule == "msip_cd_layoutMQA" &&
					             $creationdatesecpcs < $layoutMQAdatenoversionsec && 
             	     			     	     ( $creationdatesecparentpcs == 0 ||
		       			               $creationdatesecparentpcs < $layoutMQAdatenoversionsec ) &&
						     $msipmoduleversiontxt == "default" } {
							set allowviolation 1
						}
						if { $allowviolation == 0 } {
							ruleErrorApplicable "(PCSQA-2.1k in01) $msipmodule has incorrect version '$msipmoduleversiontxt' setting instead of at least '$refversion($msipmodule)' at creation date $creationdatepcs of PCS in ${parentprojectenvtxt}project.env"
						}
					}
					set available($msipmodule) 1
					
					if { [file exists $refccs/design/project.env] } {
						catch { exec $exec_cmd -c "cat $refccs/design/project.env | \
						                                grep '^\[\[:space:\]\]*module\[\[:space:\]\]\[\[:space:\]\]*load\[\[:space:\]\]' | \
										grep $msipmodule | tail -1 | awk '{ print \$3 }' | sed -e 's#/# #g'" } ccsmsipmodulesversion
						if { $ccsmsipmodulesversion != "" } {
							catch { exec $exec_cmd -c "echo $ccsmsipmodulesversion | awk '{ print \$2 }'" } ccsmsipmoduleversion
							set ccsmsipmoduleversionint [version2int $ccsmsipmoduleversion]
							## ensure msipmoduleversionint and ccsmsipmoduleversionint equal integer length
							if { $msipmoduleversion != "" &&
					     		    [string is integer $msipmoduleversionint] &&
					      		    [string is integer $ccsmsipmoduleversionint] } {
								while { [string length $msipmoduleversionint] < 
							                [string length $ccsmsipmoduleversionint] } {
									set msipmoduleversionint [expr $msipmoduleversionint * 10]
								}
							}
							if { $ccsmsipmoduleversion != "" &&
							     [string is integer $msipmoduleversionint] &&
					      		     [string is integer $ccsmsipmoduleversionint] } {
								while { [string length $ccsmsipmoduleversionint] < 
							        	[string length $msipmoduleversionint] } {
									set ccsmsipmoduleversionint [expr $ccsmsipmoduleversionint * 10]
								}
							}
							if { $msipmoduleversion != "" &&
							     $ccsmsipmoduleversion != "" && 
							     [string is integer $msipmoduleversionint] &&
					      		     [string is integer $ccsmsipmoduleversionint] &&
							     $msipmoduleversionint < $ccsmsipmoduleversionint } {
								ruleErrorApplicable "(PCSQA-2.1k in01) $msipmodule has older version '$msipmoduleversion' setting than '$ccsmsipmoduleversion' in CCS at creation date $creationdatepcs of PCS in ${parentprojectenvtxt}project.env"
							}
						}					
					}
				}
			}			
		}
		foreach reftool $reftools {
			if { ( [info exists available($reftool)] == 0 ||
			       ( ( $reftool == "ude_internal_tools" ||
			           $reftool == "ude_internal_tools_falcon" ) &&
			         [llength $available($reftool)] < 2 ) ) &&
			     [info exists refversion($reftool)] } {
			     	if { $reftool == "ude_internal_tools" ||
			             $reftool == "ude_internal_tools_falcon" } {
					set reftoolversion "unload and default"
				} else {
					set reftoolversion $refversion($reftool)
				}
				ruleErrorApplicable "(PCSQA-2.1k in01) $reftool has no version setting instead of '$reftoolversion' at creation date $creationdatepcs of PCS in ${parentprojectenvtxt}project.env"
			}
		}
	}
}
cd $run_dir

## Rule 2.1jk
proc modules_at_this_site { moduleerrors } {

	global siteid

	set moduleerrorstxt ""
	foreach moduleerror $moduleerrors {
		if { $moduleerror != "" } {
			set toolatsites $::env(MSIP_LYNX_PCSQA)/bin/tool_at_sites.ctr
			## Syntax: module[/version] <site1>,<site2>
			if { [file exists $toolatsites] } {
				catch { exec sh -c "grep $moduleerror $toolatsites | awk '{ print \$2 }'" } modules_at_sites				
				if { $modules_at_sites != "" } {
					if { [string first $siteid $modules_at_sites] != -1 } {
						## module is installed at this site, but module load issue
						set moduleerrorstxt "$moduleerrorstxt, '$moduleerror'"
					}
				} else {
					## try module without version in toolatsites
					set slashindex [string first "/" $moduleerror]
					if { $slashindex != -1 } {
						set moduleerrornover [string range $moduleerror 0 [expr $slashindex - 1]]
						catch { exec sh -c "grep $moduleerrornover $toolatsites | awk '{ print \$2 }'" } modules_at_sites
						if { $modules_at_sites != "" } {
							if { [string first $siteid $modules_at_sites] != -1 } {
								## module is installed at this site, but module load issue
								set moduleerrorstxt "$moduleerrorstxt, '$moduleerror'"
							}
						} else {
							## no control for module without version, so default module is installed at this site, but module load issue
							set moduleerrorstxt "$moduleerrorstxt, '$moduleerror'"							
						}
					} else {
						## no control for module, so default module is installed at this site, but module load issue
						set moduleerrorstxt "$moduleerrorstxt, '$moduleerror'"							
					}
				}
			} else {
				## no control file, so default module is installed at this site, but module load issue
				set moduleerrorstxt "$moduleerrorstxt, '$moduleerror'"
			}
		}
	}
	set moduleerrorstxt [string trimleft $moduleerrorstxt ","]
	set moduleerrorstxt [string trimleft $moduleerrorstxt]
	return $moduleerrorstxt
}

if { [file exists $run_dir/${uniqueprefix}moduleprojectenv] } {
	## LOADEDMODULES from ude env files
	set runscript_moduleprojectenv $run_dir/${uniqueprefix}moduleprojectenv
} else {
	## get modules from projectenv 
	set runscript_moduleprojectenv ${uniqueprefix}moduleprojectenv
	set fidsed [open ${uniqueprefix}sedscript w]
	puts $fidsed "s#unsetenv\\s*MSIP_\\(\[^_\]*\\)_VERSION#module unload \\L\\1#g"
	## convert first: setenv MSIP_<APP>_VERSION           -> setenv MSIP_<app>_VERSION
	## add before setenv 'module unload' to prevent 'conflicts with the currently loaded module(s)'(STAR 9000862020)
	puts $fidsed "s#setenv\\s*MSIP_\\(\[^_\]*\\)_VERSION#module unload \\L\\1\\nsetenv \\UMSIP_\\L\\1\\U_VERSION#g"
	## after that   : setenv MSIP_<app>_VERSION <version> -> module load <app>/<version>
	## preventing conversion of <version> to lower case
	## \\L is applicable for all buffers in sed !
	puts $fidsed "s#setenv\\s*MSIP_\\(\[^_\]*\\)_VERSION\\s*\\(\\S\\S*\\)#module load \\1/\\2#g"
	puts $fidsed "s#cd\\n#customdesigner\\n#g"
	puts $fidsed "s#cc\\n#customcompiler\\n#g"
	puts $fidsed "s#starrcxt\\n#star_rcxt\\n#g"  
	puts $fidsed "s#cd/#customdesigner/#g"
	puts $fidsed "s#cc/#customcompiler/#g"
	puts $fidsed "s#starrcxt/#star_rcxt/#g"  
	close $fidsed
	catch { exec $exec_cmd -c "grep -v ^\[\[:blank:\]\]*# $projectenv | sed -f ${uniqueprefix}sedscript | grep 'module\[\[:space:\]\]' > $runscript_moduleprojectenv && rm -f ${uniqueprefix}sedscript" } dummy
}
catch { exec $exec_cmd -c "source $::env(MODULESHOME)/init/bash 2> /dev/null && module purge 2> /dev/null && chmod u+x $runscript_moduleprojectenv && source $runscript_moduleprojectenv 2> ${uniqueprefix}moduleerrors" } dummy
catch { exec $exec_cmd -c "cat ${uniqueprefix}moduleerrors | grep -v -i license > ${uniqueprefix}moduleerrors2" } dummy
catch { exec $exec_cmd -c "/bin/mv -f ${uniqueprefix}moduleerrors2 ${uniqueprefix}moduleerrors" } dummy
incr checks
if { [file size ${uniqueprefix}moduleerrors] > 0 } {
	catch { exec $exec_cmd -c "cat ${uniqueprefix}moduleerrors | grep \"Unable to locate a modulefile for\" | awk '{print \$8}' | sed -e \"s/'//g\"" } moduleerrors
	set moduleerrors [split $moduleerrors "\n"]	
	set moduleerrorstxt [modules_at_this_site $moduleerrors]
	if { $moduleerrorstxt != "" } {
		## support of "ModuleCmd_Load.c(199):ERROR:105: Unable to locate a modulefile for '...'"
		ruleErrorApplicable "(PCSQA-2.1jk in01) The following tools version in project.env are not available in site $siteid: $moduleerrorstxt"
	}
	catch { exec $exec_cmd -c "cat ${uniqueprefix}moduleerrors | grep \"Cannot open file\" | awk '{print \$5}' | sed -e \"s/'//g\"" } moduleerrors
	set moduleerrors [split $moduleerrors "\n"]	
	set moduleerrorstxt [modules_at_this_site $moduleerrors]
	if { $moduleerrorstxt != "" } {
		## support of "utility.c(2340):ERROR:50: Cannot open file '...' for 'reading'" (STAR 9001192526)
		ruleErrorApplicable "(PCSQA-2.1jk in01) Tools in project.env can not be set in site $siteid due to omission of: $moduleerrorstxt"
	}
}  
}
}

if { $siteid != "in01" } {
incr checks
if { [file exists $p4root/ddr54/d820-ddr54v2-tsmc5ffp12/rel1.30a_mrvl_sup1/design/.cdesigner.tcl] } {
	ruleErrorApplicable "(PCSQA-2.1m) design/.cdesigner.tcl is present in p4"
	if { [ruleApplicable "2.1m"] } {
		incr p4errors
	}
}
incr checks
if { [file exists $p4root/ddr54/d820-ddr54v2-tsmc5ffp12/rel1.30a_mrvl_sup1/cad/.cdesigner.tcl] } {
	ruleErrorApplicable "(PCSQA-2.1m) cad/.cdesigner.tcl is present in p4"
	if { [ruleApplicable "2.1m"] } {
		incr p4errors
	}
}
}

if { $siteid == "in01" } {
if { [file exists $pcs/cad] } {
set cadroot "$::env(udecadrep)/proj/"

## Rule 2.1ff/2.1iii/2.1jjj
set automotivevalue ""
if { [file exists $projectenv] } {
	catch { exec $exec_cmd -c "cat $projectenv | grep -v -e ^\[\[:blank:\]\]*# -e unsetenv | grep setenv | grep automotive | head -1 | awk '{print \$3}' | sed -e 's/\"//g'" } automotivevalue
	if { $automotivevalue == "" } {
		if { $msip_parentchild_type == "CHILD_CAD_SETUP" ||
		     $msip_parentchild_type == "CHILD_ALL" } {
			catch { exec $exec_cmd -c "cat $projectenv | grep -v -e ^\[\[:blank:\]\]*# -e unsetenv | grep setenv | grep MSIP_PARENT_PCS_PRODUCT_NAME | head -1 | awk '{print \$3}' | sed -e 's/\"//g'" } msip_parent_pcs_product_name
			catch { exec $exec_cmd -c "cat $projectenv | grep -v -e ^\[\[:blank:\]\]*# -e unsetenv | grep setenv | grep MSIP_PARENT_PCS_PROJ_NAME    | head -1 | awk '{print \$3}' | sed -e 's/\"//g'" } msip_parent_pcs_proj_name
			catch { exec $exec_cmd -c "cat $projectenv | grep -v -e ^\[\[:blank:\]\]*# -e unsetenv | grep setenv | grep MSIP_PARENT_PCS_REL_NAME     | head -1 | awk '{print \$3}' | sed -e 's/\"//g'" } msip_parent_pcs_rel_name
			set parentpcs $ude3proj/$msip_parent_pcs_product_name/$msip_parent_pcs_proj_name/$msip_parent_pcs_rel_name
			set parentpcsprojectenv $parentpcs/cad/project.env
			if { [file exists $parentpcsprojectenv] } {
				catch { exec $exec_cmd -c "cat $parentpcsprojectenv | grep -v -e ^\[\[:blank:\]\]*# -e unsetenv | grep setenv | grep automotive | head -1 | awk '{print \$3}' | sed -e 's/\"//g'" } automotivevalue
			}
		}	
	}
}
set stackuppaths [glob -nocomplain $pcs/cad/*]
foreach stackuppath $stackuppaths {
	if { [file exists $stackuppath/env.tcl ] } {
		catch { exec $exec_cmd -c "basename $stackuppath" } stackup
		set rapostfixes [list "_RA.tcl" "_RAESD.tcl" "_RA_selfheating.tcl" "_totem.cfg" "_totem_automotive.cfg"]
		set emirrule("_RA.tcl") "ff"
		set emirrule("_RAESD.tcl") "ff"
		set emirrule("_RA_selfheating.tcl") "iii"
		set emirrule("_totem.cfg") "jjj"
		set emirrule("_totem_automotive.cfg") "ggg-c"
		foreach rapostfix $rapostfixes {
			if { [string first "automotive" $rapostfix] != -1 &&
			     $automotivevalue != "YES" } {
			     continue
			}
			incr checks
			set emirlink ""
			set normtarget ""
			set target $pcs/cad/emir/${stackup}${rapostfix}
			if { [file exists $target] } {
				if { [file type $target] == "link" } {
					set emirlink $target
					## ensure file normalize works by going to link directory
					catch { exec $exec_cmd -c "dirname $emirlink" } dirlink
					cd $dirlink
					set target [file readlink $emirlink]
				}
				## normtarget can point to a CCSCS !!
				set normtarget [file normalize $target]
			}
			set nounrapostfix [string trimleft $rapostfix "_"]
			set lcnounrapostfix [string tolower $nounrapostfix]
			if { [file exists $normtarget] == 0 } {
				set parenttarget ""
				if { $parentpcs != "" } {
					set parenttarget $parentpcs/cad/emir/${stackup}${rapostfix}
				} else {
					if { $refccs != "" } {
						set parenttarget $refccs/cad/${stackup}/emir/${nounrapostfix}
						if { [file exists $parenttarget] == 0 } {
							set parenttarget $refccs/cad/${stackup}/emir/${lcnounrapostfix}
						}
					}
				}
				if { [file exists $parenttarget] } {			
					ruleErrorApplicable "(PCSQA-2.1$emirrule("$rapostfix") in01) cad/emir/${stackup}${rapostfix} does not exist"
				}
			} else {
				if { $emirlink != "" } {
					if { $parentpcs != "" } {
						## STAR 9001416584					
						incr checks
						if { [string compare "$parentpcs/cad/emir/${stackup}${rapostfix}" $normtarget] != 0 } {
							ruleErrorApplicable "(PCSQA-2.1$emirrule("$rapostfix") in01) Link cad/emir/${stackup}${rapostfix} does not point to correct target: $target"
						}
					} else {
						if { $refccs != "" } {
							incr checks
							set refendtarget1 "cad/${stackup}/emir/${nounrapostfix}"
							set refendtarget2 "cad/${stackup}/emir/${lcnounrapostfix}"
							## normtarget has to begin with cadroot and end with refendtarget1 or 2
							if { [string compare -length [string length $cadroot] $cadroot $normtarget] != 0 ||
							     ( [string range $normtarget [expr [string length $normtarget] - [string length $refendtarget1]] [expr [string length $normtarget] - 1]] != $refendtarget1 &&
							       [string range $normtarget [expr [string length $normtarget] - [string length $refendtarget2]] [expr [string length $normtarget] - 1]] != $refendtarget2 ) } {
								## normtarget does not point to cadroot
								ruleErrorApplicable "(PCSQA-2.1$emirrule("$rapostfix") in01) Link cad/emir/${stackup}${rapostfix} does not point to correct target: $target"
							}
							## if normtarget point to cadroot
							## rule 2.1n will check if cad/emir/${stackup}${rapostfix} points to reference CCS
						}
					}
				}
			}
		}
		## loop rapostfixes
	}
}
## loop stackuppaths

## Rule 2.1aaa
if { $refccs != "" } {
	set sheinfoexists 1
	set stackuppaths [glob -nocomplain $refccs/cad/*]
	foreach stackuppath $stackuppaths {
		if { [file exists $stackuppath/env.tcl] } {
			catch { exec $exec_cmd -c "basename $stackuppath" } stackup
			if { [file exists $refccs/cad/$stackup/emir/RA.she.tcl] &&
			     [file isdirectory $pcs/cad/$stackup] &&
			     [file exists $pcs/cad/emir/she.info] == 0 } {
			     set sheinfoexists 0
			     break
			}
		}
	}
	if { $sheinfoexists == 0 } {
		ruleErrorApplicable "(PCSQA-2.1aaa in01) she.info file $pcs/cad/emir/she.info omits"
	}
}

proc check_reference_to_correct_parentcs { src target normtarget parentcs normparentcs referencetype } {

		global checks
		global cadroot
		global ude3proj
		global refccs
		global parentpcs
		
		incr checks
		## do not accept at this point a CCS with postfix: character after refccs in target has to be '/'
		if { ( ( $parentcs == $refccs    && [string compare -length [string length $cadroot]  $cadroot  $normtarget] == 0 ) ||
		       ( $parentcs == $parentpcs && [string compare -length [string length $ude3proj] $ude3proj $normtarget] == 0 ) ) &&
		     ( [string compare -length [string length $normparentcs] $normparentcs $normtarget]   != 0 ||
		       ( [string compare -length [string length $normparentcs] $normparentcs $normtarget] == 0 &&
		         [string index $normtarget [string length $normparentcs]] != "/" ) ) &&
		     ( [string compare -length [string length $normparentcs] $normparentcs $target]     != 0 ||
		       ( [string compare -length [string length $normparentcs] $normparentcs $target]   == 0 &&
		         [string index $target [string length $normparentcs]] != "/" ) ) &&
		     ( [string compare -length [string length $parentcs]     $parentcs     $normtarget] != 0 ||
		       ( [string compare -length [string length $parentcs]   $parentcs     $normtarget] == 0 &&
		         [string index $normtarget [string length $parentcs]] != "/" ) ) &&
		     ( [string compare -length [string length $parentcs]     $parentcs     $target]     != 0 ||
		       ( [string compare -length [string length $parentcs]   $parentcs     $target]     == 0 &&
		         [string index  $target [string length $parentcs]] != "/" ) ) } {
			if { $parentcs == $refccs } { 
				## Support of following case:
				## refccs: 	/remote/proj/cad/<CCS>
				## normrefccs: 	$cadroot<CCS>
				## target: 	$ude3proj/cad/<CCS>/cad/...
				## normtarget: 	$cadroot<CCSCS-<node>>/relx.y/cad/...
				set normrefccs [file normalize $refccs]
				set ccsnameversion [string range $normrefccs [string length $cadroot] [expr [string length $normrefccs] - 1]]
				set reftarget      $ude3proj/cad/$ccsnameversion
				## enforce within target mapping to $ude3proj of reftarget
				set orgtarget $target
				catch { exec $exec_cmd -c "echo $orgtarget | sed -e 's#/remote/cad\-rep/proj/#$ude3proj/cad/#' -e 's#/remote/proj/#$ude3proj/#g'" } target				
		     		if { [string compare -length [string length $reftarget] $reftarget $target]     != 0 ||
		                     ( [string compare -length [string length $reftarget] $reftarget $target]   == 0 &&
		                       [string index $target [string length $reftarget]] != "/" ) } {
				       	switch $referencetype {
				       		"link" {
							ruleErrorApplicable "(PCSQA-2.1n in01) Link does not point to reference CCS: $src -> $orgtarget"
						}
				       		"source" -
						"include" {
							ruleErrorApplicable "(PCSQA-2.1uu2 in01) $src does not $referencetype reference CCS: $orgtarget"
						}
					}
				}
			} else {
				ruleErrorApplicable "(PCSQA-2.1.1i in01) Link does not point to Parent PCS: $src -> $target"
			}
		}
}

catch { exec $exec_cmd -c "find $pcs/cad/* -type l" } links
set links [split $links \n]
foreach link $links {
	## ensure file normalize works by going to link directory
	catch { exec $exec_cmd -c "dirname $link" } dirlink
	if { [string first "No such file" $dirlink] != -1 } {
		continue
	}
	cd $dirlink
	set target [file readlink $link]
	## normtarget can point to a CCSCS !!
	set normtarget [file normalize $target]
	## P10020416-32291
	set doubledot [string first "/../" $target]
	if { $doubledot != -1 } {
		set linktarget [string range $target 0 [expr $doubledot - 1]]
		if { [file type $linktarget] == "link" } {
			## bug in tcl 8.4
			set normtarget [file normalize $linktarget]
		}
	}
	incr checks
	if { [file exists $normtarget] } {
		if { ( ( $msip_parentchild_type == "" || ( $msip_parentchild_type != "CHILD_CAD_SETUP" && $msip_parentchild_type != "CHILD_ALL" ) ) && $refccs != "" ) ||
		     ( ( $msip_parentchild_type == "CHILD_CAD_SETUP" || $msip_parentchild_type == "CHILD_ALL" ) && $parentpcs != "" ) } {
			set parentcs     $refccs
			set normparentcs [file normalize $refccs]
			if { $msip_parentchild_type == "CHILD_CAD_SETUP" || $msip_parentchild_type == "CHILD_ALL" } {
				## since 16.1:
				## 2.1.1i)	A PCS where $MSIP_PARENTCHILD_TYPE=CHILD_CAD_SETUP or CHILD_ALL 
				##              must link the following parent PCS folder CONTENTS if they exist:
				##              models, emir and plugins

				## one level up in link
				set linkdir [file tail $dirlink]
				if { $linkdir == "models" || $linkdir == "emir" || $linkdir == "plugins" } {
					set parentcs     $parentpcs
					set normparentcs [file normalize $parentpcs]
				}
			}
			
			check_reference_to_correct_parentcs $link $target $normtarget $parentcs $normparentcs "link" 
		}
	} else {
		ruleErrorApplicable "(PCSQA-1.3 in01) Broken link found at $link -> $target"		
	}
}

proc check_references_to_refccs_of_type { referencetype } {

	global refccs
	global pcs
	global macroreplace
	global ccsreplace
	global ude3proj

	set normrefccs [file normalize $refccs]
	catch { exec sh -c "find $pcs/cad/* -type f" } cadfiles
	set cadfiles [split $cadfiles \n]
	foreach cadfile $cadfiles {
		catch { exec sh -c "grep -i \"^\[\[:blank:\]\]*$referencetype\[\[:blank:\]\]\" $cadfile | grep -v ^\[\[:blank:\]\]*# | wc -l" } references
		if { $references > 0 } {
			catch { exec sh -c "grep -i \"^\[\[:blank:\]\]*$referencetype\[\[:blank:\]\]\" $cadfile | grep -v ^\[\[:blank:\]\]*# | awk '{ print \$2 }' | $macroreplace $ccsreplace" } references
			set references [split $references \n]
			foreach reference $references {
				set normreference [file normalize $reference]
				if { [string match {^$ude3proj/cad/c[0-9][0-9][0-9]\-.+$} $normreference] } {
					## normreference refers to a CCS
					## check to refccs
					check_reference_to_correct_parentcs $cadfile $reference $normreference $refccs $normrefccs "$referencetype"
				}				
			}
		}
	}
}

if { $refccs != "" } {
	check_references_to_refccs_of_type "source"
	check_references_to_refccs_of_type "include"
}

}

if { $msip_parentchild_type == "PARENT" } {
	set ref_parent_proj_home  "\${MSIP_PROJ_ROOT}/\${MSIP_PARENT_PCS_PRODUCT_NAME}/\${MSIP_PARENT_PCS_PROJ_NAME}/\${MSIP_PARENT_PCS_REL_NAME}"
	set ref2_parent_proj_home [string map { \{ "" \} "" } $ref_parent_proj_home]
	if { [file exists $projectenv] } {
		catch { exec $exec_cmd -c "cat $projectenv | grep -v -e ^\[\[:blank:\]\]*# -e unsetenv | grep setenv | grep PARENT_PROJ_HOME | head -1 | awk '{print \$3}' | sed -e 's/\"//g'" } parent_proj_home
		incr checks
		if { $parent_proj_home != "" } {
			incr checks
			if { $parent_proj_home != $ref_parent_proj_home && $parent_proj_home != $ref2_parent_proj_home } {
				ruleErrorApplicable "(PCSQA-2.1.1l in01) Wrong value of setenv of PARENT_PROJ_HOME in project.env: setenv PARENT_PROJ_HOME $parent_proj_home"
			}
		} else {
			ruleErrorApplicable "(PCSQA-2.1.1l in01) No setenv of PARENT_PROJ_HOME in project.env: setenv PARENT_PROJ_HOME $ref_parent_proj_home"
		}
	}
	
	catch { exec $exec_cmd -c "find $pcs/cad/* -type f | grep -e '\.tcl\$' -e '\.lib\.defs\$' -e '\.env\$'"} pcsfiles
	set pcsmacros [list "MSIP_PRODUCT_NAME" "MSIP_PROJ_NAME" "MSIP_REL_NAME" "PROJ_HOME"]
	foreach pcsmacro $pcsmacros {
		set pcsmacrocounter [string map {MSIP MSIP_PARENT_PCS PROJ_HOME PARENT_PROJ_HOME} $pcsmacro]
		foreach pcsfile $pcsfiles {
			incr checks
			catch { exec $exec_cmd -c "grep $pcsmacro $pcsfile | grep -v -e ^\[\[:blank:\]\]*# -e RUN_DIR_ROOT -e CAD_PROJ_HOME -e $pcsmacrocounter | wc -l"} macropresent
			if { $macropresent > 0 } {
				ruleErrorApplicable "(PCSQA-2.1.1b in01) Use $pcsmacrocounter instead of $pcsmacro in $pcsfile"
			}
		}
	}
}

## since 16.1:
## 2.1.1i)	A PCS where $MSIP_PARENTCHILD_TYPE=CHILD_CAD_SETUP or CHILD_ALL 
##              must link the following parent PCS folder CONTENTS if they exist:
##              models, emir and plugins

## No check on models, emir and plugins folders anymore
## Check on rule 2.1.1i shares the code with rule 2.1n
## if { ( $msip_parentchild_type == "CHILD_CAD_SETUP" || $msip_parentchild_type == "CHILD_ALL" ) && $parentpcs != "" } {
## 	catch { exec $exec_cmd -c "find $pcs/cad/* -type f | grep -e \"/models/\" -e \"/emir/\" -e \"/plugins/\" "} linkdirfiles
## 	set linkdirfiles [split $linkdirfiles \n]
## 	set linkdirlist [list]
## 	foreach linkdirfile $linkdirfiles {
## 		set linkdir 	[file dirname $linkdirfile]
## 		set linkdirname [file tail    $linkdir]
## 		while { $linkdir != "." && $linkdirname != "models" && $linkdirname != "emir" && $linkdirname != "plugins" } {
## 			set linkdir 	[file dirname $linkdir]
## 			set linkdirname [file tail    $linkdir]
## 		}
## 		if { $linkdir != "." } {
## 			lappend linkdirlist $linkdir
## 		}
## 	}
## 	if { [llength $linkdirlist] > 0 } {
## 		set linkdirlist [lsort -unique $linkdirlist]
## 		foreach linkdir $linkdirlist {
## 			incr checks
## 			ruleErrorApplicable "(PCSQA-2.1.1i in01) Folder does not point to Parent PCS: $linkdir"
## 		}
## 	}
## }

incr checks
set pcstcl $pcs/cad/pcs.tcl
if { [file exists $pcstcl] && [file size $pcstcl] > 0 } {
	ruleWarningApplicable "(PCSQA-2.2c in01) cad/pcs.tcl exists in PCS and is not empty"
}

if { $msip_parentchild_type == "CHILD_CAD_SETUP" && $parentpcs != "" } {
	incr checks
	set parentpcstcl $parentpcs/cad/pcs.tcl
	if { [file exists $pcstcl] } {
		if { [file exists $parentpcstcl] } {
			catch { exec $exec_cmd -c "cat $pcstcl | grep -v ^\[\[:blank:\]\]*# | grep source | grep MSIP_PARENT_PCS_ | wc -l" } usedparentpcstcl
			if { $usedparentpcstcl > 0 } {
				catch { exec $exec_cmd -c "cat $pcstcl | grep -v ^\[\[:blank:\]\]*# | grep source | grep MSIP_PARENT_PCS_ | awk '{print \$2}' | $macroreplace $parentpcsreplace" } usedparentpcstcl
				if { $usedparentpcstcl != $parentpcstcl } {
					ruleErrorApplicable "(PCSQA-2.1.1h in01) No source of Parent PCS pcs.tcl in cad/pcs.tcl in PCS: source $usedparentpcstcl"
				}
			} else {
				ruleErrorApplicable "(PCSQA-2.1.1h in01) No source of Parent PCS pcs.tcl in cad/pcs.tcl in PCS by: source \$env(MSIP_PROJ_ROOT)/\$env(MSIP_PARENT_PCS_PRODUCT_NAME)/\$env(MSIP_PARENT_PCS_PROJ_NAME)/\$env(MSIP_PARENT_PCS_REL_NAME)/cad/pcs.tcl"
			}
		}
	} else {
		if { [file exists $parentpcstcl] } {
			ruleErrorApplicable "(PCSQA-2.1.1h in01) No cad/pcs.tcl exists in PCS to source Parent PCS pcs.tcl"
		}
	}
}

if { ( $msip_parentchild_type == "CHILD_RnD_LIBS" || $msip_parentchild_type == "CHILD_ALL" ) && $parentpcs != "" } {
	set designlibdefs $pcs/design/lib.defs
	if { [file exists $designlibdefs] } {
		## MSIP_PROJ_P4WS_ROOT or PROJ_P4_ROOT since spec 16.1
		## /projects/ since 19.1
		set parentpcsp4v1 MSIP_PROJ_P4WS_ROOT/projects/$msip_parent_pcs_product_name/$msip_parent_pcs_proj_name/$msip_parent_pcs_rel_name
		set parentpcsp4v2 PROJ_P4_ROOT/projects/$msip_parent_pcs_product_name/$msip_parent_pcs_proj_name/$msip_parent_pcs_rel_name
		incr checks
	       	catch { exec $exec_cmd -c "cat $designlibdefs | grep -v ^\[\[:blank:\]\]*# | grep INCLUDE | grep MSIP_PARENT_PCS_ | wc -l" } usedparentdesignlibdefs
	       	if { $usedparentdesignlibdefs > 0 } {
	               catch { exec $exec_cmd -c "cat $designlibdefs | grep -v ^\[\[:blank:\]\]*# | grep INCLUDE | grep MSIP_PARENT_PCS_ | awk '{print \$2}' | $macroreplace $parentpcsreplace" } usedparentdesignlibdefs
	               if { "$usedparentdesignlibdefs" != "$parentpcsp4v1/pcs/design/lib.defs"                  && "$usedparentdesignlibdefs" != "$parentpcsp4v2/pcs/design/lib.defs" &&
		            "$usedparentdesignlibdefs" != "$parentpcsp4v1/pcs/design/MSIP_METAL_STACK/lib.defs" && "$usedparentdesignlibdefs" != "$parentpcsp4v2/pcs/design/MSIP_METAL_STACK/lib.defs" } {
	        	       ruleErrorApplicable "(PCSQA-2.1.1j in01) No INCLUDE of Parent PCS design/lib.defs in design/lib.defs in PCS: INCLUDE $usedparentdesignlibdefs"
	               }
	       	} else {
	               ruleErrorApplicable "(PCSQA-2.1.1j in01) No INCLUDE of Parent PCS design/lib.defs in design/lib.defs in PCS by: INCLUDE \${MSIP_PROJ_P4WS_ROOT|PROJ_P4_ROOT}/projects/\${MSIP_PARENT_PCS_PRODUCT_NAME}/\${MSIP_PARENT_PCS_PROJ_NAME}/\${MSIP_PARENT_PCS_REL_NAME}/design/\[\${MSIP_METAL_STACK}/\]lib.defs"
	       	}
	}
}

incr checks
set pcsinprogress 1
if { $pcsinprogress == 0 } {
	catch { exec $exec_cmd -c "grep \"/ddr54/d820-ddr54v2-tsmc5ffp12/rel1.30a_mrvl_sup1/\" $::env(udecadrep)/projects/perforce_global_pcs_template | wc -l" } pcslines
	if { $pcslines > 0 } {	
		ruleErrorApplicable "(PCSQA-2.1r in01) PCS is not 'In progress' in VC, but available in $::env(udecadrep)/projects/perforce_global_pcs_template"
	}
}

set enable21q 0
if { $enable21q == 1 && 
     [ruleApplicable "2.1q"] &&
     [ruleApplicable "2.1y"] } {

set pcspath $pcs/cad
set stackuppaths [glob -nocomplain $pcspath/*/env.tcl]
if { [llength $stackuppaths] == 0 } {
	puts "SNPS_ERROR  : No metal stack options found at $pcspath"
} else {

set stackuppaths [glob -nocomplain $pcspath/*]
foreach stackuppath $stackuppaths {
	if [file exists $stackuppath/env.tcl ] {
		catch { exec $exec_cmd -c "basename $stackuppath" } stackup

		set ude_run_dir $run_dir/${uniqueprefix}udework
		file delete -force $ude_run_dir
		file mkdir $ude_run_dir
		cd $ude_run_dir

		set fid_sourceude [open sourceude w]
		puts $fid_sourceude "setenv MSIP_PROJ_ROOT $::env(PCSQA_PROJ_ROOT)"
		puts $fid_sourceude "setenv MSIP_PRODUCT_NAME ddr54"
		puts $fid_sourceude "setenv UDE_HOME $ude_run_dir"
		puts $fid_sourceude "setenv PROJ_HOME $pcs"
		close $fid_sourceude

		set fid_checkmetalstack [open checkmetalstack.tcl w]
		puts $fid_checkmetalstack "set fid \[open $ude_run_dir/result w\]"
		incr checks
		puts $fid_checkmetalstack "if { \[info exists ::env(CAD_METAL_STACK)\] && \[info exists ::env(METAL_STACK)\] && \$::env(CAD_METAL_STACK) != \$::env(METAL_STACK) } {"
		puts $fid_checkmetalstack "	puts \$fid \"SNPS_ERROR  : (PCSQA-2.1q in01) environment variables CAD_METAL_STACK and METAL_STACK have not the same contents, CAD_METAL_STACK=\$::env(CAD_METAL_STACK) and METAL_STACK=\$::env(METAL_STACK)\""
		puts $fid_checkmetalstack "}"
		incr checks
		puts $fid_checkmetalstack "set lppliblibs \[dm::getLibs lpplib\]"
		puts $fid_checkmetalstack "if { \[db::getNext \$lppliblibs\] == \"\" } {"
		puts $fid_checkmetalstack "	set lppliblibs \[dm::getLibs lpplib2\]"
		puts $fid_checkmetalstack "	if { \[db::getNext \$lppliblibs\] == \"\" } {"
		puts $fid_checkmetalstack "		set lppliblibs \[dm::getLibs lpplib3\]"
		puts $fid_checkmetalstack "		if { \[db::getNext \$lppliblibs\] == \"\" } {"
		puts $fid_checkmetalstack "			puts \$fid \"SNPS_ERROR  : (PCSQA-2.1y in01) Libraries lpplib and lpplib2 and lpplib3 not found for metal stack $stackup\""
		puts $fid_checkmetalstack "		}"
		puts $fid_checkmetalstack "	}"	
		puts $fid_checkmetalstack "}" 
		puts $fid_checkmetalstack "set libraries \[list \"devices\" \"devices_fab\" \"techlib\" \"basic\" \"basicAddon\" \"analogLib\" \"analogLibAddon\" \"sheets\" \"widgets\"\]"
		puts $fid_checkmetalstack "foreach lib \$libraries {" 
		puts $fid_checkmetalstack "	set libs \[dm::getLibs \$lib\]"
		puts $fid_checkmetalstack "	if { \[db::getNext \$libs\] == \"\" } {"
		puts $fid_checkmetalstack "		puts \$fid \"SNPS_ERROR  : (PCSQA-2.1y in01) Library \$lib not found for metal stack $stackup\""
		puts $fid_checkmetalstack "	}"
		puts $fid_checkmetalstack "}" 
		puts $fid_checkmetalstack "close \$fid" 
		puts $fid_checkmetalstack "exit -force 1"
		close $fid_checkmetalstack

		catch { exec csh -c "source $::env(MODULESHOME)/init/csh && source $::env(udecadrep)/etc/.cshrc && module purge && module load no_module_env && module load ude-wrapper && setenv MSIP_PROJ_ROOT $::env(PCSQA_PROJ_ROOT) && setenv UDE_HOME $ude_run_dir && cd $ude_run_dir && ude3 --projectType ddr54 --projectName d820-ddr54v2-tsmc5ffp12 --releaseName rel1.30a_mrvl_sup1 --metalStack $stackup --nogui --sourceShellFile $ude_run_dir/sourceude --command \"source $ude_run_dir/checkmetalstack.tcl\" > udelog" } dummy
		if { [file size result] > 0 } {
			catch { exec $exec_cmd -c "cat result" } errormessage
			puts "$errormessage"
		}

		cd $run_dir
		file delete -force $ude_run_dir
	}
}

}

}

}
## $siteid == "in01"

if { $siteid != "in01" } {
	set pcsstatus $p4root/ddr54/d820-ddr54v2-tsmc5ffp12/rel1.30a_mrvl_sup1/cad/.PCSQA_STATUS
	incr checks
	if { [file exists $pcsstatus] == 0 } {
		ruleErrorApplicable "(PCSQA-2.1t) No cad/.PCSQA_STATUS file available in p4"
		if { [ruleApplicable "2.1t"] } {
			incr p4errors
		}
	}
}

proc dec2bin i {
    ## 0 <= i <= 7
    ## returns a string with 3 digits, e.g. dec2bin 3 => 011 
    set res {} 
    while {$i>0} {
        set res [expr {$i%2}]$res
        set i [expr {$i/2}]
    }
    if {$res == {}} {set res "000"}
    while { [string length $res] < 3 } {
    	set res "0$res"
    }
    return $res
}


proc oct2bin o {
    ## 000 <= i <= 777
    ## returns a string with 9 digits, e.g. oct2bin 750 => 111101000 
    set res ""
    set i 0
    while { $i < [string length $o] } {
    	set bin [dec2bin [string index $o $i]]
	set res "$res$bin"
	incr i 
    } 
    while { [string length $res] < 9 } {
    	set res "0$res"
    }
    return $res
}

set waiveenvvarsfiles [list \
    "*_options*" \
    "*/emir/*.tcl" \
    "*/emir/*.inc" \
    "*/lvs*.include.cdl" \
    "*/lvs*.include.*.cdl" \
    "*/lvs*.include" \
    "*/lvs*.include.*" \
    "*calibre*.cal" \
    "*icv*.rs" \
    "*/perc_*.top" \
    "*/esp/*.sp" \
    "*/esp/*.edm" \
    "*/readme" \
    "*/*.txt" \
    "*/*.tmpl" \
    "*/starrc*template" \
]

proc iswaiveenvvarsfile pcsfile {

    global waiveenvvarsfiles

    set res 0     
    foreach  waiveenvvarsfile $waiveenvvarsfiles {
    	if { [string match $waiveenvvarsfile $pcsfile] } {
    		set res 1
		break		
	}
    }
    return $res    
}

set waivereferencesfiles [list \
    "*/readme" \
    "*/README" \
    "*/*.txt" \
    "*/*.tmpl" \
    "*/*.version" \
    "*/*.log" \
    "*/*.config" \
]

proc iswaivereferencesfile pcsfile {

    global waivereferencesfiles

    set res 0     
    foreach  waivereferencesfile $waivereferencesfiles {
    	if { [string match $waivereferencesfile $pcsfile] } {
    		set res 1
		break		
	}
    }
    return $res    
}

if { $siteid == "in01" } {
	set pcscad $::env(PCSQA_PROJ_ROOT)/ddr54/d820-ddr54v2-tsmc5ffp12/rel1.30a_mrvl_sup1/cad
	set pcsqastatusfile ".PCSQA_STATUS"
	if { [info exists ::env(MSIP_LYNX_PCSQA)] &&
     	     [string first "beta" [file tail $::env(MSIP_LYNX_PCSQA)]] != -1 } {
		set pcsqastatusfile ".PCSQA_STATUS_beta"
		set pcsstatus $pcscad/$pcsqastatusfile
		if { [file exists $pcsstatus] == 0 } {
			set pcsstatus $p4root/ddr54/d820-ddr54v2-tsmc5ffp12/rel1.30a_mrvl_sup1/cad/$pcsqastatusfile
			if { [file exists $pcsstatus] == 0 } {
				set pcsqastatusfile ".PCSQA_STATUS"
			}
		}
	}
	set pcsstatus $pcscad/$pcsqastatusfile
	if { [file exists $pcsstatus] == 0 } {
		set pcsstatus $p4root/ddr54/d820-ddr54v2-tsmc5ffp12/rel1.30a_mrvl_sup1/cad/$pcsqastatusfile
	}
	if { [file exists $pcsstatus] && [file isdirectory $pcscad] } {
		cd $pcscad
		catch { exec $exec_cmd -c "find . -type f -not -name '.PCSQA_STATUS' -not -name '.PCSQA_STATUS_beta' -not -name '.whoami' -exec md5sum {} \\; | awk '{print \$2\" \"\$1}' | sed -e 's#\\./##g' > $run_dir/${uniqueprefix}chksum" } dummy
		catch { exec $exec_cmd -c "find . -type l -exec md5sum {} \\; | awk '{print \$2\" \"\$1}' | sed -e 's#\\./##g' >> $run_dir/${uniqueprefix}chksum" } dummy
		catch { exec $exec_cmd -c "cat $run_dir/${uniqueprefix}chksum | sed -e 's#;# #g' | awk '{print \$2}' | sort | md5sum | awk '{print \$1}'" } chksum
		catch { exec $exec_cmd -c "grep \"^PCSQA CHKSUM\" $pcsstatus | sed -e 's#:# #g' -e 's#;# #g' | awk '{print \$3}'" } refchksum
		incr checks
		if { $chksum != $refchksum } {
		ruleErrorApplicable "(PCSQA-2.1t in01) Combined chksum of PCS files (excluding $pcsqastatusfile) (=$chksum) is not the same as the one inside $pcsqastatusfile file, PCSQA CHKSUM entry (=$refchksum)"
		set fp [open $run_dir/${uniqueprefix}chksum r]
		set file_data [read $fp]
		close $fp
		set fileschksum [split $file_data "\n"]
		foreach filechksum $fileschksum {
			catch { exec $exec_cmd -c "echo \"$filechksum\" | awk '{print \$1}'" } file
			if { $file != "" } {
			catch { exec $exec_cmd -c "grep \"^$file;\" $pcsstatus | wc -l" } fileavailable
			if { $fileavailable > 0 } {
				catch { exec $exec_cmd -c "echo \"$filechksum\" | awk '{print \$2}'" } actchksum
				catch { exec $exec_cmd -c "grep \"^$file;\" $pcsstatus | sed -e 's/;/ /g' | awk '{print \$2}'" } refchksum
				if { $actchksum != $refchksum } {
					ruleErrorApplicable "(PCSQA-2.1t in01) Chksum of file path $file (=$actchksum) is not the same as the one inside cad/$pcsqastatusfile file (=$refchksum)"
					if { [file type $file] == "link" } {
						ruleWarningApplicable "(PCSQA-2.1t in01) $file is a link, the chksum difference is outside of the PCS and please check if the change is valid"
					}
				}
			} else {
				ruleErrorApplicable "(PCSQA-2.1t in01) No chksum entry in cad/$pcsqastatusfile for file path $file"
			}
			}			
		}
		}
		catch { exec $exec_cmd -c "rm -f $run_dir/${uniqueprefix}chksum" } dummy

		catch { exec $exec_cmd -c "cat $pcsstatus | grep -v PCSQA | sed -e 's/;/ /g' | awk '{ print \$1 }'" } pcsstatuscadfiles
		set pcsstatuscadfiles [split $pcsstatuscadfiles "\n"]
		foreach pcsstatuscadfile $pcsstatuscadfiles {
			if { $pcsstatuscadfile != "" &&
			     [file exists $pcscad/$pcsstatuscadfile] == 0 } {
				ruleErrorApplicable "(PCSQA-2.1t in01) Chksum entry in cad/$pcsqastatusfile does not exists as file path cad/$pcsstatuscadfile"
			}
		}

		cd $run_dir
	}

	if { [file exists $pcs/cad] } {	
		catch { exec $exec_cmd -c "find $pcs/cad/* -type f | grep -v -e \".PCSQA_STATUS\" -e \".PCSQA_STATUS_beta\"" } pcsfiles
		set pcstriple "ddr54/d820-ddr54v2-tsmc5ffp12/rel1.30a_mrvl_sup1"
		set parentpcstriple "$msip_parent_pcs_product_name/$msip_parent_pcs_proj_name/$msip_parent_pcs_rel_name"
		set ccstriple "cad/$msip_cad_proj_name/$msip_cad_rel_name"
		set helicvar "\[\[:blank:\]\]HELIC_PDK_ROOT\[\[:blank:\]\]*"
		## if $MSIP_PROJ_ROOT/f130_helic is used, MSIP_PROJ_ROOT is replaced by $ude3proj
		## successor: /remote/cad-rep/fab/<fab_code>/<node>/logic/<flavor>/rules/helic
		set helicpathslist [list \
		                    "/remote/proj/f130_helic" \
				    "$ude3proj/f130_helic" \
				    "MSIP_PROJ_ROOT/f130_helic" \
				    "/remote/cad-rep/fab/.*/.*/logic/.*/rules/helic" \
				   ]
		set varhelicpaths ""
		set helicpaths ""
		foreach hp $helicpathslist {
			set varhelicpaths "$varhelicpaths -e \"$helicvar$hp\""
			set helicpaths "$helicpaths -e \"$hp\""
		}
		set projvarslist [list "/remote/proj" "/remote/cad-rep/projects" "MSIP_PROJ_ROOT"]
		set ignoreprojvars "grep -v"
		foreach projvar $projvarslist {
			set ignoreprojvars "$ignoreprojvars -e $projvar"
		}
		set ignoreprojvars "$ignoreprojvars -e /remote/cad-rep/fab -e /remote/cad-rep/msip/cd -e /remote/cad-rep/msip/ude_conf -e /remote/cad-rep/nvm/diData $varhelicpaths -e \[\[:blank:\]\]udescratch\[\[:blank:\]\] -e \[\[:blank:\]\]udescratch="
		set removeenvchars   "sed -e 's#\\\$env##g' -e 's#\[(\]##g' -e 's#\[)\]##g' -e 's#\\\$##g' -e 's#\{##g' -e 's#\}##g'"
		set replacepcsmacros "sed -e 's#MSIP_PRODUCT_NAME#ddr54#g' -e 's#MSIP_PROJ_NAME#d820-ddr54v2-tsmc5ffp12#g' -e 's#MSIP_REL_NAME#rel1.30a_mrvl_sup1#g'"
		set replaceccsmacros "sed -e 's#MSIP_CAD_REL_NAME#$msip_cad_rel_name#g' -e 's#MSIP_CAD_PROJ_NAME#$msip_cad_proj_name#g'"
		set refccstxt ""
		if { $refccs != "" } {
			set refccstxt " or other than reference CCS"
		}
		foreach pcsfile $pcsfiles {
		    if { [file exists $pcsfile] } {

			## P10020416-20893		    
		    	set removecommentline ""
		    	set pcsfileext [file extension $pcsfile]
			set commentchar ""
			switch $pcsfileext {
				".inc" {
					set commentchar "*"
				}
				".sp" {
					set commentchar "*"
				}
				".cdl" {
					set commentchar "*"
				}
				".tcl" {
					set commentchar "#"
				}
				default {
					set commentchar ""
				}				
			}
			if { $commentchar == "" } {
		    		set pcsfilename [file tail $pcsfile]
				switch $pcsfilename {
					"lvs.include" {
						set commentchar "*"
					}				
					"lib.defs" {
						set commentchar "#"
					}				
					"project.env" {
						set commentchar "#"
					}				
					default {
						set commentchar ""
					}				
				}
			}
			if { $commentchar != "" } {
				set removecommentline "| grep -v ^\[\[:blank:\]\]*\\$commentchar"
			}
			
			foreach projvar $projvarslist {
				if { ( $msip_parentchild_type == "" ||
				       ( $msip_parentchild_type != "CHILD_CAD_SETUP" && 
				         $msip_parentchild_type != "CHILD_ALL" ) ) } { 	     
					set acceptprojvarparentpcstriple ""
				} else {
					set acceptprojvarparentpcstriple "-e \"$projvar/$parentpcstriple\""
				}
				set bberror 0
				catch { exec $exec_cmd -c "grep \"$projvar\" $pcsfile $removecommentline | $removeenvchars | grep \"$projvar/$pcstriple\" | grep -v \"^\[\[:blank:\]\]*#\" | wc -l" } bbitemavail
				incr checks
				if { $bbitemavail > 0 && [iswaiveenvvarsfile $pcsfile] == 0 } {
					set projvartxt $projvar
					if { $projvar == "MSIP_PROJ_ROOT" } {
						set projvartxt "\$MSIP_PROJ_ROOT"
					}
					ruleErrorApplicable "(PCSQA-2.1bb in01) Reference $projvartxt/$pcstriple in file $pcsfile, use \$PROJ_HOME" 	
				}

				catch { exec $exec_cmd -c "grep \"$projvar\" $pcsfile \
				                                $removecommentline | \
								$removeenvchars | \
								$replacepcsmacros $parentpcsreplace | \
								$replaceccsmacros | \
								grep -v -e \"^\[\[:blank:\]\]*#\" \
								-e \"$projvar/$pcstriple\" \
								$acceptprojvarparentpcstriple \
								-e \"$projvar/$ccstriple\" \
								$varhelicpaths | wc -l" } projvaravail
				incr checks
				if { $projvaravail > 0 } {
					catch { exec $exec_cmd -c "grep \"$projvar\" $pcsfile \
				                                        $removecommentline | \
									$removeenvchars | \
									$replacepcsmacros $parentpcsreplace | \
									$replaceccsmacros | \
									grep -v -e \"^\[\[:blank:\]\]*#\" \
									-e \"$projvar/$pcstriple\" \
									$acceptprojvarparentpcstriple \
									-e \"$projvar/$ccstriple\" \
									$varhelicpaths " } projvarrefs
					set projvarrefs [split $projvarrefs "\n"]
					foreach projvarref $projvarrefs {
						ruleErrorApplicable "(PCSQA-2.1bb in01) Reference '$projvarref' in file $pcsfile refers to different PCS$refccstxt"
					} 	
					set bberror 1
				}
				if { $projvar != "MSIP_PROJ_ROOT" } {
					catch { exec $exec_cmd -c "grep \"$projvar\" $pcsfile $removecommentline | \
					                                grep -v -e \"^\[\[:blank:\]\]*#\" \
									        -e \"$projvar/$pcstriple\" \
										$varhelicpaths | wc -l" } ccitemavail
					incr checks
					if { $ccitemavail > 0 && [iswaiveenvvarsfile $pcsfile] == 0 } {
						ruleErrorApplicable "(PCSQA-2.1cc in01) Reference $projvar in file $pcsfile, use \$MSIP_PROJ_ROOT" 	
					}
					if { $bberror == 0 } {
						catch { exec $exec_cmd -c "grep \"$projvar\" $pcsfile \
										$removecommentline | \
										$replacepcsmacros $parentpcsreplace | \
										grep -v -e \"^\[\[:blank:\]\]*#\" \
										-e \"$projvar/$pcstriple\" \
										$acceptprojvarparentpcstriple \
										-e \"$projvar/cad\" \
										$varhelicpaths | wc -l" } ccitemavail
						incr checks
						if { $ccitemavail > 0 } {
						catch { exec $exec_cmd -c "grep \"$projvar\" $pcsfile \
										$removecommentline | \
										$replacepcsmacros $parentpcsreplace | \
										grep -v -e \"^\[\[:blank:\]\]*#\" \
										-e \"$projvar/$pcstriple\" \
										$acceptprojvarparentpcstriple \
										-e \"$projvar/cad\" \
										$varhelicpaths " } ccitemrefs 
							set ccitemrefs [split $ccitemrefs "\n"]
							foreach ccitemref $ccitemrefs {
								ruleErrorApplicable "(PCSQA-2.1cc in01) Reference '$ccitemref' in file $pcsfile refers to different PCS"
							} 	
						}
					}	
				}
			}
			
			if { [iswaivereferencesfile $pcsfile] == 0 } {
				if { ( $msip_parentchild_type == "" ||
				       ( $msip_parentchild_type != "CHILD_CAD_SETUP" && 
				         $msip_parentchild_type != "CHILD_ALL" ) ) } { 	     
					set acceptparentpcstriple ""
				} else {
					set acceptparentpcstriple "-e \"$parentpcstriple\""
				}
				## detect reference outside scope of CCSes and PCSes: starting with /remote/
				## ignore all paths which are defined in ignoreprojvars
				set projvars [list "\[\[:blank:\]\]/remote/" "\[\[:blank:\]\]/slowfs/" \
				                   "\[\[:blank:\]\]/SCRATCH/" "\[\[:blank:\]\]/u/" "\[\[:blank:\]\]/usr/" \
						   "\\\"/remote/" "\\\"/slowfs/" "\\\"/SCRATCH/" "\\\"/u/" "\\\"/usr/" \
						   "'/remote/" "'/slowfs/" "'/SCRATCH/" "'/u/" "'/usr/" \
				             ]
				foreach projvar $projvars {
					catch { exec $exec_cmd -c "grep \"$projvar\" $pcsfile \
									$removecommentline | \
									$ignoreprojvars | \
									$removeenvchars | \
									$replacepcsmacros $parentpcsreplace | \
									$replaceccsmacros | \
									grep -v -e \"^\[\[:blank:\]\]*#\" \
									-e \"$pcstriple\" $acceptparentpcstriple \
									-e \"$msip_cad_proj_name/$msip_cad_rel_name\" | wc -l" } projvaravail
					incr checks
					if { $projvaravail > 0 } {
					catch { exec $exec_cmd -c "grep \"$projvar\" $pcsfile \
									$removecommentline | \
									$ignoreprojvars | \
									$removeenvchars | \
									$replacepcsmacros $parentpcsreplace | \
									$replaceccsmacros | \
									grep -v -e \"^\[\[:blank:\]\]*#\" \
									-e \"$pcstriple\" $acceptparentpcstriple \
									-e \"$msip_cad_proj_name/$msip_cad_rel_name\" " } projvarrefs
						set projvarrefs [split $projvarrefs "\n"]
						foreach projvarref $projvarrefs {
							## 2.1cc (spec 20.1) -> 2.1hhh (since spec 21.1)
							## Waiving for this Rule 2.1cc spec 20.1 does also apply for 2.1hhh
							ruleErrorApplicable "(PCSQA-2.1hhh in01) Reference '$projvarref' in file $pcsfile refers outside PCSes,CCSes,ude and fab area"
						} 	
					}
				}
				
				if { "in01" == "us01" } {
					catch { exec $exec_cmd -c "grep $varhelicpaths $pcsfile \
									$removecommentline | \
									$removeenvchars | \
									grep -v -e \"^\[\[:blank:\]\]*#\" | wc -l" } helicrefavail
					if { $helicrefavail > 0 } {
						catch { exec $exec_cmd -c "grep $varhelicpaths $pcsfile \
										$removecommentline | \
										$removeenvchars | \
										grep -v -e \"^\[\[:blank:\]\]*#\" " } helicrefs
						set helicrefs [split $helicrefs " \t\n"]
						foreach helicref $helicrefs {
							if { $helicref == "" } {
								continue
							}
							catch { exec $exec_cmd -c "echo $helicref | grep $helicpaths | sed -e 's#MSIP_PROJ_ROOT#/remote/proj#g' " } helicpath
							if { $helicpath != "" } {
							     	incr checks
								if { [file exists $helicpath] == 0 } {
									ruleErrorApplicable "(PCSQA-2.1bb us01) Helic reference path '$helicpath' in file $pcsfile does not exist"
							     	}
							}
						}				
					}				
				}
			}

		    }
		}

		if { [file isdirectory $pcs/cad/shared/starrcxt] } {	
			catch { exec $exec_cmd -c "find $pcs/cad/shared/starrcxt -type f" } starfiles
			foreach starfile $starfiles {
			    if { [file exists $starfile] } {
				catch { exec $exec_cmd -c "grep \"SPICE_SUBCKT_FILE\" $starfile | grep -v \"^*\" | wc -l" } spicesubcktfileavail
				incr checks
				if { $spicesubcktfileavail > 0 } {
					ruleErrorApplicable "(PCSQA-2.1aa in01) SPICE_SUBCKT_FILE available in file $starfile" 	
				}
			    }
			}
		}
	}

	set designpcs "/remote/proj/ddr54/d820-ddr54v2-tsmc5ffp12/rel1.30a_mrvl_sup1"
	if { [file isdirectory $designpcs] } {		
	    catch { exec sh -c "ls -l $designpcs 2> /dev/null | awk '{print \$11}' | head -1" } link
	    if { $link != "" } {
	        ## Rule 2.1x is only applicable, if designpcs is a link; a project setup
		set targetdesignpcs [gettargetfile $designpcs]
		if { [file exists $projectenv] } {
			catch { exec $exec_cmd -c "cat $projectenv | grep -v '^\[\[:blank:\]\]*#' | grep -e setenv | grep -v unsetenv | grep -e MSIPRunDirRestrict\[\[:blank:\]\] | awk '{ print \$3 }' | sed -e 's/\"//g'" }  msiprundirrestrictvalue
			if { $msiprundirrestrictvalue == "" } {
				## group of 2.1x is not applicable, if MSIPRunDirRestrict is defined, see rule 2.1mm.
				set sg_pdks 65859
				catch { exec sh -c "ls -dn $targetdesignpcs | awk '{ print \$4 }'" } filegroupid
				incr checks
				if { $filegroupid != $sg_pdks } {
					ruleErrorApplicable "(PCSQA-2.1x in01) PCS directory $designpcs does not belong to $sg_pdks (sg_pdks) group ID, but $filegroupid"
				}
			}
		}
		
		set designpcspermissions [file attributes $targetdesignpcs -permissions]
		set gpw_permissions      "xxxx1xxxx"
		set gpw_permissions_txt  "g+w"
		incr checks
		if { [matchpermissions $designpcspermissions $gpw_permissions] == 0 } {
			set designpcsugopermissions [string range $designpcspermissions [expr [string length $designpcspermissions] - 3] [expr [string length $designpcspermissions] - 1]]
			ruleErrorApplicable "(PCSQA-2.1x in01) PCS directory $designpcs has not $gpw_permissions_txt permissions, but $designpcsugopermissions"
		}
	    }
	}

	if { [file exists $projectenv] } {
		set intelp4port 1700
		set p4port 0
		if { [file exists $run_dir/${uniqueprefix}udeenv] } {
			catch { exec $exec_cmd -c "cat $run_dir/${uniqueprefix}udeenv | grep -e P4PORT | head -1 | awk '{ print \$2 }' | sed -e 's/\"//g' -e 's/:/ /g' | awk '{ print \$2 }'" } p4port
		}
		if { $p4port != $intelp4port } {
			catch { exec $exec_cmd -c "cat $projectenv | grep -v '^\[\[:blank:\]\]*#' | grep -e setenv | grep -v unsetenv | grep -e P4PORT | awk '{ print \$3 }' | sed -e 's/\"//g' -e 's/:/ /g' | awk '{ print \$2 }'" } p4port
		}
		if { $p4port != $intelp4port &&
		     $parentpcs != "" &&
		     ( $msip_parentchild_type == "CHILD_CAD_SETUP" ||
		       $msip_parentchild_type == "CHILD_ALL" ) } {
			set parentpcsprojectenv $parentpcs/cad/project.env
			if { [file exists $parentpcsprojectenv] } {
				catch { exec $exec_cmd -c "cat $parentpcsprojectenv | grep -v '^\[\[:blank:\]\]*#' | grep -e setenv | grep -v unsetenv | grep -e P4PORT | awk '{ print \$3 }' | sed -e 's/\"//g' -e 's/:/ /g' | awk '{ print \$2 }'" } p4port
			}
		}
		if { $p4port != $intelp4port &&
		     $refccs != "" &&
		     [file exists $refccs/design/project.env] } {
			catch { exec $exec_cmd -c "cat $refccs/design/project.env | grep -v '^\[\[:blank:\]\]*#' | grep -e setenv | grep -v unsetenv | grep -e P4PORT | awk '{ print \$3 }' | sed -e 's/\"//g' -e 's/:/ /g' | awk '{ print \$2 }'" } p4port
		}
		set intelpcs 0
		if { $p4port == $intelp4port &&
		     $refccs != "" &&
		     [string first "-int" $msip_cad_proj_name] != -1 } {
			set intelpcs 1
		}

		set msiprundirrestrictwarning 0
		set parentpcstext ""
		set parentpcsunsetenvmsiprundirrestrict 0
		catch { exec $exec_cmd -c "cat $projectenv | grep -v '^\[\[:blank:\]\]*#' | grep -e setenv | grep -v unsetenv | grep -e MSIPRunDirRestrict\[\[:blank:\]\] | awk '{ print \$3 }' | sed -e 's/\"//g'" }  msiprundirrestrictvalue
		catch { exec $exec_cmd -c "cat $projectenv | grep -v '^\[\[:blank:\]\]*#' | grep unsetenv  | grep -e MSIPRunDirRestrict\[\[:blank:\]\] | wc -l" }  pcsunsetenvmsiprundirrestrict
		if { $msiprundirrestrictvalue == "" &&
		     $parentpcs != "" &&
		     ( $msip_parentchild_type == "CHILD_CAD_SETUP" ||
		       $msip_parentchild_type == "CHILD_ALL" ) } {
			set parentpcsprojectenv $parentpcs/cad/project.env
			if { [file exists $parentpcsprojectenv] } {
				catch { exec $exec_cmd -c "cat $parentpcsprojectenv | grep -v '^\[\[:blank:\]\]*#' | grep -e setenv | grep -v unsetenv | grep -e MSIPRunDirRestrict\[\[:blank:\]\] | awk '{ print \$3 }' | sed -e 's/\"//g'" }  msiprundirrestrictvalue
				catch { exec $exec_cmd -c "cat $parentpcsprojectenv | grep -v '^\[\[:blank:\]\]*#' | grep unsetenv  | grep -e MSIPRunDirRestrict\[\[:blank:\]\] | wc -l" }  parentpcsunsetenvmsiprundirrestrict
				if { $msiprundirrestrictvalue != "" } {
					if { $pcsunsetenvmsiprundirrestrict == 0 } {
						ruleErrorApplicable "(PCSQA-2.1mm in01) Parent PCS sets MSIPRunDirRestrict, but PCS does not and no unsetenv"
					}
					set msiprundirrestrictwarning 1
					set parentpcstext "of Parent PCS "
				}
			}
		}
		if { $msiprundirrestrictvalue == "" &&
		     $refccs != "" &&
		     [file exists $refccs/design/project.env] } {
			catch { exec $exec_cmd -c "cat $refccs/design/project.env | grep -v '^\[\[:blank:\]\]*#' | grep -e setenv | grep -v unsetenv | grep -e MSIPRunDirRestrict\[\[:blank:\]\] | awk '{ print \$3 }' | sed -e 's/\"//g'" }  msiprundirrestrictvalue
			if { $msiprundirrestrictvalue != "" } {
				if { $pcsunsetenvmsiprundirrestrict == 0 &&
				     $parentpcsunsetenvmsiprundirrestrict == 0 } {
					ruleErrorApplicable "(PCSQA-2.1mm in01) CCS sets MSIPRunDirRestrict, but (Parent) PCS does not and no unsetenv"
				}
			 	set msiprundirrestrictwarning 1
			 	set parentpcstext "of CCS "
			}
		}
		set restricterrors 0
		if { $msiprundirrestrictvalue != "" } {
			if { $intelpcs } {
				set rule "ee1"
			} else {
				set rule "mm"
			}
			## check Unix group
			catch { exec $exec_cmd -c "echo $msiprundirrestrictvalue | sed -e 's/:/ /g' | awk '{ print \$1 }'" }  restrictunixgroup
			catch { exec $exec_cmd -c "getent group $restrictunixgroup | wc -l" }  getentresults
			incr checks
			if { $getentresults == 0 } {
				set msgtext "(PCSQA-2.1$rule in01) Unix group $restrictunixgroup of MSIPRunDirRestrict value in project.env ${parentpcstext}is no valid Unix group"
				if { $msiprundirrestrictwarning == 1 } {
					ruleWarningApplicable "$msgtext"
				} else {
					ruleErrorApplicable "$msgtext"
					incr restricterrors
				}
			}
			
			if { $intelpcs } {
				incr checks
				if { [string equal -length 3 "icf" $restrictunixgroup ] == 0 } {
					set msgtext "(PCSQA-2.1ee1 in01) Unix group $restrictunixgroup of MSIPRunDirRestrict value in project.env ${parentpcstext}does not start with 'icf'"
					if { $msiprundirrestrictwarning == 1 } {
						ruleWarningApplicable "$msgtext"
					} else {
						ruleErrorApplicable "$msgtext"
						incr restricterrors
					}
				}
			}

			## Check Octal code								
			catch { exec $exec_cmd -c "echo $msiprundirrestrictvalue | sed -e 's/:/ /g' | awk '{ print \$2 }'" }  octalcode
			incr checks
			if { [string length $octalcode] == 3 && $octalcode >= 0 && $octalcode <= 777 } {
				set requiredoctalcode "xxxxxx000"
				incr checks
				if { [matchpermissions $octalcode $requiredoctalcode] == 0 } {
					set msgtext "(PCSQA-2.1$rule in01) Octal code $octalcode of MSIPRunDirRestrict in project.env ${parentpcstext}has not xx0 permissions"
					if { $msiprundirrestrictwarning == 1 } {
						ruleWarningApplicable "$msgtext"
					} else {
						ruleErrorApplicable "$msgtext"
						incr restricterrors
					}
				}
			} else {
				set msgtext "(PCSQA-2.1$rule in01) Octal code $octalcode of MSIPRunDirRestrict in project.env ${parentpcstext}is no valid Unix octal code"
				if { $msiprundirrestrictwarning == 1 } {
					ruleWarningApplicable "$msgtext"
				} else {
					ruleErrorApplicable "$msgtext"
					incr restricterrors
				}
			}
		} else {
			if { $intelpcs } {
				## PCS should be treated as Intel out of Berry farm
				ruleErrorApplicable "(PCSQA-2.1ee1 in01) Omission of 'setenv MSIPRunDirRestrict <unix_group>:<octal_code>' in project.env"
			}
			incr restricterrors
		}

		if { $restricterrors == 0 &&
		     [string compare -length [string length $ude3proj] $ude3proj $pcs] == 0 } {
			if { [file type $pcs] == "link" } {
				set targetpcs [file readlink $pcs]]
				set refpcs    "/remote/proj/ddr54/d820-ddr54v2-tsmc5ffp12/rel1.30a_mrvl_sup1"
				if { $targetpcs == $refpcs } {
					incr checks
					set pcsdir $refpcs
					set requiredoctalcode [oct2bin $octalcode]
					while { $pcsdir != "/" } {
						set dirgroup       [file attributes $pcsdir -group]
						set dirpermissions [file attributes $pcsdir -permissions]
						if { $dirgroup == $restrictunixgroup && [matchpermissions $dirpermissions $requiredoctalcode] } {
							break
						}
						set pcsdir [file dirname $pcsdir]
					}
					if { $pcsdir == "/" } {
						ruleErrorApplicable "(PCSQA-2.1mm in01) Directory (or parent directory of) $refpcs has not the required MSIPRunDirRestrict settings <unix_group>:<octal_code> = $restrictunixgroup:$octalcode"
					}
				}
			}
		}

		if { $intelpcs } {
		set ccsmsiprundirrestrictvalue ""			
		if { $refccs != "" } {
			set envcommontcl $refccs/cad/shared/env_common.tcl
			if { [file exists $envcommontcl] == 0 } {
				set envcommontcl $refccs/cad/shared/env/env_common.tcl
			}
			if { [file exists $envcommontcl] } {
				catch { exec $exec_cmd -c "cat $envcommontcl | grep -v '^\[\[:blank:\]\]*#' | sed -e 's/db::setPrefValue\\s\\s*MSIPRunDirRestrict/\\ndb::setPrefValue MSIPRunDirRestrict/g' | grep -e \"db::setPrefValue MSIPRunDirRestrict\" | head -1 | awk '{ print \$4 }' | sed -e 's/\"//g' -e 's/\}//g'" }  ccsmsiprundirrestrictvalue
			}
		}
		if { $msiprundirrestrictvalue != "" && $ccsmsiprundirrestrictvalue != "" } {
			incr checks
		     	if { $msiprundirrestrictvalue != $ccsmsiprundirrestrictvalue } {
				ruleErrorApplicable "(PCSQA-2.1ee2 in01) MSIPRunDirRestrict values at PCS ($msiprundirrestrictvalue) in project.env and CCS ($ccsmsiprundirrestrictvalue) in env_common.tcl are different"
			}
		}
		if { $msiprundirrestrictvalue != "" } {
			set envtcls [glob -nocomplain $pcs/cad/*/env.tcl]
			set refcode "if{\[catch{db::createPrefMSIPRunDirRestrict-value\\\"unix_group:octal_code\\\"}err\]}{db::setPrefValueMSIPRunDirRestrict-value\\\"unix_group:octal_code\\\"}"
			catch { exec $exec_cmd -c "echo \"$refcode\" | sed -e 's/unix_group:octal_code/$msiprundirrestrictvalue/g'" } refcode
			foreach envtcl $envtcls {
				catch { exec sh -c "basename \$(dirname $envtcl)" } metalstack
				set omitted 0
				set correctvalue 1
				
				catch { exec $exec_cmd -c "cat $envtcl | grep -v '^\[\[:blank:\]\]*#' | sed -e 's/db::setPrefValue\\s\\s*MSIPRunDirRestrict/\\ndb::setPrefValue MSIPRunDirRestrict/g' | grep -e \"db::setPrefValue MSIPRunDirRestrict\" | head -1 | awk '{ print \$4 }' | sed -e 's/\"//g' -e 's/\}//g'" }  metalmsiprundirrestrictvalue
				incr checks
				if { $metalmsiprundirrestrictvalue != "" } {
					incr checks
					if { $msiprundirrestrictvalue != $metalmsiprundirrestrictvalue } {
						ruleErrorApplicable "(PCSQA-2.1ee2 in01) MSIPRunDirRestrict values at PCS ($msiprundirrestrictvalue) in project.env and TCL preference value in $metalstack/env.tcl ($metalmsiprundirrestrictvalue) are different"
						set correctvalue 0
					}
				} else {
					ruleErrorApplicable "(PCSQA-2.1ee2 in01) Omission of TCL preference value setting 'db::setPrefValue MSIPRunDirRestrict -value \"$msiprundirrestrictvalue\"' in $metalstack/env.tcl"
					set omitted 1
				}

				if { $ccsmsiprundirrestrictvalue == "" && $omitted == 0 && $correctvalue == 1 } {
					## convert the actual code, which has to be checked, in same format as refcode (oneliner without spaces)					
					catch { exec $exec_cmd -c "cat $envtcl | grep -v '^\[\[:blank:\]\]*#' | tr -d '\n' | sed -e 's/ //g' -e 's/\\t//g' | sed -e 's/if/\\nif/g' | grep db::createPrefMSIPRunDirRestrict | sed -e 's/\}/\} /g' -e 's/\} err\\]/\}err\\]/g' -e 's/\} \{/\}\{/g' -e 's/\} /\}\\n/g' | grep db::createPrefMSIPRunDirRestrict" } actcode
					incr checks
					if { $actcode != $refcode } {
						ruleErrorApplicable "(PCSQA-2.1ee2 in01) TCL preference value of MSIPRunDirRestrict in $metalstack/env.tcl is not set by required code"
						if { [ruleApplicable "2.1ee2"] } {
							puts "if { \[ catch { db::createPref MSIPRunDirRestrict -value \"$msiprundirrestrictvalue\" } err \] } {"
							puts "	db::setPrefValue MSIPRunDirRestrict -value \"$msiprundirrestrictvalue\""
							puts "}"
						}
					}
				}
			}
		}
		}
		
		catch { exec $exec_cmd -c "cat $projectenv | grep -v '^\[\[:blank:\]\]*#' | grep -e setenv | grep -v unsetenv | grep -e PINS_VERSION | tail -1 | awk '{ print \$3 }' | sed -e 's/\"//g'" }  pins_version_value
		if { $pins_version_value == "" } {
			if { $parentpcs != "" &&
			     ( $msip_parentchild_type == "CHILD_CAD_SETUP" ||
			       $msip_parentchild_type == "CHILD_ALL" ) } {
				set parentpcsprojectenv $parentpcs/cad/project.env
				if { [file exists $parentpcsprojectenv] } {
					catch { exec $exec_cmd -c "cat $parentpcsprojectenv | grep -v '^\[\[:blank:\]\]*#' | grep -e setenv | grep -v unsetenv | grep -e PINS_VERSION | tail -1 | awk '{ print \$3 }' | sed -e 's/\"//g'" }  pins_version_value
				}
			}	
			if { $pins_version_value == "" } {
				if { $refccs != "" } {
					set refccsprojectenv $refccs/design/project.env
					if { [file exists $refccsprojectenv] } {
						catch { exec $exec_cmd -c "cat $refccsprojectenv | grep -v '^\[\[:blank:\]\]*#' | grep -e setenv | grep -v unsetenv | grep -e PINS_VERSION | tail -1 | awk '{ print \$3 }' | sed -e 's/\"//g'" }  pins_version_value
					}
				}	
			}
		}
		if { $pins_version_value != "" } {
			set pinsfile $::env(udecadrep)/msip/ude_conf/snps_pins/$pins_version_value/ddr54_pins.txt
			if { [file exists $pinsfile] == 0 } {
				set pinsfile $::env(udecadrep)/msip/ude_conf/snps_pins_gen2/production/ddr54/$pins_version_value/ddr54_pins.txt
				if { [file exists $pinsfile] == 0 } {
					ruleWarningApplicable "(PCSQA-2.1pp in01) No PINS_VERSION $pins_version_value file has been found: $pinsfile"
				}	
			}
			if { $vicipinsversion != "" && $vicipinsversion != $pins_version_value } {
				ruleErrorApplicable "(PCSQA-2.1pp in01) PINS_VERSION value '$pins_version_value' in (inherited) project.env is not equal to value '$vicipinsversion' in ViCi Porting Spec"
			}			
		} else {
			ruleErrorApplicable "(PCSQA-2.1pp in01) Omission of PINS_VERSION setting in (inherited) project.env"
		}

		catch { exec $exec_cmd -c "cat $projectenv | grep -v '^\[\[:blank:\]\]*#' | grep -e setenv | grep -v unsetenv | grep -e EXPORT_COMPLIANT  | awk '{ print \$3 }' | sed -e 's/\"//g'" }  export_compliant_value
		if { $export_compliant_value == 1 } {
			catch { exec $exec_cmd -c "cat $projectenv | grep -v '^\[\[:blank:\]\]*#' | grep -e setenv | grep -v unsetenv | grep -e MSIPRunDirRestrict\[\[:blank:\]\] | awk '{ print \$3 }' | sed -e 's/\"//g'" }  msiprundirrestrictvalue
			incr checks
			if { $msiprundirrestrictvalue != "" } {
				## check Unix group
				catch { exec $exec_cmd -c "echo $msiprundirrestrictvalue | sed -e 's/:/ /g' | awk '{ print \$1 }'" }  restrictunixgroup
				catch { exec $exec_cmd -c "getent group $restrictunixgroup | wc -l" }  getentresults
				incr checks
				if { $getentresults == 0 } {
					ruleErrorApplicable "(PCSQA-2.1qq in01) Unix group $restrictunixgroup of MSIPRunDirRestrict value in project.env of EXPORT_COMPLIANT PCS is no valid Unix group"
				}
			} else {
				ruleErrorApplicable "(PCSQA-2.1qq in01) Omission of 'setenv MSIPRunDirRestrict <unix_group>:<octal_code>' in project.env of EXPORT_COMPLIANT PCS"
			}
			
			if { [file exists $pcs/design/lib.defs] } {
				catch { exec $exec_cmd -c "cat $pcs/design/lib.defs | grep -v -e \"^\[\[:blank:\]\]*#\" -e \"^\[\[:blank:\]\]*$\" | head -2 | sed -e 's/\\s//g' -e 's/INCLUDE/INCLUDE /' > $run_dir/libdefsincludes" } dummy
				catch { exec $exec_cmd -c "echo 'INCLUDE \${PROJ_HOME}/cad/lib.defs' > $run_dir/reflibdefsincludes" } dummy 
				catch { exec $exec_cmd -c "echo 'INCLUDE \${MSIP_PROJ_P4WS_ROOT}/projects/\${MSIP_PRODUCT_NAME}ec/\${MSIP_PROJ_NAME}/\${MSIP_REL_NAME}/lib/lib.defs' >> $run_dir/reflibdefsincludes" } dummy
				catch { exec $exec_cmd -c "diff $run_dir/libdefsincludes $run_dir/reflibdefsincludes > $run_dir/difflibdefsincludes" } dummy
				if { [file size $run_dir/difflibdefsincludes] > 0 } {
					ruleErrorApplicable "(PCSQA-2.1rr in01) design/lib.defs of EXPORT_COMPLIANT PCS has not required content"
					if { [ruleApplicable "2.1rr"] } {
					puts "First 2 INCLUDE statements in PCS design/lib.defs:" 
    					set fid [open $run_dir/libdefsincludes r]
    					while { [gets $fid line] >= 0 } {
     	 					puts $line
    					}
    					close $fid
					puts "Required contents:"
    					set fid [open $run_dir/reflibdefsincludes r]
    					while { [gets $fid line] >= 0 } {
     	 					puts $line
    					}
    					close $fid
					}
				}
				catch { exec $exec_cmd -c "rm -f $run_dir/*libdefsincludes" } dummy
			}
		}
	}

	set designdirs [list "design" "design_unrestricted"]
	foreach designdir $designdirs {
		set pcsdesign $pcs/$designdir
		if { [file isdirectory $pcsdesign] } {
			catch { exec $exec_cmd -c "du -sh $pcsdesign | awk '{ print \$1 }'" } diskusage
			incr checks
			if { [string first M $diskusage] != -1 || [string first G $diskusage] != -1 } {
				set more10M 1
				if { [string first M $diskusage] != -1 } {
					set digitdiskusage [string trimright $diskusage M]
					if { [format %f $digitdiskusage]  <= 10.0 } {
						set more10M 0
					}				
				}
				if { $more10M == 1 } {
					if { $designdir == "design" } {
						set errorchars "ii"
					}
					if { $designdir == "design_unrestricted" } {
						set errorchars "kk"
					}
					ruleErrorApplicable "(PCSQA-2.1$errorchars in01) $designdir folder of PCS contains more than 10MB of information"
				}
			}
			if { $designdir == "design_unrestricted" } {
				set cadrep "/remote/cad-rep"
				incr checks
				if { [file type $pcsdesign] == "link" } {
					set targetdesign [gettargetfile $pcsdesign]
					if { [string compare -length [string length $cadrep] $cadrep $targetdesign] != 0 } {
						ruleErrorApplicable "(PCSQA-2.1ll in01) $designdir folder of PCS is no link to $cadrep location, but $targetdesign"
					}
				} else {
					if { [string compare -length [string length $cadrep] $cadrep $pcsdesign] != 0 } {
						ruleErrorApplicable "(PCSQA-2.1ll in01) $designdir folder of PCS is not located in $cadrep location"
					}
				}
			}
		}
	}
	
	## Rule 2.1yy/2.1lll
	if { [file isdirectory $pcs] && $refccs != "" } {

		set cvcp_has_AreaCap 0
		if { [file exists $run_dir/${uniqueprefix}lppsource] } {
			catch { exec $exec_cmd -c "cat $run_dir/${uniqueprefix}lppsource | grep cvcp_has_AreaCap | grep true | wc -l" } cvcp_has_AreaCap
		}

		set modelsdirs [list "cvcp" "cvcp_mc" "cvcp_mc_sigamp" \
		                     "cvpp" "cvpp_mc" "cvpp_mc_sigamp" "EOL" \
				     "hspice" "hspice_mc" "hspice_mc_sigamp" \
				     "hspice_rf" "hspice_mc_rf" "hspice_mc_sigamp_rf" "nt"]
		foreach modelsdir $modelsdirs {
			if { [file exists $refccs/cad/models/$modelsdir] } {
				 incr checks
				 if { [file exists $pcs/cad/models/$modelsdir] == 0 } {
				 	 ruleErrorApplicable "(PCSQA-2.1yy in01) Omission of $pcs/cad/models/$modelsdir"
				 } else {
				 	 if { $cvcp_has_AreaCap > 0 &&
				 	      [string first $modelsdir "cvcp"] != -1 } {
				 		 incr checks
				 		 ## Rule 2.1lll
				 		 set targetcvcp $pcs/cad/models/$modelsdir
				 		 if { [file type $targetcvcp] == "link" } {
				 			 ## PCS links to Parent PCS/CCS
				 			 set targetcvcp [file readlink $targetcvcp]
				 		 }
				 		 if { [file type $targetcvcp] == "link" } {
				 			 ## Parent PCS links to CCS
				 			 set targetcvcp [file readlink $targetcvcp]
				 		 }
				 		 if { [file type $targetcvcp] == "link" } {
				 			 ## CCS links to /remote/cad-rep/msip/generic_decks/cvcp_models/<version>/cvcp*
				 			 set targetcvcp [file readlink $targetcvcp]
				 		 }
				 		 set targetpath [file dirname [file dirname $targetcvcp]]
				 		 set reftargetpath "/remote/cad-rep/msip/generic_decks/cvcp_models"
				 		 if { [string compare $targetpath $reftargetpath] != 0 } {
				 			 ruleErrorApplicable "(PCSQA-2.1lll in01) cad/models/$modelsdir does not point to $reftargetpath, but $targetcvcp"
				 		 } else {
				 			 set targetversion [file tail [file dirname $targetcvcp]]
				 			 set targetversionint [version2int $targetversion]
				 			 set reftargetversion "2021.04"
				 			 set reftargetversionint [version2int $reftargetversion]

				 			 if { [string is integer $targetversionint] &&
				 			      [string is integer $reftargetversionint] } {
				 				 while { [string length $reftargetversionint] < 
				 					 [string length $targetversionint] } {
				 						 set reftargetversionint [expr $reftargetversionint * 10]
				 				 }
				 			 }
				 			 
				 			 if { $targetversionint < $reftargetversionint } {
				 				 ruleErrorApplicable "(PCSQA-2.1lll in01) cad/models/$modelsdir does not point to at least $reftargetpath/$reftargetversion, but $targetversion"									 
				 			 }
				 		 }							 
				 	 }
				 }
			}
		}		
	}
	
	## Rule 2.1zz (P10113980-6859)
	if { [file isdirectory $pcs] && $refccs != "" } {
		set streamlayermaps [glob -nocomplain $pcs/cad/*/stream/stream*.layermap* $pcs/cad/*/stream/*/stream*.layermap*]
		foreach streamlayermap $streamlayermaps {
			catch { exec $exec_cmd -c "echo $streamlayermap | sed -e 's#$pcs#$refccs#g'" } ccsstreamlayermap 
			if { [file exists $ccsstreamlayermap] } {
				if { [file type $streamlayermap] == "link" } {
					set pcsstreamlayermap [file readlink $streamlayermap]
					if { [file normalize $pcsstreamlayermap] == [file normalize $ccsstreamlayermap] } {
						## PCS stream.layermap is link to CCS"
						continue
					}
				}
			
				incr checks
				set additionalpcslpps [list]
				## catch { exec $exec_cmd -c "cat $streamlayermap | grep -v ^\[\[:blank:\]\]*# | awk '{ print \$1,\$2 }'" } pcslpps
				catch { exec $exec_cmd -c "cat $streamlayermap | grep -v ^\[\[:blank:\]\]*# | grep ^TEMP | awk '{ print \$1 }'" } pcslpps
				set pcslpps [lsort -unique [split $pcslpps "\n"]]
				foreach pcslpp $pcslpps {
					if { $pcslpp != " " } {
						## replace space between layer name and purpose
						## by grep blank wild card
						## catch { exec $exec_cmd -c "echo \"$pcslpp\" | sed -e 's# #\[\[:blank:\]\]\[\[:blank:\]\]*#g' -e 's#$#\[\[:blank:\]\]\[\[:blank:\]\]*#g'" } pcslppgrep

						set pcslppgrep "$pcslpp\[\[:blank:\]\]"
						catch { exec $exec_cmd -c "grep \"^$pcslppgrep\" $ccsstreamlayermap | wc -l" } pcslppinccs
						if { $pcslppinccs == 0 } {
							lappend additionalpcslpps $pcslpp
						} 
##						else {
##							catch { exec $exec_cmd -c "grep \"^$pcslppgrep\" $streamlayermap    | awk '{ print \$3,\$4 }'" } pcslppnums
##							set pcslppnums [lsort -unique [split $pcslppnums "\n"]]
##							catch { exec $exec_cmd -c "grep \"^$pcslppgrep\" $ccsstreamlayermap | awk '{ print \$3,\$4 }'" } ccslppnums
##							set ccslppnums [lsort -unique [split $ccslppnums "\n"]]
##							set lppnumsequal 1
##							if { [llength $pcslppnums] == [llength $ccslppnums] } {
##								for { set i 0 } { $i < [llength $pcslppnums] } { incr i } {
##									set pcslppnum [lindex $pcslppnums $i]
##									set ccslppnum [lindex $ccslppnums $i]
##									if { "$pcslppnum" != "$ccslppnum" } {
##										set lppnumsequal 0
##										break 
##									}
##								}
##							} else {
##								set lppnumsequal 0					
##							}
##							if { $lppnumsequal == 0 } {
##								ruleErrorApplicable "(PCSQA-2.1zz in01) PCS lpp '$pcslpp' has different stream numbers '$pcslppnums' as in CCS '$ccslppnums', in PCS stream layermap $streamlayermap in comparison to CCS equivalent $ccsstreamlayermap"					
##							}
##						}
					}					
				}
				foreach additionalpcslpp $additionalpcslpps {
					ruleErrorApplicable "(PCSQA-2.1zz in01) Additional TEMP layer '$additionalpcslpp' in PCS stream layermap $streamlayermap in comparison to CCS equivalent $ccsstreamlayermap"					
				}				
			}
		}		
	}	
}

## 2.1.3 Rules exclusive for LL PCSs 
if { "ddr54" == "std" &&
     $siteid == "in01" } {

	set completed_refccs 0
	set node ""
	if { $refccs != "" } {
		set releasestatus ""
		if { [file exists $refccs/usage.txt] } {
			catch { exec $exec_cmd -c "grep \"Release Status\" $refccs/usage.txt | sed -e 's/:/ : /g' | awk '{print \$4}'" } releasestatus
		}
		if { [file exists $refccs/COMPLETED] ||
		     [file exists $refccs/COMPLETED.txt] ||
		     $releasestatus == "COMPLETED" } {
			set completed_refccs 1
		}

		set ccsname [file tail [file dirname $refccs]]
		set firstdash   [string first "-" $ccsname]
		set seconddash  [string first "-" $ccsname [expr $firstdash + 1]]
		set foundrynode [string range $ccsname [expr $firstdash + 1] [expr $seconddash - 1]]
		set node [string trimleft $foundrynode abcdefghijklmnopqrstuvwxyz_]
		set node [lindex [scan $node {%d}] 0]
	}
	  
	## 2.1.3a/2.1.3b/2.1.3g
	set envtcls [glob -nocomplain $pcs/cad/*/env.tcl]
	foreach envtcl $envtcls {
		catch { exec sh -c "basename \$(dirname $envtcl)" } metalstack
		incr checks
		if { [file isdirectory $pcs/cad/$metalstack/lltech] == 0 } {
			puts "SNPS_ERROR  : (PCSQA-2.1.3a in01) No directory cad/$metalstack/lltech exists"					
		} else {
			if { 0 && [file exists $pcs/cad/$metalstack/lltech/env.tcl] == 0 } {
				## 2.1.3g
				## spec 26.0
				puts "SNPS_ERROR  : (PCSQA-2.1.3g in01) No cad/$metalstack/lltech/env.tcl exists"					
			}
		
			if { 0 && $completed_refccs } {
				## 2.1.3b
				## spec 26.0
				set ccslltechcontentpaths [glob -nocomplain $refccs/cad/$metalstack/lltech/*]
				foreach ccslltechcontentpath $ccslltechcontentpaths {
					set ccslltechcontent [file tail $ccslltechcontentpath]
					incr checks
					if { [file exists $pcs/cad/$metalstack/lltech/$ccslltechcontent] == 0 ||
					     [file type   $pcs/cad/$metalstack/lltech/$ccslltechcontent] != "link" } {
						puts "SNPS_ERROR  : (PCSQA-2.1.3b in01) No link cad/$metalstack/lltech/$ccslltechcontent exists"					
					} else {
						set ccstarget [gettargetfile $pcs/cad/$metalstack/lltech/$ccslltechcontent]
						incr checks
						if { $ccstarget != [file normalize $ccslltechcontentpath] } {
							puts "SNPS_ERROR  : (PCSQA-2.1.3b in01) Link cad/$metalstack/lltech/$ccslltechcontent does not link to $ccslltechcontentpath"					
						}
					}
				}
			}
		}
	}
	
	## 2.1.3c
	incr checks
	if { [file exists $pcs/usage.txt] == 0 } {
		puts "SNPS_ERROR  : (PCSQA-2.1.3c in01) No $pcs/usage.txt exists"						
	}

	set libdefs $pcs/design/lib.defs	
	## 2.1.3d
	if { $node != "" && $node <= 7 } {
		incr checks
		if { [file exists $libdefs] == 0 } {
			puts "SNPS_ERROR  : (PCSQA-2.1.3d in01) No design/lib.defs exists"						
		} else {
			catch { exec sh -c "cat $libdefs | grep -v ^\[\[:blank:\]\]*# | grep INCLUDE     | \
			                                   grep -v -e PROJ_P4_ROOT -e SOFTINCLUDE | \
							   awk '{print \$2}' | sed -e 's#MSIP_PROJ_ROOT#$::env(PCSQA_PROJ_ROOT)#g' | \
							   $macroreplace $ccsreplace $parentpcsreplace" } includes
			set includes [split $includes \n]
			set includefound 0
			foreach include $includes {
				set envtcls [glob -nocomplain $pcs/cad/*/env.tcl]
				foreach envtcl $envtcls {
					catch { exec sh -c "basename \$(dirname $envtcl)" } metalstack
					catch { exec sh -c "echo '$include' | sed -e 's#\$\{CAD_METAL_STACK\}#$metalstack#g' \
					                                          -e 's#CAD_METAL_STACK#$metalstack#g' \
										  -e 's#\$\{METAL_STACK\}#$metalstack#g' \
										  -e 's#METAL_STACK#$metalstack#g'" } metalinclude
					if { [file normalize $metalinclude] ==
					     [file normalize $pcs/cad/$metalstack/lltech/layout_tech/lib.defs] } {
					     set includefound 1
					     break
					}
				}
				if { $includefound == 1 } {
					break
				}
			}
			incr checks
			if { $includefound == 0 } {
				puts "SNPS_ERROR  : (PCSQA-2.1.3d in01) No INCLUDE of cad/<metal-stack>/lltech/layout_tech/lib.defs exists in design/lib.defs"						
			}			
		}	
	}
		
	## 2.1.3e
	if { $node != "" && $node > 7 } {
		incr checks
		if { [file exists $libdefs] == 0 } {
			puts "SNPS_ERROR  : (PCSQA-2.1.3e in01) No design/lib.defs exists"						
		} else {
			catch { exec sh -c "cat $libdefs | grep -v ^\[\[:blank:\]\]*# | grep INCLUDE     | \
			                                   grep -v -e PROJ_P4_ROOT -e SOFTINCLUDE | \
							   awk '{print \$2}' | sed -e 's#MSIP_PROJ_ROOT#$::env(PCSQA_PROJ_ROOT)#g' | \
							   $macroreplace $ccsreplace $parentpcsreplace" } includes
			set includes [split $includes \n]
			set includefound 0
			foreach include $includes {
			       if { [file normalize $include] ==
			            [file normalize $refccs/design/lib.defs] } {
			            set includefound 1
			            break
			       }
			}
			incr checks
			if { $includefound == 0 } {
				puts "SNPS_ERROR  : (PCSQA-2.1.3e in01) No INCLUDE of $refccs/design/lib.defs exists in design/lib.defs"						
			}			
		}		
	}
	
	## 2.1.3f	
	incr checks
	if { [file exists $pcs/cad/shared/options_dmy] == 0 ||
	     [file size   $pcs/cad/shared/options_dmy] >  0 } {
		puts "SNPS_ERROR  : (PCSQA-2.1.3f in01) No empty $pcs/cad/shared/options_dmy exists"						
	}
	
	## 2.1.3h/2.1.3i
	set envtcls [glob -nocomplain $pcs/cad/*/env.tcl]
	foreach envtcl $envtcls {
		catch { exec sh -c "basename \$(dirname $envtcl)" } metalstack
		set lltechenvtcl $pcs/cad/$metalstack/lltech/env.tcl
		if { [file exists $lltechenvtcl] } {
			set refpath ""
			if { $node != "" && $node <= 7 } {
				set refpath "\"\$env\(PROJ_HOME\)/cad/\$env\(METAL_STACK\)/lltech/layout_tech/stream.layermap\""
				set rule "2.1.3h"
			}
			if { $node != "" && $node > 7  } {
				set refpath "\"\$env\(MSIP_PROJ_ROOT\)/cad/\$env\(MSIP_CAD_PROJ_NAME\)/\$env\(MSIP_CAD_REL_NAME\)/cad/\$env\(METAL_STACK\)/stream/STD/stream.layermap\""
				set rule "2.1.3i"
			}
			catch { exec sh -c "grep -e stream\\.layermap $lltechenvtcl | grep -v ^\[\[:blank:\]\]*# | awk '{ print \$NF }'" } path
			incr checks
			if { $path == "" ||
			    ( $refpath != "" &&
			      "$path" != "$refpath" ) } {
				puts "SNPS_ERROR  : (PCSQA-$rule in01) No define of stream layer map by $refpath in cad/$metalstack/lltech/env.tcl"						
			}
		}
	}
	
}


puts "Number of executed checks: $checks"		

if { $siteid != "in01" } {
	if { $p4errors > 0 } {
		puts "Give task $SEV(task) Pass Status value 'Waived' to ensure reaching task evaluate_status"
		catch { exec $exec_cmd -c "touch $SEV(log_dir)/$SEV(task).pass" } dummy
	}
	set upcs  [string map { - _ . _ } [string toupper ddr54_d820-ddr54v2-tsmc5ffp12_rel1.30a_mrvl_sup1]]
	set usite [string toupper $siteid]
	sproc_msg -info "METRIC | INTEGER PCSQA.P4ERRORS.${upcs}_$usite | $p4errors"
	set score [expr $p4errors * 5 ]
	sproc_msg -info "METRIC | INTEGER PCSQA.P4SCORE.${upcs}_$usite | $score"
}


## -----------------------------------------------------------------------------
## End Of File
## -----------------------------------------------------------------------------
