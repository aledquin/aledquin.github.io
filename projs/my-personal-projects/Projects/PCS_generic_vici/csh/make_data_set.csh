#!/bin/tcsh -f


set data_file = "/slowfs/dcopt105/alvaro/GitLab/alvaro/PCS_generic_vici/env/data"

set prod_line = "lpddr5x"
set PCS_proj  = "d930-lpddr5x-tsmc5ff12"
set PCS_rel_v = "rel0.90_tc"
set CCS_proj  = "c253-tsmc5ff-1.2v"
set CCS_rel_v = "rel9.3.1"

set STAR_ID   = "P10023532-44310"

rm -f $data_file
touch $data_file

foreach PCS_rel_v_u ($PCS_rel_v)

echo "$prod_line $PCS_proj $PCS_rel_v_u $CCS_proj $CCS_rel_v $STAR_ID " >> $data_file

end


