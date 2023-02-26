#!/depot/tcl8.5.12/bin/tclsh8.5
proc utils__script_usage_statistics {toolname version} {
    set prefix "ddr-da-"
    set reporter "/remote/cad-rep/msip/tools/bin/msip_get_usage_info"
    set cmd ""
    set script_dirname [file dirname [file normalize [info script]]]
    append cmd "$reporter --tool_name  \"${prefix}${toolname}\" "
    append cmd "--stage main --category ude_ext_1 "
    append cmd "--tool_path \"$script_dirname\" --tool_version \"$version\""

    exec sh -c $cmd
}

set script_name [file tail [file rootname [file normalize [info script]]]]
utils__script_usage_statistics $script_name "2022ww30"

# Script Will tag data from hierarchy of the cell#
# script will consider data which are under P4 client root directory#
# GUI function : custom::script::tag_hierarchy #
#			 -> Script will take cell details from selected data in library manager #
# command line function : custom::script::check_hierarchy_starttag <oaid> #
#created by : Rajesh (rraghav@synopsys.com)#

db::createPref customscriptsubmittag -value 1 -description "preference to submit tag file after creation default is True" -type bool
db::createPref customscripttaggingsuccess -value 0 -description "preference to check final status of tagging" -type bool
namespace eval custom::script {
    proc tag_getdetails {} {
        db::setPrefValue customscriptsubmittag -value 1
        set sel [dm::getSelected];
        if {"dmCell" == [db::getAttr type -of $sel]} {
            set cellname [db::getAttr name -of  $sel]
            set viewname "layout"
        } else {
            set cellname [db::getAttr cellName -of  $sel];
            set viewname [db::getAttr name -of $sel]
        }
        set libname [db::getAttr libName -of  $sel]
        set cvid [oa::DesignOpen $libname $cellname $viewname r]        
        custom::script::check_hierarchy_starttag $cvid
    }

    proc check_hierarchy_starttag {cvid} {
        set libpath [dm::getLibs [string trim [db::getAttr libName -of $cvid] "\""]]
        set libpath [oa::getFullPath [db::getNext $libpath]]
        set tagfilepath [file join $libpath [db::getAttr cellName -of $cvid]]
        set tagfilepath	 "$tagfilepath.tag"
        db::setPrefValue customscripttaggingsuccess -value 0
        puts "checking hierarchy"
        puts "Checking unmanaged cells"
        global env
        set hierdetails [custom::script::tag_hierarchylist $cvid]
        puts "!!! $hierdetails"
        set opencells [list ]
        set unmangedcelllist [list]
        set cmd "p4 opened -as"
        set rootpath [exec p4 -F %clientRoot% -ztag info]        
        set progress_length [expr {[llength $hierdetails] + 2}]
        set winId 0
        catch {set winId [db::getAttr id -of [gi::getActiveWindow]]}
        set diagName "taghiercellstatus"
        set d [gi::createDialog $diagName -parent [gi::getWindows $winId] -title "Hierarchy check progress" -showApply false -showHelp false -extraButtons {"ignore\ and\ proceed" "Abort"} -buttonProc [list custom::script::tag_hierarchy $cvid]]

        set progressbardetails [custom::script::create_progressbar $d "hierprog"]

        for {set i 0} {$i < [llength $hierdetails]} {set i [expr {$i+2}]} {
            set libname [lindex $hierdetails $i]

            set libpath [dm::getLibs [string trim $libname "\""]]
            set libpath [oa::getFullPath [db::getNext $libpath]]


            if {[regexp $rootpath $libpath]} {
                set x [expr {$i+1}]
                foreach cellname [lindex $hierdetails $x] {
                    set cellname [string trim $cellname "\""]
                    set cellfilepath  [file join  $libpath $cellname]
                    set	cellpath [file join  $libpath $cellname "..."]
                    set cmd [concat $cmd $cellpath]
                    set ownFiles [exec find $cellfilepath -type f -perm -u+w -user $env(USER) | sed -n {/.*\.cdslck.*/!p} | sed -n {/.*\.oacache/!p}  | sed -n {/.*\.nfs.*/!p}  | sed -n {/\/\..*/!p} | sed -n {/.*snapshot\.png/!p} | sed -n {/.*layout\.config/!p} | sed -n {/.*data\.dm/!p}] ;
                    set haveLst [exec p4 have [file join $cellfilepath ...]]
                    set openFiles [list]
                    set haveFiles [list]
                    foreach haveFile [split $haveLst \n] {
                        lappend haveFiles [lindex $haveFile 2];
                    }
                    foreach f $ownFiles {
                        if {[lsearch $haveFiles $f] < 0} {
                            lappend openFiles $f
                        }
                    }

                    custom::script::update_progressbar $progressbardetails $i $progress_length

                    foreach path $openFiles {
                        set filePath ""
                        if {![regsub $libpath $path "" filePath ] } continue                        
                        set dmObjLst [split $path "/"]

                        if {[regexp {.*\.oa} $dmObjLst]} {
                            set length [llength $dmObjLst]
                            set libName [lindex $dmObjLst [expr {$length - 4}]]
                            set cellName [lindex $dmObjLst [expr {$length - 3}]]
                            set viewName [lindex $dmObjLst [expr {$length - 2}]]

                            lappend unmangedcelllist "$libName/$cellName/$viewName"
                        }
                    }

                }
            }
        }
        set unmangedcelllist [lsort -unique $unmangedcelllist]        
        set flag 0
        if {[llength $unmangedcelllist] > 0} {            

            set flag 1
            set table [gi::createTable "unmanagedhierTable" -parent $d  -readOnly 0 -alternatingRowColors 1]
            set c1 [gi::createColumn -parent $table -label "Sl.No" -stretch 0 -readOnly 1]
            set c2 [gi::createColumn -parent $table -label "cell details" -stretch 1 -readOnly 1]
            set c3 [gi::createColumn -parent $table -label "remark" -stretch 1 -readOnly 1]

            set i 1
            foreach temp $unmangedcelllist {
                set r [gi::createRow -parent $table]
                db::setAttr value -of [gi::getCells -row $r -column $c1] -value $i
                db::setAttr value -of [gi::getCells -row $r -column $c2] -value $temp
                db::setAttr value -of [gi::getCells -row $r -column $c3] -value "un-managed"
                incr i

            }

        }
        custom::script::update_progressbar $progressbardetails [expr {$progress_length - 1}] $progress_length

        set job [xt::createJob check_open -type interactive \
            -data [list $flag $winId $cvid] \
            -cmdLine "$cmd > ~/open_temp.log" \
            -runDesc "Get opened cells"  \
            -exitProc custom::script::opened_hier_cells]


        puts "Waiting for job"
        xt::wait $job
        puts "Job complete"

        set jobstatus [db::getPrefValue customscripttaggingsuccess]
        if {$jobstatus} {
            return	$tagfilepath
        } else {
            return "nil"
        }
    }

    proc opened_hier_cells {temp } {

        set flag [lindex [db::getAttr data -of $temp] 0]
        set winId [lindex [db::getAttr data -of $temp] 1]
        set cvid [lindex [db::getAttr data -of $temp] 2]
        puts "Checking open cells"
        set file "~/open_temp.log"
        set fileid [open $file "r"]
        set opened_cells [list]
        while {[gets $fileid file_info] >= 0} {
            if {[regexp {.*\.oa.*} $file_info]} {
                lappend opened_cells $file_info

            }
        }
        close $fileid
        set dialog [gi::getDialogs taghiercellstatus -parent [gi::getWindows $winId]]


        db::setAttr geometry -of $dialog -value 500x500+100+100;

        if {[llength $opened_cells] > 0} {
            set flag 1

            set table [gi::createTable "openedhierTable" -parent $dialog  -readOnly 0 -alternatingRowColors 1 ]
            set c1 [gi::createColumn -parent $table -label "Sl.No" -stretch 0 -readOnly 1]
            set c2 [gi::createColumn -parent $table -label "cell details" -stretch 1 -readOnly 1]
            set c3 [gi::createColumn -parent $table -label "Opened by" -stretch 1 -readOnly 1]
            set i 1

            foreach file_info $opened_cells {
                if {[regexp {.*/(.*/.*/.*)/.*\.oa.*[\s]+(.*)@.*} $file_info _l celldetails username]} {
                    set r [gi::createRow -parent $table]
                    db::setAttr value -of [gi::getCells -row $r -column $c1] -value $i
                    db::setAttr value -of [gi::getCells -row $r -column $c2] -value $celldetails
                    db::setAttr value -of [gi::getCells -row $r -column $c3] -value $username
                    set cell [gi::getCells -row $r]
                    db::setAttr style.foreground -of $cell -value "#ff0000"
                    incr i
                }

            }
        }

        file delete $file
        set pb [gi::findChild "hierprog" -in $dialog]
        custom::script::update_progressbar $pb 10 10

        db::foreach b [db::getAttr dialog.buttonBar.children] {
            if {[db::getAttr b.name]== "cancel" || [db::getAttr b.name]== "close"} {
                db::setAttr shown -of $b -value false
            } else {
                db::setAttr shown -of $b -value false

            }
        }

        puts "Hierarchy check completed"
        if {!$flag } {

            custom::script::tag_hierarchy $cvid $dialog [list "ignore and proceed"]
            db::setPrefValue customscripttaggingsuccess -value 1

        } else {


            set promptout [gi::prompt "DO you want to ignore and proceed" -title "Question" -buttons [list "yes" "no"] -cancel "no"]
            if {$promptout == "yes"} {
                custom::script::tag_hierarchy $cvid $dialog [list "ignore and proceed"]
                db::setPrefValue customscripttaggingsuccess -value 1
            } else {
                custom::script::tag_hierarchy $cvid $dialog [list "abort"]
                db::setPrefValue customscripttaggingsuccess -value 0
            }
        }

    }

    proc tag_hierarchy {{cvid 0} dialog buttonname} {

        if {[lindex $buttonname 0] == "ignore and proceed"} {
            if {$cvid ==0} {
                set cvid [db::getAttr editDesign -of [de::getActiveContext]]
            }
            set topcellname [db::getAttr cellName -of $cvid]
            set toplibname [db::getAttr libName -of $cvid]


            set hierdetails [custom::script::tag_hierarchylist $cvid]
            set reqlib [list ]
            set rootpath [exec p4 -F %clientRoot% -ztag info]
            for {set i 0} {$i < [llength $hierdetails]} {set i [expr {$i+2}]} {
                set libname [lindex $hierdetails $i]

                set libpath [dm::getLibs [string trim $libname "\""]]
                set libpath [oa::getFullPath [db::getNext $libpath]]
                if {[regexp $rootpath $libpath]} {
                    lappend reqlib $libname
                }

            }
            puts "Tagging started......"
            puts "$hierdetails"
            set tagpath "p4 have"
            for {set i 0} {$i < [llength $hierdetails]} {set i [expr {$i+2}]} {
                set libname [lindex $hierdetails $i]
                if {[lsearch $reqlib $libname] >= 0} {
                    set libpath [dm::getLibs [string trim $libname "\""]]
                    set libpath [oa::getFullPath [db::getNext $libpath]]
                    if {[regexp $rootpath $libpath]} {
                        set x [expr {$i+1}]
                        foreach cellname [lindex $hierdetails $x] {
                            set cellname [string trim $cellname "\""]
                            set	cellpath [file join $libpath $cellname "..."]
                            set tagpath [concat $tagpath $cellpath]


                        }
                    }
                }
            }
            set tagfilepath [custom::script::tag_data $tagpath $topcellname $toplibname]
            catch {db::destroy $dialog}
            puts "Tagging complete ...."
            set temptagfilepath "$tagfilepath.temp"

            puts "Sorting tag file"
            exec sort $tagfilepath > "$temptagfilepath"
            file copy -force $temptagfilepath $tagfilepath
            file delete $temptagfilepath
            puts "Tagging complete"
            db::setPrefValue customscripttaggingsuccess -value 1
            return $tagfilepath

        } else {
            catch {db::destroy $dialog}
            return  "nil"
        }

    }

    proc tag_data {cellpath cellname libname} {
        puts $cellpath       
        set libpath [dm::getLibs [string trim $libname "\""]]
        set libpath [oa::getFullPath [db::getNext $libpath]]
        set tagfilepath [file join $libpath $cellname]
        set tagfilepath "$tagfilepath.tag"
        puts "Tag file : $tagfilepath"
        set addflag 1
        catch {exec p4 sync $tagfilepath}
        if {[file exists $tagfilepath]} {
            catch {exec p4 edit -t text $tagfilepath}
            puts "checking out $tagfilepath"
            set addflag 0
        }

        catch {eval exec $cellpath > $tagfilepath}

        set fileid [open $tagfilepath r]
        set tempvar  " "
        while {[gets $fileid file_info] >= 0} {

            regexp {(.*)[\s]+-[\s]+(.*)} $file_info _l depotpath localpath
            #set tempval "$depotpath\n"
            lappend tempvar $depotpath

        }

        close $fileid
        set fileid [open $tagfilepath w]
        foreach templine $tempvar {
            puts $fileid $templine
        }
        close $fileid
        if {$addflag} {
            puts "p4 add $tagfilepath"
            exec p4 add $tagfilepath
        }

        set submitpref [db::getPrefValue customscriptsubmittag]

        if {$submitpref} {
            puts "Pref customscriptsubmittag is set to True\nsubmitting tag file"
            custom::script::getdescription $tagfilepath
        }
        return $tagfilepath


    }

    proc getdescription {f} {
        catch {gi::closeWindows [gi::getDialogs checkindesc]}
        set dialog [gi::createDialog checkindesc -title "Submit Design Changes" -showApply 0 -execProc [list custom::script::execSubmit $f] -showHelp 0 ]
        set l [gi::createLabel submitPrompt -parent $dialog  -label "Write design change description:"]
        set desc [gi::createTextInput desc -parent $dialog -height 5 -width 35]
    }

    proc execSubmit {fname dialog} {
        puts $fname
        set m [gi::findChild desc.value -in $dialog];
        exec p4 submit -d $m $fname

    }

    proc tag_hierarchylist {design} {
        # Use the magic "hierarchy" attribute of the design context to
        # dump hierarchy.  This is fast.  It skips vias but that doesn't
        # matter for this use.
        set libName [oa::getLibName $design]
        set cellName [oa::getCellName $design]
        set viewName [oa::getViewName $design]
        array set hierlist {}
        set liblist {}
        set lcvList {}
        set viewList {}
        set cxt [de::open [dm::getCellViews $viewName -libName $libName -cellName $cellName] -headless 1 -readOnly 1]
        set hierarchy [db::getAttr hierarchy -of $cxt]
        he::foreach hctx $hierarchy {
            set cv [db::getAttr cellView -of $hctx]
            #
            # Sample LCV map line:
            # "rx_top","ssp_gold","rx_top","layout","0"
            #
            # celltype 0=normal inst, 1=stdvia, 2=pcell inst/via, but we don't have enough
            # information in general to know that, so "0" for all.  Doesn't matter to VUE.
            lappend liblist [format {"%s"} [db::getAttr libName -of $cv]]
            lappend lcvList [format {"%s","%s"}  [db::getAttr libName -of $cv]  [db::getAttr cellName -of $cv]]
            lappend viewList [format {"%s","%s"}  [db::getAttr cellName -of $cv]  [db::getAttr name -of $cv]]

        }
        de::close $cxt

        set liblist [lsort -unique $liblist]
        foreach libname $liblist {
            set celllist {}
            foreach lcv $lcvList {
                set temp [split $lcv ","]

                if { [lindex $temp 0] == $libname } {

                    lappend celllist [lindex $temp 1]
                }
            }
            set celllist [lsort -unique $celllist]
            set hierlist($libname) $celllist

        }
        foreach tlib $liblist {
        }

        return [array get hierlist]

    }

    proc sync_Tagfiles {} {
        set sel [dm::getSelected];
        if {"dmCell" == [db::getAttr type -of $sel]} {
            set cellname [db::getAttr name -of  $sel]
            set viewname "layout"
        } else {
            set cellname [db::getAttr cellName -of  $sel];
            set viewname [db::getAttr name -of $sel]
        }
        set libname [db::getAttr libName -of  $sel]

        set libpath [db::getAttr path -of [dm::getLibs $libname]]
        set tagfileName [file join $libpath $cellname]
        set tagfileName  "$tagfileName.tag"
        puts $tagfileName
        catch {exec p4 sync $tagfileName}
        set filelog [exec p4 filelog -l $tagfileName]

        catch {gi::closeWindows [gi::getDialogs tagrev]}

        set dialog [gi::createDialog tagrev -title "Tag file History" -showHelp 0 -showApply 0 -extraButtons "Sync\\ tag\\ file Rollback\\ to\\ tagged\\ version" -buttonProc "custom::script::open_tagfile"]
        db::setAttr geometry -of $dialog -value 1200x500+100+100;
        set table [gi::createTable taghistorytable -parent $dialog  -readOnly 1 -allowSortColumns 1 -alternatingRowColors 1]
        set c1 [gi::createColumn -parent $table -label "Revision Number" -stretch 0 -readOnly 1]
        set c2 [gi::createColumn -parent $table -label "Action" -stretch 0 -readOnly 1]
        set c3 [gi::createColumn -parent $table -label "Date" -stretch 0 -readOnly 1]
        set c4 [gi::createColumn -parent $table -label "Description" -stretch 1 -readOnly 1]
        set c5 [gi::createColumn -parent $table -label "User" -stretch 0 -readOnly 1]
        set buff [split $filelog "\n"]

        foreach it $buff {
            if [regexp {^//} $it] {
                set fileRow [gi::createRow -parent $table -expanded 1];
                db::setAttr value -of [gi::getCells -row $fileRow -column $c1]  -value [file tail $it] ;
                db::setAttr value -of [gi::getCells -row $fileRow -column $c4]  -value $it ;
            } elseif  [regexp {...[\s]+#([0-9]+)[\s]+[a-z]+[\s]+[0-9]+[\s]+([a-z/]+) on ([0-9/]+) by ([a-z][-a-z0-9_]+)@} $it _l ver op time owner] {
                set r [gi::createRow -parent $fileRow];
                db::setAttr value -of [gi::getCells -row $r -column $c1]  -value $ver;
                db::setAttr value -of [gi::getCells -row $r -column $c2]  -value $op;
                db::setAttr value -of [gi::getCells -row $r -column $c3]  -value $time;
                db::setAttr value -of [gi::getCells -row $r -column $c5]  -value $owner;
            } else {
                set desc [db::getAttr value -of [gi::getCells -row $r -column $c4]];
                set desc [concat $desc $it];
                db::setAttr value -of [gi::getCells -row $r -column $c4]  -value $desc
            }
        }

    }

    proc open_tagfile {dialog buttonname} {
        
        set table [db::filter [db::getAttr children -of $dialog] -filter {%name == "taghistorytable"}]
        set row [db::getAttr selection -of $table]
        set parent [db::getAttr parent -of $row]
        set cells [gi::getCells -row $row]
        set ver [db::getAttr value -of [db::getNext $cells]]
        set cells [gi::getCells -row [gi::getRows -parent [db::getNext $table]]]
        db::getNext $cells
        db::getNext $cells
        db::getNext $cells
        set path [db::getAttr value -of [db::getNext $cells]]

        if {[lindex $buttonname 0] == "Rollback to tagged version"} {
            puts "Rolling back to tagged version"
            set outfile "$path#$ver"
            puts "Taking $outfile for rolling back"
            catch {eval exec p4 sync $outfile}
            set latestoutfile $path
            set path [exec p4 have $path]
            regexp {(.*)[\s]+-[\s]+(.*)} $path _l depotpath path

            set libnames [list ]
            set fileid [open $path r]
            set tempvar  " "
            while {[gets $fileid file_info] >= 0} {

                # regexp {(.*)[\s]+-[\s]+(.*)} $file_info _l depotpath

                if {[regexp {.*\.oa} $file_info]} {
                    lappend tempvar [list $file_info]

                    if {[regexp {.*/(.*)/.*/.*/.*} $file_info _l libname]} {
                        lappend libnames $libname
                    }
                }

            }
            close $fileid

            if {[llength $libnames] > 0} {


                set libnames [lsort -unique $libnames]
                set dialog [gi::createDialog displaylibnames -title "Select Libraries to edit and checkin" -showHelp 0 -showApply 0 -execProc [list custom::script::submit_rolledback $tempvar]]
                set table [gi::createTable librariestable -parent $dialog  -readOnly 0 -allowSortColumns 1 -alternatingRowColors 1 -selectionModel "multipleRows"]
                set c1 [gi::createColumn -parent $table -label "Library name" -stretch 1 -readOnly 1]
                set c2 [gi::createColumn -parent $table -label "Sel" -stretch 0 -readOnly 0 -dataType bool]
                foreach temp $libnames {

                    set r [gi::createRow -parent $table]
                    db::setAttr value -of [gi::getCells -row $r -column $c1] -value $temp
                    db::setAttr value -of [gi::getCells -row $r -column $c2] -value 0

                }

            } else {
                de::sendMessage  "Cells are not edited" -severity "information"
            }
            catch {eval exec p4 sync $latestoutfile}
        }

        if {[lindex $buttonname 0] == "Sync tag file"} {
            set outfile "$path#$ver"
            set tempvar "_P4_"
            if {[regexp {.*/(.*)} $path _l cellname]} {
                set localfile "$cellname$tempvar$ver.sh"
                puts "p4 print -q -o $localfile $outfile "
                exec p4 print -q -o $localfile $outfile
                puts "Processing $localfile Started......"
                set fileid [open $localfile r]
                set tempvar  " "
                while {[gets $fileid file_info] >= 0} {

                    #regexp {(.*)[\s]+-[\s]+(.*)} $file_info _l depotpath localpath
                    set tempval "p4 sync $file_info"
                    lappend tempvar $tempval

                }

                close $fileid
                exec chmod 777 $localfile
                set fileid [open $localfile w]
                foreach temp $tempvar {
                    puts $fileid $temp

                }
                close $fileid

                puts "Processing $localfile completed....."
                puts $localfile
                set cmd "xterm -e sh $localfile"
                xt::createJob tag_sync -type interactive \
                    -cmdLine $cmd  \
                    -data [list $buttonname $path]\
                    -runDesc "sync tag file"  \
                    -exitProc custom::script::tag_jobclbk                
            } else {
                de::sendMessage "Error in getting tag file name" -severity error
            }
        }
        catch {gi::closeWindows [gi::getDialogs tagrev]}
    }


    proc submit_rolledback {tempvar  dialog} {
        set child [db::getAttr children -of $dialog]
        set table [db::filter $child -filter {%type == "giTable"}]
        set reqlib [list ]

        set rows [gi::getRows -parent [db::getNext $table]]
        db::foreach row $rows {
            set cells [gi::getCells -row $row]
            set c1 [db::getAttr value -of [db::getNext $cells]]
            set c2 [db::getAttr value -of [db::getNext $cells]]
            if {$c2} {
                lappend reqlib $c1
            }
        }
        set errorcelllist [list ]

        foreach filepathtemp $tempvar {

            set errorflag 1
            set filepath [lindex $filepathtemp 0]
            set path [split $filepath "#"]


            set local_filepath [eval exec p4 have [lindex $path 0]]
            set currentver [lindex  $local_filepath 1]
            set local_filepath [lindex  $local_filepath 2]
            if {$currentver == [lindex [split $filepath "#"] 1]} {
                de::sendMessage "$filepath is same as current version, scipping rollback" -severity warning
                set errorflag 0
            }
            if {[regexp {.*/(.*)/.*/.*/.*} $local_filepath _l libname]} {
                if {[lsearch $reqlib $libname] >= 0 } {
                    if ![catch {exec p4 fstat -T "otherOpen" } $local_filepath] {                        
                        lappend errorcelllist $filepath
                        set errorflag 0
                    }
                    if {$errorflag} {

                        regsub [file tail [lindex $path 0]] [lindex $path 0] ... cellpath;
                        catch {eval exec p4 sync $cellpath}
                        if {[catch {set buff [exec p4 edit -t +l $cellpath]} err]} {
                            de::sendMessage $err -severity error
                            set errorflag 0
                            lappend errorcelllist $filepath
                        }
                    }
                    if {$errorflag} {
                        set file_list [list ]
                        set buff [split $buff \n]
                        set file_list [list ];
                        foreach line $buff {
                            lappend file_list [lindex [split [lindex $line 0] #] 0]
                        }

                        if [catch {exec p4 print -o $local_filepath -q $filepath} err] {
                            de::sendMessage  $err -severity error
                            return
                        }

                        set m "Tag Script : Rollback to Version $filepath"
                        set m [string map {\n \\n\\t \/ \\/ & \\& # \\#} $m]
                        set emptyChangeList [exec p4 change -o | sed {s://.*::} | sed "s/<enter description here>/$m/"  | p4 change -i];
                        regexp {Change[\s]+([0-9]+)} $emptyChangeList _a changelist;

                        set cmd  "exec echo  $file_list | xargs p4 reopen -c $changelist >> p4.log; exec p4 submit -c $changelist "
                        
                        if [catch {eval $cmd} err ] {
                            # NOP
                        }
                    }
                }
            }
        }

        if {[llength $errorcelllist] > 0} {
            de::sendMessage  "Following Cells are not Rolled back" -severity error
            foreach temperrorcell $errorcelllist {
                de::sendMessage  $temperrorcell -severity error
            }
        }
        dm::refreshLibraryManager
    }

    proc tag_jobclbk {temp} {


        puts "job completed"
        dm::refreshLibraryManager
        set refresh [de::showRefreshDesigns]

    }

    proc create_progressbar {p name } {
        db::foreach b [db::getAttr p.buttonBar.children] {
            db::setAttr shown -of $b -value false
        }
        set pb [gi::createPushButton $name -parent $p]
        db::setAttr pb.styleSheet -value "QPushButton \{background: white; border: 1px solid black;\}"
        db::setAttr pb.enabled -value 0
        return $pb
    }

    proc update_progressbar {pb n ntotal} {
        set n [expr {$n*1.0}]
        set ntotal [expr {$ntotal*1.0}]

        db::eval {
            set ih [db::createInterruptHandler "myInterrupt"]
            if {$n<=$ntotal} {
                set p [expr {$n/$ntotal}]
                custom::script::pbSetValue $pb $p
                db::checkForInterrupt -handler $ih
            }
        }
    }

    proc  pbSetValue {pb p} {
        set c1 black
        set c2 white
        if {$p>=1} {
            set styleSheet "QPushButton \{min-width: 500 ;background: $c1; border: 0px;\}"
        } elseif {$p<=0} {
            set styleSheet "QPushButton \{min-width: 500 ;background: $c2; border: 0px;\}"
        } else {
            set styleSheet "QPushButton \{min-width: 500 ;background: qlineargradient(x1: 0, y1: 0, x2: 1, y2: 0, stop: 0 $c1, stop: $p $c1, stop: [expr {$p+0.01}] $c2, stop: 1.0 $c2); border: 1px solid $c1;\}"
        }


        db::setAttr pb.label -value "[expr {round($p*100)}]\%"

        db::setAttr pb.styleSheet -value $styleSheet

    }

}

set m [gi::getMenus dmCellViewContextMenu];
gi::createAction tag_hier -title "Create Tag file" -command custom::script::tag_getdetails
gi::createAction sync_tag -title "Sync Tag file" -command custom::script::sync_Tagfiles
gi::addActions  {tag_hier sync_tag} -to $m





################################################################################
# No Linting Area
################################################################################

# nolint Main
# nolint Line 232: N Non-default arg after default arg
# nolint Line 528: W Found constant 
# nolint Line 595: N Suspicious variable name 