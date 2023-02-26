db::setAttr geometry -of [gi::getFrames 1] -value 1270x800+5+28
gi::setActiveWindow 1
gi::setActiveWindow 1 -raise true
gi::setActiveWindow 0
gi::setActiveWindow 0 -raise true
source $env(UDE_REM_ARGS); if [catch $env(REM_ARGS)] {puts $errorInfo}
gi::setActiveWindow 1
gi::setActiveWindow 1 -raise true
