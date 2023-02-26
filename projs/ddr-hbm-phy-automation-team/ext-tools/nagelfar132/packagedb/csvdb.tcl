# This syntax definition is for the csv from tcllib package
# package require csv


set ::syntax(csv::iscomplete) 1
set ::syntax(csv::join) {r 1 3}
set ::syntax(csv::joinlist) {r 1 3}
set ::syntax(csv::joinmatrix) {r 1 3}
set ::syntax(csv::read2matrix) {o? x x x? x?}
set ::option(csv::read2matrix)  {-alternate}
set ::syntax(csv::read2queue) {o? x x x?}
set ::option(csv::read2queue)  {-alternate}
set ::syntax(csv::report) {r 2 3}
set ::syntax(csv::split) {o? x x? x?}
set ::option(csv::split)  {-alternate}
set ::syntax(csv::split2matrix) {o? x x x? x?}
set ::option(csv::split2matrix)  {-alternate}
set ::syntax(csv::split2queue) {o? x x x? x?}
set ::option(csv::split2queue)  {-alternate}
set ::syntax(csv::writematrix) {r 2 4}
set ::syntax(csv::writequeue) {r 2 4}


lappend ::knownPackages csv
