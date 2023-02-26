#!/depot/tcl8.6.3/bin/tclsh8.6
#nolint Main
#nolint utils__script_usage_statistics

global env
if {![info exists env(MSIP_CC_VERSION)] && ![info exists env(ICVWB_BIN)]} {
    package provide Misc 1.0
    package require Messaging 1.0
    package require yaml
}

namespace eval Misc {
    # Export commands
    namespace export run_system_cmd get_call_stack \
                     write_file read_file read_file_aref check_file \
                     get_caller_sub_name get_subroutine_name \
                     print_function_footer print_function_header \
                     get_max_val get_min_val prompt_before_continue \
                     checkPinCheckExist \
                     get_username get_release_version get_permission_mode \
                     yml2tcl_import yml2tcl_getvalue
}

# nolint utils__script_usage_statistics

#------------------------------------------------------------
# "run_system_cmd" --> execute a terminal command line
# Use the following line to get the StdOut, StdErr and Status
#>> lassign [run_system_cmd "command"] stdout stderr status
# Can provide verbosity, by default is 0.
#------------------------------------------------------------
proc Misc::run_system_cmd {command {verbosity 0}} {
    
    # Set the default status value. If there is no error, it should remain
    # unchanged.
    set status 0
    set errorList {}
    # Try to execute the command. If it fails, create a list containing all of
    # the error details.
    set stdout ""
    set stderr ""
    # Use a pipe for the stderr so that if the command prints something to the stderr
    # but exists normally, run_system_cmd will return the correct exist status
    lassign [chan pipe] chanout chanin
    lappend command 2>@$chanin
    try {
        set get_call_stack [get_call_stack]
        if { $verbosity >= [[namespace qualifiers [namespace current]]::Messaging::const_to_int LOW] } then { [namespace qualifiers [namespace current]]::Messaging::sysprint "Running system command : '$command' ..." }
        if { $verbosity >= [[namespace qualifiers [namespace current]]::Messaging::const_to_int FUNCTIONS] } then { [namespace qualifiers [namespace current]]::Messaging::sysprint "Subroutine Call Stack: $get_call_stack" }
        # The command should be expanded when it is passed to exec.
        set pipe [open |$command "r"]
        while {[gets $pipe line] >= 0} {
            lappend stdout $line
            if { [[namespace qualifiers [namespace current]]::Messaging::const_to_int $verbosity] >= [[namespace qualifiers [namespace current]]::Messaging::const_to_int MEDIUM] } {
                puts $line
            }
        }
        close $chanin
        set stderr [read $chanout]
        close $pipe
    } on error {result options} {
        [namespace qualifiers [namespace current]]::Messaging::dprint LOW $result
        [namespace qualifiers [namespace current]]::Messaging::eprint $result
        # [namespace qualifiers [namespace current]]::Messaging::eprint $options
        set errInfo [dict get $options -errorinfo]
        set status 1
    } trap NONE errOut {
        # $errOut now holds the message that was written to stderr
        # and everything written to stdout!
        append errorList $errOut
    } trap CHILDKILLED {- opts} {
        lassign [dict get $opts -errorcode] - sigName msg
        # process $pid was killed by signal $sigName; message is $msg
        set status 1
        lappend errorList [list $sigName $msg]
    } trap CHILDSTATUS {- opts} {
        lassign [dict get $opts -errorcode] - code
        # process $pid exited with non-zero exit code $code
        set status 1
        lappend errorList [list $code]
    } trap CHILDSUSP {- opts} {
        lassign [dict get $opts -errorcode] - sigName msg
        # process $pid was suspended by signal $sigName; message is $msg
        set status 1
        lappend errorList [list $sigName $msg]
    } trap POSIX {- opts} {
        lassign [dict get $opts -errorcode] errName msg
        # Some kind of kernel failure; details in $errName and $msg
        set status 1
        lappend errorList [list $errName $msg]
    } 

    # Return a list with the specified order to keep the output format
    # consistant under all circumstances.

    prompt_before_continue [expr {[[namespace qualifiers [namespace current]]::Messaging::const_to_int INSANE] + 100}]

    if {[info exists errInfo] && $stderr == ""} {
        set stderr $errInfo 
    }

    # Make stdout have a better format
    set stdout [join $stdout "\n"]
    return [list $stdout $stderr $status ]
}

#-----------------------------------------------------------------
#  sub 'get_call_stack' => prints out the hierarchy of
#    calling subroutines.
#-----------------------------------------------------------------
proc Misc::get_call_stack {{iframe "0"}} {

    set line_of_procs ""
    for {set i [expr {[info level]-1}]} {$i > $iframe} {incr i -1} {
        set level [info level -$i]
        set frame [info frame -$i]

        if {[dict exists $frame proc]} {
            set pname [dict get $frame proc]
            set pargs [lrange $level 1 end]

            if {$line_of_procs == ""} {
                append line_of_procs "$pname "
            } else {
                append line_of_procs " --> $pname "
            }
                        
            foreach arg $pargs {
                append line_of_procs "   * $arg"
            }


        } else {
            append line_of_procs " - **unknown stack item**: $level $frame"
            break
        }
    }

    return [join $line_of_procs]
}

##------------------------------------------------------------------
##  write to a output file
##
##  Arguments:
##
##      - file_name -> reference to the file path location.
##      - message -> you can refer it between quotes or curve braces
##      - mode: "w" -> you can change it to a+ to get full permisions
##  Examples
##      write_file ~/file.txt $message
##      write_file log.file {You can add text here} a+
##------------------------------------------------------------------

proc Misc::write_file {file_name message args} {
    foreach arg $args {
        if {$arg in [list w w+ r r+ a a+]} {
            set mode $arg
            [namespace qualifiers [namespace current]]::Messaging::viprint 1 "mode --> $mode"
        }    
    }
    if {![info exists mode]} {set mode "w" }
    try {
        set open_file [open $file_name $mode]
        if {"-nonewline" in $args} {
            [namespace qualifiers [namespace current]]::Messaging::viprint 1 "-nonewline option enabled"
            puts -nonewline $open_file $message
        } else { puts $open_file $message }
        close $open_file
        [namespace qualifiers [namespace current]]::Messaging::viprint CRAZY "Writing in $file_name: '$message'"
    } on error {result options} {
        [namespace qualifiers [namespace current]]::Messaging::dprint HIGH "It could not write in $file_name: '$message'"
        [namespace qualifiers [namespace current]]::Messaging::dprint HIGH [dict get $options -errorstack]
    }
}

proc Misc::get_permission_mode {file_to_check} {
    lassign [run_system_cmd "ls -ltr $file_to_check"] line err status
    if { $status == 0 } {
        set dote [lindex [split $line " "] 0]
        [namespace qualifiers [namespace current]]::Messaging::iprint "Permission mode: $dote"
        return $dote
    } else {
        if {![file exists $file_to_check]} {
            [namespace qualifiers [namespace current]]::Messaging::eprint "$file_to_check does not exist."
            return ""
        } else {
            [namespace qualifiers [namespace current]]::Messaging::fprint "This shouldn't happen. \nStdOut --> $line \nStdErr --> $err"
        }
    }
}

##------------------------------------------------------------------
##  read a file and return file array
##------------------------------------------------------------------
proc Misc::read_file {file_to_read { option "" }} {
    if {![file exists $file_to_read]} {
        [namespace qualifiers [namespace current]]::Messaging::eprint "$file_to_read does not exist."
        return 1
    }

    if {![file readable $file_to_read]} {
        [namespace qualifiers [namespace current]]::Messaging::eprint "$file_to_read is not readable."
        get_permission_mode $file_to_read
        [namespace qualifiers [namespace current]]::Messaging::iprint "Please use the next command to fix it: chmod ug+r $file_to_read"
        return 1

    }
    try {
        set fp [open $file_to_read r]
        [namespace qualifiers [namespace current]]::Messaging::dprint INSANE "Reading File: $file_to_read" 
        if {![expr {$option == "" }]} {
            set file_data [read $option $fp]
        } else {
            set file_data [read $fp]
        }
        close $fp
        return $file_data
    } on error {result options} {
        [namespace qualifiers [namespace current]]::Messaging::eprint "It could not read in $file_to_read"
        [namespace qualifiers [namespace current]]::Messaging::eprint [dict get $options -errorstack]
    }
}


##------------------------------------------------------------------
##  Function:
##
##      $status = read_file_aref($inFileName, \@datum, [ $readOptions ] )
##
##  Purpose:
##
##    To read a text file and store it's contents into the supplied array.
##    It will also return the status of the open call.
##
##  Arguments:
##
##      inFileName:
##          The name of the file that you want to read in
##      arefOutput:
##          A reference to an array to store the file contents. One line per
##          array element. Each line is chomped so it does not have a trailing
##          linefeed.
##      readOptions:
##          [optional] For adding special directives to the open command.
##              Example:  ':encoding(UTF-8)'
##  Returns:
##
##      0 : success
##     -1 : failed to open the file; the error message will be placed into
##          the passed in array.
##     -2 : invalid args passed to the function
##
##  Example: 
##
##    my @datum;
##    my $errors = read_file_aref("file.txt", \@datum);
##    foreach my $text ( @datum ) {
##      print("$text\n");
##    }
##------------------------------------------------------------------
proc Misc::read_file_aref {inFileName arefOutput {args}} {
    if {![file exists $inFileName]} {
        [namespace qualifiers [namespace current]]::Messaging::eprint "$inFileName does not exist."
        return 1
    } 
    try {
        set fp [open $inFileName r]
        if {[info exists args]} {
            try {
                set file_data [read $args $fp]
            } on error {res opts} {
                [namespace qualifiers [namespace current]]::Messaging::eprint "The arguments are not correct."
                return -2
            }
            
        } else {
            set file_data [read $fp]
        }
        uplevel #0 "array set $arefOutput [gets $file_data]"
        close $fp
        return 0
    } on error {result options} {
        [namespace qualifiers [namespace current]]::Messaging::eprint "It could not read succesfully in $inFileName"
        [namespace qualifiers [namespace current]]::Messaging::eprint [dict get $options -errorstack]
        return -1
    }
}

##------------------------------------------------------------------
## Function:
#       check_file fileName ?mode?
#   Purpose:
#   
#       Does the checks requried before opening the file. The checks
#       differe depeneding on the mode.
#
#       mode: r
#           Checks that the file exists and is readable.
#       mode: w/a
#           Checks that either the file exists and is writable
#           or that its parent directory exists and is writable.
#
#       returns true on sucess and false otherwise.
##------------------------------------------------------------------
proc Misc::check_file {file_to_check {mode r}} {
    set file_to_check [file normalize $file_to_check]
    if {$mode == "r"} {
        if {![file exists $file_to_check]} {
            [namespace qualifiers [namespace current]]::Messaging::eprint "The file '$file_to_check' does not exist."
            return false
        }

        if {![file readable $file_to_check]} {
            [namespace qualifiers [namespace current]]::Messaging::eprint "The file '$file_to_check' is not readable."
            get_permission_mode $file_to_check
            [namespace qualifiers [namespace current]]::Messaging::wprint "Please use the next command to fix it: chmod ug+r $file_to_check"
            return false
        }
    } elseif {$mode == "w" || $mode == "a"} {
        if {![file exists $file_to_check]} {
            set dir [file dirname $file_to_check]
            if {![file exists $dir]} {
                [namespace qualifiers [namespace current]]::Messaging::eprint "The directory '$dir' does not exist."
                return false
            }
            if {![file writable $dir]} {
                [namespace qualifiers [namespace current]]::Messaging::eprint "The directory '$dir' is not writable."
                return false
            }
        } else {
            if {![file writable $file_to_check]} {
                [namespace qualifiers [namespace current]]::Messaging::eprint "The file '$file_to_check' is not writable."
                return false
            }
        }
    } else {
        [namespace qualifiers [namespace current]]::Messaging::fatal_error "Unkown mode: $mode"
    }
    return true
}


#-----------------------------------------------------------------
#  'get_subroutine_name' => get the proc that 
#                            the one executed it.
#-----------------------------------------------------------------
proc Misc::get_subroutine_name {} {
    try {
        set results [dict get [info frame -1] proc]
    } on error {result options} {
        set results ""
    }
    return $results
}


#-----------------------------------------------------------------
#  'get_caller_sub_name' => get the pevious proc that 
#                            the one executed it.
#-----------------------------------------------------------------
proc Misc::get_caller_sub_name {} {
    try {
        set results [dict get [info frame -2] proc]
    } on error {result options} {
        set results ""
    }
    return $results
}


#-----------------------------------------------------------------
#  sub 'print_function_header'
#-----------------------------------------------------------------
proc Misc::print_function_header {} {
    try {
        set longline [string repeat - 20]
        set title [get_caller_sub_name]
        set init_msg "Starting Function: "
        [namespace qualifiers [namespace current]]::Messaging::dprint FUNCTIONS "$longline $init_msg $title $longline" 3
    } on error {result options} {
        [namespace qualifiers [namespace current]]::Messaging::eprint $result
    }

}

#-----------------------------------------------------------------
#  sub 'print_function_footer'
#-----------------------------------------------------------------
proc Misc::print_function_footer {} {

    try {
        set longline [string repeat - 20]
        set title [get_caller_sub_name]
        set init_msg "Ending Function: "
        [namespace qualifiers [namespace current]]::Messaging::dprint FUNCTIONS "$longline $init_msg $title $longline" 3
    } on error {result options} {
        [namespace qualifiers [namespace current]]::Messaging::eprint $result
    }
}

#------------------------------------------------------------------
# get_min_val : return the smaller of two numbers
#------------------------------------------------------------------
proc Misc::get_min_val {{value_A ""} {value_B ""}} {
    set A_is_empty [expr {$value_A==""}]
    set B_is_empty [expr {$value_B==""}]
    set both_are_empty [expr {$A_is_empty+$B_is_empty==2}]
    set A_is_integer [if {[[namespace qualifiers [namespace current]]::Messaging::isa_integer $value_A]} {list 1} else {list 0}]
    set B_is_integer [if {[[namespace qualifiers [namespace current]]::Messaging::isa_integer $value_B]} {list 1} else {list 0}]
    set both_are_int [expr {$A_is_integer+$B_is_integer==2}]
    try {
        if {$both_are_empty} { 
            [namespace qualifiers [namespace current]]::Messaging::eprint "Both values are not defined"
            return ""
        } elseif {$A_is_empty} { 
            [namespace qualifiers [namespace current]]::Messaging::eprint "The first value is not defined"
            if {$B_is_integer} {
                return $value_B
            } else {
                [namespace qualifiers [namespace current]]::Messaging::eprint "The second value is not an integer."
                return ""
            }
        } elseif {$B_is_empty} { 
            [namespace qualifiers [namespace current]]::Messaging::eprint "The second value is not defined"
            if {$A_is_integer} {
                return $value_A
            } else {
                [namespace qualifiers [namespace current]]::Messaging::eprint "The first value is not an integer."
                return ""
            }
        }
        if {$both_are_int} { 
            if {$value_A > $value_B} {
                return $value_B
            } else {
                return $value_A
            }
        } elseif {$A_is_integer} { 
            [namespace qualifiers [namespace current]]::Messaging::eprint "The second value is not an integer"
            return $value_A
        } elseif {$B_is_integer} { 
            [namespace qualifiers [namespace current]]::Messaging::eprint "The first value is not an integer"
            return $value_B
        } else {
            [namespace qualifiers [namespace current]]::Messaging::fprint 1 "Something is broken."
        }
    } on error {result options} {
        [namespace qualifiers [namespace current]]::Messaging::eprint $result
    }
}


#------------------------------------------------------------------
# get_max_val : return the larger of two numbers
#------------------------------------------------------------------
proc Misc::get_max_val {{value_A ""} {value_B ""}} {
    set A_is_empty [expr {$value_A==""}]
    set B_is_empty [expr {$value_B==""}]
    set both_are_empty [expr {$A_is_empty+$B_is_empty==2}]
    set A_is_integer [if {[[namespace qualifiers [namespace current]]::Messaging::isa_integer $value_A]} {list 1} else {list 0}]
    set B_is_integer [if {[[namespace qualifiers [namespace current]]::Messaging::isa_integer $value_B]} {list 1} else {list 0}]
    set both_are_int [expr {$A_is_integer+$B_is_integer==2}]
    try {
        if {$both_are_empty} { 
            [namespace qualifiers [namespace current]]::Messaging::eprint "Both values are not defined"
            return ""
        } elseif {$A_is_empty} { 
            [namespace qualifiers [namespace current]]::Messaging::eprint "The first value is not defined"
            if {$B_is_integer} {
                return $value_B
            } else {
                [namespace qualifiers [namespace current]]::Messaging::eprint "The second value is not an integer."
            }
        } elseif {$B_is_empty} { 
            [namespace qualifiers [namespace current]]::Messaging::eprint "The second value is not defined"
            if {$A_is_integer} {
                return $value_A
            } else {
                [namespace qualifiers [namespace current]]::Messaging::eprint "The first value is not an integer."
            }
        }
        if {$both_are_int} { 
            if {$value_A < $value_B} {
                return $value_B
            } else {
                return $value_A
            }
        } elseif {$A_is_integer} { 
            [namespace qualifiers [namespace current]]::Messaging::eprint "The second value is not an integer"
            return $value_A
        } elseif {$B_is_integer} { 
            [namespace qualifiers [namespace current]]::Messaging::eprint "The first value is not an integer"
            return $value_B
        } else {
            [namespace qualifiers [namespace current]]::Messaging::fprint 1 "Something is broken."
        }
    } on error {result options} {
        [namespace qualifiers [namespace current]]::Messaging::eprint $result
    }
}

#-----------------------------------------------------------------
# halt execution until user hits enter key
# this enables author/user to hit pause on execution so
# they can examine the user/debug messages (from dprint)
#-----------------------------------------------------------------
proc Misc::prompt_before_continue { haltLevel {line_number ""}} {
    global DEBUG
    global DA_RUNNING_UNIT_TESTS

    set line_msg ""
    if {$DEBUG >= [[namespace qualifiers [namespace current]]::Messaging::const_to_int $haltLevel]} {
        if { [info exists $line_number] && [[namespace qualifiers [namespace current]]::Messaging::isa_integer $line_number]} {
            set line_msg "Line $line_number:"
        }
        get_call_stack

        if { $DEBUG >= [[namespace qualifiers [namespace current]]::Messaging::const_to_int INSANE]} {
            [namespace qualifiers [namespace current]]::Messaging::dprint $DEBUG "Hit enter to continue..."
            flush stdout
            gets stdin
            if {[info exists DA_RUNNING_UNIT_TESTS] && [expr {$DA_RUNNING_UNIT_TESTS == 1}] } {
                return stdin
            }
        }
    }
}


proc Misc::prompt_user_yesno {message {default_value "default"} {limit "3"}} {
    set default_value_toupper [string toupper $default_value]
    switch -- $default_value_toupper {
        Y { set yesno "Yn" }
        N { set yesno "yN" }
        default { set yesno "yn" }
    }

    Messaging::hprint "$message \[$yesno\] > "
    gets stdin answer_user
    if {$answer_user==""} {return $default_value_toupper}
    set answer_user_toupper [string toupper $answer_user]

    set counter "0"
    while { $answer_user_toupper != "Y" && $answer_user_toupper != "N" } {
        Messaging::hprint "$answer_user is not Y or N. Please try again."
        Messaging::hprint "$message \[$yesno\] > "
        unset answer_user
        gets stdin answer_user
        set answer_user_toupper [string toupper $answer_user]
        incr counter
        if {$counter >= $limit} {return "" }
    }

    return $answer_user_toupper
}



#-----------------------------------------------------------------
# 'checkPinCheckExist'
# Function: it gets and checks if pincheck/alphaPinCheck.macro exists.
# Usage: checkPinCheckExist fp arg2 arg3
# Input: fp: <file path>
# Return: TRUE if passing, FALSE if failing or NULL_VAL if problem in setup.
# Outputs: - Error msg for undefined var
#          - Output from the command called
# Example: checkPinCheckExist "depotPath"
#-----------------------------------------------------------------

proc Misc::checkPinCheckExist {depotPath} {

    if {![info exists depotPath]} {
        [namespace qualifiers [namespace current]]::Messaging::dprint HIGH "File path was not defined!\n"
        return NULL_VAL
    }

    if {![regexp {//depot/} $depotPath]} {
        [namespace qualifiers [namespace current]]::Messaging::dprint HIGH "File path does not start with //depot/: $depotPath\n"
        return NULL_VAL
    }

    try {
        
        set p4_files [ exec p4 files -e $depotPath ]

        # lassign [run_system_cmd "p4 files $depotPath"] p4_files stderr status

        if {[llength $p4_files] == 0} {
            [namespace qualifiers [namespace current]]::Messaging::dprint HIGH "P4 files command came back empty: $depotPath\n"
            return NULL_VAL
        }

        foreach file $p4_files {
            # restructure regex so that it looks for pincheck/metalstack/alphaPinCheck
            if {[regexp {pincheck\/[^\/]+\/alphaPinCheck\.\w+} $file]} {
                lassign [run_system_cmd "p4 fstat -Ol -T \"fileSize\" $file"] size
                if {[regexp {fileSize 0} $size]} {
                    regexp {\/\S*/(dwc\S*)/\d\S*macro} $file dir macro
                    set pincheck "$dir/$macro.pincheck"
                    lassign [run_system_cmd "p4 fstat -Ol -T \"fileSize\" $pincheck"] pincheckSize
                    if {[regexp {fileSize 0} $pincheckSize]} {
                        return EMPTY
                    } else {
                        return FALSE
                    }
                } else { 
                    return TRUE 
                }
            }
        }
        return FALSE

    } on error {result options} {
        [namespace qualifiers [namespace current]]::Messaging::dprint HIGH $result
        [namespace qualifiers [namespace current]]::Messaging::dprint HIGH [dict get $options -errorstack]
    }
}
#-----------------------------------------------------------------
# 'get_username'
# Function: return the user name
# Usage: get_username
# Return: username
#-----------------------------------------------------------------
proc Misc::get_username {} {
    global tcl_platform
    return $tcl_platform(user)
}

#-----------------------------------------------------------------
# 'get_release_version'
# Function: return the last release version
# Usage: get_release_version <script_path>
# Input: (optional) scriptBin --> path to where the scripts are located.
# Return: last_version as 2022.10 by default or 0 if it fails or -1 if error.
# Output: Error message if it fails finding the path directory.
#         Error messages if something gets broken.
#-----------------------------------------------------------------
proc Misc::get_release_version {{scriptBin ""}} {
    set tool_release_version "da_get_release_version.pl"
    set version "2022.11"
    global RealBin
    try {
        if {![file isdirectory $scriptBin]} {
            if {[file isdirectory $RealBin]} {
                set scriptBin "$RealBin"
            } else {
                [namespace qualifiers [namespace current]]::Messaging::veprint LOW ".version file is not in the chosen directory."
                return $version
            }
        }
        set tool "$scriptBin/$tool_release_version"
        lassign [run_system_cmd "$tool $scriptBin" ] version sterr status
    } on error {result options} {
        [namespace qualifiers [namespace current]]::Messaging::vwprint LOW "version = $version"
        [namespace qualifiers [namespace current]]::Messaging::vwprint LOW $result
        [namespace qualifiers [namespace current]]::Messaging::vwprint LOW [dict get $options -errorstack]
    } finally {
        return $version
    }
}


#-----------------------------------------------------------------
# 'strip'
# Function: return Returns a value equal to string except that any 
#  leading or trailing characters that occur in chars are removed.
# Usage: strip "message" ?char2rem?
# Return: cleaned_message
#-----------------------------------------------------------------
proc Misc::strip  {message {char2rem ""} } {
    if {$char2rem == ""} {
        return [string trim $message]
    } else {
        return [string trim $message $char2rem]
    }
}





#-----------------------------------------------------------------
# 'yml2tcl'
# Function: set all thw variables from a YML file
# Usage: yml2tcl file_name ?level?
# Return: No Return
#-----------------------------------------------------------------
proc Misc::yml2tcl_import {sample {level 1}} {
    dict for {key value} [yaml::yaml2dict -file $sample] {
        upvar $level $key $key
        if {[array exists value]} {
            array set $name_array $value
        } else {
            set $key $value
        }
    }
    foreach {key value} $releaseMacro {
        set var_name "releaseMacro\{$key\}"
        upvar $level $var_name $var_name
        set $var_name $value
    }
}

proc Misc::get_variables_from_file {__file} {
    source $__file
    unset __file
    return [info locals]
}

proc Misc::yml2tcl_getvalue {sample var_name} {
    dict for {key value} [yaml::yaml2dict -file $sample] {
        if {$key == $var_name} {return $value}
    }
    eprint "The variable $var_name was not found"
    return error
}





# 
# ⠸⣷⣦⠤⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣀⣠⣤⠀⠀⠀
# ⠀⠙⣿⡄⠈⠑⢄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⠔⠊⠉⣿⡿⠁⠀⠀⠀
# ⠀⠀⠈⠣⡀⠀⠀⠑⢄⠀⠀⠀⠀⠀⠀⠀⠀⠀⡠⠊⠁⠀⠀⣰⠟⠀⠀⠀⣀⣀
# ⠀⠀⠀⠀⠈⠢⣄⠀⡈⠒⠊⠉⠁⠀⠈⠉⠑⠚⠀⠀⣀⠔⢊⣠⠤⠒⠊⠉⠀⡜
# ⠀⠀⠀⠀⠀⠀⠀⡽⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠩⡔⠊⠁⠀⠀⠀⠀⠀⠀⠇
# ⠀⠀⠀⠀⠀⠀⠀⡇⢠⡤⢄⠀⠀⠀⠀⠀⡠⢤⣄⠀⡇⠀⠀⠀⠀⠀⠀⠀⢰⠀
# ⠀⠀⠀⠀⠀⠀⢀⠇⠹⠿⠟⠀⠀⠤⠀⠀⠻⠿⠟⠀⣇⠀⠀⡀⠠⠄⠒⠊⠁⠀
# ⠀⠀⠀⠀⠀⠀⢸⣿⣿⡆⠀⠰⠤⠖⠦⠴⠀⢀⣶⣿⣿⠀⠙⢄⠀⠀⠀⠀⠀⠀
# ⠀⠀⠀⠀⠀⠀⠀⢻⣿⠃⠀⠀⠀⠀⠀⠀⠀⠈⠿⡿⠛⢄⠀⠀⠱⣄⠀⠀⠀⠀
# ⠀⠀⠀⠀⠀⠀⠀⢸⠈⠓⠦⠀⣀⣀⣀⠀⡠⠴⠊⠹⡞⣁⠤⠒⠉⠀⠀⠀⠀⠀
# ⠀⠀⠀⠀⠀⠀⣠⠃⠀⠀⠀⠀⡌⠉⠉⡤⠀⠀⠀⠀⢻⠿⠆⠀⠀⠀⠀⠀⠀⠀
# ⠀⠀⠀⠀⠀⠰⠁⡀⠀⠀⠀⠀⢸⠀⢰⠃⠀⠀⠀⢠⠀⢣⠀⠀⠀⠀⠀⠀⠀⠀
# ⠀⠀⠀⢶⣗⠧⡀⢳⠀⠀⠀⠀⢸⣀⣸⠀⠀⠀⢀⡜⠀⣸⢤⣶⠀⠀⠀⠀⠀⠀
# ⠀⠀⠀⠈⠻⣿⣦⣈⣧⡀⠀⠀⢸⣿⣿⠀⠀⢀⣼⡀⣨⣿⡿⠁⠀⠀⠀⠀⠀⠀
# ⠀⠀⠀⠀⠀⠈⠻⠿⠿⠓⠄⠤⠘⠉⠙⠤⢀⠾⠿⣿⠟⠋
# 
