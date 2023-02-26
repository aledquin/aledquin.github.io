#!/bin/tcsh -f

set tools = ( ddr-ckt-rel ddr-utils ddr-utils-in08 ddr-utils-timing ddr-utils-lay )
foreach tool ( $tools)
    p4_compare_shelltools_with_gitlab -tool $tool | grep ExtraInP4
end
