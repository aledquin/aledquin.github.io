#!/depot/tcl8.6.3/bin/tclsh8.6
#!/depot/tk8.6.1/bin/wish

package require try         ;# Tcllib.
package require cmdline 1.5 ;# First version with proper error-codes.
package require fileutil

set RealBin [file dirname [file normalize [info script]] ]
set RealScript [file tail [file normalize [info script]] ]

# Declare cmdline opt vars here, so they are global
set opt_fast ""
set opt_test ""
set opt_help ""
set opt_project ""

lappend auto_path "$RealBin/../lib/tcl"
set currentDir [pwd]

set DEBUG      0
set VERBOSITY  0
set VERSION    0
set STDOUT_LOG ""
set AUTHOR     "Patrick Juliano"
set PROGRAM_NAME "$RealScript"
set LOGFILENAME "$currentDir/$RealScript.log"

package require Messaging 1.0
package require Misc 1.0
namespace import ::Messaging::*
namespace import ::Misc::*


#-----------------------------------------------------------------------------
proc checkRequiredFile {fileName} {
    if { [file exists $fileName] } {return 1}
    eprint ":  Missing required file:\n\t$fileName"
    return 0
}

#-----------------------------------------------------------------------------
proc processProject {projPath} {

    set projHome "$::env(MSIP_PROJ_ROOT)/$projPath"
    set projEnv  "$projHome/cad/project.env"
    if {![file exists $projEnv]} {
        eprint ":  Project ENV file doesn't exist:  \"$projEnv\" "
        eprint ":  Projects \"$projPath\" does not exist"
        myexit { 1 }
    }

    set t [split $projPath "/"]
    set projectType [lindex $t 0]
    set projectName [lindex $t 1]
    set projectRelease [lindex $t 2]

    set legalRelease "$projHome/design/legalRelease.txt"

    set OK true
    if {![checkRequiredFile $legalRelease]} {set OK false}
    if {!$OK} {
        eprint " Aborting ... can't open file:\n\t$legalRelease"
        myexit { 1 }
    }

    set releaseRoot ""
    source $legalRelease
    if { [info exists p4_release_root] } {
        foreach xx $p4_release_root {lappend releaseRoot "//depot/$xx"}
    }
    if [info exists rel] { set ipReleaseName $rel }
    if [info exists vcrel] {set ipReleaseNameVC $vcrel}
    if [info exists ferel] {set ferelName $ferel}
    if [info exists process] {set processName $process}

    set OK true
    foreach varName {iprojectType projectName projectRelease ipReleaseName ipReleaseNameVC processName releaseRoot } {
        if { ![info exists varName ] } {
            eprint " Variable \"\$$varName\" is undefined!"
            set OK false
        } else {
            dprint 3 "Variable \"\$$varName\" is defined."
        }
    }
    if {!$OK} {
        eprint " Aborting on missing required variable(s)."
        myexit { 1 }
    }

    if { [info exists ferelName] } {
        set root "[lindex $releaseRoot 0]/fe/rel/$ferelName"
    } else {
        set root "[lindex $releaseRoot 0]/fe/rel/$ipReleaseNameVC"
    }

    dprint 2 "MyMain::projectType    = $projectType"
    dprint 2 "MyMain::projectType    = $projectName"
    dprint 2 "MyMain::projectRelease = $projectRelease"
    dprint 2 "MyMain::ipReleaseName  = $ipReleaseName"
    dprint 2 "MyMain::ipReleaseNameVC= $ipReleaseNameVC"
    dprint 2 "MyMain::processName    = $processName"
    dprint 2 "MyMain::releaseRoot    = $releaseRoot"
    dprint 2 "MyMain::root           = $root"

    return "$projectType $projectName $projectRelease $ipReleaseName $ipReleaseNameVC $processName {$releaseRoot} $root"
}

#-----------------------------------------------------------------------------
#
#-----------------------------------------------------------------------------
proc get_depot_filelist {root} {

    iprint "Exporting from Perforce depot: $root/..."
    set p4fileslog [exec p4 files -e $root/...]
    viprint 3 $p4fileslog

    return $p4fileslog
}

#-----------------------------------------------------------------------------
# Find the most recent changelist number for all RTL files in the //depot
#-----------------------------------------------------------------------------
proc get_max_changelist_number {p4fileslog} {

    set err 0
    foreach f [split $p4fileslog "\n"] {
        #puts "\"$f\""
        #Example: //depot/products/.../verilog/std_primitives.v#1 - add change 10257259 (text)
        if {[regexp {^(\S+)#(\d+)\D+(\d+)\s} $f dummy depotFile ver changelist ]} {
            set changelists($changelist) 1
            lappend p4fileList $depotFile
        } else {
            eprint ":  Failed to match '$f'"
            set err 1
        }

        set maxCL 0
        foreach cl [array names changelists] {
            if {$cl > $maxCL} {set maxCL $cl}
        }
    }

    viprint 1 "Changelists: [array names changelists], using $maxCL"
    if $err { myexit { 1 } }

    lappend p4fileList  $maxCL
    return $p4fileList
}

# -----------------------------------------------------------------------------
#  change RTL dir based whether we are running this script during
#      functional testing or in production.
#-----------------------------------------------------------------------------
proc adjust_rtldir_path {rtlDir opt_test maxCL} {

    if { $opt_test } {
        # for functional testing because we can't touch
        # project execution directories during testing
        append rtlDir "test-rtl"
    } else {
        # default
        append rtlDir "rtl"
    }

    if { ![file writable $rtlDir] } {
        eprint " RTL directory is not writeable: $rtlDir "
        myexit { 1 }
    }
    append rtlDir "/cl$maxCL"

    viprint 1 "Directory for RTL export:\n\t$rtlDir"

    return $rtlDir
}

# -----------------------------------------------------------------------------
#   Check RTL directory exists, and remove all existing files so
#       no legacy files are there before we start the export process
# -----------------------------------------------------------------------------
proc cleanup_rtl_dir { rtlDir opt_fast } {

    if { [file exists $rtlDir] } {
        wprint "RTL directory exists, flushing: $rtlDir"
        set files [glob -nocomplain "$rtlDir/*"]
        foreach f $files {
            viprint 3 " Deleting existing RTL file: '$f'"
            if {! $opt_fast } { file delete -force $f }
        }
    } else {
        file mkdir $rtlDir
    }

    return true
}


# -----------------------------------------------------------------------------
#  MAIN - pseudocode
#  1. get list of RTL files in perforce //depot
#  2. determine the latest changelist
#  3. clean-out the disk path where RTL is being exported: /remote/cad-rep/...
#  4. Export files from P4 to disk
#  5. setup sym-link based on rel ver (from legalRelease.txt)
#-----------------------------------------------------------------------------
proc Main {opt_project opt_test opt_fast} {
    lassign [processProject $opt_project] projectType projectName projectRelease ipReleaseName ipReleaseNameVC processName releaseRoot root

    ##  Check the required variables
    set OK true
    set home [pwd]

    set p4fileslog [get_depot_filelist $root]
    set p4fileList [get_max_changelist_number $p4fileslog ]

    isa_list { $p4fileList }
    set maxCL [ lindex $p4fileList end ]
    # remove maxCL from the list
    set p4fileList [ lreplace $p4fileList end end  ]
    #puts "$p4fileList"

    # define path where RTL will be exported
    set rtlDir "$::env(MSIP_PROJ_ROOT)/$projectType/$projectName/$projectRelease/design/"
    set rtlDir [ adjust_rtldir_path $rtlDir $opt_test $maxCL ]

    # -----------------------------------------------------------------------------
    #  Remove all files before export
    # -----------------------------------------------------------------------------
    cleanup_rtl_dir $rtlDir $opt_fast

    # -----------------------------------------------------------------------------
    #  Export from Perforce to RTL directory
    # -----------------------------------------------------------------------------
    iprint "Exporting rtl from:\n\t $root -->\n\t $rtlDir"
    set n 0
    foreach p4f $p4fileList {
        set t [split $p4f "/"]
        set fileName "$rtlDir/[lindex $t end]"
        prompt_before_continue 5
        if { !$opt_fast } { exec p4 print -o $fileName $p4f }
        if {! [file exists $fileName] } { wprint "File doesn't exist (not exported from Perforce properly): $fileName" }
        incr n
    }
    iprint "Total # files exported: '$n'"

    #-------------------------------------------------------------------------
    # Setup symoblic link using release name -> dirname based on changelist
    #-------------------------------------------------------------------------
    cd $rtlDir
    cd ..
    # remove existing sym-link with same name
    if [file exists $ipReleaseName] {file delete $ipReleaseName}
    # create sym-link
    file link -symbolic $ipReleaseName cl$maxCL
    iprint "Creating symbolic link: $ipReleaseName -> cl$maxCL \n\t...in directory $rtlDir/.."
    cd $home

    return 0
}
# End Main

#-----------------------------------------------------------------------------
proc showUsage {} {
    set msg "\nUsage:  alphaHLDepotExportRtl.tcl -p <projSPEC>"
    append msg "\n\t\t where projSPEC => \"productName/projectName/projectRelease\""
    append msg "\n\t Example command lines:\n"
    append msg "\t\t  alphaHLDepotExportRtl.tcl -p lpddr4xm/d551-lpddr4xm-tsmc16ffc18/rel1.00 \n"
    append msg "\t\t  alphaHLDepotExportRtl.tcl -p lpddr4xm/d551-lpddr4xm-tsmc16ffc18/rel1.00 -t \n"
    append msg "\t\t  alphaHLDepotExportRtl.tcl -p lpddr5x/d931-lpddr5x-tsmc3eff-12/rel1.00_cktpcs \n"
    append msg "\n\t Valid command line options:\n"
    append msg "\t     -p projSPEC : specifies the product/project/release triplet\n"
    append msg "\t     -d #        : verbosity of debug messaging\n"
    append msg "\t     -v #        : verbosity of user messaging\n"
    append msg "\t     -t          : use functional testing setup\n"
    append msg "\t     -f          : fast execution (skip pre-clean of RTL area & export from Perforce)\n"
    puts $msg
    return $msg
}


#-----------------------------------------------------------------
# process command line options...must have the variables
#    declared globally and set their value in this proc
#-----------------------------------------------------------------
proc process_cmdline {} {
    set parameters {
        {p.arg  "none" "product/project/release"}
        {v.arg  "0"    "verbosity"}
        {d.arg  "0"    "debug"}
        {f             "run fast (skip delete, p4 print" }
        {t             "functional testing mode"}
        {h             "help message"}
    }
    set usage {showUsage}
    try {
        array set options [::cmdline::getoptions ::argv $parameters $usage ]
    } trap {CMDLINE USAGE} {msg o} {
        # Trap the usage signal, print the message, and exit the application.
        # Note: Other errors are not caught and passed through to higher levels!
        eprint "Invalid Command line options provided!"
        showUsage
        myexit { 1 }
    }

    global VERBOSITY
    global DEBUG
    global opt_project
    global opt_fast
    global opt_test
    global opt_help

    set VERBOSITY   $options(v)
    set DEBUG       $options(d)
    set opt_test    $options(t)
    set opt_fast    $options(f)
    set opt_help    $options(h)
    set opt_project $options(p)

    dprint LOW "debug value     : $DEBUG"
    dprint LOW "verbosity value : $VERBOSITY"
    dprint LOW "project value   : $opt_project"
    dprint LOW "test value      : $opt_test"
    dprint LOW "fast value      : $opt_fast"
    dprint LOW "help value      : $opt_help"

    prompt_before_continue SUPER

    if { $opt_help } {
        showUsage
        myexit 0
    }

    if { $opt_project == "none" } {
        showUsage
        myexit 1
    }

    if { $opt_test } {
        wprint " Running functional test ... RTL export directory changed"
    }
}


#-----------------------------------------------------------------------------
#  call procedure:  Main
#-----------------------------------------------------------------------------

if {![info exists ::DDR_DA_UNIT_TEST]} {
    try {
        header
        process_cmdline
        set exitval [Main $opt_project $opt_test $opt_fast]
    } on error {results options} {
        set exitval [fatal_error [dict get $options -errorinfo]]
    } finally {
        write_stdout_log "$LOGFILENAME"
    }
    myexit $exitval
} else { puts $::DDR_DA_UNIT_TEST }







####################################
## No Linting Area
####################################

# nolint Line  78: N Suspicious variable name
# 11-07-2022: monitor usage is in header now
# nolint utils__script_usage_statistics
