de::sendMessage "Sourcing [info script]"

namespace eval ::amd {

namespace export *

variable startUpDir [file dirname [info script]]
# Please note dependencies when adding packages. Load more common packages first.
variable packages {amd::snpsutils amd::lsw amd::align amd::autoPin amd::PDKLePwrGridDraw amd::ac amd::HiLayMacroBD amd::reviewDesign amd::dataExport}

    
proc loadPPDKConfFiles {} {
    variable startUpDir
    db::setPrefValue amdPwrGrdCellView -value amd_ginfLib_pPDK/customPGv1/layout
    db::init cdesigner/GVAR_amdEnvVariables_pPDK.tcl
    db::init cdesigner/PdkEnv_amdEnvVariables_pPDK.tcl
    db::init cdesigner/GVAR_amdLayVariables_pPDK.tcl    
    set ::amd::GVAR_amdRevRc(global,projrev) [file join $startUpDir "GVAR_amdLayVariables_pPDK.tcl"]   
    #set ::amd::GVAR_amdEnvVariables(amdAMDLSWUserOwnedCurrentFileName) [file join $startUpDir "GVAR_amdLayVariables_pPDK.tcl"] 
}

proc loadOldTechConfFiles {} {
    variable startUpDir
    db::setPrefValue amdPwrGrdCellView -value amd_ginfLib/customPGv1/layout
    db::init cdesigner/GVAR_amdEnvVariables.tcl
    db::init cdesigner/PdkEnv_amdEnvVariables.tcl
    db::init cdesigner/GVAR_amdLayVariables.tcl
    set ::amd::GVAR_amdRevRc(global,projrev) [file join $startUpDir "GVAR_amdLayVariables.tcl"]  
    #set ::amd::GVAR_amdEnvVariables(amdAMDLSWUserOwnedCurrentFileName) [file join $startUpDir "GVAR_amdLayVariables.tcl"]    
}


proc loadConfFiles {type} {
    switch $type {
        "old" {loadOldTechConfFiles }
        "ppdk" {loadPPDKConfFiles}
    }
}

proc loadPackages {{type "ppdk"}} {
    amd::loadConfFiles $type
    variable packages
    foreach p $packages {
        package forget $p
        package require $p
    }
    ::amd::_lsw::amdLSW_INIT
}

proc getVersion {} {
    return "1.1.1"
}

}

#amd::loadPackages "old"
amd::loadPackages "ppdk"

