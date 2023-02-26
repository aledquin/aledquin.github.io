# Copyright (c) 2004-2015 Synopsys, Inc. This Galaxy Custom Designer software
# and the associated documentation are confidential and proprietary to
# Synopsys, Inc. Your use or disclosure of this Galaxy Custom Designer software
# is subject to the terms and conditions of a written license agreement between
# you, or your company, and Synopsys, Inc.

db::createPref amdDRTNoteComment \
    -description "Keeps value of the Review Note Comment field" \
    -type string \
    -value ""
db::createPref amdDRTPhase \
    -description "" \
    -type string \
    -value ""
db::createPref amdDRTRevision \
    -description "" \
    -type int \
    -value 1    
db::createPref amdDRTInput \
    -description "" \
    -type string \
    -value Point      
db::createPref amdChangeStatusNote \
    -type string -value "" \
    -description "Keeps value of the Note field of the Change Status dialog"