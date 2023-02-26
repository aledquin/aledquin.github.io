namespace eval ::amd {

namespace export *

variable GVAR_amdEnvVariables
array set GVAR_amdEnvVariables {}

set GVAR_amdEnvVariables(amdInterpreterLayerAbbrevLay) {drw drawing pin pin1}
set GVAR_amdEnvVariables(amdTechLibName) amd_gf14lpe_tech
set GVAR_amdEnvVariables(layout,labelHeight) "0.05"
set GVAR_amdEnvVariables(layout,labelFontStyle) "euroStyle"
set GVAR_amdEnvVariables(layout,labelJustify) "centerCenter"
set GVAR_amdEnvVariables(layout,labelDrafting) "true"
set GVAR_amdEnvVariables(layout,labelOverbar) "false"
set GVAR_amdEnvVariables(layout,pinTextPurpose) "pin"

}
