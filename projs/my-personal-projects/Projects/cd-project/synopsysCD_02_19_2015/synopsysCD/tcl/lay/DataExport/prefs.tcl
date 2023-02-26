# Copyright (c) 2004-2015 Synopsys, Inc. This Galaxy Custom Designer software
# and the associated documentation are confidential and proprietary to
# Synopsys, Inc. Your use or disclosure of this Galaxy Custom Designer software
# is subject to the terms and conditions of a written license agreement between
# you, or your company, and Synopsys, Inc.

db::createPref amdDEBackupDir \
    -description "Keeps value of backup sub-dir name to put data in" \
    -type string \
    -value ""
db::createPref amdDEBackupPath \
    -description "Keeps full Path to put Backup sub-dir under" \
    -type string \
    -value ""
db::createPref amdDEVerboseOutput \
    -description "Verbose output in CD console" \
    -type string \
    -value "No"
db::createPref amdDECaptureLogFile \
    -description "Test/crash CD log to capture for replay" \
    -type string \
    -value ""
db::createPref amdDETechLibs \
    -description "" \
    -type string \
    -value ""
db::createPref amdDECreateTarFile \
    -description "Create tar file" \
    -type string \
    -value "Yes"
db::createPref amdDEPDKLibs \
    -description "List of libraries which will be automatically copied in their entirety into the new library area" \
    -type string \
    -value "basic analogLib primitives ginfLib amd_skill amd_primitives amd_logicgates amd_simlib amd_basic amd_unitcells amd_ginfLib"    
db::createPref amdDECopyPDKLibs \
    -description "Enable automatic copy of required libs" \
    -type string \
    -value "Yes"  