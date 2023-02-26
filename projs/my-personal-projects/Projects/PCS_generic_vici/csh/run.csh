#!/bin/tcsh -fx


set LOC_DIR = "/slowfs/dcopt105/alvaro/GitLab/PCS_generic_vici"
set TOOL  = "$LOC_DIR/csh/PCS_generic_vici.csh"

set data_file =  "$LOC_DIR/env/data"
set data_tmp  =  `wc -l $data_file`
set data_size = $data_tmp[1]
unset data_tmp

set j = 1

while ( $j <= $data_size )
    
    set data = `cat $data_file | head -$j | tail -1`
    
    source $TOOL $data

    @ j++

end

