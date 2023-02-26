# This syntax definition is for the csv from tcllib package
# package require csv


set ::syntax(json::json2dict) 1
set ::syntax(json::many-json2dict) {x x?}

lappend ::knownPackages json
