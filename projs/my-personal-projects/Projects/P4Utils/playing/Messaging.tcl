


variable args

proc append_message {file message} {
    set open_file [open my.log file]
    puts $open_file "$message"
    close $open_file
}

proc logMsg {fp message} {
    puts $message
    puts $fp $message
}


#-----------------------------------------------------------------
# error print:
# print in red with '-E- ' prefix and log it
#-----------------------------------------------------------------
proc eprint {message} {
    set msg "-E- $message"
    if {[file exist $filename]} {
        append_message $filename $msg
    } 
    puts $msg
}


#-----------------------------------------------------------------
# informational print:
# normal print with '-I- ' prefix and log it
#-----------------------------------------------------------------
proc iprint {message} {
    set msg "-I- $message"
    if {[file exist $filename]} {
        append_message $filename $msg
    } 
    puts $msg
}


#-----------------------------------------------------------------
# warning print:
# print in yellow with '-W- ' prefix and log it
#-----------------------------------------------------------------
proc wprint {message} {
    set msg "-W- $message"
    if {[file exist $filename]} {
        append_message $filename $msg
    } 
    puts $msg
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
proc wprint {message exit_status} {
    set msg "-W- $message"
    if {[file exist $filename]} {
        append_message $filename $msg
    } 
    if {[!info exist $exit_status]}{

    }

    puts $msg
}


