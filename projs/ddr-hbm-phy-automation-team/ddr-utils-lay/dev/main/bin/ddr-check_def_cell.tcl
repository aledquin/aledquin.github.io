#!/depot/tcl8.6.6/bin/tclsh

proc check_def_cell { libName defcell } {

     set design [ed]    

     puts "" 
     puts "checking cell :  [db::getAttr libName -of $design]/[db::getAttr cellName -of $design]/[db::getAttr viewName -of $design]"
     puts "reference cell:  $libName/$defcell/layout"
     puts ""
     puts ""
     
     # check to see if view exists... if not exit
     if {![oa::DesignExists $libName $defcell layout]} { 
        puts "$libName/$defcell does not exist... please check"
        return -1
     } 
        
     

     set cellview [dm::getCellViews layout -libName $libName -cellName $defcell ]
     set cxt [de::open $cellview -headless true -readOnly true]
     set defDesign [db::getAttr cxt.editDesign]

     ## lets check the prBoundary between two cells
     set def_pr [DDR::getPrBoundary $defDesign]
     set pr [DDR::getPrBoundary $design]

     if { $def_pr != -1 && $pr != -1 } { 
        set def_bbox [de::getBBox $def_pr]
        set bbox [de::getBBox $pr]
        set lx [DDR::leftEdge $bbox]
        set ux [DDR::rightEdge $bbox]
        set ly [DDR::bottomEdge $bbox]
        set uy [DDR::topEdge $bbox]
        set dlx [DDR::leftEdge $def_bbox]
        set dux [DDR::rightEdge $def_bbox]
        set dly [DDR::bottomEdge $def_bbox]
        set duy [DDR::topEdge $def_bbox]

 
        puts "DEF pr_boundary is:  $dlx,$dly   $dux,$duy"
        if { $lx == $dlx && $ly == $dly && $ux == $dux && $uy == $duy } {
           puts "CELL pr_boundary matches ...."
        } else {
           puts "*** CELL pr_boundary DOESN'T MATCH:  $lx,$ly  $ux,$uy" 
        }
     } else {
       if { $def_pr == -1 } { puts "DEF pr_boundary missing!" }
       if { $pr == -1 } { puts "CURRENT cell pr_boundary missing!" }
       return -1 
     }

     set dinsts [db::getInsts -of $defDesign]
     set insts [db::getInsts -of $design]

     set dcount [db::getCount $dinsts]
     set count [db::getCount $insts]

     if { $dcount != $count } { 
        puts ""
        puts "** INSTANCE count doesn't match between DEF reference and CELL"
        puts ""
        puts "DEF instances ($dcount) (lib ts05n* filtered from results) "
        db::foreach inst $dinsts {
            set name [db::getAttr inst.name]
            set cell [db::getAttr inst.cellName]
            set view [db::getAttr inst.viewName]
            set lib  [db::getAttr inst.libName]
            set orient [db::getAttr inst.orientation]
            set origin [db::getAttr inst.origin]
             
            if { ! [string match *ts05n* $lib] }  { 
               puts "DEF cell: $name  $origin  $orient   $lib/$cell/$view"
            }
        }

        puts ""
        puts "CUR cell instances ($count): "
        db::foreach inst $insts {
            set name [db::getAttr inst.name]
            set cell [db::getAttr inst.cellName]
            set view [db::getAttr inst.viewName]
            set lib  [db::getAttr inst.libName]
            set orient [db::getAttr inst.orientation]
            set origin [db::getAttr inst.origin]
            puts "CUR cell: $name  $origin  $orient   $lib/$cell/$view"
        }
        puts ""
     }

     ## check instances:
     db::foreach dinst $dinsts  { 
         set dname [db::getAttr dinst.name]
         set dcell [db::getAttr dinst.cellName]
         set dview [db::getAttr dinst.viewName]
         set dlib  [db::getAttr dinst.libName]
         set dorient [db::getAttr dinst.orientation]
         set dorigin [db::getAttr dinst.origin]

     if { ! [string match *ts05n* $dlib] } {  

         puts "" 
         puts "DEF cell: $dname  $dorigin  $dorient   $dlib/$dcell/$dview"  

        # we will try to match instance in current design and flag if missing
        set inst [db::getNext [db::getInsts [db::getAttr dinst.name] -of $design]]
        if { $inst == "" } { 
           puts "*** not matching instance in current cell"
        } else {
               set name [db::getAttr inst.name]
               set cell [db::getAttr inst.cellName]
               set view [db::getAttr inst.viewName]
               set lib  [db::getAttr inst.libName]
               set orient [db::getAttr inst.orientation]
               set origin [db::getAttr inst.origin]

               if { $name == $dname && $orient == $dorient && $origin == $dorigin } { 
                  puts "CELL instance matches name, orient, and origin ... "
               } else {
                  puts "*** no match:  $name  $origin  $orient  $lib/$cell/$view"
               }
        }
     }
     }

}

################################################################################
# No Linting Area
################################################################################

# nolint Main
# nolint utils__script_usage_statistics
# nolint  Line 8: W Found constant