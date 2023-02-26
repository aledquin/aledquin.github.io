# Copyright (c) 2004-2014 Synopsys, Inc. This Galaxy Custom Designer software
# and the associated documentation are confidential and proprietary to
# Synopsys, Inc. Your use or disclosure of this Galaxy Custom Designer software
# is subject to the terms and conditions of a written license agreement between
# you, or your company, and Synopsys, Inc.

namespace eval ::amd::amdHelpRoutines {

proc amdHelpDisplayTwiki {twiki} {
    set url "http://mpdwww.amd.com/twiki/bin/view/Cadteam/${twiki}"
    xt::createJob openWebPage -type interactive -cmdLine "htmlview $url" -runDesc "Open Twiki web page"
}

}
