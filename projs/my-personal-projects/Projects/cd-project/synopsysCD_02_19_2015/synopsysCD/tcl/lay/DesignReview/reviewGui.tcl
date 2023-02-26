# Copyright (c) 2004-2015 Synopsys, Inc. This Galaxy Custom Designer software
# and the associated documentation are confidential and proprietary to
# Synopsys, Inc. Your use or disclosure of this Galaxy Custom Designer software
# is subject to the terms and conditions of a written license agreement between
# you, or your company, and Synopsys, Inc.

namespace eval ::amd::_designReview {
    
namespace import -force ::amd::amdLayLibrary::*
namespace import -force ::amd::utils::*

variable columns [list Phase Rev Comment Reviewer Date Location Status Owner Notes]
variable stateTable
array set stateTable {}

proc amdDesignReview {ctx {update 0}} {
    variable columns
    variable stateTable

    set ns [namespace current]
    set oaDes [db::getAttr editDesign -of $ctx]
    set lcv "[db::getAttr oaDes.libName]\/[db::getAttr oaDes.cellName]\/[db::getAttr oaDes.viewName]"
    
    set reviewDlg [db::getNext [gi::getDialogs reviewDialog]]
    if {""!=$reviewDlg} {
        set form [gi::findChild form -in $reviewDlg]
        if {[db::getAttr lcv -of $form]!=$form} {
            gi::closeWindows $reviewDlg
            set reviewDlg ""
        }
    }
    
    if {""==$reviewDlg} {
        set reviewDlg [gi::createDialog reviewDialog \
        -showApply true -showHelp true \
        -execProc ${ns}::amdDesignReviewOK -title "Design Review Tool \t\t$lcv" \
        -extraButtons "CustomCancel" -buttonProc ${ns}::amdDesignReviewCancel]    
        
        set form [gi::createGroup form -parent $reviewDlg]
        db::setAttr shown -of $form -value 0
        
        set inline1 [gi::createInlineGroup note -parent $reviewDlg]
        
        set category [gi::createMutexInput category -parent $inline1 -enum \
            {Phase "Pre Layout" Layout "Final Layout"} -viewType combo \
            -valueChangeProc ${ns}::amdDesignReviewGetFilteredList]
        set query [gi::createTextInput query -parent $inline1]    
        set filterBtn [gi::createPushButton filter -parent $inline1 -label "Filter" \
        -execProc ${ns}::amdDesignReviewGetFilteredList -toolTip "Filter Notes"]
        set reviewBtn [gi::createPushButton review -parent $inline1 -label "Add Review" \
        -execProc ${ns}::amdDesignReviewAdd -toolTip "Add new review note"]
        
        set tbl [gi::createTable report -allowAddRows false \
        -allowResizeColumns false -parent $reviewDlg \
        -allowHideColumns true -valueChangeProc ${ns}::designReviewOp \
        -readOnly true \
        -allowSortColumns 1 -alternatingRowColors 1 \
        -selectionChangeProc ${ns}::amdDesignReviewReportCB]
        
        foreach c $columns {
            set stretch 0
            if {"Comment"==$c} {
                set stretch 1
            }
            set col_$c [ gi::createColumn -label $c -parent $tbl -stretch $stretch] 
        }
        
        # In the future add Design LCV to the tooltip
        set fixedBtn [gi::createPushButton fixed -parent $reviewDlg \
            -label "Fixed" -enabled 0 -execProc [list ${ns}::amdDesignReviewSetStatus "Fixed"] ]
        set cannotBtn [gi::createPushButton cannotFix -parent $reviewDlg \
            -label "Can't Fix" -enabled 0 -execProc [list ${ns}::amdDesignReviewSetStatus "Can't Fix"]]
        set clearBtn [gi::createPushButton clear -parent $reviewDlg \
            -label "Clear" -enabled 0 -execProc [list ${ns}::amdDesignReviewSetStatus ""]]
                
        set delBtn [gi::createPushButton delete -parent $reviewDlg \
            -label "Delete" -enabled 0 -execProc ${ns}::amdDesignReviewDelete]
        set clearMarkersBtn [gi::createPushButton clearMarkers -parent \
            $reviewDlg -label "Clear Markers" -enabled 0 -execProc ${ns}::amdDesignReviewDeleteMarkers]
        gi::layout $cannotBtn -rightOf $fixedBtn
        gi::layout $clearBtn -rightOf $cannotBtn
        gi::layout $delBtn -rightOf $clearBtn
        gi::layout $delBtn -justify center 
        gi::layout $clearMarkersBtn -rightOf $delBtn
        set hide [gi::createBooleanInput hide -parent $reviewDlg \
            -label "Hide fixed errors" -valueChangeProc ${ns}::amdDesignReviewGetFilteredList]
        gi::layout $hide -rightOf $clearMarkersBtn
        gi::layout $hide -justify right 
        
        set cancelBtn [db::filter [db::getAttr buttonBar.children -of $reviewDlg] -filter {%label=="Cancel"}]
        db::setAttr shown -of $cancelBtn -value 0
        set cancelBtn [db::filter [db::getAttr buttonBar.children -of $reviewDlg] -filter {%label=="CustomCancel"}]
        db::setAttr label -of $cancelBtn -value Cancel
        
        amdDesignReviewRefresh $oaDes
        set contents [amdDesignReviewRead $oaDes]
        foreach line $contents {
            amdAddEntry $line 0 $reviewDlg
        }
        catch {array unset stateTable}
        array set stateTable {}
        set form [gi::findChild form -in $reviewDlg]
        db::addAttr lcv -of $form -value $lcv
        db::addAttr initialList -of $form -value $contents        
        db::addAttr design -of $form -value [getLCV $oaDes]
        db::setAttr geometry -of $reviewDlg -value 912x245+674+479
    }
    
    gi::setActiveDialog $reviewDlg
}


proc amdDesignReviewCancel {dlg w} {
    if {[amdDesignReviewIsModified]} {
        set res [gi::prompt "All changes made to the Design Review Tool will be lost, are you sure?" \
        -title "Prompt" -buttons "Yes No" -icon "question" -parent $dlg]
        if {"Yes"==$res} {
            amdDesignReviewDeleteMarkers        
            catch {array unset stateTable}
            array set stateTable {}
            amdDesignReviewCleanUp $dlg
        } else {
            # bring up the cellview previously reviewed
            set form [gi::findChild form -in $dlg]
            set oaDes [openDesign [db::getAttr design -of $form]]
            amdDisplayLayout [db::getAttr oaDes.libName] [db::getAttr oaDes.cellName] [db::getAttr oaDes.viewName]
        }
    } else {
        amdDesignReviewDeleteMarkers
    }
    gi::closeWindows $dlg
}

proc amdDesignReviewOK {dlg} {
    if {[amdDesignReviewIsModified]} {
        variable stateTable
        set reviewList [amdDesignReviewCheckIn $dlg]
        array unset stateTable
        array set stateTable {}
        set form [gi::findChild form -in $dlg]
        db::addAttr initialList -of $form -value $reviewList  
    }
    amdDesignReviewDeleteMarkers
    amdDesignReviewUpdateButtons $dlg     
}

proc amdDesignReviewUpdateButtons {dlg} {
    if {![amdDesignReviewIsModified]} {
        amdDesignReviewCleanUp $dlg
    }
}

proc amdDesignReviewCleanUp {dlg} {
    set form [gi::findChild form -in $dlg]
    set oaDes [openDesign [db::getAttr design -of $form]]
    set file [amdDesignReviewGetFile $oaDes]
    if {""!=$file} {
        if {![catch {amdRun "p4 opened $file"}]} {
            amdRun "p4 revert $file"
        }
        if {![file size $file]} {
            amdRun "rm -rf [amdGetDirFromPath $file]"
        }        
    }
}


proc amdDesignReviewCheckIn {dlg} {
    set form [gi::findChild form -in $dlg]
    set tbl [gi::findChild report -in $dlg]
    set oaDes [openDesign [db::getAttr design -of $form]]
    set file [amdDesignReviewGetFile $oaDes]
    if {""==$file} {    
        error "amdDesignReviewCheckIn: Review file does not exist!"
    }
    if {![amdIsFileCheckedOut $file]} {
        error "amdDesignReviewCheckIn: Review file is not checked out!"
    }
    
	# modify the file
    set reviewList {}
    db::foreach row [gi::getRows -parent $tbl] {
        set entry {}
        db::foreach cell [gi::getCells -row $row] {
            lappend entry [db::getAttr value -of $cell]
        }
        lappend reviewList $entry
    }
	amdDesignReviewWrite $file $reviewList 

    # generate description    
    set description [amdDesignReviewGenDescription]
    
	# delete if the file is empty
    if {![file size $file]} {
        amdRun "p4 revert $file"
        set dirName [amdGetDirFromPath $file]
        amdRun "p4 delete $dirName/..."
        amdRun "rm -rf $dirName"
        append description "; Empty review file deleted"
    }
	# now check it back in
    amdRun "p4 submit -d \"$description\" $file  "
    return $reviewList
}

proc amdDesignReviewGenDescription {} {
    variable stateTable

    set added 0
    set deleted 0
    set fixed 0
    set cantfix 0
    set cleared 0
    set description ""
    
    if {[info exist stateTable(added)]} {
        set added [llength $stateTable(added)]
    }
    if {[info exist stateTable(deleted)]} {
        set deleted [llength $stateTable(deleted)]
    }
    if {[info exist stateTable(fixed)]} {
        set fixed [llength $stateTable(fixed)]
    }
    if {[info exist stateTable(cantfix)]} {
        set cantfix [llength $stateTable(cantfix)]
    }
    if {[info exist stateTable(cleared)]} {
        set cleared [llength $stateTable(cleared)]
    }    
    
    if {$added} {
        set m ""
        if {1!=$added} {
            set m "s"
        }
        lappend description "Added $added review${m}"
    }

    if {$deleted} {
        set m ""
        if {1!=$deleted} {
            set m "s"
        }
        lappend description "Deleted $deleted review${m}"
    }
    
    if {$fixed} {
        set m ""
        if {1!=$fixed} {
            set m "s"
        }
        lappend description "Fixed $fixed review${m}"
    }

    if {$cantfix} {
        set m ""
        if {1!=$cantfix} {
            set m "s"
        }
        lappend description "Changed status of $cantfix review${m} to can't fix" 
    }

    if {$cleared} {
        set m ""
        if {1!=$cleared} {
            set m "s"
        }
        lappend description "Cleared status of $cleared review${m}" 
    }    
    return [join $description "; "]    
}


proc amdDesignReviewWrite {file itemList} {
    if {[catch {set fh [open $file "w"]}]} {
        error "amdDesignReviewWrite:Cannot open '$file' for write! "
    }
    foreach item $itemList {
        puts $fh \{$item\}
    }
    close $fh
}


proc amdIsFileCheckedOut {file} {
    if {[file isfile $file]} {
        if {[amdIsFileICManaged $file]} {
            if [catch {set status [amdRun "p4 opened $file"]} err] {
				set status $err
			}
            if {![regexp {not opened} $status]} {
                return 1
            }
        } else {
            return 1
        }
    } else {
        de::sendMessage "amdIsFileCheckedOut: Please specify a valid file!" -severity warning
    }
    return 0
}

#proc amdIsFileICManaged {file} {
#  if {[file isfile $file]} {
#        catch {set status [amdRun "p4 sync -n $file"]}
#        if {[regexp "not under client's root" $status] || [regexp "not in client view" $status] } {
#            return 0
#        } else {
#            return 1
#        }
#    } else {
#        de::sendMessage "amdIsFileICManaged: Please specify a valid file!" -severity warning
#    }
#    return 0
#}

proc amdIsFileICManaged {file} {
  if {[file isfile $file]} {
        if [catch {set status [amdRun "p4 have $file"]} err] {
			set status $err
		} 
        if {[regexp "not on client" $status] } {
           	return 0
        } else {
           	return 1
        }
		
    } else {
        de::sendMessage "amdIsFileICManaged: Please specify a valid file!" -severity warning
    }
    return 0
}

proc amdDesignReviewGetFilteredList {w} {
    variable columns
    set dlg [getParentDialog $w]
    set tbl [gi::findChild report -in $dlg]
    set rows [gi::getRows -parent $tbl]
    set phase [gi::findChild category.value -in $dlg]
    set hide [gi::findChild hide.value -in $dlg]
    set queries [gi::findChild query.value -in $dlg]
    set queries [string trim $queries]
    
    db::foreach row $rows {
        db::setAttr shown -of $row -value 1
    }
    
    if {"Phase"!=$phase} {
        db::foreach row $rows {
            set val [amdDesignReviewGetEntryValue $row "Phase"]
            if {$val!=$phase} {
                db::setAttr shown -of $row -value 0
            }
        }
    }
    if {$hide} {
        db::foreach row $rows {
            set val [amdDesignReviewGetEntryValue $row "Status"]
            if {$val=="Fixed"} {
                db::setAttr shown -of $row -value 0
            }
        }        
    }
    
    if {""!=$queries} {
        db::foreach row $rows {
            set count 0
            foreach query $queries {
                if {[string is integer $query]} {
                    set val [amdDesignReviewGetEntryValue $row "Rev"]
                    if {$val==$query} {
                        incr count
                    }
                } else {
                    foreach c $columns {
                        set val [amdDesignReviewGetEntryValue $row $c]
                        if {-1!=[string first [string tolower $query] [string tolower $val]]} {
                            incr count
                            break
                        }
                    }
                }
            }
            if {$count!=[llength $queries]} {
                db::setAttr shown -of $row -value 0
            }
        }
    }
}


proc amdDesignReviewReportCB {tbl} {
    set dlg [getParentDialog $tbl]
    set form [gi::findChild form -in $dlg]
    set oaDes [openDesign [db::getAttr design -of $form]]
    set ctx [deFindContext $oaDes]
    if {""==$ctx} {
        return 0
    }
    
    giEnableWidget $dlg fixed
    giEnableWidget $dlg cannotFix
    giEnableWidget $dlg clear
    giEnableWidget $dlg delete
    giEnableWidget $dlg clearMarkers
    
    set oaMarker {}
    set selRow [db::getNext [db::getAttr tbl.selection]]
    if {""!=$selRow} {
        set cells [gi::getCells -row $selRow]
        set location [amdDesignReviewGetEntryValue $selRow "Location"]
        set block [oa::getTopBlock $oaDes]
        set phase [amdDesignReviewGetEntryValue $selRow "Phase"]
        set revision [amdDesignReviewGetEntryValue $selRow "Rev"]
        set comment [amdDesignReviewGetEntryValue $selRow "Comment"]
        set comment "\[$phase rev.${revision}\] $comment"
        set markers [db::getMarkers -design $oaDes -tool "Design Review Tool"]
        set markers [db::filter $markers -filter {%bBox==$location}]
        
        set oaPA [oa::PointArray [box2oaBox $location]]
        set tran [de::startTransaction reviewMarkerFromTable -design $oaDes]
        db::foreach m $markers {
            db::destroy $m
        }
        set oaMarker [oa::MarkerCreate $block $oaPA $comment \
            "Design Review" "Design Review Tool" 1 1 warning]
        de::endTransaction $tran    

        set reviewer [amdDesignReviewGetEntryValue $selRow "Reviewer"]
        if {$::env(USER) == $reviewer} {
            giEnableWidget $dlg delete 1    
        }  
        giEnableWidget $dlg fixed 1
        giEnableWidget $dlg cannotFix 1
        giEnableWidget $dlg clear 1        
        if {""!=$oaMarker} {
            de::deselectAll $ctx
            de::select $oaMarker
            de::fit -set $oaMarker -scale 0.6
        }        
    }
    
    set markers [db::getMarkers -design $oaDes -tool "Design Review Tool"]
    if {![db::isEmpty $markers]} {
        giEnableWidget $dlg clearMarkers 1
    }

}


proc amdDesignReviewDelete {btn} {
    set dlg [getParentDialog $btn]
    set form [gi::findChild form -in $dlg]
    set oaDes [openDesign [db::getAttr design -of $form]]
    set tbl [gi::findChild report -in $dlg]
    if {[amdDesignReviewIsModified] || ([amdDesignReviewCheckIsLatest $oaDes] && [amdDesignReviewCheckIsCheckedOut $oaDes])} {
		# checkout as soon as delete button is clicked
		if {![amdDesignReviewIsModified]} {
			amdDesignReviewCheckOut $oaDes
		}
        
        set res [gi::prompt "Are you sure you want to delete the selected reviews?" \
        -title "Prompt" -buttons "Yes No" -icon "question" -parent $dlg]   
        if {"Yes"==$res} {
            set selRow [db::getAttr tbl.selection]
            if {[amdDesignReviewGetEntryValue $selRow "Reviewer"]==$::env(USER)} {
                amdDesignReviewTrackChanges $selRow "Deleted"
                set location [amdDesignReviewGetEntryValue $selRow "Location"]
                set markers [db::getMarkers -design $oaDes -tool "Design Review Tool"]
                set markers [db::filter $markers -filter {%bBox==$location}]
                set tran [de::startTransaction reviewMarkerFromTable -design $oaDes]
                db::foreach m $markers {
                    db::destroy $m
                }
                de::endTransaction $tran              
                db::destroy $selRow
            } else {
                amdWarn "Only the original reviewers can delete their review entries!" $dlg
            }
        }
    }
}

proc amdDesignReviewCheckIsCheckedOut {oaDes} {
    return 1
}

# return t if review file is latest
proc amdDesignReviewCheckIsLatest {oaDes} {
    if {[amdDesignReviewIsLatest $oaDes]} {
        return 1
    }
    set reviewDlg [db::getNext [gi::getDialogs reviewDialog]]
    set res [gi::prompt "The review file on the depot has been updated. No changes can be made until the latest version is synced down. Sync now?" \
        -title "Prompt" -buttons "Yes No" -icon "question" -parent $reviewDlg]
    if {"Yes"==$res} {
        amdRun "icmp4 sync -f [amdDesignReviewGetFile $oaDes]"
        set form [gi::findChild form -in $reviewDlg]
        set oaDes [openDesign [db::getAttr design -of $form]]
        set ctx [deFindContext $oaDes]        
        gi::closeWindows $reviewDlg
        amdDesignReview $ctx
    }
    return 0
}

# refresh the review text.txt without prompt
proc amdDesignReviewRefresh {oaDes} {
    if {![amdDesignReviewIsLatest $oaDes]} {
        amdRun "p4 sync -f [amdDesignReviewGetFile $oaDes]"
    }
}

proc amdDesignReviewIsLatest {oaDes} {
    # check if the review cellview needs to be updated, return t in most cases unless there's an update
    set file [amdDesignReviewGetFile $oaDes 1]
    if {""!=$file} {
        if [catch {set out [amdRun "p4 sync -n $file"]} err] {
		
			return 1	
		}
        if {""!=$out} {
            if {[regexp {not under client's root} $out] || [regexp {not in client view} $out]} {
                de::sendMessage "amdDesignReviewIsLatest: Library '[db::getAttr libName -of $oaDes]' is not under ICManage." -sverity warning
                return 1
            }
        } else {
            return 1
        }
    } else {
        de::sendMessage "amdDesignReviewIsLatest: 'review' cellview cannot be found!" -sverity warning
    }
    return 0    
}


proc amdDesignReviewDeleteMarkers {{btn ""}} {
    set dlg [db::getNext [gi::getDialogs reviewDialog]]
    set form [gi::findChild form -in $dlg]
    set oaDes [openDesign [db::getAttr design -of $form]]
    
    db::destroy [db::getMarkers -design $oaDes -tool "Design Review Tool"]
    set clearBtn [gi::findChild clearMarkers -in $dlg]
    db::setAttr enabled -of $clearBtn -value 0
}


proc designReviewOp {widget} {
    #puts [db::listAttrs -of $widget]
    #column dataType parent readOnly row style this toolTip type value
    #puts "To be defined!!!" Isn't this procedure extra?
}

proc amdDesignReviewRead {oaDes} {
    set file [amdDesignReviewGetFile $oaDes]
    set itemList {}
    if {""!=$file} {
        if {[catch {set fh [open $file "r"]}]} {
            error "amdDesignReviewRead: Cannot read '$file'!"
        }
        set contents [read $fh]
        close $fh
        foreach l $contents {
            # backward compatibility (without user and notes field)
            if {7==[llength $l]} {
                lappend l "" ""
            }                    
            if {9==[llength $l]} {
                lappend itemList $l
            }
        }
    }
    return $itemList
}


proc amdDesignReviewGetFile {oaDes {forced 0}} {
    if {"schematic"==[db::getAttr oaDes.viewType]} {
        set vName "review_schematic"
    } else {
        set vName "review"
    }

    set lName [db::getAttr oaDes.libName]
    set cName [db::getAttr oaDes.cellName]
    set viewName [db::getAttr oaDes.viewName]
    set cv [db::getNext [dm::getCellViews $viewName -cellName $cName -libName $lName]]
    set file ""
    
    set dmFile [db::getNext [dm::getDMFiles -dmContainer $cv]]
    set path [amdGetDirFromPath [db::getAttr dmFile.path]]
    set file [file normalize [file join $path "../" $vName "text.txt"]]
    if {$forced} {
        file mkdir [file dir $file]
        if {![file isfile $file]} {
            set fh [open $file "w"]
            close $fh
        }
    }
    if {![file isfile $file]} {
        set file ""
    }
    return $file
}


proc writeReviewFile {fName contents} {
    set rev [open $fName w]
    foreach line $contents { 
        puts $rev \{$line\}
    }
    close $rev    
}

proc amdDesignReviewSetStatus { state widget } {
    set ns [namespace current]
    set d [db::getAttr widget.parent]
    set dlg [db::getNext [gi::getDialogs amdDesignReviewSetStatusForm -parent $d]]
    if {""==$dlg} {
        set dlg [gi::createDialog amdDesignReviewSetStatusForm \
        -parent $d -showHelp true \
        -execProc [list ${ns}::amdDesignReviewSetStatusDisplayFormCB $d] \
        -title "Design Review Tool - Change Status" ]
        set notes [gi::createTextInput notes -parent $dlg  \
            -label "Enter notes" -prefName amdChangeStatusNote]
    }
    set notes [gi::findChild notes -in $dlg]
    db::addAttr state -of $notes -value $state
    
    gi::execDialog $dlg
}

proc amdDesignReviewSetStatusDisplayFormCB {reviewDlg w} {
    set dlg [getParentDialog $w]
    set notes [gi::findChild notes -in $dlg]
    set state [db::getAttr state -of $notes]
    set notesVal [string trim [db::getAttr value -of $notes]]
    
    if {"Can't Fix" == $state && ""==$notesVal} {
        amdWarn "Notes field cannot be empty when changing status to \"Can't Fix\"!" $dlg
        gi::setActiveDialog $reviewDlg
        return
    }

    set form [gi::findChild form -in $reviewDlg]
    set oaDes [openDesign [db::getAttr design -of $form]]
    
    if {[amdDesignReviewIsModified] || ([amdDesignReviewCheckIsLatest $oaDes] && [amdDesignReviewCheckIsCheckedOut $oaDes])} {
        set txt [db::getPrefValue amdChangeStatusNote]
        set tbl [gi::findChild report -in $reviewDlg]
        set selRow [db::getAttr tbl.selection]
        set giCell [gi::getCells -row $selRow -column \
            [gi::getColumns -parent $tbl -filter {%label == "Notes"}]]
        db::setAttr value -of $giCell -value $txt
        set giCell [gi::getCells -row $selRow -column \
            [gi::getColumns -parent $tbl -filter {%label == "Status"}]]
        db::setAttr value -of $giCell -value $state
        set giCell [gi::getCells -row $selRow -column \
            [gi::getColumns -parent $tbl -filter {%label == "Owner"}]]
        db::setAttr value -of $giCell -value $::env(USER)
        
        # track changes for ICM description
        amdDesignReviewTrackChanges $selRow $state
    }
}


proc amdDesignReviewTrackChanges {row action} {
    variable stateTable
    set action [string tolower $action]
    set checkout 0
    set skip 0
    
    if {"can't fix"==$action } {
        set action cantfix
    }
    if {""==$action } {
        set action cleared
    }
    
    # perhaps we need to checkout?
    if {![amdDesignReviewIsModified]} {
        set checkout 1
    }
    
    set tbl [db::getAttr parent -of $row]
    set reviewDlg [db::getNext [gi::getDialogs reviewDialog]]
    set form [gi::findChild form -in $reviewDlg]
    set initialList [db::getAttr initialList -of $form]
    set oaDes [openDesign [db::getAttr design -of $form]]
    set entry [amdGetEntry $row]
    # identify "real" changes
    if {"added"!=$action && "deleted"!=$action} {
        set skip [member $entry $initialList]
    }
    
    # remove the status, user and notes field
    set entry [lrange $entry 0 5]
            
    switch $action {
        "deleted" {
            if {[info exist stateTable(added)] && [member $entry $stateTable(added)]} {
                set stateTable(added) [remove $entry $stateTable(added)]
                set skip 1
            }

            if {[info exist stateTable(cantfix)] && [member $entry $stateTable(cantfix)]} {
                set stateTable(cantfix) [remove $entry $stateTable(cantfix)]
            }
            if {[info exist stateTable(cleared)] && [member $entry $stateTable(cleared)]} {
                set stateTable(cleared) [remove $entry $stateTable(cleared)]
            }     
            if {[info exist stateTable(fixed)] && [member $entry $stateTable(fixed)]} {
                set stateTable(fixed) [remove $entry $stateTable(fixed)]
            }               
        }
        "fixed" {
            if {[info exist stateTable(cantfix)] && [member $entry $stateTable(cantfix)]} {
                set stateTable(cantfix) [remove $entry $stateTable(cantfix)]
            }
            if {[info exist stateTable(cleared)] && [member $entry $stateTable(cleared)]} {
                set stateTable(cleared) [remove $entry $stateTable(cleared)]
            }     
            if {[info exist stateTable(fixed)] && [member $entry $stateTable(fixed)]} {
                set stateTable(fixed) [remove $entry $stateTable(fixed)]
            }             
        }
        "cantfix" {
            if {[info exist stateTable(cantfix)] && [member $entry $stateTable(cantfix)]} {
                set stateTable(cantfix) [remove $entry $stateTable(cantfix)]
            }
            if {[info exist stateTable(cleared)] && [member $entry $stateTable(cleared)]} {
                set stateTable(cleared) [remove $entry $stateTable(cleared)]
            }     
            if {[info exist stateTable(fixed)] && [member $entry $stateTable(fixed)]} {
                set stateTable(fixed) [remove $entry $stateTable(fixed)]
            }             
        }        
        "cleared" {
            if {[info exist stateTable(cantfix)] && [member $entry $stateTable(cantfix)]} {
                set stateTable(cantfix) [remove $entry $stateTable(cantfix)]
            }
            if {[info exist stateTable(fixed)] && [member $entry $stateTable(fixed)]} {
                set stateTable(fixed) [remove $entry $stateTable(fixed)]
            }             
        }       
    }
    if {[info exist stateTable(fixed)] && ![llength $stateTable(fixed)]} {
        unset stateTable(fixed)
    }
    if {[info exist stateTable(cantfix)] && ![llength $stateTable(cantfix)]} {
        unset stateTable(cantfix)
    }    
    if {[info exist stateTable(cleared)] && ![llength $stateTable(cleared)]} {
        unset stateTable(cleared)
    }    
    if {[info exist stateTable(deleted)] && ![llength $stateTable(deleted)]} {
        unset stateTable(deleted)
    }    
    if {[info exist stateTable(added)] && ![llength $stateTable(added)]} {
        unset stateTable(added)
    }

    if {!$skip} {
        if {![info exist stateTable($action)]} {
            set stateTable($action) {}
        }
        if {![member $entry $stateTable($action)]} {
            lappend stateTable($action) $entry
        }
    }
    
    if {$checkout && [amdDesignReviewIsModified]} {
        amdDesignReviewCheckOut $oaDes
    }
}


proc amdDesignReviewCheckOut {oaDes} {
    set file [amdDesignReviewGetFile $oaDes]
    if {""!=$file && [file size $file]} {
        set action "edit"
    } else {
        set file [amdDesignReviewGetFile $oaDes 1]
        set action "add"
    }
    if {[amdIsFileCheckedOut $file] && $action == "edit"} {
        return 1
    } else {
        # first attempt to sync to latest revision
		if {$action == "edit"} {
        	amdRun "p4 sync -f $file"
		}
        # check it out
        amdRun "p4 $action $file"
        return [amdIsFileCheckedOut $file]
    }
}

proc amdDesignReviewIsModified {} {
    variable stateTable
    return [array size stateTable]
}


proc amdDesignReviewGetEntryValue {row fieldName} {
    set cells [gi::getCells -row $row]
    set giCell [db::filter $cells -filter {%column.label == $fieldName}]
    return [db::getAttr value -of $giCell]
}


proc amdAddEntry {line {trackChanges 0} {reviewDlg ""}} {
    variable columns
    if {""==$reviewDlg} {
        set reviewDlg [db::getNext [gi::getDialogs reviewDialog]]
    }
    set tbl [gi::findChild report -in $reviewDlg]
    set row [gi::createRow -parent $tbl]
    
    foreach oneColumn $columns value  $line  {
        set giCell [gi::getCells -row $row -column \
            [gi::getColumns -parent $tbl -filter {%label == $oneColumn}]]
        db::setAttr value -of $giCell -value $value
    }
    if {$trackChanges} {
        amdDesignReviewTrackChanges $row "Added"
    }
}

proc amdGetEntry {row} {
    variable columns
    set tbl [db::getAttr parent -of $row]
    set res {}
    foreach oneColumn $columns {
        set giCell [gi::getCells -row $row -column \
            [gi::getColumns -parent $tbl -filter {%label == $oneColumn}]]
        lappend res [db::getAttr value -of $giCell]
    }    
    return $res
}


proc amdDesignReviewAdd {widget} {
    set reviewDlg [db::getNext [gi::getDialogs reviewDialog]]
    set form [gi::findChild form -in $reviewDlg]
    set oaDes [openDesign [db::getAttr design -of $form]]
    if {[amdDesignReviewIsModified] || ([amdDesignReviewCheckIsLatest $oaDes] && [amdDesignReviewCheckIsCheckedOut $oaDes])} {
        # checkout as soon as add review button is clicked
        if {![amdDesignReviewIsModified]} {
            amdDesignReviewCheckOut $oaDes
        }
        amdDisplayLayout [db::getAttr oaDes.libName] [db::getAttr oaDes.cellName] [db::getAttr oaDes.viewName]
        amd::createMarker    
    }

}

} ;# End of namespace ::amd::_designReview 


namespace eval ::amd::createMarker {

namespace import -force ::amd::utils::*
namespace import -force ::amd::_designReview::*

proc init {self context {args ""}} {
    set ns [namespace current]
    if {"maskLayout" != [db::getAttr context.editDesign.viewType]} {
        error "Can only draw marker in a layout view"
    }
    if {"Point"==[db::getPrefValue amdDRTInput]} {
        set shapeEng [de::createShapeEngine -completeProc [list ${ns}::completeShape $context] -shapeType point]
    } else {
        set shapeEng [de::createShapeEngine -completeProc [list ${ns}::completeShape $context] -shapeType rectangle]
    }
    db::setAttr self.engine -value $shapeEng
    set prompt "Click on canvas to create a marker"
    db::setAttr self.prompt -value $prompt
}
    
proc buildDialog {self dlg} {
    set ns [namespace current]
    set reviewDlg [db::getNext [gi::getDialogs reviewDialog]]
    if {""==$reviewDlg} {
        return
    }
    set phase [gi::findChild category.value -in $reviewDlg]
    if {"Phase"!=$phase} {
        db::setPrefValue amdDRTPhase -value $phase
    } else {
        db::setPrefValue amdDRTPhase -value "Pre Layout"
    }
    set phase [gi::createMutexInput phase \
        -parent $dlg \
        -enum {"Pre Layout" "Layout" "Final Layout"} \
        -viewType combo \
        -prefName amdDRTPhase -label "Phase"]
    for {set i 1} {$i <= 10} {incr i} {
        lappend vList $i
    }
    set rev [gi::createMutexInput rev \
        -parent $dlg \
        -label Revision \
        -viewType combo \
        -enum $vList \
        -prefName amdDRTRevision]
    set input [gi::createMutexInput input \
        -label "Input" \
        -parent $dlg \
        -enum [list "Point" "BBox"] \
        -valueChangeProc [list ${ns}::changeEngine $self] \
        -prefName amdDRTInput]
    gi::layout $input -rightOf $rev
    gi::layout $input -justify right
    set txt [gi::createTextInput text \
        -height 3 \
        -width 50 \
        -parent $dlg \
        -label Comment \
        -prefName amdDRTNoteComment]
}


proc changeEngine {self widget} {
    set ns [namespace current]
    set dialog [db::getAttr self.dialog]
    set input [gi::findChild /input -in $dialog]
    set mode [db::getAttr input.value]
    set context [db::getNext [db::getAttr self.contexts]]
    if {"Point" == $mode} {
        set shapeEng [de::createShapeEngine -completeProc [list ${ns}::completeShape $context] -shapeType point]
    } else {
        set shapeEng [de::createShapeEngine -completeProc [list ${ns}::completeShape $context] -shapeType rectangle]
    }
    db::setAttr self.engine -value $shapeEng    
} 


proc completeShape {context self} {
    variable columns
    set context [db::getNext [db::getAttr contexts -of $self]]
    set points [db::getAttr self.engine.points]
    set oaDes [db::getAttr context.editDesign]
    if {"schematic" == [db::getAttr oaDes.viewType]} {
        set side 0.1
    } else {
        set side 0.05
    }
    set block [oa::getTopBlock $oaDes]
    set bBox [processPoints $points $side]
    set oaPA [oa::PointArray [box2oaBox $bBox]]
    set window [db::getAttr context.window]
    set phase [db::getPrefValue amdDRTPhase]
    set revision [db::getPrefValue amdDRTRevision]
    set comment [db::getPrefValue amdDRTNoteComment]
    regsub -all \n $comment " " comment
    set reviewer $::env(USER)
    set date [getCurrentTime]
    set location $bBox
    set status ""
    set owner ""
    set notes ""
    
    set line [list $phase $revision $comment $reviewer $date $location $status $owner $notes]
    ::amd::_designReview::amdAddEntry $line 1

    set comment "\[$phase rev.${revision}\] $comment"    
    set tran [de::startTransaction reviewMarker -design $oaDes]
    set oaMarker [oa::MarkerCreate $block $oaPA $comment \
            "Design Review" "Design Review Tool" 1 1 warning]    
    de::endTransaction $tran    
    de::abortCommand -window $window
    
    set reviewDlg [db::getNext [gi::getDialogs reviewDialog]]
    if {""==$reviewDlg} {
        return
    }    
    gi::setActiveDialog $reviewDlg
}


proc toolbarCreated {self toolBar} {
    set context [db::getNext [db::getAttr self.contexts]] 
    catch {gi::pressButton {eject} -in [gi::getToolbars {deCommandOptions} -from [db::getAttr context.window]]}
    de::sendMessage "Dialog for this command cannot be hidden" -severity warning
}


proc processPoints {points side} {
    set l [llength $points ]
	if {$l == 4} {
        set bBox [getBoxFromPoints $points]
    } else {
        set side [expr $side/2]
        set pList [string trimleft [string trimright [string trim $points] \}] \{]
        set x1 [expr [lindex $pList 0] - $side]
        set x2 [expr [lindex $pList 0] + $side]
        set y1 [expr [lindex $pList 1] - $side]
        set y2 [expr [lindex $pList 1] + $side]
        set bBox [list [list $x1 $y1] [list $x2 $y2]]
    }
	return $bBox
}


proc getBoxFromPoints { points } {
    set lx [lindex $points 0 0]
    set ly [lindex $points 0 1]
    set ux [lindex $points 0 0]
    set uy [lindex $points 0 1]
    foreach point $points {
        if { $lx > [lindex $point 0] } {
            set lx [lindex $point 0]
        }
        if { $ly > [lindex $point 1] } {
            set ly [lindex $point 1]
        }
        if { $ux < [lindex $point 0] } {
            set ux [lindex $point 0]
        }
        if { $uy < [lindex $point 1] } {
            set uy [lindex $point 1]
        }
    }
    return [list [list $lx $ly] [list $ux $uy]]
}

}

de::createCommand amd::createMarker \
    -description  "Creates a marker" -type interactive \
    -title "Create Marker" -label "Create Marker..." \
    -category deCommands
db::setPrefValue amdCreateMarkerDialogMode -value true 

