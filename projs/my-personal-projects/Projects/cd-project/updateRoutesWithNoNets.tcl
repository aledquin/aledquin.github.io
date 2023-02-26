namespace eval amd::userTools {

    proc destroyRoutesWithNoNet { design } {
        if { [oa::isSubMaster $design] } return
        if { [oa::isSuperMaster $design] } return
        if { [db::isEmpty [oa::getRoutes [oa::getTopBlock $design]]] } return
        db::eval {
            db::foreach route [oa::getRoutes [oa::getTopBlock $design]] {
                if { [oa::hasNet $route] } continue
                oa::destroy $route
            }
        }
    }

    proc destroyRoutesWithNoNetReopened { design mode } {
        destroyRoutesWithNoNet $design
    }

    db::createCallback destroyRoutesWithNoNetCB \
                       -callbackType onFirstDesignOpened \
                       -procedure [namespace current]::destroyRoutesWithNoNet \
                       -priority 100  \
                       -viewType maskLayout

    db::createCallback destroyRoutesWithNoNetReopenedCB \
                       -callbackType onPostDesignReopened \
                       -procedure [namespace current]::destroyRoutesWithNoNetReopened \
                       -priority 100  \
                       -viewType maskLayout

}
