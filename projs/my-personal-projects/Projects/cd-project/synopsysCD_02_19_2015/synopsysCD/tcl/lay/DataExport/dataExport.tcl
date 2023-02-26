# Copyright (c) 2004-2015 Synopsys, Inc. This Galaxy Custom Designer software
# and the associated documentation are confidential and proprietary to
# Synopsys, Inc. Your use or disclosure of this Galaxy Custom Designer software
# is subject to the terms and conditions of a written license agreement between
# you, or your company, and Synopsys, Inc.


# Project:      Data Export Tool 
# File:         dataExport.tcl
# Description:  

namespace eval ::amd::_de { 

namespace import -force ::amd::utils::*

proc exportCreateForm {} {
    set dlgName exportDialog
    
    set ns [namespace current]
    set ctx ""
    set cv ""
    set techRefs ""
    if {[catch {set ctx [de::getActiveContext]}]} {
        de::sendMessage "No valid cellview is open. Please open the top level cell and retry." -severity warning
    }

    set exportDlg [db::getNext [gi::getDialogs $dlgName]]
    if {""!=$ctx} {
        set oaDes [db::getAttr ctx.editDesign]
        set cv [db::getNext [dm::getCellViews [db::getAttr oaDes.viewName] \
            -cellName [db::getAttr oaDes.cellName] \
            -libName [db::getAttr oaDes.libName]]]
        set techRefs [getAllRefLibNames $oaDes]
    }
    catch {de::registerHelp -helpID exportDialogHelp -type url \
    -target "http://mpdwww.amd.com/twiki/bin/view/Cadteam/CadenceTestcaseCaptureFormHelp"}

    if {""==[db::getPrefValue amdDEBackupPath]} {
        db::setPrefValue amdDEBackupPath -value [pwd]
    }
    db::setPrefValue amdDETechLibs -value $techRefs
    
    if {""==$exportDlg} {
        set exportDlg [gi::createDialog $dlgName \
        -showApply true -showHelp true \
        -execProc ${ns}::exportEngine -title "Data Export" -topicId exportDialogHelp] 
        dm::createCellViewInput lcv -parent $exportDlg \
            -value $cv -required true -valueChangeProc ${ns}::cvSetCB
        gi::createTextInput techLib -parent $exportDlg \
            -label "Technology Library" -prefName amdDETechLibs
        gi::createTextInput pdkLib -parent $exportDlg \
            -label "Required Libraries" -prefName amdDEPDKLibs
        gi::createTextInput backDirField -parent $exportDlg \
            -label "New Backup sub-dir name to put data in" -prefName amdDEBackupDir
        gi::createFileInput dirField -parent $exportDlg \
            -label "Full Path to put Backup sub-dir under" \
                -prefName amdDEBackupPath -fileType directory
        gi::createFileInput replayLogField -parent $exportDlg \
            -label "Test/crash CD log to capture for replay" -fileType file -prefName amdDECaptureLogFile    
        gi::createMutexInput verboseField -parent $exportDlg \
            -label "Verbose output in Console?" -enum {"No" "Yes"} -prefName amdDEVerboseOutput
        gi::createMutexInput tarField -parent $exportDlg \
            -label "Create tar file?" -enum {"No" "Yes"} -prefName amdDECreateTarFile
        set w [gi::createMutexInput copyLibs -parent $exportDlg \
            -label "Copy Required Libraries" -enum {"No" "Yes"} -prefName amdDECopyPDKLibs -valueChangeProc ${ns}::enableLibsCopyCB]
        enableLibsCopyCB $w
        db::setAttr geometry -of $exportDlg -value 600x600+20%+40%
    } else {
        set lcv [gi::findChild lcv -in $exportDlg]
        db::setAttr value -of $lcv -value $cv
    }
    gi::setActiveDialog $exportDlg
}


proc enableLibsCopyCB {w} {
    set dlg [db::getAttr w.parent]
    set pdkLib [gi::findChild pdkLib -in $dlg]
    db::setAttr enabled -of $pdkLib -value [expr ("Yes"==[db::getAttr w.value] ? 1: 0)]
}

proc cvSetCB {w} {
    set cv [db::getAttr w.value]
    set lName [db::getAttr cv.libName]
    set cName [db::getAttr cv.cellName]
    set vName [db::getAttr cv.name]
    if {""!=$lName && ""!=$cName && ""!=$vName} {
        if {![catch {set scv [dm::getCellViews $vName -cellName $cName -libName $lName]}]} {
            set ctx [db::getNext [de::getContexts -filter {%editDesign.libName==$lName && %editDesign.cellName==$cName && %editDesign.viewName==$vName}]]
            if {""==$ctx} {
                set ctx [de::createContext $scv -readOnly true]
                set oaDes [db::getAttr ctx.editDesign]
                set techRefs [getAllRefLibNames $oaDes]
                db::setPrefValue amdDETechLibs -value $techRefs
                de::close $ctx
            }
        }
    }
}

proc exportEngine {dlg} {
    # Prepare the backup by checking to see if the destination directory exists, 
    # and if not, creating the directory. The directory one level up must exist 
    # in advance as well.
    set backupDir [db::getPrefValue amdDEBackupDir]
    set backupPath [db::getPrefValue amdDEBackupPath]
    set verbose [expr {[db::getPrefValue amdDEVerboseOutput]=="Yes" ? 1 : 0}]
    
    # Error check first:
    set completeBackPath [file normalize [file join $backupPath $backupDir]]
    if {![file isdir $backupPath]} {
        de::sendMessage "Export: Backup directory doesn't exist: $backupPath" -severity error
        return
    }
    if {[file isdir $completeBackPath]} {
        de::sendMessage "Export: Backup directory already exists: $backupDir" -severity error
        return    
    }
    
    if {[catch {file mkdir $completeBackPath}]} {
        de::sendMessage "Export: Cannot create backup directory: $completeBackPath" -severity error
        return    
    }
    
    # Having created the new backup directory, create a lib.defs file that will sit in the
    # directory, and open it for editing:    
    
    if {[catch {set libFile [open [file join $completeBackPath lib.defs] "w"]}]} {
        de::sendMessage "Export: Cannot create lib.defs file in directory $completeBackPath" -severity error
        return           
    }

    # Begin Backup:
    puts "Beginning backup"
        
    # Let's copy over the log file for easy replay
    puts "Backing up log file into directory $completeBackPath"
    file copy -force [file join $::env(SYNOPSYS_CUSTOM_LOCAL) cdesigner.log] $completeBackPath
    
    
    # Obtain the libraries that will be backed up completely. 
    set libsDS [getLibInfo]

    # For each regular library to be backed up fully...
    db::eval {
        set ih [db::createInterruptHandler "Copy Libs"]
        foreach fullBackupLib $libsDS {
            set dmLib [db::getNext [dm::getLibs $fullBackupLib]]
            if {""!=$dmLib} {
                set fullLibDir [db::getAttr dmLib.path]
                
                # Store the new library's complete path (this includes the library directory name,
                # i.e., the cells will sit in THIS directory).            
                set newLibDir [file join $completeBackPath $fullBackupLib]
                
                # And finally copy the library into the destination directory.
                # Since this can take a while, let the user know which lib is being copied, and when 
                # that copy is completed. 
                db::checkForInterrupt "Copy Lib" -handler $ih                
                if {$verbose} {
                    puts "Backing up library $fullBackupLib into directory $newLibDir."
                }
                exec cp -r $fullLibDir $newLibDir
                
                db::checkForInterrupt "Copy Lib" -handler $ih
                if {$verbose} {
                    puts "- Successfully backed up library $fullBackupLib into directory $newLibDir."
                } 
                puts $libFile "DEFINE $fullBackupLib ./${fullBackupLib}"
            }
        }
    }
    
    #***************************************************************************
    #Back up the open cell view hierarchically.
    #***************************************************************************/
    set closeContxet 0
    set libNameList {}    
    set lcv [gi::findChild lcv -in $dlg]
    set cv [db::getAttr lcv.value]
    set lName [db::getAttr cv.libName]
    set cName [db::getAttr cv.cellName]
    set vName [db::getAttr cv.name]
    
    #set ctx [db::getNext [de::getContexts -filter {%editDesign.libName==$lName && %editDesign.cellName==$cName && %editDesign.viewName==$vName}]]
    #if {""==$ctx} {
    #    set closeContxet 1
    #    set ctx [de::createContext $cv -readOnly true]
    #}
    array set cells {}
    #[db::getAttr hierarchy -of $ctx]
    he::foreach c $cv {
        set currLibName [db::getAttr c.cellView.libName]
        if {![member $currLibName $libsDS]} {
            lappend cells($currLibName) [db::getAttr c.cellView.cellName]
        }
    }

    # Create the destination library name for each library:
    foreach libName [array names cells] {
        set libBackPath [file join $completeBackPath $libName]
        if {$verbose} {
            puts "Backing up library $libName into directory $libBackPath."
        }
        exec mkdir -p $libBackPath
        set oldLibPath [db::getAttr path -of [dm::getLibs $libName]]
        # Copy over all files that are not design data from within the library directory:
        exec find $oldLibPath -maxdepth 1 -type f -exec cp -r \{\} $libBackPath \;
        exec find $oldLibPath -maxdepth 1 -type d -name ".*" -exec cp -r \{\} $libBackPath \;
        puts $libFile "DEFINE $libName ./${libName}"
        foreach cellName $cells($libName) {
            set sourceDir [file join $oldLibPath $cellName]
            set destDir [file join $libBackPath $cellName]
            exec cp -r $sourceDir $destDir
            # Alert the user, then issue the copy command.
            if {$verbose} {
                puts "Backing up cell $sourceDir into $destDir"
            }
        }
    }

    # Remove any cdslck files that were erroneously copied over.
    exec find $completeBackPath -type f -name *cdslck* -exec rm -rf \{\} \;

    # If the display.drf, .cdsinit, or .cdsenv file exists, copy it in
    set otherFiles [list "display.drf" ".cdesigner.tcl" "prefs.xml" "display.tcl"]
    set cwd [pwd]
    
    foreach otherFile $otherFiles {
        if {[file isfile [file join $cwd $otherFile]]} {
            exec cp [file join $cwd $otherFile] $completeBackPath
            if {$verbose} {
                puts "Backed up file: $otherFile"
            }
        }
    }

    close $libFile
    
    #;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    #;; Create a README.txt file to contain AMD Confidential statement
    #;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    set fileName [file join $completeBackPath README.txt]
    set fh [open $fileName "w"]
    puts $fh "All material contained within this tar file and related correspondence,"
    puts $fh "including instructions, files and content, represented in all data forms are"
    puts $fh "strictly AMD confidential and required to adhere to current NDA restrictions."
    puts $fh "Material should only be used for intended purpose. Any other use must require"
    puts $fh "prior written consent by an authorized AMD representative."
    close $fh
    
    set replayFile [db::getPrefValue amdDECaptureLogFile]
    if {[file isfile $replayFile]} {
        puts "Copying session log for replay: $replayFile"
        exec cp -a $replayFile [file join $completeBackPath replay.log]
    }
 
    # Depending on what the user entered into the form, tar the file.
    if {"Yes" == [db::getPrefValue amdDECreateTarFile]} {
        if {$verbose} {
            puts "Tarring up directory: ${completeBackPath}.tar.gz"
        }
        cd $backupPath 
        #puts "tar -cf - $backupDir | gzip -c - > ${completeBackPath}.tar.gz"
        exec tar -cf - $backupDir | gzip -c - > ${completeBackPath}.tar.gz
        cd $cwd
        if {$verbose} {
            puts "- Successfully tarred up directory: ${completeBackPath}.tar.gz."
        }        
    }
    
    puts "****************************************************************************"
    puts "*                          Backup completed!!                              *"
    puts "****************************************************************************"
}


    
    
proc getLibInfo {} {
    # Following are text strings that should be part of library names that will
    # be copied in their ENTIRETY!! NOTE: If you enter nil, the prefix or suffix will 
    # simply not be used as a filter, and the lib name will always pass that test.
    
    set copyLibNameSuffix "###"
    set copyLibNamePrefix "###"
    
    set techLibs [db::getPrefValue amdDETechLibs]
    
    # Following is an optional list of libraries which will be automatically copied in their 
    # entirety into the new library area. Each must be spelled correctly!!
    # set copyIncludeLibNameList {}
    # copyIncludeLibNameList [list "basic" "analogLib" $techLibs]
    set copyIncludeLibNameList {}
    if {"Yes"==[db::getPrefValue amdDECopyPDKLibs]} {
        set copyIncludeLibNameList [db::getPrefValue amdDEPDKLibs]
    }
    set copyIncludeLibNameList [concat $copyIncludeLibNameList $techLibs]
    
    set libList [db::createList [db::getAttr name -of [dm::getLibs]]]
    set FullBackupList {}
    foreach libName $libList {
        if {[regexp $copyLibNameSuffix $libName]} {
            puts $libName
            lappend FullBackupList $libName
        } elseif {[regexp $copyLibNamePrefix $libName]} {
            puts $libName
            lappend FullBackupList $libName
        }
    }
    # Add to this list the FullBackupList. All of these libraries will be copied entirely.
    set fullBackupLibList [lsort -unique [concat $FullBackupList $copyIncludeLibNameList]]
    return $fullBackupLibList
}

}

