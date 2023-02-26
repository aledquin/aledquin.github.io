# This syntax definition is for the cmdline from tcllib package
# package require cmdline


set ::syntax(cmdline::getopt) {v x n n}
set ::syntax(cmdline::getKnownOpt) {v x n n}
set ::syntax(cmdline::getoptions) {v x x?}
set ::syntax(cmdline::getKnownOptions) {v x x?}
set ::syntax(cmdline::usage) {r 1 2}
set ::syntax(cmdline::getfiles) 2
set ::syntax(cmdline::getArgv0) 0

lappend ::knownPackages cmdline
