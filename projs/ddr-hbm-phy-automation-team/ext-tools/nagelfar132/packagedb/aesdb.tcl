# This syntax definition is for the aes from tcllib package
# package require aes

set ::syntax(aes::aes) {p* x?}
set ::option(aes::aex)  {-mode -dir -key -iv -hex -out -chunksize}
set ::syntax(aes::Init) 3
set ::syntax(aes::Encrypt) 2
set ::syntax(aes::Decrypt) 2
set ::syntax(aes::Reset) 2
set ::syntax(aes::Final) 1

lappend ::knownPackages aes
