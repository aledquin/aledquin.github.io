# This syntax definition is for the http package
# package require http

set ::syntax(http::config) {p*}
set ::option(http::config) {-accept -proxyhost -proxyport -proxyfilter -urlencoding -useragent}
set ::syntax(http::geturl) {x p*}
set ::option(http::geturl) {-binary -blocksize -channel -command -handler -headers -keepalive -method -myaddr -progress -protocol -query -queryblocksize -querychannel -strict -timeout -type -validate}
set ::syntax(http::formatQuery) {r 2}
set ::syntax(http::reset) {r 1 2}
set ::syntax(http::wait) 1
set ::syntax(http::data) 1
set ::syntax(http::error) 1
set ::syntax(http::status) 1
set ::syntax(http::code) 1
set ::syntax(http::ncode) 1
set ::syntax(http::size) 1
set ::syntax(http::meta) 1
set ::syntax(http::cleanup) 1
set ::syntax(http::register) 3
set ::syntax(http::unregister) 1

lappend ::knownPackages http
