#!/bin/tcsh
module unload icvwb
module load icvwb/2022.03-SP1
icvwb -run icvwb_generate_layout.mac -nodisplay -log icvwb_generate_layout.log
