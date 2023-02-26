# Copyright (c) 2004-2014 Synopsys, Inc. This Galaxy Custom Designer software
# and the associated documentation are confidential and proprietary to
# Synopsys, Inc. Your use or disclosure of this Galaxy Custom Designer software
# is subject to the terms and conditions of a written license agreement between
# you, or your company, and Synopsys, Inc.

#puts "XPCdefineVflag.tcl.tcl"
namespace eval ::amd::XPC {

namespace export *

proc XPCdefineVflag {} {
    global pcCellView ; # Where it comes from? Actually it is the cell 
    # where the PCell is instantiated, i.e. flag-rectangle is created
    # Next question, what XPCtstDebugPrintFormalParams procedure does.
    
    set libName "amd_primitives" 
    set cellName "Vflag"
    #set cdfId [cdfGetBaseCellCDF [ddGetObj $libName $cellName ]]
    # Returns the base-level CDF description attached to a cell. If one is not defined, it returns nil.      
    # Lib/Cell/View definition
    set cdfId [cdfGetBaseCellCDF $libName $cellName] ; # The function should be written
    if {$cdfId = ""} {
        de::sendMessage "Create the CDF first for $libName/$cellName\n" -severity error;
    }
    #;;@  Cell Initialization
    puts "Creating PCELL for $libName/$cellName/layout/maskLayout\n"
    
    
    # Procedure XPCpcGetDefaultCDFValue should be written
    set w [XPCpcGetDefaultCDFValue $cdfId "w"]
    set l [XPCpcGetDefaultCDFValue $cdfId "l"]
    set metalLayer [XPCpcGetDefaultCDFValue $cdfId "metalLayer"]
    set metalPurpose[XPCpcGetDefaultCDFValue $cdfId "metalPurpose"]
    set paramsPCell [list $w $l $metalLayer $metalPurpose]
    set lcvList [list $libName $cellName "layout" "maskLayout"]
    
    if {0} {
           XPCtstDebugPrintFormalParams( pcCellView )
    }
    
    set propTable(cvId) $pcCellView
    set    propTable(w) $w
    set    propTable(l) $l 
    set    propTable(metalLayer) $metalLayer 
    set    propTable(metalPurpose) $metalPurpose
    set propLst [array get propTable]
    
    set dbId [ pcDefinePCell $lcvList $paramsPCell $propArr];# The function should be written
    # Inside pcDefinePCell procedure we have call to XPCdrawVflag. XPCdrawVflag $propLst
    de::save $dbId
    
}
if {0} {
#Functions to implement
    cdfGetBaseCellCDF
    pcDefinePCell
    XPCpcGetDefaultCDFValue
    XPCtstDebugPrintFormalParams
}
}

















