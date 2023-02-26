# This syntax definition is for the base64 from tcllib package
# package require base64

set ::syntax(base64::decode) 1
set ::syntax(base64::encode) {p* x}
set ::option(base64::encode) {-maxlen -wrapchar}

lappend ::knownPackages base64
