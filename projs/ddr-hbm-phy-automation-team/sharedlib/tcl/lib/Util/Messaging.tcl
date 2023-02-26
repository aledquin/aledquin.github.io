#!/depot/tcl8.5.12/bin/tclsh8.5
#nolint Main
#nolint utils__script_usage_statistics

global env
if {![info exists env(MSIP_CC_VERSION)] && ![info exists env(ICVWB_BIN)]} {
    package provide Messaging 1.0
    package require Misc 1.0
}

namespace eval Messaging {
    # Export commands
    namespace export write_stdout_log header footer     \
        eprint iprint hprint wprint fatal_error fprint \
        dprint viprint vwprint veprint nprint sysprint \
        isa_boolean isa_string isa_list    \
        isa_integer                        \
        myexit const_to_int                \
        utils__script_usage_statistics *
}

# nolint utils__script_usage_statistics

#-----------------------------------------------------------------
#
#-----------------------------------------------------------------
proc Messaging::utils__script_usage_statistics {toolname version {arg_cmd_line ""}} {

    global RealBin
    set prefix "ddr-da-"
    set reporter "/remote/cad-rep/msip/tools/bin/msip_get_usage_info"
    set cmd ""
    set script_dirname [file dirname [file normalize [info script]]]
    append cmd "$reporter --tool_name  \"${prefix}${toolname}\" "
    append cmd "--stage main --category ude_ext_1 "
    append cmd "--tool_path \"$RealBin\" --tool_version \"$version\" "

    if { $arg_cmd_line != "" } {
        global argv
        set arg_cmd_line $argv
        append cmd "--command \"$arg_cmd_line\" "
    }
    [namespace qualifiers [namespace current]]::Misc::run_system_cmd $cmd
}

#-----------------------------------------------------------------
# user should never just exit
# they should set the value and print the footer
#-----------------------------------------------------------------
proc Messaging::myexit {exitval} {
    global DEBUG
    try {
        if {[info exists ::DA_RUNNING_UNIT_TESTS]} {
            dprint CRAZY "myexit was interrupted by Test Mode."
        } else {
            exit $exitval
        }
    } on error {result options} {
        eprint $result
        exit 1
    }
}

#-----------------------------------------------------------------------------
# check if the var is a #####
#-----------------------------------------------------------------------------
proc Messaging::isa_boolean {foo} {
    if {[string is boolean -strict $foo]} {
        dprint CRAZY "foo is an integer!"
        return true
    }
    return false
}

proc Messaging::isa_string {foo} {
    if {[info exists $foo]} {
        dprint CRAZY "foo is an integer!"
        return true
    }
    return false
}

proc Messaging::isa_integer {foo} {
    if {[string is integer -strict $foo]} {
        return true
    }
    return false
}

proc Messaging::isa_list {foo} {
    if {[string is list $foo]} {
        dprint CRAZY "foo is a list! (length: [llength $foo])"
        return true
    }
    return false
}

proc Messaging::isa_aref {foo} {
    if {[array exists foo]} {
        dprint CRAZY "foo is an array! (length: [llength $foo])"
        return true
    }
    return false
}

#-----------------------------------------------------------------------------
# Write all the user messages to a log file
#-----------------------------------------------------------------------------
proc Messaging::write_stdout_log {file_name} {
    global STDOUT_LOG
    try {
        if {[info exists STDOUT_LOG]} {
            iprint "Writing log file: '$file_name'"
            [namespace qualifiers [namespace current]]::Misc::write_file $file_name $STDOUT_LOG
        }
    } on error {- -} {

    }
}

#-----------------------------------------------------------------------------
proc Messaging::logger {message} {
    global STDOUT_LOG
    if {[info exists STDOUT_LOG]} {
        append STDOUT_LOG "$message \n"
    }
}

#-----------------------------------------------------------------------------
# Time formatter ( takes seconds, outputs HH:MM:SS )
#-----------------------------------------------------------------------------
proc Messaging::time_formatter {input} {
    set seconds [expr {  $input % 60  }]
    set minutes [expr { ($input / 60) % 60  }]
    set hours   [expr {  $input /3600 }]
    return [format "%02d:%02d:%02d" $hours $minutes $seconds]
}

#-----------------------------------------------------------------------------
#  proc header
#-----------------------------------------------------------------------------
proc Messaging::header { } {

    uplevel #0 { set START_TIME [clock seconds] }
    uplevel #0 { set VERSION [[namespace qualifiers [namespace current]]::Misc::get_release_version] }

    global AUTHOR
    global START_TIME
    global RealBin
    global RealScript
    global VERSION
    global argv

    set cmd_argv ""
    if {[info exists argv]} {
        set cmd_argv [join $argv " "]
    }

    set START_TIME_format [clock format $START_TIME]
    Messaging::utils__script_usage_statistics $RealScript $VERSION

    nprint "\n\n#######################################################"
    nprint "###  Date , Time     : $START_TIME_format"
    nprint "###  Script Name     : $RealScript"
    nprint "###  Command         : $RealBin/$RealScript $cmd_argv"
    nprint "###  Author          : $AUTHOR"
    nprint "###  Release Version : $VERSION"
    nprint "###  User            : [[namespace qualifiers [namespace current]]::Misc::get_username]"
    nprint "#######################################################\n"
}

#-----------------------------------------------------------------------------
#  proc footer
#-----------------------------------------------------------------------------
proc Messaging::footer { } {

    global AUTHOR
    global VERSION
    global RealBin
    global RealScript
    global START_TIME

    set END_TIME [clock seconds]
    set RUNTIME [expr {$END_TIME - $START_TIME}]

    set START_TIME_format [clock format $START_TIME]
    set END_TIME_format [clock format $END_TIME]
    set RUNTIME_format [time_formatter $RUNTIME]

    nprint "\n\n#######################################################"
    nprint "###  Goodbye World"
    nprint "###  Date, Time (START): $START_TIME_format"
    nprint "###  Date, Time (END)  : $END_TIME_format"
    nprint "###  Runtime           : $RUNTIME_format"
    nprint "###  Script Name       : $RealScript"
    nprint "###  Script Path       : $RealBin"
    nprint "###  Author            : $AUTHOR"
    nprint "###  Release Version   : $VERSION"
    nprint "#######################################################\n"
}

#-----------------------------------------------------------------
# Add timestamp
# Adds timestamp to thee message if the global variable TIMESTAMP
# exists.
#-----------------------------------------------------------------
proc Messaging::add_timestamp {message} {
    global TIMESTAMP
    if {[info exists TIMESTAMP]} {
        set message "\[[clock format [clock seconds]]\] $message"
    }
    return $message
}

#-----------------------------------------------------------------
# get_msg_line
#
#-----------------------------------------------------------------
proc Messaging::get_msg_line {message {iframe "2"}} {
    global DEBUG
    if {![info exists DEBUG]} {
        return "$message"
    }
    if {$DEBUG >= [const_to_int CRAZY]} {
        set line_number [lindex [info frame [expr {[info level]-$iframe}]] 3]
        set call_stack [get_call_stack $iframe]
        return "Line $line_number: $call_stack: $message"
    } else {
        return "$message"
    }
}

#-----------------------------------------------------------------
# informational print:
# normal print with '-I- ' prefix and log it
#-----------------------------------------------------------------
proc Messaging::iprint {message} {
    global env
    set message [get_msg_line $message]
    if {[info exists env(MSIP_CC_VERSION)]} {
        de::sendMessage $message -severity "information"
        set msg [add_timestamp "-I- $message"]
    } else {
        set msg [add_timestamp "-I- $message"]
        colored $msg "normal"
    }
    Messaging::logger $msg
}

#-----------------------------------------------------------------
# warning print:
# print in yellow with '-W- ' prefix and log it
#-----------------------------------------------------------------
proc Messaging::wprint {message} {
    global env
    set message [get_msg_line $message]
    if {[info exists env(MSIP_CC_VERSION)]} {
        de::sendMessage $message -severity "warning"
        set msg [add_timestamp "-W- $message"]
    } else {
        set msg [add_timestamp "-W- $message"]
        colored $msg "yellow"
    }
    Messaging::logger $msg
}

#-----------------------------------------------------------------
# error print:
# print in red with '-E- ' prefix and log it
#-----------------------------------------------------------------
proc Messaging::eprint {message} {
    global env
    set message [get_msg_line $message]
    if {[info exists env(MSIP_CC_VERSION)]} {
        de::sendMessage $message -severity "error"
        set msg [add_timestamp "-E- $message"]
    } else {
        set msg [add_timestamp "-E- $message"]
        colored $msg "red"
    }
    Messaging::logger $msg
}

#-----------------------------------------------------------------
# fatal_error:
# print in red on white with '-F- ' prefix and log it. Terminate afterwards
# unless FPRINT_NOEXIT is set to 1
#
# Takes 1 required argument and one optional argument.
#
# Required: message string
# Optional: status value to use in exit() call
#
#-----------------------------------------------------------------
proc Messaging::fatal_error {message} {
    global exit_status env
    set message [get_msg_line $message]
    if {[info exists env(MSIP_CC_VERSION)]} {
        de::sendMessage $message -severity "error"
        set msg [add_timestamp "-F- $message"]
        Messaging::logger $msg
        if {[info exists exit_status]} {
            set local_exit_status $exit_status
        } else {
            set local_exit_status 1
        }
        # Return to the first Main proc call in the stack.
        for {set i [expr {[info level]-1}]} {$i >= 0} {incr i -1} {
            set level [info level $i]
            if {[regexp {.*_Main} $level]} {
                return -level [expr {[info level] -$i}] $local_exit_status
            }
        }
        error "Unable to get the level for 'main'"
    } else {
        set msg [add_timestamp "-F- $message"]
        Messaging::logger $msg
        colored $msg "white_on_red"
        if {[info exists exit_status]} {
            return -level [info level] $exit_status
        } else {
            return -level [info level] 1
        }
    }
}


#-----------------------------------------------------------------
# fatal print:
# print in red on white with '-F- ' prefix and log it. Terminate afterwards
# unless FPRINT_NOEXIT is set to 1
#
# Takes 1 required argument and one optional argument.
#
# Required: message string
# Optional: status value to use in exit() call
#
#-----------------------------------------------------------------
proc Messaging::fprint {message} {
    global exit_status env
    set message [get_msg_line $message]
    if {[info exists env(MSIP_CC_VERSION)]} {
        de::sendMessage $message -severity "error"
        set msg [add_timestamp "-F- $message"]
        Messaging::logger $msg
        if {[info exists exit_status]} {
            set local_exit_status $exit_status
        } else {
            set local_exit_status 1
        }
        # Return to the first Main proc call in the stack.
        for {set i [expr {[info level]-1}]} {$i >= 0} {incr i -1} {
            set level [info level $i]
            if {[regexp {.*_Main} $level]} {
                return -level [expr {[info level] -$i}] $local_exit_status
            }
        }
        error "Unable to get the level for 'main'"
    } else {
        set msg [add_timestamp "-F- $message"]
        Messaging::logger $msg
        colored $msg "white_on_red"
        if {[info exists exit_status]} {
            return -level [info level] $exit_status
        } else {
            return -level [info level] 1
        }
    }
}

#-----------------------------------------------------------------
# debug informational print:
# if the DEBUG variable is >= to the first argument,
# prefix message with '-D', and log it
#-----------------------------------------------------------------
proc Messaging::dprint {threshold message {iframe "2"}} {
    global DEBUG env
    if {![info exists DEBUG] || ![isa_integer $DEBUG]} {return ""}
    set message [get_msg_line "$message" $iframe]
    if {$DEBUG >= [const_to_int $threshold]} {
        if {[info exists env(MSIP_CC_VERSION)]} {
            puts "-D- $message"
            set msg [add_timestamp "-D- $message"]
        } else {
            set msg [add_timestamp "-D- $message"]
            colored $msg "blue"
        }
        Messaging::logger $msg
    }
}

#-----------------------------------------------------------------
# verbosity informational print:
# if the VERBOSITY is equal to or higher than the first argument, normal print
# with '-I- ' prefix and log it
#-----------------------------------------------------------------
proc Messaging::viprint {threshold message} {
    global VERBOSITY
    if {![info exists VERBOSITY]} {return ""}
    if {$VERBOSITY >= [const_to_int $threshold]} {
        iprint $message
    }
}

#-----------------------------------------------------------------
# verbosity warning print:
# if the VERBOSITY is equal to or higher than the first argument, print in yellow
# with '-W- ' prefix and log it
#-----------------------------------------------------------------
proc Messaging::vwprint {threshold message} {
    global VERBOSITY
    if {![info exists VERBOSITY]} {return ""}
    if {$VERBOSITY >= [const_to_int $threshold]} {
        wprint $message
    }
}

#-----------------------------------------------------------------
# verbosity error print:
# if the VERBOSITY is equal to or higher than the first argument, print in red
# with '-E- ' prefix and log it
#-----------------------------------------------------------------
proc Messaging::veprint {threshold message} {
    global VERBOSITY
    if {![info exists VERBOSITY]} {return ""}
    if {$VERBOSITY >= [const_to_int $threshold]} {
        eprint $message
    }
}
#-----------------------------------------------------------------
# normal print:
# print normally with no prefix
#-----------------------------------------------------------------
proc Messaging::nprint {message} {
    global env
    set message [get_msg_line $message]
    set msg "$message"
    Messaging::logger $msg
    if {[info exists env(MSIP_CC_VERSION)]} {
        puts $msg
    } else {
        colored $msg "normal"
    }
}

#-----------------------------------------------------------------
# highlight print:
# print in cyan with '-I- ' prefix and log it
#-----------------------------------------------------------------
proc Messaging::hprint {message} {
    global env
    set message [get_msg_line $message]
    set msg [add_timestamp "-I- $message"]
    Messaging::logger $msg
    if {[info exists env(MSIP_CC_VERSION)]} {
        iprint $msg
    } else {
        colored $msg "cyan"
    }
}

#-----------------------------------------------------------------
# verbosity highlight print:
# if the VERBOSITY is equal to or higher than the first argument, print in cyan
# with '-I- ' prefix and log it
#-----------------------------------------------------------------
proc Messaging::vhprint {threshold message} {
    global VERBOSITY
    if {![info exists VERBOSITY]} {return ""}
    if {$VERBOSITY >= [const_to_int $threshold]} {
        hprint $message
    }
}

#-----------------------------------------------------------------
# p4 print:
# print in green with no prefix
#-----------------------------------------------------------------
proc Messaging::p4print {message} {
    global env
    set message [get_msg_line $message]
    set msg "$message"
    Messaging::logger $msg
    if {[info exists env(MSIP_CC_VERSION)]} {
        iprint $msg
    } else {
        colored $msg "green"
    }
}

#-----------------------------------------------------------------
# system call print:
# normal print with '-S- ' prefix and log it
#-----------------------------------------------------------------
proc Messaging::sysprint {message} {
    global env
    set message [get_msg_line $message]
    set msg [add_timestamp "-S- $message"]
    Messaging::logger $msg
    if {[info exists env(MSIP_CC_VERSION)]} {
        iprint $msg
    } else {
        colored $msg "magenta"
    }
}

#-----------------------------------------------------------------
# Add color to messages
#-----------------------------------------------------------------
proc Messaging::colored {message color} {
    switch $color {
        "red"    {set color_code "1;31m"}
        "green"  {set color_code "1;32m"}
        "yellow" {set color_code "1;33m"}
        "blue"   {set color_code "1;34m"}
        "magenta" {set color_code "1;35m"}
        "cyan"  {set color_code "1;36m"}
        "white_on_red" {set color_code "37;41m"}
        default  {set color_code "1m"}
    }
    set unit_test_mode_exist [info exists ::DA_RUNNING_UNIT_TESTS]
    if { $unit_test_mode_exist } {
        puts "$message"
    } else {
        puts "\033\[$color_code$message\033\[0m"
    }
}

#-----------------------------------------------------------------
# Constant to integer:
# transform constants to integers for DEEUG/VERBOSITY, if the
# variable is already an integer, return it as it is.
#-----------------------------------------------------------------
proc Messaging::const_to_int {var} {
    if {[string is integer $var]} {
        return $var
    }
    switch -- $var {
        NONE      { return 0 }
        LOW       { return 1 }
        MEDIUM    { return 2 }
        FUNCTIONS { return 3 }
        HIGH      { return 4 }
        SUPER     { return 5 }
        CRAZY     { return 6 }
        INSANE    { return 100 }
        EMPTY_STR { return ""}
        default {
            error "Unknown constant: $var"
        }
    }
}


# ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠿⠿⠿⠿⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
# ⣿⣿⣿⣿⣿⣿⣿⣿⠟⠋⠁⠀⠀⠀⠀⠀⠀⠀⠀⠉⠻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
# ⣿⣿⣿⣿⣿⣿⣿⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢺⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
# ⣿⣿⣿⣿⣿⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠆⠜⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
# ⣿⣿⣿⣿⠿⠿⠛⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⠻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
# ⣿⣿⡏⠁⠀⠀⠀⠀⠀⣀⣠⣤⣤⣶⣶⣶⣶⣶⣦⣤⡄⠀⠀⠀⠀⢀⣴⣿⣿⣿⣿⣿You know what to do ⣿⣿⣿⣿
# ⣿⣿⣷⣄⠀⠀⠀⢠⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⢿⡧⠇⢀⣤⣶⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
# ⣿⣿⣿⣿⣿⣿⣾⣮⣭⣿⡻⣽⣒⠀⣤⣜⣭⠐⢐⣒⠢⢰⢸⣿⣿⣿⣿⣿⣿⣿⣿⣿
# ⣿⣿⣿⣿⣿⣿⣿⣏⣿⣿⣿⣿⣿⣿⡟⣾⣿⠂⢈⢿⣷⣞⣸⣿⣿⣿⣿⣿⣿⣿⣿⣿
# ⣿⣿⣿⣿⣿⣿⣿⣿⣽⣿⣿⣷⣶⣾⡿⠿⣿⠗⠈⢻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
# ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠻⠋⠉⠑⠀⠀⢘⢻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
# ⣿⣿⣿⣿⣿⣿⣿⡿⠟⢹⣿⣿⡇⢀⣶⣶⠴⠶⠀⠀⢽⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
# ⣿⣿⣿⣿⣿⣿⡿⠀⠀⢸⣿⣿⠀⠀⠣⠀⠀⠀⠀⠀⡟⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
# ⣿⣿⣿⡿⠟⠋⠀⠀⠀⠀⠹⣿⣧⣀⠀⠀⠀⠀⡀⣴⠁⢘⡙⢿⣿⣿⣿⣿⣿⣿⣿⣿
# ⠉⠉⠁⠀⠀⠀⠀⠀⠀⠀⠀⠈⠙⢿⠗⠂⠄⠀⣴⡟⠀⠀⡃⠀⠉⠉⠟⡿⣿⣿⣿⣿
# ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢷⠾⠛⠂⢹⠀⠀⠀⢡⠀⠀⠀⠀⠀⠙⠛⠿⢿


# nolint Line 168: N Suspicious brackets around command
