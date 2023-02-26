# This syntax definition is for the control package from tcllib
# package require control


set ::syntax(control::control) {x x*}
set ::syntax(control::assert) {E x*}
set ::syntax(control::do) {c o? E?}
set ::syntax(control::no-op) {x*}

lappend ::knownPackages control
